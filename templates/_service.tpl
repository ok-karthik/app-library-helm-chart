{{- define "library-chart.service.tpl" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "library-chart.name" . }} #Gets suffixed with environment name as helm release name has app name + environment
  labels:
    {{- include "library-chart.labels" . | nindent 4 }}
  annotations:
    {{- range $key, $value := .Values.service.annotations }}
    {{ $key }}: {{ $value | quote }}
    {{- end }}
    {{- include "library-chart.annotations" . | nindent 4 }}
{{- /*
    # Helm multi-line comment block
    # Don't enable/use below for normal service as instant domain URL will not work
    # Useful Only when you are deploying a headless service to CaaS
    {{- if eq (.Values.istioSidecarInject) false }}
    networking.istio.io/exportTo: "."
    {{- end }}
*/}}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.targetPort | default .Values.service.port }}
      protocol: TCP
      name: http
  selector:
    {{- include "library-chart.selectorLabels" . | nindent 4 }}
{{- end }}