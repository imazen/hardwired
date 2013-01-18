module Hardwired
  class Template
    module ContentTyped
      attr_accessor :content_type
    end


  
    def title
      meta.title || (heading && "#{heading} - #{Hardwired::Config.config.title}") ||  (path == '/' && Config.config.title)
    end

    def date
      @date ||= meta.date && DateTime.parse(meta.date)
    end

    def atom_id
      meta.atom_id || "tag:#{Hardwired::Config.config.atom_id || Hardwired::Config.config.url  || request.host},#{date ? date.strftime('%Y-%m-%d') : ""}:#{path}"
    end

    def read_more
      meta.read_more || 'Continue reading'
    end

    def summary (scope = nil, min_characters = 200)
      meta_summary || first_sentences(scope,min_characters)
    end

    def meta_summary
      meta.summary && meta.summary.gsub('\n', "\n")
    end

    def other_pages_with_shared_tags
       Hardwired::Index.pages.select { |p| not (p.tags & self.tags).empty? }
    end


    #Returns true if this file is a content file, such as a page or a post
    def is_page?
      return true if flag?('page')  #Permit override with Flags: page
      return false if in_layout_dir? #no pages in _layout
      return false if [:sass,:scss, :less, :coffee].include?(engine_name) #Never css or javascript
      true
    end

    def is_post?
      false
    end

    def in_layout_dir?
      
      !path.index(Paths.layout_subfolder).nil? && path.index(Paths.layout_subfolder) < 2 
    end


    #Should return true if the file can be rendered
    def can_render?
      return true if flag?('visible')
      !hidden? and !in_layout_dir?
    end 

    def hidden?
      flag?('hidden') || (!Hardwired::SiteBase.development? and draft?)
    end

    def draft?
      flag? 'draft'
    end 

    def flags
      parse_string_list(meta.flags)
    end

    def flag?(flag)
      flags.include?(flag) || flags.include?(flag.to_s)
    end 

    def libs
      parse_string_list(meta.libs)
    end

    def lib?(name)
      libs.include?(name) || libs.include?(name.to_s)
    end

    def tags
      parse_string_list(meta.tags)
    end

    def tag?(name)
      tags.include?(name) || tags.include?(name.to_s)
    end 


    def heading
      meta.heading || markup_heading
    end

    def default_layout
      return Paths.layout_subfolder + '/page'
    end

    def layout
      return meta.layout unless meta.layout.nil?
      return nil if in_layout_dir? || [:scss,:sass,:less,:coffee].include?(format.to_sym)
      default_layout
    end

    def layout_template
      Index.find(layout, dir_path)
    end


    attr_reader :filename, :path, :last_modified, :format, :line, :markup_body, :markup_heading, :markup, :meta

    def initialize(physical_filename, raw_contents=nil, line = 0)
      @filename = physical_filename
      @last_modified = File.mtime(filename)
      @format = File.extname(filename).downcase[1..-1].to_sym
      @path = Index.virtual_path_for(filename)
      @line = line.to_i
      if raw_contents.nil? && !File.zero?(filename)
        File.open(@filename) { |f|
          @raw_contents = f.read
        }
      else
        @raw_contents = ''
      end

      begin
        @meta, @markup, has_meta = MetadataParsing.extract(@raw_contents)
      rescue Psych::SyntaxError
        raise $!, "Invalid metadata in #{@path} \n #{$!}"
      end
      @meta = RecursiveOpenStruct.new(@meta)
      
      @markup.lstrip! #remove leading whitespace so parsing works properly
      @markup_heading = ContentFormats[@format].nil? ? nil : ContentFormats[@format].heading(markup)
      @markup_body = ContentFormats[@format].nil? ? markup : ContentFormats[@format].body(markup)

      #Adjust line offset for metadata and heading removal
      @line += @raw_contents.lines.count - @markup_body.lines.count 
    end

    def self.load(filename)
      begin
        t = Template.new(filename)
        t.is_page? ? Page.new(t) : t
      rescue
        debugger
        raise $!, "Error loading template '#{filename}': #{$!}"
      end 
    end





    def body(scope)
      render(scope.settings, {:layout => false}, scope )
    end

    def render_plaintext(scope)
      Nokogiri::HTML(body(scope)).text.squeeze(" \n\t")
    end

    def first_sentences(scope, min_chars)
      Text.get_whole_sentences(render_plaintext(scope),min_chars)
    end


    # Renders the current template and its layouts
    # Pass {:layout => false} to options to disable rendering of layouts
    def render(config = {}, options = {},scope = nil, locals=nil,&block)
      debugger if !options.is_a?(Hash) 

      #Merge engine-specific options from config
      Tilt.alternate_engine_names(engine_name).each do |engine|
        engine_options  = config.respond_to?(engine) ? config.send(engine) : {}
        debugger if !engine_options.is_a?(Hash) or !options.is_a?(Hash)
        options         = engine_options.merge(options)
      end

      #Establish defaults for scope, locals, content type, and default encoding
      scope ||= options.delete(:scope) || Object.new
      locals ||= {}
      locals = options[:locals].merge(locals) if options[:locals]
      
      content_type    = meta.content_type || options.delete(:content_type) || renderer_class.default_mime_type || options.delete(:default_content_type)
      locals[:template] = self


      scope.template_stack ||= []
      stack = scope.template_stack
      stack.push(self)

      options[:default_encoding] ||= config.default_encoding if config.respond_to?(:default_encoding)

      #Removed inner_templates so engines don't complain
      inner_templates = options.delete(:inner_templates) || []
        
      debugger if scope.config.nil?

      old_dir = Dir.pwd
      #Change current directory for benefit of less/scss/etc
      Dir.chdir(File.dirname(filename))

      #Render current template
      i = renderer_class.new(filename,line,options){markup_body}
      output = i.render(scope, locals, &block)

      ##Check for infinite loop via inner_templates
      raise "Infinite loop in layout chain: #{inner_templates.map { |p| "'#{p.path}'"}.join(' -> ')} -> '#{path}'  (did you override the 'layout' method?)" if inner_templates.include?(self) 
      inner_templates << self
      options[:inner_templates] = inner_templates

      #Render parents recursively
      output = layout_template.render(config, options,scope,locals) {output} unless layout_template.nil? || options[:layout] == false

      Dir.chdir(old_dir)
      stack.pop

      #First template rendered controls the content-type
      output.extend(ContentTyped).content_type = content_type if content_type
      
      output
    end



    #The virtual path of the physical parent directory
    # /app/content/folder/index.md -> "/folder"
    #/app/content/folder.md -> ""
    def dir_path
      self.filename[Paths.content_path.length..-1].sub(/\/[^\/]$/m,'')
    end 



    def engine_name
      format
    end

    #meta.renderer can override the default selection based on engine_name/format
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




    def parent
      parents.first
    end

    def parents
      Enumerator.new do |y|
      parent = path
        while !parent.empty? do
          parent.sub!(/(^|\/)[^\/]+\/?$/m,"")
          y << Index[parent] unless Index[parent].nil?
        end
      end
    end

    def ==(other)
      other.respond_to?(:path) && (self.path == other.path)
    end

    def copy_vars_from(other, *vars)
      vars = [:@filename,:@last_modified,:@format,:@path,:@raw_contents,:@line,:@meta,:@markup,:@markup_body,:@markup_heading] if vars.nil? || vars.empty?
      vars.each do |v|
        instance_variable_set(v,other.instance_variable_get(v))
      end
    end


     def parse_string_list(text)
      return [] if text.nil?
      if text.is_a?(String) 
        text = text.split(',').map { |string| string.strip }
      end
      text
    end
  end
end 
