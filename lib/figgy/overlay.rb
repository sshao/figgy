class Figgy
  class Overlay
    @handlers = []

    class << self
      attr_accessor :handlers
    end

    attr_accessor :name, :locations

    def initialize(name, source, locations)
      @name = name
      @source = source
      @locations = Array(locations)
    end
  end

  class FileSource < Overlay
    def initialize(name, source, locations)
      super
    end

    def all_keys
      files_for('*').map { |f| File.basename(f).sub(/\..+$/, '') }
    end

    def files_for(name)
      extensions = Overlay.handlers.map(&:first)
      globs = extensions.map { |ext| "#{name}.#{ext}" }

      filepaths = @locations.map do |dir|
        globs.map { |glob| File.join(dir, glob) }
      end.flatten.uniq

      Dir[*filepaths]
    end

    def fetch(file)
      handler_for(file).call(File.read(file))
    end

    private

    def handler_for(filename)
      match = Overlay.handlers.find { |ext, handler| filename =~ /\.#{ext}$/ }
      match && match.last
    end
  end

  class VaultSource < Overlay
    def initialize(name, source, locations)
      super
    end

    def all_keys
      @source.logical.list(dir)
    end

    def files_for(name)
      @locations.map { |dir| "#{dir}/#{name}" }
    end

    def fetch(file)
      secret = @source.logical.read(file)

      # vault-ruby returns a hash of symbol keys, which causes
      # issues with deep merge (FileSource overlays have string keys
      # causing deep_merge to not merge symbol keys -> string keys)
      raw_json = secret.data.to_json
      JSON.parse(raw_json)
    end
  end
end
