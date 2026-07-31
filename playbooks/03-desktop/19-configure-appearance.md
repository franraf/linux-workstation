---

title: Configurar aparência
version: 1.0
status: Draft
author: Rafael
last_review: 2026-07-31
related:

* architecture.md
* ADR-0002
* ADR-0003
* ADR-0004
* ADR-0005

---

# 19 — Configurar aparência

## Objetivo

Configurar a identidade visual da sessão gráfica, garantindo consistência entre os componentes do desktop.

Ao final deste playbook, aplicações, menus, barra de status, notificações, terminal, gerenciador de arquivos e tela de bloqueio compartilharão uma aparência coerente.

---

# Pré-requisitos

* Sessão gráfica configurada.
* Stack tipográfica instalada.
* Componentes funcionais do desktop instalados e configurados.

---

# Resultado esperado

Ao concluir este playbook:

* a identidade visual da workstation estará definida;
* temas, ícones e cursores estarão disponíveis;
* os componentes do desktop apresentarão aparência consistente;
* as configurações visuais estarão organizadas conforme a ADR-0005.

---

# Procedimento

## 1. Definir a identidade visual

Estabeleça os padrões visuais da workstation.

Considere:

* paleta de cores;
* tipografia;
* espaçamentos;
* bordas;
* cantos;
* transparência;
* contraste;
* densidade da interface.

Evite introduzir variações visuais sem justificativa.

---

## 2. Organizar os recursos visuais

Mantenha temas, imagens, estilos e configurações organizados por responsabilidade.

Evite duplicar os mesmos valores em diversos componentes quando puderem ser compartilhados ou documentados em uma fonte central.

---

## 3. Configurar o tema das aplicações

Defina o tema utilizado pelas aplicações gráficas.

Considere a integração entre aplicações baseadas em diferentes toolkits.

Confirme que o tema possui suporte adequado aos modos claro ou escuro previstos pelo projeto.

---

## 4. Configurar o tema de ícones

Instale e configure o conjunto de ícones adotado pela workstation.

Valide a renderização no gerenciador de arquivos, nos menus e nas aplicações gráficas.

---

## 5. Configurar o cursor

Instale e configure o tema e o tamanho do cursor.

Confirme que a configuração é aplicada de forma consistente em aplicações Wayland e nas aplicações executadas por meio da camada de compatibilidade X11.

---

## 6. Configurar o plano de fundo

Defina o plano de fundo da sessão gráfica.

Mantenha o recurso versionado no repositório de dotfiles quando sua licença permitir redistribuição.

Recursos que não puderem ser versionados deverão possuir instruções claras de obtenção.

---

## 7. Integrar os componentes do desktop

Aplique a identidade visual aos componentes já configurados:

* sessão gráfica;
* barra de status;
* bloqueio da sessão;
* lançador de aplicações;
* central de notificações;
* emulador de terminal;
* gerenciador de arquivos.

A aparência não deverá alterar a responsabilidade funcional de cada componente.

---

## 8. Validar acessibilidade e legibilidade

Confirme que:

* textos possuem contraste suficiente;
* elementos importantes são distinguíveis;
* fontes permanecem legíveis;
* estados de foco, alerta e erro são visualmente identificáveis;
* a aparência não prejudica a operação da workstation.

---

## 9. Testar a consistência visual

Reinicie a sessão gráfica e revise os componentes em conjunto.

Confirme que não existem diferenças inesperadas de tema, fonte, cursor ou escala.

---

# Verificação

Confirme que:

* a identidade visual está aplicada;
* temas, ícones e cursor são carregados corretamente;
* aplicações Wayland e X11 apresentam aparência compatível;
* a tipografia é consistente;
* o plano de fundo é carregado;
* os componentes permanecem funcionais;
* não existem erros relacionados aos recursos visuais.

---

# Problemas comuns

## Tema não aplicado em algumas aplicações

Identifique o toolkit utilizado pela aplicação e revise a integração correspondente.

---

## Cursor inconsistente

Confirme que o tema e o tamanho estão definidos nos mecanismos necessários para Wayland e X11.

---

## Ícones ausentes

Verifique se o tema de ícones está instalado e se possui os recursos esperados.

---

## Fontes inconsistentes

Revise a stack tipográfica e as configurações específicas dos componentes.

---

## Recursos não encontrados

Confirme os caminhos utilizados e se os arquivos necessários estão disponíveis no sistema ou nos dotfiles.

---

## Baixo contraste ou legibilidade

Ajuste a paleta e os estilos antes de considerar a configuração concluída.

A estética não deve comprometer a utilização.

---

# Próximo playbook

Após validar a aparência, prossiga para:

```text
20-desktop-validation.md
```

---

# Referências

* Arch Wiki — Uniform look for Qt and GTK applications
* Arch Wiki — Cursor themes
* Arch Wiki — Icons
* Arch Wiki — Fonts
* XDG Base Directory Specification
* ADR-0005 — Modularize Configuration by Capability

---

# Lições aprendidas

Registrar aqui ajustes na identidade visual, incompatibilidades entre toolkits, problemas de contraste ou recursos que exijam tratamento especial.
