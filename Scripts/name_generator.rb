class NameGenerator
  
  @@characters = ['a', 'ka', 'ma', 'sa', 'hi', 'ho', 'he', 'hy', 'am', 'at', 'ar', 'th', 'pa', 'po']
  @@names_used = []
  
  def self.generate_name
    name = create_name
    name = create_name while @@names_used.include?(name)
    return name
  end
  
  private
  
  def self.create_name
    picks = rand(2) + 2
    while picks > 0 do
      picks -= 1
      name = "#{name}#{@@characters.sample}"
    end
    
    return name.capitalize
  end
end