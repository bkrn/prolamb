FROM amazonlinux:2023

ARG SWIPL=9.2.0
ARG SWIPL_CHECKSUM=10d90b15734d14d0d7972dc11a3584defd300d65a9f0b1185821af8c3896da5e

WORKDIR /build

VOLUME /dist

RUN dnf install -y \
  gcc \
  gcc-c++ \
  tar \
  gzip \
  cmake \
  ninja-build \
  libunwind \
  gperftools-devel \
  freetype-devel \
  gmp-devel \
  jpackage-utils \
  libICE-devel \
  libjpeg-turbo-devel \
  libSM-devel \
  ncurses-devel \
  openssl-devel \
  pkgconfig \
  readline-devel \
  libedit-devel \
  zlib-devel \
  uuid-devel \
  libarchive-devel \
  libyaml-devel &> /dev/null

# Build swipl
RUN mkdir -p /var/task && \
    curl https://www.swi-prolog.org/download/stable/src/swipl-${SWIPL}.tar.gz -o swipl-${SWIPL}.tar.gz &> /dev/null && \
    SUM=$(sha256sum swipl-${SWIPL}.tar.gz | cut -d ' ' -f 1) && \
    [ ${SUM} = ${SWIPL_CHECKSUM} ] && \
    tar xfz swipl-${SWIPL}.tar.gz > /dev/null && \
    cd swipl-${SWIPL} && \
    echo "SWIPL cmake" && \
    cmake \
        -DCMAKE_INSTALL_PREFIX=/var/task \
        -DSWIPL_PACKAGES_PCRE=OFF \
        -DSWIPL_PACKAGES_ODBC=OFF \
        -DSWIPL_PACKAGES_JAVA=OFF \
        -DSWIPL_PACKAGES_X=OFF \
        -DUSE_TCMALLOC=OFF \
        -DSWIPL_SHARED_LIB=OFF \
        -DBUILD_TESTING=OFF \
        -DINSTALL_TESTS=OFF \
        -DINSTALL_DOCUMENTATION=OFF &> /dev/null && \
    echo "SWIPL make" && \
    make > /dev/null && \
    echo "SWIPL make install" && \
    make install > /dev/null && \
    cd .. && rm -rf * > /dev/null && \
    rm -rf /var/task/bin > /dev/null && \
    rm -rf /var/task/share > /dev/null

RUN dnf clean all

COPY build.sh /var/task/
COPY prolamb.pl /var/task/
RUN mv /var/task/prolamb.pl /var/task/bootstrap && chmod 777 /var/task/bootstrap

WORKDIR /var/task

CMD ["./build.sh"]