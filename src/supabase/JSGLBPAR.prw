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

    Private aMiddle   := {} as array
    Private oIntAct   as object
    Private oContract as object
    Private oContType as object
    Private oDataExp  as object
    Private aContract := {} as array
    Private lSupabase := .F. as logical
    Private nCustomer := 0 as numeric
   
    default lCheck := .F.

    // Carrega os dados do cliente
    MsAguarde({|| lSupabase := chkActive() }, 'Conectando...', 'Checando conexão com ambiente web...' )
    if lSupabase
        MsAguarde({|| nCustomer := getCustomer() }, 'Obtendo dados do cliente...', 'Identificando cliente...' )
        if nCustomer > 0
            MsAguarde({|| aContract := getContract() }, 'Obtendo contrato...', 'Verificando contratos vigentes para o cliente...' )
            if len( aContract ) > 0
                lChecked := lSupabase .and. Date() <= aContract[3]
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
    oPgAtu:SetCancelAction( {|| MsgYesNo( 'Está certo de que gostaria de sair do do assistente?', 'Tem certeza?' ), oDlgConf:DeActivate() } )

    // Página 2 - Dados do conrtato
    oPgAtu := oWiz:AddStep("2", {|oPanel| buildPanel( 2 /* nPage */, oPanel) } )
    oPgAtu:SetStepDescription( 'Status do Contrato' )
    oPgAtu:SetNextAction( {|| nextPage( 2 /* nPageAtu */) } )
    oPgAtu:SetPrevAction( {|| .T. } )
    oPgAtu:SetPrevTitle( "Status de Conexão" )
    oPgAtu:SetCancelAction( {|| MsgYesNo( 'Está certo de que gostaria de sair do do assistente?', 'Tem certeza?' ), oDlgConf:DeActivate() } )

    // Página 3 - Finalização
    oPgAtu := oWiz:AddStep("3", {|oPanel| buildPanel( 3 /* nPage */, oPanel) } )
    oPgAtu:SetStepDescription( 'Finalização' )
    oPgAtu:SetNextAction( {|| oDlgConf:DeActivate() } )
    oPgAtu:SetPrevAction( {|| .T. } )
    oPgAtu:SetPrevTitle( "Contrato" )
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


    elseif nPage == 3       // Finalização
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

    if nAtual == 1      // Configurações do supabase

        lSuccess := lSupabase
        if ! lSuccess
            Hlp( 'SUPABASE',;
                 'Falha durante a tentativa de conexão com o banco web',;
                 'Tente novamente em alguns minutos' )
        endif

    elseif nAtual == 2  // Fim
        lSuccess := .T.
    endif

return lSuccess

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
