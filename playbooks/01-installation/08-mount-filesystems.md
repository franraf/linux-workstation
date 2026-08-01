---

title: Montar os sistemas de arquivos
version: 1.0
status: Draft
author: Rafael
last_review: 2026-07-31
related:

* architecture.md
* ADR-0002
* ADR-0003
* ADR-0004

---

# 07 — Montar os sistemas de arquivos

## Objetivo

Montar o sistema de arquivos utilizando a estrutura de subvolumes definida pela arquitetura do projeto.

Ao final deste playbook, o ambiente estará preparado para a instalação do sistema base.

---

# Pré-requisitos

* Volume LUKS2 aberto.
* Sistema de arquivos Btrfs criado.
* Todos os subvolumes criados.

---

# Resultado esperado

Ao concluir este playbook:

* o subvolume raiz estará montado em `/mnt`;
* os demais subvolumes estarão montados em seus respectivos pontos de montagem;
* a partição EFI estará montada no local definido pela arquitetura.

---

# Procedimento

## 1. Montar o subvolume raiz

Monte o subvolume `@` em `/mnt`.

Utilize as opções de montagem definidas pela arquitetura do projeto.

---

## 2. Criar os pontos de montagem

Crie todos os diretórios necessários para os demais subvolumes.

Os diretórios deverão refletir a estrutura final do sistema.

---

## 3. Montar os demais subvolumes

Monte os subvolumes nos respectivos pontos de montagem:

| Subvolume    | Ponto de montagem           |
| ------------ | --------------------------- |
| `@home`      | `/mnt/home`                 |
| `@var`       | `/mnt/var`                  |
| `@var_log`   | `/mnt/var/log`              |
| `@var_cache` | `/mnt/var/cache`            |
| `@pkg`       | `/mnt/var/cache/pacman/pkg` |
| `@docker`    | `/mnt/var/lib/docker`       |
| `@snapshots` | `/mnt/.snapshots`           |

---

## 4. Montar a partição EFI

Monte a EFI System Partition no diretório definido pela arquitetura.

---

## 5. Revisar a estrutura montada

Confirme que todos os pontos de montagem estão ativos antes de iniciar a instalação do sistema.

---

# Verificação

Confirme que:

* todos os subvolumes estão montados;
* cada subvolume está montado no diretório correto;
* a partição EFI está acessível;
* a árvore de diretórios corresponde à arquitetura do projeto.

---

# Problemas comuns

## Subvolume não encontrado

Verifique se o subvolume foi criado no playbook anterior.

---

## Ponto de montagem inexistente

Crie o diretório correspondente antes da montagem.

---

## Partição EFI montada incorretamente

Confirme se a ESP foi selecionada corretamente e se está montada no ponto previsto pela arquitetura.

---

# Próximo playbook

Após validar todas as montagens, prossiga para:

```text
09-install-base-system.md
```

---

# Referências

* Arch Wiki — Btrfs
* Arch Wiki — Installation Guide
* Arch Wiki — EFI System Partition

---

# Lições aprendidas

Registrar ajustes nas opções de montagem, alterações na estrutura de subvolumes ou incompatibilidades observadas durante futuras instalações.
