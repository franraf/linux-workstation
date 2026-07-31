---

title: Configurar gerenciador de arquivos
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

# 18 — Configurar gerenciador de arquivos

## Objetivo

Configurar o gerenciador de arquivos da workstation, definindo sua integração com a sessão gráfica e proporcionando uma experiência consistente para navegação e gerenciamento do sistema de arquivos.

Ao final deste playbook, o gerenciador de arquivos estará alinhado com os padrões definidos pelo projeto.

A implementação adotada pelo projeto utiliza o **Thunar**.

---

# Pré-requisitos

* Sessão gráfica configurada.
* Gerenciador de arquivos instalado.

---

# Resultado esperado

Ao concluir este playbook:

* o gerenciador de arquivos seguirá a identidade visual da workstation;
* a navegação pelo sistema de arquivos estará configurada conforme os padrões do projeto;
* a integração com a sessão gráfica estará concluída.

---

# Procedimento

## 1. Organizar a configuração

Estruture os arquivos conforme a ADR-0005.

Separe aparência, comportamento e integrações sempre que possível.

---

## 2. Configurar a navegação

Defina o comportamento padrão da navegação.

Considere:

* painel lateral;
* diretório inicial;
* ordenação;
* visualização;
* arquivos ocultos;
* miniaturas.

---

## 3. Configurar integrações

Integre o gerenciador de arquivos aos componentes da workstation.

Considere:

* emulador de terminal;
* navegador padrão;
* aplicações associadas;
* lançador de aplicações.

---

## 4. Configurar operações de arquivos

Defina os padrões para manipulação de arquivos.

Considere:

* cópia;
* movimentação;
* exclusão;
* lixeira;
* dispositivos removíveis.

---

## 5. Validar a experiência

Execute operações comuns de gerenciamento de arquivos.

Confirme que a navegação e as operações ocorrem conforme esperado.

---

# Verificação

Confirme que:

* o gerenciador inicia corretamente;
* a navegação pelo sistema de arquivos é funcional;
* arquivos podem ser manipulados normalmente;
* aplicações associadas são abertas corretamente;
* não existem erros durante a execução.

---

# Problemas comuns

## Aplicação não inicia

Revise a instalação e confirme a integração com a sessão gráfica.

---

## Associações incorretas

Revise as aplicações padrão configuradas para cada tipo de arquivo.

---

## Dispositivos removíveis não aparecem

Confirme que os componentes necessários para gerenciamento de dispositivos estão instalados e configurados.

---

## Problemas de permissões

Revise as permissões do usuário e a integração com os serviços do sistema.

---

# Próximo playbook

Após validar o gerenciador de arquivos, prossiga para:

```text
19-configure-appearance.md
```

---

# Referências

* Documentação oficial do Thunar
* Arch Wiki — Thunar
* XDG Base Directory Specification
* ADR-0005 — Modularize Configuration by Capability

---

# Lições aprendidas

Registrar aqui melhorias na navegação, novas integrações, ajustes de comportamento ou observações relevantes identificadas durante a evolução do gerenciador de arquivos.
