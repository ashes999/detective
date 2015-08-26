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
  def self.spawn(npc)    
    events = Game_Map::instance.events    
    template_id = npc.template_id
    
    # Clone the event into a random spot, unless we saved their spot with the remember_event_position script.    
    if npc.x.nil? || npc.y.nil?
      location = Game_Map::instance.find_random_empty_spot
    else
      location = { :x => npc.x, :y => npc.y }
    end    
    Game_Map::instance.spawn_event(location[:x], location[:y], template_id, DATA_MAP_ID)          
    event = events[events.keys[-1]]    
    npc.update_event(event)
    return npc
  end  
end
