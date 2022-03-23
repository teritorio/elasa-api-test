FROM ruby:3.1

RUN mkdir -p /srv/app
COPY entrypoint.sh Gemfile Gemfile.lock Rakefile /srv/app/
COPY Gemfile Gemfile.lock /srv/app/test/
RUN cd /srv/app && bundle install
COPY test /srv/app/test

ENTRYPOINT ["/srv/app/entrypoint.sh"]
