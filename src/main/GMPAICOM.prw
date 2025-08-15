#include 'totvs.ch'
#include 'topconn.ch'
#include 'hbutton.ch'
#include 'rwmake.ch'
#include 'tbiconn.ch'
#include 'tbicode.ch'
#include 'fwmvcdef.ch'

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
#define LBL_TOP	   .T.							// Posição do label de topo
#define LBL_LEFT   .F.							// Seta posição da label à esquerda do get
 
/*/{Protheus.doc} GMPAICOM
Rotina para gestão de compras, elaboração inteligente de pedidos e acompanhamento de carteira de fornecedores
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 7/9/2019
/*/
User Function GMPAICOM()
                       
	Local oCboAna as object
	local oCboFil as object
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
	local aFields  := {"B1_COD","B1_DESC","B1_UM","NECCOMP","QTDBLOQ","PRCNEGOC","ULTPRECO","CONSMED","DURACAO","DURAPRV","ESTOQUE","EMPENHO","QTDSOL","QTDCOMP","LEADTIME","TPLDTIME","PREVENT","B1_LM","B1_QE","B1_LE","B1_EMIN","A5_FORNECE","A5_LOJA"} 
	Local aAlter   := {"NECCOMP","QTDBLOQ","PRCNEGOC","B1_LM", "B1_QE", "B1_LE", "A5_FORNECE", "B1_UM", "LEADTIME", "B1_DESC", "B1_EMIN" }
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
	local oPerfil  as object
	local oDescPer as object
	local aRadMenu := { "Todos os produtos", "Apenas sugestões de compra", "Apenas risco de ruptura" }
	local cLastRun := "" as character
	local oLine    as object
	local cFileWF  := "" as character
	local aAuxHea  := doHeadCar()
	local oAliSol   as object
	
	Private aHeaSol   := {} as array
	Private _nQtBlq   := 0 as numeric
	Private aHeaCar   := aClone( aAuxHea[1] )		// Header do grid do carrinho de compras
	Private aAltCar   := aClone( aAuxHea[2] )		// Campos editáveis do carrinho de compras
	Private aCarFil   := {} as array
	Private aCboFil   := getCboFil()
	Private _cFilPrd  := "" as character
	Private _aTypes   := {} as array
	Private nRadMenu  := 1 as numeric 
	Private cZB6      := AllTrim( SuperGetMv( 'MV_X_PNC04',,"" ) )			// Alias da tabela ZB6 no ambiente do cliente
	Private cZB3      := AllTrim( SuperGetMv( 'MV_X_PNC02',,"" ) )			// Alias da tabela ZB3 no ambiente do cliente
	Private cZBM      := AllTrim( SuperGetMv( 'MV_X_PNC16',,'' ) )			// Alias da tabela ZBM no ambiente do cliente
	Private cPerfil   := "" as character
	Private cDescPer  := "" as character
	Private cMarca    := GetMark()
	Private oLblDia   := Nil
	Private nGetQtd   := 0
	Private cCboAna   := '1' 
	Private cCboFil   := 'YY'
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
	Private nPosEMi   := 0 as numeric
	Private nPosDur   := 0 
	Private nPosEmE   := 0 
	Private nPosVen   := 0 
	Private nPosSol   := 0 as numeric
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
	Private cFdGroup  := AllTrim( SuperGetMv( 'MV_X_PNC13' ) )
	Private _aFilters := { Space(200),;
						   Space(200),; 
						   Space(TAMSX3('A2_COD')[1]),;
						   Space(TAMSX3(cFdGroup)[1]),;
						   Space(TAMSX3('B1_COD')[1]),;
						   Space(TAMSX3('A2_LOJA')[1]),;
						   .F. /* lCancel */ }

	Private lCrescente := .T. as logical
	Private nLastCol   := 0 as numeric 
	Private aMrkFor    := {} as array
	Private aFullPro   := {} as array
	Private _cPedSol   := "" as character

	// Atualiza variável que indica se a conexão com supabase está ativa
	lSupabase := U_JSGLBPAR( .T. /* lCheck */ )
	if ! lSupabase
		Return Nil
	endif

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

	// Checa existencia do parâmetro e da configuração do alias da tabelas de perfis de cálculo
	if ! GetMv( 'MV_X_PNC16', .T. ) .or. Empty( cZBM )
		Hlp( 'MV_X_PNC16',;
			'Parâmetro interno que define alias da tabela de perfis de cálculo não existe ou não foi configurado corretamente',;
			'Verifique com a equipe responsável pela rotina, solicite atualização para a versão mais recente e tente novamente.' )
		Return Nil
	elseif FindFunction( 'U_JSPERCHK' )
		// Função que checa existência de conteúdo na tabela e, se está vazia, cria um registro genérico com a fórmula padrão de cálculo de compras
		// definida através do parâmetro MV_X_PNC01
		if !U_JSPERCHK()
			Return Nil 
		endif
	else
		Hlp( 'MV_X_PNC16',;
			'Função de manutenção dos perfis de cálculo não localizada neste ambiente',;
			'Solicite à equipe responsável a atualização desta rotina e tente novamente.' )
		Return Nil
	endif

	// Inicializa com o perfil de cálculo default da rotina
	cPerfil  := StrZero( 1, TAMSX3( cZBM +'_ID' )[1] )
	cDescPer := RetField( cZBM, 1, FWxFilial( cZBM ) + cPerfil, cZBM +'_DESC' )

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
	SetKey( VK_F4, {|| Processa( {|| supplyerChoice( /* lForce */ ) }, 'Aguarde!','Analisando dados do MRP...' ) } )
	SetKey( VK_F5, {|| Processa( {|| fLoadInf() }, 'Aguarde!','Analisando dados do MRP...' ) } )
	SetKey( VK_F12, {|| fManPar(), fLoadCfg() } )
	
	aStrFor := {}
	aAdd( aStrFor, { "MARK"      , "C", 02, 00 } )
	aAdd( aStrFor, { "A2_COD"    , "C", TAMSX3( "A2_COD"     )[01], TAMSX3( "A2_COD"     )[02] } )
	aAdd( aStrFor, { "A2_LOJA"   , "C", TAMSX3( "A2_LOJA"    )[01], TAMSX3( "A2_LOJA"    )[02] } )
	aAdd( aStrFor, { "A2_NOME"   , "C", TAMSX3( "A2_NOME"    )[01], TAMSX3( "A2_NOME"    )[02] } )
	aAdd( aStrFor, { "A2_NREDUZ" , "C", TAMSX3( "A2_NREDUZ"  )[01], TAMSX3( "A2_NREDUZ"  )[02] } )
	aAdd( aStrFor, { "A2_EMAIL"  , "C", TAMSX3( "A2_EMAIL"   )[01], TAMSX3( "A2_EMAIL"   )[02] } )
	aAdd( aStrFor, { "LEADTIME"  , "N", 03, 00 } )
	aAdd( aStrFor, { "A2_X_LTIME", "N", 03, 00 } )
	aAdd( aStrFor, { "PEDIDO"    , "C", 01, 00 } )
	
	oAliFor := FWTemporaryTable():New( 'FORTMP', aStrFor )
	oAliFor:AddIndex( '01', {'A2_NOME'})
	oAliFor:AddIndex( '02', {'A2_COD','A2_LOJA' } )
	oAliFor:Create()
	
	// Cabeçalho do grid que vai exibir os dados
	aCabFor := {}
	aAdd( aCabFor, { ' '           , &("{|| iif( Trim(FORTMP->PEDIDO) == 'S','"+ CCARCOM +"','"+ CWHITE+ "') }"), "C", "@BMP", 1, 1, 0, .F., {|| Nil }, .T. } )
	aAdd( aCabFor, { 'Razão Social', {|| Trim( FORTMP->A2_NOME    ) }, 'C', '@!', 1, 20, 00 } )
	aAdd( aCabFor, { 'Fantasia'    , {|| Trim( FORTMP->A2_NREDUZ  ) }, 'C', '@!', 1, 10, 00 } )
	aAdd( aCabFor, { 'L.T.(C)'     , {|| FORTMP->LEADTIME           }, 'N', '@E 999', 2, 03, 00 } )
	aAdd( aCabFor, { 'L.T.(I)'     , {|| RetField('SA2',1,FWxFilial("SA2") + FORTMP->A2_COD + FORTMP->A2_LOJA, "A2_X_LTIME" )},;
		 'N', '@E 999', 2, 03, 00, .T. /* lCanEdit */, {|| A2LTMCHG() }, Nil, Nil, 'FORTMP->A2_X_LTIME' } )

	// Cria o alias temporário das solicitações
	oAliSol := doAliSol()

	aHeaPro := getColPro( aFields, aAlter )							
	// Guarda o posicionamento dos campos para posteriormente utilizá-los ao longo do fonte
	nPosPrd := aScan( aHeaPro, {|x| AllTrim(x[17]) == "B1_COD"     } )+2 
	nPosDes := aScan( aHeaPro, {|x| AllTrim(x[17]) == "B1_DESC"    } )+2
	nPosUnM := aScan( aHeaPro, {|x| AllTrim(x[17]) == "B1_UM"      } )+2
	nPosLtM := aScan( aHeaPro, {|x| AllTrim(x[17]) == "B1_LM"      } )+2
	nPosFor := aScan( aHeaPro, {|x| AllTrim(x[17]) == "A5_FORNECE" } )+2
	nPosLoj := aScan( aHeaPro, {|x| AllTrim(x[17]) == "A5_LOJA"    } )+2
	nPosNec := aScan( aHeaPro, {|x| AllTrim(x[17]) == "NECCOMP"    } )+2
	nPosNeg := aScan( aHeaPro, {|x| AllTrim(x[17]) == "PRCNEGOC"   } )+2
	nPosUlt := aScan( aHeaPro, {|x| AllTrim(x[17]) == "ULTPRECO"   } )+2
	nPosCon := aScan( aHeaPro, {|x| AllTrim(x[17]) == "CONSMED"    } )+2
	nPosDur := aScan( aHeaPro, {|x| AllTrim(x[17]) == "DURACAO"    } )+2
	nPosDuP := aScan( aHeaPro, {|x| AllTrim(x[17]) == "DURAPRV"    } )+2
	nPosEmE := aScan( aHeaPro, {|x| AllTrim(x[17]) == "ESTOQUE"    } )+2
	nPosVen := aScan( aHeaPro, {|x| AllTrim(x[17]) == "EMPENHO"    } )+2
	nPosSol := aScan( aHeaPro, {|x| AllTrim(x[17]) == "QTDSOL"     } )+2
	nPosQtd := aScan( aHeaPro, {|x| AllTrim(x[17]) == "QTDCOMP"    } )+2
	nPosPrv := aScan( aHeaPro, {|x| AllTrim(x[17]) == "PREVENT"    } )+2
	nPosLdT := aScan( aHeaPro, {|x| AllTrim(x[17]) == "LEADTIME"   } )+2
	nPosTLT := aScan( aHeaPro, {|x| AllTrim(x[17]) == "TPLDTIME"   } )+2		// Tipo do Lead-Time (C=Calculado P=Produto ou F=Fornecedor)
	nPosBlq := aScan( aHeaPro, {|x| AllTrim(x[17]) == "QTDBLOQ"    } )+2
	nPosQtE := aScan( aHeaPro, {|x| AllTrim(x[17]) == "B1_QE"      } )+2
	nPosLtE := aScan( aHeaPro, {|x| AllTrim(x[17]) == "B1_LE"      } )+2
	nPosEMi := aScan( aHeaPro, {|x| AllTrim(x[17]) == "B1_EMIN"    } )+2
	nPosInc := 1
	nPosChk := 2
	
	// Realiza leitura das preferências da rotina
	Processa( {|| fLoadCfg() }, 'Aguarde!','Lendo configurações da rotina...' )
	if Len( aConfig ) == 0 
		MsgStop( 'Não foi possível prosseguir porque as configurações internas da rotina não puderam ser lidas ou ainda não foram cadastradas!','Parâmetro interno MV_X_PNC03' )
		Return ( Nil )
	EndIf

	// Filtros de tipos de produtos "padrões" definidos nas configurações
	_aFilters[2] := PADR(aConfig[21],200,' ')		// pré-definições dos tipos de produtos a serem analisados
	cLastRun     := AllTrim( SuperGetMv( 'MV_X_PNC12',,"" ) )
	
	if _cPedSol == '3'		// Usuário escolhe
		_cPedSol := cValToChar( Aviso( 'Tipo de Documento',;
									'Devido a necessidade de estruturas de tela diferentes para a gravação de solicitações de compras e pedidos de compras, antes de iniciarmos, '+;
									'preciso que defina qual é o tipo de documento que gostaria de gerar na finalização do carrinho.',;
									{ 'Pedido de Compra', 'Solicitação' }, 3 ) )
	endif

	// Botões da EnchoiceBar
	// aAdd( aButtons, { "BTNWARN"  , {|| fShowEv() }           , "Riscos de Ruptura" } )
	// aAdd( aButtons, { "BTNNOTIFY", {|| fShowEv( aColPro[ oBrwPro:nAt][nPosPrd] ) }, "Eventos do Produto" } )
	aAdd( aButtons, { "BMPMANUT" , {|| iif( !Empty(U_JSDoFrml( cPerfil )),;
										Processa( {|| fLoadInf() }, 'Aguarde!','Analisando dados do MRP...' ), Nil ) }, "Formula de Cálculo" } ) 
	aAdd( aButtons, { "BTNEMPEN" , {|| iif( len( aColPro ) > 0, fShowEm( aColPro[ oBrwPro:nAt][nPosPrd] ), Nil ) }, "Empenhos do Produto" } )
	aAdd( aButtons, { "BTNPEDIDO", {|| iif( len( aColPro ) > 0, fSolPend(), Nil ) }, "Solicitações de Compra" } )
	aAdd( aButtons, { "BTNPEDIDO", {|| iif( len( aColPro ) > 0, fPedFor(), Nil ) }, "Pedidos em Aberto" } )
	aAdd( aButtons, { "BTNENTR"  , {|| iif( len( aColPro ) > 0, entryDocs( aColPro[ oBrwPro:nAt ][nPosPrd] ), Nil ) }, "Entradas" } )
	aAdd( aButtons, { "BTNSAIDA" , {|| iif( len( aColPro ) > 0, outPuts( aColPro[ oBrwPro:nAt ][nPosPrd] ), Nil ) }, "Saídas" } )
	aAdd( aButtons, { "BTNPAICFG", {|| fManPar(), fLoadCfg() }, "Parâmetros Internos (F12)" } )
	aAdd( aButtons, { "BTNCONFIG", {|| oBrwPro:Config() }, "Configurar Janela de Produtos" } )
	aAdd( aButtons, { "BTNFILIAL", {|| _aFil := userFil( _aFil ),;
									Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' ) }, "Selecionar Filiais" } )
	aAdd( aButtons, { "BTNFILTRO", {|| _aFilters := prodFilter( _aFilters ),;
									Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' ) }, "Filtro" } )
	aAdd( aButtons, { "BTNPRINT" , {|| iif( len( aColPro ) > 0, printBrw( oBrwPro ), Nil ) }, 'Exportar dados de produtos' } )
	aAdd( aButtons, { "BTNPRDFOR", {|| impPrdFor() }, 'Importar Vínculo Produto x Fornecedor' } )
	aAdd( aButtons, { "BTNIMPORT", {|| cLastRun := AllTrim(impData( cLastRun )) }, "Importar Indices dos Produtos" } )
	aAdd( aButtons, { "BTNPROD"  , {|| iif( len( aColPro ) > 0, manutProd( aColPro[oBrwPro:nAt][nPosPrd] ), Nil ) }, 'Manutenção do Produto' } )
	aAdd( aButtons, { "BTNPRMRP" , {|| iif( len( aColPro ) > 0, mrpRemove( aColPro[oBrwPro:nAt][nPosPrd] ), Nil ) }, 'Remover do MRP' } )

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
			 'pode gerar falhas no processo de análise de compras e, consequentsemente, rupturas indesejadas de estoque.' )
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
	oLayer:AddWindow( 'colPro' , 'winPro' , 'Produtos', 100, .F., .F., {|| Nil }, "line2")
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
	oBrwFor:GetColumn(2):bLDblClick := {|oBrwFor| iif( FORTMP->PEDIDO == 'S', fCarCom( FORTMP->A2_COD, FORTMP->A2_LOJA ), Nil ) }
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
	oBrwPro:GetColumn(nPosFor):xF3 := "SA2"
	oBrwPro:SetEditCell( .T., {|| U_PCOMVLD() } )
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

	@ 30, 20 CHECKBOX oGir001 VAR lGir001 PROMPT "Críticos"     		SIZE 048, 008 OF oWinPar COLORS 8421504, 16777215 FONT oFntCbo ON CHANGE Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' ) PIXEL
	@ 40, 20 CHECKBOX oGir002 VAR lGir002 PROMPT "Alto Giro"    		SIZE 048, 008 OF oWinPar COLORS 8421504, 16777215 FONT oFntCbo ON CHANGE Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' ) PIXEL
	@ 50, 20 CHECKBOX oGir003 VAR lGir003 PROMPT "Médio Giro"   		SIZE 048, 008 OF oWinPar COLORS 8421504, 16777215 FONT oFntCbo ON CHANGE Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' ) PIXEL
	@ 60, 20 CHECKBOX oGir004 VAR lGir004 PROMPT "Baixo Giro"   		SIZE 048, 008 OF oWinPar COLORS 8421504, 16777215 FONT oFntCbo ON CHANGE Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' ) PIXEL
	@ 70, 20 CHECKBOX oGir005 VAR lGir005 PROMPT "Sem Giro"     		SIZE 048, 008 OF oWinPar COLORS 8421504, 16777215 FONT oFntCbo ON CHANGE Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' ) PIXEL
	
	oRadMenu := TRadMenu():New( 30, 70, aRadMenu,, oWinPar,,,,,,,,100,12,,,,.T.)
	oRadMenu:bSetGet := {|u| iif( pCount()==0, nRadMenu, nRadMenu := u ) }
	oRadMenu:bChange := {|| Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' ) }

	oPerfil := TGet():New( 65, 70,{|u| If(pCount()>0,cPerfil:=u,cPerfil ) },oWinPar,030,012,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'cPerfil',,,,.T.,.F.,,'Perfil Calc.', 1 )
	oPerfil:cF3 := cZBM
	oPerfil:bValid := {|| !Empty( cPerfil ) .and. ExistCpo( cZBM, cPerfil ) }
	oPerfil:bChange := {|| cDescPer := RetField( cZBM, 1, FWxFilial( cZBM ) + cPerfil, cZBM +'_DESC' ),; 
						   Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' ) }

	oDescPer := TGet():New( 65, 110,{|u| If(pCount()>0,cDescPer:=u,cDescPer ) },oWinPar,070,012,"@x",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'cDescPer',,,,.T.,.F.,,'Descrição', 1  )
	oDescPer:bWhen := {|| .F. }

	@ 06, 04 SAY oLblPer PROMPT "Período: " SIZE (oWinDash:nWidth/2)*0.1, 011 OF oWinDash FONT oFntTxt COLORS 8421504, 16777215 PIXEL
	@ 04, 06+(oWinDash:nWidth/2)*0.1 MSCOMBOBOX oCboAna VAR cCboAna ITEMS aCboAna SIZE (oWinDash:nWidth/2)*0.3, 013 OF oWinDash COLORS 8421504, 16777215 FONT oFntCbo ON CHANGE Processa( {|| fLoadAna() }, 'Aguarde!', 'Analisando sazonalidade do produto...' ) PIXEL
	@ 04, 08+((oWinDash:nWidth/2)*0.4) MSGET oGetQtd VAR nGetQtd SIZE (oWinDash:nWidth/2)*0.1, 010 OF oWinDash PICTURE "@E 99" COLORS 8421504, 16777215 FONT oFntCbo ON CHANGE Processa( {|| fLoadAna() }, 'Aguarde!','Analisando sazonalidade do produto...' ) PIXEL
	@ 06, 10+((oWinDash:nWidth/2)*0.5) SAY oLblAna PROMPT "..." SIZE (oWinDash:nWidth/2)*0.2, 011 OF oWinDash FONT oFntTxt COLORS 8421504, 16777215 PIXEL
	@ 04, 06+(oWinDash:nWidth/2)*0.6 MSCOMBOBOX oCboFil VAR cCboFil ITEMS aCboFil SIZE (oWinDash:nWidth/2)*0.3, 013 OF oWinDash COLORS 8421504, 16777215 FONT oFntCbo ON CHANGE Processa( {|| fLoadAna() }, 'Aguarde!', 'Analisando sazonalidade do produto...' ) PIXEL

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
														
	oAliFor:Delete()
	oAliSol:Delete()	// Apaga alias temporário de solicitações
	
Return ( Nil )

/*/{Protheus.doc} JSENTRDC
Função para permitir a chamada da função a partir de fontes externos desenvolvidos pelo próprio cliente
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 1/13/2025
@param cDoc, character, ID do documento de entrada
@param cSerie, character, Serie do documento de entrada
@param cFornece, character, ID do fornecedor
@param cLoja, character, Loja do fornecedor
@param cTipo, character, Tipo do documento de entrada
/*/
User Function JSENTRDC( cDoc, cSerie, cFornece, cLoja, cTipo )
return entryDocs( Nil, cDoc, cSerie, cFornece, cLoja, cTipo )

/*/{Protheus.doc} entryDocs
Função para exibir os documentos de entrada relacionados ao produto
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 16/08/2024
@param cProduto, character, ID do produto
@param cDoc, character, ID do documento de entrada
@param cSerie, character, Serie do documento de entrada
@param cFornece, character, ID do fornecedor
@param cLoja, character, loja do fornecedor
@param cTipo, character, Tipo do documento de entrada
/*/
static function entryDocs( cProduto, cDoc, cSerie, cFornece, cLoja, cTipo )
	
	local aArea    := getArea()
	local cQuery   := "" as character
	local aButtons := {} as array
	local lSuccess := .T. as logical
	local bOk      :={|| iif( lDocEntr, lSuccess := checkDoc( oBrowse, SD1TMP->D1_FILIAL, cDoc, cSerie, cFornece, cLoja, cTipo ), Nil), iif( lSuccess, oDlgDoc:End(), Nil )}
	local bCancel  :={|| oDlgDoc:End()}
	local aFields  := { "D1_FILIAL", "D1_DOC", "D1_SERIE", "D1_ITEM", "D1_LOCAL","D1_FORNECE", "D1_LOJA", "D1_QUANT", "D1_VUNIT", "D1_TOTAL", "D1_VALIPI", "D1_VALICM",;
						"D1_TES", "D1_COD", "B1_DESC", "D1_UM", "D1_CF", "D1_DESC", "D1_IPI", "D1_PICM", "D1_EMISSAO", "D1_DTDIGIT", "D1_BASEICM", "D1_VALDESC",;
						"D1_BASEIPI", "D1_CUSTO", "D1_BASIMP5", "D1_BASIMP6", "D1_VALIMP5", "D1_VALIMP6", "D1_ALQIMP5", "D1_ALQIMP6", "D1_VALFRE",;
						"D1_ICMSDIF", "D1_ALQCSL", "D1_VOPDIF", "A2_NOME", "A2_EST", "D1_DESPESA", "D1_ALIQSOL", "D1_ICMSRET", "D1_MARGEM" }
	local bValid   :={|| .T. }
	local bInit    :={|| EnchoiceBar( oDlgDoc, bOk, bCancel,,aButtons )} 
	local oPanDoc        as object
	local oPanPed		 as object
	local oPanFld1       as object
	local oPanFld2		 as object
	local oPanFld3		 as object
	local aColumns := {} as array
	local aFldCol  := {} as array
	local nX       := 0  as numeric
	local lEnable  := .T. as logical
	local cAlias   := "SD1TMP" as character
	local oTmp     as object
	
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
	local oBtnIgn  as object
	local oBtnLuc  as object
	local oBtnDOp  as object
	local oBtnICV  as object
	local oBtnCSL  as object
	local oBtnIRP  as object
	local oBtnIna  as object
	local oBtnFin  as object
	local nEmpr    := 0 as numeric
	local cDB      := TCGetDB()
	local cFilHist := cFilAnt
	local cMasters := AllTrim( SuperGetMv( 'MV_X_PNC15',, '000000' ) )
	local lDocEntr := .F. as logical
	local aOptions := {} as array
	local aStruct  := {} as array
	local cType    := "" as character
	local cSerCFI  := PADR(AllTrim( SuperGetMv( 'MV_X_PNC17',,'' ) ),TAMSX3('D1_SERIE')[1], ' ' )		// Série para notas de complemento de frete interno
	local oSize    as object
	local oSize1   as object

	// Cabeçalho
	Private oGetCod  as object
	Private oGetDes  as object
	Private oGetUM   as object
	Private oGetNCM  as object
	Private oGetUOC  as object
	Private oGetTab  as object
	Private oGetUNF  as object

	// Entrada
	Private oGetTES  as object
	Private oGetDTE  as object
	Private oGetICM  as object
	Private oValICM  as object
	Private oGetIPI  as object
	Private oValIPI  as object
	Private oGetFre  as object
	Private oValFre  as object
	Private oGetICF  as object
	Private oValICF  as object
	Private oGetOut  as object
	Private oValOut  as object
	Private oGetFin  as object
	Private oValFin  as object
	Private oGetPC   as object
	Private oValPC   as object
	Private oGetST   as object
	Private oValST   as object
	Private oGetMVA  as object
	Private oGetCuL  as object
	Private oGetCuM  as object
	Private oGrpCom  as object

	// Saída
	Private oGetLuc  as object		// Lucro pretendido
	Private oGetPCV  as object		// PIS/COFINS Venda
	Private oGetICV  as object		// ICMS Venda
	Private oGetOpe  as object		// Percentual custo operacional
	Private oGetCSL  as object		// Percentual CSLL
	Private oGetIRP  as object		// Percentual IRPJ
	Private oGetIna  as object		// Índice Inadimplência
	Private oGetTCV  as object		// Total custo variável
	Private oGetFiV  as object		// Custo financeiro (desconto conforme forma de pagamento)
	Private oGetIPS  as object		// IPI de saída
	Private oGetPSL  as object		// Preço sem lucro
	Private oGetSug  as object		// Sugestão preço de venda
	Private oGetPrc  as object		// Preço de venda
	Private oGetMg1  as object		// Margem do preço sugerido
	Private oGetScI  as object		// Preço sugerido + IPI
	Private oGetMg2  as object		// Margem sobre o preço vigente
	Private oGetPCI  as object		// Preço final com IPI

	// Dados do produto
	Private cGetCod := "" as character
	Private cGetDes := "" as character
	Private cGetUM  := "" as character
	Private nGetUOC := 0 as numeric
	Private cGetNCM := "" as character
	Private cGetTab := PADR(SuperGetMV( 'MV_TABPAD',,Space(TAMSX3('DA1_CODTAB')[1]) ), TAMSX3('DA0_CODTAB')[1], ' ')
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
	Private nGetLuc := GetMV( 'MV_X_PNC05',,0 )
	Private nGetPCV := GetMV( 'MV_TXPIS'  ,,0 ) + GetMV( 'MV_TXCOFIN',,0 ) 										// PIS/COFINS Venda
	Private nGetICV := iif( GetMv( 'MV_X_PNC18', .T. ), GetMV( 'MV_X_PNC18' ), GetMV( 'MV_ICMPAD' ) ) 			// ICMS Venda (formação de preços)
	Private nGetOpe := GetMV( 'MV_X_PNC06',,0 )																	// Despesas Operacionais Venda
	Private nGetCSL := GetMV( 'MV_X_PNC07',,0 )																	// CSLL
	Private nGetIRP := GetMV( 'MV_X_PNC08',,0 )																	// IRPJ
	Private nGetIna := GetMV( 'MV_X_PNC09',,0 )																	// Índice Inadimplência
	Private nGetTCV := 0																						// Total Custo Variável
	Private nGetFiV := GetMV( 'MV_X_PNC10',,0 )																	// Custo Financeiro (custo cartão, desconto à vista...)
	Private nGetPSL := 0			// Preço sem lucro
	Private nGetSug := 0			// Sugestão Preço de Venda
	Private nGetMg1 := 0 			// Margem sobre o preço sugerido
	Private nGetScI := 0 as numeric	// Preço Sugerido + IPI
	Private nGetPrc := 0			// Preço de Venda Atual
	private nGetMg2 := 0			// Margem sobre o preço vigente
	private nGetPCI := 0 			// Preço final + IPI
	Private nGetIPS := 0 			// IPI de saída
	
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

	default cProduto := ""
	default cDoc     := ""
	default cSerie   := ""
	default cFornece := ""
	default cLoja    := ""
	default cTipo    := ""

	// Valida o tipo de documento que o usuário clicou para abrir a rotina de formação de preços
	if ! Empty( cTipo ) .and. ! cTipo == 'N'
		Hlp( 'TIPODOC',;
			 'O tipo do documento não permite abertura da tela de formação de preços',;
			 'Apenas notas do tipo NORMAL são consideradas pela rotina de formação de preços. Selecione outro documento e tente novamente' )
		return Nil
	endif
	lDocEntr := ! Empty( cDoc ) .and. ! Empty( cSerie ) .and. ! Empty( cFornece ) .and. ! Empty( cLoja )

	// Tratativa para que, quando chamada da função for a partir de outras rotinas, trata a filial _aFil para evitar error-log devido a variável não existente.
	if ! Type( '_aFil' ) == 'A'
		_aFil := { cFilAnt }
	endif
	
	// Quando  produto não for informado no filtro, exibe os produtos no browse
	if Empty( cProduto )
		aFldCol := { "D1_FILIAL", "D1_ITEM", "D1_COD","B1_DESC", "D1_EMISSAO", "D1_DTDIGIT", "D1_DOC", "D1_SERIE", "D1_FORNECE", "D1_LOJA", "A2_NOME", "A2_EST", "D1_QUANT",; 
						"D1_VUNIT", "D1_TOTAL", "D1_VALDESC", "F1_X_FPRC" }
	else
		cGetCod := cProduto
		cGetDes := RetField( 'SB1', 1, FWxFilial( 'SB1' ) + cProduto, 'B1_DESC' )
		cGetUM  := RetField( 'SB1', 1, FWxFilial( 'SB1' ) + cProduto, 'B1_UM' )
		cGetNCM := RetField( 'SB1', 1, FWxFilial( 'SB1' ) + cProduto, 'B1_POSIPI' )
		nGetLuc := getLucro( cProduto, SuperGetMV( 'MV_X_PNC05',,0 ) )
		nGetIPS := RetField( 'SB1', 1, FWxFilial( 'SB1' ) + cProduto, 'B1_IPI' )
		aFldCol := { "D1_FILIAL", "D1_EMISSAO", "D1_DTDIGIT", "D1_DOC", "D1_SERIE", "D1_ITEM", "D1_FORNECE", "D1_LOJA", "A2_NOME", "A2_EST", "D1_QUANT",; 
						"D1_VUNIT", "D1_TOTAL", "D1_VALDESC", "F1_X_FPRC"  }
	endif

	if len( _aFil ) > 0
		cQuery := "SELECT TEMP.* FROM ( "+ CEOL
		for nEmpr := 1 to len( _aFil )
			
			cFilAnt := _aFil[nEmpr]
			// Query para análise 
			cQuery += "SELECT " + CEOL
			// Adiciona todos os campos do vetor na query
			aEval( aFields, {|x| cQuery += x +', ',;
								 aAdd( aStruct, { x, GetSX3Cache( x, 'X3_TIPO' ), GetSX3Cache( x, 'X3_TAMANHO' ), GetSX3Cache( x, 'X3_DECIMAL' ) } ) } )
			cQuery += "D1.R_E_C_N_O_ RECSD1, " + CEOL
			aAdd( aStruct, { 'RECSD1', 'N', 9, 0 } )
			if SF1->( FieldPos( 'F1_X_FPRC' ) ) > 0
				cQuery += " CASE WHEN F1.F1_X_FPRC = 'S' THEN 'S' ELSE 'N' END AS F1_X_FPRC, " + CEOL
			else
				cQuery += " 'N' AS F1_X_FPRC, " + CEOL
			endif
			aAdd( aStruct, { 'F1_X_FPRC', 'C', 1, 0 } )
			
			cQuery += "COALESCE(" + CEOL

			// Soma valores de notas de complemento
			cQuery += "( SELECT SUM( COMP.D1_TOTAL ) FROM "+ RetSqlName( 'SD1' ) +" COMP " + CEOL
			cQuery += "  INNER JOIN "+ RetSqlName( 'SF1' ) +" F1 " + CEOL
			cQuery += "   ON F1.F1_FILIAL  = '"+ FWxFilial( 'SF1' ) +"' " + CEOL
			cQuery += "  AND F1.F1_DOC     = COMP.D1_DOC " + CEOL
			cQuery += "  AND F1.F1_SERIE   = COMP.D1_SERIE " + CEOL
			cQuery += "  AND F1.F1_FORNECE = COMP.D1_FORNECE " + CEOL
			cQuery += "  AND F1.F1_LOJA    = COMP.D1_LOJA " + CEOL
			cQuery += "  AND F1.F1_TPCOMPL = '1' " + CEOL		// Complemento de Preço
			cQuery += "  AND F1.D_E_L_E_T_ = ' ' " + CEOL
			cQuery += "  WHERE COMP.D1_FILIAL  = '"+ FWxFilial( 'SD1' ) +"' " + CEOL
			cQuery += "    AND COMP.D1_NFORI   = D1.D1_DOC " + CEOL
			cQuery += "    AND COMP.D1_SERIORI = D1.D1_SERIE " + CEOL
			cQuery += "    AND COMP.D1_ITEMORI = D1.D1_ITEM " + CEOL
			cQuery += "    AND COMP.D1_FORNECE = D1.D1_FORNECE " + CEOL
			cQuery += "    AND COMP.D1_LOJA    = D1.D1_LOJA " + CEOL
			cQuery += "    AND COMP.D1_TIPO    = 'C' " + CEOL
			cQuery += "    AND COMP.D_E_L_E_T_ = ' ' " + CEOL
			cQuery += " ),0) " +CEOL
			cQuery += " + " + CEOL
			cQuery += "COALESCE(" + CEOL
			cQuery += "(SELECT SUM(D1FRT.D1_TOTAL) D1_TOTAL "+ CEOL
			cQuery += "FROM "+ RetSqlName( 'SF8' ) +" F8 " + CEOL
			cQuery += "INNER JOIN "+ RetSqlName( 'SD1' ) +" D1FRT "+ CEOL
			cQuery += " ON D1FRT.D1_FILIAL  = '"+ FWxFilial( 'SD1' ) +"' " + CEOL
			cQuery += "AND D1FRT.D1_DOC     = F8.F8_NFDIFRE " +CEOL
			cQuery += "AND D1FRT.D1_SERIE   = F8.F8_SEDIFRE "+ CEOL
			cQuery += "AND D1FRT.D1_ITEM    = D1.D1_ITEM " + CEOL
			cQuery += "AND D1FRT.D1_COD     = D1.D1_COD "+ CEOL
			cQuery += "AND D1FRT.D1_FORNECE = F8.F8_TRANSP "+ CEOL
			cQuery += "AND D1FRT.D1_LOJA    = F8.F8_LOJTRAN "+ CEOL
			cQuery += "AND D1FRT.D_E_L_E_T_ = ' ' "+ CEOL
			cQuery += "WHERE F8.F8_FILIAL  = '"+ FWxFilial( 'SF8' ) +"' " +CEOL
			cQuery += "  AND F8.F8_NFORIG  = D1.D1_DOC " + CEOL
			cQuery += "  AND F8.F8_SERORIG = D1.D1_SERIE "+ CEOL
			cQuery += "  AND F8.F8_SEDIFRE = '"+ cSerCFI +"' " +CEOL
			cQuery += "  AND F8.D_E_L_E_T_ = ' ' ) " + CEOL
			cQuery += ",0) AS VALFIN, " + CEOL
			
			aAdd( aStruct, { 'VALFIN', 'N', 12, 2 } )

			cQuery += "COALESCE(" + CEOL
			cQuery += "(SELECT SUM(D1FRT.D1_TOTAL) D1_TOTAL "+ CEOL
			cQuery += "FROM "+ RetSqlName( 'SF8' ) +" F8 " + CEOL
			cQuery += "INNER JOIN "+ RetSqlName( 'SD1' ) +" D1FRT "+ CEOL
			cQuery += " ON D1FRT.D1_FILIAL  = '"+ FWxFilial( 'SD1' ) +"' " + CEOL
			cQuery += "AND D1FRT.D1_DOC     = F8.F8_NFDIFRE " +CEOL
			cQuery += "AND D1FRT.D1_SERIE   = F8.F8_SEDIFRE "+ CEOL
			cQuery += "AND D1FRT.D1_ITEM    = D1.D1_ITEM " + CEOL
			cQuery += "AND D1FRT.D1_COD     = D1.D1_COD "+ CEOL
			cQuery += "AND D1FRT.D1_FORNECE = F8.F8_TRANSP "+ CEOL
			cQuery += "AND D1FRT.D1_LOJA    = F8.F8_LOJTRAN "+ CEOL
			cQuery += "AND D1FRT.D_E_L_E_T_ = ' ' "+ CEOL
			cQuery += "WHERE F8.F8_FILIAL  = '"+ FWxFilial( 'SF8' ) +"' " +CEOL
			cQuery += "  AND F8.F8_NFORIG  = D1.D1_DOC " + CEOL
			cQuery += "  AND F8.F8_SERORIG = D1.D1_SERIE "+ CEOL
			cQuery += "  AND F8.F8_SEDIFRE <> '"+ cSerCFI +"' " +CEOL
			cQuery += "  AND F8.D_E_L_E_T_ = ' ') " + CEOL
			cQuery += ",0) AS VALFRT "+ CEOL
			
			aAdd( aStruct, { 'VALFRT', 'N', 12, 2 } )

			cQuery += "FROM "+ RetSqlName( 'SD1' ) +" D1 " + CEOL
			
			// Faz Join com tabela de fornecedor
			cQuery += "INNER JOIN "+ RetSqlName( 'SA2' ) +" A2 " + CEOL
			cQuery += " ON A2.A2_FILIAL  = '"+ FWxFIlial( 'SA2' ) +"' "+ CEOL
			cQuery += "AND A2.A2_COD     = D1.D1_FORNECE " + CEOL
			cQuery += "AND A2.A2_LOJA    = D1.D1_LOJA " + CEOL
			cQuery += "AND A2.D_E_L_E_T_ = ' ' " + CEOL

			cQuery += "INNER JOIN "+ RetSqlName( 'SF1' ) +" F1 " +CEOL
			cQuery += " ON F1.F1_FILIAL  = '"+ FWxFilial( 'SF1' ) +"' " + CEOL
			cQuery += "AND F1.F1_DOC     = D1.D1_DOC " + CEOL
			cQuery += "AND F1.F1_SERIE   = D1.D1_SERIE "+ CEOL
			cQuery += "AND F1.F1_FORNECE = D1.D1_FORNECE "+ CEOL
			cQuery += "AND F1.F1_LOJA    = D1.D1_LOJA "+ CEOL
			cQuery += "AND F1.F1_TIPO    = D1.D1_TIPO " + CEOL
			cQuery += "AND F1.D_E_L_E_T_ = ' ' " + CEOL

			cQuery += "INNER JOIN "+ RetSqlName( 'SB1' ) +" B1 " + CEOL
			cQuery += " ON B1.B1_FILIAL  = '"+ FWxFilial( 'SB1' ) +"' " + CEOL
			cQuery += "AND B1.B1_COD     = D1.D1_COD " + CEOL
			cQuery += "AND B1.D_E_L_E_T_ = ' ' " + CEOL

			cQuery += "WHERE D1.D1_FILIAL  = '"+ FWxFilial( 'SD1' ) +"' "+ CEOL
			if ! Empty( cProduto )
				cQuery += "  AND D1.D1_COD     = '"+ cProduto +"' " + CEOL
			endif
			if ! Empty( cDoc )
				cQuery += "  AND D1.D1_DOC     = '"+ cDoc +"'  " + CEOL
			endif
			if ! Empty( cSerie )
				cQuery += "  AND D1.D1_SERIE   = '"+ cSerie +"' " + CEOL
			endif
			if ! Empty(  cFornece )
				cQuery += "  AND D1.D1_FORNECE = '"+ cFornece +"' " + CEOL
			endif
			if ! Empty( cLoja )
				cQuery += "  AND D1.D1_LOJA    = '"+ cLoja +"' " + CEOL
			endif
			if ! Empty( cTipo )
				cQuery += "  AND D1.D1_TIPO    = '"+ cTipo +"' " + CEOL		// Apenas notas do tipo Normal
			else
				cQuery += "  AND D1.D1_TIPO    = 'N' " + CEOL
			endif
			cQuery += "  AND D1.D1_TES     <> '"+ Space( TAMSX3('D1_TES')[1] ) +"' " + CEOL	// Apenas notas já classificadas
			cQuery += "  AND D1.D_E_L_E_T_ = ' ' " + CEOL
			
			if nEmpr < len( _aFil )
				cQuery += " UNION ALL " + CEOL
			endif
		next nEmpr
		
		// Muda o formato de encerramento da query conforme banco utilizado
		if AllTrim(cDB) $ "ORACLE|SQLSERVER" 
			cQuery += ") TEMP " + CEOL
		else
			cQuery += ") AS TEMP " + CEOL
		endif

		// Se o produto vier vazio, é porque está visualizando o documento de entrada inteiro
		if Empty( cProduto )
			cQuery += "ORDER BY TEMP.D1_ITEM, TEMP.D1_COD, TEMP.B1_DESC " + CEOL
		else
			cQuery += "ORDER BY TEMP.D1_EMISSAO DESC, TEMP.RECSD1 DESC " + CEOL
		endif
	endif
	cFilAnt := cFilHist		
	
	// Define as colunas do browse
	for nX := 1 to len( aFldCol )
		cType := GetSX3Cache( aFldCol[nX], 'X3_TIPO' )
		aAdd( aColumns, FWBrwColumn():New() )
		aColumns[len(aColumns)]:SetTitle( GetSX3Cache( aFldCol[nX], 'X3_TITULO' ) )
		aColumns[len(aColumns)]:SetType( cType )
		aColumns[len(aColumns)]:SetSize( GetSX3Cache( aFldCol[nX], 'X3_TAMANHO' ) )
		aColumns[len(aColumns)]:SetDecimal( GetSX3Cache( aFldCol[nX], 'X3_DECIMAL' ) )
		aColumns[len(aColumns)]:SetData(&( getStrData( aFldCol[nX] ) ))
		aColumns[len(aColumns)]:SetAlign( getAlign( GetSX3Cache( aFldCol[nX], 'X3_TIPO' ) ) )
		aColumns[len(aColumns)]:SetPicture( GetSX3Cache( aFldCol[nX], 'X3_PICTURE' ) )
		// Quando existir combo configurado no dicionário de dados, atribui opções do combo às configurações
		if !Empty( GetSX3Cache( aFldCol[nX], 'X3_CBOX' ) )
			aOptions := StrTokArr(AllTrim(GetSX3Cache( aFldCol[nX], 'X3_CBOX' )),';')
			aColumns[len(aColumns)]:SetOptions( aOptions )
		endif
		aColumns[len(aColumns)]:SetReadVar( "SD1TMP->"+aFldCol[nX] )
		aColumns[len(aColumns)]:SetID( aFldCol[nX] )

	next nX

	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( 'Compl.Fin.' )
	aColumns[len(aColumns)]:SetType( 'N' )
	aColumns[len(aColumns)]:SetSize( 13 )
	aColumns[len(aColumns)]:SetDecimal( 2 )
	aColumns[len(aColumns)]:SetData( {|| SD1TMP->VALFIN } )
	aColumns[len(aColumns)]:SetAlign( getAlign( 'N' ) )
	aColumns[len(aColumns)]:SetPicture( "@E 9,999,999.99" )
	aColumns[len(aColumns)]:SetReadVar( "SD1TMP->VALFIN" )
	aColumns[len(aColumns)]:SetID( "VALFIN" )

	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( 'Vlr. Frete' )
	aColumns[len(aColumns)]:SetType( 'N' )
	aColumns[len(aColumns)]:SetSize( 13 )
	aColumns[len(aColumns)]:SetDecimal( 2 )
	aColumns[len(aColumns)]:SetData( {|| SD1TMP->VALFRT } )
	aColumns[len(aColumns)]:SetAlign( getAlign( 'N' ) )
	aColumns[len(aColumns)]:SetPicture( "@E 9,999,999.99" )
	aColumns[len(aColumns)]:SetReadVar( "SD1TMP->VALFRT" )
	aColumns[len(aColumns)]:SetID( "VALFRT" )

	oTmp := FWTemporaryTable():New( cAlias )
	oTmp:SetFields( aStruct )
	oTmp:Create()

	// ConOut(cQuery)
	SQLToTrb( cQuery, aStruct, cAlias )
	DBSelectArea( cAlias )

	// Cálculo de dimensões e objetos
	oSize := FWDefSize():New( .T. /* lEnchoiceBar */, .T., 1000 )
	oSize:AddObject( 'DOC', 100, 30, .T., .T. )
	oSize:AddObject( 'CAB', 100, 40, .T., .F. )
	oSize:AddObject( 'CALC', 100, 200, .T., .F. )
	oSize:lProp := .T.
	oSize:Process()

	// Tamanho dos campos de cálculo
	oSize1 := FWDefSize():New( .F. /* lEnchoiceBar */, .T. /* lFixo */, oSize:GetDimension( 'CALC', 'YSIZE' ) )
	oSize1:lLateral := .T.
	oSize1:AddObject( 'CALC1', 20, 100, .T., .T. )
	oSize1:AddObject( 'CALC2', 50, 100, .T., .T. )
	oSize1:AddObject( 'CALC3', 30, 100, .T., .T. )
	oSize1:lProp := .T.
	oSize1:Process()

	// Documentos de entrada ligados ao produto atual
	oDlgDoc := TDialog():New( oSize:aWindSize[1], oSize:aWindSize[2], oSize:aWindSize[3], oSize:aWindSize[4],'Documentos de Entrada para o Produto',,,,,CLR_BLACK,CLR_WHITE,,,.T.)

	oPanDoc := TGroup():New( oSize:GetDimension( 'DOC', "LININI" ),;
								oSize:GetDimension( 'DOC', "COLINI" ),;
								oSize:GetDimension( 'DOC', "LINEND" ),;
								oSize:GetDimension( 'DOC', "COLEND" ), /* cTitle */,oDlgDoc,,,.T.)

	oPanPed := TGroup():New( oSize:GetDimension( 'CAB', "LININI" ),;
								oSize:GetDimension( 'CAB', "COLINI" ),;
								oSize:GetDimension( 'CAB', "LINEND" ),;
								oSize:GetDimension( 'CAB', "COLEND" ), '  Produto  '/* cTitle */,oDlgDoc,,,.T.)

	oPanFld1 := TGroup():New( oSize:GetDimension( 'CALC', "LININI" ),;
								oSize1:GetDimension( 'CALC1', "COLINI" ),;
								oSize:GetDimension( 'CALC', "LINEND" ),;
								oSize1:GetDimension( 'CALC1', "COLEND" ), '  Entrada  '/* cTitle */,oDlgDoc,,,.T.)

	oPanFld2 := TGroup():New( oSize:GetDimension( 'CALC', "LININI" ),;
								oSize1:GetDimension( 'CALC2', "COLINI" ),;
								oSize:GetDimension( 'CALC', "LINEND" ),;
								oSize1:GetDimension( 'CALC2', "COLEND" ), '  Formacão de Preço  '/* cTitle */,oDlgDoc,,,.T.)

	oPanFld3 := TGroup():New( oSize:GetDimension( 'CALC', "LININI" ),;
								oSize1:GetDimension( 'CALC3', "COLINI" ),;
								oSize:GetDimension( 'CALC', "LINEND" ),;
								oSize1:GetDimension( 'CALC3', "COLEND" ), '  Última Entrada  '/* cTitle */,oDlgDoc,,,.T.)

	oBrowse := FWBrowse():New( oPanDoc )
	oBrowse:SetDataTable()
	oBrowse:SetAlias( cAlias )
	oBrowse:DisableReport()
	oBrowse:DisableConfig()
	oBrowse:SetLineHeight( 20 )
	oBrowse:AddLegend( "SD1TMP->F1_X_FPRC == 'S'", 'BR_VERDE', 'Item revisado' )
	oBrowse:AddLegend( "! SD1TMP->F1_X_FPRC == 'S'", 'BR_VERMELHO', 'Item não revisado' )
	oBrowse:SetColumns( aColumns )
	oBrowse:bChange := {|| someChange( .T. /* lReset */), oDlgDoc:Refresh(), iif( ValType(oGetUOC) == 'O', oGetUOC:SetFocus(), Nil ), oBrowse:SetFocus() }
	oBrowse:SetEditCell( .T., {|| .T. } )
	oBrowse:GetColumn( aScan( aFldCol, {|x| AllTrim(x) == 'F1_X_FPRC' } ) +1 ):SetEdit(.T.)
	oBrowse:GetColumn( aScan( aFldCol, {|x| AllTrim(x) == 'F1_X_FPRC' } ) +1 ):SetReadVar( "SD1TMP->F1_X_FPRC" )
	oBrowse:Activate()

	// Group dados do produto
	nLine   := oSize:GetDimension( 'CAB', "LININI" ) + 10
	oGetCod   := doGet( nLine, 004, {|u| if( pCount()>0,cGetCod:=u,cGetCod ) }, oPanPed, 60, 10, "@x", 'cGetCod', 'Cod.Prod.', !lEnable, LBL_TOP )
	oGetCod:cF3 := GetSX3Cache( 'D1_COD', 'X3_F3' )
	oGetDes   := doGet( nLine, 074, {|u| if( pCount()>0,cGetDes:=u,cGetDes ) }, oPanPed, 140, 10, "@x", 'cGetDes', 'Descrição', !lEnable, LBL_TOP )
	oGetUM    := doGet( nLine, 224, {|u| if( pCount()>0,cGetUM:=u,cGetUM   ) }, oPanPed, 30, 10, "@x", 'cGetUM', 'Un.Med.', !lEnable, LBL_TOP )
	oGetNCM   := doGet( nLine, 264, {|u| if( pCount()>0,cGetNCM:=u,cGetNCM ) }, oPanPed, 60, 10, PesqPict('SB1','B1_POSIPI'), 'cGetNCM', 'NCM', !lEnable, LBL_TOP )
	oGetNCM:cF3 := GetSX3Cache( 'B1_POSIPI', 'X3_F3' )	
	oGetUOC   := doGet( nLine, 334, {|u| if( pCount()>0,nGetUOC:=u,nGetUOC ) }, oPanPed, 70, 10, "@E 9,999,999.99", 'nGetUOC', 'Prc.Compra', lEnable, LBL_TOP )
	oGetTab   := doGet( nLine, 414, {|u| if( pCount()>0,cGetTab:=u,cGetTab ) }, oPanPed, 40, 10, "@!", 'cGetTab', 'Tab.Preço', , LBL_TOP )
	oGetTab:cF3 := GetSX3Cache( 'C5_TABELA', 'X3_F3' )
	oGetUNF   := doGet( nLine, 464, {|u| if( pCount()>0,nGetUNF:=u,nGetUNF ) }, oPanPed, 70, 10, "@E 9,999,999.99", 'nGetUNF', 'Valor', !lEnable, LBL_TOP )

	// Entrada
	nLine := oSize:GetDimension( 'CALC', "LININI" ) + 10
	oGetTES   := doGet( nLine, 004, {|u| if( PCount()>0,cGetTES:=u,cGetTES ) }, oPanFld1, 40, 10, "@!", 'cGetTES', 'TES', !lEnable )
	oGetTES:cF3 := "SF4"	// Pesquisa padrão cadastro de TES
	oGetDTE   := doGet( nLine, 095, {|u| if( PCount()>0,cGetDTE:=u,cGetDTE ) }, oPanFld1, 70, 10, "@x", 'cGetDTE',, !lEnable )
	nLine += 14
	oGetICM   := doGet( nLine, 004, {|u| if( PCount()>0,nGetICM:=u,nGetICM ) }, oPanFld1, 40, 10, "@R 9,999.99 %", 'nGetICM', 'ICMS', lEnable )
	oGetICM:bChange := {|| nValICM := (nGetICM/100)*nGetUOC, someChange() }
	oValICM   := doGet( nLine, 095, {|u| if( PCOunt()>0,nValICM:=u,nValICM ) }, oPanFld1, 40, 10, "@E 9,999,999.99", 'nValICM',, !lEnable,,CLR_RED )
	nLine += 14
	oGetIPI   := doGet( nLine, 004, {|u| if( pCOunt()>0,nGetIPI:=u,nGetIPI ) }, oPanFld1, 40, 10, "@R 9,999.99 %", 'nGetIPI', 'IPI', lEnable )
	oGetIPI:bChange := {|| nValIPI := (nGetIPI/100)*nGetUOC, someChange() }
	oValIPI   := doGet( nLine, 095, {|u| if( PCount()>0,nValIPI:=u,nValIPI ) }, oPanFld1, 40, 10, "@E 9,999,999.99", 'nValIPI',, !lEnable )
	nLine += 14
	oGetFre   := doGet( nLine, 004, {|u| if( pCOunt()>0,nGetFre:=u,nGetFre ) }, oPanFld1, 40, 10, "@R 9,999.99 %", 'nGetFre', 'Frete', lEnable )
	oGetFre:bChange := {|| nValFre := (nGetFre/100)*nGetUOC, someChange() }
	oValFre   := doGet( nLine, 095, {|u| if( PCount()>0,nValFre:=u,nValFre ) }, oPanFld1, 40, 10, "@E 9,999,999.99", 'nValFre',,!lEnable )
	nLine += 14
	oGetICF   := doGet( nLine, 004, {|u| if( pCOunt()>0,nGetICF:=u,nGetICF ) }, oPanFld1, 40, 10, "@R 9,999.99 %", 'nGetICF', 'ICMS Frete', lEnable )
	oGetICF:bChange := {|| nValICF := (nGetICF/100)*nValFre, someChange() }
	oValICF   := doGet( nLine, 095, {|u| if( PCount()>0,nValICF:=u,nValICF ) }, oPanFld1, 40, 10, "@E 9,999,999.99", 'nValICF',,!lEnable,,CLR_RED )
	nLine += 14
	oGetOut   := doGet( nLine, 004, {|u| if( pCOunt()>0,nGetOut:=u,nGetOut ) }, oPanFld1, 40, 10, "@R 9,999.99 %", 'nGetOut', 'Outras Desp.',lEnable )
	oGetOut:bChange := {|| nValOut := (nGetOut/100)*nGetUOC, someChange() }
	oValOut   := doGet( nLine, 095, {|u| if( PCount()>0,nValOut:=u,nValOut ) }, oPanFld1, 40, 10, "@E 9,999,999.99", 'nValOut',,!lEnable )
	nLine += 14
	oGetFin   := doGet( nLine, 004, {|u| if( pCOunt()>0,nGetFin:=u,nGetFin ) }, oPanFld1, 40, 10, "@R 9,999.99 %", 'nGetFin', 'Financeiro', lEnable )
	oGetFin:bChange := {|| nValFin := (nGetFin/100)*nGetUOC, someChange() }
	oValFin   := doGet( nLine, 095, {|u| if( PCount()>0,nValFin:=u,nValFin ) }, oPanFld1, 40, 10, "@E 9,999,999.99", 'nValFin',,lEnable )
	oValFin:bChange := {|| nGetFin := (nValFin/nGetUOC)*100, someChange() }
	nLine += 14
	oGetPC    := doGet( nLine, 004, {|u| if( pCOunt()>0,nGetPC :=u,nGetPC  ) }, oPanFld1, 40, 10, "@R 9,999.99 %", 'nGetPC', 'PIS/COFINS', lEnable )
	oGetPC:bChange := {|| nValPC := (nGetPC/100)*nGetUOC, someChange() }
	oValPC    := doGet( nLine, 095, {|u| if( PCount()>0,nValPC :=u,nValPC  ) }, oPanFld1, 40, 10, "@E 9,999,999.99", 'nValPC',, !lEnable,,CLR_RED )
	nLine += 14
	oGetST    := doGet( nLine, 004, {|u| if( pCOunt()>0,nGetST :=u,nGetST  ) }, oPanFld1, 40, 10, "@R 9,999.99 %", 'nGetST', 'ST', lEnable )
	oGetST:bChange := {|| nValST := (nGetST/100)*nGetUOC, someChange() }
	oValST    := doGet( nLine, 095, {|u| if( PCount()>0,nValST :=u,nValST  ) }, oPanFld1, 40, 10, "@E 9,999,999.99", 'nValST',, !lEnable )
	nLine += 14
	oGetMVA   := doGet( nLine, 004, {|u| if( pCOunt()>0,nGetMVA:=u,nGetMVA ) }, oPanFld1, 40, 10, "@R 9,999.99 %", 'nGetMVA', 'MVA', !lEnable )
	nLine += 14
	oGetCuL   := doGet( nLine, 004, {|u| if( pCOunt()>0,nGetCuL:=u,nGetCuL ) }, oPanFld1, 40, 10, "@E 9,999,999.9999", 'nGetCuL', 'Custo Líq.', !lEnable )
	nLine += 14
	oGetCuM   := doGet( nLine, 004, {|u| if( pCOunt()>0,nGetCuM:=u,nGetCuM ) }, oPanFld1, 40, 10, "@E 9,999,999.9999", 'nGetCuM', 'Custo Médio', !lEnable )
	
	// Saída
	nIniHor := oSize1:GetDimension( 'CALC2', "COLINI" ) + 4
	nLine   := oSize:GetDimension( 'CALC', "LININI" ) + 10
	oGetLuc   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetLuc:=u,nGetLuc ) }, oPanFld2, 40, 10, "@R 9,999.99 %", 'nGetLuc', 'Lucro' )
	oBtnLuc   := TButton():New( nLine, nIniHor+110, "Tornar Padrão",oPanFld2,{|| setLucro( SD1TMP->D1_COD, nGetLuc ), readGlobal(), someChange() }, 40,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	oBtnLuc:bWhen := {|| GetMv( 'MV_X_PNC05', .T. /* lCheck */ ) .and. nGetLuc != getLucro( SD1TMP->D1_COD, GetMV( 'MV_X_PNC05') ) }

	nLine += 14
	oGetPCV   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetPCV:=u,nGetPCV ) }, oPanFld2, 40, 10, "@R 9,999.99 %", 'nGetPCV', 'PIS/COFINS' )
	nLine += 14
	oGetICV   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetICV:=u,nGetICV ) }, oPanFld2, 40, 10, "@R 9,999.99 %", 'nGetICV', 'ICMS' )
	oBtnICV   := TButton():New( nLine, nIniHor+110, 'Tornar Padrão', oPanFld2, { || PutMv( 'MV_X_PNC18', nGetICV ), readGlobal(), someChange() }, 40, 10,,,.F.,.T.,.F.,,.F.,,,.F. )
	oBtnICV:bWhen := {|| GetMv( 'MV_X_PNC18', .T. /* lCheck */ ) .and. nGetICV != GetMV( 'MV_X_PNC18') }

	nLine += 14
	oGetOpe   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetOpe:=u,nGetOpe ) }, oPanFld2, 40, 10, "@R 9,999.99 %", 'nGetOpe', 'Desp.Oper' )
	oBtnDOp   := TButton():New( nLine, nIniHor+110, "Tornar Padrão",oPanFld2,{|| PutMV( 'MV_X_PNC06', nGetOpe ), readGlobal(), someChange() }, 40,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	oBtnDOp:bWhen := {|| GetMv( 'MV_X_PNC06', .T. /* lCheck */ ) .and. nGetOpe != GetMV( 'MV_X_PNC06') }

	nLine += 14
	oGetCSL   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetCSL:=u,nGetCSL ) }, oPanFld2, 40, 10, "@R 9,999.99 %", 'nGetCSL', 'CSLL' )
	oBtnCSL  := TButton():New( nLine, nIniHor+110, "Tornar Padrão",oPanFld2,{|| PutMV( 'MV_X_PNC07', nGetCSL ), readGlobal(), someChange() }, 40,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	oBtnCSL:bWhen := {|| GetMv( 'MV_X_PNC07', .T. /* lCheck */ ) .and. nGetCSL != GetMV( 'MV_X_PNC07') }

	nLine += 14
	oGetIRP   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetIRP:=u,nGetIRP ) }, oPanFld2, 40, 10, "@R 9,999.99 %", 'nGetIRP', 'IRPJ' )
	oBtnIRP   := TButton():New( nLine, nIniHor+110, "Tornar Padrão",oPanFld2,{|| PutMV( 'MV_X_PNC08', nGetIRP ), readGlobal(), someChange() }, 40,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	oBtnIRP:bWhen := {|| GetMv( 'MV_X_PNC08', .T. /* lCheck */ ) .and. nGetIRP != GetMV( 'MV_X_PNC08') }

	nLine += 14
	oGetIna   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetIna:=u,nGetIna ) }, oPanFld2, 40, 10, "@R 9,999.99 %", 'nGetIna', 'Inadimpl' )
	oBtnIna   := TButton():New( nLine, nIniHor+110, "Tornar Padrão",oPanFld2,{|| PutMV( 'MV_X_PNC09', nGetIna ), readGlobal(), someChange() }, 40,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	oBtnIna:bWhen := {|| GetMv( 'MV_X_PNC09', .T. /* lCheck */ ) .and. nGetIna != GetMV( 'MV_X_PNC09') }

	nLine += 14
	oGetTCV   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetTCV:=u,nGetTCV ) }, oPanFld2, 40, 10, "@R 9,999.99 %", 'nGetTCV', 'Tt.Cus.Var', !lEnable )
	nLine += 14
	oGetFiV   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetFiV:=u,nGetFiV ) }, oPanFld2, 40, 10, "@R 9,999.99 %", 'nGetFiV', 'Financeiro' )
	oBtnFin   := TButton():New( nLine, nIniHor+110, "Tornar Padrão",oPanFld2,{|| PutMV( 'MV_X_PNC10', nGetFiV ), readGlobal(), someChange() }, 40,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	oBtnFin:bWhen := {|| GetMv( 'MV_X_PNC10', .T. /* lCheck */ ) .and. nGetFiV != GetMV( 'MV_X_PNC10' ) }

	nLine += 14
	oGetIPS   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetIPS:=u,nGetIPS ) }, oPanFld2, 40, 10, "@E 9,999,999.99", 'nGetIPS', 'IPI Saída', lEnable )

	nLine += 14
	oGetPSL   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetPSL:=u,nGetPSL ) }, oPanFld2, 40, 10, "@E 9,999,999.99", 'nGetPSL', 'Prc.s/Lucro', !lEnable )
	nLine += 14
	oGetSug   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetSug:=u,nGetSug ) }, oPanFld2, 40, 10, "@E 9,999,999.99", 'nGetSug', 'Sug.Preço' )
	oGetMg1   := doGet( nLine, nIniHor+91,{|u| if( PCount()>0,nGetMg1:=u,nGetMg1 ) }, oPanFld2, 40, 10, "@R 9,999.99 %", 'nGetMg1',, !lEnable )
	oGetScI   := doGet( nLine, nIniHor+143, {|u| if( PCount()>0,nGetScI:=u,nGetScI ) }, oPanFld2, 40, 10, "@E 9,999,999.99", 'nGetScI', 'PS+IPI',!lEnable )
	oBtnTab   := TButton():New( nLine, nIniHor+227, "Aplicar",oPanFld2,{|| priceAdjust( cGetTab, SD1TMP->D1_COD, nGetSug ), oBrowse:LineRefresh(), someChange() }, 30,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	oBtnTab:bWhen := {|| !Empty( cGetTab ) .and. ! Round( nGetSug, 2 ) == nGetPrc .and. RetCodUsr() $ cMasters }

	if lDocEntr
		oBtnIgn := TButton():New( nLine, nIniHor+287, "Ignorar",oPanFld2,{|| checkItem(), oBrowse:LineRefresh(), someChange() }, 30,10,,,.F.,.T.,.F.,,.F.,,,.F. )
		oBtnIgn:bWhen := {|| ! SD1TMP->(EOF()) .and. RetCodUsr() $ cMasters }
	endif

	nLine += 14
	oGetPrc   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetPrc:=u,nGetPrc ) }, oPanFld2, 40, 10, "@E 9,999,999.99", 'nGetPrc', 'Prc.Venda', !lEnable )
	oGetMg2   := doGet( nLine, nIniHor+91,{|u| if( PCount()>0,nGetMg2:=u,nGetMg2 ) }, oPanFld2, 40, 10, "@R 9,999.99 %", 'nGetMg2',,!lEnable )
	oGetPCI   := doGet( nLine, nIniHor+143,{|u| if( PCount()>0,nGetPCI:=u,nGetPCI ) }, oPanFld2, 40, 10, "@E 9,999,999.99", 'nGetPCI', 'PV+IPI',!lEnable )

	// Ultima compra
	nIniHor   := oSize1:GetDimension( 'CALC3', "COLINI" ) + 08
	nLine	  := oSize:GetDimension( 'CALC', "LININI" ) + 10
	oGetUPr   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetUPr:=u,nGetUPr ) }, oPanFld3, 50, 10, "@E 9,999,999.99", 'nGetUPr', 'Ult.Preço', !lEnable )
	nLine     += 14
	oGetUQt   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetUQt:=u,nGetUQt ) }, oPanFld3, 40, 10, "@E 9,999,999", 'nGetUQt', 'Ult.Quant.', !lEnable )
	nLine     += 14
	oGetUDt   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,dGetUDt:=u,dGetUDt ) }, oPanFld3, 40, 10,, 'dGetUDt', 'Dt.Ult.NF', !lEnable )
	nLine     += 14
	oGetUPz   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,cGetUPz:=u,cGetUPz ) }, oPanFld3, 90, 10,"@x", 'cGetUPz', 'Ult.Prazo', !lEnable )
	nLine     += 14
	oGetNF    := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,cGetNF :=u,cGetNF  ) }, oPanFld3, 50, 10,"@!", 'cGetNF', 'Ult.Nota', !lEnable )
	nLine     += 14
	oGetUFo   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,cGetUFo:=u,cGetUFo ) }, oPanFld3, 90, 10,"@x", 'cGetUFo', 'Ult.Forn', !lEnable )
	nLine     += 14
	oGetUFi   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,cGetUFi:=u,cGetUFi ) }, oPanFld3, 40, 10,"@!", 'cGetUFi', 'Filial', !lEnable )

	oDlgDoc:Activate(,,,.T. /* lCentered */, bValid,,bInit)

	// Encerra cálculos
	MaFisEnd()

	oTmp:Delete()
	FreeObj( oTmp )

	restArea( aArea )
return nil

/*/{Protheus.doc} checkDoc
FUnção para checar o documento quando o processo de formação de preços for finalizado
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 1/17/2025
@param oBrowse, object, objeto do browse
@param cFil, character, filial
@param cDoc, character, número do documento
@param cSerie, character, série do documento
@param cFornece, character, fornecedor
@param cLoja, character, loja
@param cTipo, character, tipo do documento
@return logical, lSuccess
/*/
Static function checkDoc( oBrowse, cFil, cDoc, cSerie, cFornece, cLoja, cTipo )
	
	local aArea := SD1TMP->(getArea())
	local lSuccess := .T.

	SD1TMP->( DBGoTop() )
	While ! SD1TMP->( EOF() )
		lSuccess := lSuccess .and. SD1TMP->F1_X_FPRC == 'S'
		SD1TMP->( DBSkip() )
	end

	if ! lSuccess
		lSuccess := MsgYesNo( 'Foram identificados alguns itens que não tiveram seu preço de venda revisado, '+;
		'gostaria de IGNORAR o processo de revisão e MARCAR A NOTA TODA COMO REVISADA?', " A T E N Ç Ã O ! " )
	Endif

	if lSuccess
		DBSelectArea( 'SF1' )
		SF1->( DBSetOrder( 1 ) )
		if SF1->( DBSeek( cFil + cDoc + cSerie + cFornece + cLoja + cTipo ) )
			RecLock( 'SF1', .F. )
			SF1->F1_X_FPRC := 'S'
			SF1->( MsUnlock() )
		endif
	else
		hlp( 'NAOREVISADA',;
			 'Esta nota não foi revisada por completo',;
			 'Realize a revisão de todos os itens, ajustando os preços ou ignorando-os para que o sistema entenda que a revisão foi concluída.' )
	endif

	restArea( aArea )
return lSuccess

/*/{Protheus.doc} checkItem
Função para marcar item da tabela temporária como checado quanto ao processo de formação de preços
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 1/17/2025
/*/
static function checkItem()
	RecLock( 'SD1TMP', .F. )
	SD1TMP->F1_X_FPRC := 'S'
	SD1TMP->( MsUnlock() )
return Nil

/*/{Protheus.doc} setLucro
Atribui valor padrão conforme escolha do usuário (se for apenas para produto, se for apenas parâmetro ou ambos)
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 1/14/2025
@param cProduto, character, ID do produto
@param nDefault, numeric, índice default
@return logical, lSuccess
/*/
static function setLucro( cProduto, nDefault )

	local nX       := 0 as numeric
	local cFilHist := cFilAnt
	local nOpc     := 0 as numeric
	local lSuccess := .F. as logical

	DBSelectArea( 'SBZ' )
	SBZ->( DBSetOrder( 1 ) )		// BZ_FILIAL + BZ_COD

	DBSelectArea( 'SB1' )
	SB1->( DBSetOrder( 1 ) )		// B1_FILIAL + B1_COD

	nOpc := Aviso( 'A T E N Ç Ã O ',;
				   'Onde você gostaria de definir essa margem de lucro? Apenas para este produto? Ajustar o índice padrão '+;
				   '(quando não estiver cadastrado no produto, o sistema usa um índice padrão definido via Configurador)? Ou ajustar as duas coisas?',;
				   { 'Apenas Produto', 'Parâmetro Config.', 'Ambos' }, 3 )
	for nX := 1 to len( _aFil )
		cFilAnt := _aFil[nX]

		if nOpc == 1 .or. nOpc == 3		// Se for para alterar apenas o produto ou ambos
			
			if SBZ->( DBSeek( FWxFilial( 'SBZ' ) + cProduto ) )  .and. SBZ->( FieldPos( 'BZ_X_LUCRO' ) ) > 0 
				// Altera apenas quando o valor informado for diferente do valor existente
				if SBZ->BZ_X_LUCRO != nDefault
					RecLock( 'SBZ', .F. )
					SBZ->BZ_X_LUCRO := nDefault
					SBZ->( MsUnlock() )
					lSuccess := .T.
				endif
			elseif SB1->( DBSeek( FWxFilial( 'SB1' ) + cProduto ) ) .and. SB1->( FieldPos( 'B1_X_LUCRO' ) ) > 0
				if SB1->B1_X_LUCRO != nDefault
					RecLock( 'SB1', .F. )
					SB1->B1_X_LUCRO := nDefault
					SB1->( MsUnlock() )
					lSuccess := .T.
				endif
			endif
		endif
		
		if nOpc == 2 .or. nOpc == 3	// Se for para alterar apenas parâmetro ou ambos
			// Ajusta também conteúdo do parâmetro
			PutMV( 'MV_X_PNC05', nDefault )
			lSuccess := .T.
		endif

	next nX

	cFilAnt := cFilHist
return lSuccess

/*/{Protheus.doc} readGlobal
Função para ler informações atualizadas do conteúdo das variáveis globais
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 1/14/2025
/*/
static function readGlobal()
	nGetIPS := RetField( 'SB1', 1, FWxFilial( 'SB1' ) + SD1TMP->D1_COD, 'B1_IPI' )
	nGetLuc := getLucro( SD1TMP->D1_COD, GetMV( 'MV_X_PNC05') )
	nGetOpe := GetMV( 'MV_X_PNC06')
	nGetCSL := GetMV( 'MV_X_PNC07')
	nGetIRP := GetMV( 'MV_X_PNC08')
	nGetIna := GetMV( 'MV_X_PNC09')
	nGetFiV := GetMV( 'MV_X_PNC10')
	nGetICV := GetMV( 'MV_X_PNC18')
return Nil

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

	// Antes de aplicar preço, valida existência da tabela de preços
	if ! ExistCpo( 'DA0', cTab )
		hlp( 'TABELA INEXISTENTE',;
			 'A tabela de preços informada não existe ou não está cadastrada na filial atual',;
			 'Verifique se a tabela de preços informada está correta e se está cadastrada na filial atual' )
		restArea( aArea )
		Return lSuccess
	endif

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

	if lSuccess
		checkItem()
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
	local cRet := "" as character
	if cField == 'D1_VALFRE'
		cRet := '{|| '+ cField +' + VALFRT }'
	else
		cRet := '{|| '+ cField +' }'
	endif
return cRet

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
			aAdd( aMrkFor, ( cAlias )->( FieldGet( FieldPos( 'A2_COD' ) ) ) + ( cAlias )->( FieldGet( FieldPos( 'A2_LOJA' ) ) ) )
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

/*/{Protheus.doc} fCanPed
Função que cancela pedidos em aberto com o fornecedor
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/16/2024
/*/
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
	local cFilHist   := cFilAnt
	local nEmpr      := 0 as numeric

	for nEmpr := 1 to len( _aFil )

		cEmpAnt := _aFil[nEmpr]

		// Busca os pedidos pendentes 
		cQuery := "SELECT C7.C7_NUM, C7.C7_ITEM, C7.C7_DATPRF, C7.C7_QUANT - C7.C7_QUJE EMPED, C7.C7_QUJE FROM "+ RetSqlName( 'SC7' ) +" C7 " + CEOL
		cQuery += "WHERE C7.C7_FILIAL  = '"+ FWxFilial( 'SC7' ) +"' " + CEOL 
		cQuery += "  AND C7.C7_PRODUTO = '"+ cProd +"' " + CEOL
		cQuery += "  AND C7.C7_RESIDUO <> 'S' " + CEOL
		cQuery += "  AND C7.C7_ENCER   <> 'E' " + CEOL
		cQuery += "  AND C7.C7_CONAPRO <> 'B' " + CEOL						// desconsidera se o pedido ainda estiver pendente de aprovação
		cQuery += "  AND C7.D_E_L_E_T_ = ' ' " + CEOL
		
		DBUseArea( .T., 'TOPCONN', TcGenQry( ,,cQuery ), 'PDAJUS', .F., .T. )
		
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

	Next nEmpr

	// Devolve posicionamento na empresa
	cFilAnt := cFilHist

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

/*/{Protheus.doc} fRepEnt
Função para realizar reprogramação de entrega do pedido com o fornecedor
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/16/2024
/*/
Static Function fRepEnt()
	
	Local cProd    := oEvent:aCols[ oEvent:nAt ][ aScan( oEvent:aHeader, {| x | AllTrim( x[02] ) == cZB3 +"_PROD" } ) ]
	Local nPrd     := aScan( oEvent:aHeader, {|x| AllTrim( x[2] ) == cZB3 +"_PROD" } )
	lOCAL nDat     := aScan( oEvent:aHeader, {|x| AllTrim( x[2] ) == cZB3 +"_DATA" } )
	local nFil     := aScan( oEvent:aHeader, {|x| AllTrim( x[2] ) == cZB3 +"_FILIAL" } )
	Local cQuery   := ""
	Local aPeds    := {}
	Local nX       := 0
	Local cStlBtn  := ""
	Local oDlg     := Nil
	Local oLblDat  := Nil
	Local oDatIgn  := Nil
	Local dDatIgn  := StoD( Space( 8 ) )
	Local oTexto   := Nil
	Local cTexto   := ""
	Local oClose   := Nil
	Local oSave    := Nil
	Local lRet     := .F.
	Local cAux     := ""
	Local dAux     := Nil
	Local aLin     := {}
	Local aIte     := {}
	local cFilHist := cFilAnt as character
	local nEmpr    := 0 as numeric
	
	Private lMsErroAuto := .F.
	
	if len( _aFil ) > 0
		
		for nEmpr := 1 to len( _aFil )
			
			cFilAnt := _aFil[nEmpr]

			// Busca os pedidos pendentes 
			cQuery := "SELECT C7.C7_FILIAL, C7.C7_NUM, C7.C7_ITEM, C7.C7_DATPRF, C7.C7_QUANT - C7.C7_QUJE EMPED, C7.C7_QUJE FROM "+ RetSqlName( 'SC7' ) +" C7 " + CEOL
			cQuery += "WHERE C7.C7_FILIAL  = '"+ FWxFilial( 'SC7' ) +"' "+ CEOL 
			cQuery += "  AND C7.C7_PRODUTO = '"+ cProd +"' " + CEOL
			cQuery += "  AND C7.C7_RESIDUO <> 'S' " + CEOL
			cQuery += "  AND C7.C7_ENCER   <> 'E' " + CEOL
			cQuery += "  AND C7.C7_CONAPRO <> 'B' " + CEOL						// Desconsidera se o pedido ainda estiver pendente de aprovação
			cQuery += "  AND C7.D_E_L_E_T_ = ' ' " + CEOL
			
			DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), 'PDAJUS', .F., .T. )
			
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
									lMsErroAuto := .F.
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
					EndIf
					
				EndIf
				
			EndIf
		
		next nEmpr
	
	endif
	
	cFilAnt := cFilHist

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
	Local aFields   := {"C7_FILIAL", "C7_FILENT", "NUMERO","C7_ITEM","C7_QUANT","SALDO","C7_PRECO","C7_TOTAL","C7_EMISSAO","C7_DATPRF","C7_FORNECE","C7_LOJA","A2_NOME"}
	Local aAlter    := {}
	Local cTitulo   := "Pedidos em aberto"
	Local oBtnLeg   := Nil
	local oBtnImp   as object
	local oBtnMail  as object
	Local oBtnExc   as object
	local nPosBtn   := 0 as numeric
	local lEnvPed   := AllTrim(SuperGetMv( "MV_ENVPED",, '0')) $ '1|2'
	local bExcluir  := {|| iif( Len(oGrid:aCols) > 0, orderDel( oGrid:aCols[oGrid:nAt][ColPos(oGrid,'C7_FILIAL')],;
							oGrid:aCols[oGrid:nAt][ColPos(oGrid,'NUMERO')] ), Nil) }
	
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
    
	nPosBtn := iif( lEnvPed, 295, 336 )
    @ 136, nPosBtn BUTTON oBtnLeg  PROMPT "&Legenda"  SIZE 037, 012 OF oDlgPed ACTION fLegenda() PIXEL
	nPosBtn+= 39
	if lEnvPed
		@ 136, nPosBtn BUTTON oBtnMail PROMPT "&Enviar E-mail" SIZE 045, 012 OF oDlgPed ACTION sndMail( oGrid:aCols[oGrid:nAt][ColPos(oGrid,'NUMERO')] ) PIXEL
		nPosBtn += 47
	endif
	@ 136, nPosBtn BUTTON oBtnImp  PROMPT "&Imprimir" SIZE 037, 012 OF oDlgPed ACTION iif( Len(oGrid:aCols) > 0, GMPCPRINT( oGrid:aCols[oGrid:nAt][ColPos(oGrid,'C7_FILIAL')],;
																															oGrid:aCols[oGrid:nAt][ColPos(oGrid,'NUMERO')] ), Nil) PIXEL
	nPosBtn += 39
	@ 136, nPosBtn BUTTON oBtnExc  PROMPT "&Excluir"  SIZE 037, 012 OF oDlgPed ACTION Eval( bExcluir ) PIXEL
	oBtnExc:bWhen := {|| Len(oGrid:aCols) > 0 }

	nPosBtn += 39
    @ 136, nPosBtn BUTTON oBtnFec  PROMPT "&Fechar"   SIZE 037, 012 OF oDlgPed ACTION oDlgPed:End() PIXEL
    
    ACTIVATE MSDIALOG oDlgPed CENTERED ON INIT ;
	Processa( {|| fPedPen( .F./*lNoInt*/, nOpc, aColPro[ oBrwPro:nAt ][ nPosPrd ] /*cProd*/ ) }, 'Aguarde!','Buscando pedidos não atendidos!' )

	SetKey( K_ALT_X, {|| fMarkPro() } )
	SetKey( VK_F4, {|| Processa( {|| supplyerChoice( /* lForce */ ) }, 'Aguarde!','Analisando dados do MRP...' ) } )
	SetKey( VK_F5, {|| Processa( {|| fLoadInf() }, 'Aguarde!','Analisando dados do MRP...' ) } )
	SetKey( VK_F12, {|| fManPar() } )

Return ( Nil )


/*/{Protheus.doc} fPedFor
Função para exibição das solicitações de compra abertas por produto
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 16/04/2025
/*/
Static Function fSolPend()
	
	Local oBtnFec
	Local oGetDes
	Local cGetDes   := aColPro[ oBrwPro:nAt ][ nPosDes ]
	Local oGetPrd
	Local cGetPrd   := aColPro[ oBrwPro:nAt ][ nPosPrd ]
	Local oLblPrd   := 0
	Local nX        := 0
	Local aHeaderEx := {}
	Local aFields   := {"C1_FILIAL", "C1_FILENT", "C1_NUM","C1_ITEM","C1_QUANT","SALDO","C1_VUNIT","C1_EMISSAO","C1_DATPRF","C1_SOLICIT"}
	Local aAlter    := {}
	Local cTitulo   := "Solicitações do produto em aberto"
	Local oBtnLeg   := Nil
	Local oBtnExc   as object
	local nPosBtn   := 0 as numeric
	local bExcluir  := {|| a110Del( aColsEx[oGrid:nAt][aScan(aHeaderEx, {|x| AllTrim(x[2]) == 'C1_FILIAL' })],;
									aColsEx[oGrid:nAt][aScan(aHeaderEx, {|x| AllTrim(x[2]) == 'C1_NUM' })] ),;
							aColsEx := getSolic( aColPro[ oBrwPro:nAt ][ nPosPrd ] /*cProd*/ ),;
							oGrid:aCols := aClone( aColsEx ),;
							oGrid:ForceRefresh() }
	
	Private aColsEx := {}
	Private oGrid   := Nil
	Private oDlgPed := Nil

	// Define campo de legenda manualmente
	aAdd( aHeaderEx, { " ","LEGENDA", "@BMP",02, 00, ".F.","", "C", "", "V" ,"" , "","","V" } )

	// Define as configurações dos campos do grid
  	For nX := 1 to Len(aFields)
        if aFields[nX] == "SALDO"
        	aAdd( aHeaderEx, { 'Saldo', "SALDO", "@E 999,999.99", 11, 2, , , "N", ,"V", , } )
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
    
	nPosBtn := 500 - 120
    @ 136, nPosBtn BUTTON oBtnLeg  PROMPT "&Legenda"  SIZE 038, 012 OF oDlgPed ACTION fLegenda() PIXEL
	nPosBtn+= 40

	@ 136, nPosBtn BUTTON oBtnExc  PROMPT "&Excluir"  SIZE 037, 012 OF oDlgPed ACTION Eval( bExcluir ) PIXEL
	oBtnExc:bWhen := {|| Len(oGrid:aCols) > 0 }
	nPosBtn += 39

    @ 136, nPosBtn BUTTON oBtnFec  PROMPT "&Fechar"   SIZE 038, 012 OF oDlgPed ACTION oDlgPed:End() PIXEL
    
    ACTIVATE MSDIALOG oDlgPed CENTERED ON INIT ;
	Processa( {|| aColsEx := getSolic( aColPro[ oBrwPro:nAt ][ nPosPrd ] /*cProd*/ ),;
				 oGrid:aCols := aClone( aColsEx ),;
				 oGrid:ForceRefresh(),;
				 oDlgPed:End() }, 'Aguarde!','Buscando solicitações não atendidas...' )

	SetKey( K_ALT_X, {|| fMarkPro() } )
	SetKey( VK_F4, {|| Processa( {|| supplyerChoice( /* lForce */ ) }, 'Aguarde!','Analisando dados do MRP...' ) } )
	SetKey( VK_F5, {|| Processa( {|| fLoadInf() }, 'Aguarde!','Analisando dados do MRP...' ) } )
	SetKey( VK_F12, {|| fManPar() } )

Return ( Nil )

/*/{Protheus.doc} a110Del
Função para deletar solicitação de compra
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 5/5/2025
@param cNum, character, Numero da solicitação
@return logical, lSuccess
/*/
static function a110Del( cFil, cNum )
	
	local lSuccess  := .F. as logical

	Private aRotina    := FWLoadMenuDef( 'MATA110' )
	Private l110Auto   := .T.
	Private INCLUI     := .F.
	Private ALTERA     := .F.
	Private lAlcSolCtb := SuperGetMv( 'MV_APRSCEC', .F., .F. )
	Private lGeraSCR   := SuperGetMv( 'MV_APROVSC', .F., .F. )
	Private cGrpAprov  := SuperGetMv( 'MV_APGRDFL', .F., "" )

	DBSelectArea( 'SC1' )
	SC1->( DBSetOrder( 1 ) )
	if SC1->( DBSeek( cFil + cNum ) )
		If MsgYesNo( 'Está certo(a) de que gostaria de excluir a solicitação número '+ cNum +'?', 'A T E N Ç Ã O !' )
			lSuccess := A110Deleta( 'SC1', SC1->( Recno() ), 5, .F. /* lCopia */, .F. /* lWhenGet */, .F. /* lVisual */ )
		endif
	endif
return lSuccess

/*/{Protheus.doc} getSolic
Função para obter as solicitações que estão pendentes de serem atendidas referente ao produto selecionado
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 4/16/2025
@param cProduto, character, ID do produto
@return array, aColsEx
/*/
static function getSolic( cProduto )

	Local cQuery := "" as character
	local aColsEx := {} as array
	
	aColsEx := {}

	cQuery += "SELECT C1.C1_FILIAL, C1.C1_FILENT, C1.C1_NUM, C1_ITEM, SUM( C1.C1_QUANT ) C1_QUANT, SUM(C1.C1_QUANT - C1.C1_QUJE) SALDO, C1.C1_VUNIT, " + CEOL
	cQuery += "       C1.C1_DATPRF, C1.C1_EMISSAO, C1.C1_SOLICIT " + CEOL
	cQuery += "FROM "+ RetSqlName( 'SC1' ) +" C1 " + CEOL
	
	cQuery += "INNER JOIN "+ RetSqlName( 'SB1' ) +" B1 "+ CEOL
	cQuery += " ON B1.B1_FILIAL  "+ U_JSFILIAL( "SB1", _aFil ) +" "+ CEOL
	cQuery += "AND B1.B1_COD     = C1.C1_PRODUTO " + CEOL
	cQuery += "AND B1.D_E_L_E_T_ = ' ' " + CEOL
	
    cQuery += "WHERE C1.C1_FILIAL  = '"+ FWxFilial( 'SC1' ) +"' "
	cQuery += "  AND C1.C1_FILENT     "+ U_JSFILIAL( 'SC1', _aFil ) +" "+ CEOL
    cQuery += "  AND C1.C1_PRODUTO = '"+ cProduto +"' " + CEOL
    cQuery += "  AND C1.C1_RESIDUO <> 'S' " + CEOL
    cQuery += "  AND C1.C1_PEDIDO  = '"+ Space( TAMSX3( 'C1_PEDIDO' )[1] ) +"' " + CEOL
    cQuery += "  AND C1.D_E_L_E_T_ = ' ' " + CEOL
    
    cQuery += "GROUP BY C1.C1_FILIAL, C1.C1_FILENT,C1.C1_NUM, C1.C1_ITEM, C1.C1_VUNIT, C1.C1_DATPRF, C1.C1_EMISSAO, C1.C1_SOLICIT " + CEOL
    cQuery += "ORDER BY C1.C1_FILIAL, C1.C1_FILENT,C1.C1_DATPRF, C1.C1_NUM " + CEOL
    
	MPSysOpenQuery( cQuery, "PEDTMP" )
	
	// Seta o tipo de conteúdo dos campos quando for data
    TcSetField( 'PEDTMP', 'C1_DATPRF' , 'D' )
	TcSetField( 'PEDTMP', 'C1_EMISSAO', 'D' )
	
	PEDTMP->( DbGoTop() )
	
	If !PEDTMP->( EOF() )
		While !PEDTMP->( EOF() )
			
			aAdd( aColsEx, { iif( PEDTMP->C1_QUANT == PEDTMP->SALDO, "BR_VERDE", "BR_AZUL" ),;
							 PEDTMP->C1_FILIAL,;
							 PEDTMP->C1_FILENT,;
			                 PEDTMP->C1_NUM,;	
			                 PEDTMP->C1_ITEM,;
			                 PEDTMP->C1_QUANT,;
			                 PEDTMP->SALDO,;
			                 PEDTMP->C1_VUNIT,;
							 PEDTMP->C1_EMISSAO,;
			                 PEDTMP->C1_DATPRF,;
			                 PEDTMP->C1_SOLICIT,;
			                 .F.} )
			
			PEDTMP->( DbSkip() )
			
		EndDo
	EndIf
	PEDTMP->( DbCloseArea() )

return aColsEx

/*/{Protheus.doc} orderDel
FUnção para eliminação completa do pedido de compra
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/18/2025
@param cFil, character, Filial do pedido
@param cPedido, character, ID do pedido
@return logical, lSuccess
/*/
static function orderDel( cFil, cPedido )
	
	local lSuccess := .F. as logical
	local aCab     := {} as array
	local aItens   := {} as array
	local aLine    := {} as array
	local cFilHist := cFilAnt

	Private lMsErroAuto := .F. as logical

	cFilAnt := cFil

	DBSelectArea( 'SC7' )
	SC7->( DBSetOrder( 1 ) )
	if SC7->( DBSeek( FWxFilial( 'SC7' ) + cPedido ) )
		
		aAdd( aCab, { "C7_FILIAL", SC7->C7_FILIAL, Nil } )
		aAdd( aCab, { "C7_NUM", SC7->C7_NUM, Nil } )
		aAdd( aCab, { "C7_EMISSAO", SC7->C7_EMISSAO, Nil } )
		aAdd( aCab, { "C7_FORNECE", SC7->C7_FORNECE, Nil } )
		aAdd( aCab, { "C7_LOJA", SC7->C7_LOJA, Nil } )
		aAdd( aCab, { "C7_COND", SC7->C7_COND, Nil } )
		aAdd( aCab, { "C7_CONTATO", SC7->C7_CONTATO, Nil } )
		aAdd( aCab, { "C7_FILENT", SC7->C7_FILENT, Nil } )

		While ! SC7->( EOF() ) .and. SC7->C7_FILIAL + SC7->C7_NUM == FWxFilial( 'SC7' ) + cPedido
			
			aAdd( aLine, { "C7_ITEM", SC7->C7_ITEM, Nil } )
			aAdd( aLine, { "C7_PRODUTO", SC7->C7_PRODUTO, Nil } )
			aAdd( aLine, { "C7_QUANT", SC7->C7_QUANT, Nil } )
			aAdd( aLine, { "C7_PRECO", SC7->C7_PRECO, Nil } )
			aAdd( aLine, { "C7_REC_WT", SC7->(Recno()), Nil } )
			aAdd( aItens, aCLone( aLine ) )
			aLine := {}

			SC7->( DBSkip() )
		end

		if len( aCab ) > 0 .and. len( aItens ) > 0
			lMsErroAuto := .F.
			MSExecAuto({|a,b,c,d,e| MATA120(a,b,c,d,e)},1,aCab,aItens,5,.F.)
			if lMsErroAuto
				lSuccess := .F.
				MostraErro()
			else
				MsgInfo( "Pedido "+ cPedido +" excluído com sucesso!", 'S U C E S S O !' )
				Processa( {|| fPedPen( .F./*lNoInt*/, 2, aColPro[ oBrwPro:nAt ][ nPosPrd ] /*cProd*/ ) }, 'Aguarde!','Buscando pedidos não atendidos!' )
			endif
		endif

	endif
	cFilAnt := cFilHist

return lSuccess


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
	Default nOpc   := 2		// Exibe os pedidos pendentes para o produto
	
	aColsEx := {}

	cQuery += "SELECT C7.C7_FILIAL, C7.C7_FILENT, C7.C7_NUM NUMERO, C7_ITEM, C7_CONAPRO, SUM( C7.C7_QUANT ) C7_QUANT, SUM(C7.C7_QUANT - C7.C7_QUJE) SALDO, C7.C7_PRECO, SUM( C7.C7_TOTAL ) C7_TOTAL, " + CEOL
	cQuery += "       C7.C7_DATPRF, C7.C7_EMISSAO, C7.C7_FORNECE, C7.C7_LOJA, A2.A2_NOME " + CEOL
	cQuery += "FROM "+ RetSqlName( 'SC7' ) +" C7 " + CEOL
	
	cQuery += "INNER JOIN "+ RetSqlName( 'SB1' ) +" B1 "+ CEOL
	cQuery += " ON B1.B1_FILIAL  "+ U_JSFILIAL( "SB1", _aFil ) +" "+ CEOL
	cQuery += "AND B1.B1_COD     = C7.C7_PRODUTO " + CEOL
	cQuery += "AND B1.D_E_L_E_T_ = ' ' " + CEOL
	
	cQuery += "INNER JOIN "+ RetSqlName( 'SA2' ) +" A2 " + CEOL
	cQuery += " ON A2.A2_FILIAL " + U_JSFILIAL( "SA2", _aFil ) +" "+ CEOL
	cQuery += "AND A2.A2_COD     = C7.C7_FORNECE " + CEOL
	cQuery += "AND A2.A2_LOJA    = C7.C7_LOJA "+ CEOL
	cQuery += "AND A2.D_E_L_E_T_ = ' ' " + CEOL
	
    cQuery += "WHERE C7.C7_FILIAL  = '"+ FWxFilial( 'SC7' ) +"' "+ CEOL
	cQuery += "  AND C7.C7_FILENT  "+ U_JSFILIAL( 'SC7', _aFil ) +" "+ CEOL
    cQuery += "  AND C7.C7_PRODUTO = '"+ cProd +"' " + CEOL
    cQuery += "  AND C7.C7_RESIDUO <> 'S' " + CEOL
    cQuery += "  AND C7.C7_ENCER   <> 'E' " + CEOL
    cQuery += "  AND C7.D_E_L_E_T_ = ' ' " + CEOL
    
    cQuery += "GROUP BY C7.C7_FILIAL, C7.C7_FILENT, C7.C7_NUM, C7.C7_ITEM, C7_CONAPRO, C7.C7_PRECO, C7.C7_DATPRF, C7.C7_EMISSAO, C7.C7_FORNECE, C7.C7_LOJA, A2.A2_NOME " + CEOL
    cQuery += "ORDER BY C7.C7_FILIAL, C7.C7_FILENT, C7.C7_DATPRF, C7.C7_NUM " + CEOL
    
	TcQuery cQuery New Alias 'PEDTMP'
	DbSelectArea( 'PEDTMP' )
	
	// Seta o tipo de conteúdo dos campos quando for data
    TcSetField( 'PEDTMP', 'C7_DATPRF' , 'D' )
	TcSetField( 'PEDTMP', 'C7_EMISSAO', 'D' )
	
	PEDTMP->( DbGoTop() )
	
	If !PEDTMP->( EOF() )
		While !PEDTMP->( EOF() )
			
			aAdd( aColsEx, { iif( PEDTMP->C7_CONAPRO == 'B', "BR_AZUL", "BR_VERDE" ),;
							 PEDTMP->C7_FILIAL,;
							 PEDTMP->C7_FILENT,;
			                 PEDTMP->NUMERO,;	
			                 PEDTMP->C7_ITEM,;
			                 PEDTMP->C7_QUANT,;
			                 PEDTMP->SALDO,;
			                 PEDTMP->C7_PRECO,;
			                 PEDTMP->C7_TOTAL,;
							 PEDTMP->C7_EMISSAO,;
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

/*/{Protheus.doc} fLoadAna
Função para carregar a análise gráfica de sazonalidade por filial
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/16/2024
@param lNoInt, logical, indica se a execução está sendo feita sem interface
/*/
Static Function fLoadAna( lNoInt )
	
	Local aArea  := GetArea()
	Local cQuery := ""
	Local aPer   := {}
	Local dIni   := Nil
	Local dFim   := Nil
	Local aMes   := { 'jan','fev','mar','abr','mai','jun','jul','ago','set','out','nov','dez' }
	Local nX     := 0
	Local aTemp  := {}
	local aCliLoja := {} as array
	Local cINCli   := "" as character
	local nAux     := 0 as numeric
	local nVendido := 0 as numeric
	local nProduz  := 0 as numeric
	
	Default lNoInt := .F.
	
	oDash:DeActivate()
	
	aCliLoja := U_JSCLISM0()
	if len( aCliLoja ) > 0
        aEval( aCliLoja, {|x| nAux++, cINCli += "'"+ x[1] + x[2] +"'" + iif( nAux < len(aCliLoja), ',', '' ) } )
    endif

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

		aTemp   := StrTokArr( AllTrim( aColPro[ oBrwPro:nAt ][ nPosDes ] ), ' ' )
		cDesPro := ""
		aEval( aTemp, { |x| cDesPro += SubStr( x, 01, iif( Len( x ) >= 3, 3, Len( x ) ) ) +' ' } )
		
		// Monta comando para leitura dos dados do banco
		cQuery := ""
		oDash:SetPicture( PesqPict( cZB3, cZB3 +'_INDINC' ) )
		For nX := 1 to Len( aPer )
			
			// Query para identificar saídas referente ao produto
			cQuery := "SELECT ROUND(COALESCE(SUM(D2.D2_QUANT),0),0) QTDVEN FROM "+ RetSqlName( 'SD2' ) +" D2 " + CEOL
			cQuery += "WHERE 0=0 "+ CEOL
			
			if cCboFil != 'XX'		// Todas as filiais
				if cCboFil == 'YY'	// Filtro de filiais
					cQuery += "  AND D2.D2_FILIAL "+ U_JSFILIAL( 'SD2', _aFil ) +" "+ CEOL
				else
					cQuery += "  AND D2.D2_FILIAL = '"+ cCboFil +"' " + CEOL
				endif
			endif
			cQuery += "  AND D2.D2_COD     = '"+ aColPro[ oBrwPro:nAt ][ nPosPrd ] +"' " + CEOL
			cQuery += "  AND D2.D2_TIPO    = 'N' " + CEOL		// Apenas notas de saída do tipo N
			cQuery += "  AND D2.D2_EMISSAO BETWEEN '"+ DtoS( aPer[nX][01] ) +"' AND '"+ DtoS( aPer[nX][02] ) +"' " + CEOL
			if ! Empty( cINCli )			// Codigos de clientes referente as filiais do cadastro de empresas
				cQuery += "  AND CONCAT(D2.D2_CLIENTE,D2.D2_LOJA) NOT IN ( "+ cINCli +" ) " + CEOL
			endif
			cQuery += "  AND D2.D_E_L_E_T_ = ' ' " + CEOL

			DBUseArea( .T., "TOPCONN", TcGenQry(,,cQuery), "TMPVEN" /* cAlias */, .F. /* lShared */, .T. /* lReadOnly */ )
			nVendido := 0
			If !TMPVEN->( EOF() )
				nVendido := TMPVEN->QTDVEN
			EndIf
			TMPVEN->( DbCloseArea() )

			cQuery := "SELECT COALESCE(SUM(D3.D3_QUANT),0) AS QTDPROD FROM "+ RetSqlName( 'SD3' ) +" D3 " + CEOL
			cQuery += "WHERE 0=0 " + CEOL
			if cCboFil != 'XX'		// Todas as filiais
				if cCboFil == 'YY'	// Filtro de filiais
					cQuery += "  AND D3.D3_FILIAL "+ U_JSFILIAL( "SD3", _aFil ) +" " + CEOL
				else
					cQuery += "  AND D3.D3_FILIAL = '"+ cCboFil +"' " + CEOL
				endif
			endif
			
			cQuery += "  AND D3.D3_COD    = '"+ aColPro[ oBrwPro:nAt ][ nPosPrd ] +"' " + CEOL
			cQuery += "  AND D3.D3_EMISSAO BETWEEN '"+ DtoS( aPer[nX][01] ) +"' AND '"+ DtoS( aPer[nX][02] ) +"' " + CEOL
			cQuery += "  AND D3.D3_TM     >= '500' " + CEOL
			cQuery += "  AND ( D3.D3_OP     <> '"+ Space( TAMSX3('D3_OP')[1] ) +"' OR D3.D3_CF = 'RE0' ) " + CEOL
			cQuery += "  AND D3.D3_ESTORNO = ' ' " + CEOL
			cQuery += "  AND D3.D_E_L_E_T_ = ' ' " + CEOL
		
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
	local nQtdAtual := 0  as numeric
	local cProdAnt  := "" as character
	local nEstoque  := 0  as numeric
	local lPEPNC04  := ExistBlock( 'PEPNC04' )
	local lRisk     := .F. as logical
	local lPEPNC05  := ExistBLock( 'PEPNC05' )
	local aPEPNC05  := {} as array
	
	Default lNoInt := .F.								// Default é rodar "Com Interface"
	
	_aProdFil := {} 
	aMrkFor   := {} 

	if !IsInCallStack( "A2LTMCHG" )
		DbSelectArea( 'FORTMP' )
		ZAP
	endif
	
	aColPro  := {}
	aFullPro := {}

	// Processa os dados de análise apena quando o usuário selecionou alguma filial
	if len( _aFil ) > 0

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
		
		// Valida se alguma classificação de giro foi selecionada antes de prosseguir
		if Len( aGiros ) > 0
			
			// Consulta todos os produtos para exibí-los no grid
			cQuery := U_JSQRYINF( aConfig, _aFilters, _cPedSol )		
			
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
				DBSelectArea( 'SA2' )
				SA2->( DBSetOrder( 1 ) )
				FORTMP->( DBSetOrder( 2 ) )		// COD + LOJA

				While !PRDTMP->( EOF() )
					nAtual++
					IncProc( 'Analisando '+ AllTrim( SubStr( PRDTMP->B1_DESC, 01, 30 ) ) + '('+ AllTrim( cValToChar( nAtual ) ) +'/'+ AllTrim( cValToChar( nQtdPrd ) ) +')' )
					
					aAux := {}
					aAux := betterSupplier( PRDTMP->B1_COD,; 
											aConfig,;
											_aFilters[03],;
											_aFilters[06] )
					cFornece := PADR( aAux[1], TAMSX3('A2_COD')[1], ' ')		// Codigo do fornecedor
					cLoja    := PADR( aAux[2], TAMSX3('A2_LOJA')[1], ' ' )		// Codigo da loja

					// Quando alteração for chamada pela validação do LDTime do fornecedor, não tem necessidade de atualizar dados dos fornecedores
					if ! isInCallStack( "A2LTMCHG" )
						if ! FORTMP->( DBSeek( cFornece + cLoja ) )

							RecLock( 'FORTMP', .T. )
							FORTMP->MARK        := cMarca
							FORTMP->A2_COD      := cFornece
							FORTMP->A2_LOJA     := cLoja
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
							FORTMP->PEDIDO := iif( aScan( aCarCom, {|x| x[carPos('C7_FORNECE')]+x[carPos('C7_LOJA')] == FORTMP->A2_COD + FORTMP->A2_LOJA } ) > 0, 'S', 'N' )									
							FORTMP->( MsUnlock() )
							
							aAdd( aMrkFor, FORTMP->A2_COD + FORTMP->A2_LOJA )

						endif
					endif

					// Identifica lead-time conforme regra definida para produto, fornecedor (informado) ou fornecedor (calculado)

					if PRDTMP->B1_PE > 0
						nLeadTime := PRDTMP->B1_PE
						cLeadTime := 'P'		// Produto
					else
						// Posiciona no fornecedor e loja
						if SA2->( DBSeek( FWxFilial( 'SA2' ) + cFornece + cLoja ) )
							if SA2->A2_X_LTIME > 0
								nLeadTime := SA2->A2_X_LTIME
								cLeadTime := 'F'		// Fornecedor
							else
								nLeadTime := calcLt( PRDTMP->B1_COD, cFornece, cLoja )
								cLeadTime := 'C'		// Calculado					
							endif
						endif
					endif 
					
					// PE para manipulação do saldo em estoque
					if lPEPNC04
						nEstoque  := ExecBlock( "PEPNC04", .F., .F., { aConfig, PRDTMP->B1_COD, PRDTMP->ESTOQUE } )
					else
						nEstoque := PRDTMP->ESTOQUE
					endif

					// Cálculo da duração do estoque com os pedidos de compra aprovados
					nQtdAtual := iif( aConfig[24] == 'S', nEstoque - PRDTMP->EMPENHO, nEstoque )
					nPrjEst   := Round( ( nQtdAtual - PRDTMP->B1_EMIN + PRDTMP->QTDCOMP )/ PRDTMP->(FieldGet( FieldPos( cZB3 +'_CONMED' ) )), 0 )
					if nPrjEst > 999   
						nPrjEst := 999
					elseif nPrjEst < 0
						nPrjEst := 0
					EndIf

					// Mede se há risco do produto sofrer ruptura
					lRisk := nPrjEst < ( aConfig[01] + nLeadTime )
					if ! lRisk .and. PRDTMP->QTDCOMP > 0 .and. !Empty(PRDTMP->PRVENT) .and. StoD( PRDTMP->PRVENT ) < Date() .and. Round( nQtdAtual/PRDTMP->( FieldGet( FieldPos( cZB3 +'_CONMED' ) ) ), 0 ) < aConfig[01]
						lRisk := .T.
					endif
					if lRisk
						// Trata exceções dos eventos para os produtos sinalizados manualmente pelo operador
						DBSelectArea( cZB6 )
						(cZB6)->( DBSetOrder( 1 ) )
						If DBSeek( xFilial( cZB6 ) + PRDTMP->B1_COD )
							if (cZB6)->( FieldGet( FieldPos( cZB6 +'_DTLIM' ) ) ) >= Date()
								lRisk := .F.
							EndIf
						EndIf

					endif
					
					// Cálculo da duração prevista quando as quantidades bloqueadas forem liberadas
					nDurPrv := Round( ( nQtdAtual + PRDTMP->QTDCOMP + PRDTMP->QTDBLOQ )/ PRDTMP->( FieldGet( FieldPos( cZB3 +'_CONMED' ) ) ), 0 ) - nLeadTime
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
								nEstoque /* nQtdEst */,; 
								PRDTMP->EMPENHO /* nQtdEmp */,;
								PRDTMP->QTDCOMP /* nQtdPed */,;
								PRDTMP->QTDSOL /*nQtdSol*/ }
					
					nQtdCom := fCalNec( aInfPrd, cPerfil )
					
					// Quando apenas sugestões estiver marcado, exibe só os produtos com quantidade de compra maior que 0 (zero)
					if nRadMenu == 2 .and. nQtdCom == 0
						PRDTMP->( DbSkip() )
						Loop
					elseif nRadMenu == 3 .and. ! lRisk
						PRDTMP->( DbSkip() )
						Loop
					EndIf
					
					// Trata produtos pelo índice de incidência
					nIndGir := PRDTMP->( FieldGet( FieldPos( cZB3 +'_INDINC' ) ) ) 
					nPrice  := priceSupplier( PRDTMP->B1_COD, cFornece, cLoja )
					
					// Antes de adicionar o produto ao vetor, verifica se o mesmo já não está listado para esta filial
					if len( _aProdFil ) == 0 .or. aScan( _aProdFil, {|x| x[3] == PRDTMP->B1_COD .and. x[25] == PRDTMP->FILIAL } ) == 0
						aAdd( _aProdFil,{ nIndGir,;
										aScan( aCarCom, {|x| x[carPos('C7_PRODUTO')] == PRDTMP->B1_COD .and. x[carPos('C7_FORNECE')] == cFornece .and. x[carPos('C7_LOJA')] == cLoja } ) > 0,;
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
										nEstoque /*Em Estoque*/,; 
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
										PRDTMP->FILIAL /* Filial */,;
										PRDTMP->QTDSOL /*Quantidade Solicitada*/ } )
					endif
					
					PRDTMP->( DbSkip() )
				EndDo
			EndIf
			
			PRDTMP->( DbCloseArea() )
			
		EndIf
		
		for nX := 1 to len( _aProdFil )
			
			if ! _aProdFil[nX][3] == cProdAnt
				nIndGir := 0
			endif

			// Define a importância do produto conforme a unidade em que o mesmo tem um melhor índice de giro
			nIndGir  := Max(_aProdFil[nX][1], nIndGir )
			cProdAnt := _aProdFil[nX][3]

			// Obtém a classificação de giro do produto
			nGiro   := aScan( aGiros, {|x| nIndGir >= x[1] .and. nIndGir <= x[2] } )
			if nGiro > 0	// Se a classificação de giro não puder ser identificada, não exibe o produto
				if aScan( aColPro, {|x| x[nPosPrd] == _aProdFil[nX][3] } ) == 0
					aAdd( aColPro, { nIndGir,; 
									_aProdFil[nX][2],;
									_aProdFil[nX][3],;
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
									_aProdFil[nX][26],;
									_aProdFil[nX][15],;
									_aProdFil[nX][16],;
									_aProdFil[nX][17],;
									_aProdFil[nX][18],;
									_aProdFil[nX][19],;
									_aProdFil[nX][20],;
									_aProdFil[nX][21],;
									_aProdFil[nX][22],;
									_aProdFil[nX][23],;
									_aProdFil[nX][24] } )
					
					// Ponto de entrada que permite adicionar informações ao browse de produtos
					if lPEPNC05
						aPEPNC05 := ExecBlock( 'PEPNC05',.F.,.F., { aClone(aColPro[len(aColPro)]), 2 /* nLocal 1=Montagem do Header ou 2=Montagem do aCols*/ } )
						if ValType( aPEPNC05 ) == 'A' .and. len( aPEPNC05 ) > 0
							aColPro[len(aColPro)] := aClone( aPEPNC05 )
						endif
					endif

				else
					
					aColPro[aScan( aColPro, {|x| x[nPosPrd] == _aProdFil[nX][3] } )][nPosInc] := nIndGir
					aColPro[aScan( aColPro, {|x| x[nPosPrd] == _aProdFil[nX][3] } )][nPosNec] += _aProdFil[nX][6]			// Necessidade de Compra
					aColPro[aScan( aColPro, {|x| x[nPosPrd] == _aProdFil[nX][3] } )][nPosBlq] += _aProdFil[nX][7]			// Ped. Compra Bloq.
					aColPro[aScan( aColPro, {|x| x[nPosPrd] == _aProdFil[nX][3] } )][nPosQtd] += _aProdFil[nX][15]		// Quantidade Comprada
					aColPro[aScan( aColPro, {|x| x[nPosPrd] == _aProdFil[nX][3] } )][nPosSol] += _aProdFil[nX][26]		// Quantidade Solicitada
					aColPro[aScan( aColPro, {|x| x[nPosPrd] == _aProdFil[nX][3] } )][nPosEmE] += _aProdFil[nX][13]		// Quantidade de estoque atual
					aColPro[aScan( aColPro, {|x| x[nPosPrd] == _aProdFil[nX][3] } )][nPosCon] += _aProdFil[nX][10]		// Consumo médio
					aColPro[aScan( aColPro, {|x| x[nPosPrd] == _aProdFil[nX][3] } )][nPosEMi] += _aProdFil[nX][22]		// Estoque mínimo

					// Cálculo da duração do estoque com os pedidos de compra aprovados
					nPrjEst   := Round( ( aColPro[aScan( aColPro, {|x| x[nPosPrd] == _aProdFil[nX][3] } )][nPosEmE] -; 
										  aColPro[aScan( aColPro, {|x| x[nPosPrd] == _aProdFil[nX][3] } )][nPosEMi] +; 
										  aColPro[aScan( aColPro, {|x| x[nPosPrd] == _aProdFil[nX][3] } )][nPosQtd] ) /; 
										  aColPro[aScan( aColPro, {|x| x[nPosPrd] == _aProdFil[nX][3] } )][nPosCon], 0 )
					if nPrjEst > 999   
						nPrjEst := 999
					elseif nPrjEst < 0
						nPrjEst := 0
					EndIf

					aColPro[aScan( aColPro, {|x| x[nPosPrd] == _aProdFil[nX][3] } )][nPosDur] := nPrjEst					// Duração do estoque e da qtde comprada

					// Cálculo da duração prevista quando as quantidades bloqueadas forem liberadas
					nDurPrv := Round( ( aColPro[aScan( aColPro, {|x| x[nPosPrd] == _aProdFil[nX][3] } )][nPosEmE] +; 
									    aColPro[aScan( aColPro, {|x| x[nPosPrd] == _aProdFil[nX][3] } )][nPosQtd] +; 
										aColPro[aScan( aColPro, {|x| x[nPosPrd] == _aProdFil[nX][3] } )][nPosBlq] )/; 
										aColPro[aScan( aColPro, {|x| x[nPosPrd] == _aProdFil[nX][3] } )][nPosCon], 0 ) - _aProdFil[nX][16]
					if nDurPrv > 999 
						nDurPrv := 999
					elseif nDurPrv < 0
						nDurPrv := 0
					EndIf

					aColPro[aScan( aColPro, {|x| x[nPosPrd] == _aProdFil[nX][3] } )][nPosDuP] := nDurPrv					// Duração prevista (tira leadtime e soma quantidade bloqueada)

				endif
				
			endif

		next nX
	
	endif
    
	// Restaura a ordem padrão de busca de fornecedor
	// FORTMP->( DBSetOrder( 1 ) )
	// Devolve o posicionamento do fornecedor
	// FORTMP->( DbGoTo( nRecFor ) )
	aFullPro := aClone( aColPro )
	oBrwPro:SetArray(aColPro)
	oBrwPro:UpdateBrowse()
	
	// Apenas atualiza o browse de fornecedores quando a alteração não partir dele mesmo
	if !isInCallStack( 'A2LTMCHG' )
		oBrwFor:Refresh(.T. /* lGoTop */)
		oBrwFor:UpdateBrowse()
	endif

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
@param aConfig, array, vetor de configurações da central de compras
@return array, aRet[ cBetterSupplier, cBetterStore ]
/*/
static function betterSupplier( cProduto, aConfig, cFornece, cLoja )

	local aArea  := getArea()
	local aRet   := {"",""} as array
	local cQuery := "" as character
	local aRegs  := {} as array
	local nPrice := 0 as numeric
	local nLdTime := 0 as numeric

	default cFornece := ""
	default cLoja    := ""
	default cPedSol  := "1"

	if aConfig[22] == '1'		// Fabricante
		aRet := { RetField( 'SB1', 1, FWxFilial( 'SB1' ) + cProduto, 'B1_PROC' ),; 
				RetField( 'SB1', 1, FWxFilial( 'SB1' ) + cProduto, 'B1_LOJPROC' ) }
	else
		cQuery := qryAvgLt( cProduto, cFornece, cLoja )
		DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), 'REGFOR', .F., .T. )

		if !REGFOR->( EOF() )
			while ! REGFOR->( EOF() ) 
				nPrice  := priceSupplier( cProduto, REGFOR->A5_FORNECE, REGFOR->A5_LOJA )
				nLdTime := iif( REGFOR->( FieldPos( 'A2_X_LTIME' ) ) > 0 .AND. REGFOR->A2_X_LTIME > 0, REGFOR->A2_X_LTIME, REGFOR->PRAZOMEDIO )
				aAdd( aRegs, { REGFOR->A5_FORNECE,; 
								REGFOR->A5_LOJA,; 
								iif( nPrice == 0, 999999999.99, nPrice),; 
								nLdTime } )
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


/*/{Protheus.doc} qryAvgLt
Função para retornar a query que calcula o tempo médio de entrega de um produto com um fornecedor
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 4/22/2025
@param cProduto, character, ID do produto (obrigatório)
@param cFornece, character, ID do fornecedor (opcional)
@param cLoja, character, Loja do fornecedor (opcional)
@return character, cQuery
/*/
static function qryAvgLt( cProduto, cFornece, cLoja )

	local cQuery := "" as character

	default cFornece := "" 
	default cLoja    := "" 

	cQuery := "SELECT DISTINCT "
	cQuery += "   A5.A5_FORNECE, "
	cQuery += "   A5.A5_LOJA, "
	if SA2->( FieldPos( 'A2_X_LTIME' ) ) > 0
		cQuery += "   A2.A2_X_LTIME, "
	endif
	// cQuery += "   COALESCE(ROUND(( SUM(D1_TOTAL) - SUM(D1_DESC) ) / SUM(D1_QUANT), 2),0) VALORMEDIO, "
	if TCGetDB() == 'MSSQL'		// Conversao diferente quando banco for SQLServer
		cQuery += "   AVG(DATEDIFF(day,CONVERT(DATETIME,D1.D1_DTDIGIT,112),CONVERT(DATETIME,COALESCE(C7.C7_EMISSAO,D1.D1_DTDIGIT),112))) PRAZOMEDIO "
	else
		cQuery += "   AVG(TO_DATE(D1.D1_DTDIGIT,'YYYYMMDD') - TO_DATE(COALESCE(C7.C7_EMISSAO,D1.D1_DTDIGIT),'YYYYMMDD')) PRAZOMEDIO "
	endif
	cQuery += "FROM "+ RetSqlName( 'SA5' ) +" A5 "

	cQuery += "INNER JOIN "+ RetSqlName( 'SA2' ) +" A2 "
	cQuery += " ON A2.A2_COD     = A5.A5_FORNECE "
	cQuery += "AND A2.A2_LOJA    = A5.A5_LOJA "
	cQuery += "AND A2.A2_MSBLQL  <> '1' "		// Evita considerar fornecedores bloqueados
	cQuery += "AND A2.D_E_L_E_T_ = ' ' "

	cQuery += "LEFT JOIN "+ RetSqlName( 'SD1' ) +" D1 "
	cQuery += " ON D1.D1_TIPO    = 'N' "							// Apenas notas do tipo normal
	cQuery += "AND D1.D1_COD     = A5.A5_PRODUTO "				    // Apenas o produto selecionado
	cQuery += "AND D1.D1_FORNECE = A5.A5_FORNECE "
	cQuery += "AND D1.D1_LOJA    = A5.A5_LOJA "
	cQuery += "AND D1.D_E_L_E_T_ = ' ' "

	cQuery += "LEFT JOIN "+ RetSqlName( 'SC7' ) +" C7 "
	cQuery += " ON C7.C7_FILIAL  = D1.D1_FILIAL "
	cQuery += "AND C7.C7_NUM     = D1.D1_PEDIDO "
	cQuery += "AND C7.C7_ITEM    = D1.D1_ITEMPC "
	cQuery += "AND C7.D_E_L_E_T_ = ' ' "

	cQuery += "WHERE A5.A5_PRODUTO = '"+ cProduto +"' "				// Apenas o produto selecionado
	if ! Empty( cFornece )
		cQuery += " AND A5.A5_FORNECE = '"+ cFornece +"' "
	endif
	if ! Empty( cLoja )
		cQuery += " AND A5.A5_LOJA    = '"+ cLoja +"' "
	endif
	cQuery += "  AND A5.D_E_L_E_T_ = ' ' "
	cQuery += "GROUP BY A5.A5_FORNECE, A5.A5_LOJA "
	
	// Se incluiu na query, precisa incluir no group by
	if SA2->( FieldPos( 'A2_X_LTIME' ) ) > 0
		cQuery += ", A2.A2_X_LTIME "
	endif

return cQuery

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

/*/{Protheus.doc} x
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
	local nFil      := 0 as numeric
	local aLinFil   := {} as array
	local cFilHist  := cFilAnt
	local nQtdSeg   := 0 as numeric
	local nPrcSeg   := 0 as numeric
	local cSegUM    := "" as character
	local cTpFator  := "" as character
	local nFator    := 0 as numeric

	// Valida se a quantidade do produto sinalizado é maior que zero
	if ! aColPro[oBrwPro:At()][nPosNec] > 0
		Hlp( 'QUANTIDADE ZERO',; 
			'A quantidade a ser comprada do produto '+ AllTrim( aColPro[oBrwPro:At()][nPosPrd] ) +' é "zero"',;
			'Não é possível adicionar um produto ao carrinho sem definir a quantidade a ser comprada!' )
		Return Nil
	elseif ( Empty( aColPro[oBrwPro:At()][nPosFor] ) .or. Empty( aColPro[oBrwPro:At()][nPosLoj] ) ) .and. _cPedSol == '1'
		if Empty( supplyerChoice( .T. /* lForce */ ) )
			Hlp( 'NO_SUPPLYER',;
				 'Não é possível enviar um produto ao carrinho de compras sem antes definir o fornecedor',;
				 'Utilize o atalho F4, selecione um dos fornecedores com vínculo ao produto e tente novamente.' )
			Return Nil
		endif
	endif

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
			aAdd( aLinCar, iif( !Empty( aConfig[26] ), aConfig[26], RetField( 'SB1', 1, xFilial( 'SB1' ) + aColPro[oBrwPro:nAt][nPosPrd], 'B1_LOCPAD' ) ) )
			aAdd( aLinCar, Space( TAMSX3( 'C7_OBS' )[01] ) )
			cSegUM   := RetField( 'SB1', 1, FWxFilial( 'SB1' ) + aColPro[oBrwPro:nAt][nPosPrd], 'B1_SEGUM' )
			cTpFator := RetField( 'SB1', 1, FWxFilial( 'SB1' ) + aColPro[oBrwPro:nAt][nPosPrd], 'B1_TIPCONV' )
			nFator   := RetField( 'SB1', 1, FWxFilial( 'SB1' ) + aColPro[oBrwPro:nAt][nPosPrd], 'B1_CONV' )
			aAdd( aLinCar, cSegUM )
			nQtdSeg := ConvUM( aColPro[oBrwPro:nAt][nPosPrd],; 
								  aColPro[oBrwPro:nAt][nPosNec],;
								  0 /* nQtdSeg */,;
								  2 /* nRetQtd */ )
			aAdd( aLinCar, nQtdSeg )
			if nQtdSeg > 0
				if cTpFator == 'M'
					nPrcSeg := ( aColPro[oBrwPro:nAt][nPosNeg] / nFator ) * nQtdSeg
				else
					nPrcSeg := ( aColPro[oBrwPro:nAt][nPosNeg]* nFator ) * nQtdSeg
				endif
			else
				nPrcSeg := 0
			endif
			aAdd( aLinCar, Round( nPrcSeg, 2 ) )
			aAdd( aLinCar, Space( TAMSX3( 'C7_CC'  )[1] ) /* cCC */ )
			aAdd( aLinCar, RetField( 'SB1', 1, xFilial( 'SB1' ) + aColPro[oBrwPro:nAt][nPosPrd], 'B1_IPI' ) )
			aAdd( aLinCar, 0 )		// Valor desconto
			aAdd( aLinCar, aColPro[oBrwPro:nAt][nPosFor] )
			aAdd( aLinCar, aColPro[oBrwPro:nAt][nPosLoj] )

			if lUsaFrete
				aAdd( aLinCar, 0 )
			endif
			aAdd( aLinCar, .F. )

			// Prepara vetores para carrinho de compra por produto e por filial
			for nFil := 1 to len( _aFil )
				cFilAnt := _aFil[nFil]
				nProdFil := aScan( _aProdFil, {|x| x[3] == aLinCar[carPos('C7_PRODUTO')] .and. x[25] == AllTrim(_aFil[nFil]) } )
				if nProdFil > 0 .and. _aProdFil[nProdFil][6] > 0
					aLinFil     := aClone( aLinCar )
					aLinFil[carPos('QUANT')]  := _aProdFil[nProdFil][6]
					aLinFil[carPos('TOTAL')]  := aLinFil[carPos('QUANT')] * aLinFil[carPos('PRECO')]
					aLinFil[carPos('C7_LOCAL')]  := iif( !Empty( aConfig[26] ), aConfig[26], RetField( 'SB1', 1, FWxFilial( 'SB1' ) + aLinFil[carPos('C7_PRODUTO')], 'B1_LOCPAD' ) )
					nQtdSeg     := ConvUM( aColPro[oBrwPro:nAt][nPosPrd],; 
											aLinFil[carPos('QUANT')],;
											0 /* nQtdSeg */,;
											2 /* nRetQtd */ )
					aLinFil[carPos('QTSEGUM')] := nQtdSeg 
					if nQtdSeg > 0
						nPrcSeg := aLinFil[carPos('TOTAL')] / nQtdSeg
					else
						nPrcSeg := 0
					endif
					aLinFil[carPos('VALSEGUM')]   := Round( nPrcSeg, 2 )
					aAdd( aLinFil, _aFil[nFil] )

					aAdd( aCarFil, aClone( aLinFil ) )
					aLinFil := {}
				endif
				// Atualiza perfil de cálculo do produto automaticamente para que o sistema saiba qual perfil de cálculo o produto utiliza
				// durante os recálculos feitos de maneira automática
				DBSelectArea( 'SB1' )
				SB1->( DBSetOrder( 1 ) )
				if SB1->( DBSeek( FWxFilial( 'SB1' ) + aColPro[oBrwPro:nAt][nPosPrd] ) )
					if ! SB1->B1_X_PERCA == cPerfil
						RecLock( 'SB1', .F. )
						SB1->B1_X_PERCA := cPerfil
						SB1->( MsUnlock() )
					endif
				endif
			next nFil
			cFilAnt := cFilHist

			aAdd( aCarCom, aClone( aLinCar ) )
			aLinCar := {}

			lInclui := .T.
			cForLoj := aColPro[oBrwPro:nAt][nPosFor] + aColPro[oBrwPro:nAt][nPosLoj]
		Else

			// Elimina do carrinho por filial
			for nFil := 1 to len( _aFil )
				nProdFil := aScan( aCarFil, {|x| x[carPos('C7_PRODUTO')] == aColPro[oBrwPro:nAt][nPosPrd] .and. x[len(x)] == _aFil[nFil] } )
				if nProdFil > 0
					aDel( aCarFil, nProdFil )
					aSize( aCarFil, len( aCarFil )-1 )
				endif
			next nFil

			cForLoj := aColPro[oBrwPro:nAt][nPosFor] + aColPro[oBrwPro:nAt][nPosLoj]
			aDel( aCarCom, aScan( aCarCom, {|x| x[carPos('C7_PRODUTO')] == aColPro[oBrwPro:nAt][nPosPrd] .and.;
												x[carPos('C7_FORNECE')] == aColPro[oBrwPro:nAt][nPosFor] .and.;
												x[carPos('C7_LOJA')] == aColPro[oBrwPro:nAt][nPosLoj] } ) ) 
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
		Elseif !lInclui .and. aScan( aCarCom, {|x| x[carPos('C7_FORNECE')] + x[carPos('C7_LOJA')] == cForLoj } ) == 0
			if FORTMP->( DBSeek( cForLoj ) ) .and. FORTMP->PEDIDO == 'S'
				RecLock( 'FORTMP', .F. )
				FORTMP->PEDIDO := 'N'
				FORTMP->( MsUnlock() )
			endif
		EndIf
	EndIf
	
	cFilAnt := cFilHist
	oBrwFor:UpdateBrowse()
	oBrwPro:LineRefresh()
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
	Local nX        := 0
	local nLeadTime := 0  as numeric
	local cLeadTime := 0  as character
	local nPrjEst   := 0  as numeric
	local nDurPrv   := 0  as numeric
	local aInfPrd   := {} as array
	local nQtdCom   := 0  as numeric
	local nAux      := 0 as numeric
	local nEstSeg   := 0 as numeric
	
	Private oBtnSel     := Nil
	Private lMsErroAuto := .F.

	if oBrwPro:oBrowse != Nil
		nColAtu := oBrwPro:ColPos()
		DbSelectArea( 'SB1' )
		if SB1->( FieldPos( oBrwPro:GetColumn(oBrwPro:ColPos()):GetID() ) ) > 0
			SB1->( DbSetOrder( 1 ) )
			
			If DbSeek( FWxFilial( 'SB1' ) + aColPro[oBrwPro:nAt][nPosPrd] )
				
				// Compara a informação em memória com a informação gravada no cadastro do produto pra ver se é diferente
				if ( &( 'SB1->'+ oBrwPro:GetColumn(oBrwPro:ColPos()):GetID() ) != aColPro[oBrwPro:At()][nColAtu] )  

					aAdd( aVetPrd, { "B1_FILIAL", xFilial( 'SB1' ), Nil } )
					aAdd( aVetPrd, { "B1_COD"   , aColPro[oBrwPro:nAt][nPosPrd], Nil } )
					aAdd( aVetPrd, { oBrwPro:GetColumn(oBrwPro:ColPos()):GetID(), aColPro[oBrwPro:At()][nColAtu], Nil } )
					
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

		if oBrwPro:GetColumn(oBrwPro:ColPos()):GetID() == "A5_FORNECE"	// Quando a alteração for em um fornecedor
			
			// Apenas atualiza dados do fornecedor e da relação de produto x fornecedor quando o conteúdo do campo não for vazio
			if ! Empty( aColPro[oBrwPro:At()][nPosFor] )

				// Loja do fornecedor
				aColPro[oBrwPro:At()][nPosLoj] := SA2->A2_LOJA

				DBSelectArea( "FORTMP" )
				FORTMP->( DBSetOrder( 2 ) )		// Fornecedor e Loja
				if ! FORTMP->( DBSeek( aColPro[oBrwPro:At()][nPosFor] + aColPro[oBrwPro:At()][nPosLoj] ) )
					
					// Fornecedor
					aFullPro[ aScan( aFullPro, {|x| x[nPosPrd] == aColPro[oBrwPro:nAt][nPosPrd] } ) ] := aClone( aColPro[oBrwPro:nAt] )

					RecLock( 'FORTMP', .T. )
					FORTMP->MARK        := cMarca
					FORTMP->A2_COD      := aColPro[oBrwPro:At()][nPosFor]
					FORTMP->A2_LOJA     := aColPro[oBrwPro:At()][nPosLoj]
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
					FORTMP->PEDIDO := iif( aScan( aCarCom, {|x| x[carPos('C7_FORNECE')]+x[carPos('C7_LOJA')] == FORTMP->A2_COD + FORTMP->A2_LOJA } ) > 0, 'S', 'N' )
					FORTMP->( MsUnlock() )
					oBrwFor:UpdateBrowse()
				endif

				// Atualiza o vínculo entre produto e fornecedor, quando necessário
				updProFor( aColPro[oBrwPro:nAt][nPosPrd] /* cProduto */,;
						aColPro[oBrwPro:At()][nPosFor] /* cFornece */,;
						aColPro[oBrwPro:At()][nPosLoj] /* cLoja */ )

				// Quando usuário não alterou o preço negociado, atualiza o conteúdo do campo do preço conforme tabela de preço do novo fornecedor ou preço historico do novo fornecedor
				if aColPro[oBrwPro:nAt][nPosUlt] == aColPro[obrwPro:nAt][nPosNeg]

					aColPro[oBrwPro:nAt][nPosUlt] := priceSupplier( aColPro[ oBrwPro:nAt ][ nPosPrd ], aColPro[oBrwPro:At()][nPosFor], aColPro[oBrwPro:At()][nPosLoj] )
					aColPro[obrwPro:nAt][nPosNeg] := aColPro[oBrwPro:nAt][nPosUlt]
					// Ajusta também o vetor de backup para que, em caso de restauração, a informação esteja atualizada
					aFullPro[ aScan( aFullPro, {|x| x[nPosPrd] == aColPro[ oBrwPro:nAt ][ nPosPrd ] } ) ] := aClone( aColPro[ oBrwPro:nAt ] )
					// Se o produto já estiver no carrinho de compras, ajusta o valor também no carrinho
					if aScan( aCarCom, {|x| AllTrim( x[carPos('C7_PRODUTO')] ) == AllTrim( aColPro[ oBrwPro:nAt ][ nPosPrd ] ) } ) > 0
						aCarCom[ aScan( aCarCom, {|x| AllTrim( x[carPos('C7_PRODUTO')] ) == AllTrim( aColPro[ oBrwPro:nAt ][ nPosPrd ] ) } ) ][ carPos('PRECO') ] := aColPro[obrwPro:nAt][nPosNeg]
						aCarCom[ aScan( aCarCom, {|x| AllTrim( x[carPos('C7_PRODUTO')] ) == AllTrim( aColPro[ oBrwPro:nAt ][ nPosPrd ] ) } ) ][ carPos('TOTAL') ] := aColPro[oBrwPro:At()][nPosNec] * aColPro[oBrwPro:nAt][nPosNeg]
					endif
					for nX := 1 to len( _aFil )
						nAux := aScan(_aProdFil,{|x| x[3] == aColPro[ oBrwPro:nAt ][ nPosPrd ] .and. x[25] == _aFil[nX] })
						_aProdFil[ nAux ][8] := aColPro[oBrwPro:At()][nPosNeg]
						_aProdFil[ nAux ][9] := aColPro[oBrwPro:At()][nPosUlt]
					next nX

					for nX := 1 to len( _aFil )
						nAux := aScan(_aProdFil,{|x| x[3] == aColPro[ oBrwPro:nAt ][ nPosPrd ] .and. x[25] == _aFil[nX] })
						if aScan( aCarFil, {|x| x[carPos('C7_PRODUTO')] == aColPro[ oBrwPro:nAt ][ nPosPrd ] .and. x[len(x)] == _aFil[nX] } ) > 0
							aCarFil[ aScan( aCarFil, {|x| x[carPos('C7_PRODUTO')] == aColPro[ oBrwPro:nAt ][ nPosPrd ] .and. x[len(x)] == _aFil[nX] } ) ][carPos('PRECO')] := _aProdFil[nAux][8]
							aCarFil[ aScan( aCarFil, {|x| x[carPos('C7_PRODUTO')] == aColPro[ oBrwPro:nAt ][ nPosPrd ] .and. x[len(x)] == _aFil[nX] } ) ][carPos('TOTAL')] := ;
								aCarFil[ aScan( aCarFil, {|x| x[carPos('C7_PRODUTO')] == aColPro[oBrwPro:nAt][nPosPrd] .and. x[len(x)] == _aFil[nX] } ) ][carPos('PRECO')] * _aProdFil[nAux][carPos('TOTAL')]
						endif
					next nX

				endif

			endif

		endif
		
		if nColAtu == nPosNec						// Alteração no campo de necessidade de compra
			
			if aScan( aCarCom, {|x| AllTrim( x[carPos('C7_PRODUTO')] ) == AllTrim( aColPro[ oBrwPro:nAt ][ nPosPrd ] ) } ) > 0

				// Quando a compra não for multi-filial, foi permitida a edição diretamente no grid principal
				if len( _aFil ) == 1 .and. _aFil[1] == cFilAnt
					// Valida se quantidade do browse de produtos é diferente da quantidade do vetor x filial
					if aColPro[oBrwPro:At()][nPosNec] != _aProdFil[aScan(_aProdFil,{|x| x[3] == aColPro[oBrwPro:At()][nPosPrd] .and. x[25] == _aFil[1] })][6]
						_aProdFil[aScan(_aProdFil,{|x| x[3] == aColPro[oBrwPro:At()][nPosPrd] .and. x[25] == _aFil[1] })][6] := aColPro[oBrwPro:At()][nPosNec]
					endif
				endif
				
				aCarCom[ aScan( aCarCom, {|x| AllTrim( x[carPos('C7_PRODUTO')] ) == AllTrim( aColPro[ oBrwPro:nAt ][ nPosPrd ] ) } ) ][ carPos('QUANT') ] := aColPro[oBrwPro:At()][nPosNec]
				aCarCom[ aScan( aCarCom, {|x| AllTrim( x[carPos('C7_PRODUTO')] ) == AllTrim( aColPro[ oBrwPro:nAt ][ nPosPrd ] ) } ) ][ carPos('TOTAL') ] := aColPro[oBrwPro:At()][nPosNec] * aColPro[oBrwPro:nAt][nPosNeg]
				
				for nX := 1 to len( _aFil )
					nAux := aScan(_aProdFil,{|x| x[3] == aColPro[ oBrwPro:nAt ][ nPosPrd ] .and. x[25] == _aFil[nX] .and. x[23] == aColPro[ oBrwPro:nAt ][ nPosFor ] .and. x[24] == aColPro[ oBrwPro:nAt ][ nPosLoj ] })
					_aProdFil[ nAux ][6] := aColPro[oBrwPro:At()][nPosNec]
				next nX

				for nX := 1 to len( _aFil )
					nAux := aScan(_aProdFil,{|x| x[3] == aColPro[ oBrwPro:nAt ][ nPosPrd ] .and. x[25] == _aFil[nX] })
					if aScan( aCarFil, {|x| x[carPos('C7_PRODUTO')] == aColPro[ oBrwPro:nAt ][ nPosPrd ] .and. x[len(x)] == _aFil[nX] } ) > 0
						aCarFil[ aScan( aCarFil, {|x| x[carPos('C7_PRODUTO')] == aColPro[ oBrwPro:nAt ][ nPosPrd ] .and. x[len(x)] == _aFil[nX] } ) ][carPos('QUANT')] := _aProdFil[nAux][6]
						aCarFil[ aScan( aCarFil, {|x| x[carPos('C7_PRODUTO')] == aColPro[ oBrwPro:nAt ][ nPosPrd ] .and. x[len(x)] == _aFil[nX] } ) ][carPos('TOTAL')] := aCarFil[ aScan( aCarFil, {|x| x[carPos('C7_PRODUTO')] == aColPro[oBrwPro:nAt][nPosPrd] .and. x[len(x)] == _aFil[nX] } ) ][carPos('PRECO')] * _aProdFil[nAux][carPos('TOTAL')]
					endif
				next nX

				// Ajusta também o vetor de backup para que, em caso de restauração, a informação esteja atualizada
				aFullPro[ aScan( aFullPro, {|x| x[nPosPrd] == aColPro[ oBrwPro:nAt ][ nPosPrd ] } ) ] := aClone( aColPro[ oBrwPro:nAt ] )

			else
				// Quando a compra não for multi-filial, foi permitida a edição diretamente no grid principal
				if len( _aFil ) == 1 .and. _aFil[1] == cFilAnt
					// Valida se quantidade do browse de produtos é diferente da quantidade do vetor x filial
					if aColPro[oBrwPro:At()][nPosNec] != _aProdFil[aScan(_aProdFil,{|x| x[3] == aColPro[oBrwPro:At()][nPosPrd] .and. x[25] == _aFil[1] })][6]
						_aProdFil[aScan(_aProdFil,{|x| x[3] == aColPro[oBrwPro:At()][nPosPrd] .and. x[25] == _aFil[1] })][6] := aColPro[oBrwPro:At()][nPosNec]
					endif
				endif
			EndIf
		ElseIf nColAtu == nPosNeg					// Alteração no campo do valor negociado
			
			if aScan( aCarCom, {|x| AllTrim( x[carPos('C7_PRODUTO')] ) == AllTrim( aColPro[ oBrwPro:nAt ][ nPosPrd ] ) } ) > 0

				aCarCom[ aScan( aCarCom, {|x| AllTrim( x[carPos('C7_PRODUTO')] ) == AllTrim( aColPro[ oBrwPro:nAt ][ nPosPrd ] ) } ) ][ carPos('PRECO') ] := aColPro[oBrwPro:nAt][nPosNeg]
				aCarCom[ aScan( aCarCom, {|x| AllTrim( x[carPos('C7_PRODUTO')] ) == AllTrim( aColPro[ oBrwPro:nAt ][ nPosPrd ] ) } ) ][ carPos('TOTAL') ] := aColPro[oBrwPro:nAt][nPosNec] * aColPro[oBrwPro:nAt][nPosNeg]

				for nX := 1 to len( _aFil )
					nAux := aScan(_aProdFil,{|x| x[3] == aColPro[ oBrwPro:nAt ][ nPosPrd ] .and. x[25] == _aFil[nX] .and. x[23] == aColPro[ oBrwPro:nAt ][ nPosFor ] .and. x[24] == aColPro[ oBrwPro:nAt ][ nPosLoj ] })
					_aProdFil[ nAux ][8] := aColPro[oBrwPro:At()][nPosNeg]
				next nX

				for nX := 1 to len( _aFil )
					nAux := aScan(_aProdFil,{|x| x[3] == aColPro[ oBrwPro:nAt ][ nPosPrd ] .and. x[25] == _aFil[nX] })	
					if aScan( aCarFil, {|x| x[carPos('C7_PRODUTO')] == aColPro[ oBrwPro:nAt ][ nPosPrd ] .and. x[len(x)] == _aFil[nX] } ) > 0 
						aCarFil[ aScan( aCarFil, {|x| x[carPos('C7_PRODUTO')] == aColPro[ oBrwPro:nAt ][ nPosPrd ] .and. x[len(x)] == _aFil[nX] } ) ][carPos('PRECO')] := aColPro[oBrwPro:nAt][nPosNeg] 
						aCarFil[ aScan( aCarFil, {|x| x[carPos('C7_PRODUTO')] == aColPro[ oBrwPro:nAt ][ nPosPrd ] .and. x[len(x)] == _aFil[nX] } ) ][carPos('TOTAL')] := aColPro[oBrwPro:nAt][nPosNeg] * _aProdFil[nAux][6]
					endif
				next nX

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

				// Estoque de segurança
				nEstSeg := RetField( "SB1", 1, FWxFilial( 'SB1' )+ aColPro[ oBrwPro:nAt ][ nPosPrd ], "B1_EMIN" )

				// Atualiza os dados da linha do produto conforme alterações realizadas no campo do lead-time
				// Cálculo da duração do estoque com os pedidos de compra aprovados
				nPrjEst := Round( ( aColPro[ oBrwPro:nAt ][ nPosEmE ] - ;
									iif( aConfig[24] == 'S', aColPro[ oBrwPro:nAt ][ nPosVen ], 0 ) + ;
									aColPro[ oBrwPro:nAt ][ nPosQtd ] - ;
									nEstSeg )/ ;
									aColPro[ oBrwPro:nAt ][ nPosCon ], 0 )
				if nPrjEst > 999 
					nPrjEst := 999
				elseif nPrjEst < 0
					nPrjEst := 0
				EndIf
				
				// Cálculo da duração prevista quando as quantidades bloqueadas forem liberadas
				nDurPrv := Round( ( aColPro[ oBrwPro:nAt ][ nPosEmE ] - ;
									aColPro[ oBrwPro:nAt ][ nPosVen ] + ;
									aColPro[ oBrwPro:nAt ][ nPosQtd ] + ;
									aColPro[ oBrwPro:nAt ][ nPosBlq ] - ;
									nEstSeg )/ ;
									aColPro[ oBrwPro:nAt ][ nPosCon ], 0 ) - nLeadTime
				if nDurPrv > 999 
					nDurPrv := 999
				elseif nDurPrv < 0
					nDurPrv := 0
				EndIf
				
				aInfPrd := { nSpinBx /*nDias de programação de estoque*/,;
							nLeadTime /*nLdTime*/,;
							nPrjEst,;
							aColPro[ oBrwPro:nAt ][ nPosCon ] /*nConMed*/,;
							aColPro[ oBrwPro:nAt ][ nPosLtM ] /*nLotMin*/,;
							aColPro[ oBrwPro:nAt ][ nPosQtE ] /*nQtdEmb*/,;
							aColPro[ oBrwPro:nAt ][ nPosLtE ] /* nLotEco */,;
							nEstSeg /* nEstSeg */,;
							aColPro[ oBrwPro:nAt ][ nPosEmE ] /* nQtdEst */,;
							aColPro[ oBrwPro:nAt ][ nPosVen ] /* nQtdEmp */,;
							aColPro[ oBrwPro:nAt ][ nPosQtd ] /* nQtdCom */,;
							aColPro[ oBrwPro:nAt ][ nPosSol ] /* nQtdSol */ }
				
				// Função que calcula a necessidade de compra
				nQtdCom := fCalNec( aInfPrd, cPerfil )
				aColPro[ oBrwPro:nAt ][ nPosNec ] := nQtdCom
				aColPro[ oBrwPro:nAt ][ nPosDur ] := nPrjEst
				aColPro[ oBrwPro:nAt ][ nPosDuP ] := nDurPrv
				aColPro[ oBrwPro:nAt ][ nPosLdT ] := nLeadTime
				aColPro[ oBrwPro:nAt ][ nPosTLT ] := cLeadTime

			else
				lReturn := .F.
			endif

		EndIf
		
		If nColAtu == nPosBlq

			// Quando a compra não for multi-filial, foi permitida a edição diretamente no grid principal
			if len( _aFil ) == 1 .and. _aFil[1] == cFilAnt
				// Valida se quantidade do browse de produtos é diferente da quantidade do vetor x filial
				if aColPro[oBrwPro:At()][nPosBlq] != _aProdFil[aScan(_aProdFil,{|x| x[3] == aColPro[oBrwPro:At()][nPosPrd] .and. x[25] == _aFil[1] })][7]
					_aProdFil[aScan(_aProdFil,{|x| x[3] == aColPro[oBrwPro:At()][nPosPrd] .and. x[25] == _aFil[1] })][7] := aColPro[oBrwPro:At()][nPosBlq]
				endif
			endif
			
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
							If oNewGrid:aCols[nX][carPos('QUANT')] > 0 
								
								// Verifica se a quantidade no grid para o item do pedido é diferente da quantidade atual do item no pedido
								if oNewGrid:aCols[nX][carPos('QUANT')] != SC7->C7_QUANT
								
									aAdd( aLin, { "C7_ITEM"    , oNewGrid:aCols[nX][nPosIte], Nil } )
									aAdd( aLin, { "C7_PRODUTO" , SC7->C7_PRODUTO, Nil } )
									aAdd( aLin, { "C7_QUANT"   , oNewGrid:aCols[nX][carPos('QUANT')], Nil } )
									aAdd( aLin, { "C7_PRECO"   , SC7->C7_PRECO, Nil } )
									aAdd( aLin, { "C7_TOTAL"   , SC7->C7_PRECO * oNewGrid:aCols[nX][carPos('QUANT')], Nil } ) 
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
				If DbSeek( aChvSC7[1] )
					
					aIte := {}
					aCab := {}
					aAdd( aCab, { "C7_FILIAL"  , SubStr( aChvSC7[1], 01, TAMSX3('C7_FILIAL')[1] ) } )
					aAdd( aCab, { "C7_NUM"     , SubStr( aChvSC7[1], TAMSX3('C7_FILIAL')[1]+1, TAMSX3("C7_NUM")[1] ) } )
					aadd( aCab, { "C7_EMISSAO" , SC7->C7_EMISSAO })
					aadd( aCab, { "C7_FORNECE" , SC7->C7_FORNECE })
					aadd( aCab, { "C7_LOJA"    , SC7->C7_LOJA })
					aadd( aCab, { "C7_COND"    , SC7->C7_COND })
					aadd( aCab, { "C7_CONTATO" , SC7->C7_CONTATO })
					aadd( aCab, { "C7_FILENT"  , SubStr( aChvSC7[1], 01, TAMSX3('C7_FILENT')[1] ) } )
					
					aLin := {}
					If aColPro[oBrwPro:At()][nPosBlq] > 0
						
						aAdd( aLin, { "C7_ITEM"   , SubStr( aChvSC7[1], TAMSX3('C7_FILIAL')[1]+TAMSX3("C7_NUM")[1]+1, TAMSX3("C7_ITEM")[1] ), Nil } )
						aAdd( aLin, { "C7_PRODUTO", SC7->C7_PRODUTO, Nil } )
						aAdd( aLin, { "C7_QUANT"  , aColPro[oBrwPro:At()][nPosBlq], Nil } )
						aAdd( aLin, { "C7_PRECO"  , SC7->C7_PRECO, Nil } )
						aAdd( aLin, { "C7_TOTAL"  , SC7->C7_PRECO * aColPro[oBrwPro:At()][nPosBlq], Nil } )
						aAdd( aLin, { "C7_CONAPRO", SC7->C7_CONAPRO, Nil } )
						aAdd( aLin, { "C7_REC_WT" , SC7->(Recno()), Nil } )
						
					Else
						
						aAdd( aLin, { "C7_ITEM"   , SubStr( aChvSC7[1], TAMSX3('C7_FILIAL')[1]+TAMSX3("C7_NUM")[1]+1, TAMSX3("C7_ITEM")[1] ), Nil } )
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
						MsgInfo( "O item "+ SubStr( aChvSC7[1], TAMSX3('C7_FILIAL')[1]+TAMSX3("C7_NUM")[1]+1, TAMSX3("C7_ITEM")[1] ) +" do pedido "+; 
						         SubStr( aChvSC7[1], TAMSX3('C7_FILIAL')[1]+1, TAMSX3("C7_NUM")[1] ) +" foi alterado, pressione <b>F5</b> quando quiser atualizar "+;
						         "as informações do grid!","Pronto!" )
					EndIf
					
				EndIf

			Else
				Hlp( 'NOPEDPEND',;
					 'Não foram encontrados pedidos pendentes referente a este produto com seu respectivo fornecedor',;
					 'A edição pode ser realizada apenas quando há pedidos com saldo pendente de aprovação' )
				// Restaura quantidade anterior à edição do campo
				aColPro[oBrwPro:nAt][nPosBlq] := _nQtBlq
				lReturn := .T.
			EndIf

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
	If ( cAliCfg )->( DbSeek( FWxFilial( cAliCfg ) ) )
		
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
		if ( cAliCfg )->( FieldPos( cAliCfg + '_PRILE'  ) ) > 0	// [19] - Indica se prioriza lote econômico para sugestão da quantidade de compra
			aAdd( aConfig, &( cPref + 'PRILE'  ) )		
		else
			aAdd( aConfig, 'S' )					// [19] - Indica se prioriza lote econômico para sugestão da quantidade de compra
		endif

		if ( cAliCfg )->( FieldPos( cAliCfg + '_CRIT' ) ) > 0
			aAdd( aConfig, StrTran( &( cPref + 'CRIT' ), ' ', '1' ) )		// Default 1=preço
		else
			aAdd( aConfig, '1' )					// [20] - Critério de escolha do melhor fornecedor 1=Preço 2=L.Time
		endif

		if ( cAliCfg )->( FieldPos( cAliCfg + '_TIPOS' ) ) > 0 .and. ! Empty( &( cPref + 'TIPOS' ) )
			aAdd( aConfig, &( cPref + 'TIPOS' ) )
		else
			aAdd( aConfig, 'MP/ME' )				// [21] - Tipos de produtos a serem considerados para a central de compras separados por "/"
		endif

		if ( cAliCfg )->( FieldPos( cAliCfg + '_RELFOR' ) ) > 0 .and. !Empty( &( cPref + 'RELFOR' ) )
			aAdd( aConfig, &( cPref + 'RELFOR' ) )
		else
			aAdd( aConfig, '1' )					// [22] - Indica a relação entre os produtos e o fornecedor (1=Fabricante 2=Prod.x Fornecedor ou 3=Hist.Compra)
		endif

		if ( cAliCfg )->( FieldPos( cAliCfg + '_MAILWF' ) ) > 0
			aAdd( aConfig, &( cPref + 'MAILWF' ) )	// [23] - E-mail para envio de notificações de workflow
		else
			aAdd( aConfig, " " )
		endif

		if ( cAliCfg )->( FieldPos( cAliCfg + '_EMSATU' ) ) > 0
			aAdd( aConfig, StrTran(&( cPref + 'EMSATU' )," ", "S" ) )	// [24] - Indica se deve deduzir empenho para compor o saldo atual do produto (default "S")
		else
			aAdd( aConfig, "S" )
		endif

		if ( cAliCfg )->( FieldPos( cAliCfg + '_DHIST' ) ) > 0 .and. &( cPref + 'DHIST' ) > 0
			aAdd( aConfig, &( cPref + 'DHIST' ) )						// [25] - Indica o tempo em dias que o sistema deve manter gravado referente aos cálculos executados por produto
		else
			aAdd( aConfig, 30 )
		endif

		if ( cAliCfg )->( FieldPos( cAliCfg + '_LOCPAD' ) ) > 0
			aAdd( aConfig, &( cPref + 'LOCPAD' ) )						// [26] - Indica um ID de armazém padrão (NNR) para compras quando o armazém utilizado pela empresa for diferente do armazém padrão do produto
		endif

		if ( cAliCfg )->( FieldPos( cAliCfg + '_TPDOC' ) ) > 0
			aAdd( aConfig, iif( Empty( &( cPref + 'TPDOC' ) ), '1', &( cPref + 'TPDOC' ) ) )	// [27] - Indica o tipo de documento que será gerado no ato do fechamento do carrinho
		else
			aAdd( aConfig, '1' )
		endif

		// Inicializa variáveis do workspace
		nSpinBx  := aConfig[01]			// Pré-definição dias de estoque
		lGir001  := aConfig[02]			// Pré-definição itens críticos
		lGir002  := aConfig[03]			// Pré-definição itens alto giro
		lGir003  := aConfig[04]			// Pré-definição itens médio giro
		lGir004  := aConfig[05]			// Pré-definição itens baixo giro
		lGir005  := aConfig[06]			// Pré-definições itens sem giro
		// lGir006 := aConfig[07]			// Pré-definições itens sob demanda
		cCboAna  := aConfig[08]			// Pré-definições tipo de análise de sazonalidade
		nGetQtd  := aConfig[09]			// Pré-definições da qtde de períodos analisados

		// Atualiza apenas na primeira vez
		if Empty( _cPedSol )
			_cPedSol := aConfig[27]			// Tipo de documento a ser gerado no fechamento do carrinho 1-Pedido 2-Solicitação ou 3-Usuário Escolhe
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
	local nQtdProd  := 0 as numeric
	local nQtdDoc   := 0 as numeric
	Local nConMed   := 0
	Local lEvento   := .F.
	Local cMsg      := ""
	Local nPrjEst   := 0
	local dPrjAux   := StoD(" ")
	local lWF       := .F. as logical
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
	local aAuxWF    := {} as array
	local oProcess  as object
	local oHTML     as object
	local cDtTime   as character
	local lManual   := .F. as logical
	local cFornece  := "" as character
	local cLoja     := "" as character
	Local aAux      := {} as array
	local nVenda    := 0 as numeric
	local nConsumo  := 0 as numeric
	local lInclui   := .F. as logical
	local aPerProd  := {} as array 
	local dDataAux  as date
	local nDiasAux  := 0 as numeric
	local nDiasTot  := 0 as numeric
	local nTempo    := 0 as numeric
	local nX        := 0 as numeric
	local aDataWF   := {} as array
	local nLin      := 0 as numeric
	local cColor    := "" as character
	local nQtdAtual := 0 as numeric
	local lPEPNC04  := ExistBlock( "PEPNC04" )
	local nEstoque  := 0 as numeric
	local dHoje     := Date() as date
	
	Private cPerfDef := "" as character
	Private cPerfil  := "" as character
	Private cFdGroup := "" as character
	Private _aFil    := {} as array
	Private cZB6     := "" as character
	Private aConfig  := {} as array
	Private cZB3     := "" as character 
	Private _aFilters := {}
	Private cZBM     := "" as character
	Private _cPedSol := "" as character

	Default aParam := {}
	
	// Valida parâmetros
	if aParam != Nil .and. Len( aParam ) > 0
		
		ConOut( FunName() + ' - ' + DtoC( dHoje ) + ' - ' + Time() + ' - ' + 'CONECTANDO NA EMPRESA EMPRESA '+ aParam[01] +' E FILIAL '+ aParam[02] +'!' )
		RpcClearEnv()
		RpcSetType( 3 )
		PREPARE ENVIRONMENT EMPRESA aParam[01] FILIAL aParam[02] TABLES "SB1,SD1,SA2" MODULO "CFG" 

		// Valida existência dos parâmetros do painel de compras antes de executar a rotina
		fLoadCfg( .T. /*lAuto*/ )
		if Len( aConfig ) == 0
			ConOut( FunName() + ' - ' + DtoC( dHoje ) + ' - ' + Time() + ' - ' + 'PARAMETROS DO PAINEL DE COMPRAS NAO CADASTRADOS PARA A EMPRESA '+ cEmpAnt +' E FILIAL '+ cFilAnt +'!' )
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
	cFdGroup  := AllTrim( Upper( SuperGetMv( 'MV_X_PNC13',,'B1_GRUPO' ) ) )
	_aFilters := { Space(200),;
					Space(200),; 
					Space(TAMSX3('A2_COD')[1]),;
					Space(TAMSX3(cFdGroup)[1] ),;
					Space(TAMSX3('B1_COD')[1] ),;
					Space( TAMSX3('A2_LOJA')[1] ),;
					.F. /* lCancel */ }

	_aFilters[2] := PADR(aConfig[21],200,' ')					// pré-definições dos tipos de produtos a serem analisados
	
	// Valida existência da tabela ZBM
	cZBM         := AllTrim( GetMV( 'MV_X_PNC16' ) )			// Tabela de perfis de cálculo
	if !Empty( cZBM )
		if !U_JSPERCHK()
			Return Nil
		endif
	else
		ConOut( 'GMINDPRO - '+ Time() +' - AUSENCIA DE CONFIGURACAO PARA A TABELA DE PERFIS DE CALCULO' )
		Return Nil
	endif

	// Define um perfil de cálculo padrão  
	cPerfDef     := StrZero(1,TAMSX3(cZBM +'_ID')[1])
	cPerfil      := cPerfDef

	// Valida se existe o parâmetro configurado no ambiente
	lMVPNC12 := GetMv( 'MV_X_PNC12', .T. /* lCheck */ )
	cDtTime := FWTimeStamp(2)
	
	// Valida existência da função que analisa produtos pendentes de inativação
	lFunIna := ExistBlock( "GMPRDDES" )
	IF lFunIna
		ExecBlock( "GMPRDDES", .F., .F., Nil )
	EndIf

	// Realiza chamada da rotina que analisa pedidos de compras com quantidade a classificar e sem pré-nota de entrada
	if ExistBlock( 'GMPCACLA' )
		ExecBlock( 'GMPCACLA', .T., .T., Nil )
	endif
	
	aPerAna := {}
	if aConfig[15] == 'C'
		aPerAna := { dHoje-aConfig[14], dHoje } 
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
	    
		DBSelectArea( 'SA2' )
		SA2->( DBSetOrder( 1 ) )	

    	While !PRDTMP->( EOF() )
    		
    		nAtu++
    		ConOut( FunName() + ' - ' + DtoC( dHoje ) + ' - ' + Time() + ' - ' + 'ANALISANDO PRODUTO '+ AllTrim( SubStr( PRDTMP->B1_DESC, 01, 30 ) ) +' ( '+ AllTrim( PRDTMP->B1_COD ) +' )' )
			if lManual
				IncProc( 'Analisando produto '+ AllTrim( PRDTMP->B1_DESC ) +'... [ '+ cValToChar( Round((nAtu/nQtd)*100,0)) +'% ]' )
			endif
			
			// Posiciona no registro físico do produto
    		SB1->( DbGoTo( PRDTMP->RECSB1 ) )

			dDatInc  := getDatInc( aPerAna[01] /* dIni */ )
			aPerProd := {} 						// Vetor de períodos a serem considerados para cada produto
			dDataAux := aPerAna[02]				// Variável auxiliar para ajudar a determinar a faixa de período de cada produto
			nDiasAux := 0						// Variável auxiliar para contagem de dias já analisados
			nDiasTot := aPerAna[02]-aPerAna[01]	// Total de dias que vão ser analisados para o produto
			
			// Valida existência de codigo de produto anterior 
			if Empty( SB1->B1_CODANT )
				aAdd( aPerProd, { SB1->B1_COD, dDatInc, aPerAna[02], 1 } )
			else
				while dDataAux > aPerAna[01]
					nDiasAux := dDataAux - dDatInc
					dDataAux := dDataAux - nDiasAux
					aAdd( aPerProd, { SB1->B1_COD, dDataAux, dDataAux + nDiasAux, nDiasAux/nDiasTot } )		
					if dDataAux > aPerAna[01] .and. !Empty( SB1->B1_CODANT )
						SB1->( DBSeek( FWxFilial( 'SB1' ) + SB1->B1_CODANT ) )
						dDatInc := getDatInc( aPerAna[01] )
					else
						Exit
					endif
				end
				nTempo :=  aPerProd[1][3] - aPerProd[len(aPerProd)][2]
				if nTempo < nDiasTot
					for nX := 1 to len( aPerProd )
						aPerProd[nX][4] := ( aPerProd[nX][3] - aPerProd[nX][2] ) / nTempo
					next nX
				endif
				
			endif

			// aPerProd
			// aPerProd[n][1]: Codigo do produto
			// aPerProd[n][2]: Inicio do período de análise do produto
			// aPerProd[n][3]: Fim do período de análise do produto
			// aPerProd[n][4]: Percentual correspondente a quantidade de dias em que o produto foi analisado 

			// Re-posiciona no registro físico do produto
    		SB1->( DbGoTo( PRDTMP->RECSB1 ) )

			aAux := {}
			aAux := betterSupplier( PRDTMP->B1_COD, aConfig )
			cFornece := PADR( aAux[1], TAMSX3('A2_COD')[1], ' ')		// Codigo do fornecedor
			cLoja    := PADR( aAux[2], TAMSX3('A2_LOJA')[1], ' ' )		// Codigo da loja
			
			// Identifica lead-time conforme regra definida para produto, fornecedor (informado) ou fornecedor (calculado)
			if PRDTMP->B1_PE > 0
				nLeadTime := PRDTMP->B1_PE
				cLeadTime := 'P'		// Produto
			else
				// Posiciona no fornecedor e loja
				if SA2->( DBSeek( FWxFilial( 'SA2' ) + cFornece + cLoja ) )
					if SA2->A2_X_LTIME > 0
						nLeadTime := SA2->A2_X_LTIME
						cLeadTime := 'F'		// Fornecedor
					else
						nLeadTime := calcLt( PRDTMP->B1_COD, cFornece, cLoja )
						cLeadTime := 'C'		// Calculado					
					endif
				endif
			endif 
			
			// Comando para leitura do índice de giro dos produtos
			nIndGir  := 0
    		nConMed  := 0
			nDUteis  := 0
			nVenda   := 0
			nConsumo := 0
			nQtdProd := 0
			nQtdDoc  := 0

			for nX := 1 to len( aPerProd )

				cQuery := "SELECT "+ CEOL
				cQuery += "	COUNT(*) QTD_PRODUTO " + CEOL
				cQuery += "FROM "+ RetSqlName( "SD2" ) +" D2 " + CEOL
				cQuery += "WHERE D2.D2_FILIAL  = '"+ FWxFilial( 'SD2' ) +"' " + CEOL
				cQuery += "  AND D2.D2_COD     = '"+ aPerProd[nX][01] +"' " + CEOL
				cQuery += "  AND D2.D2_TIPO    = 'N' "+ CEOL
				cQuery += "  AND D2.D2_EMISSAO BETWEEN '"+ DtoS( aPerProd[nX][02] ) +"' AND '"+ DtoS( aPerProd[nX][03] ) +"' " + CEOL
				cQuery += "  AND D2.D2_CLIENTE <> '"+ PADR( SubStr( SM0->M0_CGC, 01, 08 ), TAMSX3('D2_CLIENTE')[1], ' ' ) +"' " + CEOL
				cQuery += "  AND D2.D_E_L_E_T_ = ' ' " + CEOL
				
				DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), 'INDPRO', .F., .T. )
				if !INDPRO->( EOF() )
					nQtdProd += INDPRO->QTD_PRODUTO
				EndIf
				INDPRO->( DBCloseArea() )

				// Conta quantas vezes a MP apareceu em Ordens de Produção
				cQuery := "SELECT "
				cQuery += "  COUNT(*) QTD_PRODUTO "+ CEOL 
				cQuery += "FROM "+ RetSqlName( 'SD3' ) +" D3 " + CEOL
				cQuery += "WHERE D3.D3_FILIAL  = '"+ FWxFilial( 'SD3' ) +"' "+ CEOL
				cQuery += "  AND D3.D3_COD     = '"+ aPerProd[nX][01] +"' " + CEOL
				cQuery += "  AND D3.D3_EMISSAO BETWEEN '"+ DtoS( aPerProd[nX][02] ) +"' AND '"+ DtoS( aPerProd[nX][03] ) +"' " + CEOL
				cQuery += "  AND D3.D3_TM     >= '500' " + CEOL
				cQuery += "  AND ( D3.D3_OP     <> '"+ Space( TAMSX3('D3_OP')[1] ) +"' OR D3.D3_CF = 'RE0' ) " + CEOL
				cQuery += "  AND D3.D3_ESTORNO = ' ' " + CEOL
				cQuery += "  AND D3.D_E_L_E_T_ = ' ' "
				
				DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), 'INDPRO', .F., .T. )
				if !INDPRO->( EOF() )
					nQtdProd += INDPRO->QTD_PRODUTO
				EndIf
				INDPRO->( DBCloseArea() )
				
				// Verifica se a faixa de data a ser analisada é maior ou igual a data de inclusao do produto no sistema
				if aConfig[15] == "C"
					nDUteis += aPerProd[nX][03] - aPerProd[nX][02] 
				Else
					nAux    := 0
					dAux    := aPerProd[nX][02]
					While ( dAux + nAux ) < aPerProd[nX][03]
						if DataValida( dAux + nAux, .T. ) == dAux + nAux
							nDUteis++
						EndIf
						nAux++
					EndDo
				EndIf
				
				cQuery := "SELECT COALESCE(SUM(D2.D2_QUANT),0) AS QTD_TOTAL FROM "+ RetSqlName( 'SD2' ) +" D2 " + CEOL
				
				cQuery += "INNER JOIN "+ RetSqlName( 'SF4' ) +" F4 " + CEOL
				cQuery += " ON F4.F4_FILIAL  = '"+ FWxFilial( 'SF4' ) +"' "+ CEOL
				cQuery += "AND F4.F4_CODIGO  = D2.D2_TES "+ CEOL
				cQuery += "AND F4.F4_ESTOQUE = 'S' "+ CEOL
				cQuery += "AND F4.D_E_L_E_T_ = ' ' "+ CEOL

				cQuery += "WHERE D2.D2_FILIAL  = '"+ FWxFilial( 'SD2' ) +"' "+ CEOL
				cQuery += "  AND D2.D2_TIPO    = 'N' "+ CEOL
				cQuery += "  AND D2.D2_EMISSAO BETWEEN '"+ DtoS( aPerProd[nX][02] ) +"' AND '"+ DtoS( aPerProd[nX][03] ) +"' " + CEOL
				cQuery += "  AND D2.D2_CLIENTE <> '"+ PADR(SubStr( SM0->M0_CGC, 01, 08 ),TAMSX3('C5_CLIENTE')[1], ' ' ) +"' " + CEOL
				cQuery += "  AND D2.D2_COD     = '"+ aPerProd[nX][01] +"' " + CEOL
				cQuery += "  AND D2.D_E_L_E_T_ = ' ' " + CEOL
				
				DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), "MEDCON", .F., .T. )
				nVenda += MEDCON->QTD_TOTAL
				MEDCON->( DbCloseArea() )
				
				cQuery := "SELECT COALESCE(SUM(D3.D3_QUANT),0) AS QTD_TOTAL FROM "+ RetSqlName( 'SD3' ) +" D3 " + CEOL
				cQuery += "WHERE D3.D3_FILIAL = '"+ FWxFilial( 'SD3' ) +"' "+ CEOL
				cQuery += "  AND D3.D3_COD    = '"+ aPerProd[nX][01] +"' " + CEOL
				cQuery += "  AND D3.D3_EMISSAO BETWEEN '"+ DtoS( aPerProd[nX][02] ) +"' AND '"+ DtoS( aPerProd[nX][03] ) +"' " + CEOL
				cQuery += "  AND D3.D3_TM     >= '500' " + CEOL
				cQuery += "  AND ( D3.D3_OP     <> '"+ Space( TAMSX3('D3_OP')[1] ) +"' OR D3.D3_CF = 'RE0' ) " + CEOL
				cQuery += "  AND D3.D3_ESTORNO = ' ' " + CEOL
				cQuery += "  AND D3.D_E_L_E_T_ = ' ' " 

				DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), "MEDCON", .F., .T. )
				nConsumo += MEDCON->QTD_TOTAL
				MEDCON->( DbCloseArea() )

			next nX

			cQuery := "SELECT "+ CEOL
			cQuery += "	 COUNT( DISTINCT CONCAT( D2.D2_DOC, D2.D2_SERIE ) ) QTD_PEDIDOS "+ CEOL
			cQuery += "FROM "+ RetSqlName( "SD2" ) +" D2 " + CEOL
			cQuery += "WHERE D2.D2_FILIAL  = '"+ FWxFilial( 'SD2' ) +"' " + CEOL
			cQuery += "  AND D2.D2_TIPO    = 'N' "+ CEOL
			cQuery += "  AND D2.D2_EMISSAO BETWEEN '"+ DtoS( aPerProd[len(aPerProd)][02] ) +"' AND '"+ DtoS( aPerProd[1][03] ) +"' " + CEOL
			cQuery += "  AND D2.D2_CLIENTE <> '"+ PADR( SubStr( SM0->M0_CGC, 01, 08 ), TAMSX3('D2_CLIENTE')[1], ' ' ) +"' " + CEOL
			cQuery += "  AND D2.D_E_L_E_T_ = ' ' " + CEOL
			
			DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), 'INDPRO', .F., .T. )
			if !INDPRO->( EOF() )
				nQtdDoc  += INDPRO->QTD_PEDIDOS
			EndIf
			INDPRO->( DBCloseArea() )

			// Conta quantas vezes a MP apareceu em Ordens de Produção
			cQuery := "SELECT "
			if TCGetDB() $ "ORACLE" 
				cQuery += "  COUNT( DISTINCT SUBSTR( D3.D3_OP,01, 06 ) ) QTD_OP " + CEOL
			else
				cQuery += "  COUNT( DISTINCT SUBSTRING( D3.D3_OP,01, 06 ) ) QTD_OP " + CEOL
			endif
			cQuery += "FROM "+ RetSqlName( 'SD3' ) +" D3 " + CEOL
			cQuery += "WHERE D3.D3_FILIAL  = '"+ FWxFilial( 'SD3' ) +"' "+ CEOL
			cQuery += "  AND D3.D3_EMISSAO BETWEEN '"+ DtoS( aPerProd[len(aPerProd)][02] ) +"' AND '"+ DtoS( aPerProd[1][03] ) +"' " + CEOL
			cQuery += "  AND D3.D3_TM     >= '500' " + CEOL
			cQuery += "  AND D3.D3_OP     <> '"+ Space( TAMSX3('D3_OP')[1] ) +"' " + CEOL
			cQuery += "  AND D3.D3_ESTORNO = ' ' " + CEOL
			cQuery += "  AND D3.D_E_L_E_T_ = ' ' "
			
			DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), 'INDPRO', .F., .T. )
			if !INDPRO->( EOF() )
				nQtdDoc  += INDPRO->QTD_OP
			EndIf
			INDPRO->( DBCloseArea() )
			
			// Calcula o índice de giro do produto
			nIndGir := Round(((nQtdProd / nQtdDoc)*100),TAMSX3( cZB3 +'_INDINC')[2] )

			// Venda e consumo
			if (nVenda + nConsumo) != 0
				nConMed := Round((nVenda+nConsumo) / iif( nDUteis == 0, 1, nDUteis ),4)		
			Else
				nConMed := 0.0001
			EndIf

    		lEvento := .F.
    		cMsg    := ""
    		nPrjEst := 0
    		dPrjAux := dHoje
    		nDUteis := 0
			lWF     := .F.

			// PE para manipulação do saldo atual do produto
			if lPEPNC04
				nEstoque  := ExecBlock( "PEPNC04", .F., .F., { aConfig, PRDTMP->B1_COD, PRDTMP->ESTOQUE } )
			else
				nEstoque := PRDTMP->ESTOQUE
			endif

    		// Calcula duração do estoque do produto baseado nas variáveis: consumo médio, estoque disponível, quantidade já comprada e data de previsão de entrega do fornecedor
			nQtdAtual := iif( aConfig[24] == "S", nEstoque - PRDTMP->EMPENHO, nEstoque ) 
    		nPrjEst := Round( ( nQtdAtual + PRDTMP->QTDCOMP )/nConMed, 0 ) 
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
						lWF     := .T.
					Else
						
						// Verifica a duração do estoque considerando dias úteis ou dias corridos de acordo com o parâmetro
						if aConfig[15] == "C"
			    			dPrjAux := dHoje + nPrjEst
			    		Else
			    			nAux := 0
			    			nDUteis := 0
			    			While nDUteis < nPrjEst
			    				
			    				if DataValida( dHoje + nAux, .T. ) == dHoje + nAux
			    					nDUteis++
			    				EndIf
			    				
			    				nAux++
			    			EndDo
			    			dPrjAux := dHoje + nAux
			    		EndIf
						
						cMsg    := 'Risco de ruptura em '+ DtoC( dPrjAux )
						lWF     := .T.
					EndIf
    			EndIf
    		EndIf
    		
    		// Verifica se tem produto já comprado que esteja com previsão de entrega vencida
    		If PRDTMP->QTDCOMP > 0 .and. StoD( PRDTMP->PRVENT ) < dHoje
	    		
	    		// Verifica a possibilidade de ruptura de acordo com a configuração (dias úteis ou dias corridos)
				nQtdAtual := iif( aConfig[24] == "S", nEstoque - PRDTMP->EMPENHO, nEstoque ) 
				if Round( nQtdAtual/nConMed, 0 ) < aConfig[01] 
					if aConfig[15] == "C"
		    			dPrjAux := dHoje + Round( nQtdAtual/nConMed, 0 )
		    		Else
		    			nDUteis := 0 
		    			nAux    := 0
		    			While nDUteis < Round( nQtdAtual/nConMed, 0 )
		    				
		    				if DataValida( dHoje + nAux, .T. ) == dHoje + nAux
		    					nDUteis++
		    				EndIf
		    				
		    				nAux++
		    			EndDo
		    			dPrjAux := dHoje + nAux
		    		EndIf
	    		EndIf
	    		
	    		lEvento := .T.
	    		cMsg    := "Compra com atraso na entrega"+; 
	    		           iif( Round( nQtdAtual/nConMed, 0 ) > aConfig[01],; 
	    		           ', mas sem risco de ruptura pelos próximos '+ AllTrim( cValToChar( aConfig[01] ) ) +' dias',; 
	    		           iif( Round( nQtdAtual/nConMed, 0 ) == 0,; 
	    		           ' e está sem estoque disponível',; 
	    		           iif( Round( nQtdAtual/nConMed, 0 ) < aConfig[01],; 
	    		           '. Risco de ruptura em '+ DtoC( dPrjAux ), '' ) ) ) +"."
				if Round( nQtdAtual/nConMed, 0 ) < aConfig[01]
					lWF := .T.
				endif
			EndIf
    		
    		// Trata exceções dos eventos para os produtos sinalizados manualmente pelo operador
    		if lEvento
    			DBSelectArea( cZB6 )
    			(cZB6)->( DBSetOrder( 1 ) )
    			If DBSeek( xFilial( cZB6 ) + PRDTMP->B1_COD )
    				if (cZB6)->( FieldGet( FieldPos( cZB6 +'_DTLIM' ) ) ) >= dHoje
    					cMsg    := "IGNORA AUTO: "+ cMsg
						lWF     := .F.
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
						 nEstoque,; 
						 PRDTMP->EMPENHO,;
						 PRDTMP->QTDCOMP,;
						 PRDTMP->QTDSOL /*nQtdSol*/ }

    		// Calcula necessidade de compra do material
			cPerfil := RetField( 'SB1', 1, FWxFilial( 'SB1' ) + PRDTMP->B1_COD, 'B1_X_PERCA' )
			if Empty( cPerfil )		// Quando vazio, usa o perfil default
				cPerfil := cPerfDef
			endif
    		nQtdCom := fCalNec( aInfPrd, cPerfil )
    		
    		// Valida existência de chave primária da tabela
    		lInclui := ! (cZB3)->( DbSeek( xFilial( cZB3 ) + PRDTMP->B1_COD + DtoS( dHoje ) ) ) 

			ConOut( FunName() + ' - ' + DtoC( dHoje ) + ' - ' + Time() + ' - ' + cValToChar( nAtu ) + '/' + cValToChar( nQtd ) + ' - GRAVANDO DADOS DO PRODUTO '+ AllTrim( SubStr( PRDTMP->B1_DESC, 01, 30 ) ) +' ( '+ AllTrim( PRDTMP->B1_COD ) +' )' )
			
			RecLock( cZB3, lInclui )
			if lInclui
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_FILIAL' ), xFilial( cZB3 ) ) )
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_PROD'   ), PRDTMP->B1_COD ) )
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_DATA'   ), dHoje ) )
			endif
			( cZB3 )->( FieldPut( FieldPos( cZB3 +'_INDINC' ), nIndGir ) )
			( cZB3 )->( FieldPut( FieldPos( cZB3 +'_CONMED' ), nConMed ) )
			( cZB3 )->( FieldPut( FieldPos( cZB3 +'_TMPGIR' ), aConfig[14] ) )
			( cZB3 )->( FieldPut( FieldPos( cZB3 +'_TPDIAS' ), aConfig[15] ) )
			( cZB3 )->( FieldPut( FieldPos( cZB3 +'_PRJEST' ), nPrjEst ) )
			( cZB3 )->( FieldPut( FieldPos( cZB3 +'_NECCOM' ), nQtdCom ) )
			( cZB3 )->( FieldPut( FieldPos( cZB3 +'_SALDO'  ), nEstoque ) ) 
			( cZB3 )->( FieldPut( FieldPos( cZB3 +'_QTDEMP' ), PRDTMP->EMPENHO ) ) 
			( cZB3 )->( FieldPut( FieldPos( cZB3 +'_QTDCOM' ), PRDTMP->QTDCOMP ) )
			( cZB3 )->( FieldPut( FieldPos( cZB3 +'_LDTIME' ), nLeadTime ) )
			( cZB3 )->( FieldPut( FieldPos( cZB3 +'_PRVENT' ), StoD( PRDTMP->PRVENT ) ) )
			( cZB3 )->( FieldPut( FieldPos( cZB3 +'_AVISO'  ), iif( lEvento, 'S','N' ) ) )
			( cZB3 )->( FieldPut( FieldPos( cZB3 +'_MSG'    ), cMsg ) )	
			( cZB3 )->( FieldPut( FieldPos( cZB3 +'_JUSTIF' ), iif( "IGNORA" $ cMsg, aConfig[18], Space( TAMSX3( cZB3 +"_JUSTIF")[01] ) ) ) )
			( cZB3 )->( MsUnlock() )

			// Adiciona no vetor de workflow para notificar comprador quanto a necessidade de atenção
			if lWF .and. ( len( aDataWF ) == 0 .or. aScan( aDataWF, {|x| x[1] == PRDTMP->B1_COD } ) == 0 )
				aAdd( aDataWF, { PRDTMP->B1_COD,;
								 nConMed,;
								 iif( aConfig[15] == 'C', 'Corridos', 'Úteis' ),;
								 nPrjEst,;
								 nQtdCom,;
								 nEstoque,; 
								 PRDTMP->EMPENHO,;
								 PRDTMP->QTDCOMP,;
								 nLeadTime,;
								 StoD( PRDTMP->PRVENT ),;
								 cMsg } )
			endif			

    		PRDTMP->( DbSkip() )
    	EndDo
    EndIf
    
    PRDTMP->( DbCloseArea() )
	
	if lMVPNC12
		PutMV( 'MV_X_PNC12', cDtTime )
	endif

	// Verifica se o campo referente ao código de justificativa padrão já foi adicionado ao vetor de parâmetros
	if Len( aConfig ) >= 18 .and. !Empty( aConfig[18] )
		
		ConOut( "GMINDPRO - "+ Time() +" - JUSTIFICANDO NOTIFICACOES NAO TRATADAS DE DIAS ANTERIORES... " )
		
		cQuery := "UPDATE "+ RetSqlName( cZB3 ) +" SET "+ cZB3 +"_JUSTIF = '"+ aConfig[18] +"' "
		cQuery += "WHERE "+ cZB3 +"_FILIAL "+ U_JSFILIAL( cZB3, _aFil ) + " "
		cQuery += "  AND "+ cZB3 +"_AVISO  = 'S' "
		cQuery += "  AND "+ cZB3 +"_JUSTIF = '"+ Space( TAMSX3( cZB3 +"_JUSTIF")[01] ) +"' "
		cQuery += "  AND "+ cZB3 +"_DATA   < '"+ DtoS( dHoje ) +"' " 
		cQuery += "  AND D_E_L_E_T_ = ' ' "
		
		If TcSQLExec( cQuery ) < 0
			 ConOut( "GMINDPRO - "+ Time() +" - ERRO DURANTE EXECUCAO DO COMANDO: " + CEOL +;
			         cQuery + CEOL +;
			         Replicate( '-', 50 ) + CEOL +;
			         TCSQLError() )
		EndIf
		
	EndIf

	// Verifica a quantidade de dias que o sistema deve manter de histórico de cálculos para os produtos
	if aConfig[25] > 0
		ConOut( "GMINDPRO - "+ Time() +": ELIMINANDO SALDO HISTORICO DE CALCULOS" )
		cQuery := "DELETE FROM "+ RetSqlName( cZB3 ) +" WHERE "+ cZB3 +"_FILIAL = '"+ FWxFilial( cZB3 ) +"' AND "+ cZB3 +"_DATA < '"+ DtoS( dHoje-aConfig[25] ) +"' " 
		If TcSQLExec( cQuery ) < 0
			 ConOut( "GMINDPRO - "+ Time() +" - ERRO DURANTE EXECUCAO DO COMANDO: " + CEOL +;
			         cQuery + CEOL +;
			         Replicate( '-', 50 ) + CEOL +;
			         TCSQLError() )
		EndIf
	endif

	// Validações para disparo de workflow
	// 1. Valida se tem conteúdo pra enviar
	// 2. Valida se a estrutura existe (ou foi criada com sucesso) 
	// 3. Verifica se tem e-mail cadastrado para receber o workflow
	aAuxWF := wfStruct()
	if len( aDataWF ) > 0 .and. len( aAuxWF ) > 0 .and. aAuxWF[1] .and. !Empty( aConfig[23] )

		oProcess := TWFProcess():new( "JSPAICOM", OemToAnsi( 'Alertas de Ruptura' ) )
		oProcess:NewTask( "RUPTURA", aAuxWF[2] )
		oProcess:cSubject := "[PAINEL DE COMPRAS] Alerta(s) de Ruptura "+ cDtTime
		oProcess:cTo      := AllTrim( aConfig[23] )		

		oHTML := oProcess:oHTML
		oHTML:ValByName("EMPRESA", OemToAnsi( SM0->M0_FILIAL ) )
		oHTML:ValByName("TITULOMSG", OemToAnsi( "Foram identificados produtos com risco de ruptura de estoque..." ) )
		oHTML:ValByName("DATAHORA", OemToAnsi( cDtTime ) )
		
		for nX := 1 to len( aDataWF )
			nLin++	

            if nLin % 2 != 0
                cColor := "#dcdcdc"
            Else
                cColor := "#fff"
            EndIf
            
            aAdd((oHTML:ValByName("IT.CLPRODUTO"     )), cColor  )
			aAdd((oHTML:ValByName("IT.PRODUTO"       )), AllTrim( aDataWF[nX][1] ) )
			aAdd((oHTML:ValByName("IT.CLDESCRICAO"   )), cColor  )
			aAdd((oHTML:ValByName("IT.DESCRICAO"     )), AllTrim( RetField( 'SB1', 1, FWxFilial( 'SB1' ) + aDataWF[nX][1], 'B1_DESC' ) ) )
			aAdd((oHTML:ValByName("IT.CLCONSUMO"     )), cColor  )
            aAdd((oHTML:ValByName("IT.CONSUMO"       )), AllTrim( Transform( aDataWF[nX][2], GetSX3Cache( cZB3 +'_CONMED', 'X3_PICTURE' ) ) ) )
			aAdd((oHTML:ValByName("IT.CLTIPODIA"     )), cColor  )
            aAdd((oHTML:ValByName("IT.TIPODIA"       )), AllTrim( aDataWF[nX][3] ) )
			aAdd((oHTML:ValByName("IT.CLDURACAO"     )), cColor  )
            aAdd((oHTML:ValByName("IT.DURACAO"       )), AllTrim( Transform( aDataWF[nX][4], GetSX3Cache( cZB3 +'_PRJEST', 'X3_PICTURE' ) ) ) )
			aAdd((oHTML:ValByName("IT.CLNECESSIDADE" )), cColor  )
            aAdd((oHTML:ValByName("IT.NECESSIDADE"   )), AllTrim( Transform( aDataWF[nX][5], GetSX3Cache( cZB3 +'_NECCOM', 'X3_PICTURE' ) ) ) )
			aAdd((oHTML:ValByName("IT.CLESTOQUE"     )), cColor  )
            aAdd((oHTML:ValByName("IT.ESTOQUE"       )), AllTrim( Transform( aDataWF[nX][6], GetSX3Cache( cZB3 +'_SALDO', 'X3_PICTURE' ) ) ) )
			aAdd((oHTML:ValByName("IT.CLEMPENHO"     )), cColor  )
            aAdd((oHTML:ValByName("IT.EMPENHO"       )), AllTrim( Transform( aDataWF[nX][7], GetSX3Cache( cZB3 +'_QTDEMP', 'X3_PICTURE' ) ) ) )
			aAdd((oHTML:ValByName("IT.CLCOMPRADO"    )), cColor  )
            aAdd((oHTML:ValByName("IT.COMPRADO"      )), AllTrim( Transform( aDataWF[nX][8], GetSX3Cache( cZB3 +'_QTDCOM', 'X3_PICTURE' ) ) ) )
			aAdd((oHTML:ValByName("IT.CLPREVISAO"    )), cColor  )
            aAdd((oHTML:ValByName("IT.PREVISAO"      )), AllTrim( DtoC( aDataWF[nX][10] ) ) )
			aAdd((oHTML:ValByName("IT.CLLDTIME"      )), cColor  )
            aAdd((oHTML:ValByName("IT.LDTIME"        )), AllTrim( Transform( aDataWF[nX][9], GetSX3Cache( cZB3 +'_LDTIME', 'X3_PICTURE' ) ) ) )
			aAdd((oHTML:ValByName("IT.CLMENSAGEM"    )), cColor  )
            aAdd((oHTML:ValByName("IT.MENSAGEM"      )), AllTrim( aDataWF[nX][11] ) )
		next nX

		oProcess:Start()
		oProcess:Finish()
	    WFSENDMAIL()

	endif

	// Prepara desconexão da rotina automática
	if ! lManual
		ConOut( FunName() + ' - ' + DtoC( dHoje ) + ' - ' + Time() + ' - ' + 'DESCONECTANDO DA EMPRESA '+ cEmpAnt +' E FILIAL '+ cFilAnt +'!' )
		RESET ENVIRONMENT
	EndIf
	
	ConOut( FunName() + ' - ' + DtoC( dHoje ) + ' - ' + Time() + ' - ' + 'FIM DA ROTINA DE RECALCULO DE INDICES DO PRODUTO!' )
	
Return ( Nil )

/*/{Protheus.doc} wfStruct
Função que valida se a estrutura de workflow está preparada para envio de e-mails
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 1/2/2025
@return array, aReturn
/*/
static function wfStruct()
	
	local lSuccess := .T. as logical
	local oFile    as object
	local cPath    := "/workflow/"
	local cFileWF  := "painel_compras_ruptura_v01.html"
	local cWF      := "" as character

	lSuccess := File( cPath + cFileWF )
	if ! lSuccess
		cWF := U_RuptWF()
		oFile := FWFileWriter():New( cPath + cFileWF )
		if oFile:Create()
			oFile:Write( cWF )
			oFile:Close()
		endif
	endif

return { lSuccess, iif( lSuccess, cPath + cFileWF, "" ) }

/*/{Protheus.doc} fCalNec
FUnção que calcula a necessidade de compra para o produto com base na fórmula definida
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/04/2024
@param aInfPrd, array, vetor com informações sobre o produto
@param cPerfil, character, ID do perfil de compra setado pelo usuário na rotina de análise
@return numeric, nQtdCom
/*/
Static Function fCalNec( aInfPrd, cPerfil )
	
	local lPriLE    := aConfig[19] == 'S'
	local cFormula  := "" as character
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
	Private nQtdSol := 0 as numeric
	
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
	nQtdSol := aInfPrd[12]

	// Valida existência da fórmula
	cFormula := AllTrim( RetField( cZBM, 1, FWxFilial( cZBM ) + cPerfil, cZBM+'_FORMUL' ) )
	if Empty( cFormula )
		nQtdCom := 0
		Return nQtdCom
	endif

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

/*/{Protheus.doc} JSDoFrml 
Função de manutenção da fórmula de cálculo da necessidade de compra
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 09/04/2024
@param cID, character, ID do perfil de cálculo
@return character, cFormula
/*/
User Function JSDoFrml( cID, oDlg )
	
	Local oBtnAbP  := Nil
	Local oBtnAdd  := Nil
	Local oBtnDiv  := Nil
	Local oBtnFeP  := Nil
	Local oBtnMai  := Nil
	Local oBtnMen  := Nil
	Local oBtnVez  := Nil
	Local oCboVar  := Nil
	Local oFntFor  := TFont():New("Courier New", , 014, , .T., , , , , .F., .F.)
	Local oGetFor  := Nil
	Local oLblVar  := Nil
	local cPerf    := "" as character
	local cFormula := "" as character
	local bOk      := {|| cFormula := fGrvCri( cPerf, cFormTmp ), iif( oDlg==Nil, oDlgCri:End(), Nil ) }
	local bCancel  := {|| oDlgCri:End() }
	local aButtons := {} as array
	local oModel    as object
	local oMaster   as object
	local cZBM     := AllTrim(GetMV( 'MV_X_PNC16' ))
	local cForm    := ""
	local cCboVar  := ""
	local cFormTmp := ""		// Formula temporária

	Private oDlgCri  := Nil
	
	default oDlg := Nil

	if !oDlg == Nil
		oDlgCri  := oDlg
		oModel   := FWModelActive()
		oMaster  := oModel:GetModel( cZBM +'MASTER' )
		cPerf    := oMaster:GetValue( cZBM +'_ID' )
		cFormTmp := AllTrim( oMaster:GetValue( cZBM +'_FORMUL' ) )
		cForm  := fLoadCri( oMaster:GetValue( cZBM +'_FORMUL' ) )
	else
		cFormTmp := AllTrim( RetField( cZBM, 1, FWxFilial( cZBM ) + cPerfil, cZBM +'_FORMUL' ) )
		cForm  := fLoadCri( cFormTmp )
		cPerf    := cID
		DEFINE MSDIALOG oDlgCri TITLE "Critério de Compra - "+ AllTrim( RetField( cZBM, 1, FWxFilial( cZBM ) + cPerf, cZBM +"_DESC" ) ) FROM 000, 000 TO 175, 700 COLORS 0, 16777215 PIXEL
	endif

    @ 037, 006 SAY oLblVar PROMPT "Variáveis" SIZE 025, 007 OF oDlgCri COLORS 0, 16777215 PIXEL

	oGetFor := TSay():New( 058, 004, {|u| cForm },oDlgCri,,oFntFor,,,,.T.,CLR_RED,CLR_WHITE,340,20)

    @ 035, 032 MSCOMBOBOX oCboVar VAR cCboVar ITEMS fGetVar( 1 /*nOpc*/, @cCboVar ) SIZE 070, 013 OF oDlgCri  COLORS 0, 16777215 PIXEL
    @ 035, 104 BUTTON oBtnAdd PROMPT "&Adicionar" SIZE 035, 012 OF oDlgCri ACTION {|| cForm := fManFor( 1 /*nOpc*/,, @cFormTmp, @cCboVar ), oGetFor:CtrlRefresh() } PIXEL
    @ 035, 141 BUTTON oBtnRem PROMPT "&Remover" SIZE 035, 012 OF oDlgCri ACTION {|| cForm := fManFor( 2 /*nOpc*/,, @cFormTmp, @cCboVar ), oGetFor:CtrlRefresh() } PIXEL
    @ 035, 350-(12*6)-(2*6) BUTTON oBtnAbP PROMPT "(" SIZE 012, 012 OF oDlgCri ACTION {|| cForm := fManFor( 3 /*nOpc*/, oBtnAbP:CCAPTION /*cOpc*/, @cFormTmp, @cCboVar ), oGetFor:CtrlRefresh() } PIXEL
    @ 035, 350-(12*5)-(2*5) BUTTON oBtnFeP PROMPT ")" SIZE 012, 012 OF oDlgCri ACTION {|| cForm := fManFor( 3 /*nOpc*/, oBtnFeP:CCAPTION /*cOpc*/, @cFormTmp, @cCboVar ), oGetFor:CtrlRefresh() } PIXEL
    @ 035, 350-(12*4)-(2*4) BUTTON oBtnMen PROMPT "-" SIZE 012, 012 OF oDlgCri ACTION {|| cForm := fManFor( 3 /*nOpc*/, oBtnMen:CCAPTION /*cOpc*/, @cFormTmp, @cCboVar ), oGetFor:CtrlRefresh() } PIXEL
    @ 035, 350-(12*3)-(2*3) BUTTON oBtnMai PROMPT "+" SIZE 012, 012 OF oDlgCri ACTION {|| cForm := fManFor( 3 /*nOpc*/, oBtnMai:CCAPTION /*cOpc*/, @cFormTmp, @cCboVar ), oGetFor:CtrlRefresh() } PIXEL
    @ 035, 350-(12*2)-(2*2) BUTTON oBtnDiv PROMPT "/" SIZE 012, 012 OF oDlgCri ACTION {|| cForm := fManFor( 3 /*nOpc*/, oBtnDiv:CCAPTION /*cOpc*/, @cFormTmp, @cCboVar ), oGetFor:CtrlRefresh() } PIXEL
    @ 035, 350-(12*1)-(2*1) BUTTON oBtnVez PROMPT "x" SIZE 012, 012 OF oDlgCri ACTION {|| cForm := fManFor( 3 /*nOpc*/, "*" /*cOpc*/, @cFormTmp, @cCboVar ), oGetFor:CtrlRefresh() } PIXEL
    
	if oDlg == Nil
    	ACTIVATE MSDIALOG oDlgCri CENTERED ON INIT EnchoiceBar( oDlgCri, bOk, bCancel,, aButtons )
	endif
	
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
Static Function fGrvCri( cID, cFormula )
	
	DBSelectArea( cZBM )
	( cZBM )->( DBSetOrder( 1 ) )		// ID
	if ( cZBM )->( DBSeek( FWxFilial( cZBM ) + cID ) )
		RecLock( cZBM, .F. )
		( cZBM )->( FieldPut( FieldPos( cZBM +'_FORMUL' ), cFormula ) )
		( cZBM )->( MsUnlock() )
	else
		cFormula := ""
	endif
	
Return ( cFormula )
 
*/
/*/{Protheus.doc} fManFor
Função que re torna as variáveis que poderão ser utilizadas na composição da fórmula de cálculo das necessidades de compra
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/25/2025
@param nOpc, numeric, 1=Adiciona COnteúdo, 2=Remove Conteúdo ou 3=Adiciona Operador
@param cOpc, character, Operador que será adicionado à fórmula
@param cFormTmp, character, Formula atual (não visual)
@param cCboVar, character, Conteúdo do combo de variáveis
@return character, cFormulaVisual
/*/
Static Function fManFor( nOpc, cOpc, cFormTmp, cCboVar )
	
	Local aItens   := {}
	Local cVar     := ""
	Local nX       := 0
	local cAux     := "" as character
	local oModel   as object
	local oMaster  as object
	local lMVC     := FWIsInCallStack( 'U_JSPERCAL' )
	local cZBM     := AllTrim( GetMv( 'MV_X_PNC16' ) )
	
	Default cOpc := ""

	cAux := cFormTmp // Inicializa com conteúdo atual da fórmula
	if nOpc == 1 .or. nOpc == 3				// Adicionar
		cVar     := fGetVar(2, @cCboVar )[aScan( fGetVar(2, @cCboVar ), {|x| AllTrim(x[1]) == cCboVar } )][02]
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
	cAux := fLoadCri( cAux, Nil, @cCboVar )
	if lMVC
		oModel := FWModelActive()
		// Checa operação para saber se deve atualizar o conteúdo da variável ou não
		if oModel:GetOperation() == MODEL_OPERATION_INSERT .or. oModel:GetOperation() == MODEL_OPERATION_UPDATE
			oMaster := oModel:GetModel( cZBM +'MASTER' )
			oMaster:SetValue( cZBM +'_FORMUL', cFormTmp )
		endif
	endif

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
Static Function fLoadCri( cCodCri, lVar, cCboVar )
	
	Local cRet   := ""
	Local aItens := ""
	Local aVar   := {}
	Local nX     := 0
	
	Default cCodCri := ""
	Default lVar    := .F.		// Indica se o retorno deve ser da variável ou da descrição dela .T.=Variável .F.=Descrição
	
	// Verifica se for visualização, alteração ou exclusão
	if ! Empty( cCodCri )
		
		aItens := StrTokArr( AllTrim( cCodCri ), CSEPARA )
		aVar   := fGetVar(2, @cCboVar )
		
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
Static Function fGetVar( nOpc, cCboVar )
	
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
	aAdd( aVar, { 'Qtd. Solic.', 'nQtdSol'         } )
	
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
	local oGetCom as object
	Local oGetEmi
	Local oGetFor
	Local oGetLoj
	Local oGetMai
	Local oLbCont
	Local oLblEmi
	Local oLblFor 
	Local nX        := 0
	Local cTitulo   := ""
	Local lOk       := .F.
	local aCarrinho := {} as array
	local oGetFre   as object
	local oPerFre   as object
	local lUsaFrete := X3Uso( GetSX3Cache( 'C7_VALFRE', 'X3_USADO' ) )
	local oTransp   as object
	local oTransLj  as object
	local oDescTran as object
	local oDescont  as object
	local cDescTran := Space( TAMSX3( 'A4_NOME' )[1] )
	local nCol      := 0 as numeric
	local nLin      := 0 as numeric
	local aSize     := MsAdvSize()
	local nHor      := (aSize[5]/2)*0.8
	local nVer      := (aSize[6]/2)*0.8
	local lUsaTrans := .F. as logical
	local bValid    := {|| .T. }
	local aButtons  := {} as array
	local bCancel   := {|| oDlgCar:End() }
	local oCbo      as object
	local aCbo      := {} as array  
	local cFil      := "" as character
	local bOk       := {|| Processa( { || lOk := fGrvPed( oCbo, aCbo, SubStr(cCbo,1,len(cFilAnt)), cFor, cLoj ),; 
							iif( lOk, oDlgCar:End(), Nil ) }, 'Aguarde!','Incluindo '+ iif( _cPedSol == '1', 'pedido', 'solicitação' ) +' de compra...' ) }
	local bInit     := {|| EnchoiceBar( oDlgCar, bOk, bCancel,, aButtons ), fChgCar() }
	local nWidth    := 0 as numeric
	local cPicTransp := "" as character
	local cPicName   := "" as character
	
	Private nDescont := 0 as numeric
	Private oTot1UN   as object
	Private oTot2UN   as object
	Private cCbo    := "" as character
	Private lPrice  := .T. as logical
	Private oTotal  as object
	Private cTransp := "" as character
	Private cTransLj := "" as character
	Private nTotPed := 0 as numeric
	Private dGetEmi := Date()
	Private cGetLoj := cLoj
	Private cGetFor := cFor
	Private cContat := Space( TAMSX3( 'C7_CONTATO' )[01] )
	Private cGetMai := Space( TAMSX3( 'A2_EMAIL'   )[01] )
	Private cGetCon := Space( TAMSX3( 'C7_COND'    )[01] )
	Private cGetDes := Space( TAMSX3( 'E4_DESCRI'  )[01] )
	Private cGetCom := Space( TAMSX3( 'Y1_COD'     )[1] )
	Private oBrwCar := Nil
	Private oLblMai := Nil
	Private oLblNum	:= Nil
	Private oLblCnd := Nil
	Private oDlgCar := Nil 
	Private nPerFre := 0 as numeric
	Private cCboFrt := 'C'
	Private nGetFre := 0 as numeric
	Private nTot1UN := 0 as numeric
	Private nTot2UN := 0 as numeric
	
	// Seta um hot key no Ctrl + R
	SetKey( K_CTRL_R, {|| fReplica( aCbo, cCbo ) } )

	// Adiciona as diferentes filiais ao combo
	if len( aCarFil ) > 0
		for nX := 1 to len( aCarFil )
			cFil := aCarFil[nX][len( aCarFil[nX])]
			if aScan( aCbo, {|y| SubStr(y,1,len(cFilAnt)) == cFil } ) == 0
				aAdd( aCbo, cFil+'='+ fName(cFil) )
			endif
		next nX
	else
		MsgStop( "Vetor aCarFil que controla carrinho de compras por filial está corrompido!",'A T E N Ç Ã O !' )
		Return ( Nil )
	endif
	cCbo := SubStr(aCbo[1],1,len(cFilAnt))

	cGetCon := RetField( 'SA2', 1, xFilial( 'SA2' ) + cGetFor + cGetLoj, 'A2_COND' )
	cGetDes := RetField( 'SE4', 1, xFilial( 'SE4' ) + cGetCon, 'E4_DESCRI' )
	cGetMai := RetField( 'SA2', 1, xFilial( 'SA2' ) + cGetFor + cGetLoj, 'A2_EMAIL' )
	cContat := RetField( 'SA2', 1, xFilial( 'SA2' ) + cGetFor + cGetLoj, 'A2_CONTATO' )
	cTitulo := "CARRINHO DE COMPRAS" + iif( !Empty( cGetFor ), " - " + AllTrim( RetField( 'SA2', 1, xFilial( 'SA2' ) + cGetFor + cGetLoj, 'A2_NOME' ) ), '' )    
	if cCboFrt == 'C'		// Transportadora
		lUsaTrans  := SC7->( FieldPos( 'C7_X_TRANS' ) ) > 0 .and. X3Uso( GetSX3Cache( 'C7_X_TRANS', 'X3_USADO' ) )
		cTransp    := RetField( 'SA2', 1, xFilial( 'SA2' ) + cGetFor + cGetLoj, 'A2_TRANSP' )
		cPicTransp := PesqPict( 'SC7', 'C7_X_TRANS' )
		cPicName   := PesqPict( 'SA4', 'A4_NREDUZ' )
	else						// Fornecedor
		cPicTransp := PesqPict( 'SC7', 'C7_TRANSP' )
		lUsaTrans  := SC7->( FieldPos( 'C7_TRANSP' ) ) > 0 .and. SC7->( FieldPos( 'C7_TRANSLJ' ) ) > 0
		cTransp    := Space( iif( SC7->( FieldPos( 'C7_TRANSP' ) ) > 0, TAMSX3( 'C7_TRANSP' )[1], TAMSX3( 'A2_COD' )[1] ) )
		cTransLj   := Space( iif( SC7->( FieldPos( 'C7_TRANSLJ' ) ) > 0, TAMSX3( 'C7_TRANSLJ' )[1], TAMSX3( 'C7_TRANSLJ' )[1] ) )
		cPicName   := PesqPict( 'SA2', 'A2_NREDUZ' )
	endif
	
	// Verifica os itens do carrinho que pertencem ao fornecedor em questão
	aCarrinho := getCarrinho( cGetFor, cGetLoj, cCbo, aHeaCar ) 
	
	// Ordena os produtos do carrinho por nome do produto
	aSort( aCarrinho,,,{|x,y| x[carPos('C7_DESCRI')] < y[carPos('C7_DESCRI')] } )	

	// Dialog do carrinho de compras
	nWidth := (aSize[5]/2)*0.7
	oDlgCar := TDialog():New( 0, 0, aSize[6]*0.8, aSize[5]*0.8,cTitulo,,,,,CLR_BLACK,CLR_WHITE,,,.T.)
    
	nCol := 6
	nLin := 36
	@ nLin, nCol SAY oLblFil PROMPT "Filial:"                SIZE nWidth*0.19, 007 OF oDlgCar COLORS 0, 16777215 PIXEL
	nCol += nWidth*0.2
    @ nLin, nCol SAY oLblEmi PROMPT "Dt. Emissão:"           SIZE nWidth*0.13, 007 OF oDlgCar COLORS 0, 16777215 PIXEL
	nCol += nWidth*0.14

	if _cPedSol == '1'	// Exibe dados de fornecedor apenas quando for pedido
		@ nLin, nCol SAY oLblFor PROMPT "Fornecedor:"            SIZE nWidth*0.14, 007 OF oDlgCar COLORS 0, 16777215 PIXEL
		nCol += nWidth*0.15
		@ nLin, nCol SAY oLblMai PROMPT "E-mail Forn."           SIZE nWidth*0.16, 007 OF oDlgCar COLORS 0, 16777215 PIXEL
		nCol += nWidth*0.17
		@ nLin, nCol SAY oLbCont PROMPT "Contato:"               SIZE nWidth*0.08, 007 OF oDlgCar COLORS 0, 16777215 PIXEL
		nCol += nWidth*0.09
		@ nLin, nCol SAY oLblCnd PROMPT "Condição de Pagamento:" SIZE nWidth*0.24, 007 OF oDlgCar COLORS 0, 16777215 PIXEL
		nCol += nWidth*0.25
	elseif _cPedSol == '2'	// Solicitação
		@ nLin, nCol SAY oLblFor PROMPT "Comprador:"            SIZE nWidth*0.08, 007 OF oDlgCar COLORS 0, 16777215 PIXEL
		nCol += nWidth*0.09
	endif

	nCol := 6
	nLin := 44
	oCbo := TComboBox():New(nLin,nCol,{|u|if(PCount()>0,cCbo:=u,cCbo)}, aCbo,nWidth*0.19,13,oDlgCar,,;
			{||alterFil( oBrwCar, cCbo, cGetFor, cGetLoj ),fChgCar()},,,,.T.,,,,,,,,,'cCbo')
	nCol += nWidth*0.20
    @ nLin, nCol MSGET oGetEmi VAR dGetEmi SIZE nWidth*0.13, 011 OF oDlgCar COLORS 0, 16777215 WHEN .T. PIXEL
	nCol += nWidth*0.14

	if _cPedSol == '1'		// Quando pedido de compra, exibe dados de fornecedor
		@ nLin, nCol MSGET oGetFor VAR cGetFor SIZE nWidth*0.09, 011 OF oDlgCar COLORS 0, 16777215 VALID fValFor() WHEN .T. F3 "SA2" PIXEL
		oGetFor:bChange := {|| cGetCon := RetField( 'SA2', 1, xFilial( 'SA2' ) + cGetFor + cGetLoj, 'A2_COND' ),;
							cGetDes := RetField( 'SE4', 1, xFilial( 'SE4' ) + cGetCon, 'E4_DESCRI' ),;
							cGetMai := RetField( 'SA2', 1, xFilial( 'SA2' ) + cGetFor + cGetLoj, 'A2_EMAIL' ),;
							cContat := RetField( 'SA2', 1, xFilial( 'SA2' ) + cGetFor + cGetLoj, 'A2_CONTATO' ),;
							oGetCon:CtrlRefresh(),;
							oGetDes:CtrlRefresh(),;
							oGetMai:CtrlRefresh(),;
							oContat:CtrlRefresh() }
		nCol += nWidth*0.1
		@ nLin, nCol MSGET oGetLoj VAR cGetLoj SIZE nWidth*0.04, 011 OF oDlgCar COLORS 0, 16777215 VALID fValFor() PIXEL
		nCol += nWidth*0.05
		@ nLin, nCol MSGET oGetMai VAR cGetMai SIZE nWidth*0.16, 011 OF oDlgCar COLORS 0, 16777215 VALID fMailFor() WHEN .T. PIXEL
		nCol += nWidth*0.17
		@ nLin, nCol MSGET oContat VAR cContat SIZE nWidth*0.08, 011 OF oDlgCar COLORS 0, 16777215 VALID fContFor() WHEN .T. PIXEL
		nCol += nWidth*0.09
		@ nLin, nCol MSGET oGetCon VAR cGetCon SIZE nWidth*0.04, 011 OF oDlgCar COLORS 0, 16777215 VALID fValCon() WHEN .T. F3 "SE4" PIXEL
		nCol += nWidth*0.05
		@ nLin, nCol MSGET oGetDes VAR cGetDes SIZE nWidth*0.19, 011 OF oDlgCar COLORS 0, 16777215 WHEN .F. PIXEL
	elseif _cPedSol == '2'		// Solicitação de Compra
		@ nLin, nCol MSGET oGetCom VAR cGetCom SIZE nWidth*0.08, 011 OF oDlgCar COLORS 0, 16777215 VALID Vazio() .or. ExistCpo( "SY1", cGetCom ) F3 "SY1" PIXEL
		nCol += nWidth*0.09
	endif

	nLin := 58
	oBrwCar := MsNewGetDados():New( nLin, 004, nVer-40, nHor-04, GD_DELETE+GD_UPDATE, "AllwaysTrue", "AllwaysTrue", "", aAltCar,, Len( aCarrinho ), "U_FMANCAR", "", "AllwaysTrue", oDlgCar, aHeaCar, aCarrinho )
    // oBrwCar:oBrowse:bChange := {|| fChgCar() }
    oBrwCar:oBrowse:bDelOk := {|| fBrwDel() }

	nCol := 6
	nLin := nVer - 30

	if _cPedSol == '1'		// Quando fechamento for com pedido de compra, exibe campos de frete

		oCboFrt := TComboBox():New( nLin, nCol,{|u|if(PCount()>0,cCboFrt:=u,cCboFrt)}, {"C=CIF","F=FOB","S=Sem Frete"},50,14,oDlgCar,,{|| cCboFrt := SubStr( cCboFrt,1,1 ),;
																																		fchgObjFr( oTransp, cCboFrt, @cDescTran, oDescTran ),;
																																		fChgCar() },,,,.T.,,,,,,,,,'cCboFrt', 'Tp.Frete', 1)

		nCol += 60
		if lUsaFrete		// Verifica se o campo do valor do frete está em uso no ambiente do cliente
			oGetFre := TGet():New( nLin, nCol,{|u|if(PCount()==0,nGetFre,nGetFre:=u)},oDlgCar,60,011,PesqPict( 'SC7', 'C7_VALFRE' ),,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'nGetFre',,,,.T.,.F.,,'Valor Frete',1 )
			oGetFre:bChange := {|| lPrice := .T., fChgCar() }
			oGetFre:bWhen := {|| SubStr(cCboFrt,1,1) $ 'C|F' }
			nCol += 70

			oPerFre := TGet():New( nLin, nCol,{|u|if(PCount()==0,nPerFre,nPerFre:=u)},oDlgCar,30,011,"@E 999.99",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'nPerFre',,,,.T.,.F.,,'% Frete',1 )
			oPerFre:bChange := {|| lPrice := .F., fChgCar() }
			oPerFre:bWhen := {|| SubStr(cCboFrt,1,1) $ 'C|F' }
			nCol += 40
		endif 

		if lUsaTrans

			oTransp := TGet():New( nLin, nCol, {|u| if( PCount()==0,cTransp,cTransp:=u ) }, oDlgCar, 040, 011, cPicTransp,,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'cTransp',,,,.T.,.F.,,'Transp.',1 )
			oTransp:cF3 := iif( cCboFrt == 'C', 'SA4', 'SA2')
			if cCboFrt == 'C'		// Transportadora 
				oTransp:bChange := {|| cDescTran := RetField( 'SA4', 1, FWxFilial( 'SA4' ) + cTransp, 'A4_NREDUZ' ) }
			else						// Fornecedor
				oTransp:bChange := {|| cDescTran := RetField( 'SA2', 1, FWxFilial( 'SA2' ) + cTransp + AllTrim(cTransLj), 'A2_NREDUZ' ) }
			endif
			oTransp:bValid := {|| Empty( cTransp ) .or. ExistCpo( iif( cCboFrt == 'C', 'SA4', 'SA2'), cTransp + iif( cCboFrt == 'F', AllTrim(cTransLj), '' ) ) }
			oTransp:bWhen  := {|| ( SubStr(cCboFrt,1,1) == 'C' .and. X3Uso(GetSX3Cache('C7_X_TRANS','X3_USADO')) ) .or. ( SubStr(cCboFrt,1,1) == 'F' .and. X3Uso(GetSX3Cache('C7_TRANSP','X3_USADO')) ) }
			nCol += 45

			if cCboFrt == 'F'	// Fornecedor
				oTransLj         := TGet():New( nLin, nCol, {|u| if( PCount()==0,cTransLj,cTransLj:=u ) }, oDlgCar, 020, 011, GetSX3Cache( 'C7_TRANSLJ', 'X3_PICTURE' ),,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'cTransLj',,,,.T.,.F.,,'Loja',1 )
				oTransLj:bChange := {|| cDescTran := RetField( 'SA2', 1, FWxFilial( 'SA2' ) + cTransp + AllTrim(cTransLj), 'A2_NREDUZ' ) }
				oTransLj:bValid  := {|| (Empty( cTransp ) .and. Empty( cTransLj )) .or. ExistCpo( 'SA2', cTransp + AllTrim(cTransLj) ) }
				oTransLj:bWhen   := {|| cCboFrt == 'F' .and. X3Uso(GetSX3Cache('C7_TRANSLJ','X3_USADO')) }
				nCol += 25
			endif

			oDescTran := TGet():New( nLin, nCol, {|u| if( PCount()==0,cDescTran,cDescTran:=u ) }, oDlgCar, 080, 011, cPicName,,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'cDescTran',,,,.T.,.F.,,'Nome Transp.',1 )
			oDescTran:bWhen := {|| .F. }
			nCol += 90

		endif

	endif

	if _cPedSol == '1'	// Quando pedido de compra, exibe campo de valor de desconto negociado com fornecedor
		oDescont := TGet():New( nLin, nCol, {|u| if( PCount()==0,nDescont,nDescont:=u ) }, oDlgCar, 080, 011, PesqPict( 'SC7', 'C7_VLDESC' ),,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'nDescont',,,,.T.,.F.,,'Vlr.Desc.',1 )
		oDescont:bChange := {|| fChgCar() }
		nCol += 90
	endif

	oTotal := TGet():New( nLin, nCol, {|u| if( PCount()==0,nTotPed,nTotPed:=u ) }, oDlgCar, 080, 011, "@E 9,999,999.99",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'nTotPed',,,,.T.,.F.,,'Total do Pedido',1 )
	oTotal:bWhen := {|| .F. }

	nCol += 90

	oTot1UN := TGet():New( nLin, nCol, {|u| if( PCount()==0,nTot1UN,nTot1UN:=u ) }, oDlgCar, 060, 011, PesqPict( 'SC7', 'C7_QUANT' ),,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'nTot1UN',,,,.T.,.F.,,'Qtd.1a UN',1 )
	oTot1UN:bWhen := {|| .F. }

	nCol += 70

	oTot2UN := TGet():New( nLin, nCol, {|u| if( PCount()==0,nTot2UN,nTot2UN:=u ) }, oDlgCar, 060, 011, PesqPict( 'SC7', 'C7_QTSEGUM' ),,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'nTot2UN',,,,.T.,.F.,,'Qtd.2a UN',1 )
	oTot2UN:bWhen := {|| .F. }
                                                                                                    
	oDlgCar:Activate(,,,.T., bValid,,bInit)
	
	if lOk
		oBrwFor:LineRefresh()
		Processa( {|| fLoadInf() }, 'Aguarde!','Buscando informações dos produtos...' )
	EndIf
	
	SetKey( K_CTRL_R, {|| Nil } )
	SetKey( VK_F5, {|| Processa( {|| fLoadInf() }, 'Aguarde!','Analisando dados do MRP...' ) } )
	SetKey( VK_F12, {|| fManPar() } )
	
Return ( Nil )

/*/{Protheus.doc} fChgObjFr
Função para alterar configurações do objeto relacionado ao tipo de frete do pedido de compra
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 5/12/2025
@param oTrans, object, Objeto onde é informada a transportadora
@param oLoja, object, Loja da transportadora (quando utilizado fornecedor)
@param cCbo, character, Combo do tipo de frete
/*/
static function fChgObjFr( oTrans, cCbo, cDescTran, oDescTran )
	
	if cCbo == 'C'		// Cif
		cTransp := CriaVar( 'C7_X_TRANS' )
		cTransLj := Nil
		oTrans:bChange := {|| cDescTran := RetField( 'SA4', 1, FWxFilial( 'SA4' ) + cTransp, 'A4_NREDUZ' ) }
		oTrans:cF3 := "SA4"
		cDescTran  := Space( TAMSX3('A4_NREDUZ')[1] )
	else
		cTransp := CriaVar( 'C7_TRANSP' )
		oTrans:bChange := {|| cDescTran := RetField( 'SA2', 1, FWxFilial( 'SA2' ) + cTransp + AllTrim(cTransLj), 'A2_NREDUZ' ) }
		oTrans:cF3 := "SA2"
		cTransLj := CriaVar( 'C7_TRANSLJ' )
		cDescTran := Space( TAMSX3('A2_NREDUZ')[1] )
	endif
	nGetFre := 0
	nPerFre := 0	
	
	oTrans:CtrlRefresh()
	oDescTran:CtrlRefresh()

return Nil

/*/{Protheus.doc} fReplica
Função de replicação de dados do carrinho para facilitar processo de preenchimento dos dados
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 3/20/2025
/*/
Static Function fReplica( aCbo, cCbo )
	
	local nX     := 0 as numeric
	local cField := "" as character
	local xInfo  := Nil
	local nLin   := 0 as numeric
	local nLinPro := 0 as numeric
	local nProFil := 0 as numeric
	local nQtdPro := 0 as numeric
	local nCbo    := aScan( aCbo, {|x| SubStr(x,1,len(cFilAnt)) == cCbo } )
	
	if oBrwCar != Nil .and. Len( oBrwCar:aCols ) > 0
		
		if aScan( aAltCar, {|x| AllTrim( x ) == AllTrim( oBrwCar:aHeader[oBrwCar:oBrowse:ColPos()][02] ) } ) > 0
			if MsgYesNo( 'Tem certeza que deseja resplicar o conteúdo do campo <b>'+ oBrwCar:aHeader[oBrwCar:oBrowse:ColPos()][01] +'</b>','Está certo disso?' )
				xInfo := oBrwCar:aCols[ oBrwCar:nAt ][ oBrwCar:oBrowse:ColPos() ]
				cField := AllTrim( oBrwCar:aHeader[ oBrwCar:oBrowse:ColPos() ][02] )
				for nX := 1 to len( oBrwCar:aCols )
					
					oBrwCar:aCols[nX][oBrwCar:oBrowse:ColPos() ] := xInfo
					nLin := aScan(aCarFil,{|x| x[carPos('C7_PRODUTO')] == oBrwCar:aCols[nX][carPos('C7_PRODUTO')] .and.;
												x[carPos('C7_FORNECE')] == oBrwCar:aCols[nX][carPos('C7_FORNECE')] .and.;
												x[carPos('C7_LOJA')] == oBrwCar:aCols[nX][carPos('C7_LOJA')] .and.;
												x[len(x)] == SubStr(aCbo[nCbo],1,len(cFilAnt)) })
					
					nLinPro := aScan(aColPro,{|x| x[nPosPrd] == oBrwCar:aCols[nX][carPos('C7_PRODUTO')] .and.;
												x[nPosFor] == oBrwCar:aCols[nX][carPos('C7_FORNECE')] .and.;
												x[nPosLoj] == oBrwCar:aCols[nX][carPos('C7_LOJA')] })
					
					nProFil := aScan( _aProdFil, {|x| x[3] == oBrwCar:aCols[nX][carPos('C7_PRODUTO')] .and.;
													  x[25] == SubStr(aCbo[nCbo],1,len(cFilAnt)) } )

					if cField == "QUANT"
						
						oBrwCar:aCols[nX][ carPos( 'TOTAL' ) ] := xInfo * oBrwCar:aCols[nX][ carPos( 'PRECO' ) ]
						oBrwCar:aCols[nX][ carPos( 'QTSEGUM' ) ] := ConvUM( oBrwCar:aCols[nX][carPos('C7_PRODUTO')], xInfo, 0, 2 )
						aCarFil[nLin][ carPos( 'QUANT' ) ] := xInfo
						aCarFil[nLin][ carPos( 'TOTAL' ) ] := oBrwCar:aCols[nX][ carPos( 'TOTAL' ) ]
						_aProdFil[nProFil][6] := xInfo
						nQtdPro := 0
						aEval( _aProdFil, {|x| nQtdPro += iif( x[3] == oBrwCar:aCols[nX][carPos('C7_PRODUTO')], x[6], 0 ) } )
						aColPro[nPosNec] := nQtdPro

					elseif cField == 'PRECO'
						
						oBrwCar:aCols[nX][ carPos( 'TOTAL' ) ] := xInfo * oBrwCar:aCols[nX][ carPos( 'QUANT' ) ]
						oBrwCar:aCols[nX][ carPos( 'VALSEGUM' ) ] := iif( oBrwCar:aCols[nX][ carPos( 'QTSEGUM' ) ] > 0, oBrwCar:aCols[nX][ carPos( 'TOTAL' ) ] / oBrwCar:aCols[nX][ carPos( 'QTSEGUM' ) ], 0 )
						aCarFil[nLin][ carPos( 'PRECO' ) ] := xInfo
						aCarFil[nLin][ carPos( 'TOTAL' ) ] := oBrwCar:aCols[nX][ carPos( 'TOTAL' ) ]
						_aProdFil[nProFil][8] := xInfo
						aColPro[nLinPro][nPosNeg] := xInfo

					elseif cField == 'TOTAL'
						oBrwCar:aCols[nX][ carPos( 'PRECO' ) ] := xInfo / oBrwCar:aCols[nX][ carPos( 'QUANT' ) ]
						oBrwCar:aCols[nX][ carPos( 'VALSEGUM' ) ] := iif( oBrwCar:aCols[nX][ carPos( 'QTSEGUM' ) ] > 0, xInfo / oBrwCar:aCols[nX][ carPos( 'QTSEGUM' ) ], 0 )
						aCarFil[nLin][ carPos( 'TOTAL' ) ] := xInfo
						aCarFil[nLin][ carPos( 'PRECO' ) ] := oBrwCar:aCols[nX][ carPos( 'PRECO' ) ]
						_aProdFil[nProFil][8] := oBrwCar:aCols[nX][ carPos( 'PRECO' ) ]
						aColPro[nLinPro][nPosNeg] := oBrwCar:aCols[nX][ carPos( 'PRECO' ) ]

					elseif cField == 'VALSEGUM'
						oBrwCar:aCols[nX][ colPos( 'TOTAL' ) ] := xInfo * oBrwCar:aCols[nX][ carPos( 'QTSEGUM' ) ]
						oBrwCar:aCols[nX][ colPos( 'PRECO' ) ] := oBrwCar:aCols[nX][ colPos( 'TOTAL' ) ] / oBrwCar:aCols[nX][ carPos( 'QUANT' ) ]
						aCarFil[nLin][ carPos( 'TOTAL' ) ] := oBrwCar:aCols[nX][ colPos( 'TOTAL' ) ]
						aCarFil[nLin][ carPos( 'PRECO' ) ] := oBrwCar:aCols[nX][ colPos( 'PRECO' ) ]
						_aProdFil[nProFil][8] := oBrwCar:aCols[nX][ carPos( 'PRECO' ) ]
						aColPro[nLinPro][nPosNeg] := oBrwCar:aCols[nX][ carPos( 'PRECO' ) ]

					elseif cField == 'QTSEGUM'
						oBrwCar:aCols[nX][ colPos( 'TOTAL' ) ] := xInfo * oBrwCar:aCols[nX][ carPos( 'VALSEGUM' ) ]
						oBrwCar:aCols[nX][ colPos( 'QUANT' ) ] := oBrwCar:aCols[nX][ colPos( 'TOTAL' ) ] / oBrwCar:aCols[nX][ carPos( 'VALSEGUM' ) ]
						aCarFil[nLin][ colPos( 'TOTAL' ) ] := oBrwCar:aCols[nX][ colPos( 'TOTAL' ) ]
						aCarFil[nLin][ colPos( 'QUANT' ) ] := oBrwCar:aCols[nX][ colPos( 'QUANT' ) ]
						_aProdFil[nProFil][6] := oBrwCar:aCols[nX][ colPos( 'QUANT' ) ]
						nQtdPro := 0
						aEval( _aProdFil, {|x| nQtdPro += iif( x[3] == oBrwCar:aCols[nX][carPos('C7_PRODUTO')], x[6], 0 ) } )
						aColPro[nPosNec] := nQtdPro

					endif

				next nX
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
@param oCbo, object, objeto do combo
@param aCbo, array, array do combo
@param cCbo, character, conteúdo do combo
@param cFornece, character, fornecedor
@param cLoja, character, loja
@return logical, lAllOk - indica se conseguiu realizar a inclusão do pedido de compra
/*/
Static Function fGrvPed( oCbo, aCbo, cCbo, cFornece, cLoja )
	
	Local aCol := {} as array
	Local aHea := oBrwCar:aHeader
	Local aCab := {}
	Local aIte := {}
	Local aLin := {}
	Local nX   := 0
	Local nPrd := aScan( aHea, {|x| AllTrim( x[02] ) == 'C7_PRODUTO' } )
	Local nQtd := aScan( aHea, {|x| AllTrim( x[02] ) == 'QUANT'      } )
	Local nPrc := aScan( aHea, {|x| AllTrim( x[02] ) == 'PRECO'      } )
	Local nTot := aScan( aHea, {|x| AllTrim( x[02] ) == 'TOTAL'      } )
	Local nDes := aScan( aHea, {|x| AllTrim( x[02] ) == 'C7_DESCRI'  } )
	Local nUnM := aScan( aHea, {|x| AllTrim( x[02] ) == 'C7_UM'      } )
	Local nIni := aScan( aHea, {|x| AllTrim( x[02] ) == 'DINICOM'    } )
	Local nEnt := aScan( aHea, {|x| AllTrim( x[02] ) == 'DATPRF'     } )
	Local nLoc := aScan( aHea, {|x| AllTrim( x[02] ) == 'C7_LOCAL'   } )
	Local nObs := aScan( aHea, {|x| AllTrim( x[02] ) == 'C7_OBSM'    } )
	local nVFr := aScan( aHea, {|x| AllTrim( x[02] ) == 'C7_VALFRE'  } )
	local nDesc := aScan( aHea, {|x| AllTrim( x[02] ) == 'C7_VLDESC' } )
	local nCbo := 0 as numeric
	local lSuccess := .T. as logical
	local nField   := 0 as numeric
	local lPEPNC03 := ExistBlock( "PEPNC03" )
	local aRetPE   := Nil
	local nValFrt  := 0 as numeric
	local cItem    := StrZero( 0, TAMSX3('C7_ITEM')[1] )
	local aAuxWF   := {} as array
	local oProcess as object
	local oHTML    as object
	local cMailCom := "" as character
	local nLin     := 0 as numeric
	local cColor   := "" as character
	
	Private lMsErroAuto := .F.
	
	// Valida preenchimento dos dados do carrinho antes de prosseguir
	if ! fValPed()
		hlp( 'A T E N Ç Ã O ',;
			'Existem informações inconsistentes e/ou que não foram preenchidas corretamente.',;
			'Revise os dados do carrinho de compras e tente novamente.' )
		Return .F.
	endif

	ProcRegua( len( aCbo ) )

	if len( aCbo ) > 0
		for nCbo := 1 to len( aCbo )
			
			oCbo:Select( nCbo )
			aCol := oBrwCar:aCols
			
			nValFrt := 0
			aEval( aCol, {|x| nValFrt += iif( nVFr > 0, x[nVFr], 0 ) } )
			
			IncProc( 'Gerando '+ iif( _cPedSol == '1', 'pedido', 'solicitação' ) +' para a filial '+ cFilAnt +'...' )

			aCab := {}
			if _cPedSol == '1' // Pedido
				aAdd( aCab, { "C7_FILIAL"  , FWxFilial( 'SC7' ), Nil } )
				cDoc := GetSXENum("SC7","C7_NUM")
				SC7->(dbSetOrder(1))
				While SC7->(dbSeek(xFilial("SC7")+cDoc))
					ConfirmSX8()
					cDoc := GetSXENum("SC7","C7_NUM")
				EndDo
				ConfirmSX8()
				aAdd( aCab, { "C7_NUM"     , cDoc   , Nil } )
				aAdd( aCab, { "C7_EMISSAO" , dGetEmi, Nil } )
				aAdd( aCab, { "C7_FORNECE" , cGetFor, Nil } )
				aAdd( aCab, { "C7_LOJA"    , cGetLoj, Nil } )
				aAdd( aCab, { "C7_COND"    , cGetCon, Nil } )
				aAdd( aCab, { "C7_CONTATO" , cContat, Nil } )
				aAdd( aCab, { "C7_TPFRETE" , cCboFrt, Nil } )
				if nValFrt > 0
					if cCboFrt == 'C'		// CIF
						aAdd( aCab, { "C7_FRETE"  , nValFrt, Nil } )
					elseif cCboFrt == 'F'
						aAdd( aCab, { 'C7_FRETCON', nValFrt, Nil } )
						if SC7->( FieldPos( 'C7_TRANSP' ) ) > 0 .and. ! Empty( cTransp )
							aAdd( aCab, { "C7_TRANSP", cTransp, Nil } )
							aAdd( aCab, { "C7_TRANSLJ", cTransLj, Nil } )
						endif
					endif
				endif
				aAdd( aCab, { "C7_FILENT"  , SubStr(aCbo[nCbo],1,len(cFilAnt)), Nil } )
				
				aIte := {}
				For nX := 1 to Len( aCol )
					
					if !aCol[nX][Len(aHea)+1]
						
						cItem := Soma1(cItem)
						aAdd( aLin, { "C7_ITEM", cItem, Nil } )
						if nPrd > 0
							aAdd( aLin, { "C7_PRODUTO", aCol[nX][nPrd], Nil } )
						endif
						if nDes > 0
							aAdd( aLin, { "C7_DESCRI" , aCol[nX][nDes], Nil } )
						endif
						if nUnM > 0
							aAdd( aLin, { "C7_UM"     , aCol[nX][nUnM], Nil } )
						endif
						if nQtd > 0
							aAdd( aLin, { "C7_QUANT"  , aCol[nX][nQtd], Nil } )
						endif
						if nPrc > 0
							aAdd( aLin, { "C7_PRECO"  , aCol[nX][nPrc], Nil } )
						endif
						if nTot > 0
							aAdd( aLin, { "C7_TOTAL"  , aCol[nX][nTot], Nil } )
						endif
						if nIni > 0
							aAdd( aLin, { "C7_DINICOM", aCol[nX][nIni], Nil } )
						endif
						if nEnt > 0
							aAdd( aLin, { "C7_DATPRF" , aCol[nX][nEnt], Nil } )
						endif
						if nLoc > 0
							aAdd( aLin, { "C7_LOCAL"  , aCol[nX][nLoc], Nil } )
						endif
						if nObs > 0
							aAdd( aLin, { "C7_OBSM"    , aCol[nX][nObs], Nil } )
						endif

						if cCboFrt == 'C'		// Cif
							if SC7->( FieldPos( 'C7_X_TRANS' ) ) > 0 .and. X3Uso( GetSX3Cache( 'C7_X_TRANS', 'X3_USADO' ) ) .and. ! Empty( cTransp )
								aAdd( aLin, { "C7_X_TRANS", cTransp, Nil } )
							endif
							if nVFr > 0	.and. aCol[nX][nVFr] > 0
								aAdd( aLin, { "C7_VALFRE", aCol[nX][nVFr], Nil } )
							endif
						endif

						if carPos( 'QTSEGUM' ) > 0 .and. aCol[nX][carPos('QTSEGUM')] > 0
							aAdd( aLin, { "C7_QTSEGUM", aCol[nX][carPos('QTSEGUM')], Nil } )
						endif

						if nDesc > 0 .and. aCol[nX][nDesc] > 0
							aAdd( aLin, { "C7_VLDESC", aCol[nX][nDesc], Nil } )
						endif

						// Tratamento para adicionar gravação de campos que possam ter sido incluídos no header e no aCols através de pontos de entrada.
						for nField := 1 to len( aHea )
							if aScan( aLin, {|x| AllTrim(x[1]) == AllTrim(aHea[nField][2]) } ) == 0 .and.;
							aScan( aCab, {|x| AllTrim(x[1]) == AllTrim(aHea[nField][2]) } ) == 0 .and.; 
							SC7->( FieldPos( aHea[nField][2] ) ) > 0 .and. ! AllTrim(aHea[nField][2]) $ "C7_VALFRE"

								if ! ( GetSX3Cache( aHea[nField][2], 'X3_TIPO' ) $ "C|M" .and. Empty( aCol[nX][nField] ) )
									aAdd( aLin, { aHea[nField][2], aCol[nX][nField], Nil  } )
								endif
							endif
						next nField
						
						aAdd( aIte, aClone( aLin ) )
						aLin := {}
						
					EndIf
					
				Next nX
				
				if lPEPNC03
					// PE para gravação de dados complementares no pedido de compra
					aRetPE := ExecBlock( "PEPNC03",.F., .F., { aHea, aCol, aCab, aIte } )
					if ValType( aRetPE ) == 'A' .and. len( aRetPE ) == 2
						aCab := aClone( aRetPE[1] )
						aIte := aCLone( aRetPE[2] )
					endif
				endif

				lMsErroAuto := .F.
				MSExecAuto({|a,b,c,d| MATA120(a,b,c,d)}, 1, aCab, aIte, 3 )
				
				if lMsErroAuto
					lSuccess := .F.
					MostraErro()
				Else 
					
					// Remove os registros por filial
					for nX := 1 to len( aCol )
						aDel( aCarFil, aScan( aCarFil, {|x| x[carPos('C7_PRODUTO')] == aCol[nX][carPos('C7_PRODUTO')] .and.;
															x[carPos('C7_FORNECE')] == aCol[nX][carPos('C7_FORNECE')] .and.;
															x[carPos('C7_LOJA')]    == aCol[nX][carPos('C7_LOJA')] .and.;
															x[len(x)] == SubStr(aCbo[nCbo],1,len(cFilAnt)) } ) )		
						aSize( aCarFil, len( aCarFil )-1 )		
					next nX

					if MsgYesNo( 'Pedido de compra número <b>'+ SC7->C7_NUM +'</b> gerado com SUCESSO!'+;
								 iif( ! SubStr(aCbo[nCbo],1,len(cFilAnt)) == cFilAnt, ' Entrega na filial: '+ SubStr(aCbo[nCbo],1,len(cFilAnt)), '' )  +'. Deseja realizar a impressão do pedido?','S U C E S S O ! Pedido Nro. '+ SC7->C7_NUM +'' )
						GMPCPrint( SC7->C7_FILIAL, SC7->C7_NUM )
					endif

					if AllTrim(SuperGetMv( "MV_ENVPED",, '0')) $ '1|2' .and.; 
					MsgYesNo( 'Gostaria de realizar o envio do pedido de compra diretamente para o e-mail do fornecedor?', 'Enviar Pedido por e-Mail?' )
						Processa({|| sndMail( SC7->C7_NUM ), 'Preparando envio de e-mail para o fornecedor...', 'Aguarde' }) 
					endif
				EndIf
			else
				DBSelectArea( 'SC1' )
				SC1->( DBSetOrder( 1 ) )

				aAdd( aCab, { "C1_FILIAL"  , FWxFilial( 'SC1' ), Nil } )
				cDoc := GetSXENum("SC1","C1_NUM")
				SC1->(dbSetOrder(1))
				While SC1->(dbSeek(xFilial("SC1")+cDoc))
					ConfirmSX8()
					cDoc := GetSXENum("SC1","C1_NUM")
				EndDo
				ConfirmSX8()
				aAdd( aCab, { "C1_NUM"     , cDoc   , Nil } )
				aAdd( aCab, { "C1_EMISSAO" , dGetEmi, Nil } )
				aAdd( aCab, { "C1_SOLICIT" , cUserName, Nil } )
				if ! Empty( cGetCom ) 	// Verifica se o código do comprador está preenchido para enviar na execauto
					aAdd( aCab, { "C1_CODCOMP" , cGetCom, Nil } )
				endif
				aAdd( aCab, { "C1_FILENT"  , SubStr(aCbo[nCbo],1,len(cFilAnt)), Nil } )
				
				aIte := {}
				For nX := 1 to Len( aCol )
					
					if !aCol[nX][Len(aHea)+1]
						
						cItem := Soma1(cItem)
						aAdd( aLin, { "C1_ITEM", cItem, Nil } )
						if nPrd > 0
							aAdd( aLin, { "C1_PRODUTO", aCol[nX][nPrd], Nil } )
						endif
						if nUnM > 0
							aAdd( aLin, { "C1_UM"     , aCol[nX][nUnM], Nil } )
						endif
						
						if nPrc > 0
							aAdd( aLin, { "C1_OBS"  , aCol[nX][nObs], Nil } )
						endif
						if nIni > 0
							aAdd( aLin, { "C1_EMISSAO", aCol[nX][nIni], Nil } )
						endif
						if nEnt > 0
							aAdd( aLin, { "C1_DATPRF" , aCol[nX][nEnt], Nil } )
						endif
						if nLoc > 0
							aAdd( aLin, { "C1_LOCAL"  , aCol[nX][nLoc], Nil } )
						endif

						if nQtd > 0
							aAdd( aLin, { "C1_QUANT"  , aCol[nX][nQtd], Nil } )
						endif

						if nPrc > 0 .and. aCol[nX][nPrc] > 0
							aAdd( aLin, { "C1_VUNIT", aCol[nX][nPrc], Nil } )
						endif
						
						aAdd( aIte, aClone( aLin ) )
						aLin := {}
						
					EndIf
					
				Next nX

				lMsErroAuto := .F.
				MSExecAuto({|a,b,c| MATA110(a,b,c)}, aCab, aIte, 3 )
				
				if lMsErroAuto
					lSuccess := .F.
					MostraErro()
				Else 
					
					// Remove os registros por filial
					for nX := 1 to len( aCol )
						aDel( aCarFil, aScan( aCarFil, {|x| x[carPos('C7_PRODUTO')] == aCol[nX][carPos('C7_PRODUTO')] .and.;
															x[carPos('C7_FORNECE')] == aCol[nX][carPos('C7_FORNECE')] .and.;
															x[carPos('C7_LOJA')]    == aCol[nX][carPos('C7_LOJA')] .and.;
															x[len(x)] == SubStr(aCbo[nCbo],1,len(cFilAnt)) } ) )		
						aSize( aCarFil, len( aCarFil )-1 )		
					next nX

					aAuxWF   := U_JSWFSOL()
					cMailCom := getMailCom( cGetCom )
					// Valida estrutura e tambem existência de comprador ligado à solicitação
					if len( aAuxWF ) == 2 .and. aAuxWF[1] .and. ! Empty( cMailCom )
						If MsgYesNo('Solicitação de compra número <b>'+ SC1->C1_NUM +'</b> gerada com SUCESSO para a filial '+ cFilAnt +', gostaria de enviar notificação (workflow) ao comprador?', 'S U C E S S O ! Solicitação '+ SC1->C1_NUM )
							
							oProcess := TWFProcess():new( "JSPAICOM", OemToAnsi( 'Solicitação de Compra' ) )
							oProcess:NewTask( "SOLICITA", aAuxWF[2] )
							oProcess:cSubject := "[PAINEL DE COMPRAS] Nova Solicitação número "+ SC1->C1_NUM
							oProcess:cTo      := cMailCom				

							oHTML := oProcess:oHTML
							oHTML:ValByName("EMPRESA", OemToAnsi( SM0->M0_FILIAL ) )
							oHTML:ValByName("TITULOMSG", OemToAnsi( "Nova Solicitação incluída com número "+ SC1->C1_NUM ) )
							oHTML:ValByName("SOLICITACAO", OemToAnsi( SC1->C1_NUM ) )
							oHTML:ValByName("USUARIO", OemToAnsi( Capital( AllTrim( UsrFullName( __cUserID ) ) ) ) )
							oHTML:ValByName("DATAHORA", OemToAnsi( FWTimeStamp(2) ) )
							
							for nX := 1 to len( aCol )
								nLin++	

								if nLin % 2 != 0
									cColor := "#dcdcdc"
								Else
									cColor := "#fff"
								EndIf
								
								aAdd((oHTML:ValByName("IT.CLPRODUTO"     )), cColor  )
								aAdd((oHTML:ValByName("IT.PRODUTO"       )), AllTrim( aCol[nX][nPrd] ) )
								aAdd((oHTML:ValByName("IT.CLDESCRICAO"   )), cColor  )
								aAdd((oHTML:ValByName("IT.DESCRICAO"     )), AllTrim( RetField( 'SB1', 1, FWxFilial( 'SB1' ) + aCol[nX][nPrd], 'B1_DESC' ) ) )
								aAdd((oHTML:ValByName("IT.CLUNIMED"      )), cColor  )
								aAdd((oHTML:ValByName("IT.UNIMED"        )), AllTrim( aCol[nX][nUnM] ) )
								aAdd((oHTML:ValByName("IT.CLNECESSIDADE" )), cColor  )
								aAdd((oHTML:ValByName("IT.NECESSIDADE"   )), AllTrim( Transform( aCol[nX][nQtd], GetSX3Cache( 'C1_QUANT', 'X3_PICTURE' ) ) ) )

							next nX

							oProcess:Start()
							oProcess:Finish()
							WFSENDMAIL()

						endif
					else
						MsgInfo( 'Solicitação de compra número <b>'+ SC1->C1_NUM +'</b> gerada com SUCESSO para a filial '+ cFilAnt +'!','S U C E S S O ! Solicitação '+ SC1->C1_NUM )
					endif

				EndIf
			endif

		next nCbo
	endif

	if lSuccess
		
		// Se realizou inclusão do pedido de compra, manda atualizar todo o grid do painel		
		RecLock( 'FORTMP', .F. )
		FORTMP->PEDIDO := 'N'
		FORTMP->( MsUnlock() )

		// Remove todos os itens do carrinho
		while aScan( aCarCom, {|x| x[carPos('C7_FORNECE')] == cFornece .and. x[carPos('C7_LOJA')] == cLoja } ) > 0
			aDel( aCarCom, aScan( aCarCom, {|x| x[carPos('C7_FORNECE')] == cFornece .and. x[carPos('C7_LOJA')] == cLoja } ) )
			aSize( aCarCom, Len( aCarCom )-1 )
		end
		
	endif
	
Return ( lSuccess )

/*/{Protheus.doc} getMailCom
FUnção para obter o e-mail do comprador relacionado à solicitação de compra
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 5/6/2025
@param cGetCom, character, ID do comprador
@return character, cMailCom
/*/
static function getMailCom( cGetCom )
	local cMailCom := "" as character
	local cAux     := "" as character
	default cGetCom := ""
	if ! Empty( cGetCom )
		DBSelectArea( 'SY1' )
		SY1->( DBSetOrder( 1 ) )
		if SY1->( DBSeek( FWxFilial( 'SY1' ) + cGetCom ) )
			cMailCom += AllTrim( Lower( SY1->Y1_EMAIL ) )

			if ! Empty( SY1->Y1_USER )
				// Valida se o e-mail do usuário do sistema está preenchido e se não é o mesmo e-mail cadastrado no cadastro de comprador
				cAux := AllTrim( Lower( UsrRetMail( SY1->Y1_USER ) ) )
				if ! Empty( cAux ) .and. ! cAux $ cMailCom
					cMailCom += iif( !Empty(cMailCom),';','' ) + cAux
				endif
			endif
		endif
	endif
return cMailCom

/*/{Protheus.doc} GMPCPRINT
Função para geração automática do pedido de compra diretamente pela tela do painel
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 6/6/2022
@param cPC, character, Número do pedido de compra
/*/
Static Function GMPCPRINT( cFil, cPC )
	
	local aArea    := getArea()
	// Local oRep     := Nil
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
		if ! SC7->( DBSeek( cFil + cPC ) )
			restArea( aArea )
			MsgStop( 'Número do pedido de compra <b>'+ cPC +'</b> não foi recebido corretamente na função de impressão!','F A L H A' )
			return Nil
		endif
	endif
	
	MATR110( 'SC7', SC7->(Recno()), 1 )
	
	restArea( aArea )
Return ( Nil )

/*/{Protheus.doc} fContFor
Função para redefinir contato do fornecedor com base no nome de contato informado no momento do envio do pedido
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/26/2025
@return logical, lValidated
/*/
Static Function fContFor()
	
	Local aArea   := GetArea()
	Local lRet    := .T.
	Local cConDef := RetField( 'SA2', 1, xFilial( 'SA2' ) + cGetFor + cGetLoj, "A2_CONTATO" )
	
	if cContat != cConDef
		DbSelectArea( 'SA2' )
		SA2->( DbSetOrder( 1 ) )
		if DbSeek( xFilial( 'SA2' ) + cGetFor + cGetLoj )
			RecLock( 'SA2', .F. )
			SA2->A2_CONTATO := cContat
			SA2->( MsUnlock() )
		EndIf
	EndIf
	
	RestArea( aArea )
Return ( lRet )


/*/{Protheus.doc} fMailFor
Função que faz a checagem e alteração do e-mail do fornecedor quando informado um e-mail diferente pelo usuário do Painel de compras
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/26/2025
@return logical, lValidated
/*/
Static Function fMailFor()
	
	Local aArea   := GetArea()
	Local lRet    := .T.
	Local cMaiDef := RetField( 'SA2', 1, xFilial( 'SA2' ) + cGetFor + cGetLoj, "A2_EMAIL" )
	
	if !cGetMai == cMaiDef

		DbSelectArea( 'SA2' )
		SA2->( DbSetOrder( 1 ) )
		if DbSeek( xFilial( 'SA2' ) + cGetFor + cGetLoj )
			RecLock( 'SA2', .F. )
			SA2->A2_EMAIL := cGetMai
			SA2->( MsUnlock() )
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
	
	if _cPedSol == '1'		// Quando for pedido, valida preenchimento da condição de pagamento
		lRet := iif( Empty( cGetCon ), .F., lRet )
	endif
	lRet := iif( Len( aCol ) == 0, .F., lRet )
	if _cPedSol == '1'	// Quando for pedido, valida preenchimento do fornecedor
		lRet := iif( Empty( cGetFor ) .or. Empty( cGetLoj ), .F., lRet )
	endif
	aEval( aCol, {|x| lRet := iif( ( x[nQtd] == 0 .or. x[nPrc] == 0 .or. x[nTot] == 0 ) .and. !x[Len(aHea)+1], .F., lRet ) } )
	
Return ( lRet )

/*/{Protheus.doc} fValFor
Função para validar dados do fornecedor (codigo e loja)
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 3/7/2025
@return logical, lRet
/*/
Static Function fValFor()
	
	local cReadVar := ReadVar()
	Local lRet := .T. as logical
	local cFornece := "" as character
	local cLoja    := "" as character

	if 'CGETFOR' $ Upper( cReadVar )
		cFornece := &( cReadVar )
	else
		cFornece := cGetFor
	endif

	if 'CGETLOJ' $ Upper( cReadVar )
		cLoja := &( cReadVar )
	else
		cLoja := AllTrim( cGetLoj )
	endif

	// Valida se existe o cadastro e se não está inativo
	lRet := ExistCpo( 'SA2', cFornece + cLoja, 1 )
	
	if lRet 
		cGetMai := RetField( 'SA2', 1, xFilial( 'SA2' ) + cFornece + cLoja, 'A2_EMAIL' )
		cContat := RetField( 'SA2', 1, xFilial( 'SA2' ) + cFornece + cLoja, 'A2_CONTATO' )
		oDlgCar:CCAPTION := "CARRINHO DE COMPRAS" + " - " + AllTrim( RetField( 'SA2', 1, xFilial( 'SA2' ) + cFornece + cLoja, 'A2_NOME' ) )
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
	
	local nIndIPI  := 0 as numeric
	local lSuccess := .T. as logical
	local nQtd     := 0 as numeric
	local cReadVar := ReadVar()

	if oBrwCar:oBrowse:ColPos() == carPos( 'QUANT' )				// Se a alteração foi no campo de quantidade 
		if M->QUANT != Nil
			oBrwCar:aCols[oBrwCar:nAt][carPos( 'TOTAL' )] := M->QUANT * oBrwCar:aCols[oBrwCar:nAt][carPos('PRECO')]
			oBrwCar:aCols[oBrwCar:nAt][carPos( 'QTSEGUM' )] := ConvUM( oBrwCar:aCols[oBrwCar:nAt][carPos('C7_PRODUTO')],; 
																		&(cReadVar),;
																		0 /* nQtdSeg */,;
																		2 /* nRetQtd */ )
		EndIf 
	ElseIf oBrwCar:oBrowse:ColPos() == carPos('PRECO')			// alteração no campo do preço 
		if M->PRECO != Nil
			oBrwCar:aCols[oBrwCar:nAt][carPos( 'TOTAL' )] := oBrwCar:aCols[oBrwCar:nAt][carPos('QUANT')] * M->PRECO  
			oBrwCar:aCols[oBrwCar:nAt][carPos( 'VALSEGUM' )] := Round( oBrwCar:aCols[oBrwCar:nAt][carPos( 'TOTAL' )] / oBrwCar:aCols[oBrwCar:nAt][carPos( 'QTSEGUM' )], 2 ) 
		EndIf
	ElseIf oBrwCar:oBrowse:ColPos() == carPos( 'TOTAL' ) 			// alteração no campo do total
		if M->TOTAL != Nil
			oBrwCar:aCols[oBrwCar:nAt][carPos('PRECO')] := M->TOTAL / iif( oBrwCar:aCols[oBrwCar:nAt][carPos('QUANT')] > 0, oBrwCar:aCols[oBrwCar:nAt][carPos('QUANT')], 1 ) 
			oBrwCar:aCols[oBrwCar:nAt][carPos('VALSEGUM')] := Round( &(cReadVar) / iif( oBrwCar:aCols[oBrwCar:nAt][carPos('VALSEGUM')]  > 0, oBrwCar:aCols[oBrwCar:nAt][carPos('VALSEGUM')] , 1 ) , 2 )
		EndIf
	elseif oBrwCar:oBrowse:ColPos() == carPos( 'C7_IPI' )			// Alteração do índice de IPI
		oBrwCar:aCols[oBrwCar:nAt][carPos('C7_IPI')] := M->C7_IPI 
		nIndIPI := RetField( 'SB1', 1, FWxFilial( 'SB1' ) + oBrwCar:aCols[oBrwCar:nAt][carPos( 'C7_PRODUTO' )], 'B1_IPI' ) 
		if M->C7_IPI != nIndIPI
			if MsgYesNo( 'Gostaria de alterar a alíquota padrão de IPI do produto <b>'+ AllTrim( oBrwCar:aCols[oBrwCar:nAt][carPos('C7_DESCRI')] ) +'</b>?',; 
						'A T E N Ç Ã O !' )
				DBSelectArea( 'SB1' )
				SB1->( DBSetOrder( 1 ) )
				if SB1->(DBSeek( FWxFilial( 'SB1' ) + oBrwCar:aCols[oBrwCar:nAt][carPos('C7_PRODUTO')] )) 
					RecLock( 'SB1', .F. )
					SB1->B1_IPI := M->C7_IPI
					SB1->( MsUnlock() )
				else
					lSuccess := .F.
				endif
			endif
		endif
	elseif oBrwCar:oBrowse:ColPos() == carPos( 'QTSEGUM' ) 
	
		nQtd := ConvUM( oBrwCar:aCols[oBrwCar:nAt][carPos('C7_PRODUTO')],; 
							&(cReadVar),;
							&(cReadVar) /* nQtdSeg */,;
							1 /* nRetQtd */ )
		
		// AJusta quantidade conforme fator de conversão
		oBrwCar:aCols[oBrwCar:nAt][carPos('QUANT')]    := nQtd
		// Atualiza valor total da linha do produto 
		oBrwCar:aCols[oBrwCar:nAt][carPos('TOTAL')]    := nQtd * oBrwCar:aCols[oBrwCar:nAt][carPos('PRECO')]
		// Atualiza valor unitário da segunda unidade de medida
		oBrwCar:aCols[oBrwCar:nAt][carPos('VALSEGUM')] := oBrwCar:aCols[oBrwCar:nAt][carPos('TOTAL')] / &(cReadVar)
	
	elseif oBrwCar:oBrowse:ColPos() == carPos( 'VALSEGUM' )
 
		oBrwCar:aCols[oBrwCar:nAt][carPos('TOTAL')] := &( cReadVar ) * oBrwCar:aCols[oBrwCar:nAt][carPos('QTSEGUM')] 
		oBrwCar:aCols[oBrwCar:nAt][carPos('PRECO')] := oBrwCar:aCols[oBrwCar:nAt][carPos('TOTAL')] / oBrwCar:aCols[oBrwCar:nAt][carPos('QUANT')]

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
	local nDescRat := 0 as numeric
	local nPercIte := 0 as numeric
	local cReadVar := Upper(ReadVar())
	
	// Valida se existe conteúdo no aCols antes de prosseguir
	nTotPed := 0
	if oBrwCar != Nil .and. Len( oBrwCar:aCols ) > 0

		nTot1UN := 0
		nTot2UN := 0
		for nX := 1 to len( oBrwCar:aCols )
			if ! oBrwCar:aCols[nX][len(oBrwCar:aHeader)+1]
				if 'TOTAL' $ cReadVar .and. oBrwCar:nAt == nX
					nValTot += &( cReadVar )
				else
					nValTot += oBrwCar:aCols[nX][carPos('TOTAL')] 
				endif
				if 'C7_IPI' $ cReadVar .and. oBrwCar:nAt == nX
					nValIPI += Round(&(cReadVar)*nValTot,2)
				else
					nValIPI += Round((oBrwCar:aCols[nX][carPos('C7_IPI')]/100)*nValTot,2) 
				endif

				// Atualiza totalizadores quantitativos por unidade de medida
				nTot1UN += iif( 'QUANT' $ cReadVar .and. oBrwCar:nAt == nX, &(cReadVar), oBrwCar:aCols[nX][carPos('QUANT')] )
				nTot2UN += iif( 'QTSEGUM' $ cReadVar .and. oBrwCar:nAt == nX, &(cReadVar), oBrwCar:aCols[nX][carPos('QTSEGUM')] )

			endif
		next nX

		if carPos( 'C7_VALFRE' ) > 0
			if ! lPrice
				nPercent := nPerFre/100
				nGetFre  := Round( nValTot * (nPerFre/100), 2)
			else
				nPercent := nGetFre / nValTot
				nPerFre  := Round( nPercent * 100, 2)
			endif
			aEval( oBrwCar:aCols, {|x| nFreteIt := Round(x[carPos('TOTAL')]*nPercent,2),; 
									x[carPos('C7_VALFRE')] := nFreteIt,;
									nFrete += nFreteIt } )
			// Se ficou alguma diferença residual em virtude do arredondamento, ajusta no último item
			if nGetFre != nFrete 
				oBrwCar:aCols[len(oBrwCar:aCols)][carPos('C7_VALFRE')] += nGetFre - nFrete
			endif
		endif
		
		if carPos( 'C7_VLDESC' ) > 0	// Quando existir campo do valor de desconto no browse, faz o rateio do valor informado
			nDescRat := 0 
			for nX := 1 to len( oBrwCar:aCols )
				nPercIte := oBrwCar:aCols[nX][carPos('TOTAL')] / nValTot
				oBrwCar:aCols[nX][carPos( 'C7_VLDESC' )] := Round( iif( nX == len(oBrwCar:aCols), nDescont - nDescRat, nDescont * nPercIte ), TAMSX3('C7_VLDESC')[2] )
				nDescRat += oBrwCar:aCols[nX][carPos( 'C7_VLDESC' )]				
			next nX
		endif

		nTotPed := nValTot + nValIPI + nGetFre - nDescont
		oBrwCar:oBrowse:Refresh()
		oTotal:Refresh()
		oTot1UN:Refresh()
		oTot2UN:Refresh()

		dataProdUpd( oBrwCar, cCbo )
		oBrwPro:oBrowse:Refresh()
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
	aColumns[len(aColumns)]:SetData( {|| QRYEMP->NUMERO } )

	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( 'Item' )
	aColumns[len(aColumns)]:SetSize( TAMSX3( 'DC_ITEM' )[1] )
	aColumns[len(aColumns)]:SetType( 'C' )
	aColumns[len(aColumns)]:SetPicture( "@!" )
	aColumns[len(aColumns)]:SetData( {|| QRYEMP->ITEM } )

	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( 'Quant.' )
	aColumns[len(aColumns)]:SetSize( TAMSX3( 'DC_QUANT' )[1] )
	aColumns[len(aColumns)]:SetType( 'N' )
	aColumns[len(aColumns)]:SetPicture( GetSX3Cache( 'DC_QUANT', 'X3_PICTURE' ) )
	aColumns[len(aColumns)]:SetData( {|| QRYEMP->QUANT } )
	aColumns[len(aColumns)]:SetAlign( 2 )

	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( 'Tipo' )
	aColumns[len(aColumns)]:SetSize( 20 )
	aColumns[len(aColumns)]:SetType( 'C' )
	aColumns[len(aColumns)]:SetPicture( '@x' )
	aColumns[len(aColumns)]:SetData( {|| iif( QRYEMP->TIPO == '1', 'Pedido', 'Ordem de Produção' ) } )

	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( 'Armazém' )
	aColumns[len(aColumns)]:SetSize( TAMSX3( 'DC_LOCAL' )[1] )	
	aColumns[len(aColumns)]:SetType( 'C' )
	aColumns[len(aColumns)]:SetPicture( '@!' )
	aColumns[len(aColumns)]:SetData( {|| QRYEMP->ARMAZEM } )
	
	// Exibe coluna do endereço apenas quando o sistema estiver controlando endereçamento do produto
	if lEndereco		
		aAdd( aColumns, FWBrwColumn():New() )
		aColumns[len(aColumns)]:SetTitle( 'Endereço' )
		aColumns[len(aColumns)]:SetSize( TAMSX3( 'DC_LOCALIZ' )[1] )
		aColumns[len(aColumns)]:SetType( 'C' )
		aColumns[len(aColumns)]:SetPicture( '@!' )
		aColumns[len(aColumns)]:SetData( {|| QRYEMP->ENDERECO } )
	endif

	// Configura browse para exibição dos dados
	oBrowse := FWBrowse():New( oDlgEmp )
	oBrowse:SetAlias( 'QRYEMP' )
	oBrowse:SetDataQuery()
	oBrowse:DisableReport()
	oBrowse:DisableConfig()
	oBrowse:SetQuery( getQrEmp( cProduto, lEndereco ) )
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
		cQuery := "SELECT DC_PEDIDO NUMERO, DC_ITEM ITEM, DC_QUANT QUANT, CASE DC_ORIGEM WHEN 'SC6' THEN '1' ELSE '2' END TIPO, "
		cQuery += "       DC_LOCAL ARMAZEM, DC_LOCALIZ ENDERECO FROM "+ RetSqlName( 'SDC' ) +" DC "
		cQuery += "WHERE DC.DC_FILIAL  = '"+ FWxFilial( 'SDC' ) +"' "
		cQuery += "  AND DC.DC_PRODUTO = '"+ cProduto +"' "
		cQuery += "  AND DC.D_E_L_E_T_ = ' ' "
	else
		// Query para buscar empenhos do produto quando não há controle de endereçamento
		cQuery := "SELECT C9.C9_PEDIDO NUMERO, C9.C9_ITEM ITEM, C9.C9_QTDLIB QUANT, '1' TIPO, C9.C9_LOCAL ARMAZEM, "
		cQuery += "       ' ' ENDERECO FROM "+ RetSqlName( 'SC9' ) +" C9 "
		cQuery += "WHERE C9.C9_FILIAL   = '"+ FWxFilial( 'SC9' ) +"' "
		cQuery += "  AND C9.C9_PRODUTO  = '"+ cProduto +"' "
		cQuery += "  AND C9.C9_BLEST    = '  ' "
		cQuery += "  AND C9.C9_BLCRED   = '  ' "
		cQuery += "  AND C9.D_E_L_E_T_  = ' ' "
		cQuery += "UNION ALL "
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

/*/{Protheus.doc} A2LTMCHG
FUnção de validação da alteração do campo do Lead-Time do Fornecedor
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 6/28/2022
@return logical, lRet
/*/
static function A2LTMCHG()
	
	local lRet := .T. as logical

	if FORTMP->A2_X_LTIME < 0
		lRet := .F.
	else
		DBSelectArea( 'SA2' )
		SA2->( DBSetOrder( 1 ) )		// A2_FILIAL + A2_COD + A2_LOJA
		if SA2->( DBSeek( FWxFilial( 'SA2' ) + FORTMP->A2_COD + FORTMP->A2_LOJA ) )
			RecLock( 'SA2', .F. )
			SA2->A2_X_LTIME := FORTMP->A2_X_LTIME
			SA2->( MsUnlock() )

			Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' )
		endif
	endif

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
	local oGetGrp       as object
	local oGetProd 		as object
	local oLoja         as object
	local lCancel       := .F. as logical

	default lManual := .F.

	_aFilters := aClone( aFiltros )
	_cTypes   := _aFilters[2]
	
	oLookDlg := FWDialogModal():New()
	oLookDlg:SetEscClose( .F. )
	oLookDlg:SetTitle( 'Filtro de Seleção de Produtos' )
	oLookDlg:SetSubTitle( 'Defina os filtros para análise de compra dos produtos...' )
	oLookDlg:SetSize( 300, 200 )
	oLookDlg:CreateDialog()
	oLookDlg:AddCloseButton( {|| lCancel := .T., _aFilters := aClone(aFiltros), _aFilters[len(_aFilters)] := lCancel, oLookDlg:DeActivate() }, "Cancelar" )
	oLookDlg:AddOkButton( {|| iif( lManual .or. valFilPro( _aFilters ), oLookDlg:DeActivate(), Nil ), _aFilters[len(_aFilters)] := lCancel }, "Ok" )
	oContainer := TPanel():New( ,,, oLookDlg:getPanelMain() )
	oContainer:Align := CONTROL_ALIGN_ALLCLIENT

	oGetLook  := TGet():New( 10,04, {|u| if(PCount()==0,_aFilters[1],_aFilters[1]:=u)},oContainer,110,012,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'_aFilters[1]',,,,.T.,.F.,,'Expressão de filtro por nome', 1 )
	oGetTypes := TGet():New( 35,04, {|u| if(PCount()==0,_cTypes,_cTypes:=u)},oContainer,100,012,"@x",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'_cTypes',,,,.T.,.F.,,'Tipos de Produtos', 1 )
	oGetTypes:bWhen := {|| .F. }
	oBtnTypes := tBitmap():New( 43, 106, 12, 12,,"painel_compras_lupa.png", .T., oContainer,{|| _cTypes := U_JSPAITYP( _cTypes ),;
																						_aFilters[2] := _cTypes }, NIL, .F., .F., NIL, NIL, .F., NIL, .T., NIL, .F.)
	oGetFor   := TGet():New( 60,04, {|u| if(PCount()==0,_aFilters[3],_aFilters[3]:=u)},oContainer,70,012,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'_aFilters[3]',,,,.T.,.F.,,'Fornecedor', 1 )
	oGetFor:cF3 := "SA2"

	oLoja     := TGet():New( 60,86, {|u| if(PCount()==0,_aFilters[6],_aFilters[6]:=u)},oContainer,40,012,"@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'_aFilters[6]',,,,.T.,.F.,,'Loja', 1 )

	oGetGrp   := TGet():New(85,04, {|u| if(PCount()==0,_aFilters[4],_aFilters[4]:=u)},oContainer,70,012,"@x",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'_aFilters[4]',,,,.T.,.F.,,'Grupo Produto', 1 )
	oGetGrp:cF3 := GetSX3Cache( cFdGroup, 'X3_F3' )

	oGetProd   := TGet():New(110,04, {|u| if(PCount()==0,_aFilters[5],_aFilters[5]:=u)},oContainer,80,012,"@x",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'_aFilters[5]',,,,.T.,.F.,,'Produto', 1 )
	oGetProd:cF3 := GetSX3Cache( 'A5_PRODUTO', 'X3_F3' )

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
	lValidated := len( AllTrim( aFiltros[1] ) ) >= 3 .or. !Empty( aFiltros[3] ) .or. !Empty( aFiltros[4] ) .or. !Empty( aFiltros[5] )
	if ! lValidated
		lValidated := MsgYesNo( 'Você está pesquisando uma faixa de dados muito grande, está certo(a) de que deseja prosseguir?', 'A T E N Ç Ã O !' )
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

/*/{Protheus.doc} impPrdFor
Função para importar vínculo de produto versus fornecedor no Protheus
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/13/2025
@return logical, lSuccess
/*/
static function impPrdFor()
	
	local lSuccess := .T. as logical
	local cPath    := "" as character

	// Obtem arquivo com patch completo a partir do smartclient do usuário
	cPatch := AllTrim( cGetFile( 'Arquivo CSV |*.csv',; 
								 'Selecione o arquivo CSV que gostariade importar...',;
								 0 /* nMascPad */,;
								 "" /* cInitDir */,;
								 .T. /* lOpen */,;
								 GETF_LOCALHARD,;
								 .F. /* lServerTree */,;
								 .T. /* lKeepCase */ ) )
	
	// Se retornar vazio, é porque usuário cancelou o processo antes de selecionar a pasta
	if ! Empty( cPatch )
		if File( cPatch )
			MsAguarde( {|| lSuccess := procPrdFor( cPatch ) }, 'Aguarde!','Importando vínculo de produto e fornecedor...' )
			if lSuccess
				MsgInfo( 'Arquivo '+ cPath +' importado com sucesso!', 'S U C E S S O !' )
			endif
		else
			Hlp( 'ARQUIVO INVALIDO',;
				 'Caminho ou nome do arquivo é inválido!',;
				 'Selecione outro arquivo ou verifique se o caminho informado para o arquivo é válido.' )
		endif
	endif

return lSuccess

/*/{Protheus.doc} impData
Função de importação dos dados de produtos via excel
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 26/06/2024
@return character, cLastRun
/*/
static function impData( cLast )

	local lSuccess := .T. as logical
	local cPatch   := "" as character
	local cLastRun := "" as character
	
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
				if GetMv( 'MV_X_PNC12', .T. /* lCheck */ )
					cLastRun := GetMv( 'MV_X_PNC12' )
				else
					cLastRun := cLast
				endif
				Processa( {|| fLoadInf() }, 'Aguarde!','Analisando dados do MRP...' )
			endif
		else
			Hlp( 'ARQUIVO INVALIDO',;
				 'Caminho ou nome do arquivo é inválido!',;
				 'Selecione outro arquivo ou verifique se o caminho informado para o arquivo é válido.' )
		endif
	endif
return cLastRun

/*/{Protheus.doc} procPrdFor
Função de processamento do vínculo de produto e fornecedor
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/13/2025
@param cFile, character, patch completo do arquivo selecionado pelo usuário
@return logical, lSuccess
/*/
static function procPrdFor( cFile )

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
	local nFail    := 0 as numeric
	local nLine    := 0 as numeric
	local cChave   := "" as character
	
	Private aFileHdr := {} as array

	// Verifica se tem permissão de leitura para abrir o arquivo
	if oFile:Open()
		
		nSize := oFile:GetFileSize()

		// Seta o índice de pesquisa
		DBSelectArea( "SA5" )
		SA5->( DBSetOrder( 1 ) )		// PRODUTO + DATA

		// Enquanto encontrar linhas no arquivo, processa as informações...
		while oFile:hasLine() .and. lSuccess
			// Obtem as linhas do arquivo
			cLine := AllTrim(oFile:GetLine())
			nLine++
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
				if checkStruct( "SA5", aFileHdr ) 
					
					DBSelectArea( 'SA5' )
					SA5->( DBSetOrder( 1 ) )		// A5_FORNECE + A5_LOJA + A5_PRODUTO
					if SB1->( DBSeek( FWxFilial( 'SB1' ) + aAux[gt( "A5_PRODUTO" )] ) )

						DBSelectArea( 'SA2' )
						SA2->( DBSetOrder( 1 ) )		// A2_COD + A2_LOJA
						if SA2->( DBSeek( FWxFilial( 'SA2' ) + PADR( AllTrim( aAux[gt( 'A5_FORNECE' )]),TAMSX3('A2_COD')[1], ' ' ) +; 
						 PADR( AllTrim( aAux[gt( 'A5_LOJA' )]),TAMSX3('A2_LOJA')[1], ' ' ) ) )
							// Tenta localizar registro do produto na data informada para garantir que o registro não vai se repetir
							lExist := SA5->( DBSeek( FWxFilial( "SA5" ) + PADR(AllTrim( aAux[gt( 'A5_FORNECE' )] ), TAMSX3('A5_FORNECE')[1], ' ' ) + aAux[gt( 'A5_LOJA' )] + aAux[gt( 'A5_PRODUTO' )] ) )
							if ! lExist
								// Se o código da chave estiver informada no arquivo, utiliza a do arquivo, do contrário, gera uma nova com base na sequencia das chaves existentes na tabela
								if gt( 'A5_CHAVE' ) == 0
									cChave := newKey()
								else
									cChave := aAux[gt( 'A5_CHAVE' )]
								endif
							endif
							// Se o registro já existe para of produto, atualiza os dados
							RecLock( "SA5", !lExist )
								
								SA5->( FieldPut( FieldPos( 'A5_FILIAL' ), FWxFilial( "SA5" ) ) )
								
								if !lExist
									SA5->( FieldPut( FieldPos( 'A5_CHAVE' ), cChave ) )
								endif

								for nField := 1 to len( aFileHdr )
									if SA5->( FieldPos( aFileHdr[nField][1] ) ) > 0
										SA5->( FieldPut( FieldPos( aFileHdr[nField][1] ), typeAdapt( aFileHdr[nField][1], aAux[gt( aFileHdr[nField][1] )] ) ) )
									endif
								next nField
								
							SA5->( MsUnlock() )
						else
							nFail++
							ConOut( 'O fornecedor '+ aAux[gt( 'A5_FORNECE' )] +' da linha '+ StrZero( nLine, 5 ) +' nao foi localizado' )	
						endif
					else
						nFail++
						ConOut( 'O produto '+ aAux[gt( 'A5_PRODUTO' )] +' da linha '+ StrZero( nLine, 5 ) +' nao foi localizado' )
					endif
				else
					lSuccess := .F.
				endif
			endif
			
		end
		oFile:Close()
		
		if nFail > 0
			Hlp( 'INCONSISTENCIAS',;
				cValToChar(nFail) +' registros da planilha apresentaram problemas no momento da checagem de seus respectivos cadastros (produto e/ou fornecedor) e, sendo assim, não chegaram a ser importados',;
				'Verifique o arquivo console.log do servidor para identificar os códigos que foram ignorados na importação' )
		endif

	endif
return lSuccess

/*/{Protheus.doc} newKey
Obtem nova chave do campo A5_CHAVE na função de importação do vínculo de produto versus fornecedor
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/13/2025
@return character, cNewKey
/*/
static function newKey()`

	local cNewKey := StrZero(1,TAMSX3( 'A5_CHAVE' )[1] )
	local cQuery := "" as character
	local cAlias := "" as character

	// MOnta query para leitura do ultimo número utilizado
	cQuery := "SELECT COALESCE(MAX(A5_CHAVE),'"+ cNewKey +"') A5_CHAVE FROM "+ RetSqlName( 'SA5' ) +" WHERE A5_FILIAL = '"+ FWxFilial( 'SA5' ) +"' AND D_E_L_E_T_ = ' ' "
	cAlias := MpSysOpenQuery( cQuery )
	if !Empty( ( cAlias )->A5_CHAVE )
		cNewKey := Soma1( ( cAlias )->A5_CHAVE )
	endif
	( cAlias )->( DBCloseArea() )
	
return cNewKey

/*/{Protheus.doc} checkStruct
Função para checar se os campos obrigatórios estão vindo no arquivo .csv
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/13/2025
@param cAlias, character, Alias que está sendo validado
@param aHeader, array, Cabeçalho contendo o nome físico dos campos que estão sendo informados no arquivo para importação
@return logical, lSuccess
/*/
static function checkStruct( cAlias, aHeader )
	local lSuccess := .T. as logical
	local aFldSA5  := { "A5_FORNECE", "A5_LOJA", "A5_NOMEFOR", "A5_PRODUTO", "A5_NOMPROD" }
	local nField   := 0 as numeric
	if cAlias == 'SA5'		// Produto versus fornecedor
		for nField := 1 to len( aFldSA5 )
			lSuccess := lSuccess .and. aScan( aHeader, {|x| AllTrim(x[1]) == AllTrim(aFldSA5[nField]) } ) > 0
		next nField
		if ! lSuccess
			Hlp( 'ESTRUTURA INVALIDA',;
				'Os campos obrigatórios para importação do vínculo entre produto e fornecedor não foram encontrados no arquivo .csv',;
				'Verifique se os campos obrigatórios estão presentes no arquivo e tente novamente' )
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
	local lMVPNC12 := GetMv( 'MV_X_PNC12', .T. /* lCheck */ )
	local cDtTime  := "" as character
	local nFail    := 0 as numeric
	local nLine    := 0 as numeric
	
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
			nLine++
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
				if gt( cZB3 +'_PROD' ) > 0 .and. gt( cZB3 +'_DATA' ) > 0 
					
					DBSelectArea( 'SB1' )
					SB1->( DBSetOrder( 1 ) )
					if SB1->( DBSeek( FWxFilial( 'SB1' ) + aAux[gt( cZB3 +'_PROD' )] ) )
						// Tenta localizar registro do produto na data informada para garantir que o registro não vai se repetir
						lExist := ( cZB3 )->( DBSeek( FWxFilial( cZB3 ) + aAux[gt( cZB3 +'_PROD' )] + DtoS(CtoD(aAux[gt( cZB3 +'_DATA' )])) ) )

						// Se o registro já existe para o produto, atualiza os dados
						RecLock( cZB3, !lExist )
							( cZB3 )->( FieldPut( FieldPos( cZB3 +'_FILIAL' ), FWxFilial( cZB3 ) ) )
							for nField := 1 to len( aFileHdr )
								if ( cZB3 )->( FieldPos( aFileHdr[nField][1] ) ) > 0
									( cZB3 )->( FieldPut( FieldPos( aFileHdr[nField][1] ), typeAdapt( aFileHdr[nField][1], aAux[gt( aFileHdr[nField][1] )] ) ) )
								endif
							next nField
						( cZB3 )->( MsUnlock() )
					else
						nFail++
						ConOut( 'O produto '+ aAux[gt( cZB3 +'_PROD' )] +' da linha '+ StrZero( nLine, 5 ) +' nao foi localizado' )
					endif
					
				elseif ! gt( cZB3 +'_PROD' ) > 0 .or. ! gt( cZB3 +'_DATA' ) > 0 
					Hlp( 'CAMPOS CHAVE',;
						'Os campos de codigo do produto e/ou data não foram informados no arquivo .csv',;
						'Esses campos são obrigatórios para o registro dos índices de produtos' )
					lSuccess := .F.
				endif
			endif
			
		end
		oFile:Close()
		
		// Grava data de importação do índice
		if lMVPNC12
			cDtTime := FWTimeStamp(2)
			PutMV( 'MV_X_PNC12', cDtTime )
		endif

		if nFail > 0
			Hlp( 'PRODUTOS INEXISTENTES',;
				cValToChar(nFail) +' produtos da planilha não foram localizados no cadastro e, sendo assim, não chegaram a ser importados',;
				'Verifique o arquivo console.log do servidor para identificar os códigos que foram ignorados na importação' )
		endif

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
	
	local cVar      := upper(ReadVar())	
	local aLast     := {} as array	
	local cCDIPI    := "" as character
	Private aHeader := headerSD1()
	Private aCols   := getCols( SD1TMP->D1_FILIAL, SD1TMP->D1_DOC, SD1TMP->D1_SERIE, SD1TMP->D1_FORNECE, SD1TMP->D1_LOJA, SD1TMP->D1_TIPO )
	Private n       := aScan( aCols, {|x| x[d1Pos('D1_ITEM')] == SD1TMP->D1_ITEM .and.;
										  x[d1Pos('D1_COD')] == SD1TMP->D1_COD } )
	
	default lReset  := .F.

	DBSelectArea( 'SA2' )
	SA2->( DBSetOrder( 1 ) )
	SA2->( DBSeek( FWxFilial('SA2' ) + SD1TMP->D1_FORNECE + SD1TMP->D1_LOJA ) )

	// Se já existir cálculo em memória, encerra e começa outro
	if MaFisFound("NF")
		MaFisEnd()
	endif

	// Inicializa cálculo de impostos da NF
	MAFisIni( SD1TMP->D1_FORNECE,;
			  SD1TMP->D1_LOJA,;
			  'F',;
			  SD1TMP->D1_TIPO,;
			  Nil,;
			  MaFisRelImp("MT100", {"SF1", "SD1"}),;
			  Nil,;
			  .T.,;
			  "SB1",;
			  "MATA103" )

	// Carrega dados da NF para o aCols
	MaFisToCols(aHeader,aCols,,"MT100")

	// Entrada
	if ! lReset
		nGetUOC := ( SD1TMP->D1_TOTAL - SD1TMP->D1_VALDESC ) / SD1TMP->D1_QUANT
		nGetUNF := ( SD1TMP->D1_TOTAL - SD1TMP->D1_VALDESC ) / SD1TMP->D1_QUANT
		cGetTES := SD1TMP->D1_TES
		nGetICM := SD1TMP->D1_PICM
		// nGetIPI := 
	else
		MaFisAlt( "IT_VUNIT", nGetUOC, n )
		MaFisAlt( "IT_TES", cGetTES, n )
		MaFisAlt( "IT_ALIQICM", nGetICM, n )
		
	endif

	// nGetUOC := MaFisRet( n, 'IT_' )

	// DBSelectArea( 'SF4' )
	// SF4->( DBSetOrder( 1 ) )
	// if SF4->( DBSeek( FWxFilial( 'SF4' ) + cGetTES ) )
	// 	cGetDTE := SF4->F4_TEXTO
	// 	cCDIPI  := SF4->F4_CREDIPI
	// else
	// 	cGetDTE := ""
	// 	cCDIPI  := "N"
	// endif
	nGetICM := iif( lReset, SD1TMP->D1_PICM, nGetICM )
	nValICM := iif( lReset, ( SD1TMP->D1_VALICM / SD1TMP->D1_QUANT ) - (( SD1TMP->D1_VALFRE / SD1TMP->D1_QUANT ) * ( nGetICM/100 ) ), nGetUOC * (nGetICM/100) ) * -1
	nGetIPI := iif( lReset, iif( cCDIPI == 'N', SD1TMP->D1_IPI, 0 ), nGetIPI )
	nValIPI := iif( lReset, SD1TMP->D1_VALIPI / SD1TMP->D1_QUANT, nGetUOC * (nGetIPI/100) )
	nGetFre := iif( lReset, ( ( SD1TMP->D1_VALFRE + SD1TMP->VALFRT ) / ( SD1TMP->D1_TOTAL - SD1TMP->D1_VALDESC )) * 100, nGetFre )
	nValFre := iif( lReset, ( SD1TMP->D1_VALFRE + SD1TMP->VALFRT ) / SD1TMP->D1_QUANT, nGetFre*(nGetUOC/100) )
	nGetICF := iif( lReset, 0, nGetICF )
	nValICF := iif( lReset, 0, nValFre * (nGetICF/100) ) * -1
	nGetOut := iif( lReset, (SD1TMP->D1_DESPESA/(SD1TMP->D1_TOTAL-SD1TMP->D1_VALDESC)) * 100, nGetOut )
	nValOut := iif( lReset, SD1TMP->D1_DESPESA / SD1TMP->D1_QUANT, nGetUOC * (nGetOut/100) )
	nGetFin := iif( lReset, (SD1TMP->VALFIN / ( SD1TMP->D1_TOTAL - SD1TMP->D1_VALDESC )) * 100, nGetFin )
	nValFin := iif( lReset, SD1TMP->VALFIN / SD1TMP->D1_QUANT, nGetUOC * (nGetFin/100) )
	nGetPC  := iif( lReset, SD1TMP->D1_ALQIMP5 + SD1TMP->D1_ALQIMP6, nGetPC )
	nValPC  := iif( lReset, ( SD1TMP->D1_VALIMP5 + SD1TMP->D1_VALIMP6 ) / SD1TMP->D1_QUANT, nGetUOC * (nGetPC/100) ) * -1
	nGetST  := iif( lReset, iif( SD1TMP->D1_ICMSRET > 0, SD1TMP->D1_ALIQSOL, 0 ), nGetST )
	nValST  := iif( lReset, SD1TMP->D1_ICMSRET / SD1TMP->D1_QUANT, nGetUOC * (nGetST/100) )
	nGetMVA := iif( lReset, SD1TMP->D1_MARGEM, nGetMVA )
	nGetCuL := nGetUOC + nValICM + nValPC + nValIPI + nValFre + nValICF + nValOut + nValFin + nValST
	nGetCuM := RetField( 'SB2', 1, SD1TMP->D1_FILIAL + SD1TMP->D1_COD + SD1TMP->D1_LOCAL, 'B2_CM1' )

	// Saída
	nGetTCV := nGetLuc + nGetPCV + nGetICV + nGetOpe + nGetCSL + nGetIRP + nGetIna
	nGetPSL := nGetCuL / ( 1-(nGetTCV-nGetLuc)/100)
	nGetSug := Round(iif( cVar == 'NGETSUG', nGetSug, ( nGetCuL / ( 1-(nGetTCV/100) ) ) / ( 1-(nGetFiV/100) ) ),TAMSX3('DA1_PRCVEN')[2])
	nGetScI := nGetSug + ( nGetSug * ( nGetIPS/100 ) )
	nGetMg1 := ( (nGetSug-nGetCuL) / nGetSug ) * 100
	nGetPrc := RetField( 'DA1', 1, FWxFilial( 'DA1' ) + cGetTab + SD1TMP->D1_COD, "DA1_PRCVEN" )
	nGetMg2 := iif( nGetPrc > 0, ( (nGetPrc-nGetCuL) / nGetPrc ) * 100, 0 )
	nGetPCI := nGetPrc + ( nGetPrc * (nGetIPS/100) )

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
@param lLblTop, logical, indica se a label deve ser exibida no topo do get ou no lado esquerdo
@return object, oGet
/*/
static function doGet( nTop, nLeft, bAction, oDlg, nSize, nHeight, cPicture, cVar, cLabel, lEnable, lLblTop, nColor )

	local oFont   := TFont():New('Courier New',,9,.T.)
	local cLbPad  := "" as character 
	local oGet    as object

	default lEnable := .T.
	default lLblTop := .F.
	default nColor  := 0

	cLbPad := iif( ValType( cLabel ) == 'C' .and. !Empty( cLabel ) .and. !lLblTop, PADR( AllTrim( cLabel ), 12, '.' ), cLabel )

	oGet := TGet():New( nTop, nLeft, bAction, oDlg, nSize, nHeight,cPicture,,nColor,Nil,,.F.,,.T. /* lPixel */,,.F.,/* bWhen */,;
						.F.,.F.,/* bChange */,/* lReadOnly */,.F.,,cVar,,,,.T.,.T.,,cLbPad, iif( lLblTop, 1, 2 ), oFont, CLR_BLUE )
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
							AllTrim(SM0TMP->M0_CODFIL),;
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
	local nPropor  := 0.6 
	local lPEPNC05 := ExistBlock( 'PEPNC05' )
	local aPEPNC05 := {} as array

	for nX := 1 to len( aFields )
		DBSelectArea( 'SB1' )
		if SB1->( FieldPos( aFields[nX] ) ) > 0 .or. Alltrim(aFields[nX]) $ "A5_FORNECE|A5_LOJA"
			cType := StrTran(GetSX3Cache( aFields[nX], 'X3_TIPO' ),'M','C')
			if !Empty(GetSX3Cache( aFields[nX], "X3_CBOX" ))
				aAux := StrTokArr( GetSX3Cache( aFields[nX], "X3_CBOX" ),';')
			else
				aAux := {}
			endif
			aAdd(aColumns, {;
							AllTrim(GetSX3Cache( aFields[nX], 'X3_TITULO' )),;                     	// [n][01] Título da coluna
							&("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX+2) +"] }"),; 				// [n][02] Code-Block de carga dos dados
							StrTran(GetSX3Cache( aFields[nX], 'X3_TIPO' ),'M','C'),;                // [n][03] Tipo de dados
							AllTrim(GetSX3Cache( aFields[nX], 'X3_PICTURE' )),;                     // [n][04] Máscara
							iif( cType == "C", 1, iif( cType == "N", 2, 0 )),;                      // [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
							GetSX3Cache( aFields[nX], 'X3_TAMANHO' )*nPropor,;                             	// [n][06] Tamanho
							GetSX3Cache( aFields[nX], 'X3_DECIMAL' ),;                              // [n][07] Decimal
							aScan( aAlter, {|x| AllTrim(x) == aFields[nX] } ) > 0,;                 // [n][08] Indica se permite a edição
							{|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
							.F.,;                            										// [n][10] Indica se exibe imagem
							Nil,;                            										// [n][11] Code-Block de execução do duplo clique
							"aColPro[oBrwPro:At()]["+cValToChar(nX+2)+"]",;                    		// [n][12] Variável a ser utilizada na edição (ReadVar)
							{|oBrw| sortCol(oBrw) },;              									// [n][13] Code-Block de execução do clique no header
							.F.,;                            										// [n][14] Indica se a coluna está deletada
							.F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
							aAux,;                             										// [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
							aFields[nX] })                          								// [n][17] Id da coluna
		elseif aFields[nX] == 'QTDBLOQ' 
			aAdd(aColumns, {;
							'Qtd.Bloq.',;                     										// [n][01] Título da coluna
							&("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX+2) +"] }"),; 				// [n][02] Code-Block de carga dos dados
							"N",;                													// [n][03] Tipo de dados
							"@E 999,999,999",;                     									// [n][04] Máscara
							2,;                      												// [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
							11 * nPropor,;                             										// [n][06] Tamanho
							0,;                              										// [n][07] Decimal
							aScan( aAlter, {|x| AllTrim(x) == aFields[nX] } ) > 0,;                 // [n][08] Indica se permite a edição
							{|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
							.F.,;                            										// [n][10] Indica se exibe imagem
							Nil,;                            										// [n][11] Code-Block de execução do duplo clique
							"aColPro[oBrwPro:At()]["+cValToChar(nX+2)+"]",;                    		// [n][12] Variável a ser utilizada na edição (ReadVar)
							{|oBrw| sortCol(oBrw) },;            									// [n][13] Code-Block de execução do clique no header
							.F.,;                            										// [n][14] Indica se a coluna está deletada
							.F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
							{},;                             										// [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
							aFields[nX] })                          								// [n][17] Id da coluna
		elseif aFields[nX] == 'NECCOMP'
			aAdd(aColumns, {;
							'Comprar',;                     										// [n][01] Título da coluna
							&("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX+2) +"] }"),; 				// [n][02] Code-Block de carga dos dados
							"N",;                													// [n][03] Tipo de dados
							"@E 999,999,999",;                     									// [n][04] Máscara
							2,;                      												// [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
							11 * nPropor,;                             										// [n][06] Tamanho
							0,;                              										// [n][07] Decimal
							aScan( aAlter, {|x| AllTrim(x) == aFields[nX] } ) > 0,;                 // [n][08] Indica se permite a edição
							{|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
							.F.,;                            										// [n][10] Indica se exibe imagem
							Nil,;                            										// [n][11] Code-Block de execução do duplo clique
							"aColPro[oBrwPro:At()]["+cValToChar(nX+2)+"]",;                    		// [n][12] Variável a ser utilizada na edição (ReadVar)
							{|oBrw| sortCol(oBrw) },;           									// [n][13] Code-Block de execução do clique no header
							.F.,;                            										// [n][14] Indica se a coluna está deletada
							.F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
							{},;                             										// [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
							aFields[nX] })                          								// [n][17] Id da coluna
		elseif aFields[nX] == 'QTDSOL'
			aAdd(aColumns, {;
							'Qtd.Solic.',;                     										// [n][01] Título da coluna
							&("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX+2) +"] }"),; 				// [n][02] Code-Block de carga dos dados
							"N",;                													// [n][03] Tipo de dados
							"@E 999,999,999",;                     									// [n][04] Máscara
							2,;                      												// [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
							11 * nPropor,;                             										// [n][06] Tamanho
							0,;                              										// [n][07] Decimal
							aScan( aAlter, {|x| AllTrim(x) == aFields[nX] } ) > 0,;                 // [n][08] Indica se permite a edição
							{|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
							.F.,;                            										// [n][10] Indica se exibe imagem
							Nil,;                            										// [n][11] Code-Block de execução do duplo clique
							"aColPro[oBrwPro:At()]["+cValToChar(nX+2)+"]",;                    		// [n][12] Variável a ser utilizada na edição (ReadVar)
							{|oBrw| sortCol(oBrw) },;           									// [n][13] Code-Block de execução do clique no header
							.F.,;                            										// [n][14] Indica se a coluna está deletada
							.F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
							{},;                             										// [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
							aFields[nX] })                          								// [n][17] Id da coluna
		elseif aFields[nX] == 'PRCNEGOC'
			aAdd(aColumns, {;
							'Prç.Neg.',;                     										// [n][01] Título da coluna
							&("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX+2) +"] }"),; 				// [n][02] Code-Block de carga dos dados
							"N",;                													// [n][03] Tipo de dados
							"@E 9,999,999.99",;                     								// [n][04] Máscara
							2,;                      												// [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
							11 * nPropor,;                             										// [n][06] Tamanho
							2,;                              										// [n][07] Decimal
							aScan( aAlter, {|x| AllTrim(x) == aFields[nX] } ) > 0,;                 // [n][08] Indica se permite a edição
							{|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
							.F.,;                            										// [n][10] Indica se exibe imagem
							Nil,;                            										// [n][11] Code-Block de execução do duplo clique
							"aColPro[oBrwPro:At()]["+cValToChar(nX+2)+"]",;                    		// [n][12] Variável a ser utilizada na edição (ReadVar)
							{|oBrw| sortCol(oBrw) },;           									// [n][13] Code-Block de execução do clique no header
							.F.,;                            										// [n][14] Indica se a coluna está deletada
							.F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
							{},;                             										// [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
							aFields[nX] })                          								// [n][17] Id da coluna
		elseif aFields[nX] == "ULTPRECO"
			aAdd(aColumns, {;
							'Ult.Prç.',;                     										// [n][01] Título da coluna
							&("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX+2) +"] }"),; 				// [n][02] Code-Block de carga dos dados
							"N",;                													// [n][03] Tipo de dados
							"@E 9,999,999.99",;                     								// [n][04] Máscara
							2,;                      												// [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
							11 * nPropor,;                             										// [n][06] Tamanho
							2,;                              										// [n][07] Decimal
							aScan( aAlter, {|x| AllTrim(x) == aFields[nX] } ) > 0,;                 // [n][08] Indica se permite a edição
							{|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
							.F.,;                            										// [n][10] Indica se exibe imagem
							Nil,;                            										// [n][11] Code-Block de execução do duplo clique
							"aColPro[oBrwPro:At()]["+cValToChar(nX+2)+"]",;                    		// [n][12] Variável a ser utilizada na edição (ReadVar)
							{|oBrw| sortCol(oBrw) },;          										// [n][13] Code-Block de execução do clique no header
							.F.,;                            										// [n][14] Indica se a coluna está deletada
							.F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
							{},;                             										// [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
							aFields[nX] })                          								// [n][17] Id da coluna
		elseif aFields[nX] == 'CONSMED'
			aAdd(aColumns, {;
							'Cons.Med.',;                     										// [n][01] Título da coluna
							&("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX+2) +"] }"),; 				// [n][02] Code-Block de carga dos dados
							"N",;                													// [n][03] Tipo de dados
							"@E 9,999,999.9999",;                     								// [n][04] Máscara
							2,;                      												// [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
							14 * nPropor,;                             										// [n][06] Tamanho
							4,;                              										// [n][07] Decimal
							aScan( aAlter, {|x| AllTrim(x) == aFields[nX] } ) > 0,;                 // [n][08] Indica se permite a edição
							{|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
							.F.,;                            										// [n][10] Indica se exibe imagem
							Nil,;                            										// [n][11] Code-Block de execução do duplo clique
							"aColPro[oBrwPro:At()]["+cValToChar(nX+2)+"]",;                    		// [n][12] Variável a ser utilizada na edição (ReadVar)
							{|oBrw| sortCol(oBrw) },;            									// [n][13] Code-Block de execução do clique no header
							.F.,;                            										// [n][14] Indica se a coluna está deletada
							.F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
							{},;                             										// [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
							aFields[nX] })                          								// [n][17] Id da coluna

		elseif aFields[nX] == 'DURACAO'
			aAdd(aColumns, {;
							'Duração',;                     										// [n][01] Título da coluna
							&("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX+2) +"] }"),; 				// [n][02] Code-Block de carga dos dados
							"N",;                													// [n][03] Tipo de dados
							"@E 999",;                     											// [n][04] Máscara
							2,;                      												// [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
							3 * nPropor,;                             										// [n][06] Tamanho
							0,;                              										// [n][07] Decimal
							aScan( aAlter, {|x| AllTrim(x) == aFields[nX] } ) > 0,;                 // [n][08] Indica se permite a edição
							{|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
							.F.,;                            										// [n][10] Indica se exibe imagem
							Nil,;                            										// [n][11] Code-Block de execução do duplo clique
							"aColPro[oBrwPro:At()]["+cValToChar(nX+2)+"]",;                    		// [n][12] Variável a ser utilizada na edição (ReadVar)
							{|oBrw| sortCol(oBrw) },;          										// [n][13] Code-Block de execução do clique no header
							.F.,;                            										// [n][14] Indica se a coluna está deletada
							.F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
							{},;                             										// [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
							aFields[nX] })                          								// [n][17] Id da coluna
		elseif aFields[nX] == 'DURAPRV'
			aAdd(aColumns, {;
							'Dur.s/L.T.',;                     										// [n][01] Título da coluna
							&("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX+2) +"] }"),; 				// [n][02] Code-Block de carga dos dados
							"N",;                													// [n][03] Tipo de dados
							"@E 999",;                     											// [n][04] Máscara
							2,;                      												// [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
							3 * nPropor,;                             										// [n][06] Tamanho
							0,;                              										// [n][07] Decimal
							aScan( aAlter, {|x| AllTrim(x) == aFields[nX] } ) > 0,;                 // [n][08] Indica se permite a edição
							{|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
							.F.,;                            										// [n][10] Indica se exibe imagem
							Nil,;                            										// [n][11] Code-Block de execução do duplo clique
							"aColPro[oBrwPro:At()]["+cValToChar(nX+2)+"]",;                    		// [n][12] Variável a ser utilizada na edição (ReadVar)
							{|oBrw| sortCol(oBrw) },;          										// [n][13] Code-Block de execução do clique no header
							.F.,;                            										// [n][14] Indica se a coluna está deletada
							.F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
							{},;                             										// [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
							aFields[nX] })                          								// [n][17] Id da coluna
		elseif aFields[nX] == 'ESTOQUE'
			aAdd(aColumns, {;
							'Sld.Atual',;                     										// [n][01] Título da coluna
							&("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX+2) +"] }"),; 				// [n][02] Code-Block de carga dos dados
							"N",;                													// [n][03] Tipo de dados
							AllTrim(GetSX3Cache("B2_QATU", "X3_PICTURE")),;                     	// [n][04] Máscara
							2,;                      												// [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
							GetSX3Cache("B2_QATU", "X3_TAMANHO") * nPropor,;                             		// [n][06] Tamanho
							GetSX3Cache("B2_QATU", "X3_DECIMAL"),;                         			// [n][07] Decimal
							aScan( aAlter, {|x| AllTrim(x) == aFields[nX] } ) > 0,;                 // [n][08] Indica se permite a edição
							{|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
							.F.,;                            										// [n][10] Indica se exibe imagem
							Nil,;                            										// [n][11] Code-Block de execução do duplo clique
							"aColPro[oBrwPro:At()]["+cValToChar(nX+2)+"]",;                    		// [n][12] Variável a ser utilizada na edição (ReadVar)
							{|oBrw| sortCol(oBrw) },;         										// [n][13] Code-Block de execução do clique no header
							.F.,;                            										// [n][14] Indica se a coluna está deletada
							.F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
							{},;                             										// [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
							aFields[nX] })                          								// [n][17] Id da coluna
		elseif aFields[nX] == 'EMPENHO'
			aAdd(aColumns, {;
							'Empenho',;                     										// [n][01] Título da coluna
							&("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX+2) +"] }"),; 				// [n][02] Code-Block de carga dos dados
							"N",;                													// [n][03] Tipo de dados
							AllTrim(GetSX3Cache("B2_RESERVA", "X3_PICTURE")),;                     	// [n][04] Máscara
							2,;                      												// [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
							GetSX3Cache("B2_RESERVA", "X3_TAMANHO") * nPropor,;                             	// [n][06] Tamanho
							GetSX3Cache("B2_RESERVA", "X3_DECIMAL"),;                         		// [n][07] Decimal
							aScan( aAlter, {|x| AllTrim(x) == aFields[nX] } ) > 0,;                 // [n][08] Indica se permite a edição
							{|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
							.F.,;                            										// [n][10] Indica se exibe imagem
							Nil,;                            										// [n][11] Code-Block de execução do duplo clique
							"aColPro[oBrwPro:At()]["+cValToChar(nX+2)+"]",;                    		// [n][12] Variável a ser utilizada na edição (ReadVar)
							{|oBrw| sortCol(oBrw) },;            									// [n][13] Code-Block de execução do clique no header
							.F.,;                            										// [n][14] Indica se a coluna está deletada
							.F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
							{},;                             										// [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
							aFields[nX] })                          								// [n][17] Id da coluna
		elseif aFields[nX] == 'QTDCOMP'
			aAdd(aColumns, {;
							'Qt.Compr',;                     										// [n][01] Título da coluna
							&("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX+2) +"] }"),; 				// [n][02] Code-Block de carga dos dados
							"N",;                													// [n][03] Tipo de dados
							AllTrim(GetSX3Cache("C7_QUANT", "X3_PICTURE")),;                     	// [n][04] Máscara
							2,;                      												// [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
							GetSX3Cache("C7_QUANT", "X3_TAMANHO") * nPropor,;                             	// [n][06] Tamanho
							GetSX3Cache("C7_QUANT", "X3_DECIMAL"),;                         		// [n][07] Decimal
							aScan( aAlter, {|x| AllTrim(x) == aFields[nX] } ) > 0,;                 // [n][08] Indica se permite a edição
							{|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
							.F.,;                            										// [n][10] Indica se exibe imagem
							Nil,;                            										// [n][11] Code-Block de execução do duplo clique
							"aColPro[oBrwPro:At()]["+cValToChar(nX+2)+"]",;                    		// [n][12] Variável a ser utilizada na edição (ReadVar)
							{|oBrw| sortCol(oBrw) },;            									// [n][13] Code-Block de execução do clique no header
							.F.,;                            										// [n][14] Indica se a coluna está deletada
							.F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
							{},;                             										// [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
							aFields[nX] })                          								// [n][17] Id da coluna
		Elseif aFields[nX] == 'LEADTIME'
			aAdd(aColumns, {;
							'Ld.Time',;                     										// [n][01] Título da coluna
							&("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX+2) +"] }"),; 				// [n][02] Code-Block de carga dos dados
							"N",;                													// [n][03] Tipo de dados
							AllTrim(GetSX3Cache("B1_PE", "X3_PICTURE")),;                     		// [n][04] Máscara
							2,;                      												// [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
							GetSX3Cache("B1_PE", "X3_TAMANHO") * nPropor,;                             		// [n][06] Tamanho
							GetSX3Cache("B1_PE", "X3_DECIMAL"),;                         			// [n][07] Decimal
							aScan( aAlter, {|x| AllTrim(x) == aFields[nX] } ) > 0,;                 // [n][08] Indica se permite a edição
							{|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
							.F.,;                            										// [n][10] Indica se exibe imagem
							Nil,;                            										// [n][11] Code-Block de execução do duplo clique
							"aColPro[oBrwPro:At()]["+cValToChar(nX+2)+"]",;                    		// [n][12] Variável a ser utilizada na edição (ReadVar)
							{|oBrw| sortCol(oBrw) },;           									// [n][13] Code-Block de execução do clique no header
							.F.,;                            										// [n][14] Indica se a coluna está deletada
							.F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
							{},;                             										// [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
							aFields[nX] })                          								// [n][17] Id da coluna
		elseif aFields[nX] == 'TPLDTIME'
			aAdd(aColumns, {;
							'Tp.Ld.T',;                     										// [n][01] Título da coluna
							&("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX+2) +"] }"),; 				// [n][02] Code-Block de carga dos dados
							"C",;                													// [n][03] Tipo de dados
							"@x",;                     												// [n][04] Máscara
							0,;                      												// [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
							1,;                             										// [n][06] Tamanho
							0,;                         											// [n][07] Decimal
							aScan( aAlter, {|x| AllTrim(x) == aFields[nX] } ) > 0,;                 // [n][08] Indica se permite a edição
							{|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
							.F.,;                            										// [n][10] Indica se exibe imagem
							Nil,;                            										// [n][11] Code-Block de execução do duplo clique
							"aColPro[oBrwPro:At()]["+cValToChar(nX+2)+"]",;                    		// [n][12] Variável a ser utilizada na edição (ReadVar)
							{|oBrw| sortCol(oBrw) },;          										// [n][13] Code-Block de execução do clique no header
							.F.,;                            										// [n][14] Indica se a coluna está deletada
							.F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
							{"C=Calculado","F=Fornecedor","P=Produto"},;                            // [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
							aFields[nX] })                          								// [n][17] Id da coluna
		elseif aFields[nX] == 'PREVENT'
			aAdd(aColumns, {;
							'Prev.Entr.',;                     										// [n][01] Título da coluna
							&("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX+2) +"] }"),; 				// [n][02] Code-Block de carga dos dados
							"D",;                													// [n][03] Tipo de dados
							Nil,;                     												// [n][04] Máscara
							0,;                      												// [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
							8 * nPropor,;                             								// [n][06] Tamanho
							0,;                         											// [n][07] Decimal
							aScan( aAlter, {|x| AllTrim(x) == aFields[nX] } ) > 0,;                 // [n][08] Indica se permite a edição
							{|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
							.F.,;                            										// [n][10] Indica se exibe imagem
							Nil,;                            										// [n][11] Code-Block de execução do duplo clique
							"aColPro[oBrwPro:At()]["+cValToChar(nX+2)+"]",;                    		// [n][12] Variável a ser utilizada na edição (ReadVar)
							{|oBrw| sortCol(oBrw) },;          										// [n][13] Code-Block de execução do clique no header
							.F.,;                            										// [n][14] Indica se a coluna está deletada
							.F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
							{},; 										                            // [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
							aFields[nX] })                          								// [n][17] Id da coluna
		endif
	next nX

	if lPEPNC05
		// Permite manipular o vetor de colunas do browse de produtos
		aPEPNC05 := ExecBlock( 'PEPNC05', .F., .F., { aClone(aColumns), 1 /* nLocal 1=aHeader ou 2=aCols */ } )
		if ValType( aPEPNC05 ) == 'A' .and. len( aPEPNC05 ) > 0
			aColumns := aClone( aPEPNC05 )
		endif
	endif

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
			if aScan( aForLoj, {|x| x[1] + x[2] == aCarCom[nX][carPos('C7_FORNECE')] + aCarCom[nX][carPos('C7_LOJA')] } ) == 0
				aAdd( aForLoj, { aCarCom[nX][carPos('C7_FORNECE')], aCarCom[nX][carPos('C7_LOJA')] } )
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
	local nCol := oBrw:ColPos() 
	if nLastCol == nCol
		lCrescente := ! lCrescente
	else
		lCrescente := .T.
	endif
	nLastCol := nCol
	aSort( aColPro,,, {|x,y| &('x[nCol] '+ iif( lCrescente, '>','<' ) +' y[nCol]') } )
	oBrw:UpdateBrowse()
return Nil

/*/{Protheus.doc} Pz
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
user function PCOMPRE(oBrw, oCol, cPre )
	
	local lCanEdit := .T. as logical
	local oQtdFil         as object
	local nAux     := 0 as numeric
	local bOk      := {|| nAux := 0, aEval( _aProdFil, {|x| iif( x[3] == cProduto, nAux+= x[6], nil ) } ),;
						  aColPro[aScan(aColPro, {|x| x[nPosPrd] == cProduto })][nPosNec] := nAux,;
						  updCarCom( cProduto ),;
						  oBrwPro:UpdateBrowse(),;
						  oQtdFil:End() }

	local bCancel  :={|| oQtdFil:End() }
	local aButtons := {}  as array
	local bValid   :={|| .T. }
	local bInit    :={|| EnchoiceBar( oQtdFil, bOk, bCancel,,aButtons )}
	local aColumns := {} as array
	local cProduto := aColPro[oBrwPro:At()][nPosPrd]
	local cFornece := aColPro[oBrwPro:At()][nPosFor]
	local cLoja    := aColPro[oBrwPro:At()][nPosLoj]
	local cFil     := "" as character
	local nX       := 0 as numeric
	local oSize    as object
	local oGroup   as object
	local oGetNec  as object
	local nGetNec  := 0 as numeric
	local oGetQtd  as object
	local nGetQtd  := 0 as numeric
	local oGetEmp  as object
	local nGetEmp  := 0 as numeric
	local oGetMed  as object
	local nGetMed  := 0 as numeric
	local nGetCom  := 0 as numeric
	local oGetCom  as object
	local bVldCell := {|| _aProdFil[ aScan( _aProdFil, {|x| x[25]+x[3] == aProFil[oProFil:At()][25]+aProFil[oProFil:At()][3] } ) ] := aProFil[oProFil:At()],;
						 nAux := 0,;
						 aEval( _aProdFil, {|x| iif( x[3] == cProduto, nAux+= x[6], nil ) } ),;
						 nGetNec := nAux,;
						 oGetNec:CtrlRefresh(),;
						 .T. }

	Private aProFil  := {} as array
	Private oProFil  as object

	if oBrwPro:GetColumn(oBrwPro:ColPos()):GetID() == 'NECCOMP'
		
		// Quando a compra não for multi-filial, permite a edição diretamente no grid principal
		if len( _aFil ) == 1 .and. _aFil[1] == cFilAnt
			lCanEdit := .T.
		else
			// Cria subvetor editável apenas com o produto selecionado
			if len( _aProdFil ) > 0
				for nX := 1 to len( _aProdFil )
					cFil := _aProdFil[nX][25]		// Filial
					// Executa verificação apenas quando o produto for referente a linha selecionada
					if _aProdFil[nX][3]	== cProduto .and. _aProdFil[nX][23] == cFornece .and. _aProdFil[nX][24] == cLoja
						// Verifica se o produto já não foi adicionado anteriormente.
						if len( aProFil ) == 0 .or. aScan( aProFil, {|x| x[3] == cProduto .and. x[23] == cFornece .and. x[24] == cLoja .and. x[25] == cFil } ) == 0
							aAdd( aProFil, aClone( _aProdFil[nX] ) )
						endif

					endif
				next nX		
			endif

			// Inicializa variáveis dos gets
			aEval( _aProdFil, {|x| iif( x[3] == cProduto, nGetMed+= x[10], nil ) } )
			aEval( _aProdFil, {|x| iif( x[3] == cProduto, nGetQtd+= x[13], nil ) } )
			aEval( _aProdFil, {|x| iif( x[3] == cProduto, nGetEmp+= x[14], nil ) } )
			aEval( _aProdFil, {|x| iif( x[3] == cProduto, nGetNec+= x[06], nil ) } )
			aEval( _aProdFil, {|x| iif( x[3] == cProduto, nGetCom+= x[15], nil ) } )

			aAdd( aColumns, FWBrwColumn():New() )
			aColumns[len(aColumns)]:SetTitle( 'Filial' )
			aColumns[len(aColumns)]:SetData( &( "{|oBrw| aProFil[oBrw:At()][25] }" ) )
			aColumns[len(aColumns)]:SetType( 'C' )
			aColumns[len(aColumns)]:SetAlign( 1 )		// Alinha a Esquerda
			aColumns[len(aColumns)]:SetSize( TAMSX3( 'C7_FILIAL' )[1] )
			aColumns[len(aColumns)]:SetPicture( "@!" )

			aAdd( aColumns, FWBrwColumn():New() )
			aColumns[len(aColumns)]:SetTitle( 'Nome' )
			aColumns[len(aColumns)]:SetData( &( "{|oBrw| filName( cEmpAnt, aProFil[oBrw:At()][25]) }" ) )
			aColumns[len(aColumns)]:SetType( 'C' )
			aColumns[len(aColumns)]:SetAlign( 1 )		// Alinha a Esquerda
			aColumns[len(aColumns)]:SetSize( len( SM0->M0_FILIAL ) )
			aColumns[len(aColumns)]:SetPicture( "@x" )

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
			
			// Cálculo de dimensões e objetos
			oSize := FWDefSize():New( .T. /* lEnchoiceBar */, .T. /* lFixo */, 600, .F. )
			oSize:AddObject( 'GRID', 100, 90, .T., .T. )
			oSize:AddObject( 'TOTAL', 100, 30, .T., .F. )
			oSize:lProp := .T.
			oSize:Process()
			
			oQtdFil := TDialog():New( oSize:aWindSize[1],oSize:aWindSize[2],oSize:aWindSize[3],oSize:aWindSize[4],;
						'Quantidades x Filial - '+ aColPro[oBrwPro:At()][nPosDes],,,,,CLR_BLACK,CLR_WHITE,,,.T.) 
			
			oGroup := TGroup():New( oSize:GetDimension( 'GRID', "LININI" ),;
									oSize:GetDimension( 'GRID', "COLINI" ),;
									oSize:GetDimension( 'GRID', "LINEND" ),;
									oSize:GetDimension( 'GRID', "COLEND" ), /* cTitle */,oQtdFil,,,.T.)

			oProFil := FWBrowse():New( oGroup )
			oProFil:SetDataArray()
			oProFil:SetArray( aProFil )
			oProFil:DisableConfig()
			oProFil:DisableReport()
			oProFil:SetColumns( aColumns )
			oProFil:SetLineHeight( 20 )
			oProFil:SetEditCell( .T., bVldCell )
			oProFil:GetColumn(3):SetReadVar( "aProFil[oProFil:At()][6]" )
			oProFil:GetColumn(3):lEdit := .T.
			oProFil:Activate()	

			nAux := oSize:Getdimension( 'TOTAL', 'COLINI' )
			oGetNec := TGet():New( oSize:Getdimension( 'TOTAL', 'LININI' ),;
									nAux,;
									{|u| if(PCount()==0,nGetNec,nGetNec:=u)},oQtdFil,080,011,"@E 999,999,999.99",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'nGetNec',,,,.F.,.T.,,'Total Compra:', 1 )
			oGetNec:bWhen := {|| .F. }
			nAux += 90

			oGetQtd := TGet():New( oSize:Getdimension( 'TOTAL', 'LININI' ),;
									nAux,;
									{|u| if(PCount()==0,nGetQtd,nGetQtd:=u)},oQtdFil,080,011,"@E 999,999,999.99",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'nGetQtd',,,,.F.,.T.,,'Qtde Atual:', 1 )
			oGetQtd:bWhen := {|| .F. }
			nAux += 90

			oGetEmp := TGet():New( oSize:Getdimension( 'TOTAL', 'LININI' ),;
									nAux,;
									{|u| if(PCount()==0,nGetEmp,nGetEmp:=u)},oQtdFil,080,011,"@E 999,999,999.99",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'nGetEmp',,,,.F.,.T.,,'Empenhado:', 1 )
			oGetEmp:bWhen := {|| .F. }
			nAux += 90

			oGetMed := TGet():New( oSize:Getdimension( 'TOTAL', 'LININI' ),;
									nAux,;
									{|u| if(PCount()==0,nGetMed,nGetMed:=u)},oQtdFil,080,011,"@E 9,999,999.9999",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'nGetMed',,,,.F.,.T.,,'Consumo/Dia:', 1 )
			oGetMed:bWhen := {|| .F. }
			nAux += 90

			oGetCom := TGet():New( oSize:Getdimension( 'TOTAL', 'LININI' ),;
									nAux,;
									{|u| if(PCount()==0,nGetCom,nGetCom:=u)},oQtdFil,080,011,"@E 9,999,999.9999",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'nGetCom',,,,.F.,.T.,,'Comprado:', 1 )
			oGetCom:bWhen := {|| .F. }

			oQtdFil:Activate(,,,.T., bValid,,bInit)
			lCanEdit := .F.
		endif

	elseif oBrwPro:GetColumn(oBrwPro:ColPos()):GetID() == 'QTDBLOQ'		
	
		// Deixa alterar apenas quando a filial posicionada for a filial que o usuário está logado
		if len( _aFil ) == 1 .and. _aFil[1] == cFilAnt .and. aColPro[oBrw:At()][nPosBlq] > 0
			_nQtBlq := aColPro[oBrw:At()][nPosBlq]
			lCanEdit := .T.
		else
			lCanEdit := .F.
		endif
	endif

return lCanEdit

/*/{Protheus.doc} filName
Função para retornar nome da filial conforme código de empresa e filial recebidos como parâmetro
@type function
@version 12.1.2410
@author Jean Carlos Pandolfo Saggin
@since 5/14/2025
@param cEmp, character, ID da empresa
@param cFil, character, ID da filial
@return character, descrição da filial
/*/
static function filName( cEmp, cFil )
	local cFilName := "" as character
	local cQuery := "" as character
	local cAlias := "" as character
	cQuery := "SELECT M0_FILIAL FROM SYS_COMPANY M0 WHERE M0.M0_CODIGO = '"+ cEmp +"' AND M0.M0_CODFIL = '"+ cFil +"' AND M0.D_E_L_E_T_ = ' ' " 
	cAlias := MPSysOpenQuery( cQuery )
	if ! ( cAlias )->( EOF() )
		cFilName := AllTrim(( cAlias )->M0_FILIAL)
	endif
	( cAlias )->( DBCloseArea() )
return cFilName

/*/{Protheus.doc} updCarCom
Função para atualizar quantidade no carrinho de compra
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/25/2024
@param cProduto, character, Codigo do produto
/*/
static function updCarCom( cProduto )
	
	local nAux   := 0 as numeric
	local nQuant := 0 as numeric
	local nFil   := 0 as numeric

	if len( _aFil ) > 0
		for nFil := 1 to len( _aFil )

			nAux   := aScan( _aProdFil, {|x| x[3] == cProduto .and. x[25] == _aFil[nFil] } )
			nQuant := _aProdFil[nAux][6]

			// Valida se o produto já está no carrinho
			if aScan( aCarFil, {|x| x[carPos('C7_PRODUTO')] == cProduto .and. x[len(x)] == _aFil[nFil] } ) > 0
				aCarFil[ aScan( aCarFil, {|x| x[carPos('C7_PRODUTO')] == cProduto .and. x[len(x)] == _aFil[nFil] } ) ][ carPos('QUANT') ] := nQuant
				aCarFil[ aScan( aCarFil, {|x| x[carPos('C7_PRODUTO')] == cProduto .and. x[len(x)] == _aFil[nFil] } ) ][ carPos('TOTAL') ] := nQuant * aCarFil[ aScan( aCarFil, {|x| x[carPos('C7_PRODUTO')] == cProduto .and. x[len(x)] == _aFil[nFil] } ) ][ carPos('PRECO') ]
			endif

		next nFil
	endif

return Nil

/*/{Protheus.doc} getCboFil
Função para retornar o combo de filtro de filiais no gráfico de consumo
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/16/2024
@return array, vetor de filiais
/*/
static function getCboFil()

	local aCboFil := {} as array
	local cQuery  := "" as array
	local cAlias  := "" as character
	
	aAdd( aCboFil, 'XX=Todas' )
	aAdd( aCboFil, 'YY=Filtro Filiais' )
	
	// Query para leitura das filiais da empresa no SM0 (SYS_COMPANY)
	cQuery := "SELECT M0.M0_CODFIL, M0.M0_FILIAL FROM SYS_COMPANY M0 "
	cQuery += "WHERE M0.M0_CODIGO = '"+ cEmpAnt +"' " 
	cQuery += "  AND M0.D_E_L_E_T_ = ' ' "
	cAlias := MPSysOpenQuery( cQuery )

	if !( cALias )->( EOF() )
		while ! ( cAlias )->( EOF() )
			aAdd( aCboFil, AllTrim(( cAlias )->M0_CODFIL) + '='+ AllTrim( ( cAlias )->M0_FILIAL ) )
			( cAlias )->( DBSkip() )
		end
	endif
	( cAlias )->( DBCloseArea() )

return aCboFil

/*/{Protheus.doc} fName
Retorna nome reduzido da filial
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/17/2024
@param cFil, character, Codigo da filial
@return character, cName
/*/
static function fName( cFil )
	local cQuery := "" as character
	local cAlias := "" as character
	cQuery := "SELECT M0_FILIAL FROM SYS_COMPANY WHERE M0_CODIGO = '"+ cEmpAnt +"' AND M0_CODFIL = '"+ cFil +"' AND D_E_L_E_T_ = ' ' "
	cAlias := MPSysOpenQuery( cQuery )
	if !( cAlias )->( EOF() )
		cName := AllTrim( ( cAlias )->M0_FILIAL )
	endif
	( cAlias )->( DBCloseArea() )
return cName

/*/{Protheus.doc} alterFil
Função executada na troca de filial na tela do carrinho de compra
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/17/2024
@param oBrowse, object, objeto do browse
@param cFil, character, filial selecionadda
/*/
static function alterFil( oBrowse, cCbo, cGetFor, cGetLoj )
	Local aCarrinho := getCarrinho( cGetFor, cGetLoj, cCbo )
	oBrowse:aCols := aClone( aCarrinho )
	oBrowse:ForceRefresh()
return Nil

/*/{Protheus.doc} getCarrinho
Função para fazer carrinho removendo campo filial utilizado apenas para controle
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/17/2024
@param cGetFor, character, Fornecedor
@param cGetLoj, character, Loja
@param cCbo, character, Filial
@param aHeader, array, Header do carrinho de compra
@return array, aCarrinho
/*/
static function getCarrinho( cGetFor, cGetLoj, cCbo, aHeader )
	
	local aCarrinho := {} as array
	local nCarrinho := 0 as numeric
	local lPEPNC02  := ExistBlock( 'PEPNC02' )		// Preparação dos dados do carrinho
	local aRetPE    := Nil

	aEval( aCarFil, {|x| iif( x[carPos('C7_FORNECE')]+x[carPos('C7_LOJA')]+x[len(x)] == cGetFor + cGetLoj + cCbo,;	
							aAdd( aCarrinho, aClone( x ) ),;
							Nil ) } )
	if len( aCarrinho ) > 0
		for nCarrinho := 1 to len( aCarrinho )
			aDel( aCarrinho[nCarrinho], len(aCarrinho[nCarrinho]) )
			aSize( aCarrinho[nCarrinho], len(aCarrinho[nCarrinho])-1 )
		next nCarrinho
	endif

	if lPEPNC02		// Alteração de dados no carrinho de compras
		aRetPE := ExecBlock( 'PEPNC02', .F., .F., { aHeader, aCarrinho } )
		if ValType( aRetPE ) == 'A'
			aCarrinho := aClone( aRetPE )
		endif
	endif
		
return aCarrinho

/*/{Protheus.doc} dataProdUpd
Função para atualizar os vetores de produtos com os dados do carrinho após a manutenção
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/18/2024
@param aCols, array, vetor do browse do carrinho de compra
@param cCbo, character, filial selecionada
/*/
static function dataProdUpd( oBrw, cCbo )
	
	local aCols    := oBrw:aCols
	local nQuant   := 0 as numeric
	local nValue   := 0 as numeric
	local cReadVar := ReadVar()
	local nX       := 0 as numeric
	local nAux     := 0 as numeric
	local nQtdSeg  := 0 as numeric
	local nValSeg  := 0 as numeric

	if len( aCols ) > 0
		
		for nX := 1 to len( aCols )

			nQuant := 0
			if oBrw:aHeader[oBrw:oBrowse:ColPos()][2] == 'QUANT' .and. 'QUANT' $ cReadVar .and. nX == oBrw:nAt
				nQuant := &( cReadVar )
			else
				nQuant := aCols[nX][carPos('QUANT')]
			endif
			nValue := 0
			if oBrw:aHeader[oBrw:oBrowse:ColPos()][2] == 'PRECO' .and. 'PRECO' $ cReadVar .and. nX == oBrw:nAt
				nValue := &( cReadVar )
			else
				nValue := aCols[nX][carPos('PRECO')]
			endif
			nQtdSeg := 0
			if oBrw:oBrowse:ColPos() == carPos( 'QTSEGUM' ) .and. nX == oBrw:nAt
				nQtdSeg := M->QTSEGUM
			else
				nQtdSeg := aCols[nX][carPos('QTSEGUM')] 
			endif
			nValSeg := 0
			if oBrw:oBrowse:ColPos() == carPos( 'VALSEGUM' ) .and. nX == oBrw:nAt
				nValSeg := M->VALSEGUM
			else
				nValSeg := aCols[nX][carPos('VALSEGUM')]
			endif

			// Ajusta o vetor de origem do carrinho individual por filial
			nAux := aScan( aCarFil, {|x| x[carPos('C7_PRODUTO')] == aCols[nX][carPos('C7_PRODUTO')] .and. x[carPos('C7_FORNECE')] == cGetFor .and. x[carPos('C7_LOJA')] == cGetLoj .and. x[len(x)] == cCbo } )
			if nAux > 0
				aCarFil[nAux][carPos('QUANT')]      := nQuant
				aCarFil[nAux][carPos('PRECO')]      := nValue
				aCarFil[nAux][carPos('TOTAL')]      := nValue * nQuant
				aCarFil[nAux][carPos('QTSEGUM')]    := nQtdSeg 
				aCarFil[nAux][carPos('VALSEGUM')]   := nValSeg
			endif

			// Ajusta o vetor que armazena dados do produto x filial
			nAux := aScan( _aProdFil, {|x| x[3] == aCols[nX][carPos('C7_PRODUTO')] .and. x[25] == cCbo } )
			if nAux > 0 
				_aProdFil[nAux][6] := nQuant		
				_aProdFil[nAux][8] := nValue
			endif

			// Soma quantidade geral por produto a ser comprado
			nQuant := 0
			aEval( _aProdFil, {|x| iif( x[3] == aCols[nX][carPos('C7_PRODUTO')], nQuant += x[6], Nil ) } )

			// Verifica se consegue encontrar o produto no vetor de produtos
			nAux := aScan( aColPro, {|x| x[nPosPrd] == aCols[nX][carPos('C7_PRODUTO')] } )
			
			// Percorre vetor alterando quantidade genérica por produto
			if nAux > 0 
				aColPro[nAux][nPosNec] := nQuant
				aColPro[nAux][nPosNeg] := nValue

				// Replace no vetor de 
				aFullPro[ aScan( aFullPro, {|x| x[nPosPrd] == aCols[nX][carPos('C7_PRODUTO')] } ) ] := aClone( aColPro[nAux] )
			endif

		next nX
	endif

	oBrwPro:UpdateBrowse()

return Nil

/*/{Protheus.doc} gPos
Função para retornar posição de um campo contido no grid do tipo MsNewGetDados
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/18/2024
@param oGrid, object, objeto do grid
@param cField, character, nome do cajpo
@return numeric, nPos
/*/
static function gPos( oGrid, cField )
return aScan( oGrid:aHeader, {|x| AllTrim( x[2] ) == AllTrim( cField ) } )

/*/{Protheus.doc} getDatInc
* A T E N Ç Ã O * NECESSARIO ESTAR POSICIONADO NA SB1 PARA EXECUTAR A FUNCAO
Função para retornar data da inclusao do produto no sistema (se houver)
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/30/2024
@param dIni, date, data de inicio das análises
@return date, dDatInc
/*/
static function getDatInc( dIni )
	
	local dDatInc := StoD( '20100101' )

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

	if dIni > dDatInc
		dDatInc := dIni
	endif

return dDatInc

/*/{Protheus.doc} outPuts
Função para exibir as saídas de um determinado produto, seja por consumo no processo produtivo ou pela venda
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 1/15/2025
@param cProduto, character, ID do produto
/*/
static function outPuts( cProduto )

	local aFields   := {} as array
	local aColumns  := {} as array
	local oBrwOut as object
	local bOk       := {|| oOutPuts:End() }
	local bCancel   := {|| oOutPuts:End() }
	local aButtons  := {} as array
	local bValid    := {|| .T. }
	local bInit     := {|| EnchoiceBar( oOutPuts, bOk, bCancel, , aButtons ),;
						   Processa( {|| makeTot(oBrwOut, dDe, dAte, _aFil, cProduto ),;
						   oOutPuts:Refresh() }, 'Aguarde...', 'Rastreando dados do produto...' ) }
	local nFields   := 0 as numeric
	local cType     := "" as character
	local oLayer    as object
	local oWinMov   as object
	local cQuery    := "" as character
	local dDe       := StoD("")
	local dAte      := CtoD( SubStr( AllTrim( SuperGetMv( 'MV_X_PNC12',,"" ) ), 1, 10 ) ) 
	local nDUteis   := 0 as numeric
	local nAux      := 0 as numeric
	local cDescri   := AllTrim( RetField( 'SB1', 1, FWxFilial( 'SB1' ) + cProduto, 'B1_DESC' ) )
	local cDB       := TCGetDB()
	local oWinMed   as object

	private oDocPrd as object
	private nDocPrd := 0 as numeric
	private oDocTot as object
	private nDocTot := 0 as numeric
	private oIndGiro as object
	private nIndGiro := 0 as numeric
	private oClassif as object
	private cClassif := "" as character
	Private oOutPuts as object
	private oWinRes  as object
	private oQtdSai  as object
	private nQtdSai  := 0 as numeric
	private oMedSai  as object
	
	// Define período de análise das movimentações de saída conforme parâmetros 
	if aConfig[15] == 'C'		// Verifica configurações de dias (corridos ou úteis)
		dDe := dAte-aConfig[14]
	Else
		nDUteis := 0
		nAux    := 0
		While nDUteis < aConfig[14]
			if DataValida( dAte - nAux, .T. ) == dAte - nAux
				nDUteis++
			EndIf
			nAux++
		EndDo
		dDe := dAte - nAux
	EndIf

	aAdd( aColumns, FWBrwColumn():new() )
	aColumns[len(aColumns)]:SetTitle( 'Tipo Saída' )
	aColumns[len(aColumns)]:SetType( 'C' )
	aColumns[len(aColumns)]:SetSize( 10 )
	aColumns[len(aColumns)]:SetDecimal( 0 )
	aColumns[len(aColumns)]:SetAlign( 1 )
	aColumns[len(aColumns)]:SetData( &('{|| iif( TIPO == "P", "Produção", "Venda" ) }') )
	aColumns[len(aColumns)]:SetPicture( "@x" )
	
	aFields := { "D2_FILIAL", "D2_DOC", "D2_SERIE", "D2_EMISSAO", "D2_CLIENTE", "D2_LOJA", "A1_NOME", "D2_LOCAL", "D2_QUANT" }
	for nFields := 1 to len( aFields )
		cType := GetSX3Cache( aFields[nFields], 'X3_TIPO' )
		aAdd( aColumns, FWBrwColumn():new() )
		aColumns[len(aColumns)]:SetTitle( AllTrim(GetSX3Cache( aFields[nFields], 'X3_TITULO' )) )
		aColumns[len(aColumns)]:SetType( cType )
		aColumns[len(aColumns)]:SetSize( GetSX3Cache( aFields[nFields], 'X3_TAMANHO' ) )
		aColumns[len(aColumns)]:SetDecimal( GetSX3Cache( aFields[nFields], 'X3_DECIMAL' ) )
		aColumns[len(aColumns)]:SetAlign( iif( cType == "N", 2, iif( cType $ 'M|C', 1, 0 ) ) )
		aColumns[len(aColumns)]:SetData( &('{|| '+ iif( cType == 'D', 'StoD(', '' ) + aFields[nFields] + iif( cType == 'D', ')', '' ) +' }') )
		aColumns[len(aColumns)]:SetPicture( AllTrim(GetSX3Cache( aFields[nFields], 'X3_PICTURE' )) )
	next nFields

	// Query para leitura dos dados de saída do produto
	cQuery += "SELECT TEMP.* FROM ( "
	cQuery += U_JSQRYSAI( cProduto, dDe, dAte, _aFil )
	if AllTrim(cDB) $ "ORACLE|SQLSERVER" 
		cQuery += ") TEMP "
	else
		cQuery += ") AS TEMP "
	endif
	cQuery += "ORDER BY TEMP.D2_FILIAL, TEMP.D2_EMISSAO, TEMP.D2_DOC, TEMP.A1_NOME "

	oOutPuts := TDialog():New( 0, 0, 600, MsAdvSize()[5]*0.9, 'Saídas de '+ cDescri +' de '+ DtoC( dDe ) +' até '+ DtoC( dAte ), , , , , CLR_BLACK, CLR_WHITE, , , .T. )

	oLayer := FWLayer():New()
	oLayer:Init( oOutPuts, .F. /* lCloseButton */ )
	oLayer:AddLine( 'LINE01', 30, .F. )
	oLayer:AddLine( 'LINE02', 68, .F. )
	
	oLayer:AddColumn( 'COL01', 060, .F., 'LINE01' )
	oLayer:AddColumn( 'COL03', 040, .F., 'LINE01' )
	oLayer:AddColumn( 'COL02', 100, .F., 'LINE02' )

	oLayer:AddWindow( 'COL01', 'WIN01', 'Totalizadores'      , 100, .F., .F., {|| Nil }, 'LINE01', {|| Nil } )
	oLayer:AddWindow( 'COL03', 'WIN03', 'DashBoard de Médias', 100, .F., .F., {|| Nil }, 'LINE01', {|| Nil } )
	oLayer:AddWindow( 'COL02', 'WIN02', 'Movimentos de Saída', 100, .F., .F., {|| Nil }, 'LINE02', {|| Nil } )
	
	oWinRes := oLayer:GetWinPanel( 'COL01', 'WIN01', 'LINE01' )
	oWinMov := oLayer:GetWinPanel( 'COL02', 'WIN02', 'LINE02' )
	oWinMed := oLayer:GetWinPanel( 'COL03', 'WIN03', 'LINE01' )

	oDocPrd := TGet():New( 06, 04, {|u| if(PCount()==0,nDocPrd,nDocPrd:=u) }, oWinRes, 60, 12, "@E 999,999",,0,Nil,,.F.,,.T. /* lPixel */,,.F.,{|| .F. }/* bWhen */,;
						.F.,.F.,/* bChange */,/* lReadOnly */,.F.,,'nDocPrd',,,,.T.,.F.,,'Saídas Produto', 1 )

	oDocTot := TGet():New( 06, 74, {|u| if(PCount()==0,nDocTot,nDocTot:=u) }, oWinRes, 60, 12, "@E 999,999",,0,Nil,,.F.,,.T. /* lPixel */,,.F.,{|| .F. }/* bWhen */,;
						.F.,.F.,/* bChange */,/* lReadOnly */,.F.,,'nDocTot',,,,.T.,.F.,,'Total Saídas', 1 )
	
	oIndGiro := TGet():New( 06, 144, {|u| if(PCount()==0,nIndGiro,nIndGiro:=u) }, oWinRes, 60, 12, PesqPict( cZB3, cZB3 + '_INDINC' ),,0,Nil,,.F.,,.T. /* lPixel */,,.F.,{|| .F. }/* bWhen */,;
						.F.,.F.,/* bChange */,/* lReadOnly */,.F.,,'nIndGiro',,,,.T.,.F.,,'Índice Incidência', 1 )

	oClassif := TGet():New( 06, 214, {|u| if(PCount()==0,cClassif,cClassif:=u) }, oWinRes, 80, 12, "@x",,0,Nil,,.F.,,.T. /* lPixel */,,.F.,{|| .F. }/* bWhen */,;
						.F.,.F.,/* bChange */,/* lReadOnly */,.F.,,'cClassif',,,,.T.,.F.,,'Classificação', 1 )

	oQtdSai  := TGet():New( 30, 04, {|u| if(PCount()==0,nQtdSai,nQtdSai:=u) }, oWinRes, 80, 12, "@E 999,999,999.99",,0,Nil,,.F.,,.T. /* lPixel */,,.F.,{|| .F. }/* bWhen */,;
						.F.,.F.,/* bChange */,/* lReadOnly */,.F.,,'nQtdSai',,,,.T.,.F.,,'Quant.Saída', 1 )

	oMedSai  := FWChartFactory():New()
    oMedSai:SetChartDefault( COLUMNCHART )
    oMedSai:SetOwner( oWinMed )
    oMedSai:SetLegend( CONTROL_ALIGN_NONE )
 	oMedSai:SetAlignSerieLabel(CONTROL_ALIGN_RIGHT)
 	oMedSai:EnableMenu(.F.)
    oMedSai:SetMask(" *@* ")
    oMedSai:SetPicture( '@E 999,999.9999' )
    oMedSai:Activate()

	oBrwOut := FWBrowse():New( oWinMov )
	oBrwOut:SetDataQuery()
	oBrwOut:SetColumns( aColumns )
	oBrwOut:SetQuery( cQuery )
	oBrwOut:SetAlias( 'SAITMP' )
	oBrwOut:DisableReport()
	oBrwOut:DisableConfig()
	oBrwOut:SetLineHeight( 20 )
	oBrwOut:Activate()

	oOutPuts:Activate(,,,.T., bValid,, bInit)

return Nil

/*/{Protheus.doc} makeTot
Função para atualizar totalizadores da tela de detalhamento dos movimentos de saída
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 1/15/2025
@param oBrowse, object, objeto do browse
@param dDe, date, inicio da faixa de análise
@param dAte, date, final da faixa de data
@param _aFil, array, vetor de filiais selecionadas pelo usuário
/*/
static function makeTot( oBrowse, dDe, dAte, _aFil, cProduto )
	
	local cAlias   := oBrowse:Alias()
	local aArea    := ( cAlias )->( GetArea() )
	local aDocsPrd := {} as array
	local cQuery   := "" as character
	local cTmp     := "" as character
	local cDB      := TCGETDB()
	local aPer     := {} as array
	local dAux1    := StoD('')
	local dAux2    := StoD('')
	local nAux     := 0 as numeric

	dAux2 := date()-Day(Date())
	dAux1 := dAux2
	nAux  := 1
	while nAux <= 6
		dAux1-= Day(dAux1)
		nAux++
	end
	dAux1+=1
	aAdd( aPer, { '6M', dAux1, dAux2 } )		// 6 meses

	dAux2 := date()-Day(Date())
	dAux1 := dAux2
	nAux  := 1
	while nAux <= 3
		dAux1-= Day(dAux1)
		nAux++
	end
	dAux1+=1
	aAdd( aPer, { '3M', dAux1, dAux2 } )		// 3 meses

	dAux2 := date()-Day(Date())
	dAux1 := dAux2 - (Day(dAux2)-1)	
	aAdd( aPer, { SubStr(Lower(MesExtenso(Month(dAux1))),1,3)+'/'+Right(AllTrim(cValToChar(Year(dAux1))),2), dAux1, dAux2 } )		// Último Mês Cheio

	ProcRegua( 4 )
	IncProc( 'Identificando saídas com o produto...' )
	nQtdSai := 0
	( cAlias )->( DBGoTop() )
	while ! ( cAlias )->( EOF() )

		if len( aDocsPrd ) == 0 .or. aScan( aDocsPrd, {|x| AllTrim(x[1]) + AllTrim(x[2]) == AllTrim(( cAlias )->D2_DOC) + AllTrim(( cAlias )->D2_SERIE) } ) == 0
			aAdd( aDocsPrd, { ( cAlias )->D2_DOC, ( cAlias )->D2_SERIE } )
		endif
		nQtdSai += ( cAlias )->D2_QUANT
		( cAlias )->( DBSkip() )
	end
	nDocPrd := len( aDocsPrd )

	IncProc( 'Identificando número total de saídas' )
	cQuery := "SELECT COUNT( DISTINCT CONCAT( TEMP.D2_DOC, TEMP.D2_SERIE ) ) QTD_SAIDAS FROM ( "
	cQuery += U_JSQRYSAI( Nil, dDe, dAte, _aFil ) 
	if AllTrim(cDB) $ "ORACLE|SQLSERVER" 
		cQuery += ") TEMP "
	else
		cQuery += " ) AS TEMP "
	endif
	cTmp := MPSysOpenQuery( cQuery )
	if ! ( cTmp )->( EOF() )
		nDocTot := ( cTmp )->QTD_SAIDAS
	endif
	( cTmp )->( DBCloseArea() )

	IncProc( 'Calculando índices...' ) 
	nIndGiro := ( nDocPrd / nDocTot ) * 100
	
	if nIndGiro >= aConfig[10]
		cClassif := "Itens Críticos"
	elseif  nIndGiro >= aConfig[11] .and. nIndGiro <=  (aConfig[10]-0.000001)
		cClassif := "Alto Giro"
	elseif nIndGiro >= aConfig[12] .and. nIndGiro <= (aConfig[11]-0.000001)
		cClassif := "Médio Giro"
	elseif nIndGiro >= aConfig[13] .and. nIndGiro <= (aConfig[12]-0.000001)
		cClassif := "Baixo Giro"
	else
		cClassif := "Sem Giro"
	endif

	IncProc( 'Atualizando gráfico...' )
	oMedSai:DeActivate()
	for nAux := 1 to len( aPer )
		cQuery := "SELECT COALESCE(SUM( TEMP.D2_QUANT ),0) SAIDAS FROM ( "
		cQuery += U_JSQRYSAI( cProduto, aPer[nAux][2], aPer[nAux][3], _aFil ) 
		if AllTrim(cDB) $ "ORACLE|SQLSERVER" 
			cQuery += ") TEMP "
		else
			cQuery += " ) AS TEMP "
		endif
		cTmp := MPSysOpenQuery( cQuery )
		if ! ( cTmp )->( EOF() )
			oMedSai:AddSerie( aPer[nAux][01], ( cTmp )->SAIDAS/(aPer[nAux][3]-(aPer[nAux][2]-1)) )
		endif
		( cTmp )->( DBCloseArea() )
	next nAux
	oMedSai:Activate()

	oDocPrd:CtrlRefresh()
	oDocTot:CtrlRefresh()
	oIndGiro:CtrlRefresh()
	oClassif:CtrlRefresh()
	oQtdSai:CtrlRefresh()

	restArea( aArea )
return Nil

/*/{Protheus.doc} printBrw
Função para gerar processo de extração dos dados de análise dos produtos
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/6/2025
@param oBrowse, object, objeto do browse
/*/
static function printBrw( oBrowse )
	
	local aArea := getArea()
	local oReport as object

	oReport := repPrdDef()
	oReport:PrintDialog()																																																																								

	restArea( aArea )
return Nil

/*/{Protheus.doc} repPrdDef
Função que gera o modelo do relatório no formato TReport
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/7/2025
@return object, oReport
/*/
static function repPrdDef()
	
	local oReport  as object
	local bReport  := {|oReport| repPrtProd( oReport ) }
	local oSection as object
	local oColumns := oBrwPro:GetColumns()
	local nCol     := 0 as numeric

	oReport := TReport():New( "GMPAICOM",;
							  "Análise de Produtos para Compra",;
							  Nil,;
							  bReport,;
							  Nil )
	oReport:SetTotalInLine( .F. )
	oReport:lParamPage := .F.
	oReport:oPage:SetPaperSize( 9 )			// Default tamanho A4
	oReport:cFontBody := 'Courier New'
	oReport:nFontBody := 6
	oReport:nLineHeight := 30
	oReport:SetLandscape()					// Formato default paisagem

	oSection := TRSection():New( oReport,;
								 "Produtos Analisados",;
								 { "QRY_AUX" } )
	
	oSection:SetTotalInLine( .F. )
	oSection:SetHeaderSection( .T. )		// Imprime cabecalho da seção

	// Algoritmo para identificar colunas ativas do browse e criar as TRCell dinamicamente
	if ValType( oColumns ) == 'A'
		for nCol := 1 to len( oColumns )
			if ! Empty( oColumns[nCol]:GetID() ) .and. !oColumns[nCol]:Deleted()
				TRCell():New( oSection /* oSection */,; 
							oColumns[nCol]:GetID() /* cFieldID */,; 
							"QRY_AUX" /* cMainAlias */,;
							oColumns[nCol]:GetTitle() /* cTitle */,;
							oColumns[nCol]:GetPicture() /* cPicture */,;
							oColumns[nCol]:GetSize() /* nSize */,;
							.T. /* lPixels */,;
							&('{|| '+ oColumns[nCol]:ReadVar() +'}') /* bPrinterCodeBlock */,;
							iif( oColumns[nCol]:GetAlign() == 0, "CENTER", iif( oColumns[nCol]:GetAlign() == 1, "LEFT", "RIGHT" ) ) /* cAlign */,;
							Nil /* cHeaderAlign */,;
							Nil /* lCellBreak */,;
							Nil /* nColSpace */,;
							Nil /* lAutoSize */,;
							Nil /* nClrBack */,;
							Nil /* nClrFore */,;
							Nil /* lBold */ )
			endif
		next nCol
	endif
	
return oReport

/*/{Protheus.doc} repPrtProd
Função para imprimir o relatório utilizando o modelo criado anteriormente
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/7/2025
@param oReport, object, Model do relatório
/*/
static function repPrtProd( oReport )
	
	local aArea    := getArea()
	local oSection := oReport:Section(1)
	local nLine    := 0 as numeric
	local nLineOld := oBrwPro:At()

	oReport:SetMeter( len( aColPro ) )	
	if len( aColPro ) > 0

		oSection:Init()
		for nLine := 1 to len( aColPro )
			
			oBrwPro:GoTo( nLine )

			oReport:SetMsgPrint( 'Imprimindo registro '+ cValToChar( nLine )  +' de '+ cValToChar( len( aColPro ) ) )
			oReport:IncMeter()
			oSection:PrintLine()

		next nLine

		oBrwPro:GoTo( nLineOld )
		oSection:Finish()

	endif

	restArea( aArea )
return Nil

/*/{Protheus.doc} manutProd
Função de chamada da rotina de manutenção de produtos usando modelo MVC
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/7/2025
@param cProduto, character, ID do produto
/*/
static function manutProd( cProduto )
	
	local cFunOld := FunName()

	DBSelectArea( 'SB1' )
	SB1->( DBSetOrder( 1 ) )
	if SB1->( DBSeek( FWxFilial( 'SB1' ) + cProduto ) )
		SetFunName( 'MATA010' )
		If FWExecView( 'Manutenção do Produto', 'MATA010', MODEL_OPERATION_UPDATE ) == 0
			Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' )			
		endif
		SetFunName( cFunOld )
	endif
return Nil

/*/{Protheus.doc} mrpRemove
Função para remover o produto do MRP
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/8/2025
@param cProduto, character, ID do produto
@return logical, lSuccess
/*/
static function mrpRemove( cProduto )
	local cFunOld := FunName()
	local aFields := {} as array
	local lSuccess := .F. as logical
	
	DBSelectArea( 'SB1' )
	SB1->( DBSetOrder( 1 ) )
	if SB1->( DBSeek( FWxFilial( 'SB1' ) + cProduto ) )

		// Verifica se realmente quer remover o produto dos cálculos do MRP
		if MsgYesNo( 'Está certo(a) de que quer remover este produto dos cálculos do MRP? Se possuir Ordens de Produção '+;
					'que utilizem este produto como matéria-prima, os empenhos não serão gerados!', 'A T E N Ç Ã O !' )

			SetFunName( 'MATA010' )
			aAdd( aFields, { "B1_FILIAL", FWxFilial( "SB1" ), Nil } )
			aAdd( aFields, { "B1_COD", cProduto, Nil } )
			aAdd( aFields, { "B1_MRP", 'N' } )
			If FWMVCRotAuto( FWLoadModel( 'MATA010' ), "SB1", MODEL_OPERATION_UPDATE, {{"SB1MASTER", aFields}} ,,.T.)
				lSuccess := .T.
				Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' )			
			endif
			SetFunName( cFunOld )

		endif
	endif

	SetFunName( cFunOld )
return lSuccess

/*/{Protheus.doc} updProFor
Função de atualização do vínculo entre produto e fornecedor
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/25/2025
@param cProduto, character, ID do produto
@param cFornece, character, ID do fornecedor
@param cLoja, character, Loja do fornecedor
@param lRemover, logical, Indica se o vínculo deve ser removido
@return logical, lSuccess
/*/
static function updProFor( cProduto, cFornece, cLoja, lRemover )
	
	local lSuccess := .F. as logical
	default lRemover := .F.

	if lRemover
		DBSelectArea( 'SA5' )
		SA5->( DBSetOrder( 1 ) )	// Filial + Fornece + Loja + Produto
		if SA5->( DBSeek( FWxFilial( 'SA5' ) + PADR(AllTrim(cFornece),tamsx3('A5_FORNECE')[1],' ') + PADR(AllTrim(cLoja),TAMSX3('A5_LOJA')[1],' ') + cProduto ) )
			RecLock( 'SA5', .F. )
			SA5->( DBDelete() )
			SA5->( MsUnlock() )
			lSuccess := .T.
		endif
	else
		// Quando fornecedor ou loja estiverem vazios, ignora o processo de vínculo entre produto e fornecedor
		if ! Empty( cFornece ) .and. ! Empty( cLoja )

			if aConfig[22] == '1'		// Fabricante
				
				// Atualiza vínculo de produto com o fabricante
				DBSelectArea( 'SB1' )
				SB1->( DBSetOrder( 1 ) )		// Filial + Cod
				if SB1->( DBSeek( FWxFilial( 'SB1' ) + cProduto ) )
					if SB1->B1_PROC != cFornece .or. SB1->B1_LOJPROC != cLoja
						RecLock( 'SB1', .F. )
						SB1->B1_PROC := cFornece
						SB1->B1_LOJPROC := cLoja
						SB1->( MsUnlock() )
						lSuccess := .T.
					endif
				endif

			else	// Produto x Fornecedor ou histórico

				DBSelectArea( 'SA5' )
				SA5->( DBSetOrder( 1 ) )	// Filial + Fornece + Loja + Produto
				if ! SA5->( DBSeek( FWxFilial( 'SA5' ) + cFornece + cLoja + cProduto ) )
					RecLock( 'SA5', .T. )
					SA5->A5_FILIAL  := FWxFilial( 'SA5' )
					SA5->A5_FORNECE := cFornece
					SA5->A5_LOJA    := cLoja
					SA5->A5_NOMEFOR := RetField( "SA2", 1, FWxFilial( 'SA2' ) + cFornece + cLoja, 'A2_NOME' )
					SA5->A5_PRODUTO := cProduto
					SA5->A5_NOMPROD := RetField( "SB1", 1, FWxFilial( 'SB1' ) + cProduto, 'B1_DESC' )
					SA5->A5_CHAVE   := newKey()
					SA5->( MsUnlock() )
					lSuccess := .T.
				endif

			endif

		endif

	endif

return lSuccess

/*/{Protheus.doc} priceSupplier
Função para obter o preço do fornecedor (tabela ou histórico)
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/27/2025
@param cProduto, character, ID do produto
@param cFornece, character, ID do fornecedor
@param cLoja, character, Loja do fornecedor
@return numeric, nPrice
/*/
static function priceSupplier( cProduto, cFornece, cLoja )
	
	local aArea  := getArea()
	local nPrice := 0  as numeric
	local cQuery := "" as character
	local cAlias := "" as character

	cQuery := "SELECT AIB_PRCCOM FROM "+ RetSqlName( "AIB" ) +" AIB " 

	cQuery += "INNER JOIN "+ RetSqlName( 'AIA' ) +" AIA "
	cQuery += " ON AIA.AIA_FILIAL = '"+ FWxFIlial( 'AIA' ) +"' "
	cQuery += "AND AIA.AIA_CODFOR = AIB.AIB_CODFOR "
	cQuery += "AND AIA.AIA_LOJFOR = AIB.AIB_LOJFOR "
	cQuery += "AND AIA.AIA_CODTAB = AIB.AIB_CODTAB "
	cQuery += "AND '"+ DtoS(dDataBase) +"' >= AIA.AIA_DATDE " 
	cQuery += "AND '"+ DtoS(dDataBase) +"' <= CASE WHEN AIA.AIA_DATATE = '"+ Space(8) +"' THEN '99999999' ELSE AIA.AIA_DATATE END "
	cQuery += "AND AIA.D_E_L_E_T_ = ' ' "

	cQuery += "WHERE AIB.AIB_FILIAL = '"+ FWxFilial( "AIB" ) +"' "
	cQuery += "  AND AIB.AIB_CODFOR = '"+ cFornece +"' "
	cQuery += "  AND AIB.AIB_LOJFOR = '"+ cLoja +"' "
	cQuery += "  AND AIB.AIB_CODPRO = '"+ cProduto +"' "
	cQuery += "  AND AIB.AIB_DATVIG <= '"+ DtoS( dDataBase ) +"' "
	cQuery += "  AND AIB.D_E_L_E_T_ = ' ' "

	cAlias := MPSysOpenQuery( cQuery )
	DBSelectArea( cAlias )
	if ! ( cAlias )->( EOF() )
		nPrice := ( cAlias )->AIB_PRCCOM
	endif
	( cAlias )->( DBCloseArea() )

	// Quando não houver preço de tabela, utiliza o último preço de nota de entrada cobrado pelo fornecedor
	if nPrice == 0
		nPrice := lastPrice( cProduto, cFornece, cLoja )
	endif

	restArea( aArea )
return nPrice

/*/{Protheus.doc} doHeadCar
Cria o header do carrinho de compra pra poder ler as variáveis de referência de colunas
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 3/6/2025
@return array, aReturn[aHeaderEx,aCarAlt] 
/*/
static function doHeadCar()

	local aHeaderEx := {} as array
	local aAlter    := {"QUANT","PRECO","TOTAL","DATPRF","C7_LOCAL","C7_OBSM","C7_IPI", "QTSEGUM", "VALSEGUM" }
	Local aFields   := {"C7_PRODUTO","C7_DESCRI","C7_UM","QUANT","PRECO","TOTAL","DINICOM","DATPRF","C7_LOCAL",;
						"C7_OBSM","C7_SEGUM","QTSEGUM","VALSEGUM","C7_CC","C7_IPI","C7_VLDESC","C7_FORNECE", "C7_LOJA" } 
	local lUsaFrete := X3Uso( GetSX3Cache( 'C7_VALFRE', 'X3_USADO' ) )
	local lPEPNC01  := ExistBlock( 'PEPNC01' )
	local aRetPE    := Nil
	local nX        := 0 as numeric

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
			aAdd( aHeaderEx, {"Total","TOTAL","@E 999,999,999.99",15,2,/*SX3->X3_VALID*/,,"N",,"V",,} )
		elseif aFields[nX] == 'DINICOM'
			aAdd( aHeaderEx, {"In.Compra","DINICOM","@D",08,0,/*SX3->X3_VALID*/,,"D",,"V",,} )
		elseif aFields[nX] == 'DATPRF'
			aAdd( aHeaderEx, {"Entrega","DATPRF","@D",08,0,/*SX3->X3_VALID*/,,"D",,"V",,} )
		elseif aFields[nX] == 'QTSEGUM'
			aAdd( aHeaderEx, { "Qt.S.UM",; 
							   "QTSEGUM",; 
							   GetSX3Cache("C7_QTSEGUM", 'X3_PICTURE'),; 
							   GetSX3Cache("C7_QTSEGUM", 'X3_TAMANHO' ),;
							   GetSX3Cache("C7_QTSEGUM", 'X3_DECIMAL' ),;
							   /* GetSX3Cache("C7_QTSEGUM",, 'X3_VALID' ) */,;
							   GetSX3Cache("C7_QTSEGUM", 'X3_USADO' ),;
							   GetSX3Cache("C7_QTSEGUM", 'X3_TIPO' ),;
							   GetSX3Cache("C7_QTSEGUM", 'X3_F3' ),;
							   GetSX3Cache("C7_QTSEGUM", 'X3_CONTEXT' ),;
							   GetSX3Cache("C7_QTSEGUM", 'X3_CBOX' ),;
							   GetSX3Cache("C7_QTSEGUM", 'X3_RELACAO' ) } )
		elseif aFields[nX] == 'VALSEGUM'
			aAdd( aHeaderEx, {"Val.S.UM", 'VALSEGUM', "@E 999,999,999.99", 15, 2, /*SX3->X3_VALID*/,,"N",," V" ,,} )
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

	if lPEPNC01
		// Ponto de entrada para manutenção do aHeader (permite adicionar ou realizar a manutenção de campos existentes)
		// Este ponto de entrada funciona em conjunto com o PE PEPNC02, usado para popular os dados
		aRetPE := ExecBlock( "PEPNC01", .F., .F., aHeaderEx )
		if ValType( aRetPE ) == 'A' .and. len( aRetPE ) > 0
			aHeaderEx := aClone( aRetPE )

			// Para os campos novos adicionados e ou substituídos, adiciona todos eles ao vetor de campos em que o browse vai permitir alterações
			for nX := 1 to len( aHeaderEx )
				if aScan( aFields, {|x| AllTrim(x) == AllTrim( aHeaderEx[nX][2] ) } ) == 0
					aAdd( aAlter, aHeaderEx[nX][2] )
				endif
			next nX

		endif
	endif
	
return { aHeaderEx, aAlter }

/*/{Protheus.doc} carPos
FUnção para retornar posição de um campo do carrinho de compras de forma dinâmica
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 3/6/2025
@param cField, character, ID do campo
@return numeric, nPos
/*/
static function carPos( cField )
return aScan( aHeaCar, {|x| AllTrim( x[2] ) == AllTrim( cField ) } )

/*/{Protheus.doc} supplyerChoice
Função para retornar os fornecedores vinculados ao produto de forma que o usuário consiga selecioná-lo para atender a necessidade de compra do produto
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 3/20/2025
@param lForce, logical, indica se deve forçar a seleção de um fornecedor para poder encerrar a tela
@return variadic, xRet
/*/
static function supplyerChoice( lForce )
	
	local xRet     := "" as character
	local cDescri  := "" as character
	local bValid   := {|| !lForce .or. !Empty( xRet ) }
	local bRemove  := {|| updProFor( aColPro[oBrwPro:At()][nPosPrd], FORPRO->A5_FORNECE, FORPRO->A5_LOJA, .T. /* lRemover */ ),;
						  oBrowse:Refresh( .T. ),;
						  oBrowse:UpdateBrowse() }
	local aButtons := {{'BTNREMOVE', bRemove, 'Remover vínculo' }} as array
	local bOk      := {||   xRet := iif( !Empty( FORPRO->A5_FORNECE ) .and. !Empty( FORPRO->A5_LOJA ),; 
										FORPRO->A5_FORNECE + FORPRO->A5_LOJA,; 
										Space( TAMSX3('A2_COD')[1] ) + Space( TAMSX3('A2_LOJA')[1] )),; 
							iif( !lForce .or. !Empty(xRet),; 
								oDlgFor:End(),; 
								Hlp( "FORNOBRIGAT",;
									 "A seleção de fornecedor é obrigatória",;
									 "Selecione (ou adicione) um fornecedor e pressione o botão Confirmar para prosseguir com o processo de compra" ) ) }
	local bCancel  := {|| oDlgFor:End() }
	local bInit    := {|| EnchoiceBar( oDlgFor, bOk, bCancel, , aButtons ) }
	local oDlgFor  as object
	local aFields  := {} as array
	local aColumns := {} as array
	local oBrowse  as object
	local nX       := 0 as numeric
	local nAux     := 0 as numeric

	default lForce := .F.

	// Chega se tem conteúdo no browse de produtos antes de prosseguir
	if len( aColPro ) == 0 .or. Empty(aColPro[1][nPosPrd])
		Hlp( 'NOPRODUCT',;
			'Não há produtos em análise para seleção de fornecedores',;
			'Refaça o filtro, clica sobre o produto desejado quando este aparecer na área de análise e tente novamente' )
		restArea( aArea )
		return xRet
	endif

	xRet := aColPro[oBrwPro:At()][nPosFor] + aColPro[oBrwPro:At()][nPosLoj]
	aFields := { "A5_FORNECE", "A5_LOJA", "A2_NOME", "A5_CODPRF", "D1_VUNIT", "LDTIMEC", "LDTIMEI" }

	for nX := 1 to len( aFields )
		aAdd( aColumns, FWBrwColumn():New() )
		if aFields[nX] == 'LDTIMEC'
			aColumns[len(aColumns)]:SetTitle( 'Lt.Calc.' )
			aColumns[len(aColumns)]:SetData( &("{|| calcLt( '"+ aColPro[oBrwPro:At()][nPosPrd] +"', FORPRO->A5_FORNECE, FORPRO->A5_LOJA ) }") )	
			aColumns[len(aColumns)]:SetType( "N" )
			aColumns[len(aColumns)]:SetSize( 4 )
			aColumns[len(aColumns)]:SetAlign( getAlign( "N" ) )
			aColumns[len(aColumns)]:SetPicture( "@E 9,999" )
			aColumns[len(aColumns)]:SetID( aFields[nX] )
		elseif aFields[nX] == 'LDTIMEI'
			aColumns[len(aColumns)]:SetTitle( 'Lt.Infor.' )
			aColumns[len(aColumns)]:SetData( &("{|| "+ aFields[nX] +" }") )
			aColumns[len(aColumns)]:SetType( "N" )
			aColumns[len(aColumns)]:SetSize( 4 )
			aColumns[len(aColumns)]:SetAlign( getAlign( "N" ) )
			aColumns[len(aColumns)]:SetPicture( "@E 9,999" )
			aColumns[len(aColumns)]:SetID( aFields[nX] )
		else
			aColumns[len(aColumns)]:SetTitle( GetSX3Cache( aFields[nX], 'X3_TITULO' ) )
			if aFields[nX] == 'D1_VUNIT'
				aColumns[len(aColumns)]:SetData( &("{|| priceSupplier('"+ aColPro[oBrwPro:At()][nPosPrd] +"', FORPRO->A5_FORNECE, FORPRO->A5_LOJA ) }") )
			else
				aColumns[len(aColumns)]:SetData( &("{|| "+ aFields[nX] +" }") )
			endif
			aColumns[len(aColumns)]:SetType( GetSX3Cache( aFields[nX], 'X3_TIPO' ) )
			aColumns[len(aColumns)]:SetSize( GetSX3Cache( aFields[nX], 'X3_TAMANHO' )*0.4 )
			aColumns[len(aColumns)]:SetAlign( getAlign( GetSX3Cache( aFields[nX], 'X3_TIPO' ) ) )
			aColumns[len(aColumns)]:SetPicture( GetSX3Cache( aFields[nX], 'X3_PICTURE' ) )
			aColumns[len(aColumns)]:SetID( aFields[nX] )
		endif
	next nX

	cDescri := AllTrim( aColPro[oBrwPro:At()][nPosDes] )
	oDlgFor := TDialog():New(0,0,500,900,'Fornecedores de '+ cDescri,,,,,CLR_BLACK,CLR_WHITE,,,.T.)

	oBrowse := FWBrowse():New( oDlgFor )
	oBrowse:SetDataQuery()
	oBrowse:SetAlias( 'FORPRO' )
	oBrowse:SetQuery( querySupplyers() )
	oBrowse:DisableConfig()
	oBrowse:DisableReport()
	oBrowse:SetColumns( aColumns )
	oBrowse:SetDoubleClick( bOk )
	oBrowse:Activate()

	oDlgFor:Activate(,,,.T. /* lCentered */, bValid, , bInit )

	// Quando o Ok for pressionado, atualiza os dados dos campos
	if Empty( SubStr( xRet, 1, TAMSX3('A2_COD')[1] ) ) .or. Empty( SubStr( xRet, TAMSX3('A2_COD')[1]+1, TAMSX3('A2_LOJA')[1] ) )
		
		hlp( 'INVALIDSUPPLYER',;
			 'Fornecedor inválido! O registro selecionado será ignorado!',;
			 'Utilize a busca de fornecedor (F4) e selecione um registro com código e loja válidos' )
	    xRet := Space( TAMSX3('A2_COD')[1] ) + Space( TAMSX3('A2_LOJA')[1] )

	endif

	if xRet != aColPro[oBrwPro:At()][nPosFor] + aColPro[oBrwPro:At()][nPosLoj]
		
		aColPro[oBrwPro:At()][nPosFor] := SubStr( xRet, 1, TAMSX3('A2_COD')[1] )
		aColPro[oBrwPro:At()][nPosLoj] := SubStr( xRet, TAMSX3('A2_COD')[1]+1, TAMSX3('A2_LOJA')[1] )
		for nX := 1 to len( _aProdFil )
			if _aProdFil[nX][3] == aColPro[oBrwPro:At()][nPosPrd] 
				_aProdFil[nX][23] := aColPro[oBrwPro:At()][nPosFor] 
				_aProdFil[nX][24] := aColPro[oBrwPro:At()][nPosLoj] 
			endif
		next nX
		aFullPro[aScan( aFullPro, {|x| x[nPosPrd] == aColPro[oBrwPro:At()][nPosPrd] } )] := aClone( aColPro[oBrwPro:At()] )

		// Quando usuário não alterou o preço negociado, atualiza o conteúdo do campo do preço conforme tabela de preço do novo fornecedor ou preço historico do novo fornecedor
		if aColPro[oBrwPro:nAt][nPosUlt] == aColPro[obrwPro:nAt][nPosNeg]

			aColPro[oBrwPro:nAt][nPosUlt] := priceSupplier( aColPro[ oBrwPro:nAt ][ nPosPrd ], aColPro[oBrwPro:At()][nPosFor], aColPro[oBrwPro:At()][nPosLoj] )
			aColPro[obrwPro:nAt][nPosNeg] := aColPro[oBrwPro:nAt][nPosUlt]
			// Ajusta também o vetor de backup para que, em caso de restauração, a informação esteja atualizada
			aFullPro[ aScan( aFullPro, {|x| x[nPosPrd] == aColPro[ oBrwPro:nAt ][ nPosPrd ] } ) ] := aClone( aColPro[ oBrwPro:nAt ] )
			// Se o produto já estiver no carrinho de compras, ajusta o valor também no carrinho
			if aScan( aCarCom, {|x| AllTrim( x[carPos('C7_PRODUTO')] ) == AllTrim( aColPro[ oBrwPro:nAt ][ nPosPrd ] ) } ) > 0
				aCarCom[ aScan( aCarCom, {|x| AllTrim( x[carPos('C7_PRODUTO')] ) == AllTrim( aColPro[ oBrwPro:nAt ][ nPosPrd ] ) } ) ][ carPos('PRECO') ] := aColPro[obrwPro:nAt][nPosNeg]
				aCarCom[ aScan( aCarCom, {|x| AllTrim( x[carPos('C7_PRODUTO')] ) == AllTrim( aColPro[ oBrwPro:nAt ][ nPosPrd ] ) } ) ][ carPos('TOTAL') ] := aColPro[oBrwPro:At()][nPosNec] * aColPro[oBrwPro:nAt][nPosNeg]
			endif
			for nX := 1 to len( _aFil )
				nAux := aScan(_aProdFil,{|x| x[3] == aColPro[ oBrwPro:nAt ][ nPosPrd ] .and. x[25] == _aFil[nX] .and. x[23] == aColPro[ oBrwPro:nAt ][ nPosFor ] .and. x[24] == aColPro[ oBrwPro:nAt ][ nPosLoj ] })
				_aProdFil[ nAux ][8] := aColPro[oBrwPro:At()][nPosNeg]
				_aProdFil[ nAux ][9] := aColPro[oBrwPro:At()][nPosUlt]
			next nX

			for nX := 1 to len( _aFil )
				nAux := aScan(_aProdFil,{|x| x[3] == aColPro[ oBrwPro:nAt ][ nPosPrd ] .and. x[25] == _aFil[nX] })
				if aScan( aCarFil, {|x| x[carPos('C7_PRODUTO')] == aColPro[ oBrwPro:nAt ][ nPosPrd ] .and. x[len(x)] == _aFil[nX] } ) > 0
					aCarFil[ aScan( aCarFil, {|x| x[carPos('C7_PRODUTO')] == aColPro[ oBrwPro:nAt ][ nPosPrd ] .and. x[len(x)] == _aFil[nX] } ) ][carPos('PRECO')] := _aProdFil[nAux][8]
					aCarFil[ aScan( aCarFil, {|x| x[carPos('C7_PRODUTO')] == aColPro[ oBrwPro:nAt ][ nPosPrd ] .and. x[len(x)] == _aFil[nX] } ) ][carPos('TOTAL')] := ;
						aCarFil[ aScan( aCarFil, {|x| x[carPos('C7_PRODUTO')] == aColPro[oBrwPro:nAt][nPosPrd] .and. x[len(x)] == _aFil[nX] } ) ][carPos('PRECO')] * _aProdFil[nAux][carPos('TOTAL')]
				endif
			next nX
		
		endif

		DBSelectArea( "FORTMP" )
		FORTMP->( DBSetOrder( 2 ) )		// Fornecedor e Loja
		if ! FORTMP->( DBSeek( aColPro[oBrwPro:At()][nPosFor] + aColPro[oBrwPro:At()][nPosLoj] ) )
			
			RecLock( 'FORTMP', .T. )
			FORTMP->MARK        := cMarca
			FORTMP->A2_COD      := aColPro[oBrwPro:At()][nPosFor]
			FORTMP->A2_LOJA     := aColPro[oBrwPro:At()][nPosLoj]
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
			FORTMP->PEDIDO := iif( aScan( aCarCom, {|x| x[carPos('C7_FORNECE')]+x[carPos('C7_LOJA')] == FORTMP->A2_COD + FORTMP->A2_LOJA } ) > 0, 'S', 'N' )
			FORTMP->( MsUnlock() )
			oBrwFor:UpdateBrowse()
		endif

		oBrwPro:UpdateBrowse()
	endif

return xRet

/*/{Protheus.doc} querySupplyers
Função para montar query para leitura dos fornecedores x produto
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 3/20/2025
@return character, cQuery
/*/
static function querySupplyers()
	
	local cQuery := "" as character

	cQuery := "SELECT A5_FORNECE, A5_LOJA, A2.A2_NOME, A5_CODPRF, 0 D1_VUNIT, 0 LDTIMEC, "
	if SA2->( FieldPos( 'A2_X_LTIME' ) ) > 0
		cQuery += " A2_X_LTIME LDTIMEI "
	else
		cQuery += "0 AS A2_X_LTIME LDTIMEI "
	endif
	cQuery += "FROM "+ RetSqlName( 'SA5' ) +" A5 "
	
	cQuery += "INNER JOIN "+ RetSqlName( 'SA2' ) +" A2 "
	cQuery += " ON A2.A2_FILIAL  = '"+ FWxFilial( 'SA2' ) +"' "
	cQuery += "AND A2.A2_COD     = A5.A5_FORNECE "
	cQuery += "AND A2.A2_LOJA    = A5.A5_LOJA "
	cQuery += "AND A2.A2_MSBLQL  <> '1' "		// Desconsidera fornecedores inativos
	cQuery += "AND A2.D_E_L_E_T_ = ' ' "

	cQuery += "WHERE A5.A5_FILIAL = '"+ FWxFilial( 'SA5' ) +"' "
	cQuery += "  AND A5.A5_PRODUTO = '"+ aColPro[oBrwPro:At()][nPosPrd] +"' "
	cQuery += "  AND A5.D_E_L_E_T_ = ' ' "

return cQuery

/*/{Protheus.doc} doAliSol
Função para criar alias temporário de armazenamento de solicitações por produto
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 5/6/2025
@return object, oAliSol
/*/
static function doAliSol()
	
	local oAliSol as object
	local aStrSol := {} as array
	local nX      := {} as array
	local cType   := "" as character
	
	aStrSol := {}
	aAdd( aStrSol, { 'C1_FILIAL' , 'C', TAMSX3('C1_FILIAL' )[1], TAMSX3('C1_FILIAL' )[2] } )
	aAdd( aStrSol, { 'C1_ITEM'   , 'C', TAMSX3('C1_ITEM'   )[1], TAMSX3('C1_ITEM'   )[2] } )
	aAdd( aStrSol, { 'C1_NUM'    , 'C', TAMSX3('C1_NUM'    )[1], TAMSX3('C1_NUM'    )[2] } )
	aAdd( aStrSol, { 'C1_PRODUTO', 'C', TAMSX3('C1_PRODUTO')[1], TAMSX3('C1_PRODUTO')[2] } )
	aAdd( aStrSol, { 'COMPRAR'   , 'N', TAMSX3('C1_QUANT'  )[1], TAMSX3('C1_QUANT'  )[2] } )
	aAdd( aStrSol, { 'C1_QUANT'  , 'N', TAMSX3('C1_QUANT'  )[1], TAMSX3('C1_QUANT'  )[2] } )
	aAdd( aStrSol, { 'C1_EMISSAO', 'D', TAMSX3('C1_EMISSAO')[1], TAMSX3('C1_EMISSAO')[2] } )
	aAdd( aStrSol, { 'C1_SOLICIT', 'C', TAMSX3('C1_SOLICIT')[1], TAMSX3('C1_SOLICIT')[2] } )
	aAdd( aStrSol, { 'C1_CODCOMP', 'C', TAMSX3('C1_CODCOMP')[1], TAMSX3('C1_CODCOMP')[2] } )

	oAliSol := FWTemporaryTable():New( 'SOLTMP', aStrSol )
	oAliSol:AddIndex( '01', { 'C1_FILIAL', 'C1_NUM' } )
	oAliSol:Create()

	// Variável private na função principal
	aHeaSol := {}
	for nX := 1 to len( aStrSol )
		if SC1->(FieldPos(aStrSol[nX][1])) > 0
			cType := GetSX3Cache( aStrSol[nX][1], 'X3_TIPO' )
			aAdd( aHeaSol, FWBrwColumn():New() )
			aHeaSol[len(aHeaSol)]:SetTitle( GetSX3Cache( aStrSol[nX][1], 'X3_TITULO' ) )
			aHeaSol[len(aHeaSol)]:SetType( cType )
			aHeaSol[len(aHeaSol)]:SetSize( GetSX3Cache( aStrSol[nX][1], 'X3_TAMANHO' ) * 0.6 )
			aHeaSol[len(aHeaSol)]:SetPicture( GetSX3Cache( aStrSol[nX][1], 'X3_PICTURE' ) )
			aHeaSol[len(aHeaSol)]:SetAlign( iif( cType $ "C|M", 1, iif( cType == 'N', 2, 0 ) ) )
			aHeaSol[len(aHeaSol)]:SetData( &('{|| '+ aStrSol[nX][1] +' }') )	
			aHeaSol[len(aHeaSol)]:SetID( aStrSol[nX][1] )
		elseif AllTrim(aStrSol[nX][1]) == 'COMPRAR'
			cType := GetSX3Cache( 'C1_QUANT', 'X3_TIPO' )
			aAdd( aHeaSol, FWBrwColumn():New() )
			aHeaSol[len(aHeaSol)]:SetTitle( GetSX3Cache( 'C1_QUANT', 'X3_TITULO' ) )
			aHeaSol[len(aHeaSol)]:SetType( cType )
			aHeaSol[len(aHeaSol)]:SetSize( GetSX3Cache( 'C1_QUANT', 'X3_TAMANHO' ) * 0.6 )
			aHeaSol[len(aHeaSol)]:SetPicture( GetSX3Cache( 'C1_QUANT', 'X3_PICTURE' ) )
			aHeaSol[len(aHeaSol)]:SetAlign( iif( cType $ "C|M", 1, iif( cType == 'N', 2, 0 ) ) )
			aHeaSol[len(aHeaSol)]:SetData( &('{|| '+ aStrSol[nX][1] +' }') )
			aHeaSol[len(aHeaSol)]:SetReadVar( 'SOLTMP->'+ aStrSol[nX][1] )
			aHeaSol[len(aHeaSol)]:SetID( aStrSol[nX][1] )
		endif
	next nX

return oAliSol

/*/{Protheus.doc} headerSD1
Retorna cabeçalho dos campos da tabela SD1 conforme dicionário de dados
@type function
@version 12.1.2410
@author Jean Carlos Pandolfo Saggin
@since 7/16/2025
@return array, aHeader
/*/
static function headerSD1()

	local aHeader    := {} as array
	local aSD1Struct := SD1->( DBStruct() )
	local nX         := 0 as numeric

	for nX := 1 to len( aSD1Struct )
		If X3USO( GetSX3Cache( aSD1Struct[nX][1], "X3_USADO") )
			aadd(aHeader,{ GetSX3Cache(aSD1Struct[nX][1], 'X3_TITULO'),;
							aSD1Struct[nX][1],;
							GetSX3Cache( aSD1Struct[nX][1], "X3_PICTURE" ),;
							GetSX3Cache( aSD1Struct[nX][1], "X3_TAMANHO" ),;
							GetSX3Cache( aSD1Struct[nX][1], "X3_DECIMAL" ),;
							GetSX3Cache( aSD1Struct[nX][1], "X3_VALID" ),;
							GetSX3Cache( aSD1Struct[nX][1], "X3_USADO" ),;
							GetSX3Cache( aSD1Struct[nX][1], "X3_TIPO" ),;
							GetSX3Cache( aSD1Struct[nX][1], "X3_F3" ),;
							GetSX3Cache( aSD1Struct[nX][1], "X3_CONTEXT" ) })
		EndIf
	next nX

return aHeader

/*/{Protheus.doc} getCols
Função para ler e armazenar no aCols, os dados do documento que está sendo analisado no processo de formação de preços
@type function
@version 12.1.2410
@author Jean Carlos Pandolfo Saggin
@since 7/16/2025
@param cDoc, character, Documento
@param cSerie, character, Série
@param cFornece, character, Fornecedor
@param cLoja, character, Loja
@param cTipo, character, Tipo
@return array, aCols
/*/
static function getCols( cFil, cDoc, cSerie, cFornece, cLoja, cTipo )
	
	local aCols := {} as array
	local nX    := 0 as numeric
	local aLine := {} as array

	DBSelectArea( 'SD1' )
	SD1->( DBSetOrder( 1 ) )
	If DBSeek( cFil + cDoc + cSerie + cFornece + cLoja )
		while ! SD1->( EOF() ) .and. SD1->D1_FILIAL + SD1->D1_DOC + SD1->D1_SERIE + SD1->D1_FORNECE + SD1->D1_LOJA == ;
			cFil + cDoc + cSerie + cFornece + cLoja
			// Considera apenas notas do tipo recebido via parâmetro
			if SD1->D1_TIPO == cTipo
				for nX := 1 to len( aHeader )
					aAdd( aLine, SD1->( FieldGet( FieldPos( aHeader[nX][2] ) ) ) )
				next nX
				aAdd( aCols, aClone( aLine ) )
				aLine := {}
			endif
			SD1->( DBSkip() )
		end
	endif
return aCols

/*/{Protheus.doc} d1Pos
Retorna posição do campo no vetor aHeader da tabela SD1
@type function
@version 12.1.2410
@author Jean Carlos Pandolfo Saggin
@since 7/16/2025
@param cField, character, ID do campo
@return numeric, nPos
/*/
static function d1Pos( cField )
return aScan( aHeader, {|x| AllTrim( cField ) == AllTrim(x[2]) } )
