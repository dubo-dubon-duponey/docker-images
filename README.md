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

All of your images use a single base image (both for runtime and build), based on our debootstrapped version of Debian Buster.
While Alpine is certainly a very good distro and a reasonable choice, musl is still problematic in a number of cases,
and the community size and available packages are not up-to-par with Debian.

### Dependencies

Runtime dependencies are kept to the absolute minimum.

## Security 

### Image integrity guarantees

XXXNOTTRUEYET All our images are signed using Docker Notary and published on Docker Hub, meaning that what you get from there is exactly 
what we built, signed and pushed, and cannot be tempered with.

Be sure to use `export DOCKER_CONTENT_TRUST=1` while pulling them.

Our build script also enforce `DOCKER_CONTENT_TRUST`, extending this guarantee to our base images at build time.

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

The above guarantees that builds are reproducible.

### Simplicity and audit-ability over fanciness

Entrypoint scripts are kept simple on purpose.
We do not package fancy init systems (like s6), monitoring tools, etc.

This of course comes at a cost - for example, there is no provision for recovering from a process crash (which will just exit the container).

We do believe such issues are best dealt with by your orchestrator, or other systems outside of the containers we provide.

### Trust model

As long as you pick a specific git commit from our images repo:

 * our images are straightforward to audit: looking at `Dockerfile`, `entrypoint` and `build` gives you a thorough understanding of what's going on
 * given all dependencies are pinned (in a content addressable fashion), you do not have to trust any third-party infrastructure or distribution mechanisms integrity
 * we only depend on our own base image for both runtime and buildtime which you can rebuild yourself would you like it to

... possible attack vectors would be:

 * a compromise of snapshot.debian.org, from which our base image is built
 * a compromise of Debian repositories and developpers gpg keys that would replace an existing package at a specific version with something different, and that would make its way into snapshot.debian.org

Henceforth you still have to trust that Debian snapshot maintainers (and overall package maintainers) secure their signing keys appropriately.

Of course, pinning softwares at a specific git commit does not give you guarantees that the content of it is "legit", just that it hasn't been modified after the fact.
You still have to audit and vet the content of said software, at said specific version.

### Runtime security

All images:

 * run read-only (with explicit volumes for read-write access - eg: /certs, /data)
 * run as non-root (in some cases, downgrading at runtime through chroot)
 * run with no capabilities

## Observability & predictability

All images thrive at:

 * log to stdout and stderr
 * run a single process (exception for out of band ACME certificate retrieval and Avahi daemons)
 * have a HEALTHCHECK (some exceptions)
 * expose a (Prometheus) metrics endpoint (some exceptions)

## List of images

 * [base](https://github.com/dubo-dubon-duponey/docker-base) (base runtime and build images, on top of our Debian image)
 * [Caddy](https://github.com/dubo-dubon-duponey/docker-caddy)
 * [CoreDNS](https://github.com/dubo-dubon-duponey/docker-coredns)
 * [Elastic](https://github.com/dubo-dubon-duponey/docker-elastic)
 * [FileBeat](https://github.com/dubo-dubon-duponey/docker-filebeat)
 * [Homebridge server and a few plugins](https://github.com/dubo-dubon-duponey/docker-homebridge)
 * [HomeKit Alsa](https://github.com/dubo-dubon-duponey/docker-homekit-alsa)
 * [Kibana](https://github.com/dubo-dubon-duponey/docker-kibana)
 * [Librespot](https://github.com/dubo-dubon-duponey/docker-librespot)
 * [AFP/timemachine server](https://github.com/dubo-dubon-duponey/docker-netatalk)
 * [Roon Server & Roon Bridge](https://github.com/dubo-dubon-duponey/docker-roon)
 * [Airport receiver](https://github.com/dubo-dubon-duponey/docker-shairport-sync)

## Future

### New images

 * [Plex](https://github.com/dubo-dubon-duponey/docker-plex)
 * [Ombi](https://github.com/dubo-dubon-duponey/docker-ombi)
 * [Transmission with protonvpn support](https://github.com/dubo-dubon-duponey/docker-transmission)

### Tier 1

 * [TODO] finish adding healthchecks for all images
 * [TODO] finish downgrading root for all images
 * [TODO] finish refactoring all images on top of base
 * [TODO] sign all images properly
 * [TODO] better handling of docker version detection to accommodate for future 20.x releases
 * [TODO] slim-fast HomeBridge
 * [TODO] a custom dyndns service
 * [INVESTIGATE] replace HomeBridge with https://github.com/brutella/hc (also look at https://www.npmjs.com/package/homebridge-http-base)

 * [HOMEBRIDGE] any armv7 image is broken when it comes to certificates - introduce a hack to either:
    * build the base-runtime image natively
    * or re-install ca-certificates on first-run at runtime
 * [HOMEBRIDGE] weather plus is busted

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
