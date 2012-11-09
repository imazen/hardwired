module Hardwired
	class Rules
    class << self
			attr_accessor :content_extensions


		end 
	end
end
Hardwired::Rules.content_extensions = ['markdown','mkd','md','mdown', 'textile','rdoc','wiki','creole','mw','mediawiki']
