#include 'topconn.ch'

/*/{Protheus.doc} MA103OPC
PE para inclusão de novas opções de botões na rotina de documento de entrada
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 1/13/2025
@return array, aRet
/*/
user function MA103OPC()
    local aRet := {} as array
    
    // Apenas inclui função no menu da rotina se o fonte estiver compilado no RPO
    if FindFunction( 'U_JSENTRDC' )
        aAdd( aRet, { "Formação de Preços", "U_GMFORPRC", 0, 2 } )
    endif

return aRet

/*/{Protheus.doc} GMFORPRC
Função responsável pela chamada de rotina customizada para formação de preços
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 1/13/2025
/*/
User Function GMFORPRC()
return U_JSENTRDC( SF1->F1_DOC, SF1->F1_SERIE, SF1->F1_FORNECE, SF1->F1_LOJA, SF1->F1_TIPO )
