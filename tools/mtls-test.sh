#!/usr/bin/env bash
set -o errexit -o errtrace -o functrace -o nounset -o pipefail

# On mac:  CURL_BINARY=$(brew --prefix)/opt/curl/bin/curl ./docker-images/tools/mtls-test.sh

readonly root="$(cd "$(dirname "${BASH_SOURCE[0]:-$PWD}")" 2>/dev/null 1>&2 && pwd)"

# Linux in container
#curl 7.74.0 (x86_64-pc-linux-gnu) libcurl/7.74.0 OpenSSL/1.1.1k zlib/1.2.11 brotli/1.0.9 libidn2/2.3.0 libpsl/0.21.0 (+libidn2/2.3.0) libssh2/1.9.0 nghttp2/1.43.0 librtmp/2.3
#Release-Date: 2020-12-09
#Protocols: dict file ftp ftps gopher http https imap imaps ldap ldaps mqtt pop3 pop3s rtmp rtsp scp sftp smb smbs smtp smtps telnet tftp
#Features: alt-svc AsynchDNS brotli GSS-API HTTP2 HTTPS-proxy IDN IPv6 Kerberos Largefile libz NTLM NTLM_WB PSL SPNEGO SSL TLS-SRP UnixSockets

# Macos system
#curl 7.64.1 (x86_64-apple-darwin20.0) libcurl/7.64.1 (SecureTransport) LibreSSL/2.8.3 zlib/1.2.11 nghttp2/1.41.0
#Release-Date: 2019-03-27
#Protocols: dict file ftp ftps gopher http https imap imaps ldap ldaps pop3 pop3s rtsp smb smbs smtp smtps telnet tftp
#Features: AsynchDNS GSS-API HTTP2 HTTPS-proxy IPv6 Kerberos Largefile libz MultiSSL NTLM NTLM_WB SPNEGO SSL UnixSockets

# Brew
# dmp@macArena:~/Projects/Distribution/docker-images$ $(brew --prefix)/opt/curl/bin/curl --version
#curl 7.78.0 (x86_64-apple-darwin20.4.0) libcurl/7.78.0 (SecureTransport) OpenSSL/1.1.1l zlib/1.2.11 brotli/1.0.9 zstd/1.5.0 libidn2/2.3.2 libssh2/1.9.0 nghttp2/1.44.0 librtmp/2.3 OpenLDAP/2.5.7
#Release-Date: 2021-07-21
#Protocols: dict file ftp ftps gopher gophers http https imap imaps ldap ldaps mqtt pop3 pop3s rtmp rtsp scp sftp smb smbs smtp smtps telnet tftp
#Features: alt-svc AsynchDNS brotli GSS-API HSTS HTTP2 HTTPS-proxy IDN IPv6 Kerberos Largefile libz MultiSSL NTLM NTLM_WB SPNEGO SSL TLS-SRP UnixSockets zstd

# https://www.claudiokuenzler.com/blog/693/curious-case-of-curl-ssl-tls-sni-http-host-header

C_USER_R="dmp:\$maumau14041976"
C_USER="dubodubonduponey:aFBZBVJ6EjcFXyktok3osCeV6pc"
C_CERT="$root/cert.pem"
C_CA="$root/ca.pem"

C_KEY="$root/key.pem"
C_PASSWORD=""

CURL_BINARY="${CURL_BINARY:-curl}"
# CURL_BINARY=$(brew --prefix)/opt/curl/bin/curl

http::verify(){
  local domain="$1"
  local status="${2:-}"
  local error=""
  shift
  shift || true
  echo "$status" | grep -qE "^[0-9]+$" || error=err

  echo "----------------------------------------------------------------------------------------------------------------"
  echo "Auditing $domain"
  echo "----------------------------------------------------------------------------------------------------------------"

  # XXX --proto '=https'
  com=("$CURL_BINARY" -v -o/dev/null --proxy-cacert "$C_CA" --cacert "$C_CA")

  com+=("$@")
  com+=("$domain")

  res=
  result="$("${com[@]}" 2>&1)" || res=$?

  echo "Command: ${com[*]}"
  echo "Expected $status"
  echo "Actual exit code: $res"

  if [ "$error" ] && [ ! "$res" ]; then
    echo "Content: $result"
    echo "Was expecting a failure and did not get one"
    return 1
  fi
  if [ ! "$error" ] && [ "$res" ]; then
    echo "Content: $result"
    echo "Was expecting success but did get a failure"
    echo "Repeating command: ${com[*]}"
    return 1
  fi

  if [ "$status" ] && ! echo "$result" | grep -q "$status"; then
    echo "Content: $result"
    echo "Was expecting http status $status"
    echo "Repeating command: ${com[*]}"
    return 1
  fi
}

###################################
# Testing go mod
###################################
http::verify "https://go-proxy.local/" "200" --user "$C_USER" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY" --tlsv1.3 --tls-max 1.3
http::verify "https://go-proxy.local/" "err" --user "$C_USER" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY" --tlsv1.2 --tls-max 1.2

# http2 works
http::verify "https://go-proxy.local/" "200" --user "$C_USER" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY" --http2 --http2-prior-knowledge

# Just credentials work
http::verify "https://go-proxy.local/" "200" --user "$C_USER" --http2 --http2-prior-knowledge

# Other versions of TLS are rejected
# curl does not build with these anymore by default: --sslv2 --sslv3
http::verify "https://go-proxy.local/" "err" --user "$C_USER" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY" --tlsv1.0 --tls-max 1.0
http::verify "https://go-proxy.local/" "err" --user "$C_USER" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY" --tlsv1.1 --tls-max 1.1

# Just the cert, or nothing, will not work
http::verify "https://go-proxy.local/" "401" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY"
http::verify "https://go-proxy.local/" "401"


exit

###################################
# Testing the registry
###################################
# Success requires authenticated user proxy or regular, with tls 1.2 minimum
http::verify "https://registry-push.local/v2/" "200" --user "$C_USER_R" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY" --tlsv1.3 --tls-max 1.3

http::verify "https://registry-push.local/v2/" "err" --user "$C_USER_R" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY" --tlsv1.2 --tls-max 1.2

# http2 works
http::verify "https://registry-push.local/v2/" "200" --user "$C_USER_R" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY" --http2 --http2-prior-knowledge

# Other versions of TLS are rejected
# curl does not build with these anymore by default: --sslv2 --sslv3
http::verify "https://registry-push.local/v2/" "err" --user "$C_USER_R" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY" --tlsv1.0 --tls-max 1.0
http::verify "https://registry-push.local/v2/" "err" --user "$C_USER_R" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY" --tlsv1.1 --tls-max 1.1

# Just the credentials or just the cert will not work
http::verify "https://registry-push.local/v2/" "401" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY"
http::verify "https://registry-push.local/v2/" "err" --user "$C_USER_R"
http::verify "https://registry-push.local/v2/" "err"


# Testing the apt proxy as a proxy server
# XXX sometimes 16, sometimes 55
# XXX very interesting - there is no reason why curl would behave differently / complain in the proxy scenario wrt HTTP2, but it *does* with old versions

###################################
# Testing the apt proxy as a proxy
# Success requires authenticated user proxy or regular, and tls 1.2 and 1.3 should succeed
http::verify "http://snapshot.debian.org/archive/" "200" --proxy https://apt-proxy.local --user "$C_USER" --tlsv1.2 --tls-max 1.2
http::verify "http://snapshot.debian.org/archive/" "200" --proxy https://apt-proxy.local --user "$C_USER" --tlsv1.3 --tls-max 1.3

http::verify "http://snapshot.debian.org/archive/" "200" --proxy https://apt-proxy.local --proxy-user "$C_USER" --tlsv1.2 --tlsv1.2
http::verify "http://snapshot.debian.org/archive/" "200" --proxy https://apt-proxy.local --proxy-user "$C_USER" --tlsv1.3 --tlsv1.3

# http2 works
http::verify "http://snapshot.debian.org/archive/" "200" --proxy https://apt-proxy.local --user "$C_USER" --http2 --http2-prior-knowledge

# Other versions of TLS are rejected
# XXX cannot control that with curl apparently, which uses TLS max for all proxy connections
#http::verify "http://snapshot.debian.org/archive/" "err" --proxy https://apt-proxy.local --user "$C_USER" --tlsv1.0 --tls-max 1.0
#http::verify "http://snapshot.debian.org/archive/" "err" --proxy https://apt-proxy.local --user "$C_USER" --tlsv1.1 --tls-max 1.1

# Valid mTLS has no effect and is still successful
http::verify "http://snapshot.debian.org/archive/" "200" --proxy https://apt-proxy.local --user "$C_USER" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY"
http::verify "http://snapshot.debian.org/archive/" "200" --proxy https://apt-proxy.local --proxy-user "$C_USER" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY"

# No credentials fails, with or without valid certificates
http::verify "http://snapshot.debian.org/archive/" "401" --proxy https://apt-proxy.local --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY"
http::verify "http://snapshot.debian.org/archive/" "401" --proxy https://apt-proxy.local

###################################
# Testing the apt proxy as a front for another domain
###################################
# Success requires authenticated user proxy or regular, with tls 1.2 minimum
http::verify "https://apt-proxy.local/archive/" "200" -H "Host: snapshot.debian.org" --user "$C_USER" --tlsv1.2 --tls-max 1.2
http::verify "https://apt-proxy.local/archive/" "200" -H "Host: snapshot.debian.org" --user "$C_USER" --tlsv1.3 --tls-max 1.3

# http2 works
http::verify "https://apt-proxy.local/archive/" "200" -H "Host: snapshot.debian.org" --user "$C_USER" --http2 --http2-prior-knowledge

# Other versions of TLS are rejected
# curl does not build with these anymore by default: --sslv2 --sslv3
http::verify "https://apt-proxy.local/archive/" "err" -H "Host: snapshot.debian.org" --user "$C_USER" --tlsv1.0 --tls-max 1.0
http::verify "https://apt-proxy.local/archive/" "err" -H "Host: snapshot.debian.org" --user "$C_USER" --tlsv1.1 --tls-max 1.1

# Valid mTLS has no effect and is still successful
http::verify "https://apt-proxy.local/archive/" "200" -H "Host: snapshot.debian.org" --user "$C_USER" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY"

# No credentials fails, with or without valid certificates
http::verify "https://apt-proxy.local/archive/" "401" -H "Host: snapshot.debian.org" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY"
http::verify "https://apt-proxy.local/archive/" "401" -H "Host: snapshot.debian.org"

###################################
# Testing the apt proxy in and for itself
###################################
# Success requires authenticated user proxy or regular, with tls 1.2 minimum
http::verify "https://apt-proxy.local/archive/" "200"  --user "$C_USER" --tlsv1.2 --tls-max 1.2
http::verify "https://apt-proxy.local/archive/" "200"  --user "$C_USER" --tlsv1.3 --tls-max 1.3

# http2 works
http::verify "https://apt-proxy.local/archive/" "200"  --user "$C_USER" --http2 --http2-prior-knowledge

# Other versions of TLS are rejected
# curl does not build with these anymore by default: --sslv2 --sslv3
http::verify "https://apt-proxy.local/archive/" "err"  --user "$C_USER" --tlsv1.0 --tls-max 1.0
http::verify "https://apt-proxy.local/archive/" "err"  --user "$C_USER" --tlsv1.1 --tls-max 1.1

# Valid mTLS has no effect and is still successful
http::verify "https://apt-proxy.local/archive/" "200"  --user "$C_USER" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY"

# No credentials fails, with or without valid certificates
http::verify "https://apt-proxy.local/archive/" "401"  --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY"
http::verify "https://apt-proxy.local/archive/" "401"


###################################
# Testing the apt front as a front for another domain
###################################
# XXX when a service has some level of mTLS enabled, we get the finger on having SNI not matching the host header, so, trick it with --resolve instead - PITA
# Success requires authenticated user proxy or regular, with tls 1.2 minimum
IP=10.0.4.111
http::verify "https://snapshot.debian.org/archive/" "200" --resolve snapshot.debian.org:443:$IP --user "$C_USER" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY" --tlsv1.2 --tls-max 1.2
http::verify "https://snapshot.debian.org/archive/" "200" --resolve snapshot.debian.org:443:$IP --user "$C_USER" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY" --tlsv1.3 --tls-max 1.3

# http2 works
http::verify "https://snapshot.debian.org/archive/" "200" --resolve snapshot.debian.org:443:$IP --user "$C_USER" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY" --http2 --http2-prior-knowledge

# Other versions of TLS are rejected
# curl does not build with these anymore by default: --sslv2 --sslv3
http::verify "https://snapshot.debian.org/archive/" "err" --resolve snapshot.debian.org:443:$IP --user "$C_USER" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY" --tlsv1.0 --tls-max 1.0
http::verify "https://snapshot.debian.org/archive/" "err" --resolve snapshot.debian.org:443:$IP --user "$C_USER" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY" --tlsv1.1 --tls-max 1.1

# Just the credentials or just the cert will not work
http::verify "https://snapshot.debian.org/archive/" "401" --resolve snapshot.debian.org:443:$IP --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY"
http::verify "https://snapshot.debian.org/archive/" "err" --resolve snapshot.debian.org:443:$IP --user "$C_USER"
http::verify "https://snapshot.debian.org/archive/" "err" --resolve snapshot.debian.org:443:$IP

###################################
# Testing the apt front in and for itself
###################################
# Success requires authenticated user proxy or regular, with tls 1.2 minimum
http::verify "https://apt-front.local/archive/" "200" --user "$C_USER" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY" --tlsv1.2 --tls-max 1.2
http::verify "https://apt-front.local/archive/" "200" --user "$C_USER" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY" --tlsv1.3 --tls-max 1.3

# http2 works
http::verify "https://apt-front.local/archive/" "200" --user "$C_USER" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY" --http2 --http2-prior-knowledge

# Other versions of TLS are rejected
# curl does not build with these anymore by default: --sslv2 --sslv3
http::verify "https://apt-front.local/archive/" "err" --user "$C_USER" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY" --tlsv1.0 --tls-max 1.0
http::verify "https://apt-front.local/archive/" "err" --user "$C_USER" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY" --tlsv1.1 --tls-max 1.1

# Just the credentials or just the cert will not work
# Not clear why the difference...
http::verify "https://apt-front.local/archive/" "401" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY"
http::verify "https://apt-front.local/archive/" "err" --user "$C_USER"
http::verify "https://apt-front.local/archive/" "err"

###################################
# Testing the apt mirror
###################################
# Success requires authenticated user proxy or regular, with tls 1.2 minimum
http::verify "https://apt-mirror.local/" "200" --user "$C_USER" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY" --tlsv1.2 --tls-max 1.2
http::verify "https://apt-mirror.local/" "200" --user "$C_USER" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY" --tlsv1.3 --tls-max 1.3

# http2 works
http::verify "https://apt-mirror.local/" "200" --user "$C_USER" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY" --http2 --http2-prior-knowledge

# Other versions of TLS are rejected
# curl does not build with these anymore by default: --sslv2 --sslv3
http::verify "https://apt-mirror.local/" "err" --user "$C_USER" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY" --tlsv1.0 --tls-max 1.0
http::verify "https://apt-mirror.local/" "err" --user "$C_USER" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY" --tlsv1.1 --tls-max 1.1

# Just the credentials or just the cert will not work
# Not clear why the difference...
http::verify "https://apt-mirror.local/" "401" --cert "$C_CERT:$C_PASSWORD" --key "$C_KEY"
http::verify "https://apt-mirror.local/" "err" --user "$C_USER"
http::verify "https://apt-mirror.local/" "err"

# XXX missing
# - wrong credentials
# - wrong certificates
# - http1.0 and http1.1 tests


exit

modeler::tls(){
  local tls=(1.0 1.1 1.2 1.3)

  local tlsmin="${1:-1.0}"
  local tlsmax="${2:-1.3}"

  for test_tls in "${tls[@]}"; do
    result=true
    [ "$(echo "$test_tls>=$tlsmin" | bc -l)" == 1 ] && [ "$(echo "$test_tls<=$tlsmax" | bc -l)" == 1 ] || result=
  done
}


describe: {
  machine: "1.2.3.4" # defaults to normal DNS resolution

  protocol: {
    min: 1.0
    max: 2.0
  }

  tls: {
    min: 1.2 # defaults to 1.0
    max: 1.3 # defaults to 1.3
  }

  http: false | true | upgrade

  url: "/v2/" # defaults to /

  "/": {

  }

  host: "registry-push.local"

  auth: {
    basic: {
      user: "foo",
      password: "bar"
    },
    mtls: {
      cert: "xxx"
      password: "myyy"
    }
  }
}

