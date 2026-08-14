PROFILE ?= dell-latitude-e5470
PHASE ?=
STEP ?=

.PHONY: help phases steps run-step validate-automation

help:
	@printf '%s\n' \
	  'Linux Workstation repository commands' \
	  '' \
	  '  make phases' \
	  '      List phases declared by the selected profile.' \
	  '' \
	  '  make steps PHASE=04-development' \
	  '      List steps declared by a phase.' \
	  '' \
	  '  make run-step PHASE=04-development STEP=07-development-validation' \
	  '      Execute one explicit step through the repository runner.' \
	  '' \
	  '  make validate-automation' \
	  '      Validate the runner and manifest parser.' \
	  '' \
	  'Optional: PROFILE=<profile-id> (default: dell-latitude-e5470)'

phases:
	@./scripts/workstation phases --profile "$(PROFILE)"

steps:
	@test -n "$(PHASE)" || { echo 'PHASE is required.' >&2; exit 1; }
	@./scripts/workstation steps "$(PHASE)" --profile "$(PROFILE)"

run-step:
	@test -n "$(PHASE)" || { echo 'PHASE is required.' >&2; exit 1; }
	@test -n "$(STEP)" || { echo 'STEP is required.' >&2; exit 1; }
	@./scripts/workstation run-step "$(PHASE)" "$(STEP)" --profile "$(PROFILE)"

validate-automation:
	@bash tests/automation/runner-static.sh
