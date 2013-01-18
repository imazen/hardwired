# Hardwired - Flexible websites with Git and a text editor

Hardwired tries to be intuitive and minimize specialized knowledge. We all hate CMSes.

Dependencies: ruby 1.9+, sinatra 1.3.3+, sinatra-contrib, tilt, nokogiri

Suggested dev server: rerun + thin

License: MIT

Hardwired is embeddable, self-contained, and easy to modify. 

####Samples

* [Absurdly minimal example](https://github.com/nathanaeljones/hardwired-sample-minimal)
* [Basic site with Twitter Bootstrap, Google Analytics, and Disqus](https://github.com/nathanaeljones/hardwired-sample-bootstrap) - not yet complete
* [My personal blog](https://github.com/nathanaeljones/njcom)

####Additional resources:

* [Frequently asked questions](https://github.com/nathanaeljones/hardwired/blob/master/faq.md)
* [Creating a hardwired site - step-by-step](https://github.com/nathanaeljones/hardwired/blob/master/tutorial.md)  - not yet complete
* [Migrating from NestaCMS](https://github.com/nathanaeljones/hardwired/blob/master/migrating-from-nesta.md)
* [Migrating from Wordpress (with import script!)](https://github.com/nathanaeljones/hardwired/blob/master/migrating-from-wordpress.md)


## Definitions

* A `Template` is any file which can be rendered by [by Tilt](https://github.com/rtomayko/tilt/blob/master/lib/tilt.rb). .coffee, .scss, .markdown, .slim, .erb, and .htmf are a few examples. We also call this a `dynamic file`. `Static files` are files which Tilt cannot render.
* A `Layout` is a template which has area(s) that can be filled with content from a 'child' template. These areas are usually defined with `yield` or `yield_content`.  Unlike Sinatra, Hardwired supports nested layouts. 
* The `normalized path` for a template is created by taking the filename relative to /content/, stripping the last file extension, reducing '/index' to '/', stripping leading/trailing slashes, then restoring the leasing slash. index.virtual_path_for(filename) contains the implementation.
* A `Page` is any `Template` which is *not* located in '/content/_layout/' and should render (X)HTML.
* A `Post` is a `Page` which has a publish date specified in the metadata.

## Overview

1. Hardwired automatically maps URLs to filenames - minus the extension for dynamic files. Example:

			/about -> /content/about.slim
			/about -> /content/about/index.md
			/about -> /content/about.md

	 Only one of the above files may exist - otherwise Hardwired will complain loudly during startup, when it indexes all files with 'dynamic' extensions.

	 '/about' is the *normalized path* for all of the given files.

2. Hardwired supports and indexes all of the file types [supported by Tilt](https://github.com/rtomayko/tilt/blob/master/lib/tilt.rb), as well as a couple extra. You can add support for your own formats easily through Tilt. Here are the ones you'll probably prefer using the most:

	1. [Markdown](http://daringfireball.net/projects/markdown/syntax) - *.md - Clean and minimalistic, a panacea for 95% of writing.
	2. Html Fragment - *.htmf - Great for migrating from other CMSes, like Wordpress.
	4. [Slim](http://slim-lang.com/) - *.slim - Fantastic for layouts and complex pages, much more intuitive and readable than HAML.
	5. [Erubis](http://www.kuwata-lab.com/erubis/) - *.erubis - For those who like `<%= %>` too much to let it go.
	
	You can access the index via `Hardwired::Index`, or using the `index` variable within a template or the app scope. 


3. Static files are served as you would expect.

		/img/logo.png -> /content/img/logo.png

		Non-static files can be served as static files using this convention:

		/file.md -> /content/file.static.md

4. Hardwired is designed for SEO excellence. 

	1. Trailing slashes are normalized via 301. Ex. /about/ -> /about

	2. Redirects are easy to manage, and can be configured *in the destination file metadata*, as well as site-wide via sinatra.

	3. Sitemaps are easy - copy and paste `rss.xml.slim` from the example project.


5. Sass, scss, less, and coffeescript files are *also* acessible *with* an extension (whereas other dynamic files are only accessible through their *normalized path*)

		/file.css -> /content/file.less
		/file -> /content/file.less
		/script.js -> /content/file.coffee
		/script -> /content/file.coffee


## Variables available to dynamic files

Keeping config, index, and page data access simple is a very high priority. 

* `config`  - config.yml variables. A few which are commonly used:
	* config.title
	* config.author.name
	* config.author.email

* `index`  - Index 
	* index.files - enumerator of all dynamic files/templates.
	* index.pages - array of visible  `pages`. Pages with 'Flags: hidden' are excluded.
	* index.posts - the subset of `pages` which have a publish date - sorted by date. Posts with a future publish date are excluded.
	* index.page_tags - unique tags used by visible pages
	* index.post_tags - unique tags used by visible posts
	* index.posts_tagged() - posts with the given tag
	* index.pages_tagged() - pages with the given tag
	* index['/path/to/file'] - Access any template by its *normalized path*. See member reference below.

* `page` - The current content page. Accessible from layouts as well as the page itself.

* `template` - The current dynamic file. When referenced by a layout, it will point to the layout, not the child content page. When referenced by a content page, it will point to the content page. This is the only variable inaccessible to partials rendered using sinatra helpers such as 'erb', 'haml', 'etc'.


## Members of Template and Page

### Path-related members

* .path - The *normalized path* for the file. This is also the domain-relative URL.
* .filename - The physical path to the file.
* .last_modified - The last modified date of the physical file
* .format - the file extension from .filename
* .in_layout_dir? Returns true if this file is located in /content/_layout/
* .parents - Enumerator of 'parent' files (returns 'page' instances, not paths). Ex. /index.md (/) is the parent of /about.md (/about), which is the parent of /about/contact.md (/about/contect). Levels are skipped if missing.
* .parent - Closest parent.

### Metadata-related members

* .meta - All front-matter metadata can be accessed via .meta. `.meta` is a case-insensitive recursive open struct, so you can use the dot-syntax (.meta.author.email)instead of the hash accessor

* .flags - meta.flags, parsed into a list
* .flag?(flag) - Returns true if flags contains the given string
* .libs - meta.libs, parsed into a list. We usually use this for informing a layout that we need a common javascript or CSS library.
* .lib?(lib) - Returns true if libs contains the given string

* .is_page? - Returns true if this template is not a css/js file and not in _layout. Returns true if 'Flags: page' is set, regardless of other circumstances.
* .is_post? - Returns true if the template is a post (a page with a date).
* .hidden? - Returns true if this template is hidden. Templates can be hidden with 'Flags: hidden', or hidden on production, but displayed in development with 'Flags: draft'.
* .can_render? - Returns true if the template is not hidden and not in _layout, OR if 'Flags: visible' is set. If the template is a post with a future 'date' value, false will be returned.
* .heading - Returns meta.heading. If meta.heading is nil, returns the heading from the body. May return nil.

**The following members only exist on pages and posts**

* .tags - meta.tags, parsed into a list.
* .tag?(tag) - Returns true if meta.tags includes the given string.
* .date - The publish date parsed from page.meta.date, as a DateTime object
* .title - HTML &lt;title&ht; to use. Override with meta.title.
* .heading - meta.heading. If meta.heading is null, the heading extracted from the file will be used.

### Layout & rendering members

* .layout - Retuns a string path to the parent layout. Defaults to '/_layout/page', override with meta.layout. Defaults nil for scss,sass,less,coffe files, and files in _layout.
* .layout_template - Returns a Template instance for the parent layout. Returns nil if .layout is nil or cannot be found (search path is /content/, current folder, /content/_layout/)
* .renderer_class - Returns a reference to the class (not an instance of it) that should be used to render the template. Override with meta.renderer. 
* .render(global_options = {}, options = {},scope = nil, locals=nil,&block) - You must pass the application instance ('self') as the paramter for 'scope' in order for references to work. Renders parent layout chain as well, unless {:layout => false} is provided for 'options'.
* .body(scope) - Renders just this file (not the layout(s) it references).
* .summary(scope, min_chars) - Extracts the first few sentences from .body(scope) as plain text, continuing until at least 'min_chars' are accumulated.


## Metadata

All dynamic files (including layouts) are permitted to have metadata at the top. Metadata must be separated from the main file body by at least two blank lines. Alternatively, surround the metadata with two lines containing only `---`. (Yes, we're compatible with Nesta, Jeykll, nanoc, Ruhoh files)

Example markdown file with metadata:

		Aliases: /docs/old-url
		Layout: legal-page

		# This is the page heading

		And the first paragraph.

		... And the second paragraph.


Headings are automatically parsed and stripped from .htmlf, .haml, .md, and .textile files. Use the `Heading:` metadata key to specify the page heading for other file types.

Headings are not rendered unless a layout displays them using 'page.heading'.

## Metadata reference


* `Aliases:` - Space delimited list of domain-local URLs to redirect to the current page. Use '+' to represent spaces in URLs
* `Redirect To:` - Turns a page into a placeholder for a remote URL redirect
* `Content_Type` - Ovveride the default content type
* `Layout` - Specify the parent template to use when rendering the page. Defaults to `_layout/page`. Override `layout_paths` to customize interpretation and search paths.
* `Heading` - Specify the heading 

*	`Flags: hidden` - Prevents the file from being displayed anywhere
* `Flags: draft` - The page/post is displayed in development, but not in production.

*	`Libs: jquery, jquery-ui, ` - A way for pages and layouts to communicate about what js/css libs are needed. Just a convention, you can use arbitrary medata freely.
* `Tags: ruby rails sinatra` - A convention for tagging pages and posts
* `Flags: visible` - Force a file in _layout to be renderable.


## Standard folders

* `/content/` All content, layouts, templates, and static files go here. (configurable)
* `/content/_layout/` All layouts, page templates, and partials go here. (configurable)

## Standard files

* `/config.yml` - Data here can be accessed in any template or layout through `config.*`. This is a freeform YML file with no required fields; only your layout files need communicate with it.
* `/Gemfile` - Lists the gems required by the website. Must include `gem 'hardwired'`
* `/config.ru` - This is the file called by the web server to start the application. It calls `site.rb`, then runs the app with `run new Site`.
* `/site.rb` - This file is where you define your Site instance. At minimum, it must include:

		Hardwired::Paths.root = ::File.expand_path('.', ::File.dirname(__FILE__))

		class Site < Hardwired::SiteBase 
				config_file 'config.yml'
		end
* /content/404.ext  &amp; /content/500.ext - If you inherit from Hardwired::Bootstrap instead of Hardwired::SiteBase, these files will be hooked up automatically. Any dynamic format works - htmf, markdown, slim, etc.


## List of dynamic file extensions

All file types which are [supported by Tilt](https://github.com/rtomayko/tilt/blob/master/lib/tilt.rb), and are *included in your Gemfile* are automatically rendered. That includes:


* `*.sass`, `*.scss`, and `*.less` files are dynamically rendered, and accessible with .css in the URL instead of .sass.
* `*.coffee` files are compiled to javascript on the fly, and can be accessed at '/path/name.js' instead of '/path/name.coffee'
* `*.htmf` - Plaintext html fragment - The only format included with Hardwired.
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
4. For many developers, it makes more sense to version content with code than to keep it in a separate data store. Especially if your content tends to interact with code or rely on it.


