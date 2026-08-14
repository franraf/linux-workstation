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

## Arquitetura atual

A workstation utiliza, entre outros componentes:

* Arch Linux;
* UEFI + GPT;
* systemd-boot;
* LUKS2;
* Btrfs;
* Hyprland;
* greetd + tuigreet;
* Waybar;
* PipeWire;
* NetworkManager;
* Docker + Compose + Buildx;
* Dev Containers;
* Git;
* Zsh + Oh My Zsh + Starship;
* Visual Studio Code oficial da Microsoft;
* Codex CLI;
* chezmoi para convergência de configuração de usuário;
* runner declarativo `scripts/workstation`.

O sistema utiliza a GPU Intel integrada como padrão. A GPU AMD dedicada permanece disponível para uso sob demanda.

## Organização

```text
linux-workstation/
├── .github/
│   └── workflows/
├── docs/
│   ├── adr/
│   ├── architecture.md
│   ├── roadmap.md
│   └── standards.md
├── dotfiles/
├── examples/
├── packages/
├── playbooks/
├── profiles/
│   └── dell-latitude-e5470/
├── scripts/
│   ├── lib/
│   └── workstation
├── system/
├── tests/
├── .chezmoiroot
├── .gitignore
├── LICENCE
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

Contém manifests, ordem de execução e particularidades de cada perfil de hardware.

### `scripts/lib/`

Contém comportamento reutilizável compartilhado pelos steps.

### `scripts/workstation`

É o runner de alto nível do repositório. Ele lê `profile.yaml` e `phase.yaml`, descobre fases e steps, mostra status e planos, executa fases de maneira supervisionada, persiste o ponto de retomada e preserva as confirmações implementadas pelos próprios steps.

### `system/`

Armazena configurações canônicas de sistema e serviços.

### `dotfiles/`

Armazena configurações canônicas de usuário que pertencem à workstation. O diretório `dotfiles/home` é aplicado pelo chezmoi usando este próprio repositório como source state.

### `tests/`

Contém gates estáticos, de integração e de runtime que validam o estado esperado.

### `examples/`

Reúne exemplos realmente reutilizáveis, como Dev Containers de referência.

## Perfil inicial

O primeiro profile suportado é:

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

Não há dual boot.

## Fases implementadas e validadas

```text
01-installation
02-system
03-desktop
04-development
```

Cada fase possui seu próprio `phase.yaml`, playbooks, scripts e gate final.

A Milestone 5 — Repository Automation está concluída. A próxima fase de implementação é `05-operations`.

## Estratégia de desenvolvimento

As ferramentas fundamentais permanecem instaladas no host, incluindo Git, Docker, VS Code, OpenSSH e ferramentas CLI globais.

SDKs, CLIs e runtimes específicos de projetos permanecem preferencialmente em Dev Containers.

Isso inclui, entre outros:

* .NET;
* Node.js;
* Terraform;
* kubectl;
* Helm;
* AWS CLI;
* runtimes Python utilizados pelos projetos.

## Runner do repositório

Depois de clonar o repositório, os principais comandos são:

```bash
make bootstrap
make status
make phases
make steps PHASE=04-development
make plan-phase PHASE=04-development
```

Execução e retomada supervisionadas:

```bash
make run-phase PHASE=04-development
make execution-status
make resume-plan
make resume
```

O runner nunca responde automaticamente confirmações destrutivas.

Validação portátil do repositório:

```bash
make validate-portable
```

## Status

As milestones de Installation, System, Desktop, Development e Repository Automation estão concluídas.

O trabalho atual está concentrado em **Operations**, seguido futuramente por Security.

A reconstrução integral a partir da ISO será exercitada em uma instalação real futura; não é simulada de forma destrutiva apenas para validar o runner.

Nenhum procedimento deve ser considerado estável somente porque existe no repositório; o status deve acompanhar a validação real correspondente.

## Conceitos arquiteturais

* **Architecture First:** decisões precedem implementações.
* **Documentation as Source of Truth:** o repositório representa o estado esperado da workstation.
* **Incremental Evolution:** mudanças são pequenas, verificáveis e reversíveis.
* **Single Responsibility:** cada artefato possui uma responsabilidade clara.
* **Capabilities over Implementations:** capacidades são permanentes; ferramentas podem ser substituídas.
* **Modular Configuration:** configurações são separadas por responsabilidade.
* **Validate Before Advancing:** cada fase termina com uma validação objetiva.
* **Profile-driven Orchestration:** manifests coordenam execução sem duplicar a implementação dos steps.

Consulte [`docs/architecture.md`](docs/architecture.md), [`docs/roadmap.md`](docs/roadmap.md) e os [Architecture Decision Records](docs/adr/) para detalhes.

## Como começar

1. Leia arquitetura, padrões e ADRs.
2. Identifique o profile de hardware.
3. Execute `make bootstrap` para descobrir o estado atual e a próxima ação segura.
4. Consulte fases e steps disponíveis.
5. Execute as fases pelo runner na ordem indicada.
6. Valide cada fase antes de avançar.
7. Registre problemas e lições aprendidas.

## Estados dos documentos

Os documentos podem utilizar:

* `Draft`;
* `Review`;
* `Stable`;
* `Deprecated`.

## Contribuições

Toda mudança relevante deve respeitar os princípios do projeto, possuir justificativa clara, atualizar a documentação correspondente e incluir ou atualizar verificações quando aplicável.

Decisões arquiteturais devem ser registradas em ADR antes da implementação.

## Licença

Consulte o arquivo [`LICENCE`](LICENCE).
