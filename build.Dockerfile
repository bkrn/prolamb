FROM lambci/lambda:build-provided

ARG SWIPL=8.2.3
ARG CMAKE=3.15.5
ARG CMAKE_CHECKSUM=fbdd7cef15c0ced06bb13024bfda0ecc0dedbcaaaa6b8a5d368c75255243beb4
ARG SWIPL_CHECKSUM=9403972f9d87f1f4971fbd4a5644b4976b1b18fc174be84506c6b713bd1f9c93

ARG PG_ODBC_VERSION=10.03.0000
ARG SF_ODBC_VERSION=2.22.5
ARG SF_ODBC=true
ARG PG_ODBC=true

WORKDIR /build

VOLUME /dist

# Install postgres to build odbc driver
RUN mkdir -p /var/task && mkdir -p /var/task/lib && \
  yum install -y \
  unixODBC \
  unixODBC-devel \
  libpq-devel \
  postgresql-devel &> /dev/null && \
  cp /usr/lib64/libodbc.so.2 /var/task/lib && \
  cp /usr/lib64/libpq.so.5 /var/task/lib && \
  cp /usr/lib64/libodbcinst.so.2 /var/task/lib


# Build a modern version of cmake in order to build swipl
RUN curl -L https://github.com/Kitware/CMake/releases/download/v${CMAKE}/cmake-${CMAKE}.tar.gz -o cmake-${CMAKE}.tar.gz &> /dev/null && \
    SUM=$(sha256sum cmake-${CMAKE}.tar.gz | cut -d ' ' -f 1) && \
    [ ${SUM} = ${CMAKE_CHECKSUM} ] && \
    tar xfz cmake-${CMAKE}.tar.gz &> /dev/null && \  
    cd cmake-3.15.5 && \
    echo "cmake bootstrap" && \
    ./bootstrap &> /dev/null && \
    echo "cmake make" && \
    make &> /dev/null && \ 
    echo "cmake make install" && \     
    make install &> /dev/null && \
    cd .. && rm -rf * &> /dev/null

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
  cp /usr/local/lib/psql* /var/task/lib; } || true

# Add snowflake ODBC driver
# /var/task/lib/snowflake/odbc/lib
RUN [ "${SF_ODBC}" = "true" ] && { SF_ODBC_URL="https://sfc-repo.snowflakecomputing.com/odbc/linux/${SF_ODBC_VERSION}/snowflake-odbc-${SF_ODBC_VERSION}.x86_64.rpm" &> /dev/null && \
  curl ${SF_ODBC_URL} --output snowflake-odbc-${SF_ODBC_VERSION}.x86_64.rpm &> /dev/null && \
  yum install -y snowflake-odbc-${SF_ODBC_VERSION}.x86_64.rpm && \
  cp -r /usr/lib64/snowflake /var/task/lib; } || true

COPY build.sh /var/task/
COPY prolamb.pl /var/task/
COPY dynamic.pl /var/task/
RUN mv /var/task/dynamic.pl /var/task/bootstrap && chmod 777 /var/task/bootstrap

WORKDIR /var/task

ENV STATIC_MODULE=""
ENV BUNDLE_NAME="bundle.zip"
CMD ["./build.sh"]
