## Base Makefile for working with Terraform locally for help type `make help`
OVERRIDE_MODULES ?= $(shell git show --oneline ${CIRCLE_SHA1} | head -1 | grep "\#modules" | sed -E 's/^.*\#modules(.*)\#modules.*/\1/g')

MODULES := $(shell git show --name-only --oneline ${CIRCLE_SHA1} | awk -F"/" '/^AWS\/modules\// {print $$3}' | grep -v README | sort -u)
ALL_MODULES := $(shell for module in $(sort $(wildcard ./AWS/modules/**/main.tf)); do echo $$module | cut -d/ -f4 | tr "\n" " "; done)
TF_PATH = "./AWS/modules"

AWS_ACCESS = "./AWS/example/access/"

### ---------------------------------- ### 

modules: ## display what modules will be applied to
	@echo ${MODULES}

.PHONY: modules

all-modules: ## generates a list of all modules
	@echo ${ALL_MODULES}

.PHONY: all-modules

### ---------------------------------- ### 

ssh: ## generate ssh keypair usage `make ssh NAME=testKey`
	@echo "Generating new ssh key path = $(AWS_ACCESS)"; \
	ssh-keygen -f $(AWS_ACCESS)$(NAME) -t ed25519; \
	chmod 600 $(AWS_ACCESS)$(NAME).*

.PHONY: ssh


clean: ## Remove Terraform build files
	@echo "Cleaning terraform files"; \
	find . -name .terraform | xargs rm -rf; \

.PHONY: clean


fmt: clean ## run terraform fmt to see diffs in formatting
	@echo "Running Terraform format to check code for formatting issues"; \
	for module in ${MODULES}; do \
		terraform -chdir=./AWS/modules/$$module fmt -check=true -write=false -diff=true; \
	done; \
	echo "Done running Terraform format"

.PHONY: fmt

fmt-write: clean ## run terraform fmt write to correct any basic formatting issues
	@echo "Running Terraform format write to correct any basic formatting issues"; \
	for module in ${MODULES}; do \
		terraform -chdir=./AWS/modules/$$module fmt -write=true; \
	done; \
	echo "Done running Terraform format with write"

.PHONY: fmt-write


help: ## show this usage
	@echo "\033[36mKC Terraform Makefile:\033[0m\nUsage: make [target]\n"; \
	grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help
.DEFAULT_GOAL := help