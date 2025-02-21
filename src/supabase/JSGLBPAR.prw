#include 'totvs.ch'
#include 'protheus.ch'
#include 'topconn.ch'

#define APP_ID 1        // ID da aplica��o no Supabase

/*/{Protheus.doc} JSGLBPAR
Fun��o para configurar os par�metros do Painel de Compras
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@param lCheck, logical, Indica se a fun��o est� sendo chamada apenas para checagem da comunica��o com supabase
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
    MsAguarde({|| lSupabase := chkActive() }, 'Conectando...', 'Checando conex�o com ambiente web...' )
    if lSupabase
        MsAguarde({|| nCustomer := getCustomer() }, 'Obtendo dados do cliente...', 'Identificando cliente...' )
        if nCustomer > 0
            MsAguarde({|| aContract := getContract() }, 'Obtendo contrato...', 'Verificando contratos vigentes para o cliente...' )
            if len( aContract ) > 0
                lChecked := lSupabase .and. Date() <= aContract[3]
            endif
        endif
    endif
    
    // Quando for apenas para chegar e o retorno for verdadeiro, nem exibe a tela de configura��es
    if lCheck .and. lChecked
        if aContract[2]     // Verifica se � vers�o Trial
            Hlp( 'TRIAL_VERSION',;
                'Voc� est� utilizando a rotina Painel de Compras em vers�o trial (vers�o de avalia��o)',;
                'Aproveite todas as funcionalidades, voc� tem at� '+ DtoC( aContract[3] ) +' para fazer seu setor de compras decolar!' )
        endif
        Return lChecked
    endif

    oDlgConf := FWDialogModal():New()
    oDlgConf:SetBackground( .T. )
    oDlgConf:SetTitle( 'PlugIn Painel de Compras - '+ U_JSGETVER() )
    oDlgConf:SetSubTitle( 'Permite definir os par�metros e configura��es internas do Painel de Compras no Protheus' )
    oDlgConf:SetSize( 300, 480 )
    oDlgConf:EnableFormBar( .F. )
    oDlgConf:SetCloseButton( .F. )
    oDlgConf:SetEscClose( .F. )
    oDlgConf:CreateDialog()
    oPanel := oDlgConf:GetPanelMain() 

    oWiz := FWWizardControl():New( oPanel )
    oWiz:ActiveUISteps()

    // P�gina 1 - Dados de conex�o com supabase
    oPgAtu := oWiz:AddStep("1")
    oPgAtu:SetStepDescription( 'Status do banco web' )
    oPgAtu:SetConstruction( {|oPanel| buildPanel( 1 /* nPage */, oPanel) } )
    oPgAtu:SetNextAction( {|| nextPage( 1 /* nPageAtu */) } )
    oPgAtu:SetCancelAction( {|| MsgYesNo( 'Est� certo de que gostaria de sair do do assistente?', 'Tem certeza?' ), oDlgConf:DeActivate() } )

    // P�gina 2 - Dados do conrtato
    oPgAtu := oWiz:AddStep("2", {|oPanel| buildPanel( 2 /* nPage */, oPanel) } )
    oPgAtu:SetStepDescription( 'Status do Contrato' )
    oPgAtu:SetNextAction( {|| nextPage( 2 /* nPageAtu */) } )
    oPgAtu:SetPrevAction( {|| .T. } )
    oPgAtu:SetPrevTitle( "Status de Conex�o" )
    oPgAtu:SetCancelAction( {|| MsgYesNo( 'Est� certo de que gostaria de sair do do assistente?', 'Tem certeza?' ), oDlgConf:DeActivate() } )

    // P�gina 3 - Finaliza��o
    oPgAtu := oWiz:AddStep("3", {|oPanel| buildPanel( 3 /* nPage */, oPanel) } )
    oPgAtu:SetStepDescription( 'Finaliza��o' )
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
Fun��o respons�vel pela cria��o dos objetos gr�ficos de acordo com a p�gina que est� sendo criada no wizard
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 23/08/2023
@param nPage, numeric, indica o n�mero da p�gina que est� sendo criada
@param oPanel, object, objeto do painel onde os objetos ser�o dispostos
/*/
Static Function buildPanel( nPage, oPanel )

    local nLine     := 1 as numeric
    local nLnSize   := 20 as numeric
    Local oFont     := TFont():New('Courier New',, -12, .F.)
    local bSupabase := {|| 'Sincroniza��o online....: '+ iif( lSupabase, "Online", "Offline" ) }
    local bContract := {|| 'Data Ades�o.............: '+ DtoC( iif( lSupabase, aContract[1], StoD(" ") ) ) }
    local bContType := {|| 'Status Licenciamento....: '+ contractType() }
    local bDataExp  := {|| 'Data de expira��o.......: '+ DtoC( iif( lSupabase, aContract[3], StoD(" ") ) ) }
    local cMessage  := "" as character

    default nPage := 1

    if nPage == 1       // dados de conex�o ao supabase
        
        // Integra��o ativa ou inativa
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


    elseif nPage == 3       // Finaliza��o
        nLine := 2
        cMessage := "A checagem do PlugIn Painel de Compras foi finalizada"
        if Date() > aContract[3]
            cMessage += ", por�m, "
            cMessage += iif( aContract[2], "a vers�o de avalia��o expirou!", "a vig�ncia do contrato expirou!" )
            cMessage += " Entre em contato com seu parceiro de neg�cios e renove seu contrato atrav�s do telefone/WhatsApp (45) 9 9981 5097."
        endif
        oSayEnd := TSay():New( nLine*nLnSize, 30, {|| cMessage + chr(13)+chr(10) +;
                            'Vers�o: '+ U_JSGETVER() },;
                             oPanel,,oFont,,,,.T.,CLR_GRAY,CLR_WHITE,400,60)
        oSayEnd:CtrlRefresh()

    endif

return Nil

/*/{Protheus.doc} contractType
Fun��o para retornar tipo de contrato atual do cliente
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
            cContType := "Trial (vers�o de avalia��o"+ iif( Date() > aContract[3], " expirada", "" ) +")"
        elseif Date() > aContract[3]        // T�rmino do contrato
            cContType := "Vig�ncia do contrato expirada"
        else
            cContType := "Contrato Vigente"
        endif
    else
        cContType := ""
    endif
return cContType

/*/{Protheus.doc} nextPage
Fun��o executada ao clicar sobre o bot�o next do wizard
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 23/08/2023
@param nAtual, numeric, indica a p�gina em que o usu�rio acabou de definir os par�metros
@return logical, lSuccess
/*/
Static Function nextPage( nAtual )
    
    Local lSuccess := .T. as logical

    if nAtual == 1      // Configura��es do supabase

        lSuccess := lSupabase
        if ! lSuccess
            Hlp( 'SUPABASE',;
                 'Falha durante a tentativa de conex�o com o banco web',;
                 'Tente novamente em alguns minutos' )
        endif

    elseif nAtual == 2  // Fim
        lSuccess := .T.
    endif

return lSuccess

/*/{Protheus.doc} chkActive
Fun��o para checar se a conex�o com o supabase est� online
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

    // Verifica se o cliente j� � cadastrado
    oResult := U_JSSUPABASE( "GET", "CUSTOMER", {"ID"}, cWhere )
    if ValType( oResult ) == 'J' .and. len( oResult ) > 0
        nCustomer := oResult[1]["ID"]
    else

        // Se n�o for cadastrado, j� realiza o cadastro com base nos dados da SM0
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
                "ID do cliente n�o foi criado! Verifique a conex�o junto ao fornecedor do Painel de Compras" )
        endif
    endif
    FreeObj( oResult )
    oResult := Nil

return nCustomer

/*/{Protheus.doc} getContract
Fun��o para obter os dados do contrato do cliente
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
                "Dados do contrato n�o foram obtidos! Verifique a conex�o junto ao fornecedor do Painel de Compras" )
        endif
    endif
    FreeObj( oResult )
    oResult := Nil

return aContract

/*/{Protheus.doc} hlp
Fun��o facilitadora para utiliza��o da fun��o Help do Protheus
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 08/04/2024
@param cTitle, character, Titulo da janela
@param cFail, character, Informa��es sobre a falha
@param cHelp, character, Informa��es com texto de ajuda
/*/
static function hlp( cTitle, cFail, cHelp )
return Help( ,, cTitle,, cFail, 1, 0, NIL, NIL, NIL, NIL, NIL,{ cHelp } )
