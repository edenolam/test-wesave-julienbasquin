FROM ruby:3.3
WORKDIR /app
COPY Gemfile Gemfile.lock* ./
RUN bundle install
COPY . .
EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
