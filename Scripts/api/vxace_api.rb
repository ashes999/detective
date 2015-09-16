# This directory wraps around and makes simple/easy, stuff that uses the API (not necessarily extends it)
require 'scripts/api/game_interpreter'
require 'scripts/api/game_event'
require 'scripts/api/game_map'

# Require all our fixes.
Dir.glob('scripts/patches/*.rb').each do |f|
  require "#{f.sub('.rb', '')}"
end