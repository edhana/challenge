FROM ruby:2.4
RUN gem install bundler
WORKDIR /usr/src/app
COPY Gemfile /usr/src/app
COPY Gemfile.lock /usr/src/app
RUN bundle install
    
ADD . /usr/src/app

CMD ["rspec", "spec/hparser_spec.rb"]