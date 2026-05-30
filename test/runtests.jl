# SPDX-FileCopyrightText: 2026 Guido Wolf Reichert <gwr@bsl-support.de>
# SPDX-License-Identifier: EUPL-1.2+

using TestItemRunner

@run_package_tests

#TODO test that Reuse() will use bundled templates

#TODO test that write_templates(tmpdir) writes expected files

#TODO test that Reuse(templates = tmpdir) uses edited/custom templates

#TODO test a missing `REUSE.toml.mustache` errors cleanly

#TODO missing README template only errors when readme_license_section = true
