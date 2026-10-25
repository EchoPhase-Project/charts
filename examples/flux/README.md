# EchoPhase with Flux

A starting point to run EchoPhase on your own cluster the GitOps way: your
repository describes the release, and [Flux](https://fluxcd.io) keeps the
cluster in step with it. You do not need a copy of the project's own
[deploy](https://github.com/EchoPhase-Project/deploy) repository: that one is
tied to the project's cluster (its registry, keys and tools).

| File | What |
|---|---|
| `namespace.yaml` | the `echophase` namespace |
| `chart.yaml` | the published chart, pinned to a version (`OCIRepository`) |
| `helmrelease.yaml` | the release and its values (`HelmRelease`) |
| `secret-values.example.yaml` | the passwords' shape; encrypt your copy before committing |
| `kustomization.yaml` | what Flux applies from this folder |
| `flux-kustomization.yaml` | the Flux object that points at this folder, with SOPS decryption |

## Before you start

- A cluster with Flux installed and bootstrapped from your repository
  (`flux bootstrap github …`, see the Flux docs).
- An ingress controller: ingress-nginx, or Traefik (the k3s default).
- [SOPS](https://getsops.io) and [age](https://age-encryption.org) to encrypt
  the passwords, or another way to create the Secret (below).

## Steps

1. Copy this folder into your repository, for example as `apps/echophase/`.

2. In `helmrelease.yaml`, set `webapp.ingress.host` to your domain and
   `controller` to your ingress controller. Look through the chart's
   [values](../../charts/echophase/values.yaml) for anything else.

3. Create the passwords. With SOPS and age:

   ```sh
   age-keygen -o age.agekey                     # keep it safe, out of Git
   cp secret-values.example.yaml secret-values.enc.yaml
   # set the passwords in secret-values.enc.yaml, then encrypt it in place:
   sops --encrypt --age <public key from age.agekey> \
     --encrypted-regex '^(data|stringData)$' --in-place secret-values.enc.yaml
   ```

   Then uncomment `secret-values.enc.yaml` in `kustomization.yaml`, and give
   Flux the private key:

   ```sh
   kubectl -n flux-system create secret generic sops-age \
     --from-file=age.agekey=age.agekey
   ```

   Not using SOPS? Create the Secret `echophase-secret-values` yourself (Sealed
   Secrets, External Secrets, or `kubectl create secret` from the example) and
   leave it out of `kustomization.yaml`.

4. Copy `flux-kustomization.yaml` into your cluster directory (for example
   `clusters/<cluster>/echophase.yaml`) and set its `path` to where you put
   this folder. Drop the `decryption` block if you do not use SOPS.

5. Commit and push. Flux installs the release within minutes:

   ```sh
   flux get kustomizations
   flux get helmreleases -n echophase
   ```

## Upgrading

Change the `tag` in `chart.yaml` to a newer chart version and push. Each
[release](https://github.com/EchoPhase-Project/charts/releases) says which
EchoPhase version it runs and what changed.

## Notes

- Postgres keeps the password its volume was first created with: to change it
  later, change it in the database too (`ALTER USER`), then in the Secret.
- The databases (PostgreSQL, ScyllaDB, Valkey) run inside the release, with
  their data on persistent volumes. To use external ones, see "External
  databases" in the [charts README](../../README.md#external-databases).
