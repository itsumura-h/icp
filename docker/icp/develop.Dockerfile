FROM ubuntu:24.04

# prevent timezone dialogue
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt upgrade -y && \
    apt install -y \
      git \
      curl \
      xz-utils \
      ca-certificates \
      libunwind-dev \
      build-essential
# libunwind-dev: /root/.cache/dfinity/versions/0.24.3/canister_sandbox: error while loading shared libraries: libunwind.so.8: cannot open shared object file: No such file or directory
# build-essential: gcc, g++, make
RUN apt autoremove -y

WORKDIR /root

# icp
## https://github.com/dfinity/sdk/releases/latest
ARG DFX_VERSION=0.22.0
RUN curl -OL https://internetcomputer.org/install.sh
RUN chmod +x install.sh
ARG DFXVM_INIT_YES=yes
RUN DFXVM_INIT_YES=$DFXVM_INIT_YES DFX_VERSION=$DFX_VERSION ./install.sh

# nodejs
# https://nodejs.org/en/download/prebuilt-binaries
ARG NODE_VERSION=20.18.1
RUN curl -OL https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz
RUN tar -xvf node-v${NODE_VERSION}-linux-x64.tar.xz
RUN rm node-v${NODE_VERSION}-linux-x64.tar.xz
RUN mv node-v${NODE_VERSION}-linux-x64 .node
ENV PATH $PATH:/root/.node/bin

# # pnpm
# RUN curl -fsSL https://get.pnpm.io/install.sh | bash -
# ENV PATH $PATH:/root/.local/share/pnpm

# # python
# RUN curl https://pyenv.run | bash
# ENV PATH $PATH:/root/.pyenv/bin
# # RUN pyenv install 3.10.7
# ENV PIPENV_VENV_IN_PROJECT true

RUN git config --global --add safe.directory /application
WORKDIR /application
