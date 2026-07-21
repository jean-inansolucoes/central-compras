#include 'totvs.ch'
#include 'topconn.ch'

#define LG_CRITICO "BR_VERMELHO"				// Legenda de itens críticos
#define LG_ALTO    "BR_LARANJA"					// Legenda de itens de alto giro
#define LG_MEDIO   "BR_AMARELO"					// Legenda para itens de giro mediano
#define LG_BAIXO   "BR_CINZA"					// Legenda para itens de baixo giro
#define LG_SEMGIRO "BR_BRANCO"					// Legenda para itens considerados sem giro

/*/{Protheus.doc} JSORDPRD
Função para ixibir ao usuário os produtos cuja OP devem ser geradas
@type function
@version 12.1.2510
@author Jean Carlos Pandolfo Saggin
@since 11/05/2026 
@return logical, lChange, indicando se houve alguma alteração (gerado OP) para que a tela principal seja atualizada
/*/
user function JSORDPRD()
    
    local lChange  := .F. as logical
    local oDlg            as object
    local oMain           as object
	local oOPs            as object
    local bValid   := {|| .T. }
    local bOk      := {|| lChange := .T., oDlg:End()}
    local bCancel  := {|| oDlg:End() }
    local bInit    := {|| EnchoiceBar( oDlg, bOk, bCancel, ,aButtons )}
    local aColumns := U_JSHDRPA()
	local aButtons := {} as array
	local bBkpF4   as codeblock
	local bBkpF5   as codeblock
	local bBkpF11  as codeblock
	local bBkpF12  as codeblock
	local bBkpAlX  as codeblock

	// Botões a serem exibidos na tela de exibição das PAs
	aAdd( aButtons, { , 'Matéria-Prima (Tudo)', {|| iif( showMP() .and. MsgYesNo( 'Gostaria de Gerar as OPs automaticamente?', 'A T E N Ç Ã O !' ),; 
													Processa( {|| lChange := createOPs( oOPs ) }, 'Aguarde!', 'Gerando OPs...' ), Nil ) }, 'Clique para exibir as MPs ligadas à PA',,.T. /* lShowBar */, .T. /* lShowConfig */ } )
	aAdd( aButtons, { , 'MPs c/ Nec. Compra', {|| iif( showMP(.F. /* lAll */) .and. MsgYesNo( 'Gostaria de Gerar as OPs automaticamente?', 'A T E N Ç Ã O !' ),; 
													Processa( {|| lChange := createOPs( oOPs ) }, 'Aguarde!', 'Gerando OPs...' ), Nil ) }, 'Exibe apenas as MPs ligadas às PAs marcadas e que tenham necessidade de compra',,.T. /* lShowBar */, .T. /* lShowConfig */ } )
	aAdd( aButtons, { , 'Remover da Lista', {|| iif( removePA(), oOPs:UpdateBrowse(), Nil ) },; 
		'Remove o PA da lista para não gerar Ordem de Produção',,.T. /* lShowBar */, .T. /* lShowConfig */ } )

	// Limpa conteúdo das teclas de atalho para evitar conflitos com a rotina principal do MRP
	bBkpF4  := SetKey( VK_F4  , {|| Nil } )
	bBkpF5  := SetKey( VK_F5  , {|| Nil } )
	bBkpF11 := SetKey( VK_F11 , {|| Nil } )
	bBkpF12 := SetKey( VK_F12 , {|| Nil } )
	bBkpAlX := SetKey( K_ALT_X, {|| Nil } )

    // Dialog para exibição dos itens do tipo PA ou PI que necessitam de OPs a serem geradas
    oDlg := FWDialogModal():New()
    oDlg:SetEscClose( .T. )
    oDlg:SetTitle( 'SmartSupply - OPs a serem geradas - '+ U_JSGETVER() )
    oDlg:SetSize( (MsAdvSize()[6]/2)*0.7, (MsAdvSize()[5]/2)*0.7 )
    oDlg:SetSubTitle( "Produtos que possuem estrutura para serem produzidos...." )
    oDlg:CreateDialog()
	oDlg:AddCloseButton( {|| oDlg:DeActivate()}, "Cancelar" )
	oDlg:AddOkButton( {|| lChange := MsgYesNo( 'Ao gerar as OPs através deste botão, você <b>IGNORA</b> a análise de demanda de matéria-prima, '+;
												'está certo(a) que deseja gerar a OP por aqui?', 'A T E N Ç Ã O !' ),;
						  iif( lChange, Processa( {|| lChange := createOPs( oOPs ) }, 'Aguarde!', 'Gerando OPs...' ), Nil ),; 
                          oDlg:DeActivate() }, "Apenas Gerar OPs" )
	oDlg:AddButtons( aButtons )

    oMain := oDlg:GetPanelMain()

    oOps := FWBrowse():New( oMain )
	oOps:SetDataTable()
    oOPs:SetAlias( 'TMPSC2' )
	oOps:DisableReport()
	oOps:AddMarkColumns( {|oOps| if( TMPSC2->MARK, 'LBOK','LBNO' ) },;
						 {|oOps| TMPSC2->MARK := !TMPSC2->MARK },;
						 {|oOps| lMark := !TMPSC2->MARK, DBEval( {|| TMPSC2->MARK := lMark } ), oOps:UpdateBrowse() } )
	oOps:SetColumns( aColumns )
	oOps:Activate()

    oDlg:Activate( ,,,.T., bValid,, bInit )

	// Devolve as configurações padrões das teclas de atalho após fechamento da janela de exibição das PAs
	bBkpF4  := SetKey( VK_F4  , bBkpF4  )
	bBkpF5  := SetKey( VK_F5  , bBkpF5  )
	bBkpF11 := SetKey( VK_F11 , bBkpF11 )
	bBkpF12 := SetKey( VK_F12 , bBkpF12 )
	bBkpAlX := SetKey( K_ALT_X, bBkpAlX )

return lChange

/*/{Protheus.doc} createOPs
Função que cria as OPs baseado nos registros marcados da tabela temporária TMPSC2
@type function
@version 12.1.2510
@author Jean Carlos Pandolfo Saggin
@since 19/05/2026
@param oBrw, object, Objeto do browse
@return logical, lSuccess, indica se houve sucesso no processo de inclusão das OPs
/*/
static function createOPs( oBrw )
	
	local lSuccess := .T. as logical
	local nRecAtu  := TMPSC2->(Recno())
	local aOrdPrd  := {} as array
	local aRetJob  := {} as array
	local aOPs     := {} as array
	local cMsg     := "" as character
	local nReg     := 0 as numeric
	
	DBSelectArea( 'TMPSC2' )
	TMPSC2->( DBGoTop() )
	
	// Soma quantidade de registros existentes na tabela e que estejam marcados
	DBEval({|| iif( TMPSC2->MARK, nReg++, Nil ) })
	TMPSC2->( DBGoTop() )

	while ! TMPSC2->( EOF() ) .and. lSuccess
		
		if TMPSC2->MARK

			IncProc( 'Incluindo OP ref. produto '+  AllTrim(TMPSC2->B1_DESC) +'...' )
			aOrdPrd := MakeOp()
			aRetJob := StartJob( 'U_JSINCOP',;
								 GetEnvServer(),;
								 .T. /* lWait */,;
								 aOrdPrd,;
								 cEmpAnt,;
								 cFilAnt ) 
			lSuccess := ValType( aRetJob ) == 'A' .and. len(aRetJob) == 2 .and. !Empty( aRetJob[1] )
			if lSuccess 
				aAdd( aOPs, { TMPSC2->( Recno() ), aRetJob[1] } )
			else
				hlp( 'OP_FAILED',;
					'Falha na Inclusão da Ordem de Produção',;
					aRetJob[2] )
			endif

		endif
		TMPSC2->( DBSkip() )
	enddo
	
	// Verifica se conseguiu gerar alguma OP
	if len( aOPs ) > 0
	
		// Após inclusão da OP, elimina os registros da tabela temporária
		cMsg := "Foram geradas as OPs: "+ CHR(13)+CHR(10)
		aEval( aOPs, {|x| TMPSC2->( DBGoTo( x[1] ) ),;
						  RecLock( 'TMPSC2', .F. ),;
						  TMPSC2->( DBDelete() ),;
						  TMPSC2->( MsUnlock() ),;
						  cMsg += x[2] + chr(13)+ chr(10) } )
		oBrw:Refresh()
		oBrw:UpdateBrowse()
		
		MsgInfo( cMsg, 'Resumo de OPs Geradas' )

	else
		// Se não incluiu nenhuma OP, devolve o registro que estava posicionado
		TMPSC2->( DBGoTo( nRecAtu ) )
	endif

return lSuccess

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

/*/{Protheus.doc} makeOP
Cria o Vetor da OP
@type function
@version 12.1.2410
@author JS Soluções
@since 3/13/2025
@return array, aOrdPrd
/*/
static function makeOP()

    local cOP     := Space( TAMSX3('C2_NUM')[1] ) as character
    local aOrdPrd := {} as array

    DBSelectArea( 'SC2' )
    SC2->( DbSetOrder( 1 ) )

    cOP := GetSXENum( 'SC2', 'C2_NUM', ,1 )
    ConfirmSX8()
    
    // Valida existência do número da OP antes de prosseguir
    while SC2->( DBSeek( FWxFilial( 'SC2' ) + cOP ) )
        cOP := GetSXENum( 'SC2', 'C2_NUM', ,1 )
        ConfirmSX8()
    end

    aAdd( aOrdPrd, { "C2_FILIAL" , FWxFilial( "SC2" ), Nil } )
    aAdd( aOrdPrd, { "C2_NUM"    , cOP, Nil } )
    aAdd( aOrdPrd, { "C2_PRODUTO", TMPSC2->C2_PRODUTO, Nil } )
    aAdd( aOrdPrd, { "C2_ITEM"   , "01", Nil } )
    aAdd( aOrdPrd, { "C2_SEQUEN" , "001", Nil } )
    aAdd( aOrdPrd, { "C2_QUANT"  , TMPSC2->C2_QUANT, Nil } )
    aAdd( aOrdPrd, { "C2_DATPRI" , dDataBase, Nil } )
    aAdd( aOrdPrd, { "C2_DATPRF" , dDataBase, Nil } )
    aAdd( aOrdPrd, { "C2_OBS"    , "OP Gerada via SmartSupply", Nil  } )
    aAdd( aOrdPrd, { "C2_EMISSAO", dDataBase, Nil } )
    aAdd( aOrdPrd, { "C2_TPOP"   , 'F' /*F=Firme ou P=Prevista*/, Nil } )
    aAdd( aOrdPrd, { "C2_STATUS" , 'N' /*N=Normal ou U=Suspensa ou S=Sacramentada*/, Nil } )
    // aAdd( aOrdPrd, { "C2_X_PROGR", iif( lMVC, oOP:GetValue( _cAliCb +'_CDPLAN' ), &( _cAliCb +'->'+ _cAliCb +'_CDPLAN' ) ), Nil } )
    // aAdd( aOrdPrd, { "C2_X_IDAPO", iif( lMVC, oOP:GetValue( _cAliCb +'_ID' ), &( _cAliCb +'->'+ _cAliCb +'_ID' ) ), Nil } )
    aAdd( aOrdPrd, {"AUTEXPLODE" , "S" , NIL} )
    
    SC2->( DbSetOrder( 1 ) )

return aOrdPrd

/*/{Protheus.doc} removePA
Remove os itens selecionados da lista de PAs
@type function
@version 12.1.2510
@author Jean Carlos Pandolfo Saggin
@since 15/05/2026
@return logical, lSuccess
/*/
static function removePA()

	local nRec     := TMPSC2->( Recno() )
	local lSuccess := .T. as logical
	local aRemove  := {} as array
	local nX       := 0 as numeric
	
	DBSelectArea( 'TMPSC2' )
	TMPSC2->( DBSetOrder( 1 ) )
	TMPSC2->( DBGoTop() )
	DBEval( {|| iif( TMPSC2->MARK, aAdd( aRemove, TMPSC2->C2_PRODUTO ), Nil ) } )
	
	// Verifica se há itens a serem removidos e se o usuário realmente quer remover
	if len( aRemove ) > 0  .and. MsgYesNo( 'Está certo que deseja <b>REMOVER</b> os PAs marcados?', 'A T E N Ç Ã O !' )
		
		for nX := 1 to len( aRemove )
			
			if TMPSC2->( DBSeek( aRemove[nX] ) )

				// Remove da tabela temporária de PA
				RecLock( 'TMPSC2', .F. )
				TMPSC2->( DBDelete() )
				TMPSC2->( MsUnlock() )
				SC22col()

			else
				lSuccess := .F.
			endif

		next nX
	endif

	if !lSuccess
		// Se não houve sucesso no processo, devolve o Recno posicionado
		TMPSC2->( DBGoTo( nRec ) )
	endif
	
return lSuccess

/*/{Protheus.doc} SC22col
Função para atualizar dados da tabela temporária da SC2 para o vetor principal da rotina
@type function
@version 12.1.2510
@author Jean Carlos Pandolfo Saggin
@since 15/05/2026
@return logical, lSccess
/*/
static function SC22col()
	
	local nRec     := TMPSC2->( Recno() )
	local lSuccess := .T. as logical
	local nPAs     := 0 as numeric

	// Verifica se consegue localizar no vetor de produtos, o código da PA que está sendo removido
	if aScan( aColPro, {|x| x[nPosPrd] == TMPSC2->C2_PRODUTO } ) > 0
		aColPro[ aScan( aColPro, {|x| x[nPosPrd] == TMPSC2->C2_PRODUTO } ) ][nPosChk] := .F.		// Desmarca o PA
	endif

	// Desmarca do vetor full
	if aScan( aFullPro, {|x| x[nPosPrd] == TMPSC2->C2_PRODUTO } ) > 0
		aFullPro[ aScan( aFullPro, {|x| x[nPosPrd] == TMPSC2->C2_PRODUTO } ) ][nPosChk] := .F.		// Desmarca o PA também do vetor full
	endif
	
	// Percorre TMPSC2 buscando todas as PAs listadas
	DBSelectArea( 'TMPSC2' )
	TMPSC2->(DBGoTop())
	DBEval( {|| iif( !TMPSC2->(Deleted()), nPAs++, Nil ) } )

	// Atualiza componente do botão que indica quantidade de PAs selecionadas
	oBtnOPs:CCAPTION := cValToChar( nPAs ) + " PA(s)"
	oBtnOPs:NWIDTH   := (Len( AllTrim( oBtnOPs:CCAPTION ) )+1)*10
	oBtnOPs:Refresh()
	
	// Atualiza browse de produtos
	oBrwPro:UpdateBrowse()

	// Devolve o registro que estava posicionado anteriormente
	TMPSC2->( DBGoTo( nRec ) )

return lSuccess

/*/{Protheus.doc} showMP
Função para exibir as MPs ligadas ao processo de produção do PA selecionado
@type function
@version 12.1.2510
@author Jean Carlos Pandolfo Saggin
@since 13/05/2026
@param lAll, logical, .T. para exibir todas as MPs ou .F. para exibir apenas as necessidades de compra
@return logical, lChange
/*/
static function showMP( lAll )
	
	local aArea  := getArea()
	local oDlg    as object
	local aMPs    := {} as array
	local aBkpFil := {} as array

	local bValid   := {|| .T. }
	local bOk      := {|| lChange := add2Car( aData, oBrw ), oDlg:End() }
	local bCancel  := {|| oDlg:End() }
	local aButtons := {} as array
	local bInit    := {|| EnchoiceBar( oDlg, bOk, bCancel,,aButtons ) }
	local aConfig  := U_JSGETCFG(.F. /* lAuto */)
	local aFields  := U_JSMAINFD()[1]												// Campos a serem exibidos no grid de produtos
	Local aAlter   := U_JSMAINFD()[2]												// Campos editáveis no grid de produtos
	local aHeaPro  := U_JSCOLPRO( aFields, aAlter )
	local aSize    := MsAdvSize()
	local lMark    := .F. as logical
	local aTemp    := {} as array
	local nX       := 0 as numeric
	local aTemp2   := {} as array
	local lChange  := .F. as logical
	local nPosFul   := 0 as numeric
	local nConMedPA := 0 as numeric

	local cTitulo := "Matéria-Prima para PA: "+ AllTrim(TMPSC2->B1_DESC) + " - " + AllTrim(TMPSC2->C2_PRODUTO )

	Private oBrw  as object
	Private aData := {} as array

	default lAll := .T. 	// Indica se deve exibir todas as MPs ou apenas o que gerou demanda de compra

	// Realiza backup dos filtros do usuário antes de realizar o processamento e depois devolve assim que o usuário encerrar a tela das MPs
	if Type( '_aFilters' ) == 'A' .and. len( _aFilters ) > 0
		aBkpFil := aClone( _aFilters )
		_aFilters := {}
	endif

	// Monta tabela temporária com as MPs para exibir em tela
	DBSelectArea( 'TMPSC2' )
	TMPSC2->( DBGoTop() )
	while ! TMPSC2->( EOF() )
		if TMPSC2->MARK	// Verifica se o registro está marcado
			// Recupera o consumo médio diário real do PA (mesmo índice exibido na grid principal), base para explodir a estrutura
			nPosFul   := aScan( aFullPro, {|x| x[nPosPrd] == TMPSC2->C2_PRODUTO } )
			nConMedPA := iif( nPosFul > 0, aFullPro[nPosFul][nPosCon], 0 )
			// Obtém as MPs ligadas ao PA, explodindo o consumo médio (e não a necessidade de compra) pela estrutura
			aTemp := getMPs( TMPSC2->C2_PRODUTO, nConMedPA )
			if len( aTemp ) > 0
				for nX := 1 to len( aTemp )
					// Se o produto já está relacionado no vetor de MPs, apenas soma as quantidades, do contrário, adiciona o produto e quantidade
					if aScan( aTemp2, {|x| x[1] == aTemp[nX][1] } ) == 0
						aAdd( aTemp2, aClone( aTemp[nX] ) )
					else
						aTemp2[aScan( aTemp2, {|x| x[1] == aTemp[nX][1] } )][2] += aTemp[nX][2]
					endif
				next nX
			endif
			aTemp := {}
		endif
		TMPSC2->( DBSkip() )
	enddo

	// aTemp2 já contém o consumo médio diário de cada MP (soma das contribuições de cada PA marcado, explodidas pela estrutura)
	aMPs := aClone( aTemp2 )

	// Chama processamento do cálculo das MPs para mostrar ao usuário
	aData := U_JSCALCMP( aMPs, lAll )

	// Botão "Outras Ações" para consultar como o sistema chegou na sugestão calculada para a MP posicionada na grid
	aAdd( aButtons, { "BMPCONSUL", {|| iif( len( aData ) > 0, U_JSSEQCAL( aData[oBrw:nAt][nPosPrd] ), Nil ) }, 'Sequência de Cálculo da Sugestão'} )

	// Limpa conteúdo das teclas de atalho para evitar conflitos com a rotina principal do MRP
	SetKey( VK_F4, {|| Processa( {|| U_JSSUPPLY( /* lForce */, aData, oBrw ) }, 'Aguarde!','Analisando fornecedores da MP...' ) } )

	oDlg := TDialog():New( 0, 0, aSize[6]*0.9, aSize[5]*0.9,cTitulo,,,,,CLR_BLACK,CLR_WHITE,,,.T.)
	
	oBrw := FWBrowse():New( oDlg )
	oBrw:SetDataArray()
	oBrw:SetArray( aData )
	oBrw:DisableReport()
	oBrw:AddLegend( "aData[oBrw:nAt][1] >= "+ cValToChar( aConfig[10] ), LG_CRITICO, "Itens Criticos" )
	oBrw:AddLegend( "aData[oBrw:nAt][1] < "+ cValToChar( aConfig[10] ) +" .and. "+;
					   "aData[oBrw:nAt][1] >= "+ cValToChar( aConfig[11] ), LG_ALTO, "Alto Giro" )
	oBrw:AddLegend( "aData[oBrw:nAt][1] < "+ cValToChar( aConfig[11] ) +" .and. "+;
					   "aData[oBrw:nAt][1] >= "+ cValToChar( aConfig[12] ), LG_MEDIO, "Medio Giro" )
	oBrw:AddLegend( "aData[oBrw:nAt][1] < "+ cValToChar( aConfig[12] ) +" .and. "+;
					   "aData[oBrw:nAt][1] >= "+ cValToChar( aConfig[13] ), LG_BAIXO, "Baixo Giro" )  
	oBrw:AddLegend( "aData[oBrw:nAt][1] < "+ cValToChar( aConfig[13] ), LG_SEMGIRO, "Sem Giro" )
	oBrw:AddMarkColumn( {|| iif( aData[oBrw:nAt][2], "LBOK", "LBNO" ) },; 
						{|| aData[oBrw:nAt][2] := iif( aData[oBrw:nAt][nPosNec] > 0, !aData[oBrw:nAt][2], aData[oBrw:nAt][2] ) },; 
						{|| lMark := len(aData) > 0 .and. !aData[1][2], iif( len( aData ) > 0, aEval( aData, {|x| x[2] := iif( x[nPosNec] > 0, lMark, x[2] ) } ), Nil ), oBrw:UpdateBrowse() } )
	oBrw:SetColumns( aHeaPro )
	oBrw:GetColumn(aScan( aHeaPro, {|x| AllTrim(x[17]) == 'A5_FORNECE' } )+2):xF3 := "SA2"
	oBrw:SetEditCell( .T., {|| .T. } )
	oBrw:Activate()

	oDlg:Activate(,,,.T., bValid,, bInit)

	// Devolve os filtros do usuário para que a função possa prosseguir
	if len( aBkpFil ) > 0
		_aFilters := aClone( aBkpFil )
	endif

	restArea( aArea )
return lChange

/*/{Protheus.doc} add2Car
Função para adicionar itens de MP marcados para o vetor do carrinho de compras
@type function
@version 12.1.2510
@author Jean Carlos Pandolfo Saggin
@since 19/05/2026
@param aData, array, vetor de dados da grid
@param oBrw, object, objeto da grid
@return logical, lSuccess
/*/
static function add2Car( aData, oBrw )
	
	local lSuccess := .F. as logical
	local nX       := 0 as numeric
	
	if len( aData ) > 0
		for nX := 1 to len( aData )
			// Verifica se o item está marcado e se a necessidade de compra é maior do que zero
			oBrw:GoTo(nX)
			if aData[oBrw:nAt][nPosChk] .and. aData[oBrw:nAt][nPosNec] > 0
				U_JSMRKPRO( aData, oBrw )
				lSuccess := .T.
			endif
		next nX
	endif

return lSuccess

/*/{Protheus.doc} getMPs
Retornar todas as MPs ligadas ao PA (e subprodutos) retornando o código de cada insumo, quantidade média diária a ser utilizada e quantidade total
@type function
@version 12.1.2510
@author Jean Carlos Pandolfo Saggin
@since 12/05/2026
@param cProduto, character, Código do produto tipo PA
@param nQuant, numeric, Quantidade diária (consumo médio) do produto a ser explodida pela estrutura
@return array, aMPs, vetor contendo código e consumo médio diário por matéria-prima que será consumida
/*/
static function getMPs( cProduto, nQuant )

	local aArea := getArea()
	local aMPs  := {} as array
	local aSub  := {} as array
	
	DBSelectArea( 'SG1' )
	SG1->( DBSetOrder( 1 ) )    // G1_FILIAL + G1_COMP + G1_COD
	if SG1->( DBSeek( FWxFilial( 'SG1' ) + cProduto ) )
		while ! SG1->( EOF() ) .and. SG1->G1_FILIAL == FWxFilial( 'SG1' ) .and. SG1->G1_COD == cProduto
			
			// Verifica se o componente é um produto intermediário
			if U_JSISPA( SG1->G1_COMP )
				aSub := getMPs( SG1->G1_COMP, SG1->G1_QUANT * nQuant )
				aEval( aSub, {|x| aAdd( aMPs, aClone(x) ) } )
				aSub := {}
			else
				aAdd( aMPs, { SG1->G1_COMP, SG1->G1_QUANT * nQuant } )
			endif

			SG1->(DbSkip())
		EndDo
	endif

	restArea( aArea )
return aMPs

/*/{Protheus.doc} JSHDRPA
Função que retorna colunas a serem exibidas na grid de PAs
@type function
@version 12.1.2510
@author Jean Carlos Pandolfo Saggin
@since 11/05/2026
@return array, aColumns
/*/
user function JSHDRPA()
	
	local aFields  := { "C2_PRODUTO", "B1_DESC", "C2_UM", "C2_QUANT" }
	local aCanEdt  := { "C2_QUANT" }
	local aColumns := {} as array
	local nX       := 0 as numeric
	local cType    := "" as character

	for nX := 1 to len( aFields )
		cType := GetSX3Cache( aFields[nX], 'X3_TIPO' )
		aAdd( aColumns, { ;
						  GetSX3Cache( aFields[nX], 'X3_TITULO' ) /* cTitle */,;
						  &('{|oBrw| '+ aFields[nX] +' }') /* bLoadData */,;
						  cType,;
						  GetSX3Cache( aFields[nX], 'X3_PICTURE' ) /* cPicture */,;
						  iif( cType $ "C|M", 1, iif( cType == 'N', 2, 0 ) ) /* nAlign */,;
						  GetSX3Cache( aFields[nX], 'X3_TAMANHO' )*0.5 /* nColSize */,;
						  GetSX3Cache( aFields[nX], 'X3_DECIMAL' ) /* nDecimal */,;
						  aScan( aCanEdt, {|x| AllTrim(x) == AllTrim(aFields[nX]) } ) > 0 /* lCanEdit */,;
						  {|| U_BRWPAVLD() } /* bCellVld */,;
						  .F. /* lShowImg */,;
						  Nil /* bLDblClick */,;
						  "TMPSC2->"+  aFields[nX] /* cReadVar */,;
						  Nil /* bHeaderClick */,;
						  .F. /* lDeleted */,;
						  .F. /* lDetail */,;
						  Nil /* aOptions */,;
						  aFields[nX] /* cID */,;
						  .F. /* lVirtual */;
						   } )
	next nX

return aColumns

user function BRWPAVLD()
return .T.

/*/{Protheus.doc} JSALIASPA
Função para criar a temp-table para armazenamento dos dados dos PAs em que deve haver geração das OPs
@type function
@version 12.1.2510
@author Jean Carlos Pandolfo Saggin
@since 11/05/2026
@param aColumns, array, vetor de colunas do browse
@return object, oTable
/*/
user function JSALIPA( aColumns )
	
	local oAlias as object
	local nX     := 0 as numeric
	local aStruct := {} as array

    aAdd( aStruct, { "MARK", "L", 1, 0 } )      // Campo para indicar se o registro está ou não selecionado
	for nX := 1 to len( aColumns )
		cField := aColumns[nX][17]
		aAdd( aStruct, { cField,; 
						 GetSX3Cache( cField, "X3_TIPO" ),;
						 GetSX3Cache( cField, "X3_TAMANHO" ),;
						 GetSX3Cache( cField, "X3_DECIMAL" ) } )
	next nX
	
	oAlias := FWTemporaryTable():New( 'TMPSC2', aStruct )
	oAlias:AddIndex( '01', { 'C2_PRODUTO' } )
	oAlias:Create()

return oAlias
