#!/bin/sh -l

cd /srv/app
SWAGGER_URL="$1" ONTOLOGY_URL="$2" bundle exec rake
