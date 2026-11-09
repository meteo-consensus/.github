# .github — meteo-consensus

Organisation-wide defaults:

- `.github/workflows/node-ci.yml`: reusable CI for every TypeScript repo (lint, typecheck, tests with coverage, audit, dependency review, single `CI` gate). Dependency review runs on pull requests of public repos only: on private repos the action needs GitHub Code Security or GitHub Advanced Security ([About dependency review](https://docs.github.com/en/code-security/concepts/supply-chain-security/about-dependency-review), checked 09/11/2026), so they rely on `pnpm audit` in the `check` job.
- `.github/workflows/release.yml`: reusable release-please flow, optional publish to GitHub Packages.
- `.github/ISSUE_TEMPLATE/`: task and epic forms used by the factory agents.
- `.github/pull_request_template.md`, `SECURITY.md`: inherited by every repo.

Actions are pinned by full commit SHA; versions are checked with `/check-versions` in the factory.
