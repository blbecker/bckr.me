# bckr.me

[![Production](https://github.com/blbecker/bckr.me/actions/workflows/deploy.yml/badge.svg)](https://github.com/blbecker/bckr.me/actions/workflows/deploy.yml)

Source for <https://bckr.me>

## Dev

This website is built using [Hugo](https://gohugo.io/). There's a docker-compose at the root of the repo for building and operations. By default, `hugo server` is run as a compose service serving the website at <http://localhost:1313>

Running in dev mode

```bash
docker compose up -d \
  --remove-orphans
```

Creating a post

```bash
docker compose run hugo new content path/to/content
docker compose run hugo new content posts/$(date +%Y)/${post_title}
```

Theme: <https://github.com/jpanther/congo>

## IndieWeb Features

- Webmentions via webmention.io
- [h-card](https://microformats.org/wiki/h-card#Properties) for author on the homepage (considering moving to about)
- [h-entry](http://microformats.org/wiki/h-entry#Properties) markup on Posts
- Shortcodes for some microformats
  - Hugo also supports [appending attributes](https://gohugo.io/content-management/markdown-attributes/#overview) for some elements in Markdown
