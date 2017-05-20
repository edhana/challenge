FROM ruby:2.4
WORKDIR /usr/src/app
COPY Gemfile /usr/src/app
COPY Gemfile.lock /usr/src/app
    
ADD . /usr/src/app

CMD ["rspec", "spec/hparser_spec.rb"]