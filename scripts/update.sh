#!/bin/sh

set -e

git pull
docker-compose build
docker-compose restart app
