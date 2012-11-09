module Hardwired
	class Page

		def metadata(key)
			@metadata[key.downcase]
		end

    def layout
      (metadata('layout') || 'layout').to_sym
    end

    def template
      (metadata('template') || 'page').to_sym
    end


    def last_modified
      @last_modified ||= File.stat(@filename).mtime
    end

    def description
      metadata('description')
    end

    def abspath
    	"/#{path}"
    end
    
    def keywords
      metadata('keywords')
    end
    
    def metadata(key)
      @metadata[key]
    end
    
    def draft?
      flagged_as?('draft')
    end

    def hidden?
      flagged_as?('hidden') or (draft? && Nesta::App.production?)
    end


    def flagged_as?(flag)
      flags = metadata('flags')
      flags && flags.split(',').map { |name| name.strip }.include?(flag)
    end

    def self.find_all
      all.select { |p| ! p.hidden? }
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
      if metadata('title')
        metadata('title')
      elsif parent && (! parent.heading.nil?)
        "#{heading} - #{parent.heading}"
      elsif heading
        "#{heading} - #{Nesta::Config.title}"
      elsif abspath == '/'
        Nesta::Config.title
      end
    end

    def date(format = nil)
      @date ||= if metadata("date")
        if format == :xmlschema
          Time.parse(metadata("date")).xmlschema
        else
          DateTime.parse(metadata("date"))
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
       strings = metadata('tags')
       strings.nil? ? [] : strings.split(',').map { |string| string.strip }
     end

    
     def libs
       strings = metadata('libs')
       strings.nil? ? [] : strings.split(',').map { |string| string.strip }
     end
     
     def lib(lib)
        (libs.include?(lib) or libs.include?(lib.to_s))
     end


   

  end
end