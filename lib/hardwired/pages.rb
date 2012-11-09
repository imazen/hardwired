module Hardwired
  class TemplateFile
    @@cache = {}
    @@loaded = false

    def self.cache
      @@cache
    end

    attr_reader :filename, :path, :mtime, :format

    def self.load_all
      return if @@loaded
      ## All files with Tilt-registered extensions
      file_pattern = File.join(Hardwired::Paths.content_path, "**", "*.{#{Tilt.mappings.keys.join(',')}}")
      Dir.glob(file_pattern).map do |path|
        #skip statics, layouts, and parts
        next if path =~ /\.(static|layout|part)\./i
        load_physical(path)
      end
      @@loaded = true ##So other threads know when we're done
    end

    def self.load_physical(fname)
      return if !File.file?(fname) #To skip dirs
      #Strip base path, leading slashes, and last extension
      url = fname[Hardwired::Paths.content_path.length..-1].sub(/^\/+/,"")
      ext = File.extname(url).downcase[1..-1];
      url = url[0..-(ext.length + 2)] unless ext.nil? or ext.empty?

      #Parse file category
      cat = url[/\.(content|c|direct|d)$/i]
      url = url[0..-(cat.length + 1)] unless cat.nil?


      #Should we attempt to parse this file as content?
      is_content =  (cat.nil? and Hardwired::Rules.content_extensions.include?(ext)) or /^\.(content|c)$/i === cat

      ## Reduce /index/
      url = url.sub(/(^|\/)index$/im,"")

      debugger if url == '' and !is_content

      begin
        #We must check that this file hasn't already been cached - multiple threads call cache_all simultaneously
        if is_content && (@@cache[url].nil? || File.mtime(fname) != @@cache[url].mtime)
          @@cache[url] = Page.new(fname, url)
        end

        if !is_content and @@cache[url].nil?
          @@cache[url] = TemplateFile.new(fname, url)
        end
      rescue Errno::ENOENT
        @@cache[url] = nil 
      end 

      @@cache[url]
    end

    def initialize(filename, path)
      @filename = filename
      @mtime = File.mtime(filename)
      @format = File.extname(filename).downcase[1..-1].to_sym
      @path = path
    end

    def self.find_by_path(path)
      TemplateFile.load_all
      @@cache[path.sub(/^\/+/,"")]
    end

    def self.all_files
      TemplateFile.load_all
      Enumerator.new  do |yielder| 
        @@cache.each do |k,v|
          yielder.yield v
        end
      end 
    end

    def self.all_pages
      TemplateFile.load_all
      Enumerator.new  do |yielder| 
        @@cache.each do |k,v|
          yielder.yield v if v.content? and !v.hidden?
        end
      end 
    end

    def self.all 
      all_pages 
    end

    #Returns true if this file is a content file
    def content?
      false
    end

    def parent
      parents.first
    end

    def hidden?
      false
    end 

    def parents
      parent = path
      while !parent.empty? do
        parent.sub!(/(^|\/)[^\/]+\/?$/m,"")
        yield @@cache[parent] unless @@cache[parent].nil?
      end
    end

    def ==(other)
      other.respond_to?(:path) && (self.path == other.path)
    end
  end 



  class Page < TemplateFile
    def content?
      true
    end



    def initialize(filename,url)
      super

      @metadata = RecursiveOpenStruct.new
      @markup = ''

      if !File.zero?(filename)
        File.open(@filename) { |f|
          @raw_contents = f.read
        }
        @metadata, @markup = Hardwired::MetadataParsing.parser.new.extract(@raw_contents)
        @metadata = RecursiveOpenStruct.new(@metadata)
      end
    end

    def markup
      @markup
    end

    def heading
      Hardwired::ContentFormats[@format].heading(markup)
    end

    def body(scope = nil)
      body_text = Hardwired::ContentFormats[@format].body(markup)
      convert_to_html(@format, scope, body_text)
    end

    def hidden?
      false
    end

    def template
      :'page'
    end

    def layout
      :'layout'
    end



    def to_html(scope = nil)
      convert_to_html(@format, scope, @markup)
    end


  private

    def tag_lines_of_haml(text)
      tagged = (text =~ /^\s*%/)
      if tagged
        text
      else
        text.split(/\r?\n/).inject("") do |accumulator, line|
          accumulator << "%p #{line}\n"
        end
      end
    end

    private


    def convert_to_html(format, scope, text)
      text = tag_lines_of_haml(text) if @format == :haml

      custom_renderer = metadata('renderer')

      if !custom_renderer.nil?
        renderer = Regexp.new("(:|^)" + Regexp.escape(custom_renderer) + "$", :ignorecase)
        engine = Tilt.mappings.values.flatten.select{ |obj| renderer.match(obj.name) }.first
        raise "Custom renderer not found: #{custom_renderer}" if engine.nil?
      else
        engine = Tilt[format]
        raise "Template engine not found: #{format}" if engine.nil?
      end

      template = engine.new(@fname,0,{}){text}
      template.render(scope)
    end
  end
  #Alias so Hardwired::Pages.all can work
  Pages = Page
end 
