#==============================================================================|
#  ** Script Info                                                              |
#------------------------------------------------------------------------------|
#  * Script Name                                                               |
#    DoubleX RMVXA Dynamic Data                                                |
#------------------------------------------------------------------------------|
#  * Functions                                                                 |
#    Stores the changes to the database done by users during game executions   |
#    Can't be used with data having contents that can't be serialized          |
#------------------------------------------------------------------------------|
#  * Terms Of Use                                                              |
#    You shall keep this script's Script Info part's contents intact           |
#    You shalln't claim that this script is written by anyone other than       |
#    DoubleX or his aliases                                                    |
#    None of the above applies to DoubleX or his aliases                       |
#------------------------------------------------------------------------------|
#  * Prerequisites                                                             |
#    Abilities:                                                                |
#    1. Decent RGSS3 scripting proficiency to fully utilize this script        |
#    2. Custom script comprehensions to edit that script's used data stored in |
#       RPG::BaseItem and/or its subclasses                                    |
#------------------------------------------------------------------------------|
#  * Instructions                                                              |
#    1. Open the script editor and put this script into an open slot between   |
#       Materials and Main, save to take effect.                               |
#------------------------------------------------------------------------------|
#  * Links                                                                     |
#    Script Usage 101:                                                         |
#    1. forums.rpgmakerweb.com/index.php?/topic/32752-rmvxa-script-usage-101/  |
#    2. rpgmakervxace.net/topic/27475-rmvxa-script-usage-101/                  |
#    This script:                                                              |
#    1.                                                                        |
#------------------------------------------------------------------------------|
#  * Authors                                                                   |
#    DoubleX                                                                   |
#------------------------------------------------------------------------------|
#  * Changelog                                                                 |
#    v1.00a(GMT 0400 16-5-2015):                                               |
#    1. 1st version of this script finished                                    |
#==============================================================================|

($doublex_rmvxa ||= {})[:Dynamic_Data] = "v1.00a"

#==============================================================================|
#  ** Script Implementations                                                   |
#     You need not edit this part as it's about how this script works          |
#------------------------------------------------------------------------------|
#  * Script Support Info:                                                      |
#    1. Prerequisites                                                          |
#       - Some RGSS3 scripting proficiency to fully comprehend this script     |
#    2. Method documentation                                                   |
#       - The 1st part informs whether the method's rewritten, aliased or new  |
#       - The 2nd part describes what the method does for new methods only     |
#       - The 3rd part describes what the arguments of the method are          |
#       - The 4th part describes how this method works for new methods only,   |
#         and describes the parts added or rewritten for rewritten or aliased  |
#         methods only                                                         |
#       Example:                                                               |
# #----------------------------------------------------------------------------|
# #  Rewrite/Alias/New method: def_name                                        |
# #  - What this method does                                                   |
# #----------------------------------------------------------------------------|
# # *args: What these arguments are                                            |
# def def_name(*args)                                                          |
#   # How this method works                                                    |
#   def_name_code                                                              |
#   #                                                                          |
# end # def_name                                                               |
#------------------------------------------------------------------------------|

#------------------------------------------------------------------------------|
#  * Edit module: DataManager                                                  |
#------------------------------------------------------------------------------|

class << DataManager

  #----------------------------------------------------------------------------|
  #  Alias method: save_game_without_rescue                                    |
  #----------------------------------------------------------------------------|
  alias save_game_without_rescue_dynamic_data save_game_without_rescue
  def save_game_without_rescue(index)
    ["actors", "classes", "skills", "items", "weapons", "armors", "enemies", 
     "troops", "states", "animations", "tilesets", "common_events", 
     "system"].each { |type| eval("$game_system.data_#{type} = $data_#{type}") }
    save_game_without_rescue_dynamic_data(index)
  end # save_game_without_rescue

  #----------------------------------------------------------------------------|
  #  Alias method: extract_save_contents                                       |
  #----------------------------------------------------------------------------|
  alias extract_save_contents_dynamic_data extract_save_contents
  def extract_save_contents(contents)
    extract_save_contents_dynamic_data(contents)
    ["actors", "classes", "skills", "items", "weapons", "armors", "enemies", 
     "troops", "states", "animations", "tilesets", "common_events", 
     "system"].each { |type| eval("$data_#{type} = $game_system.data_#{type}") }
  end # extract_save_contents

end # DataManager

#------------------------------------------------------------------------------|
#  * Edit class: Game_System                                                   |
#------------------------------------------------------------------------------|

class Game_System

  #----------------------------------------------------------------------------|
  #  New public instance variables                                             |
  #----------------------------------------------------------------------------|
  ["actors", "classes", "skills", "items", "weapons", "armors", "enemies", 
   "troops", "states", "animations", "tilesets", "common_events", 
   "system"].each { |type| eval("attr_accessor :data_#{type}") }

end # Game_System

#------------------------------------------------------------------------------|

#==============================================================================|