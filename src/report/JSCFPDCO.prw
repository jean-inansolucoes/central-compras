#include 'totvs.ch'
#include 'topconn.ch'

/*/{Protheus.doc} JSCFPDCO
Tela de configuracao do layout do relatorio de pedido de compra (item 6 da analise do Painel de
Compras). Permite definir, por ambiente, quais campos aparecem no cabecalho e nos itens do PDF
gerado por JSRLPDCO.tlpp, e com que largura, sem a necessidade de alterar codigo-fonte para cada
cliente. A configuracao e gravada em /gmpaicom/jsrlpdco.conf (JSON).
@type function
@version 1.0
@author Visualize - Software e Inovacao
@since 30/07/2026
/*/
user function JSCFPDCO()

	local oDlgCfg    as object
	local oLayer     as object
	local oWinCab    as object
	local oWinIte    as object
	local oGrpLin    as object
	local oGrpCpo    as object
	local aSize      := MsAdvSize()
	local oCfg       as object
	local bOk        as codeblock
	local bCancel    as codeblock

	Private aLinhas     := {} as array	// Uma entrada por linha do cabecalho: {nSeq, nAlturaCm, aCampos} - FWBrowse opera direto neste array
	Private aItens      := {} as array	// Uma entrada por campo de item: {nSeq,cLabel,nTam,cOrigem,cDado,cFormula,cAlin} - FWBrowse opera direto neste array
	Private oBrwLin     as object
	Private oBrwCpoCab  as object
	Private oBrwIte     as object
	Private aRowsCab := {} as array	// Copia dos campos da linha de cabecalho selecionada (muda a cada linha escolhida em oBrwLin)
	Private oColDadCab as object	// Coluna "Dado" da grid de campos do cabecalho - SetOptions atualizado conforme a Origem
	Private oColDadIte as object	// Coluna "Dado" da grid de itens - SetOptions atualizado conforme a Origem

	if File( U_JSPATHSV(3) )
		oCfg := carCfgAtu()
	else
		oCfg := monCfgPad()
	endif

	carEstrut( oCfg )

	bOk     := {|| okConfirm( oDlgCfg ) }
	bCancel := {|| oDlgCfg:End() }

	DEFINE MSDIALOG oDlgCfg TITLE "SmartSupply - Layout do Relatorio de Pedido de Compra" FROM 000, 000 TO aSize[06], aSize[05] COLORS 0, 16777215 PIXEL STYLE DS_MODALFRAME

	oLayer := FWLayer():New()
	oLayer:Init( oDlgCfg )

	oLayer:AddLine( "linCab", 50, .T. )
	oLayer:AddColumn( "colCab", 100, .F., "linCab" )
	oLayer:AddWindow( "colCab", "winCab", "Cabecalho do Relatorio", 100, .F., .F., , "linCab" )
	oWinCab := oLayer:GetWinPanel( "colCab", "winCab", "linCab" )

	oLayer:AddLine( "linIte", 50, .T. )
	oLayer:AddColumn( "colIte", 100, .F., "linIte" )
	oLayer:AddWindow( "colIte", "winIte", "Itens do Relatorio", 100, .F., .F., , "linIte" )
	oWinIte := oLayer:GetWinPanel( "colIte", "winIte", "linIte" )

	// Duas metades lado a lado dentro da janela superior: linhas (esquerda) x campos da linha (direita).
	// Nao usa FWLayer aninhado (sem precedente comprovado no projeto) - posiciona os grupos diretamente.
	// TGroup trabalha em uma proporcao de resolucao diferente do WinPanel do FWLayer - por isso
	// oWinCab:nHeight/nWidth precisam ser divididos por 2 para as coordenadas baterem corretamente.
	oGrpLin := TGroup():New( 002, 002, (oWinCab:nHeight/2)-4, ((oWinCab:nWidth/2)*0.35), "Linhas do Cabecalho" /* cTitle */, oWinCab,,,.T. )
	oGrpCpo := TGroup():New( 002, ((oWinCab:nWidth/2)*0.35)+6, (oWinCab:nHeight/2)-4, (oWinCab:nWidth/2)-4, "Campos da Linha Selecionada" /* cTitle */, oWinCab,,,.T. )

	monGrdLin( oGrpLin )
	monGrdCab( oGrpCpo )
	monGrdIte( oWinIte )

	ACTIVATE MSDIALOG oDlgCfg CENTERED ON INIT Eval( {|| EnchoiceBar( oDlgCfg, bOk, bCancel ) } )

return Nil

/*/{Protheus.doc} okConfirm
Acao do botao "Confirmar" da EnchoiceBar: valida e grava a configuracao e, somente se valida,
encerra o dialogo.
@type function
@version 1.0
@author Visualize - Software e Inovacao
@since 30/07/2026
@param oDlg, object, dialogo principal da tela de configuracao
@return logical, lSuccess
/*/
static function okConfirm( oDlg )

	local lSuccess := valEGrava() as logical

	if lSuccess
		oDlg:End()
	endif

return lSuccess

/*/{Protheus.doc} monCfgPad
Facilitador: quando ainda nao existe /gmpaicom/jsrlpdco.conf, monta em memoria a estrutura
equivalente ao layout hoje hardcoded em JSRLPDCO.tlpp, como ponto de partida editavel. Os campos
que hoje sao calculados por funcao AdvPL (Transportadora, Valor Frete, Prev.Entr., Cod.Prd.For.,
Fornecedor+Loja, Razao Social, CGC/CPF, Cond.Pagto) entram como Origem=FOR com formula em branco -
o usuario precisa escolher uma formula ja cadastrada no Configurador antes de conseguir gravar.
@type function
@version 1.0
@author Visualize - Software e Inovacao
@since 30/07/2026
@return object, oCfg
/*/
static function monCfgPad()

	local oCfg   := JsonObject():New()
	local oCab   := JsonObject():New()
	local oIte   := JsonObject():New()
	local aLin   := {}

	aAdd( aLin, monLinPad( { { "Fornecedor", 10, 12, "FOR", "", "" },;
									{ "Razao Social", 12, 40, "FOR", "", "" },;
									{ "CGC/CPF", 6, 20, "FOR", "", "" } } ) )

	aAdd( aLin, monLinPad( { { "Cond.Pagto", 10, 34, "FOR", "", "" },;
									{ "Emissao", 12, 20, "SC7", "C7_EMISSAO", "" },;
									{ "Tp. Frete", 8, 16, "FOR", "", "" } } ) )

	aAdd( aLin, monLinPad( { { "Transportadora", 12, 33, "FOR", "", "" },;
									{ "Valor Frete", 12, 15, "FOR", "", "" },;
									{ "Prev.Entr.", 13, 15, "FOR", "", "" } } ) )

	oCab['linhas'] := aLin
	oCfg['cabecalho'] := oCab

	oIte['campos'] := {}
	aAdd( oIte['campos'], monCpoIte( "Item", 4, "SC7", "C7_ITEM", "", "CENTER", .F. ) )
	aAdd( oIte['campos'], monCpoIte( "Cod.Prd.For.", 14, "FOR", "", "", "LEFT", .F. ) )
	aAdd( oIte['campos'], monCpoIte( "Codigo", 9, "SC7", "C7_PRODUTO", "", "LEFT", .F. ) )
	aAdd( oIte['campos'], monCpoIte( "GrTb", 4, "SB1", "B1_XGPTP", "", "CENTER", .T. ) )
	aAdd( oIte['campos'], monCpoIte( "Descricao", 33, "SB1", "B1_DESC", "", "LEFT", .F. ) )
	aAdd( oIte['campos'], monCpoIte( "Qtde", 9, "SC7", "C7_QUANT", "", "RIGHT", .F. ) )
	aAdd( oIte['campos'], monCpoIte( "UM", 4, "SC7", "C7_UM", "", "CENTER", .F. ) )
	aAdd( oIte['campos'], monCpoIte( "Vlr Unit.", 7, "SC7", "C7_PRECO", "", "RIGHT", .F. ) )
	aAdd( oIte['campos'], monCpoIte( "Vlr Total", 10, "SC7", "C7_TOTAL", "", "LEFT", .F. ) )
	aAdd( oIte['campos'], monCpoIte( "IPI", 6, "SC7", "C7_IPI", "", "LEFT", .F. ) )
	oCfg['itens'] := oIte

return oCfg

/*/{Protheus.doc} monLinPad
Monta um JsonObject de uma linha do cabecalho (altura padrao 0.6cm) a partir de um array simples
de definicoes de campo, usado apenas por monCfgPad().
@type function
@version 1.0
@author Visualize - Software e Inovacao
@since 30/07/2026
@param aDefs, array, { {cLabel,nTamRot,nTamDad,cOrigem,cDado,cFormula}, ... }
@return object, oLinha
/*/
static function monLinPad( aDefs )

	local oLinha := JsonObject():New()
	local aCampos := {}
	local nX := 0 as numeric
	local oCampo as object

	for nX := 1 to len( aDefs )
		oCampo := JsonObject():New()
		oCampo['label']          := aDefs[nX][1]
		oCampo['tamanho_rotulo'] := aDefs[nX][2]
		oCampo['tamanho_dado']   := aDefs[nX][3]
		oCampo['origem']         := aDefs[nX][4]
		oCampo['dado']           := aDefs[nX][5]
		oCampo['formula']        := aDefs[nX][6]
		aAdd( aCampos, oCampo )
	next nX

	oLinha['altura_cm'] := 0.6
	oLinha['campos']    := aCampos

return oLinha

/*/{Protheus.doc} monCpoIte
Monta um JsonObject de um campo da grade de itens, usado apenas por monCfgPad().
@type function
@version 1.0
@author Visualize - Software e Inovacao
@since 30/07/2026
@return object, oCampo
/*/
static function monCpoIte( cLabel, nTam, cOrigem, cDado, cFormula, cAlin, lOpcional )

	local oCampo := JsonObject():New()

	oCampo['label']     := cLabel
	oCampo['tamanho']   := nTam
	oCampo['origem']    := cOrigem
	oCampo['dado']      := cDado
	oCampo['formula']   := cFormula
	oCampo['alinhamento'] := cAlin
	oCampo['opcional']  := lOpcional

return oCampo

/*/{Protheus.doc} carCfgAtu
Le o arquivo /gmpaicom/jsrlpdco.conf ja existente, no mesmo padrao ja usado pelo painel para
preferencias do usuario (FWFileReader + JsonObject:FromJson).
@type function
@version 1.0
@author Visualize - Software e Inovacao
@since 30/07/2026
@return object, oCfg (Nil se falhar a leitura - nesse caso, monta o padrao)
/*/
static function carCfgAtu()

	local oJson   := JsonObject():New()
	local oFile   as object
	local cResult := Nil
	local oRet    := Nil

	oFile := FWFileReader():New( U_JSPATHSV(3) )
	if oFile:Open()
		cResult := oJson:FromJson( oFile:FullRead() )
		if ValType( cResult ) == 'U'
			oRet := oJson
		endif
		oFile:Close()
	endif

	if oRet == Nil
		oRet := monCfgPad()
	endif

return oRet

/*/{Protheus.doc} carEstrut
Converte o objeto de configuracao (oCfg, vindo do disco ou do padrao) para os arrays de trabalho
(aLinhas/aItens) usados pelas grids da tela, e monta os espelhos achatados iniciais.
@type function
@version 1.0
@author Visualize - Software e Inovacao
@since 30/07/2026
@param oCfg, object, configuracao carregada
/*/
static function carEstrut( oCfg )

	local nX as numeric
	local nY as numeric
	local oLinha as object
	local oCampo as object
	local aCampos as array
	local nTamForm := TAMSX3( "M4_CODIGO" )[1] as numeric

	aLinhas := {}
	for nX := 1 to len( oCfg['cabecalho']['linhas'] )
		oLinha := oCfg['cabecalho']['linhas'][nX]
		aCampos := {}
		for nY := 1 to len( oLinha['campos'] )
			oCampo := oLinha['campos'][nY]
			aAdd( aCampos, { nY, PADR( oCampo['label'], 30 ), oCampo['tamanho_rotulo'], oCampo['tamanho_dado'], oCampo['origem'], oCampo['dado'], PADR( oCampo['formula'], nTamForm ) } )
		next nY
		aAdd( aLinhas, { nX, oLinha['altura_cm'], aCampos } )
	next nX

	aItens := {}
	for nX := 1 to len( oCfg['itens']['campos'] )
		oCampo := oCfg['itens']['campos'][nX]
		aAdd( aItens, { nX, PADR( oCampo['label'], 30 ), oCampo['tamanho'], oCampo['origem'], oCampo['dado'], PADR( oCampo['formula'], nTamForm ), oCampo['alinhamento'] } )
	next nX

	if len( aLinhas ) > 0
		aRowsCab := aClone( aLinhas[1][3] )
	endif

return Nil

/*/{Protheus.doc} renumSeq
Renumera sequencialmente a coluna "Seq." (posicao 1) de um array de trabalho, usado apos
inserir/excluir uma linha em qualquer uma das 3 grids da tela.
@type function
@version 1.0
@author Visualize - Software e Inovacao
@since 30/07/2026
@param aArr, array, array de trabalho a renumerar (aLinhas, aItens ou aRowsCab)
/*/
static function renumSeq( aArr )

	local nX as numeric

	for nX := 1 to len( aArr )
		aArr[nX][1] := nX
	next nX

return Nil

/*/{Protheus.doc} stripCbo
Extrai apenas o codigo (parte antes do "=") de um valor que pode ter vindo tanto de digitacao
livre quanto de um combo montado via SetOptions/lstCpoMul ("CODIGO=Titulo"). Seguro para string
vazia.
@type function
@version 1.0
@author Visualize - Software e Inovacao
@since 30/07/2026
@param cVal, character, valor a limpar
@return character, codigo limpo
/*/
static function stripCbo( cVal )

	local aTok as array

	if Empty( cVal )
		return ""
	endif

	aTok := StrTokArr( cVal, "=" )
	if len( aTok ) == 0
		return AllTrim( cVal )
	endif

return AllTrim( aTok[1] )

/*/{Protheus.doc} monGrdLin
Monta a grid editavel das linhas do cabecalho (esquerda da janela superior): Sequencia e Altura(cm).
Ao mudar de linha selecionada, atualiza a grid de campos (mestre-detalhe).
@type function
@version 1.0
@author Visualize - Software e Inovacao
@since 30/07/2026
@param oParent, object, painel onde a grid sera desenhada
/*/
static function monGrdLin( oParent )

	local aColumns := {} as array

	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( "Seq." )
	aColumns[len(aColumns)]:SetSize( 6 )
	aColumns[len(aColumns)]:SetType( 'N' )
	aColumns[len(aColumns)]:SetPicture( '@E 99' )
	aColumns[len(aColumns)]:SetData( {|| aLinhas[oBrwLin:At()][1] } )

	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( "Altura (cm)" )
	aColumns[len(aColumns)]:SetSize( 12 )
	aColumns[len(aColumns)]:SetType( 'N' )
	aColumns[len(aColumns)]:SetPicture( '@E 9.99' )
	aColumns[len(aColumns)]:SetData( {|| aLinhas[oBrwLin:At()][2] } )
	aColumns[len(aColumns)]:SetEdit( .T. )
	aColumns[len(aColumns)]:SetReadVar( 'aLinhas[oBrwLin:At()][2]' )

	oBrwLin := FWBrowse():New( oParent )
	oBrwLin:SetDataArray()
	oBrwLin:SetArray( aLinhas )
	oBrwLin:DisableConfig()
	oBrwLin:DisableReport()
	oBrwLin:SetColumns( aColumns )
	oBrwLin:SetEditCell( .T., {|| .T. } )
	oBrwLin:SetInsert( .T. )
	oBrwLin:SetDelete( .T., {|| delLin() } )
	oBrwLin:SetDelOK( {|| Len( aLinhas ) > 1 } )
	oBrwLin:bChange := {|| chgLin() }
	oBrwLin:Activate()

return Nil

/*/{Protheus.doc} chgLin
Evento de troca de linha selecionada na grid esquerda (linhas do cabecalho): renumera a sequencia,
garante altura/campos validos (protege contra uma linha recem-inserida pelo SetInsert nativo, cujos
campos ainda nao foram inicializados) e recarrega a grid de campos (direita) com os campos da nova
linha selecionada. Protegido contra a primeira chamada disparada pelo proprio oBrwLin:Activate(),
quando oBrwCpoCab ainda nao foi criado (monGrdCab so roda depois que monGrdLin retorna).
@type function
@version 1.0
@author Visualize - Software e Inovacao
@since 30/07/2026
/*/
static function chgLin()

	local nAt := oBrwLin:At() as numeric

	if nAt <= 0 .or. nAt > len( aLinhas )
		return Nil
	endif

	renumSeq( aLinhas )

	if ValType( aLinhas[nAt][2] ) != 'N' .or. aLinhas[nAt][2] == 0
		aLinhas[nAt][2] := 0.6
	endif
	if ValType( aLinhas[nAt][3] ) != 'A'
		aLinhas[nAt][3] := {}
	endif

	aRowsCab := aClone( aLinhas[nAt][3] )

	if ValType( oBrwCpoCab ) == 'O'
		oBrwCpoCab:SetArray( aRowsCab )
		oBrwCpoCab:Refresh( .T. )
		oBrwCpoCab:UpdateBrowse()
	endif

return Nil

/*/{Protheus.doc} delLin
Exclui a linha de cabecalho atualmente selecionada em oBrwLin (callback de SetDelete). Bloqueia a
exclusao quando so resta uma linha (a impressao precisa de pelo menos um bloco de cabecalho).
@type function
@version 1.0
@author Visualize - Software e Inovacao
@since 30/07/2026
@return logical, .T. se excluiu
/*/
static function delLin()

	local nAt := oBrwLin:At() as numeric

	if len( aLinhas ) <= 1 .or. nAt <= 0 .or. nAt > len( aLinhas )
		return .F.
	endif

	aDel( aLinhas, nAt )
	aSize( aLinhas, len( aLinhas ) - 1 )
	renumSeq( aLinhas )

	oBrwLin:SetArray( aLinhas )
	oBrwLin:Refresh( .T. )
	oBrwLin:UpdateBrowse()
	chgLin()

return .T.

/*/{Protheus.doc} monGrdCab
Monta a grid editavel dos campos da linha de cabecalho selecionada (direita da janela superior):
Sequencia, Label, Tamanho Rotulo, Tamanho Dado, Origem, Dado, Formula.
@type function
@version 1.0
@author Visualize - Software e Inovacao
@since 30/07/2026
@param oParent, object, painel onde a grid sera desenhada
/*/
static function monGrdCab( oParent )

	local aColumns := {} as array
	local aOriCab  := { "SA2=Fornecedor", "SC7=Pedido de Compra", "FOR=Formula" } as array

	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( "Seq." )
	aColumns[len(aColumns)]:SetSize( 5 )
	aColumns[len(aColumns)]:SetType( 'N' )
	aColumns[len(aColumns)]:SetPicture( '@E 99' )
	aColumns[len(aColumns)]:SetData( {|| aRowsCab[oBrwCpoCab:At()][1] } )

	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( "Label" )
	aColumns[len(aColumns)]:SetSize( 20 )
	aColumns[len(aColumns)]:SetType( 'C' )
	aColumns[len(aColumns)]:SetPicture( '@!' )
	aColumns[len(aColumns)]:SetData( {|| aRowsCab[oBrwCpoCab:At()][2] } )
	aColumns[len(aColumns)]:SetEdit( .T. )
	aColumns[len(aColumns)]:SetReadVar( 'aRowsCab[oBrwCpoCab:At()][2]' )

	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( "Tam.Rot(%)" )
	aColumns[len(aColumns)]:SetSize( 10 )
	aColumns[len(aColumns)]:SetType( 'N' )
	aColumns[len(aColumns)]:SetPicture( '@E 999' )
	aColumns[len(aColumns)]:SetData( {|| aRowsCab[oBrwCpoCab:At()][3] } )
	aColumns[len(aColumns)]:SetEdit( .T. )
	aColumns[len(aColumns)]:SetReadVar( 'aRowsCab[oBrwCpoCab:At()][3]' )

	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( "Tam.Dado(%)" )
	aColumns[len(aColumns)]:SetSize( 10 )
	aColumns[len(aColumns)]:SetType( 'N' )
	aColumns[len(aColumns)]:SetPicture( '@E 999' )
	aColumns[len(aColumns)]:SetData( {|| aRowsCab[oBrwCpoCab:At()][4] } )
	aColumns[len(aColumns)]:SetEdit( .T. )
	aColumns[len(aColumns)]:SetReadVar( 'aRowsCab[oBrwCpoCab:At()][4]' )

	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( "Origem(SA2/SC7/FOR)" )
	aColumns[len(aColumns)]:SetSize( 20 )
	aColumns[len(aColumns)]:SetType( 'C' )
	aColumns[len(aColumns)]:SetPicture( '@!' )
	aColumns[len(aColumns)]:SetData( {|| aRowsCab[oBrwCpoCab:At()][5] } )
	aColumns[len(aColumns)]:SetEdit( .T. )
	aColumns[len(aColumns)]:SetReadVar( 'aRowsCab[oBrwCpoCab:At()][5]' )
	aColumns[len(aColumns)]:SetOptions( aOriCab )
	aColumns[len(aColumns)]:SetValid( {|| sincDadCab() } )

	aAdd( aColumns, FWBrwColumn():New() )
	oColDadCab := aColumns[len(aColumns)]
	oColDadCab:SetTitle( "Dado (duplo-clique escolhe)" )
	oColDadCab:SetSize( 24 )
	oColDadCab:SetType( 'C' )
	oColDadCab:SetPicture( '@!' )
	oColDadCab:SetData( {|| aRowsCab[oBrwCpoCab:At()][6] } )
	oColDadCab:SetEdit( .T. )
	oColDadCab:SetReadVar( 'aRowsCab[oBrwCpoCab:At()][6]' )
	oColDadCab:SetOptions( lstCpoMul( { "SA2", "SC7" } ) )

	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( "Formula" )
	aColumns[len(aColumns)]:SetSize( 5 )
	aColumns[len(aColumns)]:SetType( 'C' )
	aColumns[len(aColumns)]:SetPicture( '@!' )
	aColumns[len(aColumns)]:SetData( {|| aRowsCab[oBrwCpoCab:At()][7] } )
	aColumns[len(aColumns)]:SetEdit( .T. )
	aColumns[len(aColumns)]:SetReadVar( 'aRowsCab[oBrwCpoCab:At()][7]' )
	aColumns[len(aColumns)]:xF3 := "SM4"

	oBrwCpoCab := FWBrowse():New( oParent )
	oBrwCpoCab:SetDataArray()
	oBrwCpoCab:SetArray( aRowsCab )
	oBrwCpoCab:DisableConfig()
	oBrwCpoCab:DisableReport()
	oBrwCpoCab:SetColumns( aColumns )
	oBrwCpoCab:SetEditCell( .T., {|| .T. } )
	oBrwCpoCab:SetInsert( .T. )
	oBrwCpoCab:SetDelete( .T., {|| delCab() } )
	oBrwCpoCab:SetDelOK( {|| Len( aRowsCab ) > 1 } )
	oBrwCpoCab:bChange := {|| chgCab() }
	oBrwCpoCab:SetDoubleClick( {|| aRowsCab[oBrwCpoCab:At()][6] := escCampo( aRowsCab[oBrwCpoCab:At()][5] ),;
								oBrwCpoCab:Refresh( .T. ), oBrwCpoCab:UpdateBrowse() } )
	oBrwCpoCab:Activate()

return Nil

/*/{Protheus.doc} chgCab
Evento de troca de linha selecionada na grid direita (campos do cabecalho): sincroniza a edicao
de volta para aLinhas (quando ja existe ao menos uma linha selecionada) e atualiza as opcoes da
coluna "Dado" conforme a Origem do campo agora selecionado (ver sincDadCab()).
@type function
@version 1.0
@author Visualize - Software e Inovacao
@since 30/07/2026
/*/
static function chgCab()

	local nAt := oBrwLin:At() as numeric

	if len( aLinhas ) > 0 .and. nAt > 0 .and. nAt <= len( aLinhas )
		aLinhas[nAt][3] := aClone( aRowsCab )
	endif

	sincDadCab()

return Nil

/*/{Protheus.doc} sincDadCab
Atualiza o SetOptions da coluna "Dado" da grid de campos do cabecalho para exibir apenas os campos
da tabela informada na coluna "Origem" do campo atualmente selecionado - disparado tanto ao editar
a Origem (SetValid) quanto ao trocar de linha selecionada (bChange, via chgCab()).
@type function
@version 1.0
@author Visualize - Software e Inovacao
@since 04/08/2026
@return logical, .T. (sempre aceita a edicao da Origem)
/*/
static function sincDadCab()

	local cOri as character

	if ValType( oColDadCab ) != 'O' .or. len( aRowsCab ) == 0 .or. oBrwCpoCab:At() <= 0
		return .T.
	endif

	cOri := stripCbo( aRowsCab[oBrwCpoCab:At()][5] )

	if cOri $ "SA2|SC7"
		oColDadCab:SetOptions( lstCpoDic( cOri ) )
	else
		oColDadCab:SetOptions( {} )
	endif

return .T.

/*/{Protheus.doc} delCab
Exclui o campo atualmente selecionado na grid de campos do cabecalho (callback de SetDelete).
Bloqueia a exclusao quando so resta um campo (cada linha do cabecalho precisa de ao menos um).
@type function
@version 1.0
@author Visualize - Software e Inovacao
@since 30/07/2026
@return logical, .T. se excluiu
/*/
static function delCab()

	local nAt := oBrwCpoCab:At() as numeric

	if len( aRowsCab ) <= 1 .or. nAt <= 0 .or. nAt > len( aRowsCab )
		return .F.
	endif

	aDel( aRowsCab, nAt )
	aSize( aRowsCab, len( aRowsCab ) - 1 )
	renumSeq( aRowsCab )

	oBrwCpoCab:SetArray( aRowsCab )
	oBrwCpoCab:Refresh( .T. )
	oBrwCpoCab:UpdateBrowse()
	chgCab()

return .T.

/*/{Protheus.doc} monGrdIte
Monta a grid editavel dos campos da grade de itens (janela inferior): Sequencia, Label, Tamanho,
Origem, Dado, Formula, Alinhamento. Insercao/exclusao de linha habilitadas via SetInsert/SetDelete
(substitui a antiga coluna "Opcional" - todo campo agora e tratado como opcional na impressao, ver
monCfgFim()).
@type function
@version 1.0
@author Visualize - Software e Inovacao
@since 30/07/2026
@param oParent, object, painel onde a grid sera desenhada
/*/
static function monGrdIte( oParent )

	local aColumns := {} as array
	local aOriIte  := { "SA2=Fornecedor", "SC7=Pedido de Compra", "SB1=Produto", "SB5=Dados Adicionais do Produto", "FOR=Formula" } as array
	local aAlinIte := { "LEFT=Esquerda", "RIGHT=Direita", "CENTER=Centro" } as array

	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( "Seq." )
	aColumns[len(aColumns)]:SetSize( 5 )
	aColumns[len(aColumns)]:SetType( 'N' )
	aColumns[len(aColumns)]:SetPicture( '@E 99' )
	aColumns[len(aColumns)]:SetData( {|| aItens[oBrwIte:At()][1] } )

	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( "Label" )
	aColumns[len(aColumns)]:SetSize( 16 )
	aColumns[len(aColumns)]:SetType( 'C' )
	aColumns[len(aColumns)]:SetPicture( '@!' )
	aColumns[len(aColumns)]:SetData( {|| aItens[oBrwIte:At()][2] } )
	aColumns[len(aColumns)]:SetEdit( .T. )
	aColumns[len(aColumns)]:SetReadVar( 'aItens[oBrwIte:At()][2]' )

	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( "Tam.(%)" )
	aColumns[len(aColumns)]:SetSize( 8 )
	aColumns[len(aColumns)]:SetType( 'N' )
	aColumns[len(aColumns)]:SetPicture( '@E 999' )
	aColumns[len(aColumns)]:SetData( {|| aItens[oBrwIte:At()][3] } )
	aColumns[len(aColumns)]:SetEdit( .T. )
	aColumns[len(aColumns)]:SetReadVar( 'aItens[oBrwIte:At()][3]' )

	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( "Origem(SA2/SC7/SB1/SB5/FOR)" )
	aColumns[len(aColumns)]:SetSize( 24 )
	aColumns[len(aColumns)]:SetType( 'C' )
	aColumns[len(aColumns)]:SetPicture( '@!' )
	aColumns[len(aColumns)]:SetData( {|| aItens[oBrwIte:At()][4] } )
	aColumns[len(aColumns)]:SetEdit( .T. )
	aColumns[len(aColumns)]:SetReadVar( 'aItens[oBrwIte:At()][4]' )
	aColumns[len(aColumns)]:SetOptions( aOriIte )
	aColumns[len(aColumns)]:SetValid( {|| sincDadIte() } )

	aAdd( aColumns, FWBrwColumn():New() )
	oColDadIte := aColumns[len(aColumns)]
	oColDadIte:SetTitle( "Dado (duplo-clique escolhe)" )
	oColDadIte:SetSize( 24 )
	oColDadIte:SetType( 'C' )
	oColDadIte:SetPicture( '@!' )
	oColDadIte:SetData( {|| aItens[oBrwIte:At()][5] } )
	oColDadIte:SetEdit( .T. )
	oColDadIte:SetReadVar( 'aItens[oBrwIte:At()][5]' )
	oColDadIte:SetOptions( lstCpoMul( { "SA2", "SC7", "SB1", "SB5" } ) )

	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( "Formula" )
	aColumns[len(aColumns)]:SetSize( 5 )
	aColumns[len(aColumns)]:SetType( 'C' )
	aColumns[len(aColumns)]:SetPicture( '@!' )
	aColumns[len(aColumns)]:SetData( {|| aItens[oBrwIte:At()][6] } )
	aColumns[len(aColumns)]:SetEdit( .T. )
	aColumns[len(aColumns)]:SetReadVar( 'aItens[oBrwIte:At()][6]' )
	aColumns[len(aColumns)]:xF3 := "SM4"

	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( "Alinhamento(LEFT/RIGHT/CENTER)" )
	aColumns[len(aColumns)]:SetSize( 16 )
	aColumns[len(aColumns)]:SetType( 'C' )
	aColumns[len(aColumns)]:SetPicture( '@!' )
	aColumns[len(aColumns)]:SetData( {|| aItens[oBrwIte:At()][7] } )
	aColumns[len(aColumns)]:SetEdit( .T. )
	aColumns[len(aColumns)]:SetReadVar( 'aItens[oBrwIte:At()][7]' )
	aColumns[len(aColumns)]:SetOptions( aAlinIte )

	oBrwIte := FWBrowse():New( oParent )
	oBrwIte:SetDataArray()
	oBrwIte:SetArray( aItens )
	oBrwIte:DisableConfig()
	oBrwIte:DisableReport()
	oBrwIte:SetColumns( aColumns )
	oBrwIte:SetEditCell( .T., {|| .T. } )
	oBrwIte:SetInsert( .T. )
	oBrwIte:SetDelete( .T., {|| delIte() } )
	oBrwIte:SetDelOK( {|| Len( aItens ) > 1 } )
	oBrwIte:bChange := {|| renumSeq( aItens ), sincDadIte() }
	oBrwIte:SetDoubleClick( {|| aItens[oBrwIte:At()][5] := escCampo( aItens[oBrwIte:At()][4] ),;
							 oBrwIte:Refresh( .T. ), oBrwIte:UpdateBrowse() } )
	oBrwIte:Activate()

return Nil

/*/{Protheus.doc} delIte
Exclui o campo atualmente selecionado na grid de itens (callback de SetDelete). Bloqueia a
exclusao quando so resta um campo (a grade de itens precisa de ao menos um campo configurado).
@type function
@version 1.0
@author Visualize - Software e Inovacao
@since 30/07/2026
@return logical, .T. se excluiu
/*/
static function delIte()

	local nAt := oBrwIte:At() as numeric

	if len( aItens ) <= 1 .or. nAt <= 0 .or. nAt > len( aItens )
		return .F.
	endif

	aDel( aItens, nAt )
	aSize( aItens, len( aItens ) - 1 )
	renumSeq( aItens )

	oBrwIte:SetArray( aItens )
	oBrwIte:Refresh( .T. )
	oBrwIte:UpdateBrowse()

return .T.

/*/{Protheus.doc} sincDadIte
Atualiza o SetOptions da coluna "Dado" da grid de itens para exibir apenas os campos da tabela
informada na coluna "Origem" do item atualmente selecionado - disparado tanto ao editar a Origem
(SetValid) quanto ao trocar de linha selecionada (bChange).
@type function
@version 1.0
@author Visualize - Software e Inovacao
@since 04/08/2026
@return logical, .T. (sempre aceita a edicao da Origem)
/*/
static function sincDadIte()

	local cOri as character

	if ValType( oColDadIte ) != 'O' .or. len( aItens ) == 0 .or. oBrwIte:At() <= 0
		return .T.
	endif

	cOri := stripCbo( aItens[oBrwIte:At()][4] )

	if cOri $ "SA2|SC7|SB1|SB5"
		oColDadIte:SetOptions( lstCpoDic( cOri ) )
	else
		oColDadIte:SetOptions( {} )
	endif

return .T.

/*/{Protheus.doc} escCampo
Abre uma lista de selecao (mesmo padrao ja usado em JSMANTAG.prw/getRes) com os campos existentes
no dicionario da tabela informada (SA2/SC7/SB1/SB5), lidos dinamicamente via DBStruct()+SX3 - nao
depende de uma lista fixa por tabela, entao se adapta ao dicionario real de cada ambiente.
@type function
@version 1.0
@author Visualize - Software e Inovacao
@since 30/07/2026
@param cOrigemAtual, character, valor atual da coluna "Origem" da linha (ex.: "SA2", "SC7", "FOR")
@return character, cCampo escolhido (ou o valor atual, se nao escolher nada)
/*/
static function escCampo( cOrigemAtual )

	local cAlias    := AllTrim( StrTokArr( cOrigemAtual, "=" )[1] )
	local cCampo    := "" as character
	local aOpcoes   := {} as array
	local oDlgSel   as object
	local aColumns  := {} as array

	Private oBrwSel as object

	if cAlias == 'FOR' .or. Empty( cAlias )
		Hlp( 'ORIGEM_FOR',;
			 'Origem "Formula" nao usa campo de tabela',;
			 'Preencha diretamente o codigo da formula na coluna "Formula".' )
		return cCampo
	endif

	if Select( cAlias ) == 0 .and. ! ( cAlias $ "SA2|SC7|SB1|SB5" )
		Hlp( 'TABELA_INDISPONIVEL',;
			 'A tabela '+ cAlias +' nao esta disponivel neste ambiente',;
			 'Verifique se essa tabela existe no dicionario de dados antes de escolher campos dela.' )
		return cCampo
	endif

	aOpcoes := lstCpoDic( cAlias )
	if len( aOpcoes ) == 0
		Hlp( 'SEM_CAMPOS', 'Nenhum campo encontrado para '+ cAlias, 'Verifique o dicionario de dados.' )
		return cCampo
	endif

	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( 'Campo' )
	aColumns[len(aColumns)]:SetSize( 40 )
	aColumns[len(aColumns)]:SetType( 'C' )
	aColumns[len(aColumns)]:SetData( {|| aOpcoes[oBrwSel:At()] } )

	oDlgSel := TDialog():New( 0, 0, 300, 400, 'Selecione o campo de '+ cAlias,,,,,CLR_BLACK,CLR_WHITE,,,.T. )
	oBrwSel := FWBrowse():New( oDlgSel )
	oBrwSel:SetDataArray()
	oBrwSel:SetArray( aOpcoes )
	oBrwSel:DisableConfig()
	oBrwSel:DisableReport()
	oBrwSel:SetColumns( aColumns )
	oBrwSel:SetDoubleClick( {|| cCampo := AllTrim( StrTokArr( aOpcoes[oBrwSel:At()], "=" )[1] ), oDlgSel:End() } )
	oBrwSel:Activate()
	oDlgSel:Activate(,,,.T.)

	if Empty( cCampo )
		cCampo := ""
	endif

return cCampo

/*/{Protheus.doc} lstCpoDic
Le a estrutura real (DBStruct) do alias informado e devolve a lista de campos no formato
"CAMPO=Titulo", na mesma linha ja usada em headerSD1() (GMPAICOM.prw) - evita depender de uma lista
fixa de campos por tabela, entao funciona igual para SA2/SC7/SB1/SB5 sem manutencao adicional.
@type function
@version 1.0
@author Visualize - Software e Inovacao
@since 30/07/2026
@param cAlias, character, alias da tabela (SA2/SC7/SB1/SB5)
@return array, aOpcoes
/*/
static function lstCpoDic( cAlias )

	local aOpcoes := {} as array
	local aStruct := {} as array
	local nX      := 0 as numeric
	local lAbriu  := .F. as logical

	if Select( cAlias ) == 0
		lAbriu := .T.
		DBSelectArea( cAlias )
	endif

	aStruct := ( cAlias )->( DBStruct() )
	for nX := 1 to len( aStruct )
		if X3Uso( GetSX3Cache( aStruct[nX][1], "X3_USADO" ) )
			aAdd( aOpcoes, AllTrim( aStruct[nX][1] ) +"="+ AllTrim( GetSX3Cache( aStruct[nX][1], 'X3_TITULO' ) ) )
		endif
	next nX

return aOpcoes

/*/{Protheus.doc} lstCpoMul
Concatena a lista de campos (formato "CAMPO=Titulo") de varias tabelas em uma unica lista, usada
para popular o SetOptions da coluna "Dado" (que pode vir de qualquer uma das tabelas aceitas pela
coluna "Origem" correspondente).
@type function
@version 1.0
@author Visualize - Software e Inovacao
@since 30/07/2026
@param aAlias, array, lista de alias a combinar (ex.: {"SA2","SC7"})
@return array, aOpcoes combinado
/*/
static function lstCpoMul( aAlias )

	local aOpcoes  := {} as array
	local aParcial as array
	local nX as numeric
	local nY as numeric

	for nX := 1 to len( aAlias )
		aParcial := lstCpoDic( aAlias[nX] )
		for nY := 1 to len( aParcial )
			aAdd( aOpcoes, aParcial[nY] )
		next nY
	next nX

return aOpcoes

/*/{Protheus.doc} valEGrava
Valida a configuracao (somas de percentual = 100% por linha/bloco de itens, coerencia
Origem/Dado/Formula) e, se valida, grava /gmpaicom/jsrlpdco.conf via toJsonFile(), no mesmo padrao
ja usado pelo painel para preferencias do usuario.
@type function
@version 1.0
@author Visualize - Software e Inovacao
@since 30/07/2026
@return logical, lSuccess
/*/
static function valEGrava()

	local lSuccess := .F. as logical
	local nX       := 0 as numeric
	local nY       := 0 as numeric
	local nSoma    := 0 as numeric
	local oCfg     as object
	local cResult  := Nil

	// Garante que a linha/campos exibidos no momento estao refletidos em aLinhas (aItens ja e o
	// proprio array usado pelo FWBrowse, nao precisa de sincronismo)
	if len( aLinhas ) > 0 .and. oBrwLin:At() > 0
		aLinhas[oBrwLin:At()][3] := aClone( aRowsCab )
	endif

	// (a) Soma de percentuais = 100% em cada linha do cabecalho
	for nX := 1 to len( aLinhas )
		nSoma := 0
		for nY := 1 to len( aLinhas[nX][3] )
			nSoma += aLinhas[nX][3][nY][3] + aLinhas[nX][3][nY][4]
		next nY
		if nSoma != 100
			Hlp( 'SOMA_INVALIDA',;
				 'A linha '+ cValToChar( nX ) +' do cabecalho soma '+ cValToChar( nSoma ) +'%, mas precisa somar exatamente 100%',;
				 'Ajuste os tamanhos de rotulo/dado dos campos dessa linha e tente novamente.' )
			return lSuccess
		endif
		// (b) Coerencia Origem/Dado/Formula em cada campo do cabecalho
		for nY := 1 to len( aLinhas[nX][3] )
			if ! chkCoer( aLinhas[nX][3][nY][5], aLinhas[nX][3][nY][6], aLinhas[nX][3][nY][7] )
				return lSuccess
			endif
		next nY
	next nX

	// (c) Soma de percentuais = 100% na grade de itens
	nSoma := 0
	for nX := 1 to len( aItens )
		nSoma += aItens[nX][3]
	next nX
	if nSoma != 100
		Hlp( 'SOMA_INVALIDA_ITENS',;
			 'Os campos de itens somam '+ cValToChar( nSoma ) +'%, mas precisam somar exatamente 100%',;
			 'Ajuste os tamanhos dos campos de itens e tente novamente.' )
		return lSuccess
	endif

	// (d) Coerencia Origem/Dado/Formula em cada campo de itens
	for nX := 1 to len( aItens )
		if ! chkCoer( aItens[nX][4], aItens[nX][5], aItens[nX][6] )
			return lSuccess
		endif
	next nX

	oCfg := monCfgFim()
	cResult := oCfg:toJsonFile( U_JSPATHSV(3) )
	lSuccess := ValType( cResult ) != 'C'
	if ! lSuccess
		Hlp( 'FALHA_GRAVAR', 'Nao foi possivel gravar a configuracao', 'Falha: '+ cResult )
	endif

return lSuccess

/*/{Protheus.doc} chkCoer
Confere a coerencia de um campo: se Origem for uma tabela, "Dado" e obrigatorio; se Origem=FOR,
"Formula" e obrigatoria e precisa existir no Cadastro de Formulas (SM4, validado via ExistCpo).
@type function
@version 1.0
@author Visualize - Software e Inovacao
@since 30/07/2026
@param cOrigem, character, origem do campo (com ou sem a descricao apos o "=")
@param cDado, character, campo informado
@param cFormula, character, codigo da formula informado
@return logical, lOk
/*/
static function chkCoer( cOrigem, cDado, cFormula )

	local lOk := .T. as logical
	local cOri := AllTrim( StrTokArr( cOrigem, "=" )[1] )

	if cOri == 'FOR'
		if Empty( cFormula )
			Hlp( 'FORMULA_OBRIGATORIA', 'Origem "Formula" exige o codigo da formula preenchido', 'Preencha o codigo (Configurador > Formulas) ou troque a Origem.' )
			lOk := .F.
		elseif ! ExistCpo( 'SM4', cFormula )
			Hlp( 'FORMULA_INEXISTENTE', 'O codigo de formula "'+ AllTrim(cFormula) +'" nao foi encontrado no Cadastro de Formulas', 'Cadastre a formula no Configurador (SM4) antes de usa-la aqui.' )
			lOk := .F.
		endif
	else
		if Empty( cDado )
			Hlp( 'DADO_OBRIGATORIO', 'Quando a Origem e uma tabela, o campo "Dado" e obrigatorio', 'Preencha o campo (F3 para escolher) ou troque a Origem para "Formula".' )
			lOk := .F.
		endif
	endif

return lOk

/*/{Protheus.doc} monCfgFim
Monta o JsonObject final a partir dos arrays de trabalho (aLinhas/aItens), pronto para gravacao.
@type function
@version 1.0
@author Visualize - Software e Inovacao
@since 30/07/2026
@return object, oCfg
/*/
static function monCfgFim()

	local oCfg  := JsonObject():New()
	local oCab  := JsonObject():New()
	local oIte  := JsonObject():New()
	local aLin  := {}
	local aCpo  := {}
	local nX as numeric
	local nY as numeric
	local oLinha as object
	local oCampo as object

	for nX := 1 to len( aLinhas )
		oLinha := JsonObject():New()
		oLinha['altura_cm'] := aLinhas[nX][2]
		aCpo := {}
		for nY := 1 to len( aLinhas[nX][3] )
			oCampo := JsonObject():New()
			oCampo['label']          := AllTrim( aLinhas[nX][3][nY][2] )
			oCampo['tamanho_rotulo'] := aLinhas[nX][3][nY][3]
			oCampo['tamanho_dado']   := aLinhas[nX][3][nY][4]
			oCampo['origem']         := stripCbo( aLinhas[nX][3][nY][5] )
			oCampo['dado']           := stripCbo( aLinhas[nX][3][nY][6] )
			oCampo['formula']        := AllTrim( aLinhas[nX][3][nY][7] )
			aAdd( aCpo, oCampo )
		next nY
		oLinha['campos'] := aCpo
		aAdd( aLin, oLinha )
	next nX
	oCab['linhas'] := aLin
	oCfg['cabecalho'] := oCab

	aCpo := {}
	for nX := 1 to len( aItens )
		oCampo := JsonObject():New()
		oCampo['label']       := AllTrim( aItens[nX][2] )
		oCampo['tamanho']     := aItens[nX][3]
		oCampo['origem']      := stripCbo( aItens[nX][4] )
		oCampo['dado']        := stripCbo( aItens[nX][5] )
		oCampo['formula']     := AllTrim( aItens[nX][6] )
		oCampo['alinhamento'] := stripCbo( aItens[nX][7] )
		// Toda a grade de itens agora e tratada como opcional (ver monGrdIte) - se o campo do
		// dicionario nao existir no ambiente, o relatorio redistribui a largura graciosamente
		oCampo['opcional']    := .T.
		aAdd( aCpo, oCampo )
	next nX
	oIte['campos'] := aCpo
	oCfg['itens'] := oIte

return oCfg
