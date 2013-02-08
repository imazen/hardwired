require "zlib"
require "stringio"
require "time"  # for Time.httpdate
require 'rack/utils'

module Hardwired
  class Deflater

    DEFAULT_CONTENT_TYPES = 
      [
      # All html, text, css, and csv content should be compressed
      "text/plain",
      "text/html",
      "text/csv",
      "text/css",

      # Only vector graphics and uncompressed bitmaps can benefit from compression.
      #GIF, JPG, and PNG already use a lz* algorithm, and certain browsers can get confused.
      "image/x-icon",
      "image/svg+xml",
      "application/x-font-ttf",
      "application/x-font-opentype",
      "application/vnd.ms-fontobject",

      # All javascript should be compressed
      "text/javascript",
      "application/ecmascript",
      "application/json",
      "application/javascript",

      # All xml should be compressed
      "text/xml",
      "application/xml",
      "application/xml-dtd",
      "application/soap+xml",
      "application/xhtml+xml",
      "application/rdf+xml",
      "application/rss+xml",
      "application/atom+xml"]
  

    ##
    # Creates Rack::Deflater middleware.
    #
    # [app] rack app instance
    # [options] hash of deflater options, i.e.
    #           'min_length' - minimum content length to trigger deflating (defaults to 1024 bytes)
    #           'skip_if' - a lambda which, if evaluates to true, skips deflating
    #           'include_types' - a lambda (Ruby 1.9+) or an array denoting mime-types to compress
    def initialize(app, options = {})
      @app = app

      @min_length = options[:min_length] || 1024
      @skip_if = options[:skip_if]
      @include_types = options[:include_types] || DEFAULT_CONTENT_TYPES
   
    end

    def call(env)
      status, headers, body = @app.call(env)
      headers = Rack::Utils::HeaderHash.new(headers)

      unless should_deflate?(env, status, headers, body)
        return [status, headers, body]
      end

      request = Rack::Request.new(env)

      encoding = Rack::Utils.select_best_encoding(%w(gzip deflate identity),
                                            request.accept_encoding)

      # Set the Vary HTTP header.
      vary = headers["Vary"].to_s.split(",").map { |v| v.strip }
      unless vary.include?("*") || vary.include?("Accept-Encoding")
        headers["Vary"] = vary.push("Accept-Encoding").join(",")
      end

      case encoding
      when "gzip"
        headers['Content-Encoding'] = "gzip"
        headers.delete('Content-Length')
        mtime = headers.key?("Last-Modified") ?
          Time.httpdate(headers["Last-Modified"]) : Time.now
        [status, headers, GzipStream.new(body, mtime)]
      when "deflate"
        headers['Content-Encoding'] = "deflate"
        headers.delete('Content-Length')
        [status, headers, DeflateStream.new(body)]
      when "identity"
        [status, headers, body]
      when nil
        body.close if body.respond_to?(:close)
        message = "An acceptable encoding for the requested resource #{request.fullpath} could not be found."
        [406, {"Content-Type" => "text/plain", "Content-Length" => message.length.to_s}, [message]]
      end
    end

    class GzipStream
      def initialize(body, mtime)
        @body = body
        @mtime = mtime
      end

      def each(&block)
        @writer = block
        gzip  =::Zlib::GzipWriter.new(self)
        gzip.mtime = @mtime
        @body.each { |part|
          gzip.write(part)
          gzip.flush
        }
      ensure
        @body.close if @body.respond_to?(:close)
        gzip.close
        @writer = nil
      end

      def write(data)
        @writer.call(data)
      end
    end

    class DeflateStream
      DEFLATE_ARGS = [
        Zlib::DEFAULT_COMPRESSION,
        # drop the zlib header which causes both Safari and IE to choke
        -Zlib::MAX_WBITS,
        Zlib::DEF_MEM_LEVEL,
        Zlib::DEFAULT_STRATEGY
      ]

      def initialize(body)
        @body = body
      end

      def each
        deflater = ::Zlib::Deflate.new(*DEFLATE_ARGS)
        @body.each { |part| yield deflater.deflate(part, Zlib::SYNC_FLUSH) }
        yield deflater.finish
        nil
      ensure
        @body.close if @body.respond_to?(:close)
        deflater.close
      end
    end

    private

    def should_deflate?(env, status, headers, body)
      # Skip compressing empty entity body responses and responses with
      # no-transform set.
      if Rack::Utils::STATUS_WITH_NO_ENTITY_BODY.include?(status) ||
          headers['Cache-Control'].to_s =~ /\bno-transform\b/ ||
         (headers['Content-Encoding'] && headers['Content-Encoding'] !~ /\bidentity\b/)
        return false
      end

      # Skip if response body is too short
      if @min_length > headers['Content-Length'].to_i
        return false
      end

      # Skip if :skip_if lambda is provided and evaluates to true
      if @skip_if &&
          @skip_if.call(env, status, headers, body)
        return false
      end


      mime_type = headers['Content-Type'].gsub(/;.*\Z/,"").downcase
      # Skip if :include is provided and evaluates to false
      if @include_types &&
          !((@include_types === mime_type) || 
          (@include_types.respond_to?(:"include?") && 
            @include_types.include?(mime_type)))
        puts "Not compressing #{mime_type}"
        return false
      end

      true
    end
  end
end