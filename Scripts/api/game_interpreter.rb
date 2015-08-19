class Game_Interpreter
  def self.instance
    return $game_map.interpreter
  end
  
  ###
  # Show a list of choices. You can specify which choice is "cancel".
  # By default, it's the second choice (same as the UI).
  #
  # choices: a list of choices (eg. ['one', 'two', 'three'])
  # options: A hash of additional options. They are:
  #    :cancel_index => the index of the choice to return when the user cancels; defaults to -1 (disable cancelling)
  #    :return_type => :index (return an index in "choices") or :name (return the choice name)
  ###
  def show_choices(choices, options = {})
    cancel_index = options[:cancel_index] || -1
    return_type = options[:return_type || :index]
    params = []
    params.push(choices)
    params.push(cancel_index)
    setup_choices(params)
    wait_for_message
    result_index = @branch[@indent]
    return return_type == :name ? choices[result_index] : result_index
  end

  ###
  # Show a message on screen, just like the Show Text event.
  # This isn't quite the same as talking to an NPC -- events don't stop.
  ###
  def show_message(text, options = {})
    $game_message.add(text)
    wait_for_message unless options[:wait] == false
  end
  
  def game_over  
    SceneManager.goto(Scene_Gameover)
    Fiber.yield
  end
end