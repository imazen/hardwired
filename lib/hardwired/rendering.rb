# Rendering - Because Sinatra's template rendering is very limited

 # Template rendering methods. Each method takes the name of a template
  # to render as a Symbol and returns a String with the rendered output,
  # as well as an optional hash with additional options.
  #
  # `template` is either the name or path of the template as symbol
  # (Use `:'subdir/myview'` for views in subdirectories), or a string
  # that will be rendered.
  #
  # Possible options are:
  #   :content_type   The content type to use, same arguments as content_type.
  #   :layout         If set to false, no layout is rendered, otherwise
  #                   the specified layout is used (Ignored for `sass` and `less`)
  #   :layout_engine  Engine to use for rendering the layout.
  #   :locals         A hash with local variables that should be available
  #                   in the template
  #   :scope          If set, template is evaluate with the binding of the given
  #                   object rather than the application instance.
  #   :views          Views directory to use.
module Hardwired
  module Rendering


    #Cached - matches non-default extensions to the canonical name via the Tilt database
	  def normalize_engine_name(name)
	  	return @@engine_aliases[name] unless @@engine_aliases.nil? or @@engine_aliases[name].nil?

	  	sinatra_methods = [:erb, :haml, :sass,:scss,:less,:builder,:liquid,:markdown,:textile,
	  				:rdoc,:radius,:markaby,:coffee,:nokogiri,:slim,:creole,:wlang,:yajl,
	  				:rabl]

	  	engine = engine.to_s.downcase.to_sym

	  	if not sinatra_methods.include?(engine)
	  		handler = Tilt[engine]
	  		engine = nil
	  		sinatra_methods.each do |n|
	  			if Tilt.mappings[n.to_s].include?(handler)
	  				engine = n
	  				break
	  			end
	  		end
	  	end

	  	@@engine_aliases[name] = engine
	  	engine
	  end

	  #Selects the appropriate render method based on 'extension'
	  def auto_render(extension, template, options={},locals={})
	  	engine = normalize_engine_name(extension)
	  	raise "Unrecognized template extension #{extension}; not registered with Tilt" if engine.nil?

	  	self.send engine, template, options, locals
	  end


    # Calls the given block for every possible template file in views,
    # named name.ext, where ext is registered on engine.
    def find_template(views, name, engine)
      yield ::File.join(views, "#{name}.#{@preferred_extension}")
      Tilt.mappings.each do |ext, engines|
        next unless ext != @preferred_extension and engines.include? engine
        yield ::File.join(views, "#{name}.#{ext}")
      end
    end

  private
    def render(engine, data, options={}, locals={}, &block)
      # merge app-level, engine-specific options
      engine_options  = settings.respond_to?(engine) ? settings.send(engine) : {}
      options         = engine_options.merge(options)

      # extract generic options
      locals          = options.delete(:locals) || locals         || {}
      views           = options.delete(:views)  || settings.views || "./views"
      layout          = options.delete(:layout)
      eat_errors      = layout.nil?
      layout          = engine_options[:layout] if layout.nil? or layout == true
      layout          = @default_layout         if layout.nil? or layout == true
      content_type    = options.delete(:content_type)  || options.delete(:default_content_type)
      layout_engine   = options.delete(:layout_engine) || engine
      scope           = options.delete(:scope)         || self

      # set some defaults
      options[:outvar]           ||= '@_out_buf'
      options[:default_encoding] ||= settings.default_encoding

      # compile and render template
      begin
        layout_was      = @default_layout
        @default_layout = false
        template        = compile_template(engine, data, options, views)
        output          = template.render(scope, locals, &block)
      ensure
        @default_layout = layout_was
      end

      # render layout
      if layout
        options = options.merge(:views => views, :layout => false, :eat_errors => eat_errors, :scope => scope)
        catch(:layout_missing) { return render(layout_engine, layout, options, locals) { output } }
      end

      output.extend(ContentTyped).content_type = content_type if content_type
      output
    end

  end
 end