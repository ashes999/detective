# By Ashes999 (github.com/ashes999)
# Creates random NPC via NpcSpawner::create_npc.

require 'scripts/spawn_events'
require 'scripts/models/npc'

class NpcSpawner  
  @@DATA_MAP_ID = 2      # Map with our events that we copy to create people

  def self.data_map_id
    return @@DATA_MAP_ID
  end
  
  def self.spawn(npc)    
    events = Game_Map::instance.events    
    template_id = npc.template_id
    
    # Clone the event into a random spot, unless we saved their spot with the remember_event_position script.    
    if npc.x.nil? || npc.y.nil?
      location = Game_Map::instance.find_random_empty_spot
    else
      location = { :x => npc.x, :y => npc.y }
    end
    
    Game_Map::instance.spawn_event(location[:x], location[:y], template_id, @@DATA_MAP_ID)
    event = events[events.keys[-1]]    
    npc.update_event(event)
    Logger.debug "SPAWNED #{npc} ON MAP #{Game_Map::instance.map_id} AT #{location[:x]}, #{location[:y]}"
    return npc
  end  
end
