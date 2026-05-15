# CGE-P Capstone — Acme Health Patient Intake API

AWS_PROFILE ?= default
AWS_REGION  ?= us-east-1

.PHONY: deploy test destroy opa-test conftest-check fmt-check validate policy-test all

deploy:
	cd terraform && terraform init && terraform apply -auto-approve

test:
	curl -s -X POST $$(cd terraform && terraform output -raw api_url) \
	  -H 'Content-Type: application/json' \
	  -d '{"name":"Test Patient","dob":"1990-01-01","complaint":"Headache"}' | jq .

destroy:
	cd terraform && terraform destroy -auto-approve

# CGE-P Compliance checks
opa-test:
	opa test -v policies/

conftest-check:
	conftest test --policy policies --namespace compliance.cmmc.sc1311 policies/fixtures/compliant.json
	conftest test --policy policies --namespace compliance.cmmc.sc138 policies/fixtures/compliant.json
	conftest test --policy policies --namespace compliance.cmmc.mp389 policies/fixtures/compliant.json
	conftest test --policy policies --namespace compliance.cmmc.ac315 policies/fixtures/compliant.json
	conftest test --policy policies --namespace compliance.cmmc.au331 policies/fixtures/compliant.json

fmt-check:
	terraform -chdir=terraform fmt -check

validate:
	terraform -chdir=terraform validate

policy-test: opa-test conftest-check

all: fmt-check validate opa-test conftest-check