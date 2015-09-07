require 'scripts/models/evidence'

class EvidenceGenerator

  EVIDENCE_SOURCES = []
  BLOOD_EVENT_ID = 2
  MAX_BLOOD_POOLS = 2 # Don't spawn more than this
  
  def initialize
    raise 'Static class!'
  end
  
  def self.distribute_evidence(non_victims, npc_maps, mansion_map_id)
    # An array of stuff that we need to spawn on the corresponding map.
    # This includes things like fingerprints, pools of blood, etc.
    evidence = []
    
    # We spawn up to MAX_BLOOD_POOLS pools in the mansion. Obviously, finding
    # someone's blood in the same place as a dead body is pretty good evidence.
    blood_spawned = 0
    
    # is there a pool of the victim's blood in your house/location? That's a signal.
    spawned_victims_blood_pool = false     
    
    data = ExternalData::instance
    non_victims.each do |npc|
      #sources = EVIDENCE_SOURCES.sample(npc.evidence_count)
      #sources.each do |s|      
      #end
      
      # TODO: while-loop (evidence_count > 0) plzkthx
      if npc.evidence_count > 0 && rand(100) <= data.get(:blood_pool_probability) && blood_spawned < MAX_BLOOD_POOLS        
        # spawn a pool of blood
        e = BloodPool.new
        e.map_id = mansion_map_id
        e.template_id = BLOOD_EVENT_ID
        e.blood_type = npc.blood_type
        npc.evidence_count -= 1
        evidence << e
        blood_spawned += 1
        Logger.debug("Generating a pool of #{npc.name}'s blood type in the mansion.")
      end
      
      if npc.evidence_count > 0 && rand(100) <= data.get(:victims_blood_pool_probability) && spawned_victims_blood_pool == false        
        e = BloodPool.new
        e.map_id = npc.map_id
        e.template_id = BLOOD_EVENT_ID
        e.blood_type = npc.blood_type
        npc.evidence_count -= 1
        evidence << e
        spawned_victims_blood_pool = true
        Logger.debug("Generating a pool of the victim's blood in #{npc.name}'s dwelling.")
      end
    end
    
    return evidence
  end  
end