
module Hardwired
  class Template
    module ContentTyped
      attr_accessor :content_type
    end
  
    def title
      meta.title || (heading && "#{heading} - #{Config.config.title}") ||  (path == '/' && Config.config.title)
    end

    def date
      @date ||= meta.date ? DateTime.parse(meta.date) : nil
    end

    def atom_id
      meta.atom_id || "tag:#{Config.config.atom_id || Config.config.url  || request.host},#{date ? date.strftime('%Y-%m-%d') : ""}:#{path}"
    end

    def read_more
      meta.read_more || 'Continue reading'
    end

    def summary (scope = nil, min_characters = 200, options={})
      meta_summary || first_sentences(scope,min_characters, options)
    end

    def meta_summary
      meta.summary && meta.summary.gsub('\n', "\n")
    end

    def other_pages_with_shared_tags
       Index.pages.select { |p| not (p.tags & self.tags).empty? }
    end


    #Returns true if this file is a content file, such as a page or a post
    def is_page?
      return true if flag?('page')  #Permit override with Flags: page
      return false if in_layout_dir? #no pages in _layout
      return false if [:sass,:scss, :less, :coffee].include?(engine_name) #Never css or javascript
      true
    end

    def is_post?
      date && is_page?
    end

    def in_layout_dir?
      
      !path.index(Paths.layout_subfolder).nil? && path.index(Paths.layout_subfolder) < 2 
    end


    #Should return true if the file can be rendered
    def can_render?
      return false if date && date >= DateTime.now 
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

    def add_flag(flag)
      meta.flags = parse_string_list(meta.flags).concat([flag]) unless flag?(flag)
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

    def initialize(physical_filename, virtual_path=nil, raw_contents=nil, line = 0)
      raise "Either a filename or raw_content is required" if physical_filename.nil? && raw_contents.nil? 
      @filename = physical_filename
      @last_modified = File.mtime(filename) unless physical_filename.nil?
      @format = File.extname(filename || virtual_path).downcase[1..-1].to_sym
      @path = virtual_path || Index.virtual_path_for(filename)
      @line = line.to_i
      if raw_contents.nil? 
        raw_contents = !File.zero?(filename) ? File.read(@filename) : ''
      end
      file_lines = raw_contents.lines.count

      begin
        @meta, @markup, has_meta = MetadataParsing.extract(raw_contents)
      rescue Psych::SyntaxError
        raise $!, "Invalid metadata in #{@path} \n #{$!}", $!.backtrace
      end
      @meta = RecursiveOpenStruct.new(@meta)
      
      @markup = @markup.lstrip #remove leading whitespace so parsing works properly
      @markup_heading = ContentFormats[@format].nil? ? nil : ContentFormats[@format].heading(markup)
      @markup_body = ContentFormats[@format].nil? ? markup : ContentFormats[@format].body(markup)

      #Adjust line offset for metadata and heading removal (and lstrop above)

      @markup_body = "\n" * (file_lines - @markup_body.lines.count + line.to_i) + @markup_body
      @markup = "\n" * (file_lines - @markup.lines.count + line.to_i) + @markup
    end

    def serialize_with_yaml
      YAML.dump(Hash[@meta.to_hash.to_a]) + "---\n\n" + @markup.strip
    end 

    def after_load
    end 

    def self.load(filename, virtual_path = nil)
      
      t = Template.new(filename, virtual_path)
      t = t.is_page? ? Page.new(t) : t
      t.after_load
      return t
    rescue 
      raise $!, "Error loading template '#{filename}'#{virtual_path ? " under virtual path '" + virtual_path  + "'" : ""}: #{$!}", $!.backtrace
    end





    def body(scope, options={})
      render(scope.config, {:layout => false, :page => self}.merge(options), scope )
    end

    def render_plaintext(scope, options={})
      Nokogiri::HTML(body(scope, options)).text.squeeze(" \n\t")
    end

    def first_sentences(scope, min_chars, options={})
      Text.get_whole_sentences(render_plaintext(scope,options),min_chars)
    end


    # Renders the current template and its layouts
    # Pass {:layout => false} to options to disable rendering of layouts
    def render(config = {}, options = {},scope = nil, locals=nil,&block)
      debugger if !options.is_a?(Hash) 

      #Merge engine-specific options from config
      Tilt.alternate_engine_names(engine_name).each do |engine|
        options = config.send(engine).to_hash.merge(options) if config.respond_to?(engine)
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

      
      scope.page_stack ||= []
      page_stack = scope.page_stack
      page = options.delete(:page)
      page_stack.push(page) if page

      options[:default_encoding] ||= config.default_encoding if config.respond_to?(:default_encoding)

      #Removed inner_templates so engines don't complain
      inner_templates = options.delete(:inner_templates) || []
      options_layout = options.delete(:layout) 
      options.delete(:anywhere) #This setting shouldn't propogate any further, it's only for entry level
      
      options.delete(:locals)
      #Remaining options should be accessible
      locals[:options] = options.clone

      debugger if scope.config.nil?

      old_dir = Dir.pwd
      #Change current directory for benefit of less/scss/etc
      Dir.chdir(File.dirname(filename))

      #Render current template
      i = get_cached_renderer(filename,line,options,markup_body)
      output = i.render(scope, locals, &block)
    

      ##Check for infinite loop via inner_templates
      raise "Infinite loop in layout chain: #{inner_templates.map { |p| "'#{p.path}'"}.join(' -> ')} -> '#{path}'  (did you override the 'layout' method?)" if inner_templates.include?(self) 
      inner_templates << self
      options[:inner_templates] = inner_templates

      #Render parents recursively
      output = layout_template.render(config, options,scope,locals) {output} unless layout_template.nil? || (options_layout == false)

      Dir.chdir(old_dir)
      stack.pop
      page_stack.pop if page

      #First template rendered controls the content-type
      output.extend(ContentTyped).content_type = content_type if content_type
      
      output
    end
    
    def get_cached_renderer(filename,line,options,markup_body)
      new_hashcode = markup_body.hash ^ options.hash 
      if @_cached_renderer_invalidation != new_hashcode
        renderer = renderer_class.new(filename,line,options){markup_body}
        @_cached_renderer_invalidation = new_hashcode
        @_cached_renderer = renderer
      end
      renderer || @_cached_renderer 
    end
    private :get_cached_renderer

      


    #The virtual path of the physical parent directory
    # /app/content/folder/index.md -> "/folder"
    #/app/content/folder.md -> ""
    def dir_path
      Index.virtual_parent_dir_for(filename,false) || path.sub(/\/[^\/]+\Z/m,'')
    end 



    def engine_name
      format
    end

    #meta.renderer can override the default selection based on engine_name/format
    def renderer_class
      return @renderer_class unless @renderer_class.nil?
      if not meta.renderer.nil? 
        renderer = Regexp.new("(:|^)" + Regexp.escape(meta.renderer) + "$", :ignorecase)

        matching_instance = Tilt.default_mapping.template_map.values.select{|klass| renderer.match(klass.name)}.first
        return matching_instance unless matching_instance.nil?

        matching_names = Tilt.default_mapping.lazy_map.values.flatten.select{|name| renderer.match(name)}.to_a + [meta.renderer, "Tilt::#{meta.renderer}"]

        matching_names.each do |name|
          klass = constant_defined?(name)
          return klass if klass
        end 
      else
        @renderer_class = Tilt[engine_name]
      end
      raise "Template engine not found: #{meta.renderer || engine_name}" if @renderer_class.nil?
      @renderer_class
    end

    def constant_defined?(name)
      name.split('::').inject(Object) do |scope, n|
        return false if scope.autoload?(n) # skip autload
        return false unless scope.const_defined?(n)
        scope.const_get(n)
      end
    end

    private :constant_defined?




    def parent
      parents.first
    end

    def parents
      y = []
      parent = path
      while !parent.empty? && parent != '/' do
        parent = parent.sub(/(^|\/)[^\/]+?$/,"")
        y << Hardwired::Index[parent] unless Hardwired::Index[parent].nil?
      end
      y
    end

    def ==(other)
      other.respond_to?(:path) && (self.path == other.path)
    end



    def parse_string_list(text)
      return [] if text.nil?
      if text.is_a?(String) 
        text = text.split(',').map { |string| string.strip }
      end
      text
    end



    def copy_vars_from(other, *vars)
      vars = [:@filename,:@last_modified,:@format,:@path,:@line,:@meta,:@markup,:@markup_body,:@markup_heading] if vars.nil? || vars.empty?
      vars.each do |v|
        instance_variable_set(v,other.instance_variable_get(v))
      end
    end
  end

  class Page < Template
    def initialize(filename)
      if filename.instance_of?(Template)
        copy_vars_from(filename)
      else
        debugger
        super
      end
    end
  end
end 

