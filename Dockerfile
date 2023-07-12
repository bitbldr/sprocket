FROM ghcr.io/gleam-lang/gleam:v0.29.0-erlang-alpine as builder

RUN apk add --update nodejs npm

RUN npm install -g yarn typescript ts-node

WORKDIR /build

# copy source files
COPY . .

# install gleam deps
RUN gleam deps download

# install node deps
RUN yarn install

# # install node deps
RUN yarn run client:build
RUN yarn run tailwind:build

# # build release
RUN gleam export erlang-shipment

RUN mv build/erlang-shipment /app

# FROM erlang:24.0.1-alpine
FROM ghcr.io/gleam-lang/gleam:v0.29.0-erlang-alpine

WORKDIR /app
RUN chown nobody /app

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app /app

USER nobody

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]