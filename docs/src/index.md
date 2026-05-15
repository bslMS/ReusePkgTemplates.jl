```@meta
CurrentModule = ReusePkgTemplates
```

# ReusePkgTemplates.jl

`ReusePkgTemplates.jl` provides a small convenience layer for creating
REUSE-compliant Julia package templates on top of
[PkgTemplates.jl](https://juliaci.github.io/PkgTemplates.jl/stable/).

It is intended for Julia projects that want package scaffolds with explicit SPDX
copyright and licensing metadata instead of relying on a single root `LICENSE`
file. The package keeps PkgTemplates.jl as the underlying template engine, while
adding REUSE-oriented defaults and helper functions.

The package is developed by [BSL Management Support](https://bsl-support.de) as
part of a broader commitment to transparent open source infrastructure, clear
licensing metadata, responsible software stewardship, and practical software
independence.

## Purpose

PkgTemplates.jl already provides the standard mechanism for generating Julia
package repositories. `ReusePkgTemplates.jl` does not replace it. Instead, it
wraps and extends the setup path for projects that want REUSE-compliant
repository metadata from the beginning.

The intended use is simple: create ordinary PkgTemplates.jl templates, but with a
REUSE-aware plugin set and project layout policy.

## Scope

`ReusePkgTemplates.jl` is intended to support:

- creating Julia package templates with REUSE-compliant licensing metadata,
- replacing the conventional single-license-file workflow with REUSE-oriented
  project generation,
- composing PkgTemplates.jl plugins with REUSE-specific plugins and defaults,
- generating package scaffolds that distinguish source code, documentation,
  assets, tests, and tooling files where appropriate,
- supporting consistent project setup across related Julia repositories.

The package is general Julia infrastructure. It is not specific to BSL Management
Support's modeling and simulation work.

## Non-goals

`ReusePkgTemplates.jl` is not a replacement for PkgTemplates.jl, and it is not a
standalone SPDX parser or repository license auditor. Expression parsing,
approval checks, and repository-level license analysis belong in
[ReuseLicensing.jl](https://bsl-support.de/julia/ReuseLicensing.jl/) and related
REUSE tooling.

## Status

The package is in active development. The initial API is intentionally small, but
may still change while practical template-generation workflows are refined.

## Installation

```julia
using Pkg
Pkg.add(url = "https://github.com/bslMS/ReusePkgTemplates.jl")
```

The source code and issue tracker are available in the
[GitHub repository](https://github.com/bslMS/ReusePkgTemplates.jl).

## Related projects

- [PkgTemplates.jl](https://juliaci.github.io/PkgTemplates.jl/stable/) provides
  the underlying Julia package template engine.
- [ReuseLicensing.jl](https://bsl-support.de/julia/ReuseLicensing.jl/) provides
  supporting infrastructure for REUSE- and SPDX-based licensing workflows.
- [REUSE](https://reuse.software/) defines the licensing metadata convention this
  package is designed to support.

## Index

```@index
```
