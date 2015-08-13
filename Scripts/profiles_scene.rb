class Scene_Profiles < Scene_ItemBase
  STATUS_WINDOW_HEIGHT = 48
  
  # Start Processing
  def start
    super
    create_suspects_window
    create_details_window
    create_status_window
  end

  def create_suspects_window
    @suspect_list = Window_SuspectsList.new
    @suspect_list.viewport = @viewport
    @suspect_list.set_handler(:ok,     method(:on_suspect_ok))
    @suspect_list.set_handler(:cancel, method(:return_scene))
  end

  def create_details_window
    wy = @suspect_list.y + @suspect_list.height
    wh = Graphics.height - wy  - STATUS_WINDOW_HEIGHT
    @details_window = Window_ItemList.new(0, wy, Graphics.width, wh)
    @details_window.viewport = @viewport
    #@details_window.set_handler(:ok,     method(:on_item_ok))
    #@details_window.set_handler(:cancel, method(:on_item_cancel))
    @suspect_list.details_window = @details_window
  end
  
  def create_status_window    
    @status_window = Window_SuspectsStatus.new(0, @details_window.y + @details_window.height, Graphics.width, STATUS_WINDOW_HEIGHT)
    @status_window.viewport = @viewport
    #@suspect_list.set_handler(:ok,     method(:on_suspect_ok))
    #@suspect_list.set_handler(:cancel, method(:return_scene))
    @suspect_list.status_window = @status_window
  end

  # when you select a category (suspect)
  def on_suspect_ok
    @details_window.activate
    @details_window.select_last
  end

  #def on_item_ok
  #  $game_party.last_item.object = item
  #  determine_item
  #end

  #def on_item_cancel
  #  @details_window.unselect
  #  @suspect_list.activate
  #end
end


class Window_SuspectsList < Window_HorzCommand
  attr_reader   :suspect_list, :status_window

  def initialize
    super(0, 0)
  end

  def window_width
    Graphics.width
  end
  
  ### Maximum number of items to show at one time. Items are fixed width :(
  def col_max
    return 6
  end

  def update
    super
    @suspect_list.category = current_symbol if @suspect_list
  end

  def make_command_list
    DetectiveGame::instance.npcs.each do |n|
      add_command(n.name, n.name.to_sym)
    end
  end

  def details_window=(details_window)
    @details_window = details_window
    update
  end
  
  def status_window=(status_window)
    @status_window = status_window
    update
  end
end

class Window_SuspectsStatus < Window_Base
  def initialize(x, y, w, h)
    super
  end
end