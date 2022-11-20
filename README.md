# SpaceTrack

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://benelsen.github.io/SpaceTrack.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://benelsen.github.io/SpaceTrack.jl/dev/)
[![Build Status](https://github.com/benelsen/SpaceTrack.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/benelsen/SpaceTrack.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/benelsen/SpaceTrack.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/benelsen/SpaceTrack.jl)

## Descriptions

This package is basically just a more convenient interface to the public space-track.org REST-ish API.

You require a set of credentials to use it. Please see [space-track.org website](https://www.space-track.org/) on how to create an account.

## Status

I just started to rewrite this from an earlier private implementation. 
The basics should work now, but before you see some documentation and that `1.0` release don't consider the interface stable.

- [x] login/logout
- [x] automatic state/cookie handling
- [x] basic request validation to catch gross errors
- [x] requests return parsed json
- [ ] documentation
- [ ] better handling of timed out sessions, request throttling etc.
- [ ] custom types for returned data
- [ ] pagination / automatic limits
- [ ] high-level interface for comon requests
- [ ] catching quirks of the API (like requesting too much data, predicates that don't work for certain queries
- [ ] `publicfiles` interface
- [ ] Tables.jl support
