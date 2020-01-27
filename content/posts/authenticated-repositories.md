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
# RPM
## Configure Server
## Configure Client
Entry in `/etc/yum/repos.d/${repoName}.repo` repo file
```
username=user
password=pass
```

# Debian
## Configure Server
## Configure Client
Entry in `/etc/apt/auth.conf`
``` bash
machine ${repoServer}/${repoPath}
    login ${username}
    password ${password or API Token}
```
