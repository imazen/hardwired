require 'sinatra/extension'

module Hardwired
  module Aliases
    extend Sinatra::Extension

    # set some settings for development
    #configure :development do
    #  set :reload_stuff, true
    #end

    # Add a before filter to perform any redirects requested by individual pages
    before do
      this_url = AliasTable.normalize(request.fullpath)
      table = AliasTable.all()
      if table.include?(this_url)
        redirect table[this_url], 301 # Always do permanent redirects
      end
    end


    class AliasTable
      @@all = nil
      
      # Cache the redirects table in a static variable
      def self.all
        if @@all.nil?
          @@all = AliasTable.build_alias_table
        end
        return @@all
      end
      
      def self.build_alias_table
        table = {}
        Hardwired::Page.find_all().each do |p| 
          dest = p.abspath
          if p.metadata("Redirect To")
            dest = p.metadata("Redirect To")
            table[AliasTable.normalize(p.abspath)] = dest
          end
          p.aliases.each  do |url| 
            table[AliasTable.normalize(url)] = dest
          end
        end
        return table
      end
      
      def self.normalize(url)
        return url.gsub("+"," ").downcase #TODO: Normalize url encoding
      end
    end
  end 
end

module Hardwired
  class Page
  
    def aliases
      if metadata('aliases')
        return metadata('aliases').split(/\s+/) # Aliases are separated by whitespaces. Use '+' to represent a space in a URL.
      else
        return []
      end
    end
  end
end

