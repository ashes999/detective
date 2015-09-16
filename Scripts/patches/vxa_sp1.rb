#==============================================================================
# ■ VXAce_SP1
#------------------------------------------------------------------------------
# This is an official bug fix for the default scripts.
# Place this above Materials.
#==============================================================================
 
#------------------------------------------------------------------------------
# 【Bug Fixes】
#------------------------------------------------------------------------------
# ● Event command "Change State" when you simultaneously add and remove the same 
# state, thereafter add that state fails.
# ● Event Command "Show Animation" the animation and the map scroll are not 
# synched.
# ● Auto battle, action not chosen correctly.
# ● When an equipment is removed because you can't equip it anymore, and as a 
# result another equipment needs to be removed, that equipment grows ?
# ● Event comand Erase picture fix. The game slows down as a whole.
# ● Move route option "Jump if not possible", during the execution if you touch 
# an event with the trigger "Player touch" that event is queued. 
# ● Magic reflection skill does not reflect the state validity.
# ● Font setting, when putting bold or italic as default, that setting changes 
# on screen change
#------------------------------------------------------------------------------
class Game_Battler
  attr_accessor :magic_reflection
  #--------------------------------------------------------------------------
  # ● 敵対関係の判定
  #--------------------------------------------------------------------------
  alias vxace_sp1_opposite? opposite?
  def opposite?(battler)
    vxace_sp1_opposite?(battler) || battler.magic_reflection
  end
end
#------------------------------------------------------------------------------
class Game_Actor
  #--------------------------------------------------------------------------
  # ● 装備できない装備品を外す
  #     item_gain : 外した装備品をパーティに戻す
  #--------------------------------------------------------------------------
  alias vxace_sp1_release_unequippable_items release_unequippable_items
  def release_unequippable_items(item_gain = true)
    loop do
      last_equips = equips.dup
      vxace_sp1_release_unequippable_items(item_gain)
      return if equips == last_equips
    end
  end
  #--------------------------------------------------------------------------
  # ● 自動戦闘時の戦闘行動を作成
  #--------------------------------------------------------------------------
  def make_auto_battle_actions
    @actions.size.times do |i|
      @actions[i] = make_action_list.max_by {|action| action.value }
    end
  end
end
#------------------------------------------------------------------------------
class Game_Player
  #--------------------------------------------------------------------------
  # ● マップイベントの起動
  #     triggers : トリガーの配列
  #     normal   : プライオリティ［通常キャラと同じ］かそれ以外か
  #--------------------------------------------------------------------------
  alias vxace_sp1_start_map_event start_map_event
  def start_map_event(x, y, triggers, normal)
    return if $game_map.interpreter.running?
    vxace_sp1_start_map_event(x, y, triggers, normal)
  end
end
#------------------------------------------------------------------------------
class Game_Picture
  #--------------------------------------------------------------------------
  # ● ピクチャの消去
  #--------------------------------------------------------------------------
  alias vxace_sp1_erase erase
  def erase
    vxace_sp1_erase
    @origin = 0
  end
end
#------------------------------------------------------------------------------
class Game_Interpreter
  #--------------------------------------------------------------------------
  # ● ステートの変更
  #--------------------------------------------------------------------------
  alias vxace_sp1_command_313 command_313
  def command_313
    vxace_sp1_command_313
    $game_party.clear_results
  end
end
#------------------------------------------------------------------------------
class Sprite_Character
  #--------------------------------------------------------------------------
  # ● 位置の更新
  #--------------------------------------------------------------------------
  alias vxace_sp1_update_position update_position
  def update_position
    move_animation(@character.screen_x - x, @character.screen_y - y)
    vxace_sp1_update_position
  end
  #--------------------------------------------------------------------------
  # ● アニメーションの移動
  #--------------------------------------------------------------------------
  def move_animation(dx, dy)
    if @animation && @animation.position != 3
      @ani_ox += dx
      @ani_oy += dy
      @ani_sprites.each do |sprite|
        sprite.x += dx
        sprite.y += dy
      end
    end
  end
end
#------------------------------------------------------------------------------
class Sprite_Picture
  #--------------------------------------------------------------------------
  # ● 転送元ビットマップの更新
  #--------------------------------------------------------------------------
  alias vxace_sp1_update_bitmap update_bitmap
  def update_bitmap
    if @picture.name.empty?
      self.bitmap = nil
    else
      vxace_sp1_update_bitmap
    end
  end
end
#------------------------------------------------------------------------------
class Window_Base
  #--------------------------------------------------------------------------
  # ● フォント設定のリセット
  #--------------------------------------------------------------------------
  alias vxace_sp1_reset_font_settings reset_font_settings
  def reset_font_settings
    vxace_sp1_reset_font_settings
    contents.font.bold = Font.default_bold
    contents.font.italic = Font.default_italic
  end
end
#------------------------------------------------------------------------------
class Scene_Battle
  #--------------------------------------------------------------------------
  # ● 魔法反射の発動
  #--------------------------------------------------------------------------
  alias vxace_sp1_invoke_magic_reflection invoke_magic_reflection
  def invoke_magic_reflection(target, item)
    @subject.magic_reflection = true
    vxace_sp1_invoke_magic_reflection(target, item)
    @subject.magic_reflection = false
  end
end