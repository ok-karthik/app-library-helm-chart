{{- define "library-chart.pdb.tpl" -}}
{{- if .Values.PodDisruptionBudget.enabled }}
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ include "library-chart.name" . }}-pdb
  labels:
    {{- include "library-chart.labels" . | nindent 4 }}
spec:
  minAvailable: {{ .Values.PodDisruptionBudget.minAvailable | default "1" }}
  selector:
    matchLabels:
      {{- include "library-chart.selectorLabels" . | nindent 6 }}
{{- end }}
{{- end -}}
