```@meta
CurrentModule = ReusePkgTemplates
```

# [User Guide](@id user-guide)

This User Guide assumes that you are already comfortable using PkgTemplates.jl for creating
Julia packages. Before reading on, this may be a good time to review that package's
[User Guide](https://juliaci.github.io/PkgTemplates.jl/stable/user/). Here is a short
refresher.

## The Package Templating Workflow

To generate your package in a directory `dir` of your choice you need to declare a
`PkgTemplates.Template`. A `Template` is configured with keyword arguments.

```julia
# PkgTemplates-Workflow

t = Template(;
    USER_OPTIONS...,
    PACKAGE_OPTIONS...,
    plugins = [PLUGIN_1, PLUGIN_2, ...]
)

t("PACKAGE-NAME") # generates the package under that name in `dir`
```

Let's look at these parts:

- `USER_OPTIONS`: Let you provide a GitHub `user` and `authors` for the package.
- `PACKAGE_OPTIONS`: Allow you to give a directory `dir` to place the package in, a `host`
  URL for the hosting service, and a `julia` minimum-allowed version number.
- `plugins`: A vector of plugins. These are the "workhorses" that generate files
  and _do_ stuff in `prehook`, `hook`, and `posthook` phases, sequenced according to
  a given `precedence`, e.g., `git` typically comes last in the `posthook` phase.

That process remains intact, all you have to remember is that `with_reuse`
composes your plugin vector with the `Reuse` plugin:

```julia
# ReusePkgTemplates-Workflow
t = Template(;
    USER_OPTIONS...,
    PACKAGE_OPTIONS...,
    plugins = with_reuse([PLUGIN_1, PLUGIN_2, ...]; kwargs...)
)

t("PACKAGE-NAME") # generates the package under that name in `dir`
```

As you can see, all we need to address are the keyword arguments of `with_reuse`.
These are identical to those of the `Reuse` plugin. Most users should configure
`Reuse` through `with_reuse`.

In the following, we will group keyword arguments for better parsing and discussion.

## Package-Level Copyright Holders

```julia
copyright_holders::Union{Vector{<:AbstractString}, Nothing} = nothing
```

Typically, when you are freshly creating a package, chances are that the package
`authors` are also the copyright holders. So that value is what the argument will
default to.

But if the authors are working for a company or some other legal entity or if the
authors have transferred their copyright to a third party, then copyright holders may
differ from authors.

!!! note "Copyright Holders Refer to the Package as a Whole"
    The `Reuse` plugin assumes that the authors are copyright holders of the package's
    source code files and thus SPDX file copyright notes will default to the `authors`.
    The `copyright_holders` enter the `COPYRIGHT_NOTICE` of the `Reuse` plugin view and
    will be listed in the copyright notice of the `LICENSE` file and in the
    `package_copyright_notice` field of the `[reuse_licensing]` table in `Project.toml`.

The `COPYRIGHT_NOTICE` in the `Reuse` plugin `view` function for rendering templates will
have the following form:

```
Copyright © {{{YEAR}}} {{{COPYRIGHT_HOLDERS}}}
```

Here `COPYRIGHT_HOLDERS` will be nicely rendered with the last name preceded by an
"and" using the Oxford comma. The same formatting is used for multiple `authors` in
file-level and `REUSE.toml` templates.

## License Expressions and License Domains

```julia
package_license::Union{AbstractString, Nothing} = nothing,
code_license::Union{AbstractString, Nothing} = nothing,
infrastructure_license::Union{AbstractString, Nothing} = nothing,
docs_license::Union{AbstractString, Nothing} = nothing,
docs_assets_license::Union{AbstractString, Nothing} = nothing
```

In the default case, `package_license` will default to `MIT` and the `code_license` will
default to the `package_license`. Furthermore, `infrastructure_license` and `docs_license`
will default to the `code_license`, while `docs_assets_license` will default to the
`docs_license`.

Therefore generating a REUSE-compliant package with an `MIT` license for everything just
requires this:

```julia
plugins = with_reuse()
t = Template(; plugins)
```

As with PkgTemplates itself, this short form assumes that the relevant Git
configuration is available; otherwise pass `user` and `authors` explicitly to
`Template`.

### SPDX License Expressions

If you want another license than `MIT` or separate licenses for different domains, you
need to provide a valid
[SPDX license expression](https://spdx.github.io/spdx-spec/v2.3/SPDX-license-expressions/)
for the keyword argument of the addressed license domain. Very often such an expression
will just consist of a single SPDX license identifier, e.g., `MIT`, `Apache-2.0`.

The rules are as follows:

- Use SPDX license identifiers and expressions such as `MIT`, `Apache-2.0`,
  `GPL-3.0-or-later`, or `MIT OR Apache-2.0`.
- Deprecated GNU-style identifiers such as `GPL-3.0` and `GPL-3.0+` are accepted
  as a convenience and normalized to modern SPDX identifiers such as `GPL-3.0-only` and
  `GPL-3.0-or-later`.
- A trailing `+` may be used for "or later" style expressions where applicable,
  e.g., `EUPL-1.2+`.
- Custom license texts may be referenced with `LicenseRef-...` identifiers. The
  corresponding text must be provided in `license_ref_dir`.

`Reuse` will write parsed and normalized SPDX expressions to `REUSE.toml` or as part of
a file's explicit SPDX notice. License and exception texts implied by all given license
expressions are copied to `LICENSES/` and — for the `package_license` expression to
`LICENSE`. The texts are provided by
[`ReuseLicensing.jl`](https://bsl-support.de/julia/ReuseLicensing.jl/), which ships a
versioned snapshot of the SPDX License List data.

### License Domains

To understand the following, please read the sections on [inbound](@ref inbound-licensing)
and [outbound](@ref outbound-licensing) in the [Licensing FAQ](@ref licensing-faq) section.

#### File-Level Licensing Domains

Each of the files in your package directory will — at least initially — belong to exactly
one of the following _licensing domains_:

- Code: the source code for your package, which will typically consist of all `.jl` files
  in `src/`, `test/` or `benchmark/`.
- Infrastructure: project metadata and infrastructure files, e.g., CI or `.toml` files.
- Documentation: `.md` files that are used by `documenter.jl` to produce the
  documentation, including the `README.md`.
- Documentation assets: files with images and other content, which will typically appear
  in the documentation.

To see what this concretely amounts to, let's look at an excerpt from the bundled
`REUSE.toml.mustache` template:

```toml
[[annotations]]
path = [
    ".gitattributes",
    ".gitignore",
    ".github/**",
    ".vscode/**",
    ".licensing/**",
    ".drone.star",
    ".JuliaFormatter.toml",
    ".codecov.yml",
    ".*.yml",
    "CITATION.bib",
    "CODEOWNERS",
    "Project.toml",
    "Manifest.toml",
    "docs/make.jl",
    "docs/Project.toml",
    "docs/Manifest.toml",
    "test/Project.toml",
    "test/Manifest.toml"
]
precedence = "closest"
SPDX-FileCopyrightText = "{{{YEAR}}} {{{AUTHORS}}}"
SPDX-License-Identifier = "{{{INFRASTRUCTURE_LICENSE}}}"
SPDX-FileComment = "This file is generated, project metadata, or other project infrastructure."

[[annotations]]
path = ["docs/src/assets/**"]
precedence = "closest"
SPDX-FileCopyrightText = "{{{YEAR}}} {{{AUTHORS}}}"
SPDX-License-Identifier = "{{{DOCS_ASSETS_LICENSE}}}"
SPDX-FileComment = "This file is content for the documentation."

[[annotations]]
path = [
    "{{{README}}}",
    "docs/*.md",
    "docs/src/**/*.md"
]
precedence = "closest"
SPDX-FileCopyrightText = "{{{YEAR}}} {{{AUTHORS}}}"
SPDX-License-Identifier = "{{{DOCS_LICENSE}}}"
SPDX-FileComment = "This file is a documentation source file."
```

#### Package-Level or Outbound Domain

We already touched upon the package-level copyright notice. It will be coupled with the
package-level license expression given by `package_license`. While it often may coincide
with the `code_license` expression, that may not hold in general.

The file-level license expressions do not have to be identical to the package-level
license expression. For example, individual source files may be licensed under `MIT`,
while the package-level declaration may need to be stricter because the distributed
package is intended to be used together with dependencies under stronger terms. Thus, the
`Reuse` plugin will separately copy all required license texts, as referenced by your
package-level license declaration, into the `LICENSE` file in your package root.

## License Approval Policies

```julia
license_policy::Symbol = :general_registry
```

ReusePkgTemplates validates license expressions according to a configurable policy.
Accordingly, `with_reuse` has a `license_policy` argument, which must be one of the
following symbols: `:general_registry`, `:osi_approved`, `:free`, or `:none`.

- `license_policy = :general_registry` requires that `package_license` and `code_license`
  expressions have an
  [unconjoined OSI-approved path](https://bsl-support.de/julia/ReuseLicensing.jl/approval/#ReuseLicensing.UnconjoinedOSIApproval).
  For the safest General Registry registration path, use a single OSI-approved
  license for `package_license`, without `AND`, `OR`, `WITH`, or `LicenseRef-...`.

  All other license expressions must either have an unconjoined OSI-approved or an
  [open content path](https://bsl-support.de/julia/ReuseLicensing.jl/approval/#ReuseLicensing.OpenContentApproval).

- `license_policy = :osi_approved` requires that all license expressions have an
  [OSI-approved path](https://bsl-support.de/julia/ReuseLicensing.jl/approval/#ReuseLicensing.OSIApproved).
  Under this policy a conjunction of OSI-approved licenses is admissible.

- `license_policy = :free` requires that `package_license` and `code_license` expressions
  have an
  [OSI-approved path](https://bsl-support.de/julia/ReuseLicensing.jl/approval/#ReuseLicensing.OSIApproved),
  and that non-code expressions either have an OSI-approved or an
  [FSF libre](https://bsl-support.de/julia/ReuseLicensing.jl/approval/#ReuseLicensing.FSFLibre)
  approved path.

- `license_policy = :none` requires valid SPDX license expressions that may contain custom
  `LicenseRef-...` identifiers.

!!! note "General Registry Approval"
    The `:general_registry` approval is by no means a guarantee for an admissible format
    to Julia's General Registry registration. It is the author's best attempt at helping to
    shape a REUSE-compliant repository in such a way that it will likely receive a
    favorable review.

## Bring Your Own Templates

```julia
license_ref_dir::Union{AbstractString, Nothing} = nothing,
template_dir::Union{AbstractString, Nothing} = nothing
```

ReusePkgTemplates bundles the following template files:

- `README_licensing_section.md.mustache`: a template for an optional `## Licensing` section
  that will be appended to a project's `README.md` file.
- `REUSE.toml.mustache`: a template for configuring the REUSE specific
  `REUSE.toml` file.
- `REUSE.yml.mustache`: a template for an optional REUSE linting workflow as part
  of the GitHub Actions workflow.

You can use [`write_templates`](@ref) to write these files to a directory. You can edit
these files to your own liking and provide them for a package `Template` by passing the
directory to `template_dir`.

!!! note "Template File Rules"
    You may create different directories for different generation profiles, but you must
    use the exact filename given above. For any template file that is required by the
    plugin, `Reuse` will fall back to a bundled version, if the template's filename is
    not found in a given `template_dir`. All `.mustache` files are rendered, even if the
    bundled version contains no Mustache slots.

Another place where templates may be needed is custom `LicenseRef-...` license identifiers
used in any of the given license expressions. The following configuration requires that
the user provides either `LicenseRef-Proprietary-1.0.txt` or
`LicenseRef-Proprietary-1.0.txt.mustache` in the directory `MyLicenses/`.

```julia
code_license = "LicenseRef-Proprietary-1.0",
license_ref_dir = "MyLicenses"
```

The `view` function of the `Reuse` plugin will provide the following replacements for
`Mustache` template slots:

- `PKG`: the package name used when the `Template` is generated.
- `COPYRIGHT_HOLDERS`: a preconfigured string built from the vector of `copyright_holders`.
- `YEAR`: a string providing `year(today())` from the `Dates.jl` package.
- `AUTHORS`: a preconfigured string built from `authors`.
- `PACKAGE_LICENSE`: the normalized license expression from `package_license`.
- `INFRASTRUCTURE_LICENSE`: the normalized license expression from
  `infrastructure_license`.
- `DOCS_LICENSE`: the normalized license expression from `docs_license`.
- `DOCS_ASSETS_LICENSE`: the normalized license expression from `docs_assets_license`.
- `PACKAGE_LICENSE_FILE`: the package-level license file, i.e., `LICENSE`.
- `README`: the destination given by the `Readme` plugin or else `README.md`.
- `REUSE_SPECIFICATION_VERSION`: the result of
  [`ReuseLicensing.reuse_specification_version()`].
- `SPDX_LICENSE_LIST_VERSION`: the result of
  [`ReuseLicensing.spdx_license_list_version()`].

!!! note "Templates Owned by ReuseLicensing.jl"
    To keep the package-level licensing contract clear and unambiguous, the
    `Project.toml.metadata.mustache` and the `LICENSE.mustache` templates are owned by
    `ReuseLicensing.jl`. They cannot be changed by users.

## Optional Tasks

```julia
enable_reuse_lint::Bool = true,
readme_licensing_section::Bool = false
```

ReusePkgTemplates adds a separate REUSE lint GitHub Actions workflow by default
when the `GitHubActions` plugin is present.

The following content is appended to the destination of the `Readme` plugin, which will
typically be `README.md` in the root directory of the package.

~~~md
## Licensing

This package's authoritative package-level license expression, copyright notice,
and corresponding license texts are recorded in [`LICENSE`](LICENSE).

Machine-readable package licensing metadata is recorded in the `[reuse_licensing]`
table of [`Project.toml`](Project.toml).

Individual files may carry separate file-level license expressions, as recorded by their
SPDX notices or by [`REUSE.toml`](REUSE.toml). This project follows the
[REUSE specification](https://reuse.software/spec/) for file-level copyright and licensing
information. License texts used for file-level REUSE licensing are stored in
[`LICENSES/`](LICENSES/).

> Recorded `Manifest.toml` files under `.licensing/manifests/`, where provided,
> document dependency resolutions considered when choosing the package-level
> license expression. They are evidence for that licensing decision, not guarantees for
> other Julia versions, platforms, dependency resolutions, extensions, artifacts,
> load paths, or local modifications.

To verify the file-level REUSE metadata:

```bash
reuse lint
reuse spdx
```
~~~

You can adapt this to your needs by providing a custom
`README_licensing_section.md.mustache` in `template_dir`.

## Complete Setup Example

```julia
using ReusePkgTemplates

plugins = with_reuse(
    [
        Git(; manifest = true, ssh = true),
        GitHubActions(; x86 = true),
        Codecov()
    ];
    package_license = "EUPL-1.2+",
    docs_license = "CC-BY-4.0",
    infrastructure_license = "0BSD",
    readme_licensing_section = true
)

t = Template(;
    user = "your-github-user",
    authors = "Your Name <you@example.org>",
    dir = ".",
    plugins
)

t("MyPackage")
```

Here `code_license` is not given, so source files default to `package_license`.
Documentation text is licensed separately with `docs_license`, while generated
project infrastructure is covered by `infrastructure_license`. Setting
`readme_licensing_section = true` appends the bundled licensing section to the
generated README.

[`ReuseLicensing.reuse_specification_version()`]: https://bsl-support.de/julia/ReuseLicensing.jl/#ReuseLicensing.reuse_specification_version-Tuple{}
[`ReuseLicensing.spdx_license_list_version()`]: https://bsl-support.de/julia/ReuseLicensing.jl/spdx/#ReuseLicensing.spdx_license_list_version
