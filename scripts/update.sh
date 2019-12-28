#!/bin/sh

set -e

git pull
$(dirname $0)/start.sh
