

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




 
  end
end 
