---
title: Hardware token
version: 0.1
status: Deferred
author: Rafael
last_review: 2026-08-19
related:
  - 06-tpm2.md
---

# 07 — Hardware token

## Objetivo

Registrar o uso opcional de token físico sem tornar a fase Security dependente de hardware que ainda não está disponível.

## Estado atual

**Deferred / optional hardware.**

Nenhum token físico está disponível nesta geração para enrollment ou teste operacional.

## Regra

A ausência de hardware token não é falha de segurança nem bloqueia a validação da fase. Este controle só será promovido quando existir hardware concreto e um caso de uso definido, por exemplo FIDO2 para autenticação ou recuperação.

## Restrições

- não criar configuração fictícia para satisfazer checklist;
- não substituir as credenciais LUKS de recuperação existentes por dependência exclusiva de token;
- não versionar material secreto associado ao token;
- qualquer enrollment futuro deve possuir procedimento de perda/roubo do dispositivo.

## Próximo playbook

`08-security-validation.md`
