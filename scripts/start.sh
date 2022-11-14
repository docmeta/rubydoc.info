#!/bin/sh

cd $(dirname $0)/..
ruby scripts/setup_host_path.rb
if [ ! -f config/certs/selfsigned-priv.pem ]; then yes '' | openssl req -x509 -nodes -days 9999 -newkey rsa:2048 -keyout config/certs/selfsigned-priv.pem -out config/certs/selfsigned-cert.pem &>/dev/null; fi
chown root:docker /var/run/docker.sock 2>/dev/null
docker swarm init 2>/dev/null
docker-compose build
docker stack deploy --resolve-image never --compose-file docker-compose.yml rubydoc
