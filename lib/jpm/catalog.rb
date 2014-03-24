require 'forwardable'
require 'json'

require 'jpm'
require 'jpm/errors'
require 'jpm/plugin'

module JPM
  class Catalog
    extend Forwardable

    attr_reader :plugins

    # Dekegate the #size method to our plugins hash
    def_delegator :@plugins, :size
    def_delegator :@plugins, :[]

    def initialize(options={})
      super()
      @plugins = {}
    end

    # Append a +JPM::Plugin+ to the catalog
    #
    # @param [JPM::Plugin] plugin
    # @return [JPM::Catalog]
    def <<(plugin)
      # We're overriding this method instead of delegating it to the @plugins
      # instance method to make sure that we're structuring our +Hash+
      # correctly, and only inserting valid +JPM::Plugin+ objects
      unless plugin.instance_of? JPM::Plugin
        raise ArgumentError, "`plugin` must be an instance of JPM::Plugin"
      end

      @plugins[plugin.name] = plugin

      return self
    end

    # Install a plugin and its dependencies if it has any
    def install(plugin)
      unless plugin.dependencies.empty?
        raise NotImplementedError, "I can't install dependencies yet!"
      end

      response = JPM.fetch(plugin.url)
      filename = File.basename(plugin.url)

      return save_plugin(filename, response.body)
    end

    def search(term)
      results = []
      @plugins.each_pair do |name, plugin|
        if name.match(term)
          if block_given?
            yield plugin
          else
            results << plugin
          end
        end
      end

      return results
    end

    # Create an instance of a catalog from a file on the current system's disk
    #
    # @param [String] filepath Absolute path to an update-center.json file
    # @return [JPM::Catalog] instance of a Catalog
    def self.from_file(filepath)
      catalog = self.new

      unless File.exists?(filepath)
        raise JPM::Errors::MissingCatalogError, "`#{filepath}` is not a valid file"
      end

      plugins = []
      File.open(filepath, 'rb') do |fd|
        buffer = fd.read
        raise JPM::Errors::InvalidCatalogError if (buffer.nil? || buffer.empty?)
        buffer = buffer.split("\n")
        # Trim off the first and last lines, which are the JSONP gunk
        buffer = buffer[1 ... -1]

        data = JSON.parse(buffer.join("\n"))
        plugins = data['plugins']
      end

      # The plugin data is in the form of a +Hash+, in that it looks something
      # like this:
      #   {
      #     "git" => {
      #       "name" => "git",
      #       "version" => "1.0"
      #     }
      #   }
      plugins.each do |name, plugin|
        catalog << JPM::Plugin.from_hash(plugin)
      end

      return catalog
    end

    private

    def save_plugin(filename, contents)
      File.open(File.join(JPM.plugins_dir, filename), 'wb+') do |fd|
        fd.write(contents)
      end
    end
  end
end
