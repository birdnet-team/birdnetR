# Contributing to birdnetR

Thank you for your interest in contributing to birdnetR! This document covers the development workflow, branching strategy, versioning conventions, and release process for maintainers and contributors.

## Branch model

| Branch | Purpose |
|--------|--------|
| `main` | Default branch. All development happens here. |
| `feature/*`, `fix/*` | Short-lived branches for individual changes. Target `main` via PR. |
| `release/x.y.z` | Short-lived branch cut from `main` to prepare a CRAN submission. Merged back into `main` after acceptance, then deleted. |

There is no long-lived development branch. Day-to-day work goes directly into `main` via pull requests from feature or fix branches.

## Versioning

birdnetR follows [semantic versioning](https://semver.org): `MAJOR.MINOR.PATCH`.

- **Released versions** (on CRAN): `x.y.z` — e.g. `0.3.2`
- **Development versions** (on `main` between releases): `x.y.z.9000` — e.g. `0.3.3.9000`

The `.9000` suffix is the conventional R development version indicator (see [r-pkgs](https://r-pkgs.org/lifecycle.html#sec-lifecycle-version-number)). It signals that `main` contains work beyond the last CRAN release.

After a release is merged back into `main`, bump the version in `DESCRIPTION` immediately:

```
Version: 0.3.3.9000
```

## pkgdown documentation

Every push to `main` deploys the pkgdown site via GitHub Actions (`pkgdown-dev.yaml`). The version in `DESCRIPTION` determines which variant is published:

| Version on `main` | Docs destination | URL |
|-------------------|-----------------|-----|
| `x.y.z` (release) | stable | `https://birdnet-team.github.io/birdnetR/` |
| `x.y.z.9000` (dev) | development | `https://birdnet-team.github.io/birdnetR/dev/` |

This is handled automatically by `_pkgdown.yml` with `development: mode: auto`. No manual configuration is needed — just keep the version in `DESCRIPTION` consistent with the conventions above.

Pull requests into `main` build the site as a check but do not deploy it. Pushes to feature/fix and `release/*` branches do not build it.

Publishing a GitHub release also rebuilds the stable docs from the release tag (`pkgdown-release.yaml`). You can run that workflow by hand, too; its `tag` input takes a tag or a branch name.

This also aligns with `pak::pak("birdnet-team/birdnetR")`, which installs from the default branch (`main`).

## Release workflow

Releases are prepared on a short-lived `release/x.y.z` branch so that CRAN-specific housekeeping does not block ongoing feature work on `main`.

```
main  ──►  release/x.y.z  ──►  main
```

### Checklist

1. **Cut release branch** from `main`:
   ```
   git checkout -b release/0.3.2 main
   ```
2. **Finalize version** — set `Version: 0.3.2` in `DESCRIPTION` (remove `.9000`).
3. **Update `NEWS.md`** — rename `# birdnetR (development version)` to `# birdnetR x.y.z`.
4. **Update `README.md`** for the release, if it describes the development version: remove the development-version note, put `install.packages()` first, and point links to the documentation at the stable site (no `/dev/`).
5. **Check the package**:
   ```r
   devtools::check()
   rcmdcheck::rcmdcheck(args = c("--as-cran"))
   ```
6. **Update `cran-comments.md`** with submission notes.
7. **Deploy the stable docs** if the README links to pages that are new in this release: run the `pkgdown-release` workflow by hand with the release branch as `tag`. CRAN checks every URL in the README, so the pages must exist on the stable site before you submit.
8. **Submit to CRAN**:
   ```r
   devtools::submit_cran()
   ```
9. **After CRAN acceptance**, merge `release/x.y.z` into `main`, tag the release and publish a GitHub release for the tag (this rebuilds the stable docs):
   ```
   git checkout main && git merge --no-ff release/0.3.2
   git tag v0.3.2
   git push --tags
   ```
10. **Bump version on `main`** — set `Version: 0.3.3.9000` in `DESCRIPTION`.
11. **Delete the release branch**:
    ```
    git branch -d release/0.3.2
    ```

## Code style

birdnetR uses [tidyverse style](https://style.tidyverse.org). Run `styler::style_pkg()` before submitting a pull request.

## Getting help

Open an issue on [GitHub](https://github.com/birdnet-team/birdnetR/issues) for bug reports and feature requests.
