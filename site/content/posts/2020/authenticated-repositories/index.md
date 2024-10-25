---
title: "Authenticated Repositories"
date: 2020-01-27T17:19:28-05:00
lastmod: 2023-05-04T17:19:28-05:00
draft: false
tags:
  - linux
  - packaging
  - rpm
  - deb
categories:
  - tech
thumbnailImage: https://farm1.staticflickr.com/629/21860953461_35de6932ce_b.jpg
thumbnailImagePosition: left
thumbnailAlt: A closed lock secures a door latch. The door and lock are lightly weathered.
metaAlignment: left
summary: Authenticated software repositories are a great solution for proprietary distribution, as well as controlling access to dev/beta releases. Native tools support this, but proper implementations are non-obvious.
aliases:
- posts/authenticated-repositories
---

Although RPM and Debian repos are generally intended for distributing software to the public, there are times when a more private approach is desired. Whether for proprietary software or merely keeping "the internet" out of development spaces, let's take a look at how to secure linux package repositories in a way that is transparent to native tools.

Recently, at work, I came across a requirement to establish authenticated package repositories (RPM and DEB) for software we distribute. This was a surprisingly non-trivial task. Broadly speaking, there are two ways to pull this off--using HTTP Basic Auth or Client SSL Certs. Which makes sense for you will depend on your goals and environment.

Both RPM and Debian repositories consist, essentially, of a webserver providing structured files at an expected location. Neither format requires (though, software offerings do exist in this area) an application server providing any sort of intelligence to deliver software. If packages are available at the correct paths with the correct metadata in the correct location, you've got a repository server. As a result, the configuration of the server side of both of these authentication mechanisms does not differ from the typical deployment of those mechanism. That is to say, if you can configure an nginx host to use basic auth, then you can configure nginx *serving a package repository* to use basic auth. The configuration of the clients, on the other hand, requires a bit more work.

<!-- toc -->

# Basic Auth
## Configure Server
[Basic Auth](https://tools.ietf.org/html/rfc7617) specifies the mechanism by which the client presents credentials to the webserver. It does not, however, specify what the webserver then does with those credentials. There are a huge number of options for basic auth backends, from simple htpasswd files to more complex systems such as LDAP or any number of proprietary SSO products. For the sake of simiplicity, we'll use htpasswd files here, but a production grade deployment would likely use something more robust.

I'll be using the below htpasswd file generated using the command `htpasswd -B -c repo-users.passwd exampleUser`. This command will prompt for a password, hash that password using `bcrypt` (due to the `-B` flag) and store the results in `./repo-users.passwd`.

```
# ./repo-users.passwd

exampleUser:$2y$05$kXKPC7zN9J32KYLaiNRw9.HyEYT0yJ.zOkfqvwxYfUEuqSEMJxNLS
```

We must then configure the webserver to authenticate a resource using this file. Doing so requires ensuring that the htpasswd file is readable by the user running the webserver. Nginx typically runs as the user `nginx`, while Apache could be run by either `httpd` or `apache` depending on distribution. In either case, this user may be determined by checking for which user is running the webserver process using `ps`. Once proper ownership and permissions are applied to the htpasswd file, basic auth may be configured by placing the following stanzas in the webserver configuration.


#### Configure Nginx
``` bash {linenos=table,hl_lines=["7-9"]}
# /etc/nginx/conf.d/repo.conf

server {
    listen       80;
    server_name  repo.example.com;

    # Configure Basic Auth
    auth_basic           "Restricted Repository Content";
    auth_basic_user_file /path/to/repo-users.htpasswd;

    charset koi8-r;
    access_log  /data/logs/host.access.log  main;

    location / {
        root   /data/www/html;
        index  index.html index.htm;
    }

    error_page  404              /404.html;

    location /repo {
       alias /data/www/html/repo/;
       autoindex on;
    }

}
```

#### Configure Apache

The Apache webserver can be configured similarly using an Auth stanza within the Directory block.

``` aconf {linenos=table,hl_lines=["16-20"]}
# /etc/httpd/site-enabled/repo.conf (depending on distro)

NameVirtualHost *:80

<VirtualHost *:80>
    ServerAdmin webmaster@repo.example.com
    ServerName My Repository
    ServerAlias repo.example.com
    DocumentRoot /var/www/html
    ErrorLog /var/log/httpd/error.log
    CustomLog /var/log/httpd/access.log combined
    <Directory "/var/www/html">             
        AllowOverride All
        Require all granted                 # required in Apache 2.4

        # Configure Basic Auth
        AuthType Basic
        AuthName "Restricted Repository Content"
        AuthUserFile /path/to/repo-users.htpasswd
        Require valid-user
    </Directory>
</VirtualHost>
```

## Configure Client
Now that the server has been configured, we must tell the client tools to perform an HTTP Basic Auth as part of the connection to a particular repository. Unlike configuring the server, these configurations will be different for each type of repository.
### RPM
RPM clients (including `yum` and `dnf`) expect the configuration of http basic auth credentials to occur in the repo file for the repository. The RPM repo file spec includes username and password directives that may be used for this purpose.

Entry in repo file
``` bash {linenos=table,hl_lines=["10-12"]}
# /etc/yum/repos.d/example-repo.repo

[example-repo]
name=example-repo
baseurl=https://example.repo.com/repo
gpgcheck=1
repo_gpgcheck=1
enabled=1

# Configure Basic Authentication
username=${username}
password=${passwordOrAPIToken}
```
### Debian
Debian uses auth.conf (typically at `/etc/apt/auth.conf`) to associate credentials with a particular repository. The structure of this is somewhat similar to ssh_config. A stanza is opened by specificing the remote host (machine, in auth.conf parlance) to which that configuration applies. Subsequent lines indicate configuration options for that machine until the file ends or another stanza begins.

Entry in `/etc/apt/auth.conf`
``` bash {linenos=table,hl_lines=["3-5"]}
# /etc/apt/auth.conf

machine repo.example.com/path/to/repository/root
    login ${username}
    password ${passwordOrAPIToken}
```

``` bash {linenos=table,hl_lines=["5-6"]}
# /etc/apt/sources.list

...

# Configure repo corresponding to /etc/apt/auth.conf
deb https://example.repo.com/ ${distro} ${component}

```
# SSL Client Certificates
<!-- FixMe: Add Article About Private PKI -->
Most system administrators are likely familiar with using x509 certificates to verify the authenticity of webserver. In addition to verifying that a server is who it claims to be, though, these certificates may also be used to authenticate **clients**. Client certificate authentication can be a great option in those environments where strong identity verification is required, where clients may be configured with a certificate, and in which the management of a private CA is feasible (more on this in a later post). If those things are true, client certificates may provide stronger security than most basic authentication mechanisms and, depending on other available, might be more easily automated.

## Configure Server
In order to configure client certificate authentication, our webserver must have some mechanism for establishing the identity of clients. We do this by trusting a certificate authority (or CA) which issues certificates. If we trust a CA, then we also trust those certificates issued by that authority. This section assumes that a CA already exists which may issue certificates to the clients of this repository server.

#### Nginx
``` bash {linenos=table,hl_lines=["7-8","10-12"]}
# /etc/nginx/conf.d/repo.conf

server {
    listen       80;
    server_name  repo.example.com;

    ssl_client_certificate /etc/example/ca.pem;
    ssl_verify_client on;

    # Verification depth is optional.
    # Only set if you control both ca and clients.
    # ssl_verify_depth 1;

    charset koi8-r;
    access_log  /data/logs/host.access.log  main;

    location / {
        root   /data/www/html;
        index  index.html index.htm;
    }

    error_page  404              /404.html;

    location /repo {
       alias /data/www/html/repo/;
       autoindex on;
    }

}
```

#### Apache
``` aconf {linenos=table,hl_lines=[13,"19-21"]}
# /etc/httpd/site-enabled/repo.conf (depending on distro)

NameVirtualHost *:80

<VirtualHost *:80>
    ServerAdmin webmaster@repo.example.com
    ServerName My Repository
    ServerAlias repo.example.com
    DocumentRoot /var/www/html
    ErrorLog /var/log/httpd/error.log
    CustomLog /var/log/httpd/access.log combined

    SSLCACertificateFile /etc/example/ca.pem

    <Directory "/var/www/html">             
        AllowOverride All
        Require all granted                 # required in Apache 2.4

        # Require Client Certificate Auth For the repo Directory
        SSLOptions +StdEnvVars
        SSLVerifyClient require

    </Directory>
</VirtualHost>
```

## Configure Client
### RPM

Configuration is done in the repo file.
```bash {linenos=table,hl_lines=["10-13"]}
# /etc/yum/repos.d/example-repo.repo

[example-repo]
name=example-repo
baseurl=https://example.repo.com/repo
gpgcheck=1
repo_gpgcheck=1
enabled=1

# Configure SSL Client Certificate Authentication
sslverify=1
sslclientcert=/path/to/client.pem
sslclientkey=/path/to/client.key
```

### Debian
Configuration is primarily done in the apt.conf.d file which much must correspond to a repo defined in the sources.list file.

``` bash {linenos=table,hl_lines=["9-10","12-13"]}
# /etc/apt/apt.conf.d/50example-repo

Debug::Acquire::https "true";

Acquire::https::example.repo.com {
    Verify-Peer "true";
    Verify-Host "true";

    # Uncomment only if server is using non-standard CA
    # CaInfo "/opt/CA.crt";

    SslCert "/path/to/client.pem";
    SslKey  "/path/to/client.key";
};
```

``` bash {linenos=table,hl_lines=["5-6"]}
# /etc/apt/sources.list

    ...

    # Configure repo corresponding to apt.conf.d
    deb https://example.repo.com/ ${distro} ${component}

```
---

#### Attributions
["Security By Thy Name"](https://www.flickr.com/photos/37996646802@N01/21860953461) by [cogdogblog](https://www.flickr.com/photos/37996646802@N01) is licensed under [CC BY 2.0](https://creativecommons.org/licenses/by/2.0/?ref=ccsearch&atype=rich)
