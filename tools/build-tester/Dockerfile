ARG           FROM_REGISTRY=docker.io/dubodubonduponey
ARG           FROM_IMAGE_BUILDER=debian@sha256:d17b322f1920dd310d30913dd492cbbd6b800b62598f5b6a12d12684aad82296
ARG           FROM_IMAGE_RUNTIME=scratch

ARG           _private_df="${FROM_REGISTRY:+$FROM_REGISTRY/$FROM_IMAGE_BUILDER}"

FROM          ${_private_df:-scratch}                                                                                   AS debootstrap-builder

SHELL         ["/bin/bash", "-o", "errexit", "-o", "errtrace", "-o", "functrace", "-o", "nounset", "-o", "pipefail", "-c"]

ARG           DEBIAN_FRONTEND="noninteractive"
ARG           TERM="xterm"
ARG           LANG="C.UTF-8"
ARG           LC_ALL="C.UTF-8"
ARG           TZ="America/Los_Angeles"

ARG           TARGETPLATFORM

# XXX all of these should probably be ARG and ONBUILD ARG, otherwise they leak into runtime
ENV           CURL_HOME=/run/secrets
ENV           APT_CONFIG=/run/secrets/APT_CONFIG
RUN           touch "$APT_CONFIG"

RUN           --mount=type=secret,uid=100,id=CA \
              --mount=type=secret,uid=100,id=CERTIFICATE \
              --mount=type=secret,uid=100,id=KEY \
              --mount=type=secret,uid=100,id=GPG.gpg \
              --mount=type=secret,id=NETRC \
              --mount=type=secret,id=APT_SOURCES \
              --mount=type=secret,id=APT_CONFIG \
              apt-get update -qq && apt-get install -qq --no-install-recommends \
                curl=7.88.1-10+deb12u5

RUN           --mount=type=secret,id=CA \
              --mount=type=secret,id=CERTIFICATE \
              --mount=type=secret,id=KEY \
              --mount=type=secret,id=GPG.gpg \
              --mount=type=secret,id=NETRC \
              --mount=type=secret,id=TARGET_REPOSITORY \
              --mount=type=secret,id=.curlrc \
              curl XXX
