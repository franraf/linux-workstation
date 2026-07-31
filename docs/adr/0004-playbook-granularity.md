---

title: Granularidade dos playbooks
version: 1.0
status: Stable
author: Rafael
last_review: 2026-07-31
related:

* ADR-0002
* ADR-0003
* standards.md

---

# ADR-0004 — Granularidade dos playbooks

## Status

Aceito.

## Contexto

Os playbooks constituem a documentação operacional do projeto e serão utilizados tanto como guia durante uma instalação manual quanto como referência para futuras automações.

Sem critérios claros para sua divisão, existe o risco de produzir documentos excessivamente grandes, difíceis de revisar, testar e manter.

Por outro lado, uma divisão excessiva gera fragmentação desnecessária e dificulta acompanhar o fluxo completo de uma tarefa.

É necessário definir um critério consistente para determinar o tamanho e a responsabilidade de cada playbook.

## Decisão

Cada playbook deverá possuir **um único objetivo operacional**.

Ao término da execução do playbook, o sistema deverá estar em um estado consistente e verificável.

Sempre que possível, um playbook deverá:

* possuir um objetivo claramente definido;
* ter início e fim bem delimitados;
* depender apenas dos playbooks anteriores;
* terminar com uma etapa objetiva de validação;
* indicar o próximo playbook recomendado.

A divisão dos documentos será orientada por responsabilidade, e não pela quantidade de comandos ou pelo número de páginas.

## Exemplos

São considerados playbooks adequados:

```text
01-prepare-install-media.md
02-configure-firmware.md
03-partition-disk.md
04-create-luks.md
05-create-btrfs.md
06-mount-filesystems.md
07-install-base-system.md
08-configure-system.md
09-install-bootloader.md
10-first-boot.md
```

Não é recomendado concentrar toda a instalação em um único documento como:

```text
install-arch-linux.md
```

Esse formato mistura diversas responsabilidades independentes e dificulta manutenção, revisão e validação.

## Critérios de divisão

Um novo playbook deverá ser criado quando ocorrer pelo menos uma das seguintes situações:

* início de uma nova fase da instalação;
* mudança significativa de contexto técnico;
* necessidade de validação intermediária;
* possibilidade de reutilização em outros cenários;
* risco elevado associado à etapa.

Não se deve criar novos playbooks apenas para reduzir artificialmente o tamanho dos documentos.

## Estrutura mínima

Todo playbook deverá conter, quando aplicável:

* Objetivo
* Pré-requisitos
* Procedimento
* Verificação
* Problemas comuns
* Próximo playbook
* Referências
* Lições aprendidas

## Consequências positivas

* Documentos menores e mais focados.
* Revisões simplificadas.
* Validações independentes.
* Melhor reutilização.
* Facilidade para automatizar etapas específicas.
* Menor impacto de futuras alterações.

## Consequências negativas

* Maior quantidade de arquivos.
* Necessidade de manter referências entre playbooks.
* Índice operacional mais extenso.

Esses custos são considerados aceitáveis diante dos benefícios de organização e manutenção.

## Alternativas consideradas

### Um único playbook para toda a instalação

Rejeitada por concentrar responsabilidades distintas em um único documento.

### Divisão por quantidade de páginas ou linhas

Rejeitada porque o tamanho do documento não representa, por si só, uma responsabilidade técnica.

### Divisão extremamente granular

Exemplo:

```text
create-efi-partition.md
format-efi.md
mount-efi.md
```

Rejeitada por aumentar a fragmentação sem ganho proporcional de clareza.

## Regras de aplicação

Ao criar um novo playbook, pergunte:

1. Ele possui um único objetivo?
2. Pode ser validado isoladamente?
3. Termina em um estado consistente?
4. Pode ser reutilizado em outro fluxo?
5. Existe um momento natural para encerrar este documento?

Se a maioria das respostas for positiva, a granularidade é adequada.

## Lições aprendidas

Definir a granularidade dos playbooks antes da implementação evita documentos monolíticos e estabelece uma base consistente para futuras automações.
