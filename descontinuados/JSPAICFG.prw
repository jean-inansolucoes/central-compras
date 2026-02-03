#include 'totvs.ch'
#include 'fwmvcdef.ch'

#define JSVERSION U_JSGETVER()
#define LINE      40
#define COLUMN    190
#define NSPACE    10

/*/{Protheus.doc} JSPAICFG
Função de configuração dos parâmetros internos da central de compras.
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/09/2024
/*/
user function JSPAICFG()
    
    local lOk     := .F. as logical
    local oDlg    as object
    local bOk     := {|| lOk := saveConfig(), iif( lOk, oDlg:DeActivate(), Nil ) }
    local oWindow as object
    local aCheck  := {} as array
    local aParms  := getParms()
    local nLin    := 0 as numeric
    local nCol    := 0 as numeric
    local oScroll as object
    local oPar001, oPar002, oPar003, oPar004, oPar005, oPar006, oPar007, oPar008, oPar009, oPar010, oPar011 as object
    local cPar001, cPar002, cPar003, cPar004 := "" as character
    local nPar005, nPar006, nPar007, nPar008, nPar009, nPar010, nPar011 := 0 as numeric
    // local aResp   := {} as array
    
    // Verifica se a versão do dicionário de dados é compatível com a versão das rotinas
    aCheck := checkConfig( aParms )
    if len( aCheck ) > 0
        U_HLP( 'A T E N Ç A O !',;
                'Foi identificado diferença entre a versão do dicionário de dados existente em seu ambiente com a versão das rotinas em execução.',;
                'Execute o processo completo de atualização da versão do Addon Painel de Compras e tente novamente.' )
        return Nil
    endif

    // Inicializa conteúdo dos parâmetros
    cPar001 := ""
    cPar002 := PADR(AllTrim(SuperGetMv( 'MV_X_PNC02',,'' )),3,' ')
    cPar003 := PADR(AllTrim(SuperGetMv( 'MV_X_PNC03',,'' )),3,' ')
    cPar004 := PADR(AllTrim(SuperGetMv( 'MV_X_PNC04',,'' )),3,' ')
    nPar005 := SuperGetMv( 'MV_X_PNC05',,0 )                            // Índice de lucro padrão pretendido

    oDlg := FWDialogModal():New()
    oDlg:SetEscClose( .T. )
    oDlg:SetTitle( "Configurações do Painel de Compras - "+ JSVERSION )
    oDlg:SetSubTitle( AllTrim(SM0->M0_FILIAL) )
    oDlg:SetSize( 400, 600 )

    oDlg:CreateDialog()
    oDlg:AddCloseButton( Nil, 'Fechar' )
    oDlg:AddOkButton( bOk, 'Confirmar' )

    oWindow := TPanel():New( ,,, oDlg:GetPanelMain() )
    oWindow:Align := CONTROL_ALIGN_ALLCLIENT

    oScroll := TScrollBox():New( oWindow, 0, 0, oWindow:nClientHeight, oWindow:nClientWidth, .T., .T., .T. )
    oScroll:Align := CONTROL_ALIGN_ALLCLIENT

    nLin := 1
    nCol := 0
    oPar001 := TGet():New( nLin*LINE, (nCol*COLUMN)+NSPACE,{|u|if(PCount()==0,cPar001,cPar001:=u)},oScroll,COLUMN*0.7,012,;
                "@x",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'cPar001',,,,.T.,.F.,,aParms[aScan(aParms,{|x|x[1]=='MV_X_PNC01'})][2], 1 )
    oPar001:bWhen := {|| FWIsAdmin()}
    
    nCol++
    oPar002 := TGet():New( nLin*LINE, (nCol*COLUMN)+NSPACE,{|u|if(PCount()==0,cPar002,cPar002:=u)},oScroll,30,012,;
                "@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'cPar002',,,,.T.,.F.,,aParms[aScan(aParms,{|x|x[1]=='MV_X_PNC02'})][2], 1 )
    oPar002:cF3 := "SX2"
    oPar002:bWhen := {|| FWIsAdmin()}

    nCol++
    oPar003 := TGet():New( nLin*LINE, (nCol*COLUMN)+NSPACE,{|u|if(PCount()==0,cPar003,cPar003:=u)},oScroll,30,012,;
                "@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'cPar003',,,,.T.,.F.,,aParms[aScan(aParms,{|x|x[1]=='MV_X_PNC03'})][2], 1 )
    oPar003:cF3 := "SX2"
    oPar003:bWhen := {|| FWIsAdmin()}

    nCol := 0
    nLin++
    oPar004 := TGet():New( nLin*LINE, (nCol*COLUMN)+NSPACE,{|u|if(PCount()==0,cPar004,cPar004:=u)},oScroll,30,012,;
                "@!",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'cPar004',,,,.T.,.F.,,aParms[aScan(aParms,{|x|x[1]=='MV_X_PNC04'})][2], 1 )
    oPar004:cF3 := "SX2"
    oPar004:bWhen := {|| FWIsAdmin()}

    nCol++
    oPar005 := TGet():New( nLin*LINE, (nCol*COLUMN)+NSPACE,{|u|if(PCount()==0,nPar005,nPar005:=u)},oScroll,080,012,;
                "@E 9,999.99",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'nPar005',,,,.T.,.F.,,aParms[aScan(aParms,{|x|x[1]=='MV_X_PNC05'})][2], 1 )
    oPar005:bWhen := {|| FWIsAdmin()}

    nCol++
    oPar006 := TGet():New( nLin*LINE, (nCol*COLUMN)+NSPACE,{|u|if(PCount()==0,nPar006,nPar006:=u)},oScroll,080,012,;
                "@E 9,999.99",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'nPar006',,,,.T.,.F.,,aParms[aScan(aParms,{|x|x[1]=='MV_X_PNC06'})][2], 1 )
    oPar006:bWhen := {|| FWIsAdmin() }

    nCol := 0
    nLin++
    oPar007 := TGet():New( nLin*LINE, (nCol*COLUMN)+NSPACE,{|u|if(PCount()==0,nPar007,nPar007:=u)},oScroll,080,012,;
                "@E 9,999.99",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'nPar007',,,,.T.,.F.,,aParms[aScan(aParms,{|x|x[1]=='MV_X_PNC07'})][2], 1 )
    oPar007:bWhen := {|| FWIsAdmin() }

    nCol++
    oPar008 := TGet():New( nLin*LINE, (nCol*COLUMN)+NSPACE,{|u|if(PCount()==0,nPar008,nPar008:=u)},oScroll,080,012,;
                "@E 9,999.99",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'nPar008',,,,.T.,.F.,,aParms[aScan(aParms,{|x|x[1]=='MV_X_PNC08'})][2], 1 )
    oPar008:bWhen := {|| FWIsAdmin() }

    nCol++
    oPar009 := TGet():New( nLin*LINE, (nCol*COLUMN)+NSPACE,{|u|if(PCount()==0,nPar009,nPar009:=u)},oScroll,080,012,;
                "@E 9,999.99",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'nPar009',,,,.T.,.F.,,aParms[aScan(aParms,{|x|x[1]=='MV_X_PNC09'})][2], 1 )
    oPar009:bWhen := {|| FWIsAdmin() }

    nLin++
    nCol := 0
    oPar010 := TGet():New( nLin*LINE, (nCol*COLUMN)+NSPACE,{|u|if(PCount()==0,nPar010,nPar010:=u)},oScroll,080,012,;
                "@E 9,999.99",,0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,'nPar010',,,,.T.,.F.,,aParms[aScan(aParms,{|x|x[1]=='MV_X_PNC10'})][2], 1 )
    oPar010:bWhen := {|| FWIsAdmin() }

    nCol++
    oPar011 := TComboBox():New( nLin*LINE, (nCol*COLUMN)+NSPACE,{|u|if(PCount()>0,nPar011:=u,nPar011)}, {"Fornecedor Padrão","Melhor Fornecedor"},80,14,oScroll,,,,,,.T.,,,,,,,,,'nPar011', aParms[aScan(aParms,{|x|x[1]=='MV_X_PNC11'})][2], 1)
    oPar011:bWhen := {|| FWIsAdmin() }

    oDlg:Activate()

return Nil

/*/{Protheus.doc} saveConfig
Função para salvar as configurações selecionadas pelo usuário
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 13/09/2024
@return logical, lSuccess
/*/
static function saveConfig()
    local lSuccess := .T. as logical
return lSuccess

/*/{Protheus.doc} getParms
Obtém os parâmetros internos da rotina
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/09/2024
@return array, aParms
/*/
static function getParms()
    local aParms := {} as array
    aAdd( aParms, { 'MV_X_PNC01', 'Fórmula de cálculo para identificar demanda de reposição do produto' } )
    aAdd( aParms, { 'MV_X_PNC02', 'Alias da tabela que armazena os índices previamente calculados para os produtos' } )
    aAdd( aParms, { 'MV_X_PNC03', 'Alias da tabela de configurações internas do Painel de Compras' } )
    aAdd( aParms, { 'MV_X_PNC04', 'Alias da tabela de controle de produtos em processo de descontinuidade' } )
    aAdd( aParms, { 'MV_X_PNC05', 'Índice padrão de lucro pretendido' } )
    aAdd( aParms, { 'MV_X_PNC06', 'Índice aproximado de despesas operacionais para formação de preços' } )
    aAdd( aParms, { 'MV_X_PNC07', 'Índice de CSLL utilizado na formação de preços' } )
    aAdd( aParms, { 'MV_X_PNC08', 'Índice de IRPJ utilizado na composição do preço de venda' } )
    aAdd( aParms, { 'MV_X_PNC09', 'Índice de Inadimplência utilizado na composição do preço de venda' } )
    aAdd( aParms, { 'MV_X_PNC10', 'Índice de custo financeiro para composição do preço de venda' } )
    aAdd( aParms, { 'MV_X_PNC11', 'Análise para obter fornecedor (Fornecedor Padrão ou Melhor Fornecedor)' } )
return aParms

/*/{Protheus.doc} checkConfig
Função de checagem dos parâmetros internos da rotina
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 12/09/2024
@param aParms, array, array com os dados dos parâmetros a serem validados
@return array, aErros
/*/
static function checkConfig( aParms )
    
    local aErros := {} as array
    aEval( aParms, {|x| iif( !GetMv( x[1], .T. /* lCheck */ ),;
                        'Ausência de configuração do parâmetro interno '+ x[1] +' ('+ x[2] +')', Nil ) } )

return aErros
