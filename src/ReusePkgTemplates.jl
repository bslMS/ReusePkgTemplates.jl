# SPDX-FileCopyrightText: 2026 Guido Wolf Reichert <gwr@bsl-support.de>
# SPDX-License-Identifier: EUPL-1.2+

module ReusePkgTemplates

using Dates: today, year
using PkgTemplates: PkgTemplates, @plugin, @with_kw_noshow
using ReuseLicensing: ReuseLicensing

export Reuse

const DEFAULT_TEMPLATE_DIR = Ref{String}(joinpath(dirname(@__DIR__), "templates"))

template_file(paths::AbstractString...) = joinpath(DEFAULT_TEMPLATE_DIR[], paths...)

include("reuse_plugin.jl")

end
