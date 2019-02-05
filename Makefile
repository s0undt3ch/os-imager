# Minimal makefile for running packer lint

OS  =
OS_REV  =
SALT_BRANCH = develop
PACKERDIR  = AWS
REGION  = us-west-2
TEMPLATE = $(PACKERDIR)/$(OS)/$(OS).json
VAR_FILE = $(PACKERDIR)/$(OS)/$(OS)-$(OS_REV)-$(REGION).json

.PHONY: help
help:
	@echo ''
	@echo '  Targets:'
	@echo '    build, validate'
	@echo ''
	@echo '  Usage:'
	@echo '    make <target> OS=<SOME OS> OS_REV=<SOME OS REVISION>'


ifeq ($(shell test -f  $(PACKERDIR)/$(OS)/$(OS)-$(OS_REV).json && echo 1 || echo 0), 1)
	TEMPLATE = $(PACKERDIR)/$(OS)/$(OS)-$(OS_REV).json
endif

.PHONY: validate
validate:
	$(info OS=$(OS))
	$(info OS_REV=$(OS_REV))
	$(info SALT_BRANCH=$(SALT_BRANCH))
	$(info TEMPLATE=$(TEMPLATE))
	$(info VAR_FILE=$(VAR_FILE))
	@mkdir -p .tmp/states .tmp/pillar
	@packer validate -var 'salt_branch=$(SALT_BRANCH)' -var-file=$(VAR_FILE) $(TEMPLATE)

.PHONY: build
build:
	$(info OS=$(OS))
	$(info OS_REV=$(OS_REV))
	$(info SALT_BRANCH=$(SALT_BRANCH))
	$(info TEMPLATE=$(TEMPLATE))
	$(info VAR_FILE=$(VAR_FILE))
	@mkdir -p .tmp/states .tmp/pillar
	@packer build -var 'salt_branch=$(SALT_BRANCH)' -var-file=$(VAR_FILE) $(TEMPLATE)
