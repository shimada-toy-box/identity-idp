FROM amazonlinux:latest

RUN amazon-linux-extras install ruby2.6
# FIPS note - AmazonLinux2 provides openssl 1.0.2k-fips
RUN yum install -y gcc-c++ make ruby-devel git openssl openssl-devel \
    postgresql-devel
# Things we may not need - Try without later
RUN yum install -y readline-devel zlib-devel libyaml-devel libxml2-devel sqlite-devel

# Requirements to build static assets
RUN curl -sL https://rpm.nodesource.com/setup_12.x | bash -
RUN curl -sL https://dl.yarnpkg.com/rpm/yarn.repo -o /etc/yum.repos.d/yarn.repo
RUN yum install -y nodejs yarn

WORKDIR /srv/idp/current
ENV BUNDLE_DIR /srv/idp/shared
ENV INSTALL_DIR /srv/idp/current

COPY . /srv/idp/current/

# Install production Gems
RUN gem install bundler -v 1.17.3
RUN bundle config build.nokogiri --use-system-libraries
RUN bundle install --deployment --path "$BUNDLE_DIR/bundle" --binstubs "$BUNDLE_DIR/bin" --without 'deploy development doc test'

# Install NodeJS and Yarn and production packages
COPY package.json yarn.lock ./
RUN NODE_ENV=production yarn install --force \
    && bundle exec yarn install

# Doesn't necessarily have to be this user.  Just cannot be root
RUN adduser websrv

RUN ln -s /srv/idp/current/config/application.yml.default /srv/idp/current/config/application.yml
RUN ln -s /srv/idp/current/config/service_providers.localdev.yml /srv/idp/current/config/service_providers.yml
RUN ln -s /srv/idp/current/config/agencies.localdev.yml /srv/idp/current/config/agencies.yml
RUN ln -s keys.example keys
RUN ln -s certs.example certs
RUN mkdir log
RUN touch log/telephony.log && chmod 777 log/telephony.log
RUN touch log/development.log && chmod 777 log/development.log
RUN touch log/production.log && chmod 777 log/production.log
RUN touch log/newrelic_agent.log && chmod 777 log/newrelic_agent.log
RUN touch /srv/idp/current/yarn-error.log && chmod 777 /srv/idp/current/yarn-error.log
RUN touch /srv/idp/current/node_modules/.yarn-integrity && chmod 777 /srv/idp/current/node_modules/.yarn-integrity

RUN export RAILS_ENV=production
RUN export piv_cac_verify_token_url="https://foo"
RUN export secret_key_base=foo
RUN export saml_endpoint_configs='[{"suffix":"2019","secret_key_passphrase":"trust-but-verify"},{"suffix":"2018","secret_key_passphrase":"asdf1234"},{"suffix":"2020","secret_key_passphrase":"trust-but-verify"}]'

# Current error
# info "fsevents@1.2.13" is an optional dependency and failed compatibility check. Excluding it from installation.
# error An unexpected error occurred: "EACCES: permission denied, unlink '/srv/idp/current/node_modules/.yarn-integrity'".
# Precompile assets
RUN chown -R websrv /srv/idp
RUN su - websrv -c "ls /srv/idp/current"
RUN su - websrv -c "cd /srv/idp/current && bundle exec rake assets:precompile"

# Download GeoIP datbase
#RUN mkdir ${INSTALL_DIR}/geo_data
#COPY GeoIP2-City.mmdb ${INSTALL_DIR}/geo_data/GeoLite2-City.mmdb

# Download hacked password database
RUN mkdir -p ${INSTALL_DIR}/pwned_passwords && touch ${INSTALL_DIR}/pwned_passwords/pwned_passwords.txt

# Clone identity-idp-confg
#RUN git clone git@github.com:18F/identity-idp-config.git ${INSTALL_DIR}/identity-idp-config

# Entrypoint for debugging
CMD [bash]
