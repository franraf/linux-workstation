# Playbooks

## Objetivo

Os playbooks descrevem os procedimentos operacionais do projeto **linux-workstation**.

Eles documentam, de forma reproduzível, todas as etapas necessárias para instalar, configurar, manter e recuperar uma workstation baseada em Arch Linux.

Os playbooks são escritos para serem executados por pessoas. A automação é consequência dessa documentação, nunca seu substituto.

---

# Filosofia

Os playbooks seguem os princípios definidos pelos ADRs do projeto.

Em especial:

* documentação antes da implementação;
* automação depois do entendimento;
* mudanças pequenas e verificáveis;
* procedimentos reproduzíveis;
* validação ao final de cada etapa.

Sempre que um procedimento for automatizado, sua versão manual continuará documentada.

---

# Organização

Os playbooks são organizados por fase do ciclo de vida da workstation.

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

Cada diretório possui uma responsabilidade específica.

## 01-installation

Procedimentos para instalação inicial do sistema operacional.

Exemplos:

* preparação da mídia de instalação;
* configuração da UEFI;
* particionamento;
* criptografia;
* criação do sistema de arquivos;
* instalação do Arch Linux;
* configuração inicial;
* instalação do bootloader.

## 02-system

Configuração dos componentes fundamentais do sistema.

Exemplos:

* NetworkManager;
* PipeWire;
* BlueZ;
* Snapper;
* fstrim;
* OpenSSH;
* ferramentas essenciais.

## 03-desktop

Construção do ambiente gráfico.

Exemplos:

* Hyprland;
* Waybar;
* Kitty;
* Rofi;
* Hyprlock;
* Hypridle;
* Thunar.

## 04-development

Preparação da workstation para desenvolvimento de software.

Exemplos:

* Docker;
* Docker Compose;
* Visual Studio Code;
* Dev Containers;
* chezmoi.

## 05-maintenance

Procedimentos recorrentes de manutenção.

Exemplos:

* atualização do sistema;
* limpeza de caches;
* gerenciamento de snapshots;
* verificações de integridade;
* manutenção preventiva.

## 06-recovery

Procedimentos para recuperação do sistema.

Exemplos:

* recuperação do boot;
* restauração de snapshots;
* desbloqueio manual do LUKS;
* recuperação via ambiente live.

---

# Ordem de execução

Os playbooks deverão ser executados na ordem indicada pela numeração dos diretórios e dos arquivos.

A numeração representa a sequência recomendada de execução, não uma dependência técnica obrigatória.

Quando um playbook depender de outro, essa dependência deverá ser explicitamente indicada no documento.

---

# Estrutura dos playbooks

Todo playbook deverá possuir, quando aplicável, as seguintes seções:

1. Objetivo
2. Pré-requisitos
3. Procedimento
4. Verificação
5. Problemas comuns
6. Próximo playbook
7. Referências
8. Lições aprendidas

A ordem poderá ser adaptada quando necessário, desde que a consistência entre os documentos seja preservada.

---

# Validação

Nenhum playbook é considerado concluído apenas porque todos os comandos foram executados.

Ao final de cada procedimento deverá existir uma forma objetiva de verificar o resultado.

A validação pode incluir:

* comandos de inspeção;
* análise de arquivos gerados;
* confirmação do estado do sistema;
* execução de scripts de teste;
* reinicialização controlada.

---

# Tratamento de problemas

Caso ocorra uma falha durante a execução de um playbook:

1. interrompa o procedimento;
2. identifique a causa do problema;
3. corrija a documentação, se necessário;
4. registre a solução em `docs/troubleshooting.md`, quando aplicável;
5. atualize as lições aprendidas do playbook correspondente.

O objetivo é que cada incidente torne a documentação mais completa.

---

# Relação com automações

Os scripts presentes em `scripts/` deverão implementar procedimentos já descritos pelos playbooks.

Nenhum script deverá existir sem que o procedimento manual correspondente esteja documentado e compreendido.

Sempre que houver divergência entre um script e um playbook, o playbook deverá ser revisado e ambos deverão voltar a representar o mesmo processo.

---

# Perfis de hardware

Os playbooks descrevem o fluxo geral do projeto.

Quando um procedimento depender de características específicas de um equipamento, essas particularidades deverão ser documentadas em `profiles/<hardware>/`.

Assim, o mesmo playbook poderá ser reutilizado por diferentes perfis de hardware.

---

# Convenções

Os playbooks seguem as convenções definidas em:

* `docs/standards.md`
* `docs/architecture.md`
* `docs/adr/`

Mudanças estruturais na organização dos playbooks deverão ser registradas por meio de um novo ADR.

---

# Estado atual

Atualmente, os diretórios de playbooks representam a estrutura planejada do projeto.

Os procedimentos serão adicionados e validados progressivamente durante a construção da workstation.

---

# Próximos passos

A sequência inicial prevista para a instalação é:

1. `01-prepare-install-media.md`
2. `02-configure-firmware.md`
3. `03-partition-disk.md`
4. `04-create-luks.md`
5. `05-create-btrfs.md`
6. `06-mount-filesystems.md`
7. `07-install-base-system.md`
8. `08-configure-system.md`
9. `09-install-bootloader.md`
10. `10-first-boot.md`

Cada etapa deverá ser concluída e validada antes do início da próxima.

---

# Lições aprendidas

Os playbooks constituem a documentação operacional do projeto. Sua principal função é garantir que uma instalação possa ser reproduzida de forma previsível, auditável e independente da memória do mantenedor.
