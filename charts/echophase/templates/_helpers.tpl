{{/*
Expand the name of the chart.
*/}}
{{- define "echophase.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "echophase.fullname" -}}
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
{{- define "echophase.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "echophase.labels" -}}
helm.sh/chart: {{ include "echophase.chart" . }}
{{ include "echophase.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "echophase.selectorLabels" -}}
app.kubernetes.io/name: {{ include "echophase.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Image pull policy
*/}}
{{- define "echophase.imagePullPolicy" -}}
{{- .Values.global.imagePullPolicy | default "IfNotPresent" }}
{{- end }}

{{/*
Image of one of our components: (list $ .Values.<component>.image).
The tag defaults to the chart's appVersion, so a chart release pins the
images it was released with.
*/}}
{{- define "echophase.image" -}}
{{- $root := index . 0 }}{{- $img := index . 1 -}}
{{- printf "%s/%s:%s" $root.Values.imageRegistry $img.repository (toString ($img.tag | default $root.Chart.AppVersion)) }}
{{- end }}

{{/*
Pull policy of one of our images: (list $ .Values.<component>.image). The
explicit pullPolicy if set, else Always for the moving "latest" tag and
IfNotPresent for any other (immutable) tag.
*/}}
{{- define "echophase.appImagePullPolicy" -}}
{{- $root := index . 0 }}{{- $img := index . 1 -}}
{{- $img.pullPolicy | default (ternary "Always" "IfNotPresent" (eq (toString ($img.tag | default $root.Chart.AppVersion)) "latest")) }}
{{- end }}

{{/*
Where the server finds each database: the release's own (<db>.enabled) or the
external one (<db>.external), which then must name a host.
*/}}
{{- define "echophase.postgresHost" -}}
{{- if .Values.postgres.enabled -}}
{{- printf "%s-postgres" (include "echophase.fullname" .) }}
{{- else -}}
{{- required "postgres.external.host is required when postgres.enabled is false" .Values.postgres.external.host }}
{{- end }}
{{- end }}

{{- define "echophase.postgresPort" -}}
{{- ternary .Values.postgres.service.port .Values.postgres.external.port .Values.postgres.enabled }}
{{- end }}

{{- define "echophase.valkeyHost" -}}
{{- if .Values.valkey.enabled -}}
{{- printf "%s-valkey" (include "echophase.fullname" .) }}
{{- else -}}
{{- required "valkey.external.host is required when valkey.enabled is false" .Values.valkey.external.host }}
{{- end }}
{{- end }}

{{- define "echophase.valkeyPort" -}}
{{- ternary .Values.valkey.service.port .Values.valkey.external.port .Values.valkey.enabled }}
{{- end }}

{{/* TLS to Valkey: only an external one may need it. */}}
{{- define "echophase.valkeySsl" -}}
{{- and (not .Values.valkey.enabled) .Values.valkey.external.ssl }}
{{- end }}

{{/* Comma-separated contact points of the Scylla cluster. */}}
{{- define "echophase.scyllaContactPoints" -}}
{{- if .Values.scylla.enabled -}}
{{- printf "%s-scylla" (include "echophase.fullname" .) }}
{{- else -}}
{{- required "scylla.external.contactPoints is required when scylla.enabled is false" .Values.scylla.external.contactPoints }}
{{- end }}
{{- end }}

{{- define "echophase.scyllaPort" -}}
{{- ternary .Values.scylla.service.port .Values.scylla.external.port .Values.scylla.enabled }}
{{- end }}
