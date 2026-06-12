#Include "totvs.ch"

/*/{Protheus.doc} PEPNC10
Ponto de Entrada para customização da condição de pagamento no fechamento do pedido de compra.
Este Ponto de Entrada é chamado durante a abertura do carrinho de compras (função fCarCom)
permitindo que o cliente customize a sugestão de condição de pagamento baseado em regras
específicas de negócio.
@type function
@version 12.1.2510
@since 06/12/2026
@return character, cNewCond
*/
User Function PEPNC10()

	local aArea    := getArea()
	local cCondPg  := PARAMIXB[1]		// Condição de pagamento sugerida pela rotina padrão
	local cFornece := PARAMIXB[2]		// Código do fornecedor
	local cLoja    := PARAMIXB[3]		// Loja do fornecedor
	// local aDados   := PARAMIXB[4]		// aCols antes da remoção dos campos de controle para exibição na rotina
	// local aHeader  := PARAMIXB[5]		// aHeader do carrinho de compras
	local cNewCond := Space( TAMSX3('C7_COND')[1] )			// Inicializa com a condição de pagamento sugerida pelo padrão

	DBSelectArea( 'AIA' )
	AIA->( DBSetOrder( 1 ) )
	if AIA->( DBSeek( FWxFilial( 'AIA' ) + cFornece + cLoja ) )
		// Percorre o cadastro de tabelas de preços por fornecedor para encontrar umas tabela de preços válida
		while ! AIA->( EOF() ) .and. AIA->AIA_FILIAL + AIA->AIA_CODFOR + AIA->AIA_LOJFOR == FWxFilial( 'AIA' ) + cFornece + cLoja .and. Empty( cNewCond )
			// Verifica se a tabela de preços está ativa
			if AIA->AIA_DATDE <= dDataBase .and. ( AIA->AIA_DATATE >= dDataBase .or. AIA->AIA_DATATE == StoD(" ") )
				// Retorna a condição de pagamento atrelada à tabela de preços
				cNewCond := AIA->AIA_CONDPG
			endif
		end
	endif

	// Quando não conseguiu localizar outra condição de pagamento, retorna a que o sistema sugeriu
	if Empty( cNewCond )
		cNewCond := cCondPg
	endif

	restArea( aArea )
Return cNewCond
