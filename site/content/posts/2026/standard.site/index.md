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

## Sequoia

[Sequoia](https://sequoia.pub/blog/introducing-sequoia) is a CLI tool for publishing a self-hosted blog to atproto. It has first class support for static site generators and a great fit for this site. Setup is simple following the [quickstart guide](https://sequoia.pub/quickstart).

## Hugo

Standard.site publications include some metadata to establish the connection to the atproto record for the publication and documents. This metadata is stored in rel links in the head of the html document. When publishing, sequoia injects the atproto record uri into an `atUri` key in the markdown frontmatter. We can consume this parameter to reference the atUri for each post automatically. The Congo theme I use for this site supports an `extend-head.html` to add elements to the `<head>` globally. We'll conditionally inject a site.standard.document link, if an atUri param is specified, and always include the site.standard.publication link. This establishes the trust relationship between the atproto-published standard.site objects and the website.

```html
<!-- atproto verification -->
{{ if .Params.atUri }}
<link rel="site.standard.document" href="{{ safeURL .Params.atUri }}" />
{{ end }}
<link
  rel="site.standard.publication"
  href="at://did:plc:u6nttbpfrjvdgyzjj6c7fih7/site.standard.publication/3mnljdbkemk24"
/>
```

## Secrets

To simplfy CI and future extensions, I'm using dotenvx to to encrypt a `.env` file in the repo to provide sequoia its config. This env file stores my DID, sequoia app password, and pds url (seemingly required for self-hosted PDSs).

## Github Actions

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

## Links

- [Full Implementation](https://github.com/blbecker/bckr.me/tree/402f68e7395a656a2c259bce374f2e0df3cda0fa)
- [Standard.site Validator](https://site-validator.fly.dev/)
