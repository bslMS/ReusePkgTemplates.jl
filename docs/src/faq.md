```@meta
CurrentModule = ReusePkgTemplates
```

# [Licensing FAQ](@id licensing-faq)

!!! warning "This is not legal advice"
    This FAQ explains the licensing model assumed by `ReusePkgTemplates.jl` and
    the REUSE/SPDX metadata it generates. It also states the licensing assumptions
    and policy opinions that motivate the package design. It is technical
    documentation, not a legal opinion. For binding legal decisions, especially
    publication, redistribution, relicensing, or registry policy questions,
    consult a qualified lawyer.

## Why is this not just a PkgTemplates.jl pull request?

REUSE support is not an ordinary additive plugin. It maps over the generated
repository: file headers, generated license texts, `REUSE.toml`, root `LICENSE`,
`Project.toml` metadata, and CI checks all need to agree.

That makes REUSE support cross-cutting in a way that does not fit cleanly beside
PkgTemplates.jl's traditional `License` plugin. The latter reflects the common
single-license workflow; `ReusePkgTemplates.jl` instead distinguishes
file-level SPDX metadata from the package-level license declaration.

For that reason this package wraps PkgTemplates.jl rather than replacing it or
requiring PkgTemplates.jl itself to adopt a more opinionated licensing model.

## Why not just use one license for a package?

### File-level licensing: the inbound licensing problem

If all relevant files in a repository are source code and are intended to be
distributed under the same terms, a single package-level license declaration can
be clear and sufficient.

But many package repositories are not that uniform and will contain documentation,
diagrams, generated files, data, configuration files, assets, and project
infrastructure. Applying a single software license to all of these materials can be
misleading or impossible, especially when imported material may only be
redistributed under its existing terms.

This is especially visible for data: public-sector and research-data guidance
commonly treats datasets and databases as their own licensing problem, with
dedicated recommendations such as Datenlizenz Deutschland, CC0, CC BY, or Open
Data Commons licenses.

### Package-level licensing: the outbound licensing problem

A package-level license declaration answers a different question: under which
terms is the package intended to be distributed as a combined work?

There are good reasons for permissive, weak-copyleft, and strong-copyleft open
source licenses. The right choice depends on the goals of the package authors.
For example, a package may use a copyleft license as its package-level
declaration while still containing some files under more permissive licenses
where that is appropriate.

`ReusePkgTemplates.jl` therefore separates two questions: What is the intended
outbound license for the package as distributed? What license applies to each
individual file?

The root `LICENSE` file accordingly records the outbound package-level
license declaration and the license texts it references. File-level licensing
is recorded through SPDX metadata and, in accordance with REUSE, the corresponding
license texts are collected under `LICENSES/`.

## Why not leave outbound licensing to SBOM tooling?

SBOM tooling can describe files, components, dependencies, and license metadata.
That information is useful evidence for review, but it does not declare
the terms under which the package author intends to distribute it as a software work.

Outbound licensing is not a purely mechanical aggregation of file-level licenses
or dependency metadata. It involves an intentional legal and policy decision by
the copyright holder or distributor: what is the licensed work, under which terms
is it offered, and under which assumptions is that declaration meant to hold?

`ReusePkgTemplates.jl` therefore treats SBOM-style metadata and tooling as
supporting evidence, not as substitutes for an explicit package-level license
declaration.

## Should dependency licenses influence the package-level license declaration?

Yes, probably for dependencies that are expected to be used with the package in ordinary
operation or that are commonly distributed together with it.

A package-level license declaration is not a mechanical aggregation of dependency
licenses, and it does not relicense dependencies. Dependencies remain governed by
their own licenses. Still, the package-level declaration should be made with the
expected dependency environment in mind. A package that normally depends on
copyleft components, generated artifacts, extensions, or binary libraries deserves
closer review before choosing a permissive package-level declaration.

This is one reason why a permissive license such as MIT is not always the most
informative package-level declaration. A permissive declaration can be clear for
the package author's own files, but it may give an incomplete impression if the
package is practically inseparable from components that impose additional
redistribution obligations.

For example, a package may contain mostly MIT-licensed project-authored files and
still be distributed, in its ordinary instantiated form, together with mandatory
copyleft dependencies. In that situation the MIT file-level notices remain true,
but they do not by themselves describe the licensing obligations of the complete
functional distribution.

`ReusePkgTemplates.jl` therefore treats dependency licensing as a separate review
problem, but not as an irrelevant one. Dependency licenses are not automatically
folded into the package-level declaration, yet expected dependencies should inform
the licensing policy chosen for the package and the warnings recorded in the
licensing documentation.

## Further reading

The following external resources are useful starting points for the licensing
model assumed by this package:

- [REUSE](https://reuse.software/) for file-level licensing metadata and the
  `LICENSES/` repository layout.
- [SPDX](https://spdx.dev/) for standardized license identifiers, license
  expressions, and software bill of materials conventions.
- [Interoperable Europe's Licensing Assistant](https://interoperable-europe.ec.europa.eu/collection/eupl/solution/licensing-assistant)
  for comparing, selecting, and checking compatibility of open source software
  licenses in a European public-sector context.
- [GovData's guidance on data licenses](https://www.govdata.de/informationen/lizenzen)
  for German public-sector data licensing guidance [in German].
- The [DCAT-AP.de license list](https://www.dcat-ap.de/def/licenses/) for
  standardized license identifiers used in German DCAT-AP metadata.
- [data.europa.eu's report on licence compatibility in Europe](https://data.europa.eu/sites/default/files/report/Licence%20compatibility%20in%20Europe%20a%20winding%20road%20to%20Creative%20Commons_ENG_0.pdf)
  for a European data-license compatibility discussion.
- [OpenAIRE's research data licensing guidance](https://www.openaire.eu/how-do-i-license-my-research-data)
  for research data licensing recommendations.
