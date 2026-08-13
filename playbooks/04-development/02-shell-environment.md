---
title: Ambiente de shell
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-13
related:
  - architecture.md
  - ADR-0005
  - ADR-0009
---

# 02 — Ambiente de shell

## Objetivo

Configurar o shell principal do host com Zsh, Oh My Zsh e Starship, mantendo a configuração modular e separada de runtimes específicos de projeto.

## Fontes canônicas

Pacotes:

```text
packages/development/shell.txt
```

Configuração:

```text
system/development/zsh/
system/development/starship/starship.toml
```

Implementação do perfil:

```text
profiles/dell-latitude-e5470/04-development/02-shell-environment/run.sh
```

## Responsabilidade deste passo

O passo instala e configura somente a camada de shell/prompt:

* Zsh;
* Oh My Zsh;
* Starship;
* estrutura modular de configuração.

Ferramentas como `fzf`, `zoxide`, `eza`, `bat`, `ripgrep` e similares pertencem ao `05-cli-tools` e não são instaladas aqui.

## Estrutura instalada

```text
~/.zshenv
~/.config/zsh/
├── .zshrc
└── modules/
    ├── aliases.zsh
    ├── completion.zsh
    ├── environment.zsh
    ├── functions.zsh
    ├── integrations.zsh
    └── prompt.zsh

~/.config/starship/
└── starship.toml

~/.local/share/
└── oh-my-zsh/
```

`.zshenv` define `ZDOTDIR=~/.config/zsh`. O `.zshrc` é apenas o ponto de entrada e carrega os módulos versionados.

Oh My Zsh é mantido como checkout Git do usuário em `~/.local/share/oh-my-zsh`; o script não executa atualização automática de um checkout existente. O diretório customizado é suportado pelo próprio Oh My Zsh. 

## Execução

A partir do diretório do passo:

```bash
sudo ./run.sh
```

Ou, quando necessário:

```bash
sudo ./run.sh --user rafael
```

O script:

1. instala `zsh` e `starship` a partir da lista declarativa;
2. instala Oh My Zsh caso ainda não exista;
3. preserva um backup `.pre-linux-workstation` quando encontra uma configuração local divergente;
4. distribui os arquivos canônicos para o home do usuário;
5. configura Zsh como shell padrão;
6. abre uma inicialização não persistente de Zsh para validar a integração com Starship.

## Verificação

Depois da execução, encerre a sessão do usuário e entre novamente. Confirme:

```bash
getent passwd "$USER" | cut -d: -f7
zsh --version
starship --version
```

Abra um novo terminal e confirme que o shell inicia sem erros e que o prompt Starship aparece.

## Próximo playbook

```text
03-code-editor.md
```
