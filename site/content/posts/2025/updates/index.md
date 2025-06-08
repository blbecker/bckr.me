---
title: "Updates"
date: 2025-06-10T20:59:50Z
draft: true
tags:
  - meta
  - blog
  - indieweb
categories:
  - personal
thumbnailAlt:
metaAlignment: left
summary: Updates to my website and thoughts on what to do next.
---

I've been a bit more active on my website lately, and I wanted to document a bit of what I've done and what I've been thinking about. Something about moving has me thinking more about documenting my experiences--especially in photographs--and sharing that with others (Rachel has said something similar about her website). I hope to spend more time doing things I enjoy, especially outside, and photography is something that Rachel and I enjoy doing together. This change in our lives is one of simplification and decluttering; perhaps I can simplify my engagement with the internet in a similar way.

## Website Updates

### Infrastructure

I've configured a CDN sharing content from object storage, which should be a very efficient way to share high resolution images. I actually had this partially configured previously, but I've now setup URL rewrites in a way that I like and have fully tested it.

<!-- prettier-ignore -->
{{< figure
    src="https://cdn.bckr.me/img/NGC3344_hst1024.jpg"
    alt="NASA Astronomy photo of the day of NGC 3344, a spiral galaxy in the constellation Leo Minor."
    caption="[APOD image of NGC 3344](https://apod.nasa.gov/apod/2506) served via the CDN"
    >}}

Right now, I just have some testing images (and a huge collection of [88x31 buttons](https://cdn.bckr.me/bin/hellnet_8831_buttons_nodupes.zip) :grin:) are in there currently, but if I find myself with a need to distribute data at scale, I'll be ready for it. If nothing else, I can share any photos I take at full resolution. If I do actually share a lot of photos, I'll probably need to build out some shortcodes to make that easier. The theme I use, Congo, supplies a versatile `figure` shortcode, but I'll need a way to handle carousels.

### Pages

I made some updates and additions to my slash pages. I updated my [/now]({{< relref "now" >}}) page to include some information about my [reading]({{< relref "now#reading" >}}) and slightly revised the bit about [moving]({{< relref "now#moving-to-puerto-rico" >}}). I also added a [/chipotle]({{< relref "chipotle" >}}) page which, despite the name, includes more than _just_ my Chipotle order. I hope I get the chance to use it, but it's a neat idea regardless. I added my Subway order as well, and am considering adding checkable checkboxes to make it a bit easier to use.

### Upcoming

I'd like to circle back around on my webmentions and indieweb features. I've built out a small number of shortcodes, that mostly just wrap content in a `span` with an appropriate type, but it's an okay foundation. Next, I'd like to work on recieving and sending webmentions. There's quite a bit of prior art out there for fetching and displaying webmentions for me to learn from. I'm already configured for recieving the mentions, but I don't have a way to display them yet. I intend to fetch the webmentions, store them as data in the repo, and then display them on the page. I like this solution because it will allow me to serve the mentions directly and avoid unnecessary 3rd party references on my site.
