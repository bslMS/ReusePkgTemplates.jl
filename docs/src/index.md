```@meta
CurrentModule = ReusePkgTemplates
```

# ReusePkgTemplates.jl

`ReusePkgTemplates.jl` helps generate Julia package repositories that start with
REUSE/SPDX licensing metadata instead of retrofitting it later.

It builds on [PkgTemplates.jl](https://juliaci.github.io/PkgTemplates.jl/stable/)
and adds a REUSE-aware setup layer for file-level SPDX metadata, an outbound
package-level license declaration, generated `LICENSES/` content, `REUSE.toml`
annotations, `Project.toml` license metadata, and optional REUSE linting in GitHub Actions.

Use it when you want ordinary Julia package scaffolds, but with licensing policy
clearly declared from the first commit.

## Why this package exists

Julia package templates traditionally start from a root `LICENSE` file containing
a single license text. That is simple, but it does not scale well to repositories
containing source code, documentation, generated files, assets, data, and tooling
under possibly different licenses.

`ReusePkgTemplates.jl` makes the initial scaffold compatible with the
[REUSE](https://reuse.software/) convention: files carry machine-readable SPDX
metadata, file-level license texts are collected under `LICENSES/`, while the root
`LICENSE` file records the package-level license declaration and the supporting
license texts implied by that declaration.

## What it provides

- a REUSE-aware plugin for PkgTemplates.jl,
- a `with_reuse` convenience wrapper for composing ordinary PkgTemplates plugins,
- customization support for ReusePkgTemplates-owned templates through
  `write_templates` and `template_dir`,
- defaults for `REUSE.toml`, generated `LICENSES/` content, and package-level
  `LICENSE` and `Project.toml` metadata,
- optional GitHub Actions integration for REUSE linting.

## What it does not do

`ReusePkgTemplates.jl` is not a legal compatibility checker, a standalone SPDX
parser, or a repository license auditor. Those concerns belong in
[ReuseLicensing.jl](https://bsl-support.de/julia/ReuseLicensing.jl/) and in
ordinary legal review.

The package records licensing intent and generates reviewable metadata. It does
not prove that a package-level license declaration is compatible with every file,
dependency, or distribution context.

## Suggested reading path

Start with the [User Guide](@ref user-guide) to create a first template. Use the
[Licensing FAQ](@ref licensing-faq) for conceptual questions about package-level
declarations, file-level SPDX metadata, and REUSE layout. Use the
[API Reference](@ref api-reference) once you need precise constructor and keyword details.

## Status

The package is in active development. The initial API is intentionally small, but
may still change while practical template-generation workflows are refined.

## Index

```@index
```
