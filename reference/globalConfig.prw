#include 'totvs.ch'
#include 'protheus.ch'
#include 'topconn.ch'

#define VERSION U_AVGETVER()            // retorna versão da integração
#define STATUS_OK  'Pronto'             // Status OK das tabelas intermediárias
#define STATUS_UPD 'Desatualizado'      // Status PRECISANDO DE ATUALIZACAO das tabelas intermediárias
#define STATUS_NOT 'Inexistente'        // Status INEXISTENTE das tabelas intermediárias
#define JOB_NAME   'AVJOBAPP'

/*/{Protheus.doc} AVGLBCON
Função para configurar os parâmetros de integração entre o ERP e o APP
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 23/08/2023
/*/
User Function AVGLBCON()

    Local oDlgConf as object
    Local oPanel   as object
    Local oWiz     as object
    Local oPgAtu   as object
    
    Private cMVSupa   := U_AVGETDB( .T. /* lLiteral */ )
    Private cMVKey    := U_AVGETKEY( .T. /* lLiteral */ )
    Private cSupabase := PADR( U_AVGETDB(), 80, ' ' ) as character
    Private cApiKey   := PADR( U_AVGETKEY(), 250, ' ' ) as character
    Private aMiddle   := {} as array
    Private oBrowse   as object
    Private oSayNuc   as object
    Private oSayUsr   as object
    Private oFieldNuc as object
    Private oFieldUsr as object
    Private oFieldGrp as object
    Private oFieldPrd as object
    Private oFieldLot as obtect
    Private oFieldFun as object
    Private oFieldIte as object
    Private oFieldOco as object
    Private oFieldCol as object
    Private oFieldSol as object
    Private oFieldMan as object
    Private oFieldReq as object
    Private oSayPrd   as object
    Private oSayLot   as object
    Private oSayFun   as object
    Private oSayGrp   as object
    Private oSayIte   as object
    Private oSayOco   as object
    Private aFldNuc   := {} as array
    Private aFldPrd   := {} as array
    Private aRelNuc   := {} as array
    Private aRelPrd   := {} as array
    Private lIntAct   := FindFunction( 'U_AVINTACT' ) .and. U_AVINTACT()
    Private aJOB      := {} as array

    aFldPrd := { 'ID', 'PROD_NOME', 'PROD_UN', 'PROD_GRUPO', 'PROD_ATIVO', 'D_E_L_E_T_' }

    // Relação entre os campos do supabase com os campos da tabela no Protheus
    aRelNuc := U_AVGETREL( 'nucleo' )
    aEval( aRelNuc, {|x| aAdd( aFldNuc, x[1] ) } )

    aRelPrd := {{ 'ID'                 , 'B1_COD'  , ''},;
                {'PROD_NOME'           , 'B1_DESC' , ''},;
                {'PROD_UN'             , 'B1_UM'   , ''},;
                {'PROD_GRUPO'          , 'B1_GRUPO', ''},;
                {'PROD_ATIVO'          , ''        , '!B1_MSBLQL=="1"' },;
                {'D_E_L_E_T_'          , ''        , "iif(Deleted(),'S','N')" }}

    oDlgConf := FWDialogModal():New()
    oDlgConf:SetBackground( .T. )
    oDlgConf:SetTitle( 'PlugIn Protheus x Avicola App - '+ VERSION )
    oDlgConf:SetSubTitle( 'Permite definir os parâmetros internos para integração entre o ERP e APP' )
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
    oPgAtu:SetStepDescription( 'Dados de conexão com supabase' )
    oPgAtu:SetConstruction( {|oPanel| buildPanel( 1 /* nPage */, oPanel) } )
    oPgAtu:SetNextAction( {|| nextPage( 1 /* nPageAtu */), iif( ! lIntAct, oDlgConf:DeActivate(), .T. ) } )
    oPgAtu:SetCancelAction( {|| MsgYesNo( 'Está certo de que gostaria de sair do do assistente de configuração?', 'Tem certeza?' ), oDlgConf:DeActivate() } )

    // Página 2 - Criação do ambiente intermediário (tabelas no banco do ERP)
    oPgAtu := oWiz:AddStep("2", {|oPanel| buildPanel( 2 /* nPage */, oPanel) } )
    oPgAtu:SetStepDescription( 'Tabelas internas do PlugIn no ERP' )
    oPgAtu:SetNextAction( {|| nextPage( 2 /* nPageAtu */ ) } )
    oPgAtu:SetPrevAction( {|| .T. } )
    oPgAtu:SetPrevTitle( "Supabase" )
    oPgAtu:SetCancelAction( {|| MsgYesNo( 'Está certo de que gostaria de sair do assistente de configuração?', 'Tem certeza?' ), oDlgConf:DeActivate() } )
    oPgAtu:SetCancelWhen( { || .T. } )

    // Página 3 - Campos Customizados
    oPgAtu := oWiz:AddStep("3", {|oPanel| buildPanel( 3 /* nPage */, oPanel) } )
    oPgAtu:SetStepDescription( 'Checagem de Campos Customizados' )
    oPgAtu:SetNextAction( {|| nextPage( 3 /* nPageAtu */ ) } )
    oPgAtu:SetPrevAction( {|| .T. } )
    oPgAtu:SetPrevTitle( "Tabelas" )
    oPgAtu:SetCancelAction( {|| MsgYesNo( 'Está certo de que gostaria de sair do assistente de configuração?', 'Tem certeza?' ), oDlgConf:DeActivate() } )
    oPgAtu:SetCancelWhen( { || .T. } )

    // Página 4 - Merge de dados
    oPgAtu := oWiz:AddStep("4", {|oPanel| buildPanel( 4 /* nPage */, oPanel) } )
    oPgAtu:SetStepDescription( 'Merge de Dados ERP x App' )
    oPgAtu:SetNextAction( {|| nextPage( 4 /* nPageAtu */ ) } )
    oPgAtu:SetPrevAction( {|| .T. } )
    oPgAtu:SetPrevTitle( "Campos" )
    oPgAtu:SetCancelAction( {|| MsgYesNo( 'Está certo de que gostaria de sair do assistente de configuração?', 'Tem certeza?' ), oDlgConf:DeActivate() } )
    oPgAtu:SetCancelWhen( { || .T. } )

    // Página 5 - Configuração do JOB
    oPgAtu := oWiz:AddStep("5", {|oPanel| buildPanel( 5 /* nPage */, oPanel) } )
    oPgAtu:SetStepDescription( 'JOB de Integração' )
    oPgAtu:SetNextAction( {|| nextPage( 5 /* nPageAtu */ ) } )
    oPgAtu:SetPrevAction( {|| .T. } )
    oPgAtu:SetPrevTitle( "Merge de Dados" )
    oPgAtu:SetCancelAction( {|| MsgYesNo( 'Está certo de que gostaria de sair do assistente de configuração?', 'Tem certeza?' ), oDlgConf:DeActivate() } )
    oPgAtu:SetCancelWhen( { || .T. } )

    // Página 6 - Finalização
    oPgAtu := oWiz:AddStep("6", {|oPanel| buildPanel( 6 /* nPage */, oPanel) } )
    oPgAtu:SetStepDescription( 'Finalização' )
    oPgAtu:SetNextAction( {|| oDlgConf:DeActivate() } )
    oPgAtu:SetPrevAction( {|| .T. } )
    oPgAtu:SetPrevTitle( "JOB de Integração" )
    oPgAtu:SetCancelAction( {|| oDlgConf:DeActivate() } )
    oPgAtu:SetCancelWhen( { || .F. } )

    oWiz:Activate()

    oDlgConf:Activate()
    oWiz:Destroy()

return nil

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
    
    Local oSupabase       as object
    Local oApiKey         as object
    Local oIntAct         as object
    Local aColumns  := {} as array
    Local aTables   := {} as array
    Local bStatus
    Local oFont     := TFont():New('Courier New', , -12, .F.)
    local oFontLb   := TFont():New('Courier New', , -11, .F.)
    local bGrupo    :={|| getText( 'grupo' , nPage )}
    local bProduto  :={|| getText( 'produto' , nPage )}
    Local bNucleo   :={|| getText( 'nucleo' , nPage )}
    local bUsrNuc   :={|| getText( 'funcaoxnucleo' , nPage )}
    local bLote     :={|| getText( 'lote' , nPage )}
    local bFuncao   :={|| getText( 'funcao' , nPage )}
    local bItem     :={|| getText( 'subitens' , nPage )}
    local bOcor     :={|| getText( 'ocorrencias' , nPage )}
    local bColeta   :={|| getText( 'coletaitens' , nPage )}
    local bSolicita :={|| getText( 'solicitacoes' , nPage )}
    local bManut    :={|| getText( 'manutencao', nPage ) }
    local bRequest  :={|| getText( 'pedidoitem', nPage ) }
    local aIntAct   :={"A=Ativa", "D=Desativa"}
    local cIntAct   := iif(lIntAct, 'A' , 'D' )
    local oSayEnd         as object
    local oLbOnSt         as object
    local oOnSt           as object
    local cOnSt     := JOB_NAME
    local oRefRate        as object
    local nRefRate  := 60 as numeric
    local oLbJOB          as object
    local oMain           as object
    local cMain     := "U_AVJBSYNC"
    local oEnv            as object
    local cEnv      := GetEnvServer()
    local oParams         as object
    local nParams   := 3  as numeric
    local oPar1           as object
    local cPar1     := cEmpAnt
    local oPar2           as object
    local cPar2     := cFilAnt
    local oPar3           as object
    local nPar3     := 1  as numeric
    local nLine     := 1  as numeric
    local nLnSize   := 12 as numeric
    local cCombo    := "Ativo"
    local aJOBChg   := {} as array
    local oSave           as object
    local oDelete         as object
    local oGroup          as object
    local cIniName  := "" as character
    local aSessions := {} as array
    local cLastDT   := AllTrim( SuperGetMv( 'MV_X_AVJDT' ,,"" ) )
    local oLastDT         as object

    default nPage := 1

    if nPage == 1       // dados de conexão ao supabase

        // URL Supabase
        oSupabase := TGet():New( 10, 04, {|u| if(PCount()>0,cSupabase:=u,cSupabase)}, oPanel, 200, 12,,,,,,,,.T. /* lPixel */,,,{|| .T. }/* bWhen */,;
							,, /* bChange */, .F. /* lReadOnly */, .F. /* lPassword */,,'cSupabase',,,,.T.,.F.,,'Supabase URL:', 1 /* nLabelPos */  )

        // API-Key
        oApiKey := TGet():New( 40, 04, {|u| if(PCount()>0,cApiKey:=u,cApiKey)}, oPanel, 400, 12,,,,,,,,.T. /* lPixel */,,,{|| .T. }/* bWhen */,;
							,, /* bChange */, .F. /* lReadOnly */, .F. /* lPassword */,,'cApiKey',,,,.T.,.F.,,'Supabase API-Key:', 1 /* nLabelPos */  )
        
        // Integração ativa ou inativa
        oIntAct := TComboBox():New(70,04,{|u|if(PCount()>0,cIntAct:=u,cIntAct)},aIntAct,100,13,oPanel,,{|| lIntAct := SubStr(cIntAct,1,1) == 'A' };
        ,,,,.T.,,,,,,,,,'cIntAct', 'Ativa/Desativa Integração' /* cLabel */, 1 /* nPosLabel */)

    elseif nPage == 2   // tabelas de controle interno do plugIn
        
        aMiddle := {}
        aTables := U_AVGETTBL()     // Retorna tabelas da integração
        aEval( aTables, {|x| aAdd( aMiddle, { x[1], x[2], retStatus( x[1] ) } ) } )
        
        aColumns := {}
        aAdd( aColumns, { 'Tabela'   , {|| aMiddle[oBrowse:At()][1] }, 'C', '@!', 1, 020, 0 } )
        aAdd( aColumns, { 'Descrição', {|| aMiddle[oBrowse:At()][2] }, 'C', '@x', 1, 100, 0 } )
        aAdd( aColumns, { 'Status'   , {|| aMiddle[oBrowse:At()][3] }, 'C', '@x', 1, 015, 0 } )
        
        // Regra para definição do status do registro
        bStatus := {|| iif( AllTrim( aMiddle[oBrowse:At()][3] ) == STATUS_OK, 'BR_VERDE',;
                        iif( AllTrim( aMiddle[oBrowse:At()][3] ) == STATUS_UPD, 'BR_AMARELO',;
                        'BR_VERMELHO' ) ) }

        // Cria um browse para exibir o processo de manutenção das tabelas
        oBrowse := FWBrowse():New( oPanel )
        oBrowse:SetDataArray()                  // Tipo de dados por trás do browse
        oBrowse:SetArray( aMiddle )             // Dados
        oBrowse:AddStatusColumn( bStatus )      // Legenda
        oBrowse:SetColumns( aColumns )          // Demais colunas
        oBrowse:DisableReport()
        oBrowse:DisableConfig()
        oBrowse:DisableLocate()
        oBrowse:DisableFilter()
        oBrowse:DisableSeek()
        oBrowse:Activate( .T. /* lFWBrowse */)

    elseif nPage == 3       // Campos customizados

        nLine := 1
        oFieldNuc := TSay():New( nLine*nLnSize, 30, bNucleo, oPanel,,oFont,,,,.T.,CLR_GRAY,CLR_WHITE,400,20)
        oFieldNuc:CtrlRefresh()
        
        nLine++
        oFieldUsr := TSay():New( nLine*nLnSize, 30, bUsrNuc, oPanel,,oFont,,,,.T.,CLR_GRAY,CLR_WHITE,400,20)
        oFieldUsr:CtrlRefresh()

        nLine++
        oFieldGrp := TSay():New( nLine*nLnSize, 30, bGrupo, oPanel,,oFont,,,,.T.,CLR_GRAY,CLR_WHITE,400,20)
        oFieldGrp:CtrlRefresh()

        nLine++
        oFieldPrd := TSay():New( nLine*nLnSize, 30, bProduto, oPanel,,oFont,,,,.T.,CLR_GRAY,CLR_WHITE,400,20)
        oFieldPrd:CtrlRefresh()

        nLine++
        oFieldLot := TSay():New( nLine*nLnSize, 30, bLote, oPanel,,oFont,,,,.T.,CLR_GRAY,CLR_WHITE,400,20)
        oFieldLot:CtrlRefresh()

        nLine++
        oFieldFun := TSay():New( nLine*nLnSize, 30, bFuncao, oPanel,,oFont,,,,.T.,CLR_GRAY,CLR_WHITE,400,20)
        oFieldFun:CtrlRefresh()

        nLine++
        oFieldIte := TSay():New( nLine*nLnSize, 30, bItem, oPanel,,oFont,,,,.T.,CLR_GRAY,CLR_WHITE,400,20)
        oFieldIte:CtrlRefresh()

        nLine++
        oFieldOco := TSay():New( nLine*nLnSize, 30, bOcor, oPanel,,oFont,,,,.T.,CLR_GRAY,CLR_WHITE,400,20)
        oFieldOco:CtrlRefresh()

        nLine++
        oFieldCol := TSay():New( nLine*nLnSize, 30, bColeta, oPanel,,oFont,,,,.T.,CLR_GRAY,CLR_WHITE,400,20)
        oFieldCol:CtrlRefresh()

        nLine++
        oFieldSol := TSay():New( nLine*nLnSize, 30, bSolicita, oPanel,,oFont,,,,.T.,CLR_GRAY,CLR_WHITE,400,20)
        oFieldSol:CtrlRefresh()

        nLine++
        oFieldMan := TSay():New( nLine*nLnSize, 30, bManut, oPanel,,oFont,,,,.T.,CLR_GRAY,CLR_WHITE,400,20)
        oFieldMan:CtrlRefresh()

        nLine++
        oFieldReq := TSay():New( nLine*nLnSize, 30, bRequest, oPanel,,oFont,,,,.T.,CLR_GRAY,CLR_WHITE,400,20)
        oFieldReq:CtrlRefresh()

    elseif nPage == 4       // Merge de dados
        
        nLine := 1
        oSayNuc := TSay():New( nLine*nLnSize, 30, bNucleo, oPanel,,oFont,,,,.T.,CLR_GRAY,CLR_WHITE,400,20)
        oSayNuc:CtrlRefresh()

        nLine++
        oSayUsr := TSay():New( nLine*nLnSize, 30, bUsrNuc, oPanel,,oFont,,,,.T.,CLR_GRAY,CLR_WHITE,400,20)
        oSayUsr:CtrlRefresh()

        nLine++
        oSayPrd := TSay():New( nLine*nLnSize, 30, bProduto, oPanel,,oFont,,,,.T.,CLR_GRAY,CLR_WHITE,400,20)
        oSayPrd:CtrlRefresh()

        nLine++
        oSayGrp := TSay():New( nLine*nLnSize, 30, bGrupo, oPanel,,oFont,,,,.T.,CLR_GRAY,CLR_WHITE,400,20)
        oSayGrp:CtrlRefresh()

        nLine++
        oSayLot := TSay():New( nLine*nLnSize, 30, bLote, oPanel,,oFont,,,,.T.,CLR_GRAY,CLR_WHITE,400,20)
        oSayLot:CtrlRefresh()
        
        nLine++
        oSayFun := TSay():New( nLine*nLnSize, 30, bFuncao, oPanel,,oFont,,,,.T.,CLR_GRAY,CLR_WHITE,400,20)
        oSayFun:CtrlRefresh()

        nLine++
        oSayIte := TSay():New( nLine*nLnSize, 30, bItem, oPanel,,oFont,,,,.T.,CLR_GRAY,CLR_WHITE,400,20)
        oSayIte:CtrlRefresh()

        nLine++
        oSayOco := TSay():New( nLine*nLnSize, 30, bOcor, oPanel,,oFont,,,,.T.,CLR_GRAY,CLR_WHITE,400,20)
        oSayOco:CtrlRefresh()

    elseif nPage == 5       // JOB de integração

        nLine     := 1
        nLnSize   := 12
        cIniName  := GetSrvIniName()
        aSessions := GetINISessions( Upper(cIniName) )

        oLbOnSt  := TSay():New( nLine * nLnSize, 20, {|| '[ONSTART]' }, oPanel,,oFontLb/* oFont */,,,,.T.,CLR_BLUE,CLR_WHITE,40,20)
        nLine++
        cOnSt    := PADR(GetPvProfString( "ONSTART", 'Jobs', cOnSt, cIniName ), 80, ' ' )
        oOnSt    := TGet():New( nLine * nLnSize, 20, {|u| if(PCount()>0,cOnSt:=u,cOnSt)}, oPanel, 40, 10,,,,,,,,.T. /* lPixel */,,,{|| .T. }/* bWhen */,;
							,, {|| aJOBChg[1] := cOnSt, oSave:SetFocus(), oOnSt:SetFocus() }/* bChange */, .F. /* lReadOnly */, .F. /* lPassword */,,'cOnSt',,,,.T.,.F.,,PADR('jobs',15,'.')+': ', 2 /* nLabelPos */,oFontLb, CLR_GREEN  )
        nLine++
        nRefRate := GetPvProfileInt( "ONSTART", 'RefreshRate', nRefRate, cIniName )
        oRefRate := TGet():New( nLine * nLnSize, 20, {|u| if(PCount()>0,nRefRate:=u,nRefRate)}, oPanel, 40, 10,,,,,,,,.T. /* lPixel */,,,{|| .T. }/* bWhen */,;
							,, {|| aJOBChg[2] := nRefRate, oSave:SetFocus(), oRefRate:SetFocus() }/* bChange */, .F. /* lReadOnly */, .F. /* lPassword */,,'nRefRate',,,,.T.,.F.,,PADR('RefreshRate',15,'.')+': ', 2 /* nLabelPos */,oFontLb, CLR_GREEN )
        nLine += 2
        oLbJOB   := TSay():New( nLine * nLnSize, 20, {|| '['+ JOB_NAME +']' }, oPanel,,oFontLb/* oFont */,,,,.T.,CLR_BLUE,CLR_WHITE,40,20)
        nLine++
        cMain    := PADR(GetPvProfString( JOB_NAME, 'Main', cMain, cIniName ), 10, ' ' )
        oMain    := TGet():New( nLine * nLnSize, 20, {|u| if(PCount()>0,cMain:=u,cMain)}, oPanel, 40, 10,,,,,,,,.T. /* lPixel */,,,{|| .T. }/* bWhen */,;
							,, {|| aJOBChg[3] := cMain, oSave:SetFocus(), oMain:SetFocus() }/* bChange */, .F. /* lReadOnly */, .F. /* lPassword */,,'cMain',,,,.T.,.F.,,PADR('Main',15,'.')+': ', 2 /* nLabelPos */,oFontLb, CLR_GREEN )
        
        oGroup := TGroup():New( (nLine * nLnSize)-15, 200, (nLine * nLnSize)+15, 200+86,'Configurações',oPanel,,,.T.)
        oSave  := TButton():New( nLine * nLnSize, 202, "Salvar", oPanel, {|| Save(aJOBChg, cIniName), aJOB := aClone( aJOBChg ), oEnv:SetFocus(), oSave:SetFocus() },;
                                 40,10,,,.F.,.T.,.F.,,.F.,{|| Empty(aJOB) .or. changed(aJOB,aJOBChg) },,.F. )
        oDelete := TButton():New( nLine * nLnSize, 244, "Remover", oPanel, {|| Remove(cIniName), aJOB := {}, oEnv:SetFocus(), oDelete:SetFocus() },;
                                 40,10,,,.F.,.T.,.F.,,.F.,{|| ! Empty( aJOB ) },,.F. )
        nLine++
        cEnv     := PADR(GetPvProfString( JOB_NAME, 'Environment', cEnv, cIniName ), 20, ' ' )
        oEnv     := TGet():New( nLine * nLnSize, 20, {|u| if(PCount()>0,cEnv:=u,cEnv)}, oPanel, 40, 10,,,,,,,,.T. /* lPixel */,,,{|| .T. }/* bWhen */,;
							,, {|| aJOBChg[4] := cEnv, oSave:SetFocus(), oEnv:SetFocus() }/* bChange */, .F. /* lReadOnly */, .F. /* lPassword */,,'cEnv',,,,.T.,.F.,,PADR('Environment',15,'.')+': ', 2 /* nLabelPos */,oFontLb, CLR_GREEN )
        nLine++
        nParams  := GetPvProfileInt( JOB_NAME, 'nParms', nParams, cIniName )
        oParams  := TGet():New( nLine * nLnSize, 20, {|u| if(PCount()>0,nParams:=u,nParams)}, oPanel, 40, 10,,,,,,,,.T. /* lPixel */,,,{|| .T. }/* bWhen */,;
							,, {|| aJOBChg[5] := nParams, oSave:SetFocus(), oParams:SetFocus() }/* bChange */, .F. /* lReadOnly */, .F. /* lPassword */,,'nParams',,,,.T.,.F.,,PADR('nParms',15,'.')+': ', 2 /* nLabelPos */,oFontLb, CLR_GREEN )

        // Data e hora da última execução do JOB        
        oLastDT    := TGet():New( nLine * nLnSize, 200, {|u| if(PCount()>0,cLastDT:=u,cLastDT)}, oPanel, 086, 10,,,,,,,,.T. /* lPixel */,,,/* bWhen */,;
							,,/* bChange */, .T. /* lReadOnly */, .F. /* lPassword */,,'cLastDT',,,,.T.,.F.,,PADR('Ultima Execução',15,'.')+': ', 1 /* nLabelPos */ )
        
        nLine++
        cPar1    := PADR(GetPvProfString( JOB_NAME, 'Parm1', cPar1, cIniName ), len( cEmpAnt ), ' ' )
        oPar1    := TGet():New( nLine * nLnSize, 20, {|u| if(PCount()>0,cPar1:=u,cPar1)}, oPanel, 40, 10,,,,,,,,.T. /* lPixel */,,,{|| .T. }/* bWhen */,;
							,, {|| aJOBChg[6] := cPar1, oSave:SetFocus(), oPar1:SetFocus() }/* bChange */, .F. /* lReadOnly */, .F. /* lPassword */,,'cPar1',,,,.T.,.F.,,PADR('Parm1',15,'.')+': ', 2 /* nLabelPos */,oFontLb, CLR_GREEN )
        nLine++
        cPar2    := PADR(GetPvProfString( JOB_NAME, 'Parm2', cPar2, cIniName ), len( cFilAnt ), ' ' )
        oPar2    := TGet():New( nLine * nLnSize, 20, {|u| if(PCount()>0,cPar2:=u,cPar2)}, oPanel, 40, 10,,,,,,,,.T. /* lPixel */,,,{|| .T. }/* bWhen */,;
							,, {|| aJOBChg[7] := cPar2, oSave:SetFocus(), oPar2:SetFocus() }/* bChange */, .F. /* lReadOnly */, .F. /* lPassword */,,'cPar2',,,,.T.,.F.,,PADR('Parm2',15,'.')+': ', 2 /* nLabelPos */,oFontLb, CLR_GREEN )
        nLine++
        nPar3    := GetPvProfileInt( JOB_NAME, 'Parm3', nPar3, cIniName )
        if nPar3 == 1
            cCombo := "Ativo"
        else
            cCombo := "Inativo"
        endif
        oPar3    := TComboBox():New(nLine * nLnSize,20,{|u|if(PCount()>0,cCombo:=u,cCombo)}, {"Ativo","Inativo"},40,12,oPanel,,;
                    {|| nPar3 := iif(AllTrim(cCombo) == 'Ativo', 1, 0),;
                        aJOBChg[8] := nPar3,; 
                        oSave:SetFocus(), oPar3:SetFocus() };
                    ,,,,.T.,,,,,,,,,'cCombo', PADR('Parm3',15,'.')+': ', 2 /* nLabelPos */,oFontLb,CLR_GREEN )
        aJOB := { cOnSt,;
                  nRefRate,;
                  cMain,;
                  cEnv,;
                  nParams,;
                  cPar1,;
                  cPar2,;
                  nPar3 }
        aJOBChg := aClone( aJob )
        // Não adianta ter os dados no vetor se o arquivo appserver.ini não estiver configurado
        if aScan( aSessions, {|x| AllTrim( x ) == AllTrim( JOB_NAME ) } ) == 0
            aJOB := {} 
        endif
        oSave:SetFocus()
        oOnSt:SetFocus()

    elseif nPage == 6       // Finalização

        oSayEnd := TSay():New( 20, 30, {|| 'A configuração do PlugIn de Integração entre Protheus e '+;
                            'o App Avícola foi finalizada com S U C E S S O !' + chr(13)+chr(10) +;
                            'Versão: '+ VERSION },;
                             oPanel,,oFont,,,,.T.,CLR_GRAY,CLR_WHITE,400,60)
        oSayEnd:CtrlRefresh()

    endif

return Nil

/*/{Protheus.doc} Remove
Função para remover informações do JOB do appserver.ini
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 29/11/2023
@param cIni, character, Nome do arquivo appserver.ini
@return logical, lSuccess
/*/
static function Remove( cIni )
    local lSuccess := .T. as logical
    local cSecao   := "" as character
    
    cSecao := "ONSTART"
    DeleteSectionINI( cSecao, cIni )
    cSecao := AllTrim( JOB_NAME )
    DeleteSectionINI( cSecao, cIni )

return lSuccess

/*/{Protheus.doc} save
Função para salvar os dados definidos nos parâmetros do JOB
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 29/11/2023
@param aData, array, dados a serem salvos
@param cIni, character, nome do arquivo appserver.ini
@return logical, lSuccess
/*/
static function save( aData, cIni )
    
    local lSuccess := .T.
    local cSecao   := "" as character
    local cChave   := "" as character
    local cConteudo:= "" as character

    cSecao    := "ONSTART"
    cChave    := "Jobs"
    cConteudo := AllTrim( aData[1] )
    WritePProString( cSecao, cChave, cConteudo, cIni )
    cChave    := "RefreshRate"
    cConteudo := AllTrim( cValToChar( aData[2] ) )
    WritePProString( cSecao, cChave, cConteudo, cIni )

    cSecao    := JOB_NAME
    cChave    := "Main"
    cConteudo := AllTrim( aData[3] )
    WritePProString( cSecao, cChave, cConteudo, cIni )
    cChave    := "Environment"
    cConteudo := AllTrim( aData[4] )
    WritePProString( cSecao, cChave, cConteudo, cIni )
    cChave    := "nParms"
    cConteudo := AllTrim( cValToChar( aData[5] ) )
    WritePProString( cSecao, cChave, cConteudo, cIni )
    cChave    := "Parm1"
    cConteudo := AllTrim( aData[6] )
    WritePProString( cSecao, cChave, cConteudo, cIni )
    cChave    := "Parm2"
    cConteudo := AllTrim( aData[7] )
    WritePProString( cSecao, cChave, cConteudo, cIni )
    cChave    := "Parm3"
    cConteudo := AllTrim( cValToChar( aData[8] ) )
    WritePProString( cSecao, cChave, cConteudo, cIni )

return lSuccess


/*/{Protheus.doc} changed
Função para verificar se houve mudança nos dados dos parâmetros do JOB
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 29/11/2023
@param aOri, array, vetor com os dados de origem
@param aAtu, array, vetor atualizado
@return logical, lHasChange
/*/
static function changed( aOri, aAtu )
    local lHasChange := .F. as logical
    local nPos       := 0 as numeric
    aEval( aOri, {|x| nPos++, lHasChange := lHasChange .or. ! x == aAtu[nPos] } )
return lHasChange

/*/{Protheus.doc} getText
Retorna o texto da label de acordo com a tabela
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 14/09/2023
@param cTable, character, tabela
@return character, cText
/*/
static function getText( cTable, nPage )
    
    local nStrSize := 40 as numeric
    local cText    := "" as character

    if cTable == 'nucleo'
        if nPage == 3       // Campos Customizados
            cText := PADR( 'Campos Custom. Nucleos (ZH6)', nStrSize, '.' ) +': '+; 
                    iif( ZH6->( FieldPos( 'ZH6_X_IDAP' ) ) > 0 .and.;
                    ZH6->( FieldPos( 'ZH6_X_NAVI' ) ) > 0 .and. ;
                    ZH6->( FieldPos( 'ZH6_X_BEM' ) ) > 0, STATUS_OK, STATUS_UPD )
        elseif nPage == 4   // Merge de dados
            cText := PADR( 'App x ERP (Nucleos)', nStrSize, '.' ) +': '+ getStatus( cTable )
        endif
    elseif cTable == 'funcaoxnucleo'
        if nPage == 3
            cText := PADR( 'Campos Usuário x Nucleo (ZHV)', nStrSize, '.' ) +': '+ iif( ZHV->( FieldPos( 'ZHV_X_IDAP' ) ) > 0, STATUS_OK, STATUS_UPD )
        elseif nPage == 4
            cText := PADR( 'App x ERP (Usuários x Núcleo)', nStrSize, '.' ) +': '+ getStatus( cTable )
        endif
    elseif cTable == 'grupo'
        if nPage == 3
            cText := PADR( 'Campos Custom. Grupo (SBM)', nStrSize, '.' ) +': '+ iif( SBM->( FieldPos( 'BM_X_IDAP' ) ) > 0, STATUS_OK, STATUS_UPD )
        elseif nPage == 4
            cText := PADR( 'App x ERP (Grupo de Produtos)', nStrSize, '.' ) +': '+ getStatus( cTable )
        endif
    elseif cTable == 'produto'
        if nPage == 3
            cText := PADR( 'Campos Custom. Produtos (SB1)', nStrSize, '.' ) +': '+; 
                    iif( SB1->( FieldPos( 'B1_X_RANCH' ) ) > 0 .and. SB1->( FieldPos( 'B1_X_DTAP' ) ) > 0, STATUS_OK, STATUS_UPD )
        elseif nPage == 4
            cText := PADR( 'App x ERP (Produtos)', nStrSize, '.' ) +': '+ getStatus( cTable )
        endif
    elseif cTable == 'lote'
        if nPage == 3
            cText := PADR( 'Campos Custom. Lotes (ZH0)', nStrSize, '.' ) +': '+; 
                    iif( ZH0->( FieldPos( 'ZH0_X_IDAP' ) ) > 0, STATUS_OK, STATUS_UPD )
        elseif nPage == 4
            cText := PADR( 'App x ERP (Lotes)', nStrSize, '.' ) +': '+ getStatus( cTable )
        endif
    elseif cTable == 'funcao'
        if nPage == 3       // estrutura
            cText := PADR( 'Campos Custom. Funções (SRJ)', nStrSize, '.' ) +': '+; 
                    iif( SRJ->( FieldPos( 'RJ_X_IDAP' ) ) > 0, STATUS_OK, STATUS_UPD )
        elseif nPage == 4   // sincronização de dados
            cText := PADR( 'App x ERP (Funções)', nStrSize, '.' ) +': '+ getStatus( cTable )
        endif
    elseif cTable == 'subitens'
        if nPage == 3
            cText := PADR( 'Campos Custom. SubItens (ZH1)', nStrSize, '.' ) +': '+; 
                    iif( ZH1->( FieldPos( 'ZH1_X_IDAP' ) ) > 0 .and.; 
                         ZH1->( FieldPos( 'ZH1_X_APP' ) ) > 0 .and.; 
                         ZH1->( FieldPos( 'ZH1_X_SEXO' ) ) > 0 .and.;
                         ZH1->( FieldPos( 'ZH1_X_GRAP' ) ) > 0 .and.;
                         ZH1->( FieldPos( 'ZH1_X_NOMR' ) ) > 0, STATUS_OK, STATUS_UPD )
        elseif nPage == 4
            cText := PADR( 'App x ERP (SubItens)', nStrSize, '.' ) +': '+ getStatus( cTable )
        endif
    elseif cTable == 'ocorrencias'
        if nPage == 3
            cText := PADR( 'Campos Custom. Ocorrencias (SU9)', nStrSize, '.' ) +': '+; 
                    iif( SU9->( FieldPos( 'U9_X_IDAP' ) ) > 0 .and.; 
                         SU9->( FieldPos( 'U9_X_APP' ) ) > 0, STATUS_OK, STATUS_UPD )
        elseif nPage == 4
            cText := PADR( 'App x ERP (Ocorrencias)', nStrSize, '.' ) +': '+ getStatus( cTable )
        endif
    elseif cTable == 'coletaitens'
        cText := PADR( 'Campos Custom. Itens da Coleta (ZHL)', nStrSize, '.' ) +': '+; 
                iif( ZHL->( FieldPos( 'ZHL_X_IDAP' ) ) > 0, STATUS_OK, STATUS_UPD )
    elseif cTable == 'solicitacoes'
        cText := PADR( 'Campos Custom. Solicitações (ZIA)', nStrSize, '.' ) +': '+; 
                iif( ZIA->( FieldPos( 'ZIA_X_IDAP' ) ) > 0 .and. ;
                ZIA->( FieldPos( 'ZIA_X_IDSO' ) ) > 0, STATUS_OK, STATUS_UPD )
    elseif cTable == 'manutencao'
        cText := PADR( 'Campos Custom. OS Manutenções (STJ)', nStrSize, '.' ) +': '+; 
                iif( STJ->( FieldPos( 'TJ_X_IDAP' ) ) > 0 .and. ;
                STJ->( FieldPos( 'TJ_X_IDSO' ) ) > 0, STATUS_OK, STATUS_UPD )
    elseif cTable == 'pedidoitem'
        cText := PADR( 'Campos Custom. Req. ao Armazém (SCP)', nStrSize, '.' ) +': '+; 
                iif( SCP->( FieldPos( 'CP_X_IDAP' ) ) > 0 .and. ;
                SCP->( FieldPos( 'CP_X_IDPD' ) ) > 0, STATUS_OK, STATUS_UPD )
    endif
return cText

/*/{Protheus.doc} getStatus
Obtem status da sincronização dos dados com a tabela recebida por parâmetros
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 13/09/2023
@param cTabela, character, nome físico da tabela do supabase
@return character, cStatus
/*/
static function getStatus( cTabela )
    
    local cStatus  := STATUS_OK
    Local cQuery   := "" as character
    
    if cTabela == 'nucleo'

        // Verifica se há registros não sincronizados com o app
        cQuery := U_AVQRYDEF( cTabela, .T. /* lCount */ )
        DBUseArea( .T., 'TOPCONN', TcGenQry( ,,cQuery ), 'ZH6TMP', .F. /* lShared */, .T. /* lReadOnly */ )
        if ZH6TMP->QTDE > 0
            cStatus := STATUS_UPD
        endif
        ZH6TMP->( DBCloseArea() )

    elseif cTabela == 'funcaoxnucleo'

        // Verifica se no ERP há registros não sincronizados com o supabase
        cQuery := U_AVQRYDEF( cTabela, .T. /* lCount */ )
        DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), 'ZHVTMP', .F., .T. )
        if ! ZHVTMP->( EOF() )
            cStatus := iif( ZHVTMP->QTDE > 0, STATUS_UPD, cStatus )
        endif
        ZHVTMP->( DBCloseArea() )

    elseif cTabela == 'grupo'

        // Query para leitura dos grupos pendentes de sincronização
        cQuery := U_AVQRYDEF( cTabela, .T. /* lCount */ )
        DBUseArea( .T., 'TOPCONN', TcGenQry( ,,cQuery ), 'SBMTMP', .F., .T. )
        if ! SBMTMP->( EOF() )
            cStatus := iif( SBMTMP->QTDE > 0, STATUS_UPD, cStatus )
        endif
        SBMTMP->( DBCloseArea() )

    elseif cTabela == 'produto'

        // Query para identificar produtos a serem sincronizados com o app
        cQuery := U_AVQRYDEF( cTabela, .T. /* lCount */ )
        DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), 'SB1TMP', .F., .T. )
        if ! SB1TMP->( EOF() )
            cStatus := iif( SB1TMP->QTDE > 0, STATUS_UPD, cStatus )
        endif
        SB1TMP->( DBCloseArea() )

    elseif cTabela == 'lote'

        // Query para ver se há registros não sincronizados com o supabase
        cQuery := U_AVQRYDEF( cTabela, .T. /* lCount */ )
        DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), 'ZH0TMP', .F., .T. )
        if ! ZH0TMP->(EOF())
            cStatus := iif( ZH0TMP->QTDE > 0, STATUS_UPD, cStatus )
        endif
        ZH0TMP->( DBCloseArea() )

    elseif cTabela == 'funcao'

        DBSelectArea( 'SRJ' )
        SRJ->( DBSetOrder( 1 ) )

        // COnsulta se há registros não sincronizados com o supabase
        cQuery := U_AVQRYDEF( cTabela, .T. /* lCount */ )
        DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), 'SRJTMP', .F., .T. )
        if ! SRJTMP->( EOF() )
            cStatus := iif( SRJTMP->QTDE > 0, STATUS_UPD, cStatus )
        endif
        SRJTMP->( DBCloseArea() ) 

    elseif cTabela == 'subitens'
        
        DBSelectArea( 'ZH1' )
        ZH1->( DBSetOrder( 1 ) )
        
        cQuery := U_AVQRYDEF( cTabela, .T. /* lCount */ )
        DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), 'ZH1TMP', .F., .T. )
        if ! ZH1TMP->( EOF() )
            cStatus := iif( ZH1TMP->QTDE > 0, STATUS_UPD, cStatus )
        endif
        ZH1TMP->( DBCloseArea() )
    
    elseif cTabela == 'ocorrencias'

        DBSelectArea( 'SU9' )
        SU9->( DBSetOrder( 1 ) )

        cQuery := U_AVQRYDEF( cTabela, .T. /* lCount */ )
        DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), 'SU9TMP', .F., .T. )
        if ! SU9TMP->( EOF() )
            cStatus := iif( SU9TMP->QTDE > 0, STATUS_UPD, cStatus )
        endif
        SU9TMP->( DBCloseArea() )

    endif

return cStatus

/*/{Protheus.doc} retStatus
Devolve para o browse o status da tabela
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 23/08/2023
@param cTable, character, nome físico da tabela
@return character, cStatus
/*/
static function retStatus( cTable )
    
    Local cAlias  := "" as character
    Local aOldStr := {} as array
    Local aStruct := {} as array
    Local cStatus := STATUS_OK as character
    
    // Cria tabela de clientes Sovis
    if ! TcCanOpen( cTable )
        cStatus := STATUS_NOT
    else
        cAlias := GetNextAlias()
        DBUseArea( .F., 'TOPCONN', cTable, cAlias, .F., .F. )
        
        // Retorna estrutura da tabela para a versão atual do plugIn
        aStruct := U_AVTBLSTR( cTable )

        // Obtem a estrutura atual da tabela física presente no banco
        aOldStr := ( cAlias )->( DBStruct() )
        ( cAlias )->( DBCloseArea() )

        // Compara as duas estruturas para saber se tem necessidade de atualizar
        if hasChange( aStruct, aOldStr, cTable )
            cStatus := STATUS_UPD
        endif
    endif

return cStatus

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
        aIndex := U_AVTBLIDX( cTable ) 
        if len( aIndex ) > 0
            aEval( aIndex, {|x| lHasChange := lHasChange .or. ! TCCanOpen( cTable, x[1] ) } )
        endif
    endif

return lHasChange

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
    Local oResult  as object
    Local nX       := 0 as numeric
    Local aOldStr  := {} as array
    Local aStruct  := {} as array
    Local cAlias   := "" as character
    Local nTopErr  := 0 as numeric
    Local cSX6     := "SX6"
    Local aIndex   := {} as array
    Local nIndex   := 0 as numeric
    local lCreated := .T. as logical
    local lDone    := .T. as logical

    if nAtual == 1      // Configurações do supabase

        if lIntAct
            lSuccess := ! Empty( cSupabase ) .and. !Empty( cApiKey )
            if lSuccess
                oResult := U_SUPCLIENT( AllTrim( cSupabase ), AllTrim( cApiKey), "HEAD" /* cMethod */ )
                lSuccess := ValType( oResult ) == 'J'
                FreeObj( oResult )
                oResult := nil
                If lSuccess
                    // Valida se o parâmetro existe, se não existe, força a criação do mesmo no dicionário
                    if GetMV( cMVSupa, .T. )
                        PutMV( cMVSupa, cSupabase )
                    else
                        DBSelectArea( cSX6 )
                        ( cSX6 )->( DBSetOrder( 1 ) )
                        RecLock( cSX6, .T. )
                        ( cSX6 )->( FieldPut( FieldPos( 'X6_VAR'    ), cMVSupa ) )
                        ( cSX6 )->( FieldPut( FieldPos( 'X6_TIPO'   ), 'C' ) )
                        ( cSX6 )->( FieldPut( FieldPos( 'X6_DESCRIC'), 'URL para conexão do ERP ao Supabase' ) )
                        ( cSX6 )->( FieldPut( FieldPos( 'X6_DSCSPA' ), 'URL para la conexión del ERP a Supabase' ) )
                        ( cSX6 )->( FieldPut( FieldPos( 'X6_DSCENG' ), 'URL for ERP connecting to Supabase' ) )
                        ( cSX6 )->( FieldPut( FieldPos( 'X6_CONTEUD'), cSupabase ) )
                        ( cSX6 )->( FieldPut( FieldPos( 'X6_CONTSPA'), cSupabase ) )
                        ( cSX6 )->( FieldPut( FieldPos( 'X6_CONTENG'), cSupabase ) )
                        ( cSX6 )->( MsUnlock() )
                    endif

                    // Verifica existência do parâmetro com o código da chave da API para conexão ao supabase
                    if GetMv( cMVKey, .T. )
                        PutMV( cMVKey, cApiKey )
                    else
                        DBSelectArea( cSX6 )
                        ( cSX6 )->( DBSetOrder( 1 ) )
                        RecLock( cSX6, .T. )
                        ( cSX6 )->( FieldPut( FieldPos( 'X6_VAR'    ), cMVKey ) )
                        ( cSX6 )->( FieldPut( FieldPos( 'X6_TIPO'   ), 'C' ) )
                        ( cSX6 )->( FieldPut( FieldPos( 'X6_DESCRIC'), 'ApiKey para conexão do ERP ao Supabase' ) )
                        ( cSX6 )->( FieldPut( FieldPos( 'X6_DSCSPA' ), 'ApiKey para la conexión del ERP a Supabase' ) )
                        ( cSX6 )->( FieldPut( FieldPos( 'X6_DSCENG' ), 'ApiKey for ERP connecting to Supabase' ) )
                        ( cSX6 )->( FieldPut( FieldPos( 'X6_CONTEUD'), cApiKey ) )
                        ( cSX6 )->( FieldPut( FieldPos( 'X6_CONTSPA'), cApiKey ) )
                        ( cSX6 )->( FieldPut( FieldPos( 'X6_CONTENG'), cApiKey ) )
                        ( cSX6 )->( MsUnlock() )
                    endif
                else
                    U_HLP( 'Dados de Conexão Inválidos',;
                        'Os dados informados para conexão ao supabase podem não estar corretos.',;
                        'Verifique a URL e a APIKey para que o sistema consiga realizar a checagem das informações.' )
                endif
            else
                U_HLP( 'Dados Obrigatórios',;
                        'Os dados para conexão ao supabase são obrigatórios.',;
                        'Só será possível utilizar o  processo de integração quando forem informados os dados corretos de conexão ao supabase' )
            endif
        endif

        // Valida se o parâmetro existe, se não existe, força a criação do mesmo no dicionário
        if GetMV( U_AVINTACT( .T. /* lLiteral */), .T. )
            PutMV( U_AVINTACT( .T. /* lLiteral */), lIntAct )
        else
            DBSelectArea( cSX6 )
            ( cSX6 )->( DBSetOrder( 1 ) )
            RecLock( cSX6, .T. )
            ( cSX6 )->( FieldPut( FieldPos( 'X6_VAR'    ), U_AVINTACT( .T. /* lLiteral */) ) )
            ( cSX6 )->( FieldPut( FieldPos( 'X6_TIPO'   ), 'L' ) )
            ( cSX6 )->( FieldPut( FieldPos( 'X6_DESCRIC'), 'Ativa/Desativa Integração com App' ) )
            ( cSX6 )->( FieldPut( FieldPos( 'X6_DSCSPA' ), 'Ativa/Desativa Integração com App' ) )
            ( cSX6 )->( FieldPut( FieldPos( 'X6_DSCENG' ), 'Ativa/Desativa Integração com App' ) )
            ( cSX6 )->( FieldPut( FieldPos( 'X6_CONTEUD'), cValToChar(lIntAct) ) )
            ( cSX6 )->( FieldPut( FieldPos( 'X6_CONTSPA'), cValToChar(lIntAct) ) )
            ( cSX6 )->( FieldPut( FieldPos( 'X6_CONTENG'), cValToChar(lIntAct) ) )
            ( cSX6 )->( MsUnlock() )
        endif

        if ! lIntAct
            lSuccess := MsgYesNo( 'A integração com o aplicativo Avícola está desativada, deseja manter desta forma?', 'A T E N Ç Ã O !' )
        endif

    elseif nAtual == 2  // Estrutura intermediária
        
        if len( aMiddle ) > 0
            for nX := 1 to len( aMiddle )
                aIndex := U_AVTBLIDX( aMiddle[nX][1] )
                if aMiddle[nX][3] == STATUS_UPD         // Tabelas que precisam de update
                    
                    // Obtem um nome de alias temporário
                    cAlias := GetNextAlias()
                    DBUseArea( .F., 'TOPCONN', aMiddle[nX][1], cAlias, .F., .F. )
                    // Obtem a estrutura da tabela para eviar junto da função TCAlter
                    aOldStr := ( cAlias )->( DBStruct() )
                    ( cAlias )->( DBCloseArea() )

                    // Obtem a nova estrutura
                    aStruct := U_AVTBLSTR( aMiddle[nX][1] /* cTable */ )

                    if len( aStruct ) > 0

                        // Chama função padrão do TopConnect para alterar a tabela intermediária
                        lSuccess := TCAlter( aMiddle[nX][1], aOldStr, aStruct, @nTopErr )
                        if ! lSuccess
                            U_HLP( 'Falha na Alteração',;
                                    'Falha durante a tentativa de alterar estrutura da tabela '+ aMiddle[nX][1],;
                                    TcSQLError() )
                        else
                            if len( aIndex ) > 0
                                for nIndex := 1 to len( aIndex )
                                    if ! TCCanOpen( aMiddle[nX][1], aIndex[nIndex][1] )
                                        
                                        cAlias := GetNextAlias()
                                        DBUseArea( .F., 'TOPCONN', aMiddle[nX][1], cAlias, .F., .F. )
                                        ( cAlias )->( DBCreateIndex( aIndex[nIndex][1], aIndex[nIndex][2], aIndex[nIndex][3] ) )
                                        ( cAlias )->( DBClearIndex() )
                                        ( cAlias )->( DBSetIndex( aIndex[nIndex][1] ) )
                                        ( cAlias )->( DBCloseArea() )
                                        lSuccess := TCCanOpen( aMiddle[nX][1], aIndex[nIndex][1] )

                                    endif
                                    if ! lSuccess
                                        U_HLP( 'Falha na Criação do Índice',;
                                                'O índice '+ aIndex[nIndex][1] +' da tabela ' + aMiddle[nX][1] +' não pode ser criado!' )
                                        Exit
                                    endif
                                next nIndex
                            endif
                            if lSuccess
                                aMiddle[nX][3] := STATUS_OK
                                oBrowse:GoTo( nX, .T. /* lRefresh */ )
                                oBrowse:UpdateBrowse( .T. /* lResetSeed */)
                            endif
                        endif
                    else
                        lSuccess := .F.
                        U_HLP( 'Sem Estrutura',;
                                'A tabela '+ aMiddle[nX][1] +' não possui estrutura definida!',;
                                'Defina uma estrutura por meio da função AVGETSTR e tente novamente.' )
                    endif

                elseif aMiddle[nX][3] == STATUS_NOT     // Tabelas que não estão criadas
                    
                    // Obtem estrutura da tabela
                    aStruct := U_AVTBLSTR( aMiddle[nX][1] /* cTable */ )
                    
                    // Verifica se a tabela tem estrutura
                    if len( aStruct ) > 0
                        
                        // Função do DbAccess para criar a tabela de acordo com a estrutura enviada por parâmetro
                        DBCreate( aMiddle[nX][1], aStruct, 'TOPCONN' )
                        
                        // Tenta abrir a tabela depois de criada
                        lSuccess := TcCanOpen( aMiddle[nX][1] )
                        if ! lSuccess
                            U_HLP( aMiddle[nX][1],;
                                    'A tabela '+ aMiddle[nX][1] +' não pode ser criada!',;
                                    'Falha durante processo de criação da tabela' )
                        else
                            if len( aIndex ) > 0
                                for nIndex := 1 to len( aIndex )
                                    if ! TCCanOpen( aMiddle[nX][1], aIndex[nIndex][1] )
                                        
                                        cAlias := GetNextAlias()
                                        DBUseArea( .F., 'TOPCONN', aMiddle[nX][1], cAlias, .F., .F. )
                                        ( cAlias )->( DBCreateIndex( aIndex[nIndex][1], aIndex[nIndex][2], aIndex[nIndex][3] ) )
                                        ( cAlias )->( DBClearIndex() )
                                        ( cAlias )->( DBSetIndex( aIndex[nIndex][1] ) )
                                        ( cAlias )->( DBCloseArea() )
                                        lSuccess := TCCanOpen( aMiddle[nX][1], aIndex[nIndex][1] )

                                    endif
                                    if ! lSuccess
                                        U_HLP( 'Falha na Criação do Índice',;
                                                'O índice '+ aIndex[nIndex][1] +' da tabela ' + aMiddle[nX][1] +' não pode ser criado!' )
                                        Exit
                                    endif
                                next nIndex
                            endif
                            if lSuccess
                                aMiddle[nX][3] := STATUS_OK
                                oBrowse:GoTo( nX, .T. /* lRefresh */ )
                                oBrowse:UpdateBrowse( .T. /* lResetSeed */)
                            endif
                        endif
                    else
                        lSuccess := .F.
                        U_HLP( 'Sem Estrutura',;
                                'A tabela '+ aMiddle[nX][1] +' não possui estrutura definida!',;
                                'Defina uma estrutura por meio da função AVGETSTR e tente novamente.' )
                    endif

                endif
                if ! lSuccess
                    Exit
                endif
            next nX
        endif

    elseif nAtual == 3      // Campos customizados
        
        // Verifica se os campos customizados existem
        if STATUS_UPD $ oFieldNuc:CCAPTION 
            MsAguarde( {|| lCreated := createFields( 'nucleo' ) }, 'Aguarde!','[ Núcleos ] Customizando campos...' )
            if lCreated
                oFieldNuc:SetText( getText( 'nucleo', nAtual ) )
                oFieldNuc:CtrlRefresh()
                lSuccess := STATUS_OK $ oFieldNuc:CCAPTION 
            else
                lSuccess := .F.
            endif
        endif

        if lSuccess .and. STATUS_UPD $ oFieldUsr:CCAPTION
            MsAguarde( {|| lCreated := createFields( 'funcaoxnucleo' ) }, 'Aguarde!', '[ Usuários x Núcleo ] Customizando campos...' )
            if lCreated 
                oFieldUsr:SetText( getText( 'funcaoxnucleo', nAtual ) )
                oFieldUsr:CtrlRefresh()
                lSuccess := STATUS_OK $ oFieldUsr:CCAPTION
            else    
                lSuccess := .F.
            endif
        endif

        if lSuccess .and. STATUS_UPD $ oFieldPrd:CCAPTION
            MsAguarde( {|| lCreated := createFields( 'produto' ) }, 'Aguarde!', '[ Produto ] Customizando campos...' )
            if lCreated
                oFieldPrd:SetText( getText( 'produto', nAtual ) )
                oFieldPrd:CtrlRefresh()
                lSuccess := STATUS_OK $ oFieldPrd:CCAPTION
            else
                lSuccess := .F.
            endif
        endif

        if lSuccess .and. STATUS_UPD $ oFieldGrp:CCAPTION
            MsAguarde( {|| lCreated := createFields( 'grupo' ) }, 'Aguarde!', '[ Grupo ] Customizando campos...' )
            if lCreated
                oFieldGrp:SetText( getText( 'grupo', nAtual ) )
                oFieldGrp:CtrlRefresh()
                lSuccess := STATUS_OK $ oFieldGrp:CCAPTION
            else
                lSuccess := .F.
            endif
        endif

        if lSuccess .and. STATUS_UPD $ oFieldLot:CCAPTION
            MsAguarde( {|| lCreated := createFields( 'lote' ) }, 'Aguarde!', '[ Lote ] Customizando campos...' )
            if lCreated
                oFieldLot:SetText( getText( 'lote', nAtual ) )
                oFieldLot:CtrlRefresh()
                lSuccess := STATUS_OK $ oFieldLot:CCAPTION
            else
                lSuccess := .F.
            endif
        endif

        if lSuccess .and. STATUS_UPD $ oFieldFun:CCAPTION
            MsAguarde( {|| lCreated := createFields( 'funcao' ) }, 'Aguarde!', '[ Função ] Customizando campos...' )
            if lCreated
                oFieldFun:SetText( getText( 'funcao', nAtual ) )
                oFieldFun:CtrlRefresh()
                lSuccess := STATUS_OK $ oFieldFun:CCAPTION
            else
                lSuccess := .F.
            endif
        endif

        if lSuccess .and. STATUS_UPD $ oFieldIte:CCAPTION
            MsAguarde( {|| lCreated := createFields( 'subitens' ) }, 'Aguarde!', '[ SubItens ] Customizando campos...' )
            if lCreated
                oFieldIte:SetText( getText( 'subitens', nAtual ) )
                oFieldIte:CtrlRefresh()
                lSuccess := STATUS_OK $ oFieldIte:CCAPTION
            else
                lSuccess := .F.
            endif
        endif

        if lSuccess .and. STATUS_UPD $ oFieldOco:CCAPTION
            MsAguarde( {|| lCreated := createFields( 'ocorrencias' ) }, 'Aguarde!', '[ Ocorrências ] Customizando campos...' )
            if lCreated
                oFieldOco:SetText( getText( 'ocorrencias', nAtual ) )
                oFieldOco:CtrlRefresh()
                lSuccess := STATUS_OK $ oFieldOco:CCAPTION
            else
                lSuccess := .F.
            endif
        endif

        // Campos customizados da coleta
        if lSuccess .and. STATUS_UPD $ oFieldCol:CCAPTION
            MsAguarde( {|| lCreated := createFields( 'coletaitens' ) }, 'Aguarde!', '[ Coletas ] Customizando campos...' )
            if lCreated
                oFieldCol:SetText( getText( 'coletaitens', nAtual ) )
                oFieldCol:CtrlRefresh()
                lSuccess := STATUS_OK $ oFieldCol:CCAPTION
            else
                lSuccess := .F.
            endif
        endif

        if lSuccess .and. STATUS_UPD $ oFieldSol:CCAPTION
            MsAguarde( {|| lCreated := createFields( 'solicitacoes' ) }, 'Aguarde!', '[ Solicitações ] Customizando campos...' )
            if lCreated
                oFieldSol:SetText( getText( 'solicitacoes', nAtual ) )
                oFieldSol:CtrlRefresh()
                lSuccess := STATUS_OK $ oFieldSol:CCAPTION
            else
                lSuccess := .F.
            endif
        endif

        if lSuccess .and. STATUS_UPD $ oFieldMan:CCAPTION
            MsAguarde( {|| lCreated := createFields( 'manutencao' ) }, 'Aguarde!', '[ Manutenções ] Customizando campos...' )
            if lCreated
                oFieldMan:SetText( getText( 'manutencao', nAtual ) )
                oFieldMan:CtrlRefresh()
                lSuccess := STATUS_OK $ oFieldMan:CCAPTION
            else
                lSuccess := .F.
            endif
        endif

        if lSuccess .and. STATUS_UPD $ oFieldReq:CCAPTION
            MsAguarde( {|| lCreated := createFields( 'pedidoitem' ) }, 'Aguarde!', '[ Requisições ao Armazém ] Customizando campos...' )
            if lCreated
                oFieldReq:SetText( getText( 'pedidoitem', nAtual ) )
                oFieldReq:CtrlRefresh()
                lSuccess := STATUS_OK $ oFieldReq:CCAPTION
            else
                lSuccess := .F.
            endif
        endif   

    elseif nAtual == 4      // Merge de dados

        if STATUS_UPD $ oSayNuc:CCAPTION
            MsAguarde( {|| lDone := updNucleo() }, 'Aguarde!', '[ Núcleo ] Sincronizando dados...' )
            if lDone
                oSayNuc:SetText( getText( 'nucleo', nAtual ) )
                oSayNuc:CtrlRefresh()
                lSuccess := STATUS_OK $ oSayNuc:CCAPTION
            else
                lSuccess := .F.
            endif
        endif

        if STATUS_UPD $ oSayUsr:CCAPTION
            MsAguarde( {|| lDone := updUsrNuc() }, 'Aguarde!', '[ Usuários x Núcleo ] Sincronizando dados...' )
            if lDone
                oSayUsr:SetText( getText( 'funcaoxnucleo', nAtual ) )
                oSayUsr:CtrlRefresh()
                lSuccess := STATUS_OK $ oSayUsr:CCAPTION
            else
                lSuccess := .F.
            endif
        endif

        if lSuccess .and. STATUS_UPD $ oSayPrd:CCAPTION
            MsAguarde( {|| lDone := updProduto() }, 'Aguarde!', '[ Produto ] Sincronizando dados...' )
            if lDone
                oSayPrd:SetText( getText( 'produto', nAtual ) )
                oSayPrd:CtrlRefresh()
                lSuccess := STATUS_OK $ oSayPrd:CCAPTION
            else
                lSuccess := .F.
            endif
        endif

        if lSuccess .and. STATUS_UPD $ oSayGrp:CCAPTION
            MsAguarde( {|| lDone := updGrupo() }, 'Aguarde!', '[ Grupo ] Sincronizando dados...' )
            if lDone
                oSayGrp:SetText( getText( 'grupo', nAtual ) )
                oSayGrp:CtrlRefresh()
                lSuccess := STATUS_OK $ oSayGrp:CCAPTION
            else
                lSuccess := .F.
            endif
        endif

        if lSuccess .and. STATUS_UPD $ oSayLot:CCAPTION
            MsAguarde( {|| lDone := updLote() }, 'Aguarde!', '[ Lote ] Sincronizando dados...' )
            if lDone        
                oSayLot:SetText( getText( 'lote', nAtual ) )
                oSayLot:CtrlRefresh()
                lSuccess := STATUS_OK $ oSayLot:CCAPTION
            else
                lSuccess := .F.
            endif
        endif

        if lSuccess .and. STATUS_UPD $ oSayFun:CCAPTION
            MsAguarde( {|| lDone := updFuncao() }, 'Aguarde!', '[ Função ] Sincronizando dados...' )
            if lDone
                oSayFun:SetText( getText( 'funcao', nAtual ) )
                oSayFun:CtrlRefresh()
                lSuccess := STATUS_OK $ oSayFun:CCAPTION
            else
                lSuccess := .F.
            endif
        endif

        if lSuccess .and. STATUS_UPD $ oSayIte:CCAPTION
            MsAguarde( {|| lDone := updSubItens() }, 'Aguarde!', '[ SubItens ] Sincronizando dados...' )
            if lDone
                oSayIte:SetText( getText( 'subitens', nAtual ) )
                oSayIte:CtrlRefresh()
                lSuccess := STATUS_OK $ oSayIte:CCAPTION
            else
                lSuccess := .F.
            endif
        endif

        if lSuccess .and. STATUS_UPD $ oSayOco:CCAPTION
            MsAguarde( {|| lDone := updOcorrencias() }, 'Aguarde!', '[ Ocorrências ] Sincronizando dados...' )
            if lDone
                oSayOco:SetText( getText( 'ocorrencias', nAtual ) )
                oSayOco:CtrlRefresh()
                lSuccess := STATUS_OK $ oSayOco:CCAPTION
            else
                lSuccess := .F.
            endif
        endif

    elseif nAtual == 5      // Configurações do JOB

        // Se o parâmetro não existir, força criação do mesmo na SX6
        if ! GetMv( 'MV_X_AVJDT', .T. /* lCheck */ )
            DBSelectArea( cSX6 )
            ( cSX6 )->( DBSetOrder( 1 ) )
            RecLock( cSX6, .T. )
            ( cSX6 )->( FieldPut( FieldPos( 'X6_VAR'    ), 'MV_X_AVJDT' ) )
            ( cSX6 )->( FieldPut( FieldPos( 'X6_TIPO'   ), 'C' ) )
            ( cSX6 )->( FieldPut( FieldPos( 'X6_DESCRIC'), 'Data e hora ultima execução do JOB' ) )
            ( cSX6 )->( FieldPut( FieldPos( 'X6_DSCSPA' ), 'Fecha y hora de la última ejecución' ) )
            ( cSX6 )->( FieldPut( FieldPos( 'X6_DSCENG' ), 'Date and time of the last job execution' ) )
            ( cSX6 )->( FieldPut( FieldPos( 'X6_CONTEUD'), "" ) )
            ( cSX6 )->( FieldPut( FieldPos( 'X6_CONTSPA'), "" ) )
            ( cSX6 )->( FieldPut( FieldPos( 'X6_CONTENG'), "" ) )
            ( cSX6 )->( MsUnlock() )
        endif

    endif

return lSuccess

/*/{Protheus.doc} updOcorrencias
Função para sincronização inicial do cadastro de ocorrências
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 04/10/2023
@return logical, lSuccess
/*/
static function updOcorrencias()
    
    local aArea    := getArea()
    local cQuery   := ""  as character
    local aLine    := {}  as array
    local nX       := 0   as numeric
    local aData    := {}  as array
    local nMaxID   := U_AVLASTID( 'ID', 0, 'ocorrencias' )
    local xAux     := Nil
    local lSuccess := .T. as logical
    local aRelOcor := {} as array
    local aFields  := {} as array
    local oResult  as object

    DBSelectArea( 'SU9' )
    SU9->( DBSetOrder( 1 ) )

    // Retorna vetor auxiliar para leitura dos dados de ocorrências
    aRelOcor := U_AVGETREL( 'ocorrencias' )
    aEval( aRelOcor, {|x|  aAdd( aFields, x[1] )  } )

    // Query para leitura das ocorrências
    cQuery := U_AVQRYDEF( 'ocorrencias' )
    DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), 'SU9TMP', .F., .T. )
    if ! SU9TMP->( EOF() )
        
        while ! SU9TMP->( EOF() )
            
            // Posiciona no registro físico da tabela
            SU9->( DBGoTo( SU9TMP->RECSU9 ) )
            
            for nX := 1 to len( aRelOcor )
                xAux := Nil
                xAux := &( 'SU9->('+ iif( !Empty( aRelOcor[nX][3] ), aRelOcor[nX][3], aRelOcor[nX][2] ) +')' )
                if aRelOcor[nX][1] == 'ID' .and. xAux == 0
                    nMaxID++
                    xAux := nMaxID
                endif
                aAdd( aLine, xAux )
            next nX
            aAdd( aData, aClone( aLine ) )
            aLine := {}

            SU9TMP->( DBSkip() )
        end
        SU9TMP->( DBCloseArea() )

        if len( aData ) > 0
            // Sincroniza os dados com o supabase
            oResult := U_SUPCLIENT( U_AVGETDB(), U_AVGETKEY(), 'POST', 'ocorrencias', aFields, /* cWhere */, aData )
            if ValType( oResult ) == 'J' .and. len( oResult ) > 0
                DBSelectArea( 'SU9' )
                SU9->( DbSetOrder( 1 ) )
                
                for nX := 1 to len( oResult )
                    
                    // Posiciona no registro do ERP
                    SU9->( DBGoTo( oResult[nX]['IDERP'] ) )

                    // Armazena o ID do registro no App
                    RecLock('SU9', .F. )
                    SU9->U9_X_IDAP := oResult[nX]['ID']
                    SU9->( MsUnlock() )

                next nX
            else
                lSuccess := .F.
            endif

            FreeObj( oResult )
            oResult := Nil

        endif
    endif

    restArea( aArea )
return lSuccess

/*/{Protheus.doc} updSubItens
Função criada para sincronizar os subitens no momento da execução do compatibilizador
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 29/09/2023
@return logical, lSuccess
/*/
static function updSubItens()
    
    local lSuccess := .T. as logical
    local aFields  := {} as array
    local aRelIte  := {} as array
    local aLine    := {} as array
    local aData    := {} as array
    local xAux     := Nil
    local nX       := 0 as numeric
    local nMaxID   := 0 as numeric
    local oResult  as object

    // Identifica o último ID usado para a tabela
    nMaxID  := U_AVLASTID( 'subitens', 0, 'ID' )

    // Captura o relacionamento entre a tabela do Protheus e a tabela do supabase
    aRelIte := U_AVGETREL( 'subitens' )
    aEval( aRelIte, {|x| aAdd( aFields, x[1] ) } )
    
    // Query para leitura dos dados de subitens da tabela do Protheus
    cQuery := U_AVQRYDEF( 'subitens' )
    DBUSeArea( .T., 'TOPCONN', TcGenQry(,,cQuery), 'ZH1TMP', .F., .T. )
    if ! ZH1TMP->( EOF() )
        
        DBSelectArea( 'ZH1' )
        ZH1->( DBSetOrder( 1 ) )

        while ! ZH1TMP->( EOF() )
        
            // Posiciona no registro físico da tabela 
            ZH1->( DBGoTo( ZH1TMP->RECZH1 ) )
            for nX := 1 to len( aRelIte )
                xAux := Nil
                xAux := &( 'ZH1->('+ iif( !Empty( aRelIte[nX][3] ), aRelIte[nX][3], aRelIte[nX][2] ) +')' )
                if aRelIte[nX][1] == 'ID' .and. xAux == 0
                    nMaxID++
                    xAux := nMaxID
                endif
                aAdd( aLine, xAux )
            next nX
            aAdd( aData, aClone( aLine ) )
            aLine := {}

            ZH1TMP->( DBSkip() )
        end
    endif
    ZH1TMP->( DBCloseArea() )

    if len( aData ) > 0
        
        // Sincroniza os dados de subitens com o supabase
        oResult := U_SUPCLIENT( U_AVGETDB(), U_AVGETKEY(), 'POST', 'subitens', aFields, /* cWhere */, aData )
        if ValType( oResult ) == 'J' .and. len( oResult ) > 0
            
            DBSelectArea( 'ZH1' )
            ZH1->( DBSetOrder( 1 ) )

            for nX := 1 to len( oResult )
                
                // Posiciona no registro físico da tabela
                ZH1->( DBGoTo( oResult[nX]['IDERP'] ) )

                // Guarda o registro do supabase no Protheus
                RecLock( 'ZH1', .F. )
                ZH1->ZH1_X_IDAP := oResult[nX]['ID']
                ZH1->( MsUnlock() )

            next nX

        else
            lSuccess := .F.
        endif
    endif

return lSuccess

/*/{Protheus.doc} updGrupo
Função para sincronizar dados de grupo com o supabase
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 29/09/2023
@return logical, lSuccess
/*/
static function updGrupo()

    local lSuccess := .T. as logical
    local cQuery   := "" as character
    local xAux     := Nil
    local aLine    := {} as array
    local aData    := {} as array
    local aFields  := {} as array
    local aRelGrp  := {} as array
    local nX       := 0 as numeric
    local oResult  as object

    aRelGrp := U_AVGETREL( 'grupo' )
    aEval( aRelGrp, {|x| iif( !Empty( x[1] ), aAdd( aFields, x[1] ), Nil ) } )

    cQuery := U_AVQRYDEF( 'grupo' )

    DBUseArea( .T. /* lNew */, 'TOPCONN' /* cDriver */, TcGenQry(,,cQuery) /* cQuery */, 'SBMTMP' /* cAlias */, .F. /* lShared */, .T. /* lReadOnly */ )
    if ! SBMTMP->( EOF() )
        
        DBSelectArea( 'SBM' )
        SBM->( DBSetOrder( 1 ) )

        while ! SBMTMP->( EOF() )

            // Posiciona no registro físico
            SBM->( DBGoTo( SBMTMP->RECSBM ) )
            for nX := 1 to len( aRelGrp )
                xAux := Nil
                xAux := &( 'SBM->('+ iif( !Empty( aRelGrp[nX][3] ), aRelGrp[nX][3], aRelGrp[nX][2] ) +')' )
                aAdd( aLine, xAux )
            next nX
            aAdd( aData, aClone( aLine ) )
            aLine := {}

            SBMTMP->( DBSkip() )
        end

        if len( aData ) > 0

            // Sincroniza os dados de grupos com o supabase
            oResult := U_SUPCLIENT( U_AVGETDB(), U_AVGETKEY(), 'POST', 'grupo', aFields, /* cWhere */,aData )
            if ValType( oResult ) == 'J' .and. len( oResult ) > 0
                
                DBSelectArea( 'SBM' )
                SBM->( DBSetOrder( 1 ) )

                for nX := 1 to len( oResult )

                    // Se o IDERP vier vazio, significa que o registro do center não está ligado a um registro do ERP, logo, o mesmo deve ser ignorado
                    if oResult[nX]['IDERP'] > 0
                        
                        // Posiciona no registro do ERP
                        SBM->( DBGoTo( oResult[nX]['IDERP'] ) )
                        
                        RecLock( 'SBM', .F. )
                        SBM->BM_X_IDAP := oResult[nX]['ID']
                        SBM->( MsUnlock() )

                    endif   
                next nX
            else
                if MsgYesNo( 'Gostaria de visualizar a estrutura dos dados que geraram a inconsistência?', 'Visualizar dados?' )
                    U_HLP( 'DADOS',;
                            varInfo('Campos', aFields ),;
                            varInfo('Dados[1]', aData[1] ) )
                endif
                lSuccess := .F.
            endif

            FreeObj( oResult )
            oResult := Nil

        endif

    endif
    SBMTMP->( DBCloseArea() )

return lSuccess

/*/{Protheus.doc} updFuncao
Sincroniza cadastro de funções com o supabase
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 28/09/2023
@return logical, lSuccess 
/*/
static function updFuncao()
    
    local lSuccess := .T. as logical
    local cQuery   := "" as character
    local nX       := 0 as numeric
    local aRelFun  := {} as array
    local aFields  := {} as array
    local aLine    := {} as array
    local aData    := {} as array
    local xAux     := Nil 
    
    aRelFun := U_AVGETREL( 'funcao' )
    aEval( aRelFun, {|x| iif( ! Empty( x[1] ), aAdd( aFields, x[1] ), Nil ) } ) 

    cQuery := "SELECT R_E_C_N_O_ RECSRJ FROM "+ RetSqlName( 'SRJ' ) +" WHERE RJ_X_IDAP = '"+ Space( TAMSX3('RJ_X_IDAP')[1] ) +"' AND D_E_L_E_T_ = ' ' "
    DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), 'SRJTMP', .F., .T. )

    if ! SRJTMP->( EOF() )

        DBSelectArea( 'SRJ' )
        SRJ->( DBSetOrder( 1 ) )
        while ! SRJTMP->( EOF() )
            
            // Posiciona no registro do cadastro de funções
            SRJ->( DBGoTo( SRJTMP->RECSRJ ) )

            for nX := 1 to len( aRelFun )
                xAux := nil
                xAux := &( 'SRJ->('+ iif( ! Empty( aRelFun[nX][3] ), aRelFun[nX][3], aRelFun[nX][2] ) +')' )
                aAdd( aLine, xAux )
            next nX
            aAdd( aData, aClone( aLine ) )
            aLine := {}
            
            SRJTMP->( DBSkip() )
        end
    endif
    SRJTMP->( DBCloseArea() )

    if len( aData ) > 0

        // Sincroniza os dados do ERP com supabase
        oResult := U_SUPCLIENT( U_AVGETDB(), U_AVGETKEY(), 'POST', 'funcao', aFields,,aData )
        if ValType( oResult ) == 'J' .and. len( oResult ) > 0
            DBSelectArea( 'SRJ' )
            SRJ->( DBSetOrder( 1 ) )
            for nX := 1 to len( oResult )

                if oResult[nX]['IDERP'] > 0
                    
                    // Posiciona no registro físico do ERP
                    SRJ->( DBGoTo( oResult[nX]['IDERP'] ) )

                    // Atualiza o registro do protheus com o ID do registro do supabase
                    RecLock( 'SRJ', .F. )
                    SRJ->RJ_X_IDAP := oResult[nX]['ID']
                    SRJ->( MsUnlock() )

                endif

            next nX
        else
            U_HLP( 'FUNCAO',;
                    'Não foi possível sincronizar o cadastro de funções',;
                    'Verifique no logo do console da aplicação ou verifique com a equipe responsável pelo processo de integração' )
            lSuccess := .F.
        endif
    endif

return lSuccess

/*/{Protheus.doc} updUsrNuc
Função para executar a sincronização de usuários x núcleo durante o processo de compatibilização da base
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 26/09/2023
@return logical, lSuccess
/*/
static function updUsrNuc()
    
    local lSuccess := .T. as logical
    local aFields  := {}  as array
    local aRelUsr  := {}  as array
    local aData    := {}  as array
    local oResult         as object
    local nX       := 0   as numeric
    local aLine    := {}  as array
    local xAux     := nil
    local nMaxID   := U_AVLASTID( 'ID' , 0, 'funcaoxnucleo' )
    local cQuery   := ""  as character

    aRelUsr := U_AVGETREL( 'funcaoxnucleo' )
    aEval( aRelUsr, {|x| iif( !Empty( x[1] ), aAdd( aFields, x[1] ), Nil ) } )

    DBSelectArea( 'ZHV' )
    ZHV->( DBSetOrder( 1 ) )

    // Query para leitura dos dados no banco
    cQuery := "SELECT R_E_C_N_O_ RECZHV FROM "+ RetSqlName( 'ZHV' ) +" WHERE ZHV_X_IDAP = 0 AND D_E_L_E_T_ = ' ' "
    DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), 'ZHVTMP', .F., .T. )
    if ! ZHVTMP->( EOF() )
        
        while ! ZHVTMP->( EOF() )
            // Posiciona no registro físico
            ZHV->( DBGoTo( ZHVTMP->RECZHV ) )

            for nX := 1 to len( aRelUsr )
                xAux := Nil
                xAux := &( "ZHV->("+ iif( !Empty( aRelUsr[nX][3] ), aRelUsr[nX][3], aRelUsr[nX][2] ) +")" )
                if aRelUsr[nX][1] == 'ID' .and. xAux == 0
                    nMaxID++
                    xAux := nMaxID
                endif
                aAdd( aLine, xAux )
            next nX
            aAdd( aData, aClone( aLine ) )
            aLine := {}

            ZHVTMP->( DBSkip() )
        end
    endif
    ZHVTMP->( DBCloseArea() )

    if len( aData ) > 0

        // Envia os dados para o supabase
        oResult := U_SUPCLIENT( U_AVGETDB(), U_AVGETKEY(), 'POST', 'funcaoxnucleo', aFields, , aData )
        if ValType( oResult ) == 'J' .and. len( oResult ) > 0
            
            DBSelectArea( 'ZHV' )
            ZHV->( DBSetOrder( 1 ) )

            for nX := 1 to len( oResult )

                if oResult[nX]['IDERP'] > 0
                    
                    // Manda posicionar no registro do ERP
                    ZHV->( DBGoTo( oResult[nX]['IDERP'] ) )

                    RecLock( 'ZHV', .F. )
                    ZHV->ZHV_X_IDAP := oResult[nX]['ID']
                    ZHV->( MsUnlock() )

                endif

            next nX
        else
            lSuccess := .F.
        endif
        FreeObj( oResult )
        oResult := Nil
    endif

return lSuccess

/*/{Protheus.doc} updProduto
Função para carga inicial dos dados de produto
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 19/09/2023
@return logical, lSuccess
/*/
static function updProduto()
    
    local lSuccess := .T. as logical
    local oResult  as object
    local cQuery   := "" as character
    local aDados   := {} as array
    local aLin     := {} as array
    local nX       := 0 as numeric
    local xAux     := Nil

    // Query para leitura dos produtos aptos a serem integrados com o app
    cQuery := "SELECT R_E_C_N_O_ RECSB1 FROM "+ RetSqlName( 'SB1' ) +" WHERE B1_X_RANCH = 'S' AND D_E_L_E_T_ = ' ' "
    DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), 'SB1TMP', .F., .T. )
    if ! SB1TMP->( EOF() )
        
        DBSelectArea( 'SB1' )
        SB1->( DBSetOrder( 1 ) )
        
        while ! SB1TMP->( EOF() )
            SB1->( DBGoTo( SB1TMP->RECSB1 ) )
            for nX := 1 to len( aRelPrd )
                xAux := &( 'SB1->('+ iif( !Empty( aRelPrd[nX][3] ), aRelPrd[nX][3], aRelPrd[nX][2] ) +')')
                aAdd( aLin, xAux )
            next nX
            aAdd( aDados, aClone( aLin ) )
            aLin := {}
            SB1TMP->( DBSkip() )
        end
    endif
    SB1TMP->( DBCloseArea() )

    if len( aDados ) > 0
        // Conecta ao supabase para sincronizar produtos
        oResult := U_SUPCLIENT( U_AVGETDB(), U_AVGETKEY(), 'POST', 'produto', aFldPrd,/* cWHere */,aDados )
        if ValType( oResult ) == 'J' .and. len( oResult ) > 0
            
            DBSelectArea( 'SB1' )
            SB1->( DBSetOrder( 1 ) )

            for nX := 1 to len( oResult )
                // Obtem o retorno e grava nos registros sincronizados a data e hora do sincronismo
                if SB1->( DBSeek( FWxFilial( 'SB1' ) + PADR( oResult[nX]['ID'], TAMSX3('B1_COD')[1], ' ' ) ) )
                    RecLock( 'SB1', .F. )
                    SB1->B1_X_DTAP := FWTimeStamp(2)
                    SB1->( MsUnlock() )
                endif
            next nX
        else
            U_HLP( 'PRODUTO', 'Falha durante o processo de sincronização de produtos',;
                'Verifique o motivo junto da equipe responsável pela integração entre o ERP e o APP' )
            lSuccess := .F.
        endif

        FreeObj( oResult )
        oResult := Nil

    endif

return lSuccess

/*/{Protheus.doc} updLote
Função responsável pelo processo de atualização de lotes do ERP na base do center
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 26/09/2023
@return logical, lSuccess
/*/
static function updLote()
    
    local lSuccess := .T. as logical
    local aFields  := {} as array
    local aRelLot  := {} as array
    local aData    := {} as array
    local xAux     := Nil
    local aLine    := {} as array
    local oResult  as object
    local nX       := 0 as numeric
    local cQuery   := "" as character
    local nMaxID   := U_AVLASTID( 'R_E_C_N_O_'/* cField */, 0, 'lote' )
    
    aRelLot := U_AVGETREL( 'lote' )
    // Define o vetor de campos que serão enviados para montagem do json
    aEval( aRelLot, {|x| iif( !Empty( x[1] ), aAdd( aFields, x[1] ), Nil ) } )
    
    DBSelectArea( 'ZH0' )
    ZH0->( DBSetOrder( 1 ) )

    // Query para leitura dos dados do ERP
    cQuery := "SELECT R_E_C_N_O_ RECZH0 FROM "+ RetSqlName( 'ZH0' ) +" WHERE ZH0_X_IDAP = 0 AND D_E_L_E_T_ = ' ' "
    DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), 'ZH0TMP', .F., .T. )
    if ! ZH0TMP->( EOF() )
        while ! ZH0TMP->( EOF() )
            
            // Manda o DBAccess posicionar no registro
            ZH0->( DBGoTo( ZH0TMP->RECZH0 ) )
            for nX := 1 to len( aRelLot )
                xAux := Nil
                xAux := &( 'ZH0->('+ iif( !Empty( aRelLot[nX][3] ), aRelLot[nX][3], aRelLot[nX][2] ) +')' )
                // Quando o registro ainda não foi enviado ao supabase, atribui um ID
                if aRelLot[nX][1] == 'R_E_C_N_O_' .and. xAux == 0
                    nMaxID++
                    xAux := nMaxID
                endif
                aAdd( aLine, xAux )
            next nX
            aAdd( aData, aClone( aLine ) )
            aLine := {}

            ZH0TMP->( DBSkip() )
        end
    endif
    ZH0TMP->( DBCloseArea() )

    if len( aData ) > 0
        // Consome o webservice para enviar os dados do ERP para sincronização
        oResult := U_SUPCLIENT( U_AVGETDB(), U_AVGETKEY(), 'POST', 'lote', aFields,,aData )
        if ValType( oResult ) == 'J' .and. len( oResult ) > 0
            DBSelectArea( 'ZH0' )
            for nX := 1 to len( oResult )
                
                // Posiciona no registro do ERP
                if oResult[nX]['IDERP'] > 0
                    // Campo que armazena o Recno do ERP na tabela do supabase
                    ZH0->( DBGoTo( oResult[nX]['IDERP'] ) )
                    
                    RecLock( 'ZH0', .F. )
                    ZH0->ZH0_X_IDAP := oResult[nX]['R_E_C_N_O_']
                    ZH0->( MsUnlock() )
                endif

            next nX
        else
            lSuccess := .F.
            U_HLP( 'LOTE',;
                    'Falha durante sincronização dos dados de lote com o aplicativo Avícola',;
                    'Não foi possível identificar informações quanto ao retorno do processo de sincronização.' )
        endif
    endif

return lSuccess

/*/{Protheus.doc} updNucleo
Função responsável pelo merge dos dados de cadastro de núcleo entre o Protheus e o App Avicola
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 15/09/2023
@return logical, lSuccess
/*/
static function updNucleo()
    
    local lSuccess := .T. as logical
    local oResult  as object
    local nX       := 0  as numeric
    local aDados   := {} as array
    Local xAux     := Nil
    local aLin     := {} as array
    Local nMaxID   := 0 as numeric
    Local cQuery   := "" as character

    // Ultimo ID utilizado
    nMaxID := U_AVLASTID( 'ID', 0, 'nucleo' )    

    // Gera uma carga de remessa de dados do Protheus para o app como forma de atualização dos dados entre as plataformas
    // Importante: quem comanda as alterações será sempre o ERP no caso da tabela de núcleos.
    cQuery := "SELECT R_E_C_N_O_ RECZH6 FROM "+ RetSQLName( 'ZH6' ) +" WHERE ZH6_X_IDAP = 0 AND D_E_L_E_T_ = ' ' "
    DBUseArea( .T., "TOPCONN", TcGenQry(,,cQuery), "ZH6TMP", .F., .T. )
    
    aDados := {}
    DBSelectArea( 'ZH6' )
    While ! ZH6TMP->( EOF() )
    
        ZH6->( DBGoTo( ZH6TMP->RECZH6 ) )
        for nX := 1 to len( aRelNuc )
            xAux := &( 'ZH6->('+ iif( !Empty( aRelNuc[nX][3] ), aRelNuc[nX][3], aRelNuc[nX][2] ) +')' )
            // Posiciona no recno corrente
            ZH6->( DBGoTo( ZH6TMP->RECZH6 ) )
            // Quando for o campo ID e o registro não tiver ligação com a tabela do supabase, incrementa 1 no máximo ID que existe e atribui ao registro
            if AllTrim( aRelNuc[nX][1] ) == 'ID' .and. xAux == 0
                nMaxID++
                xAux := nMaxID
            endif
            aAdd( aLin, xAux )
        next nX
        aAdd( aDados, aClone( aLin ) )
        aLin := {}

        ZH6TMP->( DBSkip() )
    end
    ZH6TMP->( DBCloseArea() )

    if len( aDados ) > 0
        
        // Envia dados para o supabase
        oResult := U_SUPCLIENT( U_AVGETDB(), U_AVGETKEY(), 'POST', 'nucleo', aFldNuc,,aDados )
        if ValType( oResult ) == 'J' .and. len( oResult ) > 0
            
            DBSelectArea( 'ZH6' )
            ZH6->( DBSetOrder( 1 ) )        // ZH6_FILIAL + ZH6_CODNUC

            for nX := 1 to len( oResult )
                if oResult[nX]['IDERP'] > 0
                    
                    // Posiciona no registro do ERP
                    ZH6->( DBGoTo( oResult[nX]['IDERP'] ) )
                    
                    RecLock( 'ZH6', .F. )
                    ZH6->ZH6_X_IDAP := oResult[nX]['ID']
                    ZH6->( MsUnlock() )

                endif
                
            next nX
        else
            lSuccess := .F.
        endif

        FreeObj( oResult )
        oResult := Nil

    endif
return lSuccess

/*/{Protheus.doc} createFields
Função para criar campos customizados nas tabelas já existentes
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 15/09/2023
@param cTable, character, nome físico da tabela do supabase
@return logical, lSuccess
/*/
static function createFields( cTable )
    
    local lSuccess := .T. as logical
    local aSX3     := {} as array
    local cSeqZH6  := "01" as character
    Local cSeqSB1  := "01" as character
    local cSeqZH0  := "01" as character
    local cSeqZHV  := "01" as character
    local cSeqSRJ  := "01" as character
    local cSeqSBM  := "01" as character
    local cSeqZH1  := "01" as character
    local cSeqSU9  := "01" as character
    local cSeqZHL  := "01" as character
    local cSeqZIA  := "01" as character
    local cSeqSTJ  := "01" as character
    local cSeqSCP  := "01" as character
    local aStruct  := {} as array
    local nX       := 0 as numeric
    local nJ       := 0 as numeric
    Local aArqUpd  := {} as array
    Local aOldStr  := {} as array
    Local nContext := 0 as numeric
    Local aNewStr  := {} as array
    Local nTipo    := 0 as numeric
    Local nCampo   := 0 as numeric
    Local nTamanho := 0 as numeric
    local nDecimal := 0 as numeric
    Local nTopErr  := 0 as numeric

    aStruct :={ { "X3_ARQUIVO", 0 }, { "X3_ORDEM"  , 0 }, { "X3_CAMPO"  , 0 }, { "X3_TIPO"   , 0 }, { "X3_TAMANHO", 0 }, { "X3_DECIMAL", 0 }, { "X3_TITULO" , 0 }, ;
                { "X3_TITSPA" , 0 }, { "X3_TITENG" , 0 }, { "X3_DESCRIC", 0 }, { "X3_DESCSPA", 0 }, { "X3_DESCENG", 0 }, { "X3_PICTURE", 0 }, { "X3_VALID"  , 0 }, ;
                { "X3_USADO"  , 0 }, { "X3_RELACAO", 0 }, { "X3_F3"     , 0 }, { "X3_NIVEL"  , 0 }, { "X3_RESERV" , 0 }, { "X3_CHECK"  , 0 }, { "X3_TRIGGER", 0 }, ;
                { "X3_PROPRI" , 0 }, { "X3_BROWSE" , 0 }, { "X3_VISUAL" , 0 }, { "X3_CONTEXT", 0 }, { "X3_OBRIGAT", 0 }, { "X3_VLDUSER", 0 }, { "X3_CBOX"   , 0 }, ;
                { "X3_CBOXSPA", 0 }, { "X3_CBOXENG", 0 }, { "X3_PICTVAR", 0 }, { "X3_WHEN"   , 0 }, { "X3_INIBRW" , 0 }, { "X3_GRPSXG" , 0 }, { "X3_FOLDER" , 0 }, ;
                { "X3_CONDSQL", 0 }, { "X3_CHKSQL" , 0 }, { "X3_IDXSRV" , 0 }, { "X3_ORTOGRA", 0 }, { "X3_TELA"   , 0 }, { "X3_POSLGT" , 0 }, { "X3_IDXFLD" , 0 }, ;
                { "X3_AGRUP"  , 0 }, { "X3_MODAL"  , 0 }, { "X3_PYME"   , 0 } }
    nContext := aScan( aStruct, {|x| AllTrim( x[1] ) == 'X3_CONTEXT' } )
    nCampo   := aScan( aStruct, {|x| AllTrim( x[1] ) == 'X3_CAMPO' } )
    nTipo    := aScan( aStruct, {|x| AllTrim( x[1] ) == 'X3_TIPO' } )
    nTamanho := aScan( aStruct, {|x| AllTrim( x[1] ) == 'X3_TAMANHO' } )
    nDecimal := aScan( aStruct, {|x| AllTrim( x[1] ) == 'X3_DECIMAL' } )

    if cTable == 'nucleo'

        // ID do registro no app
        if ZH6->( FieldPos( 'ZH6_X_IDAP' ) ) == 0
            cSeqZH6 := iif( cSeqZH6 > "01", Soma1(cSeqZH6), newSeq( 'ZH6' ) )
            aAdd( aSX3, { ;
                        'ZH6'																	, ; //X3_ARQUIVO
                        cSeqZH6																	, ; //X3_ORDEM
                        'ZH6_X_IDAP'															, ; //X3_CAMPO
                        'N'																		, ; //X3_TIPO
                        9																		, ; //X3_TAMANHO
                        0																		, ; //X3_DECIMAL
                        'ID App'															    , ; //X3_TITULO
                        'ID App'															    , ; //X3_TITSPA
                        'ID App'															    , ; //X3_TITENG
                        'ID App Avicola'														, ; //X3_DESCRIC
                        'ID App Avicola'														, ; //X3_DESCSPA
                        'ID App Avicola'														, ; //X3_DESCENG
                        '@E 9,999,999'															, ; //X3_PICTURE
                        ''																		, ; //X3_VALID
                        'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', ; //X3_USADO
                        ''																		, ; //X3_RELACAO
                        ''																		, ; //X3_F3
                        0																		, ; //X3_NIVEL
                        'xxxxxx x'																, ; //X3_RESERV
                        ''																		, ; //X3_CHECK
                        ''																		, ; //X3_TRIGGER
                        'U'																		, ; //X3_PROPRI
                        'N'																		, ; //X3_BROWSE
                        'V'																		, ; //X3_VISUAL
                        'R'																		, ; //X3_CONTEXT
                        ''																		, ; //X3_OBRIGAT
                        ''																		, ; //X3_VLDUSER
                        ''																		, ; //X3_CBOX
                        ''																		, ; //X3_CBOXSPA
                        ''																		, ; //X3_CBOXENG
                        ''																		, ; //X3_PICTVAR
                        ''																		, ; //X3_WHEN
                        ''																		, ; //X3_INIBRW
                        ''																		, ; //X3_GRPSXG
                        ''																		, ; //X3_FOLDER
                        ''																		, ; //X3_CONDSQL
                        ''																		, ; //X3_CHKSQL
                        ''																		, ; //X3_IDXSRV
                        'N'																		, ; //X3_ORTOGRA
                        ''																		, ; //X3_TELA
                        '1'																		, ; //X3_POSLGT
                        'N'																		, ; //X3_IDXFLD
                        ''																		, ; //X3_AGRUP
                        '2'																		, ; //X3_MODAL
                        ''																		} ) //X3_PYME
        endif
        
        // Campo para indicar o número de aviários de um núcleo
        if ZH6->( FieldPos( 'ZH6_X_NAVI' ) ) == 0
            cSeqZH6 := iif( cSeqZH6 > "01", Soma1(cSeqZH6), newSeq( 'ZH6' ) )
            aAdd( aSX3, { ;
                        'ZH6'																	, ; //X3_ARQUIVO
                        cSeqZH6																	, ; //X3_ORDEM
                        'ZH6_X_NAVI'															, ; //X3_CAMPO
                        'N'																		, ; //X3_TIPO
                        3																		, ; //X3_TAMANHO
                        0																		, ; //X3_DECIMAL
                        'Nr Aviários'														    , ; //X3_TITULO
                        'Nr Aviários'														    , ; //X3_TITSPA
                        'Nr Aviários'														    , ; //X3_TITENG
                        'Número de Aviários'    												, ; //X3_DESCRIC
                        'Número de Aviários'													, ; //X3_DESCSPA
                        'Número de Aviários'													, ; //X3_DESCENG
                        '@E 999'    															, ; //X3_PICTURE
                        ''																		, ; //X3_VALID
                        'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', ; //X3_USADO
                        ''																		, ; //X3_RELACAO
                        ''																		, ; //X3_F3
                        0																		, ; //X3_NIVEL
                        'xxxxxx x'																, ; //X3_RESERV
                        ''																		, ; //X3_CHECK
                        ''																		, ; //X3_TRIGGER
                        'U'																		, ; //X3_PROPRI
                        'N'																		, ; //X3_BROWSE
                        'A'																		, ; //X3_VISUAL
                        'R'																		, ; //X3_CONTEXT
                        ''																		, ; //X3_OBRIGAT
                        ''																		, ; //X3_VLDUSER
                        ''																		, ; //X3_CBOX
                        ''																		, ; //X3_CBOXSPA
                        ''																		, ; //X3_CBOXENG
                        ''																		, ; //X3_PICTVAR
                        ''																		, ; //X3_WHEN
                        ''																		, ; //X3_INIBRW
                        ''																		, ; //X3_GRPSXG
                        ''																		, ; //X3_FOLDER
                        ''																		, ; //X3_CONDSQL
                        ''																		, ; //X3_CHKSQL
                        ''																		, ; //X3_IDXSRV
                        'N'																		, ; //X3_ORTOGRA
                        ''																		, ; //X3_TELA
                        '1'																		, ; //X3_POSLGT
                        'N'																		, ; //X3_IDXFLD
                        ''																		, ; //X3_AGRUP
                        '2'																		, ; //X3_MODAL
                        ''																		} ) //X3_PYME
        endif

        // Campo para indicar o código do bem
        if ZH6->( FieldPos( 'ZH6_X_BEM' ) ) == 0
            cSeqZH6 := iif( cSeqZH6 > "01", Soma1(cSeqZH6), newSeq( 'ZH6' ) )
            aAdd( aSX3, { ;
                        'ZH6'																	, ; //X3_ARQUIVO
                        cSeqZH6																	, ; //X3_ORDEM
                        'ZH6_X_BEM'				    											, ; //X3_CAMPO
                        'C'																		, ; //X3_TIPO
                        TAMSX3('T9_CODBEM')[1]													, ; //X3_TAMANHO
                        0																		, ; //X3_DECIMAL
                        'Cod. Bem'		    												    , ; //X3_TITULO
                        'Cod. Bem'	    													    , ; //X3_TITSPA
                        'Cod. Bem'  			   											    , ; //X3_TITENG
                        'Codigo do Bem'    	    	    										, ; //X3_DESCRIC
                        'Codigo do Bem'	    			    									, ; //X3_DESCSPA
                        'Codigo do Bem' 					    								, ; //X3_DESCENG
                        '@!'           															, ; //X3_PICTURE
                        ''																		, ; //X3_VALID
                        'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', ; //X3_USADO
                        ''																		, ; //X3_RELACAO
                        'ST9'																	, ; //X3_F3
                        0																		, ; //X3_NIVEL
                        'xxxxxx x'																, ; //X3_RESERV
                        ''																		, ; //X3_CHECK
                        ''																		, ; //X3_TRIGGER
                        'U'																		, ; //X3_PROPRI
                        'N'																		, ; //X3_BROWSE
                        'A'																		, ; //X3_VISUAL
                        'R'																		, ; //X3_CONTEXT
                        ''																		, ; //X3_OBRIGAT
                        ''																		, ; //X3_VLDUSER
                        ''																		, ; //X3_CBOX
                        ''																		, ; //X3_CBOXSPA
                        ''																		, ; //X3_CBOXENG
                        ''																		, ; //X3_PICTVAR
                        ''																		, ; //X3_WHEN
                        ''																		, ; //X3_INIBRW
                        ''																		, ; //X3_GRPSXG
                        ''																		, ; //X3_FOLDER
                        ''																		, ; //X3_CONDSQL
                        ''																		, ; //X3_CHKSQL
                        ''																		, ; //X3_IDXSRV
                        'N'																		, ; //X3_ORTOGRA
                        ''																		, ; //X3_TELA
                        '1'																		, ; //X3_POSLGT
                        'N'																		, ; //X3_IDXFLD
                        ''																		, ; //X3_AGRUP
                        '2'																		, ; //X3_MODAL
                        ''																		} ) //X3_PYME
        endif
    
    elseif cTable == 'funcaoxnucleo'
        
        // Campo do ID do registro no APP
        if ZHV->( FieldPos( 'ZHV_X_IDAP' ) ) == 0
            cSeqZHV := newSEQ( 'ZHV' )
            aAdd( aSX3, { ;
                        'ZHV'																	, ; //X3_ARQUIVO
                        cSeqZHV																	, ; //X3_ORDEM
                        'ZHV_X_IDAP'  															, ; //X3_CAMPO
                        'N'																		, ; //X3_TIPO
                        9																		, ; //X3_TAMANHO
                        0																		, ; //X3_DECIMAL
                        'ID App'     															, ; //X3_TITULO
                        'ID App'    															, ; //X3_TITSPA
                        'ID App'    															, ; //X3_TITENG
                        'ID no App Avicola'														, ; //X3_DESCRIC
                        'ID no App Avicola'														, ; //X3_DESCSPA
                        'ID no App Avicola'														, ; //X3_DESCENG
                        '@E 9,999,999'															, ; //X3_PICTURE
                        ''																		, ; //X3_VALID
                        'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', ; //X3_USADO
                        ''																		, ; //X3_RELACAO
                        ''																		, ; //X3_F3
                        0																		, ; //X3_NIVEL
                        'xxxxxx x'																, ; //X3_RESERV
                        ''																		, ; //X3_CHECK
                        ''																		, ; //X3_TRIGGER
                        'U'																		, ; //X3_PROPRI
                        'N'																		, ; //X3_BROWSE
                        'V'																		, ; //X3_VISUAL
                        'R'																		, ; //X3_CONTEXT
                        ''																		, ; //X3_OBRIGAT
                        ''																		, ; //X3_VLDUSER
                        ''          															, ; //X3_CBOX
                        ''          															, ; //X3_CBOXSPA
                        ''	            														, ; //X3_CBOXENG
                        ''																		, ; //X3_PICTVAR
                        ''																		, ; //X3_WHEN
                        ''																		, ; //X3_INIBRW
                        ''																		, ; //X3_GRPSXG
                        ''																		, ; //X3_FOLDER
                        ''																		, ; //X3_CONDSQL
                        ''																		, ; //X3_CHKSQL
                        ''																		, ; //X3_IDXSRV
                        'N'																		, ; //X3_ORTOGRA
                        ''																		, ; //X3_TELA
                        '1'																		, ; //X3_POSLGT
                        'N'																		, ; //X3_IDXFLD
                        ''																		, ; //X3_AGRUP
                        '2'																		, ; //X3_MODAL
                        ''																		} ) //X3_PYME
        endif
    
    elseif cTable == 'produto'

        if SB1->( FieldPos( 'B1_X_RANCH' ) ) == 0
            cSeqSB1 := newSeq( 'SB1' )
            aAdd( aSX3, { ;
                        'SB1'																	, ; //X3_ARQUIVO
                        cSeqSB1																	, ; //X3_ORDEM
                        'B1_X_RANCH'  															, ; //X3_CAMPO
                        'C'																		, ; //X3_TIPO
                        1																		, ; //X3_TAMANHO
                        0																		, ; //X3_DECIMAL
                        'Rancho'	    														, ; //X3_TITULO
                        'Rancho'	    														, ; //X3_TITSPA
                        'Rancho'       															, ; //X3_TITENG
                        'Envia App Avicola'														, ; //X3_DESCRIC
                        'Envia App Avicola'														, ; //X3_DESCSPA
                        'Envia App Avicola'														, ; //X3_DESCENG
                        '@!'																	, ; //X3_PICTURE
                        ''																		, ; //X3_VALID
                        'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', ; //X3_USADO
                        ''																		, ; //X3_RELACAO
                        ''																		, ; //X3_F3
                        0																		, ; //X3_NIVEL
                        'xxxxxx x'																, ; //X3_RESERV
                        ''																		, ; //X3_CHECK
                        ''																		, ; //X3_TRIGGER
                        'U'																		, ; //X3_PROPRI
                        'N'																		, ; //X3_BROWSE
                        'A'																		, ; //X3_VISUAL
                        'R'																		, ; //X3_CONTEXT
                        ''																		, ; //X3_OBRIGAT
                        ''																		, ; //X3_VLDUSER
                        'S=Sim;N=Nao'															, ; //X3_CBOX
                        'S=Sim;N=Nao'															, ; //X3_CBOXSPA
                        'S=Sim;N=Nao'															, ; //X3_CBOXENG
                        ''																		, ; //X3_PICTVAR
                        ''																		, ; //X3_WHEN
                        ''																		, ; //X3_INIBRW
                        ''																		, ; //X3_GRPSXG
                        ''																		, ; //X3_FOLDER
                        ''																		, ; //X3_CONDSQL
                        ''																		, ; //X3_CHKSQL
                        ''																		, ; //X3_IDXSRV
                        'N'																		, ; //X3_ORTOGRA
                        ''																		, ; //X3_TELA
                        '1'																		, ; //X3_POSLGT
                        'N'																		, ; //X3_IDXFLD
                        ''																		, ; //X3_AGRUP
                        '2'																		, ; //X3_MODAL
                        ''																		} ) //X3_PYME
        endif

        if SB1->( FieldPos( 'B1_X_DTAP' ) ) == 0
            cSeqSB1 := iif( cSeqSB1 > "01", Soma1(cSeqSB1), newSeq( 'SB1' ) )
            aAdd( aSX3, { ;
                        'SB1'																	, ; //X3_ARQUIVO
                        cSeqSB1																	, ; //X3_ORDEM
                        'B1_X_DTAP'  															, ; //X3_CAMPO
                        'C'																		, ; //X3_TIPO
                        20                  													, ; //X3_TAMANHO
                        0																		, ; //X3_DECIMAL
                        'DtHr App'															    , ; //X3_TITULO
                        'DtHr App'															    , ; //X3_TITSPA
                        'DtHr App'			    												, ; //X3_TITENG
                        'Dt e Hr Env App'  														, ; //X3_DESCRIC
                        'Dt e Hr Env App'														, ; //X3_DESCSPA
                        'Dt e Hr Env App'														, ; //X3_DESCENG
                        '@!'																	, ; //X3_PICTURE
                        ''																		, ; //X3_VALID
                        'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', ; //X3_USADO
                        ''																		, ; //X3_RELACAO
                        ''																		, ; //X3_F3
                        0																		, ; //X3_NIVEL
                        'xxxxxx x'																, ; //X3_RESERV
                        ''																		, ; //X3_CHECK
                        ''																		, ; //X3_TRIGGER
                        'U'																		, ; //X3_PROPRI
                        'N'																		, ; //X3_BROWSE
                        'V'																		, ; //X3_VISUAL
                        'R'																		, ; //X3_CONTEXT
                        ''																		, ; //X3_OBRIGAT
                        ''																		, ; //X3_VLDUSER
                        ''          															, ; //X3_CBOX
                        ''          															, ; //X3_CBOXSPA
                        ''          															, ; //X3_CBOXENG
                        ''																		, ; //X3_PICTVAR
                        '.F.'   																, ; //X3_WHEN
                        ''																		, ; //X3_INIBRW
                        ''																		, ; //X3_GRPSXG
                        ''																		, ; //X3_FOLDER
                        ''																		, ; //X3_CONDSQL
                        ''																		, ; //X3_CHKSQL
                        ''																		, ; //X3_IDXSRV
                        'N'																		, ; //X3_ORTOGRA
                        ''																		, ; //X3_TELA
                        '1'																		, ; //X3_POSLGT
                        'N'																		, ; //X3_IDXFLD
                        ''																		, ; //X3_AGRUP
                        '2'																		, ; //X3_MODAL
                        ''																		} ) //X3_PYME
        endif
    elseif cTable == 'lote'
        if ZH0->( FieldPos( 'ZH0_X_IDAP' ) ) == 0
            cSeqZH0 := iif( cSeqZH0 > "01", Soma1(cSeqZH0), newSeq( 'ZH0' ) )
            aAdd( aSX3, { ;
                        'ZH0'																	, ; //X3_ARQUIVO
                        cSeqZH0																	, ; //X3_ORDEM
                        'ZH0_X_IDAP'  															, ; //X3_CAMPO
                        'N'																		, ; //X3_TIPO
                        9                     													, ; //X3_TAMANHO
                        0																		, ; //X3_DECIMAL
                        'ID App'															    , ; //X3_TITULO
                        'ID App'															    , ; //X3_TITSPA
                        'ID App'			    												, ; //X3_TITENG
                        'ID Registro App'  														, ; //X3_DESCRIC
                        'ID Registro App'														, ; //X3_DESCSPA
                        'ID Registro App'														, ; //X3_DESCENG
                        '@E 9,999,999'  														, ; //X3_PICTURE
                        ''																		, ; //X3_VALID
                        'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', ; //X3_USADO
                        ''																		, ; //X3_RELACAO
                        ''																		, ; //X3_F3
                        0																		, ; //X3_NIVEL
                        'xxxxxx x'																, ; //X3_RESERV
                        ''																		, ; //X3_CHECK
                        ''																		, ; //X3_TRIGGER
                        'U'																		, ; //X3_PROPRI
                        'N'																		, ; //X3_BROWSE
                        'V'																		, ; //X3_VISUAL
                        'R'																		, ; //X3_CONTEXT
                        ''																		, ; //X3_OBRIGAT
                        ''																		, ; //X3_VLDUSER
                        ''          															, ; //X3_CBOX
                        ''          															, ; //X3_CBOXSPA
                        ''          															, ; //X3_CBOXENG
                        ''																		, ; //X3_PICTVAR
                        '.F.'   																, ; //X3_WHEN
                        ''																		, ; //X3_INIBRW
                        ''																		, ; //X3_GRPSXG
                        ''																		, ; //X3_FOLDER
                        ''																		, ; //X3_CONDSQL
                        ''																		, ; //X3_CHKSQL
                        ''																		, ; //X3_IDXSRV
                        'N'																		, ; //X3_ORTOGRA
                        ''																		, ; //X3_TELA
                        '1'																		, ; //X3_POSLGT
                        'N'																		, ; //X3_IDXFLD
                        ''																		, ; //X3_AGRUP
                        '2'																		, ; //X3_MODAL
                        ''																		} ) //X3_PYME
        endif
    elseif cTable == 'funcao'
        if SRJ->( FieldPos( 'RJ_X_IDAP' ) ) == 0
            cSeqSRJ := iif( cSeqSRJ > "01", Soma1(cSeqSRJ), newSeq( 'SRJ' ) )
            aAdd( aSX3, { ;
                        'SRJ'																	, ; //X3_ARQUIVO
                        cSeqSRJ																	, ; //X3_ORDEM
                        'RJ_X_IDAP'  															, ; //X3_CAMPO
                        'C'																		, ; //X3_TIPO
                        TAMSX3('RJ_FUNCAO')[1] 													, ; //X3_TAMANHO
                        0																		, ; //X3_DECIMAL
                        'ID App'															    , ; //X3_TITULO
                        'ID App'															    , ; //X3_TITSPA
                        'ID App'			    												, ; //X3_TITENG
                        'ID Registro App'  														, ; //X3_DESCRIC
                        'ID Registro App'														, ; //X3_DESCSPA
                        'ID Registro App'														, ; //X3_DESCENG
                        '@!'              														, ; //X3_PICTURE
                        ''																		, ; //X3_VALID
                        'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', ; //X3_USADO
                        ''																		, ; //X3_RELACAO
                        ''																		, ; //X3_F3
                        0																		, ; //X3_NIVEL
                        'xxxxxx x'																, ; //X3_RESERV
                        ''																		, ; //X3_CHECK
                        ''																		, ; //X3_TRIGGER
                        'U'																		, ; //X3_PROPRI
                        'N'																		, ; //X3_BROWSE
                        'V'																		, ; //X3_VISUAL
                        'R'																		, ; //X3_CONTEXT
                        ''																		, ; //X3_OBRIGAT
                        ''																		, ; //X3_VLDUSER
                        ''          															, ; //X3_CBOX
                        ''          															, ; //X3_CBOXSPA
                        ''          															, ; //X3_CBOXENG
                        ''																		, ; //X3_PICTVAR
                        '.F.'   																, ; //X3_WHEN
                        ''																		, ; //X3_INIBRW
                        ''																		, ; //X3_GRPSXG
                        ''																		, ; //X3_FOLDER
                        ''																		, ; //X3_CONDSQL
                        ''																		, ; //X3_CHKSQL
                        ''																		, ; //X3_IDXSRV
                        'N'																		, ; //X3_ORTOGRA
                        ''																		, ; //X3_TELA
                        '1'																		, ; //X3_POSLGT
                        'N'																		, ; //X3_IDXFLD
                        ''																		, ; //X3_AGRUP
                        '2'																		, ; //X3_MODAL
                        ''																		} ) //X3_PYME
        endif
    elseif cTable = 'grupo'
        if SBM->( FieldPos( 'BM_X_IDAP' ) ) == 0
            cSeqSBM := iif( cSeqSBM > "01", Soma1(cSeqSBM), newSeq( 'SBM' ) )
            aAdd( aSX3, { ;
                        'SBM'																	, ; //X3_ARQUIVO
                        cSeqSBM																	, ; //X3_ORDEM
                        'BM_X_IDAP'  															, ; //X3_CAMPO
                        'C'																		, ; //X3_TIPO
                        TAMSX3('BM_GRUPO')[1] 													, ; //X3_TAMANHO
                        0																		, ; //X3_DECIMAL
                        'ID App'															    , ; //X3_TITULO
                        'ID App'															    , ; //X3_TITSPA
                        'ID App'			    												, ; //X3_TITENG
                        'ID Registro App'  														, ; //X3_DESCRIC
                        'ID Registro App'														, ; //X3_DESCSPA
                        'ID Registro App'														, ; //X3_DESCENG
                        '@!'              														, ; //X3_PICTURE
                        ''																		, ; //X3_VALID
                        'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', ; //X3_USADO
                        ''																		, ; //X3_RELACAO
                        ''																		, ; //X3_F3
                        0																		, ; //X3_NIVEL
                        'xxxxxx x'																, ; //X3_RESERV
                        ''																		, ; //X3_CHECK
                        ''																		, ; //X3_TRIGGER
                        'U'																		, ; //X3_PROPRI
                        'N'																		, ; //X3_BROWSE
                        'V'																		, ; //X3_VISUAL
                        'R'																		, ; //X3_CONTEXT
                        ''																		, ; //X3_OBRIGAT
                        ''																		, ; //X3_VLDUSER
                        ''          															, ; //X3_CBOX
                        ''          															, ; //X3_CBOXSPA
                        ''          															, ; //X3_CBOXENG
                        ''																		, ; //X3_PICTVAR
                        '.F.'   																, ; //X3_WHEN
                        ''																		, ; //X3_INIBRW
                        ''																		, ; //X3_GRPSXG
                        ''																		, ; //X3_FOLDER
                        ''																		, ; //X3_CONDSQL
                        ''																		, ; //X3_CHKSQL
                        ''																		, ; //X3_IDXSRV
                        'N'																		, ; //X3_ORTOGRA
                        ''																		, ; //X3_TELA
                        '1'																		, ; //X3_POSLGT
                        'N'																		, ; //X3_IDXFLD
                        ''																		, ; //X3_AGRUP
                        '2'																		, ; //X3_MODAL
                        ''																		} ) //X3_PYME
        endif
    elseif cTable == 'subitens'
        if ZH1->( FieldPos( 'ZH1_X_IDAP' ) ) == 0
            cSeqZH1 := iif( cSeqZH1 > "01", Soma1(cSeqZH1), newSeq( 'ZH1' ) )
            aAdd( aSX3, { ;
                        'ZH1'																	, ; //X3_ARQUIVO
                        cSeqZH1																	, ; //X3_ORDEM
                        'ZH1_X_IDAP'  															, ; //X3_CAMPO
                        'N'																		, ; //X3_TIPO
                        9                    													, ; //X3_TAMANHO
                        0																		, ; //X3_DECIMAL
                        'ID App'															    , ; //X3_TITULO
                        'ID App'															    , ; //X3_TITSPA
                        'ID App'			    												, ; //X3_TITENG
                        'ID Registro App'  														, ; //X3_DESCRIC
                        'ID Registro App'														, ; //X3_DESCSPA
                        'ID Registro App'														, ; //X3_DESCENG
                        '@E 9,999,999'     														, ; //X3_PICTURE
                        ''																		, ; //X3_VALID
                        'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', ; //X3_USADO
                        ''																		, ; //X3_RELACAO
                        ''																		, ; //X3_F3
                        0																		, ; //X3_NIVEL
                        'xxxxxx x'																, ; //X3_RESERV
                        ''																		, ; //X3_CHECK
                        ''																		, ; //X3_TRIGGER
                        'U'																		, ; //X3_PROPRI
                        'N'																		, ; //X3_BROWSE
                        'V'																		, ; //X3_VISUAL
                        'R'																		, ; //X3_CONTEXT
                        ''																		, ; //X3_OBRIGAT
                        ''																		, ; //X3_VLDUSER
                        ''          															, ; //X3_CBOX
                        ''          															, ; //X3_CBOXSPA
                        ''          															, ; //X3_CBOXENG
                        ''																		, ; //X3_PICTVAR
                        '.F.'   																, ; //X3_WHEN
                        ''																		, ; //X3_INIBRW
                        ''																		, ; //X3_GRPSXG
                        ''																		, ; //X3_FOLDER
                        ''																		, ; //X3_CONDSQL
                        ''																		, ; //X3_CHKSQL
                        ''																		, ; //X3_IDXSRV
                        'N'																		, ; //X3_ORTOGRA
                        ''																		, ; //X3_TELA
                        '1'																		, ; //X3_POSLGT
                        'N'																		, ; //X3_IDXFLD
                        ''																		, ; //X3_AGRUP
                        '2'																		, ; //X3_MODAL
                        ''																		} ) //X3_PYME
        endif

        if ZH1->( FieldPos( 'ZH1_X_APP' ) ) == 0
            cSeqZH1 := iif( cSeqZH1 > "01", Soma1(cSeqZH1), newSeq( 'ZH1' ) )
            aAdd( aSX3, { ;
                        'ZH1'																	, ; //X3_ARQUIVO
                        cSeqZH1																	, ; //X3_ORDEM
                        'ZH1_X_APP'  															, ; //X3_CAMPO
                        'C'																		, ; //X3_TIPO
                        1                    													, ; //X3_TAMANHO
                        0																		, ; //X3_DECIMAL
                        'Envia App?'														    , ; //X3_TITULO
                        'Envia App?'														    , ; //X3_TITSPA
                        'Envia App?'		    												, ; //X3_TITENG
                        'Envia para App'  														, ; //X3_DESCRIC
                        'Envia para App'														, ; //X3_DESCSPA
                        'Envia para App'														, ; //X3_DESCENG
                        '@!'             														, ; //X3_PICTURE
                        ''																		, ; //X3_VALID
                        'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', ; //X3_USADO
                        ''																		, ; //X3_RELACAO
                        ''																		, ; //X3_F3
                        0																		, ; //X3_NIVEL
                        'xxxxxx x'																, ; //X3_RESERV
                        ''																		, ; //X3_CHECK
                        ''																		, ; //X3_TRIGGER
                        'U'																		, ; //X3_PROPRI
                        'N'																		, ; //X3_BROWSE
                        'A'																		, ; //X3_VISUAL
                        'R'																		, ; //X3_CONTEXT
                        ''																		, ; //X3_OBRIGAT
                        ''																		, ; //X3_VLDUSER
                        'S=Sim;N=Nao' 															, ; //X3_CBOX
                        'S=Si;N=No'    															, ; //X3_CBOXSPA
                        'S=Yes;N=No'   															, ; //X3_CBOXENG
                        ''																		, ; //X3_PICTVAR
                        ''         																, ; //X3_WHEN
                        ''																		, ; //X3_INIBRW
                        ''																		, ; //X3_GRPSXG
                        ''																		, ; //X3_FOLDER
                        ''																		, ; //X3_CONDSQL
                        ''																		, ; //X3_CHKSQL
                        ''																		, ; //X3_IDXSRV
                        'N'																		, ; //X3_ORTOGRA
                        ''																		, ; //X3_TELA
                        '1'																		, ; //X3_POSLGT
                        'N'																		, ; //X3_IDXFLD
                        ''																		, ; //X3_AGRUP
                        '2'																		, ; //X3_MODAL
                        ''																		} ) //X3_PYME
        endif

        if ZH1->( FieldPos( 'ZH1_X_SEXO' ) ) == 0
            cSeqZH1 := iif( cSeqZH1 > "01", Soma1(cSeqZH1), newSeq( 'ZH1' ) )
            aAdd( aSX3, { ;
                        'ZH1'																	, ; //X3_ARQUIVO
                        cSeqZH1																	, ; //X3_ORDEM
                        'ZH1_X_SEXO'  															, ; //X3_CAMPO
                        'C'																		, ; //X3_TIPO
                        1                    													, ; //X3_TAMANHO
                        0																		, ; //X3_DECIMAL
                        'Sexo'      														    , ; //X3_TITULO
                        'Sexo'      														    , ; //X3_TITSPA
                        'Sexo'      		    												, ; //X3_TITENG
                        'Sexo'           														, ; //X3_DESCRIC
                        'Sexo'          														, ; //X3_DESCSPA
                        'Sexo'          														, ; //X3_DESCENG
                        '@!'             														, ; //X3_PICTURE
                        ''																		, ; //X3_VALID
                        'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', ; //X3_USADO
                        ''																		, ; //X3_RELACAO
                        ''																		, ; //X3_F3
                        0																		, ; //X3_NIVEL
                        'xxxxxx x'																, ; //X3_RESERV
                        ''																		, ; //X3_CHECK
                        ''																		, ; //X3_TRIGGER
                        'U'																		, ; //X3_PROPRI
                        'N'																		, ; //X3_BROWSE
                        'A'																		, ; //X3_VISUAL
                        'R'																		, ; //X3_CONTEXT
                        ''																		, ; //X3_OBRIGAT
                        ''																		, ; //X3_VLDUSER
                        'M=Macho;F=Femea;A=Ambos'												, ; //X3_CBOX
                        'M=Macho;F=Femea;A=Ambos'												, ; //X3_CBOXSPA
                        'M=Macho;F=Femea;A=Ambos'												, ; //X3_CBOXENG
                        ''																		, ; //X3_PICTVAR
                        ''         																, ; //X3_WHEN
                        ''																		, ; //X3_INIBRW
                        ''																		, ; //X3_GRPSXG
                        ''																		, ; //X3_FOLDER
                        ''																		, ; //X3_CONDSQL
                        ''																		, ; //X3_CHKSQL
                        ''																		, ; //X3_IDXSRV
                        'N'																		, ; //X3_ORTOGRA
                        ''																		, ; //X3_TELA
                        '1'																		, ; //X3_POSLGT
                        'N'																		, ; //X3_IDXFLD
                        ''																		, ; //X3_AGRUP
                        '2'																		, ; //X3_MODAL
                        ''																		} ) //X3_PYME
        endif

        if ZH1->( FieldPos( 'ZH1_X_GRAP' ) ) == 0
            cSeqZH1 := iif( cSeqZH1 > "01", Soma1(cSeqZH1), newSeq( 'ZH1' ) )
            aAdd( aSX3, { ;
                        'ZH1'																	, ; //X3_ARQUIVO
                        cSeqZH1																	, ; //X3_ORDEM
                        'ZH1_X_GRAP'  															, ; //X3_CAMPO
                        'C'																		, ; //X3_TIPO
                        1                    													, ; //X3_TAMANHO
                        0																		, ; //X3_DECIMAL
                        'Grupo App'     													    , ; //X3_TITULO
                        'Grupo App'      													    , ; //X3_TITSPA
                        'Grupo App'      		    											, ; //X3_TITENG
                        'Agrupamento App'           											, ; //X3_DESCRIC
                        'Agrupamento App'         												, ; //X3_DESCSPA
                        'Agrupamento App'  														, ; //X3_DESCENG
                        '@!'             														, ; //X3_PICTURE
                        ''																		, ; //X3_VALID
                        'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', ; //X3_USADO
                        ''																		, ; //X3_RELACAO
                        ''																		, ; //X3_F3
                        0																		, ; //X3_NIVEL
                        'xxxxxx x'																, ; //X3_RESERV
                        ''																		, ; //X3_CHECK
                        ''																		, ; //X3_TRIGGER
                        'U'																		, ; //X3_PROPRI
                        'N'																		, ; //X3_BROWSE
                        'A'																		, ; //X3_VISUAL
                        'R'																		, ; //X3_CONTEXT
                        ''																		, ; //X3_OBRIGAT
                        ''																		, ; //X3_VLDUSER
                        'P=Producao;G=Geral;R=Recria'   										, ; //X3_CBOX
                        'P=Producao;G=Geral;R=Recria'	    									, ; //X3_CBOXSPA
                        'P=Producao;G=Geral;R=Recria'   										, ; //X3_CBOXENG
                        ''																		, ; //X3_PICTVAR
                        ''         																, ; //X3_WHEN
                        ''																		, ; //X3_INIBRW
                        ''																		, ; //X3_GRPSXG
                        ''																		, ; //X3_FOLDER
                        ''																		, ; //X3_CONDSQL
                        ''																		, ; //X3_CHKSQL
                        ''																		, ; //X3_IDXSRV
                        'N'																		, ; //X3_ORTOGRA
                        ''																		, ; //X3_TELA
                        '1'																		, ; //X3_POSLGT
                        'N'																		, ; //X3_IDXFLD
                        ''																		, ; //X3_AGRUP
                        '2'																		, ; //X3_MODAL
                        ''																		} ) //X3_PYME
        endif

        if ZH1->( FieldPos( 'ZH1_X_NOMR' ) ) == 0
            cSeqZH1 := iif( cSeqZH1 > "01", Soma1(cSeqZH1), newSeq( 'ZH1' ) )
            aAdd( aSX3, { ;
                        'ZH1'																	, ; //X3_ARQUIVO
                        cSeqZH1																	, ; //X3_ORDEM
                        'ZH1_X_NOMR'  															, ; //X3_CAMPO
                        'C'																		, ; //X3_TIPO
                        1                    													, ; //X3_TAMANHO
                        0																		, ; //X3_DECIMAL
                        'Nome Reduz.'     													    , ; //X3_TITULO
                        'Nome Reduz.'      													    , ; //X3_TITSPA
                        'Nome Reduz.'      		    											, ; //X3_TITENG
                        'Nome Reduzido'                											, ; //X3_DESCRIC
                        'Nome Reduzido'         												, ; //X3_DESCSPA
                        'Nome Reduzido'  														, ; //X3_DESCENG
                        '@!'             														, ; //X3_PICTURE
                        ''																		, ; //X3_VALID
                        'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', ; //X3_USADO
                        ''																		, ; //X3_RELACAO
                        ''																		, ; //X3_F3
                        0																		, ; //X3_NIVEL
                        'xxxxxx x'																, ; //X3_RESERV
                        ''																		, ; //X3_CHECK
                        ''																		, ; //X3_TRIGGER
                        'U'																		, ; //X3_PROPRI
                        'N'																		, ; //X3_BROWSE
                        'A'																		, ; //X3_VISUAL
                        'R'																		, ; //X3_CONTEXT
                        'S' 																	, ; //X3_OBRIGAT
                        ''																		, ; //X3_VLDUSER
                        'D=Diarios;B=Bons;M=Mortes;S=Descartes;R=Racao'							, ; //X3_CBOX
                        'D=Diarios;B=Bons;M=Mortes;S=Descartes;R=Racao'	    					, ; //X3_CBOXSPA
                        'D=Diarios;B=Bons;M=Mortes;S=Descartes;R=Racao' 						, ; //X3_CBOXENG
                        ''																		, ; //X3_PICTVAR
                        ''         																, ; //X3_WHEN
                        ''																		, ; //X3_INIBRW
                        ''																		, ; //X3_GRPSXG
                        ''																		, ; //X3_FOLDER
                        ''																		, ; //X3_CONDSQL
                        ''																		, ; //X3_CHKSQL
                        ''																		, ; //X3_IDXSRV
                        'N'																		, ; //X3_ORTOGRA
                        ''																		, ; //X3_TELA
                        '1'																		, ; //X3_POSLGT
                        'N'																		, ; //X3_IDXFLD
                        ''																		, ; //X3_AGRUP
                        '2'																		, ; //X3_MODAL
                        ''																		} ) //X3_PYME
        endif
    elseif cTable == 'ocorrencias'
        if SU9->( FieldPos( 'U9_X_APP' ) ) == 0
            cSeqSU9 := iif( cSeqSU9 > "01", Soma1(cSeqSU9), newSeq( 'SU9' ) )
            aAdd( aSX3, { ;
                        'SU9'																	, ; //X3_ARQUIVO
                        cSeqSU9																	, ; //X3_ORDEM
                        'U9_X_APP'  															, ; //X3_CAMPO
                        'C'																		, ; //X3_TIPO
                        1                    													, ; //X3_TAMANHO
                        0																		, ; //X3_DECIMAL
                        'Envia App?'      		    										    , ; //X3_TITULO
                        'Envia App?'      													    , ; //X3_TITSPA
                        'Envia App?'      		   												, ; //X3_TITENG
                        'Envia Para App'         												, ; //X3_DESCRIC
                        'Envia Para App'        												, ; //X3_DESCSPA
                        'Envia Para App'        												, ; //X3_DESCENG
                        '@!'             														, ; //X3_PICTURE
                        ''																		, ; //X3_VALID
                        'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', ; //X3_USADO
                        ''																		, ; //X3_RELACAO
                        ''																		, ; //X3_F3
                        0																		, ; //X3_NIVEL
                        'xxxxxx x'																, ; //X3_RESERV
                        ''																		, ; //X3_CHECK
                        ''																		, ; //X3_TRIGGER
                        'U'																		, ; //X3_PROPRI
                        'N'																		, ; //X3_BROWSE
                        'A'																		, ; //X3_VISUAL
                        'R'																		, ; //X3_CONTEXT
                        ''																		, ; //X3_OBRIGAT
                        ''																		, ; //X3_VLDUSER
                        'S=Sim;N=Nao'           												, ; //X3_CBOX
                        'S=Sim;N=Nao'           												, ; //X3_CBOXSPA
                        'S=Sim;N=Nao'           												, ; //X3_CBOXENG
                        ''																		, ; //X3_PICTVAR
                        ''         																, ; //X3_WHEN
                        ''																		, ; //X3_INIBRW
                        ''																		, ; //X3_GRPSXG
                        ''																		, ; //X3_FOLDER
                        ''																		, ; //X3_CONDSQL
                        ''																		, ; //X3_CHKSQL
                        ''																		, ; //X3_IDXSRV
                        'N'																		, ; //X3_ORTOGRA
                        ''																		, ; //X3_TELA
                        '1'																		, ; //X3_POSLGT
                        'N'																		, ; //X3_IDXFLD
                        ''																		, ; //X3_AGRUP
                        '2'																		, ; //X3_MODAL
                        ''																		} ) //X3_PYME
        endif

        if SU9->( FieldPos( 'U9_X_IDAP' ) ) == 0
            cSeqSU9 := iif( cSeqSU9 > "01", Soma1(cSeqSU9), newSeq( 'SU9' ) )
            aAdd( aSX3, { ;
                        'SU9'																	, ; //X3_ARQUIVO
                        cSeqSU9																	, ; //X3_ORDEM
                        'U9_X_IDAP'  															, ; //X3_CAMPO
                        'N'																		, ; //X3_TIPO
                        9                    													, ; //X3_TAMANHO
                        0																		, ; //X3_DECIMAL
                        'ID App'      														    , ; //X3_TITULO
                        'ID App'      														    , ; //X3_TITSPA
                        'ID App'      		    												, ; //X3_TITENG
                        'ID do Aplicativo'           											, ; //X3_DESCRIC
                        'ID do Aplicativo'          											, ; //X3_DESCSPA
                        'ID do Aplicativo'          											, ; //X3_DESCENG
                        '@!'             														, ; //X3_PICTURE
                        ''																		, ; //X3_VALID
                        'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', ; //X3_USADO
                        ''																		, ; //X3_RELACAO
                        ''																		, ; //X3_F3
                        0																		, ; //X3_NIVEL
                        'xxxxxx x'																, ; //X3_RESERV
                        ''																		, ; //X3_CHECK
                        ''																		, ; //X3_TRIGGER
                        'U'																		, ; //X3_PROPRI
                        'N'																		, ; //X3_BROWSE
                        'V'																		, ; //X3_VISUAL
                        'R'																		, ; //X3_CONTEXT
                        ''																		, ; //X3_OBRIGAT
                        ''																		, ; //X3_VLDUSER
                        ''												                        , ; //X3_CBOX
                        ''						                        						, ; //X3_CBOXSPA
                        ''                      												, ; //X3_CBOXENG
                        ''																		, ; //X3_PICTVAR
                        '.F.'         															, ; //X3_WHEN
                        ''																		, ; //X3_INIBRW
                        ''																		, ; //X3_GRPSXG
                        ''																		, ; //X3_FOLDER
                        ''																		, ; //X3_CONDSQL
                        ''																		, ; //X3_CHKSQL
                        ''																		, ; //X3_IDXSRV
                        'N'																		, ; //X3_ORTOGRA
                        ''																		, ; //X3_TELA
                        '1'																		, ; //X3_POSLGT
                        'N'																		, ; //X3_IDXFLD
                        ''																		, ; //X3_AGRUP
                        '2'																		, ; //X3_MODAL
                        ''																		} ) //X3_PYME
        endif

    elseif cTable == 'coletaitens'    
        if ZHL->( FieldPos( 'ZHL_X_IDAP' ) ) == 0
            cSeqZHL := iif( cSeqZHL > "01", Soma1(cSeqZHL), newSeq( 'ZHL' ) )
            aAdd( aSX3, { ;
                        'ZHL'																	, ; //X3_ARQUIVO
                        cSeqZHL																	, ; //X3_ORDEM
                        'ZHL_X_IDAP'  															, ; //X3_CAMPO
                        'N'																		, ; //X3_TIPO
                        9                    													, ; //X3_TAMANHO
                        0																		, ; //X3_DECIMAL
                        'ID App'      														    , ; //X3_TITULO
                        'ID App'      														    , ; //X3_TITSPA
                        'ID App'      		    												, ; //X3_TITENG
                        'ID do Aplicativo'           											, ; //X3_DESCRIC
                        'ID do Aplicativo'          											, ; //X3_DESCSPA
                        'ID do Aplicativo'          											, ; //X3_DESCENG
                        '999'             														, ; //X3_PICTURE
                        ''																		, ; //X3_VALID
                        'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', ; //X3_USADO
                        ''																		, ; //X3_RELACAO
                        ''																		, ; //X3_F3
                        0																		, ; //X3_NIVEL
                        'xxxxxx x'																, ; //X3_RESERV
                        ''																		, ; //X3_CHECK
                        ''																		, ; //X3_TRIGGER
                        'U'																		, ; //X3_PROPRI
                        'N'																		, ; //X3_BROWSE
                        'V'																		, ; //X3_VISUAL
                        'R'																		, ; //X3_CONTEXT
                        ''																		, ; //X3_OBRIGAT
                        ''																		, ; //X3_VLDUSER
                        ''												                        , ; //X3_CBOX
                        ''						                        						, ; //X3_CBOXSPA
                        ''                      												, ; //X3_CBOXENG
                        ''																		, ; //X3_PICTVAR
                        '.F.'         															, ; //X3_WHEN
                        ''																		, ; //X3_INIBRW
                        ''																		, ; //X3_GRPSXG
                        ''																		, ; //X3_FOLDER
                        ''																		, ; //X3_CONDSQL
                        ''																		, ; //X3_CHKSQL
                        ''																		, ; //X3_IDXSRV
                        'N'																		, ; //X3_ORTOGRA
                        ''																		, ; //X3_TELA
                        '1'																		, ; //X3_POSLGT
                        'N'																		, ; //X3_IDXFLD
                        ''																		, ; //X3_AGRUP
                        '2'																		, ; //X3_MODAL
                        ''																		} ) //X3_PYME
        endif
    
    elseif cTable == 'solicitacoes'    
        if ZIA->( FieldPos( 'ZIA_X_IDAP' ) ) == 0
            cSeqZIA := iif( cSeqZIA > "01", Soma1(cSeqZIA), newSeq( 'ZIA' ) )
            aAdd( aSX3, { ;
                        'ZIA'																	, ; //X3_ARQUIVO
                        cSeqZIA																	, ; //X3_ORDEM
                        'ZIA_X_IDAP'  															, ; //X3_CAMPO
                        'N'																		, ; //X3_TIPO
                        9                    													, ; //X3_TAMANHO
                        0																		, ; //X3_DECIMAL
                        'ID App'      														    , ; //X3_TITULO
                        'ID App'      														    , ; //X3_TITSPA
                        'ID App'      		    												, ; //X3_TITENG
                        'ID do Aplicativo'           											, ; //X3_DESCRIC
                        'ID do Aplicativo'          											, ; //X3_DESCSPA
                        'ID do Aplicativo'          											, ; //X3_DESCENG
                        '999'             														, ; //X3_PICTURE
                        ''																		, ; //X3_VALID
                        'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', ; //X3_USADO
                        ''																		, ; //X3_RELACAO
                        ''																		, ; //X3_F3
                        0																		, ; //X3_NIVEL
                        'xxxxxx x'																, ; //X3_RESERV
                        ''																		, ; //X3_CHECK
                        ''																		, ; //X3_TRIGGER
                        'U'																		, ; //X3_PROPRI
                        'N'																		, ; //X3_BROWSE
                        'V'																		, ; //X3_VISUAL
                        'R'																		, ; //X3_CONTEXT
                        ''																		, ; //X3_OBRIGAT
                        ''																		, ; //X3_VLDUSER
                        ''												                        , ; //X3_CBOX
                        ''						                        						, ; //X3_CBOXSPA
                        ''                      												, ; //X3_CBOXENG
                        ''																		, ; //X3_PICTVAR
                        '.F.'         															, ; //X3_WHEN
                        ''																		, ; //X3_INIBRW
                        ''																		, ; //X3_GRPSXG
                        ''																		, ; //X3_FOLDER
                        ''																		, ; //X3_CONDSQL
                        ''																		, ; //X3_CHKSQL
                        ''																		, ; //X3_IDXSRV
                        'N'																		, ; //X3_ORTOGRA
                        ''																		, ; //X3_TELA
                        '1'																		, ; //X3_POSLGT
                        'N'																		, ; //X3_IDXFLD
                        ''																		, ; //X3_AGRUP
                        '2'																		, ; //X3_MODAL
                        ''																		} ) //X3_PYME
        endif

        if ZIA->( FieldPos( 'ZIA_X_IDSO' ) ) == 0
            cSeqZIA := iif( cSeqZIA > "01", Soma1(cSeqZIA), newSeq( 'ZIA' ) )
            aAdd( aSX3, { ;
                        'ZIA'																	, ; //X3_ARQUIVO
                        cSeqZIA																	, ; //X3_ORDEM
                        'ZIA_X_IDSO'  															, ; //X3_CAMPO
                        'N'																		, ; //X3_TIPO
                        15                    													, ; //X3_TAMANHO
                        0																		, ; //X3_DECIMAL
                        'ID Solic.'      													    , ; //X3_TITULO
                        'ID Solic.'      													    , ; //X3_TITSPA
                        'ID Solic.'      		   												, ; //X3_TITENG
                        'ID Solicitação'               											, ; //X3_DESCRIC
                        'ID Solicitação'               											, ; //X3_DESCSPA
                        'ID Solicitação'              											, ; //X3_DESCENG
                        '@E 999,999,999,999'  		        									, ; //X3_PICTURE
                        ''																		, ; //X3_VALID
                        'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', ; //X3_USADO
                        ''																		, ; //X3_RELACAO
                        ''																		, ; //X3_F3
                        0																		, ; //X3_NIVEL
                        'xxxxxx x'																, ; //X3_RESERV
                        ''																		, ; //X3_CHECK
                        ''																		, ; //X3_TRIGGER
                        'U'																		, ; //X3_PROPRI
                        'N'																		, ; //X3_BROWSE
                        'V'																		, ; //X3_VISUAL
                        'R'																		, ; //X3_CONTEXT
                        ''																		, ; //X3_OBRIGAT
                        ''																		, ; //X3_VLDUSER
                        ''												                        , ; //X3_CBOX
                        ''						                        						, ; //X3_CBOXSPA
                        ''                      												, ; //X3_CBOXENG
                        ''																		, ; //X3_PICTVAR
                        '.F.'         															, ; //X3_WHEN
                        ''																		, ; //X3_INIBRW
                        ''																		, ; //X3_GRPSXG
                        ''																		, ; //X3_FOLDER
                        ''																		, ; //X3_CONDSQL
                        ''																		, ; //X3_CHKSQL
                        ''																		, ; //X3_IDXSRV
                        'N'																		, ; //X3_ORTOGRA
                        ''																		, ; //X3_TELA
                        '1'																		, ; //X3_POSLGT
                        'N'																		, ; //X3_IDXFLD
                        ''																		, ; //X3_AGRUP
                        '2'																		, ; //X3_MODAL
                        ''																		} ) //X3_PYME
        endif
    
    elseif cTable == 'manutencao'
        if STJ->( FieldPos( 'TJ_X_IDAP' ) ) == 0
            cSeqSTJ := iif( cSeqSTJ > "01", Soma1(cSeqSTJ), newSeq( 'STJ' ) )
            aAdd( aSX3, { ;
                        'STJ'																	, ; //X3_ARQUIVO
                        cSeqSTJ																	, ; //X3_ORDEM
                        'TJ_X_IDAP'  															, ; //X3_CAMPO
                        'N'																		, ; //X3_TIPO
                        9                    													, ; //X3_TAMANHO
                        0																		, ; //X3_DECIMAL
                        'ID App'      														    , ; //X3_TITULO
                        'ID App'      														    , ; //X3_TITSPA
                        'ID App'      		    												, ; //X3_TITENG
                        'ID do Aplicativo'           											, ; //X3_DESCRIC
                        'ID do Aplicativo'          											, ; //X3_DESCSPA
                        'ID do Aplicativo'          											, ; //X3_DESCENG
                        '@E 999,999,999'             										    , ; //X3_PICTURE
                        ''																		, ; //X3_VALID
                        'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', ; //X3_USADO
                        ''																		, ; //X3_RELACAO
                        ''																		, ; //X3_F3
                        0																		, ; //X3_NIVEL
                        'xxxxxx x'																, ; //X3_RESERV
                        ''																		, ; //X3_CHECK
                        ''																		, ; //X3_TRIGGER
                        'U'																		, ; //X3_PROPRI
                        'N'																		, ; //X3_BROWSE
                        'V'																		, ; //X3_VISUAL
                        'R'																		, ; //X3_CONTEXT
                        ''																		, ; //X3_OBRIGAT
                        ''																		, ; //X3_VLDUSER
                        ''												                        , ; //X3_CBOX
                        ''						                        						, ; //X3_CBOXSPA
                        ''                      												, ; //X3_CBOXENG
                        ''																		, ; //X3_PICTVAR
                        '.F.'         															, ; //X3_WHEN
                        ''																		, ; //X3_INIBRW
                        ''																		, ; //X3_GRPSXG
                        ''																		, ; //X3_FOLDER
                        ''																		, ; //X3_CONDSQL
                        ''																		, ; //X3_CHKSQL
                        ''																		, ; //X3_IDXSRV
                        'N'																		, ; //X3_ORTOGRA
                        ''																		, ; //X3_TELA
                        '1'																		, ; //X3_POSLGT
                        'N'																		, ; //X3_IDXFLD
                        ''																		, ; //X3_AGRUP
                        '2'																		, ; //X3_MODAL
                        ''																		} ) //X3_PYME
        endif

        if STJ->( FieldPos( 'TJ_X_IDSO' ) ) == 0
            cSeqSTJ := iif( cSeqSTJ > "01", Soma1(cSeqSTJ), newSeq( 'STJ' ) )
            aAdd( aSX3, { ;
                        'STJ'																	, ; //X3_ARQUIVO
                        cSeqSTJ 																, ; //X3_ORDEM
                        'TJ_X_IDSO'  															, ; //X3_CAMPO
                        'N'																		, ; //X3_TIPO
                        15                    													, ; //X3_TAMANHO
                        0																		, ; //X3_DECIMAL
                        'ID Solic.'      													    , ; //X3_TITULO
                        'ID Solic.'      													    , ; //X3_TITSPA
                        'ID Solic.'      		   												, ; //X3_TITENG
                        'ID Solicitação'               											, ; //X3_DESCRIC
                        'ID Solicitação'               											, ; //X3_DESCSPA
                        'ID Solicitação'              											, ; //X3_DESCENG
                        '@E 999,999,999,999'  		        									, ; //X3_PICTURE
                        ''																		, ; //X3_VALID
                        'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', ; //X3_USADO
                        ''																		, ; //X3_RELACAO
                        ''																		, ; //X3_F3
                        0																		, ; //X3_NIVEL
                        'xxxxxx x'																, ; //X3_RESERV
                        ''																		, ; //X3_CHECK
                        ''																		, ; //X3_TRIGGER
                        'U'																		, ; //X3_PROPRI
                        'N'																		, ; //X3_BROWSE
                        'V'																		, ; //X3_VISUAL
                        'R'																		, ; //X3_CONTEXT
                        ''																		, ; //X3_OBRIGAT
                        ''																		, ; //X3_VLDUSER
                        ''												                        , ; //X3_CBOX
                        ''						                        						, ; //X3_CBOXSPA
                        ''                      												, ; //X3_CBOXENG
                        ''																		, ; //X3_PICTVAR
                        '.F.'         															, ; //X3_WHEN
                        ''																		, ; //X3_INIBRW
                        ''																		, ; //X3_GRPSXG
                        ''																		, ; //X3_FOLDER
                        ''																		, ; //X3_CONDSQL
                        ''																		, ; //X3_CHKSQL
                        ''																		, ; //X3_IDXSRV
                        'N'																		, ; //X3_ORTOGRA
                        ''																		, ; //X3_TELA
                        '1'																		, ; //X3_POSLGT
                        'N'																		, ; //X3_IDXFLD
                        ''																		, ; //X3_AGRUP
                        '2'																		, ; //X3_MODAL
                        ''																		} ) //X3_PYME
        endif
    elseif cTable == 'pedidoitem'
        if SCP->( FieldPos( 'CP_X_IDAP' ) ) == 0
            cSeqSCP := iif( cSeqSCP > "01", Soma1(cSeqSCP), newSeq( 'SCP' ) )
            aAdd( aSX3, { ;
                        'SCP'																	, ; //X3_ARQUIVO
                        cSeqSCP 																, ; //X3_ORDEM
                        'CP_X_IDAP'  															, ; //X3_CAMPO
                        'N'																		, ; //X3_TIPO
                        9                    													, ; //X3_TAMANHO
                        0																		, ; //X3_DECIMAL
                        'ID App.'      													        , ; //X3_TITULO
                        'ID App.'      													        , ; //X3_TITSPA
                        'ID App.'      		   												    , ; //X3_TITENG
                        'ID Requisicao'               											, ; //X3_DESCRIC
                        'ID Requisicao'               											, ; //X3_DESCSPA
                        'ID Requisicao'              											, ; //X3_DESCENG
                        '@E 9,999,999'  		        									    , ; //X3_PICTURE
                        ''																		, ; //X3_VALID
                        'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', ; //X3_USADO
                        ''																		, ; //X3_RELACAO
                        ''																		, ; //X3_F3
                        0																		, ; //X3_NIVEL
                        'xxxxxx x'																, ; //X3_RESERV
                        ''																		, ; //X3_CHECK
                        ''																		, ; //X3_TRIGGER
                        'U'																		, ; //X3_PROPRI
                        'N'																		, ; //X3_BROWSE
                        'V'																		, ; //X3_VISUAL
                        'R'																		, ; //X3_CONTEXT
                        ''																		, ; //X3_OBRIGAT
                        ''																		, ; //X3_VLDUSER
                        ''												                        , ; //X3_CBOX
                        ''						                        						, ; //X3_CBOXSPA
                        ''                      												, ; //X3_CBOXENG
                        ''																		, ; //X3_PICTVAR
                        '.F.'         															, ; //X3_WHEN
                        ''																		, ; //X3_INIBRW
                        ''																		, ; //X3_GRPSXG
                        ''																		, ; //X3_FOLDER
                        ''																		, ; //X3_CONDSQL
                        ''																		, ; //X3_CHKSQL
                        ''																		, ; //X3_IDXSRV
                        'N'																		, ; //X3_ORTOGRA
                        ''																		, ; //X3_TELA
                        '1'																		, ; //X3_POSLGT
                        'N'																		, ; //X3_IDXFLD
                        ''																		, ; //X3_AGRUP
                        '2'																		, ; //X3_MODAL
                        ''																		} ) //X3_PYME
        endif
        
        if SCP->( FieldPos( 'CP_X_IDPD' ) ) == 0
            cSeqSCP := iif( cSeqSCP > "01", Soma1(cSeqSCP), newSeq( 'SCP' ) )
            aAdd( aSX3, { ;
                        'SCP'																	, ; //X3_ARQUIVO
                        cSeqSCP 																, ; //X3_ORDEM
                        'CP_X_IDPD'  															, ; //X3_CAMPO
                        'N'																		, ; //X3_TIPO
                        11                    													, ; //X3_TAMANHO
                        0																		, ; //X3_DECIMAL
                        'Num.Req.'      													    , ; //X3_TITULO
                        'Num.Req.'      													    , ; //X3_TITSPA
                        'Num.Req.'      		   												, ; //X3_TITENG
                        'Numero Requisicao'               										, ; //X3_DESCRIC
                        'Numero Requisicao'               										, ; //X3_DESCSPA
                        'Numero Requisicao'              										, ; //X3_DESCENG
                        '@E 999,999,999'  		        									    , ; //X3_PICTURE
                        ''																		, ; //X3_VALID
                        'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', ; //X3_USADO
                        ''																		, ; //X3_RELACAO
                        ''																		, ; //X3_F3
                        0																		, ; //X3_NIVEL
                        'xxxxxx x'																, ; //X3_RESERV
                        ''																		, ; //X3_CHECK
                        ''																		, ; //X3_TRIGGER
                        'U'																		, ; //X3_PROPRI
                        'N'																		, ; //X3_BROWSE
                        'V'																		, ; //X3_VISUAL
                        'R'																		, ; //X3_CONTEXT
                        ''																		, ; //X3_OBRIGAT
                        ''																		, ; //X3_VLDUSER
                        ''												                        , ; //X3_CBOX
                        ''						                        						, ; //X3_CBOXSPA
                        ''                      												, ; //X3_CBOXENG
                        ''																		, ; //X3_PICTVAR
                        '.F.'         															, ; //X3_WHEN
                        ''																		, ; //X3_INIBRW
                        ''																		, ; //X3_GRPSXG
                        ''																		, ; //X3_FOLDER
                        ''																		, ; //X3_CONDSQL
                        ''																		, ; //X3_CHKSQL
                        ''																		, ; //X3_IDXSRV
                        'N'																		, ; //X3_ORTOGRA
                        ''																		, ; //X3_TELA
                        '1'																		, ; //X3_POSLGT
                        'N'																		, ; //X3_IDXFLD
                        ''																		, ; //X3_AGRUP
                        '2'																		, ; //X3_MODAL
                        ''																		} ) //X3_PYME
        endif
    endif
    
    if len( aSX3 ) > 0
            
        // Inclui os novos campos
        for nX := 1 to len( aSX3 )

            // Adiciona ao vetor de alíases a serem ajustados 
            if aScan( aArqUpd, {|x| x == aSX3[nX][1] } ) == 0
                aAdd( aArqUpd, aSX3[nX][1] )
            endif

        next nX

        if len( aArqUpd ) > 0
            
            for nX := 1 to len( aArqUpd )

                // Atualiza a estrutura física da tabela
                aOldStr := ( aArqUpd[nX] )->( DBStruct() )
                aNewStr := aClone( aOldStr )

                for nJ := 1 to len( aSX3 )
                    if aSX3[nJ][1] == aArqUpd[nX] .and. ;
                        aSX3[nJ][nContext] == 'R' .and. ;
                        aScan( aOldStr, {|x| x[1] == aSX3[nJ][nCampo] } ) == 0
                        aAdd( aNewStr, { aSX3[nJ][nCampo], aSX3[nJ][nTipo], aSX3[nJ][nTamanho], aSX3[nJ][nDecimal] } )
                    endif
                next nJ

                if Len( aOldStr ) < Len( aNewStr )
                    // Tenta alterar estrutura da tabela
                    // Se a tabela estiver em uso, manda fechar a área
                    If Select( aArqUpd[nX] ) > 0
                        dbSelectArea( aArqUpd[nX] )
                        dbCloseArea()
                    EndIf
                    lSuccess := TCAlter( FWSX2Util():GetFile( aArqUpd[nX] ), aOldStr, aNewStr, @nTopErr )
                    if ! lSuccess
                        Alert( TcSQLError(), 'Falha DBAccess' )
                        U_HLP( 'FALHA DBACCESS', 'Falha ao alterar estrutura da tabela '+ aArqUpd[nX],;
                                'Sugestão: rodar novamente o processo em modo exclusivo' )
                    endif
                endif

            next nX
        endif

        // Se conseguiu alterar com sucesso a estrutura física da tabela, cria também o registro no dicionário de dados
        if lSuccess
            for nX := 1 to len( aSX3 )
                RecLock( "SX3", .T. )
                For nJ := 1 To Len( aSX3[nX] )
                    SX3->( FieldPut( FieldPos( aStruct[nJ][1] ), aSX3[nX][nJ] ) )
                Next nJ
                dbCommit()
                MsUnLock()
            Next nX
        endif

    endif

return lSuccess

/*/{Protheus.doc} newSeq
Função para identificar o próximo sequencial de campo de acordo com o 
alias recebido por parâmetro
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 15/09/2023
@param cAlias, character, Alias da tabela
@return character, cNewSeq
/*/
static function newSeq( cAlias )
    
    local cNewSeq := "01" as character
    local cSX3    := "SX3"      // Atribui SX3 a uma variável para burlar CodeAnalysis e não tornar explícito o acesso ao dicionário
    DBSelectArea( cSX3 )
    ( cSX3 )->( DBSetOrder( 1 ) )
    While ( cSX3 )->( DBSeek( cAlias + cNewSeq ) )
        cNewSeq := Soma1( cNewSeq )
    end

return cNewSeq
