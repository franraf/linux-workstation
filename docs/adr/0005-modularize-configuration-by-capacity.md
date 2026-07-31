---

title: ADR-0005 — Modularizar configurações por capacidade
status: Accepted
date: 2026-07-31
deciders:

* Rafael

---

# ADR-0005 — Modularizar configurações por capacidade

## Status

Accepted

---

## Contexto

À medida que a workstation evolui, os componentes do sistema passam a possuir configurações cada vez mais complexas.

Arquivos monolíticos dificultam:

* manutenção;
* revisão de mudanças;
* testes;
* automação;
* reutilização de partes da configuração.

Além disso, o projeto adota uma arquitetura baseada em capacidades, onde cada playbook entrega uma única capacidade da workstation.

Essa organização também deve ser refletida nos arquivos de configuração.

---

## Decisão

As configurações da workstation deverão ser organizadas de forma modular, agrupando arquivos por responsabilidade ou capacidade.

Sempre que suportado pela ferramenta utilizada, um arquivo principal deverá atuar apenas como ponto de entrada, delegando a configuração para módulos menores.

Cada módulo deverá possuir uma única responsabilidade claramente identificável.

---

## Consequências

### Positivas

* Configurações menores e mais legíveis.
* Alterações mais fáceis de revisar no Git.
* Menor risco de conflitos durante modificações.
* Reutilização de módulos entre perfis ou ambientes.
* Facilidade para automação.
* Melhor isolamento entre capacidades da workstation.

### Negativas

* Maior quantidade de arquivos.
* Estrutura inicial ligeiramente mais complexa.
* Necessidade de definir convenções para organização dos módulos.

---

## Diretrizes

Sempre que possível:

* separar configurações por domínio de responsabilidade;
* evitar arquivos monolíticos;
* utilizar mecanismos nativos de inclusão (`include`, `source`, equivalentes);
* manter nomes consistentes e descritivos;
* preservar baixo acoplamento entre módulos.

---

## Exemplos

### Hyprland

```text
~/.config/hypr/

hyprland.conf

conf.d/
    monitors.conf
    input.conf
    environment.conf
    autostart.conf
    workspaces.conf
    keybindings.conf
    window-rules.conf
    animations.conf
```

---

### Waybar

```text
~/.config/waybar/

config
style.css

modules/
    cpu.jsonc
    memory.jsonc
    network.jsonc
    battery.jsonc
```

---

### Kitty

```text
~/.config/kitty/

kitty.conf

conf.d/
    appearance.conf
    fonts.conf
    keyboard.conf
```

---

### Docker

```text
docker/

compose.yaml

compose.d/
    databases.yaml
    monitoring.yaml
    development.yaml
```

---

## Relação com outras ADRs

* ADR-0004 estabelece que cada playbook possui uma única responsabilidade.
* ADR-0005 aplica o mesmo princípio às configurações da workstation.

---

## Revisão futura

Esta decisão poderá ser revisada caso alguma ferramenta utilizada não ofereça mecanismos adequados para modularização ou quando a divisão em módulos introduzir complexidade superior aos benefícios obtidos.
