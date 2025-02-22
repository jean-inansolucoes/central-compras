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
    local cID       := "" as character

    local cFrmlDef  := ALlTrim( SuperGetMv( 'MV_X_PNC01',,'' ) ) 

    // Valiada se o alias da tabela de perfis de c�lculo est� configurado no par�metro
    if Empty( cAlias )
        Hlp( 'MV_X_PNC16','Al�ases da tabela de perfis de c�lculo inexistenete',;
             'Execute a atualiza��o do Painel de Compras para solucionar o problema e tente novamente.')
        return Nil
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

    oView := FWFormView():New()
    oView:SetModel( oModel )
    oView:AddField( cMVPNC16 +'VIEW', oStruct, cMVPNC16+'MASTER' )
    oView:CreateHorizontalBox( 'GERAL', 100 )
    oView:SetOwnerView( cMVPNC16 +'VIEW', 'GERAL' )
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
    local oStruct   := FWFormStruct( 1, cMVPNC16, {|cField| ! AllTrim( cField ) == cMVPNC16 +'_FORMUL' } )

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
