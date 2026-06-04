# SPDX-FileCopyrightText: 2026 Guido Wolf Reichert <gwr@bsl-support.de>
# SPDX-License-Identifier: EUPL-1.2+

"""
    with_reuse([plugins]; kwargs...) -> Vector{<:Plugins}

Return a PkgTemplates plugin specification vector with REUSE support enabled. The returned
vector is intended to be passed directly as the `plugins` keyword to `PkgTemplates.Template`.

`with_reuse` wraps an optional collection of PkgTemplates plugins, removes any
explicit `PkgTemplates.License` plugin, disables the default `PkgTemplates.License`
plugin, and appends a configured [`Reuse`](@ref) plugin. Passing an existing `Reuse`
plugin in `plugins` is rejected; configure `Reuse` through the keyword arguments to
`with_reuse` instead.

Use this helper when constructing templates that should use an outbound
package-level license declaration together with REUSE file-level licensing metadata.

# Keyword Arguments

- `copyright_holders::Union{Vector{<:AbstractString}, Nothing}`: Copyright holders used
  to construct the package-level copyright notice with the current year. Defaults to the
  template `authors`.
- `package_license::Union{AbstractString, Nothing}`: Outbound SPDX license expression
  for the package-level software work. Defaults to `"MIT"`.
- `code_license::Union{AbstractString, Nothing}`: SPDX license expression for the
  project's source code. Defaults to `package_license`.
- `infrastructure_license::Union{AbstractString, Nothing}`: SPDX license expression for
  project metadata and infrastructure files. Defaults to `code_license`.
- `docs_license::Union{AbstractString, Nothing}`: SPDX license expression for
  documentation text. Defaults to `code_license`.
- `docs_assets_license::Union{AbstractString, Nothing}`: SPDX license expression for
  documentation assets. Defaults to `docs_license`.
- `license_ref_dir::Union{AbstractString, Nothing}`: Optional directory containing
  user-supplied license texts for `LicenseRef-...` identifiers. For `LicenseRef-X`,
  `LicenseRef-X.txt.mustache` is rendered if present; otherwise `LicenseRef-X.txt`
  is used verbatim.
- `template_dir::Union{AbstractString, Nothing}`: Optional directory containing template
  overrides. Missing files fall back to the bundled templates.
- `enable_reuse_lint::Bool`: Whether to add a REUSE lint GitHub Actions workflow when
  `GitHubActions` is present. Defaults to `true`.
- `readme_license_section::Bool`: Whether to append a licensing section to the generated
  README. Defaults to `false`.
- `license_policy::Symbol`: Approval policy for SPDX license expressions. Must be one of
  `:general_registry`, `:osi_approved`, `:free`, or `:none`. Defaults to
  `:general_registry`.

# Examples

```julia
plugins = with_reuse(
    [
        Git(; manifest = true, ssh = true),
        GitHubActions(; x86 = true),
        Codecov()
    ];
    package_license = "EUPL-1.2+",
    docs_license = "CC-BY-SA-4.0",
    infrastructure_license = "0BSD",
    readme_license_section = true
)

t = Template(; plugins)
```

# Notes

- Deprecated GNU-style SPDX identifiers such as `GPL-3.0+` are accepted as a convenience
  and normalized by ReuseLicensing.jl.
- The `:general_registry` policy is a best-effort helper for generating packages that are
  likely to satisfy Julia General Registry license expectations. It is not a guarantee of
  registry acceptance and does not assess legal compatibility between the package-level
  declaration and file-level licenses.
"""
function with_reuse(
        plugins = PkgTemplates.Plugin[];
        copyright_holders::Union{Vector{<:AbstractString}, Nothing} = nothing,
        package_license::Union{AbstractString, Nothing} = nothing,
        code_license::Union{AbstractString, Nothing} = nothing,
        infrastructure_license::Union{AbstractString, Nothing} = nothing,
        docs_license::Union{AbstractString, Nothing} = nothing,
        docs_assets_license::Union{AbstractString, Nothing} = nothing,
        license_ref_dir::Union{AbstractString, Nothing} = nothing,
        template_dir::Union{AbstractString, Nothing} = nothing,
        enable_reuse_lint::Bool = true,
        readme_license_section::Bool = false,
        license_policy::Symbol = :general_registry
)
    any(p -> p isa Reuse, plugins) && throw(ArgumentError(
        "with_reuse: plugins already contain a Reuse plugin."
    ))

    filtered = Any[p for p in plugins if !(p isa PkgTemplates.License)]

    reuse = Reuse(;
        copyright_holders,
        package_license,
        code_license,
        infrastructure_license,
        docs_license,
        docs_assets_license,
        license_ref_dir,
        template_dir,
        enable_reuse_lint,
        readme_license_section,
        license_policy
    )

    push!(filtered, !PkgTemplates.License)
    push!(filtered, reuse)
    return filtered
end

"""
    write_templates(dir::AbstractString; force::Bool = false)

Copy the bundled ReusePkgTemplates template files into `dir`.

Use this when you want to customize generated REUSE files. The copied directory
can be edited and then passed to [`with_reuse`](@ref) or [`Reuse`](@ref) as
`template_dir`.

Existing files are left untouched by default. Pass `force = true` to overwrite
template files that already exist in `dir`. Hidden platform files such as
`.DS_Store` are not copied.

# Examples

```julia
write_templates("reuse_templates")

t = Template(;
    plugins = with_reuse([
        Git(),
        SrcDir(),
    ];
        template_dir = "reuse_templates",
        package_license = "EUPL-1.2+",
    ),
)
```
"""
function write_templates(dir::AbstractString; force::Bool = false)
    mkpath(dir)

    for name in sort(readdir(DEFAULT_TEMPLATE_DIR[]))
        startswith(name, ".") && continue

        src = template_file(name)
        isfile(src) || continue

        dest = joinpath(dir, name)
        if isfile(dest) && !force
            throw(ArgumentError(
                "ReusePkgTemplates: template file `$dest` already exists; " *
                "pass `force = true` to overwrite it"
            ))
        end

        cp(src, dest; force)
    end

    return dir
end
