#========================================================================
# ** Logger
#    By: ashes999 (ashes999@yahoo.com)
#    Version: 1.0
#------------------------------------------------------------------------
# * Description:
# Allows you to log messages at a given level (default is :info).
# Levels are: :info, :debug. 
#========================================================================

LEVELS = { :info => 1, :debug => 2 }

class Logger
  @@logging_level = :info
  @@first_message = true
  
  def self.logging_level=(value)
    @@logging_level = value
  end

	def self.log(message, level = @@logging_level)
		return if level > @@logging_level
		
		mode = @@first_message ? 'w' : 'a'
		
		File.open('log.txt', mode) { |f|
			f.write("#{Time.new} :: #{message}\n")
		}
		
		@@first_message = false
	end
	
	def self.info(message)
		Logger.log(message, :info)
	end
	
	def self.debug(message)
		Logger.log(message, :debug)
	end		
end

