#!/bin/bash

set -e
set -x
set -o pipefail
set -u

curl -v -f "https://cf-healthcheck.${DOMAIN}/"
