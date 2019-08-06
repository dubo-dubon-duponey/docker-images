# Docker Images

> Dubo, Dubon, Duponey

All our images follow four core principles:

 1. support multiple architectures
 1. minimize runtime footprint/size
 1. have a solid security focus
 1. keep it simple

## Multi-arch

We strongly recommend using (and are using ourselves) "buildx" to build and push multi-architecture versions of our images.

All our images provide a simple `./build.sh` script to help you do so, with overrides for key elements of the build process (platforms selection, final image name, etc).

To the extent the underlying software actually builds on it, we support arm6, arm7, arm64 and amd64.

 * arm6 is hit and miss, and is unlikely to receive much love
 * arm7 is still quite useful for Raspberry PI 3, albeit it's being superseded by arm64

## Footprint

### Multistage images

Images that actually require "building" anything are multistage and clearly separate "build" and "runtime" phases.
As such, our live images never carry around useless (eg: build) dependencies.

### Slim base distro

All of your images use Debian `buster-slim` as a base - the only exception being nodejs projects (using a `dubnium-buster` base).
While Alpine is certainly a very good distro and a reasonable choice, musl is still problematic in a number of cases,
and the community size and available packages are not up-to-par with Debian.

### Dependencies

Runtime dependencies are kept to the absolute minimum.

## Security 

### Image integrity guarantees

All our images are signed using Docker Notary and published on Docker Hub, meaning that what you get from there is exactly 
what we built, signed and pushed, and cannot be tempered with.
Be sure to use `export DOCKER_CONTENT_TRUST=1` while pulling them.

Our build script also enforce `DOCKER_CONTENT_TRUST`, extending this guarantee to the base images at build time.

### Reduced attack surface

As a consequence of our dependencies strategy and base distro choice.

### Dependencies pinning

All packaged softwares and their dependencies are pinned to a content addressable hash:

 * git-cloned-repos are always checked out to a specific commit hash
 * yarn packages are pinned to a specific git commit, and retrieved from github instead of npm (if required, we fork them and yarn lock their dependencies)
 * dependencies retrieved from casual urls are always downloaded and committed at a specific version alongside the Dockerfile - in such a case, a `refresh.sh` 
 script is provided so you can refresh them on your own

The "exception" to this rule is deb packages, albeit being retrieved solely from buster repos (the current stable).

### Build reproducibility

The above guarantees that builds are reproducible, as long as there is no security update to a debian dependency package.

### Simplicity and audit-ability over fanciness

Entrypoint scripts are kept simple on purpose.
We do not package fancy init systems (like s6), monitoring tools, etc.

This of course comes at a cost - for example, there is no provision for recovering from a process crash (which will just exit the container).

We do believe such issues are best dealt with by your orchestrator, or other systems outside of the containers we provide.

### Trust model

As long as you pick a specific git commit from our images repo:

 * our images are straightforward to audit: looking at `Dockerfile`, `entrypoint` and `build` usually give you a thorough understanding of what's going on
 * given all dependencies are pinned (in a content addressable fashion), you do not have to trust any third-party infrastructure or distribution system
 * we only depend on two base images at runtime (buster and dubnium-buster), and three images at build time (buster, golang-1.13-buster and dubnium-buster), all of them being officially maintained by Docker

... the only "moving" part you have to trust is the Debian packages official repositories

## List of images

 * [homebridge server and a few plugins](https://github.com/dubo-dubon-duponey/docker-homebridge)
 * [logdna logspout](https://github.com/dubo-dubon-duponey/docker-logspout)
 * [AFP/timemachine server](https://github.com/dubo-dubon-duponey/docker-netatalk)
 * [roon player & roon bridge](https://github.com/dubo-dubon-duponey/docker-roon)
 * [airport receiver](https://github.com/dubo-dubon-duponey/docker-shairport-sync)

Work in progress:

 * [plex](https://github.com/dubo-dubon-duponey/docker-plex)
 * [ombi](https://github.com/dubo-dubon-duponey/docker-ombi)
 * [transmission](https://github.com/dubo-dubon-duponey/docker-transmission)

## Future

 * consider moving all dependencies to git submodules
 * aim for airgapped building (past obtaining the git clone)
 * investigate proxying debian repos
