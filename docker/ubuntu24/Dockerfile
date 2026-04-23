FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      bash \
      bison \
      build-essential \
      bzip2 \
      ca-certificates \
      curl \
      file \
      flex \
      gettext \
      git \
      libicu-dev \
      libldap2-dev \
      libperl-dev \
      libreadline-dev \
      libselinux1-dev \
      libssl-dev \
      libxml2-dev \
      libxslt1-dev \
      pkg-config \
      python3-dev \
      tcl-dev \
      uuid-dev \
      xz-utils \
      zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

