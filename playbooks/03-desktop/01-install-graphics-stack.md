---

title: Instalar a stack gráfica
version: 1.0
status: Draft
author: Rafael
last_review: 2026-07-31
related:

* architecture.md
* ADR-0002
* ADR-0003
* ADR-0004

---

# 01 — Instalar a stack gráfica

## Objetivo

Instalar e validar os componentes fundamentais necessários para execução de uma sessão gráfica baseada em Wayland.

Ao final deste playbook, a workstation possuirá a base gráfica necessária para instalação e execução do Hyprland.

---

# Pré-requisitos

* Fase **02-system** concluída e validada.
* Sistema atualizado.
* Pacman configurado.
* Hardware gráfico identificado.
* Acesso administrativo disponível.

---

# Resultado esperado

Ao concluir este playbook:

* os componentes fundamentais do Wayland estarão instalados;
* os drivers gráficos necessários estarão disponíveis;
* a aceleração gráfica estará funcional;
* o sistema estará preparado para instalação do compositor.

---

# Procedimento

## 1. Identificar o hardware gráfico

Confirme quais dispositivos gráficos estão presentes na workstation.

Identifique:

* GPU integrada;
* GPU dedicada, quando aplicável;
* fabricante de cada dispositivo;
* driver utilizado pelo kernel.

---

## 2. Definir a estratégia gráfica

Confirme qual dispositivo gráfico será utilizado como principal durante a sessão Wayland.

Em sistemas com múltiplas GPUs, documente a estratégia adotada para:

* renderização principal;
* aceleração gráfica;
* uso eventual da GPU secundária;
* economia de energia.

---

## 3. Instalar os componentes do Wayland

Instale os componentes fundamentais necessários para execução de aplicações e compositores Wayland.

Evite incluir neste playbook componentes específicos do Hyprland ou ferramentas de personalização do desktop.

---

## 4. Instalar os componentes gráficos

Instale os componentes correspondentes ao hardware identificado.

A seleção deverá seguir o perfil da workstation e as recomendações oficiais para o hardware utilizado.

---

## 5. Instalar suporte a aplicações legadas

Configure o suporte necessário para execução de aplicações que ainda dependam do protocolo X11 dentro da sessão Wayland.

Esse suporte não deverá substituir o Wayland como arquitetura gráfica principal.

---

## 6. Validar os módulos do kernel

Confirme que os módulos gráficos esperados foram carregados corretamente.

Verifique se não existem conflitos entre os dispositivos gráficos ou drivers disponíveis.

---

## 7. Validar a aceleração gráfica

Confirme que o sistema reconhece corretamente o hardware gráfico e que a aceleração está disponível.

Registre qualquer limitação específica do hardware.

---

## 8. Revisar os registros do sistema

Analise os registros relacionados ao subsistema gráfico.

Confirme que não existem erros críticos de inicialização, firmware ou carregamento de módulos.

---

# Verificação

Confirme que:

* o hardware gráfico foi identificado corretamente;
* os drivers esperados estão carregados;
* a aceleração gráfica está disponível;
* os componentes fundamentais do Wayland estão instalados;
* o suporte a aplicações X11 está disponível quando necessário;
* não existem erros gráficos críticos nos registros do sistema.

---

# Problemas comuns

## Dispositivo gráfico não identificado

Confirme que o dispositivo está habilitado no firmware e que o kernel possui suporte ao hardware.

---

## Driver incorreto carregado

Revise os módulos ativos e confirme que correspondem ao hardware identificado.

---

## Aceleração gráfica indisponível

Verifique a instalação dos componentes gráficos, a disponibilidade de firmware e os registros do kernel.

---

## Conflito entre GPUs

Revise a estratégia definida para sistemas híbridos e confirme qual dispositivo deve assumir a renderização principal.

---

## Aplicações X11 não executam

Confirme que a camada de compatibilidade prevista pelo projeto está instalada e operacional.

---

# Próximo playbook

Após validar a stack gráfica, prossiga para:

```text
02-install-compositor.md
```

---

# Referências

* Arch Wiki — Wayland
* Arch Wiki — Hardware video acceleration
* Arch Wiki — Intel graphics
* Arch Wiki — AMDGPU
* Arch Wiki — PRIME
* Documentação oficial do Hyprland

---

# Lições aprendidas

Registrar aqui particularidades do hardware gráfico, conflitos entre dispositivos, limitações de drivers ou ajustes necessários para futuras instalações.

