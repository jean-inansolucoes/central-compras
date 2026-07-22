#include 'totvs.ch'
#include 'topconn.ch'

// Posições das colunas do vetor de trace carregado de PNC_RVTRC_<empresa>
#define TRC_NIVEL   01
#define TRC_PAI     02
#define TRC_PROD    03
#define TRC_QTPOR   04
#define TRC_NECBRT  05
#define TRC_ESTABT  06
#define TRC_OPABT   07
#define TRC_NECLIQ  08
#define TRC_CONTRIB 09
#define TRC_TIPO    10
#define CEOL        chr(13)+chr(10)

/*/{Protheus.doc} JSSEQCAL
Tela "Sequência de Cálculo" do SmartSupply: apresenta como o sistema chegou ao resultado da
sugestão de compra/produção do produto posicionado na grid principal. Para componentes com
análise reversa habilitada, exibe a árvore multinível das estruturas (classe DBTree) lida do
trace materializado pelo job (PNC_RVTRC_<empresa>), com as necessidades individuais de cada nó
e o painel de detalhes da composição do valor final. Para produtos sem estrutura (ou com a
análise reversa desabilitada), exibe o breakdown do cálculo convencional: fórmula do perfil,
valor de cada variável, resultado e ajustes de lote até a sugestão final.
Pré-condição: deve ser chamada a partir da tela principal (U_GMPAICOM), pois utiliza as
variáveis Private da tela (_aProdFil, nPos*, nSpinBx, cPerfil, aConfig, _aFil).
@type function
@version 20.0002
@author Jean Carlos Pandolfo Saggin
@since 09/07/2026
@param cProduto, character, código do produto posicionado na grid principal (ou na grid de MPs, quando chamado a partir de showMP/U_JSORDPRD)
@return logical, lSucesso
/*/
user function JSSEQCAL( cProduto )

    local lSucesso := .T. as logical
    local oDlgSeq  as object
    local oPanTre  as object
    local oPanDet  as object
    local oTree    as object
    local oMemo    as object
    local aTrace   := {} as array
    local aCalRow  := {} as array
    local aDetTxt  := {} as array
    local oDescHM  := Nil
    local cFilSel  := cFilAnt as character
    local cTabTrc  := "PNC_RVTRC_"+ cEmpAnt
    local cTabCal  := "PNC_RVCALC_"+ cEmpAnt
    local cDetail  := "" as character
    local cTitle   := "" as character
    local dDtCalc  := CtoD( SubStr( GetMv( 'MV_X_PNC12',,DtoC( Date() ) ), 01, 10 ) )
    local bChgTre  := Nil
    local aButtons := {} as array

    Private nDias   := 0
    Private nLdTime := 0
    Private nPrjEst := 0
    Private nConMed := 0
    Private nLotMin := 0
    Private nQtdEmb := 0
    Private nLotEco := 0
    Private nEstSeg := 0
    Private nQtdEst := 0
    Private nQtdEmp := 0
    Private nQtdPed := 0
    Private nQtdSol := 0
    Private nQtdPrd := 0

    default cProduto := ""

    if Empty( cProduto )
        return .F.
    endif

    // Quando a análise contempla mais de uma filial, o usuário escolhe qual filial auditar
    // (não se aplica dentro da tela de MPs - U_JSORDPRD/showMP -, pois a matéria-prima já vem consolidada entre as filiais)
    if ! isInCallStack( 'U_JSORDPRD' ) .and. Type( '_aFil' ) == 'A' .and. len( _aFil ) > 1
        cFilSel := askFil( _aFil )
        if Empty( cFilSel )
            return .F.      // usuário cancelou a seleção
        endif
    endif

    // Carrega o trace materializado da análise reversa (quando existir para o produto/filial/data)
    if TCCanOpen( cTabTrc ) .and. TCCanOpen( cTabCal )
        aTrace  := loadTrc( cTabTrc, cFilSel, cProduto, dDtCalc )
        aCalRow := loadCal( cTabCal, cFilSel, cProduto, dDtCalc )
    endif

    // Componente com resultado materializado porém sem trace da execução corrente: orienta o recálculo
    if len( aCalRow ) > 0 .and. len( aTrace ) == 0
        hlp( 'Trace indisponível',;
             'O detalhamento da análise reversa desta execução não está mais disponível.',;
             'Execute o recálculo dos índices dos produtos para regravar a sequência de cálculo. Será exibido o detalhamento do cálculo convencional.' )
    endif

    cTitle := 'Sequência de Cálculo - '+ AllTrim( cProduto )

    oDlgSeq := FWDialogModal():New()
    oDlgSeq:SetEscClose( .T. )
    oDlgSeq:SetTitle( cTitle )
    oDlgSeq:SetSize( (MsAdvSize()[6]/2)*0.8, (MsAdvSize()[5]/2)*0.8 )	// 80% da resolução da tela (largura, altura)
    if len( aTrace ) > 0
        oDlgSeq:SetSubTitle( 'Análise reversa de estruturas - filial '+ AllTrim( cFilSel ) +' - cálculo de '+ DtoC( dDtCalc ) )
    elseif isInCallStack( 'U_JSORDPRD' )
        oDlgSeq:SetSubTitle( 'Cálculo convencional (fórmula do perfil) - matéria-prima (consolidado entre filiais)' )
    else
        oDlgSeq:SetSubTitle( 'Cálculo convencional (fórmula do perfil) - filial '+ AllTrim( cFilSel ) )
    endif
    oDlgSeq:EnableAllClient()
    oDlgSeq:CreateDialog()
    oDlgSeq:AddCloseButton( {|| oDlgSeq:DeActivate() }, "Fechar" )

    // Painel esquerdo: árvore da sequência de cálculo | Painel direito: detalhes do nó selecionado
    oPanTre := TPanel():New( ,,, oDlgSeq:getPanelMain() )
    oPanTre:Align := CONTROL_ALIGN_LEFT
    oPanTre:nWidth := 650   // Largura ampliada para comportar a descrição completa dos nós da árvore de sequência de cálculo
    oPanDet := TPanel():New( ,,, oDlgSeq:getPanelMain() )
    oPanDet:Align := CONTROL_ALIGN_ALLCLIENT

    oTree := DBTree():New( 0, 0, 100, 100, oPanTre,,, .T. )
    oTree:Align := CONTROL_ALIGN_ALLCLIENT

    cDetail := 'Selecione um item da árvore para visualizar os detalhes do cálculo.'
    oMemo := TMultiget():New( 0, 0, {|u| iif( PCount() > 0, cDetail := u, cDetail ) },;
                              oPanDet, 100, 100,,,,,, .T. /* lPixel */,,,,,, .T. /* lReadOnly */ )
    oMemo:Align := CONTROL_ALIGN_ALLCLIENT

    // Monta a árvore e o vetor de textos de detalhe por nó (CARGO = índice do vetor)
    if len( aTrace ) > 0
        oDescHM := loadDesc( aTrace, cProduto )
        // Descarta nós cujo produto está referenciado na estrutura (SG1) mas não possui cadastro físico em SB1
        // (e toda a subárvore dependente deles), evitando exibir/carregar dados inúteis na sequência de cálculo
        aTrace  := filterTrc( aTrace, oDescHM )
        aDetTxt := buildRev( oTree, aTrace, aCalRow, oDescHM, dDtCalc )
    else
        aDetTxt := buildConv( oTree, cProduto, cFilSel )
    endif

    // Botão para imprimir/exportar (TReport) os dados utilizados no rastreio da sugestão de compra/produção;
    // o usuário escolhe o formato de saída na própria tela de impressão (impressora, PDF, Excel, HTML, etc.)
    aAdd( aButtons, { , 'Imprimir/Exportar Dados', {|| doReport( aTrace, aCalRow, oDescHM, cProduto, cFilSel, dDtCalc ) },;
        'Exibe a tela de impressão para gerar os dados utilizados no rastreio da sugestão no formato desejado (impressora, PDF, Excel, etc.)',,.T. /* lShowBar */, .T. /* lShowConfig */ } )
    oDlgSeq:AddButtons( aButtons )

    // Troca de nó selecionado: atualiza o painel de detalhes
    bChgTre := {|| showDet( oTree, aDetTxt, @cDetail, oMemo ) }
    oTree:bChange := bChgTre

    oDlgSeq:Activate()

return lSucesso

/*/{Protheus.doc} showDet
Atualiza o painel de detalhes conforme o nó selecionado na árvore (CARGO = índice do vetor de textos).
@type function
@version 20.0002
@author Jean Carlos Pandolfo Saggin
@since 09/07/2026
@param oTree, object, árvore da sequência de cálculo
@param aDetTxt, array, textos de detalhe por nó
@param cDetail, character, variável do painel de detalhes (por referência)
@param oMemo, object, controle de exibição dos detalhes
/*/
static function showDet( oTree, aDetTxt, cDetail, oMemo )

    local cCargo := "" as character
    local nIdx   := 0 as numeric

    cCargo := oTree:GetCargo()
    if ValType( cCargo ) == 'C' .and. ! Empty( cCargo )
        nIdx := Val( cCargo )
        if nIdx > 0 .and. nIdx <= len( aDetTxt )
            cDetail := aDetTxt[nIdx]
            oMemo:Refresh()
        endif
    endif

return Nil

/*/{Protheus.doc} loadTrc
Carrega o trace da sequência de cálculo do componente (PNC_RVTRC) ordenado pela sequência de gravação.
@type function
@version 20.0002
@author Jean Carlos Pandolfo Saggin
@since 09/07/2026
@param cTabTrc, character, nome físico da tabela de trace
@param cFilTrc, character, filial auditada
@param cProduto, character, código do componente
@param dDtCalc, date, data de referência do cálculo (MV_X_PNC12)
@return array, linhas { nivel, pai, produto, qtpor, necbrt, estabt, opabt, necliq, contrib, tipo }
/*/
static function loadTrc( cTabTrc, cFilTrc, cProduto, dDtCalc )

    local aTrace := {} as array
    local cQuery := "" as character
    local cAlias := GetNextAlias()

    cQuery := "SELECT NIVEL, PAI, PROD, QTPOR, NECBRT, ESTABT, OPABT, NECLIQ, CONTRIB, TIPO " + CEOL
    cQuery += "FROM "+ cTabTrc +" " + CEOL
    cQuery += "WHERE FILIAL = '"+ cFilTrc +"' " + CEOL
    cQuery += "  AND MP     = '"+ cProduto +"' " + CEOL
    cQuery += "  AND DTCALC = '"+ DtoS( dDtCalc ) +"' " + CEOL
    cQuery += "  AND D_E_L_E_T_ = ' ' " + CEOL
    cQuery += "ORDER BY SEQ " + CEOL

    DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), cAlias, .F., .T. )
    while ! ( cAlias )->( EOF() )
        aAdd( aTrace, { ( cAlias )->NIVEL,;
                        ( cAlias )->PAI,;
                        ( cAlias )->PROD,;
                        ( cAlias )->QTPOR,;
                        ( cAlias )->NECBRT,;
                        ( cAlias )->ESTABT,;
                        ( cAlias )->OPABT,;
                        ( cAlias )->NECLIQ,;
                        ( cAlias )->CONTRIB,;
                        ( cAlias )->TIPO } )
        ( cAlias )->( DbSkip() )
    end
    ( cAlias )->( DbCloseArea() )

return aTrace

/*/{Protheus.doc} loadCal
Carrega o resultado consolidado da análise reversa do componente (PNC_RVCALC).
@type function
@version 20.0002
@author Jean Carlos Pandolfo Saggin
@since 09/07/2026
@param cTabCal, character, nome físico da tabela de resultado
@param cFilCal, character, filial auditada
@param cProduto, character, código do componente
@param dDtCalc, date, data de referência do cálculo (MV_X_PNC12)
@return array, { necrev, demestr, demvnd, vendia, condia, posabt, nfinais, dtexec, demldt } ou vazio -
        demldt vem zerado (sem erro) em ambientes ainda não migrados pelo assistente de estruturas
/*/
static function loadCal( cTabCal, cFilCal, cProduto, dDtCalc )

    local aCalRow := {} as array
    local cQuery  := "" as character
    local cAlias  := GetNextAlias()
    local cAliChk := "" as character
    local lTemLdt := .F. as logical
    local nDemLdt := 0 as numeric

    // Verifica se o campo DEMLDT (quantidade adicional por lead time) já existe fisicamente na tabela,
    // evitando erro de SQL em ambientes ainda não atualizados pelo assistente de estruturas (U_JSGLBPAR)
    cAliChk := GetNextAlias()
    DBUseArea( .T., 'TOPCONN', cTabCal, cAliChk, .T., .F. )
    lTemLdt := ( cAliChk )->( FieldPos( 'DEMLDT' ) ) > 0
    ( cAliChk )->( DBCloseArea() )

    cQuery := "SELECT NECREV, DEMESTR, "
    if lTemLdt
        cQuery += "DEMLDT, "
    endif
    cQuery += "DEMVND, VENDIA, CONDIA, POSABT, NFINAIS, DTEXEC " + CEOL
    cQuery += "FROM "+ cTabCal +" " + CEOL
    cQuery += "WHERE FILIAL = '"+ cFilCal +"' " + CEOL
    cQuery += "  AND PROD   = '"+ cProduto +"' " + CEOL
    cQuery += "  AND DTCALC = '"+ DtoS( dDtCalc ) +"' " + CEOL
    cQuery += "  AND D_E_L_E_T_ = ' ' " + CEOL

    DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), cAlias, .F., .T. )
    if ! ( cAlias )->( EOF() )
        if lTemLdt
            nDemLdt := ( cAlias )->DEMLDT
        endif
        aCalRow := { ( cAlias )->NECREV,;
                     ( cAlias )->DEMESTR,;
                     ( cAlias )->DEMVND,;
                     ( cAlias )->VENDIA,;
                     ( cAlias )->CONDIA,;
                     ( cAlias )->POSABT,;
                     ( cAlias )->NFINAIS,;
                     ( cAlias )->DTEXEC,;
                     nDemLdt }
    endif
    ( cAlias )->( DbCloseArea() )

return aCalRow

/*/{Protheus.doc} loadDesc
Carrega as descrições dos produtos presentes no trace com uma única query (hashmap código -> descrição).
@type function
@version 20.0002
@author Jean Carlos Pandolfo Saggin
@since 09/07/2026
@param aTrace, array, linhas do trace
@param cProduto, character, código do componente auditado
@return object, hashmap código -> descrição
/*/
static function loadDesc( aTrace, cProduto )

    local oDescHM := HMNew()
    local oSeen   := HMNew()
    local aCodes  := {} as array
    local cLista  := "" as character
    local cQuery  := "" as character
    local cAlias  := "" as character
    local nX      := 0 as numeric
    local xDummy  := Nil

    aAdd( aCodes, cProduto )
    HMSet( oSeen, cProduto, .T. )
    for nX := 1 to len( aTrace )
        if ! HMGet( oSeen, aTrace[nX][TRC_PROD], @xDummy )
            HMSet( oSeen, aTrace[nX][TRC_PROD], .T. )
            aAdd( aCodes, aTrace[nX][TRC_PROD] )
        endif
    next nX

    for nX := 1 to len( aCodes )
        if Empty( cLista )
            cLista := "'"+ aCodes[nX] +"'"
        else
            cLista += ",'"+ aCodes[nX] +"'"
        endif
    next nX

    cQuery := "SELECT B1.B1_COD, B1.B1_DESC FROM "+ RetSqlName( 'SB1' ) +" B1 " + CEOL
    cQuery += "WHERE B1.B1_FILIAL  = '"+ FWxFilial( 'SB1' ) +"' " + CEOL
    cQuery += "  AND B1.B1_COD IN ( "+ cLista +" ) " + CEOL
    cQuery += "  AND B1.D_E_L_E_T_ = ' ' " + CEOL

    cAlias := GetNextAlias()
    DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), cAlias, .F., .T. )
    while ! ( cAlias )->( EOF() )
        HMSet( oDescHM, ( cAlias )->B1_COD, ( cAlias )->B1_DESC )
        ( cAlias )->( DbSkip() )
    end
    ( cAlias )->( DbCloseArea() )

return oDescHM

/*/{Protheus.doc} filterTrc
Remove do trace os nós cujo produto está referenciado na estrutura (SG1) mas não possui cadastro
físico em SB1 (registro ausente ou excluído), bem como toda a subárvore dependente desses nós
(demais linhas do trace com nível maior, na sequência de pré-ordem), evitando carregar/exibir
dados inúteis no DBTree da sequência de cálculo. A existência em SB1 é verificada a partir do
hashmap de descrições (loadDesc): um código só está presente nesse hashmap quando a consulta à
SB1 efetivamente o localizou.
@type function
@version 21.0002
@author Jean Carlos Pandolfo Saggin
@since 22/07/2026
@param aTrace, array, linhas do trace da análise reversa
@param oDescHM, object, hashmap código -> descrição, montado em loadDesc a partir da SB1
@return array, aFiltered - trace sem os nós/subárvores de produtos não cadastrados em SB1
/*/
static function filterTrc( aTrace, oDescHM )

    local aFiltered  := {} as array
    local xDummy     := Nil
    local nNivelSkip := -1 as numeric
    local nX         := 0 as numeric

    for nX := 1 to len( aTrace )

        // Ainda dentro da subárvore de um nó descartado por produto não cadastrado: também descarta
        if nNivelSkip >= 0 .and. aTrace[nX][TRC_NIVEL] > nNivelSkip
            loop
        endif
        nNivelSkip := -1

        if ! HMGet( oDescHM, aTrace[nX][TRC_PROD], @xDummy )
            // Produto sem cadastro em SB1: descarta o nó e passa a descartar toda a sua subárvore
            nNivelSkip := aTrace[nX][TRC_NIVEL]
            loop
        endif

        aAdd( aFiltered, aTrace[nX] )

    next nX

return aFiltered

/*/{Protheus.doc} buildRev
Monta a árvore da análise reversa a partir do trace (pré-ordem com nível) e devolve o vetor de
textos de detalhe por nó (CARGO da árvore = índice do vetor).
@type function
@version 20.0002
@author Jean Carlos Pandolfo Saggin
@since 09/07/2026
@param oTree, object, árvore de exibição
@param aTrace, array, linhas do trace (ordenadas por SEQ)
@param aCalRow, array, resultado consolidado (PNC_RVCALC) do componente
@param oDescHM, object, hashmap código -> descrição
@param dDtCalc, date, data de referência do cálculo
@return array, textos de detalhe por nó
/*/
static function buildRev( oTree, aTrace, aCalRow, oDescHM, dDtCalc )

    local aDetTxt := {} as array
    local cLabel  := "" as character
    local cDesc   := "" as character
    local lFilho  := .F. as logical
    local nAberto := 0 as numeric
    local nProx   := 0 as numeric
    local nX      := 0 as numeric

    for nX := 1 to len( aTrace )

        cDesc := ""
        HMGet( oDescHM, aTrace[nX][TRC_PROD], @cDesc )
        cLabel := AllTrim( aTrace[nX][TRC_PROD] ) +' - '+ AllTrim( SubStr( cDesc, 01, 30 ) )
        if aTrace[nX][TRC_TIPO] == 'M'
            cLabel += ' | Sugestão: '+ fmtNum( aCalRow[1] )
        elseif aTrace[nX][TRC_TIPO] == 'F'
            cLabel += ' | Necessidade: '+ fmtNum( aTrace[nX][TRC_NECLIQ] )
        else
            cLabel += ' | Líquida: '+ fmtNum( aTrace[nX][TRC_NECLIQ] )
        endif

        if aTrace[nX][TRC_TIPO] == 'M'
            aAdd( aDetTxt, mpDetail( aTrace[nX], aCalRow, cDesc, dDtCalc ) )
        else
            aAdd( aDetTxt, noDetail( aTrace[nX], cDesc, oDescHM ) )
        endif

        // Um nó possui filhos quando a próxima linha do trace está um nível acima (pré-ordem)
        lFilho := nX < len( aTrace ) .and. aTrace[nX+1][TRC_NIVEL] == aTrace[nX][TRC_NIVEL] + 1
        if lFilho
            oTree:AddTree( cLabel, .T., 'FOLDER5', 'FOLDER6',,, cValToChar( len( aDetTxt ) ) )
            nAberto := aTrace[nX][TRC_NIVEL] + 1
        else
            oTree:AddTreeItem( cLabel, 'PMSTASK4',, cValToChar( len( aDetTxt ) ) )
            nAberto := aTrace[nX][TRC_NIVEL]
        endif

        // Fecha os ramos abertos ao retornar para um nível inferior (ou ao final da árvore)
        if nX < len( aTrace )
            nProx := aTrace[nX+1][TRC_NIVEL]
        else
            nProx := 0
        endif
        while nAberto > nProx
            oTree:EndTree()
            nAberto--
        end

    next nX

return aDetTxt

/*/{Protheus.doc} mpDetail
Monta o texto de detalhe do nó raiz (componente auditado) com a composição do valor final.
@type function
@version 20.0002
@author Jean Carlos Pandolfo Saggin
@since 09/07/2026
@param aRow, array, linha do trace do nó raiz
@param aCalRow, array, resultado consolidado (PNC_RVCALC)
@param cDesc, character, descrição do produto
@param dDtCalc, date, data de referência do cálculo
@return character, texto de detalhe
/*/
static function mpDetail( aRow, aCalRow, cDesc, dDtCalc )

    local cTxt    := "" as character
    local nAntLot := 0 as numeric

    nAntLot := aCalRow[2] + aCalRow[9] + aCalRow[3] - aCalRow[6]
    if nAntLot < 0
        nAntLot := 0
    endif

    cTxt := 'COMPONENTE AUDITADO' + CRLF
    cTxt += Replicate( '-', 60 ) + CRLF
    cTxt += 'Produto: '+ AllTrim( aRow[TRC_PROD] ) +' - '+ AllTrim( cDesc ) + CRLF
    cTxt += 'Data do cálculo: '+ DtoC( dDtCalc ) +'  |  Execução: '+ AllTrim( aCalRow[8] ) + CRLF
    cTxt += CRLF
    cTxt += 'COMPOSIÇÃO DA SUGESTÃO DE COMPRA (análise reversa)' + CRLF
    cTxt += Replicate( '-', 60 ) + CRLF
    cTxt += '(+) Demanda derivada das estruturas..: '+ fmtNum( aCalRow[2] ) + CRLF
    cTxt += '    (soma das contribuições líquidas dos produtos que utilizam este componente -' + CRLF
    cTxt += '    baseada na média de venda dos PAs cuja MP é componente)' + CRLF
    cTxt += '(+) Adicional por lead-time do fornecedor: '+ fmtNum( aCalRow[9] ) + CRLF
    cTxt += '    (média diária da demanda das estruturas x dias de lead time da MP, quando o' + CRLF
    cTxt += '    parâmetro CONSLT está ativo; exibido à parte para diferenciar do que veio puramente' + CRLF
    cTxt += '    da estrutura)' + CRLF
    cTxt += '(+) Parcela de venda direta..........: '+ fmtNum( aCalRow[3] ) + CRLF
    cTxt += '    (média diária de venda '+ fmtNum( aCalRow[4] ) +' x horizonte de dias + lead time)' + CRLF
    cTxt += '(-) Posição abatida..................: '+ fmtNum( aCalRow[6] ) + CRLF
    cTxt += '    (estoque disponível + pedidos de compra em carteira + solicitações)' + CRLF
    cTxt += '(=) Necessidade antes dos lotes......: '+ fmtNum( nAntLot ) + CRLF
    cTxt += '(=) SUGESTÃO FINAL (após lotes)......: '+ fmtNum( aCalRow[1] ) + CRLF
    cTxt += CRLF
    cTxt += 'Produtos finais na cadeia: '+ cValToChar( aCalRow[7] ) + CRLF
    cTxt += 'Consumo interno médio/dia (referência): '+ fmtNum( aCalRow[5] ) + CRLF
    cTxt += CRLF
    cTxt += 'Observação: os valores por nó da árvore são globais do produto' + CRLF
    cTxt += '(demanda agregada de todas as estruturas), e não rateados por caminho.'

return cTxt

/*/{Protheus.doc} noDetail
Monta o texto de detalhe de um nó intermediário ou produto final da árvore.
@type function
@version 20.0002
@author Jean Carlos Pandolfo Saggin
@since 09/07/2026
@param aRow, array, linha do trace
@param cDesc, character, descrição do produto
@param oDescHM, object, hashmap código -> descrição
@return character, texto de detalhe
/*/
static function noDetail( aRow, cDesc, oDescHM )

    local cTxt    := "" as character
    local cDescPai := "" as character

    HMGet( oDescHM, aRow[TRC_PAI], @cDescPai )

    if aRow[TRC_TIPO] == 'F'
        cTxt := 'PRODUTO FINAL (raiz da cadeia)' + CRLF
    else
        cTxt := 'PRODUTO INTERMEDIÁRIO' + CRLF
    endif
    cTxt += Replicate( '-', 60 ) + CRLF
    cTxt += 'Produto: '+ AllTrim( aRow[TRC_PROD] ) +' - '+ AllTrim( cDesc ) + CRLF
    cTxt += CRLF
    if aRow[TRC_TIPO] == 'F'
        cTxt += 'Necessidade calculada (fórmula do perfil): '+ fmtNum( aRow[TRC_NECLIQ] ) + CRLF
        cTxt += '(cálculo convencional do produto final: dias, lead time,' + CRLF
        cTxt += ' duração de estoque e consumo médio próprios)' + CRLF
    else
        cTxt += 'Necessidade bruta (agregada)....: '+ fmtNum( aRow[TRC_NECBRT] ) + CRLF
        cTxt += '(-) Estoque disponível abatido..: '+ fmtNum( aRow[TRC_ESTABT] ) + CRLF
        cTxt += '(-) OPs em aberto abatidas......: '+ fmtNum( aRow[TRC_OPABT] ) + CRLF
        cTxt += '(=) Necessidade líquida.........: '+ fmtNum( aRow[TRC_NECLIQ] ) + CRLF
    endif
    cTxt += CRLF
    cTxt += 'LIGAÇÃO NA ESTRUTURA' + CRLF
    cTxt += Replicate( '-', 60 ) + CRLF
    cTxt += 'Utiliza '+ AllTrim( Str( aRow[TRC_QTPOR] ) ) +' un. do produto do nível abaixo ('+ AllTrim( aRow[TRC_PAI] ) +' - '+ AllTrim( SubStr( cDescPai, 01, 25 ) ) +')' + CRLF
    cTxt += 'Contribuição que desce desta ligação: '+ fmtNum( aRow[TRC_CONTRIB] ) + CRLF
    cTxt += '(necessidade líquida x quantidade por unidade)'

return cTxt

/*/{Protheus.doc} buildConv
Monta a árvore do breakdown do cálculo convencional (fórmula do perfil da tela) para produto
sem análise reversa, reproduzindo passo a passo o fCalNec: variáveis, resultado da fórmula e
ajustes de lote até a sugestão final (via U_JSAPLLOT, o mesmo motor do cálculo oficial).
@type function
@version 20.0002
@author Jean Carlos Pandolfo Saggin
@since 09/07/2026
@param oTree, object, árvore de exibição
@param cProduto, character, código do produto
@param cFilSel, character, filial auditada
@return array, textos de detalhe por nó
/*/
static function buildConv( oTree, cProduto, cFilSel )

    local aDetTxt := {} as array
    local aRowFil := {} as array
    local cFormTx := "" as character
    local cFormVr := "" as character
    local cDesc   := "" as character
    local lPriLE  := aConfig[19] == 'S'
    local nResFor := 0 as numeric
    local nAposLM := 0 as numeric
    local nAposLE := 0 as numeric
    local nAposEm := 0 as numeric
    local nPosRow := 0 as numeric

    if isInCallStack( 'U_JSORDPRD' )
        // Dentro da tela de MPs (showMP): localiza a linha na grid de matérias-primas (aData, Private de showMP)
        nPosRow := aScan( aData, {|x| x[nPosPrd] == cProduto } )
        if nPosRow == 0
            oTree:AddTreeItem( 'Produto não localizado na análise corrente', 'PMSTASK4',, '1' )
            aAdd( aDetTxt, 'O produto '+ AllTrim( cProduto ) +' não foi localizado nos dados carregados da análise corrente.' )
            return aDetTxt
        endif
        aRowFil := aData[nPosRow]
    else
        // Localiza a linha do produto/filial na granularidade por filial da tela
        nPosRow := aScan( _aProdFil, {|x| x[nPosPrd] == cProduto .and. x[len(x)] == cFilSel } )
        if nPosRow == 0
            nPosRow := aScan( _aProdFil, {|x| x[nPosPrd] == cProduto } )
        endif
        if nPosRow == 0
            oTree:AddTreeItem( 'Produto não localizado na análise corrente', 'PMSTASK4',, '1' )
            aAdd( aDetTxt, 'O produto '+ AllTrim( cProduto ) +' não foi localizado nos dados carregados da análise corrente. Atualize a análise (F5) e tente novamente.' )
            return aDetTxt
        endif
        aRowFil := _aProdFil[nPosRow]
    endif
    cDesc   := aRowFil[nPosDes]

    // Variáveis da fórmula (mesmos insumos do fCalNec da tela)
    nDias   := nSpinBx
    nLdTime := aRowFil[nPosLdT]
    nPrjEst := aRowFil[nPosDur]
    nConMed := aRowFil[nPosCon]
    nLotMin := aRowFil[nPosLtM]
    nQtdEmb := aRowFil[nPosQtE]
    nLotEco := aRowFil[nPosLtE]
    nEstSeg := aRowFil[nPosEMi]
    nQtdEst := aRowFil[nPosEmE]
    nQtdEmp := aRowFil[nPosVen]
    nQtdPed := aRowFil[nPosQtd]
    nQtdSol := aRowFil[nPosSol]
    nQtdPrd := aRowFil[nPosOrd]

    // Fórmula do perfil de cálculo em uso na tela (texto legível e expressão avaliável)
    cFormTx := U_JSFRMTXT( cPerfil, .F. )
    cFormVr := U_JSFRMTXT( cPerfil, .T. )

    if Empty( cFormVr )
        nResFor := 0
    else
        nResFor := Round( &( cFormVr ), 0 )
        if nResFor < 0
            nResFor := 0
        endif
    endif

    // Ajustes de lote aplicados passo a passo com o mesmo motor do cálculo oficial (U_JSAPLLOT)
    nAposLM := U_JSAPLLOT( nResFor, nLotMin, 0, 0, .F. )
    nAposLE := U_JSAPLLOT( nAposLM, 0, nLotEco, 0, lPriLE )
    nAposEm := U_JSAPLLOT( nAposLE, 0, 0, nQtdEmb, .F. )

    oTree:AddTree( AllTrim( cProduto ) +' - '+ AllTrim( SubStr( cDesc, 01, 30 ) ) +' | Sugestão: '+ fmtNum( nAposEm ), .T., 'FOLDER5', 'FOLDER6',,, '1' )
    aAdd( aDetTxt, 'CÁLCULO CONVENCIONAL' + CRLF + Replicate( '-', 60 ) + CRLF +;
                   'Produto: '+ AllTrim( cProduto ) +' - '+ AllTrim( cDesc ) + CRLF +;
                   iif( isInCallStack( 'U_JSORDPRD' ), 'Filial: consolidado entre as filiais selecionadas', 'Filial: '+ AllTrim( cFilSel ) ) + CRLF + CRLF +;
                   'A sugestão é calculada pela fórmula do perfil de cálculo em uso,' + CRLF +;
                   'seguida dos ajustes de lote. Navegue pelos itens da árvore para' + CRLF +;
                   'visualizar cada etapa.' )

    oTree:AddTreeItem( 'Fórmula: '+ AllTrim( cFormTx ), 'PMSTASK4',, '2' )
    aAdd( aDetTxt, 'FÓRMULA DO PERFIL DE CÁLCULO' + CRLF + Replicate( '-', 60 ) + CRLF +;
                   'Perfil..: '+ AllTrim( cPerfil ) + CRLF +;
                   'Fórmula.: '+ AllTrim( cFormTx ) + CRLF +;
                   'Expressão: '+ AllTrim( cFormVr ) )

    oTree:AddTreeItem( 'Variáveis da fórmula', 'PMSTASK4',, '3' )
    aAdd( aDetTxt, 'VARIÁVEIS DA FÓRMULA' + CRLF + Replicate( '-', 60 ) + CRLF +;
                   'Dias Pretendidos (nDias).......: '+ fmtNum( nDias ) + CRLF +;
                   'Lead Time (nLdTime)............: '+ fmtNum( nLdTime ) + CRLF +;
                   'Duração do Estoque (nPrjEst)...: '+ fmtNum( nPrjEst ) + CRLF +;
                   'Consumo Médio (nConMed)........: '+ AllTrim( Str( nConMed ) ) + CRLF +;
                   'Lote Mínimo (nLotMin)..........: '+ fmtNum( nLotMin ) + CRLF +;
                   'Qtde Embalagem (nQtdEmb).......: '+ fmtNum( nQtdEmb ) + CRLF +;
                   'Lote Econômico (nLotEco).......: '+ fmtNum( nLotEco ) + CRLF +;
                   'Estoque Mínimo (nEstSeg).......: '+ fmtNum( nEstSeg ) + CRLF +;
                   'Saldo em Estoque (nQtdEst).....: '+ fmtNum( nQtdEst ) + CRLF +;
                   'Empenhado (nQtdEmp)............: '+ fmtNum( nQtdEmp ) + CRLF +;
                   'Qtde Comprada (nQtdPed)........: '+ fmtNum( nQtdPed ) + CRLF +;
                   'Qtde Solicitada (nQtdSol)......: '+ fmtNum( nQtdSol ) + CRLF +;
                   'Qtde em O.P. (nQtdPrd).........: '+ fmtNum( nQtdPrd ) )

    oTree:AddTreeItem( 'Resultado da fórmula: '+ fmtNum( nResFor ), 'PMSTASK4',, '4' )
    aAdd( aDetTxt, 'RESULTADO DA FÓRMULA' + CRLF + Replicate( '-', 60 ) + CRLF +;
                   'Valor calculado (arredondado, mínimo zero): '+ fmtNum( nResFor ) )

    oTree:AddTreeItem( 'Lote mínimo ('+ fmtNum( nLotMin ) +'): '+ fmtNum( nAposLM ), 'PMSTASK4',, '5' )
    aAdd( aDetTxt, 'AJUSTE DE LOTE MÍNIMO' + CRLF + Replicate( '-', 60 ) + CRLF +;
                   'Quando a quantidade calculada for maior que zero e menor que o' + CRLF +;
                   'lote mínimo (B1_LM), a sugestão é elevada ao lote mínimo.' + CRLF + CRLF +;
                   'Antes: '+ fmtNum( nResFor ) +'  |  Depois: '+ fmtNum( nAposLM ) )

    oTree:AddTreeItem( 'Lote econômico ('+ fmtNum( nLotEco ) +'): '+ fmtNum( nAposLE ), 'PMSTASK4',, '6' )
    if lPriLE
        aAdd( aDetTxt, 'AJUSTE DE LOTE ECONÔMICO (priorizado nos parâmetros internos)' + CRLF + Replicate( '-', 60 ) + CRLF +;
                       'A sugestão é elevada ao próximo múltiplo do lote econômico (B1_LE).' + CRLF + CRLF +;
                       'Antes: '+ fmtNum( nAposLM ) +'  |  Depois: '+ fmtNum( nAposLE ) )
    else
        aAdd( aDetTxt, 'AJUSTE DE LOTE ECONÔMICO' + CRLF + Replicate( '-', 60 ) + CRLF +;
                       'A priorização do lote econômico está DESABILITADA nos parâmetros' + CRLF +;
                       'internos (PRILE = N): nenhum ajuste é aplicado nesta etapa.' + CRLF + CRLF +;
                       'Antes: '+ fmtNum( nAposLM ) +'  |  Depois: '+ fmtNum( nAposLE ) )
    endif

    oTree:AddTreeItem( 'Múltiplo de embalagem ('+ fmtNum( nQtdEmb ) +'): '+ fmtNum( nAposEm ), 'PMSTASK4',, '7' )
    aAdd( aDetTxt, 'AJUSTE DE MÚLTIPLO DE EMBALAGEM' + CRLF + Replicate( '-', 60 ) + CRLF +;
                   'A sugestão é elevada ao próximo múltiplo da quantidade por' + CRLF +;
                   'embalagem (B1_QE), quando cadastrada.' + CRLF + CRLF +;
                   'Antes: '+ fmtNum( nAposLE ) +'  |  Depois: '+ fmtNum( nAposEm ) + CRLF + CRLF +;
                   'SUGESTÃO FINAL: '+ fmtNum( nAposEm ) )

    oTree:EndTree()

return aDetTxt

/*/{Protheus.doc} askFil
Solicita ao usuário a filial a ser auditada quando a análise contempla mais de uma filial.
@type function
@version 20.0002
@author Jean Carlos Pandolfo Saggin
@since 09/07/2026
@param aFilSel, array, filiais da análise corrente
@return character, filial escolhida (vazio quando cancelado)
/*/
static function askFil( aFilSel )

    local oDlgFil  as object
    local oCombo   as object
    local cEscolha := aFilSel[1] as character
    local lOk      := .F. as logical

    DEFINE MSDIALOG oDlgFil TITLE 'Sequência de Cálculo' FROM 000,000 TO 110,260 PIXEL
    @ 008,010 SAY 'Selecione a filial a ser auditada:' SIZE 110,10 OF oDlgFil PIXEL
    @ 020,010 COMBOBOX oCombo VAR cEscolha ITEMS aFilSel SIZE 110,12 OF oDlgFil PIXEL
    @ 038,035 BUTTON 'Confirmar' SIZE 040,012 OF oDlgFil PIXEL ACTION ( lOk := .T., oDlgFil:End() )
    @ 038,080 BUTTON 'Cancelar' SIZE 040,012 OF oDlgFil PIXEL ACTION ( lOk := .F., oDlgFil:End() )
    ACTIVATE MSDIALOG oDlgFil CENTERED

    if ! lOk
        cEscolha := ""
    endif

return cEscolha

/*/{Protheus.doc} fmtNum
Formata um valor numérico para exibição nos painéis da sequência de cálculo.
@type function
@version 20.0002
@author Jean Carlos Pandolfo Saggin
@since 09/07/2026
@param nValor, numeric, valor
@return character, valor formatado
/*/
static function fmtNum( nValor )

    local cValor := "" as character

    default nValor := 0

    cValor := AllTrim( Transform( nValor, '@E 999,999,999.99' ) )

return cValor

/*/{Protheus.doc} hlp
Função facilitadora para utilização da função Help do Protheus.
@type function
@version 20.0002
@author Jean Carlos Pandolfo Saggin
@since 09/07/2026
@param cTitle, character, título da janela
@param cFail, character, informações sobre a falha
@param cHelp, character, informações com texto de ajuda
/*/
static function hlp( cTitle, cFail, cHelp )
return Help( ,, cTitle,, cFail, 1, 0, NIL, NIL, NIL, NIL, NIL, { cHelp } )

/*/{Protheus.doc} doReport
Exibe a tela de impressão (TReport) com os dados utilizados no rastreio da sugestão de
compra/produção exibida na tela Sequência de Cálculo, permitindo ao usuário escolher o formato
de saída desejado (impressora, PDF, Excel, HTML, etc.) na própria tela padrão de impressão do
Protheus. Quando a análise reversa está ativa para o produto (aTrace preenchido), monta a árvore
completa do trace materializado (PNC_RVTRC_<empresa>) e o resumo do componente auditado
(PNC_RVCALC_<empresa>); quando é o cálculo convencional (fórmula do perfil), monta as variáveis
da fórmula e os ajustes de lote aplicados (mesmo motor de buildConv/fCalNec). Em ambos os casos
inclui uma coluna de fórmula (nomes de variáveis simplificados, apenas para deixar claro como o
resultado foi obtido) e uma seção de legenda explicando cada variável/coluna e a origem do dado.
@type function
@version 21.0001
@author Jean Carlos Pandolfo Saggin
@since 22/07/2026
@param aTrace, array, linhas do trace da análise reversa (vazio quando cálculo convencional)
@param aCalRow, array, resultado consolidado (PNC_RVCALC) do componente auditado
@param oDescHM, object, hashmap código -> descrição dos produtos da cadeia (Nil no cálculo convencional)
@param cProduto, character, código do produto auditado
@param cFilSel, character, filial auditada
@param dDtCalc, date, data de referência do cálculo
/*/
static function doReport( aTrace, aCalRow, oDescHM, cProduto, cFilSel, dDtCalc )

    local oReport := Nil as object
    local cDesc    := "" as character

    Private lRepRev  := len( aTrace ) > 0 as logical
    Private aIdent   := {} as array
    Private aResumo  := {} as array
    Private aArvore  := {} as array
    Private aLegenda := {} as array
    Private aRepRows := {} as array
    Private nRepRow  := 0 as numeric

    if ValType( oDescHM ) == 'H'
        HMGet( oDescHM, cProduto, @cDesc )
    endif

    if lRepRev
        aIdent   := montaIdRv( cProduto, cDesc, cFilSel, dDtCalc, aCalRow )
        aResumo  := montaRes( aCalRow )
        aArvore  := montaArv( aTrace, oDescHM )
        aLegenda := montaLgRv()
    else
        aIdent   := montaIdCv( cProduto, cDesc, cFilSel )
        aResumo  := montaVarC()
        aArvore  := montaSeqC()
        aLegenda := montaLgCv()
    endif

    oReport := repSeqDef( lRepRev )
    oReport:PrintDialog()

return Nil

/*/{Protheus.doc} repSeqDef
Monta o modelo do relatório (TReport) com as seções utilizadas na exportação dos dados de
rastreio da sequência de cálculo: Identificação, Resumo/Variáveis, Árvore/Sequência de Cálculo e
Legenda. O layout das seções 2 e 3 varia conforme o modo de cálculo (análise reversa ou
convencional); a seção de Legenda é comum aos dois modos (mesmas 3 colunas).
@type function
@version 21.0001
@author Jean Carlos Pandolfo Saggin
@since 22/07/2026
@param lRev, logical, indica se o modo é análise reversa (.T.) ou cálculo convencional (.F.)
@return object, oReport
/*/
static function repSeqDef( lRev )

    local oReport   as object
    local oSecIdent as object
    local oSecRes   as object
    local oSecArv   as object
    local oSecLeg   as object
    local bReport   := {|oReport| repSeqBody( oReport ) }
    local cPicNum   := "@E 999,999,999.99"

    oReport := TReport():New( "JSSEQCAL",;
                              "SmartSupply - Dados de Rastreio da Sequência de Cálculo",;
                              Nil,;
                              bReport,;
                              Nil )
    oReport:SetTotalInLine( .F. )
    oReport:lParamPage := .F.
    oReport:oPage:SetPaperSize( 9 )         // Default tamanho A4
    oReport:cFontBody := 'Courier New'
    oReport:nFontBody := 6
    oReport:nLineHeight := 30
    oReport:SetLandscape()                  // Formato paisagem (comporta a seção de árvore com muitas colunas)

    // Seção 1 - Identificação (chave/valor) - mesma estrutura nos dois modos
    oSecIdent := TRSection():New( oReport, "Identificação", { "IDENT" } )
    oSecIdent:SetTotalInLine( .F. )
    oSecIdent:SetHeaderSection( .T. )
    TRCell():New( oSecIdent, "CAMPO", "IDENT", "Campo", Nil, 150, .T., {|| aRepRows[nRepRow][1] }, "LEFT", Nil, Nil, Nil, Nil, Nil, Nil, Nil )
    TRCell():New( oSecIdent, "VALOR", "IDENT", "Valor", Nil, 350, .T., {|| aRepRows[nRepRow][2] }, "LEFT", Nil, Nil, Nil, Nil, Nil, Nil, Nil )

    if lRev

        // Seção 2 - Resumo da sugestão (componente auditado)
        oSecRes := TRSection():New( oReport, "Resumo da Sugestão (Componente Auditado)", { "RESUMO" } )
        oSecRes:SetTotalInLine( .F. )
        oSecRes:SetHeaderSection( .T. )
        TRCell():New( oSecRes, "VARIAV", "RESUMO", "Variável",  Nil, 90,  .T., {|| aRepRows[nRepRow][1] }, "LEFT",  Nil, Nil, Nil, Nil, Nil, Nil, Nil )
        TRCell():New( oSecRes, "VALOR",  "RESUMO", "Valor",     cPicNum, 100, .T., {|| aRepRows[nRepRow][2] }, "RIGHT", Nil, Nil, Nil, Nil, Nil, Nil, Nil )
        TRCell():New( oSecRes, "FORMUL", "RESUMO", "Fórmula",   Nil, 500, .T., {|| aRepRows[nRepRow][3] }, "LEFT",  Nil, Nil, Nil, Nil, Nil, Nil, Nil )

        // Seção 3 - Árvore de rastreio (todos os nós visitados a partir do componente auditado)
        oSecArv := TRSection():New( oReport, "Árvore de Rastreio", { "ARVORE" } )
        oSecArv:SetTotalInLine( .F. )
        oSecArv:SetHeaderSection( .T. )
        TRCell():New( oSecArv, "NIVEL",  "ARVORE", "Nível",         Nil, 40,  .T., {|| aRepRows[nRepRow][01] }, "CENTER", Nil, Nil, Nil, Nil, Nil, Nil, Nil )
        TRCell():New( oSecArv, "TIPO",   "ARVORE", "Tipo",          Nil, 130, .T., {|| aRepRows[nRepRow][02] }, "LEFT",   Nil, Nil, Nil, Nil, Nil, Nil, Nil )
        TRCell():New( oSecArv, "PROD",   "ARVORE", "Produto",       Nil, 80,  .T., {|| aRepRows[nRepRow][03] }, "LEFT",   Nil, Nil, Nil, Nil, Nil, Nil, Nil )
        TRCell():New( oSecArv, "DESC",   "ARVORE", "Descrição",     Nil, 160, .T., {|| aRepRows[nRepRow][04] }, "LEFT",   Nil, Nil, Nil, Nil, Nil, Nil, Nil )
        TRCell():New( oSecArv, "PAI",    "ARVORE", "Produto Pai",   Nil, 80,  .T., {|| aRepRows[nRepRow][05] }, "LEFT",   Nil, Nil, Nil, Nil, Nil, Nil, Nil )
        TRCell():New( oSecArv, "DESCPAI","ARVORE", "Descrição Pai", Nil, 160, .T., {|| aRepRows[nRepRow][06] }, "LEFT",   Nil, Nil, Nil, Nil, Nil, Nil, Nil )
        TRCell():New( oSecArv, "QTPOR",  "ARVORE", "Qtd/Unid.",     cPicNum, 90, .T., {|| aRepRows[nRepRow][07] }, "RIGHT", Nil, Nil, Nil, Nil, Nil, Nil, Nil )
        TRCell():New( oSecArv, "NECBRT", "ARVORE", "Nec.Bruta",     cPicNum, 100, .T., {|| aRepRows[nRepRow][08] }, "RIGHT", Nil, Nil, Nil, Nil, Nil, Nil, Nil )
        TRCell():New( oSecArv, "ESTABT", "ARVORE", "Est.Abatido",   cPicNum, 100, .T., {|| aRepRows[nRepRow][09] }, "RIGHT", Nil, Nil, Nil, Nil, Nil, Nil, Nil )
        TRCell():New( oSecArv, "OPABT",  "ARVORE", "OP Abatida",    cPicNum, 100, .T., {|| aRepRows[nRepRow][10] }, "RIGHT", Nil, Nil, Nil, Nil, Nil, Nil, Nil )
        TRCell():New( oSecArv, "NECLIQ", "ARVORE", "Nec.Líquida",   cPicNum, 100, .T., {|| aRepRows[nRepRow][11] }, "RIGHT", Nil, Nil, Nil, Nil, Nil, Nil, Nil )
        TRCell():New( oSecArv, "CONTRIB","ARVORE", "Contribuição",  cPicNum, 100, .T., {|| aRepRows[nRepRow][12] }, "RIGHT", Nil, Nil, Nil, Nil, Nil, Nil, Nil )
        TRCell():New( oSecArv, "FORMUL", "ARVORE", "Fórmula",       Nil, 450, .T., {|| aRepRows[nRepRow][13] }, "LEFT",   Nil, Nil, Nil, Nil, Nil, Nil, Nil )

    else

        // Seção 2 - Variáveis da fórmula do perfil de cálculo
        oSecRes := TRSection():New( oReport, "Variáveis da Fórmula", { "VARIAV" } )
        oSecRes:SetTotalInLine( .F. )
        oSecRes:SetHeaderSection( .T. )
        TRCell():New( oSecRes, "VARIAV", "VARIAV", "Variável", Nil, 200, .T., {|| aRepRows[nRepRow][1] }, "LEFT",  Nil, Nil, Nil, Nil, Nil, Nil, Nil )
        TRCell():New( oSecRes, "VALOR",  "VARIAV", "Valor",    cPicNum, 100, .T., {|| aRepRows[nRepRow][2] }, "RIGHT", Nil, Nil, Nil, Nil, Nil, Nil, Nil )

        // Seção 3 - Sequência de cálculo (etapas até a sugestão final)
        oSecArv := TRSection():New( oReport, "Sequência de Cálculo", { "SEQCAL" } )
        oSecArv:SetTotalInLine( .F. )
        oSecArv:SetHeaderSection( .T. )
        TRCell():New( oSecArv, "ETAPA",  "SEQCAL", "Etapa",       Nil, 220, .T., {|| aRepRows[nRepRow][1] }, "LEFT",  Nil, Nil, Nil, Nil, Nil, Nil, Nil )
        TRCell():New( oSecArv, "ANTES",  "SEQCAL", "Valor Antes", cPicNum, 100, .T., {|| aRepRows[nRepRow][2] }, "RIGHT", Nil, Nil, Nil, Nil, Nil, Nil, Nil )
        TRCell():New( oSecArv, "DEPOIS", "SEQCAL", "Valor Depois",cPicNum, 100, .T., {|| aRepRows[nRepRow][3] }, "RIGHT", Nil, Nil, Nil, Nil, Nil, Nil, Nil )
        TRCell():New( oSecArv, "FORMUL", "SEQCAL", "Fórmula",     Nil, 500, .T., {|| aRepRows[nRepRow][4] }, "LEFT",  Nil, Nil, Nil, Nil, Nil, Nil, Nil )

    endif

    // Seção 4 - Legenda das variáveis/colunas (mesma estrutura nos dois modos)
    oSecLeg := TRSection():New( oReport, "Legenda das Variáveis/Colunas", { "LEGENDA" } )
    oSecLeg:SetTotalInLine( .F. )
    oSecLeg:SetHeaderSection( .T. )
    TRCell():New( oSecLeg, "VARIAV", "LEGENDA", "Variável",     Nil, 120, .T., {|| aRepRows[nRepRow][1] }, "LEFT", Nil, Nil, Nil, Nil, Nil, Nil, Nil )
    TRCell():New( oSecLeg, "SIGNIF", "LEGENDA", "Significado",  Nil, 400, .T., {|| aRepRows[nRepRow][2] }, "LEFT", Nil, Nil, Nil, Nil, Nil, Nil, Nil )
    TRCell():New( oSecLeg, "ORIGEM", "LEGENDA", "Origem do Dado", Nil, 350, .T., {|| aRepRows[nRepRow][3] }, "LEFT", Nil, Nil, Nil, Nil, Nil, Nil, Nil )

return oReport

/*/{Protheus.doc} repSeqBody
Executa a impressão de todas as seções do relatório da sequência de cálculo, alimentando cada
seção a partir do array correspondente (Private aIdent/aResumo/aArvore/aLegenda), por meio do
ponteiro de linha corrente (Private aRepRows/nRepRow) lido pelos codeblocks das TRCell.
@type function
@version 21.0001
@author Jean Carlos Pandolfo Saggin
@since 22/07/2026
@param oReport, object, modelo do relatório montado em repSeqDef
/*/
static function repSeqBody( oReport )

    local nX := nRepRow

    // Seção 1 - Identificação
    aRepRows := aIdent
    oReport:Section(1):Init()
    for nX := 1 to len( aRepRows )
        nRepRow := nX
        oReport:Section(1):PrintLine()
    next nX
    oReport:Section(1):Finish()

    // Seção 2 - Resumo (reversa) ou Variáveis da fórmula (convencional)
    aRepRows := aResumo
    oReport:Section(2):Init()
    for nX := 1 to len( aRepRows )
        nRepRow := nX
        oReport:Section(2):PrintLine()
    next nX
    oReport:Section(2):Finish()

    // Seção 3 - Árvore de rastreio (reversa) ou Sequência de cálculo (convencional)
    aRepRows := aArvore
    oReport:Section(3):Init()
    for nX := 1 to len( aRepRows )
        nRepRow := nX
        oReport:Section(3):PrintLine()
    next nX
    oReport:Section(3):Finish()

    // Seção 4 - Legenda
    aRepRows := aLegenda
    oReport:Section(4):Init()
    for nX := 1 to len( aRepRows )
        nRepRow := nX
        oReport:Section(4):PrintLine()
    next nX
    oReport:Section(4):Finish()

return Nil

/*/{Protheus.doc} montaIdRv
Monta as linhas (Campo;Valor) da seção de identificação para o modo de análise reversa.
@type function
@version 21.0001
@author Jean Carlos Pandolfo Saggin
@since 22/07/2026
@param cProduto, character, código do produto auditado
@param cDesc, character, descrição do produto auditado
@param cFilSel, character, filial auditada
@param dDtCalc, date, data de referência do cálculo
@param aCalRow, array, resultado consolidado (PNC_RVCALC) do componente auditado
@return array, aIdent
/*/
static function montaIdRv( cProduto, cDesc, cFilSel, dDtCalc, aCalRow )

    local aIdent := {} as array

    aAdd( aIdent, { "Modo de cálculo", "Análise reversa de estruturas" } )
    aAdd( aIdent, { "Produto auditado", AllTrim( cProduto ) +' - '+ cDesc } )
    aAdd( aIdent, { "Filial", cFilSel } )
    aAdd( aIdent, { "Data do cálculo", DtoC( dDtCalc ) } )
    aAdd( aIdent, { "Execução (DTEXEC)", AllTrim( aCalRow[8] ) } )

return aIdent

/*/{Protheus.doc} montaIdCv
Monta as linhas (Campo;Valor) da seção de identificação para o modo de cálculo convencional.
@type function
@version 21.0001
@author Jean Carlos Pandolfo Saggin
@since 22/07/2026
@param cProduto, character, código do produto auditado
@param cDesc, character, descrição do produto auditado
@param cFilSel, character, filial auditada
@return array, aIdent
/*/
static function montaIdCv( cProduto, cDesc, cFilSel )

    local aIdent   := {} as array
    local cFormTx  := U_JSFRMTXT( cPerfil, .F. )
    local cFormVr  := U_JSFRMTXT( cPerfil, .T. )

    aAdd( aIdent, { "Modo de cálculo", "Cálculo convencional (fórmula do perfil)" } )
    aAdd( aIdent, { "Produto auditado", AllTrim( cProduto ) +' - '+ cDesc } )
    aAdd( aIdent, { "Filial", cFilSel } )
    aAdd( aIdent, { "Perfil de cálculo", AllTrim( cPerfil ) } )
    aAdd( aIdent, { "Fórmula do perfil", cFormTx } )
    aAdd( aIdent, { "Expressão avaliada", cFormVr } )

return aIdent

/*/{Protheus.doc} montaRes
Monta as linhas (Variável;Valor;Fórmula) do resumo da sugestão do componente auditado, a partir
do resultado consolidado (PNC_RVCALC).
@type function
@version 21.0001
@author Jean Carlos Pandolfo Saggin
@since 22/07/2026
@param aCalRow, array, resultado consolidado (PNC_RVCALC) do componente auditado
@return array, aResumo
/*/
static function montaRes( aCalRow )

    local aResumo := {} as array

    aAdd( aResumo, { "DEMESTR", aCalRow[2], "DEMESTR = soma( NECLIQ dos produtos que usam este componente x QTPOR ) - baseada na média de venda dos PAs cuja MP é componente" } )
    aAdd( aResumo, { "DEMLDT",  aCalRow[9], "DEMLDT = ( DEMESTR / PRJEST ) x LEADTIME - quantidade adicional pelo lead time do fornecedor da MP, calculada somente quando o parâmetro CONSLT está ativo" } )
    aAdd( aResumo, { "DEMVND",  aCalRow[3], "DEMVND = VENDIA x ( PRJEST + LEADTIME, quando o parâmetro CONSLT está ativo )" } )
    aAdd( aResumo, { "VENDIA",  aCalRow[4], "VENDIA = venda direta do componente no período / dias do período" } )
    aAdd( aResumo, { "CONDIA",  aCalRow[5], "CONDIA = consumo interno do componente no período / dias do período (referência, não entra na fórmula)" } )
    aAdd( aResumo, { "POSABT",  aCalRow[6], "POSABT = estoque disponível + pedidos em carteira + solicitações" } )
    aAdd( aResumo, { "NFINAIS", aCalRow[7], "Quantidade de produtos finais distintos que dependem deste componente" } )
    aAdd( aResumo, { "NECREV",  aCalRow[1], "NECREV = AplicaLotes( Round( DEMESTR + DEMLDT + DEMVND - POSABT, 0 ) )  <- SUGESTÃO FINAL" } )

return aResumo

/*/{Protheus.doc} montaArv
Monta as linhas da árvore de rastreio (todos os nós visitados a partir do componente auditado),
com uma coluna de fórmula por linha explicando como cada valor foi obtido.
@type function
@version 21.0001
@author Jean Carlos Pandolfo Saggin
@since 22/07/2026
@param aTrace, array, linhas do trace da análise reversa
@param oDescHM, object, hashmap código -> descrição dos produtos da cadeia
@return array, aArvore
/*/
static function montaArv( aTrace, oDescHM )

    local aArvore  := {} as array
    local cDescNo  := "" as character
    local cDescPai := "" as character
    local cTipoDsc := "" as character
    local cForm    := "" as character
    local nX       := 0 as numeric

    for nX := 1 to len( aTrace )

        cDescNo  := ""
        cDescPai := ""
        HMGet( oDescHM, aTrace[nX][TRC_PROD], @cDescNo )
        if ! Empty( aTrace[nX][TRC_PAI] )
            HMGet( oDescHM, aTrace[nX][TRC_PAI], @cDescPai )
        endif

        if aTrace[nX][TRC_TIPO] == 'M'
            cTipoDsc := 'Componente auditado'
            cForm    := 'NECBRT = soma das CONTRIB de quem usa este produto (ver DEMVND/NECREV no resumo)'
        elseif aTrace[nX][TRC_TIPO] == 'F'
            cTipoDsc := 'Produto final (raiz da cadeia)'
            cForm    := 'NECLIQ = cálculo convencional do produto final (fórmula do perfil, fora desta árvore)'
        else
            cTipoDsc := 'Intermediário'
            cForm    := 'NECLIQ = NECBRT - ESTABT - OPABT'
        endif

        aAdd( aArvore, { aTrace[nX][TRC_NIVEL],;
                          cTipoDsc,;
                          AllTrim( aTrace[nX][TRC_PROD] ),;
                          cDescNo,;
                          AllTrim( aTrace[nX][TRC_PAI] ),;
                          cDescPai,;
                          aTrace[nX][TRC_QTPOR],;
                          aTrace[nX][TRC_NECBRT],;
                          aTrace[nX][TRC_ESTABT],;
                          aTrace[nX][TRC_OPABT],;
                          aTrace[nX][TRC_NECLIQ],;
                          aTrace[nX][TRC_CONTRIB],;
                          cForm } )

    next nX

return aArvore

/*/{Protheus.doc} montaVarC
Monta as linhas (Variável;Valor) das variáveis da fórmula do perfil de cálculo em uso na tela
(mesmas variáveis utilizadas por buildConv/fCalNec).
@type function
@version 21.0001
@author Jean Carlos Pandolfo Saggin
@since 22/07/2026
@return array, aVariav
/*/
static function montaVarC()

    local aVariav := {} as array

    aAdd( aVariav, { "nDias (Dias Pretendidos)",     nDias } )
    aAdd( aVariav, { "nLdTime (Lead Time)",          nLdTime } )
    aAdd( aVariav, { "nPrjEst (Duração do Estoque)", nPrjEst } )
    aAdd( aVariav, { "nConMed (Consumo Médio)",      nConMed } )
    aAdd( aVariav, { "nLotMin (Lote Mínimo)",        nLotMin } )
    aAdd( aVariav, { "nQtdEmb (Qtde Embalagem)",     nQtdEmb } )
    aAdd( aVariav, { "nLotEco (Lote Econômico)",     nLotEco } )
    aAdd( aVariav, { "nEstSeg (Estoque Mínimo)",     nEstSeg } )
    aAdd( aVariav, { "nQtdEst (Saldo em Estoque)",   nQtdEst } )
    aAdd( aVariav, { "nQtdEmp (Empenhado)",          nQtdEmp } )
    aAdd( aVariav, { "nQtdPed (Qtde Comprada)",      nQtdPed } )
    aAdd( aVariav, { "nQtdSol (Qtde Solicitada)",    nQtdSol } )
    aAdd( aVariav, { "nQtdPrd (Qtde em O.P.)",       nQtdPrd } )

return aVariav

/*/{Protheus.doc} montaSeqC
Monta as linhas (Etapa;Antes;Depois;Fórmula) da sequência de cálculo do modo convencional,
reproduzindo passo a passo o mesmo motor de buildConv/fCalNec (fórmula do perfil seguida dos
ajustes de lote mínimo, lote econômico e múltiplo de embalagem).
@type function
@version 21.0001
@author Jean Carlos Pandolfo Saggin
@since 22/07/2026
@return array, aSeqCal
/*/
static function montaSeqC()

    local aSeqCal  := {} as array
    local cFormVr  := U_JSFRMTXT( cPerfil, .T. )
    local lPriLE   := aConfig[19] == 'S'
    local cDscLE   := "" as character
    local nResFor  := 0 as numeric
    local nAposLM  := 0 as numeric
    local nAposLE  := 0 as numeric
    local nAposEm  := 0 as numeric

    if Empty( cFormVr )
        nResFor := 0
    else
        nResFor := Round( &( cFormVr ), 0 )
        if nResFor < 0
            nResFor := 0
        endif
    endif

    nAposLM := U_JSAPLLOT( nResFor, nLotMin, 0, 0, .F. )
    nAposLE := U_JSAPLLOT( nAposLM, 0, nLotEco, 0, lPriLE )
    nAposEm := U_JSAPLLOT( nAposLE, 0, 0, nQtdEmb, .F. )

    if lPriLE
        cDscLE := 'Eleva ao próximo múltiplo do lote econômico (B1_LE) - priorização ativa (PRILE=S)'
    else
        cDscLE := 'Priorização de lote econômico desabilitada (PRILE=N): nenhum ajuste aplicado'
    endif

    aAdd( aSeqCal, { "Resultado da fórmula",         0,        nResFor, "Resultado = Round( "+ AllTrim( cFormVr ) +", 0 ), mínimo zero" } )
    aAdd( aSeqCal, { "Ajuste lote mínimo",           nResFor,  nAposLM, "Quando 0 < Resultado < nLotMin, eleva a sugestão ao lote mínimo (B1_LM)" } )
    aAdd( aSeqCal, { "Ajuste lote econômico",        nAposLM,  nAposLE, cDscLE } )
    aAdd( aSeqCal, { "Ajuste múltiplo de embalagem", nAposLE,  nAposEm, "Eleva ao próximo múltiplo da quantidade por embalagem (B1_QE), quando cadastrada  <- SUGESTÃO FINAL" } )

return aSeqCal

/*/{Protheus.doc} montaLgRv
Monta as linhas (Variável;Significado;Origem) da legenda para o modo de análise reversa.
@type function
@version 21.0001
@author Jean Carlos Pandolfo Saggin
@since 22/07/2026
@return array, aLegenda
/*/
static function montaLgRv()

    local aLegenda := {} as array

    aAdd( aLegenda, { "NIVEL", "Nível do nó na árvore ascendente (0 = componente auditado, subindo até os produtos finais)", "Campo NIVEL de PNC_RVTRC_<empresa>" } )
    aAdd( aLegenda, { "TIPO", "M=Componente auditado (raiz da consulta) | I=Intermediário (possui pai e filhos na estrutura) | F=Produto final (sem pais)", "Classificado no momento da consulta a partir de PNC_RVTRC" } )
    aAdd( aLegenda, { "PRODUTO / PRODUTO PAI", "Código do produto do nó e do produto do nível imediatamente acima (quem consome o produto do nível atual)", "Campos PROD e PAI de PNC_RVTRC / SB1.B1_COD" } )
    aAdd( aLegenda, { "QTPOR", "Quantidade do produto do nível atual utilizada para produzir 1 unidade do produto pai", "Campo QTPOR de PNC_RVTRC, origem SG1.G1_QUANT" } )
    aAdd( aLegenda, { "NECBRT", "Necessidade bruta do nó, antes de abater estoque/OPs (soma das contribuições de todos os pais que usam este produto)", "Campo NECBRT de PNC_RVTRC" } )
    aAdd( aLegenda, { "ESTABT", "Estoque disponível abatido da necessidade bruta deste nó", "Campo ESTABT de PNC_RVTRC, origem SB2 (saldo) e reserva/empenho quando parametrizado" } )
    aAdd( aLegenda, { "OPABT", "Ordens de produção em aberto abatidas da necessidade bruta deste nó", "Campo OPABT de PNC_RVTRC, origem SC2 (ordens de produção em aberto)" } )
    aAdd( aLegenda, { "NECLIQ", "Necessidade líquida do nó (bruta - estoque - OPs, ou fórmula do perfil quando produto final)", "Campo NECLIQ de PNC_RVTRC" } )
    aAdd( aLegenda, { "CONTRIB", "Contribuição que este nó desce para o nível abaixo (necessidade líquida x quantidade por unidade)", "Campo CONTRIB de PNC_RVTRC" } )
    aAdd( aLegenda, { "DEMESTR", "Demanda derivada das estruturas (soma das contribuições líquidas dos produtos que utilizam este componente, baseada na média de venda dos PAs cuja MP é componente). Valor bruto, sem a parcela de lead time (ver DEMLDT)", "Campo DEMESTR de PNC_RVCALC_<empresa>" } )
    aAdd( aLegenda, { "DEMLDT", "Quantidade adicional sugerida em virtude do lead time de entrega do fornecedor da MP, calculada à parte da demanda estrutural bruta (média diária de DEMESTR x dias de lead time). Só é calculada quando o parâmetro CONSLT está ativo; zero caso contrário", "Campo DEMLDT de PNC_RVCALC_<empresa>" } )
    aAdd( aLegenda, { "DEMVND", "Parcela de venda direta do componente (média diária de venda x horizonte de dias, estendido pelo lead time do fornecedor quando o parâmetro CONSLT está ativo)", "Campo DEMVND de PNC_RVCALC" } )
    aAdd( aLegenda, { "VENDIA", "Média diária de venda direta do componente no período de análise", "Campo VENDIA de PNC_RVCALC, origem SD2 (notas de saída que movimentam estoque)" } )
    aAdd( aLegenda, { "CONDIA", "Média diária de consumo interno do componente em produção no período de análise. Referência informativa, não participa da fórmula da sugestão", "Campo CONDIA de PNC_RVCALC, origem SD3 (requisições de baixa por produção, TM >= 500)" } )
    aAdd( aLegenda, { "POSABT", "Posição abatida do componente (estoque disponível + pedidos de compra em carteira + solicitações de compra)", "Campo POSABT de PNC_RVCALC, origem SB2/SC7/SC1" } )
    aAdd( aLegenda, { "NFINAIS", "Quantidade de produtos finais distintos que dependem deste componente na cadeia de estruturas", "Campo NFINAIS de PNC_RVCALC" } )
    aAdd( aLegenda, { "NECREV", "Sugestão final de compra/produção do componente, após ajustes de lote (mínimo, econômico e embalagem)", "Campo NECREV de PNC_RVCALC" } )
    aAdd( aLegenda, { "PRJEST", "Dias padrão de cobertura de estoque configurados no Painel de Compras (Proj.Estoque)", "Parâmetro interno PRJEST de PNC_CONFIG_<empresa>" } )
    aAdd( aLegenda, { "LEADTIME", "Lead time de entrega considerado para o componente: prioriza o cadastro do produto (B1_PE); quando ausente e o parâmetro CONSLT está ativo, usa o lead time médio do fornecedor vinculado", "SB1.B1_PE ou SA5/SA2.A2_X_LTIME" } )
    aAdd( aLegenda, { "CONSLT", "Parâmetro interno que indica se o lead time do fornecedor deve ser somado ao horizonte de cobertura da venda direta (DEMVND) e usado como fallback quando o produto não possui B1_PE cadastrado", "Campo CONSLT de PNC_CONFIG_<empresa>" } )

return aLegenda

/*/{Protheus.doc} montaLgCv
Monta as linhas (Variável;Significado;Origem) da legenda para o modo de cálculo convencional.
@type function
@version 21.0001
@author Jean Carlos Pandolfo Saggin
@since 22/07/2026
@return array, aLegenda
/*/
static function montaLgCv()

    local aLegenda := {} as array

    aAdd( aLegenda, { "nDias", "Quantidade de dias pretendidos para a próxima compra, definida pelo usuário na tela principal", "Campo Dias da tela principal (nSpinBx)" } )
    aAdd( aLegenda, { "nLdTime", "Lead time de entrega considerado para o produto", "SB1.B1_PE, ou lead time do fornecedor (A2_X_LTIME/média histórica) quando o produto não tem B1_PE cadastrado" } )
    aAdd( aLegenda, { "nPrjEst", "Duração projetada do estoque atual em dias, considerando o consumo médio", "Calculado no recálculo de índices (U_GMINDPRO), a partir do saldo em estoque e do consumo médio" } )
    aAdd( aLegenda, { "nConMed", "Consumo médio diário do produto (venda + consumo de produção) no período de análise configurado", "Calculado no recálculo de índices, origem SD2 (vendas) e SD3 (consumo em produção)" } )
    aAdd( aLegenda, { "nLotMin", "Lote mínimo de compra do produto", "SB1.B1_LM" } )
    aAdd( aLegenda, { "nQtdEmb", "Quantidade por embalagem do produto", "SB1.B1_QE" } )
    aAdd( aLegenda, { "nLotEco", "Lote econômico do produto", "SB1.B1_LE" } )
    aAdd( aLegenda, { "nEstSeg", "Estoque mínimo/de segurança do produto", "SB1.B1_EMIN" } )
    aAdd( aLegenda, { "nQtdEst", "Saldo em estoque do produto nos armazéns configurados", "SB2.B2_QATU (armazéns configurados em Locais de Estoque)" } )
    aAdd( aLegenda, { "nQtdEmp", "Quantidade empenhada/reservada do produto", "SB2.B2_RESERVA (quando o parâmetro de dedução de empenho está ativo)" } )
    aAdd( aLegenda, { "nQtdPed", "Quantidade em pedidos de compra em carteira", "SC7.C7_QUANT - C7_QUJE" } )
    aAdd( aLegenda, { "nQtdSol", "Quantidade em solicitações de compra sem pedido vinculado", "SC1.C1_QUANT" } )
    aAdd( aLegenda, { "nQtdPrd", "Quantidade em ordens de produção em aberto", "SC2.C2_QUANT - C2_QUJE" } )

return aLegenda
