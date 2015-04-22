module Hardwired
  class JsOptimize
    @@include_cache = {}
    def self.filter_includes(options = {:defer => true}, fragment)

      return @@include_cache[fragment] if @@include_cache[fragment]
      require 'nokogiri'
      dom = Nokogiri::HTML::fragment(fragment)
      scripts = []
      mod_dates = []
      dom.css('script').each do |i|
        url = i["src"]
        next if url.nil? || url.start_with?("http") || url.start_with?("//")
        try_urls = [url.sub(/(?<!min)\.js\Z/i,".min.js"),url.sub(/(?<!min)\.js\Z/i,"-min.js"), url]
        mod_date = nil 
        try_urls.each do |u|
          begin 
            mod_date = File.mtime(Hardwired::Paths.content_path(u))
            url = u
            p url if dev?
            p mod_date if dev?
            break
          rescue
            next
          end
        end
        next if mod_date == nil 

        mod_dates << mod_date
        scripts << url
        i.remove
      end 

      avg_mod_date = mod_dates.map{|d| d.to_f}.reduce(:+).to_f / mod_dates.size

      sNode = Nokogiri::XML::Node.new('script',dom)
      sNode['defer'] = "defer" if options[:defer]
      sNode['async'] = "true" if options[:async]
      sNode['src'] = "/alljs/" + scripts.map{|s| Base64.urlsafe_encode64(s)}.join(',') + "?m=" + Time.at(avg_mod_date).to_s


      result = sNode.to_html + dom.to_html

      @@include_cache[fragment] = result
      result


    end 

    def self.create_combined_response(application_class, scripts, no_minify: dev?)
      scripts = scripts.split(',').map{|s| Base64.urlsafe_decode64(s)}

      compressor = defined?(YUI) && defined?(YUI::JavaScriptCompressor) && YUI::JavaScriptCompressor.new(:munge => false)


      compress_callback = lambda do |content, path|
        begin
            
          (compressor ? compressor.compress(content) : content)
        rescue Exception => e
          #puts "Syntax error in #{path}"
          #p e
          content
        end
      end

      session = Rack::Test::Session.new(application_class)
      combined = scripts.map { |path|
        content = nil
        result = session.get(path)
        if result.body.respond_to?(:force_encoding)
          response_encoding = result.content_type.split(/;\s*charset\s*=\s*/).last.upcase rescue 'ASCII-8BIT'
          content = result.body.force_encoding(response_encoding).encode(Encoding.default_external || 'ASCII-8BIT')  if result.status == 200
        else
          content = result.body  if result.status == 200
        end

        (path.end_with?("min.js") || path.end_with?("pack.js") || no_minify) ? content : compress_callback.call(content,path) 

      }.join("\n")
    end


  end
end 