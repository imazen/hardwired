

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
      return false if date && page.date >= DateTime.now 
      super
    end 


    def self.find_all
      Index.all_pages.select { |p| ! p.hidden? }
    end

    def self.find_articles
      find_all.select do |page|
        page.date && page.date < DateTime.now
      end.sort { |x, y| y.date <=> x.date }
    end
    
    def top_articles(count = 10)
      Page.find_articles.select { |a| a.date }[0..count-1]
    end
  

  
    def title
      if meta.title
        meta.title
      elsif parent && (! parent.heading.nil?)
        "#{heading} - #{parent.heading}"
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
      metadata('atom id')
    end

    def read_more
      metadata('read more') || 'Continue reading'
    end

    def summary
      if summary_text = metadata("summary")
        summary_text.gsub!('\n', "\n")
        convert_to_html(@format, nil, summary_text)
      end
    end


    
    def pages
      in_category = Hardwired::Page.find_all.select do |page|
        page.date.nil? && page.categories.include?(self)
      end
      in_category.sort do |x, y|
        by_priority = y.priority(path) <=> x.priority(path)
        if by_priority == 0
          x.heading.downcase <=> y.heading.downcase
        else
          by_priority
        end
      end
    end

    def articles
      Hardwired::Page.find_articles.select { |article| article.categories.include?(self) }
    end

    
    def inline_summary
      metadata("summary")
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
