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
[![REUSE](https://github.com/bslMS/ReusePkgTemplates.jl/actions/workflows/REUSE.yml/badge.svg?branch=main)](https://github.com/bslMS/ReusePkgTemplates.jl/actions/workflows/REUSE.yml?query=branch%3Amain)

<p align="center">
  <a href="https://juliaci.github.io/PkgTemplates.jl/stable/">PkgTemplates.jl</a> ·
  <a href="https://bsl-support.de/julia/ReuseLicensing.jl/">ReuseLicensing.jl</a> ·
  <a href="https://reuse.software/">REUSE</a> ·
  <a href="https://github.com/bslMS/ReusePkgTemplates.jl/issues">Issues</a>
</p>

ReusePkgTemplates.jl provides a small convenience layer for creating
REUSE-compliant Julia package templates on top of PkgTemplates.jl. It is intended
for projects that want package scaffolds with explicit file-level SPDX copyright
and licensing metadata, together with an outbound package-level license
declaration in the root `LICENSE` file.

The package keeps PkgTemplates.jl as the underlying template engine, but replaces
the conventional license-file workflow with REUSE-oriented project generation.
Its purpose is to make REUSE-compliant Julia package setup easy, repeatable, and
consistent across repositories.

This package is under active development, and public APIs may still change.

## Installation

```julia
using Pkg
Pkg.add("ReusePkgTemplates")
```

## Quick Start

### Generate a REUSE-aware package

Use `with_reuse` around the PkgTemplates plugins you want to enable. It disables PkgTemplates' conventional `License` plugin and adds REUSE-oriented files and metadata.

```julia
using ReusePkgTemplates

plugins = with_reuse([
        Git(; manifest = true, ssh = true),
        GitHubActions(; x86 = true),
        Codecov()
    ];
    package_license = "EUPL-1.2+",
    code_license = "MIT",
    docs_license = "CC-BY-4.0",
    infrastructure_license = "0BSD",
    readme_license_section = true
)

t = Template(;
    user = "your-github-user",
    authors = "Your Name <you@example.org>",
    dir = ".",
    plugins
)

t("MyPackage")
```

This generates a package with REUSE metadata, a package-level `LICENSE`, file-level license texts in `LICENSES/`, REUSE annotations in `REUSE.toml`, `Project.toml` licensing metadata, a README licensing section, and a REUSE lint workflow when `GitHubActions()` is used.

### Bring your own templates

Simply write the standard REUSE templates into a directory, adapt the files to your needs, and point the plugin generator to the template directory:

```julia
write_templates("reuse_templates")

plugins = with_reuse(;
    template_dir = "reuse_templates",
    package_license = "EUPL-1.2+"
)
```

You can do this selectively, `with_reuse` will fallback to the standard template whenever a template file is missing in the given directory.

---

For a more detailed overview, please refer to the [documentation](https://bsl-support.de/julia/ReusePkgTemplates.jl/).

<!-- PkgTemplates: REUSE licensing section start -->
## Licensing

<img src="docs/src/assets/Logo_EUPL.svg" alt="EUPL logo" width="84" align="right">

Copyright © 2026 Guido Wolf Reichert and contributors

This package is distributed under the European Union Public Licence v1.2 or
later (`EUPL-1.2+`). See `LICENSE` for details. The
[EUPL v1.2](https://eur-lex.europa.eu/eli/dec_impl/2017/863/oj) was published in the
Official Journal of the European Union and is available in 23 official EU languages.

This package-level statement declares the outbound license expected to apply when the
package code is loaded and used in the ordinary Julia package sense, for example by
`using ReusePkgTemplates` in a Julia session. Documentation, documentation assets,
generated project metadata, project infrastructure files, and other non-code files may use
separate license expressions.

This project follows the [REUSE specification](https://reuse.software/spec/) for file-level
copyright and licensing information. Copyright and license information for individual files
is provided via SPDX headers and, where applicable, via `REUSE.toml`. The corresponding
file-level license texts are stored in `LICENSES/`.

Useful REUSE checks:

```bash
reuse lint
reuse spdx
```

> Note: The recorded Manifest.toml files, where provided under `.licensing/manifests/`,
> document resolved dependency closures at the time of publication. They support the
> package-level licensing record for the distribution,but they do not determine every
> possible closure that may arise under other Julia versions, platforms, dependency
> resolutions, extensions, artifacts, load paths, or user modifications.
<!-- PkgTemplates: REUSE licensing section end -->
