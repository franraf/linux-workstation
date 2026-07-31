---

title: Configurar lançador de aplicações
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

# 15 — Configurar lançador de aplicações

## Objetivo

Configurar o lançador de aplicações da workstation, definindo sua integração com a sessão gráfica e a experiência de utilização.

Ao final deste playbook, o usuário poderá localizar e iniciar aplicações de forma rápida, consistente e integrada ao ambiente gráfico.

A implementação adotada pelo projeto utiliza o **Rofi**.

---

# Pré-requisitos

* Sessão gráfica configurada.
* Lançador de aplicações instalado.

---

# Resultado esperado

Ao concluir este playbook:

* o lançador estará integrado à sessão gráfica;
* os modos de operação previstos pelo projeto estarão disponíveis;
* a experiência de utilização seguirá os padrões definidos pela arquitetura.

---

# Procedimento

## 1. Organizar a configuração

Estruture os arquivos de configuração conforme a ADR-0005.

Separe aparência, comportamento e modos de operação sempre que possível.

---

## 2. Configurar o comportamento

Defina como o lançador deverá operar.

Considere:

* pesquisa de aplicações;
* pesquisa de comandos;
* pesquisa de arquivos;
* modos adicionais suportados pela implementação.

---

## 3. Configurar a integração

Integre o lançador à sessão gráfica.

Defina como ele será invocado e como interagirá com os demais componentes do desktop.

---

## 4. Configurar a experiência do usuário

Defina os padrões relacionados à utilização do lançador.

Considere aspectos como:

* posicionamento;
* navegação;
* comportamento durante a pesquisa;
* interação com teclado.

---

## 5. Validar a operação

Execute testes utilizando os modos previstos pela arquitetura.

Confirme que aplicações podem ser localizadas e iniciadas corretamente.

---

# Verificação

Confirme que:

* o lançador inicia corretamente;
* aplicações podem ser pesquisadas;
* aplicações podem ser executadas;
* a integração com a sessão gráfica funciona normalmente;
* não existem erros durante sua execução.

---

# Problemas comuns

## O lançador não inicia

Confirme que a sessão gráfica está operacional e que o componente foi instalado corretamente.

---

## Aplicações não aparecem

Verifique a indexação dos arquivos `.desktop` e a configuração do componente.

---

## Atalho não funciona

Revise a configuração da sessão gráfica e confirme que o atalho está registrado corretamente.

---

## Erros de renderização

Verifique a stack tipográfica e os recursos gráficos utilizados pelo componente.

---

# Próximo playbook

Após validar o lançador de aplicações, prossiga para:

```text
16-configure-notification-center.md
```

---

# Referências

* Documentação oficial do Rofi
* Arch Wiki — Rofi
* ADR-0005 — Modularize Configuration by Capability

---

# Lições aprendidas

Registrar aqui alterações na experiência do usuário, novos modos de operação, integrações adicionadas ou observações relevantes identificadas durante a evolução do lançador de aplicações.
