# ADR-0013 — Persistent Runner State and Safe Resume

- Status: Accepted
- Date: 2026-08-14

## Context

The manifest-driven workstation runner can execute a complete phase and explicitly resume from a selected step with `--from`. This is safe, but it still requires the operator to remember which step failed or was interrupted.

Repository Automation needs a minimal persistent execution state so an interrupted reconstruction can be resumed without reconstructing progress from terminal history. That state must not become configuration, must not be committed to Git, and must never contain credentials or answers to interactive confirmations.

## Decision

Persist runner execution state outside the repository under the XDG state hierarchy.

The default location is:

```text
${XDG_STATE_HOME:-$HOME/.local/state}/linux-workstation/
```

State is scoped by profile. Each profile may have one active phase execution record.

The record contains only operational metadata required for safe recovery, such as:

```text
profile=dell-latitude-e5470
phase=04-development
last_completed_step=05-cli-tools
next_step=06-ai-tooling
status=interrupted
```

The runner MUST follow these rules:

1. A step is recorded as completed only after its entrypoint returns exit code `0`.
2. The next step is derived from the phase manifest order, never guessed from directory names.
3. Passwords, tokens, confirmation answers, environment secrets and command output are never persisted.
4. Manual steps are never marked complete automatically.
5. A failed or interrupted phase keeps enough state to resume from the first uncompleted step.
6. A successfully completed phase clears its active execution record.
7. `--from` remains available as an explicit operator override and takes precedence over persisted resume state.
8. Resume refuses state whose profile, phase or step no longer exists in the current manifests.
9. State files are runtime artifacts and MUST NOT be stored in the Git repository.

## Interface

The high-level runner will expose:

```bash
./scripts/workstation execution-status
./scripts/workstation resume
./scripts/workstation clear-state
```

Equivalent Make targets may wrap these commands.

`resume` must display the recovered profile, phase and next step before execution. It must preserve the existing safety model: individual step confirmations remain interactive and destructive confirmations are never automated.

## Consequences

### Positive

- Interrupted installations can continue without remembering `--from` manually.
- State remains local to the machine and separate from declarative repository sources.
- Successful-step boundaries are explicit and auditable.
- Existing step-level confirmation behavior remains unchanged.

### Negative

- The runner gains mutable local state that must be validated carefully.
- Manifest changes can invalidate old state and therefore require defensive checks.
- A state file describes execution progress, not proof that external/manual validation remains true forever.

## Rejected alternatives

### Store state in the repository

Rejected because runtime progress is machine-specific mutable data and would pollute Git history and working trees.

### Infer progress from installed packages or runtime checks

Rejected because not every step maps cleanly to one observable package or service, and inference could incorrectly skip required configuration.

### Automatically replay the failed step without showing the recovered state

Rejected because recovery must remain transparent and supervised.

## Validation

The implementation must include static tests proving that:

- state defaults to the XDG state hierarchy;
- completed steps are persisted only after success;
- invalid or stale state is rejected;
- resume resolves the first uncompleted manifest step;
- explicit `--from` remains usable;
- successful phase completion removes active state;
- no state file is created inside the repository.
