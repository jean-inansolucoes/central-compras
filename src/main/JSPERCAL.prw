#include 'totvs.ch'

/*/{Protheus.doc} JSPERCAL
Mantida por compatibilidade com os menus que chamam o cadastro de perfis de cálculo: abre o novo cadastro de perfis
(U_JSPERFIL), que usa a tabela interna PNC_PERFIL_<empresa> - única para a empresa - no lugar da tabela do dicionário
de dados indicada no parâmetro MV_X_PNC16 (descontinuado)
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 2/21/2025
@return logical, lMudou - .T. quando algum perfil foi incluído, alterado ou excluído
/*/
user function JSPERCAL()
return U_JSPERFIL()

/*/{Protheus.doc} JSPERCHK
Mantida por compatibilidade com chamadas existentes: prepara o cadastro de perfis de cálculo (U_JSPFLCHK) - tabela
interna, migração do cadastro antigo e perfil padrão
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 2/23/2025
@return logical, lChecked
/*/
user function JSPERCHK()
return U_JSPFLCHK()
