---

title: Instalar Hyprland
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

# 02 — Instalar Hyprland

## Objetivo

Instalar o compositor Hyprland e seus componentes essenciais, preparando a workstation para iniciar uma sessão gráfica baseada em Wayland.

Ao final deste playbook, o compositor estará instalado e apto para execução.

---

# Pré-requisitos

* Stack gráfica instalada e validada.
* Sistema operacional funcional.
* Hardware gráfico configurado.

---

# Resultado esperado

Ao concluir este playbook:

* o Hyprland estará instalado;
* suas dependências obrigatórias estarão disponíveis;
* o compositor poderá ser iniciado sem erros críticos;
* a workstation estará pronta para receber a configuração da sessão gráfica.

---

# Procedimento

## 1. Revisar os componentes necessários

Confirme os componentes obrigatórios para execução do Hyprland.

Evite instalar ferramentas opcionais que pertençam a outros playbooks.

---

## 2. Instalar o compositor

Instale o Hyprland e seus componentes essenciais.

---

## 3. Confirmar dependências

Verifique se todas as dependências obrigatórias foram instaladas corretamente.

---

## 4. Revisar a instalação

Confirme que os arquivos esperados foram instalados.

Não realize personalizações nesta etapa.

---

## 5. Validar a execução

Inicie uma sessão de teste do Hyprland.

O objetivo é apenas confirmar que o compositor inicia corretamente.

Não é necessário validar aparência ou produtividade neste momento.

---

# Verificação

Confirme que:

* o Hyprland está instalado;
* o compositor inicia corretamente;
* não existem erros críticos durante a inicialização;
* o sistema permanece estável durante a sessão de teste.

---

# Problemas comuns

## Sessão não inicia

Revise os componentes da stack gráfica e confirme que todas as dependências estão presentes.

---

## Erros relacionados ao Wayland

Confirme que o ambiente foi iniciado utilizando Wayland.

---

## Falhas gráficas

Revise a configuração da GPU e confirme que os drivers correspondem ao hardware utilizado.

---

# Próximo playbook

Após validar a instalação do Hyprland, prossiga para:

```text
03-install-status-bar.md
```

---

# Referências

* Arch Wiki — Hyprland
* Documentação oficial do Hyprland
* Arch Wiki — Wayland

---

# Lições aprendidas

Registrar aqui problemas de compatibilidade, dependências adicionais ou observações relevantes identificadas durante a instalação do compositor.
