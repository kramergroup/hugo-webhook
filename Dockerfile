FROM debian:stretch

# Install pygments (for syntax highlighting) 
RUN echo "deb http://ftp.us.debian.org/debian testing main contrib non-free" > /etc/apt/sources.list.d/testing.list \
  && apt-get -qq update \
	&& DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends libstdc++6 python-pygments git ca-certificates asciidoc curl supervisor git/testing ssh webhook \
	&& rm -rf /var/lib/apt/lists/*

# Configuration variables
ENV HUGO_VERSION 0.55.3
ENV HUGO_BINARY hugo_extended_${HUGO_VERSION}_Linux-64bit.deb

ENV GIT_REPO_CONTENT_PATH ''
ENV GIT_REPO_BRANCH 'master'
ENV TARGET_DIR '/target'

ENV GIT_SSH_ID_FILE '/ssh/id_rsa'

# Download and install hugo
RUN curl -sL -o /tmp/hugo.deb \
    https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/${HUGO_BINARY} && \
    dpkg -i /tmp/hugo.deb && \
    rm /tmp/hugo.deb

WORKDIR /tmp

# Expose default webhook port
EXPOSE 9000

COPY supervisord.conf /etc/supervisord.conf
COPY hooks.json /etc/hooks.json

COPY scripts /scripts

ENTRYPOINT [ "/usr/bin/supervisord", "-c", "/etc/supervisord.conf" ]