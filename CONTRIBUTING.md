# Contributing

A pattern is a Blueprint, or a Module that Blueprints import.

## Layout

```
patterns/
├── blueprints/<name>/<version>/
│   ├── blueprint.yaml       kind: Blueprint, the operator
│   ├── stack.yaml           an example of using the Blueprint
│   ├── manifests/
│   │   ├── crd.yaml         the CRD it reconciles
│   │   └── cr.yaml          an example CR
│   └── test/
│       ├── simulate.yaml    in-memory test, run before every push
│       └── e2e.yaml         test on kind, run before every push
└── modules/<name>/
    ├── module.yaml      kind: Module, resources a Blueprint imports
    └── README.md        its inputs and what it creates
```

This is the layout `inrun init` writes, so `inrun validate`, `inrun simulate`
and `inrun e2e` find every file from inside the Blueprint's directory without
`-f`. The name and version come from each file's `metadata`. Versions start at
`v0.1.0`; a Blueprint's directory is named after its version.

## Test locally

Point a Blueprint at its Module by path while you work on both, then switch
back to the OCI reference before you push:

```yaml
- module: ../../../modules/postgres/module.yaml
```

```bash
cd patterns/blueprints/postgres/v0.1.0
inrun validate
inrun simulate
inrun e2e
```

## Push

`inrun push` runs `test/simulate.yaml` and `test/e2e.yaml` first and records
the results in the artifact. Push a Module before the Blueprints that import it:
`make push-all` does them in that order.
