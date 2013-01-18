module Hardwired
  class Index

    @@cache = {}
    @@loaded = false

    def self.cache
      @@cache
    end

   
    def self.load_all
      return if @@loaded
      ## Find all files with Tilt-registered extensions in every mounted folder
      mounted_folders.each_pair do |k,v|
        file_pattern = File.join(k, "**", "*.{#{Tilt.mappings.keys.join(',')}}")
        Dir.glob(file_pattern).map do |path|
          #skip static files
          next if path =~ /\.static./i
          ext = File.extname(path)
          next if ext.nil? || !Tilt[ext[1..-1]]
          _ = load_physical(path)
        end
      end
      @@loaded = true ##So other threads know when we're done
    end

    def self.load_physical(fname)
      
      fname = fname.to_s
      return if !File.file?(fname) #Skip directories

      url = virtual_path_for(fname)
      begin
        #Prevent conflicts
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
      return @@cache['/' + path.to_s.sub(/\A\/+/,"")]
    end

    #Searches for the template in multiple folders - unless shortname starts with a slash, in which case only content root is searched.
    #Order: 1. Root, 2. current_path, 3. _layout and other search_paths
    def self.find(shortname, current_path = nil)
      #Return nil if we were provided it
      return nil if shortname.nil?
      s = shortname.to_s #Support symbols
      return self[s] if self[s] #1. Try as-is (root)
      return nil if s[0] == '/' #Leading slashes mean 'absolute', not relative

      #search current dir if provided
      if current_path
        p = Paths.join(current_path,s)
        return self[p] if self[p]
      end
      #Search in search paths (includes _layout)
      self.search_paths.each { |path|
        p = Paths.join(path,s)
        return self[p] if self[p]
      }
      nil
    end

    def self.search_paths
      @@search_paths ||= [Paths.layout_subfolder]
    end

    def self.add_search_path(path)
      search_paths << path
    end

    #Enumerates all indexed files
    def self.files(&block)
      load_all
      Enumerator.new  do |y| 
        @@cache.each do |k,v|
          y << v
        end
      end.each(&block)
    end

    #Enumerates all indexed files, but requires a filtering block
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
      pages.select { |p| p.tag?(tag)}
    end

    def self.posts_tagged(tag)
      posts.select { |p| p.tag?(tag)}
    end

    def self.mounted_folders
      @@mounted_folders ||= {Hardwired::Paths.content_path => "/"}
    end

    def self.mount_folder(physical_path, virtual_path)
      mounted_folders[physical_path] = virtual_path
    end 

    #Useful for getting the 'virtual' working directory for a template, for located partials or layouts
    def self.virtual_parent_dir_for(fname)
      self.make_almost_virtual(fname).sub(/\/[^\/]\Z/m,'')
    end
  
    #Get the virtual path for any filename within a mounted folder
    def self.virtual_path_for(fname)
      ## Reduce "/index" to "/" if present
      path = make_almost_virtual(fname).sub(/\/index\Z/im,"/")
      
      (path.length > 1 && path[-1] == ?/) ? path[0..-2] : path

    end


    def self.make_almost_virtual(fname)
      fname = fname.to_s

      mounted_folders.each_pair { |k,v|
        if fname.start_with?(k) 
          #Replace physical portion with 'mount folder'
          p = v.gsub(/\/+\Z/m,'') + "/" + fname[k.length..-1].gsub(/\A\/+/m,'')
          #Strip extension
          ext = File.extname(p).downcase[1..-1];
          p = p[0..-(ext.length + 2)] unless ext.nil? or ext.empty?
          # Strip leading, trailing slashes, then restore leading slash
          return '/' + p.gsub(/^\/+|\/+$/m,"")
        end
      }
      raise "No root directory matches '#{fname}'"
    end 

    
  end 
end

