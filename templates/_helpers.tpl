{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "library-chart.name" -}}
  {{- if eq .Release.Name "RELEASE-NAME" -}}
    {{- printf "%s-%s" .Chart.Name .Chart.Version | trunc 63 | trimSuffix "-" -}}
  {{- else -}}
    {{- .Release.Name | trunc 63 | trimSuffix "-" -}}
  {{- end -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "library-chart.fullname" -}}
  {{- printf "%s-%s-%s" .Release.Name .Chart.Name .Chart.Version | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "library-chart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "library-chart.labels" -}}
helm.sh/chart: {{ include "library-chart.chart" . }}
{{ include "library-chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "library-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ .Release.Name }}
{{- end -}}

{{/*
Annotations
*/}}
{{- define "library-chart.annotations" -}}
jenkins.deployment.id: {{ .Values.deployment.annotations.jenkinsDeploymentId | quote }}
meta.helm.sh/release-namespace: {{ .Release.Namespace }}
meta.helm.sh/release-revision: {{ .Release.Revision | quote }}
{{- end -}}