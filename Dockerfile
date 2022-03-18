FROM ruby:3.1

RUN mkdir -p /srv/app
COPY entrypoint.sh Gemfile Gemfile.lock Rakefile /srv/app/
COPY test /srv/app/test
RUN cd /srv/app && bundle install

ENTRYPOINT ["/srv/app/entrypoint.sh"]
