---
title: Listas declarativas de pacotes
version: 1.0
status: Stable
author: Rafael
last_review: 2026-08-12
related:

* ADR-0002
* ADR-0004
* ADR-0006
* standards.md

---

# ADR-0007 — Listas declarativas de pacotes

## Status

Aceito.

## Contexto

Durante a criação dos scripts de instalação do desktop, listas de pacotes embutidas diretamente em scripts Bash dificultaram a leitura e misturaram duas responsabilidades:

* declarar quais pacotes compõem uma capacidade;
* implementar a lógica usada para instalá-los e validá-los.

O projeto já possui o diretório `packages/` com responsabilidade explícita de armazenar listas declarativas de pacotes.

## Decisão

Conjuntos de pacotes que representam uma capacidade ou fase deverão, sempre que apropriado, ser declarados em arquivos de dados separados da lógica dos scripts.

Para listas simples utilizadas pelo Pacman, o formato padrão será texto, com um pacote por linha.

Exemplo:

```text
packages/desktop/graphics.txt
```

Conteúdo:

```text
mesa
vulkan-intel
vulkan-radeon
```

O script responsável pela instalação deverá consumir a lista declarativa, sem duplicar os nomes dos pacotes em sua lógica.

Comentários e linhas vazias poderão ser suportados quando o consumidor os tratar explicitamente.

## Responsabilidades

Os arquivos de pacotes definem **o que** deve ser instalado.

Os scripts definem **como** instalar e validar.

Essa distinção deverá ser preservada.

## Consequências positivas

* Facilita revisão do conjunto de pacotes.
* Reduz duplicação entre scripts.
* Permite reutilizar listas em testes e outras automações.
* Torna alterações de dependências menores e mais claras no Git.
* Mantém a lógica Bash focada em execução e validação.

## Consequências negativas

* Introduz arquivos adicionais no repositório.
* Scripts precisam localizar e validar corretamente suas listas de pacotes.
* Mudanças estruturais no diretório `packages/` podem exigir atualização dos consumidores.

## Alternativas consideradas

### Arrays Bash dentro de cada script

Aceitáveis para casos muito pequenos, mas não adotados como padrão para capacidades com listas próprias porque acoplam dados e lógica.

### Uma única lista global de pacotes

Rejeitada porque perde a associação entre dependências e capacidades e dificulta reutilização parcial.

### Formatos estruturados como YAML

Não adotados para listas simples porque acrescentam complexidade sem benefício proporcional. Poderão ser utilizados quando metadados adicionais forem realmente necessários.

## Regras de aplicação

* Utilizar um pacote por linha nas listas simples.
* Manter nomes de arquivos e diretórios em inglês e `kebab-case`.
* Não duplicar a mesma lista dentro do script consumidor.
* O script deverá validar que o arquivo esperado existe e não está vazio quando isso for necessário para sua execução.
* A localização da lista deverá ser resolvida de forma independente do diretório corrente do usuário.

## Lições aprendidas

Separar listas de pacotes da lógica dos scripts tornou mais evidente a intenção de cada etapa e reduziu o risco de divergência entre documentação, instalação e validação.
