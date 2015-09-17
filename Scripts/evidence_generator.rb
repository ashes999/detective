require 'scripts/models/evidence'

class EvidenceGenerator

  # The maximum number of evidence to spawn/cause, per type
  MAX_SPAWNS = { :npc_blood_pool => 2, :fingerprints => 3, :victims_blood_pool => 1,
  :npc_blood_on_weapon => 2, :npc_fingerprints_on_weapon => 2,
  :resist_talking => 2, :flee_talking => 1, :block_entrance => 1  }
  # IDs of events we copy to spawn these
  EVENT_IDS = { :npc_blood_pool => 2, :fingerprints => 3 }
  
  def initialize
    raise 'Static class!'
  end
  
  # TODO: convert inputs into a hash if this continues to grow  
  # murder_weapon_in_whose_house => nil (murder weapon is in the mansion) or an NPC (in whose house we found the murder weapon)
  def self.distribute_evidence(non_victims, victim, npc_maps, mansion_map_id, notebook, murderable_weapons, murder_weapon, murder_weapon_in_whose_house)
    raise 'Notebook is nil' if notebook.nil?
    # An array of stuff that we need to spawn on the corresponding map.
    # This includes things like fingerprints, pools of blood, etc.
    evidence = []
    
    # TODO: randomize the order of these
    
    ###    
    # These signals are limited (eg. only one pool of the victim's blood)
    ###
    npc_blood_spawned = 0         # NPC's blood in the mansion
    victims_blood_spawned = 0     # Victim's blood in NPC's house/location
    fingerprints_spawned = 0      # NPC's fingerprints in the mansion
    npc_bloodied_weapons = 0      # NPC's blood on the weapon
    npc_fingerprints_weapons = 0  # NPC's fingerprints are on the weapon
    resisting_talking = 0         # NPC won't talk to you for the first 2-3 times.
    
    data = ExternalData::instance
    
    non_victims.each do |npc|
      # TODO: new algorithm for this, no more random
      # 1) Pick the distribution of signals by NPC. This depends on the total.
      #    eg. for D=10, n=4, we get 7, 6, 6 vs. 5, 4, 3, 3, 2, 2
      # 2) Distribute the 19 possible signals we have to those NPCs in that distro.
      #    Make sure it's a random subset, not that the killer always gets "victim_blood_pool".
      # 3) Profit
      
      Logger.debug("Generating evidence for #{npc.name} ...")
      # NPC's blood in the mansion
      if npc.evidence_count >= 1 && npc_blood_spawned < MAX_SPAWNS[:npc_blood_pool]        
        # spawn a pool of blood
        e = BloodPool.new
        e.map_id = mansion_map_id
        e.template_id = EVENT_IDS[:npc_blood_pool]
        e.blood_type = npc.blood_type
        npc.evidence_count -= 1
        evidence << e
        npc_blood_spawned += 1
        Logger.debug("\tGenerated a pool of #{npc.name}'s blood type (#{npc.blood_type}) in the mansion.")
      end
      
      # Victim's blood in the NPC's house/location
      if npc.evidence_count >= 2 && victims_blood_spawned < MAX_SPAWNS[:victims_blood_pool]
        e = BloodPool.new
        e.map_id = npc.map_id
        e.template_id = EVENT_IDS[:npc_blood_pool]
        e.blood_type = victim.blood_type
        npc.evidence_count -= 2
        evidence << e
        victims_blood_spawned += 1
        Logger.debug("\tGenerated a pool of the victim's blood (type #{victim.blood_type}) in #{npc.name}'s dwelling.")
      end
      
      # NPC's fingerprints in the mansion
      if npc.evidence_count > 0 && fingerprints_spawned < MAX_SPAWNS[:fingerprints]
        e = Fingerprints.new
        e.map_id = mansion_map_id
        e.template_id = EVENT_IDS[:fingerprints]
        
        if rand(100) <= data.get(:fingerprints_match)
          e.owner = npc.name          
          # Worth one evidence count, unless it's >= 70% match, in which case,
          # it's worth two evidence counts.
          npc.evidence_count -= 1          
          npc.evidence_count -= 1 if e.match_probability >= 70
          Logger.debug("\tGenerated #{npc.name}'s fingerprints in the mansion")
        else
          e.owner = nil
          Logger.debug("\tGenerated useless fingerprints in the mansion")
        end
        
        evidence << e
        fingerprints_spawned += 1        
      end
      
      # Victim's blood is always on the murder weapon.
      e = "#{victim.name}'s blood is on the #{murder_weapon}"
      e += ", which was in #{murder_weapon_in_whose_house.name}'s house" unless murder_weapon_in_whose_house.nil?
      e += '.'
      notebook.murder_weapon_evidence << e
      Logger.debug(e)
      
      # NPC's blood on the non-murder weapon
      # We do this five times, right? The chance of failure (never happens) is n^5 = 0.1. N = 0.37
      if npc.evidence_count > 0 && npc_bloodied_weapons < MAX_SPAWNS[:npc_blood_on_weapon]
        weapon = murderable_weapons.sample
        
        if weapon == murder_weapon && npc.evidence_count >= 2
          npc.evidence_count -= 2 # strong signal
        else
          weapon = murderable_weapons.sample while weapon == murder_weapon
          npc.evidence_count -= 1
        end
        
        e = "#{npc.name}'s blood is on the #{weapon}."
        notebook.murder_weapon_evidence << e
        Logger.debug "\t#{e}"        
        npc_bloodied_weapons += 1
      end
      
      # NPC's fingerprints on the murder weapon
      # We do this five times, right? The chance of failure (never happens) is n^5 = 0.1. N = 0.37
      if npc.evidence_count > 0 && npc_fingerprints_weapons < MAX_SPAWNS[:npc_fingerprints_on_weapon]
        weapon = murderable_weapons.sample
        
        if weapon == murder_weapon && npc.evidence_count >= 2
          npc.evidence_count -= 2 # strong signal          
        else
          weapon = murderable_weapons.sample while weapon == murder_weapon
          npc.evidence_count -= 1
        end
        
        e = "#{npc.name}'s fingerprints are on the #{weapon}."
        notebook.murder_weapon_evidence << e
        Logger.debug "\t#{e}"
        npc_fingerprints_weapons += 1
      end
      
      # Not sure why we get lots of duplicates here.
      notebook.murder_weapon_evidence.uniq!
      
      if npc.evidence_count > 0 && rand(100) <= 50
        npc.on_victim(:hate, victim)
        npc.evidence_count -= 1
      else
        npc.on_victim(:love, victim)
      end
      
      if npc.evidence_count > 0 && resisting_talking < MAX_SPAWNS[:resist_talking]
        npc.resist_talking
        npc.evidence_count -= 1
      end      
    end    
    
    return evidence
  end  
end
