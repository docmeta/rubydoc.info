class Configuration < Hash
  def self.load(path=CONFIG_FILE)
    config = Configuration.new

    if File.file?(path)
      YAML.load_file(path).each do |key, value|
        config[key] = value
        define_method(key) { self[key] }
      end
    end

    config
  end

  def method_missing(name, *args, &block)
    self[name]
  end
end
