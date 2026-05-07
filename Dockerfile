FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       curl \
       git \
       python3 \
       python3-pip \
       cmake \
       ninja-build \
       ccache \
       xz-utils \
       unzip \
    && rm -rf /var/lib/apt/lists/*

RUN curl -L https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo \
    && chmod +x /usr/local/bin/repo

WORKDIR /work

COPY scripts/run-standalone-build.sh /usr/local/bin/run-standalone-build.sh
RUN chmod +x /usr/local/bin/run-standalone-build.sh

ENTRYPOINT ["/usr/local/bin/run-standalone-build.sh"]
