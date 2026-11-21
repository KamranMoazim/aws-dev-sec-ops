# Git Governance

## Branching strategy

| Branch | Purpose | Created from | Merges into | Deploys to |
|---|---|---|---|---|
| `main` | Released code, always deployable | - | - | prod (after approval) |
| `develop` | Integration branch | `main` | `release/*` | dev (auto on merge) |
| `feature/*` | New work, e.g. `feature/items-endpoint` | `develop` | `develop` | - |
| `release/*` | Release candidate, e.g. `release/1.2.0` | `develop` | `main`, back into `develop` | staging, then prod |
| `hotfix/*` | Urgent prod fix, e.g. `hotfix/1.2.1` | `main` | `main`, back into `develop` | staging, then prod |

Flow: `feature/*` -> PR -> `develop` -> `release/x.y.z` -> PR -> `main` -> tag `vx.y.z`.

## Code review policy

- Every change to `main` and `develop` goes through a pull request.
- 2 approvals required, including a Code Owner (`.github/CODEOWNERS`).
- Required status checks: build, unit tests, security scans (SAST, SCA, secrets), Terraform plan.
- Stale approvals are dismissed when new commits are pushed.
- All conversations must be resolved before merge.
- Signed commits required; no force-push; no branch deletion.

## Branch protection settings

Apply to `main` and `develop` in GitHub: Settings -> Rules -> Rulesets -> New branch ruleset.

| Setting | main | develop |
|---|---|---|
| Restrict deletions | on | on |
| Block force pushes | on | on |
| Require signed commits | on | on |
| Require a pull request before merging | on | on |
| Required approvals | 2 | 2 |
| Dismiss stale approvals on new commits | on | on |
| Require review from Code Owners | on | on |
| Require conversation resolution | on | on |
| Require status checks to pass | on | on |
| Require linear history | on | off |

Required status check names are added once the pipeline exists (Step 5 and Step 6).

Rulesets on private repos need GitHub Pro (personal account) or Team (organization); they are free on public repos.

## Solo mode

GitHub never counts a PR author's own approval, so with a single maintainer the table above would block every
merge. Until a second reviewer joins, use one of these:

| Option | Changes to the table above | Trade-off |
|---|---|---|
| A. Relaxed (default) | Required approvals 0, Code Owners review off | PR + status checks + signed commits still enforced |
| B. Strict + bypass | Keep all settings, add yourself as a bypass actor in the ruleset | Shows the full team setup; bypass is logged in the audit log |

Current `.github/CODEOWNERS` assigns everything to one user. When moving to a team:

1. Create a GitHub organization (free) and transfer the repo; history is kept.
2. Create teams, e.g. `platform-team`, `app-team`, `security-team`.
3. Replace CODEOWNERS with per-path rules:

```
*                   @ORG/platform-team
/app/               @ORG/app-team
/infra/             @ORG/platform-team
/buildspecs/        @ORG/platform-team @ORG/security-team
/scripts/           @ORG/platform-team @ORG/security-team
/.github/           @ORG/platform-team @ORG/security-team
```

4. Restore 2 approvals and Code Owners review in the ruleset, and remove any bypass actors.

## Signed commits

Set up once per developer (SSH signing shown; GPG also works):

```sh
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true
git config --global tag.gpgsign true
```

Then add the same public key in GitHub as a "Signing key" (Settings -> SSH and GPG keys).

## Release tags

Semantic versioning `vMAJOR.MINOR.PATCH`, created as signed tags on `main` after a release or hotfix merge:

```sh
git tag -s v1.2.0 -m "Release 1.2.0"
git push origin v1.2.0
```

The tag and its change notes are what the prod approver reviews.

## Commit messages

Format: `<type>: <subject>` with types `feat`, `fix`, `refactor`, `chore`, `docs`, `style`, `test`.
Subject max 50 characters, imperative, capitalized, no trailing period. Optional Jira prefix,
e.g. `feat: JIRA-123 - Add items endpoint`.
