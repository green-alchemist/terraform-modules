## 
SHELL = /bin/zsh
ALL_MODULES := $(shell for module in $(sort $(wildcard ./modules/three-tier-deployment/**/main.tf)); do echo $$module | cut -d/ -f3 | tr "\n" " "; done)

PWD := $(shell pwd | rev |  cut -d/ -f1 | rev)

reverse = $(2) $(1)

rev_str = $(1) | rev 

foo = $(call reverse,a,b)
bar = $(call rev_str,baby)

REVERSE := $(shell echo reverse pwd)

# TF_PATH2 = "./terraform/dev/us-east-1/t2.micro/three-tier-deployment"
TF_PATH = "./simple"



init:
	@echo "Running terraform init"; \
	terraform -chdir=${TF_PATH} init

.PHONY: init

plan:
	@echo "Running terraform plan"; \
	terraform -chdir=${TF_PATH} plan

.PHONY: plan

validate:
	@echo "Running terraform validate"; \
	terraform -chdir=${TF_PATH} validate

.PHONY: validate

apply:
	@echo "Running terraform apply"; \
	terraform -chdir=${TF_PATH} apply

.PHONY: apply

destroy:
	@echo "Running terraform destroy"; \
	terraform -chdir=${TF_PATH} destroy

.PHONY: destroy

clean:
	@echo "Cleaning terraform files"; \
	find ./terraform/dev/us-east-1/t2.micro/three-tier-deployment -name .terraform | xargs rm -rf

.PHONY: clean

test: ## testing makefile things
	@echo ${ALL_MODULES}
	@echo $(shell for folder in $(wildcard ./modules/**); do echo $$folder; list; done )
	@echo $(wildcard ./modules/**/**)


.PHONY: test


.PHONY: here
here: ## more testing
	@echo $(wildcard ../**)
	@echo ${foo}
	@echo $(shell aws s3 ls)

rev:
	@echo $(call rev_str,kyleconley)
	@set -e; \
	aws s3 ls;
.PHONY: rev






help: ## show this usage
	@echo "\033[36mKyle Conley Terraform Makefile:\033[0m\nUsage: make [target]\n"; \
	grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help
.DEFAULT_GOAL := help