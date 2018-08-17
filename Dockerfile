FROM ruby:2.4
RUN mkdir -p /srv/cloudformation_demo
RUN mkdir -p /srv/cloudformation_demo/tmp/pids
RUN mkdir -p /srv/cloudformation_demo/tmp/sockets
WORKDIR /srv/cloudformation_demo
RUN apt-get update && apt-get install -y apt-utils nginx nodejs postgresql-client sqlite vim --no-install-recommends && rm -rf /var/lib/apt/lists/*
RUN rm -f /etc/nginx/sites-enabled/default
COPY ./templates/sites-available/default /etc/nginx/sites-available/default
RUN ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
ENV RAILS_ENV production
ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_LOG_TO_STDOUT true
ENV BIND unix:///srv/cloudformation_demo/tmp/sockets/puma.sock
ENV WORKERS 2
ENV PIDFILE /var/run/puma.pid
COPY Gemfile /srv/cloudformation_demo
COPY Gemfile.lock /srv/cloudformation_demo
RUN bundle config --global frozen 1
RUN bundle install --without development test
COPY . /srv/cloudformation_demo
RUN bundle exec rake assets:precompile
RUN bundle exec rake db:setup
CMD service nginx start && bin/bundle exec pumactl -F config/puma.rb start
