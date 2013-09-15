class Application
  
  @@filename = nil
  @@config = {}
  
  def self.initialize
    @@filename = "#{Rails.root}/config/application.yml"
    if File.exists?(@@filename)
      if yaml = YAML.load_file(@@filename)
        @@config = yaml.values[0] || {}
      end
    end
  end
  
  def self.config(name, default = nil)
    initialize unless @@filename
    value = @@config[name.to_s]
    value ? value : default
  end
end