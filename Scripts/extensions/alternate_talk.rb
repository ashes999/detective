# Originally based on "Triple Triad Script - Activation by click" by Raizen
# If you press an hold a key (eg. A), it will trigger a switch. You can create
# events that do things differently from normal if that switch is selected.
# In the context of FF8, talking to people with this key would start a card game.
# You can also have people transform into monsters while this key is held down.

module Config
  # Mapped as the events keys
  # :X is A on keyboard
  ACTIVATION_KEY = :X

  # Which switch to activate when we press/hold ACTIVATION_KEY
  ACTIVATION_SWITCH = 1
end

class Game_Player < Game_Character
  alias original_update_nonmoving update_nonmoving
  
  def update_nonmoving(*args, &block)
    original_update_nonmoving(*args, &block)
    $game_switches[Config::ACTIVATION_SWITCH] = false
    if movable? && Input.press?(Config::ACTIVATION_KEY)
      return if get_on_off_vehicle
      $game_switches[Config::ACTIVATION_SWITCH] = true
      return if check_action_event
    end
  end
end