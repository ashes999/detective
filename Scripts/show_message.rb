def show_message(text)
  #$game_message.face_name = 'fName'
  #$game_message.face_index = fIndex
  #$game_message.background = fBG
  #$game_message.position = fPos
  $game_message.add(text)
  # fName - Name of file containing desired face. Also automatically searches
  # files included in RGSS-RTP. File extensions may be omitted.
  # fIndex - Numerical identifier of face (0 is the first face).
  # fBG - [0] Normal, [1] Faded, [2] Transparent
  # fPos - [0] Top, [1] Middle, [2] Bottom
end