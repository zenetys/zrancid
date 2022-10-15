### Overview

The following scripts can be used as CGI to expose (z)RANCiD data in HTTP:

* zrancid-ls<br/>
Provide per device last backup time, size, RANCiD type. JSON output supported.

* zrancid-git-log<br/>
Git log for a given device. JSON output supported.

* zrancid-git-diff<br/>
Git diff for a given device and commit hash

* zrancid-git-show<br/>
Git show of a config for a given device and commit hash

The scripts need access to the Git repository containing RANCiD data for the default group. There are environment variables you can pass to the scripts in order to fit your context, eg. web server on another host, Git repository cloned and sync'ed somewhere else than the (z)RANCiD environment.

* RANCID_BASEDIR=\<dir\><br/>
The directory where to locate RANCiD Git default repository, ie: $RANCID_BASEDIR/default. The web server need access to the directory.

* ZRANCID_RUNAS=\<user\><br/>
The script will be (re)exec with sudo -nu \<user\>. Note: assume you will loose RANCID_BASEDIR but it actually depends on the sudo configuration you put in place.

* ZRANCID_CGI=1<br/>
Make the script work as a CGI script. Arguments get read from the $QUERY_STRING environment variable and output includes HTTP status and headers.

**Note:** we do NOT talk about **authentication** nor **access control** here, it is out of scope.

### Apache integration

In this example apache runs on the same host as the (z)RANCiD environment. We just call the scripts with ZRANCID_RUNAS=rancid and ZRANCID_CGI=1.

Apache configuration:

```
root>  cat > /etc/httpd/conf.d/zrancid.conf <<'EOF'
ScriptAliasMatch "^/zrancid/(diff|log|show)$" "/opt/zrancid/bin/zrancid-git-$1"
ScriptAlias /zrancid/ls /opt/zrancid/bin/zrancid-ls

<LocationMatch "^/zrancid/(diff|log|ls|show)$">
    SetEnv ZRANCID_RUNAS rancid
    SetEnv ZRANCID_CGI 1
    # do better auth and access control
    Require all granted
</LocationMatch>
EOF

root>  systemctl reload httpd
```

Sudo configuration:

```
root>  cat > /etc/sudoers.d/apache-zrancid <<'EOF'
Cmnd_Alias APACHE_ZRANCID = \
    /opt/zrancid/bin/zrancid-ls, \
    /opt/zrancid/bin/zrancid-git-diff, \
    /opt/zrancid/bin/zrancid-git-log, \
    /opt/zrancid/bin/zrancid-git-show
Defaults!APACHE_ZRANCID env_keep += "ZRANCID_CGI QUERY_STRING"
apache ALL=(rancid) NOPASSWD: APACHE_ZRANCID
EOF

root>  chmod 400 /etc/sudoers.d/apache-zrancid
```

### Usage example

Usage example using paths as defined in the Apache configuration from perevious section.

When calling the scripts in CGI mode, arguments are passed via query string. Query parameters keys are the same as long options on the CLI.

* GET /zrancid/ls?json=1&verbose=3
* GET /zrancid/log?name=sw-acc-01.demo&json=1&verbose=1
* GET /zrancid/diff?name=sw-acc-01.demo&commit=458adda
* GET /zrancid/show?name=sw-acc-01.demo&commit=458adda
