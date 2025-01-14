#include 'topconn.ch'

/*/{Protheus.doc} MA103OPC
PE para inclus�o de novas op��es de bot�es na rotina de documento de entrada
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 1/13/2025
@return array, aRet
/*/
user function MA103OPC()
    local aRet := {} as array
    
    // Apenas inclui fun��o no menu da rotina se o fonte estiver compilado no RPO
    if FindFunction( 'U_JSENTRDC' )
        aAdd( aRet, { "Forma��o de Pre�os", "U_GMFORPRC", 0, 2 } )
    endif

return aRet

/*/{Protheus.doc} GMFORPRC
Fun��o respons�vel pela chamada de rotina customizada para forma��o de pre�os
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 1/13/2025
/*/
User Function GMFORPRC()
return U_JSENTRDC( SF1->F1_DOC, SF1->F1_SERIE, SF1->F1_FORNECE, SF1->F1_LOJA, SF1->F1_TIPO )
