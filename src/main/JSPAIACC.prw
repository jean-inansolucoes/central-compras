#include 'totvs.ch'
#include 'fwmvcdef.ch'

/*/{Protheus.doc} JSPAIACC
Fun��o para manuten��o dos acessos ao Painel de Compras
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 5/6/2025
/*/
User Function JSPAIACC()

    local aArea   := getArea()
    local oBrowse := FWMBrowse():New()

    oBrowse:SetAlias()



    restArea( aArea )

return Nil


