# syntax=docker/dockerfile:1
ARG OS_TYPE=ubuntu
ARG OS_VERSION=22.04
FROM ${OS_TYPE}:${OS_VERSION} as setup_clang

# setup clang
ARG LLVM_MAJOR_VERSION=16
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install curl lsb-release dpkg && \
    mkdir -p /etc/apt/keyrings && \
    apt_key_path=/etc/apt/keyrings/apt.llvm.org.asc; \
    curl -sS -o $apt_key_path https://apt.llvm.org/llvm-snapshot.gpg.key && \
    arch=$(dpkg --print-architecture); \
    codename=$(lsb_release -sc); \
    cat <<EOF > /etc/apt/sources.list.d/llvm-${LLVM_MAJOR_VERSION}.list
deb [arch=$arch signed-by=$apt_key_path] http://apt.llvm.org/${codename}/ llvm-toolchain-${codename}-${LLVM_MAJOR_VERSION} main
deb-src [arch=$arch signed-by=$apt_key_path] http://apt.llvm.org/${codename}/ llvm-toolchain-${codename}-${LLVM_MAJOR_VERSION} main
EOF
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install clang-${LLVM_MAJOR_VERSION}

FROM setup_clang as build_modsecurity

ARG LUAJIT_DEB_VERSION
ARG LUAJIT_DEB_OS_ID
RUN mkdir -p /depends
RUN curl -sSL https://github.com/hnakamur/openresty-luajit-deb-docker/releases/download/${LUAJIT_DEB_VERSION}/dist-${LUAJIT_DEB_OS_ID}.tar.gz | tar zxf - -C /depends --strip-components=2
RUN dpkg -i /depends/*.deb

# Apapted from
# https://github.com/apache/trafficserver/blob/e4ff6cab0713f25290a62aba74b8e1a595b7bc30/ci/docker/deb/Dockerfile#L46-L58
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install tzdata apt-utils \
    debhelper dpkg-dev lsb-release xz-utils git \
    libyajl-dev libgeoip-dev libxml2-dev libpcre2-dev libcurl4-openssl-dev \
    libmaxminddb-dev libfuzzy-dev pkg-config liblmdb-dev

ARG SRC_DIR=/src
ARG BUILD_USER=build
RUN useradd -m -d ${SRC_DIR} -s /bin/bash ${BUILD_USER}

COPY --chown=${BUILD_USER}:${BUILD_USER} ./modsecurity/ /src/modsecurity/
USER ${BUILD_USER}
WORKDIR ${SRC_DIR}
ARG PKG_VERSION
RUN tar cf - --exclude .git --exclude debian modsecurity | xz -c > modsecurity_${PKG_VERSION}.orig.tar.xz
WORKDIR ${SRC_DIR}/modsecurity
ARG PKG_REL_DISTRIB
RUN sed -i "s/DebRelDistrib/${PKG_REL_DISTRIB}/;s/UNRELEASED/$(lsb_release -cs)/" /src/modsecurity/debian/changelog
RUN dpkg-buildpackage -us -uc

USER root
