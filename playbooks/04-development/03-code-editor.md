---
title: Editor de código
version: 1.2
status: Draft
author: Rafael
last_review: 2026-08-13
related:

* architecture.md
* ADR-0005
* ADR-0011

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

O Pacman continua responsável somente pelas dependências de runtime declaradas em:

```text
packages/development/code-editor-runtime.txt
```

## Fontes canônicas

Configuração do usuário:

```text
dotfiles/vscode/
├── settings.json
├── keybindings.json
└── extensions.txt
```

Integração do sistema:

```text
system/development/vscode/
└── code.desktop
```

## Procedimento

Execute como root preservando o usuário de destino via `sudo`:

```bash
sudo ./03-code-editor/run.sh
```

O script:

1. valida o sistema e o usuário normal de destino;
2. instala dependências de runtime ausentes pelos repositórios oficiais;
3. apresenta a origem upstream e solicita confirmação `VSCODE`;
4. baixa a versão Stable mais recente pelo endpoint oficial Microsoft;
5. valida a estrutura mínima do arquivo baixado antes de substituir a instalação anterior;
6. instala o aplicativo em `/opt/visual-studio-code`;
7. cria o comando `/usr/local/bin/code` e o launcher desktop;
8. aplica `settings.json` e `keybindings.json` ao usuário;
9. instala as extensões declaradas;
10. valida versão, arquivos canônicos e extensões.

## Dev Containers

A extensão `ms-vscode-remote.remote-containers` é instalada nesta etapa porque pertence à configuração permanente do editor.

A presença da extensão não significa que Dev Containers já esteja funcional. A capacidade depende do Docker e será testada em `04-container-platform` e no gate `07-development-validation`.

## Verificação

Confirme que:

* `code --version` retorna uma versão;
* `/usr/local/bin/code` aponta para a instalação em `/opt`;
* o launcher gráfico abre o Visual Studio Code;
* `settings.json` e `keybindings.json` correspondem às fontes versionadas;
* todas as extensões declaradas estão instaladas;
* o terminal integrado utiliza Zsh;
* operações Git locais funcionam no editor.

## Atualizações

Executar novamente este playbook baixa a versão Stable mais recente e substitui a instalação upstream de maneira controlada. Pacman não administra os binários do Visual Studio Code.

## Próximo playbook

```text
04-container-platform.md
```

## Referências

* ADR-0011 — Allow upstream distribution for selected host tools
* Documentação oficial do Visual Studio Code — Linux
* Visual Studio Code FAQ — download endpoints
* Development Containers Specification
