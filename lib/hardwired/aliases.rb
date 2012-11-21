# This file implements redirection support

module Hardwired
    
  module Aliases
    extend Sinatra::Extension

    # set some settings for development
    #configure :development do
    #  set :reload_stuff, true
    #end

    # Add a before filter to perform any redirects requested by individual pages

    before do

      #return if response.status != 404
      this_url = AliasTable.normalize(request.fullpath)
      table = AliasTable.all
      if table.include?(this_url)
        redirect table[this_url], 301 # Always do permanent redirects
      end
    end

    ## Todo - refactor to self.class instance instead of static?
    class AliasTable

      # Cache the redirects table in a static variable
      def self.all
        @@all ||= AliasTable.build_alias_table
      end
      
      def self.build_alias_table
        table = {}
        Index.files.each do |p| 
          dest = p.path
          if p.meta.redirect_to
            dest = p.meta.redirect_to
            table[AliasTable.normalize(p.path)] = dest
          end
          p.aliases.each  do |url| 
            url = AliasTable.normalize(url)
            #prevent cyclic redirects
            table[url] = dest unless url == AliasTable.normalize(dest)
          end
        end
        return table
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
        return meta.aliases.split(/\s+/) # Aliases are separated by whitespaces. Use '+' to represent a space in a URL.
      else
        return []
      end
    end
  end
end

