#!/bin/sh

rm /var/run/docker.pid
dockerd &>/var/log/docker.log &

tries=0
d_timeout=60
until docker info >/dev/null 2>&1
do
	if [ "$tries" -gt "$d_timeout" ]; then
    cat /var/log/docker.log
		echo 'Timed out trying to connect to internal docker host.' >&2
		exit 1
	fi
  tries=$(( $tries + 1 ))
	sleep 1
done

docker pull docmeta/rubydoc.info:docparse
cron
su app sh -c 'bundle exec rake gems:update server:start'
