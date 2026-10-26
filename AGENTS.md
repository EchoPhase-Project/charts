# AGENTS.md: EchoPhase charts

This repository contains the Helm chart (`charts/echophase`) and the Docker
Compose files (`compose/`) for EchoPhase. The full rules for persons are in
[CONTRIBUTING.md](CONTRIBUTING.md). This file is the short version for coding
agents. If this file and CONTRIBUTING.md are different, CONTRIBUTING.md and the
files are correct. Then correct this file.

## Commands

Get Helm from mise: run `mise install --locked`. The passwords do not have
default values. Thus, give them to the commands that render the chart:

```sh
helm lint charts/echophase --set secrets.POSTGRES_PASSWORD=x,secrets.VALKEY_PASSWORD=x
helm template echophase charts/echophase --set secrets.POSTGRES_PASSWORD=x,secrets.VALKEY_PASSWORD=x
POSTGRES_PASSWORD=x VALKEY_PASSWORD=x docker compose -f compose/compose.yaml config   # Compose
kubectl kustomize examples/flux   # the Flux example
```

Before you stop, do these steps:

1. Make sure that the two `helm` commands are successful.
2. Read the rendered output of the parts that you changed.

## Rules

### Templates

- Make names, labels, and images with the helpers in `_helpers.tpl`:
  `echophase.fullname`, `echophase.labels`, `echophase.selectorLabels`,
  `echophase.image`. Also add `app.kubernetes.io/component`.
- Get database addresses only from the helpers: `echophase.postgresHost`,
  `echophase.valkeyHost`, `echophase.scyllaContactPoints`, and the port
  helpers. Each database can be part of the release or external.
- Get object storage settings the same way: `echophase.s3`,
  `echophase.s3Endpoint`, `echophase.s3ForcePathStyle`.
- The default image tags for the server and the webapp are `appVersion`. Do
  not write these tags directly in the templates.
- Migrations run in the init container of the server. Do not add Jobs or
  hooks.

### Values

- Passwords are `required` and do not have default values. Do not put a
  password in `values.yaml`. This rule also applies to example passwords.
- For a setting that only some users need, use `echophase.extraEnv` or
  `webapp.extraEnv`. Do not add a new value for it.
- Each value in `values.yaml` must have a comment that tells its purpose.
- If you remove a value or change its name, the values files of users stop
  working. Keep the old name in operation, or mark the commit as incompatible
  (`feat!:`).

### Compose

- Keep Compose the same as the chart.

## Versions

- For each change to the chart, set a new `version` in `Chart.yaml`.
  Published versions do not change.
- Before version 1.0, increase the minor number for features and for
  incompatible value changes. Increase the patch number for fixes.
- `appVersion` is the EchoPhase release that the chart runs. When you change
  `appVersion`, change these items to the same version:
  - `ECHOPHASE_VERSION` in `compose/compose.yaml` (three locations).
  - `ECHOPHASE_VERSION` in `compose/.env.example`.
  - `--version` in the install command in the README.
- When you change `version`, change the `tag` in `examples/flux/chart.yaml`.
- Do not make release tags. The maintainers make the tag `vX.Y.Z`. This tag
  is the same as `version`.

## Commits

Use Conventional Commits. CI examines the commit messages.

- Use these types: `feat:`, `fix:`, `docs:`, `ci:`, `build:`, `chore:`.
- Use `feat!:` for changes that make current values files incompatible.
