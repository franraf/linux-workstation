---
title: Configurar lançador de aplicações
version: 1.1
status: Draft
author: Rafael
last_review: 2026-08-12
related:

* architecture.md
* ADR-0002
* ADR-0004
* ADR-0005
* ADR-0006

---

# 15 — Configurar lançador de aplicações

## Objetivo

Configurar o Rofi como lançador de aplicações da workstation, integrando-o à sessão gráfica sem introduzir conflitos de teclado ou responsabilidades visuais que pertencem à etapa de aparência.

---

# Pré-requisitos

* Sessão gráfica configurada.
* Rofi instalado.

---

# Resultado esperado

Ao concluir este playbook:

* o Rofi estará disponível sob demanda;
* os modos `drun` e `run` estarão funcionais;
* aplicações poderão ser localizadas por arquivos `.desktop`;
* o atalho global estará registrado no fragmento canônico de keybindings;
* não existirão bindings internos duplicados.

---

# Procedimento

## 1. Organizar a configuração

Utilize `~/.config/rofi/config.rasi` para comportamento do launcher.

A identidade visual final deverá ser tratada em `19-configure-appearance.md`.

## 2. Configurar modos

Habilite os modos necessários:

```text
drun
run
```

O modo `drun` será a interface principal para aplicações instaladas.

## 3. Preservar bindings internos válidos

Evite redefinir atalhos padrão do Rofi para ações incompatíveis.

Não configurar simultaneamente:

```text
kb-row-left = Left,Control+b
kb-row-right = Right,Control+f
```

porque `Left`, `Right`, `Control+b` e `Control+f` já podem estar associados à edição do texto de pesquisa.

Antes de adicionar novos bindings, utilize:

```text
rofi -list-keybindings
```

para verificar conflitos.

## 4. Integrar ao Hyprland

Registre o atalho no fragmento canônico:

```text
~/.config/hypr/conf.d/70-keybindings.conf
```

A baseline utiliza:

```text
SUPER + SPACE → rofi -show drun
```

O arquivo `70-keybindings.conf` deve permanecer compartilhado pelas capacidades que adicionam atalhos globais; não crie fragments concorrentes para a mesma responsabilidade.

## 5. Validar

Execute:

```text
rofi -show drun
```

Confirme que o launcher abre sem mensagens de bindings duplicados e que aplicações podem ser iniciadas.

---

# Verificação

Confirme que:

* `rofi -show drun` abre sem erro;
* aplicações são listadas;
* pesquisa e navegação por teclado funcionam;
* Enter executa a aplicação selecionada;
* Escape fecha o launcher;
* `SUPER + SPACE` funciona dentro do Hyprland;
* o Rofi não é iniciado como daemon no autostart.

---

# Problemas comuns

## Binding duplicado

Compare `~/.config/rofi/config.rasi` com a saída de `rofi -list-keybindings` e remova redefinições conflitantes.

## Aplicações não aparecem

Confirme a existência e validade de arquivos `.desktop` nos diretórios XDG apropriados.

## Atalho global não funciona

Confirme que `70-keybindings.conf` é carregado pelo `hyprland.conf` e que não existe outro uso de `SUPER + SPACE`.

---

# Próximo playbook

```text
16-configure-notification-center.md
```

---

# Referências

* Documentação oficial do Rofi
* ADR-0005 — Modularizar configurações por capacidade
* ADR-0006 — Separação entre instalação e configuração

---

# Lições aprendidas

Bindings que parecem convenientes podem colidir com atalhos internos já reservados pelo Rofi. A validação deve consultar os bindings efetivos do binário instalado antes de personalizá-los.
