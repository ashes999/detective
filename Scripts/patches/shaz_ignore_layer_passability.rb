#==============================================================================
# VXAce Star Passability Bug Fix
#   by NeonBlack, Shaz and Archeia
# -- Level: Easy, Normal
# -- Requires: n/a
# -- This simply checks if the tile is a star before checking passability.  
# If the tile is a star and it is passable, it then checks the tile UNDER it.  
# If not, it returns false as always. This prevents everything that is a star 
# tile from being passable.
#
# This script is edited to fix the whole upper tiles make cliff tiles passable.
#
# -- Original Topic:
# http://forums.rpgmakerweb.com/index.php?/topic/7625-vxace-passabilities-bug/
# http://forums.rpgmakerweb.com/index.php?/topic/6746-ignore-layer-passability/
#==============================================================================
 
class Game_Map
 
  def check_passage(x, y, bit)
        all_tiles(x, y).each do |tile_id|
          flag = tileset.flags[tile_id]
          if flag & 0x10 != 0                       # [☆]: No effect on passage
                next if flag >> 12 == 1             # ignore passability on terrain 1
                next             if flag & bit == 0 # [○] : Passable but star
                return false if flag & bit == bit   # [×] : Impassable
            else
                 next if flag >> 12 == 1             # ignore passability on terrain 1
                return true  if flag & bit == 0  # [○] : Passable
                return false if flag & bit == bit   # [×] : Impassable
          end
        end
        return false                                              # Impassable
  end
end