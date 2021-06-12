---
title: Welcome
comments: true
tags:
  - blog
  - TeXt
  - jekyll
  - github
published: true
---

Hi,

I’m Thomas Burgess and this is my blog. I’m a particle physicist turned data scientist, currently working in a health tech startup. Here, I’ll probably mostly write about python data science things I make. Today, I’ve set this thing up so I can share some of the things I learn (from time to time). In the process, I also figured out how to put something in my [GitHub profile](https://github.com/thomasburgess).

This blog is built with [Jekyll](http://jekyllrb.com/) and the [TeXt](https://github.com/kitian616/jekyll-TeXt-theme) theme and hosted for free on [GitHub](https://github.com/). This setup is quite cool as GitHub automatically generates the static site from markdown content on every push with zero configuration. It is quite easy to have a very similar setup in [GitLab](https://gitlab.com), but I wanted to try the [GitHub pages](https://pages.github.com/) approach. Finding and configuring a suitable theme was more challenging than getting a blog up and running. I chose TeXt because it was the first non-horrible theme I found that supported diagrams with [Mermaid](https://mermaid-js.github.io/mermaid/#/), math with [MathJax](https://www.mathjax.org/), and syntax highlighting out of the box.

## Blog deployment details

I'm using the [Ruby Gem method](https://tianqi.name/jekyll-TeXt-theme/docs/en/quick-start#ruby-gem-method) to get my theme working. With a local Jekyll installation, the blog can be tested before pushing to github with
```sh
$ bundle exec jekyll serve
```
and open the site at `http://127.0.0.1:4000`. This gets a live view that also regenerates when the source is modified, which saves waiting for GitHub to regenerate the site and gives me a chance to spot mistakes before publishing. For longer posts, working in the `_drafts` folder is useful, it lets you commit and sync content without publishing. By adding `--drafts` when running `serve` the local blog still include the unpublished drafts.

A noteworthy technicality, GitHub doesn't like the `theme:` pointing to an unsupported theme in `_config.yml` - I got warnings with every build (that otherwise actually worked). I just changed this to `remote-theme:` and the blog seems to work without throwing warnings now.

By appending the [utterances](https://utteranc.es/) script in `_layouts/article.html` a GitHub issues powered comments section is added to the site with minimal effort. 