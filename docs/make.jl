using Pkg

Pkg.develop(Pkg.PackageSpec(path = joinpath(@__DIR__, "..")))
Pkg.instantiate()

using ReusePkgTemplates
using Documenter

const PROJECT_TOML = Pkg.TOML.parsefile(joinpath(@__DIR__, "..", "Project.toml"))
const PACKAGE_VERSION = VersionNumber(PROJECT_TOML["version"])

DocMeta.setdocmeta!(
    ReusePkgTemplates,
    :DocTestSetup,
    :(using ReusePkgTemplates);
    recursive = true
)

makedocs(;
    modules = [ReusePkgTemplates],
    authors = "Guido Wolf Reichert <gwr@bsl-support.de> and contributors",
    sitename = "ReusePkgTemplates.jl",
    format = Documenter.HTML(;
        canonical = "https://bsl-support.de/julia/ReusePkgTemplates.jl",
        edit_link = "main",
        assets = String[],
        footer = "Copyright © 2026 Guido Wolf Reichert and contributors ⋅ " *
        "Documentation v$PACKAGE_VERSION " *
        "licensed under [CC-BY-SA-4.0](https://creativecommons.org/licenses/by-sa/4.0/) " *
        "⋅ Built with [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl)."
    ),
    pages = [
        "Home" => "index.md",
        "User Guide" => "user.md",
        "Licensing FAQ" => "faq.md",
        "API Reference" => "api.md"
    ]
)
