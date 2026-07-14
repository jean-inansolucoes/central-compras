#include 'totvs.ch'
#include 'topconn.ch'

#define CEOL        chr(13)+chr(10)

// Índices do vetor de snapshot por produto (montado em U_GMINDPRO e completado em loadMiss)
#define SNAP_CONMED   01      // Consumo médio diário total (venda + consumo)
#define SNAP_VENDA    02      // Quantidade total vendida no período (SD2)
#define SNAP_CONSUMO  03      // Quantidade total consumida em produção no período (SD3)
#define SNAP_DIAS     04      // Quantidade de dias considerados na média (mínimo 1)
#define SNAP_ESTOQUE  05      // Saldo em estoque (após PEPNC04, quando existir)
#define SNAP_EMPENHO  06      // Quantidade empenhada/reservada
#define SNAP_QTDCOMP  07      // Quantidade em pedidos de compra em carteira
#define SNAP_QTDSOL   08      // Quantidade em solicitações de compra sem pedido
#define SNAP_ORDPROD  09      // Quantidade em ordens de produção em aberto
#define SNAP_LOTMIN   10      // Lote mínimo (B1_LM)
#define SNAP_QTDEMB   11      // Quantidade por embalagem (B1_QE)
#define SNAP_LOTECO   12      // Lote econômico (B1_LE)
#define SNAP_ESTSEG   13      // Estoque de segurança (B1_EMIN)
#define SNAP_LEADTIME 14      // Lead time em dias
#define SNAP_PERFIL   15      // ID do perfil de cálculo do produto
#define SNAP_NECCOM   16      // Necessidade convencional já calculada (fCalNec)
#define SNAP_PRJEST   17      // Duração projetada do estoque em dias

#define MAX_NIVEL     30      // Profundidade máxima da árvore de estruturas
#define MAX_LINHAS    5000    // Limite de linhas de trace por componente
#define TAM_CHUNK     500     // Tamanho máximo de listas IN () nas queries

/*/{Protheus.doc} JSREVEST
Fase de análise reversa de estruturas do SmartSupply: a partir do snapshot de dados por produto
gerado pelo recálculo de índices (U_GMINDPRO), carrega a estrutura de produtos (SG1) em memória,
ordena a cadeia dos produtos finais para os componentes (ordenação topológica), desce a necessidade
dos produtos finais (fórmula do perfil de cálculo) multiplicando pelas quantidades da estrutura,
abate nível a nível o estoque e as OPs em aberto dos intermediários (netting global por produto) e
materializa o resultado nas tabelas PNC_RVCALC_<empresa> (resultado por produto) e
PNC_RVTRC_<empresa> (trace da sequência de cálculo para auditoria).
Pré-condição: deve ser executada dentro da pilha de U_GMINDPRO (depende das variáveis Private
aConfig, cZBM e cPerfDef para o cálculo de necessidade via U_JSCALNEC).
@type function
@version 20.0002
@author Jean Carlos Pandolfo Saggin
@since 09/07/2026
@param aCfgRev, array, vetor de configurações internas da filial (U_JSGETCFG)
@param aPerRev, array, período de análise { dInicio, dFim } utilizado pelo recálculo de índices
@param oSnap, object, hashmap com o snapshot de dados por produto (layout nos defines SNAP_*)
@param dCalc, date, data de referência do cálculo (mesma data gravada na tabela de índices)
@return logical, lSucesso - indica se a fase reversa foi executada e materializada
/*/
user function JSREVEST( aCfgRev, aPerRev, oSnap, dCalc )

    local lSucesso := .F. as logical
    local aGrafo   := {} as array
    local aTopo    := {} as array
    local aOrdem   := {} as array
    local aCiclo   := {} as array
    local aFalta   := {} as array
    local aCalc    := {} as array
    local aSnpAux  := {} as array
    local cTabCal  := "PNC_RVCALC_"+ cEmpAnt
    local cTabTrc  := "PNC_RVTRC_"+ cEmpAnt
    local nX       := 0 as numeric

    default dCalc := Date()

    // Valida existência das tabelas de materialização da análise reversa
    if ! TCCanOpen( cTabCal ) .or. ! TCCanOpen( cTabTrc )
        ConOut( 'JSREVEST - '+ Time() +' - TABELAS DE ANALISE REVERSA NAO ENCONTRADAS ( '+ cTabCal +' / '+ cTabTrc +' ). EXECUTE O ASSISTENTE U_JSGLBPAR.' )
        FWLogMsg( 'WARN', /*cTransactionId*/, 'SMARTSUPPLY', FunName(), '', '01', 'Tabelas de análise reversa não encontradas: '+ cTabCal +' / '+ cTabTrc )
        return lSucesso
    endif

    // Carrega o grafo da estrutura de produtos (SG1) em memória com uma única query
    aGrafo := loadSG1()
    if len( aGrafo[3] ) == 0
        ConOut( 'JSREVEST - '+ Time() +' - NENHUMA ESTRUTURA DE PRODUTOS (SG1) ENCONTRADA PARA A FILIAL '+ cFilAnt )
        return lSucesso
    endif
    ConOut( 'JSREVEST - '+ Time() +' - GRAFO DE ESTRUTURAS CARREGADO: '+ cValToChar( len( aGrafo[3] ) ) +' PRODUTOS ENVOLVIDOS' )

    // Ordenação topológica (produtos finais primeiro) com proteção contra ciclos
    aTopo  := topoOrder( aGrafo[1] /*oFilhos*/, aGrafo[2] /*oPais*/, aGrafo[3] /*aNodes*/ )
    aOrdem := aTopo[1]
    aCiclo := aTopo[2]
    if len( aCiclo ) > 0
        ConOut( 'JSREVEST - '+ Time() +' - ATENCAO: CICLO IDENTIFICADO NA ESTRUTURA DE PRODUTOS. PRODUTOS FORA DO CALCULO REVERSO: '+ arrToStr( aCiclo ) )
        FWLogMsg( 'WARN', /*cTransactionId*/, 'SMARTSUPPLY', FunName(), '', '02', 'Ciclo identificado na estrutura de produtos (SG1). Produtos fora do cálculo reverso: '+ arrToStr( aCiclo ) )
    endif

    // Completa o snapshot para os produtos da cadeia que ficaram fora do recálculo de índices (ex.: PAs/PIs fora dos tipos configurados)
    for nX := 1 to len( aOrdem )
        aSnpAux := {}
        if ! HMGet( oSnap, aOrdem[nX], @aSnpAux )
            aAdd( aFalta, aOrdem[nX] )
        endif
    next nX
    if len( aFalta ) > 0
        ConOut( 'JSREVEST - '+ Time() +' - COMPLETANDO DADOS DE '+ cValToChar( len( aFalta ) ) +' PRODUTOS DA CADEIA FORA DO RECALCULO PRINCIPAL...' )
        loadMiss( aFalta, aCfgRev, aPerRev, oSnap, aGrafo[2] /*oPais*/ )
    endif

    // Descida da necessidade dos produtos finais até os componentes com netting global por produto
    aCalc := calcDesc( aOrdem, aGrafo[1] /*oFilhos*/, aGrafo[2] /*oPais*/, oSnap, aCfgRev )

    // Materializa o resultado por componente e o trace da sequência de cálculo
    lSucesso := saveAll( aOrdem, aGrafo[2] /*oPais*/, oSnap, aCalc, aCfgRev, dCalc, cTabCal, cTabTrc )

return lSucesso

/*/{Protheus.doc} loadSG1
Carrega a estrutura de produtos (SG1) da filial corrente em memória com uma única query,
montando os mapas de navegação nos dois sentidos (pai para filhos e filho para pais).
Espelha o comportamento da explosão convencional (getMPs): considera apenas G1_COD, G1_COMP e
G1_QUANT, sem tratamento de perdas (G1_PERDA) ou revisões/vigência.
@type function
@version 20.0002
@author Jean Carlos Pandolfo Saggin
@since 09/07/2026
@return array, { oFilhos (hashmap pai -> { {componente, quantidade} }), oPais (hashmap componente -> { {pai, quantidade} }), aNodes (códigos distintos) }
/*/
static function loadSG1()

    local oFilhos := HMNew()
    local oPais   := HMNew()
    local oNodes  := HMNew()
    local aNodes  := {} as array
    local aAux    := {} as array
    local cQuery  := "" as character
    local cAlias  := GetNextAlias()
    local xDummy  := Nil

    cQuery := "SELECT G1.G1_COD, G1.G1_COMP, G1.G1_QUANT " + CEOL
    cQuery += "FROM "+ RetSqlName( 'SG1' ) +" G1 " + CEOL
    cQuery += "WHERE G1.G1_FILIAL  = '"+ FWxFilial( 'SG1' ) +"' " + CEOL
    cQuery += "  AND G1.G1_COD    <> G1.G1_COMP " + CEOL
    cQuery += "  AND G1.D_E_L_E_T_ = ' ' " + CEOL

    DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), cAlias, .F., .T. )
    while ! ( cAlias )->( EOF() )

        // Mapa pai -> filhos
        aAux := {}
        if HMGet( oFilhos, ( cAlias )->G1_COD, @aAux )
            aAdd( aAux, { ( cAlias )->G1_COMP, ( cAlias )->G1_QUANT } )
        else
            aAux := { { ( cAlias )->G1_COMP, ( cAlias )->G1_QUANT } }
        endif
        HMSet( oFilhos, ( cAlias )->G1_COD, aAux )

        // Mapa filho -> pais
        aAux := {}
        if HMGet( oPais, ( cAlias )->G1_COMP, @aAux )
            aAdd( aAux, { ( cAlias )->G1_COD, ( cAlias )->G1_QUANT } )
        else
            aAux := { { ( cAlias )->G1_COD, ( cAlias )->G1_QUANT } }
        endif
        HMSet( oPais, ( cAlias )->G1_COMP, aAux )

        // Lista de produtos distintos envolvidos nas estruturas
        if ! HMGet( oNodes, ( cAlias )->G1_COD, @xDummy )
            HMSet( oNodes, ( cAlias )->G1_COD, .T. )
            aAdd( aNodes, ( cAlias )->G1_COD )
        endif
        if ! HMGet( oNodes, ( cAlias )->G1_COMP, @xDummy )
            HMSet( oNodes, ( cAlias )->G1_COMP, .T. )
            aAdd( aNodes, ( cAlias )->G1_COMP )
        endif

        ( cAlias )->( DbSkip() )
    end
    ( cAlias )->( DbCloseArea() )

return { oFilhos, oPais, aNodes }

/*/{Protheus.doc} topoOrder
Realiza a ordenação topológica dos produtos das estruturas (algoritmo de Kahn), garantindo que
todo produto seja processado somente depois de todos os seus pais. Produtos envolvidos em ciclo
(ou alcançáveis apenas através de ciclo) ficam de fora da ordem e são devolvidos separadamente.
@type function
@version 20.0002
@author Jean Carlos Pandolfo Saggin
@since 09/07/2026
@param oFilhos, object, hashmap pai -> filhos
@param oPais, object, hashmap filho -> pais
@param aNodes, array, códigos distintos dos produtos das estruturas
@return array, { aOrdem (códigos em ordem topológica - finais primeiro), aCiclo (códigos fora da ordem) }
/*/
static function topoOrder( oFilhos, oPais, aNodes )

    local oGrau   := HMNew()
    local oNaOrd  := HMNew()
    local aOrdem  := {} as array
    local aCiclo  := {} as array
    local aFila   := {} as array
    local aPais   := {} as array
    local aFilhos := {} as array
    local cNode   := "" as character
    local nIni    := 1 as numeric
    local nGrau   := 0 as numeric
    local nX      := 0 as numeric
    local xDummy  := Nil

    // Grau de entrada = quantidade de ligações vindas de pais; raízes (produtos finais) iniciam a fila
    for nX := 1 to len( aNodes )
        aPais := {}
        if HMGet( oPais, aNodes[nX], @aPais )
            HMSet( oGrau, aNodes[nX], len( aPais ) )
        else
            HMSet( oGrau, aNodes[nX], 0 )
            aAdd( aFila, aNodes[nX] )
        endif
    next nX

    while nIni <= len( aFila )
        cNode := aFila[nIni]
        nIni++
        aAdd( aOrdem, cNode )
        HMSet( oNaOrd, cNode, .T. )
        aFilhos := {}
        if HMGet( oFilhos, cNode, @aFilhos )
            for nX := 1 to len( aFilhos )
                nGrau := 0
                HMGet( oGrau, aFilhos[nX][1], @nGrau )
                nGrau--
                HMSet( oGrau, aFilhos[nX][1], nGrau )
                if nGrau == 0
                    aAdd( aFila, aFilhos[nX][1] )
                endif
            next nX
        endif
    end

    // Produtos que não entraram na ordem participam de ciclo ou dependem de um ciclo
    if len( aOrdem ) < len( aNodes )
        for nX := 1 to len( aNodes )
            if ! HMGet( oNaOrd, aNodes[nX], @xDummy )
                aAdd( aCiclo, aNodes[nX] )
            endif
        next nX
    endif

return { aOrdem, aCiclo }

/*/{Protheus.doc} loadMiss
Completa o snapshot de dados para os produtos da cadeia de estruturas que ficaram fora do loop
principal do recálculo de índices (ex.: produtos acabados/intermediários fora dos tipos
configurados em TIPOS ou sem B1_MRP = 'S'). Utiliza queries dedicadas (posição de estoque e
carteiras via subselects sobre SB1 e venda/consumo agregados por produto), sem os filtros de
tipo/MRP/fornecedor da query principal. Para os produtos completados aqui a necessidade
convencional é calculada com a mesma fórmula do perfil (U_JSCALNEC).
Limitações da primeira versão (documentadas): não considera código anterior (B1_CODANT) e o
ponto de entrada PEPNC08 não é aplicado nas queries de venda/consumo destes produtos; lead time
utiliza apenas B1_PE (zero quando não cadastrado, com registro em log).
@type function
@version 20.0002
@author Jean Carlos Pandolfo Saggin
@since 09/07/2026
@param aFalta, array, códigos dos produtos sem snapshot
@param aCfgRev, array, configurações internas da filial
@param aPerRev, array, período de análise { dInicio, dFim }
@param oSnap, object, hashmap de snapshot a ser completado
@param oPais, object, hashmap filho -> pais (para identificar raízes)
/*/
static function loadMiss( aFalta, aCfgRev, aPerRev, oSnap, oPais )

    local oVenda   := HMNew()
    local oConsumo := HMNew()
    local aChunks  := inChunks( aFalta )
    local aLocais  := {} as array
    local aPaisAux := {} as array
    local aInfPrd  := {} as array
    local cLocais  := "" as character
    local cQuery   := "" as character
    local cAlias   := "" as character
    local cPerfMis := "" as character
    local cSemLT   := "" as character
    local lPerca   := SB1->( FieldPos( 'B1_X_PERCA' ) ) > 0
    local lTrfMis  := U_JSTRFFIL( cFilAnt )
    local nDiasMis := 0 as numeric
    local nConMed  := 0 as numeric
    local nVenda   := 0 as numeric
    local nConsumo := 0 as numeric
    local nEstDisp := 0 as numeric
    local nPrjEst  := 0 as numeric
    local nLdTime  := 0 as numeric
    local nNecCom  := 0 as numeric
    local nChunk   := 0 as numeric
    local nX       := 0 as numeric

    // Monta a lista de armazéns considerados para saldo (mesma regra da query principal)
    aLocais := StrTokArr( AllTrim( aCfgRev[16] ), '/' )
    for nX := 1 to len( aLocais )
        cLocais += PADR( AllTrim( aLocais[nX] ), TAMSX3( 'B2_LOCAL' )[01], ' ' )
        if nX < len( aLocais )
            cLocais += "','"
        endif
    next nX

    // Quantidade de dias do período de análise (mesma régua do recálculo de índices)
    nDiasMis := countDaysR( aPerRev[1], aPerRev[2], aCfgRev )
    if nDiasMis <= 0
        nDiasMis := 1
    endif

    // Venda (SD2 com TES que movimenta estoque) e consumo (SD3 com TM >= 500) agregados por produto
    for nChunk := 1 to len( aChunks )

        cQuery := "SELECT D2.D2_COD PROD, COALESCE(SUM(D2.D2_QUANT),0) QTD " + CEOL
        cQuery += "FROM "+ RetSqlName( 'SD2' ) +" D2 " + CEOL
        cQuery += "INNER JOIN "+ RetSqlName( 'SF4' ) +" F4 " + CEOL
        cQuery += " ON F4.F4_FILIAL  = '"+ FWxFilial( 'SF4' ) +"' " + CEOL
        cQuery += "AND F4.F4_CODIGO  = D2.D2_TES " + CEOL
        cQuery += "AND F4.F4_ESTOQUE = 'S' " + CEOL
        cQuery += "AND F4.D_E_L_E_T_ = ' ' " + CEOL
        cQuery += "WHERE D2.D2_FILIAL  = '"+ FWxFilial( 'SD2' ) +"' " + CEOL
        cQuery += "  AND D2.D2_TIPO    = 'N' " + CEOL
        cQuery += "  AND D2.D2_EMISSAO BETWEEN '"+ DtoS( aPerRev[1] ) +"' AND '"+ DtoS( aPerRev[2] ) +"' " + CEOL
        if ! lTrfMis
            cQuery += "  AND D2.D2_CLIENTE <> '"+ PADR( SubStr( SM0->M0_CGC, 01, 08 ), TAMSX3( 'D2_CLIENTE' )[1], ' ' ) +"' " + CEOL
        endif
        cQuery += "  AND D2.D2_COD IN ( "+ aChunks[nChunk] +" ) " + CEOL
        cQuery += "  AND D2.D_E_L_E_T_ = ' ' " + CEOL
        cQuery += "GROUP BY D2.D2_COD " + CEOL

        cAlias := GetNextAlias()
        DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), cAlias, .F., .T. )
        while ! ( cAlias )->( EOF() )
            HMSet( oVenda, ( cAlias )->PROD, ( cAlias )->QTD )
            ( cAlias )->( DbSkip() )
        end
        ( cAlias )->( DbCloseArea() )

        cQuery := "SELECT D3.D3_COD PROD, COALESCE(SUM(D3.D3_QUANT),0) QTD " + CEOL
        cQuery += "FROM "+ RetSqlName( 'SD3' ) +" D3 " + CEOL
        cQuery += "WHERE D3.D3_FILIAL  = '"+ FWxFilial( 'SD3' ) +"' " + CEOL
        cQuery += "  AND D3.D3_EMISSAO BETWEEN '"+ DtoS( aPerRev[1] ) +"' AND '"+ DtoS( aPerRev[2] ) +"' " + CEOL
        cQuery += "  AND D3.D3_TM     >= '500' " + CEOL
        cQuery += "  AND ( D3.D3_OP     <> '"+ Space( TAMSX3( 'D3_OP' )[1] ) +"' OR D3.D3_CF = 'RE0' ) " + CEOL
        cQuery += "  AND D3.D3_ESTORNO = ' ' " + CEOL
        cQuery += "  AND D3.D3_COD IN ( "+ aChunks[nChunk] +" ) " + CEOL
        cQuery += "  AND D3.D_E_L_E_T_ = ' ' " + CEOL
        cQuery += "GROUP BY D3.D3_COD " + CEOL

        cAlias := GetNextAlias()
        DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), cAlias, .F., .T. )
        while ! ( cAlias )->( EOF() )
            HMSet( oConsumo, ( cAlias )->PROD, ( cAlias )->QTD )
            ( cAlias )->( DbSkip() )
        end
        ( cAlias )->( DbCloseArea() )

    next nChunk

    // Posição de estoque, carteiras e dados cadastrais dos produtos faltantes
    for nChunk := 1 to len( aChunks )

        cQuery := "SELECT B1.B1_COD, B1.B1_LM, B1.B1_QE, B1.B1_LE, B1.B1_EMIN, B1.B1_PE, " + CEOL
        if lPerca
            cQuery += "B1.B1_X_PERCA, " + CEOL
        endif

        cQuery += "COALESCE((SELECT SUM(B2.B2_QATU) FROM "+ RetSqlName( 'SB2' ) +" B2 " + CEOL
        cQuery += "WHERE B2.B2_FILIAL = '"+ FWxFilial( 'SB2' ) +"' " + CEOL
        cQuery += "  AND B2.B2_COD    = B1.B1_COD " + CEOL
        cQuery += "  AND B2.B2_LOCAL  IN ( '"+ cLocais +"' ) " + CEOL
        cQuery += "  AND B2.D_E_L_E_T_ = ' ' ),0) ESTOQUE, " + CEOL

        cQuery += "COALESCE((SELECT SUM(B2.B2_RESERVA+B2.B2_QEMP) FROM "+ RetSqlName( 'SB2' ) +" B2 " + CEOL
        cQuery += "WHERE B2.B2_FILIAL = '"+ FWxFilial( 'SB2' ) +"' " + CEOL
        cQuery += "  AND B2.B2_COD    = B1.B1_COD " + CEOL
        cQuery += "  AND B2.B2_LOCAL  IN ( '"+ cLocais +"' ) " + CEOL
        cQuery += "  AND B2.D_E_L_E_T_ = ' ' ),0) EMPENHO, " + CEOL

        cQuery += "COALESCE((SELECT SUM(C7COMP.C7_QUANT - C7COMP.C7_QUJE) FROM "+ RetSqlName( 'SC7' ) +" C7COMP " + CEOL
        cQuery += "WHERE C7COMP.C7_FILIAL = '"+ FWxFilial( 'SC7' ) +"' " + CEOL
        cQuery += "  AND C7COMP.C7_PRODUTO = B1.B1_COD " + CEOL
        cQuery += "  AND C7COMP.C7_RESIDUO <> 'S' " + CEOL
        cQuery += "  AND C7COMP.C7_ENCER   <> 'E' " + CEOL
        cQuery += "  AND C7COMP.C7_CONAPRO <> 'B' " + CEOL
        cQuery += "  AND C7COMP.D_E_L_E_T_ = ' ' ),0) QTDCOMP, " + CEOL

        cQuery += "COALESCE( ( SELECT SUM( C1.C1_QUANT ) FROM "+ RetSqlName( 'SC1' ) +" C1 " + CEOL
        cQuery += "WHERE C1.C1_FILIAL  = '"+ FWxFilial( 'SC1' ) +"' " + CEOL
        cQuery += "  AND C1.C1_PRODUTO = B1.B1_COD " + CEOL
        cQuery += "  AND C1.C1_PEDIDO  = '"+ Space( TAMSX3( 'C1_PEDIDO' )[1] ) +"' " + CEOL
        cQuery += "  AND C1.C1_RESIDUO = ' ' " + CEOL
        cQuery += "  AND C1.D_E_L_E_T_ = ' ' ),0 ) QTDSOL, " + CEOL

        cQuery += "COALESCE((SELECT SUM( C2.C2_QUANT - C2.C2_QUJE ) FROM "+ RetSqlName( 'SC2' ) +" C2 " + CEOL
        cQuery += "WHERE C2.C2_FILIAL  = '"+ FWxFilial( 'SC2' ) +"' " + CEOL
        cQuery += "  AND C2.C2_PRODUTO = B1.B1_COD " + CEOL
        cQuery += "  AND C2.C2_DATRF   = '"+ Space(8) +"' " + CEOL
        cQuery += "  AND C2.D_E_L_E_T_ = ' ' ),0) ORDPROD " + CEOL

        cQuery += "FROM "+ RetSqlName( 'SB1' ) +" B1 " + CEOL
        cQuery += "WHERE B1.B1_FILIAL  = '"+ FWxFilial( 'SB1' ) +"' " + CEOL
        cQuery += "  AND B1.B1_COD IN ( "+ aChunks[nChunk] +" ) " + CEOL
        cQuery += "  AND B1.D_E_L_E_T_ = ' ' " + CEOL

        cAlias := GetNextAlias()
        DBUseArea( .T., 'TOPCONN', TcGenQry(,,cQuery), cAlias, .F., .T. )
        while ! ( cAlias )->( EOF() )

            nVenda   := 0
            nConsumo := 0
            HMGet( oVenda, ( cAlias )->B1_COD, @nVenda )
            HMGet( oConsumo, ( cAlias )->B1_COD, @nConsumo )

            // Consumo médio diário do produto (mesma regra do recálculo de índices)
            if ( nVenda + nConsumo ) != 0
                nConMed := Round( ( nVenda + nConsumo ) / nDiasMis, 4 )
            else
                nConMed := 0.0001
            endif

            // Duração projetada do estoque em dias (mesma regra do recálculo de índices)
            nEstDisp := ( cAlias )->ESTOQUE
            if aCfgRev[24] == 'S'
                nEstDisp -= ( cAlias )->EMPENHO
            endif
            nPrjEst := Round( ( nEstDisp + ( cAlias )->QTDCOMP ) / nConMed, 0 )
            if nPrjEst > 999
                nPrjEst := 999
            elseif nPrjEst < 0
                nPrjEst := 0
            endif

            // Lead time: somente B1_PE nesta primeira versão (registra em log quando zerado)
            nLdTime := ( cAlias )->B1_PE
            if nLdTime <= 0
                nLdTime := 0
                if Empty( cSemLT )
                    cSemLT := AllTrim( ( cAlias )->B1_COD )
                else
                    cSemLT += ', '+ AllTrim( ( cAlias )->B1_COD )
                endif
            endif

            // Perfil de cálculo do produto (default quando não informado)
            cPerfMis := ""
            if lPerca
                cPerfMis := ( cAlias )->B1_X_PERCA
            endif
            if Empty( cPerfMis )
                cPerfMis := cPerfDef        // Private definida em U_GMINDPRO
            endif

            // Necessidade convencional do produto pela fórmula do perfil de cálculo
            aInfPrd := { aCfgRev[01],;
                         nLdTime,;
                         nPrjEst,;
                         nConMed,;
                         ( cAlias )->B1_LM,;
                         ( cAlias )->B1_QE,;
                         ( cAlias )->B1_LE,;
                         ( cAlias )->B1_EMIN,;
                         ( cAlias )->ESTOQUE,;
                         ( cAlias )->EMPENHO,;
                         ( cAlias )->QTDCOMP,;
                         ( cAlias )->QTDSOL,;
                         ( cAlias )->ORDPROD }
            nNecCom := U_JSCALNEC( aInfPrd, cPerfMis )

            HMSet( oSnap, ( cAlias )->B1_COD, { nConMed, nVenda, nConsumo, nDiasMis,;
                                                ( cAlias )->ESTOQUE, ( cAlias )->EMPENHO, ( cAlias )->QTDCOMP, ( cAlias )->QTDSOL, ( cAlias )->ORDPROD,;
                                                ( cAlias )->B1_LM, ( cAlias )->B1_QE, ( cAlias )->B1_LE, ( cAlias )->B1_EMIN,;
                                                nLdTime, cPerfMis, nNecCom, nPrjEst } )

            ( cAlias )->( DbSkip() )
        end
        ( cAlias )->( DbCloseArea() )

    next nChunk

    if ! Empty( cSemLT )
        ConOut( 'JSREVEST - '+ Time() +' - PRODUTOS DA CADEIA SEM LEAD TIME CADASTRADO (B1_PE): '+ cSemLT )
        FWLogMsg( 'WARN', /*cTransactionId*/, 'SMARTSUPPLY', FunName(), '', '03', 'Produtos da cadeia de estruturas sem lead time cadastrado (B1_PE): '+ cSemLT )
    endif

    // Avisa produtos que continuam sem snapshot (não localizados na SB1)
    aPaisAux := {}
    for nX := 1 to len( aFalta )
        aInfPrd := {}
        if ! HMGet( oSnap, aFalta[nX], @aInfPrd )
            aAdd( aPaisAux, AllTrim( aFalta[nX] ) )
        endif
    next nX
    if len( aPaisAux ) > 0
        ConOut( 'JSREVEST - '+ Time() +' - PRODUTOS DA ESTRUTURA NAO LOCALIZADOS NO CADASTRO (SB1): '+ arrToStr( aPaisAux ) )
        FWLogMsg( 'WARN', /*cTransactionId*/, 'SMARTSUPPLY', FunName(), '', '04', 'Produtos da estrutura não localizados no cadastro (SB1): '+ arrToStr( aPaisAux ) )
    endif

return Nil

/*/{Protheus.doc} calcDesc
Executa a descida da necessidade dos produtos finais até os componentes, em ordem topológica,
com netting global por produto: a necessidade bruta de cada nó agrega as contribuições de todos
os seus pais e o abatimento de estoque/OPs em aberto acontece uma única vez por produto contra a
demanda agregada (sem dupla contagem quando o intermediário é compartilhado entre estruturas).
Para produtos finais (raízes) a necessidade líquida é a necessidade convencional calculada pela
fórmula do perfil (snapshot SNAP_NECCOM); para intermediários e componentes, a líquida é
Max(0, bruta - estoque disponível - OPs em aberto).
@type function
@version 20.0002
@author Jean Carlos Pandolfo Saggin
@since 09/07/2026
@param aOrdem, array, códigos em ordem topológica (finais primeiro)
@param oFilhos, object, hashmap pai -> filhos
@param oPais, object, hashmap filho -> pais
@param oSnap, object, hashmap de snapshot por produto
@param aCfgRev, array, configurações internas da filial
@return array, { oBruta, oLiquida, oEstAbt, oOpAbt } - hashmaps por produto
/*/
static function calcDesc( aOrdem, oFilhos, oPais, oSnap, aCfgRev )

    local oBruta   := HMNew()
    local oLiquida := HMNew()
    local oEstAbt  := HMNew()
    local oOpAbt   := HMNew()
    local aSnpAux  := {} as array
    local aPais    := {} as array
    local aFilhos  := {} as array
    local cNode    := "" as character
    local lRaiz    := .F. as logical
    local lTemSnp  := .F. as logical
    local nBruta   := 0 as numeric
    local nLiq     := 0 as numeric
    local nEstDisp := 0 as numeric
    local nEstAbt  := 0 as numeric
    local nOpAbt   := 0 as numeric
    local nAcum    := 0 as numeric
    local nX       := 0 as numeric
    local nY       := 0 as numeric

    for nX := 1 to len( aOrdem )

        cNode   := aOrdem[nX]
        aSnpAux := {}
        lTemSnp := HMGet( oSnap, cNode, @aSnpAux )
        nBruta  := 0
        HMGet( oBruta, cNode, @nBruta )
        aPais := {}
        lRaiz := ! HMGet( oPais, cNode, @aPais )
        nEstAbt := 0
        nOpAbt  := 0

        if ! lTemSnp
            // Produto sem dados (não localizado no cadastro): não gera nem propaga necessidade
            nLiq := 0
        elseif lRaiz
            // Produto final: necessidade convencional pela fórmula do perfil de cálculo
            nLiq := aSnpAux[SNAP_NECCOM]
        else
            // Intermediário/componente: abate estoque disponível e OPs em aberto da demanda agregada
            nEstDisp := aSnpAux[SNAP_ESTOQUE]
            if aCfgRev[24] == 'S'
                nEstDisp -= aSnpAux[SNAP_EMPENHO]
            endif
            if nEstDisp < 0
                nEstDisp := 0
            endif
            nEstAbt := Min( nEstDisp, nBruta )
            nOpAbt  := Min( aSnpAux[SNAP_ORDPROD], nBruta - nEstAbt )
            nLiq    := nBruta - nEstAbt - nOpAbt
        endif

        HMSet( oBruta, cNode, nBruta )
        HMSet( oLiquida, cNode, nLiq )
        HMSet( oEstAbt, cNode, nEstAbt )
        HMSet( oOpAbt, cNode, nOpAbt )

        // Propaga a necessidade líquida para os componentes multiplicando pela quantidade da estrutura
        if nLiq > 0
            aFilhos := {}
            if HMGet( oFilhos, cNode, @aFilhos )
                for nY := 1 to len( aFilhos )
                    nAcum := 0
                    HMGet( oBruta, aFilhos[nY][1], @nAcum )
                    HMSet( oBruta, aFilhos[nY][1], nAcum + ( nLiq * aFilhos[nY][2] ) )
                next nY
            endif
        endif

    next nX

return { oBruta, oLiquida, oEstAbt, oOpAbt }

/*/{Protheus.doc} saveAll
Materializa o resultado da análise reversa: para cada componente (produto que possui pais na
estrutura) grava o resultado consolidado na PNC_RVCALC (sugestão reversa com parcela de venda
direta, abatimento de posição e ajustes de lote) e o trace da sequência de cálculo na PNC_RVTRC
(árvore ascendente do componente até os produtos finais). Regrava integralmente a execução da
filial: o trace guarda apenas a última execução e o resultado é regravado por filial + data.
@type function
@version 20.0002
@author Jean Carlos Pandolfo Saggin
@since 09/07/2026
@param aOrdem, array, códigos em ordem topológica
@param oPais, object, hashmap filho -> pais
@param oSnap, object, hashmap de snapshot por produto
@param aCalc, array, { oBruta, oLiquida, oEstAbt, oOpAbt } calculados em calcDesc
@param aCfgRev, array, configurações internas da filial
@param dCalc, date, data de referência do cálculo
@param cTabCal, character, nome físico da tabela de resultado (PNC_RVCALC_<empresa>)
@param cTabTrc, character, nome físico da tabela de trace (PNC_RVTRC_<empresa>)
@return logical, lSucesso
/*/
static function saveAll( aOrdem, oPais, oSnap, aCalc, aCfgRev, dCalc, cTabCal, cTabTrc )

    local lSucesso := .T. as logical
    local oBruta   := aCalc[1]
    // local oLiquida := aCalc[2]
    local aSnpAux  := {} as array
    local aPais    := {} as array
    local aTrace   := {} as array
    local aFinais  := {} as array
    local cAliCal  := "" as character
    local cAliTrc  := "" as character
    local cQuery   := "" as character
    local cDtExec  := DtoS( Date() ) + StrTran( Time(), ':', '' )
    local cProd    := "" as character
    local lPriLE   := aCfgRev[19] == 'S'
    local nTamB1   := TAMSX3( 'B1_COD' )[1]
    local nVenDia  := 0 as numeric
    local nConDia  := 0 as numeric
    local nDemEst  := 0 as numeric
    local nDemVnd  := 0 as numeric
    local nEstDisp := 0 as numeric
    local nPosAbt  := 0 as numeric
    local nNecRev  := 0 as numeric
    local nGravado := 0 as numeric
    local nX       := 0 as numeric
    local nY       := 0 as numeric

    // Limpa a execução anterior: trace guarda somente a última execução da filial
    cQuery := "DELETE FROM "+ cTabTrc +" WHERE FILIAL = '"+ cFilAnt +"' "
    if TcSQLExec( cQuery ) < 0
        ConOut( 'JSREVEST - '+ Time() +' - ERRO AO LIMPAR TRACE ANTERIOR: '+ TCSQLError() )
        FWLogMsg( 'ERROR', /*cTransactionId*/, 'SMARTSUPPLY', FunName(), '', '05', 'Erro ao limpar trace anterior da análise reversa: '+ TCSQLError() )
        return .F.
    endif
    cQuery := "DELETE FROM "+ cTabCal +" WHERE FILIAL = '"+ cFilAnt +"' AND DTCALC = '"+ DtoS( dCalc ) +"' "
    if TcSQLExec( cQuery ) < 0
        ConOut( 'JSREVEST - '+ Time() +' - ERRO AO LIMPAR RESULTADO ANTERIOR: '+ TCSQLError() )
        FWLogMsg( 'ERROR', /*cTransactionId*/, 'SMARTSUPPLY', FunName(), '', '06', 'Erro ao limpar resultado anterior da análise reversa: '+ TCSQLError() )
        return .F.
    endif

    cAliCal := GetNextAlias()
    DBUseArea( .T., 'TOPCONN', cTabCal, cAliCal, .F., .F. )
    cAliTrc := GetNextAlias()
    DBUseArea( .T., 'TOPCONN', cTabTrc, cAliTrc, .F., .F. )

    for nX := 1 to len( aOrdem )

        cProd := aOrdem[nX]
        aPais := {}
        if ! HMGet( oPais, cProd, @aPais )
            loop        // Produto final (raiz): não recebe sugestão reversa
        endif
        aSnpAux := {}
        if ! HMGet( oSnap, cProd, @aSnpAux )
            loop        // Sem dados do produto: mantém fluxo convencional na tela (sem registro)
        endif

        // Demanda derivada das estruturas + parcela de venda direta do próprio componente
        nDemEst := 0
        HMGet( oBruta, cProd, @nDemEst )
        nVenDia := Round( aSnpAux[SNAP_VENDA] / aSnpAux[SNAP_DIAS], 4 )
        nConDia := Round( aSnpAux[SNAP_CONSUMO] / aSnpAux[SNAP_DIAS], 4 )
        nDemVnd := nVenDia * ( aCfgRev[01] + aSnpAux[SNAP_LEADTIME] )

        // Posição abatida no nível do componente: estoque disponível + pedidos em carteira + solicitações
        nEstDisp := aSnpAux[SNAP_ESTOQUE]
        if aCfgRev[24] == 'S'
            nEstDisp -= aSnpAux[SNAP_EMPENHO]
        endif
        if nEstDisp < 0
            nEstDisp := 0
        endif
        nPosAbt := nEstDisp + aSnpAux[SNAP_QTDCOMP] + aSnpAux[SNAP_QTDSOL]

        // Sugestão reversa final com ajustes de lote (mesma sequência do cálculo convencional)
        nNecRev := Round( nDemEst + nDemVnd - nPosAbt, 0 )
        if nNecRev < 0
            nNecRev := 0
        endif
        nNecRev := U_JSAPLLOT( nNecRev, aSnpAux[SNAP_LOTMIN], aSnpAux[SNAP_LOTECO], aSnpAux[SNAP_QTDEMB], lPriLE )

        // Trace da sequência de cálculo (árvore ascendente do componente até os finais)
        aFinais := {}
        aTrace  := traceMP( cProd, oPais, aCalc, oSnap, @aFinais )

        RecLock( cAliCal, .T. )
        ( cAliCal )->( FieldPut( FieldPos( 'FILIAL' ), cFilAnt ) )
        ( cAliCal )->( FieldPut( FieldPos( 'PROD'   ), PADR( cProd, nTamB1, ' ' ) ) )
        ( cAliCal )->( FieldPut( FieldPos( 'DTCALC' ), DtoS( dCalc ) ) )
        ( cAliCal )->( FieldPut( FieldPos( 'ISCOMP' ), 'S' ) )
        ( cAliCal )->( FieldPut( FieldPos( 'NECREV' ), nNecRev ) )
        ( cAliCal )->( FieldPut( FieldPos( 'DEMESTR' ), Round( nDemEst, 2 ) ) )
        ( cAliCal )->( FieldPut( FieldPos( 'DEMVND' ), Round( nDemVnd, 2 ) ) )
        ( cAliCal )->( FieldPut( FieldPos( 'VENDIA' ), nVenDia ) )
        ( cAliCal )->( FieldPut( FieldPos( 'CONDIA' ), nConDia ) )
        ( cAliCal )->( FieldPut( FieldPos( 'POSABT' ), Round( nPosAbt, 2 ) ) )
        ( cAliCal )->( FieldPut( FieldPos( 'NFINAIS' ), len( aFinais ) ) )
        ( cAliCal )->( FieldPut( FieldPos( 'DTEXEC' ), cDtExec ) )
        ( cAliCal )->( MsUnlock() )

        for nY := 1 to len( aTrace )
            RecLock( cAliTrc, .T. )
            ( cAliTrc )->( FieldPut( FieldPos( 'FILIAL' ), cFilAnt ) )
            ( cAliTrc )->( FieldPut( FieldPos( 'MP'     ), PADR( cProd, nTamB1, ' ' ) ) )
            ( cAliTrc )->( FieldPut( FieldPos( 'DTCALC' ), DtoS( dCalc ) ) )
            ( cAliTrc )->( FieldPut( FieldPos( 'SEQ'    ), StrZero( nY, 6 ) ) )
            ( cAliTrc )->( FieldPut( FieldPos( 'NIVEL'  ), aTrace[nY][1] ) )
            ( cAliTrc )->( FieldPut( FieldPos( 'PAI'    ), PADR( aTrace[nY][2], nTamB1, ' ' ) ) )
            ( cAliTrc )->( FieldPut( FieldPos( 'PROD'   ), PADR( aTrace[nY][3], nTamB1, ' ' ) ) )
            ( cAliTrc )->( FieldPut( FieldPos( 'QTPOR'  ), aTrace[nY][4] ) )
            ( cAliTrc )->( FieldPut( FieldPos( 'NECBRT' ), Round( aTrace[nY][5], 2 ) ) )
            ( cAliTrc )->( FieldPut( FieldPos( 'ESTABT' ), Round( aTrace[nY][6], 2 ) ) )
            ( cAliTrc )->( FieldPut( FieldPos( 'OPABT'  ), Round( aTrace[nY][7], 2 ) ) )
            ( cAliTrc )->( FieldPut( FieldPos( 'NECLIQ' ), Round( aTrace[nY][8], 2 ) ) )
            ( cAliTrc )->( FieldPut( FieldPos( 'CONTRIB' ), Round( aTrace[nY][9], 2 ) ) )
            ( cAliTrc )->( FieldPut( FieldPos( 'TIPO'   ), aTrace[nY][10] ) )
            ( cAliTrc )->( MsUnlock() )
        next nY

        nGravado++
        if ( nGravado % 100 ) == 0
            ConOut( 'JSREVEST - '+ Time() +' - '+ cValToChar( nGravado ) +' COMPONENTES MATERIALIZADOS...' )
        endif

    next nX

    ( cAliCal )->( DbCloseArea() )
    ( cAliTrc )->( DbCloseArea() )

    ConOut( 'JSREVEST - '+ Time() +' - ANALISE REVERSA MATERIALIZADA PARA '+ cValToChar( nGravado ) +' COMPONENTES' )

return lSucesso

/*/{Protheus.doc} traceMP
Monta as linhas de trace da sequência de cálculo de um componente: percorre a árvore ascendente
(componente no nível zero, pais diretos no nível um, subindo até os produtos finais) em
profundidade, devolvendo por nó os números globais do produto (bruta, abatimentos e líquida) e a
contribuição da ligação (líquida do nó multiplicada pela quantidade da estrutura). Nós que
participam de ciclo (sem necessidade calculada) são ignorados. A quantidade de linhas é limitada
por MAX_LINHAS e a profundidade por MAX_NIVEL.
@type function
@version 20.0002
@author Jean Carlos Pandolfo Saggin
@since 09/07/2026
@param cMP, character, código do componente auditado
@param oPais, object, hashmap filho -> pais
@param aCalc, array, { oBruta, oLiquida, oEstAbt, oOpAbt }
@param oSnap, object, hashmap de snapshot por produto
@param aFinais, array, devolve por referência os códigos distintos dos produtos finais da cadeia
@return array, linhas { nivel, pai, produto, qtpor, necbrt, estabt, opabt, necliq, contrib, tipo }
/*/
static function traceMP( cMP, oPais, aCalc, oSnap, aFinais )

    local oBruta   := aCalc[1]
    local oLiquida := aCalc[2]
    local oEstAbt  := aCalc[3]
    local oOpAbt   := aCalc[4]
    local oFinal   := HMNew()
    local aRows    := {} as array
    local aStack   := {} as array
    local aNo      := {} as array
    local aPais    := {} as array
    local cProd    := "" as character
    local cTipo    := "" as character
    local lCalc    := .F. as logical
    local nNivel   := 0 as numeric
    local nQtPor   := 0 as numeric
    local nBruta   := 0 as numeric
    local nLiq     := 0 as numeric
    local nEstAbt  := 0 as numeric
    local nOpAbt   := 0 as numeric
    local nX       := 0 as numeric
    local xDummy   := Nil

    default aFinais := {}

    // Pilha de navegação: { produto, nivel, produto do nível anterior (PAI), quantidade da ligação }
    aAdd( aStack, { cMP, 0, '', 0 } )

    while len( aStack ) > 0 .and. len( aRows ) < MAX_LINHAS

        aNo := aStack[len(aStack)]
        aSize( aStack, len(aStack)-1 )

        cProd  := aNo[1]
        nNivel := aNo[2]
        nQtPor := aNo[4]

        nBruta  := 0
        nLiq    := 0
        nEstAbt := 0
        nOpAbt  := 0
        HMGet( oBruta, cProd, @nBruta )
        HMGet( oLiquida, cProd, @nLiq )
        HMGet( oEstAbt, cProd, @nEstAbt )
        HMGet( oOpAbt, cProd, @nOpAbt )

        aPais := {}
        if nNivel == 0
            cTipo := 'M'        // Componente auditado
            aAdd( aRows, { nNivel, aNo[3], cProd, nQtPor, nBruta, 0, 0, 0, 0, cTipo } )
        elseif HMGet( oPais, cProd, @aPais )
            cTipo := 'I'        // Intermediário: possui pais na estrutura
            aAdd( aRows, { nNivel, aNo[3], cProd, nQtPor, nBruta, nEstAbt, nOpAbt, nLiq, nLiq * nQtPor, cTipo } )
        else
            cTipo := 'F'        // Produto final (raiz da cadeia)
            aAdd( aRows, { nNivel, aNo[3], cProd, nQtPor, nLiq, 0, 0, nLiq, nLiq * nQtPor, cTipo } )
            if ! HMGet( oFinal, cProd, @xDummy )
                HMSet( oFinal, cProd, .T. )
                aAdd( aFinais, cProd )
            endif
        endif

        // Empilha os pais do nó (nível acima), ignorando produtos sem cálculo (participantes de ciclo)
        if nNivel < MAX_NIVEL
            aPais := {}
            if HMGet( oPais, cProd, @aPais )
                for nX := 1 to len( aPais )
                    lCalc := HMGet( oLiquida, aPais[nX][1], @xDummy )
                    if lCalc
                        aAdd( aStack, { aPais[nX][1], nNivel+1, cProd, aPais[nX][2] } )
                    endif
                next nX
            endif
        endif

    end

    if len( aStack ) > 0
        ConOut( 'JSREVEST - '+ Time() +' - TRACE DO COMPONENTE '+ AllTrim( cMP ) +' TRUNCADO EM '+ cValToChar( MAX_LINHAS ) +' LINHAS' )
    endif

return aRows

/*/{Protheus.doc} inChunks
Divide uma lista de códigos em blocos de expressões prontas para cláusulas IN () de SQL,
respeitando o limite TAM_CHUNK de itens por bloco.
@type function
@version 20.0002
@author Jean Carlos Pandolfo Saggin
@since 09/07/2026
@param aCodes, array, códigos a serem divididos
@return array, blocos no formato "'COD1','COD2',..."
/*/
static function inChunks( aCodes )

    local aChunks := {} as array
    local cChunk  := "" as character
    local nItens  := 0 as numeric
    local nX      := 0 as numeric

    for nX := 1 to len( aCodes )
        if Empty( cChunk )
            cChunk := "'"+ aCodes[nX] +"'"
        else
            cChunk += ",'"+ aCodes[nX] +"'"
        endif
        nItens++
        if nItens >= TAM_CHUNK
            aAdd( aChunks, cChunk )
            cChunk := ""
            nItens := 0
        endif
    next nX
    if ! Empty( cChunk )
        aAdd( aChunks, cChunk )
    endif

return aChunks

/*/{Protheus.doc} countDaysR
Conta a quantidade de dias de uma faixa de datas (úteis ou corridos) conforme a configuração
TPDIAS da filial - mesma régua utilizada pelo recálculo de índices (countDays do GMPAICOM).
@type function
@version 20.0002
@author Jean Carlos Pandolfo Saggin
@since 09/07/2026
@param dDe, date, data inicial
@param dAte, date, data final
@param aCfgRev, array, configurações internas da filial
@return numeric, nDays
/*/
static function countDaysR( dDe, dAte, aCfgRev )

    local nDays := 0 as numeric

    if aCfgRev[15] == 'U'
        nDays := DateWorkDay( dDe, dAte, .T. /* lSaturday */, .F. /* lSunday */, .F. /* lHoliday */ )
    elseif aCfgRev[15] == 'C'
        nDays := DateWorkDay( dDe, dAte, .T. /* lSaturday */, .T. /* lSunday */, .T. /* lHoliday */ )
    endif

return nDays

/*/{Protheus.doc} arrToStr
Converte um vetor de códigos em uma string separada por vírgulas para exibição em logs.
@type function
@version 20.0002
@author Jean Carlos Pandolfo Saggin
@since 09/07/2026
@param aCodes, array, códigos
@return character, cLista
/*/
static function arrToStr( aCodes )

    local cLista := "" as character
    local nX     := 0 as numeric

    for nX := 1 to len( aCodes )
        if Empty( cLista )
            cLista := AllTrim( aCodes[nX] )
        else
            cLista += ', '+ AllTrim( aCodes[nX] )
        endif
    next nX

return cLista
