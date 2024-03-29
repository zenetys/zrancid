### Overview

Here we take advantage of the zrancid-plogin command, which calls RANCiD's plogin command to open a shell on a device. We use [ttyd](https://github.com/tsl0922/ttyd) to expose it in a browser.

**Note:** we do NOT talk about **authentication** nor **access control** here, it is out of scope.

In this example the context is as follows:

* ttyd listens internally on a unix socket
* apache is in front and exposes ttyd via path /ttyd/
* apache has permissions to read and write on ttyd unix socket
* both apache and ttyd runs on the same host as the (z)RANCiD environment

### ttyd setup

We assume ttyd has been installed on your system.

Note: ZENETYS provides a ttyd package for el7, el8, el9. Sources to build the RPM are available in Github repo [zenetys/rpm-ttyd](https://github.com/zenetys/rpm-ttyd). Alternatively, a prebuilt RPM is available on our YUM reposiories at [packages.zenetys.com](https://packages.zenetys.com).

Create a dedicated user for the ttyd instance:

```
root>  groupadd -g 50001 ttyd-demo
root>  useradd -g 50001 -u 50001 -s /sbin/nologin ttyd-demo
```

Create the handler script that will be run on ttyd access. This sample script will run zrancid-login as user rancid (sudo) with the name of the device to connect to as argument, taken from the URL query string.

```
root>  mkdir /opt/ttyd-demo
root>  cp /opt/zrancid/share/share/ttyd-handler.sample /opt/ttyd-demo/ttyd-handler
root>  chmod 755 /opt/ttyd-demo/ttyd-handler
```

Create the systemd service for that ttyd instance. Here we let ttyd drop provileges and we make the socket writtable to apache in order to get something functional without to much hassle. Note that option -I /usr/share/ttyd/ttyd-alt-index.html can be removed, it comes from our ttyd RPM package only to render the overlay div with a sans-serif font.

```
root>  cat > /etc/systemd/system/ttyd-demo.service <<'EOF'
[Unit]
Description=ttyd-demo
After=syslog.target
After=network.target

[Service]
Type=exec
ExecStart=/bin/sh -c 'exec /usr/bin/ttyd -i /run/ttyd-demo.sock -u $(id -u ttyd-demo) -g $(id -g ttyd-demo) -U ttyd-demo:apache -W -I /usr/share/ttyd/ttyd-alt-index.html -b / -H X-Remote-User -t disableReconnect=true -a /opt/ttyd-demo/ttyd-handler'
Restart=always
SyslogIdentifier=ttyd-demo

[Install]
WantedBy=multi-user.target
EOF

root>  systemctl daemon-reload
root>  systemctl start ttyd-demo
```

Add the sudo configuration to allow user ttyd-demo to run zrancid-login as user rancid:

```
root>  cat > /etc/sudoers.d/ttyd-zrancid <<'EOF'
Cmnd_Alias TTYD_ZRANCID = /opt/zrancid/bin/zrancid-login
ttyd-demo ALL=(rancid) NOPASSWD: TTYD_ZRANCID
EOF
```

### Apache configuration

Create an Apache configuration to do reverse proxy between the web client and ttyd. Again, security is out of scope here; you need to grant access for testing:

```
root>  cat > /etc/httpd/conf.d/ttyd.conf <<'EOF'
Redirect /ttyd /ttyd/

<Location /ttyd/>
    RequestHeader set X-Remote-User expr=anonymous@%{REMOTE_ADDR}
    RequestHeader unset Authorization
    # do proper auth and access control or grant for testing
    #Require all granted
    Require all denied
</Location>

# port 9999 does not exists, it is a dummy port to workaround a bug in
# mod_proxy_wstunnel (https://bz.apache.org/bugzilla/show_bug.cgi?id=65958)
ProxyPass /ttyd/ws unix:/run/ttyd-demo.sock|ws://127.0.0.1:9999/ws
ProxyPass /ttyd/ unix:/run/ttyd-demo.sock|http://127.0.0.1/
ProxyPassReverse /ttyd/ unix:/run/ttyd-demo.sock|http://127.0.0.1/
EOF

root>  systemctl reload httpd
```

### Test it

Now point your web browser to http(s)://\<name-or-address\>/ttyd/?arg=\<rancid-device-name\>, you should get a terminal on the device. You can see it live (but readonly) on our YaNA demo here: https://tools.zenetys.com/yana/.
