# mxabierto mxabierto/edca
# https://github.com/mxabierto/edca
# Build:
#   docker build -t mxabierto/edca .
# Usage:
#   docker run \
#   --link mongodb-container:mongodb \
#   --link postgres-container:postgres \
#   --name edca \
#   -dP mxabierto/edca

FROM alpine:3.4

MAINTAINER bcessa <ben@datos.mx>

WORKDIR /edca

ADD . /edca

# Install nodejs
RUN \
  apk add nodejs --update-cache && \
  npm install -g npm@latest && \
  rm -rf \
    /usr/share/man \
    /tmp/* \
    /var/cache/apk/* \
    /root/.npm \
    /root/.node-gyp \
    /usr/lib/node_modules/npm/man \
    /usr/lib/node_modules/npm/doc \
    /usr/lib/node_modules/npm/html

# Install dependencies
RUN \
  apk --no-cache add \
    libc6-compat \
    git

# Install NPM modules and bower components
RUN \
  npm install --no-optional && \
  npm install -g bower && \
  cd public && \
  bower --allow-root install

# Expose default connection port
ENV PORT 3000
EXPOSE ${PORT}

# Default to running the www command
ENTRYPOINT ["/edca/bin/www"]
