require 'scripts/name_generator'
require 'scripts/models/npc'

# Add an "npc" field to the event class, so we can keep all our code externalized
class Game_Event
  # Access via scripts on an event, eg. $game_map.events[self.event_id].npc
  attr_accessor :npc
end
  
# A wrapper around the RPG Maker event. It exposes some properties and stuff, and methods like die.
class SuspectNpc < Npc
    
  RESIST_TALKING_MESSAGES = ['Go away!', 'I don\t have anything to say to you.', 'You a cop? I don\'t talk to cops.', 'We can talk in the presence of my lawyer.', '...']
  
  WILL_NOW_TALK_MESSAGE = 'Okay, fine, I\'ll talk. What do you want to know?'
  
  ASKABLE_QUESTIONS = {
    :family => 'Tell me about your family.',
    :prior_record => 'Do you have a previous criminal record?',
    :biography => 'Tell me about yourself.'
  }
  
  # evidence_count: the number of signals (suspicious information) that this person is the killer.
  # Starts set to some value, and decreases every time we actualize a signal (eg. create weak alibi)
  attr_accessor :map_id, :age, :profession, :evidence_count, :blood_type  
  
  # move_speed = 1-6
  # move_frequency = 1-5
  # spritesheet_file is the filename used for the graphic, eg. Actor1.
  # spritesheet_index is the base 0 index (0-7; first row, then second row)
  # template_id is the ID of the event we're copying, on map with ID=DATA_MAP_ID
  def initialize(map_id, name, spritesheet_file = nil, spritesheet_index = nil, template_id = nil, npc_speed = nil, npc_frequency = nil)
    super(name, spritesheet_file, spritesheet_index, template_id, npc_speed, npc_frequency)
    @map_id = map_id
    data = ExternalData::instance
    
    # basic facts
    @age = 20 + rand(15)    
    @profession = data.get(:professions).sample
    @blood_type = pick_blood_type
    @evidence_count = 0
    
    @messages = [      
      "Isn't it #{['strange', 'scary', 'sad', 'unfortunate'].sample}, what happened?",
      "The weather today totally #{['sucks', 'rocks', 'is okay', 'bothers me', 'confuses me'].sample}."
    ]
    
    @messages_said = []
    @my_questions = []
    
    # After not talking this many times, we willingly talk
    # > 0 means "go away!"
    # = 0 means "ok, ok, I'll talk!"
    # -1 means just talk normally
    @resist_talking_times = -1
    
    # signal => question
    @criminology_signals = {}
  end
 
  def talk    
    if @dead
      message = "#{@name} is dead ..."
    else
      # Do we have to resist talking?
      if @resist_talking_times > -1 # when 0, say "okay I'll talk"        
        if @resist_talking_times > 0
          message = @resist_messages.sample
        else
          message = WILL_NOW_TALK_MESSAGE
        end
        @resist_talking_times -= 1
      else
        message = @messages.sample
      end
    end
    
    @messages_said << message unless @messages_said.include?(message)
    message = "#{@name}: #{message}" unless message.include?('is dead')
    Game_Interpreter.instance.show_message(message)
    DetectiveGame::instance.notebook.note(message)
    
    Game_Interpreter.instance.show_message("\\N[1]: I've heard everything #{@name} has to say.") if (@messages - @messages_said).empty?
  end

  ###
  # Given a list of signals (eg. :single, :divorced), map to category.
  # This is because the player asks a category question, like :family.
  # So if :single and :divorced are both :family, we want a hash with
  # :family => ["I'm single", "I'm divorced"]
  def answer_questions(signals, signal_to_question, signal_to_text)
    @criminology_signals = signals
    @evidence_count -= @criminology_signals.count
    @my_questions = {}
    
    signals.each do |s|
      raise "Don't have a question text for #{s}" unless signal_to_text.key?(s)
      question_text = signal_to_text[s]
      raise "Not sure the question category of #{s}" unless signal_to_question.key?(s)
      category = signal_to_question[s] # :divorced => :family      
      
      if !@my_questions.key?(category)
        @my_questions[category] = []
      end
      
      @my_questions[category] << question_text
    end
  end
  
  def show_questions
    Game_Interpreter::instance.show_message("\\N[1]: So ...", :wait => false)
    
    # Given that we have certain questions, eg. :family => "Single", "Divorced",
    # and we know :family => "Tell me about your family", generate a list of what
    # we can ask (eg. ["Tell me about your family", ...]) -- uniques only
    questions_texts = []
    @my_questions.each do |category, list|
      raise "We don't have a text for #{category}" unless ASKABLE_QUESTIONS.key?(category)
      text = ASKABLE_QUESTIONS[category]      
      questions_texts << text unless questions_texts.include?(text)
    end
    
    questions_texts << 'Never mind.'
    choice = Game_Interpreter::instance.show_choices(questions_texts, { :cancel_index => questions_texts.length - 1, :return_type => :name})
    return if choice == 'Never mind.'
    
    # map choice (eg. "Tell me about your family") to a key (eg. :family)   
    category = nil
    ASKABLE_QUESTIONS.each do |key, text|
      category = key if choice == text      
    end
    raise "Can't figure out the question type of #{choice}" if category.nil?
    
    # Given a question key like :family, show all the messages, in serial. Yes,
    # this can be a long list if the RNG turns against you (eg. up to six evidences
    # left over, and all in one category).
    texts = @my_questions[category]
    texts.each do |text|
      m = "#{@name}: #{text}"
      Game_Interpreter.instance.show_message(m)
      DetectiveGame::instance.notebook.note m
    end
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
  
  # These are the things that may consume evidence signals, so do them after we
  # know how many signals each NPC has. This consumes up to 4 signals max
  # (0-2 in the criminal record, 0-1 in social media, 0-1 in interests)
  def augment_profile
    @criminal_record = generate_criminal_record
    @social_media = generate_social_media_profile
    generate_interests
    @messages << "I like #{@social_media[:post_topic]}!"
  end
  
  def on_victim(love_or_hate, victim)
    raise "Invalid value for on_victim: #{love_or_hate}" unless [:love, :hate].include?(love_or_hate)
    if (love_or_hate == :love)
      @messages << "#{victim.name} was #{['a good person', 'someone we all admired', 'someone I look up to', 'a true friend'].sample}."
    else
      name = victim.name
      pool = ["I hated #{name}!", "#{name} deserved what they got.", "Nobody's going to cry over #{name}'s death.", "I didn't care much for #{name}"]
      @messages << pool.sample
    end
    
    Logger.debug "\t#{@name}'s position on the victim is one of #{love_or_hate}. Here's what they have to say: #{@messages[-1]}"
  end
  
  def resist_talking
    @times_talked_to = 0
    # After not talking this many times, we talk
    @resist_talking_times = rand(2) + 1 # 2-3
    # NPC says these two things
    @resist_messages = RESIST_TALKING_MESSAGES.sample(2)
    Logger.debug "#{@name} will resist talking for #{@resist_talking_times} times."
  end
  
  private
  
  def pick_blood_type
    # Based on cumulative distribution from http://www.redcrossblood.org/learn-about-blood/blood-types
    # O: 48% A: 31% B: 16% AB: 4%    
    blood_picked = rand(100)
    return 'O' if blood_picked < 48 # 48%
    return 'A' if blood_picked < 48 + 31 # 31%
    return 'B' if blood_picked < 48 + 31 + 16 # 16%
    return 'AB' # 4%
  end
  
  ###
  # Generates a random criminal record.
  # For @evidence_count == 0, you either get "no record" or "a few counts of ..."
  # For @evidence_count == 1, you may get as above, or "a short jail sentence"
  # For @evidence_count >= 2, you may get as above, or "several years of combined jail time"
  def generate_criminal_record
    severity = rand(100)
    # 30% nothing, 30% mild, 25% medium, 15% severe
    return "#{@name} has no prior criminal record." if severity < 30
    return "#{@name}'s criminal record contains a few counts of #{ExternalData::instance.get(:negligible_crimes).sample}." if severity < 60 || @evidence_count == 0
    
    # Suspicious criminal record is a signal
    @evidence_count -= 1 # "minor" crimes are worth one evidence count
    return "#{@name} served a short jail sentence for #{ExternalData::instance.get(:minor_crimes).sample}." if severity < 85 || @evidence_count == 0
    
    @evidence_count -= 1 # "major" crimes are worth two evidence counts
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
  
  def generate_interests
    if @evidence_count > 0 && rand(100) < ExternalData::instance.get(:suspicious_interests_probability)
      # TODO: have other people say this about this person, instead of them saying it themselves
      topic = ExternalData::instance.get(:suspicious_interests).sample
      @evidence_count -= 1
    else
      topic = ExternalData::instance.get(:benign_interests).sample
    end
    @messages << "I always found #{topic} fascinating."
    Logger.debug "#{@name} likes #{topic}."
  end
  
  def to_s
    return "#{@name}: #{@evidence_count}"
  end
end