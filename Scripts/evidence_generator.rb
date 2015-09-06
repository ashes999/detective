require 'scripts/models/evidence'

class EvidenceGenerator

  EVIDENCE_SOURCES = []
  BLOOD_EVENT_ID = 2
  MAX_BLOOD = 2 # Don't spawn more than this
  
  def initialize
    raise 'Static class!'
  end
  
  def self.distribute_evidence(non_victims, npc_maps, mansion_map_id)
    # An array of stuff that we need to spawn on the corresponding map.
    # This includes things like fingerprints, pools of blood, etc.
    evidence = []
    blood_spawned = 0
    
    non_victims.each do |npc|
      #sources = EVIDENCE_SOURCES.sample(npc.evidence_count)
      #sources.each do |s|      
      #end
      
      if npc.evidence_count > 0 && rand(100) <= ExternalData::instance.get(:blood_pool_probability) && blood_spawned < MAX_BLOOD        
        # spawn a pool of blood
        e = BloodPool.new
        e.map_id = mansion_map_id
        e.template_id = BLOOD_EVENT_ID
        e.blood_type = npc.blood_type
        blood_spawned += 1
        evidence << e        
      end
    end
    
    Logger.debug "Evidence is #{evidence}"
    return evidence
  end  
end