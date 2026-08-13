# Linux Workstation

Uma plataforma pessoal para construir, manter e reproduzir uma workstation Linux moderna baseada em Arch Linux.

O projeto aplica à máquina pessoal princípios de engenharia normalmente usados em software e infraestrutura: decisões arquiteturais documentadas, fontes versionadas, automação reproduzível, validação objetiva e evolução incremental.

O primeiro perfil de hardware suportado é o **Dell Latitude E5470**.

## Objetivo

Construir um ambiente Linux que seja reproduzível, documentado, seguro, modular, compreensível e simples de manter, com desenvolvimento baseado principalmente em containers.

O repositório representa o estado esperado da workstation. Configuração relevante não deve depender de ajustes manuais desconhecidos pelo projeto.

## Princípios

1. Decisões antes da implementação.
2. Automação depois do entendimento.
3. Mudanças pequenas, testáveis e reversíveis.
4. Preferência por fontes oficiais e consolidadas.
5. Exceções externas exigem justificativa documentada.
6. Scripts idempotentes sempre que possível.
7. Operações destrutivas exigem confirmação explícita.
8. Toda capacidade importante deve possuir validação.
9. Problemas encontrados devem melhorar documentação, scripts ou testes.
10. O roadmap registra ideias futuras sem interromper a fase atual.

## Arquitetura atual

A implementação principal utiliza:

* Arch Linux, UEFI e GPT;
* LUKS2 e Btrfs;
* systemd-boot e mkinitcpio;
* Snapper;
* NetworkManager, PipeWire e BlueZ;
* Hyprland, Waybar, Hyprlock, Hypridle, Rofi, SwayNC, Kitty e Thunar;
* greetd + tuigreet para autenticação da sessão;
* Git, Zsh, Oh My Zsh e Starship;
* Visual Studio Code oficial da Microsoft;
* Docker Engine, Compose, Buildx e Dev Containers;
* ferramentas CLI globais de produtividade;
* Codex CLI como ferramenta global de IA.

A GPU Intel integrada é o padrão. A GPU AMD dedicada permanece disponível para uso sob demanda.

## Organização

```text
linux-workstation/
├── .github/
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
│   └── lib/
├── system/
├── tests/
├── .gitignore
├── LICENCE
├── Makefile
└── README.md
```

### `docs/adr/`

Registra decisões arquiteturais, contexto, alternativas e consequências.

### `playbooks/`

Descreve os procedimentos e a intenção operacional de cada etapa.

### `packages/`

Contém as fontes declarativas de pacotes, organizadas por capacidade ou fase.

### `system/`

Contém configurações canônicas reproduzíveis da workstation e de ferramentas instaladas no host.

### `dotfiles/`

Contém configurações de usuário que fazem parte desta workstation e podem ser distribuídas para o home pelo respectivo script.

### `profiles/`

Contém manifests e orquestradores específicos de hardware. Os `run.sh` devem consumir fontes compartilhadas em vez de duplicá-las localmente.

### `scripts/lib/`

Contém funções Bash reutilizáveis para requisitos, pacotes, configuração de usuário, armazenamento e configuração do sistema.

### `tests/`

Contém gates estáticos e verificações de runtime. Uma fase só deve ser considerada concluída após sua validação aplicável.

### `examples/`

Reserva exemplos reutilizáveis que não sejam fontes canônicas de configuração.

## Perfil inicial

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

## Estratégia de desenvolvimento

O host contém apenas ferramentas globais da workstation. Runtimes e SDKs específicos de projetos permanecem preferencialmente em Dev Containers.

Ferramentas como `.NET`, Node.js, Terraform, kubectl, Helm, AWS CLI e runtimes Python de projeto não fazem parte da baseline do host.

O uso de pacotes oficiais do Arch continua sendo o padrão. Distribuições upstream são exceções explícitas e documentadas, como o Visual Studio Code oficial da Microsoft.

## Fases

O perfil atual está dividido em:

```text
01-installation
02-system
03-desktop
04-development
```

Cada fase possui um `phase.yaml`, playbooks correspondentes e uma etapa de validação. Fases futuras devem entrar no roadmap antes de serem implementadas.

## Estado atual

As fases 01, 02 e 03 já possuem implementação e validações versionadas. A fase 04 está implementada e aguarda validação completa na workstation antes de ser considerada concluída.

Consulte [`docs/roadmap.md`](docs/roadmap.md) para o estado das milestones e [`docs/architecture.md`](docs/architecture.md) para os limites arquiteturais.

## Como começar

1. Leia a arquitetura, os padrões e os ADRs.
2. Identifique o perfil de hardware.
3. Execute os playbooks na ordem declarada no `phase.yaml`.
4. Use os `run.sh` como orquestradores das fontes versionadas.
5. Execute o gate final da fase antes de avançar.
6. Registre qualquer divergência encontrada durante a execução real.

## Estados dos documentos

* `Draft`: conteúdo em elaboração ou ainda não validado completamente;
* `Review`: pronto para revisão;
* `Stable`: validado e adotado;
* `Deprecated`: mantido apenas como referência histórica.

## Contribuições

Toda mudança relevante deve respeitar os princípios do projeto, atualizar a documentação correspondente e incluir ou ajustar validações quando aplicável. Decisões arquiteturais devem ser registradas em ADR antes de sua implementação.

## Licença

Consulte o arquivo [`LICENCE`](LICENCE).
