#This file sets up the default 

# Hardwired route order
=begin
1. Static file served as is IF
	a. File exists and 'ext' is not any supported interpreted extension, 
	b. OR, (or path.static.ext) exists.

2. Redirect slash-terminated URLs to non-slash-terminated URLs, or vice versa.

3. 
5. Direct files are interpreted and served IF
    a. `<url>(/index)?.(direct|d).*` exists, OR `<url>(/index)?.<ext>` exists and `<ext>` is a template type that defaults to direct interpretation.

6. Content files are interpreted and served IF
	a. Pages collection has a URL match
=end

#If certain folders are KNOWN to contain only static files, we can speed those up

#use Rack::Static, :urls => ["/media"], :root "content"




#While Tilt registration is enough for direct files, content files require a specialized parser
Hardwired::ContentFormats.register Hardwired::ContentFormats::Markdown, :mdown, :md, :markdown
Hardwired::ContentFormats.register Hardwired::ContentFormats::Haml, :haml
Hardwired::ContentFormats.register Hardwired::ContentFormats::Textile, :textile
Hardwired::ContentFormats.register Hardwired::ContentFormats::Html, :htmf



Encoding.default_external = 'utf-8' if RUBY_VERSION =~ /^1.9/
module Hardwired 
	class Site < Sinatra::Base


		#Make config.yml available as 'settings'
		register Sinatra::ConfigFile

		#Enable content_for in templates
		register Sinatra::ContentFor

		#Enable redirect support

		register Hardwired::Aliases

		helpers do
      def rules
      	settings.rules
      end
		end

		set :root, Proc.new {Hardwired::Paths.root_path }
		set :views, Proc.new { Hardwired::Paths.content_path }
		set :haml, { :format => :html5 }

		#Redirect incoming urls so they don't have a trailing '/'
		before do
	    if request.path =~ Regexp.new('./$')
	      redirect to(request.path.sub(Regexp.new('/$'), ''))
	    end
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
			
			send_file interpreted_ext ? static_path : local_path
	  end

	  # Special handling for non-static .css and .js requests so they'll match the 'direct evaluation' routes
	  get %r{(.+).(css|js)} do
	  	request.path_info, _ = split_ext
	  	pass
	  end



	  #All interpreted files are in the index
	  get '*' do
	  	@page = Hardwired::TemplateFile.find_by_path(request.path_info.sub(/^\//,""))

			#debugger


	  	pass if @page.nil? or (@page.content? and @page.hidden?)



	  	@config = settings

	  	if @page.content?
				haml(@page.template, :layout => @page.layout)
			else
				render_direct @page.filename, @page.format
			end
	  end 


		helpers do

			def render_direct (filename, engine, options = {}, locals = {})

				template = Tilt[engine]
				raise "Template engine not found: #{engine}" if template.nil?

				inst = template.new(@page.filename,1,options)
				
				inst.render(scope, locals, &block)

	      output.extend(ContentTyped).content_type = content_type if content_type
	      output
			end

			def split_ext
				#Get last extension
				ext = File.extname(request.path_info)
				path = request.path_info
				if !ext.empty?
					ext = ext[1..-1] 
					path = path[0..-(ext.length + 2)]
				end
				return path, ext
			end

		  def find_template(views, name, engine, &block)
		  	#normal
		    super(views, name, engine, &block)
		    #.part
		    super(views, name.to_s + '.part', engine, &block)
		    #.layout
		    super(views, name.to_s + '.layout', engine, &block)
		  end
		end




	  not_found do
	    @config = settings
	    haml(:not_found)
	  end

	  error do
	    @config = settings
	    haml(:error)
	  end unless development?

	    get '/robots.txt' do
	      content_type 'text/plain', :charset => 'utf-8'
	      <<-EOF
	# robots.txt
	# See http://en.wikipedia.org/wiki/Robots_exclusion_standard
	      EOF
	    end


	  get %r{/attachments/([\w/.-]+)} do |file|
	    file = File.join(Nesta::Config.attachment_path, params[:captures].first)
	    if file =~ /\.\.\//
	      not_found
	    else 
	      send_file(file, :disposition => nil)
	    end
	  end

	  get '/articles.xml' do
	    content_type :xml, :charset => 'utf-8'
	    set_from_config(:title, :subtitle, :author)
	    @articles = Page.find_articles.select { |a| a.date }[0..9]
	    cache haml(:atom, :format => :xhtml, :layout => false)
	  end

	  get '/sitemap.xml' do
	    content_type :xml, :charset => 'utf-8'
	    @pages = Page.find_all
	    @last = @pages.map { |page| page.last_modified }.inject do |latest, page|
	      (page > latest) ? page : latest
	    end


	    cache haml(:sitemap, :format => :xhtml, :layout => false)
	  end
	end
end