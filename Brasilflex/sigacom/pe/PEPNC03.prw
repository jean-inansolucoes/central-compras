#include 'totvs.ch'

/*/{Protheus.doc} PEPNC03
Ponto de entrada para manipulação dos vetores do pedido de compra antes do execauto
@type function
@version 1.0
@author Jean C. P. Saggin
@since 3/12/2025
@return array, aRet[aCab,aIte]
/*/
user function PEPNC03()
    
    local aCab := aClone( PARAMIXB[3] )
    local aIte := aClone( PARAMIXB[4] )
    local nX   := 0 as numeric
    local nQuant2UN := 0 as numeric
    local nPreco2UN := 0 as numeric
    local nTotal2UN := 0 as numeric

    Private aHdr := PARAMIXB[1]
    Private aCol := PARAMIXB[2]
    Private nLine := 0 as numeric

    for nX := 1 to len( aCol )
        nLine := nX
        nQuant2UN := getValue( 'QTSEGUM' )
        nTotal2UN := getValue( 'TOTAL' )
        if ! Empty( getValue( 'C7_SEGUM' ) ) .and. nQuant2UN > 0
            nPreco2UN := nTotal2UN / nQuant2UN
            aAdd( aIte[nX], { "C7_X_2PREC", nPreco2UN, Nil } )
        endif
        aAdd( aIte[nX], { "C7_X_2TOTA", nTotal2UN, Nil } )
    next nX

return { aCab, aIte }

/*/{Protheus.doc} getValue
Função para retornar o conteúdo de um campo do aCols do carrinho de compra
@type function
@version 1.0
@author Jean C. P. Saggin
@since 3/13/2025
@param cField, character, ID do campo
@return variadic, xValue
/*/
static function getValue( cField )
return aCol[nLine][getPos(cField)]

/*/{Protheus.doc} getPos
Funcão para retornar posição de uma coluna do vetor do carrinho de compras
@type function
@version 1.0
@author Jean C. P. Saggin
@since 3/13/2025
@param cField, character, ID do campo desejado
@return numeric, nPos
/*/
static function getPos( cField )
return aScan( aHdr, {|x| AllTrim( x[2] ) == AllTrim( cField ) } )
