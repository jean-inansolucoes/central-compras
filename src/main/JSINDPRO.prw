#include 'totvs.ch'
#include 'topconn.ch'

/*/{Protheus.doc} JSINDPRO
Função para visualizar e recalcular manualmente os índices de produtos para o Painel de Compras
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/20/2024
/*/
User Function JSINDPRO()

    Local cAlias := AllTrim( SuperGetMv( 'MV_X_PNC02',,"" ) )   // Alias da tabela de índices de produtos

    Private cCadastro := "Índices de Produtos"
    Private aRotina   := {}

    AAdd( aRotina, { 'Visualizar', "AxVisual", 0, 2 } )
    AAdd( aRotina, { 'Recalcular', "U_JSINDMAN", 0, 3 } )
    
    // Valida existência de configuração no parâmetro
    if Empty( cAlias )
        Hlp( 'MV_X_PNC02',;
             'Parâmetro que determina alias da tabela de índices de produtos (MV_X_PNC02) não encontrado ou não configurado',;
             'Configure conteúdo do parâmetro mencionado e tente novamente' )
        Return Nil
    endif

    AxCadastro( cAlias, OemToAnsi( cCadastro ),,,,,,,,,,,,,.F. /* lMenuDef */ )

return Nil

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
