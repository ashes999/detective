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
end
  
# A pool of blood. Someone's blood.
class BloodPool < Evidence
  attr_accessor :blood_type
  
  def on_interact
    Game_Interpreter::instance.show_message "You see a pool of blood. You send it to the lab. It comes back as blood type '#{@blood_type}.'"
    DetectiveGame::instance.notebook.note("You found a pool of blood type #{@blood_type} in the manor.")
  end
end

class Fingerprints < Evidence
  attr_accessor :owner, :match_probability
  
  def initialize
    @match_probability = rand(40) + 50 # 50-90%    
  end
  
  def on_interact
    if (@owner.nil?)
      # poor-quality or the owner is not registered in the International DNA Database.
      match = "They were too poor-quality to match any of the suspects' fingerprints."      
    else
      match = "There's a #{@match_probability}% chance that they're #{@owner}'s fingerprints."
      
    end
    
    Game_Interpreter::instance.show_message "You send the fingerprinted-object to the International DNA Database. #{match}"
    DetectiveGame::instance.notebook.note("You found fingerprints in the manor. #{match}") unless @owner.nil?
  end
end
