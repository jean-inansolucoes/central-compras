#include 'protheus.ch'
#include 'topconn.ch'

/*/{Protheus.doc} JSRUN
Fun��o que permite a chamada da execu��o de outras fun�oes ADVPL
@type function
@version 12.1.2410
@author Jean Carlos P. Saggin
@since 25/05/2020
/*/
User Function JSRUN()

	Local oBtnCan := Nil
	Local oBtnExe := Nil
	Local oGetCmd := Nil
	Local cGetCmd := Space(250)
	Local oLblInf := Nil
	Local nChoice := 0 as numeric
	Local aTam    := { 080, 800 }
	Local nHor    := 0 as numeric
	Local nVer    := 0 as numeric 
	Local oFont   := TFont():New( 'Courier New', Nil, 16, Nil, .T. /* lBold */ )

	Private oDlgCmd := Nil

    // Permite que apenas usu�rios admin utilizem esta funcionalidade
    if !FWIsAdmin()
        U_JSHLP( 'NO_ADMIN',;
                 'Voc� n�o tem permiss�o de usu�rio administrador para executar esta rotina',;
                 'Devido a criticidade desta rotina, apenas usu�rios com perfil administrativo tem permiss�o e conhecimento adequado para execut�-la.' )
        Return Nil
    endif

	nChoice := Aviso( 'A T E N � � O !', 'Que tipo de fun��o deseja executar?', { 'Fun��o SQL', 'Fun��o AdvPL' } )

	// Quando comando SQL, abre janela maior para melhor visibilidade do comando
	if nChoice == 1	
		aTam := { 400, 800 }
	endif
	nHor := aTam[2]/2	// Largura em pixels
	nVer := aTam[1]/2	// Altura em pixels

	DEFINE MSDIALOG oDlgCmd TITLE "Executar... - " + U_JSGETVER() FROM 000, 000  TO aTam[1], aTam[2] COLORS 0, 16777215 PIXEL

	@ 002, 004 SAY oLblInf PROMPT "Informe aqui seu comando SQL ou fun��o ADVPL" SIZE 137, 007 OF oDlgCmd COLORS 0, 16777215 PIXEL

	if nChoice == 1	// SQL
		oGetCmd := TMultiGet():New( 011, 004, {|u| if( PCount() > 0, cGetCmd := u, cGetCmd ) }, oDlgCmd, nHor -6, nVer -31, oFont,,,,, .T. /* lPixel */ )
	else
		@ 011, 004 MSGET oGetCmd VAR cGetCmd SIZE 392, 010 OF oDlgCmd COLORS 0, 16777215 PIXEL
	endif
	
	@ nVer-15, 335 BUTTON oBtnExe PROMPT "&Executar" ACTION MsAguarde({|x| iif( nChoice == 1, runQuery( cGetCmd ), &( AllTrim(cGetCmd) ) ) }, 'Executando...', AllTrim( cGetCmd ), .F. ) WHEN !Empty( cGetCmd ) SIZE 061, 012 OF oDlgCmd PIXEL
	@ nVer-15, 279 BUTTON oBtnCan PROMPT "&Cancelar" ACTION oDlgCmd:End() SIZE 055, 012 OF oDlgCmd PIXEL

	ACTIVATE MSDIALOG oDlgCmd CENTERED

Return ( Nil )

/*/{Protheus.doc} runQuery
Fun��o utilizada para execu��o da query
@type function
@version 12.1.2410
@author Jean Carlos Pandolfo Saggin
@since 03/05/2023
@param cQuery, character, Query a ser executada
@return logical, lSuccess
/*/
static function runQuery( cQuery )
	
	local nResult  := 0 as numeric
	
	default cQuery := ""
	
	if ! Empty( cQuery )
		nResult := TcSQLExec( cQuery )
		if nResult < 0
			MsgStop( TCSqlError(), 'A T E N � � O !' )
		else
			MsgInfo( 'Comando executado com sucesso!', 'S U C E S S O !' )
		endif
	else
		nResult := -1
		MsgStop( 'Comando n�o foi informado!','A T E N � � O !' )
	endif
	
return nResult >= 0 
