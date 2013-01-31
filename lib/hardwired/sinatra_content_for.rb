module Hardwired
 
  # = Sinatra::ContentFor
  #
  # <tt>Sinatra::ContentFor</tt> is a set of helpers that allows you to capture
  # blocks inside views to be rendered later during the request. The most
  # common use is to populate different parts of your layout from your view.
  #
  # The currently supported engines are: Erb, Erubis, Haml and Slim.
  #
  # == Usage
  #
  # You call +content_for+, generally from a view, to capture a block of markup
  # giving it an identifier:
  #
  #     # index.erb
  #     <% content_for :some_key do %>
  #       <chunk of="html">...</chunk>
  #     <% end %>
  #
  # Then, you call +yield_content+ with that identifier, generally from a
  # layout, to render the captured block:
  #
  #     # layout.erb
  #     <%= yield_content :some_key %>
  #
  # === Classic Application
  #
  # To use the helpers in a classic application all you need to do is require
  # them:
  #
  #     require "sinatra"
  #     require "sinatra/content_for"
  #
  #     # Your classic application code goes here...
  #
  # === Modular Application
  #
  # To use the helpers in a modular application you need to require them, and
  # then, tell the application you will use them:
  #
  #     require "sinatra/base"
  #     require "sinatra/content_for"
  #
  #     class MyApp < Sinatra::Base
  #       helpers Sinatra::ContentFor
  #
  #       # The rest of your modular application code goes here...
  #     end
  #
  # == And How Is This Useful?
  #
  # For example, some of your views might need a few javascript tags and
  # stylesheets, but you don't want to force this files in all your pages.
  # Then you can put <tt><% yield_content :scripts_and_styles %></tt> on your
  # layout, inside the <head> tag, and each view can call <tt>content_for</tt>
  # setting the appropriate set of tags that should be added to the layout.
  #
  module ContentFor

    def content_for(key, &block)
      content_blocks[key.to_sym] << block.call
      return ""
    end

    def content_for?(key)
      content_blocks[key.to_sym].any?
    end

    def yield_content(key, *args)
      content_blocks[key.to_sym].join
    end

    private

    def content_blocks
      @content_blocks ||= Hash.new {|h,k| h[k] = [] }
    end
  end

end