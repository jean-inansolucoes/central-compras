---
name: smartsupply-doc-generator
description: Mantém sempre atualizada a documentação funcional do SmartSupply (Painel de Compras) em documentos/smartsupply-painel-de-compras.html e .pdf — o guia em linguagem simples, para leitores leigos, de como o motor de cálculo de compras, o painel, os relatórios e as integrações funcionam. Use esta skill SEMPRE que: (1) a skill protheus-notification-html for usada para comunicar uma nova funcionalidade, melhoria ou correção do SmartSupply (encadeamento automático — ver regra abaixo), (2) o usuário pedir explicitamente para atualizar/gerar/sincronizar a documentação do SmartSupply ou do Painel de Compras, ou (3) mudanças relevantes forem feitas em src/ (motor de cálculo, GMPAICOM, painel, relatórios JSCFPDCO/JSRLPDCO, notificações, Supabase) e for necessário refletir isso na documentação. Também use para gerar a documentação do zero caso os arquivos ainda não existam.
---

# Documentação Funcional do SmartSupply (HTML + PDF)

Mantém `documentos/smartsupply-painel-de-compras.html` (e o `.pdf` gerado a partir dele) como uma documentação viva, em português simples, sem jargão de programação, explicando como o SmartSupply funciona para quem nunca viu o código — times de supply chain, compradores, stakeholders de negócio.

## Regra de encadeamento com a skill de notificação

Sempre que a skill `protheus-notification-html` for invocada para comunicar uma **novidade real do SmartSupply** (nova funcionalidade, melhoria de motor de cálculo, correção de comportamento, nova tela/relatório) — e não um aviso puramente institucional (ex.: comunicado genérico, campanha, aviso de manutenção) — invoque esta skill em seguida, usando como escopo exatamente a mesma novidade que está sendo comunicada na notificação. O objetivo é que a documentação nunca fique defasada em relação ao que os usuários finais estão sendo avisados que mudou.

## Arquivos vivos (fonte da verdade — nunca recrie do zero)

- `documentos/smartsupply-painel-de-compras.html` — o documento fonte. **Sempre edite este arquivo diretamente** com a ferramenta Edit, nunca o reescreva inteiro do zero, exceto no bootstrap inicial (arquivo ainda não existe) ou numa reformulação estrutural pedida explicitamente pelo usuário.
- `documentos/smartsupply-painel-de-compras.pdf` — sempre gerado a partir do HTML pelo script desta skill. Nunca editado manualmente.

## Identidade visual (não alterar)

Paleta exclusiva (a mesma da skill `protheus-notification-html`): `#ffffff`, `#441c7d`, `#6b31b0`, `#a57dd0`, `#2e105d`, `#8256b9`, `#f41dab`, `#cd1f92`, `#b6acc7`.

O HTML já define essas cores como variáveis CSS (`:root`) e um sistema de componentes reutilizável — reaproveite as classes existentes em vez de inventar novas:

| Classe | Uso |
|---|---|
| `.cab-secao` (+ `.numero`) | Cabeçalho de cada seção numerada, com badge roxo |
| `.caixa.caixa-conceito` | Caixa lilás para explicar um conceito |
| `.caixa.caixa-exemplo` | Caixa pink para um exemplo numérico fictício |
| `.caixa.caixa-atencao` | Caixa amarela para ressalvas/avisos |
| `.formula` | Bloco escuro centralizado para fórmulas |
| `.passo` (+ `.bola`) | Lista numerada em círculos (passo a passo) |
| `.fluxo-etapas` | Etapas curtas lado a lado com seta — **só funciona bem com textos curtos**; para textos longos ou mais de ~4 itens, prefira `.passo` (ver "Bugs conhecidos" abaixo) |
| `.legenda-giro` / `.chip` | Legendas coloridas tipo pílula |
| `.grafico-barras` / `.barra-grupo` / `.barra` | Gráfico de barras em CSS puro — **sempre defina a altura da `.barra` em `px`, nunca em `%`** (ver "Bugs conhecidos") |
| `.arvore` | Diagrama simples de estrutura/árvore (usado na análise reversa) |
| `.sumario-lista` | Lista do sumário/índice |
| `.glossario` (`dl`/`dt`/`dd`) | Glossário de termos |
| `.rodape-pagina` | Rodapé com nome do documento + número da página (texto fixo, não é auto-numerado — ver seção de renumeração) |

Tom de escrita: leigo, direto, sem nomes de função/variável/tabela do AdvPL no corpo do texto (isso é documentação de negócio, não documentação técnica). Sempre que possível, ilustre com um exemplo numérico fictício simples e coerente com os já existentes no documento (ex.: reaproveitar os mesmos produtos fictícios — Tinta Acrílica Branca 18L, Cimento CP-II, Argamassa Pronta 20kg — quando fizer sentido, para dar continuidade ao "universo" de exemplos do documento).

## Fluxo de trabalho

### 1. Leia o HTML atual primeiro

Sempre leia `documentos/smartsupply-painel-de-compras.html` por completo antes de editar. É a linha de base viva — a estrutura de seções, a numeração do sumário e o "universo" de exemplos fictícios já existentes precisam ser respeitados e estendidos, não recriados.

Se o arquivo não existir ainda, pule para "Bootstrap / regeneração completa" no final deste documento.

### 2. Determine o escopo da mudança

- **Disparo em cadeia pela skill de notificação**: use a mesma novidade (funcionalidade/correção) que está sendo comunicada na notificação como escopo. Releia os arquivos-fonte em `src/` relacionados a essa novidade especificamente — não é necessário reanalisar o código inteiro.
- **Pedido manual do usuário sem contexto claro**: rode `git log --oneline -20 -- src/` para ver o que mudou desde a última atualização (compare com a "Versão X.Y — Mês/Ano" no rodapé da capa e da página de encerramento do HTML atual) e pergunte ao usuário qual mudança específica deve ser documentada, se não estiver óbvio.
- **Mudança ampla ou estrutural** (novo motor, reformulação grande de tela, múltiplas features acumuladas): siga o fluxo de "Bootstrap / regeneração completa" no lugar da atualização incremental.

### 3. Localize a seção correspondente no documento

Cada seção do sumário cobre um tema. Mapeamento de referência (pode mudar se o documento crescer — confira o sumário atual):

1. O problema que o SmartSupply resolve
2. Os ingredientes do cálculo (consumo médio, lead time, estoque disponível, cobertura, duração projetada, lotes)
3. A fórmula da sugestão de compra
4. Arredondamentos inteligentes (lote mínimo/econômico/embalagem)
5. Compras em rede — multi-filial (Individual vs. Pool)
6. Análise reversa de estruturas (matéria-prima/componentes)
7. Classificação por giro
8. O painel no dia a dia (telas, ações do comprador, carrinho)
9. Radar de sazonalidade
10. Alertas automáticos de ruptura
11. Pedido de compra sob medida (layout configurável)
12. Glossário

Se a novidade se encaixa em uma seção existente, edite-a lá. Se for um assunto genuinamente novo sem seção correspondente, crie uma nova seção — ver "Adicionando ou removendo uma seção" abaixo.

### 4. Edite o conteúdo

- Use a ferramenta Edit (nunca Write, exceto bootstrap) com trechos `old_string`/`new_string` pequenos e precisos.
- Refaça manualmente qualquer exemplo numérico afetado pela mudança e confira a conta com calma antes de gravar — igual foi feito nos exemplos originais (Tinta Acrílica, multi-filial, cimento/argamassa).
- Se a mudança envolve uma configuração/parâmetro novo, considere se vale a pena adicionar uma linha no Glossário (seção 12).
- Atualize a versão e a data no rodapé da capa (`.cartao-desc`/`.rodape-capa .info`) e na página de encerramento (`.capa-final p` final) — incremente a versão (ex.: 1.0 → 1.1 para atualização de conteúdo; 1.0 → 2.0 só se for reformulação estrutural) e ajuste "Mês de AAAA" para o mês/ano atual do sistema.

### 5. Adicionando ou removendo uma seção (quando necessário)

Isso exige renumeração em cascata — não pule nenhum destes pontos:

1. Insira/remova a entrada correspondente em `.sumario-lista` (número do círculo `.idx`, nome, descrição de uma linha, página `.pag`).
2. Insira/remova o(s) bloco(s) `<section class="pagina conteudo">` correspondente(s), com `.cab-secao .numero` no número certo.
3. Renumere `.cab-secao .numero` de **todas** as seções seguintes.
4. Recalcule e ajuste manualmente o número de página (`.pag` no sumário e o texto fixo dentro de cada `.rodape-pagina`) de **todas** as páginas a partir do ponto de inserção — esses números são texto fixo, não são auto-calculados. Só é possível saber os números finais corretos depois de gerar o PDF (passo 6) e contar as páginas reais; ajuste, gere de novo, confira de novo até bater.

### 6. Regenere o PDF e confira visualmente

```bash
python3 .claude/skills/smartsupply-doc-generator/scripts/build_pdf.py \
  --html documentos/smartsupply-painel-de-compras.html
```

O script gera o PDF em `documentos/smartsupply-painel-de-compras.pdf`, renderiza cada página em PNG numa pasta temporária (o caminho é impresso na saída) e aponta páginas de miolo com pouco texto (heurística de possível overflow/página quase vazia).

**Sempre releia com a ferramenta Read** — mesmo que a heurística não acuse nada — pelo menos:
- todas as páginas que você editou;
- a página imediatamente anterior e posterior a cada uma (uma mudança de texto pode empurrar conteúdo para a página seguinte);
- se o número total de páginas mudou em relação à versão anterior, o sumário inteiro e todos os rodapés (a numeração pode ter saído de sincronia).

Confira especificamente por:
- texto cortado ou vazando da caixa/página;
- página de miolo quase vazia (sinal de overflow — geralmente resolvido reduzindo levemente `padding`/`margin` da seção ou encurtando o texto, nunca compactando fonte abaixo de ~13px);
- elementos "invisíveis" (ver bug de `.barra` com `height:%` abaixo);
- números do sumário batendo com o número real impresso no rodapé de cada página.

### 7. Reporte ao usuário

Resuma em poucas frases: o que mudou no documento (seção, conteúdo), se a contagem de páginas mudou, e a versão nova gravada na capa/encerramento.

## Bugs conhecidos (já ocorreram na prática — evite reintroduzi-los)

- **Altura em `%` num filho flex sem altura explícita no pai renderiza invisível.** Isso já quebrou o gráfico de sazonalidade (`.barra`) numa primeira versão do documento: `height:38%` dentro de `.barra-grupo` (que tem altura `auto`) resolvia para zero. Corrigido usando `height` em `px` calculado proporcionalmente ao maior valor da série (ex.: maior barra = 125px, demais proporcionais). Sempre que criar um novo gráfico de barras, calcule os valores em `px`, nunca em `%`.
- **`.fluxo-etapas` com textos longos ou mais de ~4 itens quebra visualmente** (a seta `→` fica solta numa linha e o texto seguinte cai para a linha de baixo, porque o container não tem `flex-wrap` pensado para textos longos). Para sequências de passos com frases completas, use `.passo`/`.bola` (lista numerada vertical), que sempre renderiza bem independente do tamanho do texto.
- **`.sumario-lista > li` precisa de `flex-wrap:wrap`** — sem isso, o nome do item quebra caractere a caractere numa coluna estreita em vez da descrição cair para a linha de baixo. Já corrigido no CSS atual; não remova essa propriedade.
- **Números de página e do sumário são texto fixo, não calculado.** Qualquer edição que mude a altura do conteúdo pode deslocar a paginação real sem que os números escritos no HTML acompanhem — sempre gere o PDF e confira (passo 6), não confie apenas na lógica de que "só mudei uma frase".

## Bootstrap / regeneração completa

Use apenas quando o documento ainda não existe, ou quando o usuário pedir explicitamente uma reformulação estrutural ampla (não para atualizações incrementais normais).

1. **Análise profunda do código-fonte em paralelo**, com dois agentes em background (`Agent`, `subagent_type: general-purpose`, `run_in_background: true`), cada um cobrindo uma metade do domínio para não estourar o contexto:
   - Agente A — motor de cálculo: `JSSEQCAL.prw`, `JSPERCAL.prw`, `JSREVEST.prw`, `JSINDPRO.prw`, `GMPAICO1.prw`, `GMPAICO2.prw`, `JSFORPRC.prw`, `JSMANPAR.prw`, `JSMANTAG.prw`, `src/dbstruct/JSGLBPAR.prw`, `JSPNCSTR.prw`, `JSFldPut.prw`, mais os trechos centrais de `GMPAICOM.prw`/`JSPAIGEN.prw` que a fórmula referencia (`fCalNec`, `GMINDPRO`, `fGrpCalNec`, `calcLt`, `JSGETCFG`, `JSQRYINF`, `JSAPLLOT`).
   - Agente B — painel/relatórios/integrações: `GMPAICOM.prw` (ler em blocos, é grande), `JSPAIGEN.prw`, `JSPAIACC.prw`, `JSWEBCHT.prw`, `JSNOTIFY.prw`, `src/report/JSCFPDCO.prw`, `JSRLPDCO.tlpp`, `src/supabase/JSSUPABASE.prw`, `JSSUPPORT.prw`, `src/utils/jsrun.prw`, `src/html/painel_compras_ruptura_v01.html`.
   - Peça a cada agente um relatório em texto (sem gerar arquivos), em português, citando funções/variáveis do código como evidência, mas destinado a alimentar uma documentação para leigos — ou seja, você (agente principal) é quem traduz isso para linguagem simples depois, os agentes só precisam validar o comportamento real.
2. Escreva o HTML do zero com Write, seguindo a estrutura de página única por seção (capa → sumário → 12 seções → glossário → encerramento) e o sistema de componentes descrito acima.
3. Rode o script `build_pdf.py` e confira visualmente **todas** as páginas com Read (não só uma amostra) — numa regeneração completa, todo o documento é superfície de risco para os bugs conhecidos.
4. Ajuste espaçamento (`padding`/`margin`/`line-height`) globalmente se muitas páginas overflowarem, em vez de corrigir seção por seção.
