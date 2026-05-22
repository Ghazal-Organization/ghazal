# Infrastructure as Code

Bicep templates that mirror the resources already running in Azure for the
Ghazal MVP. The source of truth for **shape** is here; the source of truth for
**deployed state** is Azure itself.

## Layout

```
infra/
  main.bicep                  # top-level: env-agnostic composition
  main.<env>.bicepparam       # per-environment parameters (no secrets)
  modules/                    # one resource (or tightly coupled set) per file
README.md
```

## Conventions

- Resource names follow `<type>-ghazal-<workload>-<env>` (e.g. `func-ghazal-api-prod`).
- Secrets are **never** in `*.bicepparam`. They come from Key Vault references or
  GitHub Actions secrets injected at deploy time.
- Every resource carries `tags: { project: 'ghazal', env: <env>, owner: <team> }`.

## Apply

> Drift is expected on the first run because resources were created manually.
> Always run with `--what-if` first and inspect the diff.

```pwsh
az deployment group what-if `
  --resource-group <rg> `
  --template-file infra/main.bicep `
  --parameters infra/main.prod.bicepparam
```
