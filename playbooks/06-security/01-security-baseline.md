---
title: Security baseline
version: 0.1
status: Draft
author: Rafael
last_review: 2026-08-18
related:
  - ../../docs/roadmap.md
  - ../../docs/standards.md
---

# 01 — Security baseline

## Objetivo

Registrar a postura de segurança atual da workstation antes de aplicar hardening, sem modificar o host.

O baseline existe para separar fatos observados de controles planejados e evitar mudanças de segurança que prejudiquem recuperabilidade sem benefício demonstrado.

## Escopo

O baseline inspeciona:

- LUKS2 e estado do volume raiz;
- Secure Boot;
- configuração efetiva do OpenSSH;
- sudo e permissões relevantes;
- listeners de rede;
- serviços systemd habilitados;
- política básica de firewall;
- configuração declarada de TPM2;
- sinais óbvios de segredos versionados no repositório.

A inspeção de segredos é defensiva e limitada a padrões de arquivos e configuração; o script não imprime valores de segredos encontrados.

## Política de resultado

- `PASS`: controle esperado já está presente ou estado seguro foi comprovado;
- `INFO`: fato inventariado que não representa, por si só, falha;
- `WARN`: condição que merece decisão ou hardening posterior;
- `FAIL`: baseline não pôde comprovar um requisito estrutural já assumido pelo profile.

Secure Boot e TPM2 atualmente desabilitados são inventário/planejamento, não falha automática do baseline.

## Procedimento

1. Executar o script de baseline como root.
2. Revisar todos os listeners e serviços expostos reportados.
3. Confirmar que LUKS2 protege o volume raiz conforme o profile.
4. Confirmar que SSH efetivo não permite login root nem autenticação por senha.
5. Registrar o estado de Secure Boot e TPM2 sem alterá-los.
6. Revisar qualquer alerta de possível segredo versionado antes de prosseguir.
7. Usar os resultados para orientar os próximos playbooks da fase.

## Segurança

Este step é somente leitura.

Ele não deve:

- alterar `sshd_config`;
- ativar/desativar firewall;
- modificar slots LUKS;
- matricular chaves Secure Boot;
- registrar TPM2;
- apagar arquivos suspeitos;
- imprimir conteúdo de credenciais.

## Verificação

O baseline está correto quando produz um inventário reproduzível, retorna código diferente de zero apenas para falhas estruturais e não modifica estado da workstation.

## Próximo playbook

`02-secrets-management.md`

## Referências

- `docs/roadmap.md`
- `docs/standards.md`
- `profiles/dell-latitude-e5470/profile.yaml`
