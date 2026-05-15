<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/src/assets/logo-dark.svg">
    <source media="(prefers-color-scheme: light)" srcset="docs/src/assets/logo.svg">
    <img src="docs/src/assets/logo.svg" alt="ReusePkgTemplates logo" width="56">
  </picture>
  ReusePkgTemplates.jl
</h1>

[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://bsl-support.de/julia/ReusePkgTemplates.jl/)
[![Build Status](https://github.com/bslMS/ReusePkgTemplates.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/bslMS/ReusePkgTemplates.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![SciML Code Style](https://img.shields.io/static/v1?label=code%20style&message=SciML&color=9558b2&labelColor=389826)](https://github.com/SciML/SciMLStyle)
[![REUSE status](https://img.shields.io/badge/REUSE-compliant-brightgreen.svg)](https://reuse.software/)

<p align="center">
  <a href="https://juliaci.github.io/PkgTemplates.jl/stable/">PkgTemplates.jl</a> ·
  <a href="https://bsl-support.de/julia/ReuseLicensing.jl/">ReuseLicensing.jl</a> ·
  <a href="https://reuse.software/">REUSE</a> ·
  <a href="https://github.com/bslMS/ReusePkgTemplates.jl/issues">Issues</a>
</p>

ReusePkgTemplates.jl provides a small convenience layer for creating
REUSE-compliant Julia package templates on top of PkgTemplates.jl. It is intended
for projects that want package scaffolds with explicit SPDX copyright and
licensing metadata instead of relying on a single root `LICENSE` file.

The package keeps PkgTemplates.jl as the underlying template engine, but replaces
the conventional license-file workflow with REUSE-oriented project generation.
Its purpose is to make REUSE-compliant Julia package setup easy, repeatable, and
consistent across repositories.

This package is under active development, and public APIs may still change.

## Installation

```julia
using Pkg
Pkg.add(url = "https://github.com/bslMS/ReusePkgTemplates.jl")
```

<!-- PkgTemplates: REUSE licensing section start -->
## Licensing

<img src="docs/src/assets/Logo_EUPL.svg" alt="EUPL logo" width="84" align="right">

Copyright © 2026 Guido Wolf Reichert and contributors

The source code in this project is licensed under the European Union Public Licence v1.2 or
later (`EUPL-1.2-or-later`).
The [EUPL v1.2](https://eur-lex.europa.eu/eli/dec_impl/2017/863/oj) was published in the
Official Journal of the European Union and is available in 23 official EU languages.

Documentation, related assets, project artifacts, and tooling files use separate license
expressions.

This project follows the [REUSE specification](https://reuse.software/spec/) for copyright
and licensing information. The authoritative license texts are stored in `LICENSES/`.
Copyright and license information for individual files is provided via SPDX headers and,
where applicable, via `REUSE.toml`.

Useful REUSE checks:

```bash
reuse lint
reuse spdx
```

<!-- PkgTemplates: REUSE licensing section end -->
