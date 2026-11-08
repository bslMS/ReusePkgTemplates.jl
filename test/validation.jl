# SPDX-FileCopyrightText: 2026 Guido Wolf Reichert and contributors
# SPDX-License-Identifier: EUPL-1.2+

# Configuration acceptance and rejection before generation, including approval policies.

using TestItems

@testitem(
    "invalid SPDX expressions identify the configuration domain",
    tags = [:validation],
    setup = [WithTempdir],
    begin
        # Keyword names and diagnostic domain names differ for documentation assets.
        for (field, domain) in (
                (:package_license, "package"),
                (:code_license, "code"),
                (:infrastructure_license, "infrastructure"),
                (:docs_license, "docs"),
                (:docs_assets_license, "assets"),
            )
            @testset "$field" begin
                for (label, expression) in (
                        ("empty expression", ""),
                        ("unknown identifier", "Not-A-License"),
                        ("incomplete conjunction", "MIT AND"),
                    )
                    @testset "$label" begin
                        # Disabling approval checks must not bypass SPDX syntax validation.
                        plugins = with_reuse(
                            [!Git];
                            field => expression,
                            license_policy = :none,
                        )
                        @test_throws "invalid $domain SPDX license expression" Template(;
                            user = "test-user",
                            authors = "Test Author",
                            dir = tmp,
                            plugins,
                        )
                        @test !ispath(pkg)
                    end
                end
            end
        end
    end,
)

@testitem(
    "license policies validate approval paths",
    tags = [:validation],
    setup = [WithTempdir],
    begin
        make_template(; kwargs...) = Template(;
            user = "test-user",
            authors = "Test Author",
            dir = tmp,
            plugins = with_reuse([!Git]; kwargs...),
        )

        @test_throws "license_policy must be" make_template(; license_policy = :unknown)
        # General Registry policy accepts an unconjoined OSI-approved alternative,
        # but a conjunction of approved licenses does not satisfy that requirement.
        @test make_template(; code_license = "MIT OR Apache-2.0") isa Template
        @test_throws "code SPDX license expression" make_template(;
            code_license = "MIT AND Apache-2.0",
        )
        @test_throws "package SPDX license expression" make_template(;
            package_license = "CC-BY-4.0",
        )
        @test_throws "code SPDX license expression" make_template(;
            code_license = "CC-BY-4.0",
        )
        # Non-code domains accept CC-BY-4.0, while CC-BY-NC-4.0 fails approval.
        for field in (:infrastructure_license, :docs_license, :docs_assets_license)
            @test make_template(; field => "CC-BY-4.0") isa Template
            @test_throws "does not have" make_template(; field => "CC-BY-NC-4.0")
        end
        # :none disables approval requirements while retaining syntactically valid SPDX input.
        @test make_template(; package_license = "CC-BY-NC-4.0", license_policy = :none) isa
            Template

        # Both policies must construct the dependency's OSIApproved policy and validate
        # code expressions, including conjunctions accepted beyond General Registry policy.
        for policy in (:free, :osi_approved)
            @testset "$policy" begin
                @test make_template(;
                    code_license = "MIT AND Apache-2.0",
                    license_policy = policy,
                ) isa
                    Template
                # Regression: rejection must report validation, not a missing constructor.
                @test try
                    make_template(; code_license = "CC-BY-NC-4.0", license_policy = policy)
                    false
                catch err
                    err isa ArgumentError &&
                        occursin("code SPDX license expression", err.msg)
                end

                # :free accepts FSF-libre content; :osi_approved requires OSI approval
                # even for non-code domains. Both reject the noncommercial expression.
                for (field, domain) in (
                        (:infrastructure_license, "infrastructure"),
                        (:docs_license, "docs"),
                        (:docs_assets_license, "assets"),
                    )
                    @testset "$field" begin
                        if policy === :free
                            @test make_template(;
                                field => "CC-BY-4.0",
                                license_policy = policy,
                            ) isa
                                Template
                        else
                            @test_throws "$domain SPDX license expression" make_template(;
                                field => "CC-BY-4.0",
                                license_policy = policy,
                            )
                        end
                        @test_throws "$domain SPDX license expression" make_template(;
                            field => "CC-BY-NC-4.0",
                            license_policy = policy,
                        )
                    end
                end
            end
        end
    end,
)

@testitem(
    "LicenseRef validation requires files for every license domain",
    tags = [:validation],
    setup = [WithTempdir],
    begin
        refs = mkpath(joinpath(tmp, "refs"))
        not_a_directory = joinpath(tmp, "file.txt")
        write(not_a_directory, "not a directory")
        # Every domain, including the package-level declaration, must resolve its LicenseRefs.
        for field in (
                :package_license,
                :code_license,
                :infrastructure_license,
                :docs_license,
                :docs_assets_license,
            )
            @testset "$field" begin
                # Bypass approval checks so each failure concerns the supplied license files.
                make_template(; kwargs...) = Template(;
                    user = "test-user",
                    authors = "Test Author",
                    dir = tmp,
                    plugins = with_reuse(
                        [!Git];
                        field => "LicenseRef-Missing",
                        license_policy = :none,
                        kwargs...,
                    ),
                )
                @test_throws "license_ref_dir" make_template()
                @test_throws "existing directory" make_template(;
                    license_ref_dir = joinpath(tmp, "missing"),
                )
                @test_throws "existing directory" make_template(;
                    license_ref_dir = not_a_directory,
                )
                @test_throws "missing LicenseRef files for missing" make_template(;
                    license_ref_dir = refs,
                )
                # Configuration errors must be detected before any package is generated.
                @test !ispath(pkg)
            end
        end
        @test_throws "template_dir" Template(;
            user = "test-user",
            authors = "Test Author",
            dir = tmp,
            plugins = with_reuse([!Git]; template_dir = not_a_directory),
        )
    end,
)
