#include 'totvs.ch'
#include 'fwmvcdef.ch'

#define CLOOKUPICON "FWSKIN_ICON_LOOKUP.PNG"	// icone de pesquisa

/*/{Protheus.doc} JSMANTAG
Fun��o respons�vel pela manuten��o de tags
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/27/2024
/*/
user function JSMANTAG()
    
    local oBrowse as object
    
    Private cZBJ := AllTrim( SuperGetMv( 'MV_X_PNC14',,'   ' ) ) as character

    // Valida exist�ncia da configura��o
    if Empty( cZBJ )
        Hlp( 'MV_X_PNC14',;
            'Configura��o n�o localizada para o par�metro MV_X_PNC14',;
            'Configure o par�metro com o alias referente a tabela de Cadastro de Tags ou execute o atualizador de release do Painel de Compras para prosseguir' )
        Return nil
    endif

    oBrowse := FWLoadBrw( 'JSMANTAG' )
    oBrowse:Activate()

return Nil

/*/{Protheus.doc} modelDef
Cria o modelo de dados para manuten��o das tags
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/27/2024
@return object, oModel
/*/
static function modelDef()

    local oModel  as object
    local oStruct := FWFormStruct( 1, cZBJ ) 
    local bVldPre := {|| .T. }
    local bVldPos := {|| .T. }
    local bCommit := Nil
    local bCancel := Nil
    local bPre    := Nil
    local bPos    := Nil
    local bCarga  := Nil

    // Altera propriedade do campo ID para preenchimento autom�tico
    oStruct:SetProperty( cZBJ +'_ID', MODEL_FIELD_INIT, &("{||GETSXENUM( '"+ cZBJ +"', '"+ cZBJ +"_ID' )}") )

    oModel := MPFormModel():New( 'JSMTAG', bVldPre, bVldPos, bCommit, bCancel )
    oModel:AddFields( 'ZBJMASTER', , oStruct, bPre, bPos, bCarga )
    oModel:SetPrimaryKey({ cZBJ +'_FILIAL', cZBJ +'_ID' })
    oModel:SetDescription( 'Modelo Cadastro Tags' )
    oModel:GetModel( 'ZBJMASTER' ):SetDescription( 'Cadastro Tags (Master)' )

return oModel

/*/{Protheus.doc} viewDef
Fun��o para cria��o do objeto da view de manuten��o de tags
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/27/2024
@return object, oView
/*/
static function viewDef()
    
    local oView as object
    local oModel := FWLoadModel( 'JSMANTAG' )
    local bFields := {|cField| ! AllTrim(cField) $ cZBJ+'_ICO' }
    local oStruct := FWFormStruct( 2, cZBJ, bFields )
    local bActivate := {|oPanel| makeOther( oPanel ) }

    oView := FWFormView():New()
    oView:SetModel( oModel )
    oView:AddField( 'VIEWZBJ', oStruct, 'ZBJMASTER' )
    oView:AddOtherObject( 'VIEWOTHER', bActivate )
    oView:CreateHorizontalBox( 'TELA', 100 )
    oView:SetOwnerView( 'VIEWZBJ', 'TELA' )
    oView:SetDescription( 'Manuten��o de Tags' )
    oView:EnableTitleView( 'VIEWZBJ' )

return oView

/*/{Protheus.doc} makeOther
Fun��o para montar painel onde o usu�rio vai escolher a imagem para a tag
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/27/2024
@param oPanel, object, objecto do painel
/*/
static function makeOther( oPanel )
    
    local oModel     := FWModelActive()
    local oMaster    := oModel:GetModel( 'ZBJMASTER' )
    local aResName   := getResName()
    local cResName   := iif( oModel:GetOperation() == MODEL_OPERATION_INSERT, "white.bmp", oMaster:GetValue( cZBJ + '_ICO' ) )
    local oImage            as object
    local lDimPixels := .F. as logical
    local oBtn              as object

    oImage := TBitmap():New( 10, 10, 30, 30, /*cResName*/, /*cBmpFile*/, /*lNoBorder*/, oPanel, /*bLClicked*/, /*bRClicked*/, /*lScroll*/, /*lStretch*/, /*oCursor*/, /*uParam14*/, /*uParam15*/, /*bWhen*/, lDimPixels, /*bValid*/)
    oImage:lStretch := .F.
    oImage:Load( cResName )
    oImage:Refresh()

    oBtn := tBitmap():New( 13, 50, 12, 12,,"painel_compras_lupa.png", .T., oPanel,;
    {|| cResName := getRes( cResName, aResName ),;
        oImage:Load( cResName ),;
        oImage:Refresh() }, NIL, .F., .F., NIL, NIL, .F., NIL, .T., NIL, .F.)

return Nil

/*/{Protheus.doc} getRes
Fun��o para obter o nome do recurso selecinado pelo usu�rio atrav�s de interface de pesquisa
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/30/2024
@param cResName, character, nome do recurso atual
@param aResName, array, vetor de recursos para o usu�rio selecionar
@return character, cResName
/*/
Static function getRes( cResourse, aResName )
    
    local oDlgRes as object
    local cResName := cResourse as character
    local aButtons := {} as character
    local bOk    := {|| Nil }
    local bCancel := {|| oDlgRes:End() }
    local bValid := {|| .T. }
    local bInit  := {|| EnchoiceBar( oDlgRes, bOk, bCancel,,aButtons ) }
    local aColumns := {} as array

    Private oBrowse as object

    aAdd( aColumns, FWBrwColumn():New() )
    aColumns[len(aColumns)]:SetTitle( 'ID Recurso' )
    aColumns[len(aColumns)]:SetType( 'C' )
    aColumns[len(aColumns)]:SetSize( TAMSX3( cZBJ +'_ICO' )[1] )
    aColumns[len(aColumns)]:SetPicture( '@x' )
    aColumns[len(aColumns)]:SetData( {|| aResName[ oBrowse:At() ] } )

    oDlgRes := TDialog():New( 0, 0, 400, 400, 'Relacione uma imagem � tag...',,,,,CLR_BLACK,CLR_WHITE,,,.T.)
    
    oBrowse := FWBrowse():New( oDlgRes )
    oBrowse:SetDataArray()
    aEval( aResName, {|x| oBrowse:AddLegend( &('{|| aResName[oBrowse:At()] == '+ x +' }'), x ) })
    oBrowse:SetColumns( aColumns )
    oBrowse:SetArray( aResName )
    oBrowse:DisableReport()
    oBrowse:DisableSetup()
    oBrowse:Activate()

    oDlgRes:Activate(,,,.T., bValid,, bInit )

return cResName

/*/{Protheus.doc} getResName
Fun��o para obter a lista de recursos dispon�veis para a tag
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/27/2024
@return array, aResName
/*/
static function getResName()
    local aResName := {} as array
    aAdd( aResName, "painel_tag001.png" )
    aAdd( aResName, "painel_tag002.png" )
    aAdd( aResName, "painel_tag003.png" )
    aAdd( aResName, "painel_tag004.png" )
    aAdd( aResName, "painel_tag005.png" )
    aAdd( aResName, "painel_tag006.png" )
    aAdd( aResName, "painel_tag007.png" )
    aAdd( aResName, "painel_tag008.png" )
    aAdd( aResName, "painel_tag009.png" )
    aAdd( aResName, "painel_tag010.png" )
    aAdd( aResName, "painel_tag011.png" )
    aAdd( aResName, "painel_tag012.png" )
    aAdd( aResName, "painel_tag013.png" )
return aResName

/*/{Protheus.doc} BrowseDef
Fun��o que retorna um objeto de browse para a tela de manuten��o de tags
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/27/2024
@return object, oBrowse
/*/
static function BrowseDef()
    
    local oBrowse := FWMBrowse():New()
    oBrowse:SetAlias( cZBJ )
    oBrowse:SetDescription( 'Cadastro de Tags' )
    oBrowse:SetMenuDef( 'JSMANTAG' )
    oBrowse:Activate()

return oBrowse

/*/{Protheus.doc} menuDef
Cria menu de op��es para a rotina de cadastro de Tags
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/27/2024
@return array, aRotina
/*/
static function menuDef()
    local aRotina := {} as array
    ADD OPTION aRotina TITLE 'Visualizar'   ACTION 'VIEWDEF.JSMANTAG' OPERATION MODEL_OPERATION_VIEW    ACCESS 0
    ADD OPTION aRotina TITLE 'Incluir'      ACTION 'VIEWDEF.JSMANTAG' OPERATION MODEL_OPERATION_INSERT  ACCESS 0
    ADD OPTION aRotina TITLE 'Alterar'      ACTION 'VIEWDEF.JSMANTAG' OPERATION MODEL_OPERATION_UPDATE  ACCESS 0
    ADD OPTION aRotina TITLE 'Excluir'      ACTION 'VIEWDEF.JSMANTAG' OPERATION MODEL_OPERATION_DELETE  ACCESS 0
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
