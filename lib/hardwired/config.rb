module Hardwired
  module Config
    class << self

      def config
        @@config
      end 

      # Loads the configuration from the YAML files whose +paths+ are passed as
      # arguments, filtering the settings for the current environment.  Note that
      # these +paths+ can actually be globs.
      def load(path, app)
        Dir.chdir(Hardwired::Paths.root || '.') do
          Dir.glob(path) do |file|
            $stderr.puts "loading config file '#{file}'" if app.logging?
            document = IO.read(file)
            @@config = RecursiveOpenStruct.new(config_for_env(YAML.load(document),app.environment) || {})
            return @@config 
          end
        
        end
      end

      def config_for_env(hash,env)
        if hash.is_a?(Hash)
          hash = hash.merge(hash[env.to_s] || hash[env.to_sym] || {})
          hash.each_pair do |k,v|
            hash[k] = config_for_env(v,env)
          end 
        end
        hash
      end

    end 
  end 

end