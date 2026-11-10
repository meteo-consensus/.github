# .github — meteo-consensus

Organisation-wide defaults:

- `.github/workflows/node-ci.yml`: reusable CI for every TypeScript repo (lint, typecheck, tests with coverage, audit, dependency review, single `CI` gate). Dependency review runs on pull requests of public repos only: on private repos the action needs GitHub Code Security or GitHub Advanced Security ([About dependency review](https://docs.github.com/en/code-security/concepts/supply-chain-security/about-dependency-review), checked 09/11/2026), so they rely on `pnpm audit` in the `check` job.
- `.github/workflows/release.yml`: reusable release-please flow (release PR, tag, `CHANGELOG.md`). Output `release_created`.
- `.github/workflows/publish.yml`: reusable publish to GitHub Packages, for package repos only. It installs with `--ignore-scripts` and a `packages: read` token, packs the tarball, then publishes it from a separate job that installs nothing, after checking that the tarball's `name` and `version` match the `package.json` of the release commit; only that job holds `packages: write`. Dependency code therefore never holds a token that can publish and cannot choose the published name or version, but it can still alter the built code inside the legitimate version: that residual risk needs a reproducible build or provenance to close. The tarball is kept 7 days: a failed `publish` job can be re-run alone within that window; after it, re-run the `build` job, which re-runs `publish` with it.

Publishing is a separate workflow because GitHub refuses to start a called workflow when one of its jobs requests a permission the caller does not grant, even a job whose `if` would skip it (trial on real runners, 10/11/2026, meteo-consensus/.github#11). Callers pin both workflows by full commit SHA:

```yaml
jobs:
  release:
    uses: meteo-consensus/.github/.github/workflows/release.yml@<sha40> # <version>
    permissions:
      contents: write
      pull-requests: write
  # Package repos only (contracts, db):
  publish:
    needs: release
    if: needs.release.outputs.release_created == 'true'
    uses: meteo-consensus/.github/.github/workflows/publish.yml@<sha40> # <version>
    permissions:
      contents: read
      packages: write
```
- `.github/ISSUE_TEMPLATE/`: task and epic forms used by the factory agents.
- `.github/pull_request_template.md`, `SECURITY.md`: inherited by every repo.

Actions are pinned by full commit SHA; versions are checked with `/check-versions` in the factory.

## Licence

This repository is licensed under the MIT licence: see [`LICENSE`](LICENSE). It applies to this repository only: GitHub does not use a licence file from `.github` as an organisation default ([Creating a default community health file](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file), checked 09/11/2026), so every other repository keeps its own licence.
