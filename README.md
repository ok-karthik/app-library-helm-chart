# Purpose
The purpose of this Library Chart is to share the [Helm Named Templates](https://helm.sh/docs/chart_template_guide/named_templates/) developed through a library helm chart, which can be utilised by other charts

## What is a Library Chart?
Please read [Helm Library Chart](https://helm.sh/docs/topics/library_charts/)

## What type of [Helm Named Templates](https://helm.sh/docs/chart_template_guide/named_templates/) are included in this library chart?
- Generate ConfigMaps present in DEFAULT directory and also add environment specific ConfigMaps
- Generate Secrets present in DEFAULT directory and also add environment specific Secrets
- Filebeat sidecar container and environment specific override configs
- Load environment variables, volume mounts from values yaml files

# How to package and publish

Please refer to the steps below. The examples use an OCI registry (GitHub Container Registry) — adapt the registry and owner to your organization.

```bash
# Package the chart
helm package .

# Publish to an OCI registry (example: GitHub Container Registry)
# Requires Helm >= 3.8 with OCI support.
# 1) Authenticate to the registry (use a personal access token where required)
helm registry login ghcr.io -u YOUR_GITHUB_USERNAME

# 2) Save and push the chart (replace OWNER with your org/user)
helm chart save . ghcr.io/OWNER/library-chart:1.0.0
helm chart push ghcr.io/OWNER/library-chart:1.0.0
```

## Usage

If you publish to an OCI registry, reference the chart using an OCI repository. Example `Chart.yaml` dependency snippet:

```yaml
dependencies:
  - name: library-chart
    version: 1.0.0
    repository: oci://ghcr.io/OWNER
```
This library chart will be used as a [sub-chart](https://helm.sh/docs/chart_template_guide/subcharts_and_globals/) when the above dependency is declared.

Then the [Helm Named Templates](https://helm.sh/docs/chart_template_guide/named_templates/) can be utilised in following ways
```yaml
{{- include "library-chart.configmapsFromFiles.tpl" . -}}
{{- include "library-chart.deployment.tpl" . -}}
{{- include "library-chart.secretsFromFiles.tpl" . -}}
{{- include "library-chart.service.tpl" . -}}
``` 

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## Calling Chart Structure (example)

The following shows how a consuming chart (the "caller") can reference this `library-chart` as a dependency and structure its files so the library named templates work as intended.

Example `Chart.yaml` for the calling chart:

```yaml
apiVersion: v2
name: caller-chart
version: 0.1.0
dependencies:
  - name: library-chart
    version: 1.0.0
    repository: oci://ghcr.io/OWNER
```

Recommended directory layout for the calling chart:

```
caller-chart/
├─ Chart.yaml
├─ values.yaml                # declare values like `env`, `deployment`, `service`, etc.
├─ templates/
│  ├─ deployment.yaml         # simple wrapper that includes library templates
│  └─ service.yaml
└─ files/
   ├─ configmaps/
   │  ├─ DEFAULT/
   │  │  └─ app.conf
   │  └─ dev/
   │     └─ app.conf           # environment-specific override
   └─ secrets/
      ├─ DEFAULT/
      │  └─ db_creds
      └─ dev/
         └─ db_creds
```

Example `templates/deployment.yaml` in the calling chart (very small wrapper):

```yaml
{{- include "library-chart.deployment.tpl" . -}}
```

Example `templates/service.yaml` in the calling chart:

```yaml
{{- include "library-chart.service.tpl" . -}}
```

Example `values.yaml` (caller) snippets used by the library templates:

```yaml
env: dev
deployment:
  replicas: 2
  containers:
    main:
      name: myapp
      image:
        name: ghcr.io/OWNER/myapp
        tag: 1.2.3
service:
  port: 8080
  targetPort: 8080
```

This chart layout allows the library's named templates to read files from `files/configmaps/*` and `files/secrets/*`, and pick up `values.yaml` settings from the calling chart's scope.

## Consume locally

For developer-friendly workflows you can consume this `library-chart` locally without publishing to a registry. Two common options are shown below.

1) Local path dependency (developer workflow)

In the calling chart `Chart.yaml` use a `file://` repository pointing to the library chart path:

```yaml
dependencies:
  - name: library-chart
    version: 1.0.0
    repository: file://../library-chart
```

Then run:

```bash
helm dependency update
helm install ./ --generate-name
```

2) Vendor the library into `charts/` (self-contained caller)

Copy the library into your chart's `charts/` directory so the caller is self-contained:

```bash
cp -r ../library-chart caller-chart/charts/library-chart
cd caller-chart
helm install . --generate-name
```

Pros/cons (short):
- `file://`: simple, immediate, great for local development. Requires repo layout to be preserved.
- `charts/` vendoring: self-contained for distribution or users who only clone the caller chart. May duplicate contents if used across many callers.

Keep OCI/GHCR publishing instructions if you want CI or centralized sharing, but prefer `file://` or `charts/` for simple onboarding and local development.

## Templates Overview (what each `_*.tpl` does)

Below is a short, simple description of each template shipped in this library, and a tiny visual showing inputs → purpose.

- `_helpers.tpl`: Defines small helper named templates used across other templates (chart/release naming, labels, selectors, annotations).
  - Purpose: reusable name/label helpers
  - Visual: chart metadata + release -> `include "library-chart.name"` / labels

- `_deployment.tpl`: Renders a `Deployment` resource using values from `.Values.deployment` (containers, probes, volumes, securityContext, imagePullSecrets).
  - Purpose: centralize a common deployment pattern for callers
  - Visual: `.Values.deployment` -> Deployment YAML

- `_service.tpl`: Renders a `Service` resource (type, ports, selector) driven by `.Values.service`.
  - Purpose: create a Service matching the deployment selector
  - Visual: `.Values.service` -> Service YAML

- `_ingress.tpl`: Renders an `Ingress` (networking.k8s.io/v1) when `.Values.ingress.enabled` is true. Supports ingressClassName, rules, paths.
  - Purpose: optional HTTP routing via Ingress
  - Visual: `.Values.ingress` -> Ingress YAML

- `_configmap.tpl`: Generates one `ConfigMap` per file found under `files/configmaps/DEFAULT/` and `files/configmaps/<env>/`. Env files override DEFAULT files.
  - Purpose: convert files in `files/configmaps` into ConfigMaps automatically
  - Visual: files/configmaps/DEFAULT + files/configmaps/<env> -> multiple ConfigMaps

- `_secret.tpl`: Similar to configmaps: converts files under `files/secrets/DEFAULT/` and `files/secrets/<env>/` into `Secret` resources (base64 encoded via AsSecrets).
  - Purpose: convert secret files into Kubernetes Secrets
  - Visual: files/secrets/DEFAULT + files/secrets/<env> -> multiple Secrets

- `_networkpolicy.tpl`: When `.Values.networkPolicy.override` is true, emits a permissive `NetworkPolicy` allowing egress (networking.k8s.io/v1).
  - Purpose: optional network policy snippets (default allows all egress)
  - Visual: `.Values.networkPolicy` -> NetworkPolicy YAML

- `_pdb.tpl`: Emits a `PodDisruptionBudget` using `policy/v1` when `.Values.PodDisruptionBudget.enabled` is true (configured in `values.yaml`).
  - Purpose: protect minimum available pods during evictions
  - Visual: `.Values.PodDisruptionBudget` -> PodDisruptionBudget YAML

- `_virtualservice.tpl`: Emits an Istio `VirtualService` (networking.istio.io/v1beta1) when enabled via `.Values.istioVirtualService.enabled`.
  - Purpose: optional Istio routing configuration for advanced users
  - Visual: `.Values.istioVirtualService` -> VirtualService YAML

Use the named templates with `include` from any template in the calling chart, for example:

```yaml
{{- include "library-chart.configmapsFromFiles.tpl" . -}}
{{- include "library-chart.secretsFromFiles.tpl" . -}}
{{- include "library-chart.deployment.tpl" . -}}
{{- include "library-chart.service.tpl" . -}}
```

If you'd like, I can also add a short example caller chart to this repository (`examples/caller-chart/`) that demonstrates the full layout and a minimal end-to-end usage. Want me to add that? 