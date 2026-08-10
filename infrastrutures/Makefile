SHELL := /bin/bash
LIVE := terraform/live/test

.PHONY: init fmt validate plan apply output destroy
init:
	./scripts/tf.sh init $(UNIT)
fmt:
	terraform fmt -recursive terraform
validate:
	./scripts/tf.sh validate $(UNIT)
plan:
	./scripts/tf.sh plan $(UNIT)
apply:
	./scripts/tf.sh apply $(UNIT)
output:
	./scripts/tf.sh output $(UNIT)
destroy:
	./scripts/tf.sh destroy $(UNIT)

.PHONY: agent-plan agent-execute
agent-plan:
	./scripts/agent-task.sh $(UNIT) plan
agent-execute:
	./scripts/agent-task.sh $(UNIT) execute

.PHONY: bootstrap-backend backend-status
bootstrap-backend:
	./scripts/bootstrap-backend.sh

backend-status:
	@. ./config/accounts.env && \
	aws s3api head-bucket --bucket "$$TF_STATE_BUCKET" --profile "$$CORE_PROFILE" && \
	aws dynamodb describe-table --table-name "$$TF_LOCK_TABLE" --region "$$AWS_REGION" --profile "$$CORE_PROFILE" --query 'Table.[TableName,TableStatus]' --output table
