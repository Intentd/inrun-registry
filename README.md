# inrun-registry

Versioned [Inrun](https://github.com/intentd/inrun) patterns, published to
`ghcr.io/intentd/registry`. Each artifact carries its own test results.

| Pattern | Blueprint | Module |
|---|---|---|
| postgres | PostgreSQL with storage and pgAdmin | StatefulSet, Services, storage, pgAdmin |
| mysql | MySQL with storage and phpMyAdmin | StatefulSet, Services, storage, phpMyAdmin |
| mongodb | MongoDB with storage and mongo-express | StatefulSet, Services, storage, mongo-express |
| redis | Redis with storage and Redis Commander | StatefulSet, Services, storage, Redis Commander |
| kafka | Kafka (KRaft) with storage and Kafka UI | StatefulSet, Services, storage, Kafka UI |
| rabbitmq | RabbitMQ with storage and management UI | StatefulSet, Services, storage, management UI |
| deployment-stack | Deployment, Service and Ingress | Deployment, Service, Ingress, HPA, RBAC |

## Use

```bash
brew install intentd/tap/inrun    # or: curl -sSL https://get.inrun.dev | bash

inrun inspect postgres:v0.1.0     # version, description and test results
inrun postgres:v0.1.0             # run it
```

Import a Module into your own Blueprint:

```yaml
operatorBox:
  reconcile:
    imports:
      - module: oci://ghcr.io/intentd/registry/patterns/modules/postgres:v0.1.0
        with:
          volumeSize: "20Gi"
```

Each Module's README lists its inputs.

## Publish

```bash
make push-all    # Modules, then Blueprints; each Blueprint push runs its simulate and e2e gates
make help        # the other targets
```

## License

Apache-2.0
