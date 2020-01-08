class Configuration < Hash
  def self.load
    Configuration.new(YAML.load_file(CONFIG_FILE) || {})
  end

  def initialize(hash)
    update(hash)
    update('environment' => 'production') if environment.nil?
  end

  def method_missing(name, *args, &block)
    if name.to_s[-1,1] == "="
      self[name.to_s[0...-1]] = args[0]
    else
      self[name.to_s]
    end
  end
end
