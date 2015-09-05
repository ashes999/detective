class EvidenceGenerator

  EVIDENCE_SOURCES = []
  BLOOD_EVENT_ID = 2
  
  def initialize
    raise 'Static class!'
  end
  
  def self.distribute_evidence(non_victims, npc_maps)
    # An array of stuff that we need to spawn on the corresponding map.
    # This includes things like fingerprints, pools of blood, etc.
    evidence = []
    
    non_victims.each do |npc|
      #sources = EVIDENCE_SOURCES.sample(npc.evidence_count)
      #sources.each do |s|      
      #end
      
      if rand(100) <= 100
        # spawn a pool of blood
        e = Evidence.new
        e.map_id = npc_maps.sample
        e.template_id = BLOOD_EVENT_ID
        evidence << e
      end
    end
    
    Logger.debug "Evidence is #{evidence}"
    return evidence
  end  
end

class Evidence
  attr_accessor :template_id, :map_id
  
  def update_event(event)
    # Do whatever you need to the appearance/code of this event
    @event = event
    @event.save_pos # persist when you leave/re-enter the map    
  end
  
  def x
    return nil if @event.nil?
    return @event.x
  end
  
   def y
    return nil if @event.nil?
    return @event.y
  end
  
  def to_s
    return "Blood at (#{@x}, #{@y}) on map #{@map_id}"
  end
end
  