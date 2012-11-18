

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

    def self.find_all
      Index.pages
    end

    def self.find_articles
      Index.posts.sort { |x, y| y.date <=> x.date }
    end
    
    def top_articles(count = 10)
      Page.find_articles.select { |a| a.date }[0..count-1]
    end
  

  
    def title
      if meta.title
        meta.title
      #elsif !parent.nil? && !parent.heading.nil?
      #  "#{heading} - #{parent.heading}"
      elsif heading
        "#{heading} - #{Nesta::Config.title}"
      elsif abspath == '/'
        Nesta::Config.title
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

    def summary
      meta.summary && meta.summary.gsub!('\n', "\n")
    end


  
    
    def inline_summary
      meta.summary
    end

     def articles_by_tags
       Hardwired::Page.find_articles.select { |article| not (article.tags & self.tags).empty? }
     end
     def self.articles_by_tag(tag)
        Hardwired::Page.find_articles.select { |article| not (article.tags & [tag]).empty? }
      end

     def tags
      parse_string_list(meta.tags)
     end

    


  end
end 
