FROM golang:alpine3.13 as builder


ENV WEBHOOK_VERSION 2.8.0

WORKDIR /go/src/github.com/adnanh/webhook
## The released github webhook binary miserably failed to run on alpine go we have to build it. 
RUN apk add --no-cache --update -t build-deps curl go git gcc libc-dev libgcc upx && \
    curl -sSf -L https://github.com/adnanh/webhook/archive/${WEBHOOK_VERSION}.tar.gz -o webhook.tgz && \
    tar --strip 1 -xzf webhook.tgz && \
    go get -d && \
    env GOOS=linux GARCH=amd64 CGO_ENABLED=0 go build -v -a -installsuffix cgo -o /usr/local/bin/webhook && \
    upx -8 /usr/local/bin/webhook && \
    apk del --purge build-deps && \
    rm -rf /var/cache/apk/* && rm -rf /go 

FROM alpine:3.13

ENV DOCKER_HUGO_VERSION="0.80.0"
ENV DOCKER_HUGO_NAME="hugo_extended_${DOCKER_HUGO_VERSION}_Linux-64bit"
ENV DOCKER_HUGO_BASE_URL="https://github.com/gohugoio/hugo/releases/download"
ENV DOCKER_HUGO_URL="${DOCKER_HUGO_BASE_URL}/v${DOCKER_HUGO_VERSION}/${DOCKER_HUGO_NAME}.tar.gz"


# Configuration variables
ENV GIT_REPO_CONTENT_PATH ''
ENV GIT_CLONE_DEST '/srv/src'
ENV GIT_USERNAME 'foo_user'
ENV GIT_REPO_BRANCH 'master'
ENV GIT_SSH_ID_FILE '/ssh/id_rsa'
ENV HUGO_TARGET_DIR '/srv/static'



## The github released hugo-extended (with sass templating and extras) binary worked on alpine but
## it required libc6-compat and libstdc++
RUN apk add --update --no-cache --virtual .build-deps wget upx && \
    apk add --update --no-cache git openssh ca-certificates libc6-compat libstdc++ && \
    wget -qO- "${DOCKER_HUGO_URL}" | tar x -vzf- -C /usr/local/bin hugo && \
    addgroup -S app && adduser -S -G app app && \
    mkdir -p ${HUGO_TARGET_DIR} && chown app ${HUGO_TARGET_DIR}  && chmod 755 ${HUGO_TARGET_DIR} && \
    upx -8 /usr/local/bin/hugo && \
    apk del .build-deps && \
    rm -rf /var/cache/apk/* && \
    mkdir /etc/webhook

WORKDIR /tmp

# Expose default webhook port
EXPOSE 9000
EXPOSE 80

COPY hooks.json /etc/webhook/hooks.json
COPY scripts /scripts
COPY --from=builder /usr/local/bin/webhook /usr/local/bin/webhook
USER app
ENTRYPOINT ["/usr/local/bin/webhook", "-verbose", "-debug", "-hooks", "/etc/webhook/hooks.json"]