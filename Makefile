PROFILE ?= dell-latitude-e5470
PHASE ?=
STEP ?=
FROM ?=

.PHONY: help bootstrap status execution-status clear-state resume resume-plan phases steps run-step run-phase plan-phase validate-automation

help:
	@printf '%s\n' \
	  'Linux Workstation repository commands' \
	  '' \
	  '  make bootstrap' \
	  '      Detect the selected profile, summarize state and show the next safe action.' \
	  '  make status' \
	  '      Show phase lifecycle status and the next planned phase.' \
	  '  make execution-status' \
	  '      Show persisted execution progress for the selected profile.' \
	  '  make resume-plan' \
	  '      Show the recovered resume plan without executing it.' \
	  '  make resume' \
	  '      Resume from the first uncompleted persisted step.' \
	  '  make clear-state' \
	  '      Remove persisted execution progress for the selected profile.' \
	  '  make phases' \
	  '      List phases declared by the selected profile.' \
	  '  make steps PHASE=04-development' \
	  '      List steps declared by a phase.' \
	  '  make run-step PHASE=04-development STEP=07-development-validation' \
	  '      Execute one explicit step through the repository runner.' \
	  '  make plan-phase PHASE=04-development [FROM=05-cli-tools]' \
	  '      Show the supervised execution plan without running steps.' \
	  '  make run-phase PHASE=04-development [FROM=05-cli-tools]' \
	  '      Execute a phase in manifest order, preserving step confirmations.' \
	  '  make validate-automation' \
	  '      Validate the runner and manifest parser.'

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
validate-automation:
	@bash tests/automation/runner-static.sh
