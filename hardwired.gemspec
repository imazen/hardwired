# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)


Gem::Specification.new do |s|
  s.name        = "hardwired"
  s.version     = '0.3.2'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Nathanael Jones"]
  s.email       = ["nathanael.jones@gmail.com"]
  s.homepage    = "http://github.com/nathanaeljones/hardwired"
  s.summary     = %q{Simple, unmagical file-based cms}
  s.description = <<-EOF
Hardwired is an embedded content management system for ruby websites.
It favors direct connections over abstraction and indirection.

If you like markdown, Git, and chafe at artificial restrictions, this is 
likely the CMS for you. 

Based on Sintra/Rack.
EOF

  s.rubyforge_project = "hardwired"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]


  s.add_dependency('tilt')
  s.add_dependency('erubis')
  s.add_dependency('nokogiri')
  s.add_dependency('sinatra', '>= 1.3.3')

  
  # Test libraries
  s.add_development_dependency('minitest')
  s.add_development_dependency('rack-test')
end
