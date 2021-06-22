---
layout: article
title: Blog setup
tags:
  - blog
  - jekyll
  - TeXt
  - github
mathjax: false
categories: blog
mode: immersive
header:
  theme: dark
article_header:
  type: cover
  theme: dark
  image:
    src: assets/images/2021-06-12/ville-palmu-ZTMqY6DEGRQ-unsplash.jpg
---

This blog is built with [Jekyll](http://jekyllrb.com/) and the 
[TeXt](https://github.com/kitian616/jekyll-TeXt-theme) theme and 
hosted for free on [GitHub](https://github.com/). 
The site is generated from markdown sources automatically on every 
push to the [repository](https://github.com/thomasburgess/thomasburgess.github.io). 

It's easy to have a similar setup 
in [GitLab](https://gitlab.com), but I wanted to try the 
[GitHub pages](https://pages.github.com/) approach. Finding and configuring 
a suitable theme was more challenging than getting a blog up and running. 
The theme was the first pretty theme I found supporting 
[Mermaid diagrams](https://mermaid-js.github.io/mermaid/#/),
math with [MathJax maths](https://www.mathjax.org/), and syntax 
highlighting out of the box.  I'll try to revisit this post as the blog matures.

## Getting the blog up and running

I'm using the 
[Ruby Gem method](https://tianqi.name/jekyll-TeXt-theme/docs/en/quick-start#ruby-gem-method) 
to get my theme working. When writing a post, or testing modifications, 
I run Jekyll locally before pushing it to GitHub.
Posts added to `_drafts/` will not be published when pushing, 
which is great when writing longer posts.
To serve the site including drafts locally to the default 
`http://127.0.0.1:4000`, I run
```sh
$ bundle exec jekyll serve --drafts
```
The local server rebuilds the site when the source is modified 
(with the notable exception of `_config.yml`). Not only does this cut on 
waiting for GitHub to build the site, but it also allows me to spot 
mistakes before publishing.

## Customization

I enabled a few options:
* Enabled tag for Google [Analytics](https://analytics.google.com) and 
  [Search Console](https://search.google.com/search-console/about)
* Enabled [AddToAny](https://www.addtoany.com/) support for easy sharing of posts

and made some additions:
* Left aligned, indented equations by adding 
  `displayAlign: "left", displayIndent: "2em"` to 
  `_config` in `_includes/markdown-enhancements/mathjax`. 
* Support comments through [utterances](https://utteranc.es/) 
  following the example in this very helpful 
  [gist](https://gist.github.com/mwt/7b747b45d5e28e7a943490d7a3b8a4ff)
* Collapsible content containers through a 
  [details tag snippet](http://movb.de/jekyll-details-support.html)
    - Not working with code block content :(
* Included [jekyll-figure plugin](https://github.com/paulrobertlloyd/jekyll-figure) to get 
  pictures with `figure` and `figurecaption` tags.
* Included osano cookine consent following the approach of [www.chuvisco.me](https://www.chuvisco.me/technology/2019/07/01/cookie-consent/)

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

Header photo by <a href="https://unsplash.com/@villepalmu?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Ville Palmu</a> on <a href="https://unsplash.com/s/photos/sarek?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText">Unsplash</a>


