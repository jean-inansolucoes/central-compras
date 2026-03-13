#include 'totvs.ch'
#include 'topconn.ch'

// Ponto de entrada que permite modificar a query de análise das movimentações de saída para o produto
// Parâmetro 1: Indica o local da chamada do PE, sendo 1- contagem dos registros de saída do produto
//													   2- contagem dos registros de movimentações internas ou OPs para o produto
//													   3- soma das quantidades de saída do produto
//													   4- soma das quantidades de movimentações internas ou OPs para o produto
//													   5- conta quantos documentos de saída foram emitidos no período
//													   6- conta quantas movimentações ou ops foram feitas no período													   5- conta quantos documentos de saída foram emitidos no período
//													   7- conta quantas movimentações ou ops foram feitas no período
//                                                     8- conta quantas movimentações ou ops foram feitas no período
// Parâmetro 2: Indica a query padrão do sistema
// Retorno esperado: query completa modificada ou incrementada pronta para execução

/*/{Protheus.doc} PEPNC08
PE para ajuste de query de cálculos de médias do produto no Painel de Compras
@type function
@version 12.1.2510
@author Jean Carlos Pandolfo Saggin
@since 12/03/2026
@return character, cReturn, query modificada
/*/
user function PEPNC08()
    
    local nLocal := PARAMIXB[1]
    local cQuery := PARAMIXB[2]
    local cReturn := cQuery

    // Ajusta apenas querys de leitura das movimentações internas do estoque (SD3)
    if nLocal == 2 .or. nLocal == 4 .or. nLocal == 6 .or. nLocal == 8
        cReturn += " AND D3.D3_DOC NOT LIKE '%INVENT%' "
    endif

return cReturn
