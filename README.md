# Linux Workstation

Uma plataforma pessoal para construção, manutenção e reprodução de uma workstation Linux moderna baseada em Arch Linux.

Este projeto trata a infraestrutura de uma máquina pessoal com princípios normalmente aplicados a projetos profissionais de software e infraestrutura: decisões documentadas, mudanças versionadas, automação testável e procedimentos reproduzíveis.

O primeiro perfil de hardware suportado é o **Dell Latitude E5470**.

## Objetivo

Construir um ambiente Linux que seja:

* reproduzível;
* documentado;
* seguro;
* simples de manter;
* modular;
* compreensível antes de ser automatizado;
* preparado para desenvolvimento com containers.

O repositório é a fonte da verdade. Toda configuração relevante da workstation deve estar documentada ou representada por arquivos versionados.

## Princípios

1. Documentação antes da implementação.
2. Automação depois do entendimento.
3. Mudanças pequenas, testáveis e reversíveis.
4. Preferência por ferramentas oficiais e consolidadas.
5. Decisões arquiteturais registradas em ADRs.
6. Scripts idempotentes sempre que possível.
7. Comandos destrutivos exigem validação explícita.
8. Toda implementação importante deve possuir uma forma de verificação.
9. Problemas encontrados devem gerar documentação ou melhorias.
10. Novas ideias entram no roadmap e não interrompem a implementação sem justificativa técnica.

## Arquitetura inicial

A primeira implementação utiliza:

* Arch Linux;
* UEFI;
* GPT;
* systemd-boot;
* LUKS2;
* Btrfs;
* Snapper;
* Hyprland;
* PipeWire;
* NetworkManager;
* Docker;
* Docker Compose;
* Dev Containers;
* Zsh;
* Oh My Zsh;
* Starship;
* chezmoi.

O sistema utilizará a GPU Intel integrada como padrão. A GPU AMD dedicada permanecerá disponível para uso sob demanda.

## Organização

```text
linux-workstation/
├── .github/
│   └── workflows/
├── docs/
│   ├── adr/
│   ├── architecture.md
│   ├── changelog.md
│   ├── glossary.md
│   ├── maintenance.md
│   ├── recovery.md
│   ├── roadmap.md
│   ├── standards.md
│   └── troubleshooting.md
├── examples/
├── packages/
├── playbooks/
├── profiles/
│   └── dell-latitude-e5470/
├── scripts/
├── system/
├── tests/
├── .gitignore
├── LICENSE
├── Makefile
└── README.md
```

### `docs/adr/`

Registra decisões arquiteturais, seus contextos, alternativas e consequências.

### `playbooks/`

Contém procedimentos reproduzíveis para instalação, configuração, recuperação e manutenção.

### `packages/`

Mantém listas declarativas de pacotes utilizados no sistema.

### `profiles/`

Contém configurações e particularidades de cada perfil de hardware.

### `scripts/`

Contém automações idempotentes ou semiautomatizadas.

### `system/`

Armazena configurações do sistema operacional e serviços.

### `tests/`

Contém verificações para validar o estado da workstation.

### `examples/`

Reúne exemplos reutilizáveis de configurações, containers e ferramentas.

## Perfil inicial

O primeiro perfil suportado é:

```text
profiles/dell-latitude-e5470/
```

Hardware principal:

* Dell Latitude E5470;
* firmware UEFI;
* SSD dedicado ao Arch Linux;
* Intel HD Graphics 520;
* AMD Radeon R7 M360;
* Wi-Fi Qualcomm Atheros.

Não haverá dual boot.

## Estratégia de desenvolvimento

As ferramentas fundamentais permanecerão instaladas no host:

* Git;
* Docker;
* Docker Compose;
* Visual Studio Code;
* OpenSSH.

SDKs, CLIs e runtimes de desenvolvimento deverão permanecer preferencialmente em Dev Containers.

Isso inclui, entre outros:

* .NET;
* Node.js;
* Terraform;
* kubectl;
* Helm;
* AWS CLI;
* runtimes Python utilizados pelos projetos.

## Status

O projeto está em desenvolvimento.

A versão `v0.1.0-foundation` representa a conclusão da fundação estrutural e o congelamento da arquitetura inicial.

Nenhum playbook deve ser considerado estável até ser validado em uma instalação real.

## Como começar

A documentação deverá ser seguida nesta ordem:

1. Ler a arquitetura e os ADRs.
2. Identificar o perfil de hardware.
3. Preparar a mídia de instalação.
4. Executar os playbooks na ordem indicada.
5. Validar a instalação com os testes.
6. Registrar problemas e lições aprendidas.

Os playbooks de instalação serão adicionados progressivamente.

## Estados dos documentos

Os documentos podem utilizar os seguintes estados:

* `Draft`: conteúdo em elaboração;
* `Review`: pronto para revisão;
* `Stable`: validado em uma instalação real;
* `Deprecated`: mantido apenas como referência histórica.

## Contribuições

Toda mudança relevante deve:

1. respeitar os princípios do projeto;
2. possuir uma justificativa clara;
3. atualizar a documentação correspondente;
4. incluir ou atualizar verificações quando aplicável;
5. ser registrada por meio de commits pequenos e objetivos.

Decisões arquiteturais devem ser registradas em um ADR antes da implementação.

## Licença

Consulte o arquivo [`LICENSE`](LICENSE).
