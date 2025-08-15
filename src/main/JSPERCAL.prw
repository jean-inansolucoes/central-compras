#include 'totvs.ch'
#include 'topconn.ch'
#include 'fwmvcdef.ch'

/*/{Protheus.doc} JSPERCAL
Fun��o para manuten��o de perfis de c�lculo
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/21/2025
/*/
user function JSPERCAL()

    local oBrowse as object
    local cAlias    := AllTrim( SuperGetMv( 'MV_X_PNC16',,'' ) )

    // Valiada se o alias da tabela de perfis de c�lculo est� configurado no par�metro
    if Empty( cAlias )
        Hlp( 'MV_X_PNC16','Al�ases da tabela de perfis de c�lculo inexistenete',;
             'Execute a atualiza��o do Painel de Compras para solucionar o problema e tente novamente.')
        return Nil
    endif

    // Fun��o que for�a a cria��o do registro default de c�lculo de compra
    if !U_JSPERCHK()
        Return Nil
    endif

    // Cria um browse para a rotina
    oBrowse := FWLoadBrw( 'JSPERCAL' )
    oBrowse:Activate()

return Nil

/*/{Protheus.doc} browseDef
Cria o browse padr�o para a rotina
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/21/2025
@return object, oBrowse
/*/
static function browseDef()
    local oBrowse as object
    local cMVPNC16  := AllTrim( SuperGetMv( 'MV_X_PNC16',,'' ) )
    
    oBrowse := FWMBrowse():New()
    oBrowse:SetAlias( cMVPNC16 )
    oBrowse:SetDescription( 'Perfis de C�lculo' )
    oBrowse:SetMenuDef( 'JSPERCAL' )

return oBrowse

/*/{Protheus.doc} ViewDef
Fun��o para elabora��o do modelo de visualiza��o padr�o da rotina
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/21/2025
@return object, oView
/*/
static function ViewDef()
    
    local cMVPNC16 := AllTrim( SuperGetMv( 'MV_X_PNC16',,'' ) )
    local oModel   := FWLoadModel( 'JSPERCAL' )
    local oStruct  := FWFormStruct( 2, cMVPNC16, {|cField| ! AllTrim( cField ) == cMVPNC16 +'_FORMUL' } )
    local oView    as object
    local bActivate := {|oPanel| U_JSDoFrml( nil, oPanel ) }

    oView := FWFormView():New()
    oView:SetModel( oModel )
    oView:AddField( cMVPNC16 +'VIEW', oStruct, cMVPNC16+'MASTER' )
    oView:CreateHorizontalBox( 'H_TOP_BOX', 50 )
    oView:CreateHorizontalBox( 'H_DOWN_BOX', 50 )
    oView:SetOwnerView( cMVPNC16 +'VIEW', 'H_TOP_BOX' )
    oView:AddOtherObject( 'OTHER', bActivate )
    oView:SetOwnerView( 'OTHER', 'H_DOWN_BOX' )
    oView:EnableTitleView( cMVPNC16 +'VIEW' )

return oView

/*/{Protheus.doc} ModelDef
Fun��o para criar o modelo padr�o da rotina
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/21/2025
@return object, oModel
/*/
static function ModelDef()

    local oModel    as object
    local cMVPNC16  := AllTrim( SuperGetMv( 'MV_X_PNC16',,'' ) )
    local oStruct   := FWFormStruct( 1, cMVPNC16 )

    oModel := MPFormModel():New( 'JSPERMOD' ) 
    oModel:AddFields( cMVPNC16+'MASTER', , oStruct )
    oModel:SetDescription( 'Modelo Perfis de Calculo' )
    oModel:GetModel( cMVPNC16+'MASTER' ):SetDescription( 'Master Perfis de Calculo' )
    oModel:SetPrimaryKey( { cMVPNC16+'_FILIAL', cMVPNC16+'_ID' } )

return oModel

/*/{Protheus.doc} MenuDef
Cria um menu no formato esperado pelo mBrowse com MVC
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/21/2025
@return array, aRotina
/*/
static function MenuDef()
    local aRotina := {} as array
    aAdd( aRotina, { 'Visualizar', 'VIEWDEF.JSPERCAL', 0, MODEL_OPERATION_VIEW  , 0, Nil } )
    aAdd( aRotina, { 'Incluir'   , 'VIEWDEF.JSPERCAL', 0, MODEL_OPERATION_INSERT, 0, Nil } )
    aAdd( aRotina, { 'Alterar'   , 'VIEWDEF.JSPERCAL', 0, MODEL_OPERATION_UPDATE, 0, Nil } )
    aAdd( aRotina, { 'Excluir'   , 'VIEWDEF.JSPERCAL', 0, MODEL_OPERATION_DELETE, 0, Nil } )
return aRotina

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

/*/{Protheus.doc} JSIDPERF
Fun��o para retorno de um novo ID quando usu�rio est� incluindo registro
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/21/2025
@return character, cID
/*/
user function JSIDPERF()
    local cMVPNC16  := AllTrim( SuperGetMv( 'MV_X_PNC16',,'' ) )
    local cID := GetSXENUM( cMVPNC16, cMVPNC16 +'_ID' )
return cID

/*/{Protheus.doc} JSPERCHK
Fun��o respons�vel pela checagem e cria��o do registro com ID 01, contendo a f�rmula de c�lculo padr�o da rotina
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/23/2025
@return logical, lChecked
/*/
user function JSPERCHK()

    local lChecked := .F. as logical
    local cAlias   := GetMv( 'MV_X_PNC16' )
    local cID      := "" as character
    local cFrmlDef := ALlTrim( SuperGetMv( 'MV_X_PNC01',,'' ) ) 

    // Valida exist�ncia de fun��o que checa e cria 
	if FindFunction( 'U_JSZBMF3' )
		U_JSZBMF3()
	endif

    cID := StrZero( 1, TAMSX3( cAlias + '_ID' )[1] )
    DBSelectArea( cAlias )
    ( cAlias )->( DBSetOrder( 1 ) )     // FILIAL + ID
    if ! ( cAlias )->( DBSeek( FWxFilial( cAlias ) + cID ) )
        RecLock( cAlias, .T. )
        ( cAlias )->( FieldPut( FieldPos( cAlias +'_FILIAL' ), FWxFilial( cAlias ) ) )
        ( cAlias )->( FieldPut( FieldPos( cAlias +'_ID' ), cID ) )
        ( cAlias )->( FieldPut( FieldPos( cAlias +'_DESC' ), 'Consumo M�dio' ) )
        ( cAlias )->( FieldPut( FieldPos( cAlias +'_MSBLQL' ), '2' ) )
        ( cAlias )->( FieldPut( FieldPos( cAlias +'_FORMUL' ), cFrmlDef ) )
        ( cALias )->( MsUnlock() )
        lChecked := .T.
    else
        lChecked := .T.
    endif

    // Valida exist�ncia do campo no cadastro do produto
    lChecked := SB1->( FieldPos( 'B1_X_PERCA' ) ) > 0
    if ! lChecked
        Hlp( 'B1_X_PERCA',;
             'Campo Perfil de C�lculo n�o identificado na tabela de produtos',;
             'Aplique a �ltima atualiza��o do dicion�rio de dados da rotina Painel de Compras e tente novamente.' )
    endif

return lChecked

/*/{Protheus.doc} JSZBMF3
Faz checagem da exist�ncia da consulta padr�o 
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/24/2025
@return logical, lExist
/*/
User Function JSZBMF3()
    
    local lExist  := .T. as logical
    local cSXB    := "SXB"
    local cSX3    := "SX3" 
    local aXB     := {} as array
    local cAlias  := AllTrim( GetMV( 'MV_X_PNC16' ) )
    local lInc    := .F. as logical
    local nX      := 0 as numeric
    local nField  := 0 as numeric
    local aFields := { "XB_ALIAS", "XB_TIPO", "XB_SEQ", "XB_COLUNA", "XB_DESCRI", "XB_DESCSPA", "XB_DESCENG", "XB_CONTEM" }

    // Cria vetor contendo os dados da consulta padr�o
    aAdd( aXB, { PADR( cAlias, 6, ' ' ), '1', '01', 'DB', 'Perfis de Calculo   ', 'Perfis de Calculo   ', 'Perfis de Calculo   ', cAlias } )
    aAdd( aXB, { PADR( cAlias, 6, ' ' ), '2', '01', '01', 'Id do Perfil        ', 'Id do Perfil        ', 'Id do Perfil        ', "" } )
    aAdd( aXB, { PADR( cAlias, 6, ' ' ), '3', '01', '01', 'Cadastra Novo       ', 'Incluye Nuevo       ', 'Add New             ', "01" } )
    aAdd( aXB, { PADR( cAlias, 6, ' ' ), '4', '01', '01', 'ID do Perfil        ', 'ID do Perfil        ', 'ID do Perfil        ', cAlias +'_ID' } )
    aAdd( aXB, { PADR( cAlias, 6, ' ' ), '4', '01', '02', 'Descri��o           ', 'Descri��o           ', 'Descri��o           ', cAlias +'_DESC' } )
    aAdd( aXB, { PADR( cAlias, 6, ' ' ), '5', '01', '  ', '                    ', '                    ', '                    ', cAlias +'->'+ cAlias +'_ID' } )

    DBSelectArea( cSXB )
    ( cSXB )->( DBSetOrder( 1 ) )       // Alias + Tipo + Seq + Coluna
    for nX := 1 to len( aXB )
        lInc := !( cSXB )->( DBSeek( aXB[nX][1] + aXB[nX][2] + aXB[nX][3] + aXB[nX][4] ) )
        RecLock( cSXB, lInc )
        for nField := 1 to len( aFields )
            ( cSXB )->( FieldPut( FieldPos( aFields[nField] ), aXB[nX][nField] ) )
        next nField
        ( cSXB )->( MsUnlock() )
    next nX

    // Checagem para ver se todos os registros existem
    for nX := 1 to len( aXB )
        lExist := lExist .and. ( cSXB )->( DBSeek( aXB[nX][1] + aXB[nX][2] + aXB[nX][3] + aXB[nX][4] ) )
    next nX

    if lExist
        // Ajusta configura��o do campo, se necess�rio
        DBSelectArea( cSX3 )
        (cSX3)->( DBSetOrder( 2 ) )
        if ( cSX3 )->( DBSeek( 'B1_X_PERCA' ) ) .and. Empty( ( cSX3 )->X3_F3 )
            RecLock( cSX3, .F. )
            ( cSX3 )->( FieldPut( FieldPos( 'X3_F3' ), cAlias ) )
            ( cSX3 )->( MsUnlock() )
        endif

    endif

return lExist
