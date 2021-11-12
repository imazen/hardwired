require_relative "test_helper"

module Hardwired
  class TestParsing < Minitest::Test

    def test_yaml_page_parsing
      content = <<-eos
---
Tags: plugin
Bundle: 2
Edition: creative
Tagline: Blur, sharpen, remove noise, and perform automatic histogram adjustment.
  Plus several other cool effects.
Icon: cogs
to: plugins/advancedfilters.slim
edit_info: master/plugins/advancedfilters/readme.slim
---



h1 AdvancedFilters plugin

body text
eos


      t = Template.new(nil, "readme.slim", content)

       assert_equal "cogs",  t.meta.icon
      assert_match /body text/,  t.markup
    end 

  end
end