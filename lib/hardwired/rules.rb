module Hardwired
	class Rules
    class << self
			attr_accessor :content_extensions



			def template_options_for_page(page)

				return page.template || 'page', {:views => Hardwired::Paths.layout_path, :layout => page.layout || 'layout'}
			end

		end 
	end
end
Hardwired::Rules.content_extensions = ['markdown','mkd','md','mdown', 'textile','rdoc','wiki','creole','mw','mediawiki', 'haml']
