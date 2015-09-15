class Window_HelpScanner < Window_Help
  def set_text(text)
    super
    Logger.log "Text is now #{@text}" # may be set to '' when changing menus
  end
  
  def set_item(item)
    super
    Logger.log "Setting item to #{item.name}" unless item.nil?
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