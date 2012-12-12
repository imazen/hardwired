module Hardwired
  class Index
    @@cache = {}
    @@loaded = false

    def self.cache
      @@cache
    end

   
    def self.load_all
      return if @@loaded
      ## All files with Tilt-registered extensions
      file_pattern = File.join(Hardwired::Paths.content_path, "**", "*.{#{Tilt.mappings.keys.join(',')}}")
      Dir.glob(file_pattern).map do |path|
        #skip static files
        next if path =~ /\.static./i
        ext = File.extname(path)
        next if ext.nil? || !Tilt[ext[1..-1]]
        _ = load_physical(path)
      end
      @@loaded = true ##So other threads know when we're done
    end

    def self.load_physical(fname)
      return if !File.file?(fname) #To skip dirs

      url = virtual_path_for(fname)


      begin
        
        if !@@cache[url].nil?
          other_name = @@cache[url].filename 
          raise "Conflicting files #{fname} and #{other_name} share the same url #{url}! Filenames must be unique. #{@@cache[url].inspect}" if other_name != fname
        end

        #We must check that this file hasn't already been cached - multiple threads call cache_all simultaneously
        if @@cache[url].nil? || File.mtime(fname) != @@cache[url].last_modified
          @@cache[url] = Template.load(fname)
        end

      rescue Errno::ENOENT
        @@cache[url] = nil 
      end 

      @@cache[url]
    end

    def self.[](path)
      load_all
      return @@cache['/' + path.sub(/^\/+/,"")]
    end

    def self.files(&block)
      load_all
      Enumerator.new  do |y| 
        @@cache.each do |k,v|
          y << v
        end
      end.each(&block)
    end

    def self.enum_files
      load_all
      Enumerator.new  do |y| 
        @@cache.each do |k,v|      
          y << v if yield(v)
        end
      end
    end

    def self.pages
      @@cached_pages ||= enum_files { |p| p.is_page? && p.can_render? }.to_a
    end

    def self.posts
      @@cached_posts ||= enum_files { |p| p.is_page? && p.can_render? && p.is_post? }.sort { |x, y| y.date <=> x.date }
    end

    def self.page_tags
      pages.map{ |p| p.tags }.flatten.uniq
    end


    def self.post_tags
      posts.map{ |p| p.tags }.flatten.uniq
    end

    def self.pages_tagged(tag)
      pages.select { |p| p.tags.include?(tag)}
   end

    def self.posts_tagged(tag)
      posts.select { |p| p.tags.include?(tag)}
   end
 
    def self.virtual_path_for(fname)
      #Strip base path and last extension
      url = fname[Hardwired::Paths.content_path.length..-1]
      ext = File.extname(url).downcase[1..-1];
      url = url[0..-(ext.length + 2)] unless ext.nil? or ext.empty?

      ## Reduce /index to /
      url = url.sub(/\/index$/im,"/")
      # Strip leading, trailing slashes, then restore leading slash
      '/' + url.gsub(/^\/+|\/+$/m,"")
    end


    
  end 
end

