---

title: Configurar sincronização de horário
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

# 05 — Configurar sincronização de horário

## Objetivo

Configurar a sincronização automática de data e hora da workstation utilizando o mecanismo definido pela arquitetura do projeto.

Ao final deste playbook, o relógio do sistema permanecerá sincronizado com fontes confiáveis de tempo.

---

# Pré-requisitos

* Sistema operacional funcional.
* Conectividade de rede disponível.
* Componentes básicos do sistema configurados.

---

# Resultado esperado

Ao concluir este playbook:

* a sincronização automática de horário estará habilitada;
* a fonte de sincronização seguirá os padrões definidos pelo projeto;
* a data e a hora permanecerão corretas durante a operação da workstation.

---

# Procedimento

## 1. Revisar o serviço de sincronização

Confirme qual serviço de sincronização de horário será utilizado pela workstation.

---

## 2. Configurar a sincronização

Ajuste o serviço conforme os padrões definidos pelo projeto.

Evite manter múltiplos serviços de sincronização ativos simultaneamente.

---

## 3. Habilitar o serviço

Configure o serviço para iniciar automaticamente com o sistema.

---

## 4. Validar a sincronização

Verifique se a sincronização foi estabelecida corretamente e se o relógio do sistema está atualizado.

---

# Verificação

Confirme que:

* o serviço de sincronização está ativo;
* a data e a hora estão corretas;
* o fuso horário permanece configurado conforme definido durante a instalação;
* não existem erros relacionados à sincronização nos registros do sistema.

---

# Problemas comuns

## Horário incorreto

Verifique a conectividade de rede e confirme que a fonte de sincronização está acessível.

---

## Serviço inativo

Confirme que o serviço foi habilitado e iniciado corretamente.

---

## Conflito entre serviços

Garanta que apenas um mecanismo de sincronização de horário esteja responsável pelo relógio do sistema.

---

# Próximo playbook

Após validar a sincronização de horário, prossiga para:

```text
06-configure-journald.md
```

---

# Referências

* Arch Wiki — systemd-timesyncd
* Arch Wiki — System time
* Arch Wiki — Network Time Protocol

---

# Lições aprendidas

Registrar aqui alterações nas fontes de sincronização, problemas de precisão do relógio ou observações relevantes identificadas durante a manutenção da workstation.
