FROM registry.access.redhat.com/rhel7/rhel-atomic

# This image provides a Node.JS environment you can use to run your Node.JS
# applications.

EXPOSE 8080

# This image will be initialized with "npm run $NPM_RUN"
# See https://docs.npmjs.com/misc/scripts, and your repo's package.json
# file for possible values of NPM_RUN
ENV HOME=/opt/app-root/src \
    NPM_RUN=start \
    NODE_VERSION= \
    NPM_VERSION= \
    V8_VERSION= \
    NODE_LTS= \
    NPM_CONFIG_LOGLEVEL=info \
    NPM_CONFIG_PREFIX=$HOME/.npm-global \
    PATH=$HOME/bin:$HOME/../bin:$HOME/node_modules/.bin/:$HOME/.npm-global/bin/:$PATH \
    DEBUG_PORT=5858 \
    NODE_ENV=production \
    DEV_MODE=false \
    STI_SCRIPTS_PATH=/usr/libexec/s2i

LABEL io.k8s.description="Platform for building and running Node.js applications" \
      io.k8s.display-name="Node.js $NODE_VERSION" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,nodejs,nodejs-$NODE_VERSION" \
      io.openshift.s2i.scripts-url="image:///usr/libexec/s2i" \
      com.redhat.deployments-dir=${HOME} \
      maintainer="Lance Ball <lball@redhat.com>"

# Download and install a binary from nodejs.org
# Add the gpg keys listed at https://github.com/nodejs/node
RUN set -ex && \
  echo "default:x:1001:0:Default application user:/opt/app-root/src:/bin/bash" | cat >> /etc/passwd && \
  mkdir -p ${HOME} && \
  cd ${HOME} && \
  chown -R 1001:0 /opt/app-root && \
#   for key in \
#     9554F04D7259F04124DE6B476D5A82AC7E37093B \
#     94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
#     0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
#     FD3A5288F042B6850C66B31F09FE44734EB7990E \
#     71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
#     DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
#     B9AE9905FFD7803F25714661B63B535A4C206CA9 \
#     C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
#   ; do \
#     gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
#   done && \
  curl -OL ftp://fr2.rpmfind.net/linux/centos/7/os/x86_64/Packages/tar-1.26-31.el7.x86_64.rpm && \
  rpm -i tar-1.26-31.el7.x86_64.rpm && \
  rm tar-1.26-31.el7.x86_64.rpm && \
  curl -OL ftp://fr2.rpmfind.net/linux/centos/7/os/x86_64/Packages/gzip-1.5-8.el7.x86_64.rpm && \
  rpm -i gzip-1.5-8.el7.x86_64.rpm && \
  rm gzip-1.5-8.el7.x86_64.rpm && \
  curl -o node-${NODE_VERSION}-linux-x64.tar.gz -sSL https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.gz && \
  curl -o SHASUMS256.txt.asc -sSL https://nodejs.org/dist/${NODE_VERSION}/SHASUMS256.txt.asc && \
#   gpg --batch -d SHASUMS256.txt.asc | grep " node-${NODE_VERSION}-linux-x64.tar.gz\$" | sha256sum -c - && \
  tar -zxf node-${NODE_VERSION}-linux-x64.tar.gz -C /usr/local --strip-components=1 && \
  npm install -g npm@${NPM_VERSION} && \
  find /usr/local/lib/node_modules/npm -name test -o -name .bin -type d | xargs rm -rf; \
  rm -rf ~/node-${NODE_VERSION}-linux-x64.tar.gz ~/SHASUMS256.txt.asc /tmp/node-${NODE_VERSION} ~/.npm ~/.node-gyp ~/.gnupg \
    /usr/share/man /tmp/* /usr/local/lib/node_modules/npm/man /usr/local/lib/node_modules/npm/doc /usr/local/lib/node_modules/npm/html && \
  rpm -e gzip-1.5-8.el7.x86_64


USER 1001

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/ $STI_SCRIPTS_PATH

# Each language image can have 'contrib' a directory with extra files needed to
# run and build the applications.
COPY ./contrib/ /opt/app-root

# Set the default CMD to print the usage of the language image
CMD $STI_SCRIPTS_PATH/usage
