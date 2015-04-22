Encoding.default_external = 'utf-8' if RUBY_VERSION =~ /^1.9/

#If certain folders are KNOWN to contain only static files, we can speed those up
#use Rack::Static, :urls => ["/public"]
#use Rack::Static, :urls => ["/attachments"], :root "content"

module Hardwired 
  class SiteWithoutRoutes < Sinatra::Base

    class << self
      def config_file(path)
        Hardwired::Config.load(path, self)
      end 
      def dev?
        Sinatra::Base.development?
      end 
      def config
        Hardwired::Config.config
      end
      def index
        Hardwired::Index
      end 
    end 

    set :root, Proc.new {Hardwired::Paths.root_path }
    set :views, Proc.new { Hardwired::Paths.content_path } #To keep sinatra render methods working
    set :haml, { :format => :html5 } #Who needs html4?

    attr_accessor :select_menu, :page_stack, :template_stack

    helpers Hardwired::Helpers

    helpers do
      def config
        Hardwired::Config.config
      end
      def index
        Hardwired::Index
      end 
      def page
        page_stack.last
      end 
      def template
        template_stack.last
      end
      def dev?
        Sinatra::Base.development?
      end 

      def url_for(page)
        File.join(request.base_url, page.is_a?(Template) ? page.path : page)
      end

      #So sinatra render methods can pick up files in /content/ and /content/_layout (although we despise them)
      def find_template(views, name, engine, &block)
        #normal
        super(views, name, engine, &block)
        #_layout folder
        super(Paths.layout_path, name.to_s, engine, &block)
      end

      def partial(path, options={})
        raise "No name provided to partial(name). Name should exclude extension." if !path
        part = Index.find(path, template && template.dir_path)
        part = Index.find(path, page && page.dir_path) if part.nil? && page != template
        raise "Failed to located partial '#{path}'" if part.nil?
        output = part.render(config,{:layout => false}.merge(options), self )
      end 


      def render_file(path, options={})
        file = options[:anywhere] == true ? Index[path] : Index.find(path)
        return nil if file.nil? || !file.can_render?
        file.render(config,{:page => file}.merge(options),self)
      end

    end


  end



  class SiteBase < SiteWithoutRoutes

    #Enable redirect support
    register Hardwired::Aliases

    
    before do
      #Protect against ../ attacks and _layout access
      if request.path =~ /\.\.[\/\\]/ || (!dev? && request.path_info =~ /^\/_layout/mi)
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
      interpreted_ext = !Tilt.default_mapping.registered?(ext)
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

  class Bootstrap < SiteBase

    get %r{/google([0-9a-z]+).html?} do |code|
      "google-site-verification: google#{code}.html" if config.google_verify.include?(code)
    end

    get '/robots.txt' do
      content_type 'text/plain', :charset => 'utf-8'
      
      output = "# robots.txt\n# See http://en.wikipedia.org/wiki/Robots_exclusion_standard\n" 
      output += "Sitemap: #{url_for('/sitemap.xml')}"
      return output
    end


    not_found do
      # Don't render a full 404 page for asset requests
      path, ext = split_ext
      halt(404) if ["svg","woff","eot","ttf","jpg","png","gif","css","js"].include?(ext)
      render_file('404', :anywhere =>true)
    end

    error do
      render_file('500', :anywhere => true)
    end unless dev?

  end
end