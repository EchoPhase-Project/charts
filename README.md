# EchoPhase charts

Ways to run [EchoPhase](https://github.com/EchoPhase-Project/server) yourself.

## Kubernetes (Helm)

The chart is published as an OCI package:

```sh
helm install echophase oci://ghcr.io/echophase-project/charts/echophase \
  --version 0.4.0 --namespace echophase --create-namespace \
  --set secrets.POSTGRES_PASSWORD=change-me \
  --set secrets.VALKEY_PASSWORD=change-me
```

It runs the server and webapp images from `ghcr.io/echophase-project` at the
chart's `appVersion`, plus Postgres, ScyllaDB and Valkey. Passwords have no
defaults; keep them in a values file of your own (see
`charts/echophase/secrets.example.yaml`) or a secret manager. Other settings:
`charts/echophase/values.yaml` (ingress host and controller, resources,
persistence, rate limits, `echophase.extraEnv` and `webapp.extraEnv` for more settings of the server
and the webapp, such as OpenTelemetry endpoints or error reporting).

To run images from another registry (your own builds), set `imageRegistry`
and the components' `image.repository` / `image.tag`.

## Docker Compose

Without Kubernetes, `compose/` runs the same images on one machine:

```sh
cd compose
cp .env.example .env        # set POSTGRES_PASSWORD and VALKEY_PASSWORD
docker compose up -d        # then http://localhost:8080
```

Only the webapp is published, on 127.0.0.1 (`WEBAPP_BIND`, `WEBAPP_PORT` in
`.env`); it proxies the API to the server. `ECHOPHASE_VERSION` picks the image
tag. For working on the server locally, `compose.dev.yaml` also publishes the
databases on 127.0.0.1:

```sh
docker compose -f compose.yaml -f compose.dev.yaml up -d postgres valkey scylla
```

## Releasing the chart

Bump `version` (and `appVersion` when it should pin newer images) in
`charts/echophase/Chart.yaml`, commit, then tag `vX.Y.Z` with the same version:
GitHub Actions publishes it to `oci://ghcr.io/echophase-project/charts`.

## Verifying the images

Releases (from version 0.2.0) carry build provenance: a signed statement of the
commit and workflow each image and chart was built from, kept next to them in
GHCR. Check one with the GitHub CLI before deploying it:

```bash
gh attestation verify oci://ghcr.io/echophase-project/server:<version> --owner EchoPhase-Project
gh attestation verify oci://ghcr.io/echophase-project/webapp:<version> --owner EchoPhase-Project
gh attestation verify oci://ghcr.io/echophase-project/charts/echophase:<version> --owner EchoPhase-Project
```
