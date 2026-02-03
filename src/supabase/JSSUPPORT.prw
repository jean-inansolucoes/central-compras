#include 'totvs.ch'

user function JSSUPPORT()

    local oDlg     as object
    local oBrowse  as object
    local oLayer   as object
    local aAdvSize := MsAdvSize()
    local aSize    := MsObjSize( aAdvSize[1], aAdvSize[2], aAdvSize[3], aAdvSize[4], 2, 2 )
    local bValid   := {|| .T. }
    local bOk      := {|| oDlg:End() }
    local bCancel  := {|| oDlg:End() }
    local aExtras  := {} as array                // Botões Outras Ações
    local bInit    := {|| EnchoiceBar( oDlg, bOk, bCancel,, aExtras ) }
    local aObjects := {} as array`

    oDlg := TDialog():New( aAdvSize[1], aAdvSize[2], aAdvSize[3], aAdvSize[4],'Help Center | Painel de Compras '+ U_JSGETVER(),,,,,CLR_BLACK,CLR_WHITE,,,.T. )

    


    oDlg:Activate( ,,,.T., bValid, ,bInit )


return nil
