# komodo

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2.3.2](https://img.shields.io/badge/AppVersion-2.3.2-informational?style=flat-square)

A Helm chart for Komodo Core - build, deploy and monitor servers, containers and stacks

**Homepage:** <https://komo.do>

Deploys **Komodo Core only**. Komodo Periphery agents are installed on the
machines you want to manage (systemd unit or container) and connect *inbound*
to Core over a bi-directional WebSocket on port 9120.

## Requirements

This chart does **not** deploy a database. Komodo Core needs an external
MongoDB-compatible database (MongoDB, FerretDB, or a Percona
`PerconaServerMongoDB` cluster) reachable over the Mongo wire protocol. Point
the chart at it with `database.address` plus `database.existingSecret`.

## Installing

```bash
helm install komodo oci://ghcr.io/jdogwilly/charts/komodo \
  --version 0.1.0 \
  --namespace komodo --create-namespace \
  -f values.yaml
```

## Flux example

How this chart is consumed from `jdogwilly/cluster-apps`:

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: OCIRepository
metadata:
  name: komodo
  namespace: komodo
spec:
  interval: 1h
  url: oci://ghcr.io/jdogwilly/charts/komodo
  ref:
    tag: 0.1.0
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: komodo
  namespace: komodo
spec:
  interval: 30m
  chartRef:
    kind: OCIRepository
    name: komodo
  values:
    komodo:
      host: https://komodo.example.com
      localAuth: true
      disableUserRegistration: true
      initAdminUsername: admin
      timezone: America/Los_Angeles
      secrets:
        # KOMODO_JWT_SECRET / KOMODO_WEBHOOK_SECRET / KOMODO_INIT_ADMIN_PASSWORD
        existingSecret: komodo-secrets

    # External Percona PSMDB cluster (created separately in cluster-apps)
    database:
      address: komodo-psmdb-rs0.komodo.svc.cluster.local:27017
      existingSecret: komodo-psmdb-credentials
      usernameKey: MONGODB_USER_ADMIN_USER
      passwordKey: MONGODB_USER_ADMIN_PASSWORD

    persistence:
      keys:
        enabled: true
        size: 1Gi
      syncs:
        enabled: true
        size: 1Gi
      backups:
        enabled: true
        size: 10Gi

    ingresses:
      traefik:
        enabled: true
        className: traefik
        hosts:
          - host: komodo.example.com
            paths:
              - path: /
                pathType: Prefix
        tls:
          - secretName: komodo-tls
            hosts:
              - komodo.example.com
      tailscale:
        enabled: true
        className: tailscale
        defaultBackend: true
        tls:
          - hosts:
              - komodo
```

## Ingress

`ingresses` is a map, so several Ingress objects can point at the same
Service. Each enabled entry renders one Ingress named `<fullname>-<key>`.

* Normal controllers (Traefik, nginx, ...): use `hosts[].paths[]`.
* Tailscale operator: set `defaultBackend: true` and put the tailnet hostname
  in `tls[0].hosts[0]`; no rules are rendered and `secretName` is omitted.

Periphery agents hold a long-lived WebSocket to Core. Make sure the ingress
controller allows connection upgrades and uses a generous read/idle timeout,
otherwise agents will reconnect constantly. Traefik and the Tailscale operator
both pass upgrades through by default.

## Persistence

| Value | Container path | Default | Why |
| ----- | -------------- | ------- | --- |
| `persistence.keys` | `/config/keys` | enabled, 1Gi | Core's Noise keypair. **Losing it breaks authentication for every Periphery agent.** |
| `persistence.syncs` | `/syncs` | disabled, 1Gi | ResourceSync files written by Core. |
| `persistence.backups` | `/backups` | disabled, 10Gi | Dated database dumps from the "Backup Core Database" procedure. |

Each entry supports `enabled`, `storageClass`, `size`, `accessMode` and
`existingClaim`. No `storageClass` is set by default, so the cluster default
applies.

## Replicas and update strategy

`replicaCount` defaults to `1` and `strategy.type` defaults to `Recreate`.
Komodo Core is **not HA-safe**: the keys PVC is ReadWriteOnce, and two Cores
sharing one database would double up on polling, alerting and scheduled
procedures. A `RollingUpdate` would also deadlock waiting for the RWO volume
to detach. Leave both at their defaults unless you know what you are doing.

## Configuration file

Most settings are available as `KOMODO_*` environment variables (see
`komodo.*` and `extraEnv`), and environment variables always override the
config file. A few things can only be set in `core.config.toml`:

* the `[secrets]` block
* `[[git_provider]]` entries
* `[[image_registry]]` entries

Put a `core.config.toml` in a Secret and reference it:

```yaml
coreConfig:
  existingSecret: komodo-core-config
  key: config.toml
```

It is mounted read-only at `/config/config.toml`. The Secret name is copied to
the pod annotation `komodo.io/core-config-secret` so it shows up in
`kubectl describe pod`; its contents are **not** checksummed, because the
chart does not own that Secret — restart the Deployment yourself after
changing it.

## Custom CA certificates

The image entrypoint runs `update-ca-certificates`, so certificates mounted
into `/usr/local/share/ca-certificates` are trusted at startup:

```yaml
extraVolumes:
  - name: root-ca
    secret:
      secretName: internal-root-ca
extraVolumeMounts:
  - name: root-ca
    mountPath: /usr/local/share/ca-certificates/root_ca.crt
    subPath: root_ca.crt
    readOnly: true
```

Because of this, the container needs a writable root filesystem and root
privileges by default; `podSecurityContext` / `securityContext` are empty out
of the box.

## Probes

Komodo Core has no dedicated health endpoint, but serves an unauthenticated
`GET /version` on port 9120, which the probes use by default. Set
`livenessProbe.type: tcp` (same for readiness/startup) to fall back to a plain
TCP socket check.

## Secrets

The documented path for `KOMODO_JWT_SECRET`, `KOMODO_WEBHOOK_SECRET` and
`KOMODO_INIT_ADMIN_PASSWORD` is `komodo.secrets.existingSecret`. Keys are
looked up with `optional: true`, so the Secret only has to contain the ones
you use. The plaintext `komodo.secrets.*` / `database.username` /
`database.password` values render a chart-managed Secret and exist for local
testing only. See `examples/existing-secrets.yaml`.

If `KOMODO_JWT_SECRET` is not set, Komodo generates a new one on every start
and all sessions are invalidated on restart.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| jdogwilly | <jacob@brookins.email> |  |

## Source Code

* <https://github.com/moghtech/komodo>
* <https://github.com/jdogwilly/charts>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity rules |
| coreConfig.existingSecret | string | `""` | Name of an existing Secret containing the Komodo Core config file. Leave empty to run with the image default config. |
| coreConfig.key | string | `"config.toml"` | Key inside `coreConfig.existingSecret` holding the config file |
| database.address | string | `"mongodb:27017"` | `KOMODO_DATABASE_ADDRESS`, in `host:port` form (Mongo wire protocol). |
| database.existingSecret | string | `""` | Name of an existing Secret holding the database credentials, e.g. the Secret generated by a Percona `PerconaServerMongoDB` cluster. |
| database.password | string | `""` | Plaintext password (dev only, prefer `existingSecret`) |
| database.passwordKey | string | `"password"` | Key in `database.existingSecret` holding the password |
| database.username | string | `""` | Plaintext username (dev only, prefer `existingSecret`) |
| database.usernameKey | string | `"username"` | Key in `database.existingSecret` holding the username |
| extraEnv | list | `[]` | Additional environment variables for the Komodo Core container |
| extraEnvFrom | list | `[]` | Additional `envFrom` sources (Secrets / ConfigMaps) |
| extraVolumeMounts | list | `[]` | Additional volume mounts. Certificates placed in `/usr/local/share/ca-certificates` are installed by the image entrypoint. |
| extraVolumes | list | `[]` | Additional volumes, e.g. a custom root CA to trust |
| fullnameOverride | string | `""` | Override the fully qualified app name |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.repository | string | `"ghcr.io/moghtech/komodo-core"` | Komodo Core image repository |
| image.tag | string | `""` | Image tag. Defaults to the chart `appVersion` when empty. |
| imagePullSecrets | list | `[]` | Image pull secrets for private registries |
| ingresses | object | `{"tailscale":{"annotations":{},"className":"tailscale","defaultBackend":true,"enabled":false,"tls":[]},"traefik":{"annotations":{},"className":"traefik","enabled":false,"hosts":[{"host":"komodo.example.com","paths":[{"path":"/","pathType":"Prefix"}]}],"tls":[]}}` | Map of named Ingresses, all pointing at the same Service. This lets you expose Komodo on several ingress controllers at once (for example a LAN Traefik ingress plus a Tailscale operator ingress). One Ingress object is rendered per enabled entry, named `<fullname>-<key>`. Each entry supports either normal `hosts`/`paths` rules or the Tailscale operator style `defaultBackend: true` + `tls[].hosts` (no rules). NOTE: Periphery agents connect to Core over a long lived bi-directional WebSocket. Make sure your ingress controller does not buffer responses and uses a generous read/idle timeout, otherwise agents will flap. |
| ingresses.tailscale.annotations | object | `{}` | Ingress annotations |
| ingresses.tailscale.className | string | `"tailscale"` | IngressClass name |
| ingresses.tailscale.defaultBackend | bool | `true` | Tailscale operator style: render a `defaultBackend` instead of host rules. The MagicDNS name comes from `tls[0].hosts[0]`. |
| ingresses.tailscale.enabled | bool | `false` | Enable the Tailscale operator Ingress |
| ingresses.tailscale.tls | list | `[]` | TLS configuration. For the Tailscale operator `secretName` is omitted and `hosts[0]` becomes the tailnet hostname. |
| ingresses.traefik.annotations | object | `{}` | Ingress annotations |
| ingresses.traefik.className | string | `"traefik"` | IngressClass name |
| ingresses.traefik.enabled | bool | `false` | Enable the Traefik (LAN) Ingress |
| ingresses.traefik.hosts | list | `[{"host":"komodo.example.com","paths":[{"path":"/","pathType":"Prefix"}]}]` | Host rules |
| ingresses.traefik.tls | list | `[]` | TLS configuration |
| initContainers | list | `[]` | Extra init containers |
| komodo.disableUserRegistration | bool | `false` | `KOMODO_DISABLE_USER_REGISTRATION`. Block new signups after the first user has been created. |
| komodo.host | string | `""` | `KOMODO_HOST`. Public URL Komodo is reached at, used for OAuth redirects and webhook URL suggestions. Required for a usable install. |
| komodo.initAdminUsername | string | `""` | `KOMODO_INIT_ADMIN_USERNAME`. Creates the first admin user on first startup. Its password comes from `komodo.secrets` (see below). |
| komodo.localAuth | bool | `true` | `KOMODO_LOCAL_AUTH`. Allow username/password login. |
| komodo.monitoringInterval | string | `"15-sec"` | `KOMODO_MONITORING_INTERVAL`. How often servers are polled for stats. Options: 1-sec, 5-sec, 15-sec, 1-min, 5-min, 15-min |
| komodo.resourcePollInterval | string | `"1-hr"` | `KOMODO_RESOURCE_POLL_INTERVAL`. How often resources are polled for updates / automated actions. Options: 5-min, 15-min, 1-hr, 2-hr, 6-hr, 12-hr, 1-day |
| komodo.secrets.existingSecret | string | `""` | Name of an existing Secret holding the Komodo secrets. Referenced keys are looked up with `optional: true`, so the Secret only needs to contain the keys you actually use. |
| komodo.secrets.initAdminPassword | string | `""` | Plaintext `KOMODO_INIT_ADMIN_PASSWORD` (dev only, prefer `existingSecret`) |
| komodo.secrets.initAdminPasswordKey | string | `"KOMODO_INIT_ADMIN_PASSWORD"` | Key in `existingSecret` holding `KOMODO_INIT_ADMIN_PASSWORD` |
| komodo.secrets.jwtSecret | string | `""` | Plaintext `KOMODO_JWT_SECRET` (dev only, prefer `existingSecret`). If unset, Komodo generates a new one on every restart and all sessions are invalidated. |
| komodo.secrets.jwtSecretKey | string | `"KOMODO_JWT_SECRET"` | Key in `existingSecret` holding `KOMODO_JWT_SECRET` |
| komodo.secrets.webhookSecret | string | `""` | Plaintext `KOMODO_WEBHOOK_SECRET` (dev only, prefer `existingSecret`) |
| komodo.secrets.webhookSecretKey | string | `"KOMODO_WEBHOOK_SECRET"` | Key in `existingSecret` holding `KOMODO_WEBHOOK_SECRET` |
| komodo.timezone | string | `"Etc/UTC"` | `TZ`. Timezone used for schedules. |
| komodo.title | string | `"Komodo"` | `KOMODO_TITLE`. Browser tab title. |
| komodo.uiWriteDisabled | bool | `false` | `KOMODO_UI_WRITE_DISABLED`. Make the UI read-only (recommended when all resources are managed through ResourceSyncs). |
| livenessProbe.enabled | bool | `true` | Enable the liveness probe |
| livenessProbe.failureThreshold | int | `3` | Failure threshold |
| livenessProbe.initialDelaySeconds | int | `30` | Initial delay |
| livenessProbe.path | string | `"/version"` | HTTP path used when `type: http` |
| livenessProbe.periodSeconds | int | `10` | Period |
| livenessProbe.successThreshold | int | `1` | Success threshold |
| livenessProbe.timeoutSeconds | int | `5` | Timeout |
| livenessProbe.type | string | `"http"` | Probe type: `http` or `tcp` |
| nameOverride | string | `""` | Override the chart name |
| nodeSelector | object | `{}` | Node selector |
| persistence.backups.accessMode | string | `"ReadWriteOnce"` | Access mode |
| persistence.backups.enabled | bool | `false` | Persist `/backups` (dated database backups produced by the "Backup Core Database" procedure) |
| persistence.backups.existingClaim | string | `""` | Use an existing PVC instead of creating one |
| persistence.backups.size | string | `"10Gi"` | Volume size |
| persistence.backups.storageClass | string | `""` | StorageClass. Empty uses the cluster default. |
| persistence.keys.accessMode | string | `"ReadWriteOnce"` | Access mode |
| persistence.keys.enabled | bool | `true` | Persist `/config/keys` (Core <-> Periphery keypair). Keep enabled. |
| persistence.keys.existingClaim | string | `""` | Use an existing PVC instead of creating one |
| persistence.keys.size | string | `"1Gi"` | Volume size |
| persistence.keys.storageClass | string | `""` | StorageClass. Empty uses the cluster default. |
| persistence.syncs.accessMode | string | `"ReadWriteOnce"` | Access mode |
| persistence.syncs.enabled | bool | `false` | Persist `/syncs` (ResourceSync files written by Core) |
| persistence.syncs.existingClaim | string | `""` | Use an existing PVC instead of creating one |
| persistence.syncs.size | string | `"1Gi"` | Volume size |
| persistence.syncs.storageClass | string | `""` | StorageClass. Empty uses the cluster default. |
| podAnnotations | object | `{}` | Extra annotations for the Komodo Core pod |
| podLabels | object | `{}` | Extra labels for the Komodo Core pod |
| podSecurityContext | object | `{}` | Pod level security context |
| priorityClassName | string | `""` | PriorityClass to schedule the pod with |
| readinessProbe.enabled | bool | `true` | Enable the readiness probe |
| readinessProbe.failureThreshold | int | `3` | Failure threshold |
| readinessProbe.initialDelaySeconds | int | `5` | Initial delay |
| readinessProbe.path | string | `"/version"` | HTTP path used when `type: http` |
| readinessProbe.periodSeconds | int | `10` | Period |
| readinessProbe.successThreshold | int | `1` | Success threshold |
| readinessProbe.timeoutSeconds | int | `5` | Timeout |
| readinessProbe.type | string | `"http"` | Probe type: `http` or `tcp` |
| replicaCount | int | `1` | Number of Komodo Core replicas. Core is NOT HA-safe: the `/config/keys` keypair lives on a single ReadWriteOnce PVC and two Cores sharing one database will double up on polling/alerting. Keep this at 1. |
| resources | object | `{}` | Resource requests and limits |
| securityContext | object | `{}` | Container level security context. Note: the image entrypoint runs `update-ca-certificates`, so `readOnlyRootFilesystem: true` and running as a non-root user require additional work (see README). |
| service.annotations | object | `{}` | Service annotations |
| service.port | int | `9120` | Service port. Komodo Core serves the UI, REST API and the Periphery WebSocket on this single port. |
| service.type | string | `"ClusterIP"` | Service type |
| serviceAccount.annotations | object | `{}` | Annotations to add to the ServiceAccount |
| serviceAccount.create | bool | `true` | Create a ServiceAccount for the Komodo Core pod |
| serviceAccount.name | string | `""` | ServiceAccount name. Generated from the fullname template when empty. |
| startupProbe.enabled | bool | `true` | Enable the startup probe |
| startupProbe.failureThreshold | int | `30` | Failure threshold |
| startupProbe.initialDelaySeconds | int | `0` | Initial delay |
| startupProbe.path | string | `"/version"` | HTTP path used when `type: http` |
| startupProbe.periodSeconds | int | `5` | Period |
| startupProbe.successThreshold | int | `1` | Success threshold |
| startupProbe.timeoutSeconds | int | `3` | Timeout |
| startupProbe.type | string | `"http"` | Probe type: `http` or `tcp` |
| strategy | object | `{"type":"Recreate"}` | Deployment update strategy. Defaults to `Recreate` because the persistent volumes default to ReadWriteOnce, which would deadlock a RollingUpdate. |
| tolerations | list | `[]` | Tolerations |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.13.1](https://github.com/norwoodj/helm-docs/releases/v1.13.1)
