# MySQL Module

Deploys a production-ready MySQL instance with persistent storage, stable pod DNS, and a phpMyAdmin management console.

## What Gets Created

| Resource | Name Pattern | Purpose |
|---|---|---|
| StatefulSet | `<name>-mysql` | MySQL pods with stable identity |
| Service (headless) | `<name>-mysql-headless` | Pod DNS for replication/cluster |
| Service (client) | `<name>-mysql` | ClusterIP for application connections |
| Service (UI) | `<name>-phpmyadmin-svc` | LoadBalancer for phpMyAdmin |
| Deployment | `<name>-phpmyadmin` | phpMyAdmin management console |
| PVC (per pod) | `data-<name>-mysql-0` | Provisioned by StorageClass |

## Inputs

| Name | Default | Description |
|---|---|---|
| `image` | `mysql:latest` | MySQL container image |
| `replicas` | `1` | Number of replicas |
| `resourcePreset` | `burst` | CPU/memory preset |
| `volumeSize` | `10Gi` | PVC size per pod |
| `storageClass` | `standard` | StorageClass for dynamic provisioning |
| `database` | `app` | Default database name |
| `username` | `mysql` | MySQL user name |
| `phpMyAdminImage` | `phpmyadmin:latest` | phpMyAdmin image |

## Probes

| Probe | Type | Preset |
|---|---|---|
| startup | TCP :3306 | `slow-start` |
| liveness | TCP :3306 | `standard` |
| readiness | TCP :3306 | `standard` |
| phpMyAdmin liveness | HTTP `/` | `standard` |
| phpMyAdmin readiness | HTTP `/` | `standard` |

## Status Fields

| Field | Value |
|---|---|
| `mysqlReady` | True when all replicas are ready |
| `connectionString` | `mysql://<user>@<svc>.<ns>.svc.cluster.local:3306/<db>` |
| `phpMyAdminUrl` | `http://<phpmyadmin-svc>.<ns>.svc.cluster.local` |

## Usage in a Blueprint

```yaml
operatorBox:
  reconcile:
    imports:
      - module: oci://ghcr.io/intentd/registry/patterns/modules/mysql:v0.1.0
        with:
          database: "{{ .spec.dbName | default \"app\" }}"
          volumeSize: "{{ .spec.storageSize | default \"10Gi\" }}"
          storageClass: "{{ .spec.storageClass | default \"standard\" }}"
          resourcePreset: "{{ .spec.resourcePreset | default \"standard\" }}"
```

## Notes

- `MYSQL_PASSWORD` and `MYSQL_ROOT_PASSWORD` should be supplied via secrets referenced in your Blueprint.
- `MYSQL_RANDOM_ROOT_PASSWORD: "yes"` is set by default — override via env in your Blueprint if you need a fixed root password.
