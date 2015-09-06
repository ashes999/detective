# Used to set event direction, move speed and frequency (extends RPG Maker class)
class Game_Event
  
  # These two are used to randomize event speed
  def move_speed=(value)
    @move_speed = value
  end
  def move_frequency=(value)
    @move_frequency = value
  end
  
  def stop_walking
    @move_type = 0 # stop moving
    @direction_fix = true # don't change direction if talked to    
  end
  
  # 0, 1, or 2 for first, second, or third frame
  def animation_frame=(value)
    @pattern = @original_pattern = value
  end
end