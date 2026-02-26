#include 'topconn.ch'
#include 'totvs.ch'

/*/{Protheus.doc} JSFieldPut
Função responsável por checar e criar os campos necessários para a estrutura do painel de compras
@type function
@version 12.1.2510
@author Jean Carlos Pandolfo Saggin
@since 26/02/2026
@return logical, lSuccess
/*/
user function JSFLDPUT()

    local lSuccess := .T. as logical
    local aSX3     := {} as array
    local cNewSeq  := "01" as character
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

    // CADASTRO DE FORNECEDORES - SA2
    cAlias := "SA2"
    cField := "A2_X_FPRC"
    if (cAlias)->( FieldPos( cField ) ) == 0
        cNewSeq := iif( cNewSeq > "01", Soma1(cNewSeq), newSeq( cAlias ) )
        aAdd( aSX3, { ;
                    cAlias																	, ; //X3_ARQUIVO
                    cNewSeq																	, ; //X3_ORDEM
                    cField         															, ; //X3_CAMPO
                    "C"     																, ; //X3_TIPO
                    1																		, ; //X3_TAMANHO
                    0																		, ; //X3_DECIMAL
                    'Form.Preço?'		    											    , ; //X3_TITULO
                    'Form.Preço?'	    												    , ; //X3_TITSPA
                    'Form.Preço?'       												    , ; //X3_TITENG
                    'Formação de Preço'														, ; //X3_DESCRIC
                    'Formação de Preço'														, ; //X3_DESCSPA
                    'Formação de Preço'														, ; //X3_DESCENG
                    '@!'	        														, ; //X3_PICTURE
                    'Pertence("S/N")'													    , ; //X3_VALID
                    'x       x       x       x       x       x       x       x       x       x       x       x       x       x       x x', ; //X3_USADO
                    '"S"'															    	, ; //X3_RELACAO
                    ''																		, ; //X3_F3
                    0																		, ; //X3_NIVEL
                    'xxxxxx x'																, ; //X3_RESERV
                    ''																		, ; //X3_CHECK
                    ''																		, ; //X3_TRIGGER
                    'U'																		, ; //X3_PROPRI
                    'S'																		, ; //X3_BROWSE
                    'A'																		, ; //X3_VISUAL
                    'R'																		, ; //X3_CONTEXT
                    'S'																		, ; //X3_OBRIGAT
                    ''																		, ; //X3_VLDUSER
                    'S=Sim;N=Não'															, ; //X3_CBOX
                    'S=Sim;N=Não'															, ; //X3_CBOXSPA
                    'S=Sim;N=Não'															, ; //X3_CBOXENG
                    ''																		, ; //X3_PICTVAR
                    ''																		, ; //X3_WHEN
                    ''																		, ; //X3_INIBRW
                    ''																		, ; //X3_GRPSXG
                    getFolder(cAlias)   													, ; //X3_FOLDER
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
                        Final( 'FALHA DBACCESS '+cValtoChar( nTopErr ),; 
                                'Falha ao alterar estrutura da tabela '+ aArqUpd[nX] +', tente novamente em modo exclusivo.', .F., .F., 5 )
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

/*/{Protheus.doc} getFolder
Função para retornar qual o folder a ser utilizado para inclusão de campos para o Painel de Compras
@type function
@version 12.1.2510
@author Jean Carlos Pandolfo Saggin
@since 26/02/2026
@param cAlias, character, Alias da tabela
@return character, cFolder
/*/
static function getFolder( cAlias )
    local cFolder := '' as character
    
    DBSelectArea( 'SXA' )
    SXA->( DBSetOrder(1) )
    if SXA->( DBSeek( cAlias ) )
        // Percorre cadastro em busca do folder chamado Painel de Compras
        while ! SXA->( EOF() ) .and. SXA->XA_ALIAS == cAlias .and. Empty( cFolder )
            if 'painel' $ lower(SXA->XA_DESCRIC) .and. 'compras' $ lower(SXA->XA_DESCRIC)
                cFolder := SXA->XA_ORDEM
            endif
            SXA->( DBSkip() )
        end
    endif
return cFolder

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
