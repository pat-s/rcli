[![macOS-x86](https://github.com/pat-s/rcli/actions/workflows/main.yml/badge.svg)](https://github.com/pat-s/rcli/actions/workflows/main.yml)
[![CircleCI](https://circleci.com/gh/pat-s/rcli/tree/main.svg?style=svg)](https://circleci.com/gh/pat-s/rcli/tree/main) <img src="assets/logo.png" align="right" width = "250" />

`rcli` is a tool for simplified installion of R versions and switching between these.
It is written in `bash`, aims to be cross-platform and low on dependencies.

## Quickstart

Install via `homebrew` (on macOS):

```sh
brew tap pat-s/rcli
brew install rcli
```

Install the latest GitHub release:

```sh
curl -fLo /usr/local/bin/rcli $(curl -s https://api.github.com/repos/pat-s/rcli/releases/latest | grep "rcli" | awk '{print $2}' | sed 's|[\"\,]*||g' | grep "releases\/download")
chmod a+x /usr/local/bin/rcli
```

Install R release and devel versions and switch between them:

```sh
rcli install release
rcli install devel
rcli switch release
```

**Full documentation**: https://rcli.pat-s.me

Announcement blog post: https://pat-s.me/announcing-rcli/

An alternative to `rcli` is [r-lib/rim](https://github.com/r-lib/rim).
