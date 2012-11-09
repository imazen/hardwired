# Hardwired - A simple website framework for busy control freaks who like Git and plaintext.

The best CMS is the one that doesn't need a manual. Hardwired is tiny, readable, and (we hope) intuitive. 

Requires ruby 1.9.X

## File categories

* Part (.part.*) - A partial is a file that cannot be rendered directly; it's only usable from within another file.
* Content (.content.* or .c.*) - A content file always rendered within a template and layout, unless otherwise specified in metadata. It's also indexed in the Pages collection.
* Direct (.direct.* or .d.*) - A file that is interpreted without a layout or template, does not have metadata, and is only indexed for URL purposes.
* Layout (.layout.*) - A layout file that requires content in order to be displayed. 
* Static (.static.*) - A file that is served statically.

Other than static files, all have access to `config.yml` data (via the `settings` hash) and the Pages index (via the `Pages` class).

Any file named `index` can be used to represent a directory root.

## File type assumptions

* Markdown, textile, rdoct, and creole files are *assumed* to be `Content` files *unless* otherwise indicated by the category extension. For example, `page.md` is assumed to be a content page, but `page.part.md` is a partial.
* Coffeescript, Sass, Scss, and Less files are assumed to be `Direct` files, unless otherwise indicated.
* Haml, erb, builder, nokogiri, liquid, radius, markaby, and slim files are assumed to be `Direct` files files unless otherwise indicated.

## URL structure

URLs do not include the last file extension, nor a 'category' extension preceeding it. This permits both extensionless urls, and intentially extensioned urls (such as 'articles.xml.haml' and /articles.xml).

Urls are mapped to the matching filename. Redirects to content pages can be performed using metadata `Aliases`, but other custom behavior has to be specified in the routes collection.

## URL matching sequence


1. Static file served as is IF
	a. File exists and 'ext' is not any supported interpreted extension, 
	b. OR, (or path.static.ext) exists.

2. Redirect slash-terminated URLs to non-slash-terminated URLs, or vice versa.

3. Direct files are interpreted and served IF
    a. `<url>(/index)?.(direct|d).*` exists, OR `<url>(/index)?.<ext>` exists and `<ext>` is a template type that defaults to direct interpretation.

4. Content files are interpreted and served IF
	a. Pages collection has a URL match



May configure folders which cause content-disposition:attachment to be generated.

## Requirements for content files

Content files MUST either (a) have a valid metadata header WITH a valid `heading` value, or (b) have a parsable title.




## Why

1. Static website generators aren't flexible enough (no redirection support, zero dynamic capabilities)
2. App frameworks are good for apps, but they are overkill for content-focused *websites* that don't have dedicated staff; and especially frustrating if you don't work with them on a regular bases elsewhere.
3. Database-driven CMSes are endlessly painful (I spent 5 years with Wordpress, and I've used Drupal, Joomla, Refinery, DotNetNuke, and many others)
4. I was a loyal [Nesta](http://nestacms.com) user for several years (and wrote 4 plugins), but eventually got fed up with the layers of indirection and the 'assumption' that your day job is Sinatra.

## Website file structure

* config.ru - This file is what Rack executes at startup
* Gemfile - Describes dependencies
* config.yml - Configuration settings and strings.
* hardwired.rb - 
* site.rb
* content/ - All templates, layouts, pages, content, and static files are located inside this folder. File extensions determine how they are interpreted.




## accessing config.yml data from views

@config.*


# Optional behavior

## Nesta compat

		require 'hardwired/compat/nesta'

		# Within the App
		register Hardwired::Nesta

## Wordpress compat


		require 'hardwired/compat/wordpress'
		# Within the App
		register Hardwired::Wordpress

