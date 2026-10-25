# EchoPhase charts

Ways to run [EchoPhase](https://github.com/EchoPhase-Project/server) yourself.

## Kubernetes (Helm)

The chart is published as an OCI package:

```sh
helm install echophase oci://ghcr.io/echophase-project/charts/echophase \
  --version 0.5.0 --namespace echophase --create-namespace \
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

## External databases

The release runs PostgreSQL, ScyllaDB and Valkey itself by default. To use
your own (a managed PostgreSQL, a shared Redis, an existing Scylla or
Cassandra cluster), turn the database off and say where yours is:

```yaml
postgres:
  enabled: false
  external:
    host: postgres.example.internal
    port: 5432
    sslMode: VerifyFull         # or Require, Prefer (default), Disable...
    caCertificate:              # the CA VerifyFull checks the database against;
      secretName: postgres-ca   # leave secretName empty for a publicly signed one
      key: ca.crt
valkey:
  enabled: false
  external:
    host: redis.example.internal
    port: 6379
    ssl: true
scylla:
  enabled: false
  autoCreateKeyspace: false   # create the keyspace yourself, with your replication
  external:
    contactPoints: scylla-1.example.internal,scylla-2.example.internal
    port: 9042
    localDatacenter: dc1
secrets:
  POSTGRES_USER: echophase
  POSTGRES_DB: echophase       # must exist; the server creates its tables
  POSTGRES_PASSWORD: change-me
  VALKEY_PASSWORD: change-me
  SCYLLA_USERNAME: echophase   # empty: no authentication
  SCYLLA_PASSWORD: change-me
```

Each can be chosen on its own. The server waits for each database before it
starts and applies its migrations to them. The CA certificate's Secret is
yours, in the release's namespace (for example
`kubectl create secret generic postgres-ca --from-file=ca.crt=<bundle>`).
TLS to an external ScyllaDB is not supported yet.

## Object storage (S3)

For files, the server can use object storage, off by default. Either the
release runs [SeaweedFS](https://github.com/seaweedfs/seaweedfs) and creates
the bucket:

```yaml
s3:
  enabled: true
  bucket: echophase
secrets:
  S3_ACCESS_KEY_ID: change-me
  S3_SECRET_ACCESS_KEY: change-me
```

or the server uses an S3 of yours (AWS S3, Cloudflare R2, Garage, Ceph RGW...),
whose bucket you create beforehand:

```yaml
s3:
  bucket: echophase
  region: eu-central-1
  external:
    endpoint: https://s3.eu-central-1.amazonaws.com
    forcePathStyle: false      # true for most self-hosted S3 servers
secrets:
  S3_ACCESS_KEY_ID: …
  S3_SECRET_ACCESS_KEY: …
```

With Docker Compose: the `s3` profile runs SeaweedFS (see `compose/.env.example`).

## GitOps (Flux)

To keep the release in a Git repository of your own and let
[Flux](https://fluxcd.io) apply it, start from
[`examples/flux`](examples/flux): the chart pinned as an `OCIRepository`, a
`HelmRelease` with its values, the passwords encrypted with SOPS, and the
steps. It runs the same chart and images as `helm install`.

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
