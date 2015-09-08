require 'scripts/models/evidence'

class EvidenceGenerator

  EVIDENCE_SOURCES = []
  # IDs of events we copy to spawn these
  EVENT_IDS = { :blood => 2, :fingerprints => 3 }
  # The maximum number of evidence to spawn, per type
  MAX_SPAWNS = { :blood => 2, :fingerprints => 3, :victims_blood => 1 }
  
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
    victims_blood_spawned = 0
    fingerprints_spawned = 0
    
    data = ExternalData::instance
    non_victims.each do |npc|
      # TODO: while-loop (evidence_count > 0) plzkthx
      # Also, randomize evidence, don't go in order (blood, fingerprints, etc.)
      # Maybe put all types in an array, and sample(x) and then generate those.
      
      # NPC's blood in the mansion
      if npc.evidence_count >= 1 && rand(100) <= data.get(:blood_pool_probability) && blood_spawned < MAX_SPAWNS[:blood]        
        # spawn a pool of blood
        e = BloodPool.new
        e.map_id = mansion_map_id
        e.template_id = EVENT_IDS[:blood]
        e.blood_type = npc.blood_type
        npc.evidence_count -= 1
        evidence << e
        blood_spawned += 1
        Logger.debug("Generating a pool of #{npc.name}'s blood type in the mansion.")
      end
      
      # Victim's blood in the NPC's house/location
      if npc.evidence_count >= 2 && rand(100) <= data.get(:victims_blood_pool_probability) && victims_blood_spawned < MAX_SPAWNS[:victims_blood]
        e = BloodPool.new
        e.map_id = npc.map_id
        e.template_id = EVENT_IDS[:blood]
        e.blood_type = npc.blood_type
        npc.evidence_count -= 2
        evidence << e
        victims_blood_spawned += 1
        Logger.debug("Generating a pool of the victim's blood in #{npc.name}'s dwelling.")
      end
      
      # NPC's fingerprints in the mansion
      if npc.evidence_count > 0 && rand(100) <= data.get(:fingerprints_probability) && fingerprints_spawned < MAX_SPAWNS[:fingerprints]
        e = Fingerprints.new
        e.map_id = mansion_map_id
        e.template_id = EVENT_IDS[:fingerprints]
        
        if rand(100) <= data.get(:fingerprints_match)
          e.owner = npc.name
          
          # Worth one evidence count, unless it's >= 70% match, in which case,
          # it's worth two evidence counts.
          npc.evidence_count -= 1          
          npc.evidence_count -= 1 if e.match_probability >= 70
          Logger.debug("Generating #{npc.name}'s fingerprints in the mansion")
        else
          e.owner = nil
          Logger.debug("Generating useless fingerprints in the mansion")
        end
        
        evidence << e
        fingerprints_spawned += 1        
      end
    end
    
    return evidence
  end  
end