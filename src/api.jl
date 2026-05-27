# SPDX-FileCopyrightText: 2026 Guido Wolf Reichert <gwr@bsl-support.de>
# SPDX-License-Identifier: EUPL-1.2+

"""
    with_reuse([plugins]; kwargs...)

Return a PkgTemplates plugin list with REUSE support enabled.

`with_reuse` is a convenience wrapper for use with `PkgTemplates.Template`.
It takes an optional collection of existing plugins, removes any explicit
`PkgTemplates.License` plugin, disables the default `PkgTemplates.License`
plugin, and appends a `Reuse` plugin configured from the supplied keyword
arguments.

Use this helper when constructing templates that should use REUSE metadata
instead of the conventional single-license-file workflow.

# Examples

```julia
t = Template(;
    plugins = with_reuse([
        Git(),
        SrcDir(),
        Tests(),
    ];
        package_license = "EUPL-1.2+",
        infrastructure_license = "0BSD",
        docs_license = "CC-BY-SA-4.0",
    ),
)
```

"""
function with_reuse(
        plugins = PkgTemplates.Plugin[];
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
