{{- define "library-chart.networkpolicy.tpl" -}}
{{- if .Values.networkPolicy.override -}}
---
# Allow all outgoing(egress) traffic to internet for all pods within namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ include "library-chart.name" . }}-allow-all-egress-traffic #include library-chart.name gets suffixed with environment name as helm release name has app name + environment
spec:
  egress:
  - {}
  podSelector: {}
  policyTypes:
  - Egress
#---
### Allow incoming(ingress) traffic from specific namespaces
#apiVersion: networking.k8s.io/v1
#kind: NetworkPolicy
#metadata:
#  name: allow-ingress-traffic-from-specific-namespaces
#spec:
#  ingress:
#  - from:
#    - namespaceSelector:
#        matchLabels:
#          name: other-namespace-name
#      podSelector:
#        matchLabels:
#          app.kubernetes.io/instance: label-value
#    - namespaceSelector:
#        matchLabels:
#          name: other-namespace-name
#  podSelector:
#    matchLabels:
#      app.kubernetes.io/name: myapp
#  policyTypes:
#  - Ingress
#---
## Allow all incoming(ingress) and outgoing(egress) traffic
#apiVersion: networking.k8s.io/v1
#kind: NetworkPolicy
#metadata:
#  name: allow-all-ingress-and-egress-traffic
#spec:
#  egress:
#  - {}
#  ingress:
#  - {}
#  podSelector: {}
#  policyTypes:
#  - Ingress
#  - Egress
{{- end -}}
{{- end -}}