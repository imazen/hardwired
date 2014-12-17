# Quick Reference




`config.title`
`config.url`
`config.author.name`
`config.author.email`
`config.google_analytics_code`
`config.disqus_short_name`
`config.google_verify` (usually array)



`index['/blog']` | Access the Template for a given URL (case-sensitive). `index['/blog']` could return the template located at `/content/blog/index.md`, `/content/blog.slim`, or `/content/blog.md`, depending upon which exists. (If more than one existed, an error would be thrown on app start).

`index.pages` | Array of all visible pages on the site. (posts are also pages). Impl:  `index.enum_files { |p| p.is_page? && p.can_render? }.to_a`

`index.posts` | Sorted array of all visible posts on the site, newest first.

`index.files` | *enumerator* of all templates on the site, including layouts, sass, coffeescript, pages, and posts.

`index.enum_files` | *filterable* version of `.files`. 

`index.page_tags` | An array of all unique page tags strings

`index.post_tags` | An array of all unique post tags strings.

`index.pages_tagged(tag)` | Array of pages with the given tag. Impl: `pages.select { |p| p.tag?(tag)}`

`index.posts_tagged(tag)` | Array of posts with the given tag. Impl: `posts.select { |p| p.tag?(tag)}`

`index.virtual_path_for(filename)` | Returns the virtual path `/blog` for a given filename `..etc./app/content/blog/index.md`. 

`template` | The currently rendering template (assuming you are using Hardwired render methods)

`page` | The currently rendering page





| Available within templates (app scope) | Hardwired::Index | Hardwired::Template | | Hardwired::Config
|  


Hardwired::Paths.root_path('config.yml') - /config.yml

Hardwired::Paths.content_path('blog/me.md') -> /content/blog/me.md

Hardwired::Paths.layout_path('file.slim') -> /content/_layout/file.slim


## Helpers


`menu_tag_current(tag_with_class = :selected, query = 'li', &block)`

`menu_tag_current_haml(tag_with_class = :selected, query = 'li', &block)`



  register RubyPoweredMarkdown, 'rmd'
  
  register MarkdownVars, 'mdv'
