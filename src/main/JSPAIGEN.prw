#include 'totvs.ch'
#include 'topconn.ch'

/*/{Protheus.doc} JSGETVER
Retorna a versão do aplicativo.
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
Função com detalhamento das versões do aplicativo.
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 30/08/2024
@return array, aDetVer
/*/
user function JSDETVER()
    local aDetVer := {} as array
    aAdd( aDetVer, { '01','0001','18/09/2024', 'Versão inicial do Painel de Compras' } )
    aAdd( aDetVer, { '02','0002','20/09/2024', 'Permite informar valor de frete ao pedido de compra e também informar um código de transportadora relacionado ao processo.' } )
    aAdd( aDetVer, { '02','0003','20/09/2024', 'Permitir informar frete em percentual' } )
    aAdd( aDetVer, { '02','0004','21/09/2024', 'Permitir editar alíquota de IPI diretamente no carrinho' } )
    aAdd( aDetVer, { '02','0005','03/10/2024', 'Liberar edição de campos para simulação de preço na tela de consulta de notas' } )
    aAdd( aDetVer, { '03','0006','06/10/2024', 'Permitir definir índice de lucro desejável por produto' } )
    aAdd( aDetVer, { '04','0001','16/10/2024', 'Controle de execução do JOB de recálculo dos índices individuais dos produtos' } )
    aAdd( aDetVer, { '04','0002','17/10/2024', 'Painel de Compras Multi-Filial' } )
    aAdd( aDetVer, { '05','0001','12/11/2024', 'Adaptação para release 12.1.2410 usando smartclient webapp' } )
    aAdd( aDetVer, { '05','0002','13/11/2024', 'Novo formato de filtros, remodelagem da engine de cálculos e substituição de componentes obsoletos' } )
    aAdd( aDetVer, { '05','0003','13/11/2024', 'Workflow automático para fornecedor' } )
return aDetVer

/*/{Protheus.doc} JSFILIAL
Função para retornar expressão de filial conforme configurações de cada tabela.
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

        // Repassa todas as filiais selecionadas pelo usuário e monta um subvetor com as filiais já compatibilizadas com o tamanho utilizado pela tabela
        for nFil := 1 to len(aFil)
            cAux := SubStr( FWxFilial( cAlias ), 01, nSize )
            if aScan( aUsed, {|x| AllTrim(x) == AllTrim(cAux) } ) == 0
                aAdd( aUsed, PADR(cAux, TAMSX3( cField )[1], ' ' ) )
            endif
        next nFil
       
        // Monta expressão IN para uso na query
        if len( aUsed ) == 0
            cFilExp := " = '"+ Replicate( 'Z', TAMSX3( cField )[1] ) +"' "
        elseif len( aUsed ) == 1        // Se foi selecionado apenas uma filial, muda a expressão da query para dar mais performance
            cFilExp := " = '"+ aUsed[1] +"' "
        else
            cFilExp := " IN ( "
            aEval( aUsed, {|x| nAux++, cFilExp += "'"+ x +"'" + iif( nAux < len( aUsed ), ',', '' ) } )        
            cFilExp += " ) "
        endif

    elseif nSize == 0 .and. len( aFil ) > 0                 // Se existir filial selecionada e o tamanho do campo for zero
        cFilExp := " = '"+ FWxFilial( cAlias ) +"' "

    elseif nSize == 0 .and. len( aFil ) == 0                // Erra o filtro propositalmente para fazer com que o banco não retorne nenhum registro.
        cFilExp := " <> '"+ FWxFilial( cAlias ) +"'  "  
    endif

return cFilExp

/*/{Protheus.doc} JSFILCOM
Função para retornar algoritmo de comparação entre os campos filiais de dois alíases diferentes
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 14/10/2024
@param cLeft, character, tabela da esquerda de onde está vindo o dado para ser comparado
@param cRight, character, tabela da difeita onde está sendo executado o filtro para encontrar os dados relacionados
@param cAliasLeft, character, alias atribuído à tabela na query (não obrigatório)
@param cAliasRight, character, alias atribuído à tabela na query (não obrigatório)
@return character, cExpression
/*/
User Function JSFILCOM( cLeft, cRight, cAliasLeft, cAliasRight )

    local cFunction   := iif( TCGetDB() $ "MSSQL|POSTGRES", "SUBSTRING", "SUBSTR" )
    local cExpression := "" as character
    local cFieldLeft  := iif( SubStr( cLeft,1,1 ) == 'S', SubStr( cLeft,2,2 ), cLeft ) + '_FILIAL'
    local cFieldRight := iif( SubStr( cRight,1,1 ) == 'S', SubStr( cRight,2,2 ), cRight ) + '_FILIAL'
    local cALeft      := "" as character
    local cARight     := "" as character
    
    default cAliasLeft  := iif( SubStr( cLeft,1,1 ) == 'S', SubStr( cLeft,2,2 ), cLeft )
    default cAliasRight := iif( SubStr( cRight,1,1 ) == 'S', SubStr( cRight,2,2 ), cRight )
    
    cALeft := cAliasLeft+'.'
    cARight := cAliasRight+'.'

    // Verifica se a tratativa de filial é diferente para as duas tabelas
    if ! FWxFilial( cLeft ) == FWxFilial( cRight )

        // Se for diferente, verifica se a tabela da esquerda usa filial compartilhada
        if Len( AllTrim( FWxFilial( cLeft ) ) ) == 0

            // Se usa filial compartilhada, apenas compara com FWxFilial, pois a expressão ficará assim: A1_FILIAL = '  '
            cExpression := cALeft + cFieldLeft +" = '"+ FWxFilial( cLeft ) +"' "
        
        // Verifica se a tabela da direita usa filial compartilhada
        elseif Len( AllTrim( FWxFilial( cRight ) ) ) == 0
        
            // Se usa filial compartilhada, chama função que retorna um filtro IN para a SQL usando as filiais selecionadas pelo usuário para filtrar os registros do alias da esquerda
            cExpression := cALeft + cFieldLeft + U_JSFILIAL( cLeft, _aFil ) + ' '
        
        // Verifica se o tamanho do conteúdo da filial da tabela da esquerda é menor do que o da direita
        elseif Len( AllTrim( FWxFilial( cLeft ) ) ) < Len( AllTrim( FWxFilial( cRight ) ) )

            // Se a informação da filial da tabel a da esquerda for menor do que a informação da filial da tabela da direita, compara as duas usando substring para adequar o tamanho das duas informações
            cExpression := cFunction +'('+ cALeft + cFieldLeft +',1,'+ cValToChar( Len( AllTrim( FWxFilial( cLeft ) ) ) ) +') = '+ cFunction +'('+ cARight + cFieldRight +',1,'+ cValToChar( Len( AllTrim( FWxFilial( cLeft ) ) ) ) +') '
        else
            cExpression := cFunction +'('+ cALeft + cFieldLeft +',1,'+ cValToChar( Len( AllTrim( FWxFilial( cRight ) ) ) ) +') = '+ cFunction +'('+ cARight + cFieldRight +',1,'+ cValToChar( Len( AllTrim( FWxFilial( cRight ) ) ) ) +') '
        endif

    else
        cExpression := cALeft + cFieldLeft + ' = ' + cARight + cFieldRight
    endif

return cExpression

/*/{Protheus.doc} JSPAITYP
Função da consulta padrão PAITYP para retornar tipos de produtos desejados.
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/8/2024
@param cTipos, character, tipos de produtos que estão filtrados
@return character, _cTypes
/*/
user function JSPAITYP( cTipos )
    
    local oDlgType as object
    local oMain    as object
    local oTipos   as object
    local aTipos   := {} as array
    local aColumns := {} as array
    local lMark    := .F. as logical
    local aTypes   := {} as array
    local cRet  := "" as character

    aTypes := StrTokArr( AllTrim(cTipos), "/" )

    DBSelectArea( 'SX5' )
	SX5->( DBSetOrder(1) )
		if DBSeek( FWxFilial( 'SX5' ) + '02'  )
		while ! SX5->( EOF() ) .and. SX5->X5_FILIAL == FWxFilial( 'SX5' ) .AND. SX5->X5_TABELA == '02'
			aAdd( aTipos, { aScan( aTypes, {|x| AllTrim(x) == AllTrim( SX5->X5_CHAVE ) } ) > 0,;
							AllTrim( SX5->X5_CHAVE ),;
							AllTrim( SX5->X5_DESCRI ) } )
			SX5->( DBSkip() )
		end
	endif

    aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( 'Tipo' )
	aColumns[len(aColumns)]:SetSize( 2 )
	aColumns[len(aColumns)]:SetType( 'C' )
	aColumns[len(aColumns)]:SetPicture( '@!' )
	aColumns[len(aColumns)]:SetData( {|| aTipos[oTipos:nAt][2] } )
	
	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( 'Descrição' )
	aColumns[len(aColumns)]:SetSize( 30 )
	aColumns[len(aColumns)]:SetType( 'C' )
	aColumns[len(aColumns)]:SetPicture( '@x' )
	aColumns[len(aColumns)]:SetData( {|| aTipos[oTipos:nAt][3] } )

    oDlgType := FWDialogModal():New()
    oDlgType:SetEscClose( .T. )
    oDlgType:SetTitle( "Tipos de Produtos" )
    oDlgType:SetSize( 310, 200 )
    oDlgType:SetSubTitle( "Selecione um ou mais tipos de produtos para análise..." )
    oDlgType:CreateDialog()
	oDlgType:AddCloseButton( {|| oDlgType:DeActivate()}, "Cancelar" )
	oDlgType:AddOkButton( {|| cRet := "",; 
                             aEval( aTipos, {|x| iif( x[1], cRet += iif( Empty(cRet),"","/" )+ x[2], Nil ) } ),;
                              oDlgType:DeActivate() }, "Ok" )

    oMain := oDlgType:GetPanelMain()

    oTipos := FWBrowse():New( oMain )
	oTipos:SetDataArray()
	oTipos:SetArray( aTipos )
	oTipos:DisableConfig()
	oTipos:DisableReport()
	oTipos:SetLineHeight(20)
	oTipos:AddMarkColumns( {|oTipos| if( aTipos[oTipos:nAt][1], 'LBOK','LBNO' ) },;
							{|oTipos| aTipos[oTipos:nAt][1] := !aTipos[oTipos:nAt][1] },;
							{|oTipos| lMark := !aTipos[1][1], aEval( aTipos, {|x| x[1] := lMark } ), oTipos:UpdateBrowse() } )
	oTipos:SetColumns( aColumns )
	oTipos:Activate()

    oDlgType:Activate()
    
    cRet := PADR( cRet, 200, ' ' )

return cRet

