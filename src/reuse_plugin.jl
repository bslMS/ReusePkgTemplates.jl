# SPDX-FileCopyrightText: 2026 Guido Wolf Reichert <gwr@bsl-support.de>
# SPDX-License-Identifier: EUPL-1.2+

@plugin struct Reuse <: Plugin
    license::Union{AbstractString, Nothing} = nothing
    artifact_license::Union{AbstractString, Nothing} = nothing
    docs_license::Union{AbstractString, Nothing} = nothing
    docs_assets_license::Union{AbstractString, Nothing} = nothing
    license_ref_dir::Union{AbstractString, Nothing} = nothing
    template::String = template_file("reuse", "REUSE.toml.mustache")
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
