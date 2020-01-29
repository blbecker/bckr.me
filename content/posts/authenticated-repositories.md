---
title: "Authenticated Repositories"
date: 2020-01-27T17:19:28-05:00
draft: true
tags:
  - linux
  - packaging
  - rpm
  - deb

---
Recently, at work, I came across a requirement to establish authenticated package repositories (RPM and DEB) for software we distribute. This was a surprisingly non-trivial task. Broadly speaking, there are two ways to pull this off--using Basic Auth or Client SSL Certs. Which makes sense for you will depend on your goals and environment.

# Basic Auth
Documented in ~~[IETF RFC2617](https://tools.ietf.org/html/rfc2617)~~ [IETF RFC 7617](https://tools.ietf.org/html/rfc7617), Basic Auth is, as one might expect, quite simple. Set an HTTP Authorization header with base64 contents, and you're good to go. More importantly, the components of a basic auth request--a username and password--are standard across a variety of authentication and authorization platforms. 

# RPM
## Basic Auth
### Configure Server
### Configure Client
Entry in `/etc/yum/repos.d/${repoName}.repo` repo file
```
username=user
password=pass
```
## SSL Client Certificates
### Configure Server
### Configure Client

# Debian
## Basic Auth
### Configure Server
### Configure Client
Entry in `/etc/apt/auth.conf`
``` bash
machine ${repoServer}/${repoPath}
    login ${username}
    password ${password or API Token}
```

## SSL Client Certificates
### Configure Server
### Configure Client
