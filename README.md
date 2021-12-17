# rcli

[![rcli-macOS-x86](https://github.com/pat-s/rcli/actions/workflows/main.yml/badge.svg)](https://github.com/pat-s/rcli/actions/workflows/main.yml)
[![CircleCI](https://circleci.com/gh/pat-s/rcli/tree/main.svg?style=svg)](https://circleci.com/gh/pat-s/rcli/tree/main)
[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/patrickschratz)

**DISCLAIMER: If you find this shortly after the repo went public, please don't share it yet - I still need to test some things - thanks!**

`rcli` is a tool for simplified installion of R versions and switching between these.
It is written in `bash`, aims to be cross-platform and low on dependencies.

## Motivation

Having multiple R versions installed and switching between such is currently a tedious task on any operating system.

On **Windows**, one can install multiple versions though switching between these is not straighforward.

On **macOS**, users can only install one version of an R minor version (e.g. 4.1).
Switching is possible by using the third-party tool [`rswitch`](https://github.com/hrbrmstr/RSwitch).
By default, users are allowed to install packages into the system library.

On **Linux**, users mostly depend on how quickly their distribution moves and brings in new R versions.
If one wants additional versions, R needs to be installed from source into a custom location.
Switching is not easily possible.
By default, users are not allowed to install packages into the system library.

Tools like RStudio Workbench make this easier though they require a paid license.
Since the launch of [`renv`](https://rstudio.github.io/renv/), users aim to make their projects reproducible.
This includes using the respective R version which was used for the project initially.
However, in practice, people are always forced to bump this as they only have one (and most often a more recent) R version installed.

`rcli` aims to solve these issues by providing

- a unified way to install any R version on any major operating system
- a simple way to switch between installed R versions without loosing the packages of the respective version


## Platform support

The following platforms/distributions are currently supported:

- macOS - `x86_64` and `arm64`
- Ubuntu `x86_64`
- CentOS 7 and CentOS 8 `x86_64`
- Fedora `x86_64`
- ~~Windows~~ (planned)

## Installation

### macOS

`rcli` can be installed via `homebrew`:

```sh
brew tap pat-s/rcli
brew install rcli
```

### Linux

`rcli` can be installed by downloading the latest version of the binary from GitHub:

```sh
curl -fLo /usr/local/bin/rcli https://github.com/pat-s/rcli/releases/download/v0.1.0-alpha/rcli
chmod a+x /usr/local/bin/rcli
```

`rcli` requires the following libraries to be installed.
Most of these should already be installed by default in the respective distributions.

- wget
- sudo
- dpkg (Ubuntu)
- lsb_release
- awk
- grep

`rcli` might eventually be added to the official repositories of the respective distributions at some point in the future.

## Usage

```sh
Usage: rcli [-h] [-v] [subcommand] <R version> [--arch ARCHITECTURE]

Available commands:
    install     Install an R version
    switch      Switch between installed R versions
    list        List installed R versions
```

## FAQ

<details>
<summary>What is the oldest R version that can be installed?</summary>

For macOS: R 3.4.0

For Linux platforms which support binaries: R 3.0.0

For Linux platforms which require source installations: Any version in principle (if it compiles successfully).

</details>

<details>
<summary>How does <code>rcli</code> relate to <code>rswitch</code>?</summary>

`rcli` was inspired by `rswitch` but is otherwise not affiliated with `rswitch` in any way.

</details>

<details>
<summary>Do I need to install every R version from source on Linux?</summary>

No. `rcli` makes use of the R binaries from [rstudio/r-builds](https://github.com/rstudio/r-builds) for the respective underlying distribution.

</details>

<details>
<summary>Does <code>rcli</code> install all dependencies needed on Linux to run R?</summary>

No, `rcli` assumes that all runtime dependencies are installed.
The easiest way to do so is to install the respective distribution packages first (e.g. `r-base-core` on Ubuntu or `R` on Fedora) so that all dependencies are installed and then invoke `rcli` to install custom versions.

</details>

<details>
<summary>Are devel versions supported?</summary>

Yes.
Devel versions can be installed via `rcli install devel`.
Internally they will be stored and labelled following their semantic version.

</details>

### macOS

<details>
<summary>Will I still be able to use binary packages on macOS?</summary>

Yes, `rcli` installs the official CRAN R releases which support the use of CRAN macOS binaries.

</details>

<details>
<summary><code>radian</code> does not seem to work with <code>x86_64</code> R installations.</summary>

`radian` is a Python library and built for the `arm64` architecture.
Hence, it can only work with the R `arm64` installations.

To use `radian` with an `x86_64` installation of R, Python for `x86_64` would need to be installed (including `radian`).

</details>

<details>
<summary>I have a M1 - can I still install R for <code>x86_64</code> systems?</summary>

Yes, `x86_64`  is supported by macOS via the "Rosetta 2" translation environment.
By default, `rcli` will install the `arm64` version of R if one is available (>= v4.1.0).
Otherwise the `x86_64` version will be installed.

To force the installation of `x86_64` versions, pass the `--arch x86_64` flag to `rcli install`.

</details>

<details>

<summary>I have a M1 - do I need to be aware of something?</summary>

On a M1 machine one can install both the `arm64` and `x86_64` versions of R (the latter supported via Rosetta).
If you do so and plan to switch between both architectures, it is recommended **not** to use `ccache` to speed up source installations as the cache created by one of the respective R interpreters will also attempted to be used for the respective other architecture.
This will not work and lead to loading failures during load-time, i.e. when calling `library(<package>)`.

</details>

<details>
<summary>The official macOS installation instructions from CRAN say that only one patch version per minor release can be installed. Is this also true for <code>rcli</code>?</summary>

No, `rcli` enables you to install and switch (between) any patch version of an R minor version (e.g. 4.1.1 and 4.1.2).

</details>

<details>
<summary>How does <code>rcli</code> actually work?</summary>

`rcli` installs the selected R version via the CRAN installer and moves it to `/opt/R`.
When switching, `rcli` first backs up the current active version and copies it to `/opt/R/<R version>`.
Next, the target R version is moved from `/opt/R/<R version>` to `/Library/Frameworks/R.framework` where the active R version lives.

Unfortunately many paths in the R CRAN installer on macOS are hardcoded and R won't work if it does not live in this particular path.
Hence, every time an R version is switched, there is some copying happening which is why switching takes some seconds.

Also `rcli` takes care of maintaining the R system library because by default user packages are installed there and these should not get lost when switching.

</details>

### Ubuntu


</details>

<details>
<summary>Does <code>rcli</code> support non-LTS releases?</summary>

Yes, if no RStudio binary is available, `rcli` will attempt to install R from source.

</details>
