FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       curl \
       wget \
       git \
       git-core \
       git-lfs \
       gnupg \
       flex \
       bison \
       gperf \
       build-essential \
       zip \
       zlib1g-dev \
       gcc-multilib \
       g++-multilib \
       libc6-dev-i386 \
       lib32z1-dev \
       libgl1-mesa-dev \
       libxml2-utils \
       xsltproc \
       m4 \
       bc \
       gnutls-bin \
       python3 \
       python3-pip \
       python3-distutils \
       python-is-python3 \
       ruby \
       genext2fs \
       device-tree-compiler \
       cmake \
       ninja-build \
       make \
       libffi-dev \
       e2fsprogs \
       pkg-config \
       perl \
       openssl \
       libssl-dev \
       libelf-dev \
       libdwarf-dev \
       u-boot-tools \
       mtd-utils \
       cpio \
       doxygen \
       liblz4-tool \
       default-jre \
       default-jdk \
       texinfo \
       dosfstools \
       mtools \
       apt-utils \
       scons \
       rsync \
       libxml2-dev \
       xxd \
       libglib2.0-dev \
       libpixman-1-dev \
       kmod \
       jfsutils \
       reiserfsprogs \
       xfsprogs \
       squashfs-tools \
       pcmciautils \
       quota \
       ppp \
       libtinfo-dev \
       libncurses5-dev \
       libstdc++6 \
       gcc-arm-none-eabi \
       vim \
       ssh \
       locales \
       libxinerama-dev \
       libxcursor-dev \
       libxrandr-dev \
       libxi-dev \
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
