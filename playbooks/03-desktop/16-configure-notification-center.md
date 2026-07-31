---

title: Configurar central de notificações
version: 1.0
status: Draft
author: Rafael
last_review: 2026-07-31
related:

* architecture.md
* ADR-0002
* ADR-0003
* ADR-0004
* ADR-0005

---

# 16 — Configurar central de notificações

## Objetivo

Configurar a central de notificações da workstation, definindo como eventos do sistema e das aplicações são apresentados, organizados e disponibilizados ao usuário.

Ao final deste playbook, a sessão gráfica oferecerá uma experiência consistente para recebimento, histórico e gerenciamento de notificações.

A implementação adotada pelo projeto utiliza o **Sway Notification Center (SwayNC)**.

---

# Pré-requisitos

* Sessão gráfica configurada.
* Central de notificações instalada.

---

# Resultado esperado

Ao concluir este playbook:

* a central de notificações estará integrada à sessão;
* o comportamento das notificações seguirá os padrões definidos pelo projeto;
* a interface estará alinhada com a identidade visual da workstation.

---

# Procedimento

## 1. Organizar a configuração

Estruture os arquivos de configuração conforme a ADR-0005.

Separe aparência, comportamento e integrações sempre que possível.

---

## 2. Configurar o comportamento

Defina a política de exibição das notificações.

Considere:

* posição na tela;
* tempo de permanência;
* agrupamento;
* persistência;
* prioridade.

---

## 3. Configurar a interface

Defina a organização visual da central de notificações.

Considere elementos como:

* histórico;
* painel de notificações;
* controles rápidos, quando utilizados;
* indicadores visuais.

---

## 4. Integrar à sessão gráfica

Confirme que a central de notificações inicia automaticamente e se integra corretamente aos demais componentes do desktop.

---

## 5. Validar o fluxo de notificações

Execute notificações de teste provenientes do sistema e de aplicações.

Confirme que são apresentadas, armazenadas e descartadas conforme a política definida.

---

# Verificação

Confirme que:

* a central inicia automaticamente;
* notificações são exibidas corretamente;
* o histórico está acessível;
* notificações podem ser descartadas;
* a interface permanece consistente durante toda a sessão.

---

# Problemas comuns

## Notificações não aparecem

Confirme que não existe outro daemon de notificações ativo e que a sessão inicializou corretamente a central.

---

## Histórico indisponível

Revise a configuração da central de notificações e confirme que o recurso está habilitado.

---

## Problemas de renderização

Verifique a stack tipográfica, o tema utilizado e a integração com a sessão gráfica.

---

## Comportamento inconsistente

Revise a política de notificações antes de prosseguir.

---

# Próximo playbook

Após validar a central de notificações, prossiga para:

```text
17-configure-terminal-emulator.md
```

---

# Referências

* Documentação oficial do Sway Notification Center
* Desktop Notifications Specification
* ADR-0005 — Modularize Configuration by Capability

---

# Lições aprendidas

Registrar aqui alterações na política de notificações, integrações adicionadas, ajustes de interface ou observações relevantes identificadas durante a evolução da workstation.
