#include 'totvs.ch'

/*/{Protheus.doc} MT120BRW
Adiciona botões à rotina do Pedido de Compras
@type function
@version 12.1.2410
@author Jean Carlos Pandolfo Saggin
@since 30/10/2025
/*/
user function MT120BRW()
    local aSubMenu := {} as array
    if FindFunction( 'U_JSRLPDCO' )
        aAdd( aSubMenu, { 'Imprimir PDF do Pedido', 'U_JSRLPDCO()', 0, 2 } )
        aAdd( aRotina, { 'Painel de Compras', aSubMenu, 0, 2 } )
    endif
return Nil
