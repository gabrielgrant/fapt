#!/bin/bash -e

curl -o /tmp/fapt-install.sh https://github.com/gabrielgrant/fapt/raw/master/fapt-install.sh
curl -o /tmp/fapt.sh https://github.com/gabrielgrant/fapt/raw/master/fapt.sh

bash /tmp/fapt-install.sh
