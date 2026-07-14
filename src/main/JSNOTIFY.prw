#include 'totvs.ch'
#include 'topconn.ch'

#define EOL         chr(13)+chr(10)
#define MASTER_PWD  ";Aaerjgoe));1"   // Senha do mantenedor (hardcoded, igual para todos os clientes)

// Índices do vetor de trabalho de cada notificação exibida no wizard
#define NF_ID       1    // ID da notificação (tabela NOTIFICATION)
#define NF_TITLE    2    // Título
#define NF_BODY     3    // Corpo (HTML)
#define NF_CTRLID   4    // ID do registro de controle (0 = ainda não gravado)
#define NF_DTREAD   5    // Data/hora da primeira leitura (mantida em atualizações)
#define NF_NOTSHOW  6    // Estado atual do NOTSHOWAGAIN em memória (preservado no "Ver anterior")

/*/{Protheus.doc} JSNOTIFY
Central de Notificações do SmartSupply. Após a checagem de contrato ativo, consulta no
Supabase as notificações direcionadas ao usuário/empresa/versão corrente e as exibe em um
wizard (FWDialogModal + TWebEngine), respeitando o controle de leitura por usuário.
@type function
@author Jean Carlos Pandolfo Saggin
@since 02/07/2026
/*/
User Function JSNOTIFY()

    Local aNotify  := {} as array
    Local nCompany := 0  as numeric
    Local cUser    := AllTrim( RetCodUsr() ) as character
    Local cCurVer  := getCmpVer() as character

    // Identifica a empresa (COMPANYID) do cliente a partir do CNPJ da SM0
    nCompany := getCompanyId()
    If nCompany <= 0
        Return nil
    EndIf

    // Carrega as notificações aplicáveis (já sem as marcadas para não exibir novamente)
    aNotify := loadNotify( nCompany, cUser, cCurVer )
    If Len( aNotify ) == 0
        Return nil
    EndIf

    showWizard( aNotify, nCompany, cUser, cCurVer )

Return nil

/*/{Protheus.doc} JSNOTREG
Tela oculta (mantenedor) para cadastro de notificações, protegida por senha hardcoded.
Acionada por atalho de teclado (Ctrl+F11) a partir do painel principal do SmartSupply.
@type function
@author Jean Carlos Pandolfo Saggin
@since 02/07/2026
/*/
User Function JSNOTREG()

    // Recurso oculto: em caso de senha inválida, encerra silenciosamente
    If ! askPwd()
        Return nil
    EndIf

    regForm()

Return nil

/*/{Protheus.doc} getCompanyId
Obtém o ID da empresa (COMPANYID) no Supabase a partir do CNPJ raiz da SM0.
@type function
@author Jean Carlos Pandolfo Saggin
@since 02/07/2026
@return numeric, nId
/*/
Static Function getCompanyId()

    Local nId     := 0 as numeric
    Local oResult as object
    Local cCGC    := StrTran( SubStr( SM0->M0_CGC, 1, 8 ), "        ", "99999999" ) as character
    Local cWhere  := "CGCCPF=eq."+ cCGC +"&DELETED=eq.N" as character

    oResult := U_JSSUPABASE( "GET", "CUSTOMER", { "ID" }, cWhere )
    If ValType( oResult ) == 'J' .And. Len( oResult ) > 0
        nId := oResult[1]["ID"]
    EndIf
    oResult := Nil

Return nId

/*/{Protheus.doc} getCmpVer
Retorna a versão corrente em formato comparável ("NN.NNNN"), extraindo apenas o prefixo
da versão retornada por U_JSGETVER() (que inclui a data entre parênteses).
@type function
@author Jean Carlos Pandolfo Saggin
@since 02/07/2026
@return character, cVerAtu
/*/
Static Function getCmpVer()

    Local cVerAtu := U_JSGETVER()
    Local nPos := At( " ", cVerAtu ) as numeric

    If nPos > 0
        cVerAtu := SubStr( cVerAtu, 1, nPos - 1 )
    EndIf

Return AllTrim( cVerAtu )

/*/{Protheus.doc} jChr
Converte um valor obtido de um JSON em caractere de forma segura (null -> "").
@type function
@author Jean Carlos Pandolfo Saggin
@since 02/07/2026
@param xVal, variant, valor lido do Json
@return character, cRet
/*/
Static Function jChr( xVal )

    Local cRet := "" as character

    If ValType( xVal ) == 'C'
        cRet := xVal
    EndIf

Return cRet

/*/{Protheus.doc} inScope
Avalia se a notificação se aplica ao usuário considerando escopo de versão e usuário.
Campo vazio/nulo significa "aplica-se a todos". A empresa é filtrada no servidor.
@type function
@author Jean Carlos Pandolfo Saggin
@since 02/07/2026
@param cNotVer, character, versão cadastrada na notificação
@param cNotUser, character, usuário cadastrado na notificação
@param cCurVer, character, versão corrente em uso
@param cUser, character, código do usuário logado
@return logical, lOk
/*/
Static Function inScope( cNotVer, cNotUser, cCurVer, cUser )

    Local lOk := .T. as logical

    // Escopo de versão: exibe quando a versão em uso for igual/superior à cadastrada
    If ! Empty( cNotVer ) .And. cCurVer < AllTrim( cNotVer )
        lOk := .F.
    EndIf

    // Escopo de usuário: exibe quando vazio (todos) ou igual ao usuário logado
    If lOk .And. ! Empty( cNotUser ) .And. AllTrim( cNotUser ) != AllTrim( cUser )
        lOk := .F.
    EndIf

Return lOk

/*/{Protheus.doc} scanCtrl
Localiza no vetor de controle (retorno do Supabase) o registro de uma notificação.
@type function
@author Jean Carlos Pandolfo Saggin
@since 02/07/2026
@param oCtrl, object, coleção Json de registros de controle
@param nNotId, numeric, ID da notificação procurada
@return numeric, nRet
/*/
Static Function scanCtrl( oCtrl, nNotId )

    Local nRet := 0 as numeric
    Local nJ   := 0 as numeric

    For nJ := 1 To Len( oCtrl )
        If oCtrl[nJ]["NOTIFYID"] == nNotId
            nRet := nJ
            Exit
        EndIf
    Next nJ

Return nRet

/*/{Protheus.doc} loadNotify
Carrega as notificações aplicáveis ao usuário. Filtra a empresa no servidor (COMPANYID =
empresa OU nulo) e refina versão/usuário e "não mostrar novamente" no cliente, cruzando
com a tabela de controle NOTIFICATION_READ.
@type function
@author Jean Carlos Pandolfo Saggin
@since 02/07/2026
@param nCompany, numeric, ID da empresa
@param cUser, character, código do usuário logado
@param cCurVer, character, versão corrente
@return array, aRows
/*/
Static Function loadNotify( nCompany, cUser, cCurVer )

    Local aRows   := {} as array
    Local oNot    as object
    Local oCtrl   as object
    Local nI      := 0 as numeric
    Local nCtrl   := 0 as numeric
    Local nCtrlId := 0 as numeric
    Local cDtRead := "" as character
    Local lMuted  := .F. as logical
    Local xShow   as variant
    Local nNotId  := 0 as numeric
    Local cWhereN := "or=(COMPANYID.eq."+ AllTrim( cValToChar( nCompany ) ) +",COMPANYID.is.null)&DELETED=eq.N" as character
    Local cWhereC := "COMPANYID=eq."+ AllTrim( cValToChar( nCompany ) ) +"&USERID=eq."+ AllTrim( cUser ) as character
    Local aFldsN  := { "ID", "TITLE", "BODY", "VERSION", "USERID" } as array
    Local aFldsC  := { "ID", "NOTIFYID", "NOTSHOWAGAIN", "DTREAD" } as array

    oNot := U_JSSUPABASE( "GET", "NOTIFICATION", aFldsN, cWhereN, /*aData*/, "CREATED.asc" )
    If ValType( oNot ) != 'J' .Or. Len( oNot ) == 0
        Return aRows
    EndIf

    // Registros de controle do usuário nesta empresa
    oCtrl := U_JSSUPABASE( "GET", "NOTIFICATION_READ", aFldsC, cWhereC )

    For nI := 1 To Len( oNot )

        nNotId  := oNot[nI]["ID"]
        nCtrlId := 0
        cDtRead := ""
        lMuted  := .F.

        If ValType( oCtrl ) == 'J'
            nCtrl := scanCtrl( oCtrl, nNotId )
            If nCtrl > 0
                nCtrlId := oCtrl[nCtrl]["ID"]
                cDtRead := jChr( oCtrl[nCtrl]["DTREAD"] )
                xShow   := oCtrl[nCtrl]["NOTSHOWAGAIN"]
                If ValType( xShow ) == 'L' .And. xShow
                    lMuted := .T.
                EndIf
            EndIf
        EndIf

        If ! lMuted .And. inScope( jChr( oNot[nI]["VERSION"] ), jChr( oNot[nI]["USERID"] ), cCurVer, cUser )
            aAdd( aRows, { nNotId, jChr( oNot[nI]["TITLE"] ), jChr( oNot[nI]["BODY"] ), nCtrlId, cDtRead, .F. } )
        EndIf

    Next nI

    oNot  := Nil
    oCtrl := Nil

Return aRows

/*/{Protheus.doc} showWizard
Exibe as notificações em um FWDialogModal (wizard) com TWebEngine para renderizar o HTML
do corpo. Botões: Ver anterior, Ver depois e Marcar como lido.
@type function
@author Jean Carlos Pandolfo Saggin
@since 02/07/2026
@param aRows, array, notificações a exibir
@param nCompany, numeric, ID da empresa
@param cUser, character, código do usuário
@param cCurVer, character, versão corrente
/*/
Static Function showWizard( aRows, nCompany, cUser, cCurVer )

    Local oDlg     as object
    Local oPanel   as object
    Local oChannel as object
    Local aButtons := {} as array
    local nPort    := 0 as numeric

    Private oWeb     as object
    Private aWiz    := aRows as array
    Private nCur    := 1 as numeric
    Private nCmpNot := nCompany as numeric
    Private cUsrNot := cUser as character
    Private cVerNot := cCurVer as character
    Private oWebNot as object
    Private oDlgNot as object

    aAdd( aButtons, { , "Ver anterior",     {|| btnPrev() },  "Volta para a notificação anterior (atualiza a leitura)", , .T., .T. } )
    aAdd( aButtons, { , "Ver depois",       {|| btnLater() }, "Registra a leitura e avança mantendo a notificação visível", , .T., .T. } )
    aAdd( aButtons, { , "Marcar como lido", {|| btnRead() },  "Marca como lida e não exibe novamente", , .T., .T. } )

    oDlg := FWDialogModal():New()
    oDlg:SetEscClose( .F. )
    oDlg:SetTitle( "SmartSupply - Central de Notificações - "+ U_JSGETVER() )
    oDlg:SetSubTitle( subTitle() )
    oDlg:SetInitBlock( {|| renderCur() } )
    oDlg:SetSize( (MsAdvSize()[6]/2)*0.9, (MsAdvSize()[5]/2)*0.9 )	// 90% da resolucao da tela (altura, largura)
    oDlg:EnableFormBar( .T. )
    oDlg:CreateDialog()
    oDlg:AddCloseButton( {|| oDlgNot:DeActivate() }, "Fechar" )
    oDlg:AddButtons( aButtons )

    oDlgNot := oDlg
    oPanel  := oDlg:GetPanelMain()

    // Canal Web (WebSocket) exigido para renderizar HTML no WebApp
    oChannel := TWebChannel():New()
    nPort := oChannel:connect()

    oWeb := TWebEngine():New( oPanel, 0, 0, 100, 100, /*cUrl*/, nPort )
    oWeb:Align := CONTROL_ALIGN_ALLCLIENT
    oWeb:bLoadFinished := {|self,url| conout("Termino da carga do pagina: " + url ) }
    oDlg:Activate()

    oWebNot  := Nil
    oChannel:disconnect()
    FreeObj( oChannel )
    oChannel := Nil

Return nil

/*/{Protheus.doc} subTitle
Subtítulo fixo do wizard de notificações.
@type function
@author Jean Carlos Pandolfo Saggin
@since 02/07/2026
@return character, cReturn
/*/
Static Function subTitle()
Return "Comunicados e novidades do SmartSupply"

/*/{Protheus.doc} renderCur
Renderiza a notificação corrente injetando o HTML diretamente no TWebEngine via SetHtml.
@type function
@author Jean Carlos Pandolfo Saggin
@since 02/07/2026
/*/
Static Function renderCur()

    // Injeta o HTML diretamente no motor de renderização, sem gravar arquivo temporário
    oWeb:SetHtml( buildHtml( aWiz[nCur][NF_TITLE], aWiz[nCur][NF_BODY] ) )

Return nil

/*/{Protheus.doc} buildHtml
Monta o documento HTML (chrome ASCII + conteúdo UTF-8 vindo do Supabase).
@type function
@author Jean Carlos Pandolfo Saggin
@since 02/07/2026
@param cTitle, character, título da notificação
@param cBody, character, corpo HTML da notificação
@return character, cHtml
/*/
Static Function buildHtml( cTitle, cBody )

    Local cHtml := "" as character
    Local cPos  := AllTrim( cValToChar( nCur ) ) +" de "+ AllTrim( cValToChar( Len( aWiz ) ) ) as character

    cHtml += '<!DOCTYPE html>'+ EOL
    cHtml += '<html lang="pt-BR"><head><meta charset="utf-8">'+ EOL
    cHtml += '<meta name="viewport" content="width=device-width, initial-scale=1">'+ EOL
    cHtml += '<style>'+ EOL
    cHtml += 'body{font-family:"Segoe UI",Arial,sans-serif;margin:0;padding:16px;background:#eef1f4;color:#22303c;box-sizing:border-box;min-height:100vh;display:flex;align-items:center;justify-content:center;}'+ EOL	// altura dinamica: centraliza o wrap no viewport real do TWebEngine (== 90% da tela definido no SetSize)
    cHtml += '.wrap{max-width:1400px;width:95%;margin:0 auto;}'+ EOL	// dinamico: acompanha o tamanho real do FWDialogModal (90% da tela), com teto para nao esticar demais em telas ultrawide
    cHtml += '.badge{display:inline-block;font-size:12px;color:#5a6b7b;margin-bottom:8px;}'+ EOL
    cHtml += '.card{background:#fff;border-radius:10px;padding:24px;box-shadow:0 2px 8px rgba(0,0,0,.10);}'+ EOL
    cHtml += 'h1{font-size:20px;color:#0a5ab4;margin:0 0 16px;border-bottom:1px solid #e3e8ee;padding-bottom:10px;}'+ EOL
    cHtml += 'img{max-width:100%;height:auto;}'+ EOL
    cHtml += '</style></head><body><div class="wrap">'+ EOL
    cHtml += '<div class="badge">Notificacao '+ cPos +'</div>'+ EOL
    cHtml += '<div class="card"><h1>'+ cTitle +'</h1>'+ DecodeUTF8( cBody ) +'</div>'+ EOL
    cHtml += '</div></body></html>'+ EOL

Return cHtml

/*/{Protheus.doc} upsCtrl
Grava/atualiza (upsert) o controle de leitura da notificação corrente. Quando já existe
registro, atualiza via ID (merge na PK) mantendo DTREAD; senão, insere.
@type function
@author Jean Carlos Pandolfo Saggin
@since 02/07/2026
@param lNotShow, logical, conteúdo do campo NOTSHOWAGAIN
/*/
Static Function upsCtrl( lNotShow )

    Local aRow    := aWiz[nCur] as array
    Local nCtrlId := aRow[NF_CTRLID] as numeric
    Local cDtRead := aRow[NF_DTREAD] as character
    Local cNow    := StrTran( FWTimeStamp( 3 ), 'T', ' ' ) as character
    Local aFields := {} as array
    Local aData   := {} as array
    Local oResult as object

    If Empty( cDtRead )
        cDtRead := cNow
    EndIf

    If nCtrlId > 0
        aFields := { "ID", "NOTIFYID", "DTREAD", "DTLAST", "NOTSHOWAGAIN", "COMPANYID", "USERID", "VERSION" }
        aData   := { { nCtrlId, aRow[NF_ID], cDtRead, cNow, lNotShow, nCmpNot, AllTrim( cUsrNot ), cVerNot } }
    Else
        aFields := { "NOTIFYID", "DTREAD", "DTLAST", "NOTSHOWAGAIN", "COMPANYID", "USERID", "VERSION" }
        aData   := { { aRow[NF_ID], cDtRead, cNow, lNotShow, nCmpNot, AllTrim( cUsrNot ), cVerNot } }
    EndIf

    oResult := U_JSSUPABASE( "POST", "NOTIFICATION_READ", aFields, /*cWhere*/, aData )
    If ValType( oResult ) == 'J' .And. Len( oResult ) > 0
        aWiz[nCur][NF_CTRLID]  := oResult[1]["ID"]
        aWiz[nCur][NF_DTREAD]  := cDtRead
        aWiz[nCur][NF_NOTSHOW] := lNotShow
    EndIf
    oResult := Nil

Return nil

/*/{Protheus.doc} goNext
Avança para a próxima notificação ou encerra o wizard ao chegar na última.
@type function
@author Jean Carlos Pandolfo Saggin
@since 02/07/2026
/*/
Static Function goNext()

    If nCur < Len( aWiz )
        nCur++
        renderCur()
    Else
        oDlgNot:DeActivate()
    EndIf

Return nil

/*/{Protheus.doc} btnPrev
Ação "Ver anterior": volta à notificação anterior e atualiza o DTLAST dela.
@type function
@author Jean Carlos Pandolfo Saggin
@since 02/07/2026
/*/
Static Function btnPrev()

    If nCur > 1
        nCur--
        // Preserva o NOTSHOWAGAIN atual: esta ação deve atualizar apenas o DTLAST
        upsCtrl( aWiz[nCur][NF_NOTSHOW] )
        renderCur()
    EndIf

Return nil

/*/{Protheus.doc} btnLater
Ação "Ver depois": registra a leitura (NOTSHOWAGAIN=falso) e avança.
@type function
@author Jean Carlos Pandolfo Saggin
@since 02/07/2026
/*/
Static Function btnLater()

    upsCtrl( .F. )
    goNext()

Return nil

/*/{Protheus.doc} btnRead
Ação "Marcar como lido": registra a leitura (NOTSHOWAGAIN=verdadeiro) e avança.
@type function
@author Jean Carlos Pandolfo Saggin
@since 02/07/2026
/*/
Static Function btnRead()

    upsCtrl( .T. )
    goNext()

Return nil

/*/{Protheus.doc} askPwd
Solicita a senha do mantenedor e valida contra a constante hardcoded.
@type function
@author Jean Carlos Pandolfo Saggin
@since 02/07/2026
@return logical, lOk
/*/
Static Function askPwd()

    Local oDlg    as object
    Local oGetPwd as object
    Local cPwd    := Space( 30 ) as character
    Local lOk     := .F. as logical

    DEFINE MSDIALOG oDlg TITLE "SmartSupply - Área Restrita" FROM 000,000 TO 110,350 PIXEL

    @ 010,010 SAY "Senha do mantenedor:" SIZE 130,010 OF oDlg PIXEL
    @ 026,010 MSGET oGetPwd VAR cPwd SIZE 130,011 OF oDlg PIXEL
    oGetPwd:lPassword := .T.

    @ 060,110 BUTTON "Confirmar" SIZE 060,014 OF oDlg ACTION ( lOk := chkPwd( cPwd ), oDlg:End() ) PIXEL

    ACTIVATE MSDIALOG oDlg CENTERED

Return lOk

/*/{Protheus.doc} chkPwd
Compara a senha informada com a senha do mantenedor.
@type function
@author Jean Carlos Pandolfo Saggin
@since 02/07/2026
@param cPwd, character, senha informada
@return logical, lOk
/*/
Static Function chkPwd( cPwd )
Return AllTrim( cPwd ) == MASTER_PWD

/*/{Protheus.doc} regForm
Formulário de cadastro de notificação (mantenedor).
@type function
@author Jean Carlos Pandolfo Saggin
@since 02/07/2026
/*/
Static Function regForm()

    Local oDlg   as object
    Local cTitle := Space( 200 ) as character
    Local cCmp   := Space( 10 ) as character
    Local cVerAtu:= PadR( getCmpVer(), 20 ) as character
    Local cUsr   := Space( 6 ) as character
    Local cBody  := "" as character

    DEFINE MSDIALOG oDlg TITLE "SmartSupply - Cadastro de Notificação" FROM 000,000 TO 660,1040 PIXEL

    @ 008,010 SAY "Título:" SIZE 060,010 OF oDlg PIXEL
    @ 006,072 MSGET cTitle SIZE 400,011 OF oDlg PIXEL

    @ 026,010 SAY "Empresa (ID / vazio = todas):" SIZE 150,010 OF oDlg PIXEL
    @ 024,165 MSGET cCmp PICTURE "9999999999" SIZE 070,011 OF oDlg PIXEL

    @ 044,010 SAY "Versão (vazio = todas):" SIZE 150,010 OF oDlg PIXEL
    @ 042,165 MSGET cVerAtu SIZE 090,011 OF oDlg PIXEL

    @ 062,010 SAY "Usuário (vazio = todos):" SIZE 150,010 OF oDlg PIXEL
    @ 060,165 MSGET cUsr PICTURE "@!" SIZE 070,011 OF oDlg PIXEL

    @ 082,010 SAY "Corpo (HTML):" SIZE 150,010 OF oDlg PIXEL
    @ 094,010 GET cBody MEMO SIZE 462,150 OF oDlg PIXEL

    @ 255,330 BUTTON "Confirmar" SIZE 070,014 OF oDlg ACTION doSave( cTitle, cBody, cCmp, cVerAtu, cUsr, oDlg ) PIXEL
    @ 255,410 BUTTON "Cancelar"  SIZE 070,014 OF oDlg ACTION oDlg:End() PIXEL

    ACTIVATE MSDIALOG oDlg CENTERED

Return nil

/*/{Protheus.doc} doSave
Valida e grava a notificação no Supabase. Campos opcionais vazios são enviados como nulos
(null) para preservar a semântica "aplica-se a todos".
@type function
@author Jean Carlos Pandolfo Saggin
@since 02/07/2026
@param cTitle, character, título
@param cBody, character, corpo HTML
@param cCmp, character, ID da empresa (opcional)
@param cVerAtu, character, versão (opcional)
@param cUsr, character, usuário (opcional)
@param oDlg, object, diálogo a encerrar em caso de sucesso
/*/
Static Function doSave( cTitle, cBody, cCmp, cVerAtu, cUsr, oDlg )

    Local aFields := { "TITLE", "BODY" } as array
    Local aData   := {} as array
    Local aRow    := {} as array
    Local oResult as object

    If Empty( cTitle ) .Or. Empty( cBody )
        hlp( "CADASTRO", "Título e corpo são obrigatórios", "Preencha os campos obrigatórios e tente novamente" )
        Return nil
    EndIf

    aRow := { AllTrim( cTitle ), cBody }

    // Campos opcionais em branco são omitidos (Supabase grava null = "aplica-se a todos")
    If ! Empty( cCmp )
        If Val( AllTrim( cCmp ) ) <= 0
            hlp( "CADASTRO", "ID de empresa inválido", "Informe um código de empresa numérico positivo ou deixe em branco para todas" )
            Return nil
        EndIf
        aAdd( aFields, "COMPANYID" )
        aAdd( aRow, Val( AllTrim( cCmp ) ) )
    EndIf

    If ! Empty( cVerAtu )
        aAdd( aFields, "VERSION" )
        aAdd( aRow, AllTrim( cVerAtu ) ) 
    EndIf

    If ! Empty( cUsr )
        aAdd( aFields, "USERID" )
        aAdd( aRow, AllTrim( cUsr ) )
    EndIf

    aData := { aRow }

    oResult := U_JSSUPABASE( "POST", "NOTIFICATION", aFields, /*cWhere*/, aData )
    If ValType( oResult ) == 'J' .And. Len( oResult ) > 0
        hlp( "SUCESSO", "Notificação cadastrada com sucesso", "ID gerado: "+ AllTrim( cValToChar( oResult[1]["ID"] ) ) )
        oResult := Nil
        oDlg:End()
    Else
        hlp( "FALHA", "Falha ao cadastrar a notificação", "Verifique a conexão com o banco e tente novamente" )
    EndIf
    oResult := Nil

Return nil

/*/{Protheus.doc} hlp
Função facilitadora para utilização da função Help do Protheus.
@type function
@author Jean Carlos Pandolfo Saggin
@since 02/07/2026
@param cTitle, character, título da janela
@param cFail, character, informações sobre a falha
@param cHelp, character, texto de ajuda
/*/
Static Function hlp( cTitle, cFail, cHelp )
Return Help( ,, cTitle,, cFail, 1, 0, NIL, NIL, NIL, NIL, NIL, { cHelp } )
