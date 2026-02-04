#include "totvs.ch"

/*/{Protheus.doc} JSCHART
Classe para utilização dos gráficos do Google Chart em customizações ADVPL
@type class
@version 12.1.2410
@author Jean Carlos Pandolfo Saggin
@since 24/11/2025
/*/
Class JSCHART

    Data cTypeChart as numeric              // Tipo do gráfico (1-Barra 2-Pizza ou 3-Linha)
    Data cTitle     as character            // Título do gráfico
    Data cSubTitle  as character            // Subtítulo do gráfico
    Data oData      as object               // Dados do gráfico em formato JSON
    Data oOwner     as object               // Objeto onde o gráfico será construído
    Data nWidth     as numeric              // Largura do gráfico
    Data nHeight    as numeric              // Altura do gráfico
    Data oChannel   as object
    data oWebEngine as object
    data nPort      as numeric
    data cHTML      as character
    data cFullPath  as character

    Method New() Constructor
    Method SetData()
    Method LoadHTML()

EndClass

/*/{Protheus.doc} JSCHART::SetData
Método para alterar a base de dados da classe
@type method
@version 12.1.2410
@author Jean Carlos Pandolfo Saggin
@since 24/11/2025
@param oData, object, objeto com os dados novos
@return object, ::oData
/*/
Method SetData( oData ) Class JSCHART
return ::oData := oData

/*/{Protheus.doc} JSCHART::New
Método que instancia o JSChart e cria a visualização gráfica com base nos dados informados
@type method
@version 12.1.2410
@author Jean Carlos Pandolfo Saggin
@since 21/11/2025
@param cTypeChart, character, Tipo do chart
@param cTitle, character, Titulo
@param cSubTitle, character, SubTitulo
@param oData, object, Objeto Json contendo os dados a serem exibidos
@param oOwner, object, Objeto onde o gráfico vai ser exibido
@param nWidth, numeric, Largura do gráfico
@param nHeight, numeric, Altura do gráfico
@return object, oJSChart
/*/
Method New( cTypeChart, cTitle, cSubTitle, oData, oOwner, nWidth, nHeight ) Class JSCHART

    default cTypeChart := 1
    default cTitle     := "JSChart"
    default cSubTitle  := ""
    default nWidth     := 600
    default nHeight    := 400

    ::cTypeChart := cTypeChart
    ::cTitle     := cTitle
    ::cSubTitle  := cSubTitle
    ::oData      := oData
    ::oOwner     := oOwner
    ::nWidth     := nWidth
    ::nHeight    := nHeight
    ::cHTML      := ::LoadHTML()

Return Self

/*/{Protheus.doc} JSTCHART
Função de usuário para testar funcionamento da biblioteca de gráficos do google chart
@type function
@version 12.1.2410
@author Jean Carlos Pandolfo Saggin
@since 24/11/2025
/*/
User Function JSTCHART()

    local oDlg           as object
    local oData    := JsonObject():New()
    local aData    := {} as array
    local oChart         as object
    // local nPort    := 0  as numeric
    // local oChannel       as object
    local oWebEngine     as object
    local bOk      :={|| oDlg:End() }
    local bCancel  :={|| oDlg:End() }
    local aButtons :={{'BTNOPC1', {|| aEval( aData, {|x| x[2] := iif( ValType(x[2]) == 'C' , x[2], Random( 50, 70 ) )} ),;
                                        oData          := nil,;
                                        oData          := JsonObject():New(),;
                                        oData:Set(aData),;
                                        oChart:SetData( oData ),;
                                        oWebEngine:Navigate(oChart:LoadHTML('2')) }, 'Novos dados...' }}
    local bInit    :={|| EnchoiceBar( oDlg, bOk, bCancel,,aButtons )}

    oData := JsonObject():New()
    aAdd( aData, { 'Período', 'Quantidade' } )
    aAdd( aData, { 'Abril/2025', 52 } )
    aAdd( aData, { 'Maio/2025', 35 } )
    aAdd( aData, { 'Junho/2025', 38 } )
    aAdd( aData, { 'Julho/2025', 59 } )
    aAdd( aData, { 'Agosto/2025', 62 } )
    aAdd( aData, { 'Setembro/2025', 55 } )
    aAdd( aData, { 'Outubro/2025', 56 } )
    aAdd( aData, { 'Novembro/2025', 77 } )
    oData:Set( aData )

    oDlg := TDialog():New(0,0,400,800,'Exemplo JSCHART',,,,,CLR_BLACK,CLR_WHITE,,,.T.)

    // cTypeChart, cTitle, cSubTitle, oData, oOwner, nWidth, nHeight
    oChart := JSChart():New( 1,; 
                            'Exemplo JSCHART',; 
                            'Teste com geração de gráficos utilizando API do Google Chart',;
                            oData,;
                            oDlg,;
                            800*0.9,;
                            340*0.9 )

    oWebEngine := TWebEngine():New( oDlg, 0, 0, 100, 100, , )
    oWebEngine:Align := CONTROL_ALIGN_ALLCLIENT
    oWebEngine:Navigate( oChart:loadHTML( '2' ) )

    oDlg:Activate( ,,,.T., {|| .T. },,bInit )

return Nil

/*/{Protheus.doc} JSCHART::LoadHTML
Função para montar HTML para ser exibido
@type method
@version 12.1.2410
@author Jean Carlos Pandolfo Saggin
@since 24/11/2025
@param cTypeRet, character, Tipo do retorno esperado, sendo 1=HTML ou 2=URL do arquivo HTML
@return character, cHTML
/*/
Method LoadHTML( cTypeRet ) Class JSCHART
    
    local cHTML  := "" as character
    local oFile  as object
    Local cDirLoc  := iif( 'mac' $ Lower( GetRmtInfo()[2] ), 'l:', '' ) + Lower( AllTrim( GetTempPath( .T. /*lLocal*/ ) ) )
	Local cFileLoc := 'pnc_'+ __cUserID +'_dash.html'
	
    default cTypeRet := '2'

    // Verifica se o arquivo já não existe no diretório local
    if File( cDirLoc + cFileLoc )
        fErase( cDirLoc + cFileLoc )
    EndIf

    // Inicializa a variável com o conteúdo do HTML
    ::cHTML := ""

    cHTML += "<html>"
    cHTML += "  <head>"
    cHTML += '    <script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>'
    cHTML += '    <script type="text/javascript">'
    cHTML += "      google.charts.load('current', {'packages':['bar']});"
    cHTML += "      google.charts.setOnLoadCallback(drawChart);"

    cHTML += "      function drawChart() {"
    cHTML += "        var data = google.visualization.arrayToDataTable("+ ::oData:toJson() +");"

    cHTML += "        var options = {"
    cHTML += "          chart: {"
    cHTML += '            legend: { position: "none" }'
    cHTML += "          },"
    cHTML += "          bars: 'horizontal' "
    cHTML += "        };"

    cHTML += "        var chart = new google.charts.Bar(document.getElementById('barchart_material'));"

    cHTML += "        chart.draw(data, google.charts.Bar.convertOptions(options));"
    cHTML += "      }"
    cHTML += "    </script>"
    cHTML += "  </head>"
    cHTML += "  <body>"
    cHTML += '    <div id="barchart_material" style="width: '+ cValToChar( ::nWidth ) +'px; height: '+ cValToChar( ::nHeight ) +'px;"></div>'
    cHTML += "  </body>"
    cHTML += "</html> "

    ::cHTML := cHTML
    ::cFullPath := PADR(StrTran( "file:///"+ StrTran( cDirLoc, 'l:/', '') + cFileLoc, '\','/' ),200,' ')

    oFile := FWFileWriter():New( cDirLoc + cFileLoc, .T. )
    if oFile:Create()
        oFile:Write( ::cHTML )
        oFile:Close()
    endif
    FreeObj( oFile )
    
return iif( cTypeRet == '1', ::cHTML, ::cFullPath )
