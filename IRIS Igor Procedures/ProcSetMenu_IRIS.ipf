#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#If(Exists("AerodyneProcedureGateway_CleanUp#AerodyneProcedureGatewayExists") > 0) // so that Igor doesn't look for ipfs in the User Procedures folder or display the Load Procedures menu on instrument computers

Menu "Macros"
	Submenu "Load Procedures"
		"IRIS", /Q, LoadProcSet_IRIS()
	end
end

Function LoadProcSet_IRIS()
	string sProcName = "ProcSet_IRIS"
	Execute/P/Q/Z "INSERTINCLUDE \""+sProcName+"\""
	Execute/P/Q/Z "COMPILEPROCEDURES "		// Note the space before final quote
End

#EndIf