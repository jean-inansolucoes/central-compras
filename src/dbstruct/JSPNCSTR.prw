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
        aAdd( aStruct, { "LOCPAD" , "C", TAMSX3('B2_LOCAL')[1], 0 } )
        aAdd( aStruct, { "TPDOC"  , "C", 1, 0 } )
        aAdd( aStruct, { "MDPED"  , "C", 1, 0 } )
        aAdd( aStruct, { "CMT"    , "C", 1, 0 } )
        aAdd( aStruct, { "TRFFIL" , "C", 1, 0 } )
        aAdd( aStruct, { "ANAREV" , "C", 1, 0 } )
        aAdd( aStruct, { "CONSLT" , "C", 1, 0 } )		// Considera o lead time do fornecedor na previsão de demanda de compra da análise reversa (default 'Falso')
        aAdd( aStruct, { "ULTORI" , "C", 1, 0 } )		// Origem do último preço: 1=Última Nota de Entrada (default) ou 2=Último Pedido de Compra
        aAdd( aStruct, { "MODNEC" , "C", 1, 0 } )		// Modo de cálculo multi-filial: 1=Individual por Filial (default) ou 2=Pool/Consolidado

    // Resultado da análise reversa de estruturas por produto (consumido pela grid principal)
    elseif cTable == "PNC_RVCALC_"+ cEmpAnt

        aAdd( aStruct, { "FILIAL" , "C", len( cFilAnt ), 0 } )
        aAdd( aStruct, { "PROD"   , "C", TAMSX3('B1_COD')[1], 0 } )
        aAdd( aStruct, { "DTCALC" , "C", 8, 0 } )
        aAdd( aStruct, { "ISCOMP" , "C", 1, 0 } )
        aAdd( aStruct, { "NECREV" , "N", 14, 2 } )
        aAdd( aStruct, { "DEMESTR", "N", 14, 2 } )
        aAdd( aStruct, { "DEMLDT" , "N", 14, 2 } )		// Quantidade adicional sugerida em virtude do lead-time de entrega do fornecedor da MP (parte da demanda estrutural, quando CONSLT = 'S')
        aAdd( aStruct, { "DEMVND" , "N", 14, 2 } )
        aAdd( aStruct, { "VENDIA" , "N", 14, 4 } )
        aAdd( aStruct, { "CONDIA" , "N", 14, 4 } )
        aAdd( aStruct, { "POSABT" , "N", 14, 2 } )
        aAdd( aStruct, { "NFINAIS", "N", 4, 0 } )
        aAdd( aStruct, { "DTEXEC" , "C", 14, 0 } )

    // Trace da sequência de cálculo da análise reversa (consumido pela tela Sequência de Cálculo)
    elseif cTable == "PNC_RVTRC_"+ cEmpAnt

        aAdd( aStruct, { "FILIAL" , "C", len( cFilAnt ), 0 } )
        aAdd( aStruct, { "MP"     , "C", TAMSX3('B1_COD')[1], 0 } )
        aAdd( aStruct, { "DTCALC" , "C", 8, 0 } )
        aAdd( aStruct, { "SEQ"    , "C", 6, 0 } )
        aAdd( aStruct, { "NIVEL"  , "N", 2, 0 } )
        aAdd( aStruct, { "PAI"    , "C", TAMSX3('B1_COD')[1], 0 } )
        aAdd( aStruct, { "PROD"   , "C", TAMSX3('B1_COD')[1], 0 } )
        aAdd( aStruct, { "QTPOR"  , "N", 11, 4 } )
        aAdd( aStruct, { "NECBRT" , "N", 14, 2 } )
        aAdd( aStruct, { "ESTABT" , "N", 14, 2 } )
        aAdd( aStruct, { "OPABT"  , "N", 14, 2 } )
        aAdd( aStruct, { "NECLIQ" , "N", 14, 2 } )
        aAdd( aStruct, { "CONTRIB", "N", 14, 2 } )
        aAdd( aStruct, { "TIPO"   , "C", 1, 0 } )

    // Snapshot diário de índices por produto (materializado por U_GMINDPRO, consumido pelo Painel de Compras)
    elseif cTable == "PNC_PROD_"+ cEmpAnt

        aAdd( aStruct, { "FILIAL" , "C", len( cFilAnt ), 0 } )
        aAdd( aStruct, { "PROD"   , "C", TAMSX3('B1_COD')[1], 0 } )
        aAdd( aStruct, { "DTREF"  , "D", 8, 0 } )
        aAdd( aStruct, { "SALDO"  , "N", 12, 2 } )
        aAdd( aStruct, { "CONMED" , "N", 14, 4 } )
        aAdd( aStruct, { "NECCOM" , "N", 12, 2 } )
        aAdd( aStruct, { "QTDCOM" , "N", 12, 2 } )
        aAdd( aStruct, { "QTDEMP" , "N", 12, 2 } )
        aAdd( aStruct, { "PRJEST" , "N", 3, 0 } )
        aAdd( aStruct, { "LDTIME" , "N", 3, 0 } )
        aAdd( aStruct, { "TMPGIR" , "N", 3, 0 } )
        aAdd( aStruct, { "TPDIAS" , "C", 1, 0 } )
        aAdd( aStruct, { "INDINC" , "N", 10, 6 } )
        aAdd( aStruct, { "PRVENT" , "D", 8, 0 } )
        aAdd( aStruct, { "CM03M"  , "N", 14, 4 } )		// Média de consumo dos últimos 3 meses
        aAdd( aStruct, { "CM06M"  , "N", 14, 4 } )		// Média de consumo dos últimos 6 meses
        aAdd( aStruct, { "CM12M"  , "N", 14, 4 } )		// Média de consumo dos últimos 12 meses
        aAdd( aStruct, { "CMANT"  , "N", 14, 4 } )		// Média de consumo do mês anterior
        aAdd( aStruct, { "AVISO"  , "C", 1, 0 } )
        aAdd( aStruct, { "MSG"    , "C", 250, 0 } )
        aAdd( aStruct, { "JUSTIF" , "C", 3, 0 } )
        aAdd( aStruct, { "COMPL"  , "M", 10, 0 } )

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
        // lNewArea=.T. garante uma área de trabalho NOVA; com .F. o DBUseArea reaproveitava
        // (fechava) a área atualmente selecionada, o que chegou a derrubar a SM0 quando ela
        // era a área corrente no momento da checagem das estruturas
        DBUseArea( .T., 'TOPCONN', cTable, cAlias, .T., .F. )

        // TCCanOpen pode indicar sucesso e o DBUseArea ainda assim não abrir a área (ex.:
        // tabela sendo criada/alterada em paralelo por outra thread) - sem essa checagem,
        // o DBStruct() abaixo dispara "Alias does not exist" por operar num alias inexistente
        if Select( cAlias ) == 0
            cRet := "U"             // Força o fluxo de atualização/recriação da estrutura
        else
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
    elseif cTable == "PNC_RVCALC_"+ cEmpAnt
        aAdd( aIndex, { "PNC_RVCALC_"+ cEmpAnt+'_01', 'FILIAL+PROD+DTCALC', {|| 'FILIAL+PROD+DTCALC' } } )
    elseif cTable == "PNC_RVTRC_"+ cEmpAnt
        aAdd( aIndex, { "PNC_RVTRC_"+ cEmpAnt+'_01', 'FILIAL+MP+DTCALC+SEQ', {|| 'FILIAL+MP+DTCALC+SEQ' } } )
    elseif cTable == "PNC_PROD_"+ cEmpAnt
        aAdd( aIndex, { "PNC_PROD_"+ cEmpAnt+'_01', 'FILIAL+PROD+DTOS(DTREF)', {|| 'FILIAL+PROD+DTOS(DTREF)' } } )
    endif
return aIndex


