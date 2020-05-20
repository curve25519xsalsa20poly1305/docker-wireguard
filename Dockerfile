FROM golang:alpine as builder
WORKDIR /go/src
COPY warp.go ./warp/
RUN CGO_ENABLED=0 GOOS=linux \
    apk add --no-cache git build-base && \
    cd warp && \
    go get && \
    go build -a -installsuffix cgo -ldflags '-s' -o warp

FROM alpine:latest

COPY --from=builder /go/src/warp/warp /usr/local/bin/
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=curve25519xsalsa20poly1305/aria2:latest /usr/bin/aria2c /usr/bin/

COPY entrypoint.sh   /usr/local/bin/
COPY wireguard-up.sh /usr/local/bin/

RUN echo "http://dl-4.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
    && apk add --no-cache bash curl wget wireguard-tools openresolv ip6tables \
        libgcc libstdc++ gnutls expat sqlite-libs c-ares openssl 3proxy \
    && chmod +x \
        /usr/local/bin/entrypoint.sh \
        /usr/local/bin/wireguard-up.sh

# Wireguard Options
ENV     WIREGUARD_CONFIG                ""
ENV     WIREGUARD_INTERFACE_PRIVATE_KEY ""
ENV     WIREGUARD_INTERFACE_DNS         "1.1.1.1"
ENV     WIREGUARD_INTERFACE_ADDRESS     ""
ENV     WIREGUARD_PEER_PUBLIC_KEY       ""
ENV     WIREGUARD_PEER_ALLOWED_IPS      "0.0.0.0/0"
ENV     WIREGUARD_PEER_ENDPOINT         ""
ENV     WIREGUARD_UP                    ""

# aria2 Options
ENV     ARIA2_PORT                      ""
ENV     ARIA2_PASS                      ""
ENV     ARIA2_PATH                      "."
ENV     ARIA2_ARGS                      ""
ENV     ARIA2_UP                        ""

# Proxy Options
ENV     PROXY_USER                      ""
ENV     PROXY_PASS                      ""
ENV     PROXY_UP                        ""

# Proxy Ports Options
ENV     SOCKS5_PROXY_PORT               "1080"
ENV     HTTP_PROXY_PORT                 "3128"

ENV     DAEMON_MODE                     "false"

ENTRYPOINT  [ "entrypoint.sh" ]
