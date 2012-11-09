
require 'sinatra/extension'

#NestaCMS compatibility shims

#For Nesta .mdown compatibility - Still need to rename *.erbis -> *.erb
Tilt.register 'mdown', Tilt[:md] 

module Nesta
  Page = Hardwired::Page
  
end

module Hardwired
  module Nesta
    extend Sinatra::Extension

   	## Make Nesta::Config work
    before '*' do
    	Nesta::Config = settings
    end
  end
end

