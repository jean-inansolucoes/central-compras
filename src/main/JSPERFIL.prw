#include 'totvs.ch'

#define PFL_ARQJS   "sstwebchannel.js"   // twebchannel.js oficial da TOTVS, compilado no RPO como resource (o mesmo da tela de rótulos)
#define PFL_DIR     "/smartsupply"
#define PFL_TMP     "/smartsupply/tmp"   // Página e scripts gravados no servidor e publicados com CpyF2Web
#define PFL_MAXDES  40                   // Tamanho máximo da descrição do perfil
#define PFL_MAXFRM  250                  // Tamanho máximo da fórmula gravada (elementos separados por PFL_SEPARA)
#define PFL_SEPARA  "|"                  // Separador dos elementos da fórmula (o mesmo CSEPARA do GMPAICOM)
#define PFL_FRMPAD  "(|(|nDias|+|nLdTime|)|-|nPrjEst|)|*|nConMed"   // Fórmula padrão de fábrica (mesmo default do MV_X_PNC01)
#define PFL_F3      "PNCPFL"             // Consulta específica (SXB) do campo Perfil de Cálculo do produto (B1_X_PERCA)

// Perfil escolhido na consulta específica (U_JSPFLF3), devolvido ao campo pela expressão de retorno da consulta
// (U_JSPFLRET): estática do fonte porque a rotina que chama a consulta (ex.: cadastro de produtos) é padrão e não
// declara variável Private para o retorno, e uma Private criada aqui deixaria de existir quando a função terminasse
Static cPflRet

/*/{Protheus.doc} JSPERFIL
Cadastro dos perfis de cálculo da necessidade de compra (tabela interna PNC_PERFIL_<empresa>, fora do dicionário de
dados, única para a empresa - não é exclusiva por filial). Cada perfil tem uma descrição e uma fórmula montada com as
variáveis do motor de cálculo (U_JSPFLVAR), números, operadores e parênteses; o produto usa o perfil gravado no campo
B1_X_PERCA (vazio = perfil padrão). A interface é um HTML com JavaScript num TWebEngine dentro de um FWDialogModal,
no mesmo padrão da tela de rótulos (JSROTULO): a página, o script da tela (com o estado inicial) e o twebchannel.js
são gravados no servidor, publicados na pasta web do usuário (CpyF2Web) e abertos com navigate(); todo o JavaScript
fica em arquivos .js, porque no SmartClient HTML (WebApp) a política de segurança de conteúdo (CSP) não executa
scripts embutidos na página. Cada ação (salvar ou excluir) é gravada imediatamente e validada no servidor
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param cSel, character, perfil a exibir selecionado na abertura (padrão: perfil padrão)
@return logical, lMudou - .T. quando algum perfil foi incluído, alterado ou excluído
/*/
User Function JSPERFIL( cSel )

    Local oDlg      as object
    Local oWeb      as object
    Local aArqServ  := {} as array
    Local cLib      := "" as character
    Local cUrl      := "" as character
    Local cEstado   := "" as character
    Local cLibRmt   := "" as character
    Local nX        := 0  as numeric

    Private oPflCanal as object
    Private lPflMudou := .F. as logical
    Private lPflCarg  := .F. as logical

    Default cSel := ""

    // Tabela de perfis criada, cadastro antigo migrado e perfil padrão garantido
    If ! U_JSPFLCHK( .F. )
        Return .F.
    EndIf
    If Empty( cSel )
        cSel := U_JSPFLDEF()
    EndIf

    cLib := GetApoRes( PFL_ARQJS )
    If ValType( cLib ) != 'C' .or. Empty( cLib )
        hlp( 'PERFIS', 'O recurso '+ PFL_ARQJS +' não foi encontrado no repositório (RPO).',;
             'Compile o arquivo src/html/'+ PFL_ARQJS +' junto com os fontes do SmartSupply.' )
        Return .F.
    EndIf

    // Estado inicial (perfis, uso por produto e variáveis) montado antes da abertura e gravado no script da tela
    cEstado := pflProc( 'carga', '', cSel )

    // Canal de comunicação JavaScript x AdvPL (conectado antes da publicação/abertura da página), usado nas ações
    oPflCanal := TWebChannel():New()
    oPflCanal:bJsToAdvpl := {|oSelf, cChave, cValor| pflEvento( oSelf, cChave, cValor ) }
    oPflCanal:connect()

    cUrl := pflPublic( cLib, cEstado, @aArqServ )
    FWLogMsg( 'INFO', /*cTransactionId*/, 'SMARTSUPPLY', 'JSPERFIL', '', '01', 'Tela de perfis de cálculo: SmartClient '+ cValToChar( GetRemoteType( @cLibRmt ) ) +;
              ' ('+ AllTrim( cValToChar( cLibRmt ) ) +'), porta do canal '+ cValToChar( oPflCanal:nPort ) +', página '+ cUrl )
    If Empty( cUrl )
        hlp( 'PERFIS', 'Não foi possível publicar a tela de perfis de cálculo na pasta web do usuário.',;
             'Tente novamente. Persistindo, verifique a gravação na pasta '+ PFL_TMP +' do servidor.' )
    Else
        oDlg := FWDialogModal():New()
        oDlg:SetEscClose( .T. )
        oDlg:SetTitle( 'Perfis de Cálculo' )
        oDlg:SetSubTitle( 'Fórmulas da necessidade de compra - cadastro único da empresa, válido em todas as filiais' )
        oDlg:SetSize( 420, 680 )
        // Na inicialização da janela, só recarrega se a carga feita na criação ainda não terminou
        oDlg:SetInitBlock( {|| pflCarga( oWeb, cUrl ) } )
        oDlg:CreateDialog()
        oDlg:AddCloseButton( {|| oDlg:DeActivate() }, "Fechar" )

        oWeb := TWebEngine():New( oDlg:GetPanelMain(), 0, 0, 100, 100, /*cUrl*/, oPflCanal:nPort )
        oWeb:Align := CONTROL_ALIGN_ALLCLIENT
        oWeb:bLoadFinished := {|oEngine, cUrlCarga| lPflCarg := .T., FWLogMsg( 'INFO', /*cTransactionId*/, 'SMARTSUPPLY', 'JSPERFIL', '', '01', 'Tela de perfis de cálculo carregada no navegador: '+ cValToChar( cUrlCarga ) ) }
        oWeb:Navigate( cUrl )

        oDlg:Activate()
    EndIf

    oPflCanal:disconnect()
    FreeObj( oPflCanal )
    oPflCanal := Nil

    // Remove os arquivos gravados no servidor (as cópias da pasta web do usuário são temporárias da sessão)
    For nX := 1 To Len( aArqServ )
        FErase( aArqServ[nX] )
    Next nX

Return lPflMudou

/*/{Protheus.doc} JSPFLCHK
Prepara o cadastro de perfis de cálculo para uso: confere a tabela interna PNC_PERFIL_<empresa> e o campo do perfil no
produto (B1_X_PERCA), migra na primeira utilização os perfis do cadastro antigo (tabela do dicionário indicada no
parâmetro MV_X_PNC16, descontinuado) e garante o perfil padrão (ID 01, fórmula do MV_X_PNC01). Usada na abertura do
painel, no recálculo de índices (U_GMINDPRO), na análise reversa (U_JSREVEST), na tela de perfis e na
consulta F3 do produto; também liga ao campo B1_X_PERCA a consulta específica dos perfis (pflF3Cfg)
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param lAuto, logical, .T. em processamento sem interface (avisos só no log do servidor)
@return logical, lOk - .T. quando os perfis estão prontos para uso
/*/
User Function JSPFLCHK( lAuto )

    Local lOk    := .T. as logical
    Local cAviso := "" as character

    Default lAuto := .F.

    If SB1->( FieldPos( 'B1_X_PERCA' ) ) == 0
        lOk := .F.
        pflAviso( lAuto, 'B1_X_PERCA', 'Campo Perfil de Cálculo não identificado na tabela de produtos.',;
                  'Aplique a última atualização do dicionário de dados da rotina Painel de Compras e tente novamente.' )
    ElseIf ! TCCanOpen( pflTab() )
        // Sem interface (recálculo de índices, análise reversa), o cálculo segue com as fórmulas do cadastro antigo
        // (U_JSPFLFRM) até que o assistente de configuração crie a tabela nova
        lOk   := lAuto
        cAviso := 'A tabela de perfis de cálculo ('+ pflTab() +') ainda não foi criada neste ambiente.'
        If lAuto
            cAviso += ' O cálculo usa as fórmulas do cadastro antigo até a criação.'
        EndIf
        pflAviso( lAuto, 'PERFIS DE CALCULO', cAviso,;
                  'Acesse o assistente de configuração (Alt+F11 no painel ou U_JSGLBPAR), avance até a etapa Dicionário de Dados e conclua.' )
    Else
        // Primeira utilização: migra os perfis do cadastro antigo do dicionário
        If pflQtd() == 0
            pflMigra( lAuto )
        EndIf
        If ! pflExiste( U_JSPFLDEF() )
            pflPadrao()
        EndIf
        lOk := pflExiste( U_JSPFLDEF() )
        If ! lOk
            pflAviso( lAuto, 'PERFIS DE CALCULO', 'Não foi possível criar o perfil de cálculo padrão ('+ U_JSPFLDEF() +').',;
                      'Tente novamente em alguns instantes. Persistindo, verifique a gravação na tabela '+ pflTab() +'.' )
        EndIf
        // Consulta específica dos perfis no campo Perfil de Cálculo do produto (substitui a consulta do cadastro antigo)
        If lOk
            pflF3Cfg()
        EndIf
    EndIf

Return lOk

/*/{Protheus.doc} JSPFLFRM
Fórmula do perfil de cálculo, no formato gravado: elementos (variáveis, números, operadores e parênteses) separados por
PFL_SEPARA - o mesmo formato do cadastro antigo, interpretado por fLoadCri/fCalNec no GMPAICOM. Enquanto a tabela
interna não for criada pelo assistente de configuração, lê a fórmula do cadastro antigo (pflAntigo)
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param cId, character, ID do perfil
@return character, cFormula - vazio quando o perfil não existe
/*/
User Function JSPFLFRM( cId )

    Local cFormula := "" as character
    Local cAlias   := "" as character
    Local oExec    as object

    Default cId := ""

    If ! Empty( cId ) .and. ! TCCanOpen( pflTab() )
        // Tabela nova ainda não criada pelo assistente de configuração: fórmula do cadastro antigo
        cFormula := pflAntigo( cId )
    ElseIf ! Empty( cId )
        oExec := FwExecStatement():New( ChangeQuery( "SELECT FORMUL FROM "+ pflTab() +" WHERE ID = ? AND D_E_L_E_T_ = ' '" ) )
        oExec:SetString( 1, PadR( AllTrim( cId ), U_JSPFLTAM() ) )
        cAlias := oExec:OpenAlias()
        If ! ( cAlias )->( EOF() )
            cFormula := AllTrim( ( cAlias )->FORMUL )
        EndIf
        ( cAlias )->( DBCloseArea() )
        oExec:Destroy()
    EndIf

Return cFormula

/*/{Protheus.doc} JSPFLCBO
Itens do combo de seleção do perfil de cálculo no painel ("ID=ID - Descrição"): perfis ativos, mais o perfil
informado mesmo quando bloqueado (para continuar exibindo o perfil em uso)
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param cAtual, character, perfil em uso no painel
@return array, aItens
/*/
User Function JSPFLCBO( cAtual )

    Local aItens := {} as array
    Local cAlias := "" as character
    Local cId    := "" as character

    Default cAtual := ""

    If TCCanOpen( pflTab() )
        cAlias := MPSysOpenQuery( "SELECT ID, DESCRI, BLOQ FROM "+ pflTab() +" WHERE D_E_L_E_T_ = ' ' ORDER BY ID" )
        While ! ( cAlias )->( EOF() )
            cId := AllTrim( ( cAlias )->ID )
            If ! ( cAlias )->BLOQ == '1' .or. cId == AllTrim( cAtual )
                aAdd( aItens, cId +'='+ cId +' - '+ AllTrim( ( cAlias )->DESCRI ) )
            EndIf
            ( cAlias )->( DBSkip() )
        EndDo
        ( cAlias )->( DBCloseArea() )
    EndIf

Return aItens

/*/{Protheus.doc} JSPFLDEF
ID do perfil de cálculo padrão (01), usado pelos produtos sem perfil definido
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@return character, cId
/*/
User Function JSPFLDEF()
Return StrZero( 1, U_JSPFLTAM() )

/*/{Protheus.doc} JSPFLTAM
Tamanho do ID do perfil de cálculo: o mesmo do campo B1_X_PERCA do produto (2 quando o campo não existir)
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@return numeric, nTam
/*/
User Function JSPFLTAM()

    Local nTam := GetSX3Cache( 'B1_X_PERCA', 'X3_TAMANHO' )

    If ValType( nTam ) != 'N' .or. nTam <= 0
        nTam := 2
    EndIf

Return nTam

/*/{Protheus.doc} JSPFLVAR
Variáveis disponíveis para as fórmulas dos perfis de cálculo: descrição curta (exibida na fórmula e na sequência de
cálculo), nome da variável Private criada por fCalNec (GMPAICOM) e explicação. Novas variáveis precisam ser criadas
também em fCalNec
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@return array, aVar - { cDescricao, cVariavel, cAjuda }
/*/
User Function JSPFLVAR()

    Local aVar := {} as array

    aAdd( aVar, { 'Sld. Prod.'  , 'nQtdEst', 'Saldo atual em estoque do produto' } )
    aAdd( aVar, { 'Empenhado'   , 'nQtdEmp', 'Quantidade empenhada (reservada) do produto' } )
    aAdd( aVar, { 'Dias Pret.'  , 'nDias'  , 'Dias de estoque pretendidos (projeção definida no painel)' } )
    aAdd( aVar, { 'L-Time'      , 'nLdTime', 'Prazo de entrega (lead-time) em dias' } )
    aAdd( aVar, { 'Dura. Est.'  , 'nPrjEst', 'Duração projetada do estoque atual, em dias' } )
    aAdd( aVar, { 'Cons. Med.'  , 'nConMed', 'Consumo médio diário do produto' } )
    aAdd( aVar, { 'Lote Min.'   , 'nLotMin', 'Lote mínimo de compra' } )
    aAdd( aVar, { 'Qtde Emb.'   , 'nQtdEmb', 'Quantidade por embalagem' } )
    aAdd( aVar, { 'Qtde Comp.'  , 'nQtdPed', 'Quantidade em pedidos de compra em aberto' } )
    aAdd( aVar, { 'Estoq. Min.' , 'nEstSeg', 'Estoque mínimo (de segurança)' } )
    aAdd( aVar, { 'Qtd. Solic.' , 'nQtdSol', 'Quantidade em solicitações de compra em aberto' } )
    aAdd( aVar, { 'Qtd. em O.P.', 'nQtdPrd', 'Quantidade em ordens de produção em aberto' } )

Return aVar

/*/{Protheus.doc} JSPFLF3
Consulta específica (F3) dos perfis de cálculo, chamada pela consulta PNCPFL do dicionário (SXB, tipo RE) no campo
Perfil de Cálculo do produto (B1_X_PERCA). O cadastro de perfis é uma tabela interna (PNC_PERFIL_<empresa>), que não
pode ser consulta padrão do dicionário: o modal lista os perfis ativos (e o perfil já informado no campo, mesmo
bloqueado), com a fórmula em texto, posicionado no perfil do campo. O perfil escolhido fica na variável estática
cPflRet, devolvida ao campo pela expressão de retorno da consulta (U_JSPFLRET)
@type function
@version 27.0002
@author Jean Carlos Pandolfo Saggin
@since 03/11/2026
@return logical, lOk - .T. quando o usuário selecionou um perfil (.F. mantém o conteúdo do campo)
/*/
User Function JSPFLF3()

    Local oDlg     as object
    Local oBrw     as object
    Local aColumns := {} as array
    Local aDados   := {} as array
    Local cVar     := ReadVar() as character
    Local cAtual   := "" as character
    Local lOk      := .F. as logical
    Local nPos     := 0 as numeric

    // Conteúdo atual do campo: devolvido sem alteração quando o usuário cancela
    If ! Empty( cVar ) .and. Type( cVar ) == 'C'
        cAtual := AllTrim( &( cVar ) )
    EndIf
    cPflRet := cAtual

    If ! U_JSPFLCHK( .F. )
        Return .F.
    EndIf

    aDados := pflLista( cAtual )
    If Len( aDados ) == 0
        hlp( 'PERFIS', 'Nenhum perfil de cálculo ativo cadastrado.',;
             'Cadastre os perfis no SmartSupply (Outras Ações > Perfis de Cálculo) e tente novamente.' )
        Return .F.
    EndIf

    aAdd( aColumns, FWBrwColumn():New() )
    aColumns[len(aColumns)]:SetTitle( 'Perfil' )
    aColumns[len(aColumns)]:SetSize( 4 )
    aColumns[len(aColumns)]:SetType( 'C' )
    aColumns[len(aColumns)]:SetPicture( '@!' )
    aColumns[len(aColumns)]:SetData( {|| aDados[oBrw:nAt][1] } )

    aAdd( aColumns, FWBrwColumn():New() )
    aColumns[len(aColumns)]:SetTitle( 'Descrição' )
    aColumns[len(aColumns)]:SetSize( 25 )
    aColumns[len(aColumns)]:SetType( 'C' )
    aColumns[len(aColumns)]:SetPicture( '@x' )
    aColumns[len(aColumns)]:SetData( {|| aDados[oBrw:nAt][2] } )

    aAdd( aColumns, FWBrwColumn():New() )
    aColumns[len(aColumns)]:SetTitle( 'Situação' )
    aColumns[len(aColumns)]:SetSize( 9 )
    aColumns[len(aColumns)]:SetType( 'C' )
    aColumns[len(aColumns)]:SetPicture( '@x' )
    aColumns[len(aColumns)]:SetData( {|| aDados[oBrw:nAt][4] } )

    aAdd( aColumns, FWBrwColumn():New() )
    aColumns[len(aColumns)]:SetTitle( 'Fórmula da necessidade de compra' )
    aColumns[len(aColumns)]:SetSize( 60 )
    aColumns[len(aColumns)]:SetType( 'C' )
    aColumns[len(aColumns)]:SetPicture( '@x' )
    aColumns[len(aColumns)]:SetData( {|| aDados[oBrw:nAt][3] } )

    oDlg := FWDialogModal():New()
    oDlg:SetEscClose( .T. )
    oDlg:SetTitle( 'Perfis de Cálculo' )
    oDlg:SetSubTitle( 'Selecione o perfil de cálculo da necessidade de compra do produto' )
    oDlg:SetSize( 260, 560 )
    oDlg:CreateDialog()
    oDlg:AddCloseButton( {|| oDlg:DeActivate() }, "Cancelar" )
    oDlg:AddOkButton( {|| lOk := pflEscolhe( aDados, oBrw:nAt ), oDlg:DeActivate() }, "Selecionar" )

    oBrw := FWBrowse():New( oDlg:GetPanelMain() )
    oBrw:SetDataArray()
    oBrw:SetArray( aDados )
    oBrw:DisableConfig()
    oBrw:DisableReport()
    oBrw:SetLineHeight( 20 )
    oBrw:SetColumns( aColumns )
    oBrw:SetDoubleClick( {|| lOk := pflEscolhe( aDados, oBrw:nAt ), oDlg:DeActivate() } )
    oBrw:Activate()

    // Abre posicionado no perfil já informado no campo
    nPos := aScan( aDados, {|x| x[1] == cAtual } )
    If nPos > 0
        oBrw:GoTo( nPos, .T. /* lRefresh */ )
    EndIf

    oDlg:Activate()

Return lOk

/*/{Protheus.doc} JSPFLRET
Expressão de retorno da consulta específica dos perfis (PNCPFL, tipo 5 da SXB): devolve ao campo B1_X_PERCA o perfil
escolhido em U_JSPFLF3, com o tamanho do campo
@type function
@version 27.0002
@author Jean Carlos Pandolfo Saggin
@since 03/11/2026
@return character, cPerfil
/*/
User Function JSPFLRET()

    Local cRet := "" as character

    If ValType( cPflRet ) == 'C'
        cRet := cPflRet
    EndIf

Return PadR( AllTrim( cRet ), U_JSPFLTAM() )

/*/{Protheus.doc} pflPublic
Grava no servidor a página da tela de perfis, o script da tela (com o estado inicial) e o twebchannel.js (resource do
RPO) e os publica na pasta web do usuário (CpyF2Web), para abertura no TWebEngine com navigate(). O JavaScript vai
sempre em arquivo .js: no SmartClient HTML (WebApp) a política de segurança de conteúdo (CSP) não executa scripts
embutidos na página
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param cLib, character, conteúdo do twebchannel.js
@param cEstado, character, estado inicial da tela (JSON de pflProc), gravado no script da tela
@param aArqServ, array, (referência) arquivos gravados no servidor, para exclusão ao fechar a janela
@return character, cUrl - endereço da página na pasta web do usuário (vazio quando não publicada)
/*/
Static Function pflPublic( cLib, cEstado, aArqServ )

    Local cId     := cValToChar( ThreadId() ) +'_'+ StrTran( Time(), ':', '' ) as character
    Local cScript := 'sstwebchannel_'+ cId +'.js' as character
    Local cApp    := 'ssperfis_'+ cId +'.js' as character
    Local cPagina := 'ssperfis_'+ cId +'.html' as character
    Local cUrl    := "" as character

    If ! ExistDir( PFL_DIR )
        MakeDir( PFL_DIR )
    EndIf
    If ! ExistDir( PFL_TMP )
        MakeDir( PFL_TMP )
    EndIf

    // Lista de exclusão montada antes da gravação: remove também o que foi gravado se uma etapa seguinte falhar
    aArqServ := { PFL_TMP +'/'+ cScript, PFL_TMP +'/'+ cApp, PFL_TMP +'/'+ cPagina }
    If MemoWrite( PFL_TMP +'/'+ cScript, cLib ) .and. MemoWrite( PFL_TMP +'/'+ cApp, pflApp( cEstado ) ) .and.;
       MemoWrite( PFL_TMP +'/'+ cPagina, pflHtml( cScript, cApp ) )
        // Scripts e página publicados na mesma pasta web do usuário (a página referencia os scripts pelo nome)
        If ! Empty( CpyF2Web( PFL_TMP +'/'+ cScript, .T., .F., .F. ) ) .and. ! Empty( CpyF2Web( PFL_TMP +'/'+ cApp, .T., .F., .F. ) )
            cUrl := CpyF2Web( PFL_TMP +'/'+ cPagina, .T., .F., .F. )
        EndIf
    EndIf

    If Empty( cUrl )
        FWLogMsg( 'WARN', /*cTransactionId*/, 'SMARTSUPPLY', 'JSPERFIL', '', '01', 'Tela de perfis de cálculo não publicada na pasta web do usuário (CpyF2Web)' )
    EndIf

Return cUrl

/*/{Protheus.doc} pflCarga
Na inicialização da janela, abre a página somente se a carga feita na criação ainda não terminou
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param oWeb, object, navegador (TWebEngine)
@param cUrl, character, endereço da página publicada
/*/
Static Function pflCarga( oWeb, cUrl )

    If ! lPflCarg .and. ValType( oWeb ) == 'O'
        oWeb:Navigate( cUrl )
    EndIf

Return Nil

/*/{Protheus.doc} pflEvento
Trata as mensagens enviadas pela página (JavaScript -> AdvPL) e devolve o estado atualizado da tela.
Mensagens: carga (somente quando a página foi aberta sem o estado inicial), salvar e excluir. A descrição digitada
chega codificada com encodeURIComponent (somente ASCII), evitando problemas de acentuação
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param oCanal, object, TWebChannel
@param cChave, character, tipo da mensagem
@param cValor, character, conteúdo da mensagem (JSON)
/*/
Static Function pflEvento( oCanal, cChave, cValor )

    FWLogMsg( 'INFO', /*cTransactionId*/, 'SMARTSUPPLY', 'JSPERFIL', '', '01', 'Tela de perfis de cálculo: mensagem "'+ cChave +'" recebida da página' )
    oCanal:advplToJS( 'estado', pflProc( cChave, cValor ) )

Return Nil

/*/{Protheus.doc} pflProc
Processa uma mensagem da tela de perfis (ou a carga inicial, antes da abertura) e devolve o estado da tela em JSON.
Qualquer falha (mensagem inválida, gravação ou consulta) é capturada, registrada no log do servidor e devolvida como
mensagem de erro para a página, que assim nunca fica aguardando uma resposta que não chega
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param cChave, character, tipo da mensagem (carga, salvar ou excluir)
@param cValor, character, conteúdo da mensagem (JSON)
@param cSel, character, perfil a selecionar na tela (carga)
@return character, cJson - estado da tela (somente ASCII)
/*/
Static Function pflProc( cChave, cValor, cSel )

    Local oDados  := JsonObject():New() as object
    Local oFalha  as object
    Local bErro   as codeblock
    Local aRet    := {} as array
    Local cErro   := "" as character
    Local cMsg    := "" as character
    Local cJson   := "" as character
    Local xParser

    Default cSel := ""

    bErro := ErrorBlock( {|oErr| oFalha := oErr, Break( oErr ) } )
    Begin Sequence
        If ! Empty( cValor )
            xParser := oDados:FromJson( cValor )
            If ValType( xParser ) == 'C'
                cErro := 'Mensagem inválida recebida da tela de perfis de cálculo.'
            EndIf
        EndIf

        If Empty( cErro )
            Do Case
            Case cChave == 'salvar'
                aRet  := pflGrava( jChr( oDados['id'] ), jTxt( oDados['desc'] ), ValType( oDados['ativo'] ) == 'L' .and. oDados['ativo'],;
                                   jTok( oDados['formula'] ) )
                cErro := aRet[1]
                cSel  := aRet[2]
                If Empty( cErro )
                    cMsg      := 'Perfil '+ aRet[2] +' gravado.'
                    lPflMudou := .T.
                EndIf
            Case cChave == 'excluir'
                cSel  := jChr( oDados['id'] )
                cErro := pflExcl( cSel )
                If Empty( cErro )
                    cMsg      := 'Perfil '+ cSel +' excluído.'
                    cSel      := U_JSPFLDEF()
                    lPflMudou := .T.
                EndIf
            EndCase
        EndIf

        cJson := pflEstado( cErro, cMsg, cSel )
    Recover
        cErro := 'Falha ao processar a tela de perfis de cálculo: '+ AllTrim( oFalha:Description )
        FWLogMsg( 'ERROR', /*cTransactionId*/, 'SMARTSUPPLY', 'JSPERFIL', '', '02', cErro + Chr(13) + Chr(10) + oFalha:ErrorStack )
        cJson := '{"erro":'+ jsStr( cErro ) +'}'
    End Sequence
    ErrorBlock( bErro )

    FreeObj( oDados )

Return cJson

/*/{Protheus.doc} pflEstado
Monta o estado da tela (perfis com fórmula e quantidade de produtos que usam cada um, variáveis disponíveis, perfil a
selecionar e mensagens) em JSON somente ASCII (caracteres acentuados como \uXXXX, < e > escapados). A contagem de
produtos considera o SB1 de todas as filiais, porque o cadastro de perfis é único para a empresa; produtos sem perfil
contam no perfil padrão
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param cErro, character, mensagem de erro da última ação (vazio quando não houve erro)
@param cMsg, character, mensagem de sucesso da última ação
@param cSel, character, perfil a selecionar na tela
@return character, cJson
/*/
Static Function pflEstado( cErro, cMsg, cSel )

    Local cJson   := "" as character
    Local cAlias  := "" as character
    Local cSep    := "" as character
    Local cSepTok := "" as character
    Local cId     := "" as character
    Local cPadrao := AllTrim( U_JSPFLDEF() ) as character
    Local oUso    := JsonObject():New() as object
    Local aVars   := U_JSPFLVAR() as array
    Local aTok    := {} as array
    Local nUso    := 0 as numeric
    Local nX      := 0 as numeric

    // Produtos por perfil (SB1 de todas as filiais: o perfil vale para a empresa); sem perfil = perfil padrão
    cAlias := MPSysOpenQuery( "SELECT B1.B1_X_PERCA PERFIL, COUNT(*) QTD FROM "+ RetSqlName( 'SB1' ) +" B1 "+;
                              "WHERE B1.D_E_L_E_T_ = ' ' GROUP BY B1.B1_X_PERCA" )
    While ! ( cAlias )->( EOF() )
        cId := AllTrim( ( cAlias )->PERFIL )
        If Empty( cId )
            cId := cPadrao
        EndIf
        nUso := 0
        If oUso:hasProperty( cId )
            nUso := oUso[cId]
        EndIf
        oUso[cId] := nUso + ( cAlias )->QTD
        ( cAlias )->( DBSkip() )
    EndDo
    ( cAlias )->( DBCloseArea() )

    cJson := '{"perfis":['
    cAlias := MPSysOpenQuery( "SELECT ID, DESCRI, FORMUL, BLOQ FROM "+ pflTab() +" WHERE D_E_L_E_T_ = ' ' ORDER BY ID" )
    While ! ( cAlias )->( EOF() )
        cId  := AllTrim( ( cAlias )->ID )
        nUso := 0
        If oUso:hasProperty( cId )
            nUso := oUso[cId]
        EndIf
        cJson += cSep +'{"id":'+ jsStr( cId ) +;
                 ',"desc":'+ jsStr( AllTrim( ( cAlias )->DESCRI ) ) +;
                 ',"bloq":'+ jsBool( ( cAlias )->BLOQ == '1' ) +;
                 ',"padrao":'+ jsBool( cId == cPadrao ) +;
                 ',"uso":'+ cValToChar( nUso ) +',"formula":['
        aTok    := StrTokArr( AllTrim( ( cAlias )->FORMUL ), PFL_SEPARA )
        cSepTok := ""
        For nX := 1 To Len( aTok )
            cJson   += cSepTok + jsStr( AllTrim( aTok[nX] ) )
            cSepTok := ','
        Next nX
        cJson += ']}'
        cSep  := ','
        ( cAlias )->( DBSkip() )
    EndDo
    ( cAlias )->( DBCloseArea() )
    FreeObj( oUso )

    cJson += '],"vars":['
    cSep  := ""
    For nX := 1 To Len( aVars )
        cJson += cSep +'{"var":'+ jsStr( aVars[nX][2] ) +',"desc":'+ jsStr( aVars[nX][1] ) +',"ajuda":'+ jsStr( aVars[nX][3] ) +'}'
        cSep  := ','
    Next nX
    cJson += '],"sel":'+ jsStr( AllTrim( cSel ) ) +',"erro":'+ jsStr( cErro ) +',"msg":'+ jsStr( cMsg ) +'}'

Return cJson

/*/{Protheus.doc} pflGrava
Inclui (cId vazio) ou altera um perfil de cálculo, validando a descrição (obrigatória, única, até 40 caracteres), a
fórmula (pflValFrm) e o bloqueio (o perfil padrão não pode ser bloqueado). Na inclusão, o próximo ID é gerado sob
bloqueio (LockByName) para não haver IDs repetidos
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param cId, character, ID do perfil (vazio = inclusão)
@param cDesc, character, descrição
@param lAtivo, logical, .T. perfil ativo; .F. bloqueado
@param aTok, array, elementos da fórmula
@return array, { cErro, cId } - ID gravado (ou o informado, em caso de erro)
/*/
Static Function pflGrava( cId, cDesc, lAtivo, aTok )

    Local cErro    := "" as character
    Local cAlias   := "" as character
    Local cFormula := "" as character
    Local aRecs    := {} as array
    Local nNovo    := 0  as numeric
    Local nTam     := U_JSPFLTAM() as numeric
    Local nX       := 0  as numeric

    cId   := AllTrim( cId )
    cDesc := Left( AllTrim( cDesc ), PFL_MAXDES )
    For nX := 1 To Len( aTok )
        If ! Empty( cFormula )
            cFormula += PFL_SEPARA
        EndIf
        cFormula += aTok[nX]
    Next nX

    If Empty( cDesc )
        cErro := 'Informe a descrição do perfil.'
    ElseIf Len( pflRecnos( "SELECT R_E_C_N_O_ REC FROM "+ pflTab() +;
                           " WHERE UPPER( RTRIM( DESCRI ) ) = ? AND ID <> ? AND D_E_L_E_T_ = ' '",;
                           { Upper( cDesc ), PadR( cId, nTam ) } ) ) > 0
        cErro := 'Já existe um perfil com a descrição "'+ cDesc +'".'
    ElseIf ! Empty( cId ) .and. ! pflExiste( cId )
        cErro := 'O perfil '+ cId +' não existe mais (pode ter sido excluído por outro usuário).'
    ElseIf cId == AllTrim( U_JSPFLDEF() ) .and. ! lAtivo
        cErro := 'O perfil padrão não pode ser bloqueado: ele é usado pelos produtos sem perfil definido.'
    Else
        cErro := pflValFrm( aTok )
        If Empty( cErro ) .and. Len( cFormula ) > PFL_MAXFRM
            cErro := 'A fórmula ficou longa demais para ser gravada (até '+ cValToChar( PFL_MAXFRM ) +' caracteres). Simplifique a fórmula.'
        EndIf
    EndIf

    If Empty( cErro )
        cAlias := pflAbre()
        If Empty( cAlias )
            cErro := 'Não foi possível abrir a tabela de perfis de cálculo.'
        ElseIf Empty( cId )
            If pflTrava()
                nNovo := pflProxId()
                If Len( cValToChar( nNovo ) ) > nTam
                    cErro := 'Limite de perfis de cálculo atingido (o ID tem '+ cValToChar( nTam ) +' posições, como o campo B1_X_PERCA do produto).'
                Else
                    cId := StrZero( nNovo, nTam )
                    RecLock( cAlias, .T. )
                    ( cAlias )->( FieldPut( FieldPos( 'ID'     ), cId ) )
                    ( cAlias )->( FieldPut( FieldPos( 'DESCRI' ), cDesc ) )
                    ( cAlias )->( FieldPut( FieldPos( 'FORMUL' ), cFormula ) )
                    ( cAlias )->( FieldPut( FieldPos( 'BLOQ'   ), pflBloq( lAtivo ) ) )
                    ( cAlias )->( FieldPut( FieldPos( 'USRINC' ), RetCodUsr() ) )
                    ( cAlias )->( FieldPut( FieldPos( 'DTINC'  ), Date() ) )
                    ( cAlias )->( MsUnlock() )
                EndIf
                UnLockByName( 'PNC_PERFIL_ID', .T., .F. )
            Else
                cErro := 'Outro usuário está cadastrando um perfil neste momento. Tente novamente.'
            EndIf
        Else
            aRecs := pflRecnos( "SELECT R_E_C_N_O_ REC FROM "+ pflTab() +" WHERE ID = ? AND D_E_L_E_T_ = ' '", { PadR( cId, nTam ) } )
            If Len( aRecs ) > 0
                ( cAlias )->( DBGoTo( aRecs[1] ) )
                RecLock( cAlias, .F. )
                ( cAlias )->( FieldPut( FieldPos( 'DESCRI' ), cDesc ) )
                ( cAlias )->( FieldPut( FieldPos( 'FORMUL' ), cFormula ) )
                ( cAlias )->( FieldPut( FieldPos( 'BLOQ'   ), pflBloq( lAtivo ) ) )
                ( cAlias )->( FieldPut( FieldPos( 'USRALT' ), RetCodUsr() ) )
                ( cAlias )->( FieldPut( FieldPos( 'DTALT'  ), Date() ) )
                ( cAlias )->( MsUnlock() )
            EndIf
        EndIf
        If ! Empty( cAlias )
            ( cAlias )->( DBCloseArea() )
        EndIf
    EndIf

Return { cErro, cId }

/*/{Protheus.doc} pflExcl
Exclui (logicamente) um perfil de cálculo. Não exclui o perfil padrão nem perfis em uso por algum produto (B1_X_PERCA,
em qualquer filial) - nesse caso o perfil pode ser bloqueado
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param cId, character, ID do perfil
@return character, cErro
/*/
Static Function pflExcl( cId )

    Local cErro  := "" as character
    Local cAlias := "" as character
    Local aRecs  := {} as array
    Local nUso   := 0  as numeric
    Local nX     := 0  as numeric

    cId := AllTrim( cId )
    If cId == AllTrim( U_JSPFLDEF() )
        cErro := 'O perfil padrão não pode ser excluído: ele é usado pelos produtos sem perfil definido.'
    Else
        nUso := pflUso( cId )
        If nUso > 0
            cErro := 'Há '+ cValToChar( nUso ) +' produto(s) usando este perfil. Troque o perfil desses produtos ou bloqueie o perfil em vez de excluí-lo.'
        EndIf
    EndIf

    If Empty( cErro )
        aRecs := pflRecnos( "SELECT R_E_C_N_O_ REC FROM "+ pflTab() +" WHERE ID = ? AND D_E_L_E_T_ = ' '", { PadR( cId, U_JSPFLTAM() ) } )
        If Len( aRecs ) > 0
            cAlias := pflAbre()
            If Empty( cAlias )
                cErro := 'Não foi possível abrir a tabela de perfis de cálculo.'
            Else
                For nX := 1 To Len( aRecs )
                    pflApaga( cAlias, aRecs[nX] )
                Next nX
                ( cAlias )->( DBCloseArea() )
            EndIf
        EndIf
    EndIf

Return cErro

/*/{Protheus.doc} pflValFrm
Valida a fórmula de um perfil antes da gravação: cada elemento deve ser uma variável do motor de cálculo (U_JSPFLVAR),
um número (até 9 dígitos inteiros e 6 decimais, ponto como separador), um operador (+ - * /) ou um parêntese, na ordem
de uma expressão aritmética válida, com os parênteses fechados. A expressão é então calculada com valores de teste
(sem executar nada além de números e operadores), para garantir que o motor de cálculo conseguirá avaliá-la
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param aTok, array, elementos da fórmula
@return character, cErro - vazio quando a fórmula é válida
/*/
Static Function pflValFrm( aTok )

    Local aVars     := U_JSPFLVAR() as array
    Local cErro     := "" as character
    Local cExpr     := "" as character
    Local cTok      := "" as character
    Local lOperando := .T. as logical
    Local nNivel    := 0 as numeric
    Local nPos      := 0 as numeric
    Local nX        := 0 as numeric
    Local oFalha    as object
    Local bErro     as codeblock
    Local xRes

    If Len( aTok ) == 0
        cErro := 'Monte a fórmula do perfil.'
    EndIf

    For nX := 1 To Len( aTok )
        cTok := aTok[nX]
        nPos := aScan( aVars, {|x| x[2] == cTok } )
        If lOperando
            If cTok == '('
                nNivel++
                cExpr += '( '
            ElseIf nPos > 0
                // Valor de teste distinto para cada variável
                cExpr += cValToChar( nPos + 1 ) +' '
                lOperando := .F.
            ElseIf pflNum( cTok )
                cExpr += cTok +' '
                lOperando := .F.
            Else
                cErro := 'Elemento fora de posição ou inválido na fórmula: "'+ Left( cTok, 20 ) +'". Era esperado uma variável, um número ou "(".'
            EndIf
        Else
            If cTok == ')' .and. nNivel > 0
                nNivel--
                cExpr += ') '
            ElseIf aScan( { '+', '-', '*', '/' }, {|x| x == cTok } ) > 0
                cExpr += cTok +' '
                lOperando := .T.
            Else
                cErro := 'Elemento fora de posição ou inválido na fórmula: "'+ Left( cTok, 20 ) +'". Era esperado um operador (+ - * /) ou ")".'
            EndIf
        EndIf
        If ! Empty( cErro )
            Exit
        EndIf
    Next nX

    If Empty( cErro ) .and. lOperando
        cErro := 'A fórmula não pode terminar com um operador ou com "(".'
    ElseIf Empty( cErro ) .and. nNivel > 0
        cErro := 'Há parênteses abertos sem fechamento na fórmula.'
    EndIf

    // Cálculo de teste: a expressão contém apenas números, operadores e parênteses
    If Empty( cErro )
        bErro := ErrorBlock( {|oErr| oFalha := oErr, Break( oErr ) } )
        Begin Sequence
            xRes := &( cExpr )
            If ValType( xRes ) != 'N'
                cErro := 'A fórmula não resulta em um número.'
            EndIf
        Recover
            cErro := 'A fórmula não pôde ser calculada: '+ AllTrim( oFalha:Description )
        End Sequence
        ErrorBlock( bErro )
    EndIf

Return cErro

/*/{Protheus.doc} pflNum
Indica se o elemento da fórmula é um número válido: até 9 dígitos inteiros e, opcionalmente, ponto e até 6 decimais
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param cTok, character, elemento da fórmula
@return logical, lNumero
/*/
Static Function pflNum( cTok )

    Local nPonto := At( '.', cTok ) as numeric
    Local cInt   := cTok as character
    Local cDec   := "" as character
    Local lOk    := .F. as logical
    Local nX     := 0 as numeric

    If nPonto > 0
        cInt := Left( cTok, nPonto - 1 )
        cDec := SubStr( cTok, nPonto + 1 )
    EndIf
    lOk := Len( cInt ) >= 1 .and. Len( cInt ) <= 9 .and. ( nPonto == 0 .or. ( Len( cDec ) >= 1 .and. Len( cDec ) <= 6 ) )
    For nX := 1 To Len( cInt + cDec )
        If ! IsDigit( SubStr( cInt + cDec, nX, 1 ) )
            lOk := .F.
        EndIf
    Next nX

Return lOk

/*/{Protheus.doc} pflMigra
Migra para a tabela interna os perfis do cadastro antigo (tabela do dicionário de dados indicada no parâmetro
MV_X_PNC16, descontinuado), copiando ID, descrição, fórmula (no mesmo formato, sem conversão) e bloqueio. O cadastro
antigo podia ser exclusivo por filial: quando o mesmo ID existir em mais de uma filial, prevalece o da filial corrente
e as diferenças são registradas no log do servidor. Executada uma única vez, sob bloqueio, quando a tabela interna
ainda está vazia
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param lAuto, logical, .T. em processamento sem interface
/*/
Static Function pflMigra( lAuto )

    Local cAliOld := "" as character
    Local cAlias  := "" as character
    Local cAliNew := "" as character
    Local cQuery  := "" as character
    Local cId     := "" as character
    Local cFilOld := "" as character
    Local cConf   := "" as character
    Local cMsgMig := "" as character
    Local aLinhas := {} as array
    Local aGrav   := {} as array
    Local lBloq   := .F. as logical
    Local nTam    := U_JSPFLTAM() as numeric
    Local nPos    := 0 as numeric
    Local nPassa  := 0 as numeric
    Local nX      := 0 as numeric

    If GetMv( 'MV_X_PNC16', .T. )
        cAliOld := Upper( AllTrim( SuperGetMv( 'MV_X_PNC16',, '' ) ) )
    EndIf

    // Somente um alias de tabela do dicionário (3 posições) com os campos do cadastro antigo de perfis
    If Len( cAliOld ) == 3 .and. FWAliasInDic( cAliOld ) .and. ! Empty( GetSX3Cache( cAliOld +'_ID', 'X3_CAMPO' ) ) .and.;
       ! Empty( GetSX3Cache( cAliOld +'_FORMUL', 'X3_CAMPO' ) )

        lBloq  := ! Empty( GetSX3Cache( cAliOld +'_MSBLQL', 'X3_CAMPO' ) )
        cQuery := "SELECT T."+ cAliOld +"_FILIAL FIL, T."+ cAliOld +"_ID ID, T."+ cAliOld +"_DESC DESCRI, T."+ cAliOld +"_FORMUL FORMUL"
        If lBloq
            cQuery += ", T."+ cAliOld +"_MSBLQL BLOQ"
        EndIf
        cQuery += " FROM "+ RetSqlName( cAliOld ) +" T WHERE T.D_E_L_E_T_ = ' ' ORDER BY T."+ cAliOld +"_ID, T."+ cAliOld +"_FILIAL"

        If pflTrava()
            // Outra conexão pode ter migrado enquanto esta aguardava a trava
            If pflQtd() == 0
                cFilOld := xFilial( cAliOld )
                cAlias  := MPSysOpenQuery( cQuery )
                While ! ( cAlias )->( EOF() )
                    aAdd( aLinhas, { ( cAlias )->FIL, AllTrim( ( cAlias )->ID ), AllTrim( ( cAlias )->DESCRI ), AllTrim( ( cAlias )->FORMUL ),;
                                     lBloq .and. ( cAlias )->BLOQ == '1' } )
                    ( cAlias )->( DBSkip() )
                EndDo
                ( cAlias )->( DBCloseArea() )

                // Primeiro os perfis da filial corrente, depois os demais (o primeiro de cada ID prevalece)
                For nPassa := 1 To 2
                    For nX := 1 To Len( aLinhas )
                        If ( nPassa == 1 ) == ( aLinhas[nX][1] == cFilOld )
                            cId  := aLinhas[nX][2]
                            nPos := aScan( aGrav, {|x| x[1] == cId } )
                            If Empty( cId ) .or. Len( cId ) > nTam
                                cConf += ' ID "'+ cId +'" ignorado (tamanho maior que o do campo B1_X_PERCA).'
                            ElseIf nPos == 0
                                aAdd( aGrav, { cId, aLinhas[nX][3], aLinhas[nX][4], aLinhas[nX][5], aLinhas[nX][1] } )
                            ElseIf ! ( aGrav[nPos][3] == aLinhas[nX][4] .and. aGrav[nPos][2] == aLinhas[nX][3] )
                                cConf += ' ID '+ cId +': mantido o da filial "'+ AllTrim( aGrav[nPos][5] ) +'", diferente do da filial "'+ AllTrim( aLinhas[nX][1] ) +'".'
                            EndIf
                        EndIf
                    Next nX
                Next nPassa

                If Len( aGrav ) > 0
                    cAliNew := pflAbre()
                    If ! Empty( cAliNew )
                        For nX := 1 To Len( aGrav )
                            RecLock( cAliNew, .T. )
                            ( cAliNew )->( FieldPut( FieldPos( 'ID'     ), PadL( aGrav[nX][1], nTam, '0' ) ) )
                            ( cAliNew )->( FieldPut( FieldPos( 'DESCRI' ), Left( aGrav[nX][2], PFL_MAXDES ) ) )
                            ( cAliNew )->( FieldPut( FieldPos( 'FORMUL' ), aGrav[nX][3] ) )
                            ( cAliNew )->( FieldPut( FieldPos( 'BLOQ'   ), pflBloq( ! aGrav[nX][4] ) ) )
                            ( cAliNew )->( FieldPut( FieldPos( 'USRINC' ), RetCodUsr() ) )
                            ( cAliNew )->( FieldPut( FieldPos( 'DTINC'  ), Date() ) )
                            ( cAliNew )->( MsUnlock() )
                        Next nX
                        ( cAliNew )->( DBCloseArea() )
                    EndIf

                    FWLogMsg( 'INFO', /*cTransactionId*/, 'SMARTSUPPLY', 'JSPERFIL', '', '01', 'Perfis de cálculo migrados do cadastro antigo ('+ cAliOld +') para '+;
                              pflTab() +': '+ cValToChar( Len( aGrav ) ) +'.'+ cConf )
                    If ! lAuto
                        cMsgMig := 'Os '+ cValToChar( Len( aGrav ) ) +' perfil(is) de cálculo do cadastro antigo ('+ cAliOld +') foram migrados para o '+;
                                   'novo cadastro de perfis, único para a empresa (Outras Ações > Perfis de Cálculo).'
                        If ! Empty( cConf )
                            cMsgMig += '<br><br>Atenção:'+ cConf
                        EndIf
                        MsgInfo( cMsgMig, 'Perfis de Cálculo' )
                    EndIf
                EndIf
            EndIf
            UnLockByName( 'PNC_PERFIL_ID', .T., .F. )
        EndIf
    EndIf

Return Nil

/*/{Protheus.doc} pflAntigo
Fórmula do perfil no cadastro antigo (tabela do dicionário indicada no parâmetro MV_X_PNC16, descontinuado), na filial
corrente, como era lida antes da tabela interna - usada só enquanto a tabela interna ainda não foi criada pelo
assistente de configuração, para que o recálculo de índices sem interface não pare. Para o perfil padrão sem cadastro,
devolve a fórmula do MV_X_PNC01
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param cId, character, ID do perfil
@return character, cFormula
/*/
Static Function pflAntigo( cId )

    Local cFormula := "" as character
    Local cAliOld  := "" as character
    Local cAlias   := "" as character
    Local nTamOld  := 0 as numeric
    Local oExec    as object

    If GetMv( 'MV_X_PNC16', .T. )
        cAliOld := Upper( AllTrim( SuperGetMv( 'MV_X_PNC16',, '' ) ) )
    EndIf

    If Len( cAliOld ) == 3 .and. FWAliasInDic( cAliOld ) .and. ! Empty( GetSX3Cache( cAliOld +'_FORMUL', 'X3_CAMPO' ) )
        nTamOld := GetSX3Cache( cAliOld +'_ID', 'X3_TAMANHO' )
        If ValType( nTamOld ) != 'N' .or. nTamOld <= 0
            nTamOld := Len( AllTrim( cId ) )
        EndIf
        oExec := FwExecStatement():New( ChangeQuery( "SELECT T."+ cAliOld +"_FORMUL FORMUL FROM "+ RetSqlName( cAliOld ) +" T "+;
                                                     "WHERE T."+ cAliOld +"_FILIAL = ? AND T."+ cAliOld +"_ID = ? AND T.D_E_L_E_T_ = ' '" ) )
        oExec:SetString( 1, xFilial( cAliOld ) )
        oExec:SetString( 2, PadR( AllTrim( cId ), nTamOld ) )
        cAlias := oExec:OpenAlias()
        If ! ( cAlias )->( EOF() )
            cFormula := AllTrim( ( cAlias )->FORMUL )
        EndIf
        ( cAlias )->( DBCloseArea() )
        oExec:Destroy()
    EndIf

    If Empty( cFormula ) .and. AllTrim( cId ) == AllTrim( U_JSPFLDEF() )
        cFormula := AllTrim( SuperGetMv( 'MV_X_PNC01',, PFL_FRMPAD ) )
        If Empty( cFormula )
            cFormula := PFL_FRMPAD
        EndIf
    EndIf

Return cFormula

/*/{Protheus.doc} pflPadrao
Cria o perfil de cálculo padrão (ID 01, "Consumo Médio") com a fórmula do parâmetro MV_X_PNC01 (ou a fórmula padrão de
fábrica, quando o parâmetro estiver vazio)
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
/*/
Static Function pflPadrao()

    Local cAlias   := "" as character
    Local cFormula := AllTrim( SuperGetMv( 'MV_X_PNC01',, PFL_FRMPAD ) ) as character

    If Empty( cFormula )
        cFormula := PFL_FRMPAD
    EndIf

    If pflTrava()
        If ! pflExiste( U_JSPFLDEF() )
            cAlias := pflAbre()
            If ! Empty( cAlias )
                RecLock( cAlias, .T. )
                ( cAlias )->( FieldPut( FieldPos( 'ID'     ), U_JSPFLDEF() ) )
                ( cAlias )->( FieldPut( FieldPos( 'DESCRI' ), 'Consumo Médio' ) )
                ( cAlias )->( FieldPut( FieldPos( 'FORMUL' ), cFormula ) )
                ( cAlias )->( FieldPut( FieldPos( 'BLOQ'   ), '2' ) )
                ( cAlias )->( FieldPut( FieldPos( 'USRINC' ), RetCodUsr() ) )
                ( cAlias )->( FieldPut( FieldPos( 'DTINC'  ), Date() ) )
                ( cAlias )->( MsUnlock() )
                ( cAlias )->( DBCloseArea() )
            EndIf
        EndIf
        UnLockByName( 'PNC_PERFIL_ID', .T., .F. )
    EndIf

Return Nil

/*/{Protheus.doc} pflTrava
Bloqueio da tabela de perfis para inclusão (geração do ID) e migração, com algumas tentativas
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@return logical, lTravou
/*/
Static Function pflTrava()

    Local lTravou := .F. as logical
    Local nTenta  := 0 as numeric

    While ! lTravou .and. nTenta < 10
        lTravou := LockByName( 'PNC_PERFIL_ID', .T., .F. )
        If ! lTravou
            nTenta++
            Sleep( 300 )
        EndIf
    EndDo

Return lTravou

/*/{Protheus.doc} pflProxId
Próximo ID numérico de perfil. Considera também os perfis excluídos, para que um ID nunca seja reaproveitado por outro
perfil (produtos podem ainda guardar o ID antigo no B1_X_PERCA de alguma filial)
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@return numeric, nProx
/*/
Static Function pflProxId()

    Local cAlias := MPSysOpenQuery( "SELECT ID FROM "+ pflTab() ) as character
    Local nMaior := 0 as numeric

    While ! ( cAlias )->( EOF() )
        nMaior := Max( nMaior, Val( ( cAlias )->ID ) )
        ( cAlias )->( DBSkip() )
    EndDo
    ( cAlias )->( DBCloseArea() )

Return nMaior + 1

/*/{Protheus.doc} pflUso
Quantidade de produtos (SB1 de todas as filiais) que usam o perfil no campo B1_X_PERCA
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param cId, character, ID do perfil
@return numeric, nUso
/*/
Static Function pflUso( cId )

    Local nUso   := 0 as numeric
    Local cAlias := "" as character
    Local oExec  as object

    oExec := FwExecStatement():New( ChangeQuery( "SELECT COUNT(*) QTD FROM "+ RetSqlName( 'SB1' ) +" B1 WHERE B1.B1_X_PERCA = ? AND B1.D_E_L_E_T_ = ' '" ) )
    oExec:SetString( 1, PadR( AllTrim( cId ), U_JSPFLTAM() ) )
    cAlias := oExec:OpenAlias()
    If ! ( cAlias )->( EOF() )
        nUso := ( cAlias )->QTD
    EndIf
    ( cAlias )->( DBCloseArea() )
    oExec:Destroy()

Return nUso

/*/{Protheus.doc} pflQtd
Quantidade de perfis cadastrados (não excluídos)
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@return numeric, nQtd
/*/
Static Function pflQtd()

    Local cAlias := MPSysOpenQuery( "SELECT COUNT(*) QTD FROM "+ pflTab() +" WHERE D_E_L_E_T_ = ' '" ) as character
    Local nQtd   := ( cAlias )->QTD as numeric

    ( cAlias )->( DBCloseArea() )

Return nQtd

/*/{Protheus.doc} pflExiste
Indica se o perfil existe (não excluído)
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param cId, character, ID do perfil
@return logical, lExiste
/*/
Static Function pflExiste( cId )
Return ! Empty( cId ) .and. Len( pflRecnos( "SELECT R_E_C_N_O_ REC FROM "+ pflTab() +" WHERE ID = ? AND D_E_L_E_T_ = ' '",;
                                            { PadR( AllTrim( cId ), U_JSPFLTAM() ) } ) ) > 0

/*/{Protheus.doc} pflAbre
Abre a tabela de perfis (compartilhada) numa área nova para gravação
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@return character, cAlias (vazio quando não foi possível abrir)
/*/
Static Function pflAbre()

    Local cAlias := GetNextAlias() as character

    DBUseArea( .T. /* lNewArea */, 'TOPCONN', pflTab(), cAlias, .T. /* lShared */, .F. /* lReadOnly */ )
    If Select( cAlias ) == 0
        cAlias := ""
    EndIf

Return cAlias

/*/{Protheus.doc} pflTab
Nome físico da tabela de perfis de cálculo da empresa
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@return character, cTabela
/*/
Static Function pflTab()
Return "PNC_PERFIL_"+ cEmpAnt

/*/{Protheus.doc} pflBloq
Conteúdo do campo de bloqueio (mesma convenção do MSBLQL: 1=bloqueado, 2=ativo)
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param lAtivo, logical, .T. perfil ativo
@return character, cBloq
/*/
Static Function pflBloq( lAtivo )

    Local cBloq := '1' as character

    If lAtivo
        cBloq := '2'
    EndIf

Return cBloq

/*/{Protheus.doc} pflAviso
Aviso de falha na preparação dos perfis: Help na tela ou, sem interface, log do servidor
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param lAuto, logical, .T. em processamento sem interface
@param cTitle, character, título
@param cFail, character, falha
@param cHelp, character, solução
/*/
Static Function pflAviso( lAuto, cTitle, cFail, cHelp )

    If lAuto
        FWLogMsg( 'WARN', /*cTransactionId*/, 'SMARTSUPPLY', 'JSPERFIL', '', '01', cFail +' '+ cHelp )
    Else
        hlp( cTitle, cFail, cHelp )
    EndIf

Return Nil

/*/{Protheus.doc} pflEscolhe
Guarda o perfil da linha selecionada no modal da consulta específica, para o retorno ao campo (U_JSPFLRET)
@type function
@version 27.0002
@author Jean Carlos Pandolfo Saggin
@since 03/11/2026
@param aDados, array, perfis listados no modal (pflLista)
@param nLin, numeric, linha selecionada
@return logical, lOk - .T. quando havia uma linha válida selecionada
/*/
Static Function pflEscolhe( aDados, nLin )

    Local lOk := nLin > 0 .and. nLin <= Len( aDados ) as logical

    If lOk
        cPflRet := aDados[nLin][1]
    EndIf

Return lOk

/*/{Protheus.doc} pflLista
Perfis para o modal da consulta específica: ativos, mais o perfil informado mesmo quando bloqueado
@type function
@version 27.0002
@author Jean Carlos Pandolfo Saggin
@since 03/11/2026
@param cAtual, character, perfil já informado no campo
@return array, aDados - { cId, cDescricao, cFormulaEmTexto, cSituacao }
/*/
Static Function pflLista( cAtual )

    Local aDados := {} as array
    Local cAlias := "" as character
    Local cId    := "" as character
    Local cSitua := "" as character

    cAlias := MPSysOpenQuery( "SELECT ID, DESCRI, FORMUL, BLOQ FROM "+ pflTab() +" WHERE D_E_L_E_T_ = ' ' ORDER BY ID" )
    While ! ( cAlias )->( EOF() )
        cId := AllTrim( ( cAlias )->ID )
        If ! ( cAlias )->BLOQ == '1' .or. cId == cAtual
            cSitua := 'Ativo'
            If ( cAlias )->BLOQ == '1'
                cSitua := 'Bloqueado'
            EndIf
            aAdd( aDados, { cId, AllTrim( ( cAlias )->DESCRI ), pflTexto( AllTrim( ( cAlias )->FORMUL ) ), cSitua } )
        EndIf
        ( cAlias )->( DBSkip() )
    EndDo
    ( cAlias )->( DBCloseArea() )

Return aDados

/*/{Protheus.doc} pflTexto
Fórmula em texto legível: variáveis pelas descrições (U_JSPFLVAR), multiplicação e divisão pelos sinais usuais
@type function
@version 27.0002
@author Jean Carlos Pandolfo Saggin
@since 03/11/2026
@param cFormula, character, fórmula gravada (elementos separados por PFL_SEPARA)
@return character, cTexto
/*/
Static Function pflTexto( cFormula )

    Local aVars  := U_JSPFLVAR() as array
    Local aTok   := StrTokArr( cFormula, PFL_SEPARA ) as array
    Local cTexto := "" as character
    Local cTok   := "" as character
    Local nPos   := 0 as numeric
    Local nX     := 0 as numeric

    For nX := 1 To Len( aTok )
        cTok := AllTrim( aTok[nX] )
        nPos := aScan( aVars, {|x| x[2] == cTok } )
        If nPos > 0
            cTok := aVars[nPos][1]
        ElseIf cTok == '*'
            cTok := 'x'
        ElseIf cTok == '/'
            cTok := '÷'
        EndIf
        If ! Empty( cTexto )
            cTexto += ' '
        EndIf
        cTexto += cTok
    Next nX

Return cTexto

/*/{Protheus.doc} pflF3Cfg
Garante a consulta específica PNCPFL (SXB, tipo RE: função U_JSPFLF3 e retorno U_JSPFLRET) e a liga ao campo Perfil de
Cálculo do produto (X3_F3 do B1_X_PERCA), no lugar da consulta do cadastro antigo de perfis, que deixou de ser usado.
Só grava o que estiver faltando ou diferente; um X3_F3 personalizado (diferente de vazio, da consulta do cadastro
antigo e da PNCPFL) é mantido
@type function
@version 27.0002
@author Jean Carlos Pandolfo Saggin
@since 03/11/2026
/*/
Static Function pflF3Cfg()

    Local aXB     := {} as array
    Local aCampos := { "XB_ALIAS", "XB_TIPO", "XB_SEQ", "XB_COLUNA", "XB_DESCRI", "XB_DESCSPA", "XB_DESCENG", "XB_CONTEM" } as array
    Local cSXB    := "SXB" as character
    Local cSX3    := "SX3" as character
    Local cAliOld := "" as character
    Local cF3     := "" as character
    Local cChave  := "" as character
    Local lInc    := .F. as logical
    Local lGrava  := .F. as logical
    Local nCpo    := 0 as numeric
    Local nX      := 0 as numeric

    // Consulta específica (tipo RE): tabela de referência (tipo 1), função de seleção (tipo 2) e retorno (tipo 5)
    aAdd( aXB, { PFL_F3, '1', '01', 'RE', 'Perfis de Calculo', 'Perfiles de Calculo', 'Calculation Profiles', 'SB1' } )
    aAdd( aXB, { PFL_F3, '2', '01', '01', '', '', '', 'U_JSPFLF3()' } )
    aAdd( aXB, { PFL_F3, '5', '01', '', '', '', '', 'U_JSPFLRET()' } )

    DBSelectArea( cSXB )
    ( cSXB )->( DBSetOrder( 1 ) )       // XB_ALIAS + XB_TIPO + XB_SEQ + XB_COLUNA
    For nX := 1 To Len( aXB )
        cChave := PadR( aXB[nX][1], Len( ( cSXB )->XB_ALIAS ) ) + aXB[nX][2] + aXB[nX][3] + PadR( aXB[nX][4], Len( ( cSXB )->XB_COLUNA ) )
        lInc   := ! ( cSXB )->( DBSeek( cChave ) )
        lGrava := lInc
        For nCpo := 5 To Len( aCampos )
            If ! lInc .and. ! AllTrim( ( cSXB )->( FieldGet( FieldPos( aCampos[nCpo] ) ) ) ) == aXB[nX][nCpo]
                lGrava := .T.
            EndIf
        Next nCpo
        If lGrava
            RecLock( cSXB, lInc )
            For nCpo := 1 To Len( aCampos )
                ( cSXB )->( FieldPut( FieldPos( aCampos[nCpo] ), aXB[nX][nCpo] ) )
            Next nCpo
            ( cSXB )->( MsUnlock() )
            FWLogMsg( 'INFO', /*cTransactionId*/, 'SMARTSUPPLY', 'JSPERFIL', '', '01', 'Consulta específica '+ PFL_F3 +' (SXB tipo '+ aXB[nX][2] +') gravada' )
        EndIf
    Next nX

    // Campo Perfil de Cálculo do produto: troca a consulta vazia ou do cadastro antigo (alias do MV_X_PNC16 ou outra
    // tabela do dicionário com os campos do cadastro antigo de perfis) pela consulta específica
    If GetMv( 'MV_X_PNC16', .T. )
        cAliOld := Upper( AllTrim( SuperGetMv( 'MV_X_PNC16',, '' ) ) )
    EndIf
    DBSelectArea( cSX3 )
    ( cSX3 )->( DBSetOrder( 2 ) )       // X3_CAMPO
    If ( cSX3 )->( DBSeek( PadR( 'B1_X_PERCA', Len( ( cSX3 )->X3_CAMPO ) ) ) )
        cF3 := Upper( AllTrim( ( cSX3 )->X3_F3 ) )
        If ! cF3 == PFL_F3 .and. ( Empty( cF3 ) .or. cF3 == cAliOld .or.;
           ( Len( cF3 ) == 3 .and. ! Empty( GetSX3Cache( cF3 +'_FORMUL', 'X3_CAMPO' ) ) ) )
            RecLock( cSX3, .F. )
            ( cSX3 )->( FieldPut( FieldPos( 'X3_F3' ), PFL_F3 ) )
            ( cSX3 )->( MsUnlock() )
            FWLogMsg( 'INFO', /*cTransactionId*/, 'SMARTSUPPLY', 'JSPERFIL', '', '01', 'Consulta do campo B1_X_PERCA alterada de "'+ cF3 +'" para '+ PFL_F3 )
        EndIf
    EndIf

Return Nil

/*/{Protheus.doc} jTok
Elementos da fórmula recebidos da página (vetor de textos); itens que não forem texto viram elemento vazio, rejeitado
na validação da fórmula
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param xValor, variant, valor lido do JSON
@return array, aTok
/*/
Static Function jTok( xValor )

    Local aTok := {} as array
    Local nX   := 0 as numeric

    If ValType( xValor ) == 'A'
        For nX := 1 To Len( xValor )
            If ValType( xValor[nX] ) == 'C'
                aAdd( aTok, AllTrim( xValor[nX] ) )
            Else
                aAdd( aTok, "" )
            EndIf
        Next nX
    EndIf

Return aTok

/*/{Protheus.doc} pflHtml
Página da tela de perfis de cálculo (HTML e CSS), sem nenhum script embutido: o twebchannel.js e o script da tela são
referenciados como arquivos da mesma pasta, porque o SmartClient HTML (WebApp) publica a pasta web com uma política de
segurança de conteúdo (CSP) que não executa scripts embutidos na página
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param cScript, character, nome do twebchannel.js publicado na mesma pasta da página
@param cApp, character, nome do script da tela (pflApp) publicado na mesma pasta da página
@return character, cHtml - documento somente ASCII
/*/
Static Function pflHtml( cScript, cApp )

    Local cHtml   := "" as character
    Local cTopo   := "" as character

    BeginContent var cTopo
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  :root { --fg:#1f2328; --muted:#59636e; --line:#d1d9e0; --hover:#eef1f4; --accent:#0969da; --accentbg:#ddf4ff; --danger:#cf222e; --ok:#1a7f37; --warn:#9a6700; }
  * { box-sizing: border-box; }
  html, body { margin: 0; height: 100%; background: #ffffff; color: var(--fg);
               font-family: "Segoe UI", -apple-system, Helvetica, Arial, sans-serif; font-size: 13px; }
  .app { display: flex; height: 100%; gap: 14px; padding: 12px 14px; }
  .lado { width: 33%; min-width: 200px; display: flex; flex-direction: column; gap: 8px; }
  .editor { flex: 1; min-width: 0; display: flex; flex-direction: column; overflow-y: auto; padding-right: 2px; }
  .form { display: flex; flex-direction: column; gap: 8px; min-height: 100%; }
  .campo { width: 100%; padding: 7px 9px; border: 1px solid var(--line); border-radius: 6px; font-size: 13px; outline: none; }
  .campo:focus { border-color: var(--accent); box-shadow: 0 0 0 3px rgba(9,105,218,.15); }
  .campo:disabled { background: #f6f8fa; }
  .lista { flex: 1; overflow-y: auto; display: flex; flex-direction: column; gap: 5px; padding-right: 2px; }
  .item { border: 1px solid var(--line); border-radius: 6px; padding: 7px 9px; cursor: pointer; }
  .item:hover { background: var(--hover); }
  .item.sel { border-color: var(--accent); background: var(--accentbg); }
  .item .nome { font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  .item .info { color: var(--muted); font-size: 11px; margin-top: 2px; }
  .tag { display: inline-block; font-size: 10px; font-weight: 600; padding: 1px 6px; border-radius: 10px; margin-left: 4px; vertical-align: middle; }
  .tag.padrao { background: var(--accentbg); color: var(--accent); }
  .tag.bloq { background: #ffebe9; color: var(--danger); }
  .secao { font-size: 11px; font-weight: 600; color: var(--muted); text-transform: uppercase; letter-spacing: .3px; margin-top: 2px; }
  .titulo { font-size: 15px; font-weight: 600; }
  .linha { display: flex; gap: 6px; align-items: center; flex-wrap: wrap; }
  .chk { display: flex; align-items: center; gap: 6px; cursor: pointer; }
  .formula { min-height: 46px; border: 1px dashed var(--line); border-radius: 6px; padding: 6px; display: flex; flex-wrap: wrap; gap: 4px; align-items: center; }
  .tok { padding: 3px 8px; border-radius: 4px; font-weight: 600; font-size: 12px; }
  .tok.var { background: var(--accentbg); color: var(--accent); }
  .tok.op { background: #f6f8fa; color: var(--fg); border: 1px solid var(--line); }
  .tok.num { background: #fff8c5; color: var(--warn); }
  .vazio { color: var(--muted); padding: 4px; }
  .leitura { color: var(--muted); font-size: 12px; min-height: 16px; }
  .vars { display: grid; grid-template-columns: repeat(3, 1fr); gap: 5px; }
  .btn { padding: 5px 10px; border-radius: 6px; border: 1px solid var(--line); background: #ffffff; cursor: pointer; font-weight: 600; color: var(--fg); font-size: 12px; }
  .btn:hover:not(:disabled) { background: var(--hover); }
  .btn:disabled { opacity: .45; cursor: default; }
  .btn.var { text-align: left; font-weight: 500; }
  .btn.op { min-width: 34px; font-size: 14px; }
  .btn.primario { background: var(--accent); border-color: var(--accent); color: #ffffff; }
  .btn.primario:hover:not(:disabled) { background: #0860c4; }
  .btn.perigo { color: var(--danger); border-color: var(--danger); margin-right: auto; }
  .num { width: 96px; }
  .acoes { display: flex; gap: 6px; justify-content: flex-end; margin-top: auto; padding-top: 8px; }
  .aviso { color: var(--warn); font-size: 12px; min-height: 16px; }
  .erro { color: var(--danger); font-size: 12px; }
  .ok { color: var(--ok); font-size: 12px; }
  .dica { color: var(--muted); font-size: 11px; }
  .novo { width: 100%; padding: 8px; }
  [hidden] { display: none !important; }
</style>
</head>
<body>
<div class="app">
  <div class="lado">
    <input id="busca" class="campo" type="text" placeholder="Buscar perfis..." autocomplete="off">
    <div class="secao">Perfis de cálculo</div>
    <div id="lista" class="lista"><div class="vazio">Carregando...</div></div>
    <button id="novo" class="btn novo" type="button">Criar um novo perfil</button>
  </div>
  <div class="editor">
    <div id="semSel" class="vazio">Selecione um perfil na lista ou crie um novo.</div>
    <div id="form" class="form" hidden>
      <div class="linha"><span id="tituloEd" class="titulo"></span><span id="tagsEd"></span></div>
      <div class="secao">Descrição</div>
      <input id="desc" class="campo" type="text" maxlength="40" autocomplete="off" placeholder="Ex.: Consumo médio com estoque de segurança">
      <label class="chk"><input id="ativo" type="checkbox"> Perfil ativo (disponível para seleção no painel)</label>
      <div id="dicaAtivo" class="dica"></div>
      <div class="secao">Fórmula da necessidade de compra</div>
      <div id="formula" class="formula"></div>
      <div id="leitura" class="leitura"></div>
      <div class="linha">
        <button class="btn op" type="button" data-op="(">(</button>
        <button class="btn op" type="button" data-op=")">)</button>
        <button class="btn op" type="button" data-op="+">+</button>
        <button class="btn op" type="button" data-op="-">-</button>
        <button class="btn op" type="button" data-op="*">&times;</button>
        <button class="btn op" type="button" data-op="/">&divide;</button>
        <input id="num" class="campo num" type="text" placeholder="Número" autocomplete="off">
        <button id="addNum" class="btn" type="button">Incluir número</button>
        <button id="apagar" class="btn" type="button">Apagar último</button>
        <button id="limpar" class="btn" type="button">Limpar</button>
      </div>
      <div class="secao">Variáveis (clique para incluir na fórmula)</div>
      <div id="vars" class="vars"></div>
      <div id="aviso" class="aviso"></div>
      <div id="erro" class="erro"></div>
      <div id="msg" class="ok"></div>
      <div class="acoes">
        <button id="excluir" class="btn perigo" type="button">Excluir</button>
        <button id="desfazer" class="btn" type="button">Desfazer alterações</button>
        <button id="salvar" class="btn primario" type="button">Salvar</button>
      </div>
    </div>
  </div>
</div>
    EndContent

    // Canal no cabeçalho e script da tela ao final do corpo (executado com os elementos da página já criados).
    // Documento somente ASCII: acentos como entidades HTML
    cTopo := StrTran( cTopo, '</head>', '<script src="'+ cScript +'"></script>'+ Chr(13) + Chr(10) +'</head>' )
    cHtml := pflAscii( cTopo, .F. ) +'<script src="'+ cApp +'"></script>'+ Chr(13) + Chr(10) +;
             '</body>'+ Chr(13) + Chr(10) +'</html>'

Return cHtml

/*/{Protheus.doc} pflApp
Script da tela de perfis de cálculo (JavaScript), publicado como arquivo .js na mesma pasta da página. A fórmula é
montada por elementos (variáveis, números, operadores e parênteses), com os botões habilitados conforme o que pode vir
a seguir na expressão - as mesmas regras validadas no servidor ao salvar (pflValFrm). Nomes e descrições são sempre
exibidos com textContent (nunca interpretados como HTML) e a descrição é enviada ao AdvPL com encodeURIComponent. O
estado inicial da tela entra no lugar do marcador ESTADO do script
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param cEstado, character, estado inicial da tela (JSON somente ASCII de pflProc)
@return character, cJs - script somente ASCII (acentos como \uXXXX)
/*/
Static Function pflApp( cEstado )

    Local cJs     := "" as character
    Local cApp    := "" as character

    Default cEstado := ""

    BeginContent var cApp
(function () {
  'use strict';
  var estado = { perfis: [], vars: [] };
  var atual = null;        // perfil em edição: { id, desc, ativo, formula } (id vazio = novo perfil)
  var original = null;     // perfil como está gravado, para desfazer e detectar alterações (null = novo)
  var conectado = false;
  var aguardando = false;
  var confirmaExclusao = false;
  var OPERADORES = ['+', '-', '*', '/'];
  // Estado inicial gravado pelo Protheus ao gerar este script (pflProc); null quando o script veio sem ele
  var inicial = /*ESTADO*/null;

  function el(id) { return document.getElementById(id); }

  function enviar(chave, dados) {
    if (!conectado) { el('erro').textContent = 'Aguardando comunicação com o Protheus...'; return; }
    aguardando = true;
    renderEditor();
    twebchannel.jsToAdvpl(chave, JSON.stringify(dados || {}));
  }

  function normaliza(texto) {
    return (texto || '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toUpperCase();
  }

  function copia(p) { return { id: p.id, desc: p.desc, ativo: !p.bloq, formula: p.formula.slice() }; }

  function perfilPorId(id) {
    for (var i = 0; i < estado.perfis.length; i++) {
      if (estado.perfis[i].id === id) { return estado.perfis[i]; }
    }
    return null;
  }

  function variavel(tok) {
    for (var i = 0; i < estado.vars.length; i++) {
      if (estado.vars[i].var === tok) { return estado.vars[i]; }
    }
    return null;
  }

  function ehNumero(tok) { return /^\d{1,9}(\.\d{1,6})?$/.test(tok); }

  function rotuloTok(tok) {
    var v = variavel(tok);
    if (v) { return v.desc; }
    if (tok === '*') { return '×'; }
    if (tok === '/') { return '÷'; }
    return tok;
  }

  // Analisa a fórmula: o que pode vir a seguir e se ela está completa (mesmas regras do Protheus ao salvar)
  function analisa(f) {
    var operando = true, nivel = 0, i, t, aviso = '';
    for (i = 0; i < f.length; i++) {
      t = f[i];
      if (operando) {
        if (t === '(') { nivel++; }
        else if (variavel(t) || ehNumero(t)) { operando = false; }
        else { return { erro: 'Elemento fora de posição na fórmula: ' + rotuloTok(t), operando: operando, nivel: nivel }; }
      } else {
        if (t === ')' && nivel > 0) { nivel--; }
        else if (OPERADORES.indexOf(t) >= 0) { operando = true; }
        else { return { erro: 'Elemento fora de posição na fórmula: ' + rotuloTok(t), operando: operando, nivel: nivel }; }
      }
    }
    if (!f.length) { aviso = 'Monte a fórmula com as variáveis, números, operadores e parênteses.'; }
    else if (operando) { aviso = 'Complete a fórmula: ela não pode terminar com um operador ou com "(".'; }
    else if (nivel > 0) { aviso = 'Feche os parênteses abertos (faltam ' + nivel + ').'; }
    return { erro: '', aviso: aviso, operando: operando, nivel: nivel };
  }

  function alterado() {
    if (!atual) { return false; }
    if (!original) { return true; }
    return atual.desc !== original.desc || atual.ativo !== original.ativo || atual.formula.join('|') !== original.formula.join('|');
  }

  function limparMensagens() {
    el('erro').textContent = '';
    el('msg').textContent = '';
  }

  function bloqueiaTroca() {
    if (alterado()) {
      el('erro').textContent = 'Salve ou desfaça as alterações do perfil em edição antes de abrir outro.';
      return true;
    }
    return false;
  }

  function selecionar(p) {
    if (atual && atual.id === p.id) { return; }
    if (bloqueiaTroca()) { return; }
    original = copia(p);
    atual = copia(p);
    confirmaExclusao = false;
    limparMensagens();
    renderTudo();
  }

  function novo() {
    if (bloqueiaTroca()) { return; }
    original = null;
    atual = { id: '', desc: el('busca').value.trim(), ativo: true, formula: [] };
    confirmaExclusao = false;
    limparMensagens();
    renderTudo();
    el('desc').focus();
  }

  function renderLista() {
    var lista = el('lista');
    var filtro = normaliza(el('busca').value.trim());
    var itens = estado.perfis.filter(function (p) {
      return !filtro || normaliza(p.id + ' ' + p.desc).indexOf(filtro) >= 0;
    });
    lista.textContent = '';
    if (!itens.length) {
      var vazio = document.createElement('div');
      vazio.className = 'vazio';
      vazio.textContent = estado.perfis.length ? 'Nenhum perfil encontrado.' : 'Nenhum perfil cadastrado.';
      lista.appendChild(vazio);
      return;
    }
    itens.forEach(function (p) {
      var item = document.createElement('div');
      var nome = document.createElement('div');
      var info = document.createElement('div');
      item.className = 'item' + (atual && atual.id === p.id ? ' sel' : '');
      nome.className = 'nome';
      nome.textContent = p.id + ' - ' + p.desc;
      if (p.padrao) { nome.appendChild(etiqueta('Padrão', 'padrao')); }
      if (p.bloq) { nome.appendChild(etiqueta('Bloqueado', 'bloq')); }
      info.className = 'info';
      info.textContent = p.uso + ' produto(s) com este perfil';
      item.appendChild(nome);
      item.appendChild(info);
      item.addEventListener('click', function () { selecionar(p); });
      lista.appendChild(item);
    });
  }

  function etiqueta(texto, classe) {
    var s = document.createElement('span');
    s.className = 'tag ' + classe;
    s.textContent = texto;
    return s;
  }

  function renderVars() {
    var grade = el('vars');
    grade.textContent = '';
    estado.vars.forEach(function (v) {
      var b = document.createElement('button');
      b.type = 'button';
      b.className = 'btn var';
      b.textContent = v.desc;
      b.title = v.ajuda + ' (' + v.var + ')';
      b.addEventListener('click', function () { incluir(v.var); });
      grade.appendChild(b);
    });
  }

  function renderFormula() {
    var caixa = el('formula');
    caixa.textContent = '';
    if (!atual.formula.length) {
      var vazio = document.createElement('div');
      vazio.className = 'vazio';
      vazio.textContent = 'A fórmula está vazia.';
      caixa.appendChild(vazio);
    }
    atual.formula.forEach(function (t) {
      var s = document.createElement('span');
      var v = variavel(t);
      s.className = 'tok ' + (v ? 'var' : (ehNumero(t) ? 'num' : 'op'));
      s.textContent = rotuloTok(t);
      if (v) { s.title = v.ajuda + ' (' + v.var + ')'; }
      caixa.appendChild(s);
    });
    el('leitura').textContent = atual.formula.length ? 'Necessidade de compra = ' + atual.formula.map(rotuloTok).join(' ') : '';
  }

  function renderEditor() {
    var p = atual && atual.id ? perfilPorId(atual.id) : null;
    var a, tags, botoes, i, op;
    el('semSel').hidden = !!atual;
    el('form').hidden = !atual;
    if (!atual) { return; }

    el('tituloEd').textContent = atual.id ? 'Perfil ' + atual.id : 'Novo perfil';
    tags = el('tagsEd');
    tags.textContent = '';
    if (p && p.padrao) { tags.appendChild(etiqueta('Padrão', 'padrao')); }
    if (p && p.bloq) { tags.appendChild(etiqueta('Bloqueado', 'bloq')); }
    if (document.activeElement !== el('desc')) { el('desc').value = atual.desc; }
    el('ativo').checked = atual.ativo;
    el('ativo').disabled = aguardando || !!(p && p.padrao);
    if (p && p.padrao) {
      el('dicaAtivo').textContent = 'O perfil padrão é usado pelos produtos sem perfil definido e não pode ser bloqueado nem excluído.';
    } else if (!atual.ativo && p && p.uso) {
      el('dicaAtivo').textContent = 'Bloqueado, o perfil não aparece para seleção no painel; os ' + p.uso + ' produto(s) que já o usam continuam calculados por ele.';
    } else {
      el('dicaAtivo').textContent = '';
    }

    renderFormula();
    a = analisa(atual.formula);
    // Botões habilitados conforme o que pode vir a seguir na fórmula
    botoes = document.querySelectorAll('button[data-op]');
    for (i = 0; i < botoes.length; i++) {
      op = botoes[i].getAttribute('data-op');
      if (op === '(') { botoes[i].disabled = aguardando || !a.operando; }
      else if (op === ')') { botoes[i].disabled = aguardando || a.operando || a.nivel === 0; }
      else { botoes[i].disabled = aguardando || a.operando; }
    }
    botoes = el('vars').querySelectorAll('button');
    for (i = 0; i < botoes.length; i++) { botoes[i].disabled = aguardando || !a.operando; }
    el('num').disabled = aguardando || !a.operando;
    el('addNum').disabled = aguardando || !a.operando;
    el('apagar').disabled = aguardando || !atual.formula.length;
    el('limpar').disabled = aguardando || !atual.formula.length;
    el('desc').disabled = aguardando;
    el('aviso').textContent = a.erro || a.aviso;

    el('salvar').disabled = aguardando || !!a.erro || !!a.aviso || !atual.desc.trim() || !alterado();
    el('desfazer').disabled = aguardando || !alterado();
    el('excluir').hidden = !atual.id;
    el('excluir').disabled = aguardando || !p || p.padrao || p.uso > 0;
    if (p && p.padrao) { el('excluir').title = 'O perfil padrão não pode ser excluído'; }
    else if (p && p.uso > 0) { el('excluir').title = 'Em uso por ' + p.uso + ' produto(s): troque o perfil desses produtos ou bloqueie este perfil'; }
    else { el('excluir').title = ''; }
    el('excluir').textContent = confirmaExclusao ? 'Confirmar exclusão' : 'Excluir';
  }

  function renderTudo() {
    renderLista();
    renderEditor();
  }

  function incluir(tok) {
    if (!atual || aguardando) { return; }
    atual.formula.push(tok);
    confirmaExclusao = false;
    limparMensagens();
    renderEditor();
  }

  function incluirNumero() {
    var v = el('num').value.trim().replace(',', '.');
    if (!ehNumero(v)) { el('erro').textContent = 'Informe um número válido, com até 6 casas decimais (ex.: 1,5).'; return; }
    el('num').value = '';
    incluir(v);
  }

  function salvar() {
    if (!atual) { return; }
    confirmaExclusao = false;
    enviar('salvar', { id: atual.id, desc: encodeURIComponent(atual.desc.trim()), ativo: atual.ativo, formula: atual.formula });
  }

  function excluir() {
    if (!atual || !atual.id) { return; }
    if (!confirmaExclusao) { confirmaExclusao = true; renderEditor(); return; }
    enviar('excluir', { id: atual.id });
  }

  function desfazer() {
    atual = original ? { id: original.id, desc: original.desc, ativo: original.ativo, formula: original.formula.slice() } : null;
    confirmaExclusao = false;
    limparMensagens();
    renderTudo();
  }

  // Aplica o estado devolvido pelo Protheus: numa falha, mantém as alterações do usuário em edição
  function aplicar(novoEst) {
    var p;
    if (!novoEst) { return; }
    aguardando = false;
    if (novoEst.perfis) { estado.perfis = novoEst.perfis; }
    if (novoEst.vars && novoEst.vars.length) { estado.vars = novoEst.vars; renderVars(); }
    if (novoEst.erro) {
      el('msg').textContent = '';
      el('erro').textContent = novoEst.erro;
      if (atual && atual.id) {
        p = perfilPorId(atual.id);
        original = p ? copia(p) : null;
      }
    } else {
      el('erro').textContent = '';
      el('msg').textContent = novoEst.msg || '';
      p = perfilPorId(novoEst.sel) || (estado.perfis.length ? estado.perfis[0] : null);
      original = p ? copia(p) : null;
      atual = p ? copia(p) : null;
      confirmaExclusao = false;
    }
    renderTudo();
  }

  function receber(chave, valor) {
    var novoEst;
    if (chave !== 'estado') { return; }
    try {
      novoEst = JSON.parse(valor);
    } catch (e) {
      aguardando = false;
      el('erro').textContent = 'Falha ao ler os dados enviados pelo Protheus.';
      renderEditor();
      return;
    }
    aplicar(novoEst);
  }

  el('busca').addEventListener('input', renderLista);
  el('novo').addEventListener('click', novo);
  el('desc').addEventListener('input', function () {
    if (atual) { atual.desc = el('desc').value; confirmaExclusao = false; el('msg').textContent = ''; renderEditor(); }
  });
  el('ativo').addEventListener('change', function () {
    if (atual) { atual.ativo = el('ativo').checked; el('msg').textContent = ''; renderEditor(); }
  });
  (function () {
    var botoes = document.querySelectorAll('button[data-op]');
    for (var i = 0; i < botoes.length; i++) {
      botoes[i].addEventListener('click', (function (op) { return function () { incluir(op); }; })(botoes[i].getAttribute('data-op')));
    }
  })();
  el('addNum').addEventListener('click', incluirNumero);
  el('num').addEventListener('keydown', function (e) { if (e.key === 'Enter') { incluirNumero(); } });
  el('apagar').addEventListener('click', function () {
    if (atual && atual.formula.length) { atual.formula.pop(); limparMensagens(); renderEditor(); }
  });
  el('limpar').addEventListener('click', function () {
    if (atual) { atual.formula = []; limparMensagens(); renderEditor(); }
  });
  el('salvar').addEventListener('click', salvar);
  el('excluir').addEventListener('click', excluir);
  el('desfazer').addEventListener('click', desfazer);

  // Tela exibida já na abertura, com o estado inicial, sem esperar a conexão do canal
  aplicar(inicial);

  window.onload = function () {
    // Os eventos da tela já estão ligados; sem a biblioteca do canal, apenas informa (não interrompe o script)
    if (typeof twebchannel === 'undefined') {
      el('erro').textContent = 'Biblioteca de comunicação (sstwebchannel.js) não carregada.';
      return;
    }
    twebchannel.advplToJs = receber;
    // Dados de conexão (porta, tipo do SmartClient, thread e origem) informados pelo TWebEngine na URL
    // O canal é usado nas ações; só pede a carga quando o script veio sem o estado inicial
    twebchannel.connect(function () { conectado = true; if (!inicial) { enviar('carga', {}); } });
    // Sem conexão em 6 segundos: informa na tela (diagnóstico)
    setTimeout(function () {
      if (!conectado) { el('erro').textContent = 'Sem comunicação com o Protheus: as alterações não serão gravadas. Feche e abra a tela novamente.'; }
    }, 6000);
  };
})();
    EndContent

    cJs := pflAscii( cApp, .T. )

    // Estado inicial da tela (JSON somente ASCII) no lugar do marcador do script
    If ! Empty( cEstado )
        cJs := StrTran( cJs, '/*ESTADO*/null', cEstado )
    EndIf

Return cJs

/*/{Protheus.doc} jsStr
Converte um texto do sistema (CP-1252) numa string JSON somente ASCII: aspas, barra invertida e
caracteres de controle escapados; acentuados e demais caracteres acima de 127 como \uXXXX
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param cTexto, character, texto
@return character, cJson - texto entre aspas
/*/
Static Function jsStr( cTexto )

    Local cRet  := '"' as character
    Local cChr  := "" as character
    Local nCod  := 0  as numeric
    Local nX    := 0  as numeric

    Default cTexto := ""

    For nX := 1 To Len( cTexto )
        cChr := SubStr( cTexto, nX, 1 )
        nCod := Asc( cChr )
        If cChr == '"' .or. cChr == '\'
            cRet += '\'+ cChr
        ElseIf nCod < 32 .or. nCod > 126 .or. cChr == '<' .or. cChr == '>'	// < e >: escapados por segurança (o JSON também vai no script da tela)
            cRet += '\u'+ hex4( jsUni( nCod ) )
        Else
            cRet += cChr
        EndIf
    Next nX

Return cRet + '"'

/*/{Protheus.doc} pflAscii
Converte o texto (CP-1252) para somente ASCII: caracteres acima de 127 como entidade HTML (&#NNN;) ou, em
JavaScript, como \uXXXX
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param cTexto, character, texto
@param lJs, logical, .T. para escape JavaScript; .F. para entidade HTML
@return character, cRet
/*/
Static Function pflAscii( cTexto, lJs )

    Local cRet := "" as character
    Local cChr := "" as character
    Local nCod := 0  as numeric
    Local nX   := 0  as numeric

    For nX := 1 To Len( cTexto )
        cChr := SubStr( cTexto, nX, 1 )
        nCod := Asc( cChr )
        If nCod < 128
            cRet += cChr
        ElseIf lJs
            cRet += '\u'+ hex4( jsUni( nCod ) )
        Else
            cRet += '&#'+ cValToChar( jsUni( nCod ) ) +';'
        EndIf
    Next nX

Return cRet

/*/{Protheus.doc} jsBool
Valor lógico em JSON
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param lValor, logical, valor
@return character, cJson
/*/
Static Function jsBool( lValor )

    Local cRet := "false" as character

    If lValor
        cRet := "true"
    EndIf

Return cRet

/*/{Protheus.doc} jsUni
Converte um caractere CP-1252 no seu código Unicode (128 a 159 diferem do Latin-1)
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param nCod, numeric, código CP-1252
@return numeric, nUnicode
/*/
Static Function jsUni( nCod )

    Local aMapa := { 8364, 129, 8218, 402, 8222, 8230, 8224, 8225, 710, 8240, 352, 8249, 338, 141, 381, 143,;
                     144, 8216, 8217, 8220, 8221, 8226, 8211, 8212, 732, 8482, 353, 8250, 339, 157, 382, 376 } as array
    Local nRet  := nCod as numeric

    If nCod >= 128 .and. nCod <= 159
        nRet := aMapa[ nCod - 127 ]
    EndIf

Return nRet

/*/{Protheus.doc} hex4
Número em hexadecimal com 4 dígitos (minúsculos)
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param nValor, numeric, número (0 a 65535)
@return character, cHex
/*/
Static Function hex4( nValor )

    Local cDig := "0123456789abcdef" as character
    Local cRet := "" as character
    Local nX   := 0  as numeric

    For nX := 1 To 4
        cRet   := SubStr( cDig, ( nValor % 16 ) + 1, 1 ) + cRet
        nValor := Int( nValor / 16 )
    Next nX

Return cRet

/*/{Protheus.doc} jTxt
Texto digitado na página: chega codificado com encodeURIComponent (UTF-8 em %XX); devolve no padrão do
sistema (CP-1252), sem caracteres de controle. Caracteres sem equivalente em CP-1252 são descartados
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param xValor, variant, valor lido do JSON
@return character, cTexto
/*/
Static Function jTxt( xValor )

    Local cHex  := "0123456789ABCDEF" as character
    Local cUtf8 := "" as character
    Local cRet  := "" as character
    Local cOrig := "" as character
    Local nX    := 1  as numeric
    Local nAlto := 0  as numeric
    Local nBaix := 0  as numeric
    Local xDec

    If ValType( xValor ) == 'C'
        cOrig := xValor
        While nX <= Len( cOrig )
            nAlto := -1
            nBaix := -1
            If SubStr( cOrig, nX, 1 ) == '%' .and. nX + 2 <= Len( cOrig )
                nAlto := At( Upper( SubStr( cOrig, nX + 1, 1 ) ), cHex ) - 1
                nBaix := At( Upper( SubStr( cOrig, nX + 2, 1 ) ), cHex ) - 1
            EndIf
            If nAlto >= 0 .and. nBaix >= 0
                cUtf8 += Chr( ( nAlto * 16 ) + nBaix )
                nX += 3
            Else
                cUtf8 += SubStr( cOrig, nX, 1 )
                nX++
            EndIf
        EndDo

        xDec := DecodeUTF8( cUtf8 )
        If ValType( xDec ) != 'C'
            xDec := ""
            For nX := 1 To Len( cUtf8 )
                If Asc( SubStr( cUtf8, nX, 1 ) ) < 128
                    xDec += SubStr( cUtf8, nX, 1 )
                EndIf
            Next nX
        EndIf

        For nX := 1 To Len( xDec )
            If Asc( SubStr( xDec, nX, 1 ) ) >= 32
                cRet += SubStr( xDec, nX, 1 )
            EndIf
        Next nX
    EndIf

Return cRet

/*/{Protheus.doc} jChr
Valor caractere lido do JSON (null -> "")
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param xValor, variant, valor lido do JSON
@return character, cRet
/*/
Static Function jChr( xValor )

    Local cRet := "" as character

    If ValType( xValor ) == 'C'
        cRet := AllTrim( xValor )
    EndIf

Return cRet

/*/{Protheus.doc} hlp
Função facilitadora para utilização da função Help do Protheus
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param cTitle, character, título da janela
@param cFail, character, informações sobre a falha
@param cHelp, character, texto de ajuda
/*/
Static Function hlp( cTitle, cFail, cHelp )
Return Help( ,, cTitle,, cFail, 1, 0, NIL, NIL, NIL, NIL, NIL, { cHelp } )

/*/{Protheus.doc} pflRecnos
Executa uma consulta parametrizada (FwExecStatement) que devolve a coluna REC (R_E_C_N_O_)
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param cQuery, character, consulta com parâmetros "?"
@param aParams, array, valores dos parâmetros (caractere ou numérico), na ordem
@return array, aRecs
/*/
Static Function pflRecnos( cQuery, aParams )

    Local aRecs  := {} as array
    Local oExec  as object
    Local cAlias := "" as character
    Local nX     := 0  as numeric

    oExec := FwExecStatement():New( ChangeQuery( cQuery ) )
    For nX := 1 To Len( aParams )
        If ValType( aParams[nX] ) == 'N'
            oExec:SetNumeric( nX, aParams[nX] )
        Else
            oExec:SetString( nX, aParams[nX] )
        EndIf
    Next nX
    cAlias := oExec:OpenAlias()
    While ! ( cAlias )->( EOF() )
        aAdd( aRecs, ( cAlias )->REC )
        ( cAlias )->( DBSkip() )
    EndDo
    ( cAlias )->( DBCloseArea() )
    oExec:Destroy()

Return aRecs

/*/{Protheus.doc} pflApaga
Exclui (logicamente) o registro informado
@type function
@version 27.0001
@author Jean Carlos Pandolfo Saggin
@since 02/11/2026
@param cAlias, character, área da tabela aberta
@param nRec, numeric, R_E_C_N_O_ do registro
/*/
Static Function pflApaga( cAlias, nRec )
    ( cAlias )->( DBGoTo( nRec ) )
    If ! ( cAlias )->( EOF() )
        RecLock( cAlias, .F. )
        ( cAlias )->( DBDelete() )
        ( cAlias )->( MsUnlock() )
    EndIf
Return Nil
