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
	Local oFndFor as object
	local oFndPrd as object
	local _cFilFor := "" as character	
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
	Local oGir001, oGir002, oGir003, oGir004, oGir005, oGir006 := Nil
	Local aHeaPro  := {}
	Local aAlter   := {"NECCOMP","QTDBLOQ","PRCNEGOC","B1_LM", "B1_QE", "B1_LE", "B1_PROC", "B1_UM", "LEADTIME", "B1_DESC" }
	Local nX       := 0
	Local oLblOrd  := Nil
	Local oCboOrd  := Nil
	Local aCboOrd  := {}
	Local oCboExi  := Nil
	Local oPanAna  := Nil
	local oAliFor  as object
	local oLayer   as object
	local oLayer1  as object
	Local oGroup1  as object
	local oWinFor  as object
	local oLblPer  as object
	local bok      := {|| Nil }
	local bCancel  := {|| oDlgCom:End() }
	local aButtons := {} as array
	local oBmpCri, oBmpAlt, oBmpMed, oBmpBai, oBmpSem, oBmpSol := nil
	local oRadMenu as object
	local aRadMenu := { "Todos os produtos", "Apenas sugestões de compra", "Apenas risco de ruptura" }
	
	Private _cFilPrd := "" as character
	Private nRadMenu := 1 as numeric
	Private cFormula := AllTrim( SuperGetMv( 'MV_X_PNC01',,"" ) )			// Formula de cálculo da necessidade de compra
	Private cZB6     := AllTrim( SuperGetMv( 'MV_X_PNC04',,"" ) )			// Alias da tabela ZB6 no ambiente do cliente
	Private cZB3     := AllTrim( SuperGetMv( 'MV_X_PNC02',,"" ) )			// Alias da tabela ZB3 no ambiente do cliente	
	Private cMarca   := GetMark()
	Private oLblDia  := Nil
	Private nGetQtd  := 0
	Private cCboAna  := '1' 
	Private cCboExi  := 'Z..A'
	Private cCboOrd  := ""
	Private oDias    := Nil
	Private aCarCom  := {}															// Dados dos produtos no carrinho de compras
	Private cMark    := GetMark()
	Private cFndFor  := Space( TAMSX3( 'A2_NOME' )[01] )
	Private lGir001  := lGir002 := lGir003 := lGir004 := lGir005 := lGir006 := .T.
	Private oDlgCom  := Nil
	Private oBrwFor  := Nil
	Private aColPro  := {}
	Private oBrwPro  := Nil
	Private aSelFor  := {}															// Fornecedores com check-box marcado
	Private nPosPrd  := 0
	Private nPosDes  := 0
	Private nPosLtM  := 0 
	Private nPosUnM  := 0 
	Private nPosChk  := 0
	Private nPosFor  := 0
	Private nPosLoj  := 0
	Private nPosLeg  := 0 
	Private nPosBlq  := 0
	Private nPosNec  := 0
	Private nPosNeg  := 0
	Private nPosUlt  := 0
	Private nPosCon  := 0 
	Private nPosDur  := 0 
	Private nPosEmE  := 0 
	Private nPosVen  := 0 
	Private nPosQtd  := 0 
	Private nPosLdT  := 0 
	Private nPosTLT  := 0 as numeric
	Private nPosPrv  := 0
	Private aConfig  := {}															// Guarda configurações da rotina para uso durante a execução
	Private nSpinBx  := 0
	Private oLblAna  := Nil
	Private oDash    := Nil
	Private aEvePen  := {}															// Vetor para guardar eventos pendentes de serem resolvidos
	Private nPosQtE  := 0 as numeric				
	Private nPosLtE  := 0 as numeric

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
			 'Acesse o módulo configurador e realize a configuraç˜ão do parâmetro MV_X_PNC02' )
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
	
	// Monta dinamicamente cabeçalho do grid de produtos
	Aadd( aHeaPro, { " "    ,"LEGENDA", "@BMP", 2, 0, ".F." ,"", "C", "", "V" ,"" , "","","V" } )
	aAdd( aHeaPro, { "Check", "MARK"  , "@BMP", 2, 0, ".F." ,"", "C", "", "V" ,"" , "","","V" } )
	aAdd( aHeaPro, { AllTrim( GetSX3Cache( 'B1_COD', 'X3_TITULO' ) ),;
					'B1_COD',;
					GetSX3Cache( 'B1_COD', 'X3_PICTURE' ),;
					GetSX3Cache( 'B1_COD', 'X3_TAMANHO' ),;
					GetSX3Cache( 'B1_COD', 'X3_DECIMAL' ),;
					GetSX3Cache( 'B1_COD', 'X3_VALID'   ),;
					GetSX3Cache( 'B1_COD', 'X3_USADO'   ),;
					GetSX3Cache( 'B1_COD', 'X3_TIPO'    ),;
					GetSX3Cache( 'B1_COD', 'X3_F3'      ),;
					GetSX3Cache( 'B1_COD', 'X3_CONTEXT' ),;
					GetSX3Cache( 'B1_COD', 'X3_CBOX'    ),;
					GetSX3Cache( 'B1_COD', 'X3_RELACAO' ) } )
	
	aAdd( aHeaPro, { AllTrim( GetSX3Cache( 'B1_DESC', 'X3_TITULO' ) ),;
					'B1_DESC',;
					GetSX3Cache( 'B1_DESC', 'X3_PICTURE' ),;
					GetSX3Cache( 'B1_DESC', 'X3_TAMANHO' ),;
					GetSX3Cache( 'B1_DESC', 'X3_DECIMAL' ),;
					GetSX3Cache( 'B1_DESC', 'X3_VALID'   ),;
					GetSX3Cache( 'B1_DESC', 'X3_USADO'   ),;
					GetSX3Cache( 'B1_DESC', 'X3_TIPO'    ),;
					GetSX3Cache( 'B1_DESC', 'X3_F3'      ),;
					GetSX3Cache( 'B1_DESC', 'X3_CONTEXT' ),;
					GetSX3Cache( 'B1_DESC', 'X3_CBOX'    ),;
					GetSX3Cache( 'B1_DESC', 'X3_RELACAO' ) } )

	aAdd( aHeaPro, { AllTrim( GetSX3Cache( 'B1_UM', 'X3_TITULO' ) ),;
					'B1_UM',;
					GetSX3Cache( 'B1_UM', 'X3_PICTURE' ),;
					GetSX3Cache( 'B1_UM', 'X3_TAMANHO' ),;
					GetSX3Cache( 'B1_UM', 'X3_DECIMAL' ),;
					GetSX3Cache( 'B1_UM', 'X3_VALID'   ),;
					GetSX3Cache( 'B1_UM', 'X3_USADO'   ),;
					GetSX3Cache( 'B1_UM', 'X3_TIPO'    ),;
					GetSX3Cache( 'B1_UM', 'X3_F3'      ),;
					GetSX3Cache( 'B1_UM', 'X3_CONTEXT' ),;
					GetSX3Cache( 'B1_UM', 'X3_CBOX'    ),;
					GetSX3Cache( 'B1_UM', 'X3_RELACAO' ) } )
	
	aAdd( aHeaPro, { "Nec.Com", "NECCOMP" , "@E 999,999"   ,  7, 0,       ,  , "N",   , "V" ,   ,  } )
	aAdd( aHeaPro, { "Ped.Blq", "QTDBLOQ" , "@E 999,999"   ,  7, 0,       ,  , "N",   , "V" ,   ,  } )
	aAdd( aHeaPro, { "Prc.Neg", "PRCNEGOC", "@E 999,999.99", 11, 2,       ,  , "N",   , "V" ,   ,  } )
	aAdd( aHeaPro, { "Ult.Prc", "ULTPRECO", "@E 999,999.99", 11, 2,       ,  , "N",   , "V" ,   ,  } )
	aAdd( aHeaPro, { "Cons.Md(D)", "CONSMED" , "@E 999.9999"  , 10, 4,       ,  , "N",   , "V" ,   ,  } )
	aAdd( aHeaPro, { "Duracao", "DURACAO" , "@E 999"       ,  3, 0,       ,  , "N",   , "V" ,   ,  } )
	aAdd( aHeaPro, { "Dur.Prv", "DURAPRV" , "@E 999"       ,  3, 0,       ,  , "N",   , "V" ,   ,  } )
	aAdd( aHeaPro, { "Em Est.", "ESTOQUE" , "@E 999,999"   ,  7, 0,       ,  , "N",   , "V" ,   ,  } )
	aAdd( aHeaPro, { "Empenho", "EMPENHO" , "@E 999,999"   ,  7, 0,       ,  , "N",   , "V" ,   ,  } ) 
	aAdd( aHeaPro, { "Qt.Comp", "QTDCOMP" , "@E 999,999"   ,  7, 0,       ,  , "N",   , "V" ,   ,  } )
	aAdd( aHeaPro, { "L-Time" , "LEADTIME", "@E 999"       ,  3, 0,       ,  , "N",   , "V" ,   ,  } )
	aAdd( aHeaPro, { "Tp.Ld.T", "TPLDTIME", "@x"           ,  1, 0,       ,  , "C",   , "V" ,"C=Calculado;F=Fornecedor;P=Produto", } )
	aAdd( aHeaPro, { "Prv.Ent", "PREVENT" , "@D"           ,  8, 0,       ,  , "D",   , "V" ,   ,  } )

	aAdd( aHeaPro, { AllTrim( GetSX3Cache( 'B1_LM', 'X3_TITULO' ) ),;
					'B1_LM',;
					GetSX3Cache( 'B1_LM', 'X3_PICTURE' ),;
					GetSX3Cache( 'B1_LM', 'X3_TAMANHO' ),;
					GetSX3Cache( 'B1_LM', 'X3_DECIMAL' ),;
					GetSX3Cache( 'B1_LM', 'X3_VALID'   ),;
					GetSX3Cache( 'B1_LM', 'X3_USADO'   ),;
					GetSX3Cache( 'B1_LM', 'X3_TIPO'    ),;
					GetSX3Cache( 'B1_LM', 'X3_F3'      ),;
					GetSX3Cache( 'B1_LM', 'X3_CONTEXT' ),;
					GetSX3Cache( 'B1_LM', 'X3_CBOX'    ),;
					GetSX3Cache( 'B1_LM', 'X3_RELACAO' ) } )
	
	aAdd( aHeaPro, { AllTrim( GetSX3Cache( 'B1_QE', 'X3_TITULO' ) ),;
					'B1_QE',;
					GetSX3Cache( 'B1_QE', 'X3_PICTURE' ),;
					GetSX3Cache( 'B1_QE', 'X3_TAMANHO' ),;
					GetSX3Cache( 'B1_QE', 'X3_DECIMAL' ),;
					GetSX3Cache( 'B1_QE', 'X3_VALID'   ),;
					GetSX3Cache( 'B1_QE', 'X3_USADO'   ),;
					GetSX3Cache( 'B1_QE', 'X3_TIPO'    ),;
					GetSX3Cache( 'B1_QE', 'X3_F3'      ),;
					GetSX3Cache( 'B1_QE', 'X3_CONTEXT' ),;
					GetSX3Cache( 'B1_QE', 'X3_CBOX'    ),;
					GetSX3Cache( 'B1_QE', 'X3_RELACAO' ) } )

	aAdd( aHeaPro, { AllTrim( GetSX3Cache( 'B1_LE', 'X3_TITULO' ) ),;
					'B1_LE',;
					GetSX3Cache( 'B1_LE', 'X3_PICTURE' ),;
					GetSX3Cache( 'B1_LE', 'X3_TAMANHO' ),;
					GetSX3Cache( 'B1_LE', 'X3_DECIMAL' ),;
					GetSX3Cache( 'B1_LE', 'X3_VALID'   ),;
					GetSX3Cache( 'B1_LE', 'X3_USADO'   ),;
					GetSX3Cache( 'B1_LE', 'X3_TIPO'    ),;
					GetSX3Cache( 'B1_LE', 'X3_F3'      ),;
					GetSX3Cache( 'B1_LE', 'X3_CONTEXT' ),;
					GetSX3Cache( 'B1_LE', 'X3_CBOX'    ),;
					GetSX3Cache( 'B1_LE', 'X3_RELACAO' ) } )

	aAdd( aHeaPro, { AllTrim( GetSX3Cache( 'B1_PROC', 'X3_TITULO' ) ),;
					'B1_PROC',; 
					GetSX3Cache( 'B1_PROC', 'X3_PICTURE' ),;
					GetSX3Cache( 'B1_PROC', 'X3_TAMANHO' ),;
					GetSX3Cache( 'B1_PROC', 'X3_DECIMAL' ),;
					Nil,;
					GetSX3Cache( 'B1_PROC', 'X3_USADO'   ),;
					GetSX3Cache( 'B1_PROC', 'X3_TIPO'    ),;
					GetSX3Cache( 'B1_PROC', 'X3_F3'      ),;
					GetSX3Cache( 'B1_PROC', 'X3_CONTEXT' ),;
					GetSX3Cache( 'B1_PROC', 'X3_CBOX'    ),;
					GetSX3Cache( 'B1_PROC', 'X3_RELACAO' ) } )

	aAdd( aHeaPro, { AllTrim( GetSX3Cache( 'B1_LOJPROC', 'X3_TITULO' ) ),;
					'B1_LOJPROC',;
					GetSX3Cache( 'B1_LOJPROC', 'X3_PICTURE' ),;
					GetSX3Cache( 'B1_LOJPROC', 'X3_TAMANHO' ),;
					GetSX3Cache( 'B1_LOJPROC', 'X3_DECIMAL' ),;
					Nil,;
					GetSX3Cache( 'B1_LOJPROC', 'X3_USADO'   ),;
					GetSX3Cache( 'B1_LOJPROC', 'X3_TIPO'    ),;
					GetSX3Cache( 'B1_LOJPROC', 'X3_F3'      ),;
					GetSX3Cache( 'B1_LOJPROC', 'X3_CONTEXT' ),;
					GetSX3Cache( 'B1_LOJPROC', 'X3_CBOX'    ),;
					GetSX3Cache( 'B1_LOJPROC', 'X3_RELACAO' ) } )								
	
	// Guarda o posicionamento dos campos para posteriormente utilizá-los ao longo do fonte
	nPosLeg := aScan( aHeaPro, {|x| AllTrim( x[2] ) == "LEGENDA"    } )
	nPosPrd := aScan( aHeaPro, {|x| AllTrim( x[2] ) == "B1_COD"     } ) 
	nPosDes := aScan( aHeaPro, {|x| AllTrim( x[2] ) == "B1_DESC"    } )
	nPosUnM := aScan( aHeaPro, {|x| AllTrim( x[2] ) == "B1_UM"      } )
	nPosChk := aScan( aHeaPro, {|x| AllTrim( x[2] ) == "MARK"       } )
	nPosLtM := aScan( aHeaPro, {|x| AllTrim( x[2] ) == "B1_LM"      } )
	nPosFor := aScan( aHeaPro, {|x| AllTrim( x[2] ) == "B1_PROC"    } )
	nPosLoj := aScan( aHeaPro, {|x| AllTrim( x[2] ) == "B1_LOJPROC" } )
	nPosNec := aScan( aHeaPro, {|x| AllTrim( x[2] ) == "NECCOMP"    } )
	nPosNeg := aScan( aHeaPro, {|x| AllTrim( x[2] ) == "PRCNEGOC"   } )
	nPosUlt := aScan( aHeaPro, {|x| AllTrim( x[2] ) == "ULTPRECO"   } )
	nPosCon := aScan( aHeaPro, {|x| AllTrim( x[2] ) == "CONSMED"    } )
	nPosDur := aScan( aHeaPro, {|x| AllTrim( x[2] ) == "DURACAO"    } )
	nPosDuP := aScan( aHeaPro, {|x| AllTrim( x[2] ) == "DURAPRV"    } )
	nPosEmE := aScan( aHeaPro, {|x| AllTrim( x[2] ) == "ESTOQUE"    } )
	nPosVen := aScan( aHeaPro, {|x| AllTrim( x[2] ) == "EMPENHO"    } ) 
	nPosQtd := aScan( aHeaPro, {|x| AllTrim( x[2] ) == "QTDCOMP"    } )
	nPosPrv := aScan( aHeaPro, {|x| AllTrim( x[2] ) == "PREVENT"    } )
	nPosLdT := aScan( aHeaPro, {|x| AllTrim( x[2] ) == "LEADTIME"   } )
	nPosTLT := aScan( aHeaPro, {|x| AllTrim( x[2] ) == "TPLDTIME"   } )		// Tipo do Lead-Time (C=Calculado P=Produto ou F=Fornecedor)
	nPosBlq := aScan( aHeaPro, {|x| AllTrim( x[2] ) == "QTDBLOQ"    } )
	nPosQtE := aScan( aHeaPro, {|x| AllTrim( x[2] ) == "B1_QE"      } )
	nPosLtE := aScan( aHeaPro, {|x| AllTrim( x[2] ) == "B1_LE"      } )
	
	// Ordena por padrão pela necessidade de compra
	aCboOrd := {}
	For nX := 1 to Len( aHeaPro )
		If !Empty( aHeaPro[nX][01] )
			aAdd( aCboOrd, AllTrim( cValToChar( nX ) ) +'='+ AllTrim( aHeaPro[nX][01] ) )
		EndIf
	Next nX
	cCboOrd := AllTrim( cValToChar( nPosNec ) )
	
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
	lGir006 := aConfig[07]			// Pré-definições itens sob demanda
	cCboAna := aConfig[08]			// Pré-definições tipo de análise de sazonalidade
	nGetQtd := aConfig[09]			// Pré-definições da qtde de períodos analisados

	// Botões da EnchoiceBar
	aAdd( aButtons, { "BTNWARN"  , {|| fShowEv() }           , "Riscos de Ruptura" } )
	aAdd( aButtons, { "BMPMANUT" , {|| doFormul( cFormula ) }, "Formula de Cálculo" } )
	aAdd( aButtons, { "BTNLEG"   , {|| fLegenda() }          , "Legenda de Produtos" } )
	aAdd( aButtons, { "BTNNOTIFY", {|| fShowEv( oBrwPro:aCols[ oBrwPro:nAt][nPosPrd] ) }, "Eventos do Produto" } )
	aAdd( aButtons, { "BTNEMPEN" , {|| fShowEm( oBrwPro:aCols[ oBrwPro:nAt][nPosPrd] ) }, "Empenhos do Produto" } )
	aAdd( aButtons, { "BTNAPROV" , {|| fFunApr() }           , "Rotina de Aprovação" } )
	aAdd( aButtons, { "BTNPEDFOR", {|| fPedFor( 1 ) }        , "Pedidos do Produto com o Fornecedor Padrão" } )
	aAdd( aButtons, { "BTNPEDIDO", {|| fPedFor( 2 ) }        , "Pedidos do Produto" } )
	aAdd( aButtons, { "BTNIMPORT", {|| impData() }           , "Importar Indices dos Produtos" } )
	aAdd( aButtons, { "BTNENTR"  , {|| entryDocs( oBrwPro:aCols[ oBrwPro:nAt ][nPosPrd] ) }		 , "Compras do Produto" } )

	DEFINE MSDIALOG oDlgCom TITLE AllTrim( SM0->M0_FILIAL ) +" | Painel de Compra" FROM 000, 000  TO aSize[06], aSize[05] COLORS 0, 16777215 PIXEL
	
	// Group para separar a tela em duas partes na vertical
	@ 030, 000 GROUP oGroup1 TO nVer*NPERCSUP, nHor OF oDlgCom COLOR 0, 16777215 PIXEL
	@ nVer*NPERCSUP, 000 GROUP oGrpPro TO nVer, nHor OF oDlgCom COLOR 0, 16777215 PIXEL

	oLayer := FWLayer():New()
	oLayer:Init( oGroup1 )
	oLayer:AddColumn( "colFor" , 40, .T. )
	oLayer:AddColumn( "colPar" , 30, .T. )
	oLayer:AddColumn( "colDash", 30, .T. )
	oLayer:AddWindow( 'colFor' , 'winFor' , 'Fornecedores', 100, .F., .F., {|| Nil })
	oLayer:AddWindow( 'colPar' , 'winPar' , 'Filtros e Parâmetros', 100, .F., .F., {|| Nil })
	oLayer:AddWindow( 'colDash', 'winDash', 'Gráfico do Produto', 100, .F., .F., {|| Nil })
	oWinFor  := oLayer:GetWinPanel( 'colFor' , 'winFor')
	oWinPar  := oLayer:GetWinPanel( 'colPar' , 'winPar')
	oWinDash := oLayer:GetWinPanel( 'colDash', 'winDash')

	oLayer1 := FWLayer():New()
	oLayer1:Init( oGrpPro )
	oLayer1:AddColumn( "colPro", 100, .T. )
	oLayer1:AddWindow( 'colPro' , 'winPro' , 'Produtos', 100, .F., .F., {|| Nil })
	oWinPro  := oLayer1:GetWinPanel( 'colPro' , 'winPro')

	oFndFor := TButton():New( (oWinFor:nTop)+1, (oWinFor:nRight/2)-34, "Filtrar",oDlgCom,{|| _cFilFor := lookData( _cFilFor ),;
																							oBrwFor:SetFilterDefault( doFilter( _cFilFor, 'A2_NOME' )),;
																							oBrwFor:Refresh(.T.),;
																							oBrwFor:UpdateBrowse() }, 30,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	oFndFor:SetCSS( CBTNSTYLE ) 

	oBrwFor := FWBrowse():New( oWinFor )
	oBrwFor:SetDataTable()
	oBrwFor:SetAlias( 'FORTMP' )
	oBrwFor:DisableReport()
	oBrwFor:AddMarkColumns( {|oBrwFor| if( FORTMP->MARK == cMarca, 'LBOK','LBNO' ) },;
							{|oBrwFor| fMark( 'FORTMP' /* cAlias */, .F. /*lAll*/, oBrwFor, _cFilFor ) },;
							{|oBrwFor| fMark( 'FORTMP' /* cAlias */, .T. /*lAll*/, oBrwFor, _cFilFor ) })
	oBrwFor:GetColumn(1):SetReadVar( 'FORTMP->MARK' )
	oBrwFor:SetDoubleClick( {|oBrwFor| fMark( 'FORTMP' /* cAlias */, .F. /*lAll*/, oBrwFor, _cFilFor ) } )
	aEval( aCabFor, {|x| oBrwFor:AddColumn( aClone( x ) ) } )
	oBrwFor:GetColumn(2):bLDblClick := {|oBrwFor| fMark( 'FORTMP'/* cAlias */, .F., oBrwFor, _cFilFor ) }
	oBrwFor:GetColumn(3):bLDblClick := {|oBrwFor| fMark( 'FORTMP'/* cAlias */, .F., oBrwFor, _cFilFor ) }
	oBrwFor:SetEditCell( .T. )
	oBrwFor:DisableConfig()
	oBrwFor:SetLineHeight( 15 )
	oBrwFor:Activate()

	oBrwPro := MsNewGetDados():New( NESP, NESP, nHor-NESP, nVer-NESP, GD_UPDATE, "AllwaysTrue", "AllwaysTrue",, aAlter,, Len( aColPro ), "U_PCOMVLD()", "", "AllwaysTrue", oWinPro, aHeaPro, aColPro)
	oBrwPro:bChange := {|| Processa( {|| fLoadAna() }, 'Aguarde!','Analisando sazonalidade do produto...' ) }
	oBrwPro:oBrowse:bLDblClick := {|| iif( oBrwPro:oBrowse:nColPos == nPosChk, fMarkPro(), oBrwPro:EditCell() ) }
	oBrwPro:oBrowse:align := CONTROL_ALIGN_ALLCLIENT
	
	@ 12, 10 SAY oLblPrj PROMPT "Projeção de estoque para..." SIZE 080, 011 OF oWinPar FONT oFntTxt COLORS 8421504, 16777215 PIXEL
	oDias := tSpinBox():new( 10, 90, oWinPar, {|x| nSpinBx := x, Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' ) }, 28, 13)
    oDias:setRange( 10, 120)
    oDias:setStep( 10 )
    oDias:setValue( nSpinBx )
	@ 12, 120 SAY oLblDia PROMPT "dias ( até "+ fRetDia( nSpinBx, .T. ) +" )" SIZE 080, 011 OF oWinPar FONT oFntTxt COLORS 8421504, 16777215 PIXEL
	
	oBmpCri := TBitmap():New(030, 010, 10, 10, LG_CRITICO /*cResName*/, /*cBmpFile*/, .T./*lNoBorder*/, oWinPar, /*bLClicked*/, /*bRClicked*/, /*lScroll*/, /*lStretch*/, /*oCursor*/, /*uParam14*/, /*uParam15*/, /*bWhen*/, .T./* lDimPixels */, /*bValid*/)
	oBmpAlt := TBitmap():New(040, 010, 10, 10, LG_ALTO    /*cResName*/, /*cBmpFile*/, .T./*lNoBorder*/, oWinPar, /*bLClicked*/, /*bRClicked*/, /*lScroll*/, /*lStretch*/, /*oCursor*/, /*uParam14*/, /*uParam15*/, /*bWhen*/, .T./* lDimPixels */, /*bValid*/)
	oBmpMed := TBitmap():New(050, 010, 10, 10, LG_MEDIO   /*cResName*/, /*cBmpFile*/, .T./*lNoBorder*/, oWinPar, /*bLClicked*/, /*bRClicked*/, /*lScroll*/, /*lStretch*/, /*oCursor*/, /*uParam14*/, /*uParam15*/, /*bWhen*/, .T./* lDimPixels */, /*bValid*/)
	oBmpBai := TBitmap():New(060, 010, 10, 10, LG_BAIXO   /*cResName*/, /*cBmpFile*/, .T./*lNoBorder*/, oWinPar, /*bLClicked*/, /*bRClicked*/, /*lScroll*/, /*lStretch*/, /*oCursor*/, /*uParam14*/, /*uParam15*/, /*bWhen*/, .T./* lDimPixels */, /*bValid*/)
	oBmpSem := TBitmap():New(070, 010, 10, 10, LG_SEMGIRO /*cResName*/, /*cBmpFile*/, .T./*lNoBorder*/, oWinPar, /*bLClicked*/, /*bRClicked*/, /*lScroll*/, /*lStretch*/, /*oCursor*/, /*uParam14*/, /*uParam15*/, /*bWhen*/, .T./* lDimPixels */, /*bValid*/)
	oBmpSol := TBitmap():New(080, 010, 10, 10, LG_SOLICIT /*cResName*/, /*cBmpFile*/, .T./*lNoBorder*/, oWinPar, /*bLClicked*/, /*bRClicked*/, /*lScroll*/, /*lStretch*/, /*oCursor*/, /*uParam14*/, /*uParam15*/, /*bWhen*/, .T./* lDimPixels */, /*bValid*/)

	@ 30, 20 CHECKBOX oGir001 VAR lGir001 PROMPT "Críticos"     		SIZE 048, 008 OF oWinPar COLORS 8421504, 16777215 FONT oFntCbo ON CHANGE Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' ) PIXEL
	@ 40, 20 CHECKBOX oGir002 VAR lGir002 PROMPT "Alto Giro"    		SIZE 048, 008 OF oWinPar COLORS 8421504, 16777215 FONT oFntCbo ON CHANGE Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' ) PIXEL
	@ 50, 20 CHECKBOX oGir003 VAR lGir003 PROMPT "Médio Giro"   		SIZE 048, 008 OF oWinPar COLORS 8421504, 16777215 FONT oFntCbo ON CHANGE Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' ) PIXEL
	@ 60, 20 CHECKBOX oGir004 VAR lGir004 PROMPT "Baixo Giro"   		SIZE 048, 008 OF oWinPar COLORS 8421504, 16777215 FONT oFntCbo ON CHANGE Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' ) PIXEL
	@ 70, 20 CHECKBOX oGir005 VAR lGir005 PROMPT "Sem Giro"     		SIZE 048, 008 OF oWinPar COLORS 8421504, 16777215 FONT oFntCbo ON CHANGE Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' ) PIXEL
	@ 80, 20 CHECKBOX oGir006 VAR lGir006 PROMPT "Por Solicitação"  	SIZE 048, 008 OF oWinPar COLORS 8421504, 16777215 FONT oFntCbo ON CHANGE Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' ) PIXEL
	
	oRadMenu := TRadMenu():New( 30, 70, aRadMenu,, oWinPar,,,,,,,,100,12,,,,.T.)
	oRadMenu:bSetGet := {|u| iif( pCount()==0, nRadMenu, nRadMenu := u ) }
	oRadMenu:bChange := {|| Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' ) }

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
	
	// Botão de filtro de produto
	oFndPrd := TButton():New( (oWinPro:nTop)+1+125, (oWinFor:nRight/2)-34, "Filtrar",oDlgCom,{|| _cFilPrd := lookData( _cFilPrd ),;
																							Processa( {|| fLoadInf() }, 'Aguarde!','Executando filtro de produtos...' ) }, 30,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	oFndPrd:SetCSS( CBTNSTYLE ) 
	@ (oWinPro:nTop)+2+125, (oWinFor:nRight/2) SAY oLblOrd PROMPT "Ordenar por..." SIZE 040, 011 OF oDlgCom FONT oFntTxt COLORS 8421504, 16777215 PIXEL
	@ (oWinPro:nTop)+1+125, (oWinFor:nRight/2)+44 MSCOMBOBOX oCboOrd VAR cCboOrd ITEMS aCboOrd SIZE 60, 012 OF oDlgCom COLORS 8421504, 16777215 FONT oFntCbo ON CHANGE fSortGrd() PIXEL
	@ (oWinPro:nTop)+1+125, (oWinFor:nRight/2)+108 MSCOMBOBOX oCboExi VAR cCboExi ITEMS { 'A..Z', 'Z..A' } SIZE 28, 012 OF oDlgCom COLORS 8421504, 16777215 FONT oFntCbo ON CHANGE fSortGrd() PIXEL
	
	ACTIVATE MSDIALOG oDlgCom CENTERED ON INIT Eval({|| EnchoiceBar( oDlgCom, bOk, bCancel,,aButtons ),; 
														Processa( {|| fLoadFor() }, 'Aguarde!','Identificando fornecedores...' ),;
														oBrwFor:SetFocus(),; 
														Processa({|| fEvents() }, 'Aguarde!','Identificando alertas de ruptura...') }) 
	oAliFor:Delete()
	
Return ( Nil )

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
	local oGetBFr  as object
	local oValBFr  as object
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

	// Dados do produto
	Private cGetCod := cProduto
	Private cGetDes := RetField( 'SB1', 1, FWxFilial( 'SB1' ) + cProduto, 'B1_DESC' )
	Private cGetUM  := RetField( 'SB1', 1, FWxFilial( 'SB1' ) + cProduto, 'B1_UM' )
	Private nGetUOC := lastOC( cProduto )
	Private cGetNCM := RetField( 'SB1', 1, FWxFilial( 'SB1' ) + cProduto, 'B1_POSIPI' )
	Private cGetTab := Space( TAMSX3('DA1_CODTAB')[1] ) as character
	Private nGetUNF := 0

	// Entrada
	Private cGetTES := Space( TAMSX3('D1_TES')[1] ) as character
	Private cGetDTE := Space( TAMSX3('F4_TEXTO')[1] ) as character
	Private nGetICM := 0 
	Private nValICM := 0
	Private nGetIPI := 0
	Private nValIPI := 0
	Private nGetFre := 0
	Private nValFre := 0
	private nGetBFr := 100
	Private nValBFr := 0
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
	Private nGetLuc := 0			// Lucro pretendido
	Private nGetPCV := 0 			// PIS/COFINS Venda
	Private nGetICV := 0 			// ICMS Venda
	Private nGetOpe := 0			// Despesas Operacionais Venda
	Private nGetCSL := 0			// CSLL
	Private nGetIRP := 0			// IRPJ
	Private nGetIna := 0			// Índice Inadimplência
	Private nGetTCV := 0			// Total Custo Variável
	Private nGetFiV := 0			// Custo Financeiro (custo cartão, desconto à vista...)
	Private nGetPSL := 0			// Preço sem lucro
	Private nGetSug := 0			// Sugestão Preço de Venda
	Private nGetMg1 := 0 			// Margem sobre o preço sugerido
	Private nGetPrc := 0			// Preço de Venda Atual
	private nGetMg2 := 0			// Margem sobre o preço vigente

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
	cQuery += " ON A2.A2_FILIAL  = '"+ FWxFilial( 'SA2' ) +"' "
	cQuery += "AND A2.A2_COD     = D1.D1_FORNECE "
	cQuery += "AND A2.A2_LOJA    = D1.D1_LOJA "
	cQuery += "AND A2.D_E_L_E_T_ = ' ' "

	cQuery += "WHERE D1.D1_FILIAL  = '"+ FWxFilial( 'SD1' ) +"' "
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
	oBrowse:bChange := {|| someChange( .T. /* lReset */) }
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
	oGetUOC   := doGet( nLine, 008, {|u| if( pCount()>0,nGetUOC:=u,nGetUOC ) }, oPanFld, 70, 10, "@E 9,999,999.99", 'nGetUOC', 'Prc.Compra', !lEnable )
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
	oGetICM   := doGet( nLine, 008, {|u| if( PCount()>0,nGetICM:=u,nGetICM ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetICM', 'ICMS', !lEnable )
	oValICM   := doGet( nLine, 095, {|u| if( PCOunt()>0,nValICM:=u,nValICM ) }, oPanFld, 50, 10, "@E 9,999,999.99", 'nValICM',, !lEnable )
	nLine += 14
	oGetIPI   := doGet( nLine, 008, {|u| if( pCOunt()>0,nGetIPI:=u,nGetIPI ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetIPI', 'IPI', !lEnable )
	oValIPI   := doGet( nLine, 095, {|u| if( PCount()>0,nValIPI:=u,nValIPI ) }, oPanFld, 50, 10, "@E 9,999,999.99", 'nValIPI',, !lEnable )
	nLine += 14
	oGetFre   := doGet( nLine, 008, {|u| if( pCOunt()>0,nGetFre:=u,nGetFre ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetFre', 'Frete', !lEnable )
	oValFre   := doGet( nLine, 095, {|u| if( PCount()>0,nValFre:=u,nValFre ) }, oPanFld, 50, 10, "@E 9,999,999.99", 'nValFre',,!lEnable )
	nLine += 14
	oGetBFr   := doGet( nLine, 008, {|u| if( pCOunt()>0,nGetBFr:=u,nGetBFr ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetBFr', 'Base Frete', !lEnable )
	oValBFr   := doGet( nLine, 095, {|u| if( PCount()>0,nValBFr:=u,nValBFr ) }, oPanFld, 50, 10, "@E 9,999,999.99", 'nValBFr',,!lEnable )
	nLine += 14
	oGetICF   := doGet( nLine, 008, {|u| if( pCOunt()>0,nGetICF:=u,nGetICF ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetICF', 'ICMS Frete', !lEnable )
	oValICF   := doGet( nLine, 095, {|u| if( PCount()>0,nValICF:=u,nValICF ) }, oPanFld, 50, 10, "@E 9,999,999.99", 'nValICF',,!lEnable )
	nLine += 14
	oGetOut   := doGet( nLine, 008, {|u| if( pCOunt()>0,nGetOut:=u,nGetOut ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetOut', 'Outras Desp.',!lEnable )
	oValOut   := doGet( nLine, 095, {|u| if( PCount()>0,nValOut:=u,nValOut ) }, oPanFld, 50, 10, "@E 9,999,999.99", 'nValOut',,!lEnable )
	nLine += 14
	oGetFin   := doGet( nLine, 008, {|u| if( pCOunt()>0,nGetFin:=u,nGetFin ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetFin', 'Financeiro', !lEnable )
	oValFin   := doGet( nLine, 095, {|u| if( PCount()>0,nValFin:=u,nValFin ) }, oPanFld, 50, 10, "@E 9,999,999.99", 'nValFin',,!lEnable )
	nLine += 14
	oGetPC    := doGet( nLine, 008, {|u| if( pCOunt()>0,nGetPC :=u,nGetPC  ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetPC', 'PIS/COFINS', !lEnable )
	oValPC    := doGet( nLine, 095, {|u| if( PCount()>0,nValPC :=u,nValPC  ) }, oPanFld, 50, 10, "@E 9,999,999.99", 'nValPC',, !lEnable )
	nLine += 14
	oGetST    := doGet( nLine, 008, {|u| if( pCOunt()>0,nGetST :=u,nGetST  ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetST', 'ST', !lEnable )
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
	nLine += 14
	oGetPCV   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetPCV:=u,nGetPCV ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetPCV', 'PIS/COFINS' )
	nLine += 14
	oGetICV   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetICV:=u,nGetICV ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetICV', 'ICMS' )
	nLine += 14
	oGetOpe   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetOpe:=u,nGetOpe ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetOpe', 'Desp.Oper' )
	nLine += 14
	oGetCSL   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetCSL:=u,nGetCSL ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetCSL', 'CSLL', !lEnable )
	nLine += 14
	oGetIRP   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetIRP:=u,nGetIRP ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetIRP', 'IRPJ', !lEnable )
	nLine += 14
	oGetIna   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetIna:=u,nGetIna ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetIna', 'Inadimpl' )
	nLine += 14
	oGetTCV   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetTCV:=u,nGetTCV ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetTCV', 'Tt.Cus.Var', !lEnable )
	nLine += 14
	oGetFiV   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetFiV:=u,nGetFiV ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetFiV', 'Financeiro' )
	nLine += 14
	oGetPSL   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetPSL:=u,nGetPSL ) }, oPanFld, 50, 10, "@E 9,999,999.99", 'nGetPSL', 'Prc.s/Lucro', !lEnable )
	nLine += 14
	oGetSug   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetSug:=u,nGetSug ) }, oPanFld, 50, 10, "@E 9,999,999.99", 'nGetSug', 'Sug.Preço', !lEnable )
	oGetMg1   := doGet( nLine, nIniHor+91,{|u| if( PCount()>0,nGetMg1:=u,nGetMg1 ) }, oPanFld, 50, 10, "@E 9,999.99", 'nGetMg1',, !lEnable )
	nLine += 14
	oGetPrc   := doGet( nLine, nIniHor+4, {|u| if( PCount()>0,nGetPrc:=u,nGetPrc ) }, oPanFld, 50, 10, "@E 9,999,999.99", 'nGetPrc', 'Prc.Venda' )
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
@param cFilter, character, filtro do usuário no browse
/*/
Static Function fMark( cAlias, lAll, oBrowse, cFilter )

	local aArea  := ( cAlias )->( GetArea() )
	local lMarca := ( cAlias )->MARK != cMarca
	local cADVPL := "" as character

	default lAll := .F.
	default cFilter := ""

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

			if ! Empty( cFilter )
				cADVPL := doFilter( cFilter, 'A2_NOME' )
			endif

			// Se o registro acabou ficando de fora do filtro, força refresh geral do browse
			if ! Empty( cADVPL ) .and. ! &( cADVPL )
				oBrowse:UpdateBrowse()
			else
				oBrowse:LineRefresh()
			endif
			
		endif
		
	endif

	Processa( {|| fLoadInf() }, 'Aguarde!','Analisando dados do MRP...' )

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
		oDlgCom:Refresh()
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
	aAdd( aHeaderEx, { "Data Ev."  , cZB3 +"_DATA"  , "@D",                        08,                        00,,,"D",,"V",,} )
	aAdd( aHeaderEx, { "Produto"   , cZB3 +"_PROD"  , "@!", TAMSX3( cZB3 +'_PROD'   )[01], TAMSX3( cZB3 +'_PROD'   )[02],,,"C","SB1","V",,} )
	aAdd( aHeaderEx, { "Descricao" , "B1_DESC"      , "@!", TAMSX3('B1_DESC'    )[01], TAMSX3('B1_DESC'    )[02],,,"C",,"V",,} )
	aAdd( aHeaderEx, { "Aviso"     , cZB3 +"_MSG"   , "@!",                        60,                        00,,,"C",,"V",,} )
	
	aStr := {}
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
	aAdd( aCpo, { cZB6 +"_DATA"  , "", "Dt.Inc."      , "@!" } )
	aAdd( aCpo, { cZB6 +"_PROD"  , "", "Codigo"       , "@!" } )
	aAdd( aCpo, { "B1_DESC"   , "", "Descricao"    , "@!" } )
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
    oItEdt6 := TMenuItem():New( oDlgEve, "Colocar produto no carrinho",,,,{|| fAddCar() },,,,,,,,,.T.)
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
    cQuery += "WHERE C7.C7_FILIAL  = '"+ xFilial( 'SC7' ) +"' " + CEOL
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
	cQuery := "SELECT C7.C7_NUM, C7.C7_ITEM, C7.C7_DATPRF, C7.C7_QUANT - C7.C7_QUJE EMPED, C7.C7_QUJE FROM "+ RetSqlName( 'SC7' ) +" C7 " + CEOL
    cQuery += "WHERE C7.C7_FILIAL  = '"+ xFilial( 'SC7' ) +"' " + CEOL
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
				aAdd( aPeds, { PDAJUS->C7_NUM, PDAJUS->C7_ITEM, PDAJUS->C7_DATPRF, PDAJUS->EMPED } )
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
						If DbSeek( xFilial( "SC7" ) + aPeds[nX][1] + aPeds[nX][2] )
							
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
						If DBSeek( xFilial( cZB3 ) + oEvent:aCols[ oEvent:nAt ][ nPrd ] + DtoS( oEvent:aCols[ oEvent:nAt ][ nDat ] ) )
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

/*
+-----------------+-------------------------+---------------------------------+-------------------+
| Fonte: GMPAICOM | Funcao:  fLoadExc       | Autor: Jean Carlos P. Saggin    |  Data: 21.10.2019 |
+-----------------+-------------------------+---------------------------------+-------------------+
| Descricao: Carrega exceções para geração de eventos no painel de compras. Essas exceções podem  |
|            ou não ser                     |
+-------------------------------------------------------------------------------------------------+
| Parametros recebidos: cProduto (Código do Produto), lNoInt( Se está rodando sem interface )     |
+-------------------------------------------------------------------------------------------------+
| Retorno da funcao: Nil                                                                          |
+-------------------------------------------------------------------------------------------------+  
*/
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
	cQuery += " ON B1.B1_FILIAL  = '"+ FWxFilial( "SB1" ) +"' " + CEOL
	cQuery += "AND B1.B1_COD     = "+ cZB6 +"."+ cZB6 +"_PROD " + CEOL
	cQuery += "AND B1.B1_MSBLQL  <> '1' " + CEOL
	cQuery += "AND B1.B1_MRP     = 'S' " + CEOL
	cQuery += "AND B1.D_E_L_E_T_ = ' ' " + CEOL

	cQuery += "WHERE "+ cZB6 +"."+ cZB6 +"_FILIAL = '"+ xFilial( cZB6 ) +"' " + CEOL
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
			If DBSeek( xFilial( cZB3 ) + oEvent:aCols[ oEvent:nAt ][ nPrd ] + DtoS( oEvent:aCols[ oEvent:nAt ][ nDat ] ) )
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
	
	Local cProd := oEvent:aCols[ oEvent:nAt ][ aScan( oEvent:aHeader, {| x | AllTrim( x[02] ) == cZB3 +"_PROD" } ) ]
	Local nPrd  := aScan( oEvent:aHeader, {|x| AllTrim( x[2] ) == cZB3 +"_PROD" } )
	Local nDat  := aScan( oEvent:aHeader, {|x| AllTrim( x[2] ) == cZB3 +"_DATA" } )
	
	Private lMsErroAuto := .F.
	
	MSExecAuto({|x, y| Mata010(x, y)}, {{"B1_FILIAL", xFilial( 'SB1' ), Nil },;
	                                    {"B1_COD"   , cProd           , Nil },;
	                                    {"B1_MRP"   , 'N'             , Nil }}, 4 )
	if lMsErroAuto
		MostraErro()
	Else
		// Grava justificativa no evento para que o mesmo seja desconsiderado da visualização
		DbSelectArea( cZB3 )
		(cZB3)->( DBSetOrder( 1 ) )
		If DBSeek( xFilial( cZB3 ) + oEvent:aCols[ oEvent:nAt ][ nPrd ] + DtoS( oEvent:aCols[ oEvent:nAt ][ nDat ] ) )
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
	
	Local cProd := oEvent:aCols[ oEvent:nAt ][ aScan( oEvent:aHeader, {| x | AllTrim( x[02] ) == cZB3 +"_PROD" } ) ]
	Local nPrd  := aScan( oEvent:aHeader, {| x | AllTrim( x[02] ) == cZB3 +"_PROD" } )
	Local nDat  := aScan( oEvent:aHeader, {| x | AllTrim( x[02] ) == cZB3 +"_DATA" } )
	
	DBSelectArea( cZB6 )
	( cZB6 )->( DbSetOrder( 1 ) )
	If !DbSeek( xFilial( cZB6 ) + cProd  )
		
		RecLock( cZB6, .T. )
		(cZB6)->( FieldPut( FieldPos( cZB6 +'_FILIAL' ), FWxFilial( cZB6 ) ) )
		(cZB6)->( FieldPut( FieldPos( cZB6 +'_PROD' ), cProd ) )
		(cZB6)->( FieldPut( FieldPos( cZB6 +'_DATA' ), Date() ) )
		(cZB6)->( FieldPut( FieldPos( cZB6 +'_DTLIM' ), StoD( '20491231' ) ) )
		(cZB6)->( FieldPut( FieldPos( cZB6 +'_COMPL' ), ""  ) ) 		
		(cZB6)->( FieldPut( FieldPos( cZB6 +'_ULTTEN' ), StoD( Space( 8 ) ) ) )
		(cZB6)->( FieldPut( FieldPos( cZB6 +'_DESCO'  ), .T. ) )  							// Evento referente a descontinuidade do produto

		(cZB6)->( MsUnlock() )
	EndIf
	
	// Grava justificativa no evento para que o mesmo seja desconsiderado da visualização
	DbSelectArea( cZB3 )
	(cZB3)->( DBSetOrder( 1 ) )
	If DBSeek( xFilial( cZB3 ) + oEvent:aCols[ oEvent:nAt ][ nPrd ] + DtoS( oEvent:aCols[ oEvent:nAt ][ nDat ] ) )
		RecLock( cZB3, .F. )
		(cZB3)->( FieldPut( FieldPos( cZB3 +'_JUSTIF' ), "002" ) ) 			// Produto foi ou será descontinuado
		(cZB3)->( FieldPut( FieldPos( cZB3 +'_COMPL' ), "PRODUTO SERA DESCONTINUADO, ALIMENTADO REGISTRO DE EXCECAO ATE QUE O ESTOQUE DO MESMO SE ESGOTE" ) )	// Informações complementares da reprogramação de entrega com o fornecedor
		(cZB3)->( MsUnlock() )
	EndIf	
	
	// Valida existência da função que realiza análise e inativação do produto quando o mesmo não tem mais saldo em estoque
	if FindFunction( 'U_GMPRDDES' )
		U_GMPRDDES( cProd )
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
		
		cQuery := "SELECT "+ cZB6 +"."+ cZB6 +"_PROD, B1.B1_DESC, B1.B1_UM, "+ cZB6 +".R_E_C_N_O_ REC"+ cZB6 +","
		cQuery += " "+ cZB6 +"."+ cZB6 +"_ULTTEN, SUM( COALESCE( B2.B2_QATU, 0) ) SALDO FROM "+ RetSqlName( cZB6 ) +" "+ cZB6 +" " + CEOL
		
		// Liga com cadastro de produto
        cQuery += "INNER JOIN "+ RetSqlName( 'SB1' ) +" B1 " + CEOL
        cQuery += " ON B1.B1_FILIAL  = '"+ xFilial( 'SB1' ) +"' " + CEOL
        cQuery += "AND B1.B1_COD     = "+ cZB6 +"."+ cZB6 +"_PROD " + CEOL
        cQuery += "AND B1.B1_MSBLQL  <> '1' " + CEOL						// Apenas produtos não bloqueados
        cQuery += "AND B1.D_E_L_E_T_ = ' ' " + CEOL
        
        // Relaciona com saldo de estoque do produto
        cQuery += "LEFT JOIN "+ RetSqlName( 'SB2' ) +" B2 " + CEOL
        cQuery += " ON B2.B2_FILIAL  = '"+ xFilial( 'SB2' ) +"' " + CEOL
        cQuery += "AND B2.B2_COD     = B1.B1_COD " + CEOL
        cQuery += "AND B2.B2_LOCAL   IN ( '"+ cLocais +"' ) " + CEOL		// Armazéns que o painel de compras leva em consideração para compor saldo do produto
        cQuery += "AND B2.D_E_L_E_T_ = ' ' " + CEOL

        cQuery += "WHERE "+ cZB6 +"."+ cZB6 +"_FILIAL = '"+ xFilial( cZB6 ) +"' " + CEOL
        
        // Filtra apenas o produto que veio via parâmetro
        if !Empty( cProd )
        	cQuery += "  AND "+ cZB6 +"."+ cZB6 +"_PROD   = '"+ cProd +"' " + CEOL
        EndIf
        cQuery += "  AND "+ cZB6 +"."+ cZB6 +"_DTLIM  >= '"+ DtoS( Date() ) +"' " + CEOL	// Apenas as exceções com data limite maior ou igual a (hoje)
        cQuery += "  AND "+ cZB6 +"."+ cZB6 +"_DESCO  = 'T' " + CEOL						// Apenas os eventos que são para descontinuidade de produtos
        cQuery += "  AND "+ cZB6 +".D_E_L_E_T_ = ' ' " + CEOL  

        cQuery += "GROUP BY "+ cZB6 +"."+ cZB6 +"_PROD, B1.B1_DESC, B1.B1_UM, "+ cZB6 +".R_E_C_N_O_, "+ cZB6 +"."+ cZB6 +"_ULTTEN " + CEOL
		
        TcQuery cQuery new Alias "DESC"
        DbSelectArea( 'DESC' )
        
        if !DESC->( EOF() )
        	While !DESC->( EOF() )
        		
        		if DESC->SALDO == 0
        			
        			lMsErroAuto := .F.
        			MSExecAuto({|x, y| Mata010(x, y)}, {{"B1_FILIAL", FWxFilial( 'SB1' ), Nil },;
					                                    {"B1_COD"   , DESC->( FieldGet( FieldPos( cZB6 +'_PROD' ) ) ), Nil },;
					                                    {"B1_MRP"   , 'N'             , Nil },;
					                                    {"B1_MSBLQL", '1'             , Nil }}, 4 )
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
	Local cGetDes   := oBrwPro:aCols[ oBrwPro:nAt ][ nPosDes ]
	Local oGetPrd
	Local cGetPrd   := oBrwPro:aCols[ oBrwPro:nAt ][ nPosPrd ]
	Local oLblPrd   := 0
	Local nX        := 0
	Local aHeaderEx := {}
	Local aFields   := {"NUMERO","C7_ITEM","C7_QUANT","SALDO","C7_PRECO","C7_TOTAL","C7_DATPRF","C7_FORNECE","C7_LOJA","A2_NOME"}
	Local aAlter    := {}
	Local cTitulo   := "Pedidos em aberto"
	Local oBtnLeg   := Nil
	local oBtnImp   as object
	
	Private aColsEx := {}
	Private oGrid   := Nil
	Private oDlgPed := Nil
	
	cTitulo += iif( nOpc == 1, ' com o fornecedor '+;
	           AllTrim( RetField( 'SA2', 1, xFilial( 'SA2' ) + oBrwPro:aCols[ oBrwPro:nAt ][ nPosFor ] + oBrwPro:aCols[ oBrwPro:nAt ][ nPosLoj ], 'A2_NOME' )),;
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
    
    @ 136, 385 BUTTON oBtnLeg PROMPT "&Legenda"  SIZE 037, 012 OF oDlgPed ACTION fLegenda() PIXEL
	@ 136, 424 BUTTON oBtnImp PROMPT "&Imprimir" SIZE 037, 012 OF oDlgPed ACTION iif( Len(oGrid:aCols) > 0, GMPCPRINT( oGrid:aCols[oGrid:nAt][ColPos(oGrid,'NUMERO')] ), Nil) PIXEL
    @ 136, 463 BUTTON oBtnFec PROMPT "&Fechar"   SIZE 037, 012 OF oDlgPed ACTION oDlgPed:End() PIXEL
    
    ACTIVATE MSDIALOG oDlgPed CENTERED ON INIT ;
	Processa( {|| fPedPen( .F./*lNoInt*/, nOpc, oBrwPro:aCols[ oBrwPro:nAt ][ nPosPrd ] /*cProd*/ ) }, 'Aguarde!','Buscando pedidos não atendidos!' )
	
Return ( Nil )

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
	
	//"C7_QUANT","C7_ITEM","SALDO","C7_PRECO","C7_TOTAL","C7_DATPRF","C7_FORNECE","C7_LOJA","RAZAO"
	cQuery += "SELECT C7.C7_NUM NUMERO, C7_ITEM, C7_CONAPRO, SUM( C7.C7_QUANT ) C7_QUANT, SUM(C7.C7_QUANT - C7.C7_QUJE) SALDO, C7.C7_PRECO, SUM( C7.C7_TOTAL ) C7_TOTAL, " + CEOL
	cQuery += "       C7.C7_DATPRF, C7.C7_FORNECE, C7.C7_LOJA, A2.A2_NOME " + CEOL
	cQuery += "FROM "+ RetSqlName( 'SC7' ) +" C7 " + CEOL
	
	cQuery += "INNER JOIN "+ RetSqlName( 'SB1' ) +" B1 "+ CEOL
	cQuery += " ON B1.B1_FILIAL  = '"+ xFilial( 'SB1' ) +"' " + CEOL
	cQuery += "AND B1.B1_COD     = C7.C7_PRODUTO " + CEOL
	cQuery += "AND B1.D_E_L_E_T_ = ' ' " + CEOL
	
	cQuery += "INNER JOIN "+ RetSqlName( 'SA2' ) +" A2 " + CEOL
	cQuery += " ON A2.A2_FILIAL  = '"+ xFilial( 'SA2' ) +"' " + CEOL
	cQuery += "AND A2.A2_COD     = C7.C7_FORNECE " + CEOL
	cQuery += "AND A2.A2_LOJA    = C7.C7_LOJA "+ CEOL
	
	if nOpc == 1
		cQuery += "  AND A2.A2_COD  = B1.B1_PROC " + CEOL
		cQuery += "  AND A2.A2_LOJA = B1.B1_LOJPROC " + CEOL
	EndIf
	
	cQuery += "AND A2.D_E_L_E_T_ = ' ' " + CEOL
	
    cQuery += "WHERE C7.C7_FILIAL  = '"+ xFilial( 'SC7' ) +"' " + CEOL
    cQuery += "  AND C7.C7_PRODUTO = '"+ cProd +"' " + CEOL
    cQuery += "  AND C7.C7_RESIDUO <> 'S' " + CEOL
    cQuery += "  AND C7.C7_ENCER   <> 'E' " + CEOL
    cQuery += "  AND C7.D_E_L_E_T_ = ' ' " + CEOL
    
    cQuery += "GROUP BY C7.C7_NUM, C7.C7_ITEM, C7_CONAPRO, C7.C7_PRECO, C7.C7_DATPRF, C7.C7_FORNECE, C7.C7_LOJA, A2.A2_NOME " + CEOL
    cQuery += "ORDER BY C7.C7_DATPRF, C7.C7_NUM " + CEOL
    
	TcQuery cQuery New Alias 'PEDTMP'
	DbSelectArea( 'PEDTMP' )
	
	// Seta o tipo de conteúdo dos campos quando for data
    TcSetField( 'PEDTMP', 'C7_DATPRF', 'D' )
	
	PEDTMP->( DbGoTop() )
	
	If !PEDTMP->( EOF() )
		aColsEx := {}
		While !PEDTMP->( EOF() )
			
			aAdd( aColsEx, { iif( PEDTMP->C7_CONAPRO == 'B', "BR_AZUL", "BR_VERDE" ),;
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
	
	Default lNoInt := .F.
	
	oDash:DeActivate()
	
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
	if oBrwPro != Nil .and. Len( oBrwPro:aCols ) > 0
		
		aTemp   := StrTokArr( AllTrim( oBrwPro:aCols[ oBrwPro:nAt ][ nPosDes ] ), ' ' )
		cDesPro := ""
		aEval( aTemp, { |x| cDesPro += SubStr( x, 01, iif( Len( x ) >= 3, 3, Len( x ) ) ) +' ' } )
		
		// Monta comando para leitura dos dados do banco
		cQuery := ""
		oDash:SetPicture( PesqPict( cZB3, cZB3 +'_INDINC' ) )
		For nX := 1 to Len( aPer )
		
			cQuery := "SELECT ROUND(COALESCE(SUM(D2.D2_QUANT),0),0) QTDVEN FROM "+ RetSqlName( 'SD2' ) +" D2 " + CEOL
			cQuery += "WHERE D2.D2_FILIAL  = '"+ FWxFilial( "SD2" ) +"' " + CEOL
			cQuery += "  AND D2.D2_COD     = '"+ oBrwPro:aCols[ oBrwPro:nAt ][ nPosPrd ] +"' " + CEOL
			cQuery += "  AND D2.D2_TIPO    = 'N' " + CEOL		// Apenas notas de saída do tipo N
			cQuery += "  AND D2.D2_EMISSAO BETWEEN '"+ DtoS( aPer[nX][01] ) +"' AND '"+ DtoS( aPer[nX][02] ) +"' " + CEOL
			cQuery += "  AND D2.D_E_L_E_T_ = ' ' " + CEOL

			DBUseArea( .T., "TOPCONN", TcGenQry(,,cQuery), "TMPVEN" /* cAlias */, .F. /* lShared */, .T. /* lReadOnly */ )
			If !TMPVEN->( EOF() )
				oDash:AddSerie( aPer[nX][03], TMPVEN->QTDVEN )
			EndIf
			TMPVEN->( DbCloseArea() )
			
		Next nX
		
	EndIf
	oDash:Activate()
	oDlgCom:Refresh()
	
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
	
	Local aArea   := FORTMP->( GetArea() )
	Local cQuery  := ""
	Local cExpFor := ""
	Local nRecFor := FORTMP->( Recno() )
	Local nQtdPrd := 0
	Local nAtual  := 0
	Local cTmp    := Upper( AllTrim( _cFilPrd ) )
	Local aTmp    := StrTokArr( cTmp, ' ' )
	Local nX      := 0
	Local nIndGir := 0
	Local aGiros  := {}
	Local cLocais := ""									// Armazens onde o sistema vai ler a quantidade de saldo x produto
	Local nPrjEst := 0									// Armazena projeção do cálculo de duração do estoque atual do produto
	Local nQtdCom := 0									// Armazena o resultado do cálculo da quantidade a ser comprada
	Local aInfPrd := {}
	Local nOpcOrd := 0
	Local cExpOrd := ""
	Local lAllFor := iif( Empty( cFndFor ), .T., .F. )
	Local aAux    := {}
	Local nDurPrv := 0
	local nLeadTime := 0 as numeric
	local cLeadTime := "" as character

	
	Default lNoInt := .F.								// Default é rodar "Com Interface"
	
	If Select( "FORTMP" ) > 0
		
		DbSelectArea( 'FORTMP' )
		FORTMP->( DbGoTop() )
		
		If !FORTMP->( EOF() )
			
			cExpFor := ""	
			While !FORTMP->( EOF() )
				if !Empty( FORTMP->MARK )
					cExpFor += iif( Empty( cExpFor ), "","," ) + "'" + FORTMP->B1_PROC + FORTMP->B1_LOJPROC + "'"
				Else
					lAllFor := .F.
				EndIf
				FORTMP->( DbSkip() )
			EndDo
			
			// Devolve o posicionamento do fornecedor
			FORTMP->( DbGoTo( nRecFor ) )
			
		EndIf
	EndIf

	// Monta string referente aos armazens que serão utilizados para somatório dos saldos dos produtos
	aAux    := StrTokArr( AllTrim( aConfig[16] ), '/' )
	cLocais := ""
	For nX := 1 to Len( aAux )
		cLocais += PADR( AllTrim( aAux[nX] ), TAMSX3('B2_LOCAL')[01], ' ') + iif( nX == Len(aAux),'',"','" )
	Next nX
	
	// Valida existência de conteúdo no parâmetro de armazéns
	if Empty( cLocais )
		MsgStop( 'Locais de estoque não definidos nos parâmetros do Painel de Compras!','Defina os armazéns para leitura de saldo em estoque!' )
		Return ( Nil )
	EndIf
	
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
	
	aColPro := {}
	
	// Valida se alguma classificação de giro foi selecionada antes de prosseguir
	if Len( aGiros ) > 0
		
		// Consulta todos os produtos para exibilos no grid
		cQuery := "SELECT B1.B1_COD, B1.B1_DESC, B1.B1_UM, B1.B1_LM, B1.B1_QE, B1.B1_LE, B1.B1_PROC, " + CEOL
	    cQuery += "       B1.B1_LOJPROC, B1.R_E_C_N_O_ RECSB1, " + CEOL
	    
	    cQuery += "       COALESCE( ( SELECT ROUND(( D1.D1_TOTAL - D1.D1_DESC ) / D1.D1_QUANT,2) VALNEG FROM "+ RetSqlName( 'SD1' ) +" D1 " + CEOL
	    cQuery += "        WHERE D1.R_E_C_N_O_ = ( " + CEOL
	    cQuery += "      SELECT MAX(D1.R_E_C_N_O_) FROM "+ RetSqlName( 'SD1' ) +" D1 " + CEOL
	    cQuery += "      WHERE D1.D1_FILIAL  = '"+ xFilial( 'SD1' ) +"' " + CEOL
	    cQuery += "        AND D1.D1_COD     = B1.B1_COD " + CEOL
	    cQuery += "        AND D1.D1_FORNECE = B1.B1_PROC " + CEOL
	    cQuery += "        AND D1.D1_LOJA    = B1.B1_LOJPROC " + CEOL
	    cQuery += "        AND D1.D1_TIPO    = 'N' " + CEOL
	    cQuery += "        AND D1.D_E_L_E_T_ = ' ') ), 0) ULTPRC, " + CEOL
	    
	    cQuery += "       COALESCE(( SELECT SUM(B2.B2_QATU) QTDATU FROM "+ RetSqlName( 'SB2' ) +" B2 " + CEOL
	    cQuery += "             WHERE B2.B2_FILIAL  = '"+ xFilial( 'SB2' ) +"' " + CEOL
	    cQuery += "               AND B2.B2_COD     = B1.B1_COD " + CEOL
	    cQuery += "               AND B2.B2_LOCAL   IN ( '"+ cLocais +"' ) " + CEOL
	    cQuery += "               AND B2.D_E_L_E_T_ = ' ' ),0 ) ESTOQUE, " + CEOL
	
	    cQuery += "       COALESCE(( SELECT SUM(B2.B2_RESERVA+B2.B2_QEMP) EMPENHO FROM "+ RetSqlName( 'SB2' ) +" B2 " + CEOL
	    cQuery += "             WHERE B2.B2_FILIAL  = '"+ xFilial( 'SB2' ) +"' " + CEOL
	    cQuery += "               AND B2.B2_COD     = B1.B1_COD " + CEOL
	    cQuery += "               AND B2.B2_LOCAL   IN ( '"+ cLocais +"' ) " + CEOL
	    cQuery += "               AND B2.D_E_L_E_T_ = ' ' ),0) EMPENHO, " + CEOL 
	    
	    cQuery += "       COALESCE( ( SELECT ROUND(AVG( TO_DATE(D1.D1_DTDIGIT,'YYYYMMDD')-TO_DATE(C7.C7_EMISSAO,'YYYYMMDD')),0) MEDIA FROM "+ RetSqlName( 'SD1' ) +" D1 " + CEOL
	
	    cQuery += "              INNER JOIN "+ RetSqlName( 'SC7' ) +" C7 " + CEOL
	    cQuery += "               ON C7.C7_FILIAL  = '"+ xFilial( 'SC7' ) +"' " + CEOL
	    cQuery += "              AND C7.C7_NUM     = D1.D1_PEDIDO " + CEOL
	    cQuery += "              AND C7.C7_ITEM    = D1.D1_ITEMPC " + CEOL
	    cQuery += "              AND C7.D_E_L_E_T_ = ' ' " + CEOL
	
	    cQuery += "              WHERE D1.D1_FILIAL  = '"+ xFilial( 'SD1' ) +"' " + CEOL
	    cQuery += "                AND D1.D1_COD     = B1.B1_COD " + CEOL
	    cQuery += "                AND D1.D1_FORNECE = B1.B1_PROC " + CEOL 
	    cQuery += "                AND D1.D1_LOJA    = B1.B1_LOJPROC " + CEOL
		cQuery += "                AND D1.D1_DTDIGIT >= '"+ DtoS( Date()-365 ) +"' " + CEOL				// Pedidos de compra apenas do último ano
	    cQuery += "                AND D1.D1_TES     <> ' ' " + CEOL
	    cQuery += "                AND D1.D_E_L_E_T_ = ' ' ), 0 ) LEADTIME, " + CEOL
		
		// Identifica o lead-time do fornecedor
		if SA2->( FieldPos( 'A2_X_LTIME' ) ) > 0
			cQuery += " A2.A2_X_LTIME, "+ CEOL
		else
			cQuery += " 0 A2_X_LTIME, "+ CEOL
		endif

	    cQuery += "       B1.B1_PE, " + CEOL
	    cQuery += "       COALESCE( (SELECT SUM(C7.C7_QUANT - C7.C7_QUJE) EMPED FROM "+ RetSqlName( 'SC7' ) +" C7 " + CEOL
        cQuery += "               WHERE C7.C7_FILIAL  = '"+ xFilial( 'SC7' ) +"' " + CEOL
        cQuery += "                 AND C7.C7_PRODUTO = B1.B1_COD " + CEOL
        cQuery += "                 AND C7.C7_RESIDUO <> 'S' " + CEOL
        cQuery += "                 AND C7.C7_ENCER   <> 'E' " + CEOL
        cQuery += "                 AND C7.C7_CONAPRO = 'B' " + CEOL						// identifica quantidade em pedido de compra com bloqueio
        cQuery += "                 AND C7.D_E_L_E_T_ = ' '), 0) QTDBLOQ, " + CEOL	    
	    
	    cQuery += "       COALESCE( (SELECT SUM(C7.C7_QUANT - C7.C7_QUJE) EMPED FROM "+ RetSqlName( 'SC7' ) +" C7 " + CEOL
        cQuery += "               WHERE C7.C7_FILIAL  = '"+ xFilial( 'SC7' ) +"' " + CEOL
        cQuery += "                 AND C7.C7_PRODUTO = B1.B1_COD " + CEOL
        cQuery += "                 AND C7.C7_RESIDUO <> 'S' " + CEOL
        cQuery += "                 AND C7.C7_ENCER   <> 'E' " + CEOL
        cQuery += "                 AND C7.C7_CONAPRO <> 'B' " + CEOL						// desconsidera se o pedido ainda estiver pendente de aprovação
        cQuery += "                 AND C7.D_E_L_E_T_ = ' '), 0) QTDCOMP, " + CEOL

	    cQuery += "       COALESCE( (SELECT MAX( C7.C7_DATPRF ) FROM "+ RetSqlName( 'SC7' ) +" C7 " + CEOL
        cQuery += "               WHERE C7.C7_FILIAL  = '"+ xFilial( 'SC7' ) +"' " + CEOL
        cQuery += "                 AND C7.C7_PRODUTO = B1.B1_COD " + CEOL
        cQuery += "                 AND C7.C7_RESIDUO <> 'S' " + CEOL
        cQuery += "                 AND C7.C7_ENCER   <> 'E' " + CEOL
        cQuery += "                 AND C7.C7_CONAPRO <> 'B' " + CEOL						// desconsidera se o pedido ainda estiver pendente de aprovação
        cQuery += "                 AND C7.D_E_L_E_T_ = ' '), '        ') PRVENT, " + CEOL
        
        cQuery += "       COALESCE( ( SELECT "+ cZB3 +"_CONMED FROM "+ RetSqlName( cZB3 ) +" " + CEOL
        cQuery += "              WHERE R_E_C_N_O_ = ( " + CEOL
        cQuery += "                SELECT MAX("+ cZB3 +".R_E_C_N_O_) FROM "+ RetSqlName( cZB3 ) +" "+ cZB3 +" " + CEOL
        cQuery += "                WHERE "+ cZB3 +"."+ cZB3 +"_FILIAL = '"+ xFilial( cZB3 ) +"' " + CEOL
        cQuery += "                  AND "+ cZB3 +"."+ cZB3 +"_PROD   = B1.B1_COD " + CEOL
        cQuery += "                  AND "+ cZB3 +".D_E_L_E_T_ = ' ' ) ), 0.0001 ) "+ cZB3 +"_CONMED, " + CEOL
        
        cQuery += "       COALESCE( ( SELECT "+ cZB3 +"_INDINC FROM "+ RetSqlName( cZB3 ) +" " + CEOL
        cQuery += "              WHERE R_E_C_N_O_ = ( " + CEOL
        cQuery += "                SELECT MAX("+ cZB3 +".R_E_C_N_O_) FROM "+ RetSqlName( cZB3 ) +" "+ cZB3 +" " + CEOL
        cQuery += "                WHERE "+ cZB3 +"."+ cZB3 +"_FILIAL = '"+ xFilial( cZB3 ) +"' " + CEOL
        cQuery += "                  AND "+ cZB3 +"."+ cZB3 +"_PROD   = B1.B1_COD " + CEOL
        cQuery += "                  AND "+ cZB3 +".D_E_L_E_T_ = ' ' ) ), 0 ) "+ cZB3 +"_INDINC " + CEOL

	    cQuery += "FROM "+ RetSqlName( 'SB1' ) +" B1 " + CEOL

		cQuery += "LEFT JOIN "+ RetSqlName( 'SA2' ) +" A2 "+ CEOL
		cQuery += " ON A2.A2_FILIAL  = '"+ FWxFilial( 'SA2' ) +"' " + CEOL
		cQuery += "AND A2.A2_COD     = B1.B1_PROC "+ CEOL
		cQuery += "AND A2.A2_LOJA    = B1.B1_LOJPROC "+ CEOL
		cQuery += "AND A2.D_E_L_E_T_ = ' ' "
	
	    cQuery += "WHERE B1.B1_FILIAL  = '"+ xFilial( 'SB1' ) +"' " + CEOL
	    cQuery += "  AND B1.B1_MSBLQL  <> '1' " + CEOL				// Faz leitura apenas dos itens ativos
		cQuery += "  AND B1.B1_TIPO NOT IN ( 'PA', 'SV' ) "			// Desconsidera produtos acabado e serviços da análise do MRP
	    cQuery += "  AND B1.B1_MRP     = 'S' " + CEOL				// Apenas os produtos que devem entrar no MRP
	    
	    if Len( aTmp ) > 0
	    	For nX := 1 to Len( aTmp )
	    		cQuery += "  AND B1.B1_DESC LIKE '%"+ aTmp[nX] +"%' " + CEOL
	    	Next nX 
		EndIf
	    
	    if !lAllFor		// Verifica se os fornecedores estão todos selecionados (aí não tem necessidade de filtro)
	    	cQuery += "  AND CONCAT( B1.B1_PROC, B1.B1_LOJPROC ) IN ( "+ iif( Empty( cExpFor ), "'"+ Replicate( '9', TAMSX3('B1_PROC')[01] ) +"'", cExpFor ) +" ) " + CEOL
	    EndIf
	    
	    cQuery += "  AND B1.D_E_L_E_T_ = ' ' " + CEOL				
	    
		DBUseArea( .T., "TOPCONN", TcGenQry(,,cQuery), "PRDTMP", .F., .T. )
	    Count to nQtdPrd
	    
	    // Define o tamanho da régua para seguir com o processamento
	    ProcRegua( nQtdPrd )
	    
	    PRDTMP->( DbGoTop() )
	    if !PRDTMP->( EOF() )
	    	
	    	DbSelectArea( 'SB1' )
	    	
	    	While !PRDTMP->( EOF() )
	    		nAtual++
	    		IncProc( 'Analisando '+ AllTrim( SubStr( PRDTMP->B1_DESC, 01, 30 ) ) + '('+ AllTrim( cValToChar( nAtual ) ) +'/'+ AllTrim( cValToChar( nQtdPrd ) ) +')' )
	    		
				// Identifica lead-time conforme regra definida para produto, fornecedor (informado) ou fornecedor (calculado)
				if PRDTMP->B1_PE > 0
					nLeadTime := PRDTMP->B1_PE
					cLeadTime := 'P'		// Produto
				elseif PRDTMP->A2_X_LTIME > 0
					nLeadTime := PRDTMP->A2_X_LTIME
					cLeadTime := 'F'		// Fornecedor
				else
					nLeadTime := PRDTMP->LEADTIME
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
							 PRDTMP->B1_LE /* nLotEco */ }
	    		
	    		nQtdCom := fCalNec( aInfPrd )
	    		
	    		// Quando apenas sugestões estiver marcado, exibe só os produtos com quantidade de compra maior que 0 (zero)
	    		if nRadMenu == 2 .and. nQtdCom == 0
	    			PRDTMP->( DbSkip() )
	    			Loop
	    		EndIf
	    		
	    		// Trata produtos pelo índice de incidência
	    		nIndGir := PRDTMP->( FieldGet( FieldPos( cZB3 +'_INDINC' ) ) ) 
	    		For nX := 1 to Len( aGiros )
	    			if nIndGir >= aGiros[nX][01] .and. nIndGir <= aGiros[nX][02]
	    				
			    		aAdd( aColPro,{ aGiros[nX][03] /*legenda*/,;
										iif( aScan( aCarCom, {|x| x[1] == PRDTMP->B1_COD .and. x[13] == PRDTMP->B1_PROC .and. x[14] == PRDTMP->B1_LOJPROC } ) > 0, CIMGMRK, CIMGNOMRK ),;
			    						PRDTMP->B1_COD,;
			    						PRDTMP->B1_DESC,;
			    						PRDTMP->B1_UM,;
			    						nQtdCom /*Necessidade de compra*/,;
			    						PRDTMP->QTDBLOQ /*Ped. Compra Bloq.*/,;
			    						PRDTMP->ULTPRC /*Preço negociado*/,;
			    						PRDTMP->ULTPRC /*Ultimo Preço*/,; 
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
			    						PRDTMP->B1_PROC /*Fornecedor Padrão*/,;
			    						PRDTMP->B1_LOJPROC /*Loja do Fornecedor Padrão*/,;
			    						.F. } )
	    				
	    				Exit
	    			EndIf
	    		Next nX
	    		
	    		PRDTMP->( DbSkip() )
	    	EndDo
	    EndIf
	    
	    PRDTMP->( DbCloseArea() )
		
	EndIf
    
    if !Empty( cCboOrd )
	    nOpcOrd := Val( cCboOrd )
	    // Ordena o vetor com os dados dos produtos de acordo com o critério definido no painel
	    cExpOrd := 'x[nOpcOrd] ' + iif( cCboExi == 'A..Z', '<', '>' ) + ' y[nOpcOrd]'
	    aSort( aColPro,,,{|x,y| &( cExpOrd ) } )
    EndIf
    
	oBrwPro:aCols := aColPro
	oBrwPro:ForceRefresh()
	oDlgCom:Refresh()
	fLoadAna()
	
	RestArea( aArea )
	
Return ( Nil )

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
	cQuery := "SELECT "+ cZB3 +"."+ cZB3 +"_DATA, "+ cZB3 +"."+ cZB3 +"_PROD, B1.B1_DESC, " 
	cQuery += cZB3 +"."+ cZB3 +"_MSG, "+ cZB3 +"."+ cZB3 +"_JUSTIF FROM "+ RetSqlName( cZB3 ) +" "+ cZB3 +" " + CEOL

    cQuery += "INNER JOIN "+ RetSqlName( 'SB1' ) +" B1 " + CEOL
    cQuery += " ON B1.B1_FILIAL  = '"+ xFilial( 'SB1' ) +"' " + CEOL
    cQuery += "AND B1.B1_COD     = "+ cZB3 +"."+ cZB3 +"_PROD " + CEOL
	if Len( aExpr ) > 0
		for nExpr := 1 to len( aExpr )
			cQuery += iif( !Empty( aExpr[ nExpr ] ), "AND B1.B1_DESC LIKE '%"+ AllTrim( aExpr[nExpr] ) +"%' " + CEOL, "" )
		next
	endif
    cQuery += "AND B1.D_E_L_E_T_ = ' ' " + CEOL
    
    // Liga com tabela de produtos a serem ignorados
    cQuery += "LEFT JOIN "+ RetSqlName( cZB6 ) +" "+ cZB6 +" "+ CEOL
    cQuery += " ON "+ cZB6 +"."+ cZB6 +"_FILIAL = '"+ xFilial( cZB6 ) +"' " + CEOL
    cQuery += "AND "+ cZB6 +"."+ cZB6 +"_PROD   = "+ cZB3 +"."+ cZB3 +"_PROD " + CEOL
    cQuery += "AND "+ cZB6 +"."+ cZB6 +"_DTLIM  >= '"+ DtoS( Date() ) +"' " + CEOL
    cQuery += "AND "+ cZB6 +".D_E_L_E_T_ = ' ' " + CEOL
    
    cQuery += "WHERE "+ cZB3 +"."+ cZB3 +"_FILIAL = '"+ xFilial( cZB3 ) +"' " + CEOL
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
    		
    		aAdd( aEvePen, { EVETMP->( FieldGet( FieldPos( cZB3 +'_DATA' ) ) ),;
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

/*/{Protheus.doc} fLoadFor
Função para carregar fornecedores para a tela de análise
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 19/06/2024
/*/
Static Function fLoadFor()
	
	Local nQtdFor := 0
	Local nAtual  := 0
	Local cQuery  := ""
	Local cForPos := ""
	
	
	aSelFor := {}
	
	If Select( 'FORTMP' ) > 0
		
		cForPos := FORTMP->B1_PROC + FORTMP->B1_LOJPROC
	
		DbSelectArea( 'FORTMP' )
		FORTMP->( DbGoTop() )
		if !FORTMP->( EOF() )
			
			aSelFor := {}
			While !FORTMP->( EOF() )
				
				// Antes de excluir guarda os códigos dos fornecedores que estiverem marcados
				if !Empty( FORTMP->MARK )
					aAdd( aSelFor, { FORTMP->B1_PROC, FORTMP->B1_LOJPROC } )
				EndIf
				
				RecLock( 'FORTMP', .F. )
				FORTMP->( DBDelete() )
				FORTMP->( MsUnlock() )
				
				FORTMP->( DbSkip() )
			EndDo
		EndIf
		
	EndIf
	
	// Consulta todos os produtos para exibilos no grid
	cQuery := "SELECT DISTINCT B1.B1_PROC, B1.B1_LOJPROC, COALESCE(A2.A2_NOME,'SEM FORNECEDOR PADRAO') A2_NOME, "
	cQuery += "       COALESCE( A2.A2_NREDUZ, 'SEM FORNECEDOR') A2_NREDUZ, COALESCE( A2.A2_EMAIL, '"+ Space( TAMSX3('A2_EMAIL')[01] ) +"' ) A2_EMAIL, " + CEOL
	cQuery += "       CASE WHEN COALESCE( A2.A2_COD, '"+ Space( TAMSX3('A2_COD')[1] ) +"' ) = '"+ Space( TAMSX3('A2_COD')[1] ) +"' THEN 0 " + CEOL
	cQuery += "            ELSE ( SELECT ROUND(AVG( TO_DATE(D1.D1_DTDIGIT,'YYYYMMDD')-TO_DATE(C7.C7_EMISSAO,'YYYYMMDD')),0) MEDIA " + CEOL
	cQuery += " FROM "+ RetSqlName( 'SD1' ) +" D1 " + CEOL

    cQuery += "                   INNER JOIN "+ RetSqlName( 'SC7' ) +" C7 " + CEOL
    cQuery += "                    ON C7.C7_FILIAL  = '"+ xFilial( 'SC7' ) +"' " + CEOL
    cQuery += "                   AND C7.C7_NUM     = D1.D1_PEDIDO " + CEOL
    cQuery += "                   AND C7.C7_ITEM    = D1.D1_ITEMPC " + CEOL
    cQuery += "                   AND C7.D_E_L_E_T_ = ' ' " + CEOL

    cQuery += "                   WHERE D1.D1_FILIAL  = '"+ xFilial( 'SD1' ) +"' " + CEOL
    cQuery += "                     AND D1.D1_TES     <> ' ' " + CEOL
    cQuery += "                     AND D1.D1_FORNECE = B1.B1_PROC " + CEOL 
    cQuery += "                     AND D1.D1_LOJA    = B1.B1_LOJPROC " + CEOL
	cQuery += "                     AND D1.D1_DTDIGIT >= '"+ DtoS( Date() - DIAS_LT_FOR ) +"' " + CEOL
    cQuery += "                     AND D1.D_E_L_E_T_ = ' ' ) " + CEOL
	cQuery += "       END LEADTIME " + CEOL 
    cQuery += "FROM "+ RetSqlName( 'SB1' ) +" B1 " + CEOL

    cQuery += "LEFT JOIN "+ RetSqlName( 'SA2' ) +" A2 " + CEOL 
    cQuery += " ON A2.A2_FILIAL  = '"+ xFilial( 'SA2' ) +"' " + CEOL
    cQuery += "AND A2.A2_COD     = B1.B1_PROC " + CEOL
    cQuery += "AND A2.A2_LOJA    = B1.B1_LOJPROC " + CEOL 
    cQuery += "AND A2.D_E_L_E_T_ = ' ' " + CEOL

    cQuery += "WHERE B1.B1_FILIAL  = '"+ xFilial( 'SB1' ) +"' " + CEOL
    cQuery += "  AND B1.B1_MSBLQL  <> '1' " + CEOL				// Faz leitura apenas dos itens ativos
    cQuery += "  AND B1.B1_MRP     = 'S' " + CEOL				// Apenas os produtos que devem entrar no MRP
    cQuery += "  AND B1.D_E_L_E_T_ = ' ' " + CEOL
    
	DBUseArea( .T., "TOPCONN", TcGenQry( ,,cQuery ), "RETFOR", .F., .T. )
    Count to nQtdFor
    
    ProcRegua( nQtdFor )
    
    RETFOR->( DbGoTop() )
    if !RETFOR->( EOF() )
    	
    	nAtual := 0
    	
    	While !RETFOR->( EOF() )
    		nAtual++
    		IncProc( 'Identificando fornecedor '+ AllTrim( cValToChar( nAtual ) ) +'/'+ AllTrim( cValToChar( nQtdFor ) ) )
    		
    		RecLock( 'FORTMP', .T. )
    		FORTMP->MARK       := iif( aScan( aSelFor, { |x| x[1] == RETFOR->B1_PROC .and. x[2] == RETFOR->B1_LOJPROC } ) > 0, cMark, Space( 2 ) ) 
    		FORTMP->B1_PROC    := RETFOR->B1_PROC
    		FORTMP->B1_LOJPROC := RETFOR->B1_LOJPROC
    		FORTMP->A2_NOME    := RETFOR->A2_NOME
    		FORTMP->A2_NREDUZ  := RETFOR->A2_NREDUZ
    		FORTMP->A2_EMAIL   := RETFOR->A2_EMAIL
    		FORTMP->LEADTIME   := RETFOR->LEADTIME
			FORTMP->PEDIDO     := iif( aScan( aCarCom, {|x| x[13]+x[14] == RETFOR->B1_PROC + RETFOR->B1_LOJPROC } ) > 0, 'S', 'N' )									
    		FORTMP->( MsUnlock() )
    		
    		RETFOR->( DbSkip() )
    	EndDo
	EndIf
	
	RETFOR->( DbCloseArea() )
	
	FORTMP->( DbGoTop() )
	
	// Tenta restaurar o posicionamento no fornecedor onde estava posicionado antes de iniciar a função
	if !Empty( cForPos ) .and. !FORTMP->( EOF() )
		While !FORTMP->( EOF() ) .and. ( cForPos != FORTMP->B1_PROC + FORTMP->B1_LOJPROC )
			FORTMP->( DbSkip() )
		EndDo
		if cForPos != FORTMP->B1_PROC + FORTMP->B1_LOJPROC .or. FORTMP->( EOF() )
			FORTMP->( DbGoTop() )
		EndIf
	EndIf

	oBrwFor:Refresh(.T.)
	oBrwFor:UpdateBrowse()
	oDlgCom:Refresh()
	
Return ( Nil )

/*/{Protheus.doc} fMarkPro
Função para marcar/desmarcar registros das linhas do browse de produtos
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 21/06/2024
/*/
Static Function fMarkPro()
	
	local cForLoj := "" as character
	local lInclui := .F.
	
	if Len( oBrwPro:aCols ) > 0 .and. !Empty( oBrwPro:aCols[oBrwPro:nAt][aScan( oBrwPro:aHeader, {|x| AllTrim( x[2] ) == "B1_COD" } )] )
		oBrwPro:aCols[oBrwPro:nAt][aScan( oBrwPro:aHeader, {|x| AllTrim( x[2] ) == 'MARK' } )] := iif( oBrwPro:aCols[oBrwPro:nAt][aScan( oBrwPro:aHeader, {|x| AllTrim( x[2] ) == 'MARK' } )] != CIMGMRK, CIMGMRK, CIMGNOMRK )
		if oBrwPro:aCols[oBrwPro:nAt][aScan( oBrwPro:aHeader, {|x| AllTrim( x[2] ) == 'MARK' } )] == CIMGMRK
			aAdd( aCarCom, { oBrwPro:aCols[oBrwPro:nAt][aScan( oBrwPro:aHeader, {|x| AllTrim( x[2] ) == 'B1_COD' } )],;
			                 oBrwPro:aCols[oBrwPro:nAt][nPosDes],;
			                 oBrwPro:aCols[oBrwPro:nAt][nPosUnM],;
			                 oBrwPro:aCols[oBrwPro:nAt][nPosNec],;
			                 oBrwPro:aCols[oBrwPro:nAt][nPosNeg],;
			                 oBrwPro:aCols[oBrwPro:nAt][nPosNec]*oBrwPro:aCols[oBrwPro:nAt][nPosNeg],;
			                 Date(),;
			                 Date() + oBrwPro:aCols[oBrwPro:nAt][nPosLdT],;
			                 RetField( 'SB1', 1, xFilial( 'SB1' ) + oBrwPro:aCols[oBrwPro:nAt][nPosPrd], 'B1_LOCPAD' ),;
			                 Space( TAMSX3( 'C7_OBS' )[01] ),;
			                 '' /* cCC */,;
			                 RetField( 'SB1', 1, xFilial( 'SB1' ) + oBrwPro:aCols[oBrwPro:nAt][nPosPrd], 'B1_IPI' ),;
							 oBrwPro:aCols[oBrwPro:nAt][nPosFor],;
							 oBrwPro:aCols[oBrwPro:nAt][nPosLoj],;
			                 .F. } )
			lInclui := .T.
			cForLoj := oBrwPro:aCols[oBrwPro:nAt][nPosFor] + oBrwPro:aCols[oBrwPro:nAt][nPosLoj]
		Else
			cForLoj := oBrwPro:aCols[oBrwPro:nAt][nPosFor] + oBrwPro:aCols[oBrwPro:nAt][nPosLoj]
			aDel( aCarCom, aScan( aCarCom, {|x| x[1] == oBrwPro:aCols[oBrwPro:nAt][aScan( oBrwPro:aHeader, {|y| AllTrim( y[2] ) == 'B1_COD' } )] .and.;
												x[13] == oBrwPro:aCols[oBrwPro:nAt][aScan( oBrwPro:aHeader, {|y| AllTrim( y[2] ) == 'B1_PROC' } )] .and.;
												x[14] == oBrwPro:aCols[oBrwPro:nAt][aScan( oBrwPro:aHeader, {|y| AllTrim( y[2] ) == 'B1_LOJPROC' } )] } ) ) 
			aSize( aCarCom, Len( aCarCom )-1 )
			lInclui := .F.
		EndIf
		
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
	oDlgCom:Refresh()
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
	
	Local nColAtu  := 0
	Local lReturn  := .T.
	Local aVetPrd  := {}
	Local cQuery   := ""
	Local aChvSC7  := {}
	Local nQtdSC7  := 0
	Local aCab     := aLin := aIte := aColPd := aHdr := aFld := {}
	Local oPedidos := Nil
	Local oBtnFec  := Nil
	Local oDlgOpc  := Nil
	Local cStlBtn  := ""
	Local oNewGrid := 0
	Local nPosNum  := 0
	local nPosIte := 0
	local nPosQuant := 0
	Local nX       := 0
	local nLeadTime := 0 as numeric
	local cLeadTime := 0 as character
	local nPrjEst   := 0 as numeric
	local nDurPrv   := 0 as numeric
	local aInfPrd   := {} as array
	local nQtdCom   := 0 as numeric
	
	Private oBtnSel     := Nil
	Private lMsErroAuto := .F.
	
	if oBrwPro:oBrowse != Nil
		nColAtu := oBrwPro:oBrowse:nColPos
		DbSelectArea( 'SB1' )
		if SB1->( FieldPos( oBrwPro:aHeader[nColAtu][02] ) ) > 0
			SB1->( DbSetOrder( 1 ) )
			
			If DbSeek( xFilial( 'SB1' ) + oBrwPro:aCols[oBrwPro:nAt][nPosPrd] )
				
				// Compara a informação em memória com a informação gravada no cadastro do produto pra ver se é diferente
				if ( &( 'SB1->'+ AllTrim( oBrwPro:aHeader[nColAtu][02] ) ) != &( 'M->' + AllTrim( oBrwPro:aHeader[nColAtu][02] ) ) ) .or.;  
				   AllTrim( oBrwPro:aHeader[nColAtu][02] ) == "B1_PROC"
				   
					aAdd( aVetPrd, { "B1_FILIAL", xFilial( 'SB1' ), Nil } )
					aAdd( aVetPrd, { "B1_COD"   , oBrwPro:aCols[oBrwPro:nAt][nPosPrd], Nil } )
					aAdd( aVetPrd, { AllTrim( oBrwPro:aHeader[nColAtu][02] ), &( 'M->' + AllTrim( oBrwPro:aHeader[nColAtu][02] ) ), Nil } )
					
					If AllTrim( oBrwPro:aHeader[nColAtu][02] ) == "B1_PROC"
						aAdd( aVetPrd, { "B1_LOJPROC", iif( M->B1_LOJPROC == Nil, SA2->A2_LOJA, M->B1_LOJPROC ), Nil } )
					EndIf
					
					lMsErroAuto := .F.
					MSExecAuto({|x, y| Mata010(x, y)}, aVetPrd, 4 )
					
					If lMsErroAuto
						lReturn := !lMsErroAuto
						MostraErro()
					EndIf
					
				EndIf
				
			EndIf
			
		EndIf
		
		if oBrwPro:oBrowse:nColPos == nPosNec						// Alteração no campo de necessidade de compra
			if aScan( aCarCom, {|x| AllTrim( x[01] ) == AllTrim( oBrwPro:aCols[ oBrwPro:nAt ][ nPosPrd ] ) } ) > 0
				if MsgYesNo( 'Você está alterando a necessidade de compra de um produto que já está no carrinho, deseja mesmo alterar?','Alteração de produto do carrinho')
					aCarCom[ aScan( aCarCom, {|x| AllTrim( x[01] ) == AllTrim( oBrwPro:aCols[ oBrwPro:nAt ][ nPosPrd ] ) } ) ][ 04 ] := M->NECCOMP
					aCarCom[ aScan( aCarCom, {|x| AllTrim( x[01] ) == AllTrim( oBrwPro:aCols[ oBrwPro:nAt ][ nPosPrd ] ) } ) ][ 06 ] := M->NECCOMP * oBrwPro:aCols[oBrwPro:nAt][nPosNeg]
				Else
					lReturn := .F.
				EndIf
			EndIf
		ElseIf oBrwPro:oBrowse:nColPos == nPosNeg					// Alteração no campo do valor negociado
			if aScan( aCarCom, {|x| AllTrim( x[01] ) == AllTrim( oBrwPro:aCols[ oBrwPro:nAt ][ nPosPrd ] ) } ) > 0
				if MsgYesNo( 'Você está alterando o valor negociado de um produto que já está no carrinho, deseja mesmo alterar?','Alteração de produto do carrinho')
					aCarCom[ aScan( aCarCom, {|x| AllTrim( x[01] ) == AllTrim( oBrwPro:aCols[ oBrwPro:nAt ][ nPosPrd ] ) } ) ][ 05 ] := M->PRCNEGOC
					aCarCom[ aScan( aCarCom, {|x| AllTrim( x[01] ) == AllTrim( oBrwPro:aCols[ oBrwPro:nAt ][ nPosPrd ] ) } ) ][ 06 ] := oBrwPro:aCols[oBrwPro:nAt][nPosNec] * M->PRCNEGOC
				Else
					lReturn := .F.
				EndIf
			EndIf
		elseif oBrwPro:oBrowse:nColPos == nPosLdT 					// Alteração no campo do lead-time do produto
			if M->LEADTIME >= 0
				
				nLeadTime := M->LEADTIME
				if nLeadTime > 0
					cLeadTime := 'P'
				endif

				DBSelectArea( 'SB1' )
				SB1->( DBSetOrder( 1 ) )		// B1_FILIAL + B1_COD
				if SB1->( DBSeek( FWxFilial( 'SB1' ) + oBrwPro:aCols[ oBrwPro:nAt ][ nPosPrd ] ) )
					RecLock( 'SB1', .F. )
					SB1->B1_PE := nLeadTime
					SB1->( MsUnlock() )
					
					// Se o prazo de entrega do produto for maior do que zero, prioriza a informação do produto
					if nLeadTime == 0
						
						// Posiciona no cadastro do fornecedor padrão para o produto
						DBSelectArea( 'SA2' )
						SA2->( DbSetOrder( 1 ) ) 	// A2_FILIAL + A2_COD + A2_LOJA
						if SA2->( DBSeek( FWxFilial( 'SA2' ) + oBrwPro:aCols[ oBrwPro:nAt ][ nPosFor ] + oBrwPro:aCols[ oBrwPro:nAt ][ nPosLoj ] ) )
							// Verifica se o lead-time do fornecedor é maior do que zero
							if SA2->A2_X_LTIME > 0
								nLeadTime := SA2->A2_X_LTIME
								cLeadTime := 'F'		// Fornecedor
							endif

						endif

						// Se o lead-time ainda estiver sem valor, utiliza o cálculo do prazo médio do fornecedor padrão do produto
						if nLeadTime == 0

							// Realiza cálculo para saber prazo médio do fornecedor em relação ao produto atual
							cQuery += "SELECT COALESCE(ROUND(AVG( TO_DATE(D1.D1_DTDIGIT,'YYYYMMDD')-TO_DATE(C7.C7_EMISSAO,'YYYYMMDD')),0),0) MEDIA " + CEOL
							cQuery += "  FROM "+ RetSqlName( 'SD1' ) +" D1 " + CEOL
							
							cQuery += "INNER JOIN "+ RetSqlName( 'SC7' ) +" C7 " + CEOL
							cQuery += " ON C7.C7_FILIAL  = '"+ xFilial( 'SC7' ) +"' " + CEOL
							cQuery += "AND C7.C7_NUM     = D1.D1_PEDIDO " + CEOL
							cQuery += "AND C7.C7_ITEM    = D1.D1_ITEMPC " + CEOL
							cQuery += "AND C7.D_E_L_E_T_ = ' ' " + CEOL
						
							cQuery += "WHERE D1.D1_FILIAL  = '"+ xFilial( 'SD1' ) +"' " + CEOL
							cQuery += "  AND D1.D1_COD     = '"+ oBrwPro:aCols[ oBrwPro:nAt ][ nPosPrd ] +"' " + CEOL
							cQuery += "  AND D1.D1_FORNECE = '"+ oBrwPro:aCols[ oBrwPro:nAt ][ nPosFor ] +"' " + CEOL 
							cQuery += "  AND D1.D1_LOJA    = '"+ oBrwPro:aCols[ oBrwPro:nAt ][ nPosLoj ] +"' " + CEOL
							cQuery += "  AND D1.D1_DTDIGIT >= '"+ DtoS( Date()-DIAS_LT_FOR ) +"' " + CEOL				// Pedidos de compra apenas do último ano
							cQuery += "  AND D1.D1_TES     <> ' ' " + CEOL
							cQuery += "  AND D1.D_E_L_E_T_ = ' ' " 

							DBUseArea( .T. /* lNew */, 'TOPCONN', TcGenQry(,,cQuery), 'PRZMED', .F. /* lShared */, .T. /* lReadOnly */ )
							nLeadTime := PRZMED->MEDIA
							cLeadTime := 'C'
							PRZMED->( DBCloseArea() )
						endif

					endif

				endif

				// Atualiza os dados da linha do produto conforme alterações realizadas no campo do lead-time
				// Cálculo da duração do estoque com os pedidos de compra aprovados
				nPrjEst := Round( ( oBrwPro:aCols[ oBrwPro:nAt ][ nPosEmE ] - ;
									oBrwPro:aCols[ oBrwPro:nAt ][ nPosVen ] + ;
									oBrwPro:aCols[ oBrwPro:nAt ][ nPosQtd ] )/ ;
									oBrwPro:aCols[ oBrwPro:nAt ][ nPosCon ], 0 )
				if nPrjEst > 999 
					nPrjEst := 999
				EndIf
				
				// Cálculo da duração prevista quando as quantidades bloqueadas forem liberadas
				nDurPrv := Round( ( oBrwPro:aCols[ oBrwPro:nAt ][ nPosEmE ] - ;
									oBrwPro:aCols[ oBrwPro:nAt ][ nPosVen ] + ;
									oBrwPro:aCols[ oBrwPro:nAt ][ nPosQtd ] + ;
									oBrwPro:aCols[ oBrwPro:nAt ][ nPosBlq ] )/ ;
									oBrwPro:aCols[ oBrwPro:nAt ][ nPosCon ], 0 ) - nLeadTime
				if nDurPrv > 999 
					nDurPrv := 999
				EndIf
				
				aInfPrd := { nSpinBx /*nDias de programação de estoque*/,;
							nLeadTime /*nLdTime*/,;
							nPrjEst,;
							oBrwPro:aCols[ oBrwPro:nAt ][ nPosCon ] /*nConMed*/,;
							oBrwPro:aCols[ oBrwPro:nAt ][ nPosLtM ] /*nLotMin*/,;
							oBrwPro:aCols[ oBrwPro:nAt ][ nPosQtE ] /*nQtdEmb*/,;
							oBrwPro:aCols[ oBrwPro:nAt ][ nPosLtE ] /* nLotEco */ }
				
				// Função que calcula a necessidade de compra
				nQtdCom := fCalNec( aInfPrd )
				oBrwPro:aCols[ oBrwPro:nAt ][ nPosNec ] := nQtdCom
				oBrwPro:aCols[ oBrwPro:nAt ][ nPosDur ] := nPrjEst
				oBrwPro:aCols[ oBrwPro:nAt ][ nPosDuP ] := nDurPrv
				oBrwPro:aCols[ oBrwPro:nAt ][ nPosLdT ] := nLeadTime
				oBrwPro:aCols[ oBrwPro:nAt ][ nPosTLT ] := cLeadTime

			else
				lReturn := .F.
			endif

		EndIf
		
		If oBrwPro:oBrowse:nColPos == nPosBlq .and. oBrwPro:aCols[oBrwPro:nAt][nPosBlq] > 0
			
			// Identifica o(s) pedidos pendentes de aprovação para o produto
			cQuery := "SELECT C7.C7_NUM, C7.C7_ITEM FROM "+ RetSqlName( "SC7" ) + " C7 " + CEOL
			cQuery += "WHERE C7.C7_FILIAL  = '"+ xFilial( "SC7" ) +"' " + CEOL
			cQuery += "  AND C7.C7_PRODUTO = '"+ oBrwPro:aCols[ oBrwPro:nAt ][ nPosPrd ] +"' " + CEOL
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
					aAdd( aChvSC7, APRTMP->C7_NUM + APRTMP->C7_ITEM )
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
                aEval( aChvSC7, {|y| aAdd( aColPd, aClone( { RetField( "SC7", 1, xFilial( "SC7" ) + y, "C7_QUANT"   ),;
                                                   SubStr( y, 01, TAMSX3("C7_NUM")[1] ),;
                                                   SubStr( y, TAMSX3("C7_NUM")[1]+1, TAMSX3("C7_ITEM")[1] ),;
                                                   RetField( "SC7", 1, xFilial( "SC7" ) + y, "C7_PRECO"   ),;
                                                   RetField( "SC7", 1, xFilial( "SC7" ) + y, "C7_TOTAL"   ),;
                                                   RetField( "SC7", 1, xFilial( "SC7" ) + y, "C7_FORNECE" ),;
                                                   RetField( "SC7", 1, xFilial( "SC7" ) + y, "C7_LOJA"    ),;
                                                   RetField( "SA2", 1, xFilial( "SA2" ) +; 
                                                                       RetField( "SC7", 1, xFilial( "SC7" ) + y, "C7_FORNECE" ) +; 
                                                                       RetField( "SC7", 1, xFilial( "SC7" ) + y, "C7_LOJA"    ), "A2_NOME" ),;
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
					aAdd( aCab, { "C7_FILIAL" , xFilial( "SC7" ) } )
					aAdd( aCab, { "C7_NUM"    , SubStr( aChvSC7[1], 1, TAMSX3("C7_NUM")[1] ) } )
					aadd( aCab, {"C7_EMISSAO" ,SC7->C7_EMISSAO })
					aadd( aCab, {"C7_FORNECE" ,SC7->C7_FORNECE })
					aadd( aCab, {"C7_LOJA"    , SC7->C7_LOJA })
					aadd( aCab, {"C7_COND"    , SC7->C7_COND })
					aadd( aCab, {"C7_CONTATO" ,SC7->C7_CONTATO })
					aadd( aCab, {"C7_FILENT"  ,cFilAnt })
					
					aLin := {}
					If M->QTDBLOQ > 0
						
						aAdd( aLin, { "C7_ITEM"   , SubStr( aChvSC7[1], TAMSX3("C7_NUM")[1]+1, TAMSX3("C7_ITEM")[1] ), Nil } )
						aAdd( aLin, { "C7_PRODUTO", SC7->C7_PRODUTO, Nil } )
						aAdd( aLin, { "C7_QUANT"  , M->QTDBLOQ, Nil } )
						aAdd( aLin, { "C7_PRECO"  , SC7->C7_PRECO, Nil } )
						aAdd( aLin, { "C7_TOTAL"  , SC7->C7_PRECO * M->QTDBLOQ, Nil } )
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
			
		ElseIf oBrwPro:oBrowse:nColPos == nPosBlq .and. oBrwPro:aCols[oBrwPro:nAt][nPosBlq] == 0
			lReturn := .F.
		EndIf
		
	EndIf

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
	Local cLocais   := ""
	Local nQtd      := 0
	Local nAtu      := 0
	Local aInfPrd   := {}
	Local aPerAna   := {}
	Local nDUteis   := 0
	Local aAux      := {}
	local nX        := 0
	Local dIniPer   := Date()
	Local dAux      := Date()
	Local lFunIna   := .F.
	local nLeadTime := 0  as numeric
	local cLeadTime := "" as character
	
	Private aConfig  := {}
	Private cZB3     := "" as character
	Private cFormula := "" as character

	Default aParam := { "99","01" }
	
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
	Else
		Return ( Nil )
	EndIf
	
	// Monta string referente aos armazens que serão utilizados para somatório dos saldos dos produtos
	cFormula := AllTrim( SuperGetMv( 'MV_X_PNC01',,"" ) )
	aAux    := StrTokArr( AllTrim( aConfig[16] ), '/' )
	cLocais := ""
	For nX := 1 to Len( aAux )
		cLocais += PADR( AllTrim( aAux[nX] ), TAMSX3('B2_LOCAL')[01], ' ') + iif( nX == Len(aAux),'',"','" )
	Next nX
	//cLocais := AllTrim( SuperGetMv( 'MV_X997043',,' ' ) )
	
	// Verifica retorno vazio no conteúdo do parâmetro
	If Empty( cLocais )
		ConOut( FunName() + ' - ' + DtoC( Date() ) + ' - ' + Time() + ' - ' + 'LOCAIS DE ESTOQUE NAO DEFINIDOS NOS PARAMETROS DO PAINEL DE COMPRAS PARA A EMPRESA '+ cEmpAnt +' E FILIAL '+ cFilAnt +'!' )
		RESET ENVIRONMENT
		Return ( Nil )
	EndIf
	
	// Valida existência da função que analisa produtos pendentes de inativação
	lFunIna := ExistBlock( "GMPRDDES" )
	IF lFunIna
		ExecBlock( "GMPRDDES", .F., .F., Nil )
	EndIf
	
	// Verifica se o campo referente ao código de justificativa padrão já foi adicionado ao vetor de parâmetros
	if Len( aConfig ) >= 18 .and. !Empty( aConfig[18] )
		
		ConOut( "GMINDPRO - "+ Time() +" - JUSTIFICANDO NOTIFICACOES NAO TRATADAS DE DIAS ANTERIORES... " )
		
		cQuery := "UPDATE "+ RetSqlName( cZB3 ) +" SET "+ cZB3 +"_JUSTIF = '"+ aConfig[18] +"' "
		cQuery += "WHERE "+ cZB3 +"_FILIAL = '"+ FWxFilial( cZB3 ) +"' "
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
	
	// Consulta todos os produtos para exibilos no grid
	cQuery := "SELECT B1.B1_COD, B1.B1_DESC, B1.B1_UM, B1.B1_LM, B1.B1_QE, B1.B1_LE, B1.B1_PROC, " + CEOL
    cQuery += "       B1.B1_LOJPROC, B1.R_E_C_N_O_ RECSB1, " + CEOL
    
    cQuery += "       NVL( ( SELECT ROUND(( D1.D1_TOTAL - D1.D1_DESC ) / D1.D1_QUANT,2) VALNEG FROM "+ RetSqlName( 'SD1' ) +" D1 " + CEOL
    cQuery += "        WHERE D1.R_E_C_N_O_ = ( " + CEOL
    cQuery += "      SELECT MAX(D1.R_E_C_N_O_) FROM "+ RetSqlName( 'SD1' ) +" D1 " + CEOL
    cQuery += "      WHERE D1.D1_FILIAL  = '"+ xFilial( 'SD1' ) +"' " + CEOL
    cQuery += "        AND D1.D1_COD     = B1.B1_COD " + CEOL
    cQuery += "        AND D1.D1_FORNECE = B1.B1_PROC " + CEOL
    cQuery += "        AND D1.D1_LOJA    = B1.B1_LOJPROC " + CEOL
    cQuery += "        AND D1.D1_TIPO    = 'N' " + CEOL
    cQuery += "        AND D1.D_E_L_E_T_ = ' ') ), 0) ULTPRC, " + CEOL
    
    cQuery += "       NVL(( SELECT SUM(B2.B2_QATU) QTDATU FROM "+ RetSqlName( 'SB2' ) +" B2 " + CEOL
    cQuery += "             WHERE B2.B2_FILIAL  = '"+ xFilial( 'SB2' ) +"' " + CEOL
    cQuery += "               AND B2.B2_COD     = B1.B1_COD " + CEOL
    cQuery += "               AND B2.B2_LOCAL   IN ( '"+ cLocais +"' ) " + CEOL
    cQuery += "               AND B2.D_E_L_E_T_ = ' ' ),0 ) ESTOQUE, " + CEOL

    cQuery += "       NVL(( SELECT SUM(B2.B2_RESERVA + B2.B2_QEMP) EMPENHO FROM "+ RetSqlName( 'SB2' ) +" B2 " + CEOL
    cQuery += "             WHERE B2.B2_FILIAL  = '"+ xFilial( 'SB2' ) +"' " + CEOL
    cQuery += "               AND B2.B2_COD     = B1.B1_COD " + CEOL
    cQuery += "               AND B2.B2_LOCAL   IN ( '"+ cLocais +"' ) " + CEOL
    cQuery += "               AND B2.D_E_L_E_T_ = ' ' ),0) EMPENHO, " + CEOL
    
    cQuery += "       NVL( ( SELECT ROUND(AVG( TO_DATE(D1.D1_DTDIGIT,'YYYYMMDD')-TO_DATE(C7.C7_EMISSAO,'YYYYMMDD')),0) MEDIA FROM "+ RetSqlName( 'SD1' ) +" D1 " + CEOL

    cQuery += "              INNER JOIN "+ RetSqlName( 'SC7' ) +" C7 " + CEOL
    cQuery += "               ON C7.C7_FILIAL  = '"+ xFilial( 'SC7' ) +"' " + CEOL
    cQuery += "              AND C7.C7_NUM     = D1.D1_PEDIDO " + CEOL
    cQuery += "              AND C7.C7_ITEM    = D1.D1_ITEMPC " + CEOL
    cQuery += "              AND C7.D_E_L_E_T_ = ' ' " + CEOL

    cQuery += "              WHERE D1.D1_FILIAL  = '"+ xFilial( 'SD1' ) +"' " + CEOL
    cQuery += "                AND D1.D1_COD     = B1.B1_COD " + CEOL
    cQuery += "                AND D1.D1_FORNECE = B1.B1_PROC " + CEOL 
    cQuery += "                AND D1.D1_LOJA    = B1.B1_LOJPROC " + CEOL
	cQuery += "                AND D1.D1_DTDIGIT >= '"+ DtoS( Date()-DIAS_LT_FOR ) +"' " + CEOL
    cQuery += "                AND D1.D1_TES     <> ' ' " + CEOL
    cQuery += "                AND D1.D_E_L_E_T_ = ' ' ), 0 ) LEADTIME, " + CEOL
    
	// Identifica o lead-time do fornecedor
	if SA2->( FieldPos( 'A2_X_LTIME' ) ) > 0
		cQuery += " A2.A2_X_LTIME, "+ CEOL
	else
		cQuery += " 0 A2_X_LTIME, "+ CEOL
	endif

	cQuery += "       B1.B1_PE, " + CEOL
    cQuery += "       NVL( (SELECT SUM(C7.C7_QUANT - C7.C7_QUJE) EMPED FROM "+ RetSqlName( 'SC7' ) +" C7 " + CEOL
    cQuery += "               WHERE C7.C7_FILIAL  = '"+ xFilial( 'SC7' ) +"' " + CEOL
    cQuery += "                 AND C7.C7_PRODUTO = B1.B1_COD " + CEOL
    cQuery += "                 AND C7.C7_RESIDUO <> 'S' " + CEOL
    cQuery += "                 AND C7.C7_ENCER   <> 'E' " + CEOL
    cQuery += "                 AND C7.D_E_L_E_T_ = ' '), 0) QTDCOMP, " + CEOL

    cQuery += "       NVL( (SELECT MAX( C7.C7_DATPRF ) FROM "+ RetSqlName( 'SC7' ) +" C7 " + CEOL
    cQuery += "               WHERE C7.C7_FILIAL  = '"+ xFilial( 'SC7' ) +"' " + CEOL
    cQuery += "                 AND C7.C7_PRODUTO = B1.B1_COD " + CEOL
    cQuery += "                 AND C7.C7_RESIDUO <> 'S' " + CEOL
    cQuery += "                 AND C7.C7_ENCER   <> 'E' " + CEOL
    cQuery += "                 AND C7.D_E_L_E_T_ = ' '), '        ') PRVENT " + CEOL
    
    cQuery += "FROM "+ RetSqlName( 'SB1' ) +" B1 " + CEOL
    
    // Liga com fornecedor padrão do produto
    cQuery += "INNER JOIN "+ RetSqlName( 'SA2' ) +" A2 "+ CEOL
    cQuery += " ON A2.A2_FILIAL  = '"+ xFilial( 'SA2' ) +"' " + CEOL
    cQuery += "AND A2.A2_COD     = B1.B1_PROC " + CEOL
    cQuery += "AND A2.A2_LOJA    = B1.B1_LOJPROC " + CEOL
    cQuery += "AND A2.D_E_L_E_T_ = ' ' " + CEOL
    
    cQuery += "WHERE B1.B1_FILIAL  = '"+ xFilial( 'SB1' ) +"' " + CEOL
    cQuery += "  AND B1.B1_MSBLQL  <> '1' " + CEOL				// Faz leitura apenas dos itens ativos
    cQuery += "  AND B1.B1_MRP     = 'S' " + CEOL				// Apenas os produtos que devem entrar no MRP
    cQuery += "  AND B1.D_E_L_E_T_ = ' ' " + CEOL
	
	TcQuery cQuery New Alias 'PRDTMP'
	DBSelectArea( 'PRDTMP' )
	
	Count to nQtd
	
	PRDTMP->( DbGoTop() )
	
	ConOut( cQuery )
	
	If !PRDTMP->( EOF() )
		
		DbSelectArea( 'SB1' )
	    DbSelectArea( cZB3 )
	    (cZB3)->( DbSetOrder( 1 ) )
	    	
    	While !PRDTMP->( EOF() )
    		
    		nAtu++
    		ConOut( FunName() + ' - ' + DtoC( Date() ) + ' - ' + Time() + ' - ' + 'ANALISANDO PRODUTO '+ AllTrim( SubStr( PRDTMP->B1_DESC, 01, 30 ) ) +' ( '+ AllTrim( PRDTMP->B1_COD ) +' )' )
    		
			// Identifica lead-time conforme regra definida para produto, fornecedor (informado) ou fornecedor (calculado)
			if PRDTMP->B1_PE > 0
				nLeadTime := PRDTMP->B1_PE
				cLeadTime := 'P'		// Produto
			elseif PRDTMP->A2_X_LTIME > 0
				nLeadTime := PRDTMP->A2_X_LTIME
				cLeadTime := 'F'		// Fornecedor
			else
				nLeadTime := PRDTMP->LEADTIME
				cLeadTime := 'C'		// Calculado
			endif 

    		dDatInc := StoD( '20100101' )
    		nIndGir := 0
    		nConMed := 0
    		SB1->( DbGoTo( PRDTMP->RECSB1 ) )
    		if SB1->( Recno() ) != PRDTMP->RECSB1
    			ConOut( FunName() + ' - ' + DtoC( Date() ) + ' - ' + Time() + ' - ' + 'PRODUTO '+ AllTrim( SubStr( PRDTMP->B1_DESC, 01, 30 ) ) +' ( '+ AllTrim( PRDTMP->B1_COD ) +' ) NAO LOCALIZADO!' )
    			Loop
    		Else
    			dDatInc := CtoD( FWLeUserlg( 'B1_USERLGI', 2 ) )
    			
    			// Valida conteúdo retornado pelo log de usuários
    			if dDatInc < StoD( '20100101' )
    				dDatInc := StoD( '20100101' )
    			EndIf
    			
    			//ConOut( FunName() + ' - ' + DtoC( Date() ) + ' - ' + Time() + ' - ' + 'PRODUTO '+ AllTrim( SubStr( PRDTMP->B1_DESC, 01, 30 ) ) +' ( '+ AllTrim( PRDTMP->B1_COD ) +' ) CADASTRADO EM '+ DtoC( dDatInc ) )
    			
    	 		// Comando para leitura do índice de giro dos produtos
    			cQuery := "SELECT ROUND( ( NVL(( SELECT COUNT( DISTINCT C5.C5_NUM ) FROM "+ RetSqlName( 'SC5' ) +" C5 "+ CEOL
                cQuery += "         INNER JOIN "+ RetSqlName( 'SC6' ) +" C6 " + CEOL
                cQuery += "          ON C6.C6_FILIAL  = '"+ xFilial( 'SC6' ) +"' " + CEOL
                cQuery += "         AND C6.C6_NUM     = C5.C5_NUM " + CEOL
                cQuery += "         AND C6.C6_PRODUTO = '"+ PRDTMP->B1_COD +"' " + CEOL
                cQuery += "         AND C6.D_E_L_E_T_ = ' ' " + CEOL
                cQuery += "         WHERE C5.C5_FILIAL  = '"+ xFilial( 'SC5' ) +"' " + CEOL
                cQuery += "           AND C5.C5_EMISSAO >= '"+ DtoS( iif( aPerAna[01] > dDatInc, aPerAna[01], dDatInc ) ) +"' " + CEOL
				cQuery += "           AND C5.C5_CLIENTE <> '"+ PADR( SubStr( SM0->M0_CGC, 01, 08 ), TAMSX3('C5_CLIENTE')[1], ' ' ) +"' " + CEOL
                cQuery += "           AND C5.D_E_L_E_T_ = ' '  ),0) / " + CEOL 
                cQuery += "       NVL(( SELECT COUNT( DISTINCT C5.C5_NUM ) FROM "+ RetSqlName( 'SC5' ) +" C5 " + CEOL 
                cQuery += "         WHERE C5.C5_FILIAL  = '"+ xFilial( 'SC5' ) +"' " + CEOL
                cQuery += "           AND C5.C5_EMISSAO >= '"+ DtoS( iif( aPerAna[01] > dDatInc, aPerAna[01], dDatInc ) ) +"' " + CEOL
				cQuery += "           AND C5.C5_CLIENTE <> '"+ PADR( SubStr( SM0->M0_CGC, 01, 08 ), TAMSX3('C5_CLIENTE')[1], ' ' ) +"' " + CEOL
                cQuery += "           AND C5.D_E_L_E_T_ = ' ' ),1))*100, 6 ) INDGIRO FROM DUAL " + CEOL
                
                TcQuery cQuery New Alias 'INDPRO'
                DbSelectArea( 'INDPRO' )
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
    			
    			// Comando para leitura da média de venda de cada produto
    			cQuery := "SELECT ROUND( ( ( SELECT NVL( SUM(C6.C6_QTDVEN), 0) FROM "+ RetSqlName( 'SC6' ) +" C6 " + CEOL
                cQuery += "       INNER JOIN "+ RetSqlName( 'SC5' ) +" C5 " + CEOL 
                cQuery += "         ON C5.C5_FILIAL  = '"+ xFilial( 'SC5' ) +"' " + CEOL 
                cQuery += "       AND C5.C5_NUM     = C6.C6_NUM " + CEOL
                cQuery += "       AND C5.C5_EMISSAO >= '"+ DtoS( iif( aPerAna[01] > dDatInc, aPerAna[01], dDatInc ) ) +"' " + CEOL
                cQuery += "       AND C5.C5_TIPO    = 'N' " + CEOL
				cQuery += "       AND C5.C5_CLIENTE <> '"+ PADR(SubStr( SM0->M0_CGC, 01, 08 ),TAMSX3('C5_CLIENTE')[1], ' ' ) +"' " + CEOL
                cQuery += "       AND C5.D_E_L_E_T_ = ' ' " + CEOL

				// Liga com cadastro de TES para considerar apenas os pedidos que movimentariam estoque
				cQuery += "       INNER JOIN "+ RetSqlName( 'SF4' ) +" F4 "+ CEOL
				cQuery += "        ON F4.F4_FILIAL  = '"+ xFilial( 'SF4' ) +"' " + CEOL
				cQuery += "       AND F4.F4_CODIGO  = C6.C6_TES " + CEOL
				cQuery += "       AND F4.F4_ESTOQUE = 'S' " + CEOL					// Apenas tes que atualiza estoque
				cQuery += "       AND F4.D_E_L_E_T_ = ' ' " + CEOL

                cQuery += "       WHERE C6.C6_FILIAL  = '"+ xFilial( 'SC6' ) +"' " + CEOL
                cQuery += "         AND C6.C6_PRODUTO = '"+ PRDTMP->B1_COD +"' " + CEOL			
				cQuery += "         AND C6.D_E_L_E_T_ = ' ' ) + " + CEOL
       
                cQuery += "       ( SELECT NVL( SUM( L2.L2_QUANT ),0) FROM "+ RetSqlName( 'SL2' ) +" L2 " + CEOL
        
                cQuery += "        INNER JOIN "+ RetSqlName( 'SL1' ) +" L1 " + CEOL
                cQuery += "         ON L1.L1_FILIAL  = '"+ xFilial( 'SL1' ) +"' " + CEOL
                cQuery += "        AND L1.L1_NUM     = L2.L2_NUM " + CEOL
                cQuery += "        AND (L1.L1_NROPCLI LIKE '%VA%' OR L1.L1_NROPCLI = '"+ Space( TAMSX3('L1_NROPCLI')[01] ) +"') " + CEOL
                cQuery += "        AND L1.L1_EMISSAO >= '"+ DtoS( iif( aPerAna[01] > dDatInc, aPerAna[01], dDatInc ) ) +"' " + CEOL
				cQuery += "        AND L1.L1_CLIENTE <> '"+ PADR(SubStr( SM0->M0_CGC, 01, 08 ),TAMSX3('L1_CLIENTE')[1], ' ' ) +"' " + CEOL
                cQuery += "        AND L1.D_E_L_E_T_ = ' ' " + CEOL
        
                cQuery += "        WHERE L2.L2_FILIAL  = '"+ xFilial( 'SL2' ) +"' " + CEOL
                cQuery += "          AND L2.L2_PRODUTO = '"+ PRDTMP->B1_COD +"' " + CEOL
                cQuery += "          AND L2.D_E_L_E_T_ = ' ' ) ) / "+ AllTrim( cValToChar( iif( nDUteis == 0, 1, 0 ) ) ) +", 4) MEDIA " + CEOL
                cQuery += "FROM DUAL " + CEOL
    			
    			TcQuery cQuery New Alias 'MEDCON'
    			DbSelectArea( 'MEDCON' )
    			
    			if !MEDCON->( EOF() ) .and. MEDCON->MEDIA != 0
    				nConMed := MEDCON->MEDIA
    			Else
    				nConMed := 0.0001
    			EndIf
    			MEDCON->( DbCloseArea() )
    			
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
						 PRDTMP->B1_LE /* nLotEco */ }
    		
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
				( cZB3 )->( FieldPut( FieldPos( cZB3 +'_FILIAL' ), xFilial( cAB3 ) ) )
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
    			(cZB3)->( MsUnlock() )
    		EndIf
    		
    		PRDTMP->( DbSkip() )
    	EndDo
    EndIf
    
    PRDTMP->( DbCloseArea() )
	
	// Prepara desconexão da rotina automática
	if cEmpAnt != Nil .and. cFilAnt != Nil
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
	
	nDias   := aInfPrd[1]
	nLdTime := aInfPrd[2]
	nPrjEst := aInfPrd[3]
	nConMed := aInfPrd[4]
	nLotMin := aInfPrd[5]
	nQtdEmb := aInfPrd[6]
	nLotEco := aInfPrd[7]

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
| Fonte: GMPAICOM | Funcao:  fSortGrd       | Autor: Jean Carlos P. Saggin    |  Data: 24.07.2019 |
+-----------------+-------------------------+---------------------------------+-------------------+
| Descricao: Funçao para ordenar os dados do grid de acordo com a opção selecionada através do    |
|            componente de ordenação                                                              |
+-------------------------------------------------------------------------------------------------+
| Parametros recebidos: aInfPrd                                                                   |
| [1] nDias.....: Quantidade de dias em que se pretende manter o estoque                          |
| [2] nLdTime...: Lead-Time médio do produto (ou o que estiver definido no cadastro)              |
| [3] nPrjEst...: Quantidade de tempo previsto para duração do estoque atual (em dias)            |
| [4] nConMed...: Consumo média/dia do produto em questão                                         |
| [5] nLotMin...: Lote mínimo de compra para o produto                                            |
| [6] nQtdEmb...: Qtde que vem na embalagem (quando tiver informação a quantidade calculada será  |
|                 sempre múltipla desse número. )                                                 |
+-------------------------------------------------------------------------------------------------+
| Retorno da funcao: nQtdCom (quantidade sugerida para compra)                                    |
+-------------------------------------------------------------------------------------------------+  
*/
Static Function fSortGrd()
	
	Local aColTmp := {}
	Local nOpcOrd := 0
	Local cExpOrd := ""
	
	If oBrwPro != Nil .and. Len( oBrwPro:aCols ) > 0
		aColTmp := oBrwPro:aCols
		
		if !Empty( cCboOrd )
			
			nOpcOrd := Val( cCboOrd )
		    
		    // Ordena o vetor com os dados dos produtos de acordo com o critério definido no painel
		    cExpOrd := 'x[nOpcOrd] ' + iif( cCboExi == 'A..Z', '<', '>' ) + ' y[nOpcOrd]'
		    aSort( aColTmp,,,{|x,y| &( cExpOrd ) } )
	    EndIf
		
		// Atualiza os componentes visuais
		oBrwPro:aCols := aClone( aColTmp )
		oBrwPro:ForceRefresh()
		oDlgCom:Refresh()
		
	EndIf
	
Return ( Nil )

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
	local lInc    := GetMv( 'MV_X_PNC01', .T. /* lCheck */ ) 	
	
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
	 
	aAdd( aVar, { 'Sld. Prod.' , 'PRDTMP->ESTOQUE' } )
	aAdd( aVar, { 'Empenhado'  , 'PRDTMP->EMPENHO' } )
	aAdd( aVar, { 'Dias Pret.' , 'nDias'           } )
	aAdd( aVar, { 'L-Time'     , 'nLdTime'         } )
	aAdd( aVar, { 'Dura. Est.' , 'nPrjEst'         } )
	aAdd( aVar, { 'Cons. Med.' , 'nConMed'         } )
	aAdd( aVar, { 'Lote Min.'  , 'nLotMin'         } )
	aAdd( aVar, { 'Qtde Emb.'  , 'nQtdEmb'         } )
	aAdd( aVar, { 'Qtde Comp.' , 'PRDTMP->QTDCOMP' } )
	
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
@since 7/30/2019
/*/
Static Function fCarCom()
	
	Local oBtnCan
	Local oBtnCon
	Local oCboFrt
	Local oContat
	Local oFntTot := TFont():New("Consolas",,018,,.T.,,,,,.F.,.F.)
	Local oLblGer := TFont():New("Arial Narrow",,014,,.F.,,,,,.F.,.F.)
	Local oGetCon
	Local oGetDes
	Local oGetEmi
	Local oGetFor
	Local oGetLoj
	Local oGetMai
	Local oGetPed
	Local oGrpGer
	Local oLbCont
	Local oLblEmi
	Local oLblFor
	Local oLblFrt 
	Local nX        := 0
	Local aHeaderEx := {}
	Local aFields   := {"C7_PRODUTO","C7_DESCRI","C7_UM","QUANT","PRECO","TOTAL","DINICOM","DATPRF","C7_LOCAL","OBS","C7_CC","C7_IPI"}
	Local cTitulo   := ""
	Local lOk       := .F.
	
	Private aAlter  := {"QUANT","PRECO","TOTAL","DINICOM","DATPRF"}
	Private dGetEmi := Date()
	Private cGetLoj := Space( TAMSX3( 'C7_LOJA' )[01] )
	Private cGetFor := Space( TAMSX3( 'C7_FORNECE' )[01] )
	Private cContat := Space( TAMSX3( 'C7_CONTATO' )[01] )
	Private cGetMai := Space( TAMSX3( 'A2_EMAIL' )[01] )
	Private cGetCon := Space( TAMSX3( 'C7_COND' )[01] )
	Private cGetDes := Space( TAMSX3( 'E4_DESCRI' )[01] )
	Private oBrwCar := Nil
	Private cGetPed := Space( TAMSX3( 'C7_NUM' )[01] )
	Private oLblMai := Nil
	Private oLblTot := Nil
	Private oLblNum	:= Nil
	Private oLblCnd := Nil
	Private oTotal  := Nil
	Private oDlgCar := Nil
	Private nPosTot := nPosCod := nPosQua := nPosQua := nPosPrc := 0
	Private cCboFrt := 'C'
	
	// Seta um hot key no Ctrl + R
	SetKey( K_CTRL_R, {|| fReplica() } )
	
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
	
	cGetFor := ""
	cGetLoj := ""
	For nX := 1 to Len( aCarCom )
		if !aCarCom[ nX ][Len( aHeaderEx )+1]
			if nX == 1
				cGetFor := RetField( 'SB1', 1, xFilial( 'SB1' ) + aCarCom[nX][nPosCod], 'B1_PROC' )
				cGetLoj := RetField( 'SB1', 1, xFilial( 'SB1' ) + aCarCom[nX][nPosCod], 'B1_LOJPROC' )
			ElseIf cGetFor != RetField( 'SB1', 1, xFilial( 'SB1' ) + aCarCom[nX][nPosCod], 'B1_PROC' ) .or.; 
			       cGetLoj != RetField( 'SB1', 1, xFilial( 'SB1' ) + aCarCom[nX][nPosCod], 'B1_LOJPROC' ) 
				cGetFor := Space( TAMSX3( 'C7_FORNECE' )[01] )
				cGetLoj := Space( TAMSX3( 'C7_LOJA' )[01] )
			EndIf
		EndIf
	Next nX
	
	cGetCon := RetField( 'SA2', 1, xFilial( 'SA2' ) + cGetFor + cGetLoj, 'A2_COND' )
	cGetDes := RetField( 'SE4', 1, xFilial( 'SE4' ) + cGetCon, 'E4_DESCRI' )
	cGetMai := RetField( 'SA2', 1, xFilial( 'SA2' ) + cGetFor + cGetLoj, 'A2_EMAIL' )
	cContat := RetField( 'SA2', 1, xFilial( 'SA2' ) + cGetFor + cGetLoj, 'A2_CONTATO' )
	cTitulo := "CARRINHO DE COMPRAS" + iif( !Empty( cGetFor ), " - " + AllTrim( RetField( 'SA2', 1, xFilial( 'SA2' ) + cGetFor + cGetLoj, 'A2_NOME' ) ), '' )    
	
	// Ordena os produtos do carrinho por nome do produto
	aSort( aCarCom,,,{|x,y| x[2] < y[2] } )	

	DEFINE MSDIALOG oDlgCar TITLE cTitulo FROM 000, 000  TO 500, 1100 COLORS 0, 16777215 PIXEL

    @ 002, 002 GROUP oGrpGer TO 248, 550 OF oDlgCar COLOR 0, 16777215 PIXEL
    
    @ 014, 005 MSGET oGetPed VAR cGetPed SIZE 055, 011 OF oDlgCar COLORS 0, 16777215 WHEN .F. PIXEL
    @ 014, 067 MSGET oGetEmi VAR dGetEmi SIZE 055, 011 OF oDlgCar COLORS 0, 16777215 WHEN .T. PIXEL
    @ 014, 129 MSGET oGetCon VAR cGetCon SIZE 028, 011 OF oDlgCar COLORS 0, 16777215 VALID fValCon() WHEN .T. F3 "SE4" PIXEL
    @ 014, 159 MSGET oGetDes VAR cGetDes SIZE 079, 011 OF oDlgCar COLORS 0, 16777215 WHEN .F. PIXEL
    @ 014, 244 MSGET oGetFor VAR cGetFor SIZE 053, 011 OF oDlgCar COLORS 0, 16777215 VALID fValFor() WHEN .T. F3 "SA2" PIXEL
    @ 014, 298 MSGET oGetLoj VAR cGetLoj SIZE 029, 011 OF oDlgCar COLORS 0, 16777215 WHEN .F. PIXEL
    @ 014, 335 MSGET oGetMai VAR cGetMai SIZE 104, 011 OF oDlgCar COLORS 0, 16777215 VALID fMailFor() WHEN .T. PIXEL
    @ 014, 442 MSGET oContat VAR cContat SIZE 060, 011 OF oDlgCar COLORS 0, 16777215 VALID fContFor() WHEN .T. PIXEL
    
    @ 006, 006 SAY oLblNum PROMPT "Num.Ped."               SIZE 037, 007 OF oDlgCar FONT oLblGer COLORS 0, 16777215 PIXEL
    @ 006, 067 SAY oLblEmi PROMPT "Dt. Emissão:"           SIZE 041, 007 OF oDlgCar FONT oLblGer COLORS 0, 16777215 PIXEL
    @ 006, 129 SAY oLblCnd PROMPT "Condição de Pagamento:" SIZE 074, 007 OF oDlgCar FONT oLblGer COLORS 0, 16777215 PIXEL
    @ 006, 244 SAY oLblFor PROMPT "Fornecedor:"            SIZE 044, 007 OF oDlgCar FONT oLblGer COLORS 0, 16777215 PIXEL
    @ 006, 335 SAY oLblMai PROMPT "E-mail Forn."           SIZE 050, 007 OF oDlgCar FONT oLblGer COLORS 0, 16777215 PIXEL
    @ 006, 443 SAY oLbCont PROMPT "Contato:"               SIZE 025, 007 OF oDlgCar FONT oLblGer COLORS 0, 16777215 PIXEL
    @ 235, 005 SAY oLblFrt PROMPT "Tp. Frete: "            SIZE 029, 007 OF oDlgCar FONT oLblGer COLORS 0, 16777215 PIXEL
    @ 235, 325 SAY oLblTot PROMPT "Total Ped.: "           SIZE 035, 007 OF oDlgCar FONT oLblGer COLORS 0, 16777215 PIXEL
    @ 235, 356 SAY oTotal  PROMPT " "                      SIZE 050, 011 OF oDlgCar FONT oFntTot COLORS 16711680, 16777215 PIXEL
    
    oBrwCar := MsNewGetDados():New( 030, 004, 231, 547, GD_DELETE+GD_UPDATE, "AllwaysTrue", "AllwaysTrue", "", aAlter,, Len( aCarCom ), "U_FMANCAR", "", "AllwaysTrue", oDlgCar, aHeaderEx, aCarCom )
    oBrwCar:oBrowse:bChange := {|| fChgCar() }
    oBrwCar:oBrowse:bDelOk := {|| fBrwDel() }
    
    @ 233, 030 MSCOMBOBOX oCboFrt VAR cCboFrt ITEMS {"C=Cif","F=Fob","S=Sem Frete"} SIZE 050, 014 OF oDlgCar COLORS 0, 16777215 ON CHANGE {|| fChgCar() } PIXEL
    
    @ 232, 450 BUTTON oBtnCon PROMPT "&Continuar" SIZE 048, 013 OF oDlgCar ACTION Processa( { || lOk := fGrvPed(), iif( lOk, oDlgCar:End(), Nil ) }, 'Aguarde!','Incluindo pedido de compra!' ) WHEN fValPed() PIXEL
    @ 232, 499 BUTTON oBtnCan PROMPT "&Cancelar" SIZE 048, 013 OF oDlgCar ACTION oDlgCar:End() PIXEL
    
    ACTIVATE MSDIALOG oDlgCar CENTERED
	
	if lOk
		// Se realizou inclusão do pedido de compra, manda atualizar todo o grid do painel
		aCarCom := {}
		if Len( aCarCom ) > 0
			// @qui... tratativa para tratar de forma parcial os carrinhos de compra
		EndIf
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
	
	Private lMsErroAuto := .F.
	
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
			
			aAdd( aIte, aClone( aLin ) )
			aLin := {}
			
		EndIf
		
	Next nX
	
	lMsErroAuto := .F.
	MATA120( 1, aCab, aIte, 3 )
	
	if lMsErroAuto
		MostraErro()
	Elseif MsgYesNo( 'Pedido de compra número <b>'+ SC7->C7_NUM +'</b> gerado com sucesso! Deseja realizar a impressão do pedido?','S U C E S S O ! Pedido Nro. '+ SC7->C7_NUM +'' )
		GMPCPrint( SC7->C7_NUM )
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

/*
+-----------------+-------------------------+---------------------------------+-------------------+
| Fonte: GMPAICOM | Funcao:  fValPed        | Autor: Jean Carlos P. Saggin    |  Data: 31.07.2019 |
+-----------------+-------------------------+---------------------------------+-------------------+
| Descricao: Valida os dados da tela do carrinho de compra                                        |
+-------------------------------------------------------------------------------------------------+
| Parametros recebidos: Nil                                                                       |
+-------------------------------------------------------------------------------------------------+
| Retorno da funcao: lRet (.T.=Prossegue ou .F.=Bloqueia)                                         |
+-------------------------------------------------------------------------------------------------+  
*/
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

/*
+-----------------+-------------------------+---------------------------------+-------------------+
| Fonte: GMPAICOM | Funcao:  FMANCAR        | Autor: Jean Carlos P. Saggin    |  Data: 30.07.2019 |
+-----------------+-------------------------+---------------------------------+-------------------+
| Descricao: Valid ao executar alteração em qualquer campo do aCols                               |
+-------------------------------------------------------------------------------------------------+
| Parametros recebidos: Nil                                                                       |
+-------------------------------------------------------------------------------------------------+
| Retorno da funcao: Nil                                                                          |
+-------------------------------------------------------------------------------------------------+  
*/
User Function FMANCAR()
	
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
	EndIf
	
	fChgCar()
	
Return ( .T. )

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
Static Function fChgCar()
	
	Local nAux    := 0
	
	// Valida se existe conteúdo no aCols antes de prosseguir
	if oBrwCar != Nil .and. Len( oBrwCar:aCols ) > 0
		nAux := 0
		aEval( oBrwCar:aCols, {|x| nAux += iif( !x[ Len(oBrwCar:aHeader)+1], x[nPosTot], 0 ) } )
		oTotal:CCAPTION := AllTrim( Transform( nAux, "@E 9,999,999.99" ) )
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

/*/{Protheus.doc} q																												qe
Função chamada quando o sistema perceber qualquer alteração em um dos campos da tela
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 14/08/2024
/*/
static function someChange( lReset )
	
	local cVar := upper(ReadVar())		
	
	default lReset := .F.

	// Entrada
	nGetUNF := iif( lReset, ( SD1TMP->D1_TOTAL - SD1TMP->D1_VALDESC ) / SD1TMP->D1_QUANT, nGetUNF )
	cGetTES := SD1TMP->D1_TES
	cGetDTE := RetField( 'SF4', 1, FWxFilial( 'SF4' ) + SD1TMP->D1_TES, 'F4_TEXTO' )
	nGetICM := SD1TMP->D1_PICM
	nValICM := SD1TMP->D1_VALICM / SD1TMP->D1_QUANT
	nGetIPI := SD1TMP->D1_IPI
	nValIPI := SD1TMP->D1_VALIPI / SD1TMP->D1_QUANT
	nValBFr := ( SD1TMP->D1_TOTAL-SD1TMP->D1_VALFRE ) / SD1TMP->D1_QUANT
	nGetBFr := 100
	nGetFre := ( SD1TMP->D1_VALFRE / ( SD1TMP->D1_TOTAL - SD1TMP->D1_VALDESC )) * 100
	nValFre := ((nGetBFr/100)*nValBFr)*(nGetFre/100)
	nGetICF := 0
	nValICF := 0
	nGetOut := (SD1TMP->D1_DESPESA/(SD1TMP->D1_TOTAL-SD1TMP->D1_VALDESC)) * 100
	nValOut := SD1TMP->D1_DESPESA / SD1TMP->D1_QUANT
	nGetFin := (SD1TMP->VALFIN / ( SD1TMP->D1_TOTAL - SD1TMP->D1_VALDESC )) * 100
	nValFin := SD1TMP->VALFIN / SD1TMP->D1_QUANT
	nGetPC  := SD1TMP->D1_ALQIMP5 + SD1TMP->D1_ALQIMP6
	nValPC  := ( SD1TMP->D1_VALIMP5 + SD1TMP->D1_VALIMP6 ) / SD1TMP->D1_QUANT
	nGetST  := iif( SD1TMP->D1_ICMSRET > 0, SD1TMP->D1_ALIQSOL, 0 )
	nValST  := SD1TMP->D1_ICMSRET / SD1TMP->D1_QUANT
	nGetMVA := SD1TMP->D1_MARGEM
	nGetCuL := SD1TMP->D1_CUSTO / SD1TMP->D1_QUANT
	nGetCuM := RetField( 'SB2', 1, SD1TMP->D1_FILIAL + SD1TMP->D1_COD + SD1TMP->D1_LOCAL, 'B2_CM1' )

	// Saída


	oDlgDoc:Refresh()
return nil

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
						.F.,.F.,/* bChange */,!lEnable,.F.,,cVar,,,,.T.,.F.,,cLbPad, 2, oFont, CLR_BLUE )
	oGet:bChange := {|| someChange() }
	oGet:bWhen   := {|| lEnable }
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

