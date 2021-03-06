FROM alpine:3.5

RUN apk add --no-cache \
    git \
    subversion \
    bash \
    python \
    make \
    g++ \
    nodejs \
    php5-cli \
    curl \
    jq

RUN npm set progress=false \
    && npm install -g grunt yarn phantomjs

COPY build-wp.sh /bin/build-wp

RUN chmod +x /bin/build-wp

COPY files/composer.json /var/composer.json

ENV GITHUB_AUTH_USER=""
ENV GITHUB_AUTH_PW=""

ENTRYPOINT ["/bin/build-wp"]
