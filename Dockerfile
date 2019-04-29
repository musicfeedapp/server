FROM rails:latest

WORKDIR /app

RUN apt-get update
RUN apt-get install -y tmux

RUN gem install bundler --no-ri --no-rdoc

RUN bundle config git.allow_insecure true
RUN bundle config path /app/vendor
RUN bundle config bin /app/vendor/ruby/2.3.0/bin/
