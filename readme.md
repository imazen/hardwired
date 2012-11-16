# Hardwired - Flexible websites with Git and a text editor

Hardwired tries to be intuitive and minimize specialized knowledge. We all hate CMSes.

Dependencies: ruby 1.9+, sinatra 1.3.3+, tilt, sinatra-contrib, haml, sass, nokogiri, RedCloth, rdiscount, erubis

Suggested dev server: rerun + thin

Hardwired is embeddable, self-contained, and easy to modify.

## Overview

1. Hardwired automatically maps URLs to filenames - minus the extension for dynamic files. Example:

			/about -> /content/about.haml
			/about -> /content/about/index.md
			/about -> /content/about.md

	 Only one of the above files may exist - otherwise Hardwired will complain loudly during startup, when it indexes all files with 'dynamic' extensions.

2. Static files are served as you would expect, and do not get special extension treatment.

		/img/logo.png -> /content/img/logo.png

3. Requests can be 'downloaded' via a querystring

		/img/logo.png?download=true

4. If you want to serve a 'dynamic' file type as a static file you MUST name it `name.static.dynamicextension`. Otherwise it will be rendered instead of served.

		/file.md -> /file.static.md

5. Sass, scss, less, and cofeescript files are also acessible *with* an extension (whereas other dynamic files are not)

		/file.css -> /file.less
		/file -> file.less
		/script.js -> /file.coffee
		/script -> file.coffee

## Metadata

All dynamic files are permitted to have metadata at the top. Metadata must be separated from the main file body by at least two blank lines. Alternatively, surround the metadata with two lines containing only `---`

Example markdown file with metadata:

		Aliases: /docs/old-url
		Layout: legal-page

		# This is the page heading

		And the first paragraph.

		... And the second paragraph.


Headings are automatically parsed for .htmlf, .haml, .md, and .textile files. Use the `Heading:` metadata key to specify the page heading for other file types.

## Metadata reference


* `Aliases:` - Space delimited list of domain-local URLs to redirect to the current page. Use '+' to represent spaces in URLs
* `Redirect To:` - Turns a page into a placeholder for a remote URL redirect
* `Content_Type` - Ovveride the default content type
* Layout
*		Flags: hidden, draft, 
*		Libs: jquery, jquery-ui, 
*		Heading:


## Standard folders

* `/content/` All content, layouts, templates, and static files are located inside the `/content/` folder. (configurable)
* `/content/_layout/` All layouts, page templates, and partials go here. (configurable)

## Standard files

* `/config.yml` - Data here can be accessed in any template or layout through `@config.*`.
* `/Gemfile` - Lists the gems required by the website. Must include `gem 'hardwired'`
* `/config.ru` - This is the file called by the web server to start the application. It calls `site.rb`, then runs the app with `run new Site`.
* `/site.rb` - This file is where you define your Site instance. At minimum, it must include:

		Hardwired::Paths.root = ::File.expand_path('.', ::File.dirname(__FILE__))
		Hardwired::Paths.content_subfolder = 'content' #optional
		Hardwired::Paths.layout_subfolder = 'content/_layout' #optional

		class Site < Hardwired::Site
				#Load config.yml from the root
				config_file 'config.yml'
		end

## List of dynamic file extensions

All file types [supported by Tilt](https://github.com/rtomayko/tilt/blob/master/lib/tilt.rb) are automatically rendered. That includes:


* `*.sass`, `*.scss`, and `*.less` files are dynamically rendered to .css. URL: '/path/name.css' Filename: `/path/name.sass'
* `*.coffee` files are compiled to javascript on the fly, and can be accessed at '/path/name.js' instead of '/path/name.coffee'
* `*.htmf` - Plaintext html fragment
* `*.md, *.markdown, *.mkd, *.mdown` - Markdown
* `*.textile` - Textile
* `*.haml` - HAML
* `*.yajl` - yajl
* `*.wiki, *.mediawiki, *.mw` - MediaWiki (MediaCloth)
* `*.wiki, *.creole` - Creole
* `*.rdoc` - RDoc
* `*.radius` - Radius
* `*.liquid` - Liquid
* `*.markaby, *.mab` - Markaby
* `*.builder` - builder
* `*.nokogiri` - Nokogiri XML
* `*.str` - String template
* `*.erb, *.rhtml, *.erubis` ERB/erubis templates

You can easily register custom file extensions or renderers with Tilt.register


## Why

1. Static website generators aren't flexible enough (no redirection support, zero dynamic capabilities)
2. App frameworks are good for apps, but they are overkill for content-focused *websites* that don't have dedicated staff; and especially frustrating if you don't work with them on a regular bases elsewhere.
3. Database-driven CMSes are endlessly painful (I spent 5 years with Wordpress, and I've used Drupal, Joomla, Refinery, DotNetNuke, and many others)
4. I was a loyal [Nesta](http://nestacms.com) user for several years (and wrote 4 plugins), but eventually got fed up with the layers of indirection and the 'assumption' that your day job is Sinatra.




## Variables available to templates

@config.* (config.yml)

@page.meta.* (Page metadata)

@page.lib?

## Querying the template index

Index.

# Optional behavior

## Nesta compat

		require 'hardwired/compat/nesta'

		# Within the App
		register Hardwired::Nesta

## Wordpress compat


		require 'hardwired/compat/wordpress'
		# Within the App
		register Hardwired::Wordpress

