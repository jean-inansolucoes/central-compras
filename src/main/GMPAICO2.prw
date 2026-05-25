#include 'totvs.ch'
#include 'topconn.ch'

#define CEOL CHR( 13 ) + CHR( 10 )     // ENTER

/*/{Protheus.doc} JSSHOWOP
Função para exibição das Ordens de Produção em aberto referentes ao produto
selecionado no grid de produtos do Painel de Compras (SmartSupply).

Exibe uma dialog com as OPs do produto que ainda não foram completamente atendidas
(C2_QUANT > C2_QUJE ou que não possuam C2_ENCER = 'E').

O usuário poderá:
  - Encerrar a OP, desde que ela já possua apontamentos (via MATA680 por MSExecAuto)
  - Excluir a OP,   desde que ela não possua apontamentos (via MATA650 por MSExecAuto)

@type function
@version 12.1.2510
@author Jean Carlos Pandolfo Saggin
@since 21/05/2026
/*/
User Function JSSHOWOP()

    Local oBtnExc   := Nil
    Local oBtnFec   := Nil
    Local oGetPrd   := Nil
    Local oGetDes   := Nil
    Local oLblPrd   := 0
    Local cGetPrd   := aColPro[ oBrwPro:nAt ][ nPosPrd ]
    Local cGetDes   := aColPro[ oBrwPro:nAt ][ nPosDes ]
    Local aHeaderEx := {}
    Local aAlter    := {}
    Local nX        := 0

    // Campos do grid de OPs em aberto
    Local aFields   := { "C2_FILIAL", "C2_NUM", "C2_ITEM", "C2_SEQUEN",;
                         "C2_EMISSAO", "C2_DATPRI", "C2_DATPRF",;
                         "C2_QUANT", "SALDO", "C2_QUJE","C2_OBS" }

    Private aColsOP := {}
    Private oGridOP := Nil
    Private oDlgOP  := Nil

    For nX := 1 To Len( aFields )
        If aFields[nX] == "SALDO"
            aAdd( aHeaderEx, { "Saldo", "SALDO", "@E 999,999.99", 11, 2, , , "N", , "V", , } )
        Else
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

    DEFINE MSDIALOG oDlgOP TITLE "Ordens de Produção em Aberto" ;
        FROM 000, 000 TO 300, 1050 COLORS 0, 16777215 PIXEL

    oGridOP := MsNewGetDados():New( 018, 002, 134, 520, GD_UPDATE,;
               "AllwaysTrue", "AllwaysTrue", "", aAlter,, Len( aColsOP ),;
               "AllwaysTrue", "", "AllwaysTrue", oDlgOP, aHeaderEx, aColsOP )
    oGridOP:bChange := {|| oBtnExc:SetFocus(), oGridOP:oBrowse:SetFocus() }

    @ 004, 002 SAY oLblPrd PROMPT "Produto: " SIZE 035, 007 OF oDlgOP COLORS 0, 16777215 PIXEL
    @ 002, 043 MSGET oGetPrd VAR cGetPrd SIZE 059, 012 OF oDlgOP WHEN .F. COLORS 0, 16777215 PIXEL
    @ 002, 104 MSGET oGetDes VAR cGetDes SIZE 214, 012 OF oDlgOP WHEN .F. COLORS 0, 16777215 PIXEL

    oBtnExc := TButton():New( 136, 426, "&Excluir OP", oDlgOP,{|| iif( Len( aColsOP ) > 0,;
                    opExc( aColsOP[oGridOP:nAt][ColPos(oGridOP,'C2_FILIAL')],;
                           aColsOP[oGridOP:nAt][ColPos(oGridOP,'C2_NUM')],;
                           aColsOP[oGridOP:nAt][ColPos(oGridOP,'C2_ITEM')],;
                           aColsOP[oGridOP:nAt][ColPos(oGridOP,'C2_SEQUEN')] ),;
                    Nil ) }, 055, 012,,,.F.,.T.,.F.,,.F.,,,.F. )
    oBtnExc:bWhen := {|| Len( aColsOP ) > 0 }

    @ 136, 483 BUTTON oBtnFec PROMPT "&Fechar" SIZE 037, 012 OF oDlgOP ;
        ACTION oDlgOP:End() PIXEL

    ACTIVATE MSDIALOG oDlgOP CENTERED ON INIT ;
        Processa( {|| opPendentes( aColPro[ oBrwPro:nAt ][ nPosPrd ] ) }, 'Aguarde!', 'Buscando Ordens de Produção em aberto...' )

Return ( Nil )

/*/{Protheus.doc} colPos
Retorna posição da coluna no grid
@type function
@version 12.1.2510
@author Jean Carlos Pandolfo Saggin
@since 22/05/2026
@param oGrid, object, objeto do grid
@param cField, character, id do campo para que a função retorna sua posição
@return numeric, nColPos
/*/
static function colPos( oGrid, cField )
return aScan( oGrid:aHeader, {|x| AllTrim(x[2]) == AllTrim( cField ) } )

/*/{Protheus.doc} opPendentes
Carrega no vetor aColsOP as Ordens de Produção do produto que ainda estão em
aberto, ou seja: não encerradas (C2_ENCER <> 'E') e com saldo a produzir
(C2_QUANT > C2_QUJE).

@type function
@version 12.1.2510
@author Jean Carlos Pandolfo Saggin
@since 21/05/2026
@param cProd, character, Código do produto
/*/
Static Function opPendentes( cProd )

    Local cQuery := ""

    aColsOP := {}

    // Query principal das OPs em aberto
    cQuery += "SELECT C2.C2_FILIAL, " + CEOL
    cQuery += "       C2.C2_NUM, C2.C2_ITEM, C2.C2_SEQUEN, " + CEOL
    cQuery += "       C2.C2_EMISSAO, C2.C2_DATPRI, C2.C2_DATPRF, " + CEOL
    cQuery += "       C2.C2_QUANT, " + CEOL
    cQuery += "       (C2.C2_QUANT - C2.C2_QUJE) SALDO, " + CEOL
    cQuery += "       C2.C2_QUJE, " + CEOL
    cQuery += "       C2.C2_TPOP, C2.C2_STATUS, C2.C2_OBS " + CEOL
    cQuery += "FROM " + RetSqlName( 'SC2' ) + " C2 " + CEOL
    cQuery += "WHERE C2.C2_FILIAL  " + U_JSFILIAL( 'SC2', _aFil ) + " " + CEOL
    cQuery += "  AND C2.C2_PRODUTO = '" + cProd + "' " + CEOL
    cQuery += "  AND C2.C2_DATRF   = '        ' " + CEOL
    cQuery += "  AND (C2.C2_QUANT - C2.C2_QUJE) > 0 " + CEOL
    cQuery += "  AND C2.D_E_L_E_T_ = ' ' " + CEOL
    cQuery += "ORDER BY C2.C2_FILIAL, C2.C2_EMISSAO, C2.C2_NUM, C2.C2_ITEM " + CEOL

    TcQuery cQuery New Alias 'OPTMP'
    DbSelectArea( 'OPTMP' )

    TcSetField( 'OPTMP', 'C2_EMISSAO', 'D' )
    TcSetField( 'OPTMP', 'C2_DATPRI',  'D' )
    TcSetField( 'OPTMP', 'C2_DATPRF',  'D' )

    OPTMP->( DbGoTop() )

    If ! OPTMP->( EOF() )
        While ! OPTMP->( EOF() )

            aAdd( aColsOP, { OPTMP->C2_FILIAL,;
                             OPTMP->C2_NUM,;
                             OPTMP->C2_ITEM,;
                             OPTMP->C2_SEQUEN,;
                             OPTMP->C2_EMISSAO,;
                             OPTMP->C2_DATPRI,;
                             OPTMP->C2_DATPRF,;
                             OPTMP->C2_QUANT,;
                             OPTMP->SALDO,;
                             OPTMP->C2_QUJE,;
                             AllTrim( OPTMP->C2_OBS ),;
                             .F. } )

            OPTMP->( DbSkip() )
        EndDo
    EndIf

    OPTMP->( DbCloseArea() )

    oGridOP:aCols := aClone( aColsOP )
    oGridOP:ForceRefresh()
    oDlgOP:Refresh()

Return ( Nil )


/*/{Protheus.doc} opTemApont
Verifica se a Ordem de Produção possui apontamentos registrados na SD4.
Retorna .T. caso existam apontamentos, ou .F. caso contrário.

@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 21/05/2026
@param cFil,    character, Filial da OP
@param cNum,    character, Número da OP (C2_NUM)
@param cItem,   character, Item da OP   (C2_ITEM)
@param cSequen, character, Sequência da OP (C2_SEQUEN)
@return logical, lTemApont
/*/
Static Function opTemApont( cFil, cNum, cItem, cSequen )

    Local lTemApont := .F.
    Local cOP       := cNum + cItem + cSequen
    Local cQuery    := ""

    // Busca por apontamentos ligados a OP na tabela SD4
    cQuery += "SELECT COUNT(*) QTAPONT " + CEOL
    cQuery += "FROM " + RetSqlName( 'SD4' ) + " D4 " + CEOL
    cQuery += "WHERE D4.D4_FILIAL = '" + FWxFilial( 'SD4' ) + "' " + CEOL
    cQuery += "  AND D4.D4_OP     = '" + cOP + "' " + CEOL
    cQuery += "  AND D4.D_E_L_E_T_ = ' ' " + CEOL

    TcQuery cQuery New Alias 'APOTMP'
    DbSelectArea( 'APOTMP' )

    APOTMP->( DbGoTop() )
    If ! APOTMP->( EOF() )
        lTemApont := APOTMP->QTAPONT > 0
    EndIf

    APOTMP->( DbCloseArea() )

Return lTemApont

/*/{Protheus.doc} opExc
Realiza a exclusão da Ordem de Produção selecionada pelo usuário,
utilizando MSExecAuto com a rotina MATA650 (Manutenção de OP), conforme
padrão adotado no projeto (ver AFOPAUTO.prw via createOP).

Pré-condição: a OP Não deve possuir apontamentos na SD4.

@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 21/05/2026
@param cFil,    character, Filial da OP
@param cNum,    character, Número da OP (C2_NUM)
@param cItem,   character, Item da OP   (C2_ITEM)
@param cSequen, character, Sequencia da OP (C2_SEQUEN)
@return logical, lSuccess
/*/
Static Function opExc( cFil, cNum, cItem, cSequen )

    Local lSuccess  := .F.
    Local aVetOP    := {}
    Local cFilHist  := cFilAnt
    Local cOldFun   := FunName()

    Private lMsErroAuto := .F.

    If ! MsgYesNo( "Confirma a <b>EXCLUSÃO</b> da OP <b>" + AllTrim(cNum) + "</b>" +;
                   " / Item <b>" + AllTrim(cItem) + "</b>?<br><br>" +;
                   "<b>Atenção:</b> Esta operação não poderá ser desfeita!",;
                   "Excluir OP?" )
        Return lSuccess
    EndIf

    cFilAnt := cFil
    FWSm0Util():SetSM0PositionByCFilAnt()

    // Monta vetor para o ExecAuto do MATA650
    // MATA650 - Manutenção de OP: nOpc 5 = Exclusão
    // Necessário posicionar SC2 antes de montar o vetor (mesmo padrão de AFOPAUTO)
    DBSelectArea( 'SC2' )
    SC2->( DBSetOrder( 1 ) )

    // Posiciona na OP
    If SC2->( DBSeek( FWxFilial( 'SC2' ) + cNum + cItem + cSequen ) )        

        aAdd( aVetOP, { "C2_FILIAL" , SC2->C2_FILIAL,    Nil } )
        aAdd( aVetOP, { "C2_NUM"    , SC2->C2_NUM,       Nil } )
        aAdd( aVetOP, { "C2_ITEM"   , SC2->C2_ITEM,      Nil } )
        aAdd( aVetOP, { "C2_SEQUEN" , SC2->C2_SEQUEN,    Nil } )
        aAdd( aVetOP, { "C2_PRODUTO", SC2->C2_PRODUTO,   Nil } )
        aAdd( aVetOP, { "C2_QUANT"  , SC2->C2_QUANT,     Nil } )
        aAdd( aVetOP, { "C2_EMISSAO", SC2->C2_EMISSAO,   Nil } )
        aAdd( aVetOP, { "C2_DATPRI" , SC2->C2_DATPRI,    Nil } )
        aAdd( aVetOP, { "C2_DATPRF" , SC2->C2_DATPRF,    Nil } )

    EndIf

    If Len( aVetOP ) == 0
        MsgStop( "Não foi possível localizar a OP " + AllTrim(cNum) +;
                 " na tabela SC2. Verifique e tente novamente.", 'Atenção' )
        cFilAnt := cFilHist
        FWSm0Util():SetSM0PositionByCFilAnt()
        Return lSuccess
    EndIf

    lMsErroAuto := .F.
    SetFunName( 'MATA650' )
    MSExecAuto( {|x, y| Mata650( x, y )}, aVetOP, 5 )  // 5 = Exclusão
    SetFunName( cOldFun )

    If lMsErroAuto
        lSuccess := .F.
        MostraErro()
    Else
        lSuccess := .T.
        MsgInfo( "OP " + AllTrim(cNum) + " excluída com sucesso!", 'S U C E S S O !' )
        // Recarrega grid para refletir a alteração 
        Processa( {|| opPendentes( aColPro[ oBrwPro:nAt ][ nPosPrd ] ) },;
                  'Aguarde!', 'Atualizando Ordens de Produção em aberto...' )
    EndIf

    cFilAnt := cFilHist
    FWSm0Util():SetSM0PositionByCFilAnt()

Return lSuccess
