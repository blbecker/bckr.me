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
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> WIP: Working on authenticated repos post.
Recently, at work, I came across a requirement to establish authenticated package repositories (RPM and DEB) for software we distribute. This was a surprisingly non-trivial task. Broadly speaking, there are two ways to pull this off--using HTTP Basic Auth or Client SSL Certs. Which makes sense for you will depend on your goals and environment.

Both RPM and Debian repositories consist, essentially, of a webserver providing structured files at an expected location. Neither format requires (though, software offerings do exist in this area) an application server providing any sort of intelligence to deliver software. If packages are available at the correct paths with the correct metadata in the correct location, you've got a repository server. As a result, the configuration of the server side of both of these authentication mechanisms does not differ from the typical deployment of those mechanism. That is to say, if you can configure an nginx host to use basic auth, then you can configure nginx *serving a package repository* to use basic auth. The configuration of the clients, on the other hand, requires a bit more work.

<!-- # Basic Auth
Documented in ~~[IETF RFC2617](https://tools.ietf.org/html/rfc2617)~~ [IETF RFC 7617](https://tools.ietf.org/html/rfc7617), Basic Auth is the authentication mechanism with which most users are familiar. Username, password, -->
<<<<<<< HEAD

# Basic Auth
## Configure Server
Basic Auth specifies the mechanism by which the client presents credentials to the webserver. It does not, however, specify what the webserver then does with those credentials. There are a huge number of options for basic auth backends, from simple htpasswd files to more complex systems such as LDAP or any number of proprietary SSO products. For the sake of simiplicity, we'll use htpasswd files here, but a production grade deployment would likely use something more robust.

I'll be using the below htpasswd file generated using the command `htpasswd -B -c repo-users.passwd exampleUser`. This command will prompt for a password, hash that password using `bcrypt` (due to the `-B` flag) and store the results in `./repo-users.passwd`.

=======
Recently, at work, I came across a requirement to establish authenticated package repositories (RPM and DEB) for software we distribute. This was a surprisingly non-trivial task. Broadly speaking, there are two ways to pull this off--using Basic Auth or Client SSL Certs. Which makes sense for you will depend on your goals and environment.
=======
>>>>>>> WIP: Working on authenticated repos post.

# Basic Auth
## Configure Server
Basic Auth specifies the mechanism by which the client presents credentials to the webserver. It does not, however, specify what the webserver then does with those credentials. There are a huge number of options for basic auth backends, from simple htpasswd files to more complex systems such as LDAP or any number of proprietary SSO products. For the sake of simiplicity, we'll use htpasswd files here, but a production grade deployment would likely use something more robust.

I'll be using the below htpasswd file generated using the command `htpasswd -B -c repo-users.passwd exampleUser`. This command will prompt for a password, hash that password using `bcrypt` (due to the `-B` flag) and store the results in `./repo-users.passwd`.

```
# ./repo-users.passwd

exampleUser:$2y$05$kXKPC7zN9J32KYLaiNRw9.HyEYT0yJ.zOkfqvwxYfUEuqSEMJxNLS
```

We must then configure the webserver to authenticate a resource using this file. Doing so requires ensuring that the htpasswd file is readable by the user running the webserver. Nginx typically runs as the user `nginx` while Apache could be run by either `httpd` or `apache` depending on distribution. In either case, this user may be determined by checking for which user is running the webserver process using `ps`. Once proper ownership and permissions are applied to the htpasswd file, basic auth may be configured by placing the following stanzas in the webserver configuration.


``` bash
# /etc/nginx/conf.d/repo.conf

server {
    listen       80;
    server_name  repo.example.com;

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

<!-- ``` aconf {linenos=table,hl_lines=["16-20"]} -->
``` aconf
# /etc/httpd/site-enabled/repo.conf (depending on distro)

NameVirtualHost *:80

<<<<<<< HEAD
# RPM
## Basic Auth
### Configure Server
### Configure Client
Entry in `/etc/yum/repos.d/${repoName}.repo` repo file
>>>>>>> WIP.
```
# ./repo-users.passwd

exampleUser:$2y$05$kXKPC7zN9J32KYLaiNRw9.HyEYT0yJ.zOkfqvwxYfUEuqSEMJxNLS
```

We must then configure the webserver to authenticate a resource using this file. Doing so requires ensuring that the htpasswd file is readable by the user running the webserver. Nginx typically runs as the user `nginx` while Apache could be run by either `httpd` or `apache` depending on distribution. In either case, this user may be determined by checking for which user is running the webserver process using `ps`. Once proper ownership and permissions are applied to the htpasswd file, basic auth may be configured by placing the following stanzas in the webserver configuration.


``` bash
# /etc/nginx/conf.d/repo.conf

server {
    listen       80;
    server_name  repo.example.com;

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

<!-- ``` aconf {linenos=table,hl_lines=["16-20"]} -->
``` aconf
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
        AuthName "Restricted Content"
        AuthUserFile /path/to/repo-users.htpasswd
        Require valid-user
    </Directory>
</VirtualHost>
```
## SSL Client Certificates
### Configure Server
### Configure Client

<<<<<<< HEAD
## Configure Client
Now that the server has been configured, we must tell the client tools to perform an HTTP Basic Auth as part of the connection to a particular repository. Unlike configuring the server, these configurations will be different for each type of repository.
### RPM
RPM clients (including `yum` and `dnf`) expect the configuration of http basic auth credentials to occur in the repo file for the repository. The RPM repo file spec includes username and password directives that may be used for this purpose.

Entry in repo file
``` bash
# /etc/yum/repos.d/${repoName}.repo
[example-repo]
name=example-repo
baseurl=https://example.repo.com/repo
gpgcheck=1
repo_gpgcheck=1
enabled=1

username=${username}
password=${passwordOrAPIToken}
```
### Debian
Debian uses auth.conf (typically at `/etc/apt/auth.conf`) to associate credentials with a particular repository. The structure of this is somewhat similar to ssh_config. A stanza is opened by specificing the remote host (machine, in auth.conf parlance) to which that configuration applies. Subsequent lines indicate configuration options for that machine until the file ends or another stanza begins.

=======
# Debian
## Basic Auth
### Configure Server
### Configure Client
>>>>>>> WIP.
=======
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
        AuthName "Restricted Content"
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
``` bash
# /etc/yum/repos.d/${repoName}.repo
[example-repo]
name=example-repo
baseurl=https://example.repo.com/repo
gpgcheck=1
repo_gpgcheck=1
enabled=1

username=${username}
password=${passwordOrAPIToken}
```
### Debian
Debian uses auth.conf (typically at `/etc/apt/auth.conf`) to associate credentials with a particular repository. The structure of this is somewhat similar to ssh_config. A stanza is opened by specificing the remote host (machine, in auth.conf parlance) to which that configuration applies. Subsequent lines indicate configuration options for that machine until the file ends or another stanza begins.

>>>>>>> WIP: Working on authenticated repos post.
Entry in `/etc/apt/auth.conf`
``` bash
# /etc/apt/auth.conf

machine repo.example.com/path/to/repository/root
    login ${username}
    password ${passwordOrAPIToken}
<<<<<<< HEAD
=======
```
# SSL Client Certificates
Most system administrators are likely familiar with using x509 certificates to verify the authenticity of webserver. In addition to verifying that a server is who it claims to be, though, these certificates may also be used to authenticate **clients**. Client certificate authentication can be a great option in those environments where strong identity verification is required, where clients may be configured with a certificate, and in which the management of a private CA is feasible (more on this in a later post). If those things are true, client certificates may provide stronger security than most basic authentication mechanisms and, depending on other available, might be more easily automated.

## Configure Server
In order to configure client certificate authentication, our webserver must have some mechanism for establishing the identity of clients. We do this by trusting a certificate authority (or CA) which issues certificates. If we trust a CA, then we also trust those certificates issued by that authority. This section assumes that a CA already exists which may issue certificates to the clients of this repository server.

``` bash
# /etc/nginx/conf.d/repo.conf

>>>>>>> WIP: Working on authenticated repos post.
```
<<<<<<< HEAD
# SSL Client Certificates
Most system administrators are likely familiar with using x509 certificates to verify the authenticity of webserver. In addition to verifying that a server is who it claims to be, though, these certificates may also be used to authenticate **clients**. Client certificate authentication can be a great option in those environments where strong identity verification is required, where clients may be configured with a certificate, and in which the management of a private CA is feasible (more on this in a later post). If those things are true, client certificates may provide stronger security than most basic authentication mechanisms and, depending on other available, might be more easily automated.

## Configure Server
In order to configure client certificate authentication, our webserver must have some mechanism for establishing the identity of clients. We do this by trusting a certificate authority (or CA) which issues certificates. If we trust a CA, then we also trust those certificates issued by that authority. This section assumes that a CA already exists which may issue certificates to the clients of this repository server.

``` bash
# /etc/nginx/conf.d/repo.conf

```

``` bash
# /etc/httpd/sites-enabled/repo.conf (depending on distro)

## Configure Client
### RPM
### Debian
=======

<<<<<<< HEAD
## SSL Client Certificates
### Configure Server
### Configure Client
>>>>>>> WIP.
=======
``` bash
# /etc/httpd/sites-enabled/repo.conf (depending on distro)

## Configure Client
### RPM
### Debian
>>>>>>> WIP: Working on authenticated repos post.
