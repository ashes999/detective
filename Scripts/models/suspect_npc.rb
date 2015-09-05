require 'scripts/name_generator'
require 'scripts/models/npc'

# A wrapper around the RPG Maker event. It exposes some properties and stuff, and methods like die.
class SuspectNpc < Npc
    
  # evidence_count: the number of signals (suspicious information) that this person is the killer.
  # Starts set to some value, and decreases every time we actualize a signal (eg. create weak alibi)
  attr_accessor :map_id, :age, :profession, :evidence_count
  
  # move_speed = 1-6
  # move_frequency = 1-5
  # spritesheet_file is the filename used for the graphic, eg. Actor1.
  # spritesheet_index is the base 0 index (0-7; first row, then second row)
  # template_id is the ID of the event we're copying, on map with ID=DATA_MAP_ID
  def initialize(map_id, name, spritesheet_file = nil, spritesheet_index = nil, template_id = nil, npc_speed = nil, npc_frequency = nil)
    super(name, spritesheet_file, spritesheet_index, template_id, npc_speed, npc_frequency)
    @map_id = map_id
    
    # basic facts
    @age = 20 + rand(15)    
    @profession = ExternalData::instance.get(:professions).sample
    @blood_type = pick_blood_type
    @evidence_count = 0    
    @messages = [      
      "Isn't it #{['strange', 'scary', 'sad', 'unfortunate'].sample}, what happened?",
      "The weather today #{['sucks', 'rocks', 'is okay', 'bothers me', 'confuses me'].sample}."
    ]    
  end
 
  def talk    
    if @dead
      message = "#{@name} is dead ..."
    else
      message = "#{@name}: #{@messages.sample}"
    end
    Game_Interpreter.instance.show_message(message)
    DetectiveGame::instance.notebook.note(message)
  end
  
  def profile
    profile = ''
    profile = "#{@name} was found dead earlier today.\n" if @dead
    profile = "#{profile}#{@name} is a #{@age} year-old #{@profession} with blood type #{@blood_type}.\n#{@criminal_record}\n#{@social_media[:profile]}"
    return profile
  end
  
  def alibi_person
    return @alibi_person
  end
  
  def alibi_person=(person)
    time_of_day = ['day', 'afternoon', 'night'].sample
    @alibi_person = person
    if person.nil?
      @messages << "I was alone all #{time_of_day}."
    else
      @messages << "I was with #{@alibi_person.name} all #{time_of_day}."
    end
  end
  
  # These are the things that may consume signals, so do them after we know how
  # many signals each NPC has.
  def augment_profile
    @criminal_record = generate_criminal_record
    @social_media = generate_social_media_profile
    @messages << "I like #{@social_media[:post_topic]}!"
  end
  
  private
  
  def pick_blood_type
    # Based on culmulative distribution from http://www.redcrossblood.org/learn-about-blood/blood-types
    # O: 48% A: 31% B: 16% AB: 4%
    # i.e. 50% O, 80% O and A
    blood_picked = rand(100)
    return 'O' if blood_picked < 48
    return 'A' if blood_picked < 48 + 31
    return 'B' if blood_picked < 48 + 31 + 16
    return 'AB'
  end
  
  def generate_criminal_record
    severity = rand(100)
    # 30% nothing, 30% mild, 25% medium, 15% severe
    return "#{@name} has no prior criminal record." if severity < 30 || @evidence_count == 0
    return "#{@name}'s criminal record contains a few counts of #{ExternalData::instance.get(:negligible_crimes).sample}." if severity < 60
    
    # Suspicious criminal record is a signal
    @evidence_count -= 1
    return "#{@name} served a short jail sentence for #{ExternalData::instance.get(:minor_crimes).sample}." if severity < 85
    return "#{@name} served several years of combined jail time for #{ExternalData::instance.get(:major_crimes).sample(2).join(' and ')}."
  end
  
  def generate_social_media_profile
    data = ExternalData::instance
    site = data.get(:social_media_sites).sample
    
    if (@evidence_count > 0 && rand(100) < 50)
    # having few social connection is a signal
      num_friends = rand(15) + 15
      @evidence_count -= 1
    else
      num_friends = rand(50) + 50
    end
    
    post_frequency = data.get(:social_media_frequencies).sample
    post_topic = data.get(:social_media_topics).sample
    return {
      :site => site,
      :num_friends => num_friends,      
      :post_topic => post_topic,
      :profile => "#{@name} has #{num_friends} friends on #{site} and #{post_frequency} posts about #{post_topic}."
    }
  end
  
  def to_s
    return "#{@name}: #{@evidence_count}"
  end
end