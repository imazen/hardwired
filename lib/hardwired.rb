require 'sinatra/base'
require 'sinatra/config_file' #Enables access via settings.*
require 'sinatra/extension' #Enables simple extension development
require 'sinatra/content_for' #Enables pages and templates to define content that can be rendered elsewhere in the layout
require 'haml'
require 'sass'
require 'time'
require 'nokogiri'

require 'hardwired/structs'
require 'hardwired/config'
require 'hardwired/paths'
require 'hardwired/parsing'
require 'hardwired/index'
require 'hardwired/template'
require 'hardwired/page'
require 'hardwired/helpers'
require 'hardwired/aliases'
require 'hardwired/app'