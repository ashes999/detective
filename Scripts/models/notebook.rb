class Notebook

  STATUS_MAP = {
    :suspicious => 0,
    :unknown => 1,
    :innocent => 2
  }
  
  attr_accessor :murder_weapon_evidence
  
  def self.STATUS_MAP
    return STATUS_MAP
  end
  
  def initialize
    @npcs = []
    @npc_status = []
    @notes = []
    @murder_weapon_evidence = []
  end
  
  def npcs=(npcs)
    raise 'Can\'t create notebook without NPCs' if npcs.nil? || npcs.count == 0
    @npcs = npcs
    
    # Profiles screen just has the NPC index. Blurgh.    
    npcs.each do |n|
      @npc_status << :unknown # start out being unknown
    end
  end
  
  def note(text)    
    @notes << text unless @notes.include?(text)
  end
  
  def notes
    return 'No notes yet.' if @notes.empty?
    to_return = "There are #{@notes.count} notes:\n"
    count = 0
    @notes.each do |n|
      count += 1
      to_return = "#{to_return}#{count}) #{n}\n"
    end
    return to_return
  end
  
  def show_murder_weapon_notes
    @murder_weapon_evidence.map { |e| @notes << e }
  end
  
  def notes_for(who_or_what)
    if who_or_what.key?(:npc_index)
      npc_index = who_or_what[:npc_index]
      name = @npcs[npc_index].name      
    elsif who_or_what.key?(:name)
      # item name? person name? dun matter, yo.
      name = who_or_what[:name]
    else
      raise "Not sure how to get notes for #{who_or_what}. Consider sending in :npc_index or :name"
    end
    
    to_return = ''
    @notes.each do |n|
      # match the name with word-boundaries (full word)      
      to_return = "#{to_return}#{n}\n" if n.match(/\b#{name}\b/)
    end
    return to_return
  end
  
  def status_for(npc_index)
    raw = @npc_status[npc_index]
    # These must match the order in profiles_scene's make_command_list
    raise "Not sure what status number corresponds to #{npc_index}'s status of #{raw}." unless STATUS_MAP.key?(raw)
    return STATUS_MAP[raw]    
  end
  
  def set_npc_status(npc_index, status)
    raise "Invalid status; please send one of #{STATUS_MAP.keys}" unless STATUS_MAP.key?(status)
    @npc_status[npc_index] = status
  end
end