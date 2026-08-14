---
title: Editor de código
version: 1.3
status: Draft
author: Rafael
last_review: 2026-08-14
related:

* architecture.md
* ADR-0005
* ADR-0011
* ADR-0014

---

# 03 — Editor de código

## Objetivo

Instalar e configurar o build oficial Microsoft Visual Studio Code, integrado ao Git, ao Zsh e ao modelo de configuração versionada do projeto.

A integração completa com Dev Containers será validada apenas depois da plataforma de contêineres ser configurada no playbook seguinte.

## Política de distribuição

O Arch Linux fornece `code`, que corresponde ao Code - OSS. A implementação selecionada pela arquitetura é o build oficial Microsoft Visual Studio Code.

Conforme a ADR-0011, este playbook utiliza a distribuição Linux x64 oficial da Microsoft diretamente do endpoint upstream, sem habilitar o AUR.

O aplicativo é instalado em:

```text
/opt/visual-studio-code
```

O comando estável é exposto em:

```text
/usr/local/bin/code
```

O Pacman administra as dependências de runtime e o `chezmoi`, declarados em:

```text
packages/development/code-editor-runtime.txt
```

## Fontes canônicas

Arquivos de usuário gerenciados pelo chezmoi:

```text
.chezmoiroot → dotfiles/home

dotfiles/home/private_dot_config/private_Code/User/
├── settings.json
└── keybindings.json
```

Eles convergem para:

```text
~/.config/Code/User/settings.json
~/.config/Code/User/keybindings.json
```

A lista declarativa de extensões permanece em:

```text
dotfiles/vscode/extensions.txt
```

Integração do sistema:

```text
system/development/vscode/code.desktop
```

## Procedimento

Execute como root preservando o usuário de destino via `sudo`:

```bash
sudo ./03-code-editor/run.sh
```

O script:

1. valida o sistema e o usuário normal de destino;
2. instala dependências de runtime e `chezmoi` quando ausentes;
3. apresenta a origem upstream e solicita confirmação `VSCODE`;
4. baixa a versão Stable mais recente pelo endpoint oficial Microsoft;
5. valida a estrutura mínima do arquivo baixado antes de substituir a instalação anterior;
6. instala o aplicativo em `/opt/visual-studio-code`;
7. cria o comando `/usr/local/bin/code` e o launcher desktop;
8. usa o próprio repositório como source dir do chezmoi e aplica `settings.json` e `keybindings.json`;
9. instala as extensões declaradas;
10. valida versão, arquivos canônicos, convergência do chezmoi e extensões.

## Chezmoi

Conforme ADR-0014, não existe um segundo repositório de dotfiles. O `linux-workstation` continua sendo a fonte canônica.

O script aplica somente os alvos de VS Code relevantes:

```bash
chezmoi -S <repo-root> apply \
  ~/.config/Code/User/settings.json \
  ~/.config/Code/User/keybindings.json
```

Depois da aplicação, `chezmoi diff` para esses alvos deve estar vazio.

## Dev Containers

A extensão `ms-vscode-remote.remote-containers` é instalada nesta etapa porque pertence à configuração permanente do editor.

A presença da extensão não significa que Dev Containers já esteja funcional. A capacidade depende do Docker e será testada em `04-container-platform` e no gate `07-development-validation`.

## Verificação

Confirme que:

* `code --version` retorna uma versão;
* `chezmoi --version` retorna uma versão;
* `/usr/local/bin/code` aponta para a instalação em `/opt`;
* o launcher gráfico abre o Visual Studio Code;
* `settings.json` e `keybindings.json` correspondem ao source state versionado;
* `chezmoi -S <repo-root> diff` não mostra mudanças para os dois arquivos gerenciados;
* todas as extensões declaradas estão instaladas;
* o terminal integrado utiliza Zsh;
* operações Git locais funcionam no editor.

## Atualizações

Executar novamente este playbook baixa a versão Stable mais recente, converge novamente os arquivos gerenciados pelo chezmoi e substitui a instalação upstream de maneira controlada. Pacman não administra os binários do Visual Studio Code.

## Próximo playbook

```text
04-container-platform.md
```

## Referências

* ADR-0011 — Allow upstream distribution for selected host tools
* ADR-0014 — Chezmoi-managed User Configuration
* Documentação oficial do Visual Studio Code — Linux
* Documentação oficial do chezmoi
* Development Containers Specification
