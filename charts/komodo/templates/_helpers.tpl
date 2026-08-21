{{/*
Expand the name of the chart.
*/}}
{{- define "komodo.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "komodo.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "komodo.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "komodo.labels" -}}
helm.sh/chart: {{ include "komodo.chart" . }}
{{ include "komodo.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "komodo.selectorLabels" -}}
app.kubernetes.io/name: {{ include "komodo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "komodo.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "komodo.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Name of the chart managed Secret (only rendered when plaintext values are supplied).
*/}}
{{- define "komodo.secretName" -}}
{{- printf "%s-secret" (include "komodo.fullname" .) }}
{{- end }}

{{/*
Whether the chart managed Secret should be created.
*/}}
{{- define "komodo.createSecret" -}}
{{- if or .Values.database.username .Values.database.password .Values.komodo.secrets.jwtSecret .Values.komodo.secrets.webhookSecret .Values.komodo.secrets.initAdminPassword -}}
true
{{- end -}}
{{- end }}

{{/*
Probe handler. Renders an httpGet probe against `path`, or a tcpSocket probe
when `type` is set to "tcp". Komodo Core has no dedicated health endpoint, but
exposes an unauthenticated GET /version on the same port as the UI/API.
Usage: include "komodo.probeHandler" .Values.livenessProbe
*/}}
{{- define "komodo.probeHandler" -}}
{{- if eq (default "http" .type) "tcp" -}}
tcpSocket:
  port: http
{{- else -}}
httpGet:
  path: {{ default "/version" .path }}
  port: http
{{- end }}
{{- end }}

{{/*
PersistentVolumeClaim name for a persistence entry.
Usage: include "komodo.pvcName" (dict "root" $ "name" "keys" "config" .Values.persistence.keys)
*/}}
{{- define "komodo.pvcName" -}}
{{- if .config.existingClaim -}}
{{ .config.existingClaim }}
{{- else -}}
{{ printf "%s-%s" (include "komodo.fullname" .root) .name }}
{{- end -}}
{{- end }}
