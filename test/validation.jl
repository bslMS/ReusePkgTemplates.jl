# SPDX-FileCopyrightText: 2026 Guido Wolf Reichert and contributors
# SPDX-License-Identifier: EUPL-1.2+

# Configuration acceptance and rejection before generation, including approval policies.

using TestItems

@testitem "license policies validate approval paths" tags=[:validation] setup=[WithTempdir] begin
    make_template(; kwargs...) = Template(;
        user = "test-user", authors = "Test Author", dir = tmp,
        plugins = with_reuse([!Git]; kwargs...))

    @test_throws "license_policy must be" make_template(; license_policy = :unknown)
    # General Registry policy accepts an unconjoined OSI-approved alternative,
    # but a conjunction of approved licenses does not satisfy that requirement.
    @test make_template(; code_license = "MIT OR Apache-2.0") isa Template
    @test_throws "code SPDX license expression" make_template(;
        code_license = "MIT AND Apache-2.0")
    @test_throws "package SPDX license expression" make_template(;
        package_license = "CC-BY-4.0")
    @test_throws "code SPDX license expression" make_template(; code_license = "CC-BY-4.0")
    # Non-code domains accept CC-BY-4.0, while CC-BY-NC-4.0 fails approval.
    for field in (:infrastructure_license, :docs_license, :docs_assets_license)
        @test make_template(; field => "CC-BY-4.0") isa Template
        @test_throws "does not have" make_template(; field => "CC-BY-NC-4.0")
    end
    # :none disables approval requirements while retaining syntactically valid SPDX input.
    @test make_template(;
        package_license = "CC-BY-NC-4.0", license_policy = :none) isa Template

    # Both policies must construct the dependency's OSIApproved policy and validate
    # code expressions, including conjunctions accepted beyond General Registry policy.
    for policy in (:free, :osi_approved)
        @testset "$policy" begin
            @test make_template(;
                code_license = "MIT AND Apache-2.0", license_policy = policy) isa Template
            # Regression: rejection must report validation, not a missing constructor.
            @test try
                make_template(; code_license = "CC-BY-NC-4.0", license_policy = policy)
                false
            catch err
                err isa ArgumentError && occursin("code SPDX license expression", err.msg)
            end

            # :free accepts FSF-libre content; :osi_approved requires OSI approval
            # even for non-code domains. Both reject the noncommercial expression.
            for (field, domain) in (
                    (:infrastructure_license, "infrastructure"), (:docs_license, "docs"),
                    (:docs_assets_license, "assets")
                )
                @testset "$field" begin
                    if policy === :free
                        @test make_template(;
                            field => "CC-BY-4.0", license_policy = policy) isa Template
                    else
                        @test_throws "$domain SPDX license expression" make_template(;
                            field => "CC-BY-4.0", license_policy = policy)
                    end
                    @test_throws "$domain SPDX license expression" make_template(;
                        field => "CC-BY-NC-4.0", license_policy = policy)
                end
            end
        end
    end
end
