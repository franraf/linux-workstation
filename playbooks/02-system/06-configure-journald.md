---

title: Configurar o journald
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

# 06 — Configurar o journald

## Objetivo

Configurar o serviço de registro de eventos do sistema (`systemd-journald`) conforme os padrões definidos pelo projeto.

Ao final deste playbook, a workstation armazenará registros do sistema de forma consistente, previsível e adequada às necessidades de operação e diagnóstico.

---

# Pré-requisitos

* Sistema operacional funcional.
* Sincronização de horário configurada.
* Componentes básicos do `systemd` operacionais.

---

# Resultado esperado

Ao concluir este playbook:

* a política de armazenamento dos registros estará definida;
* a retenção de logs seguirá os padrões do projeto;
* o sistema registrará eventos de maneira consistente.

---

# Procedimento

## 1. Revisar a configuração padrão

Analise a configuração atual do `systemd-journald`.

Identifique quais parâmetros serão personalizados conforme os padrões da workstation.

---

## 2. Definir a política de armazenamento

Configure como os registros serão armazenados.

Considere aspectos como:

* persistência;
* utilização de disco;
* retenção;
* rotação automática.

---

## 3. Aplicar a configuração

Atualize a configuração do serviço conforme as decisões adotadas pelo projeto.

---

## 4. Reiniciar ou recarregar o serviço

Aplique as alterações realizadas utilizando o procedimento recomendado.

---

## 5. Validar o funcionamento

Confirme que novos eventos continuam sendo registrados normalmente após a aplicação da configuração.

---

# Verificação

Confirme que:

* o serviço está operacional;
* os registros continuam sendo gravados;
* a política de armazenamento corresponde ao esperado;
* não existem erros relacionados ao `journald`.

---

# Problemas comuns

## Logs não persistem após reinicialização

Verifique se a política de armazenamento persistente foi configurada corretamente.

---

## Crescimento excessivo dos logs

Revise os limites de retenção e utilização de disco.

---

## Serviço indisponível

Confirme a integridade da configuração antes de reiniciar o serviço.

---

# Próximo playbook

Após validar o `journald`, prossiga para:

```text id="d0m9yu"
07-configure-zram.md
```

---

# Referências

* Arch Wiki — systemd-journald
* Arch Wiki — Journal
* Arch Wiki — systemd

---

# Lições aprendidas

Registrar aqui ajustes na política de retenção, alterações na configuração do `journald` ou observações relevantes identificadas durante a operação da workstation.
