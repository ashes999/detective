class Notebook
  
  @@instance = nil  
  
  def self.instance
    @@instance ||= Notebook.new
    Logger.log("NB instance is #{@@instance}")
    return @@instance
  end
  
  def initialize    
    @notes = []
    Logger.log("New NB: notes = []")
  end
  
  def note(text)
    Logger.log("Note (#{text}) to #{@notes}!")
    @notes << text unless @notes.include?(text)
  end
  
  def notes
    return 'No notes yet.' if @notes.empty?
    to_return = "There are #{to_return.count} notes:\n"
    count = 0
    @notes.each do |n|
      count += 1
      to_return = "#{to_return}#{count}) #{n}\n"
    end
    return to_return
  end
end