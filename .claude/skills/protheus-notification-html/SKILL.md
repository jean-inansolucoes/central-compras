---
name: protheus-notification-html
description: Gera conteúdo HTML para notificações internas exibidas na Central de Notificações do Protheus (wrapper AdvPL da INAN Soluções, usado no SmartSupply e outras ferramentas), seguindo o padrão visual roxo/pink da marca e todas as restrições técnicas do wrapper (fragmento cBody, sem aspas simples, acentos em entidades HTML, classes com prefixo ss-). Use esta skill SEMPRE que o usuário pedir um HTML de notificação, comunicado, aviso de nova release/versão, novidade de ferramenta, ou mencionar "notificação do Protheus", "Central de Notificações", "cBody", "notificação do SmartSupply" — mesmo que ele não cite a skill pelo nome. Também use quando ele pedir para "gerar um HTML nesse formato" referindo-se ao padrão de notificações.
---

# Notificações HTML para o Protheus (padrão INAN / SmartSupply)

Esta skill gera o conteúdo HTML de notificações exibidas dentro do Protheus. O HTML produzido NÃO é uma página completa: ele é injetado como `cBody` dentro de um wrapper AdvPL que já monta a estrutura da página. Entender o wrapper é essencial.

## O wrapper AdvPL (contexto fixo, fora do nosso controle)

O código AdvPL monta a página assim (resumo):

- `body` com fundo cinza `#eef1f4`, fonte `"Segoe UI",Arial,sans-serif`, cor `#22303c`, padding 16px, `box-sizing:border-box`, `min-height:100vh` e `display:flex;align-items:center;justify-content:center` — centraliza o `.wrap` vertical e horizontalmente no espaço real disponível
- `.wrap` fluido: `width:95%` centralizado, com teto `max-width:1400px` (evita esticar demais em monitores ultra-wide)
- `.badge` cinza pequeno ("Notificacao N")
- `.card` branco, `border-radius:10px`, `padding:24px`, sombra leve
- `h1` azul `#0a5ab4` com borda inferior — recebe o `cTitle` passado pelo AdvPL
- `img{max-width:100%}` global
- O fragmento gerado entra logo após o `h1`, dentro do `.card`, passando por `DecodeUTF8()`

A janela (`FWDialogModal`) é auto-expansível: ocupa ~90% da resolução de tela do usuário, tanto em largura quanto em altura (calculada via `MsAdvSize()` no AdvPL), então o espaço de exibição varia por máquina — de notebooks pequenos a monitores ultra-wide. O `.wrap` acompanha a largura via percentual (teto de 1400px citado acima), e o `body` centraliza o conjunto badge+card verticalmente no viewport inteiro (`min-height:100vh` + flex), em vez de deixar o card ancorado no topo com um vazio cinza embaixo em notificações curtas. Para notificações mais longas que a altura disponível, a página rola normalmente (o `display:flex` no `body` não impede o scroll do documento). Isso significa que o fragmento pode ser exibido bem mais largo e alto do que os ~500x300 de antigamente: evitar layouts que dependam de uma coluna estreita fixa (o template já usa flex/percentual e se adapta bem), mas também não presumir uma largura ou altura mínima grande. O navegador embutido do Protheus NÃO tem acesso à internet: nunca usar Google Fonts, CDNs ou qualquer recurso externo.

## Regras OBRIGATÓRIAS do fragmento (cBody)

1. **Fragmento puro**: sem `<!DOCTYPE>`, `<html>`, `<head>`, `<body>`. Apenas o conteúdo, com o `<style>` embutido no próprio fragmento.
2. **NUNCA usar aspas simples (`'`)** em lugar nenhum do HTML/CSS/texto — o AdvPL delimita strings com aspas simples e qualquer ocorrência quebra a compilação. Atributos HTML sempre com aspas duplas. Reescrever frases para evitar apóstrofos.
3. **Acentos e caracteres especiais em entidades HTML** (`&eacute;`, `&ccedil;`, `&atilde;`, `&iacute;`, `&ecirc;`, `&otilde;`, `&acirc;`...) em todo texto visível, evitando problemas de codepage no `DecodeUTF8()`. O fragmento final deve ser 100% ASCII.
4. **Todas as classes com prefixo `ss-`** e nenhum seletor de tag "crua" (não estilizar `body`, `h1`, `p`, `img`, `div` soltos) para não conflitar com o CSS do wrapper. Nomes de animações também prefixados (`ss-pulsar`, `ss-alternar`).
5. **Não usar `h1`** no fragmento (o título azul vem do `cTitle` do AdvPL). Títulos internos são `div`/`p` com classe.
6. **Sem `position:fixed`**, sem unidades de viewport (`vw/vh/vmin`), sem `overflow` no body, sem JavaScript. O fragmento se adapta à largura do card naturalmente.
7. **Sem fontes externas**: herdar a fonte do wrapper (Segoe UI). Sem imagens externas; ícones sempre em SVG inline (stroke branco, `fill:none`, `stroke-width` ~2, cantos arredondados).

## Padrão visual (identidade da marca)

Paleta EXCLUSIVA (não usar outras cores):
`#ffffff`, `#441c7d`, `#6b31b0`, `#a57dd0`, `#2e105d`, `#8256b9`, `#f41dab`, `#cd1f92`, `#b6acc7`

Estrutura visual padrão (ver `assets/template-cbody.html`, que é o modelo aprovado — SEMPRE partir dele):

- **Painel** `.ss-panel`: gradiente roxo escuro (`#2e105d` → `#441c7d`) com brilhos radiais, cantos arredondados 14px, sombra roxa, faixa superior de 4px em gradiente `#6b31b0 → #f41dab → #cd1f92` (via `:before`), e um brilho pink desfocado no canto (`.ss-glow`).
- **Cabeçalho** `.ss-topo`: selo pill `.ss-badge` em gradiente pink com ponto pulsante + nome da ferramenta `.ss-marca` em caps lilás espaçado.
- **Título interno** `.ss-titulo`: bold 18px, com trecho de destaque em gradiente pink→lilás via `background-clip:text` (`.ss-destaque`).
- **Itens de novidade** `.ss-item`: linhas horizontais (ícone quadrado arredondado em gradiente roxo à esquerda + título 13px + descrição 11.5px em `#b6acc7` com destaques `<b>` em `#a57dd0`). O segundo item usa gradiente magenta no ícone (`.ss-item-2`). Palavras-chave importantes em `<b>`.
- **Toggle animado** `.ss-toggle`: quando a novidade envolve um parâmetro liga/desliga, incluir o interruptor animado à direita do item.
- **Rodapé** `.ss-foot` (OPCIONAL — incluir SOMENTE se o usuário pedir explicitamente na solicitação): instrução final centralizada. Quando o usuário mencionar teclas de atalho (ex.: F12), estilizá-las como keycap (`.ss-tecla`) e incluir o ícone de teclado. NUNCA adicionar rodapé, instruções de atalho ou keycaps por conta própria: se a solicitação não citar rodapé/atalho, o fragmento termina no último item de novidade.
- Media query `min-width:720px` aumentando levemente a escala.

O conteúdo (títulos, itens, quantidade de itens, rodapé) muda conforme o pedido; o visual e as regras técnicas NÃO mudam.

## Fluxo de trabalho

1. Ler `assets/template-cbody.html` e adaptá-lo ao conteúdo pedido pelo usuário (nunca escrever do zero). Atenção: o template contém um rodapé `.ss-foot` com keycap F12 apenas como exemplo — REMOVER esse bloco (e seus estilos, se não usados) a menos que o usuário tenha pedido rodapé/atalho na solicitação.
2. Salvar o fragmento num arquivo temporário de trabalho (ex.: no scratchpad da sessão).
3. Rodar o script de build, que VALIDA as regras e gera os entregáveis **diretamente dentro do projeto**, em `<raiz-do-projeto>/generated_notify/<versao>/` (uma subpasta por versão do SmartSupply, ex.: `generated_notify/20.0003/`). Sempre salvar aqui, nunca em `/mnt/user-data/outputs` ou fora do projeto:

```bash
python3 scripts/build_outputs.py <fragmento.html> --titulo "SmartSupply - Titulo da notificacao" --saida <raiz-do-projeto>/generated_notify/<versao> --nome <nome-base>
```

O script:
- Valida: ausência de aspas simples, de tags proibidas (`<!DOCTYPE`, `<html`, `<head`, `<body`, `<h1`), de caracteres não-ASCII, de `position:fixed`, unidades de viewport, `<script>`, URLs externas e classes sem prefixo `ss-`.
- Gera 3 arquivos dentro de `generated_notify/<versao>/`: `<nome>-cbody.html` (fragmento), `<nome>-preview.html` (simulação fiel do wrapper AdvPL para conferência no navegador) e `<nome>-cbody.advpl.txt` (linhas `cBody += '...'+ EOL` prontas para colar no fonte).

4. Corrigir qualquer erro apontado pelo script e rodar de novo até passar.
5. Publicar o `<nome>-preview.html` como Artifact para o usuário conferir visualmente, e apontar o caminho dos 3 arquivos já salvos em `generated_notify/<versao>/`, destacando que o `.advpl.txt` está pronto para colar no fonte.

## Dicas de conteúdo

- Textos curtos: título interno em 1 linha; descrições de itens em até 2 linhas (~120 caracteres).
- Sugerir um `cTitle` adequado para o AdvPL (ex.: "SmartSupply - Nova release disponivel") — sem acentos ou com tratativa própria do usuário, pois o título não passa pelo fragmento.
- Ýcones SVG simples de 24x24 no estilo do template (traço 2, linhas arredondadas), representando o tema de cada item (gráfico, engrenagem, caminhão, tabela etc.).
