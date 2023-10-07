FROM ghcr.io/gleam-lang/gleam:v0.31.0-erlang-alpine as builder

RUN apk add --update nodejs npm elixir

RUN npm install -g yarn typescript ts-node

WORKDIR /build

# copy source files
COPY package.json yarn.lock ./

# install node deps
RUN yarn install

# copy source files
COPY . .

# install gleam deps
RUN gleam deps download

# # install node deps
RUN yarn run client:build
RUN yarn run docs:build
RUN yarn run tailwind:build

# # build release
RUN gleam export erlang-shipment

RUN mv build/erlang-shipment /app

# FROM erlang:24.0.1-alpine
FROM ghcr.io/gleam-lang/gleam:v0.31.0-erlang-alpine

WORKDIR /app
RUN chown nobody /app

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app /app

USER nobody

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]