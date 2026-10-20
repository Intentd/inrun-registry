# Redis Module

Deploys a Redis instance with optional persistent storage, stable pod DNS, and a Redis Commander management console. Works as a pure in-memory cache or a persistent key-value store.

## What Gets Created

| Resource | Name Pattern | Purpose |
|---|---|---|
| StatefulSet | `<name>-redis` | Redis pods with stable identity |
| Service (headless) | `<name>-redis-headless` | Pod DNS |
| Service (client) | `<name>-redis` | ClusterIP for application connections |
| Service (UI) | `<name>-commander-svc` | LoadBalancer for Redis Commander |
| Deployment | `<name>-commander` | Redis Commander management UI |
| PVC (per pod) | `data-<name>-redis-0` | Provisioned by StorageClass |

## Inputs

| Name | Default | Description |
|---|---|---|
| `image` | `redis:latest` | Redis container image |
| `replicas` | `1` | Number of replicas |
| `resourcePreset` | `burst` | CPU/memory preset (burst suits cache workloads) |
| `volumeSize` | `5Gi` | PVC size per pod |
| `storageClass` | `standard` | StorageClass for dynamic provisioning |
| `commanderImage` | `rediscommander/redis-commander:latest` | Commander UI image |

## Probes

| Probe | Type | Preset |
|---|---|---|
| startup | TCP :6379 | `patient` |
| liveness | TCP :6379 | `standard` |
| readiness | TCP :6379 | `standard` |
| Commander liveness | HTTP `/` | `standard` |
| Commander readiness | HTTP `/` | `standard` |

## Status Fields

| Field | Value |
|---|---|
| `redisReady` | True when all replicas are ready |
| `connectionString` | `redis://<svc>.<ns>.svc.cluster.local:6379` |
| `commanderUrl` | `http://<commander-svc>.<ns>.svc.cluster.local:8081` |

## Usage in a Blueprint

```yaml
operatorBox:
  reconcile:
    imports:
      - module: oci://ghcr.io/intentd/registry/patterns/modules/redis:v0.1.0
        with:
          volumeSize: "{{ .spec.cacheSize | default \"5Gi\" }}"
          storageClass: "{{ .spec.storageClass | default \"standard\" }}"
          resourcePreset: "{{ .spec.resourcePreset | default \"burst\" }}"
```

## Notes

- `burst` resource preset is the default because Redis workloads are spiky: small under low load, high throughput under pressure.
- `patient` startup probe suits Redis since it initializes quickly but may need a moment to load a large AOF/RDB file on restart.
- For Redis Cluster or Sentinel mode, configure the topology separately using additional Blueprint resources.
