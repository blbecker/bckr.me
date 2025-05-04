# bckr.me

[![Production](https://github.com/blbecker/bckr.me/actions/workflows/deploy.yml/badge.svg)](https://github.com/blbecker/bckr.me/actions/workflows/deploy.yml)

Source for <https://bckr.me>

## Dev

This website is built using [Hugo](https://gohugo.io/). To build the site, run:

```bash
docker compose up -d \
  --remove-orphans
```

Theme: <https://github.com/jpanther/congo>

## IndieWeb Features

- Webmentions via webmention.io
- [h-card](https://microformats.org/wiki/h-card#Properties) for author on the homepage (considering moving to about)
- [h-entry](http://microformats.org/wiki/h-entry#Properties) markup on Posts
- Shortcodes for some microformats
  - Hugo also supports [appending attributes](https://gohugo.io/content-management/markdown-attributes/#overview) for some elements in Markdown
