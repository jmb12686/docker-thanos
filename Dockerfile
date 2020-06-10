FROM golang:1.14.2-alpine3.11 as builder

RUN apk update && apk upgrade && apk add --no-cache alpine-sdk


# Change in the docker context invalidates the cache so to leverage docker
# layer caching, moving update and installing apk packages above COPY cmd
# More info https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#leverage-build-cache

# Replaced ADD with COPY as add is generally to download content form link or tar files
# while COPY supports the basic copying of local files into the container.
# https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#add-or-copy
# COPY . $GOPATH/src/github.com/thanos-io/thanos
RUN mkdir -p $GOPATH/src/github.com/thanos-io/thanos && \
  git clone --branch v0.13.0-rc.1 --depth 1 https://github.com/thanos-io/thanos.git $GOPATH/src/github.com/thanos-io/thanos
WORKDIR $GOPATH/src/github.com/thanos-io/thanos

RUN make build

# RUN git update-index --refresh; make build

## Did not work, produced following errors: "ambiguous import: found package github.com/Azure/go-autorest/tracing in multiple modules:"
# RUN GO111MODULE=on go get github.com/thanos-io/thanos/cmd/thanos@v0.13.0-rc.1

# -----------------------------------------------------------------------------

FROM quay.io/prometheus/busybox:latest
LABEL maintainer="John Belisle"

COPY --from=builder /go/bin/thanos /bin/thanos

ENTRYPOINT [ "/bin/thanos" ]