# AI tooling

The workstation adopts Codex CLI as the single global coding-agent tool.

## Purpose

Codex CLI is intended for repository analysis, code changes, review, tests and documentation assistance from the terminal.

Project-specific instructions belong to each project repository. This directory contains only workstation-wide, non-sensitive guidance.

## Authentication

Authenticate interactively from the normal user session:

```bash
codex login
```

Do not store access tokens, API keys or generated credentials in this repository.

## Security rules

- Review generated diffs before accepting changes.
- Keep destructive commands subject to explicit user authorization.
- Do not expose SSH keys or unrelated credentials to tools.
- Run repository-specific tests after modifications.
- Prefer the smallest filesystem and repository scope required for the task.
