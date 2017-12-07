#!/usr/bin/env bash

set -e

ADAGIOS_HOST=${ADAGIOS_HOST:-localhost}
ADAGIOS_USER=${ADAGIOS_USER:-thrukadmin}
ADAGIOS_PASS=${ADAGIOS_PASS:-thrukadmin}
GIT_REPO=${GIT_REPO:-True}

# Set password if htpasswd file does not exist yet
if [[ ! -f /etc/thruk/htpasswd ]]
then
    htpasswd -c -b /etc/thruk/htpasswd "$ADAGIOS_USER" "$ADAGIOS_PASS"
	ln -s /etc/thruk/htpasswd /etc/nagios/passwd
fi

# Init git repo at /etc/nagios/
if [[ "$GIT_REPO" = "true" && ! -d /etc/nagios/.git ]]
then
    cd /etc/nagios
    echo "passwd" > .gitignore
    git init
    git add .
    git commit -m "Initial commit"
    chown -R nagios /etc/nagios/.git
fi

# Create necessary logfile structure
##touch /var/log/nagios/nagios.log
#for dir in /var/log/nagios/{archives,spool/checkresults}
#do
#    if [[ ! -d "$dir" ]]
#    then
#        mkdir -p "$dir"
#    fi
#done

# Fix permissions for nagios and pnp4nagios
chown -R nagios:nagios /etc/nagios /etc/adagios /var/lib/adagios /var/lib/pnp4nagios /var/log/pnp4nagios /var/spool/pnp4nagios /etc/pnp4nagios/process_perfdata.cfg /var/log/okconfig
# ACL group permissions need g+rwx
chmod g+rwx -R /etc/nagios /etc/adagios /var/lib/adagios /var/lib/pnp4nagios /var/log/pnp4nagios /var/spool/pnp4nagios /etc/pnp4nagios/process_perfdata.cfg /var/log/okconfig

# Execute custom init scripts
for script in $(ls -1 /opt/*.sh 2> /dev/null)
do
    [[ -x "$script" ]] && "$script"
done

exec /usr/bin/supervisord -n -c /etc/supervisord.conf
