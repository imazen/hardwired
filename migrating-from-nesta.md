# Migrating from Nesta


1. You will need to rename any .erubis files to .erb, and change any HAML that uses the 'erubis' command to 'erb'
2. You will need to migrate your menus. Hardwired does not use menu generators - instead, it provides a HTML filter function that can tag the currently opened page with any css class.

	= menu_tag_current 'current','li' do
		%ul.menu
			%li
				%a{:href => "/"} home
			%li
				%a{:href => "/download"} download
			%li
				%a{:href => "/plugins"} Plugins
			%li
				%a{:href => "/docs"} Docs
			%li
				%a{:href => "/support"} Support
			%li
				%a{:href => "/licenses"} Licenses

3. You will need the hardwired-nesta-compat gem. 