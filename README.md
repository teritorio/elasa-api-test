# Run

Validate Elasa API return.


## Directly

Install
```
bundle install
```

Run
```
SWAGGER_URL=https://dev.appcarto.teritorio.xyz/content/wp-content/plugins/ApiTeritorio/swagger-doc.yaml ONTOLOGY_URL=https://vecto-dev.teritorio.xyz/data/teritorio-tourism-ontology-dev.json bundle exec rake
# or
SWAGGER_URL=https://dev.appcarto.teritorio.xyz/content/wp-content/plugins/ApiTeritorio/swagger-doc.yaml ONTOLOGY_URL=https://vecto-dev.teritorio.xyz/data/teritorio-tourism-ontology-dev.json bundle exec ruby -Ilib:test test/api/validate_swagger_spec.rb
```

## Using Docker

Build
```
docker build -t elasa-api-test .
```

Run
```
docker run --rm -v `pwd`/test:/srv/app/test elasa-api-test https://dev.appcarto.teritorio.xyz/content/wp-content/plugins/ApiTeritorio/swagger-doc.yaml https://vecto-dev.teritorio.xyz/data/teritorio-tourism-ontology-dev.json
```
