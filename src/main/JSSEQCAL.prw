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
@param cProduto, character, código do produto posicionado na grid principal
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
    if Type( '_aFil' ) == 'A' .and. len( _aFil ) > 1
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
    if len( aTrace ) > 0
        oDlgSeq:SetSubTitle( 'Análise reversa de estruturas - filial '+ AllTrim( cFilSel ) +' - cálculo de '+ DtoC( dDtCalc ) )
    else
        oDlgSeq:SetSubTitle( 'Cálculo convencional (fórmula do perfil) - filial '+ AllTrim( cFilSel ) )
    endif
    oDlgSeq:EnableAllClient()
    oDlgSeq:CreateDialog()
    oDlgSeq:AddCloseButton( {|| oDlgSeq:DeActivate() }, "Fechar" )

    // Painel esquerdo: árvore da sequência de cálculo | Painel direito: detalhes do nó selecionado
    oPanTre := TPanel():New( ,,, oDlgSeq:getPanelMain() )
    oPanTre:Align := CONTROL_ALIGN_LEFT
    oPanTre:nWidth := 480
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
        aDetTxt := buildRev( oTree, aTrace, aCalRow, oDescHM, dDtCalc )
    else
        aDetTxt := buildConv( oTree, cProduto, cFilSel )
    endif

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
@return array, { necrev, demestr, demvnd, vendia, condia, posabt, nfinais, dtexec } ou vazio
/*/
static function loadCal( cTabCal, cFilCal, cProduto, dDtCalc )

    local aCalRow := {} as array
    local cQuery  := "" as character
    local cAlias  := GetNextAlias()

    cQuery := "SELECT NECREV, DEMESTR, DEMVND, VENDIA, CONDIA, POSABT, NFINAIS, DTEXEC " + CEOL
    cQuery += "FROM "+ cTabCal +" " + CEOL
    cQuery += "WHERE FILIAL = '"+ cFilCal +"' " + CEOL
    cQuery += "  AND PROD   = '"+ cProduto +"' " + CEOL
    cQuery += "  AND DTCALC = '"+ DtoS( dDtCalc ) +"' " + CEOL
    cQuery += "  AND D_E_L_E_T_ = ' ' " + CEOL

    DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), cAlias, .F., .T. )
    if ! ( cAlias )->( EOF() )
        aCalRow := { ( cAlias )->NECREV,;
                     ( cAlias )->DEMESTR,;
                     ( cAlias )->DEMVND,;
                     ( cAlias )->VENDIA,;
                     ( cAlias )->CONDIA,;
                     ( cAlias )->POSABT,;
                     ( cAlias )->NFINAIS,;
                     ( cAlias )->DTEXEC }
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

    nAntLot := aCalRow[2] + aCalRow[3] - aCalRow[6]
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
    cTxt += '    (soma das contribuições líquidas dos produtos que utilizam este componente)' + CRLF
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
                   'Filial: '+ AllTrim( cFilSel ) + CRLF + CRLF +;
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
