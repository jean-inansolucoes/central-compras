#include 'totvs.ch'
#include 'topconn.ch'

/*/{Protheus.doc} JSINDPRO
Fun��o para visualizar e recalcular manualmente os �ndices de produtos para o Painel de Compras
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/20/2024
/*/
User Function JSINDPRO()

    Local cAlias := AllTrim( SuperGetMv( 'MV_X_PNC02',,"" ) )   // Alias da tabela de �ndices de produtos

    Private cCadastro := "�ndices de Produtos"
    Private aRotina   := {}

    AAdd( aRotina, { 'Visualizar', "AxVisual", 0, 2 } )
    AAdd( aRotina, { 'Recalcular', "U_JSINDMAN", 0, 3 } )
    
    // Valida exist�ncia de configura��o no par�metro
    if Empty( cAlias )
        Hlp( 'MV_X_PNC02',;
             'Par�metro que determina alias da tabela de �ndices de produtos (MV_X_PNC02) n�o encontrado ou n�o configurado',;
             'Configure conte�do do par�metro mencionado e tente novamente' )
        Return Nil
    endif

    AxCadastro( cAlias, OemToAnsi( cCadastro ),,,,,,,,,,,,,.F. /* lMenuDef */ )

return Nil

/*/{Protheus.doc} JSINDMAN
Fun��o respons�vel pelo rec�lculo manual dos �ndices de produtos
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/20/2024
@return logical, lSuccess
/*/
User Function JSINDMAN()
    local lSuccess := .F. as logical
    Processa({|| U_GMINDPRO() }, 'Recalculando �ndices para os produtos do MRP', 'Aguarde!'  )
    lSuccess := .T.
return lSuccess

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
