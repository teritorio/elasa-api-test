# Run

Validate Elasa API return.


## Directly

Install
```
bundle install
```

Run
```
SWAGGER_URL=https://elasa-dev.teritorio.xyz/static/elasa-0.1.swagger.yaml ONTOLOGY_URL=https://teritorio.github.io/ontology-builder/teritorio-tourism-ontology-1.0.json bundle exec rake
# or
SWAGGER_URL=https://elasa-dev.teritorio.xyz/static/elasa-0.1.swagger.yaml ONTOLOGY_URL=https://teritorio.github.io/ontology-builder/teritorio-tourism-ontology-1.0.json bundle exec ruby -Ilib:test test/api/validate_swagger_spec.rb
```

## Using Docker

Build
```
docker build -t elasa-api-test .
```

Run
```
docker run --rm -v `pwd`/test:/srv/app/test elasa-api-test https://elasa-dev.teritorio.xyz/static/elasa-0.1.swagger.yaml https://teritorio.github.io/ontology-builder/teritorio-tourism-ontology-1.0.json
```
