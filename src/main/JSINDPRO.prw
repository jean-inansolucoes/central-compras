#include 'totvs.ch'
#include 'topconn.ch'

#define CEOL chr(13)+chr(10)

/*/{Protheus.doc} JSINDPRO
Função para visualizar e recalcular manualmente os índices de produtos para o Painel de Compras.
A partir da migração da tabela de índices para fora do dicionário de dados (PNC_PROD_<empresa>), a
visualização deixou de usar AxCadastro (dependente de SX2/SX3) e passou a usar uma grid própria.
@type function
@version 20.0005
@author Jean Carlos Pandolfo Saggin
@since 11/20/2024
/*/
User Function JSINDPRO()

    Local aArea    := getArea()
    Local cTabPrd  := "PNC_PROD_"+ cEmpAnt
    Local aSize    := MsAdvSize()
    Local nDlgHei  := aSize[06] * 0.9
    Local nDlgWid  := aSize[05] * 0.9
    Local nAreaHei := ( aSize[06] / 2 ) * 0.9
    Local nAreaWid := ( aSize[05] / 2 ) * 0.9
    Local cSearch  := Space( TAMSX3('B1_DESC')[1] )
    Local oDlgInd  as object
    Local oGrpTop  as object
    Local oGrpBrw  as object
    Local oLblSrc  as object
    Local oGetSrc  as object
    Local oBtnSrc  as object
    Local oBrowse  as object
    Local bOk      as codeblock
    Local bCancel  as codeblock

    Private cCadastro := "SmartSupply - Índices de Produtos - "+ U_JSGETVER()
    Private aDados    := {}

    // Valida existência da tabela de índices por produto (fora do dicionário de dados)
    if ! TCCanOpen( cTabPrd )
        Hlp( 'PNC_PROD',;
             'Tabela de índices por produto ('+ cTabPrd +') ainda não foi criada ou está desatualizada!',;
             'Acesse o assistente de configuração (U_JSGLBPAR), avance até a etapa Dicionário de Dados e conclua para criar/atualizar a estrutura' )
        Return Nil
    endif

    aDados := getInfo( cTabPrd, cSearch )

    bOk     := {|| Processa( {|| U_GMINDPRO(),;
                                 aDados := getInfo( cTabPrd, cSearch ),;
                                 oBrowse:SetArray( aDados ),;
                                 oBrowse:UpdateBrowse( .T. ) }, 'Recalculando índices para os produtos do MRP', 'Aguarde!' ), .T. }
    bCancel := {|| oDlgInd:End() }

    DEFINE MSDIALOG oDlgInd TITLE OemToAnsi( cCadastro ) FROM 000, 000 TO nDlgHei, nDlgWid COLORS 0, 16777215 PIXEL

    // Área superior (altura fixa) - inicia a 35 pixels do topo para não sobrepor a EnchoiceBar
    // (que ocupa os primeiros 30 pixels do diálogo); largura/altura internas na proporção
    // halved (aSize/2) usada em GMPAICOM.prw para os demais componentes de tela
    @ 035, 010 GROUP oGrpTop TO 135, nAreaWid-10 OF oDlgInd COLOR 0, 16777215 PIXEL

    @ 040, 020 SAY oLblSrc PROMPT "Pesquise pelo código ou parte do nome do produto desejado" SIZE 350, 008 OF oGrpTop PIXEL
    @ 054, 020 MSGET oGetSrc VAR cSearch SIZE 150, 012 OF oGrpTop PICTURE "@!" PIXEL
    @ 052, 178 BUTTON oBtnSrc PROMPT "Pesquisar" SIZE 050, 014 OF oGrpTop ACTION {|| aDados := getInfo( cTabPrd, cSearch ),;
                                                                                    oBrowse:SetArray( aDados ),;
                                                                                    oBrowse:UpdateBrowse( .T. ) } PIXEL

    // Área inferior (restante da tela) - apenas o container do grid de índices
    @ 140, 010 GROUP oGrpBrw TO nAreaHei-10, nAreaWid-10 OF oDlgInd COLOR 0, 16777215 PIXEL

    oBrowse := FWBrowse():New( oGrpBrw )
    oBrowse:SetDataArray()
    oBrowse:SetArray( aDados )
    oBrowse:SetColumns( getCols() )
    oBrowse:DisableConfig()
    oBrowse:DisableReport()
    oBrowse:Activate()

    ACTIVATE MSDIALOG oDlgInd CENTERED ON INIT EnchoiceBar( oDlgInd, bOk, bCancel )

    restArea( aArea )

return Nil

/*/{Protheus.doc} getInfo
Consulta os dados atualmente materializados na tabela de índices por produto (PNC_PROD_<empresa>),
com a descrição do produto (SB1), para exibição na tela de visualização. Restringe o resultado à
data do último cálculo (parâmetro interno MV_X_PNC12) e, quando informado, filtra por código ou
parte da descrição do produto.
@type function
@version 20.0005
@author Jean Carlos Pandolfo Saggin
@since 11/20/2024
@param cTabPrd, character, nome da tabela de índices por produto
@param cSearch, character, código ou parte do nome do produto para filtrar o resultado (opcional)
@return array, aDados
/*/
static function getInfo( cTabPrd, cSearch )

    local aRet     := {} as array
    local cQuery   := "" as character
    local cAlias   := "" as character
    local dDtCalc  as date
    local cBusca   := "" as character

    default cSearch := ""

    // Data do último cálculo dos índices (mesmo parâmetro/padrão usado em GMPAICOM.prw)
    dDtCalc := CtoD( SubStr( GetMv( 'MV_X_PNC12',,DtoC(date()) ), 01, 10 ) )
    cBusca  := AllTrim( Upper( cSearch ) )

    cQuery := "SELECT " + CEOL
    cQuery += "PNC.FILIAL, PNC.PROD, B1.B1_DESC, PNC.DTREF, PNC.SALDO, PNC.CONMED, PNC.NECCOM, " + CEOL
    cQuery += "PNC.QTDCOM, PNC.QTDEMP, PNC.PRJEST, PNC.LDTIME, PNC.TMPGIR, PNC.TPDIAS, PNC.INDINC, " + CEOL
    cQuery += "PNC.PRVENT, PNC.CM03M, PNC.CM06M, PNC.CM12M, PNC.CMANT, PNC.AVISO, PNC.MSG, PNC.JUSTIF " + CEOL
    cQuery += "FROM "+ cTabPrd +" PNC " + CEOL
    cQuery += "INNER JOIN "+ RetSqlName( 'SB1' ) +" B1 " + CEOL
    cQuery += " ON B1.B1_FILIAL  = '"+ FWxFilial( 'SB1' ) +"' " + CEOL
    cQuery += "AND B1.B1_COD     = PNC.PROD " + CEOL
    cQuery += "AND B1.D_E_L_E_T_ = ' ' " + CEOL
    cQuery += "WHERE PNC.FILIAL  = '"+ cFilAnt +"' " + CEOL
    cQuery += "  AND PNC.DTREF   = '"+ DtoS( dDtCalc ) +"' " + CEOL
    if ! Empty( cBusca )
        cQuery += "  AND ( B1.B1_COD LIKE '%"+ cBusca +"%' OR Upper( B1.B1_DESC ) LIKE '%"+ cBusca +"%' ) " + CEOL
    endif
    cQuery += "  AND PNC.D_E_L_E_T_ = ' ' " + CEOL
    cQuery += "ORDER BY PNC.DTREF DESC, B1.B1_DESC " + CEOL

    cAlias := GetNextAlias()
    DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), cAlias, .F., .T. )

    // Garante a tipagem correta das colunas de data no resultado da consulta (mesmo padrão já
    // utilizado para a leitura de eventos pendentes em GMPAICOM.prw)
    TcSetField( cAlias, 'DTREF' , 'D' )
    TcSetField( cAlias, 'PRVENT', 'D' )

    ( cAlias )->( DbGoTop() )
    while ! ( cAlias )->( EOF() )
        aAdd( aRet, {     ( cAlias )->FILIAL,;
                          AllTrim( ( cAlias )->PROD ),;
                          AllTrim( ( cAlias )->B1_DESC ),;
                          ( cAlias )->DTREF,;
                          ( cAlias )->SALDO,;
                          ( cAlias )->CONMED,;
                          ( cAlias )->NECCOM,;
                          ( cAlias )->QTDCOM,;
                          ( cAlias )->QTDEMP,;
                          ( cAlias )->PRJEST,;
                          ( cAlias )->LDTIME,;
                          ( cAlias )->TMPGIR,;
                          ( cAlias )->TPDIAS,;
                          ( cAlias )->INDINC,;
                          ( cAlias )->PRVENT,;
                          ( cAlias )->CM03M,;
                          ( cAlias )->CM06M,;
                          ( cAlias )->CM12M,;
                          ( cAlias )->CMANT,;
                          ( cAlias )->AVISO,;
                          AllTrim( ( cAlias )->MSG ),;
                          AllTrim( ( cAlias )->JUSTIF ) } )
        ( cAlias )->( DBSkip() )
    enddo
    ( cAlias )->( DBCloseArea() )

return aRet

/*/{Protheus.doc} getCols
Monta as colunas da grid de visualização dos índices por produto, na mesma ordem retornada por getDados
(vetor Private aDados). Os tamanhos/decimais são os mesmos definidos em U_JSGETSTR para PNC_PROD_<empresa>,
exceto Filial e Produto, resolvidos dinamicamente para respeitar o dicionário de cada ambiente.
@type function
@version 20.0004
@author Jean Carlos Pandolfo Saggin
@since 11/20/2024
@return array, aColumns
/*/
static function getCols()

    local aColumns := {} as array
    local aDef     := {} as array
    local nX       := 0 as numeric

    // { Titulo, Tipo, Tamanho, Decimal, Picture }
    aAdd( aDef, { "Filial"      , "C", len( cFilAnt )       , 0, "@!"                  } )
    aAdd( aDef, { "Produto"     , "C", TAMSX3('B1_COD')[1]  , 0, "@!"                  } )
    aAdd( aDef, { "Descricao"   , "C", TAMSX3('B1_DESC')[1] , 0, "@!"                  } )
    aAdd( aDef, { "Data"        , "D", 8                    , 0, "@D"                  } )
    aAdd( aDef, { "Saldo"       , "N", 12                   , 2, "@E 999,999,999.99"   } )
    aAdd( aDef, { "Cons.Medio"  , "N", 14                   , 4, "@E 999,999,999.9999" } )
    aAdd( aDef, { "Nec.Compra"  , "N", 12                   , 2, "@E 999,999,999.99"   } )
    aAdd( aDef, { "Qtd.Comprada", "N", 12                   , 2, "@E 999,999,999.99"   } )
    aAdd( aDef, { "Qtd.Empenho" , "N", 12                   , 2, "@E 999,999,999.99"   } )
    aAdd( aDef, { "Proj.Estoque", "N", 3                    , 0, "@E 999"              } )
    aAdd( aDef, { "Lead Time"   , "N", 3                    , 0, "@E 999"              } )
    aAdd( aDef, { "Temp.Giro"   , "N", 3                    , 0, "@E 999"              } )
    aAdd( aDef, { "Tipo Dia"    , "C", 1                    , 0, "@!"                  } )
    aAdd( aDef, { "Ind.Giro"    , "N", 10                   , 6, "@E 999.999999"       } )
    aAdd( aDef, { "Prev.Entrega", "D", 8                    , 0, "@D"                  } )
    aAdd( aDef, { "Media 3M"    , "N", 14                   , 4, "@E 999,999,999.9999" } )
    aAdd( aDef, { "Media 6M"    , "N", 14                   , 4, "@E 999,999,999.9999" } )
    aAdd( aDef, { "Media 12M"   , "N", 14                   , 4, "@E 999,999,999.9999" } )
    aAdd( aDef, { "Media Ant."  , "N", 14                   , 4, "@E 999,999,999.9999" } )
    aAdd( aDef, { "Aviso?"      , "C", 1                    , 0, "@!"                  } )
    aAdd( aDef, { "Mensagem"    , "C", 60                   , 0, "@x"                  } )
    aAdd( aDef, { "Justif."     , "C", 3                    , 0, "@!"                  } )

    for nX := 1 to len( aDef )
        aAdd( aColumns, FWBrwColumn():New() )
        aColumns[len(aColumns)]:SetTitle( aDef[nX][1] )
        aColumns[len(aColumns)]:SetType( aDef[nX][2] )
        aColumns[len(aColumns)]:SetSize( aDef[nX][3] )
        aColumns[len(aColumns)]:SetDecimal( aDef[nX][4] )
        aColumns[len(aColumns)]:SetPicture( aDef[nX][5] )
        aColumns[len(aColumns)]:SetData( &( "{|oBrw| aDados[oBrw:At()]["+ cValToChar( nX ) +"] }" ) )
    next nX

return aColumns

/*/{Protheus.doc} JSINDMAN
Função responsável pelo recálculo manual dos índices de produtos
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/20/2024
@return logical, lSuccess
/*/
User Function JSINDMAN()
    local lSuccess := .F. as logical
    Processa({|| U_GMINDPRO() }, 'Recalculando índices para os produtos do MRP', 'Aguarde!'  )
    lSuccess := .T.
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
