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
require 'scripts/models/npc'

class NpcSpawner  
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
