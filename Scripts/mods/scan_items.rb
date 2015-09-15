class Window_HelpScanner < Window_Help
  def set_item(item)  
    super
    @item = item
  end
  
  def set_text(text)
    if !@item.nil?
      notebook = DetectiveGame::instance.notebook
      notes = notebook.notes_for(:name => @item.name)    
      text = "#{text}\n#{notes}"      
    end
    super
  end
end

# Copied from Scene_Item
class Scene_Item
  def create_help_window
    @help_window = Window_HelpScanner.new
    @help_window.viewport = @viewport
  end

  # Copied from Scene_Item
  #def on_item_ok
  #  $game_party.last_item.object = item
  #  determine_item
  #end
end