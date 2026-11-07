<!--
SPDX-FileCopyrightText: 2026 Guido Wolf Reichert <gwr@bsl-support.de>
SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Contributing

ReusePkgTemplates.jl creates REUSE-compliant Julia package templates on top
of PkgTemplates.jl. Bug reports, documentation fixes, and small improvements
are welcome. Please discuss larger changes or new APIs in an issue first.

Keep pull requests focused. The maintainer may decline changes that fall
outside the package's scope or add too much maintenance work.

## Commit sign-off

Sign off every commit using the Developer Certificate of Origin (DCO):

```sh
git commit -s
```

This adds `Signed-off-by: Your Name <your.email@example.org>` to the commit
message and certifies your right to submit the contribution under the
applicable license.

## Licensing and REUSE

Contribute under the license of the file you modify. Julia source files
normally use `EUPL-1.2+`, documentation uses `CC-BY-SA-4.0`, and project
infrastructure uses `0BSD`. Follow the file's SPDX metadata where it differs.

New Julia source files should normally include:

```julia
# SPDX-FileCopyrightText: <YEAR> <YOUR NAME>
# SPDX-License-Identifier: EUPL-1.2+
```

All new files need copyright and license information through SPDX headers,
`.license` sidecars, or `REUSE.toml`, following the
[REUSE specification](https://reuse.software/spec/).

Keep shipped templates under `templates/*.mustache` covered by `REUSE.toml`.

Unless you are changing package-level licensing, leave the root `LICENSE`
and `[reuse_licensing]` table in `Project.toml` alone. Use
[ReuseLicensing](https://bslms.github.io/ReuseLicensing.jl/stable/) tooling for
package-level licensing changes so these declarations stay consistent.

## Code and tests

Add or update tests for code changes and documentation for changes to public
behavior. Keep unrelated formatting changes out of functional pull requests.

### Fatou tooling

Use **Fatou v0.25.0**, the version pinned in `.github/workflows/Fatou.yml`, for
canonical Julia formatting and static linting. Follow the official
[installation instructions](https://fatou.dev/installation.html) using your
preferred installation method. Fatou is development tooling, not a Julia
runtime dependency. `fatou.toml` sets a 92-character width, four-space
indentation, LF line endings, and the shared lint configuration.

From the repository root, verify your CLI version, format modified Julia code,
and run the same checks as CI:

```sh
fatou --version # expected: fatou 0.25.0
fatou format --safe .
fatou format --safe --check .
fatou lint .
```

Directory walks respect `.gitignore`, including generated documentation.
Review formatting changes, especially macros, comments, and string literals.
For awkwardly wrapped `@testitem` declarations, use equivalent parenthesized,
comma-separated arguments selectively, preserving names, tags, and setup.
Run the Julia tests as described in `AGENTS.md`; static linting does not
replace Julia/Kaimon runtime analysis or test execution.

The default lint rules remain enabled except `non-public-access`: the existing
implementation uses PkgTemplates' documented plugin interface and shared
ReuseLicensing helpers that are neither exported nor declared `public`.
An inline `unused-import` exception retains `@with_kw_noshow`, which
`PkgTemplates.@plugin` requires when expanding in the caller's scope.
The explicit `PkgTemplates` import lets Fatou resolve the module independently
of `@reexport`; it preserves the existing re-exports.

Fatou v0.25.0 has a known
[short-circuit guard formatting defect](https://github.com/jolars/fatou/issues/139):
it splits the multiline `&& return` in `add_julia_spdx_header`. We temporarily
accept that formatter output so the safe check stays enforced, without
rewriting correct Julia code or excluding the file. Once v0.25.1 is available,
verify the upstream fix, update the documented baseline and CI pin together,
reformat, and revisit this exception.

### Editors

See Fatou's official [editor setup](https://fatou.dev/guide/editors.html).
VS Code workspace recommendations include `jolars.fatou` and the Julia
extension. Workspace settings select Fatou for Julia formatting on save and
leave executable selection at the extension's default, which supports its
bundled binary. Use the baseline version for CLI checks even if an editor
extension bundles another version.

Fatou's language server supplies formatting, diagnostics, and navigation.
Keep the Julia extension for REPL, debugging, and testing, and retain Kaimon
for runtime work. Concurrent language servers can show duplicate diagnostics,
completion, or hover results. If that occurs, adjust the overlapping features
in personal settings (for example, `fatou.languageFeatures.enable` or
`julia.lint.run`); do not disable Julia runtime tooling. The workspace's
`editor.defaultFormatter` selects Fatou when multiple formatters are present.

## Documentation

Sources are in `docs/src/`; API documentation comes from Julia docstrings.

### Build locally

From the repository root:

```sh
julia --project=docs docs/make.jl
```

The script prepares the environment and builds HTML in `docs/build/`.
No deployment credentials are needed. Do not commit the generated files.

To preview:

```sh
python3 -m http.server 8000 --bind localhost --directory docs/build
```

Open <http://localhost:8000/>. Rebuild after edits and refresh the browser.
Stop the server with Ctrl+C.

### Publishing

GitHub Actions builds documentation for pull requests. Branches in this
repository also get previews at:

`https://bslms.github.io/ReusePkgTemplates.jl/previews/PR<number>/`

Fork pull requests are built without published previews. Contributors need
no SSH access or deployment credentials.

Pushes to `main` publish `/dev/`. Release tags matching `v*` publish versioned
documentation, with `/stable/` pointing to the latest release.

Closing or merging a PR removes its preview from `gh-pages`; the website
reflects the removal on the next Pages deployment.

### Maintainer setup

Configure GitHub Pages to serve `gh-pages` from `/ (root)`. Publishing uses
a write-enabled SSH deploy key stored as the `DOCUMENTER_KEY` Actions secret,
plus the automatically provided `GITHUB_TOKEN`. Never commit credentials.

The workflows are `.github/workflows/documentation.yml` and
`.github/workflows/doc-preview-cleanup.yml`.

## Third-party material

Record the source, copyright holder, license, and any modifications for
third-party images and other assets. Include readable attribution where
appropriate, for example in `docs/src/assets/ATTRIBUTION.md`.
