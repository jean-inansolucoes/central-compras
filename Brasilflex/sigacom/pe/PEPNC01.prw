#include 'totvs.ch'

/*/{Protheus.doc} PEPNC01
Ponto de Entrada do Painel de Compras que permite realizar a manutenção do Header do carrinho de compras e
recebe como parâmetro o Header padrão
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/27/2025
@return array, aNewHeader
/*/
user function PEPNC01()
    local aNewHeader := aClone( PARAMIXB )
    local aField     := {} as array
    local cField     := "" as character

    // Verifica se encontra o campo de observação padrão no header
    if gt( aNewHeader, 'C7OBSM' ) > 0
        cField := "C7_X_OBS"                    // Substitui o campo de observação padrão do pedido por um campo customizado
        aField := { AllTrim(  GetSX3Cache( cField, 'X3_TITULO' ) ),;
							   GetSX3Cache( cField, 'X3_CAMPO' ),;
							   GetSX3Cache( cField, 'X3_PICTURE' ),;
							   GetSX3Cache( cField, 'X3_TAMANHO' ),;
							   GetSX3Cache( cField, 'X3_DECIMAL' ),;
							   /* GetSX3Cache( cField, 'X3_VALID' ) */,;
							   GetSX3Cache( cField, 'X3_USADO' ),;
							   GetSX3Cache( cField, 'X3_TIPO' ),;
							   GetSX3Cache( cField, 'X3_F3' ),;
							   GetSX3Cache( cField, 'X3_CONTEXT' ),;
							   GetSX3Cache( cField, 'X3_CBOX' ),;
							   GetSX3Cache( cField, 'X3_RELACAO' ) }
        aNewHeader[gt( aNewHeader, 'C7OBSM' )] := aClone( aField )
    endif

return aNewHeader

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
