#pragma rtGlobals=3		// Use modern global access method and strict wave access

// This function requires Global_Utils.ipf maintained by <herndon@aerodyne.com>

// These defined constants are the index offsets direct in the file
	Constant SPB_FileFormat = 0
	Constant SPB_GlobalHeaderLines = 1
	Constant SPB_DataHeaderLines = 2
	Constant SPB_SpectrumLength = 3

	// And in Version 2+
	Constant SPB_nSpeciesUsed = 4
	Constant SPB_nLasersUsed = 5

	// These defined constants are the index offsets WITHIN a 'spectrum-element'
	Constant SPB_TS_ms_pos = 0
	Constant SPB_Duration_pos = 1
	Constant SPB_Pressure_pos = 2
	Constant SPB_Temperature_pos = 3
	Constant SPB_PRef_pos = 4
	Constant SPB_TRef_pos = 5

	Constant SPB_NumPeakPosn = 16
	Constant SPB_NumLineWid = 4

Function SPB_ParseInputFile( w,  [workingDF])
	Wave w
	String workingDF
	// w is the loaded binary file parsed with each element in the wave as the double precision data value using little endian byte ordering
	
	String loc_workFolder = "SPB_Folder"
	if( !ParamIsDefault( workingDF ) )
		loc_workFolder = workingDF
	endif
	String knownVersions = "1;2;3;"	// "2" added 11/2010
	// "3" added 5/2018
												
	Variable/G verNum = w[ SPB_FileFormat ];			Variable/G globHeader = w[SPB_GlobalHeaderLines ]
	Variable/G dataHeader = w[SPB_DataHeaderLines ];	Variable/G dataSPEPnts = w[SPB_SpectrumLength ]
	
	String saveFolder = MakeAndOrSetDF( loc_workFolder )
	// operating in the hardwired root:SPB_Folder to hardwired nameset
	Variable/G linesInFile = numpnts( w )
	Variable/G dataLines = linesInFile - globHeader
	Variable/G perSPE = dataHeader + dataSPEPnts
	Variable/G probable_spectrum_count = dataLines / perSPE
	Variable/G nSpecies 
	Variable/G nLasers
	
	// poor effort to verify that probable_spectrum_count is an integer
	if( round( probable_spectrum_count ) != probable_spectrum_count )
		printf "Division indicates %f spectra?\rContinuing despite disparity\r", probable_spectrum_count
	endif
	
	// error checking to verify that version is in the knownVersions list
	if( WhichListItem( num2str( verNum ), knownVersions ) == -1 )
		printf "Version %f not in known list -- change knownVersions string to force in SPB_BasicParseInputFile\raborting\r", verNum
		return -1
	endif
	
	Variable use_nSpecies, use_nLasers
	Variable offset2PeakPos, offset2LineWidth, offset2TRScaleFactor
	
	switch( verNum )
		case 1:
			use_nSpecies = 16; nSpecies = use_nSpecies
			use_nLasers = 4; nLasers = use_nLasers
			offset2PeakPos = 4;											// this is the within each SPE offset
			offset2LineWidth = offset2PeakPos + use_nSpecies;		// the offset with each SPE
			offset2TRScaleFactor = 0;
			break;
		case 2:
			use_nSpecies = w[ SPB_nSpeciesUsed ];
			nSpecies = use_nSpecies
			use_nLasers = w[ SPB_nLasersUsed ];
			nLasers = use_nLasers	
			offset2PeakPos = 6;											// this is the within each SPE offset
			offset2LineWidth = offset2PeakPos + use_nSpecies;		// the offset with each SPE
			offset2TRScaleFactor = 0
			break;
		case 3:
			use_nSpecies = w[ SPB_nSpeciesUsed ];
			nSpecies = use_nSpecies
			use_nLasers = w[ SPB_nLasersUsed ];
			nLasers = use_nLasers	
			offset2PeakPos 			= 6;											// this is the within each SPE offset
			offset2LineWidth 		= offset2PeakPos + use_nSpecies;		// the offset with each SPE
			offset2TRScaleFactor 	= offset2PeakPos + use_nSpecies + nLasers;		// the offset with each SPE

			break;
	endswitch;
	
	// Changes to this nameset will need to be updated in Function named SPB_ReferenceTemplateFunction
	Make/D/O/N=( probable_spectrum_count, dataSPEPnts ) SPB_Data_Spectrum_matrix
	Make/D/O/N=( probable_spectrum_count ) SPB_TimeStamp_ms, SPB_TimeStamp, SPB_TimeDuration, SPB_Pressure, SPB_Temperature
	Make/D/O/N=( probable_spectrum_count ) SPB_PresRef, SPB_TempRef
	Make/D/O/N=( probable_spectrum_count , use_nSpecies )SPB_PeakPosition
	Make/D/O/N=( probable_spectrum_count , use_nLasers )SPB_Linewidth
	Make/D/O/N=( probable_spectrum_count , use_nLasers )SPB_TuneRateScaleFactor
	
	switch( verNum )
		case 1:
			// file format 1, the original
			SPB_PresRef = 				-1;
			SPB_TempRef =	 			-1;
			SPB_TuneRateScaleFactor = 1	; // This sets the ScaleFactor to 1.0 for version 1 loads ...	
			break;		
		case 2:
			// when we need it
			SPB_PresRef = 				w[ globHeader + p * perSPE + SPB_PRef_pos ]
			SPB_TempRef =	 			w[ globHeader + p * perSPE + SPB_TRef_pos ]
			SPB_TuneRateScaleFactor = 1	; // This sets the ScaleFactor to 1.0 for version 2 loads ...	
			break;
			
		case 3:
			SPB_PresRef = 				w[ globHeader + p * perSPE + SPB_PRef_pos ]
			SPB_TempRef =	 			w[ globHeader + p * perSPE + SPB_TRef_pos ]
			Variable offset_to_trsf = globHeader + 0 * perSPE + offset2TRScaleFactor + 0;
			 
			SPB_TuneRateScaleFactor = w[ globHeader + p * perSPE + offset2TRScaleFactor + q ];
			break;	
	endswitch
	// this is version independent
	// right handside nomenclature: p is point number of the first dimension, q is point number of second dimension
	SPB_Data_Spectrum_matrix =	w[ globHeader + p * perSPE + dataHeader + q ]
	Variable/G StartDataSpectrumMatrixOffset = globHeader
	SPB_TimeStamp_ms = 			w[ globHeader + p * perSPE + SPB_TS_ms_pos ]
	SPB_TimeDuration = 			w[ globHeader + p * perSPE + SPB_Duration_pos ]
	SPB_Pressure = 				w[ globHeader + p * perSPE + SPB_Pressure_pos ]
	SPB_Temperature = 			w[ globHeader + p * perSPE + SPB_Temperature_pos ]
	SPB_PeakPosition = 			w[ globHeader + p * perSPE + offset2PeakPos +  q ]
	SPB_Linewidth = 				w[ globHeader + p * perSPE + offset2LineWidth + q ]



	SPB_TimeStamp = SPB_TimeStamp_ms / 1000;  
	SetScale/P y, 0, 0, "dat", SPB_TimeStamp; 		// this reminds igor to consider the y_th data part in units of 1/1/1904 11:59:59 styling

	// reset folder to original point
	SetDataFolder $saveFolder
	if( ParamIsDefault( workingDF ) )
		SPB_ReferenceTemplateFunction() // If it failes here, nothing will work later - this is only a test that all wave references are legit
	endif
End


Function SPB_GraftNewDataOntoInputBinary( input_w, SPB_AlterScript )
	Wave input_w
	FUNCREF SPB_AlterScript_Proto SPB_AlterScript
	//
	// input_w is the loaded binary file parsed with each element in the wave as the double precision data value using little endian byte ordering
	// new_data_w is the same product geometry of the
	// resulting parse wave -> SPB_Data_Spectrum_Matrix
	Variable debug_on = 1
	
	String saveFolder = MakeAndOrSetDF( "SPB_GraftFolder" )
	
	if( debug_on )
		Duplicate/O input_w, debug_original
	endif
	
	SPB_ParseInputFile( input_w, workingDF="SPB_GraftFolder" );
	SPB_AlterScript()
	
	Wave SPB_Data_Spectrum_matrix = root:SPB_GraftFolder:SPB_Data_Spectrum_matrix
	Wave SPB_TimeStamp_ms = root:SPB_GraftFolder:SPB_TimeStamp_ms
	Wave SPB_TimeStamp = root:SPB_GraftFolder:SPB_TimeStamp
	Wave SPB_TimeDuration = root:SPB_GraftFolder:SPB_TimeDuration
	Wave SPB_Pressure = root:SPB_GraftFolder:SPB_Pressure
	Wave SPB_Temperature = root:SPB_GraftFolder:SPB_Temperature
	Wave SPB_PresRef = root:SPB_GraftFolder:SPB_PresRef
	Wave SPB_TempRef = root:SPB_GraftFolder:SPB_TempRef
	Wave SPB_PeakPosition = root:SPB_GraftFolder:SPB_PeakPosition
	Wave SPB_Linewidth = root:SPB_GraftFolder:SPB_Linewidth
	Wave SPB_TuneRateScaleFactor = root:SPB_GraftFolder:SPB_TuneRateScaleFactor
	
	NVAR linesInFile = root:SPB_GraftFolder:linesInFile
	NVAR dataLines = root:SPB_GraftFolder:dataLines
	NVAR perSPE = root:SPB_GraftFolder:perSPE
	NVAR probable_spectrum_count = root:SPB_GraftFolder:probable_Spectrum_count
	NVAR nSpecies = root:SPB_GraftFolder:nSpecies
	NVAR nLasers = root:SPB_GraftFolder:nLasers
	
	NVAR verNum
	NVAR globHeader
	NVAR dataHeader
	NVAR dataSPEPnts
	NVAR perSPE
	
	Variable use_nSpecies, use_nLasers
	Variable offset2PeakPos, offset2LineWidth, offset2TRScaleFactor
	
	Variable local_version = input_w[ SPB_FileFormat ];
	switch( local_version )																	// This forces all written spectra up to file format 3!! Scott's decision 7/2018
		case 2:
			use_nSpecies = input_w[ SPB_nSpeciesUsed ];
			nSpecies = use_nSpecies
			use_nLasers = input_w[ SPB_nLasersUsed ];
			nLasers = use_nLasers	
			offset2PeakPos = 6;											// this is the within each SPE offset
			offset2LineWidth = offset2PeakPos + use_nSpecies;		// the offset with each SPE
			offset2TRScaleFactor = 0
		case 3:
			use_nSpecies = input_w[ SPB_nSpeciesUsed ];
			nSpecies = use_nSpecies
			use_nLasers = input_w[ SPB_nLasersUsed ];
			nLasers = use_nLasers	
			offset2PeakPos 			= 6;											// this is the within each SPE offset
			offset2LineWidth 		= offset2PeakPos + use_nSpecies;		// the offset with each SPE
			offset2TRScaleFactor 	= offset2PeakPos + use_nSpecies + nLasers;		// the offset with each SPE

			break;
	endswitch;

	
	// lay in the SPB_Data_Spectrum_matrix
	Variable idex, jdex, dsm_offset
	Variable row = DimSize( SPB_Data_Spectrum_matrix, 0 )
	Variable col = DimSize( SPB_Data_Spectrum_matrix, 1 )
	

	for( idex = 0; idex < row; idex += 1 )
		for( jdex = 0; jdex < col; jdex += 1 )
			dsm_offset = globHeader + idex * perSPE + dataHeader + jdex;		
			input_w[ dsm_offset ] = SPB_Data_Spectrum_matrix[ idex ] [ jdex ];		// note this is referenced to the Grafted directory!
		endfor
	endfor

	// parse reference 1-D entities	
	//			SPB_PresRef = 				w[ globHeader + p * perSPE + SPB_PRef_pos ]
	//			SPB_TempRef =	 			w[ globHeader + p * perSPE + SPB_TRef_pos ]
	//		// this is version independent
	//			// right handside nomenclature: p is point number of the first dimension, q is point number of second dimension
	//			SPB_Data_Spectrum_matrix =	w[ globHeader + p * perSPE + dataHeader + q ]
	//			SPB_TimeStamp_ms = 			w[ globHeader + p * perSPE + SPB_TS_ms_pos ]
	//			SPB_TimeDuration = 			w[ globHeader + p * perSPE + SPB_Duration_pos ]
	//			SPB_Pressure = 				w[ globHeader + p * perSPE + SPB_Pressure_pos ]
	//			SPB_Temperature = 			w[ globHeader + p * perSPE + SPB_Temperature_pos ]
	// lay in the single DIMS
	
	//{ SPB_TimeStamp_ms, SPB_TimeStamp, SPB_TimeDuration, SPB_Pressure, SPB_Temperature, SPB_PresRef, SPB_TempRef }
	for( idex = 0; idex < row; idex += 1 )
		dsm_offset = globHeader + idex * perSPE;		
		input_w[ dsm_offset + SPB_PRef_pos				] = SPB_PresRef[ idex ];
		input_w[ dsm_offset + SPB_TRef_pos				] = SPB_TempRef[ idex ];
		input_w[ dsm_offset + SPB_TS_ms_pos				] = SPB_TimeStamp_ms[ idex ];
		input_w[ dsm_offset + SPB_Duration_pos			] = SPB_TimeDuration[ idex ];
		input_w[ dsm_offset + SPB_Pressure_pos			] = SPB_Pressure[ idex ];
		input_w[ dsm_offset + SPB_Temperature_pos		] = SPB_Temperature[ idex ];
	endfor

	//			SPB_PeakPosition = 			w[ globHeader + p * perSPE + offset2PeakPos +  q ]
	//			SPB_Linewidth = 				w[ globHeader + p * perSPE + offset2LineWidth + q ]
	//			SPB_TuneRateScaleFactor = w[ globHeader + p * perSPE + offset2TRScaleFactor + q ];
	Variable offset_to_trsf = globHeader + 0 * perSPE + offset2TRScaleFactor + 0;

	for( idex = 0; idex < row; idex += 1 )

		for( jdex = 0; jdex < nSpecies; jdex += 1 )
			dsm_offset = globHeader + idex * perSPE + jdex;		
			input_w[ dsm_offset + offset2PeakPos ] = SPB_PeakPosition[ idex ] [ jdex ];
		endfor

		for( jdex = 0; jdex < nLasers; jdex += 1 )
			dsm_offset = globHeader + idex * perSPE + jdex;		
			input_w[ dsm_offset + offset2LineWidth ] = SPB_Linewidth[ idex ] [ jdex ];	
			if( local_version >= 3 )
				input_w[ dsm_offset + offset2TRScaleFactor ] = SPB_TuneRateScaleFactor[ idex ] [ jdex ];
			endif
		endfor
	endfor


	if( debug_on )
		Duplicate/O input_w, debug_modified
	endif
	// use_nSpecies
	
	
	// reset folder to original point
	SetDataFolder $saveFolder
End
Function SPB_GraftNewDataOntoInputFile( this_spb, new_spb, AlterScript )
	String this_spb
	String new_spb
	FUNCREF  SPB_AlterScript_Proto  AlterScript
	
	GBLoadWave /B=1 /T={4,4} /N=BinLoad /Q this_spb
	Wave input_w = BinLoad0; 
	Duplicate/O input_w, SPB_PreGraft
	SPB_GraftNewDataOntoInputBinary( input_w, AlterScript )
	Duplicate/O input_w, SPB_PostGraft, SPB_GraftDelta	
	SPB_GraftDelta = SPB_PostGraft - SPB_PreGraft

	DoWindow SPB_GraftResultTable
	if( V_Flag != 1 )
		Edit/K=1 SPB_PreGraft, SPB_PostGraft, SPB_GraftDelta as "SPB_GraftResultTable"
		DoWindow/C SPB_GraftResultTable
	endif

	
	Variable refNum
	Open/Z refNum as new_spb
	if( V_Flag != 0 )
		print "Error trying to write - ", new_spb
	endif
	FBinWrite/B=3 /F=0 refNum, input_w
	Close refNum
	
End

Function SPB_ECLStartStopNewBGFile( index, this_spb, new_spb )
	Variable index
	String this_spb
	String new_spb
	//FUNCREF  SPB_AlterScript_Proto  AlterScript
	
	GBLoadWave /B=1 /T={4,4} /N=BinLoad /Q this_spb
	Wave input_w = BinLoad0; 
	//Duplicate/O input_w, SPB_PreGraft
	//SPB_GraftNewDataOntoInputBinary( input_w, AlterScript )
	//Duplicate/O input_w, SPB_PostGraft, SPB_GraftDelta	
	//SPB_GraftDelta = SPB_PostGraft - SPB_PreGraft
	//DoWindow SPB_GraftResultTable
	//if( V_Flag != 1 )
	//Edit/K=1 SPB_PreGraft, SPB_PostGraft, SPB_GraftDelta as "SPB_GraftResultTable"
	//DoWindow/C SPB_GraftResultTable
	//endif

	String src_str, dest_str
	// The steps are:
	// display debug msg wave
	// build references to:
	// last load spe/spb & the mandated ECL index
	// start a new output_w
	// copy over the header but zero out n_spe
	// loop over last load checking each time against ecl-s-s
	// if include, append to output_w and increment
	// if n_spe > 0, write
	SVAR workingDF = root:gs_ECL_WorkFolder
	String sf = GetDataFolder(1); SetDataFolder $("root:" + workingDF )
	// display debug msg wave
	DoWindow SPB_ECL_FilterDiagWin
	if( V_Flag != 1 )
		Make/N=16/O/T SPB_ECL_FilterDiagnostic
		Edit as "SPB_ECL_FilterDiagWin"
		DoWindow/C SPB_ECL_FilterDiagWin
		AppendToTable SPB_ECL_FilterDiagnostic
	endif
	Wave/T SPB_ECL_FilterDiagnostic
	// build references to:
	// last load spe/spb & the mandated ECL index
	sprintf src_str, "ECL_%d_StartTime", index
	Wave/Z ECL_Start_w = $( src_str )
	if( WaveExists( ECL_Start_w ) != 1 )
		printf "Error referencing %s.  Aborting\r", src_str
		return -1
	endif
	sprintf src_str, "ECL_%d_StopTime", index
	Wave/Z ECL_Stop_w = $( src_str )
	if( WaveExists( ECL_Start_w ) != 1 )
		printf "Error referencing %s.  Aborting\r", src_str
		return -1
	endif
	
	// now parse and populate
	SPB_ParseInputFile( input_w ); SetDataFolder $("root:" + workingDF )
												
	Variable/G verNum = input_w[ SPB_FileFormat ];			
	Variable/G globHeader = input_w[SPB_GlobalHeaderLines ]
	Variable/G dataHeader = input_w[SPB_DataHeaderLines ];	
	Variable/G dataSPEPnts = input_w[SPB_SpectrumLength ]
	
	// operating in the hardwired root:SPB_Folder to hardwired nameset
	Variable/G linesInFile = numpnts( input_w )
	Variable/G dataLines = linesInFile - globHeader
	Variable/G perSPE = dataHeader + dataSPEPnts
	Variable/G probable_spectrum_count = dataLines / perSPE
	Variable/G nSpecies 
	Variable/G nLasers
	
	Variable use_nSpecies, use_nLasers
	Variable offset2PeakPos, offset2LineWidth, offset2TRScaleFactor
	use_nSpecies = input_w[ SPB_nSpeciesUsed ];
	nSpecies = use_nSpecies
	use_nLasers = input_w[ SPB_nLasersUsed ];
	nLasers = use_nLasers	
	offset2PeakPos 			= 6;											// this is the within each SPE offset
	offset2LineWidth 		= offset2PeakPos + use_nSpecies;		// the offset with each SPE
	offset2TRScaleFactor 	= offset2PeakPos + use_nSpecies + nLasers;		// the offset with each SPE

	
	Wave SPB_Data_Spectrum_matrix = root:SPB_Folder:SPB_Data_Spectrum_matrix
	Wave SPB_TimeStamp_ms = root:SPB_Folder:SPB_TimeStamp_ms
	Wave SPB_TimeStamp = root:SPB_Folder:SPB_TimeStamp
	Wave SPB_TimeDuration = root:SPB_Folder:SPB_TimeDuration
	Wave SPB_Pressure = root:SPB_Folder:SPB_Pressure
	Wave SPB_Temperature = root:SPB_Folder:SPB_Temperature
	Wave SPB_PresRef = root:SPB_Folder:SPB_PresRef
	Wave SPB_TempRef = root:SPB_Folder:SPB_TempRef
	Wave SPB_PeakPosition = root:SPB_Folder:SPB_PeakPosition
	Wave SPB_Linewidth = root:SPB_Folder:SPB_Linewidth
	Wave SPB_TuneRateScaleFactor = root:SPB_Folder:SPB_TuneRateScaleFactor
		
	// start a new final output_w
	Duplicate/O input_w, SPB_ECLFiltered		//		<<<<<<<<<<<< This is the target
	// copy over the header but zero out n_spe
	Redimension/N=(globHeader)  SPB_ECLFiltered;

	// loop over last load checking each time against ecl-s-s
	Variable idex, count = numpnts( SPB_TimeStamp ), edex, ecount = numpnts( ECL_Start_w ), fdex, curlen;
	Variable jdex, jcount, first_keeper;
	
	///////////// loop over start stops
	///////////// 	for each start/stop pair, loop over all times
	///////////// 		accumulate in miniSPE
	///////////// 	average miniSPE		if points > 2? go ahead
	///////////// append into FILE
	for( edex = 0; edex < ecount; edex+=1 )
		Make/N=( 0, dataSPEPnts )/O Accum_Data_Spectrum
		Make/N=0/D/O Accum_TimeStamp_ms
		Make/N=0/D/O Accum_TimeStamp
		Make/N=0/D/O Accum_TimeDuration
		Make/N=0/D/O Accum_Pressure
		Make/N=0/D/O Accum_Temperature
		Make/N=0/D/O Accum_PresRef
		Make/N=0/D/O Accum_TempRef
		first_keeper = -1;
		// skipping
		//Make/N=0/D/O SPB_PeakPosition
		//Make/N=0/D/O SPB_Linewidth
		//Make/N=0/D/O SPB_TuneRateScaleFactor
		
		for( idex = 0; idex < count; idex += 1 )
			fdex = -1;
			if( ( SPB_TimeStamp[ idex ] >= ECL_Start_w[ edex ] ) && ( SPB_TimeStamp[ idex ] <= ECL_Stop_w[ edex ] ) )
				fdex = 1; 
				if( first_keeper == -1 )
					first_keeper = idex;
				endif
			endif
			// if include, append to temp 

			if( fdex == 1 )
				Redimension/N=( DimSize( Accum_Data_Spectrum, 0 ) + 1, dataSPEPnts ) Accum_Data_Spectrum
				Accum_Data_Spectrum[ DimSize( Accum_Data_Spectrum, 1 ) - 1 ][] = SPB_Data_Spectrum_matrix[idex][q];
				AppendVal( Accum_TimeStamp_ms, SPB_TimeStamp_ms[ idex ]);
				AppendVal( Accum_TimeDuration, SPB_TimeDuration[ idex ]);
				AppendVal( Accum_Pressure, SPB_Pressure[ idex ]);
				AppendVal( Accum_Temperature, SPB_Temperature[ idex ]);
				AppendVal( Accum_PresRef, SPB_PresRef[ idex ]);
				AppendVal( Accum_TempRef, SPB_TempRef[ idex ]);
			endif
		
		endfor /////// this is for the all times that slotted into the start/stop

		Make/O/D/N=( perSPE ) avgSPE
		if( numpnts( Accum_TimeStamp_ms ) >= 2 ) 	// <<<<<<<<<<, filters against the 1 second from the next top of the hour file
			curlen = numpnts( SPB_ECLFiltered );


			Make/D/O/N=(dataSPEPnts) theAverageSpectrum
			for( jdex = 0; jdex < dataSPEPnts; jdex += 1 )
				Make/D/O/N=(DimSize( Accum_Data_Spectrum, 0 )) tempRow
				tempRow = Accum_Data_Spectrum[ 0 ][ jdex ]
				WaveStats/Q tempRow;
				theAverageSpectrum[ jdex ] = v_avg;
			endfor

			WaveStats/Q Accum_TimeStamp_ms
			avgSPE[ 0 ] = v_avg;
				
			avgSPE[ 1 ] = sum( Accum_TimeDuration );
				
			WaveStats/Q Accum_Pressure
			avgSPE[ 2 ] = v_avg;
				
			WaveStats/Q Accum_Temperature
			avgSPE[ 3 ] = v_avg;
			WaveStats/Q Accum_PresRef
			avgSPE[ 4 ] = v_avg;
			WaveStats/Q Accum_TempRef
			avgSPE[ 5 ] = v_avg;
				
				
//				for( jdex = 0; jdex < use_nSpecies; jdex += 1 )
//					avgSPE[ 6 + jdex ] = SPB_PeakPosition[ first_keeper ][ jdex ];
//				endfor
//				for( jdex = 0; jdex < use_nLasers; jdex += 1 )
//					avgSPE[ 6 + use_nSpecies + jdex ] = SPB_Linewidth[ first_keeper ][ jdex ];
//				endfor
			for( jdex = 0; jdex < use_nLasers; jdex += 1 )
					avgSPE[ 6 + use_nSpecies + use_nLasers + jdex ] = SPB_TuneRateScaleFactor[ first_keeper ][ jdex ];
			endfor

			if( verNum >= 3 )
				for( jdex = 0; jdex < use_nLasers; jdex += 1 )
					avgSPE[ 6 + use_nSpecies + use_nLasers + jdex ] = SPB_TuneRateScaleFactor[ first_keeper ][ jdex ];
				endfor
			endif
			for( jdex = 0; jdex < dataSPEPnts; jdex += 1 )
				avgSPE[ 6 + use_nSpecies + 2 * use_nLasers + jdex ] = theAverageSpectrum[ jdex ];
			endfor	
			//print 6 + use_nSpecies + 2 * use_nLasers, dataHeader 			
			Redimension/N=( curlen + perSPE ) SPB_ECLFiltered;
			SPB_ECLFiltered[ curlen, ] = avgSPE[ p - curlen ];

		endif
		// if n_spe > 0, write
	endfor
		
	Variable refNum
	Open/Z refNum as new_spb
	if( V_Flag != 0 )
		print "Error trying to write - ", new_spb
	endif
	FBinWrite/B=3 /F=0 refNum, SPB_ECLFiltered
	Close refNum
	
End

Function SPB_ECLStartStopNewFile( index, this_spb, new_spb, [algorithm] )
	Variable index
	String this_spb
	String new_spb
	String algorithm
	//FUNCREF  SPB_AlterScript_Proto  AlterScript
	
	String loc_algorithm
	if( ParamIsDefault( algorithm ) )
		loc_algorithm = "SimpleFilter"
	else
		loc_algorithm = algorithm
	endif
	
	// Keywords:: file count filecount spectrumcount
	// We need to count the spectra that are acutally going to be forwarded
	// 
	Variable IfCountIsZeroDoNotCopyFile = 1;
	Variable forwardingCount = 0;
	Variable thresholdCount = 1;	// needs at least one file
	//
	
	GBLoadWave /B=1/T={4,4} /N=BinLoad /Q this_spb
	Wave input_w = BinLoad0; 
	//Duplicate/O input_w, SPB_PreGraft
	//SPB_GraftNewDataOntoInputBinary( input_w, AlterScript )
	//Duplicate/O input_w, SPB_PostGraft, SPB_GraftDelta	
	//SPB_GraftDelta = SPB_PostGraft - SPB_PreGraft
	//DoWindow SPB_GraftResultTable
	//if( V_Flag != 1 )
	//Edit/K=1 SPB_PreGraft, SPB_PostGraft, SPB_GraftDelta as "SPB_GraftResultTable"
	//DoWindow/C SPB_GraftResultTable
	//endif

	String src_str, dest_str
	// The steps are:
	// display debug msg wave
	// build references to:
	// last load spe/spb & the mandated ECL index
	// start a new output_w
	// copy over the header but zero out n_spe
	// loop over last load checking each time against ecl-s-s
	// if include, append to output_w and increment
	// if n_spe > 0, write
	SVAR/Z workingDF = root:gs_ECL_WorkFolder
	String sf 
	if( SVAR_Exists( workingDF ) )
		sf = GetDataFolder(1); SetDataFolder $("root:" + workingDF )
	else
		String/G root:gs_ECL_WorkFolder = ""
		SetDataFolder root:
		SVAR/Z workingDF = root:gs_ECL_WorkFolder

	endif
	// display debug msg wave
	DoWindow SPB_ECL_FilterDiagWin
	if( V_Flag != 1 )
		Make/N=16/O/T SPB_ECL_FilterDiagnostic
		Edit as "SPB_ECL_FilterDiagWin"
		DoWindow/C SPB_ECL_FilterDiagWin
		AppendToTable SPB_ECL_FilterDiagnostic
	endif
	Wave/T SPB_ECL_FilterDiagnostic
	// build references to:
	// last load spe/spb & the mandated ECL index
	sprintf src_str, "ECL_%d_StartTime", index
	Wave/Z ECL_Start_w = $( src_str )
	if( WaveExists( ECL_Start_w ) != 1 )
		printf "Error referencing %s.  Aborting\r", src_str
		return -1
	endif
	sprintf src_str, "ECL_%d_StopTime", index
	Wave/Z ECL_Stop_w = $( src_str )
	if( WaveExists( ECL_Start_w ) != 1 )
		printf "Error referencing %s.  Aborting\r", src_str
		return -1
	endif
	
	// now parse and populate
	SPB_ParseInputFile( input_w ); SetDataFolder $("root:" + workingDF )
												
	Variable/G verNum = input_w[ SPB_FileFormat ];			
	Variable/G globHeader = input_w[SPB_GlobalHeaderLines ]
	Variable/G dataHeader = input_w[SPB_DataHeaderLines ];	
	Variable/G dataSPEPnts = input_w[SPB_SpectrumLength ]
	
	// operating in the hardwired root:SPB_Folder to hardwired nameset
	Variable/G linesInFile = numpnts( input_w )
	Variable/G dataLines = linesInFile - globHeader
	Variable/G perSPE = dataHeader + dataSPEPnts
	Variable/G probable_spectrum_count = dataLines / perSPE
	Variable/G nSpecies 
	Variable/G nLasers
	
	Variable use_nSpecies, use_nLasers
	Variable offset2PeakPos, offset2LineWidth, offset2TRScaleFactor
	use_nSpecies = input_w[ SPB_nSpeciesUsed ];
	nSpecies = use_nSpecies
	use_nLasers = input_w[ SPB_nLasersUsed ];
	nLasers = use_nLasers	
	offset2PeakPos 			= 6;											// this is the within each SPE offset
	offset2LineWidth 		= offset2PeakPos + use_nSpecies;		// the offset with each SPE
	offset2TRScaleFactor 	= offset2PeakPos + use_nSpecies + nLasers;		// the offset with each SPE

	
	Wave SPB_Data_Spectrum_matrix = root:SPB_Folder:SPB_Data_Spectrum_matrix
	Wave SPB_TimeStamp_ms = root:SPB_Folder:SPB_TimeStamp_ms
	Wave SPB_TimeStamp = root:SPB_Folder:SPB_TimeStamp
	Wave SPB_TimeDuration = root:SPB_Folder:SPB_TimeDuration
	Wave SPB_Pressure = root:SPB_Folder:SPB_Pressure
	Wave SPB_Temperature = root:SPB_Folder:SPB_Temperature
	Wave SPB_PresRef = root:SPB_Folder:SPB_PresRef
	Wave SPB_TempRef = root:SPB_Folder:SPB_TempRef
	Wave SPB_PeakPosition = root:SPB_Folder:SPB_PeakPosition
	Wave SPB_Linewidth = root:SPB_Folder:SPB_Linewidth
	Wave SPB_TuneRateScaleFactor = root:SPB_Folder:SPB_TuneRateScaleFactor
	variable InjectPeakPosition
		
	// start a new output_w
	Duplicate/O input_w, SPB_ECLFiltered		//		<<<<<<<<<<<< This is the target
	// copy over the header but zero out n_spe
	Redimension/N=(globHeader)  SPB_ECLFiltered;

	// loop over last load checking each time against ecl-s-s
	Variable idex, count = numpnts( SPB_TimeStamp ), jdex, jcount = numpnts( ECL_Start_w ), fdex, curlen;
	for( idex = 0; idex < count; idex += 1 )
		fdex = -1;
		for( jdex = 0; jdex < jcount; jdex+=1 )
			if( ( SPB_TimeStamp[ idex ] >= ECL_Start_w[ jdex ] ) && ( SPB_TimeStamp[ idex ] <= ECL_Stop_w[ jdex ] ) )
				fdex = 1; jdex = jcount;
			endif
		endfor	// if include, append to output_w and increment

		if( fdex == 1 )
			curlen = numpnts( SPB_ECLFiltered );
			Make/O/D/N=( perSPE ) miniSPE
			miniSPE[ 0 ] = SPB_TimeStamp_ms[ idex ];
			miniSPE[ 1 ] = SPB_TimeDuration[ idex ];
			miniSPE[ 2 ] = SPB_Pressure[ idex ];
			miniSPE[ 3 ] = SPB_Temperature[ idex ];
			miniSPE[ 4 ] = SPB_PresRef[ idex ];
			miniSPE[ 5 ] = SPB_TempRef[ idex ];
			for( jdex = 0; jdex < use_nSpecies; jdex += 1 )
//				if( jdex == 0 )
//				wave graftspedata
//					GraftSPEData =  SPB_Data_Spectrum_matrix[ idex ][ p ];
//
//					//InjectPeakPosition = SweepAndScale();
//					miniSPE[ 6 + jdex ] = InjectPeakPosition;
//					print InjectPeakPosition;
//					doupdate
//				else
					miniSPE[ 6 + jdex ] = SPB_PeakPosition[ idex ][ jdex ];
//				endif
			endfor
			// hot injection
			
			for( jdex = 0; jdex < use_nLasers; jdex += 1 )					
				miniSPE[ 6 + use_nSpecies + jdex ] = SPB_Linewidth[ idex ][ jdex ];
			endfor
			for( jdex = 0; jdex < use_nLasers; jdex += 1 )
				miniSPE[ 6 + use_nSpecies + use_nLasers + jdex ] = SPB_TuneRateScaleFactor[ idex ][ jdex ];
			endfor
			for( jdex = 0; jdex < dataSPEPnts; jdex += 1 )
				miniSPE[ 6 + use_nSpecies + 2 * use_nLasers + jdex ] = SPB_Data_Spectrum_matrix[ idex ][ jdex ];
			endfor	
			//print 6 + use_nSpecies + 2 * use_nLasers, dataHeader 			
			Redimension/N=( curlen + perSPE ) SPB_ECLFiltered;
			SPB_ECLFiltered[ curlen, ] = miniSPE[ p - curlen ];
			forwardingCount += 1;											// this tracks how many were found to be forwarded
		endif
	
		// if n_spe > 0, write
	endfor
		
	Variable refNum
	Open/Z refNum as new_spb
	if( V_Flag != 0 )
		print "Error trying to write - ", new_spb
	endif
	FBinWrite/B=3 /F=0 refNum, SPB_ECLFiltered
	Close refNum
	
	if( IfCountIsZeroDoNotCopyFile == 1 )
		
		if( forwardingCount < thresholdCount )
			// whoops, we need to delete the file
			DeleteFile/Z new_spb;
			printf "Spectrum Count (%d) does not meet threshold (%d) Deleting file %s\n", forwardingCount, thresholdCount, new_spb;
		endif
		
	endif
End

// This function supports two vectors
// one is direct via the data argument 'new_data_w'
// Alternately, you can all this like
// SPB_WriteNewSPB( original_spb, original_spe, new_data_w, newPathString, SPB_AlterScript=myAlterationScript )
// where you have written in your procedure window, or elsewhere a function named
// myAlterationScript which must be based on SPB_AlterScript_Proto() 
Function SPB_WriteNewSPB( original_spb, original_spe, newPathString, SPB_AlterScript )
	String original_spb, original_spe
	String newPathString
	FUNCREF  SPB_AlterScript_Proto  SPB_AlterScript
	
	GetFileFolderInfo/Q original_spb
	String justFileName = ParseFilePath( 0, original_spe, ":", 1, 0 )
	String justFileNameNoExt = ParseFilePath( 3, original_spe, ":", 0, 0 )
	String newFPFile, newSPBFile, newPathVerify
	
	NewPath/C/O/Q NewSPBOut , newPathString
	
	printf "Writing new files from %s\r", justFileName
	
	PathInfo NewSPBOut
	newPathVerify = s_path
	printf "Writing new files to %s\r", newPathVerify
	sprintf newFPFile, "%s:%s", s_path, justFileName
	newFPFile = RemoveDoubleColon( newFPFile );
	CopyFile/O original_spe as newFPFile
	
	sprintf newSPBFile, "%s:%s.spb", newPathVerify, justFileNameNoExt
	newSPBFile = RemoveDoubleColon( newSPBFile );
	printf "Writing new spb as %s\r", newSPBFile

	SPB_GraftNewDataOntoInputFile( original_spb, newSPBFile, SPB_AlterScript )
	
	KillPath newSPBOut
	
End
// Algorithm can only be the following 
//		"SimpleFilter" << the default.  Passes spectra between start/stop into the newSPB
//				see function -> SPB_ECLStartStopNewFile( index, original_spb, newSPBFile )
//		"AvgAndWriteBG"  This averages the found spectra into one, overrides the output, captures and writes companion _BG.spe
//
//
Function SPB_ECLWriteNewSPB( index, original_spb, original_spe, newPathString, [algorithm] )
	Variable index
	String original_spb, original_spe
	String newPathString
	String algorithm
	//FUNCREF  SPB_AlterScript_Proto  SPB_AlterScript
	
	if( ParamIsDefault( algorithm ) )
		algorithm = "simplefilter"
	endif
	
	GetFileFolderInfo/Q original_spb
	String justFileName = ParseFilePath( 0, original_spe, ":", 1, 0 )
	String justFileNameNoExt = ParseFilePath( 3, original_spe, ":", 0, 0 )
	String bgFile = ""
	
	// This is a weakness here
	// File name convention is 171201_210929_001_SIG
	Variable sig_loc = strsearch( justFileNameNoExt, "_SIG", 0 );
	if( sig_loc != -1 )
		bgfile = justFileNameNoExt[ 0, sig_loc - 1] + "_BG";
	endif
	
	
	String newFPFile, newSPBFile, newPathVerify
	
	NewPath/C/O/Q NewSPBOut , newPathString
	
	printf "Writing new files from %s\r", justFileName
	
	PathInfo NewSPBOut
	newPathVerify = s_path
	printf "Writing new files to %s\r", newPathVerify

	
	strswitch( lowerstr(algorithm) )
		case "simplefilter":
			sprintf newFPFile, "%s:%s", s_path, justFileName
			newFPFile = RemoveDoubleColon( newFPFile );
			CopyFile/O original_spe as newFPFile
	
			sprintf newSPBFile, "%s:%s.spb", newPathVerify, justFileNameNoExt
			newSPBFile = RemoveDoubleColon( newSPBFile );
			printf "Writing new spb as %s\r", newSPBFile

			SPB_ECLStartStopNewFile( index, original_spb, newSPBFile )
			break;
		
		
		case "avgandwritebg":
			if( strlen( bgfile ) > 0 )
				// then the file IS a _SIG and we have a predestin _BG set up
				sprintf newFPFile, "%s:%s.spe", s_path, bgfile
				newFPFile = RemoveDoubleColon( newFPFile );
				CopyFile/O original_spe as newFPFile
	
	
				sprintf newSPBFile, "%s:%s.spb", newPathVerify, bgfile
				newSPBFile = RemoveDoubleColon( newSPBFile );
				printf "Writing new _BG.spb as %s\r", newSPBFile
				SPB_ECLStartStopNewBGFile( index, original_spb, newSPBFile )
			else
				printf "Algorithm AvgAndWriteBG is skipping -> %s\r", original_spb
			endif
			break;
				
	endswitch
	KillPath newSPBOut
	
End
Function SPB_FFTSubRange( optStr )
	String optStr 

	Variable chan_start = 2
	Variable chan_stop = 500
	
	Wave s = root:SPB_Folder:SPB_Data_Spectrum_matrix
	

End

Function SPB_AlterScript_Proto()
	
	Wave SPB_Data_Spectrum_matrix = root:SPB_GraftFolder:SPB_Data_Spectrum_matrix
	Wave SPB_TimeStamp_ms = root:SPB_GraftFolder:SPB_TimeStamp_ms
	Wave SPB_TimeStamp = root:SPB_GraftFolder:SPB_TimeStamp
	Wave SPB_TimeDuration = root:SPB_GraftFolder:SPB_TimeDuration
	Wave SPB_Pressure = root:SPB_GraftFolder:SPB_Pressure
	Wave SPB_Temperature = root:SPB_GraftFolder:SPB_Temperature
	Wave SPB_PresRef = root:SPB_GraftFolder:SPB_PresRef
	Wave SPB_TempRef = root:SPB_GraftFolder:SPB_TempRef
	Wave SPB_PeakPosition = root:SPB_GraftFolder:SPB_PeakPosition
	Wave SPB_Linewidth = root:SPB_GraftFolder:SPB_Linewidth
	Wave SPB_TuneRateScaleFactor = root:SPB_GraftFolder:SPB_TuneRateScaleFactor
	
	// do things here ...
	// do not overwrite this function, make your own
	//
	// examples
	// fix the peak position of species 2 to a new channel ... 43
	//		SPB_PeakPosition[][1] = 43
	return 0
End

Function SPB_AlterSPB_TuneRateFacTo_1()
	
	Wave SPB_Data_Spectrum_matrix = root:SPB_GraftFolder:SPB_Data_Spectrum_matrix
	Wave SPB_TimeStamp_ms = root:SPB_GraftFolder:SPB_TimeStamp_ms
	Wave SPB_TimeStamp = root:SPB_GraftFolder:SPB_TimeStamp
	Wave SPB_TimeDuration = root:SPB_GraftFolder:SPB_TimeDuration
	Wave SPB_Pressure = root:SPB_GraftFolder:SPB_Pressure
	Wave SPB_Temperature = root:SPB_GraftFolder:SPB_Temperature
	Wave SPB_PresRef = root:SPB_GraftFolder:SPB_PresRef
	Wave SPB_TempRef = root:SPB_GraftFolder:SPB_TempRef
	Wave SPB_PeakPosition = root:SPB_GraftFolder:SPB_PeakPosition
	Wave SPB_Linewidth = root:SPB_GraftFolder:SPB_Linewidth
	Wave SPB_TuneRateScaleFactor = root:SPB_GraftFolder:SPB_TuneRateScaleFactor
	
	// do things here ...
	// do not overwrite this function, make your own
	//
	// examples
	SPB_TuneRateScaleFactor = 1.0;
	
	return 0
End

Function SPB_HexCrFixNOChannelPosition()
	
	Wave SPB_Data_Spectrum_matrix = root:SPB_GraftFolder:SPB_Data_Spectrum_matrix
	Wave SPB_TimeStamp_ms = root:SPB_GraftFolder:SPB_TimeStamp_ms
	Wave SPB_TimeStamp = root:SPB_GraftFolder:SPB_TimeStamp
	Wave SPB_TimeDuration = root:SPB_GraftFolder:SPB_TimeDuration
	Wave SPB_Pressure = root:SPB_GraftFolder:SPB_Pressure
	Wave SPB_Temperature = root:SPB_GraftFolder:SPB_Temperature
	Wave SPB_PresRef = root:SPB_GraftFolder:SPB_PresRef
	Wave SPB_TempRef = root:SPB_GraftFolder:SPB_TempRef
	Wave SPB_PeakPosition = root:SPB_GraftFolder:SPB_PeakPosition
	Wave SPB_Linewidth = root:SPB_GraftFolder:SPB_Linewidth
	Wave SPB_TuneRateScaleFactor = root:SPB_GraftFolder:SPB_TuneRateScaleFactor
	
	// do things here ...
	// do not overwrite this function, make your own
	//
	// examples
	// fix the peak position of species 2 to a new channel ... 43
	SPB_PeakPosition[][1] = 42.5

End

Function SPB_AlterAllFilesInDirectory( source_dir, dest_dir, alterScript )
	String source_dir
	String dest_dir
	FUNCREF SPB_AlterScript_Proto alterScript
	
		
	if( cmpstr( source_dir, "" ) == 0 )
		NewPath/O/Q/M="Choose directory where .spb are located" dat_LoadPATH
	else
		NewPath/O/Q dat_LoadPATH  source_dir
	endif
	if( V_Flag != 0 )
		printf "aborted, cancelled or failed NewPath\r"; return -1;
	endif
	
	Make/T/N=0/O temp_list_of_spb_tw

	// GLF_ functions are in Global_Utils.ipf
	GFL_FilelistAtOnce( "dat_LoadPATH", 0, temp_list_of_spb_tw, ".spb" )
	sort temp_list_of_spb_tw, temp_list_of_spb_tw

	String this_spb
	Variable idex = 0, count = Numpnts( temp_list_of_spb_tw )
	Variable found_spb = 0
	Variable load_this_one = 0
	String source_file, spe_file
	Variable ts, skipflag
	Variable last_ans
	if( count > 0 )
		do
			this_spb = temp_list_of_spb_tw[idex];		load_this_one = 0
			ts = dti_text2datetime( "20" + this_spb[0,12], "filename" );
			if( cmpstr(lowerstr(ParseFilePath(4, this_spb, ":", 0, 0)), "spb" ) == 0 )
				load_this_one = 1;
			endif
			printf "%s\r", dti_datetime2text( ts,"american" ) 
			if( load_this_one )
				PathInfo dat_LoadPATH
				sprintf source_file "%s:%s", s_path, this_spb
				sprintf spe_file "%s:%s.spe", s_path, StringFromList( 0, this_spb, "." )
				source_file = RemoveDoubleColon( source_file )
				spe_file = RemoveDoubleColon( spe_file )

				Make/N=0/D/O DummyWave
				Wave HH_Motion = root:HH_Motion
				if( HH_Motion( ts ) > 0.5 )
					skipflag = 0
				else
					skipflag = 1
				endif
				if( (strsearch( source_file, "_SIG", 0 ) != -1) & (skipflag==0) ) 	

					printf "loading %s file ... altering ...", source_file
				
					SPB_WriteNewSPB( source_file, spe_file, dest_dir, alterScript )	
				
					doupdate;
					
				else
					printf "Skipping %s\r", source_file
				endif
							
			endif
			idex += 1
			
			//if( idex == 1 )
			//	idex = count
			//endif
			
		while( idex < count )

	
	else
		printf "No spb files at all found in the directory\r"
	endif
	
	// and clean up afterward
	KillPath/Z dat_LoadPATH
	KillWaves/Z temp_list_of_dat_tw
	
	SetDataFolder root:

End
Function SPB_ECL_FilterFilesInDirSuite( index, tdlDatDir, dest_dir, [algorithm] )
	Variable index
	String tdlDatDir
	String dest_dir
	String algorithm
	
	String loc_algorithm
	if( ParamIsDefault( algorithm ) )
		loc_algorithm = "SimpleFilter"
	else
		loc_algorithm = algorithm
	endif	
	
	String candidateDir
	Make/N=0/T/O suiteFolderList;
	NewPath/O tmpP , tdlDatDir
	GFL_Folderlist( "tmpP", 1, suiteFolderList, "" );
	
	Variable idex, count = numpnts( suiteFolderList );
	for( idex = 0; idex < count; idex += 1 )
		
		sprintf candidateDir, "%s:%s", tdlDatDir, suiteFolderlist[ idex ]
		candidateDir  = RemoveDoubleColon( candidateDir );
		
		SPB_ECL_FilterFilesInDir( index, candidateDir, dest_dir, algorithm = loc_algorithm )
	
	endfor
	
End
Function SPB_ECL_FilterFilesInDir( index, source_dir, dest_dir, [algorithm] )
	Variable index
	String source_dir
	String dest_dir
	String algorithm
	//FUNCREF SPB_AlterScript_Proto alterScript
	
	String loc_algorithm
	if( ParamIsDefault( algorithm ) )
		loc_algorithm = "SimpleFilter"
	else
		loc_algorithm = algorithm
	endif	
	if( cmpstr( source_dir, "" ) == 0 )
		NewPath/O/Q/M="Choose directory where .spb are located" dat_LoadPATH
	else
		NewPath/O/Q dat_LoadPATH  source_dir
	endif
	if( V_Flag != 0 )
		printf "aborted, cancelled or failed NewPath\r"; return -1;
	endif
	
	NewPath/C/Q/O/Z spb_ecl_destFolder, dest_dir
	KillPath spb_ecl_destFolder
	
	Make/T/N=0/O temp_list_of_spb_tw

	// GLF_ functions are in Global_Utils.ipf
	GFL_FilelistAtOnce( "dat_LoadPATH", 0, temp_list_of_spb_tw, ".spb" )
	sort temp_list_of_spb_tw, temp_list_of_spb_tw

	String this_spb
	Variable idex = 0, count = Numpnts( temp_list_of_spb_tw )
	Variable found_spb = 0
	Variable load_this_one = 0
	String source_file, spe_file
	
	if( count > 0 )
		do
			this_spb = temp_list_of_spb_tw[idex];		load_this_one = 0
			
			if( cmpstr(lowerstr(ParseFilePath(4, this_spb, ":", 0, 0)), "spb" ) == 0 )
				load_this_one = 1;
			endif
			if( load_this_one )
				PathInfo dat_LoadPATH
				sprintf source_file "%s:%s", s_path, this_spb
				sprintf spe_file "%s:%s.spe", s_path, StringFromList( 0, this_spb, "." )
				source_file = RemoveDoubleColon( source_file )
				spe_file = RemoveDoubleColon( spe_file )

				printf "loading %s file ... altering ...", source_file
				Make/N=0/D/O DummyWave
				
				SPB_ECLWriteNewSPB( index, source_file, spe_file, dest_dir, algorithm=loc_algorithm )				
			endif
			idex += 1
			
			//if( idex == 1 )
			//	idex = count
			//endif
			
		while( idex < count )

	
	else
		printf "No spb files at all found in the directory\r"
	endif
	
	// and clean up afterward
	KillPath/Z dat_LoadPATH
	KillWaves/Z temp_list_of_dat_tw
	
	SetDataFolder root:

End

Function SPB_ReferenceTemplateFunction()
	
	Wave SPB_Data_Spectrum_matrix = root:SPB_Folder:SPB_Data_Spectrum_matrix
	Wave SPB_TimeStamp_ms = root:SPB_Folder:SPB_TimeStamp_ms
	Wave SPB_TimeStamp = root:SPB_Folder:SPB_TimeStamp
	Wave SPB_TimeDuration = root:SPB_Folder:SPB_TimeDuration
	Wave SPB_Pressure = root:SPB_Folder:SPB_Pressure
	Wave SPB_Temperature = root:SPB_Folder:SPB_Temperature
	Wave SPB_PeakPosition = root:SPB_Folder:SPB_PeakPosition
	Wave SPB_Linewidth = root:SPB_Folder:SPB_Linewidth
End

// SPB_TopSideFileList( "c:tdlwintel:data", 0 )  
// depth_code = 0 => flat, only this or selected directory
// depth_code = 1 => one deep from and including this directory
// depth_code = 2 => bore all the way down, all sublayers, all folders, all files...


Function SPB_TopSideFileList( starting_path, depth_code )
	String starting_path
	Variable depth_code
	
	String saveFolder = GetDataFolder(1); MakeAndOrSetDF( "SPB_Folder" ); Make/N=0/T/O filelist_spb; SetDataFolder $saveFolder
	String use_path; Variable invoke_dialog = 0; String msg_str, good_path
	// check to see if this function was called with a null listing
	if( cmpstr( starting_path, "" ) == 0 )
		invoke_dialog = 1
	else
		// check to see if this starting_path argument actually exists
		NewPath/O/Z/Q SPB_TSFL_Path, starting_path
		if( v_flag != 0 )
			// this represents a failed path, invoke dialog
			invoke_dialog = 1
		endif
	endif
	msg_str = "Pick Top Directory for SPB_TopSideFileList function"
	if( invoke_dialog )
		NewPath/O/Q/M=msg_str SPB_TSFL_Path
	endif
	// it should now exist for a handoff to SideSideFileList function where depth code will be managed
	// net result is a useful filelist_spb wave
	PathInfo SPB_TSFL_Path
	good_path = s_path
	SPB_DiveDirectory4SPB( good_path, 1, depth_code )
	Wave/T master_list_of_found_spbs = root:SPB_Folder:master_list_of_found_spbs
	Duplicate/O/T master_list_of_found_spbs, filelist_spb
	Wave/T filelist_spb = root:SPB_Folder:filelist_spb
	SPB_ParseAndDocumentFileList( )
End

// full scan vs random arbitrary load -- The full scan helps find things
// but will it get old with loads
// the scan should be enough to keep it stocked with reference -- if it falls outside of that
// then it will just wanr the users they're out of scanning range and prompt for rescan
// super nested load in igor should keep thing identical to size on drive.
// typical hour long is 4MB
// means a day long is ~100 MB
// a week long would be about 700 MB and will that be acceptable?  Hard question...
// needs to be based on the needed functionality.


Function SPB_ParseAndDocumentFileList( )
	
	Wave/T filelist_spb = root:SPB_Folder:filelist_spb
	Variable idex, count = numpnts( filelist_spb );
	String this_spb, speMatch, filetype, just_file, just_path, test_for
	String filetype_list = "SIG;PN;BG;REF;CAL;RAW;", this_type
	Variable jdex, jcount = ItemsInList( filetype_list )
	String saveFolder = GetDataFolder(1); SetDataFolder root:; MakeAndOrSetDF( "SPB_Folder" )
	Duplicate/O/T filelist_spb, filelist_filetype, filelist_speMatch, filelist_desthrDF
	filelist_speMatch = ""; filelist_desthrDF = ""; filelist_filetype = ""; 
	Make/O/D/N=(count) filelist_name_DAT, filelist_spb_begins, filelist_spb_ends
	filelist_spb_begins = -1; filelist_spb_ends = -1;
	
	for( idex = 0; idex < count; idex += 1 )
		// loop through file list, building entries for the other waves
		this_spb = filelist_spb[idex]; just_file = GetFileNameFromFileOrFP( this_spb )
		just_path = GetPathNameFromFileOrFP( this_spb )
		sprintf test_for, "%s%s.spe", just_path, just_file
		if( FileExistsFullPath( test_for ) == 0 )
			filelist_speMatch[idex] = test_for
		else
			filelist_speMatch[idex] = "nofile"
		endif
		jdex = 0
		filelist_filetype[idex] = "unktype"
		for( jdex = 0; jdex < jcount; jdex += 1 )
			this_type = StringFromList( jdex, filetype_list )
			if( strsearch( this_spb, this_type , 0) != -1 )
				//printf "%s %s\r", this_spb, this_type;
				filelist_filetype[idex] = this_type; jdex = jcount
			endif
			
		endfor
		filelist_name_DAT[idex] = SPE2_WintelSPEName2DateTime( just_file )
		filelist_desthrDF[idex] = "root:SPB_Folder:SPB_" + just_file[0,10]// + filelist_filetype[idex]
	endfor
	
	// TDLWintel is writing these 'hourly' files -- we will rely on this to associate each type of spectrum with
	// every hour -- mid hour changes will simply not be tolerated at this time?
	Make/N=0/O filelist_hour
	Make/N=0/O/T filelist_a_SIG, filelist_a_PN, filelist_a_BG, filelist_a_REF, filelist_a_RAW
	
	String assoc_SIG, assoc_PN, assoc_BG, assoc_REF, assoc_RAW
	Variable hour, q_hour
	for( idex = 0; idex < count; idex += 1 )
		assoc_SIG = "not_found"; assoc_PN = "not_found"; assoc_BG = "not_found"; assoc_REF = "not_found"; assoc_RAW = "not_found";
		this_spb = filelist_spb[idex]
		if( strsearch( this_spb, "SIG", 0 ) > -1 )
			// we have a SIG to pilot the process
			assoc_SIG = this_spb
			hour = HourFromIgorTime( filelist_name_DAT[idex] ) 
			for( jdex = 0; jdex < count; jdex += 1 )
				if( jdex != idex )
					this_spb = filelist_spb[jdex]
					if( strsearch( this_spb, "SIG", 0 ) == -1 )
						// then these are not SIG files .. which is good
						q_hour = HourFromIgorTime( filelist_name_DAT[jdex] )
						if( hour == q_hour )
							// this is not a SIG file and it has an 'hour' match, so lets try it
							strswitch (filelist_filetype[jdex])
								case "PN":
									assoc_PN = this_spb
									break;
								case "BG":
									assoc_BG = this_spb
									break;
								case "REF":
									assoc_REF = this_spb
									break;
								case "RAW":
									assoc_RAW = this_spb
									break;
								default:
									break;
							endswitch
						endif
					endif
				endif
			endfor
			AppendVal( filelist_hour, hour )
			AppendString( filelist_a_SIG, assoc_SIG )
			AppendString( filelist_a_PN, assoc_PN )
			AppendString( filelist_a_BG, assoc_BG )
			AppendString( filelist_a_REF, assoc_REF )
			AppendString( filelist_a_RAW, assoc_RAW )
		endif
	endfor		
	
	SetDataFolder $saveFolder
	
	//	String whole_list_set = "filelist_name_DAT;filelist_spb;filelist_filetype;filelist_speMatch;" 
	//	Sort filelist_name_DAT, filelist_name_DAT, filelist_spb, filelist_filetype, filelist_desthrDF, filelist_speMatch
End

Function SPB_ChronoTestLoad()
	
	Wave/T filelist_spb = root:SPB_Folder:filelist_spb
	Wave/T filelist_fileType = root:SPB_Folder:filelist_fileType
	Wave/T filelist_speMatch = root:SPB_Folder:filelist_speMatch
	Wave/T filelist_desthrDF = root:SPB_Folder:filelist_desthrDF
	Wave filelist_spb_begins = root:SPB_Folder:filelist_spb_begins
	Wave filelist_spb_ends = root:SPB_Folder:filelist_spb_ends
	Variable idex = 0, count = numpnts( filelist_spb )
	String this_spb, this_spe, this_type, use_df, this_df, saveFolder
	saveFolder = GetDataFolder(1)
	if( count == 0 )
		printf "cannot find files\r"; return -1
	endif
	do
		this_spb = filelist_spb[idex]; this_spe = filelist_speMatch[idex]; this_type = filelist_fileType[idex]
		this_df = filelist_desthrDF[idex]; use_df = this_df + ":" + this_type
		
		
		Wave/T/Z destFrame = root:LoadSPE_UI:loadSPE_Frame
		if( WaveExists( destFrame ) != 1 )
			zSPE2_DrawPanel()
			SetDataFolder root:; MakeAndOrSetDF( "LoadSPE_UI" )
			Make/T/N=0/O LoadSPE_Frame; SetDataFolder $saveFolder
			Wave/T destFrame = root:LoadSPE_UI:LoadSPE_Frame
		endif
		zSPE2_LoadTextToFrame( this_spe, destFrame )
		SPE2_ProcFrameAsSPE( destFrame )
		SetDataFolder root:; MakeAndOrSetDF( this_df ); KillDataFolder/Z $use_df 
		DuplicateDataFolder root:LoadSPE_II, $use_df
		zSPE2_UpdateBrowseBits()
		//zSPE2_UpdateSessionWaves(packed_file, path_file)
		
		// Binary Load /B=1 implies low-byte first; /T={4,4} implies double precision in both file and data wave
		
		GBLoadWave /B=1 /T={4,4} /N=BinLoad /Q this_spb
		Wave w = BinLoad0; 
		SPB_ParseInputFile( w )
		KillWaves/Z BinLoad0;
		// currently we need to duplicate these to our destination data folder and hook the index
		Wave SPB_Data_Spectrum_matrix = root:SPB_Folder:SPB_Data_Spectrum_matrix
		Wave SPB_TimeStamp_ms = root:SPB_Folder:SPB_TimeStamp_ms
		Wave SPB_TimeStamp = root:SPB_Folder:SPB_TimeStamp
		Wave SPB_TimeDuration = root:SPB_Folder:SPB_TimeDuration
		Wave SPB_Pressure = root:SPB_Folder:SPB_Pressure
		Wave SPB_Temperature = root:SPB_Folder:SPB_Temperature
		Wave SPB_PeakPosition = root:SPB_Folder:SPB_PeakPosition
		Wave SPB_Linewidth = root:SPB_Folder:SPB_Linewidth
		Wave SPB_TuneRateScaleFactor = root:SPB_Folder:SPB_TuneRateScaleFactor
	
		SetDataFolder root:; MakeAndOrSetDF( this_df ); MakeAndOrSetDF( use_df )
		Duplicate/O SPB_Data_Spectrum_matrix, $"Data_Spectrum_Matrix"
		Duplicate/O SPB_TimeStamp_ms, $"Timestamp_ms"
		Duplicate/O SPB_TimeStamp, $"TimeStamp"
		Duplicate/O SPB_TimeDuration, $"TimeDuration"
		Duplicate/O SPB_Pressure, $"Pressure"
		Duplicate/O SPB_Temperature, $"Temperature"
		Duplicate/O SPB_PeakPosition, $"PeakPosition"
		Duplicate/O SPB_Linewidth, $"LineWidth"
		Duplicate/O SPB_TuneRateScaleFactor, $"TuneRateScaleFactor"
		
		if( 0 )
			// Programmers note, this is devvelopment switch
			// invoke Make/D/O/N=0 root:accumulate_time, root:accumulate_TRSF
			
			ConcatenateWaves( "root:accumulate_time", "root:SPB_Folder:SPB_TimeStamp" )
			ConcatenateWaves( "root:accumulate_TRSF", "root:SPB_Folder:SPB_TuneRateScaleFactor" )

		endif
		filelist_spb_begins[idex] = SPB_TimeStamp[0]; filelist_spb_ends[idex] = SPB_TimeStamp[ numpnts( SPB_TimeStamp ) -1]
		SetDataFolder saveFolder
		idex += 1
	while( idex < count )
	
End

// needs a folder in root:SPB_Folder as arg=datafolder
// e.g. SPB_120225_07 exists formally as root:SPB_Folder:SPB_120225_07
//
Function Noise_Ethane(datafolder)
	String datafolder
	
	String saveFolder = GetDataFolder(1); SetDataFolder root:SPB_Folder
	SetDataFolder $datafolder
	// should have subfolder SIG, RAW, et al.
	
	// want to analyze fft spectrum of wavelength, then of point number
	Wave raw_time = :RAW:TimeStamp
	Variable count = numpnts( raw_time ), idex
	Make/N=(count)/D/O NoiseTime_RAW; NoiseTime_RAW = nan
	Make/N=(count)/D/O GenLen; GenLen = nan
	Make/N=(count)/D/O GenLenAmp; GenLenAmp = nan
	Wave src = :SIG:Data_Spectrum_Matrix
	Wave pilot_freq = :SIG:wb1_frequency
	Wave pilot_data = :SIG:wb1_spectrum
	
	Variable pn_start = 1, pn_stop = 500
	Variable freq_start = pilot_freq[pn_start]
	Variable freq_stop = pilot_freq[pn_stop]
	Variable freq_step =   0.0005
	Variable freq_pnts = Floor(  (freq_stop - freq_start ) / freq_step ) + 1
	freq_pnts = Floor( freq_pnts / 2 ) * 2;
	Make/N=(freq_pnts )/D/O ThisEvenFreqSpectrum
	SetScale/P x, freq_start, freq_step, "cm-1", ThisEvenFreqSpectrum
	

	Make/N=(numpnts( pilot_data)  )/D/O SourceDataSpectrum
	// goes with pilot_freq dims...?
	Duplicate/O ThisEvenFreqSpectrum, AverageEvenFreqSpectrum
	AverageEvenFreqSpectrum = 0;
	Make/N=( numpnts( ThisEvenFreqSpectrum ), numpnts( raw_time) )/D/O EvenFreqSpec_Mat, FFTEvenFreqSpec_Mat
	SetScale/P x, DimOffset( ThisEvenFreqSpectrum, 0 ), DimDelta( ThisEvenFreqSpectrum, 0 ), "cm-1", EvenFreqSpec_Mat
	//SetScale/I y, Text2DateTime( "7/8/2014 18:00" ), Text2DateTime( "7/8/2014 19:00" ), "dat", EvenFreqSpec_Mat
	for( idex = 0; idex < count; idex += 1 )
		// Pull data from the SPB array onto this source frame
		SourceDataSpectrum = src[idex][p];		/// THIS ONLY WORKs on FIRST LASER, WB2 is gone!
		
		// use that source frame together with tdlwintel original frequency computation
		// this is in wintel and based on peak position for species 1
		// x-scaling was set earlier and is fixed throughout
		ThisEvenFreqSpectrum = interp( x, pilot_freq, SourceDataSpectrum )
		
		AverageEvenFreqSpectrum = AverageEvenFreqSpectrum + ThisEvenFreqSpectrum
		
		// Fit a polynomial to the spectrum // make it a 'line'
		CurveFit/NTHR=0/Q/N=1 poly 3, ThisEvenFreqSpectrum
		Wave W_Coef
		ThisEvenFreqSpectrum -= W_Coef[0] + W_coef[1] * x + W_Coef[2] * x^2;
		// now we should have a more linearized representation of the structures...
		 
		EvenFreqSpec_Mat[][idex] = ThisEvenFreqSpectrum[p]
		 
		Duplicate/O ThisEvenFreqSpectrum, ThisFFTEvenFreq
		// out = 4	Magnitude Squared
		
		FFT/OUT=4/DEST=ThisFFTEvenFreq 	ThisEvenFreqSpectrum
		Redimension/N=( numpnts( ThisFFTEvenFreq), numpnts(raw_time)) FFTEvenFreqSpec_Mat
		 
		FFTEvenFreqSpec_Mat[][idex] = ThisFFTEvenFreq
		ThisFFTEvenFreq[0] = 1
		CurveFit/NTHR=0/Q/N=1 gauss  ThisFFTEvenFreq[10,21] /D 	
		Wave W_Coef
		GenLen[idex] = W_coef[2]
		GenLenAmp[idex] = W_coef[1]
		NoiseTime_RAW[idex] = raw_time[idex];
		//DoUpdate;
		
	endfor
	AverageEvenFreqSpectrum /= (count);
	
	return 0
	Wave/T filelist_spb = root:SPB_Folder:filelist_spb
	Wave/T filelist_fileType = root:SPB_Folder:filelist_fileType
	Wave/T filelist_speMatch = root:SPB_Folder:filelist_speMatch
	Wave/T filelist_desthrDF = root:SPB_Folder:filelist_desthrDF
	Wave filelist_spb_begins = root:SPB_Folder:filelist_spb_begins
	Wave filelist_spb_ends = root:SPB_Folder:filelist_spb_ends
	
	String this_spb, this_spe, this_type, use_df, this_df
	
	if( count == 0 )
		printf "cannot find files\r"; return -1
	endif
	do
		this_spb = filelist_spb[idex]; this_spe = filelist_speMatch[idex]; this_type = filelist_fileType[idex]
		this_df = filelist_desthrDF[idex]; use_df = this_df + ":" + this_type
		
		
		Wave/T/Z destFrame = root:LoadSPE_UI:loadSPE_Frame
		if( WaveExists( destFrame ) != 1 )
			zSPE2_DrawPanel()
			SetDataFolder root:; MakeAndOrSetDF( "LoadSPE_UI" )
			Make/T/N=0/O LoadSPE_Frame; SetDataFolder $saveFolder
			Wave/T destFrame = root:LoadSPE_UI:LoadSPE_Frame
		endif
		zSPE2_LoadTextToFrame( this_spe, destFrame )
		SPE2_ProcFrameAsSPE( destFrame )
		SetDataFolder root:; MakeAndOrSetDF( this_df ); KillDataFolder/Z $use_df 
		DuplicateDataFolder root:LoadSPE_II, $use_df
		zSPE2_UpdateBrowseBits()
		
		GBLoadWave /B=1 /T={4,4} /N=BinLoad /Q this_spb
		Wave w = BinLoad0; 
		SPB_ParseInputFile( w )
		KillWaves/Z BinLoad0;
		// currently we need to duplicate these to our destination data folder and hook the index
		Wave SPB_Data_Spectrum_matrix = root:SPB_Folder:SPB_Data_Spectrum_matrix
		Wave SPB_TimeStamp_ms = root:SPB_Folder:SPB_TimeStamp_ms
		Wave SPB_TimeStamp = root:SPB_Folder:SPB_TimeStamp
		Wave SPB_TimeDuration = root:SPB_Folder:SPB_TimeDuration
		Wave SPB_Pressure = root:SPB_Folder:SPB_Pressure
		Wave SPB_Temperature = root:SPB_Folder:SPB_Temperature
		Wave SPB_PeakPosition = root:SPB_Folder:SPB_PeakPosition
		Wave SPB_Linewidth = root:SPB_Folder:SPB_Linewidth
	
		SetDataFolder root:; MakeAndOrSetDF( this_df ); MakeAndOrSetDF( use_df )
		Duplicate/O SPB_Data_Spectrum_matrix, $"Data_Spectrum_Matrix"
		Duplicate/O SPB_TimeStamp_ms, $"Timestamp_ms"
		Duplicate/O SPB_TimeStamp, $"TimeStamp"
		Duplicate/O SPB_TimeDuration, $"TimeDuration"
		Duplicate/O SPB_Pressure, $"Pressure"
		Duplicate/O SPB_Temperature, $"Temperature"
		Duplicate/O SPB_PeakPosition, $"PeakPosition"
		Duplicate/O SPB_Linewidth, $"LineWidth"
		
		filelist_spb_begins[idex] = SPB_TimeStamp[0]; filelist_spb_ends[idex] = SPB_TimeStamp[ numpnts( SPB_TimeStamp ) -1]
		SetDataFolder saveFolder
		idex += 1
	while( idex < count )
	
End
Function SPB_PullAllTimesForType( dest_time_w, typeStr )
	Wave dest_time_w
	String typeStr
	
	String saveFolder = GetDataFolder(1)
	SetDataFolder root:SPB_Folder
	String folder_list = DataFolderDir(1), sub_folder_list
	Variable idex, count = ItemsInList( folder_list ), jdex
	String this_folder
	for( idex = 0; idex < count; idex += 1 )
		this_folder = StringFromLIst( idex, folder_list )
		SetDataFolder $this_folder
		sub_folder_list = DataFolderDir(1);
		jdex = whichlistitem( typeStr, sub_folder_list )
		if( jdex != -1 )
			SetDataFolder $typeStr
			Wave/Z time_w = timestamp
			if( WaveExists( time_w ) )
						
			endif
		endif
	endfor
	SetDataFolder $saveFolder 
	
End
Function SPB_PullBGforThisSIG( sig_time, dest_bg_w )
	Variable sig_time
	Wave dest_bg_w
	
	Variable ret_code = -1	// this will herald that a suitable bg was not found!!
	
	
	
	
	return ret_code
End

Function SPB_LoadHourLoad(path)
	String path
	
	Wave/T filelist_spb = root:SPB_Folder:filelist_spb
	Wave/T filelist_fileType = root:SPB_Folder:filelist_fileType
	Wave/T filelist_speMatch = root:SPB_Folder:filelist_speMatch
	Wave/T filelist_desthrDF = root:SPB_Folder:filelist_desthrDF
	Wave filelist_spb_begins = root:SPB_Folder:filelist_spb_begins
	Wave filelist_spb_ends = root:SPB_Folder:filelist_spb_ends
	Variable idex = 0, count = numpnts( filelist_spb )
	String this_spb, this_spe, this_type, use_df, this_df, saveFolder
	saveFolder = GetDataFolder(1)
	if( count == 0 )
		printf "cannot find files\r"; return -1
	endif
	do
		this_spb = filelist_spb[idex]; this_spe = filelist_speMatch[idex]; this_type = filelist_fileType[idex]
		this_df = filelist_desthrDF[idex]; use_df = this_df + ":" + this_type
		
		
		Wave/T/Z destFrame = root:LoadSPE_UI:loadSPE_Frame
		if( WaveExists( destFrame ) != 1 )
			zSPE2_DrawPanel()
			SetDataFolder root:; MakeAndOrSetDF( "LoadSPE_UI" )
			Make/T/N=0/O LoadSPE_Frame; SetDataFolder $saveFolder
			Wave/T destFrame = root:LoadSPE_UI:LoadSPE_Frame
		endif
		zSPE2_LoadTextToFrame( this_spe, destFrame )
		SPE2_ProcFrameAsSPE( destFrame )
		SetDataFolder root:; MakeAndOrSetDF( this_df ); KillDataFolder/Z $use_df 
		DuplicateDataFolder root:LoadSPE_II, $use_df
		zSPE2_UpdateBrowseBits()
		//zSPE2_UpdateSessionWaves(packed_file, path_file)
		
		// Binary Load /B=1 implies low-byte first; /T={4,4} implies double precision in both file and data wave
		
		GBLoadWave /B=1 /T={4,4} /N=BinLoad /Q this_spb
		Wave w = BinLoad0; 
		SPB_ParseInputFile( w )
		//		KillWaves/Z BinLoad0;
		// currently we need to duplicate these to our destination data folder and hook the index
		Wave SPB_Data_Spectrum_matrix = root:SPB_Folder:SPB_Data_Spectrum_matrix
		Wave SPB_TimeStamp_ms = root:SPB_Folder:SPB_TimeStamp_ms
		Wave SPB_TimeStamp = root:SPB_Folder:SPB_TimeStamp
		Wave SPB_TimeDuration = root:SPB_Folder:SPB_TimeDuration
		Wave SPB_Pressure = root:SPB_Folder:SPB_Pressure
		Wave SPB_Temperature = root:SPB_Folder:SPB_Temperature
		Wave SPB_PeakPosition = root:SPB_Folder:SPB_PeakPosition
		Wave SPB_Linewidth = root:SPB_Folder:SPB_Linewidth
	
		SetDataFolder root:; MakeAndOrSetDF( this_df ); MakeAndOrSetDF( use_df )
		Duplicate/O SPB_Data_Spectrum_matrix, $"Data_Spectrum_Matrix"
		Duplicate/O SPB_TimeStamp_ms, $"Timestamp_ms"
		Duplicate/O SPB_TimeStamp, $"TimeStamp"
		Duplicate/O SPB_TimeDuration, $"TimeDuration"
		Duplicate/O SPB_Pressure, $"Pressure"
		Duplicate/O SPB_Temperature, $"Temperature"
		Duplicate/O SPB_PeakPosition, $"PeakPosition"
		Duplicate/O SPB_Linewidth, $"LineWidth"
		
		filelist_spb_begins[idex] = SPB_TimeStamp[0]; filelist_spb_ends[idex] = SPB_TimeStamp[ numpnts( SPB_TimeStamp ) -1]
		SetDataFolder saveFolder
		idex += 1
	while( idex < count )
	
End
Function SPB_DiveDirectory4SPB( top_directory, first_call, layers_to_dive )
	String top_directory
	Variable first_call
	Variable layers_to_dive
	
	// Given that that this function will always be called by SPB_TopSideFileList
	// this may seem redundant, but it is a slightly safer practice to quickly check it here as well.
	if( cmpstr( top_directory, "" ) == 0 )
		NewPath/O/Q/M="Choose directory where spb files are located" dat_LoadPATH
	else
		NewPath/O/Q dat_LoadPATH  top_directory
	endif
	if( V_Flag != 0 )
		printf "aborted, cancelled or failed NewPath\r"; return -1;
	endif

	String saveFolder = GetDataFolder(1)
	SetDataFolder root:; MakeAndOrSetDF( "SPB_Folder" ); SetDataFolder root:
	Wave/T/Z master_list_of_found_spbs = root:SPB_Folder:master_list_of_found_spbs
	
	if( first_call )
		if( WaveExists( master_list_of_found_spbs ) != 1 )
			SetDataFolder root:; MakeandOrSetDF( "SPB_Folder" ); Make/T/N=0/O master_list_of_found_spbs
			SetDataFolder root:; 	Wave/T/Z master_list_of_found_spbs = root:SPB_Folder:master_list_of_found_spbs
		else
			Redimension/N=0 master_list_of_found_spbs
		endif
	endif
	
	Wave/T/Z local_list_of_found_spbs = root:SPB_Folder:local_list_of_found_spbs
	if( WaveExists( local_list_of_found_spbs ) != 1 )
		SetDataFolder root:; MakeandOrSetDF( "SPB_Folder" ); Make/T/N=0/O local_list_of_found_spbs
		SetDataFolder root:; 	Wave/T/Z local_list_of_found_spbs = root:SPB_Folder:local_list_of_found_spbs
	endif
	Wave/T/Z local_list_of_found_dirs = root:SPB_Folder:local_list_of_found_dirs
	if( WaveExists( local_list_of_found_dirs ) != 1 )
		SetDataFolder root:; MakeandOrSetDF( "SPB_Folder" ); Make/T/N=0/O local_list_of_found_dirs
		SetDataFolder root:; 	Wave/T/Z local_list_of_found_dirs = root:SPB_Folder:local_list_of_found_dirs
	endif
	// This is a two step algorithm that needs to use string lists for the various disk objects
	// Part I - Who in this directory is a spb? -- add to my list
	Variable found_files = GFL_FilelistAtOnce( "dat_LoadPATH", 0, local_list_of_found_spbs, ".spb" )
	String found_files_str = "", this_one
	Variable idex = 0, count = numpnts( local_list_of_found_spbs )
	if( count > 0 )
		PathInfo dat_LoadPATH
		do
			sprintf this_one, "%s%s", s_path, local_list_of_found_spbs[idex]
			AppendString( master_list_of_found_spbs, this_one )
			idex += 1
		while( idex < count )
	endif
	if( layers_to_dive == 0 )
		// we need to return now
		SetDataFolder $saveFolder;return 0
	endif
	
	// This is where it gets tricky, since we'll bore down ...
	Variable found_dirs = GFL_Folderlist( "dat_LoadPATH", 0, local_list_of_found_dirs, "????" )
	String found_dirs_str = ""; String this_joined_path
	idex = 0; count = numpnts( local_list_of_found_dirs )
	if( count > 0 )
		//idex = count - 1
		PathInfo dat_LoadPath
		do
			if( first_call )
				found_dirs_str = found_dirs_str + s_path + local_list_of_found_dirs[idex] + ";"
			else
				found_dirs_str = found_dirs_str + top_directory + ":" + local_list_of_found_dirs[idex] + ";"
			endif
			//idex -=1
			idex += 1
			//while( idex >= 0 )
		while( idex < count )
	endif
	idex = 0; count = ItemsInList( found_dirs_str )
	if( count > 0 )
		do
			this_joined_path = StringFromList( idex, found_dirs_str )
			printf "slipping into %s ...\r", this_joined_Path
			if( layers_to_dive == 1 )
				SPB_DiveDirectory4SPB( this_joined_Path, 0, 0 )
			endif
			if( layers_to_dive == 2 )
				SPB_DiveDirectory4SPB( this_joined_Path, 0, 2 )
			endif
			idex += 1
		while( idex < count )
	endif
	SetDataFolder $saveFolder
	
End

Window SPBFileListTable() : Table
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:SPB_Folder:
	Edit/W=(40,44,1024,335) filelist_spb,filelist_speMatch,filelist_filetype,filelist_name_DAT as "SPBFileListTable"
	AppendToTable filelist_spb_begins,filelist_spb_ends
	ModifyTable width(filelist_spb)=144,width(filelist_speMatch)=286,width(filelist_filetype)=52
	ModifyTable format(filelist_name_DAT)=8,width(filelist_name_DAT)=122,format(filelist_spb_begins)=8
	ModifyTable width(filelist_spb_begins)=122,format(filelist_spb_ends)=8,width(filelist_spb_ends)=116
	SetDataFolder fldrSav0
EndMacro

Function SEAtoOH( sea_w, oh_w )
	Wave sea_w, oh_w
	
	Variable degrees_90 = 2e6
	Variable degrees_LT_5 = 8e4
	
	

End

Function QuickAndDirty_ssHCHO( T, OH, J_HCHO )
	Variable T
	Variable OH
	Variable J_HCHO
	
	Variable return_hcho
	
	Variable ch4 = 1.8e-6
	Variable numden = 9.66e18 * 760 / T
	
	return_hcho = (OH * ch4 * numden * 2.45e-12 * exp( -1775/T)  ) / ( J_HCHO + 9.0e-12 * OH )
	
	return_hcho = 1e9 * return_hcho / ( numden )
	
	return return_hcho
	
End
Function ExtractSpectrumAtThisTime( dest_w, atime, SPE_Type )
	Wave dest_w
	Variable atime
	String SPE_Type
	
	String saveFolder = GetDatafolder(1), time_wSTR, dsm_wSTR
	String target_Folder = GetFolderNameForTime( atime, SPE_Type, 0 )
	Variable found_dex, channels
	
	if ( cmpstr( target_Folder, "not_found" ) == 0 )
		dest_w = Nan
		return -1
	endif
	sprintf time_wSTR, "%s:TimeStamp", target_Folder
	sprintf dsm_wSTR, "%s:Data_Spectrum_Matrix", target_Folder
	
	Wave/Z time_w = $time_wSTR
	Wave/Z dsm_w = $dsm_wSTR
	if( WaveExists( time_w ) + WaveExists( dsm_w ) != 2 )
		printf "serious error not finding time and data spectrum matrix in folder %s\r", target_Folder
		return -2
	endif
	
	found_dex = BinarySearch( time_w, atime )
	if( found_dex != -1 )
		if( found_dex == -2 )
			found_dex = numpnts( time_w ) - 1
		endif
		channels = DimSize( dsm_w, 1 )
		Redimension/N=(channels) dest_w
		dest_w = dsm_w[found_dex][p]
		printf "using %d tagged at %s\r", found_dex, Datetime2Text( time_w[found_dex] )
		return 1
	endif
End

Function AverageOverTimeInterval( t1, t2, SPE_Type, dest_w )
	Variable t1, t2
	String SPE_Type
	Wave dest_w
	
	// begin by just going hour by hour
	String start_folder = GetFolderNameForTime( t1, SPE_Type, 0 )
	Variable start_hour = HourFromIgorTime( t1 )
	String end_folder = GetFolderNameForTime( t2, SPE_Type, 0 )
	Variable end_hour = HourFromIgorTime( t2 )
	
	String this_folder = start_folder
	Variable this_hour = start_hour, additional_hours = 0, next_folder = 1
	// we'll be incrementing the hour to jump folders
	
	dest_w = -99
	
	do
	
	
		this_hour = start_hour + additional_hours * 3600
		this_folder = ""
	while( next_folder )
	
End

Function DoSumInOnMatrix( folder, dest_w, count_w, t1, t2 )
	String folder
	Wave dest_w, count_w
	Variable t1, t2
	
	
	if( count_w[0] == 0 )
		// then this dest arriving to us is uninitialized -- an no peak position
		dest_w = 0
	endif
	Wave matrix_w = $( "root:SPB_Folder:" + folder + ":Data_Spectrum_Matrix")
	Wave time_w = $( "root:SPB_Folder:" + folder + ":TimeStamp")
	Wave pressure_w = $( "root:SPB_Folder:" + folder + ":Pressure")
	Wave temperature_w = $( "root:SPB_Folder:" + folder + ":Temperature")
	Wave peakposition_w = $( "root:SPB_Folder:" + folder + ":PeakPosition")
	Wave linewidth_w = $( "root:SPB_Folder:" + folder + ":Linewidth")
	
	
	Variable bdex = BinarySearch( time_w, t1 )	
	Variable edex = BinarySearch( time_w, t2 )
	Variable idex
	
	if( bdex == -1 )
		bdex = 0
	endif
	if( edex == -2 )
		edex = numpnts( time_w ) - 1
	endif
	Redimension/N=(DimSize( matrix_w, 1 )) dest_w, count_w
	if( edex >= bdex )
		for( idex = bdex; idex <= edex; idex += 1 )
			dest_w += matrix_w[idex][p]
			count_w += 1
		endfor
	endif
End

Function RB_BigDo()

	Variable hour_bins = 12
	
	RB_MacroAverage(hour_bins, "diane:users:scott:documents:Aerodyne:RonBrown:raw_data:RB_060727");
	RB_MacroAverage(hour_bins, "diane:users:scott:documents:Aerodyne:RonBrown:raw_data:RB_060728");
	RB_MacroAverage(hour_bins, "diane:users:scott:documents:Aerodyne:RonBrown:raw_data:RB_060729");
	RB_MacroAverage(hour_bins, "diane:users:scott:documents:Aerodyne:RonBrown:raw_data:RB_060730");
	RB_MacroAverage(hour_bins, "diane:users:scott:documents:Aerodyne:RonBrown:raw_data:RB_060731");
	RB_MacroAverage(hour_bins, "diane:users:scott:documents:Aerodyne:RonBrown:raw_data:RB_060801");
	RB_MacroAverage(hour_bins, "diane:users:scott:documents:Aerodyne:RonBrown:raw_data:RB_060801_returnToSample");
	RB_MacroAverage(hour_bins, "diane:users:scott:documents:Aerodyne:RonBrown:raw_data:RB_060801_zoz");
	RB_MacroAverage(hour_bins, "diane:users:scott:documents:Aerodyne:RonBrown:raw_data:RB_060802_HSC");
	RB_MacroAverage(hour_bins, "diane:users:scott:documents:Aerodyne:RonBrown:raw_data:RB_060803_HSC_SB");
	RB_MacroAverage(hour_bins, "diane:users:scott:documents:Aerodyne:RonBrown:raw_data:RB_060804_HSC_BBCut");
	RB_MacroAverage(hour_bins, "diane:users:scott:documents:Aerodyne:RonBrown:raw_data:RB_060806_MBL");
	RB_MacroAverage(hour_bins, "diane:users:scott:documents:Aerodyne:RonBrown:raw_data:RB_060809_Beaumont");
	RB_MacroAverage(hour_bins, "diane:users:scott:documents:Aerodyne:RonBrown:raw_data:RB_060811_TurnBasin");


End

Function RB_MacroAverage(hour_bins, path)
	Variable hour_bins
	String path
	
	SPB_TopSideFileList( path, 0 )
	Wave/T filelist_spb = root:SPB_Folder:filelist_spb
	Wave/T filelist_fileType = root:SPB_Folder:filelist_fileType
	Wave/T filelist_speMatch = root:SPB_Folder:filelist_speMatch
	Wave/T filelist_desthrDF = root:SPB_Folder:filelist_desthrDF
	Wave filelist_spb_begins = root:SPB_Folder:filelist_spb_begins
	Wave filelist_spb_ends = root:SPB_Folder:filelist_spb_ends
	String this_file, this_type, this_match, this_destDF
	Variable this_begins, this_ends
	String this_begins_txt, this_ends_txt
	String saveFolder = GetDataFolder(1); SetDatafolder root:; MakeAndOrSetDF( "root:SPB_Folder" )
	Make/O/N=(numpnts( filelist_spb ) ) filelist_averageFilesWritten
	Make/O/N=(numpnts( filelist_spb ) )/T filelist_averageFilesDirectory
	SetDataFolder $saveFolder
	
	Wave filelist_averageFilesWritten = root:SPB_Folder:filelist_AverageFilesWritten
	Wave/T filelist_averageFilesDirectory = root:SPB_Folder:filelist_averageFilesDirectory
	
	filelist_averageFilesWritten = 0; filelist_averageFilesDirectory = "not set"
	String dest_DIR
	Variable idex = 0, count = numpnts( filelist_spb )
	if( count > 0 )
		do
			this_file = filelist_spb[idex]
			this_type = filelist_fileType[idex]
			this_match = filelist_speMatch[idex]
			this_destDF = filelist_desthrDF[idex]
			
			printf "[%d/%d] == %s as %s\r", idex+1, count, this_file, this_type
			
			RB_LoadThisFile2AvgDir( this_file, this_type, this_match, this_destDF, idex )
			dest_DIR = GetPathNameFromFileOrFP( this_file )
			dest_DIR = dest_DIR + "Average_" + this_type
			printf "Write DIR * %s\r", dest_DIR


			this_begins = filelist_spb_begins[idex]
			this_ends = filelist_spb_ends[idex]
			
			this_begins_txt = Datetime2Text( this_begins )
			this_ends_txt = Datetime2Text( this_ends )
			printf "%s >>> %s ... ", this_begins_txt, this_ends_txt		
			
			
			RB_AverageDataInAvgDir( this_begins, this_ends, dest_DIR, idex, hour_bins )
			
			printf "avg complete (%d files written to %s)\r", filelist_averageFilesWritten[ idex ], filelist_averageFilesDirectory[ idex] 
			
			idex += 1
		while( idex < count )
	endif
End

Function RB_LoadThisFile2AvgDir( file, type, spe_match, destDF, SPB_index )
	String file, type, spe_match, destDF
	Variable SPB_index
	
	// these are unread in the present 'state' and SPB_index can account once the load is done
	Wave filelist_spb_begins = root:SPB_Folder:filelist_spb_begins
	Wave filelist_spb_ends = root:SPB_Folder:filelist_spb_ends
	
	String saveFolder = GetDataFolder(1); SetDataFolder root:SPB_Folder
	
	// 
	//this_df = filelist_desthrDF[idex]; use_df = this_df + ":" + this_type
	String this_df = "root:SPB_Folder:SPB_AverageIncoming"
	
	Wave/T/Z destFrame = root:LoadSPE_UI:loadSPE_Frame
	if( WaveExists( destFrame ) != 1 )
		zSPE2_DrawPanel()
		SetDataFolder root:; MakeAndOrSetDF( "LoadSPE_UI" )
		Make/T/N=0/O LoadSPE_Frame; SetDataFolder $saveFolder
		Wave/T destFrame = root:LoadSPE_UI:LoadSPE_Frame
	endif
	zSPE2_LoadTextToFrame( spe_match, destFrame )
	SPE2_ProcFrameAsSPE( destFrame )
	SetDataFolder root:; KillDataFolder/Z $this_df ; //KillDataFolder/Z $use_df 
	DuplicateDataFolder root:LoadSPE_II, $this_df
	zSPE2_UpdateBrowseBits()
	//zSPE2_UpdateSessionWaves(packed_file, path_file)
		
	// Binary Load /B=1 implies low-byte first; /T={4,4} implies double precision in both file and data wave
	SetDataFolder root:SPB_Folder	
	GBLoadWave /B=1 /T={4,4} /N=BinLoad /Q file
	Wave w = BinLoad0; 
	SPB_ParseInputFile( w )
	KillWaves/Z BinLoad0;
	// currently we need to duplicate these to our destination data folder and hook the index
	Wave SPB_Data_Spectrum_matrix = root:SPB_Folder:SPB_Data_Spectrum_matrix
	Wave SPB_TimeStamp_ms = root:SPB_Folder:SPB_TimeStamp_ms
	Wave SPB_TimeStamp = root:SPB_Folder:SPB_TimeStamp
	Wave SPB_TimeDuration = root:SPB_Folder:SPB_TimeDuration
	Wave SPB_Pressure = root:SPB_Folder:SPB_Pressure
	Wave SPB_Temperature = root:SPB_Folder:SPB_Temperature
	Wave SPB_PeakPosition = root:SPB_Folder:SPB_PeakPosition
	Wave SPB_Linewidth = root:SPB_Folder:SPB_Linewidth
	
	SetDataFolder root:; MakeAndOrSetDF( this_df ); //MakeAndOrSetDF( use_df )
	//		Duplicate/O SPB_Data_Spectrum_matrix, $"Data_Spectrum_Matrix"
	//		Duplicate/O SPB_TimeStamp_ms, $"Timestamp_ms"
	//		Duplicate/O SPB_TimeStamp, $"TimeStamp"
	//		Duplicate/O SPB_TimeDuration, $"TimeDuration"
	//		Duplicate/O SPB_Pressure, $"Pressure"
	//		Duplicate/O SPB_Temperature, $"Temperature"
	//		Duplicate/O SPB_PeakPosition, $"PeakPosition"
	//		Duplicate/O SPB_Linewidth, $"LineWidth"
	//		
	filelist_spb_begins[SPB_index] = SPB_TimeStamp[0]; filelist_spb_ends[SPB_index] = SPB_TimeStamp[ numpnts( SPB_TimeStamp ) -1]
	//
	
	SetDataFolder $saveFolder
	
End

Function RB_LoadThisFile2GeneralDir( file, type, spe_match )
	String file, type, spe_match
		
	String saveFolder = GetDataFolder(1); SetDataFolder root:SPB_Folder
	
	String this_df = "root:SPB_Folder:SPB_GeneralLoad"
	MakeAndOrSetDF( this_df )
	this_df = this_df + ":" + type
	MakeAndOrSetDF( this_df )
	
	// set up the loader browser socket for the spe_match
	Wave/T/Z destFrame = root:LoadSPE_UI:loadSPE_Frame
	if( WaveExists( destFrame ) != 1 )
		zSPE2_DrawPanel()
		SetDataFolder root:; MakeAndOrSetDF( "LoadSPE_UI" )
		Make/T/N=0/O LoadSPE_Frame; SetDataFolder $saveFolder
		Wave/T destFrame = root:LoadSPE_UI:LoadSPE_Frame
	endif
	// use the spe_match
	zSPE2_LoadTextToFrame( spe_match, destFrame )
	SPE2_ProcFrameAsSPE( destFrame )
	SetDataFolder root:; SetDataFolder root:LoadSPE_II
	// we'd like to get stuff from the root:LoadSPE_II directory into our destination
	CopyThisDirectoryToDest( this_df )
	
	zSPE2_UpdateBrowseBits()
		
	// Binary Load /B=1 implies low-byte first; /T={4,4} implies double precision in both file and data wave
	SetDataFolder root:SPB_Folder	
	GBLoadWave /B=1 /T={4,4} /N=BinLoad /Q file
	Wave w = BinLoad0; 
	SPB_ParseInputFile( w )
	KillWaves/Z BinLoad0;
	// currently we need to duplicate these to our destination data folder and hook the index
	Wave SPB_Data_Spectrum_matrix = root:SPB_Folder:SPB_Data_Spectrum_matrix
	Wave SPB_TimeStamp_ms = root:SPB_Folder:SPB_TimeStamp_ms
	Wave SPB_TimeStamp = root:SPB_Folder:SPB_TimeStamp
	Wave SPB_TimeDuration = root:SPB_Folder:SPB_TimeDuration
	Wave SPB_Pressure = root:SPB_Folder:SPB_Pressure
	Wave SPB_Temperature = root:SPB_Folder:SPB_Temperature
	Wave SPB_PeakPosition = root:SPB_Folder:SPB_PeakPosition
	Wave SPB_Linewidth = root:SPB_Folder:SPB_Linewidth
	
	SetDataFolder root:; MakeAndOrSetDF( this_df ); 
	Duplicate/O SPB_Data_Spectrum_matrix, $"Data_Spectrum_Matrix"
	Duplicate/O SPB_TimeStamp_ms, $"Timestamp_ms"
	Duplicate/O SPB_TimeStamp, $"TimeStamp"
	Duplicate/O SPB_TimeDuration, $"TimeDuration"
	Duplicate/O SPB_Pressure, $"Pressure"
	Duplicate/O SPB_Temperature, $"Temperature"
	Duplicate/O SPB_PeakPosition, $"PeakPosition"
	Duplicate/O SPB_Linewidth, $"LineWidth"
	
	SetDataFolder $saveFolder
	
End

Function CopyThisDirectoryToDest( this_df )
	String this_df
	
	String objectName; Variable index = 0
	// type 1 == waves
	do
		objectName = GetIndexedObjName( "", 1, index )
		if( strlen( objectName) == 0 )
			break;
		endif
		Duplicate/O $objectName, $( this_df + ":" + objectName )
		index += 1
	while(1)
	
	do
		objectName = GetIndexedObjName( "", 2, index )
		if( strlen( objectName) == 0 )
			break;
		endif
		NVAR this_var = $objectName
		NVAR/Z dest_var =  $(this_df  + ":" + objectName)
		if( NVAR_Exists( dest_var ) != 1 )
			Variable/G $(this_df  + ":" + objectName)
			NVAR dest_var =  $(this_df  + ":" + objectName)
		endif
		dest_var = this_var
		index += 1
	while(1)
	
	do
		objectName = GetIndexedObjName( "", 3, index )
		if( strlen( objectName) == 0 )
			break;
		endif
		SVAR this_str = $objectName
		SVAR/Z dest_str =  $(this_df  + ":" + objectName)
		if( SVAR_Exists( dest_str) != 1 )
			Variable/G $(this_df  + ":" + objectName)
			SVAR dest_str =  $(this_df  + ":" + objectName)
		endif
		dest_str = this_str
		index += 1
	while(1)
	
End
Function RB_AverageDataInAvgDir( this_begins, this_ends, dest_DIR, SPE_Index, hour_bins )
	Variable this_begins, this_ends
	String dest_DIR
	Variable SPE_index
	Variable hour_bins

	Wave filelist_averageFilesWritten = root:SPB_Folder:filelist_AverageFilesWritten
	Wave/T filelist_averageFilesDirectory = root:SPB_Folder:filelist_averageFilesDirectory

	// needed SPE data
	Wave/T dest_Frame = root:LoadSPE_UI:LoadSPE_Frame
	Wave FrameColumn_1 = root:SPB_Folder:SPB_AverageIncoming:FrameColumn_1
	
	
	// needed SPB data
	
	Wave SPB_Data_Spectrum_matrix = root:SPB_Folder:SPB_Data_Spectrum_matrix
	Wave SPB_TimeStamp_ms = root:SPB_Folder:SPB_TimeStamp_ms
	Wave SPB_TimeStamp = root:SPB_Folder:SPB_TimeStamp
	Wave SPB_TimeDuration = root:SPB_Folder:SPB_TimeDuration
	Wave SPB_Pressure = root:SPB_Folder:SPB_Pressure
	Wave SPB_Temperature = root:SPB_Folder:SPB_Temperature
	Wave SPB_PeakPosition = root:SPB_Folder:SPB_PeakPosition
	Wave SPB_Linewidth = root:SPB_Folder:SPB_Linewidth

	
	Variable scan_length = DimSize( SPB_Data_Spectrum_matrix, 1 )
	Make/O/N=(hour_bins, scan_length )/D SPB_Average_Matrix
	Make/O/N=(hour_bins)/D Average_Count, Average_Pressure, Average_Temperature, Average_Time, Sum_Acquisition
	
	SPB_Average_Matrix = 0
	Average_Count = 0
	Average_Pressure = 0
	Average_Temperature = 0
	Average_Time = 0
	Sum_Acquisition = 0
	
	Variable idex = 0, count = numpnts( SPB_TimeStamp ), jdex, jcount = DimSize( SPB_Data_Spectrum_matrix, 1 )
	Variable now, this_bin, this_minute
	String candidate_filename
	
	do
		now = SPB_TimeStamp[idex]; this_minute = MinuteFromIgorTime( now )
		this_bin = Floor( hour_bins * this_minute / 60 )
		//printf "bin:%d for %s\r", this_bin, Datetime2Text( now )
		
		if( numtype( now ) == 0 )
			Average_Time[this_bin] += now
			for( jdex = 0; jdex < jcount; jdex += 1 )
				SPB_Average_Matrix[this_bin][jdex] += SPB_Data_Spectrum_matrix[idex][jdex]
			endfor
			Average_Pressure[this_bin ] += SPB_Pressure[idex]
			Average_Temperature[this_bin] += SPB_Temperature[idex]
			Average_Count[this_bin] += 1
			
			Sum_Acquisition[ this_bin ] += SPB_TimeDuration[idex]
		endif
		idex += 1
	while( idex < count )
	
	SPB_Average_Matrix[][] /= Average_Count[p]

	//for( jdex = 0; jdex < jcount; jdex += 1 )
	//SPB_Average_Matrix[][jdex] /= Average_Count[p]
	//endfor
	Average_Temperature /= Average_Count
	Average_Pressure /= Average_Count
	Average_Time /= Average_Count
	
	// The most important thing now is to identify the frame we are going into
	
	idex = 0; count = hour_bins
	do
		if( numtype( Average_Time[idex]) == 0 ) 
			// timestamp
			//SPE2_InjectParamIntoFrame( param_name, param_val, frame_tw )
			SPE2_InjectParamIntoFrame( "property - timestamp", 1000*Average_Time[idex], dest_Frame )
			SPE2_InjectParamIntoFrame( "property -  acquistion duration", Sum_Acquisition[idex], dest_Frame )
			// pressure
			SPE2_InjectParamIntoFrame( "cell pressure", Average_Pressure[idex], dest_Frame )
			// temperature
			SPE2_InjectParamIntoFrame( "cell temp", Average_Temperature[idex], dest_Frame )	
	
			// averaged spectrum
			FrameColumn_1 = SPB_Average_Matrix[idex][p]
			SPE2_InjectFiveColumns2Frame(FrameColumn_1 , 1, dest_Frame )
			// number of averages
			
			// new file name
			candidate_filename = SPE2_DateTime2WintelSPEName( Average_Time[idex], "ACT" )
			WriteTextWave2File( dest_Frame, dest_Dir, candidate_filename )
		endif
		idex += 1
	while( idex < count )
	//
End
	
Function RB_UndoRedoBG()
	
	
	SPB_TopSideFileList( "", 0 )
	Wave/T filelist_spb = root:SPB_Folder:filelist_spb
	Wave/T filelist_fileType = root:SPB_Folder:filelist_fileType
	Wave/T filelist_speMatch = root:SPB_Folder:filelist_speMatch
	Wave/T filelist_desthrDF = root:SPB_Folder:filelist_desthrDF
	Wave filelist_spb_begins = root:SPB_Folder:filelist_spb_begins
	Wave filelist_spb_ends = root:SPB_Folder:filelist_spb_ends
	
	// The parse and digest call in TopSideFileList makes
	// these association _a_ waves that allegedly will give the spb that matches each SIG
	//	Make/N=0/O/T filelist_a_SIG, filelist_a_PN, filelist_a_BG, filelist_a_REF
	Wave/T filelist_a_SIG = root:SPB_Folder:filelist_a_SIG
	Wave/T filelist_a_PN = root:SPB_Folder:filelist_a_PN
	Wave/T filelist_a_BG = root:SPB_Folder:filelist_a_BG
	Wave/T filelist_a_REF = root:SPB_Folder:filelist_a_REF
	
	String this_file, this_type, this_match, this_destDF
	Variable this_begins, this_ends
	String this_begins_txt, this_ends_txt
	String saveFolder = GetDataFolder(1); SetDatafolder root:; MakeAndOrSetDF( "root:SPB_Folder" )
	Make/O/N=(numpnts( filelist_spb ) ) filelist_averageFilesWritten
	Make/O/N=(numpnts( filelist_spb ) )/T filelist_averageFilesDirectory
	SetDataFolder $saveFolder
	
	Wave filelist_averageFilesWritten = root:SPB_Folder:filelist_AverageFilesWritten
	Wave/T filelist_averageFilesDirectory = root:SPB_Folder:filelist_averageFilesDirectory
	
	filelist_averageFilesWritten = 0; filelist_averageFilesDirectory = "not set"
	String dest_DIR, this_a_PN, this_a_BG, this_a_REF
	Variable idex = 0, count = numpnts( filelist_a_SIG ), found_master, jdex = 0, jcount = numpnts( filelist_spb )
	Variable pn_master, bg_master, ref_master
	Variable kdex = 0, kcount, use_bg_index, Avg_BG_ZeroOffset, This_BG_ZeroOffset
	
	String candidate_filename;
	
	if( count > 0 )
		do
			this_file = filelist_a_SIG[idex]
	
			// First look up this a_SIG file in the master listing, to harness other stuff from that index
			found_master =  -1;
			for( jdex = 0; jdex < jcount; jdex += 1 )
				if( cmpstr( filelist_spb[jdex], this_file ) == 0 )
					found_master = jdex
					jdex = jcount
				endif
			endfor
			if( found_master != -1 ) 
				this_file = filelist_spb[found_master]
				this_type = filelist_fileType[found_master]
				this_match = filelist_speMatch[found_master]
				this_destDF = filelist_desthrDF[found_master]
				this_a_PN = filelist_a_PN[ idex]
				this_a_BG = filelist_a_BG[ idex]
				this_a_REF = filelist_a_REF[ idex]
				
				pn_master = FindStringInWave( this_a_PN, filelist_spb, 0 )
				bg_master = FindStringInWave( this_a_BG, filelist_spb, 0 )
				ref_master = FindStringInWave( this_a_REF, filelist_spb, 0 )
				
				
				printf " === UndoRedoBG : [%d/%d] == \r",  idex+1, count
				if( (pn_master >= 0 ) & ( bg_master >= 0 ) & (ref_master >= 0 ) )
					printf "[SIG]: %s [PN]: %s [BG]: %s [REF]: %s\r", GetFileNameFromFileorFP(this_file), GetFileNameFromFileorFP( this_a_PN ), GetFileNameFromFileorFP( this_a_BG ), GetFileNameFromFileorFP( this_a_REF )
				
				
					RB_LoadThisFile2GeneralDir( this_file, this_type, this_match )
					RB_LoadThisFile2GeneralDir( this_a_PN, "PN", filelist_speMatch[ pn_master ] )
					RB_LoadThisFile2GeneralDir( this_a_BG, "BG", filelist_speMatch[ bg_master ] )
					RB_LoadThisFile2GeneralDir( this_a_REF, "REF", filelist_speMatch[ ref_master ] )
				 
					// Average The BG
					Wave bg_TimeStamp = root:SPB_Folder:SPB_GeneralLoad:BG:TimeStamp
					Wave bg_dataMatrix = root:SPB_Folder:SPB_GeneralLoad:BG:Data_Spectrum_Matrix
					Make/N=(DimSize( bg_dataMatrix, 1 ))/D/O root:SPB_Folder:SPB_GeneralLoad:Avg_BG
					Wave Avg_BG = root:SPB_Folder:SPB_GeneralLoad:Avg_BG
					Avg_BG = 0
					kdex = 0; kcount = DimSize( bg_dataMatrix, 0 )
					do
						Avg_BG += bg_dataMatrix[kdex][p]
						kdex += 1
					while( kdex < kcount )
					Avg_BG /= kcount
				 	
					// now we need to offset this average_BG spectrum, best to use SPEII tools.
					Wave/D FrameColumn_1 = root:LoadSPE_II:FrameColumn_1
					FrameColumn_1 = Avg_BG[p]
					Wave foo_w = root:LoadSPE_II:wb1_spectrum
					Avg_BG_ZeroOffset = SPE2_ZeroMarkerMeanOrMenu_IZero( foo_w, foo_w, foo_w, foo_w )
					Avg_BG -= Avg_BG_ZeroOffset
					//SPE2_InjectFiveColumns2Frame(FrameColumn_1 , 1, dest_Frame )
					// number of averages
					Wave sig_TimeStamp = root:SPB_Folder:SPB_GeneralLoad:SIG:TimeStamp
					Wave sig_dataMatrix = root:SPB_Folder:SPB_GeneralLoad:SIG:Data_Spectrum_Matrix
					kdex = 0; kcount = DimSize( sig_dataMatrix, 0 )
				 	
					// Undo each SPE
					Duplicate/O sig_dataMatrix, sig_UnBG_dataMatrix, sig_ReBG_dataMatrix
				 	
					// reprime the loadSPEII directories with a fresh spe file
					Wave/T dest_Frame = root:LoadSPE_UI:LoadSPE_Frame
					zSPE2_LoadTextToFrame( this_match, dest_Frame )
					SPE2_ProcFrameAsSPE( dest_Frame )	
					do
						use_bg_index = BinarySearch( bg_TimeStamp, sig_TimeStamp[kdex] )
						if( use_bg_index <= 0 )
				 			
							//  normalize the signal
							sig_UnBG_dataMatrix[kdex][] /= 1000;
							
							//  subtract the  offset in the instantaneous BG
							Wave/D FrameColumn_1 = root:LoadSPE_II:FrameColumn_1
							FrameColumn_1 = bg_dataMatrix[use_bg_index][p]
							Wave foo_w = root:LoadSPE_II:wb1_spectrum
							This_BG_ZeroOffset = SPE2_ZeroMarkerMeanOrMenu_IZero( foo_w, foo_w, foo_w, foo_w )
							bg_dataMatrix[use_bg_index][] -= This_BG_ZeroOffset
							
							// calculate UnBG data
							sig_UnBG_dataMatrix[kdex][] *= bg_dataMatrix[use_bg_index][q];
				 			 
							sig_ReBG_dataMatrix[kdex][] = numtype( Avg_BG[q] ) == 0 ? 1000 *  sig_UnBG_dataMatrix[kdex][q] / Avg_BG[q] : 0
				 			
							// This is a nice spectrum, we should write it out to a refittable spe file...
				 			
							FrameColumn_1 = sig_ReBG_dataMatrix[kdex][p];
							Wave/T dest_Frame = root:LoadSPE_UI:LoadSPE_Frame
							SPE2_InjectFiveColumns2Frame(FrameColumn_1 , 1, dest_Frame )
							// and write dest_Frame to text file
							dest_DIR = GetPathNameFromFileOrFP( this_file ) + ":Redo_UndoBG"
							candidate_filename = SPE2_DateTime2WintelSPEName( sig_TimeStamp[kdex], "SIG" )
							WriteTextWave2File( dest_Frame, dest_Dir, candidate_filename )
						endif
						kdex += 1
					while( kdex < kcount )
				else
					printf "trouble locating one or more of the BG, PN or REF sets"
				endif
				 
				//RB_LoadThisFile2AvgDir( this_file, this_type, this_match, this_destDF, idex )
				//dest_DIR = GetPathNameFromFileOrFP( this_file )
				//dest_DIR = dest_DIR + "NewBG_" + this_type
				//printf "Write DIR * %s\r", dest_DIR


				//this_begins = filelist_spb_begins[idex]
				//this_ends = filelist_spb_ends[idex]
			
				//this_begins_txt = Datetime2Text( this_begins )
				//this_ends_txt = Datetime2Text( this_ends )
				//printf "%s >>> %s ... ", this_begins_txt, this_ends_txt		
			
			
				//				RB_AverageDataInAvgDir( this_begins, this_ends, dest_DIR, idex, hour_bins )
			
				//printf "avg complete (%d files written to %s)\r", filelist_averageFilesWritten[ idex ], filelist_averageFilesDirectory[ idex] 
			
			else
				// found_master == -1
				printf "in BGUndoRedo with failed found master %d - %s\r", idex, this_file
			endif
			idex += 1
		while( idex < count )
	endif
End

Function SlapAllSpectraOnGraph( w )
	Wave w
	
	Variable idex = 0, count = DimSize( w, 0 )
	Display
	do
		AppendToGraph w[idex][]
		idex += 1
	while( idex < count )
End
Function/T GetFolderNameForTime( atime, SPE_Type, liberal )
	Variable atime
	String SPE_Type
	Variable liberal
		
	String found_FolderName = "not_found"
	String saveFolder = GetDataFolder(1), full_folder
	SetDataFolder root:SPB_Folder; 
	String spb_folder_list 
	Variable found_dex, idex, count, last_chance_hour
	String time_wSTR
	String this_folder, fabdathour
	// shoot for the moon
	String year_str = AddLeadingZeroToBase10( num2str(YearFromIgorTime( atime )), 2 )
	String month_str = AddLeadingZeroToBase10( num2str(MonthFromIgorTime( atime )), 2 )
	String day_str = AddLeadingZeroToBase10( num2str(DayFromIgorTime( atime )), 2 )
	String hour_str = AddLeadingZeroToBase10( num2str(HourFromIgorTime( atime )), 2 )
	sprintf fabdathour, "%s%s%s_%s", year_str, month_str, day_str, hour_str
	Variable CountUpHour 
	sprintf full_folder, "root:SPB_Folder:SPB_%s:%s", fabdathour, SPE_Type
	sprintf time_wSTR , "%s:TimeStamp", full_folder

	// shooting for the moon
	Wave/Z time_w = $time_wSTR
	if( WaveExists( time_w ) )
		found_dex = BinarySearch( time_w, atime )
		if( found_dex != -1 )
			if( found_dex != -2 )
				sprintf found_FolderName, full_folder
				SetDataFolder $saveFolder
				return found_FolderName
			else
				// so found dex is -2 , but we dialed this in, so just pass last value
				found_dex = numpnts( time_w ) - 1
				sprintf found_FolderName, full_folder
				SetDataFolder $saveFolder
				return found_FolderName				// THIS IS AN EARLY EASY EXIT
			endif
		endif
	endif
		
	// seach bit by bit -- if not already found
	spb_folder_list = StringByKey( "FOLDERS", DataFolderDir( 1 ) )
	count = ItemsInList( spb_folder_list , ",")
	for( idex = 0; idex < count; idex += 1 )
		this_folder = StringFromList( idex, spb_folder_list, "," )
		//print this_folder

		sprintf full_folder, "root:SPB_Folder:%s:%s", this_folder, SPE_Type
		sprintf time_wSTR , "%s:TimeStamp", full_folder
		Wave/Z time_w = $time_wSTR
		if( WaveExists( time_w ) )
			found_dex = BinarySearch( time_w, atime )
			if( found_dex != -1 )
				if( found_dex != -2 )
					sprintf found_FolderName, full_folder
					idex = count;
				else
					// so found dex is -2 , must test
					last_chance_hour = HourFromIgorTime( atime )
					CountUpHour =  str2num( StringFromList( 2, this_folder, "_" ) );
					if( last_chance_hour == CountUpHour+liberal )
						sprintf found_FolderName, full_folder
						idex = count;
					endif
				endif
			endif
		endif
	endfor
	SetDataFolder $saveFolder
	
	return found_FolderName
End

Function MinuteFromIgorTime( atime )
	Variable atime
	return str2num( StringFromList( 1, Secs2time( atime, 3 ), ":" ) )
End
Function HourFromIgorTime( atime )
	Variable atime
	return str2num( StringFromList( 0, Secs2time( atime, 3 ), ":" ) )
End
Function DayFromIgorTime( atime )
	Variable atime
	return str2num( StringFromList( 1, Secs2Date( atime, 0 ), "/" ) )
End
Function MonthFromIgorTime( atime )
	Variable atime
	return str2num( StringFromList( 0, Secs2Date( atime, 0 ), "/" ) )
End
Function YearFromIgorTime( atime )
	Variable atime
	return str2num( StringFromList( 2, Secs2Date( atime, 0 ), "/" ) )
End
Function CutSecondsFromSecs( atime )
	Variable atime
	
	String date_str = StringFromList( 0, Secs2Date( atime, -1 ), " " )
	String time_str = Secs2Time( atime, 3 )
	
	Variable yr = str2num( StringFromList( 2, date_str , "/" ) ) 
	Variable mon = str2num( StringFromList( 1, date_str , "/" ) )
	Variable day = str2num( StringFromList( 0, date_str , "/" ) )
	Variable minute = str2num( StringFromList( 1, time_str , ":" ) )
	Variable hour = str2num( StringFromList( 0, time_str , ":" ) )
	
	return Date2Secs( yr, mon, day ) + 3600 * hour + 60 * minute
End
////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////
//////////////////////// STR, STC, CAL - mix and chop for any long campaign /////////////////////
////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////

// str, stc & cal loaded into root -- always with the bookmark 
// we will put str, stc and cal into orgainzed little folders?

Function QA_MasterInput( begin_time, end_time, note_txt )
	Variable begin_time
	Variable end_time
	String note_txt
	
	String fp2myQAMaster = "diane:users:scott:documents:aerodyne:ronbrown:analysis_results:RB06_QAMaster.itx"
	// "c:field data:ron bron:drop_4MarkZ:RB06_QAMaster.itx"
	// KillWaves/Z doesn't work on Mark's Computer...
	String saveFolder = GetDataFolder(1); SetDataFolder root:; MakeAndOrSetDF( "a_QAMaster" );
	if( FileExistsFullPath( fp2myQAMaster ) != 0 )	
		Make/N=0/D/O QA_EndTime, QA_BeginTime
		Make/N=0/T/O QA_Note_tw
	else
		LoadWave/T/Q/O fp2myQAMaster
	endif
	Wave/T QA_Note_tw = QA_Note_tw
	Wave/D QA_EndTime = QA_EndTime
	Wave/D QA_BeginTime = QA_BeginTime
	
	AppendVal( QA_BeginTime, begin_time )
	AppendVal( QA_EndTime, end_time )
	AppendString( QA_Note_tw, note_txt )
	
	Sort QA_BeginTime, QA_BeginTime, QA_EndTime, QA_Note_tw
	
	Make/N=(1 + 4*numpnts( QA_BeginTime) )/D/O QA_VisualTime, QA_VisualMask
	Variable idex, count = numpnts( QA_BeginTime )
	QA_VisualTime[0] = Text2DateTime( "7/26/2006 00:00:00" ); QA_VisualMask[0] = 0
	for( idex = 0; idex < count; idex += 1 )
		QA_VisualTime[4*idex + 1] = QA_BeginTime[idex]; 
		QA_VisualMask[4*idex+1] = 0;
		QA_VisualTime[4*idex + 2] = QA_BeginTime[idex]; 
		QA_VisualMask[4*idex+2] = 1;
		QA_VisualTime[4*idex + 3] = QA_EndTime[idex]; 
		QA_VisualMask[4*idex+3] = 1;
		QA_VisualTime[4*idex + 4] = QA_EndTime[idex]; 
		QA_VisualMask[4*idex+4] = 0;
	endfor
	String list = "root:a_QAMaster:QA_Note_tw;root:a_QAMaster:QA_EndTime;root:a_QAMaster:QA_BeginTime;"
	
	
	Save/O/T/B list as fp2myQAMaster
	SetDataFolder $saveFolder; 
	
End
Function QA_MasterInputMC06( begin_time, end_time, note_txt )
	Variable begin_time
	Variable end_time
	String note_txt
	
	String fp2myQAMaster = "diane:users:scott:documents:aerodyne:aerodyne mobile lab:MCMA_2006:RB06_QAMaster.itx"
	// "c:field data:ron bron:drop_4MarkZ:RB06_QAMaster.itx"
	// KillWaves/Z doesn't work on Mark's Computer...
	String saveFolder = GetDataFolder(1); SetDataFolder root:; MakeAndOrSetDF( "a_QAMaster" );
	if( FileExistsFullPath( fp2myQAMaster ) != 0 )	
		Make/N=0/D/O QA_EndTime, QA_BeginTime
		Make/N=0/T/O QA_Note_tw
	else
		LoadWave/T/Q/O fp2myQAMaster
	endif
	Wave/T QA_Note_tw = QA_Note_tw
	Wave/D QA_EndTime = QA_EndTime
	Wave/D QA_BeginTime = QA_BeginTime
	
	AppendVal( QA_BeginTime, begin_time )
	AppendVal( QA_EndTime, end_time )
	AppendString( QA_Note_tw, note_txt )
	
	Sort QA_BeginTime, QA_BeginTime, QA_EndTime, QA_Note_tw
	
	Make/N=(1 + 4*numpnts( QA_BeginTime) )/D/O QA_VisualTime, QA_VisualMask
	Variable idex, count = numpnts( QA_BeginTime )
	QA_VisualTime[0] = Text2DateTime( "7/26/2006 00:00:00" ); QA_VisualMask[0] = 0
	for( idex = 0; idex < count; idex += 1 )
		QA_VisualTime[4*idex + 1] = QA_BeginTime[idex]; 
		QA_VisualMask[4*idex+1] = 0;
		QA_VisualTime[4*idex + 2] = QA_BeginTime[idex]; 
		QA_VisualMask[4*idex+2] = 1;
		QA_VisualTime[4*idex + 3] = QA_EndTime[idex]; 
		QA_VisualMask[4*idex+3] = 1;
		QA_VisualTime[4*idex + 4] = QA_EndTime[idex]; 
		QA_VisualMask[4*idex+4] = 0;
	endfor
	String list = "root:a_QAMaster:QA_Note_tw;root:a_QAMaster:QA_EndTime;root:a_QAMaster:QA_BeginTime;"
	
	
	Save/O/T/B list as fp2myQAMaster
	SetDataFolder $saveFolder; 
	
End


Function MC06_AverageThisPair( source_time, source_data, dest_data_str, filter_lo )
	Wave  source_time, source_data
	String dest_data_str
	Variable filter_lo
	
	
	Duplicate/O source_data, filter_source_data, mask_source_data
	
	Wave/T QA_Note_tw = root:a_QAMaster:QA_Note_tw
	Wave/D QA_EndTime = root:a_QAMaster:QA_EndTime
	Wave/D QA_BeginTime = root:a_QAMaster:QA_BeginTime
	
	Duplicate/O source_data, filter_source_data, mask_source_data

	Variable idex = 0, count = numpnts( QA_BeginTime ), bdex, edex
	mask_source_data = 1
	do
		bdex = BinarySearch( source_time, QA_BeginTime[idex] )
		edex = Binarysearch( source_time, QA_EndTime[idex] )
		
		if( (bdex >= 0 ) && (edex >= 0 ) )
			mask_source_data[bdex, edex ] = Nan
		endif
		
		idex += 1
	while( idex < count )
	idex = 0; count = numpnts( source_data )
	do
		if( source_data[idex] < filter_lo )
			mask_source_data[idex] = nan
		endif
		idex += 1
	while( idex < count )
	filter_source_data *= mask_source_data
	
	Duplicate/O filter_source_data, $( "root:" + dest_data_str )

End


Function MCMA06_AverageInFolder(prefix)
	String prefix
	
	Wave time_w = root:min1:source_atime
	Wave hcho_w = root:min1:mr_3
	Wave c2h4_w = root:min1:mr_1
	Wave nh3_w = root:min1:mr_2
	Wave hno3_w = root:min1:mr_4
	Wave chocho_w = root:min1:mr_5
	Wave hono_w = root:min1:mr_6

	Wave hcooh_w = str_mr2
	Wave uncorNH3_w = str_mr4
	Wave c2h4_w = str_mr5
	
	WaveStats/Q time_w
	Variable first_time = v_min
	Variable last_time = v_max
	
	Variable first_min = CutSecondsFromSecs( first_time )
	Variable last_min = CutSecondsFromSecs( last_time )
	
	printf "From %s to %s\r", DateTime2Text( first_min ), DateTime2Text( last_min )
	Make/N=((last_min - first_min)/60 + 1)/D/O pilot_average
	SetScale/P x, first_min, 60, "dat", pilot_average
	
	Duplicate/O pilot_average, $(prefix + "_UTC_Time" )
	Wave loc_dest_time =  $(prefix + "_UTC_Time" )
	loc_dest_time = x
	SetScale/P y, 0,0, "dat", loc_dest_time
	Duplicate/O pilot_average, $(prefix + "_HCHO" )
	Wave loc_hcho = $(prefix + "_HCHO" )
	RonBrown_AverageThisPair( time_w, hcho_w, loc_dest_time, loc_hcho )
	
	Duplicate/O pilot_average, $(prefix + "_HCOOH" )
	Wave loc_hcooh = $(prefix + "_HCOOH" )
	RonBrown_AverageThisPair( time_w, hcooh_w, loc_dest_time, loc_hcooh )
	
	Duplicate/O pilot_average, $(prefix + "_Uncorrected_NH3" )
	Wave loc_nh3 = $(prefix + "_Uncorrected_NH3" )
	RonBrown_AverageThisPair( time_w, uncorNH3_w, loc_dest_time, loc_nh3 )
	
	Duplicate/O pilot_average, $(prefix + "_Uncorrected_C2H4" )
	Wave loc_c2h4 = $(prefix + "_Uncorrected_C2H4" )
	RonBrown_AverageThisPair( time_w, c2h4_w, loc_dest_time, loc_c2h4 )
	
	String fileName = prefix + "_1MinPak.itx"
	String search = prefix + "*", list = WaveList( search, ";", "" )
	Save/T/B list as fileName
End


Function RonBrown_AverageOnGCSchedule( prefix )
	String prefix 
	Wave time_w = str_source_rtime
	Wave hcho_w = str_mr1
	Wave hcooh_w = str_mr2
	Wave uncorNH3_w = str_mr4
	Wave c2h4_w = str_mr5
	
	WaveStats/Q time_w
	Variable first_time = v_min
	Variable last_time = v_max
	
	Variable first_min = CutSecondsFromSecs( first_time )
	Variable last_min = CutSecondsFromSecs( last_time )
	
	// set for bill
	first_min = Text2DateTime( "7/26/2006 18:00:00" )
	
	printf "From %s to %s\r", DateTime2Text( first_min ), DateTime2Text( last_min )
	Make/N=((last_min - first_min)/(60*30) + 1)/D/O pilot_average
	SetScale/P x, first_min, 60*30, "dat", pilot_average
	
	Duplicate/O pilot_average, $(prefix + "_UTC_Time" )
	Wave loc_dest_time =  $(prefix + "_UTC_Time" )
	loc_dest_time = x
	SetScale/P y, 0,0, "dat", loc_dest_time
	//	Duplicate/O pilot_average, $(prefix + "_HCHO" )
	//	Wave loc_hcho = $(prefix + "_HCHO" )
	//	RonBrown_AverageThisPair( time_w, hcho_w, loc_dest_time, loc_hcho )
	//	
	//	Duplicate/O pilot_average, $(prefix + "_HCOOH" )
	//	Wave loc_hcooh = $(prefix + "_HCOOH" )
	//	RonBrown_AverageThisPair( time_w, hcooh_w, loc_dest_time, loc_hcooh )
	//	
	//	Duplicate/O pilot_average, $(prefix + "_Uncorrected_NH3" )
	//	Wave loc_nh3 = $(prefix + "_Uncorrected_NH3" )
	//	RonBrown_AverageThisPair( time_w, uncorNH3_w, loc_dest_time, loc_nh3 )
	
	Duplicate/O pilot_average, $(prefix + "_Uncorrected_C2H4" )
	Wave loc_c2h4 = $(prefix + "_Uncorrected_C2H4" )
	RonBrown_AverageThisPairTACOH( time_w, c2h4_w, loc_dest_time, loc_c2h4 )
	
	String fileName = prefix + "_TacohTimePak.itx"
	String search = prefix + "*", list = WaveList( search, ";", "" )
	Save/T/B list as fileName

End
Function RonBrown_AverageInRoot(prefix)
	String prefix
	
	Wave time_w = str_source_rtime
	Wave hcho_w = str_mr1
	Wave hcooh_w = str_mr2
	Wave uncorNH3_w = str_mr4
	Wave c2h4_w = str_mr5
	
	WaveStats/Q time_w
	Variable first_time = v_min
	Variable last_time = v_max
	
	Variable first_min = CutSecondsFromSecs( first_time )
	Variable last_min = CutSecondsFromSecs( last_time )
	
	printf "From %s to %s\r", DateTime2Text( first_min ), DateTime2Text( last_min )
	Make/N=((last_min - first_min)/60 + 1)/D/O pilot_average
	SetScale/P x, first_min, 60, "dat", pilot_average
	
	Duplicate/O pilot_average, $(prefix + "_UTC_Time" )
	Wave loc_dest_time =  $(prefix + "_UTC_Time" )
	loc_dest_time = x
	SetScale/P y, 0,0, "dat", loc_dest_time
	Duplicate/O pilot_average, $(prefix + "_HCHO" )
	Wave loc_hcho = $(prefix + "_HCHO" )
	RonBrown_AverageThisPair( time_w, hcho_w, loc_dest_time, loc_hcho )
	
	Duplicate/O pilot_average, $(prefix + "_HCOOH" )
	Wave loc_hcooh = $(prefix + "_HCOOH" )
	RonBrown_AverageThisPair( time_w, hcooh_w, loc_dest_time, loc_hcooh )
	
	Duplicate/O pilot_average, $(prefix + "_Uncorrected_NH3" )
	Wave loc_nh3 = $(prefix + "_Uncorrected_NH3" )
	RonBrown_AverageThisPair( time_w, uncorNH3_w, loc_dest_time, loc_nh3 )
	
	Duplicate/O pilot_average, $(prefix + "_Uncorrected_C2H4" )
	Wave loc_c2h4 = $(prefix + "_Uncorrected_C2H4" )
	RonBrown_AverageThisPair( time_w, c2h4_w, loc_dest_time, loc_c2h4 )
	
	String fileName = prefix + "_1MinPak.itx"
	String search = prefix + "*", list = WaveList( search, ";", "" )
	Save/T/B list as fileName
End

Function RonBrown_AverageThisPair( source_time, source_data, dest_time, dest_data )
	Wave  source_time, source_data, dest_time, dest_data
	
	Duplicate/O source_data, filter_source_data, mask_source_data
	
	Wave/T QA_Note_tw = root:a_QAMaster:QA_Note_tw
	Wave/D QA_EndTime = root:a_QAMaster:QA_EndTime
	Wave/D QA_BeginTime = root:a_QAMaster:QA_BeginTime
	
	Variable idex = 0, count = numpnts( QA_BeginTime ), bdex, edex
	mask_source_data = 1
	do
		bdex = BinarySearch( source_time, QA_BeginTime[idex] )
		edex = Binarysearch( source_time, QA_EndTime[idex] )
		
		if( (bdex >= 0 ) && (edex >= 0 ) )
			mask_source_data[bdex, edex ] = Nan
		endif
		
		idex += 1
	while( idex < count )
	
	filter_source_data *= mask_source_data
	
	
	idex = 0; count = numpnts( dest_time )
	do
		
		if( MinuteFromIgorTime( dest_time[idex] )!= 0 )
			bdex = BinarySearch( source_time, dest_time[idex] )
			edex = Binarysearch( source_time,  dest_time[idex + 1])  // this means we are averaging 'forward'
		
			Wavestats/Q/R=[bdex, edex] filter_source_data
			if( v_npnts > 2 )
				dest_data[idex] = v_avg
			else
				dest_data[idex] = Nan
			endif
		else
			dest_data[idex] = Nan
		endif
		idex += 1
	while( idex < count )
End



Function RonBrown_AverageThisPairTACOH( source_time, source_data, dest_time, dest_data )
	Wave  source_time, source_data, dest_time, dest_data
	
	Duplicate/O source_data, filter_source_data, mask_source_data
	
	Wave/T QA_Note_tw = root:a_QAMaster:QA_Note_tw
	Wave/D QA_EndTime = root:a_QAMaster:QA_EndTime
	Wave/D QA_BeginTime = root:a_QAMaster:QA_BeginTime
	
	Variable idex = 0, count = numpnts( QA_BeginTime ), bdex, edex
	mask_source_data = 1
	do
		bdex = BinarySearch( source_time, QA_BeginTime[idex] )
		edex = Binarysearch( source_time, QA_EndTime[idex] )
		
		if( (bdex >= 0 ) && (edex >= 0 ) )
			mask_source_data[bdex, edex ] = Nan
		endif
		
		idex += 1
	while( idex < count )
	
	filter_source_data *= mask_source_data
	
	
	idex = 0; count = numpnts( dest_time )
	do
		
		
		bdex = BinarySearch( source_time, dest_time[idex] )
		edex = Binarysearch( source_time,  dest_time[idex] + 5*60)  // this means we are averaging 'forward'
		
		Wavestats/Q/R=[bdex, edex] filter_source_data
		if( v_npnts > 10 )
			dest_data[idex] = v_avg
		else
			dest_data[idex] = Nan
		endif
		
		idex += 1
	while( idex < count )
End

Function EvenHour( datetime_val )
	Variable datetime_val
	
	Variable hr = HourFromIgorTime( datetime_val )
	
	Variable half = hr/2
	
	if( half == floor( half ) )
		return 1
	else
		return 0
	endif
End	
	
Function DetectAndAverageCals( time_w, data_w, start_time, end_time, destName, secsToAvg )
	Wave time_w, data_w
	Variable start_time, end_time
	String destName
	Variable secsToAvg
	Variable threshold = 10
	// DetectAndAverageCals( cal_source_rtime, cal_mr1, Text2DateTime( "8/8/2006 15:00" ), Text2DateTime( "8/8/2006 15:00" ), 120 )
	
	Make/N=0/O/D into_nan_start_times, out_of_nan_end_times
	Variable bdex = 1 + BinarySearch( time_w, start_time )
	Variable now_time = start_time
	Variable gap, condition = 0
	do
		bdex = BinarySearch( time_w, now_time ) + 1
		gap = (time_w[ bdex ] - time_w[bdex-1] )
		if( (gap > threshold) & (condition == 0) ) 
			AppendVal( into_nan_start_times, bdex )
			condition = 1
		endif	
		if( (gap < threshold) & (condition == 1) ) 
			AppendVal( out_of_nan_end_times, bdex )
			condition = 0
		endif		
		now_time += 1
	while( now_time < end_time )
	
End
	
	
Function SPB_CompactAllBG()
		
	// function to loop through all found
	// SPB_<> datafolderssssss pull together 
	// 
		
	String list = "PeakPosition;Pressure;Temperature;TimeStamp;"
	Variable currow, curcol, idex, count, jdex, jcount, kdex, kcount, dfrStatus;
	Variable drow, dcol
		
	String folder_list, this_folder, src_wave;
		
	SetDataFolder root:SPB_Folder
	folder_list = StringByKey( "FOLDERS", DataFolderDir( 1 ))
		
	Make/N=(0,0)/D/O Collected_BG
	Make/N=0/D/O Col_BGPressure, Col_BGTemperature, Col_BGTimeStamp
		
	count = ItemsInList( foldeR_list, "," )
	for( idex = 0; idex < count;idex += 1 )
		sprintf this_folder, "root:SPB_Folder:%s:BG", StringFromList( idex, folder_list, ",")
		DFREF dfr = $this_folder
		dfrStatus = DataFolderRefStatus( dfr )
		if( dfrStatus != 0 )
			SetDataFolder $this_folder
			Wave d = data_spectrum_matrix
			currow = DimSize( d, 0 );			curcol = DimSize( d, 1 )
			drow = DimSize( Collected_BG, 0);	dcol = DimSize( Collected_BG, 1 )
			Redimension/N=( currow + drow, curcol ) Collected_BG

			for( jdex = 0; jdex < curcol; jdex += 1 )
				Collected_BG[drow+jdex][] = d[jdex][q]
			endfor
				
			Wave tw = Temperature
			Wave pw = Pressure
			Wave timew = TimeStamp
				
			kcount = numpnts( tw )
			for( kdex = 0; kdex < kcount; kdex += 1 )
				AppendVal( Col_BGPressure, pw[kdex] );
				AppendVal( Col_BGTemperature, tw[kdex] );
				AppendVal( Col_BGTimeStamp, timew[kdex] );					
			endfor	
			print this_folder
		endif
	endfor
		
	
	
End

	
Function SPB_CompactAllSig()
		
	// function to loop through all found
	// SPB_<> datafolderssssss pull together 
	// 
		
	String list = "PeakPosition;Pressure;Temperature;TimeStamp;"
	Variable currow, curcol, idex, count, jdex, jcount, kdex, kcount, dfrStatus;
	Variable drow, dcol
		
	String folder_list, this_folder, src_wave;
		
	SetDataFolder root:SPB_Folder
	folder_list = StringByKey( "FOLDERS", DataFolderDir( 1 ))
		
	Make/N=(0,0)/D/O Collected_Sig
	Make/N=0/D/O Col_Pressure, Col_Temperature, Col_TimeStamp
		
	count = ItemsInList( foldeR_list, "," )
	for( idex = 0; idex < count;idex += 1 )
		sprintf this_folder, "root:SPB_Folder:%s:SIG", StringFromList( idex, folder_list, ",")
		DFREF dfr = $this_folder
		dfrStatus = DataFolderRefStatus( dfr )
		if( dfrStatus != 0 )
			SetDataFolder $this_folder
			Wave d = data_spectrum_matrix
			currow = DimSize( d, 0 );			curcol = DimSize( d, 1 )
			drow = DimSize( Collected_Sig, 0);	dcol = DimSize( Collected_Sig, 1 )
			Redimension/N=( currow + drow, curcol ) Collected_Sig

			for( jdex = 0; jdex < curcol; jdex += 1 )
				Collected_Sig[drow+jdex][] = d[jdex][q]
			endfor
				
			Wave tw = Temperature
			Wave pw = Pressure
			Wave timew = TimeStamp
				
			kcount = numpnts( tw )
			for( kdex = 0; kdex < kcount; kdex += 1 )
				AppendVal( Col_Pressure, pw[kdex] );
				AppendVal( Col_Temperature, tw[kdex] );
				AppendVal( Col_TimeStamp, timew[kdex] );					
			endfor	
			print this_folder
		endif
	endfor
		
	
	
End

Function SPB_CompactAllRaw()
		
	// function to loop through all found
	// SPB_<> datafolderssssss pull together 
	// 
		
	String list = "PeakPosition;Pressure;Temperature;TimeStamp;"
	Variable currow, curcol, idex, count, jdex, jcount, kdex, kcount, dfrStatus;
	Variable drow, dcol
		
	String folder_list, this_folder, src_wave;
		
	SetDataFolder root:SPB_Folder
	folder_list = StringByKey( "FOLDERS", DataFolderDir( 1 ))
		
	Make/N=(0,0)/D/O Collected_Raw
	Make/N=0/D/O Col_Pressure, Col_Temperature, Col_TimeStamp, Col_Wavenumber
		
	count = ItemsInList( foldeR_list, "," )
	for( idex = 0; idex < count;idex += 1 )
		sprintf this_folder, "root:SPB_Folder:%s:RAW", StringFromList( idex, folder_list, ",")
		DFREF dfr = $this_folder
		dfrStatus = DataFolderRefStatus( dfr )
		if( dfrStatus != 0 )
			SetDataFolder $this_folder
			Wave d = data_spectrum_matrix
			currow = DimSize( d, 0 );			curcol = DimSize( d, 1 )
			drow = DimSize( Collected_Raw, 0);	dcol = DimSize( Collected_Raw, 1 )
			Redimension/N=( currow + drow, curcol ) Collected_Raw

			for( jdex = 0; jdex < currow; jdex += 1 )
				Collected_Raw[drow+jdex][] = d[jdex][q]
			endfor
				
			Wave tw = Temperature
			Wave pw = Pressure
			Wave timew = TimeStamp
			Wave hvw = FrameColumn_5
				
			kcount = numpnts( tw )
			for( kdex = 0; kdex < kcount; kdex += 1 )
				AppendVal( Col_Pressure, pw[kdex] );
				AppendVal( Col_Temperature, tw[kdex] );
				AppendVal( Col_TimeStamp, timew[kdex] );					
			endfor	
			print this_folder
		endif
	endfor
		
	
	
End

// startIndex		index of time to start averaging. Usually 0
// stopIndex			index of time to stop averaging. Usually number of columns -1, i.e. DimSize(spectrum, 1)-1
Function SPB_ProduceAverageSpectrum( startIndex, stopIndex [dsm, time_w, startTime, stopTime])
	Variable startIndex, stopIndex
	Wave dsm, time_w
	Variable startTime, stopTime

	Wave SPB_Data_Spectrum_matrix = root:SPB_Folder:SPB_Data_Spectrum_matrix
	Wave SPB_TimeStamp = root:SPB_Folder:SPB_TimeStamp

	Variable bdex, edex, locStart, locStop


	if( !ParamIsDefault( dsm ) )
		Wave loc_dsm = $GetWavesDataFolder(dsm,2)
	else
		Wave loc_dsm = $GetWavesDataFolder( SPB_Data_Spectrum_matrix,2 )
	endif
	if( !ParamIsDefault( time_w ) )
		Wave loc_time = $GetWavesDataFolder(time_w,2)
	else
		Wave loc_time = $GetWavesDataFolder( SPB_TimeStamp, 2 );
	endif
	
	if( ParamIsDefault( startTime ) )
		bdex = startIndex;		locStart = loc_time[ bdex ];
	else
		locStart = startTime;		bdex = BinarySearch( time_w, locStart );
	endif
	if( ParamIsDefault( stopTime ) )
		edex = stopIndex;		locStop = loc_time[ edex ];
	else
		locStop = stopTime;		edex = BinarySearch( time_w, locStop );
	endif
	
	//printf "%s & %s\r", GetWavesDataFolder( loc_time, 2 ), GetWavesDataFolder( loc_dsm, 2 )
	//printf "Start -> %d (%s)\r", bdex, DateTime2Text( locStart )
	//printf "Stop  -> %d (%s)\r", edex, DateTime2Text( locStop )


	Variable idex, count = edex - bdex + 1
	Variable rows = DimSize( loc_dsm, 0 )
	Variable cols = DimSize( loc_dsm, 1 )
	if( edex >= cols )
		edex -= 1
	endif	
	Make/D/O/N=(cols) average_spectrum
	average_spectrum = 0;
	
	for( idex = bdex; idex <= edex; idex += 1 )
		average_spectrum += loc_dsm[ idex ] [p]
	endfor
	average_spectrum /= count;
	
End

Function SPB_HardwiredConditionalAverage(startIndex, stopIndex, destName, low, hi)
	Variable startIndex, stopIndex
	String destName
	Variable low, hi
	
	// cond = conditional set
	Wave cond_time = root:accel:source_rtime
	Wave cond_data = root:accel:accel_x
	Variable low_bound = low
	Variable high_bound = hi
	
	Variable cond_dex
	
	// data = data to average set
	Wave data_time = root:SPB_Folder:SPB_161119_1107:SIG:TimeStamp
	Wave data_w = root:SPB_Folder:SPB_161119_1107:SIG:AverageSubtracted_Full
	
	Make/D/O/N=( DimSize( data_w, 1 )  ) $destName
	Wave w = $destName
	w = 0;
 	
	Duplicate/O cond_data, highlighter; highlighter = nan;
	Variable idex, count = 0, bdex, edex;
	for( idex = startIndex; idex <= stopIndex; idex += 1 )
		bdex = BinarySearch( cond_time, data_time[ idex ] - 1 ) // THIS IS FOR 1 S DATA!
		edex = BinarySearch( cond_time, data_time[ idex ] )
		WaveStats/Q /R=[bdex, edex ] cond_data
		if( (low_bound < v_min ) & ( v_min < high_bound ) )
			highlighter[ bdex, edex ] = 1;
			w += data_w[ idex ][p];
			count += 1;
		endif
	endfor
	w /= count
 	
End

Function SPB_ConcatenateSPBs( dat_list, type )
	String dat_list
	String type
	
	// String list = "161123_1423;161123_1424;161123_1425;161123_1426;161123_1427;"

	Variable idex, count = ItemsInList( dat_list ), currows, newrows, jdex, cols
	String this_string, this_waveString, matStr, timeStr
	for( idex = 0; idex < count; idex += 1 )
		this_string = StringFromList( idex, dat_list )
		sprintf this_WaveString, "root:SPB_Folder:%s:%s", this_string, type
		sprintf matStr, "%s:Data_Spectrum_Matrix", this_WaveString
		sprintf timeStr, "%s:TimeStamp", this_WaveString
		
		Wave mat = $matStr
		Wave dat = $timeStr
		
		printf "%s & %s\r", nameofwave( mat ), nameofwave( dat )
		if( idex == 0 )
			Duplicate/O mat, root:Data_Spectrum_Matrix
			Duplicate/O dat, root:TimeStamp
		else
			Wave dmat = root:Data_Spectrum_Matrix
			Wave ddat = root:TimeStamp
			
			currows = DimSize( dmat, 0 );	cols = DimSize( dmat, 1 );
			newrows = DimSize( mat, 0 );
			
			Redimension/N=( currows + newrows, cols ) dmat
			Redimension/N=( currows + newrows ) ddat
			
			for( jdex = 0; jdex < newrows; jdex += 1 )
				dmat[ currows + jdex ][] = mat[ jdex ][q];
				ddat[ currows + jdex ] = dat[ jdex ];
			endfor
		endif
	endfor
	
	Duplicate/O ddat, root:TimeStamp_
	wave w = root:TimeStamp_
	Redimension/N=( numpnts( w ) + 1 ) w
	w[ numpnts( w ) - 1 ] = w[ numpnts( w ) - 2 ] + (w[1] - w[0])

End


// SPB_ReChunk will look in directory
// start to stop
// and produce new named waves in root:
// Cat_TimeStamp
// Cat_DataSpectrumMatrix

Function SPB_ReChunk( start_time, stop_time, type )
	Variable start_time
	Variable stop_time
	String type
	
	
	String saveFolder = GetDataFolder(1); SetDataFolder root:SPB_Folder
	String dirlist = 	StringByKey( "FOLDERS", DataFolderDir(1));
	String this_Folder, list = ""
	Variable idex, count = ItemsInList( dirlist, "," ), this_dat
	
	//	printf "From %s to %s\r", DTI_DateTime2Text( start_time, "" ), DTI_DateTime2Text( stop_time, "" )
	printf "From %s to %s\r", DateTime2Text( start_time), DateTime2Text( stop_time )
	for( idex = 0; idex < count; idex += 1 )
		this_folder = StringFromList( idex, dirlist, "," )
		this_dat = SPB_Folder2DateTime( this_Folder )
		//		printf "\t%s %s ...", this_Folder, DTI_Datetime2Text( this_dat, "" ) 
		printf "\t%s %s ...", this_Folder, Datetime2Text( this_dat ) 
		if(  (start_time <= this_dat ) & (this_dat <= stop_time ) )
			list = list + this_folder + ";"
			printf "include\r"
		else
			printf "exclude\r"
		endif
	endfor
	
	if( strlen( list ) > 0 )
		SPB_ConcatenateSPBs( list, type )
	endif
	
	SetDataFolder $saveFolder
End

Function SPB_Folder2DateTime( folder )
	String folder
	
	Variable dat
	
	String s = folder[ 4, strlen( folder ) - 1 ] + "00" 
	// s is now formatted in YYMMDD_HHMMSS
	
	// this is not y2k compatible
	dat = date2secs(str2num("20"+ s[0,1]), str2num(s[2,3]), str2num(s[4,5])) + str2num(s[7,8]) * 3600 + str2num(s[9,10]) * 60
	
	// the simple beow function in AML_communityCenter
	// do not use this because of interdependency issues. 
	// consider moving DTI_ funcitons to Global Utils
	//dat = DTI_Text2DateTime( s, "filename2y" )
	
	return dat
End
	
	

// This procedure is meant to automate the process of making a tuning rate against 
// spectrum plot as well as standardize the format.
// Method and plot design by Barry McManus; macro by Mike Moore.
// 2017-07-19

Function Wintel_TuneRateSpecPlot()

	String saveFolder = getDatafolder(1)
	makeAndOrSetDF("tuneRate")
	
	Variable refNum
	String fileFilterStr = "Spectral Files (*.spe):.spe;"
	String fullPath = ""
	String fileName = ""
	String endingStr = ""
	String name = ""
	String wNameStr = ""
	wNameStr += "N=Spec;"
	wNameStr += "N=Fit;"
	wNameStr += "N=Baseline;"
	wNameStr += "N=Fitmarker;"
	wNameStr += "N=Freq;"
	String SpecPlot = ""
	String ddpFreqPlot = ""

	//Creates symbolic path to Wintel data folder to be referenced.
	NewPath/O/Q WintelData nSTR_h_ProbeCommonPaths() // this function in LoadSpe2.ipf will default to C:tdlwintel:data 
	// but allow other good paths if that is not present. 

	//Open Window's 'Select File' dialog; saves selected file's full path as a string to S_fileName
	Open/D/F=fileFilterStr/P=WintelData/R refNum

	if (cmpstr(S_fileName, "") == 0)			//If user cancels or otherwise no file is selected.
		abort "No file selected."
	elseif (cmpstr(ParseFilePath(4, S_fileName, ":", 0, 0), "spe") != 0)
		abort "Selected file has the wrong file type."
	else
		fullPath = S_fileName
	endif
	
	//Strip all but date and timestamp of file name from path.
	fileName = ParseFilePath(3,fullPath,":",0,0)		//Returns filename with extension removed.
	fileName = fileName[0,12]		//For standard .spe file naming convention, removes  
	//suffix, leaving only date and timestamp.
	
	//If the plot for this file already exists, bring it to front and exit function.
	name = "TuningRateSpec_" + fileName
	DoWindow/F $name
	if (V_flag != 0)			//If window doesn't already exist.
		SetDataFolder saveFolder
		return -1
	endif

	//Load number of points from selected .spe file.
	LoadWave/A/B="N=Npts;"/D/J/K=1/L={0,3,1,0,0}/O/Q fullPath
	if (GetRTError(1) != 0)		//If LoadWave returns an error, assume selected file is empty.
		abort "Selected file contains no data."
	else
		Wave Npts
	endif
	//Load waves from spectral file; of interest: Spec and Freq.
	LoadWave/A/B=wNameStr/D/G/K=1/L={0,4,Npts[0],0,0}/O/Q fullPath
	Wave Spec, Freq

	WaveStats/Q Spec					//From WaveStats: V_min, wave minimum value will be used.
	Spec -= V_min					//Offset Spec so min value is 0.
	Duplicate/O Freq ddpFreq
	Differentiate ddpFreq

	//Make waves being plotted have their names reflect the file they're coming from.
	//Allows creation of plots from multiple .spe files without overwrite.
	SpecPlot = "Spec" + fileName
	ddpFreqPlot = "ddpFreq" + fileName
	Duplicate/O Spec, $SpecPlot
	Duplicate/O ddpFreq, $ddpFreqPlot

	//Create plot and format.
	Display/L/K=1/N=$name $SpecPlot as name
	AppendtoGraph/R $ddpFreqPlot
	Label left "Spectrum (mV)"
	Label right "Tuning Rate (cm\S-1\M/ch)"
	Label bottom "Channel"
	ModifyGraph rgb($SpecPlot)=(0,0,0)
	ModifyGraph lsize($SpecPlot)=2
	ModifyGraph rgb($ddpFreqPlot)=(44253,29492,58982)
	ModifyGraph lsize($ddpFreqPlot)=2
	ModifyGraph axRGB(right)=(44253,29492,58982)
	ModifyGraph tlblRGB(right)=(44253,29492,58982)
	ModifyGraph alblRGB(right)=(44253,29492,58982)	
	ModifyGraph mirror(bottom)=1
	TextBox/A=RB/N=TimeStamp fileName
	
	SetDataFolder saveFolder
	
END

///////////////////////////////////////////////////////////////////////////////////
// This function prints a set of times which can be given to TDLWintel playback
// It requires a datawave where bad data has been set to NaN
// It searches datawave for NaN points. If the number of NaN points exceeds
// the requested maxNaNsPerHour, then that whole hour of data is added to the list.
// If TDLWintel playback ever supports sub-hour refits, this function should be altered.
// selecting printEachHour=1 will print each hour with separate start stops. 
// this is normally not required.
// it will print to the command line data that looks like
//	20180401_080000, 20180401_100000
// these can then be pasted into PBFilter.dat. Make sure to specify Rev 2
////////////////////////////////////////////////////////////////////////////////////
Function writePBtimesIfNan(timewave, datawave, maxNansPerHour, [printEachHour])
	wave timewave, datawave
	variable maxNansPerHour, printEachHour
	
	if(paramisdefault(printEachHour))
		printEachHour=0
	endif
	

	variable starthour = datetime2justDate(timewave[0]) + 3600*datetime2justHour(timewave[0])
	variable endHour = datetime2justDate(timewave[numpnts(timewave)-1]) + 3600*datetime2justHour(timewave[numpnts(timewave)-1])
	variable i, hour, lastEnd=endHour, thisStart = startHour
	
	make/o/n=(numpnts(timewave)) $("PBmask_"+nameofwave(datawave))
	wave maskwave = $("PBmask_"+nameofwave(datawave))
	maskwave = NaN
	variable nanCount, startdex, enddex
	
	for(hour=startHour; hour<=endHour; hour+=3600)
	
		nanCount = 0
		startdex= binarysearch(timewave, hour)
		enddex= binarySearch(timewave, hour+3600)
		if(enddex==-2)
			enddex = numpnts(timewave)-1
		endif
		if(startdex==-1)
			startdex=0
		endif
		
		// how many NaNs in this hour?
		for(i=startdex;i<enddex;i+=1)
			if(numtype(datawave[i]) == 2)
				nanCount+=1
			endif
		endfor		

		if(nanCount> maxNansPerHour)		
		
			maskWave[startdex,enddex] = 1
	
			if(printEachHour)
				print DTI_Datetime2text(hour, "YYMMDD_HHmmSS"), ", ", DTI_Datetime2text(hour+3600, "YYMMDD_HHmmSS")	
			else // print as few pb ranges as possible
				if(hour > lastEnd || hour == endHour)
					// then nans don't continue
					// print last one found
					print DTI_Datetime2text(thisStart, "YYMMDD_HHmmSS"), ", ", DTI_Datetime2text(lastEnd, "YYMMDD_HHmmSS")				
					// update.
					thisStart = hour
					lastEnd = hour + 3600
				else
					// then it's a continuation of previously found hour
					lastEnd = hour+3600
				endif
			endif
		endif
	endfor
End
