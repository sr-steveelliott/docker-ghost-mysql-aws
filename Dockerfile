# http://support.ghost.org/supported-node-versions/
# https://github.com/nodejs/LTS
FROM node:6

# grab su-exec for easy step-down from root
RUN apk add --no-cache 'su-exec>=0.2'

RUN apk add --no-cache \
# add "bash" for "[["
		bash \
# add "tar" for "--one-file-system"
		tar

ENV GHOST_SOURCE /usr/src/ghost
WORKDIR $GHOST_SOURCE

ENV GHOST_VERSION 0.11.9

RUN set -ex; \
	\
	apk add --no-cache --virtual .build-deps \
		ca-certificates \
		gcc \
		make \
		openssl \
		python \
		unzip \
	; \
	\
	wget -O ghost.zip "https://github.com/TryGhost/Ghost/releases/download/${GHOST_VERSION}/Ghost-${GHOST_VERSION}.zip"; \
	unzip ghost.zip; \
	\
	npm install --production; \
	\
	apk del .build-deps; \
	\
	rm ghost.zip; \
	npm cache clean; \
	rm -rf /tmp/npm*

ENV GHOST_CONTENT /var/lib/ghost
RUN mkdir -p "$GHOST_CONTENT" \
	&& chown -R node:node "$GHOST_CONTENT" \
# Ghost expects "config.js" to be in $GHOST_SOURCE, but it's more useful for
# image users to manage that as part of their $GHOST_CONTENT volume, so we
# symlink.
	&& ln -s "$GHOST_CONTENT/config.js" "$GHOST_SOURCE/config.js"
VOLUME $GHOST_CONTENT

COPY docker-entrypoint.sh /usr/local/bin/

COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod u+x /entrypoint.sh \
  && mkdir -p /usr/src/ghost/content/storage \
  && npm install ghost-s3-compat \
  && npm install lodash.assign \
  && cp -r /usr/src/ghost/node_modules/ghost-s3-compat /usr/src/ghost/content/storage/ghost-s3

COPY config.js /config-example.js

ENTRYPOINT ["/entrypoint.sh"]

CMD ["npm", "start", "--production"]
