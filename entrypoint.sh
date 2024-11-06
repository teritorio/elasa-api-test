#!/bin/sh -l

cd /srv/app
SWAGGER_URL="$1" ONTOLOGY_URL="$2" API_URL="$3" bundle exec rake
