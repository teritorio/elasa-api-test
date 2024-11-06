FROM ruby:3.1

RUN mkdir -p /srv/app
WORKDIR /srv/app
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY entrypoint.sh Gemfile Gemfile.lock Rakefile test ./

ENTRYPOINT ["/srv/app/entrypoint.sh"]
