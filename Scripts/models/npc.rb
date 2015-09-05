# A wrapper around the RPG Maker event. It exposes some properties and stuff, and methods like die.
# It also has a name, which is randomly generated. Yes, really.
class Npc
  
  # attributes we need to physically appear on-screen properly and walk around
  attr_reader :spritesheet_file, :spritesheet_index, :move_speed, :move_frequency, :template_id
  attr_accessor :event
  
  # "real" model attributes about who we are and stuff
  attr_reader :name
  
  # Graphics we can use
  ### calculated damage spritesheet cells for these actors only; when formula
  ### derivation continues, you can include more actors. plzkthx.
  SPRITESHEETS = [ 'Actor1', 'Actor2' ]
  DEATH_SPRITESHEETS = ['Behavior1']
  NPC_TEMPLATE_IDS = [1]    # NPC IDs of events we can copy
  NPC_SPEEDS = [2, 3, 4, 5] # slower to faster
  NPC_FREQUENCIES = [2, 3, 4] # lower to higher
  
  # move_speed = 1-6
  # move_frequency = 1-5
  # spritesheet_file is the filename used for the graphic, eg. Actor1.
  # spritesheet_index is the base 0 index (0-7; first row, then second row)
  # template_id is the ID of the event we're copying, on map with the ID specified in NpcSpawner::DATA_MAP_ID
  def initialize(name, spritesheet_file = nil, spritesheet_index = nil, template_id = nil, npc_speed = nil, npc_frequency = nil)
    @spritesheet_file = spritesheet_file || SPRITESHEETS.sample
    @spritesheet_index = spritesheet_index || rand(8) # 8 indicies/characters per graphic
    @template_id = template_id || NPC_TEMPLATE_IDS.sample
    @move_speed = move_speed || NPC_SPEEDS.sample
    @move_frequency = move_frequency || NPC_FREQUENCIES.sample    
    @death_spritesheet = @spritesheet_file == 'Actor1' || @spritesheet_file == 'Actor2' ? DEATH_SPRITESHEETS[0] : UNKNOWN    
    @name = name
    @map_id = map_id
    @dead = false
  end
  
  # set event up correctly with graphics, speed, etc. so it looks like us
  def update_event(event)    
    @event = event    
    @event.set_graphic(@spritesheet_file, @spritesheet_index)    
    @event.move_speed = @move_speed
    @event.move_frequency = @move_frequency
    @event.npc = self    
    
    if @dead == true
      # show death
      sheet_num = @spritesheet_file[5, @spritesheet_file.length].to_i # the "2" in "Actor2"
      index = (@spritesheet_index / 4) + (2 * (sheet_num - 1))    
      @event.set_graphic(@death_spritesheet, index)
      # 2 = down, 4 = left, 6 = right, 8 = up
      # direction is used to pick the right sprite on the Damage/Behavior spritesheets
      # We want the middle of three frames
      @event.set_direction 2 * ((@spritesheet_index % 4) + 1)    
      @event.stop_walking
      @event.animation_frame = 0 # the most dead-looking.
    end
  end
  
  def die
    @dead = true
    update_event(@event) unless @event.nil?    
  end  
  
  def talk    
    message = 'Hi.'
    Game_Interpreter.instance.show_message(message)
    DetectiveGame::instance.notebook.note(message)
  end
  
  def x
    return nil if @event.nil?
    return @event.x
  end
  
   def y
    return nil if @event.nil?
    return @event.y
  end
end