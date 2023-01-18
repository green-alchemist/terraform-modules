## Base Makefile for working with Terraform locally for help type `make help`
OVERRIDE_MODULES ?= $(shell git show --oneline ${CIRCLE_SHA1} | head -1 | grep "\#modules" | sed -E 's/^.*\#modules(.*)\#modules.*/\1/g')

MODULES := $(shell git show --name-only --oneline ${CIRCLE_SHA1} | awk -F"/" '/^AWS\/modules\// {print $$3}' | grep -v README | sort -u)
ALL_MODULES := $(shell for service in $(sort $(wildcard ./AWS/modules/**/main.tf)); do echo $$service | cut -d/ -f4 | tr "\n" " "; done)


# ifneq "${OVERRIDE_MODULES}" ""
# 	override MODULES := ${OVERRIDE_MODULES}
# endif

AWS_ACCESS = "./AWS/simple/access/"

### ---------------------------------- ### 

modules: ## display what services will be applied to
	@echo ${MODULES}

.PHONY: modules

all-modules: ## generates a list of all services
	@echo ${ALL_MODULES}

.PHONY: all-modules

### ---------------------------------- ### 

ssh: ## generate ssh keypair usage `make ssh NAME=testKey`
	@echo "Generating new ssh key path = $(AWS_ACCESS)"; \
	ssh-keygen -f $(AWS_ACCESS)$(NAME) -t ed25519; \
	chmod 600 $(AWS_ACCESS)$(NAME).*

.PHONY: ssh

# sshtest: ## generate ssh keypair separates each pair in individual folder usage `make ssh NAME=testKey`
# 	@echo "Generating new ssh key path = $(AWS_ACCESS) flags = $(SSHFLAGS)"; \
# 	mkdir $(AWS_ACCESS)$(NAME); \
# 	ssh-keygen -f $(AWS_ACCESS)$(NAME)/$(NAME) -t ed25519

# .PHONY: sshtest

clean: ## Remove Terraform build files
	@echo "Cleaning terraform files"; \
	find . -name .terraform | xargs rm -rf; \

.PHONY: clean

init: ## Terraform Init
	@echo "Running terraform init"; \
	terraform -chdir=${TF_PATH} init

.PHONY: init

plan: ## Terraform Plan
	@echo "Running terraform plan"; \
	terraform -chdir=${TF_PATH} plan | tfmask

.PHONY: plan

fmt: clean ## run terraform fmt to see diffs in formatting
	@echo "Running Terraform format to check code for formatting issues"; \
	for service in ${MODULES}; do \
		terraform -chdir=./services/$$service fmt -check=true -write=false -diff=true; \
	done; \
	echo "Done running Terraform format"

.PHONY: fmt

fmt-write: clean ## run terraform fmt write to correct any basic formatting issues
	@echo "Running Terraform format write to correct any basic formatting issues"; \
	for service in ${MODULES}; do \
		terraform -chdir=./services/$$service fmt -write=true; \
	done; \
	echo "Done running Terraform format with write"

.PHONY: fmt-write


help: ## show this usage
	@echo "\033[36mKC Terraform Makefile:\033[0m\nUsage: make [target]\n"; \
	grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help
.DEFAULT_GOAL := help