#include 'totvs.ch'
#include 'topconn.ch'

#define URL_SUFIXO '/rest/v1'       // Sufixo que ser� utilizado para complementar a URL do banco 
#define EOL        chr(13)+chr(10)  // fim de linha

/*/{Protheus.doc} JSSUPABASE
Fun��o central e conex�o com a API da base de dados do supabase
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 18/08/2023
@param cMethod, character, m�todo que ser� utilizado para conex�o (get, post, head)
@param cTable, character, string com tabela do supabase
@param aFields, array, vetor de campos a serem obtidos/atualizados conforme o m�todo utilizado
@param cWhere, character, sintaxe da query de filtro para obten��o/atualiza��o dos dados
@param aData, array, vetor de dados a serem enviados quando opera��o de atualiza��o
@param cOrder, character, string contendo ordena��o requerida para os dados obtidos
@return object, oResult
/*/
User Function JSSUPABASE( cMethod, cTable, aFields, cWhere, aData, cOrderBy )

    Local oResult          as object
    Local cResult   := ""  as character
    Local oJson            as object
    Local oClient          as object
    Local aHeader   := {}  as array
    Local nTry      := 0   as numeric
    Local lSuccess  := .F. as logical
    Local cFields   := ""  as character
    Local cParser          as character
    Local cParams   := ""  as character
    local lIsBlind  := IsBlind()
    local cDataBase := U_JSGETDB() 
    local cKey      := U_JSGETKEY()

    default cMethod   := ""     //"GET"
    default cTable    := ""     //"agenda"
    default aFields   := {}     //{"ID","AG_CODUSER","AG_CODNUCLEO","AG_CODFUNCAO","AG_NOMECHEKLIST"}
    default cWhere    := ""     //"AG_NOMECHEKLIST=like.*T01*"
    default aData     := {} 
    default cOrder    := ""     //"AGE.asc,NAME.desc"

    // Instancia um objeto para conex�o usando WS Rest
    oClient := FWRest():New( cDataBase + URL_SUFIXO )
    oClient:SetPath( '/'+ cTable )

    // Define o header da requisi��o
    aAdd( aHeader, "Accept-Encoding: UTF-8" )
    aAdd( aHeader, "Content-Type: application/json; charset=iso-8859-1" )
    aAdd( aHeader, "apiKey: "+ cKey )

    if Upper( cMethod ) $ 'GET|HEAD'
        
        // Define campos que dever�o ser retornados do webservice
        if len( aFields ) > 0
            aEval( aFields, {|x| cFields += iif(Empty(cFields),'',',') + x } )
            cParams := 'select='+ cFields
        endif

        // Define os par�metros que ser�o enviados ao Get
        cParams += iif( !Empty( cParams ) .and. !Empty( cWhere ), '&', '' ) + AllTrim( cWhere )
        cParams += iif( !Empty( cParams ) .and. !Empty( cOrderBy ), '&', '' ) + iif( !Empty( cOrderBy), "order=", "" ) + AllTrim( cOrderBy )

        while ! lSuccess .and. nTry < 5
            nTry++ 
            lSuccess := oClient:Get( aHeader, cParams )
            if lSuccess
                cResult := oClient:GetResult()
                oResult := JsonObject():New()
                cParser := oResult:fromJson( cResult ) 
                if ! cParser == nil
                    if lIsBlind
                        ConOut( 'Tentativa ['+ cValToChar( nTry ) +']: Falha na realiza��o do parser do retorno.' )
                        ConOut( 'Retorno.: '+ cResult )
                        ConOut( 'Parser..: '+ cParser )
                    elseif nTry == 5
                        hlp( Upper( cMethod )+ ' FAILED',;
                               'Parser: '+ cParser,;
                               'Retorno: '+ cResult )
                    endif
                    lSuccess := .F.
                    oResult  := Nil
                endif
            else
                if lIsBlind
                    ConOut( 'Tentativa ['+ cValToChar( nTry ) +']: '+ oClient:GetLastError() )
                elseif nTry ==5
                    hlp( Upper( cMethod )+ ' FAILED',;
                               'Falha durante o processo de comunica��o com base do aplicativo',;
                               'Falha: '+ oClient:GetLastError() )
                endif
                Sleep(1000)           
            endif       
        end
    elseif Upper( cMethod ) == 'POST'        // Manuten��o e insert de registros
        
        // Quando utilizado o m�todo POST, realiza UPSERT e resolve as duplicidades realizando merge dos registros atrav�s
        // da chave abaixo adicionada ao cabe�alho da requisi��o
        aAdd( aHeader, "Prefer: resolution=merge-duplicates" )
        aAdd( aHeader, "Prefer: return=representation" )
        oJson := doJson( aFields, aData )
        if oJson != Nil
            
            // Define o json no body da requisi��o�
            oClient:SetPostParams( oJson:toJson() )

            while ! lSuccess .and. nTry < 5
                nTry++
                
                lSuccess := oClient:Post( aHeader )
                if lSuccess
                    cResult := oClient:GetResult()
                    oResult := JsonObject():New()
                    cParser := oResult:fromJson( cResult ) 
                    if ! cParser == nil
                        if lIsBlind
                            ConOut( 'Tentativa ['+ cValToChar( nTry ) +']: Falha na realiza��o do parser do retorno.' )
                            ConOut( 'Retorno.: '+ cResult )
                            ConOut( 'Parser..: '+ cParser )
                        elseif nTry == 5
                            hlp( Upper( cMethod )+ ' FAILED',;
                                'Parser: '+ cParser,;
                                'Retorno: '+ cResult )
                        endif
                        lSuccess := .F.
                        oResult  := Nil
                    endif
                else
                    if lIsBlind
                        ConOut( 'Tentativa ['+ cValToChar( nTry ) +']: '+ oClient:GetResult() )
                    elseif nTry ==5
                        hlp( Upper( cMethod )+ ' FAILED',;
                                'Falha durante o processo de comunica��o com o aplicativo',;
                                oClient:GetResult() )
                    endif
                    Sleep(1000)           
                endif       
            end
        else
            lSuccess := .F.
            oResult  := Nil
            if lIsBlind
                ConOut( 'Falha na estrutura dos vetores enviados para a montagem do Json' )
                ConOut( varInfo( 'Campos', aFields ) )
                ConOut( varInfo( 'Dados' , aData ) )
            else
                hlp( 'JSON INVALID',;
                        varInfo( 'Campos', aFields ),;
                        varInfo( 'Dados[1]', aData[1] ) )
            endif
        endif
    else
        if lIsBlind
            ConOut( 'O m�todo '+ cMethod +' inv�lido para utiliza��o do cliente de comunica��o com supabase' )
        else
            hlp( 'INVALID METHOD '+ Upper( cMethod ),;
                    'Este processo de integra��o n�o est� preparado para utiliza��o do m�todo invocado ('+ Upper( cMethod ) +').',;
                    'Verifique se o m�todo utilizado � o mais adequado para a opera��o que est� realizando.' )
        endif
    endif  

    FreeObj( oClient )
    oClient := Nil
  
return oResult

/*/{Protheus.doc} doJson
Fun��o respons�vel pela montagem do Json com base nos dados que o usu�rio enviou
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 18/08/2023
@param aFields, array, vetor de campos do json
@param aData, array, vetor bi-dimensional contendo os dados a serem populados no json
@return object, oJson
/*/
static function doJson( aFields, aData )
    
    Local oJson as objecty
    Local aJson := {} as array
    Local nX    := 0 as numeric
    Local nY    := 0 as numeric

    // Antes de prosseguir, valida: 
    // 1. Se o vetor de dados tem conte�do
    // 2. Se o vetor de campos tem conte�do
    // 3. Se o tamanho do vetor de campos � o mesmo tamanho do primeiro registro do vetor de dados
    if Len( aData ) > 0 .and. len( aFields ) > 0 .and. len( aFields ) == len( aData[1] )
        oJson := JsonObject():New()
        for nX := 1 to len(aData )
            aAdd( aJson, JsonObject():New() )
            for nY := 1 to len( aFields )
                aJson[len(aJson)][aFields[nY]] := convData(aData[nX][nY])
            next nY

            // Quando o DATAATL j� vier nos vetores da montagem do JSON, respeita o conte�do que j� veio preenchido
            if aScan( aFields, {|x| AllTrim( x ) == 'DATAATL' } ) == 0
                aJson[len(aJson)]["DATAATL"] := StrTran( FWTimeStamp(3), 'T', ' ' )
            endif

        next nX
        // Cria um vetor de Json com base no array que acabou de ser populado
        oJson:set(aJson)
    endif

return oJson

/*/{Protheus.doc} convData
Converte valores para o padr�o aceito na estrutura de um Json
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 18/08/2023
@param xData, variadic, informa��o que vai ser atribuida ao campo do Json
@return variadic, xInfo
/*/
static function convData( xData )    
    
    local xRet

    if valType( xData ) == 'D'
        if ! Empty( xData )
            xRet := StrTran( FWTimeStamp( 3, xData, '00:00:00' ), 'T', ' ' )
        else
            xRet := Nil
        endif
    elseif valType( xData ) == 'L'
        xRet := iif( xData, 'true', 'false' )
    elseif valType( xData ) == 'C'
        xRet := EncodeUTF8( Trim( xData ))        // quando charactere, remove os espa�os e converte em UTF8 no formato cp1252
    else
        xRet := xData
    endif

return xRet

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
