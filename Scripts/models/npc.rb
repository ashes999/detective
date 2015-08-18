require 'scripts/name_generator'

# A wrapper around the RPG Maker event. It exposes some properties and stuff, and methods like die.
class Npc
  
  # attributes we need to physically appear on-screen properly and walk around
  attr_reader :spritesheet_file, :spritesheet_index, :move_speed, :move_frequency, :template_id
  attr_accessor :event
  
  # "real" model attributes about who we are and stuff  
  attr_reader :name
  attr_accessor :alibi_person
  
  # spritesheet_file is the filename used for the graphic, eg. Actor1.
  # spritesheet_index is the base 0 index (0-7; first row, then second row)
  # template_id is the ID of the event we're copying, on map with ID=DATA_MAP_ID
  def initialize(spritesheet_file = nil, spritesheet_index = nil, template_id = nil, npc_speed = nil, npc_frequency = nil)
    @spritesheet_file = spritesheet_file || SPRITESHEETS.sample
    @spritesheet_index = spritesheet_index || rand(8) # 8 indicies/characters per graphic
    @template_id = template_id || NPC_TEMPLATE_IDS.sample
    @move_speed = move_speed || NPC_SPEEDS.sample
    @move_frequency = move_frequency || NPC_FREQUENCIES.sample    
    @death_spritesheet = @spritesheet_file == 'Actor1' || @spritesheet_file == 'Actor2' ? DEATH_SPRITESHEETS[0] : UNKNOWN    
    @name = NameGenerator::generate_name
    @dead = false
  end
  
  def update_event(event)
    @event = event
    # set @event up correctly with graphics, speed, etc.
    @event.set_graphic(@spritesheet_file, @spritesheet_index)    
    @event.move_speed = @move_speed
    @event.move_frequency = @move_frequency
    @event.npc = self
  end
  
  def die
    @dead = true
    # show death
    sheet_num = @spritesheet_file[5, @spritesheet_file.length].to_i # the "2" in "Actor2"
    index = (@spritesheet_index / 4) + (2 * (sheet_num - 1))    
    @event.set_graphic(@death_spritesheet, index)
    # 2 = down, 4 = left, 6 = right, 8 = up
    # direction is used to pick the right sprite on the Damage/Behavior spritesheets
    @event.set_direction 2 * ((@spritesheet_index % 4) + 1)    
    @event.stop_walking
    @event.animation_frame = 0 # the most dead-looking.
  end  
  
  def talk    
    if @dead
      message = "#{@name} is dead ..."
    else
      message = "#{@name}: I was with #{@alibi_person.name} all day."
    end
    show_message message    
    DetectiveGame::instance.notebook.note(message)
  end
end