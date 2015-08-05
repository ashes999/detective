# By Ashes999 (github.com/ashes999)
# Creates random NPC via NpcSpawner::create_npc.

# Graphics we can use
### calculated damage spritesheet cells for these actors only; when formula
### derivation continues, you can include more actors. plzkthx.
SPRITESHEETS = [ 'Actor1', 'Actor2' ]
DEATH_SPRITESHEETS = ['Behavior1']
DATA_MAP_ID = 2      # Map with our events that we copy to create people
NPC_TEMPLATE_IDS = [1]    # NPC IDs of events we can copy
NPC_SPEEDS = [2, 3, 4, 5] # slower to faster
NPC_FREQUENCIES = [2, 3, 4] # lower to higher

require 'scripts/spawn_events'
require 'scripts/name_generator'

# A wrapper around the RPG Maker event. It exposes some properties and stuff, and methods like die.
class Npc
  attr_reader :spritesheet_file, :spritesheet_index, :move_speed, :move_frequency, :template_id, :name
  attr_accessor :event
  
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
      show_message "#{@name} is dead ..."
    else
      show_message "#{@name}: Hi! The time is #{Time.new}"
    end
  end
end

class NpcSpawner  
  def self.generate_npcs(n = 6)
    npcs = []
    n.times do
      npcs << create_npc
    end
    npcs.sample.die
  end
  
  def self.create_npc
    npc = Npc.new
    events = $game_map.events    
    # Clone the event into a random spot
    location = find_random_empty_spot      
    template_id = npc.template_id
    $game_map.spawn_event(location[:x], location[:y], template_id, DATA_MAP_ID)          
    event = events[events.keys[-1]]    
    npc.update_event(event)
    return npc
  end
  
  private
  
  # Finds an empty spot. See is_empty? below.
  def self.find_random_empty_spot
    x = rand($game_map.width)
    y = rand($game_map.height)    
    
    while !is_empty?(x, y)      
      x = rand($game_map.width)
      y = rand($game_map.height)
    end    
    
    return {:x => x, :y => y}
  end
  
  # Returns true if the tile has no events on it.
  def self.is_empty?(x, y)
    event_count = $game_map.events_xy(x, y).length  
    # Is it a floor tile? That's all we need.
    #return tile_type($game_map.data[x, y, 0]) == @floor_id && event_count == 0
    return event_count == 0
  end
end

# Used to set event direction, move speed and frequency (extends RPG Maker class)
class Game_Event
  # Access via scripts on an event, eg. $game_map.events[self.event_id].npc
  attr_accessor :npc
  
  # These two are used to randomize event speed
  def move_speed=(value)
    @move_speed = value
  end
  def move_frequency=(value)
    @move_frequency = value
  end
  
  def stop_walking
    @move_type = 0 # stop moving
    @direction_fix = true # don't change direction if talked to    
  end
  
  # 0, 1, or 2 for first, second, or third frame
  def animation_frame=(value)
    @pattern = @original_pattern = value
  end
end
