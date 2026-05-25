# SPDX-FileCopyrightText: 2026 Guido Wolf Reichert <gwr@bsl-support.de>
# SPDX-License-Identifier: EUPL-1.2+

PkgTemplates.@plugin struct Reuse <: PkgTemplates.Plugin
    license::Union{AbstractString, Nothing} = nothing
    artifact_license::Union{AbstractString, Nothing} = nothing
    docs_license::Union{AbstractString, Nothing} = nothing
    docs_assets_license::Union{AbstractString, Nothing} = nothing
    license_ref_dir::Union{AbstractString, Nothing} = nothing
    template::String = template_file("REUSE.toml.mustache")
    enable_reuse_lint::Bool = true
    readme_license_section::Bool = false
    license_section_template::String = template_file("README_license_section.md.mustache")
    root_license::Bool = true
    license_approval::String = "code"
end

const REUSE_LICENSES_DIR = "LICENSES"
const REUSE_TOML_FILE = "REUSE.toml"
const SPDX_PARSE_CACHE = Dict{String, ReuseLicensing.ParsedSPDXExpression}()
const REUSE_README_SECTION_START = "<!-- PkgTemplates: REUSE licensing section start -->"
const REUSE_README_SECTION_END = "<!-- PkgTemplates: REUSE licensing section end -->"
# REUSE-IgnoreStart
const REUSE_JULIA_HEADER_TEMPLATE = """
                                    # SPDX-FileCopyrightText: {{{YEAR}}} {{{AUTHORS}}}
                                    # SPDX-License-Identifier: {{{PRIMARY_LICENSE}}}

                                    """
const REUSE_SPDX_LICENSE_TAG = "SPDX-License-Identifier:"
# REUSE-IgnoreEnd
const REUSE_HEADER_SCAN_LINES = 5

const REUSE_ROOT_LICENSE_POINTER = """
This project follows the REUSE specification for copyright and licensing
information.

The authoritative copyright and licensing information is provided by SPDX
notices in individual files and, where applicable, by REUSE.toml.

The full license texts for the licenses used in this project are located in
the LICENSES/ directory.

This file is only a pointer for repository hosts, package registries, and users
who expect a top-level LICENSE file. It does not declare a single license for the whole project and is not itself a license text.

See https://reuse.software/ for more information about the REUSE specification.
"""

#TODO: detect CI in posthook and add REUSE lint as its

struct ReuseConfig
    license::String
    artifact_license::String
    docs_license::String
    docs_assets_license::String
    licenses::Set{String}
    exceptions::Set{String}
    licenserefs::Set{String} # lowercase identifiers
end

# Return a dictionary that maps lowercase identifiers to source files.
function licenseref_files(dir::AbstractString)
    files = Dict{
        String,
        NamedTuple{
            (:txt, :mustache), Tuple{Union{String, Nothing}, Union{String, Nothing}}}
    }()

    for filename in readdir(dir)
        startswith(filename, "LicenseRef-") || continue

        payload = if endswith(filename, ".txt.mustache")
            filename[(length("LicenseRef-") + 1):(end - length(".txt.mustache"))]
        elseif endswith(filename, ".txt")
            filename[(length("LicenseRef-") + 1):(end - length(".txt"))]
        else # file not relevant
            continue
        end

        key = lowercase(payload)
        current = get(files, key, (txt = nothing, mustache = nothing))
        path = joinpath(dir, filename)

        files[key] = if endswith(filename, ".txt.mustache")
            (txt = current.txt, mustache = path)
        else
            (txt = path, mustache = current.mustache)
        end
    end
    return files
end

# Avoid expensive recalculation for parsing license expressions.
function cached_parse_spdx_expression(expr::AbstractString)
    key = String(expr)
    return get!(SPDX_PARSE_CACHE, key) do
        ReuseLicensing.parse_spdx_expression(key; legacy = :normalize)
    end
end

# Parse a single license expression and report error if that fails.
function parse_reuse_license(which::AbstractString, expr::AbstractString)
    try
        return cached_parse_spdx_expression(expr)
    catch err
        err isa ArgumentError || rethrow()
        throw(ArgumentError("Reuse: invalid $which SPDX license expression `$expr`: $(err.msg)"))
    end
end

# Parse effective license expressions after applying default fallbacks.
function parsed_reuse_licenses(p::Reuse)
    license = parse_reuse_license("license", something(p.license, "MIT"))
    artifact = if p.artifact_license === nothing
        license
    else
        parse_reuse_license("artifact", p.artifact_license)
    end
    docs = if p.docs_license === nothing
        license
    else
        parse_reuse_license("docs", p.docs_license)
    end
    assets = if p.docs_assets_license === nothing
        docs
    else
        parse_reuse_license("assets", p.docs_assets_license)
    end
    return (
        license = license,
        artifact_license = artifact,
        docs_license = docs,
        docs_assets_license = assets
    )
end

# Build `ReuseConfig` struct to provide plugin state from parsed expressions.
function reuse_config(parsed)
    license = parsed.license
    artifact = parsed.artifact_license
    docs = parsed.docs_license
    assets = parsed.docs_assets_license
    return ReuseConfig(
        license.expression,
        artifact.expression,
        docs.expression,
        assets.expression,
        union(license.licenses, artifact.licenses, docs.licenses, assets.licenses),
        union(license.exceptions, artifact.exceptions, docs.exceptions, assets.exceptions),
        union(license.licenserefs, artifact.licenserefs,
            docs.licenserefs, assets.licenserefs)
    )
end

# General method to build `ReuseConfig` that calls parsing first.
reuse_config(p::Reuse, t::PkgTemplates.Template) = reuse_config(parsed_reuse_licenses(p))

# Check approved path and report failures for the given license domain.
function validate_approved_path(which::AbstractString, parsed, approval::AbstractString)
    if approval == "code"
        requirement = "an OSI-approved path"
        policy = ReuseLicensing.OSIApproved()
    else
        requirement = "an OSI-approved or FSF-libre path"
        policy = ReuseLicensing.AnyOf(
            ReuseLicensing.OSIApproved(),
            ReuseLicensing.FSFLibre()
        )
    end
    ReuseLicensing.has_approved_license_path(parsed, policy) && return
    throw(ArgumentError(
        "Reuse: $which SPDX license expression `$(parsed.expression)` does not have " *
        requirement,
    ))
end

# Validate REUSE configuration before generation starts.
function PkgTemplates.validate(p::Reuse, t::PkgTemplates.Template)
    p.license_approval in ("code", "strict", "none") ||
        throw(ArgumentError(
            "Reuse: license_approval must be \"code\", \"strict\", or \"none\", " *
            "got \"$(p.license_approval)\""
        ))
    # License expressions should parse without errors and meet approval requirements.
    parsed = parsed_reuse_licenses(p)
    config = reuse_config(parsed)
    if p.license_approval != "none"
        validate_approved_path("license", parsed.license, "code")
        if p.license_approval == "strict"
            validate_approved_path("artifact", parsed.artifact_license, "strict")
            validate_approved_path("docs", parsed.docs_license, "strict")
            validate_approved_path("assets", parsed.docs_assets_license, "strict")
        end
    end
    isfile(p.template) ||
        throw(ArgumentError("Reuse: template file `$(p.template)` does not exist"))
    p.readme_license_section === false || isfile(p.license_section_template) ||
        throw(ArgumentError("Reuse: license section template file " *
                            "`$(p.license_section_template)` does not exist"))
    # Check if all LicenseRef-identifiers are covered by at least one file in `license_ref_dir`
    if !isempty(config.licenserefs)
        p.license_ref_dir === nothing &&
            throw(ArgumentError("`license_ref_dir` not given for the referenced licenses."))
        isdir(p.license_ref_dir) ||
            throw(ArgumentError("Reuse: `license_ref_dir` must be an existing directory"))
        available = Set(keys(licenseref_files(p.license_ref_dir)))
        missing = setdiff(config.licenserefs, available)
        if !isempty(missing)
            missing_list = join(sort(collect(missing)), ", ")
            throw(ArgumentError("Reuse: missing LicenseRef files for $missing_list"))
        end
    end
end

# Build the Mustache view used to render templates for `pkg`.
function PkgTemplates.view(p::Reuse, t::PkgTemplates.Template, pkg::AbstractString)
    config = reuse_config(p, t)
    readme_plugin = PkgTemplates.getplugin(t, PkgTemplates.Readme)
    readme_destination = if readme_plugin === nothing
        "README.md"
    else
        PkgTemplates.destination(readme_plugin)
    end
    return Dict(
        "ARTIFACT_LICENSE" => config.artifact_license,
        "AUTHORS" => join(t.authors, ", "),
        "DOCS_ASSETS_LICENSE" => config.docs_assets_license,
        "DOCS_LICENSE" => config.docs_license,
        "PKG" => pkg,
        "PRIMARY_LICENSE" => config.license,
        "README" => readme_destination,
        "YEAR" => year(today())
    )
end

# Hook should write required license files, write the rendered `REUSE.toml`.
function PkgTemplates.hook(p::Reuse, t::PkgTemplates.Template, pkg_dir::AbstractString)
    config = reuse_config(p, t)
    pkg = PkgTemplates.pkg_name(pkg_dir)

    # Generate `REUSE.toml`.
    text = PkgTemplates.render_file(
        p.template, PkgTemplates.combined_view(p, t, pkg), PkgTemplates.tags(p))
    PkgTemplates.gen_file(joinpath(pkg_dir, REUSE_TOML_FILE), text)

    # Create `LICENSES/`
    licenses_dir = joinpath(pkg_dir, REUSE_LICENSES_DIR)
    mkpath(licenses_dir)

    # Vendor unrendered SPDX license and exception texts.
    for id in sort(collect(config.licenses))
        filename = id * ".txt"
        src = ReuseLicensing.spdx_license_text_path(id)
        src === nothing &&
            throw(ArgumentError("Reuse: no SPDX license text found for `$id`"))
        cp(src, joinpath(licenses_dir, filename); force = true)
    end

    for id in sort(collect(config.exceptions))
        filename = id * ".txt"
        src = ReuseLicensing.spdx_license_exception_text_path(id)
        src === nothing &&
            throw(ArgumentError("Reuse: no SPDX exception text found for `$id`"))
        cp(src, joinpath(licenses_dir, filename); force = true)
    end

    # Vendor possibly rendered custom `LicenseRef-...` license texts.
    licenserefs = if isempty(config.licenserefs)
        nothing
    else
        licenseref_files(p.license_ref_dir)
    end
    for id in sort(collect(config.licenserefs))
        files = licenserefs[id]
        src = something(files.mustache, files.txt)
        src_name = basename(src)

        dest_name = if endswith(src_name, ".txt.mustache")
            src_name[1:(end - length(".mustache"))]
        else
            src_name
        end
        dest = joinpath(licenses_dir, dest_name)

        if endswith(src_name, ".txt.mustache")
            text = PkgTemplates.render_file(
                src, PkgTemplates.combined_view(p, t, pkg), PkgTemplates.tags(p))
            PkgTemplates.gen_file(dest, text)
        else
            cp(src, dest; force = true)
        end
    end
end

# Add SPDX header to Julia code file if not yet present.
function add_julia_spdx_header(path::AbstractString, header::AbstractString)
    isfile(path) || return

    text = read(path, String)
    lines = split(text, '\n')
    any(
        line -> occursin(REUSE_SPDX_LICENSE_TAG, line),
        lines[1:min(end, REUSE_HEADER_SCAN_LINES)]
    ) && return

    PkgTemplates.gen_file(path, header * text)
end

function has_single_plain_license(config::ReuseConfig)
    return length(config.licenses) == 1 &&
           isempty(config.exceptions) &&
           isempty(config.licenserefs)
end

# Run late enough to adjust files created by other plugins, but before Git commits them.
PkgTemplates.priority(::Reuse, ::typeof(PkgTemplates.posthook)) = 10

# Posthook should (optionally) modify a `README.md` and add individual SPDX headers
# to files, where appropriate.
function PkgTemplates.posthook(p::Reuse, t::PkgTemplates.Template, pkg_dir::AbstractString)
    pkg = PkgTemplates.pkg_name(pkg_dir)
    config = reuse_config(p, t)

    # Remove anything produced by the License plugin.
    license_plugin = PkgTemplates.getplugin(t, PkgTemplates.License)

    if license_plugin !== nothing
        path = joinpath(pkg_dir, PkgTemplates.destination(license_plugin))
        isfile(path) && rm(path)
    end

    # Write appropriate root `LICENSE` if required.
    if p.root_license
        licenses_dir = joinpath(pkg_dir, REUSE_LICENSES_DIR)
        root_license = joinpath(pkg_dir, "LICENSE")
        if has_single_plain_license(config)
            id = first(config.licenses)
            cp(joinpath(licenses_dir, id * ".txt"), root_license; force = true)
        else
            PkgTemplates.gen_file(root_license, REUSE_ROOT_LICENSE_POINTER)
        end
    end

    # Render the `README_license_section` template and append to `README.md` (optional).
    readme_plugin = PkgTemplates.getplugin(t, PkgTemplates.Readme)
    readme_file = if readme_plugin === nothing
        nothing
    else
        joinpath(pkg_dir, PkgTemplates.destination(readme_plugin))
    end

    if p.readme_license_section && readme_file !== nothing && isfile(readme_file)
        section = PkgTemplates.render_file(
            p.license_section_template,
            PkgTemplates.combined_view(p, t, pkg), PkgTemplates.tags(p)
        )
        block = join([REUSE_README_SECTION_START, section, REUSE_README_SECTION_END], "\n")
        readme_text = read(readme_file, String)
        if !occursin(REUSE_README_SECTION_START, readme_text)
            PkgTemplates.gen_file(readme_file, readme_text * "\n\n" * block)
        end
    end

    # Add explicit SPDX headers where code is actively developed.
    header = PkgTemplates.render_text(
        REUSE_JULIA_HEADER_TEMPLATE,
        PkgTemplates.combined_view(p, t, pkg), PkgTemplates.tags(p)
    )

    for T in (PkgTemplates.SrcDir, PkgTemplates.Tests, PkgTemplates.PkgBenchmark)
        plugin = PkgTemplates.getplugin(t, T)
        plugin === nothing && continue

        path = joinpath(pkg_dir, PkgTemplates.destination(plugin))
        add_julia_spdx_header(path, header)
    end
end

function PkgTemplates.customizable(::Type{Reuse})
    return (
        :license => String,
        :artifact_license => String,
        :docs_license => String,
        :docs_assets_license => String,
        :license_ref_dir => String,
        :enable_reuse_lint => Bool,
        :readme_license_section => Bool,
        :license_section_template => String,
        :root_license => Bool,
        :license_approval => String
    )
end
