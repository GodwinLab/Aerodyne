#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#If(Exists("AerodyneProcedureGateway_CleanUp#AerodyneProcedureGatewayExists") > 0) // so that Igor doesn't look for ipfs in the User Procedures folder on instrument computers

#include "ProcSet_TILDASinstrumentToolkit" // contains several required functions

#include "IRIS"
#include "WintelIgorLinkTcpIP"

#EndIf
