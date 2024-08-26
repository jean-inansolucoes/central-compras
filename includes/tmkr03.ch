#ifdef SPANISH
	#define STR0001 "Emision del Pedido de Ventas - Televentas"
	#define STR0002 "Este programa emitira el pedido de ventas creado en el sistema"
	#define STR0003 "con o sin autorizacion o la emision de factura."
	#define STR0004 "Informe los parametros de seleccion para emision de los Pedidos"
	#define STR0005 "A rayas"
	#define STR0006 "Administracion"
	#define STR0007 "Seleccionando Registros..."
	#define STR0008 "ANULADO POR EL OPERADOR"
	#define STR0009 "Empresa"
	#define STR0010 "LUGAR DE ENTREGA"
	#define STR0011 "DIRECCION DE COBRANZA"
	#define STR0012 "Nombe"
	#define STR0013 "Direccion"
	#define STR0014 "Inscr./RG"
	#define STR0015 "CPF/CNPJ"
	#define STR0016 "Atencion    : "
	#define STR0017 "Pedido      : "
	#define STR0018 "Emision     : "
	#define STR0019 "Flete       : "
	#define STR0020 "Inicio / Fin: "
	#define STR0021 "Gastos      : "
	#define STR0022 "Contacto    : "
	#define STR0023 "Descuento   : "
	#define STR0024 "Vendedor    : "
	#define STR0025 "Cond. Pago  : "
	#define STR0026 "Operador    : "
	#define STR0027 "Mapa Carg.  : "
	#define STR0028 "CARGA"
	#define STR0029 "NO CARGA"
	#define STR0030 "Forma Pago  : "
	#define STR0031 "Indemnizacion "
	#define STR0032 "Transportad.: "
	#define STR0033 "Vencimiento : "
	#define STR0034 "Observacion "
	#define STR0035 "Item Produtc                   Descripcion                     UM   Cant     Vlr Unit.      Vlr Item %Desc.     Val. Desc. %Aum  Val Aume"
	#define STR0036 "Total de las cantidades"
	#define STR0037 "Valor total del Pedido"
	#define STR0038 "| Vencto   Forma          Valor || Vencto   Forma          Valor || Vencto   Forma          Valor || Vencto   Forma          Valor |"
	#define STR0039 "De Atencion"
	#define STR0040 "A Atencion"
#else
	#ifdef ENGLISH
		#define STR0001 "Sales Order Issue - Telesales"
		#define STR0002 "This program will issue the sales order made by the system"
		#define STR0003 "with or without release or the issue of invoice."
		#define STR0004 "Inform the selection parameters to issue the Orders"
		#define STR0005 "Z-Form"
		#define STR0006 "Administration"
		#define STR0007 "Selecting Files..."
		#define STR0008 "CANCELLED BY OPERATOR"
		#define STR0009 "Company"
		#define STR0010 "PLACE FOR DELIVERY"
		#define STR0011 "COLLECTION ADDRESS"
		#define STR0012 "Name"
		#define STR0013 "Address"
		#define STR0014 "Inscr./ID"
		#define STR0015 "CPF/CNPJ"
		#define STR0016 "Servicing   : "
		#define STR0017 "Order       : "
		#define STR0018 "Issue       : "
		#define STR0019 "Freight     : "
		#define STR0020 "Beginn./ End: "
		#define STR0021 "Expenses    : "
		#define STR0022 "Contact     : "
		#define STR0023 "Discount    : "
		#define STR0024 "Sales Rep.  : "
		#define STR0025 "Paymt.Term  : "
		#define STR0026 "Operator    : "
		#define STR0027 "Load Map    : "
		#define STR0028 "LOAD   "
		#define STR0029 "DO NOT LOAD"
		#define STR0030 "Paymt.Term  : "
		#define STR0031 "Indemnity   : "
		#define STR0032 "Carrier     : "
		#define STR0033 "Validity    : "
		#define STR0034 "Observat. : "
		#define STR0035 "Product Item                   Description                        UM   Qty     Unit Vl.      Disc % Item Vl.     Incr % Disc Vl             Incr Vl"
		#define STR0036 "Total of quantities  "
		#define STR0037 "Order total Value    "
		#define STR0038 "| Due Dt   Mode           Value || Due Dt   Mode           Value || Due Dt   Mode           Value || Due Dt   Mode           Value |"
		#define STR0039 "From service  "
		#define STR0040 "To service       "
	#else
		#define STR0001 If( cPaisLoc $ "ANG|PTG", "Emissão Do Pedido De Vendas - Televendas", "Emissão do Pedido de Vendas - Televendas" )
		#define STR0002 If( cPaisLoc $ "ANG|PTG", "Este programa irá emitir o pedido de vendas criado no módulo", "Este programa irá emitir o pedido de vendas criado no sistema" )
		#define STR0003 If( cPaisLoc $ "ANG|PTG", "Com ou sem permissão ou a emissão da factura.", "com ou sem liberação ou a emissão da nota fiscal." )
		#define STR0004 "Informe os parâmetros de seleção para emissão dos Pedidos"
		#define STR0005 If( cPaisLoc $ "ANG|PTG", "Código de barras", "Zebrado" )
		#define STR0006 "Administração"
		#define STR0007 If( cPaisLoc $ "ANG|PTG", "A Seleccionar Registos...", "Selecionando Registros..." )
		#define STR0008 If( cPaisLoc $ "ANG|PTG", "Cancelado Pelo Operador", "CANCELADO PELO OPERADOR" )
		#define STR0009 "Empresa"
		#define STR0010 If( cPaisLoc $ "ANG|PTG", "Local De Entrega", "LOCAL DE ENTREGA" )
		#define STR0011 If( cPaisLoc $ "ANG|PTG", "Morada De Cobrança", "ENDEREÇO DE COBRANÇA" )
		#define STR0012 "Nome"
		#define STR0013 If( cPaisLoc $ "ANG|PTG", "Morada", "Endereço" )
		#define STR0014 If( cPaisLoc $ "ANG|PTG", "Inscr./Rg.", "Inscr./RG" )
		#define STR0015 If( cPaisLoc $ "ANG|PTG", "Nif", "CPF/CNPJ" )
		#define STR0016 "Atendimento : "
		#define STR0017 "Pedido      : "
		#define STR0018 If( cPaisLoc $ "ANG|PTG", "Emissão: ", "Emissão     : " )
		#define STR0019 If( cPaisLoc $ "ANG|PTG", "Serviço: ", "Frete       : " )
		#define STR0020 If( cPaisLoc $ "ANG|PTG", "Início / Fim: ", "Inicio / Fim: " )
		#define STR0021 If( cPaisLoc $ "ANG|PTG", "Despesas: ", "Despesas    : " )
		#define STR0022 If( cPaisLoc $ "ANG|PTG", "Contacto: ", "Contato     : " )
		#define STR0023 If( cPaisLoc $ "ANG|PTG", "Desconto: ", "Desconto    : " )
		#define STR0024 If( cPaisLoc $ "ANG|PTG", "Vendedor: ", "Vendedor    : " )
		#define STR0025 If( cPaisLoc $ "ANG|PTG", "Cond. pgt.: ", "Cond. Pagto : " )
		#define STR0026 If( cPaisLoc $ "ANG|PTG", "Operador: ", "Operador    : " )
		#define STR0027 If( cPaisLoc $ "ANG|PTG", "Mapa carreg.: ", "Mapa Carreg.: " )
		#define STR0028 If( cPaisLoc $ "ANG|PTG", "Carrega", "CARREGA" )
		#define STR0029 If( cPaisLoc $ "ANG|PTG", "Não Carrega", "NÃO CARREGA" )
		#define STR0030 If( cPaisLoc $ "ANG|PTG", "Forma pgt.: ", "Forma Pagto : " )
		#define STR0031 If( cPaisLoc $ "ANG|PTG", "Indemnização: ", "Indenização : " )
		#define STR0032 "Transportad.: "
		#define STR0033 If( cPaisLoc $ "ANG|PTG", "Validade: ", "Validade    : " )
		#define STR0034 "Observação: "
		#define STR0035 If( cPaisLoc $ "ANG|PTG", "Item Artigo                    Descrição                          UM   Qtd.     Vlr Unit.      Vlr.Item %Desc.     Vlr. Desc. %Acrésc.  Vlr.Acrésc.", "Item Produto                   Descrição                          UM   Qtde     Vlr Unit.      Vlr Item %Desc.     Val. Desc. %Acresc.  Val Acresc." )
		#define STR0036 "Total das quantidades"
		#define STR0037 If( cPaisLoc $ "ANG|PTG", "Valor Total Do Pedido", "Valor total do Pedido" )
		#define STR0038 If( cPaisLoc $ "ANG|PTG", "|Vencto.   Forma          Valor || Vencto.   Forma          Valor || Vencto.   Forma          Valor || Vencto.   Forma          Valor |", "| Vencto   Forma          Valor || Vencto   Forma          Valor || Vencto   Forma          Valor || Vencto   Forma          Valor |" )
		#define STR0039 "Do Atendimento"
		#define STR0040 If( cPaisLoc $ "ANG|PTG", "Até O Atendimento", "Ate o Atendimento" )
	#endif
#endif
