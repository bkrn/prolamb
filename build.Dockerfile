FROM amazonlinux:2023

ARG SWIPL=9.2.0
ARG SWIPL_CHECKSUM=10d90b15734d14d0d7972dc11a3584defd300d65a9f0b1185821af8c3896da5e

ARG PG_ODBC_VERSION=10.03.0000
ARG SF_ODBC_VERSION=2.22.5
ARG SF_ODBC=true
ARG PG_ODBC=true

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

# Install postgres to build odbc driver
RUN [ "${PG_ODBC}" = "true" ] || [ "${SF_ODBC}" = "true" ] && \
  echo "Install ODBC and postgres libs" && \
  mkdir -p /var/task && mkdir -p /var/task/lib && \
  dnf install -y \
  unixODBC \
  unixODBC-devel \
  libpq-devel \
  postgresql-devel &> /dev/null && \
  cp /usr/lib64/libodbc.so.2 /var/task/lib && \
  cp /usr/lib64/libpq.so.5 /var/task/lib && \
  cp /usr/lib64/libodbcinst.so.2 /var/task/lib || echo "Skipping ODBC"

# Build swipl
RUN curl https://www.swi-prolog.org/download/stable/src/swipl-${SWIPL}.tar.gz -o swipl-${SWIPL}.tar.gz &> /dev/null && \
    SUM=$(sha256sum swipl-${SWIPL}.tar.gz | cut -d ' ' -f 1) && \
    [ ${SUM} = ${SWIPL_CHECKSUM} ] && \
    tar xfz swipl-${SWIPL}.tar.gz &> /dev/null && \
    cd swipl-${SWIPL} && \
    echo "SWIPL cmake" && \
    cmake \
        -DCMAKE_INSTALL_PREFIX=/var/task \
        -DSWIPL_PACKAGES_PCRE=OFF \
        -DSWIPL_PACKAGES_JAVA=OFF \
        -DSWIPL_PACKAGES_X=OFF \
        -DUSE_TCMALLOC=OFF \
        -DSWIPL_SHARED_LIB=OFF \
        -DBUILD_TESTING=OFF \
        -DINSTALL_TESTS=OFF \
        -DINSTALL_DOCUMENTATION=OFF &> /dev/null && \
    echo "SWIPL make" && \
    make &> /dev/null && \
    echo "SWIPL make install" && \
    make install &> /dev/null && \
    cd .. && rm -rf * &> /dev/null && \
    rm -rf /var/task/bin &> /dev/null && \
    rm -rf /var/task/share &> /dev/null

# Add postgres ODBC driver
RUN [ "${PG_ODBC}" = "true" ] && { PG_ODBC_URL="https://ftp.postgresql.org/pub/odbc/versions/src/psqlodbc-${PG_ODBC_VERSION}.tar.gz" &> /dev/null && \
  curl ${PG_ODBC_URL} --output psqlodbc-${PG_ODBC_VERSION}.tar.gz &> /dev/null && \
  tar -zxvf psqlodbc-${PG_ODBC_VERSION}.tar.gz &> /dev/null && \
  cd psqlodbc-${PG_ODBC_VERSION} && \
  ./configure  &> /dev/null && \
  make &> /dev/null && make install &> /dev/null && \
  cp /usr/local/lib/psql* /var/task/lib; } ||  echo "Skipping Snowflake"

# Add snowflake ODBC driver
# /var/task/lib/snowflake/odbc/lib
RUN [ "${SF_ODBC}" = "true" ] && { SF_ODBC_URL="https://sfc-repo.snowflakecomputing.com/odbc/linux/${SF_ODBC_VERSION}/snowflake_linux_x8664_odbc-${SF_ODBC_VERSION}.tgz" &> /dev/null && \
  curl ${SF_ODBC_URL} --output snowflake_linux_x8664_odbc-${SF_ODBC_VERSION}.tgz &> /dev/null && \
  tar -zxvf snowflake_linux_x8664_odbc-${SF_ODBC_VERSION}.tgz && \
  cp -r snowflake_odbc/lib/* /var/task/lib && \
  cp -r snowflake_odbc/conf /var/task/lib && \
  cp -r snowflake_odbc/ErrorMessages /var/task/lib ; } || echo "Skipping Postgres"

COPY simba.snowflake.ini /var/task/lib/

RUN dnf clean all

COPY build.sh /var/task/
COPY prolamb.pl /var/task/
COPY dynamic.pl /var/task/
RUN mv /var/task/dynamic.pl /var/task/bootstrap && chmod -R 777 /var/task

WORKDIR /var/task

ENV STATIC_MODULE=""
ENV BUNDLE_NAME="bundle.zip"
CMD ["./build.sh"]
