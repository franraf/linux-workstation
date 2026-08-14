# ADR-0014 — Chezmoi-managed User Configuration

- Status: Accepted
- Date: 2026-08-14

## Context

The workstation already stores canonical user configuration under `dotfiles/`, but individual setup scripts still copy those files directly into the target user's home directory. This works, but duplicates application logic and leaves no common mechanism for previewing, diffing and converging user configuration.

Milestone 5 explicitly calls for operational adoption of `chezmoi`.

## Decision

Adopt `chezmoi` as the application and convergence mechanism for user-owned configuration that belongs to the workstation.

The repository itself remains the canonical source. `chezmoi` MUST NOT create or require a second independent dotfiles repository.

The repository root is used as the chezmoi source directory and a root `.chezmoiroot` file points to:

```text
dotfiles/home
```

Files under `dotfiles/home/` therefore use chezmoi source-state naming and map directly into the target user's home directory.

For example:

```text
dotfiles/home/private_dot_config/private_Code/User/settings.json
    -> ~/.config/Code/User/settings.json
```

## Scope

Initial operational scope is intentionally small:

- Visual Studio Code `settings.json`;
- Visual Studio Code `keybindings.json`.

Other workstation-owned user configuration may migrate to the same mechanism incrementally after validation. Package installation, system configuration, application installation, secrets, generated credentials and project-specific state remain outside chezmoi.

VS Code extension declarations remain in `dotfiles/vscode/extensions.txt` because extensions are managed application state rather than home-file content.

## Execution model

Setup scripts invoke chezmoi explicitly with the repository as source:

```bash
chezmoi -S <repo-root> apply <target...>
```

Before applying, scripts may use `chezmoi diff` or `chezmoi status` for diagnostics. Interactive workstation safety rules remain in force; chezmoi does not bypass step-level authorization.

The normal editing workflow is repository-first: edit the source file in this repository, review the diff, then apply it. Changes made directly in `$HOME` are not canonical until intentionally reconciled back into the repository.

## Consequences

### Positive

- user configuration gains one convergence mechanism;
- application becomes idempotent by design;
- source and destination differences can be inspected with chezmoi;
- the repository remains the single source of truth;
- future user dotfiles can migrate incrementally.

### Negative

- source-state filenames are less immediately intuitive than direct destination paths;
- scripts that previously copied files directly must be migrated;
- chezmoi becomes a host dependency for steps that apply managed dotfiles.

## Rejected alternatives

### Separate dotfiles repository

Rejected because it would split the workstation definition across repositories and create competing sources of truth.

### Keep direct copies and install chezmoi only as an optional CLI

Rejected because that would not constitute operational adoption and would retain duplicate application behavior.

### Manage all user configuration immediately

Rejected because a staged migration is easier to validate and reduces regression risk.

## Validation

The implementation must verify that:

- `.chezmoiroot` resolves the repository source state to `dotfiles/home`;
- `chezmoi` is installed before the first managed configuration is applied;
- managed VS Code files match the target state after application;
- a second apply produces no content change;
- runtime validation confirms both the `chezmoi` command and managed files;
- existing development and automation gates remain green.
