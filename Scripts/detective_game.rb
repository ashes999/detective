require 'scripts/logger'
require 'scripts/npc_spawner'

# Other requires just to load the codez; not used below
require 'scripts/models/notebook'

class DetectiveGame

  # TODO: this is updated by hand :(
  # These are the names of ITEMS in the DB.
  POTENTIAL_MURDER_WEAPONS = ['Sword', 'Pickaxe', 'Vase', 'Pot', 'Shovel']
  
  attr_reader :npcs

  @@instance = nil
  
  def initialize
    @@instance = self
  end
  
  def self.instance
    return @@instance
  end
  
  def generate_scenario(num_npcs = 6)    
    raise "Need an even number of people for this scenario" if num_npcs % 2 == 1
    generate_npcs(num_npcs)
    pick_murder_weapon
  end
  
  # Changes the close-up image of the murder weapon to the blood-streaked one
  def got_magnifying_glass
    for item in $data_items do
      next if item.nil?
      if item.name == @murder_weapon
        murder_item = item 
        break
      end
    end
    
    raise "Can't find item named #{@murder_weapon} for murder weapon" if murder_item.nil?
    murder_item.image = "inventory\\#{murder_item.name}-blood"
  end
  
  private
  
  def pick_murder_weapon
    @murder_weapon = POTENTIAL_MURDER_WEAPONS.sample
    Logger.log("Murder weapon: #{@murder_weapon}")
  end
  
  
  def generate_npcs(num_npcs)
    @npcs = []
    
    num_npcs.times do
      @npcs << NpcSpawner::create_npc
    end
    
    @killer = @npcs.sample
    @victim = @killer
    @victim = npcs.sample while @victim == @killer
    @victim.die

    Logger.log "Killer: #{@killer.name}"
    Logger.log "Victim: #{@victim.name}"
    
    non_victims = @npcs - [@victim]
    non_killers = non_victims - [@killer]
        
    non_killers.shuffle!    
    @killer.alibi_person = non_killers.sample
    
    # Pick two random people and link their alibis
    while non_killers.size > 0 do
      n1 = non_killers.pop
      n2 = non_killers.pop      
      n1.alibi_person = n2
      n2.alibi_person = n1
    end
  end
end