class Figgy
  class Configuration
    # The directories in which to search for configuration files
    attr_reader :roots

    # The list of defined overlays
    attr_reader :overlays

    # Whether to reload a configuration file each time it is accessed
    attr_accessor :always_reload

    # Whether to load all configuration files upon creation
    # @note This does not prevent +:always_reload+ from working.
    attr_accessor :preload

    # Whether to freeze all loaded objects. Useful in production environments.
    attr_accessor :freeze

    # Constructs a new {Figgy::Configuration Figgy::Configuration} instance.
    #
    # By default, uses a +root+ of the current directory, and defines handlers
    # for +.yml+, +.yaml+, +.yml.erb+, +.yaml.erb+, and +.json+.
    def initialize
      @roots    = [Dir.pwd]
      @always_reload = false
      @preload = false
      @freeze = false

      define_handler 'yml', 'yaml' do |contents|
        YAML.load(contents)
      end

      define_handler 'yml.erb', 'yaml.erb' do |contents|
        erb = ERB.new(contents).result
        YAML.load(erb)
      end

      define_handler 'json' do |contents|
        JSON.parse(contents)
      end

      @overlays = [FileSource.new('root', File, @roots)]
    end

    def root=(path)
      @roots = [File.expand_path(path)]
      @overlays = [FileSource.new('root', File, @roots)]
    end

    def add_root(path)
      @roots.unshift File.expand_path(path)
      @overlays.unshift FileSource.new('root', File, File.expand_path(path))
    end

    # @see #always_reload=
    def always_reload?
      !!@always_reload
    end

    # @see #preload=
    def preload?
      !!@preload
    end

    # @see #freeze=
    def freeze?
      !!@freeze
    end

    # Adds a new handler for files with any extension in +extensions+.
    #
    # @example Adding an XML handler
    #   config.define_handler 'xml' do |body|
    #     Hash.from_xml(body)
    #   end
    def define_handler(*extensions, &block)
      Figgy::Overlay.handlers += extensions.map { |ext| [ext, block] }
    end

    # Adds an overlay named +name+, found at +value+.
    #
    # If a block is given, yields to the block to determine +value+.
    #
    # @param name an internal name for the overlay
    # @param value the value of the overlay
    # @example An environment overlay
    #   config.define_overlay(:environment) { Rails.env }
    def define_overlay(name, value = nil)
      value = yield if block_given?

      # The dir(s) that files in this overlay-level live at.
      locations = @roots.map { |root| value ? File.join(root, value) : root }.flatten.uniq

      @overlays << FileSource.new(name, File, locations)
    end

    def define_vault_overlay(name, client, path = nil)
      path = yield if block_given?
      locations = [path] # TODO: currently no such concept as a "root" for a vault overlay, should there be
      @overlays << VaultSource.new(name, client, locations)
    end

    # Adds an overlay using the combined values of other overlays.
    # Only works with local file overlays, does not work with Vault.
    #
    # @example Searches for files in 'production_US'
    #   config.define_overlay :environment, 'production'
    #   config.define_overlay :country, 'US'
    #   config.define_combined_overlay :environment, :country
    def define_combined_overlay(*names)
      combined_name = names.join("_").to_sym

      value = names.map { |name| overlay_value(name) }.join("_")

      locations = @roots.map { |root| value ? File.join(root, value) : root }.flatten.uniq

      @overlays << FileSource.new(combined_name, File, locations)
    end

    private

    def overlay_value(name)
      overlay = @overlays.find { |o| name == o.name }
      raise "No such overlay: #{name.inspect}" unless overlay
      if overlay.is_a?(VaultSource)
        raise "Cannot define combined overlay with Vault overlay: #{name.inspect}"
      end

      # If there are multiple locations, it's only bc there are multiple roots.
      # All of them will have the same basename, so just pick the first.
      File.basename(overlay.locations.first)
    end
  end
end
