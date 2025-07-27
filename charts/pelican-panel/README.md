# pelican-panel

![Version: 0.5.1](https://img.shields.io/badge/Version-0.5.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: latest](https://img.shields.io/badge/AppVersion-latest-informational?style=flat-square)

A Helm chart for Pelican Panel - Game server management panel

**Homepage:** <https://pelican.dev>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Your Name | <your-email@example.com> |  |

## Source Code

* <https://github.com/pelican-dev/panel>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| autoscaling.enabled | bool | `false` |  |
| autoscaling.maxReplicas | int | `10` |  |
| autoscaling.minReplicas | int | `1` |  |
| autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| autoscaling.targetMemoryUtilizationPercentage | int | `80` |  |
| extraEnvFrom | list | `[]` |  |
| extraEnvVars | list | `[]` |  |
| extraVolumeMounts | list | `[]` |  |
| extraVolumes | list | `[]` |  |
| fullnameOverride | string | `""` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.repository | string | `"ghcr.io/pelican-dev/panel"` |  |
| image.tag | string | `"latest"` |  |
| imagePullSecrets | list | `[]` |  |
| ingress.annotations | object | `{}` |  |
| ingress.className | string | `""` |  |
| ingress.enabled | bool | `false` |  |
| ingress.hosts[0].host | string | `"pelican.local"` |  |
| ingress.hosts[0].paths[0].path | string | `"/"` |  |
| ingress.hosts[0].paths[0].pathType | string | `"Prefix"` |  |
| ingress.tls | list | `[]` |  |
| initContainers | list | `[]` |  |
| livenessProbe.enabled | bool | `true` |  |
| livenessProbe.failureThreshold | int | `3` |  |
| livenessProbe.initialDelaySeconds | int | `30` |  |
| livenessProbe.periodSeconds | int | `10` |  |
| livenessProbe.successThreshold | int | `1` |  |
| livenessProbe.timeoutSeconds | int | `5` |  |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| pelican.adminEmail | string | `"admin@example.com"` |  |
| pelican.adminPassword | string | `""` |  |
| pelican.adminUsername | string | `"admin"` |  |
| pelican.appDebug | bool | `false` |  |
| pelican.appEnvironment | string | `"production"` |  |
| pelican.appKey | string | `""` |  |
| pelican.appLocale | string | `"en"` |  |
| pelican.appTimezone | string | `"UTC"` |  |
| pelican.appUrl | string | `"https://pelican.local"` |  |
| pelican.cacheDriver | string | `"file"` |  |
| pelican.filesystemDisk | string | `"local"` |  |
| pelican.hashBcryptRounds | int | `10` |  |
| pelican.hashDriver | string | `"bcrypt"` |  |
| pelican.mailDriver | string | `"log"` |  |
| pelican.mailEncryption | string | `"tls"` |  |
| pelican.mailFromAddress | string | `"noreply@pelican.local"` |  |
| pelican.mailFromName | string | `"Pelican Panel"` |  |
| pelican.mailHost | string | `""` |  |
| pelican.mailPassword | string | `""` |  |
| pelican.mailPort | string | `"587"` |  |
| pelican.mailUsername | string | `""` |  |
| pelican.queueConnection | string | `"sync"` |  |
| pelican.sessionDomain | string | `""` |  |
| pelican.sessionDriver | string | `"file"` |  |
| pelican.sessionEncrypt | bool | `false` |  |
| pelican.sessionLifetime | string | `"120"` |  |
| pelican.sessionPath | string | `"/"` |  |
| pelican.trustedProxies | string | `"*"` |  |
| persistence.accessMode | string | `"ReadWriteOnce"` |  |
| persistence.data.enabled | bool | `true` |  |
| persistence.data.mountPath | string | `"/pelican-data"` |  |
| persistence.data.size | string | `"10Gi"` |  |
| persistence.enabled | bool | `true` |  |
| persistence.logs.enabled | bool | `true` |  |
| persistence.logs.mountPath | string | `"/var/www/html/storage/logs"` |  |
| persistence.logs.size | string | `"5Gi"` |  |
| persistence.size | string | `"10Gi"` |  |
| persistence.storageClass | string | `""` |  |
| podAnnotations | object | `{}` |  |
| podSecurityContext | object | `{}` |  |
| readinessProbe.enabled | bool | `true` |  |
| readinessProbe.failureThreshold | int | `3` |  |
| readinessProbe.initialDelaySeconds | int | `5` |  |
| readinessProbe.periodSeconds | int | `10` |  |
| readinessProbe.successThreshold | int | `1` |  |
| readinessProbe.timeoutSeconds | int | `5` |  |
| replicaCount | int | `1` |  |
| resources | object | `{}` |  |
| securityContext | object | `{}` |  |
| service.annotations | object | `{}` |  |
| service.port | int | `80` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| startupProbe.enabled | bool | `true` |  |
| startupProbe.failureThreshold | int | `30` |  |
| startupProbe.initialDelaySeconds | int | `0` |  |
| startupProbe.periodSeconds | int | `10` |  |
| startupProbe.successThreshold | int | `1` |  |
| startupProbe.timeoutSeconds | int | `1` |  |
| tolerations | list | `[]` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
