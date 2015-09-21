require 'scripts/logger'
require 'scripts/npc_spawner'
require 'scripts/name_generator'

require 'scripts/models/notebook'
require 'scripts/models/suspect_npc'
require 'scripts/api/vxace_api'
require 'scripts/utils/external_data'
require 'scripts/evidence_generator'
require 'scripts/utils/enumerable_math'

# Not directly used here, but just load them here so that they're defined when needed.
# UI, mods, extensions, utils, etc.
require 'scripts/utils/json_parser'
require 'scripts/ui/profiles_scene'
require 'scripts/extensions/alternate_talk'

#Font.default_name = ['ArabType']
#Font.default_size = 22

class DetectiveGame
  
  # Potential maps to spawn on. Names don't cut it (not accessible through the API), so we use map IDs.
  # 7-14 are House1-House8
  MANSION_MAP_ID = 1 # Mansion1
  NPC_MAPS = (7..14).to_a + [MANSION_MAP_ID]
  MAP_ID_REGEX = /map (\d+)/i

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

    if ExternalData::instance.key?(:universe)
      seed = ExternalData::instance.get(:universe) 
    else
      srand()
      seed = srand()
    end
    srand(seed)
    Logger.log "New game started in universe ##{seed}"
        
    Logger.logging_level = :debug if ExternalData::instance.get(:debug) == true
    Logger.debug 'Logger.debug mode enabled.'
    
    difficulty = ExternalData::instance.get(:difficulty)
    raise "Difficulty (#{difficulty}) should be in the range of 1-10" if difficulty < 1 || difficulty > 10
    @npc_maps = NPC_MAPS.clone
    
    min_npcs = ExternalData::instance.get(:min_number_of_npcs)
    max_npcs = ExternalData::instance.get(:max_number_of_npcs)
    range = max_npcs - min_npcs    
    
    # map [1..10] to [0..range] (uniform distribution)
    # difficulty of 1 = min_npcs, difficulty of 10 = max_npcs    
    num_npcs = (range * difficulty / 10.0).round    
    num_npcs = rand(range) + min_npcs
    Logger.debug "Generating #{num_npcs} npcs; range was #{min_npcs} to #{max_npcs}"
    @notebook = Notebook.new
    
    # Hash of item_name => map_id (from note)
    @potential_murder_weapons = {}    
    $data_items.each do |i|
      # Nils in the array so strip out nils; also, no note = not specified to a map id = not a murder weapon
      next if i.nil? || i.note == ''
      match = MAP_ID_REGEX.match(i.note)
      raise "Item #{i} has note #{i.note} which doesn't have a map id!" if match.nil?
      map_id = match[1].to_i
      @potential_murder_weapons[i.name] = map_id
    end
    
    generate_npcs(num_npcs)
    generate_scenario(difficulty) 
    
    @notebook.npcs = @npcs
    DataManager.set(DATA_KEY, self)    
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
    @evidences.each { |e| NpcSpawner.spawn(e) if e.map_id == Game_Map::instance.map_id }
  end
  
  private  
  
  def show_murder_weapons_list
    Game_Interpreter.instance.show_message('\N[1]: The murder weapon is ...', :wait => false)    
    weapons_list = []
    $game_party.items.collect { |item| weapons_list << item.name }.compact
    
    if (weapons_list.count > 8)
      # Too big to fit nicely on screen. Batch display it.
      choice = 'Next' # not used
      while weapons_list.count > 0 && (choice == 'Next' || choice == 'Cancel')
        batch = weapons_list[0..7]
        weapons_list -= batch
        if weapons_list.count == 0
          meta = 'Cancel'
        else
          meta = 'Next'
        end
        batch << meta
        choice = Game_Interpreter.instance.show_choices(batch, { :cancel_index => batch.length - 1, :return_type => :name})        
      end
    else
      weapons_list << 'Cancel'
      choice = Game_Interpreter.instance.show_choices(weapons_list, { :cancel_index => weapons_list.length - 1, :return_type => :name})
    end
    
    return choice
  end
  
  def show_suspects_list  
    Game_Interpreter.instance.show_message('\N[1]: The killer is ...', :wait => false)
    npc_names = []
    @npcs.map { |n| npc_names << n.name }
    npc_names << 'Cancel'
    choice = Game_Interpreter.instance.show_choices(npc_names, { :cancel_index => npc_names.length - 1, :return_type => :name})
    return choice
  end
  
  def generate_npcs(num_npcs)
    @npcs = []
    
    num_npcs.times do
      # Decide on a random map where this NPC appears. One NPC per map.
      map_id = @npc_maps.sample
      @npc_maps -= [map_id]
      name = NameGenerator::generate_name
      @npcs << SuspectNpc.new(map_id, name)
      Logger.debug "#{@npcs[-1].name} is on map #{map_id}"
    end
  end
  
  # Signals: things that indicate that a person is the murderer
  # The number of signals is 3 + (2 * difficulty), distributed
  # randomly to NPCs. (The killer gets more signals.)
  def generate_scenario(difficulty)    
    Logger.debug "Difficulty: #{difficulty}"
    @killer = @npcs.sample
    @victim = @killer
    @victim = npcs.sample while @victim == @killer
    @victim.die
    @victim.map_id = MANSION_MAP_ID
    Logger.log "Victim: #{@victim.name}"
    Logger.debug "Killer: #{@killer.name}"
    
    non_victims = @npcs - [@victim]
    non_killers = non_victims - [@killer]       
    non_killers.shuffle!
    
    num_signals = 3 + (2 * difficulty)
    evidence_counts = {}
    generate_signals_and_profiles(num_signals, non_victims, difficulty)
    
    Logger.debug "Initial distribution: #{non_victims} v=#{non_victims.collect { |n| n.evidence_count }.variance}"
    initial_sum = 0
    non_victims.map { |n| initial_sum += n.evidence_count }
    
    non_victims.each { |n| n.augment_profile }
    @victim.evidence_count = rand(2) # 0 or 1 signal, just "for fun"
    @victim.augment_profile
    
    # Everyone needs an alibi. Weak alibis are a signal.
    generate_killers_alibi(non_killers)
    generate_alibis(non_killers)
    murder_weapon_in_whose_house = nil
    # 50% chance to put the murder weapon in the house of an NPC
    if rand(50) <= 100
      # Pick a suitable NPC first
      suitable_npcs = non_victims.select { |n| n.evidence_count >= 2 }
      if !suitable_npcs.empty?
        npc = suitable_npcs.sample
        npc.evidence_count -= 2
        # Pick something on their map as the murder weapon
        @murder_weapon = @potential_murder_weapons.select { |weapon, map| map == npc.map_id }.keys.sample
        Logger.debug "Murder weapon (#{npc.name}'s house): #{@murder_weapon}"
        murder_weapon_in_whose_house = npc
      end
    end
    
    if murder_weapon_in_whose_house.nil?
      # goes in the mansion
      @murder_weapon = @potential_murder_weapons.select { |weapon, map| map == MANSION_MAP_ID }.keys.sample
      Logger.debug "Murder weapon (mansion): #{@murder_weapon}"
    end
    
    raise "Something went terribly wrong with murder weapon selection" if @murder_weapon.nil?
    @evidences = EvidenceGenerator::distribute_evidence(non_victims, @victim, @npc_maps, MANSION_MAP_ID, @notebook, @potential_murder_weapons.keys, @murder_weapon, murder_weapon_in_whose_house)    
    EvidenceGenerator::complete_profiles_with_criminology(non_victims)
    
    Logger.debug '-' * 80
    Logger.debug "Final distribution: #{non_victims}"    
    final_sum = 0
    non_victims.map { |n| final_sum += n.evidence_count }
    Logger.debug "Signals consumed: #{initial_sum - final_sum}"
  end
  
  def generate_signals_and_profiles(num_signals, non_victims, difficulty)
    ###
    # Generate a distribution. For now, just randomly add evidence to NPCs, and
    # when we're done, use the variance to tell how difficult it is. A variance
    # of 6 is pretty big (eg. distro is [6, 6, 12]; more than that is too much.
    # A variance of 2 or less means we have a close distribution, which is good
    # for very difficult games.
    num_signals.times do
      npc = non_victims.sample
      npc.evidence_count += 1
    end
    
    # pick a variance from 6 (d=0) to 1.5 (d=10), uniformly distributed across difficulty
    target_variance = 6 - (difficulty * 4.5 / 10)    
    epsilon = 1
    v = non_victims.collect { |n| n.evidence_count }.variance
    Logger.debug "Target variance is #{target_variance}; starting with #{v}..."
    Logger.debug "\tInitially, we have #{non_victims}"
    
    # Not within epsilon? we need to tweak variance.
    while (v - target_variance).abs >= epsilon
      if v > target_variance
        # Decrease variance. Decrease the max by one and increase the min by one.
        max = max_evidence_npc(non_victims)
        min = min_evidence_npc(non_victims)
        max.evidence_count -= 1
        min.evidence_count += 1 
      else
        # Increase variance. Take two random people and swap. It works. Somehow.
        r1 = non_victims.select { |n| n.evidence_count > 0 }.sample
        r2 = (non_victims - [r1]).sample
        r1.evidence_count -= 1
        r2.evidence_count += 1
      end
      
      v = non_victims.collect { |n| n.evidence_count }.variance      
    end
    Logger.debug "\tFinal variance is #{v} npcs=#{non_victims}"
        
    #
    ### End distribution
    
    # For now, the killer has the most signals. Swap to ensure it.
    non_victims.each do |n|
      if n.evidence_count > @killer.evidence_count
        temp = @killer.evidence_count        
        @killer.evidence_count = n.evidence_count
        n.evidence_count = temp
      end
    end
    
    # If there are other people (non-killers) who also have the same (max) evidence
    # count, then the killer should have one more. (We only apply it in this case,
    # in order to not disturb the evidence_count variance too much.)
    co_counts = non_victims.select { |n| n != @killer && n.evidence_count == @killer.evidence_count }
    @killer.evidence_count += 1 unless co_counts.empty?
  end
  
  def max_evidence_npc(npcs)
    max_npc = npcs.first
    
    npcs.each do |n|
      if n.evidence_count > max_npc.evidence_count
        max_npc = n
      end
    end
    
    return max_npc
  end
  
  def min_evidence_npc(npcs)
    min_npc = npcs.first
    
    npcs.each do |n|
      if n.evidence_count < min_npc.evidence_count
        min_npc = n
      end
    end
    
    return min_npc
  end
  
  def generate_killers_alibi(non_killers)
    data = ExternalData::instance
    npcs_left = []
    non_killers.map { |n| npcs_left << n }
    
    # % chance of having a strong alibi as the killer
    strong_alibi = rand(100) <= data.get(:strong_alibi_probability)
    Logger.debug " Killer's alibi is strong? #{strong_alibi}"
    Logger.debug "Non-killers: #{npcs_left.collect {|n| n.name}}"
    
    if (strong_alibi)      
      # Make a pair, or a "ring" of three people who were together
      # 40% chance to be a ring
      make_ring = true if rand(100) <= data.get(:ring_alibi_probability)
      if make_ring
        n1 = npcs_left.pop
        n2 = npcs_left.pop        
        n1.alibi_person = n2
        n2.alibi_person = @killer
        @killer.alibi_person = n1
        Logger.debug "Killer uses a ring-type alibi: #{@killer.name}, #{n1.name}, #{n2.name}}"
      else
        alibi = npcs_left.pop
        @killer.alibi_person = alibi
        alibi.alibi_person = @killer
        Logger.debug "Killer has a mutual alibi with #{alibi.name}"
      end
    elsif rand(100) <= data.get(:alone_alibi_probability)
      Logger.debug 'Killer claims to be alone as their alibi.'
      @killer.alibi_person = nil
    else
      @killer.evidence_count -= 1 # weak alibi: one indicator
      @killer.alibi_person = npcs_left.sample
      Logger.debug "Killer has an obvious alibi which #{@killer.alibi_person.name} will not verify"
    end
  end
  
  def generate_alibis(non_killers)
    npcs_left = []
    non_killers.map { |n| npcs_left << n }
    
    # Pick two random people and link their alibis
    # To deal with odd numbers, make a trio
    while npcs_left.size > 0 do
      if (npcs_left.count == 1)
        Logger.debug "Loner: #{n3.name} was alone"
        loner = npcs_left.pop
        # It's hard to re-integrate them into a trio. But, we shouldn't get
        # a negative evidence count. They're not the killer, so this won't
        # affect gameplay much (it'll just imbalance evidence_count variance
        # a bit).
        loner.evidence_count -= 1 if loner.evidence_count > 0        
      else
        n1 = npcs_left.pop
        n2 = npcs_left.pop
        
        if npcs_left.size % 2 == 1
          n3 = npcs_left.pop
          if rand(100) <= ExternalData::instance.get(:alone_alibi_probability) && n3.evidence_count > 0
            n1.alibi_person = n2
            n2.alibi_person = n1
            Logger.debug "Alibi: #{n1.name} <=> #{n2.name}"            
            n3.alibi_person = nil
            n3.evidence_count -= 1
            Logger.debug "Alibi: #{n3.name} was alone"
          else
            # ring alibi
            n1.alibi_person = n2
            n2.alibi_person = n3
            n3.alibi_person = n1
            Logger.debug "Alibi: Ring of [#{n1.name}, #{n2.name}, #{n3.name}]"
          end
        else
          Logger.debug "Alibi: #{n1.name} <=> #{n2.name}"
          n1.alibi_person = n2
          n2.alibi_person = n1
        end
      end
    end
  end
end