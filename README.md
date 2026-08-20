<p align="center">
  <img src="documentos/assets/readme-banner.svg" alt="SmartSupply - Painel de Compras Inteligente para o TOTVS Protheus" width="100%">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/ERP-TOTVS%20Protheus-441c7d?style=for-the-badge" alt="TOTVS Protheus">
  <img src="https://img.shields.io/badge/linguagem-AdvPL%20%7C%20TLPP-6b31b0?style=for-the-badge" alt="AdvPL e TLPP">
  <img src="https://img.shields.io/badge/m%C3%B3dulo-Compras%20(SIGACOM)-8256b9?style=for-the-badge" alt="Módulo Compras">
  <img src="https://img.shields.io/badge/licenciamento-Supabase-cd1f92?style=for-the-badge" alt="Licenciamento via Supabase">
</p>

O **SmartSupply** é um addon para o TOTVS Protheus que analisa o histórico de consumo, estoque e lead time dos produtos e sugere **o que comprar, de quem e em que quantidade** — reduzindo a formação manual de pedidos de compra e o risco de ruptura ou excesso de estoque.

Este repositório contém o código-fonte AdvPL/TLPP do addon, a documentação funcional completa e as customizações específicas de cada cliente atendido.

> 📘 Este README cobre a **instalação, configuração e manutenção técnica** do addon. Para entender **como o SmartSupply funciona por dentro** (fórmulas, telas, exemplos), veja a [documentação funcional completa](#documentação-completa).

---

## Sumário

- [O que o SmartSupply resolve](#o-que-o-smartsupply-resolve)
- [Estrutura do repositório](#estrutura-do-repositório)
- [Pré-requisitos](#pré-requisitos)
- [Instalação](#instalação)
- [Configuração inicial (assistente)](#configuração-inicial-assistente)
- [Parâmetros internos (MV_X_PNC\*)](#parâmetros-internos-mv_x_pnc)
- [Estruturas de dados próprias](#estruturas-de-dados-próprias)
- [Uso no dia a dia (atalhos)](#uso-no-dia-a-dia-atalhos)
- [Atualização de versão](#atualização-de-versão)
- [Customização por cliente](#customização-por-cliente)
- [Documentação completa](#documentação-completa)
- [Padrões de desenvolvimento](#padrões-de-desenvolvimento)
- [Suporte](#suporte)

---

## O que o SmartSupply resolve

Times de compras geralmente decidem o que comprar em planilhas, cruzando estoque, histórico de vendas e prazos de entrega manualmente. Isso é lento e sujeito a erro: falta produto crítico enquanto sobra produto de baixo giro.

O SmartSupply automatiza essa análise dentro do próprio Protheus, calculando a sugestão de compra produto a produto e apresentando tudo num painel único, com:

- **Sugestão de compra automática**, considerando consumo médio, lead time do fornecedor, estoque disponível e cobertura desejada;
- **Arredondamentos inteligentes** (lote mínimo, lote econômico, múltiplo de embalagem);
- **Compras em rede multi-filial**, com cálculo individual por filial ou consolidado (pool);
- **Análise reversa de estruturas**, para calcular a necessidade de matérias-primas/componentes a partir da demanda dos produtos acabados;
- **Classificação automática por giro** (crítico, alto, médio, baixo, sem giro);
- **Radar de sazonalidade** e **alertas automáticos de ruptura**;
- **Carrinho de compras** e geração do pedido diretamente do painel, com **layout de impressão configurável**.

O motor de cálculo roda por empresa/filial (`cEmpAnt`) e mantém suas próprias tabelas de apoio fora do dicionário padrão do Protheus, para não competir com a base fiscal/contábil do cliente.

## Estrutura do repositório

```
central-compras/
├── src/                      # Código-fonte do addon (o produto em si)
│   ├── main/                 # Rotina principal (GMPAICOM) e motor de cálculo
│   ├── dbstruct/              # Assistente de configuração e estruturas próprias (JSGLBPAR, JSPNCSTR)
│   ├── supabase/              # Integração de licenciamento/telemetria (JSSUPABASE, JSSUPPORT)
│   ├── report/                # Impressão do pedido de compra (layout configurável)
│   ├── utils/                 # Funções utilitárias
│   ├── html/                  # Fragmentos HTML usados pelo painel (ex.: alerta de ruptura)
│   └── images/                # Ícones e bitmaps usados nas telas
├── <Cliente>/sigacom/pe/      # Pontos de Entrada específicos de cada cliente (ex.: Alegria, Brasilflex, Madecenter)
├── documentos/                 # Documentação funcional (HTML/PDF) e roadmap
├── includes/                   # Cópia local dos .ch padrão do Protheus, para o editor/linter
├── patch/                       # Pacotes de patch (.ptm) pré-requisito de algumas versões
├── upddistr/                    # Pacotes de atualização de dicionário (UPDDISTR) por versão
├── reference/                   # Fontes de referência (não fazem parte do addon compilado)
└── descontinuados/               # Código antigo mantido apenas como histórico
```

> O código do addon em si vive só em `src/`. As pastas com nome de cliente contêm **apenas** os Pontos de Entrada daquele cliente — nunca lógica do produto (veja [Customização por cliente](#customização-por-cliente)).

## Pré-requisitos

- Ambiente **TOTVS Protheus** com o módulo **Compras (SIGACOM)** ativo.
- **VS Code** com a extensão **TOTVS Language Server** (mesma usada para compilar/depurar qualquer fonte AdvPL/TLPP deste ambiente).
- Acesso de compilação ao AppServer/RPO do ambiente de destino.
- Uma conta/contrato **SmartSupply ativo na plataforma web (Supabase)** da INAN Soluções — é o que libera o uso da ferramenta (veja [Configuração inicial](#configuração-inicial-assistente)). Sem contrato válido, o addon abre em modo trial ou fica bloqueado.

## Instalação

1. **Clone o repositório** e abra a pasta no VS Code com a extensão TOTVS Language Server configurada para o seu ambiente (mesmo processo usado para qualquer outro fonte AdvPL do Protheus).
2. **Compile os fontes de `src/`** para o RPO do ambiente — não existe um `.PRJ`/manifesto único neste repositório; compile a pasta `src/` (ou os arquivos alterados) diretamente pela extensão.
3. Se o cliente tiver uma pasta própria neste repositório (ex.: `Brasilflex/sigacom/pe/`), **compile também os Pontos de Entrada dessa pasta** — eles complementam o comportamento padrão do addon para aquele cliente específico.
4. **Registre um item de menu** no Configurador (SIGA_C), módulo **Compras (SIGACOM)**, apontando para a rotina **`U_GMPAICOM`**.
5. Acesse o novo item de menu. Na primeira execução — ou sempre que faltar alguma estrutura interna — o **assistente de configuração** abre automaticamente (veja a seguir).

## Configuração inicial (assistente)

Ao abrir a rotina pela primeira vez (ou quando alguma parte da configuração estiver pendente), o SmartSupply chama automaticamente a função **`U_JSGLBPAR`**, que apresenta um assistente guiado em 5 etapas. O mesmo assistente pode ser reaberto a qualquer momento com o atalho **Alt+F11**, dentro da rotina principal.

| Etapa | Nome | O que faz |
|---|---|---|
| 1 | **Status do banco web** | Testa a conexão com a plataforma Supabase da INAN Soluções e identifica o cliente pelo cadastro do ambiente. |
| 2 | **Status do contrato** | Mostra se o contrato está ativo, em trial (avaliação) ou vencido. |
| 3 | **Parâmetros internos** | Cria automaticamente, no Configurador, todos os parâmetros `MV_X_PNC*` que ainda não existirem, já com valores padrão. |
| 4 | **Dicionário de dados** | Cria ou atualiza as tabelas próprias do SmartSupply e seus índices, comparando a estrutura esperada pela versão atual com a estrutura física do banco. |
| 5 | **Finalização** | Conclui o assistente e grava a versão do dicionário aplicada. |

Cada etapa só avança quando a anterior é resolvida com sucesso — se a etapa 4 falhar para alguma tabela (por exemplo, impossibilidade de alterar a estrutura no banco), o assistente aponta exatamente qual tabela/índice falhou.

Não é preciso preencher nada manualmente nas etapas 3 e 4: elas leem a definição de estrutura direto do código-fonte (`U_JSGETSTR`/`U_JSTBLIDX`) e ajustam o ambiente para bater com ela.

## Parâmetros internos (MV_X_PNC\*)

Os parâmetros `MV_X_PNC01` a `MV_X_PNCxx` controlam o comportamento do motor de cálculo (fórmula de sugestão de compra, índices de formação de preço, aliases de tabelas próprias, etc.). Todos são criados automaticamente pelo assistente com um valor padrão sensato — você só precisa ajustá-los se o comportamento padrão não atender ao cliente.

Os mais relevantes para revisão de negócio (os demais são internos e raramente precisam de ajuste manual):

| Parâmetro | Uso |
|---|---|
| `MV_X_PNC01` | Fórmula da sugestão de compra (combina lead time, projeção de estoque e consumo médio). |
| `MV_X_PNC05` a `MV_X_PNC10` | Índices de formação de preço de venda (lucro líquido, despesas, impostos, inadimplência, custo financeiro). |
| `MV_X_PNC11` | Tipo de análise de fornecedor: pelo fornecedor padrão ou pelo produto. |
| `MV_ENVPED` | Habilita/desabilita o envio automático de e-mail ao fornecedor na geração do pedido. |

> Parâmetros que guardam **alias de tabela própria** (ex.: `MV_X_PNC02`, `MV_X_PNC03`, `MV_X_PNC04`, `MV_X_PNC16`) são definidos automaticamente pelo assistente — não edite o conteúdo deles manualmente, exceto orientado pela equipe responsável pelo addon.

## Estruturas de dados próprias

O SmartSupply mantém tabelas próprias, **fora do dicionário de dados padrão do Protheus**, para não interferir na base fiscal/contábil do cliente. Todas são identificadas por empresa (`cEmpAnt`) e mantidas automaticamente pela etapa 4 do assistente:

| Tabela | Conteúdo |
|---|---|
| `PNC_CONFIG_<empresa>` | Configurações gerais do motor de cálculo (critério de análise, dias de projeção, locais considerados, etc.). |
| `PNC_RVCALC_<empresa>` | Resultado da análise reversa de estruturas por produto, usado pela grade principal do painel. |
| `PNC_RVTRC_<empresa>` | Rastro (trace) do sequenciamento de cálculo da análise reversa, usado na tela de conferência do cálculo. |
| `PNC_PROD_<empresa>` | Snapshot diário de índices por produto, consumido pelo painel principal. |

## Uso no dia a dia (atalhos)

Dentro da rotina principal (`U_GMPAICOM`), estes atalhos aceleram o trabalho do comprador:

| Atalho | Ação |
|---|---|
| `Alt+F11` | Reabre o assistente de configuração. |
| `F4` | Roda a análise/MRP e recalcula as sugestões de compra. |
| `F5` | Atualiza os dados exibidos na tela. |
| `F12` | Gerencia os perfis de cálculo (parâmetros de análise por perfil). |
| `Ctrl+F11` | Abre o cadastro de notificações internas exibidas na Central de Notificações. |
| `F6` | Consulta documentos/preços do produto selecionado na grade. |

## Atualização de versão

Ao atualizar os fontes de `src/` para uma nova versão:

1. **Recompile** os fontes alterados (extensão TOTVS Language Server).
2. **Reabra o assistente** (`Alt+F11` ou reabrindo a rotina) e avance até a etapa **Dicionário de Dados** — ele detecta sozinho qualquer campo/índice novo e ajusta as tabelas próprias sem perder dados existentes.
3. Se a atualização trouxer um pacote de dicionário padrão do Protheus (campos em tabelas como `SB1`, `SA2` etc.), aplique o pacote **UPDDISTR** correspondente em `upddistr/` pelo Configurador antes de recompilar.
4. Confira `documentos/smartsupply-painel-de-compras.pdf` e o roadmap em `documentos/` para saber o que mudou na prática para o usuário final.

## Customização por cliente

Cada cliente atendido tem sua própria pasta na raiz do repositório (ex.: `Alegria/`, `Brasilflex/`, `Madecenter/`), seguindo o padrão:

```
<Cliente>/sigacom/pe/PEPNCxx.prw
```

Esses arquivos são **Pontos de Entrada** — eles ligam em pontos específicos do fluxo padrão do SmartSupply para acomodar uma regra de negócio exclusiva daquele cliente, sem alterar o código-fonte compartilhado em `src/`. Ao criar uma regra específica de um cliente, o Ponto de Entrada é sempre o lugar certo — nunca edite `src/` para resolver um caso de um cliente só.

## Documentação completa

Para entender o SmartSupply em linguagem simples — fórmulas, exemplos numéricos, telas e fluxos, sem jargão técnico — consulte:

- **[documentos/smartsupply-painel-de-compras.pdf](documentos/smartsupply-painel-de-compras.pdf)** (ou a versão [.html](documentos/smartsupply-painel-de-compras.html)) — o guia funcional completo, com todos os conceitos do motor de cálculo, o painel do dia a dia, sazonalidade, alertas de ruptura e o pedido de compra configurável.
- **[documentos/smartsupply-roadmap-nova-jornada-compras.pdf](documentos/smartsupply-roadmap-nova-jornada-compras.pdf)** — roadmap da evolução da ferramenta.

## Padrões de desenvolvimento

Este repositório segue convenções específicas de AdvPL/TLPP documentadas em [`.claude/CLAUDE.md`](.claude/CLAUDE.md) — vale a pena ler antes de contribuir com código. Os pontos mais importantes:

- Limite de **10 caracteres** para nomes de função/método/variável (**8** para `User Function`, pelo prefixo `U_`).
- Todo arquivo `.prw`/`.prg`/`.prx`/`.tlpp`/`.ch` deve estar em **CP-1252** — nunca UTF-8.
- Uso de `User Function`/`Static Function` apenas — `Function` (escopo público do padrão) é proibido em customizações.
- Conformidade com as regras **SonarQube** de AdvPL/TLPP (segurança, performance, APIs legadas).

## Suporte

SmartSupply é desenvolvido e mantido pela **INAN Soluções**. Dúvidas sobre licenciamento, contrato ou uso da ferramenta devem ser direcionadas à equipe responsável pelo addon no ambiente do cliente.
