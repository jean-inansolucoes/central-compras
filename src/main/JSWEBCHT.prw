#include 'totvs.ch'

#define EOL chr(13)+chr(10)

/*/{Protheus.doc} JSWebChart
Classe que expõe a mesma interface (subconjunto) de FWChartFactory usada hoje no Painel de Compras
(SetChtDef, SetOwner, SetLegend, SetAlinLb, EnableMenu, SetMask, SetPicture, AddSerie,
Activate, DeActivate), mas renderiza o gráfico como HTML/CSS dentro de um TWebEngine, em vez do
motor gráfico nativo do Protheus - item 21b da análise do Painel de Compras (visual mais moderno,
100% local, sem chamada a nenhuma API externa e sem dependência de biblioteca JS de terceiros).
@type class
@version 1.0
@author Visualize - Software e Inovação
@since 29/07/2026
/*/
Class JSWebChart

	Data oWeb
	Data oChannel
	Data aSeries
	Data cPicture
	Data nChartH

	Method New() Constructor
	Method SetChtDef( nType )
	Method SetOwner( oPanel )
	Method SetLegend( nAlign )
	Method SetAlinLb( nAlign )
	Method EnableMenu( lEnable )
	Method SetMask( cMask )
	Method SetPicture( cPic )
	Method AddSerie( cLabel, nValue )
	Method Activate()
	Method DeActivate()
	Method Destroy()

EndClass

/*/{Protheus.doc} New
Construtor: inicializa o vetor de séries e a máscara padrão de exibição dos valores.
@type method
@version 1.0
@author Visualize - Software e Inovação
@since 29/07/2026
@return object, self
/*/
method New() class JSWebChart
	::aSeries  := {}
	::cPicture := "@E 9,999,999"
	::nChartH  := 130	// Altura padrão (em pixels) da área de barras do gráfico
return self

/*/{Protheus.doc} SetChtDef
Mantido apenas por compatibilidade de interface com FWChartFactory (este componente só desenha
gráfico de colunas) - não executa nenhuma ação.
@type method
@version 1.0
@author Visualize - Software e Inovação
@since 29/07/2026
@param nType, numeric, tipo do gráfico (ignorado)
/*/
method SetChtDef( nType ) class JSWebChart
return nil

/*/{Protheus.doc} SetOwner
Define o painel onde o gráfico será renderizado, criando o canal e o motor de navegação web
(mesmo padrão já utilizado em JSNOTIFY.prw para a Central de Notificações).
@type method
@version 1.0
@author Visualize - Software e Inovação
@since 29/07/2026
@param oPanel, object, painel/janela onde o gráfico deve ser desenhado
/*/
method SetOwner( oPanel ) class JSWebChart

	local nPort := 0 as numeric

	::oChannel := TWebChannel():New()
	nPort      := ::oChannel:connect()

	::oWeb := TWebEngine():New( oPanel, 0, 0, 100, 100, /*cUrl*/, nPort )
	::oWeb:Align := CONTROL_ALIGN_ALLCLIENT

return nil

/*/{Protheus.doc} SetLegend
Mantido apenas por compatibilidade de interface com FWChartFactory - não executa nenhuma ação.
@type method
@version 1.0
@author Visualize - Software e Inovação
@since 29/07/2026
@param nAlign, numeric, alinhamento da legenda (ignorado)
/*/
method SetLegend( nAlign ) class JSWebChart
return nil

/*/{Protheus.doc} SetAlinLb
Mantido apenas por compatibilidade de interface com FWChartFactory - não executa nenhuma ação.
@type method
@version 1.0
@author Visualize - Software e Inovação
@since 29/07/2026
@param nAlign, numeric, alinhamento do rótulo da série (ignorado)
/*/
method SetAlinLb( nAlign ) class JSWebChart
return nil

/*/{Protheus.doc} EnableMenu
Mantido apenas por compatibilidade de interface com FWChartFactory - não executa nenhuma ação.
@type method
@version 1.0
@author Visualize - Software e Inovação
@since 29/07/2026
@param lEnable, logical, indica se o menu deveria ser habilitado (ignorado)
/*/
method EnableMenu( lEnable ) class JSWebChart
return nil

/*/{Protheus.doc} SetMask
Mantido apenas por compatibilidade de interface com FWChartFactory - não executa nenhuma ação.
@type method
@version 1.0
@author Visualize - Software e Inovação
@since 29/07/2026
@param cMask, character, máscara de exibição (ignorada)
/*/
method SetMask( cMask ) class JSWebChart
return nil

/*/{Protheus.doc} SetPicture
Define a máscara (picture) usada para formatar os valores exibidos sobre cada barra.
@type method
@version 1.0
@author Visualize - Software e Inovação
@since 29/07/2026
@param cPic, character, picture no formato Protheus (ex.: "@E 9,999,999")
/*/
method SetPicture( cPic ) class JSWebChart
	::cPicture := cPic
return nil

/*/{Protheus.doc} AddSerie
Adiciona uma barra (rótulo + valor) ao gráfico, na mesma ordem de chamada já usada hoje em
fLoadAna()/makeTot() para o FWChartFactory.
@type method
@version 1.0
@author Visualize - Software e Inovação
@since 29/07/2026
@param cLabel, character, rótulo da barra
@param nValue, numeric, valor da barra
/*/
method AddSerie( cLabel, nValue ) class JSWebChart
	default nValue := 0
	aAdd( ::aSeries, { cLabel, nValue } )
return nil

/*/{Protheus.doc} Activate
Renderiza o HTML/CSS do gráfico com as séries acumuladas desde o último DeActivate().
@type method
@version 1.0
@author Visualize - Software e Inovação
@since 29/07/2026
/*/
method Activate() class JSWebChart
	if ValType( ::oWeb ) == 'O'
		::oWeb:SetHtml( MakeChtHtm( ::aSeries, ::cPicture, ::nChartH ) )
	endif
return nil

/*/{Protheus.doc} DeActivate
Limpa as séries acumuladas, preparando o gráfico para um novo ciclo de AddSerie()+Activate().
@type method
@version 1.0
@author Visualize - Software e Inovação
@since 29/07/2026
/*/
method DeActivate() class JSWebChart
	::aSeries := {}
return nil

/*/{Protheus.doc} Destroy
Encerra o canal de comunicação do motor de navegação web, liberando os recursos associados.
@type method
@version 1.0
@author Visualize - Software e Inovação
@since 29/07/2026
/*/
method Destroy() class JSWebChart
	if ValType( ::oChannel ) == 'O'
		::oChannel:disconnect()
		FreeObj( ::oChannel )
		::oChannel := Nil
	endif
return nil

/*/{Protheus.doc} MakeChtHtm
Monta o HTML/CSS do gráfico de colunas (barras verticais com gradiente, rótulo de valor no topo
e legenda embaixo), 100% autocontido (sem script externo, sem chamada de rede).
@type function
@version 1.0
@author Visualize - Software e Inovação
@since 29/07/2026
@param aSeries, array, vetor de séries { {cLabel, nValue}, ... }
@param cPicture, character, picture Protheus usada para formatar o valor de cada barra
@param nChartH, numeric, altura disponível (em pixels) para a coluna do gráfico
@return character, cHtml
/*/
static function MakeChtHtm( aSeries, cPicture, nChartH )

	local cHtml    := "" as character
	local nX       := 0  as numeric
	local nMax     := 0  as numeric
	local nBarPx   := 0  as numeric
	local cValor   := "" as character
	local nCorIdx  := 0  as numeric
	local nLabelH  := 40 as numeric
	local nBarH    := 0  as numeric
	local aPaleta  := { { "#a7c7fb", "#3b82f6" },;
						 { "#93e0c6", "#10b981" },;
						 { "#b9c0cb", "#64748b" },;
						 { "#fcc096", "#f97316" },;
						 { "#ceb8a9", "#92613f" },;
						 { "#90cedc", "#0891b2" },;
						 { "#cbb6fb", "#8b5cf6" },;
						 { "#e7ca8e", "#ca8a04" },;
						 { "#afc493", "#4d7c0f" },;
						 { "#92cfc9", "#0d9488" } } as array

	default nChartH := 130

	nBarH := nChartH - nLabelH
	if nBarH < 0
		nBarH := 0
	endif

	aEval( aSeries, {|x| nMax := iif( x[2] > nMax, x[2], nMax ) } )
	if nMax == 0
		nMax := 1
	endif

	cHtml += '<!DOCTYPE html>'+ EOL
	cHtml += '<html lang="pt-BR"><head><meta charset="utf-8">'+ EOL
	cHtml += '<meta name="viewport" content="width=device-width, initial-scale=1">'+ EOL
	cHtml += '<style>'+ EOL
	cHtml += 'html,body{margin:0;padding:0;}'+ EOL
	cHtml += 'body{font-family:"Segoe UI",Arial,sans-serif;background:#ffffff;color:#22303c;box-sizing:border-box;padding:16px;}'+ EOL
	cHtml += '.chart{display:flex;align-items:flex-end;justify-content:space-around;gap:6px;}'+ EOL
	// Altura da coluna em pixel fixo (não percentual) - motores de renderização embutidos mais antigos
	// (caso do TWebEngine) têm suporte inconsistente para resolver "height:%" encadeado através de
	// várias camadas de flexbox; pixel fixo elimina essa dependência e funciona em qualquer motor.
	// nChartH é o espaço TOTAL já disponível no painel (não pode ser ampliado) - por isso ele é
	// dividido em duas fatias: nBarH para a barra em si e nLabelH reservado para rótulo de valor +
	// rótulo do período. Sem essa reserva, a barra do maior valor (que sozinha ocuparia nChartH
	// inteiro) sobra sem espaço para os rótulos dentro da coluna e o flexbox a encolhe (a <div> da
	// barra não tem conteúdo próprio, logo não tem altura mínima que impeça esse encolhimento) -
	// isso fazia a barra do maior valor renderizar quase do mesmo tamanho das menores
	cHtml += '.bar-col{display:flex;flex-direction:column;align-items:center;justify-content:flex-end;flex:1;height:'+ cValToChar( nChartH ) +'px;}'+ EOL
	cHtml += '.bar-val{font-size:12px;font-weight:600;color:#0a5ab4;margin-bottom:4px;white-space:nowrap;}'+ EOL
	// Altura de cada barra também vai em pixel fixo (calculada aqui, no AdvPL), no mesmo estilo inline -
	// o efeito de "crescer" continua sendo só decorativo, via CSS puro (transform:scaleY)
	cHtml += '.bar{width:70%;max-width:56px;border-radius:8px 8px 0 0;background:linear-gradient(180deg,#3fa7ff 0%,#0a5ab4 100%);box-shadow:0 2px 6px rgba(10,90,180,.25);transform-origin:bottom;animation:cresce 0.5s ease-out;}'+ EOL
	cHtml += '@keyframes cresce{from{transform:scaleY(0);}to{transform:scaleY(1);}}'+ EOL
	cHtml += '.bar-lbl{font-size:11px;color:#5a6b7b;margin-top:6px;text-align:center;max-width:90px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;}'+ EOL
	cHtml += '</style></head><body>'+ EOL
	cHtml += '<div class="chart">'+ EOL

	for nX := 1 to len( aSeries )
		nBarPx := Round( ( aSeries[nX][2] / nMax ) * nBarH, 0 )
		cValor := AllTrim( Transform( aSeries[nX][2], cPicture ) )
		nCorIdx := Randomize( 1, Len( aPaleta ) + 1 )
		cHtml += '<div class="bar-col">'+ EOL
		cHtml += '<div class="bar-val">'+ cValor +'</div>'+ EOL
		cHtml += '<div class="bar" style="height:'+ cValToChar( nBarPx ) +'px;background:linear-gradient(180deg,'+ aPaleta[nCorIdx][1] +' 0%,'+ aPaleta[nCorIdx][2] +' 100%)"></div>'+ EOL
		cHtml += '<div class="bar-lbl">'+ aSeries[nX][1] +'</div>'+ EOL
		cHtml += '</div>'+ EOL
	next nX

	cHtml += '</div>'+ EOL
	cHtml += '</body></html>'+ EOL

return cHtml
