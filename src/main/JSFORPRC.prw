#include 'topconn.ch'
#include 'totvs.ch'

/*/{Protheus.doc} JSFORPRC
Função para o processo de formação de preço
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 1/16/2025
/*/
user function JSFORPRC()
    
    // Local cAlias    := 'SF1'
    local aPerg     := {}  as array
    local lCanSave  := .T. as logical
    local lUserSave := .T. as logical
    // local cFilter   := ""  as character
    local bOk       :={|| .T. }
    // local aColors   := {}  as array
    local cFornSM0  := "" as character
	local aFornSM0  := U_JSSUPSM0()
    local oBrowse   as object
    local cAliasTMP := "SF1TMP"
    local cQuery    := "" as character
    local aFields   := { "F1_FILIAL", "F1_DOC", "F1_SERIE", "F1_X_FPRC", "F1_TIPO", "F1_ESPECIE", "F1_FORNECE", "F1_LOJA", "A2_NOME",;
                         "F1_COND", "F1_DTDIGIT", "F1_EMISSAO", "F1_VALMERC" }
    local aFieldBrw := aClone( aFields )
    local oTable    as object
    local aStruct   := {} as array
    local aColumns  := {} as array
    local aFilter   := {} as array
    local cCBox     := "" as character
    local lSuccess  := .T. as logical

    Private aRotina   := {} 
    Private cCadastro := "Formação de Preço - "+ U_JSGETVER()
    Private INCLUI    := .F.
    Private ALTERA    := .F.

    // Chega estrutura de dicionário de dados para saber se está tudo Ok antes de iniciar
    MsAguarde( {|| lSuccess := checkStruct() }, 'Aguarde...', 'Checando estruturas de dados...' )
    if ! lSuccess
        return Nil
    endif

    aAdd( aPerg, { 1, "Emissao de: ", StoD(' '),"", "", "", ".T.", 50, .F.  } )
    aAdd( aPerg, { 1, "Emissao até: ", StoD('20491231'),"", "", "", ".T.", 50, .F.  } )
    aAdd( aPerg, { 1, "Digitação de: ", StoD(' '),"", "", "", ".T.", 50, .F.  } )
    aAdd( aPerg, { 1, "Digitação até: ", StoD('20491231'),"", "", "", ".T.", 50, .F.  } )
    aAdd( aPerg, { 1, "Fornecedor: ", Space(TAMSX3('A2_COD')[1]),"", "", "SA2", ".T.", 60, .F.  } )
    aAdd( aPerg, { 1, "Loja: ", Space(TAMSX3('A2_LOJA')[1]),"", "", "", ".T.", 40, .F.  } )
    aAdd( aPerg, { 2, "Exibir: ", 2,{"Todas","Apenas Pendentes"}, 80, ".T.", .T.  } )

    // Exibe pergunta ao usuário
    if ! ParamBox( aPerg, 'Filtros Iniciais',, bOk,,,,,,, lCanSave, lUserSave )
        Return nil
    endif
    
    // Forma expressão para ignorar do filtro documentos relacionados a empresas do mesmo grupo economico
    aEval( aFornSM0, {|x| cFornSM0 += iif( !Empty( cFornSM0 ), ',', '') +"'"+ x +"'" } )
    aEval( aFields, {|x| aAdd( aStruct, { x,;
                                        GetSX3Cache( x, 'X3_TIPO' ),;
                                        GetSX3Cache( x, 'X3_TAMANHO' ),;
                                        GETSX3CACHE( x, 'X3_DECIMAL' ) } ),;
                         aAdd( aFilter, { aStruct[len(aStruct)][1],; 
                                            GetSX3Cache(aStruct[len(aStruct)][1], 'X3_TITULO'),; 
                                            TamSX3(aStruct[len(aStruct)][1])[3],; 
                                            TamSX3(aStruct[len(aStruct)][1])[1],; 
                                            TamSX3(aStruct[len(aStruct)][1])[2],; 
                                            PesqPict("SF1", aStruct[len(aStruct)][1]) } ) } )
    aAdd( aStruct, { "RECSF1", "N", 11, 0 } )       // Recno da tabela original (SF1)
    
    // Configura colunas do browse
    aEval( aFieldBrw, {|x| cCBox := AllTrim( GetSX3Cache( x, 'X3_CBOX' ) ),;
                            aAdd( aColumns, FWBrwColumn():New() ),;
                               aColumns[len(aColumns)]:SetData( &("{|| "+ x +" }") ),;
                               aColumns[len(aColumns)]:SetTitle( GetSX3Cache( x, 'X3_TITULO' ) ),;
                               aColumns[len(aColumns)]:SetSize( GetSX3Cache( x, 'X3_TAMANHO' ) * 0.4 ),;
                               aColumns[len(aColumns)]:SetDecimal( GetSX3Cache( x, 'X3_DECIMAL' ) ),;
                               aColumns[len(aColumns)]:SetPicture( GetSX3Cache( x, 'X3_PICTURE' ) ),;
                               iif( !Empty( cCBox ), aColumns[len(aColumns)]:SetOptions( StrTokArr( cCBox, ';' ) ), Nil ) } )

    if SF1->( FieldPos( 'F1_X_FPRC' ) ) == 0
        U_HLP( 'F1_X_FPRC',;
             'Ambiente desatualizado para utilização da rotina de formação de preços.',;
             'Foi identificado que o campo F1_X_FPRC não está configurado na tabela de documentos de entrada. '+;
             'Solicite a atualização necessária para a equipe responsável pelo Painel de Compras, execute a atualização e tente novamente em seguida.' )
            return Nil
    endif

    // Cria tabela temporária para receber os dados das notas pendentes de conferência de preços.
    oTable := FWTemporaryTable():New( 'SF1TMP', aStruct )
    oTable:AddIndex( '01', { "F1_FILIAL", "F1_DOC", "F1_SERIE" } )
    oTable:Create()

    cQuery := "SELECT "
    aEval( aFields, {|x| cQuery += iif( AllTrim(x) == 'F1_X_FPRC', "CASE WHEN F1."+ x +" IN ( ' ','N' ) THEN 'N' ELSE 'S' END "+ x , x ) +", " } )
    cQuery += "F1.R_E_C_N_O_ RECSF1 "
    cQuery += "FROM "+ RetSqlName( 'SF1' ) +" F1 "
 
    // Fornecedor
    cQuery += "INNER JOIN "+ RetSqlName( 'SA2' ) +" A2 "
    cQuery += " ON A2.A2_FILIAL  = '"+ FWxFilial( 'SA2' ) +"' "
    cQuery += "AND A2.A2_COD     = F1.F1_FORNECE "
    cQuery += "AND A2.A2_LOJA    = F1.F1_LOJA "
    // Ignora os fornecedores ignorados no processo de formação de preços, mas valida a regra apenas quando o campo existir
    if SA2->( FieldPos( 'A2_X_FPRC' ) ) > 0     
        cQuery += "AND A2.A2_X_FPRC <> 'N' "
    endif
    cQuery += "AND A2.D_E_L_E_T_ = ' ' "

    cQuery += "WHERE F1.F1_EMISSAO BETWEEN '"+ DtoS( MV_PAR01 ) +"' AND '"+ DtoS( MV_PAR02 ) +"' "
    cQuery += "  AND F1.F1_DTDIGIT BETWEEN '"+ DtoS( MV_PAR03 ) +"' AND '"+ DtoS( MV_PAR04 ) +"' "
    cQuery += "  AND F1.F1_TIPO     = 'N' " // Apenas notas do tipo N-Normal
    cQuery += "  AND F1.F1_FORNECE NOT IN ( "+ cFornSM0 +" ) "
    if !Empty( MV_PAR05 )       // Fornecedor
        cQuery += "  AND F1.F1_FORNECE = '"+ MV_PAR05 +"' "
    endif

    if ! Empty( MV_PAR06 )      // Loja
        cQuery += "  AND F1.F1_LOJA = '"+ MV_PAR06 +"' "
    endif
    if ( ValType(MV_PAR07) == "N" .and. MV_PAR07 == 2 ) .or. ( ValType( MV_PAR07 ) == 'C' .and. MV_PAR07 == 'Apenas Pendentes' )            // Apenas pendentes
        cQuery += "  AND F1.F1_X_FPRC <> 'S' "  // Exibe apenas documentos pendentes
    ENDIF
    cQuery += "  AND F1.D_E_L_E_T_ = ' ' "

    // Joga dados da query para TRB
    SQLToTrb( cQuery, aStruct, cAliasTMP )

    DBSelectArea( cAliasTMP )
    ( cAliasTMP )->( DBGoTop() )

    aAdd( aRotina, { OemToAnsi("Visualizar"), "U_JSVISNF", 0 , 2, 0, nil })
    aAdd( aRotina, { 'Form. Preço', 'U_JSFPRECO', 0, 2, 0, Nil } )
    aAdd( aRotina, { 'Legenda', 'U_JSFPLEG', 0, 2, 0, Nil } )

    oBrowse:= FWMBrowse():New()
    oBrowse:SetAlias(cAliasTMP) //Temporary Table Alias
    oBrowse:SetDescription( cCadastro )
    oBrowse:SetTemporary(.T.) //Using Temporary Table
    oBrowse:SetUseFilter(.T.) //Using Filter
    oBrowse:OptionReport(.F.) //Disable Report Print
    oBrowse:AddLegend( cAliasTMP +"->F1_X_FPRC == 'S'", 'BR_VERDE', 'Conferência de Preços Executada' )
    oBrowse:AddLegend( "!"+ cAliasTMP +"->F1_X_FPRC == 'S'", 'BR_VERMELHO', 'Preços Não Conferidos' )
    oBrowse:SetColumns(aColumns)
    oBrowse:SetFieldFilter(aFilter) //Set Filters
    oBrowse:Activate(/*oDlg*/) //Caso deseje incluir em um componente de Tela (Dialog, Panel, etc), informar como parâmetro o objeto
 
    //Delete Temporary Table
    oTable:Delete()
    
return Nil

/*/{Protheus.doc} JSVISNF
Função para chamar processo de visualização do documento fiscal de entrada
@type function
@version 12.1.2410
@author Jean Carlos Pandolfo Saggin
@since 28/11/2025
/*/
User function JSVISNF()
    local cFilHist := cFilAnt

    // Troca filial posicionada no sistema caso a filial da nota seja diferente da filial corrente
    if cFilAnt != SF1TMP->F1_FILIAL
		cFilAnt := SF1TMP->F1_FILIAL
		FWSM0Util():setSM0PositionBycFilAnt()
	endif

    DBSelectArea( 'SF1' )
    SF1->( DBGoTo( SF1TMP->RECSF1 ) )
    A103NFiscal( 'SF1', SF1->( Recno() ), 2 )

    if cFilAnt != cFilHist
		cFilAnt := cFilHist
		FWSM0Util():setSM0PositionBycFilAnt()
	endif
return 

/*/{Protheus.doc} JSFPLEG
Função para exibição de legendas da rotina
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 1/17/2025
/*/
User Function JSFPLEG()
    local aCores := {}
    aAdd( aCores, { "BR_VERDE", "Formação de Preços Executada para o Documento" } )
    aAdd( aCores, { "BR_VERMELHO", "Formação de Preços Não Executada" } )
Return BrwLegenda( "Legendas Doc. Entrada na Formação de Preços", "Legendas", aCores )

/*/{Protheus.doc} JSFPRECO
Chama processo de formação de preços de venda
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 1/17/2025
@param cAlias, character, Alias principal da rotina (SF1)
@param nRecno, numeric, ID único do registro
@param nOpc, numeric, opção escolhida pelo usuário (1 - Visualizar, 2 - Formação de Preço)
/*/
User Function JSFPRECO( cAlias, nRecno, nOpc )
    
    Local cFilHist := cFilAnt
    
    // Troca filial posicionada no sistema caso a filial da nota seja diferente da filial corrente
    if cFilAnt != SF1TMP->F1_FILIAL
		cFilAnt := SF1TMP->F1_FILIAL
		FWSM0Util():setSM0PositionBycFilAnt()
	endif

    // Acessa tela de formação de preços com a filial da nota
    U_JSENTRDC( SF1TMP->F1_DOC, SF1TMP->F1_SERIE, SF1TMP->F1_FORNECE, SF1TMP->F1_LOJA, SF1TMP->F1_TIPO )

    if cFilAnt != cFilHist
		cFilAnt := cFilHist
		FWSM0Util():setSM0PositionBycFilAnt()
	endif

Return 

/*/{Protheus.doc} checkStruct
Função responsável por avaliar estrutura de tabelas, índices, campos para posteriormente a rotina prosseguir com o processamento
@type function
@version 12.1.2510
@author Jean Carlos Pandolfo Saggin
@since 26/02/2026
@return logical, lSuccess
/*/
static function checkStruct()
    local lSuccess := .T. as logical
    
    // Verifica se existe o campo Forma Preço no cadastro de fornecedor
    lSuccess := lSuccess .and. SA2->(FieldPos( 'A2_X_FPRC' )) > 0
    lSuccess := lSuccess .and. SF1->(FieldPos( 'F1_X_FPRC' )) > 0
    if ! lSuccess
        ProcRegua(1)
        if MsgYesNo( 'Um ou mais campos de controle estão ausentes, deseja criá-lo(s) agora? Ao clicar sobre a opação "Não", '+;
                    'o sistema permitirá que continue, porém, alguns recursos poderão ser suprimidos...', 'A T E N Ç Ã O !' )
            IncProc( 'Adequando estrutura...' )
            lSuccess := U_JSFldPut()
        else
            lSuccess := .T.
        endif
    endif

return lSuccess
