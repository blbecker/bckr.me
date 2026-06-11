---
title: "Implementing standard.site"
date: 2026-06-06T04:16:36Z
tags:
  - blog
categories:
  - tech
summary: CI/CD based standard.site publishing with sequoia, hugo, and github actions.
draft: true
---

## Standard.site

[Standard.site](https://standard.site/) is a set of lexicons for describing long-form publications on ATProto. The standard provides schemas for describing publications (websites, blogs, etc), documents (posts or pages), subscription (following), and recommending (basically a like). The standard also describes a mechanism for verification, based on a `.well-known` endpoint and html `<link>`s. Publications are verified via .well-known and may optionally include html links for discovery hints. Documents are verified by including an html link to the atProto URI for that document.

## Sequoia

[Sequoia](https://sequoia.pub/blog/introducing-sequoia) is a CLI tool for publishing a self-hosted blog to atproto. It has first class support for static site generators and a great fit for this site. Setup is simple following the [quickstart guide](https://sequoia.pub/quickstart).

```bash
npm i -g sequoia-cli
sequoia auth # Use an app password
sequoia init # Follow the prompts
```

### Publishing

Sequoia provides a [`publish`](https://sequoia.pub/cli-reference#publish) command to parse markdown posts and generate atProto records corresponding to those resources. Publishing also injects the URI of the atProto record into the frontmatter of the source markdown file. In CI/CD, the publish step runs _before_ the hugo build so that these variables are populated before rendering.

## Hugo

### Config

`sequoia init` will create a new publication and emit a publication URI. This value is also contained in `sequoia.json`. This value will be included in our generated pages for verfication, so I store it in site parameter for reference in a partial. The atProto URIs for posts are made available via the frontmatter injected by `sequoia publish`.

### Verification

Verification of publications is done via a `.well-known` endpoint. I create a file at `site/static/` containing my publication URI to create the endpoint.

Verification of the documents requires including an html `<Link>` containing the atProto uri of the `site.standard.document` object. The [theme](https://jpanther.github.io/congo/) for this site supports an `extend-head.html` partial to add elements to the `<head>` globally. I conditionally inject a site.standard.document link, if an atUri param is specified, and always include the site.standard.publication link. There are some pages on my site that I don't publish documents for (currently, anyway), such as slash pages, and this conditional insertion handles this transparently.

```html
<!-- atproto verification -->
{{ if .Params.atUri }}
<link rel="site.standard.document" href="{{ safeURL .Params.atUri }}" />
{{ end }}
<link
  rel="site.standard.publication"
  href="{{ safeURL .Site.Params.standardSitePublicationURI }}"
/>
```

## Github Actions

### Secrets

Sequoia requires an app password to function, requiring secrets management. I use [dotenvx](https://dotenvx.com/) in this and other projects to encrypt secrets and store them with the repo in a platform agnostic way. I store an encrypted [`.env`](https://github.com/blbecker/bckr.me/blob/main/.env) file that stores my DID, sequoia app password, and pds url (seemingly required for self-hosted PDSs). Operations are simple and I only need to provide a private key to dotenvx (via a github secret) to decrypt the remaining secrets. Any new secrets for the project can be added to the `.env` file and made available everywhere the project builds.

The actions workflow performs the publication using dotenvx to populate the encrypted environment variables.

```yaml {hl_lines=["2-3","5"]}
- name: Publish to ATProto
  env:
    DOTENV_PRIVATE_KEY: ${{ secrets.DOTENV_PRIVATE_KEY }}
  run: |
    if [ "${{ github.event_name }}" = "pull_request" ]; then
      dotenvx run -f .env -- sequoia publish --dry-run
    else 
      dotenvx run -f .env -- sequoia publish 
    fi
```

### Post-publish commit

When publishing a post, sequoia writes the atUri back to the frontmatter of the markdown. In order to preserve these values, we commit them back to the repo.

```yaml {hl_lines=["4","13"]}
- name: Check for ATProto Changes
  id: check_changes
  run: |
    if [[ -n "$(git diff --exit-code)" ]]; then
      echo "Changes detected."
      echo "has_changes=true" >> $GITHUB_OUTPUT
    else
      echo "No changes detected."
      echo "has_changes=false" >> $GITHUB_OUTPUT
    fi

- name: Commit and Push ATProto Changes
  if: steps.check_changes.outputs.has_changes == 'true'
  run: |
    # configure user
    git config --global user.name "${{ github.actor }}"
    git config --global user.email "${{ github.actor }}@users.noreply.github.com"

    # stage any file changes to be committed
    git add .

    # make commit with staged changes
    git commit -m 'chore(atproto): commit atproto publishing updates'

    # push the commit back up to source GitHub repository
    git push
```

## Confirmation

The atProto records published by sequoia can be explored with [pdsls.dev](https://pdsls.dev). [site-validator.flu.dev](https://site-validator.fly.dev/) can be used to validate the verification implementation for documents and publications. The real confirmation test will come shortly after I publish this, though, when I publish my first bluesky post referencing my standard.site documents :sweat_smile:.

## Links

- [CI/CD Workflow](https://github.com/blbecker/bckr.me/blob/402f68e7395a656a2c259bce374f2e0df3cda0fa/.github/workflows/build-deploy.yml)
- [Standard.site Validator](https://site-validator.fly.dev/)
