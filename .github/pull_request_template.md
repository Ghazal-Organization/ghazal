<!--
Thank you for your contribution to Ghazal.
Keep the PR small and focused. One concern per PR.
-->

## Summary

<!-- One or two sentences: what does this PR do and why? -->

## Linked issues

Closes #
Relates to #

## Type of change

<!-- Tick all that apply -->

- [ ] Feature
- [ ] Bug fix
- [ ] Refactor (no behaviour change)
- [ ] Docs / ADR
- [ ] CI / build / tooling
- [ ] Chore

## Changes

<!-- Bullet list of the concrete changes a reviewer should look for. -->

-
-

## Architecture / ADR impact

<!-- If this PR touches a design decision, link the ADR or add a new one under docs/ADR. -->

- [ ] No ADR change
- [ ] Updates ADR: `docs/ADR/...`
- [ ] New ADR added: `docs/ADR/...`

## Backwards compatibility

<!-- Does this change a public API, route signature, DB schema, or webhook payload? -->

- [ ] No breaking change
- [ ] Breaking change — migration steps documented below

<details>
<summary>Migration / rollout notes</summary>

<!-- How is this applied safely? Feature flag? DB migration? Client coordination? -->

</details>

## Validation

<!-- How did you verify this works? -->

- [ ] `dotnet test Ghazal.slnx` is green locally
- [ ] `pnpm -r build` is green locally
- [ ] Manual smoke test described below
- [ ] N/A — docs-only change

<details>
<summary>Manual test steps</summary>

1.
2.

</details>

## Security checklist

- [ ] No secrets, tokens, or credentials in code, tests, or commit history
- [ ] User input validated at the boundary
- [ ] No new public endpoint without auth + rate-limit consideration
- [ ] Logs do not leak PII or payment data

## Screenshots / recordings

<!-- For UI changes. Drag images here or remove this section. -->

## Reviewer notes

<!-- Anything that would help a reviewer: trade-offs you considered, follow-ups you plan. -->
