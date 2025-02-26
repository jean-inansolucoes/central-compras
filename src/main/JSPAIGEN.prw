#include 'totvs.ch'
#include 'topconn.ch'
#include 'fwmvcdef.ch'

#define CEOL Chr(13)+Chr(10)

/*/{Protheus.doc} JSGETVER
Retorna a vers�o do aplicativo.
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
Fun��o com detalhamento das vers�es do aplicativo.
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 30/08/2024
@return array, aDetVer
/*/
user function JSDETVER()

    local aDetVer := {} as array
    aAdd( aDetVer, { '01','0001','18/09/2024', 'Vers�o inicial do Painel de Compras' } )
    aAdd( aDetVer, { '02','0002','20/09/2024', 'Permite informar valor de frete ao pedido de compra e tamb�m informar um c�digo de transportadora relacionado ao processo.' } )
    aAdd( aDetVer, { '02','0003','20/09/2024', 'Permitir informar frete em percentual' } )
    aAdd( aDetVer, { '02','0004','21/09/2024', 'Permitir editar al�quota de IPI diretamente no carrinho' } )
    aAdd( aDetVer, { '02','0005','03/10/2024', 'Liberar edi��o de campos para simula��o de pre�o na tela de consulta de notas' } )
    aAdd( aDetVer, { '03','0006','06/10/2024', 'Permitir definir �ndice de lucro desej�vel por produto' } )
    aAdd( aDetVer, { '04','0001','16/10/2024', 'Controle de execu��o do JOB de rec�lculo dos �ndices individuais dos produtos' } )
    aAdd( aDetVer, { '04','0002','17/10/2024', 'Painel de Compras Multi-Filial' } )
    aAdd( aDetVer, { '05','0001','12/11/2024', 'Adapta��o para release 12.1.2410 usando smartclient webapp' } )
    aAdd( aDetVer, { '05','0002','13/11/2024', 'Novo formato de filtros, remodelagem da engine de c�lculos e substitui��o de componentes obsoletos' } )
    aAdd( aDetVer, { '05','0003','13/11/2024', 'Workflow autom�tico para fornecedor' } )
    aAdd( aDetVer, { '06','0001','21/11/2024', 'Adi��o de rotina para rec�lculo manual dos �ndices dos produtos, adequa��es de consultas do rec�lculo por JOB' } )
    aAdd( aDetVer, { '07','0001','02/01/2025', 'Novas melhorias no motor de c�lculo de necessidade de compra, workflow de ruptura, nova feature de forma��o de pre�os' } )
    aAdd( aDetVer, { '07','0002','03/01/2025', 'Ajustar m�scara do campo consumo m�dio e ajustado query de consulta de pedidos em carteira' } )
    aAdd( aDetVer, { '07','0003','13/01/2025', 'Ajuste refresh da tela de forma��o de pre�os, acesso a forma��o de pre�os pelo documento de entrada, '+;
                                                'alinhamento de labels na tela de forma��o de pre�os.' } )
    aAdd( aDetVer, { '08','0001','14/01/2025', 'Inclu�do tratativa a par�metro para indicar se o usu�rio tem acesso para gravar novo pre�o de venda, '+;
                                                'Ajuste na chamada do bot�o Tornar Padr�o para gravar o conte�do e fazer refresh corretamente.' } )
    aAdd( aDetVer, { '08','0002','15/01/2025', 'Ajuste do filtro por grupo de produto, implementa��o de tela para detalhamento do consumo do produto.' } )
    aAdd( aDetVer, { '09','0001','16/01/2025', 'Rotina para forma��o de pre�os separada do Documento de Entrada.' } )
    aAdd( aDetVer, { '09','0002','20/01/2025', 'Edi��o de browse para permitir ocultar campos desnecess�rios do browse conforme necessidade do usu�rio.' } )
    aAdd( aDetVer, { '09','0003','20/01/2025', 'Valida resolu��o de tela utilizada pelo equipamento.' } )
    aAdd( aDetVer, { '09','0004','21/01/2025', 'Melhorias gr�ficas na tela de forma��o de pre�os para evitar distor��o de componentes.' } )
    aAdd( aDetVer, { '09','0005','21/01/2025', 'Ajuste na tela de visualiza��o de sa�das para evitar falha no c�lculo de m�dia quando o produto n�o cont�m movimenta��es no per�odo analisado.' } )
    aAdd( aDetVer, { '10','0001','21/01/2025', 'Adicionado par�metro nas configura��es indicar se a empresa vai considerar o empenho para obter o saldo atual de estoque.' } )
    aAdd( aDetVer, { '11','0001','23/01/2025', 'Implementado novo �ndice na tabela SF1 para agilizar abertura da tela de forma��o de pre�os' } )
    aAdd( aDetVer, { '11','0002','24/01/2025', 'Realizado ajuste para permitir que usu�rio informe o centro de custos durante fechamento do carrinho de compra' } )
    aAdd( aDetVer, { '11','0003','06/02/2025', 'Implementado impress�o de relat�rio do browse de produtos' } )
    aAdd( aDetVer, { '11','0003','08/02/2025', 'Inclu�do bot�o para desconsiderar produto do MRP' } )
    aAdd( aDetVer, { '12','0001','13/02/2025', 'Remover campos de empresa e filial da tabela de par�metros gerais, trazer ultimo diret�rio utilizado na rotina de transfer�ncia '+;
                                                'de arquivos do server para o cliente e do cliente para o server.' } )
    aAdd( aDetVer, { '12','0002','13/02/2025', 'Implementado fun��o para obter v�nculo entre produto x fornecedor atrav�s de arquivo .csv' } )
    aAdd( aDetVer, { '12','0003','14/02/2025', 'Implementa��o de conex�o com banco web para obter dados de configura��es por meio de API, '+;
                                                'remo��o de fun��o de copia para servidor e c�pia para diret�rio local' } )
    aAdd( aDetVer, { '12','0004','18/02/2025', 'Adicionado funcionalidade para permitir eliminar res�duo de um determinado produto quando o fornecedor n�o vai mais atend�-lo.' } )
    aAdd( aDetVer, { '12','0005','20/02/2025', 'Corre��o de bug ao excluir o �ltimo pedido listado na tela de pedidos em aberto para o produto' } )
    aAdd( aDetVer, { '12','0006','20/02/2025', 'Ajuste de bug no browse de fornecedores ao alterar leadtime informado' } )
    aAdd( aDetVer, { '12','0007','20/02/2025', 'Adicionado propor��o de 60% para o tamanho das colunas do browse de produtos em rela��o ao tamanho f�sico do campo no dicion�rio de dados' } )
    aAdd( aDetVer, { '12','0008','20/02/2025', 'Ajuste para o sistema trazer o lead-time default do fornecedor quando n�o houver leadtime definido para o produto' } )
    aAdd( aDetVer, { '12','0009','21/02/2025', 'Ajuste de espa�amento no c�digo do fornecedor na fun��o de importa��o da rela��o de produto versus fornecedor' } )
    aAdd( aDetVer, { '12','0010','22/02/2025', 'Altera��o para que, quando o produto for colocado no carrinho por meio do alt+x, a linha do grid de produtos seja atualizada' } )
    aAdd( aDetVer, { '12','0011','22/02/2025', 'Permitir alterar a quantidade diretamente no campo do browse do produto quando n�o for utilizado compra multi-filial' } )
    aAdd( aDetVer, { '13','0001','21/02/2025', 'Implementa��o do conceito de perfis de c�lculo' } )
    aAdd( aDetVer, { '13','0002','25/02/2025', 'V�nculo de perfil de c�lculo com o produto para rec�lculos via JOB' } )
    aAdd( aDetVer, { '13','0003','25/02/2025', 'V�nculo autom�tico de produto versus fornecedor ao informar fornecedor e loja na linha do produto' } )
    aAdd( aDetVer, { '13','0004','26/02/2025', 'Ajuste para corrigir error-log durante rec�lculo de �ndices por produto atrav�s de JOB' } )

return aDetVer

/*/{Protheus.doc} JSFILIAL
Fun��o para retornar express�o de filial conforme configura��es de cada tabela.
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

        // Repassa todas as filiais selecionadas pelo usu�rio e monta um subvetor com as filiais j� compatibilizadas com o tamanho utilizado pela tabela
        for nFil := 1 to len(aFil)
            cAux := SubStr( aFil[nFil], 01, nSize )
            if aScan( aUsed, {|x| AllTrim(x) == AllTrim(cAux) } ) == 0
                aAdd( aUsed, PADR(cAux, TAMSX3( cField )[1], ' ' ) )
            endif
        next nFil
       
        // Monta express�o IN para uso na query
        if len( aUsed ) == 0
            cFilExp := " = '"+ Replicate( 'Z', TAMSX3( cField )[1] ) +"' "
        elseif len( aUsed ) == 1        // Se foi selecionado apenas uma filial, muda a express�o da query para dar mais performance
            cFilExp := " = '"+ aUsed[1] +"' "
        else
            cFilExp := " IN ( "
            aEval( aUsed, {|x| nAux++, cFilExp += "'"+ x +"'" + iif( nAux < len( aUsed ), ',', '' ) } )        
            cFilExp += " ) "
        endif

    elseif nSize == 0 .and. len( aFil ) > 0                 // Se existir filial selecionada e o tamanho do campo for zero
        cFilExp := " = '"+ FWxFilial( cAlias ) +"' "

    elseif nSize == 0 .and. len( aFil ) == 0                // Erra o filtro propositalmente para fazer com que o banco n�o retorne nenhum registro.
        cFilExp := " <> '"+ FWxFilial( cAlias ) +"'  "  
    endif

return cFilExp

/*/{Protheus.doc} JSPAITYP
Fun��o da consulta padr�o PAITYP para retornar tipos de produtos desejados.
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/8/2024
@param cTipos, character, tipos de produtos que est�o filtrados
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
	aColumns[len(aColumns)]:SetTitle( 'Descri��o' )
	aColumns[len(aColumns)]:SetSize( 30 )
	aColumns[len(aColumns)]:SetType( 'C' )
	aColumns[len(aColumns)]:SetPicture( '@x' )
	aColumns[len(aColumns)]:SetData( {|| aTipos[oTipos:nAt][3] } )

    oDlgType := FWDialogModal():New()
    oDlgType:SetEscClose( .T. )
    oDlgType:SetTitle( "Tipos de Produtos" )
    oDlgType:SetSize( 310, 200 )
    oDlgType:SetSubTitle( "Selecione um ou mais tipos de produtos para an�lise..." )
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
Fun��o para montagem de query de an�lise do MRP para Painel de Compras
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/21/2024
@param aConf, array, vetor de configura��es do painel
@param aFilters, array, vetor de filtros aplicados na pesquisa dos produtos a serem calculados
@return character, cQuery
/*/
user function JSQRYINF( aConf, aFilters )
    
    Local cTmp     := Upper( AllTrim( aFilters[1] ) )
	Local aTmp     := StrTokArr( cTmp, ' ' )
    local cQuery   := "" as character
    local cZB3     := AllTrim( SuperGetMv( 'MV_X_PNC02' ,,"" ) ) // Alias da tabela de �ndices de produtos
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
    local cFdGroup := AllTrim( SuperGetMv( 'MV_X_PNC13',,'B1_GRUPO' ) )

    default aConf := {}
    default aFilters := {}

    // Quando n�o vier par�metros, retorna query vazia
    if !len( aConf ) > 0 .and. !len( aFilters ) > 0
        return cQuery
    endif

    aAux := StrTokArr(AllTrim(aFilters[2]),'/')
	// Cria express�o para a query SQL
	aEval( aAux, {|x| y++, cTypes += "'"+ x +"'" + iif( y < len( aAux ),',','' ) } )

    // Monta string referente aos armazens que ser�o utilizados para somat�rio dos saldos dos produtos
	aAux    := StrTokArr( AllTrim( aConf[16] ), '/' )
	cLocais := ""
	For nX := 1 to Len( aAux )
		cLocais += PADR( AllTrim( aAux[nX] ), TAMSX3('B2_LOCAL')[01], ' ') + iif( nX == Len(aAux),'',"','" )
	Next nX
    // Valida exist�ncia de conte�do no par�metro de armaz�ns
	if Empty( cLocais )
		Hlp( 'SEMLOCAIS',; 
             'Locais de estoque a serem considerados n�o definidos nos par�metros do Painel de Compras!',;
             'Defina os armaz�ns para leitura de saldo em estoque e tente novamente!' )
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
            
            // Se o fornecedor for informado, o join � exato, do contr�rio, apresenta os produtos sem fornecedor
            cQuery += iif( Empty(aFilters[3]) .and. aConf[22] == '1', "LEFT", "INNER" )
            cQuery += " JOIN "+ RetSqlName( 'SA5' ) +" A5 " + CEOL
            cQuery += " ON A5.A5_FILIAL = '"+ FWxFilial( 'SA5' ) +"' "+ CEOL
            cQuery += "AND A5.A5_PRODUTO = B1.B1_COD " + CEOL
            if ! Empty( aFilters[3] )      // Quando fornecedor � informado, faz join com a tabela de fornecedores para filtrar apenas os produtos do fornecedor informado
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
            // Se o fornecedor for informado, o join � exato, do contr�rio, apresenta os produtos sem fornecedor
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
            if ! Empty( aFilters[3] )      // Quando fornecedor � informado, faz join com a tabela de fornecedores para filtrar apenas o fornecedor informado
                cQuery += "AND A2.A2_COD = '"+ aFilters[3] +"' " + CEOL
            endif
            cQuery += "AND A2.A2_MSBLQL  <> '1' "+ CEOL
            cQuery += "AND A2.D_E_L_E_T_ = ' ' "+ CEOL
        endif

        cQuery += "WHERE B1.B1_FILIAL  = '"+ FWxFilial( 'SB1' ) +"' "+ CEOL 
        if ! Empty( aFilters[5] )
            cQuery += "  AND B1.B1_COD "+ iif( lLike, 'LIKE', '=' ) +" '"+ StrTran( iif( lLike, AllTrim(aFilters[5]), aFilters[5]),'*','%') +"' "+ CEOL                 // Filtra pelo c�digo do produto
        endif
        cQuery += "  AND B1.B1_MSBLQL  <> '1' " + CEOL				// Faz leitura apenas dos itens ativos
        cQuery += "  AND B1.B1_TIPO IN ( "+ cTypes +" ) " + CEOL	// Desconsidera produtos acabado e servi�os da an�lise do MRP
        cQuery += "  AND B1.B1_MRP     = 'S' " + CEOL				// Apenas os produtos que devem entrar no MRP
        
        if Len( aTmp ) > 0
            For nX := 1 to Len( aTmp )
                cQuery += "  AND B1.B1_DESC LIKE '%"+ aTmp[nX] +"%' " + CEOL
            Next nX 
        EndIf

        // Verifica se o filtro de fornecedor padr�o foi informado na pesquisa de produtos
        if ! Empty( aFilters[4] )
            cQuery += "  AND B1."+ cFdGroup +" LIKE '"+ aFilters[4] +"%' " + CEOL
        endif

        // Tratativa de seguran�a para evitar filtro vazio quando usu�rio apertar bot�o de cancelar
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
Fun��o facilitadora para utiliza��o da fun��o Help do Protheus
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 08/04/2024
@param cTitle, character, Titulo da janela
@param cFail, character, Informa��es sobre a falha
@param cHelp, character, Informa��es com texto de ajuda
/*/
static function hlp( cTitle, cFail, cHelp )
return Help( ,, cTitle,, cFail, 1, 0, NIL, NIL, NIL, NIL, NIL,{ cHelp } )

/*/{Protheus.doc} RuptWF
Retorna conte�do do html base para montagem de e-mail de alerta de ruptura de estoque
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
    cWF += '			<b> A T E N � � O </b>, ' + CEOL
    cWF += '		</p>' + CEOL
    cWF += CEOL
    cWF += '		<p style="text-align: justify" >Com base na an�lise de materiais realizada em ' + CEOL
    cWF += '			<b> %DATAHORA%</b> ' + CEOL
    cWF += '			, foram identificados alguns itens com risco de ruptura de estoque. S�o eles: '+ CEOL
    cWF += '		</p>' + CEOL
    cWF += CEOL
    cWF += '		<table style="width:100%; border-collapse: collapse">' + CEOL
    cWF += '			<tr>' + CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; border-top-left-radius: 5px;" align="center"> Produto </td>' + CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; " align="center"> Descri��o </td>' + CEOL
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
    cWF += '					<b>Esta mensagem foi enviada de maneira autom�tica pelos nossos sitemas, portante, n�o h� necessidade de resposta.</b>' + CEOL
    cWF += '				</p>' + CEOL
    cWF += ' 			</hr>' + CEOL
    cWF += CEOL
    cWF += '		</span>' + CEOL
    cWF += '	</body>' + CEOL
    cWF += '</html>' + CEOL

return cWF

/*/{Protheus.doc} JSCLISM0
Retorna vetor com cliente + filial dos cadastros que possuem liga��o com filiais da empresa corrente cadastradas no sistema
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 1/22/2025
@return array, aCliSM0
/*/
User Function JSCLISM0()
return getCliSM0()

/*/{Protheus.doc} JSQRYSAI
Query para leitura das saidas de produtos que tem rela��o com venda de produtos do grupo econ�mico
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 1/15/2025
@param cProduto, character, ID do produto
@param dDe, date, in�dio da faixa de pesquisa de vendas pela data de emissao
@param dAte, date, fim da faixa de pesquisa de vendas pela data de emissao
@param _aFil, array, vetor de filiais selecionadas pelo usu�rio
@return character, cQuery
/*/
user function JSQRYSAI( cProduto, dDe, dAte, _aFil )
    
    local cQuery   := "" as character
    local aCliSM0  := {} as array
    local cCliSM0  := "" as character
    local nAux     := 0  as numeric
    local cFilHist := cFilAnt
    local nFil     := 0 as numeric
    local cDB      := TCGETDB()

    default _aFil    := {}
    default cProduto := ""

    aCliSM0 := getCliSM0()
    if len( aCliSM0 ) > 0
        aEval( aCliSM0, {|x| nAux++, cCliSM0 += "'"+ x[1] + x[2] +"'" + iif( nAux < len(aCliSM0), ',', '' ) } )
    endif

    for nFil := 1 to len( _aFil )
        cFilAnt := _aFil[nFil]

        cQuery := "SELECT " + CEOL
        cQuery += "  'V' AS TIPO, D2.D2_FILIAL, D2.D2_COD, D2.D2_DOC, D2.D2_SERIE, D2.D2_EMISSAO, D2.D2_CLIENTE, D2.D2_LOJA, " + CEOL
        cQuery += "  A1.A1_NOME, D2.D2_LOCAL, D2.D2_QUANT " + CEOL
        cQuery += "FROM "+ RetSqlName( 'SD2' ) +" D2 " + CEOL
                    
        cQuery += "INNER JOIN "+ RetSqlName( 'SF4' ) +" F4 " + CEOL
        cQuery += " ON F4.F4_FILIAL  = '"+ FWxFilial( 'SF4' ) +"' "+ CEOL
        cQuery += "AND F4.F4_CODIGO  = D2.D2_TES "+ CEOL
        cQuery += "AND F4.F4_ESTOQUE = 'S' "+ CEOL
        cQuery += "AND F4.D_E_L_E_T_ = ' ' "+ CEOL

        cQuery += "INNER JOIN "+ RetSqlName( 'SA1' ) +" A1 " + CEOL
        cQuery += "  ON A1.A1_FILIAL  = '"+ FWxFilial( 'SA1' ) +"' "+ CEOL
        cQuery += " AND A1.A1_COD     = D2.D2_CLIENTE "+ CEOL
        cQuery += " AND A1.A1_LOJA    = D2.D2_LOJA "+ CEOL
        cQuery += " AND A1.D_E_L_E_T_ = ' ' "+ CEOL

        cQuery += "WHERE D2.D2_FILIAL  = '"+ FWxFilial( 'SD2' ) +"' "+ CEOL
        cQuery += "  AND D2.D2_TIPO    = 'N' "+ CEOL
        cQuery += "  AND D2.D2_EMISSAO BETWEEN '"+ DtoS( dDe ) +"' AND '"+ DtoS( dAte ) +"' " + CEOL
        if ! Empty( cCliSM0 )       // Se houver clientes cadastrados que est�o dentro do mesmo grupo econ�mico
            cQuery += "  AND CONCAT( D2.D2_CLIENTE, D2.D2_LOJA ) NOT IN ( "+ cCliSM0 +" ) " + CEOL
        endif
        if ! Empty( cProduto )
            cQuery += "  AND D2.D2_COD     = '"+ cProduto +"' " + CEOL
        endif
        cQuery += "  AND D2.D_E_L_E_T_ = ' ' " + CEOL

        cQuery += "UNION ALL "+ CEOL

        cQuery += "SELECT " + CEOL
        cQuery += "  'P' AS TIPO, D3.D3_FILIAL D2_FILIAL, D3.D3_COD D2_COD, C2.C2_NUM D2_DOC, '"+ Space( TAMSX3('D2_SERIE')[1] ) +"' AS D2_SERIE, D3.D3_EMISSAO D2_EMISSAO, "
        cQuery += "  COALESCE( C6.C6_CLI,'"+ Space( TamSX3('D2_CLIENTE')[1] ) +"' ) D2_CLIENTE, "
        cQuery += "  COALESCE( C6.C6_LOJA, '"+ Space( TamSX3('D2_LOJA')[1] ) +"' ) D2_LOJA, "
        cQuery += "  COALESCE( A1.A1_NOME, '"+ Space( TamSX3('A1_NOME')[1] ) +"' ) A1_NOME, "
        cQuery += "  D3.D3_LOCAL AS D2_LOCAL, D3.D3_QUANT AS D2_QUANT " + CEOL
        cQuery += "FROM "+ RetSqlName( 'SD3' ) +" D3 " + CEOL

        cQuery += "INNER JOIN "+ RetSqlname('SC2'  ) +" C2 " + CEOL
        cQuery += " ON C2.C2_FILIAL = '"+ FWxFilial( 'SC2' ) +"' " + CEOL
        if cDB == 'ORACLE'
            cQuery += "AND C2.C2_NUM || C2.C2_ITEM || C2.C2_SEQUEN = D3.D3_OP " + CEOL
        else
            cQuery += "AND CONCAT( CONCAT( C2.C2_NUM, C2.C2_ITEM ), C2.C2_SEQUEN ) = D3.D3_OP " + CEOL
        endif
        cQuery += "AND C2.D_E_L_E_T_ = ' ' " + CEOL

        cQuery += "LEFT JOIN "+ RetSqlName( 'SC6' ) +" C6 " + CEOL
        cQuery += " ON C6.C6_FILIAL  = '"+ FWxFilial( 'SC6' ) +"' " + CEOL
        cQuery += "AND C6.C6_NUM     = C2.C2_PEDIDO " + CEOL
        cQuery += "AND C6.C6_ITEM    = C2.C2_ITEMPV " + CEOL
        cQuery += "AND C6.D_E_L_E_T_ = ' ' " + CEOL

        cQuery += "LEFT JOIN "+ RetSqlName( 'SA1' ) +" A1 " + CEOL
        cQuery += " ON A1.A1_FILIAL  = '"+ FWxFilial( 'SA1' ) +"' "+ CEOL
        cQuery += "AND A1.A1_COD     = C6.C6_CLI "+ CEOL
        cQuery += "AND A1.A1_LOJA    = C6.C6_LOJA "+ CEOL
        cQuery += "AND A1.D_E_L_E_T_ = ' ' "+ CEOL

        cQuery += "WHERE D3.D3_FILIAL = '"+ FWxFilial( 'SD3' ) +"' "+ CEOL
        if ! Empty( cProduto )
            cQuery += "  AND D3.D3_COD    = '"+ cProduto +"' " + CEOL
        endif
        cQuery += "  AND D3.D3_EMISSAO BETWEEN '"+ DtoS( dDe ) +"' AND '"+ DtoS( dAte ) +"' " + CEOL
        cQuery += "  AND D3.D3_TM     >= '500' " + CEOL
        cQuery += "  AND D3.D3_OP     <> '"+ Space( TAMSX3('D3_OP')[1] ) +"' " + CEOL
        cQuery += "  AND D3.D3_ESTORNO = ' ' " + CEOL
        cQuery += "  AND D3.D_E_L_E_T_ = ' ' " + CEOL

        if nFil < len( _aFil )
            cQuery += "UNION ALL "+ CEOL
        endif
        
    next nFil

    // Devolve a filial que o usu�rio estava conectado quando iniciou a fun��o
    cFilAnt := cFilHist

return cQuery

/*/{Protheus.doc} getCliSM0
Obt�m os clientes do cadastro que tem rela��o com as empresas do grupo econ�mico
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 1/15/2025
@return array, aCliSM0
/*/
static function getCliSM0()

    local aCliSM0 := {} as array
    local cQuery  := "" as character
    local cAlias  := "" as character

    cQuery := "SELECT DISTINCT A1.A1_COD, A1.A1_LOJA FROM SYS_COMPANY M0 "
    cQuery += "INNER JOIN "+ RetSqlName( 'SA1' ) +" A1 "
    cQuery += " ON A1.A1_FILIAL = '"+ FWxFilial( 'SA1' ) +"' " 
    cQuery += "AND A1.A1_CGC    = M0.M0_CGC "
    cQuery += "AND A1.D_E_L_E_T_ = ' ' "
    cQuery += "WHERE M0.M0_CGC LIKE '"+ SubStr( SM0->M0_CGC, 1, 8 ) +"%' "
    cQuery += "  AND M0.D_E_L_E_T_ = ' ' "

    cAlias := MPSysOpenQuery( cQuery )
    if ! ( cAlias )->( EOF() )
        while ! ( cAlias )->( EOF() )
            aAdd( aCliSM0, { ( cAlias )->A1_COD, ( cAlias )->A1_LOJA } )
            ( cAlias )->( DBSkip() )
        end
    endif
    ( cAlias )->( DBCloseArea() )

return aCliSM0

/*/{Protheus.doc} JSGETDB
Retorna o link para o banco de dados configurado nos par�metros do cliente
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 22/08/2023
@return character, cSupabase
/*/
User Function JSGETDB()
return "https://mqdxpnvezumlldeusbmh.supabase.co"

/*/{Protheus.doc} JSGETKEY
Fun��o para devolver ao requisitante a API key de comunica��o com o banco
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 22/08/2023
@return character, cApiKey
/*/
User Function JSGETKEY()
return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1xZHhwbnZlenVtbGxkZXVzYm1oIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk1NjQxMjIsImV4cCI6MjA1NTE0MDEyMn0._bjK4yUSX6jlkWYKdwg4ou0VUBjJpIHkD5jZb4o3lqY"
