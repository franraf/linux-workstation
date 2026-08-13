# ADR-0011 — Allow upstream distribution for selected host tools

## Status

Accepted

## Context

The workstation policy prefers software distributed through the official Arch Linux repositories and keeps the AUR disabled by default. This improves predictability, reduces third-party packaging dependencies and keeps package ownership clear.

Some host tools, however, may not provide their official vendor build through the Arch Linux repositories. Visual Studio Code is the first concrete case: the repository package `code` is Code - OSS, while the workstation architecture explicitly requires the Microsoft Visual Studio Code build for its expected extension ecosystem and Dev Containers workflow.

Enabling the AUR globally only to obtain such software would weaken the package-source policy for the entire workstation.

## Decision

Allow narrowly scoped exceptions in which a host tool may be installed directly from the software vendor's official upstream distribution when all of the following conditions are true:

1. the required official vendor build is not available from the official Arch Linux repositories;
2. the repository alternative is not functionally equivalent to the implementation selected by the workstation architecture;
3. enabling the AUR would be broader than necessary for the requirement;
4. the upstream source is controlled by the software vendor;
5. installation, update and validation behavior is explicitly implemented and versioned by this repository;
6. the exception is documented in an ADR or in an ADR-backed capability policy.

AUR remains disabled by default and is not implicitly enabled by this exception.

## Application to Visual Studio Code

Visual Studio Code will use the official Microsoft Linux distribution rather than the Arch `code` package or the AUR `visual-studio-code-bin` package.

The workstation automation is responsible for:

- downloading only from the official Microsoft distribution endpoint;
- installing the application into a system-owned location;
- exposing a stable `code` command and desktop launcher;
- keeping user configuration separate from application binaries;
- validating the installed application;
- making upgrades explicit and reproducible.

## Consequences

### Positive

- preserves the selected Microsoft Visual Studio Code implementation;
- keeps AUR disabled;
- avoids silently substituting Code - OSS for Visual Studio Code;
- keeps exceptions narrow and reviewable;
- maintains the repository as the source of installation behavior.

### Negative

- Pacman does not own the upstream-installed application files;
- upgrade logic must be maintained by this project;
- package dependency and uninstall behavior require explicit automation;
- vendor endpoint changes can require maintenance.

## Rejected alternatives

### Use Arch package `code`

Rejected because it provides Code - OSS rather than the Microsoft Visual Studio Code build selected by the workstation architecture.

### Enable the AUR and install `visual-studio-code-bin`

Rejected because enabling the AUR globally is a broader policy change than required for this single host tool.

### Remove Visual Studio Code from the workstation architecture

Rejected because Visual Studio Code and Dev Containers are intentional parts of the host development workflow.

## Scope

This ADR does not grant a general exemption for arbitrary third-party installers. Each upstream-distributed host tool must satisfy the criteria above and remain explicitly represented in repository automation.

## Date

2026-08-13
