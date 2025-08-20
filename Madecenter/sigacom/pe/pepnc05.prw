#include 'totvs.ch'
#include 'topconn.ch'

/*/{Protheus.doc} PEPNC05
Ponto de entrada do Painel de Compras que permite a adi��o de novos campos ao browse de produtos
@type function
@version 12.1.2410
@author Jean Carlos Pandolfo Saggin
@since 5/16/2025
@return array, aColumns
/*/
user function PEPNC05()
    
    local aDados   := PARAMIXB[1]
    local aRetPE   := {} as array
    
    // Verifica se o campo que se quer adicionar j� n�o est� nos campos padr�es da ferramenta
    if aScan( aDados, {|x| AllTrim(x) == 'B1_XGPTP' } ) == 0 .and. SB1->( FieldPos( 'B1_XGPTP' ) ) > 0
        aAdd( aRetPE, 'B1_XGPTP' )
    endif
    
return aRetPE
                                                                                                                                                                                                                                                                                