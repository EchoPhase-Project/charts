# Contributing to EchoPhase charts

Thank you for your help with the methods to run EchoPhase: the Helm chart in
`charts/echophase` and Docker Compose in `compose/`. The rules for all
repositories (issues, licence, security reports) are in the
[guide of the organisation](https://github.com/EchoPhase-Project/.github/blob/main/CONTRIBUTING.md).

## Preparation

The project pins Helm with [mise](https://mise.jdx.dev). Run
`mise install --locked`.

Examine each change the same way as CI. The passwords do not have default
values. Thus, the chart does not render if you do not give them:

```sh
helm lint charts/echophase --set secrets.POSTGRES_PASSWORD=x,secrets.VALKEY_PASSWORD=x
helm template echophase charts/echophase --set secrets.POSTGRES_PASSWORD=x,secrets.VALKEY_PASSWORD=x
```

Read the rendered output of the parts that you changed. It is not sufficient
that the chart renders.

For a full test, install the chart into a local cluster (k3d, kind, k3s) with
your own values file. For Compose, run `docker compose config` in `compose/`
to see the resolved file. Run `docker compose up -d` to start it.

## The chart

| Template | Contents |
|---|---|
| `templates/_helpers.tpl` | Names, labels, image references, and pull policies |
| `templates/configmap.yaml`, `secret.yaml` | Settings of the server; credentials |
| `templates/echophase/` | The server (Deployment, Service, volume) |
| `templates/webapp/` | The web client (Deployment, Service, Ingress, rate limits) |
| `templates/postgres/`, `scylla/`, `valkey/` | The databases (StatefulSets). Each database has the switch `<component>.enabled`. |

### Conventions

- **Names and labels.** Get them from the helpers. Use `echophase.fullname`
  with a component suffix (`-webapp`, `-postgres`). Use `echophase.labels`
  and add `app.kubernetes.io/component`. For selectors, use
  `echophase.selectorLabels` with the component.
- **Images.** The server and webapp images go through `echophase.image`:
  `imageRegistry/repository:tag`. If the tag is empty, the helper uses the
  `appVersion` of the chart. Third-party images are plain `repository:tag`
  values.
- **Databases.** Each database is part of the release or external
  (`<db>.enabled`, `<db>.external`). Get the addresses from
  `echophase.postgresHost`, `echophase.valkeyHost`,
  `echophase.scyllaContactPoints`, and the port helpers. Do not write
  `<release>-postgres` directly.
- **Object storage.** Object storage uses the same pattern (`s3.enabled`,
  `s3.external`). `echophase.s3`, `echophase.s3Endpoint`, and
  `echophase.s3ForcePathStyle` set what the server gets.
- **Settings.** The chart renders server settings into the ConfigMap and
  credentials into the Secret. For settings that the chart does not model,
  use `echophase.extraEnv` (server) and `webapp.extraEnv` (webapp). The two
  values go through `tpl`. For a single variable, use them instead of a new
  value.
- **Secrets have no default values.** Each password is `required`, with a
  message that tells where to set it. Do not put a password in
  `values.yaml`. This rule also applies to example passwords.
- **Migrations.** Migrations run in an init container of the server
  (`migrate`). Do not use a Job or a Helm hook for them. The EF migrations of
  the server use a lock. Thus, it is safe when many pods start at the same
  time.
- **Restarts after a change.** The server pods have checksums of the
  ConfigMap and the Secret. If a template gives a new source to the server,
  add the checksum of that source there.
- **Ingress.** The chart supports `nginx` and `traefik`
  (`webapp.ingress.controller`). Other values cause an error intentionally.
  A new controller must have its translation of the rate limits.
- **Comments.** Each value in `values.yaml` has a comment that tells its
  purpose, in full sentences. Keep the file readable as the documentation of
  the chart.
- **Compatibility.** If you remove a value or change its name, the values
  files of users stop working. If possible, keep the old name in operation.
  If this is not possible, mark the commit as incompatible (`feat!:`).

## Docker Compose

`compose/compose.yaml` runs the same images and databases as the chart. The
settings come from `.env`. `.env.example` lists them. `compose.dev.yaml`
publishes the databases on `127.0.0.1`, so that you can run a server from the
source code.

Keep Compose and the chart the same. A setting that you add to one of them
usually also belongs in the other.

## Versions

The chart has two versions in `charts/echophase/Chart.yaml`:

- `version` is the version of the chart. Each change to the chart must have a
  new `version`, because a published version does not change. Before 1.0,
  increase the minor number for features and for incompatible changes to
  values. Increase the patch number for fixes.
- `appVersion` is the EchoPhase release (server and webapp images) that the
  chart runs by default. Increase it when a new EchoPhase release is
  available.

When you change `appVersion`, change these items to the same version:

- The default image tag in `compose/compose.yaml` (`ECHOPHASE_VERSION`, three
  locations).
- `ECHOPHASE_VERSION` in `compose/.env.example`.
- `--version` in the install command in the README.

When you change `version`, also change the pin in `examples/flux/chart.yaml`.

The maintainers make the releases. First, a commit sets the new `version`.
Then, a maintainer makes a tag `vX.Y.Z` that is the same as `version`. CI
refuses a tag that is different. The tag publishes
`oci://ghcr.io/echophase-project/charts/echophase` with build provenance. It
also makes a GitHub release with notes from the commits.

## Commits and pull requests

Commit messages follow Conventional Commits. CI examines them. The release
notes come from the commit messages.

- Use `feat:` for a new thing that users can do.
- Use `fix:` for a template that rendered incorrectly.
- Use `feat!:` for a change that makes current values files incompatible.
  Alternatively, add a `BREAKING CHANGE:` footer that tells how to update the
  values.

In the pull request, tell how you tested the change: `helm template` output,
an installation on a cluster, or Compose.
