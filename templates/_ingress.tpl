{{- define "library-chart.ingress.tpl" -}}
{{- if .Values.ingress.enabled -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "library-chart.name" . }} #Gets suffixed with environment name as helm release name has app name + environment
  labels:
    {{- include "library-chart.labels" . | nindent 4 }}
  annotations:
    {{- range $key, $value := .Values.ingress.annotations }}
    {{ $key }}: {{ $value | quote }}
    {{- end }}
    {{- include "library-chart.annotations" . | nindent 4 }}
spec:
  ingressClassName: {{ .Values.ingress.spec.ingressClassName }}
  rules:
    {{- range .Values.ingress.spec.rules }}
    - host: {{ .host }}
      http:
        paths:
          {{- range .http.paths }}
          - path: {{ .path | default "/" }}
            pathType: {{ .pathType | default "Prefix" }}
            backend:
              service:
                name: {{ .backend.service.name | default (include "library-chart.name" $) }}
                port:
                  number: {{ .backend.service.port.number | default $.Values.service.port }}
          {{- end }}
    {{- end }}
{{- end -}}
{{- end -}}