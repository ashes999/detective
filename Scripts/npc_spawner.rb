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
    events = Game_Map::instance.events    
    # Clone the event into a random spot
    location = Game_Map::instance.find_random_empty_spot      
    template_id = npc.template_id
    Game_Map::instance.spawn_event(location[:x], location[:y], template_id, DATA_MAP_ID)          
    event = events[events.keys[-1]]    
    npc.update_event(event)
    return npc
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
