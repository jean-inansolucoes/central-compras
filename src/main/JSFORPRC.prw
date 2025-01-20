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
    
    Local cAlias    := 'SF1'
    local aPerg     := {}  as array
    local lCanSave  := .T. as logical
    local lUserSave := .T. as logical
    local cFilter   := ""  as character
    local bOk       :={|| .T. }
    local aColors   := {}  as array

    Private aRotina   := {} 
    Private cCadastro := "Formação de Preço - "+ U_JSGETVER()

    aAdd( aPerg, { 1, "Emissao de: ", StoD(' '),"", "", "", ".T.", 50, .F.  } )
    aAdd( aPerg, { 1, "Emissao até: ", StoD('20491231'),"", "", "", ".T.", 50, .F.  } )
    aAdd( aPerg, { 1, "Digitação de: ", StoD(' '),"", "", "", ".T.", 50, .F.  } )
    aAdd( aPerg, { 1, "Digitação até: ", StoD('20491231'),"", "", "", ".T.", 50, .F.  } )
    aAdd( aPerg, { 1, "Fornecedor: ", Space(TAMSX3('A2_COD')[1]),"", "", "SA2", ".T.", 60, .F.  } )
    aAdd( aPerg, { 1, "Loja: ", Space(TAMSX3('A2_LOJA')[1]),"", "", "", ".T.", 40, .F.  } )
    aAdd( aPerg, { 2, "Exibir: ", 2,{"Todas","Apenas Pendentes"}, 80, ".T.", .T.  } )

    aAdd( aColors, { "SF1->F1_X_FPRC=='S'", "BR_VERDE" } )
    aAdd( aColors, { "!SF1->F1_X_FPRC=='S'", "BR_VERMELHO" } )

    // Exibe pergunta ao usuário
    if ! ParamBox( aPerg, 'Filtros Iniciais',, bOk,,,,,,, lCanSave, lUserSave )
        Return nil
    endif
    
    cFilter := "SF1->F1_TIPO == 'N' .and. SF1->F1_DTDIGITA >= StoD('"+ DtoS( MV_PAR03 ) +"') .and. SF1->F1_DTDIGITA <= StoD('"+ DtoS( MV_PAR04 ) +"') "  // Apenas dessa faixa de digitação
    cFilter += ".and. SF1->F1_EMISSAO >= StoD('"+ DtoS( MV_PAR01 ) +"') .and. SF1->F1_EMISSAO <= StoD('"+ DtoS( MV_PAR02 ) +"') "       // Apenas dessa faixa de emissão
    if !Empty( MV_PAR05 )       // Fornecedor
        cFilter += ".and. SF1->F1_FORNECE == '"+ MV_PAR05 +"' "     // Apenas do fornecedor informado
    endif
    if ! Empty( MV_PAR06 )      // Loja
        cFilter += ".and. SF1->F1_LOJA == '"+ MV_PAR06 +"' "        // Apenas da loja informada
    endif
    if ( ValType(MV_PAR07) == "N" .and. MV_PAR07 == 2 ) .or. ( ValType( MV_PAR07 ) == 'C' .and. MV_PAR07 == 'Apenas Pendentes' )            // Apenas pendentes
        cFilter += ".and. ! SF1->F1_X_FPRC == 'S' "     // Apenas notas pendentes
    ENDIF

    aAdd( aRotina, { OemToAnsi("Visualizar"), "A103NFiscal", 0 , 2, 0, nil })
    aAdd( aRotina, { 'Form. Preço', 'U_JSFPRECO', 0, 2, 0, Nil } )
    aAdd( aRotina, { 'Legenda', 'U_JSFPLEG', 0, 2, 0, Nil } )

    DBSelectArea( 'SF1' )
    SF1->( DBSetOrder( 1 ) )

    if SF1->( FieldPos( 'F1_X_FPRC' ) ) == 0
        Hlp( 'F1_X_FPRC',;
             'Ambiente desatualizado para utilização da rotina de formação de preços.',;
             'Foi identificado que o campo F1_X_FPRC não está configurado na tabela de documentos de entrada. '+;
             'Solicite a atualização necessária para a equipe responsável pelo Painel de Compras, execute a atualização e tente novamente em seguida.' )
            return Nil
    endif

    SF1->( DBSetFilter( {|| &cFilter }, cFilter ) )

    mBrowse( 6, 1, 22, 75, cAlias,,,,,,aColors )

    SET FILTER TO
    
return Nil

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
Return BrwLegenda( "Legendas Doc. Entrada na Formação de Preços", "Legendas", aCores)

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
Return U_JSENTRDC( SF1->F1_DOC, SF1->F1_SERIE, SF1->F1_FORNECE, SF1->F1_LOJA, SF1->F1_TIPO )

/*/{Protheus.doc} hlp
Função facilitadora para utilização da função Help do Protheus
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 08/04/2024
@param cTitle, character, Titulo da janela
@param cFail, character, Informações sobre a falha
@param cHelp, character, Informações com texto de ajuda
/*/
static function hlp( cTitle, cFail, cHelp )
return Help( ,, cTitle,, cFail, 1, 0, NIL, NIL, NIL, NIL, NIL,{ cHelp } )
