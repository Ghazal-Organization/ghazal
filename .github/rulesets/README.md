# Branch protection rulesets

GitHub branch protection lives on the server, not in the repo, so this folder
holds the **source of truth** as JSON. Apply changes through the GitHub UI or
the `gh` CLI; review them in PRs first.

## Apply `main-branch-protection.json`

Requires `gh` authenticated with admin rights on the repo.

```pwsh
gh api `
  --method POST `
  -H "Accept: application/vnd.github+json" `
  /repos/Ghazal-Organization/ghazal/rulesets `
  --input .github/rulesets/main-branch-protection.json
```

## Update an existing ruleset

```pwsh
# List existing rulesets to find the id
gh api /repos/Ghazal-Organization/ghazal/rulesets

# Replace <id> with the ruleset id from above
gh api `
  --method PUT `
  -H "Accept: application/vnd.github+json" `
  /repos/Ghazal-Organization/ghazal/rulesets/<id> `
  --input .github/rulesets/main-branch-protection.json
```

## What the `main` ruleset enforces

- `main` cannot be deleted or force-pushed
- PR required with **1 approving review**
- Stale reviews dismissed on new pushes
- **Code owner review required** (see `.github/CODEOWNERS`)
- Last push must be re-approved
- All conversation threads must be resolved
- Status checks must pass and branch must be **up to date** before merge:
  - `Frontend build`
  - `Backend build & test`
- Linear history (no merge commits)
- Squash and rebase merges only

## When the CI job names change

Update the `required_status_checks.required_status_checks[].context` values to
match the new job `name:` in `.github/workflows/ci.yml`, commit the JSON, then
re-apply with the `PUT` command above.
