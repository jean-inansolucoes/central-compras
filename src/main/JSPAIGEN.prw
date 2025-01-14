#include 'totvs.ch'
#include 'topconn.ch'
#include 'fwmvcdef.ch'

#define CEOL Chr(13)+Chr(10)

/*/{Protheus.doc} JSGETVER
Retorna a versão do aplicativo.
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 30/08/2024
@return character, cDetVer
/*/
user function JSGETVER()

    local cDetVer := "" as character
    local aDetVer := {} as array
    aDetVer := U_JSDETVER()
    cDetVer := aDetVer[len(aDetVer)][1] /* cDictVersion */ +'.'+;
                aDetVer[len(aDetVer)][2] /* cAppVersion */+' ('+;
                aDetVer[len(aDetVer)][3] /* cDate */+')'
return cDetVer

/*/{Protheus.doc} JSDETVER
Função com detalhamento das versões do aplicativo.
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 30/08/2024
@return array, aDetVer
/*/
user function JSDETVER()
    local aDetVer := {} as array
    aAdd( aDetVer, { '01','0001','18/09/2024', 'Versão inicial do Painel de Compras' } )
    aAdd( aDetVer, { '02','0002','20/09/2024', 'Permite informar valor de frete ao pedido de compra e também informar um código de transportadora relacionado ao processo.' } )
    aAdd( aDetVer, { '02','0003','20/09/2024', 'Permitir informar frete em percentual' } )
    aAdd( aDetVer, { '02','0004','21/09/2024', 'Permitir editar alíquota de IPI diretamente no carrinho' } )
    aAdd( aDetVer, { '02','0005','03/10/2024', 'Liberar edição de campos para simulação de preço na tela de consulta de notas' } )
    aAdd( aDetVer, { '03','0006','06/10/2024', 'Permitir definir índice de lucro desejável por produto' } )
    aAdd( aDetVer, { '04','0001','16/10/2024', 'Controle de execução do JOB de recálculo dos índices individuais dos produtos' } )
    aAdd( aDetVer, { '04','0002','17/10/2024', 'Painel de Compras Multi-Filial' } )
    aAdd( aDetVer, { '05','0001','12/11/2024', 'Adaptação para release 12.1.2410 usando smartclient webapp' } )
    aAdd( aDetVer, { '05','0002','13/11/2024', 'Novo formato de filtros, remodelagem da engine de cálculos e substituição de componentes obsoletos' } )
    aAdd( aDetVer, { '05','0003','13/11/2024', 'Workflow automático para fornecedor' } )
    aAdd( aDetVer, { '06','0001','21/11/2024', 'Adição de rotina para recálculo manual dos índices dos produtos, adequações de consultas do recálculo por JOB' } )
    aAdd( aDetVer, { '07','0001','02/01/2025', 'Novas melhorias no motor de cálculo de necessidade de compra, workflow de ruptura, nova feature de formação de preços' } )
    aAdd( aDetVer, { '07','0002','03/01/2025', 'Ajustar máscara do campo consumo médio e ajustado query de consulta de pedidos em carteira' } )
    aAdd( aDetVer, { '07','0003','13/01/2025', 'Ajuste refresh da tela de formação de preços, acesso a formação de preços pelo documento de entrada, '+;
                                                'alinhamento de labels na tela de formação de preços.' } )
return aDetVer

/*/{Protheus.doc} JSFILIAL
Função para retornar expressão de filial conforme configurações de cada tabela.
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 07/10/2024
@param cAlias, character, alias da tabela que se deseja executar um filtro de filial
@param aFil, array, vetor com filiais que se deseja filtrar
@return character, cFilExp
/*/
user function JSFILIAL( cAlias, aFil )
    
    local cFilExp := "" as character
    local aUsed   := {} as array
    local nSize   := Len( AllTrim( FWxFilial( cAlias ) ) )
    local nFil    := 0 as numeric
    local cAux    := "" as character
    local cField  := iif( SubStr( cAlias, 01, 01 ) == 'S', SubStr( cAlias, 02,02 ) +'_FILIAL', cAlias +'_FILIAL' )
    local nAux    := 0 as numeric

    if nSize > 0 

        // Repassa todas as filiais selecionadas pelo usuário e monta um subvetor com as filiais já compatibilizadas com o tamanho utilizado pela tabela
        for nFil := 1 to len(aFil)
            cAux := SubStr( aFil[nFil], 01, nSize )
            if aScan( aUsed, {|x| AllTrim(x) == AllTrim(cAux) } ) == 0
                aAdd( aUsed, PADR(cAux, TAMSX3( cField )[1], ' ' ) )
            endif
        next nFil
       
        // Monta expressão IN para uso na query
        if len( aUsed ) == 0
            cFilExp := " = '"+ Replicate( 'Z', TAMSX3( cField )[1] ) +"' "
        elseif len( aUsed ) == 1        // Se foi selecionado apenas uma filial, muda a expressão da query para dar mais performance
            cFilExp := " = '"+ aUsed[1] +"' "
        else
            cFilExp := " IN ( "
            aEval( aUsed, {|x| nAux++, cFilExp += "'"+ x +"'" + iif( nAux < len( aUsed ), ',', '' ) } )        
            cFilExp += " ) "
        endif

    elseif nSize == 0 .and. len( aFil ) > 0                 // Se existir filial selecionada e o tamanho do campo for zero
        cFilExp := " = '"+ FWxFilial( cAlias ) +"' "

    elseif nSize == 0 .and. len( aFil ) == 0                // Erra o filtro propositalmente para fazer com que o banco não retorne nenhum registro.
        cFilExp := " <> '"+ FWxFilial( cAlias ) +"'  "  
    endif

return cFilExp

/*/{Protheus.doc} JSFILCOM
Função para retornar algoritmo de comparação entre os campos filiais de dois alíases diferentes
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 14/10/2024
@param cLeft, character, tabela da esquerda de onde está vindo o dado para ser comparado
@param cRight, character, tabela da difeita onde está sendo executado o filtro para encontrar os dados relacionados
@param cAliasLeft, character, alias atribuído à tabela na query (não obrigatório)
@param cAliasRight, character, alias atribuído à tabela na query (não obrigatório)
@return character, cExpression
/*/
// User Function JSFILCOM( cLeft, cRight, cAliasLeft, cAliasRight )

//     local cFunction   := iif( TCGetDB() $ "MSSQL|POSTGRES", "SUBSTRING", "SUBSTR" )
//     local cExpression := "" as character
//     local cFieldLeft  := iif( SubStr( cLeft,1,1 ) == 'S', SubStr( cLeft,2,2 ), cLeft ) + '_FILIAL'
//     local cFieldRight := iif( SubStr( cRight,1,1 ) == 'S', SubStr( cRight,2,2 ), cRight ) + '_FILIAL'
//     local cALeft      := "" as character
//     local cARight     := "" as character
    
//     default cAliasLeft  := iif( SubStr( cLeft,1,1 ) == 'S', SubStr( cLeft,2,2 ), cLeft )
//     default cAliasRight := iif( SubStr( cRight,1,1 ) == 'S', SubStr( cRight,2,2 ), cRight )
    
//     cALeft := cAliasLeft+'.'
//     cARight := cAliasRight+'.'

//     // Verifica se a tratativa de filial é diferente para as duas tabelas
//     if ! Len(AllTrim(FWxFilial( cLeft ))) == Len(AllTrim(FWxFilial( cRight )))

//         // Se for diferente, verifica se a tabela da esquerda usa filial compartilhada
//         if Len( AllTrim( FWxFilial( cLeft ) ) ) == 0

//             // Se usa filial compartilhada, apenas compara com FWxFilial, pois a expressão ficará assim: A1_FILIAL = '  '
//             cExpression := cALeft + cFieldLeft +" = '"+ FWxFilial( cLeft ) +"' "
        
//         // Verifica se a tabela da direita usa filial compartilhada
//         elseif Len( AllTrim( FWxFilial( cRight ) ) ) == 0
        
//             // Se usa filial compartilhada, chama função que retorna um filtro IN para a SQL usando as filiais selecionadas pelo usuário para filtrar os registros do alias da esquerda
//             cExpression := cALeft + cFieldLeft + U_JSFILIAL( cLeft, _aFil ) + ' '
        
//         // Verifica se o tamanho do conteúdo da filial da tabela da esquerda é menor do que o da direita
//         elseif Len( AllTrim( FWxFilial( cLeft ) ) ) < Len( AllTrim( FWxFilial( cRight ) ) )

//             // Se a informação da filial da tabel a da esquerda for menor do que a informação da filial da tabela da direita, compara as duas usando substring para adequar o tamanho das duas informações
//             cExpression := cFunction +'('+ cALeft + cFieldLeft +',1,'+ cValToChar( Len( AllTrim( FWxFilial( cLeft ) ) ) ) +') = '+ cFunction +'('+ cARight + cFieldRight +',1,'+ cValToChar( Len( AllTrim( FWxFilial( cLeft ) ) ) ) +') '
//         else
//             cExpression := cFunction +'('+ cALeft + cFieldLeft +',1,'+ cValToChar( Len( AllTrim( FWxFilial( cRight ) ) ) ) +') = '+ cFunction +'('+ cARight + cFieldRight +',1,'+ cValToChar( Len( AllTrim( FWxFilial( cRight ) ) ) ) +') '
//         endif

//     else
//         cExpression := cALeft + cFieldLeft + ' = ' + cARight + cFieldRight
//     endif

// return cExpression

/*/{Protheus.doc} JSPAITYP
Função da consulta padrão PAITYP para retornar tipos de produtos desejados.
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/8/2024
@param cTipos, character, tipos de produtos que estão filtrados
@return character, _cTypes
/*/
user function JSPAITYP( cTipos )
    
    local oDlgType as object
    local oMain    as object
    local oTipos   as object
    local aTipos   := {} as array
    local aColumns := {} as array
    local lMark    := .F. as logical
    local aTypes   := {} as array
    local cRet  := "" as character

    aTypes := StrTokArr( AllTrim(cTipos), "/" )

    DBSelectArea( 'SX5' )
	SX5->( DBSetOrder(1) )
		if DBSeek( FWxFilial( 'SX5' ) + '02'  )
		while ! SX5->( EOF() ) .and. SX5->X5_FILIAL == FWxFilial( 'SX5' ) .AND. SX5->X5_TABELA == '02'
			aAdd( aTipos, { aScan( aTypes, {|x| AllTrim(x) == AllTrim( SX5->X5_CHAVE ) } ) > 0,;
							AllTrim( SX5->X5_CHAVE ),;
							AllTrim( SX5->X5_DESCRI ) } )
			SX5->( DBSkip() )
		end
	endif

    aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( 'Tipo' )
	aColumns[len(aColumns)]:SetSize( 2 )
	aColumns[len(aColumns)]:SetType( 'C' )
	aColumns[len(aColumns)]:SetPicture( '@!' )
	aColumns[len(aColumns)]:SetData( {|| aTipos[oTipos:nAt][2] } )
	
	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( 'Descrição' )
	aColumns[len(aColumns)]:SetSize( 30 )
	aColumns[len(aColumns)]:SetType( 'C' )
	aColumns[len(aColumns)]:SetPicture( '@x' )
	aColumns[len(aColumns)]:SetData( {|| aTipos[oTipos:nAt][3] } )

    oDlgType := FWDialogModal():New()
    oDlgType:SetEscClose( .T. )
    oDlgType:SetTitle( "Tipos de Produtos" )
    oDlgType:SetSize( 310, 200 )
    oDlgType:SetSubTitle( "Selecione um ou mais tipos de produtos para análise..." )
    oDlgType:CreateDialog()
	oDlgType:AddCloseButton( {|| oDlgType:DeActivate()}, "Cancelar" )
	oDlgType:AddOkButton( {|| cRet := "",; 
                             aEval( aTipos, {|x| iif( x[1], cRet += iif( Empty(cRet),"","/" )+ x[2], Nil ) } ),;
                              oDlgType:DeActivate() }, "Ok" )

    oMain := oDlgType:GetPanelMain()

    oTipos := FWBrowse():New( oMain )
	oTipos:SetDataArray()
	oTipos:SetArray( aTipos )
	oTipos:DisableConfig()
	oTipos:DisableReport()
	oTipos:SetLineHeight(20)
	oTipos:AddMarkColumns( {|oTipos| if( aTipos[oTipos:nAt][1], 'LBOK','LBNO' ) },;
							{|oTipos| aTipos[oTipos:nAt][1] := !aTipos[oTipos:nAt][1] },;
							{|oTipos| lMark := !aTipos[1][1], aEval( aTipos, {|x| x[1] := lMark } ), oTipos:UpdateBrowse() } )
	oTipos:SetColumns( aColumns )
	oTipos:Activate()

    oDlgType:Activate()
    
    cRet := PADR( cRet, 200, ' ' )

return cRet

/*/{Protheus.doc} JSQRYINF
Função para montagem de query de análise do MRP para Painel de Compras
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/21/2024
@param aConf, array, vetor de configurações do painel
@param aFilters, array, vetor de filtros aplicados na pesquisa dos produtos a serem calculados
@return character, cQuery
/*/
user function JSQRYINF( aConf, aFilters )
    
    Local cTmp     := Upper( AllTrim( aFilters[1] ) )
	Local aTmp     := StrTokArr( cTmp, ' ' )
    local cQuery   := "" as character
    local cZB3     := AllTrim( SuperGetMv( 'MV_X_PNC02' ,,"" ) ) // Alias da tabela de índices de produtos
    local nX       := 0  as numeric
    local cLocais  := "" as character
    local cTypes   := "" as character
    local aAux     := {} as array
    local y        := 0  as numeric
    local dDtCalc  := CtoD( SubStr( SuperGetMv( 'MV_X_PNC12',,DtoC(date()) ), 01, 10 ) )
    local lLike    := At( '*', aFilters[5] ) > 0
    local cFilHist := cFilAnt
    local nFil     := 0 as numeric
    local cDB      := TCGetDB()

    default aConf := {}
    default aFilters := {}

    // Quando não vier parâmetros, retorna query vazia
    if !len( aConf ) > 0 .and. !len( aFilters ) > 0
        return cQuery
    endif

    aAux := StrTokArr(AllTrim(aFilters[2]),'/')
	// Cria expressão para a query SQL
	aEval( aAux, {|x| y++, cTypes += "'"+ x +"'" + iif( y < len( aAux ),',','' ) } )

    // Monta string referente aos armazens que serão utilizados para somatório dos saldos dos produtos
	aAux    := StrTokArr( AllTrim( aConf[16] ), '/' )
	cLocais := ""
	For nX := 1 to Len( aAux )
		cLocais += PADR( AllTrim( aAux[nX] ), TAMSX3('B2_LOCAL')[01], ' ') + iif( nX == Len(aAux),'',"','" )
	Next nX
    // Valida existência de conteúdo no parâmetro de armazéns
	if Empty( cLocais )
		Hlp( 'SEMLOCAIS',; 
             'Locais de estoque a serem considerados não definidos nos parâmetros do Painel de Compras!',;
             'Defina os armazéns para leitura de saldo em estoque e tente novamente!' )
        Return cQuery 
	EndIf
    
    cQuery := "SELECT TEMP.* FROM ( "+ CEOL
    for nFil := 1 to len( _aFil )
        cFilAnt := _aFil[nFil]
        
        cQuery += "SELECT '"+ cFilAnt +"' FILIAL, B1.B1_COD, B1.B1_DESC, B1.B1_UM, B1.B1_LM, B1.B1_QE, B1.B1_LE, "
        if ! Empty( aFilters[3] )
            cQuery += "COALESCE(" +iif( aConf[22] == '1', "B1.B1_PROC", "A5.A5_FORNECE") +",'"+ Space( TAMSX3('A5_FORNECE')[1] ) +"') AS A5_FORNECE, " + CEOL
            cQuery += "COALESCE("+ iif( aConf[22] == '1', "B1.B1_LOJPROC", "A5.A5_LOJA") +",'"+ Space( TAMSX3('A5_LOJA')[1] ) +"') AS A5_LOJA, " + CEOL
        else
            cQuery += "'"+ Space( TAMSX3('A5_FORNECE')[1] ) +"' A5_FORNECE, "+ CEOL
            cQuery += "'"+ Space( TAMSX3('A5_LOJA')[1] ) +"' AS A5_LOJA, " + CEOL
        endif
        cQuery += "B1.R_E_C_N_O_ RECSB1, " + CEOL

        cQuery += "COALESCE((SELECT SUM(B2.B2_QATU) FROM "+ RetSqlName( 'SB2' ) +" B2 " + CEOL
        cQuery += "WHERE B2.B2_FILIAL = '"+ FWxFilial( 'SB2' ) +"' " + CEOL
        cQuery += "  AND B2.B2_COD    = B1.B1_COD "+ CEOL
        cQuery += "  AND B2.B2_LOCAL  IN ( '"+ cLocais +"' ) " + CEOL
        cQuery += "  AND B2.D_E_L_E_T_ = ' ' ),0) ESTOQUE, " + CEOL

        cQuery += "COALESCE((SELECT SUM(B2.B2_RESERVA+B2.B2_QEMP) FROM "+ RetSqlName( 'SB2' ) +" B2 " + CEOL
        cQuery += "WHERE B2.B2_FILIAL = '"+ FWxFilial( 'SB2' ) +"' " + CEOL
        cQuery += "  AND B2.B2_COD    = B1.B1_COD "+ CEOL
        cQuery += "  AND B2.B2_LOCAL  IN ( '"+ cLocais +"' ) " + CEOL
        cQuery += "  AND B2.D_E_L_E_T_ = ' ' ),0) EMPENHO, " + CEOL
        
        // Identifica o lead-time do fornecedor
        if SA2->( FieldPos( 'A2_X_LTIME' ) ) > 0 .AND. ! Empty( aFilters[3] )
            cQuery += " A2.A2_X_LTIME, "+ CEOL
        else
            cQuery += " 0 A2_X_LTIME, "+ CEOL
        endif

        cQuery += "B1.B1_PE, " + CEOL
        cQuery += "B1.B1_EMIN, " + CEOL

        cQuery += "COALESCE((SELECT SUM(C7BLOQ.C7_QUANT - C7BLOQ.C7_QUJE) FROM "+ RetSqlName( "SC7" ) +" C7BLOQ " + CEOL
        cQuery += "WHERE C7BLOQ.C7_FILIAL = '"+ FWxFilial( 'SC7' ) +"' " + CEOL
        cQuery += "  AND C7BLOQ.C7_PRODUTO = B1.B1_COD " + CEOL
        cQuery += "  AND C7BLOQ.C7_RESIDUO <> 'S' " + CEOL
        cQuery += "  AND C7BLOQ.C7_ENCER   <> 'E' " + CEOL
        cQuery += "  AND C7BLOQ.C7_CONAPRO = 'B' " + CEOL						// identifica quantidade em pedido de compra com bloqueio
        cQuery += "  AND C7BLOQ.D_E_L_E_T_ = ' ' ),0) QTDBLOQ, "+ CEOL

        cQuery += "COALESCE((SELECT SUM(C7COMP.C7_QUANT - C7COMP.C7_QUJE) FROM "+ RetSqlName( "SC7" ) +" C7COMP " + CEOL
        cQuery += "WHERE C7COMP.C7_FILIAL = '"+ FWxFilial( 'SC7' ) +"' " + CEOL
        cQuery += "  AND C7COMP.C7_PRODUTO = B1.B1_COD " + CEOL
        cQuery += "  AND C7COMP.C7_RESIDUO <> 'S' " + CEOL
        cQuery += "  AND C7COMP.C7_ENCER   <> 'E' " + CEOL
        cQuery += "  AND C7COMP.C7_CONAPRO <> 'B' " + CEOL						// Pedidos em carteira sem bloqueio
        cQuery += "  AND C7COMP.D_E_L_E_T_ = ' ' ),0) QTDCOMP, " + CEOL

        cQuery += "COALESCE((SELECT MAX( C7COMP.C7_DATPRF ) FROM "+ RetSqlName( "SC7" ) +" C7COMP " + CEOL
        cQuery += "WHERE C7COMP.C7_FILIAL = '"+ FWxFilial( 'SC7' ) +"' " + CEOL
        cQuery += "  AND C7COMP.C7_PRODUTO = B1.B1_COD " + CEOL
        cQuery += "  AND C7COMP.C7_RESIDUO <> 'S' " + CEOL
        cQuery += "  AND C7COMP.C7_ENCER   <> 'E' " + CEOL
        cQuery += "  AND C7COMP.C7_CONAPRO <> 'B' " + CEOL						// Pedidos em carteira sem bloqueio
        cQuery += "  AND C7COMP.D_E_L_E_T_ = ' ' ), '"+ Space(8) +"' ) PRVENT, " + CEOL

        cQuery += "COALESCE("+ cZB3 +"_CONMED,0.0001) "+ cZB3 +"_CONMED, " + CEOL
        cQuery += "COALESCE("+ cZB3 +"_INDINC,0) "+ cZB3 +"_INDINC " + CEOL

        cQuery += "FROM "+ RetSqlName( 'SB1' ) +" B1 " + CEOL
        
        if ! Empty( aFilters[3] ) .and. ! aConf[22] == '1'     // 2=Prod.x Fornecedor ou 3=Hist.Compras
            
            // Se o fornecedor for informado, o join é exato, do contrário, apresenta os produtos sem fornecedor
            cQuery += iif( Empty(aFilters[3]) .and. aConf[22] == '1', "LEFT", "INNER" )
            cQuery += " JOIN "+ RetSqlName( 'SA5' ) +" A5 " + CEOL
            cQuery += " ON A5.A5_FILIAL = '"+ FWxFilial( 'SA5' ) +"' "+ CEOL
            cQuery += "AND A5.A5_PRODUTO = B1.B1_COD " + CEOL
            if ! Empty( aFilters[3] )      // Quando fornecedor é informado, faz join com a tabela de fornecedores para filtrar apenas os produtos do fornecedor informado
                cQuery += "AND A5.A5_FORNECE = '"+ aFilters[3] +"' " + CEOL
            endif
            cQuery += "AND A5.D_E_L_E_T_ = ' ' " + CEOL

        endif

        cQuery += "LEFT JOIN "+ RetSqlName( cZB3 ) +" "+ cZB3 +" " + CEOL
        cQuery += " ON "+ cZB3 +"."+ cZB3 +"_FILIAL = '"+ FWxFilial( cZB3 ) +"' " + CEOL
        cQuery += "AND "+ cZB3 +"."+ cZB3 +"_PROD   = B1.B1_COD " + CEOL
        cQuery += "AND "+ cZB3 +"."+ cZB3 +"_DATA   = '"+ DtoS( dDtCalc ) +"' " + CEOL
        cQuery += "AND "+ cZB3 +".D_E_L_E_T_ = ' ' " + CEOL
        
        if ! Empty( aFilters[3] )       // Faz join com tabela de fornecedores apenas quando codigo do fornecedor for informado
            // Se o fornecedor for informado, o join é exato, do contrário, apresenta os produtos sem fornecedor
            cQuery += iif( Empty( aFilters[3] ) .and. aConf[22] == '1', "LEFT", "INNER" )
            cQuery += " JOIN "+ RetSqlName( 'SA2' ) +" A2 "+ CEOL
            cQuery += " ON A2.A2_FILIAL = '"+ FWxFilial( 'SA2' ) +"' "+ CEOL
            if aConf[22] == '1'     // Fabricante
                cQuery += "AND A2.A2_COD     = B1.B1_PROC "+ CEOL
                cQuery += "AND A2.A2_LOJA    = B1.B1_LOJPROC "+ CEOL
            else
                cQuery += "AND A2.A2_COD     = A5.A5_FORNECE "+ CEOL
                cQuery += "AND A2.A2_LOJA    = A5.A5_LOJA "+ CEOL
            endif
            if ! Empty( aFilters[3] )      // Quando fornecedor é informado, faz join com a tabela de fornecedores para filtrar apenas o fornecedor informado
                cQuery += "AND A2.A2_COD = '"+ aFilters[3] +"' " + CEOL
            endif
            cQuery += "AND A2.A2_MSBLQL  <> '1' "+ CEOL
            cQuery += "AND A2.D_E_L_E_T_ = ' ' "+ CEOL
        endif

        cQuery += "WHERE B1.B1_FILIAL  = '"+ FWxFilial( 'SB1' ) +"' "+ CEOL 
        if ! Empty( aFilters[5] )
            cQuery += "  AND B1.B1_COD "+ iif( lLike, 'LIKE', '=' ) +" '"+ StrTran( iif( lLike, AllTrim(aFilters[5]), aFilters[5]),'*','%') +"' "+ CEOL                 // Filtra pelo código do produto
        endif
        cQuery += "  AND B1.B1_MSBLQL  <> '1' " + CEOL				// Faz leitura apenas dos itens ativos
        cQuery += "  AND B1.B1_TIPO IN ( "+ cTypes +" ) " + CEOL	// Desconsidera produtos acabado e serviços da análise do MRP
        cQuery += "  AND B1.B1_MRP     = 'S' " + CEOL				// Apenas os produtos que devem entrar no MRP
        
        if Len( aTmp ) > 0
            For nX := 1 to Len( aTmp )
                cQuery += "  AND B1.B1_DESC LIKE '%"+ aTmp[nX] +"%' " + CEOL
            Next nX 
        EndIf

        // Verifica se o filtro de fornecedor padrão foi informado na pesquisa de produtos
        if ! Empty( aFilters[4] )
            cQuery += "  AND B1."+ cFdGroup +" LIKE '"+ aFilters[4] +"%' " + CEOL
        endif

        // Tratativa de segurança para evitar filtro vazio quando usuário apertar botão de cancelar
        if aFilters[6]
            cQuery += "  AND 0=1 " + CEOL
        endif
        
        cQuery += "  AND B1.D_E_L_E_T_ = ' ' " + CEOL

        if nFil < len( _aFil )
            cQuery += "UNION ALL "+ CEOL
        endif
    next nFil

    if cDB $ "ORACLE"
        cQuery += ") TEMP " + CEOL
    else
        cQuery += ") AS TEMP " + CEOL
    endif
    cQuery += "ORDER BY TEMP.FILIAL, TEMP.B1_COD, TEMP.B1_DESC "	+ CEOL

    // Devolve posicionamento na filial de origem
    cFilAnt := cFilHist

    ConOut( cQuery )
return cQuery

/*/{Protheus.doc} hlp
Função facilitadora para utilização da função Help do Protheus
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 08/04/2024
@param cTitle, character, Titulo da janela
@param cFail, character, Informações sobre a falha
@param cHelp, character, Informações com texto de ajuda
/*/
static function hlp( cTitle, cFail, cHelp )
return Help( ,, cTitle,, cFail, 1, 0, NIL, NIL, NIL, NIL, NIL,{ cHelp } )

/*/{Protheus.doc} RuptWF
Retorna conteúdo do html base para montagem de e-mail de alerta de ruptura de estoque
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 1/2/2025
@return character, cWF
/*/
user function RuptWF()

    local cWF := "" as character

    cWF += '<!DOCTYPE html>' + CEOL
    cWF += '<html>' + CEOL
    cWF += CEOL
    cWF += '	<head>' + CEOL
    cWF += '		<meta http-equiv="Content-Language" content="en-us">' + CEOL
    cWF += '		<meta http-equiv="Content-Type" content="text/html; charset=windows-1252">' + CEOL
    cWF += '		<title>Workflow %EMPRESA%</title>' + CEOL
    cWF += '	</head>' + CEOL
    cWF += '	<body style="font-family: Arial, Tahoma, Calibri, sans-serif; font-size:14px; font-weight: normal; " >' + CEOL
    cWF += '		<p style="color: #ff8000; font-weight: bold">%TITULOMSG%</p>' + CEOL
    cWF += '		<p> ' + CEOL
    cWF += '			<b> A T E N Ç Ã O </b>, ' + CEOL
    cWF += '		</p>' + CEOL
    cWF += CEOL
    cWF += '		<p style="text-align: justify" >Com base na análise de materiais realizada em ' + CEOL
    cWF += '			<b> %DATAHORA%</b> ' + CEOL
    cWF += '			, foram identificados alguns itens com risco de ruptura de estoque. São eles: '+ CEOL
    cWF += '		</p>' + CEOL
    cWF += CEOL
    cWF += '		<table style="width:100%; border-collapse: collapse">' + CEOL
    cWF += '			<tr>' + CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; border-top-left-radius: 5px;" align="center"> Produto </td>' + CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; " align="center"> Descrição </td>' + CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; " align="center"> Cons. Medio(D) </td>' + CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; " align="center"> Tp Dia </td>' + CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; " align="center"> Dur. Estoque(D) </td>' + CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; " align="center"> Nec. Compra </td>' + CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; " align="center"> Estoq. Atual </td>'+ CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; " align="center"> Empenho (Reserva) </td>' + CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; " align="center"> Qtde Comprada </td>' + CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; " align="center"> Prev. Entrega </td>' + CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; " align="center"> T. Entrega (Dias) </td>'+ CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; border-top-right-radius: 5px;" align="center"> Detalhamento </td>' + CEOL
    cWF += '			</tr>' + CEOL
    cWF += '		<tr>' + CEOL
    cWF += '				<td style="border-left: 1px solid rgb(204, 109, 20); background-color: %it.clproduto%" align="left">' + CEOL
    cWF += '					<font size="2">%IT.PRODUTO% </font></td>' + CEOL
    cWF += '				<td style="border-collapse: collapse; border-spacing: 5px; padding: 10px; background-color: %it.cldescricao%" align="left">' + CEOL
    cWF += '					<font size="2">%IT.DESCRICAO% </font></td>' + CEOL
    cWF += '				<td style="border-collapse: collapse; border-spacing: 5px; padding: 10px; background-color: %it.clconsumo%" align="right">' + CEOL
    cWF += '					<font size="2">%IT.CONSUMO% </font></td>' + CEOL
    cWF += '				<td style="border-collapse: collapse; border-spacing: 5px; padding: 10px; background-color: %it.cltipodia%" align="center">' + CEOL
    cWF += '					<font size="2">%IT.TIPODIA% </font></td>' + CEOL
    cWF += '				<td style="border-collapse: collapse; border-spacing: 5px; padding: 10px; background-color: %it.clduracao%" align="center">' + CEOL
    cWF += '					<font size="2">%IT.DURACAO% </font></td>' + CEOL
    cWF += '				<td style="border-collapse: collapse; border-spacing: 5px; padding: 10px; background-color: %it.clnecessidade%" align="right">' + CEOL
    cWF += '					<font size="2">%IT.NECESSIDADE% </font></td>' + CEOL
    cWF += '				<td style="border-collapse: collapse; border-spacing: 5px; padding: 10px; background-color: %it.clestoque%" align="right">' + CEOL
    cWF += '					<font size="2">%IT.ESTOQUE% </font></td>' + CEOL
    cWF += '				<td style="border-collapse: collapse; border-spacing: 5px; padding: 10px; background-color: %it.clempenho%" align="right">' + CEOL
    cWF += '					<font size="2">%IT.EMPENHO% </font></td>' + CEOL
    cWF += '				<td style="border-collapse: collapse; border-spacing: 5px; padding: 10px; background-color: %it.clcomprado%" align="right">' + CEOL
    cWF += '					<font size="2">%IT.COMPRADO% </font></td>' + CEOL
    cWF += '				<td style="border-collapse: collapse; border-spacing: 5px; padding: 10px; background-color: %it.clprevisao%" align="center">' + CEOL
    cWF += '					<font size="2">%IT.PREVISAO% </font></td>' + CEOL
    cWF += '				<td style="border-collapse: collapse; border-spacing: 5px; padding: 10px; background-color: %it.clldtime%" align="center">' + CEOL
    cWF += '					<font size="2">%IT.LDTIME% </font></td>' + CEOL
    cWF += '				<td style="border-right: 1px solid rgb(204, 109, 20);  background-color: %it.clmensagem%" align="left">' + CEOL
    cWF += '					<font size="2">%IT.MENSAGEM% </font></td>' + CEOL
    cWF += '			</tr>' + CEOL
    cWF += '			<tr>' + CEOL
    cWF += '				 <td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); border-bottom-left-radius: 5px; " ></td>' + CEOL
    cWF += '				 <td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color: white"></td>' + CEOL
    cWF += '				 <td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color: white"></td>' + CEOL
    cWF += '				 <td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color: white"></td>' + CEOL
    cWF += '				 <td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color: white"></td>' + CEOL
    cWF += '				 <td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color: white"></td>' + CEOL
    cWF += '				 <td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color: white"></td>' + CEOL
    cWF += '				 <td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color: white"></td>' + CEOL
    cWF += '				 <td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color: white"></td>' + CEOL
    cWF += '				 <td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color: white"></td>' + CEOL
    cWF += '				 <td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color: white"></td>' + CEOL
    cWF += '				 <td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); border-bottom-right-radius: 5px; color: white" align="right" ></td>' + CEOL
    cWF += '			</tr>' + CEOL
    cWF += '		</table>' + CEOL
    cWF += '		</br>' + CEOL
    cWF += CEOL
    cWF += '		<span style="font-family:  Tahoma, Calibri, sans-serif; color:#FF8000;"><font size="1">' + CEOL
    cWF += '			</br>' + CEOL
    cWF += '			<hr noshade color="#FF8000" size="0.5px">' + CEOL
    cWF += '				<p align="left">' + CEOL
    cWF += '					<b>Esta mensagem foi enviada de maneira automática pelos nossos sitemas, portante, não há necessidade de resposta.</b>' + CEOL
    cWF += '				</p>' + CEOL
    cWF += ' 			</hr>' + CEOL
    cWF += CEOL
    cWF += '		</span>' + CEOL
    cWF += '	</body>' + CEOL
    cWF += '</html>' + CEOL

return cWF
