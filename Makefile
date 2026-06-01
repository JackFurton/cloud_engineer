ENV ?= dev
TF  := terraform
TF_DIR := infra/envs/$(ENV)

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

.PHONY: init
init: ## terraform init for the selected ENV (default: dev)
	cd $(TF_DIR) && $(TF) init -input=false

.PHONY: fmt
fmt: ## Format all Terraform files in place
	$(TF) fmt -recursive infra

.PHONY: validate
validate: ## Validate the selected ENV
	cd $(TF_DIR) && $(TF) validate

.PHONY: plan
plan: ## Show planned changes (needs real GCP creds)
	cd $(TF_DIR) && $(TF) plan

.PHONY: test
test: ## Run terraform test (needs TF >= 1.6 with provider mocks)
	cd $(TF_DIR) && $(TF) test

.PHONY: check
check: fmt validate ## Quick local gate: format + validate

.PHONY: up
up: ## Start local emulators (Pub/Sub, GCS, BigQuery)
	docker compose -f local/docker-compose.yml up -d

.PHONY: down
down: ## Stop local emulators
	docker compose -f local/docker-compose.yml down -v

PY := ./.venv/bin/python

.PHONY: venv
venv: ## Create the Python venv and install app deps
	python3 -m venv .venv && ./.venv/bin/pip install -q --upgrade pip -r app/requirements.txt

.PHONY: bootstrap
bootstrap: ## Create topic/subscription/bucket inside the running emulators
	cd app && ../$(PY) bootstrap.py

.PHONY: publish
publish: ## Publish N synthetic events (N=10 by default)
	cd app && ../$(PY) publisher.py $(N)

.PHONY: process
process: ## Drain the subscription -> GCS archive + BigQuery
	cd app && ../$(PY) processor.py

.PHONY: query
query: ## Run analytical SQL against the BigQuery events table
	cd app && ../$(PY) query.py

.PHONY: demo
demo: bootstrap publish process query ## Full local run: bootstrap -> publish -> process -> query
