# Migrating from Nesta

## 1. Flatten your folder structure

Hardwired doesn't require you to keep your .scss and .css files in separate directories.

You *may* move everything from `/public/*` into `/content/`; otherwise, set a static rack directive so they continue to be served.
Move everything from `/content/pages/` down into `/content/`, and delete the empty `pages` folder.
Move `/views/atom.haml` and `/views/sitemap.haml` into `/content/`.
Move `/views/not_found.haml` and `/views/error.haml` into `/content/` and rename them to `404.haml` and `500.haml` respectively. Numeric names keep them visually separated from real content in the folder.
Move all remaining files from `/views/` to `/content/_layout/`.


You can leave /content/attachments as-is, if you wish.

## 1. Expand menus

Hardwired does not use menu generators - instead, it provides a HTML filter function that can tag the currently opened page with any css class.

See [this page for usage instructions](https://github.com/nathanaeljones/hardwired/blob/master/advanced.md).

Remember to update all references to the `menu_items`, `display_menu`, or `display_menu_items` helpers or the `Menu` class


## 2. Include `hardwired/nesta` compatibility routes and aliases

In site.rb, add 'require' and 'register' calls

		require 'hardwired/compat/nesta'

		class Site < Hardwired::Bootstrap
				
				##And call this line inside the class
				register Hardwired::Nesta


## 3. Migrate helper references


1. You will need to rename any .erubis files to .erb, and change any HAML that uses the 'erubis' command to 'erb'.
2. Replace any uses of the 'auto' or 'stylesheet' helpers with the appropriate template command, such as 'haml', 'erb', 'mardkown', etc.

4. Replace references to Nesta::Config with Hardwired::Config.config


## 4. (optional) Migrate to slim

Slim is far superior to HAML in nearly every way. If you want some iffy help converting, use this gem: 

	gem 'haml2slim', group: :development 