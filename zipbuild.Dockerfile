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

# Precompile assets
#RUN chown -R websrv /srv/idp
#RUN su - websrv -c "ls $WORKDIR"
#RUN su - websrv -c "cd $WORKDIR && bundle exec rake assets:precompile"

# Download GeoIP datbase
#RUN mkdir ${INSTALL_DIR}/geo_data
#COPY GeoIP2-City.mmdb ${INSTALL_DIR}/geo_data/GeoLite2-City.mmdb

# Download hacked password database
RUN mkdir -p ${INSTALL_DIR}/pwned_passwords && touch ${INSTALL_DIR}/pwned_passwords/pwned_passwords.txt

# Clone identity-idp-confg
#RUN git clone git@github.com:18F/identity-idp-config.git ${INSTALL_DIR}/identity-idp-config

# Entrypoint for debugging
CMD [bash]
