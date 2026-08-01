---

title: Ferramentas de linha de comando
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

# 05 — Ferramentas de linha de comando

## Objetivo

Adicionar à workstation um conjunto de ferramentas de linha de comando voltadas para produtividade, automação e inspeção do sistema.

Ao final deste playbook, a workstation oferecerá um ambiente de terminal completo para atividades de desenvolvimento, administração e depuração.

---

# Pré-requisitos

* Ambiente de shell configurado.
* Plataforma de contêineres configurada.

---

# Resultado esperado

Ao concluir este playbook:

* as ferramentas previstas pelo projeto estarão instaladas;
* a experiência da linha de comando será consistente;
* as ferramentas estarão integradas ao ambiente de shell.

---

# Estrutura da configuração

Sempre que uma ferramenta permitir configuração reproduzível, mantenha seus arquivos versionados nos dotfiles.

Estrutura recomendada:

```text
dotfiles/

cli/
├── bat/
├── delta/
├── lazygit/
├── tmux/
└── ...
```

Cada ferramenta deverá utilizar sua estrutura nativa de configuração.

Evite criar convenções artificiais quando a implementação já possuir um formato consolidado.

---

# Procedimento

## 1. Instalar as ferramentas

Instale apenas as ferramentas previstas pela arquitetura da workstation.

Considere, quando adotadas pelo projeto:

### Navegação

* eza
* tree

### Pesquisa

* fd
* ripgrep
* fzf

### Visualização

* bat
* jq
* yq

### Rede

* curl
* wget
* HTTPie

### Arquivos

* zip
* unzip

### Produtividade

* tmux
* just
* make

### Git

* lazygit
* git-delta

---

## 2. Configurar as ferramentas

Aplique as configurações versionadas para cada implementação.

Respeite o formato nativo suportado por cada ferramenta.

---

## 3. Integrar ao ambiente de shell

Confirme que as ferramentas estão integradas ao ambiente de shell.

Considere:

* aliases;
* funções;
* autocompletar;
* integração com Git;
* integração com Docker.

---

## 4. Validar as capacidades

Confirme que cada categoria de ferramentas atende ao propósito esperado.

Valide, quando aplicável:

* pesquisa de arquivos;
* busca textual;
* manipulação de JSON e YAML;
* gerenciamento de sessões;
* inspeção de repositórios Git;
* automação de tarefas.

---

## 5. Revisar consistência

Confirme que as ferramentas seguem os padrões definidos pelo projeto e que não existem sobreposições desnecessárias de funcionalidades.

---

# Verificação

Confirme que:

* todas as ferramentas previstas estão instaladas;
* as configurações versionadas foram aplicadas;
* integrações com Shell, Git e Docker funcionam corretamente;
* não existem conflitos entre ferramentas equivalentes;
* o ambiente permanece consistente e reproduzível.

---

# Problemas comuns

## Ferramenta não encontrada

Confirme que a instalação foi concluída corretamente e que o executável está disponível no ambiente.

---

## Configuração não aplicada

Revise os arquivos presentes em `dotfiles/cli/`.

---

## Integração ausente

Confirme que aliases, funções e integrações do shell foram carregados corretamente.

---

## Ferramentas redundantes

Revise a lista adotada pelo projeto e elimine implementações que entreguem capacidades equivalentes sem benefício claro.

---

# Próximo playbook

Após validar as ferramentas de linha de comando, prossiga para:

```text
06-ai-tooling.md
```

---

# Referências

* Documentação oficial de cada ferramenta adotada
* ADR-0005 — Modularize Configuration by Capability

---

# Lições aprendidas

Registrar aqui novas ferramentas incorporadas, substituições, integrações adicionadas ou observações relevantes identificadas durante a evolução do ambiente de linha de comando.
