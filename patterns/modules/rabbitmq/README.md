# RabbitMQ Module

Deploys RabbitMQ with persistent storage, stable pod DNS, AMQP service, and the built-in management web UI (included in the `rabbitmq:management` image).

## What Gets Created

| Resource | Name Pattern | Purpose |
|---|---|---|
| StatefulSet | `<name>-rabbitmq` | RabbitMQ pods with stable identity |
| Service (headless) | `<name>-rabbitmq-headless` | Pod DNS for cluster node discovery |
| Service (AMQP) | `<name>-rabbitmq` | ClusterIP for producer/consumer connections |
| Service (management) | `<name>-rabbitmq-management` | LoadBalancer for the web management UI |
| PVC (per pod) | `data-<name>-rabbitmq-0` | Provisioned by StorageClass |

## Inputs

| Name | Default | Description |
|---|---|---|
| `image` | `rabbitmq:management` | RabbitMQ image (management tag includes web UI) |
| `replicas` | `1` | Number of replicas |
| `resourcePreset` | `small` | CPU/memory preset |
| `volumeSize` | `5Gi` | PVC size per pod |
| `storageClass` | `standard` | StorageClass for dynamic provisioning |
| `username` | `admin` | Default admin username |
| `vhost` | `/` | Default virtual host |

## Probes

| Probe | Type | Preset | Notes |
|---|---|---|---|
| startup | TCP :5672 | `patient` | Quick init — 30s window is enough |
| liveness | TCP :5672 | `standard` | Detects dead AMQP listener |
| readiness | HTTP `/api/health/checks` | `standard` | Verifies management API is up |

The readiness probe uses the management API health endpoint, which confirms both the AMQP listener and the HTTP management plugin are operational before routing traffic.

## Status Fields

| Field | Value |
|---|---|
| `rabbitmqReady` | True when all replicas are ready |
| `amqpUrl` | `amqp://<user>@<svc>.<ns>.svc.cluster.local:5672<vhost>` |
| `managementUrl` | `http://<management-svc>.<ns>.svc.cluster.local:15672` |

## Usage in a Blueprint

```yaml
operatorBox:
  reconcile:
    imports:
      - module: oci://ghcr.io/intentd/registry/patterns/modules/rabbitmq:v0.1.0
        with:
          volumeSize: "{{ .spec.storageSize | default \"5Gi\" }}"
          storageClass: "{{ .spec.storageClass | default \"standard\" }}"
          resourcePreset: "{{ .spec.resourcePreset | default \"small\" }}"
          username: "{{ .spec.username | default \"admin\" }}"
```

## Notes

- `RABBITMQ_DEFAULT_PASS` must be supplied via a secret in your Blueprint.
- The `rabbitmq:management` image includes the management plugin pre-enabled on port 15672. Use `rabbitmq:latest` if you only need AMQP and want a smaller image (but then the management service becomes non-functional).
- For RabbitMQ clustering (Quorum Queues), set `replicas` > 1 and configure `RABBITMQ_ERLANG_COOKIE` consistently across pods.
- `small` resource preset suits most workloads. RabbitMQ is lightweight at rest and scales linearly with message throughput.
