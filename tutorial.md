# Tutorial 

This tutorial guides you through setting up a basic website. 

This tutorial is not yet finished; it is not functional.

### Prerequisites

1. A git repository to store your new website
2. Ruby 1.9+
3. A good text editor with ruby, yaml, and slim syntax highlighting. Sublime Text 2 is my personal choice; but [you have to install slim highlighting through package control](https://github.com/fredwu/ruby-slim-tmbundle).
4. RVM set up for the repo or a parent folder (optional, but suggested if you like isolating gem groups)


### Steps

1. Create file '/Gemfile' in the root of the repository with the following contents

        source 'http://rubygems.org'

        gem 'slim' # Our favorite layout format
        gem 'rdiscount' #Good markdown library
        gem 'rack-cache' #Lets us add caching later

        #Uncomment these 2 lines if you need scss,sass, or haml support
        #gem 'sass'
        #gem 'haml'

        #Uncomment these 2 lines if you need less support (quite heavy due to V8 dependency!)
        #gem 'therubyracer' # jS V8 engine - Required for 'less'
        #gem 'less'

        gem 'hardwired', :git => "git://github.com/nathanaeljones/hardwired.git"

        gem 'thin' #we use this webserver for both development and production

        gem "debugger", :group => :development
        gem "rerun", :group => :development


2. Run 'bundle install', verify there are no errors, and commit Gemfile and the new Gemfile.lock to the repository. We now have the libraries we need.

3. Create file '/config.ru'. This file will be our 'boot' file. Contents:

        require 'bundler/setup'
        Bundler.require(:default)

        use Rack::Cache

        require './site'
        run Site.new

4. Create file '/site.rb' (called by config.ru)

        #Set the root directory
        Hardwired::Paths.root = ::File.expand_path('.', ::File.dirname(__FILE__))

        class Site < Hardwired::Bootstrap
          require 'debugger' if development?

          #Load config.yml
          config_file 'config.yml'
        end


5. Create file '/config.yml'. The file may be blank if you wish; *there are no required fields*. However, this tuturial includes layouts that reference these.

        title: "John Doe"
        subtitle: "Anonymous tips from the asylum"

        author:
           name: John Doe
           uri: http://johndoe.me
           email: j@johndoe.me
           google_profile: "http://google.com/profiles/123456"


        # If you want to use the Disqus service (http://disqus.com) to display
        # comments on your site, register a Disqus account and then specify your
        # site's short name here. A comment form will automatically be added to
        # the bottom of your pages.
        disqus_short_name: jdoe

        # google_analytics_code
        #     Set this if you want Google Analytics to track traffic on your site.
        #     Probably best not to set a default value, but to just set it in production so you don't mess up your stats with dev traffic
        #google_analytics_code: "UA-1234567-1"
        production: 
          google_analytics_code: "UA-1234567-1"
          google_analytics_domain: "johndoe.me" #Override domain for multiple subdomain support

6. Create folders '/content' and '/content/_layout'

7. Add file '/content/_layout/layout.slim'

        layout: false

        doctype html
        html(lang="en")
          head
            meta(charset="utf-8")
            meta(http-equiv="X-UA-Compatible" content="IE=edge,chrome=1")
            
            title
              = page.title

            meta(name="viewport" content="width=device-width, initial-scale=1.0")

            link href="/css/style.css" rel="stylehseet"

            link href="/rss.xml" rel="alternate" type="application/atom+xml"

            == slim :analytics, :layout => false
          body
            == slim :header, :layout => false
            
            == yield


8. Add file '/content/_layout/page.slim'

        Layout: layout

        - if page.heading
          h1.page-header
            == page.heading
          
        == yield

        - if page.date
          p 
            |Published on 
            = page.date.strftime("%d %B %Y")

        - if !page.lib?('-comments')
          == slim :comments, :layout => false


9. Add file '/content/_layout/comments.slim'

        - if config.disqus_short_name and not page.lib?('-comments')
          #disqus_thread
          - if Sinatra::Application.environment == :development
            javascript:
              var disqus_developer = true;
          javascript:
            var disqus_shortname = '#{config.disqus_short_name}';
              (function() {
                var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;
                dsq.src = 'http://' + disqus_shortname + '.disqus.com/embed.js';
                (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
              })();
          noscript
            | Enable Javascript or
            a(href="http://disqus.com/?ref_noscript") click here to view the comments.

10. Add file '/content/_layout/analytics.slim'

        - if config.google_analytics_code
          javascript:
            var _gaq = _gaq || [];
            _gaq.push(['_setAccount', '#{config.google_analytics_code}']);
            _gaq.push(['_setDomainName', '#{config.google_analytics_domain}']);
            _gaq.push(['_trackPageview']);

            (function() {
              var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
              ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
              var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
            })();

11. Add file '/content/_layout/header.slim'

        == menu_tag_current 'active','li' do
          li
            a href="/" Home
          li
            a href="/about" About

12. Add file '/content/css/style.css'

        * {font-family:Verdana} /* Replace this with some real css*/

13. Add file '/content/rss.xml.slim'

        layout: false
        Aliases: /articles.xml /atom.xml
        content_type: xml

        doctype xml
        feed xmlns='http://www.w3.org/2005/Atom'
          title(type='text')= config.title
          generator(uri='http://effectif.com/nesta') Nesta
          id= atom_id
          link(href="#{base_url}/rss.xml" rel='self')
          link(href=base_url rel='alternate')
          subtitle type='text' = config.subtitle
          - if index.posts.first
            updated= index.posts.first.date(:xmlschema)
          - if config.author
            author
              - if config.author.name
                name= config.author.name
              - if config.author.uri
                uri= config.author.uri
              - if config.author.email
                email = config.author.email
          - index.posts.each do |article|
            entry
              title= article.heading
              link href=url_for(article) type ='text/html' rel='alternate'
              id= atom_id(article)
              content type='html' =escape_html(article.summary(self,200))
              published= article.date(:xmlschema)
              updated= article.date(:xmlschema)




13. Add file '/content/404.md'

        Flags: -sitemap

        # 404 - Page not found

        I only check the google crawl logs every few months, so if you want this fixed faster, e-mail me at email@domain.com.

14. Add file '/content/500.md'

        Flags: -sitemap

        # Bad command or file name

        Something went wrong. Very, very wrong. If you have time, please e-mail me at `email@domain.com` and let me know.


# Under construction

