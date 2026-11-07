# SPDX-FileCopyrightText: 2026 Guido Wolf Reichert and contributors
# SPDX-License-Identifier: EUPL-1.2+

# Generated licensing content: defaults, SPDX expressions, license texts, metadata,
# and REUSE compliance.

# SPDX strings below are test data, not licensing declarations for this file.
# REUSE-IgnoreStart
using TestItems

@testitem "default licenses and fallback domains appear in generated metadata" tags = [
    :integration,
    :licensing,
] setup = [WithTempdir] begin
    using ReusePkgTemplates: TOML

    # Expected license order: package, code, infrastructure, documentation, assets.
    cases = (
        ("all defaults", (;), ("MIT", "MIT", "MIT", "MIT", "MIT")),
        (
            "separate documentation fallback",
            (; package_license = "Apache-2.0", docs_license = "CC-BY-4.0"),
            ("Apache-2.0", "Apache-2.0", "Apache-2.0", "CC-BY-4.0", "CC-BY-4.0"),
        ),
        (
            "code overrides package fallback",
            (; package_license = "Apache-2.0", code_license = "MIT"),
            ("Apache-2.0", "MIT", "MIT", "MIT", "MIT"),
        ),
    )
    for (i, (label, options, expected)) in enumerate(cases)
        @testset "$label" begin
            dir = mkpath(joinpath(tmp, string(i)))
            t = Template(;
                user = "test-user",
                authors = ["First Author", "Second Author"],
                dir,
                plugins = with_reuse([!Git]; options...),
            )
            t("TestPackage")
            generated = joinpath(dir, "TestPackage")
            metadata = TOML.parsefile(joinpath(
                generated,
                "Project.toml",
            ))["reuse_licensing"]
            annotations = TOML.parsefile(joinpath(generated, "REUSE.toml"))["annotations"]
            package_license, code, infrastructure, docs, assets = expected
            @test metadata["package_license_expression"] == package_license
            @test metadata["package_copyright_notice"] ==
                "Copyright © $current_year First Author and Second Author"
            @test metadata["package_license_file"] == "LICENSE"
            @test occursin(package_license, read(joinpath(generated, "LICENSE"), String))
            @test [a["SPDX-License-Identifier"] for a in annotations] ==
                [infrastructure, assets, docs]
            @test all(
                a["SPDX-FileCopyrightText"] ==
                    "$current_year First Author and Second Author"
                for a in annotations
            )
            @test Set(readdir(joinpath(generated, "LICENSES"))) ==
                Set(id * ".txt" for id in (code, infrastructure, docs, assets))
            @test occursin(
                "SPDX-License-Identifier: $code",
                read(joinpath(generated, "src", "TestPackage.jl"), String),
            )
            @test !occursin(
                "PkgTemplates: REUSE licensing section start",
                read(joinpath(generated, "README.md"), String),
            )
        end
    end
end

@testitem "compound SPDX expressions vendor license and exception texts separately" tags = [
    :integration,
    :licensing,
] setup = [WithTempdir] begin
    using ReusePkgTemplates: TOML
    using ReusePkgTemplates: ReuseLicensing

    expression = "(GPL-2.0+ WITH Classpath-exception-2.0) OR MIT"
    normalized = "GPL-2.0-or-later WITH Classpath-exception-2.0 OR MIT"
    # Disable approval checks to isolate normalization and text generation;
    # SPDX syntax validation still runs.
    t = Template(;
        user = "test-user",
        authors = "Test Author",
        dir = tmp,
        plugins = with_reuse([!Git]; package_license = expression, license_policy = :none),
    )
    t("TestPackage")

    metadata = TOML.parsefile(project)["reuse_licensing"]
    # Parentheses may be retained by the SPDX normalizer.
    @test replace(metadata["package_license_expression"], '(' => "", ')' => "") ==
        normalized
    @test occursin(
        "GPL-2.0-or-later WITH Classpath-exception-2.0",
        read(sourcefile, String),
    )
    @test !occursin("GPL-2.0+", read(sourcefile, String))
    @test Set(readdir(licenses)) ==
        Set(["GPL-2.0-or-later.txt", "Classpath-exception-2.0.txt", "MIT.txt"])
    for id in ("GPL-2.0-or-later", "MIT")
        text = read(ReuseLicensing.spdx_license_text_path(id), String)
        @test read(joinpath(licenses, id * ".txt"), String) == text
        @test occursin(
            chomp(ReuseLicensing.normalize_line_endings(text)),
            read(license, String),
        )
    end
    exception_text = read(
        ReuseLicensing.spdx_license_exception_text_path("Classpath-exception-2.0"),
        String,
    )
    @test read(joinpath(licenses, "Classpath-exception-2.0.txt"), String) == exception_text
    @test occursin(
        chomp(ReuseLicensing.normalize_line_endings(exception_text)),
        read(license, String),
    )
end

@testitem "LicenseRef files are copied or rendered with Mustache precedence" tags = [
    :integration,
    :licensing,
] setup = [WithTempdir] begin
    refs = mkpath(joinpath(tmp, "refs"))
    # Plain text must retain its placeholders and CRLF endings when copied.
    plain = "Plain license for {{{PKG}}}.\r\nKeep placeholders verbatim.\r\n"
    write(joinpath(refs, "LicenseRef-Plain.txt"), plain)
    # Supply both forms to verify that the rendered Mustache file takes precedence.
    write(joinpath(refs, "LicenseRef-Custom.txt"), "SHADOWED plain license")
    write(
        joinpath(refs, "LicenseRef-Custom.txt.mustache"),
        "Rendered license for {{{PKG}}}, {{{YEAR}}} {{{AUTHORS}}}.\n",
    )
    # Package-only terms belong in LICENSE; LICENSES/ serves file-level licenses.
    write(joinpath(refs, "LicenseRef-PackageOnly.txt"), "Package-only terms.\n")
    write(joinpath(refs, "unrelated.txt"), "Ignore this file.")
    write(joinpath(refs, "LicenseRef-Ignored.md"), "Ignore this extension.")
    # Allow custom licenses without applying approval requirements.
    t = Template(;
        user = "test-user",
        authors = "Test Author",
        dir = tmp,
        plugins = with_reuse(
            [!Git];
            package_license = "LicenseRef-Plain AND LicenseRef-Custom AND LicenseRef-PackageOnly",
            code_license = "LicenseRef-Plain OR LicenseRef-Custom",
            license_ref_dir = refs,
            license_policy = :none,
        ),
    )
    t("TestPackage")

    @test Set(readdir(licenses)) == Set(["LicenseRef-Plain.txt", "LicenseRef-Custom.txt"])
    @test read(joinpath(licenses, "LicenseRef-Plain.txt"), String) == plain
    rendered = "Rendered license for TestPackage, $current_year Test Author."
    @test chomp(read(joinpath(licenses, "LicenseRef-Custom.txt"), String)) == rendered
    package_text = read(license, String)
    @test occursin(replace(chomp(plain), "\r\n" => "\n"), package_text)
    @test occursin(rendered, package_text)
    @test occursin("Package-only terms.", package_text)
    @test !occursin("SHADOWED", package_text)
    @test !occursin('\r', package_text)
    @test occursin(
        "SPDX-License-Identifier: LicenseRef-Plain OR LicenseRef-Custom",
        read(sourcefile, String),
    )
end

@testitem "generated package passes REUSE lint" tags = [:integration, :licensing] setup = [
    WithTempdir,
] begin
    using ReusePkgTemplates: TOML

    t = Template(;
        user = "test-user",
        authors = "Test Author <test@example.org>",
        dir = tmp,
        plugins = with_reuse(
            [!Git];
            package_license = "Apache-2.0",
            code_license = "MIT",
            infrastructure_license = "0BSD",
            docs_license = "CC-BY-4.0",
            readme_licensing_section = true,
        ),
    )
    t("TestPackage")

    @test TOML.parsefile(project)["name"] == "TestPackage"
    @test TOML.parsefile(reuse_toml)["version"] == 1
    @test occursin("fsfe/reuse-action@", read(reuse_ci, String))
    @test occursin("[`LICENSE`](LICENSE)", read(readme, String))
    # Load the generated package without inheriting the developer's startup file.
    @test success(
        `$(Base.julia_cmd()) --startup-file=no --project=$pkg -e 'using TestPackage'`,
    )
    # The external CLI is optional; report its absence as an explicit skipped check.
    reuse = Sys.which("reuse")
    if reuse === nothing
        @test_skip "reuse CLI is unavailable"
    else
        output = IOBuffer()
        command = Cmd(`$reuse lint`; dir = pkg)
        # Capture failure diagnostics before asserting on the exit status.
        result = run(pipeline(ignorestatus(command); stdout = output, stderr = output))
        report = String(take!(output))
        success(result) || @error "Generated package failed REUSE lint" report
        @test success(result)
    end
end

# REUSE-IgnoreEnd
