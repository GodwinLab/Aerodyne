#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#IF(IgorVersion() >= 8.00) // IRIS's code does not work properly on Igor Pro versions earlier than Igor Pro 8

//////////////////////////////
// Create Menu Bar Launcher //
//////////////////////////////

Menu "Macros"
	"IRIS (Interface for Runs of Interleaved Samples)", IRIS()
	"------------------", Execute("")
End

// Need flexible GUI, with new display region...
// Status
// Mixer Flask 1 (Ready for CO2, Filling with CO2, Filling with Balance Gas, Mixing, Waiting for Switcher, Flushing Lines, Open to Switcher)
// Mixer Flask 2 (Ready for CO2, Filling with CO2, Filling with Balance Gas, Mixing, Waiting for Switcher, Flushing Lines, Open to Switcher)
// Switcher (Waiting for Optical Cell, Waiting for Mixer, Filling Int. Vol. with Sample, Filling Int. Vol. with Ref, Transfering to Cell)
// Optical Cell (Measuring, Waiting for Switcher, Evacuating, Flushing, Filling) 
// ...with buttons to "Fill CO2" for the two flasks.
// Or have 4 flexible status text fields, which could be used for anything but I expect to populate with things
// like: TILDAS: measuring sample, SWITCHER: Filling int. vol. with ref, MIXER FLASK 1: mixing, and
// MIXER FLASK 2: evacuating.
// Then have the RUN button change to RESUME when waiting for the user.
// I also want a prominent user prompt text field though. Maybe that could take over the others?

// Put SHOW DIAGNOSTICS button at bottom and add a SHOW STATUS LOG there too.

// With conditional events and multiple queues, I can have a queue for Mixer Flask 1, a queue for
// Mixer Flask 2, and a queue for the switcher (and maybe a separate queue for the spectrometer with
// stuff like the wd toggling), plus a main queue and a reset queue.

// A queue can end with a conditional event that will reactivate itself or activate another script only if
// the number of completed cycles is less than max and time is less than timeout. And queues can start
// with a waitForCondition event so that they only really start if conditions are right (e.g. cell is done
// measuring).

///////////////////
// Main Function //
///////////////////

//Function IRIS_UTILITY_AppendEventToQueue(sQueueName, sAction, [sArgument1, sArgument2, sArgument3, sArgument4, sArgument5])
//	string sQueueName, sAction, sArgument1, sArgument2, sArgument3, sArgument4, sArgument5
//	
//	string sWaveName_Action
//	string sWaveName_Argument
//	string sWaveName_Comment
//	
//	sWaveName_WhichTimer = "wQueue_" + sQueueName + "_WhichTimer"
//	sWaveName_TriggerTime = "wQueue_" + sQueueName + "_TriggerTime"
//	sWaveName_Action = "wQueue_" + sQueueName + "_Action"
//	sWaveName_Argument = "wQueue_" + sQueueName + "_Argument"
//	sWaveName_Comment = "wQueue_" + sQueueName + "_Comment"
//	
//	make/O/N=1 wTemp_WhichTimer = whichTimer
//	make/O/D/N=1 wTemp_TriggerTime = triggerTime
//	make/O/T/N=1 wTemp_Action = sAction
//	make/O/T/N=1 wTemp_Argument = sArgument
//	make/O/T/N=1 wTemp_Comment = sComment
//	
//	// Concatenate will create the destination wave if it does not exist, or append to it otherwise
//	Concatenate/NP {wTemp_WhichTimer}, $sWaveName_WhichTimer
//	Concatenate/NP {wTemp_TriggerTime}, $sWaveName_TriggerTime
//	Concatenate/T/NP {wTemp_Action}, $sWaveName_Action
//	Concatenate/T/NP {wTemp_Argument}, $sWaveName_Argument
//	Concatenate/T/NP {wTemp_Comment}, $sWaveName_Comment
//		
//	killwaves wTemp_WhichTimer
//	killwaves wTemp_TriggerTime
//	killwaves wTemp_Action
//	killwaves wTemp_Argument
//	killwaves wTemp_Comment
//		
//End

// want this to be able to accept two variables or a variable and a literal number
Function IRIS_EVENT_IfTrueDoThisElseDoThat( conditionString, trueEventType, trueEventArgument, falseEventType, falseEventArgument ) // event type, event argument, conditional statement as string
	string conditionString, trueEventType, trueEventArgument, falseEventType, falseEventArgument
	
	if(IRIS_UTILITY_EvaluateConditionString( conditionString ) == 1)
		
		
		
	else
		
		
		
	endif
	
End

Function IRIS_UTILITY_EvaluateConditionString( conditionString )
	string conditionString
	
	// NOTE: This function returns 0 (false) if the conditionString is invalid.
	
//	// OLD METHOD
//	string firstVariableName, relationship, secondVariableName
//	firstVariableName = StringFromList( 0, conditionString, " " )
//	relationship = StringFromList( 1, conditionString, " " )
//	secondVariableName = StringFromList( 2, conditionString, " " )
	
	string firstVariableName, space1, relationship, space2, secondVariableName
	
	string regexString = "([[:alnum:]]+)([[:blank:]]*)(<|>|<=|>=|==|=)([[:blank:]]*)([[:alnum:]]+)"
	SplitString/E=regexString conditionString, firstVariableName, space1, relationship, space2, secondVariableName
	
	NVAR/Z var1 = root:$firstVariableName
	NVAR/Z var2 = root:$secondVariableName
	
	if( (!NVAR_Exists(var1)) || (!NVAR_Exists(var2)) )
		return 0
	endif
	
	if((cmpstr(relationship, "=") == 0) || (cmpstr(relationship, "==") == 0))
		if(var1 == var2)
			return 1
		else
			return 0
		endif
	elseif(cmpstr(relationship, "<") == 0)
		if(var1 < var2)
			return 1
		else
			return 0
		endif
	elseif(cmpstr(relationship, ">") == 0)
		if(var1 > var2)
			return 1
		else
			return 0
		endif
	elseif(cmpstr(relationship, "<=") == 0)
		if(var1 <= var2)
			return 1
		else
			return 0
		endif
	elseif(cmpstr(relationship, ">=") == 0)
		if(var1 >= var2)
			return 1
		else
			return 0
		endif
	endif
	
End

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
	
	// Set paths on disk...
	string sIRISpath
	string/G sResultsPath
	string/G sDataPathOnDisk
	string/G sDataPathOnDisk_Original
	if(developmentMode == 1)
		// Path for .iris configuration file
		sIRISpath = 	"Macintosh HD:Users:Rick:Professional:Aerodyne:Software Development:IRIS"
		// Path for saving results files
		sResultsPath = 	sIRISpath
		// Path for .str and .stc data files
		sDataPathOnDisk = "Macintosh HD:Users:Rick:Professional:Aerodyne:Software Development:IRIS"
	else
		// Path for .iris configuration file
		sIRISpath = "C:IRIS"
		// Path for saving results files
		sResultsPath = sIRISpath
		// Path for .str and .stc data files
		sDataPathOnDisk = "C:TDLWintel:Data"
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
	variable/G IRIS_WaitingForUser1 = 0
	variable/G IRIS_WaitingForUser2 = 0
	variable/G IRIS_WaitingForUser3 = 0
	variable/G scheduleIndex = 0
	variable/G cycleNumber = 0
	variable/G azaInProgress = 0
	variable/G azaValveHasTriggered = 0
	variable/G azaValve
//	variable/G azaInitialValveState
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
	variable/G output1_gasID = 0
	variable/G output2_gasID = 0
	variable/G output3_gasID = 0
	variable/G output1_variableID = 0
	variable/G output2_variableID = 0
	variable/G output3_variableID = 0
	variable/G layoutPageWidth = 850
	variable/G layoutPageHeight = layoutPageWidth*(11/8.5)
	variable/G minPointsForOutlierFiltering = 5
	variable/G MADsPerSD = 1.4826
	variable/G numOutputVariables = 1
	variable/G numSampleGases = 1
	variable/G numRefGases = 1
	variable/G numGases = 2
	variable/G numSampleGases_prev = numSampleGases
	variable/G numRefGases_prev = numRefGases
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
	variable/G paramIndexCount = 0
	
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
	make/O/T/N=3 wStatusStrings = " "
	make/O/T/N=3 wStatusCategoryNames
	
	//	38, 125, 255
	//	237, 35, 13
	//	255, 148, 0
	//	30, 177, 0
	//	160, 0, 157
	//	28, 53, 179
	//	176, 219, 58
	//	255, 142, 198
	//	30, 229, 206
	//	202, 42, 122
	//	5, 168, 157
	//	214, 184, 11
	make/O/N=(12,3) wSampleColorPalette
	wSampleColorPalette[0][0] = 16385
	wSampleColorPalette[0][1] = 28398
	wSampleColorPalette[0][2] = 65535
	wSampleColorPalette[1][0] = 60909
	wSampleColorPalette[1][1] = 8995
	wSampleColorPalette[1][2] = 3341
	wSampleColorPalette[2][0] = 65535
	wSampleColorPalette[2][1] = 38036
	wSampleColorPalette[2][2] = 0
	wSampleColorPalette[3][0] = 7710
	wSampleColorPalette[3][1] = 45489
	wSampleColorPalette[3][2] = 0
	wSampleColorPalette[4][0] = 41120
	wSampleColorPalette[4][1] = 0
	wSampleColorPalette[4][2] = 40349
	wSampleColorPalette[5][0] = 7196
	wSampleColorPalette[5][1] = 13621
	wSampleColorPalette[5][2] = 46003
	wSampleColorPalette[6][0] = 45232
	wSampleColorPalette[6][1] = 56283
	wSampleColorPalette[6][2] = 14906
	wSampleColorPalette[7][0] = 65535
	wSampleColorPalette[7][1] = 36494
	wSampleColorPalette[7][2] = 50886
	wSampleColorPalette[8][0] = 7710
	wSampleColorPalette[8][1] = 58853
	wSampleColorPalette[8][2] = 52942
	wSampleColorPalette[9][0] = 51914
	wSampleColorPalette[9][1] = 10794
	wSampleColorPalette[9][2] = 31354
	wSampleColorPalette[10][0] = 1285
	wSampleColorPalette[10][1] = 43176
	wSampleColorPalette[10][2] = 40349
	wSampleColorPalette[11][0] = 54998
	wSampleColorPalette[11][1] = 47288
	wSampleColorPalette[11][2] = 2827
	
	//	168, 133, 98
	//	113, 82, 53
	//	200, 165, 133
	//	92, 66, 41
	make/O/N=(4,3) wRefColorPalette
	wRefColorPalette[0][0] = 43176
	wRefColorPalette[0][1] = 34181
	wRefColorPalette[0][2] = 25186
	wRefColorPalette[1][0] = 29041
	wRefColorPalette[1][1] = 21074
	wRefColorPalette[1][2] = 13621
	wRefColorPalette[2][0] = 51400
	wRefColorPalette[2][1] = 42405
	wRefColorPalette[2][2] = 34181
	wRefColorPalette[3][0] = 23644
	wRefColorPalette[3][1] = 16962
	wRefColorPalette[3][2] = 10537
	
	//	119, 119, 119
	make/O/N=3 wSecondPlotColor = {30583,30583,30583}
	
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
		
		variable configMatch = 1
		
		// Get the config parameter definitions from the .iris config file (crucially, this also gets the numbers of sample and reference gases)...
		IRIS_UTILITY_LoadConfig()
		wave/T wtParamNames, wtParamValues, wtParamUnits, wtParamTypes
		
		// Populate wtParamTypes with empty strings if the .iris file is from a version of IRIS before wtParamTypes was introduced
		if(numpnts(wtParamTypes) == 0)
			redimension/N=(numpnts(wtParamNames)) wtParamTypes
		endif
		
		// Make a copy of the parameter definitions from the .iris file...
		Duplicate/O/T wtParamNames, wtParamNames_inFile
		Duplicate/O/T wtParamValues, wtParamValues_inFile
		Duplicate/O/T wtParamUnits, wtParamUnits_inFile
		Duplicate/O/T wtParamTypes, wtParamTypes_inFile
		
		// Get the config parameter definitions from the instrument .ipf file (overwriting, and using the numbers of sample and ref gases that were loaded from the .iris file)...
		FUNCREF IRIS_UTILITY_ProtoFunc IRIS_ParamFunction = $sParamFunctionName
		IRIS_UTILITY_DefineParamsPrep()
		IRIS_ParamFunction() // calls IRIS_SCHEME_DefineParams_XXXXX(), where XXXXX is the instrument type
		IRIS_UTILITY_DefineParamsWrapUp()
		
		// Compare the two sets of config parameter definitions...
		if(numpnts(wtParamNames) != numpnts(wtParamNames_inFile))
			configMatch = 0
			print num2str(numpnts(wtParamNames)) + " =/= " + num2str(numpnts(wtParamNames_inFile))
		else
			for(i=0;i<numpnts(wtParamNames);i+=1)
				if((cmpStr(wtParamNames[i], wtParamNames_inFile[i]) != 0) || (cmpStr(wtParamUnits[i], wtParamUnits_inFile[i]) != 0) || (cmpStr(wtParamTypes[i], wtParamTypes_inFile[i]) != 0)) // values don't have to match, of course
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
			
			// Prompt user for permission to proceed...
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
				sWaveListStr = "wtParamNames;wtParamValues;wtParamUnits;wtParamTypes;"
				Save/O/J/DLIM=","/B/P=pIRISpath sWaveListStr as sConfigFileName
				print "Recreated configuration file: " + sConfigFileName
				
				// Propagate the new config params to the GUI tables
				IRIS_UTILITY_PropagateParamsToTables()
	
				killwaves wtParamNames_inFile, wtParamValues_inFile, wtParamUnits_inFile, wtParamTypes_inFile
				
			else
				return 1
			endif
			
		else
			
			// Restore parameters from the .iris config file, to get their saved values...
			Duplicate/O/T wtParamNames_inFile, wtParamNames
			Duplicate/O/T wtParamValues_inFile, wtParamValues
			Duplicate/O/T wtParamUnits_inFile, wtParamUnits
			Duplicate/O/T wtParamTypes_inFile, wtParamTypes
			
			// Propagate the new config params to the GUI tables
			IRIS_UTILITY_PropagateParamsToTables()
			
		endif
		
		killwaves wtParamNames_inFile, wtParamValues_inFile, wtParamUnits_inFile, wtParamTypes_inFile
		
	else // assign default config params, and create .iris file 
		
		FUNCREF IRIS_UTILITY_ProtoFunc IRIS_ParamFunction = $sParamFunctionName
		IRIS_UTILITY_DefineParamsPrep()
		IRIS_ParamFunction() // calls IRIS_SCHEME_DefineParams_XXXXX(), where XXXXX is the instrument type
		IRIS_UTILITY_DefineParamsWrapUp()
		sWaveListStr = "wtParamNames;wtParamValues;wtParamUnits;wtParamTypes;"
		Save/J/DLIM=","/B/P=pIRISpath sWaveListStr as sConfigFileName
		print "Created configuration file: " + sConfigFileName
		
	endif
	
	// Update numSampleGases_prev and numRefGases_prev, which are used to check for GUI- or BuildSchedule-induced changes in numSampleGases or numRefGases
	numSampleGases_prev = numSampleGases
	numRefGases_prev = numRefGases

	// Create generic labels for the sample and reference gases to be measured 
	numGases = numSampleGases + numRefGases
	make/O/N=(numGases) wNumCompleteMeasurementsByGas = 0 // temporary value // the +3 is for all, all samples, and all refs
	make/O/T/N=(numGases + 3) wtOutputGasNames // the +3 is for all, all samples, and all refs
	wtOutputGasNames[0] = "ALL"
	wtOutputGasNames[1] = "ALL S"
	wtOutputGasNames[2] = "ALL R"
	for(i=0;i<numSampleGases;i+=1)
		wtOutputGasNames[i+3] = "S" + num2str(i+1)
	endfor
	for(i=0;i<numRefGases;i+=1)
		wtOutputGasNames[numSampleGases+i+3] = "R" + num2str(i+1)
	endfor
	
	// Create waves of means, standard deviations, and standard errors of the output variables, for the numeric displays
	make/O/D/N=(numGases,numOutputVariables) wOutputMeans, wOutputStDevs, wOutputStErrs
	wOutputMeans[][] = NaN
	wOutputStDevs[][] = NaN
	wOutputStErrs[][] = NaN
	
	// Create waves of means, standard deviations, and standard errors of the output variables for groups of gases (0 = all gases, 1 = all sample gases, 2 = all ref gases)
	make/O/D/N=(3,numOutputVariables) wGroupOutputMeans, wGroupOutputStDevs, wGroupOutputStErrs
	wGroupOutputMeans[][] = NaN
	wGroupOutputStDevs[][] = NaN
	wGroupOutputStErrs[][] = NaN
	
	// Create matrix of time series of output variables
	variable numAliquots = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Aliquots per Sample"))
	if(numType(numAliquots) != 0) // in case DefineParams function does not specify Number of Aliquots per Sample
		numAliquots = 1
	endif
	variable numCycles = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Cycles"))
	if(numType(numCycles) != 0) // in case DefineParams function does not specify Number of Cycles
		numCycles = 1
	endif
	make/O/D/N=(numGases,numOutputVariables,numAliquots*numCycles) wOutputTimeSeriesMatrix, wOutputTimeSeriesErrorMatrix, wOutputTimeSeriesFilterMatrix
	make/O/D/N=(numGases,numAliquots*numCycles) wOutputTime
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
	make/O/D/N=(numAliquots*numCycles) wOutputMeanToGraph1, wOutputErrorToGraph1, wOutputFilterToGraph1, wOutputTimeToGraph1
	make/O/D/N=(numAliquots*numCycles) wOutputMeanToGraph2, wOutputErrorToGraph2, wOutputFilterToGraph2, wOutputTimeToGraph2
	make/O/N=((numAliquots*numCycles),3) wOutputColorToGraph1
	wOutputColorToGraph1[][] = 0
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
	wNumCompleteMeasurementsByGas = numAliquots*numCycles
	
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
	
	wave wSampleColorPalette = root:wSampleColorPalette
	wave wRefColorPalette = root:wRefColorPalette
	wave wSecondPlotColor = root:wSecondPlotColor
	
	variable i
	
	sDataPathOnDisk = sDataPathOnDisk_Original
	
	wave/T wtParamNames = root:wtParamNames
	wave/T wtParamValues = root:wtParamValues
	wave/T wtParamUnits = root:wtParamUnits
	wave/T wtParamTypes = root:wtParamTypes
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
	variable numAliquots = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Aliquots per Sample"))
	if(numType(numAliquots) != 0) // in case DefineParams function does not specify Number of Aliquots per Sample
		numAliquots = 1
	endif
	variable numCycles = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Cycles"))
	if(numType(numCycles) != 0) // in case DefineParams function does not specify Number of Cycles
		numCycles = 1
	endif
	make/O/D/N=(numGases,numOutputVariables,numAliquots*numCycles) wOutputTimeSeriesMatrix, wOutputTimeSeriesErrorMatrix, wOutputTimeSeriesFilterMatrix
	make/O/D/N=(numGases,numAliquots*numCycles) wOutputTime
	make/O/D/N=(numAliquots*numCycles) wOutputMeanToGraph1, wOutputErrorToGraph1, wOutputFilterToGraph1, wOutputTimeToGraph1
	make/O/D/N=(numAliquots*numCycles) wOutputMeanToGraph2, wOutputErrorToGraph2, wOutputFilterToGraph2, wOutputTimeToGraph2
	make/O/N=((numAliquots*numCycles),3) wOutputColorToGraph1
	wOutputColorToGraph1[][] = 0
	wOutputTimeSeriesMatrix[][][] = NaN
	wOutputTimeSeriesErrorMatrix[][][] = NaN
	wOutputTimeSeriesFilterMatrix[][][] = 0
	wOutputTime = q + 1
	variable windowCheck = WinType("IRISpanel#ResultGraph")
	if(windowCheck == 1)
		SetAxis/W=IRISpanel#ResultGraph/A
	endif
	
	// Set which variable to graph...
	if((gasToGraph1 > 2) && (gasToGraph1 < numSampleGases + 3)) // individual sample gas
	
		wOutputMeanToGraph1 = wOutputTimeSeriesMatrix[gasToGraph1][variableToGraph1][p]
		wOutputErrorToGraph1 = wOutputTimeSeriesErrorMatrix[gasToGraph1][variableToGraph1][p]
		wOutputFilterToGraph1 = (wOutputTimeSeriesFilterMatrix[gasToGraph1][variableToGraph1][p] == 0) ? 19 : 8
		wOutputTimeToGraph1 = wOutputTime[gasToGraph1][p]
		wOutputColorToGraph1[][0] = wSampleColorPalette[mod(gasToGraph1-3,12)][0]
		wOutputColorToGraph1[][1] = wSampleColorPalette[mod(gasToGraph1-3,12)][1]
		wOutputColorToGraph1[][2] = wSampleColorPalette[mod(gasToGraph1-3,12)][2]
		
	elseif(gasToGraph1 > numSampleGases + 2) // individual ref gas
	
		wOutputMeanToGraph1 = wOutputTimeSeriesMatrix[gasToGraph1][variableToGraph1][p]
		wOutputErrorToGraph1 = wOutputTimeSeriesErrorMatrix[gasToGraph1][variableToGraph1][p]
		wOutputFilterToGraph1 = (wOutputTimeSeriesFilterMatrix[gasToGraph1][variableToGraph1][p] == 0) ? 19 : 8
		wOutputTimeToGraph1 = wOutputTime[gasToGraph1][p]
		wOutputColorToGraph1[][0] = wRefColorPalette[mod(gasToGraph1-3-numSampleGases,12)][0]
		wOutputColorToGraph1[][1] = wRefColorPalette[mod(gasToGraph1-3-numSampleGases,12)][1]
		wOutputColorToGraph1[][2] = wRefColorPalette[mod(gasToGraph1-3-numSampleGases,12)][2]
		
	elseif(gasToGraph1 == 0) // all gases
		
		wOutputMeanToGraph1 = wOutputTimeSeriesMatrix[0][variableToGraph1][p]
		wOutputErrorToGraph1 = wOutputTimeSeriesErrorMatrix[0][variableToGraph1][p]
		wOutputFilterToGraph1 = (wOutputTimeSeriesFilterMatrix[0][variableToGraph1][p] == 0) ? 19 : 8
		wOutputTimeToGraph1 = wOutputTime[0][p]
		wOutputColorToGraph1[][0] = wSampleColorPalette[0][0]
		wOutputColorToGraph1[][1] = wSampleColorPalette[0][1]
		wOutputColorToGraph1[][2] = wSampleColorPalette[0][2]
		
		duplicate/O wOutputMeanToGraph1, wMeanTemp
		duplicate/O wOutputErrorToGraph1, wErrorTemp
		duplicate/O wOutputFilterToGraph1, wFilterTemp
		duplicate/O wOutputTimeToGraph1, wTimeTemp
		duplicate/O wOutputColorToGraph1, wColorTemp
		
		if(numGases > 1)
			for(i=1;i<numSampleGases;i+=1)
				
				wMeanTemp = wOutputTimeSeriesMatrix[i][variableToGraph1][p]
				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][variableToGraph1][p]
				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][variableToGraph1][p] == 0) ? 19 : 8
				wTimeTemp = wOutputTime[i][p]
				wColorTemp[][0] = wSampleColorPalette[mod(i,12)][0]
				wColorTemp[][1] = wSampleColorPalette[mod(i,12)][1]
				wColorTemp[][2] = wSampleColorPalette[mod(i,12)][2]
				
				concatenate/NP {wMeanTemp}, wOutputMeanToGraph1
				concatenate/NP {wErrorTemp}, wOutputErrorToGraph1
				concatenate/NP {wFilterTemp}, wOutputFilterToGraph1
				concatenate/NP {wTimeTemp}, wOutputTimeToGraph1
				concatenate/NP=0 {wColorTemp}, wOutputColorToGraph1
				
			endfor
			
			for(i=numSampleGases;i<numGases;i+=1)
				
				wMeanTemp = wOutputTimeSeriesMatrix[i][variableToGraph1][p]
				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][variableToGraph1][p]
				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][variableToGraph1][p] == 0) ? 19 : 8
				wTimeTemp = wOutputTime[i][p]
				wColorTemp[][0] = wRefColorPalette[mod(i-numSampleGases,4)][0]
				wColorTemp[][1] = wRefColorPalette[mod(i-numSampleGases,4)][1]
				wColorTemp[][2] = wRefColorPalette[mod(i-numSampleGases,4)][2]
				
				concatenate/NP {wMeanTemp}, wOutputMeanToGraph1
				concatenate/NP {wErrorTemp}, wOutputErrorToGraph1
				concatenate/NP {wFilterTemp}, wOutputFilterToGraph1
				concatenate/NP {wTimeTemp}, wOutputTimeToGraph1
				concatenate/NP=0 {wColorTemp}, wOutputColorToGraph1
				
			endfor
		endif
		
		killwaves wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp, wColorTemp
		
	elseif(gasToGraph1 == 1) // all samples
		
		wOutputMeanToGraph1 = wOutputTimeSeriesMatrix[0][variableToGraph1][p]
		wOutputErrorToGraph1 = wOutputTimeSeriesErrorMatrix[0][variableToGraph1][p]
		wOutputFilterToGraph1 = (wOutputTimeSeriesFilterMatrix[0][variableToGraph1][p] == 0) ? 19 : 8
		wOutputTimeToGraph1 = wOutputTime[0][p]
		wOutputColorToGraph1[][0] = wSampleColorPalette[0][0]
		wOutputColorToGraph1[][1] = wSampleColorPalette[0][1]
		wOutputColorToGraph1[][2] = wSampleColorPalette[0][2]
		
		duplicate/O wOutputMeanToGraph1, wMeanTemp
		duplicate/O wOutputErrorToGraph1, wErrorTemp
		duplicate/O wOutputFilterToGraph1, wFilterTemp
		duplicate/O wOutputTimeToGraph1, wTimeTemp
		duplicate/O wOutputColorToGraph1, wColorTemp
		
		if(numSampleGases > 1)
			for(i=1;i<numSampleGases;i+=1)
				
				wMeanTemp = wOutputTimeSeriesMatrix[i][variableToGraph1][p]
				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][variableToGraph1][p]
				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][variableToGraph1][p] == 0) ? 19 : 8
				wTimeTemp = wOutputTime[i][p]
				wColorTemp[][0] = wSampleColorPalette[mod(i,12)][0]
				wColorTemp[][1] = wSampleColorPalette[mod(i,12)][1]
				wColorTemp[][2] = wSampleColorPalette[mod(i,12)][2]
				
				concatenate/NP {wMeanTemp}, wOutputMeanToGraph1
				concatenate/NP {wErrorTemp}, wOutputErrorToGraph1
				concatenate/NP {wFilterTemp}, wOutputFilterToGraph1
				concatenate/NP {wTimeTemp}, wOutputTimeToGraph1
				concatenate/NP=0 {wColorTemp}, wOutputColorToGraph1
				
			endfor
		endif
		
		killwaves wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp, wColorTemp
		
	elseif(gasToGraph1 == 2) // all refs
		
		wOutputMeanToGraph1 = wOutputTimeSeriesMatrix[numSampleGases][variableToGraph1][p]
		wOutputErrorToGraph1 = wOutputTimeSeriesErrorMatrix[numSampleGases][variableToGraph1][p]
		wOutputFilterToGraph1 = (wOutputTimeSeriesFilterMatrix[numSampleGases][variableToGraph1][p] == 0) ? 19 : 8
		wOutputTimeToGraph1 = wOutputTime[numSampleGases][p]
		wOutputColorToGraph1[][0] = wRefColorPalette[0][0]
		wOutputColorToGraph1[][1] = wRefColorPalette[0][1]
		wOutputColorToGraph1[][2] = wRefColorPalette[0][2]
		
		duplicate/O wOutputMeanToGraph1, wMeanTemp
		duplicate/O wOutputErrorToGraph1, wErrorTemp
		duplicate/O wOutputFilterToGraph1, wFilterTemp
		duplicate/O wOutputTimeToGraph1, wTimeTemp
		duplicate/O wOutputColorToGraph1, wColorTemp
		
		if(numRefGases > 1)
			for(i=(numSampleGases+1);i<numGases;i+=1)
				
				wMeanTemp = wOutputTimeSeriesMatrix[i][variableToGraph1][p]
				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][variableToGraph1][p]
				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][variableToGraph1][p] == 0) ? 19 : 8
				wTimeTemp = wOutputTime[i][p]
				wColorTemp[][0] = wRefColorPalette[mod(i-numSampleGases,4)][0]
				wColorTemp[][1] = wRefColorPalette[mod(i-numSampleGases,4)][1]
				wColorTemp[][2] = wRefColorPalette[mod(i-numSampleGases,4)][2]
				
				concatenate/NP {wMeanTemp}, wOutputMeanToGraph1
				concatenate/NP {wErrorTemp}, wOutputErrorToGraph1
				concatenate/NP {wFilterTemp}, wOutputFilterToGraph1
				concatenate/NP {wTimeTemp}, wOutputTimeToGraph1
				concatenate/NP=0 {wColorTemp}, wOutputColorToGraph1
				
			endfor
		endif
		
		killwaves wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp, wColorTemp
		
	endif
	
	if(gasToGraph2 > 2) // individual sample or ref gas
	
		wOutputMeanToGraph2 = wOutputTimeSeriesMatrix[gasToGraph2][variableToGraph2][p]
		wOutputErrorToGraph2 = wOutputTimeSeriesErrorMatrix[gasToGraph2][variableToGraph2][p]
		wOutputFilterToGraph2 = (wOutputTimeSeriesFilterMatrix[gasToGraph2][variableToGraph2][p] == 0) ? 16 : 8
		wOutputTimeToGraph2 = wOutputTime[gasToGraph2][p]
		
	elseif(gasToGraph2 == 0) // all gases
		
		wOutputMeanToGraph2 = wOutputTimeSeriesMatrix[0][variableToGraph2][p]
		wOutputErrorToGraph2 = wOutputTimeSeriesErrorMatrix[0][variableToGraph2][p]
		wOutputFilterToGraph2 = (wOutputTimeSeriesFilterMatrix[0][variableToGraph2][p] == 0) ? 16 : 8
		wOutputTimeToGraph2 = wOutputTime[0][p]
		
		duplicate/O wOutputMeanToGraph2, wMeanTemp
		duplicate/O wOutputErrorToGraph2, wErrorTemp
		duplicate/O wOutputFilterToGraph2, wFilterTemp
		duplicate/O wOutputTimeToGraph2, wTimeTemp
		
		if(numGases > 1)
			for(i=1;i<numGases;i+=1)
				
				wMeanTemp = wOutputTimeSeriesMatrix[i][variableToGraph2][p]
				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][variableToGraph2][p]
				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][variableToGraph2][p] == 0) ? 16 : 8
				wTimeTemp = wOutputTime[i][p]
				
				concatenate/NP {wMeanTemp}, wOutputMeanToGraph2
				concatenate/NP {wErrorTemp}, wOutputErrorToGraph2
				concatenate/NP {wFilterTemp}, wOutputFilterToGraph2
				concatenate/NP {wTimeTemp}, wOutputTimeToGraph2
				
			endfor
		endif
		
		killwaves wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp
		
	elseif(gasToGraph2 == 1) // all samples
		
		wOutputMeanToGraph2 = wOutputTimeSeriesMatrix[0][variableToGraph2][p]
		wOutputErrorToGraph2 = wOutputTimeSeriesErrorMatrix[0][variableToGraph2][p]
		wOutputFilterToGraph2 = (wOutputTimeSeriesFilterMatrix[0][variableToGraph2][p] == 0) ? 16 : 8
		wOutputTimeToGraph2 = wOutputTime[0][p]
		
		duplicate/O wOutputMeanToGraph2, wMeanTemp
		duplicate/O wOutputErrorToGraph2, wErrorTemp
		duplicate/O wOutputFilterToGraph2, wFilterTemp
		duplicate/O wOutputTimeToGraph2, wTimeTemp
		
		if(numSampleGases > 1)
			for(i=1;i<numSampleGases;i+=1)
				
				wMeanTemp = wOutputTimeSeriesMatrix[i][variableToGraph2][p]
				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][variableToGraph2][p]
				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][variableToGraph2][p] == 0) ? 16 : 8
				wTimeTemp = wOutputTime[i][p]
				
				concatenate/NP {wMeanTemp}, wOutputMeanToGraph2
				concatenate/NP {wErrorTemp}, wOutputErrorToGraph2
				concatenate/NP {wFilterTemp}, wOutputFilterToGraph2
				concatenate/NP {wTimeTemp}, wOutputTimeToGraph2
				
			endfor
		endif
		
		killwaves wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp
		
	elseif(gasToGraph2 == 2) // all refs
		
		wOutputMeanToGraph2 = wOutputTimeSeriesMatrix[numSampleGases][variableToGraph2][p]
		wOutputErrorToGraph2 = wOutputTimeSeriesErrorMatrix[numSampleGases][variableToGraph2][p]
		wOutputFilterToGraph2 = (wOutputTimeSeriesFilterMatrix[numSampleGases][variableToGraph2][p] == 0) ? 16 : 8
		wOutputTimeToGraph2 = wOutputTime[numSampleGases][p]
		
		duplicate/O wOutputMeanToGraph2, wMeanTemp
		duplicate/O wOutputErrorToGraph2, wErrorTemp
		duplicate/O wOutputFilterToGraph2, wFilterTemp
		duplicate/O wOutputTimeToGraph2, wTimeTemp
		
		if(numRefGases > 1)
			for(i=(numSampleGases+1);i<numGases;i+=1)
				
				wMeanTemp = wOutputTimeSeriesMatrix[i][variableToGraph2][p]
				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][variableToGraph2][p]
				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][variableToGraph2][p] == 0) ? 16 : 8
				wTimeTemp = wOutputTime[i][p]
				
				concatenate/NP {wMeanTemp}, wOutputMeanToGraph2
				concatenate/NP {wErrorTemp}, wOutputErrorToGraph2
				concatenate/NP {wFilterTemp}, wOutputFilterToGraph2
				concatenate/NP {wTimeTemp}, wOutputTimeToGraph2
				
			endfor
		endif
		
		killwaves wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp
		
	endif
	
	// Reset output variable mean values...
	wave wOutputMeans = root:wOutputMeans
	wave wOutputStDevs = root:wOutputStDevs
	wave wOutputStErrs = root:wOutputStErrs
	wOutputMeans[][] = NaN
	wOutputStDevs[][] = NaN
	wOutputStErrs[][] = NaN
	
	// Reset output variable group mean values...
	wave wGroupOutputMeans = root:wGroupOutputMeans
	wave wGroupOutputStDevs = root:wGroupOutputStDevs
	wave wGroupOutputStErrs = root:wGroupOutputStErrs
	wGroupOutputMeans[][] = NaN
	wGroupOutputStDevs[][] = NaN
	wGroupOutputStErrs[][] = NaN
	
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
	
	// Clear the status log...
	Notebook StatusNotebook, selection={startOfFile, endOfFile}
	Notebook StatusNotebook, text = "STATUS LOG"
	
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
	IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", secs2time(DateTime,3) + "  " + "Run started")
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
	wave/T wtParamTypes = root:wtParamTypes
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
	
	wave wSampleColorPalette = root:wSampleColorPalette
	wave wRefColorPalette = root:wRefColorPalette
	wave wSecondPlotColor = root:wSecondPlotColor
	
	variable i
	
	// Clear the status log...
	Notebook StatusNotebook, selection={startOfFile, endOfFile}
	Notebook StatusNotebook, text = "STATUS LOG"
	
	// Re-create matrix of time series of output variables, for the graph
	variable numAliquots = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Aliquots per Sample"))
	if(numType(numAliquots) != 0) // in case DefineParams function does not specify Number of Aliquots per Sample
		numAliquots = 1
	endif
	variable numCycles = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Cycles"))
	if(numType(numCycles) != 0) // in case DefineParams function does not specify Number of Cycles
		numCycles = 1
	endif
	make/O/D/N=(numGases,numOutputVariables,numAliquots*numCycles) wOutputTimeSeriesMatrix, wOutputTimeSeriesErrorMatrix, wOutputTimeSeriesFilterMatrix
	make/O/D/N=(numGases,numAliquots*numCycles) wOutputTime
	make/O/D/N=(numAliquots*numCycles) wOutputMeanToGraph1, wOutputErrorToGraph1, wOutputFilterToGraph1, wOutputTimeToGraph1
	make/O/D/N=(numAliquots*numCycles) wOutputMeanToGraph2, wOutputErrorToGraph2, wOutputFilterToGraph2, wOutputTimeToGraph2
	make/O/N=((numAliquots*numCycles),3) wOutputColorToGraph1
	wOutputColorToGraph1[][] = 0
	wOutputTimeSeriesMatrix[][][] = NaN
	wOutputTimeSeriesErrorMatrix[][][] = NaN
	wOutputTimeSeriesFilterMatrix[][][] = 0
	wOutputTime = q + 1
	variable windowCheck = WinType("IRISpanel#ResultGraph")
	if(windowCheck == 1)
		SetAxis/W=IRISpanel#ResultGraph/A
	endif
	
//	// Set which variable to graph...
//	wOutputMeanToGraph1 = wOutputTimeSeriesMatrix[gasToGraph1][variableToGraph1][p]
//	wOutputErrorToGraph1 = wOutputTimeSeriesErrorMatrix[gasToGraph1][variableToGraph1][p]
//	wOutputFilterToGraph1 = (wOutputTimeSeriesFilterMatrix[gasToGraph1][variableToGraph1][p] == 0) ? 19 : 8
//	wOutputTimeToGraph1 = wOutputTime[gasToGraph1][p]
//	wOutputMeanToGraph2 = wOutputTimeSeriesMatrix[gasToGraph2][variableToGraph2][p]
//	wOutputErrorToGraph2 = wOutputTimeSeriesErrorMatrix[gasToGraph2][variableToGraph2][p]
//	wOutputFilterToGraph2 = (wOutputTimeSeriesFilterMatrix[gasToGraph2][variableToGraph2][p] == 0) ? 16 : 8
//	wOutputTimeToGraph2 = wOutputTime[gasToGraph2][p]
	
	// Set which variable to graph...
	if((gasToGraph1 > 2) && (gasToGraph1 < numSampleGases + 3)) // individual sample gas
	
		wOutputMeanToGraph1 = wOutputTimeSeriesMatrix[gasToGraph1][variableToGraph1][p]
		wOutputErrorToGraph1 = wOutputTimeSeriesErrorMatrix[gasToGraph1][variableToGraph1][p]
		wOutputFilterToGraph1 = (wOutputTimeSeriesFilterMatrix[gasToGraph1][variableToGraph1][p] == 0) ? 19 : 8
		wOutputTimeToGraph1 = wOutputTime[gasToGraph1][p]
		wOutputColorToGraph1[][0] = wSampleColorPalette[mod(gasToGraph1-3,12)][0]
		wOutputColorToGraph1[][1] = wSampleColorPalette[mod(gasToGraph1-3,12)][1]
		wOutputColorToGraph1[][2] = wSampleColorPalette[mod(gasToGraph1-3,12)][2]
		
	elseif(gasToGraph1 > numSampleGases + 2) // individual ref gas
	
		wOutputMeanToGraph1 = wOutputTimeSeriesMatrix[gasToGraph1][variableToGraph1][p]
		wOutputErrorToGraph1 = wOutputTimeSeriesErrorMatrix[gasToGraph1][variableToGraph1][p]
		wOutputFilterToGraph1 = (wOutputTimeSeriesFilterMatrix[gasToGraph1][variableToGraph1][p] == 0) ? 19 : 8
		wOutputTimeToGraph1 = wOutputTime[gasToGraph1][p]
		wOutputColorToGraph1[][0] = wRefColorPalette[mod(gasToGraph1-3-numSampleGases,12)][0]
		wOutputColorToGraph1[][1] = wRefColorPalette[mod(gasToGraph1-3-numSampleGases,12)][1]
		wOutputColorToGraph1[][2] = wRefColorPalette[mod(gasToGraph1-3-numSampleGases,12)][2]
		
	elseif(gasToGraph1 == 0) // all gases
		
		wOutputMeanToGraph1 = wOutputTimeSeriesMatrix[0][variableToGraph1][p]
		wOutputErrorToGraph1 = wOutputTimeSeriesErrorMatrix[0][variableToGraph1][p]
		wOutputFilterToGraph1 = (wOutputTimeSeriesFilterMatrix[0][variableToGraph1][p] == 0) ? 19 : 8
		wOutputTimeToGraph1 = wOutputTime[0][p]
		wOutputColorToGraph1[][0] = wSampleColorPalette[0][0]
		wOutputColorToGraph1[][1] = wSampleColorPalette[0][1]
		wOutputColorToGraph1[][2] = wSampleColorPalette[0][2]
		
		duplicate/O wOutputMeanToGraph1, wMeanTemp
		duplicate/O wOutputErrorToGraph1, wErrorTemp
		duplicate/O wOutputFilterToGraph1, wFilterTemp
		duplicate/O wOutputTimeToGraph1, wTimeTemp
		duplicate/O wOutputColorToGraph1, wColorTemp
		
		if(numGases > 1)
			for(i=1;i<numSampleGases;i+=1)
				
				wMeanTemp = wOutputTimeSeriesMatrix[i][variableToGraph1][p]
				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][variableToGraph1][p]
				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][variableToGraph1][p] == 0) ? 19 : 8
				wTimeTemp = wOutputTime[i][p]
				wColorTemp[][0] = wSampleColorPalette[mod(i,12)][0]
				wColorTemp[][1] = wSampleColorPalette[mod(i,12)][1]
				wColorTemp[][2] = wSampleColorPalette[mod(i,12)][2]
				
				concatenate/NP {wMeanTemp}, wOutputMeanToGraph1
				concatenate/NP {wErrorTemp}, wOutputErrorToGraph1
				concatenate/NP {wFilterTemp}, wOutputFilterToGraph1
				concatenate/NP {wTimeTemp}, wOutputTimeToGraph1
				concatenate/NP=0 {wColorTemp}, wOutputColorToGraph1
				
			endfor
			
			for(i=numSampleGases;i<numGases;i+=1)
				
				wMeanTemp = wOutputTimeSeriesMatrix[i][variableToGraph1][p]
				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][variableToGraph1][p]
				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][variableToGraph1][p] == 0) ? 19 : 8
				wTimeTemp = wOutputTime[i][p]
				wColorTemp[][0] = wRefColorPalette[mod(i-numSampleGases,4)][0]
				wColorTemp[][1] = wRefColorPalette[mod(i-numSampleGases,4)][1]
				wColorTemp[][2] = wRefColorPalette[mod(i-numSampleGases,4)][2]
				
				concatenate/NP {wMeanTemp}, wOutputMeanToGraph1
				concatenate/NP {wErrorTemp}, wOutputErrorToGraph1
				concatenate/NP {wFilterTemp}, wOutputFilterToGraph1
				concatenate/NP {wTimeTemp}, wOutputTimeToGraph1
				concatenate/NP=0 {wColorTemp}, wOutputColorToGraph1
				
			endfor
		endif
		
		killwaves wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp, wColorTemp
		
	elseif(gasToGraph1 == 1) // all samples
		
		wOutputMeanToGraph1 = wOutputTimeSeriesMatrix[0][variableToGraph1][p]
		wOutputErrorToGraph1 = wOutputTimeSeriesErrorMatrix[0][variableToGraph1][p]
		wOutputFilterToGraph1 = (wOutputTimeSeriesFilterMatrix[0][variableToGraph1][p] == 0) ? 19 : 8
		wOutputTimeToGraph1 = wOutputTime[0][p]
		wOutputColorToGraph1[][0] = wSampleColorPalette[0][0]
		wOutputColorToGraph1[][1] = wSampleColorPalette[0][1]
		wOutputColorToGraph1[][2] = wSampleColorPalette[0][2]
		
		duplicate/O wOutputMeanToGraph1, wMeanTemp
		duplicate/O wOutputErrorToGraph1, wErrorTemp
		duplicate/O wOutputFilterToGraph1, wFilterTemp
		duplicate/O wOutputTimeToGraph1, wTimeTemp
		duplicate/O wOutputColorToGraph1, wColorTemp
		
		if(numSampleGases > 1)
			for(i=1;i<numSampleGases;i+=1)
				
				wMeanTemp = wOutputTimeSeriesMatrix[i][variableToGraph1][p]
				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][variableToGraph1][p]
				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][variableToGraph1][p] == 0) ? 19 : 8
				wTimeTemp = wOutputTime[i][p]
				wColorTemp[][0] = wSampleColorPalette[mod(i,12)][0]
				wColorTemp[][1] = wSampleColorPalette[mod(i,12)][1]
				wColorTemp[][2] = wSampleColorPalette[mod(i,12)][2]
				
				concatenate/NP {wMeanTemp}, wOutputMeanToGraph1
				concatenate/NP {wErrorTemp}, wOutputErrorToGraph1
				concatenate/NP {wFilterTemp}, wOutputFilterToGraph1
				concatenate/NP {wTimeTemp}, wOutputTimeToGraph1
				concatenate/NP=0 {wColorTemp}, wOutputColorToGraph1
				
			endfor
		endif
		
		killwaves wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp, wColorTemp
		
	elseif(gasToGraph1 == 2) // all refs
		
		wOutputMeanToGraph1 = wOutputTimeSeriesMatrix[numSampleGases][variableToGraph1][p]
		wOutputErrorToGraph1 = wOutputTimeSeriesErrorMatrix[numSampleGases][variableToGraph1][p]
		wOutputFilterToGraph1 = (wOutputTimeSeriesFilterMatrix[numSampleGases][variableToGraph1][p] == 0) ? 19 : 8
		wOutputTimeToGraph1 = wOutputTime[numSampleGases][p]
		wOutputColorToGraph1[][0] = wRefColorPalette[0][0]
		wOutputColorToGraph1[][1] = wRefColorPalette[0][1]
		wOutputColorToGraph1[][2] = wRefColorPalette[0][2]
		
		duplicate/O wOutputMeanToGraph1, wMeanTemp
		duplicate/O wOutputErrorToGraph1, wErrorTemp
		duplicate/O wOutputFilterToGraph1, wFilterTemp
		duplicate/O wOutputTimeToGraph1, wTimeTemp
		duplicate/O wOutputColorToGraph1, wColorTemp
		
		if(numRefGases > 1)
			for(i=(numSampleGases+1);i<numGases;i+=1)
				
				wMeanTemp = wOutputTimeSeriesMatrix[i][variableToGraph1][p]
				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][variableToGraph1][p]
				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][variableToGraph1][p] == 0) ? 19 : 8
				wTimeTemp = wOutputTime[i][p]
				wColorTemp[][0] = wRefColorPalette[mod(i-numSampleGases,4)][0]
				wColorTemp[][1] = wRefColorPalette[mod(i-numSampleGases,4)][1]
				wColorTemp[][2] = wRefColorPalette[mod(i-numSampleGases,4)][2]
				
				concatenate/NP {wMeanTemp}, wOutputMeanToGraph1
				concatenate/NP {wErrorTemp}, wOutputErrorToGraph1
				concatenate/NP {wFilterTemp}, wOutputFilterToGraph1
				concatenate/NP {wTimeTemp}, wOutputTimeToGraph1
				concatenate/NP=0 {wColorTemp}, wOutputColorToGraph1
				
			endfor
		endif
		
		killwaves wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp, wColorTemp
		
	endif
	
//	if(gasToGraph1 > 2) // individual sample or ref gas
//	
//		wOutputMeanToGraph1 = wOutputTimeSeriesMatrix[gasToGraph1][variableToGraph1][p]
//		wOutputErrorToGraph1 = wOutputTimeSeriesErrorMatrix[gasToGraph1][variableToGraph1][p]
//		wOutputFilterToGraph1 = (wOutputTimeSeriesFilterMatrix[gasToGraph1][variableToGraph1][p] == 0) ? 19 : 8
//		wOutputTimeToGraph1 = wOutputTime[gasToGraph1][p]
//		
//	elseif(gasToGraph1 == 0) // all gases
//		
//		wOutputMeanToGraph1 = wOutputTimeSeriesMatrix[0][variableToGraph1][p]
//		wOutputErrorToGraph1 = wOutputTimeSeriesErrorMatrix[0][variableToGraph1][p]
//		wOutputFilterToGraph1 = (wOutputTimeSeriesFilterMatrix[0][variableToGraph1][p] == 0) ? 19 : 8
//		wOutputTimeToGraph1 = wOutputTime[0][p]
//		
//		duplicate/O wOutputMeanToGraph1, wMeanTemp
//		duplicate/O wOutputErrorToGraph1, wErrorTemp
//		duplicate/O wOutputFilterToGraph1, wFilterTemp
//		duplicate/O wOutputTimeToGraph1, wTimeTemp
//		
//		if(numGases > 1)
//			for(i=1;i<numGases;i+=1)
//				
//				wMeanTemp = wOutputTimeSeriesMatrix[i][variableToGraph1][p]
//				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][variableToGraph1][p]
//				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][variableToGraph1][p] == 0) ? 19 : 8
//				wTimeTemp = wOutputTime[i][p]
//				
//				concatenate/NP {wMeanTemp}, wOutputMeanToGraph1
//				concatenate/NP {wErrorTemp}, wOutputErrorToGraph1
//				concatenate/NP {wFilterTemp}, wOutputFilterToGraph1
//				concatenate/NP {wTimeTemp}, wOutputTimeToGraph1
//				
//			endfor
//		endif
//		
//		killwaves wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp
//		
//	elseif(gasToGraph1 == 1) // all samples
//		
//		wOutputMeanToGraph1 = wOutputTimeSeriesMatrix[0][variableToGraph1][p]
//		wOutputErrorToGraph1 = wOutputTimeSeriesErrorMatrix[0][variableToGraph1][p]
//		wOutputFilterToGraph1 = (wOutputTimeSeriesFilterMatrix[0][variableToGraph1][p] == 0) ? 19 : 8
//		wOutputTimeToGraph1 = wOutputTime[0][p]
//		
//		duplicate/O wOutputMeanToGraph1, wMeanTemp
//		duplicate/O wOutputErrorToGraph1, wErrorTemp
//		duplicate/O wOutputFilterToGraph1, wFilterTemp
//		duplicate/O wOutputTimeToGraph1, wTimeTemp
//		
//		if(numSampleGases > 1)
//			for(i=1;i<numSampleGases;i+=1)
//				
//				wMeanTemp = wOutputTimeSeriesMatrix[i][variableToGraph1][p]
//				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][variableToGraph1][p]
//				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][variableToGraph1][p] == 0) ? 19 : 8
//				wTimeTemp = wOutputTime[i][p]
//				
//				concatenate/NP {wMeanTemp}, wOutputMeanToGraph1
//				concatenate/NP {wErrorTemp}, wOutputErrorToGraph1
//				concatenate/NP {wFilterTemp}, wOutputFilterToGraph1
//				concatenate/NP {wTimeTemp}, wOutputTimeToGraph1
//				
//			endfor
//		endif
//		
//		killwaves wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp
//		
//	elseif(gasToGraph1 == 2) // all refs
//		
//		wOutputMeanToGraph1 = wOutputTimeSeriesMatrix[numSampleGases][variableToGraph1][p]
//		wOutputErrorToGraph1 = wOutputTimeSeriesErrorMatrix[numSampleGases][variableToGraph1][p]
//		wOutputFilterToGraph1 = (wOutputTimeSeriesFilterMatrix[numSampleGases][variableToGraph1][p] == 0) ? 19 : 8
//		wOutputTimeToGraph1 = wOutputTime[numSampleGases][p]
//		
//		duplicate/O wOutputMeanToGraph1, wMeanTemp
//		duplicate/O wOutputErrorToGraph1, wErrorTemp
//		duplicate/O wOutputFilterToGraph1, wFilterTemp
//		duplicate/O wOutputTimeToGraph1, wTimeTemp
//		
//		if(numRefGases > 1)
//			for(i=(numSampleGases+1);i<numGases;i+=1)
//				
//				wMeanTemp = wOutputTimeSeriesMatrix[i][variableToGraph1][p]
//				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][variableToGraph1][p]
//				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][variableToGraph1][p] == 0) ? 19 : 8
//				wTimeTemp = wOutputTime[i][p]
//				
//				concatenate/NP {wMeanTemp}, wOutputMeanToGraph1
//				concatenate/NP {wErrorTemp}, wOutputErrorToGraph1
//				concatenate/NP {wFilterTemp}, wOutputFilterToGraph1
//				concatenate/NP {wTimeTemp}, wOutputTimeToGraph1
//				
//			endfor
//		endif
//		
//		killwaves wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp
//		
//	endif
	
	if(gasToGraph2 > 2) // individual sample or ref gas
	
		wOutputMeanToGraph2 = wOutputTimeSeriesMatrix[gasToGraph2][variableToGraph2][p]
		wOutputErrorToGraph2 = wOutputTimeSeriesErrorMatrix[gasToGraph2][variableToGraph2][p]
		wOutputFilterToGraph2 = (wOutputTimeSeriesFilterMatrix[gasToGraph2][variableToGraph2][p] == 0) ? 16 : 8
		wOutputTimeToGraph2 = wOutputTime[gasToGraph2][p]
		
	elseif(gasToGraph2 == 0) // all gases
		
		wOutputMeanToGraph2 = wOutputTimeSeriesMatrix[0][variableToGraph2][p]
		wOutputErrorToGraph2 = wOutputTimeSeriesErrorMatrix[0][variableToGraph2][p]
		wOutputFilterToGraph2 = (wOutputTimeSeriesFilterMatrix[0][variableToGraph2][p] == 0) ? 16 : 8
		wOutputTimeToGraph2 = wOutputTime[0][p]
		
		duplicate/O wOutputMeanToGraph2, wMeanTemp
		duplicate/O wOutputErrorToGraph2, wErrorTemp
		duplicate/O wOutputFilterToGraph2, wFilterTemp
		duplicate/O wOutputTimeToGraph2, wTimeTemp
		
		if(numGases > 1)
			for(i=1;i<numGases;i+=1)
				
				wMeanTemp = wOutputTimeSeriesMatrix[i][variableToGraph2][p]
				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][variableToGraph2][p]
				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][variableToGraph2][p] == 0) ? 16 : 8
				wTimeTemp = wOutputTime[i][p]
				
				concatenate/NP {wMeanTemp}, wOutputMeanToGraph2
				concatenate/NP {wErrorTemp}, wOutputErrorToGraph2
				concatenate/NP {wFilterTemp}, wOutputFilterToGraph2
				concatenate/NP {wTimeTemp}, wOutputTimeToGraph2
				
			endfor
		endif
		
		killwaves wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp
		
	elseif(gasToGraph2 == 1) // all samples
		
		wOutputMeanToGraph2 = wOutputTimeSeriesMatrix[0][variableToGraph2][p]
		wOutputErrorToGraph2 = wOutputTimeSeriesErrorMatrix[0][variableToGraph2][p]
		wOutputFilterToGraph2 = (wOutputTimeSeriesFilterMatrix[0][variableToGraph2][p] == 0) ? 16 : 8
		wOutputTimeToGraph2 = wOutputTime[0][p]
		
		duplicate/O wOutputMeanToGraph2, wMeanTemp
		duplicate/O wOutputErrorToGraph2, wErrorTemp
		duplicate/O wOutputFilterToGraph2, wFilterTemp
		duplicate/O wOutputTimeToGraph2, wTimeTemp
		
		if(numSampleGases > 1)
			for(i=1;i<numSampleGases;i+=1)
				
				wMeanTemp = wOutputTimeSeriesMatrix[i][variableToGraph2][p]
				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][variableToGraph2][p]
				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][variableToGraph2][p] == 0) ? 16 : 8
				wTimeTemp = wOutputTime[i][p]
				
				concatenate/NP {wMeanTemp}, wOutputMeanToGraph2
				concatenate/NP {wErrorTemp}, wOutputErrorToGraph2
				concatenate/NP {wFilterTemp}, wOutputFilterToGraph2
				concatenate/NP {wTimeTemp}, wOutputTimeToGraph2
				
			endfor
		endif
		
		killwaves wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp
		
	elseif(gasToGraph2 == 2) // all refs
		
		wOutputMeanToGraph2 = wOutputTimeSeriesMatrix[numSampleGases][variableToGraph2][p]
		wOutputErrorToGraph2 = wOutputTimeSeriesErrorMatrix[numSampleGases][variableToGraph2][p]
		wOutputFilterToGraph2 = (wOutputTimeSeriesFilterMatrix[numSampleGases][variableToGraph2][p] == 0) ? 16 : 8
		wOutputTimeToGraph2 = wOutputTime[numSampleGases][p]
		
		duplicate/O wOutputMeanToGraph2, wMeanTemp
		duplicate/O wOutputErrorToGraph2, wErrorTemp
		duplicate/O wOutputFilterToGraph2, wFilterTemp
		duplicate/O wOutputTimeToGraph2, wTimeTemp
		
		if(numRefGases > 1)
			for(i=(numSampleGases+1);i<numGases;i+=1)
				
				wMeanTemp = wOutputTimeSeriesMatrix[i][variableToGraph2][p]
				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][variableToGraph2][p]
				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][variableToGraph2][p] == 0) ? 16 : 8
				wTimeTemp = wOutputTime[i][p]
				
				concatenate/NP {wMeanTemp}, wOutputMeanToGraph2
				concatenate/NP {wErrorTemp}, wOutputErrorToGraph2
				concatenate/NP {wFilterTemp}, wOutputFilterToGraph2
				concatenate/NP {wTimeTemp}, wOutputTimeToGraph2
				
			endfor
		endif
		
		killwaves wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp
		
	endif
	
	// Reset output variable values...
	wave wOutputMeans = root:wOutputMeans
	wave wOutputStDevs = root:wOutputStDevs
	wave wOutputStErrs = root:wOutputStErrs
	wOutputMeans[][] = NaN
	wOutputStDevs[][] = NaN
	wOutputStErrs[][] = NaN
	
	// Reset output variable group mean values...
	wave wGroupOutputMeans = root:wGroupOutputMeans
	wave wGroupOutputStDevs = root:wGroupOutputStDevs
	wave wGroupOutputStErrs = root:wGroupOutputStErrs
	wGroupOutputMeans[][] = NaN
	wGroupOutputStDevs[][] = NaN
	wGroupOutputStErrs[][] = NaN
	
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
	IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", "Reanalysis Complete")
	
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
	NVAR IRIS_WaitingForUser1 = root:IRIS_WaitingForUser1
	NVAR IRIS_WaitingForUser2 = root:IRIS_WaitingForUser2
	NVAR IRIS_WaitingForUser3 = root:IRIS_WaitingForUser3
	NVAR azaInProgress = root:azaInProgress
	NVAR azaValve = root:azaValve
//	NVAR azaInitialValveState = root:azaInitialValveState
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
	
	variable nowDateTime, nowDate, nowYear, nowMonth, nowDay
	variable clockInterval, clockIntervalHours, clockIntervalMinutes, clockIntervalSeconds
	variable clockStartTime, clockStartHour, clockStartMinute, clockStartSecond
	variable clockStartDate, clockStartYear, clockStartMonth, clockStartDay
	variable clockStartDateTime
	variable clockTimeTolerance = 5 // seconds
	string sNowDate, sClockInterval, sClockStartTime, sClockStartDate
	
	variable thisStatusCategory
			
	string sActionFunctionName
	
	variable eventCap = 10 // max number of schedule events to do at one time
	variable azaOpeningTimeout = 5 // seconds
	
	wave/T wtParamNames = root:wtParamNames
	wave/T wtParamValues = root:wtParamValues
	wave/T wtParamUnits = root:wtParamUnits
	wave/T wtParamTypes = root:wtParamTypes
	
	wave/T wStatusCategoryNames = root:wStatusCategoryNames
	wave/T wStatusStrings = root:wStatusStrings
	
	variable numCycles = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Cycles"))
	if(numType(numCycles) != 0) // in case DefineParams function does not specify Number of Cycles
		numCycles = 1
	endif
	variable numRealCycles = numCycles // used only when analysisOnly == 1
	if((numCycles == 0) || (analysisOnly == 1)) // numCycles = 0 indicates perpetual run (up to the time limit)
		numCycles = 1e8 // effectively infinite
	endif
	
	variable timeLimit = str2num(IRIS_UTILITY_GetParamValueFromName("Time Limit"))
	if(numType(timeLimit) != 0) // in case DefineParams function does not specify Time Limit
		timeLimit = 1e8 // effectively infinite
	endif
	timeLimit = timeLimit*3600 //conversion from hours to seconds
	
	variable anchorTime
	variable elapsedTime
	variable numSimultaneousEvents
	variable eventCount
	variable noMoreEvents
	variable maxNumCompleteSampleMeasurementsSoFar
	variable minNumCompleteSampleMeasurementsSoFar
	
	// Check whether TDL Wintel is still acting on an aza or azb (i.e. fill to pressure) command, and set azaInProgress to zero if not
	if(azaInProgress == 1)
		// get azaCurrentValveState via TCP/IP using azaValve...
		azaCurrentValveState = wValveStates[azaValve]
		// then...
		if(azaValveHasTriggered == 1)
//			if(azaCurrentValveState == azaInitialValveState)
			if(azaCurrentValveState == 0)
				print "aza or azb has ended, valve = " + num2str(azaValve+1)
				azaInProgress = 0
				azaValveHasTriggered = 0
				wTimerAnchors[0] = DateTime // reset timer 0 at the completion of the aza fill
			endif
		else
//			if((azaCurrentValveState != azaInitialValveState) || (DateTime > azaOpeningTimer + azaOpeningTimeout)) // if after azaOpeningTimeout seconds, the valve state has not been observed to have changed, it is assumed that aza started and completed within one schedule agent interval
			if((azaCurrentValveState != 0) || (DateTime > azaOpeningTimer + azaOpeningTimeout)) // if after azaOpeningTimeout seconds, the valve state has not been observed to have activated, it is assumed that aza started and completed within one schedule agent interval
				azaValveHasTriggered = 1
				print "aza or azb valve has triggered, valve = " + num2str(azaValve+1)
			endif
		endif
	endif
	
	// If TDL Wintel really is still acting on an aza or azb command, don't move on to the next event yet (and don't stop the run)
	if(azaInProgress == 1)
		SetDataFolder $saveFolder
		return 0 // don't do anything below
	endif
	
	// Check whether the time limit has been reached
	if((IRIS_ShouldStartToStop == 0) && (IRIS_Stopping == 0))
		if((DateTime - startTimeSecs) > timeLimit)
			IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", secs2time(DateTime,3) + "  " + "Time limit reached")
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
	
	// Check whether IRIS is waiting for the user to click "RESUME" (we should only get this far if the time limit has not been reached and the user has not clicked STOP)
	if( (IRIS_Stopping == 0) && ((IRIS_WaitingForUser1 == 1) || (IRIS_WaitingForUser2 == 1) || (IRIS_WaitingForUser3 == 1)) )
		SetDataFolder $saveFolder
		return 0 // don't do anything below
	endif
	
	
	
	// Here we could cycle through all active schedules, which run in parallel.
	// In that case, change item format to remove timer info; instead have special commands: waitForClock (waitForAbsoluteTime), waitForClockInterval (waitForPeriodicTime), waitForTimer (waitForElapsedTime).
	
	
	
	
	// Check whether it's time to do the next scheduled action
	if(numScheduleEvents > 0) // numScheduleEvents might be zero if, for example, the Cycle is empty due to there being only 1 sample gas in a D17O_d13C_CO2_fastMixer instrument
		
		anchorTime = wTimerAnchors[wSchedule_Current_WhichTimer[scheduleIndex]]
		elapsedTime = DateTime - anchorTime
		if(elapsedTime < wSchedule_Current_TriggerTime[scheduleIndex]) // no, it's not time yet
			SetDataFolder $saveFolder
			return 0 // don't do anything below
		endif
		if(stringMatch(wSchedule_Current_Action[scheduleIndex], "WaitForClock") == 1)
		
			// argument format for WaitForClock event: "hh:mm:ss;hh:mm:ss;YYYY-MM-DD" where the first item in the string list is for the interval and the other two items are for the (optional) start time
			nowDateTime = DateTime // seconds since 1904,1,1
			sNowDate = secs2date(nowDateTime, -2)      // In YYYY-MM-DD format
			sscanf sNowDate, "%d-%d-%d", nowYear, nowMonth, nowDay
			nowDate = date2secs(nowYear, nowMonth, nowDay) // seconds since 1904,1,1
		
			sClockInterval = StringFromList(0, wSchedule_Current_Argument[scheduleIndex])
			sscanf sClockInterval, "%d:%d:%d", clockIntervalHours, clockIntervalMinutes, clockIntervalSeconds
			clockInterval = 3600*clockIntervalHours + 60*clockIntervalMinutes + clockIntervalSeconds
		
			if(ItemsInList(wSchedule_Current_Argument[scheduleIndex]) > 1)
			
				sClockStartTime = StringFromList(1, wSchedule_Current_Argument[scheduleIndex])
				sscanf sClockStartTime, "%d:%d:%d", clockStartHour, clockStartMinute, clockStartSecond
				clockStartTime = 3600*clockStartHour + 60*clockStartMinute + clockStartSecond
			
				if(ItemsInList(wSchedule_Current_Argument[scheduleIndex]) > 2)
				
					sClockStartDate = StringFromList(2, wSchedule_Current_Argument[scheduleIndex])
					sscanf sClockStartDate, "%d-%d-%d", clockStartYear, clockStartMonth, clockStartDay
					clockStartDate = date2secs( clockStartYear, clockStartMonth, clockStartDay )
				
				else
				
					clockStartDate = nowDate
				
				endif
			
				clockStartDateTime = clockStartDate + clockStartTime
			
			endif
		
			if( ( nowDateTime < clockStartDateTime ) || ( mod( nowDateTime - clockStartDateTime, clockInterval ) > clockTimeTolerance ) ) // no, it's not the right absolute time
				SetDataFolder $saveFolder
				return 0 // don't do anything below
			endif
		
			//		// argument format for WaitForClock event: "h;m;s;h;m;s;Y;M;D" where the first set of hours, minutes, seconds is for the interval and the rest is for the (optional) start time
			//		// variable nowDateTime, nowDate, nowYear, nowMonth, nowDay
			//		// variable clockInterval, clockStartTime, clockStartDate
			//		// string sNowDate
			//		clockInterval = 0 // seconds
			//		clockStartTime = 0 // seconds since start of day
			//		clockStartDate = 0 // seconds from 1904,1,1 to start of day
			//		clockInterval += 3600*str2num(StringFromList(0, wSchedule_Current_Argument[scheduleIndex])) // adding hours; unit is seconds
			//		if(ItemsInList(wSchedule_Current_Argument[scheduleIndex]) > 1)
			//			clockInterval += 60*str2num(StringFromList(1, wSchedule_Current_Argument[scheduleIndex])) // adding minutes; unit is seconds
			//			if(ItemsInList(wSchedule_Current_Argument[scheduleIndex]) > 2)
			//				clockInterval += str2num(StringFromList(2, wSchedule_Current_Argument[scheduleIndex])) // adding seconds; unit is seconds
			//			endif
			//		endif
			//		if(ItemsInList(wSchedule_Current_Argument[scheduleIndex]) > 3)
			//			clockStartTime += 3600*str2num(StringFromList(3, wSchedule_Current_Argument[scheduleIndex])) // adding hours; unit is seconds
			//			if(ItemsInList(wSchedule_Current_Argument[scheduleIndex]) > 4)
			//				clockStartTime += 60*str2num(StringFromList(4, wSchedule_Current_Argument[scheduleIndex])) // adding minutes; unit is seconds
			//				if(ItemsInList(wSchedule_Current_Argument[scheduleIndex]) > 5)
			//					clockStartTime += str2num(StringFromList(5, wSchedule_Current_Argument[scheduleIndex])) // adding seconds; unit is seconds
			//				endif
			//			endif
			//		endif
			//		if(ItemsInList(wSchedule_Current_Argument[scheduleIndex]) == 9)
			//			clockStartDate = date2secs( str2num(StringFromList(6, wSchedule_Current_Argument[scheduleIndex])), str2num(StringFromList(7, wSchedule_Current_Argument[scheduleIndex])), str2num(StringFromList(8, wSchedule_Current_Argument[scheduleIndex])) )
			//		else
			//			clockStartDate = 
			//			
			//			
			//		endif
			//		
			//		if( nowDateTime >= (clockStartTime + clockStartDate) )
			//			if( mod( nowDateTime - (clockStartTime + clockStartDate), clockInterval ) < clockTimeTolerance) // no, it's not the right absolute time
			//				SetDataFolder $saveFolder
			//				return 0 // don't do anything below
			//			endif
			//		endif
		
		endif
	
		// Look ahead to see whether there are subsequent events that should also be done now
		// (Such actions would have a trigger time of 0 on timer 0.)
		// (The purpose of this feature is mainly to provide a mechanism for handing timing control over to TDL Wintel via the bc and cr ECL commands, if desired.)
		numSimultaneousEvents = 1
		eventCount = 0
		noMoreEvents = 0
		variable isWait, isAza, isAzb
		if(scheduleIndex < (numScheduleEvents - 1))
			do
				subEventIndex = scheduleIndex + 1 + eventCount
				noMoreEvents = 1
				if(wSchedule_Current_WhichTimer[subEventIndex] == 0)
					if(wSchedule_Current_TriggerTime[subEventIndex] == 0)
						//					isAza = ((stringMatch(wSchedule_Current_Argument[subEventIndex - 1], "*aza*") == 1) || (stringMatch(wSchedule_Current_Argument[subEventIndex], "*aza*") == 1))
						//					isAzb = ((stringMatch(wSchedule_Current_Argument[subEventIndex - 1], "*azb*") == 1) || (stringMatch(wSchedule_Current_Argument[subEventIndex], "*azb*") == 1))
						isWait = (stringMatch(wSchedule_Current_Action[subEventIndex - 1], "*Wait*") == 1) // a wait for user can come at the end of a simultaneous batch, but not in the middle
						isAza = (stringMatch(wSchedule_Current_Argument[subEventIndex - 1], "*aza*") == 1) // an aza/azb can come at the end of a simultaneous batch, but not in the middle
						isAzb = (stringMatch(wSchedule_Current_Argument[subEventIndex - 1], "*azb*") == 1) // an aza/azb can come at the end of a simultaneous batch, but not in the middle
						if((!isWait) && (!isAza) && (!isAzb)) // don't go past an aza or azb command in a single batch, because then the commands after the aza or azb command will execute while the aza or azb fill is still underway
							numSimultaneousEvents += 1
							noMoreEvents = 0
							//					else
							//						print "It's an aza or azb!"
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
		
	else
		
		scheduleIndex += 1
		
	endif
	
	maxNumCompleteSampleMeasurementsSoFar = wavemax(wNumCompleteMeasurementsByGas, 0, (numSampleGases - 1))
	
	// When the current schedule is done, either advance to the next one or end the run
	if(scheduleIndex >= numScheduleEvents)
		if(cycleNumber > numCycles) // the Epilogue (cycleNumber = numCycles + 1) or the final Reset (cycleNumber = numCycles + 2) just finished
			// Turn ourself off now that all schedules are done
			sAcquisitionEndTime = secs2time(DateTime,2) + " on " + secs2date(DateTime, -1)
			if(maxNumCompleteSampleMeasurementsSoFar > 0)
				IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", secs2time(DateTime,3) + "  " + "Run stopped")
				IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", "          " + "Saving results...")
			else
				IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", secs2time(DateTime,3) + "  " + "Run stopped before data acquired")
			endif
			IRIS_UTILITY_SaveResults()
			ModifyControl IRIS_Run_tabRun, win = IRISpanel, title = "RUN"
			ModifyControl IRIS_Stop_tabRun, win = IRISpanel, title = "STOPPED"
			for(thisStatusCategory=0;thisStatusCategory<3;thisStatusCategory+=1)
				if(cmpstr(wStatusCategoryNames[thisStatusCategory]," ") != 0)
					wStatusStrings[thisStatusCategory] = "idle"
				endif
			endfor
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
					IRIS_EVENT_ReportStatus("TILDAS: Received external command to RUN")
					IRIS_EVENT_ReportStatus("TILDAS: CANNOT RUN: calibration curve is invalid")
					deletePoints 0, 1, instructionQueueForIRIS
					DoUpdate
				elseif(gasInfoIsValid == 0)
					IRIS_EVENT_ReportStatus("TILDAS: Received external command to RUN")
					IRIS_EVENT_ReportStatus("TILDAS: CANNOT RUN: gas info is invalid")
					deletePoints 0, 1, instructionQueueForIRIS
					DoUpdate
				else
					if(IRIS_Reanalyzing == 0)
						if(IRIS_Running == 0)
							IRIS_EVENT_ReportStatus("TILDAS: Received external command to RUN")
							IRIS_Running = 1
							IRIS_ConfirmToRun = 0
							IRIS_ConfirmToStop = 0
							ModifyControl IRIS_Run_tabRun, win = IRISpanel, title = "RUNNING"
							ModifyControl IRIS_Stop_tabRun, win = IRISpanel, title = "STOP"
							deletePoints 0, 1, instructionQueueForIRIS
							DoUpdate
							IRIS_UTILITY_Run()
						else
							IRIS_EVENT_ReportStatus("TILDAS: Received external command to RUN")
							IRIS_EVENT_ReportStatus("TILDAS: Command ignored: a run is already underway")
							deletePoints 0, 1, instructionQueueForIRIS
							DoUpdate
						endif
					else
						IRIS_EVENT_ReportStatus("TILDAS: Received external command to RUN")
						IRIS_EVENT_ReportStatus("TILDAS: CANNOT RUN: IRIS is currently reanalyzing data")
						deletePoints 0, 1, instructionQueueForIRIS
						DoUpdate
					endif
				endif
			
			elseif(cmpstr(lowerstr(thisInstruction), "stop") == 0)
			
				if((IRIS_Running == 1) && (IRIS_ShouldStartToStop == 0) && (IRIS_Stopping == 0))
					IRIS_EVENT_ReportStatus("TILDAS: Received external command to STOP")
					IRIS_ShouldStartToStop = 1
					IRIS_ConfirmToRun = 0
					IRIS_ConfirmToStop = 0
					ModifyControl IRIS_Stop_tabRun, win = IRISpanel, title = "STOPPING"
					deletePoints 0, 1, instructionQueueForIRIS
					DoUpdate
				else
					if(IRIS_Running == 0)
						IRIS_EVENT_ReportStatus("TILDAS: Received external command to STOP")
						IRIS_EVENT_ReportStatus("TILDAS: Command ignored: no run was in progress.")
						deletePoints 0, 1, instructionQueueForIRIS
						DoUpdate
					elseif((IRIS_ShouldStartToStop == 1) || (IRIS_Stopping == 1))
						IRIS_EVENT_ReportStatus("TILDAS: Received external command to STOP")
						IRIS_EVENT_ReportStatus("TILDAS: Command ignored: run was already stopping.")
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
				IRIS_EVENT_ReportStatus("TILDAS: Received external request for status report")
				string statusStringReport = "TILDAS: Status is: " + statusString
				IRIS_EVENT_ReportStatus(statusStringReport)
				IRIS_UTILITY_BroadcastStatus(statusString)
				deletePoints 0, 1, instructionQueueForIRIS
				DoUpdate
				
			else
				
				string reportString = "TILDAS: Received invalid command: " + thisInstruction
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
	wave/T wtParamTypes = root:wtParamTypes
	
	wave wOutputMeans = root:wOutputMeans
	wave wOutputStDevs = root:wOutputStDevs
	wave wOutputStErrs = root:wOutputStErrs
	
	wave wGroupOutputMeans = root:wGroupOutputMeans
	wave wGroupOutputStDevs = root:wGroupOutputStDevs
	wave wGroupOutputStErrs = root:wGroupOutputStErrs
	
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
	string/G sCSVResults_L1 = ""
	string/G sCSVResults_L1L2 = ""
	string sTextResultsTemp
	string sCSVResultsTemp_L1
	string sCSVResultsTemp_L1L2
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
	string/G sResultsSubfolderName = "IRIS Results - " + sRunID + " -" + sDataFileString
	string/G sResultsSubfolderPathAndName = sResultsPath + ":" + sResultsSubfolderName
	NewPath/C/Q/O pResultsSubfolderPath, sResultsSubfolderPathAndName // the "/C" flag creates the folder on disk if it does not already exist
	
	// Set filenames for saving results
	string sResultsFileNameRoot = "IRIS Numeric Results - " + sRunID + " -" + sDataFileString
	string/G sGraphsFileNameRoot = "IRIS Graphical Results - " + sRunID + " -" + sDataFileString
	string/G sGraphsFileNameBaseNoExt = sGraphsFileNameRoot // needed for appending "- Variable0" etc in IRIS_UTILITY_MakeAndSaveGraphs
	string/G sBundleFileNameRoot = "IRIS Bundled Results - " + sRunID + " -" + sDataFileString
	string sStatusFileNameRoot = "IRIS Status Log - " + sRunID + " -" + sDataFileString
	string/G sResultsFileTXT = sResultsFileNameRoot + ".txt" // name of the file to create
	string/G sResultsFileSummaryCSV_L1 = sResultsFileNameRoot + "_L1.csv" // name of the file to create
	string/G sResultsFileSummaryCSV_L1L2 = sResultsFileNameRoot + "_L1_L2.csv" // name of the file to create
	string/G sGraphsFilePNG = sGraphsFileNameRoot + ".png" // name of the file to create
	string/G sBundleFilePDF = sBundleFileNameRoot + ".pdf" // name of the file to create
	string/G sStatusFileTXT = sStatusFileNameRoot + ".txt" // name of the file to create
	string sExistingFilesTXT = IndexedFile(pResultsSubfolderPath, -1, ".txt")
	string sExistingFilesCSV = IndexedFile(pResultsSubfolderPath, -1, ".csv")
	string sExistingFilesPNG = IndexedFile(pResultsSubfolderPath, -1, ".png")
	string sExistingFilesPDF = IndexedFile(pResultsSubfolderPath, -1, ".pdf")
	string sMatchStrTXT = "*" + sResultsFileTXT + "*"
	string sMatchStrCSV_L1 = "*" + sResultsFileSummaryCSV_L1 + "*"// Berkeley-specific file
	string sMatchStrCSV_L1L2 = "*" + sResultsFileSummaryCSV_L1L2 + "*"// Berkeley-specific file
	string sMatchStrPNG = "*" + sGraphsFilePNG + "*"
	string sMatchStrPDF = "*" + sBundleFilePDF + "*"
	string sMatchStrStatusTXT = "*" + sStatusFileTXT + "*"
	variable checkTXT = stringmatch(sExistingFilesTXT, sMatchStrTXT)
	variable checkCSV_L1 = stringmatch(sExistingFilesCSV, sMatchStrCSV_L1)
	variable checkCSV_L1L2 = stringmatch(sExistingFilesCSV, sMatchStrCSV_L1L2)
	variable checkPNG = stringmatch(sExistingFilesPNG, sMatchStrPNG)
	variable checkPDF = stringmatch(sExistingFilesPDF, sMatchStrPDF)
	variable checkStatusTXT = stringmatch(sExistingFilesTXT, sMatchStrStatusTXT)
	variable adjustmentIndex = 0
	if((checkTXT == 1) || (checkPNG == 1) || (checkPDF == 1) || (checkStatusTXT == 1) || (checkCSV_L1 == 1) || (checkCSV_L1L2 == 1))
		do
			adjustmentIndex += 1
			sResultsFileTXT = sResultsFileNameRoot + " - rev" + num2istr(adjustmentIndex) + ".txt"
			sResultsFileSummaryCSV_L1 = sResultsFileNameRoot + "_summary_L1 - rev" + num2istr(adjustmentIndex) + ".csv" // Berkeley-specific file
			sResultsFileSummaryCSV_L1L2 = sResultsFileNameRoot + "_summary_L1_L2 - rev" + num2istr(adjustmentIndex) + ".csv" // Berkeley-specific file
			sGraphsFilePNG = sGraphsFileNameRoot + " - rev" + num2istr(adjustmentIndex) + ".png"
			sGraphsFileNameBaseNoExt = sGraphsFileNameRoot + " - rev" + num2istr(adjustmentIndex) // needed for appending "- Variable0" etc in IRIS_UTILITY_MakeAndSaveGraphs
			sBundleFilePDF = sBundleFileNameRoot + " - rev" + num2istr(adjustmentIndex) + ".pdf"
			sStatusFileTXT = sStatusFileNameRoot + " - rev" + num2istr(adjustmentIndex) + ".txt"
			sExistingFilesTXT = IndexedFile(pResultsSubfolderPath, -1, ".txt")
			sExistingFilesPNG = IndexedFile(pResultsSubfolderPath, -1, ".png")
			sExistingFilesPDF = IndexedFile(pResultsSubfolderPath, -1, ".pdf")
			sMatchStrTXT = "*" + sResultsFileTXT + "*"
			sMatchStrCSV_L1 = "*" + sResultsFileSummaryCSV_L1 + "*"  // Berkeley-specific file
			sMatchStrCSV_L1L2 = "*" + sResultsFileSummaryCSV_L1L2 + "*"  // Berkeley-specific file
			sMatchStrPNG = "*" + sGraphsFilePNG + "*"
			sMatchStrPDF = "*" + sBundleFilePDF + "*"
			sMatchStrStatusTXT = "*" + sStatusFileTXT + "*"
			checkTXT = stringmatch(sExistingFilesTXT, sMatchStrTXT)
			checkCSV_L1 = stringmatch(sExistingFilesTXT, sMatchStrCSV_L1)
			checkCSV_L1L2 = stringmatch(sExistingFilesTXT, sMatchStrCSV_L1L2)
			checkPNG = stringmatch(sExistingFilesPNG, sMatchStrPNG)
			checkPDF = stringmatch(sExistingFilesPDF, sMatchStrPDF)
			checkStatusTXT = stringmatch(sExistingFilesTXT, sMatchStrStatusTXT)
		while((checkTXT == 1) || (checkPNG == 1) || (checkPDF == 1) || (checkStatusTXT == 1) || (checkCSV_L1 == 1) || (checkCSV_L1L2 == 1))
	endif
	
	// Record Berkeley-specific data output
	SVAR sInstrumentType = root:sInstrumentType
	
	if(stringmatch("D17O_d13C_CO2_LBL", sInstrumentType))
		header = "Sample ID,Start time,CO2 MR,CO2 MR SE,Cell Pressure,Cell Pressure SE,Cell Temp,Cell Temp SE,d13C,d13C SE,d17O,d17O SE,d18O,d18O SE,D'17O,D'17O SE"
		Open/A/P=pResultsSubfolderPath f1 as sResultsFileSummaryCSV_L1 // if file already exists, we will append the new info to it (in case future code allows for reanalysis of data)
		fprintf f1, "%s\r\n", header
		sprintf sCSVResultsTemp_L1, "%s\r\n", header
	
		for(k=0;k<numGases;k+=1)
			if(k<numSampleGases && numtype(wOutputMeans[k][0])==0)
				fprintf f1, "%s,", wtParamValues[k]
				fprintf f1, "%s %s,", secs2date(wOutputTime[k][0],0), secs2time(wOutputTime[k][0],2)
				fprintf f1, "%g,%g,", wOutputMeans[k][8], wOutputStErrs[k][8]
				fprintf f1, "%g,%g,", wOutputMeans[k][10], wOutputStErrs[k][10]
				fprintf f1, "%g,%g,", wOutputMeans[k][11], wOutputStErrs[k][11]
				fprintf f1, "%g,%g,", wOutputMeans[k][2], wOutputStErrs[k][2]		
				fprintf f1, "%g,%g,", wOutputMeans[k][4], wOutputStErrs[k][4]
				fprintf f1, "%g,%g,", wOutputMeans[k][6], wOutputStErrs[k][6]
				fprintf f1, "%g,%g,", wOutputMeans[k][0], wOutputStErrs[k][0]
				fprintf f1, "\n"
			endif	
		endfor
		
		sCSVResults_L1 += sCSVResultsTemp_L1
		Close f1
	
		header = "Sample ID,Start time,CO2 MR,CO2 MR SE,Cell Pressure,Cell Pressure SE,Cell Temp,Cell Temp SE,d13C,d13C SE,d17O,d17O SE,d18O,d18O SE,D'17O,D'17O SE"
		Open/A/P=pResultsSubfolderPath f1 as sResultsFileSummaryCSV_L1L2 // if file already exists, we will append the new info to it (in case future code allows for reanalysis of data)
		fprintf f1, "%s\r\n", header
		sprintf sCSVResultsTemp_L1L2, "%s\r\n", header
	
		for(k=0;k<numGases;k+=1)
			if(k<numSampleGases && numtype(wOutputMeans[k][0])==0)
				fprintf f1, "%s,", wtParamValues[k]
				fprintf f1, "%s %s,", secs2date(wOutputTime[k][0],0), secs2time(wOutputTime[k][0],2)
				fprintf f1, "%g,%g,", wOutputMeans[k][8], wOutputStErrs[k][8]
				fprintf f1, "%g,%g,", wOutputMeans[k][10], wOutputStErrs[k][10]
				fprintf f1, "%g,%g,", wOutputMeans[k][11], wOutputStErrs[k][11]
				fprintf f1, "%g,%g,", wOutputMeans[k][3], wOutputStErrs[k][3]		
				fprintf f1, "%g,%g,", wOutputMeans[k][5], wOutputStErrs[k][5]
				fprintf f1, "%g,%g,", wOutputMeans[k][7], wOutputStErrs[k][7]
				fprintf f1, "%g,%g,", wOutputMeans[k][1], wOutputStErrs[k][1]		
				fprintf f1, "\n"
			endif	
		endfor
	
		sCSVResults_L1L2 += sCSVResultsTemp_L1L2
		Close f1
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
		header += "Name, Mean, SE, SD, Units"
		header += "\r\n----------------------------------------"
		Open/A/P=pResultsSubfolderPath f1 as sResultsFileTXT
		fprintf f1, "%s\r\n", header
		sprintf sTextResultsTemp, "%s\r\n", header
		sTextResults += sTextResultsTemp
		if(k<numSampleGases)
			for(i=0;i<numOutputVariables;i+=1)
				fprintf f1, "%s," + wtOutputVariableFormats[i] + "," + wtOutputVariableFormats[i] + "," + wtOutputVariableFormats[i] + ",%s\r\n", wtOutputVariableNames[i], wOutputMeans[k][i], wOutputStErrs[k][i], wOutputStDevs[k][i], wtOutputVariableUnits[i]
				sprintf sTextResultsTemp, "%s = " + wtOutputVariableFormats[i] + " ± " + wtOutputVariableFormats[i] + " (SD = " + wtOutputVariableFormats[i] + ") %s\r\n", wtOutputVariableNames[i], wOutputMeans[k][i], wOutputStErrs[k][i], wOutputStDevs[k][i], wtOutputVariableUnits[i]
				sTextResults += sTextResultsTemp
			endfor
		else
			for(ii=0;ii<numVariablesToAverage;ii+=1)
				i = wIndicesOfVariablesToAverage[ii]
				fprintf f1, "%s," + wtOutputVariableFormats[i] + "," + wtOutputVariableFormats[i] + "," + wtOutputVariableFormats[i] + ",%s\r\n", wtOutputVariableNames[i], wOutputMeans[k][i], wOutputStErrs[k][i], wOutputStDevs[k][i], wtOutputVariableUnits[i]
				sprintf sTextResultsTemp, "%s = " + wtOutputVariableFormats[i] + " ± " + wtOutputVariableFormats[i] + " (SD = " + wtOutputVariableFormats[i] + ") %s\r\n", wtOutputVariableNames[i], wOutputMeans[k][i], wOutputStErrs[k][i], wOutputStDevs[k][i], wtOutputVariableUnits[i]
				sTextResults += sTextResultsTemp
			endfor
		endif
		fprintf f1, "\r\n"
		sprintf sTextResultsTemp, "\r\n"
		sTextResults += sTextResultsTemp
		Close f1
	endfor
	header = "ALL SAMPLE GASES COLLECTIVELY\r\n"
	header += "\r\n"
	header += "Name, Mean, SE, SD, Units"
	header += "\r\n----------------------------------------"
	Open/A/P=pResultsSubfolderPath f1 as sResultsFileTXT
	fprintf f1, "%s\r\n", header
	sprintf sTextResultsTemp, "%s\r\n", header
	sTextResults += sTextResultsTemp
	for(i=0;i<numOutputVariables;i+=1)
		fprintf f1, "%s," + wtOutputVariableFormats[i] + "," + wtOutputVariableFormats[i] + "," + wtOutputVariableFormats[i] + ",%s\r\n", wtOutputVariableNames[i], wGroupOutputMeans[1][i], wGroupOutputStErrs[1][i], wGroupOutputStDevs[1][i], wtOutputVariableUnits[i]
		sprintf sTextResultsTemp, "%s = " + wtOutputVariableFormats[i] + " ± " + wtOutputVariableFormats[i] + " (SD = " + wtOutputVariableFormats[i] + ") %s\r\n", wtOutputVariableNames[i], wGroupOutputMeans[2][i], wGroupOutputStErrs[2][i], wGroupOutputStDevs[2][i], wtOutputVariableUnits[i]
		sTextResults += sTextResultsTemp
	endfor
	fprintf f1, "\r\n"
	sprintf sTextResultsTemp, "\r\n"
	sTextResults += sTextResultsTemp
	Close f1
	header = "ALL REF GASES COLLECTIVELY\r\n"
	header += "\r\n"
	header += "Name, Mean, SE, SD, Units"
	header += "\r\n----------------------------------------"
	Open/A/P=pResultsSubfolderPath f1 as sResultsFileTXT
	fprintf f1, "%s\r\n", header
	sprintf sTextResultsTemp, "%s\r\n", header
	sTextResults += sTextResultsTemp
	for(ii=0;ii<numVariablesToAverage;ii+=1)
		i = wIndicesOfVariablesToAverage[ii]
		fprintf f1, "%s," + wtOutputVariableFormats[i] + "," + wtOutputVariableFormats[i] + "," + wtOutputVariableFormats[i] + ",%s\r\n", wtOutputVariableNames[i], wGroupOutputMeans[2][i], wGroupOutputStErrs[2][i], wGroupOutputStDevs[2][i], wtOutputVariableUnits[i]
		sprintf sTextResultsTemp, "%s = " + wtOutputVariableFormats[i] + " ± " + wtOutputVariableFormats[i] + " (SD = " + wtOutputVariableFormats[i] + ") %s\r\n", wtOutputVariableNames[i], wGroupOutputMeans[2][i], wGroupOutputStErrs[2][i], wGroupOutputStDevs[2][i], wtOutputVariableUnits[i]
		sTextResults += sTextResultsTemp
	endfor
	fprintf f1, "\r\n"
	sprintf sTextResultsTemp, "\r\n"
	sTextResults += sTextResultsTemp
	Close f1
	
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
	string sWaveListStr = "wtParamNames;wtParamValues;wtParamUnits;wtParamTypes;"
	Save/J/B/A=2/DLIM=","/P=pResultsSubfolderPath sWaveListStr as sResultsFileTXT
	
	for(i=0;i<numpnts(wtParamNames);i+=1)
		sprintf sTextResultsTemp, "%s,%s,%s,%s\r\n", wtParamNames[i], wtParamValues[i], wtParamUnits[i], wtParamTypes[i]
		sTextResults += sTextResultsTemp
	endfor
	
	// Save results graphs as PNG files
	IRIS_UTILITY_MakeAndSaveGraphs()
	
	// Save all results together in a single PDF file
	IRIS_UTILITY_MakeAndSaveResultsLayout()
		
	// Report save status
	IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", secs2time(DateTime,3) + "  " + "Results saved in:")
	IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", "          " + sResultsSubfolderName)
	
	// Save status notebook as a text file
	SaveNotebook/O/S=6/P=pResultsSubfolderPath StatusNotebook as sStatusFileTXT
		
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
	string thisStringClip
//	string sTextResults_temp1, sTextResults_temp2
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
	
	// ... first the all-samples graphs...
	
	for(outputIndex=0;outputIndex<numOutputVariables;outputIndex+=1)
		
		sFileNameStr = sGraphsFileNameBaseNoExt + " - All Samples - Variable" + num2str(outputIndex) + ".png"
		sThisGraphName = "LayoutResultGraph_Samples_" + num2str(outputIndex)
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
	
	// ... then the all-refs graphs...
	
	for(ii=0;ii<numVariablesToAverage;ii+=1)
		outputIndex = wIndicesOfVariablesToAverage[ii]
		
		sFileNameStr = sGraphsFileNameBaseNoExt + " - All Refs - Variable" + num2str(outputIndex) + ".png"
		sThisGraphName = "LayoutResultGraph_Refs_" + num2str(outputIndex)
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
	
	// ... then the all-gases graphs...
	
	for(ii=0;ii<numVariablesToAverage;ii+=1)
		outputIndex = wIndicesOfVariablesToAverage[ii]
		
		sFileNameStr = sGraphsFileNameBaseNoExt + " - All Gases - Variable" + num2str(outputIndex) + ".png"
		sThisGraphName = "LayoutResultGraph_AllGases_" + num2str(outputIndex)
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
	
//	variable objectCount = 0
//	for(gasNum=0;gasNum<numGases;gasNum+=1)
//		if(gasNum < numSampleGases)
//			for(outputIndex=0;outputIndex<numOutputVariables;outputIndex+=1)
//				sFileNameStr = sGraphsFileNameBaseNoExt + " - Sample" + num2str(gasNum+1) + " - Variable" + num2str(outputIndex) + ".png"
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
//		else
//			for(ii=0;ii<numVariablesToAverage;ii+=1)
//				outputIndex = wIndicesOfVariablesToAverage[ii]
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
//		endif
//	endfor
	
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
	
	wave wSampleColorPalette = root:wSampleColorPalette
	wave wRefColorPalette = root:wRefColorPalette
	wave wSecondPlotColor = root:wSecondPlotColor
	
	NVAR numOutputVariables = root:numOutputVariables
	NVAR numVariablesToAverage = root:numVariablesToAverage
	wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
	wave/T wtOutputVariableNames = root:wtOutputVariableNames
	wave/T wtOutputVariableUnits = root:wtOutputVariableUnits
	
	SVAR sGraphsFileNameBaseNoExt = root:sGraphsFileNameBaseNoExt
	string sGraphsFilePNG
	string sGasLabel
	
	NVAR maxAxisLabelLength = root:maxAxisLabelLength
	
	KillWindow/Z IRISresultsGraphTemp
	
	// Make and save results graphs one at a time (only save 3 graphs for each variable: all gases, all samples, and all refs)...
	
	variable timeAxisMin
	variable timeAxisMax
	string sYaxisLabel
	variable outputIndex
	variable i, ii
	
	make/O/D/N=1 wTempDataWave, wTempErrorWave, wTempFilterWave, wTempTimeWave
	make/O/N=(1,3) wTempColorWave
	SetScale d 0,0,"dat", wTempTimeWave
	
	// ...first the all-samples graphs...
	
	for(outputIndex=0;outputIndex<numOutputVariables;outputIndex+=1)
		
		redimension/N=(wNumCompleteMeasurementsByGas[0]) wTempDataWave, wTempErrorWave, wTempFilterWave, wTempTimeWave
		wTempDataWave = wOutputTimeSeriesMatrix[0][outputIndex][p]
		wTempErrorWave = wOutputTimeSeriesErrorMatrix[0][outputIndex][p]
		wTempFilterWave = (wOutputTimeSeriesFilterMatrix[0][outputIndex][p] == 0) ? 19 : 8
		wTempTimeWave = wOutputTime[0][p]
		redimension/N=((wNumCompleteMeasurementsByGas[0]),3) wTempColorWave
		wTempColorWave[][0] = wSampleColorPalette[0][0]
		wTempColorWave[][1] = wSampleColorPalette[0][1]
		wTempColorWave[][2] = wSampleColorPalette[0][2]
		
		duplicate/O wTempDataWave, wMeanTemp
		duplicate/O wTempErrorWave, wErrorTemp
		duplicate/O wTempFilterWave, wFilterTemp
		duplicate/O wTempTimeWave, wTimeTemp
		duplicate/O wTempColorWave, wColorTemp
		
		if(numGases > 1)
			for(i=1;i<numSampleGases;i+=1)
				
				redimension/N=(wNumCompleteMeasurementsByGas[i]) wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp
				wMeanTemp = wOutputTimeSeriesMatrix[i][outputIndex][p]
				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][outputIndex][p]
				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][outputIndex][p] == 0) ? 19 : 8
				wTimeTemp = wOutputTime[i][p]
				redimension/N=((wNumCompleteMeasurementsByGas[i]),3) wColorTemp
				wColorTemp[][0] = wSampleColorPalette[mod(i,12)][0]
				wColorTemp[][1] = wSampleColorPalette[mod(i,12)][1]
				wColorTemp[][2] = wSampleColorPalette[mod(i,12)][2]
				
				concatenate/NP {wMeanTemp}, wTempDataWave
				concatenate/NP {wErrorTemp}, wTempErrorWave
				concatenate/NP {wFilterTemp}, wTempFilterWave
				concatenate/NP {wTimeTemp}, wTempTimeWave
				concatenate/NP=0 {wColorTemp}, wTempColorWave
				
			endfor
		endif
	
		timeAxisMin = wavemin(wTempTimeWave)
		timeAxisMax = wavemax(wTempTimeWave)
		
		killwaves wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp, wColorTemp
		
		sGraphsFilePNG = sGraphsFileNameBaseNoExt + " - All Samples - Variable" + num2str(outputIndex) + ".png"
		Display/N=IRISresultsGraphTemp/W=(tempGraphLeftEdge, tempGraphTopEdge, tempGraphLeftEdge + tempGraphWidth, tempGraphTopEdge + tempGraphHeight)/HIDE=1 wTempDataWave vs wTempTimeWave
		sYaxisLabel = wtOutputVariableNames[outputIndex] + " (" + wtOutputVariableUnits[outputIndex] + ")"
		if(strlen(sYaxisLabel) > maxAxisLabelLength)
			sYaxisLabel = wtOutputVariableNames[outputIndex] + "\r\n(" + wtOutputVariableUnits[outputIndex] + ")"
		endif
		sGasLabel = "\Z12All Samples"
		Label/W=IRISresultsGraphTemp Left sYaxisLabel
		Label/W=IRISresultsGraphTemp bottom " "
		ErrorBars/W=IRISresultsGraphTemp wTempDataWave Y, wave=(wTempErrorWave,wTempErrorWave)
		ModifyGraph/W=IRISresultsGraphTemp frameStyle = 0, fSize = 12
		ModifyGraph/W=IRISresultsGraphTemp lblMargin(left)=5
		ModifyGraph/W=IRISresultsGraphTemp mode=3, marker=19, rgb=(16385,28398,65535), msize = 5, mrkThick=2
		ModifyGraph/W=IRISresultsGraphTemp zColor(wTempDataWave)={wTempColorWave,*,*,directRGB,0}
		ModifyGraph/W=IRISresultsGraphTemp zmrkNum(wTempDataWave)={wTempFilterWave}
		ModifyGraph/W=IRISresultsGraphTemp axisEnab(left)={0,0.8}
		ModifyGraph standoff(bottom)=0
		TextBox/C/N=text0/F=0/B=1/A=LT sGasLabel
		SetAxis/W=IRISresultsGraphTemp/A
		SavePICT/WIN=IRISresultsGraphTemp/P=pResultsSubfolderPath/E=-5/RES=144 as sGraphsFilePNG
		KillWindow/Z IRISresultsGraphTemp
		
	endfor
	
	// ...then the all-refs graphs...
	
	for(ii=0;ii<numVariablesToAverage;ii+=1)
		outputIndex = wIndicesOfVariablesToAverage[ii]
		
		redimension/N=(wNumCompleteMeasurementsByGas[numSampleGases]) wTempDataWave, wTempErrorWave, wTempFilterWave, wTempTimeWave
		wTempDataWave = wOutputTimeSeriesMatrix[numSampleGases][outputIndex][p]
		wTempErrorWave = wOutputTimeSeriesErrorMatrix[numSampleGases][outputIndex][p]
		wTempFilterWave = (wOutputTimeSeriesFilterMatrix[numSampleGases][outputIndex][p] == 0) ? 19 : 8
		wTempTimeWave = wOutputTime[numSampleGases][p]
		redimension/N=((wNumCompleteMeasurementsByGas[numSampleGases]),3) wTempColorWave
		wTempColorWave[][0] = wRefColorPalette[0][0]
		wTempColorWave[][1] = wRefColorPalette[0][1]
		wTempColorWave[][2] = wRefColorPalette[0][2]
		
		duplicate/O wTempDataWave, wMeanTemp
		duplicate/O wTempErrorWave, wErrorTemp
		duplicate/O wTempFilterWave, wFilterTemp
		duplicate/O wTempTimeWave, wTimeTemp
		duplicate/O wTempColorWave, wColorTemp
		
		if(numRefGases > 1)
			for(i=(numSampleGases+1);i<numGases;i+=1)
				
				redimension/N=(wNumCompleteMeasurementsByGas[i]) wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp
				wMeanTemp = wOutputTimeSeriesMatrix[i][outputIndex][p]
				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][outputIndex][p]
				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][outputIndex][p] == 0) ? 19 : 8
				wTimeTemp = wOutputTime[i][p]
				redimension/N=((wNumCompleteMeasurementsByGas[i]),3) wColorTemp
				wColorTemp[][0] = wRefColorPalette[mod(i-numSampleGases,4)][0]
				wColorTemp[][1] = wRefColorPalette[mod(i-numSampleGases,4)][1]
				wColorTemp[][2] = wRefColorPalette[mod(i-numSampleGases,4)][2]
				
				concatenate/NP {wMeanTemp}, wTempDataWave
				concatenate/NP {wErrorTemp}, wTempErrorWave
				concatenate/NP {wFilterTemp}, wTempFilterWave
				concatenate/NP {wTimeTemp}, wTempTimeWave
				concatenate/NP=0 {wColorTemp}, wTempColorWave
				
			endfor
		endif
	
		timeAxisMin = wavemin(wTempTimeWave)
		timeAxisMax = wavemax(wTempTimeWave)
		
		killwaves wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp, wColorTemp
		
		sGraphsFilePNG = sGraphsFileNameBaseNoExt + " - All Refs - Variable" + num2str(outputIndex) + ".png"
		Display/N=IRISresultsGraphTemp/W=(tempGraphLeftEdge, tempGraphTopEdge, tempGraphLeftEdge + tempGraphWidth, tempGraphTopEdge + tempGraphHeight)/HIDE=1 wTempDataWave vs wTempTimeWave
		sYaxisLabel = wtOutputVariableNames[outputIndex] + " (" + wtOutputVariableUnits[outputIndex] + ")"
		if(strlen(sYaxisLabel) > maxAxisLabelLength)
			sYaxisLabel = wtOutputVariableNames[outputIndex] + "\r\n(" + wtOutputVariableUnits[outputIndex] + ")"
		endif
		sGasLabel = "\Z12All Refs"
		Label/W=IRISresultsGraphTemp Left sYaxisLabel
		Label/W=IRISresultsGraphTemp bottom " "
		ErrorBars/W=IRISresultsGraphTemp wTempDataWave Y, wave=(wTempErrorWave,wTempErrorWave)
		ModifyGraph/W=IRISresultsGraphTemp frameStyle = 0, fSize = 12
		ModifyGraph/W=IRISresultsGraphTemp lblMargin(left)=5
		ModifyGraph/W=IRISresultsGraphTemp mode=3, marker=19, rgb=(16385,28398,65535), msize = 5, mrkThick=2
		ModifyGraph/W=IRISresultsGraphTemp zColor(wTempDataWave)={wTempColorWave,*,*,directRGB,0}
		ModifyGraph/W=IRISresultsGraphTemp zmrkNum(wTempDataWave)={wTempFilterWave}
		ModifyGraph/W=IRISresultsGraphTemp axisEnab(left)={0,0.8}
		ModifyGraph standoff(bottom)=0
		TextBox/C/N=text0/F=0/B=1/A=LT sGasLabel
		SetAxis/W=IRISresultsGraphTemp/A
		SavePICT/WIN=IRISresultsGraphTemp/P=pResultsSubfolderPath/E=-5/RES=144 as sGraphsFilePNG
		KillWindow/Z IRISresultsGraphTemp
		
	endfor
	
	// ...then the all-gases graphs...
	
	for(ii=0;ii<numVariablesToAverage;ii+=1)
		outputIndex = wIndicesOfVariablesToAverage[ii]
		
		redimension/N=(wNumCompleteMeasurementsByGas[0]) wTempDataWave, wTempErrorWave, wTempFilterWave, wTempTimeWave
		wTempDataWave = wOutputTimeSeriesMatrix[0][outputIndex][p]
		wTempErrorWave = wOutputTimeSeriesErrorMatrix[0][outputIndex][p]
		wTempFilterWave = (wOutputTimeSeriesFilterMatrix[0][outputIndex][p] == 0) ? 19 : 8
		wTempTimeWave = wOutputTime[0][p]
		redimension/N=((wNumCompleteMeasurementsByGas[0]),3) wTempColorWave
		wTempColorWave[][0] = wSampleColorPalette[0][0]
		wTempColorWave[][1] = wSampleColorPalette[0][1]
		wTempColorWave[][2] = wSampleColorPalette[0][2]
		
		duplicate/O wTempDataWave, wMeanTemp
		duplicate/O wTempErrorWave, wErrorTemp
		duplicate/O wTempFilterWave, wFilterTemp
		duplicate/O wTempTimeWave, wTimeTemp
		duplicate/O wTempColorWave, wColorTemp
		
		if(numGases > 1)
			for(i=1;i<numSampleGases;i+=1)
				
				redimension/N=(wNumCompleteMeasurementsByGas[i]) wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp
				wMeanTemp = wOutputTimeSeriesMatrix[i][outputIndex][p]
				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][outputIndex][p]
				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][outputIndex][p] == 0) ? 19 : 8
				wTimeTemp = wOutputTime[i][p]
				redimension/N=((wNumCompleteMeasurementsByGas[i]),3) wColorTemp
				wColorTemp[][0] = wSampleColorPalette[mod(i,12)][0]
				wColorTemp[][1] = wSampleColorPalette[mod(i,12)][1]
				wColorTemp[][2] = wSampleColorPalette[mod(i,12)][2]
				
				concatenate/NP {wMeanTemp}, wTempDataWave
				concatenate/NP {wErrorTemp}, wTempErrorWave
				concatenate/NP {wFilterTemp}, wTempFilterWave
				concatenate/NP {wTimeTemp}, wTempTimeWave
				concatenate/NP=0 {wColorTemp}, wTempColorWave
				
			endfor
			
			for(i=numSampleGases;i<numGases;i+=1)
				
				redimension/N=(wNumCompleteMeasurementsByGas[i]) wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp
				wMeanTemp = wOutputTimeSeriesMatrix[i][outputIndex][p]
				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][outputIndex][p]
				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][outputIndex][p] == 0) ? 19 : 8
				wTimeTemp = wOutputTime[i][p]
				redimension/N=((wNumCompleteMeasurementsByGas[i]),3) wColorTemp
				wColorTemp[][0] = wRefColorPalette[mod(i-numSampleGases,4)][0]
				wColorTemp[][1] = wRefColorPalette[mod(i-numSampleGases,4)][1]
				wColorTemp[][2] = wRefColorPalette[mod(i-numSampleGases,4)][2]
				
				concatenate/NP {wMeanTemp}, wTempDataWave
				concatenate/NP {wErrorTemp}, wTempErrorWave
				concatenate/NP {wFilterTemp}, wTempFilterWave
				concatenate/NP {wTimeTemp}, wTempTimeWave
				concatenate/NP=0 {wColorTemp}, wTempColorWave
				
			endfor
			
		endif
	
		timeAxisMin = wavemin(wTempTimeWave)
		timeAxisMax = wavemax(wTempTimeWave)
		
		killwaves wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp, wColorTemp
		
		sGraphsFilePNG = sGraphsFileNameBaseNoExt + " - All Gases - Variable" + num2str(outputIndex) + ".png"
		Display/N=IRISresultsGraphTemp/W=(tempGraphLeftEdge, tempGraphTopEdge, tempGraphLeftEdge + tempGraphWidth, tempGraphTopEdge + tempGraphHeight)/HIDE=1 wTempDataWave vs wTempTimeWave
		sYaxisLabel = wtOutputVariableNames[outputIndex] + " (" + wtOutputVariableUnits[outputIndex] + ")"
		if(strlen(sYaxisLabel) > maxAxisLabelLength)
			sYaxisLabel = wtOutputVariableNames[outputIndex] + "\r\n(" + wtOutputVariableUnits[outputIndex] + ")"
		endif
		sGasLabel = "\Z12All Gases"
		Label/W=IRISresultsGraphTemp Left sYaxisLabel
		Label/W=IRISresultsGraphTemp bottom " "
		ErrorBars/W=IRISresultsGraphTemp wTempDataWave Y, wave=(wTempErrorWave,wTempErrorWave)
		ModifyGraph/W=IRISresultsGraphTemp frameStyle = 0, fSize = 12
		ModifyGraph/W=IRISresultsGraphTemp lblMargin(left)=5
		ModifyGraph/W=IRISresultsGraphTemp mode=3, marker=19, rgb=(16385,28398,65535), msize = 5, mrkThick=2
		ModifyGraph/W=IRISresultsGraphTemp zColor(wTempDataWave)={wTempColorWave,*,*,directRGB,0}
		ModifyGraph/W=IRISresultsGraphTemp zmrkNum(wTempDataWave)={wTempFilterWave}
		ModifyGraph/W=IRISresultsGraphTemp axisEnab(left)={0,0.8}
		ModifyGraph standoff(bottom)=0
		TextBox/C/N=text0/F=0/B=1/A=LT sGasLabel
		SetAxis/W=IRISresultsGraphTemp/A
		SavePICT/WIN=IRISresultsGraphTemp/P=pResultsSubfolderPath/E=-5/RES=144 as sGraphsFilePNG
		KillWindow/Z IRISresultsGraphTemp
		
	endfor
	
	killwaves wTempDataWave, wTempErrorWave, wTempFilterWave, wTempTimeWave
	
//	variable gasNum
//	variable timeAxisMin
//	variable timeAxisMax
//	string sYaxisLabel
//	variable outputIndex
//	variable ii
//	for(gasNum=0;gasNum<numGases;gasNum+=1)
//		make/O/D/N=(wNumCompleteMeasurementsByGas[gasNum]) wTempDataWave, wTempErrorWave, wTempFilterWave, wTempTimeWave
//		wTempTimeWave = wOutputTime[gasNum][p]
//		SetScale d 0,0,"dat", wTempTimeWave
//		timeAxisMin = wavemin(wTempTimeWave)
//		timeAxisMax = wavemax(wTempTimeWave)
//		if(gasNum < numSampleGases)
//			for(outputIndex=0;outputIndex<numOutputVariables;outputIndex+=1)
//				sGraphsFilePNG = sGraphsFileNameBaseNoExt + " - Sample" + num2str(gasNum+1) + " - Variable" + num2str(outputIndex) + ".png"
//				wTempDataWave = wOutputTimeSeriesMatrix[gasNum][outputIndex][p]
//				wTempErrorWave = wOutputTimeSeriesErrorMatrix[gasNum][outputIndex][p]
//				wTempFilterWave = (wOutputTimeSeriesFilterMatrix[gasNum][outputIndex][p] == 0) ? 19 : 8
//				Display/N=IRISresultsGraphTemp/W=(tempGraphLeftEdge, tempGraphTopEdge, tempGraphLeftEdge + tempGraphWidth, tempGraphTopEdge + tempGraphHeight)/HIDE=1 wTempDataWave vs wTempTimeWave
//				sYaxisLabel = wtOutputVariableNames[outputIndex] + " (" + wtOutputVariableUnits[outputIndex] + ")"
//				if(strlen(sYaxisLabel) > maxAxisLabelLength)
//					sYaxisLabel = wtOutputVariableNames[outputIndex] + "\r\n(" + wtOutputVariableUnits[outputIndex] + ")"
//				endif
//				sGasLabel = "\Z12Sample Gas " + num2str(gasNum + 1)
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
//		else
//			for(ii=0;ii<numVariablesToAverage;ii+=1)
//				outputIndex = wIndicesOfVariablesToAverage[ii]
//				sGraphsFilePNG = sGraphsFileNameBaseNoExt + " - Reference" + num2str(gasNum+1-numSampleGases) + " - Variable" + num2str(outputIndex) + ".png"
//				wTempDataWave = wOutputTimeSeriesMatrix[gasNum][outputIndex][p]
//				wTempErrorWave = wOutputTimeSeriesErrorMatrix[gasNum][outputIndex][p]
//				wTempFilterWave = (wOutputTimeSeriesFilterMatrix[gasNum][outputIndex][p] == 0) ? 19 : 8
//				Display/N=IRISresultsGraphTemp/W=(tempGraphLeftEdge, tempGraphTopEdge, tempGraphLeftEdge + tempGraphWidth, tempGraphTopEdge + tempGraphHeight)/HIDE=1 wTempDataWave vs wTempTimeWave
//				sYaxisLabel = wtOutputVariableNames[outputIndex] + " (" + wtOutputVariableUnits[outputIndex] + ")"
//				if(strlen(sYaxisLabel) > maxAxisLabelLength)
//					sYaxisLabel = wtOutputVariableNames[outputIndex] + "\r\n(" + wtOutputVariableUnits[outputIndex] + ")"
//				endif
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
//		endif
//		killwaves wTempDataWave, wTempErrorWave, wTempFilterWave, wTempTimeWave
//	endfor
	
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
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	NVAR numGases = root:numGases
	
	SVAR sConfigFileName = root:sConfigFileName
	
	// Load configuration parameters from config file on disk
	make/O/T/N=0 wtParamNames, wtParamValues, wtParamUnits, wtParamTypes
	string sColumnStr = "F=-2,N=wtParamNames;F=-2,N=wtParamValues;F=-2,N=wtParamUnits;F=-2,N=wtParamTypes;"
	Loadwave/Q/P=pIRISpath/J/N/L={0, 0, 0, 0, 0}/B=sColumnStr sConfigFileName // /L={nameLine, firstLine, numLines, firstColumn, numColumns}
	
	// Get number of sample gases and number of reference gases
	numSampleGases = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Sample Gases"))
	numRefGases = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Reference Gases"))
	numGases = numSampleGases + numRefGases
	
	// Propagate parameters to GUI tables
	if(numpnts(wtParamTypes) > 0) // in case the .iris file is from a version of IRIS before wtParamTypes was introduced
		IRIS_UTILITY_PropagateParamsToTables()
	endif
	
End

Function IRIS_UTILITY_SetParamNameValueAndUnits( i, param_name, param_value, param_units ) // OBSOLETE
	
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

Function IRIS_UTILITY_DefineParamsPrep()
	
	NVAR numGasParams = root:numGasParams
	NVAR numCalParams = root:numCalParams
	NVAR numBasicParams = root:numBasicParams
	NVAR numAdvancedParams = root:numAdvancedParams
	NVAR numFilterParams = root:numFilterParams
	NVAR paramIndexCount = root:paramIndexCount
	
	numGasParams = 0
	numCalParams = 0
	numBasicParams = 0
	numAdvancedParams = 0
	numFilterParams = 0
	paramIndexCount = 0
	
	make/O/T/N=0 wtParamNames, wtParamValues, wtParamUnits, wtParamTypes
	
End

Function IRIS_UTILITY_DefineParameter( param_name, param_value, param_units, param_type )
	
	string param_name, param_value, param_units, param_type
	
	NVAR paramIndexCount // needs to be declared in IRIS() and set to zero before the definition of params starts
	
	NVAR numGasParams = root:numGasParams
	NVAR numCalParams = root:numCalParams
	NVAR numBasicParams = root:numBasicParams
	NVAR numAdvancedParams = root:numAdvancedParams
	NVAR numFilterParams = root:numFilterParams
	
	wave/T wtParamNames = root:wtParamNames
	wave/T wtParamValues = root:wtParamValues
	wave/T wtParamUnits = root:wtParamUnits
	wave/T wtParamTypes = root:wtParamTypes
	
	if(exists("wtParamNames")==0)
		make/O/T/N=(paramIndexCount+1) wtParamNamesTemp, wtParamValuesTemp, wtParamUnitsTemp, wtParamTypesTemp
		Duplicate/O/T wtParamNamesTemp, wtParamNames
		Duplicate/O/T wtParamValuesTemp, wtParamValues
		Duplicate/O/T wtParamUnitsTemp, wtParamUnits
		Duplicate/O/T wtParamTypesTemp, wtParamTypes
		killwaves wtParamNamesTemp, wtParamValuesTemp, wtParamUnitsTemp, wtParamTypesTemp
	else
		if(numpnts(wtParamNames) <= paramIndexCount)
			redimension/N=(paramIndexCount+1) wtParamNames, wtParamValues, wtParamUnits, wtParamTypes
		endif
	endif
	
	wtParamNames[paramIndexCount] = param_name
	wtParamValues[paramIndexCount] = param_value
	wtParamUnits[paramIndexCount] = param_units
	wtParamTypes[paramIndexCount] = param_type
	
	paramIndexCount += 1
	
	if(cmpstr(param_type, "gas info") == 0)
		numGasParams += 1
	elseif(cmpstr(param_type, "calibration") == 0)
		numCalParams += 1
	elseif(cmpstr(param_type, "system basic") == 0)
		numBasicParams += 1
	elseif(cmpstr(param_type, "system advanced") == 0)
		numAdvancedParams += 1
	elseif(cmpstr(param_type, "filter") == 0)
		numFilterParams += 1
	endif
	
	return 0
	
End

Function IRIS_UTILITY_DefineParamsWrapUp()
	
	NVAR numOutputVariables = root:numOutputVariables
	wave/T wtOutputVariableNames = root:wtOutputVariableNames
	
	NVAR numGasParams = root:numGasParams
	NVAR numCalParams = root:numCalParams
	NVAR numBasicParams = root:numBasicParams
	NVAR numAdvancedParams = root:numAdvancedParams
	NVAR numFilterParams = root:numFilterParams
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	
	variable i
	
	// === DEFINE CALIBRATION PARAMETERS ===
	
	IRIS_UTILITY_DefineParameter( "Calibration Curve Equation", "c0*meas", "", "calibration" )
	
	// === DEFINE DATA FILTERING PARAMETERS ===
	
	for(i=0;i<numOutputVariables;i+=1)
		IRIS_UTILITY_DefineParameter( "Check " + wtOutputVariableNames[i] + " for Outliers?", "n", "(y/n)", "filter" )
		IRIS_UTILITY_DefineParameter( "Outlier Threshold for " + wtOutputVariableNames[i], "0", "standard deviations", "filter" )
		IRIS_UTILITY_DefineParameter( "Outlier Filter Group for " + wtOutputVariableNames[i], "1", "", "filter" )
	endfor
		
	// === DEFINE NUMBERS OF SAMPLE AND REF GASES ===
	
	IRIS_UTILITY_DefineParameter( "Number of Sample Gases", num2str(numSampleGases), "", "hidden" )
	IRIS_UTILITY_DefineParameter( "Number of Reference Gases", num2str(numRefGases), "", "hidden" )
	
	// === PROPAGATE PARAMETERS TO GUI TABLES ===
	
	IRIS_UTILITY_PropagateParamsToTables()
	
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
	wave/T wtParamTypes = root:wtParamTypes
	
	string saveFolder = GetDataFolder(1);
	SetDataFolder root:
	
	// Distinguishing gas info, calibration options, basic system options, advanced system options, and data filtering options
	
	Extract/O/INDX wtParamTypes, wtGasParamIndices, (cmpstr(wtParamTypes, "gas info") == 0)
	Extract/O/INDX wtParamTypes, wtCalParamIndices, (cmpstr(wtParamTypes, "calibration") == 0)
	Extract/O/INDX wtParamTypes, wtBasicParamIndices, (cmpstr(wtParamTypes, "system basic") == 0)
	Extract/O/INDX wtParamTypes, wtAdvancedParamIndices, (cmpstr(wtParamTypes, "system advanced") == 0)
	Extract/O/INDX wtParamTypes, wtFilterParamIndices, (cmpstr(wtParamTypes, "filter") == 0)
	
	numGasParams = numpnts(wtGasParamIndices)
	numCalParams = numpnts(wtCalParamIndices)
	numBasicParams = numpnts(wtBasicParamIndices)
	numAdvancedParams = numpnts(wtAdvancedParamIndices)
	numFilterParams = numpnts(wtFilterParamIndices)
	
	make/O/T/N=(numGasParams) wtGasParamNames, wtGasParamValues, wtGasParamUnits
	wtGasParamNames = wtParamNames[wtGasParamIndices[p]]
	wtGasParamValues = wtParamValues[wtGasParamIndices[p]]
	wtGasParamUnits = wtParamUnits[wtGasParamIndices[p]]
	
	calEqnStr_UI = IRIS_UTILITY_GetParamValueFromName("Calibration Curve Equation")
	IRIS_UTILITY_ValidateCalCurveEqn()
	
	make/O/T/N=(numBasicParams) wtBasicParamNames, wtBasicParamValues, wtBasicParamUnits
	wtBasicParamNames = wtParamNames[wtBasicParamIndices[p]]
	wtBasicParamValues = wtParamValues[wtBasicParamIndices[p]]
	wtBasicParamUnits = wtParamUnits[wtBasicParamIndices[p]]
	
	make/O/T/N=(numAdvancedParams) wtAdvParamNames, wtAdvParamValues, wtAdvParamUnits
	wtAdvParamNames = wtParamNames[wtAdvancedParamIndices[p]]
	wtAdvParamValues = wtParamValues[wtAdvancedParamIndices[p]]
	wtAdvParamUnits = wtParamUnits[wtAdvancedParamIndices[p]]
	
	make/O/T/N=(numFilterParams) wtFilterParamNames, wtFilterParamValues, wtFilterParamUnits
	wtFilterParamNames = wtParamNames[wtFilterParamIndices[p]]
	wtFilterParamValues = wtParamValues[wtFilterParamIndices[p]]
	wtFilterParamUnits = wtParamUnits[wtFilterParamIndices[p]]
	
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
	wave/T wtParamTypes = root:wtParamTypes
	wave/T wtGasParamNames = root:wtGasParamNames
	wave/T wtGasParamValues = root:wtGasParamValues
	wave/T wtGasParamUnits = root:wtGasParamUnits
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
	
	Extract/O/INDX wtParamTypes, wtGasParamIndices, (cmpstr(wtParamTypes, "gas info") == 0)
	Extract/O/INDX wtParamTypes, wtCalParamIndices, (cmpstr(wtParamTypes, "calibration") == 0)
	Extract/O/INDX wtParamTypes, wtBasicParamIndices, (cmpstr(wtParamTypes, "system basic") == 0)
	Extract/O/INDX wtParamTypes, wtAdvancedParamIndices, (cmpstr(wtParamTypes, "system advanced") == 0)
	Extract/O/INDX wtParamTypes, wtFilterParamIndices, (cmpstr(wtParamTypes, "filter") == 0)
	
	duplicate/O wtGasParamIndices, wTempIndexWave
	wTempIndexWave = p
	wtParamNames[wtGasParamIndices] = wtGasParamNames[wTempIndexWave]
	wtParamValues[wtGasParamIndices] = wtGasParamValues[wTempIndexWave]
	wtParamUnits[wtGasParamIndices] = wtGasParamUnits[wTempIndexWave]
	
	IRIS_UTILITY_SetParamValueByName( "Calibration Curve Equation", calEqnStr_UI )
	
//	duplicate/O wtBasicParamIndices, wTempIndexWave
//	wTempIndexWave = p
//	wtParamNames[wtBasicParamIndices] = wtBasicParamNames[wTempIndexWave]
//	wtParamValues[wtBasicParamIndices] = wtBasicParamValues[wTempIndexWave]
//	wtParamUnits[wtBasicParamIndices] = wtBasicParamUnits[wTempIndexWave]
//	
//	duplicate/O wtAdvancedParamIndices, wTempIndexWave
//	wTempIndexWave = p
//	wtParamNames[wtAdvancedParamIndices] = wtAdvParamNames[wTempIndexWave]
//	wtParamValues[wtAdvancedParamIndices] = wtAdvParamValues[wTempIndexWave]
//	wtParamUnits[wtAdvancedParamIndices] = wtAdvParamUnits[wTempIndexWave]
//	
//	duplicate/O wtFilterParamIndices, wTempIndexWave
//	wTempIndexWave = p
//	wtParamNames[wtFilterParamIndices] = wtFilterParamNames[wTempIndexWave]
//	wtParamValues[wtFilterParamIndices] = wtFilterParamValues[wTempIndexWave]
//	wtParamUnits[wtFilterParamIndices] = wtFilterParamUnits[wTempIndexWave]
	
	variable i
	for(i=0;i<numBasicParams;i+=1)
		wtParamNames[wtBasicParamIndices[i]] = wtBasicParamNames[i]
		wtParamValues[wtBasicParamIndices[i]] = wtBasicParamValues[i]
		wtParamUnits[wtBasicParamIndices[i]] = wtBasicParamUnits[i]
	endfor
	
	for(i=0;i<numAdvancedParams;i+=1)
		wtParamNames[wtAdvancedParamIndices[i]] = wtAdvParamNames[i]
		wtParamValues[wtAdvancedParamIndices[i]] = wtAdvParamValues[i]
		wtParamUnits[wtAdvancedParamIndices[i]] = wtAdvParamUnits[i]
	endfor
	
	for(i=0;i<numFilterParams;i+=1)
		wtParamNames[wtFilterParamIndices[i]] = wtFilterParamNames[i]
		wtParamValues[wtFilterParamIndices[i]] = wtFilterParamValues[i]
		wtParamUnits[wtFilterParamIndices[i]] = wtFilterParamUnits[i]
	endfor
	
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
	
	variable refFollowsSample = (stringMatch( IRIS_UTILITY_GetParamValueFromName("Ref Follows Sample"), "y*" ) == 1) ? 1 : 0 // 0 = no, 1 = yes
	
	wave stc_ECL_index = root:stc_ECL_index
	variable stcLength = numpnts(stc_ECL_index)
		
	duplicate/O wRefIndices, wRefIndicesFound
	
	if(refFollowsSample == 1)
		
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
		
	else
		
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
		
	endif
	
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
	
	wave wOutputMeanToGraph1 = root:wOutputMeanToGraph1
	wave wOutputErrorToGraph1 = root:wOutputErrorToGraph1
	wave wOutputFilterToGraph1 = root:wOutputFilterToGraph1
	wave wOutputTimeToGraph1 = root:wOutputTimeToGraph1
	wave wOutputMeanToGraph2 = root:wOutputMeanToGraph2
	wave wOutputErrorToGraph2 = root:wOutputErrorToGraph2
	wave wOutputFilterToGraph2 = root:wOutputFilterToGraph2
	wave wOutputTimeToGraph2 = root:wOutputTimeToGraph2
	
	wave wOutputColorToGraph1 = root:wOutputColorToGraph1
	
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
			wNumCompleteMeasurementsByGas[sampleNum] = 0
		else
			sIRIStemp = "ECL_" + num2str(wSampleIndices[sampleNum]) + "_StartTime"
			wNumCompleteMeasurementsByGas[sampleNum] = numpnts(root:ECL_WorkFolder_A:$sIRIStemp)
		endif
	endfor
	
	for(refNum=0;refNum<numRefGases;refNum+=1)
		thisIndexIsAbsent = IRIS_ECL_ParseAndCutIndex(wRefIndices[refNum], tidyup = 1, FirstLineIsStart = 0, LastLineIsStop = 0, SummaryTable = 0)	
		if(thisIndexIsAbsent > 0)
			wNumCompleteMeasurementsByGas[numSampleGases + refNum] = 0
		else
			sIRIStemp = "ECL_" + num2str(wRefIndices[refNum]) + "_StartTime"
			wNumCompleteMeasurementsByGas[numSampleGases + refNum] = numpnts(root:ECL_WorkFolder_A:$sIRIStemp)
		endif
	endfor
	
//	// TEMP HACK FOR MAKING A GRAPH... // TESTING!!!
//	wNumCompleteMeasurementsByGas[0] = 10
//	wNumCompleteMeasurementsByGas[1] = 11
	
	variable maxNumCompleteMeasurementsAcrossAllGases = wavemax(wNumCompleteMeasurementsByGas)
	variable maxNumCompleteMeasurementsAcrossAllSampleGases = wavemax(wNumCompleteMeasurementsByGas,0,numSampleGases-1)
	
	if(maxNumCompleteMeasurementsAcrossAllSampleGases == 0)
		SetDataFolder $saveFolder
		return 1
	endif
	
	// Add any new elements to results waves/matrices
	
	redimension/N=(numGases,numOutputVariables,maxNumCompleteMeasurementsAcrossAllGases) wOutputTimeSeriesMatrix, wOutputTimeSeriesErrorMatrix, wOutputTimeSeriesFilterMatrix
	redimension/N=(numGases,maxNumCompleteMeasurementsAcrossAllGases) wOutputTime
	redimension/N=(maxNumCompleteMeasurementsAcrossAllGases) wOutputMeanToGraph1, wOutputErrorToGraph1, wOutputFilterToGraph1, wOutputTimeToGraph1
	redimension/N=(maxNumCompleteMeasurementsAcrossAllGases) wOutputMeanToGraph2, wOutputErrorToGraph2, wOutputFilterToGraph2, wOutputTimeToGraph2
	redimension/N=((maxNumCompleteMeasurementsAcrossAllGases),3) wOutputColorToGraph1
	
	SetDataFolder $saveFolder
	return 0
			
End

Function IRIS_UTILITY_CollateDataFilterSettings()
	
	NVAR numOutputVariables = root:numOutputVariables
	wave wOutputTimeSeriesFilterMatrix = root:wOutputTimeSeriesFilterMatrix
	
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
	
	wOutputTimeSeriesFilterMatrix[][][] = 0 // reset data filtering so that it can be judged afresh given all the data points now available
	
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
		killwaves/Z root:$sSimpleCalName
	endfor
	
	// Data filtering (apply filtering due to any variable in the same filter group)
	
	IRIS_UTILITY_ApplyDataFilters() // the cell fill means, SE, and SD are calculated in here
	
	// Calculate stats for all gases, all samples, all refs
	
	IRIS_UTILITY_CalculateGasGroupOutputVariableStats()
	
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
	
	wave wNumCompleteMeasurementsByGas = root:wNumCompleteMeasurementsByGas
	
	NVAR numGases = root:numGases
	NVAR numVariablesToAverage = root:numVariablesToAverage
	
	variable gasNum
	variable i, outputIndex, rescaleFactor, assignToDiagnosticOutputNumber
	
	string sTimeName, sDataName
	
	sTimeName = "str_source_rtime"
	for(gasNum=0;gasNum<numGases;gasNum+=1)
		if(wNumCompleteMeasurementsByGas[gasNum] > 0)
			IRIS_UTILITY_CalculateGasFillTimes(sTimeName, gasNum)
		endif
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
			if(wNumCompleteMeasurementsByGas[gasNum] > 0)
				IRIS_UTILITY_CalculateGasFillMeansForOneVariable(sDataName, sTimeName, gasNum, outputIndex, rescaleFactor)
			endif
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
	
	variable numOutputPoints
	variable i
	
	numOutputPoints = wNumCompleteMeasurementsByGas[gasNum]
	
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

Function IRIS_UTILITY_CalibrateSampleVariableViaRefs(sDataName, sampleNum, wRefIndices, wTrueRefValuesOnStandardScale, outputIndex, rescaleFactor)
	string sDataName
	variable sampleNum
	wave wRefIndices
	wave wTrueRefValuesOnStandardScale
	variable outputIndex
	variable rescaleFactor
	
	// This structure might seem inefficient, as the ref cal curve will be recalculated again for each sample;
	// however, it is necessary because the ref values depend on the sample time to which they are interpolated.
	
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
	
	variable refFollowsSample = (stringMatch( IRIS_UTILITY_GetParamValueFromName("Ref Follows Sample"), "y*" ) == 1) ? 1 : 0 // 0 = no, 1 = yes
	
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
	
	string ECL_refIndex
	variable numSampleTimes
	
	if(refFollowsSample == 1)
		
		// Use the ref measurement that follows soonest after the sample measurement...
		numSampleTimes = numpnts(wSample_time)
		Make/N=(numSampleTimes)/D/O wRefInterpTemp, wCalResultRelativeToStandardScale
		for(i=0;i<numRefGases;i+=1)
			ECL_refIndex = num2str(wRefIndices[i])
			sprintf sRef_rawValue, "ECL_%s_%s_Avg", ECL_refIndex, sDataName
			sprintf sRef_time, "ECL_%s_MidTime", ECL_refIndex
			sRef_interpValue = "wRef" + num2str(i+1) + "_interpValue"
			wave/Z wRef_rawValue = root:ECL_WorkFolder_A:$sRef_rawValue
			wave/Z wRef_time = root:ECL_WorkFolder_A:$sRef_time
			if( WaveExists( wRef_rawValue ) != 1 )
				printf "In function IRIS_UTILITY_CalibrateSampleVariableViaRefs, wave %s not found, aborting\r", sRef_rawValue
				SetDataFolder $saveFolder
				return -1;
			endif
			for(j=0;j<numSampleTimes;j+=1)
				if(wSample_time[j] < wRef_time[0])
					wRefInterpTemp[j] = wRef_rawValue[0] // use first ref measurement for any samples that precede it
				else
					FindLevel/Q/P wRef_time, wSample_time[j]
					wRefInterpTemp[j] = wRef_rawValue[ceil(V_LevelX)] // use the ref measurement that follows soonest after the sample measurement
				endif
			endfor			
			Duplicate/O wRefInterpTemp, root:$sRef_interpValue
		endfor
		killwaves wRefInterpTemp
		
	else
		
		// Interpolate ref(s) onto sample time grid...
		numSampleTimes = numpnts(wSample_time)
		Make/N=(numSampleTimes)/D/O wRefInterpTemp, wCalResultRelativeToStandardScale
		for(i=0;i<numRefGases;i+=1)
			ECL_refIndex = num2str(wRefIndices[i])
			sprintf sRef_rawValue, "ECL_%s_%s_Avg", ECL_refIndex, sDataName
			sprintf sRef_time, "ECL_%s_MidTime", ECL_refIndex
			sRef_interpValue = "wRef" + num2str(i+1) + "_interpValue"
			wave/Z wRef_rawValue = root:ECL_WorkFolder_A:$sRef_rawValue
			wave/Z wRef_time = root:ECL_WorkFolder_A:$sRef_time
			if( WaveExists( wRef_rawValue ) != 1 )
				printf "In function IRIS_UTILITY_CalibrateSampleVariableViaRefs, wave %s not found, aborting\r", sRef_rawValue
				SetDataFolder $saveFolder
				return -1;
			endif
			wRefInterpTemp = interp( wSample_time[p], wRef_time, wRef_rawValue ) // avoid spline because if there's a bad sample or ref, error propagates farther into neighbors than it would with simple linear interpolation
	//		if(numpnts(wRef_time) < 4) // can't do a cubic spline with fewer than 4 points
	//			wRefInterpTemp = interp( wSample_time[p], wRef_time, wRef_rawValue )
	//		else
	//			interpolate2/E=2/T=2/I=3/X=wSample_time/Y=wRefInterpTemp wRef_time, wRef_rawValue // natural cubic spline interpolation
	//		endif
			Duplicate/O wRefInterpTemp, root:$sRef_interpValue
		endfor
		killwaves wRefInterpTemp
		
	endif
	
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

Function IRIS_UTILITY_CalculateGasGroupOutputVariableStats()
	
	// NOTE: the gas groups are: 0 = all gases, 1 = all samples, 2 = all refs
	
	string saveFolder = GetDataFolder(1);
	SetDataFolder root:
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	NVAR numGases = root:numGases
	NVAR numVariablesToAverage = root:numVariablesToAverage
	
	NVAR numOutputVariables = root:numOutputVariables
	
	NVAR minPointsForOutlierFiltering = root:minPointsForOutlierFiltering
	
	wave wGroupOutputMeans = root:wGroupOutputMeans
	wave wGroupOutputStDevs = root:wGroupOutputStDevs
	wave wGroupOutputStErrs = root:wGroupOutputStErrs
	
	wave wOutputTimeSeriesMatrix = root:wOutputTimeSeriesMatrix // wOutputTimeSeriesMatrix[gasNum][outputVariable][outputPoint]
	wave wOutputTimeSeriesErrorMatrix = root:wOutputTimeSeriesErrorMatrix
	wave wOutputTimeSeriesFilterMatrix = root:wOutputTimeSeriesFilterMatrix
	
	wave wNumCompleteMeasurementsByGas = root:wNumCompleteMeasurementsByGas
	
	wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
	
	variable gasNum, varNum, otherVarNum, ii
	variable meanTemp, sdTemp
	variable highBound, lowBound
	variable currentPossibleOutlierIndex, currentPossibleOutlierValue
	variable numOutputPoints
	
	make/O/D/N=0 IRIS_wTemp, wFilterWave
	make/O/D/N=0 IRIS_wTempSub, wFilterWaveSub
	
	for(varNum=0;varNum<numOutputVariables;varNum+=1)
	
		// All sample gases
		
		redimension/N=0 IRIS_wTemp, wFilterWave
		for(gasNum=0;gasNum<numSampleGases;gasNum+=1)
			numOutputPoints = wNumCompleteMeasurementsByGas[gasNum]
			redimension/N=(numOutputPoints) IRIS_wTempSub, wFilterWaveSub
			IRIS_wTempSub = wOutputTimeSeriesMatrix[gasNum][varNum][p]
			wFilterWaveSub = wOutputTimeSeriesFilterMatrix[gasNum][varNum][p]
			concatenate/NP {IRIS_wTempSub}, IRIS_wTemp
			concatenate/NP {wFilterWaveSub}, wFilterWave
		endfor
		
		Extract/O IRIS_wTemp, IRIS_wTemp_Filtered, (wFilterWave != 1)
		meanTemp = mean(IRIS_wTemp_Filtered)
		sdTemp = sqrt(variance(IRIS_wTemp_Filtered))
		wGroupOutputMeans[1][varNum] = meanTemp
		wGroupOutputStDevs[1][varNum] = sdTemp
		wGroupOutputStErrs[1][varNum] = sdTemp/sqrt(numpnts(IRIS_wTemp_Filtered))
		
	endfor
	
	for(ii=0;ii<numVariablesToAverage;ii+=1)
		varNum = wIndicesOfVariablesToAverage[ii]
		
		// All ref gases
		
		redimension/N=0 IRIS_wTemp, wFilterWave
		for(gasNum=0;gasNum<numRefGases;gasNum+=1)
			numOutputPoints = wNumCompleteMeasurementsByGas[numSampleGases + gasNum]
			redimension/N=(numOutputPoints) IRIS_wTempSub, wFilterWaveSub
			IRIS_wTempSub = wOutputTimeSeriesMatrix[numSampleGases + gasNum][varNum][p]
			wFilterWaveSub = wOutputTimeSeriesFilterMatrix[numSampleGases + gasNum][varNum][p]
			concatenate/NP {IRIS_wTempSub}, IRIS_wTemp
			concatenate/NP {wFilterWaveSub}, wFilterWave
		endfor
		
		Extract/O IRIS_wTemp, IRIS_wTemp_Filtered, (wFilterWave != 1)
		meanTemp = mean(IRIS_wTemp_Filtered)
		sdTemp = sqrt(variance(IRIS_wTemp_Filtered))
		wGroupOutputMeans[2][varNum] = meanTemp
		wGroupOutputStDevs[2][varNum] = sdTemp
		wGroupOutputStErrs[2][varNum] = sdTemp/sqrt(numpnts(IRIS_wTemp_Filtered))
		
		// All gases
		
		redimension/N=0 IRIS_wTemp, wFilterWave
		for(gasNum=0;gasNum<numGases;gasNum+=1)
			numOutputPoints = wNumCompleteMeasurementsByGas[gasNum]
			redimension/N=(numOutputPoints) IRIS_wTempSub, wFilterWaveSub
			IRIS_wTempSub = wOutputTimeSeriesMatrix[gasNum][varNum][p]
			wFilterWaveSub = wOutputTimeSeriesFilterMatrix[gasNum][varNum][p]
			concatenate/NP {IRIS_wTempSub}, IRIS_wTemp
			concatenate/NP {wFilterWaveSub}, wFilterWave
		endfor
		
		Extract/O IRIS_wTemp, IRIS_wTemp_Filtered, (wFilterWave != 1)
		meanTemp = mean(IRIS_wTemp_Filtered)
		sdTemp = sqrt(variance(IRIS_wTemp_Filtered))
		wGroupOutputMeans[0][varNum] = meanTemp
		wGroupOutputStDevs[0][varNum] = sdTemp
		wGroupOutputStErrs[0][varNum] = sdTemp/sqrt(numpnts(IRIS_wTemp_Filtered))
		
	endfor
	
	killwaves IRIS_wTemp, wFilterWave
	killwaves IRIS_wTempSub, wFilterWaveSub
	killwaves IRIS_wTemp_Filtered
		
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
	
	wave wGroupOutputMeans = root:wGroupOutputMeans
	wave wGroupOutputStDevs = root:wGroupOutputStDevs
	wave wGroupOutputStErrs = root:wGroupOutputStErrs
	
	wave/T wtOutputVariableUnits = root:wtOutputVariableUnits
	wave/T wtOutputVariableFormats = root:wtOutputVariableFormats
	
	string sOutput_gasID = "output" + num2str(numericDisplayNum) + "_gasID"
	NVAR output_gasID = root:$sOutput_gasID
	
	string sOutput_variableID = "output" + num2str(numericDisplayNum) + "_variableID"
	NVAR output_variableID = root:$sOutput_variableID
	
	if(output_gasID > 2) // individual sample or ref gas
		
		wDisplayMeans[numericDisplayNum - 1] = wOutputMeans[output_gasID-3][output_variableID]
		wDisplayStDevs[numericDisplayNum - 1] = wOutputStDevs[output_gasID-3][output_variableID]
		wDisplayStErrs[numericDisplayNum - 1] = wOutputStErrs[output_gasID-3][output_variableID]
		
	else // all gases (=0), all sample gases (=1), or all ref gases (=2)
		
		wDisplayMeans[numericDisplayNum - 1] = wGroupOutputMeans[output_gasID][output_variableID]
		wDisplayStDevs[numericDisplayNum - 1] = wGroupOutputStDevs[output_gasID][output_variableID]
		wDisplayStErrs[numericDisplayNum - 1] = wGroupOutputStErrs[output_gasID][output_variableID]
		
	endif
	
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
	
	wave wOutputColorToGraph1 = root:wOutputColorToGraph1
	
	wave wSampleColorPalette = root:wSampleColorPalette
	wave wRefColorPalette = root:wRefColorPalette
	wave wSecondPlotColor = root:wSecondPlotColor
	
	NVAR gasToGraph1 = root:gasToGraph1
	NVAR variableToGraph1 = root:variableToGraph1
	NVAR gasToGraph2 = root:gasToGraph2
	NVAR variableToGraph2 = root:variableToGraph2
	NVAR showSecondPlotOnGraph = root:showSecondPlotOnGraph
	NVAR useSeparateGraphAxis = root:useSeparateGraphAxis
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	NVAR numGases = root:numGases
	
	NVAR maxAxisLabelLength = root:maxAxisLabelLength
	
	variable i
	
	// Output variable
	if((gasToGraph1 > 2) && (gasToGraph1 < numSampleGases + 3)) // individual sample gas
	
		redimension/N=(wNumCompleteMeasurementsByGas[gasToGraph1 - 3]) wOutputMeanToGraph1, wOutputErrorToGraph1, wOutputFilterToGraph1, wOutputTimeToGraph1
		wOutputMeanToGraph1 = wOutputTimeSeriesMatrix[gasToGraph1 - 3][variableToGraph1][p]
		wOutputErrorToGraph1 = wOutputTimeSeriesErrorMatrix[gasToGraph1 - 3][variableToGraph1][p]
		wOutputFilterToGraph1 = (wOutputTimeSeriesFilterMatrix[gasToGraph1 - 3][variableToGraph1][p] == 0) ? 19 : 8
		wOutputTimeToGraph1 = wOutputTime[gasToGraph1 - 3][p]
		redimension/N=((wNumCompleteMeasurementsByGas[gasToGraph1 - 3]),3) wOutputColorToGraph1
		wOutputColorToGraph1[][0] = wSampleColorPalette[mod(gasToGraph1-3,12)][0]
		wOutputColorToGraph1[][1] = wSampleColorPalette[mod(gasToGraph1-3,12)][1]
		wOutputColorToGraph1[][2] = wSampleColorPalette[mod(gasToGraph1-3,12)][2]
		
	elseif(gasToGraph1 > numSampleGases + 2) // individual ref gas
	
		redimension/N=(wNumCompleteMeasurementsByGas[gasToGraph1 - 3]) wOutputMeanToGraph1, wOutputErrorToGraph1, wOutputFilterToGraph1, wOutputTimeToGraph1
		wOutputMeanToGraph1 = wOutputTimeSeriesMatrix[gasToGraph1 - 3][variableToGraph1][p]
		wOutputErrorToGraph1 = wOutputTimeSeriesErrorMatrix[gasToGraph1 - 3][variableToGraph1][p]
		wOutputFilterToGraph1 = (wOutputTimeSeriesFilterMatrix[gasToGraph1 - 3][variableToGraph1][p] == 0) ? 19 : 8
		wOutputTimeToGraph1 = wOutputTime[gasToGraph1 - 3][p]
		redimension/N=((wNumCompleteMeasurementsByGas[gasToGraph1 - 3]),3) wOutputColorToGraph1
		wOutputColorToGraph1[][0] = wRefColorPalette[mod(gasToGraph1-3-numSampleGases,12)][0]
		wOutputColorToGraph1[][1] = wRefColorPalette[mod(gasToGraph1-3-numSampleGases,12)][1]
		wOutputColorToGraph1[][2] = wRefColorPalette[mod(gasToGraph1-3-numSampleGases,12)][2]
		
	elseif(gasToGraph1 == 0) // all gases
		
		redimension/N=(wNumCompleteMeasurementsByGas[0]) wOutputMeanToGraph1, wOutputErrorToGraph1, wOutputFilterToGraph1, wOutputTimeToGraph1
		wOutputMeanToGraph1 = wOutputTimeSeriesMatrix[0][variableToGraph1][p]
		wOutputErrorToGraph1 = wOutputTimeSeriesErrorMatrix[0][variableToGraph1][p]
		wOutputFilterToGraph1 = (wOutputTimeSeriesFilterMatrix[0][variableToGraph1][p] == 0) ? 19 : 8
		wOutputTimeToGraph1 = wOutputTime[0][p]
		redimension/N=((wNumCompleteMeasurementsByGas[0]),3) wOutputColorToGraph1
		wOutputColorToGraph1[][0] = wSampleColorPalette[0][0]
		wOutputColorToGraph1[][1] = wSampleColorPalette[0][1]
		wOutputColorToGraph1[][2] = wSampleColorPalette[0][2]
		
		duplicate/O wOutputMeanToGraph1, wMeanTemp
		duplicate/O wOutputErrorToGraph1, wErrorTemp
		duplicate/O wOutputFilterToGraph1, wFilterTemp
		duplicate/O wOutputTimeToGraph1, wTimeTemp
		duplicate/O wOutputColorToGraph1, wColorTemp
		
		if(numGases > 1)
			for(i=1;i<numSampleGases;i+=1)
				
				redimension/N=(wNumCompleteMeasurementsByGas[i]) wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp
				wMeanTemp = wOutputTimeSeriesMatrix[i][variableToGraph1][p]
				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][variableToGraph1][p]
				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][variableToGraph1][p] == 0) ? 19 : 8
				wTimeTemp = wOutputTime[i][p]
				redimension/N=((wNumCompleteMeasurementsByGas[i]),3) wColorTemp
				wColorTemp[][0] = wSampleColorPalette[mod(i,12)][0]
				wColorTemp[][1] = wSampleColorPalette[mod(i,12)][1]
				wColorTemp[][2] = wSampleColorPalette[mod(i,12)][2]
				
				concatenate/NP {wMeanTemp}, wOutputMeanToGraph1
				concatenate/NP {wErrorTemp}, wOutputErrorToGraph1
				concatenate/NP {wFilterTemp}, wOutputFilterToGraph1
				concatenate/NP {wTimeTemp}, wOutputTimeToGraph1
				concatenate/NP=0 {wColorTemp}, wOutputColorToGraph1
				
			endfor
			
			for(i=numSampleGases;i<numGases;i+=1)
				
				redimension/N=(wNumCompleteMeasurementsByGas[i]) wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp
				wMeanTemp = wOutputTimeSeriesMatrix[i][variableToGraph1][p]
				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][variableToGraph1][p]
				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][variableToGraph1][p] == 0) ? 19 : 8
				wTimeTemp = wOutputTime[i][p]
				redimension/N=((wNumCompleteMeasurementsByGas[i]),3) wColorTemp
				wColorTemp[][0] = wRefColorPalette[mod(i-numSampleGases,4)][0]
				wColorTemp[][1] = wRefColorPalette[mod(i-numSampleGases,4)][1]
				wColorTemp[][2] = wRefColorPalette[mod(i-numSampleGases,4)][2]
				
				concatenate/NP {wMeanTemp}, wOutputMeanToGraph1
				concatenate/NP {wErrorTemp}, wOutputErrorToGraph1
				concatenate/NP {wFilterTemp}, wOutputFilterToGraph1
				concatenate/NP {wTimeTemp}, wOutputTimeToGraph1
				concatenate/NP=0 {wColorTemp}, wOutputColorToGraph1
				
			endfor
		endif
		
		killwaves wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp, wColorTemp
		
	elseif(gasToGraph1 == 1) // all samples
		
		redimension/N=(wNumCompleteMeasurementsByGas[0]) wOutputMeanToGraph1, wOutputErrorToGraph1, wOutputFilterToGraph1, wOutputTimeToGraph1
		wOutputMeanToGraph1 = wOutputTimeSeriesMatrix[0][variableToGraph1][p]
		wOutputErrorToGraph1 = wOutputTimeSeriesErrorMatrix[0][variableToGraph1][p]
		wOutputFilterToGraph1 = (wOutputTimeSeriesFilterMatrix[0][variableToGraph1][p] == 0) ? 19 : 8
		wOutputTimeToGraph1 = wOutputTime[0][p]
		redimension/N=((wNumCompleteMeasurementsByGas[0]),3) wOutputColorToGraph1
		wOutputColorToGraph1[][0] = wSampleColorPalette[0][0]
		wOutputColorToGraph1[][1] = wSampleColorPalette[0][1]
		wOutputColorToGraph1[][2] = wSampleColorPalette[0][2]
		
		duplicate/O wOutputMeanToGraph1, wMeanTemp
		duplicate/O wOutputErrorToGraph1, wErrorTemp
		duplicate/O wOutputFilterToGraph1, wFilterTemp
		duplicate/O wOutputTimeToGraph1, wTimeTemp
		duplicate/O wOutputColorToGraph1, wColorTemp
		
		if(numSampleGases > 1)
			for(i=1;i<numSampleGases;i+=1)
				
				redimension/N=(wNumCompleteMeasurementsByGas[i]) wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp
				wMeanTemp = wOutputTimeSeriesMatrix[i][variableToGraph1][p]
				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][variableToGraph1][p]
				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][variableToGraph1][p] == 0) ? 19 : 8
				wTimeTemp = wOutputTime[i][p]
				redimension/N=((wNumCompleteMeasurementsByGas[i]),3) wColorTemp
				wColorTemp[][0] = wSampleColorPalette[mod(i,12)][0]
				wColorTemp[][1] = wSampleColorPalette[mod(i,12)][1]
				wColorTemp[][2] = wSampleColorPalette[mod(i,12)][2]
				
				concatenate/NP {wMeanTemp}, wOutputMeanToGraph1
				concatenate/NP {wErrorTemp}, wOutputErrorToGraph1
				concatenate/NP {wFilterTemp}, wOutputFilterToGraph1
				concatenate/NP {wTimeTemp}, wOutputTimeToGraph1
				concatenate/NP=0 {wColorTemp}, wOutputColorToGraph1
				
			endfor
		endif
		
		killwaves wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp, wColorTemp
		
	elseif(gasToGraph1 == 2) // all refs
		
		redimension/N=(wNumCompleteMeasurementsByGas[numSampleGases]) wOutputMeanToGraph1, wOutputErrorToGraph1, wOutputFilterToGraph1, wOutputTimeToGraph1
		wOutputMeanToGraph1 = wOutputTimeSeriesMatrix[numSampleGases][variableToGraph1][p]
		wOutputErrorToGraph1 = wOutputTimeSeriesErrorMatrix[numSampleGases][variableToGraph1][p]
		wOutputFilterToGraph1 = (wOutputTimeSeriesFilterMatrix[numSampleGases][variableToGraph1][p] == 0) ? 19 : 8
		wOutputTimeToGraph1 = wOutputTime[numSampleGases][p]
		redimension/N=((wNumCompleteMeasurementsByGas[numSampleGases]),3) wOutputColorToGraph1
		wOutputColorToGraph1[][0] = wRefColorPalette[0][0]
		wOutputColorToGraph1[][1] = wRefColorPalette[0][1]
		wOutputColorToGraph1[][2] = wRefColorPalette[0][2]
		
		duplicate/O wOutputMeanToGraph1, wMeanTemp
		duplicate/O wOutputErrorToGraph1, wErrorTemp
		duplicate/O wOutputFilterToGraph1, wFilterTemp
		duplicate/O wOutputTimeToGraph1, wTimeTemp
		duplicate/O wOutputColorToGraph1, wColorTemp
		
		if(numRefGases > 1)
			for(i=(numSampleGases+1);i<numGases;i+=1)
				
				redimension/N=(wNumCompleteMeasurementsByGas[i]) wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp
				wMeanTemp = wOutputTimeSeriesMatrix[i][variableToGraph1][p]
				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][variableToGraph1][p]
				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][variableToGraph1][p] == 0) ? 19 : 8
				wTimeTemp = wOutputTime[i][p]
				redimension/N=((wNumCompleteMeasurementsByGas[i]),3) wColorTemp
				wColorTemp[][0] = wRefColorPalette[mod(i-numSampleGases,4)][0]
				wColorTemp[][1] = wRefColorPalette[mod(i-numSampleGases,4)][1]
				wColorTemp[][2] = wRefColorPalette[mod(i-numSampleGases,4)][2]
				
				concatenate/NP {wMeanTemp}, wOutputMeanToGraph1
				concatenate/NP {wErrorTemp}, wOutputErrorToGraph1
				concatenate/NP {wFilterTemp}, wOutputFilterToGraph1
				concatenate/NP {wTimeTemp}, wOutputTimeToGraph1
				concatenate/NP=0 {wColorTemp}, wOutputColorToGraph1
				
			endfor
		endif
		
		killwaves wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp, wColorTemp
		
	endif
	
//	if(gasToGraph1 > 2) // individual sample or ref gas
//		
//		redimension/N=(wNumCompleteMeasurementsByGas[gasToGraph1 - 3]) wOutputMeanToGraph1, wOutputErrorToGraph1, wOutputFilterToGraph1, wOutputTimeToGraph1
//		wOutputMeanToGraph1 = wOutputTimeSeriesMatrix[gasToGraph1 - 3][variableToGraph1][p]
//		wOutputErrorToGraph1 = wOutputTimeSeriesErrorMatrix[gasToGraph1 - 3][variableToGraph1][p]
//		wOutputFilterToGraph1 = (wOutputTimeSeriesFilterMatrix[gasToGraph1 - 3][variableToGraph1][p] == 0) ? 19 : 8
//		wOutputTimeToGraph1 = wOutputTime[gasToGraph1 - 3][p]
//		
//	elseif(gasToGraph1 == 0) // all gases
//		
//		redimension/N=(wNumCompleteMeasurementsByGas[0]) wOutputMeanToGraph1, wOutputErrorToGraph1, wOutputFilterToGraph1, wOutputTimeToGraph1
//		wOutputMeanToGraph1 = wOutputTimeSeriesMatrix[0][variableToGraph1][p]
//		wOutputErrorToGraph1 = wOutputTimeSeriesErrorMatrix[0][variableToGraph1][p]
//		wOutputFilterToGraph1 = (wOutputTimeSeriesFilterMatrix[0][variableToGraph1][p] == 0) ? 19 : 8
//		wOutputTimeToGraph1 = wOutputTime[0][p]
//		
//		duplicate/O wOutputMeanToGraph1, wMeanTemp
//		duplicate/O wOutputErrorToGraph1, wErrorTemp
//		duplicate/O wOutputFilterToGraph1, wFilterTemp
//		duplicate/O wOutputTimeToGraph1, wTimeTemp
//		
//		if(numGases > 1)
//			for(i=1;i<numGases;i+=1)
//				
//				redimension/N=(wNumCompleteMeasurementsByGas[i]) wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp
//				wMeanTemp = wOutputTimeSeriesMatrix[i][variableToGraph1][p]
//				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][variableToGraph1][p]
//				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][variableToGraph1][p] == 0) ? 19 : 8
//				wTimeTemp = wOutputTime[i][p]
//				
//				concatenate/NP {wMeanTemp}, wOutputMeanToGraph1
//				concatenate/NP {wErrorTemp}, wOutputErrorToGraph1
//				concatenate/NP {wFilterTemp}, wOutputFilterToGraph1
//				concatenate/NP {wTimeTemp}, wOutputTimeToGraph1
//				
//			endfor
//		endif
//		
//		killwaves wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp
//		
//	elseif(gasToGraph1 == 1) // all samples
//		
//		redimension/N=(wNumCompleteMeasurementsByGas[0]) wOutputMeanToGraph1, wOutputErrorToGraph1, wOutputFilterToGraph1, wOutputTimeToGraph1
//		wOutputMeanToGraph1 = wOutputTimeSeriesMatrix[0][variableToGraph1][p]
//		wOutputErrorToGraph1 = wOutputTimeSeriesErrorMatrix[0][variableToGraph1][p]
//		wOutputFilterToGraph1 = (wOutputTimeSeriesFilterMatrix[0][variableToGraph1][p] == 0) ? 19 : 8
//		wOutputTimeToGraph1 = wOutputTime[0][p]
//		
//		duplicate/O wOutputMeanToGraph1, wMeanTemp
//		duplicate/O wOutputErrorToGraph1, wErrorTemp
//		duplicate/O wOutputFilterToGraph1, wFilterTemp
//		duplicate/O wOutputTimeToGraph1, wTimeTemp
//		
//		if(numSampleGases > 1)
//			for(i=1;i<numSampleGases;i+=1)
//				
//				redimension/N=(wNumCompleteMeasurementsByGas[i]) wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp
//				wMeanTemp = wOutputTimeSeriesMatrix[i][variableToGraph1][p]
//				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][variableToGraph1][p]
//				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][variableToGraph1][p] == 0) ? 19 : 8
//				wTimeTemp = wOutputTime[i][p]
//				
//				concatenate/NP {wMeanTemp}, wOutputMeanToGraph1
//				concatenate/NP {wErrorTemp}, wOutputErrorToGraph1
//				concatenate/NP {wFilterTemp}, wOutputFilterToGraph1
//				concatenate/NP {wTimeTemp}, wOutputTimeToGraph1
//				
//			endfor
//		endif
//		
//		killwaves wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp
//		
//	elseif(gasToGraph1 == 2) // all refs
//		
//		redimension/N=(wNumCompleteMeasurementsByGas[numSampleGases]) wOutputMeanToGraph1, wOutputErrorToGraph1, wOutputFilterToGraph1, wOutputTimeToGraph1
//		wOutputMeanToGraph1 = wOutputTimeSeriesMatrix[numSampleGases][variableToGraph1][p]
//		wOutputErrorToGraph1 = wOutputTimeSeriesErrorMatrix[numSampleGases][variableToGraph1][p]
//		wOutputFilterToGraph1 = (wOutputTimeSeriesFilterMatrix[numSampleGases][variableToGraph1][p] == 0) ? 19 : 8
//		wOutputTimeToGraph1 = wOutputTime[numSampleGases][p]
//		
//		duplicate/O wOutputMeanToGraph1, wMeanTemp
//		duplicate/O wOutputErrorToGraph1, wErrorTemp
//		duplicate/O wOutputFilterToGraph1, wFilterTemp
//		duplicate/O wOutputTimeToGraph1, wTimeTemp
//		
//		if(numRefGases > 1)
//			for(i=(numSampleGases+1);i<numGases;i+=1)
//				
//				redimension/N=(wNumCompleteMeasurementsByGas[i]) wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp
//				wMeanTemp = wOutputTimeSeriesMatrix[i][variableToGraph1][p]
//				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][variableToGraph1][p]
//				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][variableToGraph1][p] == 0) ? 19 : 8
//				wTimeTemp = wOutputTime[i][p]
//				
//				concatenate/NP {wMeanTemp}, wOutputMeanToGraph1
//				concatenate/NP {wErrorTemp}, wOutputErrorToGraph1
//				concatenate/NP {wFilterTemp}, wOutputFilterToGraph1
//				concatenate/NP {wTimeTemp}, wOutputTimeToGraph1
//				
//			endfor
//		endif
//		
//		killwaves wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp
//		
//	endif
	
	if(gasToGraph2 > 2) // individual sample or ref gas
		
		redimension/N=(wNumCompleteMeasurementsByGas[gasToGraph2 - 3]) wOutputMeanToGraph2, wOutputErrorToGraph2, wOutputFilterToGraph2, wOutputTimeToGraph2
		wOutputMeanToGraph2 = wOutputTimeSeriesMatrix[gasToGraph2 - 3][variableToGraph2][p]
		wOutputErrorToGraph2 = wOutputTimeSeriesErrorMatrix[gasToGraph2 - 3][variableToGraph2][p]
		wOutputFilterToGraph2 = (wOutputTimeSeriesFilterMatrix[gasToGraph2 - 3][variableToGraph2][p] == 0) ? 19 : 8
		wOutputTimeToGraph2 = wOutputTime[gasToGraph2 - 3][p]
		
	elseif(gasToGraph2 == 0) // all gases
		
		redimension/N=(wNumCompleteMeasurementsByGas[0]) wOutputMeanToGraph2, wOutputErrorToGraph2, wOutputFilterToGraph2, wOutputTimeToGraph2
		wOutputMeanToGraph2 = wOutputTimeSeriesMatrix[0][variableToGraph2][p]
		wOutputErrorToGraph2 = wOutputTimeSeriesErrorMatrix[0][variableToGraph2][p]
		wOutputFilterToGraph2 = (wOutputTimeSeriesFilterMatrix[0][variableToGraph2][p] == 0) ? 19 : 8
		wOutputTimeToGraph2 = wOutputTime[0][p]
		
		duplicate/O wOutputMeanToGraph2, wMeanTemp
		duplicate/O wOutputErrorToGraph2, wErrorTemp
		duplicate/O wOutputFilterToGraph2, wFilterTemp
		duplicate/O wOutputTimeToGraph2, wTimeTemp
		
		if(numGases > 1)
			for(i=1;i<numGases;i+=1)
				
				redimension/N=(wNumCompleteMeasurementsByGas[i]) wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp
				wMeanTemp = wOutputTimeSeriesMatrix[i][variableToGraph2][p]
				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][variableToGraph2][p]
				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][variableToGraph2][p] == 0) ? 19 : 8
				wTimeTemp = wOutputTime[i][p]
				
				concatenate/NP {wMeanTemp}, wOutputMeanToGraph2
				concatenate/NP {wErrorTemp}, wOutputErrorToGraph2
				concatenate/NP {wFilterTemp}, wOutputFilterToGraph2
				concatenate/NP {wTimeTemp}, wOutputTimeToGraph2
				
			endfor
		endif
		
		killwaves wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp
		
	elseif(gasToGraph2 == 1) // all samples
		
		redimension/N=(wNumCompleteMeasurementsByGas[0]) wOutputMeanToGraph2, wOutputErrorToGraph2, wOutputFilterToGraph2, wOutputTimeToGraph2
		wOutputMeanToGraph2 = wOutputTimeSeriesMatrix[0][variableToGraph2][p]
		wOutputErrorToGraph2 = wOutputTimeSeriesErrorMatrix[0][variableToGraph2][p]
		wOutputFilterToGraph2 = (wOutputTimeSeriesFilterMatrix[0][variableToGraph2][p] == 0) ? 19 : 8
		wOutputTimeToGraph2 = wOutputTime[0][p]
		
		duplicate/O wOutputMeanToGraph2, wMeanTemp
		duplicate/O wOutputErrorToGraph2, wErrorTemp
		duplicate/O wOutputFilterToGraph2, wFilterTemp
		duplicate/O wOutputTimeToGraph2, wTimeTemp
		
		if(numSampleGases > 1)
			for(i=1;i<numSampleGases;i+=1)
				
				redimension/N=(wNumCompleteMeasurementsByGas[i]) wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp
				wMeanTemp = wOutputTimeSeriesMatrix[i][variableToGraph2][p]
				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][variableToGraph2][p]
				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][variableToGraph2][p] == 0) ? 19 : 8
				wTimeTemp = wOutputTime[i][p]
				
				concatenate/NP {wMeanTemp}, wOutputMeanToGraph2
				concatenate/NP {wErrorTemp}, wOutputErrorToGraph2
				concatenate/NP {wFilterTemp}, wOutputFilterToGraph2
				concatenate/NP {wTimeTemp}, wOutputTimeToGraph2
				
			endfor
		endif
		
		killwaves wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp
		
	elseif(gasToGraph2 == 2) // all refs
		
		redimension/N=(wNumCompleteMeasurementsByGas[numSampleGases]) wOutputMeanToGraph2, wOutputErrorToGraph2, wOutputFilterToGraph2, wOutputTimeToGraph2
		wOutputMeanToGraph2 = wOutputTimeSeriesMatrix[numSampleGases][variableToGraph2][p]
		wOutputErrorToGraph2 = wOutputTimeSeriesErrorMatrix[numSampleGases][variableToGraph2][p]
		wOutputFilterToGraph2 = (wOutputTimeSeriesFilterMatrix[numSampleGases][variableToGraph2][p] == 0) ? 19 : 8
		wOutputTimeToGraph2 = wOutputTime[numSampleGases][p]
		
		duplicate/O wOutputMeanToGraph2, wMeanTemp
		duplicate/O wOutputErrorToGraph2, wErrorTemp
		duplicate/O wOutputFilterToGraph2, wFilterTemp
		duplicate/O wOutputTimeToGraph2, wTimeTemp
		
		if(numRefGases > 1)
			for(i=(numSampleGases+1);i<numGases;i+=1)
				
				redimension/N=(wNumCompleteMeasurementsByGas[i]) wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp
				wMeanTemp = wOutputTimeSeriesMatrix[i][variableToGraph2][p]
				wErrorTemp = wOutputTimeSeriesErrorMatrix[i][variableToGraph2][p]
				wFilterTemp = (wOutputTimeSeriesFilterMatrix[i][variableToGraph2][p] == 0) ? 19 : 8
				wTimeTemp = wOutputTime[i][p]
				
				concatenate/NP {wMeanTemp}, wOutputMeanToGraph2
				concatenate/NP {wErrorTemp}, wOutputErrorToGraph2
				concatenate/NP {wFilterTemp}, wOutputFilterToGraph2
				concatenate/NP {wTimeTemp}, wOutputTimeToGraph2
				
			endfor
		endif
		
		killwaves wMeanTemp, wErrorTemp, wFilterTemp, wTimeTemp
		
	endif
	
	string sYaxisLabel1, sYaxisLabel2, sYaxisLabel
	DoWindow IRISpanel
	if(V_flag > 0)
		if(showSecondPlotOnGraph == 1)
			if(useSeparateGraphAxis == 1)
				sYaxisLabel1 = wtOutputVariableNames[variableToGraph1] + " (" + wtOutputVariableUnits[variableToGraph1] + ")"
				if(strlen(sYaxisLabel1) > maxAxisLabelLength)
					sYaxisLabel1 = wtOutputVariableNames[variableToGraph1] + "\r\n(" + wtOutputVariableUnits[variableToGraph1] + ")"
				endif
				Label/W=IRISpanel#ResultGraph Left sYaxisLabel1
				sYaxisLabel2 = wtOutputVariableNames[variableToGraph2] + " (" + wtOutputVariableUnits[variableToGraph2] + ")"
				if(strlen(sYaxisLabel2) > maxAxisLabelLength)
					sYaxisLabel2 = wtOutputVariableNames[variableToGraph2] + "\r\n(" + wtOutputVariableUnits[variableToGraph2] + ")"
				endif
				Label/W=IRISpanel#ResultGraph Right sYaxisLabel2
			else
				sYaxisLabel1 = wtOutputVariableNames[variableToGraph1] + " (" + wtOutputVariableUnits[variableToGraph1] + ")"
				if(strlen(sYaxisLabel1) > maxAxisLabelLength)
					sYaxisLabel1 = wtOutputVariableNames[variableToGraph1] + "\r\n(" + wtOutputVariableUnits[variableToGraph1] + ")"
				endif
//				sYaxisLabel1 = "\K(16385,28398,65535)" + sYaxisLabel1
				sYaxisLabel2 = wtOutputVariableNames[variableToGraph2] + " (" + wtOutputVariableUnits[variableToGraph2] + ")"
				if(strlen(sYaxisLabel2) > maxAxisLabelLength)
					sYaxisLabel2 = wtOutputVariableNames[variableToGraph2] + "\r\n(" + wtOutputVariableUnits[variableToGraph2] + ")"
				endif
				sYaxisLabel2 = "\K(30583,30583,30583)" + sYaxisLabel2
				sYaxisLabel = sYaxisLabel1 + "\r\n" + sYaxisLabel2
				Label/W=IRISpanel#ResultGraph Left sYaxisLabel
			endif
		else
			sYaxisLabel = wtOutputVariableNames[variableToGraph1] + " (" + wtOutputVariableUnits[variableToGraph1] + ")"
			if(strlen(sYaxisLabel) > maxAxisLabelLength)
				sYaxisLabel = wtOutputVariableNames[variableToGraph1] + "\r\n(" + wtOutputVariableUnits[variableToGraph1] + ")"
			endif
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
	
	NVAR maxAxisLabelLength = root:maxAxisLabelLength
	
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
		if(strlen(sYaxisLabel) > maxAxisLabelLength)
			sYaxisLabel = diagnosticOutput1_name + "\r\n(" + diagnosticOutput1_units + ")"
		endif
		Label/W=IRIS_DiagnosticGraph Left sYaxisLabel
		sYaxisLabel = diagnosticOutput2_name + " (" + diagnosticOutput2_units + ")"
		if(strlen(sYaxisLabel) > maxAxisLabelLength)
			sYaxisLabel = diagnosticOutput2_name + "\r\n(" + diagnosticOutput2_units + ")"
		endif
		Label/W=IRIS_DiagnosticGraph Left2 sYaxisLabel
		sYaxisLabel = diagnosticOutput3_name + " (" + diagnosticOutput3_units + ")"
		if(strlen(sYaxisLabel) > maxAxisLabelLength)
			sYaxisLabel = diagnosticOutput3_name + "\r\n(" + diagnosticOutput3_units + ")"
		endif
		Label/W=IRIS_DiagnosticGraph Left3 sYaxisLabel
	endif
	
	DoUpdate
	
End

Function IRIS_UTILITY_UpdateNumGasesInTables()
	
	wave/T wtParamNames = root:wtParamNames
	wave/T wtParamValues = root:wtParamValues
	wave/T wtParamUnits = root:wtParamUnits
	wave/T wtParamTypes = root:wtParamTypes
	
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
	SVAR sBuildScheduleFunctionName = root:sBuildScheduleFunctionName
	
	variable i
	variable numTabulatedParams = numGasParams + numCalParams + numBasicParams + numAdvancedParams + numFilterParams
	
	if( (numSampleGases != numSampleGases_prev) || (numRefGases != numRefGases_prev) )
		
		// Set aside a copy of the current config params names and values
		Duplicate/O/T wtParamNames, wtParamNames_old
		Duplicate/O/T wtParamValues, wtParamValues_old
	
		// Redefine the config params based on the new numSampleGases and/or numRefGases (all params will get default values for the moment)
		FUNCREF IRIS_UTILITY_ProtoFunc IRIS_ParamFunction = $sParamFunctionName
		IRIS_UTILITY_DefineParamsPrep()
		IRIS_ParamFunction() // calls IRIS_SCHEME_DefineParams_XXXXX(), where XXXXX is the instrument type
		IRIS_UTILITY_DefineParamsWrapUp()
		
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
		string sWaveListStr = "wtParamNames;wtParamValues;wtParamUnits;wtParamTypes;"
		Save/O/J/DLIM=","/B/P=pIRISpath sWaveListStr as sConfigFileName
		
		// Propagate the new config params to the GUI tables
		IRIS_UTILITY_PropagateParamsToTables()
	
		// Create generic labels for the sample and reference gases to be measured 
		numGases = numSampleGases + numRefGases
		make/O/N=(numGases) wNumCompleteMeasurementsByGas = 0 //1 // temporary value
		make/O/T/N=(numGases + 3) wtOutputGasNames
		wtOutputGasNames[0] = "ALL"
		wtOutputGasNames[1] = "ALL S"
		wtOutputGasNames[2] = "ALL R"
		for(i=0;i<numSampleGases;i+=1)
			wtOutputGasNames[i+3] = "S" + num2str(i+1)
		endfor
		for(i=0;i<numRefGases;i+=1)
			wtOutputGasNames[numSampleGases+i+3] = "R" + num2str(i+1)
		endfor
		
		// Ensure the displays are not set to display a gas that no longer exists
		// NOTE: there are numGases + 3 settings, the extra 3 being ALL (all gases), Ss (all samples), and Rs (all refs)
		output1_gasID = min(output1_gasID, numGases + 2)
		output2_gasID = min(output2_gasID, numGases + 2)
		output3_gasID = min(output3_gasID, numGases + 2)
		gasToGraph1 = min(gasToGraph1, numGases + 2)
		gasToGraph2 = min(gasToGraph2, numGases + 2)
		PopupMenu/Z IRIS_GasChoice1_tabRunOrReanalyze, win = IRISpanel, mode = output1_gasID + 1, value = IRIS_GUI_PopupWaveList_Gas()
		PopupMenu/Z IRIS_GasChoice2_tabRunOrReanalyze, win = IRISpanel, mode = output2_gasID + 1, value = IRIS_GUI_PopupWaveList_Gas()
		PopupMenu/Z IRIS_GasChoice3_tabRunOrReanalyze, win = IRISpanel, mode = output3_gasID + 1, value = IRIS_GUI_PopupWaveList_Gas()
		PopupMenu/Z IRIS_PlotGasChoice1_tabRunOrReanalyze, win = IRISpanel, mode = gasToGraph1 + 1, value = IRIS_GUI_PopupWaveList_Gas()
		PopupMenu/Z IRIS_PlotGasChoice2_tabRunOrReanalyze, win = IRISpanel, mode = gasToGraph2 + 1, value = IRIS_GUI_PopupWaveList_Gas()
	
		// Create waves of means, standard deviations, and standard errors of the output variables, for the numeric displays
		make/O/D/N=(numGases,numOutputVariables) wOutputMeans, wOutputStDevs, wOutputStErrs
		wOutputMeans[][] = NaN
		wOutputStDevs[][] = NaN
		wOutputStErrs[][] = NaN
		
		// Create waves of means, standard deviations, and standard errors of the output variables for groups of gases (0 = all gases, 1 = all sample gases, 2 = all ref gases)
		make/O/D/N=(3,numOutputVariables) wGroupOutputMeans, wGroupOutputStDevs, wGroupOutputStErrs
		wGroupOutputMeans[][] = NaN
		wGroupOutputStDevs[][] = NaN
		wGroupOutputStErrs[][] = NaN
		
		// Create matrix of time series of output variables
		variable numAliquots = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Aliquots per Sample"))
		if(numType(numAliquots) != 0) // in case DefineParams function does not specify Number of Aliquots per Sample
			numAliquots = 1
		endif
		variable numCycles = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Cycles"))
		if(numType(numCycles) != 0) // in case DefineParams function does not specify Number of Cycles
			numCycles = 1
		endif
		make/O/D/N=(numGases,numOutputVariables,numAliquots*numCycles) wOutputTimeSeriesMatrix, wOutputTimeSeriesErrorMatrix, wOutputTimeSeriesFilterMatrix
		make/O/D/N=(numGases,numAliquots*numCycles) wOutputTime
		wOutputTimeSeriesMatrix[][][] = NaN
		wOutputTimeSeriesErrorMatrix[][][] = NaN
		wOutputTimeSeriesFilterMatrix[][][] = 0
		wOutputTime = q + 1
	
		// Updating the prev variables
		numSampleGases_prev = numSampleGases
		numRefGases_prev = numRefGases
		
		// Rebuild schedule
		FUNCREF IRIS_UTILITY_ProtoFunc IRIS_BuildScheduleFunction = $sBuildScheduleFunctionName
		IRIS_BuildScheduleFunction() // calls IRIS_SCHEME_BuildSchedule_XXXXX(), where XXXXX is the instrument type	
		
		DoUpdate
		
	endif
	
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

Function [wave i12CH4_local, wave i13CH4_local, wave CH3D_local] IRIS_UTILITY_ConvertFrom_d13C_d2H(wave CH4_local, wave d13C_local, wave d2H_local)
	
	// The computed isotopologue mole fractions will all be inflated by the same small factor
   // due to the omission of unmeasured isotopologues from the calculation. That error will
   // exactly cancel out when converting back to deltas.
   
	variable R13_vpdb = 0.0111797
	variable R2_vsmow = 0.00015576
	
	//		We assume there is no clumping (analogously to Wehr et al 2013 Appendix A for CO2)...
	//		First find the fractions of C that are 12C and 13C:
	//		f12 = 1/(1 + R13C)
	//		f13 = R13C*f12
	//		And the fractions of H that are 1H and 2H:
	//		f1 = 1/(1 + R2)
	//		f2 = R2*f1
	//		Then calculate the isotopologue mixing ratios assuming no clumping:
	//		i12CH4_random = CH4*f12*f1*f1*f1*f1
	//		i13CH4_random = CH4*f13*f1*f1*f1*f1
	//		CH3D_random = CH4*4*f12*f1*f1*f1*f2 // factor of 4 is because there are 4 identical hydrogen sites in CH4 (and so what we call CH3D is really CHHHD + CHHDH + CHDHH + CDHHH)
   
   make/O/D/N=(numpnts(CH4_local)) R13C_temp, R2H_temp
	make/O/D/N=(numpnts(CH4_local)) f12_temp, f13_temp, f1_temp, f2_temp
	
	R13C_temp = R13_vpdb*(d13C_local/1000 + 1)
	R2H_temp = R2_vsmow*(d2H_local/1000 + 1)
	f12_temp = 1/(1 + R13C_temp)
	f13_temp = R13C_temp*f12_temp
	f1_temp = 1/(1 + R2H_temp)
	f2_temp = R2H_temp*f1_temp
	
	i12CH4_local = CH4_local*f12_temp*f1_temp*f1_temp*f1_temp*f1_temp
	i13CH4_local = CH4_local*f13_temp*f1_temp*f1_temp*f1_temp*f1_temp
	CH3D_local = CH4_local*4*(f12_temp*f1_temp*f1_temp*f1_temp*f2_temp) // factor of 4 is because there are 4 identical hydrogen sites in CH4 (and so what we call CH3D is really CHHHD + CHHDH + CHDHH + CDHHH)
	
	killwaves R13C_temp, R2H_temp
	killwaves f12_temp, f13_temp, f1_temp, f2_temp
	
	
	
End

Function [wave CH4_local, wave d13C_local, wave d2H_local] IRIS_UTILITY_ConvertTo_d13C_d2H(wave i12CH4_local, wave i13CH4_local, wave CH3D_local)
	
	variable R13_vpdb = 0.0111797
	variable R2_vsmow = 0.00015576
	
	make/O/D/N=(numpnts(i12CH4_local)) R13C_temp, R2H_temp
	
	R13C_temp = i13CH4_local/i12CH4_local
	R2H_temp = CH3D_local/(4*i12CH4_local) // factor of 4 is because there are 4 indistinguishable hydrogen sites in CH4 (and so what we call CH3D is really CHHHD + CHHDH + CHDHH + CDHHH)
	
	d13C_local = 1000*((R13C_temp/R13_vpdb) - 1)
	d2H_local = 1000*((R2H_temp/R2_vsmow) - 1)
	
	// All possible stable isotopologues written such that sites matter: (12CH4 + CHHHD + CHHDH + CHDHH + CDHHH)*(1 + 13C/12C)
	// All possible stable isotopologues written such that sites do not matter (i.e. such that CH3D = CHHHD + CHHDH + CHDHH + CDHHH): (12CH4 + CH3D)*(1 + 13C/12C)
	CH4_local = (i12CH4_local + CH3D_local)*(1 + R13C_temp)
   	
	killwaves R13C_temp, R2H_temp
	
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
//	NVAR azaInitialValveState = root:azaInitialValveState
	NVAR azaOpeningTimer = root:azaOpeningTimer
	NVAR azaValve = root:azaValve
	
	wave wValveStates = root:Wintel_Status:wintcp_valveCurrentState
	
	string azaValveString
	variable preByte, postByte
	
	if(developmentMode == 0)
		if(strlen(sCommand) > 0)
			if((stringmatch(sCommand, "aza*") == 1) || (stringmatch(sCommand, "azb*") == 1))
				azaInProgress = 1
				azaValveHasTriggered = 0
				preByte = strsearch(sCommand, ",", 0)
				postByte = strsearch(sCommand, ",", preByte + 1)
				azaValveString = sCommand[preByte+1, postByte-1]
				azaValve = str2num(azaValveString)
				if(stringmatch(sCommand, "azb*") == 1)
					azaValve -= 1 // azb counts valves from 1 but behind the scenes, TDL Wintel still counts them from 0
				endif
//				azaInitialValveState = wValveStates[azaValve]
				azaOpeningTimer = DateTime
				print "aza or azb starting, valve = " + num2str(azaValve+1)
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
	
	wave/T wStatusCategoryNames = root:wStatusCategoryNames
	wave/T wStatusStrings = root:wStatusStrings
		
	if(strlen(sStatusMessage) > 0)
		
		IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", secs2time(DateTime,3) + "  " + sStatusMessage)
		
		if(stringmatch(sStatusMessage, wStatusCategoryNames[0] + ":*"))
			sStatusMessage = ReplaceString(wStatusCategoryNames[0] + ":", sStatusMessage, "")
			sStatusMessage = TrimString(sStatusMessage)
			wStatusStrings[0] = sStatusMessage
		elseif(stringmatch(sStatusMessage, wStatusCategoryNames[1] + ":*"))
			sStatusMessage = ReplaceString(wStatusCategoryNames[1] + ":", sStatusMessage, "")
			sStatusMessage = TrimString(sStatusMessage)
			wStatusStrings[1] = sStatusMessage
		elseif(stringmatch(sStatusMessage, wStatusCategoryNames[2] + ":*"))
			sStatusMessage = ReplaceString(wStatusCategoryNames[2] + ":", sStatusMessage, "")
			sStatusMessage = TrimString(sStatusMessage)
			wStatusStrings[2] = sStatusMessage
		endif
		
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
	if(numType(numCycles) != 0) // in case DefineParams function does not specify Number of Cycles
		numCycles = 1
	endif
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

Function IRIS_EVENT_WaitForClock(sClockTime)
	string sClockTime
	
	// The argument format for a WaitForClock event is: "hh:mm:ss;hh:mm:ss;YYYY-MM-DD",
	// where the first item in the string list is for the interval and the other two items
	// are for the (optional) start time.
	
	// This IRIS_EVENT_WaitForClock(sClockTime) function will be called but doesn't actually
	// do anything; the waiting for the designated clock time is handled by the ScheduleAgent.
	
End

Function IRIS_EVENT_WaitForUser(sUserPrompt)
	string sUserPrompt
	
	NVAR IRIS_WaitingForUser1 = root:IRIS_WaitingForUser1
	NVAR IRIS_WaitingForUser2 = root:IRIS_WaitingForUser2
	NVAR IRIS_WaitingForUser3 = root:IRIS_WaitingForUser3
	wave/T wStatusCategoryNames = root:wStatusCategoryNames
	wave/T wStatusStrings = root:wStatusStrings
	
	NVAR resumeButtonWidth = root:resumeButtonWidth
	NVAR panelWidth = root:panelWidth
	NVAR panelMargin = root:panelMargin
	NVAR status_leftEdgePosition = root:status_leftEdgePosition
	NVAR entryHeight = root:entryHeight
		
	if(strlen(sUserPrompt) > 0)
	
		IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", secs2time(DateTime,3) + "  " + sUserPrompt)
		
		if(stringmatch(sUserPrompt, wStatusCategoryNames[0] + ":*"))
			IRIS_WaitingForUser1 = 1
			sUserPrompt = ReplaceString(wStatusCategoryNames[0] + ":", sUserPrompt, "")
			sUserPrompt = TrimString(sUserPrompt)
			wStatusStrings[0] = sUserPrompt
			ModifyControl IRIS_Status1_tabRunOrReanalyze, win = IRISpanel, valueColor = (65535,0,0), size = {panelWidth - status_leftEdgePosition - panelMargin - panelMargin/2 - resumeButtonWidth,entryHeight}
			ModifyControl IRIS_Resume1_tabRun, win = IRISpanel, disable = 0
		elseif(stringmatch(sUserPrompt, wStatusCategoryNames[1] + ":*"))
			IRIS_WaitingForUser2 = 1
			sUserPrompt = ReplaceString(wStatusCategoryNames[1] + ":", sUserPrompt, "")
			sUserPrompt = TrimString(sUserPrompt)
			wStatusStrings[1] = sUserPrompt
			ModifyControl IRIS_Status2_tabRunOrReanalyze, win = IRISpanel, valueColor = (65535,0,0), size = {panelWidth - status_leftEdgePosition - panelMargin - panelMargin/2 - resumeButtonWidth,entryHeight}	
			ModifyControl IRIS_Resume2_tabRun, win = IRISpanel, disable = 0
		elseif(stringmatch(sUserPrompt, wStatusCategoryNames[2] + ":*"))
			IRIS_WaitingForUser3 = 1
			sUserPrompt = ReplaceString(wStatusCategoryNames[2] + ":", sUserPrompt, "")
			sUserPrompt = TrimString(sUserPrompt)
			wStatusStrings[2] = sUserPrompt
			ModifyControl IRIS_Status3_tabRunOrReanalyze, win = IRISpanel, valueColor = (65535,0,0), size = {panelWidth - status_leftEdgePosition - panelMargin - panelMargin/2 - resumeButtonWidth,entryHeight}
			ModifyControl IRIS_Resume3_tabRun, win = IRISpanel, disable = 0
		else
			IRIS_WaitingForUser1 = 1
			sUserPrompt = TrimString(sUserPrompt)
			wStatusStrings[0] = sUserPrompt
			ModifyControl IRIS_Status1_tabRunOrReanalyze, win = IRISpanel, valueColor = (65535,0,0), size = {panelWidth - status_leftEdgePosition - panelMargin - panelMargin/2 - resumeButtonWidth,entryHeight}
			ModifyControl IRIS_Resume1_tabRun, win = IRISpanel, disable = 0
		endif
		
		IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", secs2time(DateTime,3) + "  " + "Waiting for user")
		
	endif
	
End

///////////////////////////
// Generic GUI Functions //
///////////////////////////

Function IRIS_GUI_Panel()
	
	wave/T wtParamNames = root:wtParamNames
	wave/T wtParamValues = root:wtParamValues
	wave/T wtParamUnits = root:wtParamUnits
	wave/T wtParamTypes = root:wtParamTypes
	wave/T wtGasParamNames = root:wtGasParamNames
	wave/T wtGasParamValues = root:wtGasParamValues
	wave/T wtGasParamUnits = root:wtGasParamUnits
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
	
	wave wOutputColorToGraph1 = root:wOutputColorToGraph1
	
	NVAR numOutputVariables = root:numOutputVariables
	wave/T wtOutputVariableNames = root:wtOutputVariableNames
	wave/T wtOutputVariableUnits = root:wtOutputVariableUnits
	
	wave/T wtDisplayUnits = root:wtDisplayUnits
	wave/T wtDisplayFormat = root:wtDisplayFormat
	
	wave/T wtDataFilterTable_CheckForOutliers
	wave/T wtDataFilterTable_OutlierThresholds
	wave/T wtDataFilterTable_FilterGroups
	
	wave/T wStatusCategoryNames = root:wStatusCategoryNames
	wave/T wStatusStrings = root:wStatusStrings
	
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
	
	variable/G maxAxisLabelLength = 30
	
	variable/G panelLeftEdgePosition = 0 //50
	variable/G panelTopEdgePosition = 0 //76
	variable/G panelWidth = 650
	variable/G panelHeight = 700
	variable panelTopMargin = 40
	variable/G panelMargin = 20
	variable panelHorizontalCenter = panelWidth/2
	
	variable fontSize = 16
	variable runFontSize = 16
	variable standbyFontSize = 12
	variable stopFontSize = 14
	variable fileChoicefontSize = 12
	variable fileChoiceEntryHeight = 30
	variable/G graphFontSize = 14
	variable tableFontSize = 11 //13
	variable scheduleFontSize = 12
	variable scheduleTitleFontSize = 12
	variable notebookFontSize = 12
	variable statusHeaderFontSize = 14
	variable statusFontSize = 14
	
	variable calCurveIsValidLEDwidth = 100
	variable calCurveFieldWidth = panelWidth - 2*panelMargin - calCurveIsValidLEDwidth - 10
	variable calInstructionsFontSize = 12
	variable calInstructionsLineHeight = 18
	variable calInstructionsTopMargin = 20
	variable calInstructionsBottomMargin = 20
	
	variable LEDringThickness = 5
	
	variable runIDlabelWidth = 100
	variable runIDentryWidth = panelWidth - 2*panelMargin - runIDlabelWidth
	
	variable runButtonHorizontalSeparation = panelMargin
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
	variable/G entryHeight = 25
	variable rowHeightMargin = (rowHeight - entryHeight)/2
	
	variable verticalNudge = 2
	
	variable toTheRightOfButtons_leftEdgePosition = panelMargin + max(runButtonWidth,stopButtonWidth) + 2*LEDringThickness + runButtonHorizontalSeparation
	variable statusHeaderWidth = 100
	variable statusHeaderHorizontalSeparation = 10
	variable/G status_leftEdgePosition = toTheRightOfButtons_leftEdgePosition + statusHeaderWidth + statusHeaderHorizontalSeparation
	variable statusOverheadSeparator = 20
	variable statusVerticalSeparation = 0
	variable statusVerticalOffset = 2
	
	variable headerVerticalOffset = 0//2
	variable headerHorizontalOffset = 3
	
	variable quadColumnWidth0 = 60
	variable quadColumnWidth = 100 // 80
	variable quadColumnSeparator = 10
	variable plusMinusWidth = 30
	variable unitsWidth = 60
	variable quadColumnWidth1 = panelWidth - 2*panelMargin - quadColumnWidth0 - 2*quadColumnWidth - 2*quadColumnSeparator - plusMinusWidth - unitsWidth //200
	variable quadColumn0_leftEdgePosition = panelMargin
	variable quadColumn1_leftEdgePosition = quadColumn0_leftEdgePosition + quadColumnWidth0 + quadColumnSeparator
	variable quadColumn2_leftEdgePosition = quadColumn1_leftEdgePosition + quadColumnWidth1 + quadColumnSeparator
	variable quadColumn3_leftEdgePosition = quadColumn2_leftEdgePosition + quadColumnWidth + plusMinusWidth
	variable quadColumn4_leftEdgePosition = quadColumn3_leftEdgePosition + quadColumnWidth
	
	variable quadColumnWidth0_forGraph = quadColumnWidth0
	variable quadColumnWidth1_forGraph = 150
	
	variable/G resumeButtonWidth = 60
	variable resumeButtonHeight = entryHeight
	variable resumeButtonFontSize = 11
	variable resumeButtonVerticalOffset = -2
	
	variable ownAxisCheckBoxWidth = 70
	
	variable numGasesTotalWidth = panelWidth - 2*panelMargin
	variable numGasesBodyWidth = 50
	
	variable/G diagnosticsShown = 0
	variable diagGraphButtonWidth = 100
	variable diagGraphButtonHeight = 25
	variable diagGraphButtonFontSize = 14
	
	variable logDiagnosticButtonHorizontalSeparator = 5
	
	variable/G logShown = 0
	variable logButtonWidth = 50
	variable logButtonHeight = 25
	variable logButtonFontSize = 14
	
	variable/G midGreyColorR = 25000 //32767 //16383 //32767 //57343 //65535
	variable/G midGreyColorG = 25000
	variable/G midGreyColorB = 25000
	
	variable advOptionsButtonHeight = 30
	variable advOptionsButtonWidth = 300	
	
	variable tableHeightRowScaleFactor = 3 // 2.2 for Windows, 1.7 for Mac
	variable gasTableHeight = tableHeightRowScaleFactor*tableFontSize*(numpnts(wtGasParamNames) + 1) // unused
	variable basicTableHeight = tableHeightRowScaleFactor*tableFontSize*(numpnts(wtBasicParamNames)) + 20 // the +20 is for the scroll bar
	variable dataFilterTableHeight = tableHeightRowScaleFactor*tableFontSize*(numOutputVariables + 1)
	
//	variable statusNotebookHeight = 60
//	variable statusNotebookVerticalSeparation = 10
	
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
	TabControl tb, tabLabel(2)="System" // formerly "Config" (renamed because Gas Info, Calibration, and Data Filtering are also config tabs)
	TabControl tb, tabLabel(3)="Calibration"
	TabControl tb, tabLabel(4)="Data Filtering"
	TabControl tb, tabLabel(5)="View Schedule" // maybe I should turn this into something you can view from a button within the Schedule tab
	TabControl tb, tabLabel(6)="Reanalysis"
	SetDrawLayer UserBack
		
	// Populate the "Run" tab (and much of the "Reanalysis" tab)...
	
	variable verticalPositionAtStart = panelTopMargin //+ rowHeightMargin
	
	ValDisplay runningLED_tabRun,pos={runButtonLeftEdgePosition-LEDringThickness,verticalPositionAtStart},size={runButtonWidth+2*LEDringThickness,runButtonHeight+2*LEDringThickness}
	ValDisplay runningLED_tabRun,limits={0,1,0},barmisc={0,0},mode=2, frame = 0
	ValDisplay runningLED_tabRun,value = #"IRIS_Running",zeroColor=(LEDr_run_off,LEDg_run_off,LEDb_run_off),lowColor=(LEDr_run_off,LEDg_run_off,LEDb_run_off),highColor=(LEDr_run_on,LEDg_run_on,LEDb_run_on)
	Button IRIS_Run_tabRun, pos = {runButtonLeftEdgePosition,verticalPositionAtStart+LEDringThickness}, size = {runButtonWidth,runButtonHeight}, proc = IRIS_GUI_Run_ButtonProc, fSize = runFontSize, fstyle = 1, title = "RUN"
	
	variable verticalPositionAtBottomOfRunButtonLED = verticalPositionAtStart + runButtonHeight + 2*LEDringThickness
		
	ValDisplay stoppingLED_tabRun,pos={stopButtonLeftEdgePosition-LEDringThickness,verticalPositionAtBottomOfRunButtonLED+runButtonVerticalSeparation},size={stopButtonWidth+2*LEDringThickness,stopButtonHeight+2*LEDringThickness}
	ValDisplay stoppingLED_tabRun,limits={0,1,0},barmisc={0,0},mode=2, frame = 0
	ValDisplay stoppingLED_tabRun,value = #"(IRIS_ShouldStartToStop || IRIS_Stopping)",zeroColor=(LEDr_stop_off,LEDg_stop_off,LEDb_stop_off),lowColor=(LEDr_stop_off,LEDg_stop_off,LEDb_stop_off),highColor=(LEDr_stop_on,LEDg_stop_on,LEDb_stop_on)
	Button IRIS_Stop_tabRun, pos = {stopButtonLeftEdgePosition,verticalPositionAtBottomOfRunButtonLED+runButtonVerticalSeparation+LEDringThickness}, size = {stopButtonWidth,stopButtonHeight}, proc = IRIS_GUI_Stop_ButtonProc, fSize = stopFontSize, fstyle = 1, title = "STOP"
	
	variable verticalPositionAtBottomOfStopButtonLED = verticalPositionAtBottomOfRunButtonLED + runButtonVerticalSeparation + stopButtonHeight + 2*LEDringThickness
	
	CheckBox IRIS_Standby_tabRun, align = 0, pos = {runButtonLeftEdgePosition-LEDringThickness,verticalPositionAtBottomOfStopButtonLED+runButtonVerticalSeparation}, size = {runButtonWidth, standbyCheckboxHeight}, fsize = standbyFontSize, title = "Heed Ext. Cmds."
	CheckBox IRIS_Standby_tabRun, proc = IRIS_GUI_Standby_CheckBoxProc
	
	variable verticalPositionAtBottomOfStandbyCheckbox = verticalPositionAtBottomOfStopButtonLED + standbyCheckboxHeight + runButtonVerticalSeparation
	
	SetVariable IRIS_RunID_tabRunOrReanalyze, value = sRunID, pos = {toTheRightOfButtons_leftEdgePosition,verticalPositionAtStart}, size = {panelWidth - toTheRightOfButtons_leftEdgePosition - panelMargin - logButtonWidth - diagGraphButtonWidth - 2*logDiagnosticButtonHorizontalSeparator,entryHeight}, fSize = fontSize, title = "Run ID: "
	Button IRIS_ShowDiagnostics_tabRunOrReanalyze, align = 1, pos = {panelWidth - panelMargin,verticalPositionAtStart}, size = {diagGraphButtonWidth,diagGraphButtonHeight}, proc = IRIS_GUI_ShowDiagnostics_ButtonProc, fSize = diagGraphButtonFontSize, title = "Diagnostics"
	Button IRIS_ShowLog_tabRunOrReanalyze, align = 1, pos = {panelWidth - panelMargin - diagGraphButtonWidth - logDiagnosticButtonHorizontalSeparator,verticalPositionAtStart}, size = {logButtonWidth,logButtonHeight}, proc = IRIS_GUI_ShowLog_ButtonProc, fSize = logButtonFontSize, title = "Log"
	
	variable verticalPositionAtBottomOfRunID = verticalPositionAtStart + entryHeight + rowHeightMargin
	
	variable statusBoxHeight
	if(cmpstr(wStatusCategoryNames[2], " ") == 0)
		statusBoxHeight = 2*entryHeight + 1*statusVerticalSeparation + statusOverheadSeparator
	else
		statusBoxHeight = 3*entryHeight + 2*statusVerticalSeparation + statusOverheadSeparator
	endif
	
	GroupBox StatusBox_tabRunOrReanalyze pos={toTheRightOfButtons_leftEdgePosition, verticalPositionAtBottomOfRunID + statusOverheadSeparator - statusOverheadSeparator/2}, size={panelWidth - panelMargin - toTheRightOfButtons_leftEdgePosition, statusBoxHeight}
	
	//	TitleBox IRIS_StatusHeader_tabRunOrReanalyze, pos = {toTheRightOfButtons_leftEdgePosition,verticalPositionAtBottomOfRunID + headerVerticalOffset}, size = {statusHeaderWidth,entryHeight}, fSize=statusHeaderFontSize, title = "Status: ", frame = 0//, anchor = MC
	TitleBox IRIS_StatusHeader1_tabRunOrReanalyze, pos = {toTheRightOfButtons_leftEdgePosition,verticalPositionAtBottomOfRunID + statusOverheadSeparator + headerVerticalOffset}, size = {statusHeaderWidth,entryHeight}, fixedSize=1, fSize=statusHeaderFontSize, title = wStatusCategoryNames[0], frame = 0, anchor = RC
	variable verticalPositionAfterStatus1 = verticalPositionAtBottomOfRunID + statusOverheadSeparator + entryHeight + statusVerticalSeparation
	TitleBox IRIS_StatusHeader2_tabRunOrReanalyze, pos = {toTheRightOfButtons_leftEdgePosition,verticalPositionAfterStatus1 + headerVerticalOffset}, size = {statusHeaderWidth,entryHeight}, fixedSize=1, fSize=statusHeaderFontSize, title = wStatusCategoryNames[1], frame = 0, anchor = RC
	variable verticalPositionAfterStatus2 = verticalPositionAfterStatus1 + entryHeight + statusVerticalSeparation
	TitleBox IRIS_StatusHeader3_tabRunOrReanalyze, pos = {toTheRightOfButtons_leftEdgePosition,verticalPositionAfterStatus2 + headerVerticalOffset}, size = {statusHeaderWidth,entryHeight}, fixedSize=1, fSize=statusHeaderFontSize, title = wStatusCategoryNames[2], frame = 0, anchor = RC
//	variable verticalPositionAfterStatus3 = verticalPositionAfterStatus2 + entryHeight + statusVerticalSeparation
//	TitleBox IRIS_StatusHeader4_tabRunOrReanalyze, pos = {toTheRightOfButtons_leftEdgePosition,verticalPositionAfterStatus3 + headerVerticalOffset}, size = {statusHeaderWidth,entryHeight}, fixedSize=1, fSize=statusHeaderFontSize, title = wStatusCategoryNames[3], frame = 0, anchor = RC
	
	variable thisStatusCategory
	for(thisStatusCategory=0;thisStatusCategory<3;thisStatusCategory+=1)
		if(cmpstr(wStatusCategoryNames[thisStatusCategory]," ") != 0)
			wStatusStrings[thisStatusCategory] = "idle"
		endif
	endfor
	
	SetVariable IRIS_Status1_tabRunOrReanalyze, pos = {status_leftEdgePosition,verticalPositionAtBottomOfRunID + statusOverheadSeparator + statusVerticalOffset}, size = {panelWidth - status_leftEdgePosition - panelMargin - panelMargin/2,entryHeight}, fSize = statusFontSize
	SetVariable IRIS_Status1_tabRunOrReanalyze, value = wStatusStrings[0], noedit = 1, title = " ", frame = 0, valueColor = (16385,28398,65535)
	variable verticalPositionAtBottomOfStatus1 = verticalPositionAtBottomOfRunID + statusOverheadSeparator + entryHeight + statusVerticalSeparation + statusVerticalOffset
	SetVariable IRIS_Status2_tabRunOrReanalyze, pos = {status_leftEdgePosition,verticalPositionAtBottomOfStatus1}, size = {panelWidth - status_leftEdgePosition - panelMargin - panelMargin/2,entryHeight}, fSize = statusFontSize
	SetVariable IRIS_Status2_tabRunOrReanalyze, value = wStatusStrings[1], noedit = 1, title = " ", frame = 0, valueColor = (16385,28398,65535)
	variable verticalPositionAtBottomOfStatus2 = verticalPositionAtBottomOfStatus1 + entryHeight + statusVerticalSeparation
	SetVariable IRIS_Status3_tabRunOrReanalyze, pos = {status_leftEdgePosition,verticalPositionAtBottomOfStatus2}, size = {panelWidth - status_leftEdgePosition - panelMargin - panelMargin/2,entryHeight}, fSize = statusFontSize
	SetVariable IRIS_Status3_tabRunOrReanalyze, value = wStatusStrings[2], noedit = 1, title = " ", frame = 0, valueColor = (16385,28398,65535)
	
	Button IRIS_Resume1_tabRun, pos = {panelWidth - panelMargin - resumeButtonWidth - statusOverheadSeparator/2,verticalPositionAtBottomOfRunID + statusOverheadSeparator + statusVerticalOffset + resumeButtonVerticalOffset}, size = {resumeButtonWidth,resumeButtonHeight}, proc = IRIS_GUI_Resume_ButtonProc, fSize = resumeButtonFontSize, valueColor = (65535,0,0), disable = 3, title = "RESUME"
	Button IRIS_Resume2_tabRun, pos = {panelWidth - panelMargin - resumeButtonWidth - statusOverheadSeparator/2,verticalPositionAtBottomOfStatus1 + resumeButtonVerticalOffset}, size = {resumeButtonWidth,resumeButtonHeight}, proc = IRIS_GUI_Resume_ButtonProc, fSize = resumeButtonFontSize, valueColor = (65535,0,0), disable = 3, title = "RESUME"
	Button IRIS_Resume3_tabRun, pos = {panelWidth - panelMargin - resumeButtonWidth - statusOverheadSeparator/2,verticalPositionAtBottomOfStatus2 + resumeButtonVerticalOffset}, size = {resumeButtonWidth,resumeButtonHeight}, proc = IRIS_GUI_Resume_ButtonProc, fSize = resumeButtonFontSize, valueColor = (65535,0,0), disable = 3, title = "RESUME"
	
//	ValDisplay standbyLED_tabRun,pos={standbyButtonLeftEdgePosition-LEDringThickness,verticalPositionAtBottomOfRunButtonLED+runButtonVerticalSeparation},size={standbyButtonWidth+2*LEDringThickness,standbyButtonHeight+2*LEDringThickness}
//	ValDisplay standbyLED_tabRun,limits={0,1,0},barmisc={0,0},mode=2, frame = 0
//	ValDisplay standbyLED_tabRun,value = #"IRIS_Standby",zeroColor=(LEDr_standby_off,LEDg_standby_off,LEDb_standby_off),lowColor=(LEDr_standby_off,LEDg_standby_off,LEDb_standby_off),highColor=(LEDr_standby_on,LEDg_standby_on,LEDb_standby_on)
//	Button IRIS_Standby_tabRun, pos = {standbyButtonLeftEdgePosition,verticalPositionAtBottomOfRunButtonLED+runButtonVerticalSeparation+LEDringThickness}, size = {standbyButtonWidth,standbyButtonHeight}, proc = IRIS_GUI_Standby_ButtonProc, fSize = standbyFontSize, fstyle = 1, title = "Heed Ext Cmds"
//	
//	variable verticalPositionAtBottomOfStandbyButtonLED = verticalPositionAtBottomOfRunButtonLED + runButtonVerticalSeparation + standbyButtonHeight + 2*LEDringThickness
	
	variable verticalPositionSoFar = verticalPositionAtBottomOfStandbyCheckbox + panelMargin
	
	TitleBox IRIS_GasHeader_tabRunOrReanalyze, pos = {quadColumn0_leftEdgePosition,verticalPositionSoFar}, size = {quadColumnWidth0,entryHeight}, fSize=fontSize, title = "Gas", frame = 0//, anchor = MC
	TitleBox IRIS_VariableHeader_tabRunOrReanalyze, pos = {quadColumn1_leftEdgePosition,verticalPositionSoFar}, size = {quadColumnWidth1,entryHeight}, fSize=fontSize, title = "Variable", frame = 0//, anchor = MC
	TitleBox IRIS_MeanHeader_tabRunOrReanalyze, pos = {quadColumn2_leftEdgePosition + headerHorizontalOffset,verticalPositionSoFar}, size = {quadColumnWidth,entryHeight}, fSize=fontSize, title = "Mean", frame = 0//, anchor = MC
	TitleBox IRIS_StErrHeader_tabRunOrReanalyze, pos = {quadColumn3_leftEdgePosition + headerHorizontalOffset,verticalPositionSoFar}, size = {quadColumnWidth,entryHeight}, fSize=fontSize, title = "SE", frame = 0//, anchor = MC
	
	verticalPositionSoFar += entryHeight + rowHeightMargin + rowHeightMargin
	
	PopupMenu IRIS_GasChoice1_tabRunOrReanalyze, align = 1, bodyWidth = quadColumnWidth0, pos = {quadColumn0_leftEdgePosition + quadColumnWidth0,verticalPositionSoFar+verticalNudge}, fSize = fontSize, title = ""
	PopupMenu IRIS_GasChoice1_tabRunOrReanalyze, mode = output1_gasID + 1, value = IRIS_GUI_PopupWaveList_Gas()
	PopupMenu IRIS_GasChoice1_tabRunOrReanalyze, proc = IRIS_GUI_SelectGas1_PopupMenuProc
	PopupMenu IRIS_VariableChoice1_tabRunOrReanalyze, align = 1, bodyWidth = quadColumnWidth1, pos = {quadColumn1_leftEdgePosition + quadColumnWidth1,verticalPositionSoFar+verticalNudge}, fSize = fontSize, title = ""
	PopupMenu IRIS_VariableChoice1_tabRunOrReanalyze, mode = output1_variableID + 1, value = IRIS_GUI_PopupWaveList_Variable1()
	PopupMenu IRIS_VariableChoice1_tabRunOrReanalyze, proc = IRIS_GUI_SelectVariable1_PopupMenuProc
	SetVariable IRIS_OutputMean1_tabRunOrReanalyze, pos = {quadColumn2_leftEdgePosition,verticalPositionSoFar}, size = {quadColumnWidth,entryHeight}, fSize = fontSize
	SetVariable IRIS_OutputMean1_tabRunOrReanalyze, format = wtDisplayFormat[0], limits = {-inf,inf,0}, value = wDisplayMeans[0], noedit = 1, title = " ", frame = 0, valueColor = (16385,28398,65535)
	TitleBox IRIS_PlusMinus1_tabRunOrReanalyze, pos = {quadColumn3_leftEdgePosition-20,verticalPositionSoFar}, size = {10,entryHeight}, fSize=fontSize, title = "±", frame = 0, anchor = MC
	SetVariable IRIS_OutputStErr1_tabRunOrReanalyze, pos = {quadColumn3_leftEdgePosition,verticalPositionSoFar}, size = {quadColumnWidth,entryHeight}, fSize = fontSize
	SetVariable IRIS_OutputStErr1_tabRunOrReanalyze, format = wtDisplayFormat[0], limits = {-inf,inf,0}, value = wDisplayStErrs[0], noedit = 1, title = " ", frame = 0, valueColor = (16385,28398,65535)
	SetVariable IRIS_OutputUnits1_tabRunOrReanalyze, pos = {quadColumn4_leftEdgePosition,verticalPositionSoFar}, size = {unitsWidth,entryHeight}, fSize = fontSize
	SetVariable IRIS_OutputUnits1_tabRunOrReanalyze, limits = {-inf,inf,0}, value = wtDisplayUnits[0], noedit = 1, frame = 0, title = " "
	
	verticalPositionSoFar += entryHeight + rowHeightMargin + rowHeightMargin
	
	PopupMenu IRIS_GasChoice2_tabRunOrReanalyze, align = 1, bodyWidth = quadColumnWidth0, pos = {quadColumn0_leftEdgePosition + quadColumnWidth0,verticalPositionSoFar+verticalNudge}, fSize = fontSize, title = ""
	PopupMenu IRIS_GasChoice2_tabRunOrReanalyze, mode = output2_gasID + 1, value = IRIS_GUI_PopupWaveList_Gas()
	PopupMenu IRIS_GasChoice2_tabRunOrReanalyze, proc = IRIS_GUI_SelectGas2_PopupMenuProc
	PopupMenu IRIS_VariableChoice2_tabRunOrReanalyze, align = 1, bodyWidth = quadColumnWidth1, pos = {quadColumn1_leftEdgePosition + quadColumnWidth1,verticalPositionSoFar+verticalNudge}, fSize = fontSize, title = ""
	PopupMenu IRIS_VariableChoice2_tabRunOrReanalyze, mode = output2_variableID + 1, value = IRIS_GUI_PopupWaveList_Variable2()
	PopupMenu IRIS_VariableChoice2_tabRunOrReanalyze, proc = IRIS_GUI_SelectVariable2_PopupMenuProc
	SetVariable IRIS_OutputMean2_tabRunOrReanalyze, pos = {quadColumn2_leftEdgePosition,verticalPositionSoFar}, size = {quadColumnWidth,entryHeight}, fSize = fontSize
	SetVariable IRIS_OutputMean2_tabRunOrReanalyze, format = wtDisplayFormat[1], limits = {-inf,inf,0}, value = wDisplayMeans[1], noedit = 1, title = " ", frame = 0, valueColor = (16385,28398,65535)
	TitleBox IRIS_PlusMinus2_tabRunOrReanalyze, pos = {quadColumn3_leftEdgePosition-20,verticalPositionSoFar}, size = {10,entryHeight}, fSize=fontSize, title = "±", frame = 0, anchor = MC
	SetVariable IRIS_OutputStErr2_tabRunOrReanalyze, pos = {quadColumn3_leftEdgePosition,verticalPositionSoFar}, size = {quadColumnWidth,entryHeight}, fSize = fontSize
	SetVariable IRIS_OutputStErr2_tabRunOrReanalyze, format = wtDisplayFormat[1], limits = {-inf,inf,0}, value = wDisplayStErrs[1], noedit = 1, title = " ", frame = 0, valueColor = (16385,28398,65535)
	SetVariable IRIS_OutputUnits2_tabRunOrReanalyze, pos = {quadColumn4_leftEdgePosition,verticalPositionSoFar}, size = {unitsWidth,entryHeight}, fSize = fontSize
	SetVariable IRIS_OutputUnits2_tabRunOrReanalyze, limits = {-inf,inf,0}, value = wtDisplayUnits[1], noedit = 1, frame = 0, title = " "
	
	verticalPositionSoFar += entryHeight + rowHeightMargin + rowHeightMargin
	
	PopupMenu IRIS_GasChoice3_tabRunOrReanalyze, align = 1, bodyWidth = quadColumnWidth0, pos = {quadColumn0_leftEdgePosition + quadColumnWidth0,verticalPositionSoFar+verticalNudge}, fSize = fontSize, title = ""
	PopupMenu IRIS_GasChoice3_tabRunOrReanalyze, mode = output3_gasID + 1, value = IRIS_GUI_PopupWaveList_Gas()
	PopupMenu IRIS_GasChoice3_tabRunOrReanalyze, proc = IRIS_GUI_SelectGas3_PopupMenuProc
	PopupMenu IRIS_VariableChoice3_tabRunOrReanalyze, align = 1, bodyWidth = quadColumnWidth1, pos = {quadColumn1_leftEdgePosition + quadColumnWidth1,verticalPositionSoFar+verticalNudge}, fSize = fontSize, title = ""
	PopupMenu IRIS_VariableChoice3_tabRunOrReanalyze, mode = output3_variableID + 1, value = IRIS_GUI_PopupWaveList_Variable3()
	PopupMenu IRIS_VariableChoice3_tabRunOrReanalyze, proc = IRIS_GUI_SelectVariable3_PopupMenuProc
	SetVariable IRIS_OutputMean3_tabRunOrReanalyze, pos = {quadColumn2_leftEdgePosition,verticalPositionSoFar}, size = {quadColumnWidth,entryHeight}, fSize = fontSize
	SetVariable IRIS_OutputMean3_tabRunOrReanalyze, format = wtDisplayFormat[2], limits = {-inf,inf,0}, value = wDisplayMeans[2], noedit = 1, title = " ", frame = 0, valueColor = (16385,28398,65535)
	TitleBox IRIS_PlusMinus3_tabRunOrReanalyze, pos = {quadColumn3_leftEdgePosition-20,verticalPositionSoFar}, size = {10,entryHeight}, fSize=fontSize, title = "±", frame = 0, anchor = MC
	SetVariable IRIS_OutputStErr3_tabRunOrReanalyze, pos = {quadColumn3_leftEdgePosition,verticalPositionSoFar}, size = {quadColumnWidth,entryHeight}, fSize = fontSize
	SetVariable IRIS_OutputStErr3_tabRunOrReanalyze, format = wtDisplayFormat[2], limits = {-inf,inf,0}, value = wDisplayStErrs[2], noedit = 1, title = " ", frame = 0, valueColor = (16385,28398,65535)
	SetVariable IRIS_OutputUnits3_tabRunOrReanalyze, pos = {quadColumn4_leftEdgePosition,verticalPositionSoFar}, size = {unitsWidth,entryHeight}, fSize = fontSize
	SetVariable IRIS_OutputUnits3_tabRunOrReanalyze, limits = {-inf,inf,0}, value = wtDisplayUnits[2], noedit = 1, frame = 0, title = " "
	
	verticalPositionSoFar += entryHeight + rowHeightMargin + panelMargin
	
//	verticalPositionSoFar = max(verticalPositionSoFar, verticalPositionAtBottomOfStandbyCheckbox)
//	verticalPositionSoFar += panelMargin
	
	// Create an embedded graph to show the results...
	string sYaxisLabel
//	variable bottomOfGraph = panelHeight - logoHeight - panelMargin - statusNotebookHeight - statusNotebookVerticalSeparation - entryHeight - 2*rowHeightMargin
	variable bottomOfGraph = panelHeight - logoHeight - panelMargin - entryHeight - 2*rowHeightMargin
	Display/HOST=IRISpanel/N=ResultGraph/W=(panelMargin, verticalPositionSoFar, panelWidth - panelMargin, bottomOfGraph) wOutputMeanToGraph1 vs wOutputTimeToGraph1
	sYaxisLabel = wtOutputVariableNames[variableToGraph1] + " (" + wtOutputVariableUnits[variableToGraph1] + ")"
	if(strlen(sYaxisLabel) > maxAxisLabelLength)
		sYaxisLabel = wtOutputVariableNames[variableToGraph1] + "\r\n(" + wtOutputVariableUnits[variableToGraph1] + ")"
	endif
	Label Left sYaxisLabel
	Label bottom " "
	SetWindow IRISpanel#ResultGraph, hide = 0
	ModifyGraph/W=IRISpanel#ResultGraph frameStyle = 1, fSize = graphFontSize
	ModifyGraph lblMargin(left)=5
	ModifyGraph mode=3, marker=19, rgb=(16385,28398,65535), msize = 5, mrkThick=2
//	ModifyGraph rgb(wOutputMeanToGraph1)=(16385,28398,65535)
	ModifyGraph zColor(wOutputMeanToGraph1)={wOutputColorToGraph1,*,*,directRGB,0}
	ModifyGraph axRGB(left)=(0,0,0), alblRGB(left)=(0,0,0), tlblRGB(left)=(0,0,0)
	ModifyGraph UIControl = 2^0 + 2^1 + 2^2 + 2^4 + 2^5 + 2^6 + 2^7 + 2^10 + 2^11
	ErrorBars wOutputMeanToGraph1 Y, wave=(wOutputErrorToGraph1,wOutputErrorToGraph1)
	ModifyGraph zmrkNum(wOutputMeanToGraph1)={wOutputFilterToGraph1}
	SetActiveSubwindow ##
	
	verticalPositionSoFar = bottomOfGraph + 2*rowHeightMargin
	
	PopupMenu IRIS_PlotGasChoice1_tabRunOrReanalyze, align = 1, bodyWidth = quadColumnWidth0_forGraph, pos = {panelMargin + quadColumnWidth0_forGraph,verticalPositionSoFar+verticalNudge}, fSize = fontSize, title = ""
	PopupMenu IRIS_PlotGasChoice1_tabRunOrReanalyze, mode = gasToGraph1 + 1, value = IRIS_GUI_PopupWaveList_Gas()
	PopupMenu IRIS_PlotGasChoice1_tabRunOrReanalyze, proc = IRIS_GUI_SelectPlotGas1_PopupMenuProc
	PopupMenu IRIS_PlotVariableChoice1_tabRunOrReanalyze, align = 1, bodyWidth = quadColumnWidth1_forGraph, pos = {panelMargin + quadColumnWidth0_forGraph + 10 + quadColumnWidth1_forGraph,verticalPositionSoFar+verticalNudge}, fSize = fontSize, title = ""
	PopupMenu IRIS_PlotVariableChoice1_tabRunOrReanalyze, mode = variableToGraph1 + 1, value = IRIS_GUI_PopupWaveList_VariableG1()
	PopupMenu IRIS_PlotVariableChoice1_tabRunOrReanalyze, proc = IRIS_GUI_SelectPlotVariable1_PopupMenuProc
	
	CheckBox IRIS_ShowSecondPlotOnGraph_tabRunOrReanalyze, align = 1, pos = {panelWidth - panelMargin - ownAxisCheckBoxWidth - quadColumnWidth1_forGraph - 10 - quadColumnWidth0_forGraph - 10,verticalPositionSoFar+verticalNudge}, title = "Compare"
	CheckBox IRIS_ShowSecondPlotOnGraph_tabRunOrReanalyze, proc = IRIS_GUI_ShowSecondPlotOnGraph_CheckBoxProc
	
	PopupMenu IRIS_PlotGasChoice2_tabRunOrReanalyze, align = 1, bodyWidth = quadColumnWidth0_forGraph, pos = {panelWidth - panelMargin - ownAxisCheckBoxWidth - quadColumnWidth1_forGraph - 10,verticalPositionSoFar+verticalNudge}, fSize = fontSize, title = ""
	PopupMenu IRIS_PlotGasChoice2_tabRunOrReanalyze, mode = gasToGraph2 + 1, value = IRIS_GUI_PopupWaveList_Gas()
	PopupMenu IRIS_PlotGasChoice2_tabRunOrReanalyze, proc = IRIS_GUI_SelectPlotGas2_PopupMenuProc
	PopupMenu IRIS_PlotGasChoice2_tabRunOrReanalyze, disable = 2
	PopupMenu IRIS_PlotVariableChoice2_tabRunOrReanalyze, align = 1, bodyWidth = quadColumnWidth1_forGraph, pos = {panelWidth - panelMargin - ownAxisCheckBoxWidth,verticalPositionSoFar+verticalNudge}, fSize = fontSize, title = ""
	PopupMenu IRIS_PlotVariableChoice2_tabRunOrReanalyze, mode = variableToGraph2 + 1, value = IRIS_GUI_PopupWaveList_VariableG2()
	PopupMenu IRIS_PlotVariableChoice2_tabRunOrReanalyze, proc = IRIS_GUI_SelectPlotVariable2_PopupMenuProc
	PopupMenu IRIS_PlotVariableChoice2_tabRunOrReanalyze, disable = 2
	
	CheckBox IRIS_PlotSeparateAxisChoice_tabRunOrReanalyze, align = 1, pos = {panelWidth - panelMargin,verticalPositionSoFar+verticalNudge}, title = "Own Axis"
	CheckBox IRIS_PlotSeparateAxisChoice_tabRunOrReanalyze, proc = IRIS_GUI_OneOrTwoGraphAxes_CheckBoxProc
	CheckBox IRIS_PlotSeparateAxisChoice_tabRunOrReanalyze, disable = 2
			
	verticalPositionSoFar += entryHeight + rowHeightMargin
	
//	// Create an embedded notebook to display status messages for the user...
//	variable winTypeCode = winType("IRISpanel#StatusNotebook")
//	if(winTypeCode > 0)
//		KillWindow IRISpanel#StatusNotebook
//	endif
//	NewNotebook/HOST=IRISpanel/N=StatusNotebook/V=0/F=0/OPTS=3/W=(panelMargin, panelHeight - logoHeight - panelMargin - statusNotebookHeight, panelWidth-panelMargin, panelHeight - logoHeight - panelMargin) as "STATUS"
//	Notebook IRISpanel#StatusNotebook, frameStyle = 1, visible = 1, fsize = notebookFontSize
//	Notebook IRISpanel#StatusNotebook, changeableByCommandOnly = 1
//	Notebook IRISpanel#StatusNotebook, text = "STATUS"
//	SetActiveSubwindow ##
	
	// Add the Aerodyne logo...
	NewPanel/HOST=IRISpanel/N=LogoSubwindowPanel_tabRunOrReanalyze/W=(0,panelHeight - logoHeight,panelWidth,panelHeight)
	ModifyPanel/W=IRISpanel#LogoSubwindowPanel_tabRunOrReanalyze frameStyle = 0, frameInset = 0, noEdit = 1, fixedSize = 1
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
	
	ValDisplay chooseFilesLED_tabReanalyze,pos={runButtonLeftEdgePosition-LEDringThickness, verticalPositionAtStart},size={chooseFilesButtonWidth+2*LEDringThickness,chooseFilesButtonHeight+2*LEDringThickness}
	ValDisplay chooseFilesLED_tabReanalyze,limits={0,1,0},barmisc={0,0},mode=2, frame = 0, disable = 1
	ValDisplay chooseFilesLED_tabReanalyze,value = #"IRIS_ChoosingFiles",zeroColor=(LEDr_chooseFiles_off,LEDg_chooseFiles_off,LEDb_chooseFiles_off),lowColor=(LEDr_chooseFiles_off,LEDg_chooseFiles_off,LEDb_chooseFiles_off),highColor=(LEDr_chooseFiles_on,LEDg_chooseFiles_on,LEDb_chooseFiles_on)
	Button IRIS_ChooseFiles_tabReanalyze, pos = {runButtonLeftEdgePosition, verticalPositionAtStart + LEDringThickness}, size = {chooseFilesButtonWidth,chooseFilesButtonHeight}, proc = IRIS_GUI_ChooseFiles_ButtonProc, fSize = fileChoicefontSize, fstyle = 1, disable = 1, title = "Choose File(s)"
	
	ValDisplay reanalyzeLED_tabReanalyze,pos={runButtonLeftEdgePosition-LEDringThickness, verticalPositionAtStart + chooseFilesButtonHeight + 2*LEDringThickness + runButtonVerticalSeparation},size={reanalyzeButtonWidth+2*LEDringThickness,reanalyzeButtonHeight+2*LEDringThickness}
	ValDisplay reanalyzeLED_tabReanalyze,limits={0,1,0},barmisc={0,0},mode=2, frame = 0, disable = 1
	ValDisplay reanalyzeLED_tabReanalyze,value = #"IRIS_Reanalyzing",zeroColor=(LEDr_reanalyze_off,LEDg_reanalyze_off,LEDb_reanalyze_off),lowColor=(LEDr_reanalyze_off,LEDg_reanalyze_off,LEDb_reanalyze_off),highColor=(LEDr_reanalyze_on,LEDg_reanalyze_on,LEDb_reanalyze_on)
	Button IRIS_Reanalyze_tabReanalyze, pos = {runButtonLeftEdgePosition, verticalPositionAtStart + chooseFilesButtonHeight + 2*LEDringThickness + runButtonVerticalSeparation + LEDringThickness}, size = {reanalyzeButtonWidth,reanalyzeButtonHeight}, proc = IRIS_GUI_Reanalyze_ButtonProc, fSize = runFontSize, fstyle = 1, disable = 1, title = "REANALYZE"
	
	// Triggers a rebuild of the schedule whenever one of the embedded tables is modified...
	SetWindow IRISpanel, hook(IRISsystemTableHook) = IRIS_GUI_SystemTableEntryHook
		
	// Create a hidden notebook to hold the status log...
	variable logLeftEdge, logTopEdge
	variable infoBarHeightAllowance = 0 //44
	GetWindow/Z IRISpanel wsize
	if(V_flag == 0)
		logLeftEdge = V_left + panelWidth + 10
		logTopEdge = V_top
	endif
	NewNotebook/Q/K=3/N=StatusNotebook/V=0/F=0/W=(logLeftEdge, logTopEdge, logLeftEdge + panelWidth, logTopEdge + panelHeight - infoBarHeightAllowance) as "Status Log"
	Notebook StatusNotebook, fsize = notebookFontSize
	Notebook StatusNotebook, changeableByCommandOnly = 1
	Notebook StatusNotebook, text = "STATUS LOG"
	SetWindow StatusNotebook, hook(IRISlogKilledHook) = IRIS_GUI_LogKilledHook // changes button title appropriately when user kills the diagnostic graph window the old fashioned way
	DoWindow/F IRISpanel
	
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
	if( (output1_gasID == 1) || ((output1_gasID > 2) && (output1_gasID < (numSampleGases + 3))) ) // output1_gasID == 0 is all gases, output1_gasID == 1 is all samples, output1_gasID == 2 is all refs
		for(i=0;i<numOutputVariables;i+=1)
			list = list + wtOutputVariableNames[i] + ";"
		endfor
	else
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
	if( (output2_gasID == 1) || ((output2_gasID > 2) && (output2_gasID < (numSampleGases + 3))) ) // output2_gasID == 0 is all gases, output2_gasID == 1 is all samples, output2_gasID == 2 is all refs
		for(i=0;i<numOutputVariables;i+=1)
			list = list + wtOutputVariableNames[i] + ";"
		endfor
	else
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
	if( (output3_gasID == 1) || ((output3_gasID > 2) && (output3_gasID < (numSampleGases + 3))) ) // output3_gasID == 0 is all gases, output3_gasID == 1 is all samples, output3_gasID == 2 is all refs
		for(i=0;i<numOutputVariables;i+=1)
			list = list + wtOutputVariableNames[i] + ";"
		endfor
	else
		for(ii=0;ii<numVariablesToAverage;ii+=1)
			i = wIndicesOfVariablesToAverage[ii]
			list = list + wtOutputVariableNames[i] + ";"
		endfor
	endif
	
	return list
End

Function/S IRIS_GUI_PopupWaveList_VariableG1()
	
	wave/T wtOutputVariableNames = root:wtOutputVariableNames
	
	NVAR numOutputVariables = root:numOutputVariables
	NVAR numVariablesToAverage = root:numVariablesToAverage
	wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
	
	NVAR gasToGraph1 = root:gasToGraph1
	NVAR numSampleGases = root:numSampleGases
	
	variable i, ii
	string list = ""
	if( (gasToGraph1 == 1) || ((gasToGraph1 > 2) && (gasToGraph1 < (numSampleGases + 3))) ) // gasToGraph1 == 0 is all gases, gasToGraph1 == 1 is all samples, gasToGraph1 == 2 is all refs
		for(i=0;i<numOutputVariables;i+=1)
			list = list + wtOutputVariableNames[i] + ";"
		endfor
	else
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
	if( (gasToGraph2 == 1) || ((gasToGraph2 > 2) && (gasToGraph2 < (numSampleGases + 3))) ) // gasToGraph2 == 0 is all gases, gasToGraph2 == 1 is all samples, gasToGraph2 == 2 is all refs
		for(i=0;i<numOutputVariables;i+=1)
			list = list + wtOutputVariableNames[i] + ";"
		endfor
	else
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
	NVAR IRIS_WaitingForUser1 = root:IRIS_WaitingForUser1
	NVAR IRIS_WaitingForUser2 = root:IRIS_WaitingForUser2
	NVAR IRIS_WaitingForUser3 = root:IRIS_WaitingForUser3
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
			isTabSystem = (tabNum == 2)
			isTabCal = (tabNum == 3)
			isTabFilter = (tabNum == 4)
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
			if(isTabRun == 1)
				if(IRIS_WaitingForUser1 == 0)
					ModifyControl IRIS_Resume1_tabRun, win = IRISpanel, disable = 3
				endif
				if(IRIS_WaitingForUser2 == 0)
					ModifyControl IRIS_Resume2_tabRun, win = IRISpanel, disable = 3
				endif
				if(IRIS_WaitingForUser3 == 0)
					ModifyControl IRIS_Resume3_tabRun, win = IRISpanel, disable = 3
				endif
			endif
			SetWindow IRISpanel#ResultGraph, hide = !isTabRunOrReanalyze
			SetWindow IRISpanel#LogoSubwindowPanel_tabRunOrReanalyze, hide = !isTabRunOrReanalyze
//			Notebook IRISpanel#StatusNotebook, visible = isTabRunOrReanalyze
			SetWindow IRISpanel#GasTable, hide = !isTabGas
			SetWindow IRISpanel#BasicSystemTable, hide = !isTabSystem
			SetWindow IRISpanel#AdvSystemTable, hide = ((!isTabSystem) || (advOptionsHidden == 1))
			SetWindow IRISpanel#PrologueTable, hide = !isTabSchedule
			SetWindow IRISpanel#CycleTable, hide = !isTabSchedule
			SetWindow IRISpanel#EpilogueTable, hide = !isTabSchedule
			SetWindow IRISpanel#DataFilterTable, hide = !isTabFilter
			IRIS_ConfirmToRun = 0
			if(IRIS_Running == 0)
				ModifyControl IRIS_Run_tabRun, win = IRISpanel, title = "RUN"
			endif
//			if(IRIS_Running == 1)
//				if(IRIS_WaitingForUser == 1)
//					ModifyControl IRIS_Run_tabRun, win = IRISpanel, title = "\K(65535,0,0)RESUME"
//				else
//					ModifyControl IRIS_Run_tabRun, win = IRISpanel, title = "RUNNING"
//				endif
//			else
//				ModifyControl IRIS_Run_tabRun, win = IRISpanel, title = "RUN"
//			endif
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
	
	wave/T wStatusStrings = root:wStatusStrings
	
	switch( ba.eventCode )
		case 2: // mouse up
			if(calCurveIsValid == 0)
				IRIS_EVENT_ReportStatus("TILDAS: CANNOT RUN: calibration curve is invalid")
			elseif(gasInfoIsValid == 0)
				IRIS_EVENT_ReportStatus("TILDAS: CANNOT RUN: gas info is invalid")
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
//							IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", secs2time(DateTime,3) + "  " + "Stopped listening for external commands")
							IRIS_UTILITY_Run()
						endif
					else
//						if(IRIS_WaitingForUser == 1)
//							ModifyControl IRIS_Run_tabRun, win = IRISpanel, title = "RUNNING"
//							ModifyControl IRIS_Status1_tabRunOrReanalyze, win = IRISpanel, valueColor = (16385,28398,65535)
//							ModifyControl IRIS_Status2_tabRunOrReanalyze, win = IRISpanel, valueColor = (16385,28398,65535)
//							ModifyControl IRIS_Status3_tabRunOrReanalyze, win = IRISpanel, valueColor = (16385,28398,65535)
//							wStatusStrings[0] = "resuming"
//							IRIS_WaitingForUser = 0
//							IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", secs2time(DateTime,3) + "  " + "User resumed the run")
//						else
							IRIS_ConfirmToStop = 0
							ModifyControl IRIS_Stop_tabRun, win = IRISpanel, title = "STOP"
//						endif
					endif
				endif
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function IRIS_GUI_Resume_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	NVAR IRIS_Running = root:IRIS_Running
//	NVAR IRIS_Standby = root:IRIS_Standby
	NVAR IRIS_ConfirmToRun = root:IRIS_ConfirmToRun
	NVAR IRIS_ConfirmToStop = root:IRIS_ConfirmToStop
	NVAR IRIS_Reanalyzing = root:IRIS_Reanalyzing
	NVAR IRIS_WaitingForUser1 = root:IRIS_WaitingForUser1
	NVAR IRIS_WaitingForUser2 = root:IRIS_WaitingForUser2
	NVAR IRIS_WaitingForUser3 = root:IRIS_WaitingForUser3
	NVAR calCurveIsValid = root:calCurveIsValid
	
	NVAR resumeButtonWidth = root:resumeButtonWidth
	NVAR panelWidth = root:panelWidth
	NVAR panelMargin = root:panelMargin
	NVAR status_leftEdgePosition = root:status_leftEdgePosition
	NVAR entryHeight = root:entryHeight
	
	SVAR sInstrumentID = root:sInstrumentID
	
	IRIS_UTILITY_ValidateGasInfo()
	NVAR gasInfoIsValid = root:gasInfoIsValid
	
	wave/T wStatusStrings = root:wStatusStrings
	
	switch( ba.eventCode )
		case 2: // mouse up
			if(IRIS_Running == 1)
				if(IRIS_WaitingForUser1 == 1)
//					ModifyControl IRIS_Run_tabRun, win = IRISpanel, title = "RUNNING"
					if(cmpstr(ba.ctrlName,"IRIS_Resume1_tabRun") == 0)
						ModifyControl IRIS_Status1_tabRunOrReanalyze, win = IRISpanel, valueColor = (16385,28398,65535), size = {panelWidth - status_leftEdgePosition - panelMargin - panelMargin/2,entryHeight}
						ModifyControl IRIS_Resume1_tabRun, win = IRISpanel, disable = 3
						wStatusStrings[0] = "resuming"
						IRIS_WaitingForUser1 = 0
					endif
				endif
				if(IRIS_WaitingForUser2 == 1)
					if(cmpstr(ba.ctrlName,"IRIS_Resume2_tabRun") == 0)
						ModifyControl IRIS_Status2_tabRunOrReanalyze, win = IRISpanel, valueColor = (16385,28398,65535), size = {panelWidth - status_leftEdgePosition - panelMargin - panelMargin/2,entryHeight}
						ModifyControl IRIS_Resume2_tabRun, win = IRISpanel, disable = 3
						wStatusStrings[1] = "resuming"
						IRIS_WaitingForUser2 = 0
					endif
				endif
				if(IRIS_WaitingForUser3 == 1)
					if(cmpstr(ba.ctrlName,"IRIS_Resume3_tabRun") == 0)
						ModifyControl IRIS_Status3_tabRunOrReanalyze, win = IRISpanel, valueColor = (16385,28398,65535), size = {panelWidth - status_leftEdgePosition - panelMargin - panelMargin/2,entryHeight}
						ModifyControl IRIS_Resume3_tabRun, win = IRISpanel, disable = 3
						wStatusStrings[2] = "resuming"
						IRIS_WaitingForUser3 = 0
					endif
				endif
				IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", secs2time(DateTime,3) + "  " + "User clicked \"RESUME\"")
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
	NVAR extCmdQueueAgentPeriod = root:extCmdQueueAgentPeriod
	
	SVAR sInstrumentID = root:sInstrumentID
	
	wave/T instructionQueueForIRIS = root:instructionQueueForIRIS
	
	switch( CB_Struct.eventCode )
		case 2: // mouse up
			if(IRIS_Standby == 0)
				if(IRIS_Reanalyzing == 0)
					redimension/N=0 instructionQueueForIRIS
					IRIS_Standby = 1
					IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", secs2time(DateTime,3) + "  " + "Started listening for external commands")
					variable ticksAtStart = ticks 
					CtrlNamedBackground extCmdQueueAgent, proc = IRIS_UTILITY_ExtCmdQueueAgent, period = extCmdQueueAgentPeriod*60, start = ticksAtStart + extCmdQueueAgentPeriod*60
				endif
			else
				IRIS_Standby = 0
				IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", secs2time(DateTime,3) + "  " + "Stopped listening for external commands")
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
	NVAR IRIS_WaitingForUser1 = root:IRIS_WaitingForUser1
	NVAR IRIS_WaitingForUser2 = root:IRIS_WaitingForUser2
	NVAR IRIS_WaitingForUser3 = root:IRIS_WaitingForUser3
	
	NVAR resumeButtonWidth = root:resumeButtonWidth
	NVAR panelWidth = root:panelWidth
	NVAR panelMargin = root:panelMargin
	NVAR status_leftEdgePosition = root:status_leftEdgePosition
	NVAR entryHeight = root:entryHeight
	
	SVAR ECL_clearQueue = root:ECL_clearQueue
	SVAR ECL_CloseAllValves = root:ECL_CloseAllValves
	SVAR sResultsFileTXT = root:sResultsFileTXT
	
	wave/T wStatusCategoryNames = root:wStatusCategoryNames
	wave/T wStatusStrings = root:wStatusStrings
	
	variable thisStatusCategory
	
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
					ModifyControl IRIS_Status1_tabRunOrReanalyze, win = IRISpanel, valueColor = (16385,28398,65535), size = {panelWidth - status_leftEdgePosition - panelMargin - panelMargin/2,entryHeight}
					ModifyControl IRIS_Status2_tabRunOrReanalyze, win = IRISpanel, valueColor = (16385,28398,65535), size = {panelWidth - status_leftEdgePosition - panelMargin - panelMargin/2,entryHeight}
					ModifyControl IRIS_Status3_tabRunOrReanalyze, win = IRISpanel, valueColor = (16385,28398,65535), size = {panelWidth - status_leftEdgePosition - panelMargin - panelMargin/2,entryHeight}
					ModifyControl IRIS_Resume1_tabRun, win = IRISpanel, disable = 3
					ModifyControl IRIS_Resume2_tabRun, win = IRISpanel, disable = 3
					ModifyControl IRIS_Resume3_tabRun, win = IRISpanel, disable = 3
					for(thisStatusCategory=0;thisStatusCategory<3;thisStatusCategory+=1)
						if(cmpstr(wStatusCategoryNames[thisStatusCategory]," ") != 0)
							wStatusStrings[thisStatusCategory] = "..."
						endif
					endfor
					IRIS_WaitingForUser1 = 0
					IRIS_WaitingForUser2 = 0
					IRIS_WaitingForUser3 = 0
					IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", secs2time(DateTime,3) + "  " + "User clicked \"STOP\"")
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
//						IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", secs2time(DateTime,3) + "  " + "Stopped listening for external commands")
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
					Notebook StatusNotebook, selection={startOfFile, endOfFile}
					Notebook StatusNotebook, text = "STATUS LOG"
					
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
								IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", "*** WARNING: All files must be in the same directory! ***")
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
					
					IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", "The following files were selected for reanalysis:")
					for(thisFile=0;thisFile<numberOfFiles;thisFile+=1)
						IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", wSTRrootNames[thisFile] + " (.str/.stc)")
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
						IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", "*** WARNING: You must first choose files to reanalyze! ***")
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
				ModifyControl IRIS_ShowDiagnostics_tabRunOrReanalyze, win = IRISpanel, title = "Hide"
				diagnosticsShown = 1
			else
				KillWindow/Z IRIS_DiagnosticGraph
				ModifyControl IRIS_ShowDiagnostics_tabRunOrReanalyze, win = IRISpanel, title = "Diagnostics"
				diagnosticsShown = 0
			endif
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function IRIS_GUI_ShowLog_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	NVAR logShown = root:logShown
	
	switch( ba.eventCode )
		case 2: // mouse up
			if(logShown == 0)
				SetWindow StatusNotebook, hide = 0
				ModifyControl IRIS_ShowLog_tabRunOrReanalyze, win = IRISpanel, title = "Hide"
				logShown = 1
			else
				SetWindow StatusNotebook, hide = 1
				ModifyControl IRIS_ShowLog_tabRunOrReanalyze, win = IRISpanel, title = "Log"
				logShown = 0
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
	
	NVAR maxAxisLabelLength = root:maxAxisLabelLength
	
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
	
	string sYaxisLabel1, sYaxisLabel2, sYaxisLabel
	
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
//						ModifyGraph/W=IRISpanel#ResultGraph axRGB(left)=(16385,28398,65535), alblRGB(left)=(16385,28398,65535), tlblRGB(left)=(16385,28398,65535)
						ModifyGraph/W=IRISpanel#ResultGraph axRGB(right)=(30583,30583,30583), alblRGB(right)=(30583,30583,30583), tlblRGB(right)=(30583,30583,30583)
						sYaxisLabel1 = wtOutputVariableNames[variableToGraph1] + " (" + wtOutputVariableUnits[variableToGraph1] + ")"
						if(strlen(sYaxisLabel1) > maxAxisLabelLength)
							sYaxisLabel1 = wtOutputVariableNames[variableToGraph1] + "\r\n(" + wtOutputVariableUnits[variableToGraph1] + ")"
						endif
						Label/W=IRISpanel#ResultGraph Left sYaxisLabel1
						sYaxisLabel2 = wtOutputVariableNames[variableToGraph2] + " (" + wtOutputVariableUnits[variableToGraph2] + ")"
						if(strlen(sYaxisLabel2) > maxAxisLabelLength)
							sYaxisLabel2 = wtOutputVariableNames[variableToGraph2] + "\r\n(" + wtOutputVariableUnits[variableToGraph2] + ")"
						endif
						Label/W=IRISpanel#ResultGraph Right sYaxisLabel2
						ModifyGraph/W=IRISpanel#ResultGraph lblMargin(right)=5
						ModifyGraph/W=IRISpanel#ResultGraph mode(wOutputMeanToGraph2)=3, rgb(wOutputMeanToGraph2)=(30583,30583,30583), marker(wOutputMeanToGraph2)=16, msize(wOutputMeanToGraph2) = 5, mrkThick(wOutputMeanToGraph2)=2
						ErrorBars/W=IRISpanel#ResultGraph wOutputMeanToGraph2 Y, wave=(wOutputErrorToGraph2,wOutputErrorToGraph2)
						ModifyGraph/W=IRISpanel#ResultGraph zmrkNum(wOutputMeanToGraph2)={wOutputFilterToGraph2}
						ModifyGraph/W=IRISpanel#ResultGraph fSize(right) = graphFontSize
					else
						AppendToGraph/W=IRISpanel#ResultGraph/L wOutputMeanToGraph2 vs wOutputTimeToGraph2
						ReorderTraces/W=IRISpanel#ResultGraph wOutputMeanToGraph1,{wOutputMeanToGraph2}
						ModifyGraph/W=IRISpanel#ResultGraph axRGB(left)=(0,0,0), alblRGB(left)=(0,0,0), tlblRGB(left)=(0,0,0)
						sYaxisLabel1 = wtOutputVariableNames[variableToGraph1] + " (" + wtOutputVariableUnits[variableToGraph1] + ")"
						if(strlen(sYaxisLabel1) > maxAxisLabelLength)
							sYaxisLabel1 = wtOutputVariableNames[variableToGraph1] + "\r\n(" + wtOutputVariableUnits[variableToGraph1] + ")"
						endif
//						sYaxisLabel1 = "\K(16385,28398,65535)" + sYaxisLabel1
						sYaxisLabel2 = wtOutputVariableNames[variableToGraph2] + " (" + wtOutputVariableUnits[variableToGraph2] + ")"
						if(strlen(sYaxisLabel2) > maxAxisLabelLength)
							sYaxisLabel2 = wtOutputVariableNames[variableToGraph2] + "\r\n(" + wtOutputVariableUnits[variableToGraph2] + ")"
						endif
						sYaxisLabel2 = "\K(30583,30583,30583)" + sYaxisLabel2
						sYaxisLabel = sYaxisLabel1 + "\r\n" + sYaxisLabel2
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
					if(strlen(sYaxisLabel) > maxAxisLabelLength)
						sYaxisLabel = wtOutputVariableNames[variableToGraph1] + "\r\n(" + wtOutputVariableUnits[variableToGraph1] + ")"
					endif
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
	
	NVAR maxAxisLabelLength = root:maxAxisLabelLength
	
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
	
	string sYaxisLabel1, sYaxisLabel2, sYaxisLabel
	
	switch(CB_Struct.eventCode)
		case 2:		// Mouse up
			useSeparateGraphAxis = CB_Struct.checked
			if(useSeparateGraphAxis != useSeparateGraphAxis_old)
				if(useSeparateGraphAxis == 1)
					RemoveFromGraph/W=IRISpanel#ResultGraph wOutputMeanToGraph2
					AppendToGraph/W=IRISpanel#ResultGraph/R wOutputMeanToGraph2 vs wOutputTimeToGraph2
					ReorderTraces/W=IRISpanel#ResultGraph wOutputMeanToGraph1,{wOutputMeanToGraph2}
//					ModifyGraph/W=IRISpanel#ResultGraph axRGB(left)=(16385,28398,65535), alblRGB(left)=(16385,28398,65535), tlblRGB(left)=(16385,28398,65535)
					ModifyGraph/W=IRISpanel#ResultGraph axRGB(right)=(30583,30583,30583), alblRGB(right)=(30583,30583,30583), tlblRGB(right)=(30583,30583,30583)
					sYaxisLabel1 = wtOutputVariableNames[variableToGraph1] + " (" + wtOutputVariableUnits[variableToGraph1] + ")"
					if(strlen(sYaxisLabel1) > maxAxisLabelLength)
						sYaxisLabel1 = wtOutputVariableNames[variableToGraph1] + "\r\n(" + wtOutputVariableUnits[variableToGraph1] + ")"
					endif
					Label/W=IRISpanel#ResultGraph Left sYaxisLabel1
					sYaxisLabel2 = wtOutputVariableNames[variableToGraph2] + " (" + wtOutputVariableUnits[variableToGraph2] + ")"
					if(strlen(sYaxisLabel2) > maxAxisLabelLength)
						sYaxisLabel2 = wtOutputVariableNames[variableToGraph2] + "\r\n(" + wtOutputVariableUnits[variableToGraph2] + ")"
					endif
					Label/W=IRISpanel#ResultGraph Right sYaxisLabel2
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
					sYaxisLabel1 = wtOutputVariableNames[variableToGraph1] + " (" + wtOutputVariableUnits[variableToGraph1] + ")"
					if(strlen(sYaxisLabel1) > maxAxisLabelLength)
						sYaxisLabel1 = wtOutputVariableNames[variableToGraph1] + "\r\n(" + wtOutputVariableUnits[variableToGraph1] + ")"
					endif
//					sYaxisLabel1 = "\K(16385,28398,65535)" + sYaxisLabel1
					sYaxisLabel2 = wtOutputVariableNames[variableToGraph2] + " (" + wtOutputVariableUnits[variableToGraph2] + ")"
					if(strlen(sYaxisLabel2) > maxAxisLabelLength)
						sYaxisLabel2 = wtOutputVariableNames[variableToGraph2] + "\r\n(" + wtOutputVariableUnits[variableToGraph2] + ")"
					endif
					sYaxisLabel2 = "\K(30583,30583,30583)" + sYaxisLabel2
					sYaxisLabel = sYaxisLabel1 + "\r\n" + sYaxisLabel2
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
			NVAR numVariablesToAverage = root:numVariablesToAverage
			wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
						
			output1_gasID = PU_Struct.popNum - 1
			if( (output1_gasID > (numSampleGases + 2)) || (output1_gasID == 0) || (output1_gasID == 2) ) // output1_gasID == 0 is all gases, output1_gasID == 1 is all samples, output1_gasID == 2 is all refs
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
			NVAR numVariablesToAverage = root:numVariablesToAverage
			wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
			
			output2_gasID = PU_Struct.popNum - 1
			if( (output2_gasID > (numSampleGases + 2)) || (output2_gasID == 0) || (output2_gasID == 2) ) // output2_gasID == 0 is all gases, output2_gasID == 1 is all samples, output2_gasID == 2 is all refs
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
			NVAR numVariablesToAverage = root:numVariablesToAverage
			wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
			
			output3_gasID = PU_Struct.popNum - 1
			if( (output3_gasID > (numSampleGases + 2)) || (output3_gasID == 0) || (output3_gasID == 2) ) // output3_gasID == 0 is all gases, output3_gasID == 1 is all samples, output3_gasID == 2 is all refs
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
			NVAR numVariablesToAverage = root:numVariablesToAverage
			wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
			
			gasToGraph1 = PU_Struct.popNum - 1
			if( (gasToGraph1 > (numSampleGases + 2)) || (gasToGraph1 == 0) || (gasToGraph1 == 2) ) // gasToGraph1 == 0 is all gases, gasToGraph1 == 1 is all samples, gasToGraph1 == 2 is all refs
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
			NVAR numVariablesToAverage = root:numVariablesToAverage
			wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
			
			gasToGraph2 = PU_Struct.popNum - 1
			if( (gasToGraph2 > (numSampleGases + 2)) || (gasToGraph2 == 0) || (gasToGraph2 == 2) ) // gasToGraph2 == 0 is all gases, gasToGraph2 == 1 is all samples, gasToGraph2 == 2 is all refs
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
			NVAR numVariablesToAverage = root:numVariablesToAverage
			wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
			
			if( (output1_gasID > (numSampleGases + 2)) || (output1_gasID == 0) || (output1_gasID == 2) ) // output1_gasID == 0 is all gases, output1_gasID == 1 is all samples, output1_gasID == 2 is all refs
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
			NVAR numVariablesToAverage = root:numVariablesToAverage
			wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
			
			if( (output2_gasID > (numSampleGases + 2)) || (output2_gasID == 0) || (output2_gasID == 2) ) // output2_gasID == 0 is all gases, output2_gasID == 1 is all samples, output2_gasID == 2 is all refs
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
			NVAR numVariablesToAverage = root:numVariablesToAverage
			wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
			
			if( (output3_gasID > (numSampleGases + 2)) || (output3_gasID == 0) || (output3_gasID == 2) ) // output3_gasID == 0 is all gases, output3_gasID == 1 is all samples, output3_gasID == 2 is all refs
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
			NVAR numVariablesToAverage = root:numVariablesToAverage
			wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
			
			if( (gasToGraph1 > (numSampleGases + 2)) || (gasToGraph1 == 0) || (gasToGraph1 == 2) ) // gasToGraph1 == 0 is all gases, gasToGraph1 == 1 is all samples, gasToGraph1 == 2 is all refs
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
			NVAR numVariablesToAverage = root:numVariablesToAverage
			wave wIndicesOfVariablesToAverage = root:wIndicesOfVariablesToAverage
			
			if( (gasToGraph2 > (numSampleGases + 2)) || (gasToGraph2 == 0) || (gasToGraph2 == 2) ) // gasToGraph2 == 0 is all gases, gasToGraph2 == 1 is all samples, gasToGraph2 == 2 is all refs
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
		string sWaveListStr = "wtParamNames;wtParamValues;wtParamUnits;wtParamTypes;"
		Save/O/J/DLIM=","/B/P=pIRISpath sWaveListStr as sConfigFileName
	endif
	
End

Function IRIS_GUI_ChangeNumGases_SetVariableProc(SV_Struct) : SetVariableControl
	STRUCT WMSetVariableAction &SV_Struct
	
	IRIS_UTILITY_UpdateNumGasesInTables()
	
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
	
				// Save wtParamValues to the .iris file to record any user modifications to it, but restore wtParamNames, wtParamUnits, and wtParamTypes from the .iris file to undo any user modifications to them...
				string sColumnStr = "F=-2,N=wtParamNames;F=-2,N=wtParamValuesOld;F=-2,N=wtParamUnits;F=-2,N=wtParamTypes;"
				Loadwave/Q/P=pIRISpath/J/N/L={0, 0, 0, 0, 0}/B=sColumnStr sConfigFileName // /L={nameLine, firstLine, numLines, firstColumn, numColumns}
				wave/T wtParamValuesOld = root:wtParamValuesOld
				string sWaveListStr = "wtParamNames;wtParamValues;wtParamUnits;wtParamTypes;"
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
	
	variable hookResult = 0

	switch(s.eventCode)
		case 2:				// diagnostic graph window killed
			diagnosticsShown = 0
			DoWindow IRISpanel
			if(V_flag == 1)
				ModifyControl IRIS_ShowDiagnostics_tabRunOrReanalyze, win = IRISpanel, title = "Diagnostics"
			endif
			break
	endswitch

	return hookResult		// 0 if nothing done, else 1
	
End

Function IRIS_GUI_LogKilledHook(s)
	STRUCT WMWinHookStruct &s
	
	NVAR logShown = root:logShown
	
	variable hookResult = 0

	switch(s.eventCode)
		case 15:				// diagnostic graph window killed
			logShown = 0
			DoWindow IRISpanel
			if(V_flag == 1)
				ModifyControl IRIS_ShowLog_tabRunOrReanalyze, win = IRISpanel, title = "Log"
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
	
	NVAR maxAxisLabelLength = root:maxAxisLabelLength
	
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
	if(strlen(sYaxisLabel) > maxAxisLabelLength)
		sYaxisLabel = diagnosticOutput1_name + "\r\n(" + diagnosticOutput1_units + ")"
	endif
	Label/W=$sDiagnosticGraphName Left sYaxisLabel
	sYaxisLabel = diagnosticOutput2_name + " (" + diagnosticOutput2_units + ")"
	if(strlen(sYaxisLabel) > maxAxisLabelLength)
		sYaxisLabel = diagnosticOutput2_name + "\r\n(" + diagnosticOutput2_units + ")"
	endif
	Label/W=$sDiagnosticGraphName Left2 sYaxisLabel
	sYaxisLabel = diagnosticOutput3_name + " (" + diagnosticOutput3_units + ")"
	if(strlen(sYaxisLabel) > maxAxisLabelLength)
		sYaxisLabel = diagnosticOutput3_name + "\r\n(" + diagnosticOutput3_units + ")"
	endif
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

// NOTE: this ASCII-encoded picture was created using the Pictures... panel in the
// Misc menu, from a PNG that has the desired image repeated 3 times horizontally
// (I can't remember why that's necessary, but it works). The PNG dimensions were
// width = 2700, height = 140, but Igor put in the comment "PNG: width= 648,
// height= 33" above the Picture keyword for some reason.

// PNG: width= 648, height= 33
Picture AerodyneLogoButtonPic
	ASCII85Begin
	M,6r;%14!\!!!!.8Ou6I!!!@b!!!"X#R18/!).;K\c;^1RUoSmAkbu".KBGK#QP&0&c`"6!!!$"!<<
	*#)?9p@!!!$"!!$%#)ZU$A!!!$"!!$=+-ia>L!!!$"!WW3$0`V7T!!!c7!!$VdB`J89!!!$"!!%BHz
	!!+VN!!!$"!!+VN!!!$rBm=3*D..O)EZe2!D]ghg2D-^?!!!(n!WW?'!!!$"!"+[X!rrH(!!!$"!!%
	rX!!!!Qn^`0i!!!=E86L!6!%oJr!%oJsGbmWJ!!!+ABiJ2V=A;IM@rH3:@:X:cAM/4EDu]k<!!#-+3
	d>L\D.Rft+F%a>DK@j`4X+<FDdm9=DK@jUATV?6+s;+kG\qDACHWkD9i)s"DfTD32D-[90Hr[f+<Vd
	hEb&cC;FEtsG\q87F#n>PAj%>OFEDI_0/%NnG:n(q/oPcC0/5II3A3'A0/>:7Eb&c6F*VYF@<aAAF!
	Dkm$6UH6+<VdhEb&cC6tLFLEbTK7Bl@l3Eb&cC@:F.tF?Lfl$6UH6+<VdL+<VdL+F%a>DK@jMG\LbQ
	,%u(?E&oX*DK@F=A8bpg/n8g:04fBBAhPkk0J=UW+<VdL+<VdL+<VdLG\q87F#nP_E'5CYFEDI_0/%
	3a/n&:/@V%0%Df%.P@;mkS/heq&$6UH6+<VdL+<VdL+F%a>DK@j\BkCs?,%u(?E&oX*DK@F=A8bpg/
	n8g:06Co?AhPkk0J=V6$6UH6+<VdL+<WdXG\LbN:hb/cCfs/?D.RU+Bl@lQ0f1RH04fBBAi`b&G\(\
	o6tpLLDKBN1DE\CM+<VdL+<VdL4CrbOAi`b&G\(\n6tpLLDKBN1DE]g70JGUBAU%p$3`'O8ASbI:Bl
	.F!F(oQ14piDT+<VdL+<VdhG\qC\6ZQaHFDl2!Df9GU:hb/cCi*U&DfQssEc3'V/iG=:1H[=8D/_O'
	Eb/[$DfSfqDeqTE+<VdL+<VdL+?XmcE&p^)FCA]gFC@RGFCdWk0JYI:0et=80iTka3\rTR1H@$@2**
	EF4>1qrE&p^)FCA]gFC@RGFCdWC+<VdL+<VdL+?Xa[AnF)+;IsofCisi6Df.`p0JG170JG.70JG174
	>1ejAnF)+;IsofCisi6Df.`G+<VdL+<VdL+?Xa[AnF)%ATMd+F`_>9DH1RgF?VHB06Co?Ai`h$F)Pl
	;FD5Z2<GlMm4piDT+<VdL+<VdhFD5?!3a#?lF)Pl;FD5Z24u4lH0JG170/5.70JGUBFD5?!3a#?lF)
	Pl;FD5Z24piDT+<VdL+<VdhFD5?!3_sd1ASuTuFD5Z24u#/QFD5?!3_sd1ASuTuFD5Z24piDT+<VdL
	4>1_cAi`=kF(96)E-,f4DE\CM+<Wd"Eb&cC;FEu<$9Ttd3d>L\D.Rft4ppT1?\/7X+94u$5u`*!m+l
	lU<9:eXnB^hhe$e_N95dH:V-+@6&k-:8Pa"$[.UWR]#_JM4T(+-d`^E*X5`@XfHP<T%PMBqJs-]T9M
	QpVVb#5%Qp+eGe4Q#$<94rf3bKS8unp.uV8@"cVh:^JLq4-V.cPI]J+sJ3T+sJ3T+sJ3T+sJ3T+sJ3
	T+sJ3T+sJ3T+sJ3T+sJ3T+sJ3T+sJ3T+sJ3T+sJ3T+sJ3T+sJ3T+sJ3T+sJ3T+sJ3T+sJ3T+sJ3T+s
	J3T+sJ3T+sJ3T+sJ3T+sJ3T+sJ3T+sJ3T+sJ3T+sJ3T+sJ3T+sJ3T+sJ3T+sJ3T+sJ3T+sJ3T+sJ3T
	+sJ3T+sJ3T+sJ3T+sJ3T+sJ3T,!(0DV@0&l)a%VZfGa-p--ugq@;APf^_X_c;.JV*l8E,R*kYSaE['
	8hr-2s.6o<A8'+kfg&J<Eq@3-[<+sJ3T+sJ3T+sNa\iIoT01Ao^Wq=XRICD,j3MI%(^-7WSW((7K2`
	0:6-X(m1e"X4L+&gFVU<@r`9LhmmH:5.M<"C":!`JSK=&QuUBhHR!?E(EAb6psG-I@(7rLkpkCLkpk
	CLkpj8h)Jh"K<D`QL&s"F5K+I"?%Sb_hu7lmpRjP[ciO4C&BTVM#='EB,DufSAcWfLd3(]f6>?O;&A
	^HfR,p'DS!tId[Nc7=((h,j&J5Tq7E4nkg?#S)OElqDLkpkC.*JmU";)4X&J:iA-]GL?#tq/XHHi_b
	:chF&:B=?;:n+\OYog&/q(7.C3>e+t%mV,](dr*AntlE5,<,Dag)k`cCDtMl6psF27!.3o*[DpR+sJ
	5*K<aG>&J5Te&[`u](eq?a9;Vpj2TG@JJh_d773E7eY8FU4!:Oa\2>CB;C<E-k:mhUjrWH`&E"W"r;
	,Ld#MXOUl(`nNiLkpkCg5^H?LkpkCLklP\%YR5<6psG-8XqK'#-'/>0=[_"`,.^Pe;GmMb>8Vf@=k$
	M^KS&@PZO?C,<p&.;@fR"(p&MPJ"V$--Lg!*ilt[>NS9?B779O36q#Nj0Fnd.&J5TedD=ITJr#5=Lk
	r>?-]Fp!`R5)@^-05t)gB>YaJFD-ViY4Th,384&(d?fEP::Im80Z5!c/,2B7W/Mi:XK(gHOab+V>:u
	&J7n+Qj8J(LkpkCBFf9V+<i!R,,/nm$)=IC=$1_M2pV]J_r).-k<dN)lL47#_!NX%cT'f\1GR-s-;B
	"O5[K$"\&Om"f?Bkq$=H[U+sJ3T,2/$%OGJ^KLkpl>EIs"&LkpjJ"ATds7MSQHSCj.KQ(B?^_!#H/F
	Aot#H'kYhX$#ucW*GFM,*/-?TJ_8tb8<A/Ks>ImO)M/CFB(^s6psF2RD_3Y6psF26q$B$5t"+/6pr%
	eZ3+7:T.B)31T^D9aKI^a7j**q'Kt/(3!co)LRKdn=f;<K#'?rSq@h>R:Ck*ZiL!;?779O36q!7gb_
	&;O6psF2a$$um_5k1,DN%8/'CGr6/5jlbHqb@[?rT(`Fo%oGaCH^G<IlePFHHXrb,`/!*'!QK+hP'(
	&J5Te&Tn0QE1]8'pnua*L4a*<L&EWSP%-YJMG.9[k02Q\S:Bne[2[F(4O@=Q\7\`^=q^nE,pXZY+sN
	c,Nd7i4o,nVW&J5Tqf@Y(pLkpkCLcR"\(eqkYo4N`9<fI=ElVLgr+IJTBS"&8AGK+@JimuU!YMCT0D
	hqo;PLj>P?En0iIARAr+sJ3T,"`+&_*]me&eP]f&^bU_b5'WtZ_$uT'mpoO2\NQuCP5lZ\748sZN)#
	8dK3@n!iQdj2&!d7f/tbcoh6/i6psF26uD*t\q#h#Et:tpKbsWD$N;''cQIq&SVV*\BeK7ql\7%oOI
	N91[K?QW92s5q3s]s(eE-"s00,d;0>5<SAVc.uLkr"Y?lj,!o,nVW&J5Tq:ZUN-?C*Tego7c.MC2AB
	$<f2igDB$-o&&3&HCkLO5cT]8'*/XF0M!d5-p;o^?I#BK^/F^RF)Ii_,9e<U,,4.<_Pe"*k1r#6o=T
	"@i!oa8;LNqDFt(_;IVNM4YBNuh&0P7WI?$-7!\d)DqNWDuelD\/Kh[sfLkpkCLkmGoQj8\0H'!i<L
	kpjJ[EI^Y#bO*E`%f8>N^@XfOI(jb$HsT9eFjBP@SA83f1q8+k;Y2C8]dkWXQt<"j]f4/r^&`r71g+
	D&J:.TS1o6lW[_q/=`_-PpMUUj!C/Ur-PDX\o`k0SZL-i0CO0nq`HWBG*Jp0rL>X=ZS5sn.\>l!!?[
	+fa"VD=Y&J5V_(%Yg2Qj8J(Lkpkc;qfuG6BrQ=p0kuJ+sJ3TU(49"%77IlbN@+V)m/ok<:>S""DE*/
	f*Yn#q!C/8I!VZH]1W0pQHo)ufbPgX"9".5558%JI(#dm+sJ3TU(2m&n<bm?&eP]f&Q,G[DVg?t@,j
	$c\/IUuWfJgK.SiE15$U<u\@)$R5_c-3*:9C/K'+*YF4WN.rUii#6UX=16psPc'h2C^jfp7sk#g+*:
	tuGO560.BV\K169Cd6g\"gP3/eM@<%d-NPI"e.j'AlY@kgCtfg&09>M+e^R6psF27-"UEi%\^_,U+E
	V,,,R,*@I#eNY=fK6psE`$n$uTjPhPjbDXp7A6&OA5Y8SZ>TcKKZEq:>Z`nH[J?j>]Iqj\1341JQo=
	L$noW;E&^"AS6Jr#5=LkpkIKR#7_Qj8J(Lkpkc6b7+5N:9dGr9nEopbrIJ,J?#JM?s&]p%iNC-sn6k
	r="4JBfob6(]_5Q34I)a=3)hWhYC@:92F26(I^_[6psGFj+PhY9Un2@(sSEKi5Yh<1/NQ.:_X8U?Ds
	tZ/I(8MFM'[ApD4HMUh<AspoH"'Xa0TMqFh\n6psF27+<.;_3AFN,U+EV,,,R$*@Hjb4&->!&J5Ut!
	1YaSgVgX$MI#c?"Rp7.To9_\,2kf9LYJkVD[#WuN7O.1@0!2k1g#(\(&t@]q70V)$R-c=+sJ5b+7im
	o0Fnd.&J5UPLVSo`.Dq/Z6psF26s6ZUmYo>8Qd*:B0Oa;V"_Jt-"*1.3&<%1QN?[#?d99Eq!nF8V/F
	e?iG<M@\l!fI)LkpkCp0\q846AgQ+sJ3Tb%_UQ:+6\@P1rtk%mYTU(SD<?cL"oG3X!MSJ7uRHOBQq(
	R$M]]YP4ZsUdq;?+X/*S,,,/[pCg$:4uO]2f%^P]kn"P>\fLj3W%G751od9+XhKr/.poDul_B)FbR\
	?t(a:.J+sJ5n_03^Y845j66pt0l?cNKO4u1l4U80KKEtk;9!ns$H3`8@s![qpg]XnC)]qd(*oah]I&
	J<DSa7Y,5MPV%_6*4H:^`<u.K0h>!'7^3nFrEe%J4QPq8LZq.d'"dd_":<e6:=406q#))MPV%_IZ;%
	(H*Ehn%h]Hd&J7m+@E453A&em"+sJ5*/9Leb(fa,UQCQ@&qJ?4\Z=Inc!4H#iJ+Q-a!U-->@T#ru"P
	"CgB.a$D.[E,`/r,7=LkpkI6bDq4J8^!aYl-6d&eP]f&Q+j%a,+uWNY=fK6psFGk.$s9HMPF]oM`a'
	'KR_m[Ho+m&UA]aL/U!ei_fcm9NRH*j\X/BfPC@uLdmH[k9(?K&J5Ud#4l4l0b4m/&J5UP7^3&(4(H
	;;+sJ3TU9&B?%aL#]CeDXu^g0dM4O^_)Vcb1(D;I#BES!8'/+iI-(R/NEH]$QRW9N.pdtJ>F&J5W&n
	Ul*@.khJH&J5Te;.d$7@:lb(";)4X&Q.+=/glV?e`laAogU&s6D/(Q#j1Pil?V:4g=#4^>V2%&VTVR
	f#D+Jd<j*Mb>oLk-0gnDt6pu-E?lmN!b_&;O6psG-&aVK>;=$8.6psF2PQd)Z&*$_BR/AC8q[ENcRB
	C,1-5c?i[bC^FgTm[ENtdra87&0OC+&fa41hb0a-i>JKSYG?Lkn)Vk/".94@hk.6psH1MB+(M!]s-g
	&J5TeA_:u[@C0LhNErXOI8>AWRBC*[(XU3G23pG6D+DqL'W=:j$s^4Sl#*UU)BE+HS*<P$LkpkCW:O
	I>bXTg/6psF27+?\<E?Zp;irfr+&J7lp*B+X$UX?#S2"Bm3j:';)n,"uok!-+rlepM31''XQ%tTKl@
	XF+3?+-@J+sJ3TU3'cab\G@S6psF27$Ml]30@4nEIs"&LkmI3NgBbaH)%li["qrjTK(E>!.Y(B,4bV
	lf8gmS`TI8]A@eX3'!!r%WpP+5VX#?K+sJ5*:5=*Kb:sM?&J5Te;*(uB6oJMp#pLQ;,,.ak/gcNPS3
	*Q<iDuo-;_hY%*XZ_#DCSiX.6af$2$#ReUqlYB=0F]PP\%E=+sJ3T,3h:X#<N"L5p@Ks+sKViG+?Wg
	lo7:!6psG-!M02lGVg<r0mKTFj9lNP10r3i>.:o>GF_!S5TlJt-4;d5c3[Wl!eVX.&J5TeV#p6rLVZ
	)D6psF27-VLI'3U>9-]!S7LksblVnZa/ml`TEKH'G-!!=u^bPi3=BT2%u&/7FbmAt;Y]EuZKC9Re@`
	rc$XH_(-!UeE@(hm]<B?T.tc1L1I;nZI8jU5>UfL_]7ZUfsnO5U>JoVp:*E$$b9c,=+T+_kMnmR:!/
	nl-68Zp3Tda,,4,LKR)0TB,06]@](]!\rLVaC?f5u`fQshB"5e\Qn[$SWS/tbOfE&3J+AFif1kXjH1
	6?j1(P"[Dp3i%7$Pr`#Ka0+F/K__E%BG\.G8aBScW,+/KH3&#=Y8$W@N&`G+=r2l%*P110k>$&J5W&
	nY"?,(sS&\7X-+Y".E5P9)oV2\o?]'VKOq)V83#<1%HhjjV'##`We*:c*_[9>Ne=;H6'B+$cq'Vpp0
	rB5c#Q102]]V8F*:_l2^Zp'A'LF7b8h&[HTah&KQi\Y(`7$U"0>(MMMLk>2slD:k8aL+]&UT:]iZH-
	ZF$dLkscA<QkLu`!T`T>Xsbg&PpBpKSh`C:.qWJ)h>`oJGV-.1UTI05lf,]7+;FbK1&+lc'SaXO(^@
	bre]1'R4RbcTd!X)<AS1cNY>2B$PF$`&J:jHVk5[.=kj3p6)Ns-QiN8cr9]VK<U]=DT$-@JK'cCY'n
	dWt>k6#1'nok<2?k)6+s*liUa_VN^O+KY,9F>@gAp:8Ll(%Ma'`62_JQK!*O\;D^V=%S?ut@NF(2E,
	Xakk)JM]Q^;CmD+jji2e<!cO$mlX![,f?BM6hS("O)4W?hs[#a_3_A!]RG^M'8NQ)YPO'2kkI(+Ypm
	YK)K-`.qHU&#]AKY!qLC0EJ=)\WX$4ZIb_+,l7$Kgr5p@MqB$>ng(HYA3E)q.P+<o^qEIs"&Z5G`!U
	dh8R0KNXfjPa/4$^n/m2$t%aj_l[(<n6AC5WuL06'hp2J1Z:6)\Upj[*RWE2&JCMFk%oBSHt/OQF1i
	l&IR+7)ED4$^$fk\nOqUVcHQZ(6hu8!@u*-.N6%!<T1$D\?ekB,Kes8'ns?6n)Ts2(gcDqVMA`GY)g
	#*!Kd(gMU=&YHPE71KRVK<s!tt=>]`RX'iE^.KM26t$Y?81B2j-k#On[j+XA*%jP`;%8R0SSID3tQb
	La\`I&!C;d3!"OM-]"]1fPuM!Lp@m[:8C@WSM1tA7a2lac*m]_B"F;Gk[L(WWK)4A=I;g_k^0B9'OV
	l=qur*3)V+NR2r'5fPh!R9TQWGJZ@b?;"X3FO%rT.U4l6$p)S9!K7[ZYPZkZhZTn=IA/c04qHC1-?f
	hpP,-tgYfWa;S(\-T&Qe3$j)Wi[\Q/paK0i!L2e).6GK68W`H&i-SO3)nem=M1msm=c,a&HNH<-UI]
	D)$Be"2k3s9cC-/n0FooL&lIC<%h]IO2IddR^Y!OX*@HXkH0dLV6q#^e*@Fa_dnUa.ZcfonXjqEZY2
	]e."F=[@0'du$EC]j%!pP\&hOQ#Z63V;.iecG1k>qbsrOng.g`q]53-)'Z+J@mbE5(\Q_9sAWSI.]6
	?Il6'_`r=oG(%O+JnG*4DG.\Ba<dD\"p7u!^2k:+'CK+'QE]4;C2H(@K0*>YHH&QR!a\q9VnksC5?t
	U(Ah;DR&gb`$$kYeDhu/(K$P\k^7br1<779NH!3gVL7/Te\93C,EgGekA88Cqa<L=#Z#MT@P+E^`/K
	1&+leX-T`#BlVF`sEr))g7_o,,/nnNYAD@Bd\jcl<Xi@5LX`pM(1t0(Mk%rWN,k"ol([sU,F!g8O\(
	O*r_pAq5R3t"$<Z;iYhti,PCFI8hKCrqK?4gkLrYJrWK#SCmQ%j?Ucpa&?8?=f#-YOqFs4#@D#dB[8
	nOQ.n'gBG;go<7fYGY\l>E"W>u78`6Y;)Z;.Lq8\.QhNplO!f8LCu?P4Td=BhsQ2/6!$N(G"nTnQuF
	o)[o<Ck8N!.?FWDJS6Z8EW?)Kj02DhTN6Tf&s+uj3:DR4eo+`8eM=?,^I'2[%i%_fSAn9D,5c)Aomm
	#9,u.u2XtUAA&#LB=+E_;?K9QSaK1(q2b_+s]4&3$?";/$^4&->!;)Vq)M:CdS'1T0Mn>>UhYtL5U!
	OC2fPSiV\]t:BFpPmo4Y6JrLEkCX<&a*qiQh]sP+j9b-ME)%B/6Z)#nae34%Et79iS*npEgm!@TfI-
	:ZqZ1A505Zpc^FC\J)#$6;u4eeG5Z&<dR.EG:uG:QVIaIOBj#t]AS%HF9f//f",,1?N*`e8\Dm\#*u
	#k_gFK)J%CdA*>o.X2`]1jM3^m&,eJK+&/dttmHf-bS!s.=Fi'8T]Jfk&g:_AB^e,]PHYps\n\-g1(
	dmj#cqSl5i+,tX:\n;TFIf92H^T;2Mn!&XVWG-!?&&<>n`8B```HrpTS'tUXAJ+&jk/$c,4@l"Xo,s
	k;o,nXA!qRQ1_2]2q37/f"EIp5%G+9[!U9)@p'.MBZ-]E@jc\8)pVX*_;'QS1bhTfJUZ?+sMe=+@jG
	D,lH&GC!&20[*L=R#*$4V'aX[(l&;-#KMf$f!V<pUebc^&"h""Ra`hUh_*]a-I/p'*'RXe+&KMMTXr
	;!3Utr2TYV/3,&fG7-RSIOkTt'.JumsL^A1J`jp;th#nah5sJHc!6E(:/jSjnTM5oF6>F\teBmVJ\H
	#6Fht_^&JBJN8gbXE)F[+)9o+T=8=I,599o(3CR]lkpn_O2gLo`!V1E7N"N\D!@'D#T>k!A:FQj5'W
	Qj8Hr"dfP:%sFINa,.05`sM%TfPuMkJ/p"n-l(BS,.0JfK[I'PYlPU6@Sr@2iS(_o+:a)/&4&ceT$^
	e#;Gl<<PIi?So\HN4pEOM@!SAl`-)!TaU;?fc$T'-AT8G#*['\CTo@Vu=!d(c?p[ci=Y.3b(X&$B.J
	a];/mZb2R;!Zp?eR]<^FWXP/l1^1V`MQdVdNbroe&/HE$dkn=1htdI320pD>,RF[=5rh<D?k]QdTR3
	)%LUVZ(]Y\V*R5u3!eBuFKDA6_\bM$e-UkqdRT;*j&p47j"p4(*i(&<g<j;/blQ:%?G?L.NQj;*$H'
	!<53]H1e8djcI,"`U45ro?rS7'Bop:u\%e60':"JlJf:(U8PYiA,dATqNsK7_PB_+*NS5QUp:J6DrF
	!;I+Wf0n[q!a,`K6R)@\J?9\@(][MgbKnqm%>#h,.+9Gn5DaAtmFuL>c\D.Ak:DhdSe5@BbMZd?4$.
	%iSfBfTh)BsP]iBSI5YqQYFs'RLc5D$(UV0TObZ'[9S>D)nO1lc4m'WgjYIh#pZA']PWVF3[ZdW*%A
	QnDn:>rJ^f+^Kt)h>]tXHr0f4.o[ZaN";3$a::0i[B-p/?$qAH*@Yp2i#_<7\cOBZObH'7\D^A5bXg
	0'sbZ\Z7=*V;&3R]CcBRjb_+DJ0b7/#0FndnMD,Rh;0d-,eW/1"U0NZU=].=JIMW:Edn_XRqXh!*?6
	AK9rAE)R!K%McohIg_>Nf@FHGA41E,G_6SN"RUkr=fZ<)gNh._$+H+(o6,$0mW)EIuWYTHCDIj$XJ_
	SnHj[oJl&1G5u3dhpVqZEjL6d>-d5GS(79!30=TA"@-l/L&sC:^r(s5hAniD\sk54<4'\?MaZ&ig=C
	8\iIoUrk]A>6C;Lb'1%.Eq.R:E\aAu)YX"e4MgRPTc7rtk9oraHCUM8S2ErS)1)9A_LkaCD8$_Y#b"
	J&nEEUPtKo]NMY"TK&:*^?@rAOh7gW\R]\4V)GVe=Heh?I1SmG[eG>(N/(n.(ZafliIp8#)_@g4,G0
	B`FG59GVj!P4@[5`$hG=;nP*lrJ9#0M_ZO2W0S%18=%8DmU8AIp[W4J#Q;HBQBTDT!.ihX:L3n5;FR
	d%sU.uhl=g`a&e6!0Q&?9;<.2QBV!bVT"s*0WHU%mRcV5nM;YVu=GJ;CMIKI'Q<Cf>C>q"Ym65_+i3
	6<:"p/BT0Yk!;N-)20aT[K5tBo,r0Nb_),ib_&<J$I"-E2!d2aIdB&1NYBpQZ/Yt`"ZoHj;6$k\6qV
	U5$)7e0=#DjYIAEaS33TKi0]K'T2aB$s3))ia%($k/OrtqZL:uN7Y'A^,+_b&t-2mChrbu`Pr=&`2m
	/71*#6oKmDXibM#8XL'`r``NibUmO1-%<"m(%1)c[slb4\Jki=BbRCIsnt<jDsRTHN>.XU=2)&c"E/
	-",%+@Eil?jb0RL'S0Z>h=-TBgA+\7s_4AU5V$]G*Zj@"=Y'FP]:"fuM%Snt0)Zp$AH6V[6b&bnbnR
	$e%s3"?-9FYlZ)uINq0!N--<BW'n1<->ZmmK&0eYqt(*DqS+DsFL*h*cXuRtt:LC\#Ue[\pekar8Ca
	_1])JG.3CQ.-A@`@NHe08'HUM/kP4lQ$#Q`#DqXeb_(!O"f:=5ealPcQEa3nTH6?=J3!sN"]>TE%L"
	bH=JI?I!uYEAVPW=k"-C6TTnjb%X!SGV%H8r(>P@#k`Hf)@dY*'FJMG5>0\k,siZ"rMO1<_7aNZ1o)
	_-PlVJPD[SrOJbJ;pNhAh#(\EFKT"+Jb#c'>7@=OjB@0G+9[^g=1+/YnN#[QCA(8/3of8X>6DAVkr2
	i-a^7#F826PB_9h'-h.jmAF):<@\%8NB`D4.H@E6H]3V*H!g3Y!%Y,NLa8mPV'LCQ'S"9)R4I@)aF.
	t,W&R`Xl\9&!1r$D9[QD<b9$4MHX#(gJVA7>MTmE>*ZfA(29G='[f)85)#?m8G>;.*95NTZ8ap\MXQ
	;#.*4$(L]s!/"3h!X$81jgQl/;7UB:Q4t>-R$>p#>cqhV!T-*D*?n7k#QU2OV@K<2d$A>H^#83:Y0A
	Zq=5&S,cG?/4'W&OQ=5BMUh/MkM+.;gn!l1hZk0MZ[WEir6rW\7_5*%1nHM*a8eis>rO1oBQU?l<b[
	iB\4NI;MKNl\iFF85OXQ9=@h2h.X=\."_L4Eu+pK1,*_H'$H$ffWrP?K7>sOGFCb4@huY%YX5)*@KK
	ZJiY9&S=jt3`sEq^"a6D,]hUFne5<]9#@%DiZif`re%Pe7pE_QShVW_>2[:$[o;7CE!@UP!<!m#k#Z
	dpi2+D,I<BUqg=1,_f/O2.mR([G['L/p1i,&o[C`5*?AO/H8n@/O,JGOWPB82-a(hTm61;*'+T6Y5.
	kjJW9(TBC"W-4;r1D2sm#7)&j(DM:\fHk?AL&q''>r<4jP3^h"M"L2IdT3[Vqf]PdU<^T-oG4&":*<
	R?lZs=9%X[sFM_c0fT_ch+Kp/F6X1qE(PT3K4RG\&g;2:s)h@P/=KHd?!%,[tC,AkPTji,QZ$%R<jQ
	n]*m#4is[.*R=.0$36A"kNE!b[DP<U'!([da>9$@JaKRM5+S$$0l3VEIuVm*=.KM-.m2]jZ:qF;:hI
	r=:Fi.X[7Bcn(KeIko0K#RrEi^@,gU(g?(B)90K1Nebc'BK-@f0O>VRa=?L5%6Ad\&f[.)V03ApE`J
	mf&]WOH%bGn4.Ais%6gKOVgo<0eLQG6kA6m1]\^7odk4Dqk?7?=kuZX#!_U.$-9KdIqo=Vn8,j92Cg
	J.R5nZsbg3'bi.1P6(S)eKlT<I+I;^Wcf?^-^jq7M_P3p\Tgi51#dK7e2[F3_$.6T.0$t;QUIC[KhJ
	9Y8Q0,+5^]ts:hVG^XP1@6bi+ClcI.S_RQcT+70VlMX[gp54`TnSo)G9ZGbs;GLaWWZ`6Qh<!gNN7>
	d,a!CZ,*>EMP13d$3Il<l$nc$I".)@NM>*KR&[-Te1Od'd#4B'%$`I#O*YhJM7biET5'lEIp4eG+>5
	4@0]+C8d0C.8@_JO@<?a9BrI_?gAlpAqqNJ>@V<?cqWs],oQgCj6.<J57Drue>Pd3r;7Qtd**$-N<3
	3t!W0LUXCn;@ZA0C%>TRC:S=?hN5=^TWfp@,r,PudNO#^kH2[\$"p$ks:`h0/n8LubMb6A=@UQ#Jbc
	2>Hgj^2J5mB^McXKT4N8nNpP+0H>[[<&#.R6#m2u5"(-7ku%af?'UOZkWZ<pm/i8C&YO?r57p2]m\V
	7%2c1f2nCc)VJ:CQgYA[0c=k(j\`1+>?OktQEdR6oCN-s]!gLV,Cm"G1ur_$7>%hJdJ]40(h:mo6c7
	$M*n+.Q5n0\uf.Y7.4;SB1a2+94u$5ucm$b)0bS/8Ik)@?_M\RKloq4QGQIKAL2]9HiQ7K.mg6a2'l
	/C!i5/#]!K;fp6oFkkMtV84UQ-KUKc='8ODa'@`_[irl1d3tN$%.^7r$l?/O%UGXnJo*llkM>mT6"5
	k`VF+:Q;h5D^'a9r&$"J!fUfLbR/Ck/upX=MZ#0^**l?(o?GHdC+1[g-hd?#@^8o87_j%tLACH'^$(
	gD0Q8UZeJ7MZEE/)`l_&,_4OC&Hc?babo<dCVso2VKcV8XArI0:K*1>OJKaq"/+h-QYXap!aF,Rp0g
	rPFTQa`71)$sJ?RK7p8>^JUSf^N^@B:O,Hm%kP[VJ)97m[2g\[s=Oe;#@n@*Mk7%K!Db5g#Cn)gXKK
	'2ru0FEBbH1E:]it-lkSg"H]&ARlL;0MF1?AZ6ApXO(HiMk4+dp<`"NAft9J70Km2<M^W0Fq&O_)t8
	&dtU!K..\Pn*Jf!&NeSP[1Q3>%>/cL8e<-uq"Jl2^&/%i4YiA,TFIEN25Yd>q*Lu0l/3+'Nd__LY`>
	01;K^+EHrIJ=L4eOAekD1Z9XK<B:ilJud/;%W86Dad0Uued[J<^ZsG-*A38'Zk>ZN,ZBW]l=ioNJ1u
	"_\cAN$rk'F*@I.5JQBpp%<U.W8cgt%]EsiC$LB\$kSa!hUtt1.KE3*cG=oCh5^#Z!s&+"*J#V;C2.
	MT""HZcY@JsAjn)SASV8Fhg+jQ.kQJ*sCe4b%%V[kA39k7L33iY5?9WRQ[&pOr7$KFWRP#e-J?Oq9X
	s<L`RS0BVdagNoR0V2kH#Q!lK@E1@%oTtm%h__h0FuToYQJ>-@)n+VYi>k/*:,XNBu(:47$J&F30>8
	QBYp^m!DoBS?IJB]$ihuSmFb.D_V/qC]Deo#Sm;8uLK(qJ<YJgQR.KscMj;Neh?M3m/BeKeRn(C9RN
	oeHqY^;q2A"XLW6^`B3eUs*?sH^D!4]1=QhUOX6,OST;UqQI#XqPkf4jsoGD8V_U&&Nm!^JA))t&11
	_l>^9*$D%.(GsA?es-nsDI+p,+s3Vg+R0Z\7`P^$9J;*cqK\]5Ke(L\?_"YLk4]j)!j9>@<P\&'Tn/
	rbn*u5_3uC8_<V6$lX[&n%G8\+j*EUs`#DIFW4dZKK_`UI1!V7G1"7mWIV$cf:*=4e=AeB3V2ul$8:
	e/?^'9kEA5Y+9l^lB)md:jqdMJ"+W[XVoW[o3OI.8X=FcIu3_6uqg2T;'*5jFkF]+a(@=+9`s\CKtM
	-kJc_e&u3+!>DfTdln&5:psJ6/pRKn)+8:'G4dD0#gJ:A!GCfGZ(D'OH..P!KU-o.?dT9W<C21>(%D
	\I135u?JMK8b[Od`;+d_ed="\.iT5MM(R[E?O8pE1J^@GcVr?CcEEr3ko'`*f*b-$PYe-le`+/u!eY
	;A)imW/+K-)EeL\6,'PE#1-FYME]>[WT+9U@#)N[8<h)\#:U[\#DjiDQj;m>fRY`GYiEZNfPuL(#^2
	`2FCE2r,"`#^S4J^d0k%FuW=s6ZpTc^Q]=Ut^!AHb^5AkAUoT's3/p.<#W.n>u7dCaHa&2;A;4MQU0
	*6=Ci)l%nkPjS2SsM+BI.Qs)7.&UbpEF>WUaj':@iDH!?%Dbm+B1l4"C9GY>AJh*YI5onZs")MiU^]
	YWoj@&["ep0/?4;KmV04h'oa\j5NbuIcD"XrqHK*"Wr0E0-.;>&D74]o10"4er5FZGGEY%BnMFbsF?
	A4LgB4DDopDZ[WUCIW37))KrV`UOaC!D%'4hd<_%)*COElr9N-UMj%.bSRV#p62*?@3QAf5c^fFL&=
	:e/<]'9j!n3'fs3_N#;od4$E$%`eHA,J*_Xau\?Xd20ThT&NKf%^Gn#L0AjU/@LFLs&Z[JHD,;nGK(
	H&/d$(#!r;4fFo*kegL2B0dA#\'\4-H4=&^_nQ7]_k92g*@(i\Z5rN.$NX0mEji&ud1#P8(iLDr#4Y
	/O[Jhg`hX'UG*pkqd[#,S8U7jLWDC_<*"nE5:#;+kI0VCd=)4B:Ir4D(,+Jl4j\FD1H0K7J+DPk(fF
	VY""#^&=X?;T")ef!2S2(A)$iK[o=Gbc"!Nr^maD'"i7_2>>K8?KN6NH@KYUMl3*(3WTsa3Z$7tN(i
	F)e?WF\<*mnYA.pAaai#2.(0pPWa*%J<%02HImfNh;h'JZVo(=rVrg@GAg)K;]7(2^-:ClQhh**^nZ
	FFW>-U(XiGn@G5u;jZR"MVLP=7=O#J&]`OS-T5?Xi#.?)B:Bq-2UmFj<Enql=sMHX=^^`Xq-a8WnN`
	`IYW8E`)p]SpT!+.f=!6Y(gOMhjB$Hd-HDKNm<Q*su,Ygni40D5D,(Ju,G12NdL.s#QM(<$o-?G1l(
	SGg=rKD7HO^O<Zc$;b\3Nf,#PE<J]Ynh'V7cLS+k!1=kYG"5SZdTt06@,731?GbiiL4A^YW6,!!\P[
	g,_BKW/Lr,LnXp1!+Xa/<CJ6SIeWgQEWaBr"Z?3e+9#[<X8;!C5'T-R1gi[Z='/nM;34[&XJ<@@HBF
	YkrE1=^%c[>]SogkgT==R!H1,V!uS+<u?an7ba,[a!j=:qSW.fnt7-9Th3$)#u%5^e*BqO1ts/W7)N
	NIFjNR@R8(S%FG$<2f<'C)p/A4Fu#E"EHFSS%bi8c,X-oiDcpFIUP4+CE4d(iJ,%!"?dS8E4c0M4E]
	Rb="VpY"X?d+;6M_$Xf8HTO-LM;&JNY+^,?b*=Qf0jO]8/ddIb)K=FH;@+YVatijf]OYS@i'KG2j'_
	Iu:b&ZYZa=c_1Ap[aH/a#r!o0FooL*\6Bh"#1<u#Nik?@ifI&4P3OBo3hH)*]skn_+oh--TVBRS05s
	`lo7;q^lB'rPR?b:OZo=F_Iu:X$l#P+Y2^?-LPPa3<cu)=VouYi2gVVnE%QUq9Ga"0Wod;sC`cbrbN
	^e#mgQ/<"]1QN\dgWC`r'em`dS2d[C[3T!:r((*=7GW!CGglp+uca9jO#S2gXbPi6G/HO>tMlf'XBK
	$&f-T#'k06)qAiWls#1c=O4C,C(Y7lMGmY"12lj#oAR1'm>KiE/Lao9,'qco?2,tcF^YdeA!HXC?lW
	AuO=$6#@aDg$RKs,"M0L3J,-(0f^gB#`19GQrA+Z8haRH^!Il8]qTrL6j5Yl/8`rM]bIV;(=T=o/Ip
	uj*@cD1i,Wp*mjBRc5%%BeJt#)TV&>aU'd[\'RAK5/b1;kTkVB5P=ZWV6PM9rrW8CB?$`<HWXAE;RM
	5N:fA<[:!V6Yrl'9%/p$P'K!dt:Nd2e(r\N#-:We^ImA$X-6jq3C&t;WN;Kk`pPf2R?2oaC*e)j8`'
	7M7@-.K6B+<_N`CUn0h;?nn3Z,1RpA[aWRIc.mJaa62+lQ"e;'8TQ"SN<\M!'Is+D_bfC65KfoATNL
	2nsjDO2Klno>@^cVZ9mO<iZc?`G?`9+ANE*'Ns%7Hc&3,2BBHf$$S!NM^9!K^_d*b-:"#-S7VlV)_.
	rTj_6u$*7*\[^fafcs4!,'++,+KN<Ul5]D#1g%>0j("`Z?H'clXsG#Lh\;3NZ-buS[d"IiY+ejeHMj
	o&dEqM3JNo#_2M=!-c&It24^%&b]BWsLf.Fj*F]hFOn4'I(3kPZd&-*O*5O8q:aoJ[HEjhX/p1a#dn
	a_Y4,'pVF\lO(7-nM(YB/T\o,OGUo2o#6BX<diYe;s1>510U55"UK&&VMGReSj9.8Wb"rPg88I&?:h
	QFKkTq:meEGc8=TTj"FI+tmfm8M*B_(!upYb+VN+:b)FDkKXi^#RB^N`X0Y8O*YeCbG<(u`7?Yss%s
	"q%%^(D%2+#)Ht-=*F\jHBZhU@H6L?pVtIip1"d+<^&V<WL^"*(`C"tC9VJPj1p2-':KU[N3OT?<X4
	I9]`E4Rkh_r&"677mg&bL<<[otiG^K@?8T2]Po:DudCQj-`pf=Z,_MN+:PZ\G*'I/%6.<\#Z(ntL:_
	U0D)8mis<OA`$:=[fHKe6!6NNOU&hDi1X+r5!1+$TOgpceS6cc,][j9t:5g1'F-=@%9:DH;-lUTFUZ
	Z8$"4,-\+;eP7L`0T>0FV!sZXqRm/.aT]Y;^h=]HO%:3^J8#Ve1(c>..!5"sKdI79hq8kfq9fmEBT\
	0`fg8kB#&NqQI/Vgb4TVa4Z.56X@Kuo+C)&>qU9MAE0G_s?c(M:@m.JKSDF/Q+I7Q6]&I,-T&rc4q3
	R+RTAE,o7WLAAEFUSr@,r"THd\RK80e@]Yc&7%!cUaE,iX'h`C0u*n&,Cfi8&Q6YK\VaSNU,!nK46,
	I/pCFS1bFc?4a\"d?;J*jnF:i(*lk#NhR0T,b;e'/U1h2JJk!A,qk!A.Gr@ng0M0[JJj2=&N=c".H3
	Xg2%hun-o1No:]/AmJ]7$J&F30?Cq@_ue@eC+Q&gGPrhK'[Qe'm]#N25>(M\bofU//$bQ(lqG_1BIO
	^<pj]RqgVFi$Z0S7TShNNV^[H1^hr6qJ]hHoMli7Q+H'%Q<;OYeHgQL'f#$>#KglfPd7sdsA#'&W:g
	*brL`LHT$-]q\FVK?Id+ndoXU@BkVEc"%,G@.>SuknQjn2X.J)>Umr22b^0XK"S0\E%i/f+2t8<L;T
	[AZ!^G^BZ9*KcEgj?g7V+fe7^\UWKmWmbVSS/c%V'k6"@J=NBla?bT*!1]^V-PRh/=*aGC#\oi(61s
	7/!M!^E,9bbW.Y3mUCX3C3hQ+=U;2lu##":P&0tXoppRiUS`d)^Bm"N4C?Sq,gQ_NZTaZ`Hi1H,+0!
	c)T/5GL6ir'^W=;N$_=3,&6ociDcgJMR=sBn75Ag=P/2o>8:)*r>Pu3R^1s>!<Y`L5Q/AM>GU`5IA0
	/i.-aX`c4b-B>8AY\ONDj7I%#<m2I/N_?/d`:]s4<0m<!KWCuZ-j,n&46]R`@cNJt(q?$^bXYJSgH-
	J%'Od9"XFp*H6])`m,5aZN`</<X:eKTf`J>+*VD6hf<!F>n_n0Hlm.\?N)giLe6ljh[#DI2+8?&_S^
	m,\cr",e3-2$a/AWG8[!Dj1;Y&rLZ1>ml=W+)pC1F4WTpgU^njrq@h5[CBJBm!&nC+JPX]g0T<:]RL
	q#7p;W=GB+4JeOp(E;oh%?$2eq]*=kBJG0\?N+*1itYm\cP^`ND8HWVIoT%#cp;%^G:XJF:8+>+FJ-
	?YpY<(&6'9gq(;)[58qHB*\"!C>Dqa')]L-E'1R5eAOc$=H(/_,en$l]%BSIQQuSY<;LU2h+u\esc<
	`2ZNWV0t!YF@eN,53)_F*@./HFme9VQ!"]@]7=dXQNe1_&J-L_/eu$5ej6'-_*V0A_bNVmu?<[Ufa$
	uhT_W!GjCh%:OMO^R[-NiRPPj;9L"j53_B*<a)C:.7(/U(%_LC*Q!4oOa7:TdL%QG]\(]$tHNoYP=%
	>J*`41)eN%W]C90-Y[:10<Ys&6icTY?jIJ0=o_$&Xlm5JO.1@L1V$/!I_T^Q,;j>?91#=.4k9R_g1i
	??YE1eIh><cfJrj.M!O`QZ4:P]e!9*$(RF4I8RL4aDK$hu-K>.Kt.r^r.r[F8(`m),57,oV!!pH$rh
	C)AQ#;j)sB],Q(/$J&q63Y%'3>kXq-m5fgJ<_#]IP>40Uc6<>^\7-h]*>H`.2kA9qe!^t!Dmn2<NP2
	>r<JNV0:<aF<SoLAEV%oSJ=ZknP6#cVm/LnW;nI4,U8n?J!.5P32ctu&?SQKA0?-JZ4O:VPZVt?bli
	\QWK3=7\OEiP9Gu0RB4D:,fR0T,bR0WK:`]TV&k!B$7#FPh')*:T8*:,Z$NYBHj*@D?8NYC)s*@D>X
	*@G$pj$ZO'lo<D,fQ#n)fQ#mNSRV*1/$,"4+ud93s.iUK#*9pS[.2Z#L@fo]B*((j<DUh\>q*)9JTL
	]9>6a^8_76oo64-QXjeT>d6^<.<@1S@`S\QD$:k6V;(=#:jQ<iS]S@r<oVe.4h7pgs;@/u6]IC4hKE
	;Rtm='!(#=V[P60LAtrd'\E3+C.rd0q`.^NH7\+=c;`Os55I^\)h9m[B#2WLE[6oDj:F.=6cA]`"ac
	K5H]f;Y6TSAZQJQId+I.]\IQuX8#US=J/:FTGhXiX"\#1ud&ufS]]t4j($9l`E'_!.nc:`k^o>oEo#
	e!,5<iiDiWiN1^ZE.=39C5GhS#_`ZMMJB5]J#:7RAuc!V;,IIKk[n4ijPEB0CWljX3_$L1OG3%Io/R
	/JiAS0XA>eaY%M^ra2s5V_.:[b4WP#XoS1ohgKuipRSjSGlZR2W_0JYP$DplH`7:r!@/1@^V0Xq;?t
	1EJt\W6K8#1E(b/elPTK70I_RPNW<OmIK]tcY(QEUWIN''cT_2<_Nl6KXYQ?ba.t\)QR",(7"Z*V8H
	&TFk7i1;H<pQ)(m'Qg_!@Z@(c^$#1lDMSA)!cJ1%@FQu@E2"l4dOW0UA%&eH-)N(P1dmC^d""8^1,_
	%C"sC?RoEf3lQnL<V?,&#Ml2du`q:[W2\(pX!89JR7A/ifJdHt!/J70oEUtO7oDIuO][<$t7AE`O>4
	JW=2HoQ-5gMa>!*`[g#r"u&;%T8ulb;8d1&Oc42ZVs[Ab3+oC@(4W(AIr!8#!+%\m(cQ,lfPqkSOIU
	^APgh5BpVf'?>2l.N4;82bV_meb$t)f;mhOolP]iMN28RR48C@g(/e]1c@7Q]]-c.(HsY@WNC"tQF/
	a^clrHY/[%SJ]hn+j1+QtoT_cU;;p#b_^BU>4/JD8jrJjjQ-4k,3po.iar5jRrCSt:R,m"JY:tTMW8
	^T/j3"%;O==-@GF^FU,f>c./oYbf,T7!cK4[a:9X2D?ID(BjRci:`SVq6&!2)S1<`dAZ(_[dU6oQ;i
	>'#g,:FEg*.P[$+r`dak$AKtqOk.qOYH'!;*m<MMJo>6:SDda\L4QaICk@YiP%J-5'b_,mK%l+Y:)=
	nuI(-<(N*:,Z$NYCb=OW*RO\@ZX%SCiT;-eNEJ+*O/F&j&k`J"5/2U@[U`'1RQ@:t,a!Hp^@b:]YNA
	ZYQ_in]L9:1-8eE0E`E*"bd1h*MC.VMY$F`2ijpMdJj=&'F"R\(pYLeO$s,6!1\H+QPE[7_0tX-2K&
	a!)_g"mNqX8P"peH$jrW#bp7*`SkMG09!%W=ME;#G,SgNlZi`riqN'6ONVMK%hCL;a^eKPo0OV+gD!
	Eq+o*kZX#.P;FfP6TgVB_pG.[m$!L@AB_Q$#V\>=&C%U3<WAO?3Yq/hcNieRUY/Ui-IYLZri9Eb/[8
	qq#gQ-&?*a%fo)bT@V;X)^(<HoC)8'l#M%u[k4`WX3d&@q5[UI=:/rnI%N2'`!";h?5>UW[jg-'.?=
	hNMB92`R_VW``.b//*RgRpN7IfftMmb)<E/CSHn)&KTb]V=s9=A$MLT7Q80*AiaV3[DtHeBCFdPR^g
	>@0t^&1T)N4XV>l0L-JVG5K289=kG"pEQ]<Y?C2iihN.$h<G.h<>br>!u>\-R!o/<jg,atp8n5n5VF
	,3CNC?.V$V/(<`CW@gm1$s#L-R7\=m*@UFP:)l#PkJKN9$:Io+)k(%G\>>Qb^>dI#:T2$CnO(:KhR;
	c4Zbm#fHSokdku@E#GcU73C*qVFMH$T4O*MDFUcn-C:$!CQ@KcVAh_n`Uq[1H%9POC)2jksWbm5(GF
	3P&n.L(B>#_>,_7f68o0,7n$1,l3./kS*3`S_)T7()aAPhXQO1[r_bMZ9jKM3pj-c$FeWn8<!T2K<S
	JcBd#Ck<LEN<V?NA&)dX[7M7"E"7Qhs'(oo*+"h+?nCpAm6LJV#,<6a0!Y?;t<t-pfCE%)<$3Wu(Vj
	U%k_)%NdoJde)_jGk*f8e@!?[*h$()L:d.@Wqll6m/\=XE\&lC#B6@"0;>d9"@H8GGJh0[F8+#8EZt
	<*58spUA?<6[!3US9lL(g$rs%D>B`34bs*h`\^Zge"nLiOQ3O<cFc-@sf<+c4k8c0)u1lL?<"Y([1"
	c+SN8M.!N*V-ePB)q^KW/ac6/&sk6l1^2qF8t]h`t)oJUZ_D757Gd%!&.j<UjcA;5#iU.6%3%q3u'G
	G*MU>TJuXfDk6q4K#P2>h@NO<WH*D_f@*nf`b_(?u%l+YN%q];m[*40HK6o<`1(R7qfR^8Z@)iRsS6
	uT=A&]"3#@b`1(@4#sNY?bTA&jG%YiCCdlo<C<4&0mTYYbt4G$JOg*lD:Ufd%)cF5Gbm6C/A.GQ%uM
	=.nXV?:Ubeq:5)CTDUI=;&NJ?G.D8U+s?l6OY`g2CC<qcKN8(n8?NLY:O!/Y]P!n84E&l4b4l51-S[
	;\&?qiO!</D'P4t8D5't\fSk]-oAY@re'[8?,Bhp1ipE0"1C>/][qL3;'+=H,#<Q1X^5d\1toMOg>j
	g,`S<^(cO97DfR&kiuD<;OMiS`"5sY77)n?\NC!p21&2U:&O"%b*%]5H_P8g/6aT:]0>gV9Q=^4_92
	&J0S*j!rOYV^#S-udm(dE5Np,lbZad1<W#b"mnV)T,bVq$=DqXJlL+K6U=#mm3_3?oI4TuM`e>3'dS
	Xc9s89J*;sE_]AbW[@pL6er^i65)(qd3L-([\ukHg[J<EXV:pTje=[oW0o[;[?o#0`-S_+,VR"-/R]
	Ic"r5e0Vr%ia/XnQ00W=1B`Uo/=<uZ[=*Br?'6_tp/Qg=<<X"3X?5UXDUkoq(>Z)n^Ot%D"EFKim^:
	nO:B>^ss)':gB.k.iWk0)t]-f!HG$,e"_/BB5I/Bph?Tm>!cJTQnKO&68&lgaPOGi7JJ)ALpV7LY..
	[D](908#oWY3dV9k/Rc8rA#gMj_=NjpkX9XgtKtJbgVE3m\R*Pf38\1huSR._fY&qlg?`!$(7"^X7j
	bA+Z^NMkfGWpu1qhLT_f^2LEaP>(5s9/HZPD=iK5^DVjGgITMi'\n#PpF*$q`W;ZpT:@M'\hGhR$V]
	bJYceQ$KTPA:bCnS#Bh_7iK\dGU,<aWlI#_)U9Zq#<7W<IfW3UcgNh1YZaZp):7s)FNfaIGe^r-Oc9
	F^WsV0.a\C?unI#9=.sJ3cn/jV`MD&r'QZ`T=aKIUd>Lj1qDI."*9%#%$DZZo\J,@p9*#QpHQbr+<S
	t6foWfc_#G[l5G4qL4O46e7IB:b;hMNXH&dc2`Qs"LJ9_8fGSYesTh2)?mZ)2fE\#Y[$7l5nQ-Ce'3
	1Lq6m+40ZqT8_\;-#6ME#L[uSml*BAKg);?.D@T!mk/Ff=R&+rJH@WhtG92qc42)a;CPA\XKYN2m.D
	pVX>5irrm@VC*J7c!^iZ%p#QRZ]_0/6a1%l(W0A4EK3=%Vn5.>]b_+,lH`CQs"IKE)FhHm'_9%Sp/.
	_`0p<GbDWp3pjn%8:]1Q="UMD0Q$>AQ%U.`UQ+WraXDAOp855n0b`eX5,K%l\g07\pCuM1VZt"Cm94
	Bgu!Z'k7=bA`u`*g<>tQF7sp0J".CDEm!)lPQCOU4?O/#S@-sPF69"+f=Sc_qu(bVIbkoo(]$E?oRi
	hZ$l)GZET44L@7?\O[3gGJE<:n5E<6.IKZENIEDggI`AJfY+s]pZD6r]G+`X6E$AfF!'bVm!'G;c[i
	^Bn8il$CHi%2$-#?hfJ5G"2U-$'oY4:/%2k@-Y:VkgukUXnTAcDSAeOa=rX(YNO4Km7@mf1<UZX'`'
	&Em7psYp=L$P/aX/i-M_J-_a2i/QIj/Z]"ZT\G'`@/^>CWU`aN-d27$TqS/Ao1^jiq^q*m3?C<(Q#q
	4gX>sL&75Nt,pro78H(bI.L6a2neo:8;j[E?hMq+Y!R)S(KQJ5@QE-/"^q.#gZBh`1Lkn]F!f<#6Ou
	ggLA;fhl7^q.T&\pQ4@5[sI>,a6E+U!4#V%kR#oapY!se^CZ;,5,@(Oi]Wi/*hTLEi1P]nC^0AJ_H`
	6GM&boP/o>0=4H6KFn2qUs>BFm@P.8O6(V9:aG:f4@J4&68!)=D_"HN'&r'4J3+hGR36CO6gOM;afi
	VKH-?!CF$llj_uZ+SlmAZrkYFcq9Ecu;it!EB-P8mi$W?"d2O-`>%5_B4N\"`Dk)@PQ>E_Yk;IeipA
	m31*Qi5i$V/(V1#\1#ol?Z@>s"\>2/Wmmi'1P.:sC#4Ojj]5Kh7bm9JK8gI/3!$`WM2<W6g?8d6,79
	4:,O]o^5^$j2OYa?r3H$u/J*EPr8r4/WWB5EqBL9)Rr>4Bl5XN&(B!-n@o\][-gY9W^CaWQ"dd\K2'
	%*uIM'8siRL3WVh&q5_8_8-H[ZXGk)d=h=Ve.3#j^lm?5jR4J?Is]S]LIZ^PQRKM#H5X)tF%HGq_-H
	R3JAJQ^'b-UTjbP1FIn$m)@-W0oj8n9KP4;`q*u5$1hd-9?W]Xe*"!DYSV9fZC)]O1VLqjtm&[@]4N
	I21c9`X(Hn//s5)jhR01S3N1+;YVlJaE.-F>BTYps8cR!c?/ARQW,r_XWZ2hp,kcm9Wfc,JicZ5k=k
	9<3415nt9\AN_B/9$Xf^(H.iAZEI-cA7H<S2m"t31C40UQ`knDWrC,]pR@XBY+94u$5uckd>'ecprh
	UZT%C31.W[[kJ;_e"b_olYP49gnrVBs@Y9HHhXWrF>Y?U_$FS19W3?Z/2E,C(*XpiE(.Is`].d..!V
	Z9s?"h[9>?Ti1(Z6U+\V_pAp+loXiloj/%)?k.m>Yb=BJLo,W?9]u^#/+eIf*t6[>Fb@L%#N$%B2'>
	Z,!9mK?\MkU2nc>fn1b4XLlcV2WZ\$,;*!X=f0g0MCe/`<ce0@]oDFj/@`/4FSfnQ9oRlL:EbJXJqI
	LP.>A2u25EYG5R!WInnA3dms`b03AEC0B.IE0YP&p.SqNLHDNNTgKu0QA:GX)F,>?+.YF5`.N5acEq
	F#^:A2;e$J:b4=9?8n2Su7WLG=hiMFqKJ1I:.l=nr`%qC/dTf[?S@HG6IC*PErKeZCC[kPd>2mIr,^
	UJ`1RiAd[(bg]'DM4b\a9I:@`B<l#dfOM6.3<4Sqs-S.H3b%Q+&!kLBcX(PL"N338rWQJK[cb:BDAb
	i.jbeX$1Nt=nf=-il&N2]H-#-85"l?PBIdqKd:+]r!@lYCA/1c1p&'!aSoPpR*d4b\^&_k)f+-Kb:)
	S1+\iH70k+Obg7Jc+M',SaQG]FB<YOVEJ3P5s/'(-ZRd@rBWfB@>^n<,$"pUJ3:eR>BZt]`cHN=RBg
	;BXY&6MZc<<@(`Fhc7O^T8_VQt?mWW8n$\IOa9gXEt#e`rtQ,r"6oi!#>XgQD&FAET4H[mMZ#3+EOQ
	dYMD;<W21M8hsJVeXf*`NSO#$;f+4bT`/0=<m^T:-M:0Wn:;Hm:5U-;P6'aYR=5q/p;hn_BO<,&hM8
	2,jX/]Jpi@P=2"+$-W@Xr#-HrkaU`&4iH@aNW`%pjG*Lc#"lbp-!Ej^FURT7H]1i5;:3,M*MTUmn<'
	Vu>)^8Ol1&;6R3+M<alpCn0c^]1)_$J+o4n<]hC%1UFh+]a,TX<4&DNb'Oo#YIMu;'T8Bl?-1EE\.!
	%MAV/QKL#88'7;k#sbUTn.n2J-s@E;m`-_e&Va8VHLO&<6Anr*GsXQAijJK"Ye:3n^RC[?Xa=`@j9V
	i4bU11B<4'#nQt69s^;pm2N$IcfJ0ArUN1\_BNoRe@m#3<%L4m+IEJBQ,1][q\ORN^RGb`b_;Xa%jt
	<_rsN9RJaUG!BGJ,-Et;30DO4UG@').<R=iS,5HS$]I*\aOep`f&8iuNh0jD`n:%N(ldYe:ZT=Oih'
	2&eDHBYfI2@XINGNgp_H;ci:"q,tX,\2^rQ0`Uh$ihb]$2*qrBE7g&4lXO04NB/c"XRj6kWnQ#HjlJ
	IWGUE')bDrO+UI$-Ee#"fqa+EUYib9I+_hfBo:b?,8)l"3WnB\[D=WJ<pM1:n0[D57:;C:KX%t`--e
	k-/&j:d/l1D^rK#X[@jS?3=6l$??2m9r^BDn:a3:Sl1p>&;GPf7NR4H*qX"^$P(>?e/Hk@7a+VIPHV
	pW1)hD9WZPY%8O9j64<o)'V=7=rf"\%Xb9fSMId[t9X4>p)FI6%Q.WY3n%*NiUl7qKoB#oRFsT*>(5
	mp/[e+T3o*I7`P0bs606`pr7o`":WW'`/)"WG^LZ9VUDN95<O[WaA52]W/O'YMHjU8B!P([MeC&Us5
	t[a7LZ'\cUR1USGK;.]_CcGGou.ZIW0+&Oc@Dr%IiQ%Q&.*Z"F2)h,/7:UrJ*1XSt6kpd)nZ'L<l,A
	.74aUpl$D?fT81t\ig>]:II:?T(Nl7HOsL?&O'd>ig6:Nrk9]uUSS>j]rL`o-c5))g)sYLHV\8HMj3
	8f!$6<s?pdrl"OJathp<nVCAqEdS<o^uQaU]ZDMiTK3-a#1Z^(#m.V8U"MS`sBc78JHG:oDi0^&BX`
	g?r!aPa%!`'lIf;NI]GidL-^3V,`.6TZQ.FHJ(";GrKmF[&dFP.FDt!-emu^Hh6N^jZ?i/SS"63)Iu
	tE36VmoFc,j`A=ZAF)fc=J#J"!ck!Q[Kmp8269c=`_9`_DlR2=WWF%"EKCrjtqEZ7rK)e5&)#D(q%u
	(FgO>tW;Fgr)4RN.+hM%`B#E?[mnnW5_m?6O;4,Yg<L,Yj!q_TXT!!b%*16K1C(S2b1C+tAOhhc$?o
	R4GCA,4To2nV<%9D-mA;7C;d(=r'\C?P'=f<%8QS=UX2@V4LmPGGNQY!#oRJq\3@g_8<L'9nR2PW]'
	q%)+:K)5(L?ph#+s:=\PDEC3Eoi@Elcs]#c+WQ3=T@C@JH+5gSr/3Eid%3B3VnQJpcND_%Xjk+j"90
	8#c?i<5M@[JF:kSC)&WJ^,/k4"hJ.?3oRe<berplXPL]/&oKolPtM/!3fr/fG_UhJlJ%^(29H>jOLD
	5AW@cm4eG^k$"9W&HN4'=DZVk`[G0+h34Nn@1WJg>7*P;WN7#5UC4KrJhQ-@29"P](/+P;XVi!50N`
	%Y8K`*7B4ptCmV0T%F7Q7N_GAPjFSR?cpB%Q+./@lB0<%im3$G^/ISYSSY>rMAeafD=GpMefMl[HHl
	g6fMDI/drC[f\%"rI#q+q0nc,njYZPif(2ec%'g<#6@.E.I#aaa^)fjB#uWq1HH]5pAqGBg7cJE,:m
	Mk=e/L0IfsM(OZRndi8Asb*)KSO(dQ\AErs9%9I+ZU_FY+k*g!>(dKQIE^EE&`>"q?Ommn1m-^jIra
	]44I_"%LtJC!>EE(::@*mr97LJR,\hZ]K]<=)>9iVjr-f#hi@mtn]0ikCBSAudhSd_Js9ichL#$HS]
	%jf6hkMtfdfl-48UkgAuCc-`=(d\Sjj4=*M0#*RUFiZ8B?U3)%\[Z5]Hm/4h\dKBf+<&KnQ-9\`;7q
	'5061=\KL@!Y'U)5<5d?E>J)RUH^(7GNMID&1a$^<IS&7.83fXXW,Bs,9<!*`iUa4[B`]5?N&gqgi'
	g/qJLHO2LUZjN4T`Ot@\c$QA)Pj,et=p!V"d,)Z*50.q=g_P`k="W.RJ+B?(o7";br;7?H9mGmrc]3
	MMcA9^;'Rt`8CK4#S+l'@P6QIG+I^!rEoRfjPqEY@?IP@VF%q\l+#=C]mqSAC_58a5_+S::\(&GaCL
	V#n4`1^("S-Xrbof<M<',gZWM%fPg$],NW'G;c3.O7c^mX5EKKNT!%-UQh2_:B3<@+5lj$A-`]?Y^F
	6^Z7oOXTSF6faYe$!%!DH:+['/6J>rh5hk8-83A/\R%J$:'D2ekqG%US%\rpQ::W"Ek..bp7*l,t/H
	S?@7jk?PqWru?@r!$1$=Up\khdZ_Vl@g-bklA%FW4T^:/ou/!+[p?.HqNgq!>7qVe:K]PV2Ha9J=I=
	'@qck!F>!=[SDS"K`9o<U>u;W5DE-<A?L8c[5%U4WdAXYd!9S.8Rkg73Un<u_T9I'Nm:YP"p!SNkkU
	=COm'0>-F$>*'[PLJkK6b/q29$taD_01S<Y9:WIj'Noi"K3hJ]1Q]i%\p!-Cg:`kt[!7]9?6,N]bDC
	OZDa$!r2$0A!Am\g2%rZ'[7V&("k'1Xtk-"VPRNcY,CkahH_.AQ-W5[J'=[Rk.TAbS[gIW.#HA'6H+
	P6kgu2F[!k$r'1d&H&G(W5Y*nca4_SWoEmRRgI)IZ#W>aARs*B7BSWke.]/R6n:^k/m%@(Sb1<4B<Z
	8YflL9_5Z$1d<jLA<o+h61r,-c`;'d(7H"fZN0iV<Il&=bX7=3:1XHfh3_jNOuh`F@D%X[If$RAQ^#
	Se]Sm[-7Ga]pJJE`Fu&)lLG>Ri_(9R]iRj999Q%D00k#cqjD*dcWo':FBEZ@L%0\R6gdh^]0,CBq"0
	PeF&l'<J-$L8Ln)d8S4)YTJTF=@UJW5P]:R(CM8oA/B.#mKAF[1K:)a=W7aFXg4)XIr,k#^n.jY?cU
	0,Js5\Hps#!>]aM(8cg>.4p.H,[$[n:u$+4"fMo&SiF]\+u.Z91R<"(sAfX/o1+-#LPN[<Sn+%fKf8
	2X56?!KuKiS5<e8p0ltsCHTjVNEF'LlIKn.^,>^@f#qn5,/(?j`kQb=i69j+5T[431..i-@Kmk_h69
	c=`_9`^i'`,YZ$N4Ar#9,,aK:bVYKuML!NGbqtL;XD/<kiL*g.Rq9%NFC1ZOeLOOZ3@hNs2a)@NBGt
	^M#9?6G*tl`/-B0>Yp`=3'm,//H+'G::M;IX!:BLl'4EdELQ6C-;JYIqTC4RS;AB,#m^Ls-'H"Jn3i
	:KFi9,HF7iUA]mh`:@g)T.M%b1?#3/0r]P^j)[-R_diSC9<Y+II+^37ZlX3.<pn5)E"_:LqG#IsNtF
	,DrNm$2;Ng.EILH-AgL80'C*lDJ43$"M!^/Kmm1SN(&"L.r\YW^iSpC&h%nhCf;^,T&>_!<3Gd#ln*
	_c]*Ak:V_hcO4f[PJIk?a-NO$:5WRDFXFe:$Wk@-*#m$)11Fg(%E?[**hBnEK#AG9E30=V?S:Iu>^^
	j,/(aJ8]:l`HZi[.R4qX!_L_M&B(&gmrq4OB$jiWMDLI.?j6=oIchSNf4@i_P6)`!MMuCn<T]fh(dV
	hT)3*5Q@?6iXH"ZC4h.f1@I@fhOQVLkmke"30Es)Ce888NI,=bagkQ#U4CSB'QG<n[GjZoM.I7\)37
	iD>5Y40-Tq=o72+h`ka;bKB.Y#dJ&\f.k20Fn4an9Nq's5F!7h>l$i>_nc3d78i-lqHbT(U\j?G,&Y
	Y/%32NteSaAuUBbh.2$M+TMBm-c=GJ&FT^a:&4hM"e#g8t9jg%tIjCKY:a.C%XOC!q:I8GD"a3OM`1
	sR`'%Ws+Hn2!9t*!QT3CZ.bUpu8&TsUDc]#'no,*N-EQZ1.-^P"Q*pC$/]'!a`d)?`LdI6k%C$TD,=
	"e"-)phaBH/^O@@i1e#GGj$&c!^+(]Ua`!SBdjArNcKi+fj\8<1-aI9SI6TJijpl3]i?_<H<j="L@m
	<X,L$#I,2X(Ua&]0(;SD<mt))TH]FRa4HW]cRnB#E60$"-XTu>mcO\TT32S:10cO>j?jq<]Y=Uf)Z]
	GF@^gju*1@op5FDiF\6$`+4JR\.IjKX**.kp*<+Eo))-/u6@`Gq5)r7<OO/3t?=7<);)6a^[T4Ipb>
	Z+:bGLF0jTuZT7H6EPD!:!O+Be:g7n_@HWjQp,RKT[ACgKCI6'F7P9#iu&)aj2W-\N\&'6.sbE4".e
	B<0iD7hnFJ&oA=E$!mdpM^4nH\\9o>g]Oj:>YUh]>`asD\E>N&(cIG0en+Ze6R5=%Fl1O:Pr;ekqDZ
	G=WiU4Qn`b5+?kuXArmne7QP'R,-/E#<Qo0a>77m(R*/Ej\.XbB+u)n#ORD!&fK8;r4D&oqpMeI_Mf
	NO4*k8%X2u+tBPXg#iDD6$qk3-'Qf\"_qja.%'/-<I9#384VhoaZ=inH_5-V?BM`2J;oq0<pW9>lr!
	0AJBIt@*m20.+o#f'.fSWmT09oT?nMON6j9+<DNAeke,k.0`J&6$\\7Ik-\"+*S*MqYLEiWdo!\m$2
	%"4ek.MDk(f4aU:hLs(1UG(<DN<6TP[-EM47-k$MurW_Ui8^SPPgVX*dDGZ]Ok5eoZ.Ier`]>7,c3O
	"]6nbDL_:7ofn0`%XL6!S76TZajJmIrbkV!L%J6B1f)dHI[&poCihoME+)IJTrErf_IP@*T58a75/?
	8Aq9e+DAIW1oG5?L^T*t4sl&*?pV#PUtKoRihZCfLh!'<P1VEMA:Vie2qNi^?BDME(.BSQG7iM%_%P
	U.ukO,-sVq":u1n;@86o)&3c3NY!3C#=bIOU6_dY-&8h8XIX@uHVrjp"Q<5u)C$Z+(-DE:]Hq8gV,X
	+oj]QXk<W3")&FM")1/&HtZ<Xaei[95G/_^a8B^BJF/K`h7?%(Fii3R5R01Joc)Ph-K3X%O&LL73V1
	<K?(]bu>n2%5B*d]:Y30SjQ"*>NCPLNVX2H8WMb*c\(Y7M3.rL:70X-\,q30OWUop547Q+E.l3K'`X
	5prWHU9BV6Dr#,+-M%b!U,e`3e+3_l*4[_-WhEV@5^icCfAsm<,S$K",F&cQ!X0oED?V]fjOuX=iqe
	!i*K#nq\+RGTCrP<Z<7a%>)FX=<'*FS8:!0'3a<?S0?D8/)DArgMP-Wl\EN`iD.M:m1*TDu`u=$+*&
	U=k,Lka'6;P-GmWH,mS)p%*e7T-Tb>PtFS#Y.A8)F1!,d`mURA]"iKF-ep5j;!0%D]q6]*XtKM+i+^
	*4\R`je@@'Y*2Jg`'_oE:V2Z/o.:)Wc./70-64b2C.GX`%mm!7I/MXl4kIm<1['s>BhdKQJ=X[uhEk
	VBYr#Bu&1ONRp\Qgp7@OZV;upep'4gX=rnjCcRc-G4KO21_cp!3']l0`$l#AHXqkRs;AS)lkJ>:9h[
	DNg5"m@WjHcYQAcg(0U,Xd<DW(KiBpn=H:O.fb@.KGEN5N(rC^7?$ai869pQU.M\f%Cu%O!0u_8?\B
	Y/N%*`Vh?3ajElqYDUpoGCkHl9kHi"C--BeAO3\p3!tX5I*R.@m'#0R"n[GHn=YaL8FepMYXCnX2KI
	;G^nf*tc5tGhi3U?,-7PFK_ts];(+C^m0".*B8b%E5*joK+/%orEp+hIP@VF&+7n4nq2o\ANp?I&>:
	0SrF!O069ht]Tc\*Dck"]6(AbjCQU9\"lVpEFBJNCTS8_:qS4G(S:8Cr^S-Xrb+`S^&O>sLH+`S\O:
	,Gj>S-Z-fB"M'C(r\DYl>=6FC[+<Sdr(U]'JY*l>U*8M3Z&sE,btdCZ7l5OnBVmF)PM*;TC*SPj_cT
	?%Of*R&OLB=MB)#pfQ:$5pLYI`CNKg'L=7A_N8^-=dr*60A\g<;,qX9AEliKB6^g2%@^CtN`mSM4j\
	iRW*\Kdr?44f;lNFX1[HmaGgb&9".tBcN1tT$):iD9Y=o=Q4r+OSU3b93fkSi)>i9<eNs2Bl(gYZps
	'9C+SleENT&#APG7e0o(gd1s[pRRJ3-3J;CR&,(9h'['G#/@IBR]tOeYCurWGrr&]"@-.l8)H$WH]-
	`WWN"juTIN3V?/9sNT^"32+E9Q;h#NtfAlEkY5uI@")9H+JI)\FKLT.@u$P8UVn??EW[qi<:lG(`4i
	)?5p57u)P.$<%WL?KlV/Stmb0.(DrY*_5pocO64pH7TK%AOhd8t3B@mA=5)Rfip'3n^J\'<tl0s2\1
	4-_6FB.M%=rXTpE%f`8<j^XYqWkIJm3<Wc_`^e1Q;,E#1M%:&0J!=8gS!,M`,l_sJg5'=b*kFd*kG&
	Jcm`hWPc\0@Qd[64m)EZ1kPZ<i1ao,PF-Z#-_C*?%p*)D_!?h0br8`lj(7#E?K?f&[u)])L;q5?jP_
	B\Xj4!0B!hD.%0J^86<B+P/)1>78'`(Bp37E%Jqu;<7Mh&ip4tSPa#$%^;tHK_9`!_`@WH3)t/(JEj
	eL"5l+RID1t#^F"*t1ZRXW3@n%=@,c$')n0/Ug(W_=9m&\8jPHs70Ng2*b+6LV.j*]-eg16N(;ABG2
	0d7YjW_kKF>h)8f[*`apWCXK"$/WhCZe7ZB2=S\mu4IO!6Fj:h>X@KH&IFFR#4]F>bN6U[R*1qqSBN
	GrEs"R3^5#lJY=/Jo)53jrEueu69htUTcZCi$N4Ar#=C`.qW.$Y-X5Y50u*n*'e2YBkjq];[6.oS'0
	qF7@>+h&UY^Xg!"pY/Z4\OBZ4\NW`m7ftW'YB;l8mqC].KFl6fJ4hM%`m?L_G,5`//;c4R7e:$\?Ne
	dn9mEjDfr8?Ef3<3)Lhn#'dq?',Gj8+Epho3oWQ=lBlp@bfqqifGac^-jXh0e.O,U\e-<=0P`,;pj-
	dGI4)Q:-i-N(oa[d(N]hRSeI0dt=`ESaV+t$W_J^TKOQm8Y,@*P_#C/skI_eB_3KaZkVG>oD14EgUE
	?b,q9CQM6&1:f>H4=O?:kll?ogRjt@fd8jHu@'6[&YKJ9NZGXBW$aE#D>'Fbr(*-!9aoZ7!kX8i3,<
	$r]Ir2I!$"[KV.a(.KFJ*D[(2Jbl$7p8"=gA$(<1[VMGm'.sa+C3:U1-Q*3^u8uf!$EM=phFh'Yc`!
	HrVX)-+VIDgu_!'!u5hG@JPf&07cr8o7:P11fP?N+.U]kcSuf[C8gKZfgMSO%BmP=1d4qi<^F>#(S!
	oiGkbr^/$l7"Tm6_!\Op374U9r9[bHrFa-r?TWMtYSSlflI,?f7[uF^%ZGQs(L)W2LO2IX]KN^_^T1
	K0MC8"qJ:RrC-rpFR$/fY=mn^rJJ'@AiHY_`_r0msQI1[I,.:1J3ZN5BNje"C<CA7Stm[J%'FR7ZEq
	2#6(8DpGdY>P!(IG,/*D>"n7.2>k9Z?RW+nt]W7L[Bt,pnGGO862</i%jI'%"@6J0W\3\k8PPlc09f
	?Wt1k)17<fOp"N%t0$*efap`5bAR=-%TA2:dm06fI;W4geru.iVW7aU'PQ0s_kgp<]Ik6qSaJAO[q0
	#D^?U`#&N3W3ldKKnd0nZ#Z:!u;i_1b[DB,9RN)GGX_h#U#n.tIiE2=K^HaVnuWdD'C$6TXEKGMFV3
	gLKQS<r.;2PDu&3L3R7j4kHkB`oQE>L:4F!Nc>rC<a/-Z[VBE)XAT%[hbc(FJQK'BH'(hc?7WD%V[E
	8-6'lqs@'S95N4]a5Wn-p%N+%(2mlPA]g]`e>b#5b^T*[96B'NlVgIQ/bn,X!uRMX?Z:L<eb(,R7\&
	W=WP;QW.7Ookekrq)`.Erp2Z$@Y1t20nnk;r%,.7ABjV:Tm!Iosnf[3s^\aQGGA39e#:,[FWk:];hg
	#IgQ0gP_+_3((OUekZJU<]:6c$eD95(@P*Xt`F=eF@L"2?TKlNR=m"EnRH,6]g]IV2!5;+aQ=n6&oO
	Oh2$\qK6"8H1#T+-_gN-Kg2$PrLjkOF))#5m;OEK:;`0TfK`.KGb:U@BFg21@]20@?1ql8NkPp"r6d
	qh*4KV`G;2"2%Ttgp:>uXbCMX69c;dTcXD(5F>0=*t5#6l3E0,N=#PkkQb%]L41iKK=)'bhuQmB#=C
	]mqSCaZBTK+BNlo8q%rPN3j4a6&T/,t(.=!?P%38>;<Uc(;Vt')/'-5HBM%^HGD`U8QMYR13=#^a=X
	Q;(E*>mU.`/4@ePADB$`0u%)&LWHe7'?Dr4lSlL"/Cuq];%sDCFO8_,t#?q@>+[`_eudV$;q*co<T&
	W/-j#Mo.4:1:$,5X3p5d?&LV,!6#HpTXuQ(ZZYk.<9m+V4RF"pj2\8enil(+2_2&aN'5"rdEjm:8!$
	^%1JN+hB@]05!&LX)4RjG>M*OMTI`<8M2PQ\?#8J8?S6&?9GG5u_Vb&JU:6;I9BHGkXZ>c%j(`qkpl
	/*EWJEPa/U&Ce6#'dr=Thb0JAk?Fcr11DVU3(6l?PJqNl,&hon$.p6f]^`VBQ9;n"+h=sTV$fo/WX[
	(.6l]%_KH^oVlLtl<R^A?`De4<?pCSdA,ZeVW//GRY:;>dU$=so53>!Xs>mh]Ei^@E,iWN2u$)[m#9
	1R<"A3C6g6d\;DB@?SD8BqH0!tcn1Yr)f,U9SkRHkF5r<r,o&IY=SZQ2N?9B4`Da(jlPq8t;:#@cG>
	akp,$gj<Kp8[I*>Kr?$Eq;7dN^!g/"+8O"DHoBGf:hfPE!ME'S[#`gOr`"?usFNH*:rSA3RYA^u334
	/7)44:>#rWb)po5g#l,3ZBW*(2XqQ@a>^IbnG_Q1llb)X7+?L0I-d#>Mi$4+Md1rF\O!.D<B;CYsL?
	a0rK:+qC<Z\H/4BWej.CK@UN,F+[Wa)fsVofS*(-o_3"TYcVHkb]P,TKj3,@IhL!9&-DPd"N[elpit
	-tOp,/(CXh2qgslk=a[@]Y?.?4[.2F7$G!cEADX5dNjG."?#*"mTS@lpH>j-Wjq56s`BsS@VZujUWA
	BD>aHee?JnX0E_"jt>@gFeu-'IaRM#Z.2qUu(=arkpa#K%Wk/N$-4'!@V>;JMjt>Oo="+[!$Tfo'Js
	]G],(d_i$p'DJJg4\=h2`b@%8?L?9NqrludQ:)-aR)DsU^:!)6pZ]Q/#&AT4s5<i6bN*+;3LNbT1WW
	H<2D-D;`QmNaT,pQk&2Q>#c3n\Kr<'u^>>r2EDU^2lhe]tF[6?ebs<LX>B!X]QrD6=qfifhSB.i2JU
	pCk,-kqcuZb+ck^QQnc8]<P\X.Ofn0=%l^DS;c)W,M-,JhP7CUZ3&`V)JOWnWn^]5DqOtrcTaPiiVc
	dXK>\T-Ks'f+M^O+:;&h5?"SXn4&(PM'Q5JsQN,hCU$@+%/LKp*^l9p78>l1DGBeJ)+HR4,+EoOFc+
	*uf>RTaiI?d^8MHNd[SNeAN+pVajWAQ$BiX,O5"L9.AZ2=EDOh>]Ig*TSrCcmrg0@t;,c4*Ch.Ubq.
	`X4mE^P5Ur/EJ_;To%d]C)kdbK69j\8ck"]+kQ`mooRju%./b9=cjtk[YYLl6%/jSI0g\*LTG77=cj
	tk[Yk9Fj:,H/uE?Z'9!_=0SKZ&_/38pm!5e+;LO>p*!;Fho=M%^aA&gpp!&gm`/,YljY@n<*qVBb*9
	-qN=:qmS*?mibVAY%Re8+94u$5ucdLiRSo9i;BmAO#uKWhO@jbp^r%LMs*i,&6p^KE<EoD_7K6NC2;
	+]lqs;uKo613*I.[Y>EPcSF\n3JCJVUlj#)\WV3(P]3.FcW7:KKhL2Q:+m<r8gX&/p;"u-6f7Lp<s'
	tbEgbN/_Y^b%fRP-d82Kb=["RGIn?qmn*fG#3]^elPpt_%S+/kp%HpQZEBSfrU)4965!47g@(BUAa4
	ERi<@6&Y!(%o&P#QBQ=)T(bP8=[V9n#nl_`"8%'8LNU'qM6Do'Rq9]0\4LEl)j63<#-12WZ&BMn\qd
	'RY2F,c3[-`IiRA%)8G%%[er4U8V2Sh^:'t[>R1QV+:rHN,J/_&Y\&Hq)68IqqjiF^S_k#W?#OV7hu
	@B+%O@)]LREc)<9=20aNgY0MT+1VNBa<[aoe%MOeh)cN#09k6IK`T0SlgI.%$36Z9g8<4#\Sot5F:,
	1.k&eZTYd);/"oR(>V[++\i4:h)-U./H!-$.EpWG=jY`jAWd,>%jFYCma-cd.0=Ni<RX*`Re'k-f-E
	8;L+F",fCqC7"o[Vt?$0:OljdEdd;o5]f7W'F?Y(Jc.+"kFb.i4H@iTVsR6ZcGejPkZkEOd+SYJq3o
	f"<Ahn9MqUfPoR..!/PR(1`J<!<8RIrHiVubA%N.',KY+[2C.RPKKVn?MX\_96%khSC1?[lQ:tIEm\
	,mGAn65$8pR=2^@V2c^bQf)ikeg%l:'ED:B]btn6QKB^Jr\h[3$.[_-Ca=#M5IZWCG`oKRPWIK,GF#
	_*C&GIaE<doRihZXLf\KK.U'd#Mg*j_9`]NB=r<nrEuT&V3!YK<$?5_a?c>H(ADNeE_)]+M%`Vk$&%
	u_%#GWHKuAh030?WQEPbEnEPeR<O>rB"f7QD[kgEL,'rMQI*=Ama!Kh,3WX5ageFR@1"LL`GP#lnZ]
	F44SZofjB+?h(H4\8_WrqN"u^:WO?X(m%=9.B0'rl`!%roGuas$%(.*W!)BFqND%)9IC*2K)LHf&O?
	Zl3bnOqFMIiY[jD$qM^T)/C4qo(SHmf-1Q`.-U5-4W^)u0o^j1q`ruLuH:Ij+7a,qV=AUA\q4E37Ah
	f-lD="OLBu+.`8gM^iH;3PIi1*5(@SMjFh,Y;L"eKe+$HeQF$9B31)m$t=A+b"JCnu-_pr;%=,O-0@
	;V_<aYt-^Nb`NV>$W(?NP>1SCao?F4p'p(KKlSsf+LtMEb$<X-9H3InUO3muSZP2=;6u2AgTL]=Xl4
	pEpP>5Q3c&f=eDQh56;.'*(Bh4Sc,WbcmH]ufp5]jMA=Obg!MhSl*mn--(BY(O=]gVj))D9Ri@'4/)
	:6[7Z3(r:ns(A)b)bJsLb\o;\DBjZ!+.CM4Xru+VQ>YGQbY=;]2jCkC'L#0!+TRF"IiO]OfWLO"]a:
	scuG/M8]m\"qQuMd/t5&qjHb`HJc.?sXP)Wn-L`cOQ3XS,iVUa:<MU,88f*^]AT]d/kO4@`S.6QVg(
	j(q<"cr])VYYhU5OZ^:)[H"YJE(p2Dnf@<(4RFh/GU$g64f`+9%K!]FP/uZ=]r>iJOrr.eAgPTZUQ6
	%ZWk?R%_]FISc.ETcX^A?oE^f0UN?H+&!gG0*0cc;!8.j/+eJ==6KlF/+eJ^$N4?BKmp7_69k80eWO
	,@qUXBnLO(!n<@r3b*8knGCP;Yg)@.ts\/TnR%I:GDs2-e<5QBBb2a"=DEb"')J=em^"D!:bH"fEm]
	7UYB.'*O/3k%006o/tIL_Fg2)HTS%a<8h*V]`d&;+I/?Gk1g$%ZBIIIW=p&+Xh=s/L!rW<+SEUeIj5
	Js1$87/k*)@#+XTJI0;n"Z0TRM\L+QgfFCF2"B'(W'S&//%0eR!-[^-t"D)o>?k=^L*=]KkRp+giob
	iT"J6^^obpQ7ONZP-!&gp0'M"e#aa3DBmfs1,jHh+b'2kue+&!rq?C2#=+*"hLM5&gXa"V3@#-^_e-
	e0@`D?+I6(dUDa&\ZblNFRY)"#YLUHi%c&<@,-oZJS#H@g_0qonH4@VT,g-\j'g>/lHm8@NJ(]X$1*
	0$"G@Wsr)%XsKQAT"AeQO;p317&mde2<kDc"`m(M`9VBb6=-jgh>PdB(0.i0f0s5$q!G'f$pJ?Z$WI
	9")BB8L0[bO9:/A'qTfo=eE@pD+,R?p3=Jd\1X&RE*$J,&.I8cQ`7=`@(F9J6N=4=6Aje9Cc0Onqo)
	HDuCPjPf2Bcp<EU;g4j-Yj8S8@hi0FQ6RibK9;@h'5s4!]*dKPTV&.HGhM'mt8M&#)5bbb4nAAD[*u
	q4BnIODq9AkMdRP)6/bA^Cg0aOB:4tuH[Gk^F(cL'*%-S>D_^(;$F,nqdq$VG'p=5#bef0p'4^fY*9
	A=#%L#"=i<[!;P6CRUeWD1Qk\F]nK3cmQ550;f6?<';DT1U755U2A:^`!pC#hr3RTQ'">"P@CiEaOs
	fa`1hJ((q!U(f'<CYFX&GO9UYri/7u!M=TAO,@E_sEs87U:T80aBc-A+Q:Ol2pcq$q+@3_<]`%4G]?
	G:RLcDSZGZq=3rK;C3N<Uk">\'I&HkDVA#n;J.hk5t^<mqhRq3`dO\@$AK(SnE[l6Dd.=!?EQG\to!
	8>rliTO"R"fZLN"_8b28F_1jj$,3XCTJ2Y47_gL6NbHh)<4]o:ge184FGgB$\&-)3s;ht=YEb"&IQ5
	G;UVCb#aQeWLJirW3SgLZ&WB5Qtbm*/3ih[%`go(aX[cM=u\j#'=`)?@lno7Xtm'!Er0pLs'?^=6f?
	aVPOk;:)K8E3EMeA1I5(N>;<+$jus+_f_Xp%&D5\2H8lF6U)Fa_9<8b@#ta`5F=m5+)K^joRicRO[@
	"@XrmtX>+t5;'-plcq9aZX3`55+IV>An5$I^6Vqt^/cC$cfF?6JoSjEpY3q<>C\&,gFInl,RCJWJXO
	4PYO(I3"6UrfJ95b'MDUQCKq5s6440Dp%0/sc[CI]u"U,+/5aFC/*?#DkG!<or(m3"\D$J'%Cg>"5$
	d#YpoRgbRlB2=@i@HGkXEC6t!V"^^1NYTTTM"@>G8<ES(6'82[^Fm2YkJC4uVclD$J:NW'FJ3)].N8
	VV\8q#ViS1r#XS1qGa#XY&cbp#p00l]&^E<8FhCAFaBRgI;_^BUV]:-:IIhT'^inXDt$S^\<8nAL0>
	5u5!khVKp($/N";47Bgug;qU\'Pm6lY`#E?liM2uJ4l>*S3UKA`.=7(MR:>',#1ZGJ:PQEs"Gfq/=J
	PJ`\S:jcX*-=C2&t(:4X)l-P!A@$m[t9)D<^N<=ANq>DL:+LiD",)K/f7W;Sf.5&e7Sek"FZimF4[p
	343bmK@csaCUP5/qL.o]W4ZYIJg";/nLSJdU$jG)ZfS%duQan6ekE#&+h%V!32@_Bp'AfmKF^Ci(_#
	Bn_r39s/JX14^@JphbTMJ!!!/2(Uc&j['ZH8a%jrV>&t!`^BCgH+a\hRrh6@4-6a4`@+iZ45>20Fo;
	mr-\XnLj$EuV-c,ZEI+3?#;geI3efRi=Ynu_'ZqM\Y6=>FmYjd7an'0quK-UpCDKG:O?PCL723/64R
	.D4GK_S'U)nO?8m2^87M:4m.TmiTd=LanqupC)<JpqTpM6VGGlitV`nl/l.P5QE$gDSIL&.32A/W-S
	^L"jY2'.!C2H&>tE&$<Q9P73]ok_DN+EP)M%G=Q&.F>:)^N&0rL)-##>fl($.P.XAhnB_cTU*`EZG7
	fr?jH_E==Y-dEYfRDZA]5MAo_12$tj@e7QOTKA>ID4$\HiHBO-`A"(V!JR?Z5(J0;FhY&E@d5n+ZO#
	P<BY`EVADML7IA-I?+VAj,`*ARWOO%c?oTcrPJVGE@fq4g,dsL;RJ13`)k4V-URe$2h!_M^m*>o2*B
	$dAQ5kZJ$355p&:qTkK1Pa\HI"DS;Elu2iRNRX%U1U\CtSU,"&o?\<_r_AbGL9o+'T:^o$$;XPqEl>
	/gu_!2ra0H"'XFKnVm^KK;K.U7*>'O,4Z"_KTK!6NKm7Xbo?8Qh#irRcpB:*C0t.JlJZf?mYO@'$B1
	<A)_L^DpJ0B%nM')N,C;P'I[(jL!i'r9CAbW?ZILl5nAuX34$DnXCBkDgLJ8&%!15]Sc+shi(c(EW'
	E";Pl[9*?&>9lt+>1$Vbda[.9dY5/&]#X]rJ9Vi8&.+pRt"B,p?e?q8<G0<asX]2^nr0bh*,PH%]2Q
	W#U&bl3>MD,$p$`Q@'>F]FFk)#6"bn#0[%*q5F=p6+)In&&%X4^K:sB'N^>rI.]?<F;f.K&%WJTuhV
	(qi3,t:]I3-`ABN`_)JbY&Z/6VpcodAo:`2h,4!m`%^<7:MJmbR%ZVht77^mR0eLHpEP)>.9r375@g
	&go$_2Zu`KS?R?s'3@8>8PeeH-3;6IGMPcZ.%>uWeYt_a`/0I*,Yn-]l-=(l>2mKcQ4bRfj$`ti5]t
	#%"pZgm"bG%;6sLe(,e)K8`!Mbt89Mk--<90mPTilt)2T$-!YZpo-b19KC^G*5QMm>>,Z59!9UtV>_
	')S#mXO5L8NeSoA;HQr*ZgP'*>2E1#3<?+qXr:iUV=K^oUPkXrB2?1@LiN[UA1kh6(DmPY-l1SoLZq
	"b3RMW0"u/uaOs@MS%H>Dj%!LlC_%;$,&h;9JQ:rddV+#\D?^U_E?[%YEPb*[0-5HOM%d>ei"IIHgU
	M^f,sH6URn&uV!9-DkO[Yd"@Le>d/!?/hH67rBF#((*OkNq$P'-*:IH%4)00SAp?\ENK`n#ec;ue<k
	nCN?NB)\f)-cQ%[pLTQ/YK5F4d+i_:f<t'hBY3LWheJNMf^B1B>ajM#J560H'_n"cSpdto,r_).s$%
	[_M>HFle@:tK]I0,f\*WOrAF$[q4Y6Md5i4^,b"W1.CZ#0f%5#gIAAU,)#Wi*&P*+c4Yc?*)(#-?*f
	[lMXlEMXZ^i+SOJh9E?]>C#m7Rkq2+$G0&b#:ee1'H:;HfsPO#deZ$:=Q:3@S,k"3Nc:dRm?jcf(sQ
	<jpF65F0>HJpfh'a>4aac%8.fIg$mc#K,#?gN-<nlc_NO^T*KORdB;`Z]F+]DfDneY'BZLC*\S9b.V
	C,$"V)WR8kV/t*X/YK:^NHs19:DqnA-W#C&:sW1p2'7Vr<]g:Ur)s:m]V`mXHHu4EFep=&oMFUY!Ef
	"k8jei0$5/J7.)i^U*o;DRL>71P:W<W'/'P#]P/"ZL1%l&\0E_q6Kr"#2.X2:Lj*!WCYb,CO)f>D#p
	8KSC<"sSW<LIJA27)Z\d8G^Z/:\5U]Jp3aTVl5V<%)D=]Uab9<L3On=Q9E\=#sK#Xi0c:=cYAY2e1I
	+lQgYFMqDlpIggYlYeCZSm-2o$BSIUI+1>e:B!?ak<3(9p)`c6(^T;=W`R@Z<gMAT[_`fELT]E&j7_
	\rj4Z*ZTKOB2*e,)!@XQC+M6O*?m8p#Bihm=e>qB'@f`rVpb5j4mh\BL12`uN<$H<J^aj/_25]'JgZ
	HSd2'no87<Bg^/WV6iXp@'`q6nPGJT;4.DZ[/O\UiF1#?IN?%/liO69gic;E3J1TVlH0jEsc7#lW]?
	km)b]Kmp8*69c=`_4V/6@-@gt..i-@Kmp6`X,q=%CTYCip:r)\QT4NYPE1.Z%tOWuCc9SP!Z#u-'`$
	;%/Z7b.nbh\V>YaQIlflE<D2V_=g[U!(X`P@WFFd]8M:Vn/M;WjjqJ:n0QK3\cnqqAbf?0<'D9^!*?
	d)36W/SC"Xr5.aS$[a&'?Lr.,1+0IAeQP$YooB!^cB[JN&ordL+rt*lhk#F?c36kI,[P!BV/e&ZWGh
	9'7lHmqi*RtF3IhI`5ue#2D>R4Q?D#L9+`OXaRjM[/UGU\%8]+FKXUq[K+fV;s3N>@:'et-'.7tQ&L
	Z@GS0C^5+.,$m%=V(Rm9IXkd):be[k-3]ajaaW8:8tXau\P#rN9YlR)hQ=:,jS7B-9rO^Y-P^P,.c+
	>WQ`SY:Lo>(6=q(3#P)t]en*<l7aS\@"%"]PnBMhX3XjbjA8^oo0<m8AD9.o2"hP0SoL;l,98td$+C
	8u'K.0]:,GU6b^n.V1WEGh*C">IW*K[Z!c+Vn`H_C/[:NuEmFCCW^Cfr[0[8L4p_^l;+TGGOMuL;6h
	/Rnl(7bidhOpj*(em/eqm$[TgN*^Q1"PW!$Kn:scWI!)$*OGYT)!V>dC&R)?8?:a\+6I^#1C`tp7`E
	qXG6L"a?T*okjcfa:O;a[1^<Ha#-ck]:H$dA'$\^DW)Lfo\bT^rjg'k$O](`US1gbFSg;?6-AB,Vkl
	>^;!c>%3:BBrC*8`HmPQ5H(hcXDM,E[pD77.%5r+RkYV(.[F))fL7#Dets+$nm"Lk.>k)CqF0oU3-K
	;^TU&)go^0'<#(G_=u,bNG8*=\R\5-Fs&ig/`IbZoUI`1jI'a0m7I[F9<scJTC1lja8`H7[5GFe_#p
	,-n/S4[A$0mP0.T)u`s-d7iPM:>(U-?*]XU!/pC(<d:[*=5eY=?d^*W/nF!sK;I@.'pI(qn&UN3csg
	F'4s_VWUZoe+!7dLj4rE/%llb?/b/l%7?5/f_GV\ETrW4<>T?R`rS[\*Vh19Ui$"JqEfUa0.de.jla
	;`6GYMIIQmf[h^NN^Qe,6[%>m);I4-bV[/N^-<Z?[?gtn<7s1ui(r+FMrtUY45j57JFe.5%=b!1r!*
	]JA"gnNL(Eg1pZD!a*X=,Ue@e0J-,cA'G*XU"*Ng\GaB;W(!-fEkUb3*Z6G>QPWJLRj#2j^re[`d]H
	$R\USS>e!j1B?IB.7S9i^r%1<I`*`.K:sC2V9f_o!4=RH.![sH)u;i**R9,\ZgC(DG_d(1_1Sl:&%X
	1]K>A<!_0l[hi/sdr3!%q;&LRSI6$fI:M%aS;&gpitE?ZY>#$"3aa>0r\30?ZREMB-nie3dfi^?>-B
	T>F=`5,C<$9#7fKJl+u#p<%[IOeB%!CM(0i2(<>R%;:mklSSVe;*N,8]qFQ6#(+=mG:uOG#J(1]Lte
	;L9Sm*n)72@qYMU=7>AV1#nYDtdC3fo%P3/)$2tu$J)%X,KX/P9:)fME)4_Ta^N+j`ItN:1BN,^5io
	5@=>MiQ]\ar8hJ?WBK$<c=.R/7#1>*ud'geGiaB-CU7H7BEpF-(jA/%^8&Cj,lNF%$sU-`$,TJn9^n
	m8Q:m/U/Cq!S76D*e\\:8?31letam?II,VNq$A3C[V97=P/Z2AVbX>1PY$G'>@3&p851j,1J?B#LhX
	F;%k'm;Mr=IY!A<meSf2MC>Fc@>9E[in1`28KSS7-Y?:fJfWlc1rW`+UYQn6VPO+?!d6:q,SpC5^R+
	mm3Nf17r^omTYLKfmRa<OaK&G"CopcT9+,alf*K7ZCd.L<)U&/SgY0M1kgt\lUA)<"oB$5rJa8"0Mi
	F-%I-"k6hGOh@sY4p\QR3OEq+!!'lhlAa?F>6)dqr!QW%tNFN!jh-FnVfDT+!/b>tI:ETQp.r>:5bF
	oG5p-5S.(S(h>RH(eO-.gCn]u+^m<"?HWli@(p3`,JNhh3ANmCnHUMB]I-76mocS6V2"_>haC3En/-
	3oUpjhN%[3LWn25XjF6Aj2.FS/gu,kF-'5S6q.4pk?S5!=_K>I*g%Z"Y5Y+3!?Qr(Z0nq)%obUjPdj
	Ru`k]r_WE5\[=2dZ1]MME8Q`hdQF]Nh;ORLA325Q??Cb`<OPL__MJ!HfR9:_M@rB?D96'L\f9oH#kP
	l_2Vh67do9;r7[."UE,:rF,Z]YJS.(lLh5Q"L)7S(Ae6>FI62fSUF?_9`^)<Tj\DF;Xm@6eaWnK5N`
	?rSWQn/"1TO.eJ@-(&Ga-Kmk`JKD!7qrF"Y969ba/I^#(f,Yf=Ei^D;qVeeno8?7h3dAi!9JI."J/h
	ePG*-T8WO?f16+`S\O:'=QfS-Xrb!>H.o;E?"Y'1^Q'd;%ucatqmE3rB)5J9\_?Dd'F>o]o9?p[TS4
	mkG@*@BJ?Wj)&(#?K1A/g%D\W\eW"PK[q"#h:8[aa%Lcd?[]1o]GWOe$",\GD$f#MJ9fWX*ac>BjR'
	SR[(4[2,JAG?>!I9.M"@_7O!/lWBsNX&S`<-`!r*X(hgo9ohA3%PP&K2o8I$QH\HOId]G3\n7EU1Ho
	Qa-%m-MLrfYIc<YPEM`52c=n#.Q$>&pa9bA+i*G`#@Yd02G94XS7l7f%?oP)1f7!SI7?PlUUbra!"k
	shsV;eForR4]tM,a`a4J&/mj&A^d?Yl(5Zl3hTdJ0g]L-B*C$kX8Cr@t80iSXL5(FB0us^?ODh\=:3
	4+V>srdW0b1!^;`8d8:10ephh>99q<63$"39K3N[<SPeZJ0Sq^RKq++N198`Et0)jCO,`%CaT@3kkq
	1uglL_Tal_<)oukbGq,[Q3^3k2T)ZAlVFOY;e'7hL7.9b\h)m4)?c1Ca8i9#nLk]D81*G'<Q-bVLe"
	Yb=s0e4^?DE-mll_j+A^,/pYW0oqcQ#Y\4n=n=TY8dVHYD7J[f;`Cu.AR%O',RXJ2?b]:d@'\m[N8?
	%Ngp#d%oUpB)?7M0U3cP8%t'alFDemN'@qBT._Foi"("iE7ANZ_I-"D;k$d8S#o"1PO4FWiEd+_N+^
	$1UBg;!B;%H:Fe==lpc^s#SuV(\Rfj`!.ecOreeLW5aVmoUQ"Qo,dRdqT?K+B2ZOu\&[;)&'n'S8HF
	nC&Dqmi6(,N.://r?crssc]*Hk%Ciba5;8b9-aO,n.cflgu?G=A&'ptEF!O,$^$=:9#[n`a).`MsFW
	]"?dn:i9!6b5uidT0UZ[[CEML&FK;'9d`<C5NHo>&V,iE21#BDjJ"OSp4S:pKB,q4UDhLZ2Fm3rU2U
	c9RR04UqS>l%2#9K>:W&P)5?3/Oa7@NL+*>.ZoRe"rqSCbA#N7'1!U/9Uh1U52oRihZ%&D5\!XSb_O
	f"4"&J?I3.3qY.!4=TA6r3q.L!;qTS8`/uWe_<3Jah#8,Yf=qKu=96KuAi+$AfGn'G;dRYQLXj=6G(
	=XjI(JOq5-hWc#M5#@X89r9CsQ?hb]VZ*2k,Hi$C*D5@V+S-c/>J79/74c_f[3Tg#-"fSu&co4@7b4
	Hf&\/<*/[V\0FmAA$dhiQBtNPSBugM_POn>J5-gSB<0L]PTdq%.LW4Q0XWi6ChTr!qL;rgPE2o(?",
	N8E*Z??TA17f'4.6`F"2J'tb'>+eGInT9rT?;1V(V<(9L^UemjUqeq0rLma7kGG7W38@nu&#,3!brH
	_T;&RM#J-t97-7'scr5"r]Dik>H3-g?^(,;`1G:HTu.rI!jhRrUW4a-2aFpX(e5rR%XZm]UZWa%g0n
	#h'pF-^K<Q'<E%H3[]]3/gH"'Hgrm8n)iLOuqZ)V_Y19]clHp7,Gckm_$,6eOALimgF6m:_CsQ2OS7
	036$2MPcWX2a5Hbe01?_7pfRn-9serkPd.Cs\_o`OgA9WfW\EQ^Tc=822J)HkmJ\BFWSej0^'6MI8m
	=R`L]$_3q7lstYF:4oU,*u<eJq]fbk?M1$<ZaM4YqCZAa/PYZf5!8^7ZQ5cBWc4.1a;Y#[I>9?OU0;
	jS'^5H=&#3+M$VYh_t]BYIGc.p8;6_Y^-k^SLh?[<EMuS@2m$9AD=:j4Dr0qb"TRRf.(LZk98aIDCs
	igPOI]4]jn=7H/2\-,/M7r=A++MGjO4f)!<Z4N+s$1rBW;,7`fNZqRO"GNMM%WS?t!>HH5+.*@k:%%
	:-8E5*iZgj!iK/=6Kl0r?1VM/8tJdq8"*AC[ikFKD7;"6&S(V3Dpgm_9`^i<Tj[WYPm\j.mGZ_#HYX
	scjs_fkQeFEoRg9]qE]d`n46MLS-Xrb=VVPsgiOAH-\;s:"`0G?&gq]1f"-YN+b?ks6K1C(S-V%IF:
	*j<%E8p8'901$M%]lL<8th.F^T=USC*2-j6g2"@[$]/GH4b4_?GdLs0'p9EP4Hd^Ah48]'mT:n#f!O
	ju,aT"[j<blr&(a,_8tf]H8\QkAu-q02?sn(68i::X<:rl%D!^p4uc[Z+g#KLg4M84TRbbE6QbNhd1
	ZLA5KUP^oGO*$'1"l!iO`7L)GF$q`dUb1_tq_"*bo>5jXYu2H(iqa8uHddb_qVc4=lXNHe<J)4=)#Z
	qpgIFfQoc2G(/<8>>I]Ek9:fT`)qY'3eZti!pG4k,88kb,^WH!bft6`qjQ@GVG^fC&C#KHF82u+lVN
	!6cgGi'li9'NBtRcYHp^CcJ*+3^6"B#h3rp%<aB9./=,Warn\A*8,u@BU70.>:'9u%!4:i&?RGR`TE
	,g?1Sip2RJ,HKQWL)m(V4L]&9nf'9N=7/Mk&ruP;,<><+8*kEe*4<h*H6p7:Nl)PVrI9_P%A9_:(oe
	.G<g5>V\&@n77#EobRTj&R`c+QCo8.,ppP?`b:dJE:fZkULoRUZDjk8bX/c?l3F][OAl@u[qbKILB2
	3W96Y]aFr,6O:U[3_An^\I<t8'D:(i[,gU0g7!e-.,igZRPrk9l163[Di+94u$5uaq@G-(&@Y&b`0g
	D+^4Q)i`h2B+_L4;Mn8eADF*f5dQNEd'kTadAp0/`&T!,&>TV!.E[@gSut?2U<LMH_U*p9A49XOa!6
	O:8ifBcjtk[0V/'q0VbhIn"].=nVHmkT_I^BK*FgLGeA`Z0_C"^gP10]g"N'IE6sj.Di+u%?k.m>0Y
	Ke;R&c_'&(V4)qS=CM+`S\O:1VeNOZ7oR5j0>-.h%7J3ST;,$$V*AM3'ui>9S"'l+2s9Oh')*371hO
	EMA.JU(3+`J2M]ZdMa+X.OV>iEKd$(aAc62B;to#]n\9B.q0lZ<<=8s(@S_O_oH&o6jo4Q=c:*=rrm
	XW:@%l4#$'8KZ=FAAJ`F7;)l^KRD8GZ+G?;9L)h8;,`%OW"B<dHq]t)bh(cAo2`r@3\VC0`Ij[PBkX
	/:m5D^WBu9UI[DdbV(n-2fbB",*C?5jl70!d?6`Z0@?\4nkDTTMTgt.<*EZeP6Ed<m2E4b^`B.V&Ej
	nU+/&$OS&H;aSZ#(SU$`)`OYu?[n_.n"q6Ek+u:bo8i0"sCV8YdM#i=/anWK)8jF%dA9Z4s7q:NsL)
	l%;EArI(844aY\WJ/W`!)JU7$N+T!G319R@`hflM:D+%*[;YFaBLi^7Pr90X^RSVk0o7hrjn[F[S16
	,SKh(+g(l`XDH@CJ^TN7A4JgY!;5$B#A2*pZNup&:o"H:7KC+28e2&TU5<I;JG?Mp)Hn_;!<3\_3qI
	uGf2Y]lQQ!j8!HA](>rcD"$j"g7oXV$(d#WLMLBggiE`'$JDn_,35_.E+Y\+!gFk&QYI3M>g0`XO`j
	f4V&<B*0+d>B"i@6J$A5hJ^Ps&Cgib\NWBi[5<KTEbKL's0ZqaV&Ybc]&$oImrU]mm=ZK!F-,=-Sf&
	l[0?5r_:&Y(]m0J77WUA:GdF@+<!`1+>X$M=E00M)Zp`$;0l:[cHiAeP$dEG-ndtF\0;UZK"<^%&A,
	)bp8n2"4;)IY@Tlt04"6aCK/3Ti_Wp%8e1VruhHpMnUq_Y*ZIYh"8=nO&Ikute2g'dhMPft&pVUjLK
	12%4^.%h.+gUHd5m?]AZ&$#pEoO.Z<W!@<)l9S^`[)]W89FhI4*"H.8B_>ahX<,TUD!SnKe:6K;><Q
	YMeUrjdHI/H*Ws>aJ4>sI)'@q^g.Fs(>OE36<&43JYKNW$T3+7\eS?NKVLD&o4OW*OFOV6t>!UD^Bc
	bYY>3omY^hg(ImQ3"gnUdm;23PJ$AJ=Q[&!&XhZ+S^9an(gpsrd2i?ScADlm@D9I_92ta&s3?+d<D/
	/n'*mFZ2:rkcTmj=%dl\:33heldtIJu&o#7iO5Q:7V;KPaVD]m^K)"FOpaV_C[1L.q&XfV??"OJ",U
	d)o766-h,gm^28$m(:`-`2lNZG9V8r2T,!'J(?=p"c50FR-7F!B<CR!'_J!"sobAs"+5=qTq>,"S_[
	mYZZaNJ'PZbT$a_qnPs&=u"&Hh+aQVBNCLcGo\sNc6V<Sp554h+9Z`YfqZ^,V#P!k%7]CP@]`O'l,j
	n(1Yri2^Un9*MWs7bej>mD5m2-i]$A&)5`SE=!L=(-OtL'-IXDM'oC"JT=>kUHnlEfWg5+qn0ZYH&J
	=Zc,?QArbMc#]H-TtV3[/:SjkqbS%GYrV>ScOT-)^/$nK9Z,$!2%R\ig!)2XT%445%>_FOhgPg<WgE
	ZnOd+)Y3k'sH:rc?&2Bc+8As:Nq^doa]"P!Rp]esVMa"om?^gb+g4Q#u8k0R.38&6jgU6'[1_C7ekQ
	:5f_ffhSH`ad9@^#r!Vp9#,k%PClp9`)re,s-N)/9!)MTsC(QI8XT]feoRbnl%'E;;<-T/gEeV3]?1
	HI+nfdd"[/5nEO2e:Z6O/tH0/BNEdN5uXj+[!M4\A+^rEWs?nRHI1rnA!Eg28&p=0)2'SR4?Nu(ml4
	0Gb>n)BIU//d!F-).#XCHsZ5q1-d.a<c\IuLZi(*p?)I4+Q"?=='=J6_tlM$TOoZ^t5cYL.(Dhm4JA
	$e41@`JKk^>>ddb0-(=s"=MI8*Zb"HH1ki;!u<=dXhH3NYBKo"(BB5'7U`_R/i;)i*h.#$M7-`;^Iq
	[K!Kgl"NbO]ml5;`W-9@H=RE"RW6^1F"[+#^=`Y\o:a6=<--$=aX`p:s5^KZbNY>6h2ZQ4cM-r6V93
	g(I`(Cm7bO'A@!;8EJ!,U>.@VT[!-Oe1%a,,bsVW3>co)Tu2=Uc<2:)jo?4&-c-(6"is]16a6WIh]!
	OO'#fr]<BYj2<AP[SPF/LXC*.W$`hK30EWO`!AKOS:Wh0*W,K,%53Vt-+Mu'qKj^t*%+GP:DOruJeU
	EXNYA'W!'8JA`sL3X?#l9h36.iT`%dTeFI@JmXE`a+,nO;bU<DL:cQSssO8Cl#=8&6AXlGilBrt/IY
	YLGSl&OS*2f()7eXm0n6!d$R59L<KcO+]mITbH9H!gE\S]$kWR9bpgG3[?d8%hQtUB"Jem^aj#aHN#
	m/tV];&L#b)fV@uD.0T>0o^j5,cHL0,9@9G/!7-;fDbKr.YO9s\^h;n(;TUsr)a@;eU[h5:hnan[&,
	AqD:&1;E[l7PbCiqR<BDVZOPi&pPY-+o_JA1UT<S?)T8`q%D.L:Ltkq>Lb(;G^`:On3^X$Ru#dH<R3
	F[Kqgo1UKIb"R%uR<reDlm;]DWl&.r@C1P-ftTYImURWh.'eseN#%-#CSonb%SCXG3e[HVK(Is=1&<
	p<QA[Cc;8(5I*bN!4VNQ.O0^8M!ZZR)E4Z]ctTqs1O)ha!383Bf6.K?aTB<0F5ja7D%l4*:^N<D9][
	Q.0KS3(uli/a==6:j\giFcJIm7l^,TFk:]"BSh;i:W6<9AZ_kao*t_^'WcM!_4%>I8m"f1i*Gkofg(
	!l)-'>GpW&TS3n$620eu-Lt7h-$"/);(0?MPhl*3#e"P#=!C3ke,FiqPAro)&j<tcU@M1g0JZN*uq[
	9OO+=2Us"O+2:jm(DdVjareVQJ!tS5-uBU-RR=i[tPMl(I%I#9a0XVsTk-F4d7p/S8*JBV5TapD;mi
	rQ=EA@pBOBnrH!u(on'a?>]A.)-.9:@eHDEK1>oB%pD,0e;i(3<Y$7h=N:a65hHY65\M/D;tM#-NbW
	\:WHF_E)='8E(@*r2e;b3nJ^>D&37/T/3+:6oFe#[r'*gMZ15l9b'2ni8@aj9Wa.Ye>5^]cJU@SmZ?
	?H:8YIWRe+0R]nZ]A.XGQ*mK`P8':.4@,"Z,u?_KMqaF8_lR-+@hRh$CYTmn3sQNJ;$>_YX%Uja>a0
	LB\GJ^[Mjss2;'RE]e\N@OQZQmPIg_4:!Y!\.mR>H2LQ]gMhYE^qh1NB5*TeO/p:`3l?kt;p\b%H.@
	?IbI0q[D,*<oCFk_4E/qkh7l$sHd'c(Vf$+JU?g-1kZ;\B=;#nbY\aFf-$Xm*1Lo]\@]JfG?i$&+m`
	:&d$9qg/n4J5AY66;]rlZ+m-tUceGKC7&<7&7kDPb\=DmRLmro2:$94+-L:_X9n]dMM.RO"OHMa&7>
	#qR'-)':Vo,c^^#OL3Cgeu=I^R?\oD6+Uu0_J"///?EJ>qD\so!K=MuN:I\0o.+]=5[Ul<=X*f6sBn
	/ff[`8s9=,V7c(6k]Y&W$<B-^^UCBS1_pbSW3ggI"0!#r"Gj?&,FLV8haBNmg!Smco.I/C\IU(aC!$
	hfo?cC6U>jG@@!V<UV3)t!A9/t)HTu$G-+Md8I#7Rqe*fgm\F#4;5VTme1Rq#*[,0b[S+\+N;??-cE
	]^sI8uMkISK;uOZ!?g87++Q_8,N]fk$qq'^6!VRG@uW;e4h2;9Rq9lG5<'cuH-.4<F-faRQ/5C%Yjp
	X<(&feUn`Lp#(sdeUpm5VJ4*96)t6O=fgY:FWfJcEUGep*=1+;1&AK3T>,N=BGp+qOW*OF!EdC!lsh
	%`!*I8J1T]ViFe!-\0mR2LeYBU<6e&.rW)a0o$5<Kr8;u!dT;M*h6CoBG-\/BD&\W6n655">F&4Jc.
	>\c#Ta$#$9uoFCndU>kQh`*f9#[=tpD0bH$MYP_:".R,6Iq<5"(j]c$m7;Ye#5#rkqA:i!)4[$#u^8
	:0BE%>M<eb:"nnNNSe$J?0TF*uQ^AKajQF#?'#8`ZO.+m5\2__[-f-nj'.J>11$Q;N^pVo<*F@4[N^
	ZKZ4%RiMqq>uM_7$g*49ts3ncA["I?eQUkZHMPf@D'R?W1unQ']nr*K<Na-fceTjcu"<1[/Pk6[.rE
	YmuUbWjHI!RqT0Rj"B^\GH?7,FK5mk?'bo:q1b@PFVM6(`BuQg?MN`GS.6bO%fjC'5h;dSp9XtLA:V
	R#BbY]8kTN?Yl2f8eD?:GNOh?o:,'-9#N@UsH&2Be%a@iq=9l("PEE6YsEesObM,sHupKmTM4Wjk?e
	fDN?D;L$&?.%g[:?6.%b_#B=W9$tN(N4_:(B@Aa&88:PAS'3tkKM$S1DbSH/Hha(#a"H9*100+'#N0
	&2:ZD"1V>WW!8uObrPP>ABj*D@7%h(r;4jGFIa]MIWBLT,ks9\$cLc-T9rn>OK3>Mi/4%g`]\JH_O"
	?&-Ws;Sh61&Be#EJsM#XLBhDgG5_4dZ_[#?,+)@&@$hGXQ$6TF"X0RUGf]eUp@*M9P1h"G4iQL*(in
	4&11'PkkuBmgFB,-oHJ:SfU,mGh)V*f53T\,W4auNJX<M#%W$G:=[Zc.=Sl:IJkkA)pgXdM7!V0Z,r
	M:4&1>'*%)XJ"Sk+=rZAJ;eM?)C@CH0k=/4Vl+tZd"%Ua5\_S^o$Hk'P2_r=g?S,agjK7jKmpiN#;*
	[8W2#'HHo.$-#B::('uj*YP#JB:hQ:)FaHnua@>*@Ch(?[t18*%+:">(A)7NY=[>!98CGM84IH+btX
	Bnr@8$M,u#drH^ad3Zc3[JBZ>Q9pEM76>4*"<pr![\GlsT4FLI&.pdm]jZ$\[cPk/M!f+U3,"VMsmP
	lA!X?TqL3!%J"K)%.g3,qVu(^7^:kU2MWXne_(5qWcTKdZ8W<!lgc&>pq1DnNjQJij*q60'a$IS$BM
	h(dLB`)eJdN;@5d74X[RHM4h6Y<(ij+)X5S>j$7[=plqdG\3/ZU/eJ$Io=d'J8rM`0g!=1]U2:0Y.$
	VnTH3]B!mMpb.+kK:H!tdC"aQC^W6+c:8=:Wp.0?*mp%G9kdMET1cE$(ZX&J&=T>',4UEZDg+um^.5
	Xqs_R\(ab(eW1\88SC3fslY->.(moEI@qJ%jAFj_T.tf*Sl)djglM4<uUf@h9PVe)(i'\iQclCKb7a
	51>@a'Tg4qh&_UteUICK)o?bJj[^:?:p?ASap&f!>dC^@4VG&btBWWlh%A0VO(!9ISh\XnpRf#5UUZ
	"e7EQ04-o>j4,eD*nELn'A'Ru8P8/fHl3D3SaP\E8i[+@22enZO%q%LVhIEEuY(k0'X`KfEki;6l3c
	i%BiaDX?EL?CpZ1=?sS&K2#SOGDGK.c$p*F"S#"2^'UB/USI'PqI^*A]:nKNTN%l:-RQfeQAs%Bi)H
	(kk!Xo"Y?Tp;8@t9ZT*9a+a(,SYJ<7o%b?%W4:oJ)o^m+=2=c5/TF[a\B#Nie'lBcF92Q;+#145qQ$
	$`%]"YK0o9j##0NZP8C9VD[p[!M4$d"<T>45TTP5cY.=e[9]W'ikiWLt.,J2HC?c_!431X<+`pn7]^
	#:07`flSnoI#K!im+HJb-M=l/7TAp'&lSrkiY`9Ae(=mKB3_lJba#Zsta,0a7'cUAFYc@?HQ%1DFgu
	C@,+]U1hs0Lgf08M8gIIY#>YPR7,T<>fa_`'LI*a)H^_@h+M^GY(i&_Z86S691]_S.;92/Yit"S1$$
	>Pa"$pj1MH#^LT3D4Tq-66l&C_<D)@DW+C*#i7mVNq(,$:t?+*LdT8h60_:A?!c>nUWpX1E9MM=l%>
	@9Klh4j78[h,_<XIoVbpls)CcF\9lr-1-*%&$3cGd!fR`=TBj\P$bW\H'$o>4\$rF9O,C)is*?nt*_
	'tJ[iJ7Vr?BV%>Z`bJRr*DfM22cVdJ9'-L&SqtY9*gY+!9PL6=e@PLZN-@5:5E_@mfhCk8`70'#VLg
	uM$&=1:lM61?B$qs$K)BB@I2ZDFbOP_Cf=2:&V>aW<X\u$Jl+AMJm0&X(!'%a7O6mTf^VAY$pOu9_S
	6+Z'Nn2R`H`IgbC2@W'Y(<HL<LR`D:k*=qdg\2(Q\/V&U=rPU>:Z#3i6*9GRD>k#aj;8#is2L($Zc`
	TG^)R$hV!YpPm`B\ut13Ql\?s2M5V-4-&G`!"H\5;Z>+S-d46[Uu8(h:M^f/s%?]S!Q"A^c+;$H\gL
	u[Q7Wc3(RgX+0q1\%ePi.o"O+45Lh,UTeoGH/H8%@4'NmSDE&b/qTH&0%:slUq0L[k"#Ldg4ojFY!4
	a:YEH8%K_&"6r"T[e\83nA;f3Y5K8$0siiJC_TtcZ,[b_<6h?`sGW+=iZAON-1XM,-d.A-<S:p'<L6
	4Z0aMjb[)+i!"hC=^n/G,N[#(s'"hO<s,I`lA]P2V3p-6VBj_,f(D5!qr';c[a/RnOl4ijT*X*H62K
	f-Q>JL!((T@#o+A>_c)\*D55kT0nX>/6kWt'5a[=QYN!,9RCTRt+h[I2+g@?6Q/g1rQoB._?&>l[.k
	'o`\/=$6>m2'T?QYiQpti`AF@KlC5lhEIi1dDW?YWS0F\<*>SfI0k!MBiBOFTh*ruP=dl:4`YU(KM,
	bC]-e3aI%AXci?7mfO;?[Q)Q!8]&A6sMBE!dDDb<&C-$[\AIf`o_04-Cb%fdu:/*eG<"$u4&$ll,$&
	5DR8K,tS5X,rAW[i`u^W)A.4c*KYP*Ms1S=gcK^]_UE^l@_>H9K16SWE85(lBYK7f!0)tJ6)_*R^9B
	BGC!#QP%Qb7Pk:J&-*R&[1Q0O"<G&U?W^=<[#QlWp!>5:%Bj%'qO$Hk-fY5WA[<,7k-%"D3'`\XQ9i
	rC0F(N]^OtgdmNBOFnjG&mrM'&=n\q@s"#CIh9Gh_gFg&uZfNb>BVlb<F6%^;1F:t8"DpafW/l,g=7
	QtCd4Y!mbMO?4j@&a`XaE^Q1%1N)QqUsC6[c,fi3K+(telRHRj0o-LkQ/0Ij$&+<j)c0qL.1?3<?m7
	3T>0d:Y)Ki7]GjP<[>kan'-HJ>/2]!\#QOPe.$JYq2o]$_hjr5&P%(!!;%Qd]%-H#,b/<$lGX<'L*H
	>q-Y$/;R'C`08Ydpr(/!N[>!lGMmQ1TVWkJ^oC4Z$Oc[7BGN;(**\Xa!/6?S1rtoEh'?DKEn-EdW#>
	/f5^"6@@BL-3_j4AFdtFsZ&TJHY`9Ad=N?8.gMu5OR)h$omF5?)JGBE#nO=@WdmsrPH')M7#'sMs9=
	2]e"+.e`..N'Y$u&OV[1[b,F60C9g0Nms:#MJAN[bY"pBQuD0?[m'<`:FlR7K3k&hgE&W:N5X3PokL
	+^GCF&AabFn>q3/r.mpQ;,Ra`Zr%-ddI;M%P9+L^RcpKN1O=Cfr=`lEU&L5t9=hXi)=ffh3(6Lc/AQ
	*co61Aai/nE[.cpR7OAuL]F-K4WkeI(thXdAc"*163YZ`WoN*_4;`Jp)ErtU'([%%oe37)f-^,(1UT
	@65_]Xp]C0Pqm36sshVck<%6g'L;qJ1>[Cr8%a\f9a"6[Q;:7cWtVHM/WI5+Hfd`;.N$kUgN%R<n^I
	g!ALi^!HnjU@@;IZg4eP+d`Jnm/.o_5%GSV4nKVBs/=Vm,[m+.06I*j0;to`oj#,RnCPa&$:.7G&$V
	)E0R$MTq]B1+:rB:QY%XE:eT^3kTeeQ4j4:\%,UccITY:70!eTN%PB&@ijYJ#^#@J,8R+1jOIp6D#k
	mND?-kSj2Xq;J+o'hDmB,DZ^"S"3og::^F+^,ub<kZK1ha>P&boF=(3`XJ8\;c,Y$5LdFAa>[^YYJp
	<A,e_Gi,:I9h`HM[@(R)?3b4)\;YVS5a0tSF!3QS.(U>:d6V^*M5$,6ZI3ct:lFraUif%PRCQ&SC^L
	p/6s#+AjR!W\KO7N(r,<s[96E.@qrWa4q^LR,i5eUo<UHLTj#oq9ifc&,^gBT1Jo%Bt0J!6:-AK[k]
	(Y^4[]_5:<tBM!o#S4HCO#JtMb[\%]40]U5pS?NKVWN_Br-8gema,(#t?"pmYNY@gi*@D=+eo;lseo
	AP8lSr;n-Q7#!?PlMQf`D<0TK\t;"oJUuml@e#l#-@s:B^P2O$8*'Pc,\*h)aJt'c$+c!am8T7#RET
	+r^O\lIpj\TNN\iHh([=-hZk?+ehV[nf3qh+KeG1i]UM%W*00e(6o@P`R3N']o3;FnIGeJg9BrF+<N
	T)cGq`!hJcb#4F-Yr&lK5A\-^%PY)`<L"f^SZ>sY&ofXajt7CK<_3pr9p!#DIKc7FKb5gYHOII8R8'
	T^jsm%;!KG<n2Gf%t[(h<S>A_"_r+$51$o8bML(2l8+Wlhe"Mp`==(DJJEt*_cqT%GR-@<N8@u^BLA
	HpEKNg%\HnskUfr*Zi)rW-.)fA;4b^4J_gt1?uh@pL+'\70Zl!NJ6SZdj8$NL3r]6V,)d"mV&_tDot
	>e!k=jWK9(Bh[`Hbe?'PdHK#gZL7NM7%7phHI^LtZN!DB'h2^g.KbW949U!VUIVr)SmtY3TgmErH*U
	,,638cdtJ]i2_poOAYX^anucaf[T6%ilC(X6!afc]TCQ5"f_&m%ffo0F[#)jdLe'B:J6U5;#leej<3
	:mi8XtKP$9Y?mHO3S7%Q*sO2*3ocHc\j^Wu=mdMUSYe^19?^*m=c!Ku=BGo9V`76sO,Rh7'L)_ZDB:
	S&l/A4fE7&0E6NF&HTHBflUf/`4&fm32)J))q2B(h]Uq#2V9jCI7j"U'ac_0o23&:(cRa<'MEdI<_E
	DAdoV?IH5+3UNND#V[dY8JD9hC/Wg11Pu>ViWTna^Dg_X0`hJZYjY,H^K[!>=<+GT/!3@6c!`fh84k
	QD<Ws>aJCtb$%K7ML)qe3,;EN[iEc*;RKJ^oBILL^"M,sBh!+rLD%-fV@j';emPM5/4EOOeCq9h36Y
	irffEN*=8Y"'ESMUHYd>KGi?\+pHP;U+t5=ip^p2?Pq&0a]f7/(Cp1!NXkh%6mhTqq8)cdMZ&@HeOX
	3TM*p?R_fTd&^Ac>>HYNm0,kqh9AISrt:Zs_]RS2SM7L':n'YEsW[I<!A8<V%ORJCR]aK.h1V*Y`s"
	W0''WOp_jFKi2o`qYo6k6VEQZK"c#9jKS:[Jt)TV@PE^5eh<fgD*_1*Wr$GUg+'G%jEZCRPd!;ZirU
	j4-2WeIilC&XZM&JM5>8``uR-N&?\c6;M>-3[EleU-Q+l2]#p)S/ec&[!Mj%H',7C#gVi0Pc0jd6PN
	IR6"q78I!9?uJVo=j3O*"[931'B14R48lj*d_pOCXP#'fmPanpkj$Z#oEt3.tK9R(WDJ:%^iBG3/0:
	9,8eKIi8;C]*Z;k5ckLLa6MJdH9on"`eUb'"cb@0+#_Fc?)%sW*l("%p7RZ\J.''#^9;50XA_jj!.Z
	,cb4:H<ch`-EI\+I`O<$mf1m4&8'K&63fE!/"m'SpH$+/r`'6\g4_s"g\2"c'E*ho3*fs=qVjp>Ue@
	?of6M#95G5=6J5dB."Zh@G$31Vs%;aM2(9H>_0U!\.IY_2/.WTYCa!\o`S,jTs8NScDs.j<1B5iV^4
	NYVoK;93g)$jqFEc_l-qYf,^u*%%]X<:c..8LMgr*:>qYhRf4t&aC:JHa9sY]ICdC1O^_T2#ik)2JU
	[':ZtaPQIk-poi^?00(Q73`#gI3;7(ai6P-gPbK^*>,^UW6:X]i,(f9@SalR<kOZN(A@1@GhWn6C`n
	E6+7_b\]+sa<EE^g@29rmJVplhp]LQ/X=f%(-d_CLVo,1S=IAlm`b2R!GK+h/<\hA=j*MZlG4S_]6[
	:Ac*2N@lG:I[,C4=AeUtt'VY$P>9isQ'*9]\6am-^^=?X/9Ws>+'a6Gr`HE?-p9$A;'?l^Tr?l^VT,
	0(!Neo;lKa,K&3ae^-G33aRk3+3g5XlDfZXQ.6JXQ.5Rat\BSFN)-Vm@fTu(bQA\?\fU4q:7!eHZ+<
	\&t8mZH6`tcHkH&3h).?5rc%hHkB^Iq<s1-F^s!LIK@iR,qXquKj+D!.W3!NJ^nk`?42!\N]fA>sJX
	Hg:S6>s%"g$:70[@VReV.4n#so.)80;D37O\%,S`fsVcc"L<oG]_PATUB2*V6iW9q4@,mPt4j:eJgn
	!$_L%./h>bogZI%<,rmCe*JqUTSt[!"C^u1dHa0ZN'kaD,795-RZ;AeH1.bNVo)S#-Bh_/hVYbr_OY
	I$TCD'MfsgB,D8/."/V?BOX;NB^F8Ah#O$-cjqdUEV]CU'$-^M40F5*cLp7=80IUD+Wd's6E#@N%g9
	nca!g`-hR_m7D38iFR8P$:,-k]V$5\ZTX'957)]3s(oRdqDck2goUMcu'h_c[dpq#.:Y4D7S&=TK-o
	_[*e3IEpi@K(dJ'$+94u$5u`DCX[2Is!+-OM@@rBtDG7OeeE=!?_W$EY7YLBmJ#8:)5WKpJ#R&\.r`
	cD$f6S'4639Ue63WDG;:.O2#lH8N,sdZsr1QEV\?;n(]%8KaOuX^W^Hitn,^EU!oP]L[)uc[".C,-;
	^bmod._9ZSE*"7_59RUc?Zmnh!%K?O5?Y\9e$!NlOT>IIZe#J92_CT7qUQdEKS*or49:P+5a#e?b+H
	)*ZZ,I0)/0Uk^UUoE$HJ86"L>k:lNi(-PjeS8MQ,JN2JCs'PT)J+ZUT&KElRSTIW#'jJ3P%]B)p-V!
	(J/D8LrBReL6+t#32[1LDiB!;EEg]VLPQ#P']3;r@86ORq@ib!.cQM:&gVpXbW]&e"G5K@DC+_H"+o
	h'49Ard5(h!]4$sYaNHuno>@F8^OD96qJudiY<HtoQd*qAK,U6bi-YNb$Hmilb7/g^`jPqT?oiH3<p
	m,j%D6tba_q<^+O"`aVWEnLoq3JK\/l&?b3D9n#Ff[kkWuJ"YXOR,4m7]C\(-+3%pD,0oq6SU1CfZk
	gf.MTOO\uL_hWB)#_7&fa9'q4i[Ai;coBQ::*dk@:8Gok:*d'('@q^g("RB!AZXo[F0+E?iSgH,NBL
	/fN3rP&\$tOGOEU_7'QJ2a;1jrKIekM^J''pZYnW,tTEMPdM]0!4j[C93<U;mLUAu:8pWjM8^[s-@A
	T?uTfZiY<Bm(S3NWc.n$N\YH!&I?t]4VMNMan?dD1`=?*grpW;gM48<QC)qhb>3ki4?MPF^JHVg#XK
	]q*PG!,5%\^!H=?#0%,dO=n.05rrD-o5cogi!jFh\qL^c"Z'oa<Df/*&R!9Vqq"O&&@m<]=6+l-/Je
	7U/->W)H.QP$CXiab/MH*Snq+L15ZR9JX!?B`gDb<eRor['aB"u)ml7JVTNEVl;hs'mdY#AeL4]_c!
	V?jj/!SL)dpX`1]o5)c.Qd<BgDpc'TZ_6rEM9J(O@^V2m^(,-fa,1c8&bmqNR]$L`,&n*C[->4,C*c
	%!C3p_mrJcK16L*d?=p=T:Pr#R%MV9hZJ'X\A@Usu:E77EiG<D$uEl`6NP51-XN\^Yib?>#C!4R>2o
	@@372)\94)bP$t[s6>2\!$`SJ94BSh,#Bnqp:C*=)<AjGf$OH6f]J*C^$V8'\e0%XTdnaFl!9E$4cu
	OpOBZQ*#3eUA8EDRr81]U?i_\8#MsDQY:>UBD-uq@(4DV8_H_V7Re"]BT"a0-cO;bY@'eeF"b);4o#
	ob\Gs)2b$m;,1$3U43-8'0,iTcK-SG&L42>*lASLk7IKKMQ9;kWZW3\U4&QH(KD//n8`UmY%GZ#C3o
	o$;(GIg"I:q!#E>f6%&hXH@S8L;I0XNh5""(`MHF$:P:slDT*fV=9u!qhGCF+U(eO*W*@o@Cb^8HB@
	IlYt^!R58VI<#^/_LB9D-DJ6pm*'!&1&qOKPFrtFVC3XS;).4"lk6C_BrpWl/(-C.3?C%pXhb'U9^f
	"kLs]rKu7>Pg2>IiF,c1B9TdirAh3WAj`TJ;k6L6fST<(I8$4^&ZIk1(`AHBjN"iG(9CB%4;0IqEC4
	h)UkQ1^A#AE,gcB`Xll)[h#P)Mrn.g;Q4AC@/*S2;5c+i99Dk>.qnQ,6*V?ilV[`Zc;#ME/[s?tK!)
	TAZ8B=.?+5U(uq(7a=0%NSHU9RKObLkn=`%ONO?oD./X&ad0qFfV,8?Lgm+=f:(+k,dUQ6R6I#Ld_;
	lbRPp/Ql:jVSh[bWs>aJ4Fkt7NQ>34Y-rZ'lG6t0%uTTNd!+&F4d_P1=q:\uH/PN&4_Qj_jQ,ARYDY
	nXJB%B%4dI=bI?"sg^:ub*@Wro5S=g*a^C+iM^df>-hqe#N%l/.@qoEfJW2R67BcRK.hQL]PJp8jjR
	6"*=[:`i,@skB(Up;@qGisWKHdR;7j$ZWAgWJs\oG=9^1S=@[2n`M0_ANjQHVA+:8A]B+f$o]n+p/7
	GD[4O,U<eLu110$B!NB<d<#FPmI3q]RBluIPk'C96q,O]C7+=.e"31^F%i<1Ze?T(7'84((l.dg&e2
	n5mN@;I$.G'hs^R;g"B:\,6nP58!,oe96m87E5EM@^;X=YQ0OFCJ9V5[d7gMV@=*@KnZ3)5:65BuZ;
	-i-LbHesO%0n?GNj]\XGj2@#09tf*P6=u9UAbhHHhG@rM!Q<Y6_h>[jPEU>]3DMtPqE?0V,`UI>3&,
	@1UaIZel^Uu.Zi&VhCZ^11PJVkT<JF!f;LMR0LkgTSPAm&=hh/f=+RAFVdlS,8RH)4r<rtK?$.75T'
	27@E!R?a!HH1jm8oJqUO:*2D-uH^*a,/Nddmr9/Gl0\a9B!c0]!:WaOYtaCHM"oOarEZqREBNdB5#O
	R-^_7tE1CTb8[r;[M%e^6J$E[81PHj.B;RqS'Depo:(3WgXZpS-0-G3IdV\49GFXa"LJ58;8$>[:`]
	1TnW3T:Z/^`bnXhD=PS4uUg!6p*@Jic`g>/uINE*QWbrV*))X,G!BGu6s?U>R48#FSSO+UGmt^"X"k
	4er#s9#2#<KEutdMbIHfk+!>c`L[2$?WgR--"B)gBgJM<H;9p$Vc`pm!p?tu@4o@-!dW<A]mI3/l-q
	:'Y:L2H5m_(Pnmf@AR)43,lZrZhq.2Duj\ZJG#;?_R:ZmC!ImEiX9'UgHCLRN*'a/uXlL3]9dh^GGR
	t")@l&u@d'0*[T&Fqbs0<=Nt\K_9QO@0qI*!27[?5)JFLl@i&n]Da0pIF\B4fU&<Ob`B&f8fI^ReM[
	^Q*"8U!,j?@?Z`5irYkF%]:LpO3\B)bZ/b!k]H<AEL51Fr?mS3((QmK%FfbP[W.n\+l]ObrR\FnKP8
	:n_q=d4'.*PppH?6;a+_caH^F(0o$UOi^`:hFV2G=+D?glh,]fM`NF+LVe'K0K2VZQp795jesmg5%\
	X5Q8Oi:AY,dNG>AJ8^#:<oQ&6OSf'FMY27K>E,^:-pb.J!"^ic`Ro(&SgEe;DqL!fhLpr\8<s^]l.?
	UR)5#Zo9.iX@MpG?RE#6Fs\KgNZgHk<%ajD:\1,tY#"O@'nL&cbp;86,;J#Z4p(A1q<^U^MJhMJ>u$
	_LdV1hhUo,^G1.kq?n4qp,_BIbfc#6KQqqCQoM+7+LBD*pK=;%]&5=5`=W]KY/tT]3guq[*c^/4\K&
	3.re4RW9KZcUW*E;:/Cg\!<>GP5="rF,k4&E#*B`rMV97h&R79Z\(>b.4`&,t97?<=KYC4*,H!U(\;
	&WpO99">!8_oF<9@&M$=Hn_At'L)0(ITEK;XcXc11a!'ah'iC"sAk)]"7\<F6#s[[dL3TB8R(*0^Ol
	!*D)Bl,CQ;>u(oPpV%&5-C64saE%ZX9DB3qg<lo)!3"ou]GBCOfbIE1X;5"R>T@FV.9O-YHR-r=@C/
	t&0@BNQ/XZd@<=pnOB"d<Ia6LJT*&i0t93DW3Y^4Y1Ws;kGlG;gpoj@j%#H]%0de+^hWs;A'HEa7:<
	Y&Am=RklTH]#hhq@,iq!;9d@YV_'4&X@=*E2qrBK=DtZo4),nrOAT!a4sDDH^/9hH]SL9b/,()fcUo
	f'@Uh_l5^-:]e*W)oo9\=)3j7J_C`rg/%\#>GV]>qG!@tE3,rQ&M6lYO^A$fFR\qURGKfBmGjW!#i-
	.b_%#@j^F>e-/!07Q/M7sYdN:WuT6dfTc"k`9'@3j`V=*6T1qu2W_l'ZiP9arCmXke(c.2J:`[B5I9
	bOT`D4>^q2XA\LPpuS7)+.FQnEo';tAZg%t-e$,fI?!2VACtuBN4/jRL\+;RcZ):!mQoP7U\0W\A$Y
	;XYp5XrK[.e]6A)tqVo6e!-Vg-&fKG,k!"aS,'X)_N(t`K\S;6[hGBu0trJ3X]PniRFmqOUAMS>Ug0
	?@HBfGhnO66@Dl$'kBH$",%g6'3i":]Sh/<cMDHQcq*c;S+6)Ne$kek`iXh(6Z0Z0)CJnV[[kESC-M
	,9.ir1;>?TJ2\j=0pdiiJ!C/;WJ&&LYFH.$!!?djm:98L#c8*'iRW+ed7flBP3"_$!>WgT]ET4ZlCE
	Ch@EsSA%VKff7`94=kqOP7!$g"cB,G.Z@k>X3P7(6@%s.?LTUS-9^8t>a:ctOLJEoTf7Z4!q^WHXlb
	nEQes5A9hIg+Bk%6gMdkcnc?U#rbTJbE:dDETQiYB7d-J_#H0g;XZTmHe?j,pJk4nh_&o4Iu_<n#K"
	(YN^P'.=!r'Zd"l%:HnVrdNY=]ZZ,_FU`,Td*'EEH')Xu/.MGKfWkQ(fI+7AY=.8XFt76d&9pipFLm
	RQ8l\jeu7^1P8cgYu$?6M1(V3MT,s5iNJO=Z^cM#O+l?J/%1Tfj>ltD*V8sA%`\or4%VrH<-4AbM6m
	n`T(V"UbIfo.K4Uu-kl],%u.!ebM6lCE8AS3m-M#I.t&("/d'?VcHV,u-q+%<k_6!nM<Or--o,X?+N
	BNKRBgX[)a!0,a/?l@U72J"L#D3/54=1r>VEsXIHCC#f7_gm*2$%7,<P,`!,s!-?7s>'N<\Hl!"0P%
	^KE^2r5q\DJ:PRNg2Gd=Qi'Z.TB'Ma-_hEC)?e[mW-M-/B#X_[5qr:5EinM[dOkgS&WOr181lA)mn&
	Fmq!WH`4P8A:)WA8"G,'jSXa$in%UaG+DIRan@K?P_40XT]=u@D(R<J2ZqG!E(;k.SZLnPrL+BdNnU
	PShPLfl&@/&(l$%0^SD^aXO6)ARtnSYVZP;B[Ns%DMQp!:tn$d8L(4%A&%)h\M9&/l:,n-16sof6&0
	a]A;cP5WBC.99;?L9Mh_ir0<;+F@1"MkO&)$j"cE)[TGd+!cbJq(M^)'3oHn[;QbC37NLasdClN).U
	#$[h@#H1-t(c'$.$8HaU;5//r7'@qrCt8X4AbS)bGDlfjAM`7H?$+(F%*[ntiTeCq4T;n@@PR2p$sX
	a_8@<J0qLPU)o05etnIGT.0/g"H`%5Ij,$Q=5*[$_4JC0bm!V.L';tP?^:\5]-pgr#<`R^AZ(kA4Ss
	mWV'EDun])1XL3e1[1PA"48@m&1ra0fmhG$`EGED-FW)nDHl1oN11r.G'N[jWSHEMN>?O*k^-*Sj;D
	gcddbE7A+K.UU+@.pjOcjZr[PDn2[_:E,h?u)umYQ7c8RUPks1TVWkMUd?F_h3*%84uRqM>(&Bol3M
	_8%%B1FWe&O'1n(PBH8I(`]?j3?l]LR=N?8H=N:a65e%p%3+3g5O#E#fbUQ9@9>,Sas'#h:!ta\>F"
	APtO1!$1iK3mh!2gt`TU(GpPS^^+a;7?Y-rK"m0OK?_A)eqaYpRJgJlXCnoOOY/\K6tN2s>s??QfBX
	Z#k#'lN\:5;K4XG?m:j!#[h$N\'2d.huKp\=3h`TB1-8C.?bC:'n]"b2FSl<^cS:O^/.qOXh1f1b#H
	u]p^2U@Q7<#!&C-@P&)X`AY3MSnKaArJ*'am7C_E`D20#gM;`-ND`)M7O"8Ij$LP*;Hh^3=b7$$q>o
	G=R+:\_"KLP,9$S2%aXY1e/e,*O-O80Dl)";5k6Uo5C!4A9&RkUkPg[;d[7"grf#7>Fnc&8n($\qYf
	Z!*a[WZ:c0"@'g4QJ:ZpSY:4)aB^+MA$V3t,<IsupE?cqfpR!!g6:>uqZ.0X+<gJbOk"F2=V'eUOir
	CuK+[T?7plC4nW5u54*Oc"%Uf'sJ4rlnt+<?;Hq:]u1R=(nEWGB797(n/iGRZ`&"N(1ZI)j/hU)C-"
	l;o>trVJ:=M#uH]^rmj)^W@m%,9hUPOWS;6`hsGXd?(7,C]pt7d+hs)!=jXo":#;gSAO^r]Gf^rBQc
	?`FTC80_=tA4P86l;3hsU/H<f(PM^L[ZQZ*(kWRM%VILT[hCYIQ6*0@!hE5*U:n(lOW]sKX"gq0?-4
	!M0>,-N5t3><01VP&CdV4G9+Gl6R4`T--H/#@,"JVj%e=+D)QE0?C(OoC!qNQ;isMdZP.Muql4-*DU
	Af<;AQHLc\"SNE+XA-!HXjh#sA!pYg]*BH$`@4E[1hb/K/o;6&rBPn:MbUk7_<@H4\R.gW3=QS-<':
	kF6(TRdF`p1BmK%5K#=?W#cWs;jaeUn`JojAE6*]1e"_.He4fGpps/Vf=85<?Fq^3WX)D^!1XjEQ1t
	;"$@U]tApV`5eIjaA:EXZTG7Yk5^GEGVCf*[_d$98"9Z)ajrFH(pV#%^&7ROPUXH)!1(IfeqoLP:WQ
	'6*hqj783B\jCm#G<SrY.RVG%sW"HrI&@Y5F,M;s7#Nr[h&X:32o'`=WUKK3]<)`PIXHKjcnA`5fdb
	'Na[f8aY+^AhE"PZ\^$"Se1U0VWWjo:&Fognn#JAVBt$_Y)U*MT\VJ4<BWtLB3oR<$R<]'<1_h`.sM
	DCSi*T`sM>GK,HaG#^?O`U#UfXF"P2:!>p5CKQJR1/Wr>rn-Ou$6'K(5i"&+[QFJL"+pZ_>JseVoLn
	ii1>M@Ot1:G2_'7j9D/r8ns<;.l)LBsu8(sT=Ci#/?)=b%qtrX5Ino,srp\<VX]08fnr*@Gr^I6i=U
	fcS=&C41m#H-^?/NSZX:qK:s3T)P:pQ^;%9IIQlkSVPGeG0uE"&SJQ:=S2X1@JLps\$XKc$$dVE+(s
	RmO]N-CJdO^cn.A?d71%"k&V)tLjhDq4T-sRt!%(Q^!KmRIRlF.k;+gr_>:+rS9rW?,(_?0QaSs!-r
	JhPAbQ5Xm4]1Z-ES?\S__2ibj2P\tb+j+0(E,87*8hAf:,pUE!qI,NcV5%4'BCf'r3o3LF*tCFn^UO
	Uih(HVr[2I;JOZ'Sdl:)*+]HDf6cYW`(WV<k`,UuL'EC$S0Qq+!D.WIjo.EA&9o*9rZE"%I"R8?>DZ
	G#+JIAFTIU1^3Wp/5dFTj4d<7eSUo=FKkQ@WcjQm>CK"pj^d;!os.4XP+dARTF/$9O.'ImI+6WHLVj
	-W3hM-s0Hqi<1C;[;7)K-7JO*1cl'&'AT1dX@S"07t=2S3Vbc&$32p;4A3`K7rI.?P5-d'm()`\YTn
	Rir<knr$M"T%Crd"h0"V74-)'0mUAkFt%r4M^)n.tVLI(!\Zkq\1OE$03/_#d!]dO&i&:tl5"`X6Kd
	+=X6)bVR1Jpa?Npj&KVU$)k,Y6O*'K"[Ve#TuQ^q1N>B2M(c0PXPkW&*cJ])pI02?u2Dr\d#>7a1bQ
	E5PDKI6fNEBrs]XR#a(/OG[+tU8m[:5l^#*5`qiE%T&ZqB^&X&l`'CbQ.$k$u%Y-ep]dehD7dBMO.g
	QY[(3fmE9-)3U&-RNpSUR.Y`rYs*LhK+u2#TU9<(Ogu!(%geM#')%+4V_Sj[5d07I)8AqFI9"#dtPC
	6`:H2FX3_U.S\Su3dDN6k.f]TgYOl3-rrh&$UD6j6[o]0'4GJp<\(su!8`?k^PR4(77%0Y=$1lZ*ol
	lRFS^Oc42H^cfaUKY$Q0(9J@5IL!>QdM?NpOWM=IW0^k0\)d47j[r"D[<J]n/6(I?LFPs?^J%ML%DE
	`.`uZ?1Z0+JTC_Kp/*5>N1r2(%%+W7oK2Ai(Kl['MtD(f[6c8.2Tf-+lDjA^P>6AY&#VX;HYXQ^nO\
	ICTj0fipdlU<u$l+TeVMe`K1M&q?7T8r.W'U&a(`Q[]Nn!IW;DA"4Zr%/^J5dR9q_aDO^6!T=KB(rW
	OQ"(#UV]>/3C"+iHtbH'\kf'rVYt(]#)B)?.#5>e@ps]or1;DsZ;KIu=BC%It:1Nb!#u"X)-FPaWQE
	=hWh:M$LaNMoIpUf!$%07quE_280*"b?98o$KNETIcXBXCA<R9b#f11ZU)CGJG=XO]@927&aZHL+[Y
	o!Jh76>DV,jC:3s3dO?7-)@GBXgpVQGV5T'XJ+cqZ6c5OW9!WEDAh\BTR0-1!j1L[=(Sj`-4&BdXYJ
	Q+t)MJkNU4+hLFYRQTqZ:0Yjj*^s],g]a/s!)Z>Wg!V*X<8rgOtY=%$-<@TUp)n+d"Jpjcsu`V$WoQ
	::p>8mlG;%\ojHoa4_XNHJ\J6-Cd&!&#7WZ6H;O9bpf7n`_!45/Tti]a[#B-ta?J0p_@5`iO^u\eEM
	E,.a,/AT*@Db5*@K(8NYB[ANY>!hNY=o,#B,lW`'W]EER#,fr&r7^:lfaHJ\7/8-PK8CrVg-S`'-]=
	V^8'`faEmJ":#",N-Vs452C2?kl=0s45">CU=@8l)`oXmkTI`b6NafAcJ=Ui_m!LDj3B]^C[qY][fb
	<[F6l^m%Q5>3f=_>J-e.5#FoXN_SWgcO?!SWDOJfYiW:3-"F,qnM\8EfA>q#m3Hc+Lm3O4DQNo[8/T
	(YnpTW?WQCfa"QJf<$O,G<Z/4M;t8l$,&G`A_]$)%6#GFM7Y;!aW-&<.8%4<OGd0*?%)FF`iE5mA`S
	+j@dNO\[#[=gR>2a5Qua;lopgNg:=+ug^0UUKU7;gJu/qVfFn]19Hq(Og^(_7d<o.srY_U5ED9_6p#
	_,AFbaf2Y,f/%/]c+Jh?d@IB.;hV%DQ"B:*L7$8<gn:&MAj[''Qo&3n<:m0:b29iMNI\*&FX'3rkQ'
	Q=3"ed<A8c<sSfE6_4@0nh0$$\8Fc=(`H:/p6WJO`1I'L@3\&dpcuoif1m:^2R:$\mCK=<k3fc#6Cu
	m@+RFf(9Adedf@gDDZCnCfPb+(3Esq;SS7I%)m&(5AMCp'cfc=(^]u\P&S3<l']WkaB,cA3r&dkZQ[
	'5TVpX2b>J?[$jc?<$dMo")2ld^5;FZJ=@*a<*AI,9LRO3=MF[Y=gUD5`*4Xfc@2g7hRfUop@k@eim
	cN6Wh)YORpgW=QpFZ-PHSV_C=bjT%?n-'*6'mH:KOIT5%gD(G.h/[<:T(WVVsmi*^.B+0WMCV*+#eE
	2E.GpiI8I6Hf>e9_.lMbp??mI@/7k3%ELmZ$Y6b_`fg=4QU2+;DlOi,cT%>rF1^`s_"IU9u"`aM4+X
	\O)g[JR/>&2MasM7&iLi'&Z[irt]V2dNQ9debFIuMk\T&f.K%mEu6&HpQgK[)3LAfE&c8u^KW6158g
	3-Bf=7/TVuTF;&e_,6V)<E<;Z2D?7_,.Lp_Dr-1abRHagF4FJuC=k1<"G()-.<AD]AI+]ou)^I@*Wo
	]/ep4/e]!%W8+R8kEnW>YmiU%g)5\C3G8d5bnV&.WNt-;HNV_k-f,N05Y/#;DQ#*ftB!s2jPO#PQRK
	22?+.Fr7sbUEd:2>Y82(_="S3s/13%R3Bk)>&Ea[(T++)96;@U7)$eaA^&XEhA;0daK!uc^r%/P<XH
	*GQ4^1+0/TI,a37"+#2CdM5X4TXD[5=LD$Tc?MY<m@9Ye)6K(KU:4%ItGVjLV&1S[[dJ,B4bDWQA^H
	FWPVY*U'E[qjs06$=\q6ccFf@]&cK!lG4fL4a8ZbHI1rnCh!'F0WZ>&H>js,%pD+%=?Y:TX<+`pn6"
	_h+3a'cWg.9@rWcI3-4j>Hq;/&'oRHTZqYW2`NY?mR-WIZgB@5QVHb+A3&&"@7!<*mr1UmZ-!p3S)E
	)ZT!>6>$@(/LIP*iT#ta\ca1o+^3Q+u4>dZnY$Qo!1j7`*(]B-prM9<Zh[%HfFE[^Y%n5%NI`9I)i=
	+3[U1BiD>W&)@$]u6R4#>LCeaY$-AoAkB?\4Y"c'KMC-Vp"N9]IbpuIo>C((!X2\gDcUh(+_T4lqjE
	2`^M<$sS"L&8!%#Kn-Kh-[/dMLk?XlWP[I*J#1#MF2XkqT1h5Fh1L!q<fIL.Uk;?ljj-+_ioVq<Ie]
	a&EaKQo0r?#a<D'eF5>b3^')Ec!*#5em'KsD=V#U0'-L%ROMa0?BiWdJaTTtHRnW7&3hqN+aX@)A*p
	X-bDc<HE?j#i]A,s9<#B3a'u<DoOcesZ0kRD!5KW+LBhHDW+r?I.8s"Z+l-[q5g]2!f.n!pA,%'`fU
	&87j%.rN*l.;K0[<`",@/q;Ji/R$E^6b:qhis9QPO`IZ>n]eX5D!.K"5X:Ees@aIrQh-beoOjULgj0
	XY5n73HV#i.)@oGT"F(0eMn[9UMoS&IeFd?cfr0:(>B^IJD\5NYJm$`iPraHaLu?n!khe$7s4kWF[g
	?;&kCtU3EV3n:*X:V%"M8d.&og29Xb8>7APlH=TB.EWSO'CtC>3aY7@O#!^2X:j1b/'YU>4M&:gSEf
	T/IZMIDkrWrtq.d>AOt[&h.$AiTW)oa#7j(DS^5hB:*&7Nf*$N?_6cB?Z6:&#d5]udG@rN#g!^BQaZ
	b&IK0H7HX$)^So1QjY:.)h%hSaK`&-sOaqaU$(/9*5]`ZA?9$0U<f%/Ed:7um0hW,p\IGD__YMJ_Be
	e83,8K<L%7M?J1S95p1+(VUs3bAu^?V&i7lrHs_eqh%\HJ]7FdJ*Z4TFK"GbL^(-RaCf'Pn=]54b:g
	bT)<^/K4=sO"C!FCUP#/%k3%G#mZJCt+Lf1ZWYOUOr!k)J4)B]I(5p.@Yum$%X<)2<eUnWq-(A""BX
	(Yj(5q9FU\M:'!VF%DY`9Ci]Vi/em@!q1$e*_2m;nerJ4O&)Qd,R2&JRf)5u]kc)F3R.-U(d:IS+f*
	%*&[qco':lX9`"=pOq44;#!BXd\>b)Yc(9OcG)C[lcnDq1XC\Oir_;:O@hptFaS\mar06/AY1lTAA6
	O!kK[sR-%20j`sJk3X9k@V:)$EmrC[/e1j5Apo?Ob)NdWFQf9lr@oG^$`">:HP/VW4QRPpTo:5%.&[
	;p4+-NF.LX85k>51.u&G/fOU*?.%73)9Wi$NnEU.c.pXb,nfd"Y#m"lb7e6M=VVp':98dh6V:iUrmN
	G;bt/JdlVp!R1/QmAr[OT,O/pBVV^kSdlrX:c>*rIh@/c^$K=%m7O!%./,a?YmsT.Iju`OQmHpi>Z(
	cp3"L@/L@60(8dtW?VCL.t0ET2nAr>s0*GRa`7b0glg;!Egf*@J4_QWmIr0N6!u!%;h[,1-mGh6]Y$
	;6=r1&G^[kcuB,?>W$Xl@>oY"-_rAjAel@6A>+h%]&NpT#`u+Ak&ek^j$^+EHR88VS@r.uM\S$iS8]
	+$'90^^KFF>)r(P?8NY>6I(/B0rD>bQZ./e<2M"<D'$V_Wh[*nC%n]rctnFBf&+EpY\Y\ijs$-*@;7
	E5`'V3`OCYcVW5U!lM<6H1C'a>J%/ODU_2c_>F*(hY??3cj@bo_a%:]l/?VE1A%Wb2451h3rWLB]-D
	60\YjiZTC^B^B-DHdo=9+-pE;+.gL8,-sF2RC&_mtB*6ce/baY*mbIMdquFjfn!i59G`@T)XtLg-/3
	CbX==crV-1d[64j/Td0a0t[#(Q.DGqGgOIT>X7.hCD0//F/_@^-p)=?W#cWs:3l9C&j/csj7^//HD@
	M05>%Jp!SC(g+fblSt#$XQ)]&XQ+tVSCiU>S?S"eJ9@Aq%G#OYpi)`_DD-s#Pi>9@57_3AJM/0.!p=
	5e"'?%'\Yo.)qH4)HpCatK!"$<BF_C6JG#ib#'B#.Xl9k?/'"N'Xl'O[UN.mD5@QFAY^27JEp14SeX
	3p]FZPASVekI+Tr8AQ``F?)S//F/oK.UR*TZ(B^$<@[@//F/_@QBUVNYB[BNY<1d-(A#W$&cc3Yum$
	6No*2Y&U(/\/VA'b&<W"`pMc,q.+ff\rV_%in=L9WDPP9S!GE)<G]dlDRCi07q_Gr?[Bc:h,'^>%Fm
	*sp3,#Q:RgaE%7nE;;+MNTMLP&b5Y;s#9.u.nV(5p.@YuiOWp?P#%4D=Cq!ilPX(/$QiHI--+==b62
	OUcH/<!4iTCiorq@g)qsPP?cHbN\fV:[RcB*no5l13#=];Q)c*r&/6e-!O.fY>Oh0HWej-3CYHcmjO
	E-7c51A^+AOOni*E?U:i*mYuiOmbMhXZ]eBe$l.j[+']prtaFb&*45AjV]Wb:uRT/'Zg!\YPm6h$-#
	e:S`R$p0T*aHI^s49fsK%<@#`ZaV;-nJKQ,Se&4@QB1AY1W^WqA^"g^Z#2#YZ"3iiRN!>mljE4ZWJa
	oMoB/YcdKA!j3g-[FfP`JWs:3l9=D'Ncsj7^//HEkcM@c`W>+9g!dPFcVZf`QIJ=>;o@$W5qI#ef]q
	5?'4Fm5,Dsq"bUUonMN^(:"<d0Kj5[8.O!fh3@\-[!lgI[lXVG,!HPB],gd^1$M9>DAu_SN%tdp\`W
	FthEN/9A(c\9&^O%<9fiC-$7PXeqYRi)"W6WYbelPmdkU!""`5X`i$o01_tF&?0J;HWIc9ceH3B+7V
	\AUN:]cg3qsch0pf_<RR6XI>3#?&85"sL*]&)T%F&6c&Cn*?Yur!b;HW`d:l0J^Th4hiAbiY!.]8Dl
	5N2=.@$FX;cQ![]97YLdY54&`58WHnc^hP3VZKPq8Gdc5%V%'-Tq=^RrA8FMauK>HmE`\:"$s'HqG*
	?I<A6.pnq'4\NRip*'g*`S_RQ9dM>DQ009TZ^M0`tlh0&2!WW3;(k#6Q5lefW4pV,g7KjP506<u/$-
	Bp#iWOeJ@W;GLJC2:6s">fBouiimFkM(4-#mS>To22R/j;>ij>2"=4$4mL'")Ea?V$a#XY675rBd=D
	6+K].ib.meT[g#O[@=S)+Zh6S!T]k`18sN+\5)Jdofk4@QW'CB\L!8<!!!"O5p)m5!Z2"8+92BYAa5
	ITQ)h7SoBt!bjJn,":OKfB@CT]7mJ^1f.P@ler/XQ5imQuGSe(bgNKYHq.rm5lclOCtP6H/7:&-S-6
	jOL0qW1G\\EpimpCO#iVk]pG\(`elCl'SZ!!)41N&s9gl.EUpn$lTj\00Hp27-M?;8UW`Ae.r9qU;?
	@obgP,GF\)gI\FGrnsiB3ZQYK]`FNJ6qAEn]_e#\+gWhqWB9YZS:aM=AN6^/7F4WdB9)G0N=$d9UpZ
	tYoO:2*h?r6'>oK`KG'7CDl!/s5bc/6i@qoi>19D<P!PO*K=Q,T:CkM1Aod?eLq*I=\7dCDT@h_j*,
	KSP'1HK*NeSN']_hPIcG`XUm*U;6-0WgX5i*D6<Fmr1]#OC)TI[o^;m'0S#%L\dWG&3eHEIGtDf2tM
	3$!!)RX,45I,-<8OO<-PM=Jn1o.I8KJ9I1**"#A4#&(B.*2=n\'.VmK7G=RZVG]$7'e,m?3&(XSUDI
	O[$e.dN"a33[COER$WI7:LT+KH$XVX6$AHpS/t65lXZP.,Ph>1]RN+6)+t=#6DJ]oK`HW0Ntk0)q'n
	`<PQ1\9MmE;,_F!*a1hMcRtC>o6'QUG*JG$=CN73J/;k03O%n9$N@[g)"Y5uLg,lTi/_S2@+.:m,W=
	=&iMB`l:!4]<9^%aHAP?+ie.dO.H1Q^M_dYB+PEG$0j(F;-gGpK`<E_RS:MkS28[D"<[:EP(6l'YuX
	HNE2qlW<Nlhq`]hNSNYhWpFs-RROY5[<_:KRIT>\!!()eoYFs%*s@H(I1QAY'T2b,VFGe,F(r]S8WE
	k$2DBKf19GCFVe`nW9g8@R[us=F7CTib5Ea>NfaqLOjCc_hojst29a;d!+[Vi0rHrT/MY)i[?gKeV:
	nMZSFNM;:&Ie^?>Zi4Vp_pG:lgO;"JdKar_(&$',o,E<Ddt'mW2/*eT/N2U#>Nbr7?(:bI?TSA5[g.
	qE-k/P:Y5'Ym14@8`PF1KT'J#pg<[`(!!"]Vcj,>\4pVi5qB,b<-mYd\p*N?A8G:'"eV$9^bDR&1jR
	ango.r\:2J^]a,&*N>[g_Y9;0,;V"1(M@qk>IJ=VN9#mol6+2\mb@!6A[*0R<oC2DfO-O$!#t9_0Q[
	1%%0!L=qV#jj>))`gupSbEaFjj,O4LA=]jDhV_8<<77!3NaJ+JpJ.j*^FRpH!!!"RJj/rnd0G5s66?
	=1!!O[:bk..4o;kSVPOFhP`>rZ'=>k33dA-&\me1j:g?,]O/mYA`\SgcSc1R'<T5Qg,6\I]j]70F5n
	`F"#l"8U[bI0!gZ#:^h4-/80!<A4:R%tgW5MGA\:\JUMe0A0UbVO[$,Vn&59Mi=kfS0QBisl0!jNUl
	:H#+g$XE4,iQ_4+Wak!h:>1/Z4A,lT0_hUE8..ffuaNt.m!'m6hHH"0e7!.QM?-sQ^+.!\]SS>Gb=d
	ppghjD.9733WU$JXp$gIogkA\[;g59srX^Z-rg*pP3=g;H@3!!)(-hCptr],E5ig2Ki_"nj66#:30d
	SLKV1ANF9dYVHf%)S%g5'FB!,=E%p65&Yu#aNX@;$-Jj]GqK'sJ71nhr0?Ju5V\uD!W[`P`o=r6`8U
	nr<*5Xj!+9p/WOP7k.s5*<fBZqIHhWp)<AI:7<2nl+9C##&r@kIoRel<5cb8njf=KuP"<]Yg3bpr,f
	omc5>^gGN>f#^C)]-2Vqd][,!$d%Y2urdt:o*<-!!&\=V4*mKc6)LmTC^SLSpTeu:MStaE><]tqc+i
	(rI$RPSXWf4G?_)X3Jom0J<;^)g#fP:&3M*"%s6LN7R&EVf%*PgG/o^S!!!F&,45H+b-$KcS'o$^`p
	KfXb5TK,s$X$EAOTZ5?*[PUHtVAoB9-k6e93\:6i_8iRT5DC<H%B9P$^B!\X@n#VIob@j>n(W!5ODb
	&,lWY&1D#[5l^m]9Qi9q<q=9,(#/G,j@RI+86-XQXuqi3WRWP58n@e4RG)c/q7$M-a8pM./:[TCaF2
	nF^CZ=ICgWI42us"E^>fZtmmH9!s68OeRm6dbGA4G1AL@Q.#;tFD'aiB/8P`N'lg(TI5QBVV=.Y=3&
	:iQ([;9oPB>XsbqLYMNJ1inpH8tA+C[X<TlYHP$!4b?:U^mOGMEV:G!/f5Y(+1a&0b7BV\:hg-TLc=
	I!<>An.-<9@/1.K(=&kQh\ipDt/+38.V!>HGN<iIL\c'>"T*Qq[Y8g]Wn@W9QG:Wa)<PN#/(HmZ,8K
	.)814e,l7lN&<io^CD!%8'D5lelW4pV,gMHsNJp*gbg5KDd%cPIre/S^2*&:iQHB%:BiKAQ+PP(.eN
	F#2QJ<AS&l9<o_3j(JDmi&rQu+u<\G9("7t51adqA=:2Of4Q?^O#tgp1&G$24abeb\,X-Qf:"mPnIH
	>3)9]Ko(Wj-Yp1_VRqYt&tVeo2`epDYj'EA+].eH",KoS>&!!$u[m"O1ec;\CnMVLB7R*ThT?/1igj
	LD!u/[XurO*u@^F#'/?3tQqtRC-jP=eCBYb-XJ;YLoEP4oDE,S*rP*lYHP$i4\0*d:&>7HEa/clg7R
	1NKS1GX'0+H=86?Q*\s(p=/PS0q[YJu8o7hg*-Wk4n[a%ccAF;j?Qj-_jM*f?(eRCk/qr89ei1YLUN
	SM*@u:Qm!"^[W+FldH*s;QD\/^D?!/_)@'*&"HQ;M\MC36IoI/MSACN0#D8ZI"1A<S>!c?0;QUphVG
	bk.MnBt.s69RHHI(+ng03uEMCc!7f%@Q'djeUo!H^eP):cRK@I4fSf49oI4g'A86Z%R2l?FPL""!!)
	QjI1SZ;TFV)(!*gD"'*&@[M\?'j'HV-/*GNW+0_9\ZZtrdP8bNIWImiiH,b(P's8=`c3[*)U"aXJF4
	WaIVeoaVa1.iVg!!!!-$%3?b!!!"V!fI]l$5&10!!!_1;,U:!6[eO)Epn6c7c8Hl'O;NCh/'6T\9+j
	KMVP#sDCIPQk54!-R`c3Gfoj6Q'2BN]8LDosaT);@!!'taJ,5fY0GAjGz7L4nc!"&mf'*&"H->jZ[a
	\BmJV&)4RO8#kf>`e?BkSDreOaU?/)dKsTmZSn*XZW&K9qIO6%7pfKm&,u?(<JTgX`K=QHg^B5p\#*
	?2Zs*\!!!iMqB,b<!!!]m(+0(^!!))Z\-iTqZ.TMo-VdZa-)sS;'AXIN'8b0,.M&h-1=^Y.RV&j/2k
	M3ofqgp,$H[VTmP9!3d-7FVk2,N<a$L0g/?E[2B$R3Qd\WA7M3XKT[:Ykka\9q9.f]PL!9!n(#6=f)
	!2+l(cf,'8KE(uP!4ZGOzz!!#J.M\?'j!!)#u%ANn'zzOBX82zzzzzzzzzzzzzzzzzzzzzzzzzzzz!
	!'t'If\u!=n1112MD,2!!#SZ:.26O@"J
	ASCII85End
End

#ENDIF