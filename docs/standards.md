---

title: Padrões do projeto
version: 1.0
status: Stable
author: Rafael
last_review: 2026-07-30
related:

* ADR-0001
* ADR-0002

---

# Padrões do projeto

## Objetivo

Este documento define os padrões adotados pelo projeto `linux-workstation`.

Seu objetivo é manter consistência entre documentação, código, scripts, estrutura do repositório e histórico de mudanças.

Sempre que um novo componente for criado, este documento deverá ser consultado antes da implementação.

---

# Estrutura do repositório

Cada diretório possui uma responsabilidade bem definida.

| Diretório    | Responsabilidade                      |
| ------------ | ------------------------------------- |
| `docs/`      | Documentação permanente do projeto    |
| `docs/adr/`  | Architecture Decision Records         |
| `playbooks/` | Procedimentos reproduzíveis           |
| `packages/`  | Listas declarativas de pacotes        |
| `profiles/`  | Configurações específicas de hardware |
| `scripts/`   | Automações                            |
| `system/`    | Arquivos de configuração do sistema   |
| `tests/`     | Validações da workstation             |
| `examples/`  | Exemplos reutilizáveis                |

Nenhum diretório deverá acumular responsabilidades de outro.

---

# Convenções de nomenclatura

## Arquivos

Todos os arquivos utilizarão:

* letras minúsculas;
* `kebab-case`;
* nomes descritivos.

Exemplos:

```text
install-base.md
filesystem-layout.md
network-manager.sh
```

Não utilizar:

```text
InstallBase.md
install_base.md
Novo Documento.md
```

---

## Diretórios

Também utilizarão `kebab-case`.

Exemplo:

```text
profiles/
playbooks/
examples/
```

---

## Scripts

Scripts Bash utilizarão nomes iniciados por verbos.

Exemplos:

```text
install-base.sh
configure-network.sh
enable-snapper.sh
```

---

## ADRs

Os ADRs seguirão obrigatoriamente o formato:

```text
0001-project-language.md
0002-project-philosophy.md
0003-systemd-boot.md
```

A numeração nunca deverá ser reutilizada.

Mesmo ADRs removidos permanecem reservados.

---

# Padrão dos documentos

Todo documento deverá possuir Front Matter YAML.

Modelo:

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

* Draft
* Review
* Stable
* Deprecated

---

## Estrutura recomendada

Sempre que aplicável, utilizar:

* Objetivo
* Contexto
* Pré-requisitos
* Decisão
* Procedimento
* Verificação
* Próximos passos
* Referências
* Lições aprendidas

Nem todas as seções são obrigatórias, mas a organização deve permanecer consistente.

---

# Padrão dos scripts

Todos os scripts Bash deverão iniciar com:

```bash
#!/usr/bin/env bash

set -Eeuo pipefail
```

Sempre que possível deverão conter um cabeçalho semelhante a:

```text
Nome
Objetivo
Pré-requisitos
Idempotente?
ADRs relacionados
```

Os scripts deverão:

* validar pré-requisitos;
* falhar rapidamente em caso de erro;
* produzir mensagens claras;
* evitar efeitos colaterais inesperados;
* retornar códigos de saída apropriados.

---

# Operações destrutivas

Comandos destrutivos não poderão ser executados automaticamente.

Exemplos:

* `mkfs`
* `parted`
* `fdisk`
* `wipefs`
* `cryptsetup luksFormat`
* exclusão de partições

Antes da execução, o usuário deverá confirmar digitando exatamente:

```text
ERASE
```

Confirmações do tipo `y`, `yes` ou apenas pressionar Enter não serão aceitas.

---

# Commits

O projeto utiliza **Conventional Commits**.

Tipos principais:

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

Exemplos:

```text
docs(adr): define project philosophy
feat(boot): add systemd-boot installation playbook
fix(network): correct NetworkManager configuration
test(storage): validate Btrfs subvolumes
```

Cada commit deverá representar uma única mudança lógica.

---

# Branches

Enquanto houver apenas um mantenedor, mudanças poderão ser realizadas diretamente na branch principal.

Caso existam colaboradores, recomenda-se:

```text
feature/<nome>
fix/<nome>
docs/<nome>
```

---

# Comentários

Comentários devem explicar decisões, não repetir o código.

Evitar:

```bash
count=$((count + 1)) # incrementa count
```

Preferir:

```bash
# O primeiro snapshot é ignorado porque representa o estado inicial.
```

---

# Idioma

Seguir a estratégia definida no ADR-0001.

* Documentação em português.
* Código e elementos técnicos em inglês.

---

# Ferramentas

Sempre que possível, utilizar ferramentas dos repositórios oficiais do Arch Linux.

Dependências externas deverão possuir justificativa documentada.

---

# Validação

Toda implementação relevante deverá possuir uma forma objetiva de validação.

Exemplos:

* comando de verificação;
* script em `tests/`;
* checklist documentado;
* evidência registrada.

---

# Qualidade

Antes de considerar uma tarefa concluída, verificar:

* A documentação foi atualizada?
* Existe ADR quando necessário?
* O procedimento pode ser reproduzido?
* Há uma forma clara de validação?
* Os testes foram criados ou atualizados?
* O changelog precisa ser atualizado?

---

# Mudanças nos padrões

Este documento é considerado parte da base arquitetural do projeto.

Alterações deverão ocorrer apenas quando houver benefício técnico claro, buscando preservar a consistência do repositório ao longo do tempo.

---

# Lições aprendidas

Padronização precoce reduz retrabalho, facilita revisões e torna o projeto mais previsível à medida que cresce.
