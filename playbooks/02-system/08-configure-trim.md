
---

title: Configurar TRIM
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

# 08 — Configurar TRIM

## Objetivo

Configurar a execução periódica do TRIM para manter o desempenho e a longevidade dos dispositivos de armazenamento em estado sólido (SSD).

Ao final deste playbook, a workstation executará operações de descarte de blocos conforme a política definida pelo projeto.

---

# Pré-requisitos

* Sistema operacional funcional.
* Dispositivo de armazenamento compatível com TRIM.
* Sistema de arquivos configurado e operacional.

---

# Resultado esperado

Ao concluir este playbook:

* o mecanismo de TRIM estará configurado;
* a política de execução seguirá os padrões definidos pelo projeto;
* o sistema contribuirá para a manutenção do desempenho do SSD ao longo do tempo.

---

# Procedimento

## 1. Confirmar suporte ao TRIM

Verifique se o dispositivo de armazenamento e o sistema de arquivos suportam operações de descarte.

---

## 2. Revisar a estratégia adotada

Confirme se o projeto utiliza TRIM contínuo, periódico ou outra abordagem documentada.

---

## 3. Configurar o mecanismo de execução

Configure o serviço ou temporizador responsável pela execução do TRIM.

Evite utilizar estratégias conflitantes simultaneamente.

---

## 4. Habilitar a execução automática

Configure o mecanismo para executar conforme a periodicidade definida pelo projeto.

---

## 5. Validar a configuração

Confirme que o serviço ou temporizador está corretamente registrado e apto para execução.

---

# Verificação

Confirme que:

* o suporte ao TRIM está disponível;
* o mecanismo automático está habilitado;
* não existem erros relacionados à execução do descarte;
* a política definida pelo projeto foi aplicada corretamente.

---

# Problemas comuns

## SSD sem suporte

Confirme as características do dispositivo antes de habilitar o TRIM.

---

## Serviço não executa

Verifique se o mecanismo configurado foi habilitado corretamente.

---

## Estratégias conflitantes

Garanta que apenas uma política de TRIM esteja ativa.

---

# Próximo playbook

Após validar a configuração do TRIM, prossiga para:

```text id="2vbn8p"
09-configure-sudo.md
```

---

# Referências

* Arch Wiki — Solid State Drives
* Arch Wiki — fstrim
* Arch Wiki — systemd timers

---

# Lições aprendidas

Registrar aqui alterações na política de TRIM, observações sobre desempenho do armazenamento ou ajustes realizados durante a manutenção da workstation.
