# rcli

`rcli` is a tool for simplified installing and switching between R versions.

The following platforms/distributions are currently supported:

- macOS - `x86_64` and `arm64`
- Ubuntu `x86_64`

## Installation

### macOS

`rcli` can be installed via `homebrew`:

```sh
brew tap pat-s/rcli
brew install rcli
```

### Ubuntu

`rcli` can be installed by downloading the binary from the GitHub release:

```sh
curl -fLo /usr/local/bin/rcli https://github.com/pat-s/rcli/raw/main/rcli
chmod a+x /usr/local/bin/rcli
```

## FAQ

<details>
<summary>What is the oldest R version that can be installed</summary>

For macOS: R 3.4.0
For Ubuntu:

</details>

<details>
<summary>How does `rcli` relate to `rswitch`?</summary>

`rcli` was inspired by `rswitch` but is otherwise not affiliated with `rswitch` in any way.

</details>

### macOS

<details>
<summary>Will I still be able to use binary packages on macOS?</summary>

Yes, `rcli` installs the official CRAN R releases which support the use of CRAN macOS binaries.

</details>

<details>
<summary>`radian` does not seem to work with `x86_64` R installations.</summary>

`radian` is a Python library and built for the `arm64` architecture.
Hence, it can only work with the R `arm64` installations.

To use `radian` with an `x86_64` installation of R, Python for `x86_64` would need to be installed (including `radian`).

</details>

<details>
<summary>I have a M1 - can I still install R for `x86_64` systems?</summary>

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
<summary>The official macOS installation instructions from CRAN say that only one patch version per minor release can be installed. Is this also true for `rcli`?</summary>

No, `rcli` enables you to install and switch (between) any patch version of an R minor version (e.g. 4.1.1 and 4.1.2).

</details>

### Ubuntu
