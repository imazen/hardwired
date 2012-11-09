#You can only have 1 Hardwired site per app rack. Supporting multiple instances would have required a lot more startup configuration.
module Hardwired
 class Paths
    class << self
      attr_accessor :root, :content_subfolder


      def root_path(basename = nil)
        join(root, basename)
      end
      def content_path(basename = nil)
        join(root_path(content_subfolder || 'content'), basename)
      end
      def join(dirname, segment)
        segment.nil? ? dirname : File.join(dirname, segment.to_s)
      end
    end
  end
end