---

title: Editor de código
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

# 03 — Editor de código

## Objetivo

Adicionar à workstation um editor de código moderno, integrado e reproduzível para desenvolvimento de software.

Ao final deste playbook, a workstation oferecerá um ambiente de edição preparado para trabalhar com projetos locais e ambientes de desenvolvimento baseados em contêineres.

A implementação adotada pelo projeto utiliza o **Visual Studio Code**.

---

# Pré-requisitos

* Ambiente de shell configurado.
* Capacidade de controle de versão concluída.
* Sessão gráfica operacional.

---

# Resultado esperado

Ao concluir este playbook:

* o editor estará instalado;
* a configuração estará versionada;
* as extensões definidas pelo projeto estarão disponíveis;
* a integração com Git, terminal e Dev Containers estará funcional.

---

# Estrutura da configuração

A configuração do editor deverá ser mantida junto aos dotfiles da workstation.

Estrutura recomendada:

```text id="yvn4e8"
dotfiles/

vscode/
├── settings.json
├── keybindings.json
├── extensions.txt
└── snippets/
```

Sempre que possível, mantenha cada tipo de configuração em seu próprio arquivo.

Evite concentrar configurações de naturezas diferentes em um único recurso.

A estrutura deverá permanecer compatível com o formato nativo suportado pelo editor.

---

# Procedimento

## 1. Instalar o editor

Instale o editor definido pela arquitetura da workstation.

---

## 2. Restaurar a configuração

Aplique os arquivos versionados da configuração.

Considere:

* preferências globais;
* atalhos;
* snippets;
* extensões.

Confirme que a configuração aplicada corresponde à versão mantida no repositório.

---

## 3. Configurar o ambiente

Revise as configurações relacionadas à experiência de desenvolvimento.

Considere:

* fontes;
* tema;
* terminal integrado;
* formatação;
* salvamento automático;
* comportamento da interface.

---

## 4. Instalar as extensões

Instale as extensões previstas pela arquitetura.

Utilize a lista versionada no projeto como fonte única de verdade.

Evite instalar extensões permanentes fora desse controle.

---

## 5. Configurar integrações

Confirme a integração do editor com:

* Git;
* ambiente de shell;
* plataforma de contêineres;
* terminal integrado.

---

## 6. Validar Dev Containers

Abra um projeto preparado para desenvolvimento em contêiner.

Confirme que o editor:

* reconhece a configuração;
* cria ou reutiliza o ambiente;
* conecta-se corretamente ao contêiner;
* disponibiliza todas as funcionalidades esperadas.

---

## 7. Validar a experiência

Abra um projeto de teste.

Confirme que é possível:

* editar arquivos;
* utilizar o terminal integrado;
* executar operações do Git;
* iniciar um Dev Container;
* trabalhar normalmente dentro do ambiente isolado.

---

# Verificação

Confirme que:

* o editor inicia corretamente;
* a configuração versionada foi aplicada;
* as extensões previstas estão instaladas;
* Git está integrado;
* Dev Containers funcionam corretamente;
* não existem erros durante a utilização.

---

# Problemas comuns

## Editor não inicia

Confirme que a instalação foi concluída corretamente e que a sessão gráfica está operacional.

---

## Configuração não aplicada

Revise os arquivos presentes em `dotfiles/vscode/` e confirme que foram restaurados corretamente.

---

## Extensões ausentes

Compare as extensões instaladas com a lista versionada pelo projeto.

---

## Dev Containers indisponíveis

Confirme que a plataforma de contêineres está instalada e integrada ao editor.

---

## Git não reconhecido

Verifique a integração com a capacidade de controle de versão.

---

# Próximo playbook

Após validar o editor de código, prossiga para:

```text id="glwjcu"
04-container-platform.md
```

---

# Referências

* Documentação oficial do Visual Studio Code
* Development Containers Specification
* ADR-0005 — Modularize Configuration by Capability

---

# Lições aprendidas

Registrar aqui novas extensões adotadas, melhorias na configuração do editor, integrações adicionadas ou observações relevantes identificadas durante sua evolução.
