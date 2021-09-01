#!/bin/bash

yunobin=$(which yunohost)

if [ "$1" == "yunohost.users.discover" ];then
	users=$($yunobin user list --fields 'uid' | awk -F ': ' '/username: / {print $2}');echo -n "{\"data\":[";for user in $users;do echo -n "{\"{#USERNAME}\":\"$user\"},";done | sed 's/,$//' ;echo "]}"
fi

if [ "$1" == "yunohost.user.quota" ] ;then
	quota=$($yunobin user info "$2" | grep -Po "use:.*\(\K([0-9]{1,3})");if [ -z "$quota" ];then echo 0 ; else echo "$quota" ;fi
fi

if [ "$1" == "yunohost.domains.discover" ] ;then
	domains=$($yunobin domain list --output-as plain);echo -n "{\"data\":[";for domain in $domains;do echo -n "{\"{#DOMAIN}\":\"$domain\"},";done | sed 's/,$//' ;echo "]}"
fi

if [ "$1" == "yunohost.domain.cert" ] ;then
	$yunobin domain cert-status "$2" --output-as plain --full| awk '/#/{ next;} {printf "%s;",$0} END {print ""}'
fi

if [ "$1" == "yunohost.services.discover" ] ;then
	services=$($yunobin service status 2>/dev/null| grep -Po '^([A-Za-z]+)(?=(:))');echo -n "{\"data\":[";for service in $services;do echo -n "{\"{#SERVICE}\":\"$service\"},";done | sed 's/,$//' ;echo "]}"
fi

if [ "$1" == "yunohost.service.status" ] ;then
	service=$($yunobin service status "$2" --output-as json 2>/dev/null)
	if [[ "$(echo $service | jq -r '.description')" == *"doesn't exists for systemd"* ]] ;then
		echo "$service" | jq -c '.active = "disabled"' 
	else
		echo "$service"
	fi
fi

if [ "$1" == "yunohost.backups.number" ] ;then
	$yunobin backup list --output-as plain | wc -l
fi

if [ "$1" == "yunohost.backups.ageoflastbackup" ] ;then
	if [ $($yunobin backup list --output-as plain | wc -l) -ne 0 ] ;then
		timestamp=$(date +"%F %R" -d"$($yunobin backup list -i | tail -n 4 | head -n 1 | grep -Po 'created_at: \K(.*)')")
		echo $(( ($(date +%s) - $(date -d"$timestamp" +%s))/(60*60*24) ))
	else
		echo "No backup detected"
	fi
fi

if [ "$1" == "yunohost.ports.tcp.discovery" ] ;then
	ports=$($yunobin  firewall list -r --output-as plain | awk '/#ipv4/{flag=1;next}/#uPnP/{flag=0}flag' | awk '/##TCP/{flag=1;next}/##TCP/{flag=0}flag');echo -n "{\"data\":[";for port in $ports;do echo -n "{\"{#PORT}\":\"$port\"},";done | sed 's/,$//' ;echo "]}"
fi

if [ "$1" == "yunohost.ports.udp.discovery" ] ;then
	ports=$($yunobin  firewall list -r --output-as plain | awk '/#ipv4/{flag=1;next}/#uPnP/{flag=0}flag' | awk '/##UDP/{flag=1;next}/##TCP/{flag=0}flag');echo -n "{\"data\":[";for port in $ports;do echo -n "{\"{#PORT}\":\"$port\"},";done | sed 's/,$//' ;echo "]}"
fi

if [ "$1" == "yunohost.migrations.lastinstalled" ] ;then
	$yunobin tools migrations state | grep -Po " number: \K(.*)"
fi

if [ "$1" == "yunohost.migrations.lastavailable" ] ;then
	$yunobin tools migrations list | tail -n 1 | grep -Po " number: \K(.*)"
fi
