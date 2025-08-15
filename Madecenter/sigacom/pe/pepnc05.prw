#include 'totvs.ch'
#include 'topconn.ch'

/*/{Protheus.doc} PEPNC05
Ponto de entrada do Painel de Compras que permite a adição de novos campos ao browse de produtos
@type function
@version 12.1.2410
@author Jean Carlos Pandolfo Saggin
@since 5/16/2025
@return array, aColumns
/*/
user function PEPNC05()
    
    local aDados   := PARAMIXB[1]
    local nLocal   := PARAMIXB[2]       // 1=Montagem do Header ou 2=Montagem do aCols
    local aColumns := {} as array
    local nX       := 0 as numeric
    local aLine    := {} as array
    
    if nLocal == 1      // Montagem do header
        for nX := 1 to len( aDados )
            aAdd( aColumns, aClone(aDados[nX]) )
            if AllTrim(aDados[nX][17]) == 'B1_DESC' // Quando chegar ao campo da descrição do produto, adiciona um campo para exibir o grupo de tabela de preço definido para o produto
                aAdd(aColumns, {;
                                GetSX3Cache( 'B1_XGPTP', 'X3_TITULO' ),;                     			// [n][01] Título da coluna
                                &("{|oBrw| aColPro[oBrw:At()]["+ cValToChar(nX+2) +"] }"),;             // [n][02] Code-Block de carga dos dados
                                GetSX3Cache( 'B1_XGPTP', 'X3_TIPO' ),;                					// [n][03] Tipo de dados
                                GetSX3Cache( 'B1_XGPTP', 'X3_PICTURE' ),;                     			// [n][04] Máscara
                                1,;                      												// [n][05] Alinhamento (0=Centralizado, 1=Esquerda ou 2=Direita)
                                GetSX3Cache( 'B1_XGPTP', 'X3_TAMANHO' )*0.6,;                           // [n][06] Tamanho
                                GetSX3Cache( 'B1_XGPTP', 'X3_DECIMAL' ),;                         		// [n][07] Decimal
                                .F. /* lCanEdit */,;                                                    // [n][08] Indica se permite a edição
                                {|| AlwaysTrue() },;                          							// [n][09] Code-Block de validação da coluna após a edição
                                .F.,;                            										// [n][10] Indica se exibe imagem
                                Nil,;                            										// [n][11] Code-Block de execução do duplo clique
                                Nil,;                                                                   // [n][12] Variável a ser utilizada na edição (ReadVar)
                                {|oBrw| sortCol(oBrw, aDados) },;          							    // [n][13] Code-Block de execução do clique no header
                                .F.,;                            										// [n][14] Indica se a coluna está deletada
                                .F.,;                            										// [n][15] Indica se a coluna será exibida nos detalhes do Browse
                                {},; 										                            // [n][16] Opções de carga dos dados (Ex: 1=Sim, 2=Não)
                                'B1_XGPTP' })                          								    // [n][17] Id da coluna
            endif
        next nX
    elseif nLocal == 2      // Montagem do aCols
        if ValType( oBrwPro ) == 'O' .and. len( aDados ) > 0
            for nX := 1 to len( aDados )
                aAdd( aLine, aDados[nX] )
                if nX+1 == aScan( oBrwPro:aCOLUMNS, {|x| x:cID == 'B1_XGPTP' } )
                    aAdd( aLine, RetField( 'SB1', 1, FWxFilial( 'SB1' ) + aDados[aScan( oBrwPro:aCOLUMNS, {|x| x:cID == 'B1_COD' } )], 'B1_XGPTP' ) )
                endif
            next nX
            aColumns := aClone( aLine )
            aLine := {}
        endif
    endif
return aColumns

/*/{Protheus.doc} sortCol
Função para ordenar grid conforme coluna que for clicada
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/22/2024
@param oBrw, object, Objeto do Browse
/*/
static function sortCol( oBrw, aHeader )
    local cCol := cValToChar(aScan(aHeader,{|x| AllTrim(x[17]) == 'B1_COD' }))  
    lCrescente := ! lCrescente
	aSort( aColPro,,, {|x,y| &("RetField('SB1', 1, FWxFilial('SB1')+x["+cCol+"],'B1_XGPTP')"+ iif( lCrescente, '>','<' ) +" RetField('SB1', 1, FWxFilial('SB1')+y["+cCol+"],'B1_XGPTP')") } )
	oBrw:UpdateBrowse()
return Nil
