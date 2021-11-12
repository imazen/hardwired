require_relative "test_helper"

module Hardwired
  class TestMisc < Minitest::Test

    def test_nokogiri_xml
      #for Hardwired::JsOptimize.filter_includes()
      dom = Nokogiri::XML::Document.new()
      sNode = Nokogiri::XML::Node.new('script',dom)
      sNode['async'] = nil

      assert_equal "<script async=\"\"/>", sNode.to_s 
    end
  end
end