#include 'totvs.ch'

/*/{Protheus.doc} PEPNC04
PE do Painel de Compras para permitir manipular a quantidade de estoque atual do produto
@type function
@version 1.0
@author Jean C. P. Saggin
@since 3/14/2025
@return numeric, nNewQtd
/*/
user function PEPNC04()

    local aArea     := getArea()
    local aConf    := aClone(PARAMIXB[1])
    local cProduto := PARAMIXB[2]
    local nNewQtd   := PARAMIXB[3]
    local nAux      := 0 as numeric
    local nX        := 0 as numeric
    local aLocais   := StrTokArr( AllTrim( aConf[16] ), '/' )
    
    // Desconsidera saldo do armazém 77 para fins de saldo dos produtos pois é armazém de produção que, em teoria, vai utilizar todo o saldo
    // no seu processo produtivo.
    if len( aLocais ) > 0
        for nX := 1 to len( aLocais )
            if ! AllTrim(aLocais[nX]) == '77'     // Diferente do armazém de produção
                nAux += RetField( 'SB2', 1, FWxFilial( 'SB2' ) + cProduto + aLocais[nX], 'B2_QATU' )
            endif
        next nX
    endif
    nNewQtd := nAux

    restArea( aArea )
return nNewQtd
