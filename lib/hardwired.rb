require 'sinatra/base'
require 'sinatra/config_file' #Enables access via settings.*
require 'sinatra/extension' #Enables simple extension development
require 'sinatra/content_for' #Enables pages and templates to define content that can be rendered elsewhere in the layout
require 'haml'
require 'sass'
require 'time'

require 'hardwired/structs'
require 'hardwired/paths'
require 'hardwired/rules'
require 'hardwired/parsing'
require 'hardwired/pages'
require 'hardwired/helpers'
require 'hardwired/metadata'
require 'hardwired/aliases'
require 'hardwired/app'