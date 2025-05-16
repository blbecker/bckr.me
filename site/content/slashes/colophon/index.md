---
title: "Colophon"
date: 2025-05-09T12:00:00-04:00
draft: false
url: colophon
menus: Slashes
summary: How it's made!
weight: 40
showAuthor: false
sharingLinks: false
invertPagination: true
---

## Philosophy

This website is meant to serve as an expression of myself, my interests, and my values. I've approached this project as an opportunity to experiment and to operate a software project according to my preferences. I've chosen open-source and privacy respecting technologies. The website does not load third-party javascript or utilize any form of tracking.

The code of the website is licensed under [GPLv3](https://www.gnu.org/licenses/gpl-3.0-standalone.html) and the content is licensed [CC-BY-SA](https://creativecommons.org/licenses/by-sa/4.0/).

## Toolchain

This is a static website built using Hugo. The theme is [Congo](https://git.io/hugo-congo) by JPanther, with some minor tweaks to handle webformats for the indieweb. The source code is hosted on [Github](https://github.com/blbecker/bckr.me) and built/deployed using Github Actions. Because this site is open-source, it's eligible for the Github Actions free tier, so it's a very convenient way to operate the project.

## Hosting

The website is hosted on Cloudflare pages. Initially, I was using the built in deployment functionality, in which the page is built by Cloudflare, but have since migrated to deploying via Github Actions CI/CD pipelines. This allows me to perform validation steps prior to deployment to provide things like [spellcheck](https://github.com/tbroadley/spellchecker-cli) and [secrets leak detection](https://github.com/gitleaks/gitleaks)

Large media is stored on Backblaze B2 and served via Cloudflare. Backblaze and Cloudflare have a [partnership](https://www.backblaze.com/docs/cloud-storage-deliver-public-backblaze-b2-content-through-cloudflare-cdn) under which serving content from a bucket via Cloudflare does not incur egress fees, providing efficient distribution of large media at nearly zero cost.

## IndieWeb

This website is configured for Indieweb functionality. Webmentions are received via [webmention.io](https://webmention.io/). If I continue to leverage webmentions long-terrm, I may migrate my receiver to my [homelab]( {{< ref "now#Homelab" >}} ) or look at a serverless solution using Cloudflare Workers and some kind of cheap storage.

I haven't wired up webmention sending yet, but I plan on utilizing [timmarinin/Webmention](https://github.com/timmarinin/webmention) or [willnorris/webmention](https://github.com/willnorris/webmention) as a Github Actions step after deployment to send webmentions.

My current theme doesn't include microformats markup out of the box, so I've had to override some layouts. So far, this hasn't been too intrusive so maintaining compatibility with upstream shouldn't be too difficult. I've added shortcodes for some mf2 markup to simplify using them inside content.
