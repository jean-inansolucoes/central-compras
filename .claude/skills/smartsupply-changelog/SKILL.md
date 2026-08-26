---
name: smartsupply-changelog
description: Mantém atualizado o changelog interno do SmartSupply (Painel de Compras) — o array aDetVer dentro de "user function JSDETVER" em src/main/JSPAIGEN.prw — adicionando um novo registro sempre que uma correção de bug, um ajuste de comportamento ou uma nova funcionalidade for implementada em qualquer rotina do addon (GMPAICOM.prw, JSPAIGEN.prw, JSPNCSTR.prw, JSGLBPAR.prw, JSREVEST.prw, JSSEQCAL.prw, JSINDPRO.prw, JSMANPAR.prw, JSMANTAG.prw, JSFORPRC.prw, JSPAIACC.prw, JSWEBCHT.prw, JSNOTIFY.prw, JSSUPPORT.prw, relatórios JSCFPDCO/JSRLPDCO, ou qualquer outro fonte do SmartSupply/Painel de Compras). Use esta skill SEMPRE ao concluir esse tipo de alteração nessas rotinas, mesmo que o usuário não peça explicitamente — não use para mudanças em outros módulos/clientes do repositório fora do SmartSupply, para edições apenas de documentação, ou para investigações que não resultaram em alteração de código.
---

# Changelog interno do SmartSupply (aDetVer / JSDETVER)

O SmartSupply mantém seu próprio changelog dentro do código: `user function JSDETVER()`, em `src/main/JSPAIGEN.prw`, monta e devolve o array `aDetVer`. Cada elemento documenta uma entrega (correção, ajuste ou nova funcionalidade).

## Estrutura de cada registro

```advpl
aAdd( aDetVer, { '<versão dicionário>', '<sequência>', '<data>', '<resumo>' } )
```

1. **Versão do dicionário** (`aDetVer[n][1]`): só muda quando esta tarefa cria ou altera um **campo, índice, tabela** (ex.: `PNC_*`, `SBZ`) ou **parâmetro interno `MV_X_PNC*`**. Se a mudança é só código/comportamento, sem tocar dicionário, **mantenha a mesma versão** da última entrada.
2. **Sequência de compilação** (`aDetVer[n][2]`): sempre `+1` em relação à última entrada, com zero à esquerda até 4 dígitos (`'0001'`, `'0002'`, ... `'0010'`, ...). **Reinicia para `'0001'`** sempre que a versão do dicionário (posição 1) mudar nesta entrada.
3. **Data** (`aDetVer[n][3]`): formato `DD/MM/AAAA` — data em que o ajuste foi **iniciado** (normalmente a data corrente da sessão; veja o contexto `currentDate` da conversa).
4. **Resumo** (`aDetVer[n][4]`): uma frase objetiva do que foi efetivamente alterado/implementado, em português, tom de changelog de negócio — descreva o efeito para quem usa o painel, sem nomes de função/variável/tabela do AdvPL. Calibre pelo histórico existente no próprio array.

## Quando adicionar um registro

Ao terminar de implementar, na mesma tarefa/sessão, uma correção de bug, um ajuste de comportamento ou uma nova funcionalidade em qualquer rotina do SmartSupply — adicione um registro ao final do array, mesmo que o usuário não peça.

**Não** adicione registro para:
- Mudanças em outros módulos/clientes do repositório, fora do escopo do SmartSupply.
- Edições puramente de documentação (`documentos/*.html`), sem mudança de código.
- Investigação/diagnóstico que não resultou em nenhuma alteração de código.

Quando várias alterações pequenas fazem parte do **mesmo** pedido do usuário (ex.: vários arquivos tocados para resolver um único bug), normalmente um único registro cobrindo o conjunto é suficiente — não crie um registro por arquivo. Se o usuário pediu duas coisas claramente distintas na mesma conversa, são dois registros separados.

## Passo a passo

1. **Releia o array antes de editar.** Abra `src/main/JSPAIGEN.prw`, localize `user function JSDETVER()` e leia as últimas linhas do array (a função termina em `return aDetVer` logo após a última entrada) para saber a versão e a sequência **atuais**. Nunca assuma de memória — o array pode ter crescido desde a última vez que você olhou.
2. **Decida a versão** (posição 1): igual à última entrada, a menos que esta tarefa tenha alterado dicionário (campo/índice/tabela/`MV_X_PNC*`) — nesse caso incremente em 1. O salto de `'21'` para `'23'` no histórico foi intencional e pontual (confirmado pelo usuário) — não é um padrão a seguir; ao precisar incrementar, sempre avance a versão em 1 a partir da última usada, sem pular números e sem perguntar.
3. **Calcule a sequência** (posição 2): última sequência + 1, 4 dígitos com zero à esquerda. Reinicia para `'0001'` só se a versão mudou no passo 2.
4. **Data** (posição 3): data corrente da sessão, `DD/MM/AAAA`.
5. **Escreva o resumo** (posição 4): uma frase, no tom das entradas existentes.
6. **Edite com segurança de encoding.** `JSPAIGEN.prw` é CP-1252/CRLF. Siga o fluxo obrigatório de encoding do `CLAUDE.md` deste projeto — a ferramenta Edit/Write corrompe acentos neste arquivo. Prefira um script Python: leia os bytes, decodifique como `cp1252`, faça a substituição de string exata (linhas separadas por `\r\n`), regrave com `.encode('cp1252')`. Depois verifique imediatamente que o arquivo **não** decodifica como UTF-8 válido contendo `U+FFFD` (se decodificar com `U+FFFD`, o arquivo corrompeu e precisa ser reconstruído antes de prosseguir, também conforme o `CLAUDE.md`).
7. **Não anuncie isso como entregável principal.** É manutenção de rotina — uma menção breve no resumo final da tarefa ("registro adicionado ao changelog interno") é suficiente; não é preciso destacar ou pedir confirmação ao usuário.

## Referência — exemplos reais do histórico (para calibrar tom/formato)

```advpl
aAdd( aDetVer, { '20','0006','16/07/2026', 'Correção para que a tela de MPs do JSORDPRD utilize a mesma análise reversa de estruturas (NECREV) já usada pela grid principal, exibindo todos os componentes da estrutura independente de cadastro de fornecedor ou flag de MRP' } )
aAdd( aDetVer, { '21','0001','20/07/2026', 'Novo parâmetro de cálculo para permitir à empresa definir se o lead-time deve ser considerado no cálculo reverso de matéria-prima' } )
aAdd( aDetVer, { '23','0001','04/08/2026', 'Novos recursos para o motor de cálculo de sugestão de compra multi-filial' } )
aAdd( aDetVer, { '23','0008','24/08/2026', 'Correção para que a sugestão de compra por filial no modo de cálculo Pool/Consolidado exiba corretamente quantidade zero para filiais sem consumo médio no período, em vez de uma fração residual do arredondamento' } )
```
