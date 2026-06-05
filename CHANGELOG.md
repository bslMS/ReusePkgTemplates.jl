<!--
SPDX-FileCopyrightText: 2026 Guido Wolf Reichert <gwr@bsl-support.de>
SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## [0.1.0] - 2026-06-05

### Added

- Initial release of `ReusePkgTemplates.jl`.
- Added the `Reuse` plugin for generating REUSE-oriented Julia package scaffolds.
- Added the `with_reuse` helper for composing ordinary PkgTemplates plugins with
  REUSE support while disabling PkgTemplates' conventional `License` plugin.
- Added generation of `REUSE.toml`, `LICENSES/`, package-level `LICENSE` content,
  `[reuse_licensing]` metadata in `Project.toml`, and SPDX headers for generated
  Julia source and test files.
- Added optional README licensing section generation with
  `readme_licensing_section`.
- Added optional REUSE lint GitHub Actions workflow generation when
  `GitHubActions` is present.
- Added template customization support through `write_templates` and
  `template_dir` for ReusePkgTemplates-owned `.mustache` templates.
- Added package-level copyright holder configuration through `copyright_holders`.
- Added release-scoped manifest evidence under `.licensing/`.
- Added documentation, REUSE compliance workflow, CI, and Codecov upload setup.

### Notes

- Package-level `LICENSE` and `Project.toml` metadata templates are owned by
  `ReuseLicensing.jl`; `ReusePkgTemplates.jl` exposes only its own template files
  through `write_templates`.

[Unreleased]: https://github.com/bslMS/ReusePkgTemplates.jl/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/bslMS/ReusePkgTemplates.jl/releases/tag/v0.1.0
