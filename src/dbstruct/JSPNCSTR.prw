#include 'totvs.ch'
#include 'topconn.ch'

/*/{Protheus.doc} JSGETSTR
Função para retornar estrutura da tabela solicitada
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 3/3/2025
@param cTable, character, tabela
@return array, aStruct
/*/
user function JSGETSTR( cTable )

    local aStruct := {} as array

    // Configurações gerais
    if cTable == "PNC_CONFIG_"+ cEmpAnt

        aAdd( aStruct, { "FILIAL" , "C", len( cFilAnt ), 0 } )
        aAdd( aStruct, { "PRJEST" , "N", 3, 0 } )
        aAdd( aStruct, { "ITECRI" , "L", 1, 0 } )
        aAdd( aStruct, { "ITEALT" , "L", 1, 0 } )
        aAdd( aStruct, { "ITEMED" , "L", 1, 0 } )
        aAdd( aStruct, { "ITEBAI" , "L", 1, 0 } )
        aAdd( aStruct, { "ITESEM" , "L", 1, 0 } )
        aAdd( aStruct, { "ITESOB" , "L", 1, 0 } )
        aAdd( aStruct, { "TIPANA" , "C", 1, 0 } )
        aAdd( aStruct, { "QTDANA" , "N", 2, 0 } )
        aAdd( aStruct, { "INDCRI" , "N", 9, 6 } )
        aAdd( aStruct, { "INDALT" , "N", 9, 6 } )
        aAdd( aStruct, { "INDMED" , "N", 9, 6 } )
        aAdd( aStruct, { "INDBAI" , "N", 9, 6 } )
        aAdd( aStruct, { "TMPGIR" , "N", 3, 0 } )
        aAdd( aStruct, { "TPDIAS" , "C", 1, 0 } )
        aAdd( aStruct, { "LOCAIS" , "C", 70, 0 } )
        aAdd( aStruct, { "USPDES" , "C", 70, 0 } )
        aAdd( aStruct, { "PRILE"  , "C", 1, 0 } )
        aAdd( aStruct, { "CRIT"   , "C", 1, 0 } )
        aAdd( aStruct, { "TIPOS"  , "C", 100, 0 } )
        aAdd( aStruct, { "RELFOR" , "C", 1, 0 } )
        aAdd( aStruct, { "MAILWF" , "C", 100, 0 } )
        aAdd( aStruct, { "EMSATU" , "C", 1, 0 } )
        aAdd( aStruct, { "DHIST"  , "N", 3, 0 } )
        // aAdd( aStruct, { "LOCPAD" , "C", TAMSX3('NNR_CODIGO')[1], 0 } )

    elseif cTable == "PNC_CALC_PROD_"+ cEmpAnt

    elseif cTable == "PNC_ITENS_DESC_"+ cEmpAnt

    elseif cTable == "PNC_TAGS_"+ cEmpAnt

    elseif cTable == "PNC_ALERTAS_"+ cEmpAnt

    elseif cTable == "PNC_ALERTAS_ENV_"+ cEmpAnt

    elseif cTable == "PNC_PERFIS_"+ cEmpAnt

    endif

return aStruct

/*/{Protheus.doc} JSTBLCHK
Função para checagem da estrutura da tabela para saber se necessita atualização
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 3/12/2025
@param cTable, character, nome físico da tabela
@return character, cRet (I=Inserir U=Alterar ou O=Ok)
/*/
user function JSTBLCHK( cTable )
    
    local cRet    := "" as character       // I=Inserir, U=Alterar ou O=Ok (quando não precisa ajustar)
    local aStruct := {} as array
    local aOldStr := {} as array
    local cAlias  := "" as character

    if ! TCCanOpen( cTable )
        cRet := "I"             // Inserir
    else
        cAlias := GetNextAlias()
        DBUseArea( .T., 'TOPCONN', cTable, cAlias, .F., .F. )
        
        // Retorna estrutura da tabela para a versão atual do plugIn
        aStruct := U_JSGETSTR( cTable )

        // Obtem a estrutura atual da tabela física presente no banco
        aOldStr := ( cAlias )->( DBStruct() )
        ( cAlias )->( DBCloseArea() )

        // Compara as duas estruturas para saber se tem necessidade de atualizar
        if hasChange( aStruct, aOldStr, cTable )
            cRet := "U"
        else
            cRet := "O"
        endif
    endif

return cRet


/*/{Protheus.doc} hasChange
Função que avalia as estruturas do dicionário da rotina em comparação com o dicionário da tabela do banco
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 15/06/2023
@param aDic, array, dicionário da rotina
@param aBank, array, estrutura da tabela do banco
@param cTable, character, nome físico da tabela
@return logical, lHasChange
/*/
static function hasChange( aDic, aBank, cTable )
    
    local aArea      := getArea()
    Local lHasChange := .F. as logical
    Local nLine      := 0 as numeric
    Local nCol       := 0 as numeric
    Local nPos       := 0 as numeric
    Local aIndex     := {} as array

    for nLine := 1 to len( aDic )
        // Se o campo do dicionário existe na tabela do banco, compara a estrutura do campo pra ver se está igual
        nPos := aScan( aBank, {|x| AllTrim( x[1] ) == AllTrim( aDic[nLine][1] ) } )
        if nPos > 0
            for nCol := 1 to len( aBank[nPos] )
                // Compara campo a campo para ver se tem alguma alteração na estrutura da tabela
                lHasChange := lHasChange .or. ( aDic[nLine][nCol] != aBank[nPos][nCol] )
                // Se identificou qualquer alteração, sai fora do laço para dar mais performance para a rotina
                if lHasChange
                    Exit
                endif
            next nCol
        else
            lHasChange := .T.
        endif
        // Se identificou qualquer alteração, sai fora do laço para dar mais performance para a rotina
        if lHasChange
            Exit
        endif
    next nLine

    if ! lHasChange
        // Verifica se consegue abrir os índices
        aIndex := U_JSTBLIDX( cTable ) 
        if len( aIndex ) > 0
            aEval( aIndex, {|x| lHasChange := lHasChange .or. ! TCCanOpen( cTable, x[1] ) } )
        endif
    endif
    restArea( aArea )
return lHasChange

/*/{Protheus.doc} JSTBLIDX
Obtem os índices para a tabela especificada via parâmetro
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 3/7/2025
@param cTable, character, tabela
@return array, aIndex
/*/
user function JSTBLIDX( cTable )
    local aIndex := {} as array
     if cTable == "PNC_CONFIG_"+ cEmpAnt
        aAdd( aIndex, { "PNC_CONFIG_"+ cEmpAnt+'_01', 'Filial', {|| 'FILIAL' } } )
    endif
return aIndex


