---
name: upddistr-ficha-tecnica
description: Gera a Ficha Técnica de Atualização de Dicionário de Dados a partir de um pacote de distribuição diferencial (UPDDISTR) exportado pelo Configurador do Protheus, geralmente entregue como um único arquivo .rar (ex.: upddistr_2510.rar). A skill descompacta o .rar automaticamente (sempre extraindo de novo, nunca reaproveitando uma extração antiga) e cruza manifest_update.txt, o(s) payload(s) sdf<pais>.txt e os arquivos de ajuda hlpdf<idioma>.txt para produzir um HTML/PDF listando todas as operações (inclusão, alteração, exclusão) que serão aplicadas ao dicionário do ambiente de destino (SX2, SX3, SIX, SX6, SXA, SXB). Use esta skill SEMPRE que o usuário pedir para analisar/documentar um pacote UPDDISTR, descompactar/extrair um .rar de atualização de dicionário, gerar "ficha técnica do dicionário", "documentação do pacote de atualização", relatório de "o que vai mudar no dicionário", ou mencionar arquivos/pastas como manifest_update.txt, sdfbra.txt, hlpdfpor.txt, upddistr_*.rar — mesmo que ele não cite a skill pelo nome.
---

# Ficha Técnica de Atualização de Dicionário (UPDDISTR)

Esta skill audita um pacote de atualização diferencial de dicionário de dados gerado pelo Configurador do
Protheus (rotina UPDDISTR) e produz um relatório técnico (HTML + PDF) explicando, tabela por tabela e campo
por campo, tudo o que o pacote vai gravar no dicionário do ambiente de destino.

## Quando usar

Sempre que o usuário pedir para:
- Analisar/documentar um diretório de pacote UPDDISTR (tipicamente contém `manifest_update.txt`, `sdf<pais>.txt`,
  `hlpdf<idioma>.txt`, `mnupack.txt`).
- Gerar uma "ficha técnica", "documentação técnica" ou "relatório de impacto" de uma atualização de dicionário.
- Saber o que vai mudar (inclusão/alteração/exclusão) em SX2, SX3, SIX, SX6, SXA ou SXB antes de aplicar um
  pacote em produção.

## Arquivos de um pacote UPDDISTR (contexto)

| Arquivo | Conteúdo |
|---|---|
| `<nome>.rar` (ex.: `upddistr_2510.rar`) | Forma mais comum de distribuição do pacote: um único `.rar` contendo os arquivos abaixo, tipicamente dentro de uma subpasta com o nome do projeto (ex.: `SmartSupply_Bridi/`). Quando presente, é sempre a fonte usada — ver passo 2. |
| `manifest_update.txt` | Manifesto oficial e legível: lista, seção por seção (SIX, SX2, SX6, SXB, SXA, SX3, Helps), cada operação com `Operação:Inclusão ou Alteração` ou `Operação:Exclusão` e os campos-chave do registro afetado. **Fonte de verdade para a contagem de operações.** |
| `sdf<pais>.txt` (ex.: `sdfbra.txt`) | Payload físico de estrutura (texto de largura fixa, sem quebras de linha) com o conteúdo real dos registros: expressão de chave dos índices (SIX), tipo/tamanho/decimais/título dos campos (SX3), descrição/valor padrão dos parâmetros (SX6). Um arquivo por localização/país; pode haver mais de um. |
| `hlpdf<idioma>.txt` (ex.: `hlpdfpor.txt`, `hlpdfeng.txt`, `hlpdfspa.txt`) | Texto de ajuda contextual (F1) por campo, um arquivo por idioma. Formato `<tamanho 6 dígitos>P<campo>USER<texto>`, registros concatenados sem separador. |
| `mnupack.txt` | Pacote de alterações de menu (frequentemente vazio). |

## Fluxo de trabalho

1. **Localizar o diretório do pacote**: pedir/confirmar o caminho se não estiver óbvio pelo contexto da
   conversa (ex.: `upddistr/`, um diretório citado pelo usuário). O diretório precisa conter, direta ou
   indiretamente (via `.rar`, ver passo 2), pelo menos `manifest_update.txt` — os demais arquivos são
   opcionais (a skill degrada graciosamente e sinaliza no próprio relatório o que não pôde ser enriquecido).
2. **Rodar o script**, que descompacta o `.rar` (se necessário) e faz todo o parsing, cruzamento de dados,
   classificação de risco e geração dos entregáveis:

   ```bash
   python3 .claude/skills/upddistr-ficha-tecnica/scripts/gerar_ficha_tecnica.py --dir <diretorio-do-pacote>
   ```

   Por padrão a saída é gravada **dentro do próprio diretório do pacote** (`ficha-tecnica-dicionario.html` e
   `.pdf`), para ficar ao lado dos arquivos-fonte (ou do `.rar`). Use `--saida <outro-diretorio>` apenas se o
   usuário pedir explicitamente um local diferente.

   Regras de resolução do `.rar` (automáticas, não precisam ser explicadas ao usuário a não ser que dêem
   erro):
   - Se `manifest_update.txt` não existir diretamente em `--dir`, o script procura exatamente **um** arquivo
     `.rar` nesse diretório e o descompacta em `<dir>/_extraido_<nome-do-rar>/` usando a primeira ferramenta
     disponível no sistema (`bsdtar` → `unrar` → `unar` → `7z`/`7za`; `bsdtar` já vem por padrão no macOS).
   - Essa extração é **sempre refeita do zero** a cada execução (a pasta `_extraido_*` antiga é apagada
     antes) — nunca reaproveita uma extração antiga, para não analisar por engano uma versão desatualizada
     do pacote quando o usuário substituir o `.rar` por um mais novo.
   - Se houver **mais de um** `.rar` no diretório, ou nenhuma ferramenta de extração disponível, o script
     para com uma mensagem de erro clara — repassar essa mensagem ao usuário (não tentar adivinhar qual
     `.rar` usar nem instalar ferramentas sem perguntar).
   - A pasta `_extraido_*` fica ignorada pelo git (`.gitignore` do projeto já tem essa regra).
3. **Ler a "Análise de completude" impressa no console** ao final da execução — ela lista automaticamente:
   - o total de operações e se todas foram localizadas/enriquecidas;
   - itens do manifesto que não puderam ser localizados no(s) `sdf*.txt` (aparecem como "N/D" no relatório);
   - se `mnupack.txt` tem conteúdo não interpretado (precisa de revisão manual);
   - se nenhum payload `sdf*.txt` foi encontrado (relatório fica limitado aos dados do manifesto).
   Repassar esses pontos ao usuário no resumo da resposta, não só deixá-los enterrados no PDF.
4. Se o Google Chrome/Chromium não estiver instalado, o script avisa e gera **apenas o HTML** (o PDF é
   pulado, não é erro fatal). Nesse caso, publicar o HTML como Artifact para o usuário conferir no navegador,
   ou orientar "Imprimir > Salvar como PDF" a partir do HTML.
5. Publicar o HTML gerado como Artifact (visualização rápida) e informar o caminho dos arquivos gravados no
   projeto.

## O que o relatório cobre

- Capa com metadados do pacote (projeto, descrição, versão, release, data/hora, responsável), extraídos do
  cabeçalho do `manifest_update.txt`.
- Sumário executivo e contagem consolidada de operações por dicionário (SX2/SIX/SX3/SX6/SXA/SXB/menu/help).
- Tabelas (SX2) com cross-reference automático: se um parâmetro SX6 incluído no mesmo pacote tem como valor
  padrão o alias de uma tabela também incluída, o relatório aponta essa relação; se uma tabela nova só recebe
  um índice de ordem > 1 neste pacote, sinaliza como possível extensão de tabela pré-existente.
- Índices (SIX) com a expressão de chave completa, extraída do payload físico.
- Campos (SX3) agrupados por tabela, com tipo/tamanho/decimais/título (do payload) e descrição funcional (do
  help em português), classificados em Tabela nova / Tabela customizada pré-existente / Campo customizado
  (`_X_`) / Campo padrão TOTVS — essa última categoria dispara um alerta específico na seção de riscos.
- Parâmetros (SX6) com descrição e valor padrão reconstruídos do payload físico.
- Consultas padrão (SXB) e pastas de campos (SXA), agrupadas por consulta/tabela.
- Estatística de cobertura da ajuda de campo (F1) por idioma, incluindo detecção automática de textos
  não-traduzidos (idioma diferente do de referência com conteúdo idêntico).
- Seção de riscos **gerada dinamicamente a partir do que foi encontrado** (nunca hardcoded): toda exclusão em
  qualquer dicionário, todo campo padrão TOTVS que teve propriedades reaplicadas, lacunas de extração,
  conteúdo em `mnupack.txt`, ausência de payload, idiomas de ajuda totalmente vazios.

## Limitações conhecidas (avisar o usuário quando relevante)

- O layout de largura fixa do `sdf<pais>.txt` foi obtido por engenharia reversa empírica (não é documentado
  oficialmente pela TOTVS) e validado contra pacotes reais do módulo Central de Compras. Todo valor extraído
  passa por validação de formato antes de entrar no relatório; quando a validação falha, o campo aparece como
  `N/D` em vez de arriscar mostrar um valor truncado ou incorreto — mas se um pacote futuro usar uma variação
  de layout ainda não vista, é possível que mais itens caiam em `N/D` do que o esperado. Nesse caso, revisar
  manualmente os itens listados na "Análise de completude".
- O conteúdo de `mnupack.txt` (quando não vazio) não é interpretado — o relatório apenas sinaliza o tamanho do
  arquivo e recomenda revisão manual ou validação em homologação.
- Nenhuma descrição de negócio é inventada: toda frase explicativa no relatório vem de um dado real (título de
  campo, texto de ajuda, cross-reference de parâmetro) ou é genérica quando não há dado disponível. Isso é
  intencional — evita apresentar como fato algo que a skill não pode confirmar.
