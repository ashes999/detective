require 'scripts/logger'
require 'scripts/npc_spawner'

# Other requires just to load the codez; not used below
require 'scripts/models/notebook'

class DetectiveGame
  def self.generate_scenario(num_npcs = 6)
    
    npcs = []
    
    num_npcs.times do
      npcs << NpcSpawner::create_npc
    end
    
    @@killer = npcs.sample
    @@victim = @@killer
    @@victim = npcs.sample while @@victim == @@killer
    @@victim.die

    Logger.log "Killer: #{@@killer.name}"
    Logger.log "Victim: #{@@victim.name}"
    
    non_victims = npcs - [@@victim]
    non_killers = non_victims - [@@killer]
    
    raise "Need an even number of people for this scenario" if non_killers.size % 2 == 1
    non_killers.shuffle!    
    @@killer.alibi_person = non_killers.sample
    
    while non_killers.size > 0 do
      n1 = non_killers.pop
      n2 = non_killers.pop      
      n1.alibi_person = n2
      n2.alibi_person = n1
    end
  end
end