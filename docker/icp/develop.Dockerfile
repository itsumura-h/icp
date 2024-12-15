FROM ubuntu:24.04

# prevent timezone dialogue
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update
RUN apt upgrade -y
RUN apt install -y \
  git \
  curl \
  xz-utils \
  ca-certificates \
  libunwind-dev
# libunwind-dev: /root/.cache/dfinity/versions/0.24.3/canister_sandbox: error while loading shared libraries: libunwind.so.8: cannot open shared object file: No such file or directory

RUN apt autoremove -y

# nodejs
WORKDIR /root

# https://nodejs.org/en/download/prebuilt-binaries
ARG NODE_VERSION=v22.12.0
RUN curl -OL https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.xz
RUN tar -xvf node-${NODE_VERSION}-linux-x64.tar.xz
RUN rm node-${NODE_VERSION}-linux-x64.tar.xz
RUN mv node-${NODE_VERSION}-linux-x64 .node
ENV PATH $PATH:/root/.node/bin

# pnpm
RUN curl -fsSL https://get.pnpm.io/install.sh | bash -
ENV PATH $PATH:/root/.local/share/pnpm

# icp
RUN mkdir -p /root/.dfx/bin
## dfxvm
## https://github.com/dfinity/dfxvm/releases/latest
ARG DFXVM_VERSION=v1.0.0
RUN curl -OL https://github.com/dfinity/dfxvm/releases/download/${DFXVM_VERSION}/dfxvm-x86_64-unknown-linux-gnu.tar.gz
RUN tar -xvf dfxvm-x86_64-unknown-linux-gnu.tar.gz
RUN rm dfxvm-x86_64-unknown-linux-gnu.tar.gz
RUN cp dfxvm-x86_64-unknown-linux-gnu/dfxvm /root/.dfx/bin/
RUN rm -rf dfxvm-x86_64-unknown-linux-gnu
## dfx
## https://github.com/dfinity/sdk/releases/latest
ARG DFX_VERSION=0.24.3
RUN curl -OL https://github.com/dfinity/sdk/releases/download/${DFX_VERSION}/dfx-x86_64-unknown-linux-gnu.tar.gz
RUN tar -xvf dfx-x86_64-unknown-linux-gnu.tar.gz
RUN rm dfx-x86_64-unknown-linux-gnu.tar.gz
RUN cp dfx-x86_64-unknown-linux-gnu/dfx /root/.dfx/bin/
RUN rm -rf dfx-x86_64-unknown-linux-gnu

ENV PATH $PATH:/root/.dfx/bin

WORKDIR /application
