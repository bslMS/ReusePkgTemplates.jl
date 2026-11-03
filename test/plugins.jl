# SPDX-FileCopyrightText: 2026 Guido Wolf Reichert and contributors
# SPDX-License-Identifier: EUPL-1.2+

# Interactions with PkgTemplates plugins: composition, overrides, optional outputs, and
# preservation of existing content.

# SPDX strings below are test data, not licensing declarations for this file.
# REUSE-IgnoreStart
using TestItems

@testitem "with_reuse preserves caller plugins and disables the default License" tags=[:integration] setup=[WithTempdir] begin
    readme_plugin = Readme(; destination = "ABOUT.md")
    # Disabled-plugin entries must survive composition alongside plugin instances.
    input = [readme_plugin, License(), !Git]
    original = copy(input)
    plugins = with_reuse(input; package_license = "Apache-2.0", enable_reuse_lint = false)
    @test input == original
    @test readme_plugin in plugins
    @test !Git in plugins
    # Removing an explicit License must also suppress PkgTemplates' default instance.
    @test !License in plugins
    @test count(p -> p isa Reuse, plugins) == 1
    @test !any(p -> p isa License, plugins)
    reuse = only(p for p in plugins if p isa Reuse)
    @test reuse.package_license == "Apache-2.0"
    @test !reuse.enable_reuse_lint
    t = Template(; user = "test-user", authors = "Test Author", dir = tmp, plugins)
    @test PkgTemplates.getplugin(t, License) === nothing
    @test PkgTemplates.getplugin(t, Readme) === readme_plugin
end

@testitem "direct Reuse removes a License plugin custom destination" tags=[:integration] setup=[WithTempdir] begin
    # Bypass with_reuse so the posthook must remove output from an active License plugin.
    t = Template(;
        user = "test-user", authors = "Test Author", dir = tmp,
        plugins = [!Git, License(; name = "MIT", destination = "COPYING"),
            Reuse(; package_license = "Apache-2.0")])
    t("TestPackage")
    @test !ispath(joinpath(pkg, "COPYING"))
    @test occursin("Apache-2.0", read(license, String))
    @test occursin("Apache License", read(license, String))
    @test !occursin("Permission is hereby granted", read(license, String))
end

@testitem "template overrides render variables and honor a custom README destination" tags=[:integration] setup=[WithTempdir] begin
    using ReusePkgTemplates: TOML

    overrides = joinpath(tmp, "overrides")
    write_templates(overrides)
    # Keep valid TOML and YAML while adding markers that prove each override was rendered.
    open(joinpath(overrides, "REUSE.toml.mustache"), "a") do io
        write(io, "\n# Custom REUSE metadata for {{{PKG}}}.\n")
    end
    write(joinpath(overrides, "README_licensing_section.md.mustache"),
        "License {{{PACKAGE_LICENSE}}} for {{{PKG}}}, {{{YEAR}}} {{{COPYRIGHT_HOLDERS}}}.\n")
    open(joinpath(overrides, "REUSE.yml.mustache"), "a") do io
        write(io, "\n# Custom workflow for {{{PKG}}}.\n")
    end
    t = Template(;
        user = "test-user", authors = "Test Author", dir = tmp,
        plugins = with_reuse([!Git, Readme(; destination = "ABOUT.md")];
            template_dir = overrides, package_license = "Apache-2.0",
            readme_licensing_section = true))
    t("TestPackage")

    about = joinpath(pkg, "ABOUT.md")
    @test !ispath(readme)
    @test occursin("License Apache-2.0 for TestPackage, $current_year Test Author.",
        read(about, String))
    @test occursin("# Custom REUSE metadata for TestPackage.", read(reuse_toml, String))
    @test occursin("# Custom workflow for TestPackage.", read(reuse_ci, String))
    annotations = TOML.parsefile(reuse_toml)["annotations"]
    # File-level licensing must follow the README plugin's custom destination too.
    @test any("ABOUT.md" in a["path"] for a in annotations)
    # Repeating the hook must not append a second licensing section.
    before = read(about, String)
    PkgTemplates.posthook(only(p for p in t.plugins if p isa Reuse), t, pkg)
    @test read(about, String) == before
end

@testitem "generation supports disabled optional plugins" tags=[:integration] setup=[WithTempdir] begin
    using ReusePkgTemplates: TOML

    # Request the optional README section even without a Readme plugin to exercise its guard.
    t = Template(;
        user = "test-user", authors = "Test Author", dir = tmp,
        plugins = with_reuse([!Git, !Readme, !GitHubActions, !SrcDir, !Tests];
            readme_licensing_section = true))
    t("TestPackage")
    @test isfile(license)
    @test isfile(joinpath(licenses, "MIT.txt"))
    @test TOML.parsefile(project)["reuse_licensing"]["package_license_expression"] == "MIT"
    @test !ispath(readme)
    @test !ispath(reuse_ci)
    @test !ispath(sourcefile)
    @test !ispath(testfile)
    # Annotation patterns may mention files that the selected plugins do not generate.
    @test any("README.md" in a["path"] for a in TOML.parsefile(reuse_toml)["annotations"])
end

@testitem "posthook preserves existing headers and metadata and annotates benchmarks" tags=[:integration] setup=[WithTempdir] begin
    using ReusePkgTemplates: TOML

    source_template = joinpath(tmp, "source.jlt")
    # Preserve an explicit Apache header despite the MIT default; annotate bare benchmarks.
    source = "# SPDX-License-Identifier: Apache-2.0\nmodule {{{PKG}}}\nend\n"
    write(source_template, source)
    t = Template(;
        user = "test-user", authors = "Test Author", dir = tmp,
        plugins = with_reuse([!Git, SrcDir(; file = source_template), PkgBenchmark()]))
    t("TestPackage")

    @test read(sourcefile, String) == replace(source, "{{{PKG}}}" => "TestPackage")
    benchmark = joinpath(pkg, "benchmark", "benchmarks.jl")
    @test startswith(read(benchmark, String), "# SPDX-FileCopyrightText: $current_year Test Author\n")
    @test occursin("SPDX-License-Identifier: MIT", read(benchmark, String))
    @test occursin("using BenchmarkTools", read(benchmark, String))

    # Existing declarations belong to the caller, even when different from Reuse's defaults.
    metadata = TOML.parsefile(project)
    metadata["reuse_licensing"]["package_license_expression"] = "Apache-2.0"
    open(project, "w") do io
        TOML.print(io, metadata)
    end
    paths = [project, sourcefile, testfile, benchmark]
    before = read.(paths, String)
    PkgTemplates.posthook(only(p for p in t.plugins if p isa Reuse), t, pkg)
    @test read.(paths, String) == before
end

@testitem "SPDX header insertion handles missing files and CRLF without duplication" tags=[:integration] setup=[WithTempdir] begin
    using ReusePkgTemplates: add_julia_spdx_header

    path = joinpath(tmp, "source.jl")
    header = "# SPDX-FileCopyrightText: $current_year Test Author\n# SPDX-License-Identifier: MIT\n\n"
    add_julia_spdx_header(path, header)
    @test !ispath(path)
    # Empty files have no separator blank line; a source body retains that separator.
    for (label, body, expected) in (
            ("empty source", "",
                "# SPDX-FileCopyrightText: $current_year Test Author\n# SPDX-License-Identifier: MIT\n"),
            ("CRLF source", "module Example\r\nend\r\n", header * "module Example\nend\n")
        )
        @testset "$label" begin
            write(path, body)
            add_julia_spdx_header(path, header)
            @test read(path, String) == expected
            before = read(path)
            add_julia_spdx_header(path, header)
            @test read(path) == before
        end
    end
    # The fifth line is the scan boundary; finding a tag must preserve even CRLF bytes.
    existing = "# First line\r\n# Second\r\n# Third\r\n# Fourth\r\n# SPDX-License-Identifier: Apache-2.0\r\n"
    write(path, existing)
    add_julia_spdx_header(path, header)
    @test read(path, String) == existing
end

# REUSE-IgnoreEnd
