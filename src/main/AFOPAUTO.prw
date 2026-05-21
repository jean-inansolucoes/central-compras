#include 'totvs.ch'
#include 'topconn.ch'
#include 'fwmvcdef.ch'
#include 'tbiconn.ch'

#define COPERACDEF "01"     // Operação padrão para apontamento da OP
#define CHRINIDEF  "08:00"  // Horário padrão para início das operacoes
#define CHRFINDEF  "08:20"  // Horário padrão para finalização das operações
#define NQTDFUNC   1        // Quantidade padrão de funcionários envolvidos na operação de produção
#define CTEMPODEF  "000:20"   // Tempo padrão para realização do processo de produção

/*/{Protheus.doc} AFOPAUTO
Função criada para apontamento automático de OPs durante o processo de pesagem e conferência de produção
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 18/01/2024
/*/
User Function AFOPAUTO()
    
    local oBrowse as object
    local aAux    := {} as array
    local cAux    := "" as character

    Private _cAliCb  := AllTrim(SuperGetMv( 'MV_X_PRD01',,"" ))
    Private _cAliIt  := AllTrim(SuperGetMv( 'MV_X_PRD02',,"" ))
    Private nHandle  := 0 as numeric
    Private cPorta   := AllTrim(SuperGetMv( 'MV_X_PRD03',,'' ))
    Private cVelocid := AllTrim(SuperGetMv( 'MV_X_PRD04',,'9600' ))
    Private cParidad := AllTrim(SuperGetMv( 'MV_X_PRD05',,'n' ))
    Private cBits    := AllTrim(SuperGetMv( 'MV_X_PRD06',,'8' ))
    Private cStopBit := AllTrim(SuperGetMv( 'MV_X_PRD07',,'2' ))
    Private cFluxo   := AllTrim(SuperGetMv( 'MV_X_PRD08',,'' ))
    Private nTimer   := SuperGetMv( 'MV_X_PRD09',,5 )
    // Private cPrinter := AllTrim(SuperGetMv( 'MV_X_PRD10',,'' ))
    Private cPasswd  := AllTrim(SuperGetMv( 'MV_X_PRD11',,'' ))
    Private cConfig  := cPorta +':'+cVelocid +','+cParidad+','+cBits+','+cStopBit
    Private _lBalOn  := .F. as logical
    Private nPeso    := 0 as numeric
    Private aOper    := {} as array
    Private oBtnAdd  as object
    Private oPeso    as object
    Private oQuant   as object
    Private nQuant   := 0 as numeric
    Private bSetF7   := {|| putPeso() }
    private INCLUI   := .F. as logical
    private ALTERA   := .F. as logical
    Private nRadPeso := 1 as numeric
    Private lPrintOk := .T. as logical
     
    // Faz checagem da estrutura de dados da rotina
    aAux := checkStruct()
    if ! aAux[1]
        aEval( aAux[2], {|x| cAux += x + chr(13)+chr(10) } )
        MsgStop( cAux +'A rotina será encerrada!', 'A T E N Ç Ã O !' )    
        Return Nil
    endif

    // checa se é possível abrir a balança
    if GetRemoteType() == 1     // Habilita apenas quando for Windows
        _lBalOn := checkBal()
        if ! _lBalOn .and. MsgYesNo( 'A comunicação com a balança parece estar offline ou as configurações não foram definidas, gostaria de configurar agora?', 'BALANÇA' )
            U_AFOPPARM()
        endif
        // lPrintOk := checkPrinter()
        // if ! lPrintOk
        //     U_HLP( 'LABEL PRINTER',;
        //             'As configurações definidas para a impressora de etiqueta não são válidas',;
        //             'Revise as configurações do equipamento '+ AllTrim( cPrinter ) + ' e tente novamente. Por hora, a funcionalidade vai permanecer desabilitada.' )
        // endif
    endif
    oBrowse := FWLoadBrw( 'AFOPAUTO' )
    oBrowse:Activate()

return Nil

/*/{Protheus.doc} checkPrinter
Função para checar se a impressora está disponível para utilização
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 23/02/2024
@return logical, lPrinterOk
/*/
// static function checkPrinter()
//     local lPrinterOk := .F. as logical
//     if GetRemoteType() == 1 // Windows
//         lPrinterOk := U_AFCFGPRT( cPrinter )
//     endif
// return lPrinterOk

/*/{Protheus.doc} BrowseDef
Função que retorna um objeto do tipo FWMBrowse
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 18/01/2024
@return object, oBrowse
/*/
static function BrowseDef()
    local oBrowse := FWMBrowse():New()
    oBrowse:SetAlias( _cAliCb )
    oBrowse:SetDescription( AllTrim( SM0->M0_FILIAL ) +' | Registro de Produção' )
    oBrowse:SetMenuDef( 'AFOPAUTO' )
    oBrowse:AddLegend( _cAliCb +"_STATUS=='P'", "BR_AMARELO", "Apontamento Pendente de Aprovação", Nil, .F. /* lFilter */ )
    oBrowse:AddLegend( "!"+ _cAliCb +"_STATUS == 'P'", "BR_VERMELHO", "OP Gerada com Sucesso", Nil, .F. /* lFilter */ )
return oBrowse

/*/{Protheus.doc} MenuDef
Função padrão para definição do menu MVC para o MBrowse
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 21/01/2024
@return array, aRotina
/*/
static function MenuDef()
    local aRotina := {} as array
    ADD OPTION aRotina Title '&Visualizar'           Action 'VIEWDEF.AFOPAUTO' OPERATION MODEL_OPERATION_VIEW   ACCESS 0 
    ADD OPTION aRotina Title '&Nova Produção'        Action 'VIEWDEF.AFOPAUTO' OPERATION MODEL_OPERATION_INSERT ACCESS 0 
    ADD OPTION aRotina Title '&Aprovar'              Action 'U_AFOPAPV()'      OPERATION MODEL_OPERATION_UPDATE ACCESS 0
    ADD OPTION aRotina Title '&Excluir'              Action 'VIEWDEF.AFOPAUTO' OPERATION MODEL_OPERATION_DELETE ACCESS 0
    ADD OPTION aRotina Title '&Parâmetros da Rotina' Action 'U_AFOPPARM()'     OPERATION 8 ACCESS 0
    ADD OPTION aRotina Title '&Gerar Etiquetas'      Action 'U_AFPRTETI()'     OPERATION MODEL_OPERATION_VIEW ACCESS 0
return aRotina

/*/{Protheus.doc} AFOPAPV
Função de aprovação do registro de apontamento de produção
@type function
@version 12.1.2410
@author JS Soluções Tecnológicas
@since 2/3/2025
@param cAlias, character, Alias principal do browse
@param nReg, numeric, Recno do registro
@param nOpc, numeric, Opção selecionada pelo usuário
/*/
User Function AFOPAPV( cAlias, nReg, nOpc )

    local aArea      := getArea()
    local nQtdAnt    := 0 as numeric
    local nQtdPlan   := 0 as numeric
    local cFaixa     := "" as character
    local nQtdTol    := 0 as numeric
    local lSuccess   := .T. as logical
    local cNumOrd    := "" as character
    local aAux       := {} as array
    local aReturn    := {} as array
    local aOrdPrd    := {} as array
    
    Private lMsErroAuto := .F. as logical

    if &(_cALiCb +'->'+ _cAliCb +'_STATUS') == 'P'      // Pendente de aprovação

        DBSelectArea( 'ZB9' )
        ZB9->( DBSetOrder( 2 ) )
        if ZB9->( DBSeek( FWxFilial( 'ZB9' ) + &( _cAliCb +'->'+ _cAliCb +'_CDPLAN' ) + &( _cAliCb +'->'+ _cAliCb +'_PROD' ) ) )

            // Faixa obtida do cabeçalho do apontamento (deve ser preenchida quando o codigo do planejamento for preenchido)
            cFaixa   := &( _cAliCb +'->'+ _cAliCb +'_FAIXA' )
            nQtdPlan := ZB9->ZB9_QTPLA

            DBSelectArea( 'ZPE' )
            ZPE->( DBSetOrder( 1 ) )
            if ZPE->( DBSeek( FWxFilial( 'ZPE' ) + cFaixa ) )
                if ZPE->ZPE_TPTOL == 'I'        // Índice
                    nQtdTol := Round((ZPE->ZPE_TOLER/100) * ZB9->ZB9_QTPLA,0)
                else                            // Quantidade
                    nQtdTol := ZPE->ZPE_TOLER
                endif
            endif
        else
            nQtdPlan := 0
            nQtdTol  := 0
        endif
        
        // Quantidade já produzida + quantidade que está sendo apontada agora
        nQtdAnt := prodAnt( &( _cAliCb +'->'+ _cAliCb +'_CDPLAN' ), &(_cAliCb +'->'+ _cAliCb +'_PROD') )

        if MsgYesNo( 'O apontamente de produção atual, somado ao que já foi produzido anteriormente desse produto para este código de planejamento, somam '+;
            Transform( &(_cAliCb +'->'+ _cAliCb +'_QTDE' ) + nQtdAnt, '@E 99,999,999.99' ) +" "+;
            &(_cAliCb +'->'+ _cAliCb +'_UM' )+ ', enquanto que o planejamento previa uma produção de '+;
            Transform( nQtdPlan, '@E 99,999,999.99' ) +" "+ &( _cAliCb +'->'+ _cAliCb +'_UM' ) +". A tolerância para a faixa a que esse processo pertence, "+;
            "prevê uma quantidade excedente de "+ Transform( nQtdTol, '@E 99,999,999.99' ) +" "+  &( _cAliCb +'->'+ _cAliCb +'_UM' ) +", "+;
            "mesmo assim, a quantidade que está sendo apontada excede o planejado, gostaria de aprovar com senha este lançamento?", 'A T E N Ç Ã O !' )
            if checkPasswd()
                aOrdPrd := makeOP()
                Processa({|| aAux := StartJob( 'U_SFINCOP',; 
                                                    GetEnvServer(),; 
                                                    .T. /* lWait */,; 
                                                    aOrdPrd,;
                                                    _cAliCb,; 
                                                    cEmpAnt,; 
                                                    cFilAnt,; 
                                                    &( _cAliCb +'->'+ _cAliCb +'_ID' ),;
                                                    dDataBase ) }, 'Aguarde...', 'Incluindo OP ref. apontamento '+ &( _cAliCb +'->'+ _cAliCb +'_ID' ), .F. )
                cNumOrd := aAux[1]
                lSuccess:= ValType(cNumOrd) == 'C' .and. !Empty( cNumOrd )
                if lSuccess
                    
                    // Grava o número da OP no formula'rio
                    RecLock( _cAliCb, .F. )
                    ( _cAliCb )->( FieldPut( FieldPos( _cAliCb +'_OP' ), cNumOrd ) )
                    ( _cAliCb )->( MsUnlock() )

                    Processa({|| aReturn := execOP( Nil, cNumOrd ) }, 'Aguarde...', 'Apontando OP '+ cNumOrd, .F. )
                    lSuccess := aReturn[1] .and. setDataApv()
                endif
                if lSuccess
                    MsgInfo( 'Apontamento aprovado com sucesso!', 'S E C E S S O !' )
                else
                    MsgStop( aAux[2], 'Falha na inclusão da OP' )
                endif
            endif
        Endif
    else
        U_HLP( 'STATUS',;
               'O status do apontamento atual não permite aprovação!',;
               'Apenas apontamentos pendentes podem ser aprovados! Selecione um apontamento pendente e tente novamente.' )
    endif

    restArea( aArea )
return nil

/*/{Protheus.doc} AFRTETI
Função que chama impressão manual de etiquetas do processo
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 23/02/2024
@param cAlias, character, Alias atual
@param nReg, numeric, Recno posicionado
@param nOpc, numeric, Opção escolhida pelo usuário no menu
@return logical, lSuccess
/*/
User function AFPRTETI( cAlias, nReg, nOpc, aLabels )
    
    local aArea     := getArea()
    local lSuccess  := .T. as logical
    Local cProduto  := ""  as character
    local cDescri   := ""  as character
    local cID       := ( _cAliCb )->( FieldGet( FieldPos( _cAliCb + '_ID' ) ) )
    local cColab    := ""  as character // Codigo do colaborador
    local cDesCol   := ""  as character // Nome do colaborador
    local nPesoEti  := 0   as numeric
    local cPlano    := ""  as character
    local cDesPlan  := ""  as character
    local nQtdPrd   := 0   as numeric
    local cUM       := ""  as character
    local nX        := 0   as numeric
    local cDescPrd  := ""  as character
    local cAux      := ""  as character
    local nMargLeft := 13                               // Margem de segurança conforme tipo de etiqueta utilizado
    local nLnHeight := 05                               // Largura de cada linha de dados
    local nLine     := 1   as numeric                   // Variável para controle da linha que está sendo impressa
    local nLbPadTop := 0.5                              // Espaçamento entre o quadro e o label do quadro (Indica que tipo de informação vai dentro do quadro)
    local nDtPadTop := 2  as numeric                    // Espaçamento entre o topo do quadro e o início da informação que está sendo exibida dentro dele
    local nMaxPrd   := 35 as numeric
    local nLinePrd  := 0 as numeric
    
    default aLabels := {}

    // Variável private que indica se a impressora de etiquetas está ativa
    if lPrintOk

        // DBSelectArea( 'CB5' )
        // CB5->( DBSetOrder( 1 ) )
        // if CB5->( DbSeek( FWxFilial( 'CB5' ) + cPrinter ) )

            // Se o vetor veio vazio, utiliza o processo posicionado
            if len( aLabels ) == 0

                DBSelectArea( _cAliIt )
                ( _cAliIt )->( DBSetOrder( 1 ) )
                if ( _cAliIt )->( DBSeek( FWxFilial( _cAliIt ) + cID ) )
                
                    while ! ( _cAliIt )->( EOF() ) .and. ;
                        ( _cAliIt )->( FieldGet( FieldPos( _cAliIt +'_FILIAL' ) ) ) +;
                        ( _cAliIt )->( FieldGet( FieldPos( _cAliIt +'_ID' ) ) ) == ;
                        FWxFilial( _cAliIt ) + cID
                        
                        cProduto := ( _cAliCb )->( FieldGet( FieldPos( _cAliCb +'_PROD' ) ) )
                        cDescri  := AllTrim( RetField( 'SB1', 1, FWxFilial( 'SB1' ) + cProduto, 'B1_DESC' ) )
                        cColab   := ( _cAliIt )->( FieldGet( FieldPos( _cAliIt +'_OPERA' ) ) )
                        cDesCol  := AllTrim( RetField( 'CB1', 1, FWxFilial( 'CB1' ) + PADR( AllTrim( cColab ), TAMSX3( 'CB1_CODOPE' )[1], ' ' ), 'CB1_NOME' ) )
                        nPesoEti := ( _cAliIt )->( FieldGet( FieldPos( _cAliIt +'_PESO' ) ) )
                        cPlano   := ( _cAliCb )->( FieldGet( FieldPos( _cAliCb +'_CDPLAN' ) ) )
                        cDesPlan := AllTrim( RetField( 'ZB8', 1, FWxFilial( 'ZB8' ) + cPlano, 'ZB8_DSPLA' ) )
                        nQtdPrd  := ( _cAliIt )->( FieldGet( FieldPos( _cAliIt +'_QTDE' ) ) )
                        cUM      := RetField( "SB1", 1, FWxFilial( 'SB1' ) + cProduto, 'B1_UM' )
                        cVolume  := ( _cAliIt )->( FieldGet( FieldPos( _cAliIt +'_VOLUME' ) ) )

                        // Verifica se o volume já está listado para impressão de etiqueta
                        if len( aLabels ) > 0 .and. aScan( aLabels, {|x| x[11] == cVolume } ) > 0
                            aLabels[aScan( aLabels, {|x| x[11] == cVolume } )][3] := iif( cColab != aLabels[aScan( aLabels, {|x| x[11] == cVolume } )][3], "VARIOS", cColab )
                            aLabels[aScan( aLabels, {|x| x[11] == cVolume } )][4] := iif( cDesCol != aLabels[aScan( aLabels, {|x| x[11] == cVolume } )][4], "VARIOS", cDesCol )
                            aLabels[aScan( aLabels, {|x| x[11] == cVolume } )][5] += nPesoEti
                            aLabels[aScan( aLabels, {|x| x[11] == cVolume } )][8] += nQtdPrd
                        else
                            aAdd( aLabels, { cProduto,;    // 1. Codigo do Produto
                                            cDescri,;      // 2. Descrição do Produto
                                            cColab,;       // 3. Codigo do Colaborador que produziu
                                            cDesCol,;      // 4. Nome do colaborador
                                            nPesoEti,;     // 5. Peso da caixa (leitura da balança ou informado manualmente)
                                            cPlano,;       // 6. Codigo do Planejamento da Produção
                                            cDesPlan,;     // 7. Descricao do Plano
                                            nQtdPrd,;      // 8. Quantidade Produzida (Primeira UM)
                                            cUM,;          // 9. Unidade de Medida do Produto
                                            cID,;          // 10. ID do processo de apontamento
                                            cVolume } )    // 11. Numero do volume   
                        endif 

                        ( _cAliIt )->( DBSkip() )
                    End

                else
                    lSuccess := .F.
                endif
            
            endif

            if len( aLabels ) > 0
                
                // // Inicia comunicação com impressora de etiquetas
                // MSCBPRINTER( AllTrim( CB5->CB5_MODELO ),"LPT"+ CB5->CB5_LPT,,34.5,.F.,,,,,,.T.)
                // MSCBCHKSTATUS( CB5->CB5_VERSTA == '1' )
                
                MSCBPRINTER("ZEBRA","LPT2",,,.F.,,,,,,.F.,)
			    MSCBCHKSTATUS(.F.)

                for nX := 1 to len( aLabels )
                        
                    // Inicia impressão da etiqueta
                    MSCBBEGIN(1,4)
                    
                    nLine := 1
                    MSCBBox( nMargLeft+ 05, nLnHeight * nLine, nMargLeft+ 75, nLnHeight * (nLine+7), 2, "B" )       // Box Geral

                    // Codigo e descricao do produto
                    MSCBSay( nMargLeft+ 06, (nLnHeight * nLine) + nLbPadTop, "Codigo", "N", "0", "012,013", .F., .F.,,.F., .F. )
                    MSCBSay( nMargLeft+ 08, (nLnHeight * nLine) + nDtPadTop, aLabels[nX][1], "N", "0", "015,016", .F., .F.,,.F., .F. )
                        

                    // Regra para que o sistema faça a quebra de linha conforme tamanho da descrição do produto
                    cAux := AllTrim( aLabels[nX][2] )
                    if len( cAux ) > nMaxPrd
                        
                        nLinePrd := Int( len( cAux ) / nMaxPrd )
                        nLinePrd += iif( len( cAux ) % nMaxPrd == 0, 0, 1 ) 
                        nLinePrd := 1 + (( nLinePrd -1 )* 0.5)
                        
                        MSCBBox( nMargLeft+ 05, nLnHeight * nLine, nMargLeft+ 30, nLnHeight * (nLine+nLinePrd), 1, "B" )       // Codigo Produto
                        MSCBBox( nMargLeft+ 30, nLnHeight * nLine, nMargLeft+ 75, nLnHeight * (nLine+nLinePrd), 1, "B" )       // Descricao Produto
                        MSCBSay( nMargLeft+ 31, (nLnHeight * nLine) + nLbPadTop, "Descrição Produto", "N", "0", "012,013", .F., .F.,,.F., .F. )
                        while ! Empty( cAux )
                            cDescPrd := SubStr( cAux, 1, iif( len( cAux ) >= nMaxPrd, nMaxPrd, len( cAux ) ) )
                            cAux     := iif( len( cAux ) > nMaxPrd, SubStr( cAux, nMaxPrd+1 ), '' )
                            MSCBSay( nMargLeft+ 33, (nLnHeight * nLine) + nDtPadTop, cDescPrd, "N", "0", "015,016", .F., .F.,,.F., .F. )    
                            nLine+= 0.5
                        end
                        nLine += 0.5
                    else
                        MSCBBox( nMargLeft+ 30, nLnHeight * nLine, nMargLeft+ 75, nLnHeight * (nLine+1), 1, "B" )       // Descricao Produto
                        MSCBSay( nMargLeft+ 31, (nLnHeight * nLine) + nLbPadTop, "Descrição Produto", "N", "0", "012,013", .F., .F.,,.F., .F. )
                        MSCBSay( nMargLeft+ 33, (nLnHeight * nLine) + nDtPadTop, aLabels[nX][2], "N", "0", "015,016", .F., .F.,,.F., .F. )
                        nLine++
                    endif

                    MSCBBox( nMargLeft+ 05, nLnHeight * nLine, nMargLeft+ 20, nLnHeight * (nLine+1), 1, "B" )       // Codigo Colaborador(a)
                    MSCBSay( nMargLeft+ 06, (nLnHeight * nLine) + nLbPadTop, "Colaborador(a)", "N", "0", "012,013", .F., .F.,,.F., .F. )
                    MSCBSay( nMargLeft+ 08, (nLnHeight * nLine) + nDtPadTop, aLabels[nX][3], "N", "0", "015,016", .F., .F.,,.F., .F. )

                    MSCBBox( nMargLeft+ 20, nLnHeight * nLine, nMargLeft+ 55, nLnHeight * (nLine+1), 1, "B" )       // Nome Colaborador(a)
                    MSCBSay( nMargLeft+ 21, (nLnHeight * nLine) + nLbPadTop, "Nome Colaborador(a)", "N", "0", "012,013", .F., .F.,,.F., .F. )
                    MSCBSay( nMargLeft+ 23, (nLnHeight * nLine) + nDtPadTop, aLabels[nX][4], "N", "0", "015,016", .F., .F.,,.F., .F. )
                    
                    MSCBBox( nMargLeft+ 55, nLnHeight * nLine, nMargLeft+ 75, nLnHeight * (nLine+1), 1, "B" )       // Peso Produzido
                    MSCBSay( nMargLeft+ 56, (nLnHeight * nLine) + nLbPadTop, "Peso (kg)", "N", "0", "012,013", .F., .F.,,.F., .F. )
                    MSCBSay( nMargLeft+ 58, (nLnHeight * nLine) + nDtPadTop, AllTrim( Transform( aLabels[nX][5], "@E 9,999.999" ) ), "N", "0", "015,016", .F., .F.,,.F., .F. )

                    nLine++
                    MSCBBox( nMargLeft+ 05, nLnHeight * nLine, nMargLeft+ 20, nLnHeight * (nLine+1), 1, "B" )       // Codigo Plano
                    MSCBSay( nMargLeft+ 06, (nLnHeight * nLine) + nLbPadTop, "Plano", "N", "0", "012,013", .F., .F.,,.F., .F. )
                    MSCBSay( nMargLeft+ 08, (nLnHeight * nLine) + nDtPadTop, aLabels[nX][6], "N", "0", "015,016", .F., .F.,,.F., .F. )

                    MSCBBox( nMargLeft+ 20, nLnHeight * nLine, nMargLeft+ 55, nLnHeight * (nLine+1), 1, "B" )       // Descrição Plano
                    MSCBSay( nMargLeft+ 21, (nLnHeight * nLine) + nLbPadTop, "Descrição Plano", "N", "0", "012,013", .F., .F.,,.F., .F. )
                    MSCBSay( nMargLeft+ 23, (nLnHeight * nLine) + nDtPadTop, aLabels[nX][7], "N", "0", "015,016", .F., .F.,,.F., .F. )
                    
                    MSCBBox( nMargLeft+ 55, nLnHeight * nLine, nMargLeft+ 75, nLnHeight * (nLine+1), 1, "B" )       // Quantidade Produzida
                    MSCBSay( nMargLeft+ 56, (nLnHeight * nLine) + nLbPadTop, "Qtde ("+ aLabels[nX][9] +")", "N", "0", "012,013", .F., .F.,,.F., .F. )
                    MSCBSay( nMargLeft+ 58, (nLnHeight * nLine) + nDtPadTop, Transform( aLabels[nX][8], '@E 99,999.99' ), "N", "0", "015,016", .F., .F.,,.F., .F. )

                    MSCBEND()
                    Sleep(150)
                    
                next nX

                MSCBCLOSEPRINTER()
            else
                lSuccess := .F.
            endif

        // else
        //     lSuccess := .F.
        // endif

    else
        lSuccess := .F.
    endif

    restArea( aArea )
return lSuccess

/*/{Protheus.doc} modelDef
Função padrão para definição do modelo de dados da rotina
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 21/01/2024
@return object, oModel
/*/
static function modelDef()
    
    local oModel          as object
    local cMaster   := _cAliCb + 'MASTER'
    local cDetail   := _cAliIt + 'DETAIL'
    local oStruCab  := FWFormStruct( 1, _cAliCb )
    local oStruIte  := FWFormStruct( 1, _cAliIt )
    local aRelation := {} as array
    local aTriggers := {} as array
    local bLinePre  := {|oGrid,nLine,cAction| linePre( oGrid, nLine, cAction ) }
    local bPost     := {|oModel| preCommit( oModel ) }

    aAdd( aTriggers, FWStruTrigger( _cAliCb +'_PROD',;
                                    _cAliCb +'_DESCRI',;
                                    "SB1->B1_DESC",;
                                    .T.,;
                                    "SB1",;
                                    1,;
                                    "FWxFilial('SB1')+M->"+ _cAliCb +"_PROD",;
                                    Nil,;
                                    "01" ) )
    
    aAdd( aTriggers, FWStruTrigger( _cAliCb +'_PROD',;
                                    _cAliCb +'_RECUR',;
                                    "SG2->G2_RECURSO",;
                                    .T.,;
                                    "SG2",;
                                    1,;
                                    "FWxFilial('SG2')+M->"+ _cAliCb +"_PROD",;
                                    Nil,;
                                    "02" ) )

    aAdd( aTriggers, FWStruTrigger( _cAliCb +'_PROD',;
                                    _cAliCb +'_UM',;
                                    "SB1->B1_UM",;
                                    .T.,;
                                    "SB1",;
                                    1,;
                                    "FWxFilial('SB1')+M->"+ _cAliCb +"_PROD",;
                                    Nil,;
                                    "03" ) )
    
    aAdd( aTriggers, FWStruTrigger( _cAliCb +'_CDPLAN',;
                                    _cAliCb +'_DPLAN',;
                                    "ZB8->ZB8_DSPLA",;
                                    .T.,;
                                    "ZB8",;
                                    1,;
                                    "FWxFilial('ZB8')+M->"+_cAliCb+"_CDPLAN",;
                                    Nil,;
                                    "04" ))

    aAdd( aTriggers, FWStruTrigger( _cAliCb +'_CDPLAN',;
                                    _cAliCb +'_FAIXA',;
                                    "U_SFSELFX()",;
                                    .F.,;
                                    Nil,;
                                    Nil,;
                                    Nil,;
                                    Nil,;
                                    "05" ))

    oStruCab:AddTrigger( aTriggers[1][1],;
                         aTriggers[1][2],;
                         aTriggers[1][3],;
                         aTriggers[1][4] )

    oStruCab:AddTrigger( aTriggers[2][1],;
                         aTriggers[2][2],;
                         aTriggers[2][3],;
                         aTriggers[2][4] )

    oStruCab:AddTrigger( aTriggers[3][1],;
                         aTriggers[3][2],;
                         aTriggers[3][3],;
                         aTriggers[3][4] )

    // Descrição do código de planejamento
    oStruCab:AddTrigger( aTriggers[4][1],;
                         aTriggers[4][2],;
                         aTriggers[4][3],;
                         aTriggers[4][4] )

    // Gatilho para preenchimento da faixa de análise
    oStruCab:AddTrigger( aTriggers[5][1],;
                         aTriggers[5][2],;
                         aTriggers[5][3],;
                         aTriggers[5][4] )

    // ALtera propriedade VALID do campo do código de planejamento
    oStruCab:SetProperty( _cAliCb +'_CDPLAN', MODEL_FIELD_VALID, FwBuildFeature(STRUCT_FEATURE_VALID, 'Vazio().or.U_SFVLDPLN()'))

    // Atribui inicializador padrão para o campo do ID quando for inclusão
    oStruCab:SetProperty( _cAliCb +'_ID', MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, 'U_SFAPOID()') )

    oModel := MPFormModel():New( 'MDOPAUTO',,bPost )
    oModel:AddFields( cMaster, , oStruCab )
    oModel:AddGrid( cDetail, cMaster, oStruIte, bLinePre )

    aAdd( aRelation, { _cAliIt +'_FILIAL', 'FWxFilial("'+ _cAliIt +'")' } )
    aAdd( aRelation, { _cAliIt +'_ID', _cAliCb +'_ID' } )

    oModel:SetRelation( cDetail,  aRelation, ( _cAliIt )->( IndexKey( 1 ) ) )
    oModel:SetPrimaryKey( { _cAliCb +"_FILIAL", _cAliCb +'_ID' } )

    oModel:SetDescription( 'Registro de Produção' )
    oModel:GetModel( cMaster ):SetDescription( 'Cabeçalho do Apontamento' )
    oModel:GetModel( cDetail ):SetDescription( 'Pesagens do Apontamento' )

    // Bloqueia propriedades do ModelGrid
    oModel:GetModel( cDetail ):SetNoInsertLine( .T. )
    oModel:GetModel( cDetail ):SetNoUpdateLine( .T. )

return oModel

/*/{Protheus.doc} preCommit
Função criada para executar a inclusão da OP e realizar os apontamentos necessários antes da persistência dos dados
do modelo no banco de dados
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 14/02/2024
@param oModel, object, objeto do modelo de dados
@return logical, lSuccess
/*/
static function preCommit( oModel )
    
    local lSuccess := .T. as logical
    local cNumOrd  := "" as character
    local aAux     := {} as array
    local oOP      := oModel:GetModel( _cAliCb +'MASTER' )
    // local oAponta  := oModel:GetModel( _cAliIt +'DETAIL' )
    local lInclui  := oModel:GetOperation() == MODEL_OPERATION_INSERT
    local lUpdate  := oModel:GetOperation() == MODEL_OPERATION_UPDATE
    local lExclui  := oModel:GetOperation() == MODEL_OPERATION_DELETE
    local aOrdPrd  := {} as array
    local nOpc     := 0 as numeric
    // local nX       := 0 as numeric
    local aRows    := FWSaveRows()
    local aAponta  := {} as array
    // local nTotApo  := 0 as numeric
    local aLabels  := {} as array
    local cFaixa   := "" as character
    local nQtdTol  := 0 as numeric
    local nQtdPlan := 0 as numeric
    // local cOldFun  := FunName()
    local aReturn  := {} as array
    local lAprov   := .F. as logical

    Private lMsErroAuto :=.F.
    Private lMsHelpAuto :=.T.

    if ( lInclui .or. lUpdate ) .and. Empty( oOP:GetValue( _cAliCb +'_OP' ) )

        // Valida se o código do planejamento foi preenchido para poder verificar se a tolerância do que foi produzido está dentro da expectativa
        if !Empty( oOP:GetValue( _cAliCb +'_CDPLAN' ) )

            DBSelectArea( 'ZB9' )
            ZB9->( DBSetOrder( 2 ) )
            if ZB9->( DBSeek( FWxFilial( 'ZB9' ) + oOP:GetValue( _cAliCb +'_CDPLAN' ) + oOP:GetValue( _cAliCb +'_PROD' ) ) )

                // Faixa obtida do cabeçalho do apontamento (deve ser preenchida quando o codigo do planejamento for preenchido)
                cFaixa   := oOP:GetValue( _cAliCb +'_FAIXA' )
                nQtdPlan := ZB9->ZB9_QTPLA

                DBSelectArea( 'ZPE' )
                ZPE->( DBSetOrder( 1 ) )
                if ZPE->( DBSeek( FWxFilial( 'ZPE' ) + cFaixa ) )
                    if ZPE->ZPE_TPTOL == 'I'        // Índice
                        nQtdTol := Round((ZPE->ZPE_TOLER/100) * ZB9->ZB9_QTPLA,0)
                    else                            // Quantidade
                        nQtdTol := ZPE->ZPE_TOLER
                    endif
                endif
            else
                nQtdPlan := 0
                nQtdTol  := 0
            endif

            // Identifica a quantidade já produzida para o produto relacionado ao código de planejamento informado
            nQtdAnt := prodAnt( oOP:GetValue( _cAliCb +'_CDPLAN' ), oOP:GetValue( _cAliCb +'_PROD' ) )

            // Verifica se a quantidade que está sendo apontada, mais a quantidade que já foi produzida em outras ordens do mesmo produto
            // está dentro da quantidade prevista para a produção somado a quantidade de tolerância de acordo com a faixa em que o 
            // apontamento se encontra
            if ( oOP:GetValue( _cAliCb +'_QTDE' ) + nQtdAnt ) > ( nQtdPlan + nQtdTol )
                oOP:SetValue( _cAliCb + '_STATUS', 'P' )        // Pendente (Bloqueado)
                if MsgYesNo( 'O apontamente de produção atual, somado ao que já foi produzido anteriormente desse produto para este código de planejamento, somam '+;
                    Transform( oOP:GetValue( _cAliCb +'_QTDE' ) + nQtdAnt, '@E 99,999,999.99' ) +" "+;
                    oOP:GetValue( _cAliCb +'_UM' ) +', enquanto que o planejamento previa uma produção de '+;
                    Transform( nQtdPlan, '@E 99,999,999.99' ) +" "+ oOP:GetValue( _cAliCb +'_UM' ) +". A tolerância para a faixa a que esse processo pertence, "+;
                    "prevê uma quantidade excedente de "+ Transform( nQtdTol, '@E 99,999,999.99' ) +" "+  oOP:GetValue( _cAliCb +'_UM' ) +", "+;
                    "mesmo assim, a quantidade que está sendo apontada excede o planejado, gostaria de aprovar com senha este lançamento?", 'A T E N Ç Ã O !' )
                    if checkPasswd()
                        lAprov := .T.
                    endif
                endif
            endif
        endif
        
        // Valida se já não existe apontamento com o número em memória
        if lInclui .and. existID(oOP:GetValue( _cAliCb +'_ID' ) )
            oOP:SetValue( _cAliCb +'_ID', U_SFAPOID() )
        endif

        // Apenas gera a OP no PCP quando o status estiver sem restrição ou Aprovado
        if ( oOP:GetValue( _cALiCb + '_STATUS' ) $ 'S|A' .or. lAprov ) .and. lSuccess
            
            //Processa({|| cNumOrd := createOP( oOP ) }, 'Aguarde...', 'Incluindo OP ref. apontamento '+ oOP:GetValue( _cAliCb +'_ID' ), .F. )
            aOrdPrd := makeOP( oOP )
            Processa({|| aAux := StartJob( 'U_SFINCOP',; 
                                            GetEnvServer(),; 
                                            .T. /* lWait */,; 
                                            aOrdPrd,; 
                                            _cAliCb,; 
                                            cEmpAnt,; 
                                            cFilAnt,;
                                            oOP:GetValue( _cAliCb +'_ID' ),;
                                            dDataBase ) }, 'Aguarde...', 'Incluindo OP ref. apontamento '+ oOP:GetValue( _cAliCb +'_ID' ), .F. )
            cNumOrd := aAux[1]
            lSuccess:= ValType( cNumOrd ) == 'C' .and. !Empty( cNumOrd )
            if lSuccess
                oOP:SetValue( _cAliCb +'_OP', cNumOrd )
                Processa({|| aReturn := execOP( oModel, cNumOrd ) }, 'Aguarde...', 'Apontando OP '+ cNumOrd )
                lSuccess := aReturn[1]
                if lSuccess
                    aLabels := aReturn[2]
                endif
            else
                MsgStop( aAux[2], 'Falha na inclusão da OP' )
            endif
            if lSuccess
                setDataApv( oOP )
            endif
        endif

    elseif lExclui
        
        // Obtem o código da Ordem de Produção que está gravado no processo
        nOpc    := 5
        cNumOrd := oOP:GetValue( _cAliCb + '_OP' )
        
        Begin Transaction
            
            DBSelectArea( 'SH6' )
            SH6->( DBSetOrder( 3 ) )        // H6_FILIAL, H6_PRODUTO, H6_OP, H6_OPERAC, H6_LOTECTL, H6_NUMLOTE
            if DBSeek( FWxFilial( 'SH6' ) + oOP:GetValue( _cAliCb + '_PROD' ) + oOP:GetValue( _cAliCb + '_OP' ) )
                While ! SH6->( EOF() ) .and. SH6->H6_FILIAL + SH6->H6_PRODUTO + SubStr( SH6->H6_OP, 01, 06 ) ==;
                    FWxFilial( 'SH6' ) + oOP:GetValue( _cAliCb + '_PROD' ) + oOP:GetValue( _cAliCb + '_OP' )

                    aAponta := {{"H6_OP"     , SH6->H6_OP      , NIL},;
                                {"H6_PRODUTO", SH6->H6_PRODUTO , NIL},;
                                {"H6_OPERAC" , SH6->H6_OPERAC  , NIL},;
                                {"H6_RECURSO", SH6->H6_RECURSO , NIL},;
                                {"H6_DTAPONT", SH6->H6_DTAPONT , NIL},;
                                {"H6_DATAINI", SH6->H6_DATAINI , NIL},;
                                {"H6_HORAINI", SH6->H6_HORAINI , NIL},;
                                {"H6_DATAFIN", SH6->H6_DATAFIN , NIL},;
                                {"H6_HORAFIN", SH6->H6_HORAFIN , NIL},;
                                {"H6_PT"     , SH6->H6_PT      , NIL},;
                                {"H6_LOCAL"  , SH6->H6_LOCAL   , NIL},;
                                {"H6_LOTECTL", SH6->H6_LOTECTL , NIL},;
                                {"H6_QTDPROD", SH6->H6_QTDPROD , NIL},;
                                {"AUTRECNO"  , SH6->(Recno())  , Nil} }

                    lMsErroAuto := .F.
                    MSExecAuto({|x, y| mata681(x,y)}, aAponta, nOpc )
                    
                    If lMsErroAuto
                        lSuccess := .F.
                        MostraErro()
                    Endif

                    SH6->( DBSkip() )

                    if ! lSuccess
                        Exit
                    endif
                end
            endif

            if lSuccess

                DBSelectArea( 'SC2' )
                SC2->( DBSetOrder( 1 ) )
                if SC2->( DBSeek( FWxFilial( 'SC2' ) + oOP:GetValue( _cAliCb + '_OP' ) ) )

                    aAdd( aOrdPrd, { "C2_FILIAL" , SC2->C2_FILIAL, Nil } )
                    aAdd( aOrdPrd, { "C2_NUM"    , SC2->C2_NUM, Nil } )
                    aAdd( aOrdPrd, { "C2_PRODUTO", SC2->C2_PRODUTO, Nil } )
                    aAdd( aOrdPrd, { "C2_ITEM"   , SC2->C2_ITEM, Nil } )
                    aAdd( aOrdPrd, { "C2_SEQUEN" , SC2->C2_SEQUEN, Nil } )
                    aAdd( aOrdPrd, { "C2_QUANT"  , SC2->C2_QUANT, Nil } )

                    lMsErroAuto := .F.
                    MSExecAuto({|x,Y| Mata650(x,Y)}, aOrdPrd, nOpc)

                    if lMsErroAuto
                        lSuccess := .F.
                        MostraErro()
                    endif

                endif

            else
                DisarmTransaction()
            endif

        End Transaction

    endif

    FWRestRows( aRows )
return lSuccess

/*/{Protheus.doc} execOP
Função para executar o apontamento automático da OP gerada no processo anterior
@type function
@version 12.1.2410
@author JS Soluções Tecnológicas
@since 2/5/2025
@param oOP, object, objeto de dados do cabeçalho do apontamento
@param cOP, character, ID da OP gerada
@return array, { lSuccess, aLabels }
/*/
static function execOP( oModel, cOP ) 

    local aLabels  := {} as array
    local nTotApo  := 0 as numeric
    local cNumOrd  := "" as character
    local lMVC     := ValType( oModel ) == 'O'
    local oOP      := iif( lMVC, oModel:GetModel( _cAliCb +'MASTER' ), Nil )
    local oAponta  := iif( lMVC, oModel:GetModel( _cAliIt +'DETAIL' ), Nil )
    local lSuccess := .T. as logical
    local cIDApont := "" as character
    local cOldFun  := FunName() as character
    local nX       := 0 as numeric

    private lMsErroAuto := .F. as logical

    default cOP := ""

    Begin Transaction

        // Percorre as linhas que deverão ser utilizadas para os apontamentos da produção
        nTotApo := 0
        cNumOrd := iif( lMVC, oOP:GetValue( _cAliCb +'_OP' ), cOP )
        cIDApont:= iif( lMVC, oOP:GetValue( _cAliCb +'_ID' ), &( _cAliCb +'->'+ _cAliCb +'_ID' ) )

        if Empty( cNumOrd )
            U_HLP( 'FALHASC2',; 
                'Não foi possível identificar OP gerada a partir do ID do Apontamento '+ iif( lMVC, oOP:GetValue( _cAliCb +'_ID' ), &( _cAliCb +'->'+ _cAliCb +'_ID' ) ),;
                'Envie esta mensagem à equipe responsável pelo sistema e aguarde para poder prosseguir.' )
            lSuccess := .F.
        endif
        if lSuccess
            if lMVC
                aAponta := {}
                for nX := 1 to oAponta:Length()
                    oAponta:GoLine( nX )
                    if ! oAponta:IsDeleted()
                        nTotApo += Round(oAponta:GetValue( _cAliIt +'_QTDE' ),0)
                        aAponta := {{ "H6_FILIAL" , FWxFilial( "SH6" ), Nil },;
                                    { "H6_OP"     , cNumOrd + "01" + "001" + "   ", Nil },;
                                    { "H6_PRODUTO", oOP:GetValue( _cAliCb +'_PROD' ), Nil },;
                                    { "H6_OPERAC" , COPERACDEF, Nil },; 
                                    { "H6_RECURSO", oOP:GetValue( _cAliCb +'_RECUR' ), Nil },;
                                    { "H6_DTAPONT", dDataBase, Nil },;
                                    { "H6_DATAINI", dDataBase, Nil },;
                                    { "H6_HORAINI", CHRINIDEF, Nil },;
                                    { "H6_DATAFIN", dDataBase, Nil },;
                                    { "H6_HORAFIN", CHRFINDEF, Nil },;
                                    { "H6_LOCAL"  , RetField( "SB1", 1, FWxFilial( "SB1" ) + oOP:GetValue( _cAliCb + '_PROD' ), "B1_LOCPAD" ), Nil },;
                                    { "H6_QTDPROD", oAponta:GetValue( _cAliIt + '_QTDE' ), Nil },;
                                    { "H6_PERDA"  , 0, Nil },;
                                    { "H6_X_QFUNC", NQTDFUNC, Nil },;
                                    { "H6_TEMPO"  , CTEMPODEF, Nil },;
                                    { "H6_OPERADO", oAponta:GetValue( _cAliIt + '_OPERA' ), Nil },;
                                    { "H6_OBSERVA", "APONT AUT ID "+ oOP:GetValue( _cAliCb +'_ID' ) +" SEQ "+ oAponta:GetValue( _cAliIt +'_SEQ' ), Nil }}
                                    // { "H6_PT"     , iif( nTotApo >= Round(oOP:GetValue( _cAliCb +'_QTDE' ),0),"T","P" ), Nil },;
                        
                        // Agrupa volumes iguais para emitir apenas uma etiqueta
                        if len( aLabels ) > 0 .and. aScan( aLabels, {|x| x[11] == oAponta:GetValue( _cAliIt + '_VOLUME' ) } ) > 0
                            // Atualiza codigo de quem realizou o apontamento, se foi mais que um operador, altera para VARIOS
                            aLabels[aScan( aLabels, {|x| x[11] == oAponta:GetValue( _cAliIt + '_VOLUME' ) } )][3] := ;
                                iif( ! aLabels[aScan( aLabels, {|x| x[11] == oAponta:GetValue( _cAliIt + '_VOLUME' ) } )][3] == oAponta:GetValue( _cAliIt + '_VOLUME' ),; 
                                    "VARIOS",;
                                    oAponta:GetValue( _cAliIt + '_OPERA' ) )
                            // Atualiza nome de quem realizou o apontamento, se foi mais que um oprador, altera para VARIOS
                            aLabels[aScan( aLabels, {|x| x[11] == oAponta:GetValue( _cAliIt + '_VOLUME' ) } )][4] := ;
                                iif( ! aLabels[aScan( aLabels, {|x| x[11] == oAponta:GetValue( _cAliIt + '_VOLUME' ) } )][4] == oAponta:GetValue( _cAliIt + '_VOLUME' ),; 
                                    "VARIOS",;
                                    oAponta:GetValue( _cAliIt + '_NOPERA' ) )
                            // Soma os pesos do mesmo volume
                            aLabels[aScan( aLabels, {|x| x[11] == oAponta:GetValue( _cAliIt + '_VOLUME' ) } )][5] += oAponta:GetValue( _cAliIt + '_PESO' )
                            // Soma as quantidades do mesmo volume
                            aLabels[aScan( aLabels, {|x| x[11] == oAponta:GetValue( _cAliIt + '_VOLUME' ) } )][8] += oAponta:GetValue( _cAliIt + '_QTDE' )
                        else
                            aAdd( aLabels, { oOP:GetValue( _cAliCb +'_PROD' ),;        // 1. Codigo do Produto
                                            oOP:GetValue( _cAliCb +'_DESCRI' ),;       // 2. Descrição do Produto
                                            oAponta:GetValue( _cAliIt + '_OPERA' ),;   // 3. Codigo do Colaborador que produziu
                                            oAponta:GetValue( _cAliIt + '_NOPERA' ),;  // 4. Nome do colaborador
                                            oAponta:GetValue( _cAliIt + '_PESO' ),;    // 5. Peso da caixa (leitura da balança ou informado manualmente)
                                            oOP:GetValue( _cAliCb +'_CDPLAN' ),;       // 6. Codigo do Planejamento da Produção
                                            oOP:GetValue( _cAliCb +'_DPLAN' ),;        // 7. Descricao do Plano
                                            oAponta:GetValue( _cAliIt + '_QTDE' ),;    // 8. Quantidade Produzida (Primeira UM)
                                            oOP:GetValue( _cAliCb +'_UM' ),;           // 9. Unidade de Medida do Produto
                                            oOP:GetValue( _cAliCb +'_ID' ),;           // 10. ID do processo de apontamento
                                            oAponta:GetValue( _cAliIt + '_VOLUME' ) } )// 11. ID do volume         
                        endif

                        SetFunName( "MATA681" )
                        lMsErroAuto := .F.
                        MSExecAuto({|x, y| mata681(x,y)}, aAponta, 3 )
                        SetFunName( cOldFun )
                        
                        If lMsErroAuto
                            lSuccess := .F.
                            MostraErro()
                        Endif
                    endif
                    if ! lSuccess
                        aLabels := {}
                        Exit
                    endif
                next nX
            else
                DBSelectArea( _cAliIt )
                ( _cAliIt )->( DBSetOrder( 1 ) )
                if ( _cAliIt )->( DBSeek( FWxFilial( _cAliIt ) + cIDApont ) )
                    aAponta := {}
                    while ! ( _cAliIt )->( EOF() ) .and. &( _cAliIt +'->'+ _cAliIt +'_FILIAL' ) + &( _cAliIt +'->'+ _cAliIt +'_ID' ) ==;
                        FWxFilial( _cAliIt ) + cIDApont .and. lSuccess
                        
                        nTotApo += Round(&( _cAliIt +'->'+ _cAliIt +'_QTDE' ), 0)
                        aAponta := {{ "H6_FILIAL" , FWxFilial( "SH6" ), Nil },;
                                        { "H6_OP"     , cNumOrd + "01" + "001" + "   ", Nil },;
                                        { "H6_PRODUTO", &( _cAliCb +'->'+ _cAliCb +'_PROD' ), Nil },;
                                        { "H6_OPERAC" , COPERACDEF, Nil },; 
                                        { "H6_RECURSO", &( _cAliCb +'->'+ _cAliCb +'_RECUR' ), Nil },;
                                        { "H6_DTAPONT", dDataBase, Nil },;
                                        { "H6_DATAINI", dDataBase, Nil },;
                                        { "H6_HORAINI", CHRINIDEF, Nil },;
                                        { "H6_DATAFIN", dDataBase, Nil },;
                                        { "H6_HORAFIN", CHRFINDEF, Nil },;
                                        { "H6_LOCAL"  , RetField( "SB1", 1, FWxFilial( "SB1" ) + &( _cAliCb +'->'+ _cAliCb + '_PROD' ), "B1_LOCPAD" ), Nil },;
                                        { "H6_QTDPROD", &( _cAliIt +'->'+ _cAliIt + '_QTDE' ), Nil },;
                                        { "H6_PERDA"  , 0, Nil },;
                                        { "H6_X_QFUNC", NQTDFUNC, Nil },;
                                        { "H6_TEMPO"  , CTEMPODEF, Nil },;
                                        { "H6_OPERADO", &( _cAliIt +'->'+ _cAliIt + '_OPERA' ), Nil },;
                                        { "H6_OBSERVA", "APONT AUT ID "+ cIDApont +" SEQ "+ &( _cAliIt +'->'+ _cAliIt +'_SEQ' ), Nil }}
                                        // { "H6_PT"     , iif( nTotApo >= Round(&( _cAliCb +'->'+ _cAliCb +'_QTDE' ),0),"T","P" ), Nil },;

                        // Agrupa volumes iguais para emitir apenas uma etiqueta
                        if len( aLabels ) > 0 .and. aScan( aLabels, {|x| x[11] == &( _cAliIt +'->'+_cAliIt + '_VOLUME' ) } ) > 0
                            // Atualiza codigo de quem realizou o apontamento, se foi mais que um operador, altera para VARIOS
                            aLabels[aScan( aLabels, {|x| x[11] == &( _cAliIt +'->'+_cAliIt + '_VOLUME' ) } )][3] := ;
                                iif( ! aLabels[aScan( aLabels, {|x| x[11] == &( _cAliIt +'->'+ _cAliIt + '_VOLUME' ) } )][3] == &( _cAliIt +'->'+ _cAliIt + '_VOLUME' ),; 
                                    "VARIOS",;
                                    &( _cAliIt +'->'+ _cAliIt + '_OPERA' ) )
                            // Atualiza nome de quem realizou o apontamento, se foi mais que um oprador, altera para VARIOS
                            aLabels[aScan( aLabels, {|x| x[11] == &( _cAliIt +'->'+ _cAliIt + '_VOLUME' ) } )][4] := ;
                                iif( ! aLabels[aScan( aLabels, {|x| x[11] == &( _cAliIt +'->'+ _cAliIt + '_VOLUME' ) } )][4] == &( _cAliIt +'->'+ _cAliIt + '_VOLUME' ),; 
                                    "VARIOS",;
                                    &( _cAliIt +'->'+ _cAliIt + '_NOPERA' ) )
                            // Soma os pesos do mesmo volume
                            aLabels[aScan( aLabels, {|x| x[11] == &( _cAliIt +'->'+ _cAliIt + '_VOLUME' ) } )][5] += &( _cAliIt +'->'+ _cAliIt + '_PESO' )
                            // Soma as quantidades do mesmo volume
                            aLabels[aScan( aLabels, {|x| x[11] == &( _cAliIt +'->'+ _cAliIt + '_VOLUME' ) } )][8] += &( _cAliIt +'->'+ _cAliIt + '_QTDE' )
                        else
                            aAdd( aLabels, {&( _cAliCb +'->'+ _cAliCb +'_PROD' ),;        // 1. Codigo do Produto
                                            RetField( 'SB1', 1, FWxFilial( 'SB1' ) + &( _cAliCb +'->'+ _cAliCb +'_PROD' ), 'B1_DESC' ),;       // 2. Descrição do Produto
                                            &( _cAliIt +'->'+ _cAliIt +'_OPERA' ),;   // 3. Codigo do Colaborador que produziu
                                            RetField( 'CB1', 1, FWxFilial( 'CB1' ) + &( _cAliIt +'->'+ _cAliIt +'_OPERA' ), 'CB1_NOME' ),;  // 4. Nome do colaborador
                                            &( _cAliIt +'->'+ _cAliIt +'_PESO' ),;    // 5. Peso da caixa (leitura da balança ou informado manualmente)
                                            &( _cAliCb +'->'+ _cAliCb +'_CDPLAN' ),;       // 6. Codigo do Planejamento da Produção
                                            RetField( 'ZB8', 1, FWxFilial( 'ZB8' ) + &( _cAliCb +'->'+ _cAliCb +'_CDPLAN' ), 'ZB8_DSPLA' ),;        // 7. Descricao do Plano
                                            &( _cAliIt +'->'+ _cAliIt +'_QTDE' ),;    // 8. Quantidade Produzida (Primeira UM)
                                            &( _cAliCb +'->'+ _cAliCb +'_UM' ),;           // 9. Unidade de Medida do Produto
                                            &( _cAliCb +'->'+ _cAliCb +'_ID' ),;           // 10. ID do processo de apontamento
                                            &( _cAliIt +'->'+ _cAliIt +'_VOLUME' ) } )// 11. ID do volume         
                        endif

                        SetFunName( "MATA681" )
                        lMsErroAuto := .F.
                        MSExecAuto({|x, y| mata681(x,y)}, aAponta, 3 )
                        SetFunName( cOldFun )
                        
                        If lMsErroAuto
                            lSuccess := .F.
                            MostraErro()
                        Endif

                        ( _cAliIt )->( DBSkip() )
                    end

                endif
            endif

        endif

        if ! lSuccess
            aLabels := {}
            DisarmTransaction()
        endif

    End Transaction

return { lSuccess, aLabels }

/*/{Protheus.doc} createOP
Função que cria Ordem de Produção e retorna o número da OP criada
@type function
@version 12.1.2410
@author JS Soluções Tecnológicas
@since 2/5/2025
@return character, cOP
/*/
static function createOP( aOrdPrd, cID )
    
    local nOpc := 3
    local cErro := "" as character
    local cOldFun := FunName()

    Private lMsErroAuto := .F.
    
    lMsErroAuto := .F.
    SetFunName( 'MATA650' )
    MSExecAuto({|x,Y| Mata650(x,Y)},aOrdPrd,nOpc)
    SetFunName( cOldFun )

    if lMsErroAuto
        cErro := MostraErro()
        cOP := Space( TAMSX3( 'C2_NUM' )[1] ) 
    else
        // Identifica o número da OP gerada
        cOP := getSC2( cID )
        cErro := ""
    endif

return { cOP, cErro }

/*/{Protheus.doc} makeOP
Cria o Vetor da OP
@type function
@version 12.1.2410
@author JS Soluções
@since 3/13/2025
@param oOP, object, Objeto do Model, quando processamento for em memória
@return array, aOrdPrd
/*/
static function makeOP( oOP )

    local cOP := Space( TAMSX3('C2_NUM')[1] ) as character
    local aOrdPrd := {} as array
    local lMVC    := .F. as logical

    default oOP := Nil

    lMVC    := ValType( oOP ) == 'O'        // Quando o objeto vier informado via parâmetro, é porque é MVC, do contrário, apenas está posicionado no processo
    nOpc    := 3
    aOrdPrd := {}

    DBSelectArea( 'SC2' )
    SC2->( DbSetOrder( 1 ) )

    cOP := GetSXENum( 'SC2', 'C2_NUM', ,1 )
    ConfirmSX8()
    
    // Valida existência do número da OP antes de prosseguir
    while SC2->( DBSeek( FWxFilial( 'SC2' ) + cOP ) )
        cOP := GetSXENum( 'SC2', 'C2_NUM', ,1 )
        ConfirmSX8()
    end

    aAdd( aOrdPrd, { "C2_FILIAL" , FWxFilial( "SC2" ), Nil } )
    aAdd( aOrdPrd, { "C2_NUM"    , cOP, Nil } )
    aAdd( aOrdPrd, { "C2_PRODUTO", iif( lMVC, oOP:GetValue( _cAliCb +'_PROD' ), &( _cAliCb +'->'+ _cAliCb +'_PROD' ) ), Nil } )
    aAdd( aOrdPrd, { "C2_ITEM"   , "01", Nil } )
    aAdd( aOrdPrd, { "C2_SEQUEN" , "001", Nil } )
    aAdd( aOrdPrd, { "C2_QUANT"  , iif( lMVC, oOP:GetValue( _cAliCb +'_QTDE' ), &( _cAliCb +'->'+ _cAliCb +'_QTDE' ) ), Nil } )
    aAdd( aOrdPrd, { "C2_DATPRI" , dDataBase, Nil } )
    aAdd( aOrdPrd, { "C2_DATPRF" , dDataBase, Nil } )
    aAdd( aOrdPrd, { "C2_OBS"    , "PROCESSO: "+ iif( lMVC, oOP:GetValue( _cAliCb +'_ID' ), &( _cAliCb +'->'+ _cAliCb +'_ID' ) ), Nil  } )
    aAdd( aOrdPrd, { "C2_EMISSAO", iif( lMVC, oOP:GetValue( _cAliCb +'_DATA' ), &( _cAliCb +'->'+ _cAliCb +'_DATA' ) ), Nil } )
    aAdd( aOrdPrd, { "C2_TPOP"   , 'F' /*F=Firme ou P=Prevista*/, Nil } )
    aAdd( aOrdPrd, { "C2_STATUS" , 'N' /*N=Normal ou U=Suspensa ou S=Sacramentada*/, Nil } )
    aAdd( aOrdPrd, { "C2_X_PROGR", iif( lMVC, oOP:GetValue( _cAliCb +'_CDPLAN' ), &( _cAliCb +'->'+ _cAliCb +'_CDPLAN' ) ), Nil } )
    aAdd( aOrdPrd, { "C2_X_IDAPO", iif( lMVC, oOP:GetValue( _cAliCb +'_ID' ), &( _cAliCb +'->'+ _cAliCb +'_ID' ) ), Nil } )
    aAdd( aOrdPrd, {"AUTEXPLODE" , "S" , NIL} )
    
    SC2->( DbSetOrder( 1 ) )

return aOrdPrd

/*/{Protheus.doc} checkPasswd
Função para obtenção e checagem da senha informada pelo usuário no processo de autorização do processo de apontamento
@type function
@version 12.1.2410
@author JS Soluções Tecnológicas
@since 2/1/2025
@return logical, lSuccess
/*/
static function checkPasswd()
    
    local lSuccess := .F. as logical
    local oDlgPass as object
    local cPassUsr := Space(200)
    local bOk      := {|| lSuccess := AllTrim( cPassUsr ) == AllTrim( cPasswd ), iif( lSuccess, oDlgPass:End(),; 
                        U_HLP( 'PASSWORD', 'Senha incorreta', 'A senha informada não condiz com a senha configurada para aprovação na rotina' ) ) }
    local bCancel  := {|| lSuccess := .F., oDlgPass:End() }
    local bValid   := {|| .T. }
    local bInit    := {|| EnchoiceBar( oDlgPass, bOk, bCancel,, {} ) }
    local oPassUsr as object

    oDlgPass := TDialog():New( 0, 0, 200, 400,'Checagem com Senha',,,,,CLR_BLACK,CLR_WHITE,,,.T.)
    oPassUsr := TGet():New( 40, 10,{|u| if( PCount()>0,cPassUsr:=u,cPassUsr ) },oDlgPass,150,012,"@*",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'cPassUsr',,,,.F.,.T.,,'Senha de validação', 1 )
    oPassUsr:lPassword := .T.
    oDlgPass:Activate( ,,,.T., bValid,,bInit )
    
return lSuccess

/*/{Protheus.doc} prodAnt
Função para retornar a quantidade já produzida do produto considerando o código do planejamento vinculado às OPs
@type function
@version 12.1.2410
@author JS Soluções Tecnológicas
@since 1/31/2025
@param cCodPlan, character, ID do Planejamento
@param cProduct, character, ID do Produto
@return numeric, nProduced
/*/
static function prodAnt( cCodPlan, cProduct )
    
    local aArea     := getArea()
    local nProduced := 0  as numeric
    
    DBSelectArea( 'SC2' )
    SC2->( DBOrderNickName( 'CODPROG' ) )
    if SC2->( DBSeek( FWxFilial( 'SC2' ) + cProduct + PADR( cCodPlan, TAMSX3( 'C2_X_PROGR' )[1], ' ' ) ) )
        nProduced := 0
        while ! SC2->( EOF() ) .and. SC2->C2_FILIAL + SC2->C2_PRODUTO + SC2->C2_X_PROGR == FWxFilial( 'SC2' ) + cProduct + PADR( cCodPlan, TAMSX3( 'C2_X_PROGR' )[1], ' ' )
            nProduced += SC2->C2_QUJE
            SC2->( DBSkip() )
        end
    endif

    restArea( aArea )
return nProduced

/*/{Protheus.doc} linePre
Função para validação pré-edição da linha
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 13/02/2024
@return logical, lSuccess
/*/
static function linePre( oGrid, nLine, cAction )
    
    local lSuccess := .T. as logical
    local oModel   := FWModelActive()
    local oMaster  := oModel:GetModel( _cAliCb +'MASTER' )
    
    if cAction == 'DELETE'
        oMaster:SetValue( _cAliCb +'_QTDE', oMaster:GetValue( _cAliCb + '_QTDE' ) -= oGrid:GetValue( _cAliIt + '_QTDE' ) )
    elseif cAction == 'UNDELETE'
        oMaster:SetValue( _cAliCb +'_QTDE', oMaster:GetValue( _cAliCb + '_QTDE' ) += oGrid:GetValue( _cAliIt + '_QTDE' ) )
    endif

return lSuccess

/*/{Protheus.doc} viewDef
Função responsável pela definição do modelo de visualização padrão da rotina
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 21/01/2024
@return object, oView
/*/
static function viewDef()

    local oView as object
    local oStruCab  := FWFormStruct( 2, _cAliCb )
    local oStruIte  := FWFormStruct( 2, _cAliIt )
    local oModel    := FWLoadModel( 'AFOPAUTO' )
    local cViewCab  := 'VIEW' + _cAliCb
    local cMaster   := _cAliCb + 'MASTER'
    local cDetail   := _cAliIt + 'DETAIL'
    local cViewDet  := 'VIEW' + _cAliIt
    local cViewPeso := 'VIEWPESO'
    local bTimer    := {|| iif( oModel:isActive(), Eval( {|| nPeso := getPeso( nPeso ), oPeso:CtrlRefresh(), runChange( .F. /* lHelp */ ) } ), Nil )}
    
    oView := FWFormView():New()
    oView:SetModel( oModel )

    oView:AddField( cViewCab, oStruCab, cMaster )
    oView:AddGrid( cViewDet, oStruIte, cDetail )
    oView:AddOtherObject( cViewPeso, {| oPanel | createPanel( oPanel ) } )

    oView:CreateHorizontalBox( 'CABEC', 40 )
    oView:CreateHorizontalBox( 'GRID', 60 )
    oView:CreateVerticalBox( 'REGISTROS', 80, 'GRID' )
    oView:CreateVerticalBox( 'PESO', 20, 'GRID' )

    oView:SetOwnerView( cViewCab, 'CABEC' )
    oView:SetOwnerView( cViewDet, 'REGISTROS' )
    oView:SetOwnerView( cViewPeso, 'PESO' )

    oView:EnableTitleView( cViewCab, 'Registro de Produção' )
    oView:EnableTitleView( cViewDet, 'Pesos Coletados' )
    oView:EnableTitleVIew( cViewPeso, 'Balança' )

    // Timer da view para capturar peso da balança
    oView:SetTimer( nTimer, bTimer )
    
    // Seta um atalho para a tecla F7 do teclado
    SetKey( VK_F7, bSetF7 )

    // Seta o campo da sequencia de apontamentos como auto-incremento
    oView:AddIncrementField( cViewDet, _cAliIt + '_SEQ' )

    // Popula as variáveis INCLUI e ALTERA utilizadas nas configurações dos campos do dicionário de dados
    INCLUI := oModel:GetOperation() == MODEL_OPERATION_INSERT
    ALTERA := oModel:GetOperation() == MODEL_OPERATION_UPDATE

return oView

/*/{Protheus.doc} putPeso
Função para gravar o peso na linha de apontaentos da OP
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 31/01/2024
@return logical, lSuccess
/*/
static function putPeso()
    
    local aArea     := getArea()
    local cMaster   := _cAliCb + 'MASTER'
    local cDetail   := _cAliIt + 'DETAIL'
    local cViewDet  := 'VIEW' + _cAliIt
    local oModel    := FWModelActive()
    local oView     := FWViewActive()
    local oAponta   := oModel:GetModel( cDetail )
    local oOP       := oModel:GetModel( cMaster )
    local lNewLine  := .F. as logical
    local nX        := 0   as numeric
    local nNew      := 0   as numeric
    local lEnd      := .F. as logical
    local lSuccess  := .F. as logical
    local nQtdTot   := 0   as numeric
    local nQuantPar := 0   as numeric
    local nPesoPar  := 0   as numeric
    local cVolume   := ""  as character

    if oModel:GetOperation() == MODEL_OPERATION_INSERT

        // Verifica se o código do operador está preenchido e se o peso já foi lido
        if nPeso > 0
            
            // Define os operadores que participaram da produção
            aOper := defineOper( aOper )

            // Checa se foi pressionado Ok na tela de operadores e se algum operador foi selecionado    
            if len( aOper ) > 0

                DBSelectArea( 'SB1' )
                SB1->( DBSetOrder( 1 ) )
                if SB1->( DBSeek( FWxFilial( 'SB1' ) + oOP:GetValue( _cAliCb + '_PROD' ) ) )

                    if SB1->B1_UM == 'KG' .or. ( SB1->B1_SEGUM == 'KG' .and. SB1->B1_CONV != 0 .and. ! Empty( SB1->B1_TIPCONV ) )
                        lEnd := .F.
                    else
                        U_HLP( 'SEG.UN.MED',;
                                'As configurações para conversão de unidades de medida não foram realizadas',;
                                'Verifique as configurações do produto e tente novamente!' )
                        lEnd := .T.
                    endif

                    if ! lEnd

                        oAponta:GoLine(1)
                        cVolume := StrZero(0,3)
                        for nX := 1 to oAponta:Length()
                            oAponta:GoLine( nX )
                            cVolume := iif( oAponta:GetValue( _cAliIt +'_VOLUME' ) > cVolume,;
                                            oAponta:GetValue( _cAliIt +'_VOLUME' ),;
                                            cVolume )
                        next nX
                        cVolume := Soma1( cVolume )

                        oAponta:SetNoInsertLine( .F. )
                        oAponta:SetNoUpdateLine( .F. )

                        for nX := 1 to len( aOper )
                            // Verifica se deve criar uma nova linha no grid
                            oAponta:GoLine( 1 )
                            lNewLine := oAponta:Length() > 1 .or. oAponta:GetValue( _cAliIt +'_QTDE' ) > 0

                            // Verifica se é nova linha ou se a primeira linha do grid ainda está vazia
                            if lNewLine .or. ( oAponta:Length() == 1 .and. oAponta:GetValue( _cAliIt +'_QTDE' ) == 0 )
                                // Cria nova linha apenas quando a primeira linha já estiver preenchida
                                if oAponta:Length() > 1 .or. oAponta:GetValue( _cAliIt +'_QTDE' ) > 0
                                    nNew := oAponta:AddLine()
                                else
                                    nNew := 1
                                endif
                                oAponta:GoLine( nNew )
                                oAponta:SetValue( _cAliIt + '_ID'    , oOP:GetValue( _cAliCb +'_ID' ) )
                                oAponta:SetValue( _cAliIt + '_OPERA' , aOper[nX][2] )
                                oAponta:SetValue( _cAliIt + '_NOPERA', AllTrim( aOper[nX][3] ) )
                                oAponta:SetValue( _cAliIt + '_PESO'  , iif( nX == len(aOper), nPeso - nPesoPar, Round( nPeso / len( aOper ), 3 ) ) )
                                oAponta:SetValue( _cAliIt + '_QTDE'  , iif( nX == len(aOper), nQuant - nQuantPar, Round( nQuant / len( aOper ), 0 ) ) ) 
                                nQuantPar += Round( nQuant / len( aOper ), 0 )
                                nPesoPar += Round( nPeso / len( aOper ), 3 )
                                oAponta:SetValue( _cAliIt + '_VOLUME', cVolume )
                                lSuccess := .T.

                            endif
                        next nX

                        oAponta:SetNoInsertLine( .T. )
                        oAponta:SetNoUpdateLine( .T. )
                    endif

                endif

            else
                lSuccess := .F.
                U_HLP( 'OPERADOR(ES)',;
                        'Não foram definidos operadores para a produção do volume que está sendo lançado',;
                        'É necessário informar ao menos um operador para que o lançamento possa ser efetivado' )
            endif

        endif

    endif

    if lSuccess
        nPeso  := 0
        nQuant := 0
        aOper  := {}
        oPeso:CtrlRefresh()
        oQuant:CtrlRefresh()
        
        // Seta o foco no campo mais adequado para dar mais performance no processo de apontamento
        if _lBalOn
            oBtnAdd:SetFocus()
        else
            oPeso:SetFocus()
        endif

        nQtdTot := 0
        for nX := 1 to oAponta:Length()
            oAponta:GoLine( nX )
            if ! oAponta:IsDeleted()
                nQtdTot += oAponta:GetValue( _cAliIt +'_QTDE' )
            endif
        next nX

        // Seta o campo da quantidade total no cabeçalho conforme quantidade apontada por operador no grid
        oOP:SetValue( _cAliCb +'_QTDE', nQtdTot )

        oAponta:GoLine(1)       // Volta para a primeira linha para melhorar visualização do grid para o usuário
        oView:Refresh( cViewDet )
    endif
    
    // Restaura posicionamento dos dados
    restArea( aArea )
return lSuccess

/*/{Protheus.doc} createPanel
Função responsável pela criação da tela de apontamento de produção
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 21/01/2024
@param oPanel, object, objeto do panel
@return object, oPanel
/*/
static function createPanel( oPanel )

    local oModel     := FWModelActive()
    local oOP        := oModel:GetModel( _cAliCb + 'MASTER' )
    local oBtnFat    as object
    local oBtnCfg    as object
    local bFatConv   :={|| openProd( oOP:GetValue( _cAliCb + '_PROD' ) ) }
    local bBtnCfg    :={|| U_AFOPPARM(), _lBalOn := checkBal(), oRadPeso:EnableItem( 2, _lBalOn ) }
    local aRadPeso   :={"Lançam. Manual", "Automatico"}
    local oRadPeso   as object

    // Campo onde o peso da balança será exibido e/ou informado
    oPeso  := TGet():New( 020, 030, { | u | If( PCount() == 0, nPeso, nPeso := u ) },oPanel, ;
            060, 012, "@E 9,999.9999",, 0, 16777215,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"nPeso",,,, .T./* lHasButton */,;
            .F. /* lNoButton */,, 'Peso da Balança', 1,,CLR_BLUE,,.T. /* lPicturePriority */, .T. /* lFocSel */ )
    oPeso:bChange := {|| runChange(), oQuant:SetFocus(), oBtnAdd:SetFocus() }
    oPeso:bWhen := {|| oModel:GetOperation() == MODEL_OPERATION_INSERT .and. nRadPeso == 1 }

    oBtnCfg := TButton():New( 027, 094, "Parâmetros",oPanel, bBtnCfg ,30,12,,,.F.,.T.,.F.,,.F.,,,.F. )
    oBtnCfg:bWhen := {|| oModel:GetOperation() == MODEL_OPERATION_INSERT .and. GetRemoteType() == 1 }
    oBtnCfg:bChange := {|| _lBalOn := checkBal() }

    oRadPeso := TRadMenu():New( 050, 030, aRadPeso,,oPanel,,,,,,,,100,12,,,,.T.)
    oRadPeso:bSetGet := {|u| if( PCount()>0, nRadPeso := u, nRadPeso ) }
    oRadPeso:EnableItem( 2, _lBalOn )
    oRadPeso:lHoriz := .T.
    oRadPeso:bChange := {|| oPeso:SetFocus(), oRadPeso:SetFocus() }

    oQuant := TGet():New( 070, 030, { | u | If( PCount() == 0, nQuant, nQuant := u ) },oPanel, ;
            060, 012, PesqPict('SH6', 'H6_QTDPROD' ),, 0, 16777215,,.F.,,.T.,,.F.,{|| .F. },.F.,.F.,,.F.,.F. ,,"nQuant",,,, .T./* lHasButton */,;
            .F. /* lNoButton */,, 'Quantidade Produzida (Fator Conv.)',;
            1,,CLR_BLUE,,.T. /* lPicturePriority */, .T. /* lFocSel */ )
    
    oBtnFat := TButton():New( 077, 094, "Produto",oPanel, bFatConv ,30,12,,,.F.,.T.,.F.,,.F.,,,.F. )
    oBtnFat:bWhen := {|| oOP:GetValue( _cAliCb + '_QTDE' ) == 0 }

    // Botão para capturar peso
    oBtnAdd := TButton():New( 116, 030, "Registrar (F7)",oPanel, bSetF7 ,94,24,,,.F.,.T.,.F.,,.F.,,,.F. )
    oBtnAdd:bWhen := {|| oModel:GetOperation() == MODEL_OPERATION_INSERT }

return oPanel

/*/{Protheus.doc} defineOper
Função para que o usuário possa definir os operadores que fazem parte do processo de produção do item que acabou de ser pesado
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 26/04/2024
@param aOper, array, vetor com os operadores
@return array, aOper
/*/
static function defineOper( aOper )

    local oDlgOper       as object
    local aButtons  := {} as array
    local bOk       := {|| aOper := getSel(aNewOper), oDlgOper:End() }
    local bCancel   := {|| oDlgOper:End() }
    local bValid    := {|| .T. }
    Local bInit     := {|| EnchoiceBar( oDlgOper, bOk, bCancel,, aButtons )}
    local lSelected := .F. as logical
    local nPos      := 0 as numeric
    local bMark     := {|| iif( aNewOper[ oBrw:At() ][1], 'LBOK', 'LBNO' ) }
    local bDblClick := {|| aNewOper[ oBrw:At() ][1] := ! aNewOper[ oBrw:At() ][1], oBrw:LineRefresh() }
    local aColumns  := {} as array

    Private aNewOper := {}
    Private oBrw           as object

    // Percorre tabela de operadores para formatar um vetor para apresentação no browse para o usuário
    aNewOper := {} 
    DBSelectArea( 'CB1' )
    CB1->( DBSetOrder( 1 ) )
    if CB1->( DBSeek( FWxFilial( 'CB1' ) ) )
        while ! CB1->( EOF() ) .and. CB1->CB1_FILIAL == FWxFilial( 'CB1' )
            nPos      := 0
            lSelected := .F.
            if len( aOper ) > 0
                nPos := aScan( aOper, {|x| x[2] == CB1->CB1_CODOPE } )
                if nPos > 0
                    lSelected := aOper[nPos][1]
                endif 
            endif
            aAdd( aNewOper, { lSelected,;
                             CB1->CB1_CODOPE,; 
                             CB1->CB1_NOME } )
            CB1->( DBSkip() )
        end
        // Ordena o vetor pelo nome dos operadores
        aSort( aNewOper,,,{|x,y| x[3] > y[3]} )
    endif

    // Codigo do operador
    aAdd( aColumns, FWBrwColumn():New() )
    aColumns[len(aColumns)]:SetTitle( 'Código' )
    aColumns[len(aColumns)]:SetType( 'C' )
    aColumns[len(aColumns)]:SetSize( TAMSX3( 'CB1_CODOPE' )[1] )
    aColumns[len(aColumns)]:SetPicture( GetSX3Cache( 'CB1_CODOPE', 'X3_PICTURE' ) )
    aColumns[len(aColumns)]:SetData({|| aNewOper[ oBrw:At() ][2] })

    // Nome do operador
    aAdd( aColumns, FWBrwColumn():New() )
    aColumns[len(aColumns)]:SetTitle( 'Nome' )
    aColumns[len(aColumns)]:SetType( 'C' )
    aColumns[len(aColumns)]:SetSize( TAMSX3( 'CB1_NOME' )[1] )
    aColumns[len(aColumns)]:SetPicture( GetSX3Cache( 'CB1_NOME', 'X3_PICTURE' ) )
    aColumns[len(aColumns)]:SetData({|| aNewOper[ oBrw:At() ][3] })

    // Monta o dialog para exibir os operadores cadastrados no sistema par ao operador selecionar
    oDlgOper := TDialog():New( 0,0,700,500,'Operadores Relacionados',,,,,CLR_BLACK,CLR_WHITE,,,.T.)
    oBrw := FWBrowse():New( oDlgOper )
    oBrw:SetDataArray()
    oBrw:SetArray( aNewOper )
    oBrw:AddMarkColumns( bMark, bDblClick, {|| Nil } )
    oBrw:SetColumns( aColumns )
    oBrw:DisableReport()
    oBrw:Activate()
    oDlgOper:Activate(,,,.T., bValid,,bInit)

return aOper

/*/{Protheus.doc} getSel
Obtem os registros selecionados no browse
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 26/04/2024
@param aBrowse, array, vetor com os operadores
@return array, aSelected
/*/
static function getSel( aBrowse )
    local aSelected := {} as array
    aEval( aBrowse, {|x| iif( x[1], aAdd( aSelected, aClone(x) ), Nil ) } )
return aSelected

/*/{Protheus.doc} openProd
Função para chamar edição do produto com a finalidade de edição do fator de conversão
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 15/02/2024
@param cProduto, character, Codigo do Produto   
/*/
static function openProd( cProduto )

    local aArea := getArea()
    local oModel := FWModelActive()
    local oView  := FWViewActive()
    local oOP    := oModel:GetModel( _cAliCb + 'MASTER' )

    DBSelectArea( 'SB1' )
    SB1->( DBSetOrder( 1 ) )
    if SB1->( DBSeek( FWxFilial( 'SB1' ) + cProduto ) )
        if ( FWExecView( 'Manutenção do Produto', 'MATA010', MODEL_OPERATION_UPDATE, Nil, {|| .T. } /* bCloseOnOk */,;
                                {|| .T. } /* bAllOk */, 20 /* nPercRed */ ) ) == 0
            oOP:SetValue( _cAliCb +'_DESCRI', RetField( 'SB1', 1, FWxFilial( 'SB1' ) + cProduto, 'B1_DESC' ) )
            oOP:SetValue( _cAliCb +'_UM', RetField( 'SB1', 1, FWxFilial( 'SB1' ) + cProduto, 'B1_UM' ) )
            oView:Refresh( 'VIEW' + _cAliCb )
            runChange()
        endif
        
    endif
    restArea( aArea )

return Nil

/*/{Protheus.doc} runChange
Função executada quando ocorrer alteração no objeto que obtem o peso do produto produzido
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 03/02/2024
@param lHelp, logical, indica se deve exibir help para usuário explicando falhas no momento da conversão
@return logical, lSuccess
/*/
static function runChange( lHelp )

    local lSuccess := .T. as logical
    local cMaster  := _cAliCb + 'MASTER'
    local oModel   := FWModelActive()
    local oView    := FWViewActive()
    local oOP      := oModel:GetModel( cMaster )
    local cProduto := "" as character

    default lHelp := .T.
    
    if ! oModel:isActive()
        return lSuccess
    endif

    if ! oOp:GetValue( _cAliCb +'_PROD' ) == SB1->B1_COD
        DBSelectArea( 'SB1' )
        SB1->( DBSetOrder( 1 ) )
        if ! SB1->( DBSeek( FWxFilial( 'SB1' ) + oOp:GetValue( _cAliCb +'_PROD' ) ) )
            lSuccess := .F.
        endif
    endif

    if lSuccess
        if SB1->B1_UM == 'KG'
            nFatConv := 1
            cFatConv := 'M'
        elseif SB1->B1_SEGUM == 'KG' .and. SB1->B1_CONV != 0 .and. ! Empty( SB1->B1_TIPCONV )
            nFatConv := SB1->B1_CONV
            cFatConv := SB1->B1_TIPCONV
        else
            lSuccess := .F.
        endif
        if ! lSuccess .and. lHelp
            if MsgYesNo( 'Fator de conversão não configurado para o produto <b>'+ AllTrim( oOP:GetValue( _cAliCb +'_DESCRI' ) ) +'</b>! '+;
                                "Para apontamento utilizando o peso como unidade de medida, é necessário que a primeira ou a segunda unid. de medida seja KG,"+;
                                " e se KG for a segunda, o fator de conversão necessariamente deve estar configurado, gostaria de fazer isso agora?", "A T E N Ç Ã O !"  )
                if FWExecView( 'Manutenção do Produto', 'MATA010', MODEL_OPERATION_UPDATE, Nil, {|| .T. } /* bCloseOnOk */,;
                                {|| .T. } /* bAllOk */, 20 /* nPercRed */ ) == 0
                    
                    // Atualiza dados do produto, caso o usuário tenha realizado algum tipo de alteração
                    cProduto := oOP:GetValue( _cAliCb +'_PROD' )
                    oOP:SetValue( _cAliCb +'_DESCRI', RetField( 'SB1', 1, FWxFilial( 'SB1' ) + cProduto, 'B1_DESC' ) )
                    oOP:SetValue( _cAliCb +'_UM', RetField( 'SB1', 1, FWxFilial( 'SB1' ) + cProduto, 'B1_UM' ) )
                    oView:Refresh( 'VIEW'+ _cAliCb )

                    if SB1->B1_UM == 'KG'
                        nFatConv := 1
                        cFatConv := 'D'
                        lSuccess := .T.
                    elseif SB1->B1_SEGUM == 'KG' .and. SB1->B1_CONV != 0 .and. ! Empty( SB1->B1_TIPCONV )
                        nFatConv := SB1->B1_CONV
                        cFatConv := SB1->B1_TIPCONV
                        lSuccess := .T.
                    else
                        U_HLP( 'SEG.UN.MED',;
                                'As configurações para conversão de unidades de medida não foram realizadas',;
                                'Verifique as configurações do produto e tente novamente!' ) 
                    endif
                endif
            endif
        endif
    endif

    if lSuccess
        nQuant := Round( iif( cFatConv == 'D', nPeso * nFatConv, nPeso / nFatConv  ), 0 /* TAMSX3('H6_QTDPROD')[2] */ )
        oQuant:CtrlRefresh()
    endif
        
return lSuccess

/*/{Protheus.doc} getPeso
Função que monitora o conteúdo enviado pela balança para identificar alterações de peso
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 30/01/2024
@param nPesoAtu, numeric, peso atual exibido em tela
@return numeric, nPeso
/*/
static function getPeso( nPesoAtu )
    
    local nPeso   := 0 as numeric
    local cBuffer := "" as character
    local nX      := 0 as numeric
    local nHandle := 0 as numeric
    local lOn     := .F. as logical
    local oModel  := FWModelActive()

    if oModel:IsActive()
        if oModel:GetOperation() == MODEL_OPERATION_INSERT .and. nRadPeso == 2
            lOn := MSOpenPort( @nHandle, cConfig )
            if lOn
                for nX := 1 to 50
                    cBuffer := ""  
                    MsRead( nHandle, @cBuffer )
                    if "E" $ cBuffer .and. At( 'kg', Lower(cBuffer) ) > At( 'n0', Lower(cBuffer) ) .and. At( 'n0', Lower(cBuffer) ) > 0
                        nPeso := Val( SubStr( StrTran(AllTrim(cBuffer),',','.'), At( 'n0', Lower(cBuffer) )+2, At( 'kg', Lower(cBuffer) ) - At( 'n0', Lower(cBuffer) )+2 ) )
                        // MsgInfo( cBuffer + chr(13)+chr(10) +;
                        //          'n0: '+ cValToChar(At( 'n0', Lower(cBuffer) )) + chr(13)+chr(10) +;
                        //          'Kg: '+ cValToChar(At( 'kg', Lower(cBuffer) )), 'Retorno da Balança' )
                    else
                        nPeso := 0
                    endif
                    if nPeso > 0
                        Exit
                    endif
                    if ! oModel:isActive()
                        Exit
                    endif
                next nX
                MsClosePort( nHandle, cConfig )
            endif
        else
            nPeso := nPesoAtu
        endif
    endif
return nPeso

/*/{Protheus.doc} checkBal
Função de checagem dos dados de conexão com a balança
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 26/01/2024
@return logical, lBalOn
/*/
static function checkBal()
    
    local lOn     := .F. as logical
    local nHandle := 0 as numeric
   
    cConfig  := cPorta +':'+cVelocid +','+cParidad+','+cBits+','+cStopBit

    // Executa tentativa de abertura da comunicação com a balança
    lOn := MSOpenPort( @nHandle, cConfig )
    if ! lOn
        U_HLP( 'BALANÇA OFFLINE',;
                'Não foi possível obter conectividade com a balança utilizando as configurações definidas. O modo de lançamento manual foi ativado!',;
                'Verifique os dados configurados e ajuste para prosseguir - Porta: '+ cPorta +', Velocidade: '+ cVelocid +', Paridade: '+ cParidad +', Bits: '+ cBits +', Bit Final: '+ cStopBit )
    else
        MsClosePort( nHandle, cConfig )
    endif

return lOn

/*/{Protheus.doc} defineParms
Função para definição dos parâmetros para comunicação com o equipamento da balança
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 26/01/2024
@return logical, lDefined
/*/
user function AFOPPARM()
    
    local lDefined := .F. as logical
    local aParms   := {} as array
    local aButtons := {} as array
    local aUSB     := {'COM1','COM2','COM3','COM4','COM5','COM6', 'COM7', 'COM8', 'COM9'}
    local aReturn  := {} as array
    local bOk      := {|| .T. }
    
    aAdd( aParms, { 2, "Porta USB: " , cPorta, aUSB, 50,,.T. /* lObrigat */ } )              // ComboBox Porta USB
    aAdd( aParms, { 1, "Velocidade: ", cVelocid, "@!",,,,40,.T. /* lObrigat */ } )                                       // Get Velocidade
    aAdd( aParms, { 2, "Paridade: "  , iif( cParidad == 's', 'Sim', 'Não'), { "Sim", "Não" }, 30,,.T. /* lObrigat */ } )
    aAdd( aParms, { 1, "Bits: "      , cBits, "@!",,,,30, .T. /* lObrigat */ } )
    aAdd( aParms, { 1, "Bit Final: " , cStopBit, "@!",,,,30, .T. /* lObrigat */ } )
    aAdd( aParms, { 1, "Fluxo: "     , PADR(AllTrim(cFluxo),50,' ' ), "@!",,,,80, .F. /* lObrigat */ } )
    aAdd( aParms, { 1, "Timer: "     , nTimer, "999",,,,40, .T. } )
    // aAdd( aParms, { 1, "Imp.Etiqueta: ", PADR(AllTrim(cPrinter),TAMSX3('CB5_CODIGO')[1], ' ' ), "@!",,"CB5",,40, .T. /* lObrigat */ } )
    aAdd( aParms, { 1, "Senha Aprov.: ", PADR(AllTrim(cPasswd),100, ' ' ), iif(FWisAdmin(),"@*","@x"),,,"FWisAdmin()",80, .F. /* lObrigat */ } )

    // Chama tela de exibição de parâmetros para usuário configurar
    if ParamBox( aParms, "Conexão com Balança", @aReturn, bOk, aButtons,,,,,,.F. /* lCanSave */,.F. /* lUserSave */)
        
        cPorta   := aReturn[1]
        cVelocid := aReturn[2]
        cParidad := aReturn[3]
        cBits    := aReturn[4]
        cStopBit := aReturn[5]
        cFluxo   := aReturn[6]
        nTimer   := aReturn[7]
        // cPrinter := aReturn[8]
        cPasswd  := aReturn[8]

        if GetMv( 'MV_X_PRD03', .T. )
            PutMv( 'MV_X_PRD03', cPorta )
        else
            RecLock( 'SX6', .T. )
            ( 'SX6' )->X6_VAR := 'MV_X_PRD03'
            ( 'SX6' )->X6_TIPO := 'C'
            ( 'SX6' )->X6_DESCRIC := "Porta USB para conexão com Balanca"
            ( 'SX6' )->X6_DSCSPA  := "Porta USB para conexão com Balanca"
            ( 'SX6' )->X6_DSCENG  := "Porta USB para conexão com Balanca"
            ( 'SX6' )->X6_CONTEUD := cPorta
            ( 'SX6' )->X6_CONTSPA := cPorta
            ( 'SX6' )->X6_CONTENG := cPorta
            ( 'SX6' )->X6_PROPRI  := 'S'
            ( 'SX6' )->( MsUnlock() )
        endif

        if GetMv( 'MV_X_PRD04', .T. )
            PutMv( 'MV_X_PRD04', cVelocid )
        else
            RecLock( 'SX6', .T. )
            ( 'SX6' )->X6_VAR := 'MV_X_PRD04'
            ( 'SX6' )->X6_TIPO := 'C'
            ( 'SX6' )->X6_DESCRIC := "Velocidade de conexão com Balanca"
            ( 'SX6' )->X6_DSCSPA  := "Velocidade de conexão com Balanca"
            ( 'SX6' )->X6_DSCENG  := "Velocidade de conexão com Balanca"
            ( 'SX6' )->X6_CONTEUD := cVelocid
            ( 'SX6' )->X6_CONTSPA := cVelocid
            ( 'SX6' )->X6_CONTENG := cVelocid
            ( 'SX6' )->X6_PROPRI  := 'S'
            ( 'SX6' )->( MsUnlock() )
        endif

        if GetMv( 'MV_X_PRD05', .T. )
            PutMv( 'MV_X_PRD05', iif( cParidad == 'Sim', 's', 'n' ) )
        else
            RecLock( 'SX6', .T. )
            ( 'SX6' )->X6_VAR := 'MV_X_PRD05'
            ( 'SX6' )->X6_TIPO := 'C'
            ( 'SX6' )->X6_DESCRIC := "Utiliza paridade na conexão com Balanca"
            ( 'SX6' )->X6_DSCSPA  := "Utiliza paridade na conexão com Balanca"
            ( 'SX6' )->X6_DSCENG  := "Utiliza paridade na conexão com Balanca"
            ( 'SX6' )->X6_CONTEUD := iif( cParidad == 'Sim', 's', 'n' )
            ( 'SX6' )->X6_CONTSPA := iif( cParidad == 'Sim', 's', 'n' )
            ( 'SX6' )->X6_CONTENG := iif( cParidad == 'Sim', 's', 'n' )
            ( 'SX6' )->X6_PROPRI  := 'S'
            ( 'SX6' )->( MsUnlock() )
        endif

        if GetMv( 'MV_X_PRD06', .T. )
            PutMv( 'MV_X_PRD06', cBits )
        else
            RecLock( 'SX6', .T. )
            ( 'SX6' )->X6_VAR := 'MV_X_PRD06'
            ( 'SX6' )->X6_TIPO := 'C'
            ( 'SX6' )->X6_DESCRIC := "Quantidade de bits da conexão com Balanca"
            ( 'SX6' )->X6_DSCSPA  := "Quantidade de bits da conexão com Balanca"
            ( 'SX6' )->X6_DSCENG  := "Quantidade de bits da conexão com Balanca"
            ( 'SX6' )->X6_CONTEUD := cBits
            ( 'SX6' )->X6_CONTSPA := cBits
            ( 'SX6' )->X6_CONTENG := cBits
            ( 'SX6' )->X6_PROPRI  := 'S'
            ( 'SX6' )->( MsUnlock() )
        endif

        if GetMv( 'MV_X_PRD07', .T. )
            PutMv( 'MV_X_PRD07', cStopBit )
        else
            RecLock( 'SX6', .T. )
            ( 'SX6' )->X6_VAR := 'MV_X_PRD07'
            ( 'SX6' )->X6_TIPO := 'C'
            ( 'SX6' )->X6_DESCRIC := "Bit final do buffer da conexão com Balanca"
            ( 'SX6' )->X6_DSCSPA  := "Bit final do buffer da conexão com Balanca"
            ( 'SX6' )->X6_DSCENG  := "Bit final do buffer da conexão com Balanca"
            ( 'SX6' )->X6_CONTEUD := cStopBit
            ( 'SX6' )->X6_CONTSPA := cStopBit
            ( 'SX6' )->X6_CONTENG := cStopBit
            ( 'SX6' )->X6_PROPRI  := 'S'
            ( 'SX6' )->( MsUnlock() )
        endif

        if GetMv( 'MV_X_PRD08', .T. )
            PutMv( 'MV_X_PRD08', cFluxo )
        else
            RecLock( 'SX6', .T. )
            ( 'SX6' )->X6_VAR := 'MV_X_PRD08'
            ( 'SX6' )->X6_TIPO := 'C'
            ( 'SX6' )->X6_DESCRIC := "Fluxo da conexão com Balanca"
            ( 'SX6' )->X6_DSCSPA  := "Fluxo da conexão com Balanca"
            ( 'SX6' )->X6_DSCENG  := "Fluxo da conexão com Balanca"
            ( 'SX6' )->X6_CONTEUD := cFluxo
            ( 'SX6' )->X6_CONTSPA := cFluxo
            ( 'SX6' )->X6_CONTENG := cFluxo
            ( 'SX6' )->X6_PROPRI  := 'S'
            ( 'SX6' )->( MsUnlock() )
        endif

        if GetMv( 'MV_X_PRD09', .T. )
            PutMv( 'MV_X_PRD09', nTimer )
        else
            RecLock( 'SX6', .T. )
            ( 'SX6' )->X6_VAR := 'MV_X_PRD09'
            ( 'SX6' )->X6_TIPO := 'N'
            ( 'SX6' )->X6_DESCRIC := "Timer entre requisicoes da conexão com Balanca"
            ( 'SX6' )->X6_DSCSPA  := "Timer entre requisicoes da conexão com Balanca"
            ( 'SX6' )->X6_DSCENG  := "Timer entre requisicoes da conexão com Balanca"
            ( 'SX6' )->X6_CONTEUD := cValToChar( nTimer )
            ( 'SX6' )->X6_CONTSPA := cValToChar( nTimer )
            ( 'SX6' )->X6_CONTENG := cValToChar( nTimer )
            ( 'SX6' )->X6_PROPRI  := 'S'
            ( 'SX6' )->( MsUnlock() )
        endif
        
        // if GetMv( 'MV_X_PRD10', .T. )
        //     PutMv( 'MV_X_PRD10', cPrinter )
        // else
        //     RecLock( 'SX6', .T. )
        //     ( 'SX6' )->X6_FIL     := FWxFilial(  "CB5" )
        //     ( 'SX6' )->X6_VAR     := 'MV_X_PRD10'
        //     ( 'SX6' )->X6_TIPO    := 'C'
        //     ( 'SX6' )->X6_DESCRIC := "Codigo do cadastro da impressora de etiqueta"
        //     ( 'SX6' )->X6_DSCSPA  := "Codigo do cadastro da impressora de etiqueta"
        //     ( 'SX6' )->X6_DSCENG  := "Codigo do cadastro da impressora de etiqueta"
        //     ( 'SX6' )->X6_CONTEUD := cPrinter
        //     ( 'SX6' )->X6_CONTSPA := cPrinter
        //     ( 'SX6' )->X6_CONTENG := cPrinter
        //     ( 'SX6' )->X6_PROPRI  := 'S'
        //     ( 'SX6' )->( MsUnlock() )
        // endif

        if GetMv( 'MV_X_PRD11', .T. )
            PutMv( 'MV_X_PRD11', cPasswd )
        else
            RecLock( 'SX6', .T. )
            ( 'SX6' )->X6_VAR     := 'MV_X_PRD11'
            ( 'SX6' )->X6_TIPO    := 'C'
            ( 'SX6' )->X6_DESCRIC := "Senha de aprovação do apontamento de OP"
            ( 'SX6' )->X6_DSCSPA  := "Senha de aprovação do apontamento de OP"
            ( 'SX6' )->X6_DSCENG  := "Senha de aprovação do apontamento de OP"
            ( 'SX6' )->X6_CONTEUD := cPasswd
            ( 'SX6' )->X6_CONTSPA := cPasswd
            ( 'SX6' )->X6_CONTENG := cPasswd
            ( 'SX6' )->X6_PROPRI  := 'S'
            ( 'SX6' )->( MsUnlock() )
        endif

        lDefined := .T.

    endif

return lDefined


/*/{Protheus.doc} checkStruct
Função para checagem da estrutura das rotinas 
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 19/01/2024
@return array, aReturn[lSuccess, aUnchecked]
/*/
static function checkStruct()
    local lSuccess := .T. as logical
    local aUnchecked := {} as array

    if Empty( _cAliCb )
        aAdd( aUnchecked, "Alias do cabeçalho da tabela de apontamentos não foi definido (MV_X_PRD01)" )
    endif
    if Empty( _cAliIt )
        aAdd( aUnchecked, "Alias dos registros de pesos do processo de apontamento não foi definido (MV_X_PRD02)" )
    endif
    // Usuário de rede
    if CB5->( FieldPos( "CB5_X_USER" ) ) == 0
        aAdd( aUnchecked, "Campo não localizado no alias CB5 (CB5_X_USER)" )
    endif
    
    // Senha de rede
    if CB5->( FieldPos( "CB5_X_PASS" ) ) == 0
        aAdd( aUnchecked, "Campo não localizado no alias CB5 (CB5_X_PASS)" )
    endif
    // Persiste login e senha a cada requisição
    if CB5->( FieldPos( "CB5_X_PERS" ) ) == 0
        aAdd( aUnchecked, "Campo não localizado no alias CB5 (CB5_X_PERS)" )
    endif
    // Nome de rede do equipamento
    if CB5->( FieldPos( "CB5_X_NWNM" ) ) == 0
        aAdd( aUnchecked, "Campo não localizado no alias CB5 (CB5_X_NWNM)" )
    endif
    lSuccess := len( aUnchecked ) == 0
return { lSuccess, aUnchecked }

/*/{Protheus.doc} SFAPOID
Função para retornar o novo ID da tabela de apontamento automático da produção
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 15/02/2024
@return character, cNewID
/*/
user function SFAPOID()
    local cNewID := GetSXENUM( _cAliCb, _cAliCb +'_ID' )
    ConfirmSX8()
    while existID( cNewID )
        cNewID := Soma1( cNewID )
    end
return cNewID

/*/{Protheus.doc} existID
Função que valida se o ID existe na tabela antes de utilizá-lo
@type function
@version 12.1.2410
@author JS Soluções
@since 3/13/2025
@param cID, character, ID a ser validado
@return logical, lExist
/*/
static function existID( cID )
    local lExist := .F. as logical
    DBSelectArea( _cAliCb )
    ( _cAliCb )->( DBSetOrder( 1 ) )
    lExist := ( _cAliCb )->( DBSeek( FWxFilial( _cAliCb ) + cID ) )
return lExist

/*/{Protheus.doc} getNextSC2
Função para retornar a próxima numeração da tabela SC2
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 15/03/2024
@return character, cNext
/*/
// static function getNextSC2()
//     local aArea  := getArea()
//     local cNext  := StrZero( 1, 6 )
//     local cQuery := "" as character

//     cQuery := "SELECT COALESCE( MAX( C2_NUM ), '"+ cNext +"') MAXNUM FROM "+ RetSqlName( 'SC2' ) +" C2 "
//     cQuery += "WHERE C2_FILIAL = '"+ FWxFilial( 'SC2' ) +"' "
//     DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), 'SC2TMP' /* cAlias */, .F. /* lShared */, .T. /* lReadOnly */ )
//     cNext := Soma1( AllTrim( SC2TMP->MAXNUM ) )
//     SC2TMP->( DBCloseArea() )

//     restArea( aArea )
// return cNext

/*/{Protheus.doc} SFSELFX
Função para identificar a faixa que o lançamento pertence
@type function
@version 12.1.2410
@author JS Soluções Tecnológicas
@since 2/1/2025
@return character, cFaixa
/*/
User Function SFSELFX()
    
    local aArea   := getArea()
    local oModel  := FWModelActive()
    local oMaster := oModel:GetModel( _cAliCb +'MASTER' )
    local nQuant  := 0 as numeric
    local cFaixa  := Space( TAMSX3( _cAliCb +'_FAIXA' )[1] )

    DBSelectArea( 'ZB9' )
    ZB9->( DBSetOrder( 2 ) )
    if ZB9->( DBSeek(  FWxFilial( 'ZB9' ) + oMaster:GetValue( _cAliCb +'_CDPLAN' ) + oMaster:GetValue( _cAliCb +'_PROD' ) ) )
        nQuant := ZB9->ZB9_QTPLA
        DBSelectArea( 'ZPE' )
        ZPE->( DBSetOrder( 1 ) )
        if ZPE->( DBSeek( FWxFilial( 'ZPE' ) ) )
            while ! ZPE->( EOF() ) .and. ZPE->ZPE_FILIAL == FWxFilial( 'ZPE' ) .and. Empty( cFaixa )
                // Verifica as faixas existentes até chegar na faixa que o planejamento se encaixa
                if nQuant >= ZPE->ZPE_QPI .and. nQuant <= ZPE->ZPE_QPF
                    cFaixa := ZPE->ZPE_FAIXA
                endif
                ZPE->( DBSkip() )
            end
        endif
    endif

    restArea( aArea )
return cFaixa

/*/{Protheus.doc} SFVLDPLN
Função valid do campo do codigo de planejamento
@type function
@version 12.1.2410
@author JS Soluções Tecnológicas
@since 2/1/2025
@return logical, lSuccess
/*/
User Function SFVLDPLN()
    
    local lSuccess := .T. as logical
    local oModel   := FWModelActive()
    local oMaster  := oModel:GetModel( _cAliCb +'MASTER' )
    
    DBSelectArea( 'ZB9' )
    ZB9->( DBSetOrder( 2 ) )
    if ! ZB9->( DBSeek(  FWxFilial( 'ZB9' ) + oMaster:GetValue( _cAliCb +'_CDPLAN' ) + oMaster:GetValue( _cAliCb +'_PROD' ) ) )
        lSuccess := .F.
        U_HLP( 'CODIGO PLANO',;
                'O produto '+ oMaster:GetValue( _cAliCb +'_PROD' ) +' não tem relação com o Código do Plano de Produção número '+ oMaster:GetValue( _cAliCb +'_CDPLAN' ),;
                'Se informar o código de planejamento, é obrigatório que o mesmo tenha relação com o produto que está sendo produzido.' )
    endif

return lSuccess

/*/{Protheus.doc} setDataApv
Função para atribuir conteúdo aos campos
@type function
@version 12.1.2410
@author JS Soluções Tecnológicas
@since 2/3/2025
@param oMaster, object, objeto do registro master
/*/
static function setDataApv( oMaster )
    
    local lSuccess := .T. as logical

    default oMaster := Nil

    if oMaster != Nil
        oMaster:SetValue( _cAliCb + '_STATUS', 'A' )
        oMaster:SetValue( _cAliCb + '_DTAPV' , Date() )
        oMaster:SetValue( _cAliCb + '_HRAPV' , Time() )
        oMaster:SetValue( _cAliCb + '_USAPV' , RetCodUsr() )
    else
        RecLock( _cAliCb, .F. )
        &( _cAliCb +'->'+ _cAliCb + '_STATUS' ) := 'A'
        &( _cAliCb +'->'+ _cAliCb + '_DTAPV'  ) := Date()
        &( _cAliCb +'->'+ _cAliCb + '_HRAPV'  ) := TIme()
        &( _cAliCb +'->'+ _cAliCb + '_USAPV'  ) := RetCodUsr()
        ( _cAliCb )->( MsUnlock() )
    endif

return lSuccess

/*/{Protheus.doc} getSC2
Retorna ID da OP gerada com base  no ID do apontamento  
@type function
@version 12.1.2410
@author JS Soluções Tecnológicas
@since 2/4/2025
@param cID, character, ID do apontamento
@return character, cSC2
/*/
static function getSC2( cID )
    
    local cSC2 := Space( TAMSX3('C2_NUM')[1] ) as character
    
    DBSelectArea( 'SC2' )
    SC2->( DBOrderNickName( 'IDAPONTA' ) )
    if SC2->( DBSeek( FWxFilial( 'SC2' ) + cID ) )
        cSC2 := SC2->C2_NUM
    endif

return cSC2

/*/{Protheus.doc} SFINCOP
FUnção que cria a ordem de produção no Protheus
@type function
@version 12.1.2410
@author JS Soluções
@since 3/13/2025
@param oOP, object, Objeto com os dados para criação da OP
@param _cAliCb, variant, Alias da tabela principal
@param cEmp, character, codigo da empresa em que o JOB deve conectar
@param cFil, character, codigo da filial em que o JOB deve conectar
@param cID, character, ID do processo de apontamento automático
@param dData, date, data base em que o usuário está logado
@return character, cOP
/*/
user function SFINCOP( aOrdPrd, cAliCab, cEmp, cFil, cID, dData )
    
    local cOP := "" as character
    local aAux := {} as array
    local cErro := "" as character

    Private _cAliCb := cAliCab

    default dData := date()


    ConOut( 'Iniciando JOB de inclusao de OP...' )
    ConOut( 'Conectando à empresa '+ cEmp +' e filial '+ cFil +'...' )

    RpcClearEnv()
    RPCSetType( 3 )
    PREPARE ENVIRONMENT EMPRESA cEmp FILIAL cFil MODULO "PCP"
    dDataBase := dData
    ConOut( 'Conectado com sucesso!' )

    ConOut( 'Gerando OP sobre o processo de apontamento ID '+ cID )
    aAux := createOP( aOrdPrd, cID )
    cOP := aAux[1]
    cErro := aAux[2]

    RESET ENVIRONMENT
    ConOut( 'Fim do Job' )

return { cOP, cErro }
