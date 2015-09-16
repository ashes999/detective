# http://forums.rpgmakerweb.com/index.php?/topic/1131-rgss3-unofficial-bugfix-snippets/
# Turn count is excluded because that's covered in Yanfly's "Ace Core"

### Randomized Enemy Self-Targeting
class Game_Action
  def targets_for_friends
	if item.for_user?
	  [subject]
	elsif item.for_dead_friend?
	  if item.for_one?
		[friends_unit.smooth_dead_target(@target_index)]
	  else
		friends_unit.dead_members
	  end
	elsif item.for_friend?
	  if item.for_one?
		if @target_index < 0
		  [friends_unit.random_target]
		else
		  [friends_unit.smooth_target(@target_index)]
		end
	  else
		friends_unit.alive_members
	  end
	end
  end
end

### Custom Font Junk Symbol Fix
class Window_Base
  alias :process_normal_character_vxa :process_normal_character
  def process_normal_character(c, pos)
	return unless c >= ' '
	process_normal_character_vxa(c, pos)
  end
end
