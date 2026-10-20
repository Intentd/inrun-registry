# inrun-registry: validate, test and push every pattern to ghcr.io/intentd/registry
#
#   make push-all                push Modules, then Blueprints (Blueprints import Modules)
#   make push-modules            push every Module
#   make push-blueprints         push every Blueprint; each push runs its simulate and e2e gates
#   make push NAME=postgres      push one Blueprint
#   make validate                validate every Module (Blueprints need their Modules pushed first)
#   make e2e NAME=postgres       run one Blueprint's e2e test on kind
#   make e2e-all                 run every Blueprint's e2e test

VERSION ?= v0.1.0
NAME    ?=
FORCE   ?= 0

INRUN := $(shell which inrun 2>/dev/null || echo "$(HOME)/.inrun/bin/inrun")

MODULES    := $(sort $(wildcard patterns/modules/*/module.yaml))
BLUEPRINTS := $(sort $(wildcard patterns/blueprints/*/$(VERSION)/blueprint.yaml))

force := $(if $(filter 1,$(FORCE)),--force,)

.PHONY: help validate push-modules push-blueprints push-all push e2e e2e-all _name

help:
	@sed -n '3,9p' Makefile | sed 's/^# //'

validate:
	@for f in $(MODULES); do $(INRUN) validate -f $$f || exit 1; done

push-modules:
	@for f in $(MODULES); do $(INRUN) push $$(dirname $$f) || exit 1; done

push-blueprints:
	@for f in $(BLUEPRINTS); do d=$$(dirname $$f); \
	  $(INRUN) pull -f $$f && $(INRUN) push $$d $(force) || exit 1; done

push-all: validate push-modules push-blueprints

push: _name
	$(INRUN) pull -f patterns/blueprints/$(NAME)/$(VERSION)/blueprint.yaml
	$(INRUN) push patterns/blueprints/$(NAME)/$(VERSION) $(force)

e2e: _name
	$(INRUN) e2e -f patterns/blueprints/$(NAME)/$(VERSION)/test/e2e.yaml

e2e-all:
	@failed=""; for f in $(BLUEPRINTS); do d=$$(dirname $$f); \
	  $(INRUN) e2e -f $$d/test/e2e.yaml || failed="$$failed $$d"; done; \
	  if [ -n "$$failed" ]; then echo "failed:$$failed"; exit 1; fi

_name:
	@test -n "$(NAME)" || { echo "NAME is required, e.g. make $(MAKECMDGOALS) NAME=postgres"; exit 1; }
