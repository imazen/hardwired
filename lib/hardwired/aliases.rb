# This file implements redirection support

module Hardwired
  module Aliases
    extend SinatraExtension


    # Add a before filter to perform any redirects requested by individual pages
    before do

      #return if response.status != 404
      dest = AliasTable.get_final_destination(request.path, request.fullpath)


      if dest
        redirect dest, 301 # Always do permanent redirects
      end
    end

    #Add an alias externally
    def add_alias(path, page)
      AliasTable.add_alias(path,page)
    end 
    

    ## Todo - refactor to self.class instance instead of static?
    class AliasTable

      def self.get_final_destination(path, fullpath)
        #Don't consider querystring when performing comparison
        this_url = AliasTable.normalize(path)
        this_full_url = AliasTable.normalize(fullpath)
        table = AliasTable.exact
        prefixes = AliasTable.prefixes

        dest ||= table[this_full_url]
        dest ||= table[this_url]
        dest ||= prefixes[this_full_url]
        dest
      end 

      @@exact = nil
      @@prefixes = nil

      # Cache the redirects table in a static variable
      def self.exact
        @@exact, @@prefixes = AliasTable.build_alias_tables if @@exact.nil?
        @@exact
      end

      def self.prefixes
        @@exact, @@prefixes = AliasTable.build_alias_tables if @@prefixes.nil?
        @@prefixes
      end

      #Add an alias to a page later, externally
      def self.add_alias(path, page)
        p = page
        url = '/' + path.to_s.gsub(/\A\/+|\/+\Z/,'')
        if page.is_a?(Symbol) || page.is_a?(String)
          p = Index[p]
        end
        return if p.nil?

        dest = p.meta.redirect_to || p.path
        if url.end_with?("*")
          url = AliasTable.normalize(url[0..-2])
          #prevent cyclic redirects
          self.prefixes[url] = dest unless AliasTable.normalize(dest).start_with?(url)
        else
          url = AliasTable.normalize(url)
          #prevent cyclic redirects
          self.exact[url] = dest unless url == AliasTable.normalize(dest)
        end
      end
      
      def self.build_alias_tables
        table = {}
        prefixes = PrefixHash.new
        Index.files.each do |p| 
          dest = p.path
          if p.meta.redirect_to
            dest = p.meta.redirect_to
            table[AliasTable.normalize(p.path)] = dest
          end
          p.aliases.each  do |url| 
            if url.end_with?("*")
              url = AliasTable.normalize(url[0..-2])
              #prevent cyclic redirects
              prefixes[url] = dest unless AliasTable.normalize(dest).start_with?(url)
            else
              url = AliasTable.normalize(url)
              #prevent cyclic redirects
              table[url] = dest unless url == AliasTable.normalize(dest)
            end
          end
        end
        return table, prefixes
      end
      
      def self.normalize(url)
        #Decode + -> " ", remove trailing slash, lowercase
        return url.gsub("+"," ").sub(/(\/)+$/,'').downcase #TODO: Normalize url encoding
      end
    end
  end 
end

module Hardwired
  class Template
  
    def aliases
      if meta.aliases
        return meta.aliases.is_a?(Array) ? meta.aliases : meta.aliases.split(/\s+/) # Aliases are separated by whitespaces. Use '+' to represent a space in a URL.
      else
        return []
      end
    end
  end
end

