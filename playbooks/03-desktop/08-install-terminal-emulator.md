---

title: Instalar emulador de terminal
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

# 08 — Instalar emulador de terminal

## Objetivo

Instalar um emulador de terminal para utilização no ambiente gráfico da workstation.

Ao final deste playbook, a sessão gráfica permitirá acesso ao shell por meio de um terminal integrado ao ambiente Wayland.

A implementação adotada pelo projeto utiliza o **Kitty**.

---

# Pré-requisitos

* Stack gráfica instalada.
* Hyprland instalado.

---

# Resultado esperado

Ao concluir este playbook:

* o emulador de terminal estará instalado;
* suas dependências obrigatórias estarão disponíveis;
* o terminal poderá ser iniciado durante a sessão gráfica.

---

# Procedimento

## 1. Revisar os componentes necessários

Confirme as dependências obrigatórias para utilização do emulador de terminal.

---

## 2. Instalar o componente

Instale a implementação definida pela arquitetura do projeto.

---

## 3. Validar a instalação

Confirme que todos os componentes esperados foram instalados corretamente.

---

## 4. Executar um teste funcional

Inicie o terminal durante uma sessão de teste.

Confirme que uma nova sessão do shell pode ser aberta normalmente.

Não configure aparência, atalhos ou comportamento nesta etapa.

---

# Verificação

Confirme que:

* o terminal está instalado;
* novas sessões podem ser abertas;
* o shell inicia corretamente;
* caracteres Unicode são exibidos corretamente;
* não existem erros críticos durante sua execução.

---

# Problemas comuns

## O terminal não inicia

Revise as dependências e confirme que a sessão gráfica está operacional.

---

## Shell não disponível

Confirme que o shell padrão do usuário está configurado corretamente.

---

## Problemas de renderização

Verifique a disponibilidade das fontes utilizadas pelo sistema.

---

# Próximo playbook

Após validar o emulador de terminal, prossiga para:

```text
09-install-file-manager.md
```

---

# Referências

* Documentação oficial do Kitty
* Arch Wiki — Kitty
* Arch Wiki — Terminal emulator

---

# Lições aprendidas

Registrar aqui incompatibilidades, dependências adicionais ou observações relevantes identificadas durante a instalação do emulador de terminal.
