```@meta
CurrentModule = ReusePkgTemplates
```

# [SPDX License Expressions](https://spdx.github.io/spdx-spec/v2.3/SPDX-license-expressions/)

- Use SPDX license identifiers and expressions such as `MIT`, `Apache-2.0`,
  `GPL-3.0-or-later`, or `MIT OR Apache-2.0`.
- Deprecated GNU-style identifiers such as `GPL-3.0` and `GPL-3.0+` are accepted
  as a convenience and normalized to modern SPDX identifiers such as `GPL-3.0-only` and
  `GPL-3.0-or-later`.
- A trailing `+` may be used for "or later" style expressions where applicable,
  e.g., `EUPL-1.2+`.
- `Reuse` writes parsed and normalized SPDX expressions to `REUSE.toml`. License and
  exception texts copied to `LICENSES/` and `LICENSE` are selected from the SPDX
  identifiers referenced by those expressions.
- Custom license texts may be referenced with `LicenseRef-...` identifiers. The
  corresponding text must be provided in `license_ref_dir`.

# [License Approval Policies](https://bsl-support.de/julia/ReuseLicensing.jl/approval/#ReuseLicensing.UnconjoinedOSIApproval)

`license_policy` must be one of the following symbols: `:general_registry`,
`:osi_approved`, `:free`, or `:none`.

- `license_policy = :general_registry` requires that `package_license` and `code_license`
  expression have an [unconjoined OSI-approved path](https://bsl-support.de/julia/ReuseLicensing.jl/approval/#ReuseLicensing.UnconjoinedOSIApproval)
  Currently, General Registry expects that `package_license` resolves to a single
  OSI-approved license without exception.

  All other license expressions must either have an unconjoined OSI-approved or an
  [open content path](https://bsl-support.de/julia/ReuseLicensing.jl/approval/#ReuseLicensing.OpenContentApproval).

- `license_policy = :osi_approved` requires that all license expressions have an
  [OSI-approved path](https://bsl-support.de/julia/ReuseLicensing.jl/approval/#ReuseLicensing.OSIApproved).
  Under this policy a conjunction of OSI-approved licenses is admissable.

- `license_policy = :free` requires that `package_license` and `code_license` expressions
  have an
  [OSI-approved path](https://bsl-support.de/julia/ReuseLicensing.jl/approval/#ReuseLicensing.OSIApproved),
  and that non-code expressions either have an OSI-approved or an
  [FSF libre](https://bsl-support.de/julia/ReuseLicensing.jl/approval/#ReuseLicensing.FSFLibre)
  approved path.

- `license_policy = :none` requires valid SPDX license expressions that may contain custom
  `LicenseRef-...` identifiers.

!!! note "General Registry Approval"
  The `:general_registry` approval is by no means a guarantee for an admissible format
  to Julia's General Registry registration. It is the authors best attempt at helping to
  shape a REUSE-compliant repository in such a way that it will likely meet upon a favorable
  review.
