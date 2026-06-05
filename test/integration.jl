# SPDX-FileCopyrightText: 2026 Guido Wolf Reichert <gwr@bsl-support.de>
# SPDX-License-Identifier: EUPL-1.2+

# REUSE-IgnoreStart
using TestItems

@testsnippet WithTempdir begin
    using Dates: today, year

    tmp = mktempdir()
    pkg = joinpath(tmp, "TestPackage")
    license = joinpath(pkg, "LICENSE")
    reuse_toml = joinpath(pkg, "REUSE.toml")
    readme = joinpath(pkg, "README.md")
    reuse_ci = joinpath(pkg, ".github", "workflows", "REUSE.yml")
    licenses = joinpath(pkg, "LICENSES")
    project = joinpath(pkg, "Project.toml")
    sourcefile = joinpath(pkg, "src", "TestPackage.jl")
    current_year = year(today())
    testfile = joinpath(pkg, "test", "runtests.jl")
end

@testitem "test case has expected files and content" setup=[WithTempdir] begin
    plugins = with_reuse(;
        package_license = "EUPL-1.2+",
        code_license = "MIT",
        docs_license = "CC-BY-4.0",
        docs_assets_license = "CC-BY-SA-4.0",
        infrastructure_license = "0BSD",
        readme_license_section = true
    )

    t = Template(;
        user = "test-user",
        authors = "Test Author <test@example.org>",
        dir = tmp,
        plugins
    )
    t("TestPackage")
    pkg = joinpath(tmp, "TestPackage")

    @test isfile(license)
    @test isfile(reuse_toml)
    @test isdir(licenses)
    @test isfile(reuse_ci)
    @test isfile(readme)
    @test isfile(joinpath(licenses, "MIT.txt"))
    @test isfile(joinpath(licenses, "CC-BY-4.0.txt"))
    @test isfile(joinpath(licenses, "CC-BY-SA-4.0.txt"))
    @test isfile(joinpath(licenses, "0BSD.txt"))
    @test !isfile(joinpath(licenses, "EUPL-1.2.txt"))

    @test occursin("EUPL-1.2+", read(license, String))
    @test occursin("European Union Member State", read(license, String))
    @test occursin("Appendix", read(license, String))
    @test occursin("MIT", read(joinpath(licenses, "MIT.txt"), String))
    @test occursin(
        "Creative Commons Attribution-ShareAlike 4.0",
        read(joinpath(licenses, "CC-BY-SA-4.0.txt"), String)
    )
    @test occursin("[reuse_licensing]", read(project, String))
    @test occursin("package_license_expression", read(project, String))
    @test occursin("EUPL-1.2+", read(project, String))
    @test occursin(
        "SPDX-FileCopyrightText = \"$current_year Test Author <test@example.org>\"",
        read(reuse_toml, String)
    )
    @test occursin(
        "SPDX-License-Identifier = \"0BSD\"",
        read(reuse_toml, String)
    )
    @test occursin(
        "SPDX-License-Identifier = \"CC-BY-4.0\"",
        read(reuse_toml, String)
    )
    @test occursin(
        "SPDX-License-Identifier = \"CC-BY-SA-4.0\"",
        read(reuse_toml, String)
    )
    @test !occursin(
        "SPDX-License-Identifier = \"MIT\"",
        read(reuse_toml, String)
    )
    @test !occursin(
        "SPDX-License-Identifier = \"EUPL-1.2+\"",
        read(reuse_toml, String)
    )
    @test occursin(
        "SPDX-License-Identifier: MIT",
        read(sourcefile, String)
    )
    @test occursin(
        "SPDX-FileCopyrightText: $current_year Test Author <test@example.org>",
        read(sourcefile, String)
    )
    @test occursin(
        "SPDX-License-Identifier: MIT",
        read(testfile, String)
    )
    @test occursin(
        "SPDX-FileCopyrightText: $current_year Test Author <test@example.org>",
        read(testfile, String)
    )

    # No duplication of [reuse_licensing] if posthook is repeated.
    reuse = only(p for p in t.plugins if p isa Reuse)
    PkgTemplates.posthook(reuse, t, pkg)
    @test length(findall("[reuse_licensing]", read(project, String))) == 1
end

@testitem "write complete set of templates to directory" begin
    dir = mktempdir()
    write_templates(dir)

    @test isfile(joinpath(dir, "REUSE.toml.mustache"))
    @test isfile(joinpath(dir, "README_license_section.md.mustache"))
    @test isfile(joinpath(dir, "REUSE.yml.mustache"))
    @test !isfile(joinpath(dir, ".DS_Store"))
end

@testitem "refuse to overwrite templates without force=true" begin
    dir = mktempdir()
    write_templates(dir)
    @test_throws ArgumentError write_templates(dir)
    write_templates(dir; force = true)
    @test isfile(joinpath(dir, "REUSE.toml.mustache"))
end

@testitem "fallback to templates if only one template is given" setup=[WithTempdir] begin
    dir = mktempdir()
    write(joinpath(dir, "README_license_section.md.mustache"),
        "Custom licensing section.\n")

    plugins = with_reuse(;
        package_license = "EUPL-1.2+",
        template_dir = dir,
        readme_license_section = true
    )

    t = Template(;
        user = "test-user",
        authors = "Test Author <test@example.org>",
        dir = tmp,
        plugins
    )
    t("TestPackage")
    pkg = joinpath(tmp, "TestPackage")

    @test occursin("Custom licensing section.", read(readme, String))
    # fallback still used for REUSE.toml.mustache
    @test occursin("version = 1", read(reuse_toml, String))
end

@testitem "plugin composition rejects Reuse and removes License plugins" begin
    @test_throws ArgumentError with_reuse([Reuse()])

    plugins = with_reuse([License()])
    @test !any(p -> p isa License, plugins)
    @test any(p -> p isa Reuse, plugins)
end

@testitem "no ci workflow for enable_reuse_lint = false" setup=[WithTempdir] begin
    plugins = with_reuse(;
        enable_reuse_lint = false
    )

    t = Template(;
        user = "test-user",
        authors = "Test Author <test@example.org>",
        dir = tmp,
        plugins
    )
    t("TestPackage")
    pkg = joinpath(tmp, "TestPackage")

    @test isfile(license)
    @test isfile(reuse_toml)
    @test isdir(licenses)
    @test !isfile(reuse_ci)
    @test isfile(readme)
end

@testitem "missing template_dir throws error" setup=[WithTempdir] begin
    plugins = with_reuse(; template_dir = "")
    @test_throws ArgumentError Template(;
        user = "test-user",
        authors = "Test Author <test@example.org>",
        dir = tmp,
        plugins
    )
end

@testitem "package-level copyright_holders differ from authors" setup=[WithTempdir] begin
    plugins = with_reuse(;
        copyright_holders = ["Aron", "Berta", "Charlie"]
    )

    t = Template(;
        user = "test-user",
        authors = "Test Author <test@example.org>",
        dir = tmp,
        plugins
    )
    t("TestPackage")
    pkg = joinpath(tmp, "TestPackage")

    copyright_notice = "Copyright © $current_year Aron, Berta, and Charlie"
    @test occursin(copyright_notice, read(license, String))
    @test occursin(
        "SPDX-FileCopyrightText: $current_year Test Author <test@example.org>",
        read(sourcefile, String)
    )
    @test occursin(copyright_notice, read(project, String))
    @test !occursin(copyright_notice, read(reuse_toml, String))
end

@testitem "copyright_holders must not be empty" setup=[WithTempdir] begin
    plugins = with_reuse(; copyright_holders = String[])
    @test_throws ArgumentError Template(;
        user = "test-user",
        authors = "Test Author <test@example.org>",
        dir = tmp,
        plugins
    )
end

@testitem "copyright_holders must not be blank holder" setup=[WithTempdir] begin
    plugins = with_reuse(; copyright_holders = String[" "])
    @test_throws ArgumentError Template(;
        user = "test-user",
        authors = "Test Author <test@example.org>",
        dir = tmp,
        plugins
    )
end

@testitem "copyright_holders must not contain blank amid valid holders" setup=[WithTempdir] begin
    plugins = with_reuse(; copyright_holders = String[" ", "Anton"])
    @test_throws ArgumentError Template(;
        user = "test-user",
        authors = "Test Author <test@example.org>",
        dir = tmp,
        plugins
    )
end

# REUSE-IgnoreEnd
