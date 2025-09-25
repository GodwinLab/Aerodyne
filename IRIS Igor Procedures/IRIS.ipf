#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#IF(IgorVersion() >= 8.00) // IRIS's code does not work properly on Igor Pro versions earlier than Igor Pro 8

//////////////////////////////
// Create Menu Bar Launcher //
//////////////////////////////

Menu "Macros"
	"IRIS (Interface for Runs of Interleaved Samples)", IRIS()
End

///////////////////
// Main Function //
///////////////////

Function IRIS()
		
	// Set Igor's internal folders...
	SetDataFolder root:
	NewDataFolder/O/S STRPanel_Folder
	string/G DestinationDataFolder = "IRISstash"
	string/G LoadedWaveNamesSTR = ""
	string/G LoadedWaveNamesSTC = ""
	make/O/T thisFile_Spec
	SetDataFolder root:
	NewDataFolder/O/S $DestinationDataFolder
	SetDataFolder root:
	
	variable/G developmentMode = 0 // 0 for normal use
	GetFileFolderInfo/Q/Z=1 "Macintosh HD:Users:Rick:Professional:Aerodyne:Software Development:IRIS"
	if(V_flag == 0)
		developmentMode = 1 // 1 for testing on non-instrument computer
	endif
	
	variable/G scheduleAgentPeriod = 0.25 // seconds, interval at which to the schedule agent will check the schedule
	variable/G extCmdQueueAgentPeriod = 0.25 //seconds, interval at which IRIS will check for external commands from WILTI
	variable/G statusOutAgentPeriod = 0.25 // seconds, interval at which IRIS will broadcast its status to WILTI
	
	// Set paths on disk...
	string sIRISpath
	string/G sResultsPath
	string/G sDataPathOnDisk
	string/G sDataPathOnDisk_Original

	String platform = UpperStr(IgorInfo(2))
	Variable platform_pos = strsearch(platform,"WINDOWS",0)
	string homeDir
	string relativePath
	if (platform_pos >= 0)
		homeDir = GetEnvironmentVariable("USERPROFILE")
		relativePath = "C:IRIS"
	else
		homeDir = GetEnvironmentVariable("USER") // GetEnvironmentVariable("HOME")
	endif

	if(developmentMode == 1)
		// Path for .iris configuration file
		sIRISpath = 	"Macintosh HD:Users:Rick:Professional:Aerodyne:Software Development:IRIS"
		// Path for saving results files
		sResultsPath = 	sIRISpath
		// Path for .str and .stc data files
		sDataPathOnDisk = "Macintosh HD:Users:Rick:Professional:Aerodyne:Software Development:IRIS"
	else
		if (platform_pos >= 0)
			// Path for .iris configuration file
			sIRISpath = "C:IRIS"
			// Path for saving results files
			sResultsPath = sIRISpath
			// Path for .str and .stc data files
			sDataPathOnDisk = "C:TDLWintel:Data"
		else
			relativePath = "Library:CloudStorage:OneDrive-UniversityofCambridge:godwinlab_data:Aerodyne:Data"
			sIRISpath = "Mac:Users" + ":" + homeDir + ":" + relativePath + ":" + "IRIS"
			sResultsPath = sIRISpath
			sDataPathOnDisk = "Mac:Users" + ":" + homeDir + ":" + relativePath
		endif
	endif
	sDataPathOnDisk_Original = sDataPathOnDisk // only needed in case the user chooses files outside this directory in the reanalysis tab 
	NewPath/C/Q/O pIRISpath, sIRISpath // the "/C" flag creates the folder on disk if it does not already exist
	NewPath/C/Q/O pResultsPath, sResultsPath // the "/C" flag creates the folder on disk if it does not already exist
	NewPath/C/Q/O STRLoadPath, sDataPathOnDisk // needs to be called STRLoadPath for compatibility with STR/STC loader functions
	
	// Kill or hide windows to simplify user experience...
	KillWindow/Z IRISpanel
	if(developmentMode != 1)
		HideProcedures
		DoWindow/H/HIDE = 1
	endif
	CreateBrowser
	ModifyBrowser close
	string sListOfAllWindowNames = WinList("*", ";", "WIN:87") // 1+2+4+16+64 = 87
	print sListOfAllWindowNames
	variable numWindowsInList = ItemsInList(sListOfAllWindowNames, ";")
	variable windowIndex
	string sWindowNameTemp
	for(windowIndex=0;windowIndex<numWindowsInList;windowIndex+=1)
		sWindowNameTemp = StringFromList(windowIndex, sListOfAllWindowNames, ";")
		DoWindow/K $sWindowNameTemp // kill window
	endfor
	
	// Empty ECL_WorkFolder_A...
	NewDataFolder/O/S root:ECL_WorkFolder_A
	string sKilledWaves = KillWavesWhichMatchStr("*")
	SetDataFolder root:
	
	// Initialize variables
	variable/G IRIS_Running = 0
	variable/G IRIS_Standby = 0
	variable/G IRIS_ConfirmToRun = 0
	variable/G IRIS_ConfirmToStop = 0
	variable/G IRIS_ShouldStartToStop = 0
	variable/G IRIS_Stopping = 0
	variable/G IRIS_Reanalyzing = 0
	variable/G IRIS_ChoosingFiles = 0
	variable/G scheduleIndex = 0
	variable/G cycleNumber = 0
	variable/G azaInProgress = 0
	variable/G azaValveHasTriggered = 0
	variable/G azaValve
	variable/G azaInitialValveState
	variable/G azaOpeningTimer
	variable/G ABGtimer = DateTime
	variable/G advOptionsHidden = 1
	variable/G isTabRunOrReanalyze = 1
	variable/G isTabGas = 0
	variable/G isTabCal = 0
	variable/G showSecondPlotOnGraph = 0
	variable/G showSecondPlotOnGraph_old = 0
	variable/G useSeparateGraphAxis = 0
	variable/G useSeparateGraphAxis_old = 0
	variable/G gasToGraph1 = 0
	variable/G variableToGraph1 = 0
	variable/G gasToGraph2 = 0
	variable/G variableToGraph2 = 0
	variable/G output1_gasID, output2_gasID, output3_gasID
	variable/G output1_variableID, output2_variableID, output3_variableID
	variable/G layoutPageWidth = 850
	variable/G layoutPageHeight = layoutPageWidth*(11/8.5)
	variable/G minPointsForOutlierFiltering = 5
	variable/G MADsPerSD = 1.4826
	variable/G numOutputVariables = 1
	variable/G numSampleGases = 1
	variable/G numRefGases = 1
	variable/G numGases = 2
	variable/G numGasParams = 1
	variable/G numCalParams = 1
	variable/G numBasicParams = 1
	variable/G numAdvancedParams = 1
	variable/G numFilterParams = 1
	variable/G numGasesControl_DisableStatus = 0
	variable/G minNumSamples = 1
	variable/G maxNumSamples = 100
	variable/G minNumRefs = 0
	variable/G maxNumRefs = 10
	variable/G minBytesInFile = 1000 // bytes, to avoid a Loadwave error when trying to load a file with no data in it (1000 bytes is enough that it won't just be a header)
	variable/G calCurveIsValid = 0
	variable/G gasInfoIsValid = 0
	variable/G globalExecuteFlag = 0
	variable/G analysisOnly = 0 // set to 0 for normal use, or to 1 to have IRIS do real-time periodic data analysis but not control the system
	
	// Initialize strings
	string/G sRunID = "unnamed"
	string/G sAcquisitionStartTime
	string/G sAcquisitionEndTime
	string/G sSTRwaveList, sSTCwaveList
	string/G sSpecialDiagnosticOutput_name
	string/G sSpecialDiagnosticOutput_units
	string/G calEqnStr_UI, calEqnStr

	// Initialize waves
	make/O/T instructionQueueForIRIS
		
	variable i
	
	// Determine instrument serial number
	string/G sInstrumentID
	string/G sConfigFileName
	string sPotentialConfigFile = IndexedFile(pIRISpath, 0, ".iris")
	variable configFileExists = (strlen(sPotentialConfigFile) > 0)
	if(configFileExists == 1) // if found, get instrument ID from filename
		variable fileNameLength = strlen(sPotentialConfigFile)
		sInstrumentID = sPotentialConfigFile[0,fileNameLength-6]
	else // if not found, prompt user to input instrument ID
		print "IRIS configuration file does not yet exist."
		string sInstrumentIDlocal
		Prompt sInstrumentIDlocal, "Enter your instrument serial number inside the quotation marks, omitting \"TILDAS\" and hyphens (e.g. \"CS139\")"
		DoPrompt "Which instrument is this?", sInstrumentIDlocal
		sInstrumentID = sInstrumentIDlocal
	endif
	sConfigFileName = sInstrumentID + ".iris"
	
	// Get instrument type from serial number
	string sBestiaryFunctionName = "IRIS_BESTIARY_" + sInstrumentID
	if(exists(sBestiaryFunctionName) != 6)
		print "*** WARNING! Serial number \"" + sInstrumentID + "\" not recognized. Please check format and try again. ***"
		return 1
	endif
	FUNCREF IRIS_UTILITY_ProtoFunc IRIS_BestiaryFunction = $sBestiaryFunctionName
	IRIS_BestiaryFunction() // calls IRIS_BESTIARY_XXXXX(), where XXXXX is the instrument serial number without hyphen
	SVAR sInstrumentType = root:sInstrumentType
	
	// Construct scheme function names
	string/G sVariableFunctionName = "IRIS_SCHEME_DefineVariables_" + sInstrumentType
	string/G sParamFunctionName = "IRIS_SCHEME_DefineParams_" + sInstrumentType
	string/G sBuildScheduleFunctionName = "IRIS_SCHEME_BuildSchedule_" + sInstrumentType
	string/G sAnalyzeFunctionName = "IRIS_SCHEME_Analyze_" + sInstrumentType
		
	// Define output variables for this instrument type
	FUNCREF IRIS_UTILITY_ProtoFunc IRIS_VariableFunction = $sVariableFunctionName
	IRIS_VariableFunction() // calls IRIS_SCHEME_DefineVariables_XXXXX(), where XXXXX is the instrument type
	
	// Create waves of data filter settings for each output variable, which will be populated in the analysis function
	make/O/D/N=(numOutputVariables) root:wCheckForOutliers = 0
	make/O/D/N=(numOutputVariables) root:wOutlierThresholds = 0
	make/O/D/N=(numOutputVariables) root:wOutlierFilterGroups = 0
	
	// Load configuration parameters for this instrument, or define configuration parameters for this instrument type
	string sWaveListStr
	if(configFileExists == 1) // load config params from .iris file
				
		// Get the config parameter definitions from the .iris config file (crucially, this also gets the numbers of sample and reference gases)...
		IRIS_UTILITY_LoadConfig()
		wave/T wtParamNames, wtParamValues, wtParamUnits
		
		// Make a copy of them...
		Duplicate/O/T wtParamNames, wtParamNames_inFile
		Duplicate/O/T wtParamValues, wtParamValues_inFile
		Duplicate/O/T wtParamUnits, wtParamUnits_inFile
		
		// Get the config parameter definitions from this .ipf file (overwriting, and using the numbers of sample and ref gases that were loaded from the .iris file)...
		FUNCREF IRIS_UTILITY_ProtoFunc IRIS_ParamFunction = $sParamFunctionName
		IRIS_ParamFunction() // calls IRIS_SCHEME_DefineParams_XXXXX(), where XXXXX is the instrument type
		
		// Compare the two sets of config parameter definitions...
		variable configMatch = 1
		if(numpnts(wtParamNames) != numpnts(wtParamNames_inFile))
			configMatch = 0
			print num2str(numpnts(wtParamNames)) + " =/= " + num2str(numpnts(wtParamNames_inFile))
		else
			for(i=0;i<numpnts(wtParamNames);i+=1)
				if((cmpStr(wtParamNames[i], wtParamNames_inFile[i]) != 0) || (cmpStr(wtParamUnits[i], wtParamUnits_inFile[i])) != 0) // values don't have to match, of course
					configMatch = 0
					print "No match for " + wtParamNames[i]
				endif
			endfor
		endif
		
		if(configMatch == 0)
			
			// Determine how to rename the old .iris file if user chooses to proceed...
			variable adjustmentIndex = 1
			string sConfigFileRename = sInstrumentID + "_iris_" + num2istr(adjustmentIndex) + ".old"
			string sExistingFiles = IndexedFile(pIRISpath, -1, ".old")
			string sMatchStr = "*" + sConfigFileRename + "*"
			variable check = stringmatch(sExistingFiles, sMatchStr)
			if(check == 1)
				do
					adjustmentIndex += 1
					sConfigFileRename = sInstrumentID + "_iris_" + num2istr(adjustmentIndex) + ".old"
					sExistingFiles = IndexedFile(pIRISpath, -1, ".old")
					sMatchStr = "*" + sConfigFileRename + "*"
					check = stringmatch(sExistingFiles, sMatchStr)
				while(check == 1)
			endif
			
			string warningStr = "This version of IRIS requires more/fewer/different configuration parameters than currently exist in the " + sInstrumentID + ".iris configuration file on disk (probably because IRIS was upgraded)."
			warningStr += "\r\n"
			warningStr += "\r\n"
			warningStr += "IRIS must build a new " + sInstrumentID + ".iris file in order to proceed."
			warningStr += "\r\n"
			warningStr += "\r\n"
			warningStr += "The old file will be renamed " + sConfigFileRename + " and IRIS will transfer as many parameter values as possible from the old file to the new one."
			warningStr += "\r\n"
			warningStr += "\r\n"
			warningStr += "You will need to carefully check the Gases, Calibration, Data Filtering, and System tabs to make sure IRIS is set up as you want."
			warningStr += "\r\n"
			warningStr += "\r\n"
			warningStr += "Would you like to proceed?"
			
			DoAlert/T=("WARNING!") 1, warningStr
			
			if(V_flag == 1) // user clicked "Yes"
				
				// Transfer values for any parameters that still exist with the same names...
				for(i=0;i<numpnts(wtParamNames_inFile);i+=1)
					IRIS_UTILITY_SetParamValueByName( wtParamNames_inFile[i], wtParamValues_inFile[i] ) // will do nothing if the param name doesn't exist
				endfor
				
				// Rename old .iris file...
				MoveFile/P=pIRISpath sConfigFileName as sConfigFileRename
				print "Old configuration file renamed as: " + sConfigFileRename
	
				// Save the new config params to a new .iris file
				sWaveListStr = "wtParamNames;wtParamValues;wtParamUnits;"
				Save/O/J/DLIM=","/B/P=pIRISpath sWaveListStr as sConfigFileName
				print "Recreated configuration file: " + sConfigFileName
				
				// Propagate the new config params to the GUI tables
				IRIS_UTILITY_PropagateParamsToTables()
	
				killwaves wtParamNames_inFile, wtParamValues_inFile, wtParamUnits_inFile
				
			else
				return 1
			endif
			
		else
			
			// Restore parameters from the .iris config file, to get their saved values...
			Duplicate/O/T wtParamNames_inFile, wtParamNames
			Duplicate/O/T wtParamValues_inFile, wtParamValues
			Duplicate/O/T wtParamUnits_inFile, wtParamUnits
			
			// Propagate the new config params to the GUI tables
			IRIS_UTILITY_PropagateParamsToTables()
			
		endif
		
		killwaves wtParamNames_inFile, wtParamValues_inFile, wtParamUnits_inFile
		
	else // assign default config params, and create .iris file 
		
		FUNCREF IRIS_UTILITY_ProtoFunc IRIS_ParamFunction = $sParamFunctionName
		IRIS_ParamFunction() // calls IRIS_SCHEME_DefineParams_XXXXX(), where XXXXX is the instrument type
		sWaveListStr = "wtParamNames;wtParamValues;wtParamUnits;"
		Save/J/DLIM=","/B/P=pIRISpath sWaveListStr as sConfigFileName
		print "Created configuration file: " + sConfigFileName
		
	endif
		
	// Create generic labels for the sample and reference gases to be measured 
	numGases = numSampleGases + numRefGases
	make/O/N=(numGases) wNumCompleteMeasurementsByGas = 0 // temporary value
	make/O/T/N=(numGases) wtOutputGasNames
	for(i=0;i<numSampleGases;i+=1)
		wtOutputGasNames[i] = "S" + num2str(i+1)
	endfor
	for(i=0;i<numRefGases;i+=1)
		wtOutputGasNames[numSampleGases+i] = "R" + num2str(i+1)
	endfor
	
	// Create waves of means, standard deviations, and standard errors of the output variables, for the numeric displays
	make/O/D/N=(numGases,numOutputVariables) wOutputMeans, wOutputStDevs, wOutputStErrs
	wOutputMeans[][] = NaN
	wOutputStDevs[][] = NaN
	wOutputStErrs[][] = NaN
	
	// Create matrix of time series of output variables
	variable numCycles = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Cycles"))
	make/O/D/N=(numGases,numOutputVariables,numCycles) wOutputTimeSeriesMatrix, wOutputTimeSeriesErrorMatrix, wOutputTimeSeriesFilterMatrix
	make/O/D/N=(numGases,numCycles) wOutputTime
	wOutputTimeSeriesMatrix[][][] = NaN
	wOutputTimeSeriesErrorMatrix[][][] = NaN
	wOutputTimeSeriesFilterMatrix[][][] = 0
	wOutputTime = q + 1
	
	// Initialize waves for the numeric displays
	make/O/D/N=3 wDisplayMeans, wDisplayStDevs, wDisplayStErrs
	wDisplayMeans[] = NaN
	wDisplayStDevs[] = NaN
	wDisplayStErrs[] = NaN
	make/O/T/N=3 wtDisplayUnits, wtDisplayFormat
	wtDisplayUnits[] = ""
	wtDisplayFormat[] = "%.4f"
	
	// Initialize waves for the display graph
	make/O/D/N=(numCycles) wOutputMeanToGraph1, wOutputErrorToGraph1, wOutputFilterToGraph1, wOutputTimeToGraph1
	make/O/D/N=(numCycles) wOutputMeanToGraph2, wOutputErrorToGraph2, wOutputFilterToGraph2, wOutputTimeToGraph2
	wOutputMeanToGraph1[] = NaN
	wOutputErrorToGraph1[] = NaN
	wOutputFilterToGraph1[] = NaN
	wOutputTimeToGraph1 = p + 1
	wOutputMeanToGraph2[] = NaN
	wOutputErrorToGraph2[] = NaN
	wOutputFilterToGraph2[] = NaN
	wOutputTimeToGraph2 = p + 1
	variable windowCheck = WinType("IRISpanel#ResultGraph")
	if(windowCheck == 1)
		SetAxis/W=IRISpanel#ResultGraph/A
	endif
	wNumCompleteMeasurementsByGas = numCycles
	
	// Set which variables to display
	IRIS_UTILITY_PopulateNumericOutput(1)
	IRIS_UTILITY_PopulateNumericOutput(2)
	IRIS_UTILITY_PopulateNumericOutput(3)
	IRIS_UTILITY_PopulateGraphOutput()
	
	// Initialize waves and strings for the diagnostic graph
	make/O/D/N=0 wDiagnosticMask_Ref, wDiagnosticMask_Sample, wDiagnosticMask_Time
//	make/O/D/N=0 wDiagnosticMask_Ref1, wDiagnosticMask_Ref2 // TESTING!!!
	make/O/D/N=0 wDiagnosticOutput1_SamplePoints, wDiagnosticOutput1_SampleTime
	make/O/D/N=0 wDiagnosticOutput2_SamplePoints, wDiagnosticOutput2_SampleTime
	make/O/D/N=0 wDiagnosticOutput3_SamplePoints, wDiagnosticOutput3_SampleTime
	make/O/D/N=0 wDiagnosticOutput1_highFreqData, wDiagnosticOutput1_highFreqTime
	make/O/D/N=0 wDiagnosticOutput2_highFreqData, wDiagnosticOutput2_highFreqTime
	make/O/D/N=0 wDiagnosticOutput3_highFreqData, wDiagnosticOutput3_highFreqTime
	make/O/D/N=0 wDiagnosticOutput1_avgData, wDiagnosticOutput1_avgTime
	make/O/D/N=0 wDiagnosticOutput2_avgData, wDiagnosticOutput2_avgTime
	make/O/D/N=0 wDiagnosticOutput3_avgData, wDiagnosticOutput3_avgTime
	make/O/D/N=0 wDiagnosticOutput1_stDevData
	make/O/D/N=0 wDiagnosticOutput2_stDevData
	make/O/D/N=0 wDiagnosticOutput3_stDevData
	make/O/D/N=0 wGasTextMarkerX, wGasTextMarkerY
	SetScale/P d, 0, 0, "dat", wDiagnosticMask_Time
	SetScale/P d, 0, 0, "dat", wDiagnosticOutput1_SampleTime, wDiagnosticOutput2_SampleTime, wDiagnosticOutput3_SampleTime
	SetScale/P d, 0, 0, "dat", wDiagnosticOutput1_highFreqTime, wDiagnosticOutput2_highFreqTime, wDiagnosticOutput3_highFreqTime
	SetScale/P d, 0, 0, "dat", wDiagnosticOutput1_avgTime, wDiagnosticOutput2_avgTime, wDiagnosticOutput3_avgTime
	string/G diagnosticOutput1_name = "", diagnosticOutput1_units = ""
	string/G diagnosticOutput2_name = "", diagnosticOutput2_units = ""
	string/G diagnosticOutput3_name = "", diagnosticOutput3_units = ""
	
	// Initialize WILTI to establish tcp/ip link between Igor and TDL Wintel
	if(developmentMode == 0)
		WILTI_Connect()
	endif
	SetDataFolder root:
	
	// Create empty schedule waves
	make/O/N=0 wSchedule_Prologue_WhichTimer, wSchedule_Cycle_WhichTimer, wSchedule_Epilogue_WhichTimer
	make/O/D/N=0 wSchedule_Prologue_TriggerTime, wSchedule_Cycle_TriggerTime, wSchedule_Epilogue_TriggerTime
	make/O/T/N=0 wSchedule_Prologue_Action, wSchedule_Cycle_Action, wSchedule_Epilogue_Action
	make/O/T/N=0 wSchedule_Prologue_Argument, wSchedule_Cycle_Argument, wSchedule_Epilogue_Argument
	make/O/T/N=0 wSchedule_Prologue_Comment, wSchedule_Cycle_Comment, wSchedule_Epilogue_Comment
	
	// Build schedule
	FUNCREF IRIS_UTILITY_ProtoFunc IRIS_BuildScheduleFunction = $sBuildScheduleFunctionName
	IRIS_BuildScheduleFunction() // calls IRIS_SCHEME_BuildSchedule_XXXXX(), where XXXXX is the instrument type
	
	// Create an empty text wave to hold the STR/STC file names
	make/O/T/N=0 wSTRrootNames
	
	// These two lines are just used to prevent a strange Igor behavior wherein the number of gases is considered to have changed if you relaunch IRIS within the same Igor experiment
	variable/G numSampleGases_prev = numSampleGases
	variable/G numRefGases_prev = numRefGases
	
	DoUpdate
	
	// Launch GUI panel
	IRIS_GUI_Panel()
	
	return 0
	
End

///////////////////////////////
// Generic Utility Functions //
///////////////////////////////

Function IRIS_UTILITY_Run()
	
	SetDataFolder root:
	
	NVAR IRIS_ShouldStartToStop = root:IRIS_ShouldStartToStop
	NVAR IRIS_Stopping = root:IRIS_Stopping
	NVAR scheduleIndex = root:scheduleIndex
	NVAR cycleNumber = root:cycleNumber
	NVAR azaInProgress = root:azaInProgress
	NVAR azaValveHasTriggered = root:azaValveHasTriggered
	NVAR numGasesControl_DisableStatus = root:numGasesControl_DisableStatus
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	NVAR numGases = root:numGases
	NVAR numOutputVariables = root:numOutputVariables
	NVAR scheduleAgentPeriod = root:scheduleAgentPeriod
	NVAR gasToGraph1 = root:gasToGraph1
	NVAR variableToGraph1 = root:variableToGraph1
	NVAR gasToGraph2 = root:gasToGraph2
	NVAR variableToGraph2 = root:variableToGraph2
	
	SVAR sInstrumentID = root:sInstrumentID
	SVAR sConfigFileName = root:sConfigFileName
	SVAR sRunID = root:sRunID
	SVAR sDataPathOnDisk = root:sDataPathOnDisk
	SVAR sDataPathOnDisk_Original = root:sDataPathOnDisk_Original
	SVAR sAcquisitionStartTime = root:sAcquisitionStartTime
	
	wave wSchedule_Current_TriggerTime = root:wSchedule_Current_TriggerTime
	
	wave wNumCompleteMeasurementsByGas = root:wNumCompleteMeasurementsByGas
	
	variable i
	
	sDataPathOnDisk = sDataPathOnDisk_Original
	
	wave/T wtParamNames = root:wtParamNames
	wave/T wtParamValues = root:wtParamValues
	wave/T wtParamUnits = root:wtParamUnits
	wave/T wtGasParamNames = root:wtGasParamNames
	wave/T wtGasParamValues = root:wtGasParamValues
	wave/T wtGasParamUnits = root:wtGasParamUnits
//	wave/T wtCalParamNames = root:wtCalParamNames
//	wave/T wtCalParamValues = root:wtCalParamValues
//	wave/T wtCalParamUnits = root:wtCalParamUnits
	wave/T wtBasicParamNames = root:wtBasicParamNames
	wave/T wtBasicParamValues = root:wtBasicParamValues
	wave/T wtBasicParamUnits = root:wtBasicParamUnits
	wave/T wtAdvParamNames = root:wtAdvParamNames
	wave/T wtAdvParamValues = root:wtAdvParamValues
	wave/T wtAdvParamUnits = root:wtAdvParamUnits
	wave/T wtFilterParamNames = root:wtFilterParamNames
	wave/T wtFilterParamValues = root:wtFilterParamValues
	wave/T wtFilterParamUnits = root:wtFilterParamUnits
	
	numGasesControl_DisableStatus = 2 // 0 to have the numSampleGases gases control enabled when the gas info tab is selected; 2 to have it greyed out when the gas info tab is selected
	DoUpdate
	
	// Build the schedule...
	SVAR sBuildScheduleFunctionName = root:sBuildScheduleFunctionName
	FUNCREF IRIS_UTILITY_ProtoFunc IRIS_BuildScheduleFunction = $sBuildScheduleFunctionName
	IRIS_BuildScheduleFunction() // calls IRIS_SCHEME_BuildSchedule_XXXXX(), where XXXXX is the instrument type
	
	// Re-create matrix of time series of output variables, for the graph
	variable numCycles = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Cycles"))
	make/O/D/N=(numGases,numOutputVariables,numCycles) wOutputTimeSeriesMatrix, wOutputTimeSeriesErrorMatrix, wOutputTimeSeriesFilterMatrix
	make/O/D/N=(numGases,numCycles) wOutputTime
	make/O/D/N=(numCycles) wOutputMeanToGraph1, wOutputErrorToGraph1, wOutputFilterToGraph1, wOutputTimeToGraph1
	make/O/D/N=(numCycles) wOutputMeanToGraph2, wOutputErrorToGraph2, wOutputFilterToGraph2, wOutputTimeToGraph2
	wOutputTimeSeriesMatrix[][][] = NaN
	wOutputTimeSeriesErrorMatrix[][][] = NaN
	wOutputTimeSeriesFilterMatrix[][][] = 0
	wOutputTime = q + 1
	variable windowCheck = WinType("IRISpanel#ResultGraph")
	if(windowCheck == 1)
		SetAxis/W=IRISpanel#ResultGraph/A
	endif
	
	// Set which variable to graph...
	wOutputMeanToGraph1 = wOutputTimeSeriesMatrix[gasToGraph1][variableToGraph1][p]
	wOutputErrorToGraph1 = wOutputTimeSeriesErrorMatrix[gasToGraph1][variableToGraph1][p]
	wOutputFilterToGraph1 = (wOutputTimeSeriesFilterMatrix[gasToGraph1][variableToGraph1][p] == 0) ? 19 : 8
	wOutputTimeToGraph1 = wOutputTime[gasToGraph1][p]
	wOutputMeanToGraph2 = wOutputTimeSeriesMatrix[gasToGraph2][variableToGraph2][p]
	wOutputErrorToGraph2 = wOutputTimeSeriesErrorMatrix[gasToGraph2][variableToGraph2][p]
	wOutputFilterToGraph2 = (wOutputTimeSeriesFilterMatrix[gasToGraph2][variableToGraph2][p] == 0) ? 16 : 8
	wOutputTimeToGraph2 = wOutputTime[gasToGraph2][p]
	
	// Reset output variable mean values...
	wave wOutputMeans = root:wOutputMeans
	wave wOutputStDevs = root:wOutputStDevs
	wave wOutputStErrs = root:wOutputStErrs
	wOutputMeans[][] = NaN
	wOutputStDevs[][] = NaN
	wOutputStErrs[][] = NaN
	
	// Reset display variable values...
	wave wDisplayMeans = root:wDisplayMeans
	wave wDisplayStDevs = root:wDisplayStDevs
	wave wDisplayStErrs = root:wDisplayStErrs
	wDisplayMeans[] = NaN
	wDisplayStDevs[] = NaN
	wDisplayStErrs[] = NaN
	
	// Identify the latest STR file before this run starts...
	string sListOfSTRfiles = IndexedFile(STRLoadPath,-1, ".str")
	string sSortedListOfSTRfiles = SortList(sListOfSTRfiles, ";", 1) // descending alphabetic ASCII sort; newest timestamped STR file should be first in the resulting list
	string/G sAntecedentSTRfile = StringFromList(0, sSortedListOfSTRfiles, ";")
	
	// Record time at start of run...
	variable/G startTimeSecs = DateTime
	sAcquisitionStartTime = secs2time(startTimeSecs,2) + " on " + secs2date(startTimeSecs, -1)
	make/O/D/N=1 wTimerAnchors
	wTimerAnchors[0] = DateTime
	
	// Clear the status window...
	Notebook IRISpanel#StatusNotebook, selection={startOfFile, endOfFile}
	Notebook IRISpanel#StatusNotebook, text = "STATUS"
	
	wNumCompleteMeasurementsByGas[] = 0
	
	// Empty the text wave of STR/STC file names...
	make/O/T/N=0 wSTRrootNames
	
	// Empty ECL_WorkFolder_A...
	NewDataFolder/O/S root:ECL_WorkFolder_A
	string sKilledWaves = KillWavesWhichMatchStr("*")
	SetDataFolder root:
	
	//	DoUpdate/W=IRISpanel/E=1
	
	// Make "Prologue" the current schedule and go to its beginning
	IRIS_UTILITY_ClearSchedule("Current")
	IRIS_UTILITY_AppendScheduleToSchedule("Current", "Prologue")
	cycleNumber = 0
	scheduleIndex = 0
	
	DoUpdate
	
	// Start the schedule (i.e. launch the schedule agent background task)...
	IRIS_ShouldStartToStop = 0
	IRIS_Stopping = 0
	azaInProgress = 0
	azaValveHasTriggered = 0
	IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", secs2time(DateTime,3) + "  " + "Run started")
	variable ticksAtStart = ticks 
	CtrlNamedBackground ScheduleAgent, proc = IRIS_UTILITY_ScheduleAgent, period = scheduleAgentPeriod*60, start = ticksAtStart + scheduleAgentPeriod*60
	
	return 0
	
End

Function IRIS_UTILITY_Reanalyze()
	
	SetDataFolder root:
	
	NVAR isTabRunOrReanalyze = root:isTabRunOrReanalyze
	NVAR isTabGas = root:isTabGas
	NVAR numGasesControl_DisableStatus = root:numGasesControl_DisableStatus
	
	if(isTabRunOrReanalyze == 1)
		PopupMenu IRIS_GasChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
		PopupMenu IRIS_GasChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
		PopupMenu IRIS_GasChoice3_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
		PopupMenu IRIS_PlotGasChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
		PopupMenu IRIS_VariableChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
		PopupMenu IRIS_VariableChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
		PopupMenu IRIS_VariableChoice3_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
		PopupMenu IRIS_PlotVariableChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
		CheckBox IRIS_ShowSecondPlotOnGraph_tabRunOrReanalyze, win=IRISpanel, disable = 2
		CheckBox IRIS_PlotSeparateAxisChoice_tabRunOrReanalyze, win=IRISpanel, disable = 2
		PopupMenu IRIS_PlotGasChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
		PopupMenu IRIS_PlotVariableChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
	endif
	numGasesControl_DisableStatus = 2 // 0 to have the numSampleGases gases control enabled when the gas info tab is selected; 2 to have it greyed out when the gas info tab is selected
	DoUpdate
	
	NVAR IRIS_Reanalyzing = root:IRIS_Reanalyzing
	NVAR cycleNumber = root:cycleNumber
	NVAR gasToGraph1 = root:gasToGraph1
	NVAR variableToGraph1 = root:variableToGraph1
	NVAR gasToGraph2 = root:gasToGraph2
	NVAR variableToGraph2 = root:variableToGraph2
	NVAR showSecondPlotOnGraph = root:showSecondPlotOnGraph
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	NVAR numGases = root:numGases
	NVAR numOutputVariables = root:numOutputVariables
	NVAR scheduleAgentPeriod = root:scheduleAgentPeriod
	
	SVAR sInstrumentID = root:sInstrumentID
	SVAR sConfigFileName = root:sConfigFileName
	SVAR sRunID = root:sRunID
	SVAR sDataPathOnDisk = root:sDataPathOnDisk
	SVAR sDataPathOnDisk_Original = root:sDataPathOnDisk_Original
	SVAR sAcquisitionStartTime = root:sAcquisitionStartTime
	SVAR sAcquisitionEndTime = root:sAcquisitionEndTime
	
	wave/T wtParamNames = root:wtParamNames
	wave/T wtParamValues = root:wtParamValues
	wave/T wtParamUnits = root:wtParamUnits
	wave/T wtGasParamNames = root:wtGasParamNames
	wave/T wtGasParamValues = root:wtGasParamValues
	wave/T wtGasParamUnits = root:wtGasParamUnits
//	wave/T wtCalParamNames = root:wtCalParamNames
//	wave/T wtCalParamValues = root:wtCalParamValues
//	wave/T wtCalParamUnits = root:wtCalParamUnits
	wave/T wtBasicParamNames = root:wtBasicParamNames
	wave/T wtBasicParamValues = root:wtBasicParamValues
	wave/T wtBasicParamUnits = root:wtBasicParamUnits
	wave/T wtAdvParamNames = root:wtAdvParamNames
	wave/T wtAdvParamValues = root:wtAdvParamValues
	wave/T wtAdvParamUnits = root:wtAdvParamUnits
	wave/T wtFilterParamNames = root:wtFilterParamNames
	wave/T wtFilterParamValues = root:wtFilterParamValues
	wave/T wtFilterParamUnits = root:wtFilterParamUnits
	
	wave wNumCompleteMeasurementsByGas = root:wNumCompleteMeasurementsByGas
	
	variable i
	
	// Re-create matrix of time series of output variables, for the graph
	variable numCycles = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Cycles"))
	make/O/D/N=(numGases,numOutputVariables,numCycles) wOutputTimeSeriesMatrix, wOutputTimeSeriesErrorMatrix, wOutputTimeSeriesFilterMatrix
	make/O/D/N=(numGases,numCycles) wOutputTime
	make/O/D/N=(numCycles) wOutputMeanToGraph1, wOutputErrorToGraph1, wOutputFilterToGraph1, wOutputTimeToGraph1
	make/O/D/N=(numCycles) wOutputMeanToGraph2, wOutputErrorToGraph2, wOutputFilterToGraph2, wOutputTimeToGraph2
	wOutputTimeSeriesMatrix[][][] = NaN
	wOutputTimeSeriesErrorMatrix[][][] = NaN
	wOutputTimeSeriesFilterMatrix[][][] = 0
	wOutputTime = q + 1
	variable windowCheck = WinType("IRISpanel#ResultGraph")
	if(windowCheck == 1)
		SetAxis/W=IRISpanel#ResultGraph/A
	endif
	
	// Set which variable to graph...
	wOutputMeanToGraph1 = wOutputTimeSeriesMatrix[gasToGraph1][variableToGraph1][p]
	wOutputErrorToGraph1 = wOutputTimeSeriesErrorMatrix[gasToGraph1][variableToGraph1][p]
	wOutputFilterToGraph1 = (wOutputTimeSeriesFilterMatrix[gasToGraph1][variableToGraph1][p] == 0) ? 19 : 8
	wOutputTimeToGraph1 = wOutputTime[gasToGraph1][p]
	wOutputMeanToGraph2 = wOutputTimeSeriesMatrix[gasToGraph2][variableToGraph2][p]
	wOutputErrorToGraph2 = wOutputTimeSeriesErrorMatrix[gasToGraph2][variableToGraph2][p]
	wOutputFilterToGraph2 = (wOutputTimeSeriesFilterMatrix[gasToGraph2][variableToGraph2][p] == 0) ? 16 : 8
	wOutputTimeToGraph2 = wOutputTime[gasToGraph2][p]
	
	// Reset output variable values...
	wave wOutputMeans = root:wOutputMeans
	wave wOutputStDevs = root:wOutputStDevs
	wave wOutputStErrs = root:wOutputStErrs
	wOutputMeans[][] = NaN
	wOutputStDevs[][] = NaN
	wOutputStErrs[][] = NaN
	
	// Reset display variable values...
	wave wDisplayMeans = root:wDisplayMeans
	wave wDisplayStDevs = root:wDisplayStDevs
	wave wDisplayStErrs = root:wDisplayStErrs
	wDisplayMeans[] = NaN
	wDisplayStDevs[] = NaN
	wDisplayStErrs[] = NaN
	
	// Load the appropriate STR/STC file pair(s)...
	IRIS_UTILITY_LoadSTRandSTC()
	
	wave str_source_rtime = root:str_source_rtime
	
	sAcquisitionStartTime = secs2time(str_source_rtime[0],2) + " on " + secs2date(str_source_rtime[0], -1)
	sAcquisitionEndTime = secs2time(str_source_rtime[numpnts(str_source_rtime) - 1],2) + " on " + secs2date(str_source_rtime[numpnts(str_source_rtime) - 1], -1)
	
	// Analyze data...
	SVAR sAnalyzeFunctionName = root:sAnalyzeFunctionName
	FUNCREF IRIS_UTILITY_ProtoFunc IRIS_AnalyzeFunction = $sAnalyzeFunctionName
	IRIS_AnalyzeFunction() // calls IRIS_SCHEME_Analyze_XXXXX(), where XXXXX is the instrument type
	
	// Save results...
	IRIS_UTILITY_SaveResults()
	
	// Display completion message...
	IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", "Reanalysis Complete")
	
	// Declare end of reanalysis...
	IRIS_Reanalyzing = 0
	ModifyControl IRIS_Reanalyze_tabReanalyze, win = IRISpanel, title = "REANALYZE"
		
	if(isTabRunOrReanalyze == 1)
		PopupMenu IRIS_GasChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
		PopupMenu IRIS_GasChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
		PopupMenu IRIS_GasChoice3_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
		PopupMenu IRIS_PlotGasChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
		PopupMenu IRIS_VariableChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
		PopupMenu IRIS_VariableChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
		PopupMenu IRIS_VariableChoice3_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
		PopupMenu IRIS_PlotVariableChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
		CheckBox IRIS_ShowSecondPlotOnGraph_tabRunOrReanalyze, win=IRISpanel, disable = 0
		if(showSecondPlotOnGraph == 1)
			CheckBox IRIS_PlotSeparateAxisChoice_tabRunOrReanalyze, win=IRISpanel, disable = 0
			PopupMenu IRIS_PlotGasChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
			PopupMenu IRIS_PlotVariableChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
		endif
	endif
	numGasesControl_DisableStatus = 0 // 0 to have the numSampleGases gases control enabled when the gas info tab is selected; 2 to have it greyed out when the gas info tab is selected
	DoUpdate
	
	SetDataFolder root:
	
	return 0
	
End

Function IRIS_UTILITY_ScheduleAgent(s)
	STRUCT WMBackgroundStruct &s
	
	string saveFolder = GetDataFolder(1);
	SetDataFolder root:
		
	// Check whether the run has already stopped
	NVAR IRIS_Running = root:IRIS_Running
	if(IRIS_Running == 0)
		SetDataFolder $saveFolder
		return 1	// stop background task from running again
	endif
		
	wave wSchedule_Current_WhichTimer = root:wSchedule_Current_WhichTimer
	wave wSchedule_Current_TriggerTime = root:wSchedule_Current_TriggerTime
	wave/T wSchedule_Current_Action = root:wSchedule_Current_Action
	wave/T wSchedule_Current_Argument = root:wSchedule_Current_Argument
	wave/T wSchedule_Current_Comment = root:wSchedule_Current_Comment
	
	variable numScheduleEvents = numpnts(wSchedule_Current_TriggerTime)
	
	wave wTimerAnchors = root:wTimerAnchors
	
	wave wValveStates = root:Wintel_Status:wintcp_valveCurrentState
	
	wave wNumCompleteMeasurementsByGas = root:wNumCompleteMeasurementsByGas
	
	NVAR cycleNumber = root:cycleNumber
	NVAR scheduleIndex = root:scheduleIndex
	NVAR IRIS_ConfirmToStop = root:IRIS_ConfirmToStop
	NVAR IRIS_ShouldStartToStop = root:IRIS_ShouldStartToStop
	NVAR IRIS_Stopping = root:IRIS_Stopping
	NVAR azaInProgress = root:azaInProgress
	NVAR azaValve = root:azaValve
	NVAR azaInitialValveState = root:azaInitialValveState
	NVAR azaOpeningTimer = root:azaOpeningTimer
	NVAR azaValveHasTriggered = root:azaValveHasTriggered
	NVAR developmentMode = root:developmentMode
	NVAR startTimeSecs = root:startTimeSecs
	NVAR isTabRunOrReanalyze = root:isTabRunOrReanalyze
	NVAR isTabGas = root:isTabGas
	NVAR numSampleGases = root:numSampleGases
	NVAR showSecondPlotOnGraph = root:showSecondPlotOnGraph
	NVAR numGasesControl_DisableStatus = root:numGasesControl_DisableStatus
	NVAR analysisOnly = root:analysisOnly
	
	SVAR sInstrumentID = root:sInstrumentID
	SVAR DestinationDataFolder = root:STRPanel_Folder:DestinationDataFolder
	SVAR sAcquisitionEndTime = root:sAcquisitionEndTime
	SVAR sAntecedentSTRfile = root:sAntecedentSTRfile
	SVAR sRunID = root:sRunID
	
	wave/T wSTRrootNames = root:wSTRrootNames
		
	variable azaCurrentValveState
	variable subEventIndex
	
	string sActionFunctionName
	
	variable eventCap = 10 // max number of schedule events to do at one time
	variable azaOpeningTimeout = 5 // seconds
	
	wave/T wtParamNames = root:wtParamNames
	wave/T wtParamValues = root:wtParamValues
	wave/T wtParamUnits = root:wtParamUnits
	
	variable numCycles = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Cycles"))
	variable numRealCycles = numCycles // used only when analysisOnly == 1
	if((numCycles == 0) || (analysisOnly == 1)) // numCycles = 0 indicates perpetual run (up to the time limit)
		numCycles = 1e8 // effectively infinite
	endif
	
	variable timeLimit = str2num(IRIS_UTILITY_GetParamValueFromName("Time Limit"))
	timeLimit = timeLimit*3600 //conversion from hours to seconds
	
	variable anchorTime
	variable elapsedTime
	variable numSimultaneousEvents
	variable eventCount
	variable noMoreEvents
	variable maxNumCompleteSampleMeasurementsSoFar
	variable minNumCompleteSampleMeasurementsSoFar
	
	if(analysisOnly == 1) // enforced perpetual run, which will only stop by timeout, by manual stoppage, or by acquisition of the specified number of sample measurements
		
		// Check whether the time limit has been reached
		if((IRIS_ShouldStartToStop == 0) && (IRIS_Stopping == 0))
			if((DateTime - startTimeSecs) > timeLimit)
				IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", secs2time(DateTime,3) + "  " + "Time limit reached")
				IRIS_ShouldStartToStop = 1
				IRIS_ConfirmToStop = 0
				ModifyControl IRIS_Stop_tabRun, win = IRISpanel, title = "STOPPING"
			endif
		endif
		
		// Check whether the run is supposed to start stopping
		if(IRIS_ShouldStartToStop == 1)
			IRIS_Stopping = 1
			IRIS_ShouldStartToStop = 0
			// Replace the current schedule with the "Reset" schedule
			IRIS_UTILITY_ClearSchedule("Current")
			IRIS_UTILITY_AppendScheduleToSchedule("Current", "Reset")
			numScheduleEvents = numpnts(wSchedule_Current_TriggerTime)
			cycleNumber = numCycles + 2
			scheduleIndex = 0	
		endif
		
		// Check whether it's time to do the next scheduled action
		anchorTime = wTimerAnchors[wSchedule_Current_WhichTimer[scheduleIndex]]
		elapsedTime = DateTime - anchorTime
		if(elapsedTime < wSchedule_Current_TriggerTime[scheduleIndex]) // no, it's not time yet
			SetDataFolder $saveFolder
			return 0 // don't do anything below
		endif
		
		// Look ahead to see whether there are subsequent events that should also be done now
		// (Such actions would have a trigger time of 0 on timer 0.)
		// (The purpose of this feature is mainly to provide a mechanism for handing timing control over to TDL Wintel via the bc and cr ECL commands, if desired.)
		numSimultaneousEvents = 1
		eventCount = 0
		noMoreEvents = 0
		if(scheduleIndex < (numScheduleEvents - 1))
			do
				subEventIndex = scheduleIndex + 1 + eventCount
				noMoreEvents = 1
				if(wSchedule_Current_WhichTimer[subEventIndex] == 0)
					if(wSchedule_Current_TriggerTime[subEventIndex] == 0)
						if(stringMatch(wSchedule_Current_Argument[subEventIndex - 1], "*aza*") == 0) // don't go past an aza command in a single batch, because then the commands after the aza command will execute while the aza fill is still underway
							numSimultaneousEvents += 1
							noMoreEvents = 0
						endif
					endif
				endif
				eventCount += 1
			while((noMoreEvents == 0) && (eventCount < eventCap) && (subEventIndex < (numScheduleEvents - 1)))
		endif
		
		// Perform the scheduled action(s), if any
		if(isTabRunOrReanalyze == 1)
			PopupMenu IRIS_GasChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
			PopupMenu IRIS_GasChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
			PopupMenu IRIS_GasChoice3_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
			PopupMenu IRIS_PlotGasChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
			PopupMenu IRIS_VariableChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
			PopupMenu IRIS_VariableChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
			PopupMenu IRIS_VariableChoice3_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
			PopupMenu IRIS_PlotVariableChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
			CheckBox IRIS_ShowSecondPlotOnGraph_tabRunOrReanalyze, win=IRISpanel, disable = 2
			CheckBox IRIS_PlotSeparateAxisChoice_tabRunOrReanalyze, win=IRISpanel, disable = 2
			PopupMenu IRIS_PlotGasChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
			PopupMenu IRIS_PlotVariableChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
		endif
		for(eventCount=0;eventCount<numSimultaneousEvents;eventCount+=1)
			subEventIndex = scheduleIndex + eventCount
			if(strlen(wSchedule_Current_Action[subEventIndex]) > 0)
				sActionFunctionName = "IRIS_EVENT_" + wSchedule_Current_Action[subEventIndex]
				FUNCREF IRIS_UTILITY_ProtoActionFunc IRIS_ActionFunction = $sActionFunctionName
				IRIS_ActionFunction(wSchedule_Current_Argument[subEventIndex]) // calls IRIS_EVENT_XXXXX(YYYYY), where XXXXX is wSchedule_Current_Action[subEventIndex] and YYYYY is wSchedule_Current_Argument[subEventIndex]
			endif
		endfor
		if(isTabRunOrReanalyze == 1)
			PopupMenu IRIS_GasChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
			PopupMenu IRIS_GasChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
			PopupMenu IRIS_GasChoice3_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
			PopupMenu IRIS_PlotGasChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
			PopupMenu IRIS_VariableChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
			PopupMenu IRIS_VariableChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
			PopupMenu IRIS_VariableChoice3_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
			PopupMenu IRIS_PlotVariableChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
			CheckBox IRIS_ShowSecondPlotOnGraph_tabRunOrReanalyze, win=IRISpanel, disable = 0
			if(showSecondPlotOnGraph == 1)
				CheckBox IRIS_PlotSeparateAxisChoice_tabRunOrReanalyze, win=IRISpanel, disable = 0
				PopupMenu IRIS_PlotGasChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
				PopupMenu IRIS_PlotVariableChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
			endif
		endif
		
		// Update timer zero
		wTimerAnchors[0] = DateTime // timer 0 is always the time since the previous schedule event was done
		
		// Increment the schedule index
		if(scheduleIndex < 0)
			scheduleIndex = 0
		else
			scheduleIndex += numSimultaneousEvents
		endif
			
		maxNumCompleteSampleMeasurementsSoFar = wavemax(wNumCompleteMeasurementsByGas, 0, (numSampleGases - 1))
		minNumCompleteSampleMeasurementsSoFar = wavemin(wNumCompleteMeasurementsByGas, 0, (numSampleGases - 1))
		
		// When the current schedule is done, either advance to the next one or end the run
		if(scheduleIndex >= numScheduleEvents)
			if(cycleNumber > numCycles) // the Epilogue (cycleNumber = numCycles + 1) or the Reset (cycleNumber = numCycles + 2) just finished
				// Turn ourself off now that all schedules are done
				sAcquisitionEndTime = secs2time(DateTime,2) + " on " + secs2date(DateTime, -1)
				if(maxNumCompleteSampleMeasurementsSoFar > 0)
					IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", secs2time(DateTime,3) + "  " + "Run stopped")
					IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", "          " + "Saving results...")
				else
					IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", secs2time(DateTime,3) + "  " + "Run stopped before data acquired")
				endif
				IRIS_UTILITY_SaveResults()
				ModifyControl IRIS_Run_tabRun, win = IRISpanel, title = "RUN"
				ModifyControl IRIS_Stop_tabRun, win = IRISpanel, title = "STOPPED"
				IRIS_Running = 0
				IRIS_ShouldStartToStop = 0
				IRIS_Stopping = 0
				numGasesControl_DisableStatus = 0 // 0 to have the numSampleGases gases control enabled when the gas info tab is selected; 2 to have it greyed out when the gas info tab is selected
			else
				if(minNumCompleteSampleMeasurementsSoFar >= numRealCycles) // the last Cycle (minNumCompleteSampleMeasurementsSoFar = numRealCycles) has finished
					// Make "Epilogue" the current schedule and start at its beginning
					IRIS_UTILITY_ClearSchedule("Current")
					IRIS_UTILITY_AppendScheduleToSchedule("Current", "Epilogue")
					numScheduleEvents = numpnts(wSchedule_Current_TriggerTime)
					cycleNumber += 1
					scheduleIndex = 0
				else  // either the Prologue (cycleNumber = 0) or a cycle other than the last one ((cycleNumber > 0) && (minNumCompleteSampleMeasurementsSoFar < numRealCycles)) just finished
					// Make "Cycle" the current schedule and start at its beginning
					IRIS_UTILITY_ClearSchedule("Current")
					IRIS_UTILITY_AppendScheduleToSchedule("Current", "Cycle")
					numScheduleEvents = numpnts(wSchedule_Current_TriggerTime)
					cycleNumber += 1
					scheduleIndex = 0
				endif
			endif
		endif
		
		DoUpdate
		
		SetDataFolder $saveFolder
		return 0 // don't do anything below
		
	endif
	
	// Check whether TDL Wintel is actually still acting on an aza (i.e. fill to pressure) command, and set azaInProgress to zero if not
	if(azaInProgress == 1)
		// get azaCurrentValveState via TCP/IP using azaValve...
		azaCurrentValveState = wValveStates[azaValve]
		// then...
		if(azaValveHasTriggered == 1)
			if(azaCurrentValveState == azaInitialValveState)
				print "aza has ended, valve = " + num2str(azaValve)
				azaInProgress = 0
				azaValveHasTriggered = 0
				wTimerAnchors[0] = DateTime // reset timer 0 at the completion of the aza fill
			endif
		else
			if((azaCurrentValveState != azaInitialValveState) || (DateTime > azaOpeningTimer + azaOpeningTimeout)) // if after azaOpeningTimeout seconds, the valve state has not been observed to have changed, it is assumed that aza started and completed within one schedule agent interval
				azaValveHasTriggered = 1
				print "aza valve has triggered, valve = " + num2str(azaValve)
			endif
		endif
	endif
	
	// If TDL Wintel really is still acting on an aza command, don't move on to the next event yet (and don't stop the run)
	if(azaInProgress == 1)
		SetDataFolder $saveFolder
		return 0 // don't do anything below
	endif
	
	// Check whether the time limit has been reached
	if((IRIS_ShouldStartToStop == 0) && (IRIS_Stopping == 0))
		if((DateTime - startTimeSecs) > timeLimit)
			IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", secs2time(DateTime,3) + "  " + "Time limit reached")
			IRIS_ShouldStartToStop = 1
			IRIS_ConfirmToStop = 0
			ModifyControl IRIS_Stop_tabRun, win = IRISpanel, title = "STOPPING"
		endif
	endif
	
	// Check whether the run is supposed to start stopping
	if(IRIS_ShouldStartToStop == 1)
		IRIS_Stopping = 1
		IRIS_ShouldStartToStop = 0
		// Replace the current schedule with the "Reset" schedule
		IRIS_UTILITY_ClearSchedule("Current")
		IRIS_UTILITY_AppendScheduleToSchedule("Current", "Reset")
		numScheduleEvents = numpnts(wSchedule_Current_TriggerTime)
		cycleNumber = numCycles + 2
		scheduleIndex = 0	
	endif
	
	// Check whether it's time to do the next scheduled action
	anchorTime = wTimerAnchors[wSchedule_Current_WhichTimer[scheduleIndex]]
	elapsedTime = DateTime - anchorTime
	if(elapsedTime < wSchedule_Current_TriggerTime[scheduleIndex]) // no, it's not time yet
		SetDataFolder $saveFolder
		return 0 // don't do anything below
	endif
	
	// Look ahead to see whether there are subsequent events that should also be done now
	// (Such actions would have a trigger time of 0 on timer 0.)
	// (The purpose of this feature is mainly to provide a mechanism for handing timing control over to TDL Wintel via the bc and cr ECL commands, if desired.)
	numSimultaneousEvents = 1
	eventCount = 0
	noMoreEvents = 0
	if(scheduleIndex < (numScheduleEvents - 1))
		do
			subEventIndex = scheduleIndex + 1 + eventCount
			noMoreEvents = 1
			if(wSchedule_Current_WhichTimer[subEventIndex] == 0)
				if(wSchedule_Current_TriggerTime[subEventIndex] == 0)
					if(stringMatch(wSchedule_Current_Argument[subEventIndex - 1], "*aza*") == 0) // don't go past an aza command in a single batch, because then the commands after the aza command will execute while the aza fill is still underway
						numSimultaneousEvents += 1
						noMoreEvents = 0
					endif
				endif
			endif
			eventCount += 1
		while((noMoreEvents == 0) && (eventCount < eventCap) && (subEventIndex < (numScheduleEvents - 1)))
	endif
	
	// Perform the scheduled action(s), if any
	if(isTabRunOrReanalyze == 1)
		PopupMenu IRIS_GasChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
		PopupMenu IRIS_GasChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
		PopupMenu IRIS_GasChoice3_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
		PopupMenu IRIS_PlotGasChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
		PopupMenu IRIS_VariableChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
		PopupMenu IRIS_VariableChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
		PopupMenu IRIS_VariableChoice3_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
		PopupMenu IRIS_PlotVariableChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
		CheckBox IRIS_ShowSecondPlotOnGraph_tabRunOrReanalyze, win=IRISpanel, disable = 2
		CheckBox IRIS_PlotSeparateAxisChoice_tabRunOrReanalyze, win=IRISpanel, disable = 2
		PopupMenu IRIS_PlotGasChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
		PopupMenu IRIS_PlotVariableChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
	endif
	for(eventCount=0;eventCount<numSimultaneousEvents;eventCount+=1)
		subEventIndex = scheduleIndex + eventCount
		if(strlen(wSchedule_Current_Action[subEventIndex]) > 0)
			sActionFunctionName = "IRIS_EVENT_" + wSchedule_Current_Action[subEventIndex]
			FUNCREF IRIS_UTILITY_ProtoActionFunc IRIS_ActionFunction = $sActionFunctionName
			IRIS_ActionFunction(wSchedule_Current_Argument[subEventIndex]) // calls IRIS_EVENT_XXXXX(YYYYY), where XXXXX is wSchedule_Current_Action[subEventIndex] and YYYYY is wSchedule_Current_Argument[subEventIndex]
		endif
	endfor
	if(isTabRunOrReanalyze == 1)
		PopupMenu IRIS_GasChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
		PopupMenu IRIS_GasChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
		PopupMenu IRIS_GasChoice3_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
		PopupMenu IRIS_PlotGasChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
		PopupMenu IRIS_VariableChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
		PopupMenu IRIS_VariableChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
		PopupMenu IRIS_VariableChoice3_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
		PopupMenu IRIS_PlotVariableChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
		CheckBox IRIS_ShowSecondPlotOnGraph_tabRunOrReanalyze, win=IRISpanel, disable = 0
		if(showSecondPlotOnGraph == 1)
			CheckBox IRIS_PlotSeparateAxisChoice_tabRunOrReanalyze, win=IRISpanel, disable = 0
			PopupMenu IRIS_PlotGasChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
			PopupMenu IRIS_PlotVariableChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
		endif
	endif
	
	// Update timer zero
	wTimerAnchors[0] = DateTime // timer 0 is always the time since the previous schedule event was done
	
	// Increment the schedule index
	if(scheduleIndex < 0)
		scheduleIndex = 0
	else
		scheduleIndex += numSimultaneousEvents
	endif
		
	maxNumCompleteSampleMeasurementsSoFar = wavemax(wNumCompleteMeasurementsByGas, 0, (numSampleGases - 1))
	
	// When the current schedule is done, either advance to the next one or end the run
	if(scheduleIndex >= numScheduleEvents)
		if(cycleNumber > numCycles) // the Epilogue (cycleNumber = numCycles + 1) or the Reset (cycleNumber = numCycles + 2) just finished
			// Turn ourself off now that all schedules are done
			sAcquisitionEndTime = secs2time(DateTime,2) + " on " + secs2date(DateTime, -1)
			if(maxNumCompleteSampleMeasurementsSoFar > 0)
				IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", secs2time(DateTime,3) + "  " + "Run stopped")
				IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", "          " + "Saving results...")
			else
				IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", secs2time(DateTime,3) + "  " + "Run stopped before data acquired")
			endif
			IRIS_UTILITY_SaveResults()
			ModifyControl IRIS_Run_tabRun, win = IRISpanel, title = "RUN"
			ModifyControl IRIS_Stop_tabRun, win = IRISpanel, title = "STOPPED"
			IRIS_Running = 0
			IRIS_ShouldStartToStop = 0
			IRIS_Stopping = 0
			numGasesControl_DisableStatus = 0 // 0 to have the numSampleGases gases control enabled when the gas info tab is selected; 2 to have it greyed out when the gas info tab is selected
		else
			if(cycleNumber == numCycles) // the last Cycle (cycleNumber = numCycles) just finished
				// Make "Epilogue" the current schedule and start at its beginning
				IRIS_UTILITY_ClearSchedule("Current")
				IRIS_UTILITY_AppendScheduleToSchedule("Current", "Epilogue")
				numScheduleEvents = numpnts(wSchedule_Current_TriggerTime)
				cycleNumber += 1
				scheduleIndex = 0
			else  // either the Prologue (cycleNumber = 0) or a cycle other than the last one (0 < cycleNumber < numCycles) just finished
				// Make "Cycle" the current schedule and start at its beginning
				IRIS_UTILITY_ClearSchedule("Current")
				IRIS_UTILITY_AppendScheduleToSchedule("Current", "Cycle")
				numScheduleEvents = numpnts(wSchedule_Current_TriggerTime)
				cycleNumber += 1
				scheduleIndex = 0
			endif
		endif
	endif
	
	DoUpdate
	
	SetDataFolder $saveFolder
	return 0
	
End

Function IRIS_UTILITY_ExtCmdQueueAgent(s)
	STRUCT WMBackgroundStruct &s
	
	string saveFolder = GetDataFolder(1);
	SetDataFolder root:
	
	NVAR calCurveIsValid = root:calCurveIsValid
	NVAR gasInfoIsValid = root:gasInfoIsValid
	NVAR IRIS_ChoosingFiles = root:IRIS_ChoosingFiles
	NVAR IRIS_Reanalyzing = root:IRIS_Reanalyzing
	NVAR IRIS_Running = root:IRIS_Running
	NVAR IRIS_ConfirmToRun = root:IRIS_ConfirmToRun
	NVAR IRIS_ConfirmToStop = root:IRIS_ConfirmToStop
	NVAR IRIS_ShouldStartToStop = root:IRIS_ShouldStartToStop
	NVAR IRIS_Stopping = root:IRIS_Stopping
	
	string thisInstruction
	variable i
	
	// read oldest line from external command queue
	// then decide whether to:
	// (1) act on it and delete it from the queue,
	// (2) ignore it and delete it from the queue, or
	// (3) ignore it and leave it in the queue to be found again next time
		
	wave/T instructionQueueForIRIS = root:instructionQueueForIRIS
	if(numpnts(instructionQueueForIRIS) > 0)
					
		// check for a clear queue command, and if one is found, delete it and all previous commands from the queue
		for(i=numpnts(instructionQueueForIRIS)-1;i>=0;i-=1)
			thisInstruction = instructionQueueForIRIS[i]
			if(strlen(thisInstruction) == 0)
				deletePoints i, 1, instructionQueueForIRIS
			else
				if(cmpstr(lowerstr(thisInstruction), "clearqueue") == 0)
					deletePoints 0, (i+1), instructionQueueForIRIS
					break
				endif
			endif
		endfor
		
		if(numpnts(instructionQueueForIRIS) > 0)
		
			thisInstruction = instructionQueueForIRIS[0]
		
			if(cmpstr(lowerstr(thisInstruction), "run") == 0)
				
				IRIS_UTILITY_ValidateGasInfo()
				NVAR gasInfoIsValid = root:gasInfoIsValid
				
				if(calCurveIsValid == 0)
					IRIS_EVENT_ReportStatus("Received external command to RUN")
					IRIS_EVENT_ReportStatus("  CANNOT RUN: calibration curve is invalid")
					deletePoints 0, 1, instructionQueueForIRIS
					DoUpdate
				elseif(gasInfoIsValid == 0)
					IRIS_EVENT_ReportStatus("Received external command to RUN")
					IRIS_EVENT_ReportStatus("  CANNOT RUN: gas info is invalid")
					deletePoints 0, 1, instructionQueueForIRIS
					DoUpdate
				else
					if(IRIS_Reanalyzing == 0)
						if(IRIS_Running == 0)
							IRIS_EVENT_ReportStatus("Received external command to RUN")
							IRIS_Running = 1
							IRIS_ConfirmToRun = 0
							IRIS_ConfirmToStop = 0
							ModifyControl IRIS_Run_tabRun, win = IRISpanel, title = "RUNNING"
							ModifyControl IRIS_Stop_tabRun, win = IRISpanel, title = "STOP"
							deletePoints 0, 1, instructionQueueForIRIS
							DoUpdate
							IRIS_UTILITY_Run()
						else
							IRIS_EVENT_ReportStatus("Received external command to RUN")
							IRIS_EVENT_ReportStatus("  Command ignored: a run is already underway")
							deletePoints 0, 1, instructionQueueForIRIS
							DoUpdate
						endif
					else
						IRIS_EVENT_ReportStatus("Received external command to RUN")
						IRIS_EVENT_ReportStatus("  CANNOT RUN: IRIS is currently reanalyzing data")
						deletePoints 0, 1, instructionQueueForIRIS
						DoUpdate
					endif
				endif
			
			elseif(cmpstr(lowerstr(thisInstruction), "stop") == 0)
			
				if((IRIS_Running == 1) && (IRIS_ShouldStartToStop == 0) && (IRIS_Stopping == 0))
					IRIS_EVENT_ReportStatus("Received external command to STOP")
					IRIS_ShouldStartToStop = 1
					IRIS_ConfirmToRun = 0
					IRIS_ConfirmToStop = 0
					ModifyControl IRIS_Stop_tabRun, win = IRISpanel, title = "STOPPING"
					deletePoints 0, 1, instructionQueueForIRIS
					DoUpdate
				else
					if(IRIS_Running == 0)
						IRIS_EVENT_ReportStatus("Received external command to STOP")
						IRIS_EVENT_ReportStatus("  Command ignored: no run was in progress.")
						deletePoints 0, 1, instructionQueueForIRIS
						DoUpdate
					elseif((IRIS_ShouldStartToStop == 1) || (IRIS_Stopping == 1))
						IRIS_EVENT_ReportStatus("Received external command to STOP")
						IRIS_EVENT_ReportStatus("  Command ignored: run was already stopping.")
						deletePoints 0, 1, instructionQueueForIRIS
						DoUpdate
					endif
				endif
			
			elseif(cmpstr(lowerstr(thisInstruction), "getstatus") == 0)
				
				string statusString
				if((IRIS_Running == 1) || (IRIS_Reanalyzing == 1) || (IRIS_ChoosingFiles == 1))
					statusString = "busy"
				else
					statusString = "ready"
				endif
				IRIS_EVENT_ReportStatus("Received external request for status report")
				string statusStringReport = "  Status is: " + statusString
				IRIS_EVENT_ReportStatus(statusStringReport)
				IRIS_UTILITY_BroadcastStatus(statusString)
				deletePoints 0, 1, instructionQueueForIRIS
				DoUpdate
				
			else
				
				string reportString = "Received invalid command: " + thisInstruction
				IRIS_EVENT_ReportStatus(reportString)
				deletePoints 0, 1, instructionQueueForIRIS
				
			endif
		
		endif
		
	endif
	
	SetDataFolder $saveFolder
	return 0
End

Function IRIS_UTILITY_BroadcastStatus(statusString)
	string statusString
	
	string saveFolder = GetDataFolder(1);
	SetDataFolder root:
	
	NVAR IRIS_Running = root:IRIS_Running
	NVAR IRIS_Reanalyzing = root:IRIS_Reanalyzing
	NVAR IRIS_ChoosingFiles = root:IRIS_ChoosingFiles
	
	make/O/T/N=1 t_statusOutFromIRIS
	t_statusOutFromIRIS[0] = statusString
	
//	if((IRIS_Running == 1) || (IRIS_Reanalyzing == 1) || (IRIS_ChoosingFiles == 1))
//		t_statusOutFromIRIS[0] = "busy"
//	else
//		t_statusOutFromIRIS[0] = "ready"
//	endif
	
	duplicate/T/O t_statusOutFromIRIS, root:WILTI_Folder:statusOutFromIRIS
	
	killwaves t_statusOutFromIRIS
	
	SetDataFolder $saveFolder
	return 0
End

Function IRIS_UTILITY_LoadSTRandSTC()
	
	SVAR sDataPathOnDisk = root:sDataPathOnDisk
	wave/T wSTRrootNames = root:wSTRrootNames // each element is "yymmdd_hhmmss"
	
	SVAR DestinationDataFolder = root:STRPanel_Folder:DestinationDataFolder
	SVAR sSTRwaveList = root:sSTRwaveList
	SVAR sSTCwaveList = root:sSTCwaveList
	
	NVAR minBytesInFile // bytes, to avoid a Loadwave error when trying to load a file with no data in it (1000 bytes is enough that it won't just be a header)
	
	string sKilledWaves
		
	String fabFileName
	String parameterlist
		
	String saveFolder = GetDataFolder(1);
	
	variable numFilePairs = numpnts(wSTRrootNames)
	variable filePairIndex
	
	variable numSTRwavesInStash
	variable waveIndex
	string sThisWave
	
	String FormatStr
	String justLoadedList
	String mappedList
	
	variable numPointsToCropForSafety = 1 // points
	
	// Empty DestinationDataFolder...
	SetDataFolder $DestinationDataFolder
	sKilledWaves = KillWavesWhichMatchStr("*")
	
	// Delete STC waves from root...
	SetDataFolder root:
	sKilledWaves = KillWavesWhichMatchStr("stc_*")
	
	// Load all the STR/STC pairs associated with this run so far...
	// (NOTE that STR and STC waves have to be handled a bit differently, in part because we can identify stc waves by their prefix but we cannot do that with str waves.)
	for(filePairIndex=0;filePairIndex<numFilePairs;filePairIndex+=1)
		
		sprintf fabFileName, "%s:%s.str", sDataPathOnDisk, wSTRrootNames[filePairIndex]
		fabFileName = RemoveDoubleColon( fabFileName ) // just in case
		GetFileFolderInfo/Q/Z fabFileName
		if(V_logEOF > minBytesInFile)
		
			// Load the STR data into DestinationDataFolder (will concatenate onto any existing waves there)...
			nSTR_LoadSTRFile( fabFileName )		// note that this nSTR function will reach "into" the right datafolder specified
		
			// Copy all the STR (i.e. non-STC) waves from DestinationDataFolder to root, overwriting any existing waves there...
			SetDataFolder root:
			SetDataFolder $DestinationDataFolder
			sSTRwaveList = WaveList("!stc*", ";", "")
			numSTRwavesInStash = ItemsInList(sSTRwaveList, ";")
			for(waveIndex=0;waveIndex<numSTRwavesInStash;waveIndex+=1)
				sThisWave = StringFromList(waveIndex, sSTRwaveList, ";")
				Duplicate/O $sThisWave, root:$sThisWave
			endfor
		
			// Delete stcL_ waves from DestinationDataFolder...
			SetDataFolder root:
			SetDataFolder $DestinationDataFolder
			sKilledWaves = KillWavesWhichMatchStr("stcL_*")
		
			// Load the stc waves as "stcL_" versions in DestinationDataFolder and then copy them as "stc_" versions to root, concatenating onto any existing waves there...
			SetDataFolder root:
			SetDataFolder $DestinationDataFolder
			sprintf fabFileName, "%s:%s.stc", sDataPathOnDisk, wSTRrootNames[filePairIndex]
			fabFileName = RemoveDoubleColon( fabFileName ) // just in case
			parameterList = zSTC_GetHeaderLine( fabFileName)
			if( strsearch( parameterList, "FILE", 0 ) == -1 )
				FormatStr = zSTC_MakeFormatStrFromList( parameterList )		
				justLoadedList = TDLCore_TailLoad( "stc-fast", "default", -1, FormatStr, fabFileName )
				mappedList = TDLCore_MapLocalListToFinal( "stc", "root:", justLoadedList )
				sSTCwaveList = mappedList // NOTE: each wave name in sSTCwaveList is prefaced by "root:", because of how TDLCore_MapLocalListToFinal works
			endif
		
		endif
		
	endfor
	
	
	
	
	// PERHAPS UNNECESSARY: Cut off the last numPointsToCropForSafety elements of each wave in case there is an incomplete row because TDL Wintel is still writing to the files (not sure if that ever actually happens)...
	wave timeWave = root:str_source_rtime
	variable newSTRlength, numSTRwavesInRoot
	newSTRlength = numpnts(timeWave) - numPointsToCropForSafety
	numSTRwavesInRoot = ItemsInList(sSTRwaveList, ";")
	for(waveIndex=0;waveIndex<numSTRwavesInRoot;waveIndex+=1)
		sThisWave = StringFromList(waveIndex, sSTRwaveList, ";")
		Redimension/N=(newSTRlength) root:$sThisWave 
	endfor
	wave timeWave = root:stc_time
	variable newSTClength, numSTCwavesInRoot
	newSTClength = numpnts(timeWave) - numPointsToCropForSafety
	numSTCwavesInRoot = ItemsInList(sSTCwaveList, ";")
	for(waveIndex=0;waveIndex<numSTCwavesInRoot;waveIndex+=1)
		sThisWave = StringFromList(waveIndex, sSTCwaveList, ";")
		Redimension/N=(newSTClength) $sThisWave // no "root:" here because it's already in each element of sSTCwaveList (but not sSTRwaveList)
	endfor
			
	IRIS_UTILITY_MonotonicTimeCheck()
	
	SetDataFolder $saveFolder
	
End

Function IRIS_UTILITY_MonotonicTimeCheck()
	// This function checks whether the STR and STC time waves increase monotonically,
	// and if not, it deletes the offending rows from all STR and/or STC files.
	
	string saveFolder = GetDataFolder(1);
	SetDataFolder root:
	
	wave STRtime = root:str_source_rtime
	wave STCtime = root:stc_time
	SVAR sSTRwaveList = root:sSTRwaveList
	SVAR sSTCwaveList = root:sSTCwaveList
	
	variable STRlength = numpnts(STRtime)
	variable STClength = numpnts(STCtime)
	variable i, waveIndex, numWaves, maxTimeSoFar
	variable numSTRindicesToKeep, numSTCindicesToKeep
	string sThisWave
	
	make/O/D/N=(STRlength) STRindicesToKeep = p
	make/O/D/N=(STClength) STCindicesToKeep = p
	
	// check for monotonic increase of STR time
	maxTimeSoFar = STRtime[0]
	for(i=1;i<STRlength;i+=1)
		if(STRtime[i] > maxTimeSoFar)
			maxTimeSoFar = STRtime[i]
		else
			deletePoints (i), 1, STRindicesToKeep
		endif
	endfor
	numSTRindicesToKeep = numpnts(STRindicesToKeep)
	
	// cut bad rows from STR files
	if(numSTRindicesToKeep < STRlength)
		numWaves = ItemsInList(sSTRwaveList, ";")
		for(waveIndex=0;waveIndex<numWaves;waveIndex+=1)
			sThisWave = StringFromList(waveIndex, sSTRwaveList, ";")
			duplicate/O root:$sThisWave, wThisWave, wNewWave
			redimension/N=(numSTRindicesToKeep) wNewWave
			wNewWave = wThisWave[STRindicesToKeep[p]]
			duplicate/O wNewWave, root:$sThisWave
		endfor
	endif
		
	// check for monotonic increase of STC time
	maxTimeSoFar = STCtime[0]
	for(i=1;i<STClength;i+=1)
		if(STCtime[i] > maxTimeSoFar)
			maxTimeSoFar = STCtime[i]
		else
			deletePoints (i), 1, STCindicesToKeep
		endif
	endfor
	numSTCindicesToKeep = numpnts(STCindicesToKeep)
	
	// cut bad rows from STC files
	if(numSTCindicesToKeep < STClength)
		numWaves = ItemsInList(sSTCwaveList, ";")
		for(waveIndex=0;waveIndex<numWaves;waveIndex+=1)
			sThisWave = StringFromList(waveIndex, sSTCwaveList, ";")
			duplicate/O $sThisWave, wThisWave, wNewWave // NOTE: each wave name in sSTCwaveList is prefaced by "root:", because of how TDLCore_MapLocalListToFinal works
			redimension/N=(numSTCindicesToKeep) wNewWave
			wNewWave = wThisWave[STCindicesToKeep[p]]
			duplicate/O wNewWave, $sThisWave // NOTE: each wave name in sSTCwaveList is prefaced by "root:", because of how TDLCore_MapLocalListToFinal works
		endfor
	endif
	
	killwaves wThisWave, wNewWave
	
	SetDataFolder $saveFolder
	
End

Function IRIS_UTILITY_SaveResults()
	
	string saveFolder = GetDataFolder(1);
	SetDataFolder root:
	
	NVAR isTabRunOrReanalyze = root:isTabRunOrReanalyze
	NVAR isTabGas = root:isTabGas
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	NVAR numGases = root:numGases
	
//	NVAR numCalibratedOutputVariables = root:numCalibratedOutputVariables
	NVAR numVariablesToAverage = root:numVariablesToAverage
	wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
	NVAR numOutputVariables = root:numOutputVariables
	
	NVAR showSecondPlotOnGraph = root:showSecondPlotOnGraph
	
	if(isTabRunOrReanalyze == 1)
		PopupMenu IRIS_GasChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
		PopupMenu IRIS_GasChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
		PopupMenu IRIS_GasChoice3_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
		PopupMenu IRIS_PlotGasChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
		PopupMenu IRIS_VariableChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
		PopupMenu IRIS_VariableChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
		PopupMenu IRIS_VariableChoice3_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
		PopupMenu IRIS_PlotVariableChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
		CheckBox IRIS_ShowSecondPlotOnGraph_tabRunOrReanalyze, win=IRISpanel, disable = 2
		CheckBox IRIS_PlotSeparateAxisChoice_tabRunOrReanalyze, win=IRISpanel, disable = 2
		PopupMenu IRIS_PlotGasChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
		PopupMenu IRIS_PlotVariableChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 2 // disabling popup menus to try to avoid Igor crashes
	endif
	DoUpdate
	
	SVAR sInstrumentID = root:sInstrumentID
	SVAR sRunID = root:sRunID
	SVAR sAcquisitionStartTime = root:sAcquisitionStartTime
	SVAR sAcquisitionEndTime = root:sAcquisitionEndTime
	SVAR sResultsPath = root:sResultsPath
	
	wave/T wSTRrootNames = root:wSTRrootNames
	
	wave/T wtParamNames = root:wtParamNames
	wave/T wtParamValues = root:wtParamValues
	wave/T wtParamUnits = root:wtParamUnits
	
	wave wOutputMeans = root:wOutputMeans
	wave wOutputStDevs = root:wOutputStDevs
	wave wOutputStErrs = root:wOutputStErrs
	
	wave/T wtOutputVariableNames = root:wtOutputVariableNames
	wave/T wtOutputVariableUnits = root:wtOutputVariableUnits
	wave/T wtOutputVariableFormats = root:wtOutputVariableFormats
	
	wave wOutputTimeSeriesMatrix = root:wOutputTimeSeriesMatrix
	wave wOutputTimeSeriesErrorMatrix = root:wOutputTimeSeriesErrorMatrix
	wave wOutputTimeSeriesFilterMatrix = root:wOutputTimeSeriesFilterMatrix
	wave wOutputTime = root:wOutputTime
	
	variable i, j, k
	variable ii, jj
	
	variable f1 // a variable to recieve the file reference number
	variable headerItemCount
	string header
	
	string/G sTextResults = ""
	string sTextResultsTemp
	string sDataFilterThreshold = IRIS_UTILITY_GetParamValueFromName("Data Filter Threshold")
		
	NVAR numSampleGases = root:numSampleGases
	wave wNumCompleteMeasurementsByGas = root:wNumCompleteMeasurementsByGas
	variable maxNumCompleteSampleMeasurementsSoFar = wavemax(wNumCompleteMeasurementsByGas, 0, (numSampleGases - 1))
	if(maxNumCompleteSampleMeasurementsSoFar < 1)
		if(isTabRunOrReanalyze == 1)
			PopupMenu IRIS_GasChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
			PopupMenu IRIS_GasChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
			PopupMenu IRIS_GasChoice3_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
			PopupMenu IRIS_PlotGasChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
			PopupMenu IRIS_VariableChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
			PopupMenu IRIS_VariableChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
			PopupMenu IRIS_VariableChoice3_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
			PopupMenu IRIS_PlotVariableChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
			CheckBox IRIS_ShowSecondPlotOnGraph_tabRunOrReanalyze, win=IRISpanel, disable = 0
			if(showSecondPlotOnGraph == 1)
				CheckBox IRIS_PlotSeparateAxisChoice_tabRunOrReanalyze, win=IRISpanel, disable = 0
				PopupMenu IRIS_PlotGasChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
				PopupMenu IRIS_PlotVariableChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
			endif
		endif
		return 0
	endif
	
	variable numFilePairs = numpnts(wSTRrootNames)
	variable filePairIndex
	
	string sDataFileString = ""
	if(numFilePairs == 1) // use the STR file name root
		sDataFileString += " " + wSTRrootNames[0]
	else // use the STR file name roots for the first and the last file pairs
		sDataFileString += " " + wSTRrootNames[0]
		sDataFileString += " " + wSTRrootNames[numFilePairs-1]
	endif
	
	// Create subfolder in which to save this run's results
	string/G sResultsSubfolderName = "IRIS Results - Run " + sRunID + " - Data" + sDataFileString
	string/G sResultsSubfolderPathAndName = sResultsPath + ":" + sResultsSubfolderName
	NewPath/C/Q/O pResultsSubfolderPath, sResultsSubfolderPathAndName // the "/C" flag creates the folder on disk if it does not already exist
	
	// Set filenames for saving results
	string sResultsFileNameRoot = "IRIS Numeric Results - Run " + sRunID + " - Data" + sDataFileString
	string/G sGraphsFileNameRoot = "IRIS Graphical Results - Run " + sRunID + " - Data" + sDataFileString
	string/G sGraphsFileNameBaseNoExt = sGraphsFileNameRoot // needed for appending "- Variable0" etc in IRIS_UTILITY_MakeAndSaveGraphs
	string/G sBundleFileNameRoot = "IRIS Bundled Results - Run " + sRunID + " - Data" + sDataFileString
	string sStatusFileNameRoot = "IRIS Status Log - Run " + sRunID + " - Data" + sDataFileString
	string/G sResultsFileTXT = sResultsFileNameRoot + ".txt" // name of the file to create
	string/G sGraphsFilePNG = sGraphsFileNameRoot + ".png" // name of the file to create
	string/G sBundleFilePDF = sBundleFileNameRoot + ".pdf" // name of the file to create
	string/G sStatusFileTXT = sStatusFileNameRoot + ".txt" // name of the file to create
	string sExistingFilesTXT = IndexedFile(pResultsSubfolderPath, -1, ".txt")
	string sExistingFilesPNG = IndexedFile(pResultsSubfolderPath, -1, ".png")
	string sExistingFilesPDF = IndexedFile(pResultsSubfolderPath, -1, ".pdf")
	string sMatchStrTXT = "*" + sResultsFileTXT + "*"
	string sMatchStrPNG = "*" + sGraphsFilePNG + "*"
	string sMatchStrPDF = "*" + sBundleFilePDF + "*"
	string sMatchStrStatusTXT = "*" + sStatusFileTXT + "*"
	variable checkTXT = stringmatch(sExistingFilesTXT, sMatchStrTXT)
	variable checkPNG = stringmatch(sExistingFilesPNG, sMatchStrPNG)
	variable checkPDF = stringmatch(sExistingFilesPDF, sMatchStrPDF)
	variable checkStatusTXT = stringmatch(sExistingFilesTXT, sMatchStrStatusTXT)
	variable adjustmentIndex = 0
	if((checkTXT == 1) || (checkPNG == 1) || (checkPDF == 1) || (checkStatusTXT == 1))
		do
			adjustmentIndex += 1
			sResultsFileTXT = sResultsFileNameRoot + " - rev" + num2istr(adjustmentIndex) + ".txt"
			sGraphsFilePNG = sGraphsFileNameRoot + " - rev" + num2istr(adjustmentIndex) + ".png"
			sGraphsFileNameBaseNoExt = sGraphsFileNameRoot + " - rev" + num2istr(adjustmentIndex) // needed for appending "- Variable0" etc in IRIS_UTILITY_MakeAndSaveGraphs
			sBundleFilePDF = sBundleFileNameRoot + " - rev" + num2istr(adjustmentIndex) + ".pdf"
			sStatusFileTXT = sStatusFileNameRoot + " - rev" + num2istr(adjustmentIndex) + ".txt"
			sExistingFilesTXT = IndexedFile(pResultsSubfolderPath, -1, ".txt")
			sExistingFilesPNG = IndexedFile(pResultsSubfolderPath, -1, ".png")
			sExistingFilesPDF = IndexedFile(pResultsSubfolderPath, -1, ".pdf")
			sMatchStrTXT = "*" + sResultsFileTXT + "*"
			sMatchStrPNG = "*" + sGraphsFilePNG + "*"
			sMatchStrPDF = "*" + sBundleFilePDF + "*"
			sMatchStrStatusTXT = "*" + sStatusFileTXT + "*"
			checkTXT = stringmatch(sExistingFilesTXT, sMatchStrTXT)
			checkPNG = stringmatch(sExistingFilesPNG, sMatchStrPNG)
			checkPDF = stringmatch(sExistingFilesPDF, sMatchStrPDF)
			checkStatusTXT = stringmatch(sExistingFilesTXT, sMatchStrStatusTXT)
		while((checkTXT == 1) || (checkPNG == 1) || (checkPDF == 1) || (checkStatusTXT == 1))
	endif
	
	// Record basic information about this run
	header = "Run ID: " + sRunID + "\r\n"
	header += "\r\n"
	header += "Instrument: " + sInstrumentID + "\r\n"
	header += "Root names for .str and .stc data files:" + sDataFileString + "\r\n"
	header += "Data aquisition started at: " + sAcquisitionStartTime + " [day/month/year (day of week)]\r\n"
	header += "Data aquisition ended at: " + sAcquisitionEndTime + " [day/month/year (day of week)]\r\n"
	Open/A/P=pResultsSubfolderPath f1 as sResultsFileTXT // if file already exists, we will append the new info to it (in case future code allows for reanalysis of data)
	fprintf f1, "%s\r\n", header
	sprintf sTextResultsTemp, "%s\r\n", header
	sTextResults += sTextResultsTemp
	Close f1
	
	// Record main summary results
	header = "OVERALL RESULTS\r\n"
	header += "===============\r\n"
	header += "\r\n"
	header += "(Reported as the mean ± 1 standard error in the mean)\r\n"
	header += "(Filtered for outliers as indicated in the results for individual cell fills reported below)\r\n"
	Open/A/P=pResultsSubfolderPath f1 as sResultsFileTXT
	fprintf f1, "%s\r\n", header
	sprintf sTextResultsTemp, "%s\r\n", header
	sTextResults += sTextResultsTemp
	Close f1
	for(k=0;k<numGases;k+=1)
		if(k<numSampleGases)
			header = "SAMPLE " + num2str(k+1) + "\r\n"
		else
			header = "REFERENCE " + num2str(k+1-numSampleGases) + "\r\n"
		endif
		header += "\r\n"
		header += "Name, Mean, SE, Units"
		header += "\r\n----------------------------------------"
		Open/A/P=pResultsSubfolderPath f1 as sResultsFileTXT
		fprintf f1, "%s\r\n", header
		sprintf sTextResultsTemp, "%s\r\n", header
		sTextResults += sTextResultsTemp
		if(k<numSampleGases)
			for(i=0;i<numOutputVariables;i+=1)
				fprintf f1, "%s," + wtOutputVariableFormats[i] + "," + wtOutputVariableFormats[i] + ",%s\r\n", wtOutputVariableNames[i], wOutputMeans[k][i], wOutputStErrs[k][i], wtOutputVariableUnits[i]
				sprintf sTextResultsTemp, "%s = " + wtOutputVariableFormats[i] + " ± " + wtOutputVariableFormats[i] + " %s\r\n", wtOutputVariableNames[i], wOutputMeans[k][i], wOutputStErrs[k][i], wtOutputVariableUnits[i]
				sTextResults += sTextResultsTemp
			endfor
		else
//			for(i=numCalibratedOutputVariables;i<numOutputVariables;i+=1)
//				fprintf f1, "%s," + wtOutputVariableFormats[i] + "," + wtOutputVariableFormats[i] + ",%s\r\n", wtOutputVariableNames[i], wOutputMeans[k][i], wOutputStErrs[k][i], wtOutputVariableUnits[i]
//				sprintf sTextResultsTemp, "%s = " + wtOutputVariableFormats[i] + " ± " + wtOutputVariableFormats[i] + " %s\r\n", wtOutputVariableNames[i], wOutputMeans[k][i], wOutputStErrs[k][i], wtOutputVariableUnits[i]
//				sTextResults += sTextResultsTemp
//			endfor
			for(ii=0;ii<numVariablesToAverage;ii+=1)
				i = wIndicesOfVariablesToAverage[ii]
				fprintf f1, "%s," + wtOutputVariableFormats[i] + "," + wtOutputVariableFormats[i] + ",%s\r\n", wtOutputVariableNames[i], wOutputMeans[k][i], wOutputStErrs[k][i], wtOutputVariableUnits[i]
				sprintf sTextResultsTemp, "%s = " + wtOutputVariableFormats[i] + " ± " + wtOutputVariableFormats[i] + " %s\r\n", wtOutputVariableNames[i], wOutputMeans[k][i], wOutputStErrs[k][i], wtOutputVariableUnits[i]
				sTextResults += sTextResultsTemp
			endfor
		endif
		fprintf f1, "\r\n"
		sprintf sTextResultsTemp, "\r\n"
		sTextResults += sTextResultsTemp
		Close f1
	endfor
	
	// Record results from individual cycles
	string sThisCycle
	string sThisTime
	header = "RESULTS FOR INDIVIDUAL CELL FILLS\r\n"
	header += "=================================\r\n"
	header += "\r\n"
	header += "(Numbers in parentheses were filtered out of the overall results reported above)\r\n"
	Open/A/P=pResultsSubfolderPath f1 as sResultsFileTXT
	fprintf f1, "%s\r\n", header
	sprintf sTextResultsTemp, "%s\r\n", header
	sTextResults += sTextResultsTemp
	Close f1
	for(k=0;k<numGases;k+=1)
		if(k<numSampleGases)
			header = "SAMPLE " + num2str(k+1) + "\r\n"
		else
			header = "REFERENCE " + num2str(k+1-numSampleGases) + "\r\n"
		endif
		header += "\r\n"
		header += "Means for Each Fill:\r\n"
		header += "\r\n"
		header += "Fill Number,Time,"
		if(k<numSampleGases)
			headerItemCount = 0
			for(i=0;i<numOutputVariables;i+=1)
				if(i == (numOutputVariables - 1))
					header += wtOutputVariableNames[i]
				else
					if(mod(headerItemCount,5) == 0)
						header += "\r\n"
						header += "  "
					endif
					header += wtOutputVariableNames[i] + ","
				endif
				headerItemCount += 1
			endfor
		else
			headerItemCount = 0
//			for(i=numCalibratedOutputVariables;i<numOutputVariables;i+=1)
//				if(i == (numOutputVariables - 1))
//					header += wtOutputVariableNames[i]
//				else
//					if(mod(headerItemCount,5) == 0)
//						header += "\r\n"
//						header += "  "
//					endif
//					header += wtOutputVariableNames[i] + ","
//				endif
//				headerItemCount += 1
//			endfor
			for(ii=0;ii<numVariablesToAverage;ii+=1)
				i = wIndicesOfVariablesToAverage[ii]
				if(i == (numOutputVariables - 1))
					header += wtOutputVariableNames[i]
				else
					if(mod(headerItemCount,5) == 0)
						header += "\r\n"
						header += "  "
					endif
					header += wtOutputVariableNames[i] + ","
				endif
				headerItemCount += 1
			endfor
		endif
		header += "\r\n----------------------------------------"
		Open/A/P=pResultsSubfolderPath f1 as sResultsFileTXT
		fprintf f1, "%s\r\n", header
		sprintf sTextResultsTemp, "%s\r\n", header
		sTextResults += sTextResultsTemp
		for(i=0;i<wNumCompleteMeasurementsByGas[k];i+=1)
			sThisCycle = num2str(i+1)
			sThisTime = secs2time(wOutputTime[k][i],2)
			fprintf f1, "%s,%s", sThisCycle, sThisTime
			sprintf sTextResultsTemp, "%s,%s", sThisCycle, sThisTime
			sTextResults += sTextResultsTemp
			if(k<numSampleGases)
				for(j=0;j<numOutputVariables;j+=1)
					if(wOutputTimeSeriesFilterMatrix[k][j][i] == 1)
						fprintf f1, ",(" + wtOutputVariableFormats[j] + ")", wOutputTimeSeriesMatrix[k][j][i]
						sprintf sTextResultsTemp, ",(" + wtOutputVariableFormats[j] + ")", wOutputTimeSeriesMatrix[k][j][i]
					else
						fprintf f1, "," + wtOutputVariableFormats[j], wOutputTimeSeriesMatrix[k][j][i]
						sprintf sTextResultsTemp, "," + wtOutputVariableFormats[j], wOutputTimeSeriesMatrix[k][j][i]
					endif
					sTextResults += sTextResultsTemp
				endfor
			else
//				for(j=numCalibratedOutputVariables;j<numOutputVariables;j+=1)
//					if(wOutputTimeSeriesFilterMatrix[k][j][i] == 1)
//						fprintf f1, ",(" + wtOutputVariableFormats[j] + ")", wOutputTimeSeriesMatrix[k][j][i]
//						sprintf sTextResultsTemp, ",(" + wtOutputVariableFormats[j] + ")", wOutputTimeSeriesMatrix[k][j][i]
//					else
//						fprintf f1, "," + wtOutputVariableFormats[j], wOutputTimeSeriesMatrix[k][j][i]
//						sprintf sTextResultsTemp, "," + wtOutputVariableFormats[j], wOutputTimeSeriesMatrix[k][j][i]
//					endif
//					sTextResults += sTextResultsTemp
//				endfor
				for(jj=0;jj<numVariablesToAverage;jj+=1)
					j = wIndicesOfVariablesToAverage[jj]
					if(wOutputTimeSeriesFilterMatrix[k][j][i] == 1)
						fprintf f1, ",(" + wtOutputVariableFormats[j] + ")", wOutputTimeSeriesMatrix[k][j][i]
						sprintf sTextResultsTemp, ",(" + wtOutputVariableFormats[j] + ")", wOutputTimeSeriesMatrix[k][j][i]
					else
						fprintf f1, "," + wtOutputVariableFormats[j], wOutputTimeSeriesMatrix[k][j][i]
						sprintf sTextResultsTemp, "," + wtOutputVariableFormats[j], wOutputTimeSeriesMatrix[k][j][i]
					endif
					sTextResults += sTextResultsTemp
				endfor
			endif
			fprintf f1, "\r\n"
			sprintf sTextResultsTemp, "\r\n"
			sTextResults += sTextResultsTemp
		endfor
		fprintf f1, "\r\n"
		sprintf sTextResultsTemp, "\r\n"
		sTextResults += sTextResultsTemp
		//	Close f1
		header = "Standard Errors in the Means for Each Fill:\r\n"
		header += "\r\n"
		header += "Fill Number,Time,"
		if(k<numSampleGases)
			headerItemCount = 0
			for(i=0;i<numOutputVariables;i+=1)
				if(i == (numOutputVariables - 1))
					header += wtOutputVariableNames[i]
				else
					if(mod(headerItemCount,5) == 0)
						header += "\r\n"
						header += "  "
					endif
					header += wtOutputVariableNames[i] + ","
				endif
				headerItemCount += 1
			endfor
		else
			headerItemCount = 0
//			for(i=numCalibratedOutputVariables;i<numOutputVariables;i+=1)
//				if(i == (numOutputVariables - 1))
//					header += wtOutputVariableNames[i]
//				else
//					if(mod(headerItemCount,5) == 0)
//						header += "\r\n"
//						header += "  "
//					endif
//					header += wtOutputVariableNames[i] + ","
//				endif
//				headerItemCount += 1
//			endfor
			for(ii=0;ii<numVariablesToAverage;ii+=1)
				i = wIndicesOfVariablesToAverage[ii]
				if(i == (numOutputVariables - 1))
					header += wtOutputVariableNames[i]
				else
					if(mod(headerItemCount,5) == 0)
						header += "\r\n"
						header += "  "
					endif
					header += wtOutputVariableNames[i] + ","
				endif
				headerItemCount += 1
			endfor
		endif
		header += "\r\n----------------------------------------"
		//	Open/A/P=pResultsSubfolderPath f1 as sResultsFileTXT
		fprintf f1, "%s\r\n", header
		sprintf sTextResultsTemp, "%s\r\n", header
		sTextResults += sTextResultsTemp
		for(i=0;i<wNumCompleteMeasurementsByGas[k];i+=1)
			sThisCycle = num2str(i+1)
			sThisTime = secs2time(wOutputTime[k][i],2)
			fprintf f1, "%s,%s", sThisCycle, sThisTime
			sprintf sTextResultsTemp, "%s,%s", sThisCycle, sThisTime
			sTextResults += sTextResultsTemp
			if(k<numSampleGases)
				for(j=0;j<numOutputVariables;j+=1)
					if(wOutputTimeSeriesFilterMatrix[k][j][i] == 1)
						fprintf f1, ",(" + wtOutputVariableFormats[j] + ")", wOutputTimeSeriesErrorMatrix[k][j][i]
						sprintf sTextResultsTemp, ",(" + wtOutputVariableFormats[j] + ")", wOutputTimeSeriesErrorMatrix[k][j][i]
					else
						fprintf f1, "," + wtOutputVariableFormats[j], wOutputTimeSeriesErrorMatrix[k][j][i]
						sprintf sTextResultsTemp, "," + wtOutputVariableFormats[j], wOutputTimeSeriesErrorMatrix[k][j][i]
					endif
					sTextResults += sTextResultsTemp
				endfor
			else
//				for(j=numCalibratedOutputVariables;j<numOutputVariables;j+=1)
//					if(wOutputTimeSeriesFilterMatrix[k][j][i] == 1)
//						fprintf f1, ",(" + wtOutputVariableFormats[j] + ")", wOutputTimeSeriesErrorMatrix[k][j][i]
//						sprintf sTextResultsTemp, ",(" + wtOutputVariableFormats[j] + ")", wOutputTimeSeriesErrorMatrix[k][j][i]
//					else
//						fprintf f1, "," + wtOutputVariableFormats[j], wOutputTimeSeriesErrorMatrix[k][j][i]
//						sprintf sTextResultsTemp, "," + wtOutputVariableFormats[j], wOutputTimeSeriesErrorMatrix[k][j][i]
//					endif
//					sTextResults += sTextResultsTemp
//				endfor
				for(jj=0;jj<numVariablesToAverage;jj+=1)
					j = wIndicesOfVariablesToAverage[jj]
					if(wOutputTimeSeriesFilterMatrix[k][j][i] == 1)
						fprintf f1, ",(" + wtOutputVariableFormats[j] + ")", wOutputTimeSeriesErrorMatrix[k][j][i]
						sprintf sTextResultsTemp, ",(" + wtOutputVariableFormats[j] + ")", wOutputTimeSeriesErrorMatrix[k][j][i]
					else
						fprintf f1, "," + wtOutputVariableFormats[j], wOutputTimeSeriesErrorMatrix[k][j][i]
						sprintf sTextResultsTemp, "," + wtOutputVariableFormats[j], wOutputTimeSeriesErrorMatrix[k][j][i]
					endif
					sTextResults += sTextResultsTemp
				endfor
			endif
			fprintf f1, "\r\n"
			sprintf sTextResultsTemp, "\r\n"
			sTextResults += sTextResultsTemp
		endfor
		fprintf f1, "\r\n"
		sprintf sTextResultsTemp, "\r\n"
		sTextResults += sTextResultsTemp
		Close f1
	endfor
	
	// Record IRIS configuration parameters
	header = "IRIS CONFIGURATION PARAMETERS\r\n"
	header += "================================\r\n"
	header += "\r\n"
	header += "Name, Value, Units"
	header += "\r\n----------------------------------------"
	Open/A/P=pResultsSubfolderPath f1 as sResultsFileTXT // if file already exists, we will append the new info to it (in case future code allows for reanalysis of data)
	fprintf f1, "%s\r\n", header
	sprintf sTextResultsTemp, "%s\r\n", header
	sTextResults += sTextResultsTemp
	Close f1
	string sWaveListStr = "wtParamNames;wtParamValues;wtParamUnits;"
	Save/J/B/A=2/DLIM=","/P=pResultsSubfolderPath sWaveListStr as sResultsFileTXT
	
	for(i=0;i<numpnts(wtParamNames);i+=1)
		sprintf sTextResultsTemp, "%s,%s,%s\r\n", wtParamNames[i], wtParamValues[i], wtParamUnits[i]
		sTextResults += sTextResultsTemp
	endfor
	
	// Save results graphs as PNG files
	IRIS_UTILITY_MakeAndSaveGraphs()
	
	// Save all results together in a single PDF file
	IRIS_UTILITY_MakeAndSaveResultsLayout()
		
	// Report save status
	IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", secs2time(DateTime,3) + "  " + "Results saved in:")
	IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", "          " + sResultsSubfolderName)
	
	// Save status notebook as a text file
	SaveNotebook/O/S=6/P=pResultsSubfolderPath IRISpanel#StatusNotebook as sStatusFileTXT
		
	if(isTabRunOrReanalyze == 1)
		PopupMenu IRIS_GasChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
		PopupMenu IRIS_GasChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
		PopupMenu IRIS_GasChoice3_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
		PopupMenu IRIS_PlotGasChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
		PopupMenu IRIS_VariableChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
		PopupMenu IRIS_VariableChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
		PopupMenu IRIS_VariableChoice3_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
		PopupMenu IRIS_PlotVariableChoice1_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
		CheckBox IRIS_ShowSecondPlotOnGraph_tabRunOrReanalyze, win=IRISpanel, disable = 0
		if(showSecondPlotOnGraph == 1)
			CheckBox IRIS_PlotSeparateAxisChoice_tabRunOrReanalyze, win=IRISpanel, disable = 0
			PopupMenu IRIS_PlotGasChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
			PopupMenu IRIS_PlotVariableChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 0 // re-enabling popup menus
		endif
	endif
	DoUpdate
	
	SetDataFolder $saveFolder
	
	return 0
	
End

Function IRIS_UTILITY_MakeAndSaveResultsLayout()
	
	string saveFolder = GetDataFolder(1);
	SetDataFolder root:
	
	NVAR panelLeftEdgePosition = root:panelLeftEdgePosition
	NVAR panelTopEdgePosition = root:panelTopEdgePosition
	NVAR panelWidth = root:panelWidth
	NVAR panelHeight = root:panelHeight
	
	variable layoutTextFontSize = 10 // point
	variable maxLinesPerPage = 60
	variable maxBytesPerLine = 120
	
	variable layoutLeftEdge = panelLeftEdgePosition + 20
	variable layoutTopEdge = panelTopEdgePosition + 20
	
	NVAR layoutPageWidth = root:layoutPageWidth
	NVAR layoutPageHeight = root:layoutPageHeight
	variable layoutPageMargin = 0
	
	// The values of layoutWidth and layoutHeight don't matter if the layout will not be displayed in Igor (i.e. if it is hidden)...
	variable layoutWidth = panelWidth // 200 //layoutPageWidth + 175 // the +175 gives room for the page thumbnails and tools
	variable layoutHeight = panelHeight // 200 //min(layoutPageHeight + 100, 800) // the +100 gives room for the info bar etc.
	
	variable layoutResultGraphWidth = layoutPageWidth/2 - layoutPageMargin
	variable layoutResultGraphHeight = layoutPageHeight/4
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	NVAR numGases = root:numGases
	
	wave wOutputTime = root:wOutputTime
	wave wOutputTimeSeriesMatrix = root:wOutputTimeSeriesMatrix
	wave wOutputTimeSeriesErrorMatrix = root:wOutputTimeSeriesErrorMatrix
	wave wOutputTimeSeriesFilterMatrix = root:wOutputTimeSeriesFilterMatrix
	
	NVAR numOutputVariables = root:numOutputVariables
	NVAR numVariablesToAverage = root:numVariablesToAverage
	wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
//	NVAR numCalibratedOutputVariables = root:numCalibratedOutputVariables
	wave/T wtOutputVariableNames = root:wtOutputVariableNames
	wave/T wtOutputVariableUnits = root:wtOutputVariableUnits
	
	SVAR sTextResults = root:sTextResults
	SVAR sBundleFilePDF = root:sBundleFilePDF
	SVAR sGraphsFileNameBaseNoExt = root:sGraphsFileNameBaseNoExt
	
	variable gasNum
	variable outputIndex
	variable ii
	
	string sThisGraphName
	string sFileNameStr
	string sYaxisLabel
	
	variable layoutVerticalPosition = 0
	variable layoutHorizontalPosition = 0
	
	GetWindow/Z IRISpanel wsize
	if(V_flag == 0)
		layoutLeftEdge = V_left + panelWidth + 10
		layoutTopEdge = V_top // + 10
	endif
	
	KillWindow/Z IRISresultsLayout
	NewLayout/N=IRISresultsLayout/HIDE=1/W=(layoutLeftEdge,layoutTopEdge,layoutLeftEdge+layoutWidth,layoutTopEdge+layoutHeight) as "IRIS Results Layout"
	LayoutPageAction/W=IRISresultsLayout size=(layoutPageWidth, layoutPageHeight),margins=(layoutPageMargin, layoutPageMargin, layoutPageMargin, layoutPageMargin)
	ModifyLayout/W=IRISresultsLayout mag=1, bgRGB=(65535,65535,65535)
	
	// Add text results to the layout, breaking them over pages as necessary...
	
	variable textStringLength = strlen(sTextResults)
	variable searchStart, nextCarriageReturn
	variable thisLineStartByte, thisLineEndByte, lastBreakableByte
	variable numberOfLines = 1
	variable numberOfTextPages = 1
	variable linesThisPage = 1
	string sTextResults_temp1, sTextResults_temp2, thisStringClip
	make/O/D/N=1 wTextBoxTemp, wTextBoxPageStarts = 0
	
	// ...first wrap lines if necessary to avoid them going out of the text box...
	thisLineStartByte = 0
	string sTextResultsNew = ""
	do
		thisLineEndByte = thisLineStartByte + maxBytesPerLine + 1 // "\r\n" counts as 2 bytes but then you have to subtract 1 to get the last byte of this line rather than the first byte of the next line
		thisStringClip = sTextResults[thisLineStartByte, thisLineEndByte]
		nextCarriageReturn = StrSearch(thisStringClip, "\r\n", 0)
		if(nextCarriageReturn >= 0) // carriage return found
			thisLineEndByte = thisLineStartByte + nextCarriageReturn + 1 // "\r\n" counts as 2 bytes so you have to add 1 to include the "\n"
			sTextResultsNew += sTextResults[thisLineStartByte, thisLineEndByte]
			thisLineStartByte = thisLineEndByte + 1
		else // no carriage return found
			if(thisLineEndByte >= textStringLength) // reached end of text
				sTextResultsNew += thisStringClip
				thisLineStartByte = thisLineEndByte + 1
			else // line is too long
				lastBreakableByte = StrSearch(thisStringClip, ",", inf, 1) // break line after a comma
				if(lastBreakableByte > 0) // comma found
					thisLineEndByte = thisLineStartByte + lastBreakableByte
					sTextResultsNew += sTextResults[thisLineStartByte, thisLineEndByte] + "...\r\n     "
					thisLineStartByte = thisLineEndByte + 1
				else // no comma found
					lastBreakableByte = StrSearch(thisStringClip, " ", inf, 1) // break line after a space
					if(lastBreakableByte > 0) // space found
						thisLineEndByte = thisLineStartByte + lastBreakableByte
						sTextResultsNew += sTextResults[thisLineStartByte, thisLineEndByte] + "...\r\n     "
						thisLineStartByte = thisLineEndByte + 1
					else // no space found either => just let this line be too long
						sTextResultsNew += thisStringClip
						thisLineStartByte = thisLineEndByte + 1
					endif
				endif
			endif
		endif
	while(thisLineStartByte < textStringLength)
	sTextResults = sTextResultsNew
	
	//	// ...first wrap lines if necessary to avoid them going out of the text box...
	//	searchStart = 1
	//	startOfThisLine = 0
	//	do
	//		thisStringClip = sTextResults[startOfThisLine, textStringLength - 1]
	//		bytesOnThisLine = StrSearch(thisStringClip, "\r\n", searchStart)
	//		if(bytesOnThisLine > 0) // carriage return found
	//			startOfNextLine = startOfThisLine + bytesOnThisLine
	//			thisStringClip = thisStringClip[0, bytesOnThisLine - 1]
	//			if(bytesOnThisLine > maxBytesPerLine)
	//				newBreakPoint = StrSearch(thisStringClip, ",", maxBytesPerLine, 1) // break lines after commas only
	//				if(newBreakPoint > 0)
	//					newBreakPoint = newBreakPoint + 1 + startOfThisLine
	//					sTextResults_temp1 = sTextResults[0, newBreakPoint - 1]
	//					sTextResults_temp2 = sTextResults[newBreakPoint, textStringLength - 1]
	//					sTextResults = sTextResults_temp1 + "...\r\n" + sTextResults_temp2
	//					textStringLength = strlen(sTextResults)
	//					startOfThisLine = newBreakPoint + 3 + 2 // "\r\n" counts as 2 bytes
	//				else
	//					startOfThisLine = startOfNextLine + 2 // "\r\n" counts as 2 bytes
	//				endif
	//			else
	//				startOfThisLine = startOfNextLine + 2 // "\r\n" counts as 2 bytes
	//			endif
	//		else // no more carriage returns in file
	//			startOfNextLine = startOfThisLine + bytesOnThisLine
	//			thisStringClip = thisStringClip[0, bytesOnThisLine - 1]
	//			if(bytesOnThisLine > maxBytesPerLine)
	//				newBreakPoint = StrSearch(thisStringClip, ",", maxBytesPerLine, 1) // break lines after commas only
	//				if(newBreakPoint > 0)
	//					newBreakPoint = newBreakPoint + 1 + startOfThisLine
	//					sTextResults_temp1 = sTextResults[0, newBreakPoint - 1]
	//					sTextResults_temp2 = sTextResults[newBreakPoint, textStringLength - 1]
	//					sTextResults = sTextResults_temp1 + "...\r\n" + sTextResults_temp2
	//					textStringLength = strlen(sTextResults)
	//					startOfThisLine = newBreakPoint + 3 + 2 // "\r\n" counts as 2 bytes
	//				else
	//					startOfThisLine = startOfNextLine + 2 // "\r\n" counts as 2 bytes
	//				endif
	//			else
	//				startOfThisLine = startOfNextLine + 2 // "\r\n" counts as 2 bytes
	//			endif
	//		endif
	//		searchStart = startOfThisLine
	//	while((nextCarriageReturn >= 0) && (searchStart < textStringLength))
	
	// ...then create a separate text box for each page...
	searchStart = 0
	do
		nextCarriageReturn = StrSearch(sTextResults, "\r\n", searchStart)
		if(nextCarriageReturn >= 0)
			numberOfLines += 1
			searchStart = nextCarriageReturn + 2 // "\r\n" counts as 2 bytes
			if(linesThisPage > maxLinesPerPage)
				numberOfTextPages += 1
				linesThisPage = 1
				wTextBoxTemp = searchStart
				Concatenate/NP {wTextBoxTemp}, wTextBoxPageStarts
			else
				linesThisPage += 1
			endif
		endif
	while((nextCarriageReturn >= 0) && (searchStart < textStringLength))
	Duplicate/O wTextBoxPageStarts, wTextBoxPageEnds
	wTextBoxPageEnds = wTextBoxPageStarts - 3
	DeletePoints 0, 1, wTextBoxPageEnds
	Redimension/N=(numberOfTextPages) wTextBoxPageEnds
	wTextBoxPageEnds[numberOfTextPages-1] = textStringLength - 1
	variable thisPage, thisPageStart, thisPageEnd
	string sThisPageText
	for(thisPage=0;thisPage<numberOfTextPages;thisPage+=1)
		thisPageStart = wTextBoxPageStarts[thisPage]
		thisPageEnd = wTextBoxPageEnds[thisPage]
		sThisPageText = sTextResults[thisPageStart,thisPageEnd]
		sThisPageText = "\Z" + num2str(layoutTextFontSize) + sThisPageText
		TextBox/W=IRISresultsLayout/F=0 sThisPageText
		LayoutPageAction/W=IRISresultsLayout appendPage
	endfor
	killwaves wTextBoxTemp, wTextBoxPageStarts, wTextBoxPageEnds
	
	// Add graphs to the layout (by first loading PNG graph images from disk)...
	
	variable objectCount = 0
	for(gasNum=0;gasNum<numGases;gasNum+=1)
		if(gasNum < numSampleGases)
			for(outputIndex=0;outputIndex<numOutputVariables;outputIndex+=1)
				sFileNameStr = sGraphsFileNameBaseNoExt + " - Sample" + num2str(gasNum+1) + " - Variable" + num2str(outputIndex) + ".png"
				sThisGraphName = "LayoutResultGraph_" + num2str(gasNum+1) + "_" + num2str(outputIndex)
				LoadPICT/O/P=pResultsSubfolderPath/Q sFileNameStr, $sThisGraphName
				AppendLayoutObject/W=IRISresultsLayout/R=(layoutHorizontalPosition, layoutVerticalPosition, layoutHorizontalPosition + layoutResultGraphWidth, layoutVerticalPosition + layoutResultGraphHeight)/F=0 picture $sThisGraphName
				if(mod(objectCount,2) == 0)
					layoutHorizontalPosition += layoutPageWidth/2
				else
					layoutVerticalPosition += layoutResultGraphHeight
					layoutHorizontalPosition = 0
				endif
				if(((layoutVerticalPosition + layoutResultGraphHeight) > layoutPageHeight) && (outputIndex < numOutputVariables - 1))
					LayoutPageAction/W=IRISresultsLayout appendPage
					layoutVerticalPosition = 0
					layoutHorizontalPosition = 0
				endif
				objectCount += 1
			endfor
		else
//			for(outputIndex=numCalibratedOutputVariables;outputIndex<numOutputVariables;outputIndex+=1)
//				sFileNameStr = sGraphsFileNameBaseNoExt + " - Reference" + num2str(gasNum+1-numSampleGases) + " - Variable" + num2str(outputIndex) + ".png"
//				sThisGraphName = "LayoutResultGraph_" + num2str(gasNum+1) + "_" + num2str(outputIndex)
//				LoadPICT/O/P=pResultsSubfolderPath/Q sFileNameStr, $sThisGraphName
//				AppendLayoutObject/W=IRISresultsLayout/R=(layoutHorizontalPosition, layoutVerticalPosition, layoutHorizontalPosition + layoutResultGraphWidth, layoutVerticalPosition + layoutResultGraphHeight)/F=0 picture $sThisGraphName
//				if(mod(objectCount,2) == 0)
//					layoutHorizontalPosition += layoutPageWidth/2
//				else
//					layoutVerticalPosition += layoutResultGraphHeight
//					layoutHorizontalPosition = 0
//				endif
//				if(((layoutVerticalPosition + layoutResultGraphHeight) > layoutPageHeight) && (outputIndex < numOutputVariables - 1))
//					LayoutPageAction/W=IRISresultsLayout appendPage
//					layoutVerticalPosition = 0
//					layoutHorizontalPosition = 0
//				endif
//				objectCount += 1
//			endfor
			for(ii=0;ii<numVariablesToAverage;ii+=1)
				outputIndex = wIndicesOfVariablesToAverage[ii]
				sFileNameStr = sGraphsFileNameBaseNoExt + " - Reference" + num2str(gasNum+1-numSampleGases) + " - Variable" + num2str(outputIndex) + ".png"
				sThisGraphName = "LayoutResultGraph_" + num2str(gasNum+1) + "_" + num2str(outputIndex)
				LoadPICT/O/P=pResultsSubfolderPath/Q sFileNameStr, $sThisGraphName
				AppendLayoutObject/W=IRISresultsLayout/R=(layoutHorizontalPosition, layoutVerticalPosition, layoutHorizontalPosition + layoutResultGraphWidth, layoutVerticalPosition + layoutResultGraphHeight)/F=0 picture $sThisGraphName
				if(mod(objectCount,2) == 0)
					layoutHorizontalPosition += layoutPageWidth/2
				else
					layoutVerticalPosition += layoutResultGraphHeight
					layoutHorizontalPosition = 0
				endif
				if(((layoutVerticalPosition + layoutResultGraphHeight) > layoutPageHeight) && (outputIndex < numOutputVariables - 1))
					LayoutPageAction/W=IRISresultsLayout appendPage
					layoutVerticalPosition = 0
					layoutHorizontalPosition = 0
				endif
				objectCount += 1
			endfor
		endif
	endfor
	
	LayoutPageAction/W=IRISresultsLayout appendPage
	
	sFileNameStr = sGraphsFileNameBaseNoExt + " - Diagnostics.png"
	sThisGraphName = "LayoutDiagnosticGraph"
	LoadPICT/O/P=pResultsSubfolderPath/Q sFileNameStr, $sThisGraphName
	AppendLayoutObject/W=IRISresultsLayout/R=(0,0,layoutPageWidth,layoutPageHeight)/F=0 picture $sThisGraphName
	
	LayoutPageAction page=(numberOfTextPages+1)
	SavePICT/WIN=IRISresultsLayout/P=pResultsSubfolderPath/W=(0,0,layoutPageWidth,layoutPageHeight)/E=-8/EF=2/PGR=(1,-1) as sBundleFilePDF
	
	KillWindow/Z IRISresultsLayout
	
	KillPICTs/A/Z
			
	SetDataFolder $saveFolder
	
	return 0
	
End

Function IRIS_UTILITY_MakeAndSaveGraphs()
	
	string saveFolder = GetDataFolder(1);
	SetDataFolder root:
	
	NVAR panelLeftEdgePosition = root:panelLeftEdgePosition
	NVAR panelTopEdgePosition = root:panelTopEdgePosition
	variable tempGraphLeftEdge = panelLeftEdgePosition + 10
	variable tempGraphTopEdge = panelTopEdgePosition + 10
	GetWindow/Z IRISpanel wsize
	if(V_flag == 0)
		tempGraphLeftEdge = V_left + 10
		tempGraphTopEdge = V_top + 10
	endif
	variable tempGraphWidth = 400
	variable tempGraphHeight = 250
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	NVAR numGases = root:numGases
	
	wave wNumCompleteMeasurementsByGas = root:wNumCompleteMeasurementsByGas
	
	wave wOutputTime = root:wOutputTime
	wave wOutputTimeSeriesMatrix = root:wOutputTimeSeriesMatrix
	wave wOutputTimeSeriesErrorMatrix = root:wOutputTimeSeriesErrorMatrix
	wave wOutputTimeSeriesFilterMatrix = root:wOutputTimeSeriesFilterMatrix
	
	NVAR numOutputVariables = root:numOutputVariables
//	NVAR numCalibratedOutputVariables = root:numCalibratedOutputVariables
	NVAR numVariablesToAverage = root:numVariablesToAverage
	wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
	wave/T wtOutputVariableNames = root:wtOutputVariableNames
	wave/T wtOutputVariableUnits = root:wtOutputVariableUnits
	
	SVAR sGraphsFileNameBaseNoExt = root:sGraphsFileNameBaseNoExt
	string sGraphsFilePNG
	string sGasLabel
	
	KillWindow/Z IRISresultsGraphTemp
	
	// Make and save results graphs one at a time...
	
	variable gasNum
	variable timeAxisMin
	variable timeAxisMax
	string sYaxisLabel
	variable outputIndex
	variable ii
	for(gasNum=0;gasNum<numGases;gasNum+=1)
		make/O/D/N=(wNumCompleteMeasurementsByGas[gasNum]) wTempDataWave, wTempErrorWave, wTempFilterWave, wTempTimeWave
		wTempTimeWave = wOutputTime[gasNum][p]
		SetScale d 0,0,"dat", wTempTimeWave
		timeAxisMin = wavemin(wTempTimeWave)
		timeAxisMax = wavemax(wTempTimeWave)
		if(gasNum < numSampleGases)
			for(outputIndex=0;outputIndex<numOutputVariables;outputIndex+=1)
				sGraphsFilePNG = sGraphsFileNameBaseNoExt + " - Sample" + num2str(gasNum+1) + " - Variable" + num2str(outputIndex) + ".png"
				wTempDataWave = wOutputTimeSeriesMatrix[gasNum][outputIndex][p]
				wTempErrorWave = wOutputTimeSeriesErrorMatrix[gasNum][outputIndex][p]
				wTempFilterWave = (wOutputTimeSeriesFilterMatrix[gasNum][outputIndex][p] == 0) ? 19 : 8
				Display/N=IRISresultsGraphTemp/W=(tempGraphLeftEdge, tempGraphTopEdge, tempGraphLeftEdge + tempGraphWidth, tempGraphTopEdge + tempGraphHeight)/HIDE=1 wTempDataWave vs wTempTimeWave
				sYaxisLabel = wtOutputVariableNames[outputIndex] + " (" + wtOutputVariableUnits[outputIndex] + ")"
				sGasLabel = "\Z12Sample Gas " + num2str(gasNum + 1)
				Label/W=IRISresultsGraphTemp Left sYaxisLabel
				Label/W=IRISresultsGraphTemp bottom " "
				ErrorBars/W=IRISresultsGraphTemp wTempDataWave Y, wave=(wTempErrorWave,wTempErrorWave)
				ModifyGraph/W=IRISresultsGraphTemp frameStyle = 0, fSize = 12
				ModifyGraph/W=IRISresultsGraphTemp lblMargin(left)=5
				ModifyGraph/W=IRISresultsGraphTemp mode=3, marker=19, rgb=(16385,28398,65535), msize = 5, mrkThick=2
				ModifyGraph/W=IRISresultsGraphTemp zmrkNum(wTempDataWave)={wTempFilterWave}
				ModifyGraph/W=IRISresultsGraphTemp axisEnab(left)={0,0.8}
				ModifyGraph standoff(bottom)=0
				TextBox/C/N=text0/F=0/B=1/A=LT sGasLabel
				SetAxis/W=IRISresultsGraphTemp/A
				SavePICT/WIN=IRISresultsGraphTemp/P=pResultsSubfolderPath/E=-5/RES=144 as sGraphsFilePNG
				KillWindow/Z IRISresultsGraphTemp
			endfor
		else
//			for(outputIndex=numCalibratedOutputVariables;outputIndex<numOutputVariables;outputIndex+=1)
//				sGraphsFilePNG = sGraphsFileNameBaseNoExt + " - Reference" + num2str(gasNum+1-numSampleGases) + " - Variable" + num2str(outputIndex) + ".png"
//				wTempDataWave = wOutputTimeSeriesMatrix[gasNum][outputIndex][p]
//				wTempErrorWave = wOutputTimeSeriesErrorMatrix[gasNum][outputIndex][p]
//				wTempFilterWave = (wOutputTimeSeriesFilterMatrix[gasNum][outputIndex][p] == 0) ? 19 : 8
//				Display/N=IRISresultsGraphTemp/W=(tempGraphLeftEdge, tempGraphTopEdge, tempGraphLeftEdge + tempGraphWidth, tempGraphTopEdge + tempGraphHeight)/HIDE=1 wTempDataWave vs wTempTimeWave
//				sYaxisLabel = wtOutputVariableNames[outputIndex] + " (" + wtOutputVariableUnits[outputIndex] + ")"
//				sGasLabel = "\Z12Reference Gas " + num2str(gasNum + 1 - numSampleGases)
//				Label/W=IRISresultsGraphTemp Left sYaxisLabel
//				Label/W=IRISresultsGraphTemp bottom " "
//				ErrorBars/W=IRISresultsGraphTemp wTempDataWave Y, wave=(wTempErrorWave,wTempErrorWave)
//				ModifyGraph/W=IRISresultsGraphTemp frameStyle = 0, fSize = 12
//				ModifyGraph/W=IRISresultsGraphTemp lblMargin(left)=5
//				ModifyGraph/W=IRISresultsGraphTemp mode=3, marker=19, rgb=(16385,28398,65535), msize = 5, mrkThick=2
//				ModifyGraph/W=IRISresultsGraphTemp zmrkNum(wTempDataWave)={wTempFilterWave}
//				ModifyGraph/W=IRISresultsGraphTemp axisEnab(left)={0,0.8}
//				ModifyGraph standoff(bottom)=0
//				TextBox/C/N=text0/F=0/B=1/A=LT sGasLabel
//				SetAxis/W=IRISresultsGraphTemp/A
//				SavePICT/WIN=IRISresultsGraphTemp/P=pResultsSubfolderPath/E=-5/RES=144 as sGraphsFilePNG
//				KillWindow/Z IRISresultsGraphTemp
//			endfor
			for(ii=0;ii<numVariablesToAverage;ii+=1)
				outputIndex = wIndicesOfVariablesToAverage[ii]
				sGraphsFilePNG = sGraphsFileNameBaseNoExt + " - Reference" + num2str(gasNum+1-numSampleGases) + " - Variable" + num2str(outputIndex) + ".png"
				wTempDataWave = wOutputTimeSeriesMatrix[gasNum][outputIndex][p]
				wTempErrorWave = wOutputTimeSeriesErrorMatrix[gasNum][outputIndex][p]
				wTempFilterWave = (wOutputTimeSeriesFilterMatrix[gasNum][outputIndex][p] == 0) ? 19 : 8
				Display/N=IRISresultsGraphTemp/W=(tempGraphLeftEdge, tempGraphTopEdge, tempGraphLeftEdge + tempGraphWidth, tempGraphTopEdge + tempGraphHeight)/HIDE=1 wTempDataWave vs wTempTimeWave
				sYaxisLabel = wtOutputVariableNames[outputIndex] + " (" + wtOutputVariableUnits[outputIndex] + ")"
				sGasLabel = "\Z12Reference Gas " + num2str(gasNum + 1 - numSampleGases)
				Label/W=IRISresultsGraphTemp Left sYaxisLabel
				Label/W=IRISresultsGraphTemp bottom " "
				ErrorBars/W=IRISresultsGraphTemp wTempDataWave Y, wave=(wTempErrorWave,wTempErrorWave)
				ModifyGraph/W=IRISresultsGraphTemp frameStyle = 0, fSize = 12
				ModifyGraph/W=IRISresultsGraphTemp lblMargin(left)=5
				ModifyGraph/W=IRISresultsGraphTemp mode=3, marker=19, rgb=(16385,28398,65535), msize = 5, mrkThick=2
				ModifyGraph/W=IRISresultsGraphTemp zmrkNum(wTempDataWave)={wTempFilterWave}
				ModifyGraph/W=IRISresultsGraphTemp axisEnab(left)={0,0.8}
				ModifyGraph standoff(bottom)=0
				TextBox/C/N=text0/F=0/B=1/A=LT sGasLabel
				SetAxis/W=IRISresultsGraphTemp/A
				SavePICT/WIN=IRISresultsGraphTemp/P=pResultsSubfolderPath/E=-5/RES=144 as sGraphsFilePNG
				KillWindow/Z IRISresultsGraphTemp
			endfor
		endif
		killwaves wTempDataWave, wTempErrorWave, wTempFilterWave, wTempTimeWave
	endfor
	
	// Then make and save diagnostic graph...
	
	IRIS_GUI_MakeDiagnosticGraph(1)
	sGraphsFilePNG = sGraphsFileNameBaseNoExt + " - Diagnostics.png"
	SavePICT/WIN=IRISresultsGraphTemp/P=pResultsSubfolderPath/E=-5/RES=144 as sGraphsFilePNG
	
	KillWindow/Z IRISresultsGraphTemp
		
	SetDataFolder $saveFolder
	
	return 0
	
End

Function IRIS_UTILITY_LoadConfig()
	
	NVAR numOutputVariables = root:numOutputVariables
	
	NVAR numGasParams = root:numGasParams
	NVAR numCalParams = root:numCalParams
	NVAR numBasicParams = root:numBasicParams
	NVAR numAdvancedParams = root:numAdvancedParams
	NVAR numFilterParams = root:numFilterParams
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	NVAR numGases = root:numGases
	
	SVAR sConfigFileName = root:sConfigFileName
	
	// Load configuration parameters from config file on disk
	make/O/T/N=0 wtParamNames, wtParamValues, wtParamUnits
	string sColumnStr = "F=-2,N=wtParamNames;F=-2,N=wtParamValues;F=-2,N=wtParamUnits;"
	Loadwave/Q/P=pIRISpath/J/N/L={0, 0, 0, 0, 0}/B=sColumnStr sConfigFileName // /L={nameLine, firstLine, numLines, firstColumn, numColumns}
	
	// Get number of sample gases and number of reference gases
	numSampleGases = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Sample Gases"))
	numRefGases = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Reference Gases"))
	numGases = numSampleGases + numRefGases
	
	// Get number of parameters in each table
	numGasParams = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Gas Parameters"))
	numCalParams = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Calibration Parameters"))
	numBasicParams = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Basic System Parameters"))
	numAdvancedParams = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Advanced System Parameters"))
	numFilterParams = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Filter Parameters"))
		
	// Propagate parameters to GUI tables
	IRIS_UTILITY_PropagateParamsToTables()
	
End

Function IRIS_UTILITY_SetParamNameValueAndUnits( i, param_name, param_value, param_units )
	
	variable i
	string param_name, param_value, param_units
	
	wave/T wtParamNames = root:wtParamNames
	wave/T wtParamValues = root:wtParamValues
	wave/T wtParamUnits = root:wtParamUnits
	
	if(exists("wtParamNames")==0)
		make/O/T/N=(i+1) wtParamNamesTemp, wtParamValuesTemp, wtParamUnitsTemp
		Duplicate/O/T wtParamNamesTemp, wtParamNames
		Duplicate/O/T wtParamValuesTemp, wtParamValues
		Duplicate/O/T wtParamUnitsTemp, wtParamUnits
		killwaves wtParamNamesTemp, wtParamValuesTemp, wtParamUnitsTemp
	else
		if(numpnts(wtParamNames) <= i)
			redimension/N=(i+1) wtParamNames, wtParamValues, wtParamUnits
		endif
	endif
	
	wtParamNames[i] = param_name
	wtParamValues[i] = param_value
	wtParamUnits[i] = param_units
	
	return 0
	
End

Function IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	variable outputIndex
	string name, sourceDataName, sourceDataType, units, format
	variable calibrateOrNot, rescaleFactor, diagnosticSlot
	
	wave/T wtOutputVariableNames = root:wtOutputVariableNames
	wave/T wtOutputVariableUnits = root:wtOutputVariableUnits
	wave/T wtOutputVariableFormats = root:wtOutputVariableFormats
	wave/T wtOutputVariableSourceDataNames = root:wtOutputVariableSourceDataNames
	wave/T wtOutputVariableSourceDataTypes = root:wtOutputVariableSourceDataTypes
	wave wOutputVariableCalibrateOrNots = root:wOutputVariableCalibrateOrNots
	wave wOutputVariableRescaleFactors = root:wOutputVariableRescaleFactors
	wave wOutputVariableDiagnosticSlots = root:wOutputVariableDiagnosticSlots
	
	variable numEntriesToAdd = (calibrateOrNot == 1) ? 2 : 1
	
	if(exists("wtOutputVariableNames")==0)
		make/O/T/N=(outputIndex+numEntriesToAdd) wtOutputVariableNamesTemp, wtOutputVariableUnitsTemp, wtOutputVariableFormatsTemp
		make/O/T/N=(outputIndex+numEntriesToAdd) wtOutputVariableSourceDataNamesTemp, wtOutputVariableSourceDataTypesTemp
		make/O/N=(outputIndex+numEntriesToAdd) wOutputVariableCalibrateOrNotsTemp, wOutputVariableRescaleFactorsTemp, wOutputVariableDiagnosticSlotsTemp
		Duplicate/O/T wtOutputVariableNamesTemp, wtOutputVariableNames
		Duplicate/O/T wtOutputVariableUnitsTemp, wtOutputVariableUnits
		Duplicate/O/T wtOutputVariableFormatsTemp, wtOutputVariableFormats
		Duplicate/O/T wtOutputVariableSourceDataNamesTemp, wtOutputVariableSourceDataNames
		Duplicate/O/T wtOutputVariableSourceDataTypesTemp, wtOutputVariableSourceDataTypes
		Duplicate/O wOutputVariableCalibrateOrNotsTemp, wOutputVariableCalibrateOrNots
		Duplicate/O wOutputVariableRescaleFactorsTemp, wOutputVariableRescaleFactors
		Duplicate/O wOutputVariableDiagnosticSlotsTemp, wOutputVariableDiagnosticSlots
		killwaves wtOutputVariableNamesTemp, wtOutputVariableUnitsTemp, wtOutputVariableFormatsTemp
		killwaves wtOutputVariableSourceDataNamesTemp, wtOutputVariableSourceDataTypesTemp
		killwaves wOutputVariableCalibrateOrNotsTemp, wOutputVariableRescaleFactorsTemp, wOutputVariableDiagnosticSlotsTemp
	else
		if(numpnts(wtOutputVariableNames) < (outputIndex+numEntriesToAdd))
			redimension/N=(outputIndex+numEntriesToAdd) wtOutputVariableNames, wtOutputVariableUnits, wtOutputVariableFormats
			redimension/N=(outputIndex+numEntriesToAdd) wtOutputVariableSourceDataNames, wtOutputVariableSourceDataTypes
			redimension/N=(outputIndex+numEntriesToAdd) wOutputVariableCalibrateOrNots, wOutputVariableRescaleFactors, wOutputVariableDiagnosticSlots
		endif
	endif
	
	if(calibrateOrNot == 1)
		
		// Entry for the calibrated version of this variable
		wtOutputVariableNames[outputIndex] = name
		wtOutputVariableUnits[outputIndex] = units
		wtOutputVariableFormats[outputIndex] = format
		wtOutputVariableSourceDataNames[outputIndex] = sourceDataName // IRIS will construct the appropriate fill-period-mean wave name for each sample gas from sourceDataName
		wtOutputVariableSourceDataTypes[outputIndex] = "avg" // only cell-fill-period means can be calibrated via ref gas(es)
		wOutputVariableCalibrateOrNots[outputIndex] = 1
		wOutputVariableRescaleFactors[outputIndex] = 1 // rescaling will be done when averaging, and we do not want to do it again when calibrating
		wOutputVariableDiagnosticSlots[outputIndex] = 0 // calibrated variables are never in the diagnostic graph
		outputIndex += 1
		
		// Entry for the uncalibrated version of this variable
		wtOutputVariableNames[outputIndex] = "Unreferenced " + name // modified name to indicate this version is uncalibrated
		wtOutputVariableUnits[outputIndex] = units
		wtOutputVariableFormats[outputIndex] = format
		wtOutputVariableSourceDataNames[outputIndex] = sourceDataName
		wtOutputVariableSourceDataTypes[outputIndex] = sourceDataType
		wOutputVariableCalibrateOrNots[outputIndex] = 0
		wOutputVariableRescaleFactors[outputIndex] = rescaleFactor
		wOutputVariableDiagnosticSlots[outputIndex] = diagnosticSlot
		outputIndex += 1
		
	else
		
		wtOutputVariableNames[outputIndex] = name // no need for modified name since there is only one version
		wtOutputVariableUnits[outputIndex] = units
		wtOutputVariableFormats[outputIndex] = format
		wtOutputVariableSourceDataNames[outputIndex] = sourceDataName
		wtOutputVariableSourceDataTypes[outputIndex] = sourceDataType
		wOutputVariableCalibrateOrNots[outputIndex] = 0
		wOutputVariableRescaleFactors[outputIndex] = rescaleFactor
		wOutputVariableDiagnosticSlots[outputIndex] = diagnosticSlot
		outputIndex += 1
		
	endif
	
	return outputIndex // return the appropriately incremented value of outputIndex
	
End

// OLD
Function IRIS_UTILITY_SetOutputNameUnitsAndFormat( i, output_name, output_units, output_format )
	
	variable i
	string output_name, output_units, output_format
	
	wave/T wtOutputVariableNames = root:wtOutputVariableNames
	wave/T wtOutputVariableUnits = root:wtOutputVariableUnits
	wave/T wtOutputVariableFormats = root:wtOutputVariableFormats
	
	if(exists("wtOutputVariableNames")==0)
		make/O/T/N=(i+1) wtOutputVariableNamesTemp, wtOutputVariableUnitsTemp, wtOutputVariableFormatsTemp
		Duplicate/O/T wtOutputVariableNamesTemp, wtOutputVariableNames
		Duplicate/O/T wtOutputVariableUnitsTemp, wtOutputVariableUnits
		Duplicate/O/T wtOutputVariableFormatsTemp, wtOutputVariableFormats
		killwaves wtOutputVariableNamesTemp, wtOutputVariableUnitsTemp, wtOutputVariableFormatsTemp
	else
		if(numpnts(wtOutputVariableNames) <= i)
			redimension/N=(i+1) wtOutputVariableNames, wtOutputVariableUnits, wtOutputVariableFormats
		endif
	endif
	
	wtOutputVariableNames[i] = output_name
	wtOutputVariableUnits[i] = output_units
	wtOutputVariableFormats[i] = output_format
	
	return 0
	
End

Function IRIS_UTILITY_SetParamValueByName( param_name, param_value )
	
	String param_name, param_value
	
	wave/T wtParamNames = root:wtParamNames
	wave/T wtParamValues = root:wtParamValues
	
	Variable the_index = -1, idex = 0
	String this_header
	
	if(exists("wtParamNames")==1)
		do
			this_header = wtParamNames[idex]
			if( strsearch( this_header, param_name, 0) != -1 )
				the_index = idex
				idex = numpnts(wtParamNames)
			endif
			idex += 1
		while( idex < numpnts( wtParamNames ) )
	endif
	
	if( the_index == -1 )
		return 1
	endif
	
	wtParamValues[the_index] = param_value
	
	return 0
	
End

Function IRIS_UTILITY_SetParamUnitsByName( param_name, param_units )
	
	String param_name, param_units
	
	wave/T wtParamNames = root:wtParamNames
	wave/T wtParamUnits = root:wtParamUnits
	
	Variable the_index = -1, idex = 0
	String this_header
	
	if(exists("wtParamNames")==1)
		do
			this_header = wtParamNames[idex]
			if( strsearch( this_header, param_name, 0) != -1 )
				the_index = idex
				idex = numpnts(wtParamNames)
			endif
			idex += 1
		while( idex < numpnts( wtParamNames ) )
	endif
	
	if( the_index == -1 )
		return 1
	endif
	
	wtParamUnits[the_index] = param_units
	
	return 0
	
End

Function/T IRIS_UTILITY_GetParamValueFromName( param_name )
	
	String param_name
	
	wave/T wtParamNames = root:wtParamNames
	wave/T wtParamValues = root:wtParamValues
	
	Variable the_index = -1, idex = 0
	String this_header, the_value_str
	Variable the_value_num	
	
	if(exists("wtParamNames")==1)
		do
			this_header = wtParamNames[idex]
			if( strsearch( this_header, param_name, 0) != -1 )
				the_index = idex
				idex = numpnts(wtParamNames)
			endif
			idex += 1
		while( idex < numpnts( wtParamNames ) )
	endif
	
	if( the_index == -1 )
		return "NotFound"
	endif
	
	the_value_str = wtParamValues[the_index]
	
	return the_value_str
	
End

Function IRIS_UTILITY_GetOutputIndexFromName( output_name )
	
	String output_name
	
	wave/T wtOutputVariableNames = root:wtOutputVariableNames
	
	Variable the_index = -1, idex = 0
	String this_header, the_value_str
	Variable the_value_num	
	
	if(exists("wtOutputVariableNames")==1)
		do
			this_header = wtOutputVariableNames[idex]
			if( strsearch( this_header, output_name, 0) != -1 )
				the_index = idex
				idex = numpnts(wtOutputVariableNames)
			endif
			idex += 1
		while( idex < numpnts( wtOutputVariableNames ) )
	endif
	
	return the_index
	
End

Function IRIS_UTILITY_PropagateParamsToTables()
	
	NVAR numOutputVariables = root:numOutputVariables
	
	NVAR numGasParams = root:numGasParams
	NVAR numCalParams = root:numCalParams
	NVAR numBasicParams = root:numBasicParams
	NVAR numAdvancedParams = root:numAdvancedParams
	NVAR numFilterParams = root:numFilterParams
	
	SVAR calEqnStr_UI = root:calEqnStr_UI
	
	wave/T wtParamNames = root:wtParamNames
	wave/T wtParamValues = root:wtParamValues
	wave/T wtParamUnits = root:wtParamUnits
	
	string saveFolder = GetDataFolder(1);
	SetDataFolder root:
	
	// Distinguishing gas info, calibration options, basic system options, advanced system options, and data filtering options
	
	make/O/T/N=(numGasParams) wtGasParamNames, wtGasParamValues, wtGasParamUnits
	wtGasParamNames = wtParamNames[p]
	wtGasParamValues = wtParamValues[p]
	wtGasParamUnits = wtParamUnits[p]
	
//	make/O/T/N=(numCalParams) wtCalParamNames, wtCalParamValues, wtCalParamUnits
//	wtCalParamNames = wtParamNames[numGasParams + p]
//	wtCalParamValues = wtParamValues[numGasParams + p]
//	wtCalParamUnits = wtParamUnits[numGasParams + p]
	
	calEqnStr_UI = IRIS_UTILITY_GetParamValueFromName("Calibration Curve Equation")
	IRIS_UTILITY_ValidateCalCurveEqn()
	
	make/O/T/N=(numBasicParams) wtBasicParamNames, wtBasicParamValues, wtBasicParamUnits
	wtBasicParamNames = wtParamNames[numGasParams + numCalParams + p]
	wtBasicParamValues = wtParamValues[numGasParams + numCalParams + p]
	wtBasicParamUnits = wtParamUnits[numGasParams + numCalParams + p]
	
	make/O/T/N=(numAdvancedParams) wtAdvParamNames, wtAdvParamValues, wtAdvParamUnits
	wtAdvParamNames = wtParamNames[numGasParams + numCalParams + numBasicParams + p]
	wtAdvParamValues = wtParamValues[numGasParams + numCalParams + numBasicParams + p]
	wtAdvParamUnits = wtParamUnits[numGasParams + numCalParams + numBasicParams + p]
	
	make/O/T/N=(numFilterParams) wtFilterParamNames, wtFilterParamValues, wtFilterParamUnits
	wtFilterParamNames = wtParamNames[numGasParams + numCalParams + numBasicParams + numAdvancedParams + p]
	wtFilterParamValues = wtParamValues[numGasParams + numCalParams + numBasicParams + numAdvancedParams + p]
	wtFilterParamUnits = wtParamUnits[numGasParams + numCalParams + numBasicParams + numAdvancedParams + p]
	
	// Creating rearranged table of data filtering options for GUI
	
	make/O/T/N=(numOutputVariables) wtDataFilterTable_CheckForOutliers, wtDataFilterTable_OutlierThresholds, wtDataFilterTable_FilterGroups
	variable outputIndex
	for(outputIndex=0;outputIndex<numOutputVariables;outputIndex+=1)
		wtDataFilterTable_CheckForOutliers[outputIndex] = wtFilterParamValues[3*outputIndex]
		wtDataFilterTable_OutlierThresholds[outputIndex] = wtFilterParamValues[3*outputIndex + 1]
		wtDataFilterTable_FilterGroups[outputIndex] = wtFilterParamValues[3*outputIndex + 2]
	endfor
	
	SetDataFolder $saveFolder
	
End

Function IRIS_UTILITY_RebuildParamWavesFromTables()
	
	NVAR numOutputVariables = root:numOutputVariables
	NVAR numGasParams = root:numGasParams
	NVAR numCalParams = root:numCalParams
	NVAR numBasicParams = root:numBasicParams
	NVAR numAdvancedParams = root:numAdvancedParams
	NVAR numFilterParams = root:numFilterParams
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	NVAR numGases = root:numGases
	
	SVAR calEqnStr_UI = root:calEqnStr_UI
	
	wave/T wtParamNames = root:wtParamNames
	wave/T wtParamValues = root:wtParamValues
	wave/T wtParamUnits = root:wtParamUnits
	wave/T wtGasParamNames = root:wtGasParamNames
	wave/T wtGasParamValues = root:wtGasParamValues
	wave/T wtGasParamUnits = root:wtGasParamUnits
//	wave/T wtCalParamNames = root:wtCalParamNames
//	wave/T wtCalParamValues = root:wtCalParamValues
//	wave/T wtCalParamUnits = root:wtCalParamUnits
	wave/T wtBasicParamNames = root:wtBasicParamNames
	wave/T wtBasicParamValues = root:wtBasicParamValues
	wave/T wtBasicParamUnits = root:wtBasicParamUnits
	wave/T wtAdvParamNames = root:wtAdvParamNames
	wave/T wtAdvParamValues = root:wtAdvParamValues
	wave/T wtAdvParamUnits = root:wtAdvParamUnits
	wave/T wtFilterParamNames = root:wtFilterParamNames
	wave/T wtFilterParamValues = root:wtFilterParamValues
	wave/T wtFilterParamUnits = root:wtFilterParamUnits
	
	// Updating data filtering param values from GUI data filtering table
	wave/T wtDataFilterTable_CheckForOutliers
	wave/T wtDataFilterTable_OutlierThresholds
	wave/T wtDataFilterTable_FilterGroups
	NVAR numOutputVariables = root:numOutputVariables
	variable outputIndex
	for(outputIndex=0;outputIndex<numOutputVariables;outputIndex+=1)
		if((cmpstr("y", wtDataFilterTable_CheckForOutliers[outputIndex]) == 0) || (cmpstr("yes", wtDataFilterTable_CheckForOutliers[outputIndex]) == 0) || (cmpstr("1", wtDataFilterTable_CheckForOutliers[outputIndex]) == 0))
			wtFilterParamValues[3*outputIndex] = "y"
		else
			wtFilterParamValues[3*outputIndex] = "n"
		endif
		wtFilterParamValues[3*outputIndex + 1] = wtDataFilterTable_OutlierThresholds[outputIndex]
		wtFilterParamValues[3*outputIndex + 2] = wtDataFilterTable_FilterGroups[outputIndex]
	endfor
	
	wtParamNames[0, numGasParams - 1] = wtGasParamNames[p]
	wtParamValues[0, numGasParams - 1] = wtGasParamValues[p]
	wtParamUnits[0, numGasParams - 1] = wtGasParamUnits[p]
	
//	wtParamNames[numGasParams, numGasParams + numCalParams - 1] = wtCalParamNames[p - numGasParams]
//	wtParamValues[numGasParams, numGasParams + numCalParams - 1] = wtCalParamValues[p - numGasParams]
//	wtParamUnits[numGasParams, numGasParams + numCalParams - 1] = wtCalParamUnits[p - numGasParams]
	
	IRIS_UTILITY_SetParamValueByName( "Calibration Curve Equation", calEqnStr_UI )
	
	wtParamNames[numGasParams + numCalParams, numGasParams + numCalParams + numBasicParams - 1] = wtBasicParamNames[p - numGasParams - numCalParams]
	wtParamValues[numGasParams + numCalParams, numGasParams + numCalParams + numBasicParams - 1] = wtBasicParamValues[p - numGasParams - numCalParams]
	wtParamUnits[numGasParams + numCalParams, numGasParams + numCalParams + numBasicParams - 1] = wtBasicParamUnits[p - numGasParams - numCalParams]
	
	wtParamNames[numGasParams + numCalParams + numBasicParams, numGasParams + numCalParams + numBasicParams + numAdvancedParams - 1] = wtAdvParamNames[p - numGasParams - numCalParams - numBasicParams]
	wtParamValues[numGasParams + numCalParams + numBasicParams, numGasParams + numCalParams + numBasicParams + numAdvancedParams - 1] = wtAdvParamValues[p - numGasParams - numCalParams - numBasicParams]
	wtParamUnits[numGasParams + numCalParams + numBasicParams, numGasParams + numCalParams + numBasicParams + numAdvancedParams - 1] = wtAdvParamUnits[p - numGasParams - numCalParams - numBasicParams]
	
	wtParamNames[numGasParams + numCalParams + numBasicParams + numAdvancedParams, numGasParams + numCalParams + numBasicParams + numAdvancedParams + numFilterParams - 1] = wtFilterParamNames[p - numGasParams - numCalParams - numBasicParams - numAdvancedParams]
	wtParamValues[numGasParams + numCalParams + numBasicParams + numAdvancedParams, numGasParams + numCalParams + numBasicParams + numAdvancedParams + numFilterParams - 1] = wtFilterParamValues[p - numGasParams - numCalParams - numBasicParams - numAdvancedParams]
	wtParamUnits[numGasParams + numCalParams + numBasicParams + numAdvancedParams, numGasParams + numCalParams + numBasicParams + numAdvancedParams + numFilterParams - 1] = wtFilterParamUnits[p - numGasParams - numCalParams - numBasicParams - numAdvancedParams]
	
	//	Concatenate/O/NP/T {wtUntabledParamNames, wtGasParamNames, wtBasicParamNames, wtAdvParamNames, wtFilterParamNames}, wtParamNames
	//	Concatenate/O/NP/T {wtUntabledParamValues, wtGasParamValues, wtBasicParamValues, wtAdvParamValues, wtFilterParamValues}, wtParamValues
	//	Concatenate/O/NP/T {wtUntabledParamUnits, wtGasParamUnits, wtBasicParamUnits, wtAdvParamUnits, wtFilterParamUnits}, wtParamUnits
	
End

Function IRIS_UTILITY_ClearSchedule(sScheduleName)
	string sScheduleName
	
	string sWaveName_WhichTimer
	string sWaveName_TriggerTime
	string sWaveName_Action
	string sWaveName_Argument
	string sWaveName_Comment
		
	sWaveName_WhichTimer = "wSchedule_" + sScheduleName + "_WhichTimer"
	sWaveName_TriggerTime = "wSchedule_" + sScheduleName + "_TriggerTime"
	sWaveName_Action = "wSchedule_" + sScheduleName + "_Action"
	sWaveName_Argument = "wSchedule_" + sScheduleName + "_Argument"
	sWaveName_Comment = "wSchedule_" + sScheduleName + "_Comment"
	
	if(exists(sWaveName_TriggerTime) == 1)
		redimension/N=0 $sWaveName_WhichTimer
		redimension/N=0 $sWaveName_TriggerTime
		redimension/N=0 $sWaveName_Action
		redimension/N=0 $sWaveName_Argument
		redimension/N=0 $sWaveName_Comment
	endif
	
End

Function IRIS_UTILITY_AppendEventToSchedule(sScheduleName, whichTimer, triggerTime, sAction, sArgument, sComment)
	string sScheduleName
	variable whichTimer
	variable triggerTime
	string sAction
	string sArgument
	string sComment
	
	string sWaveName_WhichTimer
	string sWaveName_TriggerTime
	string sWaveName_Action
	string sWaveName_Argument
	string sWaveName_Comment
	
	sWaveName_WhichTimer = "wSchedule_" + sScheduleName + "_WhichTimer"
	sWaveName_TriggerTime = "wSchedule_" + sScheduleName + "_TriggerTime"
	sWaveName_Action = "wSchedule_" + sScheduleName + "_Action"
	sWaveName_Argument = "wSchedule_" + sScheduleName + "_Argument"
	sWaveName_Comment = "wSchedule_" + sScheduleName + "_Comment"
	
	make/O/N=1 wTemp_WhichTimer = whichTimer
	make/O/D/N=1 wTemp_TriggerTime = triggerTime
	make/O/T/N=1 wTemp_Action = sAction
	make/O/T/N=1 wTemp_Argument = sArgument
	make/O/T/N=1 wTemp_Comment = sComment
	
	// Concatenate will create the destination wave if it does not exist, or append to it otherwise
	Concatenate/NP {wTemp_WhichTimer}, $sWaveName_WhichTimer
	Concatenate/NP {wTemp_TriggerTime}, $sWaveName_TriggerTime
	Concatenate/T/NP {wTemp_Action}, $sWaveName_Action
	Concatenate/T/NP {wTemp_Argument}, $sWaveName_Argument
	Concatenate/T/NP {wTemp_Comment}, $sWaveName_Comment
		
	killwaves wTemp_WhichTimer
	killwaves wTemp_TriggerTime
	killwaves wTemp_Action
	killwaves wTemp_Argument
	killwaves wTemp_Comment
		
End

Function IRIS_UTILITY_AppendScheduleToSchedule(sNameOfBaseSchedule, sNameOfScheduleToAppend)
	string sNameOfScheduleToAppend
	string sNameOfBaseSchedule
	
	string sNameOfScheduleToAppend_WhichTimer
	string sNameOfScheduleToAppend_TriggerTime
	string sNameOfScheduleToAppend_Action
	string sNameOfScheduleToAppend_Argument
	string sNameOfScheduleToAppend_Comment
	
	string sNameOfBaseSchedule_WhichTimer
	string sNameOfBaseSchedule_TriggerTime
	string sNameOfBaseSchedule_Action
	string sNameOfBaseSchedule_Argument
	string sNameOfBaseSchedule_Comment
	
	sNameOfScheduleToAppend_WhichTimer = "wSchedule_" + sNameOfScheduleToAppend + "_WhichTimer"
	sNameOfScheduleToAppend_TriggerTime = "wSchedule_" + sNameOfScheduleToAppend + "_TriggerTime"
	sNameOfScheduleToAppend_Action = "wSchedule_" + sNameOfScheduleToAppend + "_Action"
	sNameOfScheduleToAppend_Argument = "wSchedule_" + sNameOfScheduleToAppend + "_Argument"
	sNameOfScheduleToAppend_Comment = "wSchedule_" + sNameOfScheduleToAppend + "_Comment"
	
	sNameOfBaseSchedule_WhichTimer = "wSchedule_" + sNameOfBaseSchedule + "_WhichTimer"
	sNameOfBaseSchedule_TriggerTime = "wSchedule_" + sNameOfBaseSchedule + "_TriggerTime"
	sNameOfBaseSchedule_Action = "wSchedule_" + sNameOfBaseSchedule + "_Action"
	sNameOfBaseSchedule_Argument = "wSchedule_" + sNameOfBaseSchedule + "_Argument"
	sNameOfBaseSchedule_Comment = "wSchedule_" + sNameOfBaseSchedule + "_Comment"
	
	if(exists(sNameOfScheduleToAppend_WhichTimer) == 1)
		// Concatenate will create the base wave if it does not exist, or append to it otherwise
		Concatenate/NP {$sNameOfScheduleToAppend_WhichTimer}, $sNameOfBaseSchedule_WhichTimer
		Concatenate/NP {$sNameOfScheduleToAppend_TriggerTime}, $sNameOfBaseSchedule_TriggerTime
		Concatenate/T/NP {$sNameOfScheduleToAppend_Action}, $sNameOfBaseSchedule_Action
		Concatenate/T/NP {$sNameOfScheduleToAppend_Argument}, $sNameOfBaseSchedule_Argument
		Concatenate/T/NP {$sNameOfScheduleToAppend_Comment}, $sNameOfBaseSchedule_Comment
	endif
	
End

Function IRIS_UTILITY_AppendStringToNoteBook(nb, str) // Appends the string to the named notebook
	String nb // name of the notebook to log to
	String str // the string to log
	Notebook $nb selection = {endOfFile, endOfFile}
	Notebook $nb text = "\r" + str
End

Function IRIS_UTILITY_AnalysisSetup()
	
	// Collate data filtering settings
	
	IRIS_UTILITY_CollateDataFilterSettings()
	
	// Collate sample and ref gas ECL indices
	
	IRIS_UTILITY_CollateSampleAndRefIndices()
		
	// Discard sample periods that are not bracketed in time by ALL ref gases
	
	IRIS_UTILITY_TrimUnbracketedSamples()
	
	// Parse times and check for missing gases
	
	variable parseFlag = IRIS_UTILITY_ParseSampleAndRefTimes()
	
	return parseFlag
	
End

Function IRIS_UTILITY_CollateSampleAndRefIndices()
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	
	variable sampleNum, refNum
	string sIRIStemp
	
	wave wSampleIndices = root:wSampleIndices
	wave wRefIndices = root:wRefIndices
	
	for(sampleNum=0;sampleNum<numSampleGases;sampleNum+=1)
		sIRIStemp = "ECL Index for Sample " + num2str(sampleNum+1)
		wSampleIndices[sampleNum] = str2num(IRIS_UTILITY_GetParamValueFromName(sIRIStemp))
	endfor
	
	for(refNum=0;refNum<numRefGases;refNum+=1)
		sIRIStemp = "ECL Index for Reference " + num2str(refNum+1)
		wRefIndices[refNum] = str2num(IRIS_UTILITY_GetParamValueFromName(sIRIStemp))
	endfor
		
End

Function IRIS_UTILITY_TrimUnbracketedSamples()
	
	// Change sample periods to transition (i.e. garbage) periods if they are not preceded by and followed
	// by all ref gases (the rule is: don't extrapolate any refs in time, only interpolate; in other words,
	// only use sample periods that are bracketed in time by ALL ref gases)
	
	wave wRefIndices = root:wRefIndices
	wave wSampleIndices = root:wSampleIndices
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	
	variable i, sampleNum, refNum
	variable thisWasSample, allRefsFound
	
	string ECL_transitionIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Transition")
	variable transitionIndexVar = str2num(ECL_transitionIndex)
	
	wave stc_ECL_index = root:stc_ECL_index
	variable stcLength = numpnts(stc_ECL_index)
		
	duplicate/O wRefIndices, wRefIndicesFound
	
	wRefIndicesFound = 0
	allRefsFound = 0
	i = 0
	do
		thisWasSample = 0
		for(sampleNum=0;sampleNum<numSampleGases;sampleNum+=1)
			if(stc_ECL_index[i] == wSampleIndices[sampleNum])
				stc_ECL_index[i] = transitionIndexVar
				thisWasSample = 1
				break
			endif
		endfor
		if(thisWasSample == 0)
			for(refNum=0;refNum<numRefGases;refNum+=1)
				if(stc_ECL_index[i] == wRefIndices[refNum])
					wRefIndicesFound[refNum] = 1
					break
				endif
			endfor
			if(sum(wRefIndicesFound) == numRefGases)
				allRefsFound = 1
			endif
		endif
		i += 1
	while((allRefsFound == 0) && (i < stcLength))
	
	wRefIndicesFound = 0
	allRefsFound = 0
	i = stcLength - 1
	do
		thisWasSample = 0
		for(sampleNum=0;sampleNum<numSampleGases;sampleNum+=1)
			if(stc_ECL_index[i] == wSampleIndices[sampleNum])
				stc_ECL_index[i] = transitionIndexVar
				thisWasSample = 1
				break
			endif
		endfor
		if(thisWasSample == 0)
			for(refNum=0;refNum<numRefGases;refNum+=1)
				if(stc_ECL_index[i] == wRefIndices[refNum])
					wRefIndicesFound[refNum] = 1
					break
				endif
			endfor
			if(sum(wRefIndicesFound) == numRefGases)
				allRefsFound = 1
			endif
		endif
		i -= 1
	while((allRefsFound == 0) && (i >= 0))
	
	killwaves wRefIndicesFound
	
End

Function IRIS_UTILITY_ParseSampleAndRefTimes()
	
	string saveFolder = getdatafolder(1)
	SetDataFolder root:
	
	wave wSampleIndices = root:wSampleIndices
	wave wRefIndices = root:wRefIndices
	wave wNumCompleteMeasurementsByGas = root:wNumCompleteMeasurementsByGas
	
	wave wOutputTimeSeriesMatrix = root:wOutputTimeSeriesMatrix
	wave wOutputTimeSeriesErrorMatrix = root:wOutputTimeSeriesErrorMatrix
	wave wOutputTimeSeriesFilterMatrix = root:wOutputTimeSeriesFilterMatrix
	wave wOutputTime = root:wOutputTime
	
	wave wOutputMeans = root:wOutputMeans
	wave wOutputStDevs = root:wOutputStDevs
	wave wOutputStErrs = root:wOutputStErrs
	
	wave wOutputMeanToGraph1 = root:wOutputMeanToGraph1
	wave wOutputErrorToGraph1 = root:wOutputErrorToGraph1
	wave wOutputFilterToGraph1 = root:wOutputFilterToGraph1
	wave wOutputTimeToGraph1 = root:wOutputTimeToGraph1
	wave wOutputMeanToGraph2 = root:wOutputMeanToGraph2
	wave wOutputErrorToGraph2 = root:wOutputErrorToGraph2
	wave wOutputFilterToGraph2 = root:wOutputFilterToGraph2
	wave wOutputTimeToGraph2 = root:wOutputTimeToGraph2
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	NVAR numGases = root:numGases
	NVAR numOutputVariables = root:numOutputVariables
	
	variable sampleNum, refNum
	variable thisIndexIsAbsent
	string sIRIStemp
	
	for(sampleNum=0;sampleNum<numSampleGases;sampleNum+=1)
		thisIndexIsAbsent = IRIS_ECL_ParseAndCutIndex(wSampleIndices[sampleNum], tidyup = 1, FirstLineIsStart = 0, LastLineIsStop = 0, SummaryTable = 0)	
		if(thisIndexIsAbsent > 0)
			SetDataFolder $saveFolder
			return 1
		else
			sIRIStemp = "ECL_" + num2str(wSampleIndices[sampleNum]) + "_StartTime"
			wNumCompleteMeasurementsByGas[sampleNum] = numpnts(root:ECL_WorkFolder_A:$sIRIStemp)
		endif
	endfor
	
	for(refNum=0;refNum<numRefGases;refNum+=1)
		thisIndexIsAbsent = IRIS_ECL_ParseAndCutIndex(wRefIndices[refNum], tidyup = 1, FirstLineIsStart = 0, LastLineIsStop = 0, SummaryTable = 0)	
		if(thisIndexIsAbsent > 0)
			SetDataFolder $saveFolder
			return 1
		else
			sIRIStemp = "ECL_" + num2str(wRefIndices[refNum]) + "_StartTime"
			wNumCompleteMeasurementsByGas[numSampleGases + refNum] = numpnts(root:ECL_WorkFolder_A:$sIRIStemp)
		endif
	endfor
	
//	// TEMP HACK FOR MAKING A GRAPH... // TESTING!!!
//	wNumCompleteMeasurementsByGas[0] = 10
//	wNumCompleteMeasurementsByGas[1] = 11
	
	variable maxNumCompleteMeasurementsAcrossAllGases = wavemax(wNumCompleteMeasurementsByGas)
	
	// Add any new elements to results waves/matrices
	
	redimension/N=(numGases,numOutputVariables,maxNumCompleteMeasurementsAcrossAllGases) wOutputTimeSeriesMatrix, wOutputTimeSeriesErrorMatrix, wOutputTimeSeriesFilterMatrix
	redimension/N=(numGases,maxNumCompleteMeasurementsAcrossAllGases) wOutputTime
	redimension/N=(maxNumCompleteMeasurementsAcrossAllGases) wOutputMeanToGraph1, wOutputErrorToGraph1, wOutputFilterToGraph1, wOutputTimeToGraph1
	redimension/N=(maxNumCompleteMeasurementsAcrossAllGases) wOutputMeanToGraph2, wOutputErrorToGraph2, wOutputFilterToGraph2, wOutputTimeToGraph2
	
	SetDataFolder $saveFolder
	return 0
			
End

Function IRIS_UTILITY_CollateDataFilterSettings()
	
	NVAR numOutputVariables = root:numOutputVariables
	
	variable i
	
	wave/T wtOutputVariableNames = root:wtOutputVariableNames
	wave wCheckForOutliers = root:wCheckForOutliers
	wave wOutlierThresholds = root:wOutlierThresholds
	wave wOutlierFilterGroups = root:wOutlierFilterGroups
	for(i=0;i<numOutputVariables;i+=1)
		if(cmpstr("y", IRIS_UTILITY_GetParamValueFromName("Check " + wtOutputVariableNames[i] + " for Outliers")) == 0)
			wCheckForOutliers[i] = 1
		else
			wCheckForOutliers[i] = 0
		endif
		wOutlierThresholds[i] = str2num(IRIS_UTILITY_GetParamValueFromName("Outlier Threshold for " + wtOutputVariableNames[i]))
		wOutlierFilterGroups[i] = str2num(IRIS_UTILITY_GetParamValueFromName("Outlier Filter Group for " + wtOutputVariableNames[i]))
	endfor
	
End

Function IRIS_UTILITY_ApplyDataFilters()
	
	wave wNumCompleteMeasurementsByGas = root:wNumCompleteMeasurementsByGas
	
	wave wOutputTimeSeriesMatrix = root:wOutputTimeSeriesMatrix
	wave wOutputTimeSeriesFilterMatrix = root:wOutputTimeSeriesFilterMatrix
	
	wave wOutputMeans = root:wOutputMeans
	wave wOutputStDevs = root:wOutputStDevs
	wave wOutputStErrs = root:wOutputStErrs
	
	NVAR minPointsForOutlierFiltering = root:minPointsForOutlierFiltering
	NVAR numGases = root:numGases
	NVAR numOutputVariables = root:numOutputVariables
	
	variable gasNum, outputIndex
	variable meanTemp, sdTemp
	
	for(gasNum=0;gasNum<numGases;gasNum+=1)
		if(wNumCompleteMeasurementsByGas[gasNum] >= minPointsForOutlierFiltering)
			for(outputIndex=0;outputIndex<numOutputVariables;outputIndex+=1)
				make/O/D/N=(wNumCompleteMeasurementsByGas[gasNum]) IRIS_wTemp, wFilterWave
				IRIS_wTemp = wOutputTimeSeriesMatrix[gasNum][outputIndex][p]
				wFilterWave = wOutputTimeSeriesFilterMatrix[gasNum][outputIndex][p]
				Extract/O IRIS_wTemp, IRIS_wTemp_Filtered, (wFilterWave != 1)
				meanTemp = mean(IRIS_wTemp_Filtered)
				sdTemp = sqrt(variance(IRIS_wTemp_Filtered))
				wOutputMeans[gasNum][outputIndex] = meanTemp
				wOutputStDevs[gasNum][outputIndex] = sdTemp
				wOutputStErrs[gasNum][outputIndex] = sdTemp/sqrt(numpnts(IRIS_wTemp_Filtered))
				killwaves IRIS_wTemp, wFilterWave, IRIS_wTemp_Filtered
			endfor
		endif
	endfor
	
End

Function IRIS_UTILITY_AnalysisWrapUp()
	
	wave/T wtOutputVariableSourceDataNames = root:wtOutputVariableSourceDataNames
	wave wIndicesOfVariablesToCalibrate = root:wIndicesOfVariablesToCalibrate
	
	NVAR numVariablesToCalibrate = root:numVariablesToCalibrate
	
	variable i, outputIndex
	
	string sDataName, sSimpleCalName
	
	for(i=0;i<numVariablesToCalibrate;i+=1)
		outputIndex = wIndicesOfVariablesToCalibrate[i]
		sDataName = wtOutputVariableSourceDataNames[outputIndex]
		sSimpleCalName = sDataName + "_cal"
		killwaves root:$sSimpleCalName
	endfor
	
	// Data filtering (apply filtering due to any variable in the same filter group)
	
	IRIS_UTILITY_ApplyDataFilters()
	
	// Set which variables to display
	
	IRIS_UTILITY_PopulateNumericOutput(1)
	IRIS_UTILITY_PopulateNumericOutput(2)
	IRIS_UTILITY_PopulateNumericOutput(3)
	IRIS_UTILITY_PopulateGraphOutput()
	
	// Set scales and masks for the diagnostic graph
	
	IRIS_UTILITY_ScaleAndMaskDiagnosticGraph()
	
	DoUpdate
	
End

Function IRIS_UTILITY_DefineVariablesHousekeeping(numOutputVariables_local)
	variable numOutputVariables_local
	
	NVAR numOutputVariables = root:numOutputVariables
	numOutputVariables = numOutputVariables_local
	
	wave/T wtOutputVariableNames = root:wtOutputVariableNames
	wave/T wtOutputVariableUnits = root:wtOutputVariableUnits
	wave/T wtOutputVariableFormats = root:wtOutputVariableFormats
	wave/T wtOutputVariableSourceDataNames = root:wtOutputVariableSourceDataNames
	wave/T wtOutputVariableSourceDataTypes = root:wtOutputVariableSourceDataTypes
	wave wOutputVariableCalibrateOrNots = root:wOutputVariableCalibrateOrNots
	wave wOutputVariableRescaleFactors = root:wOutputVariableRescaleFactors
	wave wOutputVariableDiagnosticSlots = root:wOutputVariableDiagnosticSlots
	
	variable i, averageThis, calibrateThis
	
	variable/G numVariablesToAverage = 0
	make/O/N=0 wIndicesOfVariablesToAverage
	variable/G numVariablesToCalibrate = 0
	make/O/N=0 wIndicesOfVariablesToCalibrate
	variable/G numVariablesToMerelyRecord = 0
	make/O/N=0 wIndicesOfVariablesToMerelyRecord
	for(i=0;i<numOutputVariables;i+=1)
		if((cmpstr(wtOutputVariableSourceDataTypes[i], "str") == 0) || (cmpstr(wtOutputVariableSourceDataTypes[i], "stc") == 0)) // need to average over each cell fill period
			averageThis = 1
			numVariablesToAverage += 1
			redimension/N=(numVariablesToAverage) wIndicesOfVariablesToAverage
			wIndicesOfVariablesToAverage[numVariablesToAverage - 1] = i
		else
			averageThis = 0
		endif
		if(wOutputVariableCalibrateOrNots[i] == 1) // need to calibrate the cell-fill-period averages against ref gas(es)
			calibrateThis = 1
			numVariablesToCalibrate += 1
			redimension/N=(numVariablesToCalibrate) wIndicesOfVariablesToCalibrate
			wIndicesOfVariablesToCalibrate[numVariablesToCalibrate - 1] = i
		else
			calibrateThis = 0
		endif
		if((averageThis == 0) && (calibrateThis == 0))
			numVariablesToMerelyRecord += 1
			redimension/N=(numVariablesToMerelyRecord) wIndicesOfVariablesToMerelyRecord
			wIndicesOfVariablesToMerelyRecord[numVariablesToMerelyRecord - 1] = i
		endif
	endfor
	
//	variable/G numCalibratedOutputVariables = numVariablesToCalibrate + numVariablesToMerelyRecord
	
End

Function IRIS_UTILITY_CalibrateAllSampleVariablesViaRefs(sampleNum)
	variable sampleNum
	
	wave/T wtOutputVariableSourceDataNames = root:wtOutputVariableSourceDataNames
	wave wIndicesOfVariablesToCalibrate = root:wIndicesOfVariablesToCalibrate
	wave wOutputVariableRescaleFactors = root:wOutputVariableRescaleFactors
	wave wSampleIndices = root:wSampleIndices
	wave wRefIndices = root:wRefIndices
	
	NVAR numVariablesToCalibrate = root:numVariablesToCalibrate
	
	variable i, outputIndex, rescaleFactor
	
	string sDataName, sRefTrueName
	string sFullCalName, sSimpleCalName
	
	for(i=0;i<numVariablesToCalibrate;i+=1)
		outputIndex = wIndicesOfVariablesToCalibrate[i]
		sDataName = wtOutputVariableSourceDataNames[outputIndex]
		rescaleFactor = wOutputVariableRescaleFactors[outputIndex] // e.g. for conversion from ppb to ppm
		sRefTrueName = "wRefTrueValues_" + sDataName
		wave wRefTrueValuesName = $sRefTrueName
		IRIS_UTILITY_CalibrateSampleVariableViaRefs(sDataName, sampleNum, wRefIndices, wRefTrueValuesName, outputIndex, rescaleFactor)
		sFullCalName = "ECL_" + num2str(wSampleIndices[sampleNum]) + "_" + sDataName + "_Avg_Calibrated"
		sSimpleCalName = sDataName + "_cal" // this name drops the sample gas identification, and is only good for this iteration of the sampleNum for-loop
		duplicate/O root:ECL_WorkFolder_A:$sFullCalName, root:$sSimpleCalName
	endfor
	
End

Function IRIS_UTILITY_CalculateGasFillMeansForAllVariables()
	
	wave/T wtOutputVariableSourceDataNames = root:wtOutputVariableSourceDataNames
	wave/T wtOutputVariableSourceDataTypes = root:wtOutputVariableSourceDataTypes
	wave wOutputVariableRescaleFactors = root:wOutputVariableRescaleFactors
	wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
	wave wOutputVariableDiagnosticSlots = root:wOutputVariableDiagnosticSlots
	
	NVAR numGases = root:numGases
	NVAR numVariablesToAverage = root:numVariablesToAverage
	
	variable gasNum
	variable i, outputIndex, rescaleFactor, assignToDiagnosticOutputNumber
	
	string sTimeName, sDataName
	
	sTimeName = "str_source_rtime"
	for(gasNum=0;gasNum<numGases;gasNum+=1)
		IRIS_UTILITY_CalculateGasFillTimes(sTimeName, gasNum)
	endfor
	
	for(i=0;i<numVariablesToAverage;i+=1)
		outputIndex = wIndicesOfVariablesToAverage[i]
		sDataName = wtOutputVariableSourceDataNames[outputIndex]
		if(cmpstr(wtOutputVariableSourceDataTypes[outputIndex], "str") == 0)
			sTimeName = "str_source_rtime"
		else
			sTimeName = "stc_time"
		endif
		rescaleFactor = wOutputVariableRescaleFactors[outputIndex] // e.g. for conversion from ppb to ppm
		for(gasNum=0;gasNum<numGases;gasNum+=1)
			IRIS_UTILITY_CalculateGasFillMeansForOneVariable(sDataName, sTimeName, gasNum, outputIndex, rescaleFactor)
		endfor
		if(wOutputVariableDiagnosticSlots[outputIndex] > 0) // make this variable appear in one of the 3 plots in the diagnostic graph
			assignToDiagnosticOutputNumber = wOutputVariableDiagnosticSlots[outputIndex]
			IRIS_UTILITY_AssignHighFreqDiagnosticOutput(sDataName, sTimeName, outputIndex, assignToDiagnosticOutputNumber, rescaleFactor)
		endif
	endfor
	
End

Function IRIS_UTILITY_AssignAllSpecialOutputVariables(sampleNum)
	variable sampleNum
	
	wave/T wtOutputVariableSourceDataNames = root:wtOutputVariableSourceDataNames
	wave wOutputVariableRescaleFactors = root:wOutputVariableRescaleFactors
	wave wIndicesOfVariablesToMerelyRecord = root:wIndicesOfVariablesToMerelyRecord
	
	NVAR numVariablesToMerelyRecord = root:numVariablesToMerelyRecord
	
	variable i, outputIndex, rescaleFactor
	
	string sDataName
	
	for(i=0;i<numVariablesToMerelyRecord;i+=1)
		outputIndex = wIndicesOfVariablesToMerelyRecord[i]
		sDataName = wtOutputVariableSourceDataNames[outputIndex]
		rescaleFactor = wOutputVariableRescaleFactors[outputIndex] // e.g. for conversion from ppb to ppm			
		IRIS_UTILITY_AssignOneSpecialOutputVariable(sDataName, sampleNum, outputIndex, rescaleFactor)
	endfor
	
End
		
Function IRIS_UTILITY_AssignHighFreqDiagnosticOutput(sDataName, sTimeName, outputIndex, assignToDiagnosticOutputNumber, rescaleFactor)
	string sDataName, sTimeName
	variable outputIndex, assignToDiagnosticOutputNumber, rescaleFactor
	
	SVAR sSpecialDiagnosticOutput_name = root:sSpecialDiagnosticOutput_name
	SVAR sSpecialDiagnosticOutput_units = root:sSpecialDiagnosticOutput_units
	
	// assign high-frequency data to diagnostic output...
		
	string sDiagnosticOutput_name = "diagnosticOutput" + num2str(assignToDiagnosticOutputNumber) + "_name"
	string sDiagnosticOutput_units = "diagnosticOutput" + num2str(assignToDiagnosticOutputNumber) + "_units"
		
	string sSamplePointWave = "wDiagnosticOutput" + num2str(assignToDiagnosticOutputNumber) + "_SamplePoints"
	string sSampleTimeWave = "wDiagnosticOutput" + num2str(assignToDiagnosticOutputNumber) + "_SampleTime"
	string sDiagnosticOutput_highFreqData = "wDiagnosticOutput" + num2str(assignToDiagnosticOutputNumber) + "_highFreqData"
	string sDiagnosticOutput_highFreqTime = "wDiagnosticOutput" + num2str(assignToDiagnosticOutputNumber) + "_highFreqTime"
	string sDiagnosticOutput_avgData = "wDiagnosticOutput" + num2str(assignToDiagnosticOutputNumber) + "_avgData"
	string sDiagnosticOutput_stDevData = "wDiagnosticOutput" + num2str(assignToDiagnosticOutputNumber) + "_stDevData"
	string sDiagnosticOutput_avgTime = "wDiagnosticOutput" + num2str(assignToDiagnosticOutputNumber) + "_avgTime"
		
	SVAR diagnosticOutput_name = root:$sDiagnosticOutput_name
	SVAR diagnosticOutput_units = root:$sDiagnosticOutput_units
	wave/T wtOutputVariableNames = root:wtOutputVariableNames
	wave/T wtOutputVariableUnits = root:wtOutputVariableUnits
	if(numtype(outputIndex) == 0)
		diagnosticOutput_name = wtOutputVariableNames[outputIndex]
		diagnosticOutput_units = wtOutputVariableUnits[outputIndex]
	else
		diagnosticOutput_name = sSpecialDiagnosticOutput_name
		diagnosticOutput_units = sSpecialDiagnosticOutput_units
	endif
	
	Duplicate/O root:$sDataName, root:$sDiagnosticOutput_highFreqData
	Duplicate/O root:$sTimeName, root:$sDiagnosticOutput_highFreqTime
	
	wave highFreqData = root:$sDiagnosticOutput_highFreqData
	highFreqData = highFreqData*rescaleFactor
	
End

Function IRIS_UTILITY_CalculateGasFillTimes(sTimeName, gasNum)
	string sTimeName
	variable gasNum
	
	wave wOutputTime = root:wOutputTime
	wave wOutputTimeToGraph1 = root:wOutputTimeToGraph1
	wave wOutputTimeToGraph2 = root:wOutputTimeToGraph2
	wave wNumCompleteMeasurementsByGas = root:wNumCompleteMeasurementsByGas
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	NVAR numGases = root:numGases
	
	variable numOutputPoints = wNumCompleteMeasurementsByGas[gasNum]
	variable i
	
	string ECL_index
	if(gasNum < numSampleGases)
		ECL_index = IRIS_UTILITY_GetParamValueFromName("ECL Index for Sample " + num2str(gasNum + 1))
	else
		ECL_index = IRIS_UTILITY_GetParamValueFromName("ECL Index for Reference " + num2str(gasNum + 1 - numSampleGases))
	endif
	
	string sIRIStemp = "ECL_" + ECL_index + "_MidTime"
	if(exists("root:ECL_WorkFolder_A:" + sIRIStemp) == 1)
		wave gasTime = root:ECL_WorkFolder_A:$sIRIStemp
		for(i=0;i<numOutputPoints;i+=1)
			wOutputTime[gasNum][i] = gasTime[i]
		endfor	
		SetScale d 0,0,"dat", wOutputTime
		SetScale d 0,0,"dat", wOutputTimeToGraph1
		SetScale d 0,0,"dat", wOutputTimeToGraph2
	endif
	
End

Function IRIS_UTILITY_CalculateGasFillMeansForOneVariable(sDataName, sTimeName, gasNum, outputIndex, rescaleFactor)
	string sDataName, sTimeName
	variable gasNum, outputIndex, rescaleFactor
	
	string saveFolder = GetDataFolder(1);
	SetDataFolder root:
	
	string sDataPathFileString = "root:" + sDataName
	string sTimePathFileString = "root:" + sTimeName
	
	wave wNumCompleteMeasurementsByGas = root:wNumCompleteMeasurementsByGas
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	NVAR numGases = root:numGases
	
	string ECL_index
	if(gasNum < numSampleGases)
		ECL_index = IRIS_UTILITY_GetParamValueFromName("ECL Index for Sample " + num2str(gasNum + 1))
	else
		ECL_index = IRIS_UTILITY_GetParamValueFromName("ECL Index for Reference " + num2str(gasNum + 1 - numSampleGases))
	endif
	string sPreDelay = IRIS_UTILITY_GetParamValueFromName("Time to Ignore at Start of Measurement") // delay after fill before using data
	if(strlen(sPreDelay)==0)
		sPreDelay = "0"
	endif
	string sAlgorithmString = "TimeShift:" + sPreDelay + ",0"
	string sECLnameRootTemp = "ECL_" + ECL_index + "_" + sDataName
	
	NVAR minPointsForOutlierFiltering = root:minPointsForOutlierFiltering
	
	variable i, j
	string sIRIStemp
	
	// calculate the mean for each cell fill...
	IRIS_ECL_ApplyIndex2XY( str2num(ECL_index), $sTimePathFileString, $sDataPathFileString, sDataName, Diagnostics = 0, Algorithm = sAlgorithmString)
	
	// assign statistics to output variable waves...
	if(numtype(outputIndex) == 0)
		wave wOutputMeans = root:wOutputMeans
		wave wOutputStDevs = root:wOutputStDevs
		wave wOutputStErrs = root:wOutputStErrs
		wave wOutputTimeSeriesMatrix = root:wOutputTimeSeriesMatrix
		wave wOutputTimeSeriesErrorMatrix = root:wOutputTimeSeriesErrorMatrix
		wave wOutputTimeSeriesFilterMatrix = root:wOutputTimeSeriesFilterMatrix
		wave wOutputTime = root:wOutputTime
		wave wCheckForOutliers = root:wCheckForOutliers
		wave wOutlierThresholds = root:wOutlierThresholds
		wave wOutlierFilterGroups = root:wOutlierFilterGroups
		variable meanTemp, sdTemp
		variable highBound, lowBound
		variable currentPossibleOutlierIndex, currentPossibleOutlierValue
		variable dataFilterThreshold = str2num(IRIS_UTILITY_GetParamValueFromName("Data Filter Threshold"))
		variable numOutputPoints = wNumCompleteMeasurementsByGas[gasNum]
		sIRIStemp = sECLnameRootTemp + "_Avg"
		Duplicate/O root:ECL_WorkFolder_A:$sIRIStemp, IRIS_wTemp
		Redimension/N=(numOutputPoints) IRIS_wTemp
		IRIS_wTemp = IRIS_wTemp*rescaleFactor
		for(i=0;i<numOutputPoints;i+=1)
			wOutputTimeSeriesMatrix[gasNum][outputIndex][i] = IRIS_wTemp[i]
		endfor	
		sIRIStemp = sECLnameRootTemp + "_Serr"
		if(exists("root:ECL_WorkFolder_A:" + sIRIStemp) == 1)
			Duplicate/O root:ECL_WorkFolder_A:$sIRIStemp, IRIS_wTempSE
			Redimension/N=(numOutputPoints) IRIS_wTempSE
			IRIS_wTempSE = IRIS_wTempSE*rescaleFactor
			for(i=0;i<numOutputPoints;i+=1)
				wOutputTimeSeriesErrorMatrix[gasNum][outputIndex][i] = IRIS_wTempSE[i]
			endfor	
		else
			wOutputTimeSeriesErrorMatrix[gasNum][outputIndex][] = NaN
		endif
		if((wCheckForOutliers[outputIndex] == 1) && (numOutputPoints >= minPointsForOutlierFiltering)) // points to filter are flagged here, but the filtering is done in the analysis function, in case one variable needs to be filtered based on outliers in a different variable
			Duplicate/O IRIS_wTemp, wAbsDeviations, wFilterWave
			variable med = median(IRIS_wTemp)
			wAbsDeviations = abs(IRIS_wTemp - med)
			variable MAD = median(wAbsDeviations)
			NVAR MADsPerSD
			wFilterWave = (wAbsDeviations > wOutlierThresholds[outputIndex]*MADsPerSD*MAD)
			Extract/O/INDX wOutlierFilterGroups, variablesInThisFilterGroup, (wOutlierFilterGroups == wOutlierFilterGroups[outputIndex])
			for(i=0;i<numpnts(variablesInThisFilterGroup);i+=1)
				for(j=0;j<numOutputPoints;j+=1)
					wOutputTimeSeriesFilterMatrix[gasNum][variablesInThisFilterGroup[i]][j] = (wFilterWave[j] == 1) ? 1 : wOutputTimeSeriesFilterMatrix[gasNum][variablesInThisFilterGroup[i]][j]
				endfor
			endfor
			killwaves wAbsDeviations, wFilterWave
		endif
		meanTemp = mean(IRIS_wTemp)
		sdTemp = sqrt(variance(IRIS_wTemp))
		wOutputMeans[gasNum][outputIndex] = meanTemp
		wOutputStDevs[gasNum][outputIndex] = sdTemp
		wOutputStErrs[gasNum][outputIndex] = sdTemp/sqrt(numOutputPoints)
		killwaves IRIS_wTemp
	endif
	
	SetDataFolder $saveFolder
	
End

Function IRIS_UTILITY_CalCurveFunc(pw_local, yw_local, xw_local)
	wave pw_local, yw_local, xw_local
	
	// NOTE: To work with FuncFit, the form of this function must be:
	//	Function myFitFunc(pw, yw, xw)
	//		WAVE pw, yw, xw
	//		yw = <expression involving pw and xw>
	//	End
	
	// A global string named calEqnStr must have already been created outside of this function
	// and must consist of an equation that Igor can understand, with "xw_globalTemp" used for
	// the measured value, "yw_globalTemp" used for the true value, and "pw_globalTemp[0]",
	// "pw_globalTemp[1]", "pw_globalTemp[2]", etc used for the fit coefficients.
	// E.g. for a simple ratio fit, calEqnStr = "yw_globalTemp = pw_globalTemp[0]*xw_globalTemp"
	// E.g. for a linear fit, calEqnStr = "yw_globalTemp = pw_globalTemp[0] + pw_globalTemp[1]*xw_globalTemp"
	// E.g. for a 2nd order polynomial fit, calEqnStr = "yw_globalTemp = pw_globalTemp[0] + pw_globalTemp[1]*xw_globalTemp + pw_globalTemp[2]*xw_globalTemp^2"
	//
	// That equation string comes from IRIS_UTILITY_ValidateCalCurveEqn()
	
	NVAR globalExecuteFlag = root:globalExecuteFlag
	
	// Must duplicate input waves because the Execute operation is like typing calEqnStr into the command
	// line, without any knowledge of local wave names...
	duplicate/O pw_local, pw_globalTemp
	duplicate/O yw_local, yw_globalTemp
	duplicate/O xw_local, xw_globalTemp
	
	// Execute the assignment statement in calStrEqn as if it were typed into the command line...
	SVAR calEqnStr = root:calEqnStr
	Execute/Q/Z calEqnStr
	globalExecuteFlag = V_flag
	
	// All we need this function to tell us is the resulting value of yw...
	yw_local = yw_globalTemp
	
	// Clean up...
	killwaves pw_globalTemp
	killwaves yw_globalTemp
	killwaves xw_globalTemp
	
End

Function IRIS_UTILITY_CalibrateSampleVariableViaRefs(sDataName, sampleNum, wRefIndices, wTrueRefValuesOnStandardScale, outputIndex, rescaleFactor)
	string sDataName
	variable sampleNum
	wave wRefIndices
	wave wTrueRefValuesOnStandardScale
	variable outputIndex
	variable rescaleFactor
	
	// This structure might seem inefficient, as the ref cal curve will be recalculated again for each sample;
	// however, it is necessary because the ref values depend on the sample times to which they are interpolated.
	
	string saveFolder = GetDataFolder(1);
	SetDataFolder root:
	
	NVAR numRefGases = root:numRefGases
	
	string sSample_rawValue, sSample_time
	string sRef_rawValue, sRef_time, sRef_interpValue
	
	variable i, j
	variable meanTemp, sdTemp
	variable highBound, lowBound
	variable currentPossibleOutlierIndex, currentPossibleOutlierValue
	
	wave wNumCompleteMeasurementsByGas = root:wNumCompleteMeasurementsByGas
	
	NVAR minPointsForOutlierFiltering = root:minPointsForOutlierFiltering
	
	// Get sample values...
	
	string ECL_sampleIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Sample " + num2str(sampleNum+1))
	sprintf sSample_rawValue, "ECL_%s_%s_Avg", ECL_sampleIndex, sDataName
	wave/Z wSample_rawValue = root:ECL_WorkFolder_A:$sSample_rawValue
	if( WaveExists( wSample_rawValue ) != 1 )
		printf "In function IRIS_UTILITY_CalibrateSampleVariableViaRefs, wave %s not found, aborting\r", sSample_rawValue
		SetDataFolder $saveFolder
		return -1;
	endif
	sprintf sSample_time, "ECL_%s_MidTime", ECL_sampleIndex
	wave/Z wSample_time = root:ECL_WorkFolder_A:$sSample_time
	
	// Interpolate ref(s) onto sample time grid...
	
	string ECL_refIndex
	variable numSampleTimes = numpnts(wSample_time)
	Make/N=(numSampleTimes)/D/O wRefInterpTemp, wCalResultRelativeToStandardScale
	for(i=0;i<numRefGases;i+=1)
		ECL_refIndex = num2str(wRefIndices[i])
		sprintf sRef_rawValue, "ECL_%s_%s_Avg", ECL_refIndex, sDataName
		sprintf sRef_time, "ECL_%s_MidTime", ECL_refIndex
//		sRef_rawValue = "wRef" + num2str(i+1) + "_value"
//		sRef_time = "wRef" + num2str(i+1) + "_time"
		sRef_interpValue = "wRef" + num2str(i+1) + "_interpValue"
//		Duplicate/O $sRef_rawValue, wRef_rawValue
//		Duplicate/O $sRef_time, wRef_time		
		wave/Z wRef_rawValue = root:ECL_WorkFolder_A:$sRef_rawValue
		wave/Z wRef_time = root:ECL_WorkFolder_A:$sRef_time
		if( WaveExists( wRef_rawValue ) != 1 )
			printf "In function IRIS_UTILITY_CalibrateSampleVariableViaRefs, wave %s not found, aborting\r", sRef_rawValue
			SetDataFolder $saveFolder
			return -1;
		endif
		if(numpnts(wRef_time) < 4) // can't do a cubic spline with fewer than 4 points
			wRefInterpTemp = interp( wSample_time[p], wRef_time, wRef_rawValue )
		else
			interpolate2/E=2/T=2/I=3/X=wSample_time/Y=wRefInterpTemp wRef_time, wRef_rawValue // natural cubic spline interpolation
		endif
		Duplicate/O wRefInterpTemp, root:$sRef_interpValue
	endfor
	killwaves wRefInterpTemp
	
	// Calibrate using user-defined cal curve equation...
	
	// The right way to formulate the cal curve equation is to solve for the true value given the measured value,
	// i.e. with measured value on the x axis and true value on the y axis, and the right way to fit that cal curve
	// equation to the ref gas data is ordinary least squares (OLS), with all the measurement error presumed in the
	// true values (i.e. in the y dimension), because we don't actually care about the values of the coefficients of
	// the cal curve; we just care about finding the most likely true value for a given measured value.
	// FuncFit (and CurveFit) do OLS as long as the flag /ODR=0 (default) or /ODR=1.
	// Do NOT use orthogonal distance regression.
	wave wCalCoefs
	make/O/D/N=(numRefGases) wMeasuredRefValues
	make/O/D/N=1 wTrueSampleValue, wMeasuredSampleValue
	for(j=0;j<numSampleTimes;j+=1)
		for(i=0;i<numRefGases;i+=1)
			sRef_interpValue = "wRef" + num2str(i+1) + "_interpValue"
//			Duplicate/O $sRef_interpValue, wRef_interpValue // don't want to duplicate whole time series wave at each time step
			wave/Z wRef_interpValue = root:$sRef_interpValue
			wMeasuredRefValues[i] = wRef_interpValue[j]
		endfor
		FuncFit/Q IRIS_UTILITY_CalCurveFunc, wCalCoefs, wTrueRefValuesOnStandardScale /X=wMeasuredRefValues // fit the cal curve to the ref gas data
		wMeasuredSampleValue[0] = wSample_rawValue[j]
		IRIS_UTILITY_CalCurveFunc(wCalCoefs, wTrueSampleValue, wMeasuredSampleValue) // compute calibrated sample value using the fitted cal curve
		wCalResultRelativeToStandardScale[j] = wTrueSampleValue[0]
	endfor
	killwaves wTrueSampleValue, wMeasuredSampleValue
	
	string outputNameStr
	sprintf outputNameStr, "ECL_%s_%s_Avg_Calibrated", ECL_sampleIndex, sDataName
	duplicate/O wCalResultRelativeToStandardScale, root:ECL_WorkFolder_A:$outputNameStr
	
	// assign statistics to output variable waves...
	if(numtype(outputIndex) == 0)
		wave wOutputMeans = root:wOutputMeans
		wave wOutputStDevs = root:wOutputStDevs
		wave wOutputStErrs = root:wOutputStErrs
		wave wOutputTimeSeriesMatrix = root:wOutputTimeSeriesMatrix
		wave wOutputTimeSeriesErrorMatrix = root:wOutputTimeSeriesErrorMatrix
		wave wOutputTimeSeriesFilterMatrix = root:wOutputTimeSeriesFilterMatrix
		wave wOutputTime = root:wOutputTime
		wave wCheckForOutliers = root:wCheckForOutliers
		wave wOutlierThresholds = root:wOutlierThresholds
		wave wOutlierFilterGroups = root:wOutlierFilterGroups
		variable dataFilterThreshold = str2num(IRIS_UTILITY_GetParamValueFromName("Data Filter Threshold"))
		variable numOutputPoints = wNumCompleteMeasurementsByGas[sampleNum]
		for(i=0;i<numOutputPoints;i+=1)
			wOutputTimeSeriesMatrix[sampleNum][outputIndex][i] = wCalResultRelativeToStandardScale[i]
		endfor	
		Duplicate/O wCalResultRelativeToStandardScale, IRIS_wTemp
		redimension/N=(numOutputPoints) IRIS_wTemp
		if((wCheckForOutliers[outputIndex] == 1) && (numOutputPoints >= minPointsForOutlierFiltering)) // points to filter are flagged here, but the filtering is done in the analysis function, in case one variable needs to be filtered based on outliers in a different variable
			Duplicate/O IRIS_wTemp, wAbsDeviations, wFilterWave
			variable med = median(IRIS_wTemp)
			wAbsDeviations = abs(IRIS_wTemp - med)
			variable MAD = median(wAbsDeviations)
			NVAR MADsPerSD
			wFilterWave = (wAbsDeviations > wOutlierThresholds[outputIndex]*MADsPerSD*MAD)
			Extract/O/INDX wOutlierFilterGroups, variablesInThisFilterGroup, (wOutlierFilterGroups == wOutlierFilterGroups[outputIndex])
			for(i=0;i<numpnts(variablesInThisFilterGroup);i+=1)
				for(j=0;j<numOutputPoints;j+=1)
					wOutputTimeSeriesFilterMatrix[sampleNum][variablesInThisFilterGroup[i]][j] = (wFilterWave[j] == 1) ? 1 : wOutputTimeSeriesFilterMatrix[sampleNum][variablesInThisFilterGroup[i]][j]
				endfor
			endfor
			killwaves wAbsDeviations, wFilterWave
		endif
		meanTemp = mean(IRIS_wTemp)
		sdTemp = sqrt(variance(IRIS_wTemp))
		wOutputMeans[sampleNum][outputIndex] = meanTemp
		wOutputStDevs[sampleNum][outputIndex] = sdTemp
		wOutputStErrs[sampleNum][outputIndex] = sdTemp/sqrt(numOutputPoints)
		killwaves IRIS_wTemp
	endif
	killwaves wCalResultRelativeToStandardScale
	
	SetDataFolder $saveFolder
	
End

Function IRIS_UTILITY_ValidateCalCurveEqn()
	
	// A global string named calEqnStr_UI must have already been created outside of this function
	// and must consist of the right-hand side of an equation that Igor can understand, with "meas"
	// used for the measured value, and "c0", "c1", "c2", etc used for the fit coefficients. The
	// left-hand side of the equation (not included in the string) is always the true value.
	// E.g. for a simple ratio fit, calEqnStr_UI = "c0*meas"
	// E.g. for a linear fit, calEqnStr_UI = "c0 + c1*meas"
	// E.g. for a 2nd order polynomial fit, calEqnStr_UI = "c0 + c1*meas + c2*meas^2"
	
	NVAR calCurveIsValid = root:calCurveIsValid
	calCurveIsValid = 1
	
	NVAR numRefGases = root:numRefGases
	
	SVAR calEqnStr_UI = root:calEqnStr_UI // this is the string input by the user to represent the right-hand side of the cal curve equation
	SVAR calEqnStr = root:calEqnStr
	calEqnStr = calEqnStr_UI // this will be a modified string with the appropriate wave names inserted and the left-hand side added
	variable check = 0
	string replaceThisStr, withThisStr
	check = strsearch(calEqnStr, "meas", 0)
	if(check < 0)
		calCurveIsValid = 0
	endif
	check = strsearch(calEqnStr, "c0", 0)
	if(check < 0)
		calCurveIsValid = 0
	endif
	calEqnStr = ReplaceString("meas", calEqnStr, "xw_globalTemp")
	variable i = 0
	replaceThisStr = "c" + num2str(i)
	withThisStr = "pw_globalTemp[" + num2str(i) + "]"
	do
		calEqnStr = ReplaceString(replaceThisStr, calEqnStr, withThisStr)
		i += 1
		replaceThisStr = "c" + num2str(i)
		withThisStr = "pw_globalTemp[" + num2str(i) + "]"
		check = strsearch(calEqnStr, replaceThisStr, 0)
	while(check >= 0)
	variable numCalCurveCoefs = i
	if(numCalCurveCoefs > numRefGases)
		calCurveIsValid = 0 // need at least as many data points as coefficients in order to fit the cal curve
	endif
	calEqnStr = "yw_globalTemp = " + calEqnStr // add left-hand side
	make/O/D/N=(numCalCurveCoefs) wCalCoefs
	
	// Now do a simple test with dummy values to see if equation is really valid...
	NVAR globalExecuteFlag = root:globalExecuteFlag
	if(numRefGases > 0)
		make/O/D/N=(numRefGases) wDummyRefTrueValues, wDummyRefMeasuredValues
		IRIS_UTILITY_CalCurveFunc(wCalCoefs, wDummyRefTrueValues, wDummyRefMeasuredValues) // compute calibrated sample value using the fitted cal curve
		if(globalExecuteFlag != 0)
			calCurveIsValid = 0
		endif
		killwaves wDummyRefTrueValues, wDummyRefMeasuredValues
	else
		calCurveIsValid = 1
	endif
	
	if(WinType("IRISpanel") == 7)
		if(calCurveIsValid == 1)
			TitleBox calCurveValidityText_tabCal, win = IRISpanel, title = "VALID"
		else
			TitleBox calCurveValidityText_tabCal, win = IRISpanel, title = "INVALID"
		endif
	endif
	
End

Function IRIS_UTILITY_ValidateGasInfo()
	
	NVAR gasInfoIsValid = root:gasInfoIsValid
	gasInfoIsValid = 1
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	NVAR numGasParams = root:numGasParams
	wave/T wtParamValues = root:wtParamValues
	
	variable numSampleGasParams = numSampleGases // there's only an ID for each sample gas
	variable numRefGasParams = numGasParams - numSampleGasParams
	variable numGasParamsPerRef = numRefGasParams/numRefGases
	
	variable refNum, paramNum, thisParamNum, thisValue
	for(refNum=0;refNum<numRefGases;refNum+=1)
		for(paramNum=1;paramNum<numGasParamsPerRef;paramNum+=1) // skip first param for each ref gas, which is the ID
			thisParamNum = numSampleGasParams + refNum*numGasParamsPerRef + paramNum
			thisValue = str2num(wtParamValues[thisParamNum])
			gasInfoIsValid = (numtype(thisValue) == 0) ? gasInfoIsValid : 0 // if any ref gas non-ID value is not a number, then gas info is invalid
		endfor
	endfor
	
End

//Function IRIS_UTILITY_CalibrateSampleValuesAgainstTwoRefsWithWeightedSuperRatio(sDataName, sampleNum, ref1Num, ref2Num, ref1ValueOnStandardScale, ref2ValueOnStandardScale, outputIndex, rescaleFactor)
//	string sDataName
//	variable sampleNum, ref1Num, ref2Num, ref1ValueOnStandardScale, ref2ValueOnStandardScale, outputIndex, rescaleFactor
//	
//	string saveFolder = GetDataFolder(1);
//	SetDataFolder root:
//	
//	variable i, j
//	variable meanTemp, sdTemp
//	variable highBound, lowBound
//	variable currentPossibleOutlierIndex, currentPossibleOutlierValue
//	
//	wave wNumCompleteMeasurementsByGas = root:wNumCompleteMeasurementsByGas
//	
//	string ECL_sampleIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Sample " + num2str(sampleNum))
//	string ECL_ref1Index = IRIS_UTILITY_GetParamValueFromName("ECL Index for Reference " + num2str(ref1Num))
//	string ECL_ref2Index = IRIS_UTILITY_GetParamValueFromName("ECL Index for Reference " + num2str(ref2Num))
//	
//	NVAR minPointsForOutlierFiltering = root:minPointsForOutlierFiltering
//	
//	string outputNameStr
//	string valueSampleStr, valueRef1Str, valueRef2Str, timeStr
//	
//	// Calibrating sample against reference...
//	
//	sprintf valueSampleStr, "ECL_%s_%s_Avg", ECL_sampleIndex, sDataName
//	Wave/Z wValueSample = root:ECL_WorkFolder_A:$valueSampleStr
//	if( WaveExists( wValueSample ) != 1 )
//		printf "In function IRIS_UTILITY_CalibrateSampleValuesAgainstTwoRefs, wave %s not found, aborting\r", valueSampleStr
//		SetDataFolder $saveFolder
//		return -1;
//	endif
//	
//	sprintf valueRef1Str, "ECL_%s_%s_Avg", ECL_ref1Index, sDataName
//	Wave/Z wValueRef1 = root:ECL_WorkFolder_A:$valueRef1Str
//	if( WaveExists( wValueRef1 ) != 1 )
//		printf "In function IRIS_UTILITY_CalibrateSampleValuesAgainstTwoRefs, wave %s not found, aborting\r", valueRef1Str
//		SetDataFolder $saveFolder
//		return -1;
//	endif
//	
//	sprintf valueRef2Str, "ECL_%s_%s_Avg", ECL_ref2Index, sDataName
//	Wave/Z wValueRef2 = root:ECL_WorkFolder_A:$valueRef2Str
//	if( WaveExists( wValueRef2 ) != 1 )
//		printf "In function IRIS_UTILITY_CalibrateSampleValuesAgainstTwoRefs, wave %s not found, aborting\r", valueRef2Str
//		SetDataFolder $saveFolder
//		return -1;
//	endif
//	
//	sprintf timeStr, "ECL_%s_MidTime", ECL_sampleIndex
//	Wave/Z wSampleTime = root:ECL_WorkFolder_A:$timeStr
//	
//	sprintf timeStr, "ECL_%s_MidTime", ECL_ref1Index
//	Wave/Z wRef1Time = root:ECL_WorkFolder_A:$timeStr
//	
//	sprintf timeStr, "ECL_%s_MidTime", ECL_ref2Index
//	Wave/Z wRef2Time = root:ECL_WorkFolder_A:$timeStr
//	
//	Make/N=(numpnts(wSampleTime))/D/O wRef1InterpTemp, wRef2InterpTemp, wCalResultRelativeToStandardScale, wSlope, wIntercept
//	if(numpnts(wRef1Time) < 4) // can't do a cubic spline with fewer than 4 points
//		wRef1InterpTemp = interp( wSampleTime[p], wRef1Time, wValueRef1 )
//		wRef2InterpTemp = interp( wSampleTime[p], wRef2Time, wValueRef2 )
//	else
//		interpolate2/E=2/T=2/I=3/X=wSampleTime/Y=wRef1InterpTemp wRef1Time, wValueRef1 // natural cubic spline interpolation
//		interpolate2/E=2/T=2/I=3/X=wSampleTime/Y=wRef2InterpTemp wRef2Time, wValueRef2 // natural cubic spline interpolation
//	endif
//	
//	//	// Doing linear cal (y = m*x + b where measured is x, true is y)...
//	//	
//	//	wSlope = (ref2ValueOnStandardScale - ref1ValueOnStandardScale)/(wRef2InterpTemp - wRef1InterpTemp)
//	//	wIntercept = ref1ValueOnStandardScale - wSlope*wRef1InterpTemp
//	//	wCalResultRelativeToStandardScale = wSlope*wValueSample + wIntercept
//	//	wCalResultRelativeToStandardScale = wCalResultRelativeToStandardScale*rescaleFactor
//	//	
//	//	sprintf outputNameStr, "ECL_%s_%s_Avg_Calibrated", ECL_sampleIndex, sDataName
//	//	duplicate/O wCalResultRelativeToStandardScale, root:ECL_WorkFolder_A:$outputNameStr
//	
//	// super-ratio for ref1...
//	Make/N=(numpnts(wSampleTime))/D/O wCalResultRelativeToRef1, wCalResultRelativeToStandardScale_ref1
//	wCalResultRelativeToRef1 = 1000*(((wValueSample/1000) + 1)/((wRef1InterpTemp/1000) + 1) - 1)
//	wCalResultRelativeToStandardScale_ref1 = wCalResultRelativeToRef1 + ref1ValueOnStandardScale + 0.001*wCalResultRelativeToRef1*ref1ValueOnStandardScale
//	
//	// super-ratio for ref2...
//	Make/N=(numpnts(wSampleTime))/D/O wCalResultRelativeToRef2, wCalResultRelativeToStandardScale_ref2
//	wCalResultRelativeToRef2 = 1000*(((wValueSample/1000) + 1)/((wRef2InterpTemp/1000) + 1) - 1)
//	wCalResultRelativeToStandardScale_ref2 = wCalResultRelativeToRef2 + ref2ValueOnStandardScale + 0.001*wCalResultRelativeToRef2*ref2ValueOnStandardScale
//	
//	// weighted super-ratio...
//	variable ref1MR = str2num(IRIS_UTILITY_GetParamValueFromName("Reference 1: CO2 Mole Fraction")) // ppm
//	variable ref2MR = str2num(IRIS_UTILITY_GetParamValueFromName("Reference 2: CO2 Mole Fraction")) // ppm
//	string sMRdataName = "CO2_Avg"
//	Duplicate/O root:$sMRdataName, wSampleMR
//	wCalResultRelativeToStandardScale = wCalResultRelativeToStandardScale_ref1 + ((wSampleMR - ref1MR)/(ref2MR - ref1MR))*(wCalResultRelativeToStandardScale_ref2 - wCalResultRelativeToStandardScale_ref1)
//	
//	sprintf outputNameStr, "ECL_%s_%s_Avg_Calibrated", ECL_sampleIndex, sDataName
//	duplicate/O wCalResultRelativeToStandardScale, root:ECL_WorkFolder_A:$outputNameStr
//	
//	// Assigning statistics to output variable waves...
//	
//	if(numtype(outputIndex) == 0)
//		wave wOutputMeans = root:wOutputMeans
//		wave wOutputStDevs = root:wOutputStDevs
//		wave wOutputStErrs = root:wOutputStErrs
//		wave wOutputTimeSeriesMatrix = root:wOutputTimeSeriesMatrix
//		wave wOutputTimeSeriesErrorMatrix = root:wOutputTimeSeriesErrorMatrix
//		wave wOutputTimeSeriesFilterMatrix = root:wOutputTimeSeriesFilterMatrix
//		wave wOutputTime = root:wOutputTime
//		wave wCheckForOutliers = root:wCheckForOutliers
//		wave wOutlierThresholds = root:wOutlierThresholds
//		wave wOutlierFilterGroups = root:wOutlierFilterGroups
//		variable dataFilterThreshold = str2num(IRIS_UTILITY_GetParamValueFromName("Data Filter Threshold"))
//		variable numOutputPoints = wNumCompleteMeasurementsByGas[sampleNum-1]
//		for(i=0;i<numOutputPoints;i+=1)
//			wOutputTimeSeriesMatrix[sampleNum-1][outputIndex][i] = wCalResultRelativeToStandardScale[i]
//		endfor	
//		Duplicate/O wCalResultRelativeToStandardScale, IRIS_wTemp
//		redimension/N=(numOutputPoints) IRIS_wTemp
//		if((wCheckForOutliers[outputIndex] == 1) && (numOutputPoints >= minPointsForOutlierFiltering)) // points to filter are flagged here, but the filtering is done in the analysis function, in case one variable needs to be filtered based on outliers in a different variable
//			Duplicate/O IRIS_wTemp, wAbsDeviations, wFilterWave
//			variable med = median(IRIS_wTemp)
//			wAbsDeviations = abs(IRIS_wTemp - med)
//			variable MAD = median(wAbsDeviations)
//			NVAR MADsPerSD
//			wFilterWave = (wAbsDeviations > wOutlierThresholds[outputIndex]*MADsPerSD*MAD)
//			Extract/O/INDX wOutlierFilterGroups, variablesInThisFilterGroup, (wOutlierFilterGroups == wOutlierFilterGroups[outputIndex])
//			for(i=0;i<numpnts(variablesInThisFilterGroup);i+=1)
//				for(j=0;j<numOutputPoints;j+=1)
//					wOutputTimeSeriesFilterMatrix[sampleNum-1][variablesInThisFilterGroup[i]][j] = (wFilterWave[j] == 1) ? 1 : wOutputTimeSeriesFilterMatrix[sampleNum-1][variablesInThisFilterGroup[i]][j]
//				endfor
//			endfor
//			killwaves wAbsDeviations, wFilterWave
//		endif
//		meanTemp = mean(IRIS_wTemp)
//		sdTemp = sqrt(variance(IRIS_wTemp))
//		wOutputMeans[sampleNum-1][outputIndex] = meanTemp
//		wOutputStDevs[sampleNum-1][outputIndex] = sdTemp
//		wOutputStErrs[sampleNum-1][outputIndex] = sdTemp/sqrt(numOutputPoints)
//		killwaves IRIS_wTemp
//	endif
//	
//	killwaves wRef1InterpTemp, wRef2InterpTemp, wSlope, wIntercept, wCalResultRelativeToStandardScale
//	
//	SetDataFolder $saveFolder
//	
//End

Function IRIS_UTILITY_AssignOneSpecialOutputVariable(sSpecialOutputDataName, gasNum, outputIndex, rescaleFactor)
	string sSpecialOutputDataName
	variable gasNum, outputIndex, rescaleFactor
	
	string saveFolder = GetDataFolder(1);
	SetDataFolder root:
	
	wave wOutputMeans = root:wOutputMeans
	wave wOutputStDevs = root:wOutputStDevs
	wave wOutputStErrs = root:wOutputStErrs
	wave wOutputTimeSeriesMatrix = root:wOutputTimeSeriesMatrix
	wave wOutputTimeSeriesErrorMatrix = root:wOutputTimeSeriesErrorMatrix
	wave wOutputTimeSeriesFilterMatrix = root:wOutputTimeSeriesFilterMatrix
	
	wave wNumCompleteMeasurementsByGas = root:wNumCompleteMeasurementsByGas
	
	wave wOutputTime = root:wOutputTime
	
	wave wCheckForOutliers = root:wCheckForOutliers
	wave wOutlierThresholds = root:wOutlierThresholds
	wave wOutlierFilterGroups = root:wOutlierFilterGroups
	
	NVAR minPointsForOutlierFiltering = root:minPointsForOutlierFiltering
	
	variable i, j
	variable meanTemp, sdTemp
	variable highBound, lowBound
	variable currentPossibleOutlierIndex, currentPossibleOutlierValue
	
	variable dataFilterThreshold = str2num(IRIS_UTILITY_GetParamValueFromName("Data Filter Threshold")) // permil VSMOW
	variable numOutputPoints = wNumCompleteMeasurementsByGas[gasNum]
	
	Duplicate/O root:$sSpecialOutputDataName, IRIS_wTemp
	redimension/N=(numOutputPoints) IRIS_wTemp
	IRIS_wTemp = IRIS_wTemp*rescaleFactor
	for(i=0;i<numOutputPoints;i+=1)
		wOutputTimeSeriesMatrix[gasNum][outputIndex][i] = IRIS_wTemp[i]
		wOutputTimeSeriesErrorMatrix[gasNum][outputIndex][i] = NaN
	endfor	
	if((wCheckForOutliers[outputIndex] == 1) && (numOutputPoints >= minPointsForOutlierFiltering)) // points to filter are flagged here, but the filtering is done in the analysis function, in case one variable needs to be filtered based on outliers in a different variable
		Duplicate/O IRIS_wTemp, wAbsDeviations, wFilterWave
		variable med = median(IRIS_wTemp)
		wAbsDeviations = abs(IRIS_wTemp - med)
		variable MAD = median(wAbsDeviations)
		NVAR MADsPerSD
		wFilterWave = (wAbsDeviations > wOutlierThresholds[outputIndex]*MADsPerSD*MAD)
		Extract/O/INDX wOutlierFilterGroups, variablesInThisFilterGroup, (wOutlierFilterGroups == wOutlierFilterGroups[outputIndex])
		for(i=0;i<numpnts(variablesInThisFilterGroup);i+=1)
			for(j=0;j<numOutputPoints;j+=1)
				wOutputTimeSeriesFilterMatrix[gasNum][variablesInThisFilterGroup[i]][j] = (wFilterWave[j] == 1) ? 1 : wOutputTimeSeriesFilterMatrix[gasNum][variablesInThisFilterGroup[i]][j]
			endfor
		endfor
		killwaves wAbsDeviations, wFilterWave
	endif
	meanTemp = mean(IRIS_wTemp)
	sdTemp = sqrt(variance(IRIS_wTemp))
	wOutputMeans[gasNum][outputIndex] = meanTemp
	wOutputStDevs[gasNum][outputIndex] = sdTemp
	wOutputStErrs[gasNum][outputIndex] = sdTemp/sqrt(numOutputPoints)
	killwaves IRIS_wTemp
	
	SetDataFolder $saveFolder
	
End

Function IRIS_UTILITY_PopulateNumericOutput(numericDisplayNum)
	variable numericDisplayNum
	
	string saveFolder = getdatafolder(1)
	SetDataFolder root:
	
	wave wDisplayMeans = root:wDisplayMeans
	wave wDisplayStDevs = root:wDisplayStDevs
	wave wDisplayStErrs = root:wDisplayStErrs
	wave/T wtDisplayUnits = root:wtDisplayUnits
	wave/T wtDisplayFormat = root:wtDisplayFormat
	
	wave wOutputMeans = root:wOutputMeans
	wave wOutputStDevs = root:wOutputStDevs
	wave wOutputStErrs = root:wOutputStErrs
	wave/T wtOutputVariableUnits = root:wtOutputVariableUnits
	wave/T wtOutputVariableFormats = root:wtOutputVariableFormats
	
	string sOutput_gasID = "output" + num2str(numericDisplayNum) + "_gasID"
	NVAR output_gasID = root:$sOutput_gasID
	
	string sOutput_variableID = "output" + num2str(numericDisplayNum) + "_variableID"
	NVAR output_variableID = root:$sOutput_variableID
	
	wDisplayMeans[numericDisplayNum - 1] = wOutputMeans[output_gasID][output_variableID]
	wDisplayStDevs[numericDisplayNum - 1] = wOutputStDevs[output_gasID][output_variableID]
	wDisplayStErrs[numericDisplayNum - 1] = wOutputStErrs[output_gasID][output_variableID]
	wtDisplayUnits[numericDisplayNum - 1] = wtOutputVariableUnits[output_variableID]
	wtDisplayFormat[numericDisplayNum - 1] = wtOutputVariableFormats[output_variableID]
	
	SetDataFolder $saveFolder
	
End

Function IRIS_UTILITY_PopulateGraphOutput()
	
	string saveFolder = getdatafolder(1)
	SetDataFolder root:
	
	wave wOutputMeanToGraph1 = root:wOutputMeanToGraph1
	wave wOutputErrorToGraph1 = root:wOutputErrorToGraph1
	wave wOutputFilterToGraph1 = root:wOutputFilterToGraph1
	wave wOutputTimeToGraph1 = root:wOutputTimeToGraph1
	wave wOutputMeanToGraph2 = root:wOutputMeanToGraph2
	wave wOutputErrorToGraph2 = root:wOutputErrorToGraph2
	wave wOutputFilterToGraph2 = root:wOutputFilterToGraph2
	wave wOutputTimeToGraph2 = root:wOutputTimeToGraph2
	
	wave wOutputTime = root:wOutputTime
	wave wOutputTimeSeriesMatrix = root:wOutputTimeSeriesMatrix
	wave wOutputTimeSeriesErrorMatrix = root:wOutputTimeSeriesErrorMatrix
	wave wOutputTimeSeriesFilterMatrix = root:wOutputTimeSeriesFilterMatrix
	wave/T wtOutputVariableNames = root:wtOutputVariableNames
	wave/T wtOutputVariableUnits = root:wtOutputVariableUnits
	
	wave wNumCompleteMeasurementsByGas = root:wNumCompleteMeasurementsByGas
	
	NVAR gasToGraph1 = root:gasToGraph1
	NVAR variableToGraph1 = root:variableToGraph1
	NVAR gasToGraph2 = root:gasToGraph2
	NVAR variableToGraph2 = root:variableToGraph2
	NVAR showSecondPlotOnGraph = root:showSecondPlotOnGraph
	NVAR useSeparateGraphAxis = root:useSeparateGraphAxis
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	NVAR numGases = root:numGases
	
	// Output variable
	redimension/N=(wNumCompleteMeasurementsByGas[gasToGraph1]) wOutputMeanToGraph1, wOutputErrorToGraph1, wOutputFilterToGraph1, wOutputTimeToGraph1
	wOutputMeanToGraph1 = wOutputTimeSeriesMatrix[gasToGraph1][variableToGraph1][p]
	wOutputErrorToGraph1 = wOutputTimeSeriesErrorMatrix[gasToGraph1][variableToGraph1][p]
	wOutputFilterToGraph1 = (wOutputTimeSeriesFilterMatrix[gasToGraph1][variableToGraph1][p] == 0) ? 19 : 8
	wOutputTimeToGraph1 = wOutputTime[gasToGraph1][p]
	redimension/N=(wNumCompleteMeasurementsByGas[gasToGraph2]) wOutputMeanToGraph2, wOutputErrorToGraph2, wOutputFilterToGraph2, wOutputTimeToGraph2
	wOutputMeanToGraph2 = wOutputTimeSeriesMatrix[gasToGraph2][variableToGraph2][p]
	wOutputErrorToGraph2 = wOutputTimeSeriesErrorMatrix[gasToGraph2][variableToGraph2][p]
	wOutputFilterToGraph2 = (wOutputTimeSeriesFilterMatrix[gasToGraph2][variableToGraph2][p] == 0) ? 16 : 5
	wOutputTimeToGraph2 = wOutputTime[gasToGraph2][p]
	
	string sYaxisLabel
	DoWindow IRISpanel
	if(V_flag > 0)
		if(showSecondPlotOnGraph == 1)
			if(useSeparateGraphAxis == 1)
				sYaxisLabel = wtOutputVariableNames[variableToGraph1] + " (" + wtOutputVariableUnits[variableToGraph1] + ")"
				Label/W=IRISpanel#ResultGraph Left sYaxisLabel
				sYaxisLabel = wtOutputVariableNames[variableToGraph2] + " (" + wtOutputVariableUnits[variableToGraph2] + ")"
				Label/W=IRISpanel#ResultGraph Right sYaxisLabel
			else
				sYaxisLabel = "\K(16385,28398,65535)" + wtOutputVariableNames[variableToGraph1] + " (" + wtOutputVariableUnits[variableToGraph1] + ")\r\n\K(30583,30583,30583)" + wtOutputVariableNames[variableToGraph2] + " (" + wtOutputVariableUnits[variableToGraph2] + ")"
				Label/W=IRISpanel#ResultGraph Left sYaxisLabel
			endif
		else
			sYaxisLabel = wtOutputVariableNames[variableToGraph1] + " (" + wtOutputVariableUnits[variableToGraph1] + ")"
			Label/W=IRISpanel#ResultGraph Left sYaxisLabel
		endif
	endif
	
	SetDataFolder $saveFolder
	
End

Function IRIS_UTILITY_ScaleAndMaskDiagnosticGraph()
	
	wave str_source_rtime = root:str_source_rtime
	wave stc_time = root:stc_time
	wave stc_ECL_index = root:stc_ECL_index
	
	wave wDiagnosticMask_Ref = root:wDiagnosticMask_Ref
	wave wDiagnosticMask_Sample = root:wDiagnosticMask_Sample
	wave wDiagnosticMask_Time = root:wDiagnosticMask_Time
	wave wDiagnosticOutput1_highFreqData = root:wDiagnosticOutput1_highFreqData
	wave wDiagnosticOutput1_highFreqTime = root:wDiagnosticOutput1_highFreqTime
	wave wDiagnosticOutput2_highFreqData = root:wDiagnosticOutput2_highFreqData
	wave wDiagnosticOutput2_highFreqTime = root:wDiagnosticOutput2_highFreqTime
	wave wDiagnosticOutput3_highFreqData = root:wDiagnosticOutput3_highFreqData
	wave wDiagnosticOutput3_highFreqTime = root:wDiagnosticOutput3_highFreqTime
	wave wDiagnosticOutput1_avgData = root:wDiagnosticOutput1_avgData
	
	wave wOutputTime = root:wOutputTime
	
	wave wNumCompleteMeasurementsByGas = root:wNumCompleteMeasurementsByGas
	
	SVAR diagnosticOutput1_name = root:diagnosticOutput1_name
	SVAR diagnosticOutput1_units = root:diagnosticOutput1_units
	SVAR diagnosticOutput2_name = root:diagnosticOutput2_name
	SVAR diagnosticOutput2_units = root:diagnosticOutput2_units
	SVAR diagnosticOutput3_name = root:diagnosticOutput3_name
	SVAR diagnosticOutput3_units = root:diagnosticOutput3_units
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numGases = root:numGases
	
	string sPreDelay = IRIS_UTILITY_GetParamValueFromName("Time to Ignore at Start of Measurement") // delay after fill before using data
	if(strlen(sPreDelay)==0)
		sPreDelay = "0"
	endif
	variable preDelay = str2num(sPreDelay)
	
	variable i
	variable gasNum
	string sThisECLindex
	string sIRIStemp
	
	Duplicate/O stc_ECL_index, wDiagnosticMask_Sample, wDiagnosticMask_Ref
	Duplicate/O stc_time, wDiagnosticMask_Time
	wDiagnosticMask_Sample = 0
	wDiagnosticMask_Ref = 0
	
	make/O/D/N=0 wGasTextMarkerX
	make/O/T/N=0 wtGasTextMarkerString
	make/O/D/N=1 wWaveTemp
	make/O/T/N=1 wtWaveTemp
	
	variable firstStartTime = 1e36
	variable diagnostic1_highMark = -1e36
	variable diagnostic1_lowMark = 1e36
	variable diagnostic2_highMark = -1e36
	variable diagnostic2_lowMark = 1e36
	variable diagnostic3_highMark = -1e36
	variable diagnostic3_lowMark = 1e36
	for(gasNum=0;gasNum<numSampleGases;gasNum+=1)
		sThisECLindex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Sample " + num2str(gasNum+1))
		sIRIStemp = "ECL_" + sThisECLindex + "_StartTime"
		wave ECL_startTimes = root:ECL_Workfolder_A:$sIRIStemp
		sIRIStemp = "ECL_" + sThisECLindex + "_StopTime"
		wave ECL_stopTimes = root:ECL_Workfolder_A:$sIRIStemp
		//		sIRIStemp = "ECL_" + sThisECLindex + "_MidTime"
		//		wave ECL_midTimes = root:ECL_Workfolder_A:$sIRIStemp
		firstStartTime = min(firstStartTime, wavemin(ECL_startTimes))
		for(i=0;i<wNumCompleteMeasurementsByGas[gasNum];i+=1)
			wtWaveTemp[0] = "S" + num2str(gasNum+1)
			Concatenate/T/NP {wtWaveTemp}, wtGasTextMarkerString
			wWaveTemp[0] = (ECL_startTimes[i]+preDelay + ECL_stopTimes[i])/2 // wWaveTemp[0] = ECL_midTimes[i]
			Concatenate/NP {wWaveTemp}, wGasTextMarkerX
			wDiagnosticMask_Sample = ((wDiagnosticMask_Time >= ECL_startTimes[i]+preDelay) & (wDiagnosticMask_Time <= ECL_stopTimes[i])) ? 1 : wDiagnosticMask_Sample
			Extract/O wDiagnosticOutput1_highFreqData, wIRIStemp, ((wDiagnosticOutput1_highFreqTime >= ECL_startTimes[i]) & (wDiagnosticOutput1_highFreqTime <= ECL_stopTimes[i]))
			diagnostic1_highMark = max(diagnostic1_highMark, wavemax(wIRIStemp))
			diagnostic1_lowMark = min(diagnostic1_lowMark, wavemin(wIRIStemp))
			Extract/O wDiagnosticOutput2_highFreqData, wIRIStemp, ((wDiagnosticOutput2_highFreqTime >= ECL_startTimes[i]) & (wDiagnosticOutput2_highFreqTime <= ECL_stopTimes[i]))
			diagnostic2_highMark = max(diagnostic2_highMark, wavemax(wIRIStemp))
			diagnostic2_lowMark = min(diagnostic2_lowMark, wavemin(wIRIStemp))
			Extract/O wDiagnosticOutput3_highFreqData, wIRIStemp, ((wDiagnosticOutput3_highFreqTime >= ECL_startTimes[i]) & (wDiagnosticOutput3_highFreqTime <= ECL_stopTimes[i]))
			diagnostic3_highMark = max(diagnostic3_highMark, wavemax(wIRIStemp))
			diagnostic3_lowMark = min(diagnostic3_lowMark, wavemin(wIRIStemp))
		endfor
	endfor
	for(gasNum=numSampleGases;gasNum<numGases;gasNum+=1)
		sThisECLindex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Reference " + num2str(gasNum+1-numSampleGases))
		sIRIStemp = "ECL_" + sThisECLindex + "_StartTime"
		wave ECL_startTimes = root:ECL_Workfolder_A:$sIRIStemp
		sIRIStemp = "ECL_" + sThisECLindex + "_StopTime"
		wave ECL_stopTimes = root:ECL_Workfolder_A:$sIRIStemp
		//		sIRIStemp = "ECL_" + sThisECLindex + "_MidTime"
		//		wave ECL_midTimes = root:ECL_Workfolder_A:$sIRIStemp
		firstStartTime = min(firstStartTime, wavemin(ECL_startTimes))
		for(i=0;i<wNumCompleteMeasurementsByGas[gasNum];i+=1)
			wtWaveTemp[0] = "R" + num2str(gasNum+1-numSampleGases)
			Concatenate/T/NP {wtWaveTemp}, wtGasTextMarkerString
			wWaveTemp[0] = (ECL_startTimes[i]+preDelay + ECL_stopTimes[i])/2 // wWaveTemp[0] = ECL_midTimes[i]
			Concatenate/NP {wWaveTemp}, wGasTextMarkerX
			wDiagnosticMask_Ref = ((wDiagnosticMask_Time >= ECL_startTimes[i]+preDelay) & (wDiagnosticMask_Time <= ECL_stopTimes[i])) ? 1 : wDiagnosticMask_Ref
			Extract/O wDiagnosticOutput1_highFreqData, wIRIStemp, ((wDiagnosticOutput1_highFreqTime >= ECL_startTimes[i]) & (wDiagnosticOutput1_highFreqTime <= ECL_stopTimes[i]))
			diagnostic1_highMark = max(diagnostic1_highMark, wavemax(wIRIStemp))
			diagnostic1_lowMark = min(diagnostic1_lowMark, wavemin(wIRIStemp))
			Extract/O wDiagnosticOutput2_highFreqData, wIRIStemp, ((wDiagnosticOutput2_highFreqTime >= ECL_startTimes[i]) & (wDiagnosticOutput2_highFreqTime <= ECL_stopTimes[i]))
			diagnostic2_highMark = max(diagnostic2_highMark, wavemax(wIRIStemp))
			diagnostic2_lowMark = min(diagnostic2_lowMark, wavemin(wIRIStemp))
			Extract/O wDiagnosticOutput3_highFreqData, wIRIStemp, ((wDiagnosticOutput3_highFreqTime >= ECL_startTimes[i]) & (wDiagnosticOutput3_highFreqTime <= ECL_stopTimes[i]))
			diagnostic3_highMark = max(diagnostic3_highMark, wavemax(wIRIStemp))
			diagnostic3_lowMark = min(diagnostic3_lowMark, wavemin(wIRIStemp))
		endfor
	endfor
	killwaves wIRIStemp
	
	variable measurementDuration = str2num(IRIS_UTILITY_GetParamValueFromName("Measurement Duration")) // seconds
	variable/G diagnosticTime_scaleMin = firstStartTime - 1*measurementDuration
	variable/G diagnosticTime_scaleMax = diagnosticTime_scaleMin + 15*measurementDuration
	
	variable diagnostic1_span = diagnostic1_highMark - diagnostic1_lowMark
	variable diagnostic2_span = diagnostic2_highMark - diagnostic2_lowMark
	variable diagnostic3_span = diagnostic3_highMark - diagnostic3_lowMark
	
	variable/G diagnostic1_scaleMax = diagnostic1_highMark + diagnostic1_span
	variable/G diagnostic1_scaleMin = diagnostic1_lowMark - diagnostic1_span
	variable/G diagnostic2_scaleMax = diagnostic2_highMark + diagnostic2_span
	variable/G diagnostic2_scaleMin = diagnostic2_lowMark - diagnostic2_span
	variable/G diagnostic3_scaleMax = diagnostic3_highMark + diagnostic3_span
	variable/G diagnostic3_scaleMin = diagnostic3_lowMark - diagnostic3_span
	
	duplicate/O wGasTextMarkerX, wGasTextMarkerY
	wGasTextMarkerY[] = diagnostic1_highMark + diagnostic1_span/2
	
	DoWindow IRIS_DiagnosticGraph
	if(V_flag == 1)
		SetAxis/W=IRIS_DiagnosticGraph/A
		SetAxis/W=IRIS_DiagnosticGraph bottom diagnosticTime_scaleMin, diagnosticTime_scaleMax
		SetAxis/W=IRIS_DiagnosticGraph left diagnostic1_scaleMin, diagnostic1_scaleMax
		SetAxis/W=IRIS_DiagnosticGraph left2 diagnostic2_scaleMin, diagnostic2_scaleMax
		SetAxis/W=IRIS_DiagnosticGraph left3 diagnostic3_scaleMin, diagnostic3_scaleMax
		SetAxis/W=IRIS_DiagnosticGraph masks 0.4999, 0.5001		
		string sYaxisLabel = diagnosticOutput1_name + " (" + diagnosticOutput1_units + ")"
		Label/W=IRIS_DiagnosticGraph Left sYaxisLabel
		sYaxisLabel = diagnosticOutput2_name + " (" + diagnosticOutput2_units + ")"
		Label/W=IRIS_DiagnosticGraph Left2 sYaxisLabel
		sYaxisLabel = diagnosticOutput3_name + " (" + diagnosticOutput3_units + ")"
		Label/W=IRIS_DiagnosticGraph Left3 sYaxisLabel
	endif
	
	DoUpdate
	
End

Function IRIS_UTILITY_ProtoFunc()
	Print "IRIS_UTILITY_ProtoFunc called"
End

Function IRIS_UTILITY_ProtoActionFunc(sArgument)
	string sArgument
	Print "IRIS_UTILITY_ProtoActionFunc called"
End

Function [wave i626_local, wave i636_local, wave i628_local, wave i638_local] IRIS_UTILITY_ConvertFrom_d13C_d18O_D638(wave CO2_local, wave d13C_local, wave d18O_local, wave D638_local)
    
	variable R13_vpdb = 0.0111797
	variable R18_vsmow = 0.0020052
	variable R17_vsmow = 0.0003799
	
	//    // System of equations:
	//    (1) CO2 = (i626 + i636 + i628 + i638)*(1 + R17O)
	//    (2) R13C = (i636 + i638)/(i626 + i628)
	//    (3) R18O = (i628 + i638)/(2*(i626 + i636)) // factor of 2 is because there are 2 identical oxygen sites in CO2 (and so what we call i628 is really i628 + v826)
	//    (4) R638 = i638/i626
	//    where R638 = (D638 + 1)*R638_random
	//		      R13C = R13_vpdb*(d13C + 1)
	//		      R18O = R18_vsmow*(d18O + 1)
	//		      R17O = R17_vsmow*(d18O + 1)^0.516 (a good approximation; see Wehr et al 2013 Appendix A)
	//
	//		First need to convert D638 to R638, for which we need R638_random (i.e. R638 if there were no clumping).
	// 		So, if there were no clumping (following Wehr et al 2013 Appendix A)...
	//		First find the fractions of C that are 12C and 13C:
	//		f12 = 1/(1 + R13C)
	//		f13 = R13C*f12
	//		And the fractions of O that are 16O, 18O, and 17O:
	//		f16 = 1/(1 + R18O + R17O)
	//		f18 = R18O*f16
	//		f17 = R17O*f16 (f17 is not actually needed)
	//		Then calculate the isotopologue mixing ratios assuming no clumping:
	//		i626_random = CO2*f16*f12*f16
	//		i636_random = CO2*f16*f13*f16 (but we don't need this)
	//		i628_random = CO2*2*(f18*f12*f16) (but we don't need this)
	//		i638_random = CO2*2*(f18*f13*f16)
	//		Then R638_random = i638_random/i626_random
	//		Then R638 = (D638 + 1)*R638_random
	//
	//		Now we can solve the system of equations for the isotopologue mixing ratios...
	//
	//		Let a = CO2/(1 + R17O)
	//		Let b = a/(R13C + 1)
	//		Let c = 2*R18O/(1 + 2*R18O)
	//
	//		(1) => CO2/(1 + R17O) = (i626 + i636 + i628 + i638)
	//		    => i636 = a - (i626 + i628 + i638)   (5)
	//		in (2) => R13C = (a - (i626 + i628 + i638) + i638)/(i626 + i628)
	//		       => R13C = (a - (i626 + i628))/(i626 + i628)
	//		       => R13C = a/(i626 + i628) - 1
	//		       => (R13C + 1)*(i626 + i628) = CO2/(1 + R17O)
	//		       => (R13C + 1)*i626 + (R13C + 1)*i628 = CO2/(1 + R17O)
	//		       => (R13C + 1)*i626 = CO2/(1 + R17O) - (R13C + 1)*i628
	//		       => i626 = (CO2/(1 + R17O) - (R13C + 1)*i628)/(R13C + 1)
	//		       => i626 = a/(R13C + 1) - i628
	//				 => i626 = b - i628   (6)
	//		so (3) => R18O = (i628 + i638)/(2*(b - i628 + a - (i626 + i628 + i638)))
	//		       => R18O = (i628 + i638)/(2*(b - i628 + a - (b - i628 + i628 + i638)))
	//		       => R18O = (i628 + i638)/(2*(b - i628 + a - (b + i638)))
	//		       => R18O = (i628 + i638)/(2*(b - i628 + a - b - i638))
	//		       => R18O = (i628 + i638)/(2*(b + a - b - (i628 + i638)))
	//		       => R18O = (i628 + i638)/(2*(a - (i628 + i638)))
	//		       => (i628 + i638) = 2*R18O*(a - (i628 + i638))
	//		       => (i628 + i638) = 2*R18O*a - 2*R18O*(i628 + i638)
	//		       => (i628 + i638) + 2*R18O*(i628 + i638) = 2*R18O*a
	//		       => (i628 + i638)*(1 + 2*R18O) = 2*R18O*a
	//		       => (i628 + i638) = a*c
	//		       => i638 = a*c - i628   (7)
	//		so (4) => R638 = (a*c - i628)/(b - i628)
	//		       => R638*(b - i628) = a*c - i628
	//		       => R638*b - R638*i628 = a*c - i628
	//		       => R638*b - R638*i628 + i628 = a*c
	//		       => i628*(1 - R638) = a*c - R638*b
	//		       => i628 = (a*c - R638*b)/(1 - R638)   (8)
	//
	// So solve (8) for i628, then put it into (7) to get i638, and into (6) to get i626.
	// Then put i626, i628, and i638 into (5) to get i636.
   
   make/O/D/N=(numpnts(CO2_local)) R13C_temp, R18O_temp, R17O_temp
   make/O/D/N=(numpnts(CO2_local)) f12_temp, f13_temp, f16_temp, f18_temp
   make/O/D/N=(numpnts(CO2_local)) i626_random_temp, i638_random_temp, R638_random_temp, R638_temp
   make/O/D/N=(numpnts(CO2_local)) a_temp, b_temp, c_temp
   
	R13C_temp = R13_vpdb*(d13C_local/1000 + 1)
	R18O_temp = R18_vsmow*(d18O_local/1000 + 1)
	R17O_temp = R17_vsmow*(R18O_temp/R18_vsmow)^0.516 // (a good approximation; see Wehr et al 2013 Appendix A)
	
	f12_temp = 1/(1 + R13C_temp)
	f13_temp = R13C_temp*f12_temp
	f16_temp = 1/(1 + R18O_temp + R17O_temp)
	f18_temp = R18O_temp*f16_temp
	i626_random_temp = CO2_local*f16_temp*f12_temp*f16_temp
	i638_random_temp = CO2_local*2*(f18_temp*f13_temp*f16_temp) // factor of 2 is because there are 2 identical oxygen sites in CO2 (and so what we call i628 is really i628 + v826)
	R638_random_temp = i638_random_temp/i626_random_temp
	R638_temp = (D638_local + 1)*R638_random_temp
	
	a_temp = CO2_local/(1 + R17O_temp)
	b_temp = a_temp/(R13C_temp + 1)
	c_temp = 2*R18O_temp/(1 + 2*R18O_temp)
	
	i628_local = (a_temp*c_temp - R638_temp*b_temp)/(1 - R638_temp)
	i638_local = a_temp*c_temp - i628_local
	i626_local = b_temp - i628_local
	i636_local = a_temp - (i626_local + i628_local + i638_local)
	
	killwaves R13C_temp, R18O_temp, R17O_temp
   killwaves f12_temp, f13_temp, f16_temp, f18_temp
   killwaves i626_random_temp, i638_random_temp, R638_random_temp, R638_temp
   killwaves a_temp, b_temp, c_temp
   
End

Function [wave CO2_local, wave d13C_local, wave d18O_local, wave D638_local] IRIS_UTILITY_ConvertTo_d13C_d18O_D638(wave i626_local, wave i636_local, wave i628_local, wave i638_local)
   
	variable R13_vpdb = 0.0111797
	variable R18_vsmow = 0.0020052
	variable R17_vsmow = 0.0003799
	
	make/O/D/N=(numpnts(i626_local)) R13C_temp, R18O_temp, R17O_temp
	make/O/D/N=(numpnts(i626_local)) f12_temp, f13_temp, f16_temp, f18_temp
	make/O/D/N=(numpnts(i626_local)) R638_random_temp
	
	R13C_temp = (i636_local + i638_local)/(i626_local + i628_local)
	R18O_temp = (i628_local + i638_local)/(2*(i626_local + i636_local)) // factor of 2 is because there are 2 identical oxygen sites in CO2 (and so what we call i628 is really i628 + v826)
	R17O_temp = R17_vsmow*(R18O_temp/R18_vsmow)^0.516 // (a good approximation; see Wehr et al 2013 Appendix A)
	
	d13C_local = 1000*((R13C_temp/R13_vpdb) - 1)
	d18O_local = 1000*((R18O_temp/R18_vsmow) - 1)
		
	// All possible stable isotopologues written such that sites matter: (626 + 628 + 826 + 627 + 726 + 828 + 827 + 728 + 727)*(1 + 636/626)
	// All possible stable isotopologues written such that sites do not matter (i.e. such that 628 = 628 + 826 and 627 = 627 + 726 and 827 = 827 + 728): (626 + 628 + 627 + 828 + 827 + 727)*(1 + 636/626)
	// The following equation omits only 828 + 727 + 838 + 737:
	CO2_local = i626_local*(1 + 2*R17O_temp)*(1 + R13C_temp) + i628_local*(1 + R17O_temp) + i638_local*(1 + R17O_temp) // factor of 2 is because there are 2 identical oxygen sites in CO2 (and so what we call i628 is really i628 + v826)
   	
	//		Now need to convert R638 to D638, for which we need R638_random (i.e. R638 if there were no clumping).
	// 		So, if there were no clumping (following Wehr et al 2013 Appendix A)...
	//		First find the fractions of C that are 12C and 13C:
	//		f12 = 1/(1 + R13C)
	//		f13 = R13C*f12
	//		And the fractions of O that are 16O, 18O, and 17O:
	//		f16 = 1/(1 + R18O + R17O)
	//		f18 = R18O*f16
	//		f17 = R17O*f16 (f17 is not actually needed)
	//		Then calculate the isotopologue mixing ratios assuming no clumping:
	//		i626_random = CO2*f16*f12*f16
	//		i636_random = CO2*f16*f13*f16 (but we don't need this)
	//		i628_random = CO2*2*(f18*f12*f16) (but we don't need this)
	//		i638_random = CO2*2*(f18*f13*f16)
	//		Then R638_random = i638_random/i626_random
	//		=> R638_random = 2*(f18*f13)/(f16*f12)
	//		Then wD638 = vR638/vR638_random - 1
   
	f12_temp = 1/(1 + R13C_temp)
	f13_temp = R13C_temp*f12_temp
	f16_temp = 1/(1 + R18O_temp + R17O_temp)
	f18_temp = R18O_temp*f16_temp
	R638_random_temp = 2*(f18_temp*f13_temp)/(f16_temp*f12_temp)
	
	D638_local = 1000*((i638_local/i626_local)/R638_random_temp - 1)
	
	killwaves R13C_temp, R18O_temp, R17O_temp
	killwaves f12_temp, f13_temp, f16_temp, f18_temp
	killwaves R638_random_temp
   
End

Function [wave i626_local, wave i636_local, wave i628_local] IRIS_UTILITY_ConvertFrom_d13C_d18O(wave CO2_local, wave d13C_local, wave d18O_local)
    
	// The computed isotopologue mole fractions will all be in error by the same small factor
   // due to the assumed value of d17O in the calculation. That error will exactly cancel out
   // when converting back to deltas. All minor isotopologues are implicitly accounted for
   // via the relative abundance factors f12, f13, f16, f18, f17.
   
	variable R13_vpdb = 0.0111797
	variable R18_vsmow = 0.0020052
	variable R17_vsmow = 0.0003799
	
	//		Since we have no measurement of 638, we assume there is no clumping (following Wehr et al 2013 Appendix A)...
	//		First find the fractions of C that are 12C and 13C:
	//		f12 = 1/(1 + R13C)
	//		f13 = R13C*f12
	//		And the fractions of O that are 16O, 18O, and 17O:
	//		f16 = 1/(1 + R18O + R17O)
	//		f18 = R18O*f16
	//		Then calculate the isotopologue mixing ratios assuming no clumping:
	//		i626_random = CO2*f16*f12*f16
	//		i636_random = CO2*f16*f13*f16
	//		i628_random = CO2*2*(f18*f12*f16)
   
   make/O/D/N=(numpnts(CO2_local)) R13C_temp, R18O_temp, R17O_temp
   make/O/D/N=(numpnts(CO2_local)) f12_temp, f13_temp, f16_temp, f18_temp
   
	R13C_temp = R13_vpdb*(d13C_local/1000 + 1)
	R18O_temp = R18_vsmow*(d18O_local/1000 + 1)
	R17O_temp = R17_vsmow*(R18O_temp/R18_vsmow)^0.516 // (a good approximation; see Wehr et al 2013 Appendix A)
	f12_temp = 1/(1 + R13C_temp)
	f13_temp = R13C_temp*f12_temp
	f16_temp = 1/(1 + R18O_temp + R17O_temp)
	f18_temp = R18O_temp*f16_temp
	
	i626_local = CO2_local*f16_temp*f12_temp*f16_temp
	i636_local = CO2_local*f16_temp*f13_temp*f16_temp
	i628_local = CO2_local*2*(f18_temp*f12_temp*f16_temp) // factor of 2 is because there are 2 identical oxygen sites in CO2 (and so what we call i628 is really i628 + v826)
	
	killwaves R13C_temp, R18O_temp, R17O_temp
	killwaves f12_temp, f13_temp, f16_temp, f18_temp
	
End

Function [wave CO2_local, wave d13C_local, wave d18O_local] IRIS_UTILITY_ConvertTo_d13C_d18O(wave i626_local, wave i636_local, wave i628_local)
   
	// The omission of unmeasured isotopologues from the total CO2 mole fraction calculation here
	// will cause only a very small error due to the omission of the minor isotopologues 638, 828,
	// 728, 727, 838, 738, and 737 (which were implicitly accounted for in the conversion from
	// deltas to isotopologues, assuming no clumping).
		
   variable R13_vpdb = 0.0111797
	variable R18_vsmow = 0.0020052
	variable R17_vsmow = 0.0003799
	
	make/O/D/N=(numpnts(i626_local)) R13C_temp, R18O_temp, R17O_temp
	
	R13C_temp = i636_local/i626_local
	R18O_temp = i628_local/(2*i626_local) // factor of 2 is because there are 2 identical oxygen sites in CO2 (and so what we call i628 is really i628 + v826)
	R17O_temp = R17_vsmow*(R18O_temp/R18_vsmow)^0.516 // (a good approximation; see Wehr et al 2013 Appendix A)
	
	d13C_local = 1000*((R13C_temp/R13_vpdb) - 1)
	d18O_local = 1000*((R18O_temp/R18_vsmow) - 1)
	
	// All possible stable isotopologues written such that sites matter: (626 + 628 + 826 + 627 + 726 + 828 + 827 + 728 + 727)*(1 + 636/626)
	// All possible stable isotopologues written such that sites do not matter (i.e. such that 628 = 628 + 826 and 627 = 627 + 726 and 827 = 827 + 728): (626 + 628 + 627 + 828 + 827 + 727)*(1 + 636/626)
	// The following equation omits only 828 + 727 + 838 + 737:
	CO2_local = i626_local*(1 + 2*R17O_temp)*(1 + R13C_temp) + i628_local*(1 + R17O_temp)*(1 + R13C_temp) // factor of 2 is because there are 2 identical oxygen sites in CO2 (and so what we call i628 is really i628 + v826)
   	
	killwaves R13C_temp, R18O_temp
   
End

Function [wave i626_local, wave i636_local, wave i628_local, wave i627_local] IRIS_UTILITY_ConvertFrom_d13C_d18O_d17O(wave CO2_local, wave d13C_local, wave d18O_local, wave d17O_local)
    
	// The computed isotopologue mole fractions should be exact except for the assumption of no
	// clumping, as all minor isotopologues are implicitly accounted for via the relative abundance
	// factors f12, f13, f16, f18, f17.
   
	variable R13_vpdb = 0.0111797
	variable R18_vsmow = 0.0020052
	variable R17_vsmow = 0.0003799
	
	//		Since we have no measurement of 638, we assume there is no clumping (following Wehr et al 2013 Appendix A)...
	//		First find the fractions of C that are 12C and 13C:
	//		f12 = 1/(1 + R13C)
	//		f13 = R13C*f12
	//		And the fractions of O that are 16O, 18O, and 17O:
	//		f16 = 1/(1 + R18O + R17O)
	//		f18 = R18O*f16
	//		f17 = R17O*f16
	//		Then calculate the isotopologue mixing ratios assuming no clumping:
	//		i626_random = CO2*f16*f12*f16
	//		i636_random = CO2*f16*f13*f16
	//		i628_random = CO2*2*(f18*f12*f16)
	//		i627_random = CO2*2*(f17*f12*f16)
   
   make/O/D/N=(numpnts(CO2_local)) R13C_temp, R18O_temp, R17O_temp
	make/O/D/N=(numpnts(CO2_local)) f12_temp, f13_temp, f16_temp, f17_temp, f18_temp
	
	R13C_temp = R13_vpdb*(d13C_local/1000 + 1)
	R18O_temp = R18_vsmow*(d18O_local/1000 + 1)
	R17O_temp = R17_vsmow*(d17O_local/1000 + 1)
	f12_temp = 1/(1 + R13C_temp)
	f13_temp = R13C_temp*f12_temp
	f16_temp = 1/(1 + R18O_temp + R17O_temp)
	f18_temp = R18O_temp*f16_temp
	f17_temp = R17O_temp*f16_temp
	
	i626_local = CO2_local*f16_temp*f12_temp*f16_temp
	i636_local = CO2_local*f16_temp*f13_temp*f16_temp
	i628_local = CO2_local*2*(f18_temp*f12_temp*f16_temp) // factor of 2 is because there are 2 identical oxygen sites in CO2 (and so what we call i628 is really i628 + v826)
	i627_local = CO2_local*2*(f17_temp*f12_temp*f16_temp) // factor of 2 is because there are 2 identical oxygen sites in CO2 (and so what we call i627 is really i627 + v726)
	
	killwaves R13C_temp, R18O_temp, R17O_temp
	killwaves f12_temp, f13_temp, f16_temp, f17_temp, f18_temp
	
End

Function [wave CO2_local, wave d13C_local, wave d18O_local, wave d17O_local] IRIS_UTILITY_ConvertTo_d13C_d18O_d17O(wave i626_local, wave i636_local, wave i628_local, wave i627_local)
   
	// The omission of unmeasured isotopologues from the total CO2 mole fraction calculation here
	// will cause only a very small error due to the omission of the minor isotopologues 638, 828,
	// 728, 727, 838, 738, and 737 (which were implicitly accounted for in the conversion from
	// deltas to isotopologues, assuming no clumping).
		
   variable R13_vpdb = 0.0111797
	variable R18_vsmow = 0.0020052
	variable R17_vsmow = 0.0003799
	
	make/O/D/N=(numpnts(i626_local)) R13C_temp, R18O_temp, R17O_temp
	
	R13C_temp = i636_local/i626_local
	R18O_temp = i628_local/(2*i626_local) // factor of 2 is because there are 2 identical oxygen sites in CO2 (and so what we call i628 is really i628 + v826)
	R17O_temp = i627_local/(2*i626_local) // factor of 2 is because there are 2 identical oxygen sites in CO2 (and so what we call i627 is really i627 + v726)
	
	d13C_local = 1000*((R13C_temp/R13_vpdb) - 1)
	d18O_local = 1000*((R18O_temp/R18_vsmow) - 1)
	d17O_local = 1000*((R17O_temp/R17_vsmow) - 1)
	
	// All possible stable isotopologues written such that sites matter: (626 + 628 + 826 + 627 + 726 + 828 + 827 + 728 + 727)*(1 + 636/626)
	// All possible stable isotopologues written such that sites do not matter (i.e. such that 628 = 628 + 826 and 627 = 627 + 726 and 827 = 827 + 728): (626 + 628 + 627 + 828 + 827 + 727)*(1 + 636/626)
	// The following equation omits only 828 + 727 + 838 + 737:
	CO2_local = i626_local*(1 + 2*R17O_temp)*(1 + R13C_temp) + i628_local*(1 + R17O_temp)*(1 + R13C_temp) // factor of 2 is because there are 2 identical oxygen sites in CO2 (and so what we call i628 is really i628 + v826)
   	
	killwaves R13C_temp, R18O_temp, R17O_temp
   
End

Function [wave i626_local, wave i628_local, wave i627_local] IRIS_UTILITY_ConvertFrom_d18O_d17O(wave CO2_local, wave d18O_local, wave d17O_local)
    
	// The computed isotopologue mole fractions will all be in error by the same small factor
   // due to the assumed value of d13C = 0 in the calculation. That error will exactly cancel out
   // when converting back to deltas.
   
	variable R13_vpdb = 0.0111797
	variable R18_vsmow = 0.0020052
	variable R17_vsmow = 0.0003799
	
	//		Since we have no measurement of 638, we assume there is no clumping (following Wehr et al 2013 Appendix A)...
	//		First find the fractions of O that are 16O, 18O, and 17O:
	//		f16 = 1/(1 + R18O + R17O)
	//		f18 = R18O*f16
	//		f17 = R17O*f16
	//		Then calculate the isotopologue mixing ratios assuming no clumping:
	//		626_random = CO2*f16*f12*f16
	//		628_random = CO2*2*(f18*f12*f16)
	//		627_random = CO2*2*(f17*f12*f16)
   
   make/O/D/N=(numpnts(CO2_local)) R13C_temp, R18O_temp, R17O_temp
   make/O/D/N=(numpnts(CO2_local)) f12_temp, f16_temp, f17_temp, f18_temp
   
   R13C_temp = R13_vpdb // assume d13C = 0 (an approximation that only impacts the isotopologue mixing ratios, but cancels out in the final calibrated deltas and total CO2 as long as the code uses this value consistently)
	R18O_temp = R18_vsmow*(d18O_local/1000 + 1)
	R17O_temp = R17_vsmow*(d17O_local/1000 + 1)
	f12_temp = 1/(1 + R13C_temp)
	f16_temp = 1/(1 + R18O_temp + R17O_temp)
	f18_temp = R18O_temp*f16_temp
	f17_temp = R17O_temp*f16_temp
	
	i626_local = CO2_local*f16_temp*f12_temp*f16_temp
	i628_local = CO2_local*2*(f18_temp*f12_temp*f16_temp) // factor of 2 is because there are 2 identical oxygen sites in CO2 (and so what we call i628 is really i628 + v826)
	i627_local = CO2_local*2*(f17_temp*f12_temp*f16_temp) // factor of 2 is because there are 2 identical oxygen sites in CO2 (and so what we call i627 is really i627 + v726)
	
	killwaves R13C_temp, R18O_temp, R17O_temp
	killwaves f12_temp, f16_temp, f17_temp, f18_temp
	    
End

Function [wave CO2_local, wave d18O_local, wave d17O_local] IRIS_UTILITY_ConvertTo_d18O_d17O(wave i626_local, wave i628_local, wave i627_local)
   
	// The omission of unmeasured isotopologues from the total CO2 mole fraction calculation here
	// will cause only a very small error due to the omission of the minor isotopologues 638, 828,
	// 728, 727, 838, 738, and 737 (which are implicitly accounted for in the conversion from
	// deltas to isotopologues, assuming no clumping). The assumed value of d13C cancels out and
	// causes no error.
	
	variable R13_vpdb = 0.0111797
	variable R18_vsmow = 0.0020052
	variable R17_vsmow = 0.0003799
	
	make/O/D/N=(numpnts(i626_local)) R13C_temp, R18O_temp, R17O_temp
	
	R13C_temp = R13_vpdb // assume d13C = 0 (an approximation that only impacts the isotopologue mixing ratios, but cancels out in the final calibrated deltas and total CO2 as long as the code uses this value consistently)
	R18O_temp = i628_local/(2*i626_local) // factor of 2 is because there are 2 identical oxygen sites in CO2 (and so what we call i628 is really i628 + v826)
	R17O_temp = i627_local/(2*i626_local) // factor of 2 is because there are 2 identical oxygen sites in CO2 (and so what we call i627 is really i627 + v726)
	
	d18O_local = 1000*((R18O_temp/R18_vsmow) - 1)
	d17O_local = 1000*((R17O_temp/R17_vsmow) - 1)
	
	// All possible stable isotopologues written such that sites matter: (626 + 628 + 826 + 627 + 726 + 828 + 827 + 728 + 727)*(1 + 636/626)
	// All possible stable isotopologues written such that sites do not matter (i.e. such that 628 = 628 + 826 and 627 = 627 + 726 and 827 = 827 + 728): (626 + 628 + 627 + 828 + 827 + 727)*(1 + 636/626)
	// The following equation omits only 828 + 727 + 838 + 737:
	CO2_local = i626_local*(1 + 2*R17O_temp)*(1 + R13C_temp) + i628_local*(1 + R17O_temp)*(1 + R13C_temp) // factor of 2 is because there are 2 identical oxygen sites in CO2 (and so what we call i628 is really i628 + v826)
   	
	killwaves R13C_temp, R18O_temp, R17O_temp
   
End

Function [wave i626_local, wave i636_local] IRIS_UTILITY_ConvertFrom_d13C(wave CO2_local, wave d13C_local)
   
   // The computed isotopologue mole fractions will all be inflated by the same small factor
   // due to the omission of unmeasured isotopologues from the calculation (i.e. the assumption
   // that O16 is the only oxygen isotope). That error will exactly cancel out when converting
   // back to deltas.
   
	variable R13_vpdb = 0.0111797
	
	//		Since we have no measurement of 638, we assume there is no clumping (following Wehr et al 2013 Appendix A)...
	//		First find the fractions of C that are 12C and 13C:
	//		f12 = 1/(1 + R13C)
	//		f13 = R13C*f12
	//		Then calculate the isotopologue mixing ratios assuming no clumping:
	//		i626_random = CO2*f12 (assuming f16 = 1)
	//		i636_random = CO2*f13 (assuming f16 = 1)
   
   make/O/D/N=(numpnts(CO2_local)) R13C_temp
   make/O/D/N=(numpnts(CO2_local)) f12_temp, f13_temp
   
	// All possible stable isotopologues written such that sites matter: (626 + 628 + 826 + 627 + 726 + 828 + 827 + 728 + 727)*(1 + 636/626)
	// All possible stable isotopologues written such that sites do not matter (i.e. such that 628 = 628 + 826 and 627 = 627 + 726 and 827 = 827 + 728): (626 + 628 + 627 + 828 + 827 + 727)*(1 + 636/626)
	// The following equations assume that all are absent except 626 + 636 (because it is assumed that 18O and 17O do not exist):
	R13C_temp = R13_vpdb*(d13C_local/1000 + 1)
	f12_temp = 1/(1 + R13C_temp)
	f13_temp = R13C_temp*f12_temp
	
	i626_local = CO2_local*f12_temp
	i636_local = CO2_local*f13_temp
	
	killwaves R13C_temp
	killwaves f12_temp, f13_temp
	
End

Function [wave CO2_local, wave d13C_local] IRIS_UTILITY_ConvertTo_d13C(wave i626_local, wave i636_local)
   
	// The omission of unmeasured isotopologues from the total CO2 mole fraction calculation here
	// will not cause any error if the isotopologue mole fractions were calibrated against reference
	// gas values that were converted from deltas and total CO2 while assuming that O16 is the only
	// oxygen isotope.
   
   variable R13_vpdb = 0.0111797
	
	make/O/D/N=(numpnts(i626_local)) R13C_temp
	
	R13C_temp = i636_local/i626_local
	
	d13C_local = 1000*((R13C_temp/R13_vpdb) - 1)
	
	// All possible stable isotopologues written such that sites matter: (626 + 628 + 826 + 627 + 726 + 828 + 827 + 728 + 727)*(1 + 636/626)
	// All possible stable isotopologues written such that sites do not matter (i.e. such that 628 = 628 + 826 and 627 = 627 + 726 and 827 = 827 + 728): (626 + 628 + 627 + 828 + 827 + 727)*(1 + 636/626)
	// The following equation includes only 626 + 636:
	CO2_local = i626_local + i636_local
   	
	killwaves R13C_temp
   
End

/////////////////////
// Event Functions //
/////////////////////

// USAGE: These functions must all have names starting with "IRIS_EVENT_" and must take exactly one argument, which must be a string

Function IRIS_EVENT_SendECL(sCommand)
	string sCommand
		
	NVAR developmentMode = root:developmentMode
	NVAR azaInProgress = root:azaInProgress
	NVAR azaValveHasTriggered = root:azaValveHasTriggered
	NVAR azaInitialValveState = root:azaInitialValveState
	NVAR azaOpeningTimer = root:azaOpeningTimer
	NVAR azaValve = root:azaValve
	
	wave wValveStates = root:Wintel_Status:wintcp_valveCurrentState
	
	string azaValveString
	variable preByte, postByte
	
	if(developmentMode == 0)
		if(strlen(sCommand) > 0)
			if(stringmatch(sCommand, "aza*") == 1)
				azaInProgress = 1
				azaValveHasTriggered = 0
				preByte = strsearch(sCommand, ",", 0)
				postByte = strsearch(sCommand, ",", preByte + 1)
				azaValveString = sCommand[preByte+1, postByte-1]
				azaValve = str2num(azaValveString)
				azaInitialValveState = wValveStates[azaValve]
				azaOpeningTimer = DateTime
				print "aza starting, valve = " + num2str(azaValve)
			endif
			WILTI_EnqueString( sCommand )
		endif
	endif
	
End

Function IRIS_EVENT_FetchData(sUnusedString)
	string sUnusedString
	
	string saveFolder = GetDataFolder(1);
	SetDataFolder root:
		
	NVAR developmentMode = root:developmentMode
	NVAR minBytesInFile // bytes, to avoid a Loadwave error when trying to load a file with no data in it (1000 bytes is enough that it won't just be a header)
	
	SVAR sDataPathOnDisk = root:sDataPathOnDisk
	SVAR sAntecedentSTRfile = root:sAntecedentSTRfile
		
	wave/T wSTRrootNames = root:wSTRrootNames
	
	variable filePairIndex, numFilePairs
	string sThisFile, sThisFileRootName
	string fabFileName
	
	DoUpdate
		
	// Identify STR/STC file pairs and sort them reverse chronologically
	string sListOfSTRfiles = IndexedFile(STRLoadPath,-1, ".str")
	string sSortedListOfSTRfiles = SortList(sListOfSTRfiles, ";", 1) // descending alphabetic ASCII sort; newest timestamped STR file should be first in the resulting list
	sThisFile = StringFromList(0, sSortedListOfSTRfiles, ";")
		
	if((cmpstr(sThisFile, sAntecedentSTRfile) != 0) || (developmentMode == 1)) // only load STR/STC files that didn't exist before this run started (unless you're in testing mode)
		
		// Identify STR/STC file pairs associated with this run
		numFilePairs = WhichListItem(sAntecedentSTRfile, sSortedListOfSTRfiles, ";")
		if(developmentMode == 1)
			numFilePairs = 2
		endif
		if(numFilePairs > numpnts(wSTRrootNames))
			redimension/N=(numFilePairs) wSTRrootNames
			for(filePairIndex=0;filePairIndex<numFilePairs;filePairIndex+=1)
				sThisFile = StringFromList(filePairIndex, sSortedListOfSTRfiles, ";")
				sThisFileRootName = RemoveEnding(sThisFile, ".str")
				wSTRrootNames[numFilePairs - 1 - filePairIndex] = sThisFileRootName // a text wave containing root names of the STR/STC file pairs associated with this run (so far) in chronological order
			endfor
		endif
		
		// Don't try to load or analyze if there's no data in the first str file yet
		sprintf fabFileName, "%s:%s.str", sDataPathOnDisk, wSTRrootNames[0]
		fabFileName = RemoveDoubleColon( fabFileName ) // just in case
		GetFileFolderInfo/Q/Z fabFileName
		if(V_logEOF > minBytesInFile)
		
			// Load the appropriate STR/STC file pair(s)
			IRIS_UTILITY_LoadSTRandSTC()
		
			// Analyze data...
			SVAR sAnalyzeFunctionName = root:sAnalyzeFunctionName
			FUNCREF IRIS_UTILITY_ProtoFunc IRIS_AnalyzeFunction = $sAnalyzeFunctionName
			IRIS_AnalyzeFunction() // calls IRIS_SCHEME_Analyze_XXXXX(), where XXXXX is the instrument type
		
		endif
		
	endif
	
	DoUpdate
	
	SetDataFolder $saveFolder
	
End

Function IRIS_EVENT_StartTimer(sTimerNumber)
	string sTimerNumber
	
	wave wTimerAnchors = root:wTimerAnchors
	
	variable timerNumber = str2num(sTimerNumber)
	
	if(timerNumber > 0)
		if(timerNumber > (numpnts(wTimerAnchors) - 1))
			redimension/N=(timerNumber + 1) wTimerAnchors
		endif
		wTimerAnchors[timerNumber] = DateTime
	endif
	
End

Function IRIS_EVENT_ReportStatus(sStatusMessage)
	string sStatusMessage
	
	if(strlen(sStatusMessage) > 0)
		IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", secs2time(DateTime,3) + "  " + sStatusMessage)
		//IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", secs2time(DateTime + 6*3600 + 4*60,3) + "  " + sStatusMessage) // TESTING!!! TO MAKE A SPECIAL GRAPH
	endif
	
End

Function IRIS_EVENT_ResetABGtimer(sUnusedString)
	string sUnusedString
	
	NVAR ABGtimer = root:ABGtimer
	ABGtimer = DateTime
	
End

Function IRIS_EVENT_CheckABGinterval(sUnusedString)
	string sUnusedString
	
	string saveFolder = GetDataFolder(1);
	SetDataFolder root:
	
	NVAR ABGtimer = root:ABGtimer
	NVAR scheduleIndex = root:scheduleIndex
	NVAR cycleNumber = root:cycleNumber
	
	variable numCycles = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Cycles"))
	variable ABGinterval = 60*str2num(IRIS_UTILITY_GetParamValueFromName("Background Measurement Interval")) // seconds
	
	wave wSchedule_Current_TriggerTime = root:wSchedule_Current_TriggerTime
	
	variable currentTime = DateTime
	
	if((currentTime > (ABGtimer + ABGinterval)) && (ABGinterval > 0) && (cycleNumber < numCycles)) // don't bother doing ABG if this is the last cycle
				
		// Make "RedoABG" the current schedule and start at its beginning, without incrementing cycleNumber
		IRIS_UTILITY_ClearSchedule("Current")
		IRIS_UTILITY_AppendScheduleToSchedule("Current", "RedoABG")
		variable numScheduleEvents = numpnts(wSchedule_Current_TriggerTime)
		scheduleIndex = -1 // a negative scheduleIndex instructs the schedule agent to reset scheduleIndex to 0 instead of incrementing it after this command is performed
	
	endif
	
	SetDataFolder $saveFolder
	
End

Function IRIS_EVENT_ResumeCycleSchedule(sUnusedString)
	string sUnusedString
	
	string saveFolder = GetDataFolder(1);
	SetDataFolder root:
	
	NVAR scheduleIndex = root:scheduleIndex
	NVAR cycleNumber = root:cycleNumber
	
	wave wSchedule_Current_TriggerTime = root:wSchedule_Current_TriggerTime
		
	// Make "Cycle" the current schedule and start at its beginning, incrementing cycleNumber by 1
	IRIS_UTILITY_ClearSchedule("Current")
	IRIS_UTILITY_AppendScheduleToSchedule("Current", "Cycle")
	variable numScheduleEvents = numpnts(wSchedule_Current_TriggerTime)
	cycleNumber += 1
	scheduleIndex = -1 // a negative scheduleIndex instructs the schedule agent to reset scheduleIndex to 0 instead of incrementing it after this command is performed
	
	SetDataFolder $saveFolder
	
End

///////////////////////////
// Generic GUI Functions //
///////////////////////////

Function IRIS_GUI_Panel()
	
	wave/T wtParamNames = root:wtParamNames
	wave/T wtParamValues = root:wtParamValues
	wave/T wtParamUnits = root:wtParamUnits
	wave/T wtGasParamNames = root:wtGasParamNames
	wave/T wtGasParamValues = root:wtGasParamValues
	wave/T wtGasParamUnits = root:wtGasParamUnits
//	wave/T wtCalParamNames = root:wtCalParamNames
//	wave/T wtCalParamValues = root:wtCalParamValues
//	wave/T wtCalParamUnits = root:wtCalParamUnits
	wave/T wtBasicParamNames = root:wtBasicParamNames
	wave/T wtBasicParamValues = root:wtBasicParamValues
	wave/T wtBasicParamUnits = root:wtBasicParamUnits
	wave/T wtAdvParamNames = root:wtAdvParamNames
	wave/T wtAdvParamValues = root:wtAdvParamValues
	wave/T wtAdvParamUnits = root:wtAdvParamUnits
	wave/T wtFilterParamNames = root:wtFilterParamNames
	wave/T wtFilterParamValues = root:wtFilterParamValues
	wave/T wtFilterParamUnits = root:wtFilterParamUnits
	
	wave wOutputMeanToGraph1 = root:wOutputMeanToGraph1
	wave wOutputErrorToGraph1 = root:wOutputErrorToGraph1
	wave wOutputFilterToGraph1 = root:wOutputFilterToGraph1
	wave wOutputTimeToGraph1 = root:wOutputTimeToGraph1
	wave wOutputMeanToGraph2 = root:wOutputMeanToGraph2
	wave wOutputErrorToGraph2 = root:wOutputErrorToGraph2
	wave wOutputFilterToGraph2 = root:wOutputFilterToGraph2
	wave wOutputTimeToGraph2 = root:wOutputTimeToGraph2
	
	NVAR numOutputVariables = root:numOutputVariables
	wave/T wtOutputVariableNames = root:wtOutputVariableNames
	wave/T wtOutputVariableUnits = root:wtOutputVariableUnits
	
	wave/T wtDisplayUnits = root:wtDisplayUnits
	wave/T wtDisplayFormat = root:wtDisplayFormat
	
	wave/T wtDataFilterTable_CheckForOutliers
	wave/T wtDataFilterTable_OutlierThresholds
	wave/T wtDataFilterTable_FilterGroups
	
	SVAR sInstrumentID = root:sInstrumentID
	SVAR sRunID = root:sRunID
	SVAR calEqnStr_UI = root:calEqnStr_UI // this is the string equation input by the user
	
	NVAR IRIS_Running = root:IRIS_Running
	NVAR IRIS_Standby = root:IRIS_Standby
	NVAR IRIS_ConfirmToStop = root:IRIS_ConfirmToStop
	NVAR IRIS_ShouldStartToStop = root:IRIS_ShouldStartToStop
	NVAR IRIS_Stopping = root:IRIS_Stopping
	NVAR IRIS_Reanalyzing = root:IRIS_Reanalyzing
	NVAR IRIS_ChoosingFiles = root:IRIS_ChoosingFiles
	NVAR gasToGraph1 = root:gasToGraph1
	NVAR variableToGraph1 = root:variableToGraph1
	NVAR gasToGraph2 = root:gasToGraph2
	NVAR variableToGraph2 = root:variableToGraph2
	NVAR output1_gasID = root:output1_gasID
	NVAR output2_gasID = root:output2_gasID
	NVAR output3_gasID = root:output3_gasID
	NVAR output1_variableID = root:output1_variableID
	NVAR output2_variableID = root:output2_variableID
	NVAR output3_variableID = root:output3_variableID
	
	NVAR minNumSamples = root:minNumSamples
	NVAR maxNumSamples = root:maxNumSamples
	NVAR minNumRefs = root:minNumRefs
	NVAR maxNumRefs = root:maxNumRefs
	
	variable numSamplesIncrement = (maxNumSamples == minNumSamples) ? 0 : 1
	variable numRefsIncrement = (maxNumRefs == minNumRefs) ? 0 : 1
	
	variable/G panelLeftEdgePosition = 0 //50
	variable/G panelTopEdgePosition = 0 //76
	variable/G panelWidth = 650
	variable/G panelHeight = 700
	variable panelTopMargin = 40
	variable panelMargin = 20
	variable panelHorizontalCenter = panelWidth/2
	
	variable fontSize = 16
	variable runFontSize = 16
	variable standbyFontSize = 12
	variable stopFontSize = 14
	variable fileChoicefontSize = 12
	variable fileChoiceEntryHeight = 30
	variable/G graphFontSize = 14
	variable tableFontSize = 13
	variable scheduleFontSize = 12
	variable scheduleTitleFontSize = 12
	variable notebookFontSize = 12
	
	variable calCurveIsValidLEDwidth = 100
	variable calCurveFieldWidth = panelWidth - 2*panelMargin - calCurveIsValidLEDwidth - 10
	variable calInstructionsFontSize = 12
	variable calInstructionsLineHeight = 18
	variable calInstructionsTopMargin = 20
	variable calInstructionsBottomMargin = 20
	
	variable LEDringThickness = 5
	
	variable sampleIDlabelWidth = 100
	variable sampleIDentryWidth = panelWidth - 2*panelMargin - sampleIDlabelWidth
	
	variable runButtonHorizontalSeparation = 30 // 35
	variable runButtonVerticalSeparation = 7
	
	variable runButtonWidth = 125
	variable runButtonHeight = 50
	variable runButtonLeftEdgePosition = panelMargin + LEDringThickness
	
//	variable standbyButtonWidth = 125
//	variable standbyButtonHeight = 25
//	variable standbyButtonLeftEdgePosition = (runButtonLeftEdgePosition + runButtonWidth/2) - standbyButtonWidth/2
	
	variable standbyCheckboxHeight = 20
	
	variable stopButtonWidth = 125
	variable stopButtonHeight = 25
	variable stopButtonLeftEdgePosition = (runButtonLeftEdgePosition + runButtonWidth/2) - stopButtonWidth/2
	
	variable chooseFilesButtonWidth = 125
	variable chooseFilesButtonHeight = 30
	
	variable reanalyzeButtonWidth = 125
	variable reanalyzeButtonHeight = 60
	
	variable LEDr_run_off = 0
	variable LEDg_run_off = 24575
	variable LEDb_run_off = 0
	variable LEDr_run_on = 0
	variable LEDg_run_on = 65535
	variable LEDb_run_on = 0
	
//	variable LEDr_standby_off = 24575
//	variable LEDg_standby_off = 24575
//	variable LEDb_standby_off = 0
//	variable LEDr_standby_on = 65535
//	variable LEDg_standby_on = 65535
//	variable LEDb_standby_on = 0
	
	variable LEDr_stop_off = 24575
	variable LEDg_stop_off = 0
	variable LEDb_stop_off = 0
	variable LEDr_stop_on = 65535
	variable LEDg_stop_on = 0
	variable LEDb_stop_on = 0
	
	variable LEDr_reanalyze_off = 0
	variable LEDg_reanalyze_off = 0
	variable LEDb_reanalyze_off = 24575
	variable LEDr_reanalyze_on = 0
	variable LEDg_reanalyze_on = 0
	variable LEDb_reanalyze_on = 65535
	
	variable LEDr_chooseFiles_off = 24575
	variable LEDg_chooseFiles_off = 24575
	variable LEDb_chooseFiles_off = 0
	variable LEDr_chooseFiles_on = 65535
	variable LEDg_chooseFiles_on = 65535
	variable LEDb_chooseFiles_on = 0
	
	variable rowHeight = 30
	variable entryHeight = 25
	variable rowHeightMargin = (rowHeight - entryHeight)/2
	
	variable verticalNudge = 2
	
	variable quadColumnWidth0 = 40
	variable quadColumnWidth1 = 140
	variable quadColumnWidth = 80
	variable quadColumn0_leftEdgePosition = panelMargin + max(runButtonWidth,stopButtonWidth) + 2*LEDringThickness + runButtonHorizontalSeparation
	variable quadColumn1_leftEdgePosition = quadColumn0_leftEdgePosition + quadColumnWidth0 + 10
	variable quadColumn2_leftEdgePosition = quadColumn1_leftEdgePosition + quadColumnWidth1 + 10
	variable quadColumn3_leftEdgePosition = quadColumn2_leftEdgePosition + quadColumnWidth + 30
	variable quadColumn4_leftEdgePosition = quadColumn3_leftEdgePosition + quadColumnWidth
	
	variable ownAxisCheckBoxWidth = 70
	
	variable numGasesTotalWidth = panelWidth - 2*panelMargin
	variable numGasesBodyWidth = 50
	
	variable/G diagnosticsShown = 0
	variable diagGraphButtonWidth = 150
	variable diagGraphButtonHeight = 25
	
	variable/G midGreyColorR = 25000 //32767 //16383 //32767 //57343 //65535
	variable/G midGreyColorG = 25000
	variable/G midGreyColorB = 25000
	
	variable advOptionsButtonHeight = 30
	variable advOptionsButtonWidth = 300	
	
	variable tableHeightRowScaleFactor = 2.2 // 2.2 for Windows, 1.7 for Mac
	variable gasTableHeight = tableHeightRowScaleFactor*tableFontSize*(numpnts(wtGasParamNames) + 1) // unused
	variable basicTableHeight = tableHeightRowScaleFactor*tableFontSize*(numpnts(wtBasicParamNames) + 1)
	variable dataFilterTableHeight = tableHeightRowScaleFactor*tableFontSize*(numOutputVariables + 1)
	
	variable statusNotebookHeight = 60
	variable statusNotebookVerticalSeparation = 10
	
	//2692 × 180
	variable logoWidth = round(0.5*(2692/3)*(panelWidth/(2692/3))) //round(300/3.5)
	variable logoHeight = round(0.5*140*(panelWidth/(2692/3))) //round(240/3.5)
	
	variable scheduleTitleHeight = 25
	variable scheduleTableHeight = (panelHeight - panelTopMargin - panelMargin)/3 - scheduleTitleHeight
	
	// Create GUI Panel...
	
	DoWindow/K IRISpanel
	NewPanel/N=IRISpanel/W=(panelLeftEdgePosition,panelTopEdgePosition,panelLeftEdgePosition+panelWidth,panelTopEdgePosition+panelHeight) as "IRIS (Interface for Runs of Interleaved Samples) - " + sInstrumentID
	DoUpdate/W=IRISpanel/E=1
	TabControl tb, tabLabel(0)="Run", size={panelWidth,panelHeight}, proc = IRIS_GUI_TabProc
	TabControl tb, tabLabel(1)="Gases"
	TabControl tb, tabLabel(2)="Calibration"
	TabControl tb, tabLabel(3)="Data Filtering"
	TabControl tb, tabLabel(4)="System" // formerly "Config" (renamed because Gas Info, Calibration, and Data Filtering are also config tabs)
	TabControl tb, tabLabel(5)="View Schedule" // maybe I should turn this into something you can view from a button within the Schedule tab
	TabControl tb, tabLabel(6)="Reanalysis"
	SetDrawLayer UserBack
		
	// Populate the "Run" tab (and much of the "Reanalysis" tab)...
	
	variable verticalPositionSoFar = panelTopMargin + rowHeightMargin
	
	SetVariable IRIS_SampleID_tabRunOrReanalyze, value = sRunID, pos = {panelMargin,verticalPositionSoFar}, size = {panelWidth - 3*panelMargin - diagGraphButtonWidth,entryHeight}, fSize = fontSize, title = "Run ID "
	Button IRIS_ShowDiagnostics_tabRunOrReanalyze, align = 1, pos = {panelWidth - panelMargin,verticalPositionSoFar}, size = {diagGraphButtonWidth,diagGraphButtonHeight}, proc = IRIS_GUI_ShowDiagnostics_ButtonProc, fSize = fontSize, title = "Show Diagnostics"
	
	variable verticalPositionAtBottomOfSampleID = verticalPositionSoFar + entryHeight + rowHeightMargin
	
	ValDisplay runningLED_tabRun,pos={runButtonLeftEdgePosition-LEDringThickness,verticalPositionAtBottomOfSampleID+panelMargin},size={runButtonWidth+2*LEDringThickness,runButtonHeight+2*LEDringThickness}
	ValDisplay runningLED_tabRun,limits={0,1,0},barmisc={0,0},mode=2, frame = 0
	ValDisplay runningLED_tabRun,value = #"IRIS_Running",zeroColor=(LEDr_run_off,LEDg_run_off,LEDb_run_off),lowColor=(LEDr_run_off,LEDg_run_off,LEDb_run_off),highColor=(LEDr_run_on,LEDg_run_on,LEDb_run_on)
	Button IRIS_Run_tabRun, pos = {runButtonLeftEdgePosition,verticalPositionAtBottomOfSampleID+panelMargin+LEDringThickness}, size = {runButtonWidth,runButtonHeight}, proc = IRIS_GUI_Run_ButtonProc, fSize = runFontSize, fstyle = 1, title = "RUN"
	
	variable verticalPositionAtBottomOfRunButtonLED = verticalPositionAtBottomOfSampleID + panelMargin + runButtonHeight + 2*LEDringThickness
		
	ValDisplay stoppingLED_tabRun,pos={stopButtonLeftEdgePosition-LEDringThickness,verticalPositionAtBottomOfRunButtonLED+runButtonVerticalSeparation},size={stopButtonWidth+2*LEDringThickness,stopButtonHeight+2*LEDringThickness}
	ValDisplay stoppingLED_tabRun,limits={0,1,0},barmisc={0,0},mode=2, frame = 0
	ValDisplay stoppingLED_tabRun,value = #"(IRIS_ShouldStartToStop || IRIS_Stopping)",zeroColor=(LEDr_stop_off,LEDg_stop_off,LEDb_stop_off),lowColor=(LEDr_stop_off,LEDg_stop_off,LEDb_stop_off),highColor=(LEDr_stop_on,LEDg_stop_on,LEDb_stop_on)
	Button IRIS_Stop_tabRun, pos = {stopButtonLeftEdgePosition,verticalPositionAtBottomOfRunButtonLED+runButtonVerticalSeparation+LEDringThickness}, size = {stopButtonWidth,stopButtonHeight}, proc = IRIS_GUI_Stop_ButtonProc, fSize = stopFontSize, fstyle = 1, title = "STOP"
	
	variable verticalPositionAtBottomOfStopButtonLED = verticalPositionAtBottomOfRunButtonLED + runButtonVerticalSeparation + stopButtonHeight + 2*LEDringThickness
	
	CheckBox IRIS_Standby_tabRun, align = 0, pos = {runButtonLeftEdgePosition-LEDringThickness,verticalPositionAtBottomOfStopButtonLED+runButtonVerticalSeparation}, size = {runButtonWidth, standbyCheckboxHeight}, fsize = standbyFontSize, title = "Heed Ext. Cmds."
	CheckBox IRIS_Standby_tabRun, proc = IRIS_GUI_Standby_CheckBoxProc
	
	variable verticalPositionAtBottomOfStandbyCheckbox = verticalPositionAtBottomOfStopButtonLED + standbyCheckboxHeight + runButtonVerticalSeparation
	
//	ValDisplay standbyLED_tabRun,pos={standbyButtonLeftEdgePosition-LEDringThickness,verticalPositionAtBottomOfRunButtonLED+runButtonVerticalSeparation},size={standbyButtonWidth+2*LEDringThickness,standbyButtonHeight+2*LEDringThickness}
//	ValDisplay standbyLED_tabRun,limits={0,1,0},barmisc={0,0},mode=2, frame = 0
//	ValDisplay standbyLED_tabRun,value = #"IRIS_Standby",zeroColor=(LEDr_standby_off,LEDg_standby_off,LEDb_standby_off),lowColor=(LEDr_standby_off,LEDg_standby_off,LEDb_standby_off),highColor=(LEDr_standby_on,LEDg_standby_on,LEDb_standby_on)
//	Button IRIS_Standby_tabRun, pos = {standbyButtonLeftEdgePosition,verticalPositionAtBottomOfRunButtonLED+runButtonVerticalSeparation+LEDringThickness}, size = {standbyButtonWidth,standbyButtonHeight}, proc = IRIS_GUI_Standby_ButtonProc, fSize = standbyFontSize, fstyle = 1, title = "Heed Ext Cmds"
//	
//	variable verticalPositionAtBottomOfStandbyButtonLED = verticalPositionAtBottomOfRunButtonLED + runButtonVerticalSeparation + standbyButtonHeight + 2*LEDringThickness
	
	verticalPositionSoFar = verticalPositionAtBottomOfSampleID + panelMargin
	
	TitleBox IRIS_GasHeader_tabRunOrReanalyze, pos = {quadColumn0_leftEdgePosition,verticalPositionSoFar}, size = {quadColumnWidth0,entryHeight}, fSize=fontSize, title = "Gas", frame = 0, anchor = MC
	TitleBox IRIS_VariableHeader_tabRunOrReanalyze, pos = {quadColumn1_leftEdgePosition,verticalPositionSoFar}, size = {quadColumnWidth1,entryHeight}, fSize=fontSize, title = "Variable", frame = 0, anchor = MC
	TitleBox IRIS_MeanHeader_tabRunOrReanalyze, pos = {quadColumn2_leftEdgePosition,verticalPositionSoFar}, size = {quadColumnWidth,entryHeight}, fSize=fontSize, title = "Mean", frame = 0, anchor = MC
	TitleBox IRIS_StErrHeader_tabRunOrReanalyze, pos = {quadColumn3_leftEdgePosition,verticalPositionSoFar}, size = {quadColumnWidth,entryHeight}, fSize=fontSize, title = "SE", frame = 0, anchor = MC
	
	verticalPositionSoFar += entryHeight + rowHeightMargin + rowHeightMargin
	
	PopupMenu IRIS_GasChoice1_tabRunOrReanalyze, align = 1, bodyWidth = quadColumnWidth0, pos = {quadColumn0_leftEdgePosition + quadColumnWidth0,verticalPositionSoFar+verticalNudge}, fSize = fontSize, title = ""
	PopupMenu IRIS_GasChoice1_tabRunOrReanalyze, mode = output1_gasID + 1, value = IRIS_GUI_PopupWaveList_Gas()
	PopupMenu IRIS_GasChoice1_tabRunOrReanalyze, proc = IRIS_GUI_SelectGas1_PopupMenuProc
	PopupMenu IRIS_VariableChoice1_tabRunOrReanalyze, align = 1, bodyWidth = quadColumnWidth1, pos = {quadColumn1_leftEdgePosition + quadColumnWidth1,verticalPositionSoFar+verticalNudge}, fSize = fontSize, title = ""
	PopupMenu IRIS_VariableChoice1_tabRunOrReanalyze, mode = output1_variableID + 1, value = IRIS_GUI_PopupWaveList_Variable1()
	PopupMenu IRIS_VariableChoice1_tabRunOrReanalyze, proc = IRIS_GUI_SelectVariable1_PopupMenuProc
	SetVariable IRIS_OutputMean1_tabRunOrReanalyze, pos = {quadColumn2_leftEdgePosition,verticalPositionSoFar}, size = {quadColumnWidth,entryHeight}, fSize = fontSize
	SetVariable IRIS_OutputMean1_tabRunOrReanalyze, format = wtDisplayFormat[0], limits = {-inf,inf,0}, value = wDisplayMeans[0], noedit = 1, title = " "
	TitleBox IRIS_PlusMinus1_tabRunOrReanalyze, pos = {quadColumn3_leftEdgePosition-20,verticalPositionSoFar}, size = {10,entryHeight}, fSize=fontSize, title = "±", frame = 0, anchor = MC
	SetVariable IRIS_OutputStErr1_tabRunOrReanalyze, pos = {quadColumn3_leftEdgePosition,verticalPositionSoFar}, size = {quadColumnWidth,entryHeight}, fSize = fontSize
	SetVariable IRIS_OutputStErr1_tabRunOrReanalyze, format = wtDisplayFormat[0], limits = {-inf,inf,0}, value = wDisplayStErrs[0], noedit = 1, title = " "
	SetVariable IRIS_OutputUnits1_tabRunOrReanalyze, pos = {quadColumn4_leftEdgePosition,verticalPositionSoFar}, size = {quadColumnWidth,entryHeight}, fSize = fontSize
	SetVariable IRIS_OutputUnits1_tabRunOrReanalyze, limits = {-inf,inf,0}, value = wtDisplayUnits[0], noedit = 1, frame = 0, title = " "
	
	verticalPositionSoFar += entryHeight + rowHeightMargin + rowHeightMargin
	
	PopupMenu IRIS_GasChoice2_tabRunOrReanalyze, align = 1, bodyWidth = quadColumnWidth0, pos = {quadColumn0_leftEdgePosition + quadColumnWidth0,verticalPositionSoFar+verticalNudge}, fSize = fontSize, title = ""
	PopupMenu IRIS_GasChoice2_tabRunOrReanalyze, mode = output2_gasID + 1, value = IRIS_GUI_PopupWaveList_Gas()
	PopupMenu IRIS_GasChoice2_tabRunOrReanalyze, proc = IRIS_GUI_SelectGas2_PopupMenuProc
	PopupMenu IRIS_VariableChoice2_tabRunOrReanalyze, align = 1, bodyWidth = quadColumnWidth1, pos = {quadColumn1_leftEdgePosition + quadColumnWidth1,verticalPositionSoFar+verticalNudge}, fSize = fontSize, title = ""
	PopupMenu IRIS_VariableChoice2_tabRunOrReanalyze, mode = output2_variableID + 1, value = IRIS_GUI_PopupWaveList_Variable2()
	PopupMenu IRIS_VariableChoice2_tabRunOrReanalyze, proc = IRIS_GUI_SelectVariable2_PopupMenuProc
	SetVariable IRIS_OutputMean2_tabRunOrReanalyze, pos = {quadColumn2_leftEdgePosition,verticalPositionSoFar}, size = {quadColumnWidth,entryHeight}, fSize = fontSize
	SetVariable IRIS_OutputMean2_tabRunOrReanalyze, format = wtDisplayFormat[1], limits = {-inf,inf,0}, value = wDisplayMeans[1], noedit = 1, title = " "
	TitleBox IRIS_PlusMinus2_tabRunOrReanalyze, pos = {quadColumn3_leftEdgePosition-20,verticalPositionSoFar}, size = {10,entryHeight}, fSize=fontSize, title = "±", frame = 0, anchor = MC
	SetVariable IRIS_OutputStErr2_tabRunOrReanalyze, pos = {quadColumn3_leftEdgePosition,verticalPositionSoFar}, size = {quadColumnWidth,entryHeight}, fSize = fontSize
	SetVariable IRIS_OutputStErr2_tabRunOrReanalyze, format = wtDisplayFormat[1], limits = {-inf,inf,0}, value = wDisplayStErrs[1], noedit = 1, title = " "
	SetVariable IRIS_OutputUnits2_tabRunOrReanalyze, pos = {quadColumn4_leftEdgePosition,verticalPositionSoFar}, size = {quadColumnWidth,entryHeight}, fSize = fontSize
	SetVariable IRIS_OutputUnits2_tabRunOrReanalyze, limits = {-inf,inf,0}, value = wtDisplayUnits[1], noedit = 1, frame = 0, title = " "
	
	verticalPositionSoFar += entryHeight + rowHeightMargin + rowHeightMargin
	
	PopupMenu IRIS_GasChoice3_tabRunOrReanalyze, align = 1, bodyWidth = quadColumnWidth0, pos = {quadColumn0_leftEdgePosition + quadColumnWidth0,verticalPositionSoFar+verticalNudge}, fSize = fontSize, title = ""
	PopupMenu IRIS_GasChoice3_tabRunOrReanalyze, mode = output3_gasID + 1, value = IRIS_GUI_PopupWaveList_Gas()
	PopupMenu IRIS_GasChoice3_tabRunOrReanalyze, proc = IRIS_GUI_SelectGas3_PopupMenuProc
	PopupMenu IRIS_VariableChoice3_tabRunOrReanalyze, align = 1, bodyWidth = quadColumnWidth1, pos = {quadColumn1_leftEdgePosition + quadColumnWidth1,verticalPositionSoFar+verticalNudge}, fSize = fontSize, title = ""
	PopupMenu IRIS_VariableChoice3_tabRunOrReanalyze, mode = output3_variableID + 1, value = IRIS_GUI_PopupWaveList_Variable3()
	PopupMenu IRIS_VariableChoice3_tabRunOrReanalyze, proc = IRIS_GUI_SelectVariable3_PopupMenuProc
	SetVariable IRIS_OutputMean3_tabRunOrReanalyze, pos = {quadColumn2_leftEdgePosition,verticalPositionSoFar}, size = {quadColumnWidth,entryHeight}, fSize = fontSize
	SetVariable IRIS_OutputMean3_tabRunOrReanalyze, format = wtDisplayFormat[2], limits = {-inf,inf,0}, value = wDisplayMeans[2], noedit = 1, title = " "
	TitleBox IRIS_PlusMinus3_tabRunOrReanalyze, pos = {quadColumn3_leftEdgePosition-20,verticalPositionSoFar}, size = {10,entryHeight}, fSize=fontSize, title = "±", frame = 0, anchor = MC
	SetVariable IRIS_OutputStErr3_tabRunOrReanalyze, pos = {quadColumn3_leftEdgePosition,verticalPositionSoFar}, size = {quadColumnWidth,entryHeight}, fSize = fontSize
	SetVariable IRIS_OutputStErr3_tabRunOrReanalyze, format = wtDisplayFormat[2], limits = {-inf,inf,0}, value = wDisplayStErrs[2], noedit = 1, title = " "
	SetVariable IRIS_OutputUnits3_tabRunOrReanalyze, pos = {quadColumn4_leftEdgePosition,verticalPositionSoFar}, size = {quadColumnWidth,entryHeight}, fSize = fontSize
	SetVariable IRIS_OutputUnits3_tabRunOrReanalyze, limits = {-inf,inf,0}, value = wtDisplayUnits[2], noedit = 1, frame = 0, title = " "
	
	verticalPositionSoFar += entryHeight + rowHeightMargin
	
	verticalPositionSoFar = max(verticalPositionSoFar, verticalPositionAtBottomOfStandbyCheckbox)
	verticalPositionSoFar += panelMargin
	
	PopupMenu IRIS_PlotGasChoice1_tabRunOrReanalyze, align = 1, bodyWidth = quadColumnWidth0, pos = {panelMargin + quadColumnWidth0,verticalPositionSoFar+verticalNudge}, fSize = fontSize, title = ""
	PopupMenu IRIS_PlotGasChoice1_tabRunOrReanalyze, mode = gasToGraph1 + 1, value = IRIS_GUI_PopupWaveList_Gas()
	PopupMenu IRIS_PlotGasChoice1_tabRunOrReanalyze, proc = IRIS_GUI_SelectPlotGas1_PopupMenuProc
	PopupMenu IRIS_PlotVariableChoice1_tabRunOrReanalyze, align = 1, bodyWidth = quadColumnWidth1, pos = {panelMargin + quadColumnWidth0 + 10 + quadColumnWidth1,verticalPositionSoFar+verticalNudge}, fSize = fontSize, title = ""
	PopupMenu IRIS_PlotVariableChoice1_tabRunOrReanalyze, mode = variableToGraph1 + 1, value = IRIS_GUI_PopupWaveList_VariableG1()
	PopupMenu IRIS_PlotVariableChoice1_tabRunOrReanalyze, proc = IRIS_GUI_SelectPlotVariable1_PopupMenuProc
	
	CheckBox IRIS_ShowSecondPlotOnGraph_tabRunOrReanalyze, align = 1, pos = {panelWidth - panelMargin - ownAxisCheckBoxWidth - quadColumnWidth1 - 10 - quadColumnWidth0 - 10,verticalPositionSoFar+verticalNudge}, title = "Compare"
	CheckBox IRIS_ShowSecondPlotOnGraph_tabRunOrReanalyze, proc = IRIS_GUI_ShowSecondPlotOnGraph_CheckBoxProc
	
	PopupMenu IRIS_PlotGasChoice2_tabRunOrReanalyze, align = 1, bodyWidth = quadColumnWidth0, pos = {panelWidth - panelMargin - ownAxisCheckBoxWidth - quadColumnWidth1 - 10,verticalPositionSoFar+verticalNudge}, fSize = fontSize, title = ""
	PopupMenu IRIS_PlotGasChoice2_tabRunOrReanalyze, mode = gasToGraph2 + 1, value = IRIS_GUI_PopupWaveList_Gas()
	PopupMenu IRIS_PlotGasChoice2_tabRunOrReanalyze, proc = IRIS_GUI_SelectPlotGas2_PopupMenuProc
	PopupMenu IRIS_PlotGasChoice2_tabRunOrReanalyze, disable = 2
	PopupMenu IRIS_PlotVariableChoice2_tabRunOrReanalyze, align = 1, bodyWidth = quadColumnWidth1, pos = {panelWidth - panelMargin - ownAxisCheckBoxWidth,verticalPositionSoFar+verticalNudge}, fSize = fontSize, title = ""
	PopupMenu IRIS_PlotVariableChoice2_tabRunOrReanalyze, mode = variableToGraph2 + 1, value = IRIS_GUI_PopupWaveList_VariableG2()
	PopupMenu IRIS_PlotVariableChoice2_tabRunOrReanalyze, proc = IRIS_GUI_SelectPlotVariable2_PopupMenuProc
	PopupMenu IRIS_PlotVariableChoice2_tabRunOrReanalyze, disable = 2
	
	CheckBox IRIS_PlotSeparateAxisChoice_tabRunOrReanalyze, align = 1, pos = {panelWidth - panelMargin,verticalPositionSoFar+verticalNudge}, title = "Own Axis"
	CheckBox IRIS_PlotSeparateAxisChoice_tabRunOrReanalyze, proc = IRIS_GUI_OneOrTwoGraphAxes_CheckBoxProc
	CheckBox IRIS_PlotSeparateAxisChoice_tabRunOrReanalyze, disable = 2
			
	verticalPositionSoFar += entryHeight + rowHeightMargin + rowHeightMargin
	
	// Create an embedded graph to show the results...
	string sYaxisLabel
	Display/HOST=IRISpanel/N=ResultGraph/W=(panelMargin, verticalPositionSoFar, panelWidth - panelMargin, panelHeight - logoHeight - panelMargin - statusNotebookHeight - statusNotebookVerticalSeparation) wOutputMeanToGraph1 vs wOutputTimeToGraph1
	sYaxisLabel = wtOutputVariableNames[variableToGraph1] + " (" + wtOutputVariableUnits[variableToGraph1] + ")"
	Label Left sYaxisLabel
	Label bottom " "
	SetWindow IRISpanel#ResultGraph, hide = 0
	ModifyGraph/W=IRISpanel#ResultGraph frameStyle = 1, fSize = graphFontSize
	ModifyGraph lblMargin(left)=5
	ModifyGraph mode=3, marker=19, rgb=(16385,28398,65535), msize = 5, mrkThick=2
	ModifyGraph rgb(wOutputMeanToGraph1)=(16385,28398,65535)
	ModifyGraph axRGB(left)=(0,0,0), alblRGB(left)=(0,0,0), tlblRGB(left)=(0,0,0)
	ModifyGraph UIControl = 2^0 + 2^1 + 2^2 + 2^4 + 2^5 + 2^6 + 2^7 + 2^10 + 2^11
	ErrorBars wOutputMeanToGraph1 Y, wave=(wOutputErrorToGraph1,wOutputErrorToGraph1)
	ModifyGraph zmrkNum(wOutputMeanToGraph1)={wOutputFilterToGraph1}
	SetActiveSubwindow ##
	
	// Create an embedded notebook to display status messages for the user...
	variable winTypeCode = winType("IRISpanel#StatusNotebook")
	if(winTypeCode > 0)
		KillWindow IRISpanel#StatusNotebook
	endif
	NewNotebook/HOST=IRISpanel/N=StatusNotebook/V=0/F=0/OPTS=3/W=(panelMargin, panelHeight - logoHeight - panelMargin - statusNotebookHeight, panelWidth-panelMargin, panelHeight - logoHeight - panelMargin) as "STATUS"
	Notebook IRISpanel#StatusNotebook, frameStyle = 1, visible = 1, fsize = notebookFontSize
	Notebook IRISpanel#StatusNotebook, changeableByCommandOnly = 1
	Notebook IRISpanel#StatusNotebook, text = "STATUS"
	SetActiveSubwindow ##
	
	// Add the Aerodyne logo...
	NewPanel/N=LogoSubwindowPanel_tabRunOrReanalyze/HOST=IRISpanel/W=(0,panelHeight - logoHeight,panelWidth,panelHeight)
	ModifyPanel frameStyle = 0, frameInset = 0, noEdit = 1, fixedSize = 1
	Button IRIS_AerodyneLogo_tabRunOrReanalyze, win = IRISpanel#LogoSubwindowPanel_tabRunOrReanalyze, align = 0, pos = {panelWidth/2 - logoWidth/2, 0}, size = {logoWidth,logoHeight}, noproc, title = " ", picture = ProcGlobal#AerodyneLogoButtonPic
	SetActiveSubwindow ##
	
	// Populate the "Gases" tab...
	
	verticalPositionSoFar = panelTopMargin
	
	SetVariable IRIS_NumSampleGasInput_tabGas, value = numSampleGases, limits = {minNumSamples,maxNumSamples,numSamplesIncrement}, align = 1, pos = {panelMargin+numGasesTotalWidth,verticalPositionSoFar}, size = {numGasesTotalWidth,entryHeight}, bodyWidth = numGasesBodyWidth, disable = 1, fSize = fontSize, title = "Number of Sample Gases ", proc = IRIS_GUI_ChangeNumGases_SetVariableProc
	
	verticalPositionSoFar += entryHeight + rowHeightMargin + rowHeightMargin
	
	SetVariable IRIS_NumRefGasInput_tabGas, value = numRefGases, limits = {minNumRefs,maxNumRefs,numRefsIncrement}, align = 1, pos = {panelMargin+numGasesTotalWidth,verticalPositionSoFar}, size = {numGasesTotalWidth,entryHeight}, bodyWidth = numGasesBodyWidth, disable = 1, fSize = fontSize, title = "Number of Reference Gases ", proc = IRIS_GUI_ChangeNumGases_SetVariableProc
	
	verticalPositionSoFar += entryHeight + rowHeightMargin + rowHeightMargin
	
	// Create an embedded table to show the gas info parameters...
	Edit/HOST=IRISpanel/N=GasTable/W=(panelMargin,verticalPositionSoFar,panelWidth-panelMargin,panelHeight-panelMargin)/HIDE=0 wtGasParamNames, wtGasParamValues, wtGasParamUnits
	ModifyTable/W=IRISpanel#GasTable frameStyle = 1, size = tableFontSize, alignment(wtGasParamNames) = 0, alignment(wtGasParamValues) = 1, alignment(wtGasParamUnits) = 0
	ModifyTable/W=IRISpanel#GasTable showParts = 49
	ModifyTable/W=IRISpanel#GasTable autosize={0, 0, 1, 0, 0 }
	SetActiveSubwindow ##
	SetWindow IRISpanel#GasTable, hide = 1
	
	//	// Create an embedded table to show the gas info parameters...
	//	Edit/HOST=IRISpanel/N=GasTable/W=(panelMargin,verticalPositionSoFar,panelWidth-panelMargin,min(verticalPositionSoFar+gasTableHeight,panelHeight-panelMargin))/HIDE=0 wtGasParamNames, wtGasParamValues, wtGasParamUnits
	//	ModifyTable/W=IRISpanel#GasTable frameStyle = 1, size = tableFontSize, alignment(wtGasParamNames) = 0, alignment(wtGasParamValues) = 1, alignment(wtGasParamUnits) = 0
	//	ModifyTable/W=IRISpanel#GasTable showParts = 49
	//	ModifyTable/W=IRISpanel#GasTable autosize={0, 0, 1, 0, 0 }
	//	SetActiveSubwindow ##
	//	SetWindow IRISpanel#GasTable, hide = 1
	
	// Populate the "Calibration" tab...
	
	verticalPositionSoFar = panelTopMargin
	
	SetVariable IRIS_CalCurveInput_tabCal, value = calEqnStr_UI, pos = {panelMargin,verticalPositionSoFar}, size = {calCurveFieldWidth,entryHeight}, disable = 1, fSize = fontSize, title = "Calibration curve equation: true = ", proc = IRIS_GUI_ChangeCalCurve_SetVariableProc
	
	ValDisplay calCurveValidityLED_tabCal,pos={panelMargin + calCurveFieldWidth + 10,verticalPositionSoFar},size={calCurveIsValidLEDwidth,entryHeight}
	ValDisplay calCurveValidityLED_tabCal,limits={0,1,0},barmisc={0,0},mode=2, frame = 0, disable = 1
	ValDisplay calCurveValidityLED_tabCal,value = #"calCurveIsValid",zeroColor=(LEDr_stop_on,LEDg_stop_on,LEDb_stop_on),lowColor=(LEDr_stop_on,LEDg_stop_on,LEDb_stop_on),highColor=(LEDr_run_on,LEDg_run_on,LEDb_run_on)
	TitleBox calCurveValidityText_tabCal, pos = {panelMargin + calCurveFieldWidth + 10,verticalPositionSoFar}, size = {calCurveIsValidLEDwidth,entryHeight}, fSize=fontSize, title = "VALID", frame = 0, anchor = MC, disable = 1
	
	verticalPositionSoFar += entryHeight + calInstructionsTopMargin
	
	// A global string named calEqnStr_UI must have already been created outside of this function
	// and must consist of an equation that Igor can understand, with "meas" used for the measured
	// value, "true" used for the true value, and "c0", "c1", "c2", etc used for the fit coefficients.
	// E.g. for a simple ratio fit, calEqnStr_UI = "true = c0*meas"
	// E.g. for a linear fit, calEqnStr_UI = "true = c0 + c1*meas"
	// E.g. for a 2nd order polynomial fit, calEqnStr_UI = "true = c0 + c1*meas + c2*meas^2"
	string sBlurb = ""
	sBlurb = "INSTRUCTIONS:\n"
	TitleBox IRIS_CalCurveDirections0_tabCal, disable = 1, pos = {panelMargin,verticalPositionSoFar}, size = {panelWidth, panelHeight - verticalPositionSoFar}, fSize=calInstructionsFontSize, title = sBlurb, frame = 0
	verticalPositionSoFar += calInstructionsLineHeight + round(calInstructionsLineHeight/2)
	sBlurb = "This equation tells IRIS the form of the relationship between the true mole fraction\n"
	TitleBox IRIS_CalCurveDirections1_tabCal, disable = 1, pos = {panelMargin,verticalPositionSoFar}, size = {panelWidth, panelHeight - verticalPositionSoFar}, fSize=calInstructionsFontSize, title = sBlurb, frame = 0
	verticalPositionSoFar += calInstructionsLineHeight
	sBlurb = "(of a species or isotopologue) and the corresponding value measured by the instrument,\n"
	TitleBox IRIS_CalCurveDirections2_tabCal, disable = 1, pos = {panelMargin,verticalPositionSoFar}, size = {panelWidth, panelHeight - verticalPositionSoFar}, fSize=calInstructionsFontSize, title = sBlurb, frame = 0
	verticalPositionSoFar += calInstructionsLineHeight
	sBlurb = "with the true value isolated on the left-hand side.\n"
	TitleBox IRIS_CalCurveDirections3_tabCal, disable = 1, pos = {panelMargin,verticalPositionSoFar}, size = {panelWidth, panelHeight - verticalPositionSoFar}, fSize=calInstructionsFontSize, title = sBlurb, frame = 0
	verticalPositionSoFar += calInstructionsLineHeight + round(calInstructionsLineHeight/2)
	sBlurb = "Type the right-hand side of the equation such that:\n"
	TitleBox IRIS_CalCurveDirections4_tabCal, disable = 1, pos = {panelMargin,verticalPositionSoFar}, size = {panelWidth, panelHeight - verticalPositionSoFar}, fSize=calInstructionsFontSize, title = sBlurb, frame = 0
	verticalPositionSoFar += calInstructionsLineHeight
	sBlurb = "   (a) it uses valid Igor syntax, e.g. with the operators +, -, *, /, ^;\n"
	TitleBox IRIS_CalCurveDirections5_tabCal, disable = 1, pos = {panelMargin,verticalPositionSoFar}, size = {panelWidth, panelHeight - verticalPositionSoFar}, fSize=calInstructionsFontSize, title = sBlurb, frame = 0
	verticalPositionSoFar += calInstructionsLineHeight
	sBlurb = "   (b) the measured mole fraction is represented by \"meas\" (without quotes);"
	TitleBox IRIS_CalCurveDirections6_tabCal, disable = 1, pos = {panelMargin,verticalPositionSoFar}, size = {panelWidth, panelHeight - verticalPositionSoFar}, fSize=calInstructionsFontSize, title = sBlurb, frame = 0
	verticalPositionSoFar += calInstructionsLineHeight
	sBlurb = "   (c) the fit coefficients are represented by \"c0\", \"c1\", \"c2\", ... (without quotes); and"
	TitleBox IRIS_CalCurveDirections7_tabCal, disable = 1, pos = {panelMargin,verticalPositionSoFar}, size = {panelWidth, panelHeight - verticalPositionSoFar}, fSize=calInstructionsFontSize, title = sBlurb, frame = 0
	verticalPositionSoFar += calInstructionsLineHeight
	sBlurb = "   (d) any functions that appear have valid Igor names, e.g. exp(), ln(), sin().\n"
	TitleBox IRIS_CalCurveDirections8_tabCal, disable = 1, pos = {panelMargin,verticalPositionSoFar}, size = {panelWidth, panelHeight - verticalPositionSoFar}, fSize=calInstructionsFontSize, title = sBlurb, frame = 0
	verticalPositionSoFar += calInstructionsLineHeight + round(calInstructionsLineHeight/2)
	sBlurb = "You must have at least as many reference gases as fit coefficients to start a run.\n"
	TitleBox IRIS_CalCurveDirections9_tabCal, disable = 1, pos = {panelMargin,verticalPositionSoFar}, size = {panelWidth, panelHeight - verticalPositionSoFar}, fSize=calInstructionsFontSize, title = sBlurb, frame = 0
	verticalPositionSoFar += calInstructionsLineHeight + round(calInstructionsLineHeight/2)
	sBlurb = "EXAMPLES:\n"
	TitleBox IRIS_CalCurveDirections10_tabCal, disable = 1, pos = {panelMargin,verticalPositionSoFar}, size = {panelWidth, panelHeight - verticalPositionSoFar}, fSize=calInstructionsFontSize, title = sBlurb, frame = 0
	verticalPositionSoFar += calInstructionsLineHeight + round(calInstructionsLineHeight/2)
	sBlurb = "true = c0*meas   => proportional relationship (as in the isotope super-ratio method)\n"
	TitleBox IRIS_CalCurveDirections11_tabCal, disable = 1, pos = {panelMargin,verticalPositionSoFar}, size = {panelWidth, panelHeight - verticalPositionSoFar}, fSize=calInstructionsFontSize, title = sBlurb, frame = 0
	verticalPositionSoFar += calInstructionsLineHeight
	sBlurb = "true = c0 + c1*meas   => linear relationship (coefficients for offset and gain)\n"
	TitleBox IRIS_CalCurveDirections12_tabCal, disable = 1, pos = {panelMargin,verticalPositionSoFar}, size = {panelWidth, panelHeight - verticalPositionSoFar}, fSize=calInstructionsFontSize, title = sBlurb, frame = 0
	verticalPositionSoFar += calInstructionsLineHeight
	sBlurb = "true = c0 + c1*meas + c2*meas^2   => 2nd-order polynomial relationship\n"
	TitleBox IRIS_CalCurveDirections13_tabCal, disable = 1, pos = {panelMargin,verticalPositionSoFar}, size = {panelWidth, panelHeight - verticalPositionSoFar}, fSize=calInstructionsFontSize, title = sBlurb, frame = 0
	verticalPositionSoFar += calInstructionsLineHeight + calInstructionsBottomMargin
	
	// Populate the "System" tab...
	
	verticalPositionSoFar = panelTopMargin
	
	// Create an embedded table to show the basic system parameters...
	Edit/HOST=IRISpanel/N=BasicSystemTable/W=(panelMargin,verticalPositionSoFar,panelWidth-panelMargin,min(verticalPositionSoFar+basicTableHeight,panelHeight-panelMargin))/HIDE=0 wtBasicParamNames, wtBasicParamValues, wtBasicParamUnits
	ModifyTable/W=IRISpanel#BasicSystemTable frameStyle = 1, size = tableFontSize, alignment(wtBasicParamNames) = 0, alignment(wtBasicParamValues) = 1, alignment(wtBasicParamUnits) = 0
	ModifyTable/W=IRISpanel#BasicSystemTable showParts = 49
	ModifyTable/W=IRISpanel#BasicSystemTable autosize={0, 0, 1, 0, 0 }
	SetActiveSubwindow ##
	SetWindow IRISpanel#BasicSystemTable, hide = 1
	
	verticalPositionSoFar += basicTableHeight + 10
	
	Button IRIS_ShowAdvOptions_tabSystem, pos = {panelHorizontalCenter - advOptionsButtonWidth/2,verticalPositionSoFar}, size = {advOptionsButtonWidth,advOptionsButtonHeight}, disable = 1, proc = IRIS_GUI_ShowAdvOptions_ButtonProc, fSize = fontSize, title = "Show Advanced Options"
	
	verticalPositionSoFar += advOptionsButtonHeight + 10
	
	// Create an embedded table to show the advanced system parameters...
	Edit/HOST=IRISpanel/N=AdvSystemTable/W=(panelMargin,verticalPositionSoFar,panelWidth-panelMargin,panelHeight-panelMargin)/HIDE=0 wtAdvParamNames, wtAdvParamValues, wtAdvParamUnits
	ModifyTable/W=IRISpanel#AdvSystemTable frameStyle = 1, size = tableFontSize, alignment(wtAdvParamNames) = 0, alignment(wtAdvParamValues) = 1, alignment(wtAdvParamUnits) = 0
	ModifyTable/W=IRISpanel#AdvSystemTable showParts = 49
	ModifyTable/W=IRISpanel#AdvSystemTable autosize={0, 0, 1, 0, 0 }
	SetActiveSubwindow ##
	SetWindow IRISpanel#AdvSystemTable, hide = 1
	
	// Populate the "Schedule" tab...
	
	verticalPositionSoFar = panelTopMargin
	
	// Create an embedded table to display the "Prologue" schedule resulting from the system parameters...
	TitleBox IRIS_PrologueTitle_tabSchedule, disable = 1, pos = {panelMargin,verticalPositionSoFar}, size = {panelWidth,scheduleTitleHeight}, fSize=scheduleTitleFontSize, title = "PROLOGUE", frame = 0, anchor = LB
	verticalPositionSoFar += scheduleTitleHeight
	wave wSchedule_Prologue_WhichTimer = root:wSchedule_Prologue_WhichTimer
	wave wSchedule_Prologue_TriggerTime = root:wSchedule_Prologue_TriggerTime
	wave/T wSchedule_Prologue_Action = root:wSchedule_Prologue_Action
	wave/T wSchedule_Prologue_Argument = root:wSchedule_Prologue_Argument
	wave/T wSchedule_Prologue_Comment = root:wSchedule_Prologue_Comment
	Edit/HOST=IRISpanel/N=PrologueTable/W=(panelMargin,verticalPositionSoFar,panelWidth-panelMargin,verticalPositionSoFar+scheduleTableHeight)/HIDE=0 wSchedule_Prologue_WhichTimer, wSchedule_Prologue_TriggerTime, wSchedule_Prologue_Action, wSchedule_Prologue_Argument, wSchedule_Prologue_Comment
	ModifyTable/W=IRISpanel#PrologueTable frameStyle = 1, size = scheduleFontSize
	ModifyTable/W=IRISpanel#PrologueTable alignment = 1
	ModifyTable/W=IRISpanel#PrologueTable title(wSchedule_Prologue_WhichTimer)="Timer #", alignment(wSchedule_Prologue_WhichTimer) = 1
	ModifyTable/W=IRISpanel#PrologueTable title(wSchedule_Prologue_TriggerTime)="Event Time (s)", alignment(wSchedule_Prologue_TriggerTime) = 1
	ModifyTable/W=IRISpanel#PrologueTable title(wSchedule_Prologue_Action)="Event Function", alignment(wSchedule_Prologue_Action) = 1
	ModifyTable/W=IRISpanel#PrologueTable title(wSchedule_Prologue_Argument)="Function Argument", alignment(wSchedule_Prologue_Argument) = 0
	ModifyTable/W=IRISpanel#PrologueTable title(wSchedule_Prologue_Comment)="Comment", alignment(wSchedule_Prologue_Comment) = 0
	ModifyTable/W=IRISpanel#PrologueTable showParts = 2^3 + 2^4 + 2^5 + 2^1
	ModifyTable/W=IRISpanel#PrologueTable autosize={0, 0, 1, 0, 0 }
	ModifyTable/W=IRISpanel#PrologueTable width(wSchedule_Prologue_Comment) = 500
	SetActiveSubwindow ##
	SetWindow IRISpanel#PrologueTable, hide = 1
	verticalPositionSoFar += scheduleTableHeight
	
	// Create an embedded table to display the "Cycle" schedule resulting from the system parameters...
	TitleBox IRIS_CycleTitle_tabSchedule, disable = 1, pos = {panelMargin,verticalPositionSoFar}, size = {panelWidth,scheduleTitleHeight}, fSize=scheduleTitleFontSize, title = "CYCLE", frame = 0, anchor = LB
	verticalPositionSoFar += scheduleTitleHeight
	wave wSchedule_Cycle_WhichTimer = root:wSchedule_Cycle_WhichTimer
	wave wSchedule_Cycle_TriggerTime = root:wSchedule_Cycle_TriggerTime
	wave/T wSchedule_Cycle_Action = root:wSchedule_Cycle_Action
	wave/T wSchedule_Cycle_Argument = root:wSchedule_Cycle_Argument
	wave/T wSchedule_Cycle_Comment = root:wSchedule_Cycle_Comment
	Edit/HOST=IRISpanel/N=CycleTable/W=(panelMargin,verticalPositionSoFar,panelWidth-panelMargin,verticalPositionSoFar+scheduleTableHeight)/HIDE=0 wSchedule_Cycle_WhichTimer, wSchedule_Cycle_TriggerTime, wSchedule_Cycle_Action, wSchedule_Cycle_Argument, wSchedule_Cycle_Comment
	ModifyTable/W=IRISpanel#CycleTable frameStyle = 1, size = scheduleFontSize
	ModifyTable/W=IRISpanel#CycleTable alignment = 1
	ModifyTable/W=IRISpanel#CycleTable title(wSchedule_Cycle_WhichTimer)="Timer #", alignment(wSchedule_Cycle_WhichTimer) = 1
	ModifyTable/W=IRISpanel#CycleTable title(wSchedule_Cycle_TriggerTime)="Event Time (s)", alignment(wSchedule_Cycle_TriggerTime) = 1
	ModifyTable/W=IRISpanel#CycleTable title(wSchedule_Cycle_Action)="Event Function", alignment(wSchedule_Cycle_Action) = 1
	ModifyTable/W=IRISpanel#CycleTable title(wSchedule_Cycle_Argument)="Function Argument", alignment(wSchedule_Cycle_Argument) = 0
	ModifyTable/W=IRISpanel#CycleTable title(wSchedule_Cycle_Comment)="Comment", alignment(wSchedule_Cycle_Comment) = 0
	ModifyTable/W=IRISpanel#CycleTable showParts = 2^3 + 2^4 + 2^5 + 2^1
	ModifyTable/W=IRISpanel#CycleTable autosize={0, 0, 1, 0, 0 }
	ModifyTable/W=IRISpanel#CycleTable width(wSchedule_Cycle_Comment) = 500
	SetActiveSubwindow ##
	SetWindow IRISpanel#CycleTable, hide = 1
	verticalPositionSoFar += scheduleTableHeight
	
	// Create an embedded table to display the "Epilogue" schedule resulting from the system parameters...
	TitleBox IRIS_EpilogueTitle_tabSchedule, disable = 1, pos = {panelMargin,verticalPositionSoFar}, size = {panelWidth,scheduleTitleHeight}, fSize=scheduleTitleFontSize, title = "EPILOGUE", frame = 0, anchor = LB
	verticalPositionSoFar += scheduleTitleHeight
	wave wSchedule_Epilogue_WhichTimer = root:wSchedule_Epilogue_WhichTimer
	wave wSchedule_Epilogue_TriggerTime = root:wSchedule_Epilogue_TriggerTime
	wave/T wSchedule_Epilogue_Action = root:wSchedule_Epilogue_Action
	wave/T wSchedule_Epilogue_Argument = root:wSchedule_Epilogue_Argument
	wave/T wSchedule_Epilogue_Comment = root:wSchedule_Epilogue_Comment
	Edit/HOST=IRISpanel/N=EpilogueTable/W=(panelMargin,verticalPositionSoFar,panelWidth-panelMargin,verticalPositionSoFar+scheduleTableHeight)/HIDE=0 wSchedule_Epilogue_WhichTimer, wSchedule_Epilogue_TriggerTime, wSchedule_Epilogue_Action, wSchedule_Epilogue_Argument, wSchedule_Epilogue_Comment
	ModifyTable/W=IRISpanel#EpilogueTable frameStyle = 1, size = scheduleFontSize
	ModifyTable/W=IRISpanel#EpilogueTable alignment = 1
	ModifyTable/W=IRISpanel#EpilogueTable title(wSchedule_Epilogue_WhichTimer)="Timer #", alignment(wSchedule_Epilogue_WhichTimer) = 1
	ModifyTable/W=IRISpanel#EpilogueTable title(wSchedule_Epilogue_TriggerTime)="Event Time (s)", alignment(wSchedule_Epilogue_TriggerTime) = 1
	ModifyTable/W=IRISpanel#EpilogueTable title(wSchedule_Epilogue_Action)="Event Function", alignment(wSchedule_Epilogue_Action) = 1
	ModifyTable/W=IRISpanel#EpilogueTable title(wSchedule_Epilogue_Argument)="Function Argument", alignment(wSchedule_Epilogue_Argument) = 0
	ModifyTable/W=IRISpanel#EpilogueTable title(wSchedule_Epilogue_Comment)="Comment", alignment(wSchedule_Epilogue_Comment) = 0
	ModifyTable/W=IRISpanel#EpilogueTable showParts = 2^3 + 2^4 + 2^5 + 2^1
	ModifyTable/W=IRISpanel#EpilogueTable autosize={0, 0, 1, 0, 0 }
	ModifyTable/W=IRISpanel#EpilogueTable width(wSchedule_Epilogue_Comment) = 500
	SetActiveSubwindow ##
	SetWindow IRISpanel#EpilogueTable, hide = 1
	verticalPositionSoFar += scheduleTableHeight
	
	// Populate the "Data Filtering" tab...
	
	verticalPositionSoFar = panelTopMargin
	
	// Create an embedded table to show the data filtering parameters...
	Edit/HOST=IRISpanel/N=DataFilterTable/W=(panelMargin,verticalPositionSoFar,panelWidth-panelMargin,min(verticalPositionSoFar+dataFilterTableHeight,panelHeight-panelMargin))/HIDE=0 wtOutputVariableNames, wtDataFilterTable_CheckForOutliers, wtDataFilterTable_OutlierThresholds, wtDataFilterTable_FilterGroups
	ModifyTable/W=IRISpanel#DataFilterTable frameStyle = 1, size = tableFontSize, alignment(wtOutputVariableNames) = 2, alignment(wtDataFilterTable_CheckForOutliers) = 1, alignment(wtDataFilterTable_OutlierThresholds) = 1, alignment(wtDataFilterTable_FilterGroups) = 1
	ModifyTable/W=IRISpanel#DataFilterTable title(wtOutputVariableNames)= "Variable Name"
	ModifyTable/W=IRISpanel#DataFilterTable title(wtDataFilterTable_CheckForOutliers)= "Detect Outliers (y/n)?"
	ModifyTable/W=IRISpanel#DataFilterTable title(wtDataFilterTable_OutlierThresholds)= "Threshold (Std Devs)"
	ModifyTable/W=IRISpanel#DataFilterTable title(wtDataFilterTable_FilterGroups)= "Group #"
	ModifyTable/W=IRISpanel#DataFilterTable showParts = 39
	ModifyTable/W=IRISpanel#DataFilterTable autosize={0, 0, 1, 0, 0 }
	SetActiveSubwindow ##
	SetWindow IRISpanel#DataFilterTable, hide = 1
	
	// Populate the "Reanalysis" tab...
	
	ValDisplay chooseFilesLED_tabReanalyze,pos={runButtonLeftEdgePosition-LEDringThickness, verticalPositionAtBottomOfSampleID + panelMargin},size={chooseFilesButtonWidth+2*LEDringThickness,chooseFilesButtonHeight+2*LEDringThickness}
	ValDisplay chooseFilesLED_tabReanalyze,limits={0,1,0},barmisc={0,0},mode=2, frame = 0, disable = 1
	ValDisplay chooseFilesLED_tabReanalyze,value = #"IRIS_ChoosingFiles",zeroColor=(LEDr_chooseFiles_off,LEDg_chooseFiles_off,LEDb_chooseFiles_off),lowColor=(LEDr_chooseFiles_off,LEDg_chooseFiles_off,LEDb_chooseFiles_off),highColor=(LEDr_chooseFiles_on,LEDg_chooseFiles_on,LEDb_chooseFiles_on)
	Button IRIS_ChooseFiles_tabReanalyze, pos = {runButtonLeftEdgePosition, verticalPositionAtBottomOfSampleID + panelMargin + LEDringThickness}, size = {chooseFilesButtonWidth,chooseFilesButtonHeight}, proc = IRIS_GUI_ChooseFiles_ButtonProc, fSize = fileChoicefontSize, fstyle = 1, disable = 1, title = "Choose File(s)"
	
	ValDisplay reanalyzeLED_tabReanalyze,pos={runButtonLeftEdgePosition-LEDringThickness, verticalPositionAtBottomOfSampleID + panelMargin + chooseFilesButtonHeight + 2*LEDringThickness + runButtonVerticalSeparation},size={reanalyzeButtonWidth+2*LEDringThickness,reanalyzeButtonHeight+2*LEDringThickness}
	ValDisplay reanalyzeLED_tabReanalyze,limits={0,1,0},barmisc={0,0},mode=2, frame = 0, disable = 1
	ValDisplay reanalyzeLED_tabReanalyze,value = #"IRIS_Reanalyzing",zeroColor=(LEDr_reanalyze_off,LEDg_reanalyze_off,LEDb_reanalyze_off),lowColor=(LEDr_reanalyze_off,LEDg_reanalyze_off,LEDb_reanalyze_off),highColor=(LEDr_reanalyze_on,LEDg_reanalyze_on,LEDb_reanalyze_on)
	Button IRIS_Reanalyze_tabReanalyze, pos = {runButtonLeftEdgePosition, verticalPositionAtBottomOfSampleID + panelMargin + chooseFilesButtonHeight + 2*LEDringThickness + runButtonVerticalSeparation + LEDringThickness}, size = {reanalyzeButtonWidth,reanalyzeButtonHeight}, proc = IRIS_GUI_Reanalyze_ButtonProc, fSize = runFontSize, fstyle = 1, disable = 1, title = "REANALYZE"
	
	// Triggers a rebuild of the schedule whenever one of the embedded tables is modified...
	SetWindow IRISpanel, hook(IRISsystemTableHook) = IRIS_GUI_SystemTableEntryHook
	
	NVAR numSampleGases
	
	// Enforce limits on numbers of gases
	// NOTE: The limits are set in IRIS_BuildScheduleFunction but enforced here in the panel
	//       in order to trigger IRIS_GUI_ChangeNumGases_SetVariableProc and thereby update
	//       the config params and gas info table; that is important in the event that the
	//       config file includes a value that becomes out of bounds after a change to the
	//			limits in IRIS_BuildScheduleFunction.
	NVAR minNumSamples = root:minNumSamples
	NVAR maxNumSamples = root:maxNumSamples
	NVAR minNumRefs = root:minNumRefs
	NVAR maxNumRefs = root:maxNumRefs
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	NVAR numGases = root:numGases
	numSampleGases = max(numSampleGases, minNumSamples)
	numSampleGases = min(numSampleGases, maxNumSamples)
	numRefGases = max(numRefGases, minNumRefs)
	numRefGases = min(numRefGases, maxNumRefs)
	numGases = numSampleGases + numRefGases
	
End

Function/S IRIS_GUI_PopupWaveList_Gas()
	
	wave/T wtOutputGasNames = root:wtOutputGasNames
	
	variable i
	string list = ""
	for(i=0;i<numpnts(wtOutputGasNames);i+=1)
		list = list + wtOutputGasNames[i] + ";"
	endfor
	
	return list
End

Function/S IRIS_GUI_PopupWaveList_Variable1()
	
	wave/T wtOutputVariableNames = root:wtOutputVariableNames
	
//	NVAR numCalibratedOutputVariables = root:numCalibratedOutputVariables
	NVAR numOutputVariables = root:numOutputVariables
	NVAR numVariablesToAverage = root:numVariablesToAverage
	wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
	
	NVAR output1_gasID = root:output1_gasID
	NVAR numSampleGases = root:numSampleGases
	
	variable i, ii
	string list = ""
	if(output1_gasID < numSampleGases)
		for(i=0;i<numOutputVariables;i+=1)
			list = list + wtOutputVariableNames[i] + ";"
		endfor
	else
//		for(i=numCalibratedOutputVariables;i<numOutputVariables;i+=1)
//			list = list + wtOutputVariableNames[i] + ";"
//		endfor
		for(ii=0;ii<numVariablesToAverage;ii+=1)
			i = wIndicesOfVariablesToAverage[ii]
			list = list + wtOutputVariableNames[i] + ";"
		endfor
	endif
	
	return list
End

Function/S IRIS_GUI_PopupWaveList_Variable2()
	
	wave/T wtOutputVariableNames = root:wtOutputVariableNames
	
//	NVAR numCalibratedOutputVariables = root:numCalibratedOutputVariables
	NVAR numOutputVariables = root:numOutputVariables
	NVAR numVariablesToAverage = root:numVariablesToAverage
	wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
	
	NVAR output2_gasID = root:output2_gasID
	NVAR numSampleGases = root:numSampleGases
	
	variable i, ii
	string list = ""
	if(output2_gasID < numSampleGases)
		for(i=0;i<numOutputVariables;i+=1)
			list = list + wtOutputVariableNames[i] + ";"
		endfor
	else
//		for(i=numCalibratedOutputVariables;i<numOutputVariables;i+=1)
//			list = list + wtOutputVariableNames[i] + ";"
//		endfor
		for(ii=0;ii<numVariablesToAverage;ii+=1)
			i = wIndicesOfVariablesToAverage[ii]
			list = list + wtOutputVariableNames[i] + ";"
		endfor
	endif
	
	return list
End

Function/S IRIS_GUI_PopupWaveList_Variable3()
	
	wave/T wtOutputVariableNames = root:wtOutputVariableNames
	
//	NVAR numCalibratedOutputVariables = root:numCalibratedOutputVariables
	NVAR numOutputVariables = root:numOutputVariables
	NVAR numVariablesToAverage = root:numVariablesToAverage
	wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
	
	NVAR output3_gasID = root:output3_gasID
	NVAR numSampleGases = root:numSampleGases
	
	variable i, ii
	string list = ""
	if(output3_gasID < numSampleGases)
		for(i=0;i<numOutputVariables;i+=1)
			list = list + wtOutputVariableNames[i] + ";"
		endfor
	else
//		for(i=numCalibratedOutputVariables;i<numOutputVariables;i+=1)
//			list = list + wtOutputVariableNames[i] + ";"
//		endfor
		for(ii=0;ii<numVariablesToAverage;ii+=1)
			i = wIndicesOfVariablesToAverage[ii]
			list = list + wtOutputVariableNames[i] + ";"
		endfor
	endif
	
	return list
End

Function/S IRIS_GUI_PopupWaveList_VariableG1()
	
	wave/T wtOutputVariableNames = root:wtOutputVariableNames
	
//	NVAR numCalibratedOutputVariables = root:numCalibratedOutputVariables
	NVAR numOutputVariables = root:numOutputVariables
	NVAR numVariablesToAverage = root:numVariablesToAverage
	wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
	
	NVAR gasToGraph1 = root:gasToGraph1
	NVAR numSampleGases = root:numSampleGases
	
	variable i, ii
	string list = ""
	if(gasToGraph1 < numSampleGases)
		for(i=0;i<numOutputVariables;i+=1)
			list = list + wtOutputVariableNames[i] + ";"
		endfor
	else
//		for(i=numCalibratedOutputVariables;i<numOutputVariables;i+=1)
//			list = list + wtOutputVariableNames[i] + ";"
//		endfor
		for(ii=0;ii<numVariablesToAverage;ii+=1)
			i = wIndicesOfVariablesToAverage[ii]
			list = list + wtOutputVariableNames[i] + ";"
		endfor
	endif
	
	return list
End

Function/S IRIS_GUI_PopupWaveList_VariableG2()
	
	wave/T wtOutputVariableNames = root:wtOutputVariableNames
	
//	NVAR numCalibratedOutputVariables = root:numCalibratedOutputVariables
	NVAR numOutputVariables = root:numOutputVariables
	NVAR numVariablesToAverage = root:numVariablesToAverage
	wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
	
	NVAR gasToGraph2 = root:gasToGraph2
	NVAR numSampleGases = root:numSampleGases
	
	variable i, ii
	string list = ""
	if(gasToGraph2 < numSampleGases)
		for(i=0;i<numOutputVariables;i+=1)
			list = list + wtOutputVariableNames[i] + ";"
		endfor
	else
//		for(i=numCalibratedOutputVariables;i<numOutputVariables;i+=1)
//			list = list + wtOutputVariableNames[i] + ";"
//		endfor
		for(ii=0;ii<numVariablesToAverage;ii+=1)
			i = wIndicesOfVariablesToAverage[ii]
			list = list + wtOutputVariableNames[i] + ";"
		endfor
	endif
	
	return list
End

Function IRIS_GUI_TabProc(tca) : TabControl
	STRUCT WMTabControlAction &tca
	
	NVAR IRIS_Running = root:IRIS_Running
	NVAR IRIS_Standby = root:IRIS_Standby
	NVAR IRIS_ConfirmToRun = root:IRIS_ConfirmToRun
	NVAR IRIS_ConfirmToStop = root:IRIS_ConfirmToStop
	NVAR advOptionsHidden = root:advOptionsHidden
	NVAR isTabRunOrReanalyze = root:isTabRunOrReanalyze
	NVAR isTabGas = root:isTabGas
	NVAR isTabCal = root:isTabCal
	NVAR showSecondPlotOnGraph = root:showSecondPlotOnGraph
	NVAR numGasesControl_DisableStatus = root:numGasesControl_DisableStatus
	
	variable tabNum, isTabRun, isTabSystem, isTabSchedule, isTabFilter, isTabReanalyze
	
	switch (tca.eventCode)
		case 2: // Mouse up
			tabNum = tca.tab // Active tab number
			isTabRun = (tabNum == 0)
			isTabGas = (tabNum == 1)
			isTabCal = (tabNum == 2)
			isTabFilter = (tabNum == 3)
			isTabSystem = (tabNum == 4)
			isTabSchedule = (tabNum == 5)
			isTabReanalyze = (tabNum == 6)
			isTabRunOrReanalyze = ((isTabRun == 1) || (isTabReanalyze == 1))
			ModifyControlList ControlNameList("IRISpanel",";","*_tabRun") disable = !isTabRun
			ModifyControlList ControlNameList("IRISpanel",";","*_tabGas") disable = ((isTabGas == 1) ? numGasesControl_DisableStatus : 1)
			ModifyControlList ControlNameList("IRISpanel",";","*_tabCal") disable = !isTabCal
			ModifyControlList ControlNameList("IRISpanel",";","*_tabFilter") disable = !isTabFilter
			ModifyControlList ControlNameList("IRISpanel",";","*_tabSystem") disable = !isTabSystem
			ModifyControlList ControlNameList("IRISpanel",";","*_tabSchedule") disable = !isTabSchedule
			ModifyControlList ControlNameList("IRISpanel",";","*_tabReanalyze") disable = !isTabReanalyze
			ModifyControlList ControlNameList("IRISpanel",";","*_tabRunOrReanalyze") disable = !isTabRunOrReanalyze
			if(isTabRunOrReanalyze == 1)
				if(showSecondPlotOnGraph == 0)
					CheckBox IRIS_PlotSeparateAxisChoice_tabRunOrReanalyze, win=IRISpanel, disable = 2
					PopupMenu IRIS_PlotGasChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 2
					PopupMenu IRIS_PlotVariableChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 2
				endif
			endif
			SetWindow IRISpanel#ResultGraph, hide = !isTabRunOrReanalyze
			SetWindow IRISpanel#LogoSubwindowPanel_tabRunOrReanalyze, hide = !isTabRunOrReanalyze
			Notebook IRISpanel#StatusNotebook, visible = isTabRunOrReanalyze
			SetWindow IRISpanel#GasTable, hide = !isTabGas
			SetWindow IRISpanel#BasicSystemTable, hide = !isTabSystem
			SetWindow IRISpanel#AdvSystemTable, hide = ((!isTabSystem) || (advOptionsHidden == 1))
			SetWindow IRISpanel#PrologueTable, hide = !isTabSchedule
			SetWindow IRISpanel#CycleTable, hide = !isTabSchedule
			SetWindow IRISpanel#EpilogueTable, hide = !isTabSchedule
			SetWindow IRISpanel#DataFilterTable, hide = !isTabFilter
			IRIS_ConfirmToRun = 0
			if(IRIS_Running == 1)
				ModifyControl IRIS_Run_tabRun, win = IRISpanel, title = "RUNNING"
			else
				ModifyControl IRIS_Run_tabRun, win = IRISpanel, title = "RUN"
			endif
			IRIS_ConfirmToStop = 0
			ModifyControl IRIS_Stop_tabRun, win = IRISpanel, title = "STOP"
			break
	endswitch
	return 0
End

Function IRIS_GUI_Run_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	NVAR IRIS_Running = root:IRIS_Running
//	NVAR IRIS_Standby = root:IRIS_Standby
	NVAR IRIS_ConfirmToRun = root:IRIS_ConfirmToRun
	NVAR IRIS_ConfirmToStop = root:IRIS_ConfirmToStop
	NVAR IRIS_Reanalyzing = root:IRIS_Reanalyzing
	NVAR calCurveIsValid = root:calCurveIsValid
	
	SVAR sInstrumentID = root:sInstrumentID
	
	IRIS_UTILITY_ValidateGasInfo()
	NVAR gasInfoIsValid = root:gasInfoIsValid
	
	switch( ba.eventCode )
		case 2: // mouse up
			if(calCurveIsValid == 0)
				IRIS_EVENT_ReportStatus("CANNOT RUN: calibration curve is invalid")
			elseif(gasInfoIsValid == 0)
				IRIS_EVENT_ReportStatus("CANNOT RUN: gas info is invalid")
			else
				if(IRIS_Reanalyzing == 0)
					if(IRIS_Running == 0)
						if(IRIS_ConfirmToRun == 0)
							IRIS_ConfirmToRun = 1
							IRIS_ConfirmToStop = 0
							ModifyControl IRIS_Run_tabRun, win = IRISpanel, title = "CONFIRM?"
							ModifyControl IRIS_Stop_tabRun, win = IRISpanel, title = "STOP"
						else
							IRIS_Running = 1
							IRIS_ConfirmToRun = 0
							IRIS_ConfirmToStop = 0
							ModifyControl IRIS_Run_tabRun, win = IRISpanel, title = "RUNNING"
							ModifyControl IRIS_Stop_tabRun, win = IRISpanel, title = "STOP"
//							IRIS_Standby = 0
//							ModifyControl IRIS_Standby_tabRun, win = IRISpanel, title = "HEED EXT CMD"
//							IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", secs2time(DateTime,3) + "  " + "Stopped listening for external commands")
							IRIS_UTILITY_Run()
						endif
					else
						IRIS_ConfirmToStop = 0
						ModifyControl IRIS_Stop_tabRun, win = IRISpanel, title = "STOP"
					endif
				endif
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function IRIS_GUI_Standby_CheckBoxProc(CB_Struct) : CheckBoxControl
	STRUCT WMCheckboxAction &CB_Struct
	
	NVAR IRIS_Running = root:IRIS_Running
	NVAR IRIS_Standby = root:IRIS_Standby
	NVAR IRIS_ConfirmToRun = root:IRIS_ConfirmToRun
	NVAR IRIS_ConfirmToStop = root:IRIS_ConfirmToStop
	NVAR IRIS_Reanalyzing = root:IRIS_Reanalyzing
	NVAR calCurveIsValid = root:calCurveIsValid
	NVAR statusOutAgentPeriod = root:statusOutAgentPeriod
	NVAR extCmdQueueAgentPeriod = root:extCmdQueueAgentPeriod
	
	SVAR sInstrumentID = root:sInstrumentID
	
	wave/T instructionQueueForIRIS = root:instructionQueueForIRIS
	
	switch( CB_Struct.eventCode )
		case 2: // mouse up
			if(IRIS_Standby == 0)
				if(IRIS_Reanalyzing == 0)
					redimension/N=0 instructionQueueForIRIS
					IRIS_Standby = 1
					IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", secs2time(DateTime,3) + "  " + "Started listening for external commands")
					variable ticksAtStart = ticks 
					CtrlNamedBackground extCmdQueueAgent, proc = IRIS_UTILITY_ExtCmdQueueAgent, period = extCmdQueueAgentPeriod*60, start = ticksAtStart + extCmdQueueAgentPeriod*60
				endif
			else
				IRIS_Standby = 0
				IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", secs2time(DateTime,3) + "  " + "Stopped listening for external commands")
				CtrlNamedBackground extCmdQueueAgent, stop
			endif
			break
	endswitch

	return 0
End

Function IRIS_GUI_Stop_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	NVAR IRIS_Running = root:IRIS_Running
//	NVAR IRIS_Standby = root:IRIS_Standby
	NVAR IRIS_ConfirmToRun = root:IRIS_ConfirmToRun
	NVAR IRIS_ConfirmToStop = root:IRIS_ConfirmToStop
	NVAR IRIS_ShouldStartToStop = root:IRIS_ShouldStartToStop
	NVAR IRIS_Stopping = root:IRIS_Stopping
	
	SVAR ECL_clearQueue = root:ECL_clearQueue
	SVAR ECL_CloseAllValves = root:ECL_CloseAllValves
	SVAR sResultsFileTXT = root:sResultsFileTXT
	
	switch( ba.eventCode )
		case 2: // mouse up
			if((IRIS_Running == 1) && (IRIS_ShouldStartToStop == 0) && (IRIS_Stopping == 0))
				if(IRIS_ConfirmToStop == 0)
					IRIS_ConfirmToStop = 1
					ModifyControl IRIS_Stop_tabRun, win = IRISpanel, title = "CONFIRM?"
				else
					IRIS_ShouldStartToStop = 1
					IRIS_ConfirmToRun = 0
					IRIS_ConfirmToStop = 0
					ModifyControl IRIS_Stop_tabRun, win = IRISpanel, title = "STOPPING"
					IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", secs2time(DateTime,3) + "  " + "User clicked \"STOP\"")
				endif
			else
				if(IRIS_ConfirmToRun == 1)
					IRIS_ConfirmToRun = 0
					IRIS_ConfirmToStop = 0
					ModifyControl IRIS_Run_tabRun, win = IRISpanel, title = "RUN"
//				else
//					if(IRIS_Standby == 1)
//						IRIS_Standby = 0
//						ModifyControl IRIS_Standby_tabRun, win = IRISpanel, title = "HEED EXT CMD"
//						IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", secs2time(DateTime,3) + "  " + "Stopped listening for external commands")
//					endif
				endif
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function IRIS_GUI_ChooseFiles_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	NVAR IRIS_Running = root:IRIS_Running
	NVAR IRIS_Reanalyzing = root:IRIS_Reanalyzing
	NVAR IRIS_ChoosingFiles = root:IRIS_ChoosingFiles
	
	SVAR sInstrumentID = root:sInstrumentID
	SVAR sDataPathOnDisk = root:sDataPathOnDisk
	SVAR sDataPathOnDisk_Original = root:sDataPathOnDisk_Original
	
	wave/T wSTRrootNames = root:wSTRrootNames
	variable textStringLength
	variable nextCarriageReturn
	variable searchStart
	variable numberOfFiles
	variable thisFile
	variable preByte, postByte
	string sReanalysisFiles
	string sThisFilePathAndName
	string sThisFileRootName
	string sDataPathOnDisk_New
	
	string message = "Choose STR file(s) from a single run to reanalyze"
	string fileFilters = "STR Files:.str;"
	fileFilters += "All Files:.*;"
	
	variable refNum
	
	switch( ba.eventCode )
		case 2: // mouse up
			if(IRIS_Running == 0)
				if(IRIS_Reanalyzing == 0)
					
					IRIS_ChoosingFiles = 1
					sDataPathOnDisk = sDataPathOnDisk_Original
	
					// Empty the text wave of STR/STC file names
					redimension/N=0 wSTRrootNames
					
					// Clear the status window...
					Notebook IRISpanel#StatusNotebook, selection={startOfFile, endOfFile}
					Notebook IRISpanel#StatusNotebook, text = "STATUS"
					
					// Display dialog for selecting multiple files
					Open/D/R/MULT=1/P=STRLoadPath /F=fileFilters /M=message refNum
					sReanalysisFiles = S_fileName
					 
					// Parse sReanalysisFiles and assign file root names to the text wave of STR/STC file names
					textStringLength = strlen(sReanalysisFiles)
					searchStart = 0
					numberOfFiles = 0
					make/O/N=0 wLineEndBytes
					make/O/N=1 wLineEndTemp
					do
						nextCarriageReturn = StrSearch(sReanalysisFiles, "\r", searchStart)
						if(nextCarriageReturn >= 0)
							numberOfFiles += 1
							searchStart = nextCarriageReturn + 1 // "\r" counts as 1 byte
							wLineEndTemp[0] = nextCarriageReturn - 1
							concatenate/NP {wLineEndTemp}, wLineEndBytes
						endif
					while((nextCarriageReturn >= 0) && (searchStart < textStringLength))
					duplicate/O wLineEndBytes, wLineStartBytes
					wLineStartBytes += 2
					insertPoints 0, 1, wLineStartBytes
					wLineStartBytes[0] = 0
					redimension/N=(numberOfFiles) wLineStartBytes
					make/O/T/N=1 wtThisFileRootName
					for(thisFile=0;thisFile<numberOfFiles;thisFile+=1)
						sThisFilePathAndName = sReanalysisFiles[wLineStartBytes[thisFile], wLineEndBytes[thisFile]]
						preByte = strsearch(sThisFilePathAndName, ":", strlen(sThisFilePathAndName) - 1, 1)
						postByte = strsearch(sThisFilePathAndName, ".", strlen(sThisFilePathAndName) - 1, 1)
						sThisFileRootName = sThisFilePathAndName[preByte + 1, postByte - 1]
						sDataPathOnDisk_New = sThisFilePathAndName[0, preByte - 1]
						if(thisFile > 0)
							if(stringMatch(sDataPathOnDisk_New, sDataPathOnDisk) != 1)
								IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", "*** WARNING: All files must be in the same directory! ***")
								redimension/N=0 wSTRrootNames
								killwaves wLineEndTemp, wLineStartBytes, wLineEndBytes, wtThisFileRootName
								return 1
							endif
						endif
						sDataPathOnDisk = sDataPathOnDisk_New // overwrites the value of sDataPathOnDisk that was set in IRIS(), and so will need to be restored from sDataPathOnDisk_Original when reanalysis is done
						wtThisFileRootName[0] = sThisFileRootName
						concatenate/T/NP {wtThisFileRootName}, wSTRrootNames
					endfor
					Sort wSTRrootNames, wSTRrootNames
					
					IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", "The following files were selected for reanalysis:")
					for(thisFile=0;thisFile<numberOfFiles;thisFile+=1)
						IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", wSTRrootNames[thisFile] + " (.str/.stc)")
					endfor
					
					killwaves wLineEndTemp, wLineStartBytes, wLineEndBytes, wtThisFileRootName
					
					IRIS_ChoosingFiles = 0
					
				endif
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function IRIS_GUI_Reanalyze_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	NVAR IRIS_Running = root:IRIS_Running
	NVAR IRIS_Reanalyzing = root:IRIS_Reanalyzing
	
	SVAR sInstrumentID = root:sInstrumentID
	
	wave/T wSTRrootNames = root:wSTRrootNames
	
	switch( ba.eventCode )
		case 2: // mouse up
			if(IRIS_Running == 0)
				if(IRIS_Reanalyzing == 0)
					if(numpnts(wSTRrootNames) > 0)
						IRIS_Reanalyzing = 1
						ModifyControl IRIS_Reanalyze_tabReanalyze, win = IRISpanel, title = "REANALYZING"
						DoUpdate
						IRIS_UTILITY_Reanalyze()
					else
						IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", "*** WARNING: You must first choose files to reanalyze! ***")
					endif
				endif
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function IRIS_GUI_ShowDiagnostics_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	NVAR diagnosticsShown = root:diagnosticsShown
	
	switch( ba.eventCode )
		case 2: // mouse up
			if(diagnosticsShown == 0)
				IRIS_GUI_MakeDiagnosticGraph(0)
				ModifyControl IRIS_ShowDiagnostics_tabRunOrReanalyze, win = IRISpanel, title = "Hide Diagnostics"
				diagnosticsShown = 1
			else
				KillWindow/Z IRIS_DiagnosticGraph
				ModifyControl IRIS_ShowDiagnostics_tabRunOrReanalyze, win = IRISpanel, title = "Show Diagnostics"
				diagnosticsShown = 0
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function IRIS_GUI_ShowSecondPlotOnGraph_CheckBoxProc(CB_Struct) : CheckBoxControl
	STRUCT WMCheckboxAction &CB_Struct
	
	NVAR isTabRunOrReanalyze = root:isTabRunOrReanalyze
	
	NVAR showSecondPlotOnGraph = root:showSecondPlotOnGraph
	NVAR showSecondPlotOnGraph_old = root:showSecondPlotOnGraph_old
	NVAR useSeparateGraphAxis = root:useSeparateGraphAxis
	NVAR useSeparateGraphAxis_old = root:useSeparateGraphAxis_old
	
	NVAR variableToGraph1 = root:variableToGraph1
	NVAR variableToGraph2 = root:variableToGraph2
	NVAR graphFontSize = root:graphFontSize
	
	wave wOutputMeanToGraph1 = root:wOutputMeanToGraph1
	wave wOutputErrorToGraph1 = root:wOutputErrorToGraph1
	wave wOutputFilterToGraph1 = root:wOutputFilterToGraph1
	wave wOutputTimeToGraph1 = root:wOutputTimeToGraph1
	wave wOutputMeanToGraph2 = root:wOutputMeanToGraph2
	wave wOutputErrorToGraph2 = root:wOutputErrorToGraph2
	wave wOutputFilterToGraph2 = root:wOutputFilterToGraph2
	wave wOutputTimeToGraph2 = root:wOutputTimeToGraph2
	
	wave/T wtOutputVariableNames = root:wtOutputVariableNames
	wave/T wtOutputVariableUnits = root:wtOutputVariableUnits
	
	string sYaxisLabel
	
	switch(CB_Struct.eventCode)
		case 2:		// Mouse up
			showSecondPlotOnGraph = CB_Struct.checked
			if(showSecondPlotOnGraph != showSecondPlotOnGraph_old)
				if(showSecondPlotOnGraph == 1)
					if(isTabRunOrReanalyze == 1)
						CheckBox IRIS_PlotSeparateAxisChoice_tabRunOrReanalyze, win=IRISpanel, disable = 0
						PopupMenu IRIS_PlotGasChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 0
						PopupMenu IRIS_PlotVariableChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 0
					endif
					if(useSeparateGraphAxis == 1)
						AppendToGraph/W=IRISpanel#ResultGraph/R wOutputMeanToGraph2 vs wOutputTimeToGraph2
						ReorderTraces/W=IRISpanel#ResultGraph wOutputMeanToGraph1,{wOutputMeanToGraph2}
						ModifyGraph/W=IRISpanel#ResultGraph axRGB(left)=(16385,28398,65535), alblRGB(left)=(16385,28398,65535), tlblRGB(left)=(16385,28398,65535)
						ModifyGraph/W=IRISpanel#ResultGraph axRGB(right)=(30583,30583,30583), alblRGB(right)=(30583,30583,30583), tlblRGB(right)=(30583,30583,30583)
						sYaxisLabel = wtOutputVariableNames[variableToGraph1] + " (" + wtOutputVariableUnits[variableToGraph1] + ")"
						Label/W=IRISpanel#ResultGraph Left sYaxisLabel
						sYaxisLabel = wtOutputVariableNames[variableToGraph2] + " (" + wtOutputVariableUnits[variableToGraph2] + ")"
						Label/W=IRISpanel#ResultGraph Right sYaxisLabel
						ModifyGraph/W=IRISpanel#ResultGraph lblMargin(right)=5
						ModifyGraph/W=IRISpanel#ResultGraph mode(wOutputMeanToGraph2)=3, rgb(wOutputMeanToGraph2)=(30583,30583,30583), marker(wOutputMeanToGraph2)=16, msize(wOutputMeanToGraph2) = 5, mrkThick(wOutputMeanToGraph2)=2
						ErrorBars/W=IRISpanel#ResultGraph wOutputMeanToGraph2 Y, wave=(wOutputErrorToGraph2,wOutputErrorToGraph2)
						ModifyGraph/W=IRISpanel#ResultGraph zmrkNum(wOutputMeanToGraph2)={wOutputFilterToGraph2}
						ModifyGraph/W=IRISpanel#ResultGraph fSize(right) = graphFontSize
					else
						AppendToGraph/W=IRISpanel#ResultGraph/L wOutputMeanToGraph2 vs wOutputTimeToGraph2
						ReorderTraces/W=IRISpanel#ResultGraph wOutputMeanToGraph1,{wOutputMeanToGraph2}
						ModifyGraph/W=IRISpanel#ResultGraph axRGB(left)=(0,0,0), alblRGB(left)=(0,0,0), tlblRGB(left)=(0,0,0)
						sYaxisLabel = "\K(16385,28398,65535)" + wtOutputVariableNames[variableToGraph1] + " (" + wtOutputVariableUnits[variableToGraph1] + ")\r\n\K(30583,30583,30583)" + wtOutputVariableNames[variableToGraph2] + " (" + wtOutputVariableUnits[variableToGraph2] + ")"
						Label/W=IRISpanel#ResultGraph Left sYaxisLabel
						ModifyGraph/W=IRISpanel#ResultGraph mode(wOutputMeanToGraph2)=3, rgb(wOutputMeanToGraph2)=(30583,30583,30583), marker(wOutputMeanToGraph2)=16, msize(wOutputMeanToGraph2) = 5, mrkThick(wOutputMeanToGraph2)=2
						ErrorBars/W=IRISpanel#ResultGraph wOutputMeanToGraph2 Y, wave=(wOutputErrorToGraph2,wOutputErrorToGraph2)
						ModifyGraph/W=IRISpanel#ResultGraph zmrkNum(wOutputMeanToGraph2)={wOutputFilterToGraph2}
					endif
				else
					if(isTabRunOrReanalyze == 1)
						CheckBox IRIS_PlotSeparateAxisChoice_tabRunOrReanalyze, win=IRISpanel, disable = 2
						PopupMenu IRIS_PlotGasChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 2
						PopupMenu IRIS_PlotVariableChoice2_tabRunOrReanalyze, win=IRISpanel, disable = 2
					endif
					RemoveFromGraph/W=IRISpanel#ResultGraph wOutputMeanToGraph2
					sYaxisLabel = wtOutputVariableNames[variableToGraph1] + " (" + wtOutputVariableUnits[variableToGraph1] + ")"
					Label/W=IRISpanel#ResultGraph Left sYaxisLabel
					ModifyGraph/W=IRISpanel#ResultGraph axRGB(left)=(0,0,0), alblRGB(left)=(0,0,0), tlblRGB(left)=(0,0,0)
				endif
			endif
			showSecondPlotOnGraph_old = showSecondPlotOnGraph
			break
	endswitch
	
	return 0
End

Function IRIS_GUI_OneOrTwoGraphAxes_CheckBoxProc(CB_Struct) : CheckBoxControl
	STRUCT WMCheckboxAction &CB_Struct
	
	NVAR useSeparateGraphAxis = root:useSeparateGraphAxis
	NVAR useSeparateGraphAxis_old = root:useSeparateGraphAxis_old
	
	NVAR variableToGraph1 = root:variableToGraph1
	NVAR variableToGraph2 = root:variableToGraph2
	NVAR graphFontSize = root:graphFontSize
	
	wave wOutputMeanToGraph1 = root:wOutputMeanToGraph1
	wave wOutputErrorToGraph1 = root:wOutputErrorToGraph1
	wave wOutputFilterToGraph1 = root:wOutputFilterToGraph1
	wave wOutputTimeToGraph1 = root:wOutputTimeToGraph1
	wave wOutputMeanToGraph2 = root:wOutputMeanToGraph2
	wave wOutputErrorToGraph2 = root:wOutputErrorToGraph2
	wave wOutputFilterToGraph2 = root:wOutputFilterToGraph2
	wave wOutputTimeToGraph2 = root:wOutputTimeToGraph2
	
	wave/T wtOutputVariableNames = root:wtOutputVariableNames
	wave/T wtOutputVariableUnits = root:wtOutputVariableUnits
	
	string sYaxisLabel
	
	switch(CB_Struct.eventCode)
		case 2:		// Mouse up
			useSeparateGraphAxis = CB_Struct.checked
			if(useSeparateGraphAxis != useSeparateGraphAxis_old)
				if(useSeparateGraphAxis == 1)
					RemoveFromGraph/W=IRISpanel#ResultGraph wOutputMeanToGraph2
					AppendToGraph/W=IRISpanel#ResultGraph/R wOutputMeanToGraph2 vs wOutputTimeToGraph2
					ReorderTraces/W=IRISpanel#ResultGraph wOutputMeanToGraph1,{wOutputMeanToGraph2}
					ModifyGraph/W=IRISpanel#ResultGraph axRGB(left)=(16385,28398,65535), alblRGB(left)=(16385,28398,65535), tlblRGB(left)=(16385,28398,65535)
					ModifyGraph/W=IRISpanel#ResultGraph axRGB(right)=(30583,30583,30583), alblRGB(right)=(30583,30583,30583), tlblRGB(right)=(30583,30583,30583)
					sYaxisLabel = wtOutputVariableNames[variableToGraph1] + " (" + wtOutputVariableUnits[variableToGraph1] + ")"
					Label/W=IRISpanel#ResultGraph Left sYaxisLabel
					sYaxisLabel = wtOutputVariableNames[variableToGraph2] + " (" + wtOutputVariableUnits[variableToGraph2] + ")"
					Label/W=IRISpanel#ResultGraph Right sYaxisLabel
					ModifyGraph/W=IRISpanel#ResultGraph lblMargin(right)=5
					ModifyGraph/W=IRISpanel#ResultGraph mode(wOutputMeanToGraph2)=3, rgb(wOutputMeanToGraph2)=(30583,30583,30583), marker(wOutputMeanToGraph2)=16, msize(wOutputMeanToGraph2) = 5, mrkThick(wOutputMeanToGraph2)=2
					ErrorBars/W=IRISpanel#ResultGraph wOutputMeanToGraph2 Y, wave=(wOutputErrorToGraph2,wOutputErrorToGraph2)
					ModifyGraph/W=IRISpanel#ResultGraph zmrkNum(wOutputMeanToGraph2)={wOutputFilterToGraph2}
					ModifyGraph/W=IRISpanel#ResultGraph fSize(right) = graphFontSize
				else
					RemoveFromGraph/W=IRISpanel#ResultGraph wOutputMeanToGraph2
					AppendToGraph/W=IRISpanel#ResultGraph/L wOutputMeanToGraph2 vs wOutputTimeToGraph2
					ReorderTraces/W=IRISpanel#ResultGraph wOutputMeanToGraph1,{wOutputMeanToGraph2}
					ModifyGraph/W=IRISpanel#ResultGraph axRGB(left)=(0,0,0), alblRGB(left)=(0,0,0), tlblRGB(left)=(0,0,0)
					sYaxisLabel = "\K(16385,28398,65535)" + wtOutputVariableNames[variableToGraph1] + " (" + wtOutputVariableUnits[variableToGraph1] + ")\r\n\K(30583,30583,30583)" + wtOutputVariableNames[variableToGraph2] + " (" + wtOutputVariableUnits[variableToGraph2] + ")"
					Label/W=IRISpanel#ResultGraph Left sYaxisLabel
					ModifyGraph/W=IRISpanel#ResultGraph mode(wOutputMeanToGraph2)=3, rgb(wOutputMeanToGraph2)=(30583,30583,30583), marker(wOutputMeanToGraph2)=16, msize(wOutputMeanToGraph2) = 5, mrkThick(wOutputMeanToGraph2)=2
					ErrorBars/W=IRISpanel#ResultGraph wOutputMeanToGraph2 Y, wave=(wOutputErrorToGraph2,wOutputErrorToGraph2)
					ModifyGraph/W=IRISpanel#ResultGraph zmrkNum(wOutputMeanToGraph2)={wOutputFilterToGraph2}
				endif
			endif
			useSeparateGraphAxis_old = useSeparateGraphAxis
			break
	endswitch
	
	return 0
End

Function IRIS_GUI_SelectGas1_PopupMenuProc(PU_Struct) : PopupMenuControl
	STRUCT WMPopupAction &PU_Struct
	
	variable V_value
	variable popupIndex
	
	switch( PU_Struct.eventCode )
		case 2: // mouse up
			
			NVAR output1_gasID = root:output1_gasID
			NVAR output1_variableID = root:output1_variableID
			NVAR numSampleGases = root:numSampleGases
//			NVAR numCalibratedOutputVariables = root:numCalibratedOutputVariables
			NVAR numVariablesToAverage = root:numVariablesToAverage
			wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
						
			output1_gasID = PU_Struct.popNum - 1
			if(output1_gasID >= numSampleGases)
//				output1_variableID = max(numCalibratedOutputVariables, output1_variableID)
//				PopupMenu IRIS_VariableChoice1_tabRunOrReanalyze, win = IRISpanel, mode = output1_variableID + 1 - numCalibratedOutputVariables, value = IRIS_GUI_PopupWaveList_Variable1()
				FindValue/V=(output1_variableID) wIndicesOfVariablesToAverage
				if(V_value < 0)
					output1_variableID = wIndicesOfVariablesToAverage[0]
					popupIndex = 1
				else
					popupIndex = V_value + 1
				endif
			else
				popupIndex = output1_variableID + 1
			endif
			PopupMenu IRIS_VariableChoice1_tabRunOrReanalyze, win = IRISpanel, mode = popupIndex, value = IRIS_GUI_PopupWaveList_Variable1()
			IRIS_UTILITY_PopulateNumericOutput(1)
			
			wave/T wtDisplayFormat = root:wtDisplayFormat
			SetVariable IRIS_OutputMean1_tabRunOrReanalyze, format = wtDisplayFormat[0]
			SetVariable IRIS_OutputStErr1_tabRunOrReanalyze, format = wtDisplayFormat[0]
			
			break
	endswitch
	
	return 0
	
End

Function IRIS_GUI_SelectGas2_PopupMenuProc(PU_Struct) : PopupMenuControl
	STRUCT WMPopupAction &PU_Struct
	
	variable V_value
	variable popupIndex
	
	switch( PU_Struct.eventCode )
		case 2: // mouse up
			
			NVAR output2_gasID = root:output2_gasID
			NVAR output2_variableID = root:output2_variableID
			NVAR numSampleGases = root:numSampleGases
//			NVAR numCalibratedOutputVariables = root:numCalibratedOutputVariables
			NVAR numVariablesToAverage = root:numVariablesToAverage
			wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
			
			output2_gasID = PU_Struct.popNum - 1
			if(output2_gasID >= numSampleGases)
//				output2_variableID = max(numCalibratedOutputVariables, output2_variableID)
//				PopupMenu IRIS_VariableChoice2_tabRunOrReanalyze, win = IRISpanel, mode = output2_variableID + 1 - numCalibratedOutputVariables, value = IRIS_GUI_PopupWaveList_Variable2()
				FindValue/V=(output2_variableID) wIndicesOfVariablesToAverage
				if(V_value < 0)
					output2_variableID = wIndicesOfVariablesToAverage[0]
					popupIndex = 1
				else
					popupIndex = V_value + 1
				endif
			else
				popupIndex = output2_variableID + 1
			endif
			PopupMenu IRIS_VariableChoice2_tabRunOrReanalyze, win = IRISpanel, mode = popupIndex, value = IRIS_GUI_PopupWaveList_Variable2()
			IRIS_UTILITY_PopulateNumericOutput(2)
			
			wave/T wtDisplayFormat = root:wtDisplayFormat
			SetVariable IRIS_OutputMean2_tabRunOrReanalyze, format = wtDisplayFormat[1]
			SetVariable IRIS_OutputStErr2_tabRunOrReanalyze, format = wtDisplayFormat[1]
			
			break
	endswitch
	
	return 0
	
End

Function IRIS_GUI_SelectGas3_PopupMenuProc(PU_Struct) : PopupMenuControl
	STRUCT WMPopupAction &PU_Struct
	
	variable V_value
	variable popupIndex
	
	switch( PU_Struct.eventCode )
		case 2: // mouse up
			
			NVAR output3_gasID = root:output3_gasID
			NVAR output3_variableID = root:output3_variableID
			NVAR numSampleGases = root:numSampleGases
//			NVAR numCalibratedOutputVariables = root:numCalibratedOutputVariables
			NVAR numVariablesToAverage = root:numVariablesToAverage
			wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
			
			output3_gasID = PU_Struct.popNum - 1
			if(output3_gasID >= numSampleGases)
//				output3_variableID = max(numCalibratedOutputVariables, output3_variableID)
//				PopupMenu IRIS_VariableChoice3_tabRunOrReanalyze, win = IRISpanel, mode = output3_variableID + 1 - numCalibratedOutputVariables, value = IRIS_GUI_PopupWaveList_Variable3()
				FindValue/V=(output3_variableID) wIndicesOfVariablesToAverage
				if(V_value < 0)
					output3_variableID = wIndicesOfVariablesToAverage[0]
					popupIndex = 1
				else
					popupIndex = V_value + 1
				endif
			else
				popupIndex = output3_variableID + 1
			endif
			PopupMenu IRIS_VariableChoice3_tabRunOrReanalyze, win = IRISpanel, mode = popupIndex, value = IRIS_GUI_PopupWaveList_Variable3()
			IRIS_UTILITY_PopulateNumericOutput(3)
			
			wave/T wtDisplayFormat = root:wtDisplayFormat
			SetVariable IRIS_OutputMean3_tabRunOrReanalyze, format = wtDisplayFormat[2]
			SetVariable IRIS_OutputStErr3_tabRunOrReanalyze, format = wtDisplayFormat[2]
			
			break
	endswitch
	
	return 0
	
End

Function IRIS_GUI_SelectPlotGas1_PopupMenuProc(PU_Struct) : PopupMenuControl
	STRUCT WMPopupAction &PU_Struct
	
	variable V_value
	variable popupIndex
	
	switch( PU_Struct.eventCode )
		case 2: // mouse up
						
			NVAR gasToGraph1 = root:gasToGraph1
			NVAR variableToGraph1 = root:variableToGraph1
			NVAR numSampleGases = root:numSampleGases
//			NVAR numCalibratedOutputVariables = root:numCalibratedOutputVariables
			NVAR numVariablesToAverage = root:numVariablesToAverage
			wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
			
			gasToGraph1 = PU_Struct.popNum - 1
			if(gasToGraph1 >= numSampleGases)
//				variableToGraph1 = max(numCalibratedOutputVariables, variableToGraph1)
//				PopupMenu IRIS_PlotVariableChoice1_tabRunOrReanalyze, win = IRISpanel, mode = variableToGraph1 + 1 - numCalibratedOutputVariables, value = IRIS_GUI_PopupWaveList_VariableG1()
				FindValue/V=(variableToGraph1) wIndicesOfVariablesToAverage
				if(V_value < 0)
					variableToGraph1 = wIndicesOfVariablesToAverage[0]
					popupIndex = 1
				else
					popupIndex = V_value + 1
				endif
			else
				popupIndex = variableToGraph1 + 1
			endif
			PopupMenu IRIS_PlotVariableChoice1_tabRunOrReanalyze, win = IRISpanel, mode = popupIndex, value = IRIS_GUI_PopupWaveList_VariableG1()
			IRIS_UTILITY_PopulateGraphOutput()
			
			break
	endswitch
	
	return 0
	
End

Function IRIS_GUI_SelectPlotGas2_PopupMenuProc(PU_Struct) : PopupMenuControl
	STRUCT WMPopupAction &PU_Struct
	
	variable V_value
	variable popupIndex
	
	switch( PU_Struct.eventCode )
		case 2: // mouse up
						
			NVAR gasToGraph2 = root:gasToGraph2
			NVAR variableToGraph2 = root:variableToGraph2
			NVAR numSampleGases = root:numSampleGases
//			NVAR numCalibratedOutputVariables = root:numCalibratedOutputVariables
			NVAR numVariablesToAverage = root:numVariablesToAverage
			wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
			
			gasToGraph2 = PU_Struct.popNum - 1
			if(gasToGraph2 >= numSampleGases)
//				variableToGraph2 = max(numCalibratedOutputVariables, variableToGraph2)
//				PopupMenu IRIS_PlotVariableChoice2_tabRunOrReanalyze, win = IRISpanel, mode = variableToGraph2 + 1 - numCalibratedOutputVariables, value = IRIS_GUI_PopupWaveList_VariableG2()
				FindValue/V=(variableToGraph2) wIndicesOfVariablesToAverage
				if(V_value < 0)
					variableToGraph2 = wIndicesOfVariablesToAverage[0]
					popupIndex = 1
				else
					popupIndex = V_value + 1
				endif
			else
				popupIndex = variableToGraph2 + 1
			endif
			PopupMenu IRIS_PlotVariableChoice2_tabRunOrReanalyze, win = IRISpanel, mode = popupIndex, value = IRIS_GUI_PopupWaveList_VariableG2()
			IRIS_UTILITY_PopulateGraphOutput()
			
			break
	endswitch
	
	return 0
	
End

Function IRIS_GUI_SelectVariable1_PopupMenuProc(PU_Struct) : PopupMenuControl
	STRUCT WMPopupAction &PU_Struct
	
	switch( PU_Struct.eventCode )
		case 2: // mouse up
			
			NVAR output1_gasID = root:output1_gasID
			NVAR output1_variableID = root:output1_variableID
			NVAR numSampleGases = root:numSampleGases
//			NVAR numCalibratedOutputVariables = root:numCalibratedOutputVariables
			NVAR numVariablesToAverage = root:numVariablesToAverage
			wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
			
			if(output1_gasID >= numSampleGases)
//				output1_variableID = numCalibratedOutputVariables + PU_Struct.popNum - 1
				output1_variableID = wIndicesOfVariablesToAverage[PU_Struct.popNum - 1]
			else
				output1_variableID = PU_Struct.popNum - 1
			endif
			IRIS_UTILITY_PopulateNumericOutput(1)
			
			wave/T wtDisplayFormat = root:wtDisplayFormat
			SetVariable IRIS_OutputMean1_tabRunOrReanalyze, format = wtDisplayFormat[0]
			SetVariable IRIS_OutputStErr1_tabRunOrReanalyze, format = wtDisplayFormat[0]
			
			break
	endswitch
	
	return 0
	
End

Function IRIS_GUI_SelectVariable2_PopupMenuProc(PU_Struct) : PopupMenuControl
	STRUCT WMPopupAction &PU_Struct
	
	switch( PU_Struct.eventCode )
		case 2: // mouse up
							
			NVAR output2_gasID = root:output2_gasID
			NVAR output2_variableID = root:output2_variableID
			NVAR numSampleGases = root:numSampleGases
//			NVAR numCalibratedOutputVariables = root:numCalibratedOutputVariables
			NVAR numVariablesToAverage = root:numVariablesToAverage
			wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
			
			if(output2_gasID >= numSampleGases)
//				output2_variableID = numCalibratedOutputVariables + PU_Struct.popNum - 1
				output2_variableID = wIndicesOfVariablesToAverage[PU_Struct.popNum - 1]
			else
				output2_variableID = PU_Struct.popNum - 1
			endif
			IRIS_UTILITY_PopulateNumericOutput(2)
			
			wave/T wtDisplayFormat = root:wtDisplayFormat
			SetVariable IRIS_OutputMean2_tabRunOrReanalyze, format = wtDisplayFormat[1]
			SetVariable IRIS_OutputStErr2_tabRunOrReanalyze, format = wtDisplayFormat[1]
			
			break
	endswitch
	
	return 0
	
End

Function IRIS_GUI_SelectVariable3_PopupMenuProc(PU_Struct) : PopupMenuControl
	STRUCT WMPopupAction &PU_Struct
	
	switch( PU_Struct.eventCode )
		case 2: // mouse up
			
			NVAR output3_gasID = root:output3_gasID
			NVAR output3_variableID = root:output3_variableID
			NVAR numSampleGases = root:numSampleGases
//			NVAR numCalibratedOutputVariables = root:numCalibratedOutputVariables
			NVAR numVariablesToAverage = root:numVariablesToAverage
			wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
			
			if(output3_gasID >= numSampleGases)
//				output3_variableID = numCalibratedOutputVariables + PU_Struct.popNum - 1
				output3_variableID = wIndicesOfVariablesToAverage[PU_Struct.popNum - 1]
			else
				output3_variableID = PU_Struct.popNum - 1
			endif
			IRIS_UTILITY_PopulateNumericOutput(3)
			
			wave/T wtDisplayFormat = root:wtDisplayFormat
			SetVariable IRIS_OutputMean3_tabRunOrReanalyze, format = wtDisplayFormat[2]
			SetVariable IRIS_OutputStErr3_tabRunOrReanalyze, format = wtDisplayFormat[2]
			
			break
	endswitch
	
	return 0
	
End

Function IRIS_GUI_SelectPlotVariable1_PopupMenuProc(PU_Struct) : PopupMenuControl
	STRUCT WMPopupAction &PU_Struct
	
	switch( PU_Struct.eventCode )
		case 2: // mouse up
			
			NVAR variableToGraph1 = root:variableToGraph1
			
			NVAR gasToGraph1 = root:gasToGraph1
			NVAR variableToGraph1 = root:variableToGraph1
			NVAR numSampleGases = root:numSampleGases
//			NVAR numCalibratedOutputVariables = root:numCalibratedOutputVariables
			NVAR numVariablesToAverage = root:numVariablesToAverage
			wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
			
			if(gasToGraph1 >= numSampleGases)
//				variableToGraph1 = numCalibratedOutputVariables + PU_Struct.popNum - 1
				variableToGraph1 = wIndicesOfVariablesToAverage[PU_Struct.popNum - 1]
			else
				variableToGraph1 = PU_Struct.popNum - 1
			endif
			IRIS_UTILITY_PopulateGraphOutput()
			
			break
	endswitch
	
	return 0
	
End

Function IRIS_GUI_SelectPlotVariable2_PopupMenuProc(PU_Struct) : PopupMenuControl
	STRUCT WMPopupAction &PU_Struct
	
	switch( PU_Struct.eventCode )
		case 2: // mouse up
			
			NVAR variableToGraph2 = root:variableToGraph2
			
			NVAR gasToGraph2 = root:gasToGraph2
			NVAR variableToGraph2 = root:variableToGraph2
			NVAR numSampleGases = root:numSampleGases
//			NVAR numCalibratedOutputVariables = root:numCalibratedOutputVariables
			NVAR numVariablesToAverage = root:numVariablesToAverage
			wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
			
			if(gasToGraph2 >= numSampleGases)
//				variableToGraph2 = numCalibratedOutputVariables + PU_Struct.popNum - 1
				variableToGraph2 = wIndicesOfVariablesToAverage[PU_Struct.popNum - 1]
			else
				variableToGraph2 = PU_Struct.popNum - 1
			endif
			IRIS_UTILITY_PopulateGraphOutput()
			
			break
	endswitch
	
	return 0
	
End

Function IRIS_GUI_ChangeCalCurve_SetVariableProc(SV_Struct) : SetVariableControl
	STRUCT WMSetVariableAction &SV_Struct
	
	SVAR sConfigFileName = root:sConfigFileName
	SVAR calEqnStr_UI = root:calEqnStr_UI
	NVAR calCurveIsValid = root:calCurveIsValid
	
	IRIS_UTILITY_ValidateCalCurveEqn()
	
	if(calCurveIsValid == 1)
		// Update config param value
		IRIS_UTILITY_SetParamValueByName( "Calibration Curve Equation", calEqnStr_UI)
		// Save the new config params to the .iris file
		string sWaveListStr = "wtParamNames;wtParamValues;wtParamUnits;"
		Save/O/J/DLIM=","/B/P=pIRISpath sWaveListStr as sConfigFileName
	endif
	
End

Function IRIS_GUI_ChangeNumGases_SetVariableProc(SV_Struct) : SetVariableControl
	STRUCT WMSetVariableAction &SV_Struct
		
	wave/T wtParamNames = root:wtParamNames
	wave/T wtParamValues = root:wtParamValues
	wave/T wtParamUnits = root:wtParamUnits
	
	NVAR numOutputVariables = root:numOutputVariables
	
	NVAR numGasParams = root:numGasParams
	NVAR numCalParams = root:numCalParams
	NVAR numBasicParams = root:numBasicParams
	NVAR numAdvancedParams = root:numAdvancedParams
	NVAR numFilterParams = root:numFilterParams
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	NVAR numGases = root:numGases
	
	NVAR numSampleGases_prev = root:numSampleGases_prev
	NVAR numRefGases_prev = root:numRefGases_prev
	
	NVAR output1_gasID = root:output1_gasID
	NVAR output2_gasID = root:output2_gasID
	NVAR output3_gasID = root:output3_gasID
	NVAR gasToGraph1 = root:gasToGraph1
	NVAR gasToGraph2 = root:gasToGraph2
	
	SVAR sConfigFileName = root:sConfigFileName
	SVAR sParamFunctionName = root:sParamFunctionName
	
	variable i
	variable numTabulatedParams = numGasParams + numCalParams + numBasicParams + numAdvancedParams + numFilterParams
	
	if((numSampleGases != numSampleGases_prev) || (numRefGases != numRefGases_prev))
	
		// Set aside a copy of the current config params names and values
		Duplicate/O/T wtParamNames, wtParamNames_old
		Duplicate/O/T wtParamValues, wtParamValues_old
	
		// Redefine the config params based on the new numSampleGases and/or numRefGases (all params will get default values for the moment)
		FUNCREF IRIS_UTILITY_ProtoFunc IRIS_ParamFunction = $sParamFunctionName
		IRIS_ParamFunction() // calls IRIS_SCHEME_DefineParams_XXXXX(), where XXXXX is the instrument type
	
		// For old params that still exist, overwrite the default config param values with those we set aside earlier
		string sThisParamName, sThisParamValue
		variable restoreOldValueForThisParam
		for(i=0;i<numTabulatedParams;i+=1) // only overwrites the tabulated params, not numSampleGases, numGasParams, etc.
			sThisParamName = wtParamNames_old[i]
			sThisParamValue = wtParamValues_old[i]
			restoreOldValueForThisParam = 1
			if(stringMatch(sThisParamName, "*ECL Index*") == 1) // don't restore old values of the ECL indices, as they might conflict with those for added gases (there is no reason for users to choose non-default values for the ECL indices)
				restoreOldValueForThisParam = 0
			endif
			if(restoreOldValueForThisParam == 1)
				IRIS_UTILITY_SetParamValueByName( sThisParamName, sThisParamValue )
			endif
		endfor
		killwaves wtParamNames_old, wtParamValues_old
	
		// Save the new config params to the .iris file
		string sWaveListStr = "wtParamNames;wtParamValues;wtParamUnits;"
		Save/O/J/DLIM=","/B/P=pIRISpath sWaveListStr as sConfigFileName
		
		// Propagate the new config params to the GUI tables
		IRIS_UTILITY_PropagateParamsToTables()
	
		// Create generic labels for the sample and reference gases to be measured 
		numGases = numSampleGases + numRefGases
		make/O/N=(numGases) wNumCompleteMeasurementsByGas = 1 // temporary value
		make/O/T/N=(numGases) wtOutputGasNames
		for(i=0;i<numSampleGases;i+=1)
			wtOutputGasNames[i] = "S" + num2str(i+1)
		endfor
		for(i=0;i<numRefGases;i+=1)
			wtOutputGasNames[numSampleGases+i] = "R" + num2str(i+1)
		endfor
	
		// Ensure the displays are not set to display a gas that no longer exists
		output1_gasID = min(output1_gasID, numGases - 1)
		output2_gasID = min(output2_gasID, numGases - 1)
		output3_gasID = min(output3_gasID, numGases - 1)
		gasToGraph1 = min(gasToGraph1, numGases - 1)
		gasToGraph2 = min(gasToGraph2, numGases - 1)
		PopupMenu IRIS_GasChoice1_tabRunOrReanalyze, win = IRISpanel, mode = output1_gasID + 1, value = IRIS_GUI_PopupWaveList_Gas()
		PopupMenu IRIS_GasChoice2_tabRunOrReanalyze, win = IRISpanel, mode = output2_gasID + 1, value = IRIS_GUI_PopupWaveList_Gas()
		PopupMenu IRIS_GasChoice3_tabRunOrReanalyze, win = IRISpanel, mode = output3_gasID + 1, value = IRIS_GUI_PopupWaveList_Gas()
		PopupMenu IRIS_PlotGasChoice1_tabRunOrReanalyze, win = IRISpanel, mode = gasToGraph1 + 1, value = IRIS_GUI_PopupWaveList_Gas()
		PopupMenu IRIS_PlotGasChoice2_tabRunOrReanalyze, win = IRISpanel, mode = gasToGraph2 + 1, value = IRIS_GUI_PopupWaveList_Gas()
	
		// Create waves of means, standard deviations, and standard errors of the output variables, for the numeric displays
		make/O/D/N=(numGases,numOutputVariables) wOutputMeans, wOutputStDevs, wOutputStErrs
		wOutputMeans[][] = NaN
		wOutputStDevs[][] = NaN
		wOutputStErrs[][] = NaN
	
		// Create matrix of time series of output variables
		variable numCycles = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Cycles"))
		make/O/D/N=(numGases,numOutputVariables,numCycles) wOutputTimeSeriesMatrix, wOutputTimeSeriesErrorMatrix, wOutputTimeSeriesFilterMatrix
		make/O/D/N=(numGases,numCycles) wOutputTime
		wOutputTimeSeriesMatrix[][][] = NaN
		wOutputTimeSeriesErrorMatrix[][][] = NaN
		wOutputTimeSeriesFilterMatrix[][][] = 0
		wOutputTime = q + 1
	
		// Updating the prev variables
		numSampleGases_prev = numSampleGases
		numRefGases_prev = numRefGases
	
		DoUpdate
	
	endif
	
	return 0
	
End

Function IRIS_GUI_SystemTableEntryHook(s)
	STRUCT WMWinHookStruct &s
	
	NVAR IRIS_Running = root:IRIS_Running
	NVAR IRIS_ConfirmToRun = root:IRIS_ConfirmToRun
	NVAR IRIS_ConfirmToStop = root:IRIS_ConfirmToStop
	NVAR IRIS_Reanalyzing = root:IRIS_Reanalyzing
	
	SVAR sConfigFileName = root:sConfigFileName
	SVAR sBuildScheduleFunctionName = root:sBuildScheduleFunctionName
	
	Variable hookResult = 0

	switch(s.eventCode)
		case 24:				// tableEntryAccepted
			if((IRIS_Running == 0) && (IRIS_ConfirmToRun == 0) && (IRIS_ConfirmToStop == 0) && (IRIS_Reanalyzing == 0))
				
				// Rebuild param waves from GUI tables...
				IRIS_UTILITY_RebuildParamWavesFromTables()
	
				// Save wtParamValues to the .iris file to record any user modifications to it, but restore wtParamNames and wtParamUnits from the .iris file to undo any user modifications to them...
				string sColumnStr = "F=-2,N=wtParamNames;F=-2,N=wtParamValuesOld;F=-2,N=wtParamUnits;"
				Loadwave/Q/P=pIRISpath/J/N/L={0, 0, 0, 0, 0}/B=sColumnStr sConfigFileName // /L={nameLine, firstLine, numLines, firstColumn, numColumns}
				wave/T wtParamValuesOld = root:wtParamValuesOld
				string sWaveListStr = "wtParamNames;wtParamValues;wtParamUnits;"
				Save/O/J/DLIM=","/B/P=pIRISpath sWaveListStr as sConfigFileName
				killwaves wtParamValuesOld
				
				// Propagate restored names and units to the basic and advanced option tables...
				IRIS_UTILITY_PropagateParamsToTables()
	
				FUNCREF IRIS_UTILITY_ProtoFunc IRIS_BuildScheduleFunction = $sBuildScheduleFunctionName
				IRIS_BuildScheduleFunction() // calls IRIS_SCHEME_BuildSchedule_XXXXX(), where XXXXX is the instrument type
				
			else
				
				// Restore the original table value because a run or reanalysis is underway...
				IRIS_UTILITY_PropagateParamsToTables()
				
			endif
			break
	endswitch

	return hookResult		// 0 if nothing done, else 1
	
End

Function IRIS_GUI_DiagnosticsKilledHook(s)
	STRUCT WMWinHookStruct &s
	
	NVAR diagnosticsShown = root:diagnosticsShown
	
	Variable hookResult = 0

	switch(s.eventCode)
		case 2:				// diagnostic graph window killed
			diagnosticsShown = 0
			DoWindow IRISpanel
			if(V_flag == 1)
				ModifyControl IRIS_ShowDiagnostics_tabRunOrReanalyze, win = IRISpanel, title = "Show Diagnostics"
			endif
			break
	endswitch

	return hookResult		// 0 if nothing done, else 1
	
End

Function IRIS_GUI_ShowAdvOptions_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	NVAR advOptionsHidden = root:advOptionsHidden
	
	switch( ba.eventCode )
		case 2: // mouse up
			if(advOptionsHidden == 1)
				SetWindow IRISpanel#AdvSystemTable, hide = 0
				ModifyControl IRIS_ShowAdvOptions_tabSystem, win = IRISpanel, title = "Hide Advanced Options"
				advOptionsHidden = 0
			else
				SetWindow IRISpanel#AdvSystemTable, hide = 1
				ModifyControl IRIS_ShowAdvOptions_tabSystem, win = IRISpanel, title = "Show Advanced Options"
				advOptionsHidden = 1
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function IRIS_GUI_MakeDiagnosticGraph(makeForSave)
	variable makeForSave // 0 to display diagnostic graph window, 1 to create a temporary hidden diagnostic graph window and save it to disk as a PNG image
	
	wave wDiagnosticMask_Ref = root:wDiagnosticMask_Ref
	wave wDiagnosticMask_Sample = root:wDiagnosticMask_Sample
	wave wDiagnosticMask_Time = root:wDiagnosticMask_Time
	wave wDiagnosticOutput1_highFreqData = root:wDiagnosticOutput1_highFreqData
	wave wDiagnosticOutput1_highFreqTime = root:wDiagnosticOutput1_highFreqTime
	wave wDiagnosticOutput2_highFreqData = root:wDiagnosticOutput2_highFreqData
	wave wDiagnosticOutput2_highFreqTime = root:wDiagnosticOutput2_highFreqTime
	wave wDiagnosticOutput3_highFreqData = root:wDiagnosticOutput3_highFreqData
	wave wDiagnosticOutput3_highFreqTime = root:wDiagnosticOutput3_highFreqTime
	
	wave wGasTextMarkerX = root:wGasTextMarkerX
	wave wGasTextMarkerY = root:wGasTextMarkerY
	wave/T wtGasTextMarkerString = root:wtGasTextMarkerString
	
	NVAR panelLeftEdgePosition = root:panelLeftEdgePosition
	NVAR panelTopEdgePosition = root:panelTopEdgePosition
	NVAR panelWidth = root:panelWidth
	NVAR panelHeight = root:panelHeight
	NVAR layoutPageWidth = root:layoutPageWidth
	NVAR layoutPageHeight = root:layoutPageHeight
	
	SVAR diagnosticOutput1_name = root:diagnosticOutput1_name
	SVAR diagnosticOutput1_units = root:diagnosticOutput1_units
	SVAR diagnosticOutput2_name = root:diagnosticOutput2_name
	SVAR diagnosticOutput2_units = root:diagnosticOutput2_units
	SVAR diagnosticOutput3_name = root:diagnosticOutput3_name
	SVAR diagnosticOutput3_units = root:diagnosticOutput3_units
	
	variable controlBarHeight = 22
	variable controlButtonWidth = 60
	variable infoBarHeightAllowance = 0 //44
	
	string sYaxisLabel
	
	NVAR diagnosticTime_scaleMin = root:diagnosticTime_scaleMin
	NVAR diagnosticTime_scaleMax = root:diagnosticTime_scaleMax
		
	NVAR diagnostic1_scaleMin = root:diagnostic1_scaleMin
	NVAR diagnostic1_scaleMax = root:diagnostic1_scaleMax
	NVAR diagnostic2_scaleMin = root:diagnostic2_scaleMin
	NVAR diagnostic2_scaleMax = root:diagnostic2_scaleMax
	NVAR diagnostic3_scaleMin = root:diagnostic3_scaleMin
	NVAR diagnostic3_scaleMax = root:diagnostic3_scaleMax
	
	variable diagnosticGraphLeftEdge = panelLeftEdgePosition + panelWidth + 10
	variable diagnosticGraphTopEdge = panelTopEdgePosition
	
	GetWindow/Z IRISpanel wsize
	if(V_flag == 0)
		diagnosticGraphLeftEdge = V_left + panelWidth + 10
		diagnosticGraphTopEdge = V_top
	endif
	
	string sDiagnosticGraphName
	if(makeForSave == 0)
		sDiagnosticGraphName = "IRIS_DiagnosticGraph"
		Display/K=1/N=$sDiagnosticGraphName/W=(diagnosticGraphLeftEdge, diagnosticGraphTopEdge, diagnosticGraphLeftEdge + panelWidth, diagnosticGraphTopEdge + panelHeight - infoBarHeightAllowance)/L=masks wDiagnosticMask_Ref,wDiagnosticMask_Sample vs wDiagnosticMask_Time as "Diagnostic Graph"
	else
		sDiagnosticGraphName = "IRISresultsGraphTemp"
		Display/HIDE=1/K=1/N=$sDiagnosticGraphName/W=(0, 0, layoutPageWidth, layoutPageHeight)/L=masks wDiagnosticMask_Ref,wDiagnosticMask_Sample vs wDiagnosticMask_Time as "Diagnostic Graph"
	endif
	AppendToGraph/W=$sDiagnosticGraphName wDiagnosticOutput1_highFreqData vs wDiagnosticOutput1_highFreqTime
	AppendToGraph/W=$sDiagnosticGraphName/L=left2 wDiagnosticOutput2_highFreqData vs wDiagnosticOutput2_highFreqTime
	AppendToGraph/W=$sDiagnosticGraphName/L=left3 wDiagnosticOutput3_highFreqData vs wDiagnosticOutput3_highFreqTime
	AppendToGraph/W=$sDiagnosticGraphName wGasTextMarkerY vs wGasTextMarkerX
	
	ModifyGraph/W=$sDiagnosticGraphName mode(wDiagnosticMask_Ref)=7, mode(wDiagnosticMask_Sample)=7
	ModifyGraph/W=$sDiagnosticGraphName mode(wDiagnosticOutput1_highFreqData)=3, mode(wDiagnosticOutput2_highFreqData)=3, mode(wDiagnosticOutput3_highFreqData)=3
	ModifyGraph/W=$sDiagnosticGraphName marker(wDiagnosticOutput1_highFreqData)=19, marker(wDiagnosticOutput2_highFreqData)=19, marker(wDiagnosticOutput3_highFreqData)=19
	ModifyGraph/W=$sDiagnosticGraphName lSize(wDiagnosticMask_Ref)=0,lSize(wDiagnosticMask_Sample)=0
	ModifyGraph/W=$sDiagnosticGraphName rgb(wDiagnosticMask_Ref)=(49151,53155,65535),rgb(wDiagnosticMask_Sample)=(65535,60076,49151)
	ModifyGraph/W=$sDiagnosticGraphName rgb(wDiagnosticOutput1_highFreqData)=(0,0,0), rgb(wDiagnosticOutput2_highFreqData)=(0,0,0), rgb(wDiagnosticOutput3_highFreqData)=(0,0,0)
	ModifyGraph/W=$sDiagnosticGraphName msize(wDiagnosticOutput1_highFreqData)=2, msize(wDiagnosticOutput2_highFreqData)=2, msize(wDiagnosticOutput3_highFreqData)=2
	ModifyGraph/W=$sDiagnosticGraphName hbFill(wDiagnosticMask_Ref)=2,hbFill(wDiagnosticMask_Sample)=2
	ModifyGraph/W=$sDiagnosticGraphName mode(wGasTextMarkerY)=3,rgb(wGasTextMarkerY)=(0,0,0),textMarker(wGasTextMarkerY)={wtGasTextMarkerString,"default",0,0,5,0.00,0.00}
	ModifyGraph/W=$sDiagnosticGraphName axRGB(masks)=(65535,65535,65535)
	ModifyGraph/W=$sDiagnosticGraphName tlblRGB(masks)=(65535,65535,65535)
	ModifyGraph/W=$sDiagnosticGraphName alblRGB(masks)=(65535,65535,65535)
	ModifyGraph/W=$sDiagnosticGraphName lblPos(left)=49
	ModifyGraph/W=$sDiagnosticGraphName axisOnTop(bottom)=1,axisOnTop(left)=1,axisOnTop(left2)=1,axisOnTop(left3)=1
	ModifyGraph/W=$sDiagnosticGraphName freePos(masks)=0
	ModifyGraph/W=$sDiagnosticGraphName freePos(left2)=0
	ModifyGraph/W=$sDiagnosticGraphName freePos(left3)=0
	ModifyGraph/W=$sDiagnosticGraphName axisEnab(left)={0.68,1}
	ModifyGraph/W=$sDiagnosticGraphName axisEnab(left2)={0.34,0.66}
	ModifyGraph/W=$sDiagnosticGraphName axisEnab(left3)={0,0.32}
	ModifyGraph/W=$sDiagnosticGraphName dateInfo(bottom)={0,0,0}
	
	Label/W=$sDiagnosticGraphName bottom " "
	sYaxisLabel = diagnosticOutput1_name + " (" + diagnosticOutput1_units + ")"
	Label/W=$sDiagnosticGraphName Left sYaxisLabel
	sYaxisLabel = diagnosticOutput2_name + " (" + diagnosticOutput2_units + ")"
	Label/W=$sDiagnosticGraphName Left2 sYaxisLabel
	sYaxisLabel = diagnosticOutput3_name + " (" + diagnosticOutput3_units + ")"
	Label/W=$sDiagnosticGraphName Left3 sYaxisLabel
	ModifyGraph/W=$sDiagnosticGraphName lblPosMode = 4, lblPos(left) = 60, lblPos(left2) = 60, lblPos(left3) = 60
	
	SetAxis/W=$sDiagnosticGraphName/A
	SetAxis/W=$sDiagnosticGraphName bottom diagnosticTime_scaleMin, diagnosticTime_scaleMax
	SetAxis/W=$sDiagnosticGraphName left diagnostic1_scaleMin, diagnostic1_scaleMax
	SetAxis/W=$sDiagnosticGraphName left2 diagnostic2_scaleMin, diagnostic2_scaleMax
	SetAxis/W=$sDiagnosticGraphName left3 diagnostic3_scaleMin, diagnostic3_scaleMax
	SetAxis/W=$sDiagnosticGraphName masks 0.4999, 0.5001
	
	ModifyGraph/W=$sDiagnosticGraphName gfSize=14
	
	if(makeForSave == 0)
		
		ControlBar/W=$sDiagnosticGraphName controlBarHeight
		Button tog_left, win = $sDiagnosticGraphName, pos={0,0},size={controlButtonWidth,controlBarHeight},proc=HGB2_buttons,title="<pan left<"
		Button tog_left, win = $sDiagnosticGraphName, help={"move horizontally to the left"}
		Button tog_right, win = $sDiagnosticGraphName, pos={controlButtonWidth,0},size={controlButtonWidth,controlBarHeight},proc=HGB2_buttons,title=">pan right>"
		Button tog_right, win = $sDiagnosticGraphName, help={"move horizontally to the right"}
		Button widen, win = $sDiagnosticGraphName, pos={2*controlButtonWidth,0},size={controlButtonWidth,controlBarHeight},proc=HGB2_buttons,title="<widen>"
		Button widen, win = $sDiagnosticGraphName, help={"zoom out"}
		Button narrow, win = $sDiagnosticGraphName, pos={3*controlButtonWidth,0},size={controlButtonWidth,controlBarHeight},proc=HGB2_buttons,title=">narrow<"
		Button narrow, win = $sDiagnosticGraphName, help={"zoom in"}
		Button scale_y, win = $sDiagnosticGraphName, pos={4*controlButtonWidth,0},size={controlButtonWidth,controlBarHeight},proc=HGB2_buttons,title="Scale Y"
		Button scale_y, win = $sDiagnosticGraphName, help={"Scale to show all data vertically"}
		Button some_y, win = $sDiagnosticGraphName, pos={5*controlButtonWidth,0},size={controlButtonWidth,controlBarHeight},proc=HGB2_buttons,title="Some Y"
		Button some_y, win = $sDiagnosticGraphName, help={"Scale Y ignoring outliers"}
		Button scale_x, win = $sDiagnosticGraphName, pos={6*controlButtonWidth,0},size={controlButtonWidth,controlBarHeight},proc=HGB2_buttons,title="Scale X"
		Button scale_x, win = $sDiagnosticGraphName, help={"Scale to show all data horizontally"}
		Button scale_all, win = $sDiagnosticGraphName, pos={7*controlButtonWidth,0},size={controlButtonWidth,controlBarHeight},proc=HGB2_buttons,title="Scale All"
		Button scale_all, win = $sDiagnosticGraphName, help={"Scale to show all data"}
		
		SetWindow $sDiagnosticGraphName, hook(IRISdiagnosticsKilledHook) = IRIS_GUI_DiagnosticsKilledHook // changes button title appropriately when user kills the diagnostic graph window the old fashioned way
		
	endif
	
End

///////////////////////////////////////////////////////////////
// IRIS's versions of the standard ECL analysis functions //
///////////////////////////////////////////////////////////////

Function IRIS_ECL_ParseAndCutIndex( index, [stc_time_w, stc_index_w, subfolderSuffix, tidyup, FirstLineIsStart, LastLineIsStop, SummaryTable] )
	Variable index
	Wave stc_time_w
	Wave stc_index_w
	String subfolderSuffix
	Variable tidyup
	Variable FirstLineIsStart
	Variable LastLineIsStop
	Variable SummaryTable
	
	String saveFolder = GetDataFolder(1);
	
	if( ParamIsDefault( stc_time_w ) )
		if(exists("root:stc_time") == 0)
			return 1
		endif
		Wave stc_time = root:stc_time	// a good default
	else
		if(exists("stc_time_w") == 0)
			return 1
		endif
		Wave stc_time = stc_time_w
	endif
		
	if( ParamIsDefault( stc_index_w ) )
		if(exists("root:stc_ECL_index") == 0)
			return 1
		endif
		Wave loc_index = root:stc_ECL_index	// a good default
	else
		if(exists("stc_index_w") == 0)
			return 1
		endif
		Wave loc_index = stc_index_w
	endif
	
	if(numpnts(loc_index) == 0)
		return 1
	endif
	
	String loc_suffix
	if( ParamIsDefault( subfolderSuffix ) )
		loc_suffix = "A"	// a good default
	else
		loc_suffix = subfolderSuffix
	endif
	
	Variable loc_tidyup
	if( ParamIsDefault( tidyup ) )
		loc_tidyup = 1;
	else
		loc_tidyup = tidyup
	endif
	
	Variable loc_FirstLineIsStart
	if( ParamIsDefault( FirstLineIsStart ) )
		loc_FirstLineIsStart = 0;
	else
		loc_FirstLineIsStart = FirstLineIsStart
	endif
	Variable loc_LastLineIsStop
	if( ParamIsDefault( LastLineIsStop ) )
		loc_LastLineIsStop = 0;
	else
		loc_LastLineIsStop = LastLineIsStop
	endif
	
	Variable loc_SummaryTable
	if( ParamIsDefault( SummaryTable ) )
		loc_SummaryTable = 1
	else
		loc_SummaryTable = SummaryTable
	endif
	
	SVAR/Z global_ECL_WorkFolder = root:gs_ECL_WorkFolder
	if( SVAR_Exists( global_ECL_WorkFolder ) != 1 )
		SetDataFolder root:
		String/G gs_ECL_WorkFolder
		sprintf gs_ECL_WorkFolder, "ECL_WorkFolder_%s", loc_suffix
		MakeAndOrSetDF( gs_ECL_WorkFolder )
		SetDataFolder $saveFolder
	endif
	SVAR global_ECL_WorkFolder = root:gs_ECL_WorkFolder

	if( !ParamIsDefault( subfolderSuffix ) )
		// This means the user is directing us somewhere else
		sprintf global_ECL_WorkFolder, "ECL_WorkFolder_%s", loc_suffix
		SetDataFolder root:
		MakeAndOrSetDF( global_ECL_WorkFolder )
	endif
	
	SetDataFolder root:
	MakeAndOrSetDF( global_ECL_WorkFolder )
	Variable idex, count, doTable = 0, bdex, edex
	String destStr
	
	// make the equivalent conc
	sprintf destStr, "ECL_%d_RawIndex", index
	Duplicate/O loc_index, $destStr
	Wave dw = $destStr
	
	dw = (loc_index == index) ? 1 : Nan
	
	Duplicate/O dw, ECL_Temp_all, ECL_Temp_d
	ECL_Temp_all = numtype( dw ) == 0 ? 1 : 0
	ECL_Temp_d = ECL_Temp_all 
	Differentiate/METH=1 ECL_Temp_d
	ECL_Temp_d[numpnts(ECL_Temp_d) - 1] = 0 // the last point is meaningless when using forward differences (METH = 1 in Differentiate, above) 
	
	if(sum(ECL_Temp_all) == 0)
		SetDataFolder $saveFolder
		return 1
	endif
	
	sprintf destStr, "ECL_%dWin", index
	if( loc_SummaryTable )
		DoWindow $destStr
		if( V_Flag )	
			DoWindow/F $destStr
		else
			Edit/K=1 as destStr; DoWindow/C $destStr
			doTable = 1
		endif
	endif
	
	sprintf destStr, "ECL_%d_StartTime", index
	Make/N=0/O/D $destStr
	Wave ECL_StartTime = $destStr
	sprintf destStr, "ECL_%d_StopTime", index
	Make/N=0/O/D $destStr
	Wave ECL_StopTime = $destStr
	SetScale/P y, 0,0, "dat", ECL_StartTime, ECL_StopTime
	
	Variable startingGun = 0
	
	count = numpnts( ECL_Temp_d )
	for( idex = 0; idex < count; idex += 1 )
		if( ECL_Temp_d[ idex ] == 1 )
			AppendVal( ECL_StartTime, stc_time[ idex + 1 ] )
			startingGun = 1
		endif
		if( (ECL_Temp_d[ idex ] == -1) & startingGun )
			AppendVal( ECL_StopTime, stc_time[ idex ] )
		else
			if( (startingGun == 0) & (ECL_Temp_d[ idex ] == -1) )
				// then this indicates a Stop before a Start...
				// the solutions will be to indicate the problem and skip or honor the optional argument loc_FirstLineIsStart
				if( loc_FirstLineIsStart )
					AppendVal( ECL_StartTime, stc_time[ 0 ] )
					AppendVal( ECL_StopTime, stc_time[ idex - 1 ] )
					startingGun = 1
					//				else
					//					printf "While processing the time at %s an ECL-Stop was detected prior to a start.\r  Skipping this <Stop> and looking for next <Start>\r", datetime2text( stc_time[ idex - 1] )
					//					printf "To override, add the optional argument -> ECL_ParseAndCutIndex( 1, FirstLineIsStart=1 )\r"	
				endif			
			endif	
		endif		
	endfor
	if( loc_LastLineIsStop & (numpnts( ECL_StartTime ) == (numpnts( ECL_StopTime )	+ 1 ) ) )
		// there is a start without a stop & the user is invoking last line is stop
		AppendVal( ECL_StopTime, stc_time[ numpnts( stc_time) - 1 ] )
	endif
	
	if( numpnts( ECL_StartTime ) != numpnts( ECL_StopTime ) )
		//		printf "Warning [%s] != [%s]\r", nameofwave( ECL_StartTime ), nameofwave( ECL_StopTime )
		if( loc_tidyup == 1 )
			//			printf "cutting off the un-stopped start time at the end {see the tidyup=0 option to override this behavior} \r"
			Redimension/N=( numpnts( ECL_StopTime) ) ECL_StartTime
		else
			printf "Warning [%s] != [%s]\r", nameofwave( ECL_StartTime ), nameofwave( ECL_StopTime )
			printf "tidyup disabled; you will need to fix before continuing workflow\r"
		endif
		//		return -1;
	endif
	
	sprintf destStr, "ECL_%d_MidTime", index;
	Duplicate/O ECL_StartTime, $destStr
	Wave mid = $destStr
	mid = 1/2 * ECL_StartTime + 1/2 * ECL_StopTime
	SetScale/P y, 0,0, "dat", ECL_StartTime, ECL_StopTime, mid

	sprintf destStr, "ECL_%d_DeltaTime", index;
	Duplicate/O ECL_StartTime, $destStr
	Wave delta = $destStr
	delta = ECL_StopTime - ECL_StartTime
	SetScale/P y, 0,0, "dat",  delta
	
	if( loc_SummaryTable )
		if( doTable )
			AppendToTable ECL_StartTime
			AppendToTable ECL_StopTime
			AppendToTable mid
			AppendToTable delta

			ModifyTable format=8,width=160
			ModifyTable format(Point)=1,width(Point)=45
		endif			
	endif
	
	SetDataFolder $saveFolder
	
	return 0
	
End

Function IRIS_ECL_ApplyIndex2XY( index, time_w, data_w, destName, [Diagnostics, Algorithm, subfolderSuffix, listCall] )
	Variable index
	Wave time_w
	Wave data_w
	String destName
	Variable Diagnostics
	String Algorithm
	String subfolderSuffix
	Variable listCall
	
	Variable idex, count, doTable = 0, bdex, edex, bdex0, edex0;
	String destStr, algotype, algoargs
	Variable uval, ustd, usem, utime
	String loc_algo = "Mean"
	Variable jdex, jcount, span 
	
	Variable loc_Diagnositcs = 1;
	if( ParamIsDefault( Diagnostics ) != 1 )
		loc_Diagnositcs = Diagnostics;
	endif	

	Variable loc_listCall = 0;
	if( ParamIsDefault( listCall ) != 1 )
		loc_listCall = listCall;
	endif	
		
	if( ParamIsDefault( Algorithm ) != 1 )
		loc_algo = Algorithm;
	endif

	// This next block manages the working folder	
	String loc_suffix
	SVAR/Z global_ECL_WorkFolder = root:gs_ECL_WorkFolder
	if( (ParamIsDefault( subfolderSuffix )) & (SVAR_Exists( global_ECL_WorkFolder ) != 1 ) )
		loc_suffix = "A"	// a good default
	else
		if( SVAR_Exists( global_ECL_WorkFolder ) == 1 ) 
			loc_suffix = StringFromList( 2, global_ECL_WorkFolder, "_" )		// 2 = suffix; "ECL_WorkFolder_<2>"
		else
			loc_suffix = subfolderSuffix
		endif
	endif
	String saveFolder = GetDataFolder(1);
	SVAR/Z global_ECL_WorkFolder = root:gs_ECL_WorkFolder
	if( SVAR_Exists( global_ECL_WorkFolder ) != 1 )
		SetDataFolder root:
		String/G gs_ECL_WorkFolder
		sprintf gs_ECL_WorkFolder, "ECL_WorkFolder_%s", loc_suffix
		MakeAndOrSetDF( gs_ECL_WorkFolder )
		SetDataFolder $saveFolder
	endif
	SVAR global_ECL_WorkFolder = root:gs_ECL_WorkFolder

	sprintf global_ECL_WorkFolder, "ECL_WorkFolder_%s", loc_suffix
	SetDataFolder root:; MakeAndOrSetDF( global_ECL_WorkFolder )

	Variable algorithm_switch = -1, lowF, hiF;
	algotype = StringFromList( 0, lowerstr( loc_algo ), ":" );
	algoargs = StringFromList( 1, lowerstr( loc_algo ), ":" );
	
	strswitch( algotype )
		
		case "OrderedInterval":
		
			algorithm_switch = 2;
			lowF = str2num( StringFromList( 0, algoargs, "," ));
			hiF = str2num( StringFromList( 1, algoargs, "," ));
			break;
		
		case "TimeInterval":
			algorithm_switch = 3
			lowF = str2num( StringFromList( 0, algoargs, "," ));
			hiF = str2num( StringFromList( 1, algoargs, "," ));
			break;		
		
		case "TimeShift":
			algorithm_switch = 4
			lowF = str2num( StringFromList( 0, algoargs, "," ));
			hiF = str2num( StringFromList( 1, algoargs, "," ));
			break;		
		case "TimeShiftBothRelTf":
			algorithm_switch = 5
			lowF = str2num( StringFromList( 0, algoargs, "," ));
			hiF = str2num( StringFromList( 1, algoargs, "," ));
			break;		
		case "TimeShiftBothRelTi":
			algorithm_switch = 6
			lowF = str2num( StringFromList( 0, algoargs, "," ));
			hiF = str2num( StringFromList( 1, algoargs, "," ));
			break;		
		
		case "mean":
		default:
			algorithm_switch = 1;
			break;
	endswitch
	
	// Reference the preCut Index Start Stops
	sprintf destStr, "ECL_%d_StartTime", index; 
	Wave/Z ECL_StartTime = $destStr
	
	sprintf destStr, "ECL_%d_StopTime", index; 
	Wave/Z ECL_StopTime = $destStr
	
	sprintf destStr, "ECL_%d_MidTime", index; 
	Wave/Z ECL_MidTime = $destStr
	
	sprintf destStr, "ECL_%d_DeltaTime", index; 
	Wave/Z ECL_DeltaTime = $destStr
	
	if( WaveExists( ECL_StartTime ) + WaveExists( ECL_StopTime ) != 2 )
		printf "You need to run ECL_ParseAndCutIndex function prior to using this one.\r It will make ECL_Index%s_Start/Stop Time waves\r", index
		SetDataFolder $saveFolder
		return -1;
	endif
	
	// make the receptacle data
	sprintf destStr, "ECL_%d_%s_Avg", index, destName
	Make/O/N=0/D $destStr
	Wave ECL_Average = $destStr
	
	sprintf destStr, "ECL_%d_%s_Sdev", index, destName
	Make/O/N=0/D $destStr
	Wave ECL_StdDev = $destStr

	sprintf destStr, "ECL_%d_%s_Serr", index, destName
	Make/O/N=0/D $destStr
	Wave ECL_StdErr = $destStr

	sprintf destStr, "ECL_%d_%s_TrueTime", index, destName
	Make/O/N=0/D $destStr
	Wave ECL_TrueTime = $destStr
	
	KillWaves/Z eclxy_diag_data, eclxy_diag_time
	Make/D/O/N=0 eclxy_diag_data, eclxy_diag_time
	count = numpnts( ECL_StartTime )
	for( idex = 0; idex < count; idex += 1 )
		switch ( algorithm_switch )
			
				//this is the timeShift algorithm
			case 4:
				bdex = BinarySearch( time_w, ECL_StartTime[ idex ] + lowF )
				edex = BinarySearch( time_w, ECL_StopTime[ idex ] + hiF )
				if(bdex == -1)
					bdex = 0
				endif
				if(edex == -2)
					edex = numpnts(time_w) - 1
				endif
				
				WaveStats/Q /R=[bdex, edex] data_w
				uval = v_avg;	ustd = v_sdev;	usem = V_sem;		
				WaveStats/Q /R=[bdex, edex] time_w
				utime = v_avg;	
								
				Duplicate/O/R=[ bdex, edex ] data_w, seg_eclxy_diag_data
				Duplicate/O/R=[ bdex, edex ] time_w, seg_eclxy_diag_time
				Concatenate/NP "seg_eclxy_diag_data;", eclxy_diag_data
				Concatenate/NP "seg_eclxy_diag_time;", eclxy_diag_time		
	
				break;
				//this is the TimeShiftBothRelTf algorithm
			case 5:
				bdex = BinarySearch( time_w, ECL_StopTime[ idex ] + lowF )
				edex = BinarySearch( time_w, ECL_StopTime[ idex ] + hiF )
				if(bdex == -1)
					bdex = 0
				endif
				if(edex == -2)
					edex = numpnts(time_w) - 1
				endif
				
				WaveStats/Q /R=[bdex, edex] data_w
				uval = v_avg;	ustd = v_sdev;	usem = V_sem;		
				WaveStats/Q /R=[bdex, edex] time_w
				utime = v_avg;	
								
				Duplicate/O/R=[ bdex, edex ] data_w, seg_eclxy_diag_data
				Duplicate/O/R=[ bdex, edex ] time_w, seg_eclxy_diag_time
				Concatenate/NP "seg_eclxy_diag_data;", eclxy_diag_data
				Concatenate/NP "seg_eclxy_diag_time;", eclxy_diag_time		
	
				break;
				//this is the TimeShiftBothRelTi algorithm
			case 6:
				bdex = BinarySearch( time_w, ECL_StartTime[ idex ] + lowF )
				edex = BinarySearch( time_w, ECL_StartTime[ idex ] + hiF )
				if(bdex == -1)
					bdex = 0
				endif
				if(edex == -2)
					edex = numpnts(time_w) - 1
				endif
				
				WaveStats/Q /R=[bdex, edex] data_w
				uval = v_avg;	ustd = v_sdev;	usem = V_sem;		
				WaveStats/Q /R=[bdex, edex] time_w
				utime = v_avg;	
								
				Duplicate/O/R=[ bdex, edex ] data_w, seg_eclxy_diag_data
				Duplicate/O/R=[ bdex, edex ] time_w, seg_eclxy_diag_time
				Concatenate/NP "seg_eclxy_diag_data;", eclxy_diag_data
				Concatenate/NP "seg_eclxy_diag_time;", eclxy_diag_time		
	
				break;
			
				//this is the time fraction algorithm
			case 10:
				bdex = BinarySearch( time_w, ECL_StartTime[ idex ]  )
				edex = BinarySearch( time_w, ECL_StopTime[ idex ] )
				if(bdex == -1)
					bdex = 0
				endif
				if(edex == -2)
					edex = numpnts(time_w) - 1
				endif
				
				span = time_w[ edex ] - time_w[ bdex]
				bdex = BinarySearch( time_w, ECL_StartTime[ idex ] + span * lowF  )
				edex = BinarySearch( time_w, ECL_StartTime[ idex ] + span * hiF )
				if(bdex == -1)
					bdex = 0
				endif
				if(edex == -2)
					edex = numpnts(time_w) - 1
				endif
							
				WaveStats/Q /R=[bdex, edex] data_w
				uval = v_avg;	ustd = v_sdev;	usem = V_sem;	
				WaveStats/Q /R=[bdex, edex] time_w
				utime = v_avg;		
				
				Duplicate/O/R=[ bdex, edex ] data_w, seg_eclxy_diag_data
				Duplicate/O/R=[ bdex, edex ] time_w, seg_eclxy_diag_time
				Concatenate/NP "seg_eclxy_diag_data;", eclxy_diag_data
				Concatenate/NP "seg_eclxy_diag_time;", eclxy_diag_time		
	
				break;
			
				//this is the intervalling algorithm
			case 2:
				bdex0 = BinarySearch( time_w, ECL_StartTime[ idex ] )
				edex0 = BinarySearch( time_w, ECL_StopTime[ idex ] )
				if(bdex == -1)
					bdex = 0
				endif
				if(edex == -2)
					edex = numpnts(time_w) - 1
				endif
				
				Duplicate/O/R=[ bdex0, edex0 ] data_w, ecl_temp
				Duplicate/O/R=[ bdex0, edex0 ] time_w, ecl_temp_time
				Sort ecl_temp, ecl_temp, ecl_temp_time
				bdex = Ceil( numpnts( ecl_temp ) * lowF )
				edex = Floor( numpnts( ecl_temp ) * hiF )
				
				WaveStats/Q /R=[bdex, edex] ecl_temp
				uval = v_avg;	ustd = v_sdev;	usem = V_sem;
				WaveStats/Q /R=[bdex, edex] ecl_temp_time
				utime = v_avg;	
				
				Duplicate/O/R=[ bdex, edex ]  ecl_temp, seg_eclxy_diag_data
				Duplicate/O/R=[bdex, edex] ecl_temp_time, seg_eclxy_diag_time
				Concatenate/NP "seg_eclxy_diag_data;", eclxy_diag_data
				Concatenate/NP "seg_eclxy_diag_time;", eclxy_diag_time		

				break;

				//this is the mean algorithm
			case 1:
			default:
				bdex = BinarySearch( time_w, ECL_StartTime[ idex ] )
				edex = BinarySearch( time_w, ECL_StopTime[ idex ] )
				if(bdex == -1)
					bdex = 0
				endif
				if(edex == -2)
					edex = numpnts(time_w) - 1
				endif
				
				WaveStats/Q /R=[bdex, edex] data_w
				uval = v_avg;	ustd = v_sdev;	usem = V_sem;
				
				WaveStats/Q /R=[bdex, edex] time_w
				utime = v_avg;	
								
				Duplicate/O/R=[ bdex, edex ] data_w, seg_eclxy_diag_data
				Duplicate/O/R=[ bdex, edex ] time_w, seg_eclxy_diag_time
				Concatenate/NP "seg_eclxy_diag_data;", eclxy_diag_data
				Concatenate/NP "seg_eclxy_diag_time;", eclxy_diag_time		

				break;
						
		endswitch
		
		AppendVal( ECL_Average, uval )
		AppendVal( ECL_StdDev, ustd )
		AppendVal( ECL_StdErr, usem )
		AppendVal( ECL_TrueTime, utime )
		
	endfor
	
	String traceName, DiagnosisWinTitle
	Variable graph_minTime, graph_maxTime, medianDT, win_top, win_right, win_left, win_bottom
	
	if( (loc_Diagnositcs==1) & (loc_listCall==0) )
		sprintf DiagnosisWinTitle, "DiagnosisWin_%s_ECLIndex_%d", NameOfWave( data_w ), index 
		DoWindow ECL_DiagnosticWin
		if( V_Flag == 1 )
			GetAxis/W=ECL_DiagnosticWin/Q bottom
			graph_minTime = v_min
			graph_maxTime = v_max
			
			GetWindow ECL_DiagnosticWin wsize
			win_top = V_top
			win_right = V_right
			win_left = V_left
			win_bottom = V_bottom
	
			DoWindow/K ECL_DiagnosticWin
		else
			#IF (igorversion()<7)
			QuartileReport(ECL_DeltaTime, 0)
			NVAR V_Quartile50
			medianDT = V_Quartile50
			//medianDT=mean(ECL_DeltaTime) // Scott, please verify
			#ELSE
			medianDT = median( ECL_DeltaTime );
			#ENDIF
		
		
			graph_minTime = ECL_MidTime[ floor( numpnts( ECL_MidTime )/2 ) ] - medianDT * 1.5
			graph_maxTime = ECL_MidTime[ floor( numpnts( ECL_MidTime )/2 ) ] + medianDT * 1.5

			win_top = 100
			win_right = 800
			win_left = 50
			win_bottom = 600
						
		endif 	
		
		DoWindow ECL_DiagnosticWin
		if( V_Flag != 1 )
			Display/K=1 /W=(win_left,win_top,win_right,win_bottom) as DiagnosisWinTitle
			DoWindow/C ECL_DiagnosticWin 
			
			AppendToGraph data_w vs time_w
			traceName = NameOfwave( data_w )
			ModifyGraph mode($traceName)=2,rgb($traceName)=(0,0,0),lsize($traceName)=6
	
			AppendToGraph eclxy_diag_data vs eclxy_diag_time
			ModifyGraph mode(eclxy_diag_data)=2,rgb(eclxy_diag_data)=(65535,65535,0), lsize(eclxy_diag_data)=4
			
			AppendToGraph ECL_Average vs ECL_StartTime
			traceName = NameOfWave( ECL_Average )
			ModifyGraph mode($traceName)=3,marker($traceName)=32
			ModifyGraph rgb($traceName)=(3,52428,1)
			
			AppendToGraph ECL_Average vs ECL_StopTime
			traceName = NameOfWave( ECL_Average ) + "#1"
			ModifyGraph mode($traceName)=3,marker($traceName)=34
			
			AppendToGraph ECL_Average vs ECL_MidTime
			traceName = NameOfWave( ECL_Average ) + "#2"
			ModifyGraph mode($traceName)=3,marker($traceName)=40
			ModifyGraph msize($traceName)=6,rgb($traceName)=(16385,28398,65535),useMrkStrokeRGB($traceName)=1
	
			AppendToGraph ECL_Average vs ECL_TrueTime
			traceName = NameOfWave( ECL_Average ) + "#3"
			ModifyGraph mode($traceName)=3,marker($traceName)=18
			ModifyGraph rgb($traceName)=(3,52428,1)
			ModifyGraph msize($traceName)=6,useMrkStrokeRGB($traceName)=1
			ErrorBars $traceName Y,wave=(ECL_StdDev,ECL_StdDev)
		
			ModifyGraph grid(bottom)=1,tick=2,mirror=1;
			SetAxis bottom, graph_minTime, graph_maxTime;
			Label bottom " ";
			ModifyGraph dateInfo(bottom)={0,1,0}
			
			Execute( "HandyGraphButtons()" );
		endif
	endif // loc_diagnostics == 1
	
	SetDataFolder $saveFolder
	
	return 0;
	
End

/////////////////////////////////////////
// Aerodyne logo encoded as ASCII text //
/////////////////////////////////////////

// PNG: width= 2692, height= 140
Picture AerodyneLogoButtonPic
ASCII85Begin
M,6r;%14!\!!!!.8Ou6I!!!@Z!!!"X#Qau+!79HF)#sX:!HV./63+16*9dG'!-i'W8S1[k!%IsK!!i
Q-!?(qA!!!!"!!!!_!?2"B!!!!"!!!!g!@RpM!!!!"!!3-#LM6_k!!!!"!!!!oz!!!"0!!!!"!!!"0
!!!!"!!Akp!!<3$!!*'#!!&Yn!!E9%!!*'"$A>&S!!E9%!!*'"!/pmX!!($M1fFAS!"!U8=`XQC%q,
G<%q,L;5Gr2q!'gNU6pXds!URK)?l[dDmD#uUd456Z@.+4iY_]taU-s-,Eflpj;scQiMj*r3-#m2L(
WWd$-iZ0VG)@;%Fs=u4'WY+W<@F#>n%F8T8G$4(Mf$r"q<mU$O@4X"86I3_<oA#\cCI$Q^Kl_PkI]V
q2;>QFI$"C8O8oTK!""_e$'5,nO8oTK!""_e$'5,nO8oTK!""_e$'5,nO8oTK!"%F?!q%!d'Ls>J&g
.2f+9<)t!>6LU&g.2f+9<)t!>6LU&g.2f+9<)t!>6LU&g.2f+9<)d!Y!*?HU%WX5QW2r![L#4,X;DV
5QW2r![L#4,X;DV5QW2r![L#4,X;DV5QW2r!]QJHKCLl;.#0#J&g.2f+9<)t!>6LU&g.2f+9<)t!>6
LU&g.2f+9<)t!>6LU&g.2f+9;],q&LRY&g.2f+9<)t!>6LU&g.2f+9<)t!>6LU&g.2f+9<)t!>6LU&
g.2f+FtJ*JAM""%$\Yl!""_e$'5,nO8oTK!""_e$'5,nO8oTK!""_e$'5,nO8oTK!""_e$'5.>nb`l
Y!""_e$'5,nO8oTK!""_e$'5,nO8oTK!""_e$'5,nO8oTK!""_e$';q3-GX$e%0ju68:Uh6J-8Dn"A
"%G8:Uh6J-8Dn"A"%G8:Uh6J-8Dn"A"%G8:Uh6J-8Dn_0CD68:Uh6J-8Dn"A"%G8:Uh6J-8Dn"A"%G
8:Uh6J-8Dn"A"%G8:Uh6J-8F$"qtAurWWJdE$R[M,X;DV5QW2r![L#4,X;DV5QW2r![L#4,X;DV5QW
2r![L#4,X;DV^gK:>"!g,5,X;DV5QW2r![L#4,X;DV5QW2r![L#4,X;DV5QW2r![L#4,X;DVE.\HN(
k70hhLrf"[N12mH@'ujbIS!uO1.LY,X;DV5QW2r![KHL$(.UCf%+FM`i+8G4qn<b!""_e$'5,nOMFR
]!<+>kW35GFiP"cI8:Uh6J-8Dn"E%!:%*"A-cb7',I`n$/-Vp:"<.=I(/YA+-8:Uh6J-8Dn"A%Gt+F
m#\mbPL)rp6tUTJs]b_-8#_&g.2f+9<)tJ_PmoJHH.KIcd&/13pJo0V=O38:Uh6J-8F$VC0/er([2'
?/H)t^3oaaX]mM!FRnM7*foL\#34A^5QW2r![L#4,X;DVE,>Z4`4rQog\)XL<j#]loD,P;!dg"/$'5
,nO8oTK!""b&FVEE>Dr3(K^:IjsP#*QKh1K\I&g.2f+9<)t!>;ms";m*40cY,W;/0l^?f/FP&W85I]
XVLrR%*[oGul7V![L#4,X;DV5Q[^;!$^sf[j)I!A*K.&F"8_0e"cG98:Uh6J-8Dn"A"%GDH[,=p[<V
)eQ49acX0LOl#tPJ^1fe[hA?Q\!""_e$/B\,]XQ]1h]<;e<;<Jn.[Zl2.t6m>[1ao_e26RdG]Z+q$'
5,nO8oTK!""b&qaM\J%_qPR)[?ioS2#HgW`?)J6/T.IJeoa7&g.2f+9<)tJ_PoE//H,)8NV.`68HuX
2/?<^l*gEKq4Juu![L#4,]IN1?nhT2pmd(]Qgd97+#ncmgGG6K>;g->*5CAqX:a*Q"A"%G8:Uh6J-8
Dn"GT>FCW"b/]!QJ;`hoW1no<\JCtOi;R5q>\fU2k5J-8Dn"A"%G8:Uht9;&PhC!2eo(GB%70.=@)h
L"kbnqK4-qi_!dO8oTK!""b&HV/h)q"GKkq_37?'%saDs5(G9PKDn`q=EdoS!T\:rBB!A01c3j5QW2
r![L#4,]MKL5U=(HY3stUT5ALbccOF;[r,JcC$BL+oR'IJ+9<)t!>6LU&g2c"LHo'JgP[`!=F9kL0,
Rs-C=RtD'3L[erV7^`<>$DT&g.2f+G"_a^u]XoS]ra2"P)a4S2bNLa:US'S2+ZuU4iu5Mi2MikMRqU
!""_e$'5,nO8oUB8d)`;]3g$_jj).HAAbTSZ!uk>RCCW#o3P"="A"%G8:Uh6J-9aU!mt]RPuh:+BP?
o2rQFW=US=K7"mU$BO--nF![L#4,X;F+T)aN6UZsX)6IPDaa1JppMi*E/<*!HdW8#RXGZ9+0Hl*J=!
>6LU&g.2f\Ch-)L9Y[S^5LOl=;hKSpa&S!GeL2nFgHKg]H7b/!>6LU&g.2f(i9Bc+$P)?r-=N?RQPl
dd\TUI7abuIJGD;Q5QW2r![KI'#V].<>!>NE$aW.F=&lZ8[,g?2<`W8HRPg#05tB8!b9nG6&g.2f+9
<)tJX_f&ge[.[6\c1bA7UpiQ//cqI4,f@.IWK[704`"![L#4,X;DV0R="HFEAK_H5+\XZClF!F]X$@
4q#l$Skk\K638Dt![L#4UPf,)nY>1:Zn1OmWDc?G[p6'Re#1N[1P[mP./@QP(aM?J,X;DV5QW3M',-
2@@P>C`67a2(b0%S!nZY;tig]&3OT5]L!""_e$'5,nN!9?^bd;Zek4Xgq5Tm:GeZ.'G;AKKX%A,/CJ
HSMo"A"%G7O\?Bj%%2r>?+[Gkg6#BDsro^PEt!D7r_DR.![L1"pp@k$'5,nO8oTK^s,KeYsB=uRXAH
1SSQj&S2'&9]i3c($'5,nO8oTK!""b&kTTH8)fO52\mu`!b2ph0EiJi]o>0uh8:Uh6J-8DNF:qt8IP
cGTNK&pQNZ;bJC+:ea\RWaEo'ta1_c-(C8:Uh6J-8Dn"A"%GDIN[EBc]6YnANG4W!KtRiPHm6QeoY>
b?H1l&g.2f+9<)t!>64q"HFKeIe;9tGW];0;6as5E[8\dOpC#WO8oTK!""_e$&ha`%*%2q+)EnV5(;
M0`=!J;Za,Z+5CM7m>Q0c[!$jf2,X;DV5QW2r!]N%=//<[!d\Yd3G:+#[C"&qfWVDt[IX-,_5QW2r!
[L#4,X;F+JH/T2p?pbkh:4Bc]GqQKbB/c!&!bI+![L#4,X;F+SH+<4\+V2.8YB_AS2l#o[,uB\>-qu
2gpoV@n()q5hE;1,!""_e$'5,nOMK+8!0R&:NfG,AG'%nNQBd^upqQtL)&YC-/bAC$J-8Dn"A"%G8:
Uh\GlgN.g9k]4iph<iq=eg[:fphU&l#k5;t0lZJ-8Dn"A"%G7QUVTj)<mPfWqTi\iQ'flKmf)3HJfo
r:ubKRFh$mW&9Hd5N/bOcQG?:"A"%G8:Uh6J-8DNF;$ntr4`.,03l/G<29uthHNrYFIgaYlT0^_FUl
:;8Upq7J-8Dn"A"%G7POq2Q:HrV4aZT:XNS6D]X,8`h!Mg.B:BNU'Rs?^BI#hE,X;DVE)R@Y0$/-44
iqPc1Tdd]d%L()oi!23]&Sf40H5,P&.mHsXf[#"ldhh$O!<>-`8g>T&g.2f+9<)t!>6N+d7jU<o2DP
^*B\Snlh/+!SN:oYofOneqKqr&ft:l(nsljq*1fe),X;DV5QW2r![KIW#p94T<E42"^]F4rX&cBn4a
Znq'F.'3+):M'(LLusDeE,!./qrid7Acj8:Uh6i$KV_@/Nai5n*WKH@(!7S2bN^m+I!gr.U%EN>jfo
`3VbgJK@%)r2#`dC27Z,4*E.k>8m3j_%T@i"A"%G8:Uh6i:\8nZP&Ok[Vt%5)mloVEl!>2#g&/&d8B
6/Kbn'?mIf'YNZXmcT0M=TGTmHU!""_e$'5,nOML',J<Zighg?+&&]I$P04'#hCF!<ukb_(D2ST*0=
_T<74L*93kl0`6kt$=-8:Uh6i+=)cEpr@,\GP%M*g"7![5lQ7<Ll9oVP0t<&-sgl\8]I[l$gBsA2Lm
0]D(aLHgpO`0u_*^<ieP?IUqL./.s'+&g.2f+9<)tJPf)@1I9?X5CZ8<+<[RVS$lr%l4L4^"AO6J])
&6>?c6tXGMdiCr6!/ZN/irg![L#4,X;DV5QW2b1'4^_$qhhqW)m2->PYdKCY#R9-n#pP"<Ean?[VB4
GcHk29:%:(GW[4_0qLf8,X;DV5QW2r!^e?N@/SAS^!Aj:d4"S;:S']%g>8Dp,[@eFoD<1FRPea'S.X
DHaD-T#,%o2m4ad#Y.Pd!U0OaA6eWV=SHCl:BQR;eH+9<)t!>6LU'"F>8+DMDb$,tQPg)?$k+@0;%L
(pB4X&]rO(Q[KL0jm@9_qoh=:uTO^o53-a!JO!50Fgl%!>6LU&g.2f+9<)l`<=JY5C`ILObW`/^:ld
(Q'0J=c:/ieipe6A%Z19j>$CXeh[a:6]3KR;Fk>>)CTaSPdjQQh7jA$I+9<)t!>;p$";m*43`:brq6
=bZjaq";c;(>,YBeoJGAGLmn*G'>>7cXH#J,?(N`\F3o6=gBVl#Fq5CPn0jTo[!W@qF^^ME"-Uc2`4
c\dSeXS5jq;K=#NQt)6Y$'5,nO8oTK!!s't5edGU7;-"%JnbjhDTGTijIh[1_n<c=]/u/MQT&dHNC<
\NY9Q?l=tX*d"9h,I3LFp?FWFoc*BSH:7AF!')%St,i4O@,7PG<J+TW2u!>6LU&g.2f\5<ASe8<s;]
YOcj)l2\%?BChK>BAiLXa.kpIEu7:/mR&AAIDDp7Ic93L&Q3H>.>+bjp791LSd4Zkg6bTgNn0lHsZ8
/%mR^Od@q4@o\]8\jon;+"A"%G8:Uh4.00Y5@<<h).i(j&oY`D:'D9a`:Kbt+=b/"oK"b05%eq55#/
Um><8?U+HJLco`sZ=UM)pp!)u"qp6tptC&4%Y;*'NEi?u3d>+WMk'Qn[=]i45kgX0KmsV9>3Fn+5_e
>J#&1,Or[jaSmGM![L#4,X;DVE'4=t.r!^o=L'HI\.jtTGK9!gk!"k?S8iBPMQ:2i-Ho9l;30l6GeB
L",6IKA92JjuV<OZm@=D[",Y*GQNm=c*=MB1Y#bF2A8762sSiqECDKE+i++EFI\T?qo?lYb)![L#4,
X;DV5QW2b1'4>T>?3LsFSEf@i.=:Ik(a`7AQ3u`T]O,Mh]@T'bB9>J33n2KP4uL17A3%d]ECYq'$AW
AL&hU<,U2"UIV)?INjO&<]]Fm&Y_*O2mQsCkc=A\ediWo*6*0k'8Gj%?YmUl"!""_e$';q3,G</Sa4
p/r]?J!6F*m7i;pW;*=B.32DO>G"e2)Ld(6sA54#dh96&,^M">0780"hDMh0tDHi:@(6DBE]B+V$5[
DK%3),*CHb[`5Z:ik=;rGMQ7u=?(nY8kmRTgUD)cIHCr%HPiFAeu]lIB$:ghcRpJ.![L#4,X;DV5Q]
P5^kV3/ph]@YfG6Uj9suAl6&h75b?HmpCUp.<_igZ(nrgm9rhN3r%=$\pT*JQl#"h]SE3ugPUT:Hph
"cu!lKN*9:7=.^A2`YF_hU0fg4\O3/@"hu7in's;/uOk3<BMK!""_e$'5,nOMDD5fQ"U:4'pAU51J/
-.["I=(k&t5GIoWmP^I4^mV8Qt$t0_3!o41U.J94\$!oR/V^L[C0D*8]b[Z4"Y&LnEl9b*QZP+*-Sh
b.d<`[c_DfT6pA&jXKgpdpsI\bIXqXDCf$PkE/5EHDb8Upq7J-8Dn"F^@SDTBtGbLR8U^X06j.t5Ss
ULITi59$b:ct3#.]Ft@\]V1ugll?-Ao.sg+Wcq0(nh-tE\*TK5YWQH0I__H7pNg_1+UY'5SWi+%kVO
ns*;@Ol=X0prO7]=0a,X/"<T0NHidT.@2']&?586*D6NSMu![L#4,X;DVn2:>b]dM*L]\(VUhCuj1H
R/WJAqZM=&XXF-'tg[K<HlF\9[*]_(0#l'WaV\egTV=MNV^?Vgjh=*@JLic6#dDQR@-@%Vu,BOA'Ti
oQoeft<UX\l7OZU:g=eK0m"i^B\[f6mI/NO!e#*_*$BL>M$'5,nO8oTK!"%El!aX1]eK%k_,KCEdQY
d[V+t"Wa8oM:m^9Kt20l#$Ao0V`DZjWnnnYSpT[qtu&*uAtZF8VWbTJ(PB1h\QW.LUsAIf/8a26.'6
.Q!ddRQ(&f%ZQI-OJ&gF6_VleO$,C6c5]=5harYV,X;DV5QW2r!q/!tCQ#=hq@7t*j4amH[lJj2I-Y
jEd;t`q7HM3RACkYB^jJo,BejPKe:PCh*\F<;H=#^aS0W@L5V:_eSQ$G4Hr&E\CgK"?D<_JKN7OAVa
e;-H?W"UcrJC*mg:E`Fr%rK3KWHVdYB"^9C5VZVmGG\Y^qkZ7@4YNb@*RueN5T(])39s]$'5,nO8oT
K_"A>UMFd,s1[!J`C$n-Epp`jk%47p+UispH#i0(U7OY=]lOF@J5t-:GO3@W!#NJ6sVR@).G=e2Llp
d1N>MS^<&d:R>Bnd_kR]\FpD^?$/rq7Er)4A#MF%3qHOned-L?G.X^9,)^TWmpJLEE*BU58dS0$R<c
J-8Dn"A"%G8Dpp&J9<la@M^])^XUoB?ao#9c/V\k.(#CRg4niI%+FOgpNppWHlcn^4'uZSg;K&N<](
cEEBtViRIWS]"[s5/e24e#L:]+,(\!Z#qEs*YO=5VX49'+CoUOU@7M^i!Bl/P,D.mb0bf[d(8Q]o&O
na-Lb%r4%&g.2f+9<,M"VA1LK(2s+ZbC5<fsYO?j7SLr*`#=mg4Z?A"AZIm3r[#j:5Dd"UD[2-I3<j
Vj[>nMUo1LXPmgZdG;T]VOA0;IM@D$^.3tp]%b8T5<`^JbfqTc;5;pEKl$^b5""uM+G.b6UdSis9e^
dIpe0bLiH.A[P87^''^%a;kUN55(260b4&q<nXCa9#o+9<)t!>6N+)b?X$kJ3LoT69g4KKR1&7[OL>
_*oqB>O&FYZ%4?tQBIo4J_,V6F:;!dr=h\hT)C*q'\f??AK5\VdppNDV+^]-407aj&L/smSXANbnVp
@s>.S&3jA0!']Xd$Wh]I)i6eo\Ff%&=Lm$VKIg=luC$QjcSJ_@AA%Im\H,68E"!>6LU&g.2f(`@nua
Q`<`caNP=5StQIG-%XACf'5F@PXl2/uW42.++h^>5XYbRuRW*^-i/g6mdR59MRs6:R-7elJG>W'c5B
IV2eH]m0:IAN1)0E1d9BT*uK9lI,/ise8O-LkV'^=*DptUQBi:Wd)LeE'XrSMrqkm)S&\(taM(;0MZ
cS$"A"%G8Ds=NN;d3IUgRimL"!1(h%W'>7]9V`OOQo[U5];"9=K$u16Ic2Bs(9eYLK]M<.de$9)5'Q
/0/BpXm]s+1o3g0YH!>$k),$TMI3eBAm*s36t;iD3SRaVo(gaY0uT."kj<55osL*V4(nNKVu?EYWhM
^sjM&@B]m/r!B:C71JZ`7gP3^$sjMPgI+9<)t!>6LU'"Hm'H4u:9>Q27;CDZW9=J2g]n<WEa`8D(@E
oNc5Fi1LYDl/#S,=/"CSQNL;:+4Z""Ed\?,=L(j1-ehb?3XAAoq1Pdi&tN%]b.q4@SG);+XB9W3tsX
-^1YdfmsT]2B0R%L;`n;Q&C:jq%6o49l)q1lJqAR`pYH9$3o!$RT*.]8"A"%G8:Uh6@-@_+7_$0FkK
0Tnk[q"+&ekZBl31T#$#5o,;dO%T>Gg@FNI%3Y'+60R<(]hiBhQQiGI!1U6Ia+:8o%B<W-C<97WA^B
VrN@i8ehd`6/'qg2t\%%ZFgjW".?)]3m:[WZ")t2o?S(6pfQ\>M43TZ1KK8d;Hm?E,\V7?F*;a#4mU
^$<`Usg588#%6NSMu![L#4,k)ie)!/U/U`$.HHf7<G96%#aX8/qaPY%EDPR0)Z!\kuj9k[<YC$N85k
>N#K<K<31"KH!Dap`Da4+sKbQ'IIS61H1jPuLIl:o>V9@R\^3QpsfF4`1sfN1%6Uda1hLUGQZ=T"W3
:.Tj3RE9SC\eY'U<aR7lr%idQZSG5+NB;7M9=]sDm'\jl5&g.2f+9<)t!>;o9"J@BJ4#W^Jq4FV5k&
L2n&MuAXRLEpLC2$BSU)&uhWY'"17PZ8U,s^q_bgaR-BLm,$7;8W&+>BWhktF)?8(BVq6LrRa*0NL+
<nt-EFsJ^6lEg'`PHoqUgnnqDc_!GtotSY;5/$T[]8%n&TmeZHeis')e)>6_2X#Q.2U%dXs+Y"F?mI
u=,X;DV5QW2r!`oXmpN8mMSSrkX.=;CZUe5o68!PECbYR>P@OA%:TI(q_TppcUEHUAd%Q$);+XP&Zp
87bb[]dmg(%KuGJn!L!m&8LB"GM4dfp02a0rF.1-YN=3*g)N7f:Vo?^[^FHPchdU2uL&XVWMJ]:rMC
H_;N$$gp:\A,1#brq,ae@MZcS$"A"%G8:UiGRm>[F]^C>g[K3$6OV!#BjX9GXPL,7i,4X;OW?m5PAV
Ell6E%Q7`&%n8-b:Nsd<o5@qlX%k(e_E6:mNR2T8K_J!q7Bgh^U[P)2co56ID_1DR(FFG$U`#Kfl8E
qe,'e6e>L-ak$-fj!UjUn/j&.2;oc%o]P?H$[#6)]Q_\n_afaFM<E*N_as^0kcloMO8oTK!""_e#n3
.#'&l\E5M=h5!%+UV^gp852F@$VfgtB'T[9;:`g]M]f8\'HI8j!6;"Si2lB%\;gZ!IXaLWTd7=V2H3
Lq<LjcIoe&q`t%FkY6uR4rin7-j\sM[G*g?9$'8UC@[1^\.?KVWPErr^*9N?s"CfWu%h;?[1N5e7VC
=#%]'/=9R<F"A"%G8:Uh6J-:To!"&1<h/?><D!F_O5rN%PJeKc8#uaYG.-f5*m-_BVGh7'o*,Y(;oX
VVgrA#"r7VWl71DPjm-?l>1dqVh#k+.d#7$OQR:m%odSQ;P2!4saqmV@a2pDF>G"*m84'Un7P6r&.(
M3IPFo&ZqZ'3staXgNfsih(Sc\^&LG5TkU!TT$f"k=`b-,X;DV5QW2r!q-kTd2@nPlstP=r_q)A),<
)i0RUGMP,L_s9eS#=.eP6Y8^N8!`euOY9uEuH5EMAJYV:!ej*iItRBf+Y'"h`k%5^#?KCV&lHAY:ob
Yq*"InO7a3_R[o6[b3T\ok55hOZE0L)'pK^"SWdpKk!cs0(>K5'h8#B7DRYk4"\h6lltudiU]"313;
[-[tIJeYUKHJ$8i"EEj,!!>6LU&g.2fE+*2#@nf2OMI#kI.(tq4TV<LdHU;Ji9MKLnAZ9n\_aAr@Lq
7D0?/,@qguZKYMc0Y$Od%:$lM.(O&i?FCe,$CXQ_K*P8dF^R(qaTOF2+(,3n^';M48;#KLuHNd\KAW
kJ$P+FjI`\lOQ0bY]/!o5$H`cF\N;hnYf2)$ABP6s8I;&`".bK4-KXNO8oTK!""b&E!SiEbniH"eo\
WWde)r.CVW<&.HLl\W?UjDU8Y!n$*)]b[\pP!Ci8D*Ec7YlQRQZJr(K,><fc7/@`L2cduC@SP=g`TE
%'8c;5C4AC(NK4#!!Jp[O-sp`M)f>55,eOr:Yn&PKE)3s.ndAs1A367uLHME!HSH3IQ83X6_c'2/V-
Y&_6-Z?LRh32CrB6r)FlEM$-A""A"%G8Dnn=TIG<^5$[lr]4B=u=*M<'[e5,lZVLnSe>8se&h;A.<p
71?7\qr*fTlfk_\,C7h@'S-/ZSSn<lP9k7,:[0L8OO**)-`"M%(2tLI,!rE;G*VT\?S5EW/34W^L]-
aD+nM='JW<S<J:WEN'S6c@>^u0)bN?9/kWfpPYZeRQPlZgq(,0p[-jfq!d614:VI8h:f8*77BR.SNT
Pp"A"%G8:Uh6J-:U%!/nU!mb3]_3>4je<ett1;D+a.7P#)]do1;H7>kWSG_G-dK49ulCeM$$9j9Q!O
-[>ho'=t3;bRSYoSWF^G/&Q\_X'L_r(tf3rN[(u:<tH%<6e3LaZDY*3i&`VdhWZ&Q5'S,qLE07HK"`
c3;Ktsb.hH&ikP<Tgc;^Eg?ko"QsENo?2`3kN?'#[R@0HbI/NLP1M0n"-Q>X-"A"%G8:Uh6J-<$=!7
YOlm%T`Aml=ddFNp(GpjqK>(K<`iW"04A.eT3?<iAFAANHci!f@ohRO_Jpool5kX#8-\+>G<VHX;i'
8s-!ad$3pcetjQVnI$NS06';.,"gk'Wch7Ab""lq=@GMpGu;A,[=CC%$XE\a1WTO^X+<"E$bu5>U6W
pX^*0\`jDrf&f5KBU)=JtGs7g)b<E)q:SbVOKG4BYe+9<)t!>6N+)b"/AA]?*VT(?ePSo4L``t`i7,
[QAV_rsL1*JtMZ-u;_UY/C3+As-8lC.$cJe(k[O][ZGjoVoTV7HA$_W03X1ZRLK(*6j^2MF2'=`j@H
MTm,UNMH-\1SN\5h#Kg()%d'TGRJ,4o=OaQ)o)ip#)Og$Z](FIL0Dt<(Ep(Z7n=dn*)2V-9P<J2b0R
QN/CI:HV91t1O(g*AN/L0dEl;%i/+TW2u!>6LU&g2aL&2:4sFm#gG)SZe_WOW7'iXosM'&jLC2g$E1
,n.!:nPG"dL8[Vc(J/^JeS^m=q_NsY'%AWpqaDiTq^&2H29"@8+%N;fSk[n/rR)DCb.pbW5M]97gTH
4QhV&V.eZH5*TspG`YX.S^g3!7n?Omj3RIVlC4HrB!W\Hehp@e3g[^@7nWNNB6/Z;GE3$[t^po:QL"
A"%G8:Uh6J-9a(!Q`KF^9a_AT5"fWdG.ifrCS>A(?h!NTTG_-BnRR4AqJ/0N)=4CW)O9b]h(A7\S5\
Gp7,Nh9L\?6af0[2PcBD%Rbl$P"7=?t$^qj-N\n`(M>gJ<7-/1K>j+s?-=!_0D31DgV('IZpA4A4gN
O_=o<4Rn54OI?'eE[5bt*4-&qLQ#$/3te%LWs`'\2Gr52Tk/`8@M3(rmd#&g.2f+9<+b5m0YW0KsAr
*No9WI<[t#nS_PL8]'uDSh?8)7m(+BW/+<Y/InU\W`);0=r^OW2mhp')>B6M?Yin,`1j2+AR%Pfi^@
cTQ*PKij@j8([HdCKZD.:Y(#reN^aTi,q"R7i.W7.]fiq\@?+R_P37tuh;R3q3dSiqOOeb6^n[Jhl/
%oToi1E!ik+985NupS-O2ms'V(AW`HTdtC"Ue.tSiQ=ne)O:<+9<)t!>6LU&f<>(fUt_RriN&5.kF.
)M,0,,_XL;5&r]OVLf[JQQ;#.+,Ugl5;5>C.A](VRl^Q`^TD6fATYsY>1aP,PBKFF8)ifF_D5eeZni
@"J;e^AJ:T&\WHXQl\NnrB[BMDYP.aJNJdWtbFdBIo>OY;+('?V`8GQ!2UI!BT]OIbR[SU5YRk2)[N
GpXJ++dKNWEcPQ?cBpeDnC)ZI"A"%G8:Uh6J-8DNA-AR<)T-nt2a>h+]<&Pk>(9[%LeMJX*A49]ciG
aIX@VPU0ee`W,b(N'D9_0\lT@0S>Z9]&@j<MG$+E8tWYqEaB/K!a3o22%qG#@dDpsiGBUA5$P+%C6<
ThL1l-[El4kQ0=:Kig<b:N-iM9!*mg3r%??V:#]b3iFlnY73!An;I4jjKtuS%!3J72cg2W+A8Hi]S+
e55;nqF.!\+3'/0-!>6LU&g.2fpk9@u4i-p-AF#BSIr=U9kg?PtHl&+_=tGpM%fts+`^>`s%#N3/%?
[BP'e2_I:a$c$7eOK]k16;=jU^R8'.Oo"Bub=O*ICCTV?6&87Y;A2=(A12]1>cO^rm=n.CJG#V!4X6
T$Zm'm;_c'2^T+,\<C3(Q_+->R=FuZQePefa.`k^rJ92ifI,5+hS*dWY2^m*)Tef;7UIh:(6SBL3HJ
6)=A`1&GWjq74;T?4,23Fg9mM#0/FdgF0R58WO8oTK!""b&-mN,%M8T#DXmOiF\_JgZM3f#hU'V"'1
>jl5'QtkbV8V3KIR4aGGG4sTLK%aSU.jC"G\9Cmh?fB0S5^,#`Y"2u%^*Q(TK]#SWEFB"IW*_U4>F(
IU^s:s8NWa3F0[la`Xe;HA9m"PM/RWQj.S^5;bKpK9V4N/e%[\`65!8kWDf]Q^AN".)MLTOi0QQ]SX
Z,G_#="'T/tMr1#dCVGX@ub"tV8TK>&Ar3'<<+8:Uh6J-8Dn"@a70/-0,0^$BLX;rL+HN53rl5rq@0
):"sI,!hb;T+Z7dP"AKJ.f'V]$:P;;<4SZ8e9&C5V<qASp0>'[7s^$e9L[a-i&^M_'p7_dbEP7,0/V
5";4)&6ZsSEZ5n,4`W?Y5Z"6[P4mHT&&/>G0QF$a*?ml:6a0?5!#1<5BFp,g#0/1_Y9o=B2:+s\QLP
Ak";_g>dE>#o6)`qk&M\c,,^`b]C)6N,<:A&nHE=%qbmDi$tUJ-8Dn"A"%G872u1T!*P'.t\hU<=WH
.p`oJ3da5V`UL>l#Q._o8W5R:.%4WlM8niT2T)GOa\>#]];c>ue$bZ]s;b\/fD0I\;Gbot6j)%b9P*
ih`-AOp!Wbos6'mgYS&c*./dK_LU\ZXYPG?aaNE[Z'0)_clG7XtQJ>g5"YTW:aZ[(`pCoXDPG6t9A`
-I)C>:DYQe0_bm(&klfTN#ANM@P!p@,a/8$%r3Dl>e./9UdRS9r((2a5cZMBGjY1U>FM$iK>Le4kt!
pt"A"%G8:Uh6J-8=bJKsjfHF\C'U`sNPbT=^;+Wm7G]Eol5@<g:1&d\n0'Zs>gWT[.*SC4/(VeXW+*
@iWTQEAaNb"k[W/!<eeb`ob>dm12*aAgQZ,#./>rDRadflbg/Q(s@G:!6Mj<>RN=P1K7FDsuNb#<r#
T7O7!8#gN=bk=X=,*rH+maM_W6.?c,H,3jmpM8^U=0b*arAV4<M"9fDP\po.of%mr^6fl/k*W/ZWPQ
XO-"A"%G8:Uh\.ft^hI:jf<?glQ"),tuJR<'fu5UF?d^]fGS`3s3s/+XDYWH8[f'^Z1..i/n^GPIhm
TI0Nu'J.\F3P+i\P#>nRVPL(!cSI.(Tj?W/3kLDBRW;,&Iq`!(WCYLF5]t(D/L!JhI\KV:eEferPB-
Ttkqe)Zp\AK>*M*<bkd^NYo)s\uJ"!'-B[XhUOI`nL^3CXc,t."/47?F]E8bqocV\Y'a.%"]qWb-&7
iFU@4B%CIrucQN"A"%G8:Uh6@#+s6F!laqrMJqI1jVnR5M=h=\3CTZRM&J?84k>R,hAk'<tZtoRISp
bm$#X=32%Nf`VRMM#Z99/!0rX.%Y_e0d<JdbKVVb9B#6Vd-&rJ*b:04.*)McbGfN,7j%T/GLZE-[%l
WJs7W\i&\+EO6FBS%6NKK5'YNPrT4*i.j-nLbXd>sOKIFg?U,8cJ.o['8;B?f_O=<6X>c^?aA^U3'J
;M_!`0uNYATgL2&Sh)HB=h8](D:!'I&F;X`,X;DV5QW3Mq[e;A44X8XqX-9g-XP&G'Zl,2R1'FP;p7
re&ha;!Z$F`oBG=U;$H&o9U*:VC"BD01#JK)8>pS:onRO&S1o2ZF'U<u<CIgs"3`7cAXjWL2Kk4H"M
C@k1`6G9$Ua7mk85lU.ZodP-T7=3>n%NO)HLWPMSp4_]LE7P[8"$>_'.-CT[Wlf0rWBmoij.7Dr'&>
b*Vh3$McEbWD;DW0#taI6XI2;&rlE.>R3Y$!,X;DV5QW2b\d1Q"[RQ9X[Ct4^BM:kS7=mS[;o8$#Pq
YEK?O1BZ$1UWY6?>2Enk,?;$6j*hD2o!];`oJVD8!1a/MIqi1?EI9<p)`IR5Qk?hFsnCOe;f1,n>bW
:,cVa!Z)mHP<MG.a0&&s'_</GO,X,42iP=o1RXd&fEWaOm%`F]N,*lO#f`3tQc#b,]Pq;sJV1+aN7(
ibK:/,Ue9&rVhlVO6la=..>@)`cUSD>LMA8dM/Fds_<Nk9H'Xj2*$'5,nO8oTK^^ph-o"fS,MOnU1^
8CL%4Kpf=OE[)PW<2RDP[K[<3s;M+",.sL#Lp1<+V]pg:]Yb3PWmHn:/i8XH'_%14V4^t`1e*A+t2u
Q<gG_&Qg/YR.#(DSVW=W@Wd>EPko=ic&Hc!hAn4j)H=6L5`fIj)BWC`Y1/$6V4lt:E7J.\L)q'eKT!
3@B3kr2'E.%JCcFI++K]1\>g<Q6PMn8WoTZF?E]4ML-m'#!,D'V@J,X;DV5QW3MRhDZ7hcSG.49Fq"
#n!F@57#/"^:U47/7#]TW4]H!Vo7EM?)ii0LelEd8qLMV9dGul,hqK:ClcdX<GE39:lk*"eU(JU.eT
0HOe/lWQ:C&=rcU;/6u9G=C)]*a$;^Y/m^X"^?iPDQp*)WPU6Wpbr:0e)eqXS=T"J=o\QCZ`hKt!"i
nHNgp%;V'DugRcld4hXk<JOa6aLFOITmo^OoPfM!""_e$';si9V<VV(.MtaoF-+D.F'2YE@1_s_pa2
RlHK-iG7g(l'nltO;O+="+U[7.7H1R(/uWGbbg!NNW"GIdB+12g[4;8,1/^kF2Wd7@<-b1c/j<qEPU
hVjqI=pC4<4a^5E;LZPJ0;*brOC"r\As!Lb"V/X-b^?%mTC+)b*CoUoc!`)RXWd'7T0PDg(i1^D3+9
>#S^To(;2,a,_IK$*2?)>e#kUnK[2<'1m]W8:Uh6J-=_#i78CXRs(O?CKGZ!B';66K%Zmr,k3:j4;*
N,6%_LAM?&p']SK*95Lc):MJX>b0N>Y&[Ui6&.b_!ieeA3H8S23QULRZj:tia-ZmK=[CuCZFi7OKY0
LaY@][ZFPNXjR<WGSJF/HjK8M3@g!B)hY\)9qh,YJ4c@JiTJ%rLqF>mJg#-BXId#9ia)S\7/Tjj)?q
R&bOGD6\g^Bl0ddBqYdHrY?nJ]3DuH'3tD.O!""_e$'5,nOME7kd+EE4WpP)Mgmqp@OF3Dq.Mer[Qm
hq?oa"DE\l>[^M%(rH.U%nY.e`99="UhXl@g.&,.i*2l,b\KJu5=0d$]n09aa]6U#4NsqjZg0kYcOo
3lm@,24`3]NeITNadO9nnG71*:+uCnTB=X(gR:41XDIE6J)-GI*&l?TUC@[1s8$ZsJ)s<Jrkni>]"7
agf3`H5DT;;P'F"Hnj,]u+dte7iM'P=f,X;DV5QW2bq?Vc7op7^HCQBSNO#T74,SVS;J]a/FL.($dX
,4b?-r6+h,f1(PW0jD*7r_XCLl2"rG!VC.2=tE5B<:JN9O^[Q8[MhoMJ.*"V?k7BE#i#Hn9eDe@b5T
c0euMB$YiTmh(M^W/e0n1<fVL=R?oR+I.s+!Lr:6e0/%8&=9!3iU^9f,.5f,Qh\)KNBE%&^VLABo4e
^61HbW47L5(Fa?@B5a[PjiF"o7s9IH$*'j2PBNE_GkA*B')]$'5,nO8oUBec]mT@(b;-4b(35q1RGe
dJV@D;Lr.(dOT0k.eIIj-Zg[B0gSDUb-%OQl6s)02aUtGG[?!d&r'2=<5[l@P<843,bk+_9o6rub&l
E7$)OE'3Wq<s>o>7H/k(2c'rRfajcC+GlE[]R&pe%lNaa>NdO78cX5ZYLOPOlto_H,>:T=3jIW'VUp
^&_@:g\@k^Y!hid%k#p,#DB$e8sL#%ghd<G43F5cpT(?T9m#rj[q)4K[NY7mDV4$+9<)t!>6LU'"G%
MoYg(@[J`m#Df`P';Vi(EdSS(boV_JX@Yl<$%b2urC)<=;@e2>g<"u9oTX'I[jak8c26<UsSQRrB_i
UP&1+sZIWAYnu`S;04Wnq;K]eQ0c*7?>e1bDbI$ru[Dn`fDW2YHjN039h+gFj:@SMYpadhd>jGQ2dU
ph;O=oC3`Id=_Jr&'(bWRltWBE6c)D(Fo@8Z"%!EGpO)[+<(X?n46*e3h9>uE/OiiJ-8Dn"A"%GDL2
G)USkh==&\l:Eg*._7Gp`L:e4;<.oaLG+[MCnM;3=&NG;q$P+uJVas'GkFBhXa&7\Y'WaT[oS<CLk5
[a`*(<qkLW>$R&.*`MC<#M0G=RF7MBe:eeW7lBS3nb;bF<i80J.!hIe@@Q^n9D8XlK8,i2ocoqlZ.>
'c+WF%s%hnG`Aq8n0\/:jm3@,O`Q[icEb<YG]Hd'X;2o;Mb:d@n:-?A2M%`,CkbDY-N+""2[f<*l!$
jf2,X;DVE8q7`:orII)]AX2EMNCtl\jSUC9JBc6W<*_@jWNB:^BZe!YtH.-@VhL15Q!2^8L6I/h#LI
`u]rq_M5]jWg^N]bq>UXg[<G,\D\9u.JM;RSlb!J;Paqn,&#FU.R@3(<^L:W?DkFtimgo/l#rtokZ?
$2`T'm(HZoBertYlag0S-n@*G=*r)V(p$F;)MRAh&Ic]FGSC=p%qmb-dChRB1tl&t#3PVWl-hmmeU<
es6k*na*MeukQ-IJWW<3^9q)i)q<j![L#4,X;DVE&/0Sc00ki(YYX^gb'\US4)8"#7:be8P##4,f12
+10%;*mFZQun?NKdW_?2'<`e8o&erGZVNJfJZ1It(-Ylo08>ZM8N[a!d6L"FYVW2/I6<%OBM\E*IB>
<etQ;iX(%I3<>?,fa4j.VG&I;c4^VlsX>2]9F?bq]h-g@$,c=SYa*HiA%\G*[>C'%DlZ%fOf<XJA&Y
[m)UQ:CU*Jo#-C0>IHqp;8;"LeWEn6=:krG7lD:3+or<!!>6LU&g2a&8H8p^g*4T&\p(q"KaNOg.60
pS'3*a^d@;[<?50?,%'&/q[OCdAMRu6^ME\]4ImOh.>hH$A;)%7$K13tH/g#`a[%]tL*?.rA7S$&>3
L,Pfd=a/8=&G6Cq$D%$cinR#j]Y9=WWB:ocpTQeH>N&5J,<j7V=Q=#f9;"4rRgS/=LOpfEoO,ChtRV
`-KAJ1FnEjaM:U8&qpR4n7TuH+$Zs,Xo#j2Ph0<\!"hjNQ40qF<e?s4]4\1)+8:Uh6J-9b.!k2nuhR
&I=h7N!iHT\H]pm[#jTN@G:LZ"@e]]`57G?5!IkY\9GFAd[7';h[$h39pnBZE/+&<c8:p>m%8qH[d]
"B(DIC.sIZ;4^CsWXUs]G3*hQX6l/Dlp&\Xj)dhk;KPXV=fFiiBqAGabg"Hbri^ggS[mP4BMSQ3LOT
'Y*HtsFlL+(NBnQ:A-=gBQ/)%^UJ+\m&.p,hQZMnaND]#fOSWWFV4Ztq5%j!iUlBJI;e#,oE]5HH#8
X%q#g#n7r8:Uh6J-8Dn"@sY0!7J&*]YC=ZX(H]$q$]DDoi!lEi_`$WMZ.][:aJ;:YthPr7=^7Dm4Se
r)AR]LRdlCEV4Nj-cXrEuR6X_8D-T,FV^"L(0eH*g_P[4+"K+;<<qO4Fi8*YEJ(B-Uae%,_Jan(n^Z
ui2FmB@WlhBVb,EMiXah&V3Tp*10[qkh(5Q0<$lE+Uflp#p-q2K5Arr%0gWt(Su:B0$`aGJ6baglKK
\iZ3/nTm<3hY`oI8:Uh6J-8Dn"@tfEa)IdHEn?=j][#X03g2j,QX9S`'n]9i:+=SD7VGO3U_g3H[O#
*/'Q[/)W!).#(0[D5;4>UMj\>SRcM31F1.g[R)A4^$m(B)LdGhN#[pn)hQ2NI<$r;#3-t.8*^OQ)23
CR1L%.!YS*o=U,n%TQOCY$->9fLASrReCP5,sAn/k1ih?Aa2?7X"22_XSFlpnQPUT<%n]YCoM@LK3$
aq(gnhlK[Y2S\D/2e*$BJ+)1E%[90NZ3QcOY+9<)t!>6LU'"Hm'DUDk)h34d#h>B'.GW/o!,Z:s7Q1
(]ilVng<m\c95%WSI7nu?ZBpn2@<C)&CaQ#K/\'oIarr'^e<4ru7]Se-bT(*>?/29"dDCaZl[PSD)N
,%ch'953W>m:mTRqR9H4qT9to+A]7);P9q9_))*GlP2O<j`8!+@-HtBqiBS1TnGXD)g]!\g<uR_PN,
r;2jbQnT<EhN9m1_VqorKoS2`f(+6KW!ULV?)*Cl/4pLm`AAL5oa0.eUjjr!G[![L#4,X;DV5Q[^Q5
]<t(FRrFsV7UOS`2)%V;Nj[(bR"TU>+dMp;$jk6W_3tE7j=+k8C?,<U8ii6e.IeN21OT/:PHsZ:)^?
7Y=ML27d*FNW!s?ANn<MP>+-(uWkWW+JBi19WgiYG+2h_WF8Gh+TE!4`s7q^n1MQ[_^3H`*ah#/-ra
[RI+U^JJp+,OP47X'Z'En^:6r=H%p:2!bs7=!#q;mYPY?X7^cZ_GRm="j'l0"Xf4r0'APa'sMcTQ@3
b^$\CCaT5r+9<)t!>6N+gQk+Qm&fU1h:d2q3CM5U8nt42e;FH0hPO!CPR4#BDlO7g;h90"TfXm*7,h
WbMG-EN*;3s)Il'eBnMtP`*A\?LTHU!M;nFLc*on>Y.Asr0"]bNKU&Q[a"au:cFh<i$hs=F9?2Tn)L
H=0p5-I&1W1171'"#8Y$m#b06$IDs(Uh=*/IdC<XjGSiqAX)HmN5*RX=h2%XZJ5(?@B:99N>*CZd1d
i`$D.q6\6pq[)h8KoTJZ$&DKd,"A"%G8:Uh6?t][\a^Dc!7F/C>4HaN#]0[-e=4)66N)t'b+XXGp\'
diFK&i0Uo1G04EiT%^bQ`b/$MEZYUs^-cGV%:24mio3dAiut8O]pGen7TLMKj:9BYU!0/cFNZ2]^@g
J8OR"<t(o0]+Up[`NgC7hsnqbVS0N3ZSe)iSIB,#>CQ&?7t7X",>0h886\X;qLnZ2CLVUe2rAh%;&H
icl,*1EcuJR%UlTr"@-Nj5/o-,1\m/IOo?B3I>eHF9$s"u_Y^G-0r;?JdI<jJ'"A"%G8:Uh6J-9a7!
cU?L[m#^!Tpk(q\LCs0UpS=>88;AcQ)\rSiZUD&(klrYG,OP(abbd"Q#?@kFJ]L#'aM+InIGgseiOM
O?Y;ESVF9hWK[Ll$lGurF'((/bpJWM9Vn]m&0o@d8js`?)*X'lW4Sa1/T)Xq-.slY]bIfreg$9a[PF
e:,%4a8Ll7C-XYJs[UNj%)bFU<pk)IIdWjO_//4a$=[htji@I/=Q,R!.oO"Vkd>ApJ[t6OuA:FZOH9
0,#Fm"A"%G8:Uh6J-:Tr!+N1?mmL[3SqI\u=X[+=?6MKIK3.cDkYfJ!9SMON:a&Mp+)aeI]Q-<3=s4
>DKo-6FBppbg<N,7Je")D/3TR]=d#J`q(Cg0uC\7!HBY&g@5,CIJE>m:='Y?=S'%A`fTDS/1BE'1fm
Btak/<J@@CVc$<q+OH76p.-2,Tob's/\4E5K>_Sh%rb"gU$Xm?[U+f&XrWe^[BFm*?)dF^$s[$p[-_
?I=!dd_t*:-gj_Q>k]@>Bb$GsJ>9lH8,X;DV5QW2b"9Q&=0HLF1F3ftASSr1B&?.`fLQ[XMZ:j1nau
7I<2$6fUPZ3lQXaqb/;VY%bVBYTL(mWPAd#$aiat_/-3PedA8(-e4O<g&#X,BAG;Gslsg2M/0SD*FJ
Wbks]gR8g-`S=@R[4]^dP1XeM_)m)S[g!jXI,X^ts87ZC'DkL'Q.Kj5-XBi]B%o!;DRaYE3tXuo5<_
/62rV%QoGFd?-_;^o^%9]HFEH"spL<0[/VQh5O*g@^It$69q[CmS$8j[uDf"0OWMV!i2g5R7GMJ=GP
r6W34@B5r5QW2r![L#4[k30^h@hc;YM"Yf`6134C;qWCTHqHCrJ:Zr#.,JjTY)d,MCiL4fu7ruUpBB
d:T)2(KZ<kH<p4G9BdOf+.ah0.W2N#&gr-f]VT#GX9%1D>f]dsbBjuoF\Z?"SRQ?ZKZ-KlkS:PY*h>
d&RR;]fUp]It%\P8iAdYnuln#Pj;PHf:o3`fV.G+InUJ(>>2oYetSI,(%<Fn4%M^\rMmZY.,+ruu7R
Q'pY%36F!nhm()ZnK8$s8:2jYN:KC=,X;DV5QW2r![R7F!g.#7IFkX)^,k$@U,9Qi4?PGB,UKgo"PR
GAflcAS;PBKI#jEbs'4m\%<D)@uV+X7@>,L%]lml1Sq$X%]W5qmp,?%;=`A[R"&Y.-a>):<TdK81P%
1+Ksf0Z0/Oe?a9d@X%L3b'(7T<BoRnj!.ocKiff-0VP+`bB)]PZL'J\[kq/R[t5<XL'V*^DJi#DN=b
c8XVS?.otPSZ236?IAci;L!$Uu=aienjrL%qD&C:\h7I%O\eTpu`f;):n3[_G+$Y4aGtmc&I+U[c,X
;DV5QW2r!nSbQ4OnK>n_X-a\f!Tcr,Z/1b]/KR)g6P$,72IZ@u:7\R@t78([W[1GI4F4O]7HgdA[bW
7t))"K+^QbOPBKjl/#Ze_Wd'f9O"#9pCi,j/NDn"bJ6`,.d?1Q@pN\bUT+!%"Z,NGl8pGi't:/f9e=
"2pOX&1G?gbbAEWN]s0_?:Q0F"07#<@2_mF\N55=Z._D.X,!r<Wpn\RB;Ec]ZVXWt)1f0;.Q/^%cR4
1f6Vnl4/SrubEC4T=j]A5/IS/GY*<,chQlF6Cj"p3*s<X&c@&W2T3,H)136$d:,_!""_e$'5,ngkl5
rK*2K!:ETfI@;f;';j:^*@]9'^:5PjT&/?Qlku*Y:+ug`3-#[,f:o(sd=G9"oM$Y!IRqqfiiK>ZrRZ
a3q6ll/&"Q9>VdtuYN;%tHkK"AX-,&BZ9c(<,4R/*m]O`G-+UE7VG7SI1KqN/oBJ'l6AGCBKEa.55"
pojmamC)@P?I?rgpj?$9A8a$!Mk_aT);Je5?GObOM0/uQ\_1p"pAuQ/Vp6:Xg_W&5+.r)XT.F-OHFR
\ZiGeS2QX6[QJ)9A[/Z>aU^OA<QK\hSn$/RHEO8oTK!""_e$,"jm+QZdQO#M3Rerb]_VL-Hpn=h1jD
Bq7R$57^u/ZK9o[\XQfYWA&_R@67<g*L,[V]]r=?_/gdS$0A!-:rlg,<d.$#o+q@r3Qjspn.MB'Zil
]P**tedFVu`la3auY3^-6YrgcXgLIf@`CP/(_f5J[C9(E!q%"."m)G=K^I%q>EXH.QV,(Hi51e5*85
EJCe__Yo03ll3"o_NtI\.$ijV>=*Hi24(g@Y6mnW,h6G40`qB#^*G6eK8e82%aU1=ettK=M^3)`DL\
-n#qLH0dj!,X;DV5QW2r!]PYF>KsPp0]7:>";G?_fA>Y]ZWPdL_XLBo:n1.(_YS@2W%p<8,U>C4Ghk
VK\oK"6"-oj\15/Y9o\ts)'?Yu3)I,h<80&KZ_1(nuhdV+.9><Cm?)q\*hIgr$9@duR2X[oG/[d%I5
O[2dF+2)Ol)'RsHX"bg'3=9bbFbhp>N5Am<p\JEo]P,TlL$o(P2s\gG5[AW9u$5=Fd$G7j*cXpYCJ#
sKAUJ]P4[)mR<uN/;_tR%a(*slh$YlBr8,1mM8\'D2\[lMiX#gENZJ8oaH7^GbLG!%,,BD_!'gNU6p
Xf.>rHlmSSQj&RPek_Z2C;&M`jX^"A"%G8:Uh6?ka0Nmlo+NIEKDfSWKKUT??e*mik%pHV"pN':su<
P<_2*TH.33R@_jj#hP:D79Ls7Q(hbWJmudj5k485:r`Q1]dl<H7TCC:J3jb><9n\]&sp(qOTm>`kF;
8Zs2m!!&<BB9:NW(CVp(H:89WV)/[raDSU+]@qX8ns^St6E_RS*Ca`q`1iA7,%bHmJ7!e!4nTIL.!&
enE`03kt5C2N3kccmM-2T`D&NK(umo]<NpHcN3o2<eUHpkD]f'EhTC=uL9RGcA.&n+C.8c3GG9J9=.
J_4M3$!XXqg$'5,nOMH32TI4&QhfY_RhN$]O6uYa\?3sK*73s`2EHgM_3noa9&r@EY.I'l;;lE2$]L
S9L-r4hHECchc:k351%YaD)r0&W&Bc#8*]akgRk[7jH-j&a`NI'Vk(njFN"Z+`i*P^<P`uf$Kj.o:G
ZIeHC17M'1W`&(JCWsGJB+M3En[D,+c<tc?7.It46o6:cV,)L<`3OaFL+`%!=g*hgKaWe(2C>M,3YD
gAI(9?BitG^(VnV]G`_Dr/B?lnB92C5\NePOp3qLYB:.4*B/mQ1PQ'IVq4S2HX7#T;#rJKr5![L#4,
X;DV5QV#ogg\*Eh27_;GRg#c6mD3[Q/$I!L7";=N`%+/?Z`<%N'qPeZ@k?1:2rpl?koC"F;"`jNS%;
>2:7scoP0t&<O>?iT*SI4H?WifN^-S2OK'?=SU160rS5`CmV3DnJtf]d(3E]*inVkfhA.VD?o8rZ]?
\%J@GDkYq=>(Y\ZRQ+hRNiW*]F-$bsX>$>ueH5q+lCPD<rO4#1Z-K_uGs.E_G\M_W@5Mf%/.-niYg:
%/IR*8DU1=TE!O3-+ge/4n;/>UCW,P8d9aCK5VtRkl>#p%n?El.d"rX[rs>q1C\d?O-0JLO8oTK!""
b&m7b=&PE;FAQ;k=M[7IsSm$)$*PooIj\\mr:Z$GjpV*u#[YUO]\*@FhN:M#B_:q%iL#Z:4foH`H[>
&Z#.TU0W0$H>.?eBt"N"BFiNTPhpd1u"$<O+6&#5@k]=gZ:n@>mo`XQX32D;S->Ffm(kY5@qkrEH*#
Ana-;2h,LuV=KOY#7O0%(CG=Jo<ANu4TDs]#l1;QM*_=XW$slM%&YePKi\m<'I7'\l0AGZ;qMEM#6_
FBfgTK?m;l<Cj?_>K1>;>bg"WkFUVIn;S:%_4TRA%tP%mN1+rd7HF*BHIZ,QSN#!>6LU'"Ha'^r:+"
+)gC-"X=_U;0(P?*Y6LEM][d?.9g8.@TT'p,s+PIWi;^*5)3I`!W596E>6Aa`B0NiA0_cUnRc44WE7
dn(K?5V&YD[X!k;J=h5)6Xhrq$ocM^FTfOMq5d0$4121N'^EnieHp\'tHX1Ji[eJ2f'b_1O/4o<IGe
hO4#[KOM(QIgn,:k;"k>Yt"`msXkVjU,3fMM8)p;<Mt["N>`9[bp;qmjUr5aU^AQnO>WiibRGMhmb+
3=?,]W5$kU<M&VA%%f'+3?b^mXk*jJ[]cPK%%mILJd3A$5le;sG;X?pU,X;DV5QW2r!`pag.g=t,6#
/RVG=4&fVFMt^8uYV.6c-HFI6o&+)cX2D&u!`+h&K.Wg4mQQIB'/rWgTP1&s$pre^k`*X`]E=3<E0u
X&tQ7!U<(n`D^nn#,[OVf'9/^A2`dT[6Ql-c&9kl8SC?:AtT%4RNCCLl(qM$drnN)2qFPcR*a]!U0a
e=j2QC;rkOXrpV6:HrtWg0dZOphTW&OQDlHC);0,0#fC=Z:TLYUontN![f?rX!^A8Yng:Dl)$d(^'E
6aF,=9!):.r+JsqAtJ9o%k1B`HoF1fV#YFoluL.9:)edZ%>E4#,0(),X;DV5QW2r![IaIoj%gWHE31
j0%ppq6C%>!RWM0N6TV5=U='OF.B,inh:'cAC-sOG=IC@!;48Q@ck.kX#:5gJmEom4-YJ_i5u[5EJj
P8S]8d"O>ol)Y@@V\e\@>DQnBdeF+1*J'C.uOZYSl!Q>pqW=_pmf!4mq)ho=gE:ZQ%4-DU%g2CDhrK
Wobs]lI0,--n3d-Z$m":EA5g+#n#G[9V:iEB6&0]%uEmJk*CXLr$TamD"SS[PX"l_\GJ5+L#;i_L#G
*S3g.TqG>F96(laN7B@!.7l00'a<:k`3+.Y6&&gQr8%Za+NJ-8Dn"A"%G8ANahX)I8e)+fKmfcs'['
$6KcHA@HDoQO01+rM[Vn)Q#K_5YXPEC?X#c9__tRRO5#n`l?`:V?G-2fHFlc%H.?dZEr.3S;*KjIp1
q4K_)5EVWVp_@'tO)*rMs\;,f-:Q17[c%^XIh/5b[Q"7'9DJrS*]^oBE?<n9kWTB7R2uSU.V4!UpIG
tVDP@nC2WZsUeC2"".01:rh<0K#EG3B=>r<5AZ&,..FlITeNk?5:G;g.'3jc;ObaV_*EI3Of("NBYr
OJ%?2UF['(-sCY3EZTYiOm1>m1D8"u=sQ?7,X;DV5Q\]F!k22ahPb>FV+VCF32+]Fb35).U]-@fK]/
1+'M0coH8.S%`"_Hm6VrV!+M1_s8bAV.7VCsqa4eeHKC6AUQIdeGd\W@rIB#?dF:F8.ARF;'SGk1R[
fOrE/R(%X3f@0AKB)Y:J/;XOoR4t!d&eT1PKU#eTnEf>.$FG3d&>pr*PD"&9cs>iBL]..lX!&B6(IG
Zg33+e)VET+[.]4H]*nQ9;oassl2U-3Ho,@2\FGVE-L5b';6*H?q]!]*T0.C>hu<TA*?A7[$+D9NS1
H0P2g5R7M\ea;^AT&>P5koN!""_e$'5,n]Tka)l`PoDV^HmBH$Q5UBW;E<G`g,NPt8QtP+j!d)lCLA
fYXem+"sWiou&qTKIdtAXo$pael^c?&t3c=:)$EYj'kj-#3,'BJ6fe;4RkS8]>jOI,ndDo9.3?p@]2
EB`>h^B#&9oD;psu8E%-)$WE=&^8r*VhbKbos:Z&GF^HV7KT%mcaWnPjjl=&dXc4>A&)gIF3p5\S%j
'sl<]3=t-_.Qu]mI15\"Uc-jqTSC=P)t>9BPVC1osNCJ$P^pgA#]T8<N3oT:RO!"^AI=K+#crt_&!E
>!""_e$'5,nOMJIAkj5q:(;>H:mLY1`?,?YC?Dn4BMqSlu$#qE_plRPLg/)5k4Wt?TWPksLTHa)/2q
<MVQhn)_@qNPT.q^X.N^U6(D5e`S1'/_pe>7Bd?#<)kdne[LLZDWJGfilRJr3H[$:UX8[i6P7MP'ON
VR@<PS;7r99hYbVR(^ZQp-l"E/U?V[?Z$oD9qFXB9dMeuqU6%idT+[c>-:"Oaiheblt#b0Qi:q%$SU
5FOZRL,bWklEYd!WQJ[rA(]=2Y7IcA9P`;>a[TWi)e%=(S+a,e"8rqe'a1?]kIG_cJnJ-8Dn"A%Ia,
]Lp0iunK9qeB?P26]@eI0l#aQDe?'Mq5fNFs42&f9?W:3(5YPg1:Z[T@6^g438?a7RaaXX.4qr-,]"
-SLgnJF-2mO1o=l;U4Xab.(S_aXaTo`Y(g5V*BaF^O-`C5B67c*mh3^^Lj"'!\Z.,6WRX8P*kr8Ca.
1MJ]])*KIe_075MR't6?\V46]Ij9'Lf&\#/8,_m\;qb^285f^@SJrWRK_jbR'>Y@,-AFGX>IIP*aW%
]J'ZagpqJS8)N1[Nb/gMnPP"^[YkJ#QS)K#DslE-]:V/m(iGK:$'5,nO8oTK^hlf=-ecoeY/[h<7tj
8j6>)/q(!S0rQlK8.FsV9;e0Q#%UI'6_k_)cs(#i.2U)V(Z']W/'UhtI[c80cBQ'G_000sU!3@Ytc^
E)]\Sc41G\(/L(9\tjlb;iW.:[P/\Y_r[UZ=;BPVrJL$3[4/eO0#8d?&G75n,K5D+8t#eliIu>h#W+
+[W*Ys>+CXYF1[K%[J_I+QMphjl.insRh<`14E]MQIaOdS2op1El0iP,gK%<SKg%1UI=ApnUt\%Jp?
_Hrhp&H#K:q6J&g.2f+9<)t!>9>W`:\(rn"nlCVZBdH'0=\?S"`#V6V1,<8Ynd#6Ed-Jids3h;b9C)
X""uYK(>"5arki$nfmtdB)%PGIEi=fR@YPp`@4f%cr$J`VLBk<>o/"M]!TS:[3K'4Oa%.,23b%E3@?
*q71!b4@)?5QPJDRmS>:j04?>iZikbrP4hBmqT56*Kj@h[)]-BDp9nI]Ig=_.+s.u%F^\i5pQ</$nN
3Qq/TDRZM8Ws_YGPJiB4W9=JgpQJ?WDcRS^!GlZeStmdd!OBJ+#@L;b;-aE)I#a_"A"%G8:Uhl0a)B
b@(^@-GFn#VG:CK[ndlbG>.bK4&oh!E-<)*'gJmU=j)U#>L$k/8Toc)&8f=D0/ViDSGc&W5e?%M1X(
@op4kXkLm(>/A=\:+jUq)sd=2Qrjko[OSop3WO)H8.\Hqr[PiYSDdlAnjtpG.u?k1(fF>tjBL/^l<%
k1+!==&2A6F'e\9eZ30T,p#3-:jle$loM?LG.Dt/gLD(o*SVO*rb&RGg@ff4VbNZM`.p^VK.RfKd5c
F=gbGY%VtTRDJ,46tAh1CI`C35=QS"[aCR-'F-sn5b![L#4,X;DV5Q]O]d*Qnj&o/:&'_=N=Wgq@F:
r`Zllr6;M(=\Rb,j[g*6=)-i.Gh%??l+St]-p\0JdlBa1rAI82Of[fN1?;FHHJNNWmVt^G\V+tj%f?
*n%$$1/L8@IOJ%U8PnEL1\)tO7nT^MeNQJe.a%Lb1h'3OH02)Shh<gVrs2+a/L.`k>'9Tapc$)]TS0
BnCWMgkV_:`<-5Q!$UeLB8=p1NJeI/]2tk09/Whu/h,QhTu:&'_8U34*[8/*;V%)HQ('W2R6'Y.HGF
1Z/-n*[(Os+9<)t!>6LU&kET?a-mU!O!eFHGUhG])A7npfG0/T59`80*>O>CP#F5q$ABH7)\ee,7-H
l^8!S(o'IFaFK(Y2a>uo^/,Hnu.-q>]Ad>-oi(Y!PR>TG3IB:a4Q*6&&N&r'KQ'K7B@(72gk$mIotT
Qi,.2c`tuV]m2hGGQMG)O.;G4?P@mV0ge%NM#VS:DPl>Vr1Wk6Tskl[LI/JV#E^82ug&FfH-jX]D]R
6TD<U!b2n7TB#65>)&`1M?U&&OXSjfbckq`h29i7;1M4ir,Li^(%c9g-"A"%G8:Uh6i;Fg<b66i7.u
@Y]68t"#%`sO&+Rpj7`tRGFD301ONRC0d&LoLBM2-[T8qXu-Q._6sWEqWCB#S]@;"g`#&`!]`e2/+g
)TAc$S12lb`1]m&[!S9)kC2Kphgps][QB#G6p10uiRP(fa;*bKj^$H+1\&R-ieU3)4ER[;\_=>OY>4
haaM+_rr+F?M:Dfo9V2Qg?9HD*AgeW6#ITM<3A:3@PD'/W-GDfZEFLO?,D!^LQr9W?7`B.R;)5JIKI
sNq8D>'LteZ2q]YM\LN#(u>fT11m2inPj]&g.2f+9<)tJ_Q[p"=>C-4IL^+$#<FmiFUlDpmt*$6:Vr
opq0-fVcY>m,XeVVT[9^57AV005LEhQ3Jhu$TLE-mX+$OEG)r%Q"7<,@'37$^gPHutko[EN?a3I+hA
tsLT^(=^YkWau'jS?4b)G*LSqtX*9Hs=n1A/p#gQ82"B4UBLDn,LhbASbl;q<22?IWrjdoAGPJ-m$2
C+%iol":M+k.gr8fX`!=kJ9=-qsp)nhKOsUigh5K6_Og2jPK*r5PVV/mtVNF(nN7"VKqcW&g.2f+9<
)t!>66.!8PEYBN&Q>;6;jXC+lPO[Q(#@D;me#'U=W&BiM^='h*_3a?ua#?m'`M^.]tLlpq.S-2pa4d
r%7E(S!2^`KiRc(KAnXgLhC$GKgMelBgkO<qMW\]fH>7i8kA"GHXsr(?c/R>tZfg(Y'k*74%l'Nl5.
>f=%ZH42tK]PQ0e:R`Xgg=W.Vo8XXnfQ.h<mW0b(h_WNSeI-t'boN*io*lT/anRUbE4u_GQNt5,.1c
:fH"j_7kk+:>TrS[-ld[cYWp8k>H9$i#Ng`QV1+9<)t!>9Xl#c(b;pZqZC]rp01CP;sMV(/E6#u,Z;
R$rjoGYHqXeMg@2aUf+")ko)26W"s4q^P#@7@?P?p.Iks'C"-+JdkSSRcr/5B!_AN14'?BTSZ*uYj?
`&J\^O=]/n8*R(BM*&eqG\M&9Bu,iVa%,CW%2-EK6#qW`.l]Vqs-._H,*isgF;MnE8k#AOT.IbjWS+
*G9m%G.,2kYjBA_&VS!%Ue64Zsp:TJOJD$h6/s7r4hE=[-DOIG'W>R5Q8R+He/elrN;VZ,Z=O+F,A2
F8KW:'F3m@@hK9)F+9<)t!>6LU&g2b[Qp;qRhA'`YF<.D)M9LX-P`-kISg$I#`#SnWR@_^":PlA=F[
SZ&%e)`Kg-k!C0F(#*0qcsb?<=5Ql8YBZ5qjA#Z+d*Uh1!4jr&]-^h8+XT<1P4Gi<M$K+UjFhVDRW5
+-2]\QjKCk4Js1lR]_ZEpN(D-a32+]h:DF+"5Ek2eTN9:nV!0)jFWb";HCBg-%j>L@8&djje;(VqW#
=>Bs(+'i0)hNo*^%1nY71L3aUk&[Nh+kSbUoG@VPYNio4`qk$\lF!>6LU&g.2f+G%!78/cn>dAFW[[
o3qSk,,(R&Y`1$;l4o!Z&+/od4U_0G-M&[LB^8#.UQ/nSS1)`8Pi9/@Y]j#'DW![l*1n1]DJ[9[)`X
u(ls%i\#ZFHJ,W#`_j`Pb20,I*PO^id-#f<:&F\C*,UeBslSR4bM+qc>-Yf-N1d-kF9NP#EHdhW&Tl
Me5L:X.Nrk3gIl8Y,to7WMn*eMiY5t!),c4*'naqC=a9EtIW-i\AT`D\*]M0*8$msfZ+DuQb\B[rC-
XfWtbrlrR"r3?1*1<lT"URWk)SHMK6"A"%G8:Uj"<s#j#0HQC_USfRSWO)7]QfU)0)2:6%n<TI@9NR
rWMq=@lKHAPQhP_hpd@-do7<H\B9=6;8:;j*r!3MTn7qH%M6RT708ZTHQ=`.@`9Ee,nX.JmSrJ:oA*
jn*X:0/oBqPsNM^8ag:+c3Vcf:7grkX;;1/*T]TYTCt_HF:HH")gm+8,TN?Nm"sb[nhph#5<PtHh!*
J*M5+0(2HC3>TRP#Y]<O*a.:TshXJZ`n)*]b?p&$d&8,Wer9CJHIIuKlHtSPZ?iT]Zc6Gj"J)J`$fW
q3@o"Ok7;f_u;JY,7SP%\[sMT>D$qQBP#*rM49Cft*?\9q90RS[=PSK/X$RG0!+.hZOaLidf0lKUDL
S%IK/XaEJ7fTNn1P.^/J^eOfX"8ino:)aYO,'hsbGB^F)V$DM31c9Ja]%i>-S?oPSe#&DkA-YcIjG$
"c^W(0=a5_$#^^VL7)86rJe67/$k+^fAR9Gp8.5:n7Y%5-[]nDJ0,TH`7Q9n:ih]OdT&es*[MW.p!d
YmIVGGQP7G,i;*8NBT=V;6DX3Q]2HnWqqiYBhO?o&"7.@<s\J(ueSeW]I0oA:-+2m?g["lEQE^5GMA
:f,9o+FEsQ4B[EuDNX\*T&aTk96:n_F9J*Y(s,$dLT%ar`q1"RVmamW8lMBcB^uMrDRD!t5ZVUMc],
?%1\hDu66p71;eDu\jL)Tj@Doo/bUOVtRGnkB-(+m%>n!g'W+Pc%-n,+@i`F?sOk&;RaDf4iSC$eLW
Al3!f\?Yj\OLMSV2a9OUj*B8<>(;\/a_R$SL^>>j7WV54XhD4;EdLT#1bU4tihXH>0farA3I_!&*P>
8La1et]G81V.>$AdtA[St$04/V;hh0TbJOu&_$h?'1a5gcCi*QL0ra:!q$&fo,d<K;*\0`)3\+PDg#
>A3rm`mV:72Cb"-0edXY[_V2*E!P3;.M&_7;Jb&o?KHqOc`7f6:Eq\9%"Rq;AkRV$/'Ys:I^;i(p'(
bCY04YrBjBU17%:F;G-46c4gSB?VVjfVo!aSGdZn:^#FEeIU+]R!N-U?+b+e]62d[/G)Yn/ftjO:e@
V%X"o9"4qp-J@ITq3ID^T0\icqjj,"'Pu+NFhCSH@".^\4q1^0TOBJAm\QhQZ01:JC]9-[j\$1<R"2
Ag26SCYoO9'c,T0kZ3PYj5FqDs/05i6Q+HpHkUhC;<Z>>/5]X/e^YOWHedZ(nk)PrI=BMPZM^f*i33
DrB+h]\#rFP__iCe#BkqSQ$&/:UVi2KlS6]0]*sgZgEOoB1#W3$kZRaJWd?dBB%8C+[c!d6j;coDI@
:E)_:.AZ#f$44,gk=QthU8V6h!BO3SVKLnUGf`k4laq7G.H_[:&<!`Dhb5+fOf?+nV>uBA].!0,9>U
>,4XoNGW:p;0TWuoPti&cWW]-g7Rc^dY+o7\PX5L>OD;IO7_E#bGD3&Gk,[BOUMqX4mhFG(\"fHo)-
0KHfdOut4)-@J8h?p##7Sk-2l6NH-uZP),Aiti4?V2MDFdNS?0f-W0bbkBgJ.taHoJXrF%6.>c&0X1
W68T$U?8<X2uVgofDeA8qJ;4j2jF:+q@@0iHZ4PV.ts8nI9F/<\G;EdT0H\i@VOfL-#W0GqE_m'n`U
?"O!Y=[VU`=ccf:';>e>0&<b>adLO8p7e#+.6o]31Ab[AhcCb,gfrol'%rI44"8O^2#))>"?V8_H9F
6B!7_s$Q>Y!(`G`N6?1f$+O+Y(WA>+1QRV=<3.3B3nc)S!t(kWGS!%$rG#_%AE<UV]0%$i%SDgRBsn
Zgfe\`p;G(,'?U](E\af<^;9P"*0+',C4G?Q'1\,7ehqPlFS$p>\s%/iLP#2UbCNYj;)[G(99r7s@)
MoaPD\jrpY34e\prenjk[PLJ-]4-.=pfLIHG>j,)b`cYsb[`I/J5;,`7(K@FHhN=+I@88Y^Z\iOH2K
U>jt0$pQA%&I,cUEX2=ZX?LTr3g>2FGI_\Y;^N9f[YMcZK\*!,[.Pu;2t<L4(&48:O?oC(piCH>El[
n@B9K-WSJgXN`)1\el(Z9-(JJp3`"W!:Dk91#h,7L>PnEXoWpe$RaaEm"q>#:\>alLY6_?EgnB,Mob
=Zd_$8Uod]AYrW?8\jXi%9HX]"4Z+2BU[tTP!JRif":qqG4>CrCT\&a,eE1YE@"n8EuNpG9HDA5^!G
!L)C=&*dO^TD.?n97d?,rqOW*O:7Z7kHS@rP:gBM*NU#mO^%1W%r*RONgH-YQoppNYKZB"#[,f%ja-
R%'p%2spjlQ<k=i%qFFK!+?Sj.=jVKMIJ,5#Vi=Tk.u6N5)jMk.&AfAl;dMq;:T<T<:NrQbEjAMX7l
W?o`R9LW(XSWADA?!CNXqjZbTIJq[;drcZO;4t]4W8+g#s29N4^T_aqUQ7$6[WjRGcrFT4:Hu2c[;B
PgcR_H9?@>E,3_1/;/BjJ:Bah^`a=.;h\q\LrQCe,shK]+@;4[T5GI>'J]iqiq>F+&k0=ZP;%@Cl9K
[<:d?:[V-8b0AM2uSo/Sj4^$#"%e'`Wc*oHadPYhL!rTIc$*-1cr=4ARb(M?9FNtcd&'PSMR2Cce"2
eP*Yp8^+E"cS(4fTnbDJ0aTL.F^>pPH]C+m`YO?&m?i[XDGQ-qn<fIt[,\5U##n:>"FPXN<B8UJ=19
3Dd2_VkAVRa76>:H'KC(6/nB+!slE*1+Lk+pF?<6U0bAEjg/H$$Fl+5*T:FZZ!h:?U5FgR`oYE*5V0
;bKbBM]+sTqPRqY3%eOSD1GL?ma=O6kKh>pa@HU!M@t?prfTu[:Sao,_K3g=P%_7,b0(`,krROF`f8
5JZ##T^h*_0`\NK>pJ"WsYSb&X/@:hQ)O2K(YZRSspjV<t,NZ\+Y]Q2(e6f+VqRi4BFHtT)#l%o\T-
6tu,-UjA%2"`gf(WRI2)ms/.KMOO+6Y:Q4k!)]P1jG3',$&eRVL'j#/g+gE.\XsDToZ-u+hXRL*BF0
0-3kk8"qpO'@Z;WtR2?*`WfOYU1d8DuIp<>(<K[]X1g/(?V='p%PK+8ts)NA+)K-`$<ROJhTqakL_6
,-6Js/?U:3T4=HnL?1UTED/6n/^7o>@hq)b4>tjKf/Z<q98R66?\(*GppCJ*De\EhuPdHb+M2#?eCT
hW7kEmaYNJJ)"bEH>Qd;qpo#`WcZp2$c6`MK4m88A)i]Dr6j-FP]PFs@H$ARl39QRr'Wj.n`f5FDVp
j((Dk1+1bq/[[ThnTk%:+sp!-=Qenq>:D*5gC*?U?rDXV\dA0)O'Oe%aM).@`q!dT3R9m@"Y?kH9;!
1tmh2DCP2ccjdu$sAp^2=C:9&@?t2<(q+QC.`;hHV\-mVjt522R,#:<&MRaUdNgP<gIbM0L$'gR[BY
2S=1?8'bu2#X-31jo[6JMo^\k2gJ@4m>?k(WcqrW>W^3N1<C(U?93@RLFe@o<=D#G2ak=k'Nh8"C-q
O6*1+bIaZ[6UfGGbNc-\Ai"pu:9;NsAlMhQdrLSiU$'gtj>L/gfJ;oRmf$OsrXcH5p]p>'`:j&7DJm
mb1n/",Do$mG;nRb,sH1I;*EaC2NCT7]rW&D0/OmZHFWBqYDK9Ke"[C2fC_0dHq(ed-0:KmcdZ*c^d
3k6P8'sj<$QlOVAn&&0G%[g'H]OrgKhNBaJNqpIBCWq]LIAhti"C#\pk_bL,*H/>!%ag5lFW"Ypr[/
e_MOR2M5$NrF3B@dN;@3jW38$<^V3?W#LXQ<$p/D!u>uHLi,lWe';?IZdK4IHsP0mZ*/=e]II5fXU_
?_P.tBe=[)O(7mo$MsD;HgY"WA8(].a(re)QJ+E.c7cgGP]FMT,@%Xi:f9mF]g+apm88:a*I8D@-mq
5BfLsF*SB,f>P*O!2NUTCh"&<+Ph$6[-R:7n!"T9@@l!Ur'l]OL9>,MRF6.4oK%l?(InA`>WF!+mA1
XR)1p(6)UFe^RG@;^3L_G).%['H(8(H$<,"_o2)5?p_9Tq4t4A?C@4<bj=tQmVZ*?7:Su3Qa4;f=;!
<W`f2#pF\4PdV@bq+i,h9PRr@aWH)f:2Ap(]?$STW6ji0:e#uP>0W/j1qYnq#&;pK?_2/@G77n5K\*
!@[lAhgd&G-_MBl?#jn6SfCC=Mh/jN3l\(`(Y/aJV3Ue"OAO@:9C@h'*u0jkEuF-8kR9rR[ZAN``k.
^`QB"O?<Yip$Feb&P9TTfALs4<]3tW*m-H!V&V<g24*mu;j2]3%a,k+.>'r`&]rJAp8[Y\&BB7.p'p
h]7jOX+>%h;W@[BMk>l]Kl"X9C@W/EZNG(/WnIBd7<KF*c),*LZbLiPhAW)49(o18Ap>R05R_*L$u_
W1.^q*Ba6aF^>jtrY*gIQS5?^ChdI-QID#b%SQNJP2)@JZmr1pqnm2U1qT5SSQ$`15Y\+2R1'gOH+>
A^6EdAO(b@C%q@2GLeNk<+pZ-9h$&"^-lTF!GT!30\fnT"UpWPe&DY8[-l:Y8e+Q5hp8jX\>RTSi[O
PcVVL(N2(oe/#AEc0So4T'i:iE]KA-kK@6-qOPn3]eS[r7M_qn&h(02c^Uqe,mL*F*fRpo\+/c4CWM
Xq5cKTe%'VXnq1$#2(g3f;7n"3p=k>iY-&GQq*Wp$e'idAF*h.s^[_<4+09p+b=<M3-723Ulkj0?IJ
k[_Z7_Y_Tai.sHi0kf=i6D#;IX<u?AN;N+\;_;6q;t66)cT#jJgVYnlW"X=c,oBdq2>oZ1*o2>,LY"
[V\6WoQVZ$@4E26'btF5.&rV7Kt,))r],.rMJ0@a6<qHr0gf&&1/d,ZA&DW/2.A7U4Y8`_!9RL,F2t
9XRe7aE4*IEoU8Fc`\J$Y>$ad4VK0S<0K\L<^I:4VNR@S^#AJ9f2,t::m"!b1Je$4CPdIEE#[]lti>
?H2T/<bHq=d-]];L4\_7%Al,g27-rFOXi'ehGM""'9"C:!Ch;:J,4rZBOOg03_T0]R+Q?BL/Bg9Z]j
MhIA4sG'VJVV.g^hc_HJ!?tQ>E_bYC+i7m=bW<#JV/7q.?H@"rERA6^%2's_kcR2.hpnWS1`o[bWe<
371o1#R)lLbP3]6;(hNWpO[,egggP89cH4"#5OL4RacDh%;Hmi7.DZGDt6=3,I``j(mDj.endGZ:Hs
Gers.-?t]t0ac:kI6#qe2dAF]`/$73U#CD)o<Yj4ld[rg!aYjQ.ETt/.C!]^*'J2e*>6)PYILA<Kg2
l=rdg`)&N38%/*,fhK.=c]bl<dX;;mQu[NR^oKbdbQ/ttWi4uOT<04!C9J;E-Z'c5K,;c;IXS\o!E`
m/JYlqnoT;^^)7#AXj"]]hh5@;SNHK1VPjq9NNYK\NUXWNksM=S-$RJOi-@H02YSS%"r[4$/3mV2c%
[;2QO]E@<]E&<p4*5LRp*Xpe[*?5`a$Uo4RbZDA^&'Ho81DZ[)uIK/50n*HeS1'emQk:_=*A+oDV!K
r+`eCrcmIf8fZWhu.c^pPaU41V)kZ)o%:,FG(QTrti+)!t#.NS-F/<#Y[O=Lp1Q6(r+>W=AkA(6\S\
2ke?P=&[jolr_6P?%p<p<`I\X;Y_kJABYg^[ss.#)4ML2i[0]3>.>\n`f(lq3"5N;RF@cq7n:n.4bZ
CdQ6dkGYsu!$@udB]12.lTRPuTqfn0$0p]$3YL-a>>j^_t5nA`F;@&;H2l(DGKBlT%INF<If5P=i"_
G&.!<*nDi(Hjmt5!1?p\[ecOV3@M8E-N-O*'InUVIB7lcg:ZXBal=Y]5T5&T:3ae]XkTmQ:H\.10$&
tHFtSocTXJF'^kQ:Tu."=i#rVq"^?ta0HiPpoU'g'$u/?drtUQi&lW4Pb"\9cKl(QZ[hcr"s$#YqLT
-@=ko)HU.W!%C]u3_k',J@TG*d,FKl^jg"/hf.A47-7>Z)Juq,F@/*bZE80[U\u,g&PF6;p,Y]WIJ4
lfkl`ZbPnH#H8NE.hdJXm&>W0Hi(p)V[g7>`.1J-Z"oZ\nA4,M-?ab$\m7$FTdOE2I,hs>7F1us4>C
9cnn%NJ:W$`--1tDi@>OEu#7%_S3TXdSo6B6V9U[YOm[QDg3==eLh7)dqYH2CI^uidK"2nY19hdFYd
i`J2Q"p'.'s;"/^*b#;8!-+7DjjAs%[?nanVtbjUk=k_[4^S,9rO0@"0scAHO"cu$tWuOV+mMHrM=i
V9q%/d:4,Y(VN@G:.pDhtdB,M$bKCip%_#"T;eG5I^Pb"U>dF4).hH:q(peh`SpFuV1,Bb:[si3)i]
SUAfforf.fJ`Vf)cY2GNsuhi(O;R+FJRmR\L9$.4&Ya/fC8mSWjsIIS9rNP"QSO+X7D`-"PJfj50b(
;#]]oC6Fmeg+7hUi-1T:>s7U;Dk"LPn^rDDX@a@(r7h\7T71sa/Cf8^YOAVU(/2ANTp@@UMm_l3^@M
+AW)6-nF\6[*"95OY(MIg6.DVH>%KH7_ot3%[JRnMhDdL0Eo'q#M`2TkUft?tl3[G!t3QaTRW`Essl
;gZ+K<6[X+;aMq_J['KF)u0+l0=g\rFFSn^\%0U[K2U=Y;#&L%@QP[(Ml_7;fbnrcSFH]/DqAr=4A?
n>rQ7=E35aj/]?6-Vml+E!-In]<-l0l0Vs,8T=uJ=HF!4Y)KuhRUON3+<O-$=\kj2frQTb/^ULuI9K
i8?l$X>R*RUqF#RO+>^".$[rpc;<P:'mhn_Q^XQVItW,[7_?J$eXbg5c_",l08nMJ%]!Wf28ldh?8E
Y=7F.A<.O?[=$Y<1@@e[[LdeKkPhoLg-C`1D-1Br-1qVhdR^!iK_!pcnpI\(d-L/eO-3eO)*J:/Soc
7mErN>QA_SXKrR8KR5dUc6\9>k4[k7@h2X=(3<9Z.0$'(RT!9B9?3q1fka:)\SiI[MgeVT=4]"7V#l
IJ\!:F="KN?4:'jbbM=>W%4pQM-Kkl]0d)^]+2cp_]EBUbXqK:sjTa"X!a(m97_b")PW4-+s9:i@t+
Y_E]KZ(U8qRQTH\aQCDK9C<Sh[^*0*EHm$^ITANLB=GoKVP:m*6CX]bln7u*#^%$iF+];UYp&B@J0K
Mk_fsPh/\HT8f&6(h6Qjrl.ZRr%F%RgVSasm]J;/sQ#+B+\KjgX"h.ACd<6haVhB.qSqZ,T#ra9Olc
A2eWi`pWU\92>qYEpSSR&<pIp:lrcr1HF,cRnTSlh$[!PN+d/D7M;o5#-2UNa&`ulp>4GXPNX=o5m=
qo.V6n++K17s0U'*rI,C^E/,nT=M_ME%Gb*YKgX++&4'm2Wk5MJXje-g,Y?Q8%/(`Wnn+'J#3o]2G,
!b^@pCs]XWd<L4l+d+<o^JpiZ\'r7SLLXgiT4?f26A3%K@e^;WGD=X$+[V0<o36c(E;TLf,j2AEVa<
cKn?D7,.D.g;lZB(pTjYf;-+Zbr7I]9(6@dnM(lZ<n`ABrYVT?'T)]2N'hB-</g3l\G@akPP,rTGkO
EOhY_TAa3>IZ.pnp(Mi4^T_MQNfkCtX-'C-`O=;-E'6'L7be6:N;3ocFf([/FB3^&6Te&]7P6?8he[
)eP)N:6A+h&6H]9g8COu>#\`SDK$2:_K]^\"=>D#5$H)?U&+nLD./a_prLDK-kt1nc-9P"E%FVU<-)
I4hHrhDJMFe2'Jbl9SFqnn.@th0VRDMVCTj0bDsjR?#ih%q!\YXDr+#(@/Cq&NNh08&9tq(dPhqjkm
'c<&J)Zm@Zj;?d;;:Hgc47n(^9McfO`STQX#Jee],u<?U\#b2"h]'Nk@T53``\&k?!WI247h?Truc/
kGXV.;i/O`N"Ni!`X!cc`aq^-/^>i.DA1A4g&@P4P*A/J)\mn$e:u@9g,*X(8Ct>aP_BWV:&=/[t1M
,RMHgY(I?s]Fuf\0-$)F]N@CQE;eFAe/RTg4YNWP/u[RP_1gP(e4#C<">^]Zd3F!_/LP9EorCm?:=a
>Q=6@QDQ9b#8__#P+"-(jMJHugKTbHIJRIhI,6B?9tpMM94.hpP4jBVWRbrHG4]J$HgcmYB'l=;m!!
c<Pqq)lo)d/7A`I(UiZisDi!gi@r#-SC!(Qm`/LTD"o+QLNJ;<AsM$];G/=Uaa_KbS>M3A[hs5QU44
\g;VJ'9H-,TZmDagX0jWUl-*mbeQca[fOBFQ+*SR6,e@nfUH6p(imb@CULZZ2Fob/$#.%/h[co2Pfn
\1oIS'"!D8e6YB\1_=m9ldErnS7\sC>l%JB+R?j*QO>!UlIsQ2]ZRROSXf)L>l"LQl?i5!\JO*W/Ug
ACXT*QX+M3Mosbj"]<`IqTJoe_Bl+=[8adGT]WrM<f?:0'iZ@8D(U@q(Z?$Q_#BP-9?!dXO*+Ms:6J
COglek_ZLI/T-N4:+]9S(as(H*>XrSZDQ?'B=Qn$jXE!FU(++f:lkeCJLOC'_%qTp,aY"Kf4?7m_(Q
p_rsE$SV:FYjLcY)CPH2aj^i::aK*W%mIuobRZ@48HiIZ*gdEj3N>gP4U/i]Sq$Eq`s9S40*2+<tCj
FltDC?n03W'F2##RQb(.W5DRa([d9]IS8d-T[6]_?fNu(T3u#k-nDFg:g&/4m"GfbIM]Fi`E>\@Y5u
(Ush=:_+-^?^=p6L6chtSQbN1i\GP`Q+$YdZFC@'hCmJ_*hZeFYeW\N$.!"^tBqI^/?W9o6-OM"q^p
Hd.R)(n:6)eOtJ5-(l.\J9(hXGL]X"Sm"J!416k3](=H$1\s=he+b+=&J=HEeGT9=M2Wc)EB`mFG]5
&hk!1p[3a6d-56S-J[X'n(a>Gp7l-0p7A7dDBVM])pS\I8![anJkJD'AsBcPeWh`'!T'FJplcdq(dI
AUX/B74E[oeAK?4KMg;f[Y552oh[V,5,:akeNMegMCjJ6CbOH[>&:[Z"([9A[:_[&t4NFQ-uY[I+i)
'f%-e;oNI6l6?5[\9As3)*V]:^L=qq4(2]*f>]OYs@!K*hg@l5&e%(0+Y8dA:H=5OQGZeV1%ge=/,M
g]e9_Z0>+[`n<%_oBe8L,Ml!e^iP)KKbKT=2UI?4t!'RR<hq6!#+O"SD3'E08Nh/7@,hPSY(*IVXB_
dF!&#3PEd/=Zm&7n\3"naB28:YsB`C9so4tF7prhm>(k'R)]SV>&U]J:Lm%l%VBjl,+(8GCfArg:o>
dXknH.E@Lo\Es[qQX)Msn4*8+lp"UXro<%eopE1p68Gh\[_I-@LGBeVG?a;g8p]2-Z16#`Im["+$fg
pRZ.5=@#,Q6gJs8uq(u"XL:^DC+_R3foo^7&2&BTFr^(lhZL"K!"W4$M*ae/!\V2It9CbQiT]/*JQH
3d.+@i2>\@`hEGk%I1ECOe?QbP(Qa>7M],Mhhqt56Cq7Jo_[HPBhLZpM4^6fs']d2N9OVm0;lBh3Y+
[O<1:Cn@[A-9uj):Q#VSH""fC1f?LnsL)K0-T:s<h7U'H[qP0OgSgl.e5p8L>!X"VA"H611WLt:Z>\
e%DT?6'_PS?'H.BJ$frI\4+9qIkteVYfB/K(IAghlFAm(AqcgNN40.&4(PQfXVE,Kc[cArK\rkH(;S
ks+pZNme.hN$)\hOOF_C&Lc;FG:m>pIoZp>.tSUsXZugALBduYcnH5I>!Wa*3SCC1(E`f@?[5qQUXm
4FJM<Z-dHpL*of.7[DE=`g#m#\f'f3)B'fFYWSmuV%.DSoF#Dps"*[Ig;b_,8d(S).0*dbPr]u&K/,
rS4"$ktbF[)n\t$\A^JQ)Cd&P7qFlN&8Ft+FfQF3$D9'b"lUU[s(fHHhJ=I<eH/6:D:WEZcp]HOd<[
`iHp>_47"q<Or6a&Pft!5JpV(11VL;'[\BmiVID[H4&\W'1?ZqFEU<N4?V5%6EPVkPR@<.Kf.FXUc(
_8N_lSh<h'^sgF8?]mK?]kq*6eHKj.;9k@<^Uc.XQ*R(Z*bJmiFH.ZBCJ/'%;=6i7HPh+lYQ7P2a?7
VT8B9Uu0Ag#t9IAeKE1Je!iEKAc11S"m#?Q6)TQ$f\G\h.5F>g1WY0pHg*PEEiZpZIGK3O1DOj0R'?
3V3e*;(h[YD\4\%JL4*KdK@IK,FLF"-BCok_YDH^S8/L&t&R<&E[SlD5cB(7K32Fu7P9d`\:@Di&pg
\_$<]2r;oJ+N`>6Hu+e65+rN+-f)#!,7]c/eUnTVA`b;m!E(j-hmf;X]]iV8c0%L9ttDmm*$XCI5-s
Sr63;U>("GZb).P5OWs@[`u&$R:"J%PI9,)+<mXR1:S<`'XT0@G%'eg_M*Lq;9!-<6A'mVdNd[:P"m
mYHV2eX7fJ=j5A+&,L8o`/DK,k?C2Nh-gKG?Sbp]RZTdLAWVdcot;@YB<8j]Q!m)^9\:?p1Ea`6F`2
nskqiob8AU(H+3S)HjqF)YHn%YOJ"ljh=di]l>HD@8VGEl"9eWQbTnPcHK-/q[?2O8K=p'<sbN@oL%
LIP-<JjfQ_LUL-]Fq)ZRpnikI\Vn\N*hE8n`NS3A<Q<d:;F>Eu<,2H9h7/R_]!?c%q8jY-O[a1U(b,
REmYJAQ5?CSu:45';LN@OX59MZF>*87isDNd/2j<*DPo^`TM$]`6ra6V#<rFegoe8G>AFHmp8L^h+$
L(ZH6gV(JfTd"+LODm\BdPud2kG<D#HY><JCHrrQ(g\4J[<<)IFXp4"RTCs(U,TEPghqe=TCO7N]>?
&nJV@+q8.ePGHW*8gC>[t'ODkK!=gLI[8q=un8:OVOJbI!413pUP8A#&Bf9NKkQ@>fJ2P%(=`*ML)(
:ll+p];_`B4*+\74L;Gnb;FE_(-WB-DLTSKKL+f3ZUKq9@8Z;?$u\c4)`Ms(7;^Dt\-4K]nuXNOAWO
1@Xdo!c5YsL(6cX';3$Tf<,KACWqs^j>>XY1Wnj=.8W=N)%1!]7k=%$e*8%#b*>b4P-T!H$QaDAsH'
L9`h7HTJ4`+a5C$F_i'JeD"$WA7&,&3u]4mTFM/B2#]P=aL,OKt,+/F'/4W;>-:]ZW.RAP`8<kA'X1
gY^43'ZdbV(??8=p8DUNgh;bZ1?<VX/CQE&XPWH],&Au,^f$1Of^9mIVmdP1.=4`#cXpG1;j'D'>`Q
u;Dk(tI,m^OM%dNt'u"aQe\q=O:5>+<,(HW%%R'4,57)VWNFYcJ#F"%A87,+S=>^^K&$I2<8GC[6W[
_aY&1m^m6i@0$\Z8?k)(hj1.+7cUiL^0ujPiVs5KGYq<Y%*H2"^I6DD$Qp/Y"+5f<`(-HP[-ltLR#E
PS*"tf0Oqh$7QE]ia.jtS@#[OBu]bm>-giO<ifM!_1?@SPoAdb&6pY<%CW[fHlWG*c+@#!,$=TnPZ'
&;=_<s>rD;dN?$R_%#J2t#sM!q>\""Tt3ViumXY2p]<%;(u%eo@(P[A+C"B4$%_1OBuV+`go.r"c%3
@&<,3ClWTXQ)T:q>NOSZ2^+b2T".*@UrYIf4$-rkQLfi,`fo<;L@spjPqSl`dEP?SkZ3^a1Vb]08(p
+(242=VV$3nkAM-7Y5\*/EO(QJY<$h44mGU-B;0FE^kMBIO^?3_.A<%OAD2Ag1W9N]'-.qP_X+XfpA
'aul.j6YeR._kiA952#"*Y&l`02=UTWm.4+1AYB.]a'P@d<Xumb,2:X4n#R7Lf+C=:`9LAC>%$<'GR
QdS_U`'`Z#s$3D?ALc8FpJi$deNhcc_W!<sdd%8@*d*@b1A5;e,e&L\T=B:/JhZnNV86Rr%1#3jOq'
jJ/=C2*!3*V31&:!Hu=cT#!$W3f_E8letRF!'UD3sLE!`Ve0m;h8AuTV2,1F'DE&=5EV#Q;=*>243r
%%i9>W\"7j;ohS>SXCCOX$0,!Lbdiu'J-0YtbClY[lJY$$*?h@_k6)-^T3ls-$ne>:^\dC5HI\G[\o
rD6%h3@2pk;e%qu[4>d#ci1V`kOT^8\Y!,"`38?-r2O4-5=C.I$0Qg>gL1J/\gMXi9U"9@ZXh[l\B&
=MK8r3F=%ZiRU8Ta&hHr1q@!1am^#:aO&n0E*0,!E^E`0J]1oi!(`KNE([s7.T7&5Se8-p=LUG]K0H
E.jh`NVF9,K0R#5jr%t_r0J0j6kAaXGF.e&gOeVk4'.Bo'\,1';g._!_?fB&Q,m$LoCMKK3?"Epd])
,RbO)7HXlCut1q@[,+XTe%un+9Z8[>:iPq;&b#O[77a&;nL%S27fdao5?dU=+$NXNA^bnG>)B9i\bp
;,c:8p*/BtDjsNY/+H4?&IDn;:Sbg6r1R9T6]OF<3AABtV>Jpp0lf#lBZKkK7?G/7ZPa>B.I>Xbm7n
tNf^qc-KCS]e$5c_H*>jdF^LQ)lV3dhereCr>"W%UEr5uq+P!W;D=9DYVh-ue)ebW:-;r:4JZ:)gQs
5>J4tfZC^Pn48CTJ^DWH_$.]17r1do]YcS`*c@`\E/DrLEk#@d[(5P:CBSs1q[\o25#Ol$hu:X$@"E
=T]D4gQ,o.ga-6me+s6J=&F\qq6g;Wm[5>ooYbD^IsTn&t!Ij\#n^]!Rdr:I)%IcaW\-KCN0:a7s76
&^]_7X''e5P*`M<ak82:*[sA=Vk#2ICSDni]7olN56+Dj1k<LbE10:gB`eJmOfk!W'F;p)!`,*4u$Y
K`XOlN5k]$8I5!l_'1$,YF/^];M`oiV<dYT!(IWrK/>,rOk]^Eh=R]7b,B0auPG7_g0pmQlETi6=B`
MiTCX167e@#uFe'M*A>L:_JB^@bK,&labq)rq'IHd?BYQR>U$`Z]+EDR!fJKp*KQXPU/fK^5?-&+.h
q>H(K<VWO+-VS7uW>l&5oJe/u0TR]W=*qp;D5X,'m#V)/c<sQFOC2"+<eP9sKMjJ-X=$`d1,*DOoF4
%<1;E_C_%W`If_A!SinDZA/h!f*0RpGQk1P4[*)8.rCj_1USF^'DL-"s;gsKpFrX9Wo-@jIJA!Nt`W
sai$^\P:6pmF*G?LjUI0.NuOl^^i&Hup(m#HpqfeP1f[fF`XlmP<T<?4$s;`/':_/s?k.0UYarhS-[
Rbr$.]7W_h287Ynn]BOb]n.8=-BKl+nA&euis&ao`-kG,NT`CY"^EJmM^_.Z;$oeGf(Pk@R3Y,(k>I
m)Rpnjd6[DG1qDE2Ui:pr^1JTMt(r)Y99:B9_FgoW2)^!l.0JOL0g/"k8M!MOL&OaX/Uou:,./!d=F
[k49uBi.t(BLV-&ESFD4iLDEjljgpcR4Z#0S\u1kn5uG'<<?8;TnED=rWu'4XchU9JWhEX\<HfA;e6
[6;oPD_iHPt_U"qO!9[BLiVql31,K9.J(@X:,<K^nKP%-_AJuhC_8r53b$@d*hZ9dT,r0+bF5D@W-,
&'O:mY)*g/hUiG7k2\UN5+8KR#Q/?J,@Y5*)+I,B7#[c^V+9V.C:6R`*/1n3;)IL1`\]Aqo-2;h.'<
E"V35i$b!q7bpQ\7cE'tcM^VbXp%@^r7oDkV`Ug1-VXeKfg7=*k)?XY^/nKm:Tp\VCY>QiS;)hIlIb
\ECAYOj]U!F0=`:8C44q(S8#:GpL7qVmH@HsPmM0lq%jpob3()*-u_XmAKrqu.Js8KHH@ku@;0BsM1
T)IF;(LGgL"ooWO2*NnEe*TcNLe$Nb&'TkDZI2Wj4N5moGG_>,P>@(@.`PK&8>[,pbU7=b8H,[IGQo
VQS[Sh@lY+8d!jIcj:.B>5&AaM5^.*05VIlVOn;+[;Fnk"Q!=^FudQiV`5Rd4T8p0_7o#A`lj-:]MY
]@i0UDXD\k0=k;k1fd4==')1$F,a!k7s=?%.&.u@T6;brU%R0NU0bV_D*S_2_O]Qmp2c&+B!6g,1ud
-Qs'Q"^4LsjkPi19?f/A=l-"<j+Vp[?MIma"b2C6o(e,['UpLE>K!ojm5A@Wp1u'(dJF<N=:g/Z1MP
;3D^M<-j/^Ti'6R2d4;dDWqoFF4A@H%2+YX4-#E^lo.!N?2]G?'pQoL[!p["Xr+Z)guGhh6@5PSBY4
-6YG]/jao32oo;uU.17Di:;aY->#:o:gZ`jJ;E?DqBij(cL;;,O<)ht*ut.#,9(V"@"f,)(,ajB`2J
@t7PC,f)J>F6W30pl^9[ea(!lq"0XWbkR6N#8L`hPXX_Uj])%jCZ!'gNU6pXepVD_:Yn_'19-mP9a;
(tsQ:[Ca(WJ7^p]Gm"O+1s,f,7tW!(\I96]9uF$I4UYBZ>b?nD,@6o2c'XsafrN>I8Qr8WKX[I*J4E
5GZ@VkLp&CbT"^_*MB)T6QZp8\I.2pC)TH\;/UrSCjhQd=5I083Z#UKB3rlT/]8Nq(172Ls-s-)=R5
8h4bLm-a9[LDuo8k;b5;P+5ie:n?K]S]K?WpK+mklp%pIC6;aVl]72/ul"6W9o:ef&s>M9Y0;@l"'3
R?-^*>2$PjK7X7SnZbpkCTVgt"927VciuHA#V,^1O9'cnOTg(DHZtN.d?A``SBG@.4REUdmn@!=&O4
Oo?-R-O[O"!ZdbXU2:KXFE(*?kh1$-L&]Wr.u&<m?h\OgH@5n/E$RO!Il'`ASB<e(+l1We6[0u\6\V
j9C+(-&$/?Dgd?<n`8k]eM!Q_s$UgR;<@]RU8mc-q#lt8r?rD:pnjoG+3pR9$cUGG-&o+NU6'7+-6W
JgSZWNm^dc(b[I#po^5Osk8be1[-S2%c:BF1q3<0hqaE:<YWHd`!#7kS$fi\*3'8\Xgl]pY8s*Z`Z*
9ZY3'TiJRKL)M".-Qra,N?Nob<7E4slO&;[$n=0\6<dWqhJ/LeM6PHWZ4X6SdXYm3lEtk9FJ(_bV1T
?*k<?Y\,q:#NcM(#)t7^:3f8Q?r[2W8.Ku"?3_Ol)fP1t6$('_(>q7"s!74qe(rRqVk8BTgF)kkC`l
R%L_?qN?7^t1$SNBGah6#?&m6?1:S`NGK87S\:U3IZC7*36-G18:m>0hQri:8$<da.iMfEAM3^;^YV
tM6PE]BT]cea@YNU8O\Q9RGm2)?I#g`@e(!S.9p#DaR==pdn^:U-H,PYAVuBp/KU!+5]Kk4K[SIHS?
+='msfA+""6QoSZplYl0Sc%Wku's9A_`ZX"B'8?u*_s6OASpt`]F]EL-Un(s>i;`>"f;Bl!Y^sUZ*!
%::e:3%8X/]?(5IVqWF@OQs'IiT5?GL'9*igd-G`E"9-9t?RhiP3R)fapGq,1p31>9R`n=5`q:duc=
r&uWm#gQD__hr^p^Y47J[QpYlEet460:8@N'bpc-6-[!BXFWE#bF-#nZkNPe8\g;*=)T!ADTJmsUOl
j(iIgGF)(LBaluP4TI)Qek%P.L=ODp6D^OH#;$YL=oda@A%HfF(`TA.A5C;[*M@Sr\cQa,n_nb=oX@
4%g6H+F?8\YI3gg&K5T248Fi"M`SSM@BX;cG"oOOl6o&Jk6FL4Cr2&g!]>63t9@FL/k,f.N9c=s!/g
o<ZF,+TsbsRTLb>W3u&`\i&b=22H+WA6su#'a)DEICCOGR.0VfFo!1a8gP6Q.R^QG%e.6Sg++3OWOX
&<VBc(oga*k8.kc&4'igk\(Le/&Oe-9J=TmBS/R6<'5deKnP=c(W=XEfgCgUjp+j1hVZ<p[cc4[g>8
223&.KC3b_7>%n#"m#"?G]L.=7LU7&.9+f6I:K0K\%7K\"7PKBqOOMOq.CFYDXBd,-$VJF+umj.Zc_
qbh$^h!3!?B%l%RmTUmroDjI7cZkT!`Pln#WP-)tC3ce[FkRFdQT(X-T5[(=/L>iDY7Hb.65laFgcR
u\hdpoVM8MuB5VQn-HGq]I:#W8[qX*=%J@]IXr]UARSRpgSbO+=Llj3II$j*4*sNe(Q2PP)I%WRT&2
",L!cTg\L0N^On#K=6U&04Tsk`GTZ`'<dt2<+$4qU&+7+(9P77--h8YuKm>fd-Hpr,qKlt@d]IDRal
>G9d`%Uu"121lLMICua+$RSV2r:ff#[J?k)]Tfs"?RiZ)_9m`oGdA7=`JtDB#2PrlMs0Uk,PG>$7"&
r"]h[`W@\'.U@Urb!O4U-7boj-eQ&C]f<J[fU6i)3GWB`8/6rJ6s3-E04l=IDsunmWbO"8Df0@X'&?
:^-1eOdK^TeD&N\of0!&3"0^QVpr/GpoitGApal6PkH5d,'B1pF7:ZP'hZ"&R+0>c9M0cjAt]69flJ
*gZ>4,Uge9jnh-#q;CJ'Gf7_E;pY3>X).kE;`5kq^,oFB/_<6m*o.)[0Pd9Wr_U,9:hXf.m0rj^;KB
S<E\"nTr%-n4_t\*!nAb'[!UWL:LFk/%fXK<TK-NY8<'8\^_J/eFcIK_Z+o2.JF\59SuOCpCIJ"Vn:
<G6@\F=TWBII`aZ:WoHJLI-EGMB-Wpg:;$9ZGe+p7=NQH"Z>=5V^n.Q8ADk3(6ne<8k.)g+rnC`[(2
_hS[oMMUV7CGcUHKVL*NSc62uDp'LeOe)n`;:om:UVmSP(T5C=[[P$HEZ2fm]R1!;3>bUj*2IrU?,4
YZo5cq;$H)hR`qH^d##5L*nb2[(.?dltZ-r^eiWjqsV%Z0>@:4TS>XM]a$mSMRLlS.rNaVDR?]B*qB
LpK6#Y_l,aj#<_GTA2pI38EL<^RgnVOTFuLHQFUQIE\>(:eKf!HFd1]TW*eCM3:QRm2QO?@=:&NP9<
k>G2jb.M.I\--$&\<Y7R_<pS,+7\4d1qOeBg7Ah"22^,)XEM>]'7VGWRZeUYifA7f"&%#nWoV'MaFi
jt,_K;9eVU"ai#51ke"ff6OFK'*3q9e;1G]<tId/W_1bI*]%03;C\^%LgmkPr9&UpM2>:Bm@nI_)o,
jb]"ST_6]SA7eKsN"<;S3ufUTWqYj/7&(#5N*\0@bGn!FnJ+9:>.-U>7Rp1T*,.f-m@rPni*kp::W#
PXW<V;,F/Xb@jDpml_g"I:5]$Ym1(4lBj%k'__u(ltD5=,KWHl"HeG4C6lQRdc#!V_PpHM`1FN5/pY
JolrRi7Pg@:-me'_=DS"o.D?RGKu>N7m%O2VUCG"Q=LC:'3$s9MWEl6kk[oag8+K$R=t]Gg$bq="pS
7P4">K.8gFSqLJVR1mJ;4S4hM$r"fVgIc_<th33bfPKI2#5^A54?Fs>>3c10YZL$>PD4SHEV$'DAM8
G.RXH,\>a]1NOZVZ<Yp(;/u'd\n19o[@TW[,;A.X'YG'lPY8aU-*T6cS<VoU/@kI<t+Xq9\(6^\_Ns
NnqUU^1uk3=,&*sb:jBrrdX2cck*lE=CA4@YYWbbW@6'X"d-TYeAI2q$O)$>1CHLO1.1B%ibXlIk$X
i9+`\K@FVQ6se@^j![AHF=g8+"*`QZNJX@m2X=i8N)9mQ\3,.lZKquPZ&a26K=8GLT.AKa@"Nl`_l[
?ZSJbh!uG2rE?`_"Uk>/4nR-YNT'&ISUGm1787P9@j_U/;qI`mp5jF>NPtE$ro$)no4SIcgpYmHgm]
RZE:u<3[mg6q"^ujINS(OIt)FFd-Bd\]+(@/@4q]dWpmH$k'd3/QUt<@h"`Cl<n>^Ip$q/X:HlGqri
a<jTH[Nl:^Z5nnHXO<lHapj$3^KZD,<?:@l^b521iVi&geMId/F,9F6DWJPPFb9r<B:]k^K-D4<MkW
+Y>;6Hf)BN@.L/`m+PQ+r!5S_.oa?gS>Q+YHPU('AtV9U:\``\AW>ti`*6cJ,m5_-:uPAH6UN4.N<X
-f*Qs<(XR9J0R-'q+"=X==<D>!H6"t)8hb_)G6mY(M1(ZFg:MQJEKPR@TR_Hk9*0u)%RGpf$37LVt[
o9ObhmmN@+h^ON,&'$LU3TGEpCtlD<JZWp@3CY.NkOZmgttWX,kI*A_9IgrMrNPiVr4Cb8k)NR'=O[
q"9^"c*-N3=ru5nDHhc"]W6SN8![Is@>e4Um([kZmAP*_C2D#:nMjYOba+_JAE4o-%^3%KL@.nnh9c
IT7&M;X/GG-F8:\uklkoaM)`Mi[<#G=gACKc%q*)ne)!;rI1]&ZupS445("It@lM59,U6+NpW0YO!)
`CB880D'0d>B(se><2Tq3%L#!gR+P!@Am2OP5+jVhW;t.qQ[bEa2CC*`;%>P1FJ2)k"coTRscVuk(!
:*%N8Vk:+$F<f8"b8.plP5LY*HKC$Y)uW6T?K<FJb\TDuM%@sl0D;ZXE^?8QirUuD/d&6r48\)?UGJ
!1XVm[Z(TKYk\<HkP]\o]\9i>n6f@&s4)mMRLp]$uS^)d5Z(=(sY+s7C3gLgXdTO.Ms)*,K$iS.'/r
J]Iso/J85/.ph#l=WJks`kRr7uoU1-?8;/8Zg.2.3g"h\?HFGaDCCOXp<8\gGR"%ec*(:'qe<)`@2I
oraj[UAa-r::(PnVpj!=Ar5AMPgq.*0fHb"YG[(I-D24@U2F]%]$=fK$(P)$bd0NGm(VL,p(G9F$@,
f8L#SNXuK=jJX^'P)0[#WaqA-.XBt0hJ/*oqQ;DlcDb6K7Q<&C8[3-PP1;L?[2\oM"%+->:STAhc\5
ldJu>2(rl^'@1G_ONo4o/DB-pq)Ij&aEZ]?p-K\`M38>)MkTFi]4h@3aTn(N,X8OK;XboL8,VA%q;C
2EdFO3a=[D$4W&$jATuTIOP`]Xrf=\OhcaX;:I+oNC+3VR`ZnjaV"=V%7fu@n10Zo4s[gR519r_#hI
L]4Ka](LPi!CJmA-6Q,##X;pA2:8?<p":$WRs8,GNiDZEKAIfTn(NIeOJGB32kOpRQ6_b?/Wh5eA'T
'T*Y*ck>j3bo=fSi=KiCPM<&_SsG(q9OXl1_r>`;gPu[Q@U`b+;(0-L($6l`Zl\"D(S2Bkkt6X2DN*
qV^ruCd1it0;D,g/PX@\-oNCR6g(*>ln.Mi`p74T[.dZNZa5g1CP>tEd+2!WKE-`oLJ+dT0kgX%/a2
rHO,iS^=^VWHYquQ!Ie[h33C6/)8LU;R#Y3<=>J;O*5->C^0BS(eqnKQ:;g<T(Qp^23pn33nXf&@W_
1?X^[>ps9)old3?tIWb*6QTi3qQ;cHHJold$f'kDHDV(-T)c'V`k(l9RhRSF;8OJTFmIA9NW-hrS]\
B?qu<%O4^k:[H#N@%m9g7<ed!m!7[&`M]:DXG\K)`a=.'+nmX.X2$hd]he+]tmtI29NcXE&[IroE<V
Z@.-(^I:*qh++,N()LF(qTS3k.<Ko>BlZ6tGAb1*=@dMn/MH3B,hT#O?$)""[V8#4J,/^9IS/2tqK>
].li[FNJ1u"-2rf_l^%XLES1,3o*6p:n"q2a`rgtCI@^!U(O=7,9!P)9jK7jTnj'`"d3:/Ue<XCO@]
Z.mb;oTB&I@4=rlb@]R`t8HA;G1\<AHK_'&BI<ARZ]57;+?CpfX=3.9g?O/tQjUn%CeI[A5iMA)5??
9185,@6Gf%Cr`,_3r4tJ(ojRLb@9A=@hN.hD&Lrm_8(O`J_b_-Um9Hn!lD5<a@ch<E)_@=L[]8]&P>
Ob^OWrj<E[K,9iTh-Q<)S!H]nY(gD_D'=,K-A-ReJBg4TiZ`DQr=.sEg&S1gLU$#rIVU>=k!EKPPZK
r\+'U\pb0GjCJol]gY(%1UJMpP4[8`;bR67EJ1<DYZFDP&ek.rCP3BfU7:-S37N(8ZON=X+e)bX_e$
R1WqM/a8V@Q+phg#^-k6lZEb<`9DAh/ciI+?'gWp4j*_0d#0YmKZcHk!XS'`CNE_=VTS2O3s+NeB.?
H[IQYbZQ4PB@3!C[NP6W9NP4.6B6a@n/\L!TsC6*E3QBsVp=#G$:Ot)<tLa7H#j#;C_5!IYYW0ZWe1
=D%6SdGa*(K;T+QFuq2d@^>gSFaIB:Z@V\#b\Op(K:C9o(SJp0nJZB?g7_/-!gm\Op58sAm13[Asq"
H0f:OrPOlXE>qunp+-mj^DqUN,Ph7_.^][i6Do;uuaGU=`N?,hc$Y;]jIIiH)5'Q$,(0n'TEl>9S7W
bbO;3(Ae4X'rBJ3)P9B>;9XN8^Vk"s^q_h&k75Q#g'>"]c-c/D]&t8kb2Vj7Z,*99F@%a0)[97@DN[
6J$G3%5XqJfW\gVn$d#IHTX"KQiI!b]V]UrIAnAOmADYJ>.W\ep@UZ7\b(5g>4_Ej0"p\AW<PO7@h#
\\77B"fI)#9url/Ogc;+t'5FZKE3)p3P5C-]`7Lo:K^ler#rGcg))]Nq!kbEa"]r3DiEJ,9.I1ebYq
5._!S>ocmnHn->g;Fs=Fm[`.%&,qs!G]HD$S<rK#8d7/ko,Ra8l(AibKU#FBMSjH_!hbT:XUpl6*R$
Y?meDp=CT1FLjfG>RS>UPNCE/tQT(TdT^3E;6q3'X!61&%ZO7$WA,WcePSZ_0OfSZU<GIJerq[Ei7n
6&L2UDaQU\?u4o(_L2><?edeU*Du7"LQ(Vk2X$BD/93k5k3N<#uM(;%gbb`N:TKo.XAcHPq(IU'bWn
Tj<Ni6^cV$a<lKj\:C654LPjA5-IYr!*UA]ppI;1L-ghWGi?MFJ'E):DW&Bo&KF>,l-`4aVJ[(MK/#
eT6gKR-(GhIs\o&iP5l$=2lT3c@$s7+onu=$Qfhi4IEB8Ze-p@;N3*QXmqqkc6aW,o\C2[A)Kf-2p4
Bk_DF&j2o[CmTm(ZQKqMX#E#]q"HigD4P%UVhp0kAUC)"q>_>\c.nYH-C,;$\.7QP6NuVK8u(d?i@p
,>LorA_MY%d*6B2\26frIGA6L4T:\&Rno.#&W37,UV;0,`n]>FQ^kl(9*Fe%Q/m0ls6);1)0@J_6Kd
s"OG3U:VCdqSj.d?nkBT7T^@#oiE@3E&Y5+N?>4XQpkL7Fb'R%DBs#c#,_g>9^sTI@YQ#r%Q2=KrVt
Cp*_t07Npg2/n+U'`C*JWAVP8ibW$i@_OH*HXWk)'Er6?0g&@]V\m(i;\c=<Ie67o:#>B(Wk>O4HG*
0uHg,(b+Ym>\^7[_bB6^^<Asf]s3/eN6bddRMEY1\^:_E=kSCgU*Uf,6l,"Gn)cc%'ar^h[>N*qg5-
!E7gg,UNeNopP=.R\q$=\*@OprfQt;*RXn_=J`*UjDc8-*AD^5,T59iaL!Z)ADlEU6TXK\_bSQkJF#
^geQf6Wi!tejn;(GZ6u<sFR\4Fhu'0ke!B&t1PW*E5&Q<VO^C_$@9h`U/R)$0?Cm!RX$m)WCVrhsl"
6#B%oDPoDV,;%/88"[)D-1g?LPP;H2$24i6b;r""-D:5#Z$8$bkO-ed5I6i\!f+?$F[(d#K2/1l;18
R)[jsR+!c)rSIKSYX30YF:="gQ8t-^;sJp$V47]HE^XSV(oVrRiSgF,nguDRoufHQITumOqi@ntooK
Z3lAD;=@3L'Z.ne>hj+$^iYNbSd_JAbVnBqg9pZHF_D+s*lc+FR#dgE25jrNDAE=cO!b(g"N`;S!9(
+`TFp.#Y-[d0,Dr:]pMaYuhJ(h#YuUK<TkUCI(s-rS<]ST?9q`^![gY(]e4$blK!b7'Fgb*7e4%9Ka
iCr8rh,ROeNhR.>%S34[r7jZ[8[WQbgZ.%;4j98CiEI'T2Bu]f3q/Zf#8o$G%!I/H-jg_9+XFNG=L/
#MHob7p;;3-onHMa^@L8rpiR?<:bSC7g%Jnb9i-+pl')soFlOMP&D&AS7;5'ZVaQcPRZXi%H<jtKPf
WcBem=?K)*?9"5V5Xmk6BN<:tiZK0Ej^6luKkjh>??#N%@@-:f]fa8\S_MDWOn8dpPPY'-kuT\E;Kd
4L\.hTfR3eO,c>bi:ol=LW'-+o2iV_*thfm&LYsSpBL7Ult0.Cb6e`pmTf3LOff[(1%7AZjR$tPg=%
m;Y6,"8`*^\6b^-VYRm+:F]^MCuT/!3A,D3<h.u`H`AFFkBRUVCOZHM@$)U\g8^O?.\k+.LGVYQG"t
brEDcL##+Eo\1%.('O.FIR:/M_%4hJ8YH13?5i:PbND)D^J.Ec]BB/s>?bH?g48YEroJ6d_`5q$?<4
n0iI64rpoFSN]J,Ries8Dg*T>?6j\TjA;MA6.^(9qaTNT`8$lh(sj@^6YedGQWH:_?FT.J=hZMf,$r
+%nOVf<(g>aLR$+m[W<+.fFnWof5eKI9<Qoc^!G-q#>in5a0C?m.MoP[=TF0fJCWc_Mfn8YV*i,[Ko
0_>[F[`:a%6,!I2PIJ0hihpF@[6DbS\.N-dt\%LRn-#28Ql?1rM5;P(;(`7j%G5u8`M@o49^Nb;m`D
eb\MDLPA*5Z,g%l)S*A=<hfHd^h0l]<Z62XL&]fXHllt5q*,ZOo%bM+@-Ru,?in^kIYb=4?_?M1U"Z
n%C9l<^%BDc^?EG+$\D;3@MU:nAS4fNb7goi4KIT53h6GTT02tVLMY@8ff-)QHK>lijh&;pbeP<LFE
g"t02aK028\^^Y&.TN4""H!(.)l?!EsJ@]06n2r3!_Z3\IoODbljt+\07;6^q7?3NYamJO^\k-OQ`^
$YiAY=QjdESI3'gY2\!rL?iHU\%pFdZFX1'T+`<DiMhFo.?h);Vq*n<&u:2ZJNir*7SZ<]h:/<)Qr\
4s;.'@oV)PQG21S[iYkb.8AuDNEs74e1_/b5YWNK&Am'W9@Cc\"B/Fi-i(E/[R=rH60Tp!K+UoSjIC
;T+Ff[*#M22S)oKKG"g?j(NX3;3(gD*6+BdBCWIF`C^Ye"=CG&/Vm)fd&^G"g2>T^].-0W;l-8[8qM
=.0Ai>/,X)n$O^_lH[HLeM1\7ef_O($/A:teM&ME&U&dR73h6[2IAp=@Cj$a)'6@cF>d8+NIP'+`p(
q+"_RrRe#Wb5tO<0?g`c8/Zeq,A/MLdAcH?CaAS78/;g5:V5>VNB4*3lSApr\\o^RqkUR\l<D^L@hD
VAq`[6\V16PD-G1]Afku=ooB2V3cBD/??#&4*[\l[S,9SG5o4(D,"5=7t?K!9Npp]_ejVT^&SE8L4\
sHWrE/+egg?0krO(o6iO3s&%qPg?BN1L-6&isp=jMVGL'QQ%,<.DP(Um8OCDV,I9-GB5:BJa02XNZ8
QoHRM#45,SPc%RX?I;hJ_1n[r+AnTJ5>s6Cf`&2"$Ar+O:<jPp^&KS^[X]X@4aZc[7:q1]s@ss/N["
5=1`t5!5$#.Q>R&0kI%RMAs8.nHR/.*,lBA@@&*b[JZF:uPLiU#W_qo;hXQK#(6$b\8'=^Mm8"R[[a
XN>2F%69*B4AP:JK=@$L=>!AKE0mL+:VD:7oQ_-_,:'IooBf^e2&(04-cVE"GB0CJRT=-`:->KDI60
ka5'X-4SGM!<.bI^Pb`(GTEVIqBdKa2PLZk?dgM4KMI#'n"SYA4i;eZ/<%Y@@!d?/Zar]oT;Dh(3D%
'Sm1e0_!\LqGk40l2OXZ%rM`33D.r5hV_BPHn-I@nUj'7;2BT(FP^WGU1`0II03&();fYCH$4sr'ie
n@SOLp3K5Yg,91V5cR*oRmZ''OY,f,L<E1bpqopg+4a'\5?JI)**NI42WY^Z>DZmfK3mrX0UBX=@fA
UOi#4)oadc0i8PD26Ta)T'tPbL@c*.IEfj7'I,<\CkH/(`V8elj\=aO.G+1ZkF]VA>_jqiWlPlu6*B
m)%H1f7.rnQ>dOaZQYZEClA2UWE,otd(a4*Kab3X33>&S*=Y?aDu`UrCggnCEGFQ.dt"qtt!,\TGr<
cEG`8C&p!gq1AQae<^qqjrFbt><3I6#;*Li=P_tGUL8cKJgH*_RZJ*ZrU4$KF1\!TnhjPdO_I(6\=C
#;`\;)FBgb%pSZfc=kI5qEj*(-q&^WhVDBJI7cMoN]?^F`Xl!_^.I:G9D)#sKB+0nE-1KCYW(9'<G_
\(SD/$GDAAZ$'C%&<)83*^s\&^;X2XtnGc68F?Ni'q$7Aon64DuS@,hWKt@4Ur1gQGnMi*K7'@qSg\
m`XgU5'+OZ\d*/;39R$,5%]Liai_5@T6l<"n3GAfM!/p*12+LKa;bUje1T$6.g^UT27]%&tJHSfUJE
Ieh?gPP0S<H*U_GCq-#J[Zt#SRO#!s9=$I<nVhL-X*nW!o&e1'RU>H8;66rJ["C9t:l/^-KXs+=K][
k^pSX72H(7/%psK5iL&_K1merROBP=B'Ct9n3Bfn8O./.K#549p[3b-`b1mt.Q1i:fT[:<gS)N]Qq^
AJ38=M0JY:8)!@kOR,?*g`EmpQEY*g=>l+pHN!ue*TddV#NI,pbQ'NRH3Q0(ooG>YS6f7\SolkG"C^
>lX*Geh:j."11B?bS'.JjPQ?X?`$Tk<7<a6:0c-^O'NG_ITu<adG[;+>Al^J&2dSYo_sc#2I\mhhY0
1<4/ADU?D:9,D6JXB@(t&gXr6c@j.(-b1_A`3_h,eW?5B?_::g>oBNBRE^%>NrpS$:EUqXQ:\Gc:GZ
4#q;Vn$"*r=)F^\d'Fh7LueW&;-#FB"G1m0ARkDd#"S=<W3mA;'"FPo"bo+9)0Mg=W&l>''\U!1#f1
b3!<KC%f@6mk'rL%g``f9J@:mC(Z%"B^jO$[8C?1,Ke-:2`2n9=]]riI>#op>[-)8qD\DR<c_[u8P>
"0@>HZ2)<Lb!9K$k`\fbbiSn5T60ITP;FE'U4lDG8fca2sdG8/k/IejYP`)NBZT+WjRS5JN^'7UkHE
\t4:]=kT`VPbpg^*b8.4`s5,l:c/3lEM_rb1=Cq&f_6YNfLnnPM)JRm%.8A(ffUR_%[3`lbKY/h\.'
pNbgd8nT\TMM1AsUWEb+QfFVPeiL?QTT9*OCV0)O!QTOA0Mh\2UN&f[+FaH(bl03!PgbE@@B9HHG?j
C?Q3DB3BXT/X9f-$#j3dBlLn,HA!H#(q!@3]['-1-j!9(!MT#DZ6,[-h$f=X2It?X6bQ41ZD&kg:(`
I(@Wj_o@MGJo2nL:/H%s%AbbD).]D;nIA"n*T]U]%U[0$7%-b-'<uSRVT#FsN$hSna=l`$*OU=IBdn
,]e-.\F%R\>$kbtIga)JcTj%jPZRV7f$NuOYcmgi`_0\ZR5%'Q?']]Q5nq$#:sfkG=kPe>5eJ)p-Za
<S`cbm^!O\;%nH6Pac:Pjt`[O@cgK7/57"Du7!K?erBZKUfD!]t*l(Nei;J6biTXV<>RqG6n7O_0u8
TYO7P/R'&KK(`E[hf]D4S3B9Q2W=f@e!-uu5MhngZ.)5H;\Mr=u9+QO&B[hN3?&Qm_n$IV'"e3o`0'
/eaI.6pKGN0&Zi,Sc]5T[<j/U4&MrS[@Q,/PSUG?6XNYQe[bmV^`55eiAIpph;,/;+]T*2]J.O=]u%
94WE:-c[./V6ue9e@,MRLSVrq^ZiZC_kp-K%f]h3,_%?6N<=^Vp)Y'/VEhVrijhne#?kY1!/RDV_%J
M2CUJ-8:+RPP5YdB'2$]FW7kRIk`DS0=-gdM;(NH1I6"I.HTiYJS0CSisLN(Ok2M4;$7ZG;?:/nqGe
inX?j)QqS;r`JO![,?[$lL"P)CYO1P(sHrF<>sR,E>lCiF:0;?%@320^,?n(a0N6mJ^5j"_VQNE8^j
,qg'bRk1RY9.%%b\HHBRG2L>"W_hZDD!/OofEH-DVH/VE]CYsMo3>P3!4q@6Qe,9"P[p]iO^Y`DnJa
ZpaLjo&9gLa+u5!MlGKPlOK#8Vi]bmGJ;(F#AHTtKWEbQU&Xe]iu1Uou\TAk"V_#I`;/;gh+oZ#V?D
C$=<J.G=2[Ol<a]]O'"&B9`'XZ57<di/jp(JY8rC1=HFp;"Y=(C,%qN\;J0"oYXYF>gfJ-B3HN1`nh
N'\K\1gX0(K*GXo0b*oi(%CepYVOYOloOe-UQl,80Toahg&l`cgV><UFC*MY-UESV`HP=#R@Tkl)pZ
O[9(Q;J5g&Z0N6;@FjYAOL8E<!pKZjaZ`0L<"XCW)jZpQ^>;#4f3,U'#<)kYj/@)riQbb=_VmY6+a\
,TMX3Y?RtuG6,Ik8'*%UoLON`!B"W*!q"qgI_)<^"43fEBGlM_QV_^SG,HOJ\YIf,R2$`jW.$()n%b
U*:^Q`K1*jHprWGKW/!Fppf?r;UCL4!BlJliG^)qE7(l=aq4$+2%[\X:R$(m0FDQ%!9l!ZX%AF,7Mh
):1gc^--fN+'lQon%M+jC`4!U&jLbgb.#*)q6Hh1$lNb>l3"-5GC3iU?iIV;[*["D@"G5VHVEXSN>[
q2d+TW,<0Q?5+!)E&SfT!&1U.Z93\3!2F%"3<)Z/(2Dh<E2c?jf4&k&EVJf>*>5Q56MPf_UgQ.#(6^
d]=<2KdgqQ:*ob8Utu/\h5RKLmsX*eUp%/goH3Zq`]cOfHRD&*KFp<Sp&`Q$a`W]5%\A#1Q%Us4),W
3WS?CLa\?YJ`otgKme,Z_**Iar<BiLILQR@WTZ)LcHnY[LIUc<g..mdr&B6\pM.\.u5rB&_Fj!&!oH
t(W:)3=0Whi.\N?EV:;Z)kb^Nf8=hrt"CpYL#0b]hq"LO0(i<Po]=1X!'+;Lf+sar@oR?+T0]#iq8:
(6b!u_FX`MX5[kV-(qfCO^lJ).BImaKl&#4;SX4$2/dZ`kAQb-Z@C:jn.ri&7ugS#=Y_n275>kc'1U
f)95]\eS:>QO<%r(KQ$!?m^_ql-cB&&bFBc6;j6/h<1CAV!NCG("pqg9Jf6g?1GdMK1)VUj[c]4t8#
m>0`5]f!T*'[jK^*l7`P.gmiWYIHZ+Z___O=pJ%^Y[_VitQ7*H@j?p;:-!Mhm],XS:6[cVeZ//g6XG
b]"JV=[UE]i$L6,q,Uak`o+B[?-NPR'\CbaCBZTSU0a$N]2'WnqBE/o1$l)RWBk[m%k)UZ!T@]S)m=
P6S_rr3J)LC,em,4H'H-Q72Ym[oC5a^qVr.B=S.+-`D.0u-*O8q^MTI+kNWXablJlJT8l?srsrJJ\S
7$GSj1\.uOe-.S742RJJLUU@%q/f#8F='ds:RgC#abhbI0JWUX0P;mGP%CfXoNZX4@HP'0n+^qDpi9
Fkf'lKO8)h2u!?6B*3?^Qp#[.ff?9usJ<Qc^WqRE2]6p\jkFHlo4<n?>#(!bnemWb)E%7:5,?>kM?q
;R99hHYA:(KR=aX@JpM-GD1+(M1Q\3#CZ(2^&LhP#ksOp5Ark[^L3GdeN9YgQl50VF2V6(`-G\f3\I
[+Cq]4B'c:#`3a\_`Iu:KT)i(;o#-1cIAW+%Gbj1<(NfWp;^g5:LeA0`iW!j>3[dsWT1i*0SMt2GJ4
Uc&M)bEd8:-+:/Q<>/k5Xc-)ddi8-_bh"**rCFs5qSNrPA50NZT(+JZ6tdjVq41U8$?X?JMY8K$kkH
jGC8EkL%'N"k2b#W+"$V%\/3'(>+=[<L&^]A!!B&Ou!WDVY7><hsg5mhE?+V'SB6ls0+%@Yc+AsRD3
V9e^$FWQSB^Hcco2I`'>O4>71.YqCdm*EJG*Ai^231Fi26I5$EGh]`r1lF4*:&o@t4@__"6l3&))4\
=sERn:W(r9`F*O>=XZD?+^G%$%iukE#;VsA#Jh*R5rJ<[PJ,uYF5prZ>W(+8'_F:W:[@MS@%3c$O@)
+,;%D!h[1dt3W9$4Q'A&X7ULcues@4b$d>.NW0kUahD"QG[m+SDlNm\M-Iau:W^9-$1>RY6c&O];gf
%i9jUnGGQK$8ii0Bbo]r^%'f`::cRIDs#n=pp>Q"hd@Nn;q\^V(gn'!J1,hQC-ENL^b-@JZIbPSWB]
9dt,@Kd7E!D$0N.NIm*reYPOY&C$0LF9DK9F8k:KN@[3Y?M-<Vl)efnn70d=)"7#0(=b1dct%RSA6e
n;KGk9:kcSu>NT*@%;l?YKYA'i/9rLEA/nfJ$!I3<;2]_qK6grVaZlt:X*WaZ6MeQ*[4SY[e-;>>Sh
=!"Ibl0]]=q1PeYke'inO"["bgOP-WppVB?9mDskXC^RY6,r'ZTbo8L4R^/94h<^qmmkfa6;GhLr!o
I2,aH^JEj,8BMto8qFUf`I)q9cPn&">5K`uA]IkP_C7qb7CUYq'!6[Tip`?V1HlL6aX\%Cr/Am?,.M
(&/PPZ7bPrK*T,pon1@<P03XHo*]-Cj"=\iggu0+<E+Egb,\3B('OC*FQkLndh-P]QUT>MKn8?+Et\
#Ua<iJ81GC;d>kt!MHmg,K%^b0PU7^5^RR=G`WXu$FcfnE^QFuDa=BfqtNY4<Mc;GXWC9*.%(Fto_J
oMB"u"<QMoj@gKZn/aJ4j:I50e!!:JtHQJ-4hP"ln0UTg]l`KqKdn$0i$BAIO_OQFY<=MIO'^AAG,m
Q47hb,8SSW>h.9'ZsrmF1D'NS<QVSpj`gi+'#>52Q1](27'WPJp#WG&r6<\M\g@fSVJ7DhKqO"e]nk
KkGZ]sR$afZ7Rr2C'Q3D?#UTq8l6h;OQ'Yh1p"8P(3-j(NhoP]"!<2D1YF%1WU`gP(;WB^brT?C(LQ
dp^*j<NY=aNh_4A``amXZJQ,E/h*_..5l5'PFQ>#`q%4gAd5[/`n'?iBW:43AJ!MAlu&%eRP_q;sd9
Dq/!COjVZM_`9j`,sHs*DYa@g7MP8W$KL*+4T2a+#POKP7E\Que#-g8pA&tn,g]/X"^kDO\tL*iT\]
/D"<<2bndB43o&ti.I.2GLJc2j4h_[iGFdnc&;_Mb!Pf!U*G"=m%!6Q)o26]h[,6NVhj?dVlVD=,K&
,Nc8;CXTUJ\33'4=7^e7\iY>N=(:>9iYrYfJTM/)LEtmpLrS:BW:G4]N7jX_#7"^]H3a(GT"Bn?FX;
%"/`P0njX-U_,cVt%*=88:V(T",UB#eQF[ikZP[4feQpO6Y6+%:?p19CnnE^E]Q]1LEE1WeL@i90TJ
1hF22t6rKTJDo(Xu!tQ)[Y*&4CIm.FcXo#WX,-%id![kQ.jpJ\H<TB1/fVs8<a,b8Umr*U+'Ii_R>$
%KC/=p]H;dn^XIKcIAL\@u*Up3*f@?cW*-+Plbt-'5FX/<\hV^mjD,Od<(9;i.*6"$ogWR#8L8@-k>
5A<f^f,9a8uH4Vk/pgmh4-KL*tt)!.C'#2$Qh6+`6uasfd]$WI:+!rOK0:t-c0!f9,caJ\ULQc)l&K
MO'@^ms'q5JA^X')"I82s1\(]OBd95F"aiqGGjK>Do6@%KSl;fBVp<[!=!_\].W/U)]Q##=)*8(0Cj
mdNm$4]SQJr9\Ons,H3]o.J`c_W-VCQ-&(EC!lJ@/nD%"$RaC8<Ko$=f/l(VHMMc]<lJ"8D=CQ?/N#
;lIHpSfp$CeN"gJQAOP9-Q!Bm71iepN_^`"Q*?Ci7Oo+$XH'<IGL3(YT%BE7:,:-hFAMRi0AgFos[U
W%+7U)P6Tu'C=-%g50RW@7"QE!Al"Xl8N9=&)b@B7T>D6eBRJH?VGPE/4*(&Vl"&<Ll[Hd:5T6eWN6
Pg.co'Sf5:ur!ZU[[:N+q`$-^j^8NcI%*ZMO4QX)XiOIL`%NOYuPE3PQ/%U$Y*eP[5@=T!*mF:r5=_
kTQ^GJ`B-*!g1S?UDUHj_(B14J)Oq?cf\e/A)4;GYLUq_qt?gY_Md'8s+(noCfd$^3KB=rEDr44*4F
sH:*+9de>Uk,2U7.jdpmSj2VZfTMm]\?Hm]]3eLcZQc"f^e%KrXKSL;JAi[p:,@H-p:F3k]N8XE]J,
&O-%t/orQ:Y2K^en"d%Zf:$=<W+Sp4n/u-VdXY$rWL_rnE$.LCQmD9;Ct$q$tet5`,7<!*/;uds-*C
a.PhMP;!phTP8Y(h:82Y-OY1C>8eGd:jiMGT"2)o&XbCQ,%0@(fDksTr]mCNr=9E=f=$fuF9%iq7G9
+bc5JqaJSj68l.NPSc\C%ifINq(+e2#EgULDH]WapGQ?1b^(pI7tHAFY`FmG)E07g^bWEW$8r%@@,j
t?R?C,aHWJ/%R!JY<"#+Q/YtAO@Xo\;E8!1O@0;M[=qu,(<uJ6jnM@bIS_+nsNDJo`Iu3Y3:)E]`N[
,#'?lA%1_09k9VKN<af%-hrLfbi90*)KK@Mo$AXJLZ\GB_ru1h/*sda;c]C$_A9;,^)X>.%dh)+5re
+42+NFaR=fK*k.?ahC^umH$Mkhup)PDjq(#J'B3E`PNZDt]<3._5&HEiuj9Y-+-;ZV-]<<9*&'F7<Y
i](F;G/WO"PBqE`b9q[7F?H7L;+oBb9.c]7EFkV6DDHmAkt>dcNimPb/U&PN$\q0iNEV;bp7t5:EL'
lTm"a&,4[:Kb@FYlP6U=P?.\huZ8GZ8s4BE?2Vpu)\JtH9f\CbB%^Mr9dlfP=bl_*(o5rMLk!^QuGp
c(F4U8)@1;N.47<k!3Uro:&M9eB40dO4tVJV]6rbGA%M!%squL.s&b/:s?,6ZH4DYa.SC#t96ZUB,h
<%1+9/0N1jA/9"^H&!/L+,ISZW3=1mM5I!iZRrF`'T?rZ,[AV6mG]_M6rA9$`."k\GnDr<YKn8gd0C
>DC#"[`Jk&KE:Oa[a/'!E&QGngtC!sd#RF3lQj]KU-C>]8I78f/(XWi^&RDsP8g\,LM0+$(i2k,_H;
ehueu^A%"Fn-04U9$\(/&V;N\UU&'FZ#$.(*&H^H@kp:2GXq::fiK\W_%N7H#hfTQ0*(m_%h@SsOhQ
sF'[940*5EJ/Sk_c-f:l\=mg<Bf.3Wa.e^&-XbY4HZ5#YegXb=Lk&5F07@4DD2ejG4HYeu$u<)VL:e
hVa==g2KOX?mWT#/:]S(Z;B=:hSa;.UGVHUQPoG8\d#Cr(ou,*\&WZ@=/XJ+;.9T:1:r1;=AVh:BRM
.gpeO&P;).aNtCmZNOSX*ZrWAEg#?uV"hTl]g0/M2AQE)$K-P/!6;XCb&u,mX2&5ca"@<^:E#cJZo2
>c'>J0mfhBRg!$jLr+.@B]\6LiV\GfgRc^GCsoXn5bD)MJfcdtManET23hDb&@BYE2J/reb.urt1i0
oja2RNQp_[R3NgO_:>&@Uo-"6(geCF';\_iF28Cs3DO9k"%RFtRD<XDEHDQV3`m][OBh[>-ed-pEW)
X#`k3_B:Unm#:MX-scR8eCj=FSCej(;fNO^943V:.,s5MAr;?HrXd!;=0hMGVXhk=FSN`tJM,[?2:3
2P*bF.%CcgpU_]DO0>D3R3gQ!m7,GSOp8'\4r)]<'(hmnQ7bZgOu1H:.&N3FbW>r;;^H/pCYI/CJ1'
t3pjYA\.P^"c@nd#DV<lqbDqTS,s?F\YX.q<J;D3>VP7Veb>Y0BSJ53B*sS2IPR;hA[KM-?g'Itc?r
91nE^N.77)0r%CeA[AY!(gTqihI[4D[h,8Rm"Y8(+0)>dE;'f]dRg$Ogck]58UmSR^/4*kU#+89MOQ
$3A,2bNE[9AD`NArj(mu2`\R,F5f]=iRSD1W-CpnTu5XR*Pe20.Pf*F@(<]d*mA3b4E$U(HXA\\(Mq
Qd2KTo8O:AHcNdkOYYRFhq?DU@_*6TJ_KSBNP+A5I&%ro$%``6j8%I^$W+o!YQAt(]NGkeH]YUJ$TY
4S#N]Cd[]>(Z3\rV]Q2*,oiKY[l$+jQ6&[YrL./GO7DCY%9k7jTf>s]?"EW3Y%JpNQ#ChDH5&CrSft
5K'-q55TfH!L4!.@Y?j3m;hH4DNG,P6g3h$ST:`at7nKh3H8B7QTBYSHGe)$+jii7r*55EWh^6D8#'
>N)WbV9Qp\b2]7KmE=ndb6`dq>Zpb:P^\-m^_\@r=Y-lFaa@VkHu5/.B$&\)+Zj0`)@<;$Ou7LOYtQ
$9H4n=5T$;4q_bWifauV<&2RTq?3HF,6a*mhK$sML(`I/J3BUbeY!G:$P,cf*&,>"mjB?%a6j#A$'B
qq34QKBb"OJp'b&2]lMU@bQ?+`s8EM%5>uXcng%=aM:T=K07J)fRe3<P$[_ts*]9QVfFXsFHpnUmUi
9@QMXAmTRZ+eJ-`A$Xg<O,^jThf-2#TeQOK(EOr+GiT^Y#f_<r8`blK>7E]c?#/e6Q^Lpc`I-:h01G
-jMdirasgJEon$?tWgt+cCetZtUt,KUZGe8b#U8r;'GnA@i<X&1lI2?^0RXm'"tUni_cAh#g!$<D2j
B0Xq(9BNC):IkJ/]*?K03.q#sVCCTV,+dkbo&WRt<ldoZgbK.WH1#WBsE`rN&a4"SH`@-YI[Y76*A?
?CZo$q\TI=Y*eRMffs:Eb"HDjbs1'5oChn4[^=@3m)I]6*=+r635aRd`[K$"P9Z]e*ITEV.M,RqT*j
l56VqYV=f?OjTn62tCg($)]`4W,8N]2)eCc+a@k*E-4gK/NP'A+J^eU4'5s<"\+K/"0\T;r[]TRe-:
I"d@^@2*;=l3bJO.H!kJ&RDi\M0M9;Sb@SEhj+l5o('G4!bq&bu4r8MQnnqYa%Mg!`Nl_>rr9XlR+j
Z^h+UQR@%tHBC`#^_U[Y]->Y=:VF6US4roQ"YTYY'kjFS.<"8Ao]qMC5X8cb@LP[^f_KYE#T[2l=KA
C-jVn(gXM41=gJ"hM.Ol'XjO.Msd3@uF))dXUM4AY-uS63D*#'^8TOL"p5JUZ<3+[8`CbX<:tG'&<%
q9I_27UhQlTT1pe`PQooaC"U9E+4=9Eq(_'*$7YrVTl"N7dB$7@D'ZF])#ph[4'o%NaMVA@[LEs9%/
s=?/e7kR';<Gcm$hU)`A[ArQJ<r9=m3'i:r-9gmUTlL'/+)aUO7@W2lq9;O^ki'F1#BNse"o9HWF>$
o;SuO;+Jf!2.M`9S,_D2la(O(2OkeacKMumlkL&GW"\8`Zk8BdV1;s<T(AbIs6Dsdq_fP!sc!PH0s&
;A7S+tfL#H4fB@0-euY9"%t&:A/7%Y?(>rJCEP+FPqC86OnLY4W6GB4\I../UpdaY2m6=\mZ75%^-s
lL(G_4F7F&Q^ucoGYG7@Gc2k;?56M55ojP*FWf]-dWEf+Dt[F53=(NgWBIi=p4Z]u-=X34>cmId]@"
E#:&g)[r\Mpk]fE5Q(3_*30dTUJLW'"]!QX`*!gbEmrG3(kAL_&[kD!:cL!)_TG7&Q3ts`8k&tV+8N
5QZff2ScHt,N.!VE6VIb8.\R2.^@FbE?9Up-t&#t4TKaVVs?F#1RfqWLPjem\s<=$`C\=bN?_4QZlI
]DU2@=a#!H)a3XE2VAY9_t.IiU2QFW0hOBrNQ)0%boJh4kK)hr5.$nKu^fh45@opom9tFHjo!rm,j:
QiQof.g7;gDAfVFHW%;&0+GHQ4"dPojmNI8hkpfYO@gM+2I\lZ9*-'9*jWq9@iqR/d\%A6EAEqmZ9A
O$H\E(*1h=,r2S6lR*KcMZ@>_/R%()Wc70>+g`]+9"R0&Vta8cS<&.5Ri.YU2s6Yu@R$Spt`-1J]]j
@!+iQ#_SP,J>BsZM5hXq8`O:@_ln=%L`eL:reP7^=X2ST_q?jP\e+au)O[1eCh,0Gf"a:7V*5I:.2-
Fb_SNL!+0Id!oQ+4rX\0<RdPjGLBur):\T]bp9!'d[%=m>*N(@;02jZ]TrCjbTB4EhC.RPP<f;RQ<\
h@0Yi-\q%[RdA.nNk5.93>Nbie@q@gS8gGY.\F.5fF:eV$-6fgQaQ#Zq%LrKF($9#>+S,E%d1\\$iL
h"N.[T[,KOopYq+#f;*5@/fB<%GCsr<2%.K7*<[pe_Y%]4<WGnjr+'0^hd4rdc'rlti';9rI2gaT13
UW`J*tCb@&HhW:f-UJT:iC]'r!t?EFUdl>1*qOkrCog"<Ve#8k8:7HXtA=@6*!aS5o\W;$m_75Ost'
(BX]?:r@-nBCMYcc4uM&+gUqX0g$r/Cd7kiHu-<57iAk[L:$1_n\=toXo6APfu(,5dbD[$SCV>j12Z
T$ImsX*kPUM]]:bhZM5N8,&0*G[qQ_eA6U'f(-7?0$=1+^?CR?*o2)D+];_cl_2RX-Z&P@V8T<.n6m
m!nTCsjg@e%Wm)3NV2[%ph2>8N_^C)8PlY,Q@8340D^Hbtp;XXtm]_FZk#q$C@:$+e'ls#<jgepA\[
aU-lg1a_^YB#nYK0-,q^mp%egj7%`!g>6@n>MPMmfJciB07ZYfQ%6UHEZRWo.*o4[#B)f>TL8bdHb\
DnLbBWk0(@Y"T!&t0:O8*2o<+Oet('qtp"Ue49q<<s;534*lH.725?fF"IV?=0Vk&P'5(6(DaGLlK-
+dMHR_D's,,0gMENt,UMH,=t%;:]S/m3g>`S?GM1$eSLRWK:3P<Tm&#\>;AenqJ9a9,!fNb=^R-4%'
Ml*\3j:T/sl;qhEbSNZVGi2*Sm6J6mp(Jle@EKfTp]"KZ(&Uep`/Re@iEJ)mlgD;2]Uf9"0/bIQf=k
i#ZZ)(r^#j=Z6o5o%I#nHBV36Ei=fimu[%De@l-6G_'V4"P3ueJPS2A`nT8N3kRo)hX9UQ8W7Rk_@2
=>Qa7sCNVZT;rQ)3#r,<@a9SN)!n=TM4eSFULr%F0e2V!5q?##u3!mW`43UaCgrbO^GO:?N%bLmS$i
5Ff!ld8@@O,SOlDg'MT\4Y^<->F'.c-:$ngM%T>Y!Hq.\>:FEX7'qH.AW^o!$e!YA?*FD,E_:Ptdd_
UYc/M[`&Wp4L'2gS/QgH:n<\/EOm&+(gL>u1Wfe(rQQG8_MMbGA/VoFl=lSl2F37o&$TlC_pQiX6)o
AeAe0skg#odETa'PP)ghrfKMbH6#d[]hA]=rsf>j$bp'"sjhae*iTi3ZX38*`/0^%I^91pY`/aT-12
'/#.5NCd5dBsB`S#)#+&n8SPj)jl"1`r/:_>XYSoQ[AAkjVQT`KZpY&f2X(fY@pb6A<CdV8Wm==!'p
Ra\tQ*fAKf[_8K2=5e0uH\p$W1-n$H@m51"-Rg(5^r10aWfihD+X3)?N$?*L(KMmTAO8?J@YG\u.G.
P%E!^.3fK/%Z9H?"r`JT8hsBFrTBrS307[[r9nIXLh/TBn3h9J>`Y\FYo6^OF>$iPA+2HH/9FNR(hh
MaH<f\1c<%Qt>9q@E&o,:EIGESY(NU%*og=BkahsFYhB'6p&.J`>M-F$`>lJq[Xu@^DMf2>)L]Gi1+
i>3XGo2YZRD/*At,lNM"?!rPqKYMGjAQ,jG$tWY>_Ra4FZ0";RH+T$FKkTZd]>)'Gk=9lQ:H'ElA\a
dlITB'bBQF#Q$gQ*l=hPUQU_'a-h-%r-q.gRDd/2pC.#\XA<UP@U]UT`c&;,5$\<.fUf1#QgKN[<o)
-FH12R#jPA3-ip"'Td8MGj&/K=c]3)I6,guQKqPG3Or-uOS'YII$8jr>(I%faWCJ$$FE_`;gZ8D4EQ
YpSP0F/U;1&eXhg,608P*F!cEb33rbLKn!'gNU6pXeUYUJ-Q]5(Mk1!p"G`kFFD&-P!rPEW4ZMdTGX
4eXXie-sHT5:?3Q,\L7j:Tg5=8QGL;'AsFf#/md:IA<F*LsK&Igkomi%OQHa!osqKoc`Q+0fli]V+!
?2osaX3i1,&i%I0#T=Y*]4rh`]%Jplot0,66-H19D+iS4DAl"#7]^m'NHrqnR[1T$-gTFoh"TI(/FP
5!BUBh/SKc\N[U4ic@23?/fZn44Eh(&Af0jUtmC;+VcP@==]jT::aA$s>B6F9!D-D`a4k?!#dDSXnm
r^:YuZ+TD-(f629[2)%C=jV:^s>VSZC:gYA"G$1fDec+&4BhnGdcTf0mgt7Q9#'Y<>77AG$UujEh1E
PRaI?&%Z%nZQM$+@``$(`tnBQ3n@G__Uhs1mDHC]V=-loU;#)tF'$Sj$H'<lKS;GfRau)"]Kjn_ol[
B)[;H]a&pia*$UZ'tlQ#&-P7K,hSU),)Sf?U+".K?'[%`Q=X3B>[r9*bDYtT02??(G22JO33KP4X7t
K'HZ(#,'#"#Lln8#1cWohmft0lgP\?Q^7@,,NpYNGZc^[":W]m"pOsXjAZjYchqYA,$U#hTJH0fbb%
&VtD@VP,t[^90D&'KaggqnQ]*kcL-&h6dYpG,V[!Fm,ma!p2AYBK94I"1_o\mQZ_N=V`#3A2U.5A)u
g#*`VJ<=\&8$V,X'.lV+,\CcmnTR91(4$!SYU(fA;Nd.Lq;J''U5%.F\i_01+H2e"Ug@R0&+9Ap]s5
(rN?SUjKf[a.)`pAV:^-\t7CmQu;"Z(4#*l39LCuZm^Z&9B0@%E;="eBZ\.Ma]G@eK97\KGhVlT;rG
(*pf]jlIiN:\]/UYpHJPj#P#R:M%JgkBt@>eOPQ"oiX9;k9"7pY7X%+ZbthloHIOq@3V4-K*s_09Ib
A:QsQ@4iu]F.\^W4S20`n!Phuff,]f%T$45ujD657i350WaFn)I!UqT-.6BE*j8s:0UPWZ>G7GEma5
_?ROj2E=C*A4:j;2S=$66edU#KCQTQA/uFO'YiJRG6[Hb*(_I8_10(Fs=p*>]Ip.R?oo3:)=sFiVi<
NjFQU'6&<A]25A\8+K>4ZVbd<M7p*j\K%XN09$W^f/o&^+rPMDoZ_tIK3?3=e^bJBTrgMONZjC^uD*
/^92d?CmS3ZG,4V8S4O"%'kj$Lba8/+r`HJ,KE&s6566q?A%VoFJU3Pj:!&PB,B9/JdqLBP#pHtP*b
8+D3R^G.k36fUo0)AX7#gq71H`d.EuM51gEU1VWj6-!b[^uL(q+1Q!*D+t9+</^]0*!SA50Z65YmXT
sfJZT@`J;Brf5`m4>fcue9SbgPd.BW!s[jLlF.A(&5Ngs5G<F/XlJUAB2H0Wol-3MfT0n;c9."<6e@
)9PSg>VcbT)u6Z7*[:,-%7aq5/E,`'EA4W(&CPCbh@DHQa+q8YIo=_\2a*R>F&%&72#h[X[XHOkr<;
$YRpE=6D4Dj"G!+><:_+!,>o7=C:t&m4AE<jL`'$H/l=ml%X2(uH*c@+Vj\m.Qp1Ah</ISB#pYrDLZ
3n/,;Mo"kG)hAMR0Q$1EW2EEVN'6Z=1FMiA`^hSFaX<1&tT667m&/F@j;"HO=35K*u+X6I,Caebt](
]hPT\ZdD+,X)S\1B/sQ.<i'iqd-K,9HQh06m:\Tu7m,o^Wg.!O$R#P@];$A)!TTTR5<Q@pDn*%>c2>
d(EYd6O,G/,bn\KT:_$"7^3I2Vd!qsL)%;cr/.rI&HF&F>E"*fHQT+B2J2hk02T;.kc3kA-dWL&+CF
B`N6!H@:TDQ?$4&?&=K8[`%%ZP=,C3JA<r)3tfj,G@BCb*,^PE.Xi*Z#,!\LD)hRqun%^BT$1E*'c3
T3b\&:3AkD7K^lne2%GE4d!R>MeS]ZRJ+\]6#[1*Fo1"R54*l-*V6+<L?"ME__m>ElS9!aklqm/,43
$H(J_]pV4"!\SDJMpfm[4]1+P5EcjhR`"CF#l-=?\6a9NFp+GUIFZDhA&7*#Ms[lWM[&`@;r2Pdckc
U"L1BIlG^DmaS>PP1@jf>j&&3.GdAP@t"e`;;/)',n5euqYE8`*A76Z:Rg3dh`!<R^3F)VrV*/6S#a
$oU.R3W"?FIQhJgl[%aEpfq2lRVUT"Yj;f``o%&B%]"eMh@\8Z7tl5CNMh2)^L\SSg%Bd(khcW3HtF
56)h[.L)44#ShY/Jo`c+UXYn]LcL,BM`dY>ahuJqSf$lHq.`.HL\3^#sMX;VDT\QH42"JCH;jBr5nh
;=X\"_gMtZ?^1+cJbOks"%=m@Z0WNB0V/'Yh&2WY4/u=3ph1V16V]u'S=>)ZpIbE/4o#J26DCKA:]M
M,c+2RE</rZ\kfWr_lS%igpWOV_b8FsKG5JDPI"l:BH1)R&6rq%et^Hg^T33N.`8NIfn7;8p4V41!V
)!96Xm,Nd\Z*%Fo5;p"Erp1HiTQullGn.Mhkf_Ffn=mh+'@kq:]Ej`26KOd[XQ]M'^n:^i-86Vu@Pb
XfVb"U'kD'O'(ZtL6Hm3SAU"7+s6uP?!=CK%,^#VOg&'[2C7P#n-&-o]W6[r5l#?2K])heCi`!!,AM
Or(UY-.#&mH>:_"U87#V-a1aUGXndm<J.13P\b24Ss!WR2-3c"MJR)021?!_JGNj^(ARr`jsuChc]L
+q^6b>g!Y&.W1;-FguW8-!P6P#>sor)5s]:BQ6Rr;nJnH3M`Y0U!I?87EZ,*b^-LRBK_LqbKFEHpih
P\]YmTN8m]Q?F;nKr0-YJ]kmp7`/+Mgt?6uG#fK6s^Wkbp's+c6Bbfp8Y7A7cC<(RWq8c]L><aB2o;
1=(4Rr")A.GgICpUoWhX;6A*h:Q#Nh5d8fn(P>.oc44dpk8FuaN-Pih!J*jG78mCu*Zk9M4n,_-Y:$
&bK[9<O>)4V6h]V7f%\K9hPrfaap`/+2-7.,-W;dC:K:J^nO'W4U.2MEifedA&G(i2u+@/<j)A/oZ;
kmtO:sniU34s.\W86\Z),BI3c`KE;:iU=>OW?k*`tE\[4]0U5QeOiY;Ne7,rO/!pa56aXh>'q(0b-.
.\-<8^CUFO;]4`Ig4I(X)p3S"%a*@PulTFKK4Gb*u\*>2XGL*ZCg]-WiW34PXcGZ^-;0XV6.4G-q,U
g/oW?MTLl5LLM<G^YFJ+NQthu,`.<]hr/g]I_hh^Se8X;@Iop[,/1iM?WCZlh#_G,'?)4s"OD?"+&U
1]_6X0f=T%_bqTXdB@<N_;<cZi&WUF*&cj:gf]i(:#llZC#fMhm9A?BM"M7.R29RR-1OErQtU'V_M:
RJ$1a-;%c)d(i(o#X3Z3m6+i1)6GS@,tppL2aJ1pGDT+H(e9hX,%bt9@T+N,Vpa,t"e&'[!TMX)?&7
\u91[+Rc>WA"UqOp2iB;?b"SeA<cmPeiO!EZ5f2ZZJe/JKm#Rh`ASd[g`dm@?E7O3\`<75@a]*I&q&
,7N)FC`X#Vdf'O2tH0I@Uo&H@WIB'rB4W3r/0p3UWoG->D8@(m)XZc%q'*X]?N#orin4eulK>X9&r9
-k&jqeeF>+/k8AL-J;R7*)OZABl6<'Ym_H,(piYk@Zu@\S>^^sLSfe+<FF'2J`.-d.qeBkS&__%Am2
U.A=tcn.Z[jLCurZ;g"r'hq7I6@iH#0SraAl8iHf<=Zk]&dg!1CJ6Ct9]KF:<-\jFC-uQ`[0^/LM=&
u;qPNQoL$PG$+-)OmfM>SX_YVmIKP>HgS[<5Rn+Yk,)?/np<SP.S+(rVQW!16oGRt^rRQ1D*^A^FRm
F%SFT,D6!4b;Q"pkf`N;c=`H.UdrB?-&aA_1s!Mi5fCiWrjG<^]>1=c+;tdbf<N/U[!LJ$e)#+/(Lc
:@eR4!(8,]MO-ne.o1bu\NdkHiM7!^r*Y[ih6mYom/ZQLFO@2_D.n30a)%]pGbbO$Q#TmF;8!qL1,(
rUL27phHTgDJXiG]Gtg'mrc7Hdj6-f@=>FjRtb-gMB96OD*m!jYQQbeP+_H'=mD,+lA!70fQq^)`;F
E/XlI`$aOs.0#*pbV&N1rD+u*233_YiB?,-5]^u9"<[aAq(_YX-?X(92(2?)=ig%sAs/#ZC59mk\Dm
()'"Y]\)lom,5!J;bmZOln.:"O#n486@8q_Mr#;7I!EPK7M(,:1Nb+MIc/jN#q`2iT&5,e]\V/S%e"
36u^.T4^)"cXGn?e4.<?gCG,!Oe+fEC$R=:T"0f6?gn;25=kA@8GY28]d\j(33B3'S#e9;/cIg3([k
bH1q'ohu:*YedgU,@.A[>:;,iNY4rQS6Ya;J0%MRN_]O;S-_BToF0=TJ#bdtOO<n76eVYJmK#2b5+p
K_8'5\8coI1ceO?Y&iHq@-u6rXBF6)TWT*m\!F6kRk:C8;Fb_[QUTkdVYkA>=nlWZ+n-&9].(3h)Ub
ckE6LUBG0A]hGNIn%*"SGkpNM66G/qAYd=IolW62+gb'M7k]L)ZPDe[5`,j9%NR)(VL_gYY]aFS4`T
>Le=3"d^&.,6*JL3toEGGWC<C4.cOd^j/eUoRM8pkXKibL`Sf^oo4?RZDA.q($h.@HEe>obp(6_nf]
-\h2GO7^R:]mi-racl'(D6":(nlm=5JdX7?,5GGdJ&F:G9XmL^nR),$S@MC#fr!311``*jCC^QB/r(
"`&=?$4e*(kUGR7&oR(?6'>5p"BGht`W0#,2(I3dhdfg,W7"kJQ]]kBr6,af[,C`!.A/eFm5UktO#:
lmg$q+jE!-iJ2K5,5HKP:k/4]0ddmg=-^V1*T&4E'%ugX>[nJ2UWKRB*gK)BTE:maC@Qm)WeI&!Pr<
o?M^'[r+8B'dYc3*(O6D-Vc?^#0LgNq\aTq'CdG9@mG5^kij.q$m:H?7OSYtdU;We@)R4nT2;q9mDN
ZgSIm'S5]m(oeT]k3_).RT9nD*Z/E)?L(?6B60?6uBH/2@FnuVOC34_Dc@ARpHa-qedHhcPG@ejtAE
I`p[7XrT"jq%b(3kc81rK@VP-8#D'ZQKu'!CSCF`9TcBJ,gmA:T9@D![2*iW6tg*E"\BK`5tqP*+[u
3Z=PC0`tqEESNS?Mi[V9HfAL;L[.Qb;f$q,#p)<JH^iuQh?>`LfRN)tO%:GKI0dM?4pVkLJLi$Na0V
$H.lp;j\'ml)+.NP<TH"&m8F<,TnFsM%07,N+=7D:AhpnJ#udT[ZfPoVD)4#!Mr<-i=cbi#.(N4u\1
```i0']g^_ho^'8mK.TX\nfA]aYn/+"McLO@$F>r4;%(I7]D-bS[=7r*',ZbnSG/oAbZ'%o:RS3buP
p)Ir8H\_&3XZq.gsifn;kImPM$(.7T+n.@Q5r*)C!u?/==$UUg6^pO:K]rqcu.P@dL@##/HNWV#Xg]
i^nf5IHEZ334EMN/LLnVbadf=#M;r1sm-g&qo#ehTPJMRXi\O`0daK^Do$Lgkm!=pmC:0-'Q?H1Eqh
mUl9-'896Y/Nql@?MIhRi:V=^1`&gJ<UF&')*r3XDoB/oX@/OZ/h>>2r8"sLg%-TB0!6s>@f*^U/-8
%)]9dBabLWYdpZ<>Mt:(Mmd-,JMARK<=C2KjgZd_Ir!DUo155OEVS8kZL!3Ej!)['C]Qf=!88)FFG?
*S@l1pA=<N[,tG:oB+:F9jp/WnqST9ihP?In@ZE`YC1]F3%Ql=g0;/c^rpC]g?k(31SAgn.SRWU4V8
a*D=m%s\f^k2NW8r9f8ZQa`>/hC$1ebCj!t8_\/ttu%1IHlHNu)6#FJcGnZjJfI/s;SiDkj.KFJ7&4
m[]mj(X8SbK>c/LXjn]6!3G__M='_\uqmYEt"YD=WOC&BUK85<+:jMX@cT/8H'qgo:p\bks?8/N&L>
RJ3?$Vih\4Q2'.7=QJLA5_`.r\F^aBIp20G[D8)f*;fSm*-[qS;cMe.hlZ^,$eg;.g&.ecPm_"K:6T
PlBeh!AXp\#&KJr""QUdWL7->uYLBX"^,BfX]7Zt\2AGDC[*3\=H/pKC.;<0cXkSRPa(pp^1I?Z"p2
D8CQuL\Ai,[k=3oY;X$&iD1:%iF$h4_lY*5_BfL3NcZr_s4huGjYV0k,&'4a_-Y6XbKig+>*Am_:S#
MC0`'UkQIA/3`RLVU9C9gEn3I:T+YGZfnmkV0!S$(b_rA_eo1dgiL67%)`34[&jm^YYGU;uRpm1IiM
q+1p.qdX]ccV&G`DR;WJGS4LF[Xou8.M@0BJC@['ZC^I2hb^k><4qARSED)?866THMufFIIne4"IM*
""I7@M5,Jm%-K-=OBRn)IVt%YmMbmY'6")VWF&VcT>L`.];J0c:q;H$8p(s;\RF+nQhq&Bc;,qHTN3
e+!Q(eTM(q%ni\onk#:Lq!@'aYe4_%^+BC&m,uR2@28jaf6XSk?h0K@27;o%d:5.7-_m&4sNSiOO<f
@=,;urVk#=?dU`kUd?sS],r[+7WJ'(HH:$XD"'=Lop3#[Crf>NpuS]?rl_c]anSB(gj8S!LH[Rri^N
Zu[U["1TCAQ5&WD&j(a9C2lYdj)/1pIn/s[-_;(UQ#qh?H'Nn>"B*bA=U$5b:KXW]hb&MM17pCmOYa
:K@R-,:!+WCTW?cBc<f27#e3e9<'0P$&&qo[N8_&"A;fIc-Xl4aO1N1kIR<,'$&AEP]::ZV#9iH\_U
f3,+b[kY<93B'9AC)].Glp!Xq[6-H_[[+89PF'3p6`l>U\-PP`I,JGa:L>G8i6g(4]J0%^`f!-4=9+
Bk"]fo(bf<1N5q!AZ3=>3^dD=a'W2rAkZ3<Du?^$#&INX3/lD<^9k?iS:!0LJ4n&%R;qmHG\O&Nk&<
\`-G@BOZN-(<d(Z9<>:Gq9DXjroWV.>:-a7GI*bX?_YM^2TMpJh0*u9>MKP#(<;amo)<%9ItABc>pi
E*!,2Xl0kp]$0SZo+,7r'ma0&\_+WO_&*'u?_=Zo\"+&We/#as;ph/<@ZPV4D%5:Rlk=dqm-ps"?kZ
Q;-ECQQMa]lSDZe'IHoo8[At<E/S-E>#@b`eI7.3V7RX-W2CHfu.<DgaYEj[[-=9<=,.a&LQ^,?;;t
.Ki$nYPd9R76+=8q!<s2_n60"A+PnNpjSh[n?Jh![1pe7>WGtnK7I(auI":0HI^GON$8^XgU!I7mJM
oXjiW8t^d9mGnk&\Na[g/B\bpW!WGkks[o1bl:h^2#ac5+7-J?d>B"N%Wf5+Q)47/N.O\,`\_AtXi&
3?2&ti<0Pd0\PqpXL2N=,fD'O_c1Q"LH4'is1]qK(6/p\nf^o<'.4a%h),/<&$:Hl5nITY:j;<06k#
_D0MkRJG&/<;0.qME_0&Bt(71J.fHjmPjj8phlp#Oq,KLH&@q0&J']:f):iWbKElEu!DHel+HHoXA5
PfGP7K@:K:(dCXg0cZZ04eosjI_l?6Xmta0(iF>:a&5<H:S\dhX5G/?RK]3NJo.VF;:<+;0$^WeB6f
S9i[$5h(C@t!;U.bRa;JZ2+<)O5_"CL0nS;Tmm7ZE)9W,O6_Ph>HtN9]/uVUS:0KtVhXY$eB:gg?nQ
g4U>M:MG:m:VYG8K)]Q]#,;Pa:r;h.TTPk&e-#UL$B.M@;[6Js$[PTluL+*0"L$\,#:OO8RHkHb+Pn
4i;PHD4L=Qca]1a@;$fYq9*&W,(B!9YHrY]kod+@kH<o"]R18nVS;?K4p[YZG7bNGOd6md;aMg)B#'
-knVElU`\3OP:!CY<FqF^YE["hqOHa8U^n<oK)lVeEScbPin)r")Yo2aI)#iPoHa[iW'qZ$h&8YZ@h
26:0H/!A05FKhESmYbgpG=lfhI##TI`9#$0QLJh9$MO_n'l1/lrMb-3-?Z&nEdN[,f`YbON@b?fEER
sE(27hK0+b6#eQ\],SDLF@$h<T:@GlY!IphGXI6s#,=h'kHXZs=1G/5/V2_N7c@p+!%c7o85:f),Rg
R9+&dMPC4'gFD?G6+X`J12c(Vb>6PGD>;`sWsG.:N*%:m?H;E(u*ZPn5*P9E3p(ln\F<!ru/[Or?t=
TF4'oL%ZYM%f/R)Tsf;(Y`.59;C`"/ph]-=$M[TA%a@nmc_,,W2`ogV"253E&i/Z\#X*h1",tUr"_*
d38H=5/<*<?b&<]5%W!3XC^])C+Oo;Xi8dW*52W42m,7Hg]:r)s[>I+hKqei,=kVu8<s5M+YX(J9nr
7uYQ1,rI!n[_d%.dcXE_QW#'L%-_9Z;]"]jk<&W(GUisMR.DfdV('$cd?71fS3Ob3[3_&]@Ktp(h#7
>Spb$3.e:/R4R8P8>.gMImFk_'BN.cL>QX^djt4hSO2E;]bT#7I([FOEN)VbFK*K$ur<o@8;N>25+#
E]Ogb'u9K>E:Ke9RnV)nRdpY^F<-N,stIop.`0Dnl=i2aIAD#RF1VKV$"Yjisi,9`+H0f48J?K@Bh[
^Y[k\\]c`2<!1!H&qe;/ZZ89Ys6A.8Am,]/QE&26[^e?S4oY?eqiL.<oa^!+9<ls!r.cPJ9&Q),Srp
6n8]b8I0:b0PrrScLbVoC`''=3#:KN6NZJRlC>M$0/7t4Mr:5#?>Or-E-C.cp]'#AZ@osf7%gPtF7!
E)UAU/D+8juZ>N_1Q*+^^[R[0GSnPN9D6Sb<lX-NoKG)b4CQ[H&%n7SqPt'q#9-o`p33iVS)3bgq(u
!*DOq6!u0sA\@jLBE5=h=CT&MP%ZLe_Mg!UG3qc@05+1Ma??AOK$Y:dB==R?>VVI4%/HZIBQ+SJs!1
kch@!#\6B6f+d%.Bh.7?u5sa&3r(9oZ/JMfgC@n]+G1N=J&6V-ndhT(l#7[)=@fWM'*YSsJN]?i@A%
m<<gf1F]Bop=jVjg?=F%)U44@F)h-2^7u[C*#Naul:YaPU]:,Uo*:5a6mf<lMrS-nn0O0W2pN1)1hG
nYKH1;3L<;8sR#U*F4^</Jq)nQjSP@=e/-qIHJCV_$diu$WF"DDf%:PS9!"N7a!`90RY+DIK!&`!X4
M"Os7Ne2j(]4YPG1-nY:%h3Cq[)&3Q"bUJ0uWRUqhb9V?4+>TFPEqJq/)PaM8eWb@&''@dj/`Y^iok
VQ6Ba\(e6s\"%HeRP%hit`=8n411XhM6*Cj?lof_eUs.^\[[lFc",e,!07WuDl/SB&iP/cL4fEr9+R
$N![\\,SmJl_"bmB5-O,MMARcdoD*1oGSs43[+BWVY6_Fm3kN@;"n"h$*`^b-cULUr'14^H`uYZ'.Y
"'QsPCeh!JGo$DHLO;FT]/mp5N=M.G"9\rn_:$3uOs/1@CBX#kL=E:C!YJ);-'q<E^r8'[*$H."Le]
`^#m_HDi4t_gE.7IBQ8BO:Am7s*TJ7,P'hWlPbp/2=6_@O<GP:*S9D=G:cW%AH/.(\F5uR!4.H3b=d
MFLeGpHaBp$hrJ<TmX@#kR3@5PW>Xhtt6ji+95.7TmeI!*s&l3d(ClZe'8mX8rSCH+r50Z&;dX;+f3
4-Lf$0;Q<o-jo]3]jM#iqZ!<&F?DApQGOHEm8sEbhgTS2'md->RR,c"LcSIulNZ>5A)@?r"_2dUpSX
c$16)H>Y1)).d%k.l*ZO)R"6]mj*]S/T9NlIqp<o/d+M*WpN7Lo_O6qT8-(^[!LQn9@?>f1a)BGb)1
;c>$@V^07AHK<JoG5U<U*W:E(GcM;cK`X>Pj=j9"I;[s,1MoO_!YJR-eo.8TpE-J'D$:FZ/7BCo``>
Hd1e_QaR9r^\%Sh>>\";BfX_dOEK)=uHI*J[ZiGq#njSuLLU#qZlS\+_J._nPl85Pf)SJX"*.*`/?G
'@aBUoBHK3+R[F<I:bg-Upk_Yfj3qIT@*2R/.q2as=n!_>=HoV0=oA1[Oa[id8;s"pZn%X4'*P5q?r
oPhoF_f7sbOs.:p9OJ'm<&sN\\1f+FPluab[rKF":A@i09*^rn%P6=lRVJ:bA#m"=#.Pec%,ctsH$H
@AhCMGu`S.Y=U6B$iB\jgOZnb,JN7ib=1a2I)m;G&Zg\'nEpW)B?><6F3WqCR-g%hCN^pA!VHo?WFF
-d%@8bEgHMg/k%J-cA(D9>MZbp>o?dm6=\TJn!8<WHm+_b7>Sm`@[RiA]X66rQ+?1#G"CI=c)XAnEj
Z#hX%S)>-Sm980N:#FP!I^D+2o,Q1l\pTa;Na(krJle3Hif^9]U]YXR3tFY+f!$$J4^Nmq100=h/`E
TN)BPcqRW][DDc_CbflXri<",'KO8j<3:.dd(J0RH)T%KLJ[..%6T=@CUuUW^!^$0aAl)de70delr`
;"Qdg"(/<'!:4c^req0J8eeS'A;XN+=1!>*`pY.oK_iZB]Q;-Y&O)11Fmi5teb3\GXr'UE-2dF+2AB
=Z:5COh,RKsRQX,P'Q[r*^Gr/Wo]\:=025!0cgLqkmFVM;jRR58pWSf;B4/_:O*%pPEsbUGGA+2I4c
]S^^#d(HfQ*o4W#bT)T#ZbrBCHjG%uDs06&XO]`)Z$4K`T"S`IBjd8Iq[O7JVG:ChlGEi2iiE<-Rt*
nmo$;L&&A_2_UPoJT!Z.%%3b(h]O'`JZbB)Di9?u.T*@hob*<aM(qb%BS=Ru#Z-jc'iQ95hq4at'C^
!.p-5'-h>3G.CCM:%*>eI&%;jYD!FJKUP>[\'2uJHA^0%6:^\M0VVMRtoa);[;<3psI)^BN3(h#g'F
PMODPuFgQ5^B\i)>PqX!H.5MmRA8*c_8]:0%rAa8\-VcPkp'`XWjq7ceE%\q*&b'0S:9[,UDkIV8mZ
@?c=*(^3Z+C?k4M`4+GW'$7iatsg<S>2k1(354+;BsGj'rLI,eNc?(3j61G2V&mqnTnG:m=6Zo_Uk!
"7Zf;Y"b+%P8Fbt]moUkM8o"5qlU[W9?(m&p'CjRrq5_<2q2uDM[[a+=AdW_#pD#_d=?m?]i?ql7,n
+(1V<(hIJEu;=G:+JnOrkRq:=<Tf6-F^kFj+AjPL7M&=h%Ekd\`[d2BIOZcR'+/83<=7l3E$=--i1q
AAW4(njc1autjuJ1OoY"if!Q'DVX+nNJ[0+8&*MLY3g?h]:J'1T@oC[B20mm`ab'nr2`-K\gUEhrht
t-[ML^fb)'(WgL%u63IW9BH)-LRo::sF.s0+\@Z3(D\Cl&L$U+`!IFkS#.:CC:88)8.<_RB6=YEBeb
,M.B=s)rgD=N"E`"gIp<Bl9Vb5bAdFCh4FsTrY'DNU0<+UTU)PH^0![O^bk<p?)p(q'sq@ET_dXtmN
?cnnl1V`MB`52R1hRnZJ(LKA1I:jkKdmQpEErFbumT[AKIl5qW3kf(2@L<1&Si*d5^kkB+U<=@4n":
#,A2phLK"77;*<&7T,..kD-"XQ\!uF]Y6N9D+JVu))8-%W%ZZ9-N/2[g/AE&J1rmX[N%A4ia2J6&3g
9G8P&!.'6Xt%5*)]4a/)X\e]94jRtX?hflmCL5r[tL3mc:ZAFT7A&%QV/<!!H]jpCCB@2>,#WJ2B.r
$kUN9.&!<a<4>Q.ArO"%n%XX;I!s!8RF*.05dh"in%@4a-@uJ>cTiPF1?5Q_!3FS>Y=B>!nhem<"ln
ogVBs"Ta#(HF%^$4cs`ZZ9^])'$,kTq_o7h-*niOg1ePH(W@Tb(c/$21!p@"rW.#sQe;^JIMO_P$<"
1pq'`3"g9;%10."7ZAs__aeJn.ts0!JjpM#W7THOU.&I9DOF\>QCjepTdcd<bEnp3R/*G)_-#r_q&G
tU#7Zn"55W]19-a[(kLn:."gGY&:"a-ro:g]lZK.GK/R$HG4M1(WaTb3IE4tn,U/*tWqA]J0$k9)"?
tWSQ"2cM0S+(hfOhq.HZLUJrc`@<%LF@4'i'iEf!!@N<ehY>cQt<:0O,JjO^@Ad'\o=4JZYb'bWNo!
aS5\g^UI_b(c-2pR0fTS[M<,&Aos2`;&MX\%^1"KGLl[gWEYI#Z5Za>*]NXR9Jf#J0TU?Z(j65A'CV
=\d1KCQ0U)";V#m1]h2naH6\?eFsl`oKX8AR84#Xp.4^c!t7,GlD+4SA@7+9(UYguBPq#LdGR&L,60
Dr6s9T5=G'J%5=>NUt/Va0PtWHL2hI+lY#tAWM#F5W&P85_MUYHMp$li#dA`q_QRe\b3rgTDm=Y%Q+
;uruJ7,Y;"gNa8a?DCGlWGG4em8FrWKg\nu(Uq5L&WN-bFt*(M>$3hkC\1+/uFiTnT0o!kIW-Vhg<<
)g>A?)\8c0Z6))>q"H]>1moo4XhCgfHEZo%E8nMi(;em)'Yrie'"^sng^\]a'`.?%hdk*e1k^Y*GAf
=UFaT64=@-eg!LI#!Bg+7?QhjO;NR$&^LIDF4HS^)%/ctHCla`Kr)_BoQ8NteLA_6]Opj/K6hsS`>E
&NW!nX"pkD7"k4$7!<D]Tob5nZNefmT\>88:HJM@F;7NYe7t3o=F3C,g>;E/[O`/\L\`.6$-$Q2JJo
BWA4"m4XK@^\Rgd4INDT&Jfi^lM3CkT9PTh&VDo!KWJ2DdOBo:Ss0POj,c*mDBg,aD7MACd#5../52
dpoM@*5qN3IcjJ@5t0s\+S3#_>hATK]4HFisJ1_7UU%beMohN\j`)'B21pF]OgMPE-NjudV_Re$t>)
U^eMPXlVUIS09!Ig>hMY3gaQZgd5;Xh[8l3/>[*;eV)FFcWX-]k0R!%--p?`@nuR3%5aF<5H&&",al
J-j^[>eC=:=*7S'!_8jLGkbmiUIEg:MJm#uhPTrAt)EQ:'KM;I:GKHSR%9Lcj.1cY,OcgFu\:b+Mn=
u$5gHY$)![IQi,VKQHbb/sa0.]2S"81`22Fc%8(ca;V$Ls)*6$;CCba]8rEuJ`2"o&J%Ni!!."`8T"
)(e[?8MQ76/9Mpo;8;QbQ*C$@i+BnC0?UtEq(rI,QZ!J1GBHH`#YR/j>s9Q@j6Tn)>AlM:YbD6:b2?
KmNQT,mmiFQ<\G#'S0)<HA.kG\ZJm#uhM""7`[Zh)-;)'^[5Cekp=:I/J9$b8^*sEP_)87S\)2JDMI
9MY('Z+s&,E.A7nn,rE[r-='?D?u.D_!>RKZTsl)W1iW\G26(E"rW'93\i)kQb0);,>NRRT63MY*c'
3!gMJUD]D1k@lZ)+hOulS`Tij-KKF!n$R1CWnP"L,6]"&lX(BSH4S80gSDtt&!Dm(X%VJVIMISou1O
t=T'A;E4oASTTG$Hg\1j8)h+<@aLfVe9e>G[9l+8>I<iipT@1Nn4W9K;k`'P;H1omQ4GSj6&3^D9Xs
V/;kJp(@#d1K?$Q]s)EY1#>DFX.=5?7%F;DoD=n[edIU@Bb)V_PQ0afV_)18PsfapqciM/7>HC%$lX
Nh6\fHdmO6,TnjgQAbK(X3d?tk4ldpG8]qi-;WpA$jQ>N+<:7N<&Wu%?QL+8%srIi[`N?lc9F?`')V
C05^7YO=?'"+8a'oLpKKh=*cJc[Y]"+=m#9gD)<d#]G;I8M4V*4m@[%H4l0N"5%(85N-AF4BV!ojdu
MEg#a%Nk7?sfbNniM?jhO$=BWEf;2ATB9URu8:jG9a'P`]OJ%!2#/Bf\SkQ4QSMj=N<>Qo/47DcpY.
#ai#$pqUiDG)SPC9CImYnEgns)<]oiF=Da%0%L7XH7tGUW8ms(UAa4jFnRh_U_0@.(]-oCqeN(K0)0
B]0-mc!EjJ\R59tHdU31IN,pL1a"NM!O3^[]VW1i;^r7p0pI@"j:`QS7ViJO4N*1DWY^gs6J4A?0W[
BdnMX>mlQ($O?-SC1iNO"TE>I&]DX79(eHZW:Yg5?fQ\jd1EbQ+(id.X8*3=U-$T^Gg+WCd2#JSSS$
O[8$Ulbinq`<S$5VBp-\JrP(i^,3k*q\;W:qF)![VWRaIB]1`]M[+\Z+5Ze@+Z\2dE:$HbGrp,"%g/
-/72FU<OGJ:f>3?[TBPrcflHB?)]-C0_-5sMWCB>f!t,0$h0?g`q@45g/GL#*#D3F!4W-Vk#c_fV=V
8gTj];tM"\EB#W!fj*h&gf6T96b^o',uj"\Z5U:6d[k=VSp[@3-$.k<,<UOZjZ(VY:m5o?rKK]]qAG
=.4Cc05k=H/6kD)Qbum":=tTknNHdI?3j3[.2R\'R@k@c&Jd;tABYKgE!&H6/dVQ2YH75Qok]V#LtF
QC[otPkjO'U<rpPV,H#rSCZ3Tf)[:/H=9:iKG17uWPQuTWkAf`')k>1lK-1^9Qk1%V&c33k,n%O8ah
$&N=J@T-3l':RI6h;N4JbffV.)/K(Gd`GNYB+&#F%:RaLbh$m;7jeB"ZN$=&n$0*hbhcc&.AOLDW/A
7RC@@a/DZ0qZPA-eU?7%LBh]WQE$@VNG%i[7]H7?q=;o1rI9e4rU]-c0J;V[s;Xd3['7W0CR0Ge7,W
-5$+KlW'R"LKn(KPmuXRp<8<%9n*>-sDo#^@nf2E_,*)Tr.(0KRp*Z8+]s**73%P/$eB7re4<IO9Z@
Y`!!6VNumd5f?F-X0^32bh]n#:O`'8Y9@]a#SRiidYl#gnDMBH)7e@)])\]//qWV%M_AZ,68%@pF:l
.DM5PQ-`/-+8m&(q2Td/JfLeh<d+L._QO;M9D:UKNGe%,KdIoVc3\'N?V+u\9m(X)Ak0Ug,*@Um;&k
AZI$-EiJ&)A$5aXF<V2"\DO9U,E![7NgR]H3es61Y@cT5%_#PC1t]U*H?A<6@p\<OF6J<%`]FPh)\%
mT+Z:eD]`uqCXQJ.F53\BSSdml6SSq>.b2ETTH-L#prd8%oc&mPr[O58P+eYgMDFDn<q!Go4h6!H<?
[3c&!\Ii#kZB`c8R).N'A4YTtb_lW8/McXt8L2%?X3.G_\*>(I'snB.F#CrB=Rdn^P+!pU;SmAobCZ
"^e(?cjBU#G@,ps#)fHg9#f\2/n\m.CT`CD3"'OEi)jH-YQ-&VPn8*Aa*<n+5%W`E&ZOabNWn&GOZ<
IsQG!2K7q8()L&7Zs<.<t`rIY57f/2Qe*OZT>:gK6;T%7CIli?=QGZC!\>kd$%\V6?rCS+/O!%LW:5
SF2!jWsdbTg7l]]C=PhXUE?4H+@3WTt%_`1QS.D(lcTB<PTPOX""Be0=L<d)k`4pL\Ogfld4%Sp%UU
7h%2B$='n#t/IDfDN:W'6Q^,i5ceSl.*[X4E*E^u31Se9`E@t(=P>Tg=FeXdpJ4-UAH0NjH88W?pO0
?9RI7/MmJV:fUO@W*(T3@Ho4u,egk2UtB_k7h*p%ddsSRQJ1qPt!k-C-(<7!Hig*/3F`%5'&UP6HJ^
"j7([\D@4i(4=NaDd>DL1;7Hi!1n$%=@KqS4UZ[jZ!TiWGpqsokJmj&YLc<$;`#-1%7j<+LY174k;h
91(nhp`F]s]n9GNHnLLCs7E4/*QH-W5'JUHn)rI>[N"E%Y$VC'@##^uBr6QqYq**L)`*N(am'pe9QQ
-BS,e<VD!e95G"9T!.1h^ZoanR?(:B5b1KMh79;:R5(b084gk@RpT@5rSK1Nt=_$bR95Y]C6jE>Kk<
-^AT_l+K)cT)teX80e+R(bcCpYml6ceQ:fPN!A%s"$*fEtBo]5*cQ@Tc/_,i%$S/!GZ.&%/lB241B0
pt[]ZkD%,mXjq';ie1.Y+]fTnLSekAS'/m^pMp7_AjNesGQ%m3q/:i$6\Iki:D6cC7.:YOL(Tj@%4Q
nbn#k<U>Ig!#@!n_?Yf'$8QT%V<fK+HhUOTo#a8jXoPK?6mor;q<T.t9Zebb#Ff_ErYL"uK\&Fa6Qe
,2,3(&"8q-Kf27>0m7QNWBNZMumZF0;^Okts&:DZW`*^A)ig004138`GeqKsTHdL2Hp[>k\)WAHY=c
c2O)Vps/V<fY=S1n[\8jUnbY'WaK^i`HP?DJ)V:rE-5g7$al(eqmA]`IDQ"_%pO<W8pn\Xd$jnQ9(9
ZZBKX15+t.\525EVhknkoP&;,M@t*\<KJl-;*`$pk=QhA5+_$XKL<;==q!f#OP=GI'BK#Cf:o[@*S'
kJ]_n46k=.SoTBG),J]maht%G/S]Ll\j"q0Mnjh.ZG5CZ)!n[]F`8jYPQgi@SMfAeSm+n3Y=hFB'j_
Y:S'g2o&fR8T@3g"PYHC19FVa:3'TeN9+P,L5_kn\$UhIeBn^oTO`h0.PVq]CX]+<dn'[g!ljQ"2p"
a-(]h;Jc>g3Wc&-b%JFe>=015T4,CMOJcb?p8TsGe?PKAank,QV%IfR05@%V0$=Y:J?fet&_LpHSn1
R*GjAnh!p]:V,WWM,A)'r[ITRN`*eOKYk%]_%Ij%\r6)Bc5[sQL/8Lf?S^%WBK]g.:YWiY$,uDFM.!
pen;[Kpj`?5iDD1'nR56J,n6I=k<HS0YZi]]I2335fbNlQMTVeDT%o$4Q11OP'gR/>n-/bCMqK]`j$
S5:8/kZnlru?t*>Xhui/=64ls&%q.[X'DA]SOC3R+Zb4S/>D+M2'76B14l@\=Vd<7[j5?(a_KnFc;H
J*^9ioK@-o#q-*dGKiJHOi*Xh&%[Cdm$t<)o,,Vi;,068@jl08+$`S!3r:54-M>0"%)lEp"2V)Le/\
5kgY2&S[.)P:^Q$;&c[>;@'pk12:4U,+^(*i;Z/lrR9K6(PEOiV'(3mjBZ0&%Q!Ci6d0EY[;r'eKml
K^s#QShUYd%KQf>F$D4@'WTF:c9g<'HBSMWMR9u0ciXgM0MD3Du+6(J;;K[8/YOQW%sj'5/*"Y[X(d
^IrMt`s2YBqV=`r(s4DgoarL-5/%]Z7r$esb:(BIu&1Q<[*o3qefs0>p%!Lu^^$u:e"QCgSS$=[Lp-
!gK4a8'bliTuO[XL301-sV_:6$"HgjC]sKhio++Bhu^8#U>V6GU/P;tAD#PCbjg7btj9G(,#a!c9*s
\YuL4$`?\kNL`C.Mh"4R<)R<lQ(L,`2s>XZWbB78FJ+TN?d.-9qsU`&q=ZO^OYNsPKL5EEb7!dRB@Z
)oVO9OVUdmZHO*<Tp@N`YZ1>SEXbXHY*=OotkD$5LpNK<6M2E*#LZK9OWI`U!edo0<(Z>FBt^-fSFV
hR8oI%Fb2.&IJ.(=6U_npTB3o,p=>M?ILRq,Ab4$@r=#F^g%GiDKi[/<\9:EB>-"D9$[%a)]u&EDE=
h/s/+!HPBR;-r3G\/`dlWFX%EV\l9#J:tVG/"9+cc%F8r+^[t!/,X.o5d%'JXp-4kQpLQt'>Y=d/pC
'&F__t"!q\'\]%HBB3!llEFRk:>Kp[6WTb;jR(W8hP.`9-5Xs4kMkoB*']>eIf_ErY<P]n\HR81>]7
B%+c1q#*\@)V&QdR<ER?X@Fu0$LO@e]alIc&Be@l<Pu>*7ZCN^=IqO:P0=$.q*kf<""@GF3#0SFLR>
nAS)H<f=aU9'@?3YpDqQ@MC>.S&Eg#p+3YR]D(+q#RN/"L'os/T(5?M2lf#2"IHq8kV)RYcSF7K]&N
5\'G!:&[P!9gD2YuB9+@r=%-X?qOE?eIl)<nHaH^)B4IWBb#19k=CK==Y2h]OKPNS::m(/P,!H2bXH
%kk-$%q"/Y)hKn?%PJlPA`qcf%Hf[7jMB#_XN"@9Lm7h8uU;D"_?sic2/'H*T/(#jV*HULT^0l6arm
>T%72\M!%r8&LVlHVRW?f<9'bt85PG#R_c,Yl&KHD:D"3l];=_S<Be8Fn%8PghKMUO-g9-G@&^c>_N
EA?=n6]Tp.'3u.`bOcYWC1-nnFR>o+D4%*IZ-mo(q*pKi'.^sA!*BCY2T5*D=L^^qKqIEn^k!)-8.A
1P9c9E;Lpq=W&`?&.`)1F0)6A<OG0L(^M@0d>/;@)$B]oUE];M+u<?Z\C1]Vd<O9I<J#J@>(9oKEjC
_%VggUb'<3h5iDR?Q7+S\q$oe0JjA_@$%tU;.E--a^S'48AB64G"#9\t4*gJ])f,\1C10=aTOq6Q!t
m#.%3PUTb$m]R:Y`a*"bA2]reG%KBtTqFK:V-,j#.B'3A4M*gc\TUX[3%OT'`.3p>='l"q8F\r,Uk>
4]\Ci[U/ClWTEh1@8,cT3$s9VS#md"e6lY:n0TEA>kO\Z$?lCT6WOhk$f^CMiCDT]hLM%gJmKkn2,k
n7bZ?Fhia]A1;rq#I!.n%D%aQJ@C,(A'YHuZJPjFs3Qn^b:f>#qEjV;kU3"Uo:>?`$Ec9G1.ET:.IP
IdQ[\M>eY^"\JXJ]Fm=MNjr<YgK3ESBRqgBPnJ\]B\RIJ)n7m@%?M"uBSVXQ$Uk7ld%lfc]7Ir0&Wh
S&<gp2h<<1"]<`@,=-5os_:8SL65[NuRc<<GpWXk$VTBGq%LH>[r6dc?WeFkdtL5bD"tP'#NknTgW,
r]7dC%dS\.01PYI+Z*s3SkL"*I;mLXXJsiV%5\Z8V(qJ0eP*Umo</Qf>goreq4VA]9nq_d$Q"PB+-O
,;4D,>MV#_KK8gAYQTCKIr@\3fH.DX@-gL2BduL"Ks$Q')1oW-h1);'Wt;^%YdR_&W_gatT,Dpd"!4
AWDVc[ZiQH@b2->r&S_f'B3N;6J#O,TBO6NV0Ha@l=EMe?jdNCnbR#;L<DeJnu9kDc$5UQiB0&ZY2M
R:AYuueihRFlMhMbcD?;SK6)5=<=&;2nfdR^9$/*8]l/n2@gM-iNgiM(YOO.TTGmJomjjt#3LJF$ub
G_P9-kh:d1\1iC(r-sP9+)J,9@0Mf$C+.RTjmc[BEp*,87e=WR/h0hV'll_1+*;/:O&5#_G#XQQ?hX
/*W7eED4FX5GY&mq_Q_1SP]HZG9.W@n6YhiH%+nr+huJ:pbYUgnA)YGuj*+d`e8ss$Eq$MKQGn]/HQ
PGDfprp4/C_.LZZ+Qsr<!1A&[l"hQ;n[PaMqUgSS:UBCr,ga:8Uf7<br$^a<q$.EliQS8.q."+ASSW
.+0B78\e"P.*;hI)o1Pbc2]sO$6;_XjMF4%L37QT\pdL]XOV9A[tODEG_3jE:M>6"N4X%$B"4,1oLs
f:^N:*QYL([-m?imoM0UgnX=RE-hu<RQDnL5bYJ7THZns-MCs;fhU8N>L/qp,qlGY1j8i)dti2a-F9
oK3$IrGA6F"\M@KMaDrH+^WBZ4nbu0di\5:)o4F?3Rel6HuruP9;7#>qm>)SFpQ%H>7hN[T/5%S#@^
+hT7Sd6Gb,dN56rQ`f06h5-Y_8:U;[69DI[XQ7Z^4A0@$RlHt:hR:bRhP(4"of\AX@X?_X+=7F+:,g
6D;(ou/N=DV]1CkD(o/3)X!mdLDkEt892&;Q+8Nki^?+d\X`n7VG*$Ar_;(11>CjDmq`P+Oca.jZ0.
^]h,ZR0X,aFT1I,2mY$nUdI[dYpi_3%Rb-7OMFt\))9Be__nB^LS(jiW)qk9o'Pn[;IA%,]!/I4YZ[
W5EU1l954mc:7/fY;Dnb2YRr;F$q(Fnb7cY-dN[]CK\7`d4q#qF77tJ,HL&Y<gje'.FcrFdo=fYTo"
,IGr[gtASpJoc9S3#&%EMfqPU9D#Nf@/dSN*qg)EfQNg4-f8XTeZe[6dTT/ed#96OE?Wjd(k_+-jYS
"E-,nt;L2>LdA^i$bGS#Q*]W4oIG8PX(R-+/A`]!]$;r00\-?"C]PjQ-H#(d#A;1,B#!l"V(rS(Dn]
#iA%,qT>g#oYXc#p^`kN[r1$P-2D</#oM0h?or!k?>SLfraQm=p5dc)NmGj45#f>?`d,">FmTDOC.e
6cl/\aE0.DE++Q[eDE>]T3+5-?G4]>(b2&=JL4?+ZSk+N</2Jg\%]RB2;H#Li>ip.GVJ\0*:cFrlRX
(m5:@/>>7dM`B:MM>qM4A$g',GLXN[Qn^M2/eL%@Z&&-sD1']SX\7i+iI>ON8_HkUOVft5#aT>(+`9
FVE4"@?Ynp$qFO[k@WrkH)lh@^^io/3=!(..kt'X(S8A`/iNrn=GD!Jc(Z_=`8C)KC%'\7<?7.FfLk
mr#![:nhNV>B:Y[5%Z#o()-[i,)W`W13_Ek2lHbDG]?B2f7?EA9@ks,>`[a[9Zfa/7.ZZ`tMmhSf$l
\d,roUe5*^uIF[e=$V`:)ccIr[`9p_Y>niVY-srmV\_qONt+cP"`o:pk:2oYP3$%+,0b)M&D)^R08-
5%08Re05eW5UAcnYS6%W=s$<S5;;$K[B!31G_DF+=JPhFRPSAciW#(/+/6k`\REcC*hnU%3SSI_](g
q4d"[sD\Ua3<A6JL1#n0j@HK?9($c4;HGZ$"X'!],g^MW5T%<JXDb!O[?i*@*+CuF"M+5.-Y\#$JO4
uHlR3U_&*HXbJsW!`bS(cU&O4o^\a7E.V'7W!<DEbnu;>Xdd&*(j?J`$.0]V#JPEIsf6+i_M_AB&WZ
>n6K2c&_%td/>2%2f#dfV\>]B':Ep;`m]A$3nH"?d6DouZdh*:Bkj3qo>!5&tF'sLJbHDr'huaC?HK
1nF=;;PsY4'b=_9j,mkTKrd\(0#O[^:/:+eLmW?e&.nc)ir2%Da=*7fJ?_%Sf(X"*FM6(N7(ap2T-&
@MB2RK;S\F=0JkG]l>+5R5rK>bAi-1_,:,n`J&OR)o#hEq\C=j&g.R[P289*NaMfubHHB.=a!G)\qk
&jS.K0284EH-enSRlOCAl_JV-sR'S"*ek]4D>qCq`]hDiK.k]AlYYnDXJ.h`,?F_Ve8c9h0H"DO_DV
D]V963Y91`0:]o>Z;B`qg%5HUE,m-nDAhRJhb(A[sJCM[d[n(4nG`3Dgh#t,NK^e5io@e-fFM>T35A
:l?*1?7AZlo]U9&8f]6mS02ff/U,flPO.I15i(cm:^N;1pg^\OO%\pg><S_`]A8h:3hX^6ORTaW2QU
ZQf+[Me2iF&W`m<OngW_t,.r/>*f"Aq2m(#>@@>a&**WatP>P50MNAZhmH4U)3B<^@)EC*Y21N1r9[
.7f']6ltqqEf06]K#b=)`j;\jPN3%5TR:5PY/_^7F&QAhYpb6^T.fd;BaP0hjsL[l,UdUqluqMMf&$
#<j+WK#?5RGV;0Q3tgi*,HjD1nV5JK/kctRF5F6rQYO0TiV;CCqECDP;s'Y:1WB3WFZ:_P$'#QQ.Xe
Zj\5F%d#4(A>EA!'gNU6pXf%(EqAJlpf#,Um4;B>`s[ej>4g.kAT\Q@q.r._9de(1XZmo>r<.qS67H
]*r]5bQU1S=O%$.kc;%?3i$4^#I6jV']_h[70E\7Uk'ba?,r().K+G%i^9g;SN/c$N'D9;Od1u?,Y\
5'n"1)Y%=eqtl\*$FP>!RZh_3dCnnt#-(U!EkjMGkUaG9I,G0>sXpBAS>Q$G1lY:m?M'"ft1P@k9f7
ai%9nFJ^0FmGt6Y#WKG:+SeAmE;]OdcbQd&o8+m;`W,no?:SNPC[#:%R&E>c0X#kk2`WH=0qR6e'Mn
SBk;WCDD`l_1D[joY!>*'8^3@5s1`)At;,17mdfBsn^(+O/HZipq9CU1Vca:!/#'Uj52J2d#6%W)/+
jq-b^t.jk+PTA"5g>+U=eJYddWLP/Y\oHp!+802>2^e[Rl[QQ!lgG%ZEiRRhg:(%c=Ds>=$l_a'Qr0
<l00@[KbR&9m;5"f"dh9p&-.;e[$OiNU/#.B48kp].)<(pkT,-6R(EUk]:>FSU3MigKUQM1nFAmmI&
u"K_fc@6bL'hCeoH!rGMKoKI%M1UUGLH&]tIO#Kj9/Td'/i_M/6B#*TRZb5o+SR1lnp2+o[?lZ>[M>
X?j/e$l8=omi4]d$36a-Ias_TQ7eRt7o77B:^4uQ^ec;@;*>`u_?8VVEupZebR;+a>\XGA:s:c&nl%
Pfl&*ZcX/DQBoDD5dTQA<pi5A-A>binj*-?6_^^34:e^`Z`8se,Ea^AptQKB=)f,JN_qnr?O1'Xd:i
5AM!ripEWKl3X=^T],0,U^XMp6DaW?/QS)$F`J3rJZkW9T<?gFI+Dsk5<ndn^X`m$C>@kaeZg\a5='
aWb,2K^ITbHZbBUHHVm^L;63n\@kA1t*0/UYSgU/`$\WI1#XK/p<VnbiFd`K&#oEi,4h9l?s7Qf9g.
XR2^.!,/)uo5MMmGIu[d*G3]5D!LK:fjm(ZS#'FN]Y:6?I=nE^*/a)?GF6,u,uLVs)DfI"R&=/Zn5[
iB7nHUu(["hU?+lRp/AfqV2q\3#t2<9?G[PQ->&$,[;pBM+/t%4WB#m+[-$@'FBYp,d56K3pLiXou8
:9A5=g2RKX#Oj_VE6^$5-E.KKBI-Ysj3N<!e7Jhn7-C.3i<TW2\I9EnH\UOBSIc/)I.T"KNW/i)(Uj
FI]]hKq6<q-oJm-3<EW;->b0pc*FO^,JSZA)U&Q[!X8O.^Po3Nd%+`Fh/!EMWO;_NLfa-0+k24H#\W
(Uj)/5cTJ[tD3ku3+A:^h)dOe.[tRXeeUoF[#RrcpV-o<W`!"$Dl)HWIQ<8K):.bN4':;A`%_76alG
+8AG0IT#)OONkh0J#i$YPdfR3f1B_q1'-k$b3R'l?h$A/djFm$lmYOhsBc#&^+\bga?#>])9l62Q'(
hTE8\o,+0dmIiE(cOBQk@^bQl#p97H*:B#9*nNW=hN!0%4I42S_SP.j5=(NI\)C]*kWC/7P_S/1<m"
OhckUO,d5Wr6>@OCJ?@qW>%d]!0Fi7$bTR!2IfEEs$VI\3:Y1YXmh=d?dHKMfH<?/XA'fIaKRE5XPp
:a>(7*o.e\jai`AKZR@bROJ],+jT94(WF8r`)Ta07+uqO;TN!`92LRJ/JN1Amr<&KTMnW0(tiG`uAE
nap>%tm(A<0>rWs+6mG?P1bOO>/RU0oK:nKLmNhW93.nKsK4lefU!/Vl5V56Q6<T_/^d'VfQX!G\eL
t6oQR<qC/6?Is+.FT&[/LDG@7.,qCO>U5K:nk;nCW:T`^);Z,.;JToZ4r9MMfC`GO1gp;e-Q.U""u.
<!gb%l&9q<F4n;+e^n%`pN)t_&<VYfa=_rsjF@a\!nlirL<0.i3HhL\5b2H$>?+%#2c7&CKhobJYW_
RHHG)..RU5I8Fp]9)D>&p58n[45k.rq9Tq+FV%a6&/FdU*iIr0$M&_8($/O`f[Z$WH2e(WIe'%r7QA
7RZY=MdMC]`%BHh]f]O/N:fq)i)un"W:Zlj@Ut!oYLY.K1BZ[>C&!62P3o%X.3Xm6H<^iS"EA._(\2
N_\-&'2#%[#EoLWI2u`>Mfq/s45aI$bl$tK5Zj.jJ#YV*I!JUU4Ki"In=gT,[^.r8FlhH[?)OnA8H\
^\7'nB3]Eh:Ft8;`I\)%pUuTE1Pm/.7QQ%#]^lk&)G]E2p+O@TGg#F@Sji$a1O>dg15V?3oB-s"T)!
3'gYYLP]X7qUb2K/4(+2e$#d+dGhN_l#Re^]5=N9gLfuMWV>8_i]H%Ie`.TTYb9p7>F#k.37,nL#(Q
[$_K^Kbck":?i.orLId[J-p#:K-/#Ds:QKRsC*'/):TV3"uo81.d;8`A#&[-OL:/g0"?&1?"f*Wg6A
b4376jL;tk[HS,kS]1NBMZmOc'qn#>?I(nd#s^N)kZ1khLh$X]!C'q:)%V?/uU<D!(5+L!;!3pf!t7
:RK@ELP;583Yf1g3]f-TF2+<ZH/YNnMhTmH,hONRdRdT7-@?%(s7L8Ce\P_4-,:A0(PpSlHWcB7mUH
J^#/!"Q$rH;dcS$^XVcQIVUh033'P'D/^5<cCYIO-#oW4ud>m(%0a)ljI>-N'UEjrk(ka^]QuX3Ib0
\En`R*Iij![QAQ-7JqF79MOn4#Xl0PMCC+\$PbE$">YNFEtm\JXC#n*a+QGe83oa5I*76-%YcF1>\4
r?'/TA1TAKIGhea]R\%r6C:muqG[tc&16PRsfVr(T0)0'kZ!fc(C'1"@+!lA/lrqq/mk]e9j$O;0)0
6@INC7a?XqT-)eJE3uh@)\k4HX9].5ugpD^R/klPU7dOW/)5P?s]3U99p8Vp\]Ju0HNai8:L6$/H>k
V,6%Mo=#T"Ql'tIW7Tu7mO`^utA[fu6R:LgW_Vbmhk8Z_6_"l"gb0V@T>2uQ$r;P(a1J;fB0QclA%2
=@DYnCSeg[(H$8uLd(2Zr=Y?+,=#+U1kp9Ap=SScAD9f*#4ns!U;cOFKB#=gL]TI`kVPKU#l\7+*nf
\XGA+NI4$/<!!S-31DDE.0hjQ?9r<N>)"VE8E.`_;fJN.M3"ij`/j,S&9)A&McVAQ@'k\XKF5ogD]Z
e:H>l/A`Tj)<"D9h]0D4Is(@.0B<QEV+9W0eVgH]1:Ob)D5a:9q$g9RjYk_]/*5.:6p>F.[5So+;Te
D_/MEJ:DS:a0A6[[,dBr8M"YRPWN,_4YOaOIBQ>ooHn:<Wl<nlEJ%mMk>HIIpK0bY&-]%Os&u.i^uj
<aNR7CZ!IBc0o*d1ZifJm-@+C)W3j(ld'N3FZtXOM,XnJI8fZq.=iGmgo"EZ33XQhXTKrTIn.N0I?i
S8+\;S^,+H<?6e>e,OO>hQ@'BVq((PP!Mco2A@?%'>Yia=4ZQk]3t?lbuPXY!d^Q>mh4Q&+J>>BFdJ
Yb$`K8JAa*Ns[*T=W?&ur1NLc<+PZB_8(YFnP0[ZRh'd1S@m;*07NoCbEbj9qV*WC!^$nkm/Of;.9,
K@Y\qfKB45Ni8eMDWo'+uFrTt@)cs-Xrs87-G\)4d8,)J7m71fY[@9hMqNO3eAEDghIV9G!<-TD/q8
)bnQR""A(&/*LQ)<pGOBk`"S5fK=)BCb=16!G"L4/.N,UEDjX#:NX.^`-Ou!*!1g$6W2R!tpjUKO,R
SM=!u/YK\R1&i?er3Ba8j.Fma7di+G"jN6N-![=![#tfoWk4gSo_X$hIDY@qKo&QRPK\*r2fL:%XSP
f)^$=#Zs7Y9FVJ)HK%7]"`X1"`OA,cH<0IbAPD.a)bar)-j:4eCqai/3M`p>?#h^EfC*6/DE>^Y9qJ
5^%KX=r\%;&^JdBA<tp$Y=H2pE84o_";IhUNJ$>.3%Yp`/bt=;WXCO`I:jt^THlT-9gW>Rp;`_=jEQ
a$S1eEA(eRUQoH_g@;-]<:!Z."^2G-qGBkQ@lr5F:&Rc?(u842lSLqe.P'sRrL'eBj[S`k2moI*sp[
;4rRl4Y[F#raaPZOdtc&-F)0Wn*j@>$RHjJL.Tkq8anV)2,p;XagLqetcgbKlsO-C^<uf"hI'BUX_u
p7Y\luo/RHm,K'Qj9idjgO37gL`k((8_%7#."R>=$91oQXTs/[D`Jch?%Q);g81FBE[]b/E.eqMZOU
Nn)-a5m@>9U9<i/CepZ;$+3X&dNUj4<>,rr#kj?$ntN*:<[_%m)`^@2a$OEHVB8Z2uY-5NeoSZgo?l
gX4E(dU]k!4Oa.jT>)tbAq3!"au=du(jKn!Y+%5]a>m^hk!O[6]WB4qpd3^QG=N;?;#r?r?[r*s[[j
=Fp@EK9*L`0b")uM-e+JX6nAke6gFUfI!9=S`h%GNC&C8uKZ&"cZW1Etb24LAGT]D"r(Y.+g0#*2EF
k8pLDE'8D&dR*+Rb*pLOe;ak&Vku#(*)(FhR9KE^:RIJ=Zu@m!_'%I<+/6c6>/B`$T^9Q%ooCQ&SSJ
WNCbg)1[Tqu%<pYQV9iF5)O;THhKSBOD-32>5D$+-b(gs59pCo2=F98?C1(aG*Ws3n%R-dEhLI,2f:
36&"u+ua'h=LI"=,B6KIFc'n`8!Y?TKUln(G#1%u4Ei.*a([\8Tp<2D)0&\NlFI`HR$HWMB?([*5"f
<_)A>^/+Zm(1IDV.V+ngNaZ%@#qjlWIb'=,+u>.>(lneG#F%#!>V3#);T&aRKn4+f5m;dlndjOfUh4
.R%8C+or"WlSPKTZmn,DHZ=)XVTrl'YWJ?P4;r=;\F:=2onh[YX)J7eqUNr9-V^@L!on,1q`YY%S\4
RY7=hg>*/(.l1/%JK9A<_WD8UK^;pHd+m!i[n_jF?@;N5c>Z00SQ.CV+X9dZG<[d)!GmT4'5AWcJco
sb0uPXlBAg6iqn)Y_o'DWEqkmpO(*bDn7/Q,nB)FdjfK^mES][oN/m4!9PMQsJGuXl.;[)J`@>T?mI
iQ7@QR=qp[3t]DA@"^TLX/K8eh*&Ua7JiGpoaUPsJCu#B$s4#RNQ"F*(-YVmOp.Q+JK"-Q<Gsa)-<=
Z?'fA]AJ=a;\4U2eIEDF&Z_-^Q!(a6BiG8,m3ntrF8`OKVU\];%CHiqD!Ki#&>o'YQc+M"0f=LbV)L
@]^[$nkpgo\mfkbmIB/e>j'BpF)4p5(kpE8bf7^fZ%k!OtL&V_FD?$KC;"-oQh>kpLdAZ1H<2=9q-\
-]c:0:AiP]*=^mEW$oJ(G\fjC.^gTo(^<#!%-Zm*d`:tmiL4IJ@"tuQN@@>>9ELok9"#S1Qd+@+g`5
Yk-c;lQ?L\3\D;uJd7Z,Ed[P6jBpqG+.CRN`7SC@1ENsE@g??pFaG^lZJkUt_RVcB<c%lR84um8-ce
50-fqQ.gKl<9sb!<P,PRn9R%PIsr!Yni"]tCYi4QDWb5t:WDGS-'%N3Z>uX&i'2raUj6U(<-#['c_H
d5WX'4[%Zo/;m`QRr5n2^OEj6IYC*!_%EEX"AXCDocl8)jP4dn,q18dO9VD4l7aQtJ</Gr-`gt!^*m
JFjQk0&g/-38L[B;HDAVBLV=;IVAh(`PiXYd3.p#EZqi8inc=H]8Sb#EA"Yh2gE$!hJ8>d5!1)R?ZT
PS7fpRhH,ce^[&]Pae[$DW^M\n`+1jU3"8$W0:t%Z=I=##qgY+lIsZVHQA-?N0`\mO/"D40YC=$gD6
\U;kV!ff8:-4HR=f"Ffe7IB_T\=or:WRXhi:fB[kQ`</2F=$Cm/l5Qp64O+7t1S%u&;K&f0Y[3/@na
5eYUA'Ir;QtXo42,kZ]RPoDDg6l:i&BZ#VtP;@pL9'%L!$LU*g0tgdLqBd"kthTJ_RfJqruqIL%-Bo
6JW;@=!oSQG@J#t'kS=N$=/G#p$i]Ts7sk42K(5^s&]o)7K1+j>I:Wu$_Q0]0hJ+#/T&2r#F0Q?Ne\
`Aj=DG.dch@rpu-Xnp_-X))]Lkis6reeiWJS@@CRoJ-T%<-U1,#)NRdXYH3#Y^2uoUa^/4'oW\thel
(psYCjs[l=L&+(8EG@[i@N;n4[3YZDY.cElB)PNkMs@pS2)"L?<[7[hg4PJWC@GQ?iY=H+@.:r6(qK
T6Fbj_[Hq,TI2N7l5tS`KIb],<P+-@%`$1$s^:im=P-j,bF#^c)l30UT1\E&e(OgA$0.(,?2F;R^MY
r!mP*6o?79p(`5&n[uXtpB7,f9>MJ`QOUjR0ITiPG/p-AU45o(k+GC8-IaGI7tcH3E+m41;&"p*?J"
;te0X[&.E0jkGqZW@'kAGs!6iYYW+fVZV9f^^"#+h(]b=45rkQHa)Opdi*`B0hToR[%u2=,q]u^2;V
1BHD"-1[Q1J(eIA*a3%S#k:]o_P9j'h9gQ!i:Rg#rq6@?%ZlT5B_SSl&$=WWS)ftp+=H:4@kNu]+Po
Yg`EG.j/#d"`Y_RriIicA]O7*.F;TF"Z`bYIo%'kH50c%#2$_+S2Umo5LF5ZoBQ\0g.*c<..V\$`nB
oE]=&0"gXb'1hA6:"9lRP@@AG#1<"=^BgDh[WbSb2/kCb.eB&g?#H_CM+N.`&M+HE;le=SWHsOGaAL
AGSHM\OoL?MqE5-t?lOd$Q(q21RNIsN\%:47II)@WP7<.tHR@5\5$PW*uJ@mHQ;>FJuJ2=]R;r3bS^
3n/,@hU4M797=^Q9]X5rCeND[m@k!Qfu^(ek83K8YAg:OTrfc/7?NjtN#mLM6SO@Oi:80?0>Dmr(0Y
^SJp+H:Y.a;a.hNLlA7Wc?f)bYC+:O'YP2^:fO=<;)P.55cTQ9[<K0(Q9/^#-OH:,C9hgbFt^OPuq?
1LM#i8*ECQBnb9![ei3#<NJfZ+6GWCZ6HNO^TUB)9%"7A64[lDWHb/$8?h]pu$"<(nTY.KFAA8+E[)
Zgu:YtGiWNi/p<^fH4D!thRi4bFq4ubA3C<X^Q\7en9B6Ec'QYASuY5R?;#M2+=aXXon#U)$\l,Q#T
63"D$lP*$_j[>drNe>crU6[;Xd.OSnr'N=K(OS#1HJ[]q^#6BE._^@j`50pphn`;O\ZD?oI,\Pn4/*
Sh1rgCS"i(B0s26BOO3:h_qf[VLHkJdff!r#tHPj9!5`<cN.NZQ6brc.e'R$Mqs,BA*'*oS,pFM22d
?Z3*oXH`'Q\8cj?ds:rh7titTkpf\!P1^mWI%bE63Pg7=,T[_o>(0)t!\Wsj94V/Us9;"UHGZ-$ObT
gaW_SgFDl]S01bW,0GdB6ZElegrC1jE+,Y..dR3oLTF;0=fKD-.o$TA/JLoKtd_LE4/&VgFQOD=rkn
^j)oSn"%jr^bV07O!J10Y?6E):B0X(Qh%d9@:Zr(9q&MOIhKnp@3.+h_Ldee"cP_Bp6c1=0Ni>^WhU
>B_#`f*qhJAdTJ;kTl)hk`kSCr1$Z%PBTT'rHHKL[.UJqC)%9Gu&]prieU%Rsb'd=g@o2^E'L>=qtt
HXo+LV8;8E#@u.qY)+1c(M4q.5[asW6O:l\[#E:pF==\NR(1_klsY*;CMHmG@WGgL,.?Y/s)d1eF4>
!XUZ5<f+?n-3:2u='6mP(_!K0PcQS:CY"XLj^(8e1bBe/Ef?!$>pgk%SdD+)kba"CI?(aL+oG<T6tW
_.BOi2'XjO\uBfPD&3hl\`Rs'rZGS,:%)H:7o&Vh.P2_\i_UHlYo&MReFh?1ELg$;#J<0Q^o$&nqme
,?=HsI@".(S/*@hqL"`&eRu6WZ$UKmWL(kaY!n<lM:P]SDYiMlkj+%0hJb!KmI7hm(k3rT_@4Z\9=0
<#@dOgtiR#1=Iq?K+uILWbW]+5m]Ar"5=ACp7,I0Zbu0O>GoD.3s8,=-qVE_OIN^;[O2MG]6t],XBu
84hr(cmVM=^P43TS@_&`502Wiem<aSLe_f[A1<5(3p`4>_e@V`IUDPOF`"#e,<mb=]gtnXRm&DS_Cg
$*(4eR[`e/D&3CLJ-/M/gl,+ku*HT[V4i*a[d_WRNJ$e$9S>7]m23l.kXhmqb#CDQ-*>/Q7RT$WGmH
?=?,ATP34VGGAmh%-/q$jh6SXFA48e"KC'ngRgum[em?n.E)H@k#*=\6?a3<=ZJn16UeEM_'fOGd%A
n1puQ))JN&Fd'b_OC3pC6F!i,%5E*c*\AjmRR6;!95b];R)T5&gT(fK7ot0sh7SF2c612$sH:NAXR:
!V2i6L)DDq[1sga*&pO8VL0N,+==DNp*&OAa_)%C3_>ZHu]MK!#/gCZ.Cg.g:?)^nBc86)?6LG/RYJ
Q5[;6jTod<n%PgEMO%&ne+/?V?Z,`"f(29&j(89#R#o<*D$k-OPUTRFn7rMF32-]8LSi.MYO_EHT>5
o<Y6kZc+[L)nCCC<O#!'MV!tE$'GN+t>gEZdJ5A="$s#6;mOD8\#7WB\m-\&*!oRc/^n<'0.](V/mr
^01k+\->63dH`?-&!lKI_rZHB&3@S'i=\ab6n-6e#-EkBbB<#5'Bn5R..<]H5f%5qFl$YGNSrVh=@\
l#leJkN?)hOrsE@:#7^9*T,R;E?qFT*6m/2MB>4CE-/_a+oS7r%TGLVOn<JT3"]VE$FCp.B&B#)ds2
rm$h7V88"H^PF2Td>\qnk>$bt<YD5c6[7_QWaDn%T&:e1Kq<6s)_cIsRYgQ_"2fV5GZeGkAR8]3Tp\
;>Pp)!!gKA."5DhlcmS0.[[c]e@W-3"!]XKBJ?m02m0>GV6`%^^Ghja1SM8kAnHEt=))@uJ`-b^%(Z
l\eF+K<NpTB\(ljUoG"&m;:I5`%4ZU2;.A\sM&R0==K6Tn*mHT5inTst<3')II3mDNBB)c:jYsn^+8
Z3a,".\j78:pCtfWBB!Je:U_p_AeFV2a>"Nuo"a,VuD*[nJ/IS1dW[Sk@#OBd=<JMTF$p6Ps_m@&Y/
&H%uJ>r2oENTASA<&R&-:4MHtSh)"Xq?bj)"#92Sck>t2AO.E4^]4?3H]'RH&0/77_Kb#(prV[`t^C
-2;eM2'S-X-L]h?XFPEhE`b7QBXDWfJ%-Yt^KmVbYLdrB-9pfD,,TDFOb<722DC(`c3VWXg`2]C2;`
?6h@,J^t<d,M9OdDgU\HCVk?,9HjlqinB4^*q3\5#Z9c`5<h@7oB6I.S+%X.L;ns#m/D,sVudqX.ZY
-3Cn50H#ZKJ]]:56Wb[Wi4j,>u"e1">A:QYneY8B6%-:pc<EAeJmO24@^/]u#^3Li.:!G4Z!)K&&.^
,\"@E5)gP2E"uUNj&YGa4?lHLt[Gt0ORUj.&9nq>s"\:Up%LUA8le3dS-"NNa;c*W%]JuXdBU(1!>=
N7,J'*%BcMfGU=h&&tR.\$?eSHn^4Bl^GQXYKN2m.@rH%YR0N^BR5tXq+A7pB%-L:aq/u@9Jr*0?&c
`\W0R.%<;97utSnQoms7H<h<K%>3."!(\Uerl7\[1kp\8<*LWUqfIC;`69UI-95!j?=BRLuZ&+<$3>
3l`b:_idZM/SBj8QPQc,<e>$0Cr28e"2u1.q4+/jW;k[<4@97>^\ulo(5"Y(HUT6hE/NCX5#R7,k-7
";"&Blp2_GtLpP"1SZLu_5XXBlRd8TerGf(^,aAOQ*^S1-_)AUo-BG\:8&:nItkK\p3<&*u28=V4YA
890h;K=j-+T')rEHJRb[WBcdarPh(j4G*s,oVhQ&uTm%->pQfdQ;AOMW:Fmn!.KIasbnT=qBXC2ECJ
=B]N8Zq2i'&RT@s\%/,I4Y)P4$SU'pd5bk?Q1re"cDpFBr,i5g`ctrJ2B/Hs%M'k8Z_h8^81bTSeG"
P%]A;L'*8AG:\$:Ou$J'MJRF5B:YY/Bpjl0O')EI#0B<G?#e$YM`J!mo>H;&#b<J,f&.BZ#?M9a$&T
Y*,cP%t4#+LkdaSX@Q/LET3<</Ijk1l>=0Ndm;3)0t'ibM'I/OD`DI8%lt5357ehs&06O'O_hCZd$g
2K'TkMP1E]4`B;1>;J"R>"VNgi?5?aZR>Z*MUcCoe+aT)KYI)-mW?[kaM?W(md!+lmB]!4f%-N6Ye&
dF^A77n6PJJ*(2[)7Yhd*dqO2r$-q.iJ0Xc)3FUNn4YDLXJGF[V4&50j`!QH&lIsQq@")Ht$NW'>O_
GVeS^%^ZrnCFU,?C_/]XU6?)*_T)$uFb#l)O5/"HZeCKGigkII>_E:5uDRs6g/qD.j@SCSP9L)9<7s
(dWLWqX9_uDi:kff;3hFg<[Des:XG_X`Cbsjmb,8iYf=+Xah=nC7:SXk?[@C%9@"CiX4n*.gKHcQ@_
7@jAVs5j[h+4,PT#3?b,3KRV;a>U2jZ[1.q2@4.5p-:?WeV<FS$.i?K,B/KuW%@p8cm$s>Ku*c/=;d
D<JN@MFW7E.`2P6)(rD:he`0R:+UZ^d8ShI]d?soq7XP"VU(mu,T)pQ])[F1q'f8r0PBB<TX_5Khf7
RR*i34Spq,o0B*:dE*/HA%&C]Oc-#@1Q+*Nn%ii%LHgdh1+n9J,.A_at$6.g]@["$t'eKo%0B2qFd;
ORLISFI7"6jaTYN-2FMNs'g`.Y+%P7A+;&4mbZMJdOJpL7HDbpGJA@1,EEq"Jo]1C;TTX;oD:p\(m;
qmMZE62`1"25X^ab=R=BH&XG??OPJ*ktC`'D<=@`4BfRt.@l>-X"gh%.%UCb'$6nrWj4/HFX1PENeZ
h8FM'GPK-Y%cOAD)S.E*/7JQI]=2T,isbOic`G/kK>'mu$SgJacn18tR%;TB5r)q`5P2L\MGS=+'Z<
0UFug)p#,NFI-!UVkQ^44^pDqHMP:AC;@@o*p>hZum$*S7*,Zh5*5cVDq4bUsTcgfuob%lc=Hi5W8#
&?$3R*fI\,HI![EbIp\\n]&m98gd7cf,!oI87Jo8V1[`<siAh$C+8F5lDM]0<j9df$-TbM?E%gIKR\
8oR`?]7@M;1+LD=;"Xu0,A5W,)ck0Bs1;>q>%hG6$Ln1s'GbK#S'ZWi(J&"i5PNDlG*,@.4`ke=ATo
2:JSsb%YZ;t9iSL(.WMJkKpiW_aW=6!\9`U'8iC9^L7WG-_OZ0`M\YfN0%-?(PC<(O9,UG"XY/m;5=
R\$bSZ>&9qPX$*.rV_6k!#K:rkX`im5Oq8l]0UZ5TKB#4.CHa[6ss2Ipbdqc&ds4M2@)p="B@WFjWS
$O6P1:-$$Hh(K/&)g5e33oKEUsn#GO##;G,F7)C1Ys,gB@-U`TML,cJ@!"&"c<nCdc8KLWg*5/ns4:
bEEM&]=@Sm4T9e[cC!7qH/;Ro;,;8KP@GLFf+pu&Ui$2MCIBCo.E%Ki8uVp7XGD\k,*V\B2n-I^4KM
#e8]J8+<:$S?@N(K+M&gBQ@&((DXL=DVhCjJPkJMGR3$6JR#Ec_bhDp=l-mX^KOMq3f+NAAY$WLJ"@
c@RTpO+pC>e%\U1.[?/4-2U.24L@K<.EO#W1:7cg6,Wff]B@n1)B'_1<l'_C,OQ,J4Y&;8hr9d3^b:
lqgN8MHCa3&Dse4@&H(8)p@mbIM.<b!n40]WuhmCftm#-?jU\BOrBC\[._k-RUBbu+)akk"`Mdcj"(
``7m(TDn$s)K"=n[C1:%lYA*N;(*`eLU=Kc$H6\JSTIL_DZYBP_MBOlb$6>>oV4-tpKcGhEA:MJkJ>
f#B>`l,E#j)nBA#=skNJ+<qGAs$urqZ<BG#TSFk=#PR.LTc4!+)`l*:gPk`R(T1]3A`jU3EgZT8u$R
JAdTBN./dW.SqR:nQXCp[a?[u5T:AuO8e!/9(<?`nESL!-Di<LVi.8rQi'$Wb+=*gYSTMi>de2qg5h
@0C*iDKcJVAV$U1NL.6\(;tCL^o^^2c8Uo;l5MIIlqql`_WuFLY)Y6(T+@W)5!8$pO[O0%ch!pfU?9
%!CIC:eS.)cEbN_Bc\[/?(pijYUdm<%]bu\NMHC!gGb'Mj$!:b5\\,j]6qTi9.u]J@KR_UJg;cgVGV
+n8JZ>na+2SJ*+r+0<EJ>`c9*Xs#X7%X]40B`8qR6]Ws#7J6=8Z(/tQ(IDXD8WMB`nB%#%OrEt%Mr*
tf>b#n/Y'D2FUY2>A.cSChW&rh*V6?Ap(]\<Og2ZYYC"PrW<R<*!0G,cHck+nC0(J;n+sjIsHl$0ot
"2qElc"SWc*0SU>UPZ&EmWR)Kg/-P7YJJK/-QA0q%Lsq:aLS[q>I@t*?9.W=IQje]LD1.<\&1lt9rV
S5S-d:l.W2Vg+i=krjDGfiRC:C+:`nbdXnl`;>JJ7GH8'),m!l/Z9hj6>Y(dBFr*hi?)ifa/t':U=C
#1"cD(V10G2$$7,bs4GS&XP$T+\WW?b<VbQVq<0*SnRSs=rm1$PF7N*I]pe_fUGt_do#9"p@,pIL!Q
SPa^?8XjXJCX0OO,7-o1QD9tp6C_1Mq,8qIF7m"!:Y<k`WrY'[s@:F;Y:Ob.<_9WM]Nau%bEIL.0tg
*ON05J!NIkfm=<:@ISe76`B.HUanrr95)ks6P4C8c4\q[5_h&))AqioV8RkZf'2*K1Mr?D:?T2eh>E
ff\[Ju.P_gAN+;(ji,JC.Dsp+m(&CBoPaX;LF&p%Q+L-&lqhYV&)_hVRZRnAqFDA`BTtI\qCObpYBu
ZbcLZsF;_Aj13GlG?)GkY?dq$_jT7mmqCk[;lI[:5*?pKEIX"T1[l)1'ALmI`l2n>rX)7#V7S*V,3I
/pcfV2W$lS,B]!9hhUmK1^_A+LF@D%%k1rB)ea4*j1pt`5e']:4$s.V`Map=h!kr`\WUZ0484R2)h$
S&cP\?k"G0`->#Z?AqA.p3`)J,f.//qb*t.p8V_N-nJ&cD!#u<oF6RGQH'(CMt0?i)+rI,]t%.$pa/
]%!sjp+D6/X;?(#9mAefS*@8?U)t#I8X(BEO^](6M>)jK1:Ui4fjCE4s30*&Qf_c$.`tofM@"r[_]3
b&eq/aEOLbLVOrAlX&mQuY^S2fNG.">=2oItWa,'Qou@.6B;;UI4l2>`U,CX@^T\<qmI%Zc+YWteE(
J+5%?p4!\=\(j%jtBpTr(8?R0!:kNT*!&#R3&7A5p"qQl'0r#Vgg:F%VplG?0\:g/#i/r8r@in=89u
HTutiWS:#M&JB.qer[?Tchp.kTq6&L29p,D?<>lq;*%\:ApaHT?%76J2rAq\R..Dc&7\P\_UClhd\T
mG>W;D?70V'!&RgF(U?MFb@o,[t7Piu"E_Ht`OQ/0<,-P*j*M'mB!U6!i1e(S"`WS_8AeFJFDP0>9h
H3!iK'R:4KM$,"44pCgn:6X68dZs*#`DH]nH,RJahe3M*EfQYN.D`SVaZed@b)qn?p"6cHogkeG\gQ
nYjfg.F"C0?+<XO"`Qpjmd>\5UG/6C\(Es/kM2KFTol!6BNJY(`eaC(u=[r6j74/4O\E0S6B]5]qAg
)\WmCQJ!Ogu2C<GMVn8^WPXLTO4&6UD!/$e5d4<%otMOi*H7[5nZ<>#5@#g`qh<Z73:b.$Sq5a[ps'
.B#n^OUT=rD9h!s"UQdXloq@SfjT-NDcMV1ZRR3/AAu@t/srM[qc;9nkI5f/4pfaWe,p^95]++[\R:
&5\a;+rHl6.L7[^7nWejBVB.UJ[Vi?"W"NO@C/T]Q#4'Ji@oBp0;pNrFu;-'`9Zo9jjo\TK7bB-V+;
8gJ)Wpl(/mp*4*:e"Z/fsEW;Am)e$Z")aS]MI;O^c]i]l,je>!,('3WohV-2)]PqHl\EX"^8]PZ?sF
Rd:ke\F*:c/;boX;'@_[?LN0[6KkG5hU6-"p86M=P0_%=\_L)Ve1iXk(Pb&K]s4BC@34l?b^d"?7_p
"no0s_9TK?P%MG+_Es2UjQXZ;-VOG.6;p6AiC/1hkA`9j>XL`u&:p!fNITUle,&dV(J]4:h/cSbq8l
kM?">"AY3ZHnEZ+pY<[USaUt$m6CV!:*8N3;6=@`oqQ>%`rK,U<,a=TG?L<*<baV8.&"uoE?V2u3KN
\fQi`;KB44qCT=P1*4scND"9+9#4?_eZ@E,)9>T;B93i/*HlkG!.P!r<h.Y4?@5::UMoHNd+TX,p^1
702`TDS!/aV^s(0?o#X#ml7PZXjJadrTS?*.1Z'/aMO=4kfDTF$$4<qB84)`LM;ERHJb<T3M0-I>a*
)E(2$PajEkO+@IV0=W2"eU2PftU7uNn^B5r`OqQ/P5[Kfk7DTGI!]P_pZ(Yl%,DjEI3u%0t[`])9aD
,KLZXuKq%*4*g-DN\UD+l41jUE`;54Q$BOiErr.afQ$-qA*T%Q>9AaLQ(P\6#&A(eLA<0J`P&LT$IJ
69++FBrM82j>W^@LJ,M-Y9(KjOl@h0c@hL7SI>;b`g_ag\W%rI`DJ5j7gu3"i3aO+M\/+?3]3O&QS9
h@p_Ni=q]CfF&3IH*L*nneNDQbo_HM9bjZSA02kW;n*!k>@kCSBqb&f6>immP,M.+Yr#We`r#[ehXA
L[M&f#q]*OW_*-<jYpo(IcOZ;inlB+;1IG&)=q`s87pJiY"N$P.A#$='sr?=Y((s3aR%_O]VQTpWqF
!,$h?Y"'@IS;kJM\eXG#t7@tWP^<`C)64[I)9a1\W)Q5[N4>\I.(<1o:%-&5'AL=-I4A!(,:ZsFsl?
f4k^^Qf!hqHc?Y=i''K]jOV8p7WD+;BB'rgI?B`oki"0$1]tQ<=t8-n8]B6aiXECe:'u#XDqPf*oHB
kFUD`qeC8a$JLf2Q&Gr]]=*:D"k);=I\-B3@GmT85^n;8`T?:a"_EAp7VM^p*Ys5"<Ts>N-KqBrb))
p]l-)1C?k=fJc]TlCO_@<'Ie^d(=*MK<oYqos!'iE#Jk!'0.&[h(f;=WSIiu80_8!9q'U)0WDS\uj#
<"\5*6W=b1F&SJfpRFYHisUQAP1DSJAO`(>ieL/$BF*h=BYqN(3$mKL'I)&]BPpc>=La7WRMXiid@`
k;kJ?npV1*:EBOOdb+JY.DK%9lNIdL*DJ-rZWHs1W_(2SWp[1,@Wsgc,4ak5U[B6p@A^7[1e8o*ZGA
%gTFbo-*a82`E?UOJ%&jD(G,_rUWckUG8mXZ=1*NmVf,YVA)+;C1L>n8YL!g-aM0@V(/V@ap4*\g*"
HuqH!mk_!rVkfa*#_8sp1t*<+M:ih*a][:Gq75`kF)aVqWM-$A0PtHg9g(',e>+AFf')95b8eoV4?]
t9"OW5l$j\bN9^D,/kQu^3):d?J)sFu,Pl7ssIQ9ec4]2f'AL>`n<cm=(?596q@3jbVL&:OiO0?ACa
<ZNEHNs0+gZTQ$$hMdS$EV*KYfG+0qSBpa)BObW).n62Q_+$+0#XkUn^rh5,Xb+e=IcuV>;F0V[fd0
^WWrW=-0PjE1rOBm0&XU^r5.`M<"0$5\:>QRS-1YV4kF8!=\EEp,7J#$VAO]^bSd7^k`&d^!06[@O2
#td/SeupVBT2gW=_5]6,S,3R>%23;4:cmPXQZ'</P1M5&tWV'ocXAI_\@%Kc4=CN(bPYf>%=Ya8anD
s7uX]ortbbhA?p6AkE,4OK^VSc$\Yd44.ME358-?N>[:<c!d_e@5C2I@pOpn[W2mM.E9$)gJRK2Sq`
@."m(1Of9-02OoF:4\p$(S#7c7gj"+ctR[L%1)[RW8A&Jc'V"9PZeKeWpB4#FY+7is6&[S$iaj?VL-
qE`dI&/ONL+*9`DoT(q@(@qo]Qr5'rQ0[_NLPXS"&rH2O-P)f/+%"Il+m;@8os!\PdHcu=Y\QJ`mL0
R0esG8)"bZAQE7iL%cg]QFKa;QLS2RR]EP9_^eZY;E[R%$N#:A]&taSif?W2b9Q:<k^aJnK@LpT!eL
mn6=.0u(DjVBH9HS?_1qH@rJpQ+s/!RD51lb92Sc+-:(NW</`^W93J:YWLUc#d'$?^W!\eI>,\aMd(
*jR=hO@WV.?<k5DehN:\b/C=[TD\5-OkN"s]uD:Yl?6cc_.#`mZ>mE(GbQBmWbM[c<(AS,g`UC<MM4
X*5")3rfb/>ho1?BCqC?f)(^60+%+Kn8B7JLVo]A<N+dhe_g;q&_&pL>U$4/r4%:1fFK$0VcWuFQM#
"$sT;Lg$_!&ct>cDA.ERH^hJFX>$W`2f&8MaB`$Q8qjdiD_3>P\(:1lLBq:41sm14WD%bd/`0TU!Um
ME9i.;hYr:[OH=/k\r&?03r6f@iD\(j7)8sJK/jfCgqgA+Zk#7WkYWUYD=GY;2AD?pjClHO+(^*L+O
6.0q$>rZ=^Wla:\mS[=Bo/%(W0ru`XBI1KF<r\%K`NO+7S<:cbeuO8O-gGX1Ea1&!nD"*oRJXPVFDG
V,C9_nMf?S'OPQd7J6_3"h@VIOJF7MDaa0<4gcd.C05$U'IY9U%)N4q$^Z$ii8+e/:jW=RX)I$1m6i
*NZAr)+@&as.kqJ^fWi^%=Xn'J8B;/?..-!@R1E+,ua;lEO4/MrSO@>1]?-(r6_L;B"o-Rub)l5iYJ
9T;pJb>+hkUXkM98QYY>r]ThS&3-;SVS<@f+T1^oR8Zujboa<B;u2%C1EnR+6II\oRa?0(0!T8^1&H
i^dQ`&]V<7oJM3,t#4#YM@.]R;#_"%P0'N>$jepAO`50%]<a'/:VjPsXP8AB`8#=5p1;CoRIdO1[gj
@Yia](lY1l*iODIEcJ&`fq>;NU(G=IX<%Z=TKZHA=6FNW1GgM\3:)=lT<*rHnS>RBQY<;`f/p@BDj.
2$YM+rTXRa"Piu`I_6Ok1M^%9[$1cKQ@G3*C]l_pd%A9?%Gr?X.(/^@%cGN1c";Lj##hqj2.,nRqrB
QfC203ddXBmn55LD<1LmD?&B$g>frtmIfd[%G#nTGD2ebr$]O5,e_#tlM]sLgZ8#.CFWhqIh@janq%
m@GtO2#\<ftt6"KF#nqD&1-qOY;lRU/Fo'iaP<<,Zjb6N<gV69dToLeWG`7m("DQhR`pZQI9lA9;qe
5PS9?L!^a-qi-DY:=?3V-&C*N]$c]W3q_:fu!=k1sY-;nIPc^paZaiXY`gbFL0q9@43E`ljdYZpPn_
>Ia/[3:?g=YhM8Y/"^T8T<IZTI;N5baVo`k?#PPee/uhaMu\YOUh5Mf6=N<3@Cael);]W2ck&:f*]D
C6iZ=36o82NOpd)^F??r;CeoB%PSoK?>#!Ce:B<1dS:R";Z8WE;$,]HOAQ,P/"Df;2BK7poFIa\'1*
EXJ&o^b5\XN"pDq)DN#@7NZ]\K%5^\eH2Idm6.?p$haoG1fB]ko2^rhS1fEG!"r.&+K`ngmrj>i@iH
Fqs:P:gd1+K^c7%0sht%&3;-cB?p&.4$.P>h;!V!%7]g4Fcd]D8.W?CE.=A&-9bH0eMGQ<Hm9-j>T=
OSrW6p?b:T!2(U0L2P.cMq6:kNs,7@Opm2hN=ZX-gdEDfr$]kRGFC`b+h&&j3WW8aAB:B-]Z#p?]O$
I&@B&]ojb*R%qn,G/\NY"$GV#6TVLa,Fj=BoibkajlfMUd!q+T\]gmHU+,MeR(rAJWM$BNKQD^mf6_
JOa19+k<&3C`<ppF7.R;hOqbQJ(1SJl+&,Y`glh/@gtIJ_9<24a$OZR@@aK;N([Wq8<K<[1'%CIrr)
#q7+9Up?jK\ccM+?(f#reN-KCDUPJ2EYq>4Ak0JE:pP*^I)s5$1(g,.9>+(-1cBE]X*mDf-.#XTA5E
(^s[&7>:NX_6pf[r4>1!RC6NEZk\n`p3*i]m*sG?O$g*0S,%\,e(f#ee2%8J9nd+?q*hVk7YiIEo;W
M4+HuRB\Y<%c+<ZMo27t>A:"PA^GF;JmS7B:aTOlGm+.Af&\-F`dN(R"W%c_?8aIR78':2NnHMYmg(
-_INA-W[YnaeMfmVh?KNY5a5-X+sT3Q*'EGA:k=*he>aXrF]7#]XY98ne:A)cWThm`n1'*%O+Rs+0]
"!&F;A4tJ8.pHLs0_!r=@lN:)%Il]93,!\.]hHcVQEp4W-pMihhOf2]55\o)dB^>#(8at0^*>HkkQd
s29@FPa,N7>=p+V88c;^%k@RHEUh&HGnOqHXQQ3?'TK]O;$(`Y.p&486/:]QBm8%sb.Z!`-B&:mh"-
pU7Kg%$ULi3>C\%Oi8$qi\T22HG>$;pFpr`YSk7b(XY[UA?'NM_/$pb3C"6MJAAp\UX-Y^_AJoq?79
>PK]8eeZ5V&#n;4V/!a0QY8k?Fed!O;Ln&jTo.\u:GLPg<>h^sALiZhH".7Jm:*9AQlgY`+VV=9)@Y
G4;+$;FP31q)CXJT(\,6qh!)tt!Sk^e-AI4+q-qNOK`pUU>dcDP%K`I9FRc3/i3W2,qae#MsNQC;dU
g?\\kk$!a0Y1K*'%Q+Ul7Vtoo]KgfeGUg(!Kk1>oAh!9/s3s^&<Vlb"<,bRlZ^P^H0,;&)(-4FF2SD
>!6-?#E6'k)I;N6nf$;.-<L]igmVY#[ScM=Sn,ijs3UQ'u,8Ua/sWq2K*0@oAjXN;\a'NBsOs67B+$
;%BL%m&.:LIMI6F!W/^`9f2@BRP9G9/A6P%AOIF;$3)/Qg;a4f.U<S4'AceLYMC3)ie>T>JQ*uqr%^
Gag![lD(CW#U\eAGLU&UcR"%2Bk#fY<j+J?:\b]?=P)D6%4>LjV7o"L_<3:rD?NTM.<+gU?j<#4,,>
9NH`1Zq+DedG2G8g3[,E)@6fT&`FY[Sk,@HZtO)]_%_pqj#Z9aKLAl0SN@!SC.tBYBb>(N>_-P6SL7
X>A71PW]5jiMfaMTRumD%k/]Y<he@\H0@-PF&4FRJ3+b7C.s@O(+Dh(ER'P[+/?"1obgtU3cD`H\m7
\?bR:1lac`rR2B8P>;4Ls9KA8FGqG@EfHt2YaKt1'f^Ce&J;ONl?(.Z.>Mk@b\VRGa6[uQnoci[urM
7D$pe2."FEZX0FAoMu/Ul,JTXIe&Q6T%6:JH]l0&-+S>K_J8lpLsmu:d"CgB/Lkn+WF\!n;NApO4+J
q)eQ53>Yl03f-%K]I!#7g1EugmiBf*"_1C"chDg<r_YD_/WhXNTP-?5TGC6)maWiktkU=MDrRr@MJO
g5u1%pk%PoYQbNX34jIlT1qf/>2IJO&r-IsV$P[uPk9`uF?jU&/W=//Y5RQc*hq:aUO-j)OG(l:N3N
Feh8RPYc8cOI93n:OMPiP2^;!j"gmu&eg-.%V\b^B!mY1G8/6u\910IP"R4Ej@qR.Rle5]T3k3CSqR
2!i.eL;bm)'nDJehC+BU8)Ac`%L(0lCtI9E$X`/\KU.RGAAMZZF4bYO0CP(NQ@e/pc$&O%_dUgB9,#
&s]m)B9[(9<g;)khD)\="e4W@2pu-^o1>\!iuT=7Y>I#W`eB3Lp]o4(D>]L^p5L;I3#*31URjnZe!m
*RIPn8i'/'L,b=qM/:he[CQ#6gcS\E&$eg6Hcri0qOWDj/_EljRLmX7AfNdD7NKo4'dO87Q"@)b7pC
UVQ--?N/Gsmnm^:P1eY-:kNqhMr<?j%#sch2s=T`>>..PASRB:=@0!]F&k@$VF%'Mh"^'h(u]%[BfI
-o7pVoF_na.$H6i:5m>JbMY-)i%#kiT',?RFH6&&&=2c!WM?*lI>6[s'b1@bD"KAp%V2=D%sK2Z3-$
,_g?s$"..upVE;(V;Tn9:*_geH_d[F$g-e24?V^$6m92,CL9acQ)H8>>C55,!A9@'.sN^e$JK?1no[
:F-jD0Pl*0e2"*Z.E!#_r_V:[\!W(6Am6Dc2.9<f%ZZ!C)R2)e>NBCnZ`?&d'5u3?:G=#IN7uhH,Z.
Gabt.ki+%hL5R$%-M9)V.KMW%b2)*-W/J1t1$RYs9nVGmh8rD-<h8,G^G4dD&(3]?Z.W('a-S]DoMZ
M<\IGpJ_<1I<a+Z>s%+ZAQb6/[Ofp0u1';o!WT'TQ^%c)E&e<?2o_<!5!.b)E6Z*$6:up="mt6[)Wm
?BpXkaOm%Cec5ltS"a?%%[;:q+LI%@759r`jqm)#dP3XJ/]u#;3?:jkNk=^]!4if,BC$E;ln2NWjYV
"Qn<RFK!>9';Nb8LMd/<7@h%4PL;r133SE.X'&DZf:4KoOMB@\OJi0e@7.f*%?(>j37*G=H$<rH&#!
!7HFqH*)iJ(n56lPlF`!dt\i9baR^r97pPFq1.tU^7.dcZ^M5VNO@uiBVnV^;VHp?,FaWN+M&N"_F0
RK!&<@bG#Xe8J:V&Jd7a"#BsHIK_E;dpq>"VH0!rGFBL7=-q;gAlK`PDN/],):";K'hIk_on+bdgkE
i)B2oRYaD75(*m-b]'9peH!3>s0YR1WCg1Sk]Apms:RptPi?&LE-@*#%m3+VFglO9Iq)&<04oF@YPK
cp;1UT6l#?GU<PD<"8<1@tB@4$,jp.9*I=dOi0kU,B2+kY1,G##YZ(^#+2`Vi:U!Y/<Wg8j,UpjrVP
l%Po/6#NnCS8qW!Xn30(ruHA+d?<.+b!/-TnEKl"pT?]>pWI=06m",6(LA3`.J:"[^KdlFh9@.ie&i
s;m+Ot\>T'S;<!p6!(TW.k2.bD`]D$>))sD#f@+4ak,-kae*+_\&*)T,-%i<C]Pd+/X@k!J&El2'j%
LZZa>(@%joB5]j7f.MR/*%HU^Af`>4>5[jh#`8&m"K?\PZD=]M<IkqT5/!q,']Y8tA53OQQLN4&5\I
":b?GGK=Zejdc)d&1[[=m)"g=*\R+).#Q<,c4(GQ\Z$07QO;Oq7g[k^]>"Jr(BH=3*1Z^G<(m\CaDO
X=RME.N>`(ZDNS6Wk*hlS0+m"(-*FLT_pSf@f`t_3Hc0a[hZOPdE&$BaH7/@'@JA[l8+u6o,[X"KC0
EYI\*?D+Lo_8dGa2"N]aOiF%0N?+-n%S(aI2EIW<chk%V/O5<J4Qh5p--$ueslT:oGa=H=WlmD)W*;
dkR&8lDC4OOG"*VSI;,%0>8X/4O8$QICYR&!ht'IE!&/(9loYT^+#'OWZe=p6K)u;ZX<fZr_gZYn,E
Ln8jXQmb;Y%&X.AMn/t!=+2G0hCYOi)TUPDU\`F:-cXOqI86-Buj^?[.hY+VBa&'jf\ea@/FaB#]cJ
d]%ikQV,U0[nW"k3bibOU]V'EVU^&KZdre1ZTt4.D77!%t*'-M-AaPaB?$bW!^6M0\fS\jfTu!'gNU
6pXeR;Y3I>an1nJ''t3&Qrh<"R>JrpE)C=eiV4Jt-c".<b]j[hH^=$bj<qZf=&$qh['o\mfE3Rrd^/
NaS%?B/rHJ;@Da+C?#2c&T/_sZFh'"]m;.df=A];e[FU:-2]&=tG)_@b9cJi/]AR\en#Y^1E*O`G&S
/BU@0V7K3<6L-78+qO+Df>*bG,nq2<?pOLi*\^\D60:h;_jsff-5F5llS^J\s2Z6`eTEU6qP(&UF8!
,,1LJ]+kGsg0<`$&g4K-sYIo2>WMasi?YJUQdh]&4P+(Z<,T%RfQl8Hs9"R.^%>U;+$=/H/e9hQ_kS
FRn+C=u('I1B"2Cd],+9.R9YUf_;TAOGQkQ(]l<Sr#XU*Y^IoYi89n:+T.R?NnF;2V(oXCMU99%G/_
FsE@D(U%+3_kT8GU$!Y&gT)ehRiG9*#cW,rC'TW6gjBaj/:F\o1k[m=i!DsVC=`)9T.lB1Q/@c(.UQ
?>(E5EFITu*3)$i8G^+d\"3<34%!-nskPOk),n2!,IEiqth/f"0MJGu=]%Mg4>@eb)PK-S%11#8Sd*
^+m=9,61iH+?t6(Q91LApn^%<HAjg1%Pd4!"3g:">#5$`uD$o/oeufiNn%Kr-HR:\m/[C80oAW?CMP
J8T<c=30%Bh`0`o(8;Nl.=3bi;ORf?SJX.cPVi"C0fIdM@<QU2aA-2-Tj?81sWhH*2i(/@FD+Q;a*S
>"V#qh9iJdU5S,s,ft<7MZ#+Og6H_2@d3aZo_i+b%f*fO!]hZbkI^i5@dV>@Yk`S1klM8oS=eFV_.g
-"M[n_,>!G==8.7X$?:Ac*(^QFH5?^:soT(]Ep5B]62`t"eR6"P4/'9YH'@dAYf3Qn_1h9*ZFHAoQb
F<JqTkpOjH2B>a@OuT`foQbRIb1=B<h:m/F`XL;khd#EZe;_otAsChG%8@)q>BJ^^>JJE&f9&I&BrE
XTSa[)<63/&HZ;jKf!TlW^W*\mTuTKjpd#P7)kQkCCd$ls\)#+rBI82#<(Nf&`a*cA'>61!ZR^:DjE
#P_qSFStbDO#gijF7._NAP#e?Fb&f.hnX"5=V=0n^SeT[8p;A$j)4a!q"=$1?_2n;O:G\j_@Cd#*Q\
s*#D@C*R,l?M3@GNu5HJB'ab.P)i<<[NaTEG$>oL4*:d*?PmEUV#5NG%S2F@eY@-+<m"Pe["Zf7*R[
07c81@F3NZacX^a`fIo;`gLcobPJRg[.%+/cRd'W+=14th"9=5:M!h&8tg8)!pe2L'EF.3f;tBsN#b
;^ZS(L;_W^JVM8V2RJ4?`_qPuM@TAUR_,*<&j!&lT:5M@I9AQ#/\EoN(iQtD/MQu$'AC;u<`o)::K4
+L.ZN0:UdbuUO]Jd*CXb8ebf1EL9a==ET=c'/?]W&1.i57K.8[*p5@+is[O6mN&;)`Abp]VV't#>JY
tj+#YjYIGdM?cDk@4S<A$q?M^=NJjWQR.8PK=K<u&F4LU^5/V+)*Oj9Ne6J^oJj=WeR'kh^lcdd''j
PeP:GH8iJ/B%;TktX_a&A-u)N6hL@PV<492ed@V+Wt;CGg\dfpO9;Ok\I,QrS6NMfU'h3k!uj(.iLc
7_GeDQpk<Z#6]?<)YB-n[P4M`Ae`uO5LWc2HPliWB5t^!f)dO*&+FGu#SeVkWH9gI598Dh,6m@ekDo
LrlB#_AWZr&(=L9OH;\4f\nFtNg!\#h`':_6f&;=]u+VTftrrpjc"HeIO),d%=%88Ne@D8cAbQqUXh
ueRS)@Uk!H6D.@W1[%Gb;hVR[E.6O`&h-q8h)Pm:f("WMA#l]P5aD197]M`rq$eb"P"&W)'A?Gbg[`
ZGJ@)E5+a%_V[.rF*n=9ujnSO1dUtOt<el(u,0:+.TMSHen!-W?TA9!,H#"Xt+(nAYf>?cuA]a4sdh
i!t;''Q787C-=0B-5](IDtklQ2jeci<E:YRZ#$Ol9'>;8&WRi8YFPEk'>tB/*kG"(8YT+McW]'c</c
b9q=];2eKn'Aq\3!o@_/*4YXV"i97hCId9JpJ6)lgP::mPY?8f3W%I(/$OO`<ln2'nES)2lW7\qTDp
To"1KfcP8L?b1#a@se^_,c\+Sru]IYa9i"A1/V\e[S6+-b72UQ!nN&I@Lm/Ru4&o#L"RL;Hs@eYFW]
j</lO='iIEYdp4Woc_LcsNsUPuI5a*]f@d^5;I1,aJd0o/KpZR.?8LNX_*SnH.:/+_HK8Ci4D9@ok4
<chu'<BS0Nuf0H7A$om""H$o2Im0qUPV%jQ[>$ANlI0=!i;09gb!k>SAe]M*/B-.KQ!dUM%)rDGUFF
oq^S[+nhXMu*acsG_n`'DS%^J<>,b*g=IE5`8b_1Lt;>4k)-7a/m=fMPRGdtI7@F25hrYe@@b)\TqL
*Ql`-M"VDV^t>d`5!8_<L=;/Y#R-X/n",6#$NAGfDT44X6OeLC*QuhGd:NMLp)g5c*c#3(,Dq7SOOe
Kp7=(8))#94]\eo_k+r7:*2M>K.s82\#_C8%JHC4Fs*aXSY=)8LXDhAL2AL'4DU<FYVaGIbX]QC,gS
7RcL&6AiDTnpu3cs7dkK"5IJg(#1*O-V3X&(k%K_M.]#4)-tL=LLDeH8<&AQ3-E9"I*_=I[,Kj"?qo
)M+rK-DsUU0>=Bu9X,HM'?\`a8A[9=T%-BD3RN)dA>nabHn9im^j5do9T2:.$mNt)SbRQc[>[ElBP.
#0ENZQt[@)/$jVf+ks&.l[egjj&f^]_K%,]O*Zl$:)gCh[lGrL(":HOcQU1urJ/4:pAt1D4W?EV_Xm
[ZRr3WP=Xn3;a]la/UQY\Yo:o]>X-D^fm-Ori/KIUCs;Ti>@,:7SnOo(Y'mq)AOd-TID>l![k<K-FD
_8#8Q$V^Q:KF2^4VIAN5$F@e9;d.uE8918Aa/=OnKtf]&OP(+ASe?G6t9,HI-9Ul_6Z^^D+<Z_balP
Thq\:f:GslB)Ef4AADgFC`_X?c\/5'9'AUf5qquGI_dA]C%kejlY$IQ.ut\6u9nt>10`a?G(T&`Jhd
X^?IYm;FZAfo#pmQD1D#*g?gss6g8"V$OS\oF+To#B;\lBF2LSoE<=iaJ=D/$5<1XuqaMKn3e;KbS_
TkYU5Yh-4sLFa/_)e$)WiY*HXV-*pKh\$P&%TdU#:s0q'$g`kB589'.>f,m3b.kK\<hP4n[3`0"54u
H8<cL\bX0-$kZGXTXGkQ`?lSnNKQ"K"<=oI[`%*%@`%]4Q'TX2D>j6HZ4*]UpOr+6-1Nsub\?aL`p/
bI&@a=6+M6EQmp\q#gfHs@D27=Fp)S`mQ\>mTISQHJKK[ZBe-&U<):JrQN[H?7S&mV'Ib,\AfB3<kd
\`DsGm>,OfiRpo5MYafYM\$adbE4$.n;lRKPu3B*_)V9$,MA:c5$#lRR4tM[g)skW)Y,%[Jtqma$i>
jWJu(R)1`K(>`aNr&OIt;B6qO50W9l5HV^6E[!G&Nr4k#J/*&rK_ng@Fb0R:OGDJgFM&3%V[JH<K=a
AI*;kO$AmU*VH!+B32N-J!5UhP.%#!i`l,&oUt^N*2i0TPrY!A4F+#P:Ee;AO?t-J>m^5C7hqQ987U
*#E2*R>(GS-`S-1"_thiVA1OlPZ02NV=cu76hno;_2M;!k.K(!f+S-!=H1tN`0(7hY>BVRZp2t$H1C
!EBQGAtXCp&#>f0`K\eme-jYR0-,)\fJ4l_f]=_V8Oh*&i26jo)oMj_`[\E5WCl*QQA]$?4[R:X:A&
kYeP-XVm7jHTt\+eZ$<FblIK5A*Gh'"4Zg*dZ4Qmd\I#?!C%4A<N``#DVHQU=c#`OWKj<QWgu9<V1<
.8q=ul8k*m"4`InP6YcI_M.7_k/%N;$XF(uhMI,S'i=BH%$521DI'-1Wk?o?6G+'B]MS$%<%eW0-/.
&^6e6\@B6Le#WX8FF]PWp;n"_G^]EbM,=$:b6qE%5<(*f[[+C?\Ro%7q#t+K7qPr.iE,T1aK^Mja`h
g\g0H6*cR*BV9ru3ZS%ggi&O+C=@1,#ofI.U8qK*@js_Hc(=7B?/eC)OuA=MAS%)c?1%jqke.51hK`
dif8k=s!I(ac8%d[pQ`PUZ`^5n-()2]TD"iKS^uZAiBr1P^*BSMU?M+&F%Re]qZ1sC3iM6m9_qEKrO
Hf*#?,.^"!em$*p9oD]^Tj0r:oP"_6RW2p03T^_l>l%LV,)r5K:GX,5qfK&!`Mf0ct#/Q^TT'/R6IA
WN#H<@?5-cP=tRZ2/=C"28,oB?_&6WXdmtKm$dOhV?JMd.U;uR;-O_6;\o3'=(A:#O4Z_7g0jj+f.^
g<^f^%Z&a7bIPB619"b",un/2kVjY9!@2a,aL/@CMnNCpuLp=C?p%ECu/WM<IH3\QDJNV]bgf?AO.q
=a^TU*7Te.@eS"YB^"t!E^"+5\,Z$7QbW5>::oipc<S-kqhr4;rNH4p,NshK#:'aXB%3`o6K8i+\jk
u8KeSH:OO&$5.;n"CN!+!M'P09B3N[>.dUu6*nD0`+k1bYC<M8f4SET9W*M/?1c]nX-?@-=g^.9Z3R
ppP98jT%KT#O[UKWd3O,o`qhYJ4r"p\oHU^4URPS40<+65WB]2?K!pY]X`dfEOhR9aKsF=Tj\f$5%$
(%iUdH4^jOFE8XPUK8*JUbnF*Ki_6GriB/16Ch2]6]cU'Fk[,,!2@UNA%U`@FKP8CAFb%n4)F01:D_
(73'B886'iVU1XPrRiQ@pL]U0\W,VCg>c.kA]eYY;OZ.ATMh3dO4Bbjk`:I.!5`,R\D.P3NB\YoqKJ
V%>=t$e);lr%ogh(+ad5nc=7W/p+OG?l<9$71O;BN"F.ZL1./=Y%9`4a"csX9HA#Y:oNb?9$!Gl,Ud
1Jg]kXN:#H]']e!RVX<'1CZ%NB.Qa'b&C0uOk@aee*?mmHQb'.:E_7?PHa=E;?m&sum5:gTu,EV21<
[>7t>`K!s(C3Qnm:K1\_C-`=RanHJ<C$O#"OJh?'^74m'mi,<m1`3g(q^ZT;uWL)0,J#MK(@O^nDt)
A0(SWn3^s@iCOgHXT8*Q83uFLB)OTFIT@+`Np;`9uV)44J;jm&J-19eRY$hT`i#Z:6OXGa4H;K<>j=
YU$PsPp:W1Ysb.O]eu*SY`*JLq`A4X,k8PZ=19Ht3/8Dp2?&oHqj:aA.Q)QUT'2Nd`u"2f1RhA*7"1
2<l].A5ir01T2/s\!*Kcg$%_fa*&Sa&05r!l]ImZ-hfUEGQbunY9L%]77!@7?jLe4SVoDbd'/%>J-]
QQ`9L>)>I$"_&ICm$EQaZ3Q?$)<-Vn+'^:i[CHP]gKRBL"0\94\h$bAe9Ar:W77?>;ZHs$JBkihBjZ
1ABmeu97!W%(*u!rncJ1WEE:3)rmu07msok!iJ1DDqcr98^cU3O:T$_1rR/-."tW,p=8*nSJCIKc*C
>lri^ABa7/aj%)(ABdJRO/$)m\=p].;kN?Cl(;rE?\]apM(N-p*TnB\+%<!,(#3:/[q[\1^3A:CrBQ
E)qHC-K3=H\:>A@>7"0H8Bcd"+bZmRjA3!'N[<U:`%$1>:o'3EHdMIY[4o"n/1rWB*1"WNnX!>%PON
D]XQu)uV)r.PB)GfA8PFIsr92>5aXJN0m%,>ISI27%+d[*#&(QB:MX(-l+5mJ,\TD\CUYG+)Q=:__D
^!$Rs:J#9X"ALe.^)L*E8"r]m:0S&%PoP<f4&1ZJgZRj2PADbk74Ic<[,?<2\%oZE85`/g]Cor&Y+^
ahD4Z(u;P/B`ls!K(aS0EBaRB?rGfiJWkuHK::t3nZf4;;QQ81qMAmfPQ)&@PMTT%j3k/^qGX,P"%(
I?N:lfnW*;a+DhN4"M-W[6'4-fT@$Q^jBicT`6.uR0es?c">CXSgk%ApJ_k&a/OWO2+]&[@H-;Hd3]
S"r8R5i6!j=A(nR<<D)ncfC.^.HX!48I5BO,a?fRPQUddh'tO[YAMEF%CAS[m)ipBtTg/;X7)<03NK
)6DZ-\$ioL&&Oa[h*ZKuC,pH*ZIpSPl@-?3'>UC/UpK9Q:/A]&Ambc5=eLWr>JW'!po"FBXSr;LTYV
8[es&C^7Q.jS9NO[V;ijjb_a@`5o`XO>5K/9<YMcDN8HR22i`hrUc0jG7=3-XbigA<Y?ZsOuhAo9(N
)t;d1`)Ap-JhQf3h>Zp>3`99`2]`QA&sO#Ed?0<il!2\3XXKt)bJb@NDP=$K5%murgAc/mQ7Y$qP?6
7<t#U2?_-W]r;9V4XuoZ_iH9lejCI>L>p6.(Rdhp'MjE>F^GsTi,31!tQ/!>Yno*Dnf-0mgVBe8>I-
!6l!l;tAB:_00"3@[^C5mSFU^J:epfA,$SG'bV.EG.Lf%Vg`VPT.`"IWr5eD8k"_dO`0<unI<RH[:f
gqeq0C,F;bc)/@gLG-/Yce8!WkCH@I.9ArXm]%h#FeBor#:/UdRcS%E0NL="fDAcJfk#jc*<1i(hD3
iKZ*q@]V-](/2Wl'5j)NQt/;<R#n*8^<a&0[XGR"K!cCIm[b;sFPQ4d<m:iEtW@]`q@#&kr^QNj0o8
O(cVj^8Rsk"L\<oamV68A[+*=9KjFan<-grV0mqcT\rK*iH\F)ZSCC8!%?%WWG:L&a=BuB2+<Epk6:
fiKu;#_W^(]IR$`6kX%+)rW,/aH;T-+A$AW\-]!:U=fEh1E<k7.kla2Wo]lt)=aVM:3)kZKdda1-3+
=s1`#lFZSaPS"UqgKUS,5)-(Tnamoga49L[ulhDEW0;J[<q_<^uo7#`YEf#V_<%+@+:C7l^JoFa/][
D%LK!CtR9.,5ES\4]Tr6cPn$8.Wp$,f\QD)^NnW`hH3Om8YW($@YIf"Kn8O,[bI3^X@1dAAk(U@^k)
jp^.<=$oH^qDp-R(3Md@c,2-Lb*2WR\^gpm0uKD.$UA?u2d%/'84n8BL._B/Co-#LnGFml[TrmP8)N
29HbK$.7kNn%"[3)ouBc3m'fe,jn\8YLftPOY)k@deEGpEATJE*@VP.6U!K5i2ip=!Fo?i6YY2!F@a
W^ogX1UjD!KaDD8;ZfYt5S9Lq]$1(^!:*;?cbe2CCj_t4]k%0dA9NFX>?MfL4f45#s:<0^U:QcsL,:
WkKZ5K#VMaSV?7]O4D,_U/5+@Z'h,"&Zh'adQNOo&[iMeaQ"!@>4l9*%'2T4&G`&KDc?=mtXfkjGHj
3^(4)d(F8rMT.nm=2:_eMpX<.'TJoT/71*h\hr$Y1ACcq0=jPXAJNl`4cOFm?j^&cm;nM"'QgdVTE2
=>6mF\+kZ`4+qo<lm\$5iG1'./a;Hk?pQC@@7P1;Xok)B(*B,0ToAkl`?`Mi+Spm4)B_'AV+]lJX56
6;HqTtN+.jZh8MLlRj]KBaD*TG<C.#ppnZ$)';'k"IRW`\Gl'(LS%g8Nf3=qYcLa"FhgP8C&.--XWY
LlS$tg/T!Y<a4En0bRB"'dN7`dba$)L'eWl.mr^tX7J73C8^)4Bb/)Z'"[5BHBO@=gkHS%g[?$LWih
dWC+YC0b&m.qc5+qg^3IigDe:@iE./k+e%%9$l^kgiO+Ro1!DgoG>%<CT.^U/VIJB`]BlAgtdQIFRE
f*+h`pa^-rI.0P!/7#6o@E+<J5TBeR3ZnL$3g3JU@>9bOG]VE[1HtQde_gDC-:^0m(l31ahn!6A,rd
S:?(#9Tf_hupPZ48m;Z)kpj4#ss6*h\ASh/:8f-j%`GjL.d*o95`=9]?^lk!VKHS&B*JOLHtKt9qX3
t[rpYQ+1_B0W^XB3ab?XG>Am*Y(RGQPAKfqG_(XR-Jm^eN_^1X&mTH.*k8%nbJOF_Y/dE@NgbMJ;ID
aq[r?g#drYU<ti/V+ecl,q22F0+D(q""7XAjCc[,H#K//!XRuIV?gN:((C*J^cqEb33DK]TF,uVW!s
4Vi'O!-.D7qa&(WPcsjQ+Si]JAE:d0rXcmKp[d9>M&r9\[7a(,[+\D)-ag9qC$_ePIfoVrBTU.3`S]
aARu!R)488gc?gBKb_W[D).5?#49B4Cs9d>J4i6acpoE07I1E2MGOJ:U+Df^;LsF'!*X3iC]DD>PLG
1;kXDfiO>$kYfm<i<KM/\DR+6amc<)EX=PaIT?4O<*k]L=[euY)#%Ni6S+(pfK\q9I7"Ucs#?CfrQ&
&["6"@,cR'3tdOXQ6;lQFXkD"RITE$NiF\AV/]n(o[;JYPb<>T#="cN0$:n&l`P<+r_GQJl3_6JY;#
-F#86cE8Ms;b<D8B,U)BAg>cPgih+U>9HOj<:m)q0W^!kJb*nK!]8Bk*$G='/aGMJ#;e]#%+dYM]'-
2dB*EWMg_FP.ZIB'k&jP#RLc?g(>^Z!C6hoKb5g"W3kID4c$k23Cgk/+9_CNa<)7<TT21/d1UqHJCE
dPF,BN<h_$4oqJ(4^\''#RW&S>W#^t14V8Zeb&7N2`<!ZrQsMLe%(s]T<RU3q%`r<+gea5"&!e1o]*
ub&R4/>e_`=L9@DVI9:c]$Dd`,f>s&;X'^i=(aUSZ4<T.51ce`]clkGqY8>AY*CHsfleekYiYRj-29
/F=W._oYpX)Hn%n!or^b-9*\;nR?PKjG>E*J"*>Tb3o/Ul*&%8Pk46\nIk1.rH1foZg`TnHe(C79N%
6fr5biT6>'"9-Hi(Jj0XB/Tt5-lUMn)/CM#(&7.Y"@#j6&RP7`/JOI4%c;:R3M\_QWc6mN+hY/tgeA
agli&fT7hL0$DII/.**28XG3[=9*N.&]I"utMe!BMKV+S$p_&qZ3,NX`3`g8k(hO=b,_OAO6$a9+Ap
THGmJ.1qD4*6fHd`c2ar-'5]eoBdd;p\8LA"_'tb;FKSICiG8sZH0ZSAQ3YSLniMjo>]i/pP$T^J,f
?YYJ5AHq`iejLnSB+OHk]bLO`X,(BYhF)+R4m^M>Oon,g+C=h:\I*%)0o`p"!hlqJ0/4(&ZcNdpV4c
Pp#G1>+"u[DG:b&8Kn,1`d/53,YWB$Rdgs`G,GUjfs#H=Zqj3O`E^;"&Gdi5./WE].`_/]3JZXC+eo
+<J0X),WbWX'LG$jO*bPVd3Je#VPY\GEtb6DU%+5&["h5/VCo_j.l&nYm#h^\bmhFm]fJ1ZOJ`>>=_
<X62nj]o\-625,gm*oPR-qsqajmtN#pEYFuC!Q"I'PqK39W2".pfC5BWIek#Z^>-Qm,tM]</Dm6D7_
B8#4Y$]!g>rZXHe)?c50YP!.HjPPt_/>Tg_qo%T8DQ5Vt;k.e:78sY*K7>F[rqZAb?MPkLM^;'tg=i
JM3!t#e*=R/p6&:]\JDUb(ncoeH)9tHUJcU'<i5+UjItRYFZ)BfO`#Qa#X>_poD=rmJc;,K#r5P=Za
,^_VC*T'Q:tj;Aldd"s%(dPWF$2aXj8%[3`+(*icK$`scjR8s8ZI6!f8sLP1XoJB*6%Z9oDhW?LhPf
+^q+$&^UW7a\IE1";mC^9Un)Wg"j\f,\$p/lr[&:`c<5F\hUp<=HCH`rGJ*Is@FSj"VZJ'[IV2t0.L
ciJY]%?;AId7D&N7kk7#*5>)1_1dF)>sAO7D/4Ye(,D=cG9k&qV<i(KZ3,N+0ZO1psd#V1/IT;m\gP
%U<OJ<?XjB11D(#a5O3qJ)i?B_VT_(NZ;c+l:A;T=)p^6"mabjIcnN$o_o.N&tK)>1lmASqXAM.:+_
/A(["7gVf\U/$Q#%3;NC?@'c.hC?[-jg"^_K`!k8'V-Z5AL22!kQ2B!XV0M>)&LeqL<"R8?Jm+<tM!
"Mb+#p,._I0g'^f3bfGj*:HR0AVB%75RXg<HEt:Kn[qOK-+u[qq\"Y=?.:n8lUgZ0E@,Uc.OG7?Ge<
m8:$`'<ET[<\)_:5TRh,o12D1ZFJ%DuWZC./3K0u<4:lVJ))N)Xs1lJBE#8/*Q8#NX9bHT/._@l-(a
dDFUP)sN-1Bs0Ep["ZqqV5Gf,qbCrHqt(!El1/cm/;g#X[f9$M$-M=#V&(f*#AMo0GRHgdn2ON>hr6
r4rn&et;D].`!+!mjR6u"&(/Z"mf^;Eh`hX1$fH7/EMGU"$hModlV7=AA4dCL$H;^.^TGRJbX;3GrE
!MpK\0G^4d&(,c)&]s8Aj"XjL;qbW+T>JgJH$bS12o9?l:td9$4"e)Kul*OrH+07.`)9b>cgfFaNF"
gjQFLd]!@0uW:5MEH7`#8b:"j"[76UK:gW17U&YF&VEg@PPYSKDHQ.!=0#b*5JJjo`;nO_=*#ff0qV
4#94\KMj)OA5T0Iq;IbL$BKsa<:7\TAh=#t8`o$WUkG3F14nr/ZTHX6"*=VdVi,O@ua>[L[r.9Os9b
\9M1Q6o8jO;;Q"G3;DnjuYS^F(uZK7\u]SYV52gR#<m*]lRTXka(d3&Eb4`Lj*!Mck3b-n*e:B@>W9
50Ng^Mk)r,'KOU=]:=`5RnXT]$'H*j'_bW-5cFR%E--W]$PG&kLQI<uE:247?i0)FZUY%NLAE1HUcO
[eT=X"4%FZ-Q1*-RF@<$1Z`eCu6kFF4LZMj.9G!Vp&[pg1e5pc`.D^]Vp?t=/lZR$IQcq',i&>Mack
5@Xl0Y,6h+Sqaue'RdP-)G:.Me&3Gc8AW_7Q_em,gDg*!<jem,*E7#,R>LmDDQ?G+V9AG1Q+"d@L@8
8J\%00(uC4>-<r`!;=J)kG_N=Xp!DYY7+k[*q?<A-8]0,]R0>XL+5^$rGHM[Mq5Q%*erZ':W3"4l71
^e^&;5S#?TioZY;oXH"cV7ZI.WO9-r7n%gPTKn[PWmS!m.3#ZjFoF0HJ3[Y2p5(4pXM8h/4!1@9u"7
Xt93,4YbnKJ+9siCM%#fe34lm-lB"?:5U,8<Yn-Dm*?Nd@6?uP95PPQ<^+SYNhRlXIS98Zo?(sf_Ud
X1N!]_+Be:OP.#:7#\c)64&.gG<i,ETohu<%u'B@]]+Oi?WO$Mlc#a!,b$9:ti`a0j&iV;(Rs-;^i4
MdlPJ,T+s\`.$*0da*R.eHG@4bYuaV8b-8@klK\7h>Yj<d#s7n7^nEKXP_^KmY\fII&2e'cRK2<uiZ
?F+SuN(-9Uk,-T?%lt+WeE"$jG_,'E)M#lX''W/?`=9ep.'6FHkTqIlWeIoYDU<S#A3%j!)^N0Mie[
WR2$0'4+4#0mb<"(G.dS6i,@l5^(oQ!9';Lj#*66&fXAE;kKl,KZ"(>%Ck@Q&,/*!Zgo`H7CcX?'2)
Z)Ge)(4#!`O`#`>@bECc!8r]&T#mo5_EG>loU\B$!a-PeM?^qp#^jR@$eBK1_R+#SPB_n6S3,=8PD1
4bUps^ZV\]8h#NX$_o!^Pj6%Z_ck>";39;.aNPn8:EW1a'd?MP:a7eml.N]MfAkaY!)%/QZF$5GCLK
dp9)TV)Mf1\*IQS/.K>8;F_h;pq#YmE<2XB&m`SqnIMtB]TDI-7j0FMuX,3'XTUJrGn1d*u;HES<hW
f?01]h.&MH88tm_I?ng)/)]\9CfJ?eE<0S&-k(VNm]`%G+O72b$ih8qOPq*[g8FX<sGh&:)Q4LJgck
5FUAu-h"=>igZNp@q..JED?4-?^udf>2d8HRF!;,FD$&M-mXcs[>!=TOZWh<d7DXC7V/@A=n(bkg1,
aB0*SV\WMi$;)mh@a<J.67kJVOG7afQoQ12JZ`]co.Ukn3ImJ&C>?5om"lC8@l6,=ho897RIU4X,MT
\/F$,kl6)dN-#:]6#],+YhrAb,/SSb(:-?c)GLS1C"/7A%6Eu*fQB%*'0M)nS-RY-XugbeAZO3cG@P
je#UGE]*8I3g[t:_L!j1OaM\SY-,4H+Lq&]JDS$MgiF$Z03Wrn08II\GOQs1n-@:r<hFtf`0r(qjr.
C%n[YX2D6Z*),#McGLlp`2V3fukmB@=+=<ldCO*'.LrpeB2p8?)2\7Rt<$+(+e4$o3l"u&Uj)m:<G.
mk2EJAn3>2aX78-W9.d,3&XC]b/;`(UgXY8I[>i=J"hSFg_ar&cM7$Z2*2X:qC'/<UlQ:o!n'JAH%/
9kdiKZ"@A0!>mcqn=@$#g,%Xk-n%t?/91rPIpj&@,_U3D=K88e&IAmh-"+,d)Q=,h"*faF*5p,07A9
@j`5-;Eh(Hij1%7N\(YkDp?J]1q1K(Z6oaDUND\ZXqAK.-LQmo4&5jMfQ2)aI7+hDqZg1VipnJG8pU
gb1&+#>05jB.nI$n#:1Z"%S.A%XTNc-9O[IDI\SDd#n:.Y?09Hr)@U4+r2r`\T[^@hf_i`O55dHoWO
/Fe#"]E3Calnk@Dial0i-<^ApVLLM-'A8CPk<a)N\pu&PWF8V\dJSX,t[)>k7]:kj"@Nu.Ogq`1`Gu
.h`*Xr9s"@'FknlNnhbbE_k%6N]/2;m"4G)gA[$7$MA#8UXYUSCt?SJ@.WF)+QF5@9W1h3fsk-k74o
2XnoD1lTlOc#[eUnMI%p!\$R@bk^\c[SY"akcfH$dT%%%Ns+G9#)5J#Vh.L:NoX)a6:=C8lhq's/j4
]QNf:jGQ(0BrkE1q--Wf*SQC=*n1'G:t+=1H1C&W6-&;jl=lYdeAa-_r'dSkQ"bFf(Br+0BUnhbNYE
IL8WkoUlc5ce9J;pQQt?[!Oq8Ums"^5UUA;kT)E1&$0p1['@fG6Po'g*I6`OA=4I%R.%cY,]WL+9dP
U%Ekc[mPs$VNtA^4A1E9AiG*,qg:=g"Kk"MV&S_'!M,D=sG5;Np?MuKnaYi$-G*[URoF;7l`2EapkK
baYaFd.Q,of-p;&Ke$*cqfJlop6<p;CI[5ZmjH1HVjf(IL<]hP&=SX(L42a+CQORdje30]V,<lJ8?a
$&MtJfk.Mr"!%73FmY,PL_i._UbmEbr"UdYX+.AQCYsNN:\g.'X'dtJaNrDETSkA:6o80^d7)O5(h&
T$GE*]kQm7BGluM7L,Srk=5he)$P8Fi=G_$X#K-c?k*Qm[V"d[LNbV)2$oE(LVa--7?o&RcBL[%a-O
(l/U/1)1l241n>o!t7K2)&X^[9QcH_ue]F^9SgMK)PSm"U'R8G8FA(?;>6T@?u?BUJqIeM1)DieZj-
+77:_06:I>RX'U)=i9n9kj]]N/KcCt5@T6:n$Rl(oP\<'qe>WP'_1MsWTk6C2>.D.O\m3YB2#n6aN(
N^qltT!rNF*jdk@]TJ.4;&`*Zf=XGj?Ka+F7-41$\?O4a(i:QBSeZNGic&&`>FDh(h&C@,VsB$809J
J(\`K6P!4_=tl#Z#)Sq-N)*&D@WBMc2;3%`4VYpo*TN?Pm$g/#:YEp/pUD*V5.T;S`JP^0%O_7b13)
,\ac3)+G-hHD@b(OVS3XpX(3CEKDC,hJl\7kAU/iR.I26Nq(dCLKS;\<>!2)c+>$qi_lr\FSnul.^f
$`Fd?]>YbSX*BLj?D#p;StO1!6LoZ^Z!3u5t,_>5X>Re1f.#F$?'Uqo1>$APu59L:f(i&l$Y_Vc0+8
]4Ya"?3kMF;Bm<b<7Q_A!5_BAh8i`1$qIR4H-9X&OOR+H!lN>%@fnC_$!sL![JM3Kk.@*31X$^T"6Y
S>i50GQmAE[P#2W&h$5HR7P:fU'FJI@lkhc]^3`QT=Z0WkEYWF"cAb*)'q*YcK-QE@(Bfm!qsFFr"&
?!00Zi*[*0)):isRQhYu3?PN_jE>b?$k3`-`^nWI=W$_%X_ibOV4U'9(igRNFhuGI\KNaCIaH3V6;Q
ZZZG2V(0*E/<SI>i6VegI_@1P_4Rm!NkC1TTI%MDFXeO034JY<`)0B-:PGGK3h5tnIpa4&P)18Kdu=
lCPPqZEGZqO<8P48WMULfiG`?q!L:13Rj"Uq6/7W1o`?V^<9BV\<+0Gp/eRp!:C_(S*6\[FofI"GAC
r?[g=,$cf/6;EiJ,;KLHg;?AOFTI&Me@\\D#im-m2:3O!D_&53E9$/jaO#b/K`Y1,P'48N?37Quc:0
k'BkV^hEm7g7r;)0j;Lp7C.G<f8rgfZ1\`]93EiT%oi2p8Ud"Ed65"c4!t45(oCG=k0R]X6t\],!U+
j>JV8qK`>SJL&#"infIY?NO]3AW6lpY@>iI69Ba3XQ2e6`+uX.W?o(F+>(E=!K6-e^]!^GEk7B;,uX
f^!(#/+k!8]ZD=9p4>d'3CEhKbmF2p2#VPgnV@CNo@hD&tW?kemc?&3c=BT6lS!%KZF$\JCM^sqBEc
<)69;2cFs28hK6_CH&EEG'sjUM#-*JWrr*AdWPkE3`OrXhl8&\=#Oekk`f\GAQ#R)Fq#O/YI+j't^s
s<rafic/Jp(J>EkqjhTBD;Qp*m_L9+>ZO>QSbi\b3[4mYDpJj0-8JMWL*QNGffa_YgV+HLM(eBPm81
.F*'dZ33$e6k&<jjeS$&Xn3G[?LgiuY<u'<?b>=s!.riQ+C>!6lniNkj"]@Dj>&;)fSO9n`RAb_DB/
L\jtF8Ps*d?FRE-_jCs^"S*0gdo$h,h2^o3Ph3bLpg;FN%Bc.=d$ZN6=_Hn(I8W=b"A"BC,GC#Fm*n
Ehq4J?n3h_-L$&#"2?nc/bYGCj>bkgVXkGepERZe!Rh/$O-`>qG?g*ci1'gW#bk<c37r=[H(XC+h%O
s><nU*htNE=BN*3MODe$lFN"($[q$9!*'.cNuWqTV-8]mlS2Rp60iO_o!H5#09&+[4N]b#HR<q/h#[
FMtN><=(kT&;4>h*\fId2](t0qkNj_&*<6es6&%pAFt0qe_^Hp2KEB8lXi@eYA)b<p=VroL9+o%@3.
CcLclNe.\334R=6<7J5m[c:(c$r;If)at^$r[K0e<ZnJR10MC-K$>'P-(5I-TS%[=BSE:iLH+O6tYB
B#,;g^sP6aLJ(kh!Wj,Fa2W%-bZC61?e>#BCBp#e3j8(5&S*bo,<LC(l(./'a(/"5BaEUs4rR'fI2=
eb@TiM<i9elF?[LfedUp)$H`U0hrk&$h)%^j?oib[QamGW$4X-:41ZOF/:9KE0>1/K)b,,4Z\T#8ge
,rt8ScCmkJehP\+s$6R:Tcg*WbLA)>.1h6F!)b<_!0)*bpOrC<a^Lu:J#QP+9W?2?L1)R>b=1sXsqK
LOs7jA5$74cpDldZqA"P#1R'"uh"td54a/OVp]&n"ffc!PO<3@cou.aAIe:IQ@p/Z%SGrL2[(O27@^
!AqJbKioA`s;$`qG9s&RY=6s7=n3I.dft/cnY4ja][mj^RbO!"+T.-Sp_oTPIX6)TS\.-,'9bl06ln
mll-k4?"A`-A!1m6o&>rSqRoRG.Wi"3$q$_4Oi7=$;10EbJ"@=0U@6F#ojVlHm?k(kILd;U+LYiJoq
8T$s!sZ#,`*W(0>A-EJdC/T8Z9TEMBu#Y\WtNbc0;hVKLD0m/W8jED%*neE%25.cd0FAOSdgbqG;]0
#-f@Lqh,9)h+`:Au,7BiWM]u7=S1oJjleRgakn.EgpGXTdWBoIdj&N9AT(p/-7l:`q"/To9X!DB]uS
6NC@K(^UX9'Y1=/7$]hQ9jB8AZ65t+[IIAl)fKtrgUWA*ikXgZ:!=I?OnLU\n6s"A:VHk<0DpN?Jpk
&a:j,?`PE3QPF4G$&ZZo#Tq5Xppi]hU,&gN0VpF+'WK=\64dH8(a5HWQj@%r"%I"5o;NInB1g"jn$s
OZa<YK-W!^Ueq'5J!(*JUf**Us%=CQaR&:HCi?=gW2jSo=4h[FD4mMs_k%#!ie$=24pFk!['_L-Gq@
"D]tebSc0b"4Gr+SDe##+Y%u/euM"(W\0NX;A;2dHf5mKlk6iD0,Ua"^[aR\'MLCS/OltRX5-E;gKC
r`d3Zb:DQ$]A&.qN?7lb"r(+DJ!5K[(Ir<29.WBfDc'8iMgI5TY7AF3V;N*Q9YB5ebB+SUR\asZGUZ
nrFc0%V7O6=h/X`*)1[_\pB;f@\5XD8g6if<UbGDPQm!m9S0%%5<mLm\Yh-gM%ek#+ba`W_!`8VBbM
dgms/]?l70OQ<D)dtNYXhgSef?UYgqS*ZX:fY`=mLZgTr<;mJp=(Z#RD_"0_MrdXJOS+^\`Wm>i=!S
2n";-*S_?<`4)>JgOsHV4t+p9O'YYg@qM6eh1<'e>#5fjROE:I:u/1U+1.8n(JHBZIei_VZUgeD$Y,
V:)8=`7j8,!N$m][W:W8o:X;H8:AT(t#C:_IIE+>OO)V/#INHgnOfYekZiRYdA^TW!;8foFk5ShXs5
R=FZ#j^/B5dgb,'Kbe&E$,rp+=IH5`BrpF>]C1L=aNO@2S,_u0+/3OYM!&mC`JJE=YkuOV%=GN01]a
*_gSMZCB1OF39EMR5&LIq`Lt+Cf5r!jPjfSAb&SkoFbj8aKTYI'hfnf]aLe+4`]]E'Ki*hO0O+`$0u
\58%.@lU_aT?b&>#;8-!nV7UVHTH4t\Y,AH,3i@uma:ibNaH(-%$YXEB'dK*e`rrVO(^XE0,`?eE54
XZ]3^WjQ>'&G*L9+V2*Xe=o;@&p+#h7]6oEgF[L'I-\!_%7MD+J=Q14b]o'TUYE`XA'iH1-5Y,@Fg'
q$do^Z3D;:pS1`4\8%?8r`9*$SjCaVo^,g&EO!gulo2\oGL*6BX91dNKlc8A/tRKt]u'M8,Qio$&O<
a(;%ZlImW']U;jl^)Qm/D0L!F3R!fd9!r!Z&A5a'0)tT"Z!-()hbj6I2Nb)m;,WTd0X-<%Aou^eCi9
]fX?8(G53?o*$4NdBYXhQ2a,]JGDZO,2p#\lO,7(C<e>[<<mpk^4c0<VL6I6Vm5U2$Z)D3+T^5"=Da
mQ"Ke<]JC<W=J'pMZc_d,PmN\D,46&12&^__)N:MHc"Ej<'S\KPg_QW1lZ6muB7R[3[:8KjGG^-lU.
L3%F@qdcQ[jS!lJB"IPOEc`?12/[RsnWY:!9#/1O(K?=n$P<\.3LX+T@t$mWrSourT%;?:TAW(FKH*
=c%0[9/<;lU3odsmG8_=DnLh=u7UAXg5H2>?Iip5k1V7Ft"nUhp%U=]#MK]MH+=oZ9c9+rH-`bQu:^
g>lBoC.8.o+uf]*chG+#Ur&g-rZ4nlrcVa&/aNUf12/W\;F?^\SU"A1n0[L+#Mb_blS2jTE>_2'It1
0"3G04!R/DNfeA#0L,`ODNuYbcDf08o_a;EL+B2m&+jt@[&BY9k2gb!?'D(dqqtFP#$Tk^6pKA,3Vt
1R_h1/Zk<Tjs,Fq%,M3-O!\#fi%oTH3?W,!D8UN'\.*-u;cZe*'=V3@3YUT3I55G=ta)A4@DjA`H5S
Gqn#MljRfaG=k<LjHhfr4]-V>-5H_JFrH<eKZUUHfkZlj:?6?mVn9/5.:Zpt#-&Y.(4ID1Au$e!etD
$(J$:GUI9IXQ+pI&4fs?T1-d^F,fBAc;j"R&_l9,:b1'eHH6/ri4L19#Pd[e!b+QKKYK^7c\L.q)kb
pVtn/&'XgI7NB8kCo4aU!3/Y`$q%fZR4.8:3eC&h6LWNQJkOc<a]BuXgnGsC+aIE&QaZ.Cm!@XT4VX
]@F9'Me`geX")cq<lHisMB47Zk(+q$4__84.ECCVs8l'&R\M@[npr>VP]]oB0!4'/bR1"7"(iEnHB0
*+`dE%=l91qo:Zim]`!q`aj+<qgS?KI(WHcT;_`F=L3<RM_S-/EmjS@Hdf:5n7E+/h9lM3^XKhA=nN
*cVYX%Zi?i2g.I,2#AmG5oql%=&P:-!jf7BXB3EAnPZ7un$lO.b/'6Xm^9AgX-GhS&>'G7qq%bWP*c
`"Ph>r1JhD(b!M&F/P6CqT)m@'NC1-0I\-)2Q]kMq,lH;e@9[?>45"<G=oclXV4h7M%@\@J%r*`ur,
Cfq+$rr@1GIr8e(]W-@M*>UH:A.RJhl'+aB2r\5EO)Kk?s#DWMYjPE`ISd!I0[k&EhSBKT*CSuB#>"
:WgY5`FVN=;oT"qW%h5BHo]:8)<*[!gV;YZ^o*'rEDCi`:]E.@/$6*=/,npn[E<j1[qCLgTI+OK#=!
)h2PR;'kEp$8GW+ikRZkjDJ`_[M.Z8jJa>RClL4*kX2;CY&j[&W8H+5=DIDF6#@pkHg3g5#t5l%5(J
?ZFiRS-"rM@J+#qD+]!JJs(NV2J-[T@=TTh+27X?n;t/q!30OVj``qq>,X/cZk]S]DKiheL]=MPcY+
L.0:/,S)OidM_MlKLTjoH&!X/-/Q7t"3rnJ,<eYIe-jQs[(U=W;9#R)OlUcB4Q]_SB()%6PW>h\9[d
FFB,/_a%XGL%HE5C7f$.Y&+>gK93G.J,mX;:HZ!`9_'RM<XCJqUbc"EoB>4<%i<P!SJUQjlWCel#Z/
AKM'\.76=`*MNi`RBVYm]U.6r?WZY%WnY/;EG3q<%F^)7>*&`u$Kb,tpBa#UUfSpQ9G9"P'qhI-B><
KX,h2(\hpkk%Qo8R(L*<B(Y[Mcc/)-2ik_6%7l%-dr$q1[^3Ms)3eI,(Xa<%0&eJV$3ak%'5\*1$ql
pk:Jh*i&?0:/Y8]L"e&)AB&Q3Q$l)1eY5RZ:dC3n`RdA\R./$#+JL%JD)s;IT!mq:L9M3Ffm)N(O";
<POZ:/h[uu9PfI&,iK<8AdC)WT&b26f)0At^ZO5GB;'IK[nSFY.,(Ke=f1$kQSqR&uH)WI?EZ1lFY!
HZMg7n+7&`/nR.ioemAoulZh8o+I7U7ZpDcencO4+lIKRcj`%WO8RlCMZGMQ8B5-W*=J['l5-.&cMs
#7\Lq$VS(C,261B&^STX^23ZeD4+s2<>\6)g)H(*RJFnO]e$c^?ik_n1Yco0"oj7/="!r9SXYAdF*Y
nqrn8nZdj<!A2L$fcCjc.7^p9F*t/q_7\G."=%;!8#&[6k&7J/#NO(h^-*2NULJ'*nS(gG8.9O:Nb^
l!R(Vb:rdHnL(E;JYSUs\agka:kUj3#QXtK.LTH-d3QYd`Tn'bB14+s[Hm\9^WHlXp%?Si*UW1]4ES
*n^k%LJL]'RBM)dSfUnkAs<Je83W8Jp9(8XupK<9Gu;po=(oHksATBq'\5MG&c+WZD/OS#&s""DBh5
coSX.P`;:U[A,8c;6cfT+K",dg(2)r]p$N?V+ICC-SfoQCQ7obhfMH^96PUJ]-LZGk6e+.nJi2U/*[
hm)-FskkC,68%bGB)3/Q&3/.\8FG>tLgmLg*)06dK5tAh^NkY+p*>WJCaDO<JKnP+(d92.s1YOk\6I
!D<p.fI=^c_U(JquY?#!C.S-)E`=GicBV=id!uX!K8Aj(+cp=\1ojeX''J.t?An0>FfBqp%!"0g^V;
_1L,4mfP?Zc15l.<EY`N-surK2M%O`Y]C)DQ?9RGs5k2B4J8IE?TDKu:dbZqjb;Uu@rJI?24E#1_T!
1852#s>JUi:KgsjKh>bf(PdgArM3IA1<;)Q%;"J<07\e/BYQJCJ7,g;icMud\cJRj'O&'tPHL=ng%4
QnbekfNgu8Fc%f4*:[jS;[Z<:B15f+1h9Fl1T]?oE0DClCor.`L-^&Hht6,*/B%Dh0/kP-M/Q$V]GD
g07IfpP!p,^N5R:KHkdjHRG)8DPsn<!7j_<U_rKdC6R58F7uoN`+q%>AR`HMb^/XHE3T6'c`PO!]:S
l'A:EhO#'*9nCg$PCT/W&!<W#rZTq^ThbU&n<CU9gqL]f&00>qS$YFnL:$bF*&Y8lLl0KE@&`,@aAS
V\G=b=OGO3O)-JP;C>3t*]\Oq/-[\,e?DfROFq4"aG:-F>UAY.\?8PU,,Kf;@A1d$#RbuW,NnTe=iI
r).Jb@r!J5T)=^tQT/hYGh8_"QKa=mO%++i\6"IPfOZ(&oU!pl6D,AdkhcC@bIKa1JKkQ$Hn%!P?k+
#\AKT+R-Aid`3Z>uKk)bP\ni5a@1$\P_CUe^LS!nn[Pqd+$Pq`LYHNSYo7_2_lM%]Fj:,\U7QAg[?0
3kF,1'O8If%]sV++mCBANL6[L%U+TCgFo5I/"hI_gBchK%)9t1J,:8gp<Vd#e(2%.<i6%L4"h>JW^4
)#^[Y?Kc&_X^83>\.f#r'4Jp`Jk'[e:d1)^_OhS`sA]&s43>^bjaICh0M%2g(PbG!qLI.gJ\"d0>5s
Z3^(KV7r')@]3jMUU`Ps?,[(/]j@d-Fri]mESt6F^&u9?6-@Egj[71TMPQsjkW-AiJs=Cb!oTp>1M.
tFUu%FXGelUbb([np8%'Tm#mq"[PlLQWR-s5YUecr!_J9s?T#.'0B(YhJJgQHe't5=Rfj2t]QJ:("$
C]N"M*._TA-`n!@)ISD%OK%Z60YETk=T\6h;6k-a8<jD'3VIZN0\dRgf]Q+fh3@B9Lo'QNinQU(MZ=
CQt12OX%/Tk)6o:Hdi[r%lY?7f^)[S"cCfa<QPej1Tb%aor3I]MhO:jjmrJ;[jg`-f$hE5VVA*Sfa0
u$_.JVNm$[E4We_.:2fTX1Zp"IqPn%NQ<lGDR<$[[jhB,.<i-bq)f*N6:`Z.+@G)M!I2)%UD7-O8(u
irHk(Ftn(qaC4+.(\\RQRpZaG`lZI.m!PEY&WP>BCn\'U.6h`Gl'?2:[HH8f1^$)/\A94Mg9>I3(UP
%Vq#tI@/h'1:\2`Vr8cUsoiAMN,V*`&'5p*cM>8UH30>+Z9TRY$&0p5?;U_\=mh0m<F]2Tsqk(It,7
)N\X-nV*bR@fsd5?";5Zqt\un3?qd,F2a0)`olQm#$2anQR]T4W05!W&'55YVT`*EQYr@PfipGUMrm
<VM=jR(dP;6@P4sg>%?Rt)/;S**e&(mZd8$uqOe9e1d+3ZYj%Yme'PIX`bHY:eWW8MXX=M+XsrI;=>
'J;TbT[UONql`!=L2]!#[!`TIqf`<ka->_8^s!Tr$MQMm9aYLJ8D%]^X@@Hg[CGGKFj]Fa!Jd[e3b4
h'C9::FRdgTThm\5:tAG()8[!\T:@cNL=';>d^O7rULP]Z=%=`1\-E8S^!/<9KC2pIQBF$IhJ5HN!n
^f44c,fH.0.jn$&aa,:3\Q)(9$5-+4=gYG&3'6_h_tfP>-Eirt`_dV"O[ModK^CDjIeG]>`9iE4rG(
3GZQB(L9?74o'H]'Ub0/jA>g8P'g?Z;N&YR3R%Z9Eq]/2sJHl[Mbe>!'gNU6pXd]@!$P!,PJ-1_oe]
?,e"m\9u!*V;a)57E3UEU!nRZ?)<1h+a6?UZ`MocJL1)q::=h=\&XNc#P/>mZYh:^R@_[);;W==//s
pLKqdLPT.MkRC)/0;bcloN&\K@M*3d%IB2WMT:a355-:^;^?F]hXjpjT%aJ/T&u=C:I+Ne<,Ap[@RS
47C%6(<WcTH-)momc5W("So@OK_0Aa`skHo[BsVU,Iktb59(%&5\=!*V=<?0,WnCKH"$D/\>cd[KQV
SVZnUV#V`U)sLQWdeNXQ_G[V#2Sk'"1cJqAJap2m/@p*C1Z6R`1;V)R`mR,T@-9"-DY$M=0bJI\$0>
rrGM8$X-eaWWlp6ts!?3D1@+,"M5_8,GIT-KjE/iak,=L5R#&5c??BVtJHtmk:e)SNJqmi_;,@JiW`
+rn$<bHZe2&mY#+c"J[=,aN3T9dXo@.AC9;INh7EmGk9=X%@E@s)Xsq62<3YNQ:uN[bahsqj="ZP%K
tFGLfbZZee"/c%j_YpLQ2Hj,YU2,d>IMi148,@)#sp9+4,KgV[j/kM_I%Za\1CNbq>PC],85#]dP30
Z%HQ,)mJm"eJ:tK8r19hAf"lC"l2[i9aSm\.9@j$W.QhO:G7*s0OXLS[u\2qk!<r3KoJJ5L-fuJ\YQ
<c7"p-4!\">cT)'Q;n8p\^nl"M*RTW8@'c-Ja;jVt0b`77j;7!0:6JTiJ(SmaH5&3XHKZb#Y,!s0eb
%:rL7D;0pmh/^!f%q#SK4JL/G+JsA:S?h/.qa6m];0O0QS#=eke>%9p>f6o^7YsQ0:XX;gkg#Ib1)3
i9Sm$m"GhV:-E9<H:4*HQ)S50Fb%i%`AI-oJ(/d7".$qGkA.^"*LPHsT[eY>KnRn\dD.'qHnD[)f*k
5jVAZ;/5n0!8CIu$#1D!DuST0?r.gW3`6`iBMUel4<=3-fFG0pTA?*oGW&M=/*SnR+-6jgfB-nasKf
0\>0ZTA+W,%lGt1'L@PmJ+1G3(a=#<m9+rGW3E%E,.(hH1F4lcp=@j)/W/`f(:kT4$Pr0TCR5(hW<a
`5L+43#I$jFMV-/TmlOArD#_dHi5/Y?VqGaNB$t%u30:ZC\D0l_EAj.[X(Q&77Vdj]9c*WfLi1@oI)
i5#PJP`JC_l$2V5m-KW&4+dbepV"<`R5$X/,'NkrVX?f2I0TdA3Ot_MMr/?7lQ?(#0>%^91eh[^f4[
u+S&V:(iuDj`\-6%jXMe,Z!S&U)F>D4m'urYf/g4S?dg<V"9[3+;l!?f<0!WZWJu<%Xnds/\Gp=?k4
3h=Q7_'f,P_%Q7q^#rD(Su#G/@I1o.>GfT<(OngXNp!$$I]lQpQiYp_V&?XdM0N=.t$J!Q<BNQJ%X0
KS=[t(+NE8*u"Ri--[6);/g_>1",+mK^q0-')\N!LGUb[$?47_9B87@L;^p(?K3U<V'2XX#QBq"9j)
a3Vp*p\IEi"/F.g;!lV)Jt9m*=43Q-hScnRR(ntnaJ2)t+57?1iK@J7@,\kZnh88-9<1Uf969LZsU[
O^8gm0\R4ZL`OZE935A.5$`/_!NP(MU6-aHJ476U6L=fBg'5")78"9r5?RH^Tn*@!IC-'lrgZ0f!MF
9E8@*`O3,L=7Wn^W@5g)?//\)[dnOe2:%^e.(DMXb%]b^-!.AQi#%Yb)3%5G4=!HURU$+63E+ET-Vk
kXVTE_CQ`JZ3(Ccp,%fb]?CEX<BMq]LUYf$6Z;hahQAPsAnL*_+utq-dj'&'6fW%NRb5^cdT&_a67;
&cem/n%X5bi5fEJZgpA&+*i+akC.W7)6!j++2JuHcr5e>P++fBAStef54UGR0,s>+hgb+ATm@_3bE<
Arm_*8\_[eAfE3:XSBu12Y/jCph#hBCt>o$3L4\eoiNs\KOp$"pK+D=)V;BdYiI6cfS,*Fdec#D*Po
$kX5L+Wk"'?MQ3k/`\'>t^\i//WFFN@a"7^8(m&hYLXo.IET&JlNqRWfG;:RD9jP6UC)p:I1EM%<9G
VZ\X.qBJ^A-GCfW(iYiTM7hc3T`U=M\B-92!\bLi`#SrLK1V[P.38ME@^b]"BXdi55f.r^E95r$"M^
pMW@'4Kq:#BA,OP#f"'DUi"j^k>p_6EC`Flo$/+5s@Qa+#N4jj2fk*cG(lG/P"YBdPVl8OpWg^nM_c
Uj8LZUYA9FH1UV:SP"l5.nkn`].q9CC9'U8"q=#]c'p98XNdQ@n50<cs2U`qA4E!g..;6?PiA\J-tJ
`'NfHJ^lbW;AQnd&s9`U7Y;9r(reB;9i+SMBjBhC4&$&9&CdpQTnC3*/f*)nTE&gdXTfJBoeh-C+_;
tGnT1X+7QUn$Kr,QMrY\_==`R78tKH]"9sMbo1OHt?kUX["g<>:6'S:';oL1?4IcR<0i(=J.MsNm7-
WS&+lhq9!`0\1^@/)'t255caaZNKKN7_B@!r@`%P"HiN"0,,fa>S^;Q$KOt/6,QP*nS3)LUQ(S!,85
F0EmQJg![^I8=eGT<3d>fh53Xl78JqB_tj:):m/1J7Y.n:./-o`Uo"[d\eBbq+K7PUS_RRmkPF#r6t
(UmYnkj(.29jF(H\$u-%LI_s';c^T)VJ]6k')`Fjr(5<Z&8H^1$&rD&'XqW6*3Ya7BD0b7:WmG?BeL
DRFc&_A\l3PX9')EW2,I,lOf$4:0c*V&"m);$h%%bJoc4Rp4d,u!b3c'FUMBT&4c)a+03Po^C6gUsK
a<fW%ch)?'7K2D=/>`Q#cQFGrG.5jYe[;gl.,a3WSlhIW4$p*2IEpK*Of%!c/QT^F9HAp>8&k8)i;B
q_*YD9D97SV+GWg$s.J.?+qLH%%k7$2Ou6CipdeF?Z&Z.I5bcOq"b<pf1Gb2U\0<6dXI,/L;4_Fj(C
9p>2hO1"@h2:+]2B,6-rG\L7Y#lt$+L6pYAdK=)Se/Mj>kSo"G$3@T=b\BZ,dIc%f08/SGr;]=2I<[
]4M6iK4:=*VOE8tD4o))_*e+KCm^XI*['oITA$_`7u`Vhbfp3KhB.9]rRf$2-c@hiPFYFk3>O3%37E
Y.+m_<IT(]2E`ZQ1EoQZ#:ILE%JO=*h\M_WrW6CRqma)Amq'jAmD0g\Zm+P67"8-VJc,l1U/e!_61L
mLj$E,r&D![;rVCD%C&TXGR[7[DKTDTIGcJ4;Z2%>'G5A_AUL?*g')N,Ee2-,a5Y/tQN$K\+T`s+L[
<9a?(&W"q&V*5oCu.2a"iU%cHTFER=rfm5,$0E($X`[rdMlf6+<K<R>;.N`F>-GPkS$6KtMOs&q0AD
]3.im0g9NFoi"^^4@VV7cEV;(TVki2CYG:".^rR:W(sg'[r7A#QprlFo7r<><FAF2>8?G$:1@qZV37
?uCopP`i,dErcb9$j4gI:%9C[\S#8T?U*u2[$s.2%gP"13k9W0V;5)QFht*:!n,r^$V8[S%h(:ZY0N
YX"8@>@Dstja`,Pa97DP]-.YT14OdT\3e74aSd2AF$>Z-gQ:3=5qJe&3'_>5^:E"bOb*!q)T^G4P_E
><+X4IK8I8sih'b%_G=JN:b.c/'::.\VO867FWb17!hT`*O#t[p2VB2]'[g1FluA&3PY6cUp#=#tQY
"0uUFn:G?4E<SGmLMet.[BDU-UoF*:%IJB`QE&s2@$MdbNpRQlO_;<XR5XF/um--NQ\p<W8i8>.o1s
XVH$]3T*i,N8,dHOct9ph3;e`TTa"9b>bJoelrD9:)l9[+,h\DjAAARMHUg%.7/OYPpa7X[.*YWob/
dhN-7N"/2_"g&3EKm3[p<2#sO(CfT?4u,b<E>5ZUnD;HToJ<>/qkl)0SK?u63pRh)Fs[qbdq:]SF,Z
QA$7`MdA!2g?D(_D.$;(rXjHUOnm]V,NZlcXOR",O]#D>B5gtq30YM([Y!CBR15qrH5#Z%#U?LO>^A
Jg>]?2Th>?6?q/p=2A"g^Y;s@iH;J7*K6&7X)_H'c!SjT7*I1&f-$MM6T;;i;H;"Oh@E#Wqa^kE"r^
a=\2(hraea)EGAlP%n+oVAsk*l_,j*H)"#BCd'@5J0YJ$me3Q6+Yi<-@H"?Tjkn&b(XTeJb#fVf\@^
<8uRj%2AGiH>Ph&OV+ALYId8o'K[D#C4"^F/_,,63F?7V`$6O*u-G`u\MpahfR.W'E]!3oM]ZMip2Y
d:7ab![6saN>Sa[r:K7@Vb^Ytcr/l!hLG]<c4A^BpssR$TAV85'_E=_g6M;Ibk+1i_ud!q`njgWJKT
^GkI,QP$_SZ!6>]tko(MFCh"TU1nCWSPXkRWE8JZ57ELT?dKo8=2Nt/+]q!-:#<nl,$;N/)^&([*iE
WFa*K_oX^4j<t8#!^>V8HElg>.&bB'_K#A+D\eV(oWmlk.M#FiD@>(lK!P9YmV>"@4k+>+AN$FZd[o
oL7V'LMo`t$8$HuUlakbqI,$CXW'B2fLgAkZj)c:hj?1C,)r"UFU!'`c3V2jDqbAdrDAYcTj/*LY^3
<8A1AJh-5Om8c-Y,e&!dV<oggVg$3M6ba?*VkoZF$PWd^?f?_1ml0<k'MIG-!_S&j2Q!9JO+']u\I.
nV4%[?JH'2hAd)e$dJ`''4\uK5CN27HXB%UB$;[?`YG"2*Q#$@HhmqT`Zo\VX_`_Xk/F,a09YO]Pt$
,a&iW)^Tjf?c&e>741?FH02c?/pRQY43OiJC_!jF@$e:Ui_\nfHQ*;X4i0M\AAQm>3+fpu6MU!O\ZB
\Q)cnB8<H=fg(,(jS.3"a>9=L1m]^PNL(f5Q8]9Qg!c`:f+d;@`cL$\-`oa,/:(,So"ZaJV%KGV4-B
d0r+5RI>M2WIuTG,\Irt)b!,A=s7#CU0<"ofL&TeI?)LGA*BMt[HZl?uc/6RdhrXTYdYD#4]@td55\
<p`3Ug!h'l1J_XlNh7_PrpjZL<P]IB3FfZB'Blr<9TOMII.*iWFY-]0.CN[^c6W8_(BLd\cA9o[efX
)CRrl?<p]!QMh:X:-E%G-G*0Q3;_#p2)L0-RJOU"!FLCf[*(JZ#3LMJ5h]o8`g4EoVEiOZp^QdE`/>
$<46lA&/"QOjm,]$=ZeU"l;3_W!,p3ckH/)'9o;CbY1HQP\S\>;H5_g_ZhHkE/NS\`Gj-k2H/[N"N:
KTI*N2"0?>RJGRSV6Rt6uik76$ipZS9FW8i<R0ZSMSg#4lAUUj^<Fq$"ECF:]!#Z.T;,V:jHcXY3^D
nnu3HX6mToQ*2!YYhQ^RMcscTGdn%KHFN=7Rq[_7,_IY\W;kN">5ZMW;lbf_oFK&H$[_3k<p;An^`i
l1,?647>qsRhg(]We54)SJkESt5qYeFQSAC-^CZ*NS-;8W+RpYP_,VmfNTM73L,r?M<LCM*S9+5NEU
4"9M<`[(OXePR?.@W;Gm8.c60p%ke!g4QN$p9m.[5*./5mRZeM'92MlcAb!,:OdEH5CW?t&_rT'`'T
"U&AaJ?N&rf.I=mWHh%B&YPo-u+E)pu4W\:,%)K<[CcmY#d5\rk0rS_3&3o!CQMdU!Yi)825SPl&3W
%nJk*C+Xtg:.+;i>\ZIRIQqoOEeRD+9Q'D7r'B5HHD?rQ^bNFr;QM!2Su9.KB\%7Eiq@t:.IWbe]Jc
^R*q*`.#I_^@,>%9AhC<L'&5o%=dP&)5gF`8jaH=Wg7WHpp(&B*\c2;JH?Eg7Q2kC2n?uJu%(l=lrQ
?^EFX1^aB=)JfjB1Br_"ZAV2\n"/@nB7haaKjVr7sR:dU#<i/-Ir`iB-KKJ,E4qm:KPD"Y40'nk+_`
5X2AJ@L*",a&l[Hr@d#:2YCed:a,-WZm2WfH8Ea<7_/SVG*6n-AG#ctB5?6QllR+i:^BE;B$$>=Nde
HRWW's,]u*!jgEX@\]Gl7aM0nS=R$N]k]X$Z=/p+>","P-^/b>BuQ"'1oM@2C>&_BP,2?t9i2Dkqml
IA2S\8\^:o">V^+0Yg71E*H85^%$BE<`mc%Ms3OR9:fafoK*fTG"GSaV0Ef2SJnVhA9MPL\4Mf1`*(
%m[4$BhcYXf[*(%9_Rb3&'B"j0,JET,g\E4O6Qp995EEBRG>/MpBMZm@Tr&TT*tk<N!7$g`gSa^d6j
>?(JhF2iBHMe-'JqB8$"AHU?bm9W`JFNo=WitRC^LLVZ(Ws*o3>/gWR@g#K!J$0q>H.AE84a8@Sch%
[Z(,OACHV"''QOE;!*.L2lZk8(a1FTN%61X;PuVS^!;05q#-s?OZ-On(:^E]?e#Of,`&srd14HYKRg
fu^Z;B5CX;)',9<aY%RI<BZ]=fNQVAu9:cdb4N8L%1@4Xcsm@WirItM/i/(*ZcZZ7D*iQ3nW2qQ^K4
aj=:hM_b-R:R)`3U?&YT^.H>FH#slUb_q3n!L%F^e@BJg+AGcao4V85rk+Xl6lu%JeAS"66aZ*"hj*
pF%[#`WoJ-#_ZN^R%,pR-?O,$lIm%Ci,63+_4gVZ(._iOUXD(qhJD1?k+f;g@VAXPeaHf0:=#%PfS[
\.Gk8+b;P]2TYb[nttrpq5fUPg"X\Hj<j2UFB.(Bj-aG(\9h]".j5^%25_X#Ld-<kZ\VQIW*Lah@EQ
[P?$K#RMZ=O@kP?9+SSY5F5X?Q!E`t#H88$#LdZOmbO2@D"ZY3=m>t`Ap3(W^0Si9aaroTB3<E*Dq^
]Vk*p;'C-;*[AF"a)f@qDIol`GRJL#r;cR$;*#>gW_b*T9OYDe/trE#\a_Eg/(VH*hfZ@"h6B7mp'?
/F%ClgT4P=KB2T!.58b0U<44^>\/2'+_8BL[Vt$mbg_pb3WMi-B_b4&$:neX)ODA]L%o5a!`?hbGBo
oC<)KfDCMc(KG&7a5Uds/?l8c$S27\YdS(1F:H8M@rlZ;nJY"`ng45I[eC2$XL%/]k;%9j!bb+qHM'
6FQAl;Rf8'mf,Q2:CY>,P0Hrlnq+@KEoN!A9<.N20GZq@b@.]&b_.]jA$_3_F5>6`:/VYT-<<-a&+I
!%mBpbOgPj4MSMo*<2]^`sC*)m+T,-9-[R",5@Je\A;V#X!`qdLAHqQlDD;0CeHKaB-<^l<Fp6`.*=
>IXq_4$&7%cllm(<eM4%:=_2B6CT0=]dRp8T[<<7mg+9TYf1i9"O.0YipTDsg\6D'`t!NC\nKt#nka
j3a?8(+HmQZIfJ/qT6Q<q-cnm]i5c3\iH''B@Jpn]!4,<"<Y3/0kX16+EL[Cq9>\(o\/+P<nu[O'Y2
5##^Q1>J4Lg?Ti]c@kso^4mdKj&1n/h_*mK@;20hp3pYC5*J'q]m^I:+FBp;2jlG&K5HfTJGk^m`R2
M%?R,"Wr:i5U"Mt>$nAOE$lh.Wr*#[J-@n6D?QJ(\og:%(/?qG0>%Xe_a25on\kjS]npigR8V:G\L0
)N-i3S"PRn$+"75hj!*G%((5#f2Q6.hf8'hl\Ue5P*=_`(&dOe6QCZEoq9%KXtF-d#f+M*!:ru:4_Y
HOY!Ec3FpDA%WAQl]5C`dG$gR\CXXjjiTZX;`,\T\YFCe)@l1CLoeEk>RM=$E[</'A*T]%*G%^"ZB1
r),eR_g!"&Nr.YmA-M\#AOqC;Ac*YU!?3Y5-XTIJS]R-#u@J.37h.k$eq3q:0^,r,bpHi.$^E#9R1g
$d\CLocket\]0Yt3LBDl"q\S=hc,iWgqk&!/nj`a(E;kJ3]afX'GD:!AZ7$5s2j`Alotq'+S<J!c=J
[5d`7utJ2)#gDQ@du2)bOA*B6se+^qc<V^'>)j[S*tfBh0qPJJ&Qdd4q[(oOm:6.8N.8#G-[,Z%+)r
d#N=rS30f`FE*n_$g=m(Zdl+RSil[@G`YK<UJEYh-MYBsQDZ!tc`IEM,X<pEGl@<m4bj$ZPi[EO;4#
&h[Y7P1IPHeCg#m+D",u]4jb(c+0/qQHeGEr[BUjUYZA*l.pUB%)qj:]9A/"`n73<:cmCF/WIpgf/r
.Mu%^df*o2TFP5(t0-VG8tf&Nh5/-n.8$kMe*1e`EP;[1T;fO[Z8n2(3^-.q9Y;i>#)Z:1i7#mO+g#
dS!.<,gbeoD:nn\?CA5kT<<Op&?X^g+=n#4M7Z%M41ac-=a*]K_$=tl+q^0!oc.&BaHujft2_o=m*k
ZgrTDJNS7J$*p,4&h`4$1r7DpKO1G\1k3,!n#E`UfBuMK@I[^@U\KCT$-ebqDbZR/p(S(4:VdXn.BD
Aj1$GmQs4pHpX:D6Mh#23ns8RD^bj2nommu6"LhhrYQ@.dd68L;b&L[><i?VD2;n'!B2ejl1iTb6jX
_Q(?RWdOp?8)AOQu5g!tuMbQWENM$_'?VDW/Y_6-p&A)h>p&Z\:NRJ!=E6[5IiDOh$;B0I[P*gfum2
KNKmrdCWE+KBQib00A'@hn2<&P^pVoY(8.q/?Ik%EK]HW%tq.h-+?6.+'E_C@NKCJjhuVp5RQ4Wf/%
9Pn`,0o]N3OpV-.FIcU#-3$*GhH=.Kes5!k4_&<LTr1RNC!QTLQJd$l#)M9bO/Z"3!:;Vr^TJpAOK?
BEoCAWVBM]c/<l\VWRbbg!ESEscB&j/ie@V/Wj[$[a%<XgDmAGPiZjd=]Km-6"`@j`bYOUiK_;rP2>
`Jc0`i=4D`[_sJeP^Pc'H/Y4dZXLUc&bZ5UC&Ub3]SHQQ"SM+sC$i%'D`rERjk,Db"S9E%;_u]tJr(
-oH`4dgli<2f<B1DQe(1HIiEEP`9Ep4)(DPR8'jVoN:d-W4>h\7rUktZ$OiZG-,)&o'mctOnVuESkE
Lc+<fAKH_E:ai7?Ya'4\U_JWTs,5D<8LIHUqkj@T]TOENu8q/g,a=UNH9+F\ul(n<6Ea(C32:%`b`q
m[OH\qGAmi5n7dL:a<j.YRj0t';,2FXoVFQK[VpQND@+"8+fl[&LE07>TrV60,Ib+<>=Rh8TH4C\bj
jT#=EV$Zm<CM1cV(O2<g9*icdFT1mRa;rnqPr4jKVOp7O+'a+FT\!"e*f"njuo;"7l"\9Jcm7JUe<L
@b&&f)Ggi;b<_/E`/oh%?FWr/_dRq+`S?FJ.(DLf]l;nlLY(Gsfq!>o^Mne=p?ec=PuO38Ga8AGjdN
U+^[nRs8"mh.+./L=1]r,FYX=o(5c=TckN)ZLs4@bWN);MuJbbkG3:G$t]P`\"V&@hOY.eBnWdNKR@
YoOoT!_Cd3.@S'YL,\G3ee=.UQqHms8D\?MZ*aA4KNV\hGds2.r,V"Q#RBQPF3MnZ_9j=/fW@h"rCH
.72C,A3,[9[p)@5dJ+P=MJJdsPE,BA:3[t2NS[H*!2D6E]#?+GfE^2OK$*+9I$drSbg`0GBArkSI@D
lPriLO>]5i_\ja-gLUC!IQ3JLD&K-]5H.s$3ka2:]ps7_=*3)>LOAaTEN7>QdK0P<L3U*jP2S"ji\W
3mSBHB4iK16o=3L4\ZTZ\!1^^IS*H'cqngXfI%_DN</&&V=[tOn)tqC<RIWuY2J5G_J2>>TbhMX-tG
X%JO9Lb(8XVX7(@E\B$8?@Yik-oTcA]+f?eKk=$#j,qXU\Bs5LBNN&Fs5_L1-fl[j`obJ43,`)8D7j
I,3*cC(62BORKN_3(=.A:<Ih3tYZSAqLX63ZE;JB<&o7n0s(V7c;p!@2LmlWEd!c1PZMa-"J[;BKl+
4"+[`=7-4/lr7^tQFbCtG$4'&Sn[TGG10f%[^<ge\Yri0b_qXQF\mke)'<@k26&F;F6*n;&\s7mf.\
,'?E#1G)^?u4C0a(Gl0@o/d4Oi(#!8rr(gbP@Z>F@@J+a!jE"b3;YB#/9#6g0G5-u4KQ3m)%AYtOgC
5b^7$jIcH]o?/'`EI*2ZK97>DG]\fDQ.4<KUMJ[hht:WL_#-?C@LE,]cCZI0BRbM]>C0_*6gM!e/]U
Z&)au]mUTngK^L'N.-<PhV0K(69)DH>e0b0bsk<^D.&!?\oJ'noBh&%)<St's^@ktgdiDFXZ5s&"9:
pH@]IVD^Y'2<PYTEBKA,'/L&Q3Xi>QM^/>B@LI)F<M6\6L%k^4tqW3CE#SK5HPY:qN.BBfnD>`Gp"e
Slf>%kbZrSIJf?F%UiqPi?1h#>ZL.Rk[(*AU]LfC&pZcG\q2bR4MHBW3:lm%SSoJG9N6t=P`Pp\N6g
5">p]4D3$nn)H7#W?De;G6;*ddRVN#..M<gK:NE62Nr5)G_RTr`f_W4@&9+O,MWO0hmhMFWASWVH+$
Dtd_]-sY^nG.a?9*Qq48,:e5=QS0u,+rNLNm1CW5G.;>>3Rg_=/^-'aLt/4OJJ-_Pr;55eD*!6>O@K
qE;Pqo'GAb\B+1\7^8t&bpXXk]oR!5.P_$@hEbfWVrgrbr9G)P8K?iP<$DkD?b"5eXg6-E77_`rQ=q
NjC\*gX`8mFnRlKYrW_r)5rRHG=JcK)2KZHKXh0_mgJ2)9[^kLhBT+0QS3'b3JG-rONkkqg\UA!utW
0K;*BQ*WWbk5l?'F'Eu]c)\L.DJ5d8%0t-9E>(5qdBEcS(`mD`9`[5b9nq>XtO4t(Rn>hiks8EQ+#X
+"mh/!`'qpD1(bQ89Ebic9AG4hI\Xn2Jo[%_WI05kDf+me'0*n%*o\I5_\BJ$PB1C^5%?e:m_kI'_8
h[$nfe?,R*$VXkkp>ob0DCE`n8e=t^$j2,?Zd-tI5X)*G[l,=`Xirgm<UZs<`MeHM"b'k9!?68oobp
cV=$UXqFNbL'68i77Z"`1P+j'HE;G)TR'-DoE9']kUlZd*8;+rsX3h2Pj8.IJ<[d?$`]@57Se=VR`h
O:LBmb<3lPAqqsK1TIr%Ld42<\ef$g5X_/k(kkjYZPg0Yc+Cm@XdL2MZ@Il6<odHhb;'-WXPp',C.b
Gl80.o2_^@.H+&:>aT1HS&=jj]AoJL(UW.M-Yjp(kMaWoY5+,a6G_?+np]IQe3T-:lqG#um!?W7e,U
fuT1sA7<J[H3n1Ea=X+J$WC!1_EEoMrf'XQ".@=r7O'o8p&"B>Ji.X;jD4/uI%P1iX!MdG$g7QaKgD
Mp3$^Ju#@W@auGWqYA](-bfE?1[sLOY1M'hZSa.OiK9US#IYPjDd=UGE.l0K@N-7f<&EZ@1X%S4`R*
72]U[QJa4a:Z-:C.D@q0^q=5`!:nm3q,6i!Vm\e51r2Y>pWJDHWh"TMC21PpZL=&a9_FBiD*UscX:$
PUunU>l"OK:tTY"=61?[c:;gW"+@)V0YD"59Me.-t,D<o7;G.cJd^6Tu\ctFT*sp]?RrIfKb%#G7:U
QEmAD;$q8GOj3G?h+FPqng,$:tKkZJ1U149cbQ`kt]^?q)CoG7VA9)ukir?*rKCnDh\2\Y?D(PDY6c
3S8@NiWDIr+ce,MYUZCWd-,L8ID,iO`W\*%Qdb@DcKS].$[kS6al!*9e6X;fo-.6bSF;Qr`oi'Y(8C
TOLGs(nnZ9Bl$K0\M(\(J*uYS?[bj_A/L9PNNXA&Y%k9G0YeXjh/hao3Lo)+a[@7PMm`a1Lq;I#55#
'3X4H\Id.35rq/u"8I/Ye%)2[\bD3eLEn0*j$=be6C*.@F4CBRT%(QWLh[&J^)k6>.:-SA(nY:b.jr
fs#5D8#Uh$VlG0,Kc:tpC_O.11:SLCf[qllf6]V,9Y/7PlgXem7,:A0R<e`j4]Y68gr>gQG4e/!";A
[fKHrb&2J5P6C@i7,acW#M0`NBnAHSlgZ*bV5OoWPYjP7QO5%84^r[@@.kPK:54cp.7DF7k2[[/T@\
5d'O&m>b?EmnpA/hq5J$h(FC'C2VY$BB,n9hFcHi!nQ(%i9N3_7U80jbua=TH>0PueK#+:X<)@*0Fk
SRia6\8Y-Q\OYsXJGI;NHIuj.^1fE#M:T7RcWQ&AK]U;,5Ppj+UTXa"&sb6DM)kIG@VAli37rbQ0c=
6/K#Ye_"dbP+m-(J%58"W>9`N.p)27l"n^r?X=G:J_6f#OgD/IJNRnN1aGD4Q\SR>bZ1)"S.5O67E9
$UAd1sn\OFE$VRH1b!_I`g/LY7l\n'(_F"KDC8Jj5d$"%6)S;>_B8*R7\Rfa$/Sj%1i"[!&CU_d^Vu
LWG@9)!Ssof:]6/T86O^2=f'IIGk%%d:]4]\-9@S:4*djg\JP##V.oY)/1]K:-K+fC6m>a2Z'n+iWS
L;%j>DliI9de)%9Xlm8srI?5<(GT_$@RZ$-JZr\BHL+9DtE\9SsY(2R@E6#fmHJ8u`)$9J-&MGZ9J]
p)GL"W-&e#1HJng5q0G+h6UJgf$eRKi.>^^Lf"+A5C'$&35&FGM-S&(^>'mFh#&5Yr,PI0cfS=,@p$
ggdEtf^B(0E9Y.h?QTC+i3eCOR9]cCh[eM5nI$*DHlSaF@Da-<+(8'D4h5q9a5_PMi''ZS_c<EdV!J
qNmd%h@h1%4=&3@r-`0^aI[N-e0J:ClFe/*>T+q4*Y_+-q\_-<ua!WKLlL.7@0'=7I*n;'c<#;R(Pi
uVd/U[>R\[_"gKR>*M'*`>'<C.Fj=_.=BR5%TObr"aURdXOJ`B-:*laM1j.[FPY>=u":qfYkY@&3+&
WKuQa>,'(ZkKPP)p`4ckflCYJ,I]\I%A8)%4<^Y?XqH8TS"iCXtjR<WXa>m;:Zchr2@nBA_Au[2:Wf
_K['tS3C)6!tCGm_!n\3$Ls#B04Z!O,*_)r;Z`IK34535&D8?$)*#LA0T!W3jWij(n-F[#mN-I*]K-
uQ)>;@QPNVA;Rm5N=[?E6e1$2-$^\6VVIYC>7A4s2Vr9?4&VG9k!FretGgfVh%@a>MBT>1ED<s_`<m
FJoPU[`&Bh6HI=?bOk]ghmj-[^f^WCgMZj0o*VALm?5'@dCI$3.lf[`Fa%J3<RRh]l*4ra8YdU?i*^
8p$e%F<F\ZLC7$oE6XG>+08kaJp>Y$U'h\3e3TuqLlSlQT83LCa1$-1=Sn79DE2fq0>OotC)hLlE2f
9;eLS2gIj-C>;E]am[3"t\g7>;1c@,+;i-A1DgJtLruINPk@j-g:(1?MdEq$p@3=`,Q$%MO?G[.KpX
Sj@T3T?)Ub5.mqs+$U3-QfQnSnQ:"cemO6eAU0Eg%<9>'W+@6t3At(:Y24UIk!V[nkYL6oo%)PCRTd
>]H+giUCdC@e9pf@:_XLK"n(G1b'Q\b)TH!quK/VLEMr:f$JVk$d10,F0)8/UME,U,/'G_jh#7I;I(
-^On6ub1E0$<1?U!l`2O>XgL7n5e$Q?-YMO2>Td.jUZD.38l<_&`_iSi<`XZis;\S6!jA)_V6oc<k7
hbo4Rr,,PdH7V3s:='%")gpQILVd>W4%sfVm[LbRu'(eFB2HAA3TD?>s#=t?2`CF>Vs.-oQrd0^^29
T>D-X/snirA^"s74a1mi6iL)`O7^&!."oLMJadGjqhOe.]kBbS<jL$Ps^AaP"3d_1[>k$o-r"-([B?
5Q7.C-Vm^\9o*?DGf#iP$c!nYRt$A-&Z`h(mHo%*;eQo>G-Egn7r9XXKSab1(pZ[K9HUiBT;][)9"4
n6N/GoOX6885DcNuPhZs]#_CLrZhDC5?6ZMXl,=fq-A=\p>BR&GCDU6&gW6Y0,8)uru<`2i;H,^J5E
:P:R_AdD7k;[+Fg#s]?CrflT!oL.ah`dWNNIXHLih2D;5C;O'rM$@aB7!B:Z"\,s=1^nQ:?ZMPlKo"
%%`NU8#gJ,(9nFR'q@H?9Ifck>;JCe!OJ&+R#(f1Q_o&bZ61g35;+#//D1#5mng&*7_]p9iK:G]1Aq
r2LWjG!EY_Dcb*i5`$j^-;jC'03&i_i;%N.@V<U#=RR^bA8S76nb+6\DL0m>a&("*9nbGRAs0;Jqhs
9)rS&dodVQiTV5<G@hZNB-nJ1VH0V6qH4ek(8Xc24#P>H39^sb6@NpOJgfjUf8fq$N!=NfR#".?).W
E6WN_=Yj6.r.#g9KZTtRh?hV>kJf5Rq_!i=WAjG.Zt/rB,0kE1m9K%Lj4!85EGM+kTS83$AY\:(\aX
"FXXN`C#h0?'o[=MM@NF3V5,$1J-7O:23g27'dg4ZgiuFYdug](,G<SGfQQJq8Lsp!!%)5iC/YY0?q
'j!@\iqtW;Zj;;`l>R&FL#7%LFrPDpC#6idE_5`;'@g>M]B'sl%,_dXJ"'_9*/&.M)^$#<Cr7>Q77<
f%&f#7V%;n51Fci3pIDat/r7DbIHIF;5l6\9oPc(:#T)B_>Jn+%pjkJ;_%(G'G<(<1?6a;TVuZ!MD&
*kZF1iPXbicI]pb0oH&^Lce2em@HIBLO0"W5AB>Om(A1MGf6FR?j7ZE8hutr0;G.?6f=?oQHmY<<[Q
,Z:d_o1^"u!UVOAF.9\,FWWAA-s*8#alc-AY,;?2WFg/^Jdg9Yl7F:\0t`b.2a%YG`B),a_(VR-*tC
,1i;!KeV7:9*So([>ZZNZ9[hFYLfH^'41nMTWrZJ%YsD9l7V]OFjT[f,Y682G(D0Wi0`JD<WkZ`_ut
e8Ko.6AGJq)kSS)?h"elVkQM##+@t1Z6Y3pl,ZTquL)UYjTd06Wp)KnKNdD>T'XqZe!9SN(f?f*<cG
gN.euEIgqtds++#<tP!sr_64jaYX`dQ%]P'YLt2(j_6JYDZ=kU"^s/6Z6?TP8Ka@$^cba`lhhD_4jX
WSkR\g@h0;HkWE&ZqkLKO3rJ*M7M/dr7@6oY8r)U_:9BAS$:VohHM//#B;EX.3OjQ;"BtU``'+CXGK
l+#igmP"s?Po1Fp9p11;h\i\rsnm4G_0JM&X23%;,+@\_(=-TOG_5#[)fWt"3j'9p@Jd8gF7$aUc\D
"7VJ!t"7ZJICCE'u\4"HL"mj+Dl55Cd+\G9H6lIhg(*JXdnmdJjY/sfm*:%pFO:Bajq>X$T>dr%)'7
6VKr"E`=Wr7n"2LY!&VAl;"NB3od>c$'"Q>Y<km1F5D07f"r#r.!@;n]6/&`uaI)Vomk1a?q:<H[B.
mf&2'o[h`-&H+GI5A3[H!C@_!p?;*rb<k+:d6?7(@CcQA_>_Q%/p$l'#AB&:-Yfi.AC,`O&(Q2T<\f
9h;9ZS4H&Dp;eW`(i^l5iG:-*:cOZ#TNo:0E(Qih([0$U0%\:6WIp>D!RAEQTEmY93Vo0GR^We$QKN
?N=&h?F2[r59"8WHM14Y34W%g%C0'LlV@`7lSZm?EhW_b,/@?ge4PN!`O@j3P![jQV!J1dWfcbF^Tj
Zr^%"t/i><_kTXlR;^@3=pq50@ln3j^d&=5Y93Y@6Aempb<a1H?_NO;5%bpiTYn&W5#[N(Tt'c0Vl0
G/FncccQ(kifbT.17L?$f``pJg1[a\3cMZhZ,nJeG&m%cpa0*0"<S[:qqNG^0q<69nL/0*ZOKFZ'jb
8C%n]PAlA\7%p]4l'&O8o%#oB5CI_W\HaB$LD'e48t6r:$W9g<c9g"5f,9.4uQ6&NHDuLd>^67(;LA
0T07_mDuJ[^%9b,lH!q2ff.ABll:nA$GZPjq2[YNDX9*L_=luU9uPE+`.6B*L&u+>N1=rp$Jddg.@R
<]R0(B[AWpV(4%]R-I*77)GgJinAb3EgoFsV(8Yf_=(s2t0-F,"fQ*ZgN"$J(bhW3=Y))MZBV>u$Rq
fXdMk\5q7m2UcZAcq+!(R#Ge0HQ(5-b_GoMu4;5jnA)>K=pjZG_KiZ_Jc0<gI;SZMY![P!/[UoeHV8
^8?St;c_p:TSAqM+#g7N8E;eV]GJP1\HF/(sNmjcWN=<_]B*%:7SUlKaqTo<pB2$WjJ"ccD>g(<ZE!
YDq/[5-4)pHNBVP0*F6MpWUn^4I7nXq=+OhZ6XQP5GSiB`,66ZZpUd3Z^3<h0X0HkFAOH@T5c!YfXl
"'<W7/TC>LWMmKDO)@F)dDg@&5@L]8T!/P]fc<(NDH0>]@Mf>lFS9S-IKger?fbJdL\Tjq;"E27j#G
&bJ:fWuYe=Pu3D^T>gEUu]1YVuCDVK0n(QWKcJ,[tO?&rI"obM(l7paT=nTLnTBAm.3$IiYK+">#l%
$Ms$O$gj&KBiS!1ScuFo4o;b:udu.Q&S9fRF<W(H7[H`8$_'Uj0J]*!("@5mOh_Tp["P^*_D;')mF=
,5oYQX"<*Q'79>D!IhH4<er;5?j2W[4JFI8Rk;Z141Ut`2`IIs$gqECS1"/O_0gW55m<;<Qj?njaLQ
&U4_PKO[%2cPC(#2k]:]u/X&Ipea=<'MH0g?Hf6-loA*W)KB=&;u<1'Hfhh6pe\j"5o<4+"lBM4P-5
bp!%6aKYK"m:_9j,>_06CK&;>^L.>53l_`H?qTHHO`nD]Te/"hGS(i"$LS7ZjE4gC-up'.Lico\f\q
q+h@QA<jaU89jsM169j_2/I.E@=r%D9;.kf`q^]HlU>s[9_ip6?_Y%q6=5Fg+Y*'>JVRT+.pXjT4G"
N)HCk=s]q41-:Y+q-3=b;HtP9$rsPoqo_uY:7cARs93j!Rf!bEcM([B&C!WL(MX.eub@33mk]AdVk1
K^sOmqN]PS027HYA^U-Zs,+>#*NmP0C?LcWiSa)SDpYngNe/g:,*m4X>-I^E!7tcq82M7Uh^'>`^[D
=pu3tZ%coIq@n:!9d]Y:k&VT1+ZY@F2g([.3M8JWTO(iOSnhC>'BTFSAffTCU71hXK1l2R:M0fSZgu
;EXg-0+_%kImLdPJH0X)39Bm1n,;oXmp[<<[q]3Hg9<q/pR/F.oIL2tIV&C&YU-/J2O"R1KIST\6.B
d%4.TB/-d[c5hEChSbD19-49H=6nr@E#jS6N=X$;'jWj1;>:cS^<4.lQZCY3Ap&rlsj2ns?%]s>1ek
T5IEKT6i($QPFeKqR"3p<]@M[(d_sI(=b%XsH=2\$m2e/#uF=T7rl9p!?;B,RFe^?WcsR\BpEK`1Hb
s2igF]iFGW^6R7ELK<FW+Cp;8J_`!3dc^gR(mB>DXkqj57>WR]F3J'N]n]iUf.Id+/0eoY3kf^hp8P
#i6MEKeY.QP]s+uBD+C=3!%)-L6^I2i'pXa@:/=\8f!;lhM&X`70iDBPR(%]Qs?D!d5k%sdB4<EH:N
eeU9$O-\fk!i4N<F?]NE*kXqtHLkC9Xd`i<IA)fOI^S3iQOaY\RVK[5YhH:mG1MFd?\gIgq3_Nc:S"
Wm("h(dCUUjas6WN.PE(n!#uiZ>0Qc_lI:)FCaJ>uI>q;bsT9o/'c`JS/,8n9uW6/S7`Ggs-e&s=%c
atad6/j(XJRUJ$!<N6$")An!@8.JJf_If6=&_#_R]KMm^C(T=YnW@Z/m2Q(l:."iV^%3_(.k4W;OjF
M1Zh&K0!b%P#o$i4p!@HJ%Ndc=Be'Hi!Fih=Q/@#dPA<']578K6>>M2NWFV"+ir@9lG+s/;r+YiHiZ
#%kBjqJrhoKdDX'nmadXbg3#'oHsr!UoS*a/l3_#?\;T[.SWAh6$ke4IGUJG6_B;Y1F-.kE<ci2X12
O!u"d&nln2X-Kq8kXf&s)fDTcT66V/X$)7U+sE.J-ePg'3M!Geasrjn(r;)U7_ET]9Euhm6[NBe1HH
W/QdUA>mtomZ8S#h+D>fpfmqaI>hJXuVAr9mee^oi$7"sN@k<cajIM]o=.fT+)40'i8*kZuV-.p"ms
8IY(II4H-Tp/A@_fCq!3LqmTcE)%KIAmg7MS=N'X='J5GI;OH(=.\LKYiDr'K+$aJ[kDSgrhM#8Zdt
k77CENOK[`-d<Fu__oUc*A)mH<K,"\2`<d3P<.&h'&sO"r((!Sf%6O,NrGt+u]MS8t]m$Af&,#']>_
>Ymqjn1Xop^gXRb(OMj`TJ_'UpJONBEO=R/m?8T?g59fFf5?2DDo_.FM0d:n;3,_Do)LHN*Q\<):Ud
.E+7(/c:H4Df9PqB%%6W1/W^C*'97g;MZ2^i+E-*a;6Tk>ogVgVD(/kTScfsYo`V/\\?//C1Ts\Y<m
#2NN7\f*n>C8!t[k.W"n@Bg3/c<%&6UHibAlWX<FB+7/IsD9aZt#5SSG_YphbD*t4?Wf<4]sD-\J'8
t*m5*[tS,n/Ir1[k%41],WkNkH8k[q=VJ>0+GVojtXrBDguVV0+Gp*FpGlN^%V;bh`S=4_Sl^%fkQj
T.*p^mlf&0<>Fmp^HY:&,L"H0U2Dh\_r=05EcGqD$o/5$j\OM:A)%a1I?@);6enq<.Xq6h$,e>rh$j
udnLR3DN'3@tuj>!14L303o9d!/`>GSjhfm1[MQCa=!_09r?W@@rRSNL25+;U>15n3^?OcOfg3Dr`#
EsD%2qj)`pDk8o&S_'B4d#B_jgR^/$!VekZd`dj7Xm#b>#/C,^EKPX\YQJ<F)\I!U&g/-/C?e,n*uP
ge]3g$@7cTo%O-6B(^p`LQh48g.L*Pu!k4++uJ9A/>8`@Jf([-n4>@'TV*]SDLXK9g.6-`PAR+pC?>
*A<BeR).9Op&[YKGR*tLh]mb+Go(FZuu(Nf+,1G,OoPV\Y1-AbkS]ehbr^X7\WGJDMpR]L^/_d>KmR
$R]6>`ZV:Z7?\I-1#hG-#*r"'/QE=CU`U![,$2:tEia8F&RW%BuXs7.WhKYFZ#ciZ'&gFT\)(oQOs$
0:Q)mXEHT7c;s5I-O,Tdig.Is>QIWeB:Agff;9crr-f8Zr>GDE'8Bb=J1]7GrbXDYY8uJm&\R*#9f@
csu>qHssRR`#EA'\cj7[q%-@']ti1;QA\nP<]XM/9cT8Nqaud)dX=8%5sjIPdp1na@Q<#h2de6@`3G
iaroqJ,'CPgZgZIPK_e`2"*+K%hQ<n6Pk1Mo$^O;iV\nT!n]^+1q1_5s]@nnHF39O8]!,GR/ORUWTZ
rBfd*bM&;eo,$tTo2/AQ:sp5kK3j&9h:(,-,LQ]ZRgFlcb?X0,kG[cL-=L`bu$6SN$Spo!ej:$(d0S
!63H'&;:G8I!Y6)O-nTkPlDH!L-%%M4Jc)Flf!$jMj10o"#jUT`<@N$)Dn0T-1XGEiWGaSZ$+tWYRW
!TNfl)92qO'.FbYn(s"6g2s*.%O>XV`Ni_K\?6of%n@c>-&3.0u^NKLeDmN!UY>S`As-N'M(?o_e(8
*lk/)pl^1/%T-V(%#70>"8kW3G=V:J1X8kRSZuJfKK<"Q-R1hY^Q^qi$t)L.[mnF3KS9p>#)h_CT\(
UM)[R>^#7@7,gB7C_IAGuM[@aB69Y/O.-:c0/&(Es%P/R)B>^?lqpk,^UC"f-4:q![<Iob#0hM8$=A
Ph\j6tX6H=TpGoc``1^fA@bh9t[)*#tbQr-fgo#MfRrlVh]RKcrfsgi!Hn,s7tPVL#o6c'\VrbF[#0
=Z$-UF3[d6ITah%+S"g46h>3OO<HtmRDf#0uNeR',F+_c:M3*:!9BARfTs^YrYIkiL-?O$YLq@L"UP
@%7nK/5FjFPtk;]HGc$9-1V#b#&(XH8543jNmYT&W&*i+S1#j!M*g:@iTeXIiX"dnDGEXP!36>EF-g
0]Vl/^NtoHYtNg7C<H*!R!aE[If%ljcb=Lo)[VfZM'!'q8Vq`^r`(&O@tC2YBQSh\i>XNA1@(iM=>t
2M&E2r;=6&Em7\a'cDVf\[j(h/F*j'tdYXgOT!LmffnShiR^P-k0E!qZF]opkO/$Gl&$1ViGTI3:Fb
Uq.gl^R$p&Dr)u.7iV6"K%tgY_eZo9A,o4V^L8>gB%XL>fE)6&CD)=Kdc:G4].aTd?dLP-V3'96%Q7
sT_m7BJZUa4)'W[p\Z(3R!*<^<rOmh3<rV`H+8*#kEE@4<^Q>a1&V7U?e$9\(THZBBg;^RTl<C^(E;
/e,2I_EsLDngon`<\+AWjI\QrN]GL!=0bV5O;8;-\!WPlS_/bbi^Z[Bt$C"*F50j"IFGZS+3`ls!i3
#m%fDE6G[gVbYi1o&3L:LHg3X!s/sobe7#+.Q#n(^VB<0bpA;i:RFb?fE34"ESE):FU%.JmNpF>OEi
1Lc!*Z/-=1uj#fNN&A0IL4mgYh8epCCSG0_0G@:+H5eB`X4)Qg-Yo_mD%gOUG/+0]*>1#`h<HE=PE:
QQ6VU?Y,N`TnrV/%iQtLP7X%7[D/R`$[0M#B:C@%J.A,;F6?(J5\C!%i6nAJ*r$hE/(K[Y$^]^(J="
;mlc`ae^d*"K_>,U]urF-Qf7\[TE\OAke_5nG*4)f"!:aXHtbc3D,%TA%j6Ets+*OK:Hu14pRY8B1U
l1&+12)ICD-jZI+0As1=6@bE;ka4WVb>boobq=7jCMuQ>h<F"o,p-`A>/6JI\%eM_$"%>2p<-`o'C_
KArojo)A^-d-ZW=A?3,8&cs3.J]T)k!o''9#Ypc75,)h<VHp-Rkf>GsQS/W<4`dcj(jnej!HKRbSaS
&?DZ,OW?T<T5BD-eT1I8heLAgT@hogNFKki\GRNTP)YpeITVrVLj\VYS#7!c86m`i49YX32^!eq(^!
+Qee.)>^"GPNKXV_%AQ9Gl)dAk%O32^Rk[h`Vhp8m#SCRKQbR(`:a9*82=-S8JcHT?bY^"=/&f#YP.
up._rk/&EnM3Y/A)DRGQ[n:i"s`!_<"q(/5P>6I_No!rF0SOoB_Ki$;!l\;3<=9X7CK;gG6o?Zf1<R
HoU*B8RI\[O"#]_R"HE64pJ(T,D<RkuSD3P^-/V8FL\fAs9d+2AUsnYF+bKfNIir254!5IR_c]?\:d
&.:ojF)\'cCARM_Kr3;[,o]*".O#iq-CHK-_8:)BpOW+gXF]tj=#WSlp@3ZqqSY%2$o"AIVh-*hT7I
=iK;1.UA?#pu3IPYRD&YQ][&gld^b(Ia2$I%e^*K032F8ZO/9Jl%!k)XG90/'#qo2\JJ,K;2;u?g\"
n-s5,Kh3T^\^eG&O]ds!]5Zfh;A1KM\t%&Gf)(UE?.B;cU1Hg9+?+fcbF^dJ:Cu>TiPgY1Y?/655jc
5YIF%\Hoo?34o6j.^upsbb4V$$%\YO&#S]f6q*D;"&+t$%-<;7&ghjlUY])=D2RO58Vg[q?f/(T6'j
fl#Ub0`,S-6%t;@Ca?J(P>P)ifDdp\cE;6Aq'>T=^@e,g<FleCG8lUTI9tU9O/+HRtZoi6$*;cI8IP
L`<5Lb$f'sD0SO,!4HW9NGX=hP7-JZ*-59`!'gNU6pXe`FiS4#5Ic>CA.:>XE'2[,MVSKo)kR[eCY$
/mcqiHu\/t"oS0b,`\u6BH9#Slgm7pp$U6WB],kN(;*NqdNCc4o+&GX(nKZHCf:$8Dq,kUR_q2jNBY
<@d=63dAaS&\YtZ9h\s6)&b"^C?&*eHD7rp_(q(MlL*1iu$Q1`fn*EUTO9G5CJ1%jNSY+i&k@.7:6u
,m_A8XoD>ekTNX?K3+6e2hgFISc[P_*?To(=lndhi=?(UqlTXp`ZE:0As1A=*,/s6I1#SSm\9JC>S/
LN0(qfO-q*aJu%ll,PprYl`8Qkh.2f4qA6FsQGXdVaOcojA$h*#)ABc<eP;+<R]'ZNMkQ^'KpE`p5)
WL;?5A4A+N'Ec%;,&5E1Bpg.g#([Y1(iSV/8210Dpbe5s7.E3shYN4%s+"C;%E/@iTZt7Lg68_REJ2
,>0O$EZ7/^6?E4.cMXRaWFO$SE(^c>C]fI^H6!%ZE0T<[ZGFf#YX`\s,)rC<+[M27RFPV`X!_hZ3/a
-Hta#V?0`jZ3p<!P`u-pH\ad87X,9`s!Rq%1Y$oT"k!aWO@,mI`l&KhCD)a@)a`d$bujlC3.peJ\c&
8kos)[m5`(BLO$31S]:";?!p!&R),;+#rhaY"@?b`KZ4E5q<=6\g4?8Z[3'sN)k5R]p#"Zcpi5n[\[
\,`?,DJOS'U%&2?C\fO5I]en\T[S")&+9rF=[KKE=0XrF;$)O^6XHNo+0_#c*-/4>8)KdHr;H0C31F
P"mR\3P#HLZpuMtKa@V)-S%FcP_=.C"g@CNKP1oL3KYf-$%aK(SCpc0E%ijV<:W[j[Prmm\/,cWd]P
e[?$**J#&/U;,l$8R=]Bnr[_$PA\]r`tY:T#GJcnLU<4JFc9?!\KY)#aKrJX2BddmI<cp8HS$7WapV
Pl5WP79Nn;W;V^<Fh>;f5bI#AP^6\"V!.>4JRGiM>?a`(G3cKHgebQBX<CB1F)KI8U'k$+hfh7U,dV
Q%lg,RhA[b&,"tc<4CNc`A?\9YJpF@i/3*J2"pZ;.6H'TkHtJ)j\)XBe.E0/g#uh]D)lOUU*LfhCBF
0RV9rdGKVbK)lXMmJ2*,3WdN.3jo$.97-gc=$j3WW?+]SelnqF$_14D0S%j3=>)=cn.b=HJG1'X.:T
aP`MU(A7nUUu8d\r+V&l:dt_p"n7X>5PW$O%G/j5oPDe*D@n!W_!l@+n<+$W^HHqhZ/78uo'q<i7Bm
TRV>Ca-,RQDE!X9;OUatM^!V)(;_WO.qIf9--->KrrkkCBQ)l-##G<_0uU4$3WS28S+XbQ`h2]n?UY
&7e=5_fQo)/-7-BO<B]R=D%)*OdYOpj_n+@hdO)X)m8S^f8U`M?=\85kqbSTpXl13EuC*mlU\)iR<<
BL.lP#6Uq9*<^fgrg\3'[EKtD@Z>.*aJju.WZk.&K`,d=6?__uSlt)+GSpi^10t*&gTl3?5gpZhH]n
U;sS8#k^Kdr"?or,(A.j,U[[_Mit(Zfm38HC'0Y-gf`cL>QG@a]*Bo>*-W_mB6VX"pJ:KU?WOo%0K0
n:qbm6Sr4<1eWuq'>X1XQO_u1&p?22*Cc!eA8D2:6W]sDC<d!2@#_t/63G"]8dokB^qcO)kI57Nm#g
QS_[a(%`4pD[<DURFNEJ85H9td':t.RMT7Puj>#.8[-&Zdu##YiP<k\N;Q5bssTW\/,+$sVgmGU;CT
%tr1<[aE=l@MZe73K6E2/o,oq*821,p^9Ao+DA&*)fh$G3!loScDG.'Uki0B412bo2i+Fp1p@R@u5t
*[0A[/bLTTO!g"(IqgtTsf[0/`IsqLno_N^Z(=()r8X71N3?UV=-rqWlr4N=goQ9b[7tb?dJkJ41Ub
L)BkK_]>AW!(HMjHmWU;G>*`JttC%j/Na:pd-U<5PmY'%D)fdU0f654P*_SK0k,I_/I(!00#$bfSOW
h<`<G5.HBdobYRi_U$nc%05Qq0T3D[&h1`]F1,No0^I\%CkcWS>;U=s#N<I-4^hNm+)98NU(]Xb99$
^LSu(?Ca&`C\\5=ks5u"ucT"FIO^\Gn+Mc[#/!rQFEZo!!dE8lS<%\>X_L!Apr5.S\5OMugXDJLo3T
!Nf)XlnkRG5-?`L@GBk^rg#L3alYf`6QMC_=4*LekogoIqWe&BZ.,BI.KT_EirGA+ESeYBR*"g9iJn
4L%kcd*+FXLH-e#R%&S&Z>f!Pfc<K7DaI49-H6tZFs,rJN][>h/k7/67W8=u\MS3fNT:OLh&2N<s"I
1UL0=m-s&d%jkMs'NR.\nclnbc"GU`DSU;P!/b8<5,mLq.usPULJA<d.8>`*]$eE^jPo!q3t)J0hL9
A^T-b'&UKNa5_u7WV6Q?-QnHDZN-$].(#BC.s2%kUNj47ng)\X/m6B_\BU&0G^Y5_Sht4pVHG&M(>R
+&$Z[p^^iPa(Cd&O^(_[nj,8;^ORkt:rMM4)$Bcap*,nWqs-?L.qh^9IMNSEEAqp/!@OgMlL+]e`a^
]p.BDnL(K;_S]m[9<PFieS;UO6JP8E@A!2Li?)a!$]pFS-F25O*kj4U'5hVc'_AG1YerJ=Y!gg'+3$
9\&]@l4<R0pIm8HE38Dm9M;q8hQM$4c-P;]`-,!er@:Gl?[q&)0k<?G"p?X?:PtRtl?K-e$LHnQ%*1
lEW3Of[eK"+pp2jBHi7&5LC$$qH"Z\QH-_:=N^.iG=fq4&!P7ugV4q=H;(#gL$t((b9nF!K&.!&!%i
G'*H!!]@D_LaZAis89'=%>ZYr2[LtS#$K*Q$6_aJHi$!Sf4)LZXkBOJdb'5ghd@4e/*d7Y$'2-([B5
30A==:rVPPR]#nA5nTlI=q3A,1%FqR_f9>&<CTd5N`0@Oe!Pp?e6+8tDGjZm%S':4fRmP>R"F-lr5]
7'rV#'pWDd)UXD6h_6$TqS1O$X`]M7X#ehR"b<<T*eHEgq;auPJ>ua(QL6/Mr6?Vr-\(qX$7sQj,G^
V#4WJa%h,M7f+2r@na3C7pq<bT<Cio-0L@W'$DB$N*-lfCos02!_.>'egG.jQA%95BqH:=\nnHIO(%
[.q1Xd!SV=#B>DT)L64f=?+&uTI]/rM=`NF3J*LKSO+3j2"/.-889KSAWm5lNO=31;FhP"*Mf;])^a
26cF$>=\2A.qXB0+gO(,kYM3Nc,toU-H3!NcY%SL-l^kKCTj=Ye`rm'Jk8LMA<=c5808`k#7b"k[,i
!8NA67q,63,h]X^&"_%4GA<]t7^F<+&g9\!b\ls*NWXVOE&!6.^DD/fT*TN5#tD9!s&U1p"gHhWd8%
6K1^!h=?PLBefEY$Nu.9&Y-+PRs"`Y)Tqj;PX+uG1\`M/jVM5GV$$1a`5I">1$s]@CVuEoIBZ6\H^l
X?V6$&6p^f??WYg7EpiqRU2uCGERmB8d%^,_1npprp5r^U*jKnU1cUmc+_]]jA*#AWHk>Tg0\$]KHa
i6])%mY!G(5V>0-cDo#&]03,d]/XqgWBO2t)5,0"47PP4o](^4*ZQBOa+LW=TR1+4Udn":E)QY_'i&
K6j[C=D[Ed(*"Wf9)].a8lA7>jV`:58A.srqO*8r8I=@4Wl"%TU_WDL"f+=2cZ,Ms=G$]S)QKu)G@F
%d`Q3M@I0TCkYQ<Eb$OC]VR#q58rli9DZE]FI&>rDE@\bKiT#+0`Xc-F^-H*$Y?BCd/jRj74iNi@"Q
Og@R(_1PF($#@mVtlNMN7)uKkY$dB$kbVC>kVtU[12NuiQ7RZCuH]NIf96)3n8C.&#0B$jIh&VVm"h
OnY6hX[>_Q+:B#ho=RD65W;5*"$+TDlR7+5HRV:G)Th805IHJ(g?hr](^)OVcjdlu9KkL.@5C0a8@U
jX.ThVA,l@Ji:BE.e@qp4<*58:ea!86DK,Mh!GoaRUfj<@9_X$CpG=kQ@WhRhdm3u7[u>j^>^=:HCc
\gA?>[r`6q,QI7o0+/$nA`NH_TMDV*V:PsM$aq.#hhOG0k(`26q%X.'Q2=:"GPCOZEuoEpMrmJ*FN1
Lo(,MGFjq)RoE&kr[\kGh_e[g31L9W,YcG0"mqN@&-/^6FfjJ:?IURe$D_Brfo#N[L-3aBVUSuZ'#k
9AfYOd-T"///r4+P)b"9gH0RcnH'o<&-O34K,U]p(k4$jP1G/CJ\^l[uEZm*#us:K8B($T[b)mWJ;,
gokPJnei,)QXl#BK,!.2,2`hlq<:@b\Ng/om:l=RB%Y<\l":)VK=81;#a2Oo\4_,hc5lhBR8d,V,Em
&L@[MpH6Rj"GB"g'qp#\C!fH3T*=`rKG1S='Q;4ao6qEg&B4*m<K6rp6aFjW=mW:%YEA/"@03f2f6)
-.:1<87=dL?=imI-K7EbFZ5W,`):Wj6o'X2]JmK%^W[TaSiB[>^7[nq/MGbfr?Sb4D(ZZ<\F@S0Y$+
il?-%.Y+Lb_WiY-h=fS_DrEYtiLRa;F:pPmqp43m2?pFNgRoXj4d,lG^>4sFKpV[&g2cq!O*582]Dg
R8,Q6/8t7bNgI%@@Jo]YLgc'4i+X#K"]j!JC%Q=Ibh@4)d@NXhRB[&Q"S_3E!RO&b+>,^*rRLEn4'b
`PJ@B=CL?$]_a6Uh)Zt\h;22m$EEbNAFY>=k`m*,)-r%R"8)D#e4!Fe6l\iLl:Q2blaF!c<X4rEt?S
U3r`7UXPQpnZ.c=V?2bB<;n)7thYW*p"F!a1BGVs2Yc(GF"=>[1)GE5F&$iGI1g!KBc-2K6W6-7(%#
osEZAfm(Yd"R[_]GjT>/Y,^Ui9o(JF1;C_a\l4aIrK*\X'738H.3_"XcV,^F?`?c5jB!`s8UF!)H)V
ig,cKKi71K`t">?UZ2Q]&fFA^_ZfNrBiJpP($:ga@PHW+JIWs,hRj@neF$&e*;Q%8L+,F?bDRKTHfY
]EoSn;Xc3An9S?pH&$Rrl^$%,O)`T&+jrS^^$[]/B5=#\ITRSX"5.^05rR6H`#@.43g*`PH>(R%a/K
E*%R&'lpV\Q[q]N!1EGmdcZOhbjRAe4R:p(S5YRb2;[_&?!5a.M%-)CJ_f=R$j-5-e\A>r^hOW9k(Q
?0cLR5r[AP;T2DtP^IG@1=>%7s.Gi>mP<fG*sj+;[F#%dFta4qL\4.+u=Cl,!`IkT,>m9_Ug#HnraD
T"[B>!3h*/XbL)NdIZ+YooSXRE3UJEHT-nohU"<(\Gpqc.nk8??ge$WF.bRqdl;5]HMdRoX8U[@QD.
Z?=)\O7=q+am0nA&$D^d2,*,-?.;Zf80N&PI`oUe6bi1b6-*CS3sr.q!)h0o="r'(([Dr#g)a@517$
j[`H1EjS*bP\Xs+[I:%I-Y4&!L;%]@E*BA,6*2P>G:L!(kno^^l,Jf>Q@uO9OB4q'8ck`PbPO%g[KX
Y<?JRWRK:%oP[a-KjGrY]M$'hKhe<h@$OhiJormkYd%t]U$hI:SouL!Alh47'-`bU@UK*0bPb%1YBB
fHp`&=Pj6)]&.lKorH+osO2+U6k,/m2G0^KF2uea,#+5uZ^Ul]KMH#2h^%^QfT$*>!a1G?0"k.tsa0
af0$`G^9Nka++fQRH[X+o[I*A7Sa"*i=U%;$")c883<nUgeGTr7pXI3,S+OU-^^gaeebu&0HObi%;q
TSL%?[1fm9s**5^7D%\k>I"rA*6g\gu+IL1-R8-g/#?sWQNQrC%La?l*)"U@L$LCu!?,_OeaPT+ZN\
jjNJ&,3&O*9W&"D^(soqK`Bd!jlA7AD<d[AiFdg!Bo)Wo@[ll`5b=;/c'Ep^@Ia_2$CTjJRJZ<1'jf
piVV+@r2=/hmW7-+S-m4]K"D;1Bm`8>2nj<"_V!iNqs=\#X/fD0iF,*I!%44;^4&Zs-;Tk*@T[>S"B
,g9.,QA%4]JDroB6E00U++6OPT]V%hO=u3I6)Q#9.)D=M:F7\-P7XTDrBDJ,a7F;CRE"\F%ei,Q`s=
,hTuXZ&*/8p[ef+m2_]S/";>K2N[Ok),H6/"D4RMD9,:/f?i)"QG2_.'P"BTnHMi>^G=[R=IBAa<e&
66Sbd!3<B2I:4d)PNQmsW^Z2]nTjJaZ!CtlO,IX+B,#R]La"=A9"0>2UVl,AjcmB(Vm6L#uH3SbJg+
`q\-2'V%Naj[^p/o$E&$C5(m,1KK#Ca:DE8ce7Tk0;5s]OK.F:S4V3l4873@EIrQpjcS)JN2)<i#W+
"?V"#_O*D[X].u!>)k8s\RupP*Uac,.O\[9;h57o#bJDVrS<JUf;Y)nDQ&Zn8Z_,Bk,j-k@qU-N0$5
fJH(fZfl?DJ9^&8,`%++=.IF_2:f)TEI0JT*gZJ(`2q()7]>41*`$JZQ==T6P!A$/6Z!#FGPHTVJZ]
^;9dlFq@2RW<ZNC`;B'i@:@jlpFa):qDl!?E`QCVJq3A-0@l%hfXS`jm-Lqmn@^3M_OCno_oOJo<.G
L,dht%c*/%_0]P>EMdE*u8*D[;h(GtARNsejYictP44U@p#R."]-H+]=0`[`QDe8c7U(9D5j?Il0OJ
:ROc?,ka4F4V94+bH67IZ<ZB(^n%s,!*c+T^73;8q9(5N2UDCk6eX[@7)40kN#mN'!5.?9TSbeB(UC
d3sZM?Sd=T?gKX%AMi6&LI>\oh:JUO!G3pkMAs&M?P!_U.EI&6;7fs+C=\V7Ifjr+R.hWO&$kJnl5D
aHUmb?l@-P%94BXpfEaZsB#nZ2%QrdGZ`X0b.jOJ)+<Tfg_g6a%,\Qe\+l8&'3<81_K8Y$V$5E`b,e
enIU&'U<@)%Pg+12aqN.5UCmZa03kmeeaf8Z(S;8G,?oiiS07[6ss#ZBmP_N,S:+^3ZrF9eu\(FN%4
f2O?LcRpKS,X!sKD:;BSC%4B?PN']?:9H$f:VB@d_^dCPPRjQQ,ScJWrYZ6!3V`Yf(OAk)\/Ie(MHh
<4#GfN:UI*<\WI]mYNhDdReWE&\haR/B:*MrP7AQ^fcjQiNX[7[TI+"D)K$9EO^!C$n6A_gEkH[9f$
UU[c91J*$,?V$b^c:lo8>FPkla3;&1ePl'&'\#c<<g\0)r2(^!>h#V7%,`1g7]!^#_C/<F(9L4.de9
?EI^#hdZ[6YFfb55G]<2,:I<R]/ga8s5h@(]SUU\1!sENGrCgoJr^>nb=-K<J1;d_D'r9&-^\/njs`
Ise6)ccNY2R%Xd2-.qI]BD+IZik>sPck%?diQhKFX=UI&Eq<299MJUM97jH'@1s@i:+DhjdC6/W#<n
6&T-aGeo]*4q9o95Tikg;nCu"JIhW%dL$F'n6Z\\B`&qWmo@o4V,;"P<^nkS:f0f7_7H!O%W;J@Rrr
DTQ&FVDKh!N@JpE$2!jF[f[4U5NY>>8r3MS8^p15[.dL==+2P7o.d&<NnWuW1@dhJ=o[8K$)[Qin(3
'E(,Hc8mfR3g>[_.%J+4'N[sRM\V>+\hL-2"Ud9S)oFG?%8(8W(R`jtIoID96:j#Abf<`+-JW@/[8-
G;)M$X6aTJ3I3OMhFaJ4m\>)4-e*)oKMbRRN%4roEEV)pUcFM77Q[<SOFP2UY^V+uP]SNmEDk"<I`U
DE3E>TC"N68j'04S-h,"^\qPA\FG=,E#BeRfak+K>!X?!KbAT4m7)2<TZa0FVP"Au<^G;E5WZbIAS/
pqGinEU(>APo52Gin3+#jE[KM5X/+L8K.Jh0\6@sOT2['&_Mh4RZe;^[Gl\u?4b[.bjg=Y/f2$E>:!
*i^]+A?,1:d_n46t>SZ!$hr@;"PZM&f_.=[M%B:f%_*\R:>fp#W23uO1b[s&\O0`.lB@-<eW2,LDg<
okJRO8"6h[8'9'@/!5L;(?;0_I/Ie`e6k4II`Cu7_;%FDG9;E'f4A"=MMrq@'5akJ%:5AbIWbN<+TE
2,.-Lg3$h<3qFajDS\:o._<NK@ff\'9q5U#1P&;UcMa]o@3^eUY]$RgOU)?3B(=%OmDeM-rB\S(rQ,
&LRe$`CJi?mD4i8ccp$R1j\D(&+DQ.^:mM#M/+K3;HS@^D2d9Sgj`lYpCEp+$$>F#J+6lMcu`l?QpB
.)<impE>+BKJ$1?4dr[!/"r.G@J\5aV5fbabL=^o4.Ns@"#^E>_"QmmBc5/%:8LIuqY!2uYc#]*8,W
lConiD=ba^kmsO3SmR=cT0E/jG8^!Ya]O#qtRA'iQP>pQ`-++roc"HISjk2n3H)_"[**P8;)_O&f0e
#G:^,?BB<,d9+R-d+JJ/[&JtMDR?fe'&b/GD\"TK7lJ(9\S+Y,9TEX'$VZa^^\psJ8DDZ:M\VU<Hi%
\o`Dgpf&5=QTVWXo@g=`#1m0GEu.b9`pZ[WfePRqRB#5mmqp:0(gpLgX_@Z*(urK5bkhIc1&qD:leE
3<cmuqXd\e>VRE2_jcrD5IWHZjF$f&=%C;bs8EOU$!da1f)0)?VI2\,C!M1Xf3nsTOI7m[m_*8tU'8
)>D'1Y<3ESj.V0_"WG6<rr%b=lJm>k+O0O+?o:</"lIrTp'8aX559nKZfBV_MT]gttF`MG8S9$*6+n
Do]sZhc%W6->`mO0-^0T;l7"%OpNe6-0G(8QA#p@TQ'.6d<dF-OLc-6CgNH&+i3b!#Q9-??8Zi[d5F
	^Vp'%;N!XJ6ifcq`&=V)@.tW%8K'I5Ic(+RE<Jttq9)E28)O`^L`1nU\EeBg4@TgCEfWR8OPg6W-&@
	@+D"VFta[dWrO;,_6T+Dt)OSGYZ:%1O=37+g)K@-[DreuU4GpT]hT9JU;=k4]%!+F=7>1>Z4`OoDT4
	F%#N`XUYNHBi?f#'2QCUZSi`X#7;YRIs:Y?):R%41(*h<"SmQ=kUi<1T6YV;_'<Cm,+&m?K:PLt+:@
	R4/7R/+?kb&YaI>IB!$OE-Tu#?_?$`tJe5!8,I<,O=e(*!n\3i[6.[::HH<kRDVKIA6.%$2)Kc_3P'
	ol9!FsknCR8/!RJ)fipk=@P9jKPp.*ZQNDRFr7X3^eS=4;t3/opf/#TtZ^H.$8KR;c@-3QMI,!Kk\W
	;^:*!Y?[5O?:h<]5_g3SFK@?`6csU6/[6!>,5nAD?,A0a1;YeReabR1Q)VPb"@a'hc3MWK;?1tCo5p
	o>S:/&)gJ4=@?<\,]8q#M^V>?U=WR+iZE<.<*GBbU\.)OifBpd7?rg+dFZNcZcnMtV+sLUor]R$\RV
	E(:i.`5,7UKSp5=+hVIiE=*>tR52Bg6sst2nYA88=ENk'F%/3F^eVc@AeUbe_)(NNM])Vg@5`H=<cq
	lb(PnfZ?B=;J&=Wt</:Q_!'>t4@d]oOk6C1C+bSJ;0(lo?8$-![trX\J6-kBlX\ibra(Ta>4QWiBEc
	KMf0a"_tHYsG@?;.=5Q-%XP8^`\O'C3,#o_K5tb5Qu#]G)F(21".oU/q6F@07Vs7eLQRIB!h0c1ZHV
	Z=c:Eg5dV_g0F"0-d7;^l(s*SEI)nbq;mrF;8U)SL4$1JPRH(W53)E^E@POXSN`=!:>2]1NN1BNm9D
	l(u&8@%Sc5I-@+K'ZnIJEJp0anR5s*<0tJbeQb\%fXcm[P7.e0Wffq).MG][4'np$gLR7_i+8$LlA:
	iN)C^B!MBO7BqX`9lUsnA^I+,F#*\*cN)V#?"Z1pQj\dk7U.ltZMspod"aSeAh\`6Mp2OX!!^,_p]r
	!.N!i((@L0d-Jj>k\+WC)STDHJUo.(]K[;2XVgj#2kf()(K.5<R>iD3h*YF0Yur>nEN/1C#QXHZ(0b
	qGZk*#aoX$$qj\&XV4%,["2R!0og,9*PnG<1^(EC?=tXrc'@sW>&>3CZpp<,udn86Kh0MYpMc5PS@-
	?!2uX3olT<(e1\CPApRa.CgR^B)--8YorC`0&jN8*1\0BNQrt:G%rDme]2\I?+@28T??HYm4F&AIpK
	b0T"qC,Ro"t(@F"\LqHE:@8eiABtlC.B%E3nmI4c](:/9q_sOJ"M+Nfe6tl9Z6?'#oP11"t45RC0c1
	RahiB5*kqX.NFhE=ID_\%CdfV6ED[o?ASuuBc(Tu,%o;f[&MO&p[9\&^1BHO,ojhK5/6R[>NWhMZ+j
	32E"qcSBA&/R"i#=tpR?(A6TYX:UiZ$`1l_aY+_]87(%`*LhSfc^_e?;/5Df@8VX%mlV/gu'Kiq\b>
	">f6`TZdkUm2VS`Zh)i?K`@_B*APc.ki5"3&r..p?_,bYFDq=6*<dq=I"gkJQka"H/d]9S!QI^_!3m
	K[I&8be]B@Pb6p>H$3ebr`.Xot1#3t'7OmWr3AD15qq*O=%qcPb^Yn`Mi$#k`IEY>,l1)84PGT+ph`
	C"q%hsU,L?%:l#l+ALi;8U4Xf"dk41g=H-$;"(j<6DE*+\4FVS.tO*=r58[:3jdNh*'kQ@N2G:*t>f
	JICr7._XlNGcbN0f%uCM*bo9i]X"!Fr2'),MX3^41$OtOO<a`+NUe0X8d#1[RKO@aM@`jC(uS>#C>E
	pZgeU(TeO[h>'ZAuNFtSTf,$dZ@m%/*8SEtGT%Q^=E<5_T4jfQu&p$D89j'XH4P4EW@HLd+?"]9jJ=
	;EZRXO+VX$t"mfq*J4OI(W**J\s#O>_KiX;HD*m!9c`\qU.C:!q<'%V^%A.XDH>-#7;!_XHNWk]s[)
	--X"4-T+s2$mc8lraiEmNN)gL33sR:uK2p.!Mi:N9%R;dq\n"=\F28oQbGb3'\[/X1\8<D7R62RgS0
	p%bHl^;FlU)A$`>fQpDWW#iNB.GbBKJ:%?p))8=#QjR"4$*I6:^kJ`Y_2@HgcLnZ5ot]kV,/ToXaqF
	`N7ON)S5!N:^?F&`6;#J[96=b0W"P*M!EXV#hrse861R)bgm=V\oZ;F)8%-Z=6%Zu['`I'#7k-+3>`
	*1guYIB8-Y]!k9OK3DTg?X/+Id,]L7GNgV:Kj>ST.F=gmT;?.8!L_K)js`!c\cNf4<81'M*#1PT.]o
	sC&l3nV_D6e7u:IJlnp,WX?&'D9$(k?#OhR,I+!kc!/>A>#tY;sl'Vps"rmE('pAptu%FWC-=YH;7>
	#J.(hr@ae^PD<al>>,/0R.f!X_FLA%T](R).T?;gkl0&Wb%NFb1Df)(C;mr@i>ZPnj2X\(e6@c'%P<
	<-*L^5%3XH&.lRPSMNH;7+D1oN5>lVn"5lqQJH=h90#b'$L:O1T2LSG9$;l.Xe4^(7]/G[[j/=e*[l
	^hTjKCAlLb$OJt:\P9EaB26d)^>p,l16,&)\j/1HFffll&U/L$_EoI7*I)l.2:HPM.CbSbSQXD?2GZ
	:eh48tu4-AI\rBnad,dY)/2F8i$`%<\Sg^fNuJLL&Oa*5(dH2[^2*K+<X()<^P@0g,K0.P!k*"Li1%
	iC"p6<!@ET3HO6>mpBK.!oUunY=.)C2-u"ob5810D&?8=.PsCV%^9bGB+=&R'>>\]+jZmg^T;.0=r>
	M!*9j-alobT$45F?_$?.R=I;]H`08X/O`7'6M(p=)*SgBlDo^A-:F>RL79.O<C$F*DVWhZkW"rg9e^
	h*?B7'#k5,CCQkZ_=u7t*bH*8EmnmU=JaJG:E.4_7)W_0s5@X.l\pXK!/8)"L>d<rF!%p(*n>#k&0P
	-m@k<1[g&]rBtKA)Eu9n5;35I5ieWcJ;;?Gq_I/(7ZWbUN+j.0!$o1.3WTp#@bT,L8bC1n`3b-K[#g
	P4#ID@FH<\9^M!Ybj:-7MQn8f'm>*KO`0:f=29gb[<;O@'H<We2n5&dd>!Gn-qT45cS64i_JmsXtj[
	uS6"qU+=NX4h+=Q7Wd6PPn::$gNiDi[5iXO-e$ipp!]I$WnBmig9fl_ShP^"i[p1\N=L'-!P57HW<L
	-7V4b+m:dO,FW:tO,RV`RhYoeL*!qO`PFp%SPrT1`AL9cXZ9YLJTO$h33Ea8)=d]g,OWj^OlJ"QWR,
	A?V_UW9(Zmk4!<@L=jc]pRPRFk7_iSoY[S`eOr1OA&[^6a\WX7$ls(p>HB6ppO&)*OkdS$nOmkSKO5
	KSq$HAGl'I$V?!qF&X!V-hp57Z7)?TO8/)4SI63=6ZYb$C>=[mL%*4oV!#PQ$EtKpEa[i^.8-#i_sK
	mf`VfAVdRFp@bU92HPOI@4HL+%RFs-kP!2U?<,JWl)orD..fp(9/AOjMsg[WPl!3a"\>#J6T?c:l!5
	?D3aPJtDdaK0raj*qg":WUJ1#YaQk)BU`@+c\CtM(g`LL'Aru>BX%&lrn0b5rnT3%UgWLj<M.\`>M/
	?(LQsm2/?8h`@^BSr>2,i_9B()fcJ)3M%FkcGauM<g6p-N:U(o2](-ET-R/Y/$tN*_;ArOFP94YjHU
	"eE0$NED]2e6C_An+Qkt-(pc2<Y$V`?aKdS`@@o.5em-:uRS4ClI),tZ1[4E.u7IjCM"Kds,Qk/tbL
	i);,Qq/h>U7ZjdP*.%RjNA4dQgXNgWV&)qh2:]_?oK\iT"pNuE9<oL<`8GT)=P22pU<P\%[4r=kIRJ
	mS/kK_@aB$iWYe.QOi1T"(X^.)0CBneH>T_T=<g"j_@9J'VD$sG^c9Wi=,3gVDh][q"6C0>S`!I+&e
	i;_n2.2Wsf@)*R-.TtD,j[Sg=C=dV?cJ,L*&\mtcAJA\"<4:SZ1)Vs"'foBh?T@^*sml5h$U)%f@^h
	$A!(?f-aqpc1GTPd_*>mT.!pVtQF^2cS<Jd>86h>BdmeGs_hiL6]'3>CT0?J;a$4+2"Q+br!&jEp6.
	&\aa-<-_1j<iGOJ"Bbfe4t9d>T/Z>c5pme?%h#oK^fD7=q8rLqHR5#ioD$Ose8S__T_1"f[TV=C*c@
	T&T2f"UU&.nmtJbUag)I:*A:!XJp)1:>p<Q1O14P;Gl,1Q6(6_p*(u:Tn>T?1QaD0JpsaG!of%M<G0
	V/EB<$j_pJQMPi&"`7c4><7B6%dGT%,%&sU`'"$)q2Uk`\`;uB__[k7'(R$'Pa!R]%YoWCGSL5Q32*
	6H<B8;OtNb8kOWGAb^c"aS1\71[08<7u+7SF*lY[DY]>^u1PFfHUJN/=\?GoS67sn!mL`<-qFa:cPG
	RnH=A=&+D^qEmob';l?K;'%jPp$h#G0LP`%0=O"BM4Y[H:0t)=(0"W^?Hi1.aFF@%ZN48\Sf]&PZB^
	PeJqW99$4$DBR.m_r&jA/I/6d1(9-dcNC)#3UVMkO\84+!ZlHpagBl59=-UWT0'<).*;HkNpo<B^kD
	!CsjP)X>c/.hKRNprI7%c4D<U6RQ.Q/RCup_@aF6J5qmgRf]!M&JZTnNOU/uOZXe(,5MpI3$KREYgR
	X*\G,'_EiubM,%T0R;^Y@@_2?40SH;q;Zt'qSk3th[3.;7USd]E37141'/h/8#8G1Lb#0_$jK);na2
	pUCW@)3(!DMVL,a@\Xu)o'=0F^5s/"<@>FfNVpB-]Y2QqOKM[!AB:rZ2`_cD,SA*`%]+(`CJJmhKY!
	lf9&)s$/4%][:XP91neki'a[KEN432%iW[8$&/(6-+@0G!asf\P$TrlSc6fCB1K,(6$#E1QaQLARb-
	2<3"2=W,<a2("&Bq4Z?AR4N2r?e/la_p%K_f0/Ueq@\Zr!@.B$JhpDOeV\egd^6^urjO;a1,A`W,qD
	9gmmTDus),N9Qa;rqq(Aji3<mD:O[(RNmn/(O9Lsg8Xq7P.Hru7>eVE!)(:r'#IVQOVC-9f&U/7c^g
	1;P*4!g6J.Fg)p'`"n\[\U?WZPGmO2uo=QT-:^:Po1Z"?l/fqQ(#`9rX.kO9VAl]?L=?f?XT?(mt(1
	\3Qg'NRmu!"5H^:#4YOW,C!]P*YQ@[:"#IU52IGa:%E=AT]f`,0WXT#UMj2PP9SF3-R#_>0)7I2`Fm
	@FPI\BZFm7>K*:q$!-F(U!8P5<W6G%/\24La6*Nb(>;qL;2@7T/XK"gq';;3mBG-[4kg`h>."[/mgf
	`=]'/KY@n^4ra\$gBE&CPVYaQY5c9_nGL4eH`[I'\Ws7[SsWjgW!E';k/!-Z@j^o&RpXg4hM-cipYp
	Wb5P4JNStRGTnT\Ru!BJP/V]kg)n9WU=kW'6W8PPB?\F0O!#@Doa>so1^CVs;?9uTh)&Jlin^E[G`X
	^D)-"OnklG#HO!4+.'@eTmhCDZ&J\7=\V*5WuTlk6i;rd`uee?+GL1T&$![%qp1sVL#1R>V>Q#5lEV
	+V.Zp5roJpREOO'ZX6n3/2'pH/OZV*AE/q1D8>r/Z^'(=bE^%eojM(q!dsamBuV(Cp3)eii.=l*A_d
	1oF<)97.qtY_eSDbgL5J9`^GLg<U>d$LUp\H57c7u&[q,&mNC\oMTVgE$[#")OUglbZEb3th1Z4aM]
	Ip!iOQ\Gm"b7kO*3K:dlMok%`d`$oIT)dXP9BHc"I(GgcftVfV+EteqcVD;?n6cJ1-dFf<1U'.AQ<`
	foDJTB&b-oHY3!$WG*QNdXA@6a36#If46#iXf?*;X(c.Z36D7Na,a;f=#A]RcOqo:@ZfMR-V(M*1]Z
	mM)Y[@`jA);6SXmtZ9o7)!>lb_a.p<i1]%!#h$sV[pG4[=i>0'T^_n<YK"5=4fpf6#+J6#W+M#[nH?
	Y6jE&*eet&!Sk$CK+&GVeMoMiZSiT#IapC%[V+kId5bFkKmJM$q^'ne_!_4.?YqfMT<\(:*Pd>EVe\
	6q68-.Q1&u3IX=S/+'9q$<A>?76@'%qCj$Y_@mgfc7SIVD!Lp;t;aVoQV^t4kj6<Vq>ZoTD80IO)oY
	R;-OS6g3Kb&WK7A7K#aQ>I@Sjk0;WMs[QoSb*D5R4p3&Ea`n/H>qa%a-slCZ(Qa$+aSK+^@hZYstSV
	'IZqcD/!9[1I&f<1@eXf+[3(K;P?XOii!9LZ]X_WB]lgnjt3*moBMgc?@2W!^/Wk@\m;)uShaR(6,R
	';U?La/kK]SMH]Zo5Bd>S1hRi,%5C'TIY@!f,4,39rL*PdPf?CV=;V6kSJ@?S-q>`VI*h$[K4&Xi*n
	A[Vf:$l@?$,)q/8>aR!>fn6hKVa"Z_Hab(=k(*a4'bGn;b;0Z!g)tPh$[.]-NUu<rnc_]NnK\oe*AM
	>>+1^j&_U,iq<PTDE%n_;#]mX?0kBaKe<YbJJUu1@7$*a=JP""o+k0GJ'GtmXFQ=h#/:Q[V<F.>]U`
	6*Y3;3E*#]:=AD'uc<2EdM6oTulQZUFagG%b#nC3HC$k?^&bUgKQ%kLLq8jp:B2E3:)<Q.`1=HqH\4
	M=3s(e/"/Q_H6[.fhUH^6o>rDc'k^jV6D4W4\I.*/EDuF70/D%Jo%RQ%)0K(-M?js`/V\((HMX6C/^
	=0dNLUQ,NAh^IR5l5%iT:?[/SR2I&jY<O`//[WOo7UQM]*YB6T$rU8Ccs5MmXc.2`aQM^MqtE0krJI
	i2u>ZJ6hm3Z%us6A-Qsl0ZQ4j<hgH=fc\?bBhS[RXI%;8$9YR)^^1$e"97'@!5nWNio*[`TY[O<J?i
	Q4J?\XStPaYi0b%5(!V8LU9Is+22j9+4DKaD2pOutW`JEh4q[BsFNRT0++g(A_ke-,A/?@g4lBPS@F
	Xoj#/F/%`T4("]qfcl<C0P7mZ'mk$LZ#$jl?Y+D0mE@'(c@]Jo`0$-r,ZPg*qg7h9=(g:.3$q8sg13
	6,L)&gl6RWAW9M0hl,:pk#EK_VKsh;eS!\u3=-7!S=j=W3"Z<Xd.Sd8_B?-?>,4.Xd,TIkCC6pgUWC
	TN(TujC_^6Fs(^K@,_t^J.BM$)S0L4Ofn<9)3NGp4QV(gM)fM!U@X='A*Mut8`OU?Do)N(%W:ET>2G
	aCiWN+kBI4aINFj.\>_N+?C<$j$E\pP`E1.p'FpE_V+?)LiVlLdK+)m$pnn=aK1VBS?-_(i7MQ0)s'
	QT%^X51`m,X`T#l&`efg+l0+Jd55'#8"cWp!$G<FUj`I8!/d&7Bg4fXX)M,lG6;u7+JPZOPK3(iJA#
	gP8[b?=*OB!-,_g%mL?*.-nSNrO6W15E/o(".$"[EQB91k/fcV#TO-S-3ua[g1P8AhM<pE=d:7[FK/
	?^MYuiOEIbdeKq)!b\"V*dMnciL36qc,dbF/IDFG:G*\+,cEh+RIj_*+rPJWJI3hQ\#pfSITIsa!qM
	'R?-r(lre0^bWO3HsCWc4:lF:D&Ep3u^l2'@!s)eQ,FsdN48W0aB\25UY&uMc$>h)EJ\u]%,V]eCp=
	Y]@e5C/O^X"3?>98lLs"I:b0Q-9dMA+(dVEMLBIJBd^OX-o&8BAWkG=]c[n'M8A2EO`6Y=!NU9"p4<
	uholIc!miqM%nuK;UEK4sbj^JsbsH`_J=,u@6h(p[8m,,gAEQgVFBam>oR)Un3&t]AW^NS,Tt[k6+2
	pP$+G9!15J2WA,*8<3:!?$_QB6+7+0Q4HqXbA<^k<+7e?Yf9]Z.qpZ"R.[;*oFerAC6oG'gZA>%Fsd
	%upGQ%3$g^"BCm*l9ShIa%h4Ar_SPO%@rf'&AINR8V/]*$p*8qeVuhGnd:8+'90O]R:)fd6?+CucXT
	lDg!$Gd@I&3tGDo"?aB(_28AtqqBLO&(&Pt_'cc$l(Wu;kV5"2WTWRZ5fcR>tF_TL:a![InT@E'UgJ
	d`Poha1o&UfkI>/MH48^'mV+Oa1:*+NT,lnSg0tW`u\DLLETYi/6%6fIV9'M/p&A*J/.m=Zn\WZpON
	N0W.@i[(Q%Cf[Y$Z;Ipmlj=!Y78lS/;@?AM@'K_oqc9Z/:LcN.&bk<ZSk0s)9nlJ</2'I;AbIBfkC(
	aAJa,,HQ,oatEXm/#_q+JU`]%q+%I4XMKC8.McC[k;[0;?c;'sq`&$!IRC;..7%+)qPh8TQ]c:cW=,
	b_>YUUnZAtmXeY^UL/,@X+G;$lo=;:d4b*o+3X$"b:t'L.<AW;./CXKoqu,Am0I3pVMo,Bn%<f%,G/
	0fEh,G_!]1`6+Bnqu<39?_o)L?JEZ8EU(::ui^bqIc:(\Yd0kBnZ2R5B_9VDr*)cFH`;4iLJ:oi6km
	$hDNeFI=UY%hP-C?ms3;cYD8)E_;<AL=)"-*)0AMlm[K"cH]oXCb/PSj,.AQ(:Q+3^RE<O8Y#&@s@A
	TLX&,5n4[V9+#m6%#ZcX1=+Gl(Eb#fUP*GrQ]i:%LUJtt3f&T=;=8DKL^_WcrY>jU,5rnKEoM=]8c>
	0ML=^,3/?PD&CKoN^ec&^JQTr]=\e>0m^WK@pp$\lPS"%>*&,!eN_;V(SO]=q_A[-un!F$d5U9eYE%
	+35,eTZ7miMeRi]jc60IP\$V#TNP4]a`%[s6lL(UbIKP>'0UBh[M4%r<DG^T"%@I:DmXHf'pHZ=@Za
	JTAgt/$<i`G]]aIED6%QJg<^BM1n:Gug"c=pr&IKF%=<;4V[<;7/Do'n;H!+']4/Wj'aTkL5MFA*j:
	.7WA,(YF"H>El3lH^jbH3KQC&[&T3Egg?-QY"OJ[U^o9[A^d%9iKGaiouoTHYc/cD7!AZ6UWIJ/64P
	KcPZtllPMQ]+9_C"<#tYQQn,"29im_4?</!0%Q*)j'eiL=YNXM.>oUEp)E*At2OFggkTHrb=8QO$X3
	(K@*-(<9g1BqOB4csm!N__qbCnS@_,:XKnOlG&!#q%'V.LiTIf^apR<TJRb$0bpX#$+sTSHfc:dbT^
	a>&2mf#7uJF]/YS>2+Ak>V3%+=e*WJ*]=KhLtGH6g5JVToihUu-KlB`P$*8oGm&#5(V;erhC/jU,Ug
	kh+IVWu`?6Rr9<]MgYR0;2Kb`j])qMoh(np5Flo?iM7":i]T^*BXRMnY`1qLceg,<VFrD5-U5@>boU
	-;,/581n_"P\3tJlW=+.#Vgbr6L*EU)pe\<4l=6Ns^IiRD?TEnI\ol8JpAOcJ]iH@FHY'TaRC@)*f+
	k&Af+G=2QU?g>Wa4*Ule0fU5?HYalY_+s(dM[V[+i^38S8s7S?-Qi[mi@VGW1bYL@*$AFP'OL&l#I\
	4]5_HK\E@T'[oZ$Zso8bsW8hU-C)%KPY\A-Mh*#h[<Roa^>.kdDX1.cEo2&PghZ^RapXA>"b=J4C88
	d?\+?YHDT;,okE1c;$\l8piG5'%+X50ColY2Go6jPbUk*g=fP3Pd,1VG%td/,o\^WGi-qa0t_G,rCI
	sf>l;O6F,t0%fJhkj@3:"*[6W9:<?S,p;-F\=\GY;er_rXB"5/.bKmp":;"mej^a6]e*._Y9r$\GW-
	aC!&X/06>?,bm%qXfd`ibf71_#srM;<`L+'U@"Y^jlft_0_>4%OVB:Ka._k"bm.UF@7_=fSDZH]7ec
	Vh.9UD0Q6et+1VEI?a"\62rc,:4p'ah0KoQu,Og22"<\Aem6(?d^O-[o`d3h<$/pn+(]EG3egkO<s6
	JQ,rd@lA#XD%sFK59)DshK0ksGlUkt3?t-q5A]22/$O:8'i4Jc*#aW-g4\<JmfC?6gqs1>&4f"GPYu
	A9T$@VmeSC!]7B[/u,1%OooT0+M;uJ['bl/,UaC,7gA?U$/M'j>SZKg.m>4$1,/-2N'`@SDp*(U6IO
	l"GA_llDa*pCpa_^@CA)p84[&r-,;;:_j!-6A!e8'!+St?#*r]_\@iGhKp1UtIf3L?$YJ5LDYP$>9Y
	gN!@`^aDf,60<@ZD$s3]8jXP\cSR_&><?4Fp,%,$qWV0oVWrL02s6N'%Pc5M_l1&<"Z(?O:hsM/uV.
	EEmPsNk`>2sRafnfe52,)5-q@'?h>$N$jqa?FGYIB#HeGm>tE?)E6"Z*O?G$9B4K=m`OB\P:s:[b&6
	;@ZUK_aT0`FsWcbMgFUm1oYoS3h&P5d@j:o"$[jS0">O21MrN/tdL#[H=5JBPNrs'k:9T%tX^H^n8"
	SHT1rKX8=7m>NbLmTe]m38Qef?po^#.t;Y-K*#t[P&[e1n]A[]`MsaRVkt[^2sJ#i&_^+pSm!&YNOn
	5TH6BDE?IcS$>mTsK6?pOi`'AfoIs5(3929OKOZ5/N)In)?M2J)W8?t5Enn]6k=59S0!.6Ng9?VQ=,
	Q0qSVO6NKS3::IX3ta$TX2NJ4IUY']'L9*Q':b")cr(nib]o&IQK^pj!-6A!okNpk:csNf+R\SVn4$
	<.!B>&F=^Wspo+L"ND&:2*+o5ns$hgiC\#qLeE-[GpB_P[%2'A%GTlh:7&V:a2<cP(W8&j8PWt>Y,!
	gLsXWeM!+p?J0>^t)<p=@>[OJ(-,Xc7>6h'e"m&elY`mLZu`)5p6c_D]ADnmldpQCNPj'7tQ,Ns@YV
	_F=J<"nR2`@'_*=&i%D1I$b`moDO#R)OJAuC?*q@#`Oh[p]uh>^n9Qk]_(d2f%*Ui<OVdUJRN!lJ)T
	@%`pQOqcZ$hB5P]^H!FW2U1%rn,fp+/VLT2;Yj#B_`KW=)Gm\_6qKuR)n:m3)G^P(b!/5ph.OJ%sM3
	^O&VUBc+.45)Jp)B_>P>8i[94%#M?@\Q8.7mLFCSVIU[ar<=:34^Q.OL-Mok=AKE9>H7TJ]87pF>8I
	gE&_&AJc=]u:g.6)6V[\`s4pu4kGDRr%dMl@*WJ2b!okLZ4p'ah0KoPfq@P,9=`re=)3T5X:_`:DVT
	.M5lho;VMoI(5J,6GLi+fV4;BK.>!rACTRh$T\p@WIkJXDA@b&i;ii$0R..LNB:aKYheh\,7o6VP=Y
	qi^3?XZ\bgW_o9#X\andR%5M`CID;>6Bkif(H708WA$/#"q;&s%h/^P3MZFs_?L5(HFf9O3YK'YZ<J
	5G4.>]V'LRAGm@\nJAV`-?C=#tZH;n0(3/'Lfd$Kj`g6fD1.2`B>EiNU_!X@D23tF?A7,--Yn@9AS&
	4jTTeMF6-,=+23H^HoMiUb[)S31em;7);i`foF-0KoQu,;;:_j!4'.HNYHPc^h6a:(j0"QO&r)"H*)
	Gn(aAk*Qn>1pIC8<r^n)[JbG,TUW<3mg8.`nTdWIY0`5Sf$4.U_JLahG60#U?dmeun5I>,#R?m9m:1
	"\sU(Kpm`=$geTL=r30'H*M!Y'02_jl?F_p1dr5mLnH]9581M7\TXVR6&/m#Y\&HUPBH/Du<]PFt6l
	Op@6e1di9-A'ZDpgm(`5RQ-F`'@O>0iTt`OT_Js)#mc3AG-Ph*?YmKe9#FBW?eo_heBCnHX7=s7&Ju
	U@nIZT[Jaj?IEu9IdAIU_ES]*<7+,b%#eDg,h4nbSk3QZFkd%A3XN.9mfr!;6.[A3A'GBl1YZ_>c5i
	o7ffira9t*YoM*)2Z[Q<0DkY+p5_F>+!7W>EYOXe^`R(4)gm]3!'YY&;+.imc&g*k>NZQ)RckOeKlb
	CGoYlb$6:%8$Q@FM+$S$fh:IkCeX>(GT$c6p$(BAo&_l%\N4(/\.#pWH6kHQ3TO*RR)M"Ii$5c5ph\
	$f,)P;$m/a$Yb7LsJd\kY;t45A(IJd)G_7ZTa!:-QHRo]=i2?<ikWhriBCO1u\WJaj<h++`qo(a">/
	HR$ncdWP=uH!,D+T8(P``5J&?5.^C3gD>hSSbt]1f2n%f*kF.9md.*VlILTClF(SK3I[^3Y0P_N*Kg
	sU3[#!-0dJ(q@T'c^#SPJrRP5mG2co36LZ=tpVNg[PA^U$b;))shq#B7.]gkRqhg$3f>Vh`%8]"2X#
	RCcX'.@N1Wj6A*e?5.Gh<N^2ch<lPO5"eqVmWqAh;`[&gN2)?h6q*9GQ2@NO1+@TmFo-L";*p2:^iG
	I5Y/tMK\Y`So/s@Oh_PClS"MU"i8d%uairh6kF(4Ci:-""qn)'i!iPj7C@67B4>sgTe%)YUBU?aE.j
	G.RO%%/YBfr-RWWbVpj,mCVMG-,iT<],0?#cL_PhAR<WU!K`0W>jGl76\PR/5sP=`7<dlj4A/g;bT,
	.ZARaPDAL(X7K5[<J*^J?+qgpMP6fI;6Sf1ChmcgaeP=hoYG=G)X3\QLB%A]+Fl_K$YWbA(Uhh:G%j
	^7p,'&kcCah*([e(3TBDjCKJq-q%[AYLSET2'gV:Kj&bM&Aj6c6u_2,:r['72:Z-Z\h$I5%'en3lDQ
	`BUFF6BQA[*\-LYH+l!:t*fg8Pa>?DCh`CSnB7GM1-qe#F!7[HTGE/@W/-\CYWQFUeg#1_oZFlHr*s
	Fj$C?cZmr]]N"K@r!#JL(6pXeA(DmEjjJXR`H3@6L<,2)1l&=A<U9*Y)BijYjIc[PJM:Si]T[?"SBu
	^b<a[QNc$*hX^rjc2T<.C`6PLdfTD'8QI7rI4+rO&C@_t+-VJ,fWVjL;p_>7\-Mp?Ea\A1F_K?2so)
	pM-$e.e3?5Thf(^[,l,6B"#93#O38>GO=hP]dIj%1"kB`=\7oMoOr'>G5Ik/kq=J_nl1<,1h28Y8qk
	ksYV;C>=B!si"3J!GdY+f#iDH^r''P`lQcaG7gR?[K&P/fo4l-=e6rg&/De8Q7=Y-:1N.U;ip,;K1j
	ZiEL(ig3Fj7/p=7=9cK:d*pkk!ul57(/l#r)!'FIFDt88uANkDe@R5m6IJmMBC5"d@ln2/oQ`m;s>D
	df5U/Kqb;]DA'*5qS(?K3G$4%!@0bs:_gMY!5QCffnlqdGfVnskZpZ)ED<r;lo\?j"`BAFKU_9;L+*
	qh=puU-\.iKFEDXQ2kkOe2o1h/_seSQ[CG$7OURK08cA[Q'9H/l%oO8;4$f$\DN2-ZF3S]hhuSK:L:
	7@0kbkr?0CAaYhPp#L:3),EuC2s51pkO+i2NIE\H;MNH0"1LAOo=#O$+.PC`i7'8<MTbW2KjC7sQtE
	+:ieX-dmK?A":="YW_/%j*Gm+AHCt5LFnQEIT*;l"ifDOlf)i=^>e(bL"!!*36Qs9^ha7NnHcf`(4Z
	X%nr<EQp1l=o.'idh7@VGAfJ>!&DZ<]hF':]-g9]3a7@oD61Ga!j(kZVl[R6aMfu7*l"MgKj%7]%en
	cK"=(1;PK@59qS>?NFsK7)It%d;P;e+6r90/9a!<_eIlE]em<Ef1SiOuFLa47WB4(TV3psPT</hoF[
	Gbt3^HgZfX?rcG2f1$/uW*Sl_sQ$^*gG-M4f/S_G/-0Oj6(:e*>!Qi7?><eo9W'!!3EKJA@rokjF9i
	p8),4IJL)OL/q:iJ*3Fg^2i<T`R.6^6%^OU+IgIu:7iReI,sp8Hb/sa51n5DmdIUt.BNVhJtUtck)W
	^n2JQ8jTp?;`HCXXih.F0q;i3M^TdFgFZ).ep?;T+8XB@)\Z\C"oTd;qJDfZLidIplFGai'0$g5\)"
	\H2457jiuS9A;om)FqJR+LfS&l#g:2kYfiA@%PKX2*</9Y-mg;$=S\;n-)G[JFb.7*_@4^T#sGREB>
	L\`iR1Dm-,k2k*0R6N@,i&3sWd$,g;PVk885W?6%Cd;h8f.fAN/CHhR`]'AQhX#!L+P.YZ"j]d[.QX
	#7?fW!/@>C3`^Z+o^?Islb;pk`O*=!eR-oHPseXsiT*qUHI`Fdu,0r;S^>8M;4:ktobehed5YC$$mZ
	LJG&(?RfqF/jEZ+V7Et=USr:]+%U`@$F?2IA-/sF\MR=C:=S"^-7?"^Kc[^QVRpf@R?1BUp?`jYVE+
	18Y9+7&ihd6b&mlWS&jHF1:Eb5g!XRl#JCXo&eaj$[p;AcCV['UXkkDggnA5@1R%<snqrQQt($=PI?
	&?#`aRS;JTEB=ZdGmrXY0QZi,,f(!%,Gf^[T1an8^8ZOMN7-6U)+k:e_R5h9*J1p+R2?kZU8ADYc+\
	6m!*g;M:0OF7AYE`@*7M0piPXSS\:oDMUs>3.^_<c[^O@`jU#8Vo'.ljl,F_U>'$U)l-(7+Yi=sZCt
	,E1&WbmB";!fu!<ht"@*@-TYPd30>FN1A7=h@cnB'3[iq*-o^Pj,1_L/Yu=$o;abq4Q<)[>Tm#9"N@
	D69eo4tUYjH77>DkqtVtMP?Ou5=u&Y$h^"`F>Lt*DGt0U,V;<c&HJtcPhRu2#doF\:R"XP"DoeElNr
	<RJ>dcU[84Faljq'.4*<k=e5YEB:Gim0;s"B=G'R_h:hjkmUeo<mf?UmqY$_+'HZ,sa.X)fi*6U8D&
	3p3r"=B=_G3XJG8)'X6eH,'"oW\X=q!=nsWNI;N<VL%@aRciH7a';R8(nUd(LK$i?NiBk[FJ'F9&$=
	UZDXV8p@."f`lR[[Z&XihCV--4V>:GFC!5g9?#l[8.AA?b.8Z%f5_ft\mcU!@nuA+i12_$cmn\6l?(
	o\F`?e]5WO9+7[kO?B\2BjWq,6D+3W7O>olXOf@AfR"kn@YWW8$M/<k&M"\\6P=aO#!h*7eA#]X"?s
	JK'o)lK0s'iePqN!!*365[Z>Ro_6CLloa"Pfg"ZBlE>U*m]5MHSP6/`Xd>T/p5CZ)RB<[8260FS9rI
	Z\DU<qZFchEu_./JP[Sr$H/QU"^cr;Ksd^\$#]15[,gN9tW[jUV8CUe"iW2-Ib&[\:/X?mjLV9QkPg
	A=f_e\p2#&QDhSfu]OrifNEse?2Q<,#*l;qe$WX..*W[K'Eg&]m@een%4QOr+5WcO#M^l!XKo&?38M
	fEp'J4D65t?`PJa+jWc:AeM&A"]^32S#QcW^2c*MNYO]Yj1c+"Q#YekSdHJ]9K6?jLL1?@3k#bi7]!
	jU3M^>.g!\KS"lh3.UT[%X'V^$;:;k'\T%a[#FTM>gMKLM5NLei9/Bs#/b/F!QY[hVt$Q^)cK8s3MQ
	=mY#0#?@\"c^C@(p6i<%;u1So;.hBKqJ5+$\U67Us6Kf2fEoO-bIi7JmU#>7>F-u?r'rYAM1;E5NtF
	VW!<aa/JB"EC1j7I$T$4"447?;NnW0iTWhL,u[i`@?g;q+orRTu0'i1V1UPERps2/p4HQ!gFII=CS,
	b.K,H%hZ.<HR.>"#3M2*?(HI/N/kO1L?,C)=7og;dNg4W$pX5oEU!TO"]bfWQS4u06urDZNgCjc?,@
	ETep7l3jhPWQ4)6G81nhW7Y>HklDU2j4"n#/ChYlud(35LrU@BP4!^BYj:24s+Fq6Q'<j%bQ(@T?qs
	4:3`/&>\j+6mh(/?UbResf5Y`aiZ4F+6HiN(:ACHbj)l>`02,K5MLb4=8IF'>Bc=ZH'@VO\YlPqZ!h
	MUgsj<-gU,3uS3)X9dOX#jV(5L$AY4Nn6`kR\-AWr91+cgN3p-d/u!Q"R;u50Mn*[8qBY4GE/sjda6
	arSG9]s/cMZ'mOeeML7[EQ!XKp!!!8?Z@,Ls\7iqV#?XNHk?bL+D`oUNFDIMp(k<O[W7fo^;B+p-9N
	`5tcA)FUS?H[Hb<+Id2Z&!QV;VEZr`ekCcF.6Yd.clu.f+1qK?XYAApM9bTIkVT2qKdeQ!FN&q&<-E
	"62b!<?4g/S9Ke\EKmrY"Wo(d4m1XD.$Tt9N"a,0m$J^?(*.P]X>#:='A2[]%i9MK><&96Yl-K<m\;
	pUk#Tth3"BsQ+s6YSGs8/5_\(lAUB0O";hH\=ijd*@WGuKYdo*M70He7er^O1@NU"2tU,k!QClaA@:
	.c0;!1Hndqh.GB(_PaL<S-eUde`4o=+t$ffC%SuHed+/1cC=&m(N@iGo_"gTT:<A^6$>_Cae.D'm_6
	*P!e0#1>_bZY5QCff&BHL*rEEQW[/HtRJ,.*loC(>A<;Rg#=8QZ*4pre:*U2p9jC^.4C2EQhZlu>=H
	.k[8X4?R-]U+PLg)o24b]f,@-FEbI&QCD]$?]hHH+benJ[:uZmJ$U-e+sW.6-j>c0+gGL!<ht"T]nk
	rpRchIfok$4D-e7lqX_G71b`hNPkhm7Yoi?opuIH`?%Xj`>H\X-MNOclY3"Y;<S[4u.Y?rt1OJ!(h:
	H0_APMcgadd!i6$6kDO7YbdoG7(1?KupO9+&)NS&mk(DUfsNf2!tOd;-68J,fWV+>@L5H@)F%H1>9H
	>Q:fE(0u:39NGcJmlq-DKmT/VoY,+UG.t'Dk^Mlb>@4IKn9MBfP*65oc#gNSc0h&J?^`CC`2Wck^?Z
	)jk=pCFLR[?V41k!>lG'lN_emSar&5,H>QOp/&3p3r";&(r!hBG@a.@S@(OP%;\#*5Z4LLutG21TlM
	4fa^VNZ&]#\s3$a!ZK(m:\D@$LhE:n&#[<?ZcZ83&LaC+FjFn#U"Z5V&+q5;bukcqt?=]%B$dcAu_!
	J=d_i%T"4?)H9n+d7],U&[MMn=3b<Q6;tSMQ8R3KNAV*,'k;M/ga]m?#1?c60EtJNd5QCff&@bsJnu
	rra>/e]arI[=Zl1OL^h4;bl4u;M1@mY84;LP+u&EgZN7UnlX,W`(MM,rWdDP"<j^#lLVhm?c<)rcl.
	4r6Qd!<`s!!!*3TO[(akqN"\fr8[B1q@a1-p*t),W(ERn_WSHAFJq"f'"sQ-:-0"_XI+(J2a2]Rb.4
	iK3J=:B5QCff&3p3r"PuoUWJn7N=NbpfGPAQBj&nJ0G.'GPqF?=`n>7iq=+*#Ie5YPMpGSC4/t+Nfn
	b[63J*hVJ9;%7t5$()O!<`s!!.bFmaNn=CN\usE4L>(/[sl$hpo//u53pX5,:@AtM+?^R"OuB&`lt0
	Rg$J?gP!<9fqSDj*fV*B'rsnN&&3p3r";!fuJVu&JgI'#QG])i`Q?JHPh\e^-V?X4.Ah7.lTD.6Qr,
	;&X:f.q<\4u+%#U"Wt!XKp!!!3fad+I%CU[<E#hYU>t,\D5tdPCHl$e0jUToD%P]*>H_Og/cJP1mQ`
	nY:<`>Z4Y**nlHNip$dlJ,fWV+Fq9&$fl@`?CG''^88IAgV;VEdiJ<:gCAMBH>_M.Ih$n.=TqXFm<7
	BoB`94qf.e4YaG$5l+FjFn#U"X_^'XF#j8Z^PeaL8W1R:^hI>X].\OdI]!G\d-bsi>flXnK<ik;i"r
	fRH\AkdU`5QCff&3p3r"<;u;.fIfSA,l,:NnsA&KjLt')&8TuU#Rf%;#o!3C;KPB^Y!r*k*:i,\O\j
	^mt3,7J,fWV+FjFn'.o=/`V:FVedL;^[->4&oCDmX(<aj8n"fIpKP:XaB"]83]]k[lX]r2Q`?Jn=:%
	Y'*Y)`Pa#U"Wt!XN%7J[B"=[^:PMfkih:)cJ3?9MQMp$u3rSC1MTekeVDBZmO8Odc*pSB$QD:!XKp!
	!!3EK0VJQ:N7?]CnEoDIrT;ABI?B3>Mb0T%RmNZpd"9\Bi1;gL+'cR$:A'kAmu*a`%tTW`J,fWV+Fj
	Fn_ZV;T0g=2uX]kbArkgtW[emIek)<jdqL"VnM!>?#<$l*f$g(6c]P#L;He0m>25P]Q-bofe&3p3r"
	;!fuJ\2cN?JFu!9=qXGeJLrU!rd1qTW7k#1__((9N@DphmmdtV`(WiH?s^?)q-bL&3p3r";!fuJRJW
	WNj\fGjh8F^J#"S-om&Y@m3I1<D]3l#50u\I>nIS'\ocmYDHX;fp.V[1I>KW#kn-/\!<`s!!.i=!?k
	O47ohfC7csS]Eo4ZS`\%K<8BQM>%]O"%S9/9(1"aJ55\397k2-9_']'Is"S6&usV!NH=s,#\4+b0Oo
	#U"Wt!XN%I!Hh!UBPMtd`LSY&C5aH;lBG8]r).Wm.dgK+V3G1_=n1uU+5"+$ROb8"CTI5gh&t!u!!3
	EKJ,fWV+E4k!Usb[KD5ViorUo=a*'QM&dFO_'1MHC>^MQD9gK"HbVj8%S[JIIqhQUJ7[*"KfGO_lT)
	%f+6!<`s!!.jm<^uQubTDa:<)/F0NM4a6_j44"'[[qqZ;m"ZIA`Un=BN!Dt8$Bn)Zl5mhm@IKf]Q.o
	7k3K3VJ*m/Q^jl(+gd(o@";!fu!<`t$ZiUK%>CZY;S(eE31jAW2PDZ#9Y6Jp*D5*3EU:9KjQ*o/S=r
	%T#Siu+ol`\!KeWQ(l@+%*bE!-_;!!*365QHAA!Y$/UcgIpkEj4tF7opt=U:ID2TcTQ;j4QdPpl<q"
	[k1$F(#lR=_8,t_eJjgu^MDA_R]:D)gC$1c00fL<";!fu!<hsp@$2;cF!%>A/pj=tLA(&upXa:Ee>Q
	))PF7BpkWVq2GGZlNK1/;UV.TTLh6OJWIUm3u;VJGT54=b:'fRb8F5,,s958'>Q@tY5T>,l"BGgjW+
	FjFn#U&Uu$M;Bu-bK8*IGjU5&(^2fC5jPR5.ASuoltNi<8F;2^QEH[0(A"m.DT^3I)aU.e&t?ac)X\
	NIeC@Bl/ea8Kcf!.B+[B/!<`s!!.d]m&4n-/H3^n02S=:=DJs#XpL(r"Ed;fV&!r\@0:UAOc'r$9Fe
	kHDn7F#1,,ffWV\Fj7s/?ateJG6FiPUA'UV2$fX4).n&3p3r";!g`PB!,l4=$.9O*C<aBkVghm_mNH
	cE>""<8(ADc'i?9MON5-qa5G8dT)q@U^F0=JA8+okj%D4/$>=`j+9:4VbIKoR0V%[-j1)H!!*365QH
	B0,]L'$Dr7h^XbRh\>!#OQ&#a+sP"=7ElT&DW/LXH/?<sD]HbM<N<:X9LHfg)!c!*;G=u]@RT!$+"#
	U"Wt!XKp!!!8?jTX0.;NMb9.lC6XFDJSY(O![fZ8h#s$#h?qaVXf25,BTlqT%dbSd,unc"D1Z!/XeQ
	qK+"hc5%eJ=ER>U>H(+@I"TSfNJ,fWV+HZU)']V^YN7A.o&;s&AWU<;6Sk(ApWYg4DKpigf$3EE[lm
	_%iJ7!)C('b16KbWH8OQ7hn&3p3r";!fuJbLRSZ#%[PO/5`["4:X?e'cdI/Wb_5OO%YBVjaUm"jun8
	:iRUS*2ET7*d'IO!<`s!!!*365[X]qXnOiC9Z@^EmV#;O20D*F:1rIU+`GAUC/'&W]i5Uq/.DbTJjC
	t\YFRjI3#>@6J,fWV+FjFn#`L#o0n(C5o0/LF8ml=?k]m^#QO"^a!!3EKJ,fWV>RUWWkf$BZ*!d[;!
	!3EKJ,fWe+Q0?"W^Z8-i$BA#!!3EKJ,fWV+RfjAMXg-8i?87.+FjFn#U"Wt!XKp!!!3EKJ,fWV+FjF
	n#U"Wt!XKp!!!6XFE0'Yp]H.(V&3p3r";!fu!<`s!!!*365QCff&3p3r";!fu!<`s!!!*4W$W)d(m_
	L+N&3p3r";!fu!<`s!!!*365QCff&3p3r";!fu!<`s!!!*5B/3kq=b_2Jd!<`s!!!*365QCff&3p3r
	";!fu!<`s!!!*365QCff&3p5Hi;s_RLO8Lr!<`s!!!*365QCff&3p3r";!fu!<`s!!!*365QCff&3p
	5H0agg:+#>&f5QCff&3p3r";!fu!<`s!!!*365QCff&3p3r";!fu!<`s!@(63Upu*8V63%#h&3p3r"
	;!fu!<`s!!!*365QCff&3p3r";!fu!<`s!@*AZdj2Xj7#nT?%!<`s!!!*365QCff&3p3r";!fu!<`s
	!!!*365QCff&/[#b0n-V;Nt=PV!<`s!!!*365QCff&3p3r";!fu!<`s!!!*365QCff&/__R`V;/$EW
	Q@T5QCff&3p3r";!fu!<`s!!!*365QCff&3p3r";!fu!<e,b:lHLa_'9'o5QCff&3p3r";!fu!<`s!
	!!*365QCff&3p3r";!fu!<gCn5V[`3KU`#C";!fu!<`s!!!*365QCff&3p3r";!fu!<`s!!!*365QH
	Ao!Yj[MHgh:A";!fu!<`s!!!*365QCff&3p3r";!fu!<`s!!!*365QH?i$W)d(1Ee,2!!*365QCff&
	3p3r";!fu!<`s!!!*365QCff&3p3r";!h+\,aMCi>t*J!!*365QCff&3p3r";!fu!<`s!!!*365QCf
	f&3p3r";!h+bQ8L=a%XP\&3p3r";!fu!<`s!!!*365QCff&3p3r";!fu!<`s!!!*36(bY<-8@*-W)V
	(OOz8OZBBY!QNJ
	ASCII85End
End

/////////////////////////////////////////////
// Roster of Variable Definition Functions //
/////////////////////////////////////////////

Function IRIS_SCHEME_DefineVariables_D17O_CO2()
	
	// NOTE: "UNIVERSAL" sections must be included exactly as they are, exactly where they are.
	
	// === UNIVERSAL: DECLARATIONS (do not modify) ===
	
	NVAR gasToGraph1 = root:gasToGraph1
	NVAR variableToGraph1 = root:variableToGraph1
	NVAR gasToGraph2 = root:gasToGraph2
	NVAR variableToGraph2 = root:variableToGraph2
	NVAR output1_gasID = root:output1_gasID
	NVAR output2_gasID = root:output2_gasID
	NVAR output3_gasID = root:output3_gasID
	NVAR output1_variableID = root:output1_variableID
	NVAR output2_variableID = root:output2_variableID
	NVAR output3_variableID = root:output3_variableID
	
	string name, units, format, sourceDataName, sourceDataType
	variable calibrateOrNot, rescaleFactor, diagnosticSlot
	
	variable outputIndex = 0
	
	// === DEFINE OUTPUT VARIABLES ===
	
	name = "Δ'17O" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "CapD17O" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "avg" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "‰" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.4f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "δ17O (VSMOW)" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "d17O_VSMOW_Avg" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "avg" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "‰" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.4f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "δ18O (VSMOW)" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "d18O_VSMOW_Avg" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "avg" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "‰" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.4f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "CO2 Mole Fraction" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "CO2_Avg" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "avg" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "ppm" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.2f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "Cell Pressure" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "stc_Praw" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "stc" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "Torr" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.3f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 3 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "Cell Temperature" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "stc_Traw" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "stc" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "K" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.3f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "626 Mole Fraction" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "i626" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "ppm" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.2f" // sets the number format for onscreen display
	calibrateOrNot = 1 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1/1000 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 1 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "627 Mole Fraction" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "i627" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "ppm" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.2f" // sets the number format for onscreen display
	calibrateOrNot = 1 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1/1000 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "628 Mole Fraction" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "i628" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "ppm" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.2f" // sets the number format for onscreen display
	calibrateOrNot = 1 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1/1000 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "Unreferenced Δ'17O" // the namrawe of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "capDel17O" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "‰" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.4f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "Unreferenced δ17O" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "del17O" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "‰" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.4f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 2 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "Unreferenced δ18O" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "del18O" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "‰" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.4f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	// === UNIVERSAL: HOUSEKEEPING (do not modify) ===
	
	IRIS_UTILITY_DefineVariablesHousekeeping(outputIndex)
	
	// === SET DEFAULT VARIABLES TO DISPLAY WHEN PANEL OPENS ===
	
	output1_gasID = 0 // 0 is the first sample gas
	output2_gasID = 0 // 0 is the first sample gas
	output3_gasID = 0 // 0 is the first sample gas
	gasToGraph1 = 0 // 0 is the first sample gas
	gasToGraph2 = 0 // 0 is the first sample gas
	output1_variableID = IRIS_UTILITY_GetOutputIndexFromName( "Δ'17O" )
	output2_variableID = IRIS_UTILITY_GetOutputIndexFromName( "CO2 Mole Fraction" )
	output3_variableID = IRIS_UTILITY_GetOutputIndexFromName( "Cell Pressure" )
	variableToGraph1 = IRIS_UTILITY_GetOutputIndexFromName( "Δ'17O" )
	variableToGraph2 = IRIS_UTILITY_GetOutputIndexFromName( "Δ'17O" )
	
End

Function IRIS_SCHEME_DefineVariables_D17O_CO2_Bellows()
	
	IRIS_SCHEME_DefineVariables_D17O_CO2()
	
End

Function IRIS_SCHEME_DefineVariables_D17O_d13C_CO2()
	
	// NOTE: "UNIVERSAL" sections must be included exactly as they are, exactly where they are.
	
	// === UNIVERSAL: DECLARATIONS (do not modify) ===
	
	NVAR gasToGraph1 = root:gasToGraph1
	NVAR variableToGraph1 = root:variableToGraph1
	NVAR gasToGraph2 = root:gasToGraph2
	NVAR variableToGraph2 = root:variableToGraph2
	NVAR output1_gasID = root:output1_gasID
	NVAR output2_gasID = root:output2_gasID
	NVAR output3_gasID = root:output3_gasID
	NVAR output1_variableID = root:output1_variableID
	NVAR output2_variableID = root:output2_variableID
	NVAR output3_variableID = root:output3_variableID
	
	string name, units, format, sourceDataName, sourceDataType
	variable calibrateOrNot, rescaleFactor, diagnosticSlot
	
	variable outputIndex = 0
	
	// === DEFINE OUTPUT VARIABLES ===
	
	name = "Δ'17O" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "CapD17O" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "avg" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "‰" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.4f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "δ13C (VPDB)" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "d13C_VPDB_Avg" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "avg" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "‰" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.4f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "δ17O (VSMOW)" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "d17O_VSMOW_Avg" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "avg" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "‰" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.4f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "δ18O (VSMOW)" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "d18O_VSMOW_Avg" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "avg" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "‰" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.4f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "CO2 Mole Fraction" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "CO2_Avg" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "avg" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "ppm" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.4f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "Cell Pressure" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "stc_Praw" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "stc" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "Torr" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.3f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 3 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "Cell Temperature" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "stc_Traw" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "stc" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "K" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.3f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "626 Mole Fraction" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "i626" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "ppm" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.4f" // sets the number format for onscreen display
	calibrateOrNot = 1 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1/1000 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 1 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "636 Mole Fraction" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "i636" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "ppm" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.2f" // sets the number format for onscreen display
	calibrateOrNot = 1 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1/1000 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "627 Mole Fraction" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "i627_A" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "ppm" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.2f" // sets the number format for onscreen display
	calibrateOrNot = 1 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1/1000 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "628 Mole Fraction" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "i628" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "ppm" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.4f" // sets the number format for onscreen display
	calibrateOrNot = 1 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1/1000 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "Unreferenced Δ'17O" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "capDel17O" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "‰" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.4f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "Unreferenced δ13C" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "del13C" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "‰" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.4f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "Unreferenced δ17O" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "del17O" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "‰" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.4f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "Unreferenced δ18O" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "del18O" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "‰" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.4f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 2 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	// === UNIVERSAL: HOUSEKEEPING (do not modify) ===
	
	IRIS_UTILITY_DefineVariablesHousekeeping(outputIndex)
	
	// === SET DEFAULT VARIABLES TO DISPLAY WHEN PANEL OPENS ===
	
	output1_gasID = 0 // 0 is the first sample gas
	output2_gasID = 0 // 0 is the first sample gas
	output3_gasID = 0 // 0 is the first sample gas
	gasToGraph1 = 0 // 0 is the first sample gas
	gasToGraph2 = 0 // 0 is the first sample gas
	output1_variableID = IRIS_UTILITY_GetOutputIndexFromName( "Δ'17O" )
	output2_variableID = IRIS_UTILITY_GetOutputIndexFromName( "δ13C (VPDB)" )
	output3_variableID = IRIS_UTILITY_GetOutputIndexFromName( "CO2 Mole Fraction" )
	variableToGraph1 = IRIS_UTILITY_GetOutputIndexFromName( "Δ'17O" )
	variableToGraph2 = IRIS_UTILITY_GetOutputIndexFromName( "δ13C (VPDB)" )
	
End

Function IRIS_SCHEME_DefineVariables_D17O_d13C_CO2_CapeTown()
	
	IRIS_SCHEME_DefineVariables_D17O_d13C_CO2()
	
End

Function IRIS_SCHEME_DefineVariables_D17O_d13C_CO2_AnalyzeOnly()
	
	IRIS_SCHEME_DefineVariables_D17O_d13C_CO2()
	
End

Function IRIS_SCHEME_DefineVariables_IceCore_d13C_CO2()
	
	// NOTE: "UNIVERSAL" sections must be included exactly as they are, exactly where they are.
	
	// === UNIVERSAL: DECLARATIONS (do not modify) ===
	
	NVAR gasToGraph1 = root:gasToGraph1
	NVAR variableToGraph1 = root:variableToGraph1
	NVAR gasToGraph2 = root:gasToGraph2
	NVAR variableToGraph2 = root:variableToGraph2
	NVAR output1_gasID = root:output1_gasID
	NVAR output2_gasID = root:output2_gasID
	NVAR output3_gasID = root:output3_gasID
	NVAR output1_variableID = root:output1_variableID
	NVAR output2_variableID = root:output2_variableID
	NVAR output3_variableID = root:output3_variableID
	
	string name, units, format, sourceDataName, sourceDataType
	variable calibrateOrNot, rescaleFactor, diagnosticSlot
	
	variable outputIndex = 0
	
	// === DEFINE OUTPUT VARIABLES ===
	
	name = "δ13C (VPDB)" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "d13C_VPDB_Avg" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "avg" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "‰" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.4f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "CO2 Mole Fraction" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "CO2_Avg" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "avg" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "ppm" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.2f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "Cell Pressure" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "stc_Praw" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "stc" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "Torr" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.3f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 3 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "Cell Temperature" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "stc_Traw" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "stc" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "K" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.3f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "626 Mole Fraction" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "i626" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "ppm" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.2f" // sets the number format for onscreen display
	calibrateOrNot = 1 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1/1000 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 1 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "636 Mole Fraction" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "i636" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "ppm" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.2f" // sets the number format for onscreen display
	calibrateOrNot = 1 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1/1000 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "Unreferenced δ13C" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "del13C" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "‰" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.4f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 2 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	// === UNIVERSAL: HOUSEKEEPING (do not modify) ===
	
	IRIS_UTILITY_DefineVariablesHousekeeping(outputIndex)
	
	// === SET DEFAULT VARIABLES TO DISPLAY WHEN PANEL OPENS ===
	
	output1_gasID = 0 // 0 is the first sample gas
	output2_gasID = 0 // 0 is the first sample gas
	output3_gasID = 0 // 0 is the first sample gas
	gasToGraph1 = 0 // 0 is the first sample gas
	gasToGraph2 = 0 // 0 is the first sample gas
	output1_variableID = IRIS_UTILITY_GetOutputIndexFromName( "δ13C (VPDB)" )
	output2_variableID = IRIS_UTILITY_GetOutputIndexFromName( "CO2 Mole Fraction" )
	output3_variableID = IRIS_UTILITY_GetOutputIndexFromName( "Cell Pressure" )
	variableToGraph1 = IRIS_UTILITY_GetOutputIndexFromName( "δ13C (VPDB)" )
	variableToGraph2 = IRIS_UTILITY_GetOutputIndexFromName( "δ13C (VPDB)" )
	
End

Function IRIS_SCHEME_DefineVariables_IceCore_d13C_CO2_noVICI()
	IRIS_SCHEME_DefineVariables_IceCore_d13C_CO2()
End

Function IRIS_SCHEME_DefineVariables_D638_CO2()
	
	// NOTE: "UNIVERSAL" sections must be included exactly as they are, exactly where they are.
	
	// === UNIVERSAL: DECLARATIONS (do not modify) ===
	
	NVAR gasToGraph1 = root:gasToGraph1
	NVAR variableToGraph1 = root:variableToGraph1
	NVAR gasToGraph2 = root:gasToGraph2
	NVAR variableToGraph2 = root:variableToGraph2
	NVAR output1_gasID = root:output1_gasID
	NVAR output2_gasID = root:output2_gasID
	NVAR output3_gasID = root:output3_gasID
	NVAR output1_variableID = root:output1_variableID
	NVAR output2_variableID = root:output2_variableID
	NVAR output3_variableID = root:output3_variableID
	
	string name, units, format, sourceDataName, sourceDataType
	variable calibrateOrNot, rescaleFactor, diagnosticSlot
	
	variable outputIndex = 0
	
	// === DEFINE OUTPUT VARIABLES ===
	
	name = "Δ638" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "D638" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "avg" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "‰" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.4f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "δ13C (VPDB)" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "d13C_VPDB_Avg" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "avg" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "‰" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.4f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "δ18O (VSMOW)" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "d18O_VSMOW_Avg" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "avg" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "‰" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.4f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "CO2 Mole Fraction" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "CO2_Avg" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "avg" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "ppm" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.2f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "Cell Pressure" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "stc_Praw" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "stc" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "Torr" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.3f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 3 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "Cell Temperature" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "stc_Traw" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "stc" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "K" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.3f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "626 Mole Fraction" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "i626" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "ppm" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.2f" // sets the number format for onscreen display
	calibrateOrNot = 1 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1/1000 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 1 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "636 Mole Fraction" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "i636" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "ppm" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.2f" // sets the number format for onscreen display
	calibrateOrNot = 1 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1/1000 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "628 Mole Fraction" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "i628" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "ppm" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.2f" // sets the number format for onscreen display
	calibrateOrNot = 1 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1/1000 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "638 Mole Fraction" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "i638" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "ppm" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.2f" // sets the number format for onscreen display
	calibrateOrNot = 1 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1/1000 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "Unreferenced Δ638" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "Del638" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "‰" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.4f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 2 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "Unreferenced δ13C" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "del13C" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "‰" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.4f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 2 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "Unreferenced δ18O" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "del18O" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "‰" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.4f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	// === UNIVERSAL: HOUSEKEEPING (do not modify) ===
	
	IRIS_UTILITY_DefineVariablesHousekeeping(outputIndex)
	
	// === SET DEFAULT VARIABLES TO DISPLAY WHEN PANEL OPENS ===
	
	output1_gasID = 0 // 0 is the first sample gas
	output2_gasID = 0 // 0 is the first sample gas
	output3_gasID = 0 // 0 is the first sample gas
	gasToGraph1 = 0 // 0 is the first sample gas
	gasToGraph2 = 0 // 0 is the first sample gas
	output1_variableID = IRIS_UTILITY_GetOutputIndexFromName( "Δ638" )
	output2_variableID = IRIS_UTILITY_GetOutputIndexFromName( "CO2 Mole Fraction" )
	output3_variableID = IRIS_UTILITY_GetOutputIndexFromName( "Cell Pressure" )
	variableToGraph1 = IRIS_UTILITY_GetOutputIndexFromName( "Δ638" )
	variableToGraph2 = IRIS_UTILITY_GetOutputIndexFromName( "Δ638" )
	
End

//////////////////////////////////////////////
// Roster of Parameter Definition Functions //
//////////////////////////////////////////////

Function IRIS_SCHEME_DefineParams_D17O_CO2()
	
	// NOTE: "UNIVERSAL" sections must be included exactly as they are, exactly where they are.
	
	// === UNIVERSAL: DECLARATIONS (do not modify) ===
	
	variable paramIndexCount = 0
	variable i, j
	
	NVAR numOutputVariables = root:numOutputVariables
	wave/T wtOutputVariableNames = root:wtOutputVariableNames
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	NVAR numGases = root:numGases
	
	NVAR numGasParams = root:numGasParams
	NVAR numCalParams = root:numCalParams
	NVAR numBasicParams = root:numBasicParams
	NVAR numAdvancedParams = root:numAdvancedParams
	NVAR numFilterParams = root:numFilterParams
	
	make/O/T/N=0 wtParamNames, wtParamValues, wtParamUnits
	
	// === DEFINE GAS INFO PARAMETERS ===
	
	for(i=0;i<numSampleGases;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Sample " + num2str(i+1) + ": " + "ID", "unknown", "" ); paramIndexCount += 1
	endfor
	for(i=0;i<numRefGases;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference " + num2str(i+1) + ": " + "ID", "unknown", "" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference " + num2str(i+1) + ": " + "CO2 Mole Fraction", "unknown", "ppm" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference " + num2str(i+1) + ": " + "δ17O", "unknown", "‰ VSMOW" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference " + num2str(i+1) + ": " + "δ18O", "unknown", "‰ VSMOW" ); paramIndexCount += 1
	endfor
	numGasParams = paramIndexCount // the parameters above this line will appear in the gas info tab
	
	// === DEFINE CALIBRATION PARAMETERS ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Calibration Curve Equation", "c0*meas", "" ); paramIndexCount += 1
	numCalParams = paramIndexCount - numGasParams // the parameters above this line but below the numGasParams line will appear in the calibration tab; those below this line will appear in the basic system table
	
	// === DEFINE BASIC SYSTEM PARAMETERS ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Cycles", "10", "(use 0 for perpetual run)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Time Limit", "24", "hours" ); paramIndexCount += 1
	numBasicParams = paramIndexCount - numCalParams - numGasParams // the parameters above this line but below the numGasParams line will appear in the basic system table; those below this line will appear in the advanced system table
	
	// === DEFINE ADVANCED SYSTEM PARAMETERS ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference slope (λ)", "0.528", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Measurement Duration", "30", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Time to Ignore at Start of Measurement", "5", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Subtract Background Spectrum", "y", "(y/n)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Background Measurement Duration", "10", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Background Measurement Interval", "0", "minutes (use 0 for infinity)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Flushes of V2", "1", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Flushes of MPC", "2", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Vacuum Time before Flush of V2", "10", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Vacuum Time before Final Fill of V2", "10", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Vacuum Time before Flush of MPC", "10", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Vacuum Time before Final Fill of MPC", "10", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Vacuum Time before Background", "10", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Time to Wait for Fill of MPC from V2", "2", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Target MPC Pressure", "30", "Torr" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Target Pressure for Flush of V2", "80", "Torr" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Target Pressure for Flush of MPC", "80", "Torr" ); paramIndexCount += 1
	for(i=0;i<numSampleGases;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "ECL Index for Sample " + num2str(i+1), num2str(i+1), "" ); paramIndexCount += 1
	endfor
	for(i=0;i<numRefGases;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "ECL Index for Reference " + num2str(i+1), num2str(numSampleGases+i+1), "" ); paramIndexCount += 1
	endfor
	//	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "ECL Index for Zero Air", num2str(numSampleGases+numRefGases+1), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "ECL Index for Transition", num2str(numSampleGases+numRefGases+2), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Sample 1", "0", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Reference 1", "1", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for MPC", "2", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Flush", "3", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Vacuum", "4", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for V2", "5", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Pressure Sensor Number for MPC", "0", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Pressure Sensor Number for V2", "1", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Ratio of Total System Volume to V2", "9.5", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Action Time Spacer", "0.3", "seconds" ); paramIndexCount += 1
	numAdvancedParams = paramIndexCount - numBasicParams - numCalParams - numGasParams // the parameters above this line but below the numBasicParams line will appear in the advanced system table; those below this line will appear in the data filtering tab
	
	// === UNIVERSAL: DEFINE DATA FILTERING PARAMETERS (do not modify) ===
	
	for(i=0;i<numOutputVariables;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Check " + wtOutputVariableNames[i] + " for Outliers?", "n", "(y/n)" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Outlier Threshold for " + wtOutputVariableNames[i], "0", "standard deviations" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Outlier Filter Group for " + wtOutputVariableNames[i], "1", "" ); paramIndexCount += 1
	endfor
	numFilterParams = paramIndexCount - numAdvancedParams - numBasicParams - numCalParams - numGasParams // the parameters above this line but below the numAdvancedParams line will appear in the data filtering tab
		
	// === DEFINE INSTRUMENT-SPECIFIC PARAMETERS THAT DO NOT APPEAR IN THE GUI ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Pressure Sensor Limit for V2", "1000", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Pressure Sensor Limit for MPC", "100", "" ); paramIndexCount += 1
	
	// === UNIVERSAL: DEFINE CORE IRIS PARAMETERS THAT DO NOT APPEAR IN THE GUI (do not modify) ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Gas Parameters", num2str(numGasParams), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Calibration Parameters", num2str(numCalParams), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Filter Parameters", num2str(numFilterParams), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Basic System Parameters", num2str(numBasicParams), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Advanced System Parameters", num2str(numAdvancedParams), "" ); paramIndexCount += 1
	
	// === UNIVERSAL: DEFINE NUMBERS OF SAMPLE AND REF GASES (do not modify) ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Sample Gases", num2str(numSampleGases), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Reference Gases", num2str(numRefGases), "" ); paramIndexCount += 1
	
	// === UNIVERSAL: PROPAGATE PARAMETERS TO GUI TABLES (do not modify) ===
	
	IRIS_UTILITY_PropagateParamsToTables()
		
End

Function IRIS_SCHEME_DefineParams_D17O_CO2_Bellows()
	
	// NOTE: "UNIVERSAL" sections must be included exactly as they are, exactly where they are.
	
	// === UNIVERSAL: DECLARATIONS (do not modify) ===
	
	variable paramIndexCount = 0
	variable i
	
	NVAR numOutputVariables = root:numOutputVariables
	wave/T wtOutputVariableNames = root:wtOutputVariableNames
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	
	NVAR numGasParams = root:numGasParams
	NVAR numCalParams = root:numCalParams
	NVAR numBasicParams = root:numBasicParams
	NVAR numAdvancedParams = root:numAdvancedParams
	NVAR numFilterParams = root:numFilterParams
	
	make/O/T/N=0 wtParamNames, wtParamValues, wtParamUnits
		
	// === DEFINE GAS INFO PARAMETERS ===
	
	for(i=0;i<numSampleGases;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Sample " + num2str(i+1) + ": " + "ID", "unknown", "" ); paramIndexCount += 1
	endfor
	for(i=0;i<numRefGases;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference " + num2str(i+1) + ": " + "ID", "unknown", "" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference " + num2str(i+1) + ": " + "CO2 Mole Fraction", "unknown", "ppm" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference " + num2str(i+1) + ": " + "δ17O", "unknown", "‰ VSMOW" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference " + num2str(i+1) + ": " + "δ18O", "unknown", "‰ VSMOW" ); paramIndexCount += 1
	endfor
	numGasParams = paramIndexCount // the parameters above this line will appear in the gas info tab
	
	// === DEFINE CALIBRATION PARAMETERS ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Calibration Curve Equation", "c0*meas", "" ); paramIndexCount += 1
	numCalParams = paramIndexCount - numGasParams // the parameters above this line but below the numGasParams line will appear in the calibration tab; those below this line will appear in the basic system table
	
	// === DEFINE BASIC SYSTEM PARAMETERS ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Cycles", "10", "(use 0 for perpetual run)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Time Limit", "24", "hours" ); paramIndexCount += 1
	numBasicParams = paramIndexCount - numCalParams - numGasParams // the parameters above this line but below the numGasParams line will appear in the basic system table; those below this line will appear in the advanced system table
	
	// === DEFINE ADVANCED SYSTEM PARAMETERS ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference slope (λ)", "0.528", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Measurement Duration", "30", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Time to Ignore at Start of Measurement", "5", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Clear Prep Tubes At Start", "y", "(y/n)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Time to Wait After Clearing Prep Tubes", "60", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Subtract Background Spectrum", "y", "(y/n)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Background Measurement Duration", "10", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Background Measurement Interval", "0", "minutes (use 0 for infinity)" ); paramIndexCount += 1
	//	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Use Zero Air as an Additional Reference", "n", "(y/n)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of N2 Flushes", "2", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Vacuum Time before Flush", "5", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Vacuum Time before Final Fill", "10", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Time to Wait for Fill of MPC from Prep Tube", "2", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Target Pressure for Flush", "30", "Torr" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Target Pressure for Reference", "30", "Torr" ); paramIndexCount += 1	
	for(i=0;i<numSampleGases;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "ECL Index for Sample " + num2str(i+1), num2str(i+1), "" ); paramIndexCount += 1
	endfor
	for(i=0;i<numRefGases;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "ECL Index for Reference " + num2str(i+1), num2str(numSampleGases+i+1), "" ); paramIndexCount += 1
	endfor
	//	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "ECL Index for Zero Air", num2str(numSampleGases+numRefGases+1), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "ECL Index for Transition", num2str(numSampleGases+numRefGases+2), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Sample Prep", "0", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Sample Inject", "1", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Reference Inject", "2", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Vacuum", "3", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for N2", "4", "(counting from 0)" ); paramIndexCount += 1
	//	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Reference Prep", "5", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Action Time Spacer", "0.3", "seconds" ); paramIndexCount += 1
	numAdvancedParams = paramIndexCount - numBasicParams - numCalParams - numGasParams // the parameters above this line but below the numBasicParams line will appear in the advanced system table; those below this line will appear in the data filtering tab
	
	// === UNIVERSAL: DEFINE DATA FILTERING PARAMETERS (do not modify) ===
	
	for(i=0;i<numOutputVariables;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Check " + wtOutputVariableNames[i] + " for Outliers?", "n", "(y/n)" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Outlier Threshold for " + wtOutputVariableNames[i], "0", "standard deviations" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Outlier Filter Group for " + wtOutputVariableNames[i], "1", "" ); paramIndexCount += 1
	endfor
	numFilterParams = paramIndexCount - numAdvancedParams - numBasicParams - numCalParams - numGasParams // the parameters above this line but below the numAdvancedParams line will appear in the data filtering tab
	
	// === UNIVERSAL: DEFINE CORE IRIS PARAMETERS THAT DO NOT APPEAR IN THE GUI (do not modify) ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Sample Gases", num2str(numSampleGases), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Reference Gases", num2str(numRefGases), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Gas Parameters", num2str(numGasParams), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Calibration Parameters", num2str(numCalParams), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Filter Parameters", num2str(numFilterParams), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Basic System Parameters", num2str(numBasicParams), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Advanced System Parameters", num2str(numAdvancedParams), "" ); paramIndexCount += 1
	
	// === DEFINE INSTRUMENT-SPECIFIC PARAMETERS THAT DO NOT APPEAR IN THE GUI ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Pressure Sensor Limit for MPC", "100", "" ); paramIndexCount += 1
		
	// === UNIVERSAL: PROPAGATE PARAMETERS TO GUI TABLES (do not modify) ===
	
	IRIS_UTILITY_PropagateParamsToTables()
	
End

Function IRIS_SCHEME_DefineParams_D17O_d13C_CO2()
	
	// NOTE: "UNIVERSAL" sections must be included exactly as they are, exactly where they are.
	
	// === UNIVERSAL: DECLARATIONS (do not modify) ===
	
	variable paramIndexCount = 0
	variable i
	
	NVAR numOutputVariables = root:numOutputVariables
	wave/T wtOutputVariableNames = root:wtOutputVariableNames
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	
	NVAR numGasParams = root:numGasParams
	NVAR numCalParams = root:numCalParams
	NVAR numBasicParams = root:numBasicParams
	NVAR numAdvancedParams = root:numAdvancedParams
	NVAR numFilterParams = root:numFilterParams
	
	make/O/T/N=0 wtParamNames, wtParamValues, wtParamUnits
		
	// === DEFINE GAS INFO PARAMETERS ===
	
	for(i=0;i<numSampleGases;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Sample " + num2str(i+1) + ": " + "ID", "unknown", "" ); paramIndexCount += 1
	endfor
	for(i=0;i<numRefGases;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference " + num2str(i+1) + ": " + "ID", "unknown", "" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference " + num2str(i+1) + ": " + "CO2 Mole Fraction", "unknown", "ppm" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference " + num2str(i+1) + ": " + "δ13C", "unknown", "‰ VPDB" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference " + num2str(i+1) + ": " + "δ18O", "unknown", "‰ VSMOW" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference " + num2str(i+1) + ": " + "δ17O", "unknown", "‰ VSMOW" ); paramIndexCount += 1
		
	endfor
	numGasParams = paramIndexCount // the parameters above this line will appear in the gas info tab
	
	// === DEFINE CALIBRATION PARAMETERS ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Calibration Curve Equation", "c0*meas", "" ); paramIndexCount += 1
	numCalParams = paramIndexCount - numGasParams // the parameters above this line but below the numGasParams line will appear in the calibration tab; those below this line will appear in the basic system table
	
	// === DEFINE BASIC SYSTEM PARAMETERS ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Cycles", "10", "(use 0 for perpetual run)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Time Limit", "3", "hours" ); paramIndexCount += 1
	numBasicParams = paramIndexCount - numCalParams - numGasParams // the parameters above this line but below the numGasParams line will appear in the basic system table; those below this line will appear in the advanced system table
	
	// === DEFINE ADVANCED SYSTEM PARAMETERS ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference slope (λ)", "0.528", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Measurement Duration", "64", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Time to Ignore at Start of Measurement", "8", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Subtract Background Spectrum", "y", "(y/n)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Background Measurement Duration", "10", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Background Measurement Interval", "0", "minutes (use 0 for infinity)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Flushes of V2", "0", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Flushes of MPC", "0", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Vacuum Time before Flush of V2", "5", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Vacuum Time before Final Fill of V2", "10", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Vacuum Time before Flush of MPC", "10", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Vacuum Time before Final Fill of MPC", "20", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Vacuum Time before Background", "30", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Time to Wait for Fill of MPC from V2", "2", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Target MPC Pressure", "40", "Torr" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Target Pressure for Flush of V2", "40", "Torr" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Target Pressure for Flush of MPC", "40", "Torr" ); paramIndexCount += 1
	for(i=0;i<numSampleGases;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "ECL Index for Sample " + num2str(i+1), num2str(i+1), "" ); paramIndexCount += 1
	endfor
	for(i=0;i<numRefGases;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "ECL Index for Reference " + num2str(i+1), num2str(numSampleGases+i+1), "" ); paramIndexCount += 1
	endfor
	//	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "ECL Index for Zero Air", num2str(numSampleGases+numRefGases+1), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "ECL Index for Transition", num2str(numSampleGases+numRefGases+2), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Sample Orifice", "0", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Reference Orifice", "1", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Reference Tank", "10", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for MPC", "14", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for V2", "11", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Vacuum", "13", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Second Vacuum", "8", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Fast Cell Flush", "12", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Ref. Orifice Flush", "9", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Pressure Sensor Number for MPC", "0", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Pressure Sensor Number for V2", "1", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Ratio of Total System Volume to V2", "4.3", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Action Time Spacer", "0.3", "seconds" ); paramIndexCount += 1
	numAdvancedParams = paramIndexCount - numBasicParams - numCalParams - numGasParams // the parameters above this line but below the numBasicParams line will appear in the advanced system table; those below this line will appear in the data filtering tab
	
	// === UNIVERSAL: DEFINE DATA FILTERING PARAMETERS (do not modify) ===
	
	for(i=0;i<numOutputVariables;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Check " + wtOutputVariableNames[i] + " for Outliers?", "n", "(y/n)" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Outlier Threshold for " + wtOutputVariableNames[i], "0", "standard deviations" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Outlier Filter Group for " + wtOutputVariableNames[i], "1", "" ); paramIndexCount += 1
	endfor
	numFilterParams = paramIndexCount - numAdvancedParams - numBasicParams - numCalParams - numGasParams // the parameters above this line but below the numAdvancedParams line will appear in the data filtering tab
	
	// === UNIVERSAL: DEFINE CORE IRIS PARAMETERS THAT DO NOT APPEAR IN THE GUI (do not modify) ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Sample Gases", num2str(numSampleGases), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Reference Gases", num2str(numRefGases), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Gas Parameters", num2str(numGasParams), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Calibration Parameters", num2str(numCalParams), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Filter Parameters", num2str(numFilterParams), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Basic System Parameters", num2str(numBasicParams), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Advanced System Parameters", num2str(numAdvancedParams), "" ); paramIndexCount += 1
	
	// === DEFINE INSTRUMENT-SPECIFIC PARAMETERS THAT DO NOT APPEAR IN THE GUI ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Pressure Sensor Limit for V2", "1000", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Pressure Sensor Limit for MPC", "100", "" ); paramIndexCount += 1
		
	// === UNIVERSAL: PROPAGATE PARAMETERS TO GUI TABLES (do not modify) ===
	
	IRIS_UTILITY_PropagateParamsToTables()
		
End

Function IRIS_SCHEME_DefineParams_D17O_d13C_CO2_CapeTown()

	IRIS_SCHEME_DefineParams_D17O_d13C_CO2()
	IRIS_UTILITY_SetParamValueByName("Ratio of Total System Volume to V2", "10")
	
End

Function IRIS_SCHEME_DefineParams_D17O_d13C_CO2_AnalysisOnly()
	
	// NOTE: "UNIVERSAL" sections must be included exactly as they are, exactly where they are.
	
	// === UNIVERSAL: DECLARATIONS (do not modify) ===
	
	variable paramIndexCount = 0
	variable i
	
	NVAR numOutputVariables = root:numOutputVariables
	wave/T wtOutputVariableNames = root:wtOutputVariableNames
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	
	NVAR numGasParams = root:numGasParams
	NVAR numCalParams = root:numCalParams
	NVAR numBasicParams = root:numBasicParams
	NVAR numAdvancedParams = root:numAdvancedParams
	NVAR numFilterParams = root:numFilterParams
	
	make/O/T/N=0 wtParamNames, wtParamValues, wtParamUnits
		
	// === DEFINE GAS INFO PARAMETERS ===
	
	for(i=0;i<numSampleGases;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Sample " + num2str(i+1) + ": " + "ID", "unknown", "" ); paramIndexCount += 1
	endfor
	for(i=0;i<numRefGases;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference " + num2str(i+1) + ": " + "ID", "unknown", "" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference " + num2str(i+1) + ": " + "CO2 Mole Fraction", "unknown", "ppm" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference " + num2str(i+1) + ": " + "δ13C", "unknown", "‰ VPDB" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference " + num2str(i+1) + ": " + "δ18O", "unknown", "‰ VSMOW" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference " + num2str(i+1) + ": " + "δ17O", "unknown", "‰ VSMOW" ); paramIndexCount += 1
		
	endfor
	numGasParams = paramIndexCount // the parameters above this line will appear in the gas info tab
	
	// === DEFINE CALIBRATION PARAMETERS ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Calibration Curve Equation", "c0*meas", "" ); paramIndexCount += 1
	numCalParams = paramIndexCount - numGasParams // the parameters above this line but below the numGasParams line will appear in the calibration tab; those below this line will appear in the basic system table
	
	// === DEFINE BASIC SYSTEM PARAMETERS ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Analysis Interval", "30", "(seconds)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Cycles", "0", "(use 0 for perpetual run)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Time Limit", "24", "hours" ); paramIndexCount += 1
	numBasicParams = paramIndexCount - numCalParams - numGasParams // the parameters above this line but below the numGasParams line will appear in the basic system table; those below this line will appear in the advanced system table
	
	// === DEFINE ADVANCED SYSTEM PARAMETERS ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference slope (λ)", "0.528", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Time to Ignore at Start of Measurement", "5", "seconds" ); paramIndexCount += 1
	for(i=0;i<numSampleGases;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "ECL Index for Sample " + num2str(i+1), num2str(i+1), "" ); paramIndexCount += 1
	endfor
	for(i=0;i<numRefGases;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "ECL Index for Reference " + num2str(i+1), num2str(numSampleGases+i+1), "" ); paramIndexCount += 1
	endfor
	numAdvancedParams = paramIndexCount - numBasicParams - numCalParams - numGasParams // the parameters above this line but below the numBasicParams line will appear in the advanced system table; those below this line will appear in the data filtering tab
	
	// === UNIVERSAL: DEFINE DATA FILTERING PARAMETERS (do not modify) ===
	
	for(i=0;i<numOutputVariables;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Check " + wtOutputVariableNames[i] + " for Outliers?", "n", "(y/n)" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Outlier Threshold for " + wtOutputVariableNames[i], "0", "standard deviations" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Outlier Filter Group for " + wtOutputVariableNames[i], "1", "" ); paramIndexCount += 1
	endfor
	numFilterParams = paramIndexCount - numAdvancedParams - numBasicParams - numCalParams - numGasParams // the parameters above this line but below the numAdvancedParams line will appear in the data filtering tab
	
	// === UNIVERSAL: DEFINE CORE IRIS PARAMETERS THAT DO NOT APPEAR IN THE GUI (do not modify) ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Sample Gases", num2str(numSampleGases), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Reference Gases", num2str(numRefGases), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Gas Parameters", num2str(numGasParams), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Calibration Parameters", num2str(numCalParams), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Filter Parameters", num2str(numFilterParams), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Basic System Parameters", num2str(numBasicParams), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Advanced System Parameters", num2str(numAdvancedParams), "" ); paramIndexCount += 1
	
	// === DEFINE INSTRUMENT-SPECIFIC PARAMETERS THAT DO NOT APPEAR IN THE GUI ===
		
	// === UNIVERSAL: PROPAGATE PARAMETERS TO GUI TABLES (do not modify) ===
	
	IRIS_UTILITY_PropagateParamsToTables()
		
End

Function IRIS_SCHEME_DefineParams_IceCore_d13C_CO2()
	
	// NOTE: "UNIVERSAL" sections must be included exactly as they are, exactly where they are.
	
	// === UNIVERSAL: DECLARATIONS (do not modify) ===
	
	variable paramIndexCount = 0
	variable i
	
	NVAR numOutputVariables = root:numOutputVariables
	wave/T wtOutputVariableNames = root:wtOutputVariableNames
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	
	NVAR numGasParams = root:numGasParams
	NVAR numCalParams = root:numCalParams
	NVAR numBasicParams = root:numBasicParams
	NVAR numAdvancedParams = root:numAdvancedParams
	NVAR numFilterParams = root:numFilterParams
	
	make/O/T/N=0 wtParamNames, wtParamValues, wtParamUnits
		
	// === DEFINE GAS INFO PARAMETERS ===
	
	for(i=0;i<numSampleGases;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Sample " + num2str(i+1) + ": " + "ID", "unknown", "" ); paramIndexCount += 1
	endfor
	for(i=0;i<numRefGases;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference " + num2str(i+1) + ": " + "ID", "unknown", "" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference " + num2str(i+1) + ": " + "CO2 Mole Fraction", "unknown", "ppm" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference " + num2str(i+1) + ": " + "δ13C", "unknown", "‰ VPDB" ); paramIndexCount += 1
	endfor
	numGasParams = paramIndexCount // the parameters above this line will appear in the gas info tab
	
	// === DEFINE CALIBRATION PARAMETERS ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Calibration Curve Equation", "c0*meas", "" ); paramIndexCount += 1
	numCalParams = paramIndexCount - numGasParams // the parameters above this line but below the numGasParams line will appear in the calibration tab; those below this line will appear in the basic system table
	
	// === DEFINE BASIC SYSTEM PARAMETERS ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Cycles", "0", "(use 0 for perpetual run)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Time Limit", "24", "hours" ); paramIndexCount += 1
	numBasicParams = paramIndexCount - numCalParams - numGasParams // the parameters above this line but below the numGasParams line will appear in the basic system table; those below this line will appear in the advanced system table
	
	// === DEFINE ADVANCED SYSTEM PARAMETERS ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Measurement Duration", "90", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Time to Ignore at Start of Measurement", "3", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Subtract Background Spectrum", "y", "(y/n)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Background Measurement Duration", "10", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Background Measurement Interval", "0", "minutes (use 0 for infinity)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Use Zero Air as an Additional Reference", "n", "(y/n)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Vacuum Time before Fill of MPC", "25", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Vacuum Time before Background", "25", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Target MPC Pressure", "4", "Torr" ); paramIndexCount += 1
	for(i=0;i<numSampleGases;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "ECL Index for Sample " + num2str(i+1), num2str(i+1), "" ); paramIndexCount += 1
	endfor
	for(i=0;i<numRefGases;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "ECL Index for Reference " + num2str(i+1), num2str(numSampleGases+i+1), "" ); paramIndexCount += 1
	endfor
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "ECL Index for Zero Air", num2str(numSampleGases+numRefGases+1), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "ECL Index for Transition", num2str(numSampleGases+numRefGases+2), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Inlet", "0", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for MPC", "4", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Vacuum", "5", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "VICI Port for Ref 1", "1", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "VICI Port for Vac 1", "2", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "VICI Port for Ref 2", "3", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "VICI Port for Vac 2", "4", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "VICI Port for Sample", "5", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "VICI Port for Dead End", "6", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Pressure Sensor Number for MPC", "0", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Action Time Spacer", "0.3", "seconds" ); paramIndexCount += 1
	numAdvancedParams = paramIndexCount - numBasicParams - numCalParams - numGasParams // the parameters above this line but below the numBasicParams line will appear in the advanced system table; those below this line will appear in the data filtering tab
	
	// === UNIVERSAL: DEFINE DATA FILTERING PARAMETERS (do not modify) ===
	
	for(i=0;i<numOutputVariables;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Check " + wtOutputVariableNames[i] + " for Outliers?", "n", "(y/n)" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Outlier Threshold for " + wtOutputVariableNames[i], "0", "standard deviations" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Outlier Filter Group for " + wtOutputVariableNames[i], "1", "" ); paramIndexCount += 1
	endfor
	numFilterParams = paramIndexCount - numAdvancedParams - numBasicParams - numCalParams - numGasParams // the parameters above this line but below the numAdvancedParams line will appear in the data filtering tab
	
	// === UNIVERSAL: DEFINE CORE IRIS PARAMETERS THAT DO NOT APPEAR IN THE GUI (do not modify) ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Sample Gases", num2str(numSampleGases), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Reference Gases", num2str(numRefGases), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Gas Parameters", num2str(numGasParams), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Calibration Parameters", num2str(numCalParams), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Filter Parameters", num2str(numFilterParams), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Basic System Parameters", num2str(numBasicParams), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Advanced System Parameters", num2str(numAdvancedParams), "" ); paramIndexCount += 1
	
	// === DEFINE INSTRUMENT-SPECIFIC PARAMETERS THAT DO NOT APPEAR IN THE GUI ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Pressure Sensor Limit for MPC", "10", "" ); paramIndexCount += 1
		
	// === UNIVERSAL: PROPAGATE PARAMETERS TO GUI TABLES (do not modify) ===
	
	IRIS_UTILITY_PropagateParamsToTables()
	
End

Function IRIS_SCHEME_DefineParams_IceCore_d13C_CO2_noVICI()
	
	// NOTE: "UNIVERSAL" sections must be included exactly as they are, exactly where they are.
	
	// === UNIVERSAL: DECLARATIONS (do not modify) ===
	
	variable paramIndexCount = 0
	variable i
	
	NVAR numOutputVariables = root:numOutputVariables
	wave/T wtOutputVariableNames = root:wtOutputVariableNames
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	
	NVAR numGasParams = root:numGasParams
	NVAR numCalParams = root:numCalParams
	NVAR numBasicParams = root:numBasicParams
	NVAR numAdvancedParams = root:numAdvancedParams
	NVAR numFilterParams = root:numFilterParams
	
	make/O/T/N=0 wtParamNames, wtParamValues, wtParamUnits
	
	// === DEFINE GAS INFO PARAMETERS ===
	
	for(i=0;i<numSampleGases;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Sample " + num2str(i+1) + ": " + "ID", "unknown", "" ); paramIndexCount += 1
	endfor
	for(i=0;i<numRefGases;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference " + num2str(i+1) + ": " + "ID", "unknown", "" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference " + num2str(i+1) + ": " + "CO2 Mole Fraction", "unknown", "ppm" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference " + num2str(i+1) + ": " + "δ13C", "unknown", "‰ VPDB" ); paramIndexCount += 1
	endfor
	numGasParams = paramIndexCount // the parameters above this line will appear in the gas info tab
	
	// === DEFINE CALIBRATION PARAMETERS ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Calibration Curve Equation", "c0*meas", "" ); paramIndexCount += 1
	numCalParams = paramIndexCount - numGasParams // the parameters above this line but below the numGasParams line will appear in the calibration tab; those below this line will appear in the basic system table
	
	// === DEFINE BASIC SYSTEM PARAMETERS ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Cycles", "0", "(use 0 for perpetual run)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Time Limit", "24", "hours" ); paramIndexCount += 1
	numBasicParams = paramIndexCount - numCalParams - numGasParams // the parameters above this line but below the numGasParams line will appear in the basic system table; those below this line will appear in the advanced system table
	
	// === DEFINE ADVANCED SYSTEM PARAMETERS ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Measurement Duration", "90", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Time to Ignore at Start of Measurement", "3", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Subtract Background Spectrum", "y", "(y/n)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Background Measurement Duration", "10", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Background Measurement Interval", "0", "minutes (use 0 for infinity)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Use Zero Air as an Additional Reference", "n", "(y/n)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Vacuum Time before Flush of MPC", "10", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Vacuum Time before Fill of MPC", "25", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Vacuum Time before Background", "25", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Vacuum Time for Sample Side", "10", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Target Pressure for Flush of MPC", "2", "Torr" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Target MPC Pressure", "2", "Torr" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Flushes of MPC", "0", "Torr" ); paramIndexCount += 1
	for(i=0;i<numSampleGases;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "ECL Index for Sample " + num2str(i+1), num2str(i+1), "" ); paramIndexCount += 1
	endfor
	for(i=0;i<numRefGases;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "ECL Index for Reference " + num2str(i+1), num2str(numSampleGases+i+1), "" ); paramIndexCount += 1
	endfor
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "ECL Index for Zero Air", num2str(numSampleGases+numRefGases+1), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "ECL Index for Transition", num2str(numSampleGases+numRefGases+2), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Sample Inlet", "0", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Ref Inlet", "1", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Sample Vac", "2", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for MPC", "4", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Main Vac", "5", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Flush", "3", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Pressure Sensor Number for MPC", "0", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Action Time Spacer", "0.3", "seconds" ); paramIndexCount += 1
	numAdvancedParams = paramIndexCount - numBasicParams - numCalParams - numGasParams // the parameters above this line but below the numBasicParams line will appear in the advanced system table; those below this line will appear in the data filtering tab
	
	// === UNIVERSAL: DEFINE DATA FILTERING PARAMETERS (do not modify) ===
	
	for(i=0;i<numOutputVariables;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Check " + wtOutputVariableNames[i] + " for Outliers?", "n", "(y/n)" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Outlier Threshold for " + wtOutputVariableNames[i], "0", "standard deviations" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Outlier Filter Group for " + wtOutputVariableNames[i], "1", "" ); paramIndexCount += 1
	endfor
	numFilterParams = paramIndexCount - numAdvancedParams - numBasicParams - numCalParams - numGasParams // the parameters above this line but below the numAdvancedParams line will appear in the data filtering tab
	
	// === UNIVERSAL: DEFINE CORE IRIS PARAMETERS THAT DO NOT APPEAR IN THE GUI (do not modify) ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Sample Gases", num2str(numSampleGases), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Reference Gases", num2str(numRefGases), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Gas Parameters", num2str(numGasParams), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Calibration Parameters", num2str(numCalParams), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Filter Parameters", num2str(numFilterParams), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Basic System Parameters", num2str(numBasicParams), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Advanced System Parameters", num2str(numAdvancedParams), "" ); paramIndexCount += 1
	
	// === DEFINE INSTRUMENT-SPECIFIC PARAMETERS THAT DO NOT APPEAR IN THE GUI ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Pressure Sensor Limit for MPC", "10", "" ); paramIndexCount += 1
		
	// === UNIVERSAL: PROPAGATE PARAMETERS TO GUI TABLES (do not modify) ===
	
	IRIS_UTILITY_PropagateParamsToTables()
	
End

Function IRIS_SCHEME_DefineParams_D638_CO2()
	
	// NOTE: "UNIVERSAL" sections must be included exactly as they are, exactly where they are.
	
	// === UNIVERSAL: DECLARATIONS (do not modify) ===
	
	variable paramIndexCount = 0
	variable i
	
	NVAR numOutputVariables = root:numOutputVariables
	wave/T wtOutputVariableNames = root:wtOutputVariableNames
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	
	NVAR numGasParams = root:numGasParams
	NVAR numCalParams = root:numCalParams
	NVAR numBasicParams = root:numBasicParams
	NVAR numAdvancedParams = root:numAdvancedParams
	NVAR numFilterParams = root:numFilterParams
	
	make/O/T/N=0 wtParamNames, wtParamValues, wtParamUnits
		
	// === DEFINE GAS INFO PARAMETERS ===
	
	for(i=0;i<numSampleGases;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Sample " + num2str(i+1) + ": " + "ID", "unknown", "" ); paramIndexCount += 1
	endfor
	for(i=0;i<numRefGases;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference " + num2str(i+1) + ": " + "ID", "unknown", "" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference " + num2str(i+1) + ": " + "CO2 Mole Fraction", "unknown", "ppm" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference " + num2str(i+1) + ": " + "δ13C", "unknown", "‰ VPDB" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference " + num2str(i+1) + ": " + "δ18O", "unknown", "‰ VSMOW" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Reference " + num2str(i+1) + ": " + "Δ638", "unknown", "‰" ); paramIndexCount += 1
	endfor
	numGasParams = paramIndexCount // the parameters above this line will appear in the gas info tab
	
	// === DEFINE CALIBRATION PARAMETERS ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Calibration Curve Equation", "c0*meas", "" ); paramIndexCount += 1
	numCalParams = paramIndexCount - numGasParams // the parameters above this line but below the numGasParams line will appear in the calibration tab; those below this line will appear in the basic system table
	
	// === DEFINE BASIC SYSTEM PARAMETERS ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Cycles", "10", "(use 0 for perpetual run)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Time Limit", "24", "hours" ); paramIndexCount += 1
	numBasicParams = paramIndexCount - numCalParams - numGasParams // the parameters above this line but below the numGasParams line will appear in the basic system table; those below this line will appear in the advanced system table
	
	// === DEFINE ADVANCED SYSTEM PARAMETERS ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Measurement Duration", "30", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Time to Ignore at Start of Measurement", "5", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Subtract Background Spectrum", "y", "(y/n)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Use Zero Air from Ref Orifice for Background Spectrum", "n", "(y/n)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Background Measurement Duration", "10", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Background Measurement Interval", "0", "minutes (use 0 for infinity)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Flushes of V2", "1", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Flushes of MPC", "2", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Vacuum Time for Ref Pre-Orifice Volume", "10", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Vacuum Time before Flush of V2", "10", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Vacuum Time before Final Fill of V2", "10", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Vacuum Time before Flush of MPC", "10", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Vacuum Time before Final Fill of MPC", "10", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Vacuum Time before Background", "10", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Time to Wait for Fill of MPC from V2", "2", "seconds" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Target MPC Pressure", "30", "Torr" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Target Pressure for Flush of V2", "80", "Torr" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Target Pressure for Flush of MPC", "80", "Torr" ); paramIndexCount += 1
	for(i=0;i<numSampleGases;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "ECL Index for Sample " + num2str(i+1), num2str(i+1), "" ); paramIndexCount += 1
	endfor
	for(i=0;i<numRefGases;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "ECL Index for Reference " + num2str(i+1), num2str(numSampleGases+i+1), "" ); paramIndexCount += 1
	endfor
	//	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "ECL Index for Zero Air", num2str(numSampleGases+numRefGases+1), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "ECL Index for Transition", num2str(numSampleGases+numRefGases+2), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Sample Orifice", "0", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Ref Orifice", "1", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for MPC", "2", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Flush", "3", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Vacuum", "4", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for V2", "5", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Working Ref Supply to Ref Orifice", "6", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Zero Air Supply to Ref Orifice", "7", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Number for Vacuum Supply to Ref Orifice", "8", "(counting from 0)" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Pressure Sensor Number for MPC", "0", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Pressure Sensor Number for V2", "1", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Ratio of Total System Volume to V2", "9.5", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Valve Action Time Spacer", "0.3", "seconds" ); paramIndexCount += 1
	numAdvancedParams = paramIndexCount - numBasicParams - numCalParams - numGasParams // the parameters above this line but below the numBasicParams line will appear in the advanced system table; those below this line will appear in the data filtering tab
	
	// === UNIVERSAL: DEFINE DATA FILTERING PARAMETERS (do not modify) ===
	
	for(i=0;i<numOutputVariables;i+=1)
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Check " + wtOutputVariableNames[i] + " for Outliers?", "n", "(y/n)" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Outlier Threshold for " + wtOutputVariableNames[i], "0", "standard deviations" ); paramIndexCount += 1
		IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Outlier Filter Group for " + wtOutputVariableNames[i], "1", "" ); paramIndexCount += 1
	endfor
	numFilterParams = paramIndexCount - numAdvancedParams - numBasicParams - numCalParams - numGasParams // the parameters above this line but below the numAdvancedParams line will appear in the data filtering tab
	
	// === UNIVERSAL: DEFINE CORE IRIS PARAMETERS THAT DO NOT APPEAR IN THE GUI (do not modify) ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Sample Gases", num2str(numSampleGases), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Reference Gases", num2str(numRefGases), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Gas Parameters", num2str(numGasParams), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Calibration Parameters", num2str(numCalParams), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Filter Parameters", num2str(numFilterParams), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Basic System Parameters", num2str(numBasicParams), "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Number of Advanced System Parameters", num2str(numAdvancedParams), "" ); paramIndexCount += 1
	
	// === DEFINE INSTRUMENT-SPECIFIC PARAMETERS THAT DO NOT APPEAR IN THE GUI ===
	
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Pressure Sensor Limit for V2", "1000", "" ); paramIndexCount += 1
	IRIS_UTILITY_SetParamNameValueAndUnits( paramIndexCount, "Pressure Sensor Limit for MPC", "100", "" ); paramIndexCount += 1
		
	// === UNIVERSAL: PROPAGATE PARAMETERS TO GUI TABLES (do not modify) ===
	
	IRIS_UTILITY_PropagateParamsToTables()
		
End

////////////////////////////////////
// Roster of Scheduling Functions //
////////////////////////////////////

// IMPORTANT NOTE: There are 4 key schedules that MUST be created with these exact names:
// 1. A schedule called "Reset", which clears the ECL queue, closes the valves, and starts a new STR/STC file (this will be directly invoked when the "STOP" button is clicked and is also a convenient building block for the Prologue and Epilogue);
// 2. A schedule called "Prologue", which consists of the things that happen only at the beginning of the run;
// 3. A schedule called "Cycle", which consists of the things that happen repetitively;
// 4. A schedule called "Epilogue", which consists of the things that happen only at the end of the run, after the last cycle.
// (Any number of additional schedules with other names can be created and used as building blocks for the 4 key schedules.)

// ADDITIONAL NOTES:
// - Timer 0 is reserved for time since the previous schedule event. Most events are timed in this way.
// - If StartTimer = 0, then no other timer is started. If StartTimer = n (>0), then a timer with ID n is started.
// - WhichTimer gives the ID number n of the timer to use when checking whether TriggerTime has been reached.
// - So far, only timer 0 and timer 1 are useful. Timer 1 will be the time since the current sample or ref
//   measurement period began. The command to vacuum out the MPC will not be issued until the trigger
//   time has reached the desired measurement time relative to timer 1. Everything else will just use the
//   time relative to the previous schedule event (timer 0).
// - The aza command creates a unique situation (so far) because the length of time needed to complete aza is not
//   known in advance. So the command following the aza command does not trigger until the aza is done, and Timer 0
//   is reset when the aza fill completes, so that the timer 0 trigger time for the command after the aza
//   command is not the time since the aza command was sent, but rather the time since the aza fill completed.

Function IRIS_SCHEME_BuildSchedule_D17O_CO2()
	
	// NOTE: "UNIVERSAL" sections must be included exactly as they are, exactly where they are.
	
	// === UNIVERSAL: DECLARATIONS (do not modify) ===
	
	NVAR minNumSamples = root:minNumSamples
	NVAR maxNumSamples = root:maxNumSamples
	NVAR minNumRefs = root:minNumRefs
	NVAR maxNumRefs = root:maxNumRefs
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	NVAR numGases = root:numGases
	
	SetDataFolder root:
	
	// === DEFINE MAXIMUM AND MINIMUM ALLOWED NUMBERS OF SAMPLE AND REFERENCE GASES BASED ON HARDWARE ===
	
	minNumSamples = 1
	maxNumSamples = 1
	minNumRefs = 1
	maxNumRefs = 1
	
	// === GET VARIABLES FROM CONFIG PARAMS ===
	
	// Hardware setup
	string valveNum_sample1 = IRIS_UTILITY_GetParamValueFromName("Valve Number for Sample 1")
	string valveNum_ref1 = IRIS_UTILITY_GetParamValueFromName("Valve Number for Reference 1")
	string valveNum_intermediateVolume = IRIS_UTILITY_GetParamValueFromName("Valve Number for V2")
	string valveNum_flush = IRIS_UTILITY_GetParamValueFromName("Valve Number for Flush")
	string valveNum_mainVac = IRIS_UTILITY_GetParamValueFromName("Valve Number for Vacuum")
	string valveNum_cell = IRIS_UTILITY_GetParamValueFromName("Valve Number for MPC")
	string PsensorForMPC = IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Number for MPC")
	string PsensorForV2 = IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Number for V2")
	variable system_to_V2_volume_ratio = str2num(IRIS_UTILITY_GetParamValueFromName("Ratio of Total System Volume to V2"))
	
	// Pressure sensor limits
	variable pressureSensorLimitForV2 = str2num(IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Limit for V2")) // torr, used to prevent the user from selecting target pressures that can never be measured, which would lead to runaway aza (up to its internal time limit)
	variable pressureSensorLimitForMPC = str2num(IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Limit for MPC")) // torr, used to prevent the user from selecting target pressures that can never be measured, which would lead to runaway aza (up to its internal time limit)
	
	// Timing, repetitions, and ABG
	variable doABG = (stringMatch( IRIS_UTILITY_GetParamValueFromName("Subtract Background Spectrum"), "y*" ) == 1) ? 1 : 0 // 0 = no, 1 = yes
	variable ABGinterval = 60*str2num(IRIS_UTILITY_GetParamValueFromName("Background Measurement Interval")) // seconds
	variable backgroundDuration = str2num(IRIS_UTILITY_GetParamValueFromName("Background Measurement Duration")) // seconds
	backgroundDuration += 5 // 5 second safety margin
	variable numV2flushes = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Flushes of V2")) // number of intermediate volume flushes with nitrogen
	variable numMPCflushes = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Flushes of MPC")) // number of multipass cell flushes with nitrogen
	variable measurementDuration = str2num(IRIS_UTILITY_GetParamValueFromName("Measurement Duration")) // seconds
	variable V2evacTimeForFlush = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Flush of V2")) // seconds
	variable V2evacTimeForFinalFill = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Final Fill of V2")) // seconds
	variable MPCevacTimeForFlush = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Flush of MPC")) // seconds
	variable MPCevacTimeForFinalFill = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Final Fill of MPC")) // seconds
	variable MPCevacTimeForABG = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Background")) // seconds
	variable MPCfillTimeFromV2 = str2num(IRIS_UTILITY_GetParamValueFromName("Time to Wait for Fill of MPC from V2")) // seconds
	variable valveActionTimeSpacer = str2num(IRIS_UTILITY_GetParamValueFromName("Valve Action Time Spacer")) // number of seconds to wait before sending valve open or close command, to avoid sending effectively overlapping commands
	
	// Pressures
	variable target_MPC_pressure = str2num(IRIS_UTILITY_GetParamValueFromName("Target MPC Pressure")) // torr
	variable pressureTemp
	pressureTemp = target_MPC_pressure
	if(pressureTemp > 0.9*pressureSensorLimitForMPC) // includes a safety margin of 10% of the sensor range
		pressureTemp = 0.9*pressureSensorLimitForMPC
		target_MPC_pressure = pressureTemp
		IRIS_UTILITY_SetParamValueByName( "Target MPC Pressure", num2str(target_MPC_pressure) )
		IRIS_UTILITY_PropagateParamsToTables()
		IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", "*** WARNING: Target pressure reduced to sensor limit! ***")
	endif
	string V2targetPressureForFlush = IRIS_UTILITY_GetParamValueFromName("Target Pressure for Flush of V2") // torr
	pressureTemp = str2num(V2targetPressureForFlush)
	if(pressureTemp > 0.9*pressureSensorLimitForV2) // includes a safety margin of 10% of the sensor range
		pressureTemp = 0.9*pressureSensorLimitForV2
		V2targetPressureForFlush = num2str(pressureTemp)
		IRIS_UTILITY_SetParamValueByName( "Target Pressure for Flush of V2", V2targetPressureForFlush )
		IRIS_UTILITY_PropagateParamsToTables()
		IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", "*** WARNING: Target pressure reduced to sensor limit! ***")
	endif
	string MPCtargetPressureForFlush = IRIS_UTILITY_GetParamValueFromName("Target Pressure for Flush of MPC") // torr
	pressureTemp = str2num(MPCtargetPressureForFlush)
	if(pressureTemp > 0.9*pressureSensorLimitForMPC) // includes a safety margin of 10% of the sensor range
		pressureTemp = 0.9*pressureSensorLimitForMPC
		MPCtargetPressureForFlush = num2str(pressureTemp)
		IRIS_UTILITY_SetParamValueByName( "Target Pressure for Flush of MPC", MPCtargetPressureForFlush )
		IRIS_UTILITY_PropagateParamsToTables()
		IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", "*** WARNING: Target pressure reduced to sensor limit! ***")
	endif
	string V2targetPressureForFinalFill = num2istr(target_MPC_pressure*system_to_V2_volume_ratio) // torr
	
	// ECL indices
	string ECL_sampleIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Sample 1")
	string ECL_refIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Reference 1")
	string ECL_transitionIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Transition")
	
	variable i, j
	
	// === MAKE SCHEDULE MODULES TO USE AS BUILDING BLOCKS ===
	
	// USAGE: IRIS_UTILITY_AppendEventToSchedule(sScheduleName, whichTimer, triggerTime, sAction, sArgument, sComment)
	// where sAction is a string that will be appended to "IRIS_EVENT_" to create a reference to a function that takes at most one argument (sArgument), which must be a string
	//	e.g. IRIS_EVENT_SendECL, IRIS_EVENT_ReportStatus, IRIS_EVENT_FetchData, IRIS_EVENT_StartTimer
	
	// Flush V2
	IRIS_UTILITY_ClearSchedule("FlushV2")
	if(numV2flushes > 0)
		IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_intermediateVolume, "open intermediate volume valve")
		for(i=0;i<numV2flushes;i+=1)
			IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, 0, "ReportStatus", "Evacuating intermediate volume", "")
			IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, V2evacTimeForFlush, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, 0, "ReportStatus", "Filling int. volume with flush gas", "")
			IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, valveActionTimeSpacer, "SendECL", "aza" + PsensorForV2 + "," + valveNum_flush + "," + V2targetPressureForFlush, "fill intermediate volume with nitrogen")
		endfor
		IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_intermediateVolume, "close intermediate volume valve")
	endif
	
	// Flush MPC
	IRIS_UTILITY_ClearSchedule("FlushMPC")
	if(numMPCflushes > 0)
		IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_cell, "open MPC valve")
		for(i=0;i<numMPCflushes;i+=1)
			IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, 0, "ReportStatus", "Evacuating absorption cell", "")
			IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, MPCevacTimeForFlush, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, 0, "ReportStatus", "Filling cell with flush gas", "")
			IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, valveActionTimeSpacer, "SendECL", "aza" + PsensorForMPC + "," + valveNum_flush + "," + MPCtargetPressureForFlush, "fill MPC with nitrogen")
		endfor
		IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_cell, "close MPC valve")
	endif
	
	// Measure and Subtract Background Spectrum
	IRIS_UTILITY_ClearSchedule("SubtractBackground")
	IRIS_UTILITY_AppendScheduleToSchedule("SubtractBackground", "FlushMPC")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_cell, "open MPC valve")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ReportStatus", "Evacuating absorption cell", "")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, MPCevacTimeForABG, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_cell, "close MPC valve")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 1, "SendECL", "amabg1", "enable ABG")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ReportStatus", "Measuring spectral background", "")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "aq", "do a BG measurement")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, backgroundDuration, "", "", "wait for ABG to complete")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ResetABGtimer", "", "reset ABG timer")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ReportStatus", "Done measuring spectral background", "")
	
	// Fill V2 with Reference
	IRIS_UTILITY_ClearSchedule("FillV2withRef")
	if(V2evacTimeForFinalFill > 0)
		IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, 0, "ReportStatus", "Evacuating intermediate volume", "")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_intermediateVolume, "open intermediate volume valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, V2evacTimeForFinalFill, "SendECL", "anc" + valveNum_intermediateVolume, "close intermediate volume valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
	endif
	IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, 0, "ReportStatus", "Filling int. volume with reference", "")
	IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, valveActionTimeSpacer, "SendECL", "aza" + PsensorForV2 + "," + valveNum_ref1 + "," + V2targetPressureForFinalFill, "fill intermediate volume with working reference")
	
	// Fill V2 with Sample
	IRIS_UTILITY_ClearSchedule("FillV2withSample")
	if(V2evacTimeForFinalFill > 0)
		IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, 0, "ReportStatus", "Evacuating intermediate volume", "")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_intermediateVolume, "open intermediate volume valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, V2evacTimeForFinalFill, "SendECL", "anc" + valveNum_intermediateVolume, "close intermediate volume valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
	endif
	IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, 0, "ReportStatus", "Filling int. volume with sample", "")
	IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, valveActionTimeSpacer, "SendECL", "aza" + PsensorForV2 + "," + valveNum_sample1 + "," + V2targetPressureForFinalFill, "fill intermediate volume with sample")
	
	// Fill MPC from V2
	IRIS_UTILITY_ClearSchedule("FillMPC")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, 0, "ReportStatus", "Evacuating absorption cell", "")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_cell, "open MPC valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, MPCevacTimeForFinalFill, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, 0, "ReportStatus", "Filling cell from intermediate volume", "")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_intermediateVolume, "open intermediate volume valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, MPCfillTimeFromV2, "SendECL", "anc" + valveNum_cell, "close MPC valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_intermediateVolume, "close intermediate volume valve")
	
	// Start transition period
	IRIS_UTILITY_ClearSchedule("StartTransition")
	IRIS_UTILITY_AppendEventToSchedule("StartTransition", 0, 0, "SendECL", "bz" + ECL_transitionIndex, "set ECL index to transition")
	IRIS_UTILITY_AppendEventToSchedule("StartTransition", 0, 0, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule("StartTransition", 0, 0, "SendECL", "bdfits1", "suspend spectral fits")
	
	// Start reference measurement
	IRIS_UTILITY_ClearSchedule("StartRefMeas")
	IRIS_UTILITY_AppendEventToSchedule("StartRefMeas", 0, 0, "SendECL", "bdfits0", "activate spectral fits")
	IRIS_UTILITY_AppendEventToSchedule("StartRefMeas", 0, 0, "SendECL", "bz" + ECL_refIndex, "set ECL index to working reference")
	IRIS_UTILITY_AppendEventToSchedule("StartRefMeas", 0, 0, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule("StartRefMeas", 0, 0, "ReportStatus", "Starting reference measurement", "")
	
	// Start sample measurement
	IRIS_UTILITY_ClearSchedule("StartSampleMeas")
	IRIS_UTILITY_AppendEventToSchedule("StartSampleMeas", 0, 0, "SendECL", "bdfits0", "activate spectral fits")
	IRIS_UTILITY_AppendEventToSchedule("StartSampleMeas", 0, 0, "SendECL", "bz" + ECL_sampleIndex, "set ECL index to sample")
	IRIS_UTILITY_AppendEventToSchedule("StartSampleMeas", 0, 0, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule("StartSampleMeas", 0, 0, "ReportStatus", "Starting sample measurement", "")
	
	// Redo ABG measurement
	IRIS_UTILITY_ClearSchedule("RedoABG")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FlushMPC") // Flush MPC and then fill it with working reference from V2
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FillMPC")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "StartRefMeas") // Start measuring reference
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 0, 0, "StartTimer", "1", "start timer for reference measurement") // start timer 1
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FlushV2") // Flush V2 and then fill it with working reference (while previous ref is being measured in MPC)
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FillV2withRef")
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 1, measurementDuration, "", "", "wait for reference measurement to complete") // Wait for reference measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 0, 0, "ReportStatus", "Reference measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "StartTransition")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "SubtractBackground") // Flush MPC and record background spectrum
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 0, 1, "ResumeCycleSchedule", "", "resume Cycle schedule") // Return to the usual Cycle schedule	
	
	// === BUILD THE RESET SCHEDULE ===
	// 1. A schedule called "Reset", which clears the ECL queue, closes the valves, and starts a new STR/STC file (this will be directly invoked when the "STOP" button is clicked and is also a convenient building block for the Prologue and Epilogue);
	
	// Reset sampling system
	IRIS_UTILITY_ClearSchedule("Reset")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 0, "ReportStatus", "Resetting sampling system", "")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 0, "SendECL", "cq", "immediately clear the ECL queue (this command jumps to the front of the queue)")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 3, "SendECL", "bz" + ECL_transitionIndex, "set ECL index to transition")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "amabg0", "disable ABG")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "bdfits0", "activate spectral fits")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc0", "close valve 0")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc1", "close valve 1")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc2", "close valve 2")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc3", "close valve 3")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc4", "close valve 4")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc5", "close valve 5")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "amwd0", "deactivate write disk")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "amass0", "deactivate auto spectral save")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 1, "FetchData", "", "fetch latest data")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 1, "SendECL", "amwd1", "activate write disk")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "amass1", "activate auto spectral save")
	
	// === BUILD THE PROLOGUE SCHEDULE ===
	// 2. A schedule called "Prologue", which consists of the things that happen only at the beginning of the run;
	
	IRIS_UTILITY_ClearSchedule("Prologue")
	
	// Reset sampling system
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "Reset")
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "StartTransition")
	
	// Flush MPC and record background spectrum
	if(doABG == 1)
		IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "SubtractBackground")
	endif
	
	// Flush V2 and then fill it with working reference
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "FlushV2")
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "FillV2withRef")
	
	// === BUILD THE CYCLE SCHEDULE ===
	// 3. A schedule called "Cycle", which consists of the things that happen repetitively;
	
	IRIS_UTILITY_ClearSchedule("Cycle")
	
	// Flush MPC and then fill it with working reference from V2
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FlushMPC")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillMPC")
	
	// Start measuring reference
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartRefMeas")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "StartTimer", "1", "start timer for reference measurement") // start timer 1
	
	// Flush V2 and then fill it with sample (while working reference is being measured in MPC)
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FlushV2")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillV2withSample")
	
	// Wait for reference measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 1, measurementDuration, "", "", "wait for reference measurement to complete") // wait until timer 1 reaches measurementDuration
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "ReportStatus", "Reference measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartTransition")
	
	// Flush MPC and then fill it with sample from V2
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FlushMPC")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillMPC")
	
	// Start measuring sample
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartSampleMeas")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "StartTimer", "1", "start timer for sample measurement") // start timer 1
	
	// Flush V2 and then fill it with working reference (while sample is being measured in MPC)
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FlushV2")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillV2withRef")
	
	// Fetch latest data (while sample is being measured in MPC)
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "ReportStatus", "Fetching and analyzing data", "")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 1, "FetchData", "", "fetch latest data")
	
	// Wait for sample measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 1, measurementDuration, "", "", "wait for sample measurement to complete") // wait until timer 1 reaches measurementDuration
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "ReportStatus", "Sample measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartTransition")
	
	// Check ABG interval and redo ABG if appropriate (only include this as the very last instruction in a cycle, and make sure you have defined a schedule called "RedoABG" above!)
	if((doABG == 1) && (ABGinterval > 0))
		IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 1, "CheckABGinterval", "", "check whether it is time to redo the background")
	endif
	
	// === BUILD THE EPILOGUE SCHEDULE ===
	// 4. A schedule called "Epilogue", which consists of the things that happen only at the end of the run, after the last cycle.
	
	IRIS_UTILITY_ClearSchedule("Epilogue")
	
	// Flush MPC and then fill it with working reference from V2
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "FlushMPC")
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "FillMPC")
	
	// Start measuring reference
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "StartRefMeas")
	IRIS_UTILITY_AppendEventToSchedule("Epilogue", 0, 0, "StartTimer", "1", "start timer for reference measurement") // start timer 1
	
	// Wait for reference measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("Epilogue", 1, measurementDuration, "", "", "wait for reference measurement to complete") // wait until timer 1 reaches measurementDuration
	IRIS_UTILITY_AppendEventToSchedule("Epilogue", 0, 0, "ReportStatus", "Reference measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "StartTransition")
	
	// Reset sampling system
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "Reset")
	
	DoUpdate
	
End

Function IRIS_SCHEME_BuildSchedule_D17O_CO2_Bellows()
	
	// NOTE: "UNIVERSAL" sections must be included exactly as they are, exactly where they are.
	
	// === UNIVERSAL: DECLARATIONS (do not modify) ===
	
	NVAR minNumSamples = root:minNumSamples
	NVAR maxNumSamples = root:maxNumSamples
	NVAR minNumRefs = root:minNumRefs
	NVAR maxNumRefs = root:maxNumRefs
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	NVAR numGases = root:numGases
	
	SetDataFolder root:
	
	// === DEFINE MAXIMUM AND MINIMUM ALLOWED NUMBERS OF SAMPLE AND REFERENCE GASES BASED ON HARDWARE ===
	
	minNumSamples = 1
	maxNumSamples = 1
	minNumRefs = 1
	maxNumRefs = 1
	
	// === GET VARIABLES FROM CONFIG PARAMS ===
	
	// Hardware setup
	string valveNum_samplePrep = IRIS_UTILITY_GetParamValueFromName("Valve Number for Sample Prep")
	string valveNum_sampleInject = IRIS_UTILITY_GetParamValueFromName("Valve Number for Sample Inject")
	string valveNum_refInject = IRIS_UTILITY_GetParamValueFromName("Valve Number for Reference Inject")
	string valveNum_mainVac = IRIS_UTILITY_GetParamValueFromName("Valve Number for Vacuum")
	string valveNum_nitrogen = IRIS_UTILITY_GetParamValueFromName("Valve Number for N2")
	//	string valveNum_refPrep = IRIS_UTILITY_GetParamValueFromName("Valve Number for Reference Prep")
	string PsensorForMPC = "0"
		
	// Get pressure sensor limits
//	NVAR pressureSensorLimitForMPC = root:pressureSensorLimitForMPC // torr, used to prevent the user from selecting target pressures that can never be measured, which would lead to runaway aza (up to its internal time limit)
	variable pressureSensorLimitForMPC = str2num(IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Limit for MPC")) // torr, used to prevent the user from selecting target pressures that can never be measured, which would lead to runaway aza (up to its internal time limit)
	
	// Timing, repetitions, and ABG
	variable clearPrepTubesAtStart = (stringMatch( IRIS_UTILITY_GetParamValueFromName("Clear Prep Tubes At Start"), "y*" ) == 1) ? 1 : 0 // 0 = no, 1 = yes
	variable prepTime = str2num(IRIS_UTILITY_GetParamValueFromName("Time to Wait After Clearing Prep Tubes")) // seconds
	variable doABG = (stringMatch( IRIS_UTILITY_GetParamValueFromName("Subtract Background Spectrum"), "y*" ) == 1) ? 1 : 0 // 0 = no, 1 = yes
	variable ABGinterval = 60*str2num(IRIS_UTILITY_GetParamValueFromName("Background Measurement Interval")) // seconds
	variable backgroundDuration = str2num(IRIS_UTILITY_GetParamValueFromName("Background Measurement Duration")) // seconds
	backgroundDuration += 5 // 5 second safety margin
	variable numFlushes = str2num(IRIS_UTILITY_GetParamValueFromName("Number of N2 Flushes")) // number of multipass cell flushes with nitrogen
	variable measurementDuration = str2num(IRIS_UTILITY_GetParamValueFromName("Measurement Duration")) // seconds
	variable evacTimeForFlush = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Flush")) // seconds
	variable evacTimeForFinalFill = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Final Fill")) // seconds
	variable MPCfillTimeFromPrepTube = str2num(IRIS_UTILITY_GetParamValueFromName("Time to Wait for Fill of MPC from Prep Tube")) // seconds
	variable valveActionTimeSpacer = str2num(IRIS_UTILITY_GetParamValueFromName("Valve Action Time Spacer")) // number of seconds to wait before sending valve open or close command, to avoid sending effectively overlapping commands
	
	// Pressures
	string targetPressureForFlush = IRIS_UTILITY_GetParamValueFromName("Target Pressure for Flush") // torr
	variable pressureTemp
	pressureTemp = str2num(targetPressureForFlush)
	if(pressureTemp > 0.9*pressureSensorLimitForMPC) // includes a safety margin of 10% of the sensor range
		pressureTemp = 0.9*pressureSensorLimitForMPC
		targetPressureForFlush = num2str(pressureTemp)
		IRIS_UTILITY_SetParamValueByName( "Target Pressure for Flush", targetPressureForFlush )
		IRIS_UTILITY_PropagateParamsToTables()
		IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", "*** WARNING: Target pressure reduced to sensor limit! ***")
	endif
	string targetRefPressure = IRIS_UTILITY_GetParamValueFromName("Target Pressure for Reference") // torr
	pressureTemp = str2num(targetRefPressure)
	if(pressureTemp > 0.9*pressureSensorLimitForMPC) // includes safety margin of 1 torr
		pressureTemp = 0.9*pressureSensorLimitForMPC
		targetRefPressure = num2str(pressureTemp)
		IRIS_UTILITY_SetParamValueByName( "Target Pressure for Reference", targetRefPressure )
		IRIS_UTILITY_PropagateParamsToTables()
		IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", "*** WARNING: Target pressure reduced to sensor limit! ***")
	endif
	
	// ECL indices
	string ECL_sampleIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Sample 1")
	string ECL_refIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Reference 1")
	string ECL_transitionIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Transition")
	
	variable i, j
			
	// === MAKE SCHEDULE MODULES TO USE AS BUILDING BLOCKS ===
	
	// USAGE: IRIS_UTILITY_AppendEventToSchedule(sScheduleName, whichTimer, triggerTime, sAction, sArgument, sComment)
	// where sAction is a string that will be appended to "IRIS_EVENT_" to create a reference to a function that takes at most one argument (sArgument), which must be a string
	//	e.g. IRIS_EVENT_SendECL, IRIS_EVENT_ReportStatus, IRIS_EVENT_FetchData, IRIS_EVENT_StartTimer
	
	// Open Sample to TILDAS and Close Sample to Prep System
	IRIS_UTILITY_ClearSchedule("OpenSample")
	IRIS_UTILITY_AppendEventToSchedule("OpenSample", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_samplePrep, "close sample prep valve")
	IRIS_UTILITY_AppendEventToSchedule("OpenSample", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_sampleInject, "open sample inject valve")
	
	// Close Sample to TILDAS and Open Sample to Prep System
	IRIS_UTILITY_ClearSchedule("CloseSample")
	IRIS_UTILITY_AppendEventToSchedule("CloseSample", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_sampleInject, "close sample inject valve")
	IRIS_UTILITY_AppendEventToSchedule("CloseSample", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_samplePrep, "open sample prep valve")
	
	//	// Open Working Reference to TILDAS and Close Working Reference to Prep System
	//	IRIS_UTILITY_ClearSchedule("OpenRef")
	//	IRIS_UTILITY_AppendEventToSchedule("OpenRef", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_refPrep, "close reference prep valve")
	//	IRIS_UTILITY_AppendEventToSchedule("OpenRef", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_refInject, "open reference inject valve")
	//	
	//	// Close Working Reference to TILDAS and Open Working Reference to Prep System
	//	IRIS_UTILITY_ClearSchedule("CloseRef")
	//	IRIS_UTILITY_AppendEventToSchedule("CloseRef", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_refInject, "close reference inject valve")
	//	IRIS_UTILITY_AppendEventToSchedule("CloseRef", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_refPrep, "open reference prep valve")
	
	// Clear Sample Prep Tube and MPC
	IRIS_UTILITY_ClearSchedule("ClearSamplePrepTubeAndMPC")
	IRIS_UTILITY_AppendEventToSchedule("ClearSamplePrepTubeAndMPC", 0, 0, "ReportStatus", "Clearing cell and sample prep tube", "")
	IRIS_UTILITY_AppendScheduleToSchedule("ClearSamplePrepTubeAndMPC", "OpenSample")
	if(numFlushes > 0)
		for(i=0;i<numFlushes;i+=1)
			IRIS_UTILITY_AppendEventToSchedule("ClearSamplePrepTubeAndMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("ClearSamplePrepTubeAndMPC", 0, evacTimeForFlush, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("ClearSamplePrepTubeAndMPC", 0, valveActionTimeSpacer, "SendECL", "aza" + PsensorForMPC + "," + valveNum_nitrogen + "," + targetPressureForFlush, "fill sample tube with nitrogen")
		endfor
	endif
	IRIS_UTILITY_AppendEventToSchedule("ClearSamplePrepTubeAndMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("ClearSamplePrepTubeAndMPC", 0, evacTimeForFinalFill, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
	IRIS_UTILITY_AppendScheduleToSchedule("ClearSamplePrepTubeAndMPC", "CloseSample")
		
	//	// Clear Both Prep Tubes and MPC
	//	IRIS_UTILITY_ClearSchedule("ClearPrepTubesAndMPC")
	//	IRIS_UTILITY_AppendEventToSchedule("ClearPrepTubesAndMPC", 0, 0, "ReportStatus", "Clearing cell and prep tubes", "")
	//	IRIS_UTILITY_AppendScheduleToSchedule("ClearPrepTubesAndMPC", "OpenSample")
	//	IRIS_UTILITY_AppendScheduleToSchedule("ClearPrepTubesAndMPC", "OpenRef")
	//	if(numFlushes > 0)
	//		for(i=0;i<numFlushes;i+=1)
	//			IRIS_UTILITY_AppendEventToSchedule("ClearPrepTubesAndMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
	//			IRIS_UTILITY_AppendEventToSchedule("ClearPrepTubesAndMPC", 0, evacTimeForFlush, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
	//			IRIS_UTILITY_AppendEventToSchedule("ClearPrepTubesAndMPC", 0, valveActionTimeSpacer, "SendECL", "aza" + PsensorForMPC + "," + valveNum_nitrogen + "," + targetPressureForFlush, "fill prep tubes and MPC with nitrogen")
	//		endfor
	//	endif
	//	IRIS_UTILITY_AppendEventToSchedule("ClearPrepTubesAndMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
	//	IRIS_UTILITY_AppendEventToSchedule("ClearPrepTubesAndMPC", 0, evacTimeForFinalFill, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
	//	IRIS_UTILITY_AppendScheduleToSchedule("ClearPrepTubesAndMPC", "CloseSample")
	//	IRIS_UTILITY_AppendScheduleToSchedule("ClearPrepTubesAndMPC", "CloseRef")
		
	// Clear MPC only
	IRIS_UTILITY_ClearSchedule("ClearMPC")
	IRIS_UTILITY_AppendEventToSchedule("ClearMPC", 0, 0, "ReportStatus", "Clearing absorption cell", "")
	if(numFlushes > 0)
		for(i=0;i<numFlushes;i+=1)
			IRIS_UTILITY_AppendEventToSchedule("ClearMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("ClearMPC", 0, evacTimeForFlush, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("ClearMPC", 0, valveActionTimeSpacer, "SendECL", "aza" + PsensorForMPC + "," + valveNum_nitrogen + "," + targetPressureForFlush, "fill MPC with nitrogen")
		endfor
	endif
	IRIS_UTILITY_AppendEventToSchedule("ClearMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("ClearMPC", 0, evacTimeForFinalFill, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
	
	// Measure and Subtract Background Spectrum
	IRIS_UTILITY_ClearSchedule("SubtractBackground")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ReportStatus", "Measuring spectral background", "")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "aza" + PsensorForMPC + "," + valveNum_nitrogen + "," + targetPressureForFlush, "fill MPC with nitrogen")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 1, "SendECL", "amabg1", "enable ABG")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "aq", "do a BG measurement")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, backgroundDuration, "", "", "wait for ABG to complete")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ResetABGtimer", "", "reset ABG timer")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ReportStatus", "Done measuring spectral background", "")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ReportStatus", "Evacuating absorption cell", "")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, evacTimeForFinalFill, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
	
	// Fill MPC from Sample Tube
	IRIS_UTILITY_ClearSchedule("FillMPCfromSampleTube")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCfromSampleTube", 0, 0, "ReportStatus", "Filling cell from sample tube", "")
	IRIS_UTILITY_AppendScheduleToSchedule("FillMPCfromSampleTube", "OpenSample")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCfromSampleTube", 0, MPCfillTimeFromPrepTube, "", "", "wait for MPC to fill")
	IRIS_UTILITY_AppendScheduleToSchedule("FillMPCfromSampleTube", "CloseSample")
	
	// Fill MPC from Reference Tube
	//	IRIS_UTILITY_ClearSchedule("FillMPCfromRefTube")
	//	IRIS_UTILITY_AppendEventToSchedule("FillMPCfromRefTube", 0, 0, "ReportStatus", "Filling absorption cell from ref tube", "")
	//	IRIS_UTILITY_AppendScheduleToSchedule("FillMPCfromRefTube", "OpenRef")
	//	IRIS_UTILITY_AppendEventToSchedule("FillMPCfromRefTube", 0, MPCfillTimeFromPrepTube, "", "", "wait for MPC to fill")
	//	IRIS_UTILITY_AppendScheduleToSchedule("FillMPCfromRefTube", "CloseRef")
	IRIS_UTILITY_ClearSchedule("FillMPCwithRef")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithRef", 0, 0, "ReportStatus", "Filling cell from ref tube", "")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithRef", 0, valveActionTimeSpacer, "SendECL", "aza" + PsensorForMPC + "," + valveNum_refInject + "," + targetRefPressure, "fill MPC with working reference")
	
	// Start transition period
	IRIS_UTILITY_ClearSchedule("StartTransition")
	IRIS_UTILITY_AppendEventToSchedule("StartTransition", 0, 0, "SendECL", "bz" + ECL_transitionIndex, "set ECL index to transition")
	IRIS_UTILITY_AppendEventToSchedule("StartTransition", 0, 0, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule("StartTransition", 0, 0, "SendECL", "bdfits1", "suspend spectral fits")
	
	// Start reference measurement
	IRIS_UTILITY_ClearSchedule("StartRefMeas")
	IRIS_UTILITY_AppendEventToSchedule("StartRefMeas", 0, 0, "SendECL", "bdfits0", "activate spectral fits")
	IRIS_UTILITY_AppendEventToSchedule("StartRefMeas", 0, 0, "SendECL", "bz" + ECL_refIndex, "set ECL index to working reference")
	IRIS_UTILITY_AppendEventToSchedule("StartRefMeas", 0, 0, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule("StartRefMeas", 0, 0, "ReportStatus", "Starting reference measurement", "")
	
	// Start sample measurement
	IRIS_UTILITY_ClearSchedule("StartSampleMeas")
	IRIS_UTILITY_AppendEventToSchedule("StartSampleMeas", 0, 0, "SendECL", "bdfits0", "activate spectral fits")
	IRIS_UTILITY_AppendEventToSchedule("StartSampleMeas", 0, 0, "SendECL", "bz" + ECL_sampleIndex, "set ECL index to sample")
	IRIS_UTILITY_AppendEventToSchedule("StartSampleMeas", 0, 0, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule("StartSampleMeas", 0, 0, "ReportStatus", "Starting sample measurement", "")
	
	// Redo ABG measurement
	IRIS_UTILITY_ClearSchedule("RedoABG")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "ClearMPC") // Clear MPC
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "SubtractBackground") // Record and subtract background spectrum
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FillMPCwithRef") // Fill MPC with working reference
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "StartRefMeas") // Start measuring reference
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 0, 0, "StartTimer", "1", "start timer for reference measurement") // start timer 1
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 1, measurementDuration, "", "", "wait for reference measurement to complete") // Wait for reference measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 0, 0, "ReportStatus", "Reference measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "StartTransition")
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 0, 1, "ResumeCycleSchedule", "", "resume Cycle schedule") // Return to the usual Cycle schedule	
	
	// === BUILD THE RESET SCHEDULE ===
	// 1. A schedule called "Reset", which clears the ECL queue, closes the valves, and starts a new STR/STC file (this will be directly invoked when the "STOP" button is clicked and is also a convenient building block for the Prologue and Epilogue);
	
	// Reset sampling system
	IRIS_UTILITY_ClearSchedule("Reset")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 0, "ReportStatus", "Resetting sampling system", "")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 0, "SendECL", "cq", "immediately clear the ECL queue (this command jumps to the front of the queue)")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 3, "SendECL", "bz" + ECL_transitionIndex, "set ECL index to transition")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "amabg0", "disable ABG")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "bdfits0", "activate spectral fits")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_nitrogen, "close nitrogen valve")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_sampleInject, "close sample inject valve")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_refInject, "close ref inject valve")
	if(clearPrepTubesAtStart == 1)
		IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_samplePrep, "close sample prep valve")
	else 
		IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_samplePrep, "open sample prep valve")
	endif
	//	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_refPrep, "open ref prep valve")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "amwd0", "deactivate write disk") // these two lines ensure file is complete for final data fetch and are otherwise harmless
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "amass0", "deactivate auto spectral save") // these two lines ensure file is complete for final data fetch and are otherwise harmless
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 1, "FetchData", "", "fetch latest data")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 1, "SendECL", "amwd1", "activate write disk")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "amass1", "activate auto spectral save")
	
	// === BUILD THE PROLOGUE SCHEDULE ===
	// 2. A schedule called "Prologue", which consists of the things that happen only at the beginning of the run;
	
	IRIS_UTILITY_ClearSchedule("Prologue")
	
	// Reset sampling system
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "Reset")
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "StartTransition")
	
	// Clear MPC and possibly prep tubes
	if(clearPrepTubesAtStart == 1)
		IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "ClearSamplePrepTubeAndMPC")
	else
		IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "ClearMPC")
	endif
	
	// Record and subtract background spectrum
	if(doABG == 1)
		IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "SubtractBackground")
	endif
	
	// Wait while prep tubes are filled if prep tubes were cleared at start
	if(clearPrepTubesAtStart == 1)
		IRIS_UTILITY_AppendEventToSchedule("Prologue", 0, prepTime, "", "", "wait for prep of sample and ref") // wait until timer 1 reaches measurementDuration
	endif
	
	// Fill MPC with working reference
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "FillMPCwithRef")
	
	// Start measuring reference
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "StartRefMeas")
	IRIS_UTILITY_AppendEventToSchedule("Prologue", 0, 0, "StartTimer", "1", "start timer for reference measurement") // start timer 1
	
	// Wait for reference measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("Prologue", 1, measurementDuration, "", "", "wait for reference measurement to complete") // wait until timer 1 reaches measurementDuration
	IRIS_UTILITY_AppendEventToSchedule("Prologue", 0, 0, "ReportStatus", "Reference measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "StartTransition")
	
	// === BUILD THE CYCLE SCHEDULE ===
	// 3. A schedule called "Cycle", which consists of the things that happen repetitively;
	
	IRIS_UTILITY_ClearSchedule("Cycle")
	
	// Clear MPC and then fill it with sample
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "ClearMPC")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillMPCfromSampleTube")
	
	// Start measuring sample
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartSampleMeas")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "StartTimer", "1", "start timer for sample measurement") // start timer 1
	
	// Fetch latest data (while sample is being measured in MPC)
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 1, "FetchData", "", "fetch latest data")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "ReportStatus", "Fetching data", "")
	
	// Wait for sample measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 1, measurementDuration, "", "", "wait for sample measurement to complete") // wait until timer 1 reaches measurementDuration
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "ReportStatus", "Sample measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartTransition")
	
	// Clear MPC and then fill it with working reference
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "ClearMPC")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillMPCwithRef")
	
	// Start measuring reference
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartRefMeas")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "StartTimer", "1", "start timer for reference measurement") // start timer 1
	
	// Wait for reference measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 1, measurementDuration, "", "", "wait for reference measurement to complete") // wait until timer 1 reaches measurementDuration
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "ReportStatus", "Reference measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartTransition")
	
	// Check ABG interval and redo ABG if appropriate (only include this as the very last instruction in a cycle, and make sure you have defined a schedule called "RedoABG" above!)
	if((doABG == 1) && (ABGinterval > 0))
		IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 1, "CheckABGinterval", "", "check whether it is time to redo the background")
	endif
	
	// === BUILD THE EPILOGUE SCHEDULE ===
	// 4. A schedule called "Epilogue", which consists of the things that happen only at the end of the run, after the last cycle.
	
	IRIS_UTILITY_ClearSchedule("Epilogue")
	
	// Reset sampling system
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "Reset")
	
	DoUpdate
	
End

Function IRIS_SCHEME_BuildSchedule_D17O_d13C_CO2()
	
	// NOTE: "UNIVERSAL" sections must be included exactly as they are, exactly where they are.
	
	// === UNIVERSAL: DECLARATIONS (do not modify) ===
	
	NVAR minNumSamples = root:minNumSamples
	NVAR maxNumSamples = root:maxNumSamples
	NVAR minNumRefs = root:minNumRefs
	NVAR maxNumRefs = root:maxNumRefs
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	NVAR numGases = root:numGases
	
	SetDataFolder root:
	
	// === DEFINE MAXIMUM AND MINIMUM ALLOWED NUMBERS OF SAMPLE AND REFERENCE GASES BASED ON HARDWARE ===
	
	minNumSamples = 1
	maxNumSamples = 1
	minNumRefs = 1
	maxNumRefs = 1
	
	// === GET VARIABLES FROM CONFIG PARAMS ===
	
	// Hardware setup
	string valveNum_sample1 = IRIS_UTILITY_GetParamValueFromName("Valve Number for Sample Orifice")
	string valveNum_ref1 = IRIS_UTILITY_GetParamValueFromName("Valve Number for Reference Orifice")
	string valveNum_refTank = IRIS_UTILITY_GetParamValueFromName("Valve Number for Reference Tank")
	string valveNum_cell = IRIS_UTILITY_GetParamValueFromName("Valve Number for MPC")
	string valveNum_intermediateVolume = IRIS_UTILITY_GetParamValueFromName("Valve Number for V2")
	string valveNum_mainVac = IRIS_UTILITY_GetParamValueFromName("Valve Number for Vacuum")
	string valveNum_secondVacuum = IRIS_UTILITY_GetParamValueFromName("Valve Number for Second Vacuum")
	string valveNum_orificeFlush = IRIS_UTILITY_GetParamValueFromName("Valve Number for Fast Cell Flush")
	string valveNum_fastFlush = IRIS_UTILITY_GetParamValueFromName("Valve Number for Ref. Orifice Flush")
	string PsensorForMPC = IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Number for MPC")
	string PsensorForV2 = IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Number for V2")
	variable system_to_V2_volume_ratio = str2num(IRIS_UTILITY_GetParamValueFromName("Ratio of Total System Volume to V2"))
	
	// Pressure sensor limits
	variable pressureSensorLimitForV2 = str2num(IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Limit for V2")) // torr, used to prevent the user from selecting target pressures that can never be measured, which would lead to runaway aza (up to its internal time limit)
	variable pressureSensorLimitForMPC = str2num(IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Limit for MPC")) // torr, used to prevent the user from selecting target pressures that can never be measured, which would lead to runaway aza (up to its internal time limit)
	
	// Timing, repetitions, and ABG
	variable doABG = (stringMatch( IRIS_UTILITY_GetParamValueFromName("Subtract Background Spectrum"), "y*" ) == 1) ? 1 : 0 // 0 = no, 1 = yes
	variable ABGinterval = 60*str2num(IRIS_UTILITY_GetParamValueFromName("Background Measurement Interval")) // seconds
	variable backgroundDuration = str2num(IRIS_UTILITY_GetParamValueFromName("Background Measurement Duration")) // seconds
	backgroundDuration += 5 // 5 second safety margin
	variable numV2flushes = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Flushes of V2")) // number of intermediate volume flushes with nitrogen
	variable numMPCflushes = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Flushes of MPC")) // number of multipass cell flushes with nitrogen
	variable measurementDuration = str2num(IRIS_UTILITY_GetParamValueFromName("Measurement Duration")) // seconds
	variable V2evacTimeForFlush = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Flush of V2")) // seconds
	variable V2evacTimeForFinalFill = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Final Fill of V2")) // seconds
	variable MPCevacTimeForFlush = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Flush of MPC")) // seconds
	variable MPCevacTimeForFinalFill = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Final Fill of MPC")) // seconds
	variable MPCevacTimeForABG = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Background")) // seconds
	variable MPCfillTimeFromV2 = str2num(IRIS_UTILITY_GetParamValueFromName("Time to Wait for Fill of MPC from V2")) // seconds
	variable valveActionTimeSpacer = str2num(IRIS_UTILITY_GetParamValueFromName("Valve Action Time Spacer")) // number of seconds to wait before sending valve open or close command, to avoid sending effectively overlapping commands
	
	// Pressures
	variable target_MPC_pressure = str2num(IRIS_UTILITY_GetParamValueFromName("Target MPC Pressure")) // torr
	variable pressureTemp
	pressureTemp = target_MPC_pressure
	if(pressureTemp > 0.9*pressureSensorLimitForMPC) // includes a safety margin of 10% of the sensor range
		pressureTemp = 0.9*pressureSensorLimitForMPC
		target_MPC_pressure = pressureTemp
		IRIS_UTILITY_SetParamValueByName( "Target MPC Pressure", num2str(target_MPC_pressure) )
		IRIS_UTILITY_PropagateParamsToTables()
		IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", "*** WARNING: Target pressure reduced to sensor limit! ***")
	endif
	string V2targetPressureForFlush = IRIS_UTILITY_GetParamValueFromName("Target Pressure for Flush of V2") // torr
	pressureTemp = str2num(V2targetPressureForFlush)
	if(pressureTemp > 0.9*pressureSensorLimitForV2) // includes a safety margin of 10% of the sensor range
		pressureTemp = 0.9*pressureSensorLimitForV2
		V2targetPressureForFlush = num2str(pressureTemp)
		IRIS_UTILITY_SetParamValueByName( "Target Pressure for Flush of V2", V2targetPressureForFlush )
		IRIS_UTILITY_PropagateParamsToTables()
		IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", "*** WARNING: Target pressure reduced to sensor limit! ***")
	endif
	string MPCtargetPressureForFlush = IRIS_UTILITY_GetParamValueFromName("Target Pressure for Flush of MPC") // torr
	pressureTemp = str2num(MPCtargetPressureForFlush)
	if(pressureTemp > 0.9*pressureSensorLimitForMPC) // includes a safety margin of 10% of the sensor range
		pressureTemp = 0.9*pressureSensorLimitForMPC
		MPCtargetPressureForFlush = num2str(pressureTemp)
		IRIS_UTILITY_SetParamValueByName( "Target Pressure for Flush of MPC", MPCtargetPressureForFlush )
		IRIS_UTILITY_PropagateParamsToTables()
		IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", "*** WARNING: Target pressure reduced to sensor limit! ***")
	endif
	string V2targetPressureForFinalFill = num2istr(target_MPC_pressure*system_to_V2_volume_ratio) // torr
	
	// ECL indices
	string ECL_sampleIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Sample 1")
	string ECL_refIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Reference 1")
	string ECL_transitionIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Transition")
	
	variable i, j
	
	// === MAKE SCHEDULE MODULES TO USE AS BUILDING BLOCKS ===
	
	// USAGE: IRIS_UTILITY_AppendEventToSchedule(sScheduleName, whichTimer, triggerTime, sAction, sArgument, sComment)
	// where sAction is a string that will be appended to "IRIS_EVENT_" to create a reference to a function that takes at most one argument (sArgument), which must be a string
	//	e.g. IRIS_EVENT_SendECL, IRIS_EVENT_ReportStatus, IRIS_EVENT_FetchData, IRIS_EVENT_StartTimer
			
	// Flush V2 via ref. orifice flush valve
	IRIS_UTILITY_ClearSchedule("FlushV2")
	if(numV2flushes > 0)
		IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_intermediateVolume, "open intermediate volume valve")
		for(i=0;i<numV2flushes;i+=1)
			IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, 0, "ReportStatus", "Evacuating intermediate volume", "")
			IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_secondVacuum, "open second vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, V2evacTimeForFlush, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_secondVacuum, "close second vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, 0, "ReportStatus", "Filling int. volume with flush gas", "")
			IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, valveActionTimeSpacer, "SendECL", "aza" + PsensorForV2 + "," + valveNum_orificeFlush + "," + V2targetPressureForFlush, "fill intermediate volume with nitrogen")
		endfor
		IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_intermediateVolume, "close intermediate volume valve")
	endif
	
	// Flush MPC via fast flush valve (to not disturb V2)
	IRIS_UTILITY_ClearSchedule("FlushMPC")
	if(numMPCflushes > 0)
		IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_cell, "open MPC valve")
		for(i=0;i<numMPCflushes;i+=1)
			IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, 0, "ReportStatus", "Evacuating absorption cell", "")
			IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, MPCevacTimeForFlush, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, 0, "ReportStatus", "Filling cell with flush gas", "")
			IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, valveActionTimeSpacer, "SendECL", "aza" + PsensorForMPC + "," + valveNum_fastFlush + "," + MPCtargetPressureForFlush, "fill MPC with nitrogen")
		endfor
		IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_cell, "close MPC valve")
	endif
	
	// Measure and Subtract Background Spectrum
	IRIS_UTILITY_ClearSchedule("SubtractBackground")
	IRIS_UTILITY_AppendScheduleToSchedule("SubtractBackground", "FlushMPC")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_cell, "open MPC valve")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ReportStatus", "Evacuating absorption cell", "")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, MPCevacTimeForABG, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_cell, "close MPC valve")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 1, "SendECL", "amabg1", "enable ABG")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ReportStatus", "Measuring spectral background", "")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "aq", "do a BG measurement")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, backgroundDuration, "", "", "wait for ABG to complete")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ResetABGtimer", "", "reset ABG timer")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ReportStatus", "Done measuring spectral background", "")
	
	// Fill V2 with Reference
	IRIS_UTILITY_ClearSchedule("FillV2withRef")
	if(V2evacTimeForFinalFill > 0)
		IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, 0, "ReportStatus", "Evacuating intermediate volume", "")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_intermediateVolume, "open intermediate volume valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_secondVacuum, "open second vacuum valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, V2evacTimeForFinalFill, "SendECL", "anc" + valveNum_intermediateVolume, "close intermediate volume valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_secondVacuum, "close second vacuum valve")
	endif
	IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, 0, "ReportStatus", "Filling int. volume with reference", "")
	IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_refTank, "open reference tank valve")
	IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, valveActionTimeSpacer, "SendECL", "aza" + PsensorForV2 + "," + valveNum_ref1 + "," + V2targetPressureForFinalFill, "fill intermediate volume with working reference")
	IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_refTank, "close reference tank valve")
	
	// Fill V2 with Sample
	IRIS_UTILITY_ClearSchedule("FillV2withSample")
	if(V2evacTimeForFinalFill > 0)
		IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, 0, "ReportStatus", "Evacuating intermediate volume", "")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_intermediateVolume, "open intermediate volume valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, V2evacTimeForFinalFill, "SendECL", "anc" + valveNum_intermediateVolume, "close intermediate volume valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
	endif
	IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, 0, "ReportStatus", "Filling int. volume with sample", "")
	IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, valveActionTimeSpacer, "SendECL", "aza" + PsensorForV2 + "," + valveNum_sample1 + "," + V2targetPressureForFinalFill, "fill intermediate volume with sample")
	
	// Fill MPC from V2
	IRIS_UTILITY_ClearSchedule("FillMPC")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, 0, "ReportStatus", "Evacuating absorption cell", "")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_cell, "open MPC valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, MPCevacTimeForFinalFill, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, 0, "ReportStatus", "Filling cell from intermediate volume", "")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_intermediateVolume, "open intermediate volume valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, MPCfillTimeFromV2, "SendECL", "anc" + valveNum_cell, "close MPC valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_intermediateVolume, "close intermediate volume valve")
	
	// Start transition period
	IRIS_UTILITY_ClearSchedule("StartTransition")
	IRIS_UTILITY_AppendEventToSchedule("StartTransition", 0, 0, "SendECL", "bz" + ECL_transitionIndex, "set ECL index to transition")
	IRIS_UTILITY_AppendEventToSchedule("StartTransition", 0, 0, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule("StartTransition", 0, 0, "SendECL", "bdfits1", "suspend spectral fits")
	
	// Start reference measurement
	IRIS_UTILITY_ClearSchedule("StartRefMeas")
	IRIS_UTILITY_AppendEventToSchedule("StartRefMeas", 0, 0, "SendECL", "bdfits0", "activate spectral fits")
	IRIS_UTILITY_AppendEventToSchedule("StartRefMeas", 0, 0, "SendECL", "bz" + ECL_refIndex, "set ECL index to working reference")
	IRIS_UTILITY_AppendEventToSchedule("StartRefMeas", 0, 0, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule("StartRefMeas", 0, 0, "ReportStatus", "Starting reference measurement", "")
	
	// Start sample measurement
	IRIS_UTILITY_ClearSchedule("StartSampleMeas")
	IRIS_UTILITY_AppendEventToSchedule("StartSampleMeas", 0, 0, "SendECL", "bdfits0", "activate spectral fits")
	IRIS_UTILITY_AppendEventToSchedule("StartSampleMeas", 0, 0, "SendECL", "bz" + ECL_sampleIndex, "set ECL index to sample")
	IRIS_UTILITY_AppendEventToSchedule("StartSampleMeas", 0, 0, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule("StartSampleMeas", 0, 0, "ReportStatus", "Starting sample measurement", "")
	
	// Redo ABG measurement
	IRIS_UTILITY_ClearSchedule("RedoABG")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FlushMPC") // Flush MPC and then fill it with working reference from V2
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FillMPC")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "StartRefMeas") // Start measuring reference
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 0, 0, "StartTimer", "1", "start timer for reference measurement") // start timer 1
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FlushV2") // Flush V2 and then fill it with working reference (while previous ref is being measured in MPC)
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FillV2withRef")
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 1, measurementDuration, "", "", "wait for reference measurement to complete") // Wait for reference measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 0, 0, "ReportStatus", "Reference measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "StartTransition")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "SubtractBackground") // Flush MPC and record background spectrum
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 0, 1, "ResumeCycleSchedule", "", "resume Cycle schedule") // Return to the usual Cycle schedule	
	
	// === BUILD THE RESET SCHEDULE ===
	// 1. A schedule called "Reset", which clears the ECL queue, closes the valves, and starts a new STR/STC file (this will be directly invoked when the "STOP" button is clicked and is also a convenient building block for the Prologue and Epilogue);
	
	// Reset sampling system
	IRIS_UTILITY_ClearSchedule("Reset")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 0, "ReportStatus", "Resetting sampling system", "")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 0, "SendECL", "cq", "immediately clear the ECL queue (this command jumps to the front of the queue)")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 3, "SendECL", "bz" + ECL_transitionIndex, "set ECL index to transition")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "amabg0", "disable ABG")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "bdfits0", "activate spectral fits")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc0", "close valve 0")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc1", "close valve 1")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc8", "close valve 8")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc10", "close valve 10")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc11", "close valve 11")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc13", "close valve 13")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc14", "close valve 14")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "amwd0", "deactivate write disk")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "amass0", "deactivate auto spectral save")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 1, "FetchData", "", "fetch latest data")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 1, "SendECL", "amwd1", "activate write disk")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "amass1", "activate auto spectral save")
	
	// === BUILD THE PROLOGUE SCHEDULE ===
	// 2. A schedule called "Prologue", which consists of the things that happen only at the beginning of the run;
	
	IRIS_UTILITY_ClearSchedule("Prologue")
	
	// Reset sampling system
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "Reset")
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "StartTransition")
	
	// Flush MPC and record background spectrum
	if(doABG == 1)
		IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "SubtractBackground")
	endif
	
	// Flush V2 and then fill it with working reference
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "FlushV2")
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "FillV2withRef")
	
	// === BUILD THE CYCLE SCHEDULE ===
	// 3. A schedule called "Cycle", which consists of the things that happen repetitively;
	
	IRIS_UTILITY_ClearSchedule("Cycle")
	
	// Flush MPC and then fill it with working reference from V2
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FlushMPC")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillMPC")
	
	// Start measuring reference
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartRefMeas")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "StartTimer", "1", "start timer for reference measurement") // start timer 1
	
	// Flush V2 and then fill it with sample (while working reference is being measured in MPC)
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FlushV2")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillV2withSample")
	
	// Wait for reference measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 1, measurementDuration, "", "", "wait for reference measurement to complete") // wait until timer 1 reaches measurementDuration
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "ReportStatus", "Reference measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartTransition")
	
	// Flush MPC and then fill it with sample from V2
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FlushMPC")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillMPC")
	
	// Start measuring sample
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartSampleMeas")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "StartTimer", "1", "start timer for sample measurement") // start timer 1
	
	// Flush V2 and then fill it with working reference (while sample is being measured in MPC)
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FlushV2")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillV2withRef")
	
	// Fetch latest data (while sample is being measured in MPC)
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "ReportStatus", "Fetching and analyzing data", "")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 1, "FetchData", "", "fetch latest data")
	
	// Wait for sample measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 1, measurementDuration, "", "", "wait for sample measurement to complete") // wait until timer 1 reaches measurementDuration
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "ReportStatus", "Sample measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartTransition")
	
	// Check ABG interval and redo ABG if appropriate (only include this as the very last instruction in a cycle, and make sure you have defined a schedule called "RedoABG" above!)
	if((doABG == 1) && (ABGinterval > 0))
		IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 1, "CheckABGinterval", "", "check whether it is time to redo the background")
	endif
	
	// === BUILD THE EPILOGUE SCHEDULE ===
	// 4. A schedule called "Epilogue", which consists of the things that happen only at the end of the run, after the last cycle.
	
	IRIS_UTILITY_ClearSchedule("Epilogue")
	
	// Flush MPC and then fill it with working reference from V2
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "FlushMPC")
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "FillMPC")
	
	// Start measuring reference
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "StartRefMeas")
	IRIS_UTILITY_AppendEventToSchedule("Epilogue", 0, 0, "StartTimer", "1", "start timer for reference measurement") // start timer 1
	
	// Wait for reference measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("Epilogue", 1, measurementDuration, "", "", "wait for reference measurement to complete") // wait until timer 1 reaches measurementDuration
	IRIS_UTILITY_AppendEventToSchedule("Epilogue", 0, 0, "ReportStatus", "Reference measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "StartTransition")
	
	// Reset sampling system
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "Reset")
	
	DoUpdate
	
End

Function IRIS_SCHEME_BuildSchedule_D17O_d13C_CO2_CapeTown()
	
	// NOTE: "UNIVERSAL" sections must be included exactly as they are, exactly where they are.
	
	// === UNIVERSAL: DECLARATIONS (do not modify) ===
	
	NVAR minNumSamples = root:minNumSamples
	NVAR maxNumSamples = root:maxNumSamples
	NVAR minNumRefs = root:minNumRefs
	NVAR maxNumRefs = root:maxNumRefs
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	NVAR numGases = root:numGases
	
	SetDataFolder root:
	
	// === DEFINE MAXIMUM AND MINIMUM ALLOWED NUMBERS OF SAMPLE AND REFERENCE GASES BASED ON HARDWARE ===
	
	minNumSamples = 1
	maxNumSamples = 1
	minNumRefs = 1
	maxNumRefs = 1
	
	// === GET VARIABLES FROM CONFIG PARAMS ===
	
	// Hardware setup
	string valveNum_sample1 = IRIS_UTILITY_GetParamValueFromName("Valve Number for Sample Orifice")
	string valveNum_ref1 = IRIS_UTILITY_GetParamValueFromName("Valve Number for Reference Orifice")
	string valveNum_refTank = IRIS_UTILITY_GetParamValueFromName("Valve Number for Reference Tank")
	string valveNum_intermediateVolume = IRIS_UTILITY_GetParamValueFromName("Valve Number for V2")
	string valveNum_flush = IRIS_UTILITY_GetParamValueFromName("Valve Number for Flush")
	string valveNum_mainVac = IRIS_UTILITY_GetParamValueFromName("Valve Number for Vacuum")
	string valveNum_secondVacuum = IRIS_UTILITY_GetParamValueFromName("Valve Number for Second Vacuum")
	string valveNum_cell = IRIS_UTILITY_GetParamValueFromName("Valve Number for MPC")
	string PsensorForMPC = IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Number for MPC")
	string PsensorForV2 = IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Number for V2")
	variable system_to_V2_volume_ratio = str2num(IRIS_UTILITY_GetParamValueFromName("Ratio of Total System Volume to V2"))
	
	// Pressure sensor limits
	variable pressureSensorLimitForV2 = str2num(IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Limit for V2")) // torr, used to prevent the user from selecting target pressures that can never be measured, which would lead to runaway aza (up to its internal time limit)
	variable pressureSensorLimitForMPC = str2num(IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Limit for MPC")) // torr, used to prevent the user from selecting target pressures that can never be measured, which would lead to runaway aza (up to its internal time limit)
	
	// Timing, repetitions, and ABG
	variable doABG = (stringMatch( IRIS_UTILITY_GetParamValueFromName("Subtract Background Spectrum"), "y*" ) == 1) ? 1 : 0 // 0 = no, 1 = yes
	variable ABGinterval = 60*str2num(IRIS_UTILITY_GetParamValueFromName("Background Measurement Interval")) // seconds
	variable backgroundDuration = str2num(IRIS_UTILITY_GetParamValueFromName("Background Measurement Duration")) // seconds
	backgroundDuration += 5 // 5 second safety margin
	variable numV2flushes = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Flushes of V2")) // number of intermediate volume flushes with nitrogen
	variable numMPCflushes = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Flushes of MPC")) // number of multipass cell flushes with nitrogen
	variable measurementDuration = str2num(IRIS_UTILITY_GetParamValueFromName("Measurement Duration")) // seconds
	variable V2evacTimeForFlush = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Flush of V2")) // seconds
	variable V2evacTimeForFinalFill = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Final Fill of V2")) // seconds
	variable MPCevacTimeForFlush = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Flush of MPC")) // seconds
	variable MPCevacTimeForFinalFill = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Final Fill of MPC")) // seconds
	variable MPCevacTimeForABG = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Background")) // seconds
	variable MPCfillTimeFromV2 = str2num(IRIS_UTILITY_GetParamValueFromName("Time to Wait for Fill of MPC from V2")) // seconds
	variable valveActionTimeSpacer = str2num(IRIS_UTILITY_GetParamValueFromName("Valve Action Time Spacer")) // number of seconds to wait before sending valve open or close command, to avoid sending effectively overlapping commands
	
	// Pressures
	variable target_MPC_pressure = str2num(IRIS_UTILITY_GetParamValueFromName("Target MPC Pressure")) // torr
	variable pressureTemp
	pressureTemp = target_MPC_pressure
	if(pressureTemp > 0.9*pressureSensorLimitForMPC) // includes a safety margin of 10% of the sensor range
		pressureTemp = 0.9*pressureSensorLimitForMPC
		target_MPC_pressure = pressureTemp
		IRIS_UTILITY_SetParamValueByName( "Target MPC Pressure", num2str(target_MPC_pressure) )
		IRIS_UTILITY_PropagateParamsToTables()
		IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", "*** WARNING: Target pressure reduced to sensor limit! ***")
	endif
	string V2targetPressureForFlush = IRIS_UTILITY_GetParamValueFromName("Target Pressure for Flush of V2") // torr
	pressureTemp = str2num(V2targetPressureForFlush)
	if(pressureTemp > 0.9*pressureSensorLimitForV2) // includes a safety margin of 10% of the sensor range
		pressureTemp = 0.9*pressureSensorLimitForV2
		V2targetPressureForFlush = num2str(pressureTemp)
		IRIS_UTILITY_SetParamValueByName( "Target Pressure for Flush of V2", V2targetPressureForFlush )
		IRIS_UTILITY_PropagateParamsToTables()
		IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", "*** WARNING: Target pressure reduced to sensor limit! ***")
	endif
	string MPCtargetPressureForFlush = IRIS_UTILITY_GetParamValueFromName("Target Pressure for Flush of MPC") // torr
	pressureTemp = str2num(MPCtargetPressureForFlush)
	if(pressureTemp > 0.9*pressureSensorLimitForMPC) // includes a safety margin of 10% of the sensor range
		pressureTemp = 0.9*pressureSensorLimitForMPC
		MPCtargetPressureForFlush = num2str(pressureTemp)
		IRIS_UTILITY_SetParamValueByName( "Target Pressure for Flush of MPC", MPCtargetPressureForFlush )
		IRIS_UTILITY_PropagateParamsToTables()
		IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", "*** WARNING: Target pressure reduced to sensor limit! ***")
	endif
	string V2targetPressureForFinalFill = num2istr(target_MPC_pressure*system_to_V2_volume_ratio) // torr
	
	// ECL indices
	string ECL_sampleIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Sample 1")
	string ECL_refIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Reference 1")
	string ECL_transitionIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Transition")
	
	variable i, j
	
	// === MAKE SCHEDULE MODULES TO USE AS BUILDING BLOCKS ===
	
	// USAGE: IRIS_UTILITY_AppendEventToSchedule(sScheduleName, whichTimer, triggerTime, sAction, sArgument, sComment)
	// where sAction is a string that will be appended to "IRIS_EVENT_" to create a reference to a function that takes at most one argument (sArgument), which must be a string
	//	e.g. IRIS_EVENT_SendECL, IRIS_EVENT_ReportStatus, IRIS_EVENT_FetchData, IRIS_EVENT_StartTimer
			
	// Flush V2
	IRIS_UTILITY_ClearSchedule("FlushV2")
	if(numV2flushes > 0)
		IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_intermediateVolume, "open intermediate volume valve")
		for(i=0;i<numV2flushes;i+=1)
			IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, 0, "ReportStatus", "Evacuating intermediate volume", "")
			IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_secondVacuum, "open second vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, V2evacTimeForFlush, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_secondVacuum, "close second vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, 0, "ReportStatus", "Filling int. volume with flush gas", "")
			IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, valveActionTimeSpacer, "SendECL", "aza" + PsensorForV2 + "," + valveNum_flush + "," + V2targetPressureForFlush, "fill intermediate volume with nitrogen")
		endfor
		IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_intermediateVolume, "close intermediate volume valve")
	endif
	
	// Flush MPC
	IRIS_UTILITY_ClearSchedule("FlushMPC")
	if(numMPCflushes > 0)
		IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_cell, "open MPC valve")
		for(i=0;i<numMPCflushes;i+=1)
			IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, 0, "ReportStatus", "Evacuating absorption cell", "")
			IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_secondVacuum, "open second vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, MPCevacTimeForFlush, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_secondVacuum, "close second vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, 0, "ReportStatus", "Filling cell with flush gas", "")
			IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, valveActionTimeSpacer, "SendECL", "aza" + PsensorForMPC + "," + valveNum_flush + "," + MPCtargetPressureForFlush, "fill MPC with nitrogen")
		endfor
		IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_cell, "close MPC valve")
	endif
	
	// Measure and Subtract Background Spectrum
	IRIS_UTILITY_ClearSchedule("SubtractBackground")
	IRIS_UTILITY_AppendScheduleToSchedule("SubtractBackground", "FlushMPC")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_cell, "open MPC valve")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ReportStatus", "Evacuating absorption cell", "")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, MPCevacTimeForABG, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_cell, "close MPC valve")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 1, "SendECL", "amabg1", "enable ABG")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ReportStatus", "Measuring spectral background", "")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "aq", "do a BG measurement")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, backgroundDuration, "", "", "wait for ABG to complete")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ResetABGtimer", "", "reset ABG timer")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ReportStatus", "Done measuring spectral background", "")
	
	// Fill V2 with Reference
	IRIS_UTILITY_ClearSchedule("FillV2withRef")
	if(V2evacTimeForFinalFill > 0)
		IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, 0, "ReportStatus", "Evacuating intermediate volume", "")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_intermediateVolume, "open intermediate volume valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_secondVacuum, "open second vacuum valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, V2evacTimeForFinalFill, "SendECL", "anc" + valveNum_intermediateVolume, "close intermediate volume valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_secondVacuum, "close second vacuum valve")
	endif
	IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, 0, "ReportStatus", "Filling int. volume with reference", "")
	IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_refTank, "open reference tank valve")
	IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, valveActionTimeSpacer, "SendECL", "aza" + PsensorForV2 + "," + valveNum_ref1 + "," + V2targetPressureForFinalFill, "fill intermediate volume with working reference")
	IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_refTank, "close reference tank valve")
	
	// Fill V2 with Sample
	IRIS_UTILITY_ClearSchedule("FillV2withSample")
	if(V2evacTimeForFinalFill > 0)
		IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, 0, "ReportStatus", "Evacuating intermediate volume", "")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_intermediateVolume, "open intermediate volume valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_secondVacuum, "open second vacuum valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, V2evacTimeForFinalFill, "SendECL", "anc" + valveNum_intermediateVolume, "close intermediate volume valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_secondVacuum, "close second vacuum valve")
	endif
	IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, 0, "ReportStatus", "Filling int. volume with sample", "")
	IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, valveActionTimeSpacer, "SendECL", "aza" + PsensorForV2 + "," + valveNum_sample1 + "," + V2targetPressureForFinalFill, "fill intermediate volume with sample")
	
	// Fill MPC from V2
	IRIS_UTILITY_ClearSchedule("FillMPC")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, 0, "ReportStatus", "Evacuating absorption cell", "")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_cell, "open MPC valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, MPCevacTimeForFinalFill, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, 0, "ReportStatus", "Filling cell from intermediate volume", "")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_intermediateVolume, "open intermediate volume valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, MPCfillTimeFromV2, "SendECL", "anc" + valveNum_cell, "close MPC valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_intermediateVolume, "close intermediate volume valve")
	
	// Start transition period
	IRIS_UTILITY_ClearSchedule("StartTransition")
	IRIS_UTILITY_AppendEventToSchedule("StartTransition", 0, 0, "SendECL", "bz" + ECL_transitionIndex, "set ECL index to transition")
	IRIS_UTILITY_AppendEventToSchedule("StartTransition", 0, 0, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule("StartTransition", 0, 0, "SendECL", "bdfits1", "suspend spectral fits")
	
	// Start reference measurement
	IRIS_UTILITY_ClearSchedule("StartRefMeas")
	IRIS_UTILITY_AppendEventToSchedule("StartRefMeas", 0, 0, "SendECL", "bdfits0", "activate spectral fits")
	IRIS_UTILITY_AppendEventToSchedule("StartRefMeas", 0, 0, "SendECL", "bz" + ECL_refIndex, "set ECL index to working reference")
	IRIS_UTILITY_AppendEventToSchedule("StartRefMeas", 0, 0, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule("StartRefMeas", 0, 0, "ReportStatus", "Starting reference measurement", "")
	
	// Start sample measurement
	IRIS_UTILITY_ClearSchedule("StartSampleMeas")
	IRIS_UTILITY_AppendEventToSchedule("StartSampleMeas", 0, 0, "SendECL", "bdfits0", "activate spectral fits")
	IRIS_UTILITY_AppendEventToSchedule("StartSampleMeas", 0, 0, "SendECL", "bz" + ECL_sampleIndex, "set ECL index to sample")
	IRIS_UTILITY_AppendEventToSchedule("StartSampleMeas", 0, 0, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule("StartSampleMeas", 0, 0, "ReportStatus", "Starting sample measurement", "")
	
	// Redo ABG measurement
	IRIS_UTILITY_ClearSchedule("RedoABG")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FlushMPC") // Flush MPC and then fill it with working reference from V2
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FillMPC")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "StartRefMeas") // Start measuring reference
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 0, 0, "StartTimer", "1", "start timer for reference measurement") // start timer 1
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FlushV2") // Flush V2 and then fill it with working reference (while previous ref is being measured in MPC)
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FillV2withRef")
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 1, measurementDuration, "", "", "wait for reference measurement to complete") // Wait for reference measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 0, 0, "ReportStatus", "Reference measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "StartTransition")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "SubtractBackground") // Flush MPC and record background spectrum
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 0, 1, "ResumeCycleSchedule", "", "resume Cycle schedule") // Return to the usual Cycle schedule	
	
	// === BUILD THE RESET SCHEDULE ===
	// 1. A schedule called "Reset", which clears the ECL queue, closes the valves, and starts a new STR/STC file (this will be directly invoked when the "STOP" button is clicked and is also a convenient building block for the Prologue and Epilogue);
	
	// Reset sampling system
	IRIS_UTILITY_ClearSchedule("Reset")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 0, "ReportStatus", "Resetting sampling system", "")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 0, "SendECL", "cq", "immediately clear the ECL queue (this command jumps to the front of the queue)")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 3, "SendECL", "bz" + ECL_transitionIndex, "set ECL index to transition")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "amabg0", "disable ABG")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "bdfits0", "activate spectral fits")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc0", "close valve 0")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc1", "close valve 1")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc8", "close valve 8")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc10", "close valve 10")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc11", "close valve 11")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc13", "close valve 13")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc14", "close valve 14")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "amwd0", "deactivate write disk")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "amass0", "deactivate auto spectral save")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 1, "FetchData", "", "fetch latest data")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 1, "SendECL", "amwd1", "activate write disk")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "amass1", "activate auto spectral save")
	
	// === BUILD THE PROLOGUE SCHEDULE ===
	// 2. A schedule called "Prologue", which consists of the things that happen only at the beginning of the run;
	
	IRIS_UTILITY_ClearSchedule("Prologue")
	
	// Reset sampling system
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "Reset")
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "StartTransition")
	
	// Flush MPC and record background spectrum
	if(doABG == 1)
		IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "SubtractBackground")
	endif
	
	// Flush V2 and then fill it with working reference
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "FlushV2")
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "FillV2withRef")
	
	// === BUILD THE CYCLE SCHEDULE ===
	// 3. A schedule called "Cycle", which consists of the things that happen repetitively;
	
	IRIS_UTILITY_ClearSchedule("Cycle")
	
	// Flush MPC and then fill it with working reference from V2
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FlushMPC")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillMPC")
	
	// Start measuring reference
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartRefMeas")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "StartTimer", "1", "start timer for reference measurement") // start timer 1
	
	// Flush V2 and then fill it with sample (while working reference is being measured in MPC)
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FlushV2")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillV2withSample")
	
	// Wait for reference measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 1, measurementDuration, "", "", "wait for reference measurement to complete") // wait until timer 1 reaches measurementDuration
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "ReportStatus", "Reference measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartTransition")
	
	// Flush MPC and then fill it with sample from V2
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FlushMPC")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillMPC")
	
	// Start measuring sample
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartSampleMeas")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "StartTimer", "1", "start timer for sample measurement") // start timer 1
	
	// Flush V2 and then fill it with working reference (while sample is being measured in MPC)
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FlushV2")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillV2withRef")
	
	// Fetch latest data (while sample is being measured in MPC)
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "ReportStatus", "Fetching and analyzing data", "")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 1, "FetchData", "", "fetch latest data")
	
	// Wait for sample measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 1, measurementDuration, "", "", "wait for sample measurement to complete") // wait until timer 1 reaches measurementDuration
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "ReportStatus", "Sample measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartTransition")
	
	// Check ABG interval and redo ABG if appropriate (only include this as the very last instruction in a cycle, and make sure you have defined a schedule called "RedoABG" above!)
	if((doABG == 1) && (ABGinterval > 0))
		IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 1, "CheckABGinterval", "", "check whether it is time to redo the background")
	endif
	
	// === BUILD THE EPILOGUE SCHEDULE ===
	// 4. A schedule called "Epilogue", which consists of the things that happen only at the end of the run, after the last cycle.
	
	IRIS_UTILITY_ClearSchedule("Epilogue")
	
	// Flush MPC and then fill it with working reference from V2
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "FlushMPC")
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "FillMPC")
	
	// Start measuring reference
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "StartRefMeas")
	IRIS_UTILITY_AppendEventToSchedule("Epilogue", 0, 0, "StartTimer", "1", "start timer for reference measurement") // start timer 1
	
	// Wait for reference measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("Epilogue", 1, measurementDuration, "", "", "wait for reference measurement to complete") // wait until timer 1 reaches measurementDuration
	IRIS_UTILITY_AppendEventToSchedule("Epilogue", 0, 0, "ReportStatus", "Reference measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "StartTransition")
	
	// Reset sampling system
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "Reset")
	
	DoUpdate
	
End

Function IRIS_SCHEME_BuildSchedule_D17O_d13C_CO2_AnalysisOnly()
	
	// NOTE: "UNIVERSAL" sections must be included exactly as they are, exactly where they are.
	
	// === UNIVERSAL: DECLARATIONS (do not modify) ===
	
	NVAR minNumSamples = root:minNumSamples
	NVAR maxNumSamples = root:maxNumSamples
	NVAR minNumRefs = root:minNumRefs
	NVAR maxNumRefs = root:maxNumRefs
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	NVAR numGases = root:numGases
	
	SetDataFolder root:
	
	// === DEFINE MAXIMUM AND MINIMUM ALLOWED NUMBERS OF SAMPLE AND REFERENCE GASES BASED ON HARDWARE ===
	
	minNumSamples = 1
	maxNumSamples = 99
	minNumRefs = 1
	maxNumRefs = 99
	
	// === GET VARIABLES FROM CONFIG PARAMS ===
	
	// Timing
	variable analysisInterval = str2num(IRIS_UTILITY_GetParamValueFromName("Analysis Interval"))
	
	// === MAKE SCHEDULE MODULES TO USE AS BUILDING BLOCKS ===
	
	// USAGE: IRIS_UTILITY_AppendEventToSchedule(sScheduleName, whichTimer, triggerTime, sAction, sArgument, sComment)
	// where sAction is a string that will be appended to "IRIS_EVENT_" to create a reference to a function that takes at most one argument (sArgument), which must be a string
	//	e.g. IRIS_EVENT_SendECL, IRIS_EVENT_ReportStatus, IRIS_EVENT_FetchData, IRIS_EVENT_StartTimer
	
	// === BUILD THE RESET SCHEDULE ===
	// 1. A schedule called "Reset", which starts a new STR/STC file and fetches data (this will be directly invoked when the "STOP" button is clicked and is also a convenient building block for the Prologue and Epilogue);
	
	// Reset sampling system
	IRIS_UTILITY_ClearSchedule("Reset")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 1, "ReportStatus", "Starting new STR/STC and SPE/SPB files", "")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 0, "SendECL", "amwd0", "deactivate write disk")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 0, "SendECL", "amwd1", "activate write disk")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 0, "SendECL", "amass0", "deactivate auto spectral save")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 0, "SendECL", "amass1", "activate auto spectral save")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 2, "ReportStatus", "Fetching and analyzing data", "") // fetching every 30 seconds when doing analysis only
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 0, "FetchData", "", "fetch latest data")
	
	// === BUILD THE PROLOGUE SCHEDULE ===
	// 2. A schedule called "Prologue", which consists of the things that happen only at the beginning of the run;
	
	IRIS_UTILITY_ClearSchedule("Prologue")
	
	// Reset STR/STC and SPE/SPB files and fetch data (but there won't be any yet)
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "Reset")
	
	// === BUILD THE CYCLE SCHEDULE ===
	// 3. A schedule called "Cycle", which consists of the things that happen repetitively;
	
	IRIS_UTILITY_ClearSchedule("Cycle")
	
	// Fetch latest data
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, analysisInterval, "ReportStatus", "Fetching and analyzing data", "") // fetching every 30 seconds when doing analysis only
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "FetchData", "", "fetch latest data")
	
	// === BUILD THE EPILOGUE SCHEDULE ===
	// 4. A schedule called "Epilogue", which consists of the things that happen only at the end of the run, after the last cycle.
	
	IRIS_UTILITY_ClearSchedule("Epilogue")
	
	// Reset STR/STC and SPE/SPB files and fetch final data
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "Reset")
	
	DoUpdate
	
End

Function IRIS_SCHEME_BuildSchedule_IceCore_d13C_CO2()
	
	// NOTE: "UNIVERSAL" sections must be included exactly as they are, exactly where they are.
	
	// === UNIVERSAL: DECLARATIONS (do not modify) ===
	
	NVAR minNumSamples = root:minNumSamples
	NVAR maxNumSamples = root:maxNumSamples
	NVAR minNumRefs = root:minNumRefs
	NVAR maxNumRefs = root:maxNumRefs
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	NVAR numGases = root:numGases
	
	SetDataFolder root:
	
	// === DEFINE MAXIMUM AND MINIMUM ALLOWED NUMBERS OF SAMPLE AND REFERENCE GASES BASED ON HARDWARE ===
	
	minNumSamples = 1
	maxNumSamples = 10
	minNumRefs = 1
	maxNumRefs = 2
	
	// === GET VARIABLES FROM CONFIG PARAMS ===
	
	// Hardware setup
	string valveNum_inlet = IRIS_UTILITY_GetParamValueFromName("Valve Number for Inlet")
	string valveNum_mainVac = IRIS_UTILITY_GetParamValueFromName("Valve Number for Vacuum")
	string valveNum_cell = IRIS_UTILITY_GetParamValueFromName("Valve Number for MPC")
	string VICI_ID = "1" // numbered from 0
	string VICI_port_ref1 = IRIS_UTILITY_GetParamValueFromName("VICI Port for Ref 1")
	string VICI_port_vac1 = IRIS_UTILITY_GetParamValueFromName("VICI Port for Vac 1")
	string VICI_port_ref2 = IRIS_UTILITY_GetParamValueFromName("VICI Port for Ref 2")
	string VICI_port_vac2 = IRIS_UTILITY_GetParamValueFromName("VICI Port for Vac 2")
	string VICI_port_sample1 = IRIS_UTILITY_GetParamValueFromName("VICI Port for Sample")
	string VICI_port_deadEnd = IRIS_UTILITY_GetParamValueFromName("VICI Port for Dead End")
	string PsensorForMPC = IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Number for MPC")
		
	// Get pressure sensor limits
//	NVAR pressureSensorLimitForMPC = root:pressureSensorLimitForMPC // torr, used to prevent the user from selecting target pressures that can never be measured, which would lead to runaway aza (up to its internal time limit)
	variable pressureSensorLimitForMPC = str2num(IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Limit for MPC")) // torr, used to prevent the user from selecting target pressures that can never be measured, which would lead to runaway aza (up to its internal time limit)
	
	// Timing, repetitions, and ABG
	variable doABG = (stringMatch( IRIS_UTILITY_GetParamValueFromName("Subtract Background Spectrum"), "y*" ) == 1) ? 1 : 0 // 0 = no, 1 = yes
	variable ABGinterval = 60*str2num(IRIS_UTILITY_GetParamValueFromName("Background Measurement Interval")) // seconds
	variable backgroundDuration = str2num(IRIS_UTILITY_GetParamValueFromName("Background Measurement Duration")) // seconds
	backgroundDuration += 5 // 5 second safety margin
	variable measurementDuration = str2num(IRIS_UTILITY_GetParamValueFromName("Measurement Duration")) // seconds
	variable MPCevacTimeForFill = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Fill of MPC")) // seconds
	variable MPCevacTimeForABG = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Background")) // seconds
	variable valveActionTimeSpacer = str2num(IRIS_UTILITY_GetParamValueFromName("Valve Action Time Spacer")) // number of seconds to wait before sending valve open or close command, to avoid sending effectively overlapping commands
	
	// Pressures
	string MPCtargetPressureForFill = IRIS_UTILITY_GetParamValueFromName("Target MPC Pressure") // torr
	variable pressureTemp
	pressureTemp = str2num(MPCtargetPressureForFill)
	if(pressureTemp > 0.9*pressureSensorLimitForMPC) // includes a safety margin of 10% of the sensor range
		pressureTemp = 0.9*pressureSensorLimitForMPC
		MPCtargetPressureForFill = num2str(pressureTemp)
		IRIS_UTILITY_SetParamValueByName( "Target MPC Pressure", MPCtargetPressureForFill )
		IRIS_UTILITY_PropagateParamsToTables()
		IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", "*** WARNING: Target pressure reduced to sensor limit! ***")
	endif
	
	// ECL indices
	string ECL_sampleIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Sample 1")
	string ECL_ref1Index = IRIS_UTILITY_GetParamValueFromName("ECL Index for Reference 1")
	string ECL_ref2Index = IRIS_UTILITY_GetParamValueFromName("ECL Index for Reference 2")
	string ECL_transitionIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Transition")
	
	variable i, j
	
	// === MAKE SCHEDULE MODULES TO USE AS BUILDING BLOCKS ===
	
	// USAGE: IRIS_UTILITY_AppendEventToSchedule(sScheduleName, whichTimer, triggerTime, sAction, sArgument, sComment)
	// where sAction is a string that will be appended to "IRIS_EVENT_" to create a reference to a function that takes at most one argument (sArgument), which must be a string
	//	e.g. IRIS_EVENT_SendECL, IRIS_EVENT_ReportStatus, IRIS_EVENT_FetchData, IRIS_EVENT_StartTimer
	
	// Measure and Subtract Background Spectrum
	IRIS_UTILITY_ClearSchedule("SubtractBackground")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ReportStatus", "Evacuating absorption cell", "")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_cell, "open MPC valve")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, MPCevacTimeForABG, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_cell, "close MPC valve")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ReportStatus", "Measuring spectral background", "")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 1, "SendECL", "amabg1", "enable ABG")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "aq", "do a BG measurement")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, backgroundDuration, "", "", "wait for ABG to complete")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ResetABGtimer", "", "reset ABG timer")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ReportStatus", "Done measuring spectral background", "")
	
	// Evacuate Pre-Orifice Volume through VICI Vac 1
	IRIS_UTILITY_ClearSchedule("PumpVICIthroughVac1")
	IRIS_UTILITY_AppendEventToSchedule("PumpVICIthroughVac1", 0, valveActionTimeSpacer, "SendECL", "ba" + VICI_ID + "," + VICI_port_vac1, "switch to vac 1 VICI port")
	
	// Evacuate Pre-Orifice Volume through VICI Vac 2
	IRIS_UTILITY_ClearSchedule("PumpVICIthroughVac2")
	IRIS_UTILITY_AppendEventToSchedule("PumpVICIthroughVac2", 0, valveActionTimeSpacer, "SendECL", "ba" + VICI_ID + "," + VICI_port_vac2, "switch to vac 2 VICI port")
	
	// Fill MPC with Reference 1
	IRIS_UTILITY_ClearSchedule("FillMPCwithRef1")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithRef1", 0, 0, "ReportStatus", "Evacuating absorption cell", "")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithRef1", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithRef1", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_cell, "open MPC valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithRef1", 0, MPCevacTimeForFill, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithRef1", 0, 0, "ReportStatus", "Filling cell with reference 1", "")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithRef1", 0, valveActionTimeSpacer, "SendECL", "ba" + VICI_ID + "," + VICI_port_ref1, "switch to ref 1 VICI port")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithRef1", 0, valveActionTimeSpacer, "SendECL", "aza" + PsensorForMPC + "," + valveNum_inlet + "," + MPCtargetPressureForFill, "fill MPC with ref 1")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithRef1", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_cell, "close MPC valve")
	
	// Fill MPC with Reference 2
	IRIS_UTILITY_ClearSchedule("FillMPCwithRef2")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithRef2", 0, 0, "ReportStatus", "Evacuating absorption cell", "")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithRef2", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithRef2", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_cell, "open MPC valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithRef2", 0, MPCevacTimeForFill, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithRef2", 0, 0, "ReportStatus", "Filling cell with reference 2", "")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithRef2", 0, valveActionTimeSpacer, "SendECL", "ba" + VICI_ID + "," + VICI_port_ref2, "switch to ref 2 VICI port")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithRef2", 0, valveActionTimeSpacer, "SendECL", "aza" + PsensorForMPC + "," + valveNum_inlet + "," + MPCtargetPressureForFill, "fill MPC with ref 2")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithRef2", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_cell, "close MPC valve")
	
	// Fill MPC with Sample
	IRIS_UTILITY_ClearSchedule("FillMPCwithSample1")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithSample1", 0, 0, "ReportStatus", "Evacuating absorption cell", "")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithSample1", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithSample1", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_cell, "open MPC valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithSample1", 0, MPCevacTimeForFill, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithSample1", 0, 0, "ReportStatus", "Filling cell with sample", "")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithSample1", 0, valveActionTimeSpacer, "SendECL", "ba" + VICI_ID + "," + VICI_port_sample1, "switch to sample VICI port")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithSample1", 0, valveActionTimeSpacer, "SendECL", "aza" + PsensorForMPC + "," + valveNum_inlet + "," + MPCtargetPressureForFill, "fill MPC with sample")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithSample1", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_cell, "close MPC valve")
	
	// Start transition period
	IRIS_UTILITY_ClearSchedule("StartTransition")
	IRIS_UTILITY_AppendEventToSchedule("StartTransition", 0, 0, "SendECL", "bz" + ECL_transitionIndex, "set ECL index to transition")
	IRIS_UTILITY_AppendEventToSchedule("StartTransition", 0, 0, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule("StartTransition", 0, 0, "SendECL", "bdfits1", "suspend spectral fits")
	
	// Start reference 1 measurement
	IRIS_UTILITY_ClearSchedule("StartRef1Meas")
	IRIS_UTILITY_AppendEventToSchedule("StartRef1Meas", 0, 0, "SendECL", "bdfits0", "activate spectral fits")
	IRIS_UTILITY_AppendEventToSchedule("StartRef1Meas", 0, 0, "SendECL", "bz" + ECL_ref1Index, "set ECL index to working reference 1")
	IRIS_UTILITY_AppendEventToSchedule("StartRef1Meas", 0, 0, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule("StartRef1Meas", 0, 0, "ReportStatus", "Starting reference 1 measurement", "")
	
	// Start reference 2 measurement
	IRIS_UTILITY_ClearSchedule("StartRef2Meas")
	IRIS_UTILITY_AppendEventToSchedule("StartRef2Meas", 0, 0, "SendECL", "bdfits0", "activate spectral fits")
	IRIS_UTILITY_AppendEventToSchedule("StartRef2Meas", 0, 0, "SendECL", "bz" + ECL_ref2Index, "set ECL index to working reference 2")
	IRIS_UTILITY_AppendEventToSchedule("StartRef2Meas", 0, 0, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule("StartRef2Meas", 0, 0, "ReportStatus", "Starting reference 2 measurement", "")
	
	// Start sample measurement
	IRIS_UTILITY_ClearSchedule("StartSampleMeas")
	IRIS_UTILITY_AppendEventToSchedule("StartSampleMeas", 0, 0, "SendECL", "bdfits0", "activate spectral fits")
	IRIS_UTILITY_AppendEventToSchedule("StartSampleMeas", 0, 0, "SendECL", "bz" + ECL_sampleIndex, "set ECL index to sample")
	IRIS_UTILITY_AppendEventToSchedule("StartSampleMeas", 0, 0, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule("StartSampleMeas", 0, 0, "ReportStatus", "Starting sample measurement", "")
	
	// Redo ABG measurement
	IRIS_UTILITY_ClearSchedule("RedoABG")
	//	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FillMPCwithRef1")
	//	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "StartRef1Meas") // Start measuring reference
	//	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 0, 0, "StartTimer", "1", "start timer for reference 1 measurement") // start timer 1
	//	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 1, measurementDuration, "", "", "wait for reference 1 measurement to complete") // Wait for reference measurement to complete
	//	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 0, 0, "ReportStatus", "Reference 1 measurement complete", "")
	//	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "StartTransition")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "SubtractBackground") // Evacuate MPC and record background spectrum
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 0, 1, "ResumeCycleSchedule", "", "resume Cycle schedule") // Return to the usual Cycle schedule	
	
	// === BUILD THE RESET SCHEDULE ===
	// 1. A schedule called "Reset", which clears the ECL queue, closes the valves, and starts a new STR/STC file (this will be directly invoked when the "STOP" button is clicked and is also a convenient building block for the Prologue and Epilogue);
	
	// Reset sampling system
	IRIS_UTILITY_ClearSchedule("Reset")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 0, "ReportStatus", "Resetting sampling system", "")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 0, "SendECL", "cq", "immediately clear the ECL queue (this command jumps to the front of the queue)")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 3, "SendECL", "bz" + ECL_transitionIndex, "set ECL index to transition")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "amabg0", "disable ABG")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "bdfits0", "activate spectral fits")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc0", "close valve 0")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc1", "close valve 1")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc2", "close valve 2")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc3", "close valve 3")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc4", "close valve 4")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc5", "close valve 5")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "ba" + VICI_ID + "," + VICI_port_vac1, "switch to vac 1 VICI port")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "amwd0", "deactivate write disk")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "amass0", "deactivate auto spectral save")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 1, "FetchData", "", "fetch latest data")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 1, "SendECL", "amwd1", "activate write disk")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "amass1", "activate auto spectral save")
	
	// === BUILD THE PROLOGUE SCHEDULE ===
	// 2. A schedule called "Prologue", which consists of the things that happen only at the beginning of the run;
	
	IRIS_UTILITY_ClearSchedule("Prologue")
	
	// Reset sampling system
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "Reset")
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "StartTransition")
	
	// Evacuate MPC and record background spectrum
	if(doABG == 1)
		IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "SubtractBackground")
	endif
	
	// === BUILD THE CYCLE SCHEDULE ===
	// 3. A schedule called "Cycle", which consists of the things that happen repetitively;
	
	IRIS_UTILITY_ClearSchedule("Cycle")
		
	// Evacuate MPC and then fill it with reference 1
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillMPCwithRef1")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "PumpVICIthroughVac1")
	
	// Start measuring reference 1
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartRef1Meas")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "StartTimer", "1", "start timer for reference 1 measurement") // start timer 1
	
	// Wait for reference 1 measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 1, measurementDuration, "", "", "wait for reference 1 measurement to complete") // wait until timer 1 reaches measurementDuration
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "ReportStatus", "Reference 1 measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartTransition")
	
	// Evacuate MPC and then fill it with reference 2
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillMPCwithRef2")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "PumpVICIthroughVac2")
	
	// Start measuring reference 2
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartRef2Meas")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "StartTimer", "1", "start timer for reference 2 measurement") // start timer 1
	
	// Wait for reference 2 measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 1, measurementDuration, "", "", "wait for reference 2 measurement to complete") // wait until timer 1 reaches measurementDuration
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "ReportStatus", "Reference 2 measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartTransition")
	
	// Evacuate MPC and then fill it with sample
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillMPCwithSample1")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "PumpVICIthroughVac2")
	
	// Start measuring sample
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartSampleMeas")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "StartTimer", "1", "start timer for sample measurement") // start timer 1
	
	// Fetch latest data (while sample is being measured in MPC)
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "ReportStatus", "Fetching and analyzing data", "")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 1, "FetchData", "", "fetch latest data")
	
	// Wait for sample measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 1, measurementDuration, "", "", "wait for sample measurement to complete") // wait until timer 1 reaches measurementDuration
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "ReportStatus", "Sample measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartTransition")
	
	// Evacuate MPC and then fill it with reference 2
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillMPCwithRef2")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "PumpVICIthroughVac1")
	
	// Start measuring reference 2
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartRef2Meas")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "StartTimer", "1", "start timer for reference 2 measurement") // start timer 1
	
	// Wait for reference 2 measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 1, measurementDuration, "", "", "wait for reference 2 measurement to complete") // wait until timer 1 reaches measurementDuration
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "ReportStatus", "Reference 2 measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartTransition")
	
	// Evacuate MPC and then fill it with reference 1
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillMPCwithRef1")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "PumpVICIthroughVac2")
	
	// Start measuring reference 1
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartRef1Meas")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "StartTimer", "1", "start timer for reference 1 measurement") // start timer 1
	
	// Wait for reference 1 measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 1, measurementDuration, "", "", "wait for reference 1 measurement to complete") // wait until timer 1 reaches measurementDuration
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "ReportStatus", "Reference 1 measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartTransition")
	
	// Evacuate MPC and then fill it with sample
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillMPCwithSample1")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "PumpVICIthroughVac1")
	
	// Start measuring sample
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartSampleMeas")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "StartTimer", "1", "start timer for sample measurement") // start timer 1
	
	// Fetch latest data (while sample is being measured in MPC)
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "ReportStatus", "Fetching and analyzing data", "")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 1, "FetchData", "", "fetch latest data")
	
	// Wait for sample measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 1, measurementDuration, "", "", "wait for sample measurement to complete") // wait until timer 1 reaches measurementDuration
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "ReportStatus", "Sample measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartTransition")
	
	// Check ABG interval and redo ABG if appropriate (only include this as the very last instruction in a cycle, and make sure you have defined a schedule called "RedoABG" above!)
	if((doABG == 1) && (ABGinterval > 0))
		IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 1, "CheckABGinterval", "", "check whether it is time to redo the background")
	endif
	
	// === BUILD THE EPILOGUE SCHEDULE ===
	// 4. A schedule called "Epilogue", which consists of the things that happen only at the end of the run, after the last cycle.
	
	IRIS_UTILITY_ClearSchedule("Epilogue")
	
	// Evacuate MPC and then fill it with reference 1
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "FillMPCwithRef1")
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "PumpVICIthroughVac1")
	
	// Start measuring reference 1
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "StartRef1Meas")
	IRIS_UTILITY_AppendEventToSchedule("Epilogue", 0, 0, "StartTimer", "1", "start timer for reference 1 measurement") // start timer 1
	
	// Wait for reference 1 measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("Epilogue", 1, measurementDuration, "", "", "wait for reference 1 measurement to complete") // wait until timer 1 reaches measurementDuration
	IRIS_UTILITY_AppendEventToSchedule("Epilogue", 0, 0, "ReportStatus", "Reference 1 measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "StartTransition")
	
	// Evacuate MPC and then fill it with reference 2
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "FillMPCwithRef2")
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "PumpVICIthroughVac1")
	
	// Start measuring reference 2
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "StartRef2Meas")
	IRIS_UTILITY_AppendEventToSchedule("Epilogue", 0, 0, "StartTimer", "1", "start timer for reference 2 measurement") // start timer 1
	
	// Wait for reference 2 measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("Epilogue", 1, measurementDuration, "", "", "wait for reference 2 measurement to complete") // wait until timer 1 reaches measurementDuration
	IRIS_UTILITY_AppendEventToSchedule("Epilogue", 0, 0, "ReportStatus", "Reference 2 measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "StartTransition")
	
	// Reset sampling system
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "Reset")
	
	DoUpdate
	
End

Function IRIS_SCHEME_BuildSchedule_IceCore_d13C_CO2_noVICI()
	
	// NOTE: "UNIVERSAL" sections must be included exactly as they are, exactly where they are.
	
	// === UNIVERSAL: DECLARATIONS (do not modify) ===
	
	NVAR minNumSamples = root:minNumSamples
	NVAR maxNumSamples = root:maxNumSamples
	NVAR minNumRefs = root:minNumRefs
	NVAR maxNumRefs = root:maxNumRefs
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	NVAR numGases = root:numGases
	
	SetDataFolder root:
	
	// === DEFINE MAXIMUM AND MINIMUM ALLOWED NUMBERS OF SAMPLE AND REFERENCE GASES BASED ON HARDWARE ===
	
	minNumSamples = 1
	maxNumSamples = 1
	minNumRefs = 1
	maxNumRefs = 1
	
	// === GET VARIABLES FROM CONFIG PARAMS ===
	
	// Hardware setup
	string valveNum_sample1 = IRIS_UTILITY_GetParamValueFromName("Valve Number for Sample Inlet")
	string valveNum_ref1 = IRIS_UTILITY_GetParamValueFromName("Valve Number for Ref Inlet")
	string valveNum_sampleVac = IRIS_UTILITY_GetParamValueFromName("Valve Number for Sample Vac")
	string valveNum_mainVac = IRIS_UTILITY_GetParamValueFromName("Valve Number for Main Vac")
	string valveNum_cell = IRIS_UTILITY_GetParamValueFromName("Valve Number for MPC")
	string valveNum_flush = IRIS_UTILITY_GetParamValueFromName("Valve Number for Flush")
	string PsensorForMPC = IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Number for MPC")
		
	// Get pressure sensor limits
//	NVAR pressureSensorLimitForMPC = root:pressureSensorLimitForMPC // torr, used to prevent the user from selecting target pressures that can never be measured, which would lead to runaway aza (up to its internal time limit)
	variable pressureSensorLimitForMPC = str2num(IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Limit for MPC")) // torr, used to prevent the user from selecting target pressures that can never be measured, which would lead to runaway aza (up to its internal time limit)
	
	// Timing, repetitions, and ABG
	variable doABG = (stringMatch( IRIS_UTILITY_GetParamValueFromName("Subtract Background Spectrum"), "y*" ) == 1) ? 1 : 0 // 0 = no, 1 = yes
	variable ABGinterval = 60*str2num(IRIS_UTILITY_GetParamValueFromName("Background Measurement Interval")) // seconds
	variable backgroundDuration = str2num(IRIS_UTILITY_GetParamValueFromName("Background Measurement Duration")) // seconds
	backgroundDuration += 5 // 5 second safety margin
	variable measurementDuration = str2num(IRIS_UTILITY_GetParamValueFromName("Measurement Duration")) // seconds
	variable numMPCflushes = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Flushes of MPC")) // number of multipass cell flushes with nitrogen
	variable MPCevacTimeForFlush = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Flush of MPC")) // seconds
	variable MPCevacTimeForFill = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Fill of MPC")) // seconds
	variable MPCevacTimeForABG = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Background")) // seconds
	variable evacTimeForSampleSide = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time for Sample Side")) // seconds
	variable valveActionTimeSpacer = str2num(IRIS_UTILITY_GetParamValueFromName("Valve Action Time Spacer")) // number of seconds to wait before sending valve open or close command, to avoid sending effectively overlapping commands
	
	// Pressures
	string MPCtargetPressureForFlush = IRIS_UTILITY_GetParamValueFromName("Target Pressure for Flush of MPC") // torr
	variable pressureTemp
	pressureTemp = str2num(MPCtargetPressureForFlush)
	if(pressureTemp > 0.9*pressureSensorLimitForMPC) // includes a safety margin of 10% of the sensor range
		pressureTemp = 0.9*pressureSensorLimitForMPC
		MPCtargetPressureForFlush = num2str(pressureTemp)
		IRIS_UTILITY_SetParamValueByName( "Target Pressure for Flush of MPC", MPCtargetPressureForFlush )
		IRIS_UTILITY_PropagateParamsToTables()
		IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", "*** WARNING: Target pressure reduced to sensor limit! ***")
	endif
	string MPCtargetPressureForFill = IRIS_UTILITY_GetParamValueFromName("Target MPC Pressure") // torr
	pressureTemp = str2num(MPCtargetPressureForFill)
	if(pressureTemp > 0.9*pressureSensorLimitForMPC) // includes a safety margin of 10% of the sensor range
		pressureTemp = 0.9*pressureSensorLimitForMPC
		MPCtargetPressureForFill = num2str(pressureTemp)
		IRIS_UTILITY_SetParamValueByName( "Target MPC Pressure", MPCtargetPressureForFill )
		IRIS_UTILITY_PropagateParamsToTables()
		IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", "*** WARNING: Target pressure reduced to sensor limit! ***")
	endif
	
	// ECL indices
	string ECL_sampleIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Sample 1")
	string ECL_ref1Index = IRIS_UTILITY_GetParamValueFromName("ECL Index for Reference 1")
	string ECL_transitionIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Transition")
	
	variable i, j
	
	// === MAKE SCHEDULE MODULES TO USE AS BUILDING BLOCKS ===
	
	// USAGE: IRIS_UTILITY_AppendEventToSchedule(sScheduleName, whichTimer, triggerTime, sAction, sArgument, sComment)
	// where sAction is a string that will be appended to "IRIS_EVENT_" to create a reference to a function that takes at most one argument (sArgument), which must be a string
	//	e.g. IRIS_EVENT_SendECL, IRIS_EVENT_ReportStatus, IRIS_EVENT_FetchData, IRIS_EVENT_StartTimer
	
	// Measure and Subtract Background Spectrum
	IRIS_UTILITY_ClearSchedule("SubtractBackground")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ReportStatus", "Evacuating absorption cell", "")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_cell, "open MPC valve")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, MPCevacTimeForABG, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_cell, "close MPC valve")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ReportStatus", "Measuring spectral background", "")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 1, "SendECL", "amabg1", "enable ABG")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "aq", "do a BG measurement")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, backgroundDuration, "", "", "wait for ABG to complete")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ResetABGtimer", "", "reset ABG timer")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ReportStatus", "Done measuring spectral background", "")
	
	// Evacuate Pre-Orifice Volume through Sample Vac
	IRIS_UTILITY_ClearSchedule("EvacPreOrificeVolume")
	IRIS_UTILITY_AppendEventToSchedule("EvacPreOrificeVolume", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_sampleVac, "open sample vac valve")
	IRIS_UTILITY_AppendEventToSchedule("EvacPreOrificeVolume", 0, evacTimeForSampleSide, "SendECL", "anc" + valveNum_sampleVac, "close sample vac valve")
	
	// Flush MPC
	IRIS_UTILITY_ClearSchedule("FlushMPC")
	if(numMPCflushes > 0)
		IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_cell, "open MPC valve")
		for(i=0;i<numMPCflushes;i+=1)
			IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, 0, "ReportStatus", "Evacuating absorption cell", "")
			IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, MPCevacTimeForFlush, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, 0, "ReportStatus", "Filling cell with flush gas", "")
			IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, valveActionTimeSpacer, "SendECL", "aza" + PsensorForMPC + "," + valveNum_flush + "," + MPCtargetPressureForFlush, "fill MPC with flush gas")
		endfor
		IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_cell, "close MPC valve")
	endif
	
	// Fill MPC with Reference 1
	IRIS_UTILITY_ClearSchedule("FillMPCwithRef1")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithRef1", 0, 0, "ReportStatus", "Evacuating absorption cell", "")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithRef1", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithRef1", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_cell, "open MPC valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithRef1", 0, MPCevacTimeForFill, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithRef1", 0, 0, "ReportStatus", "Filling cell with reference 1", "")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithRef1", 0, valveActionTimeSpacer, "SendECL", "aza" + PsensorForMPC + "," + valveNum_ref1 + "," + MPCtargetPressureForFill, "fill MPC with ref 1")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithRef1", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_cell, "close MPC valve")
	
	// Fill MPC with Sample 1
	IRIS_UTILITY_ClearSchedule("FillMPCwithSample1")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithSample1", 0, 0, "ReportStatus", "Evacuating absorption cell", "")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithSample1", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithSample1", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_cell, "open MPC valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithSample1", 0, MPCevacTimeForFill, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithSample1", 0, 0, "ReportStatus", "Filling cell with sample", "")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithSample1", 0, valveActionTimeSpacer, "SendECL", "aza" + PsensorForMPC + "," + valveNum_sample1 + "," + MPCtargetPressureForFill, "fill MPC with sample")
	IRIS_UTILITY_AppendEventToSchedule("FillMPCwithSample1", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_cell, "close MPC valve")
	
	// Start transition period
	IRIS_UTILITY_ClearSchedule("StartTransition")
	IRIS_UTILITY_AppendEventToSchedule("StartTransition", 0, 0, "SendECL", "bz" + ECL_transitionIndex, "set ECL index to transition")
	IRIS_UTILITY_AppendEventToSchedule("StartTransition", 0, 0, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule("StartTransition", 0, 0, "SendECL", "bdfits1", "suspend spectral fits")
	
	// Start reference 1 measurement
	IRIS_UTILITY_ClearSchedule("StartRef1Meas")
	IRIS_UTILITY_AppendEventToSchedule("StartRef1Meas", 0, 0, "SendECL", "bdfits0", "activate spectral fits")
	IRIS_UTILITY_AppendEventToSchedule("StartRef1Meas", 0, 0, "SendECL", "bz" + ECL_ref1Index, "set ECL index to working reference 1")
	IRIS_UTILITY_AppendEventToSchedule("StartRef1Meas", 0, 0, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule("StartRef1Meas", 0, 0, "ReportStatus", "Starting reference 1 measurement", "")
	
	// Start sample measurement
	IRIS_UTILITY_ClearSchedule("StartSampleMeas")
	IRIS_UTILITY_AppendEventToSchedule("StartSampleMeas", 0, 0, "SendECL", "bdfits0", "activate spectral fits")
	IRIS_UTILITY_AppendEventToSchedule("StartSampleMeas", 0, 0, "SendECL", "bz" + ECL_sampleIndex, "set ECL index to sample")
	IRIS_UTILITY_AppendEventToSchedule("StartSampleMeas", 0, 0, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule("StartSampleMeas", 0, 0, "ReportStatus", "Starting sample measurement", "")
	
	// Redo ABG measurement
	IRIS_UTILITY_ClearSchedule("RedoABG")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FlushMPC")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FillMPCwithRef1")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "StartRef1Meas") // Start measuring reference
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 0, 0, "StartTimer", "1", "start timer for reference 1 measurement") // start timer 1
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 1, measurementDuration, "", "", "wait for reference 1 measurement to complete") // Wait for reference measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 0, 0, "ReportStatus", "Reference 1 measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "StartTransition")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "SubtractBackground") // Evacuate MPC and record background spectrum
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 0, 1, "ResumeCycleSchedule", "", "resume Cycle schedule") // Return to the usual Cycle schedule	
	
	
	
	
//	// Measure and Subtract Background Spectrum
//	IRIS_UTILITY_ClearSchedule("SubtractBackground")
//	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ReportStatus", "Evacuating absorption cell", "")
//	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_cell, "open MPC valve")
//	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
//	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, MPCevacTimeForABG, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
//	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_cell, "close MPC valve")
//	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ReportStatus", "Measuring spectral background", "")
//	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 1, "SendECL", "amabg1", "enable ABG")
//	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "aq", "do a BG measurement")
//	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, backgroundDuration, "", "", "wait for ABG to complete")
//	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ResetABGtimer", "", "reset ABG timer")
//	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ReportStatus", "Done measuring spectral background", "")
//	
	
	
	
	// === BUILD THE RESET SCHEDULE ===
	// 1. A schedule called "Reset", which clears the ECL queue, closes the valves, and starts a new STR/STC file (this will be directly invoked when the "STOP" button is clicked and is also a convenient building block for the Prologue and Epilogue);
	
	// Reset sampling system
	IRIS_UTILITY_ClearSchedule("Reset")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 0, "ReportStatus", "Resetting sampling system", "")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 0, "SendECL", "cq", "immediately clear the ECL queue (this command jumps to the front of the queue)")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 3, "SendECL", "bz" + ECL_transitionIndex, "set ECL index to transition")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "amabg0", "disable ABG")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "bdfits0", "activate spectral fits")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc0", "close valve 0")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc1", "close valve 1")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc2", "close valve 2")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc3", "close valve 3")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc4", "close valve 4")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc5", "close valve 5")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "amwd0", "deactivate write disk")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "amass0", "deactivate auto spectral save")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 1, "FetchData", "", "fetch latest data")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 1, "SendECL", "amwd1", "activate write disk")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "amass1", "activate auto spectral save")
	
	// === BUILD THE PROLOGUE SCHEDULE ===
	// 2. A schedule called "Prologue", which consists of the things that happen only at the beginning of the run;
	
	IRIS_UTILITY_ClearSchedule("Prologue")
	
	// Reset sampling system
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "Reset")
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "StartTransition")
	
	// Flush MPC and record background spectrum
	if(doABG == 1)
		IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "SubtractBackground")
	endif
	
	// === BUILD THE CYCLE SCHEDULE ===
	// 3. A schedule called "Cycle", which consists of the things that happen repetitively;
	
	IRIS_UTILITY_ClearSchedule("Cycle")
		
	// Evacuate MPC and then fill it with reference 1
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FlushMPC")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillMPCwithRef1")
	
	// Start measuring reference 1
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartRef1Meas")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "StartTimer", "1", "start timer for reference 1 measurement") // start timer 1
	
	// Wait for reference 1 measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 1, measurementDuration, "", "", "wait for reference 1 measurement to complete") // wait until timer 1 reaches measurementDuration
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "ReportStatus", "Reference 1 measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartTransition")
	
	// Evacuate MPC and then fill it with sample
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FlushMPC")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillMPCwithSample1")
	
	// Start measuring sample
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartSampleMeas")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "StartTimer", "1", "start timer for sample measurement") // start timer 1
	
	// Fetch latest data (while sample is being measured in MPC)
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "ReportStatus", "Fetching and analyzing data", "")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 1, "FetchData", "", "fetch latest data")
	
	// Wait for sample measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 1, measurementDuration, "", "", "wait for sample measurement to complete") // wait until timer 1 reaches measurementDuration
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "ReportStatus", "Sample measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartTransition")
	
	// Check ABG interval and redo ABG if appropriate (only include this as the very last instruction in a cycle, and make sure you have defined a schedule called "RedoABG" above!)
	if((doABG == 1) && (ABGinterval > 0))
		IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 1, "CheckABGinterval", "", "check whether it is time to redo the background")
	endif
	
	// === BUILD THE EPILOGUE SCHEDULE ===
	// 4. A schedule called "Epilogue", which consists of the things that happen only at the end of the run, after the last cycle.
	
	IRIS_UTILITY_ClearSchedule("Epilogue")
	
	// Evacuate MPC and then fill it with reference 1
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "FlushMPC")
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "FillMPCwithRef1")
	
	// Start measuring reference 1
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "StartRef1Meas")
	IRIS_UTILITY_AppendEventToSchedule("Epilogue", 0, 0, "StartTimer", "1", "start timer for reference 1 measurement") // start timer 1
	
	// Wait for reference 1 measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("Epilogue", 1, measurementDuration, "", "", "wait for reference 1 measurement to complete") // wait until timer 1 reaches measurementDuration
	IRIS_UTILITY_AppendEventToSchedule("Epilogue", 0, 0, "ReportStatus", "Reference 1 measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "StartTransition")
	
	// Reset sampling system
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "Reset")
	
	DoUpdate
	
End

Function IRIS_SCHEME_BuildSchedule_D638_CO2()
	
	// NOTE: "UNIVERSAL" sections must be included exactly as they are, exactly where they are.
	
	// === UNIVERSAL: DECLARATIONS (do not modify) ===
	
	NVAR minNumSamples = root:minNumSamples
	NVAR maxNumSamples = root:maxNumSamples
	NVAR minNumRefs = root:minNumRefs
	NVAR maxNumRefs = root:maxNumRefs
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	NVAR numGases = root:numGases
	
	SetDataFolder root:
	
	// === DEFINE MAXIMUM AND MINIMUM ALLOWED NUMBERS OF SAMPLE AND REFERENCE GASES BASED ON HARDWARE ===
	
	minNumSamples = 1
	maxNumSamples = 1
	minNumRefs = 1
	maxNumRefs = 1
	
	// === GET VARIABLES FROM CONFIG PARAMS ===
	
	// Hardware setup
	string valveNum_sampleOrifice = IRIS_UTILITY_GetParamValueFromName("Valve Number for Sample Orifice")
	string valveNum_refOrifice = IRIS_UTILITY_GetParamValueFromName("Valve Number for Ref Orifice")
	string valveNum_intermediateVolume = IRIS_UTILITY_GetParamValueFromName("Valve Number for V2")
	string valveNum_flush = IRIS_UTILITY_GetParamValueFromName("Valve Number for Flush")
	string valveNum_mainVac = IRIS_UTILITY_GetParamValueFromName("Valve Number for Vacuum")
	string valveNum_cell = IRIS_UTILITY_GetParamValueFromName("Valve Number for MPC")
	string valveNum_workingRef = IRIS_UTILITY_GetParamValueFromName("Valve Number for Working Ref Supply to Ref Orifice")
	string valveNum_refVac = IRIS_UTILITY_GetParamValueFromName("Valve Number for Vacuum Supply to Ref Orifice")
	string valveNum_zeroAir = IRIS_UTILITY_GetParamValueFromName("Valve Number for Zero Air Supply to Ref Orifice")
	string PsensorForMPC = IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Number for MPC")
	string PsensorForV2 = IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Number for V2")
	variable system_to_V2_volume_ratio = str2num(IRIS_UTILITY_GetParamValueFromName("Ratio of Total System Volume to V2"))
	
	// Pressure sensor limits
	variable pressureSensorLimitForV2 = str2num(IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Limit for V2")) // torr, used to prevent the user from selecting target pressures that can never be measured, which would lead to runaway aza (up to its internal time limit)
	variable pressureSensorLimitForMPC = str2num(IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Limit for MPC")) // torr, used to prevent the user from selecting target pressures that can never be measured, which would lead to runaway aza (up to its internal time limit)
	
	// Timing, repetitions, and ABG
	variable doABG = (stringMatch( IRIS_UTILITY_GetParamValueFromName("Subtract Background Spectrum"), "y*" ) == 1) ? 1 : 0 // 0 = no, 1 = yes
	variable useZAforABG = (stringMatch( IRIS_UTILITY_GetParamValueFromName("Use Zero Air from Ref Orifice for Background Spectrum"), "y*" ) == 1) ? 1 : 0 // 0 = no, 1 = yes
	variable ABGinterval = 60*str2num(IRIS_UTILITY_GetParamValueFromName("Background Measurement Interval")) // seconds
	variable backgroundDuration = str2num(IRIS_UTILITY_GetParamValueFromName("Background Measurement Duration")) // seconds
	backgroundDuration += 5 // 5 second safety margin
	variable numV2flushes = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Flushes of V2")) // number of intermediate volume flushes with nitrogen
	variable numMPCflushes = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Flushes of MPC")) // number of multipass cell flushes with nitrogen
	variable measurementDuration = str2num(IRIS_UTILITY_GetParamValueFromName("Measurement Duration")) // seconds
	variable refOrificeEvacTime = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time for Ref Pre-Orifice Volume")) // seconds
	variable V2evacTimeForFlush = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Flush of V2")) // seconds
	variable V2evacTimeForFinalFill = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Final Fill of V2")) // seconds
	variable MPCevacTimeForFlush = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Flush of MPC")) // seconds
	variable MPCevacTimeForFinalFill = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Final Fill of MPC")) // seconds
	variable MPCevacTimeForABG = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Background")) // seconds
	variable MPCfillTimeFromV2 = str2num(IRIS_UTILITY_GetParamValueFromName("Time to Wait for Fill of MPC from V2")) // seconds
	variable valveActionTimeSpacer = str2num(IRIS_UTILITY_GetParamValueFromName("Valve Action Time Spacer")) // number of seconds to wait before sending valve open or close command, to avoid sending effectively overlapping commands
	
	// Pressures
	variable target_MPC_pressure = str2num(IRIS_UTILITY_GetParamValueFromName("Target MPC Pressure")) // torr
	variable pressureTemp
	pressureTemp = target_MPC_pressure
	if(pressureTemp > 0.9*pressureSensorLimitForMPC) // includes a safety margin of 10% of the sensor range
		pressureTemp = 0.9*pressureSensorLimitForMPC
		target_MPC_pressure = pressureTemp
		IRIS_UTILITY_SetParamValueByName( "Target MPC Pressure", num2str(target_MPC_pressure) )
		IRIS_UTILITY_PropagateParamsToTables()
		IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", "*** WARNING: Target pressure reduced to sensor limit! ***")
	endif
	string V2targetPressureForFlush = IRIS_UTILITY_GetParamValueFromName("Target Pressure for Flush of V2") // torr
	pressureTemp = str2num(V2targetPressureForFlush)
	if(pressureTemp > 0.9*pressureSensorLimitForV2) // includes a safety margin of 10% of the sensor range
		pressureTemp = 0.9*pressureSensorLimitForV2
		V2targetPressureForFlush = num2str(pressureTemp)
		IRIS_UTILITY_SetParamValueByName( "Target Pressure for Flush of V2", V2targetPressureForFlush )
		IRIS_UTILITY_PropagateParamsToTables()
		IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", "*** WARNING: Target pressure reduced to sensor limit! ***")
	endif
	string MPCtargetPressureForFlush = IRIS_UTILITY_GetParamValueFromName("Target Pressure for Flush of MPC") // torr
	pressureTemp = str2num(MPCtargetPressureForFlush)
	if(pressureTemp > 0.9*pressureSensorLimitForMPC) // includes a safety margin of 10% of the sensor range
		pressureTemp = 0.9*pressureSensorLimitForMPC
		MPCtargetPressureForFlush = num2str(pressureTemp)
		IRIS_UTILITY_SetParamValueByName( "Target Pressure for Flush of MPC", MPCtargetPressureForFlush )
		IRIS_UTILITY_PropagateParamsToTables()
		IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", "*** WARNING: Target pressure reduced to sensor limit! ***")
	endif
	
	// ECL indices
	string ECL_sampleIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Sample 1")
	string ECL_refIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Reference 1")
	string ECL_transitionIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Transition")
	
	string V2targetPressureForFinalFill = num2istr(target_MPC_pressure*system_to_V2_volume_ratio) // torr
		
	variable i, j
	
	// === MAKE SCHEDULE MODULES TO USE AS BUILDING BLOCKS ===
	
	// USAGE: IRIS_UTILITY_AppendEventToSchedule(sScheduleName, whichTimer, triggerTime, sAction, sArgument, sComment)
	// where sAction is a string that will be appended to "IRIS_EVENT_" to create a reference to a function that takes at most one argument (sArgument), which must be a string
	//	e.g. IRIS_EVENT_SendECL, IRIS_EVENT_ReportStatus, IRIS_EVENT_FetchData, IRIS_EVENT_StartTimer
	
	// Flush V2
	IRIS_UTILITY_ClearSchedule("FlushV2")
	if(numV2flushes > 0)
		IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_intermediateVolume, "open intermediate volume valve")
		for(i=0;i<numV2flushes;i+=1)
			IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, 0, "ReportStatus", "Evacuating intermediate volume", "")
			IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, V2evacTimeForFlush, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, 0, "ReportStatus", "Filling int. volume with flush gas", "")
			IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, valveActionTimeSpacer, "SendECL", "aza" + PsensorForV2 + "," + valveNum_flush + "," + V2targetPressureForFlush, "fill intermediate volume with nitrogen")
		endfor
		IRIS_UTILITY_AppendEventToSchedule("FlushV2", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_intermediateVolume, "close intermediate volume valve")
	endif
	
	// Flush MPC
	IRIS_UTILITY_ClearSchedule("FlushMPC")
	if(numMPCflushes > 0)
		IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_cell, "open MPC valve")
		for(i=0;i<numMPCflushes;i+=1)
			IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, 0, "ReportStatus", "Evacuating absorption cell", "")
			IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, MPCevacTimeForFlush, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, 0, "ReportStatus", "Filling cell with flush gas", "")
			IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, valveActionTimeSpacer, "SendECL", "aza" + PsensorForMPC + "," + valveNum_flush + "," + MPCtargetPressureForFlush, "fill MPC with nitrogen")
		endfor
		IRIS_UTILITY_AppendEventToSchedule("FlushMPC", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_cell, "close MPC valve")
	endif
	
	// Evacuate MPC
	IRIS_UTILITY_ClearSchedule("EvacuateMPC")
	IRIS_UTILITY_AppendEventToSchedule("EvacuateMPC", 0, 0, "ReportStatus", "Evacuating absorption cell", "")
	IRIS_UTILITY_AppendEventToSchedule("EvacuateMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("EvacuateMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_cell, "open MPC valve")
	IRIS_UTILITY_AppendEventToSchedule("EvacuateMPC", 0, MPCevacTimeForABG, "SendECL", "anc" + valveNum_cell, "close MPC valve")
	IRIS_UTILITY_AppendEventToSchedule("EvacuateMPC", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
	
	// Switch Reference Orifice to Zero Air
	IRIS_UTILITY_ClearSchedule("SwitchRefToZero")
	IRIS_UTILITY_AppendEventToSchedule("SwitchRefToZero", 0, 0, "ReportStatus", "Switching ref. orifice to zero air", "")
	IRIS_UTILITY_AppendEventToSchedule("SwitchRefToZero", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_workingRef, "close working ref supply to ref orifice")
	IRIS_UTILITY_AppendEventToSchedule("SwitchRefToZero", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_zeroAir, "close zero air supply to ref orifice")
	IRIS_UTILITY_AppendEventToSchedule("SwitchRefToZero", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_refVac, "open vacuum supply to ref orifice")
	IRIS_UTILITY_AppendEventToSchedule("SwitchRefToZero", 0, refOrificeEvacTime, "SendECL", "anc" + valveNum_refVac, "close vacuum supply to ref orifice")
	IRIS_UTILITY_AppendEventToSchedule("SwitchRefToZero", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_zeroAir, "open zero air supply to ref orifice")
	
	// Switch Reference Orifice to Working Reference
	IRIS_UTILITY_ClearSchedule("SwitchRefToWorkingRef")
	IRIS_UTILITY_AppendEventToSchedule("SwitchRefToWorkingRef", 0, 0, "ReportStatus", "Switching ref. orifice to working ref.", "")
	IRIS_UTILITY_AppendEventToSchedule("SwitchRefToWorkingRef", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_zeroAir, "close zero air supply to ref orifice")
	IRIS_UTILITY_AppendEventToSchedule("SwitchRefToWorkingRef", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_workingRef, "close working ref supply to ref orifice")
	IRIS_UTILITY_AppendEventToSchedule("SwitchRefToWorkingRef", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_refVac, "open vacuum supply to ref orifice")
	IRIS_UTILITY_AppendEventToSchedule("SwitchRefToWorkingRef", 0, refOrificeEvacTime, "SendECL", "anc" + valveNum_refVac, "close vacuum supply to ref orifice")
	IRIS_UTILITY_AppendEventToSchedule("SwitchRefToWorkingRef", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_workingRef, "open working ref supply to ref orifice")
	
	// Fill V2 from Reference Orifice
	IRIS_UTILITY_ClearSchedule("FillV2withRef")
	if(V2evacTimeForFinalFill > 0)
		IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, 0, "ReportStatus", "Evacuating intermediate volume", "")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_intermediateVolume, "open intermediate volume valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, V2evacTimeForFinalFill, "SendECL", "anc" + valveNum_intermediateVolume, "close intermediate volume valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
	endif
	IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, 0, "ReportStatus", "Filling int. volume from ref. orifice", "")
	IRIS_UTILITY_AppendEventToSchedule("FillV2withRef", 0, valveActionTimeSpacer, "SendECL", "aza" + PsensorForV2 + "," + valveNum_refOrifice + "," + V2targetPressureForFinalFill, "fill intermediate volume from reference orifice")
	
	// Fill V2 from Sample Orifice
	IRIS_UTILITY_ClearSchedule("FillV2withSample")
	if(V2evacTimeForFinalFill > 0)
		IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, 0, "ReportStatus", "Evacuating intermediate volume", "")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_intermediateVolume, "open intermediate volume valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, V2evacTimeForFinalFill, "SendECL", "anc" + valveNum_intermediateVolume, "close intermediate volume valve")
		IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
	endif
	IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, 0, "ReportStatus", "Filling int. volume from sample orifice", "")
	IRIS_UTILITY_AppendEventToSchedule("FillV2withSample", 0, valveActionTimeSpacer, "SendECL", "aza" + PsensorForV2 + "," + valveNum_sampleOrifice + "," + V2targetPressureForFinalFill, "fill intermediate volume from sample orifice")
	
	// Fill MPC from V2
	IRIS_UTILITY_ClearSchedule("FillMPC")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, 0, "ReportStatus", "Evacuating absorption cell", "")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_mainVac, "open vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_cell, "open MPC valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, MPCevacTimeForFinalFill, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, 0, "ReportStatus", "Filling cell from intermediate volume", "")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, valveActionTimeSpacer, "SendECL", "ano" + valveNum_intermediateVolume, "open intermediate volume valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, MPCfillTimeFromV2, "SendECL", "anc" + valveNum_cell, "close MPC valve")
	IRIS_UTILITY_AppendEventToSchedule("FillMPC", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_intermediateVolume, "close intermediate volume valve")
	
	// Measure and Subtract Background Spectrum
	IRIS_UTILITY_ClearSchedule("SubtractBackground")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 1, "SendECL", "amabg1", "enable ABG")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ReportStatus", "Measuring spectral background", "")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "aq", "do a BG measurement")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, backgroundDuration, "", "", "wait for ABG to complete")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ResetABGtimer", "", "reset ABG timer")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ReportStatus", "Done measuring spectral background", "")
	
	// Start transition period
	IRIS_UTILITY_ClearSchedule("StartTransition")
	IRIS_UTILITY_AppendEventToSchedule("StartTransition", 0, 0, "SendECL", "bz" + ECL_transitionIndex, "set ECL index to transition")
	IRIS_UTILITY_AppendEventToSchedule("StartTransition", 0, 0, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule("StartTransition", 0, 0, "SendECL", "bdfits1", "suspend spectral fits")
	
	// Start reference measurement
	IRIS_UTILITY_ClearSchedule("StartRefMeas")
	IRIS_UTILITY_AppendEventToSchedule("StartRefMeas", 0, 0, "SendECL", "bdfits0", "activate spectral fits")
	IRIS_UTILITY_AppendEventToSchedule("StartRefMeas", 0, 0, "SendECL", "bz" + ECL_refIndex, "set ECL index to working reference")
	IRIS_UTILITY_AppendEventToSchedule("StartRefMeas", 0, 0, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule("StartRefMeas", 0, 0, "ReportStatus", "Starting reference measurement", "")
	
	// Start sample measurement
	IRIS_UTILITY_ClearSchedule("StartSampleMeas")
	IRIS_UTILITY_AppendEventToSchedule("StartSampleMeas", 0, 0, "SendECL", "bdfits0", "activate spectral fits")
	IRIS_UTILITY_AppendEventToSchedule("StartSampleMeas", 0, 0, "SendECL", "bz" + ECL_sampleIndex, "set ECL index to sample")
	IRIS_UTILITY_AppendEventToSchedule("StartSampleMeas", 0, 0, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule("StartSampleMeas", 0, 0, "ReportStatus", "Starting sample measurement", "")
	
	// Redo ABG measurement
	IRIS_UTILITY_ClearSchedule("RedoABG")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FlushMPC")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FillMPC") // Fill MPC with working reference from V2
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "StartRefMeas") // Start measuring reference
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 0, 0, "StartTimer", "1", "start timer for reference measurement") // start timer 1
	if(useZAforABG == 1)
		IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "SwitchRefToZero")
	endif
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FlushV2")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FillV2withRef") // Fill V2 with working reference or zero air (while previous ref is being measured in MPC)
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 1, measurementDuration, "", "", "wait for reference measurement to complete") // Wait for reference measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 0, 0, "ReportStatus", "Reference measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "StartTransition")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FlushMPC")
	if(useZAforABG == 1)
		IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FillMPC") // Fill MPC with zero air from V2
	else
		IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "EvacuateMPC")
	endif
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "SubtractBackground") // Record background spectrum
	if(useZAforABG == 1)
		IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "SwitchRefToWorkingRef")
		IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FlushV2")
		IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FillV2withRef") // Fill V2 with working reference
	endif
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 0, 1, "ResumeCycleSchedule", "", "resume Cycle schedule") // Return to the usual Cycle schedule	
	
	// === BUILD THE RESET SCHEDULE ===
	// 1. A schedule called "Reset", which clears the ECL queue, closes the valves, and starts a new STR/STC file (this will be directly invoked when the "STOP" button is clicked and is also a convenient building block for the Prologue and Epilogue);
	
	// Reset sampling system
	IRIS_UTILITY_ClearSchedule("Reset")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 0, "ReportStatus", "Resetting sampling system", "")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 0, "SendECL", "cq", "immediately clear the ECL queue (this command jumps to the front of the queue)")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 3, "SendECL", "bz" + ECL_transitionIndex, "set ECL index to transition")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "amabg0", "disable ABG")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "bdfits0", "activate spectral fits")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_flush, "close flush valve")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_mainVac, "close vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_cell, "close MPC valve")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_sampleOrifice, "close sample valve")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_refOrifice, "close ref valve")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_workingRef, "close ref orifice working ref valve")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_zeroAir, "close ref orifice zero air valve")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_refVac, "close ref orifice vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "anc" + valveNum_intermediateVolume, "close intermediate valve")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "amwd0", "deactivate write disk")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "amass0", "deactivate auto spectral save")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 1, "FetchData", "", "fetch latest data")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, 1, "SendECL", "amwd1", "activate write disk")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "amass1", "activate auto spectral save")
	
	// === BUILD THE PROLOGUE SCHEDULE ===
	// 2. A schedule called "Prologue", which consists of the things that happen only at the beginning of the run;
	
	IRIS_UTILITY_ClearSchedule("Prologue")
	
	// Reset sampling system
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "Reset")
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "StartTransition")
	
	// Record background spectrum
	if(doABG == 1)
		if(useZAforABG == 1)
			IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "SwitchRefToZero")
			IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "FlushV2")
			IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "FillV2withRef") // Fill V2 with zero air (while previous ref is being measured in MPC)
			IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "FlushMPC")
			IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "FillMPC") // Fill MPC with zero air from V2
		else
			IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "FlushMPC")
			IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "EvacuateMPC")
		endif
		IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "SubtractBackground")
	endif
	
	// Flush V2 and then fill it with working reference
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "SwitchRefToWorkingRef")
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "FlushV2")
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "FillV2withRef")
	
	// === BUILD THE CYCLE SCHEDULE ===
	// 3. A schedule called "Cycle", which consists of the things that happen repetitively;
	
	IRIS_UTILITY_ClearSchedule("Cycle")
	
	// Flush MPC and then fill it with working reference from V2
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FlushMPC")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillMPC")
	
	// Start measuring reference
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartRefMeas")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "StartTimer", "1", "start timer for reference measurement") // start timer 1
	
	// Flush V2 and then fill it with sample (while working reference is being measured in MPC)
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FlushV2")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillV2withSample")
	
	// Wait for reference measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 1, measurementDuration, "", "", "wait for reference measurement to complete") // wait until timer 1 reaches measurementDuration
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "ReportStatus", "Reference measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartTransition")
	
	// Flush MPC and then fill it with sample from V2
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FlushMPC")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillMPC")
	
	// Start measuring sample
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartSampleMeas")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "StartTimer", "1", "start timer for sample measurement") // start timer 1
	
	// Flush V2 and then fill it with working reference (while sample is being measured in MPC)
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FlushV2")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillV2withRef")
	
	// Fetch latest data (while sample is being measured in MPC)
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "ReportStatus", "Fetching and analyzing data", "")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 1, "FetchData", "", "fetch latest data")
	
	// Wait for sample measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 1, measurementDuration, "", "", "wait for sample measurement to complete") // wait until timer 1 reaches measurementDuration
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "ReportStatus", "Sample measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartTransition")
	
	// Check ABG interval and redo ABG if appropriate (only include this as the very last instruction in a cycle!)
	if((doABG == 1) && (ABGinterval > 0))
		IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 1, "CheckABGinterval", "", "check whether it is time to redo the background")
	endif
	
	// === BUILD THE EPILOGUE SCHEDULE ===
	// 4. A schedule called "Epilogue", which consists of the things that happen only at the end of the run, after the last cycle.
	
	IRIS_UTILITY_ClearSchedule("Epilogue")
	
	// Flush MPC and then fill it with working reference from V2
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "FlushMPC")
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "FillMPC")
	
	// Start measuring reference
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "StartRefMeas")
	IRIS_UTILITY_AppendEventToSchedule("Epilogue", 0, 0, "StartTimer", "1", "start timer for reference measurement") // start timer 1
	
	// Wait for reference measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("Epilogue", 1, measurementDuration, "", "", "wait for reference measurement to complete") // wait until timer 1 reaches measurementDuration
	IRIS_UTILITY_AppendEventToSchedule("Epilogue", 0, 0, "ReportStatus", "Reference measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "StartTransition")
	
	// Reset sampling system
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "Reset")
	
	DoUpdate
	
End

//////////////////////////////////
// Roster of Analysis Functions //
//////////////////////////////////

Function IRIS_SCHEME_Analyze_D17O_CO2()
	
	// NOTE: "UNIVERSAL" sections must be included exactly as they are, exactly where they are.
	
	// === UNIVERSAL: SETUP (do not modify) ===
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	
	variable sampleNum, refNum
	
	string sIRIStemp
	
	string saveFolder = getdatafolder(1)
	SetDataFolder root:
	
	make/O/N=(numSampleGases) wSampleIndices
	make/O/N=(numRefGases) wRefIndices
	
	variable parseFlag = IRIS_UTILITY_AnalysisSetup()
	if(parseFlag == 1)
		SetDataFolder $saveFolder
		return 0
	endif
	
	// === COLLATE THE TRUE REF GAS INFO ===
	// NOTE: Whatever wave names you choose here will need to be used consistently afterward in this function.
	
	variable infoFlag = 0
	make/O/N=(numRefGases) wRefTrueValues_CO2, wRefTrueValues_d18O, wRefTrueValues_d17O
	for(refNum=0;refNum<numRefGases;refNum+=1)
		
		sIRIStemp = "Reference " + num2str(refNum+1) + ": " + "CO2 Mole Fraction"
		wRefTrueValues_CO2[refNum] = str2num(IRIS_UTILITY_GetParamValueFromName(sIRIStemp)) // ppm
		infoFlag = (numtype(wRefTrueValues_CO2[refNum]) != 0) ? 1 : infoFlag
		
		sIRIStemp = "Reference " + num2str(refNum+1) + ": " + "δ18O"
		wRefTrueValues_d18O[refNum] = str2num(IRIS_UTILITY_GetParamValueFromName(sIRIStemp)) // permil VSMOW
		infoFlag = (numtype(wRefTrueValues_d18O[refNum]) != 0) ? 1 : infoFlag
		
		sIRIStemp = "Reference " + num2str(refNum+1) + ": " + "δ17O"
		wRefTrueValues_d17O[refNum] = str2num(IRIS_UTILITY_GetParamValueFromName(sIRIStemp)) // permil VSMOW
		infoFlag = (numtype(wRefTrueValues_d17O[refNum]) != 0) ? 1 : infoFlag
		
	endfor
	
	if(infoFlag > 0)
		IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", secs2time(DateTime,3) + "  " + "*** WARNING: The info for working gas " + num2str(refNum+1) + " is invalid! ***")
	endif
	
	// === CONVERT TRUE REF GAS DELTAS AND TOTAL CO2 TO ISOTOPOLOGUE MOLE FRACTIONS ===
	// NOTE: You must name the ref gas true isotopologue waves in the format: wRefTrueValues_iXXX, where XXX is 626 or 628 or 627_A, etc. (iXXX must be an entry in wOutputVariableSourceDataNames[wIndicesOfVariablesToCalibrate[j]] for some j).	
	
	make/O/D/N=(numRefGases) wRefTrueValues_i626, wRefTrueValues_i628, wRefTrueValues_i627
	[wRefTrueValues_i626, wRefTrueValues_i628, wRefTrueValues_i627] = IRIS_UTILITY_ConvertFrom_d18O_d17O(wRefTrueValues_CO2, wRefTrueValues_d18O, wRefTrueValues_d17O)
	
	// === CALCULATE DERIVED VARIABLES, PRE-CALIBRATION ===
	// NOTE: The names of the mole fraction waves imported from TDL Wintel have the format root:iXXX for isotopologues (e.g. root:i626, root:i638, root:i627_A) and simply root:XXX otherwise (e.g. root:CO2, root:N2O), except for OCS, which is root:xOCS for some reason.
	//       All variables in the IRIS_SCHEME_DefineVariables function that have type "str" or "stc" but are not imported from TDL Wintel must be created here.
	
	variable lamda_O17O18_slope = str2num(IRIS_UTILITY_GetParamValueFromName("Reference slope (λ)"))
	
	wave i626 = root:i626
	wave i627 = root:i627
	wave i628 = root:i628
	
	duplicate/O i626, del17O, del18O, capDel17O
	del17O = 1000*((i627/i626) - 1) //permil (vs HITRAN, uncalibrated)
	del18O = 1000*((i628/i626) - 1) //permil (vs HITRAN, uncalibrated)
	capDel17O = 1000*ln(del17O/1000 + 1) - lamda_O17O18_slope*1000*ln(del18O/1000 + 1)
	
	// === UNIVERSAL: CALCULATE THE MEAN AND STANDARD ERROR FOR EACH CELL FILL (do not modify) ===
	
	IRIS_UTILITY_CalculateGasFillMeansForAllVariables()
	
	// === FOR EACH SAMPLE GAS... ===
		
	for(sampleNum=0;sampleNum<numSampleGases;sampleNum+=1) 
		
		// === ...UNIVERSAL: CALIBRATE SAMPLE SPECIES/ISOTOPOLOGUE MEANS VIA THE REF GAS(ES) (do not modify) ===
		
		IRIS_UTILITY_CalibrateAllSampleVariablesViaRefs(sampleNum)
		
		// === ...CALCULATE DERIVED VARIABLES, POST-CALIBRATION ===
		// NOTE: The names of the calibrated mole fraction waves that you can use here have the format: root:X_cal, where X is the name of the corresponding wave imported from TDL Wintel (e.g. root:i626_cal or root:N2O_cal or root:xOCS_cal).
		//       All variables in the IRIS_SCHEME_DefineVariables function that have type "avg" but calibrateOrNot = 0 must be created here.
		
		wave i626_cal = root:i626_cal
		wave i627_cal = root:i627_cal
		wave i628_cal = root:i628_cal
		
		duplicate/O i626_cal, d17O_VSMOW_Avg, d18O_VSMOW_Avg, CO2_Avg, d17O_prime, d18O_prime, CapD17O
		[CO2_Avg, d18O_VSMOW_Avg, d17O_VSMOW_Avg] = IRIS_UTILITY_ConvertTo_d18O_d17O(i626_cal, i628_cal, i627_cal)
		d17O_prime = 1000*ln(d17O_VSMOW_Avg/1000 + 1)
		d18O_prime = 1000*ln(d18O_VSMOW_Avg/1000 + 1)
		CapD17O = d17O_prime - lamda_O17O18_slope * d18O_prime // this is the small deviation from the 'conventional' bulk slope (Sharp et al.)
		
		// === ...UNIVERSAL: ASSIGN REMAINING RESULTS TO OUTPUT VARIABLES (do not modify) ===
		
		IRIS_UTILITY_AssignAllSpecialOutputVariables(sampleNum)
		
	endfor
	
	// === UNIVERSAL: WRAP-UP (do not modify) ===
	
	IRIS_UTILITY_AnalysisWrapUp()
	
	SetDataFolder $saveFolder
	return 0
	
End

Function IRIS_SCHEME_Analyze_D17O_CO2_Bellows()
	
	IRIS_SCHEME_Analyze_D17O_CO2() // the analysis is the same regardless of whether the sampling system uses bellows or TDL Wintel's aza algorithm to achieve the target pressure
	
End

Function IRIS_SCHEME_Analyze_D17O_d13C_CO2()
	
	// NOTE: "UNIVERSAL" sections must be included exactly as they are, exactly where they are.
	
	// === UNIVERSAL: SETUP (do not modify) ===
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	
	variable sampleNum, refNum
	
	string sIRIStemp
	
	string saveFolder = getdatafolder(1)
	SetDataFolder root:
	
	make/O/N=(numSampleGases) wSampleIndices
	make/O/N=(numRefGases) wRefIndices
	
	variable parseFlag = IRIS_UTILITY_AnalysisSetup()
	if(parseFlag == 1)
		SetDataFolder $saveFolder
		return 0
	endif
	
	// === COLLATE THE TRUE REF GAS INFO ===
	// NOTE: Whatever wave names you choose here will need to be used consistently afterward in this function.
	
	variable infoFlag = 0
	make/O/N=(numRefGases) wRefTrueValues_CO2, wRefTrueValues_d13C, wRefTrueValues_d18O, wRefTrueValues_d17O
	for(refNum=0;refNum<numRefGases;refNum+=1)
		
		sIRIStemp = "Reference " + num2str(refNum+1) + ": " + "CO2 Mole Fraction"
		wRefTrueValues_CO2[refNum] = str2num(IRIS_UTILITY_GetParamValueFromName(sIRIStemp)) // ppm
		infoFlag = (numtype(wRefTrueValues_CO2[refNum]) != 0) ? 1 : infoFlag
		
		sIRIStemp = "Reference " + num2str(refNum+1) + ": " + "δ13C"
		wRefTrueValues_d13C[refNum] = str2num(IRIS_UTILITY_GetParamValueFromName(sIRIStemp)) // permil VSMOW
		infoFlag = (numtype(wRefTrueValues_d13C[refNum]) != 0) ? 1 : infoFlag
		
		sIRIStemp = "Reference " + num2str(refNum+1) + ": " + "δ18O"
		wRefTrueValues_d18O[refNum] = str2num(IRIS_UTILITY_GetParamValueFromName(sIRIStemp)) // permil VSMOW
		infoFlag = (numtype(wRefTrueValues_d18O[refNum]) != 0) ? 1 : infoFlag
		
		sIRIStemp = "Reference " + num2str(refNum+1) + ": " + "δ17O"
		wRefTrueValues_d17O[refNum] = str2num(IRIS_UTILITY_GetParamValueFromName(sIRIStemp)) // permil VSMOW
		infoFlag = (numtype(wRefTrueValues_d17O[refNum]) != 0) ? 1 : infoFlag
		
	endfor
	
	if(infoFlag > 0)
		IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", secs2time(DateTime,3) + "  " + "*** WARNING: The info for working gas " + num2str(refNum+1) + " is invalid! ***")
	endif
	
	// === CONVERT TRUE REF GAS DELTAS AND TOTAL CO2 TO ISOTOPOLOGUE MOLE FRACTIONS ===
	// NOTE: You must name the ref gas true isotopologue waves in the format: wRefTrueValues_iXXX, where XXX is 626 or 628 or 627_A, etc. (iXXX must be an entry in wOutputVariableSourceDataNames[wIndicesOfVariablesToCalibrate[j]] for some j).
	
	make/O/D/N=(numRefGases) wRefTrueValues_i626, wRefTrueValues_i636, wRefTrueValues_i628, wRefTrueValues_i627_A
	[wRefTrueValues_i626, wRefTrueValues_i636, wRefTrueValues_i628, wRefTrueValues_i627_A] = IRIS_UTILITY_ConvertFrom_d13C_d18O_d17O(wRefTrueValues_CO2, wRefTrueValues_d13C, wRefTrueValues_d18O, wRefTrueValues_d17O)
	
	// === CALCULATE DERIVED VARIABLES, PRE-CALIBRATION ===
	// NOTE: The names of the mole fraction waves imported from TDL Wintel have the format root:iXXX for isotopologues (e.g. root:i626, root:i638, root:i627_A) and simply root:XXX otherwise (e.g. root:CO2, root:N2O), except for OCS, which is root:xOCS for some reason.
	//       All variables in the IRIS_SCHEME_DefineVariables function that have type "str" or "stc" but are not imported from TDL Wintel must be created here.
	
	variable lamda_O17O18_slope = str2num(IRIS_UTILITY_GetParamValueFromName("Reference slope (λ)"))
	
	wave i626 = root:i626
	wave i636 = root:i636
	wave i627_A = root:i627_A
	wave i628 = root:i628
	
	duplicate/O i626, del13C, del17O, del18O, capDel17O
	del13C = 1000*((i636/i626) - 1) //permil (vs HITRAN, uncalibrated)
	del17O = 1000*((i627_A/i626) - 1) //permil (vs HITRAN, uncalibrated)
	del18O = 1000*((i628/i626) - 1) //permil (vs HITRAN, uncalibrated)	
	capDel17O = 1000*ln(del17O/1000 + 1) - lamda_O17O18_slope*1000*ln(del18O/1000 + 1)
	
	// === UNIVERSAL: CALCULATE THE MEAN AND STANDARD ERROR FOR EACH CELL FILL (do not modify) ===
	
	IRIS_UTILITY_CalculateGasFillMeansForAllVariables()
	
	// === FOR EACH SAMPLE GAS... ===
		
	for(sampleNum=0;sampleNum<numSampleGases;sampleNum+=1) 
		
		// === ...UNIVERSAL: CALIBRATE SAMPLE SPECIES/ISOTOPOLOGUE MEANS VIA THE REF GAS(ES) (do not modify) ===
		
		IRIS_UTILITY_CalibrateAllSampleVariablesViaRefs(sampleNum)
		
		// === ...CALCULATE DERIVED VARIABLES, POST-CALIBRATION ===
		// NOTE: The names of the calibrated mole fraction waves that you can use here have the format: root:X_cal, where X is the name of the corresponding wave imported from TDL Wintel (e.g. root:i626_cal or root:N2O_cal or root:xOCS_cal).
		//       All variables in the IRIS_SCHEME_DefineVariables function that have type "avg" but calibrateOrNot = 0 must be created here.
		
		wave i626_cal = root:i626_cal
		wave i636_cal = root:i636_cal
		wave i627_A_cal = root:i627_A_cal
		wave i628_cal = root:i628_cal
		
		duplicate/O i626_cal, d13C_VPDB_Avg, d17O_VSMOW_Avg, d18O_VSMOW_Avg, CO2_Avg, d17O_prime, d18O_prime, CapD17O
		[CO2_Avg, d13C_VPDB_Avg, d18O_VSMOW_Avg, d17O_VSMOW_Avg] = IRIS_UTILITY_ConvertTo_d13C_d18O_d17O(i626_cal, i636_cal, i628_cal, i627_A_cal)
		d17O_prime = 1000*ln(d17O_VSMOW_Avg/1000 + 1)
		d18O_prime = 1000*ln(d18O_VSMOW_Avg/1000 + 1)
		CapD17O = d17O_prime - lamda_O17O18_slope * d18O_prime // this is the small deviation from the 'conventional' bulk slope (Sharp et al.)
	
		// === ...UNIVERSAL: ASSIGN REMAINING RESULTS TO OUTPUT VARIABLES (do not modify) ===
		
		IRIS_UTILITY_AssignAllSpecialOutputVariables(sampleNum)
		
	endfor
	
	// === UNIVERSAL: WRAP-UP (do not modify) ===
	
	IRIS_UTILITY_AnalysisWrapUp()
	
	SetDataFolder $saveFolder
	return 0
	
End

Function IRIS_SCHEME_Analyze_D17O_d13C_CO2_CapeTown()
	
	IRIS_SCHEME_Analyze_D17O_d13C_CO2()
	
End

Function IRIS_SCHEME_Analyze_D17O_d13C_CO2_AnalysisOnly()
	
	IRIS_SCHEME_Analyze_D17O_d13C_CO2()
	
End

Function IRIS_SCHEME_Analyze_IceCore_d13C_CO2()
	
	// NOTE: "UNIVERSAL" sections must be included exactly as they are, exactly where they are.
	
	// === UNIVERSAL: SETUP (do not modify) ===
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	
	variable sampleNum, refNum
	
	string sIRIStemp
	
	string saveFolder = getdatafolder(1)
	SetDataFolder root:
	
	make/O/N=(numSampleGases) wSampleIndices
	make/O/N=(numRefGases) wRefIndices
	
	variable parseFlag = IRIS_UTILITY_AnalysisSetup()
	if(parseFlag == 1)
		SetDataFolder $saveFolder
		return 0
	endif
	
	// === COLLATE THE TRUE REF GAS INFO ===
	// NOTE: Whatever wave names you choose here will need to be used consistently afterward in this function.
	
	variable infoFlag = 0
	make/O/N=(numRefGases) wRefTrueValues_CO2, wRefTrueValues_d13C
	for(refNum=0;refNum<numRefGases;refNum+=1)
		
		sIRIStemp = "Reference " + num2str(refNum+1) + ": " + "CO2 Mole Fraction"
		wRefTrueValues_CO2[refNum] = str2num(IRIS_UTILITY_GetParamValueFromName(sIRIStemp)) // ppm
		infoFlag = (numtype(wRefTrueValues_CO2[refNum]) != 0) ? 1 : infoFlag
		
		sIRIStemp = "Reference " + num2str(refNum+1) + ": " + "δ13C"
		wRefTrueValues_d13C[refNum] = str2num(IRIS_UTILITY_GetParamValueFromName(sIRIStemp)) // permil VSMOW
		infoFlag = (numtype(wRefTrueValues_d13C[refNum]) != 0) ? 1 : infoFlag
		
	endfor
	
	if(infoFlag > 0)
		IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", secs2time(DateTime,3) + "  " + "*** WARNING: The info for working gas " + num2str(refNum+1) + " is invalid! ***")
	endif
	
	// === CONVERT TRUE REF GAS DELTAS AND TOTAL CO2 TO ISOTOPOLOGUE MOLE FRACTIONS ===
	// NOTE: You must name the ref gas true isotopologue waves in the format: wRefTrueValues_iXXX, where XXX is 626 or 628 or 627_A, etc. (iXXX must be an entry in wOutputVariableSourceDataNames[wIndicesOfVariablesToCalibrate[j]] for some j).
	
	make/O/D/N=(numRefGases) wRefTrueValues_i626, wRefTrueValues_i636
	[wRefTrueValues_i626, wRefTrueValues_i636] = IRIS_UTILITY_ConvertFrom_d13C(wRefTrueValues_CO2, wRefTrueValues_d13C)
	
	// === CALCULATE DERIVED VARIABLES, PRE-CALIBRATION ===
	// NOTE: The names of the mole fraction waves imported from TDL Wintel have the format root:iXXX for isotopologues (e.g. root:i626, root:i638, root:i627_A) and simply root:XXX otherwise (e.g. root:CO2, root:N2O), except for OCS, which is root:xOCS for some reason.
	//       All variables in the IRIS_SCHEME_DefineVariables function that have type "str" or "stc" but are not imported from TDL Wintel must be created here.
	
	wave i626 = root:i626
	wave i636 = root:i636
	
	duplicate/O i626, del13C
	del13C = 1000*((i636/i626) - 1) //permil (vs HITRAN, uncalibrated)
	
	// === UNIVERSAL: CALCULATE THE MEAN AND STANDARD ERROR FOR EACH CELL FILL (do not modify) ===
	
	IRIS_UTILITY_CalculateGasFillMeansForAllVariables()
	
	// === FOR EACH SAMPLE GAS... ===
		
	for(sampleNum=0;sampleNum<numSampleGases;sampleNum+=1) 
		
		// === ...UNIVERSAL: CALIBRATE SAMPLE SPECIES/ISOTOPOLOGUE MEANS VIA THE REF GAS(ES) (do not modify) ===
		
		IRIS_UTILITY_CalibrateAllSampleVariablesViaRefs(sampleNum)
		
		// === ...CALCULATE DERIVED VARIABLES, POST-CALIBRATION ===
		// NOTE: The names of the calibrated mole fraction waves that you can use here have the format: root:X_cal, where X is the name of the corresponding wave imported from TDL Wintel (e.g. root:i626_cal or root:N2O_cal or root:xOCS_cal).
		//       All variables in the IRIS_SCHEME_DefineVariables function that have type "avg" but calibrateOrNot = 0 must be created here.
		
		wave i626_cal = root:i626_cal
		wave i636_cal = root:i636_cal
		
		duplicate/O i626_cal, d13C_VPDB_Avg, CO2_Avg
		[CO2_Avg, d13C_VPDB_Avg] = IRIS_UTILITY_ConvertTo_d13C(i626_cal, i636_cal)
		
		// === ...UNIVERSAL: ASSIGN REMAINING RESULTS TO OUTPUT VARIABLES (do not modify) ===
		
		IRIS_UTILITY_AssignAllSpecialOutputVariables(sampleNum)
		
	endfor
	
	// === UNIVERSAL: WRAP-UP (do not modify) ===
	
	IRIS_UTILITY_AnalysisWrapUp()
	
	SetDataFolder $saveFolder
	return 0
	
End

Function IRIS_SCHEME_Analyze_IceCore_d13C_CO2_noVICI()
	IRIS_SCHEME_Analyze_IceCore_d13C_CO2()
End

Function IRIS_SCHEME_Analyze_D638_CO2()
	
	// NOTE: "UNIVERSAL" sections must be included exactly as they are, exactly where they are.
	
	// === UNIVERSAL: SETUP (do not modify) ===
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	
	variable sampleNum, refNum
	
	string sIRIStemp
	
	string saveFolder = getdatafolder(1)
	SetDataFolder root:
	
	make/O/N=(numSampleGases) wSampleIndices
	make/O/N=(numRefGases) wRefIndices
	
	variable parseFlag = IRIS_UTILITY_AnalysisSetup()
	if(parseFlag == 1)
		SetDataFolder $saveFolder
		return 0
	endif
	
	// === COLLATE THE TRUE REF GAS INFO ===
	// NOTE: Whatever wave names you choose here will need to be used consistently afterward in this function.
	
	variable infoFlag = 0
	make/O/N=(numRefGases) wRefTrueValues_CO2, wRefTrueValues_d13C, wRefTrueValues_d18O, wRefTrueValues_D638
	for(refNum=0;refNum<numRefGases;refNum+=1)
		
		sIRIStemp = "Reference " + num2str(refNum+1) + ": " + "CO2 Mole Fraction"
		wRefTrueValues_CO2[refNum] = str2num(IRIS_UTILITY_GetParamValueFromName(sIRIStemp)) // ppm
		infoFlag = (numtype(wRefTrueValues_CO2[refNum]) != 0) ? 1 : infoFlag
		
		sIRIStemp = "Reference " + num2str(refNum+1) + ": " + "δ13C"
		wRefTrueValues_d13C[refNum] = str2num(IRIS_UTILITY_GetParamValueFromName(sIRIStemp)) // permil VSMOW
		infoFlag = (numtype(wRefTrueValues_d13C[refNum]) != 0) ? 1 : infoFlag
		
		sIRIStemp = "Reference " + num2str(refNum+1) + ": " + "δ18O"
		wRefTrueValues_d18O[refNum] = str2num(IRIS_UTILITY_GetParamValueFromName(sIRIStemp)) // permil VSMOW
		infoFlag = (numtype(wRefTrueValues_d18O[refNum]) != 0) ? 1 : infoFlag
		
		sIRIStemp = "Reference " + num2str(refNum+1) + ": " + "Δ638"
		wRefTrueValues_D638[refNum] = str2num(IRIS_UTILITY_GetParamValueFromName(sIRIStemp)) // permil VSMOW
		infoFlag = (numtype(wRefTrueValues_D638[refNum]) != 0) ? 1 : infoFlag
		
	endfor
	
	if(infoFlag > 0)
		IRIS_UTILITY_AppendStringToNoteBook("IRISpanel#StatusNotebook", secs2time(DateTime,3) + "  " + "*** WARNING: The info for working gas " + num2str(refNum+1) + " is invalid! ***")
	endif
	
	// === CONVERT TRUE REF GAS DELTAS AND TOTAL CO2 TO ISOTOPOLOGUE MOLE FRACTIONS ===
	// NOTE: You must name the ref gas true isotopologue waves in the format: wRefTrueValues_iXXX, where XXX is 626 or 628 or 627_A, etc. (iXXX must be an entry in wOutputVariableSourceDataNames[wIndicesOfVariablesToCalibrate[j]] for some j).
	
	make/O/D/N=(numRefGases) wRefTrueValues_i626, wRefTrueValues_i636, wRefTrueValues_i628, wRefTrueValues_i638
	[wRefTrueValues_i626, wRefTrueValues_i636, wRefTrueValues_i628, wRefTrueValues_i638] = IRIS_UTILITY_ConvertFrom_d13C_d18O_D638(wRefTrueValues_CO2, wRefTrueValues_d13C, wRefTrueValues_d18O, wRefTrueValues_D638)
	
	// === CALCULATE DERIVED VARIABLES, PRE-CALIBRATION ===
	// NOTE: The names of the mole fraction waves imported from TDL Wintel have the format root:iXXX for isotopologues (e.g. root:i626, root:i638, root:i627_A) and simply root:XXX otherwise (e.g. root:CO2, root:N2O), except for OCS, which is root:xOCS for some reason.
	//       All variables in the IRIS_SCHEME_DefineVariables function that have type "str" or "stc" but are not imported from TDL Wintel must be created here.
	
	wave i626 = root:i626
	wave i636 = root:i636
	wave i628 = root:i628
	wave i638 = root:i638
	
	duplicate/O i626, del13C, del18O, Del638, iK_over_Khitran
	del13C = 1000*((i636/i626) - 1) //permil (vs HITRAN, uncalibrated)
	del18O = 1000*((i628/i626) - 1) //permil (vs HITRAN, uncalibrated)
	iK_over_Khitran = i636*i628/(i626*i638)
	Del638 = -1000*ln(iK_over_Khitran) //permil
	
	// === UNIVERSAL: CALCULATE THE MEAN AND STANDARD ERROR FOR EACH CELL FILL (do not modify) ===
	
	IRIS_UTILITY_CalculateGasFillMeansForAllVariables()
	
	// === FOR EACH SAMPLE GAS... ===
		
	for(sampleNum=0;sampleNum<numSampleGases;sampleNum+=1) 
		
		// === ...UNIVERSAL: CALIBRATE SAMPLE SPECIES/ISOTOPOLOGUE MEANS VIA THE REF GAS(ES) (do not modify) ===
		
		IRIS_UTILITY_CalibrateAllSampleVariablesViaRefs(sampleNum)
		
		// === ...CALCULATE DERIVED VARIABLES, POST-CALIBRATION ===
		// NOTE: The names of the calibrated mole fraction waves that you can use here have the format: root:X_cal, where X is the name of the corresponding wave imported from TDL Wintel (e.g. root:i626_cal or root:N2O_cal or root:xOCS_cal).
		//       All variables in the IRIS_SCHEME_DefineVariables function that have type "avg" but calibrateOrNot = 0 must be created here.
		
		wave i626_cal = root:i626_cal
		wave i636_cal = root:i636_cal
		wave i628_cal = root:i628_cal
		wave i638_cal = root:i638_cal
		
		duplicate/O i626_cal, d13C_VPDB_Avg, d18O_VSMOW_Avg, CO2_Avg, D638
		[CO2_Avg, d13C_VPDB_Avg, d18O_VSMOW_Avg, D638] = IRIS_UTILITY_ConvertTo_d13C_d18O_D638(i626_cal, i636_cal, i628_cal, i638_cal)
		
		// === ...UNIVERSAL: ASSIGN REMAINING RESULTS TO OUTPUT VARIABLES (do not modify) ===
		
		IRIS_UTILITY_AssignAllSpecialOutputVariables(sampleNum)
		
	endfor
	
	// === UNIVERSAL: WRAP-UP (do not modify) ===
	
	IRIS_UTILITY_AnalysisWrapUp()
	
	SetDataFolder $saveFolder
	return 0
	
End

///////////////////////////////////////////////////////
// Bestiary of Specific Instruments by Serial Number //
///////////////////////////////////////////////////////

// CS139 (UNM D17O-CO2)
Function IRIS_BESTIARY_CS139()
	string/G sInstrumentType = "D17O_CO2_Bellows"
End

// CS149 (Houston D17O-CO2)
Function IRIS_BESTIARY_CS149()
	string/G sInstrumentType = "D17O_CO2"
End

// CS133 (BAS Ice Core d13C-CO2)
Function IRIS_BESTIARY_CS133()
//	string/G sInstrumentType = "IceCore_d13C_CO2"
	string/G sInstrumentType = "IceCore_d13C_CO2_noVICI"
End

// FD117 (Cape Town 13C/18O/17O-CO2)
Function IRIS_BESTIARY_FD117()
	string/G sInstrumentType = "D17O_d13C_CO2_CapeTown"
End

// FD125 (KIT CO2 Clumped Isotope)
Function IRIS_BESTIARY_FD125()
	string/G sInstrumentType = "D638_CO2"
End

// FD136 (Cambridge CO2 Isotope)
Function IRIS_BESTIARY_FD136()
	string/G sInstrumentType = "D17O_d13C_CO2"
//	string/G sInstrumentType = "D17O_d13C_CO2_AnalysisOnly"
End

// FD140 (LBL CO2 Isotope)
Function IRIS_BESTIARY_FD140()
	string/G sInstrumentType = "D17O_d13C_CO2"
End

// FD143 (Yale CO2 Isotope)
Function IRIS_BESTIARY_FD143()
	string/G sInstrumentType = "D17O_d13C_CO2"
End

#ENDIF