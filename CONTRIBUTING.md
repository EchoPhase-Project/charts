# Contributing to EchoPhase charts

Thank you for helping with the ways to run EchoPhase: the Helm chart in
`charts/echophase` and Docker Compose in `compose/`. What is common to every
repository (issues, licence, security reports) is in the
[organisation's guide](https://github.com/EchoPhase-Project/.github/blob/main/CONTRIBUTING.md).

## Setting up

Helm is pinned with [mise](https://mise.jdx.dev): `mise install --locked`.

Check every change the way CI does (the passwords have no defaults, so the
chart does not render without them):

```sh
helm lint charts/echophase --set secrets.POSTGRES_PASSWORD=x,secrets.VALKEY_PASSWORD=x
helm template echophase charts/echophase --set secrets.POSTGRES_PASSWORD=x,secrets.VALKEY_PASSWORD=x
```

Read the rendered output of what you changed, not only whether it renders.
For a real test, install into a local cluster (k3d, kind, k3s) with your own
values file; for Compose, `docker compose config` in `compose/` shows the
resolved file, and `docker compose up -d` runs it.

## The chart

| Template | What |
|---|---|
| `templates/_helpers.tpl` | names, labels, image references and pull policies |
| `templates/configmap.yaml`, `secret.yaml` | settings of the server; credentials |
| `templates/echophase/` | the server (Deployment, Service, volume) |
| `templates/webapp/` | the web client (Deployment, Service, Ingress, rate limits) |
| `templates/postgres/`, `scylla/`, `valkey/` | the databases (StatefulSets), each behind `<component>.enabled` |

Conventions:

- **Names and labels** come from the helpers: `echophase.fullname` with a
  component suffix (`-webapp`, `-postgres`), `echophase.labels` plus
  `app.kubernetes.io/component`; selectors use `echophase.selectorLabels`
  with the component.
- **Images** of server and webapp go through `echophase.image`:
  `imageRegistry/repository:tag`, the tag falling back to the chart's
  `appVersion`. Third-party images are plain `repository:tag` values.
- **Settings** of the server are rendered into the ConfigMap, credentials into
  the Secret. Settings the chart does not model go through
  `echophase.extraEnv` (server) and `webapp.extraEnv` (webapp); both pass
  through `tpl`. Prefer them over a new value for a single variable.
- **Secrets have no defaults.** A password is `required`, with a message that
  says where to set it. Never put a real or example password in
  `values.yaml`.
- **Migrations** run in an init container of the server (`migrate`), not in a
  Job or a Helm hook: the server's EF migrations take a lock, so several pods
  starting together are safe.
- **Restarts on change**: the server's pods carry checksums of the ConfigMap
  and the Secret; a template that feeds them a new source adds it there.
- **Ingress** supports `nginx` and `traefik` (`webapp.ingress.controller`);
  anything else fails on purpose. A new controller needs its rate-limit
  translation.
- **Comments**: every value in `values.yaml` says what it is for, in full
  sentences. Keep the file readable as the chart's documentation.
- **Compatibility**: renaming or removing a value breaks the users' values
  files. Keep the old name working where you can, and mark the commit as
  breaking (`feat!:`) where you cannot.

## Docker Compose

`compose/compose.yaml` runs the same images and databases as the chart; settings
come from `.env` (`.env.example` lists them). `compose.dev.yaml` publishes the
databases on `127.0.0.1` to run a server from source. Keep Compose and the
chart in step: a setting added to one usually belongs in the other.

## Versions

The chart has two versions (`charts/echophase/Chart.yaml`):

- `version`: the chart itself. Any change to the chart needs a new one, since
  a published version never changes. Before 1.0: a new minor for features and
  for breaking changes to values, a patch for fixes.
- `appVersion`: the EchoPhase release (server and webapp images) the chart
  runs by default. Raise it when a new EchoPhase release is out.

When `appVersion` changes, change with it the default image tag in
`compose/compose.yaml` (`ECHOPHASE_VERSION`, three places) and
`compose/.env.example`, and the `--version` of the install command in the
README. When `version` changes, the Flux example's `examples/flux/chart.yaml`
pins it too.

Releases are made by the maintainers: a commit that sets the new `version`,
then a tag `vX.Y.Z` equal to it (CI refuses a tag that differs). The tag
publishes `oci://ghcr.io/echophase-project/charts/echophase` with build
provenance and a GitHub release whose notes come from the commits.

## Commits and pull requests

Commit messages follow Conventional Commits, checked in CI; the release notes
are made from them. Use `feat:` for something users can now do, `fix:` for a
template that rendered wrong, and `feat!:` (or a `BREAKING CHANGE:` footer
saying how to update values) for a change that breaks existing values files.

In the pull request, say how you tested it: `helm template` output, an install
on a cluster, or Compose.
