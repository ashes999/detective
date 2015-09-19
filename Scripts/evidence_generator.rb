require 'scripts/models/evidence'

class EvidenceGenerator

  # The maximum number of evidence to spawn/cause, per type
  MAX_SPAWNS = { :npc_blood_pool => 2, :fingerprints => 3, :victims_blood_pool => 1,
  :npc_blood_on_weapon => 3, :npc_fingerprints_on_weapon => 3, :resist_talking => 2 }
  
  # IDs of events we copy to spawn these
  EVENT_IDS = { :blood_pool => 2, :fingerprints => 3 }
  
  # None of these are mutually exclusive. They can all co-habit a single NPC.
  # But, some of them naturally group into the same type of question. So, keep
  # that, and when the player asks the right question, reveal all facts for that.
  #
  # Ask different questions per-person, based on their criminology signals.
  # signal => question. This is easiest to code/maintain.
  CRIMINOLOGY_SIGNALS = {
    :family => [:single, :divorced, :absent_father, :childhood_abuse, :loners]    
  }
  
  # Human-readable versions of our criminology signals. Make sure these match
  # the above list.
  CRIMINOLOGY_TEXTS = {
    :single => 'What family? I\'m single.',
    :divorced => 'I\'m divorced.',
    :absent_father => 'My father was never around when I was young.',
    :childhood_abuse => 'My parents used to beat me when they got drunk.',
    :loners => 'We moved around from homeless shelter to homeless shelter. I never had friends.'
  }
  
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
    
    evidence_available = []
    MAX_SPAWNS.each do |evidence, max_spawns|
      max_spawns.times do
        evidence_available << evidence
      end    
    end
    
    data = ExternalData::instance
    evidence_per_npc = (evidence_available.count / non_victims.count).ceil
    
    non_victims.each do |npc|
      # Pick a random set of evidence for this NPC, in the amount they should have.
      # Don't allow duplicates. If we didn't get enough items, s'ok, we'll consume
      # the rest of the evidence_count when we generate personality/discussion stuff.
      # Similarly, if we don't have enough evidence_count for something, put it
      # back in the pool, and move on.
      
      # Pad by +1 in the hope of getting more uniques
      npcs_evidence = evidence_available.sample(evidence_per_npc + 1).uniq
      evidence_available -= npcs_evidence
      
      Logger.debug("Generating evidence for #{npc.name}; their draw of #{evidence_per_npc}: #{npcs_evidence}")
      
      # NPC's blood in the mansion
      if npc.evidence_count >= 1 && npcs_evidence.include?(:npc_blood_pool)
        # spawn a pool of blood
        e = BloodPool.new
        e.map_id = mansion_map_id
        e.template_id = EVENT_IDS[:blood_pool]
        e.blood_type = npc.blood_type
        npc.evidence_count -= 1
        evidence << e        
        Logger.debug("\tGenerated a pool of #{npc.name}'s blood type (#{npc.blood_type}) in the mansion.")
        npcs_evidence.delete(:npc_blood_pool)
      end
      
      # Victim's blood in the NPC's house/location
      if npc.evidence_count >= 2 && npcs_evidence.include?(:victims_blood_pool)
        e = BloodPool.new
        e.map_id = npc.map_id
        e.template_id = EVENT_IDS[:blood_pool]
        e.blood_type = victim.blood_type
        npc.evidence_count -= 2
        evidence << e        
        Logger.debug("\tGenerated a pool of the victim's blood (type #{victim.blood_type}) in #{npc.name}'s dwelling.")
        npcs_evidence.delete(:victims_blood_pool)
      end
      
      # NPC's fingerprints in the mansion
      if npc.evidence_count > 0 && npcs_evidence.include?(:fingerprints)
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
          npcs_evidence.delete(:fingerprints)
        else
          e.owner = nil
          Logger.debug("\tGenerated useless fingerprints in the mansion")
        end
        
        evidence << e        
      end
      
      # Victim's blood is always on the murder weapon.
      e = "#{victim.name}'s blood is on the #{murder_weapon}"
      e += ", which was in #{murder_weapon_in_whose_house.name}'s house" unless murder_weapon_in_whose_house.nil?
      e += '.'
      notebook.murder_weapon_evidence << e
      Logger.debug(e)
      
      # NPC's blood on the non-murder weapon
      # We do this five times, right? The chance of failure (never happens) is n^5 = 0.1. N = 0.37
      if npc.evidence_count > 0 && npcs_evidence.include?(:npc_blood_on_weapon)
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
        npcs_evidence.delete(:npc_blood_on_weapon)
      end
      
      # NPC's fingerprints on the murder weapon
      # We do this five times, right? The chance of failure (never happens) is n^5 = 0.1. N = 0.37
      if npc.evidence_count > 0 && npcs_evidence.include?(:npc_fingerprints_on_weapon)
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
        npcs_evidence.delete(:npc_fingerprints_on_weapon)
      end
      
      # Not sure why we get lots of duplicates here.
      notebook.murder_weapon_evidence.uniq!
      
      if npc.evidence_count > 0 && rand(100) <= 50
        npc.on_victim(:hate, victim)
        npc.evidence_count -= 1
      else
        npc.on_victim(:love, victim)
      end
      
      if npc.evidence_count > 0 && npcs_evidence.include?(:resist_talking)
        npc.resist_talking
        npc.evidence_count -= 1
        npcs_evidence.delete(:resist_talking)
      end
      
      if !npcs_evidence.empty?
        Logger.debug "Refunding unusable evidence for #{npc.name}: #{npcs_evidence}"
        evidence_available += npcs_evidence
      end
    end    
    
    return evidence
  end
  
  ###
  # we ran distribute_evidence to generate "hard" evidence, like blood and fingerprints.
  # Now, if NPCs have any evidence_count left, fill it with criminology signals.
  # For reference, these come from: https://github.com/deengames/detective/issues/5
  ###
  def EvidenceGenerator::complete_profiles_with_criminology(non_victims)    
    reverse_criminology = {} # Used to figure out unique questions askable for an NPC    
    flattened_criminology = [] # Used to randomly pick signals
    
    CRIMINOLOGY_SIGNALS.each do |question, signals|
      signals.each do |signal|
        reverse_criminology[signal] = question
        flattened_criminology << signal
      end    
    end
    
    non_victims.each do |npc|      
      signals = flattened_criminology.sample(npc.evidence_count)
      Logger.debug("\t#{npc.name} has #{signals.count} criminology signals: #{signals}.")
      npc.answer_questions(signals, reverse_criminology, CRIMINOLOGY_TEXTS) unless signals.empty?
    end
  end
end
