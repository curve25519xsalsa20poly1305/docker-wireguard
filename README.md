# WireGuard to SOCKS5/HTTP Proxy Docker Image

Convers WireGuard connection to SOCKS5/HTTP proxy in Docker. This allows you to have multiple proxies on different ports connecting to different WireGuard upstreams.

Supports latest Docker for both Windows, Linux, and MacOS.

### Related Projects

-   [OpenVPN](https://hub.docker.com/r/curve25519xsalsa20poly1305/openvpn/) ([GitHub](https://github.com/curve25519xsalsa20poly1305/docker-openvpn))
-   [WireGuard](https://hub.docker.com/r/curve25519xsalsa20poly1305/wireguard/) ([GitHub](https://github.com/curve25519xsalsa20poly1305/docker-wireguard))
-   [Shadowsocks/ShadowsocksR](https://hub.docker.com/r/curve25519xsalsa20poly1305/shadowsocks/) ([GitHub](https://github.com/curve25519xsalsa20poly1305/docker-shadowsocks))

## What it does?

1. It reads in a WireGuard configuration file (`.conf`) from a mounted file, specified through `WIREGUARD_CONFIG` environment variable.
2. If such configuration file is not provided, it will try to generate one in the following steps:
    - If all the following environment variables are set, it will use them to generate a configuration file:
        - `WIREGUARD_INTERFACE_PRIVATE_KEY`
        - `WIREGUARD_INTERFACE_DNS` defaults to `1.1.1.1`
        - `WIREGUARD_INTERFACE_ADDRESS`
        - `WIREGUARD_PEER_PUBLIC_KEY`
        - `WIREGUARD_PEER_ALLOWED_IPS` defaults to `0.0.0.0/0`
        - `WIREGUARD_PEER_ENDPOINT`
    - Otherwise, it will generate a free Cloudflare Warp account and use that as a configuration.
3. It starts the WireGuard client program to establish the VPN connection.
4. It optionally runs the executable defined by `WIREGUARD_UP` when the VPN connection is stable.
5. It starts [3proxy](https://3proxy.ru/) server and listen on container-scoped port 1080 for SOCKS5 and 3128 for HTTP proxy on default. Proxy authentication can be enabled with `PROXY_USER` and `PROXY_PASS` environment variables. `SOCKS5_PROXY_PORT` and `HTTP_PROXY_PORT` can be used to change the default ports. For multi-user support, use sequence of `PROXY_USER_1`, `PROXY_PASS_1`, `PROXY_USER_2`, `PROXY_PASS_2`, etc.
6. It optionally runs the executable defined by `PROXY_UP` when the proxy server is ready.
7. If `ARIA2_PORT` is defined, it starts an aria2 JSON-RPC server on the port, and optionally runs the executable defined by `ARIA2_UP`.
8. It optionally runs the user specified CMD line from `docker run` positional arguments ([see Docker doc](https://docs.docker.com/engine/reference/run/#cmd-default-command-or-options)). The program will use the VPN connection inside the container.
9. If user has provided CMD line, and `DAEMON_MODE` environment variable is not set to `true`, then after running the CMD line, it will shutdown the OpenVPN client and terminate the container.

## How to use?

WireGuard connection options are specified through these container environment variables:

-   `WIREGUARD_CONFIG` (Default: `""`) - WireGuard config path. When used, will override all following `WIREGUARD_` options.
-   `WIREGUARD_INTERFACE_PRIVATE_KEY` (Default: `""`) - interface private key
-   `WIREGUARD_INTERFACE_DNS` (Default: `"1.1.1.1"`) - interface DNS
-   `WIREGUARD_INTERFACE_ADDRESS` (Default: `""`) - interface address
-   `WIREGUARD_PEER_PUBLIC_KEY` (Default: `""`) - peer public key
-   `WIREGUARD_PEER_ALLOWED_IPS` (Default: `"0.0.0.0/0"`) - peer allowed IPs
-   `WIREGUARD_PEER_ENDPOINT` (Default: `""`) - peer endpoint
-   `WIREGUARD_UP` (Default: `""`) - Optional command to be executed when WireGuard connection becomes stable

Proxy server options are specified through these container environment variables:

-   `SOCKS5_PROXY_PORT` (Default: `"1080"`) - SOCKS5 server listening port
-   `HTTP_PROXY_PORT` (Default: `"3128"`) - HTTP proxy server listening port
-   `PROXY_USER` (Default: `""`) - Proxy server authentication username
-   `PROXY_PASS` (Default: `""`) - Proxy server authentication password
-   `PROXY_USER_<N>` (Default: `""`) - The `N`-th username for multi-user proxy authentication. `N` starts from 1.
-   `PROXY_PASS_<N>` (Default: `""`) - The `N`-th password for multi-user proxy authentication. `N` starts from 1.
-   `PROXY_UP` (Default: `""`) - Optional command to be executed when proxy server becomes stable

Arai2 options are specified through these container environment variables:

-   `ARIA2_PORT` (Default: `""`) - JSON-RPC server listening port
-   `ARIA2_PASS` (Default: `""`) - `--rpc-secret` password
-   `ARIA2_PATH` (Default: `"."`) - The directory to store the downloaded file
-   `ARIA2_ARGS` (Default: `""`) - BASH-style escaped command line to append to the `aria2c` command
-   `ARIA2_UP` (Default: `""`) - Optional command to be executed when aria2 JSON-RPC server becomes stable

Other container environment variables:

-   `DAEMON_MODE` (Default: `"false"`) - force enter daemon mode when CMD line is specified

## Example with Warp

```bash

# Unix
SET NAME="wg"
HTTP_PROXY_PORT="7777"
SOCKS5_PROXY_PORT="8888"
PROXY_USER="myuser"
PROXY_PASS="mypass"
docker run --name "${NAME}" -dit --rm \
    --device=/dev/net/tun --cap-add=NET_ADMIN --privileged \
    -p "${HTTP_PROXY_PORT}":3128 \
    -p "${SOCKS5_PROXY_PORT}":1080 \
    -e PROXY_USER="${PROXY_USER}" \
    -e PROXY_PASS="${PROXY_PASS}" \
    curve25519xsalsa20poly1305/wireguard

# Windows
SET NAME="wg"
SET HTTP_PROXY_PORT="7777"
SET SOCKS5_PROXY_PORT="8888"
SET PROXY_USER="myuser"
SET PROXY_PASS="mypass"
docker run --name "%NAME%" -dit --rm ^
    --device=/dev/net/tun --cap-add=NET_ADMIN --privileged ^
    -p "%HTTP_PROXY_PORT%":3128 ^
    -p "%SOCKS5_PROXY_PORT%":1080 ^
    -e PROXY_USER="%PROXY_USER%" ^
    -e PROXY_PASS="%PROXY_PASS%" ^
    curve25519xsalsa20poly1305/wireguard
```

Then on your host machine test it with curl:

```bash
# Unix & Windows
curl ifconfig.me -x socks5h://myuser:mypass@127.0.0.1:7777
```

To stop the daemon, run this:

```bash
# Unix
NAME="wg"
docker stop "${NAME}"

# Windows
SET NAME="wg"
docker stop "%NAME%"
```

### Example with Config File

Prepare a WireGuard configuration at `./wg.conf`. NOTE: DO NOT use IPv6 related configs as they may not be supported in Docker.

```bash
# Unix
docker run -it --rm \
    --device=/dev/net/tun --cap-add=NET_ADMIN --privileged \
    -v "${PWD}":/vpn:ro -e WIREGUARD_CONFIG=/vpn/wg.conf \
    curve25519xsalsa20poly1305/wireguard \
    curl ifconfig.me

# Windows
docker run -it --rm ^
    --device=/dev/net/tun --cap-add=NET_ADMIN --privileged ^
    -v "%CD%":/vpn:ro -e WIREGUARD_CONFIG=/vpn/wg.conf ^
    curve25519xsalsa20poly1305/wireguard ^
    curl ifconfig.me
```

## Contributing

Please feel free to contribute to this project. But before you do so, just make
sure you understand the following:

1\. Make sure you have access to the official repository of this project where
the maintainer is actively pushing changes. So that all effective changes can go
into the official release pipeline.

2\. Make sure your editor has [EditorConfig](https://editorconfig.org/) plugin
installed and enabled. It's used to unify code formatting style.

3\. Use [Conventional Commits 1.0.0-beta.2](https://conventionalcommits.org/) to
format Git commit messages.

4\. Use [Gitflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)
as Git workflow guideline.

5\. Use [Semantic Versioning 2.0.0](https://semver.org/) to tag release
versions.

## License

Copyright © 2019 curve25519xsalsa20poly1305 &lt;<curve25519xsalsa20poly1305@gmail.com>&gt;

This work is free. You can redistribute it and/or modify it under the
terms of the Do What The Fuck You Want To Public License, Version 2,
as published by Sam Hocevar. See the COPYING file for more details.
