#include 'totvs.ch'

/*/{Protheus.doc} PEPNC06
PE para alterar produto que vai receber o preço na rotina de formação de preços do Painel de Compras
@type function
@version 12.1.2410
@author Jean Carlos Pandolfo Saggin
@since 01/10/2025
@return character, cProd
/*/
user function PEPNC06()

    local aArea := getArea()
    local cProd := "" as character

    DBSelectArea( 'SB1' )
    SB1->( DBSetOrder( 1 ) )
    if SB1->( DBSeek( FWxFilial( 'SB1' ) + PARAMIXB ) )
        DBSelectArea( 'SG1' )
        SG1->( DBSetOrder( 2 ) )    // G1_FILIAL + G1_COMP + G1_COD
        if SG1->( DBSeek( FWxFilial( 'SG1' ) + SB1->B1_COD ) )
            cProd := SG1->G1_COD
        endif
    endif

    restArea( aArea )
return cProd
