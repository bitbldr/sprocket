ARG BASE=debian
ARG BUILDER_IMAGE="${BASE}"
ARG RUNNER_IMAGE="${BASE}"

FROM ${BUILDER_IMAGE} as builder

# # install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git wget python3 libssl-dev libreadline-dev \
    libncurses5-dev zlib1g-dev m4 curl wx-common autoconf libxml2-utils xsltproc fop unixodbc unixodbc-dev

# install asdf plugins using version specified in .tool-versions
COPY .tool-versions .tool-versions

# prepare build dir
WORKDIR /app

RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf \
    && echo '. /root/.asdf/asdf.sh' >> ~/.bashrc \
    && echo '. /root/.asdf/completions/asdf.bash' >> ~/.bashrc

ENV PATH="${PATH}:/root/.asdf/shims:/root/.asdf/bin"

RUN export ASDF_DATA_DIR=$(mktemp -d)

# install gleam using asdf
RUN asdf plugin-add gleam
RUN asdf plugin-add nodejs
RUN asdf plugin-add erlang
RUN asdf install gleam 0.29.0
RUN asdf install nodejs 19.7.0
RUN asdf install erlang 24.0.1
RUN asdf global gleam 0.29.0
RUN asdf global nodejs 19.7.0
RUN asdf global erlang 24.0.1

# ensure asdf plugins are available in the shell
RUN asdf reshim

# # install node and global dev dependencies
RUN npm install -g yarn typescript ts-node

# copy source files
COPY . .

# install gleam deps
RUN gleam deps download

# install node deps
RUN yarn install

# # install node deps
# # RUN yarn run build
# # RUN gleam build
# RUN yarn run client:build
# RUN yarn run tailwind:build

# # build release
# RUN gleam export erlang-shipment

# ================

# # prepare build dir
# WORKDIR /app

# # install asdf plugins using version specified in .tool-versions
# COPY .tool-versions .tool-versions
# COPY setup-deps.sh setup-deps.sh

# RUN chmod +x setup-deps.sh

# # RUN ./setup-deps.sh "25.3" "0.29.0" "19.7.0"
