#include 'totvs.ch'

/*/{Protheus.doc} AVGETVER
Fun��o interna para retornar string contendo vers�o atual da integra��o com o app de avicola no formato V.D_C (Data Compila��o), onde:
V=Vers�o do PlugIn
D=Vers�o do Dicion�rio de dados (sempre que houver altera��o no dicion�rio, altera a vers�o)
C=Compila��o Sequencial para o dicion�rio corrente
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 22/08/2023
@return character, cVersion
/*/
User Function AVGETVER()
    local aDet := U_AVDETVER()
return aDet[Len(aDet)][1]+"."+;
        aDet[Len(aDet)][2] +"_"+;
        aDet[Len(aDet)][3] +" ( "+;
        aDet[Len(aDet)][4] +" )"

/*/{Protheus.doc} AVDETVER
Detalhes das vers�es liberadas
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 18/09/2023
@return array, aDet[n]{ cVersion, cDictionary, cCompilation, cDate}
/*/
User Function AVDETVER()

    local aDet := {} as array
    aAdd( aDet, { "1","001", "01", "18/09/2023", "Integra��o com Wizard, Cadastro de Usu�rios e Integra��o de Nucleos" } )
    aAdd( aDet, { "1","002", "01", "20/09/2023", "Integra��o e carga inicial do cadastro de produtos" } )
    aAdd( aDet, { "1","003", "01", "20/09/2023", "Adi��o de chave geral para controle de ativa��o/desativa��o da integra��o" } )
    aAdd( aDet, { "1","003", "02", "24/09/2023", "Configura��o via ERP do v�nculo entre usu�rios do APP e o N�cleo" } )
    aAdd( aDet, { "1","004", "01", "26/09/2023", "Sincroniza��o de Lotes" } )
    aAdd( aDet, { "1","005", "02", "27/09/2023", "Altera��o do v�nculo de usu�rios do App com N�cleo para utilizar tabela ZHV" } )
    aAdd( aDet, { "1","005", "03", "28/09/2023", "Sincroniza��o de usu�rios x n�cleo quando utilizado fun��o de replica��o em massa" } )
    aAdd( aDet, { "1","006", "01", "28/09/2023", "Sincroniza��o de cadastro de fun��es" } )
    aAdd( aDet, { "1","007", "01", "28/09/2023", "Altera��o estrutura de produto para indicar quais cadastros devem ser sincronizados, "+;
                                                 "incluido tratativa na formata��o do arquivo JSON para que os dados do tipo string sejam enviados sem espa�os em branco e "+;
                                                 "criado r�guas de processamento para exibir status no compatibilizador." } )
    aAdd( aDet, { "1","007", "02", "28/09/2023", "Corrigido bug que desposicionava registro quando utilizava fun��o U_AVIDBYNM" } )
    aAdd( aDet, { "1","008", "01", "29/09/2023", "Adicionado sincroniza��o de grupos de produtos" } )
    aAdd( aDet, { "1","008", "02", "29/09/2023", "Adicionado sincroniza��o do grupo do produto no ponto de entrada do pr�prio cadastro de produto" } )
    aAdd( aDet, { "1","009", "01", "29/09/2023", "Adicionado sincroniza��o de subitens e adicionado novas regras para os subitens no compatibilizador" } )
    aAdd( aDet, { "1","009", "02", "02/10/2023", "Ajustado rotina de cadastro APBCAD02 (Subitens) para sincronizar registros com o App" } )
    aAdd( aDet, { "1","010", "01", "04/10/2023", "Campo de controle de envio ao App na tabela de SubItens, envio do campo Tipo de N�cleo, "+;
                                                 "cria��o do campo Sexo na tabela de SubItens" } )
    aAdd( aDet, { "1","011", "01", "04/10/2023", "Sincroniza��o do cadastro de Ocorr�ncias (SU9)" } )
    aAdd( aDet, { "1","011", "02", "20/10/2023", "Ajustado sincroniza��o de Usu�rios e modificado regra para sincroniza��o de subitens" } )
    aAdd( aDet, { "1","011", "02", "27/10/2023", "Ajuste de error-log na rotina de v�nculo de usu�rio x n�cleo" } )
    aAdd( aDet, { "1","012", "01", "03/11/2023", "Adi��o de campo de controle no cadastro de sub-itens para agrupamento no app" } )
    aAdd( aDet, { "1","012", "02", "21/11/2023", "Altera��o na rotina de cadastro de usu�rio do App no Protheus para contemplar v�nculo de N�cleo x Usu�rio" } )
    aAdd( aDet, { "1","013", "01", "28/11/2023", "Novo campo no cadastro de n�cleo para indicativo de quantidade de avi�rios" } )
    aAdd( aDet, { "1","013", "02", "29/11/2023", "Novo est�gio no Wizard de configura��es para contemplar configura��o do JOB de integra��o" } )
    aAdd( aDet, { "1","013", "03", "30/11/2023", "Corre��o de bug durante verifica��o do indicativo de que o JOB est� ou n�o ativo." } )
    aAdd( aDet, { "1","013", "04", "01/12/2023", "Ajuste da matriz para envio do campo que indica a quantidade de avi�rios de um n�cleo." } )
    aAdd( aDet, { "1","013", "05", "06/12/2023", "Grava��o do conte�do do campo Box durante processo de integra��o dos dados de coleta com o ERP" } )
    aAdd( aDet, { "1","014", "01", "08/12/2023", "Integra��o de Ocorr�ncias" } )
    aAdd( aDet, { "1","015", "01", "16/12/2023", "Integra��o de Solicita��es de Manuten��o" } )
    aAdd( aDet, { "1","015", "02", "13/04/2024", "Ponto de Entrada na rotina de Manuten��o Corretiva para exibir imagens da Ordem de Servi�o" } )
    aAdd( aDet, { "1","016", "01", "29/04/2024", "JOB de integra��o de requisi��o ao armaz�m" } )
    aAdd( aDet, { "1","016", "02", "10/07/2024", "Valida��o da integra��o para evitar duplicidade de registro, "+;
                                                 "Remo��o e espa�os a direita na montagem do JSON referente aos dados do ERP que s�o enviados ao center" } )
    aAdd( aDet, { "1","016", "03", "12/07/2024", "Grava��o da mensagem geral da visita t�cnica" } )
    aAdd( aDet, { "1","016", "04", "27/08/2024", "Removido informa��o da data de emiss�o da solicita��o no momento da grava��o via execauto do pedido mensal" } )
return aDet

/*/{Protheus.doc} HLP
Fun��o para simplificar utiliza��o da fun��o Help
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 22/08/2023
@param cTitle, character, Titulo da janela
@param cError, character, Descri��o do motivo da mensagem
@param cHelp, character, Texto de ajuda para o usu�rio solucionar o problema
/*/
User Function HLP( cTitle, cError, cHelp )
return Help( ,, cTitle,, cError, 1, 0, NIL, NIL, NIL, NIL, NIL,{ cHelp } )

/*/{Protheus.doc} AVGETDB
Retorna o link para o banco de dados configurado nos par�metros do cliente
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 22/08/2023
@param lLiteral, logical, indica se deve retornar o nome literal do par�metro (default=false)
@return character, cSupabase
/*/
User Function AVGETDB( lLiteral )
    local cLiteral := "MV_X_APP01"
    default lLiteral := .F.
return iif( lLiteral, cLiteral, AllTrim( SuperGetMv( cLiteral,,"" ) ) )

/*/{Protheus.doc} AVGETKEY
Fun��o para devolver ao requisitante a API key de comunica��o com o banco
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 22/08/2023
@param lLiteral, logical, indica se deve retornar o nome literal do par�metro (default=false)
@return character, cApiKey
/*/
User Function AVGETKEY( lLiteral )
    local cLiteral := 'MV_X_APP02'
    default lLiteral := .F.
return iif( lLiteral, cLiteral, AllTrim( SuperGetMv( cLiteral,, "") ) )

/*/{Protheus.doc} AVGETTBL
Fun��o para retornar nomes das tabelas utilizadas pelo plugin da integra��o
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 23/08/2023
@return array, aTables
/*/
User Function AVGETTBL()
    Local aTables := {} as array
    aAdd( aTables, { U_AVTBNAME( 'usuarios' ), 'V�nculo entre usu�rios do ERP e usu�rios do aplicativo'} )    
return aTables

/*/{Protheus.doc} AVTBNAME
Fun��o para retornar o nome da tabela f�sica de acordo com o nome gen�rico recebido
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 24/08/2023
@param cExpression, character, express�o para indicar o nome da tabela desejada (ex: usuarios)
@return character, cTblName
/*/
User Function AVTBNAME( cExpression )
    local cTblName := "" as character
    default cExpression := ""

    if cExpression == 'usuarios'        // usu�rios ERP x Usuarios APP
        cTblName := 'USER_ERP_APP'
    endif
return cTblName

/*/{Protheus.doc} AVTBLSTR
Fun��o para retornar estrutura de cada tabela utiliada pelo PlugIn
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 23/08/2023
@param cTable, character, tabela f�sica
@return array, aStruct
/*/
User Function AVTBLSTR( cTable )
    local aStruct := {} as array
    if cTable == U_AVTBNAME( 'usuarios' )
        aAdd( aStruct, { 'ID', 'N',  7, 0 } )
        aAdd( aStruct, { 'NOME', 'C',  30, 0 } )
        aAdd( aStruct, { 'GRUPO', 'N', 7, 0 } )
        aAdd( aStruct, { 'D_GRUPO', 'C', 30, 0 } )
        aAdd( aStruct, { 'FUNCAO', 'C', 5, 0 } )
        aAdd( aStruct, { 'D_FUNCAO', 'C', 30, 0 } )
        aAdd( aStruct, { 'APPVISITA', 'L', 1, 0 } )
        aAdd( aStruct, { 'COLETA', 'L', 1, 0 } )
        aAdd( aStruct, { 'APPADMIN', 'L', 1, 0 } )
        aAdd( aStruct, { 'ATIVO', 'L', 1, 0 } )
        aAdd( aStruct, { 'IDERP', 'C', 6, 0 } )
        aAdd( aStruct, { 'SENHA', 'C', 20, 0 } )
    endif
return aStruct

/*/{Protheus.doc} AVTBLIDX
Fun��o para retorna a estrutura dos �ndices da tabela recebida via par�metro
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 24/08/2023
@param cTable, character, nome f�sico da tabela
@return array, aIndex
/*/
User Function AVTBLIDX( cTable )
    Local aIndex := {} as array
    if cTable == U_AVTBNAME( 'usuarios' )
        aAdd( aIndex, { U_AVTBNAME( 'usuarios' )+'_01', 'ID', {|| 'ID' } } )
        aAdd( aIndex, { U_AVTBNAME( 'usuarios' )+'_02', 'IDERP', {|| 'IDERP' } } )
    endif
return aIndex

/*/{Protheus.doc} AVSELAREA
Fun��o equivalente ao DBSelectArea para tabelas utilizadas pelo plugIn da integra��o
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 29/08/2023
@param cTbl, character, express�o para localiza��o da tabela f�sica (obrigat�rio)
@param lReadOnly, logical, indica se a tabela deve ser aberta em modo somente leitura ou acesso completo (default acesso completo)
@return character, cAlias
/*/
User Function AVSELAREA( cTbl, lReadOnly )

    local cAlias   := "" as character
    local cTable   := U_AVTBNAME( cTbl )
    local aStruct  := {} as array
    local aIndex   := {} as array
    local lSuccess := .T. as logical
    local nIndex   := 0 as numeric
    
    default lReadOnly := .F.

    if ! Empty( cTable )

        // Obtem estrutura da tabela
        aStruct := U_AVTBLSTR( cTable )
        
        // Verifica se a tabela tem estrutura
        if len( aStruct ) > 0
            
            // Verifica se conseguiu abrir a tabela, caso contr�rio, for�a a cria��o da tabela no ambiente
            if ! TcCanOpen( cTable )
                // Fun��o do DbAccess para criar a tabela de acordo com a estrutura enviada por par�metro
                DBCreate( cTable, aStruct, 'TOPCONN' )
            endif
            // Tenta abrir a tabela depois de criada
            lSuccess := TcCanOpen( cTable )
            if ! lSuccess
                U_HLP( cTable,;
                        'A tabela '+ cTable +' n�o pode ser criada!',;
                        'Falha durante processo de cria��o da tabela no banco de dados' )
            else
                
                // Abre a tabela 
                cAlias := 'USERAPP'
                if Select( cAlias ) == 0
                    DBUseArea( .F., 'TOPCONN', cTable, (cAlias), .F., lReadOnly )
                else
                    DBSelectArea( cAlias )
                endif

                // Identifica os �ndices da tabela 
                aIndex := U_AVTBLIDX( cTable )

                if len( aIndex ) > 0
                    
                    for nIndex := 1 to len( aIndex )
                        if ! TCCanOpen( cTable, aIndex[nIndex][1] )
                            ( cAlias )->( DBCreateIndex( aIndex[nIndex][1], aIndex[nIndex][2], aIndex[nIndex][3] ) )
                            lSuccess := TCCanOpen( cTable, aIndex[nIndex][1] )
                        else
                            ( cAlias )->( DBSetIndex( aIndex[nIndex][1] ) )
                        endif
                        if ! lSuccess
                            U_HLP( 'Falha na Cria��o do �ndice',;
                                    'O �ndice '+ aIndex[nIndex][1] +' da tabela ' + cTable +' n�o pode ser criado!' )
                            Exit
                        endif
                    next nIndex
                endif

                if ! lSuccess
                    ( cAlias )->( DBCloseArea() )
                    cAlias := ""
                endif

            endif
        else
            U_HLP( 'Sem Estrutura',;
                    'A tabela '+ cTable +' n�o possui estrutura definida!',;
                    'Defina uma estrutura por meio da fun��o AVGETSTR e tente novamente.' )
        endif

    else
        U_HLP( 'Tabela N�o Encontrada', 'N�o foi localizada nenhuma tabela por meio da express�o: '+ cTbl,;
              'Informe esta mensagem ao respons�vel t�cnico pelo sistema.' )
    endif
    
return cAlias

/*/{Protheus.doc} AVCBOX
Fun��o para retornar um combo-box com o conte�do a ser exibido para sele��o no campo
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 31/08/2023
@param cVar, character, nome do campo onde a fun��o est� referenciada
@return character, cOptions
/*/
User function AVCBOX( cVar )
    
    local cOptions := "" as character
    local oReturn  as object
    local cWhere   := "" as character
    local nX       := 0 as numeric
    local cTable   := "" as character
    local aFields  := {} as array
    local cID      := "" as character
    local cDesc    := "" as character

    default cVar := ReadVar()

    if "GRUPO" $ cVar           // grupo de acesso do usu�rio
        cWhere := "D_E_L_E_T_=eq.N"
        cTable := 'grupodeacesso'
        aFields := {'ID','GRAC_NOME'}
    elseif "FUNCAO" $ cVar      // fun��es do usu�rio
        cWhere := "D_E_L_E_T_=eq.N"
        cTable := "funcao"
        aFields := {"ID","FUNC_NOME"}
    endif

    if ! Empty( cTable )
        // Consome o webservice do supabase usando a api
        oReturn := U_SUPCLIENT( U_AVGETDB(), U_AVGETKEY(), 'get', cTable, aFields, cWhere )
        if ValType( oReturn ) == 'J' .and. len( oReturn ) > 0
            cOptions := ""
            for nX := 1 to len( oReturn )
                cID := idByChar( oReturn[nX][aFields[1]] )
                cDesc := AllTrim( DecodeUTF8(oReturn[nX][aFields[2]], 'cp1252' ) )
                cOptions += iif( ! Empty( cOptions ), ';','' ) + cID +'='+ cDesc
            next nX
        endif
        FreeObj( oReturn )
        oReturn := Nil
    endif
return cOptions

/*/{Protheus.doc} idByChar
Fun��o para converter um ID para character caso este seja num�rico
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 31/08/2023
@param xInfo, variadic, informa��o obtida pelo webservice referente ao ID do registro
@return character, cID
/*/
static function idByChar( xInfo )

    local cID := " "
    default xInfo := ""

    if ValType( xInfo ) == 'N'
        cID := AllTrim( cValToChar( xInfo ) )
    elseif ValType( xInfo ) == 'C'
        cID := AllTrim( xInfo )
    endif

return cID

/*/{Protheus.doc} AVVLDFLD
Fun��o para executar valida��o nos campos que recebem informa��es de usu�rios nas rotinas do plugin 
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 31/08/2023
@param cVar, character, local onde a fun��o de valida��o foi chamada
@return logical, lValidated
/*/
User Function AVVLDFLD( cVar )
    
    local lValidated := .T. as logical
    local aAux       := {}  as array
    local aOptions   := {}  as array
    local cTitleHlp  := ""  as character
    local cFailHlp   := ""  as character
    local cHelpHlp   := ""  as character
    
    default cVar := ReadVar()

    if "GRUPO" $ cVar .and. Type( 'cOptGrp' ) == 'C'
        aAux := StrTokArr( cOptGrp, ';' )
        aEval( aAux, {|x| aAdd( aOptions, StrTokArr( x, '=' ) ) } )
        lValidated := aScan( aOptions, {|x| x[1] == &( cVar ) } ) > 0

        if ! lValidated
            cTitleHlp := 'Grupo Inv�lido'
            cFailHlp  := 'O grupo selecionado/informado n�o � v�lido'
            cHelpHlp  := 'Selecione um grupo v�lido para que possamos prosseguir'
        endif
    elseif "FUNCAO" $ cVar .and. Type( 'cOptFun' ) == 'C'
        aAux := StrTokArr( cOptFun, ';' )
        aEval( aAux, {|x| aAdd( aOptions, StrTokArr( x, '=' ) ) } )
        lValidated := aScan( aOptions, {|x| AllTrim( x[1] ) == AllTrim( &( cVar ) ) } ) > 0

        if ! lValidated
            cTitleHlp := 'Fun��o Inv�lida'
            cFailHlp  := 'A fun��o selecionada/informada � inv�lida'
            cHelpHlp  := 'Utilize uma fun��o v�lida para que possamos prosseguir'
        endif
    endif

    if ! lValidated
        U_HLP( cTitleHlp, cFailHlp, cHelpHlp )
    endif

return lValidated

/*/{Protheus.doc} AVGETREL
Fun��o para retornar a rela��o de campos entre as tabelas locais e as tabelas do supabase
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 18/09/2023
@param cTable, character, nome fisico da tabela do supabase
@return array, aRelation
/*/
User Function AVGETREL( cTable )
    local aRelation := {} as array
    if cTable == 'nucleo'
        aRelation := { {'ID'                       , 'ZH6_X_IDAP' , "" },;
                        {'NUC_CODIGO'               , 'ZH6_CODNUC' , "" },;
                        {'NUC_DESCRICAO'            , 'ZH6_DESNUC' , "" },;
                        {'NUC_LOCAL'                , 'ZH6_LOCAL'  , "" },;
                        {'NUC_RESPONSAVEL'          , 'ZH6_NREDUZ' , "" },;
                        {'NUC_USER_RESPONSAVEL'     , ''           , "U_AVIDBYNM(ZH6_NREDUZ)" },;
                        {'NUC_CUSTO'                , 'ZH6_CCUST'  , "" },;
                        {'NUC_ATIVO'                , 'ZH6_ATIVO'  , "" },;
                        {'IDERP'                    , ''           , "Recno()" },;
                        {'D_E_L_E_T_'               , ''           , "iif(Deleted(),'S','N')" },;
                        {'NUC_TIPO'                 , ''           , "U_AVCBDESC('ZH6_TIPO')" },;
                        {'NUC_NAVIARIO'             , 'ZH6_X_NAVI' , "" }}
    elseif cTable == 'produto'
        aRelation := { { 'ID'                  , 'B1_COD'  , ''},;
                        {'PROD_NOME'           , 'B1_DESC' , ''},;
                        {'PROD_UN'             , 'B1_UM'   , ''},;
                        {'PROD_GRUPO'          , 'B1_GRUPO', ''},;
                        {'PROD_ATIVO'          , ''        , '!B1_MSBLQL=="1"' }}
    elseif cTable == 'lote'
        aRelation := {  {'R_E_C_N_O_'                   ,"ZH0_X_IDAP" ,"" },;
                        {'D_E_L_E_T_'                   , ""          , "iif(Deleted(), 'S' , 'N' )"},;
                        {'LOT_LOTE'                     , "ZH0_LOTE"  , ""},;
                        {'LOT_DESC'                     , "ZH0_DESCLO", ""},;
                        {'LOT_TIPO'                     , ""          , "U_AVCBDESC( 'ZH0_TIPO' )"},;
                        {'LOT_PRO_TERC'                 , ""          , "U_AVCBDESC( 'ZH0_TIPOFO' )"},;
                        {'LOT_QTD_F'                    , "ZH0_FEMEAS", ""},;
                        {'LOT_QTD_M'                    , "ZH0_MACHOS", ""},;
                        {'LOT_DT_ALOJAME'               , "ZH0_INICIO", ""},;
                        {'LOT_DT_TERMINO'               , "ZH0_TERMIN", ""},;
                        {'LOT_CODPADRAO'                , "ZH0_STAND" , ""},;
                        {'LOT_PADRAO'                   , "ZH0_PADRAO", ""},;
                        {'LOT_LINHAGEM'                 , "ZH0_LINHAG", ""},;
                        {'LOT_NUCLEO'                   , "ZH0_NUCLEO", ""},;
                        {'LOT_SEXO'                     , ""          , "U_AVCBDESC( 'ZH0_SEXO' )"},;
                        {'LOT_ATIVO'                    , ""          , "ZH0_ATIVO== 'S' "},;
                        {'LOT_GRUPO'                    , "ZH0_GRUPO" , ""},;
                        {'LOT_INCUBAT'                  , "ZH0_LOTEIN", ""},;
                        {'IDERP'                        , ""          , "Recno()" },;
                        {'LOT_BOX'                      , "ZH0_BOX"   , "" }}
    elseif cTable == 'funcaoxnucleo'
        aRelation := {  { 'ID'                    , "ZHV_X_IDAP", ""},;
                        {"FXN_NUC_CODIGO"         , "ZHV_NUCLEO", ""},;
                        {"D_E_L_E_T_"             , ""          , "iif( Deleted(), 'S' , 'N' )"},;
                        {"FXN_ID_USER"            , ""          , "U_AVIDBYNM( ZHV_USPROT )"},;
                        {"IDERP"                  , ""          , "Recno()" }}

    elseif cTable == 'funcao'
        aRelation := {  {'ID'           , "RJ_FUNCAO", ""},;
                        {'FUNC_NOME'    , "RJ_DESC"  , ""},;
                        {'D_E_L_E_T_'   , ""         , "iif( Deleted(), 'S' , 'N' )"},;
                        {'IDERP'        , ""         , "Recno()" }}
    elseif cTable == 'grupo'
        aRelation := {  {'ID'           , "BM_GRUPO" , ""},;
                        {'GRU_NOME'     , "BM_DESC"  , ""},;
                        {'D_E_L_E_T_'   , ""         , "iif( Deleted(), 'S' , 'N' )"},;
                        {'IDERP'        , ""         , "Recno()" }}
    
    elseif cTable == 'subitens'
        aRelation := {  { 'ID'          , "ZH1_X_IDAP", "" },;
                        { 'CODIGO'      , "ZH1_COD"   , "" },;
                        { 'COD_ITEM'    , "ZH1_CODITE", "" },;
                        { 'ITEM'        , "ZH1_ITEM"  , "" },;
                        { 'SUB_ITEM'    , "ZH1_SITEM" , "" },;
                        { 'GRUPO1'      , "ZH1_GRUPO1", "" },;
                        { 'GRUPO2'      , "ZH1_GRUPO2", "" },;
                        { "GRUPO3"      , "ZH1_GRUPO3", "" },;
                        { "RECRIA"      , "ZH1_RECRIA", "" },;
                        { "PRODUCAO"    , "ZH1_PRODU" , "" },;
                        { "SOMA"        , "ZH1_SOMA"  , "" },;
                        { "ORDEM"       , ""          , "Val(ZH1_ORDEM)" },;
                        { "ATIVO"       , "ZH1_ATIVO" , "" },;
                        { "IDERP"       , ""          , "Recno()" },;
                        { "D_E_L_E_T_"  , ""          , "iif( Deleted() .or. ZH1_X_APP != 'S', 'S', 'N' )"},;
                        { "SEXO"        , "ZH1_X_SEXO", "" },;
                        { "GRUPOAPP"    , "ZH1_X_GRAP", "" } }
    elseif cTable == 'ocorrencias'
        aRelation := {  { 'ID'                    , 'U9_X_IDAP', ""},;
                        {'OCOR_CODIGO'            , 'U9_CODIGO', ""},;
                        {'OCOR_DESC'              , "U9_DESC"  , ""},;
                        {'D_E_L_E_T_'             , ''         , 'iif(Deleted() .or. ( U9_X_APP != "S" .and. U9_X_IDAP > 0 ), "S", "N")' },;
                        {'IDERP'                  , ''         , 'Recno()' } } 
    elseif cTable == 'coletaitens'
        aRelation := { { 'R_E_C_N_O_'             , 'ZHL_X_IDAP', "" },;
                       { 'COLI_CODIGO'            , 'ZHL_COD'   , "" },;
                       { 'COLI_QUANT'             , 'ZHL_QUANT' , "" },;
                       { 'D_E_L_E_T_'             , ''          , "iif( Deleted(),'S','N')" },;
                       { 'IDERP'                  , ''          , "Recno()" },;
                       { 'COLI_BOX'               , 'ZHL_BOX'   , "" } }
    elseif cTable == 'solicitacoes'
        aRelation := { { 'R_E_C_N_O_'             , 'ZIA_X_IDAP', "" },;
                       { 'SOL_EMISSAO'            , 'ZIA_DATA'  , "" },;
                       { 'SOL_OCORRENCIA'         , 'ZIA_CLADES', "" },;
                       { 'SOL_DESCRICAO'          , 'ZIA_REPORT', "" },;
                       { 'SOL_TIPO'               , ''          , "'Ocorrencia'" },;
                       { 'SOL_ID_USER'            , ''          , "U_AVIDBYNM( ZIA_SOLICI )" },;
                       { 'D_E_L_E_T_'             , ''          , "iif( Deleted(), 'S', 'N' )" },;
                       { 'IDERP'                  , ''          , "Recno()" },;
                       { 'ID'                     , 'ZIA_X_IDSO', "" } }
    elseif cTable == 'pedidoitem'
        aRelation := { { 'ID'                     , 'CP_X_IDAP' , "" },;
                       { 'IDERP'                  , ''          , "Recno()" },;
                       { 'PEDI_PROD_UN'           , 'CP_UM'     , "" },;
                       { 'PEDI_QTD'               , 'CP_QUANT'  , "" },;
                       { 'PEDI_PED_ID'            , 'CP_X_IDPD' , "" },;
                       { 'PEDI_OBS'               , 'CP_OBS'    , "" },;
                       { 'D_E_L_E_T_'             , ''          , "iif( Deleted(), 'S', 'N' )" },;
                       { 'PEDI_PROD_ID'           , 'CP_PRODUTO', "" },;
                       { 'PEDI_ITEM'              , ''          , "Val(CP_ITEM)" },;
                       { 'PEDI_PROD_NOME'         , 'CP_DESCRI' , "" } }
    endif
return aRelation

/*/{Protheus.doc} AVIDBYNM
Fun��o para retornar o ID do usu�rio do APP com base no nome do usu�rio do ERP
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 15/09/2023
@param cName, character, nome do usu�rio do sistema
@return numeric, nIDUser
/*/
user function AVIDBYNM( cName )
    
    local cAliAtu := Alias()
    local nRecAtu := iif( Select( cAliAtu ) > 0, (cAliAtu)->(Recno()), 0 )
    local nIDUser := Nil
    local cUserID := "" as character
    local cAlias  := "" as character
    
    PSWOrder(2)     // nome do usu�rio/grupo
    if PSWSeek( cName, .T. )
        cUserID := PSWID()
        cAlias := U_AVSELAREA( 'usuarios', .T. /* lReadOnly */ )
        ( cAlias )->( DBSetOrder( 2 ) )
        if ( cAlias )->( DBSeek( cUserID ) )
            nIDUser := ( cAlias )->ID
        endif
        ( cAlias )->( DBCloseArea() )
    endif

    if nRecAtu > 0
        // Reposiciona no registro anterior
        DBSelectArea( cAliAtu )
        ( cAliAtu )->( DBGoTo( nRecAtu ) )
    endif
return nIDUser

/*/{Protheus.doc} AVINTACT
Fun��o que verifica se a integra��o com o app est� ativa ou n�o
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 20/09/2023
@param lLiteral, logical, .T.=retorna o nome literal do par�metro regulador .F.=conet�do do par�metro (default .F.)
@return variadic, xReturn
/*/
user function AVINTACT( lLiteral )
    
    local cLiteral := "MV_X_APP03"
    local lIntAct  := SuperGetMv( cLiteral,,.F. )
    local xReturn  := Nil
    
    default lLiteral := .F.

    if lLiteral
        xReturn := cLiteral
    else
        xReturn := lIntAct
    endif

return xReturn

/*/{Protheus.doc} AVCBDESC
Fun��o respons�vel por devolver o conte�do descritivo de um campo do tipo ComboBox
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 26/09/2023
@param cField, character, ID do campo
@param cValue, character, conte�do do campo (default conte�do do campo da tabela)
@return character, cDesc
/*/
user function AVCBDESC( cField, cValue )

    local cDesc := "" as character
    local aOptions := {} as array
    local cOptions := AllTrim( GetSX3Cache( cField, 'X3_CBOX' ) )
    local aAux     := StrTokArr( cOptions, ';' )
    local cOption  := "" as character

    default cValue := "" 

    if Empty( cValue )
        cOption := &( cField )
    else
        cOption := cValue
    endif

    // Define o vetor de op��es
    aEval( aAux, {|x| aAdd( aOptions, StrTokArr( x, '=' ) ) } )
    cDesc := Capital( AllTrim( aOptions[aScan(aOptions,{|x| AllTrim(x[1]) == AllTrim(cOption) })][2] ) )

return cDesc

/*/{Protheus.doc} AVLASTID
Fun��o para obter o �ltimo ID utilizado para a tabela recebida por par�metro no supabase
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 26/09/2023
@param cField, character, ID do campo a ser consultado
@param xDefault, variant, informa��o default caso a tabela esteja vazia
@param cTable, character, nome f�sico da tabela do supabase
@return variadic, xRet
/*/
user function AVLASTID( cField, xDefault, cTable )
    
    local xLast := xDefault
    local oResult    as object
    local nX    := 0 as numeric

    // Consulta a requisi��o
    oResult := U_SUPCLIENT( U_AVGETDB(), U_AVGETKEY(), 'GET', cTable, { cField }, "" /* cWhere */ )
    if ValType( oResult ) == 'J' .and. Len( oResult ) > 0
        for nX := 1 to len( oResult )
            xLast := iif( oResult[nX][ cField ] > xLast, oResult[nX][ cField ], xLast )
        next nX
    endif

    FreeObj( oResult )
    oResult := Nil
return xLast

/*/{Protheus.doc} AVQRYDEF
Fun��o para retornar a query referente a consulta de informa��es referente a tabela recebida por par�metro
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 29/09/2023
@param cTable, character, nome da tabela
@param lCount, logical, indica se deve retornar a query de contagem de registro (default .F.). Quando .F., retorna consulta dos R_E_C_N_O_ 
@param lDeleted, logical, deve exibir tamb�m registros deletados? (default .F.)
@return character, cQuery
/*/
user function AVQRYDEF( cTable, lCount, lDeleted )
    
    local cQuery := "" as character
    
    default lCount := .F.
    default lDeleted := .F.

    if cTable == 'grupo'

        cQuery := "SELECT "+ iif( lCount, "COUNT(*) QTDE ", "DISTINCT BM.R_E_C_N_O_ RECSBM " ) 
        cQuery += "FROM "+ RetSqlName( 'SBM' ) +" BM "
            
        cQuery += "INNER JOIN "+ RetSqlName( 'SB1' ) +" B1 "
        cQuery += " ON B1.B1_FILIAL  = '"+ FWxFilial( 'SB1' ) +"'"
        cQuery += "AND B1.B1_GRUPO   = BM.BM_GRUPO "
        cQuery += "AND B1.B1_X_DTAP  <> '"+ Space( TAMSX3('B1_X_DTAP')[1] ) +"' "
        cQuery += "AND B1.D_E_L_E_T_ = ' ' "

        cQuery += "WHERE BM.BM_FILIAL  = '"+ FWxFilial( 'SBM' ) +"' "
        cQuery += "  AND BM.BM_X_IDAP  = '"+ Space( TAMSX3('BM_X_IDAP')[1] ) +"' "
        if ! lDeleted
            cQuery += "  AND BM.D_E_L_E_T_ = ' ' "
        endif

    elseif cTable == 'produto'
        cQuery := "SELECT "+ iif( lCount, "COUNT(*) QTDE ", "R_E_C_N_O_ RECSB1 " ) +" FROM "+ RetSqlName( 'SB1' )
        cQuery += " WHERE B1_X_RANCH = 'S' AND B1_X_DTAP = '"+ Space( TAMSX3('B1_X_DTAP')[1] ) +"' "
        if ! lDeleted
            cQuery += " AND D_E_L_E_T_ = ' ' "
        endif
    
    elseif cTable == 'lote'
        cQuery := "SELECT "+ iif( lCount, "COUNT(*) QTDE ", "R_E_C_N_O_ RECZH0 " ) +" FROM "+ RetSqlName( 'ZH0' )
        cQuery += " WHERE ZH0_X_IDAP = 0 "
        if ! lDeleted
            cQuery += " AND D_E_L_E_T_ = ' ' "
        endif

    elseif cTable == 'funcao'
        cQuery := "SELECT "+ iif( lCount, "COUNT(*) QTDE ", "R_E_C_N_O_ RECSRJ " ) +" FROM "+ RetSqlName( 'SRJ' )
        cQuery += " WHERE RJ_X_IDAP = '"+ Space( TAMSX3('RJ_X_IDAP')[1] ) +"' "
        if ! lDeleted
            cQuery += " AND D_E_L_E_T_ = ' ' "
        endif

    elseif cTable == 'funcaoxnucleo'
        cQuery := "SELECT "+ iif( lCount, "COUNT(*) QTDE ", "R_E_C_N_O_ RECZHV " ) +" FROM "+ RetSqlName( 'ZHV' ) 
        cQuery += " WHERE ZHV_X_IDAP = 0 "
        if ! lDeleted
            cQuery += "AND D_E_L_E_T_ = ' ' "
        endif

    elseif cTable == 'nucleo'
        cQuery := "SELECT "+ iif( lCount, "COUNT(*) QTDE ", "R_E_C_N_O_ RECZH6 " ) +" FROM "+ RetSqlName( 'ZH6' )
        cQuery += " WHERE ZH6_X_IDAP = 0 "
        if ! lDeleted
            cQuery += " AND D_E_L_E_T_ = ' ' "
        endif

    elseif cTable == 'subitens'
        cQuery := "SELECT "+ iif( lCount, "COUNT(*) QTDE ", "R_E_C_N_O_ RECZH1 " ) +" FROM "+ RetSqlName( 'ZH1' )
        cQuery += " WHERE ZH1_X_APP = 'S' AND ZH1_X_IDAP = 0 "
        if ! lDeleted
            cQuery += " AND D_E_L_E_T_ = ' ' "
        endif
    
    elseif cTable == 'ocorrencias'
        cQuery := "SELECT "+ iif( lCount, "COUNT(*) QTDE ", "R_E_C_N_O_ RECSU9 " ) +" FROM "+ RetSqlName( "SU9" ) 
        cQuery += " WHERE U9_X_APP = 'S' AND U9_X_IDAP = 0 "
        if ! lDeleted
            cQuery += " AND D_E_L_E_T_ = ' ' "
        endif

    endif

return cQuery
