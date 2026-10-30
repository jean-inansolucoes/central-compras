#include 'totvs.ch'

#define ROT_MAXNOM  30          // Tamanho máximo do nome do rótulo
#define ROT_ARQJS   "sstwebchannel.js"   // twebchannel.js oficial da TOTVS, compilado no RPO como resource
#define ROT_DIR     "/smartsupply"
#define ROT_TMP     "/smartsupply/tmp"   // Página e script gravados no servidor e publicados com CpyF2Web

/*/{Protheus.doc} JSROTULO
Tela de rótulos do produto (cadastro e vínculo na mesma tela). Exibe todos os rótulos cadastrados com um
checkbox que vincula/desvincula o rótulo ao produto informado, permite criar, editar e excluir rótulos.
A interface é um HTML com JavaScript num TWebEngine dentro de um FWDialogModal. A página e o twebchannel.js
oficial da TOTVS (resource do RPO) são gravados no servidor, publicados na pasta web do usuário (CpyF2Web) e
abertos com navigate(), cuja URL informa à página os dados de conexão do TWebChannel (twebchannel.connect) -
mesmo padrão comprovado da notificação MGNOTFAL. A página é gerada só com ASCII (acentos como entidades HTML
e \uXXXX no JavaScript), independente da codificação. O estado inicial (rótulos, vínculos e paleta) vai
embutido na página, que abre sem depender de troca de mensagens com o Protheus; o canal é usado só nas ações do
usuário, cada uma gravada imediatamente. Falhas são exibidas na tela e registradas no log do servidor (FWLogMsg).
Tabelas: PNC_LABEL_<empresa> (cadastro, único para a empresa) e PNC_LABEL_PROD_<empresa> (vínculos, com a
filial seguindo o compartilhamento do SB1).
@type function
@version 25.0004
@author Jean Carlos Pandolfo Saggin
@since 16/10/2026
@param cProd, character, código do produto
@param cDesc, character, descrição do produto (exibida no subtítulo)
@param cFilVinc, character, filial do vínculo (FWxFilial('SB1') da filial analisada)
@return logical, lMudou - .T. quando algum rótulo ou vínculo foi alterado
/*/
User Function JSROTULO( cProd, cDesc, cFilVinc )

    Local oDlg      as object
    Local oWeb      as object
    Local aArqServ  := {} as array
    Local cLib      := "" as character
    Local cUrl      := "" as character
    Local cEstado   := "" as character
    Local cLibRmt   := "" as character
    Local nX        := 0  as numeric

    Private oRotCanal as object
    Private cRotProd  := "" as character
    Private cRotFil   := "" as character
    Private lRotMudou := .F. as logical
    Private lRotCarg  := .F. as logical

    Default cProd    := ""
    Default cDesc    := ""
    Default cFilVinc := FWxFilial( 'SB1' )

    cRotProd := cProd
    cRotFil  := cFilVinc

    If ! rotTabOk()
        hlp( 'ROTULOS', 'As tabelas de rótulos ainda não foram criadas neste ambiente.',;
             'Acesse o assistente de configuração (U_JSGLBPAR), avance até a etapa Dicionário de Dados e conclua.' )
        Return .F.
    EndIf

    cLib := GetApoRes( ROT_ARQJS )
    If ValType( cLib ) != 'C' .or. Empty( cLib )
        hlp( 'ROTULOS', 'O recurso '+ ROT_ARQJS +' não foi encontrado no repositório (RPO).',;
             'Compile o arquivo src/html/'+ ROT_ARQJS +' junto com os fontes do SmartSupply.' )
        Return .F.
    EndIf

    // Estado inicial (rótulos, vínculos do produto e paleta) montado antes da abertura e embutido na página: a lista
    // aparece sem depender de uma troca de mensagens com o Protheus enquanto a janela ainda está sendo aberta
    cEstado := rotProc( 'carga', '' )

    // Canal de comunicação JavaScript x AdvPL (conectado antes da publicação/abertura da página), usado nas ações
    oRotCanal := TWebChannel():New()
    oRotCanal:bJsToAdvpl := {|oSelf, cChave, cValor| rotEvento( oSelf, cChave, cValor ) }
    oRotCanal:connect()

    cUrl := rotPublica( cLib, cEstado, @aArqServ )
    FWLogMsg( 'INFO', /*cTransactionId*/, 'SMARTSUPPLY', 'JSROTULO', '', '01', 'Tela de rótulos: SmartClient '+ cValToChar( GetRemoteType( @cLibRmt ) ) +;
              ' ('+ AllTrim( cValToChar( cLibRmt ) ) +'), porta do canal '+ cValToChar( oRotCanal:nPort ) +', página '+ cUrl )
    If Empty( cUrl )
        hlp( 'ROTULOS', 'Não foi possível publicar a tela de rótulos na pasta web do usuário.',;
             'Tente novamente. Persistindo, verifique a gravação na pasta '+ ROT_TMP +' do servidor.' )
    Else
        oDlg := FWDialogModal():New()
        oDlg:SetEscClose( .T. )
        oDlg:SetTitle( 'Rótulos do Produto' )
        oDlg:SetSubTitle( AllTrim( cProd ) +' - '+ AllTrim( cDesc ) )
        oDlg:SetSize( 330, 260 )
        // Na inicialização da janela, só recarrega se a carga feita na criação ainda não terminou: uma segunda
        // carga troca a página já conectada ao canal e a nova conexão pode ser recusada
        oDlg:SetInitBlock( {|| rotCarga( oWeb, cUrl ) } )
        oDlg:CreateDialog()
        oDlg:AddCloseButton( {|| oDlg:DeActivate() }, "Fechar" )

        oWeb := TWebEngine():New( oDlg:GetPanelMain(), 0, 0, 100, 100, /*cUrl*/, oRotCanal:nPort )
        oWeb:Align := CONTROL_ALIGN_ALLCLIENT
        oWeb:bLoadFinished := {|oEngine, cUrlCarga| lRotCarg := .T., FWLogMsg( 'INFO', /*cTransactionId*/, 'SMARTSUPPLY', 'JSROTULO', '', '01', 'Tela de rótulos carregada no navegador' ) }
        oWeb:Navigate( cUrl )

        oDlg:Activate()
    EndIf

    oRotCanal:disconnect()
    FreeObj( oRotCanal )
    oRotCanal := Nil

    // Remove os arquivos gravados no servidor (as cópias da pasta web do usuário são temporárias da sessão)
    For nX := 1 To Len( aArqServ )
        FErase( aArqServ[nX] )
    Next nX

Return lRotMudou

/*/{Protheus.doc} JSROTLIS
Lista os rótulos cadastrados (ativos), na ordem de criação
@type function
@version 25.0001
@author Jean Carlos Pandolfo Saggin
@since 16/10/2026
@return array, aRotulos - { ID, nome, cor (código da paleta), imagem do rótulo (rotulo_<cor>.png) }
/*/
User Function JSROTLIS()

    Local aRotulos := {} as array
    Local cQuery   := "" as character
    Local cAlias   := "" as character

    If rotTabOk()
        cQuery := "SELECT LB.ID, LB.DESCRI, LB.COR FROM PNC_LABEL_"+ cEmpAnt +" LB "
        cQuery += "WHERE LB.D_E_L_E_T_ = ' ' ORDER BY LB.ID "
        cAlias := MPSysOpenQuery( cQuery )
        While ! ( cAlias )->( EOF() )
            aAdd( aRotulos, { ( cAlias )->ID, AllTrim( ( cAlias )->DESCRI ), AllTrim( ( cAlias )->COR ),;
                              rotImg( AllTrim( ( cAlias )->COR ) ) } )
            ( cAlias )->( DBSkip() )
        EndDo
        ( cAlias )->( DBCloseArea() )
    EndIf

Return aRotulos

/*/{Protheus.doc} JSROTPRD
Retorna os rótulos vinculados aos produtos nas filiais (do SB1) informadas, para preenchimento das colunas
de rótulo da grid. Com mais de uma filial (SB1 exclusivo), o produto recebe a união dos rótulos das
filiais, sem repetição, na ordem de criação dos rótulos
@type function
@version 25.0001
@author Jean Carlos Pandolfo Saggin
@since 16/10/2026
@param aFilSB1, array, filiais do SB1 (FWxFilial('SB1')) das filiais analisadas
@return json, oMapa - chave: código do produto (sem espaços); valor: vetor de imagens dos rótulos (rotulo_<cor>.png)
/*/
User Function JSROTPRD( aFilSB1 )

    Local oMapa   := JsonObject():New() as object
    Local oVistos := JsonObject():New() as object
    Local oExec   as object
    Local cQuery  := "" as character
    Local cAlias  := "" as character
    Local cProd   := "" as character
    Local cChave  := "" as character
    Local nFil    := 0  as numeric

    Default aFilSB1 := { FWxFilial( 'SB1' ) }

    If rotTabOk()
        cQuery := "SELECT LP.PROD, LB.ID, LB.COR "
        cQuery += "FROM PNC_LABEL_PROD_"+ cEmpAnt +" LP "
        cQuery += "INNER JOIN PNC_LABEL_"+ cEmpAnt +" LB ON LB.ID = LP.LABELID AND LB.D_E_L_E_T_ = ' ' "
        cQuery += "WHERE LP.FILIAL = ? AND LP.D_E_L_E_T_ = ' ' "
        cQuery += "ORDER BY LP.PROD, LB.ID "
        cQuery := ChangeQuery( cQuery )

        For nFil := 1 To Len( aFilSB1 )
            oExec := FwExecStatement():New( cQuery )
            oExec:SetString( 1, aFilSB1[nFil] )
            cAlias := oExec:OpenAlias()
            While ! ( cAlias )->( EOF() )
                cProd  := AllTrim( ( cAlias )->PROD )
                cChave := cProd +'|'+ cValToChar( ( cAlias )->ID )
                If ! oVistos:hasProperty( cChave )
                    oVistos[cChave] := .T.
                    If ! oMapa:hasProperty( cProd )
                        oMapa[cProd] := {}
                    EndIf
                    aAdd( oMapa[cProd], rotImg( AllTrim( ( cAlias )->COR ) ) )
                EndIf
                ( cAlias )->( DBSkip() )
            EndDo
            ( cAlias )->( DBCloseArea() )
            oExec:Destroy()
        Next nFil
    EndIf

    FreeObj( oVistos )

Return oMapa

/*/{Protheus.doc} rotPublica
Grava no servidor a página da tela de rótulos e o twebchannel.js (resource do RPO) e os publica na pasta web
do usuário (CpyF2Web), para abertura no TWebEngine com navigate()
@type function
@version 25.0001
@author Jean Carlos Pandolfo Saggin
@since 21/10/2026
@param cLib, character, conteúdo do twebchannel.js
@param cEstado, character, estado inicial da tela (JSON de rotProc), embutido na página
@param aArqServ, array, (referência) arquivos gravados no servidor, para exclusão ao fechar a janela
@return character, cUrl - endereço da página na pasta web do usuário (vazio quando não publicada)
/*/
Static Function rotPublica( cLib, cEstado, aArqServ )

    Local cId     := cValToChar( ThreadId() ) +'_'+ StrTran( Time(), ':', '' ) as character
    Local cScript := 'sstwebchannel_'+ cId +'.js' as character
    Local cPagina := 'ssrotulos_'+ cId +'.html' as character
    Local cUrl    := "" as character

    If ! ExistDir( ROT_DIR )
        MakeDir( ROT_DIR )
    EndIf
    If ! ExistDir( ROT_TMP )
        MakeDir( ROT_TMP )
    EndIf

    If MemoWrite( ROT_TMP +'/'+ cScript, cLib ) .and. MemoWrite( ROT_TMP +'/'+ cPagina, rotHtml( cScript, cEstado ) )
        aArqServ := { ROT_TMP +'/'+ cScript, ROT_TMP +'/'+ cPagina }
        // Script e página publicados na mesma pasta web do usuário (a página referencia o script pelo nome)
        If ! Empty( CpyF2Web( ROT_TMP +'/'+ cScript, .T., .F., .F. ) )
            cUrl := CpyF2Web( ROT_TMP +'/'+ cPagina, .T., .F., .F. )
        EndIf
    EndIf

    If Empty( cUrl )
        FWLogMsg( 'WARN', /*cTransactionId*/, 'SMARTSUPPLY', 'JSROTULO', '', '01', 'Tela de rótulos não publicada na pasta web do usuário (CpyF2Web)' )
    EndIf

Return cUrl

/*/{Protheus.doc} rotCarga
Na inicialização da janela, abre a página somente se a carga feita na criação ainda não terminou
@type function
@version 25.0001
@author Jean Carlos Pandolfo Saggin
@since 21/10/2026
@param oWeb, object, navegador (TWebEngine)
@param cUrl, character, endereço da página publicada
/*/
Static Function rotCarga( oWeb, cUrl )

    If ! lRotCarg .and. ValType( oWeb ) == 'O'
        oWeb:Navigate( cUrl )
    EndIf

Return Nil

/*/{Protheus.doc} rotEvento
Trata as mensagens enviadas pela página (JavaScript -> AdvPL) e devolve o estado atualizado da tela.
Mensagens: carga (somente quando a página foi aberta sem o estado inicial embutido), toggle (vincular/desvincular),
create, update e delete. Os textos digitados chegam codificados com encodeURIComponent (somente ASCII), evitando
problemas de acentuação
@type function
@version 25.0004
@author Jean Carlos Pandolfo Saggin
@since 16/10/2026
@param oCanal, object, TWebChannel
@param cChave, character, tipo da mensagem
@param cValor, character, conteúdo da mensagem (JSON)
/*/
Static Function rotEvento( oCanal, cChave, cValor )

    FWLogMsg( 'INFO', /*cTransactionId*/, 'SMARTSUPPLY', 'JSROTULO', '', '01', 'Tela de rótulos: mensagem "'+ cChave +'" recebida da página' )
    oCanal:advplToJS( 'estado', rotProc( cChave, cValor ) )

Return Nil

/*/{Protheus.doc} rotProc
Processa uma mensagem da tela de rótulos (ou a carga inicial, antes da abertura) e devolve o estado da tela em
JSON. Qualquer falha (mensagem inválida, gravação ou consulta) é capturada, registrada no log do servidor e
devolvida como mensagem de erro para a página, que assim nunca fica aguardando uma resposta que não chega
@type function
@version 25.0004
@author Jean Carlos Pandolfo Saggin
@since 30/10/2026
@param cChave, character, tipo da mensagem (carga, toggle, create, update ou delete)
@param cValor, character, conteúdo da mensagem (JSON)
@return character, cJson - estado da tela (somente ASCII)
/*/
Static Function rotProc( cChave, cValor )

    Local oDados  := JsonObject():New() as object
    Local oFalha  as object
    Local bErro   as codeblock
    Local cErro   := "" as character
    Local cJson   := "" as character
    Local lFechar := .F. as logical
    Local xParser

    bErro := ErrorBlock( {|oErr| oFalha := oErr, Break( oErr ) } )
    Begin Sequence
        If ! Empty( cValor )
            xParser := oDados:FromJson( cValor )
            If ValType( xParser ) == 'C'
                cErro := 'Mensagem inválida recebida da tela de rótulos.'
            EndIf
        EndIf

        If Empty( cErro )
            Do Case
            Case cChave == 'toggle'
                cErro := rotVinc( jNum( oDados['id'] ), ValType( oDados['marcar'] ) == 'L' .and. oDados['marcar'] )
            Case cChave == 'create'
                cErro   := rotGrvRot( 0, jTxt( oDados['nome'] ), jChr( oDados['cor'] ) )
                lFechar := Empty( cErro )
            Case cChave == 'update'
                cErro   := rotGrvRot( jNum( oDados['id'] ), jTxt( oDados['nome'] ), jChr( oDados['cor'] ) )
                lFechar := Empty( cErro )
            Case cChave == 'delete'
                cErro   := rotExcl( jNum( oDados['id'] ) )
                lFechar := Empty( cErro )
            EndCase
            If aScan( { 'toggle', 'create', 'update', 'delete' }, {|x| x == cChave } ) > 0 .and. Empty( cErro )
                lRotMudou := .T.
            EndIf
        EndIf

        cJson := rotEstado( cErro, lFechar )
    Recover
        cErro := 'Falha ao processar a tela de rótulos: '+ AllTrim( oFalha:Description )
        FWLogMsg( 'ERROR', /*cTransactionId*/, 'SMARTSUPPLY', 'JSROTULO', '', '02', cErro + Chr(13) + Chr(10) + oFalha:ErrorStack )
        cJson := '{"erro":'+ jsStr( cErro ) +',"fechar":false}'
    End Sequence
    ErrorBlock( bErro )

    FreeObj( oDados )

Return cJson

/*/{Protheus.doc} rotEstado
Monta o estado da tela (rótulos, vínculo com o produto, uso e paleta de cores) em JSON somente ASCII
(caracteres acentuados como \uXXXX, < e > escapados), independente da codificação usada pelo canal
@type function
@version 25.0004
@author Jean Carlos Pandolfo Saggin
@since 16/10/2026
@param cErro, character, mensagem de erro da última ação (vazio quando não houve erro)
@param lFechar, logical, indica à página que o editor de rótulo pode ser fechado
@return character, cJson
/*/
Static Function rotEstado( cErro, lFechar )

    Local cJson   := "" as character
    Local cQuery  := "" as character
    Local cAlias  := "" as character
    Local cSep    := "" as character
    Local aPaleta := rotPaleta() as array
    Local oVinc   := JsonObject():New() as object
    Local oExec   as object
    Local nX      := 0  as numeric

    // Rótulos vinculados ao produto da tela, na filial do vínculo (parâmetros só no WHERE, como em JSROTPRD)
    cQuery := "SELECT LP.LABELID FROM PNC_LABEL_PROD_"+ cEmpAnt +" LP "
    cQuery += "WHERE LP.FILIAL = ? AND LP.PROD = ? AND LP.D_E_L_E_T_ = ' ' "
    oExec := FwExecStatement():New( ChangeQuery( cQuery ) )
    oExec:SetString( 1, cRotFil )
    oExec:SetString( 2, cRotProd )
    cAlias := oExec:OpenAlias()
    While ! ( cAlias )->( EOF() )
        oVinc[ cValToChar( ( cAlias )->LABELID ) ] := .T.
        ( cAlias )->( DBSkip() )
    EndDo
    ( cAlias )->( DBCloseArea() )
    oExec:Destroy()

    // Rótulos cadastrados e quantos produtos usam cada um, sem parâmetros: no SQL Server, parâmetros dentro de
    // subconsultas da lista do SELECT dependem da dedução de tipo na preparação da instrução pelo driver
    cQuery := "SELECT LB.ID, LB.DESCRI, LB.COR, COUNT( DISTINCT LP.PROD ) USO "
    cQuery += "FROM PNC_LABEL_"+ cEmpAnt +" LB "
    cQuery += "LEFT JOIN PNC_LABEL_PROD_"+ cEmpAnt +" LP ON LP.LABELID = LB.ID AND LP.D_E_L_E_T_ = ' ' "
    cQuery += "WHERE LB.D_E_L_E_T_ = ' ' "
    cQuery += "GROUP BY LB.ID, LB.DESCRI, LB.COR "
    cQuery += "ORDER BY LB.ID "
    cAlias := MPSysOpenQuery( cQuery )

    cJson := '{"rotulos":['
    While ! ( cAlias )->( EOF() )
        cJson += cSep +'{"id":'+ cValToChar( ( cAlias )->ID ) +;
                 ',"nome":'+ jsStr( AllTrim( ( cAlias )->DESCRI ) ) +;
                 ',"cor":'+ jsStr( AllTrim( ( cAlias )->COR ) ) +;
                 ',"vinc":'+ jsBool( oVinc:hasProperty( cValToChar( ( cAlias )->ID ) ) ) +;
                 ',"uso":'+ cValToChar( ( cAlias )->USO ) +'}'
        cSep := ','
        ( cAlias )->( DBSkip() )
    EndDo
    ( cAlias )->( DBCloseArea() )
    FreeObj( oVinc )

    cJson += '],"cores":['
    cSep := ""
    For nX := 1 To Len( aPaleta )
        cJson += cSep +'{"cor":'+ jsStr( aPaleta[nX][1] ) +',"hex":'+ jsStr( aPaleta[nX][2] ) +',"nome":'+ jsStr( aPaleta[nX][3] ) +'}'
        cSep := ','
    Next nX
    cJson += '],"erro":'+ jsStr( cErro ) +',"fechar":'+ jsBool( lFechar ) +'}'

Return cJson

/*/{Protheus.doc} rotVinc
Vincula ou desvincula um rótulo ao produto da tela, na filial do vínculo
@type function
@version 25.0001
@author Jean Carlos Pandolfo Saggin
@since 16/10/2026
@param nId, numeric, ID do rótulo
@param lMarcar, logical, .T. vincula; .F. desvincula
@return character, cErro
/*/
Static Function rotVinc( nId, lMarcar )

    Local cErro  := "" as character
    Local cAlias := "" as character
    Local aRecs  := {} as array
    Local nX     := 0  as numeric

    If ! rotExiste( nId )
        cErro := 'O rótulo selecionado não existe mais (pode ter sido excluído por outro usuário).'
    Else
        aRecs := rotRecnos( "SELECT R_E_C_N_O_ REC FROM PNC_LABEL_PROD_"+ cEmpAnt +;
                            " WHERE FILIAL = ? AND PROD = ? AND LABELID = ? AND D_E_L_E_T_ = ' '",;
                            { cRotFil, cRotProd, nId } )
        If lMarcar .and. Len( aRecs ) == 0
            cAlias := rotAbre( "PNC_LABEL_PROD_"+ cEmpAnt )
            If Empty( cAlias )
                cErro := 'Não foi possível abrir a tabela de vínculos de rótulos.'
            Else
                RecLock( cAlias, .T. )
                ( cAlias )->( FieldPut( FieldPos( 'FILIAL'  ), cRotFil ) )
                ( cAlias )->( FieldPut( FieldPos( 'PROD'    ), cRotProd ) )
                ( cAlias )->( FieldPut( FieldPos( 'LABELID' ), nId ) )
                ( cAlias )->( FieldPut( FieldPos( 'USRINC'  ), RetCodUsr() ) )
                ( cAlias )->( FieldPut( FieldPos( 'DTINC'   ), Date() ) )
                ( cAlias )->( MsUnlock() )
                ( cAlias )->( DBCloseArea() )
            EndIf
        ElseIf ! lMarcar .and. Len( aRecs ) > 0
            cAlias := rotAbre( "PNC_LABEL_PROD_"+ cEmpAnt )
            If Empty( cAlias )
                cErro := 'Não foi possível abrir a tabela de vínculos de rótulos.'
            Else
                For nX := 1 To Len( aRecs )
                    rotApaga( cAlias, aRecs[nX] )
                Next nX
                ( cAlias )->( DBCloseArea() )
            EndIf
        EndIf
    EndIf

Return cErro

/*/{Protheus.doc} rotGrvRot
Inclui (nId = 0) ou altera um rótulo, validando nome (obrigatório, único, até 30 caracteres) e cor (paleta).
Na inclusão, o próximo ID é gerado sob bloqueio (LockByName) para não haver IDs repetidos
@type function
@version 25.0001
@author Jean Carlos Pandolfo Saggin
@since 16/10/2026
@param nId, numeric, ID do rótulo (0 = inclusão)
@param cNome, character, nome do rótulo
@param cCor, character, imagem da legenda (cor)
@return character, cErro
/*/
Static Function rotGrvRot( nId, cNome, cCor )

    Local cErro  := "" as character
    Local cAlias := "" as character
    Local cTmp   := "" as character
    Local aRecs  := {} as array
    Local nNovo  := 0  as numeric

    cNome := Left( AllTrim( cNome ), ROT_MAXNOM )

    If Empty( cNome )
        cErro := 'Informe o nome do rótulo.'
    ElseIf aScan( rotPaleta(), {|x| x[1] == cCor } ) == 0
        cErro := 'Selecione uma das cores disponíveis.'
    ElseIf Len( rotRecnos( "SELECT R_E_C_N_O_ REC FROM PNC_LABEL_"+ cEmpAnt +;
                           " WHERE UPPER( RTRIM( DESCRI ) ) = ? AND ID <> ? AND D_E_L_E_T_ = ' '",;
                           { Upper( cNome ), nId } ) ) > 0
        cErro := 'Já existe um rótulo com o nome "'+ cNome +'".'
    ElseIf nId > 0 .and. ! rotExiste( nId )
        cErro := 'O rótulo não existe mais (pode ter sido excluído por outro usuário).'
    EndIf

    If Empty( cErro )
        cAlias := rotAbre( "PNC_LABEL_"+ cEmpAnt )
        If Empty( cAlias )
            cErro := 'Não foi possível abrir a tabela de rótulos.'
        ElseIf nId == 0
            If LockByName( 'PNC_LABEL_ID', .T., .F. )
                cTmp := MPSysOpenQuery( "SELECT COALESCE( MAX( ID ), 0 ) ULTIMO FROM PNC_LABEL_"+ cEmpAnt )
                nNovo := ( cTmp )->ULTIMO + 1
                ( cTmp )->( DBCloseArea() )
                RecLock( cAlias, .T. )
                ( cAlias )->( FieldPut( FieldPos( 'ID'     ), nNovo ) )
                ( cAlias )->( FieldPut( FieldPos( 'DESCRI' ), cNome ) )
                ( cAlias )->( FieldPut( FieldPos( 'COR'    ), cCor ) )
                ( cAlias )->( FieldPut( FieldPos( 'USRINC' ), RetCodUsr() ) )
                ( cAlias )->( FieldPut( FieldPos( 'DTINC'  ), Date() ) )
                ( cAlias )->( MsUnlock() )
                UnLockByName( 'PNC_LABEL_ID', .T., .F. )
            Else
                cErro := 'Outro usuário está cadastrando um rótulo neste momento. Tente novamente.'
            EndIf
        Else
            aRecs := rotRecnos( "SELECT R_E_C_N_O_ REC FROM PNC_LABEL_"+ cEmpAnt +" WHERE ID = ? AND D_E_L_E_T_ = ' '", { nId } )
            If Len( aRecs ) > 0
                ( cAlias )->( DBGoTo( aRecs[1] ) )
                RecLock( cAlias, .F. )
                ( cAlias )->( FieldPut( FieldPos( 'DESCRI' ), cNome ) )
                ( cAlias )->( FieldPut( FieldPos( 'COR'    ), cCor ) )
                ( cAlias )->( MsUnlock() )
            EndIf
        EndIf
        If ! Empty( cAlias )
            ( cAlias )->( DBCloseArea() )
        EndIf
    EndIf

Return cErro

/*/{Protheus.doc} rotExcl
Exclui um rótulo e todos os seus vínculos com produtos (exclusão lógica)
@type function
@version 25.0001
@author Jean Carlos Pandolfo Saggin
@since 16/10/2026
@param nId, numeric, ID do rótulo
@return character, cErro
/*/
Static Function rotExcl( nId )

    Local cErro  := "" as character
    Local cAlias := "" as character
    Local aRecs  := {} as array
    Local nX     := 0  as numeric

    // Vínculos com produtos (todas as filiais)
    aRecs := rotRecnos( "SELECT R_E_C_N_O_ REC FROM PNC_LABEL_PROD_"+ cEmpAnt +" WHERE LABELID = ? AND D_E_L_E_T_ = ' '", { nId } )
    If Len( aRecs ) > 0
        cAlias := rotAbre( "PNC_LABEL_PROD_"+ cEmpAnt )
        If Empty( cAlias )
            cErro := 'Não foi possível abrir a tabela de vínculos de rótulos.'
        Else
            For nX := 1 To Len( aRecs )
                rotApaga( cAlias, aRecs[nX] )
            Next nX
            ( cAlias )->( DBCloseArea() )
        EndIf
    EndIf

    // Cadastro do rótulo
    If Empty( cErro )
        aRecs := rotRecnos( "SELECT R_E_C_N_O_ REC FROM PNC_LABEL_"+ cEmpAnt +" WHERE ID = ? AND D_E_L_E_T_ = ' '", { nId } )
        If Len( aRecs ) > 0
            cAlias := rotAbre( "PNC_LABEL_"+ cEmpAnt )
            If Empty( cAlias )
                cErro := 'Não foi possível abrir a tabela de rótulos.'
            Else
                rotApaga( cAlias, aRecs[1] )
                ( cAlias )->( DBCloseArea() )
            EndIf
        EndIf
    EndIf

Return cErro

/*/{Protheus.doc} rotExiste
Indica se o rótulo existe (não excluído)
@type function
@version 25.0001
@author Jean Carlos Pandolfo Saggin
@since 16/10/2026
@param nId, numeric, ID do rótulo
@return logical, lExiste
/*/
Static Function rotExiste( nId )
Return nId > 0 .and. Len( rotRecnos( "SELECT R_E_C_N_O_ REC FROM PNC_LABEL_"+ cEmpAnt +" WHERE ID = ? AND D_E_L_E_T_ = ' '", { nId } ) ) > 0

/*/{Protheus.doc} rotRecnos
Executa uma consulta parametrizada (FwExecStatement) que devolve a coluna REC (R_E_C_N_O_)
@type function
@version 25.0001
@author Jean Carlos Pandolfo Saggin
@since 16/10/2026
@param cQuery, character, consulta com parâmetros "?"
@param aParams, array, valores dos parâmetros (caractere ou numérico), na ordem
@return array, aRecs
/*/
Static Function rotRecnos( cQuery, aParams )

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

/*/{Protheus.doc} rotAbre
Abre uma tabela de rótulos (compartilhada) numa área nova para gravação
@type function
@version 25.0001
@author Jean Carlos Pandolfo Saggin
@since 16/10/2026
@param cTabela, character, nome físico da tabela
@return character, cAlias (vazio quando não foi possível abrir)
/*/
Static Function rotAbre( cTabela )

    Local cAlias := GetNextAlias() as character

    DBUseArea( .T. /* lNewArea */, 'TOPCONN', cTabela, cAlias, .T. /* lShared */, .F. /* lReadOnly */ )
    If Select( cAlias ) == 0
        cAlias := ""
    EndIf

Return cAlias

/*/{Protheus.doc} rotApaga
Exclui (logicamente) o registro informado
@type function
@version 25.0001
@author Jean Carlos Pandolfo Saggin
@since 16/10/2026
@param cAlias, character, área da tabela aberta
@param nRec, numeric, R_E_C_N_O_ do registro
/*/
Static Function rotApaga( cAlias, nRec )
    ( cAlias )->( DBGoTo( nRec ) )
    If ! ( cAlias )->( EOF() )
        RecLock( cAlias, .F. )
        ( cAlias )->( DBDelete() )
        ( cAlias )->( MsUnlock() )
    EndIf
Return Nil

/*/{Protheus.doc} rotTabOk
Indica se as tabelas de rótulos existem no ambiente
@type function
@version 25.0001
@author Jean Carlos Pandolfo Saggin
@since 16/10/2026
@return logical, lOk
/*/
Static Function rotTabOk()
Return TCCanOpen( "PNC_LABEL_"+ cEmpAnt ) .and. TCCanOpen( "PNC_LABEL_PROD_"+ cEmpAnt )

/*/{Protheus.doc} rotPaleta
Paleta de cores disponíveis para os rótulos: código da cor (gravado no rótulo e base do nome da imagem
rotulo_<cor>.png exibida na grid), tom em hexadecimal (tela HTML e imagens) e nome
@type function
@version 25.0001
@author Jean Carlos Pandolfo Saggin
@since 16/10/2026
@return array, aPaleta - { imagem, hexadecimal, nome }
/*/
Static Function rotPaleta()

    Local aPaleta := {} as array

    aAdd( aPaleta, { "BR_VERDE"     , "#43a047", "Verde"      } )
    aAdd( aPaleta, { "BR_VERMELHO"  , "#e53935", "Vermelho"   } )
    aAdd( aPaleta, { "BR_LARANJA"   , "#fb8c00", "Laranja"    } )
    aAdd( aPaleta, { "BR_AMARELO"   , "#fdd835", "Amarelo"    } )
    aAdd( aPaleta, { "BR_AZUL"      , "#1e88e5", "Azul"       } )
    aAdd( aPaleta, { "BR_AZUL_CLARO", "#4fc3f7", "Azul claro" } )
    aAdd( aPaleta, { "BR_VIOLETA"   , "#8e24aa", "Violeta"    } )
    aAdd( aPaleta, { "BR_PINK"      , "#ec407a", "Rosa"       } )
    aAdd( aPaleta, { "BR_MARROM"    , "#795548", "Marrom"     } )
    aAdd( aPaleta, { "BR_CINZA"     , "#9e9e9e", "Cinza"      } )
    aAdd( aPaleta, { "BR_PRETO"     , "#424242", "Preto"      } )

Return aPaleta

/*/{Protheus.doc} rotImg
Imagem do rótulo (resource src/images/rotulo_<cor>.png, faixa arredondada de 32 x 15 pixels) correspondente
à cor da paleta, exibida nas colunas de rótulo da grid e na seleção de rótulos do filtro. Cor fora da paleta
devolve a imagem transparente (white.bmp)
@type function
@version 25.0001
@author Jean Carlos Pandolfo Saggin
@since 22/10/2026
@param cCor, character, cor do rótulo (código da paleta, ex.: BR_VERDE)
@return character, cImagem
/*/
Static Function rotImg( cCor )

    Local cImagem := "white.bmp" as character

    If aScan( rotPaleta(), {|x| x[1] == cCor } ) > 0
        cImagem := "rotulo_"+ Lower( SubStr( cCor, 4 ) ) +".png"
    EndIf

Return cImagem

/*/{Protheus.doc} jsStr
Converte um texto do sistema (CP-1252) numa string JSON somente ASCII: aspas, barra invertida e
caracteres de controle escapados; acentuados e demais caracteres acima de 127 como \uXXXX
@type function
@version 25.0001
@author Jean Carlos Pandolfo Saggin
@since 16/10/2026
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
        ElseIf nCod < 32 .or. nCod > 126 .or. cChr == '<' .or. cChr == '>'	// < e >: o JSON também vai embutido no <script> da página
            cRet += '\u'+ hex4( jsUni( nCod ) )
        Else
            cRet += cChr
        EndIf
    Next nX

Return cRet + '"'

/*/{Protheus.doc} rotAscii
Converte o texto (CP-1252) para somente ASCII: caracteres acima de 127 como entidade HTML (&#NNN;) ou, em
JavaScript, como \uXXXX
@type function
@version 25.0001
@author Jean Carlos Pandolfo Saggin
@since 21/10/2026
@param cTexto, character, texto
@param lJs, logical, .T. para escape JavaScript; .F. para entidade HTML
@return character, cRet
/*/
Static Function rotAscii( cTexto, lJs )

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
@version 25.0001
@author Jean Carlos Pandolfo Saggin
@since 16/10/2026
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
@version 25.0001
@author Jean Carlos Pandolfo Saggin
@since 16/10/2026
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
@version 25.0001
@author Jean Carlos Pandolfo Saggin
@since 16/10/2026
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
@version 25.0001
@author Jean Carlos Pandolfo Saggin
@since 16/10/2026
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
@version 25.0001
@author Jean Carlos Pandolfo Saggin
@since 16/10/2026
@param xValor, variant, valor lido do JSON
@return character, cRet
/*/
Static Function jChr( xValor )

    Local cRet := "" as character

    If ValType( xValor ) == 'C'
        cRet := AllTrim( xValor )
    EndIf

Return cRet

/*/{Protheus.doc} jNum
Valor numérico inteiro lido do JSON (null/inválido -> 0)
@type function
@version 25.0001
@author Jean Carlos Pandolfo Saggin
@since 16/10/2026
@param xValor, variant, valor lido do JSON
@return numeric, nRet
/*/
Static Function jNum( xValor )

    Local nRet := 0 as numeric

    If ValType( xValor ) == 'N'
        nRet := Int( xValor )
    EndIf

Return nRet

/*/{Protheus.doc} hlp
Função facilitadora para utilização da função Help do Protheus
@type function
@version 25.0001
@author Jean Carlos Pandolfo Saggin
@since 16/10/2026
@param cTitle, character, título da janela
@param cFail, character, informações sobre a falha
@param cHelp, character, texto de ajuda
/*/
Static Function hlp( cTitle, cFail, cHelp )
Return Help( ,, cTitle,, cFail, 1, 0, NIL, NIL, NIL, NIL, NIL, { cHelp } )

/*/{Protheus.doc} rotHtml
Página da tela de rótulos (HTML, CSS e JavaScript). Os nomes dos rótulos são sempre exibidos com
textContent (nunca interpretados como HTML) e enviados ao AdvPL com encodeURIComponent
@type function
@version 25.0004
@author Jean Carlos Pandolfo Saggin
@since 16/10/2026
@param cScript, character, nome do twebchannel.js publicado na mesma pasta da página
@param cEstado, character, estado inicial da tela (JSON somente ASCII), no lugar do marcador ESTADO
@return character, cHtml - documento somente ASCII
/*/
Static Function rotHtml( cScript, cEstado )

    Local cHtml   := "" as character
    Local cTopo   := "" as character
    Local cApp    := "" as character

    Default cEstado := ""

    BeginContent var cTopo
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  :root { --fg:#1f2328; --muted:#59636e; --line:#d1d9e0; --hover:#eef1f4; --accent:#0969da; --danger:#cf222e; }
  * { box-sizing: border-box; }
  html, body { margin: 0; height: 100%; background: #ffffff; color: var(--fg);
               font-family: "Segoe UI", -apple-system, Helvetica, Arial, sans-serif; font-size: 14px; }
  .app { display: flex; flex-direction: column; height: 100%; padding: 12px 14px; gap: 10px; }
  .campo { width: 100%; padding: 8px 10px; border: 1px solid var(--line); border-radius: 6px; font-size: 14px; outline: none; }
  .campo:focus { border-color: var(--accent); box-shadow: 0 0 0 3px rgba(9,105,218,.15); }
  .secao { font-size: 12px; font-weight: 600; color: var(--muted); }
  .lista { flex: 1; overflow-y: auto; display: flex; flex-direction: column; gap: 6px; padding-right: 2px; }
  .item { display: flex; align-items: center; gap: 8px; }
  .item input[type=checkbox] { width: 16px; height: 16px; margin: 0 4px; accent-color: var(--accent); cursor: pointer; flex: none; }
  .pill { flex: 1; min-width: 0; padding: 6px 12px; border-radius: 6px; font-weight: 600; cursor: pointer;
          white-space: nowrap; overflow: hidden; text-overflow: ellipsis; user-select: none; }
  .editar { flex: none; width: 30px; height: 30px; border: none; background: transparent; border-radius: 6px;
            cursor: pointer; color: var(--muted); display: flex; align-items: center; justify-content: center; }
  .editar:hover { background: var(--hover); color: var(--fg); }
  .vazio { color: var(--muted); padding: 12px 4px; }
  .erro { color: var(--danger); font-size: 12px; min-height: 16px; }
  .editor { border: 1px solid var(--line); border-radius: 8px; padding: 10px; display: flex; flex-direction: column; gap: 8px; }
  .cores { display: grid; grid-template-columns: repeat(6, 1fr); gap: 6px; }
  .cor { height: 26px; border-radius: 6px; border: 2px solid transparent; cursor: pointer; }
  .cor.sel { border-color: var(--fg); box-shadow: inset 0 0 0 2px #ffffff; }
  .acoes { display: flex; gap: 6px; justify-content: flex-end; }
  .btn { padding: 6px 12px; border-radius: 6px; border: 1px solid var(--line); background: #ffffff; cursor: pointer; font-weight: 600; color: var(--fg); }
  .btn:hover { background: var(--hover); }
  .btn.primario { background: var(--accent); border-color: var(--accent); color: #ffffff; }
  .btn.perigo { color: var(--danger); border-color: var(--danger); margin-right: auto; }
  .novo { width: 100%; padding: 8px; border: 1px solid var(--line); background: #ffffff; border-radius: 6px; font-weight: 600; cursor: pointer; color: var(--fg); }
  .novo:hover { background: var(--hover); }
  [hidden] { display: none !important; }
</style>
</head>
<body>
<div class="app">
  <input id="busca" class="campo" type="text" placeholder="Buscar rótulos..." autocomplete="off">
  <div class="secao">Rótulos</div>
  <div id="lista" class="lista"><div class="vazio">Carregando...</div></div>
  <div id="erro" class="erro"></div>
  <div id="editor" class="editor" hidden>
    <div id="tituloEditor" class="secao">Novo rótulo</div>
    <input id="nome" class="campo" type="text" maxlength="30" placeholder="Nome do rótulo" autocomplete="off">
    <div id="cores" class="cores"></div>
    <div class="acoes">
      <button id="excluir" class="btn perigo" type="button" hidden>Excluir</button>
      <button id="cancelar" class="btn" type="button">Cancelar</button>
      <button id="salvar" class="btn primario" type="button">Salvar</button>
    </div>
  </div>
  <button id="novo" class="novo" type="button">Criar um novo rótulo</button>
</div>
    EndContent

    BeginContent var cApp
<script>
(function () {
  'use strict';
  var estado = { rotulos: [], cores: [] };
  var edicao = null;
  var confirmaExclusao = false;
  var corSelecionada = '';
  var conectado = false;
  // Estado inicial embutido pelo Protheus ao gerar a página (rotProc); null quando a página veio sem ele
  var inicial = /*ESTADO*/null;
  var ICONE_EDITAR = '<svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor" aria-hidden="true">' +
    '<path d="M11.013 1.427a1.75 1.75 0 0 1 2.474 0l1.086 1.086a1.75 1.75 0 0 1 0 2.474l-8.61 8.61c-.21.21-.47.364-.756.445' +
    'l-3.251.93a.75.75 0 0 1-.927-.928l.929-3.25c.081-.286.235-.547.445-.758l8.61-8.61Zm.176 4.823L9.75 4.81l-6.286 6.287' +
    'a.253.253 0 0 0-.064.108l-.558 1.953 1.953-.558a.253.253 0 0 0 .108-.064Zm1.238-3.763a.25.25 0 0 0-.354 0L10.811 3.75' +
    'l1.439 1.44 1.263-1.263a.25.25 0 0 0 0-.354Z"></path></svg>';

  function el(id) { return document.getElementById(id); }

  function enviar(chave, dados) {
    if (!conectado) { el('erro').textContent = 'Aguardando comunicação com o Protheus...'; return; }
    twebchannel.jsToAdvpl(chave, JSON.stringify(dados || {}));
  }

  function hexDaCor(cor) {
    for (var i = 0; i < estado.cores.length; i++) {
      if (estado.cores[i].cor === cor) { return estado.cores[i].hex; }
    }
    return '#9e9e9e';
  }

  function corDoTexto(hex) {
    var r = parseInt(hex.substr(1, 2), 16), g = parseInt(hex.substr(3, 2), 16), b = parseInt(hex.substr(5, 2), 16);
    return (0.299 * r + 0.587 * g + 0.114 * b) > 160 ? '#1f2328' : '#ffffff';
  }

  function normaliza(texto) {
    return (texto || '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toUpperCase();
  }

  function alternar(rotulo, marcar) {
    rotulo.vinc = marcar;
    enviar('toggle', { id: rotulo.id, marcar: marcar });
  }

  function renderLista() {
    var lista = el('lista');
    var filtro = normaliza(el('busca').value.trim());
    var itens = estado.rotulos.filter(function (r) { return !filtro || normaliza(r.nome).indexOf(filtro) >= 0; });
    lista.textContent = '';
    if (!itens.length) {
      var vazio = document.createElement('div');
      vazio.className = 'vazio';
      vazio.textContent = estado.rotulos.length ? 'Nenhum rótulo encontrado.' : 'Nenhum rótulo cadastrado. Crie o primeiro abaixo.';
      lista.appendChild(vazio);
      return;
    }
    itens.forEach(function (r) {
      var linha = document.createElement('div');
      linha.className = 'item';

      var marca = document.createElement('input');
      marca.type = 'checkbox';
      marca.checked = !!r.vinc;
      marca.title = r.vinc ? 'Remover do produto' : 'Atribuir ao produto';
      marca.addEventListener('change', function () { alternar(r, marca.checked); });

      var pill = document.createElement('div');
      var hex = hexDaCor(r.cor);
      pill.className = 'pill';
      pill.textContent = r.nome;
      pill.style.background = hex;
      pill.style.color = corDoTexto(hex);
      pill.title = r.uso + ' produto(s) com este rótulo';
      pill.addEventListener('click', function () { marca.checked = !marca.checked; alternar(r, marca.checked); });

      var editar = document.createElement('button');
      editar.type = 'button';
      editar.className = 'editar';
      editar.title = 'Editar rótulo';
      editar.innerHTML = ICONE_EDITAR;
      editar.addEventListener('click', function () { abrirEditor(r); });

      linha.appendChild(marca);
      linha.appendChild(pill);
      linha.appendChild(editar);
      lista.appendChild(linha);
    });
  }

  function renderCores() {
    var grade = el('cores');
    grade.textContent = '';
    estado.cores.forEach(function (c) {
      var botao = document.createElement('button');
      botao.type = 'button';
      botao.className = 'cor' + (c.cor === corSelecionada ? ' sel' : '');
      botao.style.background = c.hex;
      botao.title = c.nome;
      botao.addEventListener('click', function () { corSelecionada = c.cor; renderCores(); });
      grade.appendChild(botao);
    });
  }

  function abrirEditor(rotulo) {
    edicao = rotulo ? { id: rotulo.id } : { id: 0 };
    confirmaExclusao = false;
    el('tituloEditor').textContent = rotulo ? 'Editar rótulo' : 'Novo rótulo';
    el('nome').value = rotulo ? rotulo.nome : el('busca').value.trim();
    corSelecionada = rotulo ? rotulo.cor : (estado.cores.length ? estado.cores[0].cor : '');
    el('excluir').hidden = !rotulo;
    el('excluir').textContent = 'Excluir';
    el('erro').textContent = '';
    el('editor').hidden = false;
    el('novo').hidden = true;
    renderCores();
    el('nome').focus();
  }

  function fecharEditor() {
    edicao = null;
    el('editor').hidden = true;
    el('novo').hidden = false;
    el('erro').textContent = '';
  }

  function salvar() {
    var nome = el('nome').value.trim();
    if (!nome) { el('erro').textContent = 'Informe o nome do rótulo.'; el('nome').focus(); return; }
    enviar(edicao.id ? 'update' : 'create', { id: edicao.id, nome: encodeURIComponent(nome), cor: corSelecionada });
  }

  function excluir() {
    var rotulo = estado.rotulos.filter(function (r) { return r.id === edicao.id; })[0];
    if (!confirmaExclusao) {
      confirmaExclusao = true;
      el('excluir').textContent = (rotulo && rotulo.uso) ? 'Confirmar exclusão (' + rotulo.uso + ' produto(s))' : 'Confirmar exclusão';
      return;
    }
    enviar('delete', { id: edicao.id });
  }

  // Aplica o estado recebido: numa falha o Protheus devolve só a mensagem de erro, e a lista atual é mantida
  function aplicar(novo) {
    if (!novo) { return; }
    if (novo.rotulos) { estado.rotulos = novo.rotulos; }
    if (novo.cores) { estado.cores = novo.cores; }
    if (novo.erro) {
      el('erro').textContent = novo.erro;
    } else {
      el('erro').textContent = '';
      if (novo.fechar) { fecharEditor(); }
    }
    renderLista();
  }

  function receber(chave, valor) {
    var novo;
    if (chave !== 'estado') { return; }
    try {
      novo = JSON.parse(valor);
    } catch (e) {
      el('erro').textContent = 'Falha ao ler os dados enviados pelo Protheus.';
      return;
    }
    aplicar(novo);
  }

  el('busca').addEventListener('input', renderLista);
  el('busca').addEventListener('keydown', function (e) {
    if (e.key === 'Enter' && el('busca').value.trim() && !document.querySelector('#lista .item')) { abrirEditor(null); }
  });
  el('novo').addEventListener('click', function () { abrirEditor(null); });
  el('cancelar').addEventListener('click', fecharEditor);
  el('salvar').addEventListener('click', salvar);
  el('excluir').addEventListener('click', excluir);
  el('nome').addEventListener('keydown', function (e) {
    if (e.key === 'Enter') { salvar(); }
    if (e.key === 'Escape') { fecharEditor(); }
  });

  // Lista exibida já na abertura, com o estado embutido, sem esperar a conexão do canal
  aplicar(inicial);

  window.onload = function () {
    el('busca').focus();
    // Os eventos da tela já estão ligados; sem a biblioteca do canal, apenas informa (não interrompe o script)
    if (typeof twebchannel === 'undefined') {
      el('erro').textContent = 'Biblioteca de comunicação (sstwebchannel.js) não carregada.';
      return;
    }
    twebchannel.advplToJs = receber;
    // Dados de conexão (porta, tipo do SmartClient, thread e origem) informados pelo TWebEngine na URL
    // O canal é usado nas ações; só pede a carga quando a página veio sem o estado inicial
    twebchannel.connect(function () { conectado = true; if (!inicial) { enviar('carga', {}); } });
    // Sem conexão em 6 segundos: informa na tela (diagnóstico)
    setTimeout(function () {
      if (!conectado) { el('erro').textContent = 'Sem comunicação com o Protheus: as alterações não serão gravadas. Feche e abra a tela novamente.'; }
    }, 6000);
  };
})();
</script>
    EndContent

    // Script do canal (publicado na mesma pasta) e documento somente ASCII: acentos como entidades HTML na
    // marcação e como \uXXXX no JavaScript
    cTopo := StrTran( cTopo, '</head>', '<script src="'+ cScript +'"></script>'+ Chr(13) + Chr(10) +'</head>' )
    cHtml := rotAscii( cTopo, .F. ) + rotAscii( cApp, .T. ) +'</body>'+ Chr(13) + Chr(10) +'</html>'

    // Estado inicial da tela (JSON somente ASCII, com < e > escapados) no lugar do marcador do script
    If ! Empty( cEstado )
        cHtml := StrTran( cHtml, '/*ESTADO*/null', cEstado )
    EndIf

Return cHtml
