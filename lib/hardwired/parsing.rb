
require 'tilt'
require 'tilt/template'

module Tilt
  # Raw Htm (no template functionality). May eventually add syntax validation warnings
  class PlainHtmlTemplate < Template
    self.default_mime_type = 'text/html'

    def self.engine_initialized?
      true
    end

    def prepare
      @rawhtml = data
    end

    def evaluate(scope, locals, &block)
      @output ||= @rawhtml
    end
  end
  
  class RubyPoweredMarkdown < ErubisTemplate
    def evaluate(scope, locals, &block)
       temp = super
       (Tilt["markdown"].new { temp }).render
    end
  end
  

  class MarkdownVars < StringTemplate
    def evaluate(scope, locals, &block)
      temp = super
      (Tilt["markdown"].new { temp }).render
    end
  end 
end

Tilt.register Tilt::PlainHtmlTemplate, 'htmf'
Tilt.register Tilt::RubyPoweredMarkdown, 'rmd'
Tilt.register Tilt::MarkdownVars, 'mdv'

module Hardwired


  #Content file support
  module ContentFormats
    @template_mappings = Hash.new { |h, k| h[k] = [] }

    # The set of extensions (without the leading dot) as symbols
    def self.extensions
      @template_mappings.keys
    end

    # Normalizes string extensions to symbols, stripping the leading dot. If passed a symbol, assumes it has already been trimmed.
    def self.normalize(ext)
      (ext.is_a? Symbol) ? ext : ext.to_s.downcase.sub(/^\./, '').to_sym
    end

    # Register a template implementation by file extension.
    def self.register(template_class, *extensions)
      extensions.each do |ext|
        ext = normalize(ext)
        @template_mappings[ext].unshift(template_class).uniq!
      end
    end

    #Removes all implementations registered for the given extensions
    def self.clear(*extensions)
      extensions.each do |ext|
        @template_mappings.delete(normalize(ext))
      end
    end

    # Returns true when a template exists on an exact match of the provided file extension
    def self.registered?(ext)
      ext = normalize(ext)
      @template_mappings.key?(ext) && !@template_mappings[ext].empty?
    end

    # Lookup a class for the given extension
    # Return nil when no implementation is found.
    def self.[](ext)

       #first non-null
       fmt = @template_mappings[normalize(ext)].detect do |klass|
         not klass.nil?
       end
       
       # We don't provide a method for engine initialization like Tilt does - it doubles code complexity and we don't have a use-case yet.
       # Using static methods may be the wrong approach, but since Tilt is handling all the heavy lifting, I don't see one on the horizon.
       return fmt if fmt
    end
   

     
   class Markdown
     def self.heading (markup) markup =~ /^#\s*(.*?)(\s*#+|$)/
       Regexp.last_match(1)
     end
     
     def self.body (markup) markup.sub(/^#[^#].*$\r?\n(\r?\n)?/, '')  end
   end
   
   class Haml
       def self.heading (markup) markup =~  /^\s*%h1\s+(.*)/
         Regexp.last_match(1)
       end
       def self.body (markup) markup.sub(/^\s*%h1\s+.*$\r?\n(\r?\n)?/, '') end
   end
   
   class Textile
       def self.heading (markup) markup =~  /^\s*h1\.\s+(.*)/
         Regexp.last_match(1)
       end

       def self.body (markup) markup.sub(/^\s*h1\.\s+.*$\r?\n(\r?\n)?/, '') end
  end
   
   class Html
       def self.heading (markup) markup =~ /^\s*<h1[^><]*>(.*?)<\/h1>/
         Regexp.last_match(1)
       end

       def self.body (markup) markup.sub(/^\s*<h1[^><]*>.*?<\/h1>\s*/, '') end
    end
  end

  module MetadataParsing



    class SimpleMetadataParser
      def has_metadata?(text)
        text.split("\n").first =~ /^[\w ]+:/
      end

      def extract(text)
        first_paragraph, remaining = text.split(/\r?\n\r?\n/, 2)
        
        has_meta = has_metadata?(first_paragraph)

        metadata = has_meta ? parse(first_paragraph) : {}
        
        return metadata, has_meta ? remaining : text
      end
     

      def parse(metadata)
        hash = CaseInsensitiveHash.new
        metadata.split("\n").each do |line|
          key, value = line.split(/\s*:\s*/, 2)
          next if value.nil?
          hash[key.downcase] = value.chomp
        end
        hash
      end

    end

    class YamlMetadataParser < SimpleMetadataParser

      def parse(metadata_segment)
        yaml = YAML.load(metadata_segment)
      rescue Psych::SyntaxError
        raise MetadataParseError
      else
        raise MetadataParseError unless yaml
        metadata = CaseInsensitiveHash.new
        yaml.each { |key, value| metadata[key.downcase] = value } if yaml
        metadata 
      end 

    end 

    @@parser = SimpleMetadataParser
    def self.parser(val = nil)
      @@parser = val unless val.nil?
      @@parser
    end 

  end 

end
