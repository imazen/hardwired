require 'sinatra/extension'

#Handles redirects for /page_id/, /?p=page_id, /?page_id=page_id
#Uses WP ID: metadata values
# Also redirects /feed/ -> /rss.xml
# And /comments/feed to disqus.

module Hardwired
  module Wordpress
    extend Sinatra::Extension

    before do

      # Patterns to match

      #/[int]/*
      #?p=[int]
      #?page_id=[int]

      dest = nil

      if request.GET["p"] =~ /\A\d+\Z/
        dest ||= PageIdentifiers.ids[request.GET["p"].to_i]
      end
      if request.GET["page_id"] =~ /\A\d+\Z/
        dest ||= PageIdentifiers.ids[request.GET["page_id"].to_i]
      end

      if request.path =~ /\A\/(\d+)\//
        dest ||= PageIdentifiers.ids[$1.to_i]
      end

      if dest
        redirect dest, 301 # Always do permanent redirects
      end
    end

    get '/feed/' do
       redirect '/rss.xml', 301
    end
    
    get '/comments/feed/' do
      if config.disqus_short_name
        redirect "#{config.disqus_short_name}.disqus.com/latest.rss", 301
      end
    end


    class PageIdentifiers
      @@ids = nil

      def self.ids
        return @@ids unless @@ids.nil?
        table = {}
        Index.files.each do |p| 
          next if p.wordpress_ids.nil?
          dest = p.meta.redirect_to || p.path
          p.wordpress_ids.each do |id| 
            table[id] = dest 
          end
        end
        @@ids = table
      end
      
    end
  end 
end

module Hardwired
  class Template
  
    def wordpress_ids
      if meta.wp_id
        return (meta.wp_id.is_a?(Array) ? meta.wp_id : meta.wp_id.is_a?(String) ? meta.wp_id.split(/\s+/) : [meta.wp_id]).collect { |i| i.to_i }
      else
        return []
      end
    end
  end
end

