FROM rockylinux:8

RUN dnf -y install dnf-plugins-core epel-release && \
    dnf config-manager --set-enabled powertools && \
    dnf -y install \
      bison \
      bzip2 \
      ca-certificates \
      curl \
      file \
      flex \
      gcc \
      gcc-c++ \
      gettext \
      git \
      glibc-langpack-en \
      libicu-devel \
      libselinux-devel \
      libuuid-devel \
      libxml2-devel \
      libxslt-devel \
      make \
      openldap-devel \
      openssl-devel \
      perl-devel \
      perl-ExtUtils-Embed \
      python3-devel \
      readline-devel \
      tcl-devel \
      which \
      xz \
      zlib-devel && \
    dnf clean all

WORKDIR /workspace

