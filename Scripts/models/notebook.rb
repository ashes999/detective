class Notebook

  STATUS_MAP = {
    :suspicious => 0,
    :unknown => 1,
    :innocent => 2
  }
  
  def self.STATUS_MAP
    return STATUS_MAP
  end
  
  def initialize(npcs)
    raise 'Can\'t create notebook without NPCs' if npcs.nil? || npcs.count == 0
    @npcs = npcs
    @notes = []
    # Profiles screen just has the NPC index. Blurgh.
    @npc_status = []
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
  
  def notes_for(npc_index)
    npc_name = @npcs[npc_index].name
    to_return = ''
    @notes.each do |n|
      # match the name with word-boundaries (full word)
      to_return = "#{to_return}#{n}\n" if n.match(/\b#{npc_name}/)
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