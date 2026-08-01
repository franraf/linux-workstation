---

title: Ambiente de shell
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

# 02 — Ambiente de shell

## Objetivo

Adicionar à workstation um ambiente de shell moderno, consistente e produtivo para administração do sistema e desenvolvimento de software.

Ao final deste playbook, a workstation oferecerá uma interface de linha de comando modular, integrada e reproduzível.

A implementação adotada pelo projeto utiliza o **Zsh** como shell principal e o **Starship** como prompt.

---

# Pré-requisitos

* Capacidade de controle de versão concluída.
* Emulador de terminal configurado.

---

# Resultado esperado

Ao concluir este playbook:

* o Zsh estará configurado como shell principal do usuário;
* o Starship estará integrado ao shell;
* as ferramentas auxiliares da linha de comando estarão disponíveis;
* a configuração seguirá uma organização modular conforme a ADR-0005;
* o ambiente estará pronto para integração com as demais capacidades da workstation.

---

# Estrutura da configuração

Organize a configuração do ambiente de shell de forma modular.

Estrutura recomendada:

```text
~/.config/

zsh/
├── zshrc
└── modules/
    ├── aliases.zsh
    ├── completion.zsh
    ├── environment.zsh
    ├── functions.zsh
    ├── integrations.zsh
    └── prompt.zsh

starship/
└── starship.toml
```

O arquivo `zshrc` deverá atuar apenas como ponto de entrada, carregando os módulos responsáveis por cada aspecto da configuração.

Cada módulo deverá possuir uma única responsabilidade.

---

# Procedimento

## 1. Instalar o ambiente

Instale:

* Zsh;
* Starship;
* ferramentas auxiliares definidas pela arquitetura.

Configure o Zsh como shell padrão do usuário.

---

## 2. Organizar a estrutura

Crie a estrutura de diretórios recomendada.

Organize os módulos de forma lógica e independente.

Evite arquivos monolíticos e duplicação de configurações.

---

## 3. Configurar o ambiente

Configure os módulos responsáveis por:

* variáveis de ambiente;
* aliases;
* funções;
* autocompletar;
* integrações;
* inicialização do shell.

Cada módulo deverá tratar exclusivamente de sua responsabilidade.

---

## 4. Configurar o prompt

Configure o Starship como prompt da workstation.

Considere a exibição de:

* diretório atual;
* repositório Git;
* branch ativa;
* código de retorno do último comando;
* duração de comandos;
* indicadores relevantes ao desenvolvimento.

---

## 5. Configurar ferramentas auxiliares

Integre as ferramentas adotadas pelo projeto.

Considere:

* navegação entre diretórios;
* pesquisa de histórico;
* busca textual;
* listagem de arquivos;
* visualização de conteúdo.

---

## 6. Integrar com a workstation

Confirme a integração do ambiente de shell com:

* Git;
* emulador de terminal;
* editor de código;
* plataforma de contêineres.

---

## 7. Validar a experiência

Abra uma nova sessão de terminal.

Confirme que:

* o shell inicia corretamente;
* o prompt é carregado;
* todos os módulos são inicializados sem erros;
* as ferramentas auxiliares estão disponíveis;
* a navegação e a pesquisa funcionam corretamente.

---

# Verificação

Confirme que:

* o shell padrão é o definido pelo projeto;
* o Starship está ativo;
* a estrutura modular foi criada;
* os módulos possuem responsabilidades independentes;
* aliases e funções estão disponíveis;
* a integração com Git está operacional;
* não existem erros durante a inicialização do shell.

---

# Problemas comuns

## Shell incorreto

Confirme que o shell padrão do usuário foi atualizado corretamente.

---

## Prompt não aparece

Revise a configuração do Starship e confirme sua integração com o Zsh.

---

## Módulos não carregam

Revise o arquivo `zshrc` e confirme que todos os módulos são carregados corretamente.

---

## Inicialização lenta

Revise os módulos carregados durante a inicialização e elimine configurações desnecessárias.

---

# Próximo playbook

Após validar o ambiente de shell, prossiga para:

```text
03-code-editor.md
```

---

# Referências

* Documentação oficial do Zsh
* Documentação oficial do Starship
* Arch Wiki — Zsh
* ADR-0005 — Modularize Configuration by Capability

---

# Lições aprendidas

Registrar aqui melhorias na organização do ambiente de shell, novas integrações ou observações relevantes identificadas durante sua evolução.
