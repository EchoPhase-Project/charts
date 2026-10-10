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
