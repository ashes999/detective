require 'scripts/logger'
require 'scripts/npc_spawner'
require 'scripts/name_generator'
require 'scripts/ui/profiles_scene'
require 'scripts/models/notebook'
require 'scripts/models/suspect_npc'
require 'scripts/api/vxace_api'
require 'scripts/utils/external_data'

# Not directly used here, but just load them up please. Thanks.
require 'scripts/utils/json_parser'

class DetectiveGame

  # TODO: this is updated by hand :(
  # These are the names of ITEMS in the DB.
  POTENTIAL_MURDER_WEAPONS = ['Sword', 'Pickaxe', 'Vase', 'Pot', 'Shovel']
  
  # Potential maps to spawn on. Names don't cut it (not accessible through the API), so we use map IDs.
  # 7-14 are House1-House8
  MANSION_MAP_ID = 1 # Mansion1
  NPC_MAPS = (7..14).to_a + [MANSION_MAP_ID]

  # The key for storing this game's data in our save-game.
  DATA_KEY = :detective_game
  attr_reader :npcs, :notebook

  @@instance = nil
  
  def self.instance
    @@instance = DataManager.get(DATA_KEY) || DetectiveGame.new  
    return @@instance
  end
  
  def initialize
    Logger.log('---------------------------------------------------')
    Logger.log('New game started')
    @debug = ExternalData::instance.get(:debug)
    debug 'Debug mode enabled.'
    
    difficulty = ExternalData::instance.get(:difficulty)
    raise "Difficulty (#{difficulty}) should be in the range of 1-10" if difficulty < 1 || difficulty > 10
    
    min_npcs = ExternalData::instance.get(:min_number_of_npcs)
    max_npcs = ExternalData::instance.get(:max_number_of_npcs)
    range = max_npcs - min_npcs
    
    # map [1..10] to [0..range] (uniform distribution)
    # difficulty of 1 = min_npcs, difficulty of 10 = max_npcs    
    num_npcs = (range * difficulty / 10.0).round    
    num_npcs = rand(range) + min_npcs            
  
    generate_npcs(num_npcs)
    generate_scenario(difficulty) 
    
    @notebook = Notebook.new(@npcs)
    DataManager.set(DATA_KEY, self)
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
    # change big picture in inventory for this item to the blood-splattered one
    murder_item.image = "inventory\\#{murder_item.name}-blood"
  end
  
  def solve_case
    suspect = show_suspects_list
    if suspect != 'Cancel'
      weapon = show_murder_weapons_list
      if weapon != 'Cancel'
        if suspect == @killer.name && weapon == @murder_weapon
          Game_Interpreter.instance.show_message("#{@killer.name}: ARGH! Yes, I killed #{@victim.name} with the #{@murder_weapon}!")
        else
          Game_Interpreter.instance.show_message("#{@killer.name}: WRONG! I killed #{@victim.name} with the #{@murder_weapon}! You die!")
        end
        
        Game_Interpreter.instance.game_over
      end
    end
  end
  
  def spawn_this_maps_npcs
    @npcs.each { |n| NpcSpawner.spawn(n) if n.map_id == Game_Map::instance.map_id  }
  end
  
  private  
  
  def show_murder_weapons_list
    Game_Interpreter.instance.show_message('What\'s the murder weapon?', :wait => false)
    weapons_list = ['Cancel']
    POTENTIAL_MURDER_WEAPONS.map { |w| weapons_list << w }
    choice = Game_Interpreter.instance.show_choices(weapons_list, { :cancel_index => 0, :return_type => :name})
    return choice
  end
  
  def show_suspects_list  
    Game_Interpreter.instance.show_message('Who\'s the killer?', :wait => false)
    npc_names = ['Cancel']
    @npcs.map { |n| npc_names << n.name }
    choice = Game_Interpreter.instance.show_choices(npc_names, { :cancel_index => 0, :return_type => :name})
    return choice
  end
  
  def generate_npcs(num_npcs)
    @npcs = []
    
    num_npcs.times do
      map_id = NPC_MAPS.sample
      name = NameGenerator::generate_name
      @npcs << SuspectNpc.new(map_id, name)
      Logger.log("#{@npcs[-1].name} is on map #{map_id}")
    end
  end
  
  # Signals: things that indicate that a person is the murderer
  # The number of signals is 3 + (2 * difficulty), distributed
  # randomly to NPCs. (The killer gets more signals.)
  def generate_scenario(difficulty)    
    debug "Difficulty: #{difficulty}"
    @killer = @npcs.sample
    @victim = @killer
    @victim = npcs.sample while @victim == @killer
    @victim.die
    @victim.map_id = MANSION_MAP_ID
    Logger.log "Victim: #{@victim.name}"
    debug "Killer: #{@killer.name}"
    
    non_victims = @npcs - [@victim]
    non_killers = non_victims - [@killer]
        
    non_killers.shuffle!
    
    num_signals = 3 + (2 * difficulty)
    signal_counts = {}
    
    num_signals.times do |i|
      npc = non_victims.sample
      npc.signal_count += 1      
    end
    
    # For now, the killer has the most signals. Swap.
    non_victims.each do |n|
      if n.signal_count > @killer.signal_count
        temp = @killer.signal_count        
        @killer.signal_count = n.signal_count
        n.signal_count = temp
      end
    end
    
    # Make sure nobody ties with us. Always be one more.
    @killer.signal_count += 1
    debug "Signal distribution: #{non_victims}"
    
    generate_alibis(non_killers)    
    @murder_weapon = POTENTIAL_MURDER_WEAPONS.sample
    debug "Murder weapon: #{@murder_weapon}"
  end
  
  private
  
  def generate_alibis(non_killers)  
    # % chance of having a strong alibi as the killer
    strong_alibi = rand(100) <= ExternalData::instance.get(:strong_alibi_probability)
    debug " Killer's alibi is strong? #{strong_alibi}"
    debug "Non-killers: #{non_killers.collect {|n| n.name}}"
    
    if (strong_alibi)      
      # Make a pair, or a "ring" of three people who were together
      # 40% chance to be a ring
      make_ring = true if rand(100) <= 40
      if make_ring
        n1 = non_killers.pop
        n2 = non_killers.pop        
        n1.alibi_person = n2
        n2.alibi_person = @killer
        @killer.alibi_person = n1
        debug "Killer uses a ring-type alibi: #{@killer.name}, #{n1.name}, #{n2.name}}"
      elsif rand(100) <= ExternalData::instance.get(:alone_alibi_probability)
        debug 'Killer claims to be alone as their alibi.'
        @killer.alibi_person = nil
      else
        alibi = non_killers.pop
        @killer.alibi_person = alibi
        alibi.alibi_person = @killer
        debug "Killer has a mutual alibi with #{alibi.name}"
      end
    else
      @killer.signal_count -= 1 # weak alibi: one indicator
      @killer.alibi_person = non_killers.sample
      debug "Killer has an obvious alibi which #{@killer.alibi_person.name} will not verify"
    end
    
    # Pick two random people and link their alibis
    # To deal with odd numbers, make a trio
    while non_killers.size > 0 do
      if (non_killers.count == 1)
        loner = non_killers.pop
        loner.alibi_person = nil
        loner.signal_count -= 1
      else
        n1 = non_killers.pop
        n2 = non_killers.pop
        
        if non_killers.size % 2 == 1
          if rand(100) <= ExternalData::instance.get(:alone_alibi_probability)
            n1.alibi_person = n2
            n2.alibi_person = n1
            debug "Alibi: #{n1.name} <=> #{n2.name}"
            n3 = non_killers.pop
            n3.alibi_person = nil
            n3.signal_count -= 1
            debug "Alibi: #{n3.name} was alone"
          else
            # ring alibi
            n3 = non_killers.pop
            n1.alibi_person = n2
            n2.alibi_person = n3
            n3.alibi_person = n1
            debug "Alibi: Ring of [#{n1.name}, #{n2.name}, #{n3.name}]"
          end
        else
          debug "Alibi: #{n1.name} <=> #{n2.name}"
          n1.alibi_person = n2
          n2.alibi_person = n1
        end
      end
    end
  end
  
  def debug(message)
    Logger.log(message) if @debug == true
  end
  
end