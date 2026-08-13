---
title: Padrões do projeto
version: 1.1
status: Stable
author: Rafael
last_review: 2026-08-13
related:
  - ADR-0001
  - ADR-0002
  - ADR-0004
  - ADR-0005
  - ADR-0006
  - ADR-0007
  - ADR-0009
---

# Padrões do projeto

## Objetivo

Este documento define convenções para documentação, fontes declarativas, scripts, profiles, testes e histórico de mudanças do projeto `linux-workstation`.

## Estrutura do repositório

| Diretório | Responsabilidade |
| --- | --- |
| `docs/` | documentação permanente |
| `docs/adr/` | Architecture Decision Records |
| `playbooks/` | procedimentos e intenção operacional |
| `packages/` | listas declarativas de pacotes |
| `system/` | configurações canônicas compartilhadas |
| `dotfiles/` | configurações canônicas de usuário mantidas neste repositório |
| `profiles/` | manifests e orquestradores específicos de hardware |
| `scripts/lib/` | funções Bash reutilizáveis |
| `tests/` | gates estáticos e validações de runtime |
| `examples/` | exemplos não canônicos e reutilizáveis |

Nenhum diretório deve acumular silenciosamente responsabilidade de outro.

## Fonte canônica e orquestração

Quando um dado puder ser compartilhado, ele deve existir uma única vez como fonte canônica.

* pacotes → `packages/<capacidade>/...`;
* configuração de sistema/ferramenta → `system/<capacidade>/...`;
* configuração de usuário apropriada ao repositório → `dotfiles/<capacidade>/...`;
* lógica Bash reutilizável → `scripts/lib/...`;
* escolha, contexto de hardware e sequência → `profiles/...`;
* verificação → `tests/...`.

Um `run.sh` de profile não deve manter cópias locais de listas ou configurações compartilhadas sem justificativa específica do hardware.

## Profiles e fases

Cada fase implementada deve possuir `phase.yaml` válido, sem cercas Markdown.

O manifesto deve declarar a ordem efetiva dos steps, o playbook e o entrypoint correspondentes. A ordem documentada deve refletir o comportamento real da fase.

Não existe regra universal exigindo instalar tudo antes de configurar tudo. Essa separação pode ser decisão específica de uma fase, como ocorre no desktop.

## Nomenclatura

Arquivos e diretórios usam preferencialmente letras minúsculas e `kebab-case`, exceto quando o formato nativo de uma ferramenta exigir outro nome.

Exemplos válidos:

```text
configure-network.md
base-workstation.txt
static-artifacts.sh
starship.toml
settings.json
```

ADRs seguem:

```text
0001-project-language.md
0011-upstream-distribution-exception.md
```

A numeração de ADR nunca é reutilizada.

## Documentação

Documentos permanentes e playbooks devem usar Front Matter YAML quando aplicável:

```yaml
---
title:
version:
status:
author:
last_review:
related:
---
```

Estados permitidos:

* `Draft`;
* `Review`;
* `Stable`;
* `Deprecated`.

Não declarar uma capacidade `Stable` ou concluída apenas porque a implementação existe; a validação prevista deve ter ocorrido.

## Scripts Bash

Scripts executáveis começam com:

```bash
#!/usr/bin/env bash

set -Eeuo pipefail
```

Devem:

* validar pré-requisitos;
* produzir mensagens claras;
* falhar explicitamente;
* retornar códigos apropriados;
* ser idempotentes sempre que razoável;
* evitar assumir silenciosamente usuário, disco, UUID, interface ou credencial;
* consumir as fontes canônicas do repositório;
* mover comportamento repetido para `scripts/lib/`.

Scripts de instalação não devem exigir antecipadamente o próprio comando que pretendem instalar.

### `pipefail`

Pipelines de validação merecem atenção especial. Com `set -o pipefail`, comandos como `producer | grep -q ...` ou `producer | head ...` podem gerar falso erro quando o consumidor encerra a leitura antes do produtor.

Quando apropriado, capture a saída primeiro e faça a comparação depois.

## Permissões

`run.sh` e outros entrypoints destinados a execução direta devem ser versionados com bit executável (`100755`). Bibliotecas sourceadas e testes invocados via `bash` não precisam ser executáveis, salvo quando também forem entrypoints diretos.

## Operações destrutivas

Ações destrutivas exigem confirmação forte e específica. Para operações de armazenamento que apagam dados, a frase padrão permanece:

```text
ERASE
```

Outras operações sensíveis podem usar uma frase explícita relacionada à ação, desde que documentada e não aceitem confirmação vazia ou genérica.

## Pacotes e dependências externas

O padrão é usar repositórios oficiais do Arch Linux e manter AUR desabilitado.

Dependências upstream ou externas só podem ser usadas quando houver justificativa documentada. Uma exceção aprovada deve ser estreita e não servir como autorização genérica para outras dependências.

## Configurações e segredos

Arquivos versionados não podem conter senhas, tokens, chaves privadas ou credenciais de autenticação.

O repositório pode conter nomes de variáveis, templates seguros, instruções e configurações não sensíveis.

## Testes

Toda implementação relevante deve possuir validação apropriada.

Preferência:

1. gate de consistência do repositório;
2. teste estático de fontes e sintaxe;
3. teste de runtime do estado real;
4. checklist manual somente quando automação não for adequada, por exemplo autenticação remota, UI gráfica ou serviço externo.

Testes devem consumir as mesmas fontes declarativas usadas pelos scripts sempre que isso evitar duplicação do estado esperado.

## `.gitkeep`

`.gitkeep` só deve existir para preservar no Git um diretório intencionalmente vazio.

Assim que o diretório receber conteúdo real, o `.gitkeep` deve ser removido. Não manter `.gitkeep` em diretórios não vazios apenas por histórico.

## Commits

O projeto usa Conventional Commits:

```text
feat
fix
docs
refactor
test
chore
ci
build
perf
revert
```

Cada commit representa uma mudança lógica clara.

## Branches

Com um único mantenedor, mudanças podem ocorrer diretamente na `main`. Branches continuam válidas para isolamento quando a alteração exigir experimentação ou revisão separada.

## Idioma

Conforme ADR-0001:

* documentação em português;
* código, nomes técnicos e mensagens internas preferencialmente em inglês.

## Qualidade

Antes de considerar uma mudança concluída, verificar:

* decisão arquitetural atualizada quando necessária;
* documentação coerente com a implementação;
* fonte canônica sem duplicação desnecessária;
* script usando libs compartilhadas quando aplicável;
* validação criada ou atualizada;
* manifesto da fase consistente;
* status do roadmap refletindo validação real.

## Lições aprendidas

A consistência melhora quando o repositório diferencia explicitamente **estado desejado**, **orquestração** e **validação**, em vez de colocar tudo dentro de scripts específicos do profile.
