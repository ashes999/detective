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
end