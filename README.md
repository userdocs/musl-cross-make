# musl-cross-make custom builds

Multiarch cross builds to use with Alpine Linux based on https://git.zv.io/toolchains/musl-cross-make which delivers the builds on this website http://musl.cc

Please see the `config.mak` file in use [here](https://github.com/userdocs/musl-cross-make/blob/main/config.mak) - Using items [defined in this list](https://git.zv.io/toolchains/musl-cross-make/-/blob/master/scripts/triples.txt)

[Here is the action](https://github.com/userdocs/musl-cross-make/blob/main/.github/workflows/matrix-musl-cross-make-and-release.yml) that is [using these targets to build](https://git.zv.io/toolchains/musl-cross-make/-/raw/master/scripts/triples.txt)

Docker images also published and are available here - https://hub.docker.com/repository/docker/userdocs/mcm

```docker
userdocs/mcm:tagname
```