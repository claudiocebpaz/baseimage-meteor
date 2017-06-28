###
# From phusion/baseimage: https://github.com/phusion/baseimage-docker
# Look for newer releases: https://github.com/phusion/baseimage-docker/releases
###
FROM phusion/baseimage:0.9.22
MAINTAINER Martin Bucko <bucko@treecom.net>
LABEL name="baseimage-meteor" version="0.1"

# You can owerwrite ENVs from docker files or docker-compose
ENV ROOT_URL http://localhost/ \
  PORT 80 \
  METEOR_SETTINGS {} \
  MONGO_URL mongodb://mongodb/meteor \
  MONGO_OPLOG_URL mongodb://mongodb/local \
  MAIL_URL smtp://user:password@mailhost:port/

# Expose port
EXPOSE 80/tcp

# Copy Meteor folder
COPY . /build

# Install things and Meteor
RUN \
  if [ -d /build/.meteor/service ]; then cp -R /build/.meteor/service/* /etc/service; fi \
  && adduser --system --group meteor --home /home/meteor \
  && apt-get update \
  && apt-get upgrade -y -o Dpkg::Options::="--force-confold" \
  && apt-get --yes install git curl python build-essential \
  && curl https://install.meteor.com/ | sed s/--progress-bar/-sL/g | sh  \
  && export "NODE=$(find ~/.meteor/ -path '*bin/node' | grep '.meteor/packages/meteor-tool/' | sort | head -n 1)" \
  && ln -sf ${NODE} /usr/local/bin/node  \
  && echo "$(dirname $(dirname "$NODE"))/lib/node_modules" > /etc/container_environment/NODE_PATH

# Build APP
ONBUILD RUN \
  cd /build \
  && if [ -f package.json ]; then meteor npm install; fi \
  && meteor build --directory / --architecture=os.linux.x86_64 --server-only --allow-superuser \
  && rm -rf /build \
  && echo "ls /bundle" \
  && ls /bundle \
  && chown meteor:meteor -Rh /bundle ~/.meteor \
  && apt-get --yes purge git curl \
  && apt-get --yes autoremove \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# init baseimage services
CMD ["/sbin/my_init"]
