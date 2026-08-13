---
title: Validar o sistema
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-12
related:

* architecture.md
* ADR-0002
* ADR-0004

---

# 12 — Validar o sistema

## Objetivo

Validar que a configuração da fase `02-system` foi aplicada corretamente e que a workstation está pronta para receber a camada gráfica.

Este playbook é um gate de fase e não deve corrigir automaticamente as capacidades verificadas.

---

# Pré-requisitos

* Todos os playbooks anteriores de `02-system` concluídos.
* Sistema inicializado normalmente.
* Usuário administrativo disponível.

---

# Resultado esperado

Ao concluir este playbook:

* a linha de base do sistema estará validada;
* não existirão falhas críticas conhecidas;
* a workstation estará pronta para `03-desktop`.

---

# Procedimento

## 1. Validar o estado do sistema

Confirme que o sistema inicializa normalmente e permanece estável.

## 2. Validar gerenciamento de pacotes

Confirme que o Pacman está funcional e sem inconsistências conhecidas.

## 3. Validar componentes fundamentais

Verifique microcode, sincronização de horário, journald, zram e política de TRIM.

## 4. Validar serviços

Confirme que os serviços previstos pela fase estão ativos e que `systemctl --failed` não apresenta falhas críticas não tratadas.

## 5. Validar acesso administrativo

Confirme acesso local e remoto conforme a política do projeto.

## 6. Revisar registros

Analise os registros em busca de erros críticos ou recorrentes.

## 7. Registrar o estado

Documente limitações e warnings aceitos antes de avançar.

---

# Verificação

Confirme que:

* o sistema inicia sem erros críticos;
* todos os playbooks da fase foram aplicados;
* os serviços essenciais estão operacionais;
* o acesso administrativo funciona;
* não existem pendências que impeçam `03-desktop`.

---

# Problemas comuns

## Serviço em falha

Retorne ao playbook responsável, corrija a fonte versionada e repita a validação.

## Configuração divergente

Compare o estado atual com a documentação e os arquivos versionados antes de realizar alterações locais.

---

# Próximo playbook

```text
03-desktop/
01-install-graphics-stack.md
```

---

# Referências

* architecture.md
* Playbooks da fase `02-system`
* Arch Wiki — General recommendations

---

# Lições aprendidas

As transições entre fases devem apontar para arquivos realmente existentes no repositório; referências planejadas ou antigas comprometem a documentação como fonte da verdade.
