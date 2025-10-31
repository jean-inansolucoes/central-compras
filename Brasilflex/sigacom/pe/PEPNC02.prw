#include 'totvs.ch'

/*/{Protheus.doc} PEPNC02
PE que permite manipulação de dados do carrinho de compras
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/27/2025
@return array, aNewCols
/*/
user function PEPNC02()

    local aHeader  := aClone( PARAMIXB[1] )
    local aNewCols := aClone( PARAMIXB[2] )
    local nX       := 0 

    // Percorre o vetor atribuindo valor aos campos customizados
    if len( aNewCols ) > 0
        for nX := 1 to len( aNewCols )
            // Faz uma checagem se todos os campos necessários estão disponíveis no aCols
            if gt( aHeader, 'C7_X_OBS' ) > 0 .and. gt( aHeader, 'C7_PRODUTO' ) > 0 .and. gt( aHeader, 'QUANT' ) > 0
                aNewCols[nX][gt( aHeader, 'C7_X_OBS' )] := U_CONVUNI3( aNewCols[nX][gt( aHeader, 'C7_PRODUTO' )], aNewCols[nX][gt( aHeader, 'QUANT' )])
            elseif gt( aHeader, 'C7_X_OBS' ) > 0
                aNewCols[nX][gt( aHeader, 'C7_X_OBS' )] := CriaVar( 'C7_X_OBS' )
            endif
        next nX
    endif

return aNewCols

/*/{Protheus.doc} gt
Retorna posição de um campo no vetor
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/27/2025
@param aHeader, array, Header
@param cField, character, campo
@return numeric, nFieldPos
/*/
Static function gt( aHeader, cField )
return aScan( aHeader, {|x| AllTrim( x[2] ) == AllTrim( cField ) } )
