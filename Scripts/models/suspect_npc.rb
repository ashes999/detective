require 'scripts/name_generator'
require 'scripts/models/npc'

# A wrapper around the RPG Maker event. It exposes some properties and stuff, and methods like die.
class SuspectNpc < Npc
    
  attr_accessor :map_id, :age, :profession
  
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
    @criminal_record = generate_criminal_record
    @social_media = generate_social_media_profile
    @messages = [      
      "I like #{@social_media[:post_topic]}!",
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
    return "#{@name} is a #{@age} year-old #{@profession} with blood type #{@blood_type}.\n#{@criminal_record}\n#{@social_media[:profile]}"
  end
  
  def alibi_person
    return @alibi_person
  end
  
  def alibi_person=(person)
    @alibi_person = person
    @messages << "I was with #{@alibi_person.name} all day."    
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
    return "#{@name} has no prior criminal record." if severity < 30
    return "#{@name}'s criminal record contains a few counts of #{ExternalData::instance.get(:negligible_crimes).sample}." if severity < 60
    return "#{@name} served a short jail sentence for #{ExternalData::instance.get(:minor_crimes).sample}." if severity < 85
    return "#{@name} served several years of combined jail time for #{ExternalData::instance.get(:major_crimes).sample(2).join(' and ')}." # >= 85
  end
  
  def generate_social_media_profile
    data = ExternalData::instance
    site = data.get(:social_media_sites).sample
    num_friends = rand(50) + 50
    post_frequency = data.get(:social_media_frequencies).sample
    post_topic = data.get(:social_media_topics).sample
    return {
      :site => site,
      :num_friends => num_friends,      
      :post_topic => post_topic,
      :profile => "#{@name} has #{num_friends} friends on #{site} and #{post_frequency} posts about #{post_topic}."
    }
  end
end