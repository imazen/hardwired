#You can only have 1 Hardwired site per rack app. Supporting multiple instances would have required a lot more startup configuration.
module Hardwired
 class Paths
    class << self
      attr_accessor :root, :content_subfolder, :layout_subfolder

      def layout_subfolder 
        @layout_subfolder || '_layout' 
      end

      def content_subfolder 
        @content_subfolder || 'content' 
      end
      
      #Returns the physical path to a file in /hardwired/common/
      def common_path(name)
        join(::File.expand_path('../../common', ::File.dirname(__FILE__)),name)
      end
      
      #Returns the physical path for the given relative path joined to the root
      def root_path(basename = nil)
        join(root, basename)
      end
      def content_path(basename = nil)
        join(root_path(content_subfolder), basename)
      end
      def layout_path(basename = nil)
        join(content_path(layout_subfolder), basename)
      end
      def join(dirname, segment)
        segment.nil? ? dirname : File.join(dirname, segment.to_s)
      end
    end
  end
end