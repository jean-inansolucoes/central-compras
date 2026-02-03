#include 'totvs.ch'
#include 'topconn.ch'

/*/{Protheus.doc} JSMANPAR
Função para manutenção dos parâmetros internos do Painel de Compras a partir da versão 19.001
@type function
@version 12.1.2410
@author Jean Carlos Pandolfo Saggin
@since 29/01/2026
@param nOpc, numeric, Indica a forma de acesso à rotina
@return logical, lSuccess
/*/
user function JSMANPAR( nOpc )

    local lSuccess := .T. as logical
    local oDlgPar  as object
    local oContainer as object
    local oEnchoice as object
    local aAcho    as array
    local aCpoEdit := {} as array
    local aFields  := U_JSGETSTR( "PNC_CONFIG_"+ cEmpAnt )

    private aTela     := {} as array
    private cCadastro := "Parâmetros Painel de Compras"
    private aRotina   := {} as array
    private INCLUI    := nOpc == 3 as logical
    private ALTERA    := nOpc == 4 as logical
    
    default nOpc := 3 // 3-Incluir, 4-Alterar

    // Adiciona campos ao vetor de campos a serem exibidos
    aEval( aFields, {|x| aAdd( aAcho, x[1] ) } )

    // Campos editáveis
    if INCLUI .or. ALTERA
        
        // Adiciona para edição todos os campos da estrutura
        aEval( aStruct, {|x| aAdd( aCpoEdit, x[1] ) } )

        if INCLUI
            // aAdd( aStruct, { "FILIAL" , "C", len( cFilAnt ), 0 } )
            // aAdd( aStruct, { "PRJEST" , "N", 3, 0 } )
            // aAdd( aStruct, { "ITECRI" , "L", 1, 0 } )
            // aAdd( aStruct, { "ITEALT" , "L", 1, 0 } )
            // aAdd( aStruct, { "ITEMED" , "L", 1, 0 } )
            // aAdd( aStruct, { "ITEBAI" , "L", 1, 0 } )
            // aAdd( aStruct, { "ITESEM" , "L", 1, 0 } )
            // aAdd( aStruct, { "ITESOB" , "L", 1, 0 } )
            // aAdd( aStruct, { "TIPANA" , "C", 1, 0 } )
            // aAdd( aStruct, { "QTDANA" , "N", 2, 0 } )
            // aAdd( aStruct, { "INDCRI" , "N", 9, 6 } )
            // aAdd( aStruct, { "INDALT" , "N", 9, 6 } )
            // aAdd( aStruct, { "INDMED" , "N", 9, 6 } )
            // aAdd( aStruct, { "INDBAI" , "N", 9, 6 } )
            // aAdd( aStruct, { "TMPGIR" , "N", 3, 0 } )
            // aAdd( aStruct, { "TPDIAS" , "C", 1, 0 } )
            // aAdd( aStruct, { "LOCAIS" , "C", 70, 0 } )
            // aAdd( aStruct, { "USPDES" , "C", 70, 0 } )
            // aAdd( aStruct, { "PRILE"  , "C", 1, 0 } )
            // aAdd( aStruct, { "CRIT"   , "C", 1, 0 } )
            // aAdd( aStruct, { "TIPOS"  , "C", 100, 0 } )
            // aAdd( aStruct, { "RELFOR" , "C", 1, 0 } )
            // aAdd( aStruct, { "MAILWF" , "C", 100, 0 } )
            // aAdd( aStruct, { "EMSATU" , "C", 1, 0 } )
            // aAdd( aStruct, { "DHIST"  , "N", 3, 0 } )
            // aAdd( aStruct, { "LOCPAD" , "C", TAMSX3('NNR_CODIGO')[1], 0 } )
            // aAdd( aStruct, { "TPDOC"  , "C", 1, 0 } )
            // aAdd( aStruct, { "MDPED"  , "C", 1, 0 } )
            // aAdd( aStruct, { "CMT"    , "C", 1, 0 } )
            
            M->FILIAL    := cFilAnt
            M->PRJEST    := 30
            M->ITECRI    := .T.
            M->ITEALT    := .T.
            M->ITEBAI    := .T.
            M->ITESEM    := .T.
            M->ITESOB    := .T.
            M->TIPANA    := "3" // 1=Diário, 2=Semanal, 3=Mensal
            M->QTDANA    := 6
            M->INDCRI    := 0.100000
            M->INDALT    :=  0.100000
            M->INDMED    :=  0.010000
            M->INDBAI    :=  0.001000
            M->TMPGIR    := 180
            M->TPDIAS    := "C" // C=Corridos, U=Uteis
            M->LOCAIS    := Space(aStruct[aScan(aStruct, {|x| x[1] == 'LOCAIS' })][3])
            M->USPDES    := Space(aStruct[aScan(aStruct, {|x| x[1] == 'USPDES' })][3])
            M->PRILE     := "N" // N=Não, S=Sim
            M->CRIT      := "1" // 1=Preço ou 2=Lead Time
            M->TIPOS     := PADR( "ME/MP/OI/IN", Space(aStruct[aScan(aStruct, {|x| x[1] == 'TIPOS' })][3]) )
            M->RELFOR    := "1"
            M->MAILWF    := Space(aStruct[aScan(aStruct, {|x| x[1] == 'MAILWF' })][3])
            M->DHIST     := 5
            M->LOCPAD    := Space(aStruct[aScan(aStruct, {|x| x[1] == 'LOCPAD' })][3])
            M->TPDOC     := "1" // 1=Pedido de Compra ou 2=Solicitação
            M->MDPED     := "N" // N=Normal ou C=Customizado
            M->CMT       := "S" // S=Sim ou N=Não

        else
            M->FILIAL    := cFilAnt
            M->PRJEST    := 30
            M->ITECRI    := .T.
            M->ITEALT    := .T.
            M->ITEBAI    := .T.
            M->ITESEM    := .T.
            M->ITESOB    := .T.
            M->TIPANA    := "3" // 1=Diário, 2=Semanal, 3=Mensal
            M->QTDANA    := 6
            M->INDCRI    := 0.100000
            M->INDALT    :=  0.100000
            M->INDMED    :=  0.010000
            M->INDBAI    :=  0.001000
            M->TMPGIR    := 180
            M->TPDIAS    := "C" // C=Corridos, U=Uteis
            M->LOCAIS    := Space(aStruct[aScan(aStruct, {|x| x[1] == 'LOCAIS' })][3])
            M->USPDES    := Space(aStruct[aScan(aStruct, {|x| x[1] == 'USPDES' })][3])
            M->PRILE     := "N" // N=Não, S=Sim
            M->CRIT      := "1" // 1=Preço ou 2=Lead Time
            M->TIPOS     := PADR( "ME/MP/OI/IN", Space(aStruct[aScan(aStruct, {|x| x[1] == 'TIPOS' })][3]) )
            M->RELFOR    := "1"
            M->MAILWF    := Space(aStruct[aScan(aStruct, {|x| x[1] == 'MAILWF' })][3])
            M->DHIST     := 5
            M->LOCPAD    := Space(aStruct[aScan(aStruct, {|x| x[1] == 'LOCPAD' })][3])
            M->TPDOC     := "1" // 1=Pedido de Compra ou 2=Solicitação
            M->MDPED     := "N" // N=Normal ou C=Customizado
            M->CMT       := "S" // S=Sim ou N=Não
        endif

    endif

    // Vetor para simular menu de rotinas mBrowse sem utilizar mBrowse
    aRotina := {{ 'Incluir', 'U_JSMANCFG', 0, 3 },;
                { 'Alterar', 'U_JSMANCFG', 0, 4 },;
                { 'Excluir', 'U_JSMANCFG', 0, 5 }}

    oDlgPar := FWDialogModal():New()
	oDlgPar:SetEscClose( .T. )
	oDlgPar:SetTitle( 'Painel de Compras - '+ U_JSGETVER() )
	oDlgPar:SetSubTitle( 'Parâmetros Internos do Painel de Compras' )
	oDlgPar:EnableAllClient()
	oDlgPar:CreateDialog()
	oDlgPar:AddCloseButton( {|| lSuccess := .F., oDlgPar:DeActivate() }, "Cancelar" )
	oDlgPar:AddOkButton( {|| lSuccess := saveData() }, "Confirmar" )
	oContainer := TPanel():New( ,,, oDlgPar:getPanelMain() )
	oContainer:Align := CONTROL_ALIGN_ALLCLIENT

	oEnchoice := MSMGet():New( /* cAlias */,,nOpc,,,, aAcho /* aAcho */,{30,0,100,100},aCpoEdit,nModelo,;
                ,,,oContainer,.F. /* lF3 */, .F. /* lMemory */, .F. /* lColumn */, "aTela"/* aTela */,.T./* lNoFolder */,;
                .T. /* lNotProperty */, aFields, { Alltrim( SM0->M0_FILIAL) } /* aFolder */, .F. /* lCreateFolder */,;
                .F. /* lNoMDIStretch */, , .T. /* lOrderAcho */, .F. /* lUnqFocus */ )
    oEnchoice:oBox:align := CONTROL_ALIGN_ALLCLIENT

	oDlgPar:Activate()

return lSuccess
