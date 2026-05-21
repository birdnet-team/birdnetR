# Contributing to birdnetR

Thank you for your interest in contributing to birdnetR! This document
covers the development workflow, branching strategy, versioning
conventions, and release process for maintainers and contributors.

## Branch model

| Branch | Purpose |
|----|----|
| `main` | Default branch. All development and releases happen here. |
| `feature/*`, `fix/*` | Short-lived branches for individual changes. Target `main` via PR. |
| `release/x.y.z` | Short-lived branch cut from `main` to prepare a CRAN submission. Merged back into `main` after acceptance, then deleted. |

There is no long-lived development branch. Day-to-day work goes directly
into `main` via pull requests from feature or fix branches.

## Versioning

birdnetR follows [semantic versioning](https://semver.org):
`MAJOR.MINOR.PATCH`.

- **Released versions** (on CRAN): `x.y.z` — e.g. `0.3.2`
- **Development versions** (on `main` between releases): `x.y.z.9000` —
  e.g. `0.3.3.9000`

The `.9000` suffix is the conventional R development version indicator
(see
[r-pkgs](https://r-pkgs.org/lifecycle.html#sec-lifecycle-version-number)).
It signals that `main` contains work beyond the last CRAN release.

After a release is merged back into `main`, bump the version in
`DESCRIPTION` immediately:

    Version: 0.3.3.9000

## pkgdown documentation

pkgdown deploys **only from `main`** via GitHub Actions. The version in
`DESCRIPTION` determines which variant is published:

| Version on `main` | Docs destination | URL |
|----|----|----|
| `x.y.z` (release) | stable | `https://birdnet-team.github.io/birdnetR/` |
| `x.y.z.9000` (dev) | development | `https://birdnet-team.github.io/birdnetR/dev/` |

This is handled automatically by `_pkgdown.yml` with
`development: mode: auto`. No manual configuration is needed — just keep
the version in `DESCRIPTION` consistent with the conventions above.

Feature/fix branches and `release/*` branches do **not** trigger pkgdown
builds.

This also aligns with `pak::pak("birdnet-team/birdnetR")`, which
installs from the default branch (`main`).

## Release workflow

Releases are prepared on a short-lived `release/x.y.z` branch so that
CRAN-specific housekeeping does not block ongoing feature work on
`main`.

    main  ──►  release/x.y.z  ──►  main

### Checklist

1.  **Cut release branch** from `main`:

        git checkout -b release/0.3.2 main

2.  **Finalize version** — set `Version: 0.3.2` in `DESCRIPTION` (remove
    `.9000`).

3.  **Update `NEWS.md`** — add a dated entry for the new version; move
    items from the development section.

4.  **Check the package**:

    ``` r

    devtools::check()
    rcmdcheck::rcmdcheck(args = c("--as-cran"))
    ```

5.  **Update `cran-comments.md`** with submission notes.

6.  **Submit to CRAN**:

    ``` r

    devtools::submit_cran()
    ```

7.  **After CRAN acceptance**, merge `release/x.y.z` into `main` and tag
    the release:

        git checkout main && git merge --no-ff release/0.3.2
        git tag v0.3.2
        git push --tags

8.  **Bump version on `main`** — set `Version: 0.3.3.9000` in
    `DESCRIPTION`.

9.  **Delete the release branch**: `git branch -d release/0.3.2`

## Code style

birdnetR uses [tidyverse style](https://style.tidyverse.org). Run
`styler::style_pkg()` before submitting a pull request.

## Getting help

Open an issue on
[GitHub](https://github.com/birdnet-team/birdnetR/issues) for bug
reports and feature requests.
