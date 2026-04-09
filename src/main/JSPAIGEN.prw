#include 'totvs.ch'
#include 'topconn.ch'
#include 'fwmvcdef.ch'
#include 'tbiconn.ch'
#include 'tbicode.ch'

#define CEOL Chr(13)+Chr(10)

/*/{Protheus.doc} JSGETVER
Retorna a versão do aplicativo.
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 30/08/2024
@return character, cDetVer
/*/
user function JSGETVER()

    local cDetVer := "" as character
    local aDetVer := {} as array
    aDetVer := U_JSDETVER()
    cDetVer := aDetVer[len(aDetVer)][1] /* cDictVersion */ +'.'+;
                aDetVer[len(aDetVer)][2] /* cAppVersion */+' ('+;
                aDetVer[len(aDetVer)][3] /* cDate */+')'
return cDetVer

/*/{Protheus.doc} JSDICVER
Retorna a versão do dicionário de dados e da rotina que está em uso
@type function
@version 12.1.2410
@author Jean Carlos Pandolfo Saggin
@since 20/01/2026
@return character, cDicVer
/*/
user function JSDICVER()
    local cDicVer := "" as character
    local aDetVer := {} as array
    aDetVer := U_JSDETVER()
    cDicVer := aDetVer[len(aDetVer)][1]
return cDicVer

/*/{Protheus.doc} JSDETVER
Função com detalhamento das versões do aplicativo.
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 30/08/2024
@return array, aDetVer
/*/
user function JSDETVER()

    local aDetVer := {} as array
    aAdd( aDetVer, { '01','0001','18/09/2024', 'Versão inicial do Painel de Compras' } )
    aAdd( aDetVer, { '02','0002','20/09/2024', 'Permite informar valor de frete ao pedido de compra e também informar um código de transportadora relacionado ao processo.' } )
    aAdd( aDetVer, { '02','0003','20/09/2024', 'Permitir informar frete em percentual' } )
    aAdd( aDetVer, { '02','0004','21/09/2024', 'Permitir editar alíquota de IPI diretamente no carrinho' } )
    aAdd( aDetVer, { '02','0005','03/10/2024', 'Liberar edição de campos para simulação de preço na tela de consulta de notas' } )
    aAdd( aDetVer, { '03','0006','06/10/2024', 'Permitir definir índice de lucro desejável por produto' } )
    aAdd( aDetVer, { '04','0001','16/10/2024', 'Controle de execução do JOB de recálculo dos índices individuais dos produtos' } )
    aAdd( aDetVer, { '04','0002','17/10/2024', 'Painel de Compras Multi-Filial' } )
    aAdd( aDetVer, { '05','0001','12/11/2024', 'Adaptação para release 12.1.2410 usando smartclient webapp' } )
    aAdd( aDetVer, { '05','0002','13/11/2024', 'Novo formato de filtros, remodelagem da engine de cálculos e substituição de componentes obsoletos' } )
    aAdd( aDetVer, { '05','0003','13/11/2024', 'Workflow automático para fornecedor' } )
    aAdd( aDetVer, { '06','0001','21/11/2024', 'Adição de rotina para recálculo manual dos índices dos produtos, adequações de consultas do recálculo por JOB' } )
    aAdd( aDetVer, { '07','0001','02/01/2025', 'Novas melhorias no motor de cálculo de necessidade de compra, workflow de ruptura, nova feature de formação de preços' } )
    aAdd( aDetVer, { '07','0002','03/01/2025', 'Ajustar máscara do campo consumo médio e ajustado query de consulta de pedidos em carteira' } )
    aAdd( aDetVer, { '07','0003','13/01/2025', 'Ajuste refresh da tela de formação de preços, acesso a formação de preços pelo documento de entrada, '+;
                                                'alinhamento de labels na tela de formação de preços.' } )
    aAdd( aDetVer, { '08','0001','14/01/2025', 'Incluído tratativa a parâmetro para indicar se o usuário tem acesso para gravar novo preço de venda, '+;
                                                'Ajuste na chamada do botão Tornar Padrão para gravar o conteúdo e fazer refresh corretamente.' } )
    aAdd( aDetVer, { '08','0002','15/01/2025', 'Ajuste do filtro por grupo de produto, implementação de tela para detalhamento do consumo do produto.' } )
    aAdd( aDetVer, { '09','0001','16/01/2025', 'Rotina para formação de preços separada do Documento de Entrada.' } )
    aAdd( aDetVer, { '09','0002','20/01/2025', 'Edição de browse para permitir ocultar campos desnecessários do browse conforme necessidade do usuário.' } )
    aAdd( aDetVer, { '09','0003','20/01/2025', 'Valida resolução de tela utilizada pelo equipamento.' } )
    aAdd( aDetVer, { '09','0004','21/01/2025', 'Melhorias gráficas na tela de formação de preços para evitar distorção de componentes.' } )
    aAdd( aDetVer, { '09','0005','21/01/2025', 'Ajuste na tela de visualização de saídas para evitar falha no cálculo de média quando o produto não contém movimentações no período analisado.' } )
    aAdd( aDetVer, { '10','0001','21/01/2025', 'Adicionado parâmetro nas configurações indicar se a empresa vai considerar o empenho para obter o saldo atual de estoque.' } )
    aAdd( aDetVer, { '11','0001','23/01/2025', 'Implementado novo índice na tabela SF1 para agilizar abertura da tela de formação de preços' } )
    aAdd( aDetVer, { '11','0002','24/01/2025', 'Realizado ajuste para permitir que usuário informe o centro de custos durante fechamento do carrinho de compra' } )
    aAdd( aDetVer, { '11','0003','06/02/2025', 'Implementado impressão de relatório do browse de produtos' } )
    aAdd( aDetVer, { '11','0003','08/02/2025', 'Incluído botão para desconsiderar produto do MRP' } )
    aAdd( aDetVer, { '12','0001','13/02/2025', 'Remover campos de empresa e filial da tabela de parâmetros gerais, trazer ultimo diretório utilizado na rotina de transferência '+;
                                                'de arquivos do server para o cliente e do cliente para o server.' } )
    aAdd( aDetVer, { '12','0002','13/02/2025', 'Implementado função para obter vínculo entre produto x fornecedor através de arquivo .csv' } )
    aAdd( aDetVer, { '12','0003','14/02/2025', 'Implementação de conexão com banco web para obter dados de configurações por meio de API, '+;
                                                'remoção de função de copia para servidor e cópia para diretório local' } )
    aAdd( aDetVer, { '12','0004','18/02/2025', 'Adicionado funcionalidade para permitir eliminar resíduo de um determinado produto quando o fornecedor não vai mais atendê-lo.' } )
    aAdd( aDetVer, { '12','0005','20/02/2025', 'Correção de bug ao excluir o último pedido listado na tela de pedidos em aberto para o produto' } )
    aAdd( aDetVer, { '12','0006','20/02/2025', 'Ajuste de bug no browse de fornecedores ao alterar leadtime informado' } )
    aAdd( aDetVer, { '12','0007','20/02/2025', 'Adicionado proporção de 60% para o tamanho das colunas do browse de produtos em relação ao tamanho físico do campo no dicionário de dados' } )
    aAdd( aDetVer, { '12','0008','20/02/2025', 'Ajuste para o sistema trazer o lead-time default do fornecedor quando não houver leadtime definido para o produto' } )
    aAdd( aDetVer, { '12','0009','21/02/2025', 'Ajuste de espaçamento no código do fornecedor na função de importação da relação de produto versus fornecedor' } )
    aAdd( aDetVer, { '12','0010','22/02/2025', 'Alteração para que, quando o produto for colocado no carrinho por meio do alt+x, a linha do grid de produtos seja atualizada' } )
    aAdd( aDetVer, { '12','0011','22/02/2025', 'Permitir alterar a quantidade diretamente no campo do browse do produto quando não for utilizado compra multi-filial' } )
    aAdd( aDetVer, { '13','0001','21/02/2025', 'Implementação do conceito de perfis de cálculo' } )
    aAdd( aDetVer, { '13','0002','25/02/2025', 'Vínculo de perfil de cálculo com o produto para recálculos via JOB' } )
    aAdd( aDetVer, { '13','0003','25/02/2025', 'Vínculo automático de produto versus fornecedor ao informar fornecedor e loja na linha do produto' } )
    aAdd( aDetVer, { '13','0004','26/02/2025', 'Ajuste para corrigir error-log durante recálculo de índices por produto através de JOB' } )
    aAdd( aDetVer, { '13','0006','27/02/2025', 'Correção do cálculo de dias úteis para elaboração da média diária de compras' } )
    aAdd( aDetVer, { '14','0001','27/02/2025', 'Configuração para eliminação automática do histórico de cálculo de compras por produto' } )
    aAdd( aDetVer, { '14','0002','27/02/2025', 'Permitir informar observações por item no pedido de compras, trazer condição de pagamento pré-definida para o fornecedor' } )
    aAdd( aDetVer, { '14','0003','27/02/2025', 'Adicionados dois novos pontos de entrada que permitem manipular o aCols e o aHeader do carrinho de compras' } )
    aAdd( aDetVer, { '14','0004','27/02/2025', 'Ajustado funções internas de cálculo para considerar a variável Estoque Mínimo nos cálculos de duranção do estoque' } )
    aAdd( aDetVer, { '14','0005','27/02/2025', 'Trazer preço de tabela, quando o produto estiver em uma tabela de preços do fornecedor' } )
    aAdd( aDetVer, { '14','0006','02/03/2025', 'Removido validação de resolução de tela após reprogramação do dimensionamento de objetos' } )
    aAdd( aDetVer, { '14','0007','04/03/2025', 'Permitir alteração da quantidade para itens com pedidos bloqueados para análise' } )
    aAdd( aDetVer, { '14','0008','06/03/2025', 'Implementado rastreio de posicionamento de colunas de modo dinâmico para vetores do carrinho de compras' } )
    aAdd( aDetVer, { '14','0009','06/03/2025', 'Permitir informar quantidade zerada no campo de quantidade bloqueada.' } )
    aAdd( aDetVer, { '14','0010','06/03/2025', 'Ajuste de dimensionamento dos componentes da tela do carrinho de compras' } )
    aAdd( aDetVer, { '14','0011','07/03/2025', 'Correção de falha no momento da troca de fornecedor do carrinho em que o sistema não substitui o campo da loja' } )
    aAdd( aDetVer, { '14','0012','07/03/2025', 'Restauração de atalhos da tela principal após acessar tela de pedidos em aberto' } )
    aAdd( aDetVer, { '14','0013','07/03/2025', 'Abertura de Ponto de Entrada para gravação de campos adicionais no pedido de compra' } )
    aAdd( aDetVer, { '14','0014','14/03/2025', 'Abertura de Ponto de entrada para manipulação do saldo atual de estoque e ajustes pontuais para utilização da segunda unidade de medida no carrinho de compra' } )
    aAdd( aDetVer, { '14','0015','17/03/2025', 'Correção de denominação de alíases em cláusulas SQL em brancos SQLServer' } )
    aAdd( aDetVer, { '14','0016','18/03/2025', 'Permitir edição de campos de valor unitário e quantidade na segunda unidade de medido por meio do carrinho de compras' } )
    aAdd( aDetVer, { '14','0017','20/03/2025', 'Ajuste na regra para exibir apenas produtos com risco de ruptura e inclusão de totalizadores quantitativos pela primeira e segunda unidade de medida no carrinho.' } )
    aAdd( aDetVer, { '14','0018','20/03/2025', 'Correção de falha na execauto do pedido de compra' } )
    aAdd( aDetVer, { '14','0019','20/03/2025', 'Correção de error-log ao alterar o índice de IPI do produto no carrinho' } )
    aAdd( aDetVer, { '14','0020','20/03/2025', 'Permitir consultar fornecedores ligados ao produto' } )
    aAdd( aDetVer, { '14','0021','26/03/2025', 'Validações para evitar error-log ao tentar acessar funções auxiliares sem produtos carregados no browse' } )
    aAdd( aDetVer, { '14','0022','26/03/2025', 'Correção de error-log ao acessar rotina de consulta de empenhos' } )
    aAdd( aDetVer, { '14','0023','29/03/2025', 'Ajuste na função de replicação de dados do carrinho para que o sistema atualize os demais campos além dos que estão sendo replicados' } )
    aAdd( aDetVer, { '15','0001','03/04/2025', 'Ajuste da forma de leitura do frete complementar dos documentos de entrada e também valor financeiro adicional agregado ao custo do produto' } )
    aAdd( aDetVer, { '15','0002','08/04/2025', 'Ajustes na função de replicação de dados por meio do atalho CTRL_R para que todos os gatilhos do carrinho de compras sejam disparados, '+;
                                               'Ajuste do processo de vínculo de produto com fornecedor para ignorar quando uma das informações (fornecedor ou loja estiverem vazios), '+;
                                               'Força escolha de um fornecedor quando usuário tentar adicionar ao carrinho um produto sem fornecedor, ' +;
                                               'Permite remover vínculo de produto x fornecedor através da tela de seleção de fornecedor.' } )
    aAdd( aDetVer, { '16','0001','12/04/2025', 'Adequado rotina para ser possível gerar solicitação de compras a partir do painel.' } )
    aAdd( aDetVer, { '16','0002','16/04/2025', 'Criado tela para consulta de solicitações pendentes' } )
    aAdd( aDetVer, { '16','0003','22/04/2025', 'Inclusão de gatilho no campo de alteração de fornecedor para atualizar preço de compra sugerido' } )
    aAdd( aDetVer, { '16','0004','25/04/2025', 'Ajuste da formulação da rotina de formação de preços para considerar o percentual de acréscimo financeiro apenas após todos os outros custos' } )
    aAdd( aDetVer, { '16','0005','05/05/2025', 'Ajuste para permitir usuário informar comprador no momento da inclusão da solicitação de compra' } )
    aAdd( aDetVer, { '16','0006','05/05/2025', 'Ajustado para permitir informar desconto no pedido de compras' } )
    aAdd( aDetVer, { '16','0007','06/05/2025', 'Adição regra para disparo de workflow ao comprador quando ocorrer inclusão de solicitação com comprador já definido' } )
    aAdd( aDetVer, { '16','0008','07/05/2025', 'Ajuste de algoritmo para definir melhor fornecedor quando usuário pesquisar por um fornecedor em específico' } )
    aAdd( aDetVer, { '16','0009','10/05/2025', 'Ajuste de falha no somatório do estoque quando compra multi-filial' } )
    aAdd( aDetVer, { '16','0010','11/05/2025', 'Permitir excluir pedidos de filial diferente da que o usuário estiver posicionado' } )
    aAdd( aDetVer, { '16','0011','12/05/2025', 'Adicionar configuração para usuário poder informar transportadora ou fornecedor atrelado ao frete no pedido de compra' } )
    aAdd( aDetVer, { '16','0012','13/05/2025', 'Ajustado tratativa de geracão do pedido para que o mesmo seja sempre gerado na filial em que o usuário está posicionado, porém, com entrega na filial de destino quando a compra é multi-filial' } )
    aAdd( aDetVer, { '16','0013','14/05/2025', 'Adição de somatório totalizador na tela de edição de quantidades quando a compra for multi-filial' } )
    aAdd( aDetVer, { '16','0014','15/05/2025', 'Ajuste do cálculo do ICMS na formação de preço, redistribuição dos componentes da tela de formação de preço com FWDefSize' } )
    aAdd( aDetVer, { '16','0015','16/05/2025', 'Alteração de sinal (positivo/negativo) quando houver crédito de imposto na entrada (formação de preços)' } )
    aAdd( aDetVer, { '16','0016','16/05/2025', 'Adição do ponto de entrada PEPNC05 para permitir manipular as colunas do browse de produtos' } )
    aAdd( aDetVer, { '16','0017','04/08/2025', 'Ajuste no recálculo de índices por produto para evitar falha quando término do cálculo ocorre no dia seguinte' } )
    aAdd( aDetVer, { '16','0018','19/08/2025', 'Novos campos na tabela de empenhos do produto' } )
    aAdd( aDetVer, { '17','0001','20/08/2025', 'Implementação de novo layout de pedido de compras' } )
    aAdd( aDetVer, { '17','0002','22/08/2025', 'Alterado tratativas para gravação de pedido na filial de entrega ao invés de utilizar campo filial de destino' } )
    aAdd( aDetVer, { '17','0003','10/09/2025', 'Implementado melhoria para exibir detalhamentos no gráfico de análise de médias mensais' } )
    aAdd( aDetVer, { '17','0004','11/09/2025', 'Melhoria para permitir impressão dos dados de detalhamento do gráfico de médias' } )
    aAdd( aDetVer, { '17','0005','11/09/2025', 'Ajustes pontuais no relatório de pedido para exibir o grupo de compra do produto e também corrigido falha de impressão dos dados do transportador' } )
    aAdd( aDetVer, { '17','0006','12/09/2025', 'Adição de botão para consulta do kardex do produto na tela principal' } )
    aAdd( aDetVer, { '17','0007','12/09/2025', 'Correção de falha durante gravação da observação quando compra multi-filial.' } )
    aAdd( aDetVer, { '18','0001','23/09/2025', 'Criado função "Continuar de onde parou..."' } )
    aAdd( aDetVer, { '18','0002','25/09/2025', 'Ajustes na rotina de formação de preços no processo de simulação de preço de venda' } )
    aAdd( aDetVer, { '18','0003','30/09/2025', 'Adição de função Executar que permite rodar scripts em sintaxe SQL ou funções advpl através da interface do usuário' } )
    aAdd( aDetVer, { '18','0004','30/09/2025', 'Criação de PE para substituição de produto na formação de preços' } )
    aAdd( aDetVer, { '18','0005','02/10/2025', 'Corrigido falha que fazia com que, nos pedidos multi-filiais, ao editar as quantidades por filial, o sistema atualizasse o browse de produtos por completo.' } )
    aAdd( aDetVer, { '18','0006','03/10/2025', 'Removido do execauto do pedido de compra, o campo C7_DESCRI, para evitar validação padrão sobre o campo que, hora ou outra, apresentava inconsistências.' } )
    aAdd( aDetVer, { '18','0007','04/10/2025', 'Corrigido cálculo do valor total do pedido de compra na tela do carrinho devido a erro no cálculo do valor do IPI individual de cada produto.' } )
    aAdd( aDetVer, { '18','0008','06/10/2025', 'Ajuste para leitura e exibição do cálculo do IPI quando empresa tem crédito na entrada.' } )
    aAdd( aDetVer, { '18','0009','20/10/2025', 'Correção de error-log na rotina de execução automática do cálculo de índices por produto' } )
    aAdd( aDetVer, { '18','0010','29/10/2025', 'Ajuste da quebra de página no relatório do pedido de compra que estava suprimindo alguns itens' } )
    aAdd( aDetVer, { '18','0011','30/10/2025', 'Habilitado configuração que torna opcional o uso da nova versão do relatório do pedido de compra em PDF' } )
    aAdd( aDetVer, { '18','0012','31/10/2025', 'Correção de bug que impede a criação de novos campos via PE no carrinho de compras' } )
    aAdd( aDetVer, { '18','0013','26/11/2025', 'Adição de cláusula para ignorar documentos de venda/transferência entre empresas do mesmo grupo no processo de formação de preços' } )
    aAdd( aDetVer, { '18','0014','01/12/2025', 'Ajuste no somatório do pedido de compras quando impresso por meio do modelo padrão do Painel.' } )
    aAdd( aDetVer, { '18','0015','01/12/2025', 'Ajuste na disposição da grid de produtos para permitir ao usuário arrastar para o lado utilizando mouse' } )
    aAdd( aDetVer, { '18','0016','02/12/2025', 'Ajuste de espaçamento dos campos da grid de produtos para melhor aproveitamento de espaço da tela' } )
    aAdd( aDetVer, { '18','0017','04/12/2025', 'Ajustado cálculo de dias para consumo médio quando tipo de período analisado for Dias Corridos' } )
    aAdd( aDetVer, { '18','0018','05/12/2025', 'Criado ponto de entrada para permitir que o cliente altere configurações dos campos da grid de acordo com sua necessidade' } )
    aAdd( aDetVer, { '18','0019','05/12/2025', 'Adicionado regra de ordenação no grid de produtos para que o sistema sempre traga os dados ordenados pela descrição' } )
    aAdd( aDetVer, { '18','0020','20/01/2026', 'Ajuste para exibir código do produto em que está sendo formado o preço de venda junto da descrição do mesmo' } )
    aAdd( aDetVer, { '18','0021','20/01/2026', 'Permitir acessar o kardex do produto por dentro da tela de formação de preços' } )
    aAdd( aDetVer, { '18','0022','20/01/2026', 'Permitir salvar índice padrão para IPI de saída na tela de formação de preços.' } )
    aAdd( aDetVer, { '18','0023','21/01/2026', 'Adicionado tratativa para que a rotina delimite a quantidade de análise de giro dos produtos quando o tempo '+;
                                                'configurado for maior do que o tempo de operações da unidade' } )
    aAdd( aDetVer, { '18','0024','22/01/2026', 'Aumentado para 5 o tamanho do campo de lead-time calculado para o fornecedor' } )
    aAdd( aDetVer, { '18','0025','22/01/2026', 'Ajuste na impressão do pedido de compra que está saindo com números diferentes quando possui mais que uma página' } )
    aAdd( aDetVer, { '18','0026','23/01/2026', 'Removido obrigatoriedade do nome do fornecedor e do nome do produto na importação do arquivo de produto x fornecedor' } )
    aAdd( aDetVer, { '19','0001','26/01/2026', 'Implantação de tabelas externas ao contexto do Painel de Compras em substituição à tabelas presentes no dicionário de dados' } )
    aAdd( aDetVer, { '19','0002','02/02/2026', 'Adicionado campo de valor de venda na tela de análise de produtos para compra.' } )
    aAdd( aDetVer, { '19','0003','26/02/2026', 'Permitido a usuário visualizar documentos de todas as filiais na tela principal da formação de preços' } )
    aAdd( aDetVer, { '19','0004','26/02/2026', 'Implementado função para criação de campo automática, desde que o acesso seja em modo exclusivo à tabela' } )
    aAdd( aDetVer, { '19','0005','26/02/2026', 'Implementado regra para permitir definir no fornecedor se o mesmo deve ou não entrar na formação de preços.' } )
    aAdd( aDetVer, { '19','0006','12/03/2026', 'Criado ponto de entrada PEPNC08 para permitir alterar querys de cálculos dos produtos' } )
    aAdd( aDetVer, { '19','0007','13/03/2026', 'Adicionado data do último cálculo dos produtos para aparecer no cabeçalho do grid de produtos' } )
    aAdd( aDetVer, { '19','0008','20/03/2026', 'Ajuste na gravação do código da transportadora no pedido de venda' } )
    aAdd( aDetVer, { '19','0009','01/04/2026', 'Criado ponto de entrada PEPNC09 para permitir guardar os dados do produto antes de alterar seu preço' } )
    aAdd( aDetVer, { '19','0010','08/04/2026', 'Corrigido validação inconsistente do ambiente do Supabase' } )

return aDetVer

/*/{Protheus.doc} JSSUPSM0
Função para obter as filiais da empresa que o usuário estiver conectado
@type functionq
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/10/2024
@return array, aFilData
/*/
user function JSSUPSM0()
	
	local aFilData := {} as array
	local cQuery   := "" as character

	cQuery := "SELECT DISTINCT A2.A2_COD FROM SYS_COMPANY M0 "
	
	cQuery += "INNER JOIN "+ RetSqlName( 'SA2' ) +" A2 "
	cQuery += " ON A2.A2_FILIAL  = '"+ FWxFilial( 'SA2' ) +"' " 
	cQuery += "AND A2.A2_CGC     = M0.M0_CGC "
	cQuery += "AND A2.D_E_L_E_T_ = ' ' "

	cQuery += "WHERE M0.D_E_L_E_T_  = ' ' "
	DBUseArea( .T., "TOPCONN", TcGenQry(,,cQuery), 'SM0TMP', .F., .T.)	
	while ! SM0TMP->(EOF())
		aAdd( aFilData, SM0TMP->A2_COD )
		SM0TMP->( DBSkip() )
	end
	SM0TMP->( DBCloseArea() )
		
return aFilData

/*/{Protheus.doc} JSWFSOL
Função para criação automática da estrutura do workflow para disparo automático de e-mail ao comprador
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 5/5/2025
@return logical, lSuccess
/*/
user function JSWFSOL()

    local lSuccess := .T. as logical
	local oFile    as object
	local cPath    := "/workflow/"
	local cFileWF  := "painel_compras_solicitacao_v01.html"
	local cWF      := "" as character

	lSuccess := File( cPath + cFileWF )
	if ! lSuccess
		cWF := solicWF()
		oFile := FWFileWriter():New( cPath + cFileWF )
		if oFile:Create()
			oFile:Write( cWF )
			oFile:Close()
		endif
        lSuccess := File( cPath + cFileWF )
	endif

return { lSuccess, iif( lSuccess, cPath + cFileWF, "" ) }

/*/{Protheus.doc} solicWF
Workflow de nova solicitação 
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 5/5/2025
@return character, cWF
/*/
static function solicWF()
    
    local cWF := "" as character

    cWF := "<!DOCTYPE html>" + CEOL
    cWF += " <html>" + CEOL

    cWF += "	<head>" + CEOL
    cWF += '		<meta http-equiv="Content-Language" content="en-us">' + CEOL
    cWF += '		<meta http-equiv="Content-Type" content="text/html; charset=windows-1252">' + CEOL
    cWF += '		<title>Workflow %EMPRESA%</title>' + CEOL
    cWF += '	</head>' + CEOL
    cWF += '	<body style="font-family: Arial, Tahoma, Calibri, sans-serif; font-size:14px; font-weight: normal; " >' + CEOL
    cWF += '		<p style="color: #ff8000; font-weight: bold">%TITULOMSG%</p>' + CEOL
    cWF += '		<p> ' + CEOL
    cWF += '			<b> A T E N Ç Ã O </b>, ' + CEOL
    cWF += '		</p>' + CEOL

    cWF += '		<p style="text-align: justify" >Solicitação de compra ' + CEOL
    cWF += '			<b> %SOLICITACAO%</b> gerada pelo usuário ' + CEOL
    cWF += '			<b> %USUARIO%</b> em ' + CEOL
    cWF += ' 			<b> %DATAHORA%</b> ' + CEOL
    cWF += '			. Abaixo estão listados os produtos solicitados, são eles: ' + CEOL
    cWF += '		</p>' + CEOL

    cWF += '		<table style="width:100%; border-collapse: collapse">' + CEOL
    cWF += '			<tr>' + CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; border-top-left-radius: 5px;" align="center"> Produto </td>' + CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; " align="center"> Descrição </td>' + CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; " align="center"> Un.Med. </td>' + CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; " align="center"> Nec. Compra </td>' + CEOL
    cWF += '			</tr>' + CEOL
    cWF += '		<tr>' + CEOL
    cWF += '				<td style="border-left: 1px solid rgb(204, 109, 20); background-color: %it.clproduto%" align="left">' + CEOL
    cWF += '					<font size="2">%IT.PRODUTO% </font></td>' + CEOL
    cWF += '				<td style="border-collapse: collapse; border-spacing: 5px; padding: 10px; background-color: %it.cldescricao%" align="left">' + CEOL
    cWF += '					<font size="2">%IT.DESCRICAO% </font></td>' + CEOL
    cWF += '				<td style="border-collapse: collapse; border-spacing: 5px; padding: 10px; background-color: %it.clunimed%" align="center">' + CEOL
    cWF += '					<font size="2">%IT.UNIMED% </font></td>' + CEOL
    cWF += '				<td style="border-collapse: collapse; border-spacing: 5px; padding: 10px; background-color: %it.clnecessidade%" align="right">' + CEOL
    cWF += '					<font size="2">%IT.NECESSIDADE% </font></td>' + CEOL
    cWF += '			</tr>' + CEOL
    cWF += '			<tr>' + CEOL
    cWF += '				 <td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); border-bottom-left-radius: 5px; " ></td>' + CEOL
    cWF += '				 <td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color: white"></td>' + CEOL
    cWF += '				 <td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color: white"></td>' + CEOL
    cWF += '				 <td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); border-bottom-right-radius: 5px; color: white" align="right" ></td>' + CEOL
    cWF += '			</tr>' + CEOL
    cWF += '		</table>' + CEOL
    cWF += '		</br>' + CEOL

    cWF += '		<span style="font-family:  Tahoma, Calibri, sans-serif; color:#FF8000;"><font size="1">' + CEOL
    cWF += '			</br>' + CEOL
    cWF += '			<hr noshade color="#FF8000" size="0.5px">' + CEOL
    cWF += '				<p align="left">' + CEOL
    cWF += '					<b>Esta mensagem foi enviada de maneira automática pelos nossos sitemas, portanto, não há necessidade de resposta.</b>' + CEOL
    cWF += '				</p>' + CEOL
    cWF += ' 			</hr>' + CEOL

    cWF += '		</span>' + CEOL
    cWF += '	</body>' + CEOL
    cWF += '</html>'  + CEOL

return cWF

/*/{Protheus.doc} JSFILIAL
Função para retornar expressão de filial conforme configurações de cada tabela.
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 07/10/2024
@param cAlias, character, alias da tabela que se deseja executar um filtro de filial
@param aFil, array, vetor com filiais que se deseja filtrar
@return character, cFilExp
/*/
user function JSFILIAL( cAlias, aFil )
    
    local cFilExp := "" as character
    local aUsed   := {} as array
    local nSize   := Len( AllTrim( FWxFilial( cAlias ) ) )
    local nFil    := 0 as numeric
    local cAux    := "" as character
    local cField  := iif( SubStr( cAlias, 01, 01 ) == 'S', SubStr( cAlias, 02,02 ) +'_FILIAL', cAlias +'_FILIAL' )
    local nAux    := 0 as numeric

    if nSize > 0 

        // Repassa todas as filiais selecionadas pelo usuário e monta um subvetor com as filiais já compatibilizadas com o tamanho utilizado pela tabela
        for nFil := 1 to len(aFil)
            cAux := SubStr( aFil[nFil], 01, nSize )
            if aScan( aUsed, {|x| AllTrim(x) == AllTrim(cAux) } ) == 0
                aAdd( aUsed, PADR(cAux, TAMSX3( cField )[1], ' ' ) )
            endif
        next nFil
       
        // Monta expressão IN para uso na query
        if len( aUsed ) == 0
            cFilExp := " = '"+ Replicate( 'Z', TAMSX3( cField )[1] ) +"' "
        elseif len( aUsed ) == 1        // Se foi selecionado apenas uma filial, muda a expressão da query para dar mais performance
            cFilExp := " = '"+ aUsed[1] +"' "
        else
            cFilExp := " IN ( "
            aEval( aUsed, {|x| nAux++, cFilExp += "'"+ x +"'" + iif( nAux < len( aUsed ), ',', '' ) } )        
            cFilExp += " ) "
        endif

    elseif nSize == 0 .and. len( aFil ) > 0                 // Se existir filial selecionada e o tamanho do campo for zero
        cFilExp := " = '"+ FWxFilial( cAlias ) +"' "

    elseif nSize == 0 .and. len( aFil ) == 0                // Erra o filtro propositalmente para fazer com que o banco não retorne nenhum registro.
        cFilExp := " <> '"+ FWxFilial( cAlias ) +"'  "  
    endif

return cFilExp

/*/{Protheus.doc} JSPAITYP
Função da consulta padrão PAITYP para retornar tipos de produtos desejados.
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/8/2024
@param cTipos, character, tipos de produtos que estão filtrados
@return character, _cTypes
/*/
user function JSPAITYP( cTipos )
    
    local oDlgType as object
    local oMain    as object
    local oTipos   as object
    local aTipos   := {} as array
    local aColumns := {} as array
    local lMark    := .F. as logical
    local aTypes   := {} as array
    local cRet  := "" as character

    aTypes := StrTokArr( AllTrim(cTipos), "/" )

    DBSelectArea( 'SX5' )
	SX5->( DBSetOrder(1) )
		if DBSeek( FWxFilial( 'SX5' ) + '02'  )
		while ! SX5->( EOF() ) .and. SX5->X5_FILIAL == FWxFilial( 'SX5' ) .AND. SX5->X5_TABELA == '02'
			aAdd( aTipos, { aScan( aTypes, {|x| AllTrim(x) == AllTrim( SX5->X5_CHAVE ) } ) > 0,;
							AllTrim( SX5->X5_CHAVE ),;
							AllTrim( SX5->X5_DESCRI ) } )
			SX5->( DBSkip() )
		end
	endif

    aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( 'Tipo' )
	aColumns[len(aColumns)]:SetSize( 2 )
	aColumns[len(aColumns)]:SetType( 'C' )
	aColumns[len(aColumns)]:SetPicture( '@!' )
	aColumns[len(aColumns)]:SetData( {|| aTipos[oTipos:nAt][2] } )
	
	aAdd( aColumns, FWBrwColumn():New() )
	aColumns[len(aColumns)]:SetTitle( 'Descrição' )
	aColumns[len(aColumns)]:SetSize( 30 )
	aColumns[len(aColumns)]:SetType( 'C' )
	aColumns[len(aColumns)]:SetPicture( '@x' )
	aColumns[len(aColumns)]:SetData( {|| aTipos[oTipos:nAt][3] } )

    oDlgType := FWDialogModal():New()
    oDlgType:SetEscClose( .T. )
    oDlgType:SetTitle( "Tipos de Produtos" )
    oDlgType:SetSize( 310, 200 )
    oDlgType:SetSubTitle( "Selecione um ou mais tipos de produtos para análise..." )
    oDlgType:CreateDialog()
	oDlgType:AddCloseButton( {|| oDlgType:DeActivate()}, "Cancelar" )
	oDlgType:AddOkButton( {|| cRet := "",; 
                             aEval( aTipos, {|x| iif( x[1], cRet += iif( Empty(cRet),"","/" )+ x[2], Nil ) } ),;
                              oDlgType:DeActivate() }, "Ok" )

    oMain := oDlgType:GetPanelMain()

    oTipos := FWBrowse():New( oMain )
	oTipos:SetDataArray()
	oTipos:SetArray( aTipos )
	oTipos:DisableConfig()
	oTipos:DisableReport()
	oTipos:SetLineHeight(20)
	oTipos:AddMarkColumns( {|oTipos| if( aTipos[oTipos:nAt][1], 'LBOK','LBNO' ) },;
							{|oTipos| aTipos[oTipos:nAt][1] := !aTipos[oTipos:nAt][1] },;
							{|oTipos| lMark := !aTipos[1][1], aEval( aTipos, {|x| x[1] := lMark } ), oTipos:UpdateBrowse() } )
	oTipos:SetColumns( aColumns )
	oTipos:Activate()

    oDlgType:Activate()
    
    cRet := PADR( cRet, 200, ' ' )

return cRet

/*/{Protheus.doc} JSQRYINF
Função para montagem de query de análise do MRP para Painel de Compras
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 11/21/2024
@param aConf, array, vetor de configurações do painel
@param aFilters, array, vetor de filtros aplicados na pesquisa dos produtos a serem calculados
@param cPedSol, character, Indica o tipo de pedido que vai ser gerado 1-Pedido ou 2-Solicitacao
@return character, cQuery
/*/
user function JSQRYINF( aConf, aFilters, cPedSol, aCustom )
    
    Local cTmp     := Upper( AllTrim( aFilters[1] ) )
	Local aTmp     := StrTokArr( cTmp, ' ' )
    local cQuery   := "" as character
    local cZB3     := AllTrim( SuperGetMv( 'MV_X_PNC02' ,,"" ) ) // Alias da tabela de índices de produtos
    local nX       := 0  as numeric
    local cLocais  := "" as character
    local cTypes   := "" as character
    local aAux     := {} as array
    local y        := 0  as numeric
    local dDtCalc  := CtoD( SubStr( GetMv( 'MV_X_PNC12',,DtoC(date()) ), 01, 10 ) )
    local lLike    := At( '*', aFilters[5] ) > 0
    local cFilHist := cFilAnt
    local nFil     := 0 as numeric
    local cDB      := TCGetDB()
    local cFdGroup := AllTrim( SuperGetMv( 'MV_X_PNC13',,'B1_GRUPO' ) )

    default aConf    := {}
    default aFilters := {}
    default cPedSol  := '1'
    default aCustom  := {}

    // Quando não vier parâmetros, retorna query vazia
    if !len( aConf ) > 0 .and. !len( aFilters ) > 0
        return cQuery
    endif

    aAux := StrTokArr(AllTrim(aFilters[2]),'/')
	// Cria expressão para a query SQL
	aEval( aAux, {|x| y++, cTypes += "'"+ x +"'" + iif( y < len( aAux ),',','' ) } )

    // Monta string referente aos armazens que serão utilizados para somatório dos saldos dos produtos
	aAux    := StrTokArr( AllTrim( aConf[16] ), '/' )
	cLocais := ""
	For nX := 1 to Len( aAux )
		cLocais += PADR( AllTrim( aAux[nX] ), TAMSX3('B2_LOCAL')[01], ' ') + iif( nX == Len(aAux),'',"','" )
	Next nX
    // Valida existência de conteúdo no parâmetro de armazéns
	if Empty( cLocais )
		Hlp( 'SEMLOCAIS',; 
             'Locais de estoque a serem considerados não definidos nos parâmetros do Painel de Compras!',;
             'Defina os armazéns para leitura de saldo em estoque e tente novamente!' )
        Return cQuery 
	EndIf
    
    cQuery := "SELECT TEMP.* FROM ( "+ CEOL
    for nFil := 1 to len( _aFil )
        cFilAnt := _aFil[nFil]
        
        cQuery += "SELECT '"+ cFilAnt +"' FILIAL, B1.B1_COD, B1.B1_DESC, B1.B1_UM, B1.B1_LM, B1.B1_QE, B1.B1_LE, "
        if ! Empty( aFilters[3] )
            cQuery += "COALESCE(" +iif( aConf[22] == '1', "B1.B1_PROC", "A5.A5_FORNECE") +",'"+ Space( TAMSX3('A5_FORNECE')[1] ) +"') AS A5_FORNECE, " + CEOL
            cQuery += "COALESCE("+ iif( aConf[22] == '1', "B1.B1_LOJPROC", "A5.A5_LOJA") +",'"+ Space( TAMSX3('A5_LOJA')[1] ) +"') AS A5_LOJA, " + CEOL
        else
            cQuery += "'"+ Space( TAMSX3('A5_FORNECE')[1] ) +"' A5_FORNECE, "+ CEOL
            cQuery += "'"+ Space( TAMSX3('A5_LOJA')[1] ) +"' AS A5_LOJA, " + CEOL
        endif
        cQuery += "B1.R_E_C_N_O_ RECSB1, " + CEOL

        cQuery += "COALESCE((SELECT SUM(B2.B2_QATU) FROM "+ RetSqlName( 'SB2' ) +" B2 " + CEOL
        cQuery += "WHERE B2.B2_FILIAL = '"+ FWxFilial( 'SB2' ) +"' " + CEOL
        cQuery += "  AND B2.B2_COD    = B1.B1_COD "+ CEOL
        cQuery += "  AND B2.B2_LOCAL  IN ( '"+ cLocais +"' ) " + CEOL
        cQuery += "  AND B2.D_E_L_E_T_ = ' ' ),0) ESTOQUE, " + CEOL

        cQuery += "COALESCE((SELECT SUM(B2.B2_RESERVA+B2.B2_QEMP) FROM "+ RetSqlName( 'SB2' ) +" B2 " + CEOL
        cQuery += "WHERE B2.B2_FILIAL = '"+ FWxFilial( 'SB2' ) +"' " + CEOL
        cQuery += "  AND B2.B2_COD    = B1.B1_COD "+ CEOL
        cQuery += "  AND B2.B2_LOCAL  IN ( '"+ cLocais +"' ) " + CEOL
        cQuery += "  AND B2.D_E_L_E_T_ = ' ' ),0) EMPENHO, " + CEOL
        
        // Identifica o lead-time do fornecedor
        if SA2->( FieldPos( 'A2_X_LTIME' ) ) > 0 .AND. ! Empty( aFilters[3] )
            cQuery += " A2.A2_X_LTIME, "+ CEOL
        else
            cQuery += " 0 A2_X_LTIME, "+ CEOL
        endif

        cQuery += "B1.B1_PE, " + CEOL
        cQuery += "B1.B1_EMIN, " + CEOL

        cQuery += "COALESCE((SELECT SUM(C7BLOQ.C7_QUANT - C7BLOQ.C7_QUJE) FROM "+ RetSqlName( "SC7" ) +" C7BLOQ " + CEOL
        cQuery += "WHERE C7BLOQ.C7_FILIAL = '"+ FWxFilial( 'SC7' ) +"' " + CEOL
        cQuery += "  AND C7BLOQ.C7_PRODUTO = B1.B1_COD " + CEOL
        cQuery += "  AND C7BLOQ.C7_RESIDUO <> 'S' " + CEOL
        cQuery += "  AND C7BLOQ.C7_ENCER   <> 'E' " + CEOL
        cQuery += "  AND C7BLOQ.C7_CONAPRO = 'B' " + CEOL						// identifica quantidade em pedido de compra com bloqueio
        cQuery += "  AND C7BLOQ.D_E_L_E_T_ = ' ' ),0) QTDBLOQ, "+ CEOL

        cQuery += "COALESCE((SELECT SUM(C7COMP.C7_QUANT - C7COMP.C7_QUJE) FROM "+ RetSqlName( "SC7" ) +" C7COMP " + CEOL
        cQuery += "WHERE C7COMP.C7_FILIAL = '"+ FWxFilial( 'SC7' ) +"' " + CEOL
        cQuery += "  AND C7COMP.C7_PRODUTO = B1.B1_COD " + CEOL
        cQuery += "  AND C7COMP.C7_RESIDUO <> 'S' " + CEOL
        cQuery += "  AND C7COMP.C7_ENCER   <> 'E' " + CEOL
        cQuery += "  AND C7COMP.C7_CONAPRO <> 'B' " + CEOL						// Pedidos em carteira sem bloqueio
        cQuery += "  AND C7COMP.D_E_L_E_T_ = ' ' ),0) QTDCOMP, " + CEOL

        cQuery += "COALESCE((SELECT MAX( C7COMP.C7_DATPRF ) FROM "+ RetSqlName( "SC7" ) +" C7COMP " + CEOL
        cQuery += "WHERE C7COMP.C7_FILIAL = '"+ FWxFilial( 'SC7' ) +"' " + CEOL
        cQuery += "  AND C7COMP.C7_PRODUTO = B1.B1_COD " + CEOL
        cQuery += "  AND C7COMP.C7_RESIDUO <> 'S' " + CEOL
        cQuery += "  AND C7COMP.C7_ENCER   <> 'E' " + CEOL
        cQuery += "  AND C7COMP.C7_CONAPRO <> 'B' " + CEOL						// Pedidos em carteira sem bloqueio
        cQuery += "  AND C7COMP.D_E_L_E_T_ = ' ' ), '"+ Space(8) +"' ) PRVENT, " + CEOL

        cQuery += "COALESCE( ( SELECT SUM( C1.C1_QUANT ) FROM "+ RetSqlName( 'SC1' ) +" C1 " + CEOL
        cQuery += "WHERE C1.C1_FILIAL  = '"+ FWxFilial( 'SC1' ) +"' " + CEOL
        cQuery += "  AND C1.C1_PRODUTO = B1.B1_COD " + CEOL
        cQuery += "  AND C1.C1_PEDIDO  = '"+ Space( TAMSX3( 'C1_PEDIDO' )[1] ) +"' " + CEOL
        cQuery += "  AND C1.C1_RESIDUO = ' ' " + CEOL
        cQuery += "  AND C1.D_E_L_E_T_ = ' ' " + CEOL
        cQuery += " ),0 ) QTDSOL "                       // Quantidade em solicitação de compra

        if ! isInCallStack( 'U_GMINDPRO' )
            cQuery += ", " + CEOL
            cQuery += "COALESCE( "+ cZB3 +"_CONMED,0.0001) "+ cZB3 +"_CONMED, " + CEOL
            cQuery += "COALESCE( "+ cZB3 +"_INDINC,0) "+ cZB3 +"_INDINC " + CEOL
        endif

        // Adiciona os campos customizados à query de captura dos dados
        if len(aCustom) > 0
            aEval( aCustom, {|x| cQuery += ", "+ x } )
            cQuery += " "
        endif

        cQuery += "FROM "+ RetSqlName( 'SB1' ) +" B1 " + CEOL
        
        if ! Empty( aFilters[3] )   
            
            if aConf[22] $ '2|3'    // 2=Prod.x Fornecedor ou 3=Hist.Compras 
                
                // Se o fornecedor for informado, o join é exato, do contrário, apresenta os produtos sem fornecedor
                cQuery += "INNER JOIN "+ RetSqlName( 'SA5' ) +" A5 " + CEOL
                cQuery += " ON A5.A5_FILIAL = '"+ FWxFilial( 'SA5' ) +"' "+ CEOL
                cQuery += "AND A5.A5_PRODUTO = B1.B1_COD " + CEOL
                if ! Empty( aFilters[3] )      // Quando fornecedor é informado, faz join com a tabela de fornecedores para filtrar apenas os produtos do fornecedor informado
                    cQuery += "AND A5.A5_FORNECE = '"+ aFilters[3] +"' " + CEOL
                endif
                if ! Empty( aFilters[6] )   // Quando loja é informada, utiliza também no filtro
                    cQuery += "AND A5.A5_LOJA = '"+ aFilters[6] +"' " + CEOL
                endif
                cQuery += "AND A5.D_E_L_E_T_ = ' ' " + CEOL

                // Se o fornecedor for informado, o join é exato, do contrário, apresenta os produtos sem fornecedor
                cQuery += "INNER JOIN "+ RetSqlName( 'SA2' ) +" A2 "+ CEOL
                cQuery += " ON A2.A2_FILIAL  = '"+ FWxFilial( 'SA2' ) +"' "+ CEOL    
                cQuery += "AND A2.A2_COD     = A5.A5_FORNECE " + CEOL
                cQuery += "AND A2.A2_LOJA    = A5.A5_LOJA " + CEOL
                cQuery += "AND A2.A2_MSBLQL  <> '1' "+ CEOL
                cQuery += "AND A2.D_E_L_E_T_ = ' ' "+ CEOL

            else

                // Se o fornecedor for informado, o join é exato, do contrário, apresenta os produtos sem fornecedor
                cQuery += "INNER JOIN "+ RetSqlName( 'SA2' ) +" A2 "+ CEOL
                cQuery += " ON A2.A2_FILIAL  = '"+ FWxFilial( 'SA2' ) +"' "+ CEOL    
                cQuery += "AND A2.A2_COD     = B1.B1_PROC "+ CEOL
                cQuery += "AND A2.A2_LOJA    = B1.B1_LOJPROC "+ CEOL
                if ! Empty( aFilters[3] )      // Quando fornecedor é informado, faz join com a tabela de fornecedores para filtrar apenas o fornecedor informado
                    cQuery += "AND A2.A2_COD = '"+ aFilters[3] +"' " + CEOL
                endif
                if ! Empty( aFilters[6] )       // Quando a loja do fornecedor for informada, utiliza no filtro
                    cQuery += "AND A2.A2_LOJA = '"+ aFilters[6] +"' " + CEOL
                endif
                cQuery += "AND A2.A2_MSBLQL   <> '1' "+ CEOL
                cQuery += "AND A2.D_E_L_E_T_  = ' ' "+ CEOL

            endif

        endif

        // Quando a demanda vier da rotina de recálculo de índices, desconsidera os índices existentes
        if ! isInCallStack( 'U_GMINDPRO' )
            cQuery += "LEFT JOIN "+ RetSqlName( cZB3 ) +" "+ cZB3 +" " + CEOL
            cQuery += " ON "+ cZB3 +"."+ cZB3 +"_FILIAL = '"+ FWxFilial( cZB3 ) +"' " + CEOL
            cQuery += "AND "+ cZB3 +"."+ cZB3 +"_PROD   = B1.B1_COD " + CEOL
            cQuery += "AND "+ cZB3 +"."+ cZB3 +"_DATA   = '"+ DtoS( dDtCalc ) +"' " + CEOL
            cQuery += "AND "+ cZB3 +".D_E_L_E_T_ = ' ' " + CEOL
        endif

        cQuery += "WHERE B1.B1_FILIAL  = '"+ FWxFilial( 'SB1' ) +"' "+ CEOL 
        
        if ! Empty( aFilters[5] )
            cQuery += "  AND B1.B1_COD "+ iif( lLike, 'LIKE', '=' ) +" '"+ StrTran( iif( lLike, AllTrim(aFilters[5]), aFilters[5]),'*','%') +"' "+ CEOL                 // Filtra pelo código do produto
        endif
        
        // Filtra pelo grupo do produto que determina sua classificação quanto a tabela de preços do fornecedor
        // ESPECIFICO GMAD MADECENTER
        if SB1->( FieldPos( 'B1_XGPTP' ) ) > 0
            if len(aFilters) >= 8 .and. ValType(aFilters[7]) == 'C' .and. ! Empty( aFilters[7] )
                cQuery += "  AND B1.B1_XGPTP LIKE '"+ AllTrim(aFilters[7]) +"%' " + CEOL			// Filtra pelo grupo de produtos
            endif
        endif

        cQuery += "  AND B1.B1_MSBLQL  <> '1' " + CEOL				// Faz leitura apenas dos itens ativos
        cQuery += "  AND B1.B1_TIPO IN ( "+ cTypes +" ) " + CEOL	// Desconsidera produtos acabado e serviços da análise do MRP
        cQuery += "  AND B1.B1_MRP     = 'S' " + CEOL				// Apenas os produtos que devem entrar no MRP
        
        if ValType( aTmp ) == 'A' .and. Len( aTmp ) > 0
            For nX := 1 to Len( aTmp )
                cQuery += "  AND B1.B1_DESC LIKE '%"+ aTmp[nX] +"%' " + CEOL
            Next nX 
        EndIf

        // Verifica se o filtro de fornecedor padrão foi informado na pesquisa de produtos
        if ! Empty( aFilters[4] )
            cQuery += "  AND B1."+ cFdGroup +" LIKE '"+ aFilters[4] +"%' " + CEOL
        endif

        // Tratativa de segurança para evitar filtro vazio quando usuário apertar botão de cancelar
        if aFilters[len(aFilters)]
            cQuery += "  AND 0=1 " + CEOL
        endif
        
        cQuery += "  AND B1.D_E_L_E_T_ = ' ' " + CEOL

        if nFil < len( _aFil )
            cQuery += "UNION ALL "+ CEOL
        endif
    next nFil

    if cDB $ "ORACLE|SQLSERVER"
        cQuery += ") TEMP " + CEOL
    else
        cQuery += ") AS TEMP " + CEOL
    endif
    cQuery += "ORDER BY TEMP.B1_COD, TEMP.B1_DESC, TEMP.FILIAL "	+ CEOL

    // Devolve posicionamento na filial de origem
    cFilAnt := cFilHist

    ConOut( cQuery )
return cQuery

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

/*/{Protheus.doc} RuptWF
Retorna conteúdo do html base para montagem de e-mail de alerta de ruptura de estoque
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 1/2/2025
@return character, cWF
/*/
user function RuptWF()

    local cWF := "" as character

    cWF += '<!DOCTYPE html>' + CEOL
    cWF += '<html>' + CEOL
    cWF += CEOL
    cWF += '	<head>' + CEOL
    cWF += '		<meta http-equiv="Content-Language" content="en-us">' + CEOL
    cWF += '		<meta http-equiv="Content-Type" content="text/html; charset=windows-1252">' + CEOL
    cWF += '		<title>Workflow %EMPRESA%</title>' + CEOL
    cWF += '	</head>' + CEOL
    cWF += '	<body style="font-family: Arial, Tahoma, Calibri, sans-serif; font-size:14px; font-weight: normal; " >' + CEOL
    cWF += '		<p style="color: #ff8000; font-weight: bold">%TITULOMSG%</p>' + CEOL
    cWF += '		<p> ' + CEOL
    cWF += '			<b> A T E N Ç Ã O </b>, ' + CEOL
    cWF += '		</p>' + CEOL
    cWF += CEOL
    cWF += '		<p style="text-align: justify" >Com base na análise de materiais realizada em ' + CEOL
    cWF += '			<b> %DATAHORA%</b> ' + CEOL
    cWF += '			, foram identificados alguns itens com risco de ruptura de estoque. São eles: '+ CEOL
    cWF += '		</p>' + CEOL
    cWF += CEOL
    cWF += '		<table style="width:100%; border-collapse: collapse">' + CEOL
    cWF += '			<tr>' + CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; border-top-left-radius: 5px;" align="center"> Produto </td>' + CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; " align="center"> Descrição </td>' + CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; " align="center"> Cons. Medio(D) </td>' + CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; " align="center"> Tp Dia </td>' + CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; " align="center"> Dur. Estoque(D) </td>' + CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; " align="center"> Nec. Compra </td>' + CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; " align="center"> Estoq. Atual </td>'+ CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; " align="center"> Empenho (Reserva) </td>' + CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; " align="center"> Qtde Comprada </td>' + CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; " align="center"> Prev. Entrega </td>' + CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; " align="center"> T. Entrega (Dias) </td>'+ CEOL
    cWF += '				<td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color:white; border-top-right-radius: 5px;" align="center"> Detalhamento </td>' + CEOL
    cWF += '			</tr>' + CEOL
    cWF += '		<tr>' + CEOL
    cWF += '				<td style="border-left: 1px solid rgb(204, 109, 20); background-color: %it.clproduto%" align="left">' + CEOL
    cWF += '					<font size="2">%IT.PRODUTO% </font></td>' + CEOL
    cWF += '				<td style="border-collapse: collapse; border-spacing: 5px; padding: 10px; background-color: %it.cldescricao%" align="left">' + CEOL
    cWF += '					<font size="2">%IT.DESCRICAO% </font></td>' + CEOL
    cWF += '				<td style="border-collapse: collapse; border-spacing: 5px; padding: 10px; background-color: %it.clconsumo%" align="right">' + CEOL
    cWF += '					<font size="2">%IT.CONSUMO% </font></td>' + CEOL
    cWF += '				<td style="border-collapse: collapse; border-spacing: 5px; padding: 10px; background-color: %it.cltipodia%" align="center">' + CEOL
    cWF += '					<font size="2">%IT.TIPODIA% </font></td>' + CEOL
    cWF += '				<td style="border-collapse: collapse; border-spacing: 5px; padding: 10px; background-color: %it.clduracao%" align="center">' + CEOL
    cWF += '					<font size="2">%IT.DURACAO% </font></td>' + CEOL
    cWF += '				<td style="border-collapse: collapse; border-spacing: 5px; padding: 10px; background-color: %it.clnecessidade%" align="right">' + CEOL
    cWF += '					<font size="2">%IT.NECESSIDADE% </font></td>' + CEOL
    cWF += '				<td style="border-collapse: collapse; border-spacing: 5px; padding: 10px; background-color: %it.clestoque%" align="right">' + CEOL
    cWF += '					<font size="2">%IT.ESTOQUE% </font></td>' + CEOL
    cWF += '				<td style="border-collapse: collapse; border-spacing: 5px; padding: 10px; background-color: %it.clempenho%" align="right">' + CEOL
    cWF += '					<font size="2">%IT.EMPENHO% </font></td>' + CEOL
    cWF += '				<td style="border-collapse: collapse; border-spacing: 5px; padding: 10px; background-color: %it.clcomprado%" align="right">' + CEOL
    cWF += '					<font size="2">%IT.COMPRADO% </font></td>' + CEOL
    cWF += '				<td style="border-collapse: collapse; border-spacing: 5px; padding: 10px; background-color: %it.clprevisao%" align="center">' + CEOL
    cWF += '					<font size="2">%IT.PREVISAO% </font></td>' + CEOL
    cWF += '				<td style="border-collapse: collapse; border-spacing: 5px; padding: 10px; background-color: %it.clldtime%" align="center">' + CEOL
    cWF += '					<font size="2">%IT.LDTIME% </font></td>' + CEOL
    cWF += '				<td style="border-right: 1px solid rgb(204, 109, 20);  background-color: %it.clmensagem%" align="left">' + CEOL
    cWF += '					<font size="2">%IT.MENSAGEM% </font></td>' + CEOL
    cWF += '			</tr>' + CEOL
    cWF += '			<tr>' + CEOL
    cWF += '				 <td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); border-bottom-left-radius: 5px; " ></td>' + CEOL
    cWF += '				 <td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color: white"></td>' + CEOL
    cWF += '				 <td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color: white"></td>' + CEOL
    cWF += '				 <td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color: white"></td>' + CEOL
    cWF += '				 <td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color: white"></td>' + CEOL
    cWF += '				 <td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color: white"></td>' + CEOL
    cWF += '				 <td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color: white"></td>' + CEOL
    cWF += '				 <td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color: white"></td>' + CEOL
    cWF += '				 <td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color: white"></td>' + CEOL
    cWF += '				 <td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color: white"></td>' + CEOL
    cWF += '				 <td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); color: white"></td>' + CEOL
    cWF += '				 <td style="border-spacing: 5px; padding: 10px; background: linear-gradient(to bottom, rgb(240, 128, 24) 0%,rgb(204, 109, 20) 100%); border-bottom-right-radius: 5px; color: white" align="right" ></td>' + CEOL
    cWF += '			</tr>' + CEOL
    cWF += '		</table>' + CEOL
    cWF += '		</br>' + CEOL
    cWF += CEOL
    cWF += '		<span style="font-family:  Tahoma, Calibri, sans-serif; color:#FF8000;"><font size="1">' + CEOL
    cWF += '			</br>' + CEOL
    cWF += '			<hr noshade color="#FF8000" size="0.5px">' + CEOL
    cWF += '				<p align="left">' + CEOL
    cWF += '					<b>Esta mensagem foi enviada de maneira automática pelos nossos sitemas, portante, não há necessidade de resposta.</b>' + CEOL
    cWF += '				</p>' + CEOL
    cWF += ' 			</hr>' + CEOL
    cWF += CEOL
    cWF += '		</span>' + CEOL
    cWF += '	</body>' + CEOL
    cWF += '</html>' + CEOL

return cWF

/*/{Protheus.doc} JSCLISM0
Retorna vetor com cliente + filial dos cadastros que possuem ligação com filiais da empresa corrente cadastradas no sistema
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 1/22/2025
@return array, aCliSM0
/*/
User Function JSCLISM0()
return getCliSM0()

/*/{Protheus.doc} JSQRYSAI
Query para leitura das saidas de produtos que tem relação com venda de produtos do grupo econômico
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 1/15/2025
@param cProduto, character, ID do produto
@param dDe, date, inídio da faixa de pesquisa de vendas pela data de emissao
@param dAte, date, fim da faixa de pesquisa de vendas pela data de emissao
@param _aFil, array, vetor de filiais selecionadas pelo usuário
@return character, cQuery
/*/
user function JSQRYSAI( cProduto, dDe, dAte, _aFil )
    
    local cQuery   := "" as character
    local aCliSM0  := {} as array
    local cCliSM0  := "" as character
    local nAux     := 0  as numeric
    local cFilHist := cFilAnt
    local nFil     := 0 as numeric
    local cDB      := TCGETDB()
    local lPEPNC08  := ExistBlock( 'PEPNC08' )
    local xPEPNC08  := nil

    default _aFil    := {}
    default cProduto := ""

    aCliSM0 := getCliSM0()
    if len( aCliSM0 ) > 0
        aEval( aCliSM0, {|x| nAux++, cCliSM0 += "'"+ x[1] + x[2] +"'" + iif( nAux < len(aCliSM0), ',', '' ) } )
    endif

    for nFil := 1 to len( _aFil )
        cFilAnt := _aFil[nFil]

        cQuery := "SELECT " + CEOL
        cQuery += "  'V' AS TIPO, D2.D2_FILIAL, D2.D2_COD, D2.D2_DOC, D2.D2_SERIE, D2.D2_EMISSAO, D2.D2_CLIENTE, D2.D2_LOJA, " + CEOL
        cQuery += "  A1.A1_NOME, D2.D2_LOCAL, D2.D2_QUANT " + CEOL
        cQuery += "FROM "+ RetSqlName( 'SD2' ) +" D2 " + CEOL
                    
        cQuery += "INNER JOIN "+ RetSqlName( 'SF4' ) +" F4 " + CEOL
        cQuery += " ON F4.F4_FILIAL  = '"+ FWxFilial( 'SF4' ) +"' "+ CEOL
        cQuery += "AND F4.F4_CODIGO  = D2.D2_TES "+ CEOL
        cQuery += "AND F4.F4_ESTOQUE = 'S' "+ CEOL
        cQuery += "AND F4.D_E_L_E_T_ = ' ' "+ CEOL

        cQuery += "INNER JOIN "+ RetSqlName( 'SA1' ) +" A1 " + CEOL
        cQuery += "  ON A1.A1_FILIAL  = '"+ FWxFilial( 'SA1' ) +"' "+ CEOL
        cQuery += " AND A1.A1_COD     = D2.D2_CLIENTE "+ CEOL
        cQuery += " AND A1.A1_LOJA    = D2.D2_LOJA "+ CEOL
        cQuery += " AND A1.D_E_L_E_T_ = ' ' "+ CEOL

        cQuery += "WHERE D2.D2_FILIAL  = '"+ FWxFilial( 'SD2' ) +"' "+ CEOL
        cQuery += "  AND D2.D2_TIPO    = 'N' "+ CEOL
        cQuery += "  AND D2.D2_EMISSAO BETWEEN '"+ DtoS( dDe ) +"' AND '"+ DtoS( dAte ) +"' " + CEOL
        if ! Empty( cCliSM0 )       // Se houver clientes cadastrados que estão dentro do mesmo grupo econômico
            cQuery += "  AND CONCAT( D2.D2_CLIENTE, D2.D2_LOJA ) NOT IN ( "+ cCliSM0 +" ) " + CEOL
        endif
        if ! Empty( cProduto )
            cQuery += "  AND D2.D2_COD     = '"+ cProduto +"' " + CEOL
        endif
        cQuery += "  AND D2.D_E_L_E_T_ = ' ' " + CEOL

        if lPEPNC08
            // Ponto de entrada que permite modificar a query de análise das movimentações de saída para o produto
            // Parâmetro 1: Indica o local da chamada do PE, sendo 1- contagem dos registros de saída do produto
            //													   2- contagem dos registros de movimentações internas ou OPs para o produto
            //													   3- soma das quantidades de saída do produto
            //													   4- soma das quantidades de movimentações internas ou OPs para o produto
            //													   5- conta quantos documentos de saída foram emitidos no período
            //													   6- conta quantas movimentações ou ops foram feitas no período
            //                                                     7- lê movimentações de saída do produto para exibição na tela de detalhamento de saídas
            //                                                     8- lê movimentações internas e/ou com OPs para o produto         
            // Parâmetro 2: Indica a query padrão do sistema
            // Retorno esperado: query completa modificada ou incrementada pronta para execução
            xPEPNC08 := ExecBlock( 'PEPNC08', .F., .F., { 7, cQuery } )
            if ValType( xPEPNC08 ) == 'C' .and. ! Empty( xPEPNC08 )
                cQuery := xPEPNC08
            endif
        endif

        cQuery += "UNION ALL "+ CEOL

        cQuery += "SELECT " + CEOL
        cQuery += "  'P' AS TIPO, D3.D3_FILIAL D2_FILIAL, D3.D3_COD D2_COD, COALESCE(C2.C2_NUM,D3.D3_DOC) D2_DOC, '"+ Space( TAMSX3('D2_SERIE')[1] ) +"' AS D2_SERIE, D3.D3_EMISSAO D2_EMISSAO, "
        cQuery += "  COALESCE( C6.C6_CLI,'"+ Space( TamSX3('D2_CLIENTE')[1] ) +"' ) D2_CLIENTE, "
        cQuery += "  COALESCE( C6.C6_LOJA, '"+ Space( TamSX3('D2_LOJA')[1] ) +"' ) D2_LOJA, "
        cQuery += "  COALESCE( A1.A1_NOME, '"+ Space( TamSX3('A1_NOME')[1] ) +"' ) A1_NOME, "
        cQuery += "  D3.D3_LOCAL AS D2_LOCAL, D3.D3_QUANT AS D2_QUANT " + CEOL
        cQuery += "FROM "+ RetSqlName( 'SD3' ) +" D3 " + CEOL

        cQuery += "LEFT JOIN "+ RetSqlname('SC2'  ) +" C2 " + CEOL
        cQuery += " ON C2.C2_FILIAL = '"+ FWxFilial( 'SC2' ) +"' " + CEOL
        if cDB == 'ORACLE'
            cQuery += "AND C2.C2_NUM || C2.C2_ITEM || C2.C2_SEQUEN = D3.D3_OP " + CEOL
        else
            cQuery += "AND CONCAT( CONCAT( C2.C2_NUM, C2.C2_ITEM ), C2.C2_SEQUEN ) = D3.D3_OP " + CEOL
        endif
        cQuery += "AND C2.D_E_L_E_T_ = ' ' " + CEOL

        cQuery += "LEFT JOIN "+ RetSqlName( 'SC6' ) +" C6 " + CEOL
        cQuery += " ON C6.C6_FILIAL  = '"+ FWxFilial( 'SC6' ) +"' " + CEOL
        cQuery += "AND C6.C6_NUM     = C2.C2_PEDIDO " + CEOL
        cQuery += "AND C6.C6_ITEM    = C2.C2_ITEMPV " + CEOL
        cQuery += "AND C6.D_E_L_E_T_ = ' ' " + CEOL

        cQuery += "LEFT JOIN "+ RetSqlName( 'SA1' ) +" A1 " + CEOL
        cQuery += " ON A1.A1_FILIAL  = '"+ FWxFilial( 'SA1' ) +"' "+ CEOL
        cQuery += "AND A1.A1_COD     = C6.C6_CLI "+ CEOL
        cQuery += "AND A1.A1_LOJA    = C6.C6_LOJA "+ CEOL
        cQuery += "AND A1.D_E_L_E_T_ = ' ' "+ CEOL

        cQuery += "WHERE D3.D3_FILIAL = '"+ FWxFilial( 'SD3' ) +"' "+ CEOL
        if ! Empty( cProduto )
            cQuery += "  AND D3.D3_COD    = '"+ cProduto +"' " + CEOL
        endif
        cQuery += "  AND D3.D3_EMISSAO BETWEEN '"+ DtoS( dDe ) +"' AND '"+ DtoS( dAte ) +"' " + CEOL
        cQuery += "  AND D3.D3_TM     >= '500' " + CEOL
        cQuery += "  AND ( D3.D3_OP     <> '"+ Space( TAMSX3('D3_OP')[1] ) +"' OR D3.D3_CF = 'RE0' ) " + CEOL
        cQuery += "  AND D3.D3_ESTORNO = ' ' " + CEOL
        cQuery += "  AND D3.D_E_L_E_T_ = ' ' " + CEOL

        if lPEPNC08
            // Ponto de entrada que permite modificar a query de análise das movimentações de saída para o produto
            // Parâmetro 1: Indica o local da chamada do PE, sendo 1- contagem dos registros de saída do produto
            //													   2- contagem dos registros de movimentações internas ou OPs para o produto
            //													   3- soma das quantidades de saída do produto
            //													   4- soma das quantidades de movimentações internas ou OPs para o produto
            //													   5- conta quantos documentos de saída foram emitidos no período
            //													   6- conta quantas movimentações ou ops foram feitas no período
            //                                                     7- lê movimentações de saída do produto para exibição na tela de detalhamento de saídas
            //                                                     8 - lê movimentações internas e/ou com OPs para o produto         
            // Parâmetro 2: Indica a query padrão do sistema
            // Retorno esperado: query completa modificada ou incrementada pronta para execução
            xPEPNC08 := ExecBlock( 'PEPNC08', .F., .F., { 8, cQuery } )
            if ValType( xPEPNC08 ) == 'C' .and. ! Empty( xPEPNC08 )
                cQuery := xPEPNC08
            endif
        endif

        if nFil < len( _aFil )
            cQuery += "UNION ALL "+ CEOL
        endif
        
    next nFil

    // Devolve a filial que o usuário estava conectado quando iniciou a função
    cFilAnt := cFilHist

return cQuery

/*/{Protheus.doc} getCliSM0
Obtém os clientes do cadastro que tem relação com as empresas do grupo econômico
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 1/15/2025
@return array, aCliSM0
/*/
static function getCliSM0()

    local aCliSM0 := {} as array
    local cQuery  := "" as character
    local cAlias  := "" as character

    cQuery := "SELECT DISTINCT A1.A1_COD, A1.A1_LOJA FROM SYS_COMPANY M0 "
    cQuery += "INNER JOIN "+ RetSqlName( 'SA1' ) +" A1 "
    cQuery += " ON A1.A1_FILIAL = '"+ FWxFilial( 'SA1' ) +"' " 
    cQuery += "AND A1.A1_CGC    = M0.M0_CGC "
    cQuery += "AND A1.D_E_L_E_T_ = ' ' "
    cQuery += "WHERE M0.M0_CGC LIKE '"+ SubStr( SM0->M0_CGC, 1, 8 ) +"%' "
    cQuery += "  AND M0.D_E_L_E_T_ = ' ' "

    cAlias := MPSysOpenQuery( cQuery )
    if ! ( cAlias )->( EOF() )
        while ! ( cAlias )->( EOF() )
            aAdd( aCliSM0, { ( cAlias )->A1_COD, ( cAlias )->A1_LOJA } )
            ( cAlias )->( DBSkip() )
        end
    endif
    ( cAlias )->( DBCloseArea() )

return aCliSM0

/*/{Protheus.doc} JSGETDB
Retorna o link para o banco de dados configurado nos parâmetros do cliente
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 22/08/2023
@return character, cSupabase
/*/
User Function JSGETDB()
return "https://mqdxpnvezumlldeusbmh.supabase.co"

/*/{Protheus.doc} JSGETKEY
Função para devolver ao requisitante a API key de comunicação com o banco
@type function
@version 1.0
@author Jean Carlos Pandolfo Saggin
@since 22/08/2023
@return character, cApiKey
/*/
User Function JSGETKEY()
return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1xZHhwbnZlenVtbGxkZXVzYm1oIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk1NjQxMjIsImV4cCI6MjA1NTE0MDEyMn0._bjK4yUSX6jlkWYKdwg4ou0VUBjJpIHkD5jZb4o3lqY"
 
