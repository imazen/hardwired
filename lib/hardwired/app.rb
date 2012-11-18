
#If certain folders are KNOWN to contain only static files, we can speed those up
#use Rack::Static, :urls => ["/public"]
#use Rack::Static, :urls => ["/attachments"], :root "content"



#Register parsers for file types that support automatic header parsing
Hardwired::ContentFormats.register Hardwired::ContentFormats::Markdown, :mdown, :md, :markdown
Hardwired::ContentFormats.register Hardwired::ContentFormats::Haml, :haml
Hardwired::ContentFormats.register Hardwired::ContentFormats::Textile, :textile
Hardwired::ContentFormats.register Hardwired::ContentFormats::Html, :htmf
Hardwired::ContentFormats.register Hardwired::ContentFormats::Slim, :slim



Encoding.default_external = 'utf-8' if RUBY_VERSION =~ /^1.9/
module Hardwired 
	class Base < Sinatra::Base

		attr_accessor :select_menu, :page

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

		  def before_render_file(file)
		  	page = file
		  end

		  #So standard sinatra templates can access 'config'
		  def config
		  	settings
		  end
		  def index
		  	Hardwired::Index
		  end 

		  def render_file(path, options={})
	  		file = Hardwired::Index[path]
	  		return nil if file.nil? || !file.can_render?
				before_render_file(file)
	  		file.render(settings,options,self)
		  end

		  def auto_render(path, options=nil)
		  	#TODO - look for 'path' inside @page.filename directory, _layout, and root. Default to no layout
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
	    if request.path_info =~ Regexp.new('./$')
	      redirect to(request.path_info.sub(Regexp.new('/$'), '') + request.query_string)
	    end
	  end


		## Static files rule - As-is serving for non-interpreted extensions and *.static.*
		get '*' do
			path, ext = split_ext
			base_path = Hardwired::Paths.content_path(path)
			local_path = "#{base_path}.#{ext}";
			static_path = "#{base_path}.static.#{ext}"
			interpreted_ext = !Tilt.mappings[ext].empty?
			# We only serve the file if it's .static.* or if it's not an interpreted (Tilt-registered) extension
			pass if interpreted_ext && !File.file?(static_path)
			pass if !interpreted_ext && !File.file?(local_path)
			
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
	  	output = render_file(request.path_info)
	  	pass if output.nil?
	  	output 
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
	    render_file('404')
	  end

	  error do
	    render_file('500')
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