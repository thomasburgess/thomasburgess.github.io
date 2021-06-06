---
title: Welcome
comments: true
tags: [blog, TeXt, jekyll, github]
---

Hi, I'm Thomas Burgess and this is my blog. I probably mostly will write about python sciency things I make. Today, I've set this thing up so I can share some of the things I learn (from time to time). In the process, I also figured out how to put something in my [github profile](https://github.com/thomasburgess). 

This blog is built with [jekyll](http://jekyllrb.com/) and the [TeXt](https://github.com/kitian616/jekyll-TeXt-theme) theme and hosted with [github](https://github.com/). This setup is quite cool as github autmatically generates the static site from markdown content on every push with zero configuration. Finding and configuring a suitable theme was more challenging than getting a blog up and running. I chose TeXt because it was the first non horrible theme that supported diagrams with [mermaidjs](https://mermaid-js.github.io/mermaid/#/), math with [mathjax](https://www.mathjax.org/) and syntax highlighting out of the box.

I am using the [Ruby Gem method](https://tianqi.name/jekyll-TeXt-theme/docs/en/quick-start#ruby-gem-method) to handle things. To test something locally before pushing, I can run
```sh
bundle exec jekyll serve
```
and open the site at `http://127.0.0.1:4000` to get a live view that regenerates when the source is modified. This saves me the waiting for github to regenerate the site, and allows me to spot mistakes fast.
