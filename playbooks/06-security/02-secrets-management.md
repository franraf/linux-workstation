---
title: Gestão de segredos
version: 1.0
status: Stable
author: Rafael
last_review: 2026-08-19
related:
  - 01-security-baseline.md
---

# 02 — Gestão de segredos

## Objetivo

Definir a política de segredos da workstation sem introduzir um gerenciador adicional quando não existe caso de uso que justifique sua complexidade.

## Política

- segredos e chaves privadas nunca são versionados no Git;
- o repositório contém somente configuração declarativa e referências ao mecanismo de obtenção de credenciais;
- autenticações interativas permanecem fora do repositório;
- chaves privadas do Secure Boot permanecem em `/var/lib/sbctl/keys` e não são copiadas para o Git;
- backup do header LUKS e material de recuperação permanecem fora do Git;
- credenciais de backup, quando o step de backup for ativado, também permanecem fora do Git e fora do próprio repositório de backup;
- arquivos com conteúdo sensível devem possuir permissões restritivas compatíveis com seu uso.

## Validação realizada

O baseline de segurança confirmou que não existem nomes óbvios de arquivos portadores de segredo rastreados pelo Git. A política do profile também declara `secrets_in_repository: false`.

Não foi identificado caso de uso atual que exija Vault, pass, SOPS ou outra camada permanente de gerenciamento de segredos nesta geração.

## Critério de evolução

Um gerenciador dedicado só deve ser promovido quando existir pelo menos um caso de uso concreto que não seja adequadamente resolvido por armazenamento local protegido, autenticação interativa ou mecanismo nativo da ferramenta.

## Verificação

```bash
git ls-files | grep -Ei '(^|/)(\.env($|\.)|id_(rsa|dsa|ecdsa|ed25519)$|.*\.(pem|p12|pfx|key)$)' || true
```

Resultado esperado: nenhuma chave privada ou arquivo de segredo rastreado.

## Próximo playbook

`03-ssh-hardening.md`
