
#If certain folders are KNOWN to contain only static files, we can speed those up
#use Rack::Static, :urls => ["/public"]
#use Rack::Static, :urls => ["/attachments"], :root "content"



#Register parsers for file types that support automatic header parsing
Hardwired::ContentFormats.register Hardwired::ContentFormats::Markdown, :mdown, :md, :markdown
Hardwired::ContentFormats.register Hardwired::ContentFormats::Haml, :haml
Hardwired::ContentFormats.register Hardwired::ContentFormats::Textile, :textile
Hardwired::ContentFormats.register Hardwired::ContentFormats::Html, :htmf



Encoding.default_external = 'utf-8' if RUBY_VERSION =~ /^1.9/
module Hardwired 
	class Base < Sinatra::Base


		#Make config.yml available as 'settings'
		register Sinatra::ConfigFile

		#Enable content_for in templates
		register Sinatra::ContentFor

		#Enable redirect support
		register Hardwired::Aliases

		#Import helper methods
		helpers Hardwired::Helpers

		helpers do

	    def find_template(views, name, engine, &block)
		  	#normal
		    super(views, name, engine, &block)
		    #_layout folder
		    super(Hardwired::Paths.layout_path, name.to_s, engine, &block)
		  end
		end

		set :root, Proc.new {Hardwired::Paths.root_path }
		set :views, Proc.new { Hardwired::Paths.content_path }
		set :haml, { :format => :html5 }

		
		before do
			#Protect against ../ attacks and _layout access
			if request.path =~ /\.\.[\/\\]/ or request.path_info =~ /^\/_layout/mi
	      not_found
	    end
	    #Redirect incoming urls so they don't have a trailing '/'
	    if request.path =~ Regexp.new('./$')
	      redirect to(request.path.sub(Regexp.new('/$'), ''))
	    end
	    #Set config alias
	    @config = settings
	  end


		## Static files rule - As-is serving for non-interpreted extensions and *.static.*
		get '*' do
			path, ext = split_ext
			base_path = Hardwired::Paths.content_path(path)
			local_path = "#{base_path}.#{ext}";
			static_path = "#{base_path}.static.#{ext}"
			interpreted_ext = !Tilt.mappings[ext].empty?
			# We only serve the file if it's .static.* or if it's not an interpreted (Tilt-registered) extension
			pass if interpreted_ext and !File.file?(static_path)
			pass if !interpreted_ext and !File.file?(local_path)
			
			real_path = interpreted_ext ? static_path : local_path

			send_file(real_path, request[:download] ? {:disposition => 'attachment'} : {})
	  end

	  # Special handling for non-static .css and .js requests so they'll match the 'direct evaluation' routes
	  get %r{(.+).(css|js)} do
	  	request.path_info, _ = split_ext
	  	pass
	  end



	  #All interpreted files are in the index, even scss and coffeescript
	  get '*' do
	  	@page = Hardwired::Index[request.path_info]

	  	debugger if !request.path_info.index(/\./) and (!@page  or !@page.can_render?)
			#debugger
	  	pass if !@page.can_render?
	  	@page.render(settings,{},self)
	  end 
  end

  class Bootstrap < Base

    get '/robots.txt' do
      content_type 'text/plain', :charset => 'utf-8'
      <<-EOF
# robots.txt
# See http://en.wikipedia.org/wiki/Robots_exclusion_standard
      EOF
    end


	  not_found do
	    haml(:'404')
	  end

	  error do
	    haml(:'500')
	  end unless development?




	  get '/articles.xml' do
	    content_type :xml, :charset => 'utf-8'
	    @articles = Index.find_articles.select { |a| a.date }[0..9]
	    haml(:atom, :format => :xhtml, :layout => false)
	  end

	  get '/sitemap.xml' do
	    content_type :xml, :charset => 'utf-8'
	    @pages = Index.find_all
	    @last = @pages.map { |page| page.last_modified }.inject do |latest, page|
	      (page > latest) ? page : latest
	    end
	    haml(:sitemap, :format => :xhtml, :layout => false)
	  end

	end
end