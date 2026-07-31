---

title: Organização dos playbooks
version: 1.0
status: Stable
author: Rafael
last_review: 2026-07-30
related:

* ADR-0002
* architecture.md
* standards.md

---

# ADR-0003 — Organização dos playbooks

## Status

Aceito.

## Contexto

À medida que o projeto evolui, a quantidade de procedimentos operacionais tende a crescer significativamente.

Uma única pasta `playbooks/` contendo todos os documentos dificultaria a navegação, aumentaria o tempo de localização de informações e misturaria procedimentos pertencentes a fases distintas do ciclo de vida da workstation.

Além disso, a instalação, a manutenção, a recuperação e a configuração do ambiente possuem públicos e objetivos diferentes.

## Decisão

Os playbooks serão organizados por domínio funcional e por ordem lógica de execução.

A estrutura inicial será:

```text
playbooks/
├── README.md
├── 01-installation/
├── 02-system/
├── 03-desktop/
├── 04-development/
├── 05-maintenance/
└── 06-recovery/
```

Cada diretório representa uma fase da construção ou operação da workstation.

Dentro de cada diretório, os documentos poderão utilizar uma numeração sequencial para indicar a ordem recomendada de execução.

Exemplo:

```text
01-installation/
├── 01-prepare-install-media.md
├── 02-configure-firmware.md
├── 03-partition-disk.md
├── 04-create-luks.md
├── 05-create-btrfs.md
├── 06-mount-filesystems.md
├── 07-install-base-system.md
├── 08-configure-system.md
├── 09-install-bootloader.md
└── 10-first-boot.md
```

A numeração representa apenas a ordem de leitura e execução. Ela não estabelece dependência técnica entre os documentos.

## Motivação

Essa organização busca:

* facilitar a navegação;
* manter cada playbook pequeno e focado;
* permitir validação ao final de cada etapa;
* simplificar revisões futuras;
* evitar documentos excessivamente longos;
* permitir reutilização de playbooks em outros perfis de hardware.

## Consequências positivas

* Melhor organização da documentação operacional.
* Fluxo de instalação mais claro.
* Facilidade para localizar procedimentos específicos.
* Menor impacto de alterações em uma etapa isolada.
* Possibilidade de reutilizar fases completas em diferentes perfis.

## Consequências negativas

* A quantidade de arquivos será maior.
* Alterações de fluxo poderão exigir renumeração de documentos.
* Será necessário manter o índice dos playbooks atualizado.

Esses custos são considerados aceitáveis em troca da maior clareza e escalabilidade.

## Alternativas consideradas

### Um único playbook de instalação

Rejeitada por resultar em documentos extensos e difíceis de manter.

### Organização apenas por assunto

Rejeitada porque não evidencia a sequência operacional esperada durante uma instalação completa.

### Numeração global de todos os playbooks

Exemplo:

```text
001-...
002-...
003-...
```

Rejeitada porque dificultaria a expansão de grupos independentes e reduziria a legibilidade.

## Regras de aplicação

Todo novo playbook deverá:

* pertencer exatamente a um diretório funcional;
* possuir um objetivo único e bem definido;
* terminar com uma etapa de verificação;
* indicar claramente o próximo playbook recomendado, quando aplicável.

Playbooks não devem duplicar conteúdo. Quando um procedimento depender de outro, deverá referenciá-lo em vez de repetir instruções.

## Lições aprendidas

Uma estrutura hierárquica baseada em fases favorece a manutenção de longo prazo e reduz a complexidade percebida da documentação operacional.
