#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//•WILTI_Connect()
//WILTI_EnqueString( "connect,host=127.0.0.1,port=1234,serverid=0" );

// Wintel Igor Link Tcp Ip
// WILTI
//
// This codeset acts as the go between for TDLWintel's TCP/IP bi-directional communication
//	It is intended to forward external command language ECL commands directly to the command que
// It will receive and parse whichever status message is returned
//
// To operate -> { agent | .xop }
//		to use the "agent" leave #define usingAgent uncommented
//		to use the .XOP comment #define usingAgent out
//
// To initialize invoke
// 	aWILTI_init()
// 	WILTI_Connect()
// 
// or
// 	WILTI_EnqueString( "connect,host=127.0.0.1,port=1234,serverid=0" );
// 
// To send/queue an ECL command
// 	WILTI_EnqueString( <string> );		//	 
// 	WILTI_EnqueStrings( <Wave/T> );		// 

#define usingTcpAgent
//
//
//		if using agent try
//	xWILTI_SetAgentFolder();	// auto
// xWILTI_SetAgentFolder( fpfToAgentFolder="c:override" )



	StrConstant k_wiltiWorkingDF = "WILTI_Folder";

Function WILTI_Connect()
	
	xWILTI_IsInitialized();

#ifdef usingTcpAgent

	WILTI_msg( "connect via agent" )
	NVAR usingAgent = root:wilti_folder:usingAgent
	usingAgent = 1;
	yWILTI_Start()



#elif

	WILTI_msg( "connect via xop" )

#endif


End

Function WILTI_EnqueString( str_ )
	String str_
	
	String ts = zWILTI_mssam();
	Wave/T nqtw = xWilti_QueueOut();
	variable queCount = dimSize( nqtw, 0 );
	//printf "was %d", queCount
	Redimension/N=( queCount + 1, 2 )	nqtw
	queCount = dimSize( nqtw, 0 );
	//printf "is now %d", queCount
	
	nqtw[ queCount - 1 ][ 0 ] = str_;  
	nqtw[ queCount - 1 ][ 1 ] = ts;

End

Function WILTI_EnqueStrings( waveToEnqueue )
	Wave/T waveToEnqueue
	
	Variable idex;
	for( idex = 0; idex < numpnts( waveToEnqueue ); idex += 1 )
		WILTI_EnqueString( waveToEnqueue[ idex ] );
	endfor

End



Function WILTI_msg( msg_ )
	String msg_
	
	xWILTI_IsInitialized();
	
	DFREF df = $("root:" + k_wiltiWorkingDF );
	Wave/T/SDFR=df msgtw = msgHistory;
	SVAR/Z/SDFR=df msg = msg
	if( svar_exists( msg ) )
		msg = msg_;
	endif
	redimension/N=( DimSize(msgtw,0) + 1, 2 ) msgtw
	variable idex;
	
	variable msgDepth = DimSize( msgtw, 0 );
	if( msgDepth > 1 )
		for( idex = msgDepth - 1; idex >= 1; idex-= 1 )
			msgtw[idex][0] = msgtw[ idex - 1 ][0] 
			msgtw[idex][1] = msgtw[ idex - 1 ][1] 
		endfor
	endif
	msgtw[0][0] = msg_;	msgtw[0][1] = zWILTI_mssam();

	xWilti_msg();
	
End





// BufferInbound get tacked on the bottom
// QueueOut  get tacked on the bottom

Function/wave xWilti_BufferInbound([trim])
	variable trim
	
	dfref df = $("root:" + k_wiltiWorkingDF );
	Wave/T/SDFR=df btw = bufferIn;
	
	if( paramIsDefault( trim ) )
		trim = 128;
	endif
	if( dimsize( btw, 0 ) > trim )
		variable excess = dimsize( btw, 0 ) - trim;
		deletepoints/m=0 0, excess, btw;
	endif
	return btw;
	
End

Function/wave xWilti_QueueOut([trim])
	variable trim

	dfref df = $("root:" + k_wiltiWorkingDF );
	Wave/T/SDFR=df btw = queueOut;
	if( paramIsDefault( trim ) )
		trim = 128;
	endif
	if( dimsize( btw, 0 ) > trim )
		variable excess = dimsize( btw, 0 ) - trim;
		deletepoints/m=0 0, excess, btw;
	endif
	return btw;
End

Function/wave xWilti_msg([trim])
	variable trim

	dfref df = $("root:" + k_wiltiWorkingDF );
	Wave/T/SDFR=df btw = msgHistory;
	if( paramIsDefault( trim ) )
		trim = 64;
	endif
	if( dimsize( btw, 0 ) > trim )
		variable excess = dimsize( btw, 0 ) - trim;
		deletepoints/m=0 trim, excess, btw;
	endif
	return btw;
End

	
Function xWILTI_DF()
	dfref df = $("root:" + k_wiltiWorkingDF );
	
	if( dataFolderRefStatus( df ) == 0 )
		string sf = getdataFolder(1);
		setdatafolder root:
		makeandorsetDF( k_wiltiWorkingDF );
		dfref df = $("root:" + k_wiltiWorkingDF );
		setdataFolder $sf
	endif
	
End

Function xWILTI_IsInitialized()

	NVAR/Z reinit = root:wilti_folder:reinit
	if( !nvar_exists( reinit ) )
		xWILTI_init()
		NVAR reinit = root:wilti_folder:reinit

	endif
	if(  reinit == 1 )
		xWILTI_init();
	endif
	
	return 1;
	
End
Function xWILTI_init()

	String saveFolder = GetDataFolder(1);	SetDataFolder root:;	MakeAndOrSetDF( k_wiltiWorkingDF )	
	
	
	String destStr, type, name, list = "", this_, defStr
	Variable num, defVal
	Variable idex, count
 
	list = list + "TYPE>String;NAME>msg;INIT:notset;" + "~"

	//   Background
	//
	// 
	//	 

	list = list + "TYPE>Variable;NAME>reinit;INIT>0;" + "~"
	list = list + "TYPE>Variable;NAME>usingAgent;INIT>0;" + "~"
	list = list + "TYPE>Variable;NAME>pollInboundSkip;INIT>2;" + "~"
	list = list + "TYPE>Variable;NAME>pollInbound;INIT>0;" + "~"

	list = list + "TYPE>String;NAME>uAgentDiskPath;INIT>C:tdlwintel:wilti;" + "~"
	list = list + "TYPE>String;NAME>LastFullInbound;INIT>;" + "~"
	list = list + "TYPE>String;NAME>msg;INIT>;" + "~"

	list = list + "TYPE>WaveT2;NAME>msgHistory;PNTS>0;" + "~"
	list = list + "TYPE>WaveT2;NAME>bufferIn;PNTS>0;" + "~"
	list = list + "TYPE>WaveT2;NAME>queueOut;PNTS>0;" + "~"
	list = list + "TYPE>WaveT;NAME>uAgentCheckDown;PNTS>0;" + "~"
	
		

	count = ItemsInList( list, "~" )
	for( idex = 0; idex < count; idex +=1 )
		this_ = StringFromList( idex, list, "~" )
		type = StringByKey( "TYPE", this_, ">");	name = StringByKey( "NAME",  this_, ">" ); num = str2num( StringByKey( "PNTS",  this_, ">" ) );
			
		strswitch( type )
			case "Variable":
				NVAR/Z  varRef = $name
				if( NVAR_Exists( varRef ) != 1 )
					Variable/G $name;							NVAR  varRef = $name
					defStr = StringByKey( "INIT",  this_, ">" );		varRef = str2num( defStr )
				else
					defStr = StringByKey( "INIT",  this_, ">" );		varRef = str2num( defStr )
				endif
				break;
			case "String":
				SVAR/Z  strRef = $name
				if( SVAR_Exists( strRef ) != 1 )
					String/G $name;							SVAR  strRef = $name
					defStr = StringByKey( "INIT",  this_, ">" );		strRef =  defStr 
				else
					defStr = StringByKey( "INIT",  this_, ">" );		strRef =  defStr 
				endif
				break;
			case "WaveT":
				Wave/T/Z  tw = $name
				if( WaveExists( tw ) != 1 )
					Make/N=(num)/T $name
				else
					Make/O/N=(num)/T $name
				endif
				break;
			case "WaveT2":
				Wave/T/Z  tw = $name
				if( WaveExists( tw ) != 1 )
					Make/N=(num,2)/T $name
				else
					Make/O/N=(num,2)/T $name
				endif
				break;
			case "WaveD":
				Wave/Z  w = $name
				if( WaveExists( w ) != 1 )
					Make/N=(num)/D $name
				else
					Make/O/N=(num)/D $name
				endif
				break;	
		endswitch
	endfor
	NVAR reinit = root:wilti_folder:reinit
	reinit = 0;

	
	WILTI_msg( "initialize wilti" )
	
	Wave/T checkDownList = root:wilti_folder:uAgentCheckDown;
	AppendString( checkDownList, "r:transient" );
	AppendString( checkDownList, "c:TDLWintel:transient" );
	//AppendString( checkDownList,  "ceryx:Users:scott:transient" );
	//AppendString( checkDownList,  specialdirPath("Documents", 0, 0, 0 ) );

	SetDataFolder $saveFolder;
	
End

Function xWILTI_SetAgentFolder( [fpfToAgentFolder ] )
	String fpfToAgentFolder
	
	dfref df = $("root:" + k_wiltiWorkingDF );
	SVAR/SDFR=df uAgentDiskPath = uAgentDiskPath;
	
	variable directorySuccess
	
	if( !ParamIsDefault( fpfToAgentFolder ) )
		
		uAgentDiskPath = fpfToAgentFolder
		
	else
		Wave/T/SDFR=df uAgentCheckDown = uAgentCheckDown;
		Variable idex, count = numpnts( uAgentCheckDown );
//		for( idex = 0; idex < count; idex += 1 )
//			NewPath/O/Q/Z tpath, uAgentCheckDown[ idex ];
//				
//			PathInfo tpath
//			if( V_Flag )
//				uAgentDiskPath = uAgentCheckDown[ idex ];
//			endif
//			KillPath/Z tpath;
//		endfor
		idex = 0
		directorySuccess = 0
		do
			NewPath/O/Q/Z tpath, uAgentCheckDown[ idex ];
			PathInfo tpath
			if( V_Flag )
				uAgentDiskPath = uAgentCheckDown[ idex ];
				directorySuccess = 1
			endif
			KillPath/Z tpath;
			idex += 1
		while((directorySuccess == 0) && (idex < count))
		
	endif
		
End

Function yWILTI_BackgroundCheck_Agent(s)		// called periodically to manage queueOut and procInboundIn
	STRUCT WMBackgroundStruct &s
	
	yWILTI_StatusOutbound();
	
	yWILTI_ProcOutbound();
	
	yWILTI_ProcInbound();
	
	// save next line stuff for IRIS to do
//	yWILTI_ProcessInputQueue(); // do the things in the queue if the queue has stuff in it
	
	return 0	// Continue background task
End

Function yWILTI_BackgroundCheck_XOP(s)		// called periodically to manage queueOut and procInboundIn
	STRUCT WMBackgroundStruct &s
	
	Printf "Task %s called, ticks=%d\r", s.name, s.curRunTicks
	return 0	// Continue background task
End

Function yWILTI_Start()
	Variable numTicks = 10		// every 166 ms
	 
	//NAME:wilti_tcpip;PROC:WILTI_BackgroundCheck_Agent;RUN:1;PERIOD:60;NEXT:324733;QUIT:0;FUNCERR:0;
	CtrlNamedBackground wilti_tcpip, status
	//SVAR s_info = s_info
	if( str2num( StringByKey( "RUN", s_info ) ) == 1 )
		yWILTI_Stop();
	endif
	NVAR usingAgent = root:wilti_folder:usingAgent
	if( usingAgent )
		xWILTI_SetAgentFolder();
		CtrlNamedBackground wilti_tcpip, period=numTicks, proc=yWILTI_BackgroundCheck_Agent
		CtrlNamedBackground wilti_tcpip, start
		WILTI_msg( "starting wilti monitor" )
	else
		CtrlNamedBackground wilti_tcpip, period=numTicks, proc=yWILTI_BackgroundCheck_XOP
		CtrlNamedBackground wilti_tcpip, start
		WILTI_msg( "starting wilti monitor" )

	endif
End


Function yWILTI_Stop()
	WILTI_msg( "stopping wilti monitor" )
	CtrlNamedBackground wilti_tcpip, stop
End

// ORIGINAL...
//Function yWILTI_ProcOutbound()
//
//	dfref df = $("root:" + k_wiltiWorkingDF );
//	Wave/T/SDFR=df btw = queueOut;
//	SVAR/SDFR=df uAgentDiskPath = uAgentDiskPath;
//
//	variable outCount = DimSize( btw, 0 );
//	if( outCount == 0 ) 
//		return 0;
//	endif
//	variable idex;
//	string outstr;
//	// eat the outbound from the front!;
//	
//	Make/T/O/N=( outCount ) wiltiOutTemp;
//	for( idex = 0; idex < outCount; idex += 1 )
//		outstr = btw[ idex ][ 0 ]
//		wiltiOutTemp[ idex ] = outstr
//	
//	endfor
//	Redimension/N=(0,2) btw;
//	String filename = "IgorECLRequest.txt"
//	String targetDir = uAgentDiskPath
//	Wave/T tw = wiltiOutTemp;
//	
//	Variable writeFlag = WriteOrAppendTextWave2File( tw, targetDir, filename )	
////	print "writing file"
//	
//	if( writeFlag != 1 )
//		printf "Error[%d] failed to write %s:%s\n", writeFlag, targetDir, filename
//	endif
//	
//	return 0;
//	
//End

// NEW VERSION (ONLY CLEARS QUEUE IF WRITE TO IgorECLRequest.txt SUCCEEDS)...
Function yWILTI_ProcOutbound()

	dfref df = $("root:" + k_wiltiWorkingDF );
	
	Wave/T/SDFR=df btw = queueOut;
	SVAR/SDFR=df uAgentDiskPath = uAgentDiskPath;

	variable outCount = DimSize( btw, 0 );
	if( outCount == 0 ) 
		return 0;
	endif
	variable idex;
	string outstr;
	
	// eat the outbound from the front!;
	Make/T/O/N=( outCount ) wiltiOutTemp;
	for( idex = 0; idex < outCount; idex += 1 )
		outstr = btw[ idex ][ 0 ]
		wiltiOutTemp[ idex ] = outstr
	endfor
	
	String filename = "IgorECLRequest.txt"
	String targetDir = uAgentDiskPath
	Wave/T tw = wiltiOutTemp;
	
	Variable writeFlag = WriteOrAppendTextWave2File( tw, targetDir, filename )	
	
	if( writeFlag != 1 )
		printf "Error[%d] failed to write %s:%s\n", writeFlag, targetDir, filename
		printf "Will try again next time..."
		return 0;
	endif
	
	Redimension/N=(0,2) btw; // queue is only emptied if write succeeded
		
	return 0;
	
End

Function yWILTI_StatusOutbound()

	dfref df = $("root:" + k_wiltiWorkingDF );
	
	Wave/T/SDFR=df/Z stw = statusOutFromIRIS;
	
	if(waveexists(stw))
		if(numpnts(stw) > 0)
		
		SVAR/SDFR=df uAgentDiskPath = uAgentDiskPath;
	
		String filename = "wilti_statusOutFromIgor.txt"
		String targetDir = uAgentDiskPath
	
		variable writeFlag = WriteTextWave2File( stw, targetDir, filename )	
	
		if( writeFlag != 1 )
			printf "Error[%d] failed to write %s:%s\n", writeFlag, targetDir, filename
			printf "Will try again next time..."
		else
			killwaves stw
		endif
		
		endif
	endif
	
	return 0;
	
End

Function yWILTI_ProcInbound()
	
	dfref df = $("root:" + k_wiltiWorkingDF );
	NVAR /SDFR=df pollInboundSkip = pollInboundSkip
	NVAR /SDFR=df pollInbound = pollInbound
	
	pollInbound -= 1;
	if( pollInbound > 0 )
		return 0;
	endif
	pollInbound = pollInboundSkip;

	SVAR/SDFR=df uAgentDiskPath = uAgentDiskPath;	
	
	variable refNum;
	String sf
		
	String filename = "wilti_NofityToIgor.txt"
	String targetDir = uAgentDiskPath
	String fpf, copyfpf
	sprintf fpf, "%s:%s", targetDir, filename
	sprintf copyfpf, "%s:t_%s", targetDir, filename
	fpf = removedoublecolon( fpf );
	copyfpf = removedoublecolon( copyfpf );
	MoveFile/O/Z=1 fpf as copyfpf;
	if( v_flag != 0 )
		//print "couldn't move file: ", fpf
	else
		sf = GetDataFolder(1);
		SetDataFolder root:; MakeAndOrSetDF( "Wintel_Status" );
		Open/R/Z refNum as copyfpf
		if( v_flag == 0 )
			close refNum
			LoadWave /A /W /D /Q /J /O copyfpf
			DeleteFile/Z copyfpf;
			SetDataFolder $sf;
			return 0
		endif
		SetDataFolder $sf
	endif

	filename = "wilti_parsedValves.txt"
	sprintf fpf, "%s:%s", targetDir, filename
	sprintf copyfpf, "%s:t_%s", targetDir, filename
	fpf = removedoublecolon( fpf );
	copyfpf = removedoublecolon( copyfpf );
	MoveFile/O/Z=1 fpf as copyfpf;
	if( v_flag != 0 )
		//print "couldn't move file: ", fpf
	else
		sf = GetDataFolder(1);
		SetDataFolder root:; MakeAndOrSetDF( "Wintel_Status" );
		Open/R/Z refNum as copyfpf
		if( v_flag == 0 )
			close refNum
			LoadWave /A /W /D /Q /J /O copyfpf
			DeleteFile/Z copyfpf;
			SetDataFolder $sf;
			return 0
		endif
		SetDataFolder $sf
	endif
	
	filename = "wilti_instructionQueueForIgor.txt"
	sprintf fpf, "%s:%s", targetDir, filename
	sprintf copyfpf, "%s:t_%s", targetDir, filename
	fpf = removedoublecolon( fpf );
	copyfpf = removedoublecolon( copyfpf );
	MoveFile/O/Z=1 fpf as copyfpf;
	if( v_flag != 0 )
		//print "couldn't move file: ", fpf
	else
		sf = GetDataFolder(1);
		SetDataFolder root:; MakeAndOrSetDF( "External_Instructions" );
		wave/T instructionQueueForIRIS = root:instructionQueueForIRIS
		Open/R/Z refNum as copyfpf
		if( v_flag == 0 )
			close refNum
			make/O/T t_instructionQueueForIRIS
			ReadFile2TextWave( copyfpf, t_instructionQueueForIRIS)
			DeleteFile/Z copyfpf;
			concatenate/T/NP {t_instructionQueueForIRIS}, instructionQueueForIRIS
			killwaves/Z t_instructionQueueForIRIS
			SetDataFolder $sf;
			return 0
		endif
		SetDataFolder $sf
	endif
	
	return 0;
		
End

Function/S zWILTI_mssam()
	
	variable now = datetime;
	string asStr = DTI_Datetime2Text( now, "american" );
	return asStr
End

//#include "concatenatewaves"