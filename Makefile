PROFILE ?= dell-latitude-e5470
PHASE ?=
STEP ?=
FROM ?=

.PHONY: help bootstrap status execution-status clear-state resume resume-plan phases steps run-step run-phase plan-phase validate-automation validate-resume

help:
	@printf '%s\n' \
	  'Linux Workstation repository commands' \
	  '' \
	  '  make bootstrap' \
	  '  make status' \
	  '  make execution-status' \
	  '  make resume-plan' \
	  '  make resume' \
	  '  make clear-state' \
	  '  make phases' \
	  '  make steps PHASE=04-development' \
	  '  make run-step PHASE=04-development STEP=07-development-validation' \
	  '  make plan-phase PHASE=04-development [FROM=05-cli-tools]' \
	  '  make run-phase PHASE=04-development [FROM=05-cli-tools]' \
	  '  make validate-resume' \
	  '  make validate-automation'

bootstrap:
	@./scripts/workstation bootstrap --profile "$(PROFILE)"
status:
	@./scripts/workstation status --profile "$(PROFILE)"
execution-status:
	@./scripts/workstation execution-status --profile "$(PROFILE)"
clear-state:
	@./scripts/workstation clear-state --profile "$(PROFILE)"
resume-plan:
	@./scripts/workstation resume --plan --profile "$(PROFILE)"
resume:
	@./scripts/workstation resume --profile "$(PROFILE)"
phases:
	@./scripts/workstation phases --profile "$(PROFILE)"
steps:
	@test -n "$(PHASE)" || { echo 'PHASE is required.' >&2; exit 1; }
	@./scripts/workstation steps "$(PHASE)" --profile "$(PROFILE)"
run-step:
	@test -n "$(PHASE)" || { echo 'PHASE is required.' >&2; exit 1; }
	@test -n "$(STEP)" || { echo 'STEP is required.' >&2; exit 1; }
	@./scripts/workstation run-step "$(PHASE)" "$(STEP)" --profile "$(PROFILE)"
plan-phase:
	@test -n "$(PHASE)" || { echo 'PHASE is required.' >&2; exit 1; }
	@./scripts/workstation run-phase "$(PHASE)" --plan $(if $(FROM),--from "$(FROM)",) --profile "$(PROFILE)"
run-phase:
	@test -n "$(PHASE)" || { echo 'PHASE is required.' >&2; exit 1; }
	@./scripts/workstation run-phase "$(PHASE)" $(if $(FROM),--from "$(FROM)",) --profile "$(PROFILE)"
validate-resume:
	@bash tests/automation/resume-integration.sh
validate-automation:
	@bash tests/automation/runner-static.sh
	@bash tests/automation/resume-integration.sh
