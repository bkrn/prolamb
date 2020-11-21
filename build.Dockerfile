FROM lambci/lambda:build-provided

ARG SWIPL=8.2.2
ARG CMAKE=3.15.5
ARG CMAKE_CHECKSUM=fbdd7cef15c0ced06bb13024bfda0ecc0dedbcaaaa6b8a5d368c75255243beb4
ARG SWIPL_CHECKSUM=35ca864cfd257e3e59ebe8f01e186f8959a8b4d42f17a9a6c04ecdfa5d1e164b

WORKDIR /build

VOLUME /dist

# Install postgres to build odbc driver
RUN mkdir -p /var/task && mkdir -p /var/task/lib && \
  yum install -y \
  unixODBC \
  unixODBC-devel \
  libpq-devel \
  postgresql-devel && \
  cp /usr/lib64/libodbc.so.2 /var/task/lib && \
  cp /usr/lib64/libpq.so.5 /var/task/lib && \
  cp /usr/lib64/libodbcinst.so.2 /var/task/lib


# Build a modern version of cmake in order to build swipl
RUN curl -L https://github.com/Kitware/CMake/releases/download/v${CMAKE}/cmake-${CMAKE}.tar.gz -o cmake-${CMAKE}.tar.gz &> /dev/null && \
    SUM=$(sha256sum cmake-${CMAKE}.tar.gz | cut -d ' ' -f 1) && \
    [ ${SUM} = ${CMAKE_CHECKSUM} ] && \
    tar xfz cmake-${CMAKE}.tar.gz > /dev/null && \  
    cd cmake-3.15.5 && \
    echo "cmake bootstrap" && \
    ./bootstrap > /dev/null && \
    echo "cmake make" && \
    make > /dev/null && \ 
    echo "cmake make install" && \     
    make install > /dev/null && \
    cd .. && rm -rf * > /dev/nul

# Build swipl
RUN curl https://www.swi-prolog.org/download/stable/src/swipl-${SWIPL}.tar.gz -o swipl-${SWIPL}.tar.gz &> /dev/null && \
    SUM=$(sha256sum swipl-${SWIPL}.tar.gz | cut -d ' ' -f 1) && \
    [ ${SUM} = ${SWIPL_CHECKSUM} ] && \
    tar xfz swipl-${SWIPL}.tar.gz > /dev/null && \
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
    make > /dev/null && \
    echo "SWIPL make install" && \
    make install > /dev/null && \
    cd .. && rm -rf * > /dev/null && \
    rm -rf /var/task/bin > /dev/null && \
    rm -rf /var/task/share > /dev/null
   
RUN PG_ODBC="10.03.0000" && \
  PG_ODBC_URL="https://ftp.postgresql.org/pub/odbc/versions/src/psqlodbc-${PG_ODBC}.tar.gz" && \
  curl ${PG_ODBC_URL} --output psqlodbc-${PG_ODBC}.tar.gz && \
  tar -zxvf psqlodbc-${PG_ODBC}.tar.gz && \
  cd psqlodbc-${PG_ODBC} && \
  ./configure && \
  make && make install && \
  cp /usr/local/lib/psql* /var/task/lib

COPY build.sh /var/task/
COPY prolamb.pl /var/task/
RUN mv /var/task/prolamb.pl /var/task/bootstrap && chmod 777 /var/task/bootstrap

WORKDIR /var/task

CMD ["./build.sh"]
