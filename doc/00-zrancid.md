### Install (z)RANCiD:

Described here for el8 (rocky):

```
root>  sed -i -re s,enabled=0,enabled=1, /etc/yum.repos.d/Rocky-PowerTools.repo
root>  dnf install rancid git tig perl-Hash-Merge-Simple perl-Data-Dumper
root>  tar xvzf zrancid-<version>.tar.gz -C /opt
root>  ln -s zrancid-<version> /opt/zrancid
```

On el8 the rancid package creates a **rancid user** with a home in /var/rancid; **we are going to use that user**.

**Note:** you could use any user with (z)RANCiD, keeping the following in mind:

* Depending on how your distribution integrates RANCiD, the user may need to be in a rancid group to get read access to /etc/rancid/rancid.types.* files.
* A lambda user won't have write access to /etc/rancid/rancid.types.conf. In the initial setup section, we register our custom types by writing in that file.

If you want to put your (z)RANCiD environment in another volume, eg. /data/rancid, you can just change the rancid user home directory. As opposed to creating a symlink, this method does not touch to the /var/rancid directory brought by the distribution package.

```
root>  mkdir -m 0700 /data/rancid
root>  cp /etc/skel/.bash* /data/rancid/
root>  chown -R rancid: /data/rancid
root>  usermod -d /data/rancid rancid
```

RANCiD runs with an umask of 0027. For consistency, to avoid mixing files with different permissions, we set it more globally on the rancid user's shell. We also make (z)RANCiD scripts accessible in the PATH for convenience.

```
root>  echo 'umask 0027' >> ~rancid/.bashrc
root>  echo 'export PATH="$PATH:/opt/zrancid/bin"' >> ~rancid/.bashrc
root>  chmod 0640 ~rancid/.bash*         # just for consistency with umask
```

### Initial setup:

(z)RANCiD works with a single RANCiD group "default". We use a normalized name for the devices: \<hostname\>.\<entity\>. The term entity refers as a domain, a site or a branch of a company, a customer, etc.

**Note:** we operate as user **rancid** now. To prepare the environment run the following:

```
rancid>  mkdir -p ~/etc/{auto,cloginrc,hosts} ~/data{,/logs}
rancid>  /opt/zrancid/share/fork-rancid-conf > ~/etc/rancid.conf
rancid>  rancid-cvs -f ~/etc/rancid.conf default
rancid>  ln -s /opt/zrancid/lib/pre-commit-hook ~/data/default/.git/hooks/pre-commit
```

Register custom types available in (z)RANCiD share directory:

```
rancid>  /opt/zrancid/share/register-types /etc/rancid/rancid.types.conf
```

Add your cloginrc templates. Here we copy samples from (z)RANCiD share directory. The format is the same as cloginrc(5) but without the device name field.

```
rancid>  cp /opt/zrancid/share/std-ssh-key.cloginrc.sample ~/etc/cloginrc/std-ssh-key.demo
rancid>  cp /opt/zrancid/share/std-telnet.cloginrc.sample ~/etc/cloginrc/std-telnet.demo
```

### Add a device:

In this example we add a device named **sw-core-01.demo** as rancid type **cisco**, reachable in direct at IP address **172.26.121.11**, through SSH using the cloginrc template **ssh-key.demo**:

```
rancid>  zrancid-add sw-core-01.demo cisco std-ssh-key.demo 172.26.121.11
```

### Test login:

Make sure we can get a shell on the device. Note: the argument is actually a regex pattern.

```
rancid>  zrancid-login sw-core-01.demo
```

### Test backup:

Test and dump RANCiD output for the device. Note: the argument is actually a regex pattern.

```
rancid>  zrancid-test sw-core-01.demo
```

### Schedule backups with cron

On el8 the rancid package brings a default crontab file /etc/cron.d/rancid. Here we replace it to call (z)RANCiD scripts instead. You can create another file or setup user crontabs if you prefer.

```
root>  cat > /etc/cron.d/rancid <<EOF
30 22 * * * rancid /opt/zrancid/bin/zrancid-run @all 2>&1 |logger -t cron-zrancid-run -p notice
0 4 * * * rancid /opt/zrancid/bin/zrancid-cleanlogs 30
EOF
```

### Run backups manually:

You can run the full RANCiD backup process manually, ie: for each device, retrieve configs, git commit, send mail notifications for changes. This is done with the zrancid-run command, followed by a regex pattern to filter on devices, or followed by keyword @all to do a full run.

```
rancid>  zrancid-run @all
```


### Add devices using a YaNA source

A script can assist in adding devices to (z)RANCiD backups. It searches for devices in a YaNA database, try to guess the right RANCiD types and, with a bit of configuration, will save you time when new devices are added in the network.

First you need to setup the base URL of your YaNA backend API:

```
rancid>  echo 'export YANA_BASEURL=http://yana.example.org/yana-core' >> ~/etc/zrancid.conf
```

Now we run the script, here filtering on the "demo" entity:

```
rancid>  zrancid-auto-yana -e demo
WARNING: zrancid-auto-yana: demo/8f5038..434d26, name=sw-dist-02 => SKIP, no rancid cloginrc
WARNING: zrancid-auto-yana: demo/9ce8aa..4d7aeb, name=sw-acc-01 => SKIP, no rancid cloginrc
WARNING: zrancid-auto-yana: demo/ebe543..3a2349, name=sw-acc-02 => SKIP, no rancid cloginrc
WARNING: zrancid-auto-yana: demo/43a134..70a070, name=sw-acc-03 => SKIP, no rancid cloginrc
...
```

A bit of configuration... let's tel it we want to use the cloginrc template "std-telnet.demo" for cisco devices:

```
rancid>  cat > ~/etc/auto/demo.yana.inc <<'EOF'
function get_rancid_cloginrc_demo() {
    case "$r_type,$types" in
        cisco,*) REPLY=std-telnet.demo; return 0 ;;
    esac
    return 1
}
EOF
```

Now run the script again (add option -y, --yes to disable dry-run):

```
rancid>  zrancid-auto-yana -e demo
INFO: zrancid-auto-yana: EXEC (dry-run): 'zrancid-add' 'sw-dist-02.demo' 'type=cisco' 'cloginrc=std-telnet.demo' 'address=172.26.121.22' 'via='
INFO: zrancid-auto-yana: EXEC (dry-run): 'zrancid-add' 'sw-acc-01.demo' 'type=cisco' 'cloginrc=std-telnet.demo' 'address=172.26.121.31' 'via='
INFO: zrancid-auto-yana: EXEC (dry-run): 'zrancid-add' 'sw-acc-02.demo' 'type=cisco' 'cloginrc=std-telnet.demo' 'address=172.26.121.32' 'via='
INFO: zrancid-auto-yana: EXEC (dry-run): 'zrancid-add' 'sw-acc-03.demo' 'type=cisco' 'cloginrc=std-telnet.demo' 'address=172.26.121.33' 'via='
INFO: zrancid-auto-yana: EXEC (dry-run): 'zrancid-add' 'sw-acc-04.demo' 'type=cisco' 'cloginrc=std-telnet.demo' 'address=172.26.121.34' 'via='
```

### Monitoring devices missing from (z)RANCiD

Nagios plugin check_zrancid_auto_yana calls zrancid-auto-yana so that you can be alerted if a device that appears on the network is already registered in your (z)RANCiD backups:

```
rancid>  check_zrancid_auto_yana -e demo
CRITICAL: 4 missing devices: ap-opspace, ap-floor4, ap-restroom, ap-noc|missing=4
```

### Monitoring backups freshness

Nagios plugin check_zrancid_fresh checks for backups freshness. The thresholds are: warning / critical age (seconds) and minimum size (bytes) of the last backup config of devices:

```
rancid>  check_zrancid_fresh -e demo -w $((2*86400)) -c $((3*86400)) -s 32
CRITICAL: **too_old=1**, **too_small=1**, fresh=7|'too_old'=1;172800;259200 'too_small'=1;;32 'fresh'=7;;
sw-acc-01.demo: too old (crit)
sw-acc-01.demo: too small (crit)
```

### RANCiD email notifications

RANCiD sends email notification when there are changes in devices configs or when devices are added / removed. This require proper email configuration on your system. To set the destination email address or user, edit your /etc/aliases and add entries as follows:

```txt
rancid-default: zrancid@example.org
rancid-admin-default: zrancid@example.org
```

If you just want to disable email notifications, you can set the SENDMAIL variable to /bin/true in your **rancid** user's rancid.conf:

```
rancid>  echo 'export SENDMAIL=/bin/true' >> ~/etc/rancid.conf
```
