---
title: Disaster recovery
version: 0.1
status: Draft
author: Rafael
last_review: 2026-08-14
related:
  - 06-recovery.md
---

# 07 — Disaster recovery

## Objetivo

Definir como reconstruir a workstation após perda total do sistema ou do disco, usando o repositório e backups disponíveis como fontes de recuperação.

## Pré-requisitos

- repositório acessível fora da workstation perdida;
- mídia/ambiente de instalação compatível disponível;
- estratégia de recuperação de credenciais definida sem armazená-las no Git;
- backups necessários à restauração de dados não reconstruíveis disponíveis.

## Procedimento

1. Preparar um ambiente novo ou disco substituto.
2. Obter o repositório por um caminho documentado.
3. Recuperar credenciais necessárias por mecanismo externo ao Git.
4. Reconstruir as fases da workstation na ordem declarada pelo profile e pelo runner.
5. Restaurar dados que não podem ser reconstruídos pelo repositório.
6. Executar os gates de validação aplicáveis após cada estágio relevante.
7. Registrar lacunas encontradas durante uma reconstrução real ou ensaio apropriado.

### Limite de validação

O projeto não realizará uma reinstalação destrutiva artificial na workstation atual. O procedimento deve ser testado em ambiente apropriado ou durante uma reconstrução real futura.

## Verificação

O documento deverá ser suficiente para que a reconstrução possa ser conduzida sem depender da memória do operador sobre caminhos internos dos scripts.

## Problemas comuns

### Dependência escondida na máquina perdida

Toda dependência indispensável à reconstrução deve ter um caminho externo documentado.

### Credenciais versionadas para facilitar recuperação

Não armazenar segredos no Git; documentar como recuperá-los de fonte segura externa.

### Ordem manual divergente do profile

Usar o runner e os manifests como fonte da ordem de reconstrução, evitando uma segunda sequência mantida manualmente.

## Próximo playbook

`08-operations-validation.md`

## Referências

- `06-recovery.md`
- `docs/architecture.md`
- `docs/roadmap.md`
- `docs/standards.md`

## Lições aprendidas

- Disaster recovery deve minimizar conhecimento implícito; cada dependência que existe apenas na memória do operador é uma lacuna de recuperação.
