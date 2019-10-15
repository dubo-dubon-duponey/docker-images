# Docker Images

> Dubo, Dubon, Duponey

All our images follow five core principles:

 1. support multiple architectures
 1. minimize runtime footprint/size
 1. have a solid security focus
 1. keep it simple
 1. predictable, observable

## Multi-arch

We strongly recommend using (and are using ourselves) "buildx" to build and push multi-architecture versions of our images.

All our images provide a simple `./build.sh` script to help you do so, with overrides for key elements of the build process (platforms selection, final image name, etc).

To the extent the underlying software actually compiles on it, we support arm6, arm7, arm64 and amd64.

 * arm6 is hit and miss, and is unlikely to receive much love
 * arm7 is still quite useful for Raspberry PI 3, albeit arm64 is preferred

## Footprint

### Multistage images

Images that actually require "building" anything are multistage and clearly separate "build" and "runtime" phases.
As such, our live images never carry around useless (eg: build) dependencies.

### Slim base distro

All of your images use a single base image (both for runtime and build): Debian (`buster-slim`) as a base - the only exception being nodejs projects (using a `dubnium-buster` base).
While Alpine is certainly a very good distro and a reasonable choice, musl is still problematic in a number of cases,
and the community size and available packages are not up-to-par with Debian.

### Dependencies

Runtime dependencies are kept to the absolute minimum.

## Security 

### Image integrity guarantees

XXXNOTTRUEYET All our images are signed using Docker Notary and published on Docker Hub, meaning that what you get from there is exactly 
what we built, signed and pushed, and cannot be tempered with.
Be sure to use `export DOCKER_CONTENT_TRUST=1` while pulling them.

Our build script also enforce `DOCKER_CONTENT_TRUST`, extending this guarantee to the base images at build time.

### Reduced attack surface

As a consequence of our dependencies strategy and base distro choice.

### Dependencies pinning

All third-party software and their dependencies are pinned to a content addressable hash:

 * git-cloned-repos are always checked out to a specific commit hash
 * yarn packages are pinned to a specific git commit, and retrieved from github instead of npm (if required, we fork them and yarn lock their dependencies)
 * dependencies retrieved from casual urls are always downloaded and committed at a specific version alongside the Dockerfile - in such a case, a `refresh.sh` 
 script is provided so you can refresh them on your own

The "exception" to this rule is deb packages, which are pinned to specific versions (not content addressable).

### Build reproducibility

The above guarantees that builds are reproducible, as long as:
 
 * the base image did not change
 * Debian packages have not been modified in place with the same version

### Simplicity and audit-ability over fanciness

Entrypoint scripts are kept simple on purpose.
We do not package fancy init systems (like s6), monitoring tools, etc.

This of course comes at a cost - for example, there is no provision for recovering from a process crash (which will just exit the container).

We do believe such issues are best dealt with by your orchestrator, or other systems outside of the containers we provide.

### Trust model

As long as you pick a specific git commit from our images repo:

 * our images are straightforward to audit: looking at `Dockerfile`, `entrypoint` and `build` gives you a thorough understanding of what's going on
 * given all dependencies are pinned (in a content addressable fashion), you do not have to trust any third-party infrastructure or distribution mechanisms integrity
 * we only depend on two base images at both runtime and buildtime (buster and dubnium-buster) which are officially maintained by Docker

... possible attack vectors would be:

 * a compromise of Debian repositories and developpers gpg keys that would replace an existing package at a specific version with something different
 * a compromise of Docker official images notary keys and hub account, that would replace one of the base images we depend on with something different
 * a compromise of Debian distribution infrastructure, with a target downgrade attack pushing older (signed) versions of packages with known vulnerabilities

Henceforth you still have to trust that Debian package maintainers and Docker official images team do secure their signing keys appropriately, and to a lesser extent
that the Debian distribution infrastructure is not compromised.

Of course, pinning softwares at a specific git commit does not give you guarantees that the content of it is "legit", just that it hasn't been modified after the fact.
You still have to audit and vet the content of said software, at said specific version.

### Runtime security

All images:

 * run read-only (explicit volumes for rw - eg: /certs, /data)
 * run as non-root (exception being Avahi daemons)
 * run with no capabilities

## Observability & predictability

All images:

 * log to stdout and stderr
 * run a single process (exception for out of band ACME certificate retrieval and Avahi daemons)
 * have a HEALTHCHECK
 * expose a (Prometheus) metrics endpoint

## List of images

 * [base](https://github.com/dubo-dubon-duponey/docker-base) (base runtime and build images, on top of Debian buster-slim)
 * [Caddy](https://github.com/dubo-dubon-duponey/docker-caddy)
 * [CoreDNS](https://github.com/dubo-dubon-duponey/docker-coredns)
 * [FileBeat](https://github.com/dubo-dubon-duponey/docker-filebeat)

 * [homebridge server and a few plugins](https://github.com/dubo-dubon-duponey/docker-homebridge)
 * [logdna logspout](https://github.com/dubo-dubon-duponey/docker-logspout)
 * [AFP/timemachine server](https://github.com/dubo-dubon-duponey/docker-netatalk)
 * [roon player & roon bridge](https://github.com/dubo-dubon-duponey/docker-roon)
 * [airport receiver](https://github.com/dubo-dubon-duponey/docker-shairport-sync)

## Future

### New images

 * [plex](https://github.com/dubo-dubon-duponey/docker-plex)
 * [ombi](https://github.com/dubo-dubon-duponey/docker-ombi)
 * [transmission with protonvpn support](https://github.com/dubo-dubon-duponey/docker-transmission)

### Tier 1

 * [TODO] finish adding healthchecks for all images
 * [TODO] finish downgrading root for all images
 * [TODO] finish refactoring all images on top of base
 * [TODO] sign all images properly
 * [TODO] better handling of docker version detection to accommodate for future 20.x releases
 * [TODO] slim-fast HomeBridge
 * [TODO] a custom dyndns service
 * [INVESTIGATE] replace HomeBridge with https://github.com/brutella/hc

### Tier 2

 * [BUG] find a solution for docker UDP routing problem
 * [BUG] find a way to reuse images in cache over different builds instead of pushing everything
 * [BUG] roon core and bridges still loose their id when a new container is started
 * [BUG] roon sometimes doesn’t get the mojo… because of airport competing? or because the mojo is off? polling?
 * [BUG] redo sound testing and convolution filters with all supported configurations, including mono

 * [TODO] finish bluetooth
 * [INVESTIGATE] consider moving all dependencies to git submodules instead
 * [INVESTIGATE] investigate proxying Debian repos
 * [INVESTIGATE] consider pinning base Debian image to a specific sha
 * [INVESTIGATE] VPN
    * maybe everything is vpn-ed (inc. rasp)
    * find a VPN solution for roon
    * wireguard or https://github.com/stellarproject/guard
 * [INVESTIGATE] aim for air-gap building (past obtaining the git clone)
 * [INVESTIGATE] CoreDNS: make it possible to choose HTTP-01 challenge for certificates?
 * [INVESTIGATE] rethink init strategy https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/
