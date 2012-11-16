module Hardwired
  class Template

    #Returns true if this file is a content file, such as a page or a post
    def is_page?
      return true if flag?('page')  #Permit override with Flags: page
      return false if in_layout_dir? #no pages in _layout
      return false if [:sass,:scss,:coffee].include?(engine_name) #Never css or javascript
      true
    end

    def in_layout_dir?
      debugger if path.nil?
      !path.index(Paths.layout_subfolder).nil? && path.index(Paths.layout_subfolder) < 2 
    end


    #Should return true if the file can be rendered
    def can_render?
      return true if flag?('visible')
      hidden? and !in_layout_dir?
    end 


    def is_visible_page?
      is_page? and !hidden?
    end 

    def hidden?
      flag?('hidden') or (!Base.development? and draft?)
    end

    def draft?
      flag? 'draft'
    end 

    

    def flags
      parse_string_list(meta.flags)
    end

    def flag?(flag)
      flags.include? flag or flags.include? flag.to_sym
    end 


     def libs
      parse_string_list(meta.libs)
     end
     
     def lib?(lib)
        libs.include?(lib) or libs.include?(lib.to_s)
     end

    def flagged_as?(flag)
      flags.include?(flag)
    end

    def heading
      meta.heading || markup_heading
    end

    def layout
      meta.layout || Paths.layout_subfolder + '/page'
    end

    def layout_paths
      yield layout #as-is (root)
      return if layout[0] == '/'  #Absolute paths can't be combined
      yield filename[Paths.content_path.length..-1].sub(/\/[^\/]$/m,'/') + layout #in current folder
      yield Paths.layout_subfolder + '/' + layout #in _layout
    end



    attr_reader :filename, :path, :last_modified, :format, :line, :markup_body, :markup_heading, :markup, :meta

    def initialize(physical_filename, raw_contents=nil, line = 0)
      @filename = physical_filename
      @last_modified = File.mtime(filename)
      @format = File.extname(filename).downcase[1..-1].to_sym
      @path = Index.virtual_path_for(filename)

      @raw_contents = raw_contents || ''
      @line = line.to_i
      if raw_contents.nil? and !File.zero?(filename)
        File.open(@filename) { |f|
          @raw_contents = f.read
        }
      end


      @meta, @markup = MetadataParsing.parser.new.extract(@raw_contents)
      debugger if !@meta.is_a?(Hash)
      @meta = RecursiveOpenStruct.new(@meta)


      @markup_heading = ContentFormats[@format].nil? ? nil : ContentFormats[@format].heading(markup)
      @markup_body = ContentFormats[@format].nil? ? markup : ContentFormats[@format].body(markup)


      #Adjust line offset for metadata and heading removal
      @line += @raw_contents.lines.count - @markup_body.lines.count 
    end

    def self.load(filename)
      t = Template.new(filename)
      t = Page.new(t) if t.is_page?
      t
    end



    def renderer_class
      return @renderer_class unless @renderer_class.nil?
      if not meta.renderer.nil? 
        renderer = Regexp.new("(:|^)" + Regexp.escape(meta.renderer) + "$", :ignorecase)
        @renderer_class = Tilt.mappings.values.flatten.select{ |obj| renderer.match(obj.name) }.first
      else
        @renderer_class = Tilt[engine_name]
      end
      raise "Template engine not found: #{meta.renderer || engine_name}" if @renderer_class.nil?
      @renderer_class
    end

    def self.list_engine_names(engine)
      yield engine
      default = Tilt[engine]
      Tilt.mappings.each_pair do |k,v| 
        yield k if v.include?(default) 
      end
    end



    def render(options = {},scope = nil, locals=nil,&block)

      #Merge engine-specific options from settings
      list_engine_names(engine_name).each do |engine|
        engine_options  = settings.respond_to?(engine) ? settings.send(engine) : {}
        options         = engine_options.merge(options)
      end

      #Establish defaults for scope, locals, content type, and default encoding
      scope ||= options.delete(:scope) || Object.new
      locals ||= options.delete(:locals) || {}
      
      content_type    = meta.content_type || options.delete(:content_type)  || options.delete(:default_content_type)
      locals[:template] = self
      options[:default_encoding] ||= settings.default_encoding


      #Render current template
      i = renderer_class.new(filename,line,options){markup_body}
      output = i.render(scope, locals, &block)

      #Render parents recursively
      output = layout_template.render(options,scope,locals) {output} unless layout_template.nil?

      #First template rendered controls the content-type
      output.extend(ContentTyped).content_type = content_type if content_type
      output
    end

    def engine_name
      format.downcase.to_sym
    end


    def parent
      parents.first
    end

    def parse_string_list(text)
      return [] if text.nil?
      if text.is_a?(String) 
        text = text.split(',').map { |string| string.strip }
      end
      text
    end


    def layout_template
      layout_paths.each do |p|
        Index[p] unless Index[p].nil?
      end
      nil
    end

    def parents
      parent = path
      while !parent.empty? do
        parent.sub!(/(^|\/)[^\/]+\/?$/m,"")
        yield Index[parent] unless Index[parent].nil?
      end
    end

    def ==(other)
      other.respond_to?(:path) && (self.path == other.path)
    end

    def copy_vars_from(other, *vars)
      vars = [:@filename,:@last_modified,:@format,:@path,:@raw_contents,:@line,:@metadata,:@markup,:@markup_body,:@markup_heading] if vars.nil? || vars.empty?
      vars.each do |v|
        instance_variable_set(v,other.instance_variable_get(v))
      end
    end
  end
end 
