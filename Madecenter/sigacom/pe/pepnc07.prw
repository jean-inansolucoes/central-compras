#include 'totvs.ch'

/*/{Protheus.doc} pepnc07
PE para editar configuração dos campos do browse de produtos do Painel de Compras conforme necessidade do cliente
@type function
@version 12.1.2410
@author Jean Carlos Pandolfo Saggin
@since 03/12/2025
@return array, aModifiedColumns
/*/
user function pepnc07()
    
    local aColumns := PARAMIXB[1]
    
    if aScan( aColumns, {|x| AllTrim(x[17]) == 'PRCNEGOC' } ) > 0
        aColumns[ aScan( aColumns, {|x| AllTrim(x[17]) == 'PRCNEGOC' } ) ][4] := "@E 999,999,999.99"
    endif
    if aScan( aColumns, {|x| AllTrim(x[17]) == 'ULTPRECO' } ) > 0
        aColumns[ aScan( aColumns, {|x| AllTrim(x[17]) == 'ULTPRECO' } ) ][4] := "@E 999,999,999.99"
    endif
    if aScan( aColumns, {|x| AllTrim(x[17]) == 'QTDBLOQ' } ) > 0
        aColumns[ aScan( aColumns, {|x| AllTrim(x[17]) == 'QTDBLOQ' } ) ][14] := .T. // lDeleted
    endif
    if aScan( aColumns, {|x| AllTrim(x[17]) == 'DURAPRV' } ) > 0
        aColumns[ aScan( aColumns, {|x| AllTrim(x[17]) == 'DURAPRV' } ) ][14] := .T. // lDeleted
    endif
    if aScan( aColumns, {|x| AllTrim(x[17]) == 'LEADTIME' } ) > 0
        aColumns[ aScan( aColumns, {|x| AllTrim(x[17]) == 'LEADTIME' } ) ][14] := .T. // lDeleted
    endif
    if aScan( aColumns, {|x| AllTrim(x[17]) == 'TPLDTIME' } ) > 0
        aColumns[ aScan( aColumns, {|x| AllTrim(x[17]) == 'TPLDTIME' } ) ][14] := .T. // lDeleted
    endif
return aColumns
