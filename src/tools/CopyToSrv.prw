#include "rwmake.ch" 
#include "colors.ch"
#include "Topconn.ch"

#define VERSION iif(findFunction('U_JSGETVER'), U_JSGETVER(), '1.0' )            // retorna versão da integração

/*/{Protheus.doc} CopyToSrv
Função para copiar arquivos da maquina local para o server do protheus
@type function
@version 1.0
@author ICmais
@since 9/14/2021
/*/
User Function CopyToSrv()

	Local oDlg1

	Private cArqOri  := Space(100)
	Private cDirCopy := Space(100)

	@ 140,100 TO 310,430 DIALOG oDlg1 TITLE "Upload to Server - "+ VERSION
	@ 005,005 TO 070,160
	@ 010,010 Say "Arquivo:"
	@ 020,010 Get cArqOri Size 120, 12 
	@ 020,132 BUTTON "..." SIZE 10, 10 ACTION (cArqOri := cGetFile( "* | *.*" , "Selecione o arquivo", 0,"",.T.))
	@ 040,010 Say "Diretorio Server: "
	@ 050,010 Get cDirCopy Size 120, 12 
	@ 050,132 BUTTON "..." SIZE 10, 10 ACTION Eval({|| cDirCopy := cGetFile( "* | *.*" /* cMask */,;
																	 "Selecione um diretório de destino..." /* cTitle */,; 
																	 0,;
																	 "\" /* cInitDir */,;
																	 .T. /* lSave */,; 
																	 GETF_RETDIRECTORY /* nOptions */,; 
																	 .T. /* lShowTreeServer */,; 
																	 .T. /* lKeepCase */ ),; 
													cDirCopy := iif( ExistDir( cDirCopy ), cDirCopy, Space(100) ) } )
	@ 070,100 BMPBUTTON TYPE 1 ACTION Processa( {|| ProcArq() } ) 
	@ 070,130 BMPBUTTON TYPE 2 ACTION Close(oDlg1)

	ACTIVATE DIALOG oDlg1 CENTER

Return()

/*/{Protheus.doc} ProcArq
Função que processa a transferência do arquivo para o server
@type function
@version 1.0
@author ICmais
@since 9/14/2021
/*/
Static Function ProcArq()

	if !ExistDir(cDirCopy)
		MakeDir(cDirCopy)
	EndIf

	if CPYT2S(cArqOri, cDirCopy, .F.)
		MsgInfo("Arquivo Copiado",'Sucesso!')
	else
		Alert("Erro ao copiar o arquivo")
	EndIf
	
Return

/*/{Protheus.doc} CopyToLoc
Função para copiar arquivos do servidor para o computador local
@type function
@version 1.0
@author ICmais
@since 9/14/2021
/*/
User Function CopyToLoc()

	Local oDlg1

	Private cArqOri := Space(60)
	Private cDirCopy := Space(60)    

	@ 140,100 TO 310,430 DIALOG oDlg1 TITLE "Download from Server - "+ VERSION
	@ 005,005 TO 070,160
	@ 010,010 Say "Arquivo:"
	@ 020,010 Get cArqOri Size 120, 12
	@ 020,132 BUTTON "..." SIZE 10, 10 ACTION Eval({|| cArqOri := cGetFile( "* | *.*" /* cMask */,;
																	 "Busque o arquivo para download..." /* cTitle */,; 
																	 0,;
																	 "\" /* cInitDir */,;
																	 .F. /* lSave */,; 
																	 Nil /* nOptions */,; 
																	 .T. /* lShowTreeServer */,; 
																	 .T. /* lKeepCase */ ),; 
													cArqOri := iif( File( cArqOri ), cArqOri, Space(100) ) } )
	@ 040,010 Say "Diretorio Local:"
	@ 050,010 Get cDirCopy Size 120, 30
	@ 050,132 BUTTON "..." SIZE 10, 10 ACTION Eval({|| cDirCopy := cGetFile( "* | *.*" /* cMask */,;
																	 "Local do download..." /* cTitle */,; 
																	 0,;
																	 "" /* cInitDir */,;
																	 .T. /* lSave */,; 
																	 nOR( GETF_LOCALHARD, GETF_LOCALFLOPPY, GETF_RETDIRECTORY ) /* nOptions */,; 
																	 .F. /* lShowTreeServer */,; 
																	 .T. /* lKeepCase */ ),; 
													cDirCopy := iif( ExistDir( cDirCopy ), cDirCopy, Space(100) ) } )
	@ 070,100 BMPBUTTON TYPE 1 ACTION Processa( {|| ProcArqLoc() } )
	@ 070,130 BMPBUTTON TYPE 2 ACTION Close(oDlg1)

	ACTIVATE DIALOG oDlg1 CENTER

Return()

/*/{Protheus.doc} ProcArqLoc
Função que executa a transferência para o computador local
@type function
@version 1.0
@author ICmais
@since 9/14/2021
/*/
Static Function ProcArqLoc()

	if !ExistDir(cDirCopy)
		MakeDir(cDirCopy)
	EndIf

	if CPYS2T(cArqOri, cDirCopy, .F.)
		MsgInfo("Arquivo Copiado",'Sucesso!')
	else
		Alert("Erro ao copiar o arquivo")
	EndIf

Return
