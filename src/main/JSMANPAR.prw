#include 'totvs.ch'
#include 'topconn.ch'

/*/{Protheus.doc} JSMANPAR
Função para manutenção dos parâmetros internos do Painel de Compras a partir da versão 19.001.
Opera diretamente sobre a tabela própria PNC_CONFIG_<empresa> (fora do dicionário de dados do
Protheus), tanto para inclusão da configuração inicial da filial quanto para alteração dos
valores já gravados. A tela é construída com controles nativos (MSGET/CHECKBOX/MSCOMBOBOX)
posicionados diretamente sobre o painel, pois a tabela não está registrada no dicionário (SX3)
e portanto não pode ser editada por componentes MVC dependentes de estrutura de dicionário
(FWFormStruct/FWFormView) nem pelo antigo MsMGet (cujo contrato de parâmetros de baixo nível
não é possível validar com segurança nesta versão do framework).
@type function
@version 20.0003
@author Jean Carlos Pandolfo Saggin
@since 29/01/2026
@param nOpc, numeric, Indica a forma de acesso à rotina (3=Incluir, 4=Alterar)
@return logical, lSuccess
/*/
user function JSMANPAR( nOpc )

    local lSuccess  := .T. as logical
    local oDlgPar   as object
    local oContainer as object
    local aFields   := U_JSGETSTR( "PNC_CONFIG_"+ cEmpAnt )
    local aItTipAna := { "1=Diário", "2=Semanal", "3=Mensal" } as array
    local aItTpDias := { "C=Corridos", "U=Úteis" } as array
    local aItCrit   := { "1=Preço", "2=Lead Time" } as array
    local aItRelFor := { "1=Fabricante", "2=Prod. x Fornecedor", "3=Histórico de Compras" } as array
    local aItTpDoc  := { "1=Pedido de Compra", "2=Solicitação" } as array
    local aItMdPed  := { "N=Normal", "C=Customizado" } as array

    private cCadastro := "Parâmetros Painel de Compras"
    private INCLUI    := .F. as logical
    private ALTERA    := .F. as logical

    private lPrile   := .F. as logical
    private lEmsatu  := .F. as logical
    private lCmt     := .F. as logical
    private lTrfFil  := .F. as logical
    private lAnaRev  := .F. as logical

    default nOpc := 3 // 3-Incluir, 4-Alterar

    INCLUI := nOpc == 3
    ALTERA := nOpc == 4

    if INCLUI .or. ALTERA

        // Valores padrão de fábrica - usados na inclusão e como base para a alteração
        // (quando ALTERA, os valores abaixo são sobrepostos pelos dados gravados na PNC_CONFIG logo em seguida)
        M->FILIAL    := cFilAnt
        M->PRJEST    := 30
        M->ITECRI    := .T.
        M->ITEALT    := .T.
        M->ITEMED    := .T.
        M->ITEBAI    := .T.
        M->ITESEM    := .T.
        M->ITESOB    := .T.
        M->TIPANA    := "3" // 1=Diário, 2=Semanal, 3=Mensal
        M->QTDANA    := 6
        M->INDCRI    := 0.100000
        M->INDALT    := 0.100000
        M->INDMED    := 0.010000
        M->INDBAI    := 0.001000
        M->TMPGIR    := 180
        M->TPDIAS    := "C" // C=Corridos, U=Uteis
        M->LOCAIS    := Space( fldLen( aFields, 'LOCAIS' ) )
        M->USPDES    := Space( fldLen( aFields, 'USPDES' ) )
        M->PRILE     := "N" // N=Não, S=Sim
        M->CRIT      := "1" // 1=Preço ou 2=Lead Time
        M->TIPOS     := PADR( "ME/MP/OI/IN", fldLen( aFields, 'TIPOS' ) )
        M->RELFOR    := "1"
        M->MAILWF    := Space( fldLen( aFields, 'MAILWF' ) )
        M->EMSATU    := "S" // S=Sim ou N=Não
        M->DHIST     := 5
        M->LOCPAD    := Space( fldLen( aFields, 'LOCPAD' ) )
        M->TPDOC     := "1" // 1=Pedido de Compra ou 2=Solicitação
        M->MDPED     := "N" // N=Normal ou C=Customizado
        M->CMT       := "S" // S=Sim ou N=Não
        M->TRFFIL    := "N" // N=Não, S=Sim (considera movimentações de transferência intra-grupo no cálculo de média)
        M->ANAREV    := "N" // N=Não, S=Sim (deriva a sugestão de compra dos componentes a partir das estruturas - análise reversa)

        // Na alteração, sobrepõe os defaults acima pelos valores efetivamente gravados na PNC_CONFIG da filial
        if ALTERA
            loadCfg( aFields )
        endif

        // Traduz os campos S/N armazenados como caractere para os auxiliares de tela (checkbox)
        lPrile  := M->PRILE  == 'S'
        lEmsatu := M->EMSATU == 'S'
        lCmt    := M->CMT    == 'S'
        lTrfFil := M->TRFFIL == 'S'
        lAnaRev := M->ANAREV == 'S'

    endif

    oDlgPar := FWDialogModal():New()
	oDlgPar:SetEscClose( .T. )
	oDlgPar:SetTitle( 'SmartSupply - Parâmetros Internos - '+ U_JSGETVER() )
	oDlgPar:SetSubTitle( 'Parâmetros Internos do Painel de Compras' )
	oDlgPar:SetSize( 380, 580 )
	oDlgPar:EnableAllClient()
	oDlgPar:CreateDialog()
	oDlgPar:AddCloseButton( {|| lSuccess := .F., oDlgPar:DeActivate() }, "Cancelar" )
	oDlgPar:AddOkButton( {|| lSuccess := applyAux( aFields ), iif( lSuccess, oDlgPar:DeActivate(), Nil ) }, "Confirmar" )
	oContainer := TPanel():New( ,,, oDlgPar:getPanelMain() )
	oContainer:Align := CONTROL_ALIGN_ALLCLIENT

	// Coluna A (esquerda)
	@ 010, 010 SAY oLblA01 PROMPT "Proj.Estoque(d)"  SIZE 078, 008 OF oContainer PIXEL
	@ 008, 092 MSGET oCtlA01 VAR M->PRJEST SIZE 130, 010 OF oContainer PICTURE "999" PIXEL

	@ 030, 010 CHECKBOX oCtlA02 VAR M->ITECRI PROMPT "Traz Itens Críticos"    SIZE 210, 008 OF oContainer PIXEL
	@ 050, 010 CHECKBOX oCtlA03 VAR M->ITEALT PROMPT "Traz Itens Alto Giro"   SIZE 210, 008 OF oContainer PIXEL
	@ 070, 010 CHECKBOX oCtlA04 VAR M->ITEMED PROMPT "Traz Itens Médio Giro"  SIZE 210, 008 OF oContainer PIXEL
	@ 090, 010 CHECKBOX oCtlA05 VAR M->ITEBAI PROMPT "Traz Itens Baixo Giro"  SIZE 210, 008 OF oContainer PIXEL
	@ 110, 010 CHECKBOX oCtlA06 VAR M->ITESEM PROMPT "Traz Itens Sem Giro"    SIZE 210, 008 OF oContainer PIXEL
	@ 130, 010 CHECKBOX oCtlA07 VAR M->ITESOB PROMPT "Traz Itens Sob Demanda" SIZE 210, 008 OF oContainer PIXEL

	@ 150, 010 SAY oLblA08 PROMPT "Tipo Sazonalidade" SIZE 078, 008 OF oContainer PIXEL
	@ 148, 092 MSCOMBOBOX oCtlA08 VAR M->TIPANA ITEMS aItTipAna SIZE 130, 060 OF oContainer PIXEL

	@ 170, 010 SAY oLblA09 PROMPT "Qtd.Períodos Sazon." SIZE 078, 008 OF oContainer PIXEL
	@ 168, 092 MSGET oCtlA09 VAR M->QTDANA SIZE 130, 010 OF oContainer PICTURE "99" PIXEL

	@ 190, 010 SAY oLblA10 PROMPT "Índice Críticos"   SIZE 078, 008 OF oContainer PIXEL
	@ 188, 092 MSGET oCtlA10 VAR M->INDCRI SIZE 130, 010 OF oContainer PICTURE "99.999999" PIXEL

	@ 210, 010 SAY oLblA11 PROMPT "Índice Alto Giro"  SIZE 078, 008 OF oContainer PIXEL
	@ 208, 092 MSGET oCtlA11 VAR M->INDALT SIZE 130, 010 OF oContainer PICTURE "99.999999" PIXEL

	@ 230, 010 SAY oLblA12 PROMPT "Índice Médio Giro" SIZE 078, 008 OF oContainer PIXEL
	@ 228, 092 MSGET oCtlA12 VAR M->INDMED SIZE 130, 010 OF oContainer PICTURE "99.999999" PIXEL

	@ 250, 010 SAY oLblA13 PROMPT "Índice Baixo Giro" SIZE 078, 008 OF oContainer PIXEL
	@ 248, 092 MSGET oCtlA13 VAR M->INDBAI SIZE 130, 010 OF oContainer PICTURE "99.999999" PIXEL

	@ 270, 010 SAY oLblA14 PROMPT "Dias p/Cálc.Giro"  SIZE 078, 008 OF oContainer PIXEL
	@ 268, 092 MSGET oCtlA14 VAR M->TMPGIR SIZE 130, 010 OF oContainer PICTURE "999" PIXEL

	@ 290, 010 SAY oLblA15 PROMPT "Tipo de Dias"      SIZE 078, 008 OF oContainer PIXEL
	@ 288, 092 MSCOMBOBOX oCtlA15 VAR M->TPDIAS ITEMS aItTpDias SIZE 130, 040 OF oContainer PIXEL

	// Coluna B (direita)
	@ 010, 280 SAY oLblB01 PROMPT "Locais de Estoque"  SIZE 078, 008 OF oContainer PIXEL
	@ 008, 362 MSGET oCtlB01 VAR M->LOCAIS SIZE 200, 010 OF oContainer PIXEL

	@ 030, 280 SAY oLblB02 PROMPT "Usuários p/Notificar" SIZE 078, 008 OF oContainer PIXEL
	@ 028, 362 MSGET oCtlB02 VAR M->USPDES SIZE 200, 010 OF oContainer PIXEL

	@ 050, 280 CHECKBOX oCtlB03 VAR lPrile PROMPT "Prioriza Lote Econômico" SIZE 210, 008 OF oContainer PIXEL

	@ 070, 280 SAY oLblB04 PROMPT "Critério Fornecedor" SIZE 078, 008 OF oContainer PIXEL
	@ 068, 362 MSCOMBOBOX oCtlB04 VAR M->CRIT ITEMS aItCrit SIZE 200, 040 OF oContainer PIXEL

	@ 090, 280 SAY oLblB05 PROMPT "Tipos de Produtos"  SIZE 078, 008 OF oContainer PIXEL
	@ 088, 362 MSGET oCtlB05 VAR M->TIPOS SIZE 200, 010 OF oContainer PIXEL

	@ 110, 280 SAY oLblB06 PROMPT "Relação Prod/Forn." SIZE 078, 008 OF oContainer PIXEL
	@ 108, 362 MSCOMBOBOX oCtlB06 VAR M->RELFOR ITEMS aItRelFor SIZE 200, 060 OF oContainer PIXEL

	@ 130, 280 SAY oLblB07 PROMPT "E-mail Workflow"    SIZE 078, 008 OF oContainer PIXEL
	@ 128, 362 MSGET oCtlB07 VAR M->MAILWF SIZE 200, 010 OF oContainer PIXEL

	@ 150, 280 CHECKBOX oCtlB08 VAR lEmsatu PROMPT "Deduz Empenho do Saldo" SIZE 210, 008 OF oContainer PIXEL

	@ 170, 280 SAY oLblB09 PROMPT "Dias de Histórico"  SIZE 078, 008 OF oContainer PIXEL
	@ 168, 362 MSGET oCtlB09 VAR M->DHIST SIZE 200, 010 OF oContainer PICTURE "999" PIXEL

	@ 190, 280 SAY oLblB10 PROMPT "Armazém Padrão"     SIZE 078, 008 OF oContainer PIXEL
	@ 188, 362 MSGET oCtlB10 VAR M->LOCPAD SIZE 200, 010 OF oContainer PIXEL

	@ 210, 280 SAY oLblB11 PROMPT "Doc. do Carrinho"   SIZE 078, 008 OF oContainer PIXEL
	@ 208, 362 MSCOMBOBOX oCtlB11 VAR M->TPDOC ITEMS aItTpDoc SIZE 200, 040 OF oContainer PIXEL

	@ 230, 280 SAY oLblB12 PROMPT "Modelo do Pedido"   SIZE 078, 008 OF oContainer PIXEL
	@ 228, 362 MSCOMBOBOX oCtlB12 VAR M->MDPED ITEMS aItMdPed SIZE 200, 040 OF oContainer PIXEL

	@ 250, 280 CHECKBOX oCtlB13 VAR lCmt    PROMPT "Habilita Continuar Mais Tarde"     SIZE 220, 008 OF oContainer PIXEL
	@ 270, 280 CHECKBOX oCtlB14 VAR lTrfFil PROMPT "Considera Transf. Intra-Grupo"     SIZE 220, 008 OF oContainer PIXEL
	@ 290, 280 CHECKBOX oCtlB15 VAR lAnaRev PROMPT "Habilita Análise Reversa"          SIZE 220, 008 OF oContainer PIXEL

	oDlgPar:Activate()

return lSuccess

/*/{Protheus.doc} applyAux
Traduz os auxiliares de checkbox (lógicos) de volta para os campos de caractere S/N da estrutura
e grava a configuração na PNC_CONFIG através de saveCfg. Os campos de combo já estão ligados
diretamente aos campos M-> (código de 1 posição), sem necessidade de tradução.
@type function
@version 20.0003
@author Jean Carlos Pandolfo Saggin
@since 10/07/2026
@param aCampos, array, estrutura de campos da tabela (U_JSGETSTR)
@return logical, lSuccess
/*/
static function applyAux( aCampos )

    local lSuccess := .F. as logical

    if lPrile
        M->PRILE := 'S'
    else
        M->PRILE := 'N'
    endif

    if lEmsatu
        M->EMSATU := 'S'
    else
        M->EMSATU := 'N'
    endif

    if lCmt
        M->CMT := 'S'
    else
        M->CMT := 'N'
    endif

    if lTrfFil
        M->TRFFIL := 'S'
    else
        M->TRFFIL := 'N'
    endif

    if lAnaRev
        M->ANAREV := 'S'
    else
        M->ANAREV := 'N'
    endif

    lSuccess := saveCfg( aCampos )

return lSuccess

/*/{Protheus.doc} loadCfg
Carrega na tela (memvars M->) os valores atualmente gravados na PNC_CONFIG_<empresa> para a filial
corrente, campo a campo, com proteção contra campos ainda não existentes na tabela física.
@type function
@version 20.0002
@author Jean Carlos Pandolfo Saggin
@since 10/07/2026
@param aCampos, array, estrutura de campos da tabela (U_JSGETSTR)
/*/
static function loadCfg( aCampos )

    local cAlias := "" as character
    local cTable := "PNC_CONFIG_"+ cEmpAnt
    local nX     := 0 as numeric

    if TCCanOpen( cTable )
        cAlias := GetNextAlias()
        DBUseArea( .T., 'TOPCONN', cTable, cAlias, .F., .T. )
        DbSelectArea( cAlias )
        ( cAlias )->( DBSetIndex( cTable +'_01' ) )
        if ( cAlias )->( DBSeek( cFilAnt ) )
            for nX := 1 to len( aCampos )
                if ( cAlias )->( FieldPos( aCampos[nX][1] ) ) > 0
                    &( 'M->'+ aCampos[nX][1] ) := ( cAlias )->( FieldGet( FieldPos( aCampos[nX][1] ) ) )
                endif
            next nX
        endif
        ( cAlias )->( DBCloseArea() )
    endif

return Nil

/*/{Protheus.doc} saveCfg
Grava os parâmetros internos do Painel de Compras na tabela própria PNC_CONFIG_<empresa>, fora do
dicionário de dados do Protheus. Atualiza o registro da filial corrente quando já existir, ou
inclui um novo registro quando ainda não houver configuração gravada.
@type function
@version 20.0002
@author Jean Carlos Pandolfo Saggin
@since 10/07/2026
@param aCampos, array, estrutura de campos da tabela (U_JSGETSTR)
@return logical, lSuccess
/*/
static function saveCfg( aCampos )

    local lSuccess := .F. as logical
    local cAlias   := "" as character
    local cTable   := "PNC_CONFIG_"+ cEmpAnt
    local lInclui  := .F. as logical
    local nX       := 0 as numeric

    if ! TCCanOpen( cTable )
        hlp( 'ESTRUTURA INEXISTENTE',;
             'A tabela de configurações '+ cTable +' não foi encontrada.',;
             'Execute o assistente de configuração (F11) antes de gravar os parâmetros internos.' )
        return lSuccess
    endif

    cAlias := GetNextAlias()
    DBUseArea( .T. /* lNewArea - nunca reaproveitar a área corrente */, 'TOPCONN', cTable, cAlias, .T. /* lShared - RecLock garante o travamento de linha */, .F. )

    // Confirma que a área foi efetivamente aberta antes de prosseguir, evitando erro genérico
    // de framework mais adiante caso o DBUseArea não tenha conseguido vincular o alias
    if Select( cAlias ) == 0
        hlp( 'FALHA AO ABRIR TABELA',;
             'Não foi possível abrir a tabela '+ cTable +' (alias '+ cAlias +') para gravação.',;
             'Verifique a conexão com o banco de dados e tente novamente. Se o problema persistir,'+;
             ' contate o administrador do ambiente.' )
        return lSuccess
    endif

    DbSelectArea( cAlias )
    ( cAlias )->( DBSetIndex( cTable +'_01' ) )

    lInclui := ! ( cAlias )->( DBSeek( cFilAnt ) )

    RecLock( cAlias, lInclui )
    if lInclui
        ( cAlias )->( FieldPut( FieldPos( 'FILIAL' ), cFilAnt ) )
    endif
    for nX := 1 to len( aCampos )
        if AllTrim( aCampos[nX][1] ) != 'FILIAL' .and. ( cAlias )->( FieldPos( aCampos[nX][1] ) ) > 0
            ( cAlias )->( FieldPut( FieldPos( aCampos[nX][1] ), &( 'M->'+ aCampos[nX][1] ) ) )
        endif
    next nX
    ( cAlias )->( MsUnlock() )
    ( cAlias )->( DBCloseArea() )

    lSuccess := .T.

return lSuccess

/*/{Protheus.doc} fldLen
Devolve o tamanho (X3_TAMANHO) do campo informado dentro da estrutura recebida (U_JSGETSTR),
evitando repetir o mesmo aScan em cada campo texto que precisa de um Space() no tamanho correto.
@type function
@version 20.0002
@author Jean Carlos Pandolfo Saggin
@since 10/07/2026
@param aCampos, array, estrutura de campos da tabela (U_JSGETSTR)
@param cCampo, character, nome do campo
@return numeric, nTam
/*/
static function fldLen( aCampos, cCampo )

    local nTam := 0 as numeric
    local nPos := 0 as numeric

    nPos := aScan( aCampos, {|x| AllTrim( x[1] ) == AllTrim( cCampo ) } )
    if nPos > 0
        nTam := aCampos[nPos][3]
    endif

return nTam

/*/{Protheus.doc} hlp
Função facilitadora para utilização da função Help do Protheus.
@type function
@version 20.0002
@author Jean Carlos Pandolfo Saggin
@since 10/07/2026
@param cTitle, character, título da janela
@param cFail, character, informações sobre a falha
@param cHelp, character, informações com texto de ajuda
/*/
static function hlp( cTitle, cFail, cHelp )
return Help( ,, cTitle,, cFail, 1, 0, NIL, NIL, NIL, NIL, NIL, { cHelp } )
