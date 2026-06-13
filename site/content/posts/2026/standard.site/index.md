---
title: "Implementing standard.site"
date: 2026-06-06T04:16:36Z
tags:
  - blog
categories:
  - tech
summary: CI/CD based standard.site publishing with sequoia, hugo, and github actions.
---

After [standard.site](https://standard.site/) was released, I wanted to see how well it fit into a statically generated blog published via CI/CD. I've experimented with [indieweb](https://indieweb.org/) solutions, like [microformats](https://microformats.org/) and [webmentions](https://webmention.net/), before and was excited to try another variation on the concept. I was impressed with the simplicity of the integration and robustness of the tooling. With a couple of additions to my templates and a CI stage, I'm able to syndicate posts to ATProto and expose metadata that enables discovery and interaction.

## Standard.site

[Standard.site](https://standard.site/) is a set of lexicons for describing long-form publications on ATProto. The standard provides schemas for describing publications (sites), documents (posts/pages), subscriptions (following), and recommendations (likes). Verification happens at two layers: publications expose ownership via .well-known, while documents advertise their ATProto identity through HTML `<link>` tags.

## Sequoia

[Sequoia](https://sequoia.pub/blog/introducing-sequoia) is a CLI tool for publishing a self-hosted blog to ATProto. It has first-class support for static site generators and is a great fit for this site. Setup is simple following the [quickstart guide](https://sequoia.pub/quickstart).

```bash
npm i -g sequoia-cli
sequoia auth # Use an app password
sequoia init # Follow the prompts
```

### Publishing

Sequoia provides a [`publish`](https://sequoia.pub/cli-reference#publish) command to parse markdown posts and generate ATProto records corresponding to those resources. Publishing also injects the URI of the ATProto record into the frontmatter of the source markdown file. Because publish mutates frontmatter, the publish step runs _before_ the hugo build so that these variables are populated before rendering.

## Hugo

### Config

`sequoia init` will create a new publication and return its URI. This value is also contained in `sequoia.json`. This value will be included in our generated pages for verification, so I store it as a site parameter for reference in a partial. The ATProto URIs for posts are made available via the frontmatter injected by `sequoia publish`.

### Verification

Verification of publications is done via a `.well-known` endpoint. I create a file at `site/static/.well-known/site.standard.publication` containing my publication URI to create the endpoint.

```
at://did:plc:u6nttbpfrjvdgyzjj6c7fih7/site.standard.publication/3mnljdbkemk24
```

Verification of the documents requires including an html `<link>` containing the ATProto uri of the `site.standard.document` object. The [theme](https://jpanther.github.io/congo/) for this site supports an `extend-head.html` partial to add elements to the `<head>` globally. I conditionally inject a site.standard.document link, if an atUri param is specified, and always include the site.standard.publication link. There are some pages on my site that I don't publish documents for (currently, anyway), such as slash pages, and this conditional insertion handles this transparently.

Hugo sanitizes unknown URI schemes by default, so the at:// URIs must be wrapped with safeURL to prevent them from rendering as #ZgotmplZ.

```html
<!-- ATProto verification -->
{{ if .Params.atUri }}
<link rel="site.standard.document" href="{{ safeURL .Params.atUri }}" />
{{ end }}
<link
  rel="site.standard.publication"
  href="{{ safeURL .Site.Params.standardSitePublicationURI }}"
/>
```

After Hugo renders the page, the generated HTML contains references to both the document and publication records:

```html
<link
  rel="site.standard.document"
  href="at://did:plc:u6nttbpfrjvdgyzjj6c7fih7/site.standard.document/3mnlmzlm2lk24"
/>
<link
  rel="site.standard.publication"
  href="at://did:plc:u6nttbpfrjvdgyzjj6c7fih7/site.standard.publication/3mnljdbkemk24"
/>
```

## Github Actions

### Secrets

Sequoia requires an app password to function, which requires secrets management. I use [dotenvx](https://dotenvx.com/) in this and other projects to encrypt secrets and store them with the repo in a platform agnostic way. I store an encrypted [`.env`](https://github.com/blbecker/bckr.me/blob/main/.env) file that stores my DID, sequoia app password, and PDS URL (seemingly required for self-hosted PDSs). Operations are simple and I only need to provide a private key to dotenvx (via a github secret) to decrypt the remaining secrets. Any new secrets for the project can be added to the `.env` file and made available everywhere the project builds.

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

When publishing a post, sequoia writes the atUri back to the frontmatter of the markdown. These values become part of the metadata of the post, binding it to an ATProto object, so we commit this change back to the repo.

```yaml {hl_lines=["4","13"]}
- name: Check for ATProto Changes
  id: check_changes
  run: |
    if ! git diff --quiet; then
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
    git commit -m 'chore(ATProto): commit ATProto publishing updates'

    # push the commit back up to source GitHub repository
    git push
```

## Confirmation

The ATProto records published by sequoia can be explored with [pdsls.dev](https://pdsls.dev). [site-validator.flu.dev](https://site-validator.fly.dev/) can be used to validate the verification implementation for documents and publications. The real confirmation test will come shortly after I publish this, though, when I publish my first bluesky post referencing my standard.site documents :sweat_smile:.

## Thoughts

I really like this tooling. Sequoia fits really well into the static site CI/CD workflow and coupling it with dotenvx for secrets management makes publication highly portable. I also appreciate the tidiness of the integration and, particularly, the injection of `atURI`s into the frontmatter. The interesting part of this setup is that ATProto publication becomes another deterministic build artifact alongside generated HTML. The source of truth remains the markdown content and templates, while CI handles replication into the social graph.

## Links

- [CI/CD Workflow](https://github.com/blbecker/bckr.me/blob/f32aa3796901c0da0389467689d61f01afc9f41d/.github/workflows/build-deploy.yml)
- [Standard.site Validator](https://site-validator.fly.dev/)
