# Frequently asked questions


## How do I hide pages & posts flagged draft *on my development machine*?

This monkey-patch will change the behavior of the 'Flags: draft' metadata to be environment-agnostic:

      module Hardwired
        class Template
          def hidden?
            flag?('hidden') or draft?
          end
        end
      end

Yeah, we might make a setting for this eventually; but we want to keep the settings count as low as possible till V1.0

## Is there anything special I need to do for Heroku?

You may want to create a file name 'Procfile' in the root and add the following:

    web: bundle exec rackup config.ru -p $PORT

This is not required, but speeds up deploy time slightly.


## How to I change the content or layout folder locations?

At the top of site.rb, you can change the content and layout subfolders by adding these lines

    Hardwired::Paths.content_subfolder = 'content'
    Hardwired::Paths.layout_subfolder = '_layout'


## Force a static file to download instead of display

To force a static file to download instead of display in-browser, add `?download=true` to the URL. Hardwired will notice this and send the appropriate content-disposition headers.


## Highlighting the currently selected menu item

Hardwired does not use complex menu generators - instead, it provides a HTML filter function that can tag the currently opened page with any css class.

First parameter is the css class to tag elements with, second paramater the CSS selector used to select parents of the active hyperlink.


### Haml example

    = menu_tag_current_haml 'current','li' do
      %li
        %a{:href => "/"} Home
      %li
        %a{:href => "/about"} About

### Slim example

    == menu_tag_current 'active','li' do
      li
        a href="/" Home
      li
        a href="/about" About
   

## Redirecting 'domain.com' to 'www.domain.com' and vice-versa

    class Site < Hardwired::Bootstrap
      ... other code here

      before do
        redirect request.url.sub(/\/domain\.com/, '/www.domain.com'), 301 if request.host.start_with?("domain.com")
      end
    end 

While I used to redirect 'www.domain.com' to 'domain.com' for cleanliness, root domains cannot be load balanced easily, as not all software supports the use of CNAME records for them. Heroku and other hosted services strongly recommend against their use. 

If you still want to strip the 'www' instead of adding it, this should do the trick.


    before do
      redirect request.url.sub(/\/www.domain\.com/, '/domain.com'), 301 if request.host.start_with?("www.domain.com")
    end


## Enabling caching for great performance

In Gemfile, ensure the following line is present

    gem 'rack-cache'
  
In config.ru, make sure the following code is present and occurs before Site.new

    use Rack::Cache

In site.rb, add the methods as shown here.

    class Site < Hardwired::Bootstrap
      ... other code here
      
      helpers do
        def cache_for(time)
          response['Cache-Control'] = "public, max-age=#{time.to_i}"
        end
      end

      after '*' do 
        cache_for(dev? ? 30 : 60 * 60 * 24) #All files are cached by rack-cache and browsers for 1 day. To invalidate, refresh the page.
      end  
    end



## Override and extend *Page* and *Template*

Here's how we override the .title for all pages, and add a new method to template.
Monkey-patching is easy; drop this at the top of site.rb (or create another .rb file and `require` it)

    module Hardwired
      class Page < Template
        def title
          "I like duplicate titles everywhere!"
        end
      end
      class Template
        def is_crazy?
          return true if meta.flag? 'crazy'
        end
      end
    end


## How to serve google verification files without cluttering your site

1. Add your verification codes to config.yml as an array
        
        # Google Webmaster and Analytics usually require a 'google[code].html' file be placed on the domain
        # Use this feature to do this without polluting your directory structure
        google_verify: [344a8f78fa8143f6, b4f699bd08907a51]

2. Add a new route to Site.rb (not required if you're using Bootstrap)
      
        class Site < Hardwired::Bootstrap
          get %r{/google([0-9a-z]+).html?} do |code|
            "google-site-verification: google#{code}.html" if config.google_verify.include?(code)
          end
        end

3. Done! No more clutter
