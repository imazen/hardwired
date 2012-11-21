
require 'sinatra/extension'

#NestaCMS compatibility shims

#For Nesta .mdown compatibility - Still need to rename *.erbis -> *.erb
Tilt.register 'mdown', Tilt[:md] 

module Nesta
  Page = Hardwired::Page
  
end

module Hardwired
	class Page

		def metadata(name)
			meta.call(name) if meta.respond_to? name
			nil
		end

    def description
      meta.description
    end

     def keywords
      meta.keywords
    end

    def flagged_as? (flag)
    	flag? flag
    end

    def lib(name)
    	lib?(name)
    end

    def abspath
      path
    end
    
    def categories
    	[]
    end

  end
end

module Hardwired
  module Nesta
    extend Sinatra::Extension

   	## Make Nesta::Config work
    before '*' do
    	Nesta::Config = Hardwired::Config.config unless defined?(Nesta::Config)
    end



    helpers do

			def before_render_file(file)
				#@config = config

				@page = file
				@title = file.title if file.is_page?
				@description = file.meta.description
				@keywords = file.meta.keywords
			end


    	def url_for(page)
        File.join(base_url, page.path)
      end
  
      def base_url
        url = "http://#{request.host}"
        request.port == 80 ? url : url + ":#{request.port}"
      end
  
      def absolute_urls(text)
        text.gsub!(/(<a href=['"])\//, '\1' + base_url + '/') if text 
        text
      end
  
      def nesta_atom_id_for_page(page)
        published = page.date.strftime('%Y-%m-%d')
        "tag:#{request.host},#{published}:#{page.abspath}"
      end
  
      def atom_id(page = nil)
        if page
          page.atom_id || nesta_atom_id_for_page(page)
        else
          "tag:#{request.host},2009:/"
        end
      end
  
      def format_date(date)
        date.strftime("%d %B %Y")
      end
 

      def local_stylesheet_link_tag(name)
        pattern = File.expand_path(Hardwired.Paths.content_path("/css/#{name}.s{a,c}?ss"))
        if Dir.glob(pattern).size > 0
          haml_tag :link, :href => "/css/#{name}.css", :rel => "stylesheet"
        end
      end


    	def breadcrumb_ancestors
        ancestors = []
        page = @page
        while page
          ancestors << page
          page = page.parent
        end
        ancestors.reverse
      end

      def display_breadcrumbs(options = {})
        haml_tag :ul, :class => options[:class] do
          breadcrumb_ancestors[0...-1].each do |page|
            haml_tag :li do
              haml_tag :a, :<, :href => path_to(page.abspath), :itemprop => 'url' do
                haml_tag :span, :<, :itemprop => 'title' do
                  haml_concat link_text(page)
                end
              end
            end
          end
          haml_tag(:li, :class => current_breadcrumb_class) do
            haml_concat link_text(@page)
          end
        end
      end
     end

  end
end

