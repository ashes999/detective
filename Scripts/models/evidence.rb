#####
# Hierarchy of evidence; Evidence class is common/base stuff.
#####

# Add an "evidence" field to the event class, so we can keep all our code externalized
class Game_Event
  # Access via scripts on an event, eg. $game_map.events[self.event_id].evidence
  attr_accessor :evidence
end

class Evidence
  attr_accessor :template_id, :map_id
  
  def update_event(event)
    # Do whatever you need to the appearance/code of this event
    @event = event
    @event.save_pos # persist when you leave/re-enter the map 
    @event.evidence = self
  end
  
  def x
    return nil if @event.nil?
    return @event.x
  end
  
   def y
    return nil if @event.nil?
    return @event.y
  end
  
  def on_interact
    # Override: what happens if you walk up to this evidence and press space?
  end
  
  def to_s
    return "Blood at (#{@x}, #{@y}) on map #{@map_id}"
  end
end
  
# A pool of blood. Someone's blood.
class BloodPool < Evidence
  attr_accessor :blood_type
  
  def on_interact
    Game_Interpreter::instance.show_message "You see a pool of blood. Your phone scans it and registers it as blood type '#{blood_type}.'"
    DetectiveGame::instance.notebook.note("You found a pool of blood type #{blood_type} in the manor.")
  end
end
