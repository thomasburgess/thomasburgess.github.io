---
layout: default
last_modified_at: 2024-10-31
title: Blog setup
subtitle: High expectations colliding with harsh reality...
tags: [jekyll,github]
categories: [blog]
og_image: assets/images/2024/10/30/ville-palmu-ZTMqY6DEGRQ-unsplash.jpg
header_img: assets/images/2024/10/30/ville-palmu-ZTMqY6DEGRQ-unsplash.jpg
header_type: hero
description: Explaining my blog setup
excerpt: >
  This blog is built with Jekyll and is hosted for free on GitHun with GitHub pages. The 
  site is generated from markdown sources automatically on every push to the blog's git 
  repository.
redirect_from: 
    2021/06/12/Blog-setup
show_toc: true
show_sidetoc: true
show_breadcrumb: true
breadcrumb_list:
  - label: Home
    url: /
  - label: Blog
    url: /blog
---

_Header photo credit_[^1]

## Introduction

This blog is built with [Jekyll](http://jekyllrb.com/) and 
and is hosted for free on [GitHub](https://github.com/) with 
[GitHub pages](https://pages.github.com/). The site is generated from markdown sources
automatically on every push to the blog's
[git repository](https://github.com/thomasburgess/thomasburgess.github.io). 

The first version (v1.0 documented here 2021-06-12) of this blog used the 
[TeXt](https://github.com/kitian616/jekyll-TeXt-theme) theme. The current version 
(v2.0, 2024-10-30) is using a simpler setip with the 
[Chulapa](https://dieghernan.github.io/chulapa/) theme
and [https://bootswatch.com/minty/](https://bootswatch.com/minty/) skin.
For some earlier attempt at blogging I used [GitLab](https://gitlab.com), but I with 
this blog I wanted to try [GitHub pages](https://pages.github.com/).

Finding and configuring a suitable theme was more challenging than getting a blog up and 
running. I found the v1.0 TeXt theme too complicated and focusing a lot on things I 
don't want or need. The v2.0 Chulapa theme was a lot easier to get started with. My main 
requirement for a theme is that it supports code syntax highlighting and math with 
[MathJax maths](https://www.mathjax.org/) out of the box.

## Getting the blog up and running

I'm using the [remote_theme](https://github.com/benbalter/jekyll-remote-theme) to get my 
theme working. When writing a post, or testing modifications. There is a useful help 
repo [Chulapa-101](https://github.com/dieghernan/chulapa-101) to quickly get things 
working.

I run Jekyll locally before pushing it to GitHub.
Posts added to `_drafts/` will not be published when pushing, 
which is great when writing longer posts.
To serve the site including drafts locally to the default 
`http://127.0.0.1:4000`, I run
```sh
$ bundle exec jekyll serve --drafts --future --incremental --trace
```
The local server rebuilds the site when the source is modified 
(with the notable exception of `_config.yml`). Not only does this cut on 
waiting for GitHub to build the site, but it also allows me to spot 
mistakes before publishing. Future also shows posts with a future date, incremental 
updates pages as they are edited, trace prints more detailed error messages.

## Customization

I enabled a few options:
* ~~Enabled tag for Google [Analytics](https://analytics.google.com) and 
  [Search Console](https://search.google.com/search-console/about)~~
  * I removed this as I don't really benefit from the added tracking...
* Enabled [AddToAny](https://www.addtoany.com/) support for easy sharing of posts

And made some additions:
* Left aligned and indented MathJax equations by adding 
  `displayAlign: "left", displayIndent: "2em"` to 
  `_config` in `_includes/custom/custom_bottomscripts.html`.
* The tag and category cloud features are not working with `Jekyll > 4.0.1`. I did not
  see an easy way around this other than to require 4.0.1.
* Figured out how to use `<display>` to show/hide blocks without breaking markdown 
  formatting.
  * I had to remove `input: GFM` from kramdown settings and use html for the formatting
    ```html
    <details markdown="1">
    <summary><i>Click to expand...</i><br/>&nbsp;<br/></summary>
    content
    </details>
    ```
    which is felt a little tedious. I figured out how to make a plugin in 
    `_plutins/details_tag.rb`
    ```ruby
    module Jekyll
      class DetailsTag < Liquid::Block
        def initialize(tag_name, markup, tokens)
          super
          @summary = markup.strip
        end

        def render(context)
          content = super
          <<-HTML
    <details markdown="1">
    <summary><i>#{@summary}</i><br/>&nbsp;<br/></summary>

    #{content}

    </details>
          HTML
        end
      end
    end

    Liquid::Template.register_tag('details', Jekyll::DetailsTag)
    ```
    which then lets me just do
    ```markdown
    {\% details Click to expand details... \%}

    Hidden content.
    
    {\% enddetails \%}
    ```
    (I had to add the slashes not to run the command :S )

* Enabled search with with [https://lunrjs.com/](lunrjs)
* Enabled comments with [giscus](https://giscus.app/)
  * I followed the theme 
    [guide](https://dieghernan.github.io/chulapa/docs/02-config#comments) to enable
    discussions on my repo, installing the giscuss app in github only for the blog repo,
    building the giscus script on the app site, and adding it to the custom includes.
* Included [`jekyll-figure` plugin](https://github.com/paulrobertlloyd/jekyll-figure) to 
  get pictures with `figure` and `figurecaption` tags.

## GitHub pages annoyances

* GitHub pages doesn't like the `theme:` pointing to an unsupported theme in 
  `_config.yml`. I got warnings with every build  (that otherwise actually 
  worked). Changing this to `remote-theme:` makes the builds warning-free.
* GitHub pages runs in safe mode, and doesn't support most plugins (such as 
  the `figure` and `details` plugins that I use). This can be circumvented by 
  building handy GitHub action 
  [jekyll-deploy-action ](https://github.com/jeffreytse/jekyll-deploy-action). 
  The trickiest part was to change `master` to main in the `yml`, and adding a 
  repository secret for repo access. This fix likely fixes the first annoyance,
  but it still works with `remote-theme`, so I'll leave it like it is.

--- 

[^1]: Photo by <a href="https://unsplash.com/@villepalmu?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Ville Palmu</a> on <a href="https://unsplash.com/s/photos/sarek?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>



