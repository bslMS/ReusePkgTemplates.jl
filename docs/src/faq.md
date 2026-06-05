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

## Why is this not just a PkgTemplates pull request?

REUSE support is not an ordinary plugin addition as it maps over the generated
repository: file headers, generated license texts, `REUSE.toml`, root `LICENSE`,
`Project.toml` metadata, and CI checks all need to agree.

That makes REUSE support cross-cutting in a way that does not fit cleanly beside
PkgTemplates' traditional `License` plugin. The latter reflects the common
single-license workflow; ReusePkgTemplates instead distinguishes
file-level SPDX metadata from the package-level license declaration.

For that reason this package wraps PkgTemplates rather than replacing it or
requiring PkgTemplates.jl itself to adopt a more opinionated licensing model.

## Why not just use a single license?

### [File-Level Licensing: The Inbound Licensing Problem](@id inbound-licensing)

If all relevant files in a repository are source code and are intended to be
distributed under the same terms, a single package-level license declaration can
be clear and sufficient.

But many package repositories are not that uniform and will contain documentation,
documentation assets, generated files, data, configuration files, and other project
infrastructure. Applying a single software license to all of these materials can be
misleading or even impossible, especially when imported material may only be
redistributed under its existing terms.

This is especially visible for data: public-sector and research-data guidance
commonly treats datasets and databases as their own licensing problem, with
dedicated recommendations such as Datenlizenz Deutschland, CC0, CC BY, or Open
Data Commons licenses.

For imported non-code material, merely linking to an external source is often
weaker than recording the applicable license information in the repository: links
can break and targets can change.

### [Package-Level Licensing: The Outbound Licensing Problem](@id outbound-licensing)

A package-level license declaration answers a different question: under which
terms is the package intended to be distributed as a combined work?

There are good reasons for permissive, weak-copyleft, and strong-copyleft open
source licenses. The right choice depends on the goals of the copyright holders.
For example, a package may use a copyleft license as its package-level
declaration while still containing some files under more permissive licenses
where that is appropriate.

ReusePkgTemplates therefore separates two questions: What is the intended
outbound license for the package as distributed? What license applies to each
individual file?

The root `LICENSE` file accordingly records the package-level
license expression and the license texts it references. File-level licensing
is recorded through SPDX metadata and optionally a `REUSE.toml`. In accordance with REUSE,
the corresponding license texts are collected under `LICENSES/`.

## Why not leave outbound licensing to SBOM tooling?

SBOM tools are useful. They list files, components, "dependency
closures", and license metadata. But they do not answer the main outbound licensing
question: under which terms may the combined work be distributed?

SBOM and SPDX tools usually keep dependencies as separate components with their
own license data. For example, the `PackageLicenseDeclared` is not meant to cover external
code dependencies. That is the right _technical_ model for component accounting. But
licensing is _declarative_ and _relational_: someone who distributes a combined work has
to make an informed decision under which terms that combined work can be distributed,
modified, copied, and used. An SBOM cannot make a decision — it is not a copyright holder.

## Should dependency licenses influence the package-level license declaration?

In my opinion, for dependencies that are expected to be used with the package in ordinary
operation the answer rather firmly is: yes.

A package-level license declaration is not a mechanical aggregation of dependency
licenses, and it does not relicense dependencies. Dependencies remain governed by
their own licenses. Still, the package-level declaration should be made with the
expected dependency environment in mind. A package with mandatory copyleft
dependencies, generated artifacts, extensions, or binary libraries should be
reviewed carefully before it is declared permissively licensed at package level.

This is one reason why MIT is not always an adequate package-level declaration.
MIT may be correct for individual files in the package, but it may give a misleading
impression if the expected combined package is practically inseparable from components
that impose additional redistribution obligations (e.g., copyleft licenses).

Dependency licenses are not just "folded" into the package-level declaration merely
because they appear in a dependency closure. Instead, tightly coupled, expected
dependencies should inform the licensing policy chosen for the package.

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
