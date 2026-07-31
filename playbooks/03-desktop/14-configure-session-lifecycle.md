---

title: Configurar ciclo de vida da sessão
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

# 14 — Configurar ciclo de vida da sessão

## Objetivo

Configurar as políticas de inatividade da sessão gráfica, definindo como a workstation deve reagir durante períodos sem interação do usuário.

Ao final deste playbook, a sessão seguirá uma sequência consistente de ações relacionadas à economia de energia e proteção da sessão.

A implementação adotada pelo projeto utiliza o **Hypridle**.

---

# Pré-requisitos

* Sessão gráfica configurada.
* Componente de gerenciamento de inatividade instalado.
* Bloqueio da sessão configurado.

---

# Resultado esperado

Ao concluir este playbook:

* as políticas de inatividade estarão definidas;
* o bloqueio automático estará integrado;
* a economia de energia seguirá os padrões definidos pelo projeto.

---

# Procedimento

## 1. Organizar a configuração

Estruture os arquivos conforme a ADR-0005.

Separe políticas de inatividade, energia e bloqueio sempre que possível.

---

## 2. Definir o ciclo de vida

Estabeleça a sequência de eventos da sessão.

Considere:

* redução gradual da atividade;
* desligamento do monitor;
* bloqueio automático;
* suspensão do sistema;
* retomada da sessão.

---

## 3. Configurar integrações

Integre o gerenciamento de inatividade com:

* bloqueio da sessão;
* gerenciamento de energia;
* componentes da sessão gráfica.

---

## 4. Validar os eventos

Execute testes simulando períodos de inatividade.

Confirme que cada etapa ocorre na ordem prevista.

---

## 5. Validar a retomada

Confirme que a sessão retorna ao estado esperado após atividade do usuário.

---

# Verificação

Confirme que:

* o ciclo de vida ocorre conforme definido;
* o bloqueio automático funciona;
* a economia de energia é aplicada corretamente;
* a retomada da sessão ocorre sem inconsistências;
* não existem erros durante a execução.

---

# Problemas comuns

## Eventos não são executados

Revise a política de inatividade e confirme a integração com os componentes da sessão.

---

## Ordem incorreta dos eventos

Confirme a sequência configurada e elimine conflitos entre ações.

---

## Sessão não retorna corretamente

Revise a integração entre o gerenciador de inatividade, o bloqueio da sessão e o compositor.

---

## Consumo elevado de energia

Revise os tempos definidos e confirme que os mecanismos de economia de energia estão sendo acionados.

---

# Próximo playbook

Após validar o ciclo de vida da sessão, prossiga para:

```text
15-configure-application-launcher.md
```

---

# Referências

* Documentação oficial do Hypridle
* Documentação oficial do Hyprland
* ADR-0005 — Modularize Configuration by Capability

---

# Lições aprendidas

Registrar aqui ajustes na política de inatividade, alterações na estratégia de economia de energia ou observações relevantes identificadas durante a evolução da workstation.
