class Notebook
  
  @@instance = nil  
  
  def self.instance
    # May be invoked before initializing; make sure it's not nil
    @@instance ||= Notebook.new    
    return @@instance
  end
  
  def initialize
    @@instance = self
    @notes = []
    
    npcs = DetectiveGame::instance.npcs
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
  
  def status_for(npc_index)
    raw = @npc_status[npc_index]
    # These must match the order in profiles_scene's make_command_list
    return 0 if raw == :suspicious
    return 1 if raw == :unknown
    return 2 if raw == :innocent
    raise "Not sure what status number corresponds to #{npc_index}'s status of #{raw}."
  end
end