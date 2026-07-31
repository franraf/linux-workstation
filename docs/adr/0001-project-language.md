---

title: Idioma do projeto
version: 1.0
status: Stable
author: Rafael
last_review: 2026-07-30
related: []
-----------

# ADR-0001 — Idioma do projeto

## Status

Aceito.

## Contexto

O projeto será utilizado principalmente por seu mantenedor, cuja língua principal é o português brasileiro.

Ao mesmo tempo, o ambiente técnico no qual o projeto está inserido utiliza predominantemente inglês em comandos, código-fonte, nomes de ferramentas, documentação oficial, mensagens de erro e projetos open source.

Utilizar apenas português em toda a implementação criaria inconsistências com o ecossistema Linux. Utilizar apenas inglês na documentação tornaria a escrita e a manutenção do conhecimento menos naturais para o mantenedor.

## Decisão

O projeto adotará uma estratégia híbrida de idiomas.

A documentação explicativa será escrita em português brasileiro.

Isso inclui:

* README;
* ADRs;
* playbooks;
* documentos de arquitetura;
* manutenção;
* recuperação;
* troubleshooting;
* roadmap;
* changelog;
* glossário.

Elementos técnicos e executáveis serão escritos em inglês.

Isso inclui:

* nomes de arquivos;
* nomes de diretórios;
* scripts;
* funções;
* variáveis;
* constantes;
* comentários em código;
* mensagens de log;
* mensagens de erro;
* commits;
* nomes de branches;
* workflows de integração contínua.

Termos técnicos consolidados poderão permanecer em inglês dentro da documentação quando sua tradução reduzir a clareza.

Exemplos:

* bootloader;
* filesystem;
* subvolume;
* snapshot;
* commit;
* rollback;
* container;
* troubleshooting.

## Consequências positivas

* A documentação será mais natural para o mantenedor.
* Código e scripts permanecerão alinhados ao ecossistema Linux.
* Pesquisas por mensagens, nomes e erros serão facilitadas.
* O projeto continuará acessível para colaboradores técnicos.
* Evita-se traduzir artificialmente termos amplamente conhecidos em inglês.

## Consequências negativas

* O repositório conterá dois idiomas.
* Colaboradores que não leem português poderão ter dificuldade com a documentação.
* Será necessário manter consistência sobre quais elementos pertencem a cada idioma.

## Alternativas consideradas

### Todo o projeto em português

Rejeitada porque nomes técnicos, código e mensagens ficariam desalinhados com as ferramentas utilizadas.

### Todo o projeto em inglês

Rejeitada porque tornaria a documentação menos natural para o mantenedor principal.

### Documentação duplicada nos dois idiomas

Rejeitada inicialmente devido ao custo de manter duas versões sincronizadas.

Essa alternativa poderá ser reconsiderada caso o projeto passe a receber contribuições internacionais frequentes.

## Regras de aplicação

Exemplo de documentação:

```markdown
O subvolume dedicado ao Docker não participa dos snapshots do sistema.
```

Exemplo de variável:

```bash
docker_subvolume="@docker"
```

Exemplo de função:

```bash
create_btrfs_subvolumes() {
    # Implementation
}
```

Exemplo de commit:

```text
docs(adr): define project language strategy
```

## Lições aprendidas

Nenhuma até o momento.
