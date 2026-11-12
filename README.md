# .github — meteo-consensus

Organisation-wide defaults:

- `.github/workflows/node-ci.yml`: reusable CI for every TypeScript repo (lint, typecheck, tests with coverage, audit, dependency review, single `CI` gate). Dependency review runs on pull requests of public repos only: on private repos the action needs GitHub Code Security or GitHub Advanced Security ([About dependency review](https://docs.github.com/en/code-security/concepts/supply-chain-security/about-dependency-review), checked 09/11/2026), so they rely on `pnpm audit` in the `check` job.
- `.github/workflows/release.yml`: reusable release-please flow (release PR, tag, `CHANGELOG.md`). Output `release_created`. One release-please run at a time per calling repository; the others wait (concurrency group `release-please-<owner/repo>` with `queue: max`, distinct from the publish group), in an order GitHub does not guarantee.
- `.github/workflows/publish.yml`: reusable publish to GitHub Packages, for package repos only. It installs with `--ignore-scripts` and a `packages: read` token, packs the tarball and reports its sha256. A separate job, the only one holding `packages: write`, installs nothing: it checks the downloaded tarball against that sha256 and its structure (a single `package/` root of regular files and directories), extracts it with GNU tar, fails if an extracted file has more than one hard link (a second barrier after the listing check), checks the extracted `name` and `version` against the `package.json` of the release commit, normalizes the file modes, rebuilds a tarball from the extracted files and publishes only the rebuilt one. Whatever modes `build` produced, the published archive holds only directories and files that had an execute bit (a package `bin`) at `0755` and other files at `0644`: no setuid, setgid or sticky bit, nothing writable by group or others; the job fails if the rebuilt archive holds any other mode. What is published is exactly what GNU tar extracted and checked, so archive tricks that make tar readers disagree (a second root, a lone zero block) cannot reach the registry. One publish runs at a time per repository; the others wait (concurrency group with `queue: max`), in an order GitHub does not guarantee. Dependency code therefore never holds a token that can publish and cannot choose the published name or version, but it can still alter the built code inside the legitimate version: that residual risk needs a reproducible build or provenance to close (follow-up). The tarball is kept 7 days: a failed `publish` job can be re-run alone within that window; after it, re-run the `build` job, which re-runs `publish` with it.

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
- `.github/workflows/release-self.yml`: releases of this repository (see below). It calls `release.yml` by local path, so GitHub runs the called workflow from the same commit as the caller ([Reusing workflows](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows), checked 10/11/2026).
- `.github/ISSUE_TEMPLATE/`: task and epic forms used by the factory agents.
- `.github/pull_request_template.md`, `SECURITY.md`: inherited by every repo.

Actions are pinned by full commit SHA; versions are checked with `/check-versions` in the factory. `.github/dependabot.yml` proposes their updates weekly (`github-actions` ecosystem, 7-day cooldown, same as the factory repo template); the cooldown only delays version updates. Dependabot alerts are on for this repository but Dependabot security updates are off, so a CVE fix is a manual bump through `/check-versions` when the alert fires.

## Releases and pinning

This repository is released with release-please (`release-please-config.json`, `.release-please-manifest.json`): the release PR updates `CHANGELOG.md` and the manifest, and merging it tags `vX.Y.Z` on `main` and publishes a GitHub release. Versions stay in 0.x until the workflows are stable (first release `v0.1.0`); a breaking change (`ci!:`, `feat!:`) bumps the minor version while in 0.x. `feat`, `fix`, `perf`, `revert` and `ci` commits make a release; `docs` and `chore` commits do not (unless marked breaking).

Merging the release PR needs one manual step. release-please opens and updates it with `GITHUB_TOKEN`, which does not trigger `pull_request` workflows, so the required `actionlint` check never reports on it and the `main` ruleset blocks the merge. Just before merging, the owner closes and reopens the release PR: that runs `actionlint` on its current head.

To pin a call on a release, resolve the tag to its commit and write the tag as a comment on the same line:

```sh
gh api repos/meteo-consensus/.github/git/ref/tags/v0.1.0 --jq .object.sha
```

```yaml
    uses: meteo-consensus/.github/.github/workflows/release.yml@<sha40> # v0.1.0
```

release-please creates lightweight tags, so the command above returns the commit SHA directly; if `.object.type` is `tag`, follow it with `gh api repos/meteo-consensus/.github/git/tags/<sha> --jq .object.sha`. Always pin the full 40-character SHA, never the tag name: a tag can be moved, a SHA cannot.

Dependabot (`github-actions` ecosystem) then proposes new releases instead of every commit of `main`: it updates the version comment when it is on the same line as the SHA, and a SHA not associated with any tag is moved to the latest commit instead of the latest release ([Keeping the actions in your workflows secure and up to date](https://docs.github.com/en/actions/reference/security/secure-use#keeping-the-actions-in-your-workflows-secure-and-up-to-date), checked 10/11/2026). It resolves action versions from git tags read as SemVer, and treats a tag with a prerelease suffix (`-rc.1`) as a prerelease ([Dependabot options reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference), checked 10/11/2026). Tags are therefore plain `vX.Y.Z`, without a component prefix (`include-component-in-tag: false`).

## Licence

This repository is licensed under the MIT licence: see [`LICENSE`](LICENSE). It applies to this repository only: GitHub does not use a licence file from `.github` as an organisation default ([Creating a default community health file](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file), checked 09/11/2026), so every other repository keeps its own licence.
