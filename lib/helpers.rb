module Haml
  module Helpers
  	def menu_tag_current(tag_with_class = :selected, query = 'li', &block)
  		Hw::Helpers.menu_tag_current_in_fragment(request.path,tag_with_class,query,capture_haml(&block))
		end
	end
end

module Hw
	module Helpers
		def self.menu_tag_current_in_fragment(path_to_find, tag_with_class = :selected, elements_to_tag = 'li', fragment)
  		require 'nokogiri'
		  dom = Nokogiri::HTML::fragment(fragment)
		  dom.css(elements_to_tag).each do |i|
		    next if i.css("a[href=\"#{path_to_find}\"]").first.nil?
		    old_class = i['class'];
		    i['class'] = old_class.nil? ? tag_with_class : "#{old_class} #{tag_with_class}"
		  end 
		  dom.to_html
		end
	end
end
