#include 'totvs.ch'
#include 'topconn.ch'

/*/{Protheus.doc} JSGETVER
Retorna a vers�o do aplicativo.
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 30/08/2024
@return character, cDetVer
/*/
user function JSGETVER()

    local cDetVer := "" as character
    local aDetVer := {} as array
    aDetVer := U_JSDETVER()
    cDetVer := aDetVer[len(aDetVer)][1] /* cDictVersion */ +'.'+;
                aDetVer[len(aDetVer)][2] /* cAppVersion */+' ('+;
                aDetVer[len(aDetVer)][3] /* cDate */+')'
return cDetVer

/*/{Protheus.doc} JSDETVER
Fun��o com detalhamento das vers�es do aplicativo.
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 30/08/2024
@return array, aDetVer
/*/
user function JSDETVER()
    local aDetVer := {} as array
    aAdd( aDetVer, { '01','0001','18/09/2024', 'Vers�o inicial do Painel de Compras' } )
    aAdd( aDetVer, { '02','0002','20/09/2024', 'Permite informar valor de frete ao pedido de compra e tamb�m informar um c�digo de transportadora relacionado ao processo.' } )
    aAdd( aDetVer, { '02','0003','20/09/2024', 'Permitir informar frete em percentual' } )
    aAdd( aDetVer, { '02','0004','21/09/2024', 'Permitir editar al�quota de IPI diretamente no carrinho' } )
    aAdd( aDetVer, { '02','0005','03/10/2024', 'Liberar edi��o de campos para simula��o de pre�o na tela de consulta de notas' } )
    aAdd( aDetVer, { '03','0006','06/10/2024', 'Permitir definir �ndice de lucro desej�vel por produto' } )
    aAdd( aDetVer, { '04','0001','16/10/2024', 'Controle de execu��o do JOB de rec�lculo dos �ndices individuais dos produtos' } )
    aAdd( aDetVer, { '04','0002','17/10/2024', 'Painel de Compras Multi-Filial' } )
return aDetVer

/*/{Protheus.doc} JSFILIAL
Fun��o para retornar express�o de filial conforme configura��es de cada tabela.
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 07/10/2024
@param cAlias, character, alias da tabela que se deseja executar um filtro de filial
@param aFil, array, vetor com filiais que se deseja filtrar
@return character, cFilExp
/*/
user function JSFILIAL( cAlias, aFil )
    
    local cFilExp := "" as character
    local aUsed   := {} as array
    local nSize   := Len( AllTrim( FWxFilial( cAlias ) ) )
    local nFil    := 0 as numeric
    local cAux    := "" as character
    local cField  := iif( SubStr( cAlias, 01, 01 ) == 'S', SubStr( cAlias, 02,02 ) +'_FILIAL', cAlias +'_FILIAL' )
    local nAux    := 0 as numeric

    if nSize > 0 

        // Repassa todas as filiais selecionadas pelo usu�rio e monta um subvetor com as filiais j� compatibilizadas com o tamanho utilizado pela tabela
        for nFil := 1 to len(aFil)
            cAux := SubStr( FWxFilial( cAlias ), 01, nSize )
            if aScan( aUsed, {|x| AllTrim(x) == AllTrim(cAux) } ) == 0
                aAdd( aUsed, PADR(cAux, TAMSX3( cField )[1], ' ' ) )
            endif
        next nFil
       
        // Monta express�o IN para uso na query
        if len( aUsed ) == 0
            cFilExp := " = '"+ Replicate( 'Z', TAMSX3( cField )[1] ) +"' "
        elseif len( aUsed ) == 1        // Se foi selecionado apenas uma filial, muda a express�o da query para dar mais performance
            cFilExp := " = '"+ aUsed[1] +"' "
        else
            cFilExp := " IN ( "
            aEval( aUsed, {|x| nAux++, cFilExp += "'"+ x +"'" + iif( nAux < len( aUsed ), ',', '' ) } )        
            cFilExp += " ) "
        endif

    elseif nSize == 0 .and. len( aFil ) > 0                 // Se existir filial selecionada e o tamanho do campo for zero
        cFilExp := " = '"+ FWxFilial( cAlias ) +"' "

    elseif nSize == 0 .and. len( aFil ) == 0                // Erra o filtro propositalmente para fazer com que o banco n�o retorne nenhum registro.
        cFilExp := " <> '"+ FWxFilial( cAlias ) +"'  "  
    endif

return cFilExp

/*/{Protheus.doc} JSFILCOM
Fun��o para retornar algoritmo de compara��o entre os campos filiais de dois al�ases diferentes
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 14/10/2024
@param cLeft, character, tabela da esquerda de onde est� vindo o dado para ser comparado
@param cRight, character, tabela da difeita onde est� sendo executado o filtro para encontrar os dados relacionados
@param cAliasLeft, character, alias atribu�do � tabela na query (n�o obrigat�rio)
@param cAliasRight, character, alias atribu�do � tabela na query (n�o obrigat�rio)
@return character, cExpression
/*/
User Function JSFILCOM( cLeft, cRight, cAliasLeft, cAliasRight )

    local cFunction   := iif( TCGetDB() $ "MSSQL|POSTGRES", "SUBSTRING", "SUBSTR" )
    local cExpression := "" as character
    local cFieldLeft  := iif( SubStr( cLeft,1,1 ) == 'S', SubStr( cLeft,2,2 ), cLeft ) + '_FILIAL'
    local cFieldRight := iif( SubStr( cRight,1,1 ) == 'S', SubStr( cRight,2,2 ), cRight ) + '_FILIAL'
    
    default cAliasLeft  := iif( SubStr( cLeft,1,1 ) == 'S', SubStr( cLeft,2,2 ), cLeft ) +"."
    default cAliasRight := iif( SubStr( cRight,1,1 ) == 'S', SubStr( cRight,2,2 ), cRight ) +"."
    
    // Verifica se a tratativa de filial � diferente para as duas tabelas
    if ! FWxFilial( cLeft ) == FWxFilial( cRight )

        // Se for diferente, verifica se a tabela da esquerda usa filial compartilhada
        if Len( AllTrim( FWxFilial( cLeft ) ) ) == 0

            // Se usa filial compartilhada, apenas compara com FWxFilial, pois a express�o ficar� assim: A1_FILIAL = '  '
            cExpression := cAliasLeft + cFieldLeft +" = '"+ FWxFilial( cLeft ) +"' "
        
        // Verifica se a tabela da direita usa filial compartilhada
        elseif Len( AllTrim( FWxFilial( cRight ) ) ) == 0
        
            // Se usa filial compartilhada, chama fun��o que retorna um filtro IN para a SQL usando as filiais selecionadas pelo usu�rio para filtrar os registros do alias da esquerda
            cExpression := cAliasLeft + cFieldLeft + U_JSFILIAL( cLeft, _aFil ) + ' '
        
        // Verifica se o tamanho do conte�do da filial da tabela da esquerda � menor do que o da direita
        elseif Len( AllTrim( FWxFilial( cLeft ) ) ) < Len( AllTrim( FWxFilial( cRight ) ) )

            // Se a informa��o da filial da tabel a da esquerda for menor do que a informa��o da filial da tabela da direita, compara as duas usando substring para adequar o tamanho das duas informa��es
            cExpression := cFunction +'('+ cAliasLeft + cFieldLeft +',1,'+ cValToChar( Len( AllTrim( FWxFilial( cLeft ) ) ) ) +') = '+ cFunction +'('+ cAliasRight + cFieldRight +',1,'+ cValToChar( Len( AllTrim( FWxFilial( cLeft ) ) ) ) +') '
        else
            cExpression := cFunction +'('+ cAliasLeft + cFieldLeft +',1,'+ cValToChar( Len( AllTrim( FWxFilial( cRight ) ) ) ) +') = '+ cFunction +'('+ cAliasRight + cFieldRight +',1,'+ cValToChar( Len( AllTrim( FWxFilial( cRight ) ) ) ) +') '
        endif

    else
        cExpression := cAliasLeft + cFieldLeft + ' = ' + cAliasRight + cFieldRight
    endif

return cExpression
