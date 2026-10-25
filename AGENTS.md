# AGENTS.md: EchoPhase charts

Helm chart (`charts/echophase`) and Docker Compose (`compose/`) to run
EchoPhase. Humans read [CONTRIBUTING.md](CONTRIBUTING.md); this file is the
short version for coding agents. When the two disagree, CONTRIBUTING.md and
the files win: fix this file.

## Commands

Helm comes from mise (`mise install --locked`). The passwords have no
defaults, so pass them to render:

```sh
helm lint charts/echophase --set secrets.POSTGRES_PASSWORD=x,secrets.VALKEY_PASSWORD=x
helm template echophase charts/echophase --set secrets.POSTGRES_PASSWORD=x,secrets.VALKEY_PASSWORD=x
POSTGRES_PASSWORD=x VALKEY_PASSWORD=x docker compose -f compose/compose.yaml config   # Compose
kubectl kustomize examples/flux   # the Flux example
```

Before you finish: both helm commands succeed, and you have read the rendered
output of what you changed.

## Rules

- Names, labels and images through the helpers in `_helpers.tpl`
  (`echophase.fullname`, `echophase.labels`, `echophase.selectorLabels`,
  `echophase.image`), plus `app.kubernetes.io/component`.
- Database addresses only through the helpers (`echophase.postgresHost`,
  `echophase.valkeyHost`, `echophase.scyllaContactPoints`, the port helpers):
  each database may be the release's own or external.
- Server and webapp image tags default to `appVersion`; do not hard-code them.
- Passwords are `required` and have no defaults. Never put a password, real or
  example, in `values.yaml`.
- One-off settings go through `echophase.extraEnv` / `webapp.extraEnv`
  rather than new values.
- Migrations run in the server's init container; do not add Jobs or hooks.
- Every value in `values.yaml` has a comment saying what it is for.
- Renaming or removing a value breaks users' values files: keep the old name
  working, or mark the commit breaking (`feat!:`).
- Keep Compose in step with the chart.

## Versions

- Any change to the chart needs a new `version` in `Chart.yaml` (published
  versions never change). Before 1.0: minor for features and breaking value
  changes, patch for fixes.
- `appVersion` is the EchoPhase release the chart runs. When it changes,
  change with it `ECHOPHASE_VERSION` in `compose/compose.yaml` (three places)
  and `compose/.env.example`, and `--version` in the README's install command.
- When `version` changes, update the `tag` in `examples/flux/chart.yaml`.
- Do not create release tags: maintainers tag `vX.Y.Z` equal to `version`.

## Commits

Conventional Commits, checked in CI: `feat:`, `fix:`, `docs:`, `ci:`,
`build:`, `chore:`; `feat!:` for changes that break existing values.
