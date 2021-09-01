# Docker Images

> Dubo, Dubon, Duponey - Desimages

All our images follow five core principles:

 1. support multiple architectures
 1. minimize runtime footprint/size
 1. have a solid security focus
 1. keep it simple
 1. predictable, observable

## Multi-arch

Our build system relies on cue, buildctl, qemu and buildkit.

To the largest possible extent, we do leverage cross-compilation (qemu is unstable in that context).

All our images provide a simple `./hack/build.sh` script to help you do so, with overrides for key elements of the build process (platforms selection, final image name, etc).

To the extent the underlying software actually compiles on it, we support arm6, arm7, arm64, 386, amd64, s390x and pcc64le.

That being said:
 * arm6, s390x, ppc64le, 386 are largely unused by us, and unlikely to receive much love beside fixing the build

## Footprint

### Multistage images

Images that actually require "building" anything are multistage and clearly separate "build" and "runtime" phases.
As such, our live images never carry around useless (eg: build) dependencies.

### Slim base distro

All of your images use a single base image (both for runtime and build), based on our debootstrapped version of Debian Bullseye.

While Alpine is certainly a very good distro and a reasonable choice, musl is still problematic in a number of cases,
and the community size and available packages are not up-to-par with Debian.

### Dependencies

Runtime dependencies are kept to the absolute minimum.

## Security 

### Reduced attack surface

As a consequence of our dependencies strategy and base distro choice.

### Dependencies pinning

All third-party software and their dependencies are pinned to a content addressable hash:

 * git-cloned-repos are always checked out to a specific commit hash
 * yarn packages are pinned to a specific git commit, and retrieved from github instead of npm (if required, we fork them and yarn lock their dependencies)
 * dependencies retrieved from casual urls are always downloaded and committed at a specific version alongside the Dockerfile - in such a case, a `refresh.sh` 
 script is provided so you can refresh them on your own

The "exception" to this rule is debian packages, which are pinned to specific versions (not content addressable).

### Build reproducibility

The above guarantees that builds are reproducible.

### Simplicity and audit-ability over fanciness

Entrypoint scripts are kept simple on purpose.
We do not package fancy init systems (like s6), monitoring tools, etc.

This of course comes at a cost - for example, there is no provision for recovering from a process crash (which will just exit the container).

We do believe such issues are best dealt with by your orchestrator, or other systems outside of the containers we provide.

### Trust model

As long as you pick a specific git commit from our images repo:

 * our images are straightforward to audit: looking at `Dockerfile`, `entrypoint` and `hack` files gives you a thorough understanding of what's going on
 * given all dependencies are pinned (in a content addressable fashion), you do not have to trust any third-party infrastructure or distribution mechanisms integrity
 * we only depend on our own base image for both runtime and buildtime which you can rebuild yourself would you like it to

... possible attack vectors would be:

 * a compromise of snapshot.debian.org, from which our base image is built
 * a compromise of Debian repositories and developpers gpg keys that would replace an existing package at a specific version with something different, and that would make its way into snapshot.debian.org

Henceforth you still have to trust that Debian snapshot maintainers (and overall package maintainers) secure their signing keys appropriately.

Of course, pinning softwares at a specific git commit does not give you guarantees that the content of it is "legit", just that it hasn't been modified after the fact.
You still have to audit and vet the content of said software, at said specific version.

### Runtime security

All images aim for:

 * run read-only (with explicit volumes for read-write access - eg: /certs, /data)
 * run as non-root (in some cases, downgrading at runtime through chroot)
 * run with no capabilities

## Observability & predictability

All images thrive at:

 * log to stdout and stderr
 * run a single process (exception for out of band ACME certificate retrieval and mDNS broadcasters)
 * have a HEALTHCHECK (some exceptions)
 * expose a (Prometheus) metrics endpoint (some exceptions)

## List of images

Base:
* [debian](https://github.com/dubo-dubon-duponey/docker-debian) (base debian image, debootstrapped from Debian repos)
* [base](https://github.com/dubo-dubon-duponey/docker-base) (base runtime and build images, on top of our Debian image)
* [tools](https://github.com/dubo-dubon-duponey/docker-tools)

Tooling:
* [Athens go proxy](https://github.com/dubo-dubon-duponey/docker-goproxy)
* [Docker registry](https://github.com/dubo-dubon-duponey/docker-registry)
* [Buildkit](https://github.com/dubo-dubon-duponey/docker-buildkit)
* [Apt Utils](https://github.com/dubo-dubon-duponey/docker-aptutil)
* [Aptly](https://github.com/dubo-dubon-duponey/docker-aptly)

Infrastructure:
* [Caddy](https://github.com/dubo-dubon-duponey/docker-caddy)
* [CoreDNS](https://github.com/dubo-dubon-duponey/docker-coredns)
* [Elastic](https://github.com/dubo-dubon-duponey/docker-elastic)
* [FileBeat](https://github.com/dubo-dubon-duponey/docker-filebeat)
* [Kibana](https://github.com/dubo-dubon-duponey/docker-kibana)
* [AFP/timemachine server](https://github.com/dubo-dubon-duponey/docker-netatalk)

Home and media:
* [HomeKit Alsa](https://github.com/dubo-dubon-duponey/docker-homekit-alsa)
* [HomeKit Wiz](https://github.com/dubo-dubon-duponey/docker-homekit-wiz)
* [Librespot](https://github.com/dubo-dubon-duponey/docker-librespot)
* [Plex](https://github.com/dubo-dubon-duponey/docker-plex)
* [Roon Server & Roon Bridge](https://github.com/dubo-dubon-duponey/docker-roon)
* [Airplay receiver](https://github.com/dubo-dubon-duponey/docker-airplay)


Under development:
* [Samba](https://github.com/dubo-dubon-duponey/docker-samba)
* [Snapcast](https://github.com/dubo-dubon-duponey/docker-snapcast)
* [Mongo](https://github.com/dubo-dubon-duponey/docker-mongo)
* [Parse](https://github.com/dubo-dubon-duponey/docker-parse)
* [Postgres](https://github.com/dubo-dubon-duponey/docker-postgres)
* [Rudder](https://github.com/dubo-dubon-duponey/docker-rudder)
* [Rudder-transformer](https://github.com/dubo-dubon-duponey/docker-rudder-transformer)
