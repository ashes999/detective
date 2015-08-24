require 'scripts/logger'
require 'scripts/npc_spawner'
require 'scripts/ui/profiles_scene'
require 'scripts/models/notebook'
require 'scripts/api/vxace_api'
require 'scripts/utils/external_data'

# Not directly used here, but just load them up please. Thanks.
require 'scripts/utils/json_parser'

class DetectiveGame

  # TODO: this is updated by hand :(
  # These are the names of ITEMS in the DB.
  POTENTIAL_MURDER_WEAPONS = ['Sword', 'Pickaxe', 'Vase', 'Pot', 'Shovel']

  # The key for storing this game's data in our save-game.
  DATA_KEY = :detective_game
  attr_reader :npcs, :notebook

  @@instance = nil
  
  def self.instance
    @@instance = DataManager.get(DATA_KEY) || DetectiveGame.new    
    return @@instance
  end
  
  def initialize
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
      @npcs << NpcSpawner::create_npc
    end
  end
  
  # Consider evidence as the thing the player seeks (statements and forensics)
  #
  # "Signal" is the minimum number of pieces of evidence you need to solve this
  # "Noise" is any other evidence that's not signal
  # Difficulty is the metric of how many "signals" you need to solve the case.
  #
  # In Sleuth, you have 3 signal people (two people who's alibis match and an odd man out),
  # and 2 noise people. There are also seven items to look at, one of which is the murder weapon.
  # That brings us to a total of 3 + 1 => 4 signals.
  #
  # Easiest difficulty is three people (A => B, B => A, C => A) + 1 item
  # Keep it simple, and linear; d1 = 3, d10 = 13 (~3x harder)
  # m = 0.5, num_signals = difficulty + 3. Simple, and clean.
  # 
  # To scale difficulty, we do the following:
  #   - 1-3 bloody items (gotta scan all to figure out which is it)
  #   - 
  def generate_scenario(difficulty)
    @killer = @npcs.sample
    @victim = @killer
    @victim = npcs.sample while @victim == @killer
    @victim.die
    
    non_victims = @npcs - [@victim]
    non_killers = non_victims - [@killer]
        
    non_killers.shuffle!
    
    num_signals = 3 + difficulty
    @killer.alibi_person = non_killers.sample
    
    # Pick two random people and link their alibis
    # To deal with odd numbers, make a trio
    while non_killers.size > 0 do
      n1 = non_killers.pop
      n2 = non_killers.pop
      
      if non_killers.size % 2 == 1
        n3 = non_killers.pop
        n1.alibi_person = n2
        n2.alibi_person = n3
        n3.alibi_person = n1
      else
        n1.alibi_person = n2
        n2.alibi_person = n1
      end
    end
    
    @murder_weapon = POTENTIAL_MURDER_WEAPONS.sample
  end
  
  private
  
end