

module Hardwired
  class Page < Template


    def initialize(filename)
      if filename.instance_of?(Template)
        copy_vars_from(filename)
      else
        debugger
        super
      end
    end

    def can_render?
      return false if date && date >= DateTime.now 
      super
    end 

    def is_post? 
      date ? true : false
    end



  
    def title
      if meta.title
        meta.title
      #elsif !parent.nil? && !parent.heading.nil?
      #  "#{heading} - #{parent.heading}"
      elsif heading
        "#{heading} - #{Hardwired::Config.config.title}"
      elsif abspath == '/'
        Hardwired::Config.config.title
      end
    end

    def date(format = nil)
      @date ||= if meta.date
        if format == :xmlschema
          Time.parse(meta.data).xmlschema
        else
          DateTime.parse(meta.date)
        end
      end
    end

    def atom_id
      meta.atom_id 
    end

    def read_more
      meta.read_more || 'Continue reading'
    end

    def summary (scope = nil, min_characters = 200)
      meta.summary ? meta.summary.gsub!('\n', "\n") : super
    end

    def inline_summary
      meta.summary
    end

    def other_pages_with_shared_tags
       Hardwired::Index.pages.select { |p| not (p.tags & self.tags).empty? }
    end
 
  end
end 
