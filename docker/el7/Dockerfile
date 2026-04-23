FROM quay.io/centos/centos:7.9.2009

RUN set -eux; \
    sed -i \
      -e 's|^mirrorlist=|#mirrorlist=|g' \
      -e 's|^#baseurl=http://mirror.centos.org/centos/$releasever|baseurl=http://vault.centos.org/7.9.2009|g' \
      /etc/yum.repos.d/CentOS-*.repo; \
    yum -y makecache fast

RUN set -eux; \
    yum -y install \
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
      libuuid-devel \
      libxml2-devel \
      libxslt-devel \
      make \
      openssl-devel \
      perl \
      perl-devel \
      perl-ExtUtils-Embed \
      readline-devel \
      tcl \
      tcl-devel \
      which \
      xz \
      zlib-devel; \
    yum clean all; \
    rm -rf /var/cache/yum

WORKDIR /workspace

