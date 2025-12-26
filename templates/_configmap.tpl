{{/*
  # create one configmap for each file present inside helm-chart/files/configmaps/ "DEFAULT" and "${ENV}" directories
  #   metadata.name = <helm release name>-<filename along with extension present at helm-chart/files/configmaps/ directory>
  #               eg: <webapp-dev>-<filebeat.yml>
  # data = <filename>: <file content>
  #   inject non-secret text files, processed as templates
  # Pipeline logic will overwrite DEFAULT files with environment specific files
*/}}

{{ define "library-chart.configmapsFromFiles.tpl" }}
{{/* # to keep 'currentScope' reference for nested loops */}}
{{- $currentScope := . }}

{{- $env_trimmed_filepaths := list -}}
{{- $env_absolute_filepaths := list -}}
{{- $final_absolute_filepaths := list -}}

{{ $env_files_location := printf "files/configmaps/%s/" .Values.env }}
{{ $default_files_location := printf "files/configmaps/DEFAULT/" }}

{{/*
  # Traverse through env specific files and create ConfigMaps
*/}}
{{ range $filepath, $bytes := $currentScope.Files.Glob (printf "%s**" $env_files_location) }}
  {{- $env_trimmed_filepaths = printf "%s" (trimPrefix $env_files_location $filepath) | append $env_trimmed_filepaths -}}
  {{- $env_absolute_filepaths = printf "%s" $filepath | append $env_absolute_filepaths -}}
{{ end }}

{{- $final_absolute_filepaths := $env_absolute_filepaths -}}

{{/*
  # Traverse through DEFAULT files and prepare list of filepaths which are not present in ENV specific directory
*/}}
{{ range $filepath, $bytes := $currentScope.Files.Glob (printf "%s**" $default_files_location) }}
  {{- $default_trimmed_filepath := trimPrefix $default_files_location $filepath -}}
  {{- if not (hasSuffix ".gitignore" $filepath) }}
    {{- if not (has $default_trimmed_filepath $env_trimmed_filepaths) }}
      {{- $final_absolute_filepaths = printf "%s" $filepath | append $final_absolute_filepaths -}}
    {{- end -}}
  {{- end -}}
{{ end }}

{{/*
  # Traverse through Final override list and generate ConfigMap YAMLs
*/}}
{{- range $filepath := $final_absolute_filepaths }}
{{ $trimmed_filepath:= trimPrefix $default_files_location $filepath }}
{{ $trimmed_filepath:= trimPrefix $env_files_location $trimmed_filepath }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ template "library-chart.name" $currentScope }}-{{ $trimmed_filepath | replace "/" "-" | replace "_" "-" | lower }}
  annotations:
    {{- include "library-chart.annotations" $currentScope | nindent 4 }}
data:
  {{ base $filepath }}: |-
{{ printf "%s" (tpl ($currentScope.Files.Get $filepath) $) | indent 4 }}
---
{{- end }}

{{ end }}
