{{- define "library-chart.deployment.tpl" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "library-chart.name" . }} #{{ include "library-chart.name" . }} will also have environment name as suffix
  labels:
    {{- include "library-chart.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.deployment.replicas }}
  selector:
    matchLabels:
      {{- include "library-chart.selectorLabels" . | nindent 6 }}
  strategy:
    {{- if .Values.deployment.strategy.rollingUpdate }}
    rollingUpdate:
      maxSurge: {{ .Values.deployment.strategy.rollingUpdate.maxSurge }}
      maxUnavailable: {{ .Values.deployment.strategy.rollingUpdate.maxUnavailable }}
    {{- end }}
    type: {{ .Values.deployment.strategy.type }}
  template:
    metadata:
      labels:
        {{- include "library-chart.selectorLabels" . | nindent 8 }}
        jenkins.deployment.id: {{ .Values.deployment.annotations.jenkinsDeploymentId | quote }}
      annotations:
        {{- if eq (.Values.istioSidecarInject) false }}
        sidecar.istio.io/inject: "false"
        {{- end }}
        {{- include "library-chart.annotations" . | nindent 8 }}
    spec:
      {{- with .Values.deployment.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      securityContext:
        {{- toYaml .Values.deployment.podSecurityContext | nindent 8 }}
      {{- if .Values.deployment.runAsRoot }}
      serviceAccountName: tenant-pod-root
      automountServiceAccountToken: true
      {{- end }}
      containers:
        {{- range $containerLabel, $containerMap := .Values.deployment.containers }}
        {{- if (or ($.Values.logshipperSidecarInject) (ne $containerMap.name "logshipper")) }}
        - name: {{ $containerMap.name }}
          image: {{ $containerMap.image.name }}:{{ $containerMap.image.tag }}
          {{- if $containerMap.ports }}
          ports:
            {{- toYaml $containerMap.ports | nindent 12 }}
          {{- end }}
          {{- if $containerMap.securityContext }}
          securityContext:
            {{- toYaml $containerMap.securityContext | nindent 12 }}
          {{- end }}
          {{- if $containerMap.command }}
          command: 
          {{- range $containerMap.command }}
            {{ print "- " . }}
          {{- end }}
          {{- end }}
          {{- if $containerMap.args }}
          args: 
          {{- range $containerMap.args }}
            {{ print "- " . }}
          {{- end }}
          {{- end }}
          {{/* Loop through envVars defined for the environment */}}
          {{- if $containerMap.env -}}
          env:
            {{- range $key, $value := $containerMap.env }}
            - name: {{ $key | replace "encrypted_" "" | quote }}
              value: {{ $value | quote }}
            {{- end }}
          {{- end }}
          {{- if $containerMap.livenessProbe }}
          livenessProbe:  
            {{- toYaml $containerMap.livenessProbe | nindent 12 }}
          {{- end }}
          {{- if $containerMap.readinessProbe }}
          readinessProbe:
            {{- toYaml $containerMap.readinessProbe | nindent 12 }}
          {{- end }}
          {{- if $containerMap.resources }}
          resources:
            {{- toYaml $containerMap.resources | nindent 12 }}
          {{- end }}
          {{- if $containerMap.volumeMounts }}
          volumeMounts:
            {{- toYaml $containerMap.volumeMounts | nindent 12 }}
          {{- end }}
        {{- end }}
        {{- end }}
      volumes:
        {{- toYaml .Values.deployment.volumes | nindent 8 }}
{{- end -}}