class Game_Map
  def self.instance
    return $game_map
  end
  
  ###
  # Finds an empty spot. See is_empty? below.
  # returns a hash { :x => x, :y => y }
  ###
  def find_random_empty_spot
    x = rand(self.width)
    y = rand(self.height)    
    
    while !is_empty?(x, y)      
      x = rand(self.width)
      y = rand(self.height)
    end    
    
    return {:x => x, :y => y}
  end
  
  ###
  # Returns if a tile is empty or not. This is in the context of spawning
  # events, and a tile can only have one event on it, so this consists of
  # the following checks:
  # 1) There are no events on this tile
  # 2) The tile is passable (for all layers, all directions are passable)
  ###
  def is_empty?(x, y)
    event_count = self.events_xy(x, y).length    
    # Has no events on it (max is one event per tile), and it's passable
    return event_count == 0 && is_passable?(x, y)
  end
  
  private
  
   ###
  # Returns true if the tile (all layers) is passable in all four directions.
  # Should technically be called is_not_impassible?, but that's a double negative.
  # TODO: use passable?(x, y, d) instead.
  ###
  def is_passable?(x, y)
    # http://rgss3.wiki.fc2.com/wiki/$game_map.check_passage%2528)
    [0x001, 0x002, 0x004, 0x008].each do |d| # four directions
      return false if check_passage(x, y, d) == false
    end
    
    return true
  end
end