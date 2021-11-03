FROM --platform=$BUILDPLATFORM golang:1.23 AS builder

LABEL org.opencontainers.image.source=https://github.com/shipperizer/argocd-image-updater

RUN mkdir -p /src/argocd-image-updater
WORKDIR /src/argocd-image-updater
# cache dependencies as a layer for faster rebuilds
COPY go.mod go.sum ./
RUN go mod download
COPY . .

RUN mkdir -p dist && \
	make controller

FROM --platform=$BUILDPLATFORM alpine:3.20

RUN apk update && \
    apk upgrade && \
    apk add git openssh-client gpg tini ca-certificates && \
    # python3 py3-pip && \
    # pip3 install --upgrade pip && \
    # pip3 install awscli && \
    rm -rf /var/cache/apk/*

LABEL org.opencontainers.image.source=https://github.com/shipperizer/argocd-image-updater

RUN mkdir -p /usr/local/bin
RUN mkdir -p /app/config
RUN adduser --home "/app" --disabled-password --uid 1000 argocd

COPY --from=builder /src/argocd-image-updater/dist/argocd-image-updater /usr/local/bin/
COPY hack/git-ask-pass.sh /usr/local/bin/git-ask-pass.sh

USER 1000

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/argocd-image-updater"]
