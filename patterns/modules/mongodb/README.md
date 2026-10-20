# MongoDB Module

Deploys a production-ready MongoDB instance with persistent storage, stable pod DNS, and a mongo-express management console.

## What Gets Created

| Resource | Name Pattern | Purpose |
|---|---|---|
| StatefulSet | `<name>-mongodb` | MongoDB pods with stable identity |
| Service (headless) | `<name>-mongodb-headless` | Pod DNS for replica set members |
| Service (client) | `<name>-mongodb` | ClusterIP for application connections |
| Service (UI) | `<name>-mongoexpress-svc` | LoadBalancer for mongo-express |
| Deployment | `<name>-mongoexpress` | mongo-express management console |
| PVC (per pod) | `data-<name>-mongodb-0` | Provisioned by StorageClass |

## Inputs

| Name | Default | Description |
|---|---|---|
| `image` | `mongo:latest` | MongoDB container image |
| `replicas` | `1` | Number of replicas |
| `resourcePreset` | `burst` | CPU/memory preset |
| `volumeSize` | `10Gi` | PVC size per pod |
| `storageClass` | `standard` | StorageClass for dynamic provisioning |
| `database` | `app` | Default database name |
| `username` | `admin` | MongoDB root username |
| `mongoExpressImage` | `mongo-express:latest` | mongo-express image |

## Probes

| Probe | Type | Preset |
|---|---|---|
| startup | TCP :27017 | `slow-start` |
| liveness | TCP :27017 | `standard` |
| readiness | TCP :27017 | `standard` |
| mongo-express liveness | HTTP `/` | `standard` |
| mongo-express readiness | HTTP `/` | `standard` |

## Status Fields

| Field | Value |
|---|---|
| `mongodbReady` | True when all replicas are ready |
| `connectionString` | `mongodb://<user>@<svc>.<ns>.svc.cluster.local:27017/<db>` |
| `mongoExpressUrl` | `http://<mongoexpress-svc>.<ns>.svc.cluster.local:8081` |

## Usage in a Blueprint

```yaml
operatorBox:
  reconcile:
    imports:
      - module: oci://ghcr.io/intentd/registry/patterns/modules/mongodb:v0.1.0
        with:
          database: "{{ .spec.dbName | default \"app\" }}"
          volumeSize: "{{ .spec.storageSize | default \"10Gi\" }}"
          storageClass: "{{ .spec.storageClass | default \"standard\" }}"
          resourcePreset: "{{ .spec.resourcePreset | default \"standard\" }}"
```

## Notes

- `MONGO_INITDB_ROOT_PASSWORD` must be supplied via a secret in your Blueprint.
- mongo-express runs with `ME_CONFIG_BASICAUTH: false` by default for local development. Enable auth for production.
- For multi-replica replica sets, configure `rs.initiate()` via an init container or startup script.
