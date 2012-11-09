
require 'sinatra/extension'

#NestaCMS compatibility shims

#For Nesta .mdown compatibility - Still need to rename *.erbis -> *.erb
Tilt.register 'mdown', Tilt[:md] 

module Nesta
  Page = Hardwired::Page
  
end

module Hardwired
  module Nesta
    extend Sinatra::Extension

   	## Make Nesta::Config work
    before '*' do
    	Nesta::Config = settings
    end


    helpers do
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

