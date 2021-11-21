# musl-cross-make custom builds

Multiarch cross builds to use with Alpine Linux based on https://git.zv.io/toolchains/musl-cross-make which delivers the builds on this website http://musl.cc

Please see the `config.mak` file in use [here](https://github.com/userdocs/musl-cross-make/blob/main/config.mak) - `MATRIX_TARGET  ` is changed in the action from items [defined in this list](https://git.zv.io/toolchains/musl-cross-make/-/blob/master/scripts/triples.txt)

All I am doing is configuring my main cross targets and building them to archived releases to use with [qbittorrent-nox-static](https://github.com/userdocs/qbittorrent-nox-static)

- arm-linux-musleabihf
- armv7r-linux-musleabihf
- aarch64-linux-musl

[It's not a complicated action](https://github.com/userdocs/musl-cross-make/blob/main/.github/workflows/matrix-musl-cross-make-and-release.yml) 

