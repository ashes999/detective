class Scene_Profiles < Scene_ItemBase
  #--------------------------------------------------------------------------
  # * Start Processing
  #--------------------------------------------------------------------------
  def start
    super
    create_suspects_window
    create_item_window
  end
  #--------------------------------------------------------------------------
  # * Create Category Window
  #--------------------------------------------------------------------------
  def create_suspects_window
    @category_window = Window_SuspectsList.new
    @category_window.viewport = @viewport
    @category_window.set_handler(:ok,     method(:on_category_ok))
    @category_window.set_handler(:cancel, method(:return_scene))
  end
  #--------------------------------------------------------------------------
  # * Create Item Window
  #--------------------------------------------------------------------------
  def create_item_window
    wy = @category_window.y + @category_window.height
    wh = Graphics.height - wy
    @item_window = Window_ItemList.new(0, wy, Graphics.width, wh)
    @item_window.viewport = @viewport
    @item_window.set_handler(:ok,     method(:on_item_ok))
    @item_window.set_handler(:cancel, method(:on_item_cancel))
    @category_window.item_window = @item_window
  end
  #--------------------------------------------------------------------------
  # * Category [OK]
  #--------------------------------------------------------------------------
  def on_category_ok
    @item_window.activate
    @item_window.select_last
  end
  #--------------------------------------------------------------------------
  # * Item [OK]
  #--------------------------------------------------------------------------
  def on_item_ok
    $game_party.last_item.object = item
    determine_item
  end
  #--------------------------------------------------------------------------
  # * Item [Cancel]
  #--------------------------------------------------------------------------
  def on_item_cancel
    @item_window.unselect
    @category_window.activate
  end
  #--------------------------------------------------------------------------
  # * Play SE When Using Item
  #--------------------------------------------------------------------------
  def play_se_for_item
    Sound.play_use_item
  end
  #--------------------------------------------------------------------------
  # * Use Item
  #--------------------------------------------------------------------------
  def use_item
    super
    @item_window.redraw_current_item
  end
end


class Window_SuspectsList < Window_HorzCommand
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader   :item_window
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize
    super(0, 0)
  end
  #--------------------------------------------------------------------------
  # * Get Window Width
  #--------------------------------------------------------------------------
  def window_width
    Graphics.width
  end
  
  ### Maximum number of items to show at one item. Items are fixed width :(
  def col_max
    return 6
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    super
    @item_window.category = current_symbol if @item_window
  end
  #--------------------------------------------------------------------------
  # * Create Command List
  #--------------------------------------------------------------------------
  def make_command_list
    DetectiveGame::instance.npcs.each do |n|
      add_command(n.name, n.name.to_sym)
    end
  end
  #--------------------------------------------------------------------------
  # * Set Item Window
  #--------------------------------------------------------------------------
  def item_window=(item_window)
    @item_window = item_window
    update
  end
end