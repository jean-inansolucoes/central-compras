#include 'totvs.ch'
#include 'topconn.ch'
#include 'hbutton.ch'
#include 'rwmake.ch'
#include 'tbiconn.ch'
#include 'tbicode.ch'
#include 'style.ch'
#include 'matr110.ch'							// Include padrão do relatório de pedido de compra

#define CEOL CHR( 13 ) + CHR( 10 )				// ENTER
#define NESP 2									// ESPAÇO EM MM ENTRE OS OBJETOS NA TELA
#define NPERCSUP 310/MsAdvSize()[6]				// Percentual da tela que a área superior deve ocupar (cáculo para tonar o tamanho fixo)
#define CCARCOM "carrinho.bmp"					// IMAGEM REFERENTE AO CARRINHO DE COMPRAS EXIBIDO NA ROTINA
#define CWHITE  "white.bmp"						// IMAGEM EM BRANCO PARA CARREGAR QUANDO CARRINHO ESTIVER SEM ITENS
#define CSUBIMG "images"						// DIRETORIO ONDE
#define CSUBLOG "logs"							// DIRETORIO DE GRAVACAO DOS LOGS DE EXECUÇÕES DA ROTINA
#define CIMGMRK "LBOK"							// BITMAP PARA INDICAR QUE A LINHA ESTÁ SELECIONADA
#define CIMGNOMRK "LBNO"						// BITMAP PARA INDICAR QUE O REGISTRO ESTÁ DESMARCARDO
#define CLOOKUPICON "FWSKIN_ICON_LOOKUP.PNG"	// icone de pesquisa
#define CIMGNOT "notificacao.png"				// IMAGEM PARA EXIBIÇÃO DE NOTIFICAÇÕES                    
#define CSEPARA "|"								// CARACTERE UTILIZADO COMO SEPARADOR DO CONTEUDO DA FORMULA
#define DIAS_LT_FOR 365							// Quantidade de dias para análise do prazo médio de entrega do produto para o fornecedor padrão
#define CBTNSTYLE btnStyle()					// Estilo CSS para os botões da aplicação
#define LG_CRITICO "BR_VERMELHO"				// Legenda de itens críticos
#define LG_ALTO    "BR_LARANJA"					// Legenda de itens de alto giro
#define LG_MEDIO   "BR_AMARELO"					// Legenda para itens de giro mediano
#define LG_BAIXO   "BR_CINZA"					// Legenda para itens de baixo giro
#define LG_SEMGIRO "BR_BRANCO"					// Legenda para itens considerados sem giro
#define LG_SOLICIT "BR_VIOLETA"					// Legenda para itens obtidos por solicitação
 
/*/{Protheus.doc} GMPAICOM
Rotina para gestão de compras, elaboração inteligente de pedidos e acompanhamento de carteira de fornecedores
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 7/9/2019
/*/
User Function GMPAICOM()
                       
	Local oCboAna as object
	// Local oFndFor as object
	local oFndPrd as object
	Local oFntTxt := TFont():New("Tahoma",,015,,.F.,,,,,.F.,.T.)
	Local oFntCbo := TFont():New("Arial",,014,,.F.,,,,,.F.,.F.)
	Local oGetQtd
	Local oWinDash
	local oWinPro
	Local oWinPar
	Local oGrpPro
	Local oLblPrj
	Local aSize    := MsAdvSize()
	Local nVer     := aSize[06]/2
	Local nHor     := aSize[05]/2
	Local aCboAna  := {"1=Diário","2=Semanal","3=Mensal"}
	Local aCabFor  := {}															// Cabeçalho do browse do grid de fornecedores
	Local aStrFor  := {} 
	Local oGir001, oGir002, oGir003, oGir004, oGir005/* , oGir006 */ := Nil
	Local aHeaPro  := {}
	local aFields  := {"B1_COD","B1_DESC","B1_UM","NECCOMP","QTDBLOQ","PRCNEGOC","ULTPRECO","CONSMED","DURACAO","DURAPRV","ESTOQUE","EMPENHO","QTDCOMP","LEADTIME","TPLDTIME","PREVENT","B1_LM","B1_QE","B1_LE","B1_EMIN","B1_PROC","B1_LOJPROC"} 
	Local aAlter   := {"NECCOMP","QTDBLOQ","PRCNEGOC","B1_LM", "B1_QE", "B1_LE", "B1_PROC", "B1_UM", "LEADTIME", "B1_DESC", "B1_EMIN" }
	Local oPanAna  := Nil
	local oAliFor  as object
	local oLayer   as object
	Local oGroup1  as object
	local oWinFor  as object
	local oLblPer  as object
	local bok      := {|| procCar(), oDlgCom:End() }
	local bCancel  := {|| iif( closeVld(), oDlgCom:End(), Nil ) }
	local aButtons := {} as array
	local oBmpCri, oBmpAlt, oBmpMed, oBmpBai, oBmpSem/* , oBmpSol */ := nil
	local oRadMenu as object
	local aRadMenu := { "Todos os produtos", "Apenas sugestões de compra", "Apenas risco de ruptura" }
	local oBtnFil  as object
	local cLastRun := "" as character
	local oLine    as object
	local cFileWF  := "" as character
	
	Private _cFilPrd  := "" as character
	Private _aTypes   := {} as array
	Private nRadMenu  := 1 as numeric
	Private cFormula  := AllTrim( SuperGetMv( 'MV_X_PNC01',,"" ) )			// Formula de cálculo da necessidade de compra
	Private cZB6      := AllTrim( SuperGetMv( 'MV_X_PNC04',,"" ) )			// Alias da tabela ZB6 no ambiente do cliente
	Private cZB3      := AllTrim( SuperGetMv( 'MV_X_PNC02',,"" ) )			// Alias da tabela ZB3 no ambiente do cliente	
	Private cMarca    := GetMark()
	Private oLblDia   := Nil
	Private nGetQtd   := 0
	Private cCboAna   := '1' 
	Private cCboExi   := 'Z..A'
	Private cCboOrd   := ""
	Private oDias     := Nil
	Private aCarCom   := {}															// Dados dos produtos no carrinho de compras
	Private cMark     := GetMark()
	Private lGir001   := lGir002 := lGir003 := lGir004 := lGir005 := /* lGir006 := */ .T.
	Private oDlgCom   := Nil
	Private oBrwFor   := Nil
	Private aColPro   := {}
	Private oBrwPro   := Nil
	Private aSelFor   := {}															// Fornecedores com check-box marcado
	Private nPosPrd   := 0
	Private nPosDes   := 0
	Private nPosLtM   := 0 
	Private nPosUnM   := 0 
	Private nPosChk   := 0
	Private nPosFor   := 0
	Private nPosLoj   := 0
	Private nPosBlq   := 0
	Private nPosNec   := 0
	Private nPosNeg   := 0
	Private nPosUlt   := 0
	Private nPosCon   := 0 
	Private nPosDur   := 0 
	Private nPosEmE   := 0 
	Private nPosVen   := 0 
	Private nPosQtd   := 0 
	Private nPosLdT   := 0 
	Private nPosTLT   := 0 as numeric
	Private nPosPrv   := 0
	Private aConfig   := {}															// Guarda configurações da rotina para uso durante a execução
	Private nSpinBx   := 0
	Private nPosInc   := 0 as numeric
	Private oLblAna   := Nil
	Private oDash     := Nil
	Private aEvePen   := {}															// Vetor para guardar eventos pendentes de serem resolvidos
	Private nPosQtE   := 0 as numeric				
	Private nPosLtE   := 0 as numeric
	Private nMVPNC11  := SuperGetMv( 'MV_X_PNC11',,1 )					// Tipo de Análise (1=Pelo Fornecedor Padrão ou 2=Pelo Produto)
	Private _aFil     := { cFilAnt } as array
	Private _aProdFil := {} as array
	Private _aFilters := { Space(200),;
						   Space(200),; 
						   Space(TAMSX3('B1_PROC')[1]) }
	Private lCrescente := .T. as logical
	Private nLastCol   := 0 as numeric 
	Private aMrkFor    := {} as array
	Private aFullPro   := {} as array

	// Variáveis para o relatório referente ao pedido de compra
	Private cPicA2_CEP	:= PesqPict("SA2","A2_CEP")
	Private cPicA2_CGC	:= PesqPict("SA2","A2_CGC")
	Private cUserId   	:= RetCodUsr()
	Private lLGPD		:= FindFunction("SuprLGPD") .And. SuprLGPD()								 
	Private aStru	    := FWFormStruct(3,"SC7")[1]

	// Valida existência do parâmetro de definição de alias da tabela de notificações
	if ! GetMv( 'MV_X_PNC02', .T. ) .or. Empty( cZB3 )
		Hlp( 'MV_X_PNC02',;
			 'Parâmetro interno que define alias da tabela de notificações não definido ou não configurado!',;
			 'Acesse o módulo configurador e realize a configuração do parâmetro MV_X_PNC02' )
		return nil
	endif

	// Valida existência de parâmetro interno com alias das configurações globais
	if ! GetMv( 'MV_X_PNC03', .T. ) .or. Empty( GetMV( 'MV_X_PNC03' ) )
		Hlp( 'MV_X_PNC03',;
			 'Parâmetro interno que define alias da tabela de configurações globais da rotina não configurado ou inexistente!',;
			 'Acesse o módulo configurador e realize a configuração do parâmetro MV_X_PNC03' )
		return Nil
	endif

	//Checa configuração do alias da tabela de produtos a serem descontinuados.
	if ! GetMv( 'MV_X_PNC04', .T. ) .or. Empty( cZB6 )
		Hlp( 'MV_X_PNC04',;
			'Parâmetro interno que define alias da tabela de produtos descontinuados inexistente ou não configurado',;
			'Verifique e configure o parâmetro MV_X_PNC04 através do módulo configurador do sistema.')
		return Nil
	endif

	// Checa configuração de envio de e-mail para fornecedor
	if AllTrim( SuperGetMv( 'MV_ENVPED' ) ) $ "1|2"
		cFileWF := "/samples/wf/mata120_mail001.html"
		if !File( cFileWF )
			
			// Checa estrutura de diretórios antes de criar o arquivo
			if ! ExistDir( '/samples' )
				makeDir( '/samples' )
			endif
			if ! ExistDir( '/samples/wf' )
				makeDir( '/samples/wf' )
			endif

			// Tenta criar o arquivo base do workflow e já retorna se ele existe
			if ! writeWF( cFileWF )

				hlp( 'WF FORNECEDOR',;
					 'O arquivo base para disparo de e-Mail ao fornecedor não se encontra na pasta',;
					 'O arquivo '+ cFileWF +' é necessário para que o sistema consiga realizar o processamento sem falhas. '+;
					 'Providencie o arquivo, disponibilize-o no diretório e tente novamente, ou desabilite o envio de e-mail automático '+;
					 'através do parâmetro interno MV_ENVPED alterando seu conteúdo para 0 (zero)' )
				Return Nil
			endif
		endif
	endif
	
	// Define hotkeys da rotina
	SetKey( K_ALT_X, {|| fMarkPro() } )
	SetKey( VK_F5, {|| Processa( {|| fLoadInf() }, 'Aguarde!','Analisando dados do MRP...' ) } )
	SetKey( VK_F12, {|| fManPar() } )
	
	aStrFor := {}
	aAdd( aStrFor, { "MARK"      , "C", 02, 00 } )
	aAdd( aStrFor, { "B1_PROC"   , "C", TAMSX3( "B1_PROC"    )[01], TAMSX3( "B1_PROC"    )[02] } )
	aAdd( aStrFor, { "B1_LOJPROC", "C", TAMSX3( "B1_LOJPROC" )[01], TAMSX3( "B1_LOJPROC" )[02] } )
	aAdd( aStrFor, { "A2_NOME"   , "C", TAMSX3( "A2_NOME"    )[01], TAMSX3( "A2_NOME"    )[02] } )
	aAdd( aStrFor, { "A2_NREDUZ" , "C", TAMSX3( "A2_NREDUZ"  )[01], TAMSX3( "A2_NREDUZ"  )[02] } )
	aAdd( aStrFor, { "A2_EMAIL"  , "C", TAMSX3( "A2_EMAIL"   )[01], TAMSX3( "A2_EMAIL"   )[02] } )
	aAdd( aStrFor, { "LEADTIME"  , "N", 03, 00 } )
	aAdd( aStrFor, { "A2_X_LTIME", "N", 03, 00 } )
	aAdd( aStrFor, { "PEDIDO"    , "C", 01, 00 } )
	
	oAliFor := FWTemporaryTable():New( 'FORTMP', aStrFor )
	oAliFor:AddIndex( '01', {'A2_NOME'})
	oAliFor:AddIndex( '02', {'B1_PROC','B1_LOJPROC' } )
	oAliFor:Create()
	
	// Cabeçalho do grid que vai exibir os dados
	aCabFor := {}
	aAdd( aCabFor, { ' '           , &("{|| iif( Trim(FORTMP->PEDIDO) == 'S','"+ CCARCOM +"','"+ CWHITE+ "') }"), "C", "@BMP", 1, 1, 0, .F., {|| Nil }, .T. } )
	aAdd( aCabFor, { 'Razão Social', {|| Trim( FORTMP->A2_NOME    ) }, 'C', '@!', 1, 20, 00 } )
	aAdd( aCabFor, { 'Fantasia'    , {|| Trim( FORTMP->A2_NREDUZ  ) }, 'C', '@!', 1, 10, 00 } )
	aAdd( aCabFor, { 'L.T.(C)'     , {|| FORTMP->LEADTIME           }, 'N', '@E 999', 2, 03, 00 } )
	aAdd( aCabFor, { 'L.T.(I)'     , {|| RetField('SA2',1,FWxFilial("SA2") + FORTMP->B1_PROC + FORTMP->B1_LOJPROC, "A2_X_LTIME" )},;
		 'N', '@E 999', 2, 03, 00, .T. /* lCanEdit */, {|| A2LTMCHG() }, Nil, Nil, 'FORTMP->A2_X_LTIME' } )
	
	aHeaPro := getColPro( aFields, aAlter )							
	// Guarda o posicionamento dos campos para posteriormente utilizá-los ao longo do fonte
	nPosPrd := aScan( aFields, {|x| x == "B1_COD"     } ) 
	nPosDes := aScan( aFields, {|x| x == "B1_DESC"    } )
	nPosUnM := aScan( aFields, {|x| x == "B1_UM"      } )
	nPosLtM := aScan( aFields, {|x| x == "B1_LM"      } )
	nPosFor := aScan( aFields, {|x| x == "B1_PROC"    } )
	nPosLoj := aScan( aFields, {|x| x == "B1_LOJPROC" } )
	nPosNec := aScan( aFields, {|x| x == "NECCOMP"    } )
	nPosNeg := aScan( aFields, {|x| x == "PRCNEGOC"   } )
	nPosUlt := aScan( aFields, {|x| x == "ULTPRECO"   } )
	nPosCon := aScan( aFields, {|x| x == "CONSMED"    } )
	nPosDur := aScan( aFields, {|x| x == "DURACAO"    } )
	nPosDuP := aScan( aFields, {|x| x == "DURAPRV"    } )
	nPosEmE := aScan( aFields, {|x| x == "ESTOQUE"    } )
	nPosVen := aScan( aFields, {|x| x == "EMPENHO"    } ) 
	nPosQtd := aScan( aFields, {|x| x == "QTDCOMP"    } )
	nPosPrv := aScan( aFields, {|x| x == "PREVENT"    } )
	nPosLdT := aScan( aFields, {|x| x == "LEADTIME"   } )
	nPosTLT := aScan( aFields, {|x| x == "TPLDTIME"   } )		// Tipo do Lead-Time (C=Calculado P=Produto ou F=Fornecedor)
	nPosBlq := aScan( aFields, {|x| x == "QTDBLOQ"    } )
	nPosQtE := aScan( aFields, {|x| x == "B1_QE"      } )
	nPosLtE := aScan( aFields, {|x| x == "B1_LE"      } )
	nPosInc := len( aFields ) + 1
	nPosChk := len( aFields ) + 2
	
	// Realiza leitura das preferências da rotina
	Processa( {|| fLoadCfg() }, 'Aguarde!','Lendo configurações da rotina...' )
	if Len( aConfig ) == 0 
		MsgStop( 'Não foi possível prosseguir porque as configurações internas da rotina não puderam ser lidas ou ainda não foram cadastradas!','Parâmetro interno MV_X_PNC03' )
		Return ( Nil )
	EndIf
	
	// Inicializa variáveis do workspace
	nSpinBx := aConfig[01]			// Pré-definição dias de estoque
	lGir001 := aConfig[02]			// Pré-definição itens críticos
	lGir002 := aConfig[03]			// Pré-definição itens alto giro
	lGir003 := aConfig[04]			// Pré-definição itens médio giro
	lGir004 := aConfig[05]			// Pré-definição itens baixo giro
	lGir005 := aConfig[06]			// Pré-definições itens sem giro
	// lGir006 := aConfig[07]			// Pré-definições itens sob demanda
	cCboAna := aConfig[08]			// Pré-definições tipo de análise de sazonalidade
	nGetQtd := aConfig[09]			// Pré-definições da qtde de períodos analisados
	
	// Filtros de tipos de produtos "padrões" definidos nas configurações
	_aFilters[2] := PADR(aConfig[21],200,' ')		// pré-definições dos tipos de produtos a serem analisados

	// Botões da EnchoiceBar
	// aAdd( aButtons, { "BTNWARN"  , {|| fShowEv() }           , "Riscos de Ruptura" } )
	aAdd( aButtons, { "BMPMANUT" , {|| doFormul( cFormula ) }, "Formula de Cálculo" } )
	// aAdd( aButtons, { "BTNNOTIFY", {|| fShowEv( aColPro[ oBrwPro:nAt][nPosPrd] ) }, "Eventos do Produto" } )
	aAdd( aButtons, { "BTNEMPEN" , {|| iif( oBrwPro:nAt > 0, fShowEm( aColPro[ oBrwPro:nAt][nPosPrd] ), Nil ) }, "Empenhos do Produto" } )
	aAdd( aButtons, { "BTNPEDIDO", {|| iif( oBrwPro:nAt > 0, fPedFor(), Nil ) }, "Pedidos do Produto" } )
	aAdd( aButtons, { "BTNIMPORT", {|| impData() }           , "Importar Indices dos Produtos" } )
	aAdd( aButtons, { "BTNENTR"  , {|| iif( oBrwPro:nAt > 0, entryDocs( aColPro[ oBrwPro:nAt ][nPosPrd] ), Nil ) }, "Compras do Produto" } )
	aAdd( aButtons, { "BTNPAICFG", {|| internalParms() }     , "Parâmetros Internos" } )

	// Valida existência do parâmetro para que o sistema possa alimentar a data e hora da última execução do recálculo dos dados de produtos
	cLastRun := AllTrim( SuperGetMv( 'MV_X_PNC12',,"" ) )
	if ! GetMV( 'MV_X_PNC12', .T. /* lCheck */ )
		Hlp( 'MV_X_PNC12',;
			 'Parâmetro interno que armazena data da última execução do JOB de recálculo dos índices individuais dos produtos '+;
			 'não foi localiado no dicionário de dados!',;
			 'Faz-se necessária a execução do UPDDISTR com dicionário da rotina igual ou superior a 04.0001 de 16/10/2024' )

	elseif Empty( cLastRun ) .or. CtoD( SubStr( cLastRun, 1, 10 ) ) < (Date()-3) 
		Hlp( 'JOBLASTRUN',;
			 'A T E N Ç Ã O ! Foi constatado que o agendamento de recálculo dos índices individuais dos produtos '+;
			 iif( Empty( cLastRun ), 'nunca foi executado!', 'não é executado desde '+ cLastRun ) +'.',;
			 'Verifique juntamente com a equipe responsável pelo Protheus se o agendamento foi configurado corretamente pois a defasagem nos cálulos dos índices '+;
			 'pode gerar falhas no processo de análise de compras e, consequentemente, rupturas indesejadas de estoque.' )
	endif

	DEFINE MSDIALOG oDlgCom TITLE AllTrim( SM0->M0_FILIAL ) +" | Painel de Compra - "+ U_JSGETVER() FROM 000, 000  TO aSize[06], aSize[05] COLORS 0, 16777215 PIXEL
	
	// Group para separar a tela em duas partes na vertical
	@ 030, 000 GROUP oGroup1 TO nVer*NPERCSUP, nHor OF oDlgCom COLOR 0, 16777215 PIXEL
	@ nVer*NPERCSUP, 000 GROUP oGrpPro TO nVer, nHor OF oDlgCom COLOR 0, 16777215 PIXEL

	oLayer := FWLayer():New()
	oLayer:Init( oDlgCom )
	oLayer:AddLine( "line1", round((250/aSize[6])*100,0), .T. )
	oLayer:AddColumn( "colFor" , 40, .F., "line1" )
	oLayer:AddColumn( "colPar" , 30, .F., "line1" )
	oLayer:AddColumn( "colDash", 30, .F., "line1" )
	oLayer:AddWindow( 'colFor' , 'winFor' , 'Fornecedores', 100, .F., .F., /* {|| Nil } */, "line1")
	oLayer:AddWindow( 'colPar' , 'winPar' , 'Filtros e Parâmetros', 100, .F., .F., /* {|| Nil } */, "line1")
	oLayer:AddWindow( 'colDash', 'winDash', 'Gráfico do Produto', 100, .F., .F., /* {|| Nil } */, "line1")
	oWinFor  := oLayer:GetWinPanel( 'colFor' , 'winFor', "line1")
	oWinPar  := oLayer:GetWinPanel( 'colPar' , 'winPar', "line1")
	oWinDash := oLayer:GetWinPanel( 'colDash', 'winDash', "line1")
	
	oLayer:AddLine( "line2", 100-round((250/aSize[6])*100,0), .T. )
	oLayer:AddColumn( "colPro", 100, .F., "line2" )
	oLayer:AddWindow( 'colPro' , 'winPro' , 'Produtos', 100, .F., .F., /* {|| Nil } */, "line2")
	oWinPro  := oLayer:GetWinPanel( 'colPro' , 'winPro', "line2")
	oLine := oLayer:GetLinePanel( 'line2' )

	oBrwFor := FWBrowse():New( oWinFor )
	oBrwFor:SetDataTable()
	oBrwFor:SetAlias( 'FORTMP' )
	oBrwFor:AddMarkColumns( {|oBrwFor| if( FORTMP->MARK == cMarca, 'LBOK','LBNO' ) },;
							{|oBrwFor| fMark( 'FORTMP' /* cAlias */, .F. /*lAll*/, oBrwFor ) },;
							{|oBrwFor| fMark( 'FORTMP' /* cAlias */, .T. /*lAll*/, oBrwFor ) })
	oBrwFor:GetColumn(1):SetReadVar( 'FORTMP->MARK' )
	oBrwFor:SetDoubleClick( {|oBrwFor| fMark( 'FORTMP' /* cAlias */, .F. /*lAll*/, oBrwFor ) } )
	aEval( aCabFor, {|x| oBrwFor:AddColumn( aClone( x ) ) } )
	oBrwFor:GetColumn(2):bLDblClick := {|oBrwFor| iif( FORTMP->PEDIDO == 'S', fCarCom( FORTMP->B1_PROC, FORTMP->B1_LOJPROC ), Nil ) }
	oBrwFor:GetColumn(3):bLDblClick := {|oBrwFor| fMark( 'FORTMP', .F., oBrwFor ) }
	oBrwFor:GetColumn(4):bLDblClick := {|oBrwFor| fMark( 'FORTMP', .F., oBrwFor ) }
	oBrwFor:SetEditCell( .T. )
	oBrwFor:DisableConfig()
	oBrwFor:DisableReport()
	oBrwFor:SetLineHeight( 20 )
	oBrwFor:Activate()

	oBrwPro := FWBrowse():New( oWinPro )
	oBrwPro:SetDataArray()
	oBrwPro:SetArray( aColPro )
	oBrwPro:DisableReport()
	oBrwPro:DisableConfig()
	oBrwPro:AddLegend( "aColPro[oBrwPro:nAt]["+ cValToChar( nPosInc ) +"] >= "+ cValToChar( aConfig[10] ), LG_CRITICO, "Itens Criticos" )
	oBrwPro:AddLegend( "aColPro[oBrwPro:nAt]["+ cValToChar( nPosInc ) +"] < "+ cValToChar( aConfig[10] ) +" .and. "+;
					   "aColPro[oBrwPro:nAt]["+ cValToChar( nPosInc ) +"] >= "+ cValToChar( aConfig[11] ), LG_ALTO, "Alto Giro" )
	oBrwPro:AddLegend( "aColPro[oBrwPro:nAt]["+ cValToChar( nPosInc ) +"] < "+ cValToChar( aConfig[11] ) +" .and. "+;
					   "aColPro[oBrwPro:nAt]["+ cValToChar( nPosInc ) +"] >= "+ cValToChar( aConfig[12] ), LG_MEDIO, "Medio Giro" )
	oBrwPro:AddLegend( "aColPro[oBrwPro:nAt]["+ cValToChar( nPosInc ) +"] < "+ cValToChar( aConfig[12] ) +" .and. "+;
					   "aColPro[oBrwPro:nAt]["+ cValToChar( nPosInc ) +"] >= "+ cValToChar( aConfig[13] ), LG_BAIXO, "Baixo Giro" )
	oBrwPro:AddLegend( "aColPro[oBrwPro:nAt]["+ cValToChar( nPosInc ) +"] < "+ cValToChar( aConfig[13] ), LG_SEMGIRO, "Sem Giro" )
	oBrwPro:AddMarkColumn( {|| iif( aColPro[oBrwPro:nAt][nPosChk], "LBOK", "LBNO" ) }, {|| fMarkPro() }, {|| Nil } )
	oBrwPro:SetColumns( aHeaPro )
	oBrwPro:GetColumn(nPosFor+2):xF3 := "SA2"
	oBrwPro:SetEditCell( .T., {|| U_PCOMVLD() } )
	oBrwPro:SetLineHeight( 20 )
	oBrwPro:SetPreEditCell( {|oBrw,oCol,cPre| U_PCOMPRE(oBrw, oCol, cPre) } )
	oBrwPro:SetChange( {|| Processa( {|| iif( ValType( oDash ) == 'O', fLoadAna(), Nil ) }, 'Aguarde!', 'Analisando sazonalidade do produto...' ) } )
	oBrwPro:Activate()
	
	@ 12, 10 SAY oLblPrj PROMPT "Projeção de estoque para..." SIZE 080, 011 OF oWinPar FONT oFntTxt COLORS 8421504, 16777215 PIXEL
	oDias := tSpinBox():new( 10, 90, oWinPar, {|x| nSpinBx := x, Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' ) }, 28, 13)
    oDias:setRange( 1, 360 )
    oDias:setStep( 1 )
    oDias:setValue( nSpinBx )
	@ 12, 120 SAY oLblDia PROMPT "dias ( até "+ fRetDia( nSpinBx, .T. ) +" )" SIZE 080, 011 OF oWinPar FONT oFntTxt COLORS 8421504, 16777215 PIXEL
	
	oBmpCri := TBitmap():New(030, 010, 10, 10, LG_CRITICO /*cResName*/, /*cBmpFile*/, .T./*lNoBorder*/, oWinPar, /*bLClicked*/, /*bRClicked*/, /*lScroll*/, /*lStretch*/, /*oCursor*/, /*uParam14*/, /*uParam15*/, /*bWhen*/, .T./* lDimPixels */, /*bValid*/)
	oBmpAlt := TBitmap():New(040, 010, 10, 10, LG_ALTO    /*cResName*/, /*cBmpFile*/, .T./*lNoBorder*/, oWinPar, /*bLClicked*/, /*bRClicked*/, /*lScroll*/, /*lStretch*/, /*oCursor*/, /*uParam14*/, /*uParam15*/, /*bWhen*/, .T./* lDimPixels */, /*bValid*/)
	oBmpMed := TBitmap():New(050, 010, 10, 10, LG_MEDIO   /*cResName*/, /*cBmpFile*/, .T./*lNoBorder*/, oWinPar, /*bLClicked*/, /*bRClicked*/, /*lScroll*/, /*lStretch*/, /*oCursor*/, /*uParam14*/, /*uParam15*/, /*bWhen*/, .T./* lDimPixels */, /*bValid*/)
	oBmpBai := TBitmap():New(060, 010, 10, 10, LG_BAIXO   /*cResName*/, /*cBmpFile*/, .T./*lNoBorder*/, oWinPar, /*bLClicked*/, /*bRClicked*/, /*lScroll*/, /*lStretch*/, /*oCursor*/, /*uParam14*/, /*uParam15*/, /*bWhen*/, .T./* lDimPixels */, /*bValid*/)
	oBmpSem := TBitmap():New(070, 010, 10, 10, LG_SEMGIRO /*cResName*/, /*cBmpFile*/, .T./*lNoBorder*/, oWinPar, /*bLClicked*/, /*bRClicked*/, /*lScroll*/, /*lStretch*/, /*oCursor*/, /*uParam14*/, /*uParam15*/, /*bWhen*/, .T./* lDimPixels */, /*bValid*/)
	// oBmpSol := TBitmap():New(080, 010, 10, 10, LG_SOLICIT /*cResName*/, /*cBmpFile*/, .T./*lNoBorder*/, oWinPar, /*bLClicked*/, /*bRClicked*/, /*lScroll*/, /*lStretch*/, /*oCursor*/, /*uParam14*/, /*uParam15*/, /*bWhen*/, .T./* lDimPixels */, /*bValid*/)

	@ 30, 20 CHECKBOX oGir001 VAR lGir001 PROMPT "Críticos"     		SIZE 048, 008 OF oWinPar COLORS 8421504, 16777215 FONT oFntCbo ON CHANGE Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' ) PIXEL
	@ 40, 20 CHECKBOX oGir002 VAR lGir002 PROMPT "Alto Giro"    		SIZE 048, 008 OF oWinPar COLORS 8421504, 16777215 FONT oFntCbo ON CHANGE Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' ) PIXEL
	@ 50, 20 CHECKBOX oGir003 VAR lGir003 PROMPT "Médio Giro"   		SIZE 048, 008 OF oWinPar COLORS 8421504, 16777215 FONT oFntCbo ON CHANGE Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' ) PIXEL
	@ 60, 20 CHECKBOX oGir004 VAR lGir004 PROMPT "Baixo Giro"   		SIZE 048, 008 OF oWinPar COLORS 8421504, 16777215 FONT oFntCbo ON CHANGE Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' ) PIXEL
	@ 70, 20 CHECKBOX oGir005 VAR lGir005 PROMPT "Sem Giro"     		SIZE 048, 008 OF oWinPar COLORS 8421504, 16777215 FONT oFntCbo ON CHANGE Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' ) PIXEL
	// @ 80, 20 CHECKBOX oGir006 VAR lGir006 PROMPT "Por Solicitação"  	SIZE 048, 008 OF oWinPar COLORS 8421504, 16777215 FONT oFntCbo ON CHANGE Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' ) PIXEL
	
	oRadMenu := TRadMenu():New( 30, 70, aRadMenu,, oWinPar,,,,,,,,100,12,,,,.T.)
	oRadMenu:bSetGet := {|u| iif( pCount()==0, nRadMenu, nRadMenu := u ) }
	oRadMenu:bChange := {|| Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' ) }

	oBtnFil := TButton():New( 30, 170, "Filiais",oWinPar,{|| _aFil := userFil( _aFil ),;
							Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' ) }, (oWinPar:nWidth/2)*0.2,15,,,.F.,.T.,.F.,,.F.,,,.F. )
	// Botão de filtro de produto
	oFndPrd := TButton():New( 50, 170, "Produtos", oWinPar,{|| _aFilters := prodFilter( _aFilters ),;
															Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' ) }, (oWinPar:nWidth/2)*0.2,15,,,.F.,.T.,.F.,,.F.,,,.F. )

	@ 06, 04 SAY oLblPer PROMPT "Período: " SIZE (oWinDash:nWidth/2)*0.1, 011 OF oWinDash FONT oFntTxt COLORS 8421504, 16777215 PIXEL
	@ 04, 06+(oWinDash:nWidth/2)*0.1 MSCOMBOBOX oCboAna VAR cCboAna ITEMS aCboAna SIZE (oWinDash:nWidth/2)*0.4, 013 OF oWinDash COLORS 8421504, 16777215 FONT oFntCbo ON CHANGE Processa( {|| fLoadAna() }, 'Aguarde!', 'Analisando sazonalidade do produto...' ) PIXEL
	@ 04, 08+((oWinDash:nWidth/2)*0.5) MSGET oGetQtd VAR nGetQtd SIZE (oWinDash:nWidth/2)*0.1, 010 OF oWinDash PICTURE "@E 99" COLORS 8421504, 16777215 FONT oFntCbo ON CHANGE Processa( {|| fLoadAna() }, 'Aguarde!','Analisando sazonalidade do produto...' ) PIXEL
	@ 06, 10+((oWinDash:nWidth/2)*0.6) SAY oLblAna PROMPT "..." SIZE (oWinDash:nWidth/2)*0.2, 011 OF oWinDash FONT oFntTxt COLORS 8421504, 16777215 PIXEL
	
	oPanAna := TPanel():New( 20, 0,, oWinDash,, .T.,, CLR_BLACK, CLR_BLACK, (oWinDash:nWidth/2),/*nButtom*/ (oWinDash:nHeight/2)-20 )
    oDash := FWChartFactory():New()
    oDash:SetChartDefault( COLUMNCHART )
    oDash:SetOwner( oPanAna )
    oDash:SetLegend( CONTROL_ALIGN_NONE )
 	oDash:SetAlignSerieLabel(CONTROL_ALIGN_RIGHT)
 	oDash:EnableMenu(.F.)
    oDash:SetMask(" *@* ")
    oDash:SetPicture( '@E 9,999,999' )
    oDash:Activate()

	ACTIVATE MSDIALOG oDlgCom CENTERED ON INIT Eval({|| EnchoiceBar( oDlgCom, bOk, bCancel,,aButtons ),;
														_aFilters := prodFilter( _aFilters ),;
														Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' ) }) 
														/* oBrwFor:SetFocus(),; */ 
														/* Processa({|| fEvents() }, 'Aguarde!','Identificando alertas de ruptura...') */  
	oAliFor:Delete()
	
Return ( Nil )

/*/{Protheus.doc} internalParms
Função para abertura da rotina de manutenção de parâmetros internos
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 13/09/2024
/*/
static function internalParms()
	if U_JSPAICFG()			// Verifica se o Ok foi pressionado
		H_HLP( 'A T E N Ç Ã O',;
				'Devido a alterações realizadas em parâmetros internos, a rotina será reiniciada.',;
				'Você poderá reabrí-la imediatamente após a mesma ser encerrada.' )
		Final('Encerrando...')
	endif
return Nil

/*/{Protheus.doc} entryDocs
Função para exibir os documentos de entrada relacionados ao produto
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 16/08/2024
@param cProduto, character, ID do produto
/*/
static function entryDocs( cProduto )
	
	local aArea    := getArea()
	local cQuery   := "" as character
	local aSize    := MsAdvSize()
	// local nHor     := (aSize[5]/2)*0.8
	local aButtons := {} as array
	local bOk      :={|| oDlgDoc:End()}
	local bCancel  :={|| oDlgDoc:End()}
	local aFields  := { "D1_FILIAL", "D1_DOC", "D1_SERIE", "D1_ITEM", "D1_LOCAL","D1_FORNECE", "D1_LOJA", "D1_QUANT", "D1_VUNIT", "D1_TOTAL", "D1_VALIPI", "D1_VALICM",;
						"D1_TES", "D1_COD", "D1_UM", "D1_CF", "D1_DESC", "D1_IPI", "D1_PICM", "D1_EMISSAO", "D1_DTDIGIT", "D1_BASEICM", "D1_VALDESC",;
						"D1_BASEIPI", "D1_CUSTO", "D1_BASIMP5", "D1_BASIMP6", "D1_VALIMP5", "D1_VALIMP6", "D1_ALQIMP5", "D1_ALQIMP6", "D1_VALFRE",;
						"D1_ICMSDIF", "D1_ALQCSL", "D1_VOPDIF", "A2_NOME", "A2_EST", "D1_DESPESA", "D1_ALIQSOL", "D1_ICMSRET", "D1_MARGEM" }
	local bValid   :={|| .T. }
	local bInit    :={|| EnchoiceBar( oDlgDoc, bOk, bCancel,,aButtons )}
	local oLayer         as object
	local oPanDoc        as object
	local oPanFld        as object
	local aColumns := {} as array
	local aFldCol  := { "D1_FILIAL", "D1_EMISSAO", "D1_DTDIGIT", "D1_DOC", "D1_SERIE", "D1_ITEM", "D1_FORNECE", "D1_LOJA", "A2_NOME", "A2_EST", "D1_QUANT",; 
						"D1_VUNIT", "D1_TOTAL", "D1_VALDESC"  }
	local nX       := 0 as numeric
	local oGrpCab  as object
	local oGetCod  as object
	local oGetDes  as object
	local oGetUM   as object
	local oGetNCM  as object
	local oGetUOC  as object
	local oGetTab  as object
	local oGetUNF  as object
	local lEnable  := .T. as logical

	// Entrada
	local oGetTES  as object
	local oGetDTE  as object
	local oGetICM  as object
	local oValICM  as object
	local oGetIPI  as object
	local oValIPI  as object
	local oGetFre  as object
	local oValFre  as object
	local oGetICF  as object
	local oValICF  as object
	local oGetOut  as object
	local oValOut  as object
	local oGetFin  as object
	local oValFin  as object
	local oGetPC   as object
	local oValPC   as object
	local oGetST   as object
	Local oValST   as object
	local oGetMVA  as object
	local oGetCuL  as object
	local oGetCuM  as object
	local oGrpCom  as object
	local oGrpVen  as object
	local oGrpUlt  as object 
	
	// Saída
	local oGetLuc  as object		// Lucro pretendido
	local oGetPCV  as object		// PIS/COFINS Venda
	local oGetICV  as object		// ICMS Venda
	local oGetOpe  as object		// Percentual custo operacional
	local oGetCSL  as object		// Percentual CSLL
	local oGetIRP  as object		// Percentual IRPJ
	local oGetIna  as object		// Índice Inadimplência
	local oGetTCV  as object		// Total custo variável
	local oGetFiV  as object		// Custo financeiro (desconto conforme forma de pagamento)
	local oGetPSL  as object		// Preço sem lucro
	local oGetSug  as object		// Sugestão preço de venda
	local oGetPrc  as object		// Preço de venda
	local oGetMg1  as object		// Margem do preço sugerido
	local oGetMg2  as object		// Margem sobre o preço vigente
	
	// Última compra
	local oGetUPr  as object
	local oGetUQt  as object
	local oGetUDt  as object
	local oGetUPz  as object
	local oGetNF   as object
	local oGetUFo  as object
	local oGetUFi  as object
	local nIniHor  := 0 as numeric
	local nLine    := 0 as numeric
	local oBtnTab  as object
	local oBtnLuc  as object
	local oBtnDOp  as object
	local oBtnCSL  as object
	local oBtnIRP  as object
	local oBtnIna  as object
	local oBtnFin  as object

	// Dados do produto
	Private cGetCod := cProduto
	Private cGetDes := RetField( 'SB1', 1, FWxFilial( 'SB1' ) + cProduto, 'B1_DESC' )
	Private cGetUM  := RetField( 'SB1', 1, FWxFilial( 'SB1' ) + cProduto, 'B1_UM' )
	Private nGetUOC := 0 as numeric
	Private cGetNCM := RetField( 'SB1', 1, FWxFilial( 'SB1' ) + cProduto, 'B1_POSIPI' )
	Private cGetTab := SuperGetMV( 'MV_TABPAD',,Space(TAMSX3('DA1_CODTAB')[1]) )
	Private nGetUNF := 0 as numeric

	// Entrada
	Private cGetTES := Space( TAMSX3('D1_TES')[1] ) as character
	Private cGetDTE := Space( TAMSX3('F4_TEXTO')[1] ) as character
	Private nGetICM := 0 
	Private nValICM := 0
	Private nGetIPI := 0
	Private nValIPI := 0
	Private nGetFre := 0
	Private nValFre := 0  
	Private nGetICF := 0
	Private nValICF := 0
	Private nGetOut := 0
	Private nValOut := 0
	Private nGetFin := 0
	Private nValFin := 0
	Private nGetPC  := 0
	Private nValPC  := 0
	Private nGetST  := 0
	Private nValST  := 0
	Private nGetMVA := 0
	Private nGetCuL := 0
	Private nGetCuM := 0

	// Saída
	Private nGetLuc := getLucro( cProduto, SuperGetMV( 'MV_X_PNC05',,0 ) )
	Private nGetPCV := SuperGetMV( 'MV_TXPIS'  ,,0 ) + SuperGetMV( 'MV_TXCOFIN',,0 ) 			// PIS/COFINS Venda
	Private nGetICV := SuperGetMV( 'MV_ICMPAD' ,,0 ) 			// ICMS Venda
	Private nGetOpe := SuperGetMV( 'MV_X_PNC06',,0 )			// Despesas Operacionais Venda
	Private nGetCSL := SuperGetMV( 'MV_X_PNC07',,0 )			// CSLL
	Private nGetIRP := SuperGetMV( 'MV_X_PNC08',,0 )			// IRPJ
	Private nGetIna := SuperGetMV( 'MV_X_PNC09',,0 )			// Índice Inadimplência
	Private nGetTCV := 0			// Total Custo Variável
	Private nGetFiV := SuperGetMV( 'MV_X_PNC10',,0 )			// Custo Financeiro (custo cartão, desconto à vista...)
	Private nGetPSL := 0			// Preço sem lucro
	Private nGetSug := 0			// Sugestão Preço de Venda
	Private nGetMg1 := 0 			// Margem sobre o preço sugerido
	Private nGetPrc := 0			// Preço de Venda Atual
	private nGetMg2 := 0			// Margem sobre o preço vigente

	/*Ponto de equilíbrio = custos e despesas fixas + lucro mínimo ÷ margem de contribuição (receita – custos e despesas variáveis).*/
	
	// Ultima compra
	Private nGetUPr := 0			// Ultimo preço 
	Private nGetUQt := 0			// Quantidade da ultima compra
	Private dGetUDt := StoD('')		// Data ultima compra
	Private cGetUPz := Space( 100 )	// Descrição Ultimo Prazo de Compra 
	Private cGetNF  := Space( TAMSX3( 'F1_DOC' )[1] )		// Número da ultima nota de compra
	Private cGetUFo := Space( 100 )	// Ultimo fornecedor do material
	Private cGetUFi := Space( len( cFilAnt ) )				// Ultima filial que foi dado entrada em nota com o produto
	Private cUFFor  := ""
	Private oBrwDoc     as object
	Private oDlgDoc     as object

	// Query para análise 
	cQuery := "SELECT "
	// Adiciona todos os campos do vetor na query
	aEval( aFields, {|x| cQuery += x +', ' } )
	cQuery += "D1.R_E_C_N_O_ RECSD1, "
	cQuery += "COALESCE("
	cQuery += "( SELECT SUM( COMP.D1_TOTAL ) FROM "+ RetSqlName( 'SD1' ) +" COMP "
	cQuery += "  INNER JOIN "+ RetSqlName( 'SF1' ) +" F1 "
	cQuery += "   ON F1.F1_FILIAL  = COMP.D1_FILIAL "
	cQuery += "  AND F1.F1_DOC     = COMP.D1_DOC "
	cQuery += "  AND F1.F1_SERIE   = COMP.D1_SERIE "
	cQuery += "  AND F1.F1_FORNECE = COMP.D1_FORNECE "
	cQuery += "  AND F1.F1_LOJA    = COMP.D1_LOJA "
	cQuery += "  AND F1.F1_TPCOMPL = '1' "		// Complemento de Preço
	cQuery += "  AND F1.D_E_L_E_T_ = ' ' "
	cQuery += "  WHERE COMP.D1_FILIAL  = D1.D1_FILIAL "
	cQuery += "    AND COMP.D1_NFORI   = D1.D1_DOC "
	cQuery += "    AND COMP.D1_SERIORI = D1.D1_SERIE "
	cQuery += "    AND COMP.D1_ITEMORI = D1.D1_ITEM "
	cQuery += "    AND COMP.D1_FORNECE = D1.D1_FORNECE "
	cQuery += "    AND COMP.D1_LOJA    = D1.D1_LOJA "
	cQuery += "    AND COMP.D1_TIPO    = 'C' "
	cQuery += "    AND COMP.D_E_L_E_T_ = ' ' "
	cQuery += " ),0) AS VALFIN "
	cQuery += "FROM "+ RetSqlName( 'SD1' ) +" D1 "
	
	// Faz Join com tabela de fornecedor
	cQuery += "INNER JOIN "+ RetSqlName( 'SA2' ) +" A2 "
	cQuery += " ON A2.A2_FILIAL  " + U_JSFILIAL( 'SA2', _aFil ) + " "
	cQuery += "AND A2.A2_COD     = D1.D1_FORNECE "
	cQuery += "AND A2.A2_LOJA    = D1.D1_LOJA "
	cQuery += "AND A2.D_E_L_E_T_ = ' ' "

	cQuery += "WHERE D1.D1_FILIAL  " + U_JSFILIAL( 'SD1', _aFil ) + " "
	cQuery += "  AND D1.D1_COD     = '"+ cProduto +"' "
	cQuery += "  AND D1.D1_TIPO    = 'N' "		// Apenas notas do tipo Normal
	cQuery += "  AND D1.D1_TES     <> '"+ Space( TAMSX3('D1_TES')[1] ) +"' "	// Apenas notas já classificadas
	cQuery += "  AND D1.D_E_L_E_T_ = ' ' "
	cQuery += "ORDER BY D1.D1_EMISSAO DESC, D1.D1_DTDIGIT DESC, D1.D1_DOC ASC, D1.D1_SERIE ASC"		

	// Define as colunas do browse
	for nX := 1 to len( aFldCol )
		aAdd( aColumns, FWBrwColumn():New() )
		aColumns[len(aColumns)]:SetTitle( GetSX3Cache( aFldCol[nX], 'X3_TITULO' ) )
		aColumns[len(aColumns)]:SetType( GetSX3Cache( aFldCol[nX], 'X3_TIPO' ) )
		aColumns[len(aColumns)]:SetSize( GetSX3Cache( aFldCol[nX], 'X3_TAMANHO' ) )
		aColumns[len(aColumns)]:SetDecimal( GetSX3Cache( aFldCol[nX], 'X3_DECIMAL' ) )
		aColumns[len(aColumns)]:SetData(&( getStrData( aFldCol[nX] ) ))
		aColumns[len(aColumns)]:SetAlign( getAlign( GetSX3Cache( aFldCol[nX], 'X3_TIPO' ) ) )
		aColumns[len(aColumns)]:SetPicture( GetSX3Cache( aFldCol[nX], 'X3_PICTURE' ) )
	next nX

	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( 'Compl.Fin.' )
	aColumns[len(aColumns)]:SetType( 'N' )
	aColumns[len(aColumns)]:SetSize( 13 )
	aColumns[len(aColumns)]:SetDecimal( 2 )
	aColumns[len(aColumns)]:SetData( {|| SD1TMP->VALFIN } )
	aColumns[len(aColumns)]:SetAlign( getAlign( 'N' ) )
	aColumns[len(aColumns)]:SetPicture( "@E 9,999,999.99" )

	// Documentos de entrada ligados ao produto atual
	oDlgDoc := TDialog():New( 0, 0, aSize[6]*0.9, aSize[5]*0.8,'Documentos de Entrada para o Produto',,,,,CLR_BLACK,CLR_WHITE,,,.T.)
	
	// Cria camadas de layout
	oLayer := FWLayer():New()
	oLayer:init( oDlgDoc, .F. )
	oLayer:AddLine( 'DOCUMENTOS', 025, .F. )
	oLayer:AddLine( 'CALCULOS', 075, .F. )
	oLayer:AddCollumn( "NOTAS", 100, .T., "DOCUMENTOS" )
	oLayer:AddCollumn( "CAMPOS", 100, .T., "CALCULOS" )
	oPanDoc := oLayer:GetColPanel( 'NOTAS', "DOCUMENTOS" )
	oPanFld := oLayer:GetColPanel( 'CAMPOS', "CALCULOS" )

	oBrowse := FWBrowse():New( oPanDoc )
	oBrowse:SetDataQuery()
	oBrowse:SetQuery( cQuery )
	oBrowse:SetAlias( 'SD1TMP' )
	oBrowse:DisableReport()
	oBrowse:DisableConfig()
	oBrowse:SetLineHeight( 20 )
	oBrowse:SetColumns( aColumns )
	oBrowse:bChange := {|| someChange( .T. /* lReset */), oDlgDoc:Refresh() }
	oBrowse:Activate()

	// Group dados do produto
	nLine := 0
	oGrpCab   := TGroup():New( nLine, 4, 50, (oPanFld:nWidth/2)-4, "Produto", oPanFld,,,.T. )
	nLine += 10
	oGetCod   := doGet( nLine, 008, {|u| if( pCount()>0,cGetCod:=u,cGetCod ) }, oPanFld, 60, 10, "@x", 'cGetCod', 'Cod.Prod.', !lEnable )
	oGetCod:cF3 := GetSX3Cache( 'D1_COD', 'X3_F3' )
	oGetDes   := doGet( nLine, 108, {|u| if( pCount()>0,cGetDes:=u,cGetDes ) }, oPanFld, 120, 10, "@x", 'cGetDes', 'Descrição', !lEnable )
	oGetUM    := doGet( nLine, 268, {|u| if( pCount()>0,cGetUM:=u,cGetUM   ) }, oPanFld, 20, 10, "@x", 'cGetUM', 'Un.Med.', !lEnable )
	oGetNCM   := doGet( nLine, 328, {|u| if( pCount()>0,cGetNCM:=u,cGetNCM ) }, oPanFld, 40, 10, PesqPict('SB1','B1_POSIPI'), 'cGetNCM', 'NCM', !lEnable )
	oGetNCM:cF3 := GetSX3Cache( 'B1_POSIPI', 'X3_F3' )	
	nLine += 14
	oGetUOC   := doGet( nLine, 008, {|u| if( pCount()>0,nGetUOC:=u,nGetUOC ) }, oPanFld, 70, 10, "@E 9,999,999.99", 'nGetUOC', 'Prc.Compra', lEnable )
	oGetTab   := doGet( nLine, 118, {|u| if( pCount()>0,cGetTab:=u,cGetTab ) }, oPanFld, 40, 10, "@!", 'cGetTab', 'Tab.Preço' )
	oGetTab:cF3 := GetSX3Cache( 'C5_TABELA', 'X3_F3' )
	oGetUNF   := doGet( nLine, 208, {|u| if( pCount()>0,nGetUNF:=u,nGetUNF ) }, oPanFld, 70, 10, "@E 9,999,999.99", 'nGetUNF', 'Valor', !lEnable )

	// Entrada
	nLine := 52
	oGrpCom   := TGroup():New( nLine, 4, (oPanFld:nHeight/2)-30, ((oPanFld:nWidth/2)/3)-16, "Entrada (Operação 51-Compra Normal) ", oPanFld,,,.T. )
	nLine += 10
	oGetTES   := doGet( nLine, 008, {|u| if( PCount()>0,cGetTES:=u,cGetTES ) }, oPanFld, 40, 10, "@!", 'cGetTES', 'TES', !lEnable )
	oGetTES:cF3 := "SF4"	// Pesquisa padrão cadastro de TES
	oGetDTE   := doGet( nLine, 085, {|u| if( PCount()>0,cGetDTE:=u,cGetDTE ) }, oPanFld, 60, 10, "@x", 'cGetDTE',, !lEnable )
	nLine += 14
	oGetICM   := doGet( nLine, 008, {|u| if( PCount()>0,nGetICM:=u,nGetICM ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetICM', 'ICMS', lEnable )
	oGetICM:bChange := {|| nValICM := (nGetICM/100)*nGetUOC, someChange() }
	oValICM   := doGet( nLine, 095, {|u| if( PCOunt()>0,nValICM:=u,nValICM ) }, oPanFld, 50, 10, "@E 9,999,999.99", 'nValICM',, !lEnable )
	nLine += 14
	oGetIPI   := doGet( nLine, 008, {|u| if( pCOunt()>0,nGetIPI:=u,nGetIPI ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetIPI', 'IPI', lEnable )
	oGetIPI:bChange := {|| nValIPI := (nGetIPI/100)*nGetUOC, someChange() }
	oValIPI   := doGet( nLine, 095, {|u| if( PCount()>0,nValIPI:=u,nValIPI ) }, oPanFld, 50, 10, "@E 9,999,999.99", 'nValIPI',, !lEnable )
	nLine += 14
	oGetFre   := doGet( nLine, 008, {|u| if( pCOunt()>0,nGetFre:=u,nGetFre ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetFre', 'Frete', lEnable )
	oGetFre:bChange := {|| nValFre := (nGetFre/100)*nGetUOC, someChange() }
	oValFre   := doGet( nLine, 095, {|u| if( PCount()>0,nValFre:=u,nValFre ) }, oPanFld, 50, 10, "@E 9,999,999.99", 'nValFre',,!lEnable )
	nLine += 14
	oGetICF   := doGet( nLine, 008, {|u| if( pCOunt()>0,nGetICF:=u,nGetICF ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetICF', 'ICMS Frete', lEnable )
	oGetICF:bChange := {|| nValICF := (nGetICF/100)*nValFre, someChange() }
	oValICF   := doGet( nLine, 095, {|u| if( PCount()>0,nValICF:=u,nValICF ) }, oPanFld, 50, 10, "@E 9,999,999.99", 'nValICF',,!lEnable )
	nLine += 14
	oGetOut   := doGet( nLine, 008, {|u| if( pCOunt()>0,nGetOut:=u,nGetOut ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetOut', 'Outras Desp.',lEnable )
	oGetOut:bChange := {|| nValOut := (nGetOut/100)*nGetUOC, someChange() }
	oValOut   := doGet( nLine, 095, {|u| if( PCount()>0,nValOut:=u,nValOut ) }, oPanFld, 50, 10, "@E 9,999,999.99", 'nValOut',,!lEnable )
	nLine += 14
	oGetFin   := doGet( nLine, 008, {|u| if( pCOunt()>0,nGetFin:=u,nGetFin ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetFin', 'Financeiro', lEnable )
	oGetFin:bChange := {|| nValFin := (nGetFin/100)*nGetUOC, someChange() }
	oValFin   := doGet( nLine, 095, {|u| if( PCount()>0,nValFin:=u,nValFin ) }, oPanFld, 50, 10, "@E 9,999,999.99", 'nValFin',,lEnable )
	oValFin:bChange := {|| nGetFin := (nValFin/nGetUOC)*100, someChange() }
	nLine += 14
	oGetPC    := doGet( nLine, 008, {|u| if( pCOunt()>0,nGetPC :=u,nGetPC  ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetPC', 'PIS/COFINS', lEnable )
	oGetPC:bChange := {|| nValPC := (nGetPC/100)*nGetUOC, someChange() }
	oValPC    := doGet( nLine, 095, {|u| if( PCount()>0,nValPC :=u,nValPC  ) }, oPanFld, 50, 10, "@E 9,999,999.99", 'nValPC',, !lEnable )
	nLine += 14
	oGetST    := doGet( nLine, 008, {|u| if( pCOunt()>0,nGetST :=u,nGetST  ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetST', 'ST', lEnable )
	oGetST:bChange := {|| nValST := (nGetST/100)*nGetUOC, someChange() }
	oValST    := doGet( nLine, 095, {|u| if( PCount()>0,nValST :=u,nValST  ) }, oPanFld, 50, 10, "@E 9,999,999.99", 'nValST',, !lEnable )
	nLine += 14
	oGetMVA   := doGet( nLine, 008, {|u| if( pCOunt()>0,nGetMVA:=u,nGetMVA ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetMVA', 'MVA', !lEnable )
	nLine += 14
	oGetCuL   := doGet( nLine, 008, {|u| if( pCOunt()>0,nGetCuL:=u,nGetCuL ) }, oPanFld, 50, 10, "@E 9,999,999.99", 'nGetCuL', 'Custo Líq.', !lEnable )
	nLine += 14
	oGetCuM   := doGet( nLine, 008, {|u| if( pCOunt()>0,nGetCuM:=u,nGetCuM ) }, oPanFld, 50, 10, "@E 9,999,999.99", 'nGetCuM', 'Custo Médio', !lEnable )
	
	// Saída
	nIniHor := ((oPanFld:nWidth/2)/3)-12
	nLine   := 52
	oGrpVen   := TGroup():New( nLine, nIniHor, (oPanFld:nHeight/2)-30, (((oPanFld:nWidth/2)/3)*2)-8, "Saída", oPanFld,,,.T. )
	nLine += 10
	oGetLuc   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetLuc:=u,nGetLuc ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetLuc', 'Lucro' )
	oBtnLuc   := TButton():New( nLine, nIniHor+96, "Tornar Padrão",oPanFld,{|| PutMV( 'MV_X_PNC05', nGetLuc ), someChange() }, 50,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	oBtnLuc:bWhen := {|| GetMv( 'MV_X_PNC05', .T. /* lCheck */ ) .and. nGetLuc != SuperGetMV( 'MV_X_PNC05',,0 ) }

	nLine += 14
	oGetPCV   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetPCV:=u,nGetPCV ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetPCV', 'PIS/COFINS' )
	nLine += 14
	oGetICV   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetICV:=u,nGetICV ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetICV', 'ICMS' )
	nLine += 14
	oGetOpe   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetOpe:=u,nGetOpe ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetOpe', 'Desp.Oper' )
	oBtnDOp   := TButton():New( nLine, nIniHor+96, "Tornar Padrão",oPanFld,{|| PutMV( 'MV_X_PNC06', nGetOpe ), someChange() }, 50,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	oBtnDOp:bWhen := {|| GetMv( 'MV_X_PNC06', .T. /* lCheck */ ) .and. nGetOpe != SuperGetMV( 'MV_X_PNC06',,0 ) }

	nLine += 14
	oGetCSL   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetCSL:=u,nGetCSL ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetCSL', 'CSLL' )
	oBtnCSL  := TButton():New( nLine, nIniHor+96, "Tornar Padrão",oPanFld,{|| PutMV( 'MV_X_PNC07', nGetCSL ), someChange() }, 50,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	oBtnCSL:bWhen := {|| GetMv( 'MV_X_PNC07', .T. /* lCheck */ ) .and. nGetCSL != SuperGetMV( 'MV_X_PNC07',,0 ) }

	nLine += 14
	oGetIRP   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetIRP:=u,nGetIRP ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetIRP', 'IRPJ' )
	oBtnIRP   := TButton():New( nLine, nIniHor+96, "Tornar Padrão",oPanFld,{|| PutMV( 'MV_X_PNC08', nGetIRP ), someChange() }, 50,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	oBtnIRP:bWhen := {|| GetMv( 'MV_X_PNC08', .T. /* lCheck */ ) .and. nGetIRP != SuperGetMV( 'MV_X_PNC08',,0 ) }

	nLine += 14
	oGetIna   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetIna:=u,nGetIna ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetIna', 'Inadimpl' )
	oBtnIna   := TButton():New( nLine, nIniHor+96, "Tornar Padrão",oPanFld,{|| PutMV( 'MV_X_PNC09', nGetIna ), someChange() }, 50,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	oBtnIna:bWhen := {|| GetMv( 'MV_X_PNC09', .T. /* lCheck */ ) .and. nGetIna != SuperGetMV( 'MV_X_PNC09',,0 ) }

	nLine += 14
	oGetTCV   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetTCV:=u,nGetTCV ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetTCV', 'Tt.Cus.Var', !lEnable )
	nLine += 14
	oGetFiV   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetFiV:=u,nGetFiV ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetFiV', 'Financeiro' )
	oBtnFin   := TButton():New( nLine, nIniHor+96, "Tornar Padrão",oPanFld,{|| PutMV( 'MV_X_PNC10', nGetFiV ), someChange() }, 50,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	oBtnFin:bWhen := {|| GetMv( 'MV_X_PNC10', .T. /* lCheck */ ) .and. nGetFiV != SuperGetMV( 'MV_X_PNC10',,0 ) }

	nLine += 14
	oGetPSL   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetPSL:=u,nGetPSL ) }, oPanFld, 50, 10, "@E 9,999,999.99", 'nGetPSL', 'Prc.s/Lucro', !lEnable )
	nLine += 14
	oGetSug   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetSug:=u,nGetSug ) }, oPanFld, 50, 10, "@E 9,999,999.99", 'nGetSug', 'Sug.Preço' )
	oGetMg1   := doGet( nLine, nIniHor+91,{|u| if( PCount()>0,nGetMg1:=u,nGetMg1 ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetMg1',, !lEnable )
	oBtnTab   := TButton():New( nLine, nIniHor+143, "Aplicar",oPanFld,{|| priceAdjust( cGetTab, SD1TMP->D1_COD, nGetSug ), someChange() }, 30,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	oBtnTab:bWhen := {|| !Empty( cGetTab ) .and. ! Round( nGetSug, 2 ) == nGetPrc }

	nLine += 14
	oGetPrc   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetPrc:=u,nGetPrc ) }, oPanFld, 50, 10, "@E 9,999,999.99", 'nGetPrc', 'Prc.Venda', !lEnable )
	oGetMg2   := doGet( nLine, nIniHor+91,{|u| if( PCount()>0,nGetMg2:=u,nGetMg2 ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetMg2',,!lEnable )

	// Ultima compra
	nIniHor   := (((oPanFld:nWidth/2)/3)*2)-4
	nLine	  := 52
	oGrpUlt   := TGroup():New( nLine, nIniHor, (oPanFld:nHeight/2)-30, (oPanFld:nWidth/2)-4, "Ult.Compra", oPanFld,,,.T. )
	nLine     += 10
	oGetUPr   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetUPr:=u,nGetUPr ) }, oPanFld, 60, 10, "@E 9,999,999.99", 'nGetUPr', 'Ult.Preço', !lEnable )
	nLine     += 14
	oGetUQt   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetUQt:=u,nGetUQt ) }, oPanFld, 50, 10, "@E 9,999,999", 'nGetUQt', 'Ult.Quant.', !lEnable )
	nLine     += 14
	oGetUDt   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,dGetUDt:=u,dGetUDt ) }, oPanFld, 50, 10,, 'dGetUDt', 'Dt.Ult.NF', !lEnable )
	nLine     += 14
	oGetUPz   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,cGetUPz:=u,cGetUPz ) }, oPanFld, 100, 10,"@x", 'cGetUPz', 'Ult.Prazo', !lEnable )
	nLine     += 14
	oGetNF    := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,cGetNF :=u,cGetNF  ) }, oPanFld, 60, 10,"@!", 'cGetNF', 'Ult.Nota', !lEnable )
	nLine     += 14
	oGetUFo   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,cGetUFo:=u,cGetUFo ) }, oPanFld, 100, 10,"@x", 'cGetUFo', 'Ult.Forn', !lEnable )
	nLine     += 14
	oGetUFi   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,cGetUFi:=u,cGetUFi ) }, oPanFld, 50, 10,"@!", 'cGetUFi', 'Filial', !lEnable )

	oDlgDoc:Activate(,,,.T. /* lCentered */, bValid,,bInit)

	restArea( aArea )
return nil

/*/{Protheus.doc} getLucro
Obtem a margem de lucro desejada para o produto.
Sequência de utilização: Indicador de produto, Produto, Parâmetro interno MV_X_PNC05
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 26/09/2024
@param cProduto, character, ID do produto
@param nDefault, numeric, nDefault (MV_X_PNC05)
@return numeric, nIndLuc
/*/
static function getLucro( cProduto, nDefault )
	
	local nIndLuc := nDefault
	
	DBSelectArea( 'SBZ' )
	SBZ->( DBSetOrder( 1 ) )		// FILIAL + COD
	if SBZ->( DBSeek( FWxFilial( 'SBZ' ) + cProduto ) ) .and. SBZ->( FieldPos( 'BZ_X_LUCRO' ) ) > 0 .and. SBZ->BZ_X_LUCRO > 0
		nIndLuc := SBZ->BZ_X_LUCRO
	else
		DBSelectArea( 'SB1' )
		SB1->( DBSetOrder( 1 ) )		// FILIAL + COD
		if SB1->( DBSeek( FWxFilial( 'SB1' ) + cProduto ) ) .and. SB1->( FieldPos( 'B1_X_LUCRO' ) ) > 0 .and. SB1->B1_X_LUCRO > 0
			nIndLuc := SB1->B1_X_LUCRO
		endif
	endif

return nIndLuc 

/*/{Protheus.doc} priceAdjust
Função responsável pela chamada do processo de ajuste de preço na tabela
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 29/08/2024
@param cTab, character, ID da tabela que vai receber o ajuste
@param cProd, character, ID do produto
@param nPrice, numeric, valor a ser aplicado na tabela
@return logical, lSuccess
/*/
static function priceAdjust( cTab, cProd, nPrice )
	local aArea    := getArea()
	local lSuccess := .F. as logical
	local lExist   := .F. as logical

	DBSelectArea( 'DA1' )
	DA1->( DBSetOrder( 1 ) )		// FILIAL + CODTAB + CODPRO
	lExist := DA1->( DBSeek( FWxFilial( 'DA1' ) + cTab + cProd ) )

	if nPrice > 0 
		// Pede confirmação do usuário quando o preço da tabela é maior do que o preço que está tentando colocar
		if lExist .and. nPrice < DA1->DA1_PRCVEN
			if ! MsgYesNo( 'O preço atual do produto é <b>R$ '+ AllTrim( Transform( DA1->DA1_PRCVEN, '@E 9,999,999.99' ) ) +'</b>, '+;
							'você está tentando alterar para um valor <b>MENOR</b>, quer continuar mesmo assim?', 'A T E N Ç Ã O !' )
				restArea( aArea )
				Return lSuccess
			endif
		endif
		RecLock( 'DA1', !lExist )
		if !lExist
			DA1->DA1_FILIAL := FWxFilial( 'DA1' )
			DA1->DA1_CODTAB := cTab
			DA1->DA1_CODPRO := cProd
			DA1->DA1_ITEM   := nextTbItem( cTab )
			DA1->DA1_DATVIG := dDataBase
		endif
		DA1->DA1_PRCVEN := nPrice
		DA1->DA1_ATIVO  := '1'		// 1=Ativo
		DA1->DA1_TPOPER := '4'		// 4=Todas
		DA1->DA1_QTDLOT := 999999.99
		DA1->DA1_INDLOT := '000000000999999.99  '
		DA1->DA1_MOEDA  := 1
		DA1->( MsUnlock() )
		lSuccess := .T.
	else
		hlp( 'NEGATIVO/ZERADO',;
			 'Atenção! Você está tentando atribuir um preço 0(zero) ou negativo no preço de tabela do produto',;
			 'Preço de tabela de um produto obrigatoriamente precisa ser um número positivo (maior do que zero)' )
	endif

	restArea( aArea )
return lSuccess

/*/{Protheus.doc} nextTbItem
Obtem o próximo conteúdo do campo Item do cadastro de itens da tabela de preços
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 29/08/2024
@param cTab, character, ID da tabela
@return character, cItem
/*/
static function nextTbItem( cTab )
	
	local cQuery := "" as character
	local cItem  := "" as character
	
	// Query de busca do ultimo conteúdo do campo DA1_ITEM para a tabela recebida via parâmetro
	cQuery := "SELECT COALESCE(MAX( DA1_ITEM ),'"+ Replicate( '0', TAMSX3('DA1_ITEM')[1] ) +"') DA1_ITEM FROM "+ RetSqlName( 'DA1' ) +" DA1 " 
	cQuery += "WHERE DA1.DA1_FILIAL = '"+ FWxFilial( 'DA1' ) +"' "
	cQuery += "  AND DA1.DA1_CODTAB = '"+ cTab +"' "
	cQuery += "  AND DA1.D_E_L_E_T_ = ' ' "

	DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), 'DA1TMP', .F., .T. )
	cItem := Soma1( DA1TMP->DA1_ITEM )
	DA1TMP->( DBCloseArea() )

return cItem

/*/{Protheus.doc} getStrData
Função para definir a string com a formula do cálculo para exibição dos dados no browse
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 16/08/2024
@param cField, character, ID do campo
@return character, cStrData
/*/
static function getStrData( cField )
	local cStrData := '{|| '+ cField +' }'
	// Quando tipo de dados for data, converte para que o tipo exibido em tela fique no formato correto
	if GetSX3Cache( cField, 'X3_TIPO' ) == 'D'		
		cStrData := '{|| StoD('+ cField +') }'
	endif
return cStrData

/*/{Protheus.doc} getAlign
Função para definir alinhamento da informação no grid
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 16/08/2024
@param cType, character, tipo de dados que o campo utiliza
@return numeric, nAlign
/*/
static function getAlign( cType )
return iif( cType $ 'C/M', 1, iif( cType == 'N', 2, 0 ) )

/*/{Protheus.doc} fMark
Função responsável pela marcação dos registros do browse de fornecedores
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 6/27/2022
@param cAlias, character, Alias que vai receber a marcação
@param lAll, logical, Indica se deve marcar todos os registros
@param oBrowse, object, Objeto gráfico do browse
/*/
Static Function fMark( cAlias, lAll, oBrowse )

	local aArea    := ( cAlias )->( GetArea() )
	local lMarca   := ( cAlias )->MARK != cMarca
	local nX       := 0 as numeric

	default lAll := .F.

	if lAll

		// Posiciona e marca/desmarca todos os registros da temp-table
		( cAlias )->( DBGoTop() )
		while !( cAlias )->( EOF() )
			
			// Verifica a regra e marca/desmarca todos os registros
			RecLock( ( cAlias ), .F. )
			( cAlias )->MARK := iif( lMarca, cMarca, Space(2) )
			( cAlias )->( MsUnlock() )

			( cAlias )->( DbSkip() )
		enddo
		
		RestArea( aArea )
		oBrowse:UpdateBrowse()

	else
		
		// Executa seleção apenas quando não for final de arquivo
		if ! ( cAlias )->( EOF() )
			// Altera apenas o registro posicionado
			RecLock( ( cAlias ), .F. )
			( cAlias )->MARK := iif( lMarca, cMarca, Space(2) )
			( cAlias )->( MsUnlock() )

			// Se o registro acabou ficando de fora do filtro, força refresh geral do browse
			oBrowse:LineRefresh()
			
		endif
		
	endif

	aMrkFor := {}
	aColPro := {}
	aArea := ( cAlias )->( GetArea() )
	( cAlias )->( DBGoTop() )
	while ! ( cAlias )->( EOF() )
		// Se o registro estiver selecionado, guarda na variável
		if ( cAlias )->MARK == cMarca
			aAdd( aMrkFor, ( cAlias )->( FieldGet( FieldPos( 'B1_PROC' ) ) ) + ( cAlias )->( FieldGet( FieldPos( 'B1_LOJPROC' ) ) ) )
		endif
		( cAlias )->( DBSkip() )
	end
	restArea( aArea )
	for nX := 1 to len( aFullPro )		
		if aScan( aMrkFor, {|x| x == aFullPro[nX][nPosFor] + aFullPro[nX][nPosLoj] } ) > 0 
			aAdd( aColPro, aClone( aFullPro[nX] ) )
		endif 
	next nX
	oBrwPro:SetArray( aColPro  )
	oBrwPro:UpdateBrowse()

return ( Nil )

/*
+-----------------+-------------------------+---------------------------------+-------------------+
| Fonte: GMPAICOM | Funcao:  fFunApr        | Autor: Jean Carlos P. Saggin    |  Data: 04.11.2019 |
+-----------------+-------------------------+---------------------------------+-------------------+
| Descricao: Chama função referente a rotina de aprovação de documentos padrão do compras         |
+-------------------------------------------------------------------------------------------------+
| Parametros recebidos: Nil                                                                       |
+-------------------------------------------------------------------------------------------------+
| Retorno da funcao: Nil                                                                          |
+-------------------------------------------------------------------------------------------------+  
*/
Static Function fFunApr()
	
	Local aArea   := GetArea()
	Local cFunOld := FunName()
	
	SetFunName( "MATA094" )
	MATA094()
	SetFunName( cFunOld )
	
	RestArea( aArea )
	
	// Chama função que atualiza novamente o grid da tela principal para atualizar valores dos campos
	Processa( {|| fLoadInf() }, 'Aguarde!','Analisando dados do MRP...' )
	
Return ( Nil )

/*
+-----------------+-------------------------+---------------------------------+-------------------+
| Fonte: GMPAICOM | Funcao:  fRetDia        | Autor: Jean Carlos P. Saggin    |  Data: 02.08.2019 |
+-----------------+-------------------------+---------------------------------+-------------------+
| Descricao: Retorno da label em formato caractere com a data da projeção do estoque              |
+-------------------------------------------------------------------------------------------------+
| Parametros recebidos: Nil                                                                       |
+-------------------------------------------------------------------------------------------------+
| Retorno da funcao: Nil                                                                          |
+-------------------------------------------------------------------------------------------------+  
*/
Static Function fRetDia( nSpinBx, lNoInt )
	
	Local cRet  := DtoC( Date() )
	Local nUtil := 0
	Local nAux  := 0
	
	Default lNoInt := .F.
	
	if aConfig[15] == "C"
		cRet := AllTrim( DtoC( Date() + nSpinBx ) )
	Else
		nAux  := 0
		nUtil := 0
		While nUtil < nSpinBx
			if DataValida( Date() + nAux, .T. ) == ( Date() + nAux )
				nUtil++
			EndIf
			nAux++
		EndDo
		cRet := AllTrim( DtoC( Date() + nAux ) )
	EndIf
	
	if !lNoInt
		oLblDia:CCAPTION := "dias ( até "+ cRet +" )"
		oLblDia:CtrlRefresh()
	EndIf
	
Return ( cRet )

/*/{Protheus.doc} fShowEv
Função para mostar eventos pendentes no painel de compras e permitir que o operador tome algumas ações 
referente ao assunto à partir da própria tela
@type function
@version 12.1.25
@author Jean Carlos Pandolfo Saggin
@since 02/08/2020
@param cCodPrd, character, Código do produto
/*/
Static Function fShowEv( cCodPrd )
	
	Local oBtnSai  := Nil
	Local oGrpExc  := Nil
	Local oGrpNot  := Nil
	Local aCpo     := {}
	Local aStr     := {}
	Local lInverte := .F.
	Local cMark    := GetMark()
	Local aAlter   := { cZB3 +"_JUSTIF" }
	Local aHeaderEx := {}
	Local oBtnMod  := Nil 
	Local oBtnExc  := Nil
	Local aColPro  := {}
	Local oBtnEdt  := Nil
	Local aOption  := {}				// Opções de ações disponíveis para o operador
	local oFiltro  := Nil
	local oTblExc  as object
	
	private cFiltro := Space( 250 )
	Private oEvent  := Nil
	Private oDlgEve := Nil
	Private oItEdt1 := Nil 
    Private oItEdt2 := Nil
    Private oItEdt3 := Nil
    Private oItEdt4 := Nil
    Private oItEdt5 := Nil
    Private oItEdt6 := Nil
    Private oItEdt7 := Nil
    Private oItEdt8 := Nil
    Private oExcept := Nil
	
	Default cCodPrd := ""
	
	// Se o código do produto não veio vazio o operador está analisando os eventos de um produto específico
	if !Empty( cCodPrd )
		aAlter := {}
		Processa({|| fEvents( cCodPrd, @aColPro ) }, "Aguarde!", "Identificando eventos do produto..." ) 
	EndIf
	
	aOption := getOptions()
	
	// Define os campos do cabeçalho do grid de avisos
	aHeaderEx := {}
	aAdd( aHeaderEx, { "Filial"    , cZB3 +'_FILIAL', "@!", TAMSX3( cZB3 +'_FILIAL' )[01], TAMSX3( cZB3 +'_FILIAL' )[02],,,"C",,"V",,} )
	aAdd( aHeaderEx, { "Data Ev."  , cZB3 +"_DATA"  , "@D",                        08,                        00,,,"D",,"V",,} )
	aAdd( aHeaderEx, { "Produto"   , cZB3 +"_PROD"  , "@!", TAMSX3( cZB3 +'_PROD'   )[01], TAMSX3( cZB3 +'_PROD'   )[02],,,"C","SB1","V",,} )
	aAdd( aHeaderEx, { "Descricao" , "B1_DESC"      , "@!", TAMSX3('B1_DESC'    )[01], TAMSX3('B1_DESC'    )[02],,,"C",,"V",,} )
	aAdd( aHeaderEx, { "Aviso"     , cZB3 +"_MSG"   , "@!",                        60,                        00,,,"C",,"V",,} )
	
	aStr := {}
	aAdd( aStr, { cZB6 +'_FILIAL', "C", TAMSX3(cZB6 +'_FILIAL')[01], TAMSX3(cZB6 +'_FILIAL')[02] } )
	aAdd( aStr, { cZB6 +"_DATA"  , "D", TAMSX3(cZB6 +'_DATA'  )[01], TAMSX3(cZB6 +'_DATA'  )[02] } )
	aAdd( aStr, { cZB6 +"_PROD"  , "C", TAMSX3(cZB6 +'_PROD'  )[01], TAMSX3(cZB6 +'_PROD'  )[02] } )
	aAdd( aStr, { "B1_DESC"   , "C", TAMSX3('B1_DESC'   )[01], TAMSX3('B1_DESC'   )[02] } )
	aAdd( aStr, { cZB6 +"_DTLIM" , "D", TAMSX3(cZB6 +'_DTLIM' )[01], TAMSX3(cZB6 +'_DTLIM' )[02] } )
	aAdd( aStr, { cZB6 +"_DESCO" , "C", 03, 00 } )
	aAdd( aStr, { cZB6 +"_ULTTEN", "D", TAMSX3(cZB6 +'_ULTTEN')[01], TAMSX3(cZB6 +'_ULTTEN')[02] } )
	aAdd( aStr, { "REC"+ cZB6    , "N", 7, 0 } )
	
	oTblExc := FWTemporaryTable():New( 'EXCEVE', aStr )
	oTblExc:AddIndex( '01', { 'B1_DESC' } )
	oTblExc:Create()
	
	aCpo := {}
	aAdd( aCpo, { cZB6 +'_FILIAL', "", "Filial"       , "@!" } )
	aAdd( aCpo, { cZB6 +"_DATA"  , "", "Dt.Inc."      , "@!" } )
	aAdd( aCpo, { cZB6 +"_PROD"  , "", "Codigo"       , "@!" } )
	aAdd( aCpo, { "B1_DESC"      , "", "Descricao"    , "@!" } )
	aAdd( aCpo, { cZB6 +"_DTLIM" , "", "Dt. Lim."     , "@D" } )
	aAdd( aCpo, { cZB6 +"_DESCO" , "", "Descontinuar?", "@!" } )
	aAdd( aCpo, { cZB6 +"_ULTTEN", "", "Ult.Tent."    , "@D" } )
	
	Processa( {|| fLoadExc( cCodPrd /*cProduto*/, .T. /*lNoInt*/ ) }, "Aguarde!", "Verificando exceções ativas"+ iif( !Empty( cCodPrd ), " para o produto...", "..." ) )

	DEFINE MSDIALOG oDlgEve TITLE "Notificações Pendentes" FROM 000, 000  TO 500, 1000 COLORS 0, 16777215 PIXEL
	
    @ 000, 002 GROUP oGrpNot TO 132, 500-21 PROMPT "   Eventos pendentes de análise    " OF oDlgEve COLOR 0, 16777215 PIXEL
    @ 132, 002 GROUP oGrpExc TO 248, 500-21 PROMPT "   Exceções ativas    " OF oDlgEve COLOR 0, 16777215 PIXEL
    
	// Define um filtro para poder reduzir a pesquisa de produtos do grid
	oFiltro := TGet():New( 007, 005, {|u|iif( pCount()==0,cFiltro,cFiltro:=u )},oDlgEve,150,012,"@!",,0,,,.F.,,.T.,,.F.,{|| .T. /*bWhen*/ },.F.,.F.,{|| Processa( {|| fGrdEve( cFiltro ) }, "Aguarde!", "Recarregando eventos..." ) },.F.,.F.,,'cFiltro',,,,,,,'Filtro Desc.', 1,,,,,.T. )

    // GetDados com os eventos
    oEvent  := MsNewGetDados():New( 029, 003, 131, 475, GD_UPDATE, "AllwaysTrue", "AllwaysTrue",, aAlter,, Len( aEvePen ), "AllwaysTrue", "", "AllwaysTrue", oDlgEve, aHeaderEx, iif( !Empty( cCodPrd ), aColPro, aEvePen ) )
    oEvent:bChange := {|| fStaIte() }
    // oEvent:oBrowse:SetCss( cStyle )
    oEvent:ForceRefresh()
    
    // MarkBrowse para exibição das informações dos itens que estão sendo ignorados
    oExcept := MsSelect():New( 'EXCEVE',,, aCpo, @lInverte, cMark, { 139, 004, 246, 475 })
    // oExcept:oBrowse:SetCss( cStyle )
    oExcept:oBrowse:lCanAllMark := .T.
    oExcept:oBrowse:Refresh()
    
    //@ 003, 962 BTNBMP oBtnEdt RESNAME "fwskin_edit_ico.png" SIZE 038, 038 OF oDlgEve MESSAGE "Qual ação gostaria de executar para esse evento?" ACTION MsgInfo( 'Editando registro...','Teste' ) WHEN !EXCEVE->( EOF() )
    oMenEdt := TMenu():New(0,0,0,0,.T.)
    oItEdt1 := TMenuItem():New( oDlgEve, "Produto não faz parte do M.R.P.",,,,{|| Processa({|| fRemMRP() },"Aguarde!","Alterando configurações do M.R.P. do produto")},,,,,,,,,.T.)
    oItEdt2 := TMenuItem():New( oDlgEve, "Produto foi ou será descontinuado",,,,{|| fPrdDes() },,,,,,,,,.T.)
    oItEdt3 := TMenuItem():New( oDlgEve, "Produto comprado sob demanda",,,,{|| Nil /*fPrdDem()*/ },,,,,,,,,.T.)
    oItEdt4 := TMenuItem():New( oDlgEve, "Reprogramar entrega para...",,,,{|| fRepEnt() },,,,,,,,,.T.)
    oItEdt5 := TMenuItem():New( oDlgEve, "Ignorar necessidade de compra até...",,,,{|| fIgnore() },,,,,,,,,.T.)
    oItEdt7 := TMenuItem():New( oDlgEve, "Compra não será mais atendida",,,,{|| fCanPed() },,,,,,,,,.T.)
    oItEdt8 := TMenuItem():New( oDlgEve, "Ignorar apenas desta vez",,,,{|| fIgnore( .T. /*lPontual*/) },,,,,,,,,.T.)
    oMenEdt:Add( oItEdt1 )
    oMenEdt:Add( oItEdt2 )
    oMenEdt:Add( oItEdt3 )
    oMenEdt:Add( oItEdt4 )
    oMenEdt:Add( oItEdt5 )
    oMenEdt:Add( oItEdt6 )
    oMenEdt:Add( oItEdt7 )
    oMenEdt:Add( oItEdt8 )
    oBtnEdt := TButton():New( 003, 481, " ", oDlgEve,{||Alert("Definição das ações por evento")}, 019, 019,,,.F.,.T.,.F.,,.F.,,,.F. )
    oBtnEdt:SetPopupMenu(oMenEdt)
    
    @ 378, 962 BTNBMP oBtnMod RESNAME "fwskin_edit_ico.png" SIZE 038, 038 OF oDlgEve MESSAGE "Deseja editar a exceção selecionada?" ACTION MsgInfo( 'Editando registro...','Teste' ) WHEN !EXCEVE->( EOF() )
    @ 418, 962 BTNBMP oBtnExc RESNAME "fwskin_modal_close.png" SIZE 038, 038 OF oDlgEve MESSAGE "Deseja excluir a exceção selecionada?" ACTION MsgInfo( 'Excluindo registro...','Teste exclusao' ) WHEN !EXCEVE->( EOF() )
    @ 458, 962 BTNBMP oBtnSai RESNAME "final.png" SIZE 038, 038 OF oDlgEve MESSAGE "Pressione para sair..." ACTION oDlgEve:End() WHEN .T.
    
    ACTIVATE MSDIALOG oDlgEve CENTERED
	
	oTblExc:Delete()
	
Return ( Nil )

/*
+-----------------+-------------------------+---------------------------------+-------------------+
| Fonte: GMPAICOM | Funcao:  fCanPed        | Autor: Jean Carlos P. Saggin    |  Data: 23.11.2019 |
+-----------------+-------------------------+---------------------------------+-------------------+
| Descricao: Cancela os pedidos de compra em aberto para o produto através da rotina de eliminação|
|            de resíduo.                                                                          | 
+-------------------------------------------------------------------------------------------------+
| Parametros recebidos: Nenhum                                                                    |
+-------------------------------------------------------------------------------------------------+
| Retorno da funcao: Nil                                                                          |
+-------------------------------------------------------------------------------------------------+  
*/
Static Function fCanPed()
	
	Local nPerc      := 100					// Percentual de residuo a ser eliminado
	Local cTipo      := 1					// 1-Pedido, 2-Autor.Entrega, 3-Ambos
	Local dEmisDe    := StoD( Space( 8 ) )	// Filtrar da Data de Emissao de
	Local dEmisAte   := StoD( "20491231" )	// Filtrar da Data de Emissao Ate
	Local cCodigoDe  := ""					// Número do pedido De
	Local cCodigoAte := ""					// Número do pedido Até
	Local cProdDe    := ""					// Produto De
	Local cProdAte   := Replicate( 'Z', TAMSX3("C7_FORNECE")[1] )	// Produto Até
	Local cFornDe    := ""					// Fornecedor De
	Local cFornAte   := Replicate( 'Z', TAMSX3("C7_FORNECE")[1] )	// Fornecedor Ate
	Local dDatPrfDe  := StoD( Space( 8 ) )	// Data Previsão Fornecedor De
	Local dDatPrfAte := StoD( "20491231" )	// Data Previsão Fornecedor Até
	Local cItemDe    := ""					// Item De
	Local cItemAte   := ""					// Item Até
	Local lConsEIC   := .F.					// Filtra pedido de origem do EIC
	Local cQuery     := ""					// Guarda query para consulta dos pedidos
	Local cProd      := oEvent:aCols[ oEvent:nAt ][ aScan( oEvent:aHeader, {| x | AllTrim( x[02] ) == cZB3 +"_PROD" } ) ] 
	Local nPrd       := aScan( oEvent:aHeader, {|x| AllTrim( x[2] ) == cZB3 +"_PROD" } )
	Local nDat       := aScan( oEvent:aHeader, {|x| AllTrim( x[2] ) == cZB3 +"_DATA" } )
	
	// Busca os pedidos pendentes 
	cQuery := "SELECT C7.C7_NUM, C7.C7_ITEM, C7.C7_DATPRF, C7.C7_QUANT - C7.C7_QUJE EMPED, C7.C7_QUJE FROM "+ RetSqlName( 'SC7' ) +" C7 " + CEOL
    cQuery += "WHERE C7.C7_FILIAL  " + U_JSFILIAL( 'SC7', _aFil ) +" "+ CEOL 
    cQuery += "  AND C7.C7_PRODUTO = '"+ cProd +"' " + CEOL
    cQuery += "  AND C7.C7_RESIDUO <> 'S' " + CEOL
    cQuery += "  AND C7.C7_ENCER   <> 'E' " + CEOL
    cQuery += "  AND C7.C7_CONAPRO <> 'B' " + CEOL						// desconsidera se o pedido ainda estiver pendente de aprovação
    cQuery += "  AND C7.D_E_L_E_T_ = ' ' " + CEOL
	
	TcQuery cQuery New Alias "PDAJUS"
	DBSelectArea( "PDAJUS" )
	
	// Seta configurações dos campos do tipo data
	TcSetField( "PDAJUS","C7_DATPRF", "D" )
	
	IF !PDAJUS->( EOF() )
		
		Pergunte("MTA235",.F.)
		
		// Protege a transação de eliminação de resíduo
		BEGIN TRANSACTION 
			
			While !PDAJUS->( EOF() )
				
				cCodigoDe  := PDAJUS->C7_NUM 
				cCodigoAte := PDAJUS->C7_NUM
				cItemDe    := PDAJUS->C7_ITEM
				cItemAte   := PDAJUS->C7_ITEM
				
				Processa( {|| MA235PC(nPerc, cTipo, dEmisDe, dEmisAte, cCodigoDe, cCodigoAte, cProdDe,; 
						              cProdAte, cFornDe, cFornAte, dDatPrfDe, dDatPrfAte, cItemDe, cItemAte,; 
						              lConsEIC ) }, "Aguarde!","Eliminando resíduo do(s) pedido(s)..." )
				PDAJUS->( DBSkip() )
				
			EndDo
			
			// Grava justificativa no evento para que o mesmo seja desconsiderado da visualização
			DbSelectArea( cZB3 )
			(cZB3)->( DBSetOrder( 1 ) )
			If DBSeek( xFilial( cZB3 ) + oEvent:aCols[ oEvent:nAt ][ nPrd ] + DtoS( oEvent:aCols[ oEvent:nAt ][ nDat ] ) )
				RecLock( cZB3, .F. )
				(cZB3)->(FieldPut( FieldPos( cZB3 +'_JUSTIF' ), "007" ))		// Data de entrega reprogramada
				(cZB3)->(FieldPut( FieldPos( cZB3 +'_COMPL' ), "A COMPRA NAO SERA MAIS ATENDIDA PELO FORNECEDOR" ))	// Informações complementares da reprogramação de entrega com o fornecedor
				(cZB3)->( MsUnlock() )
			EndIf
			
		END TRANSACTION
		
		fGrdEve()
		
	EndIf
	PDAJUS->( DBCloseArea() )
	
Return ( Nil )

/*
+-----------------+-------------------------+---------------------------------+-------------------+
| Fonte: GMPAICOM | Funcao:  fStaIte        | Autor: Jean Carlos P. Saggin    |  Data: 23.11.2019 |
+-----------------+-------------------------+---------------------------------+-------------------+
| Descricao: Função para atualizar disponibilidade das ações x eventos                            | 
+-------------------------------------------------------------------------------------------------+
| Parametros recebidos: Nenhum                                                                    |
+-------------------------------------------------------------------------------------------------+
| Retorno da funcao: Nil                                                                          |
+-------------------------------------------------------------------------------------------------+  
*/
Static Function fStaIte()
	
	oItEdt1:lActive := !"COMPRA COM ATRASO" $ Upper( oEvent:aCols[ oEvent:nAT ][ aScan( oEvent:aHeader, { |x| AllTrim( x[2] ) == cZB3 +"_MSG" } ) ] )
    oItEdt2:lActive := !"COMPRA COM ATRASO" $ Upper( oEvent:aCols[ oEvent:nAT ][ aScan( oEvent:aHeader, { |x| AllTrim( x[2] ) == cZB3 +"_MSG" } ) ] )
    oItEdt3:lActive := !"COMPRA COM ATRASO" $ Upper( oEvent:aCols[ oEvent:nAT ][ aScan( oEvent:aHeader, { |x| AllTrim( x[2] ) == cZB3 +"_MSG" } ) ] ) 
    oItEdt4:lActive := "COMPRA COM ATRASO" $ Upper( oEvent:aCols[ oEvent:nAT ][ aScan( oEvent:aHeader, { |x| AllTrim( x[2] ) == cZB3 + "_MSG" } ) ] )
    oItEdt5:lActive := .T.
    oItEdt6:lActive := !"COMPRA COM ATRASO" $ Upper( oEvent:aCols[ oEvent:nAT ][ aScan( oEvent:aHeader, { |x| AllTrim( x[2] ) == cZB3 +"_MSG" } ) ] )
    oItEdt7:lActive := "COMPRA COM ATRASO" $ Upper( oEvent:aCols[ oEvent:nAT ][ aScan( oEvent:aHeader, { |x| AllTrim( x[2] ) == cZB3 +"_MSG" } ) ] )
    oItEdt8:lActive := .T.
	
	oDlgEve:Refresh()
	
Return ( Nil )

/*
+-----------------+-------------------------+---------------------------------+-------------------+
| Fonte: GMPAICOM | Funcao:  fRepEnt        | Autor: Jean Carlos P. Saggin    |  Data: 21.11.2019 |
+-----------------+-------------------------+---------------------------------+-------------------+
| Descricao: Função para realizar reprogramação da entrega do pedido com o fornecedor             | 
+-------------------------------------------------------------------------------------------------+
| Parametros recebidos: Nenhum                                                                    |
+-------------------------------------------------------------------------------------------------+
| Retorno da funcao: Nil                                                                          |
+-------------------------------------------------------------------------------------------------+  
*/
Static Function fRepEnt()
	
	Local cProd   := oEvent:aCols[ oEvent:nAt ][ aScan( oEvent:aHeader, {| x | AllTrim( x[02] ) == cZB3 +"_PROD" } ) ]
	Local nPrd    := aScan( oEvent:aHeader, {|x| AllTrim( x[2] ) == cZB3 +"_PROD" } )
	lOCAL nDat    := aScan( oEvent:aHeader, {|x| AllTrim( x[2] ) == cZB3 +"_DATA" } )
	local nFil    := aScan( oEvent:aHeader, {|x| AllTrim( x[2] ) == cZB3 +"_FILIAL" } )
	Local cQuery  := ""
	Local aPeds   := {}
	Local nX      := 0
	Local cStlBtn := ""
	Local oDlg    := Nil
	Local oLblDat := Nil
	Local oDatIgn := Nil
	Local dDatIgn := StoD( Space( 8 ) )
	Local oTexto  := Nil
	Local cTexto  := ""
	Local oClose  := Nil
	Local oSave   := Nil
	Local lRet    := .F.
	Local cAux    := ""
	Local dAux    := Nil
	Local aLin    := {}
	Local aIte    := {}
	
	Private lMsErroAuto := .F.
	
	// Busca os pedidos pendentes 
	cQuery := "SELECT C7.C7_FILIAL, C7.C7_NUM, C7.C7_ITEM, C7.C7_DATPRF, C7.C7_QUANT - C7.C7_QUJE EMPED, C7.C7_QUJE FROM "+ RetSqlName( 'SC7' ) +" C7 " + CEOL
    cQuery += "WHERE C7.C7_FILIAL  "+ U_JSFILIAL( 'SC7',_aFil  ) +" "+ CEOL 
    cQuery += "  AND C7.C7_PRODUTO = '"+ cProd +"' " + CEOL
    cQuery += "  AND C7.C7_RESIDUO <> 'S' " + CEOL
    cQuery += "  AND C7.C7_ENCER   <> 'E' " + CEOL
    cQuery += "  AND C7.C7_CONAPRO <> 'B' " + CEOL						// desconsidera se o pedido ainda estiver pendente de aprovação
    cQuery += "  AND C7.D_E_L_E_T_ = ' ' " + CEOL
	
	TcQuery cQuery New Alias "PDAJUS"
	DBSelectArea( "PDAJUS" )
	
	// Seta configurações dos campos do tipo data
	TcSetField( "PDAJUS","C7_DATPRF", "D" )
	
	IF !PDAJUS->( EOF() )
		aPeds := {}
		While !PDAJUS->( EOF() )
			
			if PDAJUS->C7_QUJE > 0
				MsgAlert( "O item <b>"+ PDAJUS->C7_ITEM +"</b> do pedido <b>"+ PDAJUS->C7_NUM +"</b> já "+;
				          "foi entregue parcialmente, portanto não pode ter a data de entrega alterada!","Quantidade já entregue" )
			Else
				aAdd( aPeds, { PDAJUS->C7_NUM, PDAJUS->C7_ITEM, PDAJUS->C7_DATPRF, PDAJUS->EMPED, PDAJUS->C7_FILIAL } )
			EndIf
			
			PDAJUS->( DBSkip() )
		EndDo
	EndIf
	PDAJUS->( DBCloseArea() )
	
	// Verifica se retornou conteúdo da leitura do banco
	If Len( aPeds ) > 0
		
		// Define o estilo dos botões da tela que será exibida				
		cStlBtn := "QPushButton { "
		cStlBtn += " margin: 2px; "
	    cStlBtn += " border-style: outset;"
	    cStlBtn += " border-width: 2px;"
	    cStlBtn += " border: 1px solid #C0C0C0;"
	    cStlBtn += " border-radius: 5px;"
	    cStlBtn += " border-color: #C0C0C0;"
	    cStlBtn += " font: bold 12px Arial;"
	    cStlBtn += " padding: 6px;"
	    cStlBtn += "}"
	    cStlBtn += "QPushButton:pressed {"
	    cStlBtn += " background-color: #e6e6f9;"
	    cStlBtn += " border-style: inset;"
	    cStlBtn += "}"
				
		// Abre caixa de diálogo solicitando para que o operador informe um texto complementar à justificativa
		DEFINE MSDIALOG oDlg TITLE "Dados complementares" FROM 000, 000  TO 220, 400 COLORS 0, 16777215 PIXEL
		
		@ 004, 002 SAY oLblDat PROMPT "Reprog. p/" SIZE 050, 007 OF oDlg COLORS 0, 16777215 PIXEL
		@ 002, 052 MSGET oDatIgn VAR dDatIgn SIZE 056, 010 VALID dDatIgn >= Date() OF oDlg COLORS 0, 16777215 PIXEL
		
		@ 016, 002 GET oTexto VAR cTexto MEMO SIZE 198, 072 OF oDlg COLORS 0, 16777215 PIXEL
		@ 180, 322 BTNBMP oClose SIZE 038, 038 OF oDlg RESNAME "fwskin_modal_close.png" MESSAGE "Cancelar?" ACTION oDlg:End()
		oClose:SetCss( cStlBtn )	
		
	    @ 180, 362 BTNBMP oSave  SIZE 038, 038 OF oDlg RESNAME "fwskin_chk_ckd.png" MESSAGE "Salvar" ACTION Processa( {|| lRet := .T., cAux := cTexto, dAux := dDatIgn, oDlg:End() },'Ok Pressed...','Continuando...')
	    oSave:SetCss( cStlBtn )

	    ACTIVATE MSDIALOG oDlg CENTERED
		
		// Verifica se existe alguma ação a ser tomada pelo sistema
		if lRet 
			
			If !Empty( cAux )
				
				if lRet
					
					lMsErroAuto := .F.
					
					BEGIN TRANSACTION
					
					// Percorre os pedidos encontrados alterando a data de previsão de entrega
					For nX := 1 to Len( aPeds )
						
						If lMsErroAuto
							Exit
						EndIf
						
						DBSelectArea( "SC7" )
						SC7->( DBSetOrder( 1 ) )		// C7_NUM + C7_ITEM
						If SC7->(DbSeek( aPeds[nX][5] + aPeds[nX][1] + aPeds[nX][2] ))
							
							aCab := {}
							aAdd( aCab, { "C7_FILIAL"  , SC7->C7_FILIAL } )
							aAdd( aCab, { "C7_NUM"     , SC7->C7_NUM } )
							aadd( aCab, { "C7_EMISSAO" , SC7->C7_EMISSAO })
							aadd( aCab, { "C7_FORNECE" , SC7->C7_FORNECE })
							aadd( aCab, { "C7_LOJA"    , SC7->C7_LOJA })
							aadd( aCab, { "C7_COND"    , SC7->C7_COND })
							aadd( aCab, { "C7_CONTATO" , SC7->C7_CONTATO })
							aadd( aCab, { "C7_FILENT"  , SC7->C7_FILENT })
							
							aLin := {}
							aIte := {}
							aAdd( aLin, { "C7_NUM"    , SC7->C7_NUM, Nil } )
							aAdd( aLin, { "C7_ITEM"   , SC7->C7_ITEM, Nil } )
							aAdd( aLin, { "C7_PRODUTO", SC7->C7_PRODUTO, Nil } )
							aAdd( aLin, { "C7_DATPRF" , dAux, Nil } )
							aAdd( aLin, { "C7_CONAPRO", SC7->C7_CONAPRO, Nil } )
							aAdd( aLin, { "C7_REC_WT" , SC7->(Recno()), Nil } )
						
							aAdd( aIte, aClone( aLin ) )
					
							Processa({|| MATA120( 1, aCab, aIte, 4/*nOpc*/, .F./*lShowDlg*/ ) }, "Alterando pedido "+ SC7->C7_NUM +;
					                      ", item "+ SC7->C7_ITEM +"...","Aguarde enquanto processo as alterações no pedido...")
					
							if lMsErroAuto 
								MostraErro()
								DisarmTransaction()
							EndIf
							
						Else
							lMsErroAuto := .T.
							Exit
						EndIf
						
					Next nX
					
					// Verifica se deu tudo certo
					If !lMsErroAuto
						
						// Grava justificativa no evento para que o mesmo seja desconsiderado da visualização
						DbSelectArea( cZB3 )
						(cZB3)->( DBSetOrder( 1 ) )
						If (cZB3)->(DBSeek( oEvent:aCols[oEvent:nAt][nFil] + oEvent:aCols[ oEvent:nAt ][ nPrd ] + DtoS( oEvent:aCols[ oEvent:nAt ][ nDat ] ) ))
							RecLock( cZB3, .F. )
							(cZB3)->( FieldPut( FieldPos( cZB3 +"_JUSTIF" ), "004" ) )			// Data de entrega reprogramada
							(cZB3)->( FieldPut( FieldPos( cZB3 + _COMPL  ), cAux ) )				// Informações complementares da reprogramação de entrega com o fornecedor
							(cZB3)->( MsUnlock() )
						EndIf
						
					EndIf
					
					END TRANSACTION
					fGrdEve()
					
				EndIf 
			
			Else
				MsgStop( "O texto complementar é obrigatório! Aproveite para descrever os detalhes da ação tomada junto do seu fornecedor!","Texto complementar é obrigatório!" )
				Return ( Nil )
			EndIf
			
		EndIf
		
	EndIf
	
Return ( Nil )

/*/{Protheus.doc} fLoadExc
Carrega exceções para geração de eventos no painel de compras. Essas exceções podem ou não ser
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 21/10/2019
@param cProduto, character, ID do produto (não obrigatório)
@param lNoInt, logical, Indica se está rodando sem interface
/*/
Static Function fLoadExc( cProduto, lNoInt )
	
	Local cQuery  := ""
	Local nQtdReg := 0
	
	Default cProduto := ""
	Default lNoInt   := .F.
	
	If Select( "EXCEVE" ) > 0
		DBSelectArea( "EXCEVE" )
		EXCEVE->( DBGoTop() )
		
		// Deleta as informações da tabela temporária para recarregar os dados
		if !EXCEVE->( EOF() )
			While !EXCEVE->( EOF() )
				
				RecLock( "EXCEVE", .F. )
				EXCEVE->( DBDelete() )
				EXCEVE->( MsUnlock() )
				
				EXCEVE->( DBSkip() )
			EndDo
		EndIf
	EndIf
	
	// Comando para leitura das exceções
	cQuery := "SELECT " + CEOL
	cQuery += "  "+ cZB6 +"_PROD PROD, B1.B1_DESC DESCRI, "+ cZB6 +"_DTLIM DTLIM, "+ cZB6 +"_DESCO DESCO, "+ cZB6 +"_DATA DATA, " + CEOL
	cQuery += "  "+ cZB6 +"_ULTTEN ULTTEN, "+ cZB6 +".R_E_C_N_O_ REC"+ cZB6 +" " + CEOL
	cQuery += "FROM "+ RetSqlName( cZB6 ) +" "+ cZB6 +" " + CEOL

	cQuery += "INNER JOIN "+ RetSqlName( "SB1" ) +" B1 " + CEOL
	cQuery += " ON B1.B1_FILIAL  " + U_JSFILIAL( 'SB1', _aFil ) +" "+ CEOL 
	cQuery += "AND B1.B1_COD     = "+ cZB6 +"."+ cZB6 +"_PROD " + CEOL
	cQuery += "AND B1.B1_MSBLQL  <> '1' " + CEOL
	cQuery += "AND B1.B1_MRP     = 'S' " + CEOL
	cQuery += "AND B1.D_E_L_E_T_ = ' ' " + CEOL

	cQuery += "WHERE "+ cZB6 +"."+ cZB6 +"_FILIAL "+ U_JSFILIAL( cZB6, _aFil ) +" "+ CEOL
	cQuery += "  AND "+ cZB6 +"."+ cZB6 +"_DTLIM  >= '"+ DtoS( Date() ) +"' " + CEOL
	cQuery += "  AND "+ cZB6 +".D_E_L_E_T_ = ' ' " + CEOL
  
	cQuery += "ORDER BY "+ cZB6 +"."+ cZB6 +"_DTLIM " + CEOL
	
	TcQuery cQuery New Alias "EXCEPT"
	DBSelectArea( "EXCEPT" )
	Count to nQtdReg
	
	TcSetField( "EXCEPT", "DTLIM" , "D" )
	TcSetField( "EXCEPT", "DATA"  , "D" )
	TcSetField( "EXCEPT", "ULTTEN", "D" )
	TCSetField( 'EXCEPT', 'DESCO' ,	'L' )
	
	EXCEPT->( DBGoTop() )
	
	if !EXCEPT->( EOF() )
		
		While !EXCEPT->( EOF() )
			
			RecLock( "EXCEVE", .T. )
			EXCEVE->( FieldPut( FieldPos( cZB6 +'_DATA' ), EXCEPT->DATA ) )
			EXCEVE->( FieldPut( FieldPos( cZB6 +'_PROD' ), EXCEPT->PROD ) )
			EXCEVE->( FieldPut( FieldPos( 'B1_DESC' ), EXCEPT->DESCRI ) )
			EXCEVE->( FieldPut( FieldPos( cZB6 +'_DTLIM' ), EXCEPT->DTLIM ) )
			EXCEVE->( FieldPut( FieldPos( cZB6 +'_DESCO' ), iif( EXCEPT->DESCO, "Sim", "Não" ) ) ) 
			EXCEVE->( FieldPut( FieldPos( cZB6 +'_ULTTEN' ), EXCEPT->ULTTEN  ) )
			EXCEVE->( FieldPut( FieldPos( 'REC'+ cZB6 ), EXCEPT->( FieldGet( FieldPos( 'REC'+ cZB6 ) ) ) ) )
			EXCEVE->( MsUnlock() )
			
			EXCEPT->( DBSkip() )
		EndDo
		
	EndIf
	EXCEPT->( DBCloseArea() )
	EXCEVE->( DBGoTop() )
	
	If !lNoInt
		oExcept:oBrowse:Refresh()
		oDlgEve:Refresh()
	EndIf
	
Return ( Nil )

/*
+-----------------+-------------------------+---------------------------------+-------------------+
| Fonte: GMPAICOM | Funcao:  fGrdEve        | Autor: Jean Carlos P. Saggin    |  Data: 13.08.2019 |
+-----------------+-------------------------+---------------------------------+-------------------+
| Descricao: Função para recarregar dados do grid de eventos pendentes                            |
+-------------------------------------------------------------------------------------------------+
| Parametros recebidos: Nenhum                                                                    |
+-------------------------------------------------------------------------------------------------+
| Retorno da funcao: Nil                                                                          |
+-------------------------------------------------------------------------------------------------+  
*/
Static Function fGrdEve( cExpr )
	
	Local nLinAtu := oEvent:nAt
	
	default cExpr  := ""

	fEvents( ,, cExpr )
	oEvent:aCols := aClone( aEvePen )
	oEvent:GoTo( nLinAtu )
	oEvent:ForceRefresh() 
	oDlgEve:Refresh()
	
Return ( Nil )

/*
+-----------------+-------------------------+---------------------------------+-------------------+
| Fonte: GMPAICOM | Funcao:  CHGEVENT       | Autor: Jean Carlos P. Saggin    |  Data: 09.08.2019 |
+-----------------+-------------------------+---------------------------------+-------------------+
| Descricao: Função executada na alteração de um campo do grid                                    |
+-------------------------------------------------------------------------------------------------+
| Parametros recebidos: Nenhum                                                                    |
+-------------------------------------------------------------------------------------------------+
| Retorno da funcao: lRet ( .T.=Continua execução ou .F.=Cancela execução )                       |
+-------------------------------------------------------------------------------------------------+  
*/
User Function CHGEVENT()
	
	Local lRet    := .F.
	Local nJus    := aScan( oEvent:aHeader, {|x| AllTrim( x[02] ) == cZB3 +"_JUSTIF" } )	 
	Local nDes    := aScan( oEvent:aHeader, {|x| AllTrim( x[02] ) == "DESCJUST" } )
	Local nPrd    := aScan( oEvent:aHeader, {|x| AllTrim( x[02] ) == cZB3 +"_PROD" } )
	Local nDat    := aScan( oEvent:aHeader, {|x| AllTrim( x[02] ) == cZB3 +"_DATA" } ) 
	local nFil    := aScan( oEvent:aHeader, {|x| AllTrim( x[02] ) == cZB3 +"_FILIAL" } ) 
	Local lCom    := .F.
	Local oClose  := Nil
	Local oTexto  := Nil
	Local oSave   := Nil
	Local oDlg    := Nil
	Local oLblDat := Nil
	Local oDatIgn := Nil
	Local cAction := ""
	local aOption := {} as array
	
	Private cTexto  := ""
	Private dDatIgn := DataValida( Date() +1, .T. )
	
	// Verifica as justificativas possíveis
	aOption := getOptions()

	// Valida se a alteração está sendo feita no campo da justificativa
	If oEvent:oBrowse:ColPos() == nJus
		
		// Verifica se a justificativa precisa de complemento
		lCom    := aOption[ aScan( aOption, {|x| x[1] == &("M->"+cZB3 +"_JUSTIF") } ) ][4]

		// Identifica a ação que o sistema deve executar ao selecionar a justificativa
		cAction := AllTrim( aOption[ aScan( aOption, {|x| x[1] == &("M->"+cZB3 +"_JUSTIF") } ) ][3] )
		
		if lCom

			// Abre caixa de diálogo solicitando para que o operador informe um texto complementar à justificativa
			DEFINE MSDIALOG oDlg TITLE "Complemento da justificativa selecionada" FROM 000, 000  TO 220, 400 COLORS 0, 16777215 PIXEL
			
			@ 004, 002 SAY oLblDat PROMPT "Ignorar até..." SIZE 050, 007 OF oDlg COLORS 0, 16777215 PIXEL
			@ 002, 052 MSGET oDatIgn VAR dDatIgn SIZE 056, 010 OF oDlg COLORS 0, 16777215 PIXEL
			@ 016, 002 GET oTexto VAR cTexto MEMO SIZE 198, 072 OF oDlg COLORS 0, 16777215 PIXEL
			@ 180, 322 BTNBMP oClose SIZE 038, 038 OF oDlg RESNAME "fwskin_modal_close.png" MESSAGE "Cancelar?" ACTION oDlg:End()
			@ 180, 362 BTNBMP oSave  SIZE 038, 038 OF oDlg RESNAME "fwskin_chk_ckd.png" MESSAGE "Salvar" ACTION Processa( {|| lRet := .T., oDlg:End() },'Ok Pressed...','Continuando...') WHEN !Empty( cTexto )

		    ACTIVATE MSDIALOG oDlg CENTERED
		
		Else
			lRet := .T.
		EndIf
		
	EndIf
	
	// Verifica se existe alguma ação a ser tomada pelo sistema
	if lRet .and. !Empty( cAction )
		
		// Executa ação relacionada ao 
		Processa( {|| lRet := &( cAction ) }, 'Aguarde!','Realizando ações para melhorar a análise do produto...' )
		
		if lRet
			
			// Atualiza descrição da justificativa
			oEvent:aCols[ oEvent:nAt ][ nDes ] := AllTrim( aOption[ aScan( aOption, {|x| x[1] == &("M->"+cZB3 +"_JUSTIF") } ) ][2] )
			DbSelectArea( cZB3 )
			(cZB3)->( DBSetOrder( 1 ) )
			If DBSeek( oEvent:aCols[oEvent:nAt][nFil] + oEvent:aCols[ oEvent:nAt ][ nPrd ] + DtoS( oEvent:aCols[ oEvent:nAt ][ nDat ] ) )
				RecLock( cZB3, .F. )
				(cZB3)->( FieldPut( FieldPos( cZB3 +'_JUSTIF' ), &("M->"+ cZB3 +"_JUSTIF") ) )
				(cZB3)->( MsUnlock() )
			EndIf
			
		EndIf 
	EndIf
	
Return ( lRet )

/*/{Protheus.doc} FREMMRP
Função para remover produto dos cálculos do MRP
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 10/08/2019
/*/
Static Function FREMMRP()
	
	Local nPrd  := aScan( oEvent:aHeader, {|x| AllTrim( x[2] ) == cZB3 +"_PROD" } )
	Local nDat  := aScan( oEvent:aHeader, {|x| AllTrim( x[2] ) == cZB3 +"_DATA" } )
	local nFil  := aScan( oEvent:aHeader, {|x| AllTrim( x[2] ) == cZB3 +"_FILIAL" } )
	
	Private lMsErroAuto := .F.
	
	MSExecAuto({|x, y| Mata010(x, y)}, {{"B1_FILIAL", oEvent:aCols[oEvent:nAt][nFil], Nil },;
	                                    {"B1_COD"   , oEvent:aCols[oEvent:nAt][nPrd], Nil },;
	                                    {"B1_MRP"   , 'N'                           , Nil }}, 4 )
	if lMsErroAuto
		MostraErro()
	Else
		// Grava justificativa no evento para que o mesmo seja desconsiderado da visualização
		DbSelectArea( cZB3 )
		(cZB3)->( DBSetOrder( 1 ) )
		If DBSeek( oEvent:aCols[oEvent:nAt][nFil] + oEvent:aCols[ oEvent:nAt ][ nPrd ] + DtoS( oEvent:aCols[ oEvent:nAt ][ nDat ] ) )
			RecLock( cZB3, .F. )
			(cZB3)->( FieldPut( FieldPos( cZB3 +'_JUSTIF' ), "001" ) )		// Produto desconsiderado do M.R.P.
			(cZB3)->( FieldPut( FieldPos( cZB3 +'_COMPL' ), "PRODUTO REMOVIDO DO M.R.P" ) )	// Informações complementares da reprogramação de entrega com o fornecedor
			(cZB3)->( MsUnlock() )
		EndIf	
	EndIf
	fGrdEve()
	
Return ( Nil )

/*
+-----------------+-------------------------+---------------------------------+-------------------+
| Fonte: GMPAICOM | Funcao:  FPRDDES        | Autor: Jean Carlos P. Saggin    |  Data: 10.08.2019 |
+-----------------+-------------------------+---------------------------------+-------------------+
| Descricao: Função para sinalizar produto para ser descontinuado assim que ficar sem estoque     |
+-------------------------------------------------------------------------------------------------+
| Parametros recebidos: Nil                                                                       |
+-------------------------------------------------------------------------------------------------+
| Retorno da funcao: lRet                                                                         |
+-------------------------------------------------------------------------------------------------+  
*/
Static Function FPRDDES()
	
	Local nPrd  := aScan( oEvent:aHeader, {| x | AllTrim( x[02] ) == cZB3 +"_PROD" } )
	Local nDat  := aScan( oEvent:aHeader, {| x | AllTrim( x[02] ) == cZB3 +"_DATA" } )
	local nFil  := aScan( oEvent:aHeader, {| x | AllTrim( x[02] ) == cZB3 +"_FILIAL" } )
	
	DBSelectArea( cZB6 )
	( cZB6 )->( DbSetOrder( 1 ) )
	If !DbSeek( oEvent:aCols[oEvent:nAt][nFil] + oEvent:aCols[oEvent:nAt][nPrd]  )
		
		RecLock( cZB6, .T. )
		(cZB6)->( FieldPut( FieldPos( cZB6 +'_FILIAL' ), oEvent:aCols[oEvent:nAt][nFil] ) )
		(cZB6)->( FieldPut( FieldPos( cZB6 +'_PROD'   ), oEvent:aCols[oEvent:nAt][nPrd] ) )
		(cZB6)->( FieldPut( FieldPos( cZB6 +'_DATA'   ), Date() ) )
		(cZB6)->( FieldPut( FieldPos( cZB6 +'_DTLIM'  ), StoD( '20491231' ) ) )
		(cZB6)->( FieldPut( FieldPos( cZB6 +'_COMPL'  ), ""  ) ) 		
		(cZB6)->( FieldPut( FieldPos( cZB6 +'_ULTTEN' ), StoD( Space( 8 ) ) ) )
		(cZB6)->( FieldPut( FieldPos( cZB6 +'_DESCO'  ), .T. ) )  							// Evento referente a descontinuidade do produto

		(cZB6)->( MsUnlock() )
	EndIf
	
	// Grava justificativa no evento para que o mesmo seja desconsiderado da visualização
	DbSelectArea( cZB3 )
	(cZB3)->( DBSetOrder( 1 ) )
	If DBSeek( oEvent:aCols[oEvent:nAt][nFil] + oEvent:aCols[ oEvent:nAt ][ nPrd ] + DtoS( oEvent:aCols[ oEvent:nAt ][ nDat ] ) )
		RecLock( cZB3, .F. )
		(cZB3)->( FieldPut( FieldPos( cZB3 +'_JUSTIF' ), "002" ) ) 			// Produto foi ou será descontinuado
		(cZB3)->( FieldPut( FieldPos( cZB3 +'_COMPL' ), "PRODUTO SERA DESCONTINUADO, ALIMENTADO REGISTRO DE EXCECAO ATE QUE O ESTOQUE DO MESMO SE ESGOTE" ) )	// Informações complementares da reprogramação de entrega com o fornecedor
		(cZB3)->( MsUnlock() )
	EndIf	
	
	// Valida existência da função que realiza análise e inativação do produto quando o mesmo não tem mais saldo em estoque
	if FindFunction( 'U_GMPRDDES' )
		U_GMPRDDES( oEvent:aCols[oEvent:nAt][nPrd] )
	Endif
	
	Processa( {|| fGrdEve() }, "Aguarde!", "Recarregando eventos..." )
	Processa( {|| fLoadExc() }, "Aguarde!", "Verificando exceções ativas..." )
	
Return ( Nil )

/*
+-----------------+-------------------------+---------------------------------+-------------------+
| Fonte: GMPAICOM | Funcao:  GMPRDDES       | Autor: Jean Carlos P. Saggin    |  Data: 12.08.2019 |
+-----------------+-------------------------+---------------------------------+-------------------+
| Descricao: Rotina para analisar produto sinalizado para ser descontinuado e ver se é possível   |
|            inativá-lo.                                                                          |
+-------------------------------------------------------------------------------------------------+
| Parametros recebidos: cProd                                                                     |
| cProd: Codigo do produto a ser analisado, caso não for informado código, serão analisados todos |
|        os produtos da tabela de controle de eventos cujo registro esteja sinalizado para descon-|
|        tinuidade.                                                                               |
+-------------------------------------------------------------------------------------------------+
| Retorno da funcao: Nil                                                                          |
+-------------------------------------------------------------------------------------------------+  
*/
User Function GMPRDDES( cProd )
	
	Local cQuery   := ""
	Local aAux     := {}
	Local nX       := 0
	Local cLocais  := ""
	Local cArqHtml := "\workflow\mensagem.html"
	Local cBody    := ""
	Local cTmp     := ""
	Local oFile    := Nil
	Local aUsrNot  := StrToKArr( aConfig[17], '/' )
	
	Private lMsErroAuto := .F.
	
	Default cProd := "" 
	
	// Valida existência de armazéns configurados nos parâmetros no painel de compras
	if !Empty( aConfig[16] )
		
		// Monta string referente aos armazens que serão utilizados para somatório dos saldos dos produtos
		aAux    := StrTokArr( Upper( AllTrim( aConfig[16] ) ), '/' )
		cLocais := ""
		For nX := 1 to Len( aAux )
			cLocais += PADR( AllTrim( aAux[nX] ), TAMSX3('B2_LOCAL')[01], ' ') + iif( nX == Len(aAux),'',"','" )
		Next nX
		
		DbSelectArea( cZB6 )
		(cZB6)->( DbSetOrder( 1 ) )
		
		cQuery := "SELECT " + CEOL
		cQuery += cZB6 +"."+ cZB6 +"_FILIAL, " + CEOL
		cQuery += cZB6 +"."+ cZB6 +"_PROD, B1.B1_DESC, B1.B1_UM, "+ cZB6 +".R_E_C_N_O_ REC"+ cZB6 +","
		cQuery += " "+ cZB6 +"."+ cZB6 +"_ULTTEN, SUM( COALESCE( B2.B2_QATU, 0) ) SALDO FROM "+ RetSqlName( cZB6 ) +" "+ cZB6 +" " + CEOL
		
		// Liga com cadastro de produto
        cQuery += "INNER JOIN "+ RetSqlName( 'SB1' ) +" B1 " + CEOL
        cQuery += " ON B1.B1_FILIAL  " + U_JSFILIAL( 'SB1', _aFil ) +" "+ CEOL
        cQuery += "AND B1.B1_COD     = "+ cZB6 +"."+ cZB6 +"_PROD " + CEOL
        cQuery += "AND B1.B1_MSBLQL  <> '1' " + CEOL						// Apenas produtos não bloqueados
        cQuery += "AND B1.D_E_L_E_T_ = ' ' " + CEOL
        
        // Relaciona com saldo de estoque do produto
        cQuery += "LEFT JOIN "+ RetSqlName( 'SB2' ) +" B2 " + CEOL
        cQuery += " ON B2.B2_FILIAL " + U_JSFILIAL( 'SB2', _aFil ) +" "+ CEOL
        cQuery += "AND B2.B2_COD     = B1.B1_COD " + CEOL
        cQuery += "AND B2.B2_LOCAL   IN ( '"+ cLocais +"' ) " + CEOL		// Armazéns que o painel de compras leva em consideração para compor saldo do produto
        cQuery += "AND B2.D_E_L_E_T_ = ' ' " + CEOL

        cQuery += "WHERE "+ cZB6 +"."+ cZB6 +"_FILIAL " + U_JSFILIAL( cZB6, _aFil ) +" "+ CEOL
        
        // Filtra apenas o produto que veio via parâmetro
        if !Empty( cProd )
        	cQuery += "  AND "+ cZB6 +"."+ cZB6 +"_PROD   = '"+ cProd +"' " + CEOL
        EndIf
        cQuery += "  AND "+ cZB6 +"."+ cZB6 +"_DTLIM  >= '"+ DtoS( Date() ) +"' " + CEOL	// Apenas as exceções com data limite maior ou igual a (hoje)
        cQuery += "  AND "+ cZB6 +"."+ cZB6 +"_DESCO  = 'T' " + CEOL						// Apenas os eventos que são para descontinuidade de produtos
        cQuery += "  AND "+ cZB6 +".D_E_L_E_T_ = ' ' " + CEOL  

        cQuery += "GROUP BY "+ cZB6 +"."+ cZB6 +"_FILIAL, "+ cZB6 +"."+ cZB6 +"_PROD, B1.B1_DESC, B1.B1_UM, "+ cZB6 +".R_E_C_N_O_, "+ cZB6 +"."+ cZB6 +"_ULTTEN " + CEOL
		
        TcQuery cQuery new Alias "DESC"
        DbSelectArea( 'DESC' )
        
        if !DESC->( EOF() )
        	While !DESC->( EOF() )
        		
        		if DESC->SALDO == 0
        			
        			lMsErroAuto := .F.
        			MSExecAuto({|x, y| Mata010(x, y)}, {{"B1_FILIAL", DESC->( FieldGet( FieldPos( cZB6 +'_FILIAL' ) ) ), Nil },;
					                                    {"B1_COD"   , DESC->( FieldGet( FieldPos( cZB6 +'_PROD' ) ) ), Nil },;
					                                    {"B1_MRP"   , 'N'             , Nil },;
					                                    {"B1_MSBLQL", '1'             , Nil } }, 4 )
					if lMsErroAuto .and. !Empty( cProd )
						MostraErro()
					Elseif lMsErroAuto
						ConOut( 'GMPRDDES - '+ DtoC( Date() ) + ' - ' + Time() + ' - Erro durante execauto para inativacao do produto codigo '+ DESC->( FieldGet( FieldPos( cZB6 +'_PROD' ) ) ) )
					EndIf
					
        		ElseIf StoD( DESC->( FieldGet( FieldPos( cZB6 +'_ULTTEN' ) ) ) ) < ( Date() - 30 )			// Verifica se o último aviso de que o produto está sendo inativado foi enviado a mais de 30 dias
        			
        			if Len( aUsrNot ) > 0
        				
        				For nX := 1 to Len( aUsrNot )
        				
		        			cBody := ""
							cTmp  := ""
							oFile := FWFileReader():New( cArqHtml )
							if oFile:Open()
								// Percorre todo o arquivo e joga o conteúdo de cada linha em variável temporária
								While oFile:hasLine()
									cBody += AllTrim( oFile:GetLine( .T. ) )
								EndDo
								// Fecha arquivo após processamento
								oFile:Close()
							EndIf
		        			
		        			if !Empty( cBody )
											
								cBody := StrTran( cBody, '%NOTIFICACAO%', OemToAnsi( 'DESCONTINUIDADE DO PRODUTO '+ AllTrim( DESC->B1_DESC ) + ' ( '+ AllTrim( DESC->( FieldGet( FieldPos( cZB6 +'_PROD' ) ) ) ) +' ) ' ) )
								cBody := StrTran( cBody, '%MENSAGEM%', OemToAnsi( "O produto "+ AllTrim( DESC->B1_DESC ) + ' ( '+ AllTrim( DESC->( FieldGet( FieldPos( cZB6 +'_PROD' ) ) ) ) +;
								                 ' ) foi sinalizado como descontinuado, entretanto, ainda consta(m) ' + AllTrim( Transform( DESC->SALDO, '@E 9,999,999.99' ) ) +;
								                 ' ' + DESC->B1_UM + ' desse produto em estoque! Evite que esse produto se torne obsoleto realizando campanhas de venda ou aumentando a divulgação!' ) )
								
							EndIf
							
							if !Empty( cBody ) .and. FindFunction( 'U_GMGERNOT' ) .and. !Empty( aUsrNot[nX] )
								U_GMGERNOT( Lower( aUsrNot[nX] ), Upper( 'DESCONTINUIDADE DO PRODUTO '+ AllTrim( DESC->B1_DESC ) ), cBody )
							EndIf
							
							FreeObj( oFile )
							
						Next nX
						
					EndIf
					
					// Grava data da última tentativa de inativação do produto
        			DbSelectArea( cZB6 )
        			(cZB6)->( DbGoTo( DESC->( FieldGet( FieldPos( 'REC'+ cZB6 ) ) ) ) )
        			RecLock( cZB6, .F. )
        			(cZB6)->( FieldPut( FieldPos( cZB6 +'_ULTTEN' ), Date() ) )
        			(cZB6)->( MsUnlock() )
        			
        		EndIf
        		
        		DESC->( DbSkip() )
        	EndDo
        EndIf
		
		DESC->( DbCloseArea() )
		
	EndIf
		  
Return ( Nil )

/*
+-----------------+-------------------------+---------------------------------+-------------------+
| Fonte: GMPAICOM | Funcao:  fLegenda       | Autor: Jean Carlos P. Saggin    |  Data: 01.08.2019 |
+-----------------+-------------------------+---------------------------------+-------------------+
| Descricao: Função para exibição de legendas do painel de compras                                |
+-------------------------------------------------------------------------------------------------+
| Parametros recebidos: nenhum                                                                    |
+-------------------------------------------------------------------------------------------------+
| Retorno da funcao: Nil                                                                          |
+-------------------------------------------------------------------------------------------------+  
*/
Static Function fLegenda()
	
	Local cTitulo := ""
	Local aCores  := {}
	
	if IsInCallStack( "fPedFor" )			// Itens de pedidos pendentes
		aCores := {{ 'BR_VERDE'     , "Item liberado"   		},;
					{ 'BR_AZUL'		, "Aguardando aprovação"	}}
		cTitulo := OemtoAnsi("Itens de pedidos pendentes")
	Else									// Legenda da janela principal
		aCores := { { LG_CRITICO, "Itens críticos"   		},;
					{ LG_ALTO  	, "Itens de alto giro"		},;
					{ LG_MEDIO	, "Itens de médio giro"		},; 
					{ LG_BAIXO	, "Itens de baixo giro" 	},;
					{ LG_SEMGIRO, "Itens sem giro"		 	},; 
					{ LG_SOLICIT, "Itens por solicitação"   }}											
		
		cTitulo := OemtoAnsi("Legenda dos Produtos")	
	EndIf										
	BrwLegenda( cTitulo, "Legendas", aCores)
	
Return ( Nil )

/*/{Protheus.doc} fPedFor
Função para exibição dos pedidos em aberto por fornecedor ou produto
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 8/1/2019
@param nOpc, numeric, 1=Pedido por fornecedor ou 2=Pedido por Item
/*/
Static Function fPedFor( nOpc )
	
	Local oBtnFec
	Local oGetDes
	Local cGetDes   := aColPro[ oBrwPro:nAt ][ nPosDes ]
	Local oGetPrd
	Local cGetPrd   := aColPro[ oBrwPro:nAt ][ nPosPrd ]
	Local oLblPrd   := 0
	Local nX        := 0
	Local aHeaderEx := {}
	Local aFields   := {"C7_FILIAL", "NUMERO","C7_ITEM","C7_QUANT","SALDO","C7_PRECO","C7_TOTAL","C7_DATPRF","C7_FORNECE","C7_LOJA","A2_NOME"}
	Local aAlter    := {}
	Local cTitulo   := "Pedidos em aberto"
	Local oBtnLeg   := Nil
	local oBtnImp   as object
	local oBtnMail  as object
	local nPosBtn   := 0 as numeric
	
	Private aColsEx := {}
	Private oGrid   := Nil
	Private oDlgPed := Nil
	
	default nOpc := 2		// Por item

	cTitulo += iif( nOpc == 1, ' com o fornecedor '+;
	           AllTrim( RetField( 'SA2', 1, xFilial( 'SA2' ) + aColPro[ oBrwPro:nAt ][ nPosFor ] + aColPro[ oBrwPro:nAt ][ nPosLoj ], 'A2_NOME' )),;
	           ' referente ao produto' )
	
	// Define campo de legenda manualmente
	aAdd( aHeaderEx, { " ","LEGENDA", "@BMP",02, 00, ".F.","", "C", "", "V" ,"" , "","","V" } )

	// Define as configurações dos campos do grid
  	For nX := 1 to Len(aFields)
        if aFields[nX] == "SALDO"
        	aAdd( aHeaderEx, { 'Saldo', "SALDO", "@E 999,999.99", 11, 2, , , "N", ,"V", , } )
        ElseIf aFields[nX] == "NUMERO"
        	aAdd( aHeaderEx, { 'Numero', "NUMERO", "@!", 06, 0, , , "C", ,"V", , } )
		else
			aAdd( aHeaderEx, { AllTrim( GetSX3Cache( aFields[nX], 'X3_TITULO' ) ),;
							   GetSX3Cache( aFields[nX], 'X3_CAMPO' ),;
							   GetSX3Cache( aFields[nX], 'X3_PICTURE' ),;
							   GetSX3Cache( aFields[nX], 'X3_TAMANHO' ),;
							   GetSX3Cache( aFields[nX], 'X3_DECIMAL' ),;
							   GetSX3Cache( aFields[nX], 'X3_VALID' ),;
							   GetSX3Cache( aFields[nX], 'X3_USADO' ),;
							   GetSX3Cache( aFields[nX], 'X3_TIPO' ),;
							   GetSX3Cache( aFields[nX], 'X3_F3' ),;
							   GetSX3Cache( aFields[nX], 'X3_CONTEXT' ),;
							   GetSX3Cache( aFields[nX], 'X3_CBOX' ),;
							   GetSX3Cache( aFields[nX], 'X3_RELACAO' ) } )
        EndIf
    Next nX
	
	DEFINE MSDIALOG oDlgPed TITLE cTitulo FROM 000, 000  TO 300, 1000 COLORS 0, 16777215 PIXEL

    oGrid := MsNewGetDados():New( 018, 002, 134, 500, GD_UPDATE, "AllwaysTrue", "AllwaysTrue", "", aAlter,, Len( aColsEx ),;
	 "AllwaysTrue", "", "AllwaysTrue", oDlgPed, aHeaderEx, aColsEx )
    
    @ 004, 002 SAY oLblPrd PROMPT "Produto: " SIZE 035, 007 OF oDlgPed COLORS 0, 16777215 PIXEL
    @ 002, 043 MSGET oGetPrd VAR cGetPrd SIZE 059, 012 OF oDlgPed WHEN .F. COLORS 0, 16777215 PIXEL
    @ 002, 104 MSGET oGetDes VAR cGetDes SIZE 214, 012 OF oDlgPed WHEN .F. COLORS 0, 16777215 PIXEL
    
	nPosBtn := iif( AllTrim(SuperGetMv( "MV_ENVPED",, '0')) $ '1|2', 336, 375 )
    @ 136, nPosBtn BUTTON oBtnLeg  PROMPT "&Legenda"  SIZE 037, 012 OF oDlgPed ACTION fLegenda() PIXEL
	nPosBtn+= 39
	@ 136, nPosBtn BUTTON oBtnMail PROMPT "&Enviar E-mail" SIZE 045, 012 OF oDlgPed ACTION sndMail( oGrid:aCols[oGrid:nAt][ColPos(oGrid,'NUMERO')] ) PIXEL
	nPosBtn += 47
	@ 136, nPosBtn BUTTON oBtnImp  PROMPT "&Imprimir" SIZE 037, 012 OF oDlgPed ACTION iif( Len(oGrid:aCols) > 0, GMPCPRINT( oGrid:aCols[oGrid:nAt][ColPos(oGrid,'NUMERO')] ), Nil) PIXEL
	nPosBtn += 39
    @ 136, nPosBtn BUTTON oBtnFec  PROMPT "&Fechar"   SIZE 037, 012 OF oDlgPed ACTION oDlgPed:End() PIXEL
    
    ACTIVATE MSDIALOG oDlgPed CENTERED ON INIT ;
	Processa( {|| fPedPen( .F./*lNoInt*/, nOpc, aColPro[ oBrwPro:nAt ][ nPosPrd ] /*cProd*/ ) }, 'Aguarde!','Buscando pedidos não atendidos!' )
	
Return ( Nil )

/*/{Protheus.doc} sndMail
Função que envia e-mail para o fornecedor
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/14/2024
@param cPedido, character, ID do pedido
/*/
static function sndMail( cPedido )

	Private l120Auto  := .F. as logical
	Private aRotina   := {}  as array
	Private INCLUI    := .F. as logical
	Private ALTERA    := .F. as logical
	Private nTipoPed  := 1 // 1-Pedido de compra 2-Autorizacao Entrega
	Private cCadastro := "Pedidos de Compra"
	
	aAdd(aRotina,{"Pesquisar","PesqBrw"   , 0, 1, 0, .F. }) //"Pesquisar"
	aAdd(aRotina,{"Visualizar","A120Pedido", 0, 2, 0, Nil }) //"Visualizar"
	aAdd(aRotina,{"Incluir","A120Pedido", 0, 3, 0, Nil }) //"Incluir"
	aAdd(aRotina,{"ALterar","A120Pedido", 0, 4, 6, Nil }) //"Alterar"
	aAdd(aRotina,{"Excluir","A120Pedido", 0, 5, 7, Nil }) //"Excluir"
	aAdd(aRotina,{"Copia","A120Copia" , 0, 4, 0, Nil }) //"Copia"
	aAdd(aRotina,{"Reenvia e-mail","A120Mail"  , 0, 2, 0, Nil }) //"Reenvia e-mail"
	aAdd(aRotina,{"Imprimir","A120Impri" , 0, 2, 0, Nil }) //"Imprimir"
	aAdd(aRotina,{"Legenda","A120Legend", 0, 1, 0, .F. }) //"Legenda"
	aAdd(aRotina,{"Conhecimento","MsDocument", 0, 4, 0, Nil }) //"Conhecimento"}

	DBSelectArea( 'SC7' )
	SC7->( DBSetOrder( 1 ) )
	if DBSeek( FWxFilial( 'SC7' ) + cPedido )
		A120Mail("SC7", SC7->( Recno() ), 2 )
	endif
return Nil

/*/{Protheus.doc} colPos
Função para capturar a posição de um campo em objetos do tipo getDados
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 6/7/2022
@param oObj, object, objeto do tipo getDados
@param cField, character, nome da coluna a ser retornada
@return numeric, nPos
/*/
static function colPos( oObj, cField )
return aScan( oObj:aHeader, {|x| AllTrim( x[2] ) == cField } )

/*
+-----------------+-------------------------+---------------------------------+-------------------+
| Fonte: GMPAICOM | Funcao:  fPedPen        | Autor: Jean Carlos P. Saggin    |  Data: 01.08.2019 |
+-----------------+-------------------------+---------------------------------+-------------------+
| Descricao: Função para atualizar grid de pedidos pendentes referente ao produto                 |
+-------------------------------------------------------------------------------------------------+
| Parametros recebidos: lNoInt, nOpc, cProd                                                       |
| lNotInt - Indica se a função foi chamada sem interface criada .T.=Sem Interface ou .F.=Com Int. |
| nOpc - 1=Exibe pedidos pendentes do produto com o fornecedor ou 2=Exibe pedidos pendentes para  |
|        o produto                                                                                |
| cProd - Codigo do produto que está sendo analisado                                              |
+-------------------------------------------------------------------------------------------------+
| Retorno da funcao: Nil                                                                          |
+-------------------------------------------------------------------------------------------------+  
*/
Static Function fPedPen( lNoInt, nOpc, cProd )
	
	Local cQuery := ""
	
	Default lNoInt := .F.
	
	cQuery += "SELECT C7.C7_FILIAL, C7.C7_NUM NUMERO, C7_ITEM, C7_CONAPRO, SUM( C7.C7_QUANT ) C7_QUANT, SUM(C7.C7_QUANT - C7.C7_QUJE) SALDO, C7.C7_PRECO, SUM( C7.C7_TOTAL ) C7_TOTAL, " + CEOL
	cQuery += "       C7.C7_DATPRF, C7.C7_FORNECE, C7.C7_LOJA, A2.A2_NOME " + CEOL
	cQuery += "FROM "+ RetSqlName( 'SC7' ) +" C7 " + CEOL
	
	cQuery += "INNER JOIN "+ RetSqlName( 'SB1' ) +" B1 "+ CEOL
	cQuery += " ON B1.B1_FILIAL  "+ U_JSFILIAL( "SB1", _aFil ) +" "+ CEOL
	cQuery += "AND B1.B1_COD     = C7.C7_PRODUTO " + CEOL
	cQuery += "AND B1.D_E_L_E_T_ = ' ' " + CEOL
	
	cQuery += "INNER JOIN "+ RetSqlName( 'SA2' ) +" A2 " + CEOL
	cQuery += " ON A2.A2_FILIAL " + U_JSFILIAL( "SA2", _aFil ) +" "+ CEOL
	cQuery += "AND A2.A2_COD     = C7.C7_FORNECE " + CEOL
	cQuery += "AND A2.A2_LOJA    = C7.C7_LOJA "+ CEOL
	
	if nOpc == 1
		cQuery += "  AND A2.A2_COD  = B1.B1_PROC " + CEOL
		cQuery += "  AND A2.A2_LOJA = B1.B1_LOJPROC " + CEOL
	EndIf
	
	cQuery += "AND A2.D_E_L_E_T_ = ' ' " + CEOL
	
    cQuery += "WHERE C7.C7_FILIAL "+ U_JSFILIAL( 'SC7', _aFil ) +" "+ CEOL
    cQuery += "  AND C7.C7_PRODUTO = '"+ cProd +"' " + CEOL
    cQuery += "  AND C7.C7_RESIDUO <> 'S' " + CEOL
    cQuery += "  AND C7.C7_ENCER   <> 'E' " + CEOL
    cQuery += "  AND C7.D_E_L_E_T_ = ' ' " + CEOL
    
    cQuery += "GROUP BY C7.C7_FILIAL, C7.C7_NUM, C7.C7_ITEM, C7_CONAPRO, C7.C7_PRECO, C7.C7_DATPRF, C7.C7_FORNECE, C7.C7_LOJA, A2.A2_NOME " + CEOL
    cQuery += "ORDER BY C7.C7_FILIAL, C7.C7_DATPRF, C7.C7_NUM " + CEOL
    
	TcQuery cQuery New Alias 'PEDTMP'
	DbSelectArea( 'PEDTMP' )
	
	// Seta o tipo de conteúdo dos campos quando for data
    TcSetField( 'PEDTMP', 'C7_DATPRF', 'D' )
	
	PEDTMP->( DbGoTop() )
	
	If !PEDTMP->( EOF() )
		aColsEx := {}
		While !PEDTMP->( EOF() )
			
			aAdd( aColsEx, { iif( PEDTMP->C7_CONAPRO == 'B', "BR_AZUL", "BR_VERDE" ),;
							 PEDTMP->C7_FILIAL,;
			                 PEDTMP->NUMERO,;
			                 PEDTMP->C7_ITEM,;
			                 PEDTMP->C7_QUANT,;
			                 PEDTMP->SALDO,;
			                 PEDTMP->C7_PRECO,;
			                 PEDTMP->C7_TOTAL,;
			                 PEDTMP->C7_DATPRF,;
			                 PEDTMP->C7_FORNECE,;
			                 PEDTMP->C7_LOJA,;
			                 PEDTMP->A2_NOME,;
			                 .F.} )
			
			PEDTMP->( DbSkip() )
			
		EndDo
	EndIf
	PEDTMP->( DbCloseArea() )
	
	if !lNoInt
		oGrid:aCols := aClone( aColsEx )
		oGrid:ForceRefresh()
		oDlgPed:Refresh()
	EndIf
	
Return ( Nil )

/*
+-----------------+-------------------------+---------------------------------+-------------------+
| Fonte: GMPAICOM | Funcao:  fLoadAna       | Autor: Jean Carlos P. Saggin    |  Data: 09.07.2019 |
+-----------------+-------------------------+---------------------------------+-------------------+
| Descricao: Função para carregar análise de sazonalidade do item selecionado.                    |
+-------------------------------------------------------------------------------------------------+
| Parametros recebidos: lNoInt                                                                    |
| lNotInt - Indica se a função foi chamada sem interface criada .T.=Sem Interface ou .F.=Com Int. |
+-------------------------------------------------------------------------------------------------+
| Retorno da funcao: Nil                                                                          |
+-------------------------------------------------------------------------------------------------+  
*/

Static Function fLoadAna( lNoInt )
	
	Local aArea  := GetArea()
	Local cQuery := ""
	Local aPer   := {}
	Local dIni   := Nil
	Local dFim   := Nil
	Local aMes   := { 'jan','fev','mar','abr','mai','jun','jul','ago','set','out','nov','dez' }
	Local nX     := 0
	Local aTemp  := {}
	local aFilData := getFilData({})
	local cINCGC   := "" as character
	local aCliLoja := {} as array
	Local cINCli   := "" as character
	local nAux     := 0 as numeric
	local nVendido := 0 as numeric
	local nProduz  := 0 as numeric
	
	Default lNoInt := .F.
	
	oDash:DeActivate()
	
	// Monta expressão para a cláusula IN do SQL
	aEval( aFilData, {|x| nAux++, cINCGC += "'"+ x[4] +"'" + iif( nAux < len( aFilData ), ',', '' ) } )

	If cCboAna == '3'		// Mensal 
		oLblAna:CCAPTION := iif( nGetQtd == 0, '...', iif( nGetQtd > 1, 'meses', 'mês' ) )
	ElseIf cCboAna == '2'	// Semanal
		oLblAna:CCAPTION := iif( nGetQtd == 0, '...', iif( nGetQtd > 1, 'semanas', 'semana' ) )
	Else
		oLblAna:CCAPTION := iif( nGetQtd == 0, '...', iif( nGetQtd > 1, 'dias', 'dia' ) )
	EndIf
	
	// Monta os períodos para serem analisados
	if nGetQtd > 0
		For nX := 1 to nGetQtd
			
			if cCboAna == '3'		// Mensal
				if nX == 1
					dIni := Date() - ( Day( Date() ) -1 )
					dFim := Date()
				Else
					dFim := dIni-1
					dIni := dFim - ( Day( dFim ) -1 ) 
				EndIf
				aAdd( aPer, { dIni, dFim, aMes[Month( dIni )]+'/'+SubStr( StrZero(Year(dIni),4),03,02) } )
			ElseIf cCboAna == '2'	// Semanal
				if nX == 1
					dIni := Date() - (Dow( Date() )-1)
					dFim := Date()
				Else
					dFim := dIni-1
					dIni := dFim - (Dow( dFim )-1)
				EndIf
				aAdd( aPer, { dIni, dFim, cValToChar( Day(dIni) )+'/'+cValToChar( Month(dIni)) +' à '+ cValToChar( Day(dFim) )+'/'+cValToChar( Month(dFim)) } )
			Elseif cCboAna == '1'	// Diário
				dIni := iif( nX==1, Date(), dIni-1 ) 
				dFim := dIni
				aAdd( aPer, { dIni, dFim, DtoC( dIni ) } )
			EndIf
			
		Next nX
	EndIf
	
	aSort( aPer,,,{ |x, y| x[1] < y[1] } )
	
	// Antes de processar os dados para o gráfico, verifica se existe conteúdo no grid de produtos
	if oBrwPro != Nil .and. Len( aColPro ) > 0
		
		for nX := 1 to len( aFilData )
			// QUery para identificação dos diferentes cadastros de clientes equivalentes as filiais do cadastro de empresas
			cQuery := "SELECT DISTINCT A1.A1_COD FROM "+ RetSqlName( 'SA1' ) +" A1 " + CEOL
			cQuery += "WHERE A1_FILIAL "+ U_JSFILIAL( 'SA1', _aFil ) + " " + CEOL
			cQuery += "  AND A1.A1_CGC IN ( "+ cINCGC +" ) " + CEOL
			cQuery += "  AND A1.D_E_L_E_T_ = ' ' " + CEOL
			DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), 'SA1TMP', .F., .T. )
			while ! SA1TMP->( EOF() )
				aAdd( aCliLoja, SA1TMP->A1_COD )
				SA1TMP->( DBSkip() )
			end
			SA1TMP->( DBCloseArea() )
			nAux := 0
			aEval( aCliLoja, {|x| nAux++, cINCli += "'"+ x +"'" + iif( nAux < len( aCliLoja ), ',', '' ) } )
		next nX

		aTemp   := StrTokArr( AllTrim( aColPro[ oBrwPro:nAt ][ nPosDes ] ), ' ' )
		cDesPro := ""
		aEval( aTemp, { |x| cDesPro += SubStr( x, 01, iif( Len( x ) >= 3, 3, Len( x ) ) ) +' ' } )
		
		// Monta comando para leitura dos dados do banco
		cQuery := ""
		oDash:SetPicture( PesqPict( cZB3, cZB3 +'_INDINC' ) )
		For nX := 1 to Len( aPer )

			// Query para identificar saídas referente ao produto
			cQuery := "SELECT ROUND(COALESCE(SUM(D2.D2_QUANT),0),0) QTDVEN FROM "+ RetSqlName( 'SD2' ) +" D2 " + CEOL
			cQuery += "WHERE D2.D2_FILIAL "+ U_JSFILIAL( 'SD2', _aFil ) +" "+ CEOL
			cQuery += "  AND D2.D2_COD     = '"+ aColPro[ oBrwPro:nAt ][ nPosPrd ] +"' " + CEOL
			cQuery += "  AND D2.D2_TIPO    = 'N' " + CEOL		// Apenas notas de saída do tipo N
			cQuery += "  AND D2.D2_EMISSAO BETWEEN '"+ DtoS( aPer[nX][01] ) +"' AND '"+ DtoS( aPer[nX][02] ) +"' " + CEOL
			if ! Empty( cINCli )			// Codigos de clientes referente as filiais do cadastro de empresas
				cQuery += "  AND D2.D2_CLIENTE NOT IN ( "+ cINCli +" ) " + CEOL
			endif
			cQuery += "  AND D2.D_E_L_E_T_ = ' ' " + CEOL

			DBUseArea( .T., "TOPCONN", TcGenQry(,,cQuery), "TMPVEN" /* cAlias */, .F. /* lShared */, .T. /* lReadOnly */ )
			nVendido := 0
			If !TMPVEN->( EOF() )
				nVendido := TMPVEN->QTDVEN
			EndIf
			TMPVEN->( DbCloseArea() )

			cQuery := "SELECT COALESCE(SUM(D3.D3_QUANT),0) AS QTDPROD FROM "+ RetSqlName( 'SD3' ) +" D3 " + CEOL
			cQuery += "WHERE D3.D3_FILIAL "+ U_JSFILIAL( "SD3", _aFil ) +" " + CEOL
			cQuery += "  AND D3.D3_COD    = '"+ aColPro[ oBrwPro:nAt ][ nPosPrd ] +"' " + CEOL
			cQuery += "  AND D3.D3_EMISSAO BETWEEN '"+ DtoS( aPer[nX][01] ) +"' AND '"+ DtoS( aPer[nX][02] ) +"' " + CEOL
			cQuery += "  AND D3.D3_TM     >= '500' " + CEOL
			cQuery += "  AND D3.D3_ESTORNO = ' ' " + CEOL
			cQuery += "  AND D3.D_E_L_E_T_ = ' ' "
		
			DBUseArea( .T., "TOPCONN", TcGenQry(,,cQuery), "TMPVEN" /* cAlias */, .F. /* lShared */, .T. /* lReadOnly */ )
			nProduz := 0
			If !TMPVEN->( EOF() )
				nProduz := TMPVEN->QTDPROD
			EndIf
			TMPVEN->( DbCloseArea() )
			
			oDash:AddSerie( aPer[nX][03], nVendido + nProduz )
		Next nX
		
	EndIf
	oDash:Activate()
	
	RestArea( aArea )
Return ( Nil )

/*/{Protheus.doc} fLoadInf
Função para recálculo dos dados do grid de compras com base nos parâmetros estipulados pelo comprador
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 7/9/2019
/*/
Static Function fLoadInf()
	
	Local cQuery    := ""
	Local nQtdPrd   := 0
	Local nAtual    := 0
	Local nX        := 0
	Local nIndGir   := 0
	Local aGiros    := {}
	Local nPrjEst   := 0 // Armazena projeção do cálculo de duração do estoque atual do produto
	Local nQtdCom   := 0 // Armazena o resultado do cálculo da quantidade a ser comprada
	Local aInfPrd   := {}
	Local aAux      := {}
	Local nDurPrv   := 0
	local nLeadTime := 0  as numeric
	local cLeadTime := "" as character
	local nPrice    := 0  as numeric
	Local nGiro     := 0  as numeric
	local cFornece  := "" as character
	local cLoja     := "" as character
	local nSumGiro  := 0  as numeric
	local nQtdGiro  := 0  as numeric
	
	Default lNoInt := .F.								// Default é rodar "Com Interface"
	
	_aProdFil := {} 
	aMrkFor   := {} 
	DbSelectArea( 'FORTMP' )
	ZAP
	
	if lGir001		// Considera itens críticos?
		aAdd( aGiros, { aConfig[10], 100, LG_CRITICO } ) 
	EndIf
	If lGir002		// Considera itens alto giro?
		aAdd( aGiros, { aConfig[11], aConfig[10]-0.000001, LG_ALTO } ) 
	EndIf
	if lGir003		// Considera itens de medio giro?
		aAdd( aGiros, { aConfig[12], aConfig[11]-0.000001, LG_MEDIO } ) 
	EndIf
	if lGir004		// Considera itens de baixo giro?
		aAdd( aGiros, { aConfig[13], aConfig[12]-0.000001, LG_BAIXO } ) 
	EndIf
	if lGir005		// Considera itens sem giro?
		aAdd( aGiros, { 0, aConfig[13]-0.000001, LG_SEMGIRO } ) 
	EndIf
	
	aColPro  := {}
	aFullPro := {}
	
	// Valida se alguma classificação de giro foi selecionada antes de prosseguir
	if Len( aGiros ) > 0
		
		// Consulta todos os produtos para exibí-los no grid
		cQuery := U_JSQRYINF( aConfig, _aFilters )		
	    
		// CopyToClipBoard( cQuery )
		// MsgInfo( 'Query copiada!', 'SQL' )

		DBUseArea( .T., "TOPCONN", TcGenQry(,,cQuery), "PRDTMP", .F., .T. )
	    Count to nQtdPrd
	    
	    // Define o tamanho da régua para seguir com o processamento
	    ProcRegua( nQtdPrd )
	    
	    PRDTMP->( DbGoTop() )
	    if !PRDTMP->( EOF() )
	    	
	    	DbSelectArea( 'SB1' )
	    	DBSelectArea( 'FORTMP' )
			FORTMP->( DBSetOrder( 2 ) )		// COD + LOJA

	    	While !PRDTMP->( EOF() )
	    		nAtual++
	    		IncProc( 'Analisando '+ AllTrim( SubStr( PRDTMP->B1_DESC, 01, 30 ) ) + '('+ AllTrim( cValToChar( nAtual ) ) +'/'+ AllTrim( cValToChar( nQtdPrd ) ) +')' )
	    		
				aAux := {}
				aAux := betterSupplier( PRDTMP->B1_COD, PRDTMP->B1_PROC, PRDTMP->B1_LOJPROC )
				cFornece := PADR( aAux[1], TAMSX3('A2_COD')[1], ' ')		// Codigo do fornecedor
				cLoja    := PADR( aAux[2], TAMSX3('A2_LOJA')[1], ' ' )		// Codigo da loja

				if ! FORTMP->( DBSeek( cFornece + cLoja ) )
					RecLock( 'FORTMP', .T. )
					FORTMP->MARK        := cMarca
					FORTMP->B1_PROC     := cFornece
					FORTMP->B1_LOJPROC  := cLoja
					FORTMP->LEADTIME    := calcLt( Nil, cFornece, cLoja )

					DBSelectArea( 'SA2' )
					SA2->( DBSetOrder( 1 ) )
					if SA2->( DBSeek( FWxFilial( 'SA2' ) + cFornece + cLoja ) )
						FORTMP->A2_NOME     := SA2->A2_NOME
						FORTMP->A2_NREDUZ   := SA2->A2_NREDUZ
						FORTMP->A2_EMAIL    := SA2->A2_EMAIL
						FORTMP->A2_X_LTIME  := SA2->A2_X_LTIME
					else
						FORTMP->A2_NOME     := "SEM FORNECEDOR"
						FORTMP->A2_NREDUZ   := "SEM FORNECEDOR"
						FORTMP->A2_EMAIL    := " "
						FORTMP->A2_X_LTIME  := 0
					endif
					FORTMP->PEDIDO := iif( aScan( aCarCom, {|x| x[13]+x[14] == FORTMP->B1_PROC + FORTMP->B1_LOJPROC } ) > 0, 'S', 'N' )									
					FORTMP->( MsUnlock() )
					
					aAdd( aMrkFor, FORTMP->B1_PROC + FORTMP->B1_LOJPROC )

				endif

				// Identifica lead-time conforme regra definida para produto, fornecedor (informado) ou fornecedor (calculado)
				if PRDTMP->B1_PE > 0
					nLeadTime := PRDTMP->B1_PE
					cLeadTime := 'P'		// Produto
				elseif PRDTMP->A2_X_LTIME > 0
					nLeadTime := PRDTMP->A2_X_LTIME
					cLeadTime := 'F'		// Fornecedor Padrao
				else
					nLeadTime := calcLt( PRDTMP->B1_COD, cFornece, cLoja )
					cLeadTime := 'C'		// Calculado
				endif 

	    		// Cálculo da duração do estoque com os pedidos de compra aprovados
	    		nPrjEst := Round( ( PRDTMP->ESTOQUE - PRDTMP->EMPENHO + PRDTMP->QTDCOMP )/ PRDTMP->(FieldGet( FieldPos( cZB3 +'_CONMED' ) )), 0 )
	    		if nPrjEst > 999   
	    			nPrjEst := 999
				elseif nPrjEst < 0
					nPrjEst := 0
	    		EndIf
	    		
	    		// Cálculo da duração prevista quando as quantidades bloqueadas forem liberadas
				nDurPrv := Round( ( PRDTMP->ESTOQUE - PRDTMP->EMPENHO + PRDTMP->QTDCOMP + PRDTMP->QTDBLOQ )/ PRDTMP->( FieldGet( FieldPos( cZB3 +'_CONMED' ) ) ), 0 ) - nLeadTime
	    		if nDurPrv > 999 
	    			nDurPrv := 999
				elseif nDurPrv < 0
					nDurPrv := 0
	    		EndIf
	    		
	    		aInfPrd := { nSpinBx /*nDias*/,;
	    		             nLeadTime /*nLdTime*/,;
	    		             nPrjEst,;
	    		             PRDTMP->( FieldGet( FieldPos( cZB3 +'_CONMED' ) ) ) /*nConMed*/,;
	    		             PRDTMP->B1_LM /*nLotMin*/,;
	    		             PRDTMP->B1_QE /*nQtdEmb*/,;
							 PRDTMP->B1_LE /* nLotEco */,;
							 PRDTMP->B1_EMIN /* nEstSeg */,;
							 PRDTMP->ESTOQUE /* nQtdEst */,;
							 PRDTMP->EMPENHO /* nQtdEmp */,;
							 PRDTMP->QTDCOMP /* nQtdPed */ }
	    		
	    		nQtdCom := fCalNec( aInfPrd )
	    		
	    		// Quando apenas sugestões estiver marcado, exibe só os produtos com quantidade de compra maior que 0 (zero)
	    		if nRadMenu == 2 .and. nQtdCom == 0
	    			PRDTMP->( DbSkip() )
	    			Loop
	    		EndIf
	    		
	    		// Trata produtos pelo índice de incidência
	    		nIndGir := PRDTMP->( FieldGet( FieldPos( cZB3 +'_INDINC' ) ) ) 
				nPrice  := lastPrice( PRDTMP->B1_COD, cFornece, cLoja )
				
				aAdd( _aProdFil,{ nIndGir,;
								aScan( aCarCom, {|x| x[1] == PRDTMP->B1_COD .and. x[13] == cFornece .and. x[14] == cLoja } ) > 0,;
								PRDTMP->B1_COD,;
								PRDTMP->B1_DESC,;
								PRDTMP->B1_UM,;
								nQtdCom /*Necessidade de compra*/,;
								PRDTMP->QTDBLOQ /*Ped. Compra Bloq.*/,;
								nPrice /*Preço negociado*/,;
								nPrice /*Ultimo Preço*/,; 
								PRDTMP->( FieldGet( FieldPos( cZB3 +'_CONMED' ) ) ) /*Consumo Medio*/,;
								nPrjEst /*Duracao Estimada*/,;
								nDurPrv /*Duracao Prev.*/,;
								PRDTMP->ESTOQUE /*Em Estoque*/,;
								PRDTMP->EMPENHO /*Empenho*/,; 
								PRDTMP->QTDCOMP /*Quantidade já Comprada*/,;
								nLeadTime /*Lead Time Médio do Produto*/,;
								cLeadTime /*Tipo Lead-Time*/,;
								StoD( PRDTMP->PRVENT ) /*Prev. Entrega*/,;
								PRDTMP->B1_LM /*Lote Mínimo*/,;
								PRDTMP->B1_QE /*Quantidade da Embalagem*/,;
								PRDTMP->B1_LE /*Lote Econômico*/,;
								PRDTMP->B1_EMIN /* Estoque Minimo (Estoque Segurança) */,;
								cFornece /*Fornecedor*/,;
								cLoja /*Loja do Fornecedor*/,;
								PRDTMP->FILIAL /* Filial */ } )
	    		
	    		PRDTMP->( DbSkip() )
	    	EndDo
	    EndIf
	    
	    PRDTMP->( DbCloseArea() )
		
	EndIf
    
	for nX := 1 to len( _aProdFil )
		
		// Reclassifica o giro do produto fazendo uma média entre as filiais
		if nX > 1 .and. _aProdFil[nX-1][3] == _aProdFil[nX][3]
			nSumGiro += _aProdFil[nX][1]
			nQtdGiro += 1
		else
			nSumGiro := _aProdFil[nX][1]
			nQtdGiro := 1
		endif
		nIndGir := nSumGiro / nQtdGiro

		// Obtém a classificação de giro do produto
		nGiro   := aScan( aGiros, {|x| nIndGir >= x[1] .and. nIndGir <= x[2] } )
		if nGiro == 0	// Se a classificação de giro não puder ser identificada, não exibe o produto
			// hlp( 'ATENCAO',;
			// 	 'O produto '+ AllTrim( _aProdFil[nX][4] ) +' não possui classificação de giro!',;
			// 	 'Revise as configurações para classificação de giro dos produtos pois existe algum buraco entre uma faixa e outra que não está sendo tratada!' )
		else
			if aScan( aColPro, {|x| x[1] == _aProdFil[nX][3] } ) == 0
				aAdd( aColPro, { _aProdFil[nX][3],;
								_aProdFil[nX][4],;
								_aProdFil[nX][5],;
								_aProdFil[nX][6],;
								_aProdFil[nX][7],;
								_aProdFil[nX][8],;
								_aProdFil[nX][9],;
								_aProdFil[nX][10],;
								_aProdFil[nX][11],;
								_aProdFil[nX][12],;
								_aProdFil[nX][13],;
								_aProdFil[nX][14],;
								_aProdFil[nX][15],;
								_aProdFil[nX][16],;
								_aProdFil[nX][17],;
								_aProdFil[nX][18],;
								_aProdFil[nX][19],;
								_aProdFil[nX][20],;
								_aProdFil[nX][21],;
								_aProdFil[nX][22],;
								_aProdFil[nX][23],;
								_aProdFil[nX][24],;
								nIndGir,;
								_aProdFil[nX][2] } )
			else
				aColPro[aScan( aColPro, {|x| x[1] == _aProdFil[nX][3] } )][23] := nIndGir
				aColPro[aScan( aColPro, {|x| x[1] == _aProdFil[nX][3] } )][4] += _aProdFil[nX][6]
				aColPro[aScan( aColPro, {|x| x[1] == _aProdFil[nX][3] } )][5] += _aProdFil[nX][7]
			endif
			
		endif

	next nX
    
	// Restaura a ordem padrão de busca de fornecedor
	// FORTMP->( DBSetOrder( 1 ) )
	// Devolve o posicionamento do fornecedor
	// FORTMP->( DbGoTo( nRecFor ) )
	aFullPro := aClone( aColPro )
	oBrwPro:SetArray(aColPro)
	oBrwPro:UpdateBrowse()

	oBrwFor:Refresh(.T. /* lGoTop */)
	oBrwFor:UpdateBrowse()

	fLoadAna()
	
	// RestArea( aArea )
	
Return ( Nil )

/*/{Protheus.doc} betterSupplier
Função para identificar o melhor fornecedor com base no critério configurado
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 05/09/2024
@param cProduto, character, ID do produto
@param cFornPad, character, ID do fornecedor padrão (se existir)
@param cLojaPad, character, loja do fornecedor padrão (se existir)
@return array, aRet[ cBetterSupplier, cBetterStore ]
/*/
static function betterSupplier( cProduto, cFornPad, cLojaPad )

	local aArea  := getArea()
	local aRet   := {"",""} as array
	local cQuery := "" as character
	local aRegs  := {} as array

	// Fornecedor e loja padrão tem prioridade sobre a regra
	if !Empty( cFornPad ) .and. !Empty( cLojaPad )
		aRet := { cFornPad, cLojaPad }
	else
		cQuery := "SELECT "
		cQuery += "   D1.D1_FORNECE, "
		cQuery += "   D1.D1_LOJA, "
		cQuery += "   ROUND(( SUM(D1_TOTAL) - SUM(D1_DESC) ) / SUM(D1_QUANT), 2) VALORMEDIO, "
		cQuery += "   AVG(TO_DATE(D1.D1_DTDIGIT,'YYYYMMDD') - TO_DATE(COALESCE(C7.C7_EMISSAO,D1.D1_DTDIGIT),'YYYYMMDD')) PRAZOMEDIO "
		cQuery += "FROM "+ RetSqlName( 'SD1' ) +" D1 "
		
		cQuery += "LEFT JOIN "+ RetSqlName( 'SC7' ) +" C7 "
		cQuery += " ON C7.C7_FILIAL "+ U_JSFILIAL( 'SC7', _aFil ) + " "
		cQuery += "AND C7.C7_NUM     = D1.D1_PEDIDO "
		cQuery += "AND C7.C7_ITEM    = D1.D1_ITEMPC "
		cQuery += "AND C7.D_E_L_E_T_ = ' ' "

		cQuery += "WHERE D1.D1_FILIAL "+ U_JSFILIAL( 'SD1', _aFil ) +" "
		cQuery += "  AND D1.D1_COD     = '"+ cProduto +"' "				// Apenas o produto selecionado
		cQuery += "  AND D1.D1_TIPO    = 'N' "							// Apenas notas do tipo normal
		cQuery += "  AND D1.D_E_L_E_T_ = ' ' "
		cQuery += "GROUP BY D1.D1_FORNECE, D1.D1_LOJA "

		DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), 'REGFOR', .F., .T. )

		if !REGFOR->( EOF() )
			while ! REGFOR->( EOF() ) 
				aAdd( aRegs, { REGFOR->D1_FORNECE, REGFOR->D1_LOJA, REGFOR->VALORMEDIO, REGFOR->PRAZOMEDIO } )
				REGFOR->( DBSkip() )
			end
		endif
		REGFOR->( DBCloseArea() )

		if len( aRegs ) > 0
			if aConfig[20]	== '1'		// melhor preço
				aSort( aRegs,,,{ |x, y| x[3] < y[3] } )
			else						// melhor prazo de entrega
				aSort( aRegs,,,{ |x, y| x[4] < y[4] } )
			endif
			aRet := { aRegs[1][1], aRegs[1][2] }	
		endif
	
	endif

	restArea( aArea )
return aRet

/*/{Protheus.doc} lastPrice
Função para verificar último preço de compra com o fornecedor para o produto
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 04/09/2024
@param cProd, character, ID do produto(obrigatório)
@param cFornece, character, ID do fornecedor (opcional)
@param cLoja, character, Loja do fornecedor (opcional)
@return numeric, nPrice
/*/
static function lastPrice( cProd, cFornece, cLoja )
	
	local nPrice := 0 as numeric
	local cQuery := "" as character

	default cFornece := ""
	default cLoja	 := ""

	// Consulta o último preço de compra do produto com o fornecedor
	cQuery := "      SELECT ROUND(( D1.D1_TOTAL - D1.D1_DESC ) / D1.D1_QUANT,2) VALNEG FROM "+ RetSqlName( 'SD1' ) +" D1 " + CEOL
	cQuery += "        WHERE D1.R_E_C_N_O_ = ( " + CEOL
	cQuery += "      SELECT MAX(D1.R_E_C_N_O_) FROM "+ RetSqlName( 'SD1' ) +" D1 " + CEOL
	cQuery += "      WHERE D1.D1_FILIAL "+ U_JSFILIAL( 'SD1', _aFil ) +" "+ CEOL 
	cQuery += "        AND D1.D1_COD     = '"+ cProd +"' " + CEOL
	// Verifica se veio fornnecedor e loja como parâmetro
	if !Empty( cFornece ) .and. !Empty( cLoja )
		cQuery += "        AND D1.D1_FORNECE = '"+ cFornece +"' " + CEOL
		cQuery += "        AND D1.D1_LOJA    = '"+ cLoja +"' " + CEOL
	endif
	cQuery += "        AND D1.D1_TIPO    = 'N' " + CEOL
	cQuery += "        AND D1.D_E_L_E_T_ = ' ') "

	DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), 'LAST', .F., .T. )
	if !LAST->( EOF() )
		nPrice := LAST->VALNEG
	endif
	LAST->( DbCloseArea() )

return nPrice

/*/{Protheus.doc} calcLt
Função para cálculo do LeadTime do produto x fornecedor
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 04/09/2024
@param cProduto, character, ID do produto (opcional)
@param cFornece, character, ID do fornecedor (opcional)
@param cLoja, character, Loja do fornecedor (opcional)
@return numeric, nLdTime
/*/
static function calcLt( cProduto, cFornece, cLoja )
	
	local nLdTime := 0 as numeric
	local cQuery  := "" as character
	local nDocs   := 0 as numeric
	local nDias   := 0 as numeric
	local nLdTmFo := 1 as numeric
	
	default cProduto := ""
	default cFornece := ""
	default cLoja	 := ""

	// Se o produto, fornecedor e loja estiverem vazios, não executa processamento do cálculo
	if Empty( cProduto ) .and. Empty( cFornece ) .and. Empty( cLoja )
		return nLdTime
	endif

	// Verifica se o campo existe no cadastro do fornecedor
	if SA2->( FieldPos( 'A2_X_LTIME' ) ) > 0 .and. SA2->A2_X_LTIME > 0
		nLdTmFo := RetField( 'SA2', 1, FWxFilial( 'SA2' ) + cFornece + cLoja, 'A2_X_LTIME' )
	endif

	// Consulta os pedidos de compra para identificar o lead-time do produto com o fornecedor
	cQuery := "SELECT D1.D1_DTDIGIT, COALESCE(C7.C7_EMISSAO,'        ') C7_EMISSAO FROM "+ RetSqlName( 'SD1' ) +" D1 " + CEOL
	
	cQuery += "LEFT JOIN "+ RetSqlName( 'SC7' ) +" C7 " + CEOL
	cQuery += " ON C7.C7_FILIAL "+ U_JSFILIAL( 'SC7', _aFil ) +" "+ CEOL
	cQuery += "AND C7.C7_NUM     = D1.D1_PEDIDO " + CEOL
	cQuery += "AND C7.C7_ITEM    = D1.D1_ITEMPC " + CEOL
	cQuery += "AND C7.D_E_L_E_T_ = ' ' " + CEOL

	cQuery += "WHERE D1.D1_FILIAL "+ U_JSFILIAL( 'SD1', _aFil ) +" "+ CEOL
	
	if !Empty( cProduto )
		cQuery += "  AND D1.D1_COD     = '"+ cProduto +"' " + CEOL
	endif

	if ! Empty( cFornece ) 
		cQuery += "  AND D1.D1_FORNECE = '"+ cFornece +"' " + CEOL 
	endif

	if ! Empty( cLoja )
		cQuery += "  AND D1.D1_LOJA    = '"+ cLoja +"' " + CEOL
	endif

	cQuery += "  AND D1.D1_DTDIGIT >= '"+ DtoS( Date()-DIAS_LT_FOR ) +"' " + CEOL				// Pedidos de compra apenas do último ano
	cQuery += "  AND D1.D1_TES     <> '   ' " + CEOL
	cQuery += "  AND D1.D1_TIPO    = 'N' " + CEOL
	cQuery += "  AND D1.D_E_L_E_T_ = ' ' " + CEOL

	DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), 'LTIME', .F., .T. )
	
	// Converte os campos em Data
	TCSetField( 'LTIME','D1_DTDIGIT', 'D' )
	TcSetField( 'LTIME','C7_EMISSAO', 'D' )

	if !LTIME->( EOF() )
		while !LTIME->( EOF() )
			nDocs++
			nDias += LTIME->D1_DTDIGIT - iif( Empty( LTIME->C7_EMISSAO ), LTIME->D1_DTDIGIT-nLdTmFo, LTIME->C7_EMISSAO )
			LTIME->( DbSkip() )
		end
		nLdTime := Round(nDias/nDocs,0)
	endif
	LTIME->( DbCloseArea() )

return nLdTime

/*
+-----------------+-------------------------+---------------------------------+-------------------+
| Fonte: GMPAICOM | Funcao:  fEvents        | Autor: Jean Carlos P. Saggin    |  Data: 09.07.2019 |
+-----------------+-------------------------+---------------------------------+-------------------+
| Descricao: Função para analisar eventos que podem sofrer variações e influenciar na estratégia  |
|            de compras.                                                                          |
+-------------------------------------------------------------------------------------------------+
| Parametros recebidos: cProduto, aColPrd                                                         |
| cProduto: Quando se deseja visualizar todos os eventos de um produto, o mesmo virá especificado |
| aColPrd: Quando o produto vier especificado via parâmetro, a função vai retornar conteúdo para  |
|          essa variável.                                                                         |
+-------------------------------------------------------------------------------------------------+
| Retorno da funcao: Nil                                                                          |
+-------------------------------------------------------------------------------------------------+  
*/
Static Function fEvents( cProduto, aColPrd, cExpr )
	
	Local aArea   := FORTMP->( GetArea() )
	Local cQuery  := ""
	Local aEveAnt := {}
	local aExpr   := {}
	local nExpr   := 0
	
	Default cProduto := ""
	Default aColPrd  := Nil
	default cExpr    := ""
	
	// Guarda status atual da variável de eventos pendentes
	if Len( aEvePen ) > 0
		aEveAnt := aClone( aEvePen )
		aEvePen := {}
	EndIf
	
	if !Empty( cExpr )
		cExpr := AllTrim( Upper( cExpr ) )
		aExpr := StrTokArr( cExpr, ' ' ) 
	endif 

	// Comando para leitura dos eventos para que comprador tome providências
	cQuery := "SELECT " + CEOL
	cQuery += cZB3 +"."+ cZB3 +"_FILIAL, "+ CEOL
	cQuery += cZB3 +"."+ cZB3 +"_DATA, "+ cZB3 +"."+ cZB3 +"_PROD, B1.B1_DESC, " + CEOL
	cQuery += cZB3 +"."+ cZB3 +"_MSG, "+ cZB3 +"."+ cZB3 +"_JUSTIF "
	cQuery += "FROM "+ RetSqlName( cZB3 ) +" "+ cZB3 +" " + CEOL

    cQuery += "INNER JOIN "+ RetSqlName( 'SB1' ) +" B1 " + CEOL
    cQuery += " ON B1.B1_FILIAL  "+ U_JSFILIAL( 'SB1', _aFil ) +" "+ CEOL
    cQuery += "AND B1.B1_COD     = "+ cZB3 +"."+ cZB3 +"_PROD " + CEOL
	if Len( aExpr ) > 0
		for nExpr := 1 to len( aExpr )
			cQuery += iif( !Empty( aExpr[ nExpr ] ), "AND B1.B1_DESC LIKE '%"+ AllTrim( aExpr[nExpr] ) +"%' " + CEOL, "" )
		next
	endif
    cQuery += "AND B1.D_E_L_E_T_ = ' ' " + CEOL
    
    // Liga com tabela de produtos a serem ignorados
    cQuery += "LEFT JOIN "+ RetSqlName( cZB6 ) +" "+ cZB6 +" "+ CEOL
    cQuery += " ON "+ cZB6 +"."+ cZB6 +"_FILIAL "+ U_JSFILIAL( cZB6, _aFil ) +" "+ CEOL
    cQuery += "AND "+ cZB6 +"."+ cZB6 +"_PROD   = "+ cZB3 +"."+ cZB3 +"_PROD " + CEOL
    cQuery += "AND "+ cZB6 +"."+ cZB6 +"_DTLIM  >= '"+ DtoS( Date() ) +"' " + CEOL
    cQuery += "AND "+ cZB6 +".D_E_L_E_T_ = ' ' " + CEOL
    
    cQuery += "WHERE "+ cZB3 +"."+ cZB3 +"_FILIAL " + U_JSFILIAL( cZB3, _aFil ) +" "+ CEOL
    cQuery += "  AND "+ cZB3 +"."+ cZB3 +"_AVISO  = 'S' " + CEOL
    
    if Empty( cProduto )
    	// Quando o produto não vier especificado, lê todas as notificações pendentes
    	cQuery += "  AND "+ cZB3 +"."+ cZB3 +"_JUSTIF = '"+ Space( TAMSX3( cZB3 +'_JUSTIF')[01] ) +"' " + CEOL
    	// Apenas produtos que não estão para serem desconsiderados
    	cQuery += "  AND COALESCE( "+ cZB6 +"."+ cZB6 +"_PROD, ' ' ) = ' ' " + CEOL
    Else
    	// Quando produto vier preenchido, lë todos os eventos relacionados a ele, indiferente se o evento foi ou não solucionado.
    	cQuery += "  AND "+ cZB3 +"."+ cZB3 +"_PROD   = '"+ cProduto +"' " + CEOL
    EndIf
    cQuery += "  AND "+ cZB3 +".D_E_L_E_T_ = ' ' " + CEOL
    cQuery += "ORDER BY "+ cZB3 +"."+ cZB3 +"_DATA, B1.B1_DESC " + CEOL
    
    TcQuery cQuery New Alias "EVETMP"
    DbSelectArea( 'EVETMP' )
    
    TcSetField( "EVETMP", cZB3 +'_DATA', 'D' )
    
    EVETMP->( DbGoTop() )
    
    if !EVETMP->( EOF() )
    	aEvePen := {}
    	While !EVETMP->( EOF() )
    		
    		aAdd( aEvePen, { EVETMP->( FieldGet( FieldPos( cZB3 +'_FILIAL' ) ) ),;
							 EVETMP->( FieldGet( FieldPos( cZB3 +'_DATA' ) ) ),;
    		                 EVETMP->( FieldGet( FieldPos( cZB3 +'_PROD' ) ) ),;
    		                 EVETMP->B1_DESC,;
    		                 EVETMP->( FieldGet( FieldPos( cZB3 +'_MSG' ) ) ),;
    		                 .F. } )
    		
    		EVETMP->( DbSkip() )
    	EndDo
    EndIf
	
	EVETMP->( DbCloseArea() )
	
	// Verifica se a informação que deve retornar é referente a um único produto
	if !Empty( cProduto )
		aColPrd := aClone( aEvePen )	// Atribui o conteúdo de aEvePen para o vetor específico do produto
		aEvePen := aClone( aEveAnt )	// Devolve o conteúdo de aEnvPen de quando iniciou o processamento
	EndIf
	
	RestArea( aArea )
Return ( Nil )

/*/{Protheus.doc} fMarkPro
Função para marcar/desmarcar registros das linhas do browse de produtos
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 21/06/2024
/*/
Static Function fMarkPro()
	
	local cForLoj   := "" as character
	local lInclui   := .F.
	local lUsaFrete := X3Uso( GetSX3Cache( 'C7_VALFRE' , 'X3_USADO' ) )
	local aLinCar   := {} as array
	
	if Len( aColPro ) > 0 .and. !Empty( aColPro[oBrwPro:nAt][nPosPrd] )
		aColPro[oBrwPro:nAt][nPosChk] := ! aColPro[oBrwPro:nAt][nPosChk]
		if aColPro[oBrwPro:nAt][nPosChk]
			
			aAdd( aLinCar, aColPro[oBrwPro:nAt][nPosPrd] ) 
			aAdd( aLinCar, aColPro[oBrwPro:nAt][nPosDes] )
			aAdd( aLinCar, aColPro[oBrwPro:nAt][nPosUnM] )
			aAdd( aLinCar, aColPro[oBrwPro:nAt][nPosNec] )
			aAdd( aLinCar, aColPro[oBrwPro:nAt][nPosNeg] )
			aAdd( aLinCar, aColPro[oBrwPro:nAt][nPosNec]*aColPro[oBrwPro:nAt][nPosNeg] )
			aAdd( aLinCar, Date() )
			aAdd( aLinCar, Date() + aColPro[oBrwPro:nAt][nPosLdT] )
			aAdd( aLinCar, RetField( 'SB1', 1, xFilial( 'SB1' ) + aColPro[oBrwPro:nAt][nPosPrd], 'B1_LOCPAD' ) )
			aAdd( aLinCar, Space( TAMSX3( 'C7_OBS' )[01] ) )
			aAdd( aLinCar, '' /* cCC */ )
			aAdd( aLinCar, RetField( 'SB1', 1, xFilial( 'SB1' ) + aColPro[oBrwPro:nAt][nPosPrd], 'B1_IPI' ) )
			aAdd( aLinCar, aColPro[oBrwPro:nAt][nPosFor] )
			aAdd( aLinCar, aColPro[oBrwPro:nAt][nPosLoj] )

			if lUsaFrete
				aAdd( aLinCar, 0 )
			endif
			aAdd( aLinCar, .F. )

			aAdd( aCarCom, aClone( aLinCar ) )
			aLinCar := {}

			lInclui := .T.
			cForLoj := aColPro[oBrwPro:nAt][nPosFor] + aColPro[oBrwPro:nAt][nPosLoj]
		Else
			cForLoj := aColPro[oBrwPro:nAt][nPosFor] + aColPro[oBrwPro:nAt][nPosLoj]
			aDel( aCarCom, aScan( aCarCom, {|x| x[1] == aColPro[oBrwPro:nAt][nPosPrd] .and.;
												x[13] == aColPro[oBrwPro:nAt][nPosFor] .and.;
												x[14] == aColPro[oBrwPro:nAt][nPosLoj] } ) ) 
			aSize( aCarCom, Len( aCarCom )-1 )
			lInclui := .F.
		EndIf

		// Clona a linha assim que houver uma marcação/desmarcação
		aFullPro[ aScan( aFullPro, {|x| x[nPosPrd] == aColPro[oBrwPro:At()][nPosPrd] } ) ] := aClone( aColPro[oBrwPro:At()] )
		
		DBSelectArea( 'FORTMP' )
		FORTMP->( DBSetOrder( 2 ) )
		if lInclui
			if FORTMP->( DBSeek( cForLoj ) ) .and. FORTMP->PEDIDO == 'N'
				RecLock( 'FORTMP', .F. )
				FORTMP->PEDIDO := 'S'
				FORTMP->( MsUnlock() )
			endif
		Elseif !lInclui .and. aScan( aCarCom, {|x| x[13] + x[14] == cForLoj } ) == 0
			if FORTMP->( DBSeek( cForLoj ) ) .and. FORTMP->PEDIDO == 'S'
				RecLock( 'FORTMP', .F. )
				FORTMP->PEDIDO := 'N'
				FORTMP->( MsUnlock() )
			endif
		EndIf
	EndIf
	
	oBrwFor:UpdateBrowse()
	oBrwPro:oBrowse:SetFocus()
	
Return ( Nil )

/*/{Protheus.doc} PCOMVLD
Função de validação de alterações dos dados do grid
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 7/17/2019z
@return logical, lRet
/*/
User Function PCOMVLD()
	
	Local nColAtu   := 0
	Local lReturn   := .T.
	Local aVetPrd   := {}
	Local cQuery    := ""
	Local aChvSC7   := {}
	Local nQtdSC7   := 0
	Local aCab      := aLin := aIte := aColPd := aHdr := aFld := {}
	Local oPedidos  := Nil
	Local oBtnFec   := Nil
	Local oDlgOpc   := Nil
	Local cStlBtn   := ""
	Local oNewGrid  := 0
	Local nPosNum   := 0
	local nPosIte   := 0
	local nPosQuant := 0
	Local nX        := 0
	local nLeadTime := 0  as numeric
	local cLeadTime := 0  as character
	local nPrjEst   := 0  as numeric
	local nDurPrv   := 0  as numeric
	local aInfPrd   := {} as array
	local nQtdCom   := 0  as numeric
	
	Private oBtnSel     := Nil
	Private lMsErroAuto := .F.

	if oBrwPro:oBrowse != Nil
		nColAtu := oBrwPro:ColPos()-2
		DbSelectArea( 'SB1' )
		if SB1->( FieldPos( oBrwPro:GetColumn(oBrwPro:ColPos()):GetID() ) ) > 0
			SB1->( DbSetOrder( 1 ) )
			
			If DbSeek( FWxFilial( 'SB1' ) + aColPro[oBrwPro:nAt][nPosPrd] )
				
				// Compara a informação em memória com a informação gravada no cadastro do produto pra ver se é diferente
				if ( &( 'SB1->'+ oBrwPro:GetColumn(oBrwPro:ColPos()):GetID() ) != aColPro[oBrwPro:At()][nColAtu] ) .or.;  
				   oBrwPro:GetColumn(oBrwPro:ColPos()):GetID() == "B1_PROC"
				   
					if oBrwPro:GetColumn(oBrwPro:ColPos()):GetID() == "B1_PROC" .and.; 
						! MsgYesNo( 'Gostaria de alterar o fornecedor padrão do produto '+ AllTrim( SB1->B1_DESC ) +'?'+;
									' Se optar por alterar, na próxima demanda de compra, o fornecedor padrão terá preferência sobre os demais fornecedores...', 'A T E N Ç Ã O !' )
						aColPro[oBrwPro:At()][nPosLoj] := SA2->A2_LOJA
						
						DBSelectArea( "FORTMP" )
						FORTMP->( DBSetOrder( 2 ) )		// Fornecedor e Loja
						if ! FORTMP->( DBSeek( aColPro[oBrwPro:At()][nPosFor] + aColPro[oBrwPro:At()][nPosLoj] ) )
							
							RecLock( 'FORTMP', .T. )
							FORTMP->MARK        := cMarca
							FORTMP->B1_PROC     := aColPro[oBrwPro:At()][nPosFor]
							FORTMP->B1_LOJPROC  := aColPro[oBrwPro:At()][nPosLoj]
							FORTMP->LEADTIME    := calcLt( Nil, aColPro[oBrwPro:At()][nPosFor], aColPro[oBrwPro:At()][nPosLoj] )
							DBSelectArea( 'SA2' )
							SA2->( DBSetOrder( 1 ) )
							if SA2->( DBSeek( FWxFilial( 'SA2' ) + aColPro[oBrwPro:At()][nPosFor] + aColPro[oBrwPro:At()][nPosLoj] ) )
								FORTMP->A2_NOME     := SA2->A2_NOME
								FORTMP->A2_NREDUZ   := SA2->A2_NREDUZ
								FORTMP->A2_EMAIL    := SA2->A2_EMAIL
								FORTMP->A2_X_LTIME  := SA2->A2_X_LTIME
							else
								FORTMP->A2_NOME     := "SEM FORNECEDOR"
								FORTMP->A2_NREDUZ   := "SEM FORNECEDOR"
								FORTMP->A2_EMAIL    := " "
								FORTMP->A2_X_LTIME  := 0
							endif
							FORTMP->PEDIDO := iif( aScan( aCarCom, {|x| x[13]+x[14] == FORTMP->B1_PROC + FORTMP->B1_LOJPROC } ) > 0, 'S', 'N' )
							FORTMP->( MsUnlock() )
							oBrwFor:UpdateBrowse()
						endif
						if lReturn
							aFullPro[ aScan( aFullPro, {|x| x[nPosPrd] == aColPro[oBrwPro:nAt][nPosPrd] } ) ] := aClone( aColPro[oBrwPro:nAt] )
						endif
						Return lReturn
					endif
					aAdd( aVetPrd, { "B1_FILIAL", xFilial( 'SB1' ), Nil } )
					aAdd( aVetPrd, { "B1_COD"   , aColPro[oBrwPro:nAt][nPosPrd], Nil } )
					aAdd( aVetPrd, { oBrwPro:GetColumn(oBrwPro:ColPos()):GetID(), aColPro[oBrwPro:At()][nColAtu], Nil } )
					
					If oBrwPro:GetColumn(oBrwPro:ColPos()):GetID() == "B1_PROC"
						aColPro[oBrwPro:At()][nPosLoj] := SA2->A2_LOJA
						aAdd( aVetPrd, { "B1_LOJPROC", aColPro[oBrwPro:At()][nPosLoj], Nil } )
					EndIf
					
					lMsErroAuto := .F.
					MSExecAuto({|x, y| Mata010(x, y)}, aVetPrd, 4 )
					
					If lMsErroAuto
						lReturn := !lMsErroAuto
						MostraErro()
					else
						aFullPro[ aScan( aFullPro, {|x| x[nPosPrd] == aColPro[oBrwPro:nAt][nPosPrd] } ) ] := aClone( aColPro[oBrwPro:nAt] )
					EndIf
					
				EndIf
				
			EndIf
			
		EndIf
		
		if nColAtu == nPosNec						// Alteração no campo de necessidade de compra
			if aScan( aCarCom, {|x| AllTrim( x[01] ) == AllTrim( aColPro[ oBrwPro:nAt ][ nPosPrd ] ) } ) > 0
				if MsgYesNo( 'Você está alterando a necessidade de compra de um produto que já está no carrinho, deseja mesmo alterar?','Alteração de produto do carrinho')
					aCarCom[ aScan( aCarCom, {|x| AllTrim( x[01] ) == AllTrim( aColPro[ oBrwPro:nAt ][ nPosPrd ] ) } ) ][ 04 ] := aColPro[oBrwPro:At()][nPosNec]
					aCarCom[ aScan( aCarCom, {|x| AllTrim( x[01] ) == AllTrim( aColPro[ oBrwPro:nAt ][ nPosPrd ] ) } ) ][ 06 ] := aColPro[oBrwPro:At()][nPosNec] * aColPro[oBrwPro:nAt][nPosNeg]
				Else
					lReturn := .F.
				EndIf
			EndIf
		ElseIf nColAtu == nPosNeg					// Alteração no campo do valor negociado
			if aScan( aCarCom, {|x| AllTrim( x[01] ) == AllTrim( aColPro[ oBrwPro:nAt ][ nPosPrd ] ) } ) > 0
				if MsgYesNo( 'Você está alterando o valor negociado de um produto que já está no carrinho, deseja mesmo alterar?','Alteração de produto do carrinho')
					aCarCom[ aScan( aCarCom, {|x| AllTrim( x[01] ) == AllTrim( aColPro[ oBrwPro:nAt ][ nPosPrd ] ) } ) ][ 05 ] := aColPro[oBrwPro:nAt][nPosNeg]
					aCarCom[ aScan( aCarCom, {|x| AllTrim( x[01] ) == AllTrim( aColPro[ oBrwPro:nAt ][ nPosPrd ] ) } ) ][ 06 ] := aColPro[oBrwPro:nAt][nPosNec] * aColPro[oBrwPro:nAt][nPosNeg]
				Else
					lReturn := .F.
				EndIf
			EndIf
		elseif nColAtu == nPosLdT 					// Alteração no campo do lead-time do produto
			if aColPro[oBrwPro:At()][nPosLdT] >= 0
				
				nLeadTime := aColPro[oBrwPro:At()][nPosLdT]
				if nLeadTime > 0
					cLeadTime := 'P'
				endif

				DBSelectArea( 'SB1' )
				SB1->( DBSetOrder( 1 ) )		// B1_FILIAL + B1_COD
				if SB1->( DBSeek( FWxFilial( 'SB1' ) + aColPro[ oBrwPro:nAt ][ nPosPrd ] ) )
					RecLock( 'SB1', .F. )
					SB1->B1_PE := nLeadTime
					SB1->( MsUnlock() )
					
					// Se o prazo de entrega do produto for maior do que zero, prioriza a informação do produto
					if nLeadTime == 0
						
						// Posiciona no cadastro do fornecedor padrão para o produto
						DBSelectArea( 'SA2' )
						SA2->( DbSetOrder( 1 ) ) 	// A2_FILIAL + A2_COD + A2_LOJA
						if SA2->( DBSeek( FWxFilial( 'SA2' ) + aColPro[ oBrwPro:nAt ][ nPosFor ] + aColPro[ oBrwPro:nAt ][ nPosLoj ] ) )
							// Verifica se o lead-time do fornecedor é maior do que zero
							if SA2->A2_X_LTIME > 0
								nLeadTime := SA2->A2_X_LTIME
								cLeadTime := 'F'		// Fornecedor
							endif

						endif

						// Se o lead-time ainda estiver sem valor, utiliza o cálculo do prazo médio do fornecedor padrão do produto
						if nLeadTime == 0
							nLeadTime := calcLt( aColPro[ oBrwPro:nAt ][ nPosPrd ], aColPro[ oBrwPro:nAt ][ nPosFor ], aColPro[ oBrwPro:nAt ][ nPosLoj ] )
							cLeadTime := 'C'
						endif

					endif

				endif

				// Atualiza os dados da linha do produto conforme alterações realizadas no campo do lead-time
				// Cálculo da duração do estoque com os pedidos de compra aprovados
				nPrjEst := Round( ( aColPro[ oBrwPro:nAt ][ nPosEmE ] - ;
									aColPro[ oBrwPro:nAt ][ nPosVen ] + ;
									aColPro[ oBrwPro:nAt ][ nPosQtd ] )/ ;
									aColPro[ oBrwPro:nAt ][ nPosCon ], 0 )
				if nPrjEst > 999 
					nPrjEst := 999
				EndIf
				
				// Cálculo da duração prevista quando as quantidades bloqueadas forem liberadas
				nDurPrv := Round( ( aColPro[ oBrwPro:nAt ][ nPosEmE ] - ;
									aColPro[ oBrwPro:nAt ][ nPosVen ] + ;
									aColPro[ oBrwPro:nAt ][ nPosQtd ] + ;
									aColPro[ oBrwPro:nAt ][ nPosBlq ] )/ ;
									aColPro[ oBrwPro:nAt ][ nPosCon ], 0 ) - nLeadTime
				if nDurPrv > 999 
					nDurPrv := 999
				EndIf
				
				aInfPrd := { nSpinBx /*nDias de programação de estoque*/,;
							nLeadTime /*nLdTime*/,;
							nPrjEst,;
							aColPro[ oBrwPro:nAt ][ nPosCon ] /*nConMed*/,;
							aColPro[ oBrwPro:nAt ][ nPosLtM ] /*nLotMin*/,;
							aColPro[ oBrwPro:nAt ][ nPosQtE ] /*nQtdEmb*/,;
							aColPro[ oBrwPro:nAt ][ nPosLtE ] /* nLotEco */,;
							RetField( "SB1", 1, FWxFilial( 'SB1' )+ aColPro[ oBrwPro:nAt ][ nPosPrd ], "B1_EMIN" ) /* nEstSeg */,;
							aColPro[ oBrwPro:nAt ][ nPosEmE ] /* nQtdEst */,;
							aColPro[ oBrwPro:nAt ][ nPosVen ] /* nQtdEmp */,;
							aColPro[ oBrwPro:nAt ][ nPosQtd ] /* nQtdCom */ }
				
				// Função que calcula a necessidade de compra
				nQtdCom := fCalNec( aInfPrd )
				aColPro[ oBrwPro:nAt ][ nPosNec ] := nQtdCom
				aColPro[ oBrwPro:nAt ][ nPosDur ] := nPrjEst
				aColPro[ oBrwPro:nAt ][ nPosDuP ] := nDurPrv
				aColPro[ oBrwPro:nAt ][ nPosLdT ] := nLeadTime
				aColPro[ oBrwPro:nAt ][ nPosTLT ] := cLeadTime

			else
				lReturn := .F.
			endif

		EndIf
		
		If nColAtu == nPosBlq .and. aColPro[oBrwPro:nAt][nPosBlq] > 0
			
			// Identifica o(s) pedidos pendentes de aprovação para o produto
			cQuery := "SELECT C7.C7_FILIAL, C7.C7_NUM, C7.C7_ITEM FROM "+ RetSqlName( "SC7" ) + " C7 " + CEOL
			cQuery += "WHERE C7.C7_FILIAL "+ U_JSFILIAL( 'SC7', _aFil ) +" "+ CEOL
			cQuery += "  AND C7.C7_PRODUTO = '"+ aColPro[ oBrwPro:nAt ][ nPosPrd ] +"' " + CEOL
			cQuery += "  AND C7.C7_RESIDUO <> 'S' " + CEOL
			cQuery += "  AND C7.C7_ENCER   <> 'E' " + CEOL
			cQuery += "  AND C7.C7_CONAPRO = 'B' " + CEOL
			cQuery += "  AND C7.D_E_L_E_T_ = ' ' " + CEOL
			
			TcQuery cQuery New Alias "APRTMP"
			DBSelectArea( "APRTMP" )
			Count to nQtdSC7
			APRTMP->( DBGoTop() )
			
			if !APRTMP->( EOF() )
				aChvSC7 := {}
				While !APRTMP->( EOF() )
					aAdd( aChvSC7, APRTMP->C7_FILIAL+APRTMP->C7_NUM + APRTMP->C7_ITEM )
					APRTMP->( DBSkip() )
				EndDo
			EndIf
			APRTMP->( DBCloseArea() )
			
			If Len( aChvSC7 ) > 1
				
				aAlt := {"QUANT"}
				
				lReturn := .F.
				aFld := {"C7_NUM","C7_ITEM","C7_PRECO","C7_TOTAL","C7_FORNECE","C7_LOJA","A2_NOME"}
				aHdr := {}
				aAdd( aHdr, { "Quant.", "QUANT", "@E 999,999,999", 11,0,,,"N",,"V",, } )
				aEval( aFld, {|x| aAdd( aHdr, { AllTrim( GetSX3Cache( x, "X3_TITULO" )),;
				                                x,;
				                                GetSX3Cache( x, "X3_PICTURE" ),;
				                                GetSX3Cache( x, "X3_TAMANHO" ),;
				                                GetSX3Cache( x, "X3_DECIMAL" ),;
				                                ,;
				                                GetSX3Cache( x, "X3_USADO"   ),;
				                                GetSX3Cache( x, "X3_TIPO"    ),;
				                                GetSX3Cache( x, "X3_F3"      ),;
				                                GetSX3Cache( x, "X3_CONTEXT" ),;
				                                GetSX3Cache( x, "X3_CBOX"    ),;
				                                GetSX3Cache( x, "X3_RELACAO" )} ) } )
                
                aColPd := {}
                aEval( aChvSC7, {|y| aAdd( aColPd, aClone( { RetField( "SC7", 1, y, "C7_QUANT"   ),;
                                                   SubStr( y, TAMSX3("C7_FILIAL")[1]+1, TAMSX3("C7_NUM")[1] ),;
                                                   SubStr( y, TAMSX3("C7_FILIAL")[1]+TAMSX3("C7_NUM")[1]+1, TAMSX3("C7_ITEM")[1] ),;
                                                   RetField( "SC7", 1, y, "C7_PRECO"   ),;
                                                   RetField( "SC7", 1, y, "C7_TOTAL"   ),;
                                                   RetField( "SC7", 1, y, "C7_FORNECE" ),;
                                                   RetField( "SC7", 1, y, "C7_LOJA"    ),;
                                                   RetField( "SA2", 1, xFilial( "SA2" ) +; 
                                                                       RetField( "SC7", 1, y, "C7_FORNECE" ) +; 
                                                                       RetField( "SC7", 1, y, "C7_LOJA"    ), "A2_NOME" ),;
                                                   .F. /*lDeleted*/ } ) ) } )
				
				cStlBtn := "QPushButton { "
				cStlBtn += " margin: 2px; "
			    cStlBtn += " border-style: outset;"
			    cStlBtn += " border-width: 2px;"
			    cStlBtn += " border: 1px solid #C0C0C0;"
			    cStlBtn += " border-radius: 5px;"
			    cStlBtn += " border-color: #C0C0C0;"
			    cStlBtn += " font: bold 12px Arial;"
			    cStlBtn += " padding: 6px;"
			    cStlBtn += "}"
			    cStlBtn += "QPushButton:pressed {"
			    cStlBtn += " background-color: #e6e6f9;"
			    cStlBtn += " border-style: inset;"
			    cStlBtn += "}"
			    
			    cStlSai := "QPushButton { "
				cStlSai += " margin: 2px; "
			    cStlSai += " border-style: outset;"
			    cStlSai += " border-width: 2px;"
			    cStlSai += " border: 1px solid #C0C0C0;"
			    cStlSai += " border-radius: 5px;"
			    cStlSai += " border-color: #C0C0C0;"
			    cStlSai += " font: bold 12px Arial;"
			    cStlSai += " padding: 6px;"
			    cStlSai += "}"
			    cStlSai += "QPushButton:pressed {"
			    cStlSai += " background-color: #e6e6f9;"
			    cStlSai += " border-style: inset;"
			    cStlSai += "}"
			    
				// Exibe tela para que o comprador possa selecionar em qual dos pedidos ele gostaria de alterar a quantidade
				DEFINE MSDIALOG oDlgOpc TITLE "Defina as quantidades corretas dos pedidos abaixo" FROM 000, 000 TO 200, 500 COLORS 0, 16777215 PIXEL
			    oPedidos := MsNewGetDados():New( 002, 002, 078, 250, GD_UPDATE, "AllwaysTrue", "AllwaysTrue", "", aAlt,, Len(aColPd), "AllwaysTrue", "", "AllwaysTrue", oDlgOpc, aHdr, aColPd)
			    @ 158, 416 BTNBMP oBtnSel RESNAME "ok.png" SIZE 040, 040 OF oDlgOpc ACTION  { lReturn := fVldGrid( oPedidos, M->QTDBLOQ ),;
                                                                                               oNewGrid := oPedidos,; 
                                                                                               iif( fVldGrid( oPedidos, M->QTDBLOQ ), oDlgOpc:End(), MsgStop( "Os campos de quantidade do grid não estão preenchidos adequadamente!","Campos de quantidade..." ) ) } WHEN .T. PIXEL
			                          
			    @ 158, 460 BTNBMP oBtnFec RESNAME "final.png" SIZE 040, 040 OF oDlgOpc ACTION { lReturn := .F., oDlgOpc:End() } WHEN .T. PIXEL
			    oBtnFec:SetCss( cStlSai )
			    ACTIVATE MSDIALOG oDlgOpc CENTERED
			    
			    // Verifica se pressionou o botão Ok
			    if lReturn
			    	
			    	nPosNum := aScan( oNewGrid:aHeader,{|x| AllTrim( x[2] ) == "C7_NUM"   } )
			    	nPosIte := aScan( oNewGrid:aHeader,{|x| AllTrim( x[2] ) == "C7_ITEM"  } )
			    	nPosQuant := aScan( oNewGrid:aHeader,{|x| AllTrim( x[2] ) == "QUANT"    } )
			    	
			    	For nX := 1 to Len( oNewGrid:aCols )
			    		
				    	DBSelectArea( "SC7" )
						SC7->( DBSetOrder( 1 ) )
						If DbSeek( xFilial( "SC7" ) + oNewGrid:aCols[nX][nPosNum] + oNewGrid:aCols[nX][nPosIte] )
							
							aIte := {}
							aCab := {}
							aAdd( aCab, { "C7_FILIAL" , xFilial( "SC7" ) } )
							aAdd( aCab, { "C7_NUM"    , oNewGrid:aCols[nX][nPosNum] } )
							aadd( aCab, {"C7_EMISSAO" , SC7->C7_EMISSAO })
							aadd( aCab, {"C7_FORNECE" , SC7->C7_FORNECE })
							aadd( aCab, {"C7_LOJA"    , SC7->C7_LOJA })
							aadd( aCab, {"C7_COND"    , SC7->C7_COND })
							aadd( aCab, {"C7_CONTATO" , SC7->C7_CONTATO })
							aadd( aCab, {"C7_FILENT"  , cFilAnt })
							
							aLin := {}
							If oNewGrid:aCols[nX][nPosQuant] > 0
								
								// Verifica se a quantidade no grid para o item do pedido é diferente da quantidade atual do item no pedido
								if oNewGrid:aCols[nX][nPosQuant] != SC7->C7_QUANT
								
									aAdd( aLin, { "C7_ITEM"    , oNewGrid:aCols[nX][nPosIte], Nil } )
									aAdd( aLin, { "C7_PRODUTO" , SC7->C7_PRODUTO, Nil } )
									aAdd( aLin, { "C7_QUANT"   , oNewGrid:aCols[nX][nPosQuant], Nil } )
									aAdd( aLin, { "C7_PRECO"   , SC7->C7_PRECO, Nil } )
									aAdd( aLin, { "C7_TOTAL"   , SC7->C7_PRECO * oNewGrid:aCols[nX][nPosQuant], Nil } )
									aAdd( aLin, { "C7_CONAPRO" , SC7->C7_CONAPRO, Nil } )
									aAdd( aLin, { "C7_REC_WT"  , SC7->(Recno()), Nil } )
								Else
									Loop
								EndIf
							Else
								
								aAdd( aLin, { "C7_ITEM"   , oNewGrid:aCols[nX][nPosIte], Nil } )
								aAdd( aLin, { "C7_PRODUTO", SC7->C7_PRODUTO, Nil } )
								aAdd( aLin, { "AUTDELETA" , "S", Nil } )
								aAdd( aLin, { "C7_REC_WT" , SC7->(Recno()), Nil } )
								
							EndIf
							aAdd( aIte, aClone( aLin ) )
							
							lMsErroAuto := .F.
							Processa({|| MATA120( 1, aCab, aIte, 4/*nOpc*/, .F./*lShowDlg*/ ) }, "Alterando pedido "+ oNewGrid:aCols[nX][nPosNum] +;
							                      ", item "+ oNewGrid:aCols[nX][nPosIte] +"...","Aguarde enquanto processo as alterações no pedido...")
							
							if lMsErroAuto 
								MostraErro()
								lReturn := .F.
							Else
								MsgInfo( "O item <b>"+ oNewGrid:aCols[nX][nPosIte] +"</b> do pedido "+; 
								         oNewGrid:aCols[nX][nPosNum] +" foi alterado, pressione <b>F5</b> quando quiser atualizar "+;
								         "as informações do grid!","Pronto!" )
							EndIf
							
						EndIf
			    		
			    	Next nX
			    	
			    EndIf
				
			ElseIf Len( aChvSC7 ) == 1
				
				DBSelectArea( "SC7" )
				SC7->( DBSetOrder( 1 ) )
				If DbSeek( xFilial( "SC7" ) + aChvSC7[1] )
					
					aIte := {}
					aCab := {}
					aAdd( aCab, { "C7_FILIAL"  , FWxFilial( "SC7" ) } )
					aAdd( aCab, { "C7_NUM"     , SubStr( aChvSC7[1], 1, TAMSX3("C7_NUM")[1] ) } )
					aadd( aCab, { "C7_EMISSAO" , SC7->C7_EMISSAO })
					aadd( aCab, { "C7_FORNECE" , SC7->C7_FORNECE })
					aadd( aCab, { "C7_LOJA"    , SC7->C7_LOJA })
					aadd( aCab, { "C7_COND"    , SC7->C7_COND })
					aadd( aCab, { "C7_CONTATO" , SC7->C7_CONTATO })
					aadd( aCab, { "C7_FILENT"  , cFilAnt })
					
					aLin := {}
					If aColPro[oBrwPro:At()][nPosBlq] > 0
						
						aAdd( aLin, { "C7_ITEM"   , SubStr( aChvSC7[1], TAMSX3("C7_NUM")[1]+1, TAMSX3("C7_ITEM")[1] ), Nil } )
						aAdd( aLin, { "C7_PRODUTO", SC7->C7_PRODUTO, Nil } )
						aAdd( aLin, { "C7_QUANT"  , aColPro[oBrwPro:At()][nPosBlq], Nil } )
						aAdd( aLin, { "C7_PRECO"  , SC7->C7_PRECO, Nil } )
						aAdd( aLin, { "C7_TOTAL"  , SC7->C7_PRECO * aColPro[oBrwPro:At()][nPosBlq], Nil } )
						aAdd( aLin, { "C7_CONAPRO", SC7->C7_CONAPRO, Nil } )
						aAdd( aLin, { "C7_REC_WT" , SC7->(Recno()), Nil } )
						
					Else
						
						aAdd( aLin, { "C7_ITEM"   , SubStr( aChvSC7[1], TAMSX3("C7_NUM")[1]+1, TAMSX3("C7_ITEM")[1] ), Nil } )
						aAdd( aLin, { "C7_PRODUTO", SC7->C7_PRODUTO, Nil } )
						aAdd( aLin, { "AUTDELETA" , "S", Nil } )
						aAdd( aLin, { "C7_REC_WT" , SC7->(Recno()), Nil } )
						
					EndIf
					aAdd( aIte, aClone( aLin ) )
					
					lMsErroAuto := .F.
					Processa({|| MATA120( 1, aCab, aIte, 4/*nOpc*/, .F./*lShowDlg*/ ) }, "Alterando pedido "+ SubStr( aChvSC7[1], 1, TAMSX3("C7_NUM")[1] ) +", item "+ SubStr( aChvSC7[1], TAMSX3("C7_NUM")[1]+1, TAMSX3("C7_ITEM")[1] ) +"...","Aguarde enquanto processo as alterações no pedido...")
					
					if lMsErroAuto 
						MostraErro()
						lReturn := .F.
					Else
						MsgInfo( "O item "+ SubStr( aChvSC7[1], TAMSX3("C7_NUM")[1]+1, TAMSX3("C7_ITEM")[1] ) +" do pedido "+; 
						         SubStr( aChvSC7[1], 1, TAMSX3("C7_NUM")[1] ) +" foi alterado, pressione <b>F5</b> quando quiser atualizar "+;
						         "as informações do grid!","Pronto!" )
					EndIf
					
				EndIf
			Else
				MsgStop( "Não consegui encontrar pedidos pendentes com esse produto!","Alteração não permitida!" )
				lReturn := .F.
			EndIf
			
		ElseIf nColAtu == nPosBlq .and. aColPro[oBrwPro:nAt][nPosBlq] == 0
			lReturn := .F.
		EndIf
		
	EndIf

	if lReturn
		aFullPro[ aScan( aFullPro, {|x| x[nPosPrd] == aColPro[oBrwPro:nAt][nPosPrd] } ) ] := aClone( aColPro[oBrwPro:nAt] )
	endif

	SetKey( VK_F5, {|| Processa( {|| fLoadInf() }, 'Aguarde!','Analisando dados do MRP...' ) } )
	SetKey( VK_F12, {|| fManPar() } )
	
Return ( lReturn )

/*
+-----------------+-------------------------+---------------------------------+-------------------+
| Fonte: GMPAICOM | Funcao:  fVldGrid       | Autor: Jean Carlos P. Saggin    |  Data: 19.11.2019 |
+-----------------+-------------------------+---------------------------------+-------------------+
| Descricao: Função para validar as informações digitadas no grid                                 |
+-------------------------------------------------------------------------------------------------+
| Parametros recebidos:                                                                           |
| oGrid: Grid com os dados alterados                                                              |
| nNewQtd: Quantidade informada no grid principal do peinel de compras                            |
+-------------------------------------------------------------------------------------------------+
| Retorno da funcao: lRet (retorno .T.=Continua ou .F.=Bloqueia)                                  |
+-------------------------------------------------------------------------------------------------+  
*/
Static Function fVldGrid( oGrid, nNewQtd )
	
	Local lRet := .T.
	Local nSum := 0
	
	aEval( oGrid:aCols, {|x| nSum += x[ aScan( oGrid:aHeader, {|x| AllTrim( x[2] ) == "QUANT" } ) ] } )
	lRet := ( nSum == nNewQtd )
	
	If lRet
		aEval( oGrid:aCols, { |x| iif( x[ aScan( oGrid:aHeader, {|x| AllTrim( x[2] ) == "QUANT" } ) ] < 0, lRet := .F., lRet := lRet ) } )
	EndIf
	
Return ( lRet )

/*/{Protheus.doc} fLoadCfg
Função para leitura das configurações internas da rotina do painel de compras
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 18/07/2019
@param lAuto, logical, indica se a chamada da função foi realizada por rotina automática
/*/
Static Function fLoadCfg( lAuto )
	
	Local aArea   := GetArea()
	Local cAliCfg := AllTrim( SuperGetMv( 'MV_X_PNC03',,"999" ) ) 
	Local cPref   := cAliCfg + '->' + cAliCfg + '_'
	
	Private cCadastro := ""
	
	Default lAuto := .F.
	
	// Esvazia vetor antes de iniciar a leitura dos dados
	aConfig := {}
	
	// Valida existência do alias criado no ambiente para poder prosseguir
	if cEmpAnt != Nil .and. cFilAnt != Nil
		If Empty( cAliCfg ) .or. cAliCfg == "999"
			Return ( Nil )	
		EndIf
	Else
		Return ( Nil )
	EndIf
	
	DbSelectArea( cAliCfg )
	( cAliCfg )->( DbSetOrder( 1 ) )
	If ( cAliCfg )->( DbSeek( xFilial( cAliCfg ) + cEmpAnt + cFilAnt ) )
		
		aAdd( aConfig, &( cPref + 'PRJEST' ) )		// [01] - Projeção padrão de estoque em dias
		aAdd( aConfig, &( cPref + 'ITECRI' ) )		// [02] - Classificação de giro: Traz Itens críticos pré-selecionado?
		aAdd( aConfig, &( cPref + 'ITEALT' ) )		// [03] - Classificação de giro: Traz Itens alto giro pré-selecionado?
		aAdd( aConfig, &( cPref + 'ITEMED' ) )		// [04] - Classificação de giro: Traz Itens médio giro pré-selecionado?
		aAdd( aConfig, &( cPref + 'ITEBAI' ) )		// [05] - Classificação de giro: Traz Itens baixo giro pré-selecionado?
		aAdd( aConfig, &( cPref + 'ITESEM' ) )		// [06] - Classificação de giro: Traz Itens sem giro pré-selecionado?
		aAdd( aConfig, &( cPref + 'ITESOB' ) )		// [07] - Classificação de giro: Traz Itens sob demanda pré-selecionado?
		aAdd( aConfig, &( cPref + 'TIPANA' ) )		// [08] - Tipo de análise de sazonalidade do produto
		aAdd( aConfig, &( cPref + 'QTDANA' ) )		// [09] - Qtde de períodos para análise de sazonalidade do produto
		aAdd( aConfig, &( cPref + 'INDCRI' ) )		// [10] - Indice de insidência para produtos considerados críticos
		aAdd( aConfig, &( cPref + 'INDALT' ) )		// [11] - Indice de insidência para produtos considerados de alto giro
		aAdd( aConfig, &( cPref + 'INDMED' ) )		// [12] - Indice de insidência para produtos considerados de medio giro
		aAdd( aConfig, &( cPref + 'INDBAI' ) )		// [13] - Indice de insidência para produtos considerados de baixo giro
		aAdd( aConfig, &( cPref + 'TMPGIR' ) )		// [14] - Quantidade de tempo (em dias) para cálculo de giro dos produtos
		aAdd( aConfig, &( cPref + 'TPDIAS' ) )		// [15] - Tipo de dias (U=Uteis ou C=Corridos)
		aAdd( aConfig, &( cPref + 'LOCAIS' ) ) 		// [16] - Locais de estoque que o sistema vai realizar o somatório do saldo x produto
		aAdd( aConfig, &( cPref + 'USPDES' ) )		// [17] - Usuários a serem notificados quando um produto for sinalizado como descontinuado
		aAdd( aConfig, &( cPref + 'JUSPAD' ) )		// [18] - Codigo da justificativa padrão para eventos não analisado de dias anteriores
		
		// Valida existência do campo antes de prosseguir
		if ( cAliCfg )->( FieldPos( cPref + 'PRILE'  ) ) > 0	// [19] - Indica se prioriza lote econômico para sugestão da quantidade de compra
			aAdd( aConfig, &( cPref + 'PRILE'  ) )		
		else
			aAdd( aConfig, 'S' )					// [19] - Indica se prioriza lote econômico para sugestão da quantidade de compra
		endif

		if ( cAliCfg )->( FieldPos( cPref + 'CRIT' ) ) > 0
			aAdd( aConfig, StrTran( &( cPref + 'CRIT' ), ' ', '1' ) )		// Default 1=preço
		else
			aAdd( aConfig, '1' )					// [20] - Critério de escolha do melhor fornecedor 1=Preço 2=L.Time
		endif

		if ( cAliCfg )->( FieldPos( cPref + 'TIPOS' ) ) > 0 .and. ! Empty( &( cPref + 'TIPOS' ) )
			aAdd( aConfig, &( cPref + 'TIPOS' ) )
		else
			aAdd( aConfig, 'MP/ME' )				// [21] - Tipos de produtos a serem considerados para a central de compras separados por "/"
		endif
		
	Elseif !lAuto
		If Aviso( 'Criar configurações?','Os parâmetros internos do painel de compras ainda não foram configurados, deseja configurá-los agora?', {'Sim','Deixa pra lá'}, 3 ) == 1
			
			cCadastro := "Parâmetros do painel de compras"
			if AxInclui( cAliCfg, 0, 3 ) == 1
				fLoadCfg()
			EndIf
		EndIf
	EndIf
	
	RestArea( aArea )
Return ( Nil )

/*
+-----------------+-------------------------+---------------------------------+-------------------+
| Fonte: GMPAICOM | Funcao:  fManPar        | Autor: Jean Carlos P. Saggin    |  Data: 18.07.2019 |
+-----------------+-------------------------+---------------------------------+-------------------+
| Descricao: Função para manutenção dos parâmetros internos da rotina.                            |
+-------------------------------------------------------------------------------------------------+
| Parametros recebidos: nenhum                                                                    |
+-------------------------------------------------------------------------------------------------+
| Retorno da funcao: Nil                                                                          |
+-------------------------------------------------------------------------------------------------+  
*/
Static Function fManPar()
	
	Local aArea   := GetArea()
	Local cAliCfg := AllTrim( SuperGetMv( 'MV_X_PNC03',,"999" ) ) 
	
	Private cCadastro := ""
	
	// Valida existência do alias criado no ambiente para poder prosseguir
	if cEmpAnt != Nil .and. cFilAnt != Nil
		If Empty( cAliCfg ) .or. cAliCfg == "999"
			Return ( Nil )	
		EndIf
	Else
		Return ( Nil )
	EndIf
	
	DbSelectArea( cAliCfg )
	( cAliCfg )->( DbSetOrder( 1 ) )
	If ( cAliCfg )->( DbSeek( xFilial( cAliCfg ) + cEmpAnt + cFilAnt ) )
		
		cCadastro := "Alteração de configurações internas"
		If AxAltera( cAliCfg, ( cAliCfg )->( Recno() ), 4 ) == 1
			fLoadCfg()
			Processa( {|| fLoadInf() }, 'Aguarde!','Analisando dados do MRP...' )
		EndIf
		
	EndIf
	
	RestArea( aArea )
Return ( Nil )

/*/{Protheus.doc} GMINDPRO
Função para recalcular os índices do produtos para a rotina do painel de compras
@type function
@version 12.1.25
@author Jean Carlos Pandolfo Saggin
@since 22/07/2019
@param aParam, array, Parâmetros recebidos para execução da rotina via schedule
/*/
User Function GMINDPRO( aParam )
	
	Local cQuery    := ""
	Local nIndGir   := 0
	Local nConMed   := 0
	Local lEvento   := .F.
	Local cMsg      := ""
	Local nPrjEst   := 0
	Local nQtdCom   := 0
	Local nQtd      := 0
	Local nAtu      := 0
	Local aInfPrd   := {}
	Local aPerAna   := {}
	Local nDUteis   := 0
	Local dIniPer   := Date()
	Local dAux      := Date()
	Local lFunIna   := .F.
	local nLeadTime := 0  as numeric
	local cLeadTime := "" as character
 	local lMVPNC12  := .F. as logical
	local lManual   := .F. as logical
	local cFornece  := "" as character
	local cLoja     := "" as character
	Local aAux      := {} as array
	local nVenda    := 0 as numeric
	local nConsumo  := 0 as numeric

	Private _aFil    := {} as array
	Private cZB6     := "" as character
	Private aConfig  := {} as array
	Private cZB3     := "" as character
	Private cFormula := "" as character
	Private _aFilters := { Space(200),;
						   Space(200),; 
						   Space(TAMSX3('B1_PROC')[1]) }

	Default aParam := {}
	
	// Valida parâmetros
	if aParam != Nil .and. Len( aParam ) > 0
		
		ConOut( FunName() + ' - ' + DtoC( Date() ) + ' - ' + Time() + ' - ' + 'CONECTANDO NA EMPRESA EMPRESA '+ aParam[01] +' E FILIAL '+ aParam[02] +'!' )
		RpcClearEnv()
		RpcSetType( 3 )
		PREPARE ENVIRONMENT EMPRESA aParam[01] FILIAL aParam[02] TABLES "SB1,SD1,SA2" MODULO "CFG" 

		// Valida existência dos parâmetros do painel de compras antes de executar a rotina
		fLoadCfg( .T. /*lAuto*/ )
		if Len( aConfig ) == 0
			ConOut( FunName() + ' - ' + DtoC( Date() ) + ' - ' + Time() + ' - ' + 'PARAMETROS DO PAINEL DE COMPRAS NAO CADASTRADOS PARA A EMPRESA '+ cEmpAnt +' E FILIAL '+ cFilAnt +'!' )
			RESET ENVIRONMENT
			Return ( Nil )
		EndIf

	else
		lManual := .T.
		// Valida existência dos parâmetros do painel de compras antes de executar a rotina
		fLoadCfg()
		if Len( aConfig ) == 0
			hlp( 'SEMPARAMETROS',;
				 'Não foram encontrados parâmetros para o painel de compras',;
				 'Realize as configurações necessárias antes de prosseguir' )
			Return ( Nil )
		EndIf
	EndIf
	
	// Filiais
	_aFil := { cFilAnt }
	cZB6 := AllTrim( SuperGetMv( 'MV_X_PNC04',,"" ) )			// Alias da tabela ZB6 no ambiente do cliente
	cZB3 := AllTrim( SuperGetMv( 'MV_X_PNC02',,"" ) )			// Alias da tabela ZB3 no ambiente do cliente
	_aFilters[2] := PADR(aConfig[21],200,' ')					// pré-definições dos tipos de produtos a serem analisados

	// Valida se existe o parâmetro configurado no ambiente
	lMVPNC12 := GetMv( 'MV_X_PNC12', .T. /* lCheck */ )

	// Monta string referente aos armazens que serão utilizados para somatório dos saldos dos produtos
	cFormula := AllTrim( SuperGetMv( 'MV_X_PNC01',,"" ) )
	
	// Valida existência da função que analisa produtos pendentes de inativação
	lFunIna := ExistBlock( "GMPRDDES" )
	IF lFunIna
		ExecBlock( "GMPRDDES", .F., .F., Nil )
	EndIf
	
	// Verifica se o campo referente ao código de justificativa padrão já foi adicionado ao vetor de parâmetros
	if Len( aConfig ) >= 18 .and. !Empty( aConfig[18] )
		
		ConOut( "GMINDPRO - "+ Time() +" - JUSTIFICANDO NOTIFICACOES NAO TRATADAS DE DIAS ANTERIORES... " )
		
		cQuery := "UPDATE "+ RetSqlName( cZB3 ) +" SET "+ cZB3 +"_JUSTIF = '"+ aConfig[18] +"' "
		cQuery += "WHERE "+ cZB3 +"_FILIAL "+ U_JSFILIAL( cZB3, _aFil ) + " "
		cQuery += "  AND "+ cZB3 +"_AVISO  = 'S' "
		cQuery += "  AND "+ cZB3 +"_JUSTIF = '"+ Space( TAMSX3( cZB3 +"_JUSTIF")[01] ) +"' "
		cQuery += "  AND "+ cZB3 +"_DATA   < '"+ DtoS( Date() ) +"' "
		cQuery += "  AND D_E_L_E_T_ = ' ' "
		
		If TcSQLExec( cQuery ) < 0
			 ConOut( "GMINDPRO - "+ Time() +" - ERRO DURANTE EXECUCAO DO COMANDO: " + CEOL +;
			         cQuery + CEOL +;
			         Replicate( '-', 50 ) + CEOL +;
			         TCSQLError() )
		EndIf
		
	EndIf
	
	// Realiza chamada da rotina que analisa pedidos de compras com quantidade a classificar e sem pré-nota de entrada
	if ExistBlock( 'GMPCACLA' )
		ExecBlock( 'GMPCACLA', .T., .T., Nil )
	endif
	
	aPerAna := {}
	if aConfig[15] == 'C'
		aPerAna := { Date()-aConfig[14], Date() }
	Else
		nDUteis := 0
		nAux    := 0
		While nDUteis < aConfig[14]
			if DataValida( dIniPer - nAux, .T. ) == dIniPer - nAux
				nDUteis++
			EndIf
			nAux++
		EndDo
		aPerAna := { dIniPer - nAux, dIniPer }
	EndIf
	
	if lManual	
		_aFilters := prodFilter( _aFilters, lManual )
	endif

	// Obtem os dados dos produtos do MRP
	cQuery := U_JSQRYINF( aConfig, _aFilters )
	DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), 'PRDTMP', .F., .T. )
	
	Count to nQtd
	
	if lManual
		ProcRegua( nQtd )
	endif
	PRDTMP->( DbGoTop() )
	
	If !PRDTMP->( EOF() )
		
		DbSelectArea( 'SB1' )
	    DbSelectArea( cZB3 )
	    (cZB3)->( DbSetOrder( 1 ) )
	    	
    	While !PRDTMP->( EOF() )
    		
    		nAtu++
    		ConOut( FunName() + ' - ' + DtoC( Date() ) + ' - ' + Time() + ' - ' + 'ANALISANDO PRODUTO '+ AllTrim( SubStr( PRDTMP->B1_DESC, 01, 30 ) ) +' ( '+ AllTrim( PRDTMP->B1_COD ) +' )' )
			if lManual
				IncProc( 'Analisando produto '+ AllTrim( PRDTMP->B1_DESC ) +'... [ '+ cValToChar( Round((nAtu/nQtd)*100,0)) +'% ]' )
			endif
    		
			aAux := {}
			aAux := betterSupplier( PRDTMP->B1_COD, PRDTMP->B1_PROC, PRDTMP->B1_LOJPROC )
			cFornece := PADR( aAux[1], TAMSX3('A2_COD')[1], ' ')		// Codigo do fornecedor
			cLoja    := PADR( aAux[2], TAMSX3('A2_LOJA')[1], ' ' )		// Codigo da loja
			
			// Identifica lead-time conforme regra definida para produto, fornecedor (informado) ou fornecedor (calculado)
			if PRDTMP->B1_PE > 0
				nLeadTime := PRDTMP->B1_PE
				cLeadTime := 'P'		// Produto
			elseif PRDTMP->A2_X_LTIME > 0
				nLeadTime := PRDTMP->A2_X_LTIME
				cLeadTime := 'F'		// Fornecedor Padrao
			else
				nLeadTime := calcLt( PRDTMP->B1_COD, cFornece, cLoja )
				cLeadTime := 'C'		// Calculado
			endif 
			
    		dDatInc := StoD( '20100101' )
    		nIndGir := 0
    		nConMed := 0

			// Posiciona no registro físico do produto
    		SB1->( DbGoTo( PRDTMP->RECSB1 ) )
		
			// Valida existência de campo customizado que armazena data da inclusao do produto
			if SB1->( FieldPos( 'B1_X_DTINC' ) ) > 0 .and. !Empty( SB1->B1_X_DTINC )
				dDatInc := SB1->B1_X_DTINC
			elseif SB1->( FieldPos( 'B1_USERLGI' ) ) > 0
				dDatInc := CtoD( FWLeUserlg( 'B1_USERLGI', 2 ) )
			else
				dDatInc := StoD( " " )
			endif

			// Valida conteúdo retornado pelo log de usuários
			if dDatInc < StoD( '20100101' )
				dDatInc := StoD( '20100101' )
			EndIf
			
			// Comando para leitura do índice de giro dos produtos
			cQuery := "SELECT ROUND( QTD_PRODUTO / CASE WHEN QTD_PEDIDOS = 0 THEN 1 ELSE QTD_PEDIDOS END, "+ cValToChar( TAMSX3( cZB3 + "_INDINC" )[2] ) +") AS INDGIRO FROM ( " + CEOL
			cQuery += "SELECT "+ CEOL
			cQuery += "	COALESCE(SUM( CASE WHEN D2.D2_COD = '"+ PRDTMP->B1_COD +"' THEN 1 ELSE 0 END ),0) QTD_PRODUTO, " + CEOL
			cQuery += "	COUNT( DISTINCT CONCAT( D2.D2_DOC, D2.D2_SERIE ) ) QTD_PEDIDOS "+ CEOL
			cQuery += "FROM "+ RetSqlName( "SD2" ) +" D2 " + CEOL
			cQuery += "WHERE D2.D2_FILIAL  "+ U_JSFILIAL( 'SD2', _aFil ) +" " + CEOL
			cQuery += "  AND D2.D2_EMISSAO >= '"+ DtoS( iif( aPerAna[01] > dDatInc, aPerAna[01], dDatInc ) ) +"' " + CEOL
			cQuery += "  AND D2.D2_CLIENTE <> '"+ PADR( SubStr( SM0->M0_CGC, 01, 08 ), TAMSX3('D2_CLIENTE')[1], ' ' ) +"' " + CEOL
			cQuery += "  AND D2.D_E_L_E_T_ = ' ' ) " + CEOL
			
			DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), 'INDPRO', .F., .T. )
			if !INDPRO->( EOF() )
				nIndGir := INDPRO->INDGIRO
			EndIf
			INDPRO->( DBCloseArea() )
			
			//ConOut( FunName() + ' - ' + DtoC( Date() ) + ' - ' + Time() + ' - ' + 'CONSUMO MEDIO DO PRODUTO '+ AllTrim( SubStr( PRDTMP->B1_DESC, 01, 30 ) ) +' ( '+ AllTrim( PRDTMP->B1_COD ) +' ) A PARTIR DE '+ DtoC( iif( ( Date() - aConfig[14] ) > dDatInc, Date() - aConfig[14], dDatInc ) ) )
			
			nDUteis := 0
			if aPerAna[01] >= dDatInc
				nDUteis := aConfig[14]
			Elseif aPerAna[01] < dDatInc .and. aConfig[15] == "C"
				nDUteis := Date() - dDatInc 
			ElseIf aPerAna[01] < dDatInc .and. aConfig[15] == "U"
				nDUteis := 0
				nAux    := 0
				dAux    := dDatInc
				While ( dAux + nAux ) < Date()
					if DataValida( dAux + nAux, .T. ) == dAux + nAux
						nDUteis++
					EndIf
					nAux++
				EndDo
			EndIf
			
			cQuery := "SELECT COALESCE(SUM(D2.D2_QUANT),0) AS QTD_TOTAL FROM "+ RetSqlName( 'SD2' ) +" D2 " + CEOL
			cQuery += "INNER JOIN "+ RetSqlName( 'SF4' ) +" F4 " + CEOL
			cQuery += " ON "+ U_JSFILCOM( 'SF4', 'SD2' ) +" " + CEOL
			cQuery += "AND F4.F4_CODIGO = D2.D2_TES "+ CEOL
			cQuery += "AND F4.F4_ESTOQUE = 'S' "+ CEOL
			cQuery += "AND F4.D_E_L_E_T_ = ' ' "+ CEOL
			cQuery += "WHERE D2.D2_FILIAL "+ U_JSFILIAL( 'SD2', _aFil ) +" "+ CEOL
			cQuery += "  AND D2.D2_TIPO   = 'N' "+ CEOL
			cQuery += "  AND D2.D2_EMISSAO >= '"+ DtoS( iif( aPerAna[01] > dDatInc, aPerAna[01], dDatInc ) ) +"' " + CEOL
			cQuery += "  AND D2.D2_CLIENTE <> '"+ PADR(SubStr( SM0->M0_CGC, 01, 08 ),TAMSX3('C5_CLIENTE')[1], ' ' ) +"' " + CEOL
			cQuery += "  AND D2.D2_COD     = '"+ PRDTMP->B1_COD +"' " + CEOL
			cQuery += "  AND D2.D_E_L_E_T_ = ' ' " + CEOL
			
			DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), "MEDCON", .F., .T. )
			nVenda := MEDCON->QTD_TOTAL
			MEDCON->( DbCloseArea() )
			
			cQuery := "SELECT COALESCE(SUM(D3.D3_QUANT),0) AS QTD_TOTAL FROM "+ RetSqlName( 'SD3' ) +" D3 " + CEOL
			cQuery += "WHERE D3.D3_FILIAL "+ U_JSFILIAL( "SD3", _aFil ) +" " + CEOL
			cQuery += "  AND D3.D3_COD    = '"+ PRDTMP->B1_COD +"' " + CEOL
			cQuery += "  AND D3.D3_EMISSAO >= '"+ DtoS( iif( aPerAna[01] > dDatInc, aPerAna[01], dDatInc ) ) +"' " + CEOL
			cQuery += "  AND D3.D3_TM     >= '500' " + CEOL
			cQuery += "  AND D3.D3_ESTORNO = ' ' " + CEOL
			cQuery += "  AND D3.D_E_L_E_T_ = ' ' " 

			DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), "MEDCON", .F., .T. )
			nConsumo := MEDCON->QTD_TOTAL
			MEDCON->( DbCloseArea() )


			if (nVenda + nConsumo) != 0
				nConMed := Round((nVenda+nConsumo) / iif( nDUteis == 0, 1, nDUteis ),4)
			Else
				nConMed := 0.0001
			EndIf
    		
    		lEvento := .F.
    		cMsg    := ""
    		nPrjEst := 0
    		dPrjAux := Date()
    		nDUteis := 0
    		
    		// Calcula duração do estoque do produto baseado nas variáveis: consumo médio, estoque disponível, quantidade já comprada e data de previsão de entrega do fornecedor
    		nPrjEst := Round( ( PRDTMP->ESTOQUE - PRDTMP->EMPENHO + PRDTMP->QTDCOMP )/nConMed, 0 ) 
    		if nPrjEst > 999 
    			nPrjEst := 999
    		Else
				// Tratativa para os casos em que ocorrer do produto ficar com estoque negativo
    			if nPrjEst < 0
					nPrjEst := 0
				endif
    			if nPrjEst < ( aConfig[01] + nLeadTime )
    				lEvento := .T.
					if nPrjEst == 0
						cMsg    := 'ATENÇÃO! Ruptura de estoque identificada!'
					Else
						
						// Verifica a duração do estoque considerando dias úteis ou dias corridos de acordo com o parâmetro
						if aConfig[15] == "C"
			    			dPrjAux := Date() + nPrjEst
			    		Else
			    			nAux := 0
			    			nDUteis := 0
			    			While nDUteis < nPrjEst
			    				
			    				if DataValida( Date() + nAux, .T. ) == Date() + nAux
			    					nDUteis++
			    				EndIf
			    				
			    				nAux++
			    			EndDo
			    			dPrjAux := Date() + nAux
			    		EndIf
						
						cMsg    := 'Risco de ruptura em '+ DtoC( dPrjAux )
					EndIf
    			EndIf
    		EndIf
    		
    		// Verifica se tem produto já comprado que esteja com previsão de entrega vencida
    		If PRDTMP->QTDCOMP > 0 .and. StoD( PRDTMP->PRVENT ) < Date()
	    		
	    		// Verifica a possibilidade de ruptura de acordo com a configuração (dias úteis ou dias corridos)
				if Round( ( PRDTMP->ESTOQUE - PRDTMP->EMPENHO )/nConMed, 0 ) < aConfig[01] 
					if aConfig[15] == "C"
		    			dPrjAux := Date() + Round( ( PRDTMP->ESTOQUE - PRDTMP->EMPENHO )/nConMed, 0 )
		    		Else
		    			nDUteis := 0 
		    			nAux    := 0
		    			While nDUteis < Round( ( PRDTMP->ESTOQUE - PRDTMP->EMPENHO )/nConMed, 0 )
		    				
		    				if DataValida( Date() + nAux, .T. ) == Date() + nAux
		    					nDUteis++
		    				EndIf
		    				
		    				nAux++
		    			EndDo
		    			dPrjAux := Date() + nAux
		    		EndIf
	    		EndIf
	    		
	    		lEvento := .T.
	    		cMsg    := "Compra com atraso na entrega"+; 
	    		           iif( Round( ( PRDTMP->ESTOQUE - PRDTMP->EMPENHO )/nConMed, 0 ) > aConfig[01],; 
	    		           ', mas sem risco de ruptura pelos próximos '+ AllTrim( cValToChar( aConfig[01] ) ) +' dias',; 
	    		           iif( Round( ( PRDTMP->ESTOQUE - PRDTMP->EMPENHO )/nConMed, 0 ) == 0,; 
	    		           ' e está sem estoque disponível',; 
	    		           iif( Round( ( PRDTMP->ESTOQUE - PRDTMP->EMPENHO )/nConMed, 0 ) < aConfig[01],; 
	    		           '. Risco de ruptura em '+ DtoC( dPrjAux ), '' ) ) ) +"."
			EndIf
    		
    		// Trata exceções dos eventos para os produtos sinalizados manualmente pelo operador
    		if lEvento
    			DBSelectArea( cZB6 )
    			(cZB6)->( DBSetOrder( 1 ) )
    			If DBSeek( xFilial( cZB6 ) + PRDTMP->B1_COD )
    				if (cZB6)->( FieldGet( FieldPos( cZB6 +'_DTLIM' ) ) ) >= Date()
    					cMsg    := "IGNORA AUTO: "+ cMsg
    				EndIf
    			EndIf
    		EndIf
    		
    		aInfPrd := { aConfig[01] /*nDias*/,;
    		             nLeadTime /*nLdTime*/,;
    		             nPrjEst,;
    		             nConMed,;
    		             PRDTMP->B1_LM /*nLotMin*/,;
    		             PRDTMP->B1_QE /*nQtdEmb*/,;
						 PRDTMP->B1_LE /* nLotEco */,;
						 PRDTMP->B1_EMIN /* nEstSeg */,;
						 PRDTMP->ESTOQUE,;
						 PRDTMP->EMPENHO,;
						 PRDTMP->QTDCOMP }

    		// Calcula necessidade de compra do material
    		nQtdCom := fCalNec( aInfPrd )  
    		
    		// Valida existência de chave primária da tabela
    		If (cZB3)->( DbSeek( xFilial( cZB3 ) + PRDTMP->B1_COD + DtoS( Date() ) ) )
    			
    			ConOut( FunName() + ' - ' + DtoC( Date() ) + ' - ' + Time() + ' - ' + cValToChar( nAtu ) + '/' + cValToChar( nQtd ) + ' - ATUALIZANDO DADOS DO PRODUTO '+ AllTrim( SubStr( PRDTMP->B1_DESC, 01, 30 ) ) +' ( '+ AllTrim( PRDTMP->B1_COD ) +' )' )
    			
    			RecLock( cZB3, .F. )
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_INDINC' ), nIndGir ) )
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_CONMED' ), nConMed ) )
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_TMPGIR' ), aConfig[14] ) )
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_TPDIAS' ), aConfig[15] ) )
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_PRJEST' ), nPrjEst ) )
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_NECCOM' ), nQtdCom ) )
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_SALDO'  ), PRDTMP->ESTOQUE ) )
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_QTDEMP' ), PRDTMP->EMPENHO ) ) 
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_QTDCOM' ), PRDTMP->QTDCOMP ) )
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_LDTIME' ), nLeadTime ) )
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_PRVENT' ), StoD( PRDTMP->PRVENT ) ) )
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_AVISO'  ), iif( lEvento, 'S','N' ) ) )
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_MSG'    ), cMsg ) )	
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_JUSTIF' ), iif( "IGNORA" $ cMsg, aConfig[18], Space( TAMSX3( cZB3 +"_JUSTIF")[01] ) ) ) )			
    			(cZB3)->( MsUnlock() )
    		Else
    			
    			ConOut( FunName() + ' - ' + DtoC( Date() ) + ' - ' + Time() + ' - ' + cValToChar( nAtu ) + '/' + cValToChar( nQtd ) + ' - GRAVANDO DADOS DO PRODUTO '+ AllTrim( SubStr( PRDTMP->B1_DESC, 01, 30 ) ) +' ( '+ AllTrim( PRDTMP->B1_COD ) +' )' )
    			
    			RecLock( cZB3, .T. )
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_FILIAL' ), xFilial( cZB3 ) ) )
    			( cZB3 )->( FieldPut( FieldPos( cZB3 +'_PROD'   ), PRDTMP->B1_COD ) )
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_DATA'   ), Date() ) )
    			( cZB3 )->( FieldPut( FieldPos( cZB3 +'_INDINC' ), nIndGir ) )
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_CONMED' ), nConMed ) )
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_TMPGIR' ), aConfig[14] ) )
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_TPDIAS' ), aConfig[15] ) )
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_PRJEST' ), nPrjEst ) )
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_NECCOM' ), nQtdCom ) )
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_SALDO'  ), PRDTMP->ESTOQUE ) )
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_QTDEMP' ), PRDTMP->EMPENHO ) ) 
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_QTDCOM' ), PRDTMP->QTDCOMP ) )
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_LDTIME' ), nLeadTime ) )
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_PRVENT' ), StoD( PRDTMP->PRVENT ) ) )
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_AVISO'  ), iif( lEvento, 'S','N' ) ) )
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_MSG'    ), cMsg ) )	
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_JUSTIF' ), iif( "IGNORA" $ cMsg, aConfig[18], Space( TAMSX3( cZB3 +"_JUSTIF")[01] ) ) ) )
    			( cZB3 )->( MsUnlock() )
    		EndIf
    		
    		PRDTMP->( DbSkip() )
    	EndDo
    EndIf
    
    PRDTMP->( DbCloseArea() )
	
	if lMVPNC12
		PutMV( 'MV_X_PNC12', FWTimeStamp(2) )
	endif

	// Prepara desconexão da rotina automática
	if ! lManual
		ConOut( FunName() + ' - ' + DtoC( Date() ) + ' - ' + Time() + ' - ' + 'DESCONECTANDO DA EMPRESA '+ cEmpAnt +' E FILIAL '+ cFilAnt +'!' )
		RESET ENVIRONMENT
	EndIf
	
	ConOut( FunName() + ' - ' + DtoC( Date() ) + ' - ' + Time() + ' - ' + 'FIM DA ROTINA DE RECALCULO DE INDICES DO PRODUTO!' )
	
Return ( Nil )

/*/{Protheus.doc} fCalNec
FUnção que calcula a necessidade de compra para o produto com base na fórmula definida
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/04/2024
@param aInfPrd, array, vetor com informações sobre o produto
@return numeric, nQtdCom
/*/
Static Function fCalNec( aInfPrd )
	
	local lPriLE    := aConfig[19] == 'S'
	Private nQtdCom := 0
	Private nDias   := 0
	Private nLdTime := 0
	Private nPrjEst := 0
	Private nConMed := 0
	Private nLotMin := 0
	Private nQtdEmb := 0
	Private nLotEco := 0 as numeric
	Private nEstSeg := 0 as numeric
	Private nQtdEst := 0 as numeric
	Private nQtdEmp := 0 as numeric
	Private nQtdPed := 0 as numeric
	
	nDias   := aInfPrd[1]
	nLdTime := aInfPrd[2]
	nPrjEst := aInfPrd[3]
	nConMed := aInfPrd[4]
	nLotMin := aInfPrd[5]
	nQtdEmb := aInfPrd[6]
	nLotEco := aInfPrd[7]
	nEstSeg := aInfPrd[8]
	nQtdEst := aInfPrd[9]		// Qtde em estoque
	nQtdEmp := aInfPrd[10]		// Quantidade empenhada
	nQtdPed := aInfPrd[11]		// Quantidade em pedido de compra não atendido

	// Realiza análise de critérios de compras conforme configurações
	nQtdCom += iif( Round( &( fLoadCri( cFormula, .T. ) ),0) < 0, 0, Round( &( fLoadCri( cFormula, .T. ) ),0) )	// (( nDias + nLdTime ) - nPrjEst ) * nConMed
	
	// Verifica cadastro de quantidade de embalagem para o produto
	if nQtdCom > 0 
		
		// Se a quantidade de compra não atingir o lote mínimo, altera para o lote mínimo
		if nQtdCom < nLotMin
			nQtdCom := nLotMin
		endif

		// Define a quantidade de compra com base no lote econômico
		if lPriLE .and. nLotEco > 0
			if ( nQtdCom % nLotEco ) != 0
				nQtdCom := ( Int( nQtdCom/nLotEco ) + 1 ) * nLotEco
			endif
		endif
		
		// Valida se quantidade da embalagem está cadastrada para tornar a demanda compatível com múltiplos da embalagem
		if nQtdEmb > 0
			if ( nQtdCom  % nQtdEmb ) != 0
				nQtdCom := ( Int( nQtdCom/nQtdEmb ) + 1 ) * nQtdEmb
			EndIf
		EndIf

	EndIf
	
Return ( nQtdCom )

/*
+-----------------+-------------------------+---------------------------------+-------------------+
| Fonte: GMPAICOM | Funcao:  fMarkAll       | Autor: Jean Carlos P. Saggin    |  Data: 25.07.2019 |
+-----------------+-------------------------+---------------------------------+-------------------+
| Descricao: Função para marcar/desmarcar todos os itens do browse de fornecedores                |
+-------------------------------------------------------------------------------------------------+
| Parametros recebidos: nenhum                                                                    |
+-------------------------------------------------------------------------------------------------+
| Retorno da funcao: Nil                                                                          |
+-------------------------------------------------------------------------------------------------+  
*/
Static Function fMarkAll()
	
	Local lMarked := .F.
	Local nForAtu := FORTMP->( Recno() )
	
	FORTMP->( DbGoTop() )
	if !FORTMP->( EOF() )
		lMarked := !Empty( FORTMP->MARK )
		While !FORTMP->( EOF() )
			
			RecLock( 'FORTMP', .F. )
			FORTMP->MARK := iif( lMarked, Space( 2 ), cMark )
			FORTMP->( MsUnlock() )
			
			FORTMP->( DbSkip() )
		EndDo
	EndIf
	
	If nForAtu > 0
		FORTMP->( DbGoTo( nForAtu ) )
	EndIf
	
	// Força atualização do browse do fornecedor
	oBrwFor:oBrowse:Refresh()
	
	Processa( {|| fLoadInf() }, 'Aguarde!','Buscando informações dos produtos...' )

Return ( Nil )

/*/{Protheus.doc} doFormul 
Função de manutenção da fórmula de cálculo da necessidade de compra
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 09/04/2024
@param cFormAtu, character, formula atual
@return character, cFormula
/*/
Static Function doFormul( cFormAtu )
	
	Local oBtnAbP  := Nil
	Local oBtnAdd  := Nil
	Local oBtnCan  := Nil
	Local oBtnDiv  := Nil
	Local oBtnFeP  := Nil
	Local oBtnGrv  := Nil
	Local oBtnMai  := Nil
	Local oBtnMen  := Nil
	Local oBtnVez  := Nil
	Local oCboVar  := Nil
	Local oCompon  := Nil
	Local oFntFor  := TFont():New("Courier New", , 014, , .T., , , , , .F., .F.)
	Local oGetFor  := Nil
	Local oLblVar  := Nil
	
	Private cFormTmp := cFormAtu		// Formula temporária
	Private oDlgCri  := Nil
	Private cCboVar  := ""
	Private cGetFor  := ""

	default cFormAtu := AllTrim( SuperGetMv( 'MV_X_PNC01',,"" ) )
	
	// Chama função de interpretação de fórmula
	cGetFor := fLoadCri( cFormAtu )
	
	DEFINE MSDIALOG oDlgCri TITLE "Critério de Compra" FROM 000, 000 TO 175, 530 COLORS 0, 16777215 PIXEL

    @ 025, 004 GROUP oCompon TO 052, 265 PROMPT "   Componentes para definição da fórmula de cálculo  " OF oDlgCri COLOR 0, 16777215 PIXEL
    @ 037, 006 SAY oLblVar PROMPT "Variáveis" SIZE 025, 007 OF oDlgCri COLORS 0, 16777215 PIXEL
    @ 054, 004 MSGET oGetFor VAR cGetFor SIZE 262, 015 OF oDlgCri COLORS 0, 16777215 WHEN .F. FONT oFntFor PIXEL
    @ 035, 032 MSCOMBOBOX oCboVar VAR cCboVar ITEMS fGetVar( 1 /*nOpc*/ ) SIZE 070, 013 OF oDlgCri  COLORS 0, 16777215 PIXEL
    @ 035, 104 BUTTON oBtnAdd PROMPT "&Adicionar" SIZE 035, 012 OF oDlgCri ACTION {|| cGetFor := fManFor( 1 /*nOpc*/,, cFormTmp ), oDlgCri:Refresh() } PIXEL
    @ 035, 141 BUTTON oBtnRem PROMPT "&Remover" SIZE 035, 012 OF oDlgCri ACTION {|| cGetFor := fManFor( 2 /*nOpc*/,, cFormTmp ), oDlgCri:Refresh() } PIXEL
    @ 035, 265-(12*6)-(2*6) BUTTON oBtnAbP PROMPT "(" SIZE 012, 012 OF oDlgCri ACTION {|| cGetFor := fManFor( 3 /*nOpc*/, oBtnAbP:CCAPTION /*cOpc*/, cFormTmp ), oDlgCri:Refresh() } PIXEL
    @ 035, 265-(12*5)-(2*5) BUTTON oBtnFeP PROMPT ")" SIZE 012, 012 OF oDlgCri ACTION {|| cGetFor := fManFor( 3 /*nOpc*/, oBtnFeP:CCAPTION /*cOpc*/, cFormTmp ), oDlgCri:Refresh() } PIXEL
    @ 035, 265-(12*4)-(2*4) BUTTON oBtnMen PROMPT "-" SIZE 012, 012 OF oDlgCri ACTION {|| cGetFor := fManFor( 3 /*nOpc*/, oBtnMen:CCAPTION /*cOpc*/, cFormTmp ), oDlgCri:Refresh() } PIXEL
    @ 035, 265-(12*3)-(2*3) BUTTON oBtnMai PROMPT "+" SIZE 012, 012 OF oDlgCri ACTION {|| cGetFor := fManFor( 3 /*nOpc*/, oBtnMai:CCAPTION /*cOpc*/, cFormTmp ), oDlgCri:Refresh() } PIXEL
    @ 035, 265-(12*2)-(2*2) BUTTON oBtnDiv PROMPT "/" SIZE 012, 012 OF oDlgCri ACTION {|| cGetFor := fManFor( 3 /*nOpc*/, oBtnDiv:CCAPTION /*cOpc*/, cFormTmp ), oDlgCri:Refresh() } PIXEL
    @ 035, 265-(12*1)-(2*1) BUTTON oBtnVez PROMPT "x" SIZE 012, 012 OF oDlgCri ACTION {|| cGetFor := fManFor( 3 /*nOpc*/, "*" /*cOpc*/, cFormTmp ), oDlgCri:Refresh() } PIXEL
    @ 073, 265-(37*1)-(2*0) BUTTON oBtnCan PROMPT "&Cancelar" SIZE 037, 012 OF oDlgCri ACTION oDlgCri:End() WHEN .T. PIXEL
    @ 073, 265-(37*2)-(2*1) BUTTON oBtnGrv PROMPT "&Gravar" SIZE 037, 012 OF oDlgCri ACTION {|| cFormula := fGrvCri( cFormTmp ), oDlgCri:End() } PIXEL
    
    ACTIVATE MSDIALOG oDlgCri CENTERED
	
Return ( cFormula )

/*/{Protheus.doc} fGrvCri
Função responsável pela gravação da configuração do critério de compra
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 09/04/2024
@param cFormula, character, formula de cálculo da necessidade de compra
@return character, cFormula
/*/
Static Function fGrvCri( cFormula )
	
	local cSX6    := "SX6" as character
	local lInc    := ! GetMv( 'MV_X_PNC01', .T. /* lCheck */ ) 	
	
	if lInc
		DBSelectArea( cSX6 )
		( cSX6 )->( DBSetOrder( 1 ) )
		RecLock( cSX6, .T. )
		( cSX6 )->(FieldPut( FieldPos( 'X6_FIL' ), Space( Len( cFilAnt ) ) ))
		( cSX6 )->(FieldPut( FieldPos( 'X6_VAR' ), 'MV_X_PNC01' ))
		( cSX6 )->(FieldPut( FieldPos( 'X6_TIPO' ), 'C' ))
		( cSX6 )->(FieldPut( FieldPos( 'X6_DESCRIC' ), 'Formula de calculo da necessidade de compra do ' ))
		( cSX6 )->(FieldPut( FieldPos( 'X6_DESC1' ), 'Painel de Compra' ))
		( cSX6 )->(FieldPut( FieldPos( 'X6_DSCSPA' ), 'Formula de calculo da necessidade de compra do ' ))
		( cSX6 )->(FieldPut( FieldPos( 'X6_DSCSPA1' ), 'Painel de Compra' ))
		( cSX6 )->(FieldPut( FieldPos( 'X6_DSCENG' ), 'Formula de calculo da necessidade de compra do ' ))
		( cSX6 )->(FieldPut( FieldPos( 'X6_DSCENG1' ), 'Painel de Compra' ))
		( cSX6 )->(FieldPut( FieldPos( 'X6_CONTEUD' ), cFormula ))
		( cSX6 )->(FieldPut( FieldPos( 'X6_CONTSPA' ), cFormula ))
		( cSX6 )->(FieldPut( FieldPos( 'X6_CONTENG' ), cFormula ))
		( cSX6 )->(FieldPut( FieldPos( 'X6_PROPRI' ), 'S' ))
		(cSX6)->( MsUnlock() )
	else
		PutMV( 'MV_X_PNC01', cFormula )
	endif
	
Return ( cFormula )

/*
+-----------------+-------------------------+---------------------------------+-------------------+
| Fonte: GMPAICOM | Funcao:  fManFor        | Autor: Jean Carlos P. Saggin    |  Data: 26.07.2019 |
+-----------------+-------------------------+---------------------------------+-------------------+
| Descricao: Função que retorna as variáveis que poderão ser utilizadas na composição da fórmula  |
|            de cálculo das necessidades de compra                                                |
+-------------------------------------------------------------------------------------------------+
| Parametros recebidos:                                                                           |
| nOpc: ( 1=Adiciona conteúdo, 2=Remove conteúdo ou 3=Adiciona Operador )                         |
| cOpc: Operador que será adicionado à fórmula                                                    |
+-------------------------------------------------------------------------------------------------+
| Retorno da funcao: bRet                                                                         |
| O retorno da função deverá ser dinâmico de acordo com o parâmetro recebido 1=Conteúdo Combo ou  |
| 2=Variáveis Disponíveis                                                                         |
+-------------------------------------------------------------------------------------------------+  
*/
Static Function fManFor( nOpc, cOpc, cGetFor )
	
	Local aItens   := {}
	Local cVar     := ""
	Local nX       := 0
	local cAux     := "" as character
	
	Default cOpc := ""
	
	cAux := cGetFor // Inicializa com conteúdo atual da fórmula
	if nOpc == 1 .or. nOpc == 3				// Adicionar
		cVar     := fGetVar(2)[aScan( fGetVar(2), {|x| AllTrim(x[1]) == cCboVar } )][02]
		cAux += iif( !Empty( cAux ), CSEPARA, "" ) + iif( !Empty( cOpc ), cOpc, cVar ) 
	ElseIf nOpc == 2						// Remover
		if !Empty( cAux )
			aItens := StrTokArr( AllTrim( cAux ), CSEPARA )
			If Len( aItens ) > 0
				aDel( aItens, Len( aItens ) )
				aSize( aItens, Len( aItens )-1 )
			EndIf
			cAux := ""
			If Len( aItens ) > 0
				For nX := 1 to Len( aItens )
					cAux += iif( !Empty( cAux ), CSEPARA, "" ) + aItens[nX]
				Next nX
			EndIf
		EndIf
	EndIf
	
	cFormTmp := cAux
	cAux := fLoadCri( cAux )
	
Return ( cAux )

/*/{Protheus.doc} fLoadCri
Função de leitura e interpretação da fórmula de cálculo de necessidade de compra
@type function
@version 1.0	
@author Jean Carlos Pandolfo Saggin	
@since 11/04/2024
@param cCodCri, character, formula existente
@return character, cReturn
/*/
Static Function fLoadCri( cCodCri, lVar )
	
	Local cRet   := ""
	Local aItens := ""
	Local aVar   := {}
	Local nX     := 0
	
	Default cCodCri := ""
	Default lVar    := .F.		// Indica se o retorno deve ser da variável ou da descrição dela .T.=Variável .F.=Descrição
	
	// Verifica se for visualização, alteração ou exclusão
	if ! Empty( cCodCri )
		
		aItens := StrTokArr( AllTrim( cCodCri ), CSEPARA )
		aVar   := fGetVar(2)
		
		if Len( aItens ) > 0
			cRet := ""
			For nX := 1 to Len( aItens )
				cRet += iif( aScan( aVar, {|y| y[2] == AllTrim( aItens[nX] ) } ) > 0, aVar[aScan( aVar, {|y| y[2] == AllTrim( aItens[nX] ) } )][iif( lVar, 02, 01)], aItens[nX] ) +' '
			Next nX
		EndIf
		
    Else // É Inclusão
		cRet := Space( 200 )
	EndIf
	
Return ( cRet )

/*
+-----------------+-------------------------+---------------------------------+-------------------+
| Fonte: GMPAICOM | Funcao:  fGetVar        | Autor: Jean Carlos P. Saggin    |  Data: 26.07.2019 |
+-----------------+-------------------------+---------------------------------+-------------------+
| Descricao: Função que retorna as variáveis que poderão ser utilizadas na composição da fórmula  |
|            de cálculo das necessidades de compra                                                |
+-------------------------------------------------------------------------------------------------+
| Parametros recebidos: nOpc ( 1=Conteúdo Combo ou 2=Variáveis Disponíveis )                      |
+-------------------------------------------------------------------------------------------------+
| Retorno da funcao: bRet                                                                         |
| O retorno da função deverá ser dinâmico de acordo com o parâmetro recebido 1=Conteúdo Combo ou  |
| 2=Variáveis Disponíveis                                                                         |
+-------------------------------------------------------------------------------------------------+  
*/
Static Function fGetVar( nOpc )
	
	Local aVar := {}
	Local aCbo := {}
	Local bRet := Nil
	 
	aAdd( aVar, { 'Sld. Prod.' , 'nQtdEst'         } )
	aAdd( aVar, { 'Empenhado'  , 'nQtdEmp'         } )
	aAdd( aVar, { 'Dias Pret.' , 'nDias'           } )
	aAdd( aVar, { 'L-Time'     , 'nLdTime'         } )
	aAdd( aVar, { 'Dura. Est.' , 'nPrjEst'         } )
	aAdd( aVar, { 'Cons. Med.' , 'nConMed'         } )
	aAdd( aVar, { 'Lote Min.'  , 'nLotMin'         } )
	aAdd( aVar, { 'Qtde Emb.'  , 'nQtdEmb'         } )
	aAdd( aVar, { 'Qtde Comp.' , 'nQtdPed'         } )
	aAdd( aVar, { 'Estoq. Min.', 'nEstSeg'         } )
	
	aSort( aVar,,, { |x,y| x[01] < y[01] } )
	aEval( aVar,{ |x| aAdd( aCbo, x[1] ) } )
	
	// Retorna a estrutura do conteúdo de acordo com a necessidade
	if nOpc == 1
		cCboVar := aCbo[01]
		bRet    := aCbo
	Else
		bRet := aVar
	EndIf
	
Return ( bRet )

/*/{Protheus.doc} fCarCom
Função referente ao carrinho de compra com o fornecedor
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@param cFor, character, ID do fornecedor
@param cLoj, character, Loja do fornecedor
@since 7/30/2019
/*/
Static Function fCarCom( cFor, cLoj )
	
	Local oCboFrt
	Local oContat 
	Local oGetCon
	Local oGetDes
	Local oGetEmi
	Local oGetFor
	Local oGetLoj
	Local oGetMai
	Local oLbCont
	Local oLblEmi
	Local oLblFor 
	Local nX        := 0
	Local aHeaderEx := {}
	Local aFields   := {"C7_PRODUTO","C7_DESCRI","C7_UM","QUANT","PRECO","TOTAL","DINICOM","DATPRF","C7_LOCAL","OBS","C7_CC","C7_IPI","C7_FORNECE", "C7_LOJA"}
	Local cTitulo   := ""
	Local lOk       := .F.
	local aCarrinho := {} as array
	local oGetFre   as object
	local oPerFre   as object
	local oTransp   as object
	local oDescTran as object
	local cDescTran := Space( TAMSX3( 'A4_NOME' )[1] )
	local lUsaFrete := X3Uso( GetSX3Cache( 'C7_VALFRE', 'X3_USADO' ) )
	local nCol      := 0 as numeric
	local nLin      := 0 as numeric
	local aSize     := MsAdvSize()
	local nHor      := (aSize[5]/2)*0.8
	local nVer      := (aSize[6]/2)*0.8
	local lUsaTrans := SC7->( FieldPos( 'C7_X_TRANS' ) ) > 0 .and. X3Uso( GetSX3Cache( 'C7_X_TRANS', 'X3_USADO' ) )
	local bValid    := {|| .T. }
	local aButtons  := {} as array
	local bOk       := {|| Processa( { || lOk := fGrvPed(), iif( lOk, oDlgCar:End(), Nil ) }, 'Aguarde!','Incluindo pedido de compra...' ) }
	local bCancel   := {|| oDlgCar:End() }
	local bInit     := {|| EnchoiceBar( oDlgCar, bOk, bCancel,, aButtons ), fChgCar() }
	
	Private oTotal  as object
	Private cTransp := Space( iif( SC7->( FieldPos( 'C7_X_TRANS' ) ) > 0, TAMSX3( 'C7_X_TRANS' )[1], 6 ) )
	Private nTotPed := 0 as numeric
	Private aAlter  := {"QUANT","PRECO","TOTAL","DINICOM","DATPRF","C7_IPI"}
	Private dGetEmi := Date()
	Private cGetLoj := cLoj
	Private cGetFor := cFor
	Private cContat := Space( TAMSX3( 'C7_CONTATO' )[01] )
	Private cGetMai := Space( TAMSX3( 'A2_EMAIL'   )[01] )
	Private cGetCon := Space( TAMSX3( 'C7_COND'    )[01] )
	Private cGetDes := Space( TAMSX3( 'E4_DESCRI'  )[01] )
	Private oBrwCar := Nil
	Private oLblMai := Nil
	Private oLblNum	:= Nil
	Private oLblCnd := Nil
	Private oDlgCar := Nil
	Private nPosTot := nPosCod := nPosQua := nPosQua := nPosPrc := nPosFre := nPosIPI := nPosDes := 0 
	Private nPerFre := 0 as numeric
	Private cCboFrt := 'C'
	Private nGetFre := 0 as numeric
	
	// Seta um hot key no Ctrl + R
	SetKey( K_CTRL_R, {|| fReplica() } )

	if lUsaFrete
		aAdd( aFields, "C7_VALFRE" )
	endif

	// Define as propriedades dos campos da planilha de produtos do carrinho
	For nX := 1 to Len(aFields)

		if aFields[nX] == "QUANT"
			aAdd( aHeaderEx, {"Qtde","QUANT","@E 999,999.99",11,2,/*SX3->X3_VALID*/,,"N",,"V",,} )
		elseif aFields[nX] == "PRECO"
			aAdd( aHeaderEx, {"Prç.Un","PRECO","@E 999,999.99",11,2,/*SX3->X3_VALID*/,,"N",,"V",,} )
		elseif aFields[nX] == 'TOTAL'
			aAdd( aHeaderEx, {"Total","TOTAL","@E 9,999,999.99",13,2,/*SX3->X3_VALID*/,,"N",,"V",,} )
		elseif aFields[nX] == 'DINICOM'
			aAdd( aHeaderEx, {"In.Compra","DINICOM","@D",08,0,/*SX3->X3_VALID*/,,"D",,"V",,} )
		elseif aFields[nX] == 'DATPRF'
			aAdd( aHeaderEx, {"Entrega","DATPRF","@D",08,0,/*SX3->X3_VALID*/,,"D",,"V",,} )
		ElseIf aFields[nX] == "OBS"
			aAdd( aHeaderEx, {"Observações","OBS","@!",TAMSX3("C7_OBS")[01],0,/*SX3->X3_VALID*/,,"C",,"V",,} )
		else
			aAdd( aHeaderEx, { AllTrim( GetSX3Cache( aFields[nX], 'X3_TITULO' ) ),;
							   GetSX3Cache( aFields[nX], 'X3_CAMPO' ),;
							   GetSX3Cache( aFields[nX], 'X3_PICTURE' ),;
							   GetSX3Cache( aFields[nX], 'X3_TAMANHO' ),;
							   GetSX3Cache( aFields[nX], 'X3_DECIMAL' ),;
							   /* GetSX3Cache( aFields[nX], 'X3_VALID' ) */,;
							   GetSX3Cache( aFields[nX], 'X3_USADO' ),;
							   GetSX3Cache( aFields[nX], 'X3_TIPO' ),;
							   GetSX3Cache( aFields[nX], 'X3_F3' ),;
							   GetSX3Cache( aFields[nX], 'X3_CONTEXT' ),;
							   GetSX3Cache( aFields[nX], 'X3_CBOX' ),;
							   GetSX3Cache( aFields[nX], 'X3_RELACAO' ) } )
		Endif
	Next nX
	
	nPosCod := aScan( aHeaderEx, {|x| AllTrim( x[02] ) == "C7_PRODUTO"  } )
	nPosQua := aScan( aHeaderEx, {|x| AllTrim( x[02] ) == "QUANT"  } )
	nPosPrc := aScan( aHeaderEx, {|x| AllTrim( x[02] ) == "PRECO"  } )
	nPosTot := aScan( aHeaderEx, {|x| AllTrim( x[02] ) == "TOTAL"    } )
	nPosFre := aScan( aHeaderEx, {|x| AllTrim( x[02] ) == "C7_VALFRE"    } )
	nPosIPI := aScan( aHeaderEx, {|x| AllTrim( x[02] ) == "C7_IPI"    } )
	nPosDes := aScan( aHeaderEx, {|x| AllTrim( x[02] ) == "C7_DESCRI" } )

	
	cGetCon := RetField( 'SA2', 1, xFilial( 'SA2' ) + cGetFor + cGetLoj, 'A2_COND' )
	cGetDes := RetField( 'SE4', 1, xFilial( 'SE4' ) + cGetCon, 'E4_DESCRI' )
	cGetMai := RetField( 'SA2', 1, xFilial( 'SA2' ) + cGetFor + cGetLoj, 'A2_EMAIL' )
	cContat := RetField( 'SA2', 1, xFilial( 'SA2' ) + cGetFor + cGetLoj, 'A2_CONTATO' )
	cTitulo := "CARRINHO DE COMPRAS" + iif( !Empty( cGetFor ), " - " + AllTrim( RetField( 'SA2', 1, xFilial( 'SA2' ) + cGetFor + cGetLoj, 'A2_NOME' ) ), '' )    
	
	// Verifica os itens do carrinho que pertencem ao fornecedor em questão
	aCarrinho := {} 
	aEval( aCarCom, {|x| iif( x[13]+x[14] == cGetFor + cGetLoj,;
						 aAdd( aCarrinho, aClone( x ) ),;
						 Nil ) } )
	
	// Ordena os produtos do carrinho por nome do produto
	aSort( aCarrinho,,,{|x,y| x[2] < y[2] } )	

	// Dialog do carrinho de compras
	oDlgCar := TDialog():New( 0, 0, aSize[6]*0.8, aSize[5]*0.8,cTitulo,,,,,CLR_BLACK,CLR_WHITE,,,.T.)
    
	nCol := 6
	nLin := 36
    @ nLin, nCol SAY oLblEmi PROMPT "Dt. Emissão:"           SIZE 041, 007 OF oDlgCar COLORS 0, 16777215 PIXEL
	nCol += 60
    @ nLin, nCol SAY oLblCnd PROMPT "Condição de Pagamento:" SIZE 074, 007 OF oDlgCar COLORS 0, 16777215 PIXEL
	nCol += 115
    @ nLin, nCol SAY oLblFor PROMPT "Fornecedor:"            SIZE 044, 007 OF oDlgCar COLORS 0, 16777215 PIXEL
	nCol += 90
    @ nLin, nCol SAY oLblMai PROMPT "E-mail Forn."           SIZE 050, 007 OF oDlgCar COLORS 0, 16777215 PIXEL
	nCol += 110
    @ nLin, nCol SAY oLbCont PROMPT "Contato:"               SIZE 025, 007 OF oDlgCar COLORS 0, 16777215 PIXEL

	nCol := 6
	nLin := 44
    @ nLin, nCol MSGET oGetEmi VAR dGetEmi SIZE 055, 011 OF oDlgCar COLORS 0, 16777215 WHEN .T. PIXEL
	nCol += 60
    @ nLin, nCol MSGET oGetCon VAR cGetCon SIZE 028, 011 OF oDlgCar COLORS 0, 16777215 VALID fValCon() WHEN .T. F3 "SE4" PIXEL
	nCol += 30
    @ nLin, nCol MSGET oGetDes VAR cGetDes SIZE 079, 011 OF oDlgCar COLORS 0, 16777215 WHEN .F. PIXEL
	nCol += 85
    @ nLin, nCol MSGET oGetFor VAR cGetFor SIZE 053, 011 OF oDlgCar COLORS 0, 16777215 VALID fValFor() WHEN .T. F3 "SA2" PIXEL
	nCol += 55
    @ nLin, nCol MSGET oGetLoj VAR cGetLoj SIZE 029, 011 OF oDlgCar COLORS 0, 16777215 WHEN .F. PIXEL
	nCol += 35
    @ nLin, nCol MSGET oGetMai VAR cGetMai SIZE 104, 011 OF oDlgCar COLORS 0, 16777215 VALID fMailFor() WHEN .T. PIXEL
	nCol += 110
    @ nLin, nCol MSGET oContat VAR cContat SIZE 060, 011 OF oDlgCar COLORS 0, 16777215 VALID fContFor() WHEN .T. PIXEL

	nLin := 58
	oBrwCar := MsNewGetDados():New( nLin, 004, nVer-40, nHor-04, GD_DELETE+GD_UPDATE, "AllwaysTrue", "AllwaysTrue", "", aAlter,, Len( aCarrinho ), "U_FMANCAR", "", "AllwaysTrue", oDlgCar, aHeaderEx, aCarrinho )
    oBrwCar:oBrowse:bChange := {|| fChgCar() }
    oBrwCar:oBrowse:bDelOk := {|| fBrwDel() }

	nCol := 6
	nLin := nVer - 30
	oCboFrt := TComboBox():New( nLin, nCol,{|u|if(PCount()>0,cCboFrt:=u,cCboFrt)}, {"C=CIF","F=FOB","S=Sem Frete"},50,14,oDlgCar,,{|| cCboFrt := SubStr( cCboFrt,1,1 ),;
																																	  nGetFre := iif( cCboFrt == 'F', nGetFre, 0 ),;
																																	  nPerFre := iif( cCboFrt == 'F', nPerFre, 0 ),;
																																	  cTransp := iif( cCboFrt == 'F', cTransp, Space( TAMSX3( 'C7_X_TRANS' )[1] ) ),;
																																	  fChgCar() },,,,.T.,,,,,,,,,'cCboFrt', 'Tp.Frete', 1)

	nCol += 60
	if lUsaFrete		// Verifica se o campo do valor do frete está em uso no ambiente do cliente
		oGetFre := TGet():New( nLin, nCol,{|u|if(PCount()==0,nGetFre,nGetFre:=u)},oDlgCar,60,011,PesqPict( 'SC7', 'C7_VALFRE' ),,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'nGetFre',,,,.T.,.F.,,'Valor Frete',1 )
		oGetFre:bChange := {|| fChgCar() }
		oGetFre:bWhen := {|| SubStr(cCboFrt,1,1) $ 'C|F' }
		nCol += 70

		oPerFre := TGet():New( nLin, nCol,{|u|if(PCount()==0,nPerFre,nPerFre:=u)},oDlgCar,30,011,"@E 999.99",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'nPerFre',,,,.T.,.F.,,'% Frete',1 )
		oPerFre:bChange := {|| fChgCar() }
		oPerFre:bWhen := {|| SubStr(cCboFrt,1,1) $ 'C|F' }
		nCol += 40
	endif 

	if lUsaTrans
		oTransp := TGet():New( nLin, nCol, {|u| if( PCount()==0,cTransp,cTransp:=u ) }, oDlgCar, 040, 011, PesqPict( 'SC7', 'C7_X_TRANS' ),,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'cTransp',,,,.T.,.F.,,'Transp.',1 )
		oTransp:cF3 := "SA4"
		oTransp:bChange := {|| cDescTran := RetField( 'SA4', 1, FWxFilial( 'SA4' ) + cTransp, 'A4_NREDUZ' ) }
		oTransp:bValid := {|| Empty( cTransp ) .or. ExistCpo( 'SA4', cTransp ) }
		nCol += 50

		oDescTran := TGet():New( nLin, nCol, {|u| if( PCount()==0,cDescTran,cDescTran:=u ) }, oDlgCar, 080, 011, PesqPict( 'SA4', 'A4_NOME' ),,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'cDescTran',,,,.T.,.F.,,'Nome Transp.',1 )
		oDescTran:bWhen := {|| .F. }
		nCol += 90

	endif

	oTotal := TGet():New( nLin, nCol, {|u| if( PCount()==0,nTotPed,nTotPed:=u ) }, oDlgCar, 080, 011, "@E 9,999,999.99",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'nTotPed',,,,.T.,.F.,,'Total do Pedido',1 )
	oTotal:bWhen := {|| .F. }
                                                                                                    
	oDlgCar:Activate(,,,.T., bValid,,bInit)
	
	if lOk
		
		// Se realizou inclusão do pedido de compra, manda atualizar todo o grid do painel		
		RecLock( 'FORTMP', .F. )
		FORTMP->PEDIDO := 'N'
		FORTMP->( MsUnlock() )
		
		// Remove todos os itens do carrinho
		for nX := 1 to len( aCarrinho )
			aDel( aCarCom, aScan( aCarCom, {|x| x[1] == aCarrinho[nX][1] .and.;
												x[13] == aCarrinho[nX][13] .and.;
												x[14] == aCarrinho[nX][14] } ) ) 
			aSize( aCarCom, Len( aCarCom )-1 )
		next nX
		aCarrinho := {}

		oBrwFor:LineRefresh()

		Processa( {|| fLoadInf() }, 'Aguarde!','Buscando informações dos produtos...' )
	EndIf
	
	SetKey( K_CTRL_R, {|| Nil } )
	
Return ( Nil )

/*
+-----------------+-------------------------+---------------------------------+-------------------+
| Fonte: GMPAICOM | Funcao:  fReplica       | Autor: Jean Carlos P. Saggin    |  Data: 02.08.2019 |
+-----------------+-------------------------+---------------------------------+-------------------+
| Descricao: Função para replicar dados do grid referente ao carrinho de compras                  |
+-------------------------------------------------------------------------------------------------+
| Parametros recebidos: Nil                                                                       |
+-------------------------------------------------------------------------------------------------+
| Retorno da funcao: Nil                                                                          |
+-------------------------------------------------------------------------------------------------+  
*/
Static Function fReplica()
	
	bInfo := Nil
	
	if oBrwCar != Nil .and. Len( oBrwCar:aCols ) > 0
		
		if aScan( aAlter, {|x| AllTrim( x ) == AllTrim( oBrwCar:aHeader[oBrwCar:oBrowse:ColPos()][02] ) } ) > 0
			if MsgYesNo( 'Tem certeza que deseja resplicar o conteúdo do campo <b>'+ oBrwCar:aHeader[oBrwCar:oBrowse:ColPos()][01] +'</b>?','Está certo disso?' )
				bInfo := oBrwCar:aCols[ oBrwCar:nAt ][ oBrwCar:oBrowse:ColPos() ]
				aEval( oBrwCar:aCols, {|x| x[ oBrwCar:oBrowse:ColPos() ] := bInfo } )
				oBrwCar:ForceRefresh()
			EndIf
		Else
			MsgStop( 'Você está tentando replicar o conteúdo do campo <b>'+ oBrwCar:aHeader[oBrwCar:oBrowse:ColPos()][01] +'</b> e ele não permite receber alterações!','Operação não permitida!' )
		EndIf
	EndIf
	
Return ( Nil )

/*/{Protheus.doc} fGrvPed
Função para gravação dos dados do pedido de compras de acordo com os dados do grid
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 7/31/2019
@return logical, lAllOk - indica se conseguiu realizar a inclusão do pedido de compra
/*/
Static Function fGrvPed()
	
	Local aCol := oBrwCar:aCols
	Local aHea := oBrwCar:aHeader
	Local aCab := {}
	Local aIte := {}
	Local aLin := {}
	Local cNum := ""
	Local nX   := 0
	Local nPrd := aScan( aHea, {|x| AllTrim( x[02] ) == 'C7_PRODUTO'} )
	Local nQtd := aScan( aHea, {|x| AllTrim( x[02] ) == 'QUANT'  } )
	Local nPrc := aScan( aHea, {|x| AllTrim( x[02] ) == 'PRECO'  } )
	Local nTot := aScan( aHea, {|x| AllTrim( x[02] ) == 'TOTAL'  } )
	Local nDes := aScan( aHea, {|x| AllTrim( x[02] ) == 'C7_DESCRI' } )
	Local nUnM := aScan( aHea, {|x| AllTrim( x[02] ) == 'C7_UM'     } )
	Local nIni := aScan( aHea, {|x| AllTrim( x[02] ) == 'DINICOM'   } )
	Local nEnt := aScan( aHea, {|x| AllTrim( x[02] ) == 'DATPRF'    } )
	Local nLoc := aScan( aHea, {|x| AllTrim( x[02] ) == 'C7_LOCAL'  } )
	Local nObs := aScan( aHea, {|x| AllTrim( x[02] ) == 'OBS'       } )
	local nVFr := aScan( aHea, {|x| AllTrim( x[02] ) == 'C7_VALFRE' } )
	
	Private lMsErroAuto := .F.
	
	// Valida preenchimento dos dados do carrinho antes de prosseguir
	if ! fValPed()
		hlp( 'A T E N Ç Ã O ',;
			'Existem informações inconsistentes e/ou que não foram preenchidas corretamente.',;
			'Revise os dados do carrinho de compras e tente novamente.' )
		Return .F.
	endif

	// Verifica a próxima numeração para o campo
	cNum := NextNumero("SC7",1,"C7_NUM",.T., Nil)
	
	aCab := {}
	aAdd( aCab, { "C7_FILIAL"  , xFilial( 'SC7' ) } )
	aAdd( aCab, { "C7_NUM"     , cNum } )
	aAdd( aCab, { "C7_EMISSAO" , dGetEmi } )
	aAdd( aCab, { "C7_FORNECE" , cGetFor } )
	aAdd( aCab, { "C7_LOJA"    , cGetLoj } )
	aAdd( aCab, { "C7_COND"    , cGetCon } )
	aAdd( aCab, { "C7_CONTATO" , cContat } )
	aAdd( aCab, { "C7_FILENT"  , iif( cFilAnt != Nil, cFilAnt, xFilial( 'SC7' ) ) } )
	
	aIte := {}
	For nX := 1 to Len( aCol )
		
		if !aCol[nX][Len(aHea)+1]
			
			
			aAdd( aLin, { "C7_PRODUTO", aCol[nX][nPrd], Nil } )
			aAdd( aLin, { "C7_DESCRI" , aCol[nX][nDes], Nil } )
			aAdd( aLin, { "C7_UM"     , aCol[nX][nUnM], Nil } )
			aAdd( aLin, { "C7_QUANT"  , aCol[nX][nQtd], Nil } )
			aAdd( aLin, { "C7_PRECO"  , aCol[nX][nPrc], Nil } )
			aAdd( aLin, { "C7_TOTAL"  , aCol[nX][nTot], Nil } )
			aAdd( aLin, { "C7_DINICOM", aCol[nX][nIni], Nil } )
			aAdd( aLin, { "C7_DATPRF" , aCol[nX][nEnt], Nil } )
			aAdd( aLin, { "C7_LOCAL"  , aCol[nX][nLoc], Nil } )
			aAdd( aLin, { "C7_OBS"    , aCol[nX][nObs], Nil } )
			aAdd( aLin, { "C7_TPFRETE", cCboFrt       , Nil } )
			if nVFr > 0			// Verifica se o campo do valor do frete está em uso no ambiente do cliente
				aAdd( aLin, { "C7_VALFRE", aCol[nX][nVFr], Nil } )
			endif

			// Se a transportadora estiver em uso no pedido, passa o parâmetro no vetor de inclusão do pedido
			if SC7->( FieldPos( 'C7_X_TRANS' ) ) > 0 .and. X3Uso( GetSX3Cache( 'C7_X_TRANS', 'X3_USADO' ) )
				aAdd( aLin, { "C7_X_TRANS", cTransp, Nil } )
			endif
			
			aAdd( aIte, aClone( aLin ) )
			aLin := {}
			
		EndIf
		
	Next nX
	
	lMsErroAuto := .F.
	MATA120( 1, aCab, aIte, 3 )
	
	if lMsErroAuto
		MostraErro()
	Else 
		if MsgYesNo( 'Pedido de compra número <b>'+ SC7->C7_NUM +'</b> gerado com sucesso! Deseja realizar a impressão do pedido?','S U C E S S O ! Pedido Nro. '+ SC7->C7_NUM +'' )
			GMPCPrint( SC7->C7_NUM )
		endif

		if AllTrim(SuperGetMv( "MV_ENVPED",, '0')) $ '1|2' .and.; 
		MsgYesNo( 'Gostaria de realizar o envio do pedido de compra diretamente para o e-mail do fornecedor?', 'Enviar Pedido por e-Mail?' )
			Processa({|| sndMail( SC7->C7_NUM ), 'Preparando envio de e-mail para o fornecedor...', 'Aguarde' }) 
		endif
	EndIf
	
Return ( !lMsErroAuto )

/*/{Protheus.doc} GMPCPRINT
Função para geração automática do pedido de compra diretamente pela tela do painel
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 6/6/2022
@param cPC, character, Número do pedido de compra
/*/
Static Function GMPCPRINT( cPC )
	
	local aArea    := getArea()
	Local oRep     := Nil
	Private lAuto  := .T.
	
	default cPC := ""

	if Empty( cPC )
		restArea( aArea )
		MsgStop( 'Número do pedido de compra <b>'+ cPC +'</b> não foi recebido corretamente na função de impressão!','F A L H A' )
		return Nil
	else
		// Tenta posicionar no pedido recebido por parâmetro na tabela SC7, se não conseguir, cai fora da função
		DBSelectArea( 'SC7' )
		SC7->( DBSetOrder( 1 ) )		// C7_FILIAL + C7_NUM + C7_ITEM
		if ! SC7->( DBSeek( FWxFilial( "SC7" ) + cPC ) )
			restArea( aArea )
			MsgStop( 'Número do pedido de compra <b>'+ cPC +'</b> não foi recebido corretamente na função de impressão!','F A L H A' )
			return Nil
		endif
	endif
 
	oRep := reportDef( SC7->( Recno() ), 1 )
	if oRep != Nil 
		oRep:PrintDialog()
	EndIf
	
	restArea( aArea )
Return ( Nil )

/*/{Protheus.doc} ReportPrint
Função de impressão do relatório de pedido de compra baseado no fonte padrão MATR110
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 6/6/2022
@param oReport, object, objeto modelo do relatório montado por meio do reportdef
@param nReg, numeric, Recno de um dos registros do pedido da tabela SC7
@param nOpcX, numeric, 1=PC ou 2=Autorização de Entrega
/*/
Static Function ReportPrint(oReport,nReg,nOpcX)

Local oSection1   := oReport:Section(1)
Local oSection2   := oReport:Section(1):Section(1)

Local aRecnoSave  := {}
Local aPedido     := {}
Local aPedMail    := {}
Local aValIVA     := {}

Local cNumSC7		:= Len(SC7->C7_NUM)
Local cCondicao		:= ""
Local cFiltro		:= ""
Local cComprador	:= ""
LOcal cAlter		:= ""
Local cAprov		:= ""
Local cTipoSC7		:= ""
Local cCondBus		:= ""
Local cMensagem		:= ""
Local cVar			:= ""
Local cPictVUnit	:= PesqPict("SC7","C7_PRECO",15)
Local cPictVTot		:= PesqPict("SC7","C7_TOTAL",, mv_par12)
Local lNewAlc		:= .F.
Local lLiber		:= .F.
Local lRejeit		:= .F.

Local nRecnoSC7   	:= 0
Local nRecnoSM0   	:= 0
Local nX          	:= 0
Local nY          	:= 0
Local nVias       	:= 0
Local nTxMoeda    	:= 0
Local nPageWidth  	:= oReport:PageWidth()
Local nPrinted    	:= 0
Local nValIVA     	:= 0
Local nTotIpi	    := 0
Local nTotIcms    	:= 0
Local nTotDesp    	:= 0
Local nTotFrete   	:= 0
Local nTotalNF    	:= 0
Local nTotSeguro  	:= 0
Local nLinPC	    := 0
Local nLinObs     	:= 0
Local nDescProd   	:= 0
Local nTotal      	:= 0
Local nTotMerc    	:= 0
Local nPagina     	:= 0
Local nOrder      	:= 1
Local lImpri      	:= .F.
Local cCident	  	:= ""
Local cCidcob	  	:= ""
Local nLinPC2	  	:= 0
Local nLinPC3	  	:= 0
Local nAprovLin 	:= 0
Local aAux1
Local nQtdLinhas //, nX
Local lC7OBSChar  	:= Type( "SC7->C7_OBS" ) == "C"
Local nFrete		:= 0
Local nSeguro       := 0
Local nDesp			:= 0
Local nPAJ_MSBLQL	:= SAJ->(FieldPos("AJ_MSBLQL"))

Private cDescPro  	:= ""
Private cOPCC     	:= ""
Private nVlUnitSC7	:= 0
Private nValTotSC7	:= 0

Private cObs01    	 := ""
Private cObs02    	  := ""
Private cObs03    	  := ""
Private cObs04    	  := ""
Private cObs05    	  := ""
Private cObs06    	  := ""
Private cObs07    	  := ""
Private cObs08    	  := ""
Private cObs09    	  := ""
Private cObs10    	  := ""
Private cObs11    	  := ""
Private cObs12    	  := ""
Private cObs13    	  := ""
Private cObs14    	  := ""
Private cObs15    	  := ""
Private cObs16    	  := ""

Private nRet		  := 0
Private cMoeda		  := ""
Private cPicMoeda	  := ""
Private cPicC7_VLDESC := "" 
Private cInscrEst	  := InscrEst()
Private cRegra        := SuperGetMV("MV_ARRPEDC",.F.,"")
Private nTamTot       := TamSX3("C7_PRECO")[2]

// Variáveis para adaptação do processo customizado
Private lPedido       := isInCallStack( "U_GMPAICOM" )

If Type("lPedido") != "L"
	lPedido := .F.
Endif

If Type("lAuto") == "U"
	lAuto := (nReg!=Nil)
Endif

If Type("cFilSA2") == "U"
	cFilSA2		:= xFilial("SA2")
Endif

If Type("cFilSA5") == "U"
	cFilSA5		:= xFilial("SA5")
Endif

If Type("cFilSAJ") == "U"
	cFilSAJ		:= xFilial("SAJ")
Endif

If Type("cFilSB1") == "U"
	cFilSB1		:= xFilial("SB1")
Endif

If Type("cFilSB5") == "U"
	cFilSB5		:= xFilial("SB5")
Endif

If Type("cFilSC7") == "U"
	cFilSC7		:= xFilial("SC7")
Endif

If Type("cFilSCR") == "U"
	cFilSCR		:= xFilial("SCR")
Endif

If Type("cFilSE4") == "U"
	cFilSE4		:= xFilial("SE4")
Endif

If Type("cFilSM4") == "U"
	cFilSM4		:= xFilial("SM4")
Endif

dbSelectArea("SAJ")
SAJ->(dbSetOrder(1))

dbSelectArea("SCR")
SCR->(dbSetOrder(1))

dbSelectArea("SC7")

SB1->(dbSetOrder(1))
SB5->(dbSetOrder(1))
SA5->(dbSetOrder(1))
SM0->(dbSetOrder(1))
SE4->(dbSetOrder(1))
SM4->(dbSetOrder(1))

If lAuto	
	SC7->(dbGoto(nReg))
	mv_par01 := SC7->C7_NUM
	mv_par02 := SC7->C7_NUM
	mv_par03 := SC7->C7_EMISSAO
	mv_par04 := SC7->C7_EMISSAO
	R110ChkPerg()
	cCondBus := AllTrim(Str(SC7->C7_TIPO) + SC7->C7_NUM)
Else
	MakeAdvplExpr(oReport:uParam)

	cCondicao := 'C7_FILIAL=="'       + cFilSC7 + '".And.'
	cCondicao += 'C7_NUM>="'          + mv_par01       + '".And.C7_NUM<="'          + mv_par02 + '".And.'
	cCondicao += 'Dtos(C7_EMISSAO)>="'+ Dtos(mv_par03) +'".And.Dtos(C7_EMISSAO)<="' + Dtos(mv_par04) + '"'
	
	oReport:Section(1):SetFilter(cCondicao,IndexKey())
	
	cCondBus := "1"+PadL(mv_par01, Len(SC7->C7_NUM),"0")
EndIf      

If lPedido
	mv_par12 := MAX(SC7->C7_MOEDA,1)
EndIf

cMoeda		:= IIf( mv_par12 < 10 , Str(mv_par12,1) , Str(mv_par12,2) )
If Val(cMoeda) == 0
	cMoeda := "1"
Endif
cPicMoeda	:= GetMV("MV_MOEDA"+cMoeda)
cPicC7_VLDESC:= PesqPict("SC7","C7_VLDESC",14, MV_PAR12)

nOrder	 := 10

If mv_par14 == 2
	cFiltro := "SC7->C7_QUANT-SC7->C7_QUJE <= 0 .Or. !EMPTY(SC7->C7_RESIDUO)"
Elseif mv_par14 == 3
	cFiltro := "SC7->C7_QUANT > SC7->C7_QUJE"
EndIf

oSection2:Cell("PRECO"):SetPicture(cPictVUnit)
oSection2:Cell("TOTAL"):SetPicture(cPictVTot)

TRPosition():New(oSection2,"SB1",1,{ || cFilSB1 + SC7->C7_PRODUTO })
TRPosition():New(oSection2,"SB5",1,{ || cFilSB5 + SC7->C7_PRODUTO })

// Executa o CodeBlock com o PrintLine da Sessao 1 toda vez que rodar o oSection1:Init()
oReport:onPageBreak( { || nPagina++ , nPrinted := 0 , CabecPCxAE(oReport,oSection1,nVias,nPagina) })

oReport:SetMeter(SC7->(LastRec()))
SC7->(dbSetOrder(nOrder))
SC7->(dbSeek(cFilSC7+cCondBus,.T.))

oSection2:Init()

cNumSC7 := SC7->C7_NUM

While !oReport:Cancel() .And. !SC7->(Eof()) .And. SC7->C7_FILIAL == cFilSC7 .And. SC7->C7_NUM >= mv_par01 .And. SC7->C7_NUM <= mv_par02
	
	If (SC7->C7_CONAPRO <> "B" .And. mv_par10 == 2) .Or.;
		(SC7->C7_CONAPRO <> "L" .And. mv_par10 == 1) .Or.;
		(SC7->C7_EMITIDO == "S" .And. mv_par05 == 1) .Or.;
		((SC7->C7_EMISSAO < mv_par03) .Or. (SC7->C7_EMISSAO > mv_par04)) .Or.;
		((SC7->C7_TIPO == 1 .OR. SC7->C7_TIPO == 3) .And. mv_par08 == 2) .Or.;
		(SC7->C7_TIPO == 2 .And. (mv_par08 == 1 .OR. mv_par08 == 3)) .Or. !MtrAValOP(mv_par11, "SC7") .Or.;
		(SC7->C7_QUANT > SC7->C7_QUJE .And. mv_par14 == 3) .Or.;
		((SC7->C7_QUANT - SC7->C7_QUJE <= 0 .Or. !Empty(SC7->C7_RESIDUO)) .And. mv_par14 == 2 )
		
		SC7->(dbSkip())
		Loop
	Endif
	
	If oReport:Cancel()
		Exit
	EndIf
	
	MaFisEnd()
	R110FIniPC(SC7->C7_NUM,,,cFiltro)
	
	cObs01    := " "
	cObs02    := " "
	cObs03    := " "
	cObs04    := " "
	cObs05    := " "
	cObs06    := " "
	cObs07    := " "
	cObs08    := " "
	cObs09    := " "
	cObs10    := " "
	cObs11    := " "
	cObs12    := " "
	cObs13    := " "
	cObs14    := " "
	cObs15    := " "
	cObs16    := " "
	
	// Roda a impressao conforme o numero de vias informado no mv_par09 
	For nVias := 1 to mv_par09
		
		// Dispara a cabec especifica do relatorio.                     
		oReport:EndPage()
		oReport:Box( 260, 010, 3020 , nPageWidth-4 ) //-- Box dos itens do relatório
		
		nPagina  := 0
		nPrinted := 0
		nTotal   := 0
		nTotMerc := 0
		nDescProd:= 0
		nLinObs  := 0
		nRecnoSC7:= SC7->(Recno())
		cNumSC7  := SC7->C7_NUM
		aPedido  := {SC7->C7_FILIAL,SC7->C7_NUM,SC7->C7_EMISSAO,SC7->C7_FORNECE,SC7->C7_LOJA,SC7->C7_TIPO}
		
		While !oReport:Cancel() .And. !SC7->(Eof()) .And. SC7->C7_FILIAL == cFilSC7 .And. SC7->C7_NUM == cNumSC7
			
			If (SC7->C7_CONAPRO <> "B" .And. mv_par10 == 2) .Or.;
				(SC7->C7_CONAPRO <> "L" .And. mv_par10 == 1) .Or.;
				(SC7->C7_EMITIDO == "S" .And. mv_par05 == 1) .Or.;
				((SC7->C7_EMISSAO < mv_par03) .Or. (SC7->C7_EMISSAO > mv_par04)) .Or.;
				((SC7->C7_TIPO == 1 .OR. SC7->C7_TIPO == 3) .And. mv_par08 == 2) .Or.;
				(SC7->C7_TIPO == 2 .And. (mv_par08 == 1 .OR. mv_par08 == 3)) .Or. !MtrAValOP(mv_par11, "SC7") .Or.;
				(SC7->C7_QUANT > SC7->C7_QUJE .And. mv_par14 == 3) .Or.;
				((SC7->C7_QUANT - SC7->C7_QUJE <= 0 .Or. !Empty(SC7->C7_RESIDUO)) .And. mv_par14 == 2 )
				
				SC7->(dbSkip())
				Loop
			Endif
			
			If oReport:Cancel()
				Exit
			EndIf
			
			oReport:IncMeter()
			
			If oReport:Row() > oReport:LineHeight() * 100
				oReport:Box( oReport:Row(),010,oReport:Row() + oReport:LineHeight() * 3, nPageWidth-4 )
				oReport:SkipLine()
				oReport:PrintText(STR0101,, 050 ) // Continua na Proxima pagina ....
				oReport:EndPage()
			EndIf
			
			// Salva os Recnos do SC7 no aRecnoSave para marcar reimpressao.
			If Ascan(aRecnoSave,SC7->(Recno())) == 0
				AADD(aRecnoSave,SC7->(Recno()))
			Endif
			
			// Inicializa o descricao do Produto conf. parametro digitado.
			cDescPro :=  ""
			If Empty(mv_par06)
				mv_par06 := "B1_DESC"
			EndIf
			
			If AllTrim(mv_par06) == "B1_DESC"
				SB1->(dbSeek( cFilSB1 + SC7->C7_PRODUTO ))
				cDescPro := SB1->B1_DESC
			ElseIf AllTrim(mv_par06) == "B5_CEME"
				If SB5->(dbSeek( cFilSB5 + SC7->C7_PRODUTO ))
					cDescPro := SB5->B5_CEME
				EndIf
			ElseIf AllTrim(mv_par06) == "C7_DESCRI"
				cDescPro := SC7->C7_DESCRI
			EndIf
			
			If Empty(cDescPro)
				SB1->(dbSeek( cFilSB1 + SC7->C7_PRODUTO ))
				cDescPro := SB1->B1_DESC
			EndIf
			
			If SA5->(dbSeek(cFilSA5+SC7->C7_FORNECE+SC7->C7_LOJA+SC7->C7_PRODUTO)) .And. !Empty(SA5->A5_CODPRF)
				cDescPro := Alltrim(cDescPro) + " ("+Alltrim(SA5->A5_CODPRF)+")"
			EndIf
			
			If SC7->C7_DESC1 != 0 .Or. SC7->C7_DESC2 != 0 .Or. SC7->C7_DESC3 != 0
				nDescProd+= CalcDesc(SC7->C7_TOTAL,SC7->C7_DESC1,SC7->C7_DESC2,SC7->C7_DESC3)
			Else
				nDescProd+=SC7->C7_VLDESC
			Endif

			// Inicializacao da Observacao do Pedido.                       
			If lC7OBSChar .AND. !Empty(SC7->C7_OBS) .And. nLinObs < 17
				If !(SC7->C7_OBS $ SC7->C7_OBSM) 
					nLinObs++
					cVar:="cObs"+StrZero(nLinObs,2)
					Eval(MemVarBlock(cVar),Alltrim(SC7->C7_OBS))
				EndIf 
			Endif
			
			If !Empty(SC7->C7_OBSM) .And. nLinObs < 17
				nLinObs++
				cVar:="cObs"+StrZero(nLinObs,2)
				Eval(MemVarBlock(cVar),Alltrim(SC7->C7_OBSM))
			Endif
						
			nTxMoeda   := IIF(SC7->C7_TXMOEDA > 0,SC7->C7_TXMOEDA,Nil)

			If !Empty(cRegra)
					If AllTrim(cRegra) == "NOROUND"
						nValTotSC7            := NoRound( SC7->C7_QUANT * SC7->C7_PRECO, nTamTot )
					ElseIf AllTrim(cRegra) == "ROUND"
						nValTotSC7            := Round( SC7->C7_QUANT * SC7->C7_PRECO, nTamTot )
					EndIf
					If nValTotSC7 > 0
						nTotal 	:= nTotal 	+ nValTotSC7
						IF SC7->C7_MOEDA == 1
							nTotMerc   := MaFisRet(,"NF_TOTAL")
						ELSE
							nFrete		:= nFrete 	+ SC7->C7_VALFRE
							nSeguro		:= nSeguro 	+ SC7->C7_SEGURO
							nDesp		:= nDesp 	+ SC7->C7_DESPESA
							nTotMerc	:= nValTotSC7
						ENDIF
					EndIf
				EndIf
			
				If !Empty(cRegra)
					If AllTrim(cRegra) == "NOROUND"
						nValTotSC7	:= NoRound( xMoeda(nValTotSC7,SC7->C7_MOEDA,Val(cMoeda),SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda),2 )
					ElseIf AllTrim(cRegra) == "ROUND"
						nValTotSC7	:= Round( xMoeda(nValTotSC7,SC7->C7_MOEDA,Val(cMoeda),SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda),2 )
					ENDIF
				ENDIF
			
			If oReport:nDevice != 4 .Or. (oReport:nDevice == 4 .And. !oReport:lXlsTable .And. oReport:lXlsHeader)  //impressao em planilha tipo tabela
				oSection2:Cell("C7_NUM"):Disable()
			EndIf
			
			If MV_PAR07 == 2 .And. !Empty(SC7->C7_QTSEGUM) .And. !Empty(SC7->C7_SEGUM)
				oSection2:Cell("C7_SEGUM"  ):Enable()
				oSection2:Cell("C7_QTSEGUM"):Enable()
				oSection2:Cell("C7_UM"     ):Disable()
				oSection2:Cell("C7_QUANT"  ):Disable()
				nVlUnitSC7 := xMoeda(((SC7->C7_PRECO*SC7->C7_QUANT)/SC7->C7_QTSEGUM),SC7->C7_MOEDA,Val(cMoeda),SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda)
			ElseIf MV_PAR07 == 1 .And. !Empty(SC7->C7_QUANT) .And. !Empty(SC7->C7_UM)
				oSection2:Cell("C7_SEGUM"  ):Disable()
				oSection2:Cell("C7_QTSEGUM"):Disable()
				oSection2:Cell("C7_UM"     ):Enable()
				oSection2:Cell("C7_QUANT"  ):Enable()
				nVlUnitSC7 := xMoeda(SC7->C7_PRECO,SC7->C7_MOEDA,Val(cMoeda),SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda)
			Else
				oSection2:Cell("C7_SEGUM"  ):Enable()
				oSection2:Cell("C7_QTSEGUM"):Enable()
				oSection2:Cell("C7_UM"     ):Enable()
				oSection2:Cell("C7_QUANT"  ):Enable()
				nVlUnitSC7 := xMoeda(SC7->C7_PRECO,SC7->C7_MOEDA,Val(cMoeda),SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda)
			EndIf
			
			If cPaisLoc <> "BRA" .Or. mv_par08 == 2
				oSection2:Cell("C7_IPI" ):Disable()
			EndIf
			 
			If mv_par08 == 1 .OR. mv_par08 == 3
				oSection2:Cell("OPCC"):Disable()
			Else
				oSection2:Cell("C7_CC"):Disable()
				oSection2:Cell("C7_NUMSC"):Disable()
				If !Empty(SC7->C7_OP)
					cOPCC := STR0065 + " " + SC7->C7_OP
				ElseIf !Empty(SC7->C7_CC)
					cOPCC := STR0066 + " " + SC7->C7_CC
				EndIf
			EndIf
			

			If oReport:nDevice == 4 .And. oReport:lXlsTable .And. !oReport:lXlsHeader  //impressao em planilha tipo tabela	
				oSection1:Init()
				TRPosition():New(oSection1,"SA2",1,{ || cFilSA2 + SC7->C7_FORNECE + SC7->C7_LOJA })
				oSection1:PrintLine()
				oSection2:PrintLine()
				oSection1:Finish()
			Else	
				oSection2:PrintLine()
			EndIf
			
			nPrinted++
			lImpri  := .T.
			
			SC7->(dbSkip())
			
		EndDo
		
		SC7->(dbGoto(nRecnoSC7))
		
		If oReport:Row() > oReport:LineHeight() * 68
			
			oReport:Box( oReport:Row(),010,oReport:Row() + oReport:LineHeight() * 3, nPageWidth-4 )
			oReport:SkipLine()
			oReport:PrintText(STR0101,, 050 ) // Continua na Proxima pagina ....
			
			// Dispara a cabec especifica do relatorio.                     
			oReport:EndPage()
			oReport:PrintText(" ",1992 , 010 ) // Necessario para posicionar Row() para a impressao do Rodape
			
			oReport:Box( 280,010,oReport:Row() + oReport:LineHeight() * ( 93 - nPrinted ) , nPageWidth-4 )

		EndIf
		
		oReport:Box( 1990 ,010,oReport:Row() + oReport:LineHeight() * ( 93 - nPrinted ) , nPageWidth-4 )
		oReport:Box( 2080 ,010,oReport:Row() + oReport:LineHeight() * ( 93 - nPrinted ) , nPageWidth-4 )
		oReport:Box( 2200 ,010,oReport:Row() + oReport:LineHeight() * ( 93 - nPrinted ) , nPageWidth-4 )
		oReport:Box( 2320 ,010,oReport:Row() + oReport:LineHeight() * ( 93 - nPrinted ) , nPageWidth-4 )
		
		oReport:Box( 2200 , 1080 , 2320 , 1400 ) // Box da Data de Emissao
		oReport:Box( 2320 ,  010 , 2406 , 1220 ) // Box do Reajuste
		oReport:Box( 2320 , 1220 , 2460 , 1750 ) // Box do IPI e do Frete
		oReport:Box( 2320 , 1750 , 2460 , nPageWidth-4 ) // Box do ICMS Despesas e Seguro
		oReport:Box( 2406 ,  010 , 2700 , 1220 ) // Box das Observacoes

		cMensagem:= Formula(C7_MSG)
		If !Empty(cMensagem)
			oReport:SkipLine()
			oReport:PrintText(PadR(cMensagem,129), , oSection2:Cell("DESCPROD"):ColPos() )
		Endif

		IF SC7->C7_MOEDA == 1
				xMoeda(nDescProd,SC7->C7_MOEDA,MV_PAR12,SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda)
			ELSE
				If !Empty(cRegra)
					If AllTrim(cRegra) == "NOROUND"
						nDescProd := NoRound((xMoeda(nDescProd,SC7->C7_MOEDA,MV_PAR12,SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda)))
					ELSE
						nDescProd := Round((xMoeda(nDescProd,SC7->C7_MOEDA,MV_PAR12,SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda)),2)
					ENDIF
				ENDIF
			ENDIF
		
		oReport:PrintText( STR0007 /*"D E S C O N T O S -->"*/ + " " + ;
		TransForm(SC7->C7_DESC1,"999.99" ) + " %    " + ;
		TransForm(SC7->C7_DESC2,"999.99" ) + " %    " + ;
		TransForm(SC7->C7_DESC3,"999.99" ) + " %    " + ;
		TransForm(nDescProd , cPicC7_VLDESC ),;
		2022 , 050 )
		
		oReport:SkipLine()
		oReport:SkipLine()
		oReport:SkipLine()
		
		// Posiciona o Arquivo de Empresa SM0.                        
		// Imprime endereco de entrega do SM0 somente se o MV_PAR13 =" "
		// e o Local de Cobranca :                                      
		nRecnoSM0 := SM0->(Recno())
		SM0->(dbSeek(SUBS(cNumEmp,1,2)+SC7->C7_FILENT))

		cCident := IIF(len(SM0->M0_CIDENT)>20,Substr(SM0->M0_CIDENT,1,15),SM0->M0_CIDENT)
		cCidcob := IIF(len(SM0->M0_CIDCOB)>20,Substr(SM0->M0_CIDCOB,1,15),SM0->M0_CIDCOB)

		If Empty(MV_PAR13) //"Local de Entrega  : "
			oReport:PrintText(STR0008 + SM0->M0_ENDENT+"  "+Rtrim(SM0->M0_CIDENT)+"  - "+SM0->M0_ESTENT+" - "+STR0009+" "+Trans(Alltrim(SM0->M0_CEPENT),cPicA2_CEP),, 050 )
		Else
			oReport:PrintText(STR0008 + mv_par13,, 050 ) //"Local de Entrega  : " imprime o endereco digitado na pergunte
		Endif
		SM0->(dbGoto(nRecnoSM0))
		oReport:PrintText(STR0010 + SM0->M0_ENDCOB+"  "+Rtrim(SM0->M0_CIDCOB)+"  - "+SM0->M0_ESTCOB+" - "+STR0009+" "+Trans(Alltrim(SM0->M0_CEPCOB),cPicA2_CEP),, 050 )
		
		oReport:SkipLine()
		oReport:SkipLine()
		
		SE4->(dbSeek(cFilSE4+SC7->C7_COND))
		
		nLinPC := oReport:Row()
		oReport:PrintText( STR0011+SubStr(SE4->E4_CODIGO,1,40),nLinPC,050 )
		oReport:PrintText( STR0070,nLinPC,1120 ) //"Data de Emissao"
		oReport:PrintText( STR0013 +" "+ Transform(xMoeda(nTotal,SC7->C7_MOEDA,Val(cMoeda),SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda) , tm(nTotal,14,MsDecimais(Val(cMoeda))) ),nLinPC,1612 ) //"Total das Mercadorias : "
		oReport:SkipLine()
		nLinPC := oReport:Row()
	
		If cPaisLoc<>"BRA"
			aValIVA := MaFisRet(,"NF_VALIMP")
			nValIVA :=0
			If !Empty(aValIVA)
				For nY:=1 to Len(aValIVA)
					nValIVA+=aValIVA[nY]
				Next nY
			EndIf
			oReport:PrintText(SubStr(SE4->E4_DESCRI,1,34),nLinPC, 050 )
			oReport:PrintText( dtoc(SC7->C7_EMISSAO),nLinPC,1120 )
			oReport:PrintText( STR0063+ "   " + ; //"Total dos Impostos:    "
			Transform(xMoeda(nValIVA,SC7->C7_MOEDA,Val(cMoeda),SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda) , tm(nValIVA,14,MsDecimais(Val(cMoeda))) ),nLinPC,1612 )
		Else
			oReport:PrintText( SubStr(SE4->E4_DESCRI,1,34),nLinPC, 050 )
			oReport:PrintText( dtoc(SC7->C7_EMISSAO),nLinPC,1120 )
			oReport:PrintText( STR0064+ "  " + ; //"Total com Impostos:    "
			Transform(xMoeda(nTotMerc,SC7->C7_MOEDA,Val(cMoeda),SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda) , tm(nTotMerc,14,MsDecimais(Val(cMoeda))) ),nLinPC,1612 )
		Endif
		oReport:SkipLine()
		
		IF SC7->C7_MOEDA == 1
			nTotIpi	  	:= MaFisRet(,'NF_VALIPI')
			nTotIcms  	:= MaFisRet(,'NF_VALICM')
			nTotDesp  	:= MaFisRet(,'NF_DESPESA')
			nTotFrete 	:= MaFisRet(,'NF_FRETE')
			nTotSeguro	:= MaFisRet(,'NF_SEGURO')
			nTotalNF  	:= MaFisRet(,'NF_TOTAL')
		Else
			If !Empty(cRegra)
				If AllTrim(cRegra) == "NOROUND"
					nTotFrete 	:= NoRound(xMoeda(nFrete,SC7->C7_MOEDA,Val(cMoeda),SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda))
					nTotSeguro 	:= NoRound(xMoeda(nSeguro,SC7->C7_MOEDA,MV_PAR12,SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda))
					nTotDesp	:= NoRound(xMoeda(nDesp ,SC7->C7_MOEDA,Val(cMoeda),SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda))
				Else
					nTotFrete 	:= Round(xMoeda(nFrete,SC7->C7_MOEDA,Val(cMoeda),SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda),2)
					nTotSeguro 	:= Round(xMoeda(nSeguro,SC7->C7_MOEDA,MV_PAR12,SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda),2)
					nTotDesp	:= Round(xMoeda(nDesp ,SC7->C7_MOEDA,Val(cMoeda),SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda),2)
				EndIf
			EndIf
			nTotalNF	:= ( nTotal + nFrete + nSeguro + nDesp ) - ( nDescProd / nTxMoeda )
			nTotalNF	:= xMoeda(nTotalNF,SC7->C7_MOEDA,MV_PAR12,SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda)
		EndIf
		
		oReport:SkipLine()
		oReport:SkipLine()
		nLinPC := oReport:Row()
		
		If SM4->(dbSeek(cFilSM4+SC7->C7_REAJUST))
			oReport:PrintText(  STR0014 + " " + SC7->C7_REAJUST + " " + SM4->M4_DESCR ,nLinPC, 050 )  //"Reajuste :"
		EndIf			

		If cPaisLoc == "BRA"
			oReport:PrintText( STR0071 + Transform(xMoeda(nTotIPI ,SC7->C7_MOEDA,Val(cMoeda),SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda) , tm(nTotIpi ,14,MsDecimais(Val(cMoeda)))) ,nLinPC,1320 ) //"IPI      :"
			oReport:PrintText( STR0072 + Transform(xMoeda(nTotIcms,SC7->C7_MOEDA,Val(cMoeda),SC7->C7_DATPRF,MsDecimais(SC7->C7_MOEDA),nTxMoeda) , tm(nTotIcms,14,MsDecimais(Val(cMoeda)))) ,nLinPC,1815 ) //"ICMS     :"
		EndIf
		oReport:SkipLine()

		nLinPC := oReport:Row()
		oReport:PrintText( STR0073 + Transform(nTotFrete , tm(nTotFrete,14,MsDecimais(Val(cMoeda)))) ,nLinPC,1320 ) //"Frete    :"
		oReport:PrintText( STR0074 + Transform(nTotDesp , tm(nTotDesp ,14,MsDecimais(Val(cMoeda)))) ,nLinPC,1815 ) //"Despesas :"
		oReport:SkipLine()
		
		// Inicializar campos de Observacoes.                           	
		If Empty(cObs02) .Or. cObs01 == cObs02
			
			cObs02 := ""
			aAux1 := strTokArr(cObs01, chr(13)+chr(10))
			nQtdLinhas := 0						
			for nX := 1 To  Len(aAux1)
				nQtdLinhas += Ceiling(Len(aAux1[nX]) / 65)
			Next nX			
			If nQtdLinhas <= 8
				R110cObs(aAux1, 65)
			Else
				R110cObs(aAux1, 40)
			EndIf			
		Else
			cObs01:= Substr(cObs01,1,IIf(Len(cObs01)<65,Len(cObs01),65))
			cObs02:= Substr(cObs02,1,IIf(Len(cObs02)<65,Len(cObs02),65))
			cObs03:= Substr(cObs03,1,IIf(Len(cObs03)<65,Len(cObs03),65))
			cObs04:= Substr(cObs04,1,IIf(Len(cObs04)<65,Len(cObs04),65))
			cObs05:= Substr(cObs05,1,IIf(Len(cObs05)<65,Len(cObs05),65))
			cObs06:= Substr(cObs06,1,IIf(Len(cObs06)<65,Len(cObs06),65))
			cObs07:= Substr(cObs07,1,IIf(Len(cObs07)<65,Len(cObs07),65))
			cObs08:= Substr(cObs08,1,IIf(Len(cObs08)<65,Len(cObs08),65))
			cObs09:= Substr(cObs09,1,IIf(Len(cObs09)<65,Len(cObs09),65))
			cObs10:= Substr(cObs10,1,IIf(Len(cObs10)<65,Len(cObs10),65))
			cObs11:= Substr(cObs11,1,IIf(Len(cObs11)<65,Len(cObs11),65))
			cObs12:= Substr(cObs12,1,IIf(Len(cObs12)<65,Len(cObs12),65))
			cObs13:= Substr(cObs13,1,IIf(Len(cObs13)<65,Len(cObs13),65))
			cObs14:= Substr(cObs14,1,IIf(Len(cObs14)<65,Len(cObs14),65))
			cObs15:= Substr(cObs15,1,IIf(Len(cObs15)<65,Len(cObs15),65))
			cObs16:= Substr(cObs16,1,IIf(Len(cObs16)<65,Len(cObs16),65))
		EndIf
		
		cComprador:= ""
		cAlter	  := ""
		cAprov	  := ""
		lNewAlc	  := .F.
		lLiber 	  := .F.
		lRejeit	  := .F.
		
		
	//Incluida validação para os pedidos de compras por item do pedido  (IP/alçada)			
		cTipoSC7:= IIF((SC7->C7_TIPO == 1 .OR. SC7->C7_TIPO == 3),"PC","AE") 
		
		If cTipoSC7 == "PC"
		
			If SCR->(dbSeek(cFilSCR+cTipoSC7+SC7->C7_NUM))
				cTst = ''
			Else
				If SCR->(dbSeek(cFilSCR+"IP"+SC7->C7_NUM))
					cTst = ''
				EndIf
			EndIf
		
		Else
		
			SCR->(dbSeek(cFilSCR+cTipoSC7+SC7->C7_NUM))
		EndIf
		
		If !Empty(SC7->C7_APROV) .Or. (Empty(SC7->C7_APROV) .And. SCR->CR_TIPO == "IP")
			
			lNewAlc := .T.
			cComprador := getFullName(SC7->C7_USER)
			If SC7->C7_CONAPRO != "B"
				IF SC7->C7_CONAPRO == "R"
					lRejeit	  := .T.
				Else
					lLiber    := .T.
				EndIf
			EndIf

			While !Eof() .And. SCR->CR_FILIAL+Alltrim(SCR->CR_NUM) == cFilSCR+Alltrim(SC7->C7_NUM) .And. SCR->CR_TIPO $ "PC|AE|IP"
				cAprov += AllTrim(getFullName(SCR->CR_USER))+" ["
				Do Case
					Case SCR->CR_STATUS=="02" //Pendente
        				cAprov += "BLQ"
					Case SCR->CR_STATUS=="03" //Liberado
						cAprov += "Ok"
					Case SCR->CR_STATUS=="04" //Bloqueado
						cAprov += "BLQ"
					Case SCR->CR_STATUS=="05" //Nivel Liberado
						cAprov += "##"
					Case SCR->CR_STATUS=="06" //Rejeitado
						cAprov += "REJ"
						
					OtherWise                 //Aguar.Lib
						cAprov += "??"
				EndCase
				cAprov += "] - "
				
				SCR->(dbSkip())
			Enddo
			If !Empty(SC7->C7_GRUPCOM)
				SAJ->(dbSeek(cFilSAJ+SC7->C7_GRUPCOM))
				While !Eof() .And. SAJ->AJ_FILIAL+SAJ->AJ_GRCOM == cFilSAJ+SC7->C7_GRUPCOM
					If SAJ->AJ_USER != SC7->C7_USER
						If nPAJ_MSBLQL > 0
							If SAJ->AJ_MSBLQL == "1"
								dbSkip()
								LOOP
							EndIf 
						EndIf
						cAlter += AllTrim(getFullName(SAJ->AJ_USER))+"/"
					EndIf
					
					SAJ->(dbSkip())
				EndDo
			EndIf
			If "[BLQ]" $ cAprov
				lLiber    := .F.
			EndIf
		EndIf

		nLinPC := oReport:Row()
		oReport:PrintText( STR0077 ,nLinPC, 050 ) // "Observacoes "
		oReport:PrintText( STR0076 + Transform(nTotSeguro , tm(nTotSeguro,14,MsDecimais(MV_PAR12))) ,nLinPC, 1815 ) // "SEGURO   :"
		oReport:SkipLine()

		nLinPC2 := oReport:Row()
		oReport:PrintText(cObs01,,050 )
		oReport:PrintText(cObs02,,050 )

		nLinPC := oReport:Row()
		oReport:PrintText(cObs03,nLinPC,050 )

		If !lNewAlc
			oReport:PrintText( STR0078 + Transform(nTotalNF , tm(nTotalNF,14,MsDecimais(MV_PAR12))) ,nLinPC,1774 ) //"Total Geral :"
		Else
			If lLiber
				oReport:PrintText( STR0078 + Transform(nTotalNF , tm(nTotalNF,14,MsDecimais(MV_PAR12))) ,nLinPC,1774 )
			Else
				oReport:PrintText( STR0078 + If((SC7->C7_TIPO == 1 .OR. SC7->C7_TIPO == 3),IF(lRejeit,STR0130,STR0051),STR0086) ,nLinPC,1390 )
			EndIf
		EndIf
		oReport:SkipLine()
		
		oReport:PrintText(cObs04,,050 )
		oReport:PrintText(cObs05,,050 )
		oReport:PrintText(cObs06,,050 )
		nLinPC3 := oReport:Row()
		oReport:PrintText(cObs07,,050 )
		oReport:PrintText(cObs08,,050 )
		oReport:PrintText(cObs09,nLinPC2,650 )
		oReport:SkipLine()
		oReport:PrintText(cObs10,,650 )
		oReport:PrintText(cObs11,,650 )
		oReport:PrintText(cObs12,,650 )
		oReport:PrintText(cObs13,,650 )
		oReport:PrintText(cObs14,,650 )
		oReport:PrintText(cObs15,,650 )
		oReport:PrintText(cObs16,,650 )

		If !lNewAlc
			
			oReport:Box( 2700 , 0010 , 3020 , 0400 )
			oReport:Box( 2700 , 0400 , 3020 , 0800 )
			oReport:Box( 2700 , 0800 , 3020 , 1220 )
			oReport:Box( 2600 , 1220 , 3020 , 1770 )
			oReport:Box( 2600 , 1770 , 3020 , nPageWidth-4 )
			
			oReport:SkipLine()
			oReport:SkipLine()
			oReport:SkipLine()

			nLinPC := oReport:Row()
			oReport:PrintText( If((SC7->C7_TIPO == 1 .OR. SC7->C7_TIPO == 3),STR0079,STR0084),nLinPC,1310) //"Liberacao do Pedido"##"Liber. Autorizacao "
			oReport:PrintText( STR0080 + IF( SC7->C7_TPFRETE $ "F","FOB",IF(SC7->C7_TPFRETE $ "C","CIF",IF(SC7->C7_TPFRETE $ "R",STR0132,IF(SC7->C7_TPFRETE $ "D",STR0133,IF(SC7->C7_TPFRETE $ "T",STR0134," " ) )))) ,nLinPC,1820 ) //STR0132 Por conta remetente, STR0133 Por conta destinatario,STR0134 Por Conta Terceiros.
			oReport:SkipLine()

			oReport:SkipLine()
			oReport:SkipLine()

			nLinPC := oReport:Row()
			oReport:PrintText( STR0021 ,nLinPC, 050 ) //"Comprador"
			oReport:PrintText( STR0022 ,nLinPC, 430 ) //"Gerencia"
			oReport:PrintText( STR0023 ,nLinPC, 850 ) //"Diretoria"
			oReport:SkipLine()

			oReport:SkipLine()
			oReport:SkipLine()

			nLinPC := oReport:Row()
			oReport:PrintText( Replic("_",23) ,nLinPC,  050 )
			oReport:PrintText( Replic("_",23) ,nLinPC,  430 )
			oReport:PrintText( Replic("_",23) ,nLinPC,  850 )
			oReport:PrintText( Replic("_",31) ,nLinPC, 1310 )
			oReport:SkipLine()

			oReport:SkipLine()
			oReport:SkipLine()
			oReport:SkipLine()
			If SC7->C7_TIPO == 1 .OR. SC7->C7_TIPO == 3
				oReport:PrintText(STR0081,,050 ) //"NOTA: So aceitaremos a mercadoria se na sua Nota Fiscal constar o numero do nosso Pedido de Compras."
			Else
				oReport:PrintText(STR0083,,050 ) //"NOTA: So aceitaremos a mercadoria se na sua Nota Fiscal constar o numero da Autorizacao de Entrega."
			EndIf
			
		Else
			
			oReport:Box( 2570 , 1220 , 2700 , 1820 )
			oReport:Box( 2570 , 1820 , 2700 , nPageWidth-4 )
			oReport:Box( 2700 , 0010 , 3020 , nPageWidth-4 )
			oReport:Box( 2970 , 0010 , 3020 , 1800 )
			
			nLinPC := nLinPC3
			
			oReport:PrintText( If((SC7->C7_TIPO == 1 .OR. SC7->C7_TIPO == 3), If( lLiber , STR0050 , IF(lRejeit,STR0130,STR0051) ) , If( lLiber , STR0085 , STR0086 ) ),nLinPC,1290 ) //"     P E D I D O   L I B E R A D O"#"|     P E D I D O   B L O Q U E A D O !!!"
			oReport:PrintText( STR0080 + Substr(RetTipoFrete(SC7->C7_TPFRETE),3),nLinPC,1830 ) //"Obs. do Frete: "
			oReport:SkipLine()

			oReport:SkipLine()
			oReport:SkipLine()
			oReport:SkipLine()
			oReport:PrintText(STR0052+" "+Substr(cComprador,1,60),,050 ) 	//"Comprador Responsavel :" //"BLQ:Bloqueado"
			oReport:SkipLine()
			oReport:PrintText(STR0053+" "+ If( Len(cAlter) > 0 , Substr(cAlter,001,130) , " " ),,050 ) //"Compradores Alternativos :"
			oReport:PrintText(            If( Len(cAlter) > 0 , Substr(cAlter,131,130) , " " ),,440 ) //"Compradores Alternativos :"
			
			

			nLinCar := 140
			nColCarac := 050
			nCCarac := 140
			
			nAprovLin := Ceiling( IIF(Len(AllTrim(cAprov)) < 75, 75, Len(AllTrim(cAprov))) / nLinCar)
			
			For nX := 1 to nAprovLin 
				If nX == 1
					oReport:PrintText(STR0054+" "+If( Len(cAprov) > 0 , Substr(cAprov,001,nLinCar) , " " ),,nColCarac ) //"Aprovador(es) :"
					nColCarac+=250
				Else
					oReport:PrintText(            If( Len(cAprov) > 0 , Substr(cAprov,nCCarac+1,nLinCar) , " " ),,nColCarac )
					nCCarac+=nLinCar
				EndIf
			Next nx

			nX:=nAprovLin
			While nX <= 3			
				oReport:SkipLine()
				nX:=nX+1
			EndDo


			nLinPC := oReport:Row()
			oReport:PrintText( STR0082+" "+STR0060 ,nLinPC, 050 ) 	//"Legendas da Aprovacao : //"BLQ:Bloqueado"
			oReport:PrintText(       "|  "+STR0061 ,nLinPC, 610 ) 	//"Ok:Liberado"
			oReport:PrintText(       "|  "+STR0131 ,nLinPC, 830 ) 	//"Ok:REJEITADO"
			oReport:PrintText(       "|  "+STR0062 ,nLinPC, 1050 ) 	//"??:Aguar.Lib"
			oReport:PrintText(       "|  "+STR0067 ,nLinPC, 1300 )	//"##:Nivel Lib"
			oReport:SkipLine()

			oReport:SkipLine()
			If SC7->C7_TIPO == 1 .OR. SC7->C7_TIPO == 3
				oReport:PrintText(STR0081,,050 ) //"NOTA: So aceitaremos a mercadoria se na sua Nota Fiscal constar o numero do nosso Pedido de Compras."
			Else
				oReport:PrintText(STR0083,,050 ) //"NOTA: So aceitaremos a mercadoria se na sua Nota Fiscal constar o numero da Autorizacao de Entrega."
			EndIf
		EndIf
		
	Next nVias
	
	MaFisEnd()
	
	// Grava no SC7 as Reemissoes e atualiza o Flag de impressao.  
	If Len(aRecnoSave) > 0
		For nX :=1 to Len(aRecnoSave)
			dbGoto(aRecnoSave[nX])
			If(SC7->C7_QTDREEM >= 99)	
				If nRet == 1
					RecLock("SC7",.F.)
					SC7->C7_EMITIDO := "S"
					MsUnLock()
				Elseif nRet == 2
					RecLock("SC7",.F.)
					SC7->C7_QTDREEM := 1
					SC7->C7_EMITIDO := "S"
					MsUnLock()
				Elseif nRet == 3
					//cancelar
				Endif
			Else
				RecLock("SC7",.F.)
				SC7->C7_QTDREEM := (SC7->C7_QTDREEM + 1)
				SC7->C7_EMITIDO := "S"
				MsUnLock()
			Endif
		Next nX

		// Reposiciona o SC7 com base no ultimo elemento do aRecnoSave. 
		SC7->(dbGoto(aRecnoSave[Len(aRecnoSave)]))
	Endif
	
	Aadd(aPedMail,aPedido)
	
	aRecnoSave := {}
	
	
	SC7->(dbSkip())
	
EndDo

oSection2:Finish()

// Executa o ponto de entrada M110MAIL quando a impressao for  
// enviada por email, fornecendo um Array para o usuario conten
// do os pedidos enviados para possivel manipulacao.            
If ExistBlock("M110MAIL")
	lEnvMail := (oReport:nDevice == 3)
	If lEnvMail
		Execblock("M110MAIL",.F.,.F.,{aPedMail})
	EndIf
EndIf

If lAuto .And. !lImpri
	Aviso(STR0104,STR0105,{"OK"})
Endif


SC7->(dbClearFilter())
SC7->(dbSetOrder(1))

Return

/*/{Protheus.doc} InscrEst
Retorna inscrição estadual do fornecedor
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 6/6/2022
@return character, cInscrEst
/*/
static function InscrEst()
return AllTrim( iif( Empty( SM0->M0_INSC), 'ISENTO', SM0->M0_INSC ) )

/*/{Protheus.doc} CabecPCxAE
Monta cabeçalho a cada quebra da seção 1
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 6/6/2022
@param oReport, object, objeto do modelo do relatório
@param oSection1, object, objeto da seção
@param nVias, numeric, quantidade de vias a serem impressas
@param nPagina, numeric, número da página
/*/
Static Function CabecPCxAE(oReport,oSection1,nVias,nPagina)

Local nLinPC		:= 0
Local nPageWidth	:= oReport:PageWidth()
Local cCGC			:= ""
Local cTitCGC 		:= FWX3Titulo( "A2_CGC" )

If Type("cPicMoeda") == "U"
	cMoeda		:= IIf( mv_par12 < 10 , Str(mv_par12,1) , Str(mv_par12,2) )
	If Val(cMoeda) == 0
		cMoeda := "1"
	Endif
	cPicMoeda := GetMV("MV_MOEDA"+cMoeda)
Endif

If Type("cInscrEst") == "U"
	cInscrEst := InscrEst()
Endif

If Type("cFilSA2") == "U"
	cFilSA2		:= xFilial("SA2")
Endif

If Type("cFilSA5") == "U"
	cFilSA5		:= xFilial("SA5")
Endif

If Type("cFilSAJ") == "U"
	cFilSAJ		:= xFilial("SAJ")
Endif

If Type("cFilSB1") == "U"
	cFilSB1		:= xFilial("SB1")
Endif

If Type("cFilSB5") == "U"
	cFilSB5		:= xFilial("SB5")
Endif

If Type("cFilSC7") == "U"
	cFilSC7		:= xFilial("SC7")
Endif

If Type("cFilSCR") == "U"
	cFilSCR		:= xFilial("SCR")
Endif

If Type("cFilSE4") == "U"
	cFilSE4		:= xFilial("SE4")
Endif

If Type("cFilSM4") == "U"
	cFilSM4		:= xFilial("SM4")
Endif

TRPosition():New(oSection1,"SA2",1,{ || cFilSA2 + SC7->C7_FORNECE + SC7->C7_LOJA })
cBitmap := R110Logo()

SA2->(dbSetOrder(1))
SA2->(dbSeek(cFilSA2 + SC7->C7_FORNECE + SC7->C7_LOJA))

oSection1:Init()

oReport:Box( 010 , 010 ,  260 , 1000 )
oReport:Box( 010 , 1000,  260 , nPageWidth-4 )  

oReport:PrintText( If(nPagina > 1,AllTrim( SM0->M0_NOMECOM )," "),,oSection1:Cell("M0_NOMECOM"):ColPos())

nLinPC := oReport:Row()
oReport:PrintText( If( mv_par08 == 1 , (STR0068), (STR0069) ) + " - " + cPicMoeda ,nLinPC,1030 )
oReport:PrintText( If( mv_par08 == 1 , SC7->C7_NUM, SC7->C7_NUMSC + "/" + SC7->C7_NUM ) + " /" + Ltrim(Str(nPagina,2)) ,nLinPC,1910 )
oReport:SkipLine()


nLinPC := oReport:Row()
If(SC7->C7_QTDREEM >= 99)	
	nRet := Aviso("TOTVS", STR0125 +chr(13)+chr(10)+ "1- " + STR0126 +chr(13)+chr(10)+ "2- " + STR0127 +chr(13)+chr(10)+ "3- " + STR0128,{"1", "2", "3"},2)
	If(nRet == 1)
		oReport:PrintText( Str(SC7->C7_QTDREEM,2) + STR0034 + Str(nVias,2) + STR0035 ,nLinPC,1910 )
	Elseif(nRet == 2)
		oReport:PrintText( "1" + STR0034 + Str(nVias,2) + STR0035 ,nLinPC,1910 )
	Elseif(nRet == 3)
		oReport:CancelPrint()
	Endif
Else		
	oReport:PrintText( If( SC7->C7_QTDREEM > 0, Str(SC7->C7_QTDREEM+1,2) , "1" ) + STR0034 + Str(nVias,2) + STR0035 ,nLinPC,1910 )
Endif                                             

oReport:SkipLine()

_cFileLogo	:= GetSrvProfString('Startpath','') + cBitmap
oReport:SayBitmap(25,25,_cFileLogo,150,60) // insere o logo no relatorio

nLinPC := oReport:Row()
oReport:PrintText(STR0087 + SM0->M0_NOMECOM,nLinPC,15)  // "Empresa:"

oReport:PrintText(STR0106 + Substr(;
If(lLGPD,RetTxtLGPD(SA2->A2_NOME,"A2_NOME"),SA2->A2_NOME),;
1,50) + " " + STR0107 + SA2->A2_COD + " " + STR0108 + SA2->A2_LOJA ,nLinPC,1025)

oReport:SkipLine()

nLinPC := oReport:Row()
oReport:PrintText(STR0088 + SM0->M0_ENDENT,nLinPC,15)

oReport:PrintText(STR0088 + Substr(;
If(lLGPD,RetTxtLGPD(SA2->A2_END,"A2_END"),SA2->A2_END),;
1,49) + " " + STR0109 + Substr(;
If(lLGPD,RetTxtLGPD(SA2->A2_BAIRRO,"A2_BAIRRO"),SA2->A2_BAIRRO),;
1,25),nLinPC,1025)

oReport:SkipLine()

If cPaisLoc == "BRA"
	cCGC	:= Transform(;
	If(lLGPD,RetTxtLGPD(SA2->A2_CGC,"A2_CGC"),SA2->A2_CGC),;
	Iif(SA2->A2_TIPO == 'F',Substr(PICPES(SA2->A2_TIPO),1,17),Substr(PICPES(SA2->A2_TIPO),1,21))) 
Else  
	cCGC	:= SA2->A2_CGC
EndIf   
        
nLinPC := oReport:Row()
oReport:PrintText(STR0089 + Trans(SM0->M0_CEPENT,cPicA2_CEP)+Space(2)+STR0090 + "  " + RTRIM(SM0->M0_CIDENT) + " " + STR0091 + SM0->M0_ESTENT ,nLinPC,15)
oReport:PrintText(STR0110+Left(;
If(lLGPD,RetTxtLGPD(SA2->A2_MUN,"A2_MUN"),SA2->A2_MUN),;
30)+" "+STR0111+;
If(lLGPD,RetTxtLGPD(SA2->A2_EST,"A2_EST"),SA2->A2_EST)+;
" "+STR0112+;
If(lLGPD,RetTxtLGPD(SA2->A2_CEP,"A2_CEP"),SA2->A2_CEP)+;
" "+cTitCGC+":"+cCGC,nLinPC,1025)

oReport:SkipLine()

nLinPC := oReport:Row()
oReport:PrintText(STR0092 + SM0->M0_TEL + Space(2) + STR0093 + SM0->M0_FAX ,nLinPC,15)

oReport:PrintText(STR0094 + "("+Substr(;
If(lLGPD,RetTxtLGPD(SA2->A2_DDD,"A2_DDD"),SA2->A2_DDD),;
1,3)+") "+Substr(;
If(lLGPD,RetTxtLGPD(SA2->A2_TEL,"A2_TEL"),SA2->A2_TEL),;
1,15) + " "+STR0114+"("+Substr(;
If(lLGPD,RetTxtLGPD(SA2->A2_DDD,"A2_DDD"),SA2->A2_DDD),;
1,3)+") "+SubStr(;
If(lLGPD,RetTxtLGPD(SA2->A2_FAX,"A2_FAX"),SA2->A2_FAX),;
1,15)+" "+If( cPaisLoc$"ARG|POR|EUA",space(11) , STR0095 )+If( cPaisLoc$"ARG|POR|EUA",space(18),;
If(lLGPD,RetTxtLGPD(SA2->A2_INSCR,"A2_INSCR"),SA2->A2_INSCR);
),nLinPC,1025)

oReport:SkipLine()

nLinPC := oReport:Row()
oReport:PrintText(cTitCGC + Transform(SM0->M0_CGC,cPicA2_CGC) ,nLinPC,15)
If cPaisLoc == "BRA"
	oReport:PrintText(Space(2) + STR0041 + cInscrEst ,nLinPC,415)
Endif
oReport:SkipLine()
oReport:SkipLine()

oSection1:Finish()

Return

/*/{Protheus.doc} R110Logo
Retorna logo do relatório
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 6/6/2022
@return character, cBitmap
/*/
Static Function R110Logo()

Local cBitmap := "LGRL"+SM0->M0_CODIGO+SM0->M0_CODFIL+".BMP" // Empresa+Filial

// Se nao encontrar o arquivo com o codigo do grupo de empresas 
// completo, retira os espacos em branco do codigo da empresa  
// para nova tentativa.                                        
If !File( cBitmap )
	cBitmap := "LGRL" + AllTrim(SM0->M0_CODIGO) + SM0->M0_CODFIL+".BMP" // Empresa+Filial
EndIf

// Se nao encontrar o arquivo com o codigo da filial completo, 
// retira os espacos em branco do codigo da filial para nova   
// tentativa.                                                  
If !File( cBitmap )
	cBitmap := "LGRL"+SM0->M0_CODIGO + AllTrim(SM0->M0_CODFIL)+".BMP" // Empresa+Filial
EndIf

// Se ainda nao encontrar, retira os espacos em branco do codigo
// da empresa e da filial simultaneamente para nova tentativa.  
If !File( cBitmap )
	cBitmap := "LGRL" + AllTrim(SM0->M0_CODIGO) + AllTrim(SM0->M0_CODFIL)+".BMP" // Empresa+Filial
EndIf

// Se nao encontrar o arquivo por filial, usa o logo padrao    
If !File( cBitmap )
	cBitmap := "LGRL"+SM0->M0_CODIGO+".BMP" // Empresa
EndIf

Return cBitmap

/*/{Protheus.doc} ReportDef
Função responsável pela geração do model do relatório do pedido de compra, baseado no fonte padrão MATR110
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 6/6/2022
@param nReg, numeric, Recno de um dos registros do pedido da tabela SC7
@param nOpcx, numeric, 1=PC ou 2=Autorização de Entrega
@return object, oReport
/*/
Static Function ReportDef(nReg,nOpcx)

Local cTitle   		:= STR0003 // "Emissao dos Pedidos de Compras ou Autorizacoes de Entrega"
Local oReport
Local oSection1
Local oSection2
Local nTamDscPrd 	:= 30 //Padrão da B1_DESC

If Type("lAuto") == "U"
	lAuto := (nReg!=Nil)
Endif

If Type("cFilSA2") == "U"
	cFilSA2		:= xFilial("SA2")
Endif

If Type("cFilSA5") == "U"
	cFilSA5		:= xFilial("SA5")
Endif

If Type("cFilSAJ") == "U"
	cFilSAJ		:= xFilial("SAJ")
Endif

If Type("cFilSB1") == "U"
	cFilSB1		:= xFilial("SB1")
Endif

If Type("cFilSB5") == "U"
	cFilSB5		:= xFilial("SB5")
Endif

If Type("cFilSC7") == "U"
	cFilSC7		:= xFilial("SC7")
Endif

If Type("cFilSCR") == "U"
	cFilSCR		:= xFilial("SCR")
Endif

If Type("cFilSE4") == "U"
	cFilSE4		:= xFilial("SE4")
Endif

If Type("cFilSM4") == "U"
	cFilSM4		:= xFilial("SM4")
Endif

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Variaveis utilizadas para parametros                         ³
//³ mv_par01               Do Pedido                             ³
//³ mv_par02               Ate o Pedido                          ³
//³ mv_par03               A partir da data de emissao           ³
//³ mv_par04               Ate a data de emissao                 ³
//³ mv_par05               Somente os Novos                      ³
//³ mv_par06               Campo Descricao do Produto    	     ³
//³ mv_par07               Unidade de Medida:Primaria ou Secund. ³
//³ mv_par08               Imprime ? Pedido Compra ou Aut. Entreg³
//³ mv_par09               Numero de vias                        ³
//³ mv_par10               Pedidos ? Liberados Bloqueados Ambos  ³
//³ mv_par11               Impr. SC's Firmes, Previstas ou Ambas ³
//³ mv_par12               Qual a Moeda ?                        ³
//³ mv_par13               Endereco de Entrega                   ³
//³ mv_par14               todas ou em aberto ou atendidos       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
Pergunte("MTR110",.F.)
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Criacao do componente de impressao                                      ³
//³                                                                        ³
//³TReport():New                                                           ³
//³ExpC1 : Nome do relatorio                                               ³
//³ExpC2 : Titulo                                                          ³
//³ExpC3 : Pergunte                                                        ³
//³ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao  ³
//³ExpC5 : Descricao                                                       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
oReport:= TReport():New("MATR110",cTitle,/* "MTR110" */, {|oReport| ReportPrint(oReport,nReg,nOpcx)})
oReport:SetPortrait()
oReport:HideParamPage()
oReport:HideHeader()
oReport:HideFooter()
oReport:SetTotalInLine(.F.)
oReport:DisableOrientation()
oReport:ParamReadOnly(lAuto)
oReport:SetUseGC(.F.)
oSection1:= TRSection():New(oReport,STR0102,{"SC7","SM0","SA2"}, /* <aOrder> */ ,;
								 /* <.lLoadCells.> */ , , /* <cTotalText>  */, /* !<.lTotalInCol.>  */, /* <.lHeaderPage.>  */,;
								 /* <.lHeaderBreak.> */, /* <.lPageBreak.>  */, /* <.lLineBreak.>  */, /* <nLeftMargin>  */,;
								 .T./* <.lLineStyle.>  */, /* <nColSpace>  */,.T. /*<.lAutoSize.> */, /*<cSeparator> */,;
								 /*<nLinesBefore>  */, /*<nCols>  */, /* <nClrBack> */, /* <nClrFore>  */)
oSection1:SetReadOnly()
oSection1:SetNoFilter("SA2")

TRCell():New(oSection1,"M0_NOMECOM","SM0","Razão Soc." ,/*Picture*/,49,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"M0_ENDENT" ,"SM0","Endereço "  ,/*Picture*/,48,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"M0_CEPENT" ,"SM0","CEP"        ,/*Picture*/,10,/*lPixel*/,{|| Trans(SM0->M0_CEPENT,cPicA2_CEP) })
TRCell():New(oSection1,"M0_CIDENT" ,"SM0","Município " ,/*Picture*/,20,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"M0_ESTENT" ,"SM0","UF "        ,/*Picture*/,11,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"M0_CGC"    ,"SM0","CGC "       ,/*Picture*/,18,/*lPixel*/,{|| Transform(SM0->M0_CGC,cPicA2_CGC) })
If cPaisLoc == "BRA"
	TRCell():New(oSection1,"M0IE"  ,"   ","Insc.Est."  ,/*Picture*/,18,/*lPixel*/,{|| InscrEst()})
EndIf
TRCell():New(oSection1,"M0_TEL"    ,"SM0","Telefone"   ,/*Picture*/,14,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"M0_FAX"    ,"SM0","Fax"        ,/*Picture*/,34,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"A2_NOME"   ,"SA2",/*Titulo*/   ,/*Picture*/,40,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"A2_COD"    ,"SA2",/*Titulo*/   ,/*Picture*/,20,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"A2_LOJA"   ,"SA2",/*Titulo*/   ,/*Picture*/,04,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"A2_END"    ,"SA2",/*Titulo*/   ,/*Picture*/,40,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"A2_BAIRRO" ,"SA2",/*Titulo*/   ,/*Picture*/,20,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"A2_CEP"    ,"SA2",/*Titulo*/   ,/*Picture*/,08,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"A2_MUN"    ,"SA2",/*Titulo*/   ,/*Picture*/,15,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"A2_EST"    ,"SA2",/*Titulo*/   ,/*Picture*/,02,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"A2_CGC"    ,"SA2",/*Titulo*/   ,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{|| code-block de impressao }*/)
TRCell():New(oSection1,"A2_INSCR"  ,"   ",If( cPaisLoc$"ARG|POR|EUA",space(11) , 'IE Forn.' ),/*Picture*/,18,/*lPixel*/,{|| If( cPaisLoc$"ARG|POR|EUA",space(18), SA2->A2_INSCR ) })
TRCell():New(oSection1,"A2_TEL"    ,"   ",'Tel.Forn.'  ,/*Picture*/,25,/*lPixel*/,{|| "("+Substr(SA2->A2_DDD,1,3)+") "+Substr(SA2->A2_TEL,1,15)})
TRCell():New(oSection1,"A2_FAX"    ,"   ",'Fax Forn.'  ,/*Picture*/,25,/*lPixel*/,{|| "("+Substr(SA2->A2_DDD,1,3)+") "+SubStr(SA2->A2_FAX,1,15)})

oSection1:Cell("A2_BAIRRO"):SetCellBreak()
oSection1:Cell("A2_CGC"   ):SetCellBreak()
oSection1:Cell("A2_INSCR"    ):SetCellBreak()

oSection2:= TRSection():New(oSection1, STR0103, {"SC7","SB1"}, /* <aOrder> */ ,;
								 /* <.lLoadCells.> */ , , /* <cTotalText>  */, /* !<.lTotalInCol.>  */, /* <.lHeaderPage.>  */,;
								 /* <.lHeaderBreak.> */, /* <.lPageBreak.>  */, /* <.lLineBreak.>  */, /* <nLeftMargin>  */,;
								 /* <.lLineStyle.>  */, /* <nColSpace>  */, /*<.lAutoSize.> */, /*<cSeparator> */,;
								 /*<nLinesBefore>  */, /*<nCols>  */, /* <nClrBack> */, /* <nClrFore>  */)

//-- Bordas para o cabeçalho
oSection2:SetCellBorder("LEFT",,, .T.)  
oSection2:SetCellBorder("TOP" ,,, .T.)

TRCell():New(oSection2, "C7_NUM"		, "SC7", "Num."        ,/*Picture*/,,,,,,,,, .T.)                                                                                
TRCell():New(oSection2, "C7_ITEM"    	, "SC7",/*Titulo*/	   ,/*Picture*/,,,,,,,,, .T.)
TRCell():New(oSection2, "C7_PRODUTO" 	, "SC7",/*Titulo*/	   ,/*Picture*/,,,,,,,,, .T.)
TRCell():New(oSection2, "DESCPROD"   	, "   ", "Desc. Prod." ,/*Picture*/, nTamDscPrd,/*lPixel*/, {|| cDescPro },,,,,, .F.)
TRCell():New(oSection2, "C7_UM"      	, "SC7", "U.M."        ,/*Picture*/,,/*lPixel*/,/* */, "CENTER",, "CENTER",,, .T.)
TRCell():New(oSection2, "C7_QUANT"   	, "SC7", "Qtd."   	   ,/*Picture*/,,/*lPixel*/,/* */, "RIGHT",, "RIGHT",,, .T.)
TRCell():New(oSection2, "C7_SEGUM"   	, "SC7", "Seg.UM"      ,/*Picture*/,,/*lPixel*/,/* */, "CENTER",, "CENTER",,, .T.)
TRCell():New(oSection2, "C7_QTSEGUM" 	, "SC7", "Qt Seg UM"   ,/*Picture*/,,/*lPixel*/,/* */, "RIGHT",, "RIGHT",,, .T.)
TRCell():New(oSection2, "PRECO"      	, "   ", "Prc.Uni."    ,/*Picture*/, TamSX3("C7_PRECO")[1],/*lPixel*/, {|| nVlUnitSC7 }, "RIGHT",, "RIGHT",,, .F.)
TRCell():New(oSection2, "C7_IPI"     	, "SC7", "IPI"         ,/*Picture*/,,/*lPixel*/,/* */,"RIGHT",, "RIGHT",,, .T.)
TRCell():New(oSection2, "TOTAL"     	, "   ", "Total"       ,/*Picture*/, TamSX3("C7_TOTAL")[1],/*lPixel*/, {|| nValTotSC7 }, "RIGHT",, "RIGHT",,, .F.)
TRCell():New(oSection2, "C7_DATPRF"  	, "SC7",/*Titulo*/	   ,/*Picture*/,,/*lPixel*/,/* */, "CENTER",, "CENTER",,, .T.)
TRCell():New(oSection2, "C7_CC"      	, "SC7", "C.Custo"     ,/*Picture*/,,/*lPixel*/,/* */, "CENTER",, "CENTER",,, .T.)
TRCell():New(oSection2, "C7_NUMSC"   	, "SC7", "Sol.Com."    ,/*Picture*/,,/*lPixel*/,/* */, "CENTER",, "CENTER",,, .T.)
TRCell():New(oSection2, "OPCC"       	, "   ", "Num.OP"      ,/*Picture*/, TamSX3("C7_OP")[1],/*lPixel*/, {|| cOPCC }, "CENTER",, "CENTER",,, .F.)        

oSection2:Cell("C7_PRODUTO"):SetLineBreak()
oSection2:Cell("DESCPROD"):SetLineBreak()
oSection2:Cell("C7_CC"):SetLineBreak()
oSection2:Cell("OPCC"):SetLineBreak()
oSection2:Cell("C7_NUMSC"):SetLineBreak()

Return(oReport)

/*
+-----------------+-------------------------+---------------------------------+-------------------+
| Fonte: GMPAICOM | Funcao:  fContFor       | Autor: Jean Carlos P. Saggin    |  Data: 31.07.2019 |
+-----------------+-------------------------+---------------------------------+-------------------+
| Descricao: Valida informações do contato digitado para o fornecedor                             |
+-------------------------------------------------------------------------------------------------+
| Parametros recebidos: Nil                                                                       |
+-------------------------------------------------------------------------------------------------+
| Retorno da funcao: lRet (.T.=Prossegue ou .F.=Bloqueia)                                         |
+-------------------------------------------------------------------------------------------------+  
*/
Static Function fContFor()
	
	Local aArea := GetArea()
	Local lRet := .T.
	Local nRet := 0
	Local cConDef := AllTrim( RetField( 'SA2', 1, xFilial( 'SA2' ) + cGetFor + cGetLoj, "A2_CONTATO" ) )
	
	if AllTrim( cContat ) != cConDef
		nRet := Aviso( 'Contato diferente!', 'O contato do cadastro do fornecedor está '+;
		        iif( Empty( cConDef ), 'vazio, ', 'diferente do informado no pedido, ' ) +;
		        'deseja atualizar o cadastro de fornecedor com a informação digitada?', {'Quero','Não'}, 3 )
		if nRet == 1			// Atualiza
			DbSelectArea( 'SA2' )
			SA2->( DbSetOrder( 1 ) )
			if DbSeek( xFilial( 'SA2' ) + cGetFor + cGetLoj )
				RecLock( 'SA2', .F. )
				SA2->A2_CONTATO := AllTrim( cContat )
				SA2->( MsUnlock() )
			EndIf
		EndIf
	EndIf
	
	RestArea( aArea )
Return ( lRet )

/*
+-----------------+-------------------------+---------------------------------+-------------------+
| Fonte: GMPAICOM | Funcao:  fMailFor       | Autor: Jean Carlos P. Saggin    |  Data: 31.07.2019 |
+-----------------+-------------------------+---------------------------------+-------------------+
| Descricao: Valida e-mail informado para o fornecedor                                            |
+-------------------------------------------------------------------------------------------------+
| Parametros recebidos: Nil                                                                       |
+-------------------------------------------------------------------------------------------------+
| Retorno da funcao: lRet (.T.=Prossegue ou .F.=Bloqueia)                                         |
+-------------------------------------------------------------------------------------------------+  
*/
Static Function fMailFor()
	
	Local aArea := GetArea()
	Local lRet := .T.
	Local nRet := 0
	Local cMaiDef := AllTrim( RetField( 'SA2', 1, xFilial( 'SA2' ) + cGetFor + cGetLoj, "A2_EMAIL" ) )
	
	if AllTrim( cGetMai ) != cMaiDef
		nRet := Aviso( 'E-mail diferente!', 'O e-mail do cadastro do fornecedor está '+;
		        iif( Empty( cMaiDef ), 'vazio, ', 'diferente do endereço informado no pedido, ' ) +;
		        'deseja atualizar o cadastro de fornecedor com a informação digitada?', {'Quero','Não'}, 3 )
		if nRet == 1			// Atualiza
			DbSelectArea( 'SA2' )
			SA2->( DbSetOrder( 1 ) )
			if DbSeek( xFilial( 'SA2' ) + cGetFor + cGetLoj )
				RecLock( 'SA2', .F. )
				SA2->A2_EMAIL := AllTrim( cGetMai )
				SA2->( MsUnlock() )
			EndIf
		EndIf
	EndIf
	
	RestArea( aArea )
Return ( lRet )

/*/{Protheus.doc} fValPed
Função de validação dos dados do carrinho de compras
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 20/09/2024
@return logical, lReturn
/*/
Static Function fValPed()
	
	Local lRet := .T.
	Local aCol := oBrwCar:aCols
	Local aHea := oBrwCar:aHeader
	Local nQtd := aScan( aHea, {|x| AllTrim( x[02] ) == "QUANT" } )
	Local nPrc := aScan( aHea, {|x| AllTrim( x[02] ) == "PRECO" } )
	Local nTot := aScan( aHea, {|x| AllTrim( x[02] ) == "TOTAL" } )
	
	lRet := iif( Empty( cGetCon ), .F., lRet )
	lRet := iif( Len( aCol ) == 0, .F., lRet )
	lRet := iif( Empty( cGetFor ) .or. Empty( cGetLoj ), .F., lRet )
	aEval( aCol, {|x| lRet := iif( ( x[nQtd] == 0 .or. x[nPrc] == 0 .or. x[nTot] == 0 ) .and. !x[Len(aHea)+1], .F., lRet ) } )
	
Return ( lRet )

/*
+-----------------+-------------------------+---------------------------------+-------------------+
| Fonte: GMPAICOM | Funcao:  fValFor        | Autor: Jean Carlos P. Saggin    |  Data: 30.07.2019 |
+-----------------+-------------------------+---------------------------------+-------------------+
| Descricao: Função para validar condição de pagamento informada                                  |
+-------------------------------------------------------------------------------------------------+
| Parametros recebidos: Nil                                                                       |
+-------------------------------------------------------------------------------------------------+
| Retorno da funcao: Nil                                                                          |
+-------------------------------------------------------------------------------------------------+  
*/
Static Function fValFor()
	
	Local lRet := ExistCpo( 'SA2', M->cGetFor + iif( M->cGetLoj != Nil, M->cGetLoj, '' ), 1 )
	
	if lRet 
		cGetMai := RetField( 'SA2', 1, xFilial( 'SA2' ) + M->cGetFor + iif( M->cGetLoj != Nil, M->cGetLoj, '' ), 'A2_EMAIL' )
		cContat := RetField( 'SA2', 1, xFilial( 'SA2' ) + M->cGetFor + iif( M->cGetLoj != Nil, M->cGetLoj, '' ), 'A2_CONTATO' )
		oDlgCar:CCAPTION := "CARRINHO DE COMPRAS" + " - " + AllTrim( RetField( 'SA2', 1, xFilial( 'SA2' ) + M->cGetFor + iif( M->cGetLoj != Nil, M->cGetLoj, '' ), 'A2_NOME' ) )
	EndIf
	
Return ( lRet )

/*
+-----------------+-------------------------+---------------------------------+-------------------+
| Fonte: GMPAICOM | Funcao:  fValCon        | Autor: Jean Carlos P. Saggin    |  Data: 30.07.2019 |
+-----------------+-------------------------+---------------------------------+-------------------+
| Descricao: Função para validar condição de pagamento informada                                  |
+-------------------------------------------------------------------------------------------------+
| Parametros recebidos: Nil                                                                       |
+-------------------------------------------------------------------------------------------------+
| Retorno da funcao: Nil                                                                          |
+-------------------------------------------------------------------------------------------------+  
*/
Static Function fValCon()
	
	Local lRet := ExistCpo( 'SE4', cGetCon, 1 )
	
	If lRet
		cGetDes := RetField( 'SE4', 1, xFilial( 'SE4' ) + cGetCon, 'E4_DESCRI' )
		oDlgCar:Refresh()
	EndIf
	
Return ( lRet )

/*/{Protheus.doc} FMANCAR
Valid das alterações do carrinho
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 09/09/2024
@return logical, lContinue
/*/
User Function FMANCAR()
	
	local nIndIPI := 0 as numeric
	local lSuccess := .T. as logical

	if oBrwCar:oBrowse:ColPos() == nPosQua				// Se a alteração foi no campo de quantidade
		if M->QUANT != Nil
			oBrwCar:aCols[oBrwCar:nAt][nPosTot] := M->QUANT * oBrwCar:aCols[oBrwCar:nAt][nPosPrc]
		EndIf 
	ElseIf oBrwCar:oBrowse:ColPos() == nPosPrc			// alteração no campo do preço
		if M->PRECO != Nil
			oBrwCar:aCols[oBrwCar:nAt][nPosTot] := oBrwCar:aCols[oBrwCar:nAt][nPosQua] * M->PRECO
		EndIf
	ElseIf oBrwCar:oBrowse:ColPos() == nPosTot			// alteração no campo do total
		if M->TOTAL != Nil
			oBrwCar:aCols[oBrwCar:nAt][nPosPrc] := M->TOTAL / iif( oBrwCar:aCols[oBrwCar:nAt][nPosQua] > 0, oBrwCar:aCols[oBrwCar:nAt][nPosQua], 1 )
		EndIf
	elseif oBrwCar:oBrowse:ColPos() == nPosIPI			// Alteração do índice de IPI
		oBrwCar:aCols[oBrwCar:nAt][nPosIPI] := M->C7_IPI
		nIndIPI := RetField( 'SB1', 1, FWxFilial( 'SB1' ) + oBrwCar:aCols[oBrwCar:nAt][nPosCod], 'B1_IPI' )
		if M->C7_IPI != nIndIPI
			if MsgYesNo( 'Gostaria de alterar a alíquota padrão de IPI do produto <b>'+ AllTrim( oBrwCar:aCols[oBrwCar:nAt][nPosDes] ) +'</b>?',;
						'A T E N Ç Ã O !' )
				DBSelectArea( 'SB1' )
				SB1->( DBSetOrder( 1 ) )
				if SB1->(DBSeek( FWxFilial( 'SB1' ) + oBrwCar:aCols[oBrwCar:nAt][nPosCod] ))
					RecLock( 'SB1', .F. )
					SB1->B1_IPI := M->C7_IPI
					SB1->( MsUnlock() )
				else
					lSuccess := .F.
				endif
			endif
		endif
	EndIf
	
	fChgCar()
	
Return ( lSuccess )

/*/{Protheus.doc} fChgCar
Recalcula dados do grid quando houver alterações
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 09/09/2024
/*/
Static Function fChgCar()
	
	local nX       := 0 as numeric
	local nValTot  := 0 as numeric
	local nFrete   := 0 as numeric
	local nPercent := 0 as numeric
	local nFreteIt := 0 as numeric
	local nValIPI  := 0 as numeric
	local cReadVar := Upper(ReadVar())
	
	// Valida se existe conteúdo no aCols antes de prosseguir
	nTotPed := 0
	if oBrwCar != Nil .and. Len( oBrwCar:aCols ) > 0
		
		for nX := 1 to len( oBrwCar:aCols )
			if ! oBrwCar:aCols[nX][len(oBrwCar:aHeader)+1]
				nValTot += oBrwCar:aCols[nX][nPosTot]
				if cReadVar == 'M->C7_IPI'
					nValIPI += Round((M->C7_IPI/100)*nValTot,2)
				else
					nValIPI += Round((oBrwCar:aCols[nX][nPosIPI]/100)*nValTot,2)
				endif
			endif
		next nX

		if nPosFre > 0
			if cReadVar == 'NPERFRE'
				nPercent := nPerFre/100
				nGetFre  := Round( nValTot * (nPerFre/100), 2)
			else
				nPercent := nGetFre / nValTot
				nPerFre  := Round( nPercent * 100, 2)
			endif
			aEval( oBrwCar:aCols, {|x| nFreteIt := Round(x[nPosTot]*nPercent,2),; 
									x[nPosFre] := nFreteIt,;
									nFrete += nFreteIt } )
			// Se ficou alguma diferença residual em virtude do arredondamento, ajusta no último item
			if nGetFre != nFrete
				oBrwCar:aCols[len(oBrwCar:aCols)][nPosFre] += nGetFre - nFrete
			endif
		endif
		nTotPed := nValTot + nValIPI + nGetFre
		oBrwCar:oBrowse:Refresh()
		oTotal:Refresh()
	EndIf
	
Return ( Nil )

/*
+-----------------+-------------------------+---------------------------------+-------------------+
| Fonte: GMPAICOM | Funcao:  fChgCar        | Autor: Jean Carlos P. Saggin    |  Data: 30.07.2019 |
+-----------------+-------------------------+---------------------------------+-------------------+
| Descricao: Função para recalcular informações do grid quando houver qualquer tipo de alteração  |
+-------------------------------------------------------------------------------------------------+
| Parametros recebidos: Nenhum                                                                    |
+-------------------------------------------------------------------------------------------------+
| Retorno da funcao: Nil                                                                          |
+-------------------------------------------------------------------------------------------------+  
*/
Static Function fBrwDel()
	fChgCar()
Return ( .T. ) 

/*/{Protheus.doc} fShowEm
Função para exibir empenhos do produto
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 21/06/2024
@param cProduto, character, ID do produto
/*/
Static Function fShowEm( cProduto )
	
	local cDescricao := AllTrim( RetField( 'SB1', 1, FWxFilial( 'SB1' ) + cProduto, 'B1_DESC' ) )
	local lEndereco  := AllTrim( RetField( 'SB1', 1, FWxFilial( 'SB1' ) + cProduto, 'B1_LOCALIZ' ) ) == 'S' .and.; 
						AllTrim( SuperGetMv( 'MV_LOCALIZ',,'N' ) ) == 'S'
	local oDlgEmp    := TDialog():New( 0, 0, 500, 900,'Empenhos do Produto '+ cDescricao,,,,,CLR_BLACK,CLR_WHITE,,,.T.)
	local oBrowse    as object
	local aColumns   := {} as array
	local bOk        := {|| oDlgEmp:End() }
	local aButtons   := {} as array
	local bCancel    := {|| oDlgEmp:End() }
	local bInit      := {|| EnchoiceBar( oDlgEmp, bOk, bCancel,,aButtons ) }
	
	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( 'Número' )
	aColumns[len(aColumns)]:SetSize( TAMSX3( 'DC_PEDIDO' )[1] )
	aColumns[len(aColumns)]:SetType( 'C' )
	aColumns[len(aColumns)]:SetPicture( "@!" )
	aColumns[len(aColumns)]:SetData( {|| QRYTMP->NUMERO } )

	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( 'Item' )
	aColumns[len(aColumns)]:SetSize( TAMSX3( 'DC_ITEM' )[1] )
	aColumns[len(aColumns)]:SetType( 'C' )
	aColumns[len(aColumns)]:SetPicture( "@!" )
	aColumns[len(aColumns)]:SetData( {|| QRYTMP->ITEM } )

	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( 'Quant.' )
	aColumns[len(aColumns)]:SetSize( TAMSX3( 'DC_QUANT' )[1] )
	aColumns[len(aColumns)]:SetType( 'N' )
	aColumns[len(aColumns)]:SetPicture( GetSX3Cache( 'DC_QUANT', 'X3_PICTURE' ) )
	aColumns[len(aColumns)]:SetData( {|| QRYTMP->QUANT } )
	aColumns[len(aColumns)]:SetAlign( 2 )

	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( 'Tipo' )
	aColumns[len(aColumns)]:SetSize( 20 )
	aColumns[len(aColumns)]:SetType( 'C' )
	aColumns[len(aColumns)]:SetPicture( '@x' )
	aColumns[len(aColumns)]:SetData( {|| iif( QRYTMP->TIPO == '1', 'Pedido', 'Ordem de Produção' ) } )

	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( 'Armazém' )
	aColumns[len(aColumns)]:SetSize( TAMSX3( 'DC_LOCAL' )[1] )
	aColumns[len(aColumns)]:SetType( 'C' )
	aColumns[len(aColumns)]:SetPicture( '@!' )
	aColumns[len(aColumns)]:SetData( {|| QRYTMP->ARMAZEM } )
	
	// Exibe coluna do endereço apenas quando o sistema estiver controlando endereçamento do produto
	if lEndereco		
		aAdd( aColumns, FWBrwColumn():New() )
		aColumns[len(aColumns)]:SetTitle( 'Endereço' )
		aColumns[len(aColumns)]:SetSize( TAMSX3( 'DC_LOCALIZ' )[1] )
		aColumns[len(aColumns)]:SetType( 'C' )
		aColumns[len(aColumns)]:SetPicture( '@!' )
		aColumns[len(aColumns)]:SetData( {|| QRYTMP->ENDERECO } )
	endif

	// Configura browse para exibição dos dados
	oBrowse := FWBrowse():New( oDlgEmp )
	oBrowse:SetDataQuery()
	oBrowse:DisableReport()
	oBrowse:DisableConfig()
	oBrowse:SetQuery( getQrEmp( cProduto, lEndereco ) )
	oBrowse:SetAlias( 'QRYTMP' )
	oBrowse:SetColumns( aColumns )
	oBrowse:Activate()

	oDlgEmp:Activate(,,,.T. /* lCentered */, {|| .T. },,bInit )
	
Return ( Nil )

/*/{Protheus.doc} getQrEmp
Retorna query para análise dos empenhos do produto conforme configurações 
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 21/06/2024
@param cProduto, character, ID do produto
@param lEndereco, character, indica se o produto utiliza enderecamento
@return character, cQuery
/*/
static function getQrEmp( cProduto, lEndereco )
	local cQuery := "" as character
	
	if lEndereco
		// Busca empenhos do produto quando utiliza controle de endereço
		cQuery := "SELECT DC_PEDIDO NUMERO, DC_ITEM ITEM, DC_QUANT QUANT, CASE DC_ORIGEM WHEN = 'SC6' THEN '1' ELSE '2' END TIPO, "
		cQuery += "       DC_LOCAL ARMAZEM, DC_LOCALIZ ENDERECO FROM "+ RetSqlName( 'SDC' ) +" "
		cQuery += "WHERE DC.DC_FILIAL  = '"+ FWxFilial( 'SDC' ) +"' "
		cQuery += "  AND DC.DC_PRODUTO = '"+ cProduto +"' "
		cQuery += "  AND DC.D_E_L_E_T_ = ' ' "
	else
		// Query para buscar empenhos do produto quando não há controle de endereçamento
		cQuery += "SELECT C9.C9_PEDIDO NUMERO, C9.C9_ITEM ITEM, C9.C9_QTDLIB QUANT, '1' TIPO, C9.C9_LOCAL ARMAZEM, "
		cQuery += "       ' ' ENDERECO FROM "+ RetSqlName( 'SC9' ) +" C9 "
		cQuery += "WHERE C9.C9_FILIAL   = '"+ FWxFilial( 'SC9' ) +"' "
		cQuery += "  AND C9.C9_PRODUTO  = '"+ cProduto +"' "
		cQuery += "  AND C9.C9_BLEST    = '  ' "
		cQuery += "  AND C9.C9_BLCRED   = '  ' "
		cQuery += "  AND C9.D_E_L_E_T_  = ' ' "
		cQuery += "UNION "
		cQuery += "SELECT LEFT(D4_OP,6) NUMERO, RIGHT(LEFT(D4_OP,8),2) ITEM, D4_QUANT QUANT, '2' TIPO, D4_LOCAL ARMAZEM, ' ' ENDERECO "
		cQuery += "FROM "+ RetSqlName( 'SD4' ) +" D4 "
		cQuery += "WHERE D4.D4_FILIAL  = '"+ FWxFilial( 'SD4' ) +"' "
		cQuery += "  AND D4.D4_COD     = '"+ cProduto +"' "
		cQuery += "  AND D4.D4_QUANT   > 0 "
		cQuery += "  AND D4.D_E_L_E_T_ = ' ' "
	endif

return cQuery 

/*/{Protheus.doc} GMPCACLA
Função para desfazer quantidade pendente a classificar nos pedidos de compra quando a informação não condiz com a realidade 
das pré-notas pendentes no sistema
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 29/03/2021
/*/
user function GMPCACLA()

	local aArea     := GetArea()
	local nQtdACla  := 0
	local nRealACla := 0

	ConOut( basicCon() +'Iniciando rotina de analise de pedidos de compra com saldo pendente de classificação...'  )

	DBSelectArea( 'SC7' )
	SC7->( DBSetOrder( 15 ) )	// C7_FILIAL + C7_ENCER + C7_PRODUTO + DTOS(C7_EMISSAO)
	if SC7->( DBSeek( FWxFilial( 'SC7' ) + Space( TAMSX3( 'C7_ENCER' )[1] ) ) )
		
		DBSelectArea( 'SD1' )
		SD1->( DBSetOrder( 22 ) )	// D1_FILIAL + D1_PEDIDO + D1_ITEMPC

		while !SC7->( EOF() ) .and. SC7->C7_FILIAL + SC7->C7_ENCER == FWxFilial( 'SC7' ) + Space( TAMSX3( 'C7_ENCER' )[1] )

			// Quantidade pendente a classificar
			if SC7->C7_QTDACLA > 0
				
				ConOut( basicCon() + 'Analisando pedido ['+ SC7->C7_NUM +'] produto ['+ AllTrim( SC7->C7_PRODUTO ) +'] Classificar: '+ AllTrim( Transform( SC7->C7_QTDACLA, '@E 999,999.99' ) ) )

				nQtdACla  := SC7->C7_QTDACLA
				nRealACla := 0

				// Verifica se encontra alguma pré-nota lançada para o produto
				if SD1->( DBSeek( FWxFilial( 'SD1' ) + SC7->C7_NUM + SC7->C7_ITEM ) )
					
					// Percorre os itens das pré-notas de entrada para o produto e verifica quais ainda não foram classificadas
					while !SD1->( EOF() ) .and. SD1->D1_FILIAL + SD1->D1_PEDIDO + SD1->D1_ITEMPC == FWxFilial( 'SD1' ) + SC7->C7_NUM + SC7->C7_ITEM

						// Verifica se a pré-nota já foi classificada, se não foi, soma o valor na quantidade real a classificar
						if Empty( SD1->D1_TES )
							nRealACla += SD1->D1_QUANT
						endif

						SD1->( DBSkip() )
					enddo
 
				endif

				ConOut( basicCon() + 'Pedido ['+ SC7->C7_NUM +'] produto ['+ AllTrim( SC7->C7_PRODUTO ) +'] Qtde Real a Classificar: '+ AllTrim( Transform( nRealACla, '@E 999,999.99' ) ) )

				// Atualiza quantidade real a classificar conforme informações da SD1
				if nRealACla != nQtdACla

					ConOut( basicCon() + 'Pedido ['+ SC7->C7_NUM +'] produto ['+ AllTrim( SC7->C7_PRODUTO ) +'] Nova quantidade a classificar: '+ AllTrim( Transform( nRealACla, '@E 999,999.99' ) ) )
					RecLock( "SC7", .F. )
					SC7->C7_QTDACLA := nRealACla
					SC7->( MsUnlock() )
				endif

			endif
			
			SC7->( DBSkip() )

		enddo

	endif

	ConOut( basicCon() +'Fim da rotina de analise de pedidos de compra pendentes de classificacao...'  )

	restArea( aArea )  

return ( Nil )

/*/{Protheus.doc} basicCon
Função para retornar conteúdo default para exibição via controle através de conout
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 29/03/2021
@return character, cBasicInfo
/*/
static function basicCon()
return ( 'GMPCACLA - '+ DtoC( Date() ) +' - '+ Time() +': ' )

/*/
Função R110ChkPerg
Autor  Vitor Pires
Data 21/09/19
Descrição Funcao para buscar as perguntas que o usuario nao pode alterar para impressao de relatorios direto do browse
/*/

Static Function R110ChkPerg()
	
	Local lPcHabPer := SuperGetMv("MV_PCHABPG", .F., .F.)
	
	If lPcHabPer
		mv_par05 := ChkPergUs(cUserId,"MTR110","05",mv_par05)
		mv_par08 := ChkPergUs(cUserId,"MTR110","08",mv_par08)
		mv_par09 := ChkPergUs(cUserId,"MTR110","09",mv_par09)
		mv_par10 := ChkPergUs(cUserId,"MTR110","10",mv_par10)
		mv_par11 := ChkPergUs(cUserId,"MTR110","11",mv_par11)
		mv_par14 := ChkPergUs(cUserId,"MTR110","14",mv_par14)
	Else
		mv_par05 := 2
		mv_par08 := SC7->C7_TIPO
		mv_par09 := 1
		mv_par10 := 3
		mv_par11 := 3
		mv_par14 := 1
	EndIf

Return
                                                    
/*/
Função ChkPergUs
Autor  Nereu Humberto Junior 
Data 21/09/07
Descrição FFuncao para buscar as perguntas que o usuario nao pode alterar para impressao de relatorios direto do browse
Sintaxe   xVar := ChkPergUs(cUserId,cGrupo,cSeq,xDefault)
Parametros cUserId 	: Id do usuario
           cGrupo 	: Grupo de perguntas
           cSeq 	 	: Numero da sequencia da pergunta
			  xDefault	: Valor default para o parametro
 Uso       MatR110
 Versão 2: Vitor Pires	25/10/2019
/*/
Static Function ChkPergUs(cUserId,cGrupo,cSeq,xDefault)

Local xRet   := Nil
Local cParam := "MV_PAR"+cSeq

SXK->(dbSetOrder(2))
If SXK->(dbSeek("U"+cUserId+cGrupo+cSeq))
	If ValType(&cParam) == "C"
		xRet := AllTrim(SXK->XK_CONTEUD)
	ElseIf 	ValType(&cParam) == "N"
		xRet := Val(AllTrim(SXK->XK_CONTEUD))
	ElseIf 	ValType(&cParam) == "D"
		xRet := CTOD((AllTrim(SXK->XK_CONTEUD)))
	Endif
Else
	If !(Type(cParam)=='U')
		xRet := &cParam
	Else
		xRet := xDefault
	EndIf		
Endif

Return(xRet)

/*/{Protheus.doc} R110FIniPC
Inicializa funções fiscais com o pedido de compras
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 6/6/2022
@param cPedido, character, número do pedido
@param cItem, character, item do pedido posicionado no momento
@param cSequen, character, sequencia do pedido
@param cFiltro, character, filtro aplicado
@return logical, lEnd
/*/
Static Function R110FIniPC(cPedido,cItem,cSequen,cFiltro)

Local aArea		:= GetArea()
Local aAreaSC7	:= SC7->(GetArea())
Local cValid	:= ""
Local nPosRef	:= 0
Local nItem		:= 0
Local cItemDe	:= IIf(cItem==Nil,'',cItem)
Local cItemAte	:= IIf(cItem==Nil,Repl('Z',Len(SC7->C7_ITEM)),cItem)
Local cRefCols	:= ''
Local nX

DEFAULT cSequen	:= ""
DEFAULT cFiltro	:= ""

dbSelectArea("SC7")
dbSetOrder(1)
If dbSeek(cFilSC7+cPedido+cItemDe+Alltrim(cSequen))
	MaFisEnd()
	MaFisIni(SC7->C7_FORNECE,SC7->C7_LOJA,"F","N","R",{})
	While !Eof() .AND. SC7->C7_FILIAL+SC7->C7_NUM == cFilSC7+cPedido .AND. ;
			SC7->C7_ITEM <= cItemAte .AND. (Empty(cSequen) .OR. cSequen == SC7->C7_SEQUEN)

		// Nao processar os Impostos se o item possuir residuo eliminado  
		If &cFiltro
			SC7->(dbSkip())
			Loop
		EndIf

		If !Empty(cRegra)
			If AllTrim(cRegra) == "NOROUND"
				nValTotSC7 := NoRound( SC7->C7_QUANT * SC7->C7_PRECO, nTamTot )
			ElseIf AllTrim(cRegra) == "ROUND"
				nValTotSC7 := Round( SC7->C7_QUANT * SC7->C7_PRECO, nTamTot )
			EndIf
		EndIf
            
		// Inicia a Carga do item nas funcoes MATXFIS  
		nItem++
		MaFisIniLoad(nItem)

		For nX := 1 To Len(aStru)
			cValid	:= StrTran(UPPER(GetCbSource(aStru[nX][7]))," ","")
			cValid	:= StrTran(cValid,"'",'"')
			If "MAFISREF" $ cValid .And. !(aStru[nX][14]) //campos que não são virtuais
				nPosRef  := AT('MAFISREF("',cValid) + 10
				cRefCols := Substr(cValid,nPosRef,AT('","MT120",',cValid)-nPosRef )
				// Carrega os valores direto do SC7.
				If aStru[nX][3] == "C7_TOTAL" .AND. !Empty(cRegra)
					MaFisLoad(cRefCols,nValTotSC7,nItem)
				Else           
					MaFisLoad(cRefCols,&("SC7->"+ aStru[nX][3]),nItem)
				EndIf
			EndIf
		Next nX		

		MaFisEndLoad(nItem,2)
		
		SC7->(dbSkip())
	End
EndIf

RestArea(aAreaSC7)
RestArea(aArea)

Return .T.

/*/{Protheus.doc} A2LTMCHG
FUnção de validação da alteração do campo do Lead-Time do Fornecedor
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 6/28/2022
@return logical, lRet
/*/
static function A2LTMCHG()
	
	local aArea := getArea()
	local lRet := .T. as logical

	if FORTMP->A2_X_LTIME < 0
		lRet := .F.
	else
		DBSelectArea( 'SA2' )
		SA2->( DBSetOrder( 1 ) )		// A2_FILIAL + A2_COD + A2_LOJA
		if SA2->( DBSeek( FWxFilial( 'SA2' ) + FORTMP->B1_PROC + FORTMP->B1_LOJPROC ) )
			RecLock( 'SA2', .F. )
			SA2->A2_X_LTIME := FORTMP->A2_X_LTIME
			SA2->( MsUnlock() )
			Processa( {|| fLoadInf() }, 'Aguarde!','Analisando dados do MRP...' )
		endif
	endif

	restArea( aArea )
return lRet

/*/{Protheus.doc} getFullName
Função para retornar nome completo do usuário com base no código
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/12/2023
@param cUser, character, codigo do usuário
@return character, cUsrFullName
/*/
static function getFullName( cUser )
return UsrFullName(cUser)

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

/*/{Protheus.doc} getOptions
Retorna opções de justificativa para os eventos do sistema
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/04/2024
@return array, aOptions
/*/
static function getOptions()
	local aOptions := {} as array
	aAdd( aOptions, { '001', 'Produto não faz parte do MRP', 'FREMMRP()', .F. } )
	aAdd( aOptions, { '002', 'Produto foi ou será descontinuado', 'FPRDDES()', .F. } )
	aAdd( aOptions, { '003', 'Produto comprado apenas sob demanda', 'FPRDDEM()', .F. } )
	aAdd( aOptions, { '004', 'Reprogramar entrega para...', 'FREPENT()', .T. } )
	aAdd( aOptions, { '005', 'Ignorar necessidade de compra até...', 'FIGNORE()', .T. } )
	aAdd( aOptions, { '006', 'Colocar produto no carrinho', 'FADDCAR()', .F. } )
	aAdd( aOptions, { '007', 'Compra não será mais atendida', 'FCANPED()', .T. } )
	aAdd( aOptions, { '008', 'Ignorar dessa vez', '.T.', .F. } )
return aOptions

/*/{Protheus.doc} btnStyle
Função para definição de estilo CSS para botoes
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 19/06/2024
@return character, cStyle
/*/
static function btnStyle()
	local cStyle := "" as character
	cStyle := "QPushButton {"
	cStyle += " border-style: outset;"
	cStyle += " border-width: 2px;"
	cStyle += " border: 1px solid #C0C0C0;"
	cStyle += " border-radius: 2px;"
	cStyle += " border-color: #C0C0C0;"
	cStyle += " font: 10px Calibri;"
	cStyle += " text-align: center"
	cStyle += "}"
	cStyle += "QPushButton:pressed {"
	cStyle += " background-color: #e6e6f9;"
	cStyle += " border-style: inset;"
	cStyle += "}"
return cStyle

/*/{Protheus.doc} lookData
Função para abertura de caixa de pesquisa
@type function
@version 1.0
@author Jean Carlos P. Saggin
@since 19/06/2024
@param cInit, character, filtro já aplicado, se existir
@return character, cText
/*/
static function lookData( cInit )
	local cLook   := "" as character
	local oLookDlg      as object
	local oGetLook      as object
	local oBtnOk   as object
	
	default cInit := ""

	cLook := PADR( cInit, 200, ' ' )
	oLookDlg := TDialog():New( 0, 0, 60,300,'Digite uma expressão de busca...',,,,,CLR_BLACK,CLR_WHITE,,,.T.)
	oLookDlg:lEscClose := .F.
	oGetLook := TGet():New( 10,04, {|u| if(PCount()==0,cLook,cLook:=u)},oLookDlg,120,011,"@x",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'cLook',,,, )
	oBtnOk   := TButton():New( 10, 126, "Ok",oLookDlg,{|| oLookDlg:End() }, 16, 12,,,.F.,.T.,.F.,,.F.,,,.F. )
	oLookDlg:Activate(,,,.T., {|| .T. },,{|| Nil })
return cLook

/*/{Protheus.doc} lookData
Função para abertura de caixa de pesquisa
@type function
@version 1.0
@author Jean Carlos P. Saggin
@since 19/06/2024
@param aFiltros, array, filtros atuais
@return character, cText
/*/
static function prodFilter( aFiltros, lManual )
	
	local oLookDlg      as object
	local oContainer    as object
	local oGetLook      as object
	local oBtnTypes     as object
	local oGetFor       as object
	local _cTypes       := "" as character

	default lManual := .F.

	_aFilters := aClone( aFiltros )
	_cTypes   := _aFilters[2]
	
	oLookDlg := FWDialogModal():New()
	oLookDlg:SetEscClose( .F. )
	oLookDlg:SetTitle( 'Filtro de Seleção de Produtos' )
	oLookDlg:SetSubTitle( 'Defina os filtros para análise de compra dos produtos...' )
	oLookDlg:SetSize( 300, 200 )
	oLookDlg:CreateDialog()
	oLookDlg:AddCloseButton( {|| _aFilters := aClone(aFiltros), oLookDlg:DeActivate()}, "Cancelar" )
	oLookDlg:AddOkButton( {|| iif( lManual .or. valFilPro( _aFilters ), oLookDlg:DeActivate(), Nil ) }, "Ok" )
	oContainer := TPanel():New( ,,, oLookDlg:getPanelMain() )
	oContainer:Align := CONTROL_ALIGN_ALLCLIENT

	oGetLook  := TGet():New( 10,04, {|u| if(PCount()==0,_aFilters[1],_aFilters[1]:=u)},oContainer,110,012,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'_aFilters[1]',,,,.T.,.F.,,'Expressão de filtro por nome', 1 )
	oGetTypes := TGet():New( 35,04, {|u| if(PCount()==0,_cTypes,_cTypes:=u)},oContainer,100,012,"@x",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'_cTypes',,,,.T.,.F.,,'Tipos de Produtos', 1 )
	oGetTypes:bWhen := {|| .F. }
	oBtnTypes := tBitmap():New( 43, 106, 12, 12,,"painel_compras_lupa.png", .T., oContainer,{|| _cTypes := U_JSPAITYP( _cTypes ),;
																						_aFilters[2] := _cTypes }, NIL, .F., .F., NIL, NIL, .F., NIL, .T., NIL, .F.)
	oGetFor   := TGet():New( 60,04, {|u| if(PCount()==0,_aFilters[3],_aFilters[3]:=u)},oContainer,70,012,"@x",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'_aFilters[3]',,,,.T.,.F.,,'Fornecedor Padrão', 1 )
	oGetFor:cF3 := "SA2"

	oLookDlg:Activate()

return _aFilters

/*/{Protheus.doc} valFilPro
Valida o conteúdo informado no filtro de pesquisa de produtos
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/25/2024
@param aFiltros, array, filtros escolhidos pelo usuário
@return logical, lValidated
/*/
static function valFilPro( aFiltros )
	local lValidated := .T. as logical
	lValidated := len( AllTrim( aFiltros[1] ) ) >= 3 .or. !Empty( aFiltros[3] )
	if ! lValidated
		Hlp( 'FILTRO INVALIDO',;
			 'Filtro de pesquisa de produtos inválido!',;
			 'Informe uma expressão de filtro para o nome do produto ou utilize o campo de fornecedor padrão para poder prosseguir' )
	endif
return lValidated

/*/{Protheus.doc} doFilter
Função para criação de filtro com a expressão digitada pelo usuário
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 19/06/2024
@param cText, character, texto informado pelo usuário na caixa de pesquisa
@param cField, character, nome do campo que vai ser usado para filtro
@return character, cFilter
/*/
static function doFilter( cText, cField )
	
	local cFilter := "" as character
	local aAux    := {} as array

	default cText := "" 
	default cField := ""

	if !Empty( cText ) .and. !Empty( cField )
		aAux := StrTokArr( AllTrim( Upper( cText ) ), ' ' )
		aEval( aAux, {|x| cFilter += iif( !Empty( cFilter ), ' .and. ', '' ) +"'"+ x +"' $ "+ cField } )
	else
		cFilter := ""
	endif

	// Se o filtro estiver preenchido, considera também registros já marcados
	// Facilitador para usuário poder filtrar vários fornecedores para analisar de uma única vez
	if !Empty( cFilter )
		cFilter := "("+ cFilter +") .or. !Empty(MARK)"
	endif

return cFilter

/*/{Protheus.doc} impData
Função de importação dos dados de produtos via excel
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 26/06/2024
@return logical, lSuccess
/*/
static function impData()
	local lSuccess := .T. as logical
	local cPatch   := "" as character
	
	// Obtem arquivo com patch completo a partir do smartclient do usuário
	cPatch := AllTrim( cGetFile( 'Arquivo CSV |*.csv',; 
								 'Selecione o arquivo CSV que gostariade importar...',;
								 0 /* nMascPad */,;
								 "" /* cInitDir */,;
								 .T. /* lOpen */,;
								 GETF_LOCALHARD,;
								 .F. /* lServerTree */,;
								 .T. /* lKeepCase */ ) )
	if ! Empty( cPatch )
		if File( cPatch )
			MsAguarde( {|| lSuccess := procData( cPatch ) }, 'Aguarde!','Importando índices de produtos...' )
			if lSuccess
				Processa( {|| fLoadInf() }, 'Aguarde!','Analisando dados do MRP...' )
			endif
		else
			Hlp( 'ARQUIVO INVALIDO',;
				 'Caminho ou nome do arquivo é inválido!',;
				 'Selecione outro arquivo ou verifique se o caminho informado para o arquivo é válido.' )
		endif
	endif
return lSuccess

/*/{Protheus.doc} procData
Função para processamento do arquivo .csv
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 26/06/2024
@param cFile, character, patch completo do arquivo a ser importado
@return logical, lSuccess
/*/
static function procData( cFile )
	
	local lSuccess := .T. as logical
	local oFile    := FWFileReader():New( cFile )
	local cLine    := "" as character
	local aAux     := {} as array
	local lExist   := .F. as logical
	local nField   := 0 as numeric
	local nSize    := 0 as numeric
	local nRead    := 0 as numeric
	local nPerc    := 0 as numeric
	local cMessage := "" as character
	
	Private aFileHdr := {} as array

	// Verifica se tem permissão de leitura para abrir o arquivo
	if oFile:Open()
		
		nSize := oFile:GetFileSize()
		// Seta o índice de pesquisa
		DBSelectArea( cZB3 )
		( cZB3 )->( DBSetOrder( 1 ) )		// PRODUTO + DATA

		// Enquanto encontrar linhas no arquivo, processa as informações...
		while oFile:hasLine() .and. lSuccess
			// Obtem as linhas do arquivo
			cLine := AllTrim(oFile:GetLine())
			aAux  := StrTokArr2( cLine, ';' )

			nRead := oFile:getBytesRead()
			nPerc := Round( (nRead/nSize)*100,0)
			if nPerc < 10
				cMessage := "Bora trabalhar! Iniciando os trabalhos, "+ cValToChar( nPerc ) +'% já foi!'
			elseif nPerc < 50
				cMessage := "Tenha paciência, logo chegaremos na metade! Já estamos em "+ cValToChar( nPerc ) +'%...'
			elseif nPerc < 80
				cMessage := "Não disse? Falta só "+ cValToChar( 100-nPerc ) +'% para finalizar...'
			else
				cMessage := "Agora é mamão com açúcar, faltando "+ cValToChar( 100-nPerc ) +'% nem dá mais tempo de tomar café...'
			endif
			MsProcTxt( cMessage )
			
			// Quando estiver na primeira linha, popula o vetor do cabeçalho para saber quais campos existem no arquivo
			if len( aFileHdr ) == 0
				aEval( aAux, {|x| aAdd( aFileHdr, { x,;
													GetSX3Cache( x, 'X3_TIPO' ),;
													GetSX3Cache( x, 'X3_TAMANHO' ),;
													GetSX3Cache( x, 'X3_DECIMAL' ),;
													GetSX3Cache( x, 'X3_DECIMAL' ) } ) } )
			else
				// Verifica se o ID do produto está presente no registro do arquivo
				// Verifica também se o produto da linha do arquivo é um registro apto para uso 
				if gt( cZB3 +'_PROD' ) > 0 .and. gt( cZB3 +'_DATA' ) > 0 .and. ExistCpo( 'SB1', aAux[gt( cZB3 +'_PROD' )], 1 )
					
					// Tenta localizar registro do produto na data informada para garantir que o registro não vai se repetir
					lExist := ( cZB3 )->( DBSeek( FWxFilial( cZB3 ) + aAux[gt( cZB3 +'_PROD' )] + DtoS(CtoD(aAux[gt( cZB3 +'_DATA' )])) ) )

					// Se o registro já existe para o produto, atualiza os dados
					RecLock( cZB3, !lExist )
						( cZB3 )->( FieldPut( FieldPos( cZB3 +'_FILIAL' ), FWxFilial('ZB3' ) ) )
						for nField := 1 to len( aFileHdr )
							if ( cZB3 )->( FieldPos( aFileHdr[nField][1] ) ) > 0
								( cZB3 )->( FieldPut( FieldPos( aFileHdr[nField][1] ), typeAdapt( aFileHdr[nField][1], aAux[gt( aFileHdr[nField][1] )] ) ) )
							endif
						next nField
					( cZB3 )->( MsUnlock() )
				elseif ! gt( cZB3 +'_PROD' ) > 0 .or. ! gt( cZB3 +'_DATA' ) > 0 
					Hlp( 'CAMPOS CHAVE',;
						'Os campos de codigo do produto e/ou data não foram informados no arquivo .csv',;
						'Esses campos são obrigatórios para o registro dos índices de produtos' )
					lSuccess := .F.
				endif
			endif
			
		end
		oFile:Close()
	endif
return lSuccess

/*/{Protheus.doc} typeAdapt
Função para conversão da informação lida a partir do arquivo texto para a tipagem do campo definida no dicionário de dados
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 26/06/2024
@param cField, character, ID do campo
@param cInfo, character, texto lido do arquivo
@return variadic, xRet
/*/
static function typeAdapt( cField, cInfo )
	local xRet := Nil
	local cType := GetSX3Cache( cField, 'X3_TIPO')
	if cType == 'N'			// Numérico
		xRet := Round( Val( StrTran( AllTrim( cInfo ), ',', '.' ) ), TAMSX3( cField )[2] )
	elseif cType == 'D'		// Data
		xRet := CtoD( cInfo )
	elseif cType == 'L'		// Lógico
		xRet := AllTrim(StrTran( cInfo, '.', '' )) == 'T'
	else					// Texto
		xRet := cInfo
	endif
return xRet


/*/{Protheus.doc} gt
Função para retornar posição de um campo no header do arquivo
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 26/06/2024
@param cField, character, id do campo
@return numeric, nPos
/*/
static function gt( cField )
return aScan( aFileHdr, {|x| AllTrim( x[1] ) == AllTrim( cField ) } )

/*/{Protheus.doc} someChange																												
Função chamada quando o sistema perceber qualquer alteração em um dos campos da tela
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 14/08/2024
/*/
static function someChange( lReset )
	
	local cVar  := upper(ReadVar())	
	local aLast := {} as array	
	
	default lReset := .F.

	// Entrada
	nGetUOC := iif( lReset, ( SD1TMP->D1_TOTAL - SD1TMP->D1_VALDESC ) / SD1TMP->D1_QUANT, nGetUOC )
	nGetUNF := iif( lReset, ( SD1TMP->D1_TOTAL - SD1TMP->D1_VALDESC ) / SD1TMP->D1_QUANT, nGetUNF )
	cGetTES := iif( lReset, SD1TMP->D1_TES, cGetTES )
	cGetDTE := RetField( 'SF4', 1, FWxFilial( 'SF4' ) + cGetTES, 'F4_TEXTO' )
	nGetICM := iif( lReset, SD1TMP->D1_PICM, nGetICM )
	nValICM := iif( lReset, SD1TMP->D1_VALICM / SD1TMP->D1_QUANT, nValICM )
	nGetIPI := iif( lReset, SD1TMP->D1_IPI, nGetIPI )
	nValIPI := iif( lReset, SD1TMP->D1_VALIPI / SD1TMP->D1_QUANT, nValIPI )
	nGetFre := iif( lReset, ( SD1TMP->D1_VALFRE / ( SD1TMP->D1_TOTAL - SD1TMP->D1_VALDESC )) * 100, nGetFre )
	nValFre := iif( lReset, SD1TMP->D1_VALFRE / SD1TMP->D1_QUANT, nValFre )
	nGetICF := iif( lReset, 0, nGetICF )
	nValICF := iif( lReset, 0, nValICF )
	nGetOut := iif( lReset, (SD1TMP->D1_DESPESA/(SD1TMP->D1_TOTAL-SD1TMP->D1_VALDESC)) * 100, nGetOut )
	nValOut := iif( lReset, SD1TMP->D1_DESPESA / SD1TMP->D1_QUANT, nValOut )
	nGetFin := iif( lReset, (SD1TMP->VALFIN / ( SD1TMP->D1_TOTAL - SD1TMP->D1_VALDESC )) * 100, nGetFin )
	nValFin := iif( lReset, SD1TMP->VALFIN / SD1TMP->D1_QUANT, nValFin )
	nGetPC  := iif( lReset, SD1TMP->D1_ALQIMP5 + SD1TMP->D1_ALQIMP6, nGetPC )
	nValPC  := iif( lReset, ( SD1TMP->D1_VALIMP5 + SD1TMP->D1_VALIMP6 ) / SD1TMP->D1_QUANT, nValPC )
	nGetST  := iif( lReset, iif( SD1TMP->D1_ICMSRET > 0, SD1TMP->D1_ALIQSOL, 0 ), nGetST )
	nValST  := iif( lReset, SD1TMP->D1_ICMSRET / SD1TMP->D1_QUANT, nValST )
	nGetMVA := iif( lReset, SD1TMP->D1_MARGEM, nGetMVA )
	nGetCuL := iif( lReset, nGetUOC - nValICM + nValIPI + nValFre - nValICF + nValOut + nValFin + nValST, nGetCuL )
	nGetCuM := RetField( 'SB2', 1, SD1TMP->D1_FILIAL + SD1TMP->D1_COD + SD1TMP->D1_LOCAL, 'B2_CM1' )

	// Saída
	nGetTCV := nGetLuc + nGetPCV + nGetICV + nGetOpe + nGetCSL + nGetIRP + nGetIna
	nGetPSL := nGetCuL / ( 1-( (nGetPCV/100)+(nGetICV/100)+(nGetOpe/100)+(nGetCSL/100)+(nGetIRP/100)+(nGetIna/100)+(nGetFiV/100) ) )
	nGetSug := iif( cVar == 'NGETSUG', nGetSug, nGetCuL / ( 1-( (nGetLuc/100)+(nGetPCV/100)+(nGetICV/100)+(nGetOpe/100)+(nGetCSL/100)+(nGetIRP/100)+(nGetIna/100)+(nGetFiV/100) ) ) )
	nGetMg1 := ( (nGetSug-nGetCuL) / nGetSug ) * 100
	nGetPrc := RetField( 'DA1', 1, FWxFilial( 'DA1' ) + cGetTab + SD1TMP->D1_COD, "DA1_PRCVEN" )
	nGetMg2 := iif( nGetPrc > 0, ( (nGetPrc-nGetCuL) / nGetPrc ) * 100, 0 )

	// Obtem os dados da ultima nota
	aLast   := getLastDoc( cGetCod )
	if Len( aLast ) > 0
		nGetUPr := aLast[1]
		nGetUQt := aLast[2]
		dGetUDt := aLast[3]
		cGetUPz := aLast[4]
		cGetNF  := aLast[5]
		cGetUFi := aLast[6]
		cGetUFo := aLast[7]
	endif
	oDlgDoc:Refresh()
return nil

/*/{Protheus.doc} getLastDoc
Função para identificar a ultima nota de entrada do cliente
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 04/09/2024
@param cProduto, character, ID do produto
@return array, aLast
/*/
static function getLastDoc( cProduto )

	local aData  := {} as array
	local cQuery := "" as character

	// Query para identificar a ultima nota
	cQuery := "SELECT D1.D1_COD, MAX(D1.D1_EMISSAO) D1_EMISSAO, COALESCE(MAX(D1.R_E_C_N_O_),0) RECSD1 "
	cQuery += "FROM "+ RetSqlName( 'SD1' ) +" D1 "
	cQuery += "WHERE D1.D1_COD     = '"+ cProduto +"' "
	cQuery += "  AND D1.D1_TIPO    = 'N' "			// Somente notas do tipo normal
	cQuery += "  AND D1.D1_TES    <> '"+ Space( TAMSX3( 'D1_TES' )[1] ) +"' "
	cQuery += "  AND D1.D_E_L_E_T_ = ' ' "
	cQuery += "GROUP BY D1.D1_COD "

	DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), 'LASTD1', .F., .T. )
	if ! LASTD1->( EOF() )
		
		// Posiciona no registro físico
		DBSelectArea( 'SD1' )
		SD1->( DBGoTo( SD1TMP->RECSD1 ) )

		aAdd( aData, ( SD1->D1_TOTAL - SD1->D1_DESC ) / SD1->D1_QUANT /* nGetUPr */ )
		aAdd( aData, SD1->D1_QUANT /* nGetUQt */ )
		aAdd( aData, SD1->D1_EMISSAO /* dGetUDt */ )
		
		// Posiciona no cabeçalho para identificar o prazo de pagamento
		DBSelectArea( 'SF1' )
		SF1->( DBSetOrder( 1 ) )		// FILIAL + DOC + SERIE + FORNECE + LOJA + TIPO
		SF1->( DBSeek( SD1->D1_FILIAL + SD1->D1_DOC + SD1->D1_SERIE + SD1->D1_FORNECE + SD1->D1_LOJA + SD1->D1_TIPO ) )

		aAdd( aData, AllTrim(RetField( 'SE4', 1, FWxFilial("SE4") + SF1->F1_COND, "E4_DESCRI" )) /* cGetUPz */ )
		aAdd( aData, SD1->D1_DOC /* cGetNF */ )
		aAdd( aData, SD1->D1_FILIAL /* cGetUFi */ )

		DBSelectArea( 'SA2' )
		SA2->( DBSetOrder( 1 ) )		// FILIAL + COD + LOJA
		SA2->( DBSeek( FWxFilial( 'SA2' ) + SF1->F1_FORNECE + SF1->F1_LOJA ) )

		aAdd( aData, AllTrim( SA2->A2_NOME ) /* cGetUFo */ )

	endif
	LASTD1->( DBCloseArea() )

return aData


/*/{Protheus.doc} doGet
Função para criar o get de forma mais simples
@type function
@version 1.0q
@author Jean Carlos Pandolfo Saggin
@since 13/08/2024
@param nTop, numeric, posição do objeto em relação ao topo do Dlg
@param nLeft, numeric, posição do objeto em relação ao lado esquerdo do Dlg
@param bAction, codeblock, codeblock do objeto
@param oDlg, object, objeto do dialog da janela
@param nSize, numeric, tamanho do campo
@param nHeight, numeric, altura do campo
@param cPicture, character, picture do campo
@param cVar, character, string com nome da variável do objeto
@param cLabel, character, string com a label do campo
@param lEnable, logical, indica se o campo deve ficar aberto para usuário alterar os dados
@return object, oGet
/*/
static function doGet( nTop, nLeft, bAction, oDlg, nSize, nHeight, cPicture, cVar, cLabel, lEnable )
	local oFont  := TFont():New('Courier New',,10,.T.)
	local cLbPad := iif( ValType( cLabel ) == 'C' .and. !Empty( cLabel ), PADR( AllTrim( cLabel ), 12, '.' ), cLabel ) 
	local oGet   as object
	default lEnable := .T.
	oGet := TGet():New( nTop, nLeft, bAction, oDlg, nSize, nHeight,cPicture,,0,Nil,,.F.,,.T. /* lPixel */,,.F.,/* bWhen */,;
						.F.,.F.,/* bChange */,/* lReadOnly */,.F.,,cVar,,,,.T.,.F.,,cLbPad, 2, oFont, CLR_BLUE )
	oGet:bChange := {|| someChange() }
	oGet:bWhen   := &('{|| '+iif(lEnable,'.T.','.F.')+ '}')
return oGet

/*/{Protheus.doc} lastOC
Função para retornar o valor negociado do último pedido de compra
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 13/08/2024
@param cProduto, character, ID do produto
@return numeric, nValue
/*/
static function lastOC( cProduto )
	
	local nValue := 0 as numeric
	local cQuery := "" as character
	
	cQuery := "SELECT COALESCE(MAX(C7.R_E_C_N_O_),0) RECSC7 FROM "+ RetSqlName( 'SC7' ) +" C7 "
	cQuery += "WHERE C7.C7_FILIAL  = '"+ FWxFilial( 'SC7' ) +"' "
	cQuery += "  AND C7.C7_PRODUTO = '"+ cProduto +"' "
  	cQuery += "  AND C7.D_E_L_E_T_ = ' ' " 

	DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), 'SC7TMP', .F., .T. )
	
	// Somente se existe nota de compra para o produto
	if SC7TMP->RECSC7 > 0
		
		// Posiciona no registro da tabela SC7
		DBSelectArea( 'SC7' )
		SC7->( DBGoTo( SC7TMP->RECSC7 ) )
		nValue := Round( SC7->C7_TOTAL / SC7->C7_QUANT, 2)

	endif
	
	SC7TMP->( DBCloseArea() )

return nValue

/*/{Protheus.doc} typesDef
Função para obter os tipos de produtos configurados como padrões para utilização na central de compras
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 09/09/2024
@return array, aTypes
/*/
static function typesDef( cTipos )
	local aTypes := {} as array
	local aAux   := StrTokArr( cTipos, '/' )
	aEval( aAux, {|x| aAdd( aTypes, Upper(AllTrim( x )) ) } )
return aTypes

/*/{Protheus.doc} getFilData
Função para obter as filiais da empresa que o usuário estiver conectado
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/10/2024
@return array, aFilData
/*/
static function getFilData( aSelected )
	
	local aFilData := {} as array
	local cQuery   := "" as character

	cQuery := "SELECT M0_CODFIL, M0_FILIAL, M0_CGC FROM SYS_COMPANY WHERE M0_CODIGO = '"+ cEmpAnt +"' AND D_E_L_E_T_ = ' ' "
	DBUseArea( .T., "TOPCONN", TcGenQry(,,cQuery), 'SM0TMP', .F., .T.)	
	while ! SM0TMP->(EOF())
		aAdd( aFilData, { aScan( aSelected, {|x| AllTrim( x ) == AllTrim( SM0TMP->M0_CODFIL ) } ) > 0 /* lMark */,;
							SM0TMP->M0_CODFIL,;
							AllTrim(SM0TMP->M0_FILIAL),;
							SM0TMP->M0_CGC } )
		SM0TMP->( DBSkip() )
	end
	SM0TMP->( DBCloseArea() )
		
return aFilData

/*/{Protheus.doc} userFil
Função para usuário selecionar as filiais que quer analisar
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/10/2024
@param aFiliais, array, vetor contendo as filiais da empresa em que o usuário está logado
@param aSelected, array, vetor com as filials já selecionadas
@return array, aSelected
/*/
static function userFil( aSelected )
	
	local oBrwFil as object
	local oDlgFil as object
	local aBrwFil  := getFilData( aSelected )
	local bOk      := {|| aSelected := getSelected( aBrwFil ), oDlgFil:End() }
	local bCancel  := {|| oDlgFil:End() }
	local aButtons := {} as array
	local binit    := {|| EnchoiceBar( oDlgFil, bOk, bCancel,,@aButtons ) }
	local lMark    := .F.
	local aColumns := {} as array

	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( 'Filial' )
	aColumns[len(aColumns)]:SetSize( len( cFilAnt ) )
	aColumns[len(aColumns)]:SetType( 'C' )
	aColumns[len(aColumns)]:SetPicture( '@!' )
	aColumns[len(aColumns)]:SetData( {|| aBrwFil[oBrwFil:nAt][2] } )

	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( 'Descrição' )
	aColumns[len(aColumns)]:SetSize( 30 )
	aColumns[len(aColumns)]:SetType( 'C' )
	aColumns[len(aColumns)]:SetPicture( '@x' )
	aColumns[len(aColumns)]:SetData( {|| aBrwFil[oBrwFil:nAt][3] } )


	oDlgFil := TDialog():New( 0, 0, 400,450,'Seleção de Filiais',,,,,CLR_BLACK,CLR_WHITE,,,.T.)
	oDlgFil:lEscClose := .T.
	oBrwFil := FWBrowse():New( oDlgFil )
	oBrwFil:SetDataArray()
	oBrwFil:SetArray( aBrwFil )
	oBrwFil:DisableConfig()
	oBrwFil:DisableReport()
	oBrwFil:AddMarkColumns( {|oBrwFil| if( aBrwFil[oBrwFil:nAt][1], 'LBOK','LBNO' ) },;
							{|oBrwFil| aBrwFil[oBrwFil:nAt][1] := !aBrwFil[oBrwFil:nAt][1] },;
							{|oBrwFil| lMark := !aBrwFil[1][1], aEval( aBrwFil, {|x| x[1] := lMark } ), oBrwFil:UpdateBrowse() } )
	
	oBrwFil:SetColumns( aColumns )
	oBrwFil:Activate()						

	oDlgFil:Activate(,,,.T., {|| .T. },,bInit)

return aSelected

/*/{Protheus.doc} getSelected
Função para obter as filiais selecionadas pelo usuário
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/10/2024
@param aBrwFil, array, vetor com as filiais da empresa
@return array, aSelected
/*/
static function getSelected( aBrwFil )
	local aSelected := {} as array
	local nFilial   := 0 as numeric
	for nFilial := 1 to len( aBrwFil )
		if aBrwFil[nFilial][1]
			aAdd( aSelected, aBrwFil[nFilial][2] )
		endif
	next nFilial
return aSelected

/*/{Protheus.doc} getColPro
Função para retornar colunas do browse de produtos
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/12/2024
@param aFields, array, vetor de campos a serem incluídos no grid
@param aAlter, array, vetor de campos em que o usuário vai poder alterar os dados
@return array, aColumns
/*/
static function getColPro( aFields, aAlter )

	local aColumns := {} as array
	local nX       := 0 as numeric
	local aAux     := {} as array
	local cType    := "" as character

	for nX := 1 to len( aFields )
		DBSelectArea( 'SB1' )
		if SB1->( FieldPos( aFields[nX] ) ) > 0
			cType := StrTran(GetSX3Cache( aFields[nX], 'X3_TIPO' ),'M','C')
			if !Empty(GetSX3Cache( aFields[nX], "X3_CBOX" ))
				aAux := StrTokArr( GetSX3Cache( aFields[nX], "X3_CBOX" ),';')
			else
				aAux := {}
			endif
			aAdd(aColumns, {;
							AllTrim(GetSX3Cache( aFields[nX], 'X3_TITULO' )),;                     	// [n][01] Título da coluna
							&("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX) +"] }"),; 				// [n][02] Code-Block de carga dos dados
							StrTran(GetSX3Cache( aFields[nX], 'X3_TIPO' ),'M','C'),;                // [n][03] Tipo de dados
							AllTrim(GetSX3Cache( aFields[nX], 'X3_PICTURE' )),;                     // [n][04] Máscara
							iif( cType == "C", 1, iif( cType == "N", 2, 0 )),;                      // [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
							GetSX3Cache( aFields[nX], 'X3_TAMANHO' ),;                             	// [n][06] Tamanho
							GetSX3Cache( aFields[nX], 'X3_DECIMAL' ),;                              // [n][07] Decimal
							aScan( aAlter, {|x| AllTrim(x) == aFields[nX] } ) > 0,;                 // [n][08] Indica se permite a edição
							{|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
							.F.,;                            										// [n][10] Indica se exibe imagem
							Nil,;                            										// [n][11] Code-Block de execução do duplo clique
							"aColPro[oBrwPro:At()]["+cValToChar(nX)+"]",;                    		// [n][12] Variável a ser utilizada na edição (ReadVar)
							{|oBrw| sortCol(oBrw) },;              									// [n][13] Code-Block de execução do clique no header
							.F.,;                            										// [n][14] Indica se a coluna está deletada
							.F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
							aAux,;                             										// [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
							aFields[nX] })                          								// [n][17] Id da coluna
		elseif aFields[nX] == 'QTDBLOQ' 
			aAdd(aColumns, {;
							'Qtd.Bloq.',;                     										// [n][01] Título da coluna
							&("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX) +"] }"),; 				// [n][02] Code-Block de carga dos dados
							"N",;                													// [n][03] Tipo de dados
							"@E 9,999,999",;                     									// [n][04] Máscara
							2,;                      												// [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
							9,;                             										// [n][06] Tamanho
							0,;                              										// [n][07] Decimal
							aScan( aAlter, {|x| AllTrim(x) == aFields[nX] } ) > 0,;                 // [n][08] Indica se permite a edição
							{|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
							.F.,;                            										// [n][10] Indica se exibe imagem
							Nil,;                            										// [n][11] Code-Block de execução do duplo clique
							"aColPro[oBrwPro:At()]["+cValToChar(nX)+"]",;                    		// [n][12] Variável a ser utilizada na edição (ReadVar)
							{|oBrw| sortCol(oBrw) },;            									// [n][13] Code-Block de execução do clique no header
							.F.,;                            										// [n][14] Indica se a coluna está deletada
							.F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
							{},;                             										// [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
							aFields[nX] })                          								// [n][17] Id da coluna
		elseif aFields[nX] == 'NECCOMP'
			aAdd(aColumns, {;
							'Comprar',;                     										// [n][01] Título da coluna
							&("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX) +"] }"),; 				// [n][02] Code-Block de carga dos dados
							"N",;                													// [n][03] Tipo de dados
							"@E 9,999,999",;                     									// [n][04] Máscara
							2,;                      												// [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
							9,;                             										// [n][06] Tamanho
							0,;                              										// [n][07] Decimal
							aScan( aAlter, {|x| AllTrim(x) == aFields[nX] } ) > 0,;                 // [n][08] Indica se permite a edição
							{|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
							.F.,;                            										// [n][10] Indica se exibe imagem
							Nil,;                            										// [n][11] Code-Block de execução do duplo clique
							"aColPro[oBrwPro:At()]["+cValToChar(nX)+"]",;                    		// [n][12] Variável a ser utilizada na edição (ReadVar)
							{|oBrw| sortCol(oBrw) },;           									// [n][13] Code-Block de execução do clique no header
							.F.,;                            										// [n][14] Indica se a coluna está deletada
							.F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
							{},;                             										// [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
							aFields[nX] })                          								// [n][17] Id da coluna
		elseif aFields[nX] == 'PRCNEGOC'
			aAdd(aColumns, {;
							'Prç.Neg.',;                     										// [n][01] Título da coluna
							&("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX) +"] }"),; 				// [n][02] Code-Block de carga dos dados
							"N",;                													// [n][03] Tipo de dados
							"@E 9,999,999.99",;                     								// [n][04] Máscara
							2,;                      												// [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
							11,;                             										// [n][06] Tamanho
							2,;                              										// [n][07] Decimal
							aScan( aAlter, {|x| AllTrim(x) == aFields[nX] } ) > 0,;                 // [n][08] Indica se permite a edição
							{|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
							.F.,;                            										// [n][10] Indica se exibe imagem
							Nil,;                            										// [n][11] Code-Block de execução do duplo clique
							"aColPro[oBrwPro:At()]["+cValToChar(nX)+"]",;                    		// [n][12] Variável a ser utilizada na edição (ReadVar)
							{|oBrw| sortCol(oBrw) },;           									// [n][13] Code-Block de execução do clique no header
							.F.,;                            										// [n][14] Indica se a coluna está deletada
							.F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
							{},;                             										// [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
							aFields[nX] })                          								// [n][17] Id da coluna
		elseif aFields[nX] == "ULTPRECO"
			aAdd(aColumns, {;
							'Ult.Prç.',;                     										// [n][01] Título da coluna
							&("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX) +"] }"),; 				// [n][02] Code-Block de carga dos dados
							"N",;                													// [n][03] Tipo de dados
							"@E 9,999,999.99",;                     								// [n][04] Máscara
							2,;                      												// [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
							11,;                             										// [n][06] Tamanho
							2,;                              										// [n][07] Decimal
							aScan( aAlter, {|x| AllTrim(x) == aFields[nX] } ) > 0,;                 // [n][08] Indica se permite a edição
							{|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
							.F.,;                            										// [n][10] Indica se exibe imagem
							Nil,;                            										// [n][11] Code-Block de execução do duplo clique
							"aColPro[oBrwPro:At()]["+cValToChar(nX)+"]",;                    		// [n][12] Variável a ser utilizada na edição (ReadVar)
							{|oBrw| sortCol(oBrw) },;          										// [n][13] Code-Block de execução do clique no header
							.F.,;                            										// [n][14] Indica se a coluna está deletada
							.F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
							{},;                             										// [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
							aFields[nX] })                          								// [n][17] Id da coluna
		elseif aFields[nX] == 'CONSMED'
			aAdd(aColumns, {;
							'Cons.Med.',;                     										// [n][01] Título da coluna
							&("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX) +"] }"),; 				// [n][02] Code-Block de carga dos dados
							"N",;                													// [n][03] Tipo de dados
							"@E 999.9999",;                     									// [n][04] Máscara
							2,;                      												// [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
							9,;                             										// [n][06] Tamanho
							4,;                              										// [n][07] Decimal
							aScan( aAlter, {|x| AllTrim(x) == aFields[nX] } ) > 0,;                 // [n][08] Indica se permite a edição
							{|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
							.F.,;                            										// [n][10] Indica se exibe imagem
							Nil,;                            										// [n][11] Code-Block de execução do duplo clique
							"aColPro[oBrwPro:At()]["+cValToChar(nX)+"]",;                    		// [n][12] Variável a ser utilizada na edição (ReadVar)
							{|oBrw| sortCol(oBrw) },;            									// [n][13] Code-Block de execução do clique no header
							.F.,;                            										// [n][14] Indica se a coluna está deletada
							.F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
							{},;                             										// [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
							aFields[nX] })                          								// [n][17] Id da coluna

		elseif aFields[nX] == 'DURACAO'
			aAdd(aColumns, {;
							'Duração',;                     										// [n][01] Título da coluna
							&("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX) +"] }"),; 				// [n][02] Code-Block de carga dos dados
							"N",;                													// [n][03] Tipo de dados
							"@E 999",;                     											// [n][04] Máscara
							2,;                      												// [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
							3,;                             										// [n][06] Tamanho
							0,;                              										// [n][07] Decimal
							aScan( aAlter, {|x| AllTrim(x) == aFields[nX] } ) > 0,;                 // [n][08] Indica se permite a edição
							{|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
							.F.,;                            										// [n][10] Indica se exibe imagem
							Nil,;                            										// [n][11] Code-Block de execução do duplo clique
							"aColPro[oBrwPro:At()]["+cValToChar(nX)+"]",;                    		// [n][12] Variável a ser utilizada na edição (ReadVar)
							{|oBrw| sortCol(oBrw) },;          										// [n][13] Code-Block de execução do clique no header
							.F.,;                            										// [n][14] Indica se a coluna está deletada
							.F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
							{},;                             										// [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
							aFields[nX] })                          								// [n][17] Id da coluna
		elseif aFields[nX] == 'DURAPRV'
			aAdd(aColumns, {;
							'Dur.s/L.T.',;                     										// [n][01] Título da coluna
							&("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX) +"] }"),; 				// [n][02] Code-Block de carga dos dados
							"N",;                													// [n][03] Tipo de dados
							"@E 999",;                     											// [n][04] Máscara
							2,;                      												// [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
							3,;                             										// [n][06] Tamanho
							0,;                              										// [n][07] Decimal
							aScan( aAlter, {|x| AllTrim(x) == aFields[nX] } ) > 0,;                 // [n][08] Indica se permite a edição
							{|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
							.F.,;                            										// [n][10] Indica se exibe imagem
							Nil,;                            										// [n][11] Code-Block de execução do duplo clique
							"aColPro[oBrwPro:At()]["+cValToChar(nX)+"]",;                    		// [n][12] Variável a ser utilizada na edição (ReadVar)
							{|oBrw| sortCol(oBrw) },;          										// [n][13] Code-Block de execução do clique no header
							.F.,;                            										// [n][14] Indica se a coluna está deletada
							.F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
							{},;                             										// [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
							aFields[nX] })                          								// [n][17] Id da coluna
		elseif aFields[nX] == 'ESTOQUE'
			aAdd(aColumns, {;
							'Sld.Atual',;                     										// [n][01] Título da coluna
							&("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX) +"] }"),; 				// [n][02] Code-Block de carga dos dados
							"N",;                													// [n][03] Tipo de dados
							AllTrim(GetSX3Cache("B2_QATU", "X3_PICTURE")),;                     	// [n][04] Máscara
							2,;                      												// [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
							GetSX3Cache("B2_QATU", "X3_TAMANHO"),;                             		// [n][06] Tamanho
							GetSX3Cache("B2_QATU", "X3_DECIMAL"),;                         			// [n][07] Decimal
							aScan( aAlter, {|x| AllTrim(x) == aFields[nX] } ) > 0,;                 // [n][08] Indica se permite a edição
							{|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
							.F.,;                            										// [n][10] Indica se exibe imagem
							Nil,;                            										// [n][11] Code-Block de execução do duplo clique
							"aColPro[oBrwPro:At()]["+cValToChar(nX)+"]",;                    		// [n][12] Variável a ser utilizada na edição (ReadVar)
							{|oBrw| sortCol(oBrw) },;         										// [n][13] Code-Block de execução do clique no header
							.F.,;                            										// [n][14] Indica se a coluna está deletada
							.F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
							{},;                             										// [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
							aFields[nX] })                          								// [n][17] Id da coluna
		elseif aFields[nX] == 'EMPENHO'
			aAdd(aColumns, {;
							'Empenho',;                     										// [n][01] Título da coluna
							&("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX) +"] }"),; 				// [n][02] Code-Block de carga dos dados
							"N",;                													// [n][03] Tipo de dados
							AllTrim(GetSX3Cache("B2_RESERVA", "X3_PICTURE")),;                     	// [n][04] Máscara
							2,;                      												// [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
							GetSX3Cache("B2_RESERVA", "X3_TAMANHO"),;                             	// [n][06] Tamanho
							GetSX3Cache("B2_RESERVA", "X3_DECIMAL"),;                         		// [n][07] Decimal
							aScan( aAlter, {|x| AllTrim(x) == aFields[nX] } ) > 0,;                 // [n][08] Indica se permite a edição
							{|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
							.F.,;                            										// [n][10] Indica se exibe imagem
							Nil,;                            										// [n][11] Code-Block de execução do duplo clique
							"aColPro[oBrwPro:At()]["+cValToChar(nX)+"]",;                    		// [n][12] Variável a ser utilizada na edição (ReadVar)
							{|oBrw| sortCol(oBrw) },;            									// [n][13] Code-Block de execução do clique no header
							.F.,;                            										// [n][14] Indica se a coluna está deletada
							.F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
							{},;                             										// [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
							aFields[nX] })                          								// [n][17] Id da coluna
		elseif aFields[nX] == 'QTDCOMP'
			aAdd(aColumns, {;
							'Qt.Compr',;                     										// [n][01] Título da coluna
							&("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX) +"] }"),; 				// [n][02] Code-Block de carga dos dados
							"N",;                													// [n][03] Tipo de dados
							AllTrim(GetSX3Cache("C7_QUANT", "X3_PICTURE")),;                     	// [n][04] Máscara
							2,;                      												// [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
							GetSX3Cache("C7_QUANT", "X3_TAMANHO"),;                             	// [n][06] Tamanho
							GetSX3Cache("C7_QUANT", "X3_DECIMAL"),;                         		// [n][07] Decimal
							aScan( aAlter, {|x| AllTrim(x) == aFields[nX] } ) > 0,;                 // [n][08] Indica se permite a edição
							{|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
							.F.,;                            										// [n][10] Indica se exibe imagem
							Nil,;                            										// [n][11] Code-Block de execução do duplo clique
							"aColPro[oBrwPro:At()]["+cValToChar(nX)+"]",;                    		// [n][12] Variável a ser utilizada na edição (ReadVar)
							{|oBrw| sortCol(oBrw) },;            									// [n][13] Code-Block de execução do clique no header
							.F.,;                            										// [n][14] Indica se a coluna está deletada
							.F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
							{},;                             										// [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
							aFields[nX] })                          								// [n][17] Id da coluna
		Elseif aFields[nX] == 'LEADTIME'
			aAdd(aColumns, {;
							'Ld.Time',;                     										// [n][01] Título da coluna
							&("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX) +"] }"),; 				// [n][02] Code-Block de carga dos dados
							"N",;                													// [n][03] Tipo de dados
							AllTrim(GetSX3Cache("B1_PE", "X3_PICTURE")),;                     		// [n][04] Máscara
							2,;                      												// [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
							GetSX3Cache("B1_PE", "X3_TAMANHO"),;                             		// [n][06] Tamanho
							GetSX3Cache("B1_PE", "X3_DECIMAL"),;                         			// [n][07] Decimal
							aScan( aAlter, {|x| AllTrim(x) == aFields[nX] } ) > 0,;                 // [n][08] Indica se permite a edição
							{|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
							.F.,;                            										// [n][10] Indica se exibe imagem
							Nil,;                            										// [n][11] Code-Block de execução do duplo clique
							"aColPro[oBrwPro:At()]["+cValToChar(nX)+"]",;                    		// [n][12] Variável a ser utilizada na edição (ReadVar)
							{|oBrw| sortCol(oBrw) },;           									// [n][13] Code-Block de execução do clique no header
							.F.,;                            										// [n][14] Indica se a coluna está deletada
							.F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
							{},;                             										// [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
							aFields[nX] })                          								// [n][17] Id da coluna
		elseif aFields[nX] == 'TPLDTIME'
			aAdd(aColumns, {;
							'Tp.Ld.T',;                     										// [n][01] Título da coluna
							&("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX) +"] }"),; 				// [n][02] Code-Block de carga dos dados
							"C",;                													// [n][03] Tipo de dados
							"@x",;                     												// [n][04] Máscara
							0,;                      												// [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
							1,;                             										// [n][06] Tamanho
							0,;                         											// [n][07] Decimal
							aScan( aAlter, {|x| AllTrim(x) == aFields[nX] } ) > 0,;                 // [n][08] Indica se permite a edição
							{|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
							.F.,;                            										// [n][10] Indica se exibe imagem
							Nil,;                            										// [n][11] Code-Block de execução do duplo clique
							"aColPro[oBrwPro:At()]["+cValToChar(nX)+"]",;                    		// [n][12] Variável a ser utilizada na edição (ReadVar)
							{|oBrw| sortCol(oBrw) },;          										// [n][13] Code-Block de execução do clique no header
							.F.,;                            										// [n][14] Indica se a coluna está deletada
							.F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
							{"C=Calculado","F=Fornecedor","P=Produto"},;                            // [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
							aFields[nX] })                          								// [n][17] Id da coluna
		elseif aFields[nX] == 'PREVENT'
			aAdd(aColumns, {;
							'Prev.Entr.',;                     										// [n][01] Título da coluna
							&("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX) +"] }"),; 				// [n][02] Code-Block de carga dos dados
							"D",;                													// [n][03] Tipo de dados
							Nil,;                     												// [n][04] Máscara
							0,;                      												// [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
							8,;                             										// [n][06] Tamanho
							0,;                         											// [n][07] Decimal
							aScan( aAlter, {|x| AllTrim(x) == aFields[nX] } ) > 0,;                 // [n][08] Indica se permite a edição
							{|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
							.F.,;                            										// [n][10] Indica se exibe imagem
							Nil,;                            										// [n][11] Code-Block de execução do duplo clique
							"aColPro[oBrwPro:At()]["+cValToChar(nX)+"]",;                    		// [n][12] Variável a ser utilizada na edição (ReadVar)
							{|oBrw| sortCol(oBrw) },;          										// [n][13] Code-Block de execução do clique no header
							.F.,;                            										// [n][14] Indica se a coluna está deletada
							.F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
							{},; 										                            // [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
							aFields[nX] })                          								// [n][17] Id da coluna
		endif
	next nX
return aColumns

/*/{Protheus.doc} writeWF
Cria automaticamente o arquivo base para dispato de workflow do processo padrão do sistema para envio do pedido ao fornecedor
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/15/2024
@param cFileWF, character, caminho absoluto onde o arquivo .html deve ser gravado
@return logical, lSuccess
/*/
static function writeWF( cFileWF )

	local lSuccess := .F. as logical
	local oFile           as object
	local cFile    := ""  as character
	local cEOL     := chr(13)+chr(10)

	cFile := "<html>" + cEOL
	cFile += "	<head>" + cEOL
	cFile += '		<meta charset="windows-1252">' + cEOL
	cFile += '		<meta charset="UTF-8">'+ cEOL
	cFile += '		<style>' + cEOL
	cFile += '			body{' + cEOL
	cFile += '				width: 			700px;' + cEOL
	cFile += "				font:			normal normal normal 14px 'open sans', sans-serif;"+ cEOL
	cFile += '			}'+ cEOL
			
	cFile += '			h1 {'
	cFile += "				font: 			normal normal normal 22px 'open sans', sans-serif;" + cEOL
	cFIle += '				color: 			rgb(0, 136, 203);' + cEOL
	cFile += '				padding-top: 	3px;'
	cFile += '				padding-bottom:	3px;' + cEOL
	cFile += '			}' + cEOL
			
	cFile += '			h2 {' + cEOL
	cFile += "				font: 			normal normal normal 14px 'open sans', sans-serif;" + cEOL
	cFile += "			}" + cEOL
			
	cFile += '			table{' + cEOL
	cFile += "				font:			normal normal normal 14px 'open sans', sans-serif;"+ cEOL
	cFile += "				text-align: 	left" + cEOL
	cFile += "				border-width: 	0px;"+ cEOL
				
	cFile += '			}'+ cEOL

	cFile += "			thead{"+ cEOL
	cFile += "				font:			normal normal normal 14px 'open sans', sans-serif;"+ cEOL
	cFile += "				background:		Gray;"+ cEOL
	cFile += "				color:			White;"+ cEOL
	cFile += "				text-align: 	left;"+ cEOL
	cFile += "				border-width: 	0px;"+ cEOL
	cFile += "			}"+ cEOL
			
	cFile += "			.grid{"+ cEOL
	cFile += "				border-top: 	solid rgb(0, 136, 203) 2px; "+ cEOL
	cFile += "				padding-top:	10px;"+ cEOL
	cFile += "				padding-bottom:	5px;"+ cEOL
	cFile += "				margin-top:		10px;"+ cEOL
	cFile += "			}"+ cEOL
	cFile += "		</style>"+ cEOL
	cFile += "	</head>"+ cEOL
	
	cFile += "	<body>"+ cEOL
	cFile += '	<div styele="width:700px;font:normal normal normal 14px '+"'open sans'"+', sans-serif;">'+ cEOL
	cFile += '		<h1 style="font:normal normal normal 22px '+"'open sans'"+', sans-serif; color:rgb(0, 136, 203);padding-top: 	3px;padding-bottom:	3px;">'+ cEOL
	cFile += '			Pedido de Compra '+ cEOL
	cFile += '		</h1>'+ cEOL
	cFile += '		<h2 style="font:normal normal normal 14px '+"'open sans'"+', sans-serif;">%cContato%</h2>' + cEOL
	cFile += '		<h2 style="font:normal normal normal 14px '+"'open sans'"+', sans-serif;">O Pedido de Compra n&uacute;mero %cPedCom% acaba de ser %cOpera%.</h2>'+ cEOL
	cFile += '		<h2 style="font:normal normal normal 14px '+"'open sans'"+', sans-serif;">Solicitamos que os itens discriminados abaixo sejam %cMsgMail%.<h2>'+ cEOL
	
	cFile += '		<!-- Cabeçalho do Pedido --> '+ cEOL
	cFile += '		<div class="grid" style="border-top:solid rgb(0, 136, 203) 2px; padding-top:10px;padding-bottom:5px;margin-top:10px;">'+ cEOL
	cFile += '			<table style="width:450px;font:normal normal normal 14px '+"'open sans'"+', sans-serif;text-align:leftborder-width:0px;">'+ cEOL
	cFile += '				<tr>'+ cEOL
	cFile += '					<td>Pedido de Compra</td> '+ cEOL
	cFile += '					<td>%cPedCom%</td>'+ cEOL
	cFile += '				</tr>'+ cEOL
	cFile += '				<tr>'+ cEOL
	cFile += '					<td>Fornecedor/Loja</td> '+ cEOL
	cFile += '					<td>%cFornLoja%</td>'+ cEOL
	cFile += '				</tr>'+ cEOL
	cFile += '				<tr>'+ cEOL
	cFile += '					<td>Cliente</td> '+ cEOL
	cFile += '					<td>%cCliente%</td>'+ cEOL
	cFile += '				</tr>'+ cEOL
	cFile += "			</table>"+ cEOL
	cFile += '		</div>'+ cEOL
		
	cFile += '		<!-- Itens do Pedido -->'+ cEOL
	cFile += '		<div class="grid" style="border-top:solid rgb(0, 136, 203) 2px; padding-top:10px;padding-bottom:5px;margin-top:10px;">'+ cEOL
	cFile += '			<table style="width:450px;font:normal normal normal 14px '+"'open sans'"+', sans-serif;text-align:leftborder-width:0px;">'+ cEOL
	cFile += '				<thead style="font:normal normal normal 14px '+"'open sans'"+', sans-serif;background:Gray;color:White;text-align:left;border-width:0px;">'+ cEOL
	cFile += '					<tr>'+ cEOL
	cFile += '						<td style="width:150px;">Item</td>'+ cEOL
	cFile += '						<td style="width:150px;">Produto</td>'+ cEOL
	cFile += '						<td style="width:400px;">Descri&ccedil;&atilde;o</td>'+ cEOL
	cFile += '						<td style="width:150px;">UM</td>'+ cEOL
	cFile += '						<td style="width:150px;">Quantidade</td>'+ cEOL
	cFile += '						<td style="width:150px;">Vl. Unit</td>'+ cEOL
	cFile += '						<td style="width:150px;">Total</td>'+ cEOL
	cFile += '						<td style="width:150px;">Dt. Entrega</td>'+ cEOL
	cFile += '					</tr>'+ cEOL
	cFile += '				</thead>'+ cEOL
	cFile += '				<tbody>'+ cEOL
	cFile += '					<tr>'+ cEOL
	cFile += '						<td style="width:150px;">%It.cItem%</td>'+ cEOL
	cFile += '						<td style="width:150px;">%It.cCod%</td>'+ cEOL
	cFile += '						<td style="width:400px;">%It.cDesc%</td>'+ cEOL
	cFile += '						<td style="width:150px;">%It.cUM%</td>'+ cEOL
	cFile += '						<td style="width:150px;">%It.nQuant%</td>'+ cEOL
	cFile += '						<td style="width:150px;">%It.nVlUnit%</td>'+ cEOL
	cFile += '						<td style="width:150px;">%It.nTotal%</td>'+ cEOL
	cFile += '						<td style="width:150px;">%It.dDtEntrega%</td>'+ cEOL
	cFile += '					</tr>'+ cEOL
	cFile += '				</tbody>'+ cEOL
	cFile += '			</table>'+ cEOL
	cFile += "		</div>"+ cEOL
	cFile += '	</div>'+ cEOL
	cFile += '	</body>'+ cEOL
	cFile += "</html>"+ cEOL

	// Grava o arquivo no diretório esperado
	oFile := FWFileWriter():New( cFileWF, .F. )
	if oFile:Create()
		oFile:Write( cFile )
		oFile:Close()
	endif

	lSuccess := File( cFileWF )
return lSuccess

/*/{Protheus.doc} closeVld
Função de validação para fechamento da tela do Painel de Compras.
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/22/2024
@return logical, lClose
/*/
static function closeVld()
	local lClose := .T. as logical
	lCLose := len( aCarCom ) == 0
	if ! lClose
		lClose := MsgYesNo( 'Seu carrinho não está vazio, se optar por sair, terá de adicioná-los novamente, deseja prosseguir?', 'A T E N Ç Ã O !' )
	endif
return lClose

/*/{Protheus.doc} procCar
Função responsável pela realização do processamento dos carrinhos de compra pendentes
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/22/2024
/*/
static function procCar()
	
	local aArea   := FORTMP->( GetArea() )
	local aForLoj := {} as array
	local nX      := 0  as numeric
	
	if len( aCarCom ) > 0
		for nX := 1 to len( aCarCom )
			if aScan( aForLoj, {|x| x[1] + x[2] == aCarCom[nX][13] + aCarCom[nX][14] } ) == 0
				aAdd( aForLoj, { aCarCom[nX][13], aCarCom[nX][14] } )
			endif
		next nX
	endif

	if len( aForLoj ) > 0
		for nX := 1 to len( aForLoj )
			fCarCom( aForLoj[nX][1], aForLoj[nX][2] )
		next nX
	endif

	restArea( aArea )
return Nil

/*/{Protheus.doc} sortCol
Função para ordenar grid conforme coluna que for clicada
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/22/2024
@param oBrw, object, Objeto do Browse
/*/
static function sortCol( oBrw )
	local nCol := oBrw:ColPos()-2
	if nLastCol == nCol
		lCrescente := ! lCrescente
	else
		lCrescente := .T.
	endif
	nLastCol := nCol
	aSort( aColPro,,, {|x,y| &('x[nCol] '+ iif( lCrescente, '>','<' ) +' y[nCol]') } )
	oBrw:UpdateBrowse()
return Nil

/*/{Protheus.doc} PCOMPRE
Função de pré-validação para edição de colunas do browse
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/24/2024
@param oBrw, object, objeto do browse
@param oCol, object, objeto da coluna clicada
@param cPre, character, character onde o click foi realizado
@return logical, lCanEdit
/*/
user function PCOMPRE(oBrw, oCol, cPre)
	
	local lCanEdit := .T. as logical
	local oQtdFil         as objet
	local nAux     := 0 as numeric
	local bOk      := {|| _aProdFil[ aScan( _aProdFil, {|x| x[25]+x[3] == aProFil[oProFil:At()][25]+aProFil[oProFil:At()][3] } ) ] := aProFil[oProFil:At()],;
						  nAux := 0, aEval( _aProdFil, {|x| iif( x[3] == cProduto, nAux+= x[6], nil ) } ),;
						  aColPro[aScan(aColPro, {|x| x[nPosPrd] == cProduto })][nPosNec] := nAux,;
						  updCarCom( cProduto, nAux ),;
						  oBrwPro:UpdateBrowse(),;
						  oQtdFil:End() }

	local bCancel  :={|| oQtdFil:End() }
	local aButtons := {}  as array
	local bValid   :={|| .T. }
	local bInit    :={|| EnchoiceBar( oQtdFil, bOk, bCancel,,aButtons )}
	local aColumns := {} as array
	local bVldCell := {|| .T. }
	local cProduto := aColPro[oBrwPro:At()][nPosPrd]

	Private aProFil  := {} as array
	Private oProFil  as object

	if (oBrw:ColPos()-2) == nPosNec

		// Cria subvetor editável apenas com o produto selecionado
		aEval( _aProdFil, {|x| iif( x[3] == cProduto, aAdd( aProFil, aClone(x) ), Nil ) } )
		
		// aAdd( _aProdFil,{ nIndGir,;
		// aScan( aCarCom, {|x| x[1] == PRDTMP->B1_COD .and. x[13] == cFornece .and. x[14] == cLoja } ) > 0,;
		// PRDTMP->B1_COD,;
		// PRDTMP->B1_DESC,;
		// PRDTMP->B1_UM,;
		// nQtdCom /*Necessidade de compra*/,;
		// PRDTMP->QTDBLOQ /*Ped. Compra Bloq.*/,;
		// nPrice /*Preço negociado*/,;
		// nPrice /*Ultimo Preço*/,; 
		// PRDTMP->( FieldGet( FieldPos( cZB3 +'_CONMED' ) ) ) /*Consumo Medio*/,;
		// nPrjEst /*Duracao Estimada*/,;
		// nDurPrv /*Duracao Prev.*/,;
		// PRDTMP->ESTOQUE /*Em Estoque*/,;
		// PRDTMP->EMPENHO /*Empenho*/,; 
		// PRDTMP->QTDCOMP /*Quantidade já Comprada*/,;
		// nLeadTime /*Lead Time Médio do Produto*/,;
		// cLeadTime /*Tipo Lead-Time*/,;
		// StoD( PRDTMP->PRVENT ) /*Prev. Entrega*/,;
		// PRDTMP->B1_LM /*Lote Mínimo*/,;
		// PRDTMP->B1_QE /*Quantidade da Embalagem*/,;
		// PRDTMP->B1_LE /*Lote Econômico*/,;
		// PRDTMP->B1_EMIN /* Estoque Minimo (Estoque Segurança) */,;
		// cFornece /*Fornecedor*/,;
		// cLoja /*Loja do Fornecedor*/,;
		// PRDTMP->FILIAL /* Filial */ } )

		aAdd( aColumns, FWBrwColumn():New() )
		aColumns[len(aColumns)]:SetTitle( 'Filial' )
		aColumns[len(aColumns)]:SetData( &( "{|oBrw| aProFil[oBrw:At()][25] }" ) )
		aColumns[len(aColumns)]:SetType( 'C' )
		aColumns[len(aColumns)]:SetAlign( 1 )		// Alinha a Esquerda
		aColumns[len(aColumns)]:SetSize( TAMSX3( 'C7_FILIAL' )[1] )
		aColumns[len(aColumns)]:SetPicture( "@!" )

		aAdd( aColumns, FWBrwColumn():New() )
		aColumns[len(aColumns)]:SetTitle( 'Qtde' )
		aColumns[len(aColumns)]:SetData( &( "{|oBrw| aProFil[oBrw:At()][6] }" ) )
		aColumns[len(aColumns)]:SetType( 'N' )
		aColumns[len(aColumns)]:SetAlign( 2 )		// Alinha a Direita
		aColumns[len(aColumns)]:SetSize( TAMSX3( 'C7_QUANT' )[1] )
		aColumns[len(aColumns)]:SetDecimal( TAMSX3( 'C7_QUANT' )[2] )
		aColumns[len(aColumns)]:SetPicture( PesqPict( 'SC7', 'C7_QUANT' ) )

		aAdd( aColumns, FWBrwColumn():New() )
		aColumns[len(aColumns)]:SetTitle( 'Cons.Medio' )
		aColumns[len(aColumns)]:SetData( &( "{|oBrw| aProFil[oBrw:At()][10] }" ) )
		aColumns[len(aColumns)]:SetType( 'N' )
		aColumns[len(aColumns)]:SetAlign( 2 )		// Alinha a Direita
		aColumns[len(aColumns)]:SetSize( TAMSX3( cZB3 +'_CONMED' )[1] )
		aColumns[len(aColumns)]:SetDecimal( TAMSX3( cZB3 +'_CONMED' )[2] )
		aColumns[len(aColumns)]:SetPicture( PesqPict( cZB3, cZB3 +'_CONMED' ) )

		aAdd( aColumns, FWBrwColumn():New() )
		aColumns[len(aColumns)]:SetTitle( 'Em Estoque' )
		aColumns[len(aColumns)]:SetData( &( "{|oBrw| aProFil[oBrw:At()][13] }" ) )
		aColumns[len(aColumns)]:SetType( 'N' )
		aColumns[len(aColumns)]:SetAlign( 2 )		// Alinha a Direita
		aColumns[len(aColumns)]:SetSize( 11 )
		aColumns[len(aColumns)]:SetDecimal( 2 )
		aColumns[len(aColumns)]:SetPicture( "@E 999,999.99" )

		aAdd( aColumns, FWBrwColumn():New() )
		aColumns[len(aColumns)]:SetTitle( 'Empenhado' )
		aColumns[len(aColumns)]:SetData( &( "{|oBrw| aProFil[oBrw:At()][14] }" ) )
		aColumns[len(aColumns)]:SetType( 'N' )
		aColumns[len(aColumns)]:SetAlign( 2 )		// Alinha a Direita
		aColumns[len(aColumns)]:SetSize( 11 )
		aColumns[len(aColumns)]:SetDecimal( 2 )
		aColumns[len(aColumns)]:SetPicture( "@E 999,999.99" )

		aAdd( aColumns, FWBrwColumn():New() )
		aColumns[len(aColumns)]:SetTitle( 'Comprado' )
		aColumns[len(aColumns)]:SetData( &( "{|oBrw| aProFil[oBrw:At()][15] }" ) )
		aColumns[len(aColumns)]:SetType( 'N' )
		aColumns[len(aColumns)]:SetAlign( 2 )		// Alinha a Direita
		aColumns[len(aColumns)]:SetSize( 11 )
		aColumns[len(aColumns)]:SetDecimal( 2 )
		aColumns[len(aColumns)]:SetPicture( "@E 999,999.99" )

		oQtdFil := TDialog():New(0,0,500,800,'Quantidades x Filial',,,,,CLR_BLACK,CLR_WHITE,,,.T.)
		
		oProFil := FWBrowse():New( oQtdFil )
		oProFil:SetDataArray()
		oProFil:SetArray( aProFil )
		oProFil:DisableConfig()
		oProFil:DisableReport()
		oProFil:SetColumns( aColumns )
		oProFil:SetLineHeight( 20 )
		oProFil:SetEditCell( .T., bVldCell )
		oProFil:GetColumn(2):SetReadVar( "aProFil[oProFil:At()][6]" )
		oProFil:GetColumn(2):lEdit := .T.
		oProFil:Activate()	

		oQtdFil:Activate(,,,.T., bValid,,bInit)
		lCanEdit := .F.
	elseif (oBrw:ColPos()-2) == nPosBlq .and. a
		lCanEdit := .F.
	endif

return lCanEdit

/*/{Protheus.doc} updCarCom
Função para atualizar quantidade no carrinho de compra
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/25/2024
@param cProduto, character, Codigo do produto
@param nAux, numeric, Quantidade
/*/
static function updCarCom( cProduto, nAux )
	
	// Valida se o produto já está no carrinho
	if aScan( aCarCom, {|x| x[01] == cProduto } ) > 0
		aCarCom[ aScan( aCarCom, {|x| x[01] == cProduto } ) ][ 04 ] := nAux
		aCarCom[ aScan( aCarCom, {|x| x[01] == cProduto } ) ][ 06 ] := nAux * aColPro[oBrwPro:nAt][nPosNeg]
	endif

return Nil
