#include 'totvs.ch'

#define MAX_WHERE 2000      // Tamanho máximo aceito para a expressão de filtro devolvida pela IA
#define MAX_FORN  50        // Quantidade máxima de fornecedores candidatos lidos na busca por nome

/*/{Protheus.doc} JSAIFLT
Filtro de produtos por linguagem natural (IA) do SmartSupply. Envia a descrição digitada pelo usuário à
Edge Function "ai-filter" do Supabase (que consulta a Claude API), valida a expressão SQL devolvida
(U_JSAIVLD) e resolve no cadastro (SA2) o fornecedor citado no texto.
A expressão devolvida é aplicada por U_JSQRYINF somente sobre as colunas da tabela derivada TEMP.
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 26/09/2026
@param cTexto, character, descrição do filtro digitada pelo usuário
@return json, oRet - propriedades where, tipos, fornecedor, loja, fornome e explicacao, ou Nil quando não
foi possível interpretar/validar o filtro (o motivo já é exibido ao usuário)
/*/
User Function JSAIFLT( cTexto )

    Local oRet    as object
    Local oResp   as object
    Local oReq    := JsonObject():New() as object
    Local cErro   := "" as character
    Local cWhere  := "" as character
    Local cForn   := "" as character
    Local cTipos  := "" as character
    Local cTipo   := "" as character
    Local aForn   := {} as array
    Local aTipos  := {} as array
    Local nX      := 0  as numeric
    Local lValid  := .T. as logical

    Default cTexto := ""

    oReq['texto']   := EncodeUTF8( AllTrim( cTexto ) )
    // CNPJ raiz da empresa, mesma regra de identificação do cliente no Supabase usada em JSNOTIFY/JSGLBPAR
    oReq['empresa'] := StrTran( SubStr( SM0->M0_CGC, 1, 8 ), "        ", "99999999" )
    oReq['usuario'] := EncodeUTF8( AllTrim( UsrRetName( RetCodUsr() ) ) )
    oReq['banco']   := AllTrim( TCGetDB() )
    oReq['colunas'] := aiCols()
    oReq['giro']    := aiGiro()

    MsAguarde( {|| oResp := aiCall( oReq, @cErro ) }, 'Filtro por IA', 'Interpretando a descrição do filtro...' )
    FreeObj( oReq )

    If ValType( oResp ) != 'J'
        hlp( 'FILTRO_IA', 'Não foi possível interpretar o filtro com a IA.', cErro )
        lValid := .F.
    EndIf

    // Expressão SQL: só é aceita se passar pela validação por lista de termos permitidos
    If lValid
        cWhere := jChr( oResp['where'] )
        If ! U_JSAIVLD( cWhere, @cErro )
            hlp( 'FILTRO_IA', 'A IA gerou um filtro que não pôde ser aceito por segurança.',;
                 cErro +'. Reescreva a descrição de forma mais simples e tente novamente.' )
            lValid := .F.
        EndIf
    EndIf

    // Tipos de produto: apenas códigos alfanuméricos de 2 posições, no formato esperado pelo filtro ("MP/PA")
    If lValid .and. ValType( oResp['tipos'] ) == 'A'
        aTipos := oResp['tipos']
        For nX := 1 To Len( aTipos )
            cTipo := Upper( AllTrim( jChr( aTipos[nX] ) ) )
            If Len( cTipo ) == 2 .and. aiAlfaNum( cTipo )
                cTipos += cTipo +'/'
            EndIf
        Next nX
    EndIf

    // Fornecedor citado no texto: resolve o código/loja no cadastro
    If lValid
        cForn := AllTrim( jChr( oResp['fornecedor'] ) )
        If ! Empty( cForn )
            aForn := aiForn( cForn )
            If Len( aForn ) == 0
                hlp( 'FILTRO_IA', 'O fornecedor "'+ cForn +'" citado no filtro não foi encontrado no cadastro.',;
                     'Confira o nome do fornecedor e tente novamente.' )
                lValid := .F.
            ElseIf aScan( aForn, {|x| x[1] != aForn[1][1] } ) > 0
                hlp( 'FILTRO_IA', 'Mais de um fornecedor corresponde a "'+ cForn +'": '+ aiLstFor( aForn ) +'.',;
                     'Informe o nome do fornecedor de forma mais completa na descrição do filtro.' )
                lValid := .F.
            EndIf
        EndIf
    EndIf

    If lValid .and. Empty( cWhere ) .and. Empty( cTipos ) .and. Len( aForn ) == 0
        hlp( 'FILTRO_IA', 'A IA não identificou nenhum critério de filtro na descrição informada.',;
             'Descreva quais produtos deseja analisar (ex.: "chapas MDF da Fibraplac com estoque abaixo do mínimo").' )
        lValid := .F.
    EndIf

    If lValid .and. ! Empty( cTipos )
        cTipos := Left( cTipos, Len( cTipos ) - 1 )     // Remove a barra final
    EndIf

    If lValid
        oRet := JsonObject():New()
        oRet['where']      := cWhere
        oRet['tipos']      := cTipos
        oRet['fornecedor'] := ""
        oRet['loja']       := ""
        oRet['fornome']    := ""
        oRet['explicacao'] := jChr( oResp['explicacao'] )
        If Len( aForn ) > 0
            oRet['fornecedor'] := aForn[1][1]
            oRet['fornome']    := AllTrim( aForn[1][3] )
            // Mais de uma loja do mesmo fornecedor: não filtra loja (considera todas)
            If Len( aForn ) == 1
                oRet['loja'] := aForn[1][2]
            EndIf
        EndIf
    EndIf

    If ValType( oResp ) == 'J'
        FreeObj( oResp )
    EndIf

Return oRet

/*/{Protheus.doc} JSAIVLD
Valida a expressão de filtro (cláusula WHERE) gerada pela IA por meio de um analisador léxico baseado em
lista de termos PERMITIDOS: colunas da tabela derivada TEMP de U_JSQRYINF, operadores de comparação,
AND/OR/NOT/IN/LIKE/BETWEEN/IS/NULL, as funções UPPER/COALESCE/ABS, números e literais entre aspas simples.
Qualquer outro termo (SELECT, UNION, nomes de tabela, comentários, ponto e vírgula, etc.) invalida a expressão.
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 26/09/2026
@param cWhere, character, expressão a ser validada
@param cErro, character, (referência) motivo da rejeição
@return logical, lValid
/*/
User Function JSAIVLD( cWhere, cErro )

    Local lValid  := .T. as logical
    Local aCols   := aiColDef() as array
    Local aPalav  := { 'AND', 'OR', 'NOT', 'IN', 'LIKE', 'BETWEEN', 'IS', 'NULL' } as array
    Local aFunc   := { 'UPPER', 'COALESCE', 'ABS' } as array
    Local aProib  := { ';', '--', '/*', '*/', '\', '"', '[', ']', '`', '#', '@', '{', '}' } as array
    Local nLen    := 0  as numeric
    Local nPos    := 1  as numeric
    Local nParen  := 0  as numeric
    Local nX      := 0  as numeric
    Local cChr    := "" as character
    Local cTok    := "" as character
    Local lFim    := .F. as logical

    Default cWhere := ""

    cErro  := ""
    cWhere := AllTrim( cWhere )
    nLen   := Len( cWhere )

    If nLen > MAX_WHERE
        cErro  := 'Expressão de filtro maior que o limite de '+ cValToChar( MAX_WHERE ) +' caracteres'
        lValid := .F.
    EndIf

    For nX := 1 To Len( aProib )
        If lValid .and. aProib[nX] $ cWhere
            cErro  := 'Sequência não permitida na expressão: '+ aProib[nX]
            lValid := .F.
        EndIf
    Next nX

    While lValid .and. nPos <= nLen
        cChr := SubStr( cWhere, nPos, 1 )
        If cChr $ ' '+ Chr(9) + Chr(10) + Chr(13)
            nPos++
        ElseIf cChr == "'"
            // Literal: avança até a aspa de fechamento, tratando '' como aspa escapada
            nPos++
            lFim := .F.
            While nPos <= nLen .and. ! lFim
                If SubStr( cWhere, nPos, 1 ) == "'"
                    If SubStr( cWhere, nPos + 1, 1 ) == "'"
                        nPos += 2
                    Else
                        lFim := .T.
                        nPos++
                    EndIf
                Else
                    nPos++
                EndIf
            EndDo
            If ! lFim
                cErro  := 'Texto entre aspas sem fechamento na expressão'
                lValid := .F.
            EndIf
        ElseIf IsDigit( cChr )
            While nPos <= nLen .and. ( IsDigit( SubStr( cWhere, nPos, 1 ) ) .or. SubStr( cWhere, nPos, 1 ) == '.' )
                nPos++
            EndDo
        ElseIf IsAlpha( cChr ) .or. cChr == '_'
            cTok := ""
            While nPos <= nLen .and. aiIdent( SubStr( cWhere, nPos, 1 ) )
                cTok += SubStr( cWhere, nPos, 1 )
                nPos++
            EndDo
            cTok := Upper( cTok )
            If Left( cTok, 5 ) == 'TEMP.'
                cTok := SubStr( cTok, 6 )
            EndIf
            If aScan( aCols, {|x| x[1] == cTok } ) == 0 .and.;
               aScan( aPalav, {|x| x == cTok } ) == 0 .and.;
               aScan( aFunc, {|x| x == cTok } ) == 0
                cErro  := 'Termo não permitido na expressão: '+ cTok
                lValid := .F.
            EndIf
        ElseIf cChr $ '=<>!+-*/,'
            nPos++
        ElseIf cChr == '('
            nParen++
            nPos++
        ElseIf cChr == ')'
            nParen--
            nPos++
            If nParen < 0
                cErro  := 'Parênteses desbalanceados na expressão'
                lValid := .F.
            EndIf
        Else
            cErro  := 'Caractere não permitido na expressão: '+ cChr
            lValid := .F.
        EndIf
    EndDo

    If lValid .and. nParen != 0
        cErro  := 'Parênteses desbalanceados na expressão'
        lValid := .F.
    EndIf

Return lValid

/*/{Protheus.doc} aiColDef
Colunas da tabela derivada TEMP de U_JSQRYINF que podem ser usadas pela IA no filtro (fonte única para o
contexto enviado à IA e para a validação da expressão devolvida)
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 26/09/2026
@return array, aCols - { nome, tipo (C/N), descrição }
/*/
Static Function aiColDef()

    Local aCols := {} as array

    aAdd( aCols, { 'FILIAL' , 'C', 'Código da filial' } )
    aAdd( aCols, { 'B1_COD' , 'C', 'Código do produto' } )
    aAdd( aCols, { 'B1_DESC', 'C', 'Descrição do produto (gravada em maiúsculas)' } )
    aAdd( aCols, { 'B1_TIPO', 'C', 'Tipo do produto (ex.: MP, PA, PI, ME, MC)' } )
    aAdd( aCols, { 'B1_UM'  , 'C', 'Unidade de medida' } )
    aAdd( aCols, { 'B1_LM'  , 'N', 'Lote mínimo de compra' } )
    aAdd( aCols, { 'B1_QE'  , 'N', 'Quantidade por embalagem' } )
    aAdd( aCols, { 'B1_LE'  , 'N', 'Lote econômico de compra' } )
    aAdd( aCols, { 'B1_PE'  , 'N', 'Prazo de entrega do produto, em dias' } )
    aAdd( aCols, { 'B1_EMIN', 'N', 'Estoque mínimo (ponto de pedido)' } )
    aAdd( aCols, { 'B1_EMAX', 'N', 'Estoque máximo' } )
    aAdd( aCols, { 'ESTOQUE', 'N', 'Saldo atual em estoque nos armazéns considerados pelo painel' } )
    aAdd( aCols, { 'EMPENHO', 'N', 'Quantidade reservada/empenhada do saldo em estoque' } )
    aAdd( aCols, { 'QTDBLOQ', 'N', 'Quantidade em pedidos de compra bloqueados (aguardando aprovação)' } )
    aAdd( aCols, { 'QTDCOMP', 'N', 'Quantidade em pedidos de compra em aberto (liberados)' } )
    aAdd( aCols, { 'PRVENT' , 'C', 'Data prevista da próxima entrega no formato AAAAMMDD (brancos quando não há)' } )
    aAdd( aCols, { 'QTDSOL' , 'N', 'Quantidade em solicitações de compra em aberto' } )
    aAdd( aCols, { 'ORDPROD', 'N', 'Quantidade em ordens de produção em aberto' } )
    aAdd( aCols, { 'CONMED' , 'N', 'Consumo médio DIÁRIO do produto (0.0001 quando não há consumo)' } )
    aAdd( aCols, { 'INDINC' , 'N', 'Índice de incidência do produto, usado na classificação de giro' } )
    aAdd( aCols, { 'GRUPO'  , 'C', 'Grupo do produto' } )
    If SB1->( FieldPos( 'B1_XGPTP' ) ) > 0
        aAdd( aCols, { 'GRPTAB', 'C', 'Grupo de tabela de preço do fornecedor' } )
    EndIf
    aAdd( aCols, { 'FORNOME', 'C', 'Razão social do fornecedor padrão do produto (maiúsculas)' } )
    aAdd( aCols, { 'FORFANT', 'C', 'Nome fantasia do fornecedor padrão do produto (maiúsculas)' } )

Return aCols

/*/{Protheus.doc} aiCols
Monta o vetor Json de colunas permitidas enviado à IA como contexto
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 26/09/2026
@return array, aJson
/*/
Static Function aiCols()

    Local aCols := aiColDef() as array
    Local aJson := {} as array
    Local nX    := 0  as numeric

    For nX := 1 To Len( aCols )
        aAdd( aJson, JsonObject():New() )
        aJson[nX]['nome']      := aCols[nX][1]
        aJson[nX]['tipo']      := aCols[nX][2]
        aJson[nX]['descricao'] := EncodeUTF8( aCols[nX][3] )
    Next nX

Return aJson

/*/{Protheus.doc} aiGiro
Limites de INDINC que definem as classificações de giro nas configurações do painel (mesma regra de
chgFilter no GMPAICOM): crítico >= aConfig[10], alto >= aConfig[11], médio >= aConfig[12], baixo >=
aConfig[13] e sem giro abaixo de aConfig[13]
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 26/09/2026
@return json, oGiro (Nil quando as configurações não estiverem disponíveis)
/*/
Static Function aiGiro()

    Local oGiro as object

    If Type( 'aConfig' ) == 'A' .and. Len( aConfig ) >= 13
        oGiro := JsonObject():New()
        oGiro['critico'] := aConfig[10]
        oGiro['alto']    := aConfig[11]
        oGiro['medio']   := aConfig[12]
        oGiro['baixo']   := aConfig[13]
    EndIf

Return oGiro

/*/{Protheus.doc} aiCall
Envia a requisição à Edge Function "ai-filter" do Supabase (a chave da Claude API fica armazenada como
secret da função, nunca no RPO)
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 26/09/2026
@param oReq, json, corpo da requisição
@param cErro, character, (referência) descrição da falha
@return json, oResp (Nil em caso de falha)
/*/
Static Function aiCall( oReq, cErro )

    Local oClient := FWRest():New( U_JSGETDB() +'/functions/v1' ) as object
    Local oResp   as object
    Local aHeader := {} as array
    Local cKey    := U_JSGETKEY() as character
    Local cResult := "" as character
    Local cParser as character

    oClient:SetPath( '/ai-filter' )
    aAdd( aHeader, 'Content-Type: application/json; charset=utf-8' )
    aAdd( aHeader, 'apikey: '+ cKey )
    aAdd( aHeader, 'Authorization: Bearer '+ cKey )
    oClient:SetPostParams( oReq:toJson() )

    If oClient:Post( aHeader )
        cResult := oClient:GetResult()
    Else
        cErro := 'Falha de comunicação com o serviço de IA: '+ oClient:GetLastError()
        If ValType( oClient:GetResult() ) == 'C'
            cResult := oClient:GetResult()
        EndIf
    EndIf

    If ! Empty( cResult )
        oResp   := JsonObject():New()
        cParser := oResp:FromJson( cResult )
        If ValType( cParser ) == 'C'
            cErro := 'Retorno inválido do serviço de IA: '+ cParser
            FreeObj( oResp )
        ElseIf oResp:hasProperty( 'erro' )
            cErro := jChr( oResp['erro'] )
            FreeObj( oResp )
        ElseIf ! Empty( cErro )
            FreeObj( oResp )
        EndIf
    EndIf

    FreeObj( oClient )

Return oResp

/*/{Protheus.doc} aiForn
Busca no cadastro de fornecedores (SA2) os candidatos cujo nome ou nome fantasia contém o texto informado
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 26/09/2026
@param cNome, character, nome do fornecedor citado no filtro
@return array, aForn - { código, loja, nome }
/*/
Static Function aiForn( cNome )

    Local aForn  := {} as array
    Local oExec  as object
    Local cQuery := "" as character
    Local cAlias := "" as character
    Local cBusca := '%'+ Upper( AllTrim( cNome ) ) +'%' as character

    cQuery := "SELECT A2_COD, A2_LOJA, A2_NOME FROM "+ RetSqlName( 'SA2' ) +" "
    cQuery += "WHERE A2_FILIAL = ? "
    cQuery += "  AND ( UPPER(A2_NOME) LIKE ? OR UPPER(A2_NREDUZ) LIKE ? ) "
    cQuery += "  AND A2_MSBLQL <> '1' "
    cQuery += "  AND D_E_L_E_T_ = ' ' "
    cQuery += "ORDER BY A2_COD, A2_LOJA "
    cQuery := ChangeQuery( cQuery )

    oExec := FwExecStatement():New( cQuery )
    oExec:SetString( 1, FWxFilial( 'SA2' ) )
    oExec:SetString( 2, cBusca )
    oExec:SetString( 3, cBusca )
    cAlias := oExec:OpenAlias()

    While ! ( cAlias )->( EOF() ) .and. Len( aForn ) < MAX_FORN
        aAdd( aForn, { ( cAlias )->A2_COD, ( cAlias )->A2_LOJA, ( cAlias )->A2_NOME } )
        ( cAlias )->( DBSkip() )
    EndDo
    ( cAlias )->( DBCloseArea() )
    oExec:Destroy()

Return aForn

/*/{Protheus.doc} aiLstFor
Monta a lista (até 10) de nomes de fornecedores candidatos para exibir ao usuário
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 26/09/2026
@param aForn, array, candidatos devolvidos por aiForn
@return character, cLista
/*/
Static Function aiLstFor( aForn )

    Local cLista := "" as character
    Local nX     := 0  as numeric

    For nX := 1 To Min( Len( aForn ), 10 )
        If ! AllTrim( aForn[nX][3] ) $ cLista
            If ! Empty( cLista )
                cLista += ', '
            EndIf
            cLista += AllTrim( aForn[nX][3] )
        EndIf
    Next nX

Return cLista

/*/{Protheus.doc} aiIdent
Indica se o caractere pode compor um identificador (letra, dígito, sublinhado ou ponto de qualificação)
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 26/09/2026
@param cChr, character, caractere avaliado
@return logical, lIdent
/*/
Static Function aiIdent( cChr )
Return IsAlpha( cChr ) .or. IsDigit( cChr ) .or. cChr == '_' .or. cChr == '.'

/*/{Protheus.doc} aiAlfaNum
Indica se o texto contém apenas letras e dígitos
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 26/09/2026
@param cTexto, character, texto avaliado
@return logical, lAlfaNum
/*/
Static Function aiAlfaNum( cTexto )

    Local lAlfaNum := .T. as logical
    Local nX       := 0  as numeric

    For nX := 1 To Len( cTexto )
        If ! ( IsAlpha( SubStr( cTexto, nX, 1 ) ) .or. IsDigit( SubStr( cTexto, nX, 1 ) ) )
            lAlfaNum := .F.
        EndIf
    Next nX

Return lAlfaNum

/*/{Protheus.doc} jChr
Converte com segurança um valor lido do Json em caractere no padrão do sistema (null -> "", UTF-8 -> cp1252)
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 26/09/2026
@param xVal, variant, valor lido do Json
@return character, cRet
/*/
Static Function jChr( xVal )

    Local cRet := "" as character
    Local xDec

    If ValType( xVal ) == 'C'
        xDec := DecodeUTF8( xVal )
        If ValType( xDec ) == 'C'
            cRet := xDec
        Else
            cRet := xVal
        EndIf
    EndIf

Return cRet

/*/{Protheus.doc} hlp
Função facilitadora para utilização da função Help do Protheus
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 26/09/2026
@param cTitle, character, título da janela
@param cFail, character, informações sobre a falha
@param cHelp, character, texto de ajuda
/*/
Static Function hlp( cTitle, cFail, cHelp )
Return Help( ,, cTitle,, cFail, 1, 0, NIL, NIL, NIL, NIL, NIL, { cHelp } )
