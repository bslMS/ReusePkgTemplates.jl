<!--
SPDX-FileCopyrightText: 2026 Guido Wolf Reichert <gwr@bsl-support.de>
SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Contributing

ReusePkgTemplates.jl creates REUSE-compliant Julia package templates based on
PkgTemplates.jl. Bug reports, documentation fixes, and improvements are welcome.
Please discuss larger changes or new APIs in an issue first.

Keep pull requests focused and avoid unrelated changes.

Fork and clone the [GitHub repository](https://github.com/bslMS/ReusePkgTemplates.jl),
then create a branch for your changes. Run the commands below from the repository
root. Install the project dependencies with:

```sh
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

Open a pull request against `main`, describing the change and the validation
commands and results.

## Commit sign-off

Sign off every commit using the Developer Certificate of Origin (DCO):

```sh
git commit -s
```
This adds a `Signed-off-by` line certifying your right to contribute under the
applicable license.

## Licensing and REUSE

Follow the existing file licenses: Julia source normally uses `EUPL-1.2+`,
documentation `CC-BY-SA-4.0`, and project infrastructure `0BSD`.

New Julia source files should normally include:

```julia
# SPDX-FileCopyrightText: <YEAR> <YOUR NAME>
# SPDX-License-Identifier: EUPL-1.2+
```

All new files require copyright and license information through SPDX headers,
`.license` sidecars, or `REUSE.toml`, following the
[REUSE specification](https://reuse.software/spec/).

Keep shipped templates under `templates/*.mustache` covered by `REUSE.toml`.

Install the [REUSE tool](https://reuse.readthedocs.io/en/stable/readme.html#install)
and run `reuse lint` after adding files or changing licensing metadata.

Unless changing package-level licensing, leave the root `LICENSE` and
`[reuse_licensing]` in `Project.toml` unchanged. Use
[ReuseLicensing.jl](https://bslms.github.io/ReuseLicensing.jl/stable/)
for package-level licensing changes.

## Code and tests

Add regression tests for bug fixes and document changes to public behavior.
Use Julia 1.13 for development; the package supports Julia 1.10 and newer.
Test version-sensitive changes against both Julia 1.10 and the development version.

### Running tests

Run the complete suite using
[TestItemApp.jl](https://github.com/julia-testitems/TestItemApp.jl) when available:

```sh
juliati
```

To run an individual test item:

```sh
juliati --filter 'name == "test case has expected files and content"'
```

TestItemApp requires Julia 1.12 or newer. For Julia 1.10 or without TestItemApp, use:

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

Define tests with TestItems.jl's `@testitem`; TestItemRunner.jl runs them through
`test/runtests.jl`. Follow existing `WithTempdir` conventions for package-generation
tests, verifying generated file contents as well as existence.

### Fatou tooling

Use [Fatou](https://fatou.dev/) for canonical Julia formatting and static linting. 
Install the version pinned in `.github/workflows/Fatou.yml`, following the official 
[installation instructions](https://fatou.dev/installation.html).

The repository's `fatou.toml` defines formatting and lint rules, including
`safe = true`, which rejects malformed or unverifiable source during CLI and
LSP formatting.

From the repository root, run:

```sh
fatou --version
fatou format --safe .
fatou format --safe --check .
fatou lint .
```

Review formatting changes, particularly macros, comments, and strings. For poorly
wrapped `@testitem` declarations, selectively use equivalent parenthesized,
comma-separated arguments while preserving test metadata and behavior.

Justified lint exceptions are configured in `fatou.toml`. Document any additional
suppressions. Static linting does not replace Julia tests.

### Editors

Fatou provides formatting, diagnostics, and language-server features. See its
[editor setup guide](https://fatou.dev/guide/editors.html).

The official Julia VS Code extension is optional. Contributors may run Julia
independently, including through Kaimon. Fatou remains the designated formatter.

## Documentation

Documentation sources reside in `docs/src/`; API documentation comes from
Julia docstrings.

Build locally:

```sh
julia --project=docs docs/make.jl
```

Preview the generated documentation at <http://localhost:8000/> using:

```sh
python3 -m http.server 8000 --bind localhost --directory docs/build
```

Do not commit generated documentation.

GitHub Actions builds documentation for pull requests and publishes previews for
branches in this repository. Fork pull requests receive build checks without
published previews. Contributors need no deployment credentials.

## Third-party material

Document the source, copyright holder, license, and modifications of third-party
material. Include attribution where appropriate, for example in
`docs/src/assets/ATTRIBUTION.md`.
