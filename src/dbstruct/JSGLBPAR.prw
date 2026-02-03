#include 'totvs.ch'
#include 'protheus.ch'
#include 'topconn.ch'

#define APP_ID 1        // ID da aplicação no Supabase

/*/{Protheus.doc} JSGLBPAR
Função para configurar os parâmetros do Painel de Compras
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@param lCheck, logical, Indica se a função está sendo chamada apenas para checagem da comunicação com supabase
@since 23/08/2023
/*/
User Function JSGLBPAR( lCheck )

    Local oDlgConf as object
    Local oPanel   as object
    Local oWiz     as object
    Local oPgAtu   as object
    local lChecked := .F. as logical
    local lStruct  := .T. as logical

    Private oIntAct   as object
    Private oContract as object
    Private oContType as object
    Private oDataExp  as object
    Private aContract := {} as array
    Private lSupabase := .F. as logical
    Private nCustomer := 0 as numeric
    Private aTab      := {} as array
    Private aPar      := {} as array
    Private aParams   := getParams()
    Private oBrowse   as object
    Private cDictVer  := Alltrim(SuperGetMv( 'MV_X_PNC20',,"00" ))
   
    default lCheck := .F.

    // Tabelas a serem checadas no momento do acesso à plataforma
    aAdd( aTab, { "01", "PNC_CONFIG_"+ cEmpAnt, "" } )

    // Faz a checagem de status das tabelas 
    // if ! cDictVer == U_JSDICVER()
    //     aEval( aParams, {|x| lStruct := lStruct .and. GetMv( x[1], .T. ) } )
    //     aEval( aTab, {|x| lStruct := lStruct .and. U_JSTBLCHK( x[2] ) == 'O' } )
    // endif

    // Carrega os dados do cliente
    MsAguarde({|| lSupabase := chkActive() }, 'Conectando...', 'Checando conexão com ambiente web...' )
    if lSupabase
        MsAguarde({|| nCustomer := getCustomer() }, 'Obtendo dados do cliente...', 'Identificando cliente...' )
        if nCustomer > 0
            MsAguarde({|| aContract := getContract() }, 'Obtendo contrato...', 'Verificando contratos vigentes para o cliente...' )
            if len( aContract ) > 0
                lChecked := lStruct .and. lSupabase .and. Date() <= aContract[3]
            endif
        endif
    endif
    
    // Quando for apenas para chegar e o retorno for verdadeiro, nem exibe a tela de configurações
    if lCheck .and. lChecked
        if aContract[2]     // Verifica se é versão Trial
            Hlp( 'TRIAL_VERSION',;
                'Você está utilizando a rotina Painel de Compras em versão trial (versão de avaliação)',;
                'Aproveite todas as funcionalidades, você tem até '+ DtoC( aContract[3] ) +' para fazer seu setor de compras decolar!' )
        endif
        
        Return lChecked
    endif

    oDlgConf := FWDialogModal():New()
    oDlgConf:SetBackground( .T. )
    oDlgConf:SetTitle( 'PlugIn Painel de Compras - '+ U_JSGETVER() )
    oDlgConf:SetSubTitle( 'Permite definir os parâmetros e configurações internas do Painel de Compras no Protheus' )
    oDlgConf:SetSize( 300, 480 )
    oDlgConf:EnableFormBar( .F. )
    oDlgConf:SetCloseButton( .F. )
    oDlgConf:SetEscClose( .F. )
    oDlgConf:CreateDialog()
    oPanel := oDlgConf:GetPanelMain() 

    oWiz := FWWizardControl():New( oPanel )
    oWiz:ActiveUISteps()

    // Página 1 - Dados de conexão com supabase
    oPgAtu := oWiz:AddStep("1")
    oPgAtu:SetStepDescription( 'Status do banco web' )
    oPgAtu:SetConstruction( {|oPanel| buildPanel( 1 /* nPage */, oPanel) } )
    oPgAtu:SetNextAction( {|| nextPage( 1 /* nPageAtu */) } )
    oPgAtu:SetCancelAction( {|| iif( MsgYesNo( 'Está certo de que gostaria de sair do do assistente?', 'Tem certeza?' ), oDlgConf:DeActivate(), .F. ) } )

    // Página 2 - Dados do Contrato
    oPgAtu := oWiz:AddStep("2", {|oPanel| buildPanel( 2 /* nPage */, oPanel) } )
    oPgAtu:SetStepDescription( 'Status do Contrato' )
    oPgAtu:SetNextAction( {|| nextPage( 2 /* nPageAtu */) } )
    oPgAtu:SetPrevAction( {|| .T. } )
    oPgAtu:SetPrevTitle( "Status de Conexão" )
    oPgAtu:SetCancelAction( {|| iif( MsgYesNo( 'Está certo de que gostaria de sair do do assistente?', 'Tem certeza?' ), oDlgConf:DeActivate(), .F. ) } )

    oPgAtu := oWiz:AddStep("3", {|oPanel| buildPanel( 3 /* nPage */, oPanel) } )
    oPgAtu:SetStepDescription( 'Parâmetros Internos' )
    oPgAtu:SetNextAction( {|| nextPage(3) } )
    oPgAtu:SetPrevAction( {|| .T. } )
    oPgAtu:SetPrevTitle( "Contrato" )
    oPgAtu:SetCancelAction( {|| iif( MsgYesNo( 'Está certo de que gostaria de sair do do assistente?', 'Tem certeza?' ), oDlgConf:DeActivate(), .F. ) } )

    oPgAtu := oWiz:AddStep("4", {|oPanel| buildPanel( 4 /* nPage */, oPanel) } )
    oPgAtu:SetStepDescription( 'Dicionário de Dados' )
    oPgAtu:SetNextAction( {|| nextPage(4) } )
    oPgAtu:SetPrevAction( {|| .T. } )
    oPgAtu:SetPrevTitle( "Parâmetros" )
    oPgAtu:SetCancelAction( {|| iif( MsgYesNo( 'Está certo de que gostaria de sair do do assistente?', 'Tem certeza?' ), oDlgConf:DeActivate(), .F. ) } )

    // Página 4 - Finalização
    oPgAtu := oWiz:AddStep("5", {|oPanel| buildPanel( 5 /* nPage */, oPanel) } )
    oPgAtu:SetStepDescription( 'Finalização' )
    oPgAtu:SetNextAction( {|| oDlgConf:DeActivate() } )
    oPgAtu:SetPrevAction( {|| .T. } )
    oPgAtu:SetPrevTitle( "Dicionário" )
    oPgAtu:SetCancelAction( {|| oDlgConf:DeActivate() } )
    oPgAtu:SetCancelWhen( { || .F. } )

    oWiz:Activate()

    oDlgConf:Activate()
    
    oWiz:Destroy()


return lChecked

/*/{Protheus.doc} buildPanel
Função responsável pela criação dos objetos gráficos de acordo com a página que está sendo criada no wizard
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 23/08/2023
@param nPage, numeric, indica o número da página que está sendo criada
@param oPanel, object, objeto do painel onde os objetos serão dispostos
/*/
Static Function buildPanel( nPage, oPanel )

    local nLine     := 1 as numeric
    local nLnSize   := 20 as numeric
    Local oFont     := TFont():New('Courier New',, -12, .F.)
    local bSupabase := {|| 'Sincronização online....: '+ iif( lSupabase, "Online", "Offline" ) }
    local bContract := {|| 'Data Adesão.............: '+ DtoC( iif( lSupabase, aContract[1], StoD(" ") ) ) }
    local bContType := {|| 'Status Licenciamento....: '+ contractType() }
    local bDataExp  := {|| 'Data de expiração.......: '+ DtoC( iif( lSupabase, aContract[3], StoD(" ") ) ) }
    local cMessage  := "" as character
    local aColumns  := {} as array
    local nPos      := 0 as numeric

    default nPage := 1

    if nPage == 1       // dados de conexão ao supabase
        
        // Integração ativa ou inativa
        nLine := 2
        oIntAct := TSay():New( nLine*nLnSize, 30, bSupabase, oPanel,,oFont,,,,.T.,CLR_GRAY,CLR_WHITE,400,20)
        oIntAct:CtrlRefresh()

    elseif nPage == 2    // Dados do contrato

        nLine := 2
        oContract := TSay():New( nLine*nLnSize, 30, bContract, oPanel,,oFont,,,,.T.,CLR_GRAY,CLR_WHITE,400,20)
        oContract:CtrlRefresh()

        nLine++
        oContType := TSay():New( nLine*nLnSize, 30, bContType, oPanel,,oFont,,,,.T.,CLR_GRAY,CLR_WHITE,400,20)
        oContType:CtrlRefresh()

        nLine++
        oDataExp := TSay():New( nLine*nLnSize, 30, bDataExp, oPanel,,oFont,,,,.T.,CLR_GRAY,CLR_WHITE,400,20)
        oDataExp:CtrlRefresh()

    elseif nPage == 3       // Parâmetros internos

        // Monta lista de parâmetros e checa existência de cada um
        aPar     := {}
        aColumns := {}
        aEval( aParams, {|x| nPos++, aAdd( aPar, { aParams[nPos][1],;
                                                    AllTrim(aParams[nPos][3]+aParams[nPos][4]+aParams[nPos][5]),;
                                                    GetMv(aParams[nPos][1], .T.),;
                                                    AllTrim(ConvPar(SuperGetMv(aParams[nPos][1],,aParams[nPos][6]))) } ) } )

        aAdd( aColumns, FWBrwColumn():New() )
        aColumns[len(aColumns)]:SetTitle( 'Parâmetro' )
        aColumns[len(aColumns)]:SetType( 'C' )
        aColumns[len(aColumns)]:SetSize( 10 )
        aColumns[len(aColumns)]:SetDecimal( 0 )
        aColumns[len(aColumns)]:SetPicture( "@!" )
        aColumns[len(aColumns)]:SetData( {|oBrw| aPar[oBrw:At()][1] } )
        
        aAdd( aColumns, FWBrwColumn():New() )
        aColumns[len(aColumns)]:SetTitle( 'Descrição' )
        aColumns[len(aColumns)]:SetType( 'C' )
        aColumns[len(aColumns)]:SetSize( 20 )
        aColumns[len(aColumns)]:SetDecimal( 0 )
        aColumns[len(aColumns)]:SetPicture( "@x" )
        aColumns[len(aColumns)]:SetData( {|oBrw| aPar[oBrw:At()][2] } )

        aAdd( aColumns, FWBrwColumn():New() )
        aColumns[len(aColumns)]:SetTitle( 'Status' )
        aColumns[len(aColumns)]:SetType( 'C' )
        aColumns[len(aColumns)]:SetSize( 2 )
        aColumns[len(aColumns)]:SetDecimal( 0 )
        aColumns[len(aColumns)]:SetPicture( "@x" )
        aColumns[len(aColumns)]:SetData( {|oBrw| iif( aPar[oBrw:At()][3], "Ok","Inexistente" ) } )

        aAdd( aColumns, FWBrwColumn():New() )
        aColumns[len(aColumns)]:SetTitle( 'Conteúdo' )
        aColumns[len(aColumns)]:SetType( 'C' )
        aColumns[len(aColumns)]:SetSize( 15 )
        aColumns[len(aColumns)]:SetDecimal( 0 )
        aColumns[len(aColumns)]:SetPicture( "@x" )
        aColumns[len(aColumns)]:SetData( {|oBrw| aPar[oBrw:At()][4] } )

        oBrowse := FWBrowse():New( oPanel )
        oBrowse:SetDataArray()
        oBrowse:SetArray( aPar )
        oBrowse:AddStatusColumn( {|| iif( aPar[oBrowse:At()][3], "BR_VERDE","BR_VERMELHO" ) }, Nil )
        oBrowse:SetColumns( aColumns )
        // oBrowse:GetColumn(2):bLDblClick := {|oBrowse| editPar( oBrowse ) }
        // oBrowse:GetColumn(3):bLDblClick := {|oBrowse| editPar( oBrowse ) }
        oBrowse:DisableConfig()
        oBrowse:DisableReport()
        oBrowse:Activate()

    elseif nPage == 4       // Dicionário de dados

        // Faz a checagem de status das tabelas 
        aColumns := {}
        aEval( aTab, {|x| x[3] := U_JSTBLCHK( x[2] ) } )
        
        aAdd( aColumns, FWBrwColumn():New() )
        aColumns[len(aColumns)]:SetTitle( 'ID' )
        aColumns[len(aColumns)]:SetType( 'C' )
        aColumns[len(aColumns)]:SetSize( 2 )
        aColumns[len(aColumns)]:SetDecimal( 0 )
        aColumns[len(aColumns)]:SetPicture( "@!" )
        aColumns[len(aColumns)]:SetData( {|oBrw| aTab[oBrw:At()][1] } )
        
        aAdd( aColumns, FWBrwColumn():New() )
        aColumns[len(aColumns)]:SetTitle( 'Tabela' )
        aColumns[len(aColumns)]:SetType( 'C' )
        aColumns[len(aColumns)]:SetSize( 30 )
        aColumns[len(aColumns)]:SetDecimal( 0 )
        aColumns[len(aColumns)]:SetPicture( "@!" )
        aColumns[len(aColumns)]:SetData( {|oBrw| aTab[oBrw:At()][2] } )

        aAdd( aColumns, FWBrwColumn():New() )
        aColumns[len(aColumns)]:SetTitle( 'Status' )
        aColumns[len(aColumns)]:SetType( 'C' )
        aColumns[len(aColumns)]:SetSize( 20 )
        aColumns[len(aColumns)]:SetDecimal( 0 )
        aColumns[len(aColumns)]:SetPicture( "@x" )
        aColumns[len(aColumns)]:SetData( {|oBrw| iif( aTab[oBrw:At()][3] == 'I', "Tabela inexistente",;
                                                 iif( aTab[oBrw:At()][3] == 'U', "Tabela desatualizada", "Ok" ))    } )

        oBrowse := FWBrowse():New( oPanel )
        oBrowse:SetDataArray()
        oBrowse:SetArray( aTab )
        oBrowse:AddStatusColumn( {|| iif( aTab[oBrowse:At()][3] == 'I', "BR_VERMELHO",;
                                     iif( aTab[oBrowse:At()][3] == 'U', "BR_AMARELO", "BR_VERDE" ) ) }, Nil )
        oBrowse:SetColumns( aColumns )
        oBrowse:DisableConfig()
        oBrowse:DisableReport()
        oBrowse:Activate()

    elseif nPage == 5       // Finalização
        nLine := 2
        cMessage := "A checagem do PlugIn Painel de Compras foi finalizada"
        if Date() > aContract[3]
            cMessage += ", porém, "
            cMessage += iif( aContract[2], "a versão de avaliação expirou!", "a vigência do contrato expirou!" )
            cMessage += " Entre em contato com seu parceiro de negócios e renove seu contrato através do telefone/WhatsApp (45) 9 9981 5097."
        endif
        oSayEnd := TSay():New( nLine*nLnSize, 30, {|| cMessage + chr(13)+chr(10) +;
                            'Versão: '+ U_JSGETVER() },;
                             oPanel,,oFont,,,,.T.,CLR_GRAY,CLR_WHITE,400,60)
        oSayEnd:CtrlRefresh()

    endif

return Nil 

/*/{Protheus.doc} contractType
Função para retornar tipo de contrato atual do cliente
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/17/2025
@return character, cContractType
/*/
static function contractType()
    local cContType := "" as character
    if lSupabase
        if aContract[2]
            cContType := "Trial (versão de avaliação"+ iif( Date() > aContract[3], " expirada", "" ) +")"
        elseif Date() > aContract[3]        // Término do contrato
            cContType := "Vigência do contrato expirada"
        else
            cContType := "Contrato Vigente"
        endif
    else
        cContType := ""
    endif
return cContType

/*/{Protheus.doc} nextPage
Função executada ao clicar sobre o botão next do wizard
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 23/08/2023
@param nAtual, numeric, indica a página em que o usuário acabou de definir os parâmetros
@return logical, lSuccess
/*/
Static Function nextPage( nAtual )
    
    Local lSuccess := .T. as logical
    local nX       := 0 as numeric
    local aIndex   := {} as array
    local cAlias   := "" as character
    local aOldStr  := {} as array
    local aStruct  := {} as array
    local nTopErr  := 0 as numeric
    local nIndex   := 0 as numeric

    if nAtual == 1      // Configurações do supabase

        lSuccess := lSupabase
        if ! lSuccess
            Hlp( 'SUPABASE',;
                 'Falha durante a tentativa de conexão com o banco web',;
                 'Tente novamente em alguns minutos' )
        endif

    // elseif nAtual == 2  // Status do Contrato

    elseif nAtual == 3  // Parâmetros

        aEval( aParams, {|x| lSuccess := lSuccess .and. iif( ! GetMv( x[1], .T. ), incPar(x), .T. ) } )

    elseif nAtual == 4  // Dicionário

        if len( aTab ) > 0
            
            for nX := 1 to len( aTab )
                aIndex := U_JSTBLIDX( aTab[nX][2] )
                if aTab[nX][3] == "U"         // Tabelas que precisam de update
                    
                    // Obtem um nome de alias temporário
                    cAlias := GetNextAlias()
                    DBUseArea( .F., 'TOPCONN', aTab[nX][2], (cAlias), .F., .F. )
                    // Obtem a estrutura da tabela para eviar junto da função TCAlter
                    aOldStr := ( cAlias )->( DBStruct() )
                    ( cAlias )->( DBCloseArea() )

                    // Obtem a nova estrutura
                    aStruct := U_JSGETSTR( aTab[nX][2] /* cTable */ )

                    if len( aStruct ) > 0

                        // Chama função padrão do TopConnect para alterar a tabela intermediária
                        lSuccess := TCAlter( aTab[nX][2], aOldStr, aStruct, @nTopErr )
                        if ! lSuccess
                            Hlp( 'Falha na Alteração',;
                                    'Falha durante a tentativa de alterar estrutura da tabela '+ aTab[nX][2],;
                                    TcSQLError() )
                        else
                            if len( aIndex ) > 0
                                for nIndex := 1 to len( aIndex )
                                    if ! TCCanOpen( aTab[nX][2], aIndex[nIndex][1] )
                                        
                                        cAlias := GetNextAlias()
                                        DBUseArea( .F., 'TOPCONN', aTab[nX][2], (cAlias), .F., .F. )
                                        ( cAlias )->( DBCreateIndex( aIndex[nIndex][1], aIndex[nIndex][2], aIndex[nIndex][3] ) )
                                        ( cAlias )->( DBClearIndex() )
                                        ( cAlias )->( DBSetIndex( aIndex[nIndex][1] ) )
                                        ( cAlias )->( DBCloseArea() )
                                        lSuccess := TCCanOpen( aTab[nX][2], aIndex[nIndex][1] )

                                    endif
                                    if ! lSuccess
                                        Hlp( 'Falha na Criação do Índice',; 
                                                'O índice '+ aIndex[nIndex][1] +' da tabela ' + aTab[nX][2] +' não pode ser criado!' )
                                        Exit
                                    endif
                                next nIndex
                            endif
                            if lSuccess
                                aTab[nX][3] := "O"
                                oBrowse:GoTo( nX, .T. /* lRefresh */ )
                                oBrowse:UpdateBrowse( .T. /* lResetSeed */)
                            endif
                        endif
                    else
                        lSuccess := .F.
                        Hlp( 'Sem Estrutura',;
                                'A tabela '+ aTab[nX][2] +' não possui estrutura definida!',;
                                'Defina uma estrutura por meio da função JSGETSTR e tente novamente.' )
                    endif

                elseif aTab[nX][3] == "I"     // Tabelas que não estão criadas
                    
                    // Obtem estrutura da tabela
                    aStruct := U_JSGETSTR( aTab[nX][2] /* cTable */ )
                    aIndex  := U_JSTBLIDX( aTab[nX][2] )
                    
                    // Verifica se a tabela tem estrutura
                    if len( aStruct ) > 0
                        
                        // Função do DbAccess para criar a tabela de acordo com a estrutura enviada por parâmetro
                        DBCreate( aTab[nX][2], aStruct, 'TOPCONN' )
                        
                        // Tenta abrir a tabela depois de criada
                        lSuccess := TcCanOpen( aTab[nX][2] )
                        if ! lSuccess
                            Hlp( aTab[nX][2],;
                                    'A tabela '+ aTab[nX][2] +' não pode ser criada!',;
                                    'Falha durante processo de criação da tabela' )
                        else
                            if len( aIndex ) > 0
                                for nIndex := 1 to len( aIndex )
                                    if ! TCCanOpen( aTab[nX][2], aIndex[nIndex][1] )
                                        
                                        cAlias := GetNextAlias()
                                        DBUseArea( .F., 'TOPCONN', aTab[nX][2], (cAlias), .F., .F. )
                                        ( cAlias )->( DBCreateIndex( aIndex[nIndex][1], aIndex[nIndex][2], aIndex[nIndex][3] ) )
                                        ( cAlias )->( DBClearIndex() )
                                        ( cAlias )->( DBSetIndex( aIndex[nIndex][1] ) )
                                        ( cAlias )->( DBCloseArea() )
                                        lSuccess := TCCanOpen( aTab[nX][2], aIndex[nIndex][1] )

                                    endif
                                    if ! lSuccess
                                        Hlp( 'Falha na Criação do Índice',;
                                                'O índice '+ aIndex[nIndex][1] +' da tabela ' + aTab[nX][2] +' não pode ser criado!' )
                                        Exit
                                    endif
                                next nIndex
                            endif
                            if lSuccess
                                aTab[nX][3] := "O"
                                oBrowse:GoTo( nX, .T. /* lRefresh */ )
                                oBrowse:UpdateBrowse( .T. /* lResetSeed */)
                            endif
                        endif
                    else
                        lSuccess := .F.
                        Hlp( 'Sem Estrutura',;
                                'A tabela '+ aTab[nX][2] +' não possui estrutura definida!',;
                                'Defina uma estrutura por meio da função JSGETSTR e tente novamente.' )
                    endif

                endif
                if ! lSuccess
                    Exit
                endif
            next nX
        endif


    elseif nAtual == 5  // Fim
        lSuccess := .T.
    endif

return lSuccess

/*/{Protheus.doc} incPar
Função para inclusão automática de parâmetro no configurador
@type function
@version 12.1.2410
@author Jean Carlos Pandolfo Saggin
@since 20/01/2026
@param aPar, array, vetor contendo dados do parâmetro a ser incluído
@return logical, lSuccess
/*/
static function incPar( aPar )
    local lSuccess := .F. as logical
    local cSX6     := "SX6" as character
    RecLock( cSX6, .T. )
        ( cSX6 )->( FieldPut( FieldPos( 'X6_FIL'     ), cFilAnt ) )
        ( cSX6 )->( FieldPut( FieldPos( 'X6_VAR'     ), aPar[1] ) )
        ( cSX6 )->( FieldPut( FieldPos( 'X6_TIPO'    ), aPar[2] ) )
        ( cSX6 )->( FieldPut( FieldPos( 'X6_DESCRIC' ), aPar[3] ) )
        ( cSX6 )->( FieldPut( FieldPos( 'X6_DSCSPA'  ), aPar[3] ) )
        ( cSX6 )->( FieldPut( FieldPos( 'X6_DSCENG'  ), aPar[3] ) )
        ( cSX6 )->( FieldPut( FieldPos( 'X6_DESC1'   ), aPar[4] ) )
        ( cSX6 )->( FieldPut( FieldPos( 'X6_DSCSPA1' ), aPar[4] ) )
        ( cSX6 )->( FieldPut( FieldPos( 'X6_DSCENG1' ), aPar[4] ) )
        ( cSX6 )->( FieldPut( FieldPos( 'X6_DESC2'   ), aPar[5] ) )
        ( cSX6 )->( FieldPut( FieldPos( 'X6_DSCSPA2' ), aPar[5] ) )
        ( cSX6 )->( FieldPut( FieldPos( 'X6_DSCENG2' ), aPar[5] ) )
        ( cSX6 )->( FieldPut( FieldPos( 'X6_CONTEUD' ), convPar(aPar[6]) ) )
        ( cSX6 )->( FieldPut( FieldPos( 'X6_CONTSPA' ), convPar(aPar[6]) ) )
        ( cSX6 )->( FieldPut( FieldPos( 'X6_CONTENG' ), convPar(aPar[6]) ) )
        ( cSX6 )->( FieldPut( FieldPos( 'X6_PROPRI'  ), "U" ) )
        ( cSX6 )->( FieldPut( FieldPos( 'X6_ACTIVE'  ), "1" ) )
    ( cSX6 )->( MsUnlock() )
    lSuccess := .T.
return lSuccess

/*/{Protheus.doc} convPar
Função para converter conteúdo do parâmetro para possibilitar inserção no SX6
@type function
@version 12.1.2410
@author Jean Carlos Pandolfo Saggin
@since 20/01/2026
@param xValue, variant, conteúdo a ser gravado no parâmetro
@return character, cValue
/*/
static function convPar( xValue )
    local cType := ValType( xValue )
    if cType == 'N'
        cValue := cValToChar( xValue )
    elseif cType == 'D'
        cValue := DtoC( xValue )
    elseif cType == 'L'
        cValue := cValToChar( xValue )
    else
        cValue := AllTrim( xValue )
    endif
return cValue

/*/{Protheus.doc} chkActive
Função para checar se a conexão com o supabase está online
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/14/2025
@return logical, lSuccess
/*/
static function chkActive()

    local lSuccess := .T. as logical
    local oResult  as object
    
    oResult := U_JSSUPABASE( "HEAD" /* cMethod */ )
    lSuccess := ValType( oResult ) == 'J'
    FreeObj( oResult )
    oResult := nil

return lSuccess

/*/{Protheus.doc} getCustomer
Obtem o ID do cliente com base nos dados do cadastro de empresas 
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/17/2025
@return numeric, nCustomer
/*/
static function getCustomer()
    
    local nCustomer := 0 as numeric
    local oResult   as object
    local aFields   := { "NAME","FANTASY", "ADDRESS", "CITY", "STATE", "NEIGHBORHOOD", "PHONE", "CGCCPF" }
    local aData     := {} as array
    local cCGC      := StrTran(SubStr( SM0->M0_CGC, 1, 8 ),"        ", "99999999" )
    local cWhere    := "CGCCPF=eq."+ cCGC +"&DELETED=eq.N"

    // Verifica se o cliente já é cadastrado
    oResult := U_JSSUPABASE( "GET", "CUSTOMER", {"ID"}, cWhere )
    if ValType( oResult ) == 'J' .and. len( oResult ) > 0
        nCustomer := oResult[1]["ID"]
    else

        // Se não for cadastrado, já realiza o cadastro com base nos dados da SM0
        oResult := Nil
        aData := {{ SM0->M0_NOMECOM,;
                    SM0->M0_FILIAL,;
                    SM0->M0_ENDENT,;
                    SM0->M0_CIDENT,;
                    SM0->M0_ESTENT,;
                    SM0->M0_BAIRENT,;
                    SM0->M0_TEL,;
                    cCGC }}

        oResult := U_JSSUPABASE( "POST", "CUSTOMER", aFields, /* cWhere */, aData )
        if ValType( oResult ) == 'J' .and. len( oResult ) > 0
            nCustomer := oResult[1]["ID"]
        else
            Hlp( "CUSTOMER",;
                "Falha ao tentar obter o ID de Cliente",;
                "ID do cliente não foi criado! Verifique a conexão junto ao fornecedor do Painel de Compras" )
        endif
    endif
    FreeObj( oResult )
    oResult := Nil

return nCustomer

/*/{Protheus.doc} getContract
Função para obter os dados do contrato do cliente
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 2/17/2025
@return array, aContract
/*/
static function getContract()

    local aContract := {} as array
    local oResult   as object
    local aFields   := { "ID", "DATE", "ENDDATE", "TRIAL" }
    local aInsFlds  := { "CUSTOMERID", "PRODUCTID", "DATE", "ENDDATE", "MONTHLYVALUE", "TRIAL" }
    local aData     := {} as array
    local cWhere    := "PRODUCTID=eq."+ AllTrim(cValToChar(APP_ID)) +"&CUSTOMERID=eq."+ AllTrim(cValToChar(nCustomer)) +"&DELETED=eq.N"

    oResult := U_JSSUPABASE( "GET", "CONTRACT", aFields, cWhere )  
    if ValType( oResult ) == 'J' .and. len( oResult ) > 0
        aContract := { StoD(StrTran(oResult[1]["DATE"],'-','')), oResult[1]["TRIAL"], StoD(StrTran(oResult[1]["ENDDATE"],'-','')) }
    else
        oResult := Nil
        aData := {{ nCustomer, APP_ID, Date(), Date()+30, 0, .T. }}
        oResult := U_JSSUPABASE( "POST", "CONTRACT", aInsFlds, /* cWhere */, aData )
        if ValType( oResult ) == 'J' .and. len( oResult ) > 0
            aContract := { StoD(StrTran(oResult[1]["DATE"],'-','')), oResult[1]["TRIAL"], StoD(StrTran(oResult[1]["ENDDATE"],'-','')) }
        else
            Hlp( "CONTRACT",;
                "Falha ao tentar obter os dados do contrato",;
                "Dados do contrato não foram obtidos! Verifique a conexão junto ao fornecedor do Painel de Compras" )
        endif
    endif
    FreeObj( oResult )
    oResult := Nil

return aContract

/*/{Protheus.doc} hlp
Função facilitadora para utilização da função Help do Protheus
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 08/04/2024
@param cTitle, character, Titulo da janela
@param cFail, character, Informações sobre a falha
@param cHelp, character, Informações com texto de ajuda
/*/
static function hlp( cTitle, cFail, cHelp )
return Help( ,, cTitle,, cFail, 1, 0, NIL, NIL, NIL, NIL, NIL,{ cHelp } )

/*/{Protheus.doc} getParms
Monta a listagem de parâmetros interos utilizados pela rotina do Painel de Compras
@type function
@version 12.1.2410
@author Jean Carlos Pandolfo Saggin
@since 20/01/2026
@return array, aParms
/*/
static function getParams()
    local aParams := {} as array

    aAdd( aParams, {; 
                    "MV_X_PNC01",;                                          // Parâmetro
                    "C",;                                                   // Tipo
                    "Formula de calculo da necessidade de compra atravé",;  // Descrição 1
                    "s do Painel de Compra",;                               // Descrição 2
                    "",;                                                    // Descrição 3
                    AllTrim(SuperGetMv("MV_X_PNC01",,"(|(|nDias|+|nLdTime|)|-|nPrjEst|)|*|nConMed" ));// Conteúdo
                    } )
    aAdd( aParams, {; 
                    "MV_X_PNC02",;                                          // Parâmetro
                    "C",;                                                   // Tipo
                    "Alias da tabela de indices por produto            ",;  // Descrição 1
                    "",;                                                    // Descrição 2
                    "",;                                                    // Descrição 3
                    AllTrim(SuperGetMv( "MV_X_PNC02",, "" )) ;              // Conteúdo
                    } )
    aAdd( aParams, {; 
                    "MV_X_PNC03",;                                          // Parâmetro
                    "C",;                                                   // Tipo
                    "Alias da tabela de parâmetros globais da central d",;  // Descrição 1
                    "e compras                                         ",;  // Descrição 2
                    "",;                                                    // Descrição 3
                    AllTrim(SuperGetMv( "MV_X_PNC03",, "" )) ;              // Conteúdo
                    } )
    aAdd( aParams, {; 
                    "MV_X_PNC04",;                                          // Parâmetro
                    "C",;                                                   // Tipo
                    "Alias da tabela de controle de produtos descontinu",;  // Descrição 1
                    "ados                                              ",;  // Descrição 2
                    "",;                                                    // Descrição 3
                    AllTrim(SuperGetMv( "MV_X_PNC04",, "" )) ;              // Conteúdo
                    } )
    aAdd( aParams, {; 
                    "MV_X_PNC05",;                                          // Parâmetro
                    "N",;                                                   // Tipo
                    "Lucro líquido que a empresa pretende obter com a v",;  // Descrição 1
                    "enda do produto                                   ",;  // Descrição 2
                    "",;                                                    // Descrição 3
                    SuperGetMv( "MV_X_PNC05",, 15 );                        // Conteúdo
                    } )
    aAdd( aParams, {; 
                    "MV_X_PNC06",;                                          // Parâmetro
                    "N",;                                                   // Tipo
                    "Índice de despesas operacionais utilizado para for",;  // Descrição 1
                    "macao de precos                                   ",;  // Descrição 2
                    "",;                                                    // Descrição 3
                    SuperGetMv( "MV_X_PNC06",, 15 );                        // Conteúdo
                    } )
    aAdd( aParams, {; 
                    "MV_X_PNC07",;                                          // Parâmetro
                    "N",;                                                   // Tipo
                    "Índice CSLL usado na formação de precos           ",;  // Descrição 1
                    "",;                                                    // Descrição 2
                    "",;                                                    // Descrição 3
                    SuperGetMv( "MV_X_PNC07",, 1.08 );                      // Conteúdo
                    } )
    aAdd( aParams, {; 
                    "MV_X_PNC08",;                                          // Parâmetro
                    "N",;                                                   // Tipo
                    "Índice IRPJ usado no processo de formação de preço",;  // Descrição 1
                    "",;                                                    // Descrição 2
                    "",;                                                    // Descrição 3
                    SuperGetMv( "MV_X_PNC08",, 1.32 );                      // Conteúdo
                    } )
    aAdd( aParams, {; 
                    "MV_X_PNC09",;                                          // Parâmetro
                    "N",;                                                   // Tipo
                    "Indice inadimplencia usado para formacao de precos",;  // Descrição 1
                    "",;                                                    // Descrição 2
                    "",;                                                    // Descrição 3
                    SuperGetMv( "MV_X_PNC09",, 2 );                         // Conteúdo
                    } )
    aAdd( aParams, {; 
                    "MV_X_PNC10",;                                          // Parâmetro
                    "N",;                                                   // Tipo
                    "Indice de custo financeiro para formacao de precos",;  // Descrição 1
                    "",;                                                    // Descrição 2
                    "",;                                                    // Descrição 3
                    SuperGetMv( "MV_X_PNC10",, 2 );                         // Conteúdo
                    } )
    aAdd( aParams, {; 
                    "MV_X_PNC11",;                                          // Parâmetro
                    "N",;                                                   // Tipo
                    "Metodo de analise 1-Fornecedor Padrão ou 2-Melhor ",;  // Descrição 1
                    "Fornecedor                                        ",;  // Descrição 2
                    "",;                                                    // Descrição 3
                    SuperGetMv( "MV_X_PNC11",, 1 );                         // Conteúdo
                    } )
    aAdd( aParams, {; 
                    "MV_X_PNC12",;                                          // Parâmetro
                    "C",;                                                   // Tipo
                    "TimeStamp da ultima execucao do job de cálculo dos",;  // Descrição 1
                    " indices dos produtos para Painel de Compras      ",;  // Descrição 2
                    "",;                                                    // Descrição 3
                    AllTrim(SuperGetMv( "MV_X_PNC12",, "" ));               // Conteúdo
                    } )
    aAdd( aParams, {; 
                    "MV_X_PNC13",;                                          // Parâmetro
                    "C",;                                                   // Tipo
                    "Campo do produto usado para filtro de grupo       ",;  // Descrição 1
                    "",;                                                    // Descrição 2
                    "",;                                                    // Descrição 3
                    AllTrim(SuperGetMv( "MV_X_PNC13",, "B1_GRUPO" ));       // Conteúdo
                    } )
    aAdd( aParams, {; 
                    "MV_X_PNC14",;                                          // Parâmetro
                    "C",;                                                   // Tipo
                    "Alias da tabela de cadastro de tags               ",;  // Descrição 1
                    "",;                                                    // Descrição 2
                    "",;                                                    // Descrição 3
                    AllTrim(SuperGetMv( "MV_X_PNC14",, "" ));               // Conteúdo
                    } )
    aAdd( aParams, {; 
                    "MV_X_PNC15",;                                          // Parâmetro
                    "C",;                                                   // Tipo
                    "Usuários com permissão para gravar preço de tabela",;  // Descrição 1
                    "",;                                                    // Descrição 2
                    "",;                                                    // Descrição 3
                    AllTrim(SuperGetMv( "MV_X_PNC15",, "000000|" ));        // Conteúdo
                    } )
    aAdd( aParams, {; 
                    "MV_X_PNC16",;                                          // Parâmetro
                    "C",;                                                   // Tipo
                    "Alias da tabela de perfis de calculo              ",;  // Descrição 1
                    "",;                                                    // Descrição 2
                    "",;                                                    // Descrição 3
                    AllTrim(SuperGetMv( "MV_X_PNC16",, "" ));               // Conteúdo
                    } )
    aAdd( aParams, {; 
                    "MV_X_PNC17",;                                          // Parâmetro
                    "C",;                                                   // Tipo
                    "Série das notas de complemento de valor financeiro",;  // Descrição 1
                    "",;                                                    // Descrição 2
                    "",;                                                    // Descrição 3
                    AllTrim(SuperGetMv( "MV_X_PNC17",, "" ));               // Conteúdo
                    } )
    aAdd( aParams, {; 
                    "MV_X_PNC18",;                                          // Parâmetro
                    "N",;                                                   // Tipo
                    "Alíquota de ICMS para formação de preços          ",;  // Descrição 1
                    "",;                                                    // Descrição 2
                    "",;                                                    // Descrição 3
                    SuperGetMv( "MV_X_PNC18",, 0 );                         // Conteúdo
                    } )
    aAdd( aParams, {; 
                    "MV_X_PNC19",;                                          // Parâmetro
                    "N",;                                                   // Tipo
                    "Alíquota de IPI para formação de preços           ",;  // Descrição 1
                    "",;                                                    // Descrição 2
                    "",;                                                    // Descrição 3
                    SuperGetMv( "MV_X_PNC19",, 0 );                         // Conteúdo
                    } )
    aAdd( aParams, {; 
                    "MV_X_PNC20",;                                          // Parâmetro
                    "C",;                                                   // Tipo
                    "Versão dicionario de dados do Painel de Compras   ",;  // Descrição 1
                    "",;                                                    // Descrição 2
                    "",;                                                    // Descrição 3
                    AllTrim(SuperGetMv( "MV_X_PNC20",, "00" ));             // Conteúdo
                    } )
return aParams
