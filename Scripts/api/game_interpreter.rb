class Game_Interpreter
  def self.instance
    return $game_map.interpreter
  end
  
  ###
  # Show a list of choices. You can specify which choice is "cancel".
  # By default, it's the second choice (same as the UI).
  #
  # choices: a list of choices (eg. ['one', 'two', 'three'])
  # cancel_index: the choice to return on 'cancel' (eg. 1)
  ###
  def show_choices(choices, cancel_index = -1)
    params = []
    params.push(choices)
    params.push(cancel_index)
    setup_choices(params)
    wait_for_message
    result_index = @branch[@indent]
    return result_index # alternatively, return choices[result_index]
  end

  ###
  # Show a message on screen, just like the Show Text event.
  # Not sure why NPCs don't stop if you call this when you talk to them.
  ###
  def show_message(text)
    $game_message.add(text)
  end
end