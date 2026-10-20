# Kafka Module

Deploys Apache Kafka in KRaft mode (no Zookeeper) with persistent storage, stable pod DNS, and a Kafka UI management console. KRaft is the built-in consensus mode available in Apache Kafka 3.3+.

## What Gets Created

| Resource | Name Pattern | Purpose |
|---|---|---|
| StatefulSet | `<name>-kafka` | Kafka broker+controller pods |
| Service (headless) | `<name>-kafka-headless` | Pod DNS for broker-to-broker communication |
| Service (client) | `<name>-kafka` | ClusterIP for producer/consumer connections |
| Service (UI) | `<name>-kafka-ui-svc` | LoadBalancer for Kafka UI |
| Deployment | `<name>-kafka-ui` | Kafka UI management console |
| PVC (per pod) | `data-<name>-kafka-0` | Log directory, provisioned by StorageClass |

## Inputs

| Name | Default | Description |
|---|---|---|
| `image` | `apache/kafka:latest` | Kafka image (must support KRaft) |
| `replicas` | `1` | Number of broker/controller replicas |
| `resourcePreset` | `compute-heavy` | CPU/memory preset |
| `volumeSize` | `20Gi` | PVC size per pod (log storage) |
| `storageClass` | `standard` | StorageClass for dynamic provisioning |
| `kafkaUiImage` | `provectuslabs/kafka-ui:latest` | Kafka UI image |

## Probes

| Probe | Type | Preset |
|---|---|---|
| startup | TCP :9092 | `slow-start` |
| liveness | TCP :9092 | `standard` |
| readiness | TCP :9092 | `standard` |
| Kafka UI liveness | HTTP `/actuator/health` | `standard` |
| Kafka UI readiness | HTTP `/actuator/health` | `standard` |

## Status Fields

| Field | Value |
|---|---|
| `kafkaReady` | True when all replicas are ready |
| `bootstrapServers` | `<svc>.<ns>.svc.cluster.local:9092` |
| `kafkaUiUrl` | `http://<kafka-ui-svc>.<ns>.svc.cluster.local:8080` |

## Usage in a Blueprint

```yaml
operatorBox:
  reconcile:
    imports:
      - module: oci://ghcr.io/intentd/registry/patterns/modules/kafka:v0.1.0
        with:
          volumeSize: "{{ .spec.storageSize | default \"20Gi\" }}"
          storageClass: "{{ .spec.storageClass | default \"standard\" }}"
          resourcePreset: "{{ .spec.resourcePreset | default \"compute-heavy\" }}"
```

## Notes

- This module configures a single-node KRaft cluster. `KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR` is set to `1` accordingly.
- For multi-broker clusters, set `replicas` > 1 and update `KAFKA_CONTROLLER_QUORUM_VOTERS` to include all pod addresses.
- `compute-heavy` resource preset is the default — Kafka is CPU-intensive under high throughput. Tune down to `medium` for development.
- `slow-start` startup probe gives Kafka 5 minutes to complete leader election and log recovery on restart.
- Kafka UI uses Spring Boot Actuator for health checks at `/actuator/health`.
