FROM rockylinux:8

RUN set -eux; \
    dnf -y update; \
    dnf -y install dnf-plugins-core; \
    dnf clean all

RUN set -eux; \
    dnf config-manager --set-enabled powertools || \
    dnf config-manager --set-enabled PowerTools || true; \
    dnf repolist all

RUN set -eux; \
    dnf -y install \
      bison \
      bzip2 \
      ca-certificates \
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
      perl \
      perl-devel \
      perl-ExtUtils-Embed \
      python3 \
      python3-devel \
      readline-devel \
      tcl \
      tcl-devel \
      which \
      xz \
      zlib-devel; \
    dnf clean all; \
    rm -rf /var/cache/dnf

WORKDIR /workspace
