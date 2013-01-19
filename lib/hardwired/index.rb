module Hardwired
  class Index
    class << self

      @cache = {}
      @loaded = false

      def cache
        @cache ||= {}
      end

      def loaded
        @loaded
      end

      def load_all
        return if loaded
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
        @loaded = true ##So other threads know when we're done
      end

      def load_physical(fname, virtual_path = nil)

        fname = fname.to_s
        return if !File.file?(fname) #Skip directories

        url = virtual_path ? ('/' + virtual_path.to_s.sub(/\A\/+/,"")) : virtual_path_for(fname)
        begin
          #Prevent conflicts
          if !cache[url].nil?
            other_name = cache[url].filename 
            raise "Conflicting files #{fname} and #{other_name} share the same url #{url}! Filenames must be unique. #{@@cache[url].inspect}" if other_name != fname
          end

          #We must check that this file hasn't already been cached - multiple threads call cache_all simultaneously
          if cache[url].nil? || File.mtime(fname) != cache[url].last_modified
            cache[url] = Template.load(fname,url)
          end

        rescue Errno::ENOENT
          cache[url] = nil 
        end 

        cache[url]
      end

      def add_common_file(name, virtual_path)
        physical_path = Paths.common_path(name)
        if !File.file?(physical_path)
          Dir.glob("#{physical_path}.{#{Tilt.mappings.keys.join(',')}}").map do |path|
            ext = File.extname(path)
            next if ext.nil? || !Tilt[ext[1..-1]]
            physical_path = path
            break
          end
        end

        load_physical(physical_path, virtual_path)
      end



      def [](path)
        load_all
        return cache['/' + path.to_s.sub(/\A\/+/,"")]
      end

      #Searches for the template in multiple folders 
      #Order (if no leading slash): 1. current_path, 2. root, 3. _layout and other search_paths
      #Order (if shortname has leading slash): 1. root
      def find(shortname, current_path = nil)

        #Return nil if we were provided it
        return nil if shortname.nil?
        #Support symbols
        s = shortname.to_s 

        #If it starts with a slash, we only search in the root.
        return self[s] if s[0] == '/' 

        #Search in current_path, root, and search paths (includes _layout)
        search_these = [current_path, nil, search_paths].flatten

        #p "Looking for #{s} in #{search_these.join(', ')}"

        
        search_these.each { |path|
          p = path ? Paths.join(path,s) : s
          return self[p] if self[p]
        }
        nil
      end

      def search_paths
        @search_paths ||= [Paths.layout_subfolder]
      end

      def add_search_path(path)
        search_paths << path
      end

      #Enumerates all indexed files
      def files(&block)
        load_all
        Enumerator.new  do |y| 
          cache.each do |k,v|
            y << v
          end
        end.each(&block)
      end

      #Enumerates all indexed files, but requires a filtering block
      def enum_files
        load_all
        Enumerator.new  do |y| 
          cache.each do |k,v|      
            y << v if yield(v)
          end
        end
      end

      def pages
        @cached_pages ||= enum_files { |p| p.is_page? && p.can_render? }.to_a
      end

      def posts
        @cached_posts ||= enum_files { |p| p.is_page? && p.can_render? && p.is_post? }.sort { |x, y| y.date <=> x.date }
      end

      def page_tags
        pages.map{ |p| p.tags }.flatten.uniq
      end


      def post_tags
        posts.map{ |p| p.tags }.flatten.uniq
      end

      def pages_tagged(tag)
        pages.select { |p| p.tag?(tag)}
      end

      def posts_tagged(tag)
        posts.select { |p| p.tag?(tag)}
      end

      def mounted_folders
        @mounted_folders ||= {Hardwired::Paths.content_path => "/"}
      end

      #Useful for getting the 'virtual' working directory for a template, for located partials or layouts
      def virtual_parent_dir_for(fname, raise_if_outside=true)
        path = make_almost_virtual(fname,raise_if_outside)
        return nil if path.nil?
        path.sub(/\/[^\/]+\Z/m,'')
      end
    
      #Get the virtual path for any filename within a mounted folder
      def virtual_path_for(fname, raise_if_outside=true)
        ## Reduce "/index" to "/" if present
        path = make_almost_virtual(fname,raise_if_outside)

        return nil if path.nil?

        path.sub!(/\/index\Z/im,"/")
        
        (path.length > 1 && path[-1] == ?/) ? path[0..-2] : path
      end

      def is_outside?(fname)
        make_almost_virtual(fname, false).nil?
      end 

      def make_almost_virtual(fname, raise_if_outside=true)
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
        raise "No root directory matches '#{fname}'" if raise_if_outside
        nil
      end 
    end
  end 
end

