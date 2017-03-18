#!/bin/bash

touch /etc/rsyncd.secrets
chmod 0400 /etc/rsyncd.secrets

cat << __EOF__ > /etc/rsyncd.conf
# GLOBAL OPTIONS
uid = root
gid = root
use chroot = true
pid file = /var/run/rsyncd.pid
log file = /dev/stdout
timeout = $RSYNC_TIMEOUT
max connections = $RSYNC_MAX_CONNECTIONS
port = $RSYNC_PORT
__EOF__

for name in $(env | grep ".*_NAME.*"); do
    prefix=$(echo "$name" | cut -d '_' -f 1)

    name_var=$prefix"_NAME"
    uid_var=$prefix"_UID"
    gid_var=$prefix"_GID"
    allow_var=$prefix"_ALLOW"
    readonly_var=$prefix"_READ_ONLY"
    vol_var=$prefix"_VOLUME"
    user_var=$prefix"_USERNAME"
    pw_var=$prefix"_PASSWORD"
    exclude_var=$prefix"_EXCLUDE"

    rs_name=${!name_var}
    rs_uid=${!uid_var}
    rs_gid=${!gid_var}
    rs_allow=${!allow_var}
    rs_readonly=${!readonly_var}
    rs_vol=${!vol_var}
    rs_user=${!user_var}
    rs_pw=${!pw_var}
    rs_exclude=${!exclude_var}

    : ${rs_uid:=root}
    : ${rs_gid:=root}
    : ${rs_readonly:=true}
    : ${rs_vol:=$VOL}
    : ${rs_user:=$RSYNC_USERNAME}
    : ${rs_pw:=$RSYNC_PASSWORD}

    echo $rs_name $rs_uid $rs_gid $rs_allow $rs_readonly $rs_vol $rs_user $rs_pw $rs_exclude

    cat << __EOF__ >> /etc/rsyncd.conf

# MODULE OPTIONS
[$rs_name]
    uid = $rs_uid
    gid = $rs_gid
    read only = $rs_readonly
    path = $rs_vol
    comment = $rs_name
    lock file = /var/lock/rsyncd
    list = yes
    ignore errors = no
    ignore nonreadable = yes
    transfer logging = yes
    log format = %t: host %h (%a) %o %f (%l bytes). Total %b bytes.
    refuse options = checksum dry-run
    dont compress = *.gz *.tgz *.zip *.z *.rpm *.deb *.iso *.bz2 *.tbz
    exclude from = /etc/rsyncd.excludes
    secrets file = /etc/rsyncd.secrets
__EOF__

    cat << __EOF__ >> /etc/rsyncd.excludes
$rs_exclude
*.!sync
*.swp
__EOF__

    if [ ! $rs_user = "" ]; then
        echo "    auth users = $rs_user" >> /etc/rsyncd.conf
        echo "$rs_user:$rs_pw" >> /etc/rsyncd.secrets
    fi
    if [ ! $rs_allow = "" ]; then
        echo "    hosts deny = *" >> /etc/rsyncd.conf
        echo "    hosts allow = $rs_allow" >> /etc/rsyncd.conf
    fi
done

exec /usr/bin/rsync --no-detach --daemon --config /etc/rsyncd.conf "$@"