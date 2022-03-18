#!/bin/sh -l

cd /srv/app
SWAGGER_URL="$1" bundle exec rake
