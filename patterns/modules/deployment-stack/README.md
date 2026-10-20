# Deployment Stack Module

Full application deployment stack: ServiceAccount, Role, RoleBinding, Deployment, Service, HPA, PDB, and optional Ingress. All inputs are optional except `image`, `port`, `name`, and `namespace`. Ingress is only created when the CR `data.host` field is non-empty.

## What Gets Created

| Resource | Name Pattern | Purpose |
|---|---|---|
| Namespace | `<namespace>` | Target namespace (created/reconciled when enabled) |
| ServiceAccount | `<name>-sa` | Pod identity for the application |
| Role | `<name>-role` | Minimal RBAC for managing the app Deployment |
| RoleBinding | `<name>-rolebinding` | Binds the ServiceAccount to the Role |
| Deployment | `<name>` | Application pods running the provided image |
| Service (ClusterIP) | `<name>-svc` | Internal service for app traffic |
| Ingress | `<name>-ingress` | Public ingress for the service (created when `host` is set) |
| HorizontalPodAutoscaler | `<name>-hpa` | Autoscaling policy for the Deployment |
| PodDisruptionBudget | `<name>-pdb` | Availability guard during voluntary disruptions |

## Inputs

| Name | Default | Description |
|---|---:|---|
| `name` | *required* | Resource name prefix. Typically the app name. |
| `namespace` | *required* | Target namespace for all resources. |
| `image` | *required* | Container image (e.g. `ghcr.io/myorg/myapp:latest`). |
| `port` | *required* | Container port the application listens on (e.g. `8080`). |
| `replicas` | `2` | Desired replica count for the Deployment. |
| `maxReplicas` | `10` | Maximum replicas for HPA scale‑out. |
| `resourcePreset` | `burst` | Resource preset (tiny, small, medium, large, burst, steady, compute-heavy, memory-heavy). |
| `ingressClass` | `nginx` | Ingress class name (nginx, traefik, kong, etc.). |
| `host` | `""` | Public hostname for Ingress (e.g. `myapp.example.com`). When empty the Ingress is not created. |

## Probes

| Probe | Type | Target | Preset |
|---|---|---:|---|
| startup | TCP | `:port` | `slow-start` (gives app time to initialize) |
| liveness | HTTP | `/healthz` or TCP `:port` | `standard` |
| readiness | HTTP | `/ready` or TCP `:port` | `standard` |

Notes: the module uses TCP probes by default when no HTTP path is provided. Adjust probe paths via inputs or by overriding templates if your app exposes HTTP health endpoints.

## Status Fields

| Field | Value |
|---|---|
| `deploymentReady` | True when the Deployment has the desired number of ready replicas |
| `serviceName` | `<name>-svc` |
| `ingressUrl` | `http://<host>` when `host` is set and Ingress is created |
| `hpaStatus` | Current HPA status summary (min/max/current replicas) |

## Usage in a Blueprint

```yaml
operatorBox:
  reconcile:
    imports:
      - module: oci://ghcr.io/intentd/registry/patterns/modules/deployment-stack:v0.1.0
        with:
          name: "{{ .metadata.name }}"
          namespace: "{{ .metadata.namespace }}"
          image: "{{ .spec.image }}"
          port: "{{ .spec.port }}"
          replicas: '{{ .spec.replicas | default "2" }}'
          maxReplicas: '{{ .spec.maxReplicas | default "10" }}'
          resourcePreset: '{{ .spec.resourcePreset | default "burst" }}'
          ingressClass: '{{ .spec.ingressClass | default "nginx" }}'
          host: '{{ .spec.host | default "" }}'
```

## Notes

- The module creates minimal RBAC (Role + RoleBinding) scoped to the target namespace and the named Deployment. Adjust rules if your application needs broader permissions.
- Ingress is only created when `host` is provided. This avoids exposing services unintentionally in environments without a configured ingress controller.
- HPA is configured with `targetCPUUtilizationPercentage: 70` by default. Tune `resourcePreset` and HPA settings for production workloads.
- PodDisruptionBudget ensures at least one pod remains available during voluntary disruptions; adjust `minAvailable` for higher availability requirements.
- The module reconciles resources only when the corresponding `when` conditions are satisfied (for example, many resources require `data.image` to exist). This makes the module safe to include in catalogs where inputs are populated at runtime.
- `resourcePreset` maps to an Inrun CPU/memory preset. Use `burst` for short-lived CPU spikes, `medium` for balanced workloads, and `memory-heavy` for memory-sensitive services.
- Service is created as ClusterIP by default. If you need a different service type (NodePort, LoadBalancer), override the template or extend the module.
