# SPDX-FileCopyrightText: 2026 Guido Wolf Reichert <gwr@bsl-support.de>
# SPDX-License-Identifier: EUPL-1.2+

PkgTemplates.@plugin struct Reuse <: PkgTemplates.Plugin
    package_license::Union{AbstractString, Nothing} = nothing
    code_license::Union{AbstractString, Nothing} = nothing
    infrastructure_license::Union{AbstractString, Nothing} = nothing
    docs_license::Union{AbstractString, Nothing} = nothing
    docs_assets_license::Union{AbstractString, Nothing} = nothing
    license_ref_dir::Union{AbstractString, Nothing} = nothing
    template_dir::Union{AbstractString, Nothing} = nothing
    enable_reuse_lint::Bool = true
    readme_license_section::Bool = false
    license_policy::Symbol = :general_registry
end

const PACKAGE_LICENSE_DECLARED_FILE = "LICENSE"
const REUSE_LICENSES_DIR = "LICENSES"
const REUSE_TOML_FILE = "REUSE.toml"
const REUSE_TOML_TEMPLATE = "REUSE.toml.mustache"
const REUSE_LICENSE_TEMPLATE = "LICENSE.mustache"
const README_LICENSE_SECTION_TEMPLATE = "README_license_section.md.mustache"
const REUSE_PROJECT_TOML_TEMPLATE = "Project.toml.metadata.mustache"
const REUSE_LINT_WORKFLOW_TEMPLATE = "REUSE.yml.mustache"
const REUSE_LINT_WORKFLOW_FILE = joinpath(".github", "workflows", "REUSE.yml")
const SPDX_PARSE_CACHE = Dict{String, ReuseLicensing.ParsedSPDXExpression}()
const REUSE_README_SECTION_START = "<!-- PkgTemplates: REUSE licensing section start -->"
const REUSE_README_SECTION_END = "<!-- PkgTemplates: REUSE licensing section end -->"
# REUSE-IgnoreStart
const REUSE_JULIA_HEADER_TEMPLATE = """
                                    # SPDX-FileCopyrightText: {{{YEAR}}} {{{AUTHORS}}}
                                    # SPDX-License-Identifier: {{{CODE_LICENSE}}}

                                    """
const REUSE_SPDX_LICENSE_TAG = "SPDX-License-Identifier:"
# REUSE-IgnoreEnd
const REUSE_HEADER_SCAN_LINES = 5

#TODO add REUSE badge if badges are present

struct ReuseConfig
    package_license::String
    code_license::String
    infrastructure_license::String
    docs_license::String
    docs_assets_license::String

    licenses::Set{String}
    exceptions::Set{String}
    licenserefs::Set{String} # lowercase identifiers

    package_licenses::Set{String}
    package_exceptions::Set{String}
    package_licenserefs::Set{String} # lowercase identifiers
end

# Resolve template file path.
function template_path(p::Reuse, filename::AbstractString)
    if p.template_dir !== nothing
        path = joinpath(p.template_dir, filename)
        isfile(path) && return path
    end
    return template_file(filename)
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
    package = parse_reuse_license("package", something(p.package_license, "MIT"))
    code = if p.code_license === nothing
        package
    else
        parse_reuse_license("code", p.code_license)
    end
    infrastructure = if p.infrastructure_license === nothing
        code
    else
        parse_reuse_license("infrastructure", p.infrastructure_license)
    end
    docs = if p.docs_license === nothing
        code
    else
        parse_reuse_license("docs", p.docs_license)
    end
    assets = if p.docs_assets_license === nothing
        docs
    else
        parse_reuse_license("assets", p.docs_assets_license)
    end
    return (
        package_license = package,
        code_license = code,
        infrastructure_license = infrastructure,
        docs_license = docs,
        docs_assets_license = assets
    )
end

# Build `ReuseConfig` struct to provide plugin state from parsed expressions.
function reuse_config(parsed)
    package = parsed.package_license
    code = parsed.code_license
    infrastructure = parsed.infrastructure_license
    docs = parsed.docs_license
    assets = parsed.docs_assets_license
    return ReuseConfig(
        package.expression,
        code.expression,
        infrastructure.expression,
        docs.expression,
        assets.expression,
        union(code.licenses, infrastructure.licenses, docs.licenses, assets.licenses),
        union(
            code.exceptions, infrastructure.exceptions, docs.exceptions, assets.exceptions),
        union(code.licenserefs, infrastructure.licenserefs,
            docs.licenserefs, assets.licenserefs),
        package.licenses,
        package.exceptions,
        package.licenserefs
    )
end

# General method to build `ReuseConfig` that calls parsing first.
reuse_config(p::Reuse, t::PkgTemplates.Template) = reuse_config(parsed_reuse_licenses(p))

# Check approved path and report failures for the given license domain.
function validate_approved_path(which::AbstractString, parsed, license_policy::Symbol)
    if license_policy === :general_registry && which ∈ ("code", "package")
        requirement = "an unconjoined OSI-approved path"
        policy = ReuseLicensing.UnconjoinedOSIApproval()
    elseif license_policy === :general_registry && which ∉ ("code", "package")
        requirement = "an unconjoined OSI-approved or open content path"
        policy = ReuseLicensing.AnyOf(
            ReuseLicensing.UnconjoinedOSIApproval(),
            ReuseLicensing.OpenContentApproval()
        )
    elseif license_policy === :free && which ∈ ("code", "package")
        requirement = "an OSI-approved path"
        policy = ReuseLicensing.OSIApproval()
    elseif license_policy === :free && which ∉ ("code", "package")
        requirement = "an OSI-approved or FSF-libre approved path"
        policy = ReuseLicensing.AnyOf(
            ReuseLicensing.OSIApproval(),
            ReuseLicensing.FSFLibre()
        )
    elseif license_policy === :osi_approved
        requirement = "an OSI-approved path"
        policy = ReuseLicensing.OSIApproval()
    else
        return true
    end
    ReuseLicensing.has_approved_license_path(parsed, policy) && return
    throw(ArgumentError(
        "Reuse: $which SPDX license expression `$(parsed.expression)` does not have " *
        requirement,
    ))
end

# Validate REUSE configuration before generation starts.
function PkgTemplates.validate(p::Reuse, t::PkgTemplates.Template)
    p.license_policy in (:general_registry, :free, :osi_approved, :none) ||
        throw(ArgumentError(
            "Reuse: license_policy must be `:general_registry`, `:free`, `:osi_approved`, " *
            "or `:none`, got \"$(p.license_policy)\""
        ))
    # License expressions should parse without errors and meet approval requirements.
    parsed = parsed_reuse_licenses(p)
    config = reuse_config(parsed)
    if p.license_policy != :none
        validate_approved_path("package", parsed.package_license, p.license_policy)
        validate_approved_path("code", parsed.code_license, p.license_policy)
        validate_approved_path(
            "infrastructure", parsed.infrastructure_license, p.license_policy)
        validate_approved_path("docs", parsed.docs_license, p.license_policy)
        validate_approved_path("assets", parsed.docs_assets_license, p.license_policy)
    end
    p.template_dir === nothing || isdir(p.template_dir) ||
        throw(ArgumentError("Reuse: template_dir `$(p.template_dir)` does not exist"))
    # Check if all LicenseRef-identifiers are covered by at least one file in `license_ref_dir`
    required_licenserefs = union(config.licenserefs, config.package_licenserefs)
    if !isempty(required_licenserefs)
        p.license_ref_dir === nothing &&
            throw(ArgumentError("`license_ref_dir` not given for the referenced licenses."))
        isdir(p.license_ref_dir) ||
            throw(ArgumentError("Reuse: `license_ref_dir` must be an existing directory"))
        available = Set(keys(licenseref_files(p.license_ref_dir)))
        missing = setdiff(required_licenserefs, available)
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
        "AUTHORS" => join(t.authors, ", "),
        "PACKAGE_LICENSE" => config.package_license,
        "PACKAGE_LICENSE_DECLARED_FILE" => PACKAGE_LICENSE_DECLARED_FILE,
        "CODE_LICENSE" => config.code_license,
        "DOCS_LICENSE" => config.docs_license,
        "DOCS_ASSETS_LICENSE" => config.docs_assets_license,
        "INFRASTRUCTURE_LICENSE" => config.infrastructure_license,
        "PKG" => pkg,
        "README" => readme_destination,
        "YEAR" => year(today())
    )
end

# Hook should write required license files, write the rendered `REUSE.toml`.
function PkgTemplates.hook(p::Reuse, t::PkgTemplates.Template, pkg_dir::AbstractString)
    config = reuse_config(p, t)
    pkg = PkgTemplates.pkg_name(pkg_dir)

    # Generate `REUSE.toml`.
    template = template_path(p, REUSE_TOML_TEMPLATE)

    text = PkgTemplates.render_file(
        template, PkgTemplates.combined_view(p, t, pkg), PkgTemplates.tags(p))
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

    # Write appropriate package license declared file, e.g., `LICENSE`.
    license_template_path = template_path(p, REUSE_LICENSE_TEMPLATE)
    license_text = PkgTemplates.render_file(
        license_template_path,
        PkgTemplates.combined_view(p, t, pkg),
        PkgTemplates.tags(p)
    )

    license_parts = String[license_text]

    for id in sort(collect(config.package_licenses))
        src = ReuseLicensing.spdx_license_text_path(id)
        src === nothing &&
            throw(ArgumentError("Reuse: no SPDX license text found for `$id`"))
        push!(license_parts, read(src, String))
    end

    for id in sort(collect(config.package_exceptions))
        src = ReuseLicensing.spdx_license_exception_text_path(id)
        src === nothing &&
            throw(ArgumentError("Reuse: no SPDX license exception text found for `$id`"))
        push!(license_parts, read(src, String))
    end

    # Vendor possibly rendered custom `LicenseRef-...` license texts.
    licenserefs = if isempty(config.package_licenserefs)
        nothing
    else
        licenseref_files(p.license_ref_dir)
    end
    for id in sort(collect(config.package_licenserefs))
        files = licenserefs[id]
        src = something(files.mustache, files.txt)
        src_name = basename(src)

        if endswith(src_name, ".txt.mustache")
            license_text = PkgTemplates.render_file(
                src, PkgTemplates.combined_view(p, t, pkg), PkgTemplates.tags(p))
            push!(license_parts, license_text)
        else
            push!(license_parts, read(src, String))
        end
    end

    PkgTemplates.gen_file(
        joinpath(pkg_dir, PACKAGE_LICENSE_DECLARED_FILE),
        join(strip.(license_parts), "\n\n") * "\n"
    )

    # Render the `README_license_section` template and append to `README.md` (optional).
    readme_plugin = PkgTemplates.getplugin(t, PkgTemplates.Readme)
    readme_file = if readme_plugin === nothing
        nothing
    else
        joinpath(pkg_dir, PkgTemplates.destination(readme_plugin))
    end

    template = template_path(p, README_LICENSE_SECTION_TEMPLATE)
    if p.readme_license_section && readme_file !== nothing && isfile(readme_file)
        section = PkgTemplates.render_file(
            template,
            PkgTemplates.combined_view(p, t, pkg), PkgTemplates.tags(p)
        )
        block = join([REUSE_README_SECTION_START, section, REUSE_README_SECTION_END], "\n")
        readme_text = read(readme_file, String)
        if !occursin(REUSE_README_SECTION_START, readme_text)
            PkgTemplates.gen_file(readme_file, rstrip(readme_text) * "\n\n" * block * "\n")
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

    # Write metadata to Project.toml.
    project_file = joinpath(pkg_dir, "Project.toml")
    project = TOML.parsefile(project_file)
    if !haskey(project, "reuse_licensing")
        text = read(project_file, String)
        section = PkgTemplates.render_file(
            template_path(p, REUSE_PROJECT_TOML_TEMPLATE),
            PkgTemplates.combined_view(p, t, pkg),
            PkgTemplates.tags(p)
        )

        PkgTemplates.gen_file(
            project_file,
            rstrip(text) * "\n\n" * strip(section) * "\n"
        )
    end

    # Establish reuse lint in GitHub Actions.
    if p.enable_reuse_lint &&
       PkgTemplates.getplugin(t, PkgTemplates.GitHubActions) !== nothing
        workflow_template = template_path(p, REUSE_LINT_WORKFLOW_TEMPLATE)
        workflow_text = PkgTemplates.render_file(
            workflow_template,
            PkgTemplates.combined_view(p, t, pkg),
            PkgTemplates.tags(p)
        )

        workflow_file = joinpath(pkg_dir, REUSE_LINT_WORKFLOW_FILE)
        mkpath(dirname(workflow_file))
        PkgTemplates.gen_file(workflow_file, workflow_text)
    end
end

function PkgTemplates.customizable(::Type{Reuse})
    return (
        :package_license => String,
        :code_license => String,
        :infrastructure_license => String,
        :docs_license => String,
        :docs_assets_license => String,
        :license_ref_dir => String,
        :template_dir => String,
        :enable_reuse_lint => Bool,
        :readme_license_section => Bool,
        :license_policy => Symbol
    )
end
