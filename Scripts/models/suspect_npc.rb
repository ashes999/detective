require 'scripts/name_generator'
require 'scripts/models/npc'

# A wrapper around the RPG Maker event. It exposes some properties and stuff, and methods like die.
class SuspectNpc < Npc
    
  attr_accessor :alibi_person, :map_id, :age, :profession
  
  NPC_PROFESSIONS = ['janitor', 'programmer', 'accountant', 'business analyst', 'personal trainer', 'CEO', 'teacher', 'cop', 'journalist']
  BLOOD_TYPES = ['A', 'B', 'AB', 'O']
  
  # move_speed = 1-6
  # move_frequency = 1-5
  # spritesheet_file is the filename used for the graphic, eg. Actor1.
  # spritesheet_index is the base 0 index (0-7; first row, then second row)
  # template_id is the ID of the event we're copying, on map with ID=DATA_MAP_ID
  def initialize(map_id, name, spritesheet_file = nil, spritesheet_index = nil, template_id = nil, npc_speed = nil, npc_frequency = nil)
    super(name, spritesheet_file, spritesheet_index, template_id, npc_speed, npc_frequency)
    @map_id = map_id
    
    # basic facts
    @profession = NPC_PROFESSIONS.sample
    @blood_type = BLOOD_TYPES.sample
    @age = 20 + rand(15)    
  end
 
  def talk    
    if @dead
      message = "#{@name} is dead ..."
    else
      message = "#{@name}: I was with #{@alibi_person.name} all day."
    end
    Game_Interpreter.instance.show_message(message)
    DetectiveGame::instance.notebook.note(message)
  end
  
  def profile
    return "#{@name} is a #{@age} year-old #{@profession} with blood type #{@blood_type}."
  end
end