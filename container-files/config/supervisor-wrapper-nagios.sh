#!/usr/bin/env bash
#
# - Adagios uses this wrapper to control Nagios services (start/stop/reload)
# - Remember to change nagios_init_script variable inside /etc/adagios/adagios.conf
# - sed -i 's|^\(nagios_init_script\)=\(.*\)$|\1="sudo /config/supervisor-nagios-wrapper.sh"|g' /etc/adagios/adagios.conf
#
if [[ "$1" = "status" ]]
then
  # Return 1 if Nagios is not running
  status=$(supervisorctl status nagios)
  echo $status
  grep RUNNING > /dev/null <<< "$status"
else
  supervisorctl "$1" nagios
fi
