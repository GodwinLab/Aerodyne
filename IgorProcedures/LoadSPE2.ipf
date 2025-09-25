#pragma rtGlobals=1		// Use modern global access method.
	Constant k_Invoke2014_STRPanel = 1;	// set to 0 to use old STR loader
	Constant k_AutoSearch_WintelGraphs = 1; // set to 0 to suspend

	Constant k_interp_WB_as_Fit_not_Laser = 1; // set 0 to go back to 'old" wavelength bands only define Laser sweep hv's

	// default constants for wgSTC_ComputeMask
	strconstant ks_default_stc_StatusWord = "stc_StatusW"
	strconstant ks_default_stc_datetime = "stc_time"


	// Load SPE 2
	// Aerodyne Research Inc, 45 Manning Road, Billerica, MA 01821
	// 2014 - Rewritten by Scott Herndon and Tara Yacovitch 
	// 2003 - Written by Scott Herndon, Quan Shi and David Nelson
	//
	// Load SPE 2 is a rewrite of Load SPE
	// Load SPE 2 is meant to handle version 5 and later SPE files.
	// Notable improvements are the ability to work directly with the zip archives and
	// improved support for the multiple laser model.

	// This ipf is broken into three main sections
	// The first section concerns the new model of loading data from a text wave 'frame'
	// In otherwords the principal function is SPE2_ProcFrameAsSPE( text_wave )
	// This function interprets the text wave as if it were the literal body of a spe file
	// This is done so that it becomes arbitrary as to how the data was put into the text wave
	// in other words, doesn't matter if data came from zip or from naked spe file
	// It is completely arbitrary where the text_wave comes from as a proper wave reference
	// is demanded by the function.  That said, the root:LoadSPE_II: data folder is reserved
	// for waves and global variables.
	// Though the waves are named in a manner which should be obvious it will help
	// to understand the process with debugging and modifying/extending this code.
	// Conceptually, the spe file consists of parameters, headers and data (columns)
	// The interpretation of the frame creates/loads into the following static waves
	// param_tw and header_tw are the text waves which contain the params and headers
	// Frame2Parameter --> THIS IS A WEAK FUNCTION - that is to say it is fragile. 
	// Look here if you are suspicous of misloading data.
	// The columns go into numeric waves called FrameColumn_x (4 or 5 of the 6 named FrameColumnns) are used.
	// There are four 'spawned' wbx_ sets of waves which would be interpreted as wavelength band
	// or 'laser' waves.  Here the data is mapped to the named entities
	// wbx_frequency, wbx_spectrum, wbx_wintel_base, bwx_wintel_fit 
	// also included are wbx_wintel_cur and wbx_igr_cur
	// These waves are very flexible or subject to dimensional change.  On ProcFrameAsSPE
	// they are all zeroed and then resized according to the number of points in the ramp.
	// The FrameColumn waves are the full data columns
	// while the wbx_ waves are the interpreted spectra within the sweeps.

	// Utility functions which may be of interest to someone using/modifying this code base
	// include; SPE2_GetSPEParamText & SPE2_GetSPEParamNumeric which can pull
	// a particular named parameter from the loaded data.  Note that the text extraction call
	// has a start_index.  Unless ultimate speed is your need, just leave this at zero.  If you give it
	// a non-zero index and it fails, it will loop around and try to look from the top before returning -1, 
	// so it doesn't matter
	// Also note the global you are trying to get your hands on may already be defined.

	// If you are modifying or extending this code, GO TO SPE2_Initialize and scolll down
	// to about half way through the function.  You will find full line references to include in
	// any function which needs access to these frame interpretations.  

	// The second section is the user interface code body.  This draws the panel and handles the button
	// calls, these functions are prefaced by zSPE2_ and this section operates from root:LoadSPE_IIUI:

	// The third section is where additional custom applications may be piped in.
	// A function there is called SPE_FreshDataLoad() which should be called after every sucessful
	// load of data, and ProcFrameAsSPE call.  This is where the so called browser session (bs?) waves
	// are updated.  If you follow this model to extract what you want, a single code base can be maintained.

	//
	//
	//

	// wgSTC_ComputeMask();
	// Default:
	// Call wgSTC_ComputeMask() to work from stc_time and stc_StatusW
	// produces wgSTC_Mask_v<n> valued 1 or 0 for valuve n, counting from zero
	// also produces Valve_<n>_Start and Valve_<n>_Stop
	//
	// Advanced: to override and specify different stc_time and stc_statusW call like
	// wgSTC_ComputeMask( stc_timeW = <wave>, statusword = <wave> )
	//	to modify default behavioir ks_default_stc_StatusWord, ks_default_stc_datetime
	//
	//
	//

	// The Constants below define the fit markers in Wintel, and their closet equivalents in Igor
	Constant k_WINTEL_F1 = 16		// Single Species Fit
	Constant k_IGOR_F1 = 41
	Constant k_WINTEL_F2 = 17		// Dual Species Fit
	Constant k_IGOR_F2 = 42
	Constant k_WINTEL_F3 = 18		// 3 Species fit
	Constant k_IGOR_F3 = 44
	Constant k_WINTEL_F4 = 19
	Constant k_IGOR_F4 = 11
	Constant k_WINTEL_F5 = 20
	Constant k_IGOR_F5 = 53
	Constant k_WINTEL_F6 = 21
	Constant k_IGOR_F6 = 56
	Constant k_WINTEL_E = 22 // Tuning Rate Start and Stop Markers
	Constant k_IGOR_E = 44
	Constant k_WINTEL_NULL = 0
	Constant k_IGOR_NULL = -2
	Constant k_WINTEL_EOFit = 5  // X markers at end of fit
	Constant k_IGOR_EOFit = 1
	Constant k_WINTEL_ZERO = 3
	Constant k_IGOR_ZERO = 8
	Constant k_WINTEL_BBaseline = 1
	Constant k_WINTEL_EBaseline = 2
	Constant k_IGOR_BBaseline = 10
	Constant k_IGOR_EBaseline = 10

	StrConstant ks_zSPE2TabList = "Browse;Load;PlayList;Average;"
	StrConstant ks_zSPE2PanelName = "Load_Browse_SPE_Panel"
	StrConstant ks_WildWintelBlockStr = "xxxx"

	//Menu "Macros"
	//	Submenu "TDLWintel File Loader Functions"
	//		"------------------", Execute("")
	//		"Loader_Browser_II", zSPE2_DrawPanel()
	//		"-------------------------", Execute("")
	//		"STR Files Loader", Execute("zSTR_initstrpanel()")
	//		"-------------------------", Execute("")
	//	End
	//End
	// This is the main function which interprets a spe file which has been put into a 'frame' or really
	// just each line of the file is an element in the text wave -- frame_w
	// This functions and the functions which are called within should only be altered to update
	// the interpretation of a spe file.
	// Other calculations should be done outside or after this function is called
	// Note that the 'browse_session' waves which are created as one looks about are handled elsewhere
	// however they tap the globals which are assigned here.
	// the browse session waves do not understand how to directly read frame_w (NOR SHOULD THEY EVER)
	// they work via the globals.  It is the responsiblity of the calling functions to update browser session waves

Function mSTR_initAndPanel()
	// launches mask panel
	
	mSTR_init();
	mStr_panel();
	
End

Function SPE2_MapWintelToIgorCur( wintel, igor )
	Wave wintel, igor
	
	Duplicate/O wintel, igor
	igor = Nan
	Variable idex = 0, count = numpnts( wintel )
	if( count > 0 )
		do
			switch( wintel[idex] )
				case k_WINTEL_F1:
					igor[idex] = k_IGOR_F1;
					break;
				case k_WINTEL_F2:
					igor[idex] = k_IGOR_F2;
					break;
				case k_WINTEL_F3:
					igor[idex] = k_IGOR_F3;
					break;
				case k_WINTEL_F4:
					igor[idex] = k_IGOR_F4;
					break;
				case k_WINTEL_F5:
					igor[idex] = k_IGOR_F5;
					break;
				case k_WINTEL_F6:
					igor[idex] = k_IGOR_F6;
					break;
				case k_WINTEL_E:
					igor[idex] = k_IGOR_E;
					break;
				case k_WINTEL_ZERO:
					igor[idex] = k_IGOR_ZERO;
					break;	
				case k_WINTEL_EOFit:
					igor[idex] = k_IGOR_EOFit;
					break;
				case k_WINTEL_BBaseline:
					igor[idex] = k_IGOR_BBaseline;
					break;
				case k_WINTEL_EBaseline:
					igor[idex] = k_IGOR_EBaseline;
					break;
				default:
			endswitch
			idex += 1
		while( idex < count )
	endif
End
Function SPE2_ProcFrameAsSPE( frame_w )
	Wave/T frame_w
	
	Variable return_val = 0;
	// Step 1 -- determine whether the initialization routine needs to be called
	// Step 2 -- probe and extract the five columns with data
	// Step 3 -- do messy work of loading global variables and strings with parameter data
	// Step 4 -- breadcrumb the tuning rate out to root: as root:L0_freq
	
	Variable trigger_init = 0;
	NVAR/Z spe2init = root:LoadSPE_II:spe2init
	if( !NVAR_Exists( spe2init ) )
		trigger_init = 1;
	else
		if( spe2init )
			trigger_init = 1;
		endif
	endif
	
	if( trigger_init )
		SPE2_Initialize();
	endif
	
	return_val = SPE2_Frame2FiveColumns( frame_w );
	if( return_val != 0 )
		printf "SPE2_Frame2FiveColumns returned terminal error number %d\r", return_val
		return return_val;
	endif
	
	return_val = SPE2_Frame2ParameterWave( frame_w );
	if( return_val != 0 )
		printf "SPE2_Frame2ParameterWave returned terminal error number %d\r", return_val
		return return_val;
	endif
	
	SPE2_Param2GlobalsAndDisp()
	
	if( k_interp_WB_as_Fit_not_Laser )
		SPE2_SplitFiveColToWBs_perFit()
	else
		SPE2_SplitFiveColumnToWBs()
	endif
	
	SPE2_WB_mV2Trans()
	
	// work with SAP_ functions (2018)
	Wave/Z FrameColumn5 = root:LoadSPE_II:FrameColumn_5
	if( WaveExists( FrameColumn5 ) )
		Duplicate/O FrameColumn5, root:L0_freq
	endif
	if( 1 )
		// tidy up
		KillWaves/Z root:freqScale_w, root:freqScaleDelta_w, root:freqScaleAbs_w
	endif
	return return_val;
End

Function SPE2_WB_mV2Trans()
	
	// This function will cycle through all four wavelength bands and calculate the transmission data
	Variable sweepNumber = 1, finalSweep = 4
	String sweepStr
	Variable result = 0
	Wave/T params_tw = root:LoadSPE_II:params_tw	
	Wave/T header_tw = root:LoadSPE_II:header_tw			
	do
		sweepStr = num2str( sweepNumber );
		NVAR SPE_SWPX_points = $("root:LoadSPE_II:SPE_SWP" + sweepStr + "_points" )
		
		if( SPE_SWPX_points > 0 )
			Wave wbx_igr_cur = $("root:LoadSPE_II:wb" + sweepStr + "_igr_cur")
			Wave wbx_wintel_cur = $("root:LoadSPE_II:wb" + sweepStr + "_wintel_cur")
			Wave wbx_trans_fit = $("root:LoadSPE_II:wb" + sweepStr + "_trans_fit")
			Wave wbx_trans_spectrum = $("root:LoadSPE_II:wb" + sweepStr + "_trans_spectrum")
			Wave wbx_wintel_fit = $("root:LoadSPE_II:wb" + sweepStr + "_wintel_fit")
			Wave wbx_wintel_base = $("root:LoadSPE_II:wb" + sweepStr + "_wintel_base")
			Wave wbx_spectrum = $("root:LoadSPE_II:wb" + sweepStr + "_spectrum")
			Wave wbx_frequency = $("root:LoadSPE_II:wb" + sweepStr + "_frequency")		
			Duplicate/O wbx_spectrum, wbx_trans_fit, wbx_trans_spectrum
			result = SPE2_GenTransData( wbx_spectrum, wbx_wintel_base, wbx_wintel_fit, wbx_wintel_cur, header_tw, params_tw, wbx_trans_spectrum, wbx_trans_fit );			
			
			SPE2_MapWintelToIgorCur( wbx_wintel_cur, wbx_igr_cur )
		endif
		sweepNumber += 1
	while( sweepNumber <= finalSweep )
	
End
Function SPE2_GenTransData( spec_w, base_w, fit_w, marker_w, header_tw, param_tw, spectrans_w, fittrans_w )
	Wave spec_w, base_w, fit_w, marker_w, header_tw, param_tw, spectrans_w, fittrans_w
	// Function calculates sigtrans_w and fittrans_w from the given waves
	
	NVAR  SPE_Channels_in_Off = root:LoadSPE_II:SPE_Channels_in_Off
	NVAR  SPE_MenuPower = root:LoadSPE_II:SPE_MenuPower
	Wave/D FrameColumn_1 = root:LoadSPE_II:FrameColumn_1
	Wave/D FrameColumn_2 = root:LoadSPE_II:FrameColumn_2
	Wave/D FrameColumn_3 = root:LoadSPE_II:FrameColumn_3
	Wave/D FrameColumn_4 = root:LoadSPE_II:FrameColumn_4
	Wave/D FrameColumn_5 = root:LoadSPE_II:FrameColumn_5
	Wave/D FrameColumn_6 = root:LoadSPE_II:FrameColumn_6
	Wave/T params_tw = root:LoadSPE_II:params_tw	
	//Wave/T header_tw = root:LoadSPE_II:header_tw		
	//Wave/D spec_laser_off = root:LoadSPE_II:spec_laser_off
	
	Variable sigoffset = SPE2_ZeroMarkerMeanOrMenu_IZero( spec_w, marker_w, header_tw, param_tw )
	if( sigoffset == -1 )
		Print "SPE2_GenTransData unable to determine offset or signal offset!"
		return - 1
	endif
	//Redimension/N=(numpnts(spec_w)) spectrans_w, fittrans_w
	spectrans_w = (spec_w - sigoffset ) / (base_w - sigoffset )
	fittrans_w = (fit_w - sigoffset ) / ( base_w - sigoffset )

End
// End of GenerateTransmissionDataSPE

///////////////////////// The next few functions are used to make the data into a transmission wave
Function SPE2_ZeroMarkerMeanOrMenu_IZero( spec_w, marker_w, header_w, param_w )
	Wave spec_w, marker_w, header_w, param_w
	Variable ret_val = 0
	
	NVAR  SPE_Channels_in_Off = root:LoadSPE_II:SPE_Channels_in_Off
	NVAR  SPE_MenuPower = root:LoadSPE_II:SPE_MenuPower
	Wave/D FrameColumn_1 = root:LoadSPE_II:FrameColumn_1
	Wave/D FrameColumn_2 = root:LoadSPE_II:FrameColumn_2
	Wave/D FrameColumn_3 = root:LoadSPE_II:FrameColumn_3
	Wave/D FrameColumn_4 = root:LoadSPE_II:FrameColumn_4
	Wave/D FrameColumn_5 = root:LoadSPE_II:FrameColumn_5
	Wave/D FrameColumn_6 = root:LoadSPE_II:FrameColumn_6
	Wave/T params_tw = root:LoadSPE_II:params_tw	
	Wave/T header_tw = root:LoadSPE_II:header_tw		
	Wave/D spec_laser_off = root:LoadSPE_II:spec_laser_off
	
	// Usage:  This functions looks for the zero markers... if it finds them it returns the average spec value
	// if not it looks in the menu and tries to find Io
	// if it explodes, it returns -1
	Variable found_one = -1, found_two = -1
	Variable TDLWintel_ZeroMarkerCode = k_WINTEL_ZERO

	Variable idex = numpnts( FrameColumn_4 )
	do
		if( FrameColumn_4[idex] == TDLWintel_ZeroMarkerCode )
			if( found_one == -1 )
				found_one = idex
				//Printf "Found a zero Marker at %g", idex
			elseif( found_one != -1 )
				found_two = idex
				//Printf " and another at %g", idex
				idex = 0
			endif
		endif	
		idex -= 1
	while( idex > 0 )
	//printf "\r"

	if( ( found_one != -1 ) %& ( found_two != -1 ) )
		WaveStats/Q/R=[found_two, found_one] FrameColumn_1
		return v_avg
	endif
	if( ( found_one != -1 ) %| ( found_two != -1 ) )
		Print "Only Found One Zero marker ... returning its value, but this is a warning of something being amiss"
		if( found_one != -1 )
			return spec_w[found_one]
		else
			return spec_w[found_two]
		endif
	endif
	// At this point in execution flow, it is apparent the zeromarkers aren't there...
	Variable MenuIZero = SPE_MenuPower
	if( MenuIZero == -1 )
		return -1
	endif
	// But this is only half of the story ... this function really needs to get the 'average' of data also
	Variable data_level = 0
	data_level = SPE2_GetDataLevel( spec_w, header_w, param_w )

	return data_level - MenuIZero

End 
// End of ZeroMarkerMeanOrMenuIZero
Function SPE2_GetDataLevel( spec_w, header_w, param_w )
	Wave spec_w, header_w, param_w

	NVAR  SPE_Channels_in_Off = root:LoadSPE_II:SPE_Channels_in_Off

	Variable OffPulseChannels =SPE_Channels_in_Off
	if( OffPulseChannels == -1 )
		OffPulseChannels = 9
	else
		OffPulseChannels += Ceil(0.02 * numpnts( spec_w ) )
	endif
	Variable endRange = numpnts( spec_w ) - OffPulseChannels
	Variable startRange = 0
	if( endRange < startRange )
		endRange = startRange + 1
	endif

	WaveStats/Q/R=[startRange, endRange] spec_w
	//Print startRange, endRange, v_avg
	return v_avg

End

// This function is where the FiveColumn data is split into wavelength bands 
// Revision 3/2015
// Now generates wavelength bands based on FITs
// Thus, if

Function SPE2_SplitFiveColToWBs_perFit()
	// The strategy will be to use a combination of SWEEP points and cursors to define several
	// things -- the waves wbx_ have already been defined and are waiting...
	// now it is likely and possible that 'laser' should be replaced with 'fit'
	
	SVAR/Z SPE_FrequencyMSG = root:LoadSPE_II:SPE_FrequencyMSG
	if( SVAR_Exists( SPE_FrequencyMSG ) != 1 )
		String saveFolder = GetDataFolder(1)
		SetDataFolder root:; MakeAndOrSetDF( "LoadSPE_II" )
		String/G SPE_FrequencyMSG = "msg initialized"
		SetDataFolder $saveFolder
		SVAR SPE_FrequencyMSG = root:LoadSPE_II:SPE_FrequencyMSG
	endif
	
	sprintf SPE_FrequencyMSG, "...perFit"
		
	NVAR  SPE_version = root:LoadSPE_II:SPE_version
	NVAR  SPE_Total_data_points = root:LoadSPE_II:SPE_Total_data_points
	NVAR  SPE_SWP1_points = root:LoadSPE_II:SPE_SWP1_points; 	NVAR  SPE_SWP2_points = root:LoadSPE_II:SPE_SWP2_points
	NVAR  SPE_SWP3_points = root:LoadSPE_II:SPE_SWP3_points; 	NVAR  SPE_SWP4_points = root:LoadSPE_II:SPE_SWP4_points
	

	NVAR  SPE_FreqResolAtPrimaryF_sw1 = root:LoadSPE_II:SPE_FreqResolAtPrimaryF_sw1;	NVAR  SPE_FreqResolAtPrimaryF_sw2 = root:LoadSPE_II:SPE_FreqResolAtPrimaryF_sw2
	NVAR  SPE_FreqResolAtPrimaryF_sw3 = root:LoadSPE_II:SPE_FreqResolAtPrimaryF_sw3;	NVAR  SPE_FreqResolAtPrimaryF_sw4 = root:LoadSPE_II:SPE_FreqResolAtPrimaryF_sw4	
	
	NVAR  SPE_Channels_in_Off = root:LoadSPE_II:SPE_Channels_in_Off
	
	NVAR  SPE_MenuPower = root:LoadSPE_II:SPE_MenuPower

	NVAR  SPE_PeakPos1 = root:LoadSPE_II:SPE_PeakPos1
	NVAR  SPE_Fingerprint1 = root:LoadSPE_II:SPE_Fingerprint1
	NVAR  SPE_FreqBand4Spec1 = root:LoadSPE_II:SPE_FreqBand4Spec1

	NVAR  SPE_PeakPos2 = root:LoadSPE_II:SPE_PeakPos2;	NVAR  SPE_Fingerprint2 = root:LoadSPE_II:SPE_Fingerprint2; 	NVAR  SPE_FreqBand4Spec2 = root:LoadSPE_II:SPE_FreqBand4Spec2
	NVAR  SPE_PeakPos3 = root:LoadSPE_II:SPE_PeakPos3;	NVAR  SPE_Fingerprint3 = root:LoadSPE_II:SPE_Fingerprint3; 	NVAR  SPE_FreqBand4Spec3 = root:LoadSPE_II:SPE_FreqBand4Spec3
	NVAR  SPE_PeakPos4 = root:LoadSPE_II:SPE_PeakPos4;	NVAR  SPE_Fingerprint4 = root:LoadSPE_II:SPE_Fingerprint4; 	NVAR  SPE_FreqBand4Spec4 = root:LoadSPE_II:SPE_FreqBand4Spec4
	NVAR  SPE_PeakPos5 = root:LoadSPE_II:SPE_PeakPos5;	NVAR  SPE_Fingerprint5 = root:LoadSPE_II:SPE_Fingerprint5; 	NVAR  SPE_FreqBand4Spec5 = root:LoadSPE_II:SPE_FreqBand4Spec5
	NVAR  SPE_PeakPos6 = root:LoadSPE_II:SPE_PeakPos6;	NVAR  SPE_Fingerprint6 = root:LoadSPE_II:SPE_Fingerprint6; 	NVAR  SPE_FreqBand4Spec6 = root:LoadSPE_II:SPE_FreqBand4Spec6
	NVAR  SPE_PeakPos7 = root:LoadSPE_II:SPE_PeakPos7;	NVAR  SPE_Fingerprint7 = root:LoadSPE_II:SPE_Fingerprint7; 	NVAR  SPE_FreqBand4Spec7 = root:LoadSPE_II:SPE_FreqBand4Spec7
	NVAR  SPE_PeakPos8 = root:LoadSPE_II:SPE_PeakPos8;	NVAR  SPE_Fingerprint8 = root:LoadSPE_II:SPE_Fingerprint8; 	NVAR  SPE_FreqBand4Spec8 = root:LoadSPE_II:SPE_FreqBand4Spec8
	NVAR  SPE_PeakPos9 = root:LoadSPE_II:SPE_PeakPos9;	NVAR  SPE_Fingerprint9 = root:LoadSPE_II:SPE_Fingerprint9; 	NVAR  SPE_FreqBand4Spec9 = root:LoadSPE_II:SPE_FreqBand4Spec9
	NVAR  SPE_PeakPos10 = root:LoadSPE_II:SPE_PeakPos10;	NVAR  SPE_Fingerprint10 = root:LoadSPE_II:SPE_Fingerprint10; 	NVAR  SPE_FreqBand4Spec10 = root:LoadSPE_II:SPE_FreqBand4Spec10
	NVAR  SPE_PeakPos11 = root:LoadSPE_II:SPE_PeakPos11;	NVAR  SPE_Fingerprint11 = root:LoadSPE_II:SPE_Fingerprint11; 	NVAR  SPE_FreqBand4Spec11 = root:LoadSPE_II:SPE_FreqBand4Spec11
	NVAR  SPE_PeakPos12 = root:LoadSPE_II:SPE_PeakPos12;	NVAR  SPE_Fingerprint12 = root:LoadSPE_II:SPE_Fingerprint12; 	NVAR  SPE_FreqBand4Spec12 = root:LoadSPE_II:SPE_FreqBand4Spec12
	NVAR  SPE_PeakPos13 = root:LoadSPE_II:SPE_PeakPos13;	NVAR  SPE_Fingerprint13 = root:LoadSPE_II:SPE_Fingerprint13; 	NVAR  SPE_FreqBand4Spec13 = root:LoadSPE_II:SPE_FreqBand4Spec13
	NVAR  SPE_PeakPos14 = root:LoadSPE_II:SPE_PeakPos14;	NVAR  SPE_Fingerprint14 = root:LoadSPE_II:SPE_Fingerprint14; 	NVAR  SPE_FreqBand4Spec14 = root:LoadSPE_II:SPE_FreqBand4Spec14
	NVAR  SPE_PeakPos15 = root:LoadSPE_II:SPE_PeakPos15;	NVAR  SPE_Fingerprint15 = root:LoadSPE_II:SPE_Fingerprint15; 	NVAR  SPE_FreqBand4Spec15 = root:LoadSPE_II:SPE_FreqBand4Spec15
	NVAR  SPE_PeakPos16 = root:LoadSPE_II:SPE_PeakPos16;	NVAR  SPE_Fingerprint16 = root:LoadSPE_II:SPE_Fingerprint16; 	NVAR  SPE_FreqBand4Spec16 = root:LoadSPE_II:SPE_FreqBand4Spec16

	Wave/D FrameColumn_1 = root:LoadSPE_II:FrameColumn_1;	Wave/D FrameColumn_2 = root:LoadSPE_II:FrameColumn_2;	Wave/D FrameColumn_3 = root:LoadSPE_II:FrameColumn_3
	Wave/D FrameColumn_4 = root:LoadSPE_II:FrameColumn_4;	Wave/D FrameColumn_5 = root:LoadSPE_II:FrameColumn_5;	Wave/D FrameColumn_6 = root:LoadSPE_II:FrameColumn_6

	Wave/T params_tw = root:LoadSPE_II:params_tw	; Wave/T header_tw = root:LoadSPE_II:header_tw
	
	Wave/D wb1_igr_cur = root:LoadSPE_II:wb1_igr_cur;	Wave/D wb1_wintel_cur = root:LoadSPE_II:wb1_wintel_cur; Wave/D wb1_trans_fit = root:LoadSPE_II:wb1_trans_fit
	Wave/D wb1_trans_spectrum = root:LoadSPE_II:wb1_trans_spectrum; 	Wave/D wb1_wintel_fit = root:LoadSPE_II:wb1_wintel_fit
	Wave/D wb1_wintel_base = root:LoadSPE_II:wb1_wintel_base; 	Wave/D wb1_spectrum = root:LoadSPE_II:wb1_spectrum;  Wave/D wb1_frequency = root:LoadSPE_II:wb1_frequency; 
	
	Wave/D wb2_igr_cur = root:LoadSPE_II:wb2_igr_cur;	Wave/D wb2_wintel_cur = root:LoadSPE_II:wb2_wintel_cur; 	Wave/D wb2_trans_fit = root:LoadSPE_II:wb2_trans_fit;	Wave/D wb2_trans_spectrum = root:LoadSPE_II:wb2_trans_spectrum
	Wave/D wb2_wintel_fit = root:LoadSPE_II:wb2_wintel_fit;	Wave/D wb2_wintel_base = root:LoadSPE_II:wb2_wintel_base
	Wave/D wb2_spectrum = root:LoadSPE_II:wb2_spectrum;	Wave/D wb2_frequency = root:LoadSPE_II:wb2_frequency;

	Wave/D wb3_igr_cur = root:LoadSPE_II:wb3_igr_cur;	Wave/D wb3_wintel_cur = root:LoadSPE_II:wb3_wintel_cur; 	Wave/D wb3_trans_fit = root:LoadSPE_II:wb3_trans_fit;	Wave/D wb3_trans_spectrum = root:LoadSPE_II:wb3_trans_spectrum
	Wave/D wb3_wintel_fit = root:LoadSPE_II:wb3_wintel_fit;	Wave/D wb3_wintel_base = root:LoadSPE_II:wb3_wintel_base
	Wave/D wb3_spectrum = root:LoadSPE_II:wb3_spectrum;	Wave/D wb3_frequency = root:LoadSPE_II:wb3_frequency;

	Wave/D wb4_igr_cur = root:LoadSPE_II:wb4_igr_cur;	Wave/D wb4_wintel_cur = root:LoadSPE_II:wb4_wintel_cur; 	Wave/D wb4_trans_fit = root:LoadSPE_II:wb4_trans_fit;	Wave/D wb4_trans_spectrum = root:LoadSPE_II:wb4_trans_spectrum
	Wave/D wb4_wintel_fit = root:LoadSPE_II:wb4_wintel_fit;	Wave/D wb4_wintel_base = root:LoadSPE_II:wb4_wintel_base
	Wave/D wb4_spectrum = root:LoadSPE_II:wb4_spectrum;	Wave/D wb4_frequency = root:LoadSPE_II:wb4_frequency;

	Wave/D spec_laser_off = root:LoadSPE_II:spec_laser_off

	Variable this_wb_begins = -1, this_wb_ends = -1
	Variable this_swp_pnts, species_number, species_in_this_wb = 0
	Variable species_in_nextFit = 0;
	
	Variable bandNumber, channel2use, fingerprint2use, wband2use
	Variable idex, wbindex, index_in_hand;
	
	species_number = 1	// tracked to set POSN
	bandNumber = 1		// tracks laser number
	
	wbindex = 1;			// tracks fit number
	
	// new strategy ... float from left to right with index_in_hand
	// index_in_hand finds each fit begins
	index_in_hand = 0;
	// do{ }while( index_in_hand < numpnts( FrameColumn_4 ) )
	do
		// index_in_hand is the initial search point and set to the EOF when this function finds a return value;
		species_in_nextFit = SPE2_NumSpeciesStartingAt( FrameColumn_4, index_in_hand );
		if( species_in_nextFit == 0 )
			// no fit initiation marker found, we are done, wrap it up and go home..
			index_in_hand = numpnts( FrameColumn_4 );
			break;
		endif
		
	
		NVAR SPE_SWPX_points = $( "root:LoadSPE_II:SPE_SWP" + num2str(bandNumber) + "_points")
		this_swp_pnts = SPE_SWPX_points
		if( this_swp_pnts == 0 )
			// there are no points in this sweep
			bandNumber += 1;
			Redimension/N=0 wbx_wintel_cur, wbx_wintel_fit, wbx_wintel_base,wbx_spectrum, wbx_frequency; 
			break;
		endif		
		/// wbindex is a floating paramter it was initialized at 1 by convention and refers the fit index
		Wave wbx_wintel_cur = $( "root:LoadSPE_II:wb" + num2str( wbindex) + "_wintel_cur")
		Wave wbx_wintel_fit = $( "root:LoadSPE_II:wb" + num2str( wbindex) + "_wintel_fit")
		Wave wbx_wintel_base = $( "root:LoadSPE_II:wb" + num2str( wbindex) + "_wintel_base")
		Wave wbx_spectrum = $( "root:LoadSPE_II:wb" + num2str( wbindex) + "_spectrum")
		Wave wbx_frequency = $( "root:LoadSPE_II:wb" + num2str( wbindex) + "_frequency")
		
		// decide where to pull from the frame column
		switch (bandNumber)
			case 1:
				this_wb_begins =  1;
				this_wb_ends = SPE_SWP1_points;
				break;
			case 2:
				this_wb_begins =  SPE_SWP1_points;
				this_wb_ends = SPE_SWP1_points + SPE_SWP2_points;
				break;
			case 3:
				this_wb_begins =  SPE_SWP1_points + SPE_SWP2_points;
				this_wb_ends = SPE_SWP1_points + SPE_SWP2_points + SPE_SWP3_points;
				break;
			case 4:
				this_wb_begins =  SPE_SWP1_points + SPE_SWP2_points + SPE_SWP3_points;
				this_wb_ends = SPE_SWP1_points + SPE_SWP2_points + SPE_SWP3_points + SPE_SWP4_points;
				break;
		endswitch
		// set up and pull from the frame columns
		Redimension/N=(this_swp_pnts) wbx_wintel_cur, wbx_wintel_fit, wbx_wintel_base,wbx_spectrum, wbx_frequency; 
		SetScale/P x, 1 + this_wb_begins, 1, "chan", wbx_wintel_cur, wbx_wintel_fit, wbx_wintel_base,wbx_spectrum, wbx_frequency;
		wbx_spectrum = FrameColumn_1[ this_wb_begins + p ]
		wbx_wintel_fit = FrameColumn_2[ this_wb_begins + p ]
		wbx_wintel_base = FrameColumn_3[ this_wb_begins + p ]
		wbx_wintel_cur = FrameColumn_4[ this_wb_begins + p ]
		wbx_frequency = FrameColumn_5[ this_wb_begins + p ]
		
		
		NVAR PeakPosX = $("root:LoadSPE_II:SPE_PeakPos"+num2str( species_number ) )
		NVAR FingerprintX = $("root:LoadSPE_II:SPE_Fingerprint"+num2str( species_number ) )
		NVAR FreqBand4SpecX = $("root:LoadSPE_II:SPE_FreqBand4Spec"+num2str( species_number ) )
	
		if( (( this_wb_begins <= PeakPosX) && (PeakPosX <= this_wb_ends)) && (species_in_nextFit > 0 ) )
			// This implies that SPE_PeakPosX does exist within the channel bounds which were just snared from FrameColumn(s)
			channel2use = PeakPosX - this_wb_begins
			fingerprint2use = FingerprintX
			wband2use = bandNumber;
		else
			// this is a problem it means that the first species in this wavelength band isn't being fit within the sweep
			NVAR/Z average_verbosity = root:LoadSPE_UI:average_verbosity
			if( NVAR_Exists( average_verbosity ) != 1 )
				String this_folder_vebo = GetDataFolder(1); SetDataFolder root:
				MakeAndOrSetDF( "LoadSPE_UI" ); Variable/G average_verbosity = 1
				NVAR average_verbosity = root:LoadSPE_UI:average_verbosity
				SetDataFolder $this_folder_vebo
			endif
			if( average_verbosity )
				sprintf SPE_FrequencyMSG, "in split frame to wb function ... cannot fully determine channel/species fingerprint relationship for wavelength band %d", idex
				printf "%s\r", SPE_FrequencyMSG
			endif
			
			channel2use = (this_wb_begins + this_wb_ends ) / 2	
			fingerprint2use = 1000
			wband2use = -1
		endif
		idex = species_number
		do
			NVAR FreqBand4SpecX = $("root:LoadSPE_II:SPE_FreqBand4Spec"+num2str( idex ) )
			FreqBand4SpecX = wband2use
			idex += 1
		while( idex <= species_in_this_wb )
		
		//printf "[%d] - %d to %d ", bandNumber, this_wb_begins, this_wb_ends
		//printf "Use Freq: %f, at c = %f/%f \r", fingerprint2use, peakposx, channel2use
		SPE2_FrequencyCalculation( wbx_frequency, fingerprint2use, channel2use )
	
	
		species_number += species_in_nextFit;	// 
		wbindex += 1;
		if( wbindex == 5 )
			//		printf " You have exceed the number of fits this display will parse\r"
			index_in_hand = numpnts(FrameColumn_4)
		endif
		
		// bandNumber is controlled separately from wbindex!! refers to the laser not the fit index
		bandNumber = SPE2_FrameIndex2BandNumber( index_in_hand + 1 );
		// I'm togging this up by one just to make sure we don't end up in a loop, crap, this might not work
			
	while( index_in_hand < numpnts( FrameColumn_4 ) )
	
	
End

Function SPE2_FrameIndex2BandNumber( chan )
	Variable chan
	
	Variable return_band = 0
	
	NVAR  SPE_SWP1_points = root:LoadSPE_II:SPE_SWP1_points; 	NVAR  SPE_SWP2_points = root:LoadSPE_II:SPE_SWP2_points
	NVAR  SPE_SWP3_points = root:LoadSPE_II:SPE_SWP3_points; 	NVAR  SPE_SWP4_points = root:LoadSPE_II:SPE_SWP4_points

	if( chan <= (SPE_SWP1_points) )
		return_band = 1;
	endif
	if( chan <= (SPE_SWP1_points + SPE_SWP2_points) )
		return_band = 2;
	endif
	if( chan <= (SPE_SWP1_points + SPE_SWP2_points + SPE_SWP3_points) )
		return_band = 2;
	endif
	if( chan <= (SPE_SWP1_points + SPE_SWP2_points + SPE_SWP3_points + SPE_SWP4_points) )
		return_band = 2;
	endif
	
	
	return return_band
End
Function SPE2_NumSpeciesStartingAt( wintel_cur, index_in_hand )
	Wave wintel_cur
	Variable &index_in_hand

	
	Variable species = 0
	Variable idex = index_in_hand, count = numpnts( wintel_cur )
	if( count > 0 )
		do
			switch (wintel_cur[idex])
				case k_WINTEL_F1:
					species = 1; index_in_hand = SPE2_Advance2EOFit( wintel_cur, idex )
					idex = count;
					break;
				case k_WINTEL_F2:
					species = 2; index_in_hand = SPE2_Advance2EOFit( wintel_cur, idex )
					idex = count;
					break;
				case k_WINTEL_F3:
					species = 3; index_in_hand = SPE2_Advance2EOFit( wintel_cur, idex )
					idex = count;
					break;
				case k_WINTEL_F4:
					species = 4; index_in_hand = SPE2_Advance2EOFit( wintel_cur, idex )
					idex = count;
					break;
				case k_WINTEL_F5:
					species = 5; index_in_hand = SPE2_Advance2EOFit( wintel_cur, idex )
					idex = count;
					break;
				case k_WINTEL_F6:
					species = 6; index_in_hand = SPE2_Advance2EOFit( wintel_cur, idex )
					idex = count;
					break;
			endswitch
			idex += 1
		while( idex < count )
	endif
	return species
End
End

// This function is where the FiveColumn data is split into wavelength bands -- this is the biggest change
// from previous versions of load spe
Function SPE2_SplitFiveColumnToWBs()
	// The strategy will be to use a combination of SWEEP points and cursors to define several
	// things -- the waves wbx_ have already been defined and are waiting...
	
	SVAR/Z SPE_FrequencyMSG = root:LoadSPE_II:SPE_FrequencyMSG
	if( SVAR_Exists( SPE_FrequencyMSG ) != 1 )
		String saveFolder = GetDataFolder(1)
		SetDataFolder root:; MakeAndOrSetDF( "LoadSPE_II" )
		String/G SPE_FrequencyMSG = "msg initialized"
		SetDataFolder $saveFolder
		SVAR SPE_FrequencyMSG = root:LoadSPE_II:SPE_FrequencyMSG
	endif
		
	NVAR  SPE_version = root:LoadSPE_II:SPE_version
	NVAR  SPE_Total_data_points = root:LoadSPE_II:SPE_Total_data_points
	NVAR  SPE_SWP1_points = root:LoadSPE_II:SPE_SWP1_points; 	NVAR  SPE_SWP2_points = root:LoadSPE_II:SPE_SWP2_points
	NVAR  SPE_SWP3_points = root:LoadSPE_II:SPE_SWP3_points; 	NVAR  SPE_SWP4_points = root:LoadSPE_II:SPE_SWP4_points
	

	NVAR  SPE_FreqResolAtPrimaryF_sw1 = root:LoadSPE_II:SPE_FreqResolAtPrimaryF_sw1;	NVAR  SPE_FreqResolAtPrimaryF_sw2 = root:LoadSPE_II:SPE_FreqResolAtPrimaryF_sw2
	NVAR  SPE_FreqResolAtPrimaryF_sw3 = root:LoadSPE_II:SPE_FreqResolAtPrimaryF_sw3;	NVAR  SPE_FreqResolAtPrimaryF_sw4 = root:LoadSPE_II:SPE_FreqResolAtPrimaryF_sw4	
	
	NVAR  SPE_Channels_in_Off = root:LoadSPE_II:SPE_Channels_in_Off
	
	NVAR  SPE_MenuPower = root:LoadSPE_II:SPE_MenuPower

	NVAR  SPE_PeakPos1 = root:LoadSPE_II:SPE_PeakPos1
	NVAR  SPE_Fingerprint1 = root:LoadSPE_II:SPE_Fingerprint1
	NVAR  SPE_FreqBand4Spec1 = root:LoadSPE_II:SPE_FreqBand4Spec1

	NVAR  SPE_PeakPos2 = root:LoadSPE_II:SPE_PeakPos2;	NVAR  SPE_Fingerprint2 = root:LoadSPE_II:SPE_Fingerprint2; 	NVAR  SPE_FreqBand4Spec2 = root:LoadSPE_II:SPE_FreqBand4Spec2
	NVAR  SPE_PeakPos3 = root:LoadSPE_II:SPE_PeakPos3;	NVAR  SPE_Fingerprint3 = root:LoadSPE_II:SPE_Fingerprint3; 	NVAR  SPE_FreqBand4Spec3 = root:LoadSPE_II:SPE_FreqBand4Spec3
	NVAR  SPE_PeakPos4 = root:LoadSPE_II:SPE_PeakPos4;	NVAR  SPE_Fingerprint4 = root:LoadSPE_II:SPE_Fingerprint4; 	NVAR  SPE_FreqBand4Spec4 = root:LoadSPE_II:SPE_FreqBand4Spec4
	NVAR  SPE_PeakPos5 = root:LoadSPE_II:SPE_PeakPos5;	NVAR  SPE_Fingerprint5 = root:LoadSPE_II:SPE_Fingerprint5; 	NVAR  SPE_FreqBand4Spec5 = root:LoadSPE_II:SPE_FreqBand4Spec5
	NVAR  SPE_PeakPos6 = root:LoadSPE_II:SPE_PeakPos6;	NVAR  SPE_Fingerprint6 = root:LoadSPE_II:SPE_Fingerprint6; 	NVAR  SPE_FreqBand4Spec6 = root:LoadSPE_II:SPE_FreqBand4Spec6
	NVAR  SPE_PeakPos7 = root:LoadSPE_II:SPE_PeakPos7;	NVAR  SPE_Fingerprint7 = root:LoadSPE_II:SPE_Fingerprint7; 	NVAR  SPE_FreqBand4Spec7 = root:LoadSPE_II:SPE_FreqBand4Spec7
	NVAR  SPE_PeakPos8 = root:LoadSPE_II:SPE_PeakPos8;	NVAR  SPE_Fingerprint8 = root:LoadSPE_II:SPE_Fingerprint8; 	NVAR  SPE_FreqBand4Spec8 = root:LoadSPE_II:SPE_FreqBand4Spec8

	Wave/D FrameColumn_1 = root:LoadSPE_II:FrameColumn_1;	Wave/D FrameColumn_2 = root:LoadSPE_II:FrameColumn_2;	Wave/D FrameColumn_3 = root:LoadSPE_II:FrameColumn_3
	Wave/D FrameColumn_4 = root:LoadSPE_II:FrameColumn_4;	Wave/D FrameColumn_5 = root:LoadSPE_II:FrameColumn_5;	Wave/D FrameColumn_6 = root:LoadSPE_II:FrameColumn_6

	Wave/T params_tw = root:LoadSPE_II:params_tw	; Wave/T header_tw = root:LoadSPE_II:header_tw
	
	Wave/D wb1_igr_cur = root:LoadSPE_II:wb1_igr_cur;	Wave/D wb1_wintel_cur = root:LoadSPE_II:wb1_wintel_cur; Wave/D wb1_trans_fit = root:LoadSPE_II:wb1_trans_fit
	Wave/D wb1_trans_spectrum = root:LoadSPE_II:wb1_trans_spectrum; 	Wave/D wb1_wintel_fit = root:LoadSPE_II:wb1_wintel_fit
	Wave/D wb1_wintel_base = root:LoadSPE_II:wb1_wintel_base; 	Wave/D wb1_spectrum = root:LoadSPE_II:wb1_spectrum;  Wave/D wb1_frequency = root:LoadSPE_II:wb1_frequency; 
	
	Wave/D wb2_igr_cur = root:LoadSPE_II:wb2_igr_cur;	Wave/D wb2_wintel_cur = root:LoadSPE_II:wb2_wintel_cur; 	Wave/D wb2_trans_fit = root:LoadSPE_II:wb2_trans_fit;	Wave/D wb2_trans_spectrum = root:LoadSPE_II:wb2_trans_spectrum
	Wave/D wb2_wintel_fit = root:LoadSPE_II:wb2_wintel_fit;	Wave/D wb2_wintel_base = root:LoadSPE_II:wb2_wintel_base
	Wave/D wb2_spectrum = root:LoadSPE_II:wb2_spectrum;	Wave/D wb2_frequency = root:LoadSPE_II:wb2_frequency;

	Wave/D wb3_igr_cur = root:LoadSPE_II:wb3_igr_cur;	Wave/D wb3_wintel_cur = root:LoadSPE_II:wb3_wintel_cur; 	Wave/D wb3_trans_fit = root:LoadSPE_II:wb3_trans_fit;	Wave/D wb3_trans_spectrum = root:LoadSPE_II:wb3_trans_spectrum
	Wave/D wb3_wintel_fit = root:LoadSPE_II:wb3_wintel_fit;	Wave/D wb3_wintel_base = root:LoadSPE_II:wb3_wintel_base
	Wave/D wb3_spectrum = root:LoadSPE_II:wb3_spectrum;	Wave/D wb3_frequency = root:LoadSPE_II:wb3_frequency;

	Wave/D wb4_igr_cur = root:LoadSPE_II:wb4_igr_cur;	Wave/D wb4_wintel_cur = root:LoadSPE_II:wb4_wintel_cur; 	Wave/D wb4_trans_fit = root:LoadSPE_II:wb4_trans_fit;	Wave/D wb4_trans_spectrum = root:LoadSPE_II:wb4_trans_spectrum
	Wave/D wb4_wintel_fit = root:LoadSPE_II:wb4_wintel_fit;	Wave/D wb4_wintel_base = root:LoadSPE_II:wb4_wintel_base
	Wave/D wb4_spectrum = root:LoadSPE_II:wb4_spectrum;	Wave/D wb4_frequency = root:LoadSPE_II:wb4_frequency;

	Wave/D spec_laser_off = root:LoadSPE_II:spec_laser_off

	Variable this_wb_begins = -1, this_wb_ends = -1
	Variable this_swp_pnts, species_number, species_in_this_wb = 0
	Variable bandNumber, channel2use, fingerprint2use, wband2use
	Variable idex
	
	species_number = 1
	bandNumber = 1
	do
		NVAR SPE_SWPX_points = $( "root:LoadSPE_II:SPE_SWP" + num2str(bandNumber) + "_points")
		this_swp_pnts = SPE_SWPX_points
	
		Wave wbx_wintel_cur = $( "root:LoadSPE_II:wb" + num2str( bandNumber) + "_wintel_cur")
		Wave wbx_wintel_fit = $( "root:LoadSPE_II:wb" + num2str( bandNumber) + "_wintel_fit")
		Wave wbx_wintel_base = $( "root:LoadSPE_II:wb" + num2str( bandNumber) + "_wintel_base")
		Wave wbx_spectrum = $( "root:LoadSPE_II:wb" + num2str( bandNumber) + "_spectrum")
		Wave wbx_frequency = $( "root:LoadSPE_II:wb" + num2str( bandNumber) + "_frequency")
	 	
		if( this_swp_pnts > 0 )
			this_wb_begins = this_wb_ends + 1
			this_wb_ends = this_wb_begins + this_swp_pnts
			Redimension/N=(this_swp_pnts) wbx_wintel_cur, wbx_wintel_fit, wbx_wintel_base,wbx_spectrum, wbx_frequency; 
			SetScale/P x, 1 + this_wb_begins, 1, "chan", wbx_wintel_cur, wbx_wintel_fit, wbx_wintel_base,wbx_spectrum, wbx_frequency;
			wbx_spectrum = FrameColumn_1[ this_wb_begins + p ]
			wbx_wintel_fit = FrameColumn_2[ this_wb_begins + p ]
			wbx_wintel_base = FrameColumn_3[ this_wb_begins + p ]
			wbx_wintel_cur = FrameColumn_4[ this_wb_begins + p ]
			wbx_frequency = FrameColumn_5[ this_wb_begins + p ]
			// In order to determine how to properly advance the species_number, we need to 
			// determine the number of species which are being accounted for in this region.
			species_in_this_wb = SPE2_GetNumSpeciesInWB( wbx_wintel_cur );
			if( species_in_this_wb > 0 )
				// it is uncllear whether or not this should be trapped.  A second check
				// of peak position is used in this wb
				// IF the scan has a single wb but two fits, who determines hv?
			
			endif
			NVAR PeakPosX = $("root:LoadSPE_II:SPE_PeakPos"+num2str( species_number ) )
			NVAR FingerprintX = $("root:LoadSPE_II:SPE_Fingerprint"+num2str( species_number ) )
			NVAR FreqBand4SpecX = $("root:LoadSPE_II:SPE_FreqBand4Spec"+num2str( species_number ) )
		
			if( (( this_wb_begins <= PeakPosX) && (PeakPosX <= this_wb_ends)) && (species_in_this_wb > 0 ) )
				// This implies that SPE_PeakPosX does exist within the channel bounds which were just snared from FrameColumn(s)
				channel2use = PeakPosX - this_wb_begins
				fingerprint2use = FingerprintX
				wband2use = bandNumber;
			else
				// this is a problem it means that the first species in this wavelength band isn't being fit within the sweep
				NVAR/Z average_verbosity = root:LoadSPE_UI:average_verbosity
				if( NVAR_Exists( average_verbosity ) != 1 )
					String this_folder_vebo = GetDataFolder(1); SetDataFolder root:
					MakeAndOrSetDF( "LoadSPE_UI" ); Variable/G average_verbosity = 1
					NVAR average_verbosity = root:LoadSPE_UI:average_verbosity
					SetDataFolder $this_folder_vebo
				endif
				if( average_verbosity )
					sprintf SPE_FrequencyMSG, "in split frame to wb function ... cannot fully determine channel/species fingerprint relationship for wavelength band %d", idex
					printf "%s\r", SPE_FrequencyMSG
				endif
				
				channel2use = (this_wb_begins + this_wb_ends ) / 2	
				fingerprint2use = 1000
				wband2use = -1
			endif
			idex = species_number
			do
				NVAR FreqBand4SpecX = $("root:LoadSPE_II:SPE_FreqBand4Spec"+num2str( idex ) )
				FreqBand4SpecX = wband2use
				idex += 1
			while( idex <= species_in_this_wb )
			//printf "[%d] - %d to %d ", bandNumber, this_wb_begins, this_wb_ends
			//printf "Use Freq: %f, at c = %f/%f \r", fingerprint2use, peakposx, channel2use
			SPE2_FrequencyCalculation( wbx_frequency, fingerprint2use, channel2use )
		else
			// there are no points in this sweep
			Redimension/N=0 wbx_wintel_cur, wbx_wintel_fit, wbx_wintel_base,wbx_spectrum, wbx_frequency; 
		endif
		
		// this is just a re-check ... of whether or not the species_number should be advanced
		if( species_in_this_wb > 0 )
			species_number += species_in_this_wb
		else
			// 4/5/2004 -- Dave and Scott think the advancement of species_number is a bug
			// if there were no species in the wb, then species_number should not be advanced.
			// afterall it is entirely possible that species 1 begin on laser 2
			//species_number += 1
		endif
		bandNumber += 1
		

	while( bandNumber <= 4 )
	
	
End
Function SPE2_FrequencyCalculation( freq_w, freq, channel )
	Wave freq_w
	Variable freq, channel
	
	Duplicate/O freq_w, freqScaleDelta_w, freqScaleAbs_w
	DoUpdate
	Variable value_at_channel = freqScaleAbs_w[channel-1]
	//printf "Value at channel = %f\r", value_at_channel
	freq_w = freq 
	freqScaleDelta_w -= value_at_channel
	
	freq_w = freq + freqScaleDelta_w
	freqScaleAbs_w = freq_w
End
Function SPE2_GetNumSpeciesInWB( wintel_cur )
	Wave wintel_cur
	
	Variable species = 0
	Variable idex = 0, count = numpnts( wintel_cur )
	if( count > 0 )
		do
			switch (wintel_cur[idex])
				case k_WINTEL_F1:
					species += 1; idex = SPE2_Advance2EOFit( wintel_cur, idex )
					break;
				case k_WINTEL_F2:
					species += 2; idex = SPE2_Advance2EOFit( wintel_cur, idex )
					break;
				case k_WINTEL_F3:
					species += 3; idex = SPE2_Advance2EOFit( wintel_cur, idex )
					break;
				case k_WINTEL_F4:
					species += 4; idex = SPE2_Advance2EOFit( wintel_cur, idex )
					break;
				case k_WINTEL_F5:
					species += 5; idex = SPE2_Advance2EOFit( wintel_cur, idex )
					break;
				case k_WINTEL_F6:
					species += 6; idex = SPE2_Advance2EOFit( wintel_cur, idex )
					break;
			endswitch
			idex += 1
		while( idex < count )
	endif
	return species
End


Function SPE2_Advance2EOFit( wintel_cur, idex )
	Wave wintel_cur
	Variable idex
	
	Variable return_val = idex
	Variable count = numpnts( wintel_cur )
	do
		if( wintel_cur[idex] == k_WINTEL_EOFit )	
			return idex
		endif
		idex += 1
	while( idex < count )
	return idex - 1 // this is pretty questionable to return the last value even though it wasn't found... 
End
// This function splits a frame_w into header_tw and param_tw -- it may need to be reworked 
// if one gets header != param dimension error -- this is a very likely candidate to fix

Function SPE2_InjectParamIntoFrame( param_name, param_val, frame_tw )
	String param_name
	Variable param_val
	Wave/T frame_tw

	Variable the_index = -1, idex = 0
	String this_header, the_value_str, str
	Variable the_value_num	
	do
		this_header = frame_tw[idex]
		if( strsearch( this_header, param_name, 0) != -1 )
			the_index = idex
			idex = numpnts(frame_tw)
		endif
		idex += 1
	while( idex < numpnts( frame_tw ) )
	if( the_index == -1 )
		return -1
	endif
	if( strsearch( param_name, "time", 0 ) > -1 )
		sprintf str, "%17f", param_val
		String hi = datetime2text( param_val /1000 )
		frame_tw[ the_index + 1 ] = str
	else
		frame_tw[ the_index + 1 ] = num2str( param_val )
	endif
End

Function SPE2_Frame2ParameterWave( frame_w )
	Wave/T frame_w
	
	Wave/T params_tw = root:LoadSPE_II:params_tw	
	Wave/T header_tw = root:LoadSPE_II:header_tw	
	
	Redimension/N=0 params_tw, header_tw
	// Version information -- Should the spe file format change substantially;
	// the following lines may need to be altered
	Variable idex = 0, count = numpnts( frame_w );
	Variable data_begins = -1;
	Variable num_data_points = -1;
	
	if( count > 0 )
	
		AppendString( header_tw, frame_w[0] )
		AppendString( params_tw, frame_w[1] )
		AppendString( header_tw, frame_w[2] )
		AppendString( params_tw, frame_w[3] )		
		
		data_begins = 4; // this implies data begins on the fifth line
		num_data_points = str2num( frame_w[3] )
		if( numtype( num_data_points ) == 0 )
			idex = num_data_points + data_begins;
		else
			idex = data_begins;
		endif
		
		do
			AppendString( header_tw, frame_w[idex] );
			AppendString( params_tw, frame_w[idex+1] );
			idex +=2;
		while( idex < count )
	else
		return -1
	endif
	
	return 0;
End

Function SPE2_InjectFiveColumns2Frame( new_data_wave, column_number, target_frame )
	Wave/d new_data_wave
	Variable column_number
	Wave/T target_frame
	
	Variable idex = 0, count = numpnts( target_frame )
	
	String replace_column
	sprintf replace_column, "root:LoadSPE_II:FrameColumn_%d", column_number
	Wave/Z replace_col_w = $replace_column
	if( WaveExists( replace_col_w ) != 1 )
		printf "Cannot reference target replacement column %s; SPE2 not initialized with template frame loaded?\r", replace_column
		return -1
	endif
	
	// step 1; set the data begins index from target_frame using identical algorithm found in SPE2_Frame2FiveColumns
	// changes there will need to be reflected here -- from that procedure
	String key_search = "spectra follow"
	String line
	Variable data_begins = -1;
	Variable num_data_points = -1;
	// Step 1 in this procedure is to extract the index of the number of points, determine this number of points
	// and set the data begins index
	do
		line = target_frame[idex];
		if( strsearch( line, key_search, 0 ) != -1 )
			data_begins = idex + 2
			num_data_points = str2num( target_frame[idex + 1] )
			
			if( numtype( num_data_points ) != 0 )
				num_data_points = -1; printf "Couldn't interpret %s as numeric value\r", target_frame[idex+1]
			endif
			idex = count;
		endif
		idex += 1;
	while( idex < count )
	if( (data_begins == -1) || (num_data_points == -1) )
		// then a serious problem has arisen
		print "In SPE2_Frame2FiveColumns -- cannot properly interpret frame as spe - aborting function"
		return -1
	endif
	
	// step 2 build identical refs as Frame2Five then run identical algorithm as the reader, but print and set frame contents...
	// Step 2 in this procedure is to extract the column data -- presently this procedure
	// accounts for only a five column load
	// a column 6 is present and defined, but not used ...
	Wave/D/Z FrameColumn_1 = root:LoadSPE_II:FrameColumn_1
	Wave/D FrameColumn_2 = root:LoadSPE_II:FrameColumn_2
	Wave/D FrameColumn_3 = root:LoadSPE_II:FrameColumn_3
	Wave/D FrameColumn_4 = root:LoadSPE_II:FrameColumn_4
	Wave/D FrameColumn_5 = root:LoadSPE_II:FrameColumn_5
	Wave/D FrameColumn_6 = root:LoadSPE_II:FrameColumn_6

	// now overlay the replacement
	switch (column_number)
		case 1:
			// This is the data or spectrum column as of TDL 5, 6, 7.... we'll only 
			// really do this one, for now...
			Variable kdex = 0, kcount = numpnts( new_data_wave ), fcount = numpnts( FrameColumn_1)
			do
				FrameColumn_1[kdex] = new_data_wave[kdex]
				kdex += 1
			while( kdex < kcount )
			if( kdex < fcount )
				do
					FrameColumn_1[kdex] = 0
					kdex += 1
				while( kdex < fcount )
			endif
			
			break;
		case 2:
			Duplicate/O/D new_data_wave, FrameColumn_2
			break;
		case 3:
			Duplicate/O/D new_data_wave, FrameColumn_3
			break;
		case 4:
			Duplicate/O/D new_data_wave, FrameColumn_4
			break;
		case 5:
			Duplicate/O/D new_data_wave, FrameColumn_5
			break;
		case 6:
			Duplicate/O/D new_data_wave, FrameColumn_6
			break;					
	endswitch
	
	//	Redimension/N=(num_data_points) FrameColumn_1, FrameColumn_2, FrameColumn_3, FrameColumn_4, FrameColumn_5, FrameColumn_6
	//	FrameColumn_6 = Nan
	
	Variable num1, num2, num3, num4, num5
	idex = data_begins
	do
		
		
		num1 = FrameColumn_1[idex - data_begins ] 
		num2 = FrameColumn_2[idex - data_begins ] 
		num3 = FrameColumn_3[idex - data_begins ] 
		num4 = FrameColumn_4[idex - data_begins ] 
		num5 = FrameColumn_5[idex - data_begins ] 
		sprintf line, "%9.5f %9.5f %9.5f %f %9.8f", num1, num2, num3, num4, num5
		target_frame[idex] = line;
		idex += 1
	while( idex - data_begins < num_data_points )
	return 0
	
	
End
Function SPE2_Frame2FiveColumns( frame_w )
	Wave/T frame_w
	
	Variable idex = 0, count = numpnts( frame_w );
	
	String key_search = "spectra follow"
	String line
	Variable data_begins = -1;
	Variable num_data_points = -1;
	// Step 1 in this procedure is to extract the index of the number of points, determine this number of points
	// and set the data begins index
	do
		line = frame_w[idex];
		if( strsearch( line, key_search, 0 ) != -1 )
			data_begins = idex + 2
			num_data_points = str2num( frame_w[idex + 1] )
			
			if( numtype( num_data_points ) != 0 )
				num_data_points = -1; printf "Couldn't interpret %s as numeric value\r", frame_w[idex+1]
			endif
			idex = count;
		endif
		idex += 1;
	while( idex < count )
	if( (data_begins == -1) || (num_data_points == -1) )
		// then a serious problem has arisen
		print "In SPE2_Frame2FiveColumns -- cannot properly interpret frame as spe - aborting function"
		return -1
	endif
	
	// Step 2 in this procedure is to extract the column data -- presently this procedure
	// accounts for only a five column load
	// a column 6 is present and defined, but not used ...
	
	Wave/D/Z FrameColumn_1 = root:LoadSPE_II:FrameColumn_1
	if( WaveExists( FrameColumn_1 ) != 1 )
		printf "Cannot reference FrameCol1 in Frame2FiveColumnes ...Perhaps SPE2 not initialized?\r"
		return -1
	endif
	
	Wave/D FrameColumn_2 = root:LoadSPE_II:FrameColumn_2
	Wave/D FrameColumn_3 = root:LoadSPE_II:FrameColumn_3
	Wave/D FrameColumn_4 = root:LoadSPE_II:FrameColumn_4
	Wave/D FrameColumn_5 = root:LoadSPE_II:FrameColumn_5
	Wave/D FrameColumn_6 = root:LoadSPE_II:FrameColumn_6

	Redimension/N=(num_data_points) FrameColumn_1, FrameColumn_2, FrameColumn_3, FrameColumn_4, FrameColumn_5, FrameColumn_6
	FrameColumn_6 = Nan
	
	Variable num1, num2, num3, num4, num5
	idex = data_begins
	do
		line = frame_w[idex];
		sscanf line, "%f %f %f %f %f", num1, num2, num3, num4, num5
		FrameColumn_1[idex - data_begins ] = num1;
		FrameColumn_2[idex - data_begins ] = num2;
		FrameColumn_3[idex - data_begins ] = num3;
		FrameColumn_4[idex - data_begins ] = num4;
		FrameColumn_5[idex - data_begins ] = num5;

		idex += 1
	while( idex - data_begins < num_data_points )
	return 0
	
End

Function SPE2_GetSPEParamNumeric( param_name, param_header_w, param_w )
	String param_name
	Wave/T param_header_w, param_w

	Variable the_index = -1, idex = 0
	String this_header, the_value_str
	Variable the_value_num	
	do
		this_header = param_header_w[idex]
		if( strsearch( this_header, param_name, 0) != -1 )
			the_index = idex
			idex = numpnts(param_header_w)
		endif
		idex += 1
	while( idex < numpnts( param_header_w ) )
	if( the_index == -1 )
		return -1
	endif
	the_value_str = param_w[the_index]
	if( cmpstr( the_value_str, "#TRUE#" ) == 0 )
		return 1
	endif
	if( cmpstr( the_value_str, "#FALSE#") == 0 )
		return 0
	endif
	if( numtype( str2num( the_value_str ) ) == 0 )
		return str2num( the_value_str )
	endif
	// couldn't figure out what to do with param
	return -2

End

Function/T SPE2_GetSPEParamText( param_name, param_header_w, param_w, start_index )
	String param_name
	Wave/T param_header_w, param_w
	Variable start_index
	
	NVAR/Z GotDex = root:LoadSPE_II:GetSPEParamText_Index
	if( NVAR_Exists( GotDex ) != 1 )
		String saveFolder = GetDataFolder(1)
		SetDataFolder root:; MakeAndOrSetDF( "LoadSPE_II" )
		Variable/G GetSPEParamText_Index
		SetDataFolder $saveFolder
		NVAR GotDex = root:LoadSPE_II:GetSPEParamText_Index
	endif
	
	Variable the_index = -1, idex = start_index, count = numpnts( param_header_w );
	String this_header, the_value_str
	Variable the_value_num	
	do
		this_header = param_header_w[idex]
		if( strsearch( this_header, param_name, 0) != -1 )
			the_index = idex
			idex = count;
		endif
		idex += 1
	while( idex < count )
	if( the_index == -1 )
		idex = 0
		do
			this_header = param_header_w[idex]
			if( strsearch( this_header, param_name, 0) != -1 )
				the_index = idex
				idex = count;
			endif
			idex += 1
		while( idex < count )
		return "Not Found"
	endif
	the_value_str = param_w[the_index]
	GotDex = the_index;
	return( the_value_str)
End

/////////////////////////////////////////////// Functions which follow are extremely long and tedious
////////////// They include
/////////// SPE2_Param2GlobalsAndDisp( ) -- this beast attempts to quickly pick out
/////////// parameters from the root:LoadSPE_II:header_tw & param_tw pair and load
/////////// them into the globals in root:LoadSPE_II
/////////// it is through this mechanism that the rolling panel items update on browse
/////////// the at_line/GotDex mechanism speeds the execution of this routine by ~40%
///////////
///////////
/////////// SPE2_Initialize() -- this is the main initialization and reference function 
/////////// to all new globals -- edit this one and BE SURE TO INCLUDE ROBUST REFERENCE
/////////// at the bottom of initialize, write out a reference which could be invoked anywhere
/////////// by so doing, you will make the code easier to maintain - trust me (scott) 

Function SPE2_Param2GlobalsAndDisp( )
	
	NVAR  SPE_version = root:LoadSPE_II:SPE_version
	NVAR  SPE_FieldNumber = root:LoadSPE_II:SPE_FieldNumber
	NVAR  SPE_Total_data_points = root:LoadSPE_II:SPE_Total_data_points
	NVAR  SPE_SWP1_points = root:LoadSPE_II:SPE_SWP1_points
	NVAR  SPE_SWP2_points = root:LoadSPE_II:SPE_SWP2_points
	NVAR  SPE_SWP3_points = root:LoadSPE_II:SPE_SWP3_points
	NVAR  SPE_SWP4_points = root:LoadSPE_II:SPE_SWP4_points
	
	NVAR  SPE_Channels_in_Off = root:LoadSPE_II:SPE_Channels_in_Off
	
	NVAR  SPE_CellResponse = root:LoadSPE_II:SPE_CellResponse
	NVAR  SPE_CellPressure = root:LoadSPE_II:SPE_CellPressure
	NVAR  SPE_CellTemperature = root:LoadSPE_II:SPE_CellTemperature
	NVAR  SPE_PathLength = root:LoadSPE_II:SPE_PathLength
	NVAR  SPE_MenuPower = root:LoadSPE_II:SPE_MenuPower
	
	NVAR  SPE_Linewidth1 = root:LoadSPE_II:SPE_Linewidth1
	NVAR  SPE_Linewidth2 = root:LoadSPE_II:SPE_Linewidth2
	NVAR  SPE_Linewidth3 = root:LoadSPE_II:SPE_Linewidth3
	NVAR  SPE_Linewidth4 = root:LoadSPE_II:SPE_Linewidth4
	
	NVAR  SPE_Polynomial = root:LoadSPE_II:SPE_Polynomial
	
	NVAR  SPE_PeakPos1 = root:LoadSPE_II:SPE_PeakPos1
	NVAR  SPE_PeakFixed1 = root:LoadSPE_II:SPE_PeakFixed1
	NVAR  SPE_MixRatio1 = root:LoadSPE_II:SPE_MixRatio1
	NVAR  SPE_Fingerprint1 = root:LoadSPE_II:SPE_Fingerprint1
	SVAR  SPE_HitFile1 = root:LoadSPE_II:SPE_HitFile1
	NVAR  SPE_HitFile1_Found = root:LoadSPE_II:SPE_HitFile1_Found
	NVAR  SPE_HitFile1_Loaded = root:LoadSPE_II:SPE_HitFile1_Loaded
	NVAR  SPE_FreqBand4Spec1 = root:LoadSPE_II:SPE_FreqBand4Spec1
	
	NVAR  SPE_PeakPos2 = root:LoadSPE_II:SPE_PeakPos2;	NVAR  SPE_PeakFixed2 = root:LoadSPE_II:SPE_PeakFixed2; NVAR  SPE_MixRatio2 = root:LoadSPE_II:SPE_MixRatio2; 
	NVAR  SPE_Fingerprint2 = root:LoadSPE_II:SPE_Fingerprint2;	SVAR  SPE_HitFile2 = root:LoadSPE_II:SPE_HitFile2; NVAR  SPE_HitFile2_Found = root:LoadSPE_II:SPE_HitFile2_Found; NVAR  SPE_HitFile2_Loaded = root:LoadSPE_II:SPE_HitFile2_Loaded; NVAR  SPE_FreqBand4Spec2 = root:LoadSPE_II:SPE_FreqBand4Spec2
		
	NVAR  SPE_PeakPos3 = root:LoadSPE_II:SPE_PeakPos3;	NVAR  SPE_PeakFixed3 = root:LoadSPE_II:SPE_PeakFixed3; NVAR  SPE_MixRatio3 = root:LoadSPE_II:SPE_MixRatio3; 
	NVAR  SPE_Fingerprint3 = root:LoadSPE_II:SPE_Fingerprint3;	SVAR  SPE_HitFile3 = root:LoadSPE_II:SPE_HitFile3; NVAR  SPE_HitFile3_Found = root:LoadSPE_II:SPE_HitFile3_Found; NVAR  SPE_HitFile3_Loaded = root:LoadSPE_II:SPE_HitFile3_Loaded; NVAR  SPE_FreqBand4Spec3 = root:LoadSPE_II:SPE_FreqBand4Spec3

	NVAR  SPE_PeakPos4 = root:LoadSPE_II:SPE_PeakPos4;	NVAR  SPE_PeakFixed4 = root:LoadSPE_II:SPE_PeakFixed4; NVAR  SPE_MixRatio4 = root:LoadSPE_II:SPE_MixRatio4; 
	NVAR  SPE_Fingerprint4 = root:LoadSPE_II:SPE_Fingerprint4;	SVAR  SPE_HitFile4 = root:LoadSPE_II:SPE_HitFile4; NVAR  SPE_HitFile4_Found = root:LoadSPE_II:SPE_HitFile4_Found; NVAR  SPE_HitFile4_Loaded = root:LoadSPE_II:SPE_HitFile4_Loaded; NVAR  SPE_FreqBand4Spec4 = root:LoadSPE_II:SPE_FreqBand4Spec4

	NVAR  SPE_PeakPos5 = root:LoadSPE_II:SPE_PeakPos5;	NVAR  SPE_PeakFixed5 = root:LoadSPE_II:SPE_PeakFixed5; NVAR  SPE_MixRatio5 = root:LoadSPE_II:SPE_MixRatio5; 
	NVAR  SPE_Fingerprint5 = root:LoadSPE_II:SPE_Fingerprint5;	SVAR  SPE_HitFile5 = root:LoadSPE_II:SPE_HitFile5; NVAR  SPE_HitFile5_Found = root:LoadSPE_II:SPE_HitFile5_Found; NVAR  SPE_HitFile5_Loaded = root:LoadSPE_II:SPE_HitFile5_Loaded; NVAR  SPE_FreqBand4Spec5 = root:LoadSPE_II:SPE_FreqBand4Spec5

	NVAR  SPE_PeakPos6 = root:LoadSPE_II:SPE_PeakPos6;	NVAR  SPE_PeakFixed6 = root:LoadSPE_II:SPE_PeakFixed6; NVAR  SPE_MixRatio6 = root:LoadSPE_II:SPE_MixRatio6; 
	NVAR  SPE_Fingerprint6 = root:LoadSPE_II:SPE_Fingerprint6;	SVAR  SPE_HitFile6 = root:LoadSPE_II:SPE_HitFile6; NVAR  SPE_HitFile6_Found = root:LoadSPE_II:SPE_HitFile6_Found; NVAR  SPE_HitFile6_Loaded = root:LoadSPE_II:SPE_HitFile6_Loaded; NVAR  SPE_FreqBand4Spec6 = root:LoadSPE_II:SPE_FreqBand4Spec6

	NVAR  SPE_PeakPos7 = root:LoadSPE_II:SPE_PeakPos7;	NVAR  SPE_PeakFixed7 = root:LoadSPE_II:SPE_PeakFixed7; NVAR  SPE_MixRatio7 = root:LoadSPE_II:SPE_MixRatio7; 
	NVAR  SPE_Fingerprint7 = root:LoadSPE_II:SPE_Fingerprint7;	SVAR  SPE_HitFile7 = root:LoadSPE_II:SPE_HitFile7; NVAR  SPE_HitFile7_Found = root:LoadSPE_II:SPE_HitFile7_Found; NVAR  SPE_HitFile7_Loaded = root:LoadSPE_II:SPE_HitFile7_Loaded; NVAR  SPE_FreqBand4Spec7 = root:LoadSPE_II:SPE_FreqBand4Spec7

	NVAR  SPE_PeakPos8 = root:LoadSPE_II:SPE_PeakPos8;	NVAR  SPE_PeakFixed8 = root:LoadSPE_II:SPE_PeakFixed8; NVAR  SPE_MixRatio8 = root:LoadSPE_II:SPE_MixRatio8; 
	NVAR  SPE_Fingerprint8 = root:LoadSPE_II:SPE_Fingerprint8;	SVAR  SPE_HitFile8 = root:LoadSPE_II:SPE_HitFile8; NVAR  SPE_HitFile8_Found = root:LoadSPE_II:SPE_HitFile8_Found; NVAR  SPE_HitFile8_Loaded = root:LoadSPE_II:SPE_HitFile8_Loaded; NVAR  SPE_FreqBand4Spec8 = root:LoadSPE_II:SPE_FreqBand4Spec8

	NVAR  SPE_timestamp = root:LoadSPE_II:SPE_timestamp;
	SVAR  SPE_time_date = root:LoadSPE_II:SPE_time_date;
	NVAR  SPE_ContinuousRefLok = root:LoadSPE_II:SPE_ContinuousRefLok;

	Wave/D FrameColumn_1 = root:LoadSPE_II:FrameColumn_1
	Wave/D FrameColumn_2 = root:LoadSPE_II:FrameColumn_2
	Wave/D FrameColumn_3 = root:LoadSPE_II:FrameColumn_3
	Wave/D FrameColumn_4 = root:LoadSPE_II:FrameColumn_4
	Wave/D FrameColumn_5 = root:LoadSPE_II:FrameColumn_5
	Wave/D FrameColumn_6 = root:LoadSPE_II:FrameColumn_6

	Wave/T params_tw = root:LoadSPE_II:params_tw	
	Wave/T header_tw = root:LoadSPE_II:header_tw	
	
	String paramStr
	Variable quick_dex
	Variable at_line = 0, count = numpnts( params_tw )
	Variable header_count = numpnts( header_tw )
	if( header_count != count )
		printf "Warning:  params_tw and header_tw in root:LoadSPE_II do not have equivalent dimension\r"
	endif
	
	// Variable or String we are searching for is: version
	// This is commonly the first parameter, we will use string search
	SPE_version = -1;
	if( strsearch( lowerStr(header_tw[0]), "version", 0 ) != -1 )
		SPE_version = str2num( params_tw[0])
		at_line = 1
	else
		if( strsearch( lowerStr(header_tw[1]), "version", 0 ) != -1 )
			SPE_version = str2num(params_tw[1] )
			at_line = 2
		endif
	endif
	
	SPE_Total_data_points = -1;
	if( strsearch( header_tw[at_line], "spectra follow", 0 ) != -1 )
		paramStr = header_tw[at_line]
		quick_dex = strsearch( lowerStr(paramStr), lowerstr("Field"), 0)
		if( quick_dex != -1 )
			sscanf lowerStr(paramStr), "field %d spectra", SPE_FieldNumber
		else
			SPE_FieldNumber = -1
		endif	
		SPE_total_data_points = str2num(params_tw[ at_line ] )
		at_line += 1
	endif
	
	
	// Now we may begin to use our head a little
	NVAR  SPE_Channels_in_Off = root:LoadSPE_II:SPE_Channels_in_Off
	
	NVAR  SPE_CellResponse = root:LoadSPE_II:SPE_CellResponse
	NVAR  SPE_CellPressure = root:LoadSPE_II:SPE_CellPressure
	NVAR  SPE_CellTemperature = root:LoadSPE_II:SPE_CellTemperature
	NVAR  SPE_PathLength = root:LoadSPE_II:SPE_PathLength
	NVAR  SPE_MenuPower = root:LoadSPE_II:SPE_MenuPower
	
	paramStr = SPE2_GetSPEParamText( "number of channels in off pulse", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_Channels_in_Off = -1
	else
		SPE_Channels_in_Off = str2num( paramStr )
	endif
	
	NVAR GotDex = root:LoadSPE_II:GetSPEParamText_Index
	at_line = GotDex; // cheating hook from last GetSPEParamText Call
	
	
	paramStr = SPE2_GetSPEParamText( "number of channels in sweep  1", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_SWP1_points = -1
	else
		SPE_SWP1_points = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call
	
	paramStr = SPE2_GetSPEParamText( "number of channels in sweep  2", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_SWP2_points = -1
	else
		SPE_SWP2_points = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call

	paramStr = SPE2_GetSPEParamText( "number of channels in sweep  3", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_SWP3_points = -1
	else
		SPE_SWP3_points = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call
	paramStr = SPE2_GetSPEParamText( "number of channels in sweep  4", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_SWP4_points = -1
	else
		SPE_SWP4_points = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call
	
	paramStr = SPE2_GetSPEParamText( "cell response time", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_CellResponse = -1
	else
		SPE_CellResponse = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call
	
	paramStr = SPE2_GetSPEParamText( "cell pressure", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_CellPressure = -1
	else
		SPE_CellPressure = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call	
	
	paramStr = SPE2_GetSPEParamText( "cell temp", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_CellTemperature = -1
	else
		SPE_CellTemperature = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call	

	paramStr = SPE2_GetSPEParamText( "pathlength", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_PathLength = -1
	else
		SPE_PathLength = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call	

	paramStr = SPE2_GetSPEParamText( "laser power, I0", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_MenuPower = -1
	else
		SPE_MenuPower = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call

	paramStr = SPE2_GetSPEParamText( "line width  1", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_Linewidth1 = -1
	else
		SPE_Linewidth1 = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call		
	paramStr = SPE2_GetSPEParamText( "line width  2", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_Linewidth2 = -1
	else
		SPE_Linewidth2 = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call		
	paramStr = SPE2_GetSPEParamText( "line width  3", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_Linewidth3 = -1
	else
		SPE_Linewidth3 = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call		
	paramStr = SPE2_GetSPEParamText( "line width  4", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_Linewidth4 = -1
	else
		SPE_Linewidth4 = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call						
	paramStr = SPE2_GetSPEParamText( "poly order for fits", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_Polynomial = -1
	else
		SPE_Polynomial = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call	

	// set for species 1 -- this is again, messy, but may allow a quick remap if future versions of file require something else

	paramStr = SPE2_GetSPEParamText( "peak position 1", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_PeakPos1 = -1
	else
		SPE_PeakPos1 = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call	
		
	paramStr = SPE2_GetSPEParamText( "fix pos? 1", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_PeakFixed1 = -1
	else
		if( cmpstr( paramStr, "#TRUE#" ) == 0 )
			SPE_PeakFixed1 = 1;
		else
			SPE_PeakFixed1 = 0;
		endif
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call		

	paramStr = SPE2_GetSPEParamText( "mix ratio 1", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_MixRatio1 = -1
	else
		SPE_MixRatio1 = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call	
	
	paramStr = SPE2_GetSPEParamText( "fingerprint frequency 1", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_Fingerprint1 = -1
	else
		SPE_Fingerprint1 = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call		
	
	paramStr = SPE2_GetSPEParamText( "hit file 1", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_HitFile1 = "no hitfile"
	else
		SPE_HitFile1 = paramStr
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call
	
	SPE_HitFile1_Found = -1
	SPE_HitFile1_Loaded = -1			
	SPE_FreqBand4Spec1 = -1

	// set for species 2 -- this is again, messy, but may allow a quick remap if future versions of file require something else

	paramStr = SPE2_GetSPEParamText( "peak position 2", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_PeakPos2 = -1
	else
		SPE_PeakPos2 = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call	
		
	paramStr = SPE2_GetSPEParamText( "fix pos? 2", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_PeakFixed2 = -1
	else
		if( cmpstr( paramStr, "#TRUE#" ) == 0 )
			SPE_PeakFixed2 = 1;
		else
			SPE_PeakFixed2 = 0;
		endif
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call		

	paramStr = SPE2_GetSPEParamText( "mix ratio 2", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_MixRatio2 = -1
	else
		SPE_MixRatio2 = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call	
	
	paramStr = SPE2_GetSPEParamText( "fingerprint frequency 2", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_Fingerprint2 = -1
	else
		SPE_Fingerprint2 = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call		
	
	paramStr = SPE2_GetSPEParamText( "hit file 2", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_HitFile2 = "no hitfile"
	else
		SPE_HitFile2 = paramStr
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call
	
	SPE_HitFile2_Found = -1
	SPE_HitFile2_Loaded = -1			
	SPE_FreqBand4Spec2 = -1	
	
	// set for species 3 -- this is again, messy, but may allow a quick remap if future versions of file require something else

	paramStr = SPE2_GetSPEParamText( "peak position 3", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_PeakPos3 = -1
	else
		SPE_PeakPos3 = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call	
		
	paramStr = SPE2_GetSPEParamText( "fix pos? 3", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_PeakFixed3 = -1
	else
		if( cmpstr( paramStr, "#TRUE#" ) == 0 )
			SPE_PeakFixed3 = 1;
		else
			SPE_PeakFixed3 = 0;
		endif
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call		

	paramStr = SPE2_GetSPEParamText( "mix ratio 3", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_MixRatio3 = -1
	else
		SPE_MixRatio3 = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call	
	
	paramStr = SPE2_GetSPEParamText( "fingerprint frequency 3", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_Fingerprint3 = -1
	else
		SPE_Fingerprint3 = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call		
	
	paramStr = SPE2_GetSPEParamText( "hit file 3", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_HitFile3 = "no hitfile"
	else
		SPE_HitFile3 = paramStr
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call
	
	SPE_HitFile3_Found = -1
	SPE_HitFile3_Loaded = -1			
	SPE_FreqBand4Spec3 = -1		
	// set for species 4 -- this is again, messy, but may allow a quick remap if future versions of file require something else

	paramStr = SPE2_GetSPEParamText( "peak position 4", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_PeakPos4 = -1
	else
		SPE_PeakPos4 = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call	
		
	paramStr = SPE2_GetSPEParamText( "fix pos? 4", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_PeakFixed4 = -1
	else
		if( cmpstr( paramStr, "#TRUE#" ) == 0 )
			SPE_PeakFixed4 = 1;
		else
			SPE_PeakFixed4 = 0;
		endif
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call		

	paramStr = SPE2_GetSPEParamText( "mix ratio 4", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_MixRatio4 = -1
	else
		SPE_MixRatio4 = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call	
	
	paramStr = SPE2_GetSPEParamText( "fingerprint frequency 4", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_Fingerprint4 = -1
	else
		SPE_Fingerprint4 = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call		
	
	paramStr = SPE2_GetSPEParamText( "hit file 4", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_HitFile4 = "no hitfile"
	else
		SPE_HitFile4 = paramStr
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call
	
	SPE_HitFile4_Found = -1
	SPE_HitFile4_Loaded = -1			
	SPE_FreqBand4Spec4 = -1	
		
	// set for species 5 -- this is again, messy, but may allow a quick remap if future versions of file require something else

	paramStr = SPE2_GetSPEParamText( "peak position 5", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_PeakPos5 = -1
	else
		SPE_PeakPos5 = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call	
		
	paramStr = SPE2_GetSPEParamText( "fix pos? 5", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_PeakFixed5 = -1
	else
		if( cmpstr( paramStr, "#TRUE#" ) == 0 )
			SPE_PeakFixed5 = 1;
		else
			SPE_PeakFixed5 = 0;
		endif
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call		

	paramStr = SPE2_GetSPEParamText( "mix ratio 5", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_MixRatio5 = -1
	else
		SPE_MixRatio5 = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call	
	
	paramStr = SPE2_GetSPEParamText( "fingerprint frequency 5", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_Fingerprint5 = -1
	else
		SPE_Fingerprint5 = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call		
	
	paramStr = SPE2_GetSPEParamText( "hit file 5", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_HitFile5 = "no hitfile"
	else
		SPE_HitFile5 = paramStr
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call
	
	SPE_HitFile5_Found = -1
	SPE_HitFile5_Loaded = -1			
	SPE_FreqBand4Spec5 = -1		
	// set for species 6 -- this is again, messy, but may allow a quick remap if future versions of file require something else

	paramStr = SPE2_GetSPEParamText( "peak position 6", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_PeakPos6 = -1
	else
		SPE_PeakPos6 = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call	
		
	paramStr = SPE2_GetSPEParamText( "fix pos? 6", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_PeakFixed6 = -1
	else
		if( cmpstr( paramStr, "#TRUE#" ) == 0 )
			SPE_PeakFixed6 = 1;
		else
			SPE_PeakFixed6 = 0;
		endif
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call		

	paramStr = SPE2_GetSPEParamText( "mix ratio 6", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_MixRatio6 = -1
	else
		SPE_MixRatio6 = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call	
	
	paramStr = SPE2_GetSPEParamText( "fingerprint frequency 6", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_Fingerprint6 = -1
	else
		SPE_Fingerprint6 = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call		
	
	paramStr = SPE2_GetSPEParamText( "hit file 6", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_HitFile6 = "no hitfile"
	else
		SPE_HitFile6 = paramStr
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call
	
	SPE_HitFile6_Found = -1
	SPE_HitFile6_Loaded = -1			
	SPE_FreqBand4Spec6 = -1		
	// set for species 7 -- this is again, messy, but may allow a quick remap if future versions of file require something else

	paramStr = SPE2_GetSPEParamText( "peak position 7", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_PeakPos7 = -1
	else
		SPE_PeakPos7 = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call	
		
	paramStr = SPE2_GetSPEParamText( "fix pos? 7", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_PeakFixed7 = -1
	else
		if( cmpstr( paramStr, "#TRUE#" ) == 0 )
			SPE_PeakFixed7 = 1;
		else
			SPE_PeakFixed7 = 0;
		endif
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call		

	paramStr = SPE2_GetSPEParamText( "mix ratio 7", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_MixRatio7 = -1
	else
		SPE_MixRatio7 = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call	
	
	paramStr = SPE2_GetSPEParamText( "fingerprint frequency 7", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_Fingerprint7 = -1
	else
		SPE_Fingerprint7 = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call		
	
	paramStr = SPE2_GetSPEParamText( "hit file 7", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_HitFile7 = "no hitfile"
	else
		SPE_HitFile7 = paramStr
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call
	
	SPE_HitFile7_Found = -1
	SPE_HitFile7_Loaded = -1			
	SPE_FreqBand4Spec7 = -1	
	// set for species 8 -- this is again, messy, but may allow a quick remap if future versions of file require something else

	paramStr = SPE2_GetSPEParamText( "peak position 8", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_PeakPos8 = -1
	else
		SPE_PeakPos8 = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call	
		
	paramStr = SPE2_GetSPEParamText( "fix pos? 8", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_PeakFixed8 = -1
	else
		if( cmpstr( paramStr, "#TRUE#" ) == 0 )
			SPE_PeakFixed8 = 1;
		else
			SPE_PeakFixed8 = 0;
		endif
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call		

	paramStr = SPE2_GetSPEParamText( "mix ratio 8", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_MixRatio8 = -1
	else
		SPE_MixRatio8 = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call	
	
	paramStr = SPE2_GetSPEParamText( "fingerprint frequency 8", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_Fingerprint8 = -1
	else
		SPE_Fingerprint8 = str2num( paramStr )
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call		
	
	paramStr = SPE2_GetSPEParamText( "hit file 8", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_HitFile8 = "no hitfile"
	else
		SPE_HitFile8 = paramStr
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call
	
	SPE_HitFile8_Found = -1
	SPE_HitFile8_Loaded = -1			
	SPE_FreqBand4Spec8 = -1	
	
	
	paramStr = SPE2_GetSPEParamText( "timestamp", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_timestamp = -1
	else
		SPE_timestamp = str2num( paramStr ) / 1000
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call

	
	paramStr = SPE2_GetSPEParamText( "time and date", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_time_date = "unknown"
	else
		SPE_time_date =  paramStr 
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call

	paramStr = SPE2_GetSPEParamText( "time and date", header_tw, params_tw, at_line )
	if( cmpstr( paramStr, "Not Found" ) == 0 )
		SPE_ContinuousRefLok = -1
	else
		if( cmpstr( paramStr, "#TRUE#" ) == 0 )
			SPE_ContinuousRefLok = 1
		else
			SPE_ContinuousRefLok = 0
		endif
	endif
	at_line = GotDex; // cheating hook from last GetSPEParamText Call
	
	
		
End

Function SPE2_Initialize()
	
	String saveFolder = GetDataFolder(1)
	SetDataFolder root:
	MakeAndOrSetDF( "LoadSPE_II" )
	//
	// Global variables and waves for LoadSPE_II's operation
	//
	
	// The following are the behind the scenes operators
	Make/N=0/O/T params_tw, header_tw
	Make/N=100/D/O FrameColumn_1, FrameColumn_2, FrameColumn_3, FrameColumn_4, FrameColumn_5, FrameColumn_6
	Make/N=25/D/O wb1_igr_cur, wb1_wintel_cur, wb1_trans_fit, wb1_trans_spectrum, wb1_wintel_fit, wb1_wintel_base, wb1_spectrum, wb1_frequency


	
	Make/N=25/D/O wb2_igr_cur, wb2_wintel_cur, wb2_trans_fit, wb2_trans_spectrum, wb2_wintel_fit, wb2_wintel_base, wb2_spectrum, wb2_frequency
	Make/N=25/D/O wb3_igr_cur, wb3_wintel_cur, wb3_trans_fit, wb3_trans_spectrum, wb3_wintel_fit, wb3_wintel_base, wb3_spectrum, wb3_frequency
	Make/N=25/D/O wb4_igr_cur, wb4_wintel_cur, wb4_trans_fit, wb4_trans_spectrum, wb4_wintel_fit, wb4_wintel_base, wb4_spectrum, wb4_frequency

	Make/N=10/D/O spec_laser_off
	
	Variable/G spe2init = 0;
	
	Variable/G working_with_zip = 0;
	
	Variable/G SPE_version = -1;
	Variable/G SPE_FieldNumber = -1;
	Variable/G SPE_Total_data_points = -1;
	Variable/G SPE_SWP1_points = -1;
	Variable/G SPE_SWP2_points = -1;
	Variable/G SPE_SWP3_points = -1;
	Variable/G SPE_SWP4_points = -1;

	Variable/G SPE_FreqResolAtPrimaryF_sw1 = -1;
	Variable/G SPE_FreqResolAtPrimaryF_sw2 = -1;
	Variable/G SPE_FreqResolAtPrimaryF_sw3 = -1;
	Variable/G SPE_FreqResolAtPrimaryF_sw4 = -1;
		
	Variable/G SPE_Channels_in_Off = -1;
	
	Variable/G SPE_CellResponse = -1;
	Variable/G SPE_CellPressure = -1;
	Variable/G SPE_CellTemperature = -1;
	Variable/G SPE_PathLength = -1;
	Variable/G SPE_MenuPower = -1;
	
	Variable/G SPE_Linewidth1 = -1;
	Variable/G SPE_Linewidth2 = -1;
	Variable/G SPE_Linewidth3 = -1;
	Variable/G SPE_Linewidth4 = -1;
	
	Variable/G SPE_LaserPower_1 = -1;
	Variable/G SPE_LaserPower_2 = -1;
	Variable/G SPE_LaserPower_3 = -1;
	Variable/G SPE_LaserPower_4 = -1;
	
	Variable/G SPE_Polynomial = -1;
	

	Variable/G SPE_PeakPos1 = -1;
	Variable/G SPE_PeakFixed1 = -1;
	Variable/G SPE_MixRatio1 = -1;
	Variable/G SPE_Fingerprint1 = -1;
	String/G SPE_HitFile1 = "na";
	Variable/G SPE_HitFile1_Found = -1;
	Variable/G SPE_HitFile1_Loaded = -1;
	Variable/G SPE_FreqBand4Spec1 = -1;
	
	Variable/G SPE_PeakPos2 = -1;
	Variable/G SPE_PeakFixed2 = -1;
	Variable/G SPE_MixRatio2 = -1;
	Variable/G SPE_Fingerprint2 = -1;
	String/G SPE_HitFile2 = "na";
	Variable/G SPE_HitFile2_Found = -1;
	Variable/G SPE_HitFile2_Loaded = -1;
	Variable/G SPE_FreqBand4Spec2 = -1;		

	Variable/G SPE_PeakPos3 = -1;
	Variable/G SPE_PeakFixed3 = -1;
	Variable/G SPE_MixRatio3 = -1;
	Variable/G SPE_Fingerprint3 = -1;
	String/G SPE_HitFile3 = "na";
	Variable/G SPE_HitFile3_Found = -1;
	Variable/G SPE_HitFile3_Loaded = -1;
	Variable/G SPE_FreqBand4Spec3 = -1;	

	Variable/G SPE_PeakPos4 = -1;
	Variable/G SPE_PeakFixed4 = -1;
	Variable/G SPE_MixRatio4 = -1;
	Variable/G SPE_Fingerprint4 = -1;
	String/G SPE_HitFile4 =  "na";
	Variable/G SPE_HitFile4_Found = -1;
	Variable/G SPE_HitFile4_Loaded = -1;
	Variable/G SPE_FreqBand4Spec4 = -1;	

	Variable/G SPE_PeakPos5 = -1;
	Variable/G SPE_PeakFixed5 = -1;
	Variable/G SPE_MixRatio5 = -1;
	Variable/G SPE_Fingerprint5 = -1;
	String/G SPE_HitFile5 = "na";
	Variable/G SPE_HitFile5_Found = -1;
	Variable/G SPE_HitFile5_Loaded = -1;
	Variable/G SPE_FreqBand4Spec5 = -1;	

	Variable/G SPE_PeakPos6 = -1;
	Variable/G SPE_PeakFixed6 = -1;
	Variable/G SPE_MixRatio6 = -1;
	Variable/G SPE_Fingerprint6 = -1;
	String/G SPE_HitFile6 = "na";
	Variable/G SPE_HitFile6_Found = -1;
	Variable/G SPE_HitFile6_Loaded = -1;
	Variable/G SPE_FreqBand4Spec6 = -1;
		
	Variable/G SPE_PeakPos7 = -1;
	Variable/G SPE_PeakFixed7 = -1;
	Variable/G SPE_MixRatio7 = -1;
	Variable/G SPE_Fingerprint7 = -1;
	String/G SPE_HitFile7 = "na";
	Variable/G SPE_HitFile7_Found = -1;
	Variable/G SPE_HitFile7_Loaded = -1;
	Variable/G SPE_FreqBand4Spec7 = -1;	
	
	Variable/G SPE_PeakPos8 = -1;
	Variable/G SPE_PeakFixed8 = -1;
	Variable/G SPE_MixRatio8 = -1;
	Variable/G SPE_Fingerprint8 = -1;
	String/G SPE_HitFile8= "na";
	Variable/G SPE_HitFile8_Found = -1;
	Variable/G SPE_HitFile8_Loaded = -1;
	Variable/G SPE_FreqBand4Spec8 = -1;					
	
	Variable/G SPE_PeakPos9 = -1;
	Variable/G SPE_PeakFixed9 = -1;
	Variable/G SPE_MixRatio9 = -1;
	Variable/G SPE_Fingerprint9 = -1;
	String/G SPE_HitFile9= "na";
	Variable/G SPE_HitFile9_Found = -1;
	Variable/G SPE_HitFile9_Loaded = -1;
	Variable/G SPE_FreqBand4Spec9 = -1;	
	Variable/G SPE_PeakPos10 = -1;
	Variable/G SPE_PeakFixed10 = -1;
	Variable/G SPE_MixRatio10 = -1;
	Variable/G SPE_Fingerprint10 = -1;
	String/G SPE_HitFile10= "na";
	Variable/G SPE_HitFile10_Found = -1;
	Variable/G SPE_HitFile10_Loaded = -1;
	Variable/G SPE_FreqBand4Spec10 = -1;	
	Variable/G SPE_PeakPos11 = -1;
	Variable/G SPE_PeakFixed11 = -1;
	Variable/G SPE_MixRatio11 = -1;
	Variable/G SPE_Fingerprint11 = -1;
	String/G SPE_HitFile11= "na";
	Variable/G SPE_HitFile11_Found = -1;
	Variable/G SPE_HitFile11_Loaded = -1;
	Variable/G SPE_FreqBand4Spec11 = -1;	
	Variable/G SPE_PeakPos12 = -1;
	Variable/G SPE_PeakFixed12 = -1;
	Variable/G SPE_MixRatio12 = -1;
	Variable/G SPE_Fingerprint12 = -1;
	String/G SPE_HitFile12= "na";
	Variable/G SPE_HitFile12_Found = -1;
	Variable/G SPE_HitFile12_Loaded = -1;
	Variable/G SPE_FreqBand4Spec12 = -1;	
	Variable/G SPE_PeakPos13 = -1;
	Variable/G SPE_PeakFixed13 = -1;
	Variable/G SPE_MixRatio13 = -1;
	Variable/G SPE_Fingerprint13 = -1;
	String/G SPE_HitFile13= "na";
	Variable/G SPE_HitFile13_Found = -1;
	Variable/G SPE_HitFile13_Loaded = -1;
	Variable/G SPE_FreqBand4Spec13 = -1;	
	Variable/G SPE_PeakPos14 = -1;
	Variable/G SPE_PeakFixed14 = -1;
	Variable/G SPE_MixRatio14 = -1;
	Variable/G SPE_Fingerprint14 = -1;
	String/G SPE_HitFile14= "na";
	Variable/G SPE_HitFile14_Found = -1;
	Variable/G SPE_HitFile14_Loaded = -1;
	Variable/G SPE_FreqBand4Spec14 = -1;	
	Variable/G SPE_PeakPos15 = -1;
	Variable/G SPE_PeakFixed15 = -1;
	Variable/G SPE_MixRatio15 = -1;
	Variable/G SPE_Fingerprint15 = -1;
	String/G SPE_HitFile15= "na";
	Variable/G SPE_HitFile15_Found = -1;
	Variable/G SPE_HitFile15_Loaded = -1;
	Variable/G SPE_FreqBand4Spec15 = -1;	
	Variable/G SPE_PeakPos16 = -1;
	Variable/G SPE_PeakFixed16 = -1;
	Variable/G SPE_MixRatio16 = -1;
	Variable/G SPE_Fingerprint16 = -1;
	String/G SPE_HitFile16= "na";
	Variable/G SPE_HitFile16_Found = -1;
	Variable/G SPE_HitFile16_Loaded = -1;
	Variable/G SPE_FreqBand4Spec16 = -1;	
	Variable/G SPE_timestamp = -1;
	String/G SPE_time_date = "na";
	Variable/G SPE_ContinuousRefLok = -1;
		
	//
	SetDataFolder $saveFolder;
	
	NVAR spe2init = root:LoadSPE_II:spe2init;
	NVAR working_with_zip = root:LoadSPE_II:working_with_zip;
	spe2init = 0;
	
	working_with_zip = 0;
	///////////////////////////////	
	NVAR  SPE_version = root:LoadSPE_II:SPE_version
	NVAR  SPE_FieldNumber = root:LoadSPE_II:SPE_FieldNumber
	
	NVAR  SPE_Total_data_points = root:LoadSPE_II:SPE_Total_data_points
	NVAR  SPE_SWP1_points = root:LoadSPE_II:SPE_SWP1_points
	NVAR  SPE_SWP2_points = root:LoadSPE_II:SPE_SWP2_points
	NVAR  SPE_SWP3_points = root:LoadSPE_II:SPE_SWP3_points
	NVAR  SPE_SWP4_points = root:LoadSPE_II:SPE_SWP4_points

	NVAR  SPE_FreqResolAtPrimaryF_sw1 = root:LoadSPE_II:SPE_FreqResolAtPrimaryF_sw1
	NVAR  SPE_FreqResolAtPrimaryF_sw2 = root:LoadSPE_II:SPE_FreqResolAtPrimaryF_sw2
	NVAR  SPE_FreqResolAtPrimaryF_sw3 = root:LoadSPE_II:SPE_FreqResolAtPrimaryF_sw3
	NVAR  SPE_FreqResolAtPrimaryF_sw4 = root:LoadSPE_II:SPE_FreqResolAtPrimaryF_sw4	

	NVAR  SPE_Channels_in_Off = root:LoadSPE_II:SPE_Channels_in_Off
	
	NVAR  SPE_CellResponse = root:LoadSPE_II:SPE_CellResponse
	NVAR  SPE_CellPressure = root:LoadSPE_II:SPE_CellPressure
	NVAR  SPE_CellTemperature = root:LoadSPE_II:SPE_CellTemperature
	NVAR  SPE_PathLength = root:LoadSPE_II:SPE_PathLength
	NVAR  SPE_MenuPower = root:LoadSPE_II:SPE_MenuPower
	
	NVAR  SPE_Linewidth1 = root:LoadSPE_II:SPE_Linewidth1
	NVAR  SPE_Linewidth2 = root:LoadSPE_II:SPE_Linewidth2
	NVAR  SPE_Linewidth3 = root:LoadSPE_II:SPE_Linewidth3
	NVAR  SPE_Linewidth4 = root:LoadSPE_II:SPE_Linewidth4
	NVAR  SPE_LaserPower_1 = root:LoadSPE_II:SPE_LaserPower_1
	NVAR  SPE_LaserPower_2 = root:LoadSPE_II:SPE_LaserPower_2
	NVAR  SPE_LaserPower_3 = root:LoadSPE_II:SPE_LaserPower_3
	NVAR  SPE_LaserPower_4 = root:LoadSPE_II:SPE_LaserPower_4	
	NVAR  SPE_Polynomial = root:LoadSPE_II:SPE_Polynomial
	

	NVAR  SPE_PeakPos1 = root:LoadSPE_II:SPE_PeakPos1
	NVAR  SPE_PeakFixed1 = root:LoadSPE_II:SPE_PeakFixed1
	NVAR  SPE_MixRatio1 = root:LoadSPE_II:SPE_MixRatio1
	NVAR  SPE_Fingerprint1 = root:LoadSPE_II:SPE_Fingerprint1
	SVAR  SPE_HitFile1 = root:LoadSPE_II:SPE_HitFile1
	NVAR  SPE_HitFile1_Found = root:LoadSPE_II:SPE_HitFile1_Found
	NVAR  SPE_HitFile1_Loaded = root:LoadSPE_II:SPE_HitFile1_Loaded
	NVAR  SPE_FreqBand4Spec1 = root:LoadSPE_II:SPE_FreqBand4Spec1
	
	NVAR  SPE_PeakPos2 = root:LoadSPE_II:SPE_PeakPos2;	NVAR  SPE_PeakFixed2 = root:LoadSPE_II:SPE_PeakFixed2; NVAR  SPE_MixRatio2 = root:LoadSPE_II:SPE_MixRatio2; 
	NVAR  SPE_Fingerprint2 = root:LoadSPE_II:SPE_Fingerprint2;	SVAR  SPE_HitFile2 = root:LoadSPE_II:SPE_HitFile2; NVAR  SPE_HitFile2_Found = root:LoadSPE_II:SPE_HitFile2_Found; NVAR  SPE_HitFile2_Loaded = root:LoadSPE_II:SPE_HitFile2_Loaded; NVAR  SPE_FreqBand4Spec2 = root:LoadSPE_II:SPE_FreqBand4Spec2
		
	NVAR  SPE_PeakPos3 = root:LoadSPE_II:SPE_PeakPos3;	NVAR  SPE_PeakFixed3 = root:LoadSPE_II:SPE_PeakFixed3; NVAR  SPE_MixRatio3 = root:LoadSPE_II:SPE_MixRatio3; 
	NVAR  SPE_Fingerprint3 = root:LoadSPE_II:SPE_Fingerprint3;	SVAR  SPE_HitFile3 = root:LoadSPE_II:SPE_HitFile3; NVAR  SPE_HitFile3_Found = root:LoadSPE_II:SPE_HitFile3_Found; NVAR  SPE_HitFile3_Loaded = root:LoadSPE_II:SPE_HitFile3_Loaded; NVAR  SPE_FreqBand4Spec3 = root:LoadSPE_II:SPE_FreqBand4Spec3

	NVAR  SPE_PeakPos4 = root:LoadSPE_II:SPE_PeakPos4;	NVAR  SPE_PeakFixed4 = root:LoadSPE_II:SPE_PeakFixed4; NVAR  SPE_MixRatio4 = root:LoadSPE_II:SPE_MixRatio4; 
	NVAR  SPE_Fingerprint4 = root:LoadSPE_II:SPE_Fingerprint4;	SVAR  SPE_HitFile4 = root:LoadSPE_II:SPE_HitFile4; NVAR  SPE_HitFile4_Found = root:LoadSPE_II:SPE_HitFile4_Found; NVAR  SPE_HitFile4_Loaded = root:LoadSPE_II:SPE_HitFile4_Loaded; NVAR  SPE_FreqBand4Spec4 = root:LoadSPE_II:SPE_FreqBand4Spec4

	NVAR  SPE_PeakPos5 = root:LoadSPE_II:SPE_PeakPos5;	NVAR  SPE_PeakFixed5 = root:LoadSPE_II:SPE_PeakFixed5; NVAR  SPE_MixRatio5 = root:LoadSPE_II:SPE_MixRatio5; 
	NVAR  SPE_Fingerprint5 = root:LoadSPE_II:SPE_Fingerprint5;	SVAR  SPE_HitFile5 = root:LoadSPE_II:SPE_HitFile5; NVAR  SPE_HitFile5_Found = root:LoadSPE_II:SPE_HitFile5_Found; NVAR  SPE_HitFile5_Loaded = root:LoadSPE_II:SPE_HitFile5_Loaded; NVAR  SPE_FreqBand4Spec5 = root:LoadSPE_II:SPE_FreqBand4Spec5

	NVAR  SPE_PeakPos6 = root:LoadSPE_II:SPE_PeakPos6;	NVAR  SPE_PeakFixed6 = root:LoadSPE_II:SPE_PeakFixed6; NVAR  SPE_MixRatio6 = root:LoadSPE_II:SPE_MixRatio6; 
	NVAR  SPE_Fingerprint6 = root:LoadSPE_II:SPE_Fingerprint6;	SVAR  SPE_HitFile6 = root:LoadSPE_II:SPE_HitFile6; NVAR  SPE_HitFile6_Found = root:LoadSPE_II:SPE_HitFile6_Found; NVAR  SPE_HitFile6_Loaded = root:LoadSPE_II:SPE_HitFile6_Loaded; NVAR  SPE_FreqBand4Spec6 = root:LoadSPE_II:SPE_FreqBand4Spec6

	NVAR  SPE_PeakPos7 = root:LoadSPE_II:SPE_PeakPos7;	NVAR  SPE_PeakFixed7 = root:LoadSPE_II:SPE_PeakFixed7; NVAR  SPE_MixRatio7 = root:LoadSPE_II:SPE_MixRatio7; 
	NVAR  SPE_Fingerprint7 = root:LoadSPE_II:SPE_Fingerprint7;	SVAR  SPE_HitFile7 = root:LoadSPE_II:SPE_HitFile7; NVAR  SPE_HitFile7_Found = root:LoadSPE_II:SPE_HitFile7_Found; NVAR  SPE_HitFile7_Loaded = root:LoadSPE_II:SPE_HitFile7_Loaded; NVAR  SPE_FreqBand4Spec7 = root:LoadSPE_II:SPE_FreqBand4Spec7

	NVAR  SPE_PeakPos8 = root:LoadSPE_II:SPE_PeakPos8;	NVAR  SPE_PeakFixed8 = root:LoadSPE_II:SPE_PeakFixed8; NVAR  SPE_MixRatio8 = root:LoadSPE_II:SPE_MixRatio8; 
	NVAR  SPE_Fingerprint8 = root:LoadSPE_II:SPE_Fingerprint8;	SVAR  SPE_HitFile8 = root:LoadSPE_II:SPE_HitFile8; NVAR  SPE_HitFile8_Found = root:LoadSPE_II:SPE_HitFile8_Found; NVAR  SPE_HitFile8_Loaded = root:LoadSPE_II:SPE_HitFile8_Loaded; NVAR  SPE_FreqBand4Spec8 = root:LoadSPE_II:SPE_FreqBand4Spec8

	NVAR  SPE_timestamp = root:LoadSPE_II:SPE_timestamp;
	SVAR  SPE_time_date = root:LoadSPE_II:SPE_time_date;
	NVAR  SPE_ContinuousRefLok = root:LoadSPE_II:SPE_ContinuousRefLok;

	Wave/D FrameColumn_1 = root:LoadSPE_II:FrameColumn_1
	Wave/D FrameColumn_2 = root:LoadSPE_II:FrameColumn_2
	Wave/D FrameColumn_3 = root:LoadSPE_II:FrameColumn_3
	Wave/D FrameColumn_4 = root:LoadSPE_II:FrameColumn_4
	Wave/D FrameColumn_5 = root:LoadSPE_II:FrameColumn_5
	Wave/D FrameColumn_6 = root:LoadSPE_II:FrameColumn_6

	Wave/D wb1_igr_cur = root:LoadSPE_II:wb1_igr_cur
	Wave/D wb1_wintel_cur = root:LoadSPE_II:wb1_wintel_cur
	Wave/D wb1_trans_fit = root:LoadSPE_II:wb1_trans_fit
	Wave/D wb1_trans_spectrum = root:LoadSPE_II:wb1_trans_spectrum
	Wave/D wb1_wintel_fit = root:LoadSPE_II:wb1_wintel_fit
	Wave/D wb1_wintel_base = root:LoadSPE_II:wb1_wintel_base
	Wave/D wb1_spectrum = root:LoadSPE_II:wb1_spectrum
	Wave/D wb1_frequency = root:LoadSPE_II:wb1_frequency
	Wave/T params_tw = root:LoadSPE_II:params_tw	
	Wave/T header_tw = root:LoadSPE_II:header_tw	

	Wave/D wb2_igr_cur = root:LoadSPE_II:wb2_igr_cur;	Wave/D wb2_wintel_cur = root:LoadSPE_II:wb2_wintel_cur; 	Wave/D wb2_trans_fit = root:LoadSPE_II:wb2_trans_fit;	Wave/D wb2_trans_spectrum = root:LoadSPE_II:wb2_trans_spectrum
	Wave/D wb2_wintel_fit = root:LoadSPE_II:wb2_wintel_fit;	Wave/D wb2_wintel_base = root:LoadSPE_II:wb2_wintel_base
	Wave/D wb2_spectrum = root:LoadSPE_II:wb2_spectrum;	Wave/D wb2_frequency = root:LoadSPE_II:wb2_frequency;

	Wave/D wb3_igr_cur = root:LoadSPE_II:wb3_igr_cur;	Wave/D wb3_wintel_cur = root:LoadSPE_II:wb3_wintel_cur; 	Wave/D wb3_trans_fit = root:LoadSPE_II:wb3_trans_fit;	Wave/D wb3_trans_spectrum = root:LoadSPE_II:wb3_trans_spectrum
	Wave/D wb3_wintel_fit = root:LoadSPE_II:wb3_wintel_fit;	Wave/D wb3_wintel_base = root:LoadSPE_II:wb3_wintel_base
	Wave/D wb3_spectrum = root:LoadSPE_II:wb3_spectrum;	Wave/D wb3_frequency = root:LoadSPE_II:wb3_frequency;

	Wave/D wb4_igr_cur = root:LoadSPE_II:wb4_igr_cur;	Wave/D wb4_wintel_cur = root:LoadSPE_II:wb4_wintel_cur; 	Wave/D wb4_trans_fit = root:LoadSPE_II:wb4_trans_fit;	Wave/D wb4_trans_spectrum = root:LoadSPE_II:wb4_trans_spectrum
	Wave/D wb4_wintel_fit = root:LoadSPE_II:wb4_wintel_fit;	Wave/D wb4_wintel_base = root:LoadSPE_II:wb4_wintel_base
	Wave/D wb4_spectrum = root:LoadSPE_II:wb4_spectrum;	Wave/D wb4_frequency = root:LoadSPE_II:wb4_frequency;

	Wave/D spec_laser_off = root:LoadSPE_II:spec_laser_off
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////// User Interface Code for SPE2 follows /////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Constant force_redraw_zspe2 = 0

Function zSPE2_DrawPanel()
	
	
	NVAR/Z Roll_SpeciesNumber = root:LoadSPE_UI:Roll_SpeciesNumber
	
	if( (NVAR_Exists( Roll_SpeciesNumber ) != 1) | (force_redraw_zspe2) )
		zSPE2_InitUIVars()
	endif
	
	NVAR xBox_IncludeZip = root:LoadSPE_UI:xBox_IncludeZip
	NVAR xBox_IncludeSPE = root:LoadSPE_UI:xBox_IncludeSPE
	NVAR xBox_BlockBK = root:LoadSPE_UI:xBox_BlockBK
	NVAR xBox_BlockRef = root:LoadSPE_UI:xBox_BlockRef
	NVAR xBox_BlockNorm = root:LoadSPE_UI:xBox_BlockNorm
	NVAR Roll_SpeciesNumber = root:LoadSPE_UI:Roll_SpeciesNumber
	NVAR xBox_DoUpdate = root:LoadSPE_UI:xBox_DoUpdate

	NVAR Sweep_ChiFilter = root:LoadSPE_UI:Sweep_ChiFilter
	NVAR Value_ChiFilter = root:LoadSPE_UI:Value_ChiFilter
	NVAR xBox_DoUEX = root:LoadSPE_UI:xBox_DoUEX
	NVAR xBox_DoRES = root:LoadSPE_UI:xBox_DoRES
	NVAR xBox_ChiFilter = root:LoadSPE_UI:xBox_ChiFilter
	SVAR AverageOptionsStr = root:LoadSPE_UI:AverageOptionsStr
	
	NVAR Mix_a = root:LoadSPE_UI:Mix_a
	NVAR Mix_b = root:LoadSPE_UI:Mix_b
	NVAR Pos_a = root:LoadSPE_UI:Pos_a
	NVAR Pos_b = root:LoadSPE_UI:Pos_b
	NVAR Fingerprint_a = root:LoadSPE_UI:Fingerprint_a
	NVAR Fingerprint_b = root:LoadSPE_UI:Fingerprint_b

	SVAR Path2Files = root:LoadSPE_UI:Path2Files
	SVAR HitFile_a = root:LoadSPE_UI:HitFile_a
	SVAR HitFile_b = root:LoadSPE_UI:HitFile_b
	SVAR TimeStampTime = root:LoadSPE_UI:TimeStampTime
	SVAR FileTimeTime = root:LoadSPE_UI:FileTimeTime
	SVAR BrowseMSG = root:LoadSPE_UI:BrowseMSG
	SVAR LoadMSG = root:LoadSPE_UI:LoadMSG
	SVAR PlayListMSG = root:LoadSPE_UI:PlayListMSG

	Wave/D disp_time = root:LoadSPE_UI:disp_time
	Wave/T disp_fileList = root:LoadSPE_UI:disp_fileList
	Wave/T pack_fileList = root:LoadSPE_UI:pack_fileList
	Wave/T path_fileList = root:LoadSPE_UI:path_fileList
	Wave disp_SelWave = root:LoadSPE_UI:disp_SelWave
	
	String TabList = ks_zSPE2TabList, this_tab, test_funcName
	Variable idex, count = ItemsInList( TabList )
	
	Variable left = 5, right = 505, top = 5, bottom = 455
	Variable tab_left = left, tab_right = right, tab_top = top, tab_bottom = bottom
	Variable tab_wid = tab_right - tab_left - 15
	Variable tab_height = tab_bottom - tab_top - 50
	
	PauseUpdate; Silent 1;
	MakeOrSetPanel( left, top, right, bottom, ks_zSPE2PanelName )
	
	TabControl mainTab, pos={tab_left, tab_top}
	TabControl mainTab, size={tab_wid, tab_height}, proc=zSPE2_AutoTabProc
	do
		this_tab = StringFromList( idex, TabList )	
		TabControl mainTab, tabLabel(idex)=StringFromList( idex, TabList )
		idex += 1
	while( idex < count )

	TabControl mainTab, value=0

	Variable msg_row = tab_top + 35, msg_col = tab_left + 4, msg_height = 25, msg_wid = tab_wid - 9
	
	
	Variable col1 = left + 4, but_wid = 50
	Variable row1 = tab_top + 35
	Variable ctrl_height = 21
	
	Variable pcol2 = col1 + but_wid + 3
	Variable col2 = right -15 - but_wid - 5
	Variable row2 = row1 + ctrl_height + 5
	Variable row3 = row2 + ctrl_height + 5
	Variable row4 = row3 + ctrl_height + 5
	Variable pathwid = msg_wid - but_wid * 2 - 5
	Variable RingMsgWid = msg_wid - but_wid
	Variable bot_row = bottom - ctrl_height - 5
	Variable big_but = 100
	
	Variable space = 5
	Variable top_row = 3, trc_1 = 5, smbutwid = 60, popDirwid = 220, butwid = 105
	Variable trc_2 = trc_1 + smbutwid + space
	Variable trc_3 = trc_2 + popDirWid + space
	
	Variable row_lb = row3 + ctrl_height + space - 5
	Variable height_lb = 240
	Variable width_lb = 180
	Variable col_1 = trc_1 + 5
	
	Variable col_ck_1 = col_1 + width_lb + 2 * space
	Variable ck_small_wid = 65
	Variable col_ck_2 = col_ck_1 + ck_small_wid + space
	Variable col_ck_3 = col_ck_2 + ck_small_wid + space
	Variable ck_long_wid = 80
	Variable ck_twid = 4 * space + 2 * ck_small_wid + ck_long_wid
	Variable ck_hei = 4 * ctrl_height + space
	Variable row_ck_1 = row_lb, row_ck_2 = row_ck_1 + ctrl_height, row_ck_3 = row_ck_1 + 2 * ctrl_height
	Variable row_ck_4 = row_ck_1 + 3 * ctrl_height, row_ck_5 = row_ck_1 + 4*ctrl_height, row_ck_6 = row_ck_1 + 5 * ctrl_height
	Variable row_ck_7 = row_ck_1 + 6 * ctrl_height, row_ck_8 = row_ck_1 + 7*ctrl_height + 2 * space
	Variable row_ck_9 = row_ck_8 + 1 * ctrl_height + 2
	
	Variable row_ck_10 = row_ck_9 + ctrl_height + 2
	
	Variable row_msg = bottom - 2 * ctrl_height, wid_msg = right - left - 2 * space - col_1
	Variable row_cmd_but = (bottom - top ) - ctrl_height - space
	Variable col_2 = col_1 + space + butwid
	Variable kspe_size = 12
	
	Button ao_SetPath_but  title = "Path", pos={col1, row1}, size={ but_wid, ctrl_height}
	Button ao_SetPath_but proc=zSPE2_MainButtonProc

	Button ao_ZipInZipOut title="Expand Zip", pos = {col1 + 2, row_lb - ctrl_height - 2}, size={width_lb - 4, ctrl_height}
	Button ao_ZipInZipOut proc=zSPE2_MainButtonProc, disable=2

		
	//	Button ao_Chrono_but  title = "^chronological^", pos={col1+2, row_lb + height_lb + 4}, size={ width_lb - 4, ctrl_height}
	//	Button ao_Chrono_but proc=zSPE2_MainButtonProc, disable=2
	
	Button ao_Graph_but  title = "Graph", pos={col2, row2}, size={ but_wid, ctrl_height}
	Button ao_Graph_but proc=zSPE2_MainButtonProc, disable=2		
	
	SetVariable ao_Path title = ">", value=root:LoadSPE_UI:Path2Files, fsize=12
	SetVariable ao_Path pos={pcol2, row1}, size={ Pathwid, msg_height }, proc=zSPE2_CheckPath
	
	SetVariable ao_BrowseMessage title = "~", value=root:LoadSPE_UI:BrowseMSG, fsize=12
	SetVariable ao_BrowseMessage pos={col1, row2}, size={ RingMsgWid, msg_height }	, noedit=1	
	
	Button ao_Close_but title = "Close", pos = { col1, bot_row }, size = {big_but, ctrl_height }
	Button ao_Close_but proc=zSPE2_MainButtonProc

	Button ao_Hide_but title = "Hide", pos = { col1 + 2 * 5 + big_but, bot_row }, size = {big_but, ctrl_height }
	Button ao_Hide_but proc=zSPE2_MainButtonProc
		
	ListBox ao_STR_LB1,pos={col_1,row_lb},size={width_lb,height_lb}, fsize=10, help={"Selection of one or more spectra allows browsing [when enabled] and loading to igor"}
	ListBox ao_STR_LB1, listWave=disp_FileList,selWave=disp_SelWave,mode= 4, proc=LoadSPE_LBProc

	SetVariable ao_msg_sv, title = " ", pos={col_1, row_msg}, value=root:LoadSPE_UI:LoadMSG, size={wid_msg, ctrl_height}, fsize=kspe_size, help={"LoadSPE maintained by herndon@aerodyne.com"}

	NVAR xBox_IncludeZip = root:LoadSPE_UI:xBox_IncludeZip
	NVAR xBox_IncludeSPE = root:LoadSPE_UI:xBox_IncludeSPE
	NVAR xBox_BlockBK = root:LoadSPE_UI:xBox_BlockBK
	NVAR xBox_BlockRef = root:LoadSPE_UI:xBox_BlockRef	
	
	Variable inc_row = row_lb
	Variable inc_col = col1 + width_lb + 2
	Variable inc_wid = width_lb / 4 - 2
	Variable spk = 2
	
	CheckBox ao_zip_ck, title = "+zip", pos={inc_col, inc_row + 0 * (spk + ctrl_height)}, size={inc_wid, ctrl_height}
	CheckBox ao_zip_ck variable=root:LoadSPE_UI:xBox_IncludeZip, proc=zSPE2_FileCheckBoxProc

	CheckBox ao_spe_ck, title = "+spe", pos={inc_col, inc_row + 1 * (spk + ctrl_height)}, size={inc_wid, ctrl_height}
	CheckBox ao_spe_ck variable=root:LoadSPE_UI:xBox_IncludeSPE, proc=zSPE2_FileCheckBoxProc
	
	CheckBox ao_ref_ck, title = "-ref", pos={inc_col, inc_row + 2 * (spk + ctrl_height)}, size={inc_wid, ctrl_height}
	CheckBox ao_ref_ck variable=root:LoadSPE_UI:xBox_BlockRef, proc=zSPE2_FileCheckBoxProc
	
	CheckBox ao_bk_ck, title = "-bkg", pos={inc_col, inc_row + 3 * (spk + ctrl_height)}, size={inc_wid, ctrl_height}
	CheckBox ao_bk_ck variable=root:LoadSPE_UI:xBox_BlockBK, proc=zSPE2_FileCheckBoxProc

	CheckBox ao_pn_ck, title = "-pn", pos={inc_col, inc_row + 4 * (spk + ctrl_height)}, size={inc_wid, ctrl_height}
	CheckBox ao_pn_ck variable=root:LoadSPE_UI:xBox_BlockPn, proc=zSPE2_FileCheckBoxProc

	CheckBox ao_rw_ck, title = "-raw", pos={inc_col, inc_row + 5 * (spk + ctrl_height)}, size={inc_wid, ctrl_height}
	CheckBox ao_rw_ck variable=root:LoadSPE_UI:xBox_BlockRaw, proc=zSPE2_FileCheckBoxProc
	
	CheckBox ao_cal_ck, title = "-cal", pos={inc_col, inc_row + 6 * (spk + ctrl_height)}, size={inc_wid, ctrl_height}
	CheckBox ao_cal_ck variable=root:LoadSPE_UI:xBox_BlockCal, proc=zSPE2_FileCheckBoxProc
	
	CheckBox ao_wild_ck, title = "-wild", pos={inc_col, inc_row + 7 * (spk + ctrl_height)}, size={inc_wid, ctrl_height}
	CheckBox ao_wild_ck variable=root:LoadSPE_UI:xBox_BlockWild, proc=zSPE2_FileCheckBoxProc
	
	CheckBox ao_norm_ck, title = "-n.spe", pos={inc_col, inc_row + 8 * (spk + ctrl_height)}, size={inc_wid, ctrl_height}
	CheckBox ao_norm_ck variable=root:LoadSPE_UI:xBox_BlockNorm, proc=zSPE2_FileCheckBoxProc
	
	CheckBox ao_zip_ck, help={"When enabled, this allows the filetype .zip into the file listing"}
	CheckBox ao_spe_ck, help={"When enabled, this allows the filetype .spe into the file listing"}
	CheckBox ao_ref_ck, help={"When enabled, this blocks _REF spe files from the file listing"}
	CheckBox ao_bk_ck, help={"When enabled, this blocks _BK spe files from the file listing"}
	CheckBox ao_cal_ck, help={"When enabled, this blocks _CAL spe files from the file listing"}
	CheckBox ao_pn_ck, help={"When enabled, this blocks _PN spe files from the file listing"}
	CheckBox ao_wild_ck, help={"When enabled, this blocks files from the file listing, which contain a match to the String Constant defined in the LoadSPE2.ipf See or Search for 'ks_WildWintelBlockStr'"}
	CheckBox ao_norm_ck, help={"When enabled, this blocks normal spe files from the file listing'"}
	
		
	Variable incol = inc_col + inc_wid + 8
	Variable inrow1 = inc_row - ctrl_height
	Variable inrow2 = inrow1 + ctrl_height + 2 + 4
	Variable inrow3 = inrow2 + ctrl_height + 2
	Variable inrow4 = inrow3 + ctrl_height + 2
	Variable inrow5 = inrow4 + ctrl_height + 2
	
	Variable inwid = 110
	Variable incol2 = inwid + incol + 8
	
	NVAR Roll_SpeciesNumber = root:LoadSPE_UI:Roll_SpeciesNumber
	String sn_title = zSPE2_GetSNButtonTitle( Roll_SpeciesNumber)
	Button br_increSN_but, title = sn_title, pos = {incol + 35, inrow1}, size={2*inwid - 30, ctrl_height}, proc=zSPE2_MainButtonProc
	
	Button br_decreSN_but, title = "<<", pos = {incol, inrow1}, size={30, ctrl_height}, proc=zSPE2_MainButtonProc
	
	SetVariable br_hita_sv, title = "!", pos={incol, inrow2}, size={inwid, ctrl_height}, noedit=1, fsize=12, variable=root:LoadSPE_UI:HitFile_JFa
	SetVariable br_finga_sv, title = "cm-1", pos={incol, inrow3}, size={inwid, ctrl_height}, noedit=1, fsize=12, variable=root:LoadSPE_UI:Fingerprint_a, limits={-inf, inf, 0}
	SetVariable br_posa_sv, title = "chan*", pos={incol, inrow4}, size={inwid, ctrl_height}, noedit=1, fsize=12, variable=root:LoadSPE_UI:Pos_a, limits={-inf, inf, 0}
	SetVariable br_mixa_sv, title = "ppb", pos={incol, inrow5}, size={inwid, ctrl_height}, noedit=1, fsize=12, variable=root:LoadSPE_UI:Mix_a, limits={-inf, inf, 0}

	
	SetVariable br_hitb_sv, title = "!", pos={incol2, inrow2}, size={inwid, ctrl_height}, noedit=1, fsize=12, variable=root:LoadSPE_UI:HitFile_JFb
	SetVariable br_fingb_sv, title = "cm-1", pos={incol2, inrow3}, size={inwid, ctrl_height}, noedit=1, fsize=12, variable=root:LoadSPE_UI:Fingerprint_b, limits={-inf, inf, 0}
	SetVariable br_posb_sv, title = "*", pos={incol2, inrow4}, size={inwid, ctrl_height}, noedit=1, fsize=12, variable=root:LoadSPE_UI:Pos_b, limits={-inf, inf, 0}
	SetVariable br_mixb_sv, title = "ppb", pos={incol2, inrow5}, size={inwid, ctrl_height}, noedit=1, fsize=12, variable=root:LoadSPE_UI:Mix_b, limits={-inf, inf, 0}	


	Variable gr_but_row = inrow5 + ctrl_height * 2
	Variable gr_but_col = incol
	Variable gr_but_wid = inwid
	
	if( k_interp_WB_as_Fit_not_Laser )
		
		Button br_graph1_but, title = "Fit 1 Graph", pos={gr_but_col, gr_but_row}, size={gr_but_wid, ctrl_height}, proc=zSPE2_MainButtonProc
		Button br_graph2_but, title = "Fit 2 Graph", pos={gr_but_col + space + gr_but_wid, gr_but_row}, size={gr_but_wid, ctrl_height}, proc=zSPE2_MainButtonProc
		Button br_graph3_but, title = "Fit 3 Graph", pos={gr_but_col, gr_but_row + ctrl_height+2}, size={gr_but_wid, ctrl_height}, proc=zSPE2_MainButtonProc
		Button br_graph4_but, title = "Fit 4 Graph", pos={gr_but_col + space + gr_but_wid, gr_but_row + ctrl_height+2}, size={gr_but_wid, ctrl_height}, proc=zSPE2_MainButtonProc
	
	else
		
		Button br_graph1_but, title = "Laser 1 Graph", pos={gr_but_col, gr_but_row}, size={gr_but_wid, ctrl_height}, proc=zSPE2_MainButtonProc
		Button br_graph2_but, title = "Laser 2 Graph", pos={gr_but_col + space + gr_but_wid, gr_but_row}, size={gr_but_wid, ctrl_height}, proc=zSPE2_MainButtonProc
		Button br_graph3_but, title = "Laser 3 Graph", pos={gr_but_col, gr_but_row + ctrl_height+2}, size={gr_but_wid, ctrl_height}, proc=zSPE2_MainButtonProc
		Button br_graph4_but, title = "Laser 4 Graph", pos={gr_but_col + space + gr_but_wid, gr_but_row + ctrl_height+2}, size={gr_but_wid, ctrl_height}, proc=zSPE2_MainButtonProc
	endif
	
	Button lo_LoOrCat_but, title = "Load File \ror\rConcatente\rSelection", pos={gr_but_col, gr_but_row}, size={gr_but_wid, 4* ctrl_height}, proc=zSPE2_MainButtonProc, help={"load .spb into root:Spectrum"}
	//	Button lo_Prep_but, title = "Prep For Analysis", pos={gr_but_col + space + gr_but_wid, gr_but_row}, size={gr_but_wid, ctrl_height}, proc=zSPE2_MainButtonProc

	
	Variable cond_row = gr_but_row + 4 * ctrl_height
	Variable cond_col = gr_but_col
	
	SetVariable br_Pressure_sv, title = "Pressure (Torr)", pos={cond_col, cond_row}, size = {gr_but_wid * 2, ctrl_height}, noedit=1, fsize=12, variable=root:LoadSPE_UI:CellPressure, limits={-inf, inf, 0}
	SetVariable br_temperature_sv, title = "Temperature (K)", pos={cond_col, cond_row + ctrl_height}, size = {gr_but_wid * 2, ctrl_height}, noedit=1, fsize=12, variable=root:LoadSPE_UI:CellTemperature, limits={-inf, inf, 0}
	SetVariable br_Pathlen_sv, title = "PathLength (cm)", pos={cond_col, cond_row + 2 * ctrl_height}, size = {gr_but_wid * 2, ctrl_height}, noedit=1, fsize=12, variable=root:LoadSPE_UI:PathLength, limits={-inf, inf, 0}
	SetVariable br_response_sv, title = "Response (s)", pos={cond_col, cond_row+ 3 * ctrl_height}, size = {gr_but_wid * 2, ctrl_height}, noedit=1, fsize=12, variable=root:LoadSPE_UI:CellResponse, limits={-inf, inf, 0}
	
	
	NVAR Sweep_ChiFilter = root:LoadSPE_UI:Sweep_ChiFilter
	NVAR Value_ChiFilter = root:LoadSPE_UI:Value_ChiFilter
	NVAR xBox_DoUEX = root:LoadSPE_UI:xBox_DoUEX
	NVAR xBox_DoRES = root:LoadSPE_UI:xBox_DoRES
	NVAR xBox_ChiFilter = root:LoadSPE_UI:xBox_ChiFilter
	SVAR AverageOptionsStr = root:LoadSPE_UI:AverageOptionsStr
	
	CheckBox av_uex_ck, title = "Simultaneous Organized Unzip", pos={inc_col + 55, inc_row + 2 * (spk + ctrl_height)}, size={inc_wid, ctrl_height}
	CheckBox av_uex_ck variable=root:LoadSPE_UI:xBox_DoUEX, proc=zSPE2_AVCheckBoxProc

	CheckBox av_res_ck, title = "Bind Found RES to Hardwired Grid", pos={inc_col + 55, inc_row + 3 * (spk + ctrl_height)}, size={inc_wid, ctrl_height}
	CheckBox av_res_ck variable=root:LoadSPE_UI:xBox_DoRES, proc=zSPE2_AVCheckBoxProc
	
	CheckBox av_chi_ck, title = "Employ Chi2 Filter During Average", pos={inc_col + 55, inc_row + 6 * (spk + ctrl_height)}, size={inc_wid, ctrl_height}
	CheckBox av_chi_ck variable=root:LoadSPE_UI:xBox_ChiFilter, proc=zSPE2_AVCheckBoxProc

	SetVariable av_ChiSweep_sv, title = "Sweep", pos={cond_col, cond_row + (-1) * ctrl_height}, size = {gr_but_wid * 2, ctrl_height}, noedit=0, fsize=12, variable=root:LoadSPE_UI:Sweep_ChiFilter, limits={1,4, 0}, proc = zSPE_AVSetVarProc
	SetVariable av_ChiFilter_sv, title = "Threshold", pos={cond_col, cond_row + 0 *  ctrl_height}, size = {gr_but_wid * 2, ctrl_height}, noedit=0, fsize=12, variable=root:LoadSPE_UI:Value_ChiFilter, limits={0, inf, 0}, proc=zSPE_AVSetVarProc
	SetVariable av_OptsStr_sv, title = "OPTS", pos={inc_col + 55, inc_row+ 0 * ctrl_height}, size = {gr_but_wid * 2, ctrl_height}, noedit=1, fsize=9, variable=root:LoadSPE_UI:AverageOptionsStr

	Button av_AlgoA title="Avg Algo A", pos = {cond_col, cond_row + 3 * ctrl_height}, size={150, ctrl_height}
	Button av_AlgoA proc=zSPE2_MainButtonProc, disable=2, fsize=9
	
	zSPE2_AVCheckBoxProc("",0)
	zSPE2_AutoTabProc( "mainTab", 0 )
	//ModifyPanel cbRGB=(65280,65280,48896)
	
	//	Button closePanel_but, title = "Close Panel", pos = {col_1, row_cmd_but}, size={ butwid, ctrl_height }
	//	Button closePanel_but, proc=DXPanel_ButtonProc, fsize=kspe_size
	
	//	Button loadfiles_but, title = "Load Selection", pos = {col_2, row_cmd_but}, size = {butwid, ctrl_height }, proc=DXPanel_ButtonProc, fsize=kspe_size
	//	Button refresh_but, title = "Refresh FileList", pos={trc_3, top_row}, size={butwid, ctrl_height}, proc=DXPanel_ButtonProc, fsize=kspe_size
	
	//	Button pickDir_but, title = "Browse Dir", pos={trc_1, top_row}, size={smbutwid, ctrl_height}, proc=DXPanel_ButtonProc, fsize=kspe_size

	//	Button closePanel_but, help={"Closes this Panel, and the Browser Window (if open) and removes evidence of this panel from experiment"}
	//	Button loadfiles_but, help = {"Loads the selected files, consecutively and creates the selected waves for each"}
	//	Button refresh_but, help = {"Refresh FileList in the selection window, without opening a director browse box"}
	//	Button pickDir_but, help = {"Browses the current disks and allows user to chose working folder"}
	
	//	PopupMenu setpath_pop, title = " ", pos={trc_2, top_row}, size={popDirWid, ctrl_height}, proc=DXPanel_DirPopProc, fsize=kspe_size
	//	PopupMenu setpath_pop, value=DXSPE_CurrentList(), mode=1, bodywidth=popDirWid - 10, help={"Directory shown is current path to the data.  Colons are the same as Windows Slash character"}
	
	//	CheckBox trak_ck, title = "Tracking Table", pos = {col_ck_1, row_ck_1}, variable=root:dxspe:g_traktable, fsize=kspe_size, help = {"When enabled, the filenames of loaded work is matched to whatever basic name is used in the destination"}
	//	CheckBox browser_ck, title = "Browser Window", pos = {col_ck_1, row_ck_2}, variable=root:dxspe:g_browseWin, fsize=kspe_size, help={"When enabled, the most recent 3 spectra chosen via mouse click or arrow in the selection box are displayed in the other window"}
	
	//	SetVariable prefix_sv, title = "Create waves with prefix", pos={col_ck_1, row_ck_3}, value=root:dxspe:gs_prefix, size={ck_twid, ctrl_height}, fsize=kspe_size, help={"Use blank for none, or label the incoming spectra with a descriptive name here"}
	//	SetVariable destDF_sv, title = "And put them in DF", pos={col_ck_1, row_ck_8}, value=root:dxspe:gs_destDF, size={ck_twid, ctrl_height}, fsize=kspe_size, help={"Name of the destination Data Folder.  See igor help for more information on working with DataFolders"}
	
	//	GroupBox wtc_gb, title = "Waves to Create", pos={col_ck_1 - 4, row_ck_4}, size = { ck_twid+2, ck_hei }, fsize=kspe_size, help={"Enabling these options allows you to control what data is kept from the spe file"}
	
	//	CheckBox spec_ck, title = "spec", pos = {col_ck_1, row_ck_5}, variable=root:dxspe:g_spec, fsize=kspe_size, help= {"Refers to the raw signal in mV"}
	//	CheckBox fit_ck, title = "fit", pos = {col_ck_1, row_ck_6}, variable=root:dxspe:g_fit, fsize=kspe_size, help={"Refers to the fitted signal, done by TDL Wintel in mV"}
	//	CheckBox base_ck, title = "base", pos = {col_ck_1, row_ck_7}, variable=root:dxspe:g_base, fsize=kspe_size, help={"Refers to the fitted baseline, done by TDL Wintel in mV"}
	
	//	CheckBox trans_ck, title = "trans", pos = {col_ck_2, row_ck_5}, variable=root:dxspe:g_trans, fsize=kspe_size, help={"Referst to the transmission spectrum"}
	//	CheckBox fittrans_ck, title = "fit trans", pos = {col_ck_2, row_ck_6}, variable=root:dxspe:g_ftrans	, fsize=kspe_size, help={"Refers to the fit through the transmission spectrum"}
	
	//	CheckBox wavelen_ck, title = "wavelength", pos = {col_ck_3, row_ck_5}, variable=root:dxspe:g_wavelen, fsize=kspe_size, help={"When enabled, the channel numbers are converted to Wavelength"}
	//	CheckBox header_ck, title = "header", pos = {col_ck_3, row_ck_6}, variable=root:dxspe:g_header, fsize=kspe_size, help={"If checked, a seperate wave is created for each loaded spectrum, containing the names of the headers"}
	//	CheckBox param_ck, title = "params", pos = {col_ck_3, row_ck_7}, variable=root:dxspe:g_param, fsize=kspe_size, help={"When enabled, the paramters associated with that spectrum are saved"}
	

	//	PopupMenu SPEPanelGraphPop,pos={col_ck_1,row_ck_9},size={popDirWid,ctrl_height},proc=DXSPEPanel_Pop,title="Graph"
	//	PopupMenu SPEPanelGraphPop,mode=2,popvalue=" Make Transmission Graph",value= #"\"Do not make graph; Make Transmission Graph; Make Raw Signal Graph; Make Both Graphs\""
	//	CheckBox hitch_1_ck, title = "Hitch(1)", pos = {col_ck_1, row_ck_10}, variable=root:dxspe:g_hitch_1, fsize=kspe_size, help= {"When Checked DXSPE_Hitch_1 is executed for each Loaded Spectrum"}
	//	CheckBox hitch_2_ck, title = "Hitch(2)", pos = {col_ck_2, row_ck_10}, variable=root:dxspe:g_hitch_2, fsize=kspe_size, help={"When Checked DXSPE_Hitch_2 is executed for each Loaded Spectrum"}
	//	CheckBox hitch_3_ck, title = "Hitch(3)", pos = {col_ck_3, row_ck_10}, variable=root:dxspe:g_hitch_3, fsize=kspe_size, help={"When Checked DXSPE_Hitch_3 is executed for each Loaded Spectrum"}
	//	String what_does_hitch_1_do = ks_what_does_hitch_1_do
	//	CheckBox hitch_1_ck, title=what_does_hitch_1_do
	//	if( strlen( what_does_hitch_1_do ) > 6 )
	//		CheckBox hitch_1_ck, fsize=9
	//	endif
	//	if( strlen( what_does_hitch_1_do ) > 12 )
	//		CheckBox hitch_1_ck, fsize=6
	//	endif
	//	String what_does_hitch_2_do = ks_what_does_hitch_2_do
	//	CheckBox hitch_2_ck, title=what_does_hitch_2_do
	//	if( strlen( what_does_hitch_2_do ) > 6 )
	//		CheckBox hitch_2_ck, fsize=9
	//	endif
	//	if( strlen( what_does_hitch_2_do ) > 12 )
	//		CheckBox hitch_2_ck, fsize=6
	//	endif
	//	String what_does_hitch_3_do = ks_what_does_hitch_3_do
	//	CheckBox hitch_3_ck, title=what_does_hitch_3_do
	//	if( strlen( what_does_hitch_3_do ) > 6 )
	//		CheckBox hitch_3_ck, fsize=9
	//	endif
	//	if( strlen( what_does_hitch_3_do ) > 12 )
	///		CheckBox hitch_3_ck, fsize=6
	//	endif	
 	
	// Index Controls
	//		// This set draws the index buttons and checkboxes
	//		Variable in_row1 = 155, in_col1 = 12, in_ColWid = 150, in_ButWid = 125, space = 2
	//		Variable in_col2 = in_col1 + in_ColWid + space
	//		Variable in_col3 = in_col2 + in_ButWid + space
	//		
	//		Variable in_row2 = in_row1 + ctrl_height + space
	//		Variable in_row3 = in_row2 + ctrl_height + space
	//		Variable in_row4 = in_row3 + ctrl_height + space
	//	
	//	
	//	SetVariable in_IndexMessage title = "Status", value=$(ks_UAIFolder+":Index_msg"), fsize=12
	//	SetVariable in_IndexMessage pos={in_col1, in_row3}, size={ msg_wid, ctrl_height }		
	//	
	//	Button in_DoIndex title = "Do Index", pos={in_col1, in_row4}, size={in_ButWid, ctrl_height}
	//	Button in_DoIndex proc = UAI_ButtonProc
	//	
	//	CheckBox in_GlobalRe_ck title = "Global Re-index", pos={in_col1, in_row1}, size={in_ColWid, ctrl_height}
	//	CheckBox in_GlobalRe_ck variable=root:UAI_Folder:xBox_GlobalRedo, proc=UAI_CheckProc
	//	CheckBox in_OnlyNewFolder_ck title = "Only New Folders", pos={in_col1, in_row2}, size={in_ColWid, ctrl_height}
	//	CheckBox in_OnlyNewFolder_ck variable=root:UAI_Folder:xBox_OnlyNewFolder, proc=UAI_CheckProc		
	//
	//	CheckBox in_GraphProgress_ck title = "Graph Progress", pos={in_col2, in_row1}, size={in_ColWid, ctrl_height}
	//	CheckBox in_GraphProgress_ck variable=root:UAI_Folder:xBox_GraphProgress
	//	
	//
	//	// Use Index Controls
	//		// Set Draw Use Index buttons and checkboxes
	//		// NOTE: the index path setters and msg are still left visible
	//		
	//		Variable sing_row1 = 120
	//		Variable sing_col1 = 15, sing_col1Wid = 210
	//		Variable sing_col2 = 8 + sing_col1 + sing_col1Wid, sing_col2Wid = 210, sing_col2BodyWid = 180
	//		Variable sing_col3 = 2 + sing_col2 + sing_col2Wid, sing_col3Wid = 25
	//		Variable sing_row2 = sing_row1 + ctrl_height + 1
	//		Variable sing_row3 = sing_row2 + ctrl_height + 1
	//		Variable sing_row4 = sing_row3 + ctrl_height + 1
	//		
	//		Variable tt_row1 = sing_row1 + 137
	//		Variable tt_row2 = tt_row1 + ctrl_height + 1
	//		Variable tt_row3 = tt_row2 + ctrl_height + 1
	//		Variable tt_row4 = tt_row3 + ctrl_height + 1
	//		Variable tt_col1 = sing_col1
	//		Variable tt_col2 = sing_col2
	//		Variable tt_col1Wid = sing_col1Wid
	//		Variable tt_col2Wid = sing_col2Wid
	//		
	//	GroupBox us_Single_gb, title = "Single Spectrum amsx & atof"
	//	GroupBox us_Single_gb, pos={sing_col1-5, sing_row1 - 21}, size={sing_col1Wid + sing_col2Wid + Sing_col3Wid + 19, 5 * ctrl_height + 5}
	//		
	//	SetVariable us_DisplayNow_sv, title = "time", pos = {sing_col1, sing_row1 }, size = {sing_col1Wid, ctrl_height}, fsize=12
	//	SetVariable us_DisplayNow_sv, value=$(ks_UAIFolder+":dv_now_str"), proc=UAI_TimeInOrLoad
	//	
	//	CheckBox us_Enslave_ck, title = "enslave time to compat. b2e", pos = {sing_col1, sing_row2 }, size = {sing_col1Wid, ctrl_height}
	//	CheckBox us_Enslave_ck, variable=root:UAI_Folder:xBox_EnslaveTo_b2e, fsize=12
	//	
	//	CheckBox us_ForceLook_ck, title = "use forced time look up", pos = {sing_col1, sing_row3 }, size = {sing_col1Wid, ctrl_height}
	//	CheckBox us_ForceLook_ck, variable=root:UAI_Folder:xBox_forcedLookup, fsize=12	
	//		
	//	SetVariable us_FoundAMSX_File_sv, title = "amsx", pos = {sing_col2, sing_row1 }, size = {sing_col2Wid, ctrl_height}
	//	SetVariable us_FoundAMSX_File_sv, value=$(ks_UAIFolder+":dv_MatchAMSX_Filename"), noedit=1, fsize=12
	//	SetVariable us_FoundAMSX_File_sv, bodywidth = sing_col2BodyWid
	//
	//	CheckBox us_ReCalibrateAMU_ck, title = "Recalibrate amu", pos = {sing_col2, sing_row2 }, size = {sing_col2Wid, ctrl_height}
	//	CheckBox us_ReCalibrateAMU_ck, variable=root:UAI_Folder:xBox_ReCalibrateAmu, fsize=12	
	//		
	//	SetVariable us_FoundATOF_File_sv, title = "atof", pos = {sing_col2, sing_row3 }, size = {sing_col2Wid, ctrl_height}
	//	SetVariable us_FoundATOF_File_sv, value=$(ks_UAIFolder+":dv_MatchATOF_Filename"), noedit=1, fsize=12
	//	SetVariable us_FoundATOF_File_sv, bodywidth = sing_col2BodyWid
	//
	//	CheckBox us_Bin2LogOnTOFS_ck, title = "do atof diam to even log bins", pos = {sing_col2, sing_row4 }, size = {sing_col2Wid, ctrl_height}
	//	CheckBox us_Bin2LogOnTOFS_ck, variable=root:UAI_Folder:xBox_Bin2LogOnTOFS, fsize=12	
	//		
	//		
	//	Button us_AMSXGraph_but, title=">", pos={sing_col3, sing_row1-2}, size = {sing_col3Wid, ctrl_height}
	//	Button us_AMSXGraph_but, proc =UAI_UseIndexButtonProc, fsize=12
	//	
	//	Button us_ATOFGraph_but, title=">", pos={sing_col3, sing_row3}, size = {sing_col3Wid, ctrl_height}
	//	Button us_ATOFGraph_but, proc =UAI_UseIndexButtonProc	, fsize=12
	//
	////
	////	Time Trend Set of controls
	//	GroupBox us_TimeTrend_gb, title = "Time Trend Creation Parameters"
	//	GroupBox us_TimeTrend_gb, pos={tt_col1-5, tt_row1 - 21}, size={tt_col1Wid + tt_col2Wid + Sing_col3Wid + 19, 5 * ctrl_height + 5}
	//	
	//	SetVariable us_TTBegin_sv, title = "ttBegin", pos = {tt_col1, tt_row1 }, size = {tt_col1Wid, ctrl_height}, fsize=12
	//	SetVariable us_TTBegin_sv, value=$(ks_UAIFolder+":dv_ttBegin_str"), proc=UAI_ttTimeInput
	//	
	//	SetVariable us_ttEnd_sv, title = "ttEnd", pos = {tt_col1, tt_row2 }, size = {tt_col1Wid, ctrl_height}, fsize=12
	//	SetVariable us_ttEnd_sv, value=$(ks_UAIFolder+":dv_ttEnd_str"), proc=UAI_ttTimeInput
	//	
	//	SetVariable us_DestDF_sv, title = "Destination DF", pos = {tt_col2, tt_row1 }, size = {tt_col1Wid, ctrl_height}, fsize=12
	//	SetVariable us_DestDF_sv, value=$(ks_UAIFolder+":TimeTrend_DestDF"), proc=UAI_zWeakDFCheck
	//
	//	SetVariable us_TTStatus_sv, title = "ttStatus", pos = {tt_col1, tt_row3 }, size = {tt_col1Wid * 2, ctrl_height}, fsize=12
	//	SetVariable us_TTStatus_sv, value=$(ks_UAIFolder+":TimeTrendStatus"), noedit=1	
	//
	//	Button us_ttCommit_but, title="Commit to TT Creation", pos={tt_col2, tt_row4}, size = {tt_col2Wid, ctrl_height}
	//	Button us_ttCommit_but, proc =UAI_UseIndexButtonProc	, fsize=12
	//	
	//		
	//		// String destFolder = ks_UAIFolder
	//		SVAR Ring_msg=$(destFolder + ":Ring_msg" )
	//		SVAR Index_msg=$(destFolder + ":Index_msg" )
	//		SVAR Ring_Path=$(destFolder + ":Ring_Path" )
	//		NVAR RingFound=$(destFolder + ":RingFound" )
	//		NVAR GlobalRedo=$(destFolder + ":xBox_GlobalRedo")
	//		NVAR OnlyNewFolder=$(destFolder + ":xBox_OnlyNewFolder")
	//		NVAR EnslaveTo_b2e = $(destFolder + ":xBox_EnslaveTo_b2e")
	//		NVAR ForcedLookup = $(destFolder + ":xBox_forcedLookup")
	//		NVAR RecalibrateAMU = $(destFolder + ":xBox_ReCalibrateAmu")
	//		NVAR Bin2LogOnTOFS = $(destFolder + ":xBox_Bin2LogOnTOFS")
	//		NVAR ndv_now = $(destFolder + ":ndv_now")
	//		NVAR ndv_ttBegin = $(destFolder + ":ndv_ttBegin")
	//		NVAR ndv_ttEnd = $(destFolder + ":ndv_ttEnd")
	//		
	//		SVAR dv_now_str = $(destFolder + ":dv_now_str")
	//		SVAR dv_MatchAMSX_FileName=$(destFolder + ":dv_MatchAMSX_FileName" )
	//		SVAR LastAMSX_FileName=$(destFolder + ":LastAMSX_FileName" )
	//		SVAR dv_MatchATOF_FileName=$(destFolder + ":dv_MatchATOF_FileName" )
	//		SVAR LastATOF_FileName=$(destFolder + ":LastATOF_FileName" )
	//
	//		SVAR TimeTrendStatus=$(destFolder + ":TimeTrendStatus" )
	//		SVAR TimeTrend_DestDF=$(destFolder + ":TimeTrend_DestDF" )
	//		SVAR dv_ttBegin_str=$(destFolder + ":dv_ttBegin_str" )
	//		SVAR dv_ttEnd_str=$(destFolder + ":dv_ttEnd_str" )
End

Function zSPE_AVSetVarProc(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	zSPE2_AVCheckBoxProc("",0)

End
Function zSPE2_MainButtonProc( ctrl ) : ButtonControl
	String ctrl
	
	SVAR BrowseMSG = root:LoadSPE_UI:BrowseMSG
	SVAR LoadMSG = root:LoadSPE_UI:LoadMSG
	
	Variable trigger_filelisting = 0
	Variable result
	if( force_redraw_zspe2 )
		sprintf LoadMSG, "debug - proc click %s", ctrl
	endif
	
	if( cmpstr( ctrl, "ao_SetPath_but" ) == 0 )
		// This button is always on, and is the main set path button -- its goal is to endeavor to help the user
		// find the files they are going for.
		result = zSPE2_GentleSetPath()
		if( result == 1 )
			trigger_filelisting = 1;
		endif
		
	endif
	if( cmpstr( ctrl, "lo_LoOrCat_but" ) == 0 )
		zSPE2_ConcatAndPrepSPB();
	endif
	if( cmpstr( ctrl, "ao_Chrono_but" ) == 0 )
		zSPE2_BuildFileList(1);
		trigger_filelisting = 0 		// just in case, don't overwrite our hard work
	endif
	
	if( cmpstr( ctrl, "br_graph1_but" ) == 0 )
		zSPE2_TransAndSigGraphDraw( 1, 1 ); SetAxis/A
	endif	
	if( cmpstr( ctrl, "br_graph2_but" ) == 0 )
		zSPE2_TransAndSigGraphDraw( 2, 1 ); SetAxis/A
	endif	
	if( cmpstr( ctrl, "br_graph3_but" ) == 0 )
		zSPE2_TransAndSigGraphDraw( 3, 1 ); SetAxis/A
	endif	
	if( cmpstr( ctrl, "br_graph4_but" ) == 0 )
		zSPE2_TransAndSigGraphDraw( 4, 1 ); SetAxis/A
	endif
	
	if( cmpstr( ctrl, "ao_ZipInZipOut" ) == 0 )
		NVAR WorkingWithZip = root:LoadSPE_UI:WorkingWithZip
		if( WorkingWithZip )	
			zSPE2_CollapseZip()	
			Button ao_ZipInZipOut title="Expand Zip"
			WorkingWithZip = 0
		else
			zSPE2_ExpandZip()
			Button ao_ZipInZipOut title="Collapse Zip"
			WorkingWithZip = 1
		endif
		
	endif
	if( cmpstr( ctrl, "av_AlgoA" ) == 0 )
		zSPE2_AlgoA_Wrapper();
	endif	
	//	Button av_AlgoA proc=zSPE2_MainButtonProc, disable=2, fsize=6

	NVAR Roll_SpeciesNumber = root:LoadSPE_UI:Roll_SpeciesNumber
	
	if( cmpstr( ctrl, "br_increSN_but" ) == 0 )
		Roll_SpeciesNumber += 1
		zSPE2_UpdateBrowseBits()
	endif
	if( cmpstr( ctrl, "br_decreSN_but" ) == 0 )
		Roll_SpeciesNumber -= 1
		zSPE2_UpdateBrowseBits()
	endif
	if( trigger_filelisting )
		DoUpdate;
		zSPE2_BuildFileList(0)
		Wave/T disp_fileList = root:LoadSPE_UI:disp_fileList

		if( numpnts( disp_fileList ) != 0 )
			//Button ao_Chrono_but win=$ks_zSPE2PanelName, disable=0
		endif
	endif
End
Function zSPE2_AlgoA_Wrapper()

	Wave/T disp_fileList = root:LoadSPE_UI:disp_fileList
	Wave/T pack_fileList = root:LoadSPE_UI:pack_fileList
	Wave/T path_fileList = root:LoadSPE_UI:path_fileList
	Wave disp_SelWave = root:LoadSPE_UI:disp_SelWave
	SVAR AverageOptionsStr = root:LoadSPE_UI:AverageOptionsStr
	
	SVAR path2files = root:LoadSPE_UI:path2files;
	
	Make/N=0/T/O serve_to_algoA_tw;
	
	NVAR WorkingWithZip = root:LoadSPE_UI:WorkingWithZip
	if( WorkingWithZip )	
		print "Collapse the Open Zip and select zip(s) before attempting Algo A"		
	else
		Variable zip_anywhere = 0
		Variable idex = 0, count = numpnts( disp_SelWave )
		if( count > 0 )
			do	
				if( disp_SelWave[idex] )
					if( strsearch( disp_fileList[idex], ".zip", 0 ) != -1 )
						zip_anywhere = 1
						AppendString( serve_to_algoA_tw, disp_fileList[idex] );
					endif
				endif
				idex += 1
			while( idex < count )
		endif	
		
		if( zip_anywhere )
			idex = 0; count = numpnts( serve_to_algoA_tw );
			NewPath/Z/O toZipFiles, path2files
				
			// UEX:0 or UEX:1 will direct AlgoA to 0 - not extract or 1 - extract to uex_token directories
			//#define OPTS_UEX "UEX"
			// CHIVAL
			// CHISWP
			// these items must be used together!
			// CHIVAL:val;CHISWP:1 will filter against greater than val for the first fit in sweep #1
			//#define OPTS_CHIV "CHIVAL"
			//#define OPTS_CHIS "CHISWP"


			String thisFile, OptionsString = AverageOptionsStr;
			if( count > 0 )
				do
						
					thisFile = serve_to_algoA_tw[idex];
					printf "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\r"
					printf "Processing %s [%d/%d] >>%s\r", thisFile, idex+1, count, path2files
					// If you are receiving an error RIGHT HERE
					//scx5_AverageHW_AlgoA /P=toZipFiles /Q thisFile, OptionsString
					// you probably need to get either beta xops >> scx5.xop, scx5Win32.xop
					// or you need the release version >>Wintel_UZAG.xop
					idex += 1
				while( idex < count );
				printf "Look in directory printed below for subdirectories containing averaged spectra\r%s", path2files
					
			endif
		endif
	endif
	
	
	


End

Function zSPE_SetZipInZipOutButton()
		
	Wave/T disp_fileList = root:LoadSPE_UI:disp_fileList
	Wave/T pack_fileList = root:LoadSPE_UI:pack_fileList
	Wave/T path_fileList = root:LoadSPE_UI:path_fileList
	Wave disp_SelWave = root:LoadSPE_UI:disp_SelWave
	
	NVAR WorkingWithZip = root:LoadSPE_UI:WorkingWithZip
	if( WorkingWithZip )	
		Button ao_ZipInZipOut title="Collapse Zip"
		WorkingWithZip = 1
		//Button av_AlgoA  disable=2
	else
		Button ao_ZipInZipOut title="Expand Zip", disable=2
		WorkingWithZip = 0
		Variable zip_anywhere = 0
		Variable idex = 0, count = numpnts( disp_SelWave )
		if( count > 0 )
			do	
				if( disp_SelWave[idex] )
					if( strsearch( disp_fileList[idex], ".zip", 0 ) != -1 )
						zip_anywhere = 1
						idex = count
					endif
				endif
				idex += 1
			while( idex < count )
		endif	
		
		if( zip_anywhere )
			Button ao_ZipInZipOut title="Expand Zip", disable=0
			//Button av_AlgoA disable=0
		endif
	endif
	
	
	
End
Function zSPE2_ExpandZip()
	// This function assumes that the user would like to expand any selected zips
	// if multiple are selected, that's ok, we will power through the whole sel wave here
	// also -- a shadow of the former directory will be created
	// the variable 	NVAR WorkingWithZip = root:LoadSPE_UI:WorkingWithZip
	// will be set to 1 and the title changed of the zipinzipout button
	Wave/D disp_time = root:LoadSPE_UI:disp_time
	Wave/T disp_fileList = root:LoadSPE_UI:disp_fileList
	Wave/T pack_fileList = root:LoadSPE_UI:pack_fileList
	Wave/T path_fileList = root:LoadSPE_UI:path_fileList
	Wave disp_SelWave = root:LoadSPE_UI:disp_SelWave
	
	NVAR WorkingWithZip = root:LoadSPE_UI:WorkingWithZip
	SVAR BrowseMSG = root:LoadSPE_UI:BrowseMSG

	sprintf BrowseMSG, "Expanding..."	
	String saveFolder = GetDataFolder(1)
	SetDataFolder root:; MakeAndOrSetDF( "root:LoadSPE_UI");
	Duplicate/O disp_time, shadow_disp_time
	Duplicate/O disp_fileList, shadow_disp_fileList
	Duplicate/O pack_fileList, shadow_pack_fileList
	Duplicate/O path_fileList, shadow_path_fileList
	Duplicate/O disp_SelWave, shadow_disp_SelWave
	
	Make/T/O/N=0 zipFileList
	SetDataFolder $saveFolder
	Wave/T zipFileLIst = root:loadspe_ui:ZipFileList
	
	Wave/D shd_disp_time = root:loadspe_ui:shadow_disp_time
	Wave/T shd_disp_fileList = root:loadspe_ui:shadow_disp_fileList
	Wave/T shd_pack_fileList = root:loadspe_ui:shadow_pack_fileList
	Wave/T shd_path_fileList = root:loadspe_ui:shadow_path_fileLIst
	Wave shd_disp_SelWave = root:LoadSPE_UI:shadow_disp_SelWave

	// nice, we now have two sets of waves, the shadow holds the data from which we now build disps and packs and paths
	String fullfile2zip
	
	Redimension/N=0 disp_time
	Redimension/N=0 disp_fileList, pack_fileList, path_fileList
	Redimension/N=0 disp_SelWave
	
	Variable this_time, result
	String thisEntry
	String thisDispFile
	String thisPath
	String fullpath2zip
	
	String this_file_in_zip
	String this_zip_file
	String this_unk_file
	Variable jdex = 0, jcount, stilloktoadd
	Variable idex = 0, count = numpnts( shd_disp_SelWave )
	if( count > 0 )
		do
			if( shd_disp_SelWave[idex] )
				this_unk_file = shd_disp_fileList[idex]
				if( strsearch( this_unk_file, ".zip", 0 ) != -1 )
					// this is a zip and it is selected from the shadow
					this_zip_file = this_unk_file
					fullpath2zip = WindowsFullPath( shd_path_fileList[idex],this_zip_file )
					if( FileExistsFullPath( fullpath2zip ) != 0 )
						sprintf BrowseMSG, "Failure to find %s", fullpath2zip
					else
						sprintf BrowseMSG, "Expanding %s", fullpath2zip
						// Old Method	result = scx_FileListFrmZip( fullpath2zip, ZipFileList )
						String toPathStr = shd_path_fileList[idex];
						NewPath/Q/O QuickUzPath, toPathStr
						//scx5_FileListFromZip/P=QuickUzPath /Q this_zip_file, root:loadspe_ui:ZipFileList
						result = 0;
						if( result == 0 )
							jdex = 0; jcount = numpnts( ZipFileList )
							sprintf BrowseMSG, "Expansion found %d files", jcount

							if( jcount > 0 )
								do
									this_file_in_zip = ZipFileList[jdex]
									if( strsearch( lowerstr(this_file_in_zip), ".spe", 0 ) != -1 )
										stilloktoadd = zSPE2_FilterOnMinusCheckBoxes( this_file_in_zip )
										if( stilloktoadd )
											thisEntry = ""
											sprintf thisEntry, "%sZIP:%s;FILE:%s;", thisEntry, this_zip_file, this_file_in_zip
										
											thisPath = shd_path_fileList[idex]
											this_time = 0
											AppendVal( disp_time, this_time )
											AppendString( disp_fileList, this_file_in_zip )
											AppendString( pack_fileList, thisEntry )
											AppendString( path_fileList, thisPath )
											AppendVal( disp_SelWave, 0 )
										endif
									endif
									jdex += 1
								while( jdex < jcount )
							endif
						else
							sprintf BrowseMSG, "Expansion of %s returned %d", fullpath2zip, result
						endif		
					endif
				else
					// this may be a selected spe file which the user is trying to 'force include'
					// it was there, so we shouldn't block it with still ok to add
					thisEntry = ""
					sprintf thisEntry, "%sZIP:%s;FILE:%s;", thisEntry, "xx", this_unk_file
					thisPath = shd_path_fileList[idex]
					this_time = 0				
					AppendVal( disp_time, this_time )
					AppendString( disp_fileList, shd_disp_FileList[idex] )
					AppendString( pack_fileList, thisEntry )
					AppendString( path_fileList, thisPath )
					AppendVal( disp_SelWave, 0 )
				endif
			endif
			idex += 1
		while( idex < count)
	endif
	
	
	// now how can we pop the list box here?
	ControlUpdate/W=ks_zSPE2PanelName/A
	String thePanel = ks_zSPE2PanelName
	ListBox ao_STR_LB1,win=$thePanel, listWave=disp_FileList,selWave=disp_SelWave,mode= 4, proc=LoadSPE_LBProc
	Button ao_ZipInZipOut, win=$thePanel, title="Collapse Zip", disable=0

End
Function zSPE2_ReFilterExpandedZip()
	// This function assumes that the user would like to expand any selected zips
	// if multiple are selected, that's ok, we will power through the whole sel wave here
	// also -- a shadow of the former directory will be created
	// the variable 	NVAR WorkingWithZip = root:LoadSPE_UI:WorkingWithZip
	// will be set to 1 and the title changed of the zipinzipout button
	Wave/D disp_time = root:LoadSPE_UI:disp_time
	Wave/T disp_fileList = root:LoadSPE_UI:disp_fileList
	Wave/T pack_fileList = root:LoadSPE_UI:pack_fileList
	Wave/T path_fileList = root:LoadSPE_UI:path_fileList
	Wave disp_SelWave = root:LoadSPE_UI:disp_SelWave
	SVAR BrowseMSG = root:LoadSPE_UI:BrowseMSG

	sprintf BrowseMSG, "Refiltering..."	
	Wave/T zipFileLIst = root:loadspe_ui:ZipFileList
	
	Wave/D shd_disp_time = root:loadspe_ui:shadow_disp_time
	Wave/T shd_disp_fileList = root:loadspe_ui:shadow_disp_fileList
	Wave/T shd_pack_fileList = root:loadspe_ui:shadow_pack_fileList
	Wave/T shd_path_fileList = root:loadspe_ui:shadow_path_fileLIst
	Wave shd_disp_SelWave = root:LoadSPE_UI:shadow_disp_SelWave

	// nice, we now have two sets of waves, the shadow holds the data from which we now build disps and packs and paths
	String fullfile2zip
	
	Redimension/N=0 disp_time
	Redimension/N=0 disp_fileList, pack_fileList, path_fileList
	Redimension/N=0 disp_SelWave
	
	Variable this_time, result
	String thisEntry
	String thisDispFile
	String thisPath
	String fullpath2zip
	
	String this_file_in_zip
	String this_zip_file
	String this_unk_file
	Variable jdex = 0, jcount, stilloktoadd
	Variable idex = 0, count = numpnts( shd_disp_SelWave )
	if( count > 0 )
		do
			if( shd_disp_SelWave[idex] )
				this_unk_file = shd_disp_fileList[idex]
				if( strsearch( this_unk_file, ".zip", 0 ) != -1 )
					// this is a zip and it is selected from the shadow
					this_zip_file = this_unk_file
					fullpath2zip = WindowsFullPath( shd_path_fileList[idex],this_zip_file )
					if( FileExistsFullPath( fullpath2zip ) != 0 )
						sprintf BrowseMSG, "Failure to find %s", fullpath2zip
					else
						sprintf BrowseMSG, "Expanding %s", fullpath2zip
						// Old Method result =  scx_FileListFrmZip( fullpath2zip, ZipFileList )
						// new Operation Method
						NewPath/O/Q QuickUzPath, shd_path_fileList[idex]
						//scx5_FileListFromZip/Q/P=QuickUzPath /Q this_zip_file, root:loadspe_ui:ZipFileList
						result = 0;
						if( result == 0 )
							jdex = 0; jcount = numpnts( ZipFileList )
							sprintf BrowseMSG, "Expansion found %d files", jcount

							if( jcount > 0 )
								do
									this_file_in_zip = ZipFileList[jdex]
									if( strsearch( lowerstr(this_file_in_zip), ".spe", 0 ) != -1 )
										stilloktoadd = zSPE2_FilterOnMinusCheckBoxes( this_file_in_zip )
										if( stilloktoadd )
											thisEntry = ""
											sprintf thisEntry, "%sZIP:%s;FILE:%s;", thisEntry, this_zip_file, this_file_in_zip
										
											thisPath = shd_path_fileList[idex]
											this_time = 0
											AppendVal( disp_time, this_time )
											AppendString( disp_fileList, this_file_in_zip )
											AppendString( pack_fileList, thisEntry )
											AppendString( path_fileList, thisPath )
											AppendVal( disp_SelWave, 0 )
										endif
									endif
									jdex += 1
								while( jdex < jcount )
							endif
						else
							sprintf BrowseMSG, "Expansion of %s returned %d", fullpath2zip, result
						endif		
					endif
				else
					// this may be a selected spe file which the user is trying to 'force include'
					// it was there, so we shouldn't block it with still ok to add
					thisEntry = ""
					sprintf thisEntry, "%sZIP:%s;FILE:%s;", thisEntry, "xx", this_unk_file
					thisPath = shd_path_fileList[idex]
					this_time = 0				
					AppendVal( disp_time, this_time )
					AppendString( disp_fileList, shd_disp_FileList[idex] )
					AppendString( pack_fileList, thisEntry )
					AppendString( path_fileList, thisPath )
					AppendVal( disp_SelWave, 0 )
				endif
			endif
			idex += 1
		while( idex < count)
	endif
	
	
	// now how can we pop the list box here?
	ControlUpdate/W=ks_zSPE2PanelName/A
	String thePanel = ks_zSPE2PanelName
	ListBox ao_STR_LB1,win=$thePanel, listWave=disp_FileList,selWave=disp_SelWave,mode= 4, proc=LoadSPE_LBProc
	Button ao_ZipInZipOut, win=$thePanel, title="Collapse Zip", disable=0

End
Function zSPE2_CollapseZip()

	Wave/D shd_disp_time = root:loadspe_ui:shadow_disp_time
	Wave/T shd_disp_fileList = root:loadspe_ui:shadow_disp_fileList
	Wave/T shd_pack_fileList = root:loadspe_ui:shadow_pack_fileList
	Wave/T shd_path_fileList = root:loadspe_ui:shadow_path_fileLIst
	Wave shd_disp_SelWave = root:LoadSPE_UI:shadow_disp_SelWave
	
	Wave/D disp_time = root:LoadSPE_UI:disp_time
	Wave/T disp_fileList = root:LoadSPE_UI:disp_fileList
	Wave/T pack_fileList = root:LoadSPE_UI:pack_fileList
	Wave/T path_fileList = root:LoadSPE_UI:path_fileList
	Wave disp_SelWave = root:LoadSPE_UI:disp_SelWave
	
	Wave/T zipFileLIst = root:loadspe_ui:ZipFileList

	Duplicate/O/D shd_disp_time, disp_time
	Duplicate/O/T shd_disp_fileList, disp_filelist
	Duplicate/O/T shd_pack_fileList, pack_fileList
	Duplicate/O/T shd_path_fileList, path_fileList
	Duplicate/O shd_disp_SelWave, disp_SelWave
	
	KillWaves/Z shd_disp_time, shd_disp_fileList, shd_pack_fileList, shd_path_fileLIst, shd_disp_SelWave, zipFileList
	
	//	ControlUpdate/W=ks_zSPE2_PanelName/A
	// now how can we pop the list box here?
	//	ControlUpdate/W=ks_zSPE2PanelName/A
	String thePanel = ks_zSPE2PanelName
	ListBox ao_STR_LB1,win=$thePanel,row=0
	//	LoadSPE_LBProc( "ao_STR_LB1", 0, 1, 1 )
End
Function zSPE2_BuildFileList(build_code)
	Variable build_code
	
	// use build_code = 0 to get the basic listing; build_code =1 for 
	// 
	Wave/D disp_time = root:LoadSPE_UI:disp_time
	Wave/T disp_fileList = root:LoadSPE_UI:disp_fileList
	Wave/T pack_fileList = root:LoadSPE_UI:pack_fileList
	Wave/T path_fileList = root:LoadSPE_UI:path_fileList
	Wave disp_SelWave = root:LoadSPE_UI:disp_SelWave

	SVAR BrowseMSG = root:LoadSPE_UI:BrowseMSG
	SVAR Path2Files = root:LoadSPE_UI:Path2Files
	
	Redimension/N=0 disp_time, disp_fileList, pack_filelist, disp_SelWave
	Variable msg_RedNorm = 56576, msg_RedAlert = 62550
	Variable msg_GreenNorm = 56576, msg_GreenAlert = 0
	Variable msg_BlueNorm = 56576, msg_BlueAlert = 0
	Variable msg_SizeNorm = 12, msg_SizeAlert = 16
	
	
	SetVariable ao_BrowseMessage, win=$ks_zSPE2PanelName, labelBack=(msg_RedAlert, msg_GreenAlert, msg_BlueAlert), fsize=msg_SizeAlert
	DoUpdate;
	
	zSPE2_BuildRawFileList( disp_filelist, pack_filelist, path_filelist )
	
	if( build_code == 0 )
		// this is the simple case
		Redimension/N=(numpnts(disp_fileList)) disp_SelWave, disp_time
		disp_SelWave = 0
		disp_time = 0
	endif

	SetVariable ao_BrowseMessage, win=$ks_zSPE2PanelName, labelBack=(msg_RedNorm, msg_GreenNorm, msg_BlueNorm), fsize=msg_SizeNorm
	DoUpdate;	
End


Function zSPE2_BuildRawFileList(raw_filelist, pack_filelist, path_filelist)
	Wave/T raw_filelist
	Wave/T pack_filelist
	Wave/T path_filelist
	
	variable result = -1
	SVAR BrowseMSG = root:LoadSPE_UI:BrowseMSG
	SVAR Path2Files = root:LoadSPE_UI:Path2Files	
	
	NVAR xBox_IncludeZip = root:LoadSPE_UI:xBox_IncludeZip
	NVAR xBox_IncludeSPE = root:LoadSPE_UI:xBox_IncludeSPE
	NVAR xBox_BlockBK = root:LoadSPE_UI:xBox_BlockBK
	NVAR xBox_BlockRef = root:LoadSPE_UI:xBox_BlockRef

	Make/O/T/N=0 temp_zspe2_prefilter
	
	NewPath/Q/O/Z temp_zspe2_path, Path2Files
	if( V_Flag != 0 )
		sprintf BrowseMSG, "Path Reference Failed? %s", Path2Files
		result = -1
	else
		sprintf BrowseMsg, "Generating file list for %s", Path2Files
		DoUpdate
		GFL_FileListAtOnce( "temp_zspe2_path", 0, temp_zspe2_prefilter, "????" )
		
		sort temp_zspe2_prefilter, temp_zspe2_prefilter
		
		
		zSPE_FilterFileList( temp_zspe2_prefilter, raw_filelist, pack_filelist, path_filelist )
	endif
	KillWaves/Z temp_zspe2_prefilter
	
	return result
End
Function zSPE_FilterFileList( source_file_list, dest_file_list, pack_filelist, path_filelist)
	Wave/T source_file_list
	Wave/T dest_file_list
	Wave/T pack_filelist
	Wave/T path_filelist
	
	SVAR BrowseMSG = root:LoadSPE_UI:BrowseMSG
	SVAR Path2Files = root:LoadSPE_UI:Path2Files	
	
	NVAR xBox_IncludeZip = root:LoadSPE_UI:xBox_IncludeZip
	NVAR xBox_IncludeSPE = root:LoadSPE_UI:xBox_IncludeSPE
	NVAR xBox_BlockBK = root:LoadSPE_UI:xBox_BlockBK
	NVAR xBox_BlockRef = root:LoadSPE_UI:xBox_BlockRef
	NVAR xBox_BlockNorm = root:LoadSPE_UI:xBox_BlockNorm

	Redimension/N=0 dest_file_list, pack_filelist, path_filelist
	String thisEntry
	String this_file
	Variable stilloktoadd, zip_dex
	Variable idex = 0, count = numpnts( source_file_list )
	do
		thisEntry = "";
		this_file = source_file_list[idex]
		// if zip and if includezip, add
		zip_dex = strsearch( this_file, ".zip", 0 )

		if( zip_dex != -1 )
			if( xBox_IncludeZip )
				AppendString( dest_file_list, this_file )
				sprintf thisEntry,"%sZIP:%s;FILE:xx;", thisEntry, this_file
				AppendString( pack_filelist, thisEntry )
				AppendString( path_filelist, Path2Files )
			endif
		endif
		
		// if spe then include
		if( strsearch( lowerstr( this_file), ".spe", 0 ) != -1 )
			if( xBox_IncludeSPE )
				stilloktoadd = 1
				stilloktoadd = zSPE2_FilterOnMinusCheckBoxes( this_file )
				if( stilloktoadd )
					AppendString( dest_file_list, this_file );
					sprintf thisEntry,"%sZIP:xx;FILE:%s;", thisEntry, this_file
					AppendString( pack_filelist, thisEntry );
					AppendString( path_filelist, Path2Files );
				endif 
			endif
		endif
		idex += 1
	while( idex < count )
	
End
Function zSPE2_FilterOnMinusCheckBoxes( filename )
	String filename
	
	Variable stilloktoadd = 1
	NVAR xBox_BlockBK = root:LoadSPE_UI:xBox_BlockBK
	NVAR xBox_BlockRef = root:LoadSPE_UI:xBox_BlockRef
	NVAR xBox_BlockPN = root:LoadSPE_UI:xBox_BlockPN
	NVAR xBox_BlockRaw = root:LoadSPE_UI:xBox_BlockRaw
	NVAR xBox_BlockCal = root:LoadSPE_UI:xBox_BlockCal
	NVAR xBox_BlockWild = root:LoadSPE_UI:xBox_BlockWild
	NVAR xBox_BlockNorm = root:LoadSPE_UI:xBox_BlockNorm
	
	if( xBox_BlockBK )
		if( strsearch( filename, "_BG", 0 ) != -1 )
			stilloktoadd = 0
		endif
	endif
	if( xBox_BlockRef )
		if( strsearch( filename, "_REF", 0 ) != -1 )
			stilloktoadd = 0
		endif
	endif				
	if( xBox_BlockPN )
		if( strsearch( filename, "_PN", 0 ) != -1 )
			stilloktoadd = 0
		endif
	endif	
	if( xBox_BlockRaW )
		if( strsearch( filename, "_RAW", 0 ) != -1 )
			stilloktoadd = 0
		endif
	endif	
	if( xBox_BlockCAL )
		if( strsearch( filename, "_CAL", 0 ) != -1 )
			stilloktoadd = 0
		endif
	endif	
	if( xBox_BlockWild )
		if( strsearch( filename, ks_WildWintelBlockStr, 0 ) != -1 )
			stilloktoadd = 0
		endif
	endif
	if( xBox_BlockNorm )
		Variable len = strlen( filename )-1, idex = len, last_underscoreDex = -1
		Variable dotdex = strsearch( filename, ".", 0 )
		do
			if( cmpstr( filename[idex], "_" ) == 0 )
				last_underscoreDex = idex; idex = 0
			endif
			idex -= 1
		while( idex > 0 )
		if( numtype( str2num( filename[last_underscoreDex+1, dotdex-1]) ) == 0 )
			stilloktoadd = 0
		endif
	
	endif				
	return stilloktoadd
End
Function zSPE2_CheckPath(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	SVAR BrowseMSG = root:LoadSPE_UI:BrowseMSG
	
	NewPath/O/Z/Q zspe2_temp_test, varStr
	if( V_flag == 0 )
		// sucess! it is a valid path
		zSPE2_BuildFileList(0)
	else
		sprintf BrowseMSG, "Failure to build path to %s", varStr	
	endif
	
End

Function zSPE2_GentleSetPath()

	SVAR BrowseMSG = root:LoadSPE_UI:BrowseMSG
	SVAR Path2Files = root:LoadSPE_UI:Path2Files
	Variable skipAggressivePreset
	
	NVAR/Z BeenThroughASetPathThisSession = root:LoadSPE_UI:BeenThroughASetPAthThisSession
	if( NVAR_Exists( BeenThroughASetPAthThisSession ) )
		skipAggressivePreset = 1
	else
		skipAggressivePreset = 0
		String saveFolder = GetDataFolder(1)
		SetDataFolder root:
		MakeAndOrSetDF( "LoadSPE_UI" )
		Variable/G BeenThroughASetPathThisSession = 1
		SetDataFolder $saveFolder
	endif
	Variable result = -1
	String list = nSTR_h_ProbeCommonPaths() // this already has done the checking of paths. 

	String this_dir
	Variable idex = 0, count = ItemsInList( list )
			
	if( skipAggressivePreset != 1 )

		do // this loop obsolete
			this_dir = StringFromList( idex, list )
			NewPath/O/Z/Q zspe2_temp_test, this_dir
			if( v_flag == 0 )
				// sucess!  => this is now the 'last path set'
				PathInfo/S zspe2_temp_test
				idex = count
			endif
			idex += 1
		while( idex < count )
	endif
	
	NewPath/O/Z/Q zspe2_other_pathtest, Path2Files
	if( V_Flag == 0 )
		// sucess, a legitimate path is in the command line, we'll override a possilbe match or in anycase
		// the last 'session' with this one
		PathInfo/S zspe2_other_pathtest
	endif
	
	
	sprintf browsemsg, "Pick Directory which has spe or spe/zip archives"	
	// We have protected the user from opening the browse somewhere with a potential henious number of files
	NewPath/M="Select Directory with SPE and/or SPE/ZIP archives..."/O/Q zspe2_temp_test
	if( v_flag != 0 )
		sprintf browsemsg, "browse aborted by user or error"
	else
		PathInfo zspe2_temp_test
		if( v_flag )
			path2files = s_path
			sprintf browsemsg, "filelist generated from ->%s...", WindowsFullPath( path2files, "" )
			result = 1;
		else
			path2files = "error"
			result = 0;
		endif		
	endif
	KillPath/Z zspe2_temp_test
	return result;
End

Function zSPE2_FileCheckBoxProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	NVAR WorkingWithZip = root:LoadSPE_UI:WorkingWithZip
	if( WorkingWithZip )	
		zSPE2_ReFilterExpandedZip()
	else
		zSPE2_BuildFileList(0)
			
	endif

End

Function zSPE2_AVCheckBoxProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	NVAR Sweep_ChiFilter = root:LoadSPE_UI:Sweep_ChiFilter
	NVAR Value_ChiFilter = root:LoadSPE_UI:Value_ChiFilter
	NVAR xBox_DoUEX = root:LoadSPE_UI:xBox_DoUEX
	NVAR xBox_DoRES = root:LoadSPE_UI:xBox_DoRES
	NVAR xBox_ChiFilter = root:LoadSPE_UI:xBox_ChiFilter
	SVAR AverageOptionsStr = root:LoadSPE_UI:AverageOptionsStr
	String UEX_tok = "0"
	if( xBox_DoUEX )
		UEX_tok = "1"
	endif
	
	String RES_tok = "0"
	if( xBox_DoRES )
		RES_tok = "1"
	endif
	
	String CHIVal_tok = "0"
	String CHISwp_tok = "0"
	if( xBox_ChiFilter )
		sprintf CHIVal_tok, "%6.3e", Value_ChiFilter
		sprintf CHISwp_tok, "%d", Sweep_ChiFilter
	endif
	sprintf AverageOptionsStr, "UEX:%s;CHIVAL:%s;CHISWP:%s;DORES:%s;", UEX_tok, CHIVal_tok, CHISwp_tok, RES_tok
End

// LoadSPE_LBProc -- Function handles the act of clicking on various files in the list box
// if and only if the the browse panel variable is active, triggers a DXBrowse_LBLoad( path, file )
Function LoadSPE_LBProc( ctrl, row, col, event )
	String ctrl
	Variable row	// row if click in interior, -1 if click is in title
	Variable col 	// column number
	Variable event	// event code, which will be the first trap
	
	//printf "Ctrl:%s, row:%d, col:%d event%d\r", ctrl, row, col, event 


	if( (event == 4) )
		SVAR msg = root:loadSPE_UI:BrowseMSG
		String name = ks_zSPE2PanelName
		NVAR WorkingWithZip = root:LoadSPE_UI:WorkingWithZip
			
		Wave/D disp_time = root:LoadSPE_UI:disp_time
		Wave/T disp_fileList = root:LoadSPE_UI:disp_fileList
		Wave/T pack_fileList = root:LoadSPE_UI:pack_fileList
		Wave/T path_fileList = root:LoadSPE_UI:path_fileList
		Wave disp_SelWave = root:LoadSPE_UI:disp_SelWave
		
		String checked_file = disp_filelist[row]
		String packed_file = pack_filelist[row]
		String path_file = path_filelist[row]
		
		sprintf msg,  "P>%s in %s", packed_file, path_file	
		if( 1 )
			if( cmpstr( checked_file, "PickDirectory" ) == 0 )
				sprintf msg, "Need to select directory using the Browse Dir"
			else		
				//if( cmpstr( stringbykey( "ZIP", packed_file ), "xx" ) == 0 )
				// then the selected file is not a zip
				//	Button ao_ZipInZipOut win=$name, disable=2					
				//endif
				//if( cmpstr( stringbykey( "FILE", packed_file ), "xx" ) == 0 )
				// then the selected file isn't exactly ready for loading pre-deco
				//Button ao_ZipInZipOut win=$name, disable=0
				//endif		
				zSPE_SetZipInZipOutButton()		
			endif
		endif
		zSPE2_PowerBrowsePackedFile( packed_file, path_file )
	endif
	
	if( event== 5 )
		zSPE_SetZipInZipOutButton()
	endif
	if( 1 )
		
		
		
	endif
	return 0
End
Function zSPE2_PowerBrowsePackedFile( packed_file, path_file )
	String packed_file
	String path_file
	
	String fullFileToS1, fullFileToSPB, rootName
	String subFile_if
	
	Variable data_was_loaded = 0
	Variable result = 0
	SVAR msg = root:loadSPE_UI:LoadMSG

	Wave/T/Z destFrame = root:LoadSPE_UI:loadSPE_Frame
	if( WaveExists( destFrame ) != 1 )
		String saveFolder = GetDataFolder(1)
		SetDataFolder root:; MakeAndOrSetDF( "LoadSPE_UI" )
		Make/T/N=0/O LoadSPE_Frame
		SetDataFolder $saveFolder
		Wave/T destFrame = root:LoadSPE_UI:LoadSPE_Frame
	endif
	
	String zip_key = StringByKey( "ZIP", packed_file )
	String file_key = StringByKey( "FILE", packed_file )
	
	sprintf msg, "%s & %s", zip_key, file_key
	if( cmpstr( zip_key, "xx" ) == 0 )
		// we are dealing with a raw spe file
		//	fullFileToS1 = WindowsFullPath( path_file, StringByKey( "FILE", packed_file) )
		fullFileToS1 = path_file + StringByKey( "FILE", packed_file );
		if( fileexistsFullPath( fullFileToS1 ) == 0 )
			result = zSPE2_LoadTextToFrame( fullFileToS1, destFrame )
			if( result == 0 )
				data_was_loaded = 1
			else
				// odd error actually
			endif
		endif
	else
	
		if( cmpstr( file_key, "xx" ) == 0 )
			// we have a zip selected, but it can't be expanded yet...
		
		else
			// we have a zip archive and a sub file selected
			fullFileToS1 = WindowsFullPath( path_file, zip_key )
			if( fileexistsFullPath( fullFileToS1 ) == 0 )
				//printf "file: %s in %s to %s\r", file_key, fullFileToS1, GetWavesDataFolder( destFrame, 2 )
				
				// old method result = scx_DecompressFile2FrameFrmZip( file_key, fullFileToS1, destFrame )
				NewPath/Q/O QuickUzPath, path_file
				//scx5_File2FrameFromZip/Q/P=QuickUzPath zip_key, file_key, root:LoadSPE_UI:LoadSPE_Frame
				result = 0; 
				if( result == 0 )
					data_was_loaded = 1
				else
					data_was_loaded = 0
					// error msg
				endif
			endif
		endif
	endif
	
	sprintf msg, "%s - %d", msg, data_was_loaded
	if( data_was_loaded )
		SPE2_ProcFrameAsSPE( destFrame )
		// This would be a graceful onramp to loadding the attendant SPB ...
		//  
		rootName = StringFromList( 0, fullfiletos1, "." )
		sprintf fullFileToSPB, "%s.SPB", rootName;
		if( fileexistsFullPath( fullFileToSPB ) == 0 )
			//printf "SPB-> %s\r", fullFileToSPB
			sprintf msg, "%s - %d - SPB", msg, data_was_loaded
			GBLoadWave /B=1 /T={4,4} /N=BinLoad /Q fullFileToSPB
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
			saveFolder = GetDataFolder(1); SetDataFolder root:SPB_Folder
			SPB_ProduceAverageSpectrum( 0, DimSize(  SPB_Data_Spectrum_matrix, 0 )-1 )
			SetDataFolder $saveFolder
		endif
		//
		zSPE2_UpdateBrowseBits()
		zSPE2_UpdateSessionWaves(packed_file, path_file)
		//DoUpdate;
	endif
End
Function Time_SPB_SliderProc(sa) : SliderControl
	STRUCT WMSliderAction &sa

	switch( sa.eventCode )
		case -1: // control being killed
			break
		default:
			if( sa.eventCode & 1 ) // value set
				Variable curval = sa.curval

				DFREF SPBFolder = root:SPB_Folder
				
				Variable dfrStatus = DataFolderRefStatus(SPBFolder)

				if (dfrStatus == 0)
					// Print "Invalid data folder reference"
					print "No SPB files included with selected .SPE file"
					return -1
				endif
				
				// currently we need to duplicate these to our destination data folder and hook the index
				Wave SPB_Data_Spectrum_matrix = root:SPB_Folder:SPB_Data_Spectrum_matrix
				Wave SPB_TimeStamp_ms = root:SPB_Folder:SPB_TimeStamp_ms
				Wave SPB_TimeStamp = root:SPB_Folder:SPB_TimeStamp
				Wave SPB_TimeDuration = root:SPB_Folder:SPB_TimeDuration
				Wave SPB_Pressure = root:SPB_Folder:SPB_Pressure
				Wave SPB_Temperature = root:SPB_Folder:SPB_Temperature
				Wave SPB_PeakPosition = root:SPB_Folder:SPB_PeakPosition
				Wave SPB_Linewidth = root:SPB_Folder:SPB_Linewidth
				Wave average_spectrum = root:SPB_Folder:average_spectrum
				if( curval > DimSize(SPB_Data_Spectrum_matrix,0) )
					curval = 0
				endif
				Slider timeslider,limits={1,DimSize(SPB_Data_Spectrum_matrix,0),0}
			
				Make/D/N=(DimSize( SPB_Data_Spectrum_matrix, 1))/O new_data_wave, avg_subtracted
				new_data_wave = SPB_Data_Spectrum_matrix[ curval ][p];
				avg_subtracted = new_data_wave - average_spectrum 
				Wave/T LoadSPE_Frame = root:LoadSPE_UI:LoadSPE_Frame
				SPE2_InjectFiveColumns2Frame( new_data_wave, 1, LoadSPE_Frame )
				// Add P & T, Peak Pos etc here
				SPE2_InjectParamIntoFrame( "cell pressure", SPB_Pressure[ curval ], LoadSPE_Frame )
				SPE2_InjectParamIntoFrame( "cell temp", SPB_Temperature[ curval ], LoadSPE_Frame )
				SPE2_InjectParamIntoFrame( "peak position 1", SPB_PeakPosition[ curval ][0], LoadSPE_Frame )
				SPE2_InjectParamIntoFrame( "peak position 2", SPB_PeakPosition[ curval ][1], LoadSPE_Frame )
				SPE2_InjectParamIntoFrame( "peak position 3", SPB_PeakPosition[ curval ][2], LoadSPE_Frame )
				SPE2_InjectParamIntoFrame( "peak position 4", SPB_PeakPosition[ curval ][3], LoadSPE_Frame )
				
				String/G spb_TimeString
				sprintf spb_TimeString, "%s", DateTime2Text( SPB_TimeStamp[ curval ] );
				Wave now_w = root:LoadSPE_UI:SPB_NowBar; 
				SetScale/P x, SPB_TimeStamp[ curval ], 0.01, "dat", now_w; now_w = p;
				SPE2_ProcFrameAsSPE( LoadSPE_Frame );
				zSPE2_UpdateBrowseBits();
				//KillWaves/Z new_data_wave;
			endif
			break
	endswitch

	return 0
End
Function zSPE2_ConcatAndPrepSPB()
	// Scott and Tara, 2017 
	// adds capability for spe browser to load/Concatenate SPB and prepare for analysis
	// 
	// outline
	// capture listbox and build listing
	// load each into root:SPB_Folder
	// concatenate into root:SPB_Concatenated
	// copy out to root: and transpose
	
	Variable loc_verbose = 1; // turn this off to supress messages
	
	// ocean

	SVAR BrowseMSG = root:LoadSPE_UI:BrowseMSG
	SVAR LoadMSG = root:LoadSPE_UI:LoadMSG
	SVAR PlayListMSG = root:LoadSPE_UI:PlayListMSG

	Wave/D disp_time = root:LoadSPE_UI:disp_time
	Wave/T disp_fileList = root:LoadSPE_UI:disp_fileList
	Wave/T pack_fileList = root:LoadSPE_UI:pack_fileList
	Wave/T path_fileList = root:LoadSPE_UI:path_fileList
	Wave disp_SelWave = root:LoadSPE_UI:disp_SelWave
	
	Variable idex, jdex, count, jcount, time_val, dotNum
	String file, pfile, fpfilespe, fpfilespb, time_str, saveFolder
	
	count = numpnts( disp_SelWave );
	for( idex = 0; idex < count; idex += 1 )
		// capture listbox and build listing
		if( disp_SelWave[ idex ] )
			//			time_val = disp_time[ idex ];		time_str = DTI_DateTime2Text( time_val, "" );
			fpfilespe = path_fileList[ idex ] + StringByKey( "FILE", pack_fileList[ idex ] );
			dotNum = ItemsInList( fpfilespe, "." )
			fpfilespb = RemoveFromList( "spe", fpfilespe, "." );
			fpfilespb = fpfilespb + "spb"
			//			if( loc_verbose )
			//				printf "%s & %s\r", fpfilespe, fpfilespb
			//			endif
			// load each into root:SPB_Folder
			zSPE2_PowerBrowsePackedFile( pack_fileList[ idex ], path_fileList[ idex ] )
			
			DFREF SPBFolder = root:SPB_Folder
				
			Variable dfrStatus = DataFolderRefStatus(SPBFolder)

			if (dfrStatus == 0)
				// Print "Invalid data folder reference"
				print "No SPB files included with selected .SPE file"
				return -1
			endif
				
			Wave SPB_Data_Spectrum_matrix = root:SPB_Folder:SPB_Data_Spectrum_matrix
			Wave SPB_TimeStamp_ms = root:SPB_Folder:SPB_TimeStamp_ms
			Wave SPB_TimeStamp = root:SPB_Folder:SPB_TimeStamp
			Wave SPB_TimeDuration = root:SPB_Folder:SPB_TimeDuration
			Wave SPB_Pressure = root:SPB_Folder:SPB_Pressure
			Wave SPB_Temperature = root:SPB_Folder:SPB_Temperature
			Wave SPB_PeakPosition = root:SPB_Folder:SPB_PeakPosition
			Wave SPB_Linewidth = root:SPB_Folder:SPB_Linewidth
			Wave SPB_TuneRateScaleFactor = root:SPB_Folder:SPB_TuneRateScaleFactor
			Wave average_spectrum = root:SPB_Folder:average_spectrum
			// concatenate into root:SPB_Concatenated
			Wave/Z SPB_Data_Spectrum_matrix_cat = root:SPB_Concatenated:SPB_Data_Spectrum_matrix
			if( WaveExists( SPB_Data_Spectrum_matrix_cat ) != 1 )
				// interpret this as the first time
				saveFolder = GetDataFolder(1); 
				SetDataFolder root:; MakeAndOrSetDF( "SPB_Concatenated" );

				if( loc_verbose )
					printf "starting concatenation with -> %s\r", fpfilespb
				endif

				Duplicate/O  SPB_Data_Spectrum_matrix, root:SPB_Concatenated:SPB_Data_Spectrum_matrix
				Duplicate/O  SPB_TimeStamp_ms , root:SPB_Concatenated:SPB_TimeStamp_ms
				Duplicate/O  SPB_TimeStamp , root:SPB_Concatenated:SPB_TimeStamp
				Duplicate/O  SPB_TimeDuration , root:SPB_Concatenated:SPB_TimeDuration
				Duplicate/O  SPB_Pressure , root:SPB_Concatenated:SPB_Pressure
				Duplicate/O  SPB_Temperature , root:SPB_Concatenated:SPB_Temperature
				Duplicate/O  SPB_PeakPosition , root:SPB_Concatenated:SPB_PeakPosition
				Duplicate/O  SPB_Linewidth , root:SPB_Concatenated:SPB_Linewidth
				Duplicate/O  SPB_TuneRateScaleFactor, root:SPB_Concatenated:SPB_TuneRateScaleFactor
				SetDataFolder $saveFolder
			else
				// interpret this as a need to concatenate ...
				if( loc_verbose )
					printf "... continuing concatenation with -> %s\r", fpfilespb
				endif
				Wave SPB_Data_Spectrum_matrix_cat = root:SPB_Concatenated:SPB_Data_Spectrum_matrix
				Wave SPB_TimeStamp_ms_cat = root:SPB_Concatenated:SPB_TimeStamp_ms
				Wave SPB_TimeStamp_cat = root:SPB_Concatenated:SPB_TimeStamp
				Wave SPB_TimeDuration_cat = root:SPB_Concatenated:SPB_TimeDuration
				Wave SPB_Pressure_cat = root:SPB_Concatenated:SPB_Pressure
				Wave SPB_Temperature_cat = root:SPB_Concatenated:SPB_Temperature
				Wave SPB_PeakPosition_cat = root:SPB_Concatenated:SPB_PeakPosition
				Wave SPB_Linewidth_cat = root:SPB_Concatenated:SPB_Linewidth
				Wave SPB_TuneRateScaleFactor_cat = root:SPB_Concatenated:SPB_TuneRateScaleFactor

				Concatenate/NP=0 {SPB_Data_Spectrum_matrix}, SPB_Data_Spectrum_matrix_cat
				Concatenate/NP=0 {SPB_TimeStamp}, SPB_TimeStamp_cat
				Concatenate/NP=0 {SPB_TimeStamp_ms}, SPB_TimeStamp_ms_cat
				Concatenate/NP=0 {SPB_TimeDuration}, SPB_TimeDuration_cat
				Concatenate/NP=0 {SPB_Pressure}, SPB_Pressure_cat
				Concatenate/NP=0 {SPB_Temperature}, SPB_Temperature_cat
				Concatenate/NP=0 {SPB_PeakPosition}, SPB_PeakPosition_cat
				Concatenate/NP=0 {SPB_Linewidth}, SPB_Linewidth_cat
				Concatenate/NP=0 {SPB_TuneRateScaleFactor}, SPB_TuneRateScaleFactor_cat
				
			endif
		endif		// end this_dispSelwave != 0
	endfor

	// Redefine waves.
	Wave SPB_Data_Spectrum_matrix_cat = root:SPB_Concatenated:SPB_Data_Spectrum_matrix
	Wave SPB_TimeStamp_ms_cat = root:SPB_Concatenated:SPB_TimeStamp_ms
	Wave SPB_TimeStamp_cat = root:SPB_Concatenated:SPB_TimeStamp
	Wave SPB_TimeDuration_cat = root:SPB_Concatenated:SPB_TimeDuration
	Wave SPB_Pressure_cat = root:SPB_Concatenated:SPB_Pressure
	Wave SPB_Temperature_cat = root:SPB_Concatenated:SPB_Temperature
	Wave SPB_PeakPosition_cat = root:SPB_Concatenated:SPB_PeakPosition
	Wave SPB_Linewidth_cat = root:SPB_Concatenated:SPB_Linewidth
	Wave SPB_TuneRateScaleFactor_cat = root:SPB_Concatenated:SPB_TuneRateScaleFactor

	// copy out to root: and transpose
	// copy out to root: and transpose

	Duplicate/O SPB_TimeStamp_cat, root:L0_time  // yes, this is inconsistent nomenclature...
	Duplicate/O SPB_Pressure_cat, root:L0_pressure
	Duplicate/O SPB_Temperature_cat, root:L0_temp
	Duplicate/O SPB_TuneRateScaleFactor_cat, root:SPB_TuneRateScaleFactor
	
	variable r=0
	for(r=0; r<dimsize(SPB_peakPosition_cat,1); r+=1)
		make/n=(dimsize(SPB_peakPosition_cat,0))/O $("root:L0_peakPos_"+num2str(r+1))
		wave rootpeakPos = $("root:L0_peakPos_"+num2str(r+1))
		rootpeakPos = SPB_peakPosition_cat[p][r]
	endfor
	Duplicate/O SPB_Data_Spectrum_matrix_cat, root:Spectrum // Keeping with Barry's defaults for root:
	// L0_freq is computed elsewhere
	
	Wave w = root:Spectrum
	MatrixTranspose w
		
	// This is where other waves should/could be collected into root if needed.
	// what about tuning rate? For now, use last-calculated tuning rate, in root:
		
	//KillDataFolder /Z root:SPB_Concatenated
	//Killwaves/z root:freqScale_w	
End
Function MatrixConcatenate()

End
Window TransmissionAndSignal_wb1x() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:LoadSPE_II:
	Display /W=(541,45,1206,359)/K=1 /L=trans_ax wb1_trans_spectrum,wb1_trans_fit,wb1_trans_spectrum vs wb1_frequency as "TransmissionAndSignal_wb1x"
	AppendToGraph/L=sig_ax wb1_spectrum,wb1_wintel_fit,wb1_wintel_base,wb1_spectrum vs wb1_frequency
	SetDataFolder fldrSav0
	ModifyGraph margin(left)=72
	ModifyGraph mode(wb1_trans_spectrum)=3,mode(wb1_trans_spectrum#1)=3,mode(wb1_spectrum)=3
	ModifyGraph mode(wb1_spectrum#1)=3
	ModifyGraph marker(wb1_trans_spectrum)=18,marker(wb1_trans_spectrum#1)=18,marker(wb1_spectrum)=18
	ModifyGraph marker(wb1_spectrum#1)=18
	ModifyGraph rgb(wb1_trans_spectrum)=(26112,52224,0),rgb(wb1_trans_fit)=(0,12800,52224)
	ModifyGraph rgb(wb1_trans_spectrum#1)=(65280,65280,0),rgb(wb1_spectrum)=(26112,52224,0)
	ModifyGraph rgb(wb1_wintel_fit)=(0,12800,52224),rgb(wb1_wintel_base)=(0,12800,52224)
	ModifyGraph rgb(wb1_spectrum#1)=(65280,65280,0)
	ModifyGraph msize(wb1_trans_spectrum#1)=5,msize(wb1_spectrum#1)=5
	ModifyGraph zmrkNum(wb1_trans_spectrum#1)={:LoadSPE_II:wb1_igr_cur},zmrkNum(wb1_spectrum#1)={:LoadSPE_II:wb1_igr_cur}
	ModifyGraph grid=2
	ModifyGraph tick=2
	ModifyGraph mirror=2
	ModifyGraph minor(bottom)=1
	ModifyGraph standoff=0
	ModifyGraph gridRGB(trans_ax)=(16384,28160,65280),gridRGB(sig_ax)=(13056,26112,0)
	ModifyGraph axRGB(trans_ax)=(16384,28160,65280),axRGB(sig_ax)=(13056,26112,0)
	ModifyGraph tlblRGB(trans_ax)=(16384,28160,65280),tlblRGB(sig_ax)=(13056,26112,0)
	ModifyGraph alblRGB(trans_ax)=(16384,28160,65280),alblRGB(sig_ax)=(13056,26112,0)
	ModifyGraph lblPos(trans_ax)=35,lblPos(sig_ax)=40
	ModifyGraph lblLatPos(trans_ax)=-20,lblLatPos(sig_ax)=-10
	ModifyGraph freePos(trans_ax)={0,bottom}
	ModifyGraph freePos(sig_ax)={0,bottom}
	ModifyGraph axisEnab(trans_ax)={0.52,1}
	ModifyGraph axisEnab(sig_ax)={0,0.48}
	Label bottom "Frequency (cm\\S-1\\M)"
	Label trans_ax "Transmission"
	Label sig_ax "Signal (mV)"
	SetAxis bottom 2831.62882430196,2832.17825282064
	SetAxis/N=1 trans_ax 0.976374193949089,1.00014653774295
	SetAxis/N=1 sig_ax 975.64013517,999.45137861
	ShowInfo
	ShowTools/A
	ControlBar 22
	Button tog_left,pos={5.00,0.00},size={55.00,22.00},proc=UsefulButtons,title="<pan left<"
	Button tog_right,pos={60.00,0.00},size={55.00,22.00},proc=UsefulButtons,title=">pan right>"
	Button widen,pos={115.00,0.00},size={55.00,22.00},proc=UsefulButtons,title="<widen>"
	Button scale_y,pos={170.00,0.00},size={55.00,22.00},proc=UsefulButtons,title="Scale Y"
	Button removeHGB,pos={235.00,0.00},size={65.00,22.00},proc=UsefulButtons,title="Remove"
	Button removeHGB,valueColor=(65535,0,0)
	Slider trans_sig_slide,pos={229.00,3.00},size={100.00,17.00},proc=zSPE2_TransAndSlideProc
	Slider trans_sig_slide,limits={0,1,0.05},value= 0.5,vert= 0,ticks= 0
	Slider timeslider,pos={325.00,5.00},size={300.00,45.00},proc=Time_SPB_SliderProc
	Slider timeslider,limits={0,60,0},value= 31.5679442508711,vert= 0
EndMacro

Function zSPE2_UpdateBrowseBits()

	// This function thieves what it will from the LoadSPE_II directory into the 'display values' over in LoadSPE_UI

	
	NVAR  SPE_version = root:LoadSPE_II:SPE_version
	NVAR  SPE_FieldNumber = root:LoadSPE_II:SPE_FieldNumber
	
	NVAR  SPE_Total_data_points = root:LoadSPE_II:SPE_Total_data_points
	NVAR  SPE_SWP1_points = root:LoadSPE_II:SPE_SWP1_points
	NVAR  SPE_SWP2_points = root:LoadSPE_II:SPE_SWP2_points
	NVAR  SPE_SWP3_points = root:LoadSPE_II:SPE_SWP3_points
	NVAR  SPE_SWP4_points = root:LoadSPE_II:SPE_SWP4_points

	NVAR  SPE_FreqResolAtPrimaryF_sw1 = root:LoadSPE_II:SPE_FreqResolAtPrimaryF_sw1
	NVAR  SPE_FreqResolAtPrimaryF_sw2 = root:LoadSPE_II:SPE_FreqResolAtPrimaryF_sw2
	NVAR  SPE_FreqResolAtPrimaryF_sw3 = root:LoadSPE_II:SPE_FreqResolAtPrimaryF_sw3
	NVAR  SPE_FreqResolAtPrimaryF_sw4 = root:LoadSPE_II:SPE_FreqResolAtPrimaryF_sw4	

	NVAR  SPE_Channels_in_Off = root:LoadSPE_II:SPE_Channels_in_Off
	
	NVAR  SPE_CellResponse = root:LoadSPE_II:SPE_CellResponse
	NVAR  SPE_CellPressure = root:LoadSPE_II:SPE_CellPressure
	NVAR  SPE_CellTemperature = root:LoadSPE_II:SPE_CellTemperature
	NVAR  SPE_PathLength = root:LoadSPE_II:SPE_PathLength
	NVAR  SPE_MenuPower = root:LoadSPE_II:SPE_MenuPower
	
	NVAR  SPE_Linewidth1 = root:LoadSPE_II:SPE_Linewidth1
	NVAR  SPE_Linewidth2 = root:LoadSPE_II:SPE_Linewidth2
	NVAR  SPE_Linewidth3 = root:LoadSPE_II:SPE_Linewidth3
	NVAR  SPE_Linewidth4 = root:LoadSPE_II:SPE_Linewidth4
	
	NVAR  SPE_Polynomial = root:LoadSPE_II:SPE_Polynomial
	

	NVAR  SPE_PeakPos1 = root:LoadSPE_II:SPE_PeakPos1
	NVAR  SPE_PeakFixed1 = root:LoadSPE_II:SPE_PeakFixed1
	NVAR  SPE_MixRatio1 = root:LoadSPE_II:SPE_MixRatio1
	NVAR  SPE_Fingerprint1 = root:LoadSPE_II:SPE_Fingerprint1
	SVAR  SPE_HitFile1 = root:LoadSPE_II:SPE_HitFile1
	NVAR  SPE_HitFile1_Found = root:LoadSPE_II:SPE_HitFile1_Found
	NVAR  SPE_HitFile1_Loaded = root:LoadSPE_II:SPE_HitFile1_Loaded
	NVAR  SPE_FreqBand4Spec1 = root:LoadSPE_II:SPE_FreqBand4Spec1
	
	NVAR  SPE_PeakPos2 = root:LoadSPE_II:SPE_PeakPos2;	NVAR  SPE_PeakFixed2 = root:LoadSPE_II:SPE_PeakFixed2; NVAR  SPE_MixRatio2 = root:LoadSPE_II:SPE_MixRatio2; 
	NVAR  SPE_Fingerprint2 = root:LoadSPE_II:SPE_Fingerprint2;	SVAR  SPE_HitFile2 = root:LoadSPE_II:SPE_HitFile2; NVAR  SPE_HitFile2_Found = root:LoadSPE_II:SPE_HitFile2_Found; NVAR  SPE_HitFile2_Loaded = root:LoadSPE_II:SPE_HitFile2_Loaded; NVAR  SPE_FreqBand4Spec2 = root:LoadSPE_II:SPE_FreqBand4Spec2
		
	NVAR  SPE_PeakPos3 = root:LoadSPE_II:SPE_PeakPos3;	NVAR  SPE_PeakFixed3 = root:LoadSPE_II:SPE_PeakFixed3; NVAR  SPE_MixRatio3 = root:LoadSPE_II:SPE_MixRatio3; 
	NVAR  SPE_Fingerprint3 = root:LoadSPE_II:SPE_Fingerprint3;	SVAR  SPE_HitFile3 = root:LoadSPE_II:SPE_HitFile3; NVAR  SPE_HitFile3_Found = root:LoadSPE_II:SPE_HitFile3_Found; NVAR  SPE_HitFile3_Loaded = root:LoadSPE_II:SPE_HitFile3_Loaded; NVAR  SPE_FreqBand4Spec3 = root:LoadSPE_II:SPE_FreqBand4Spec3

	NVAR  SPE_PeakPos4 = root:LoadSPE_II:SPE_PeakPos4;	NVAR  SPE_PeakFixed4 = root:LoadSPE_II:SPE_PeakFixed4; NVAR  SPE_MixRatio4 = root:LoadSPE_II:SPE_MixRatio4; 
	NVAR  SPE_Fingerprint4 = root:LoadSPE_II:SPE_Fingerprint4;	SVAR  SPE_HitFile4 = root:LoadSPE_II:SPE_HitFile4; NVAR  SPE_HitFile4_Found = root:LoadSPE_II:SPE_HitFile4_Found; NVAR  SPE_HitFile4_Loaded = root:LoadSPE_II:SPE_HitFile4_Loaded; NVAR  SPE_FreqBand4Spec4 = root:LoadSPE_II:SPE_FreqBand4Spec4

	NVAR  SPE_PeakPos5 = root:LoadSPE_II:SPE_PeakPos5;	NVAR  SPE_PeakFixed5 = root:LoadSPE_II:SPE_PeakFixed5; NVAR  SPE_MixRatio5 = root:LoadSPE_II:SPE_MixRatio5; 
	NVAR  SPE_Fingerprint5 = root:LoadSPE_II:SPE_Fingerprint5;	SVAR  SPE_HitFile5 = root:LoadSPE_II:SPE_HitFile5; NVAR  SPE_HitFile5_Found = root:LoadSPE_II:SPE_HitFile5_Found; NVAR  SPE_HitFile5_Loaded = root:LoadSPE_II:SPE_HitFile5_Loaded; NVAR  SPE_FreqBand4Spec5 = root:LoadSPE_II:SPE_FreqBand4Spec5

	NVAR  SPE_PeakPos6 = root:LoadSPE_II:SPE_PeakPos6;	NVAR  SPE_PeakFixed6 = root:LoadSPE_II:SPE_PeakFixed6; NVAR  SPE_MixRatio6 = root:LoadSPE_II:SPE_MixRatio6; 
	NVAR  SPE_Fingerprint6 = root:LoadSPE_II:SPE_Fingerprint6;	SVAR  SPE_HitFile6 = root:LoadSPE_II:SPE_HitFile6; NVAR  SPE_HitFile6_Found = root:LoadSPE_II:SPE_HitFile6_Found; NVAR  SPE_HitFile6_Loaded = root:LoadSPE_II:SPE_HitFile6_Loaded; NVAR  SPE_FreqBand4Spec6 = root:LoadSPE_II:SPE_FreqBand4Spec6

	NVAR  SPE_PeakPos7 = root:LoadSPE_II:SPE_PeakPos7;	NVAR  SPE_PeakFixed7 = root:LoadSPE_II:SPE_PeakFixed7; NVAR  SPE_MixRatio7 = root:LoadSPE_II:SPE_MixRatio7; 
	NVAR  SPE_Fingerprint7 = root:LoadSPE_II:SPE_Fingerprint7;	SVAR  SPE_HitFile7 = root:LoadSPE_II:SPE_HitFile7; NVAR  SPE_HitFile7_Found = root:LoadSPE_II:SPE_HitFile7_Found; NVAR  SPE_HitFile7_Loaded = root:LoadSPE_II:SPE_HitFile7_Loaded; NVAR  SPE_FreqBand4Spec7 = root:LoadSPE_II:SPE_FreqBand4Spec7

	NVAR  SPE_PeakPos8 = root:LoadSPE_II:SPE_PeakPos8;	NVAR  SPE_PeakFixed8 = root:LoadSPE_II:SPE_PeakFixed8; NVAR  SPE_MixRatio8 = root:LoadSPE_II:SPE_MixRatio8; 
	NVAR  SPE_Fingerprint8 = root:LoadSPE_II:SPE_Fingerprint8;	SVAR  SPE_HitFile8 = root:LoadSPE_II:SPE_HitFile8; NVAR  SPE_HitFile8_Found = root:LoadSPE_II:SPE_HitFile8_Found; NVAR  SPE_HitFile8_Loaded = root:LoadSPE_II:SPE_HitFile8_Loaded; NVAR  SPE_FreqBand4Spec8 = root:LoadSPE_II:SPE_FreqBand4Spec8

	NVAR  SPE_timestamp = root:LoadSPE_II:SPE_timestamp;
	SVAR  SPE_time_date = root:LoadSPE_II:SPE_time_date;
	NVAR  SPE_ContinuousRefLok = root:LoadSPE_II:SPE_ContinuousRefLok;

	Wave/D FrameColumn_1 = root:LoadSPE_II:FrameColumn_1
	Wave/D FrameColumn_2 = root:LoadSPE_II:FrameColumn_2
	Wave/D FrameColumn_3 = root:LoadSPE_II:FrameColumn_3
	Wave/D FrameColumn_4 = root:LoadSPE_II:FrameColumn_4
	Wave/D FrameColumn_5 = root:LoadSPE_II:FrameColumn_5
	Wave/D FrameColumn_6 = root:LoadSPE_II:FrameColumn_6

	Wave/D wb1_igr_cur = root:LoadSPE_II:wb1_igr_cur
	Wave/D wb1_wintel_cur = root:LoadSPE_II:wb1_wintel_cur
	Wave/D wb1_trans_fit = root:LoadSPE_II:wb1_trans_fit
	Wave/D wb1_trans_spectrum = root:LoadSPE_II:wb1_trans_spectrum
	Wave/D wb1_wintel_fit = root:LoadSPE_II:wb1_wintel_fit
	Wave/D wb1_wintel_base = root:LoadSPE_II:wb1_wintel_base
	Wave/D wb1_spectrum = root:LoadSPE_II:wb1_spectrum
	Wave/D wb1_frequency = root:LoadSPE_II:wb1_frequency
	Wave/T params_tw = root:LoadSPE_II:params_tw	
	Wave/T header_tw = root:LoadSPE_II:header_tw	

	Wave/D wb2_igr_cur = root:LoadSPE_II:wb2_igr_cur;	Wave/D wb2_wintel_cur = root:LoadSPE_II:wb2_wintel_cur; 	Wave/D wb2_trans_fit = root:LoadSPE_II:wb2_trans_fit;	Wave/D wb2_trans_spectrum = root:LoadSPE_II:wb2_trans_spectrum
	Wave/D wb2_wintel_fit = root:LoadSPE_II:wb2_wintel_fit;	Wave/D wb2_wintel_base = root:LoadSPE_II:wb2_wintel_base
	Wave/D wb2_spectrum = root:LoadSPE_II:wb2_spectrum;	Wave/D wb2_frequency = root:LoadSPE_II:wb2_frequency;

	Wave/D wb3_igr_cur = root:LoadSPE_II:wb3_igr_cur;	Wave/D wb3_wintel_cur = root:LoadSPE_II:wb3_wintel_cur; 	Wave/D wb3_trans_fit = root:LoadSPE_II:wb3_trans_fit;	Wave/D wb3_trans_spectrum = root:LoadSPE_II:wb3_trans_spectrum
	Wave/D wb3_wintel_fit = root:LoadSPE_II:wb3_wintel_fit;	Wave/D wb3_wintel_base = root:LoadSPE_II:wb3_wintel_base
	Wave/D wb3_spectrum = root:LoadSPE_II:wb3_spectrum;	Wave/D wb3_frequency = root:LoadSPE_II:wb3_frequency;

	Wave/D wb4_igr_cur = root:LoadSPE_II:wb4_igr_cur;	Wave/D wb4_wintel_cur = root:LoadSPE_II:wb4_wintel_cur; 	Wave/D wb4_trans_fit = root:LoadSPE_II:wb4_trans_fit;	Wave/D wb4_trans_spectrum = root:LoadSPE_II:wb4_trans_spectrum
	Wave/D wb4_wintel_fit = root:LoadSPE_II:wb4_wintel_fit;	Wave/D wb4_wintel_base = root:LoadSPE_II:wb4_wintel_base
	Wave/D wb4_spectrum = root:LoadSPE_II:wb4_spectrum;	Wave/D wb4_frequency = root:LoadSPE_II:wb4_frequency;

	Wave/D spec_laser_off = root:LoadSPE_II:spec_laser_off
	/////////////////////////////////// Those were the ii refs, lets get the ui refs
	NVAR WorkingWithZip = root:LoadSPE_UI:WorkingWithZip
	NVAR xBox_IncludeZip = root:LoadSPE_UI:xBox_IncludeZip
	NVAR xBox_IncludeSPE = root:LoadSPE_UI:xBox_IncludeSPE
	NVAR xBox_BlockBK = root:LoadSPE_UI:xBox_BlockBK
	NVAR xBox_BlockRef = root:LoadSPE_UI:xBox_BlockRef
	NVAR xBox_BlockPN = root:LoadSPE_UI:xBox_BlockPN
	NVAR xBox_BlockRaw = root:LoadSPE_UI:xBox_BlockRaw
	NVAR xBox_BlockCal = root:LoadSPE_UI:xBox_BlockCal
	NVAR xBox_BlockWild = root:LoadSPE_UI:xBox_BlockWild
	NVAR Roll_SpeciesNumber = root:LoadSPE_UI:Roll_SpeciesNumber
	NVAR xBox_DoUpdate = root:LoadSPE_UI:xBox_DoUpdate
	NVAR Mix_a = root:LoadSPE_UI:Mix_a
	NVAR Mix_b = root:LoadSPE_UI:Mix_b
	NVAR Pos_a = root:LoadSPE_UI:Pos_a
	NVAR Pos_b = root:LoadSPE_UI:Pos_b
	NVAR Fingerprint_a = root:LoadSPE_UI:Fingerprint_a
	NVAR Fingerprint_b = root:LoadSPE_UI:Fingerprint_b
	NVAR CellTemperature = root:LoadSPE_UI:CellTemperature
	NVAR CellPressure = root:LoadSPE_UI:CellPressure
	NVAR PathLength = root:LoadSPE_UI:PathLength
	NVAR CellResponse = root:LoadSPE_UI:CellResponse
	NVAR Laser1Power = root:LoadSPE_UI:Laser1Power
	NVAR Laser2Power = root:LoadSPE_UI:Laser2Power
	NVAR Laser3Power = root:LoadSPE_UI:Laser3Power
	NVAR Laser4Power = root:LoadSPE_UI:Laser4Power
	SVAR Path2Files = root:LoadSPE_UI:Path2Files
	SVAR HitFile_a = root:LoadSPE_UI:HitFile_a
	SVAR HitFile_b = root:LoadSPE_UI:HitFile_b
	SVAR HitFile_JFa = root:LoadSPE_UI:HitFile_JFa
	SVAR HitFile_JFb = root:LoadSPE_UI:HitFile_JFb
	SVAR TimeStampTime = root:LoadSPE_UI:TimeStampTime
	SVAR FileTimeTime = root:LoadSPE_UI:FileTimeTime
	SVAR BrowseMSG = root:LoadSPE_UI:BrowseMSG
	SVAR LoadMSG = root:LoadSPE_UI:LoadMSG
	SVAR PlayListMSG = root:LoadSPE_UI:PlayListMSG

	if( (Roll_SpeciesNumber <= 0 ) | (Roll_SpeciesNumber > 8 ))
		Roll_SpeciesNumber = 1
	endif
	
	NVAR  SPE_PeakPosX = $("root:LoadSPE_II:SPE_PeakPos"+num2str(Roll_SpeciesNumber));
	NVAR  SPE_PeakFixedX = $("root:LoadSPE_II:SPE_PeakFixed"+num2str(Roll_SpeciesNumber));
	NVAR  SPE_MixRatioX = $("root:LoadSPE_II:SPE_MixRatio"+num2str(Roll_SpeciesNumber)); 
	NVAR  SPE_FingerprintX = $("root:LoadSPE_II:SPE_Fingerprint"+num2str(Roll_SpeciesNumber));
	SVAR  SPE_HitFileX = $("root:LoadSPE_II:SPE_HitFile"+num2str(Roll_SpeciesNumber));
	NVAR  SPE_FreqBand4SpecX = $("root:LoadSPE_II:SPE_FreqBand4Spec"+num2str(Roll_SpeciesNumber));
	
	HitFile_a = SPE_HitFileX
	HitFile_JFa = zSPE2_JustFileFromFull( HitFile_a )
	if( SPE_PeakFixedX )
		Pos_a = -1 * SPE_PeakPosX
	else
		Pos_a = SPE_PeakPosX
	endif
	Mix_a = SPE_MixRatioX
	Fingerprint_a = SPE_FingerprintX
	
	//	TimeStampTime = DateTime2Text( SPE_timestamp )
	sprintf TimeStampTime, "%s (%5.4f)", DateTime2Text( SPE_timestamp ), SPE_timestamp - Text2DateTime( DateTime2Text( SPE_timestamp))

	Variable Roll_SpeciesNumber_b = Roll_SpeciesNumber + 1
	if( Roll_SpeciesNumber_b > 8 )
		Roll_SpeciesNumber_b =1
	endif
	if( Roll_SpeciesNumber_b < 1 )
		Roll_SpeciesNumber_b = 8
	endif
	
	NVAR  SPE_PeakPosX = $("root:LoadSPE_II:SPE_PeakPos"+num2str(Roll_SpeciesNumber_b));
	NVAR  SPE_PeakFixedX = $("root:LoadSPE_II:SPE_PeakFixed"+num2str(Roll_SpeciesNumber_b));
	NVAR  SPE_MixRatioX = $("root:LoadSPE_II:SPE_MixRatio"+num2str(Roll_SpeciesNumber_b)); 
	NVAR  SPE_FingerprintX = $("root:LoadSPE_II:SPE_Fingerprint"+num2str(Roll_SpeciesNumber_b));
	SVAR  SPE_HitFileX = $("root:LoadSPE_II:SPE_HitFile"+num2str(Roll_SpeciesNumber_b));
	NVAR  SPE_FreqBand4SpecX = $("root:LoadSPE_II:SPE_FreqBand4Spec"+num2str(Roll_SpeciesNumber_b));
	
	HitFile_b = SPE_HitFileX
	HitFile_JFb = zSPE2_JustFileFromFull( HitFile_b )
	if( SPE_PeakFixedX )
		Pos_b = -1 * SPE_PeakPosX
	else
		Pos_b = SPE_PeakPosX
	endif
	Mix_b = SPE_MixRatioX
	Fingerprint_b = SPE_FingerprintX

	CellTemperature = SPE_CellTemperature
	CellPressure = SPE_CellPressure
	PathLength = SPE_Pathlength
	CellResponse = SPE_CellResponse		

	String sn_title = zSPE2_GetSNButtonTitle( Roll_SpeciesNumber )
	Button br_increSN_but,win=$ks_zSPE2PanelName,  title = sn_title

	
End
Function/T zSPE2_GetSNButtonTitle( Roll)
	Variable Roll
	string sn_title = "whoops"
	
	Variable second_roll = roll + 1
	if( second_roll == 9 )
		second_roll = 1
	endif
	sprintf sn_title, "Species %d >>       Species %d >>", roll, second_roll

	return sn_title
End
Function/T zSPE2_JustFileFromFull( sourceFP )
	String sourceFP
	String destJF = sourceFP

	Variable sourceLen = strlen( sourceFP )
	Variable dot_dex = strsearch( sourceFP, ".", 1 )
	
	Variable idex = dot_dex
	Variable first_slash = 0
	do
		if( (cmpstr( sourceFP[idex], "\\") == 0 ) | ( cmpstr( sourceFP[idex], ":" ) == 0 ) )
			first_slash = idex;
			idex = 0;
		endif
		idex -= 1
	while( idex > 0 )
	
	destJF = sourceFP[ first_slash + 1, dot_dex-1 ]
	return destJF
End

Function zSPE2_LoadTextToFrame( filefp, dest_tw )
	String filefp
	Wave/T dest_tw
	
	Variable result = 0, refNum
	String line, term
	Open/R refNum as filefp
	if( refNum != 0 )
		Redimension/N=0 dest_tw
		do
			freadline refnum, line
			if( strlen( line ) < 1 )
				break;
			endif
			line = line[0, strlen(line) - 2 ]
			term = line[strlen(line)-1]
			if( (cmpstr( term, num2char(13)) == 0 ) | (cmpstr(term, num2char(10)) == 0 ) )
				line = line[0, strlen(line) - 2]
			endif
			//printf "%s\r", line
			AppendString( dest_tw, line )
		while( 1 )
		Close refNum
	else
		result = -1
	endif
	return result
End

Function zSPE2_UpdateSessionWaves(packed_file, path)
	String packed_file, path

	
	NVAR  SPE_version = root:LoadSPE_II:SPE_version
	NVAR  SPE_FieldNumber = root:LoadSPE_II:SPE_FieldNumber
	
	NVAR  SPE_Total_data_points = root:LoadSPE_II:SPE_Total_data_points
	NVAR  SPE_SWP1_points = root:LoadSPE_II:SPE_SWP1_points
	NVAR  SPE_SWP2_points = root:LoadSPE_II:SPE_SWP2_points
	NVAR  SPE_SWP3_points = root:LoadSPE_II:SPE_SWP3_points
	NVAR  SPE_SWP4_points = root:LoadSPE_II:SPE_SWP4_points

	NVAR  SPE_FreqResolAtPrimaryF_sw1 = root:LoadSPE_II:SPE_FreqResolAtPrimaryF_sw1
	NVAR  SPE_FreqResolAtPrimaryF_sw2 = root:LoadSPE_II:SPE_FreqResolAtPrimaryF_sw2
	NVAR  SPE_FreqResolAtPrimaryF_sw3 = root:LoadSPE_II:SPE_FreqResolAtPrimaryF_sw3
	NVAR  SPE_FreqResolAtPrimaryF_sw4 = root:LoadSPE_II:SPE_FreqResolAtPrimaryF_sw4	

	NVAR  SPE_Channels_in_Off = root:LoadSPE_II:SPE_Channels_in_Off
	
	NVAR  SPE_CellResponse = root:LoadSPE_II:SPE_CellResponse
	NVAR  SPE_CellPressure = root:LoadSPE_II:SPE_CellPressure
	NVAR  SPE_CellTemperature = root:LoadSPE_II:SPE_CellTemperature
	NVAR  SPE_PathLength = root:LoadSPE_II:SPE_PathLength
	NVAR  SPE_MenuPower = root:LoadSPE_II:SPE_MenuPower
	
	
	NVAR  SPE_Linewidth1 = root:LoadSPE_II:SPE_Linewidth1
	NVAR  SPE_Linewidth2 = root:LoadSPE_II:SPE_Linewidth2
	NVAR  SPE_Linewidth3 = root:LoadSPE_II:SPE_Linewidth3
	NVAR  SPE_Linewidth4 = root:LoadSPE_II:SPE_Linewidth4
	
	NVAR  SPE_LaserPower_1 = root:LoadSPE_II:SPE_LaserPower_1
	NVAR  SPE_LaserPower_2 = root:LoadSPE_II:SPE_LaserPower_2
	NVAR  SPE_LaserPower_3 = root:LoadSPE_II:SPE_LaserPower_3
	NVAR  SPE_LaserPower_4 = root:LoadSPE_II:SPE_LaserPower_4
	
	NVAR  SPE_Polynomial = root:LoadSPE_II:SPE_Polynomial


	NVAR  SPE_PeakPos1 = root:LoadSPE_II:SPE_PeakPos1
	NVAR  SPE_PeakFixed1 = root:LoadSPE_II:SPE_PeakFixed1
	NVAR  SPE_MixRatio1 = root:LoadSPE_II:SPE_MixRatio1
	NVAR  SPE_Fingerprint1 = root:LoadSPE_II:SPE_Fingerprint1
	SVAR  SPE_HitFile1 = root:LoadSPE_II:SPE_HitFile1
	NVAR  SPE_HitFile1_Found = root:LoadSPE_II:SPE_HitFile1_Found
	NVAR  SPE_HitFile1_Loaded = root:LoadSPE_II:SPE_HitFile1_Loaded
	NVAR  SPE_FreqBand4Spec1 = root:LoadSPE_II:SPE_FreqBand4Spec1
	
	NVAR  SPE_PeakPos2 = root:LoadSPE_II:SPE_PeakPos2;	NVAR  SPE_PeakFixed2 = root:LoadSPE_II:SPE_PeakFixed2; NVAR  SPE_MixRatio2 = root:LoadSPE_II:SPE_MixRatio2; 
	NVAR  SPE_Fingerprint2 = root:LoadSPE_II:SPE_Fingerprint2;	SVAR  SPE_HitFile2 = root:LoadSPE_II:SPE_HitFile2; NVAR  SPE_HitFile2_Found = root:LoadSPE_II:SPE_HitFile2_Found; NVAR  SPE_HitFile2_Loaded = root:LoadSPE_II:SPE_HitFile2_Loaded; NVAR  SPE_FreqBand4Spec2 = root:LoadSPE_II:SPE_FreqBand4Spec2
		
	NVAR  SPE_PeakPos3 = root:LoadSPE_II:SPE_PeakPos3;	NVAR  SPE_PeakFixed3 = root:LoadSPE_II:SPE_PeakFixed3; NVAR  SPE_MixRatio3 = root:LoadSPE_II:SPE_MixRatio3; 
	NVAR  SPE_Fingerprint3 = root:LoadSPE_II:SPE_Fingerprint3;	SVAR  SPE_HitFile3 = root:LoadSPE_II:SPE_HitFile3; NVAR  SPE_HitFile3_Found = root:LoadSPE_II:SPE_HitFile3_Found; NVAR  SPE_HitFile3_Loaded = root:LoadSPE_II:SPE_HitFile3_Loaded; NVAR  SPE_FreqBand4Spec3 = root:LoadSPE_II:SPE_FreqBand4Spec3

	NVAR  SPE_PeakPos4 = root:LoadSPE_II:SPE_PeakPos4;	NVAR  SPE_PeakFixed4 = root:LoadSPE_II:SPE_PeakFixed4; NVAR  SPE_MixRatio4 = root:LoadSPE_II:SPE_MixRatio4; 
	NVAR  SPE_Fingerprint4 = root:LoadSPE_II:SPE_Fingerprint4;	SVAR  SPE_HitFile4 = root:LoadSPE_II:SPE_HitFile4; NVAR  SPE_HitFile4_Found = root:LoadSPE_II:SPE_HitFile4_Found; NVAR  SPE_HitFile4_Loaded = root:LoadSPE_II:SPE_HitFile4_Loaded; NVAR  SPE_FreqBand4Spec4 = root:LoadSPE_II:SPE_FreqBand4Spec4

	NVAR  SPE_PeakPos5 = root:LoadSPE_II:SPE_PeakPos5;	NVAR  SPE_PeakFixed5 = root:LoadSPE_II:SPE_PeakFixed5; NVAR  SPE_MixRatio5 = root:LoadSPE_II:SPE_MixRatio5; 
	NVAR  SPE_Fingerprint5 = root:LoadSPE_II:SPE_Fingerprint5;	SVAR  SPE_HitFile5 = root:LoadSPE_II:SPE_HitFile5; NVAR  SPE_HitFile5_Found = root:LoadSPE_II:SPE_HitFile5_Found; NVAR  SPE_HitFile5_Loaded = root:LoadSPE_II:SPE_HitFile5_Loaded; NVAR  SPE_FreqBand4Spec5 = root:LoadSPE_II:SPE_FreqBand4Spec5

	NVAR  SPE_PeakPos6 = root:LoadSPE_II:SPE_PeakPos6;	NVAR  SPE_PeakFixed6 = root:LoadSPE_II:SPE_PeakFixed6; NVAR  SPE_MixRatio6 = root:LoadSPE_II:SPE_MixRatio6; 
	NVAR  SPE_Fingerprint6 = root:LoadSPE_II:SPE_Fingerprint6;	SVAR  SPE_HitFile6 = root:LoadSPE_II:SPE_HitFile6; NVAR  SPE_HitFile6_Found = root:LoadSPE_II:SPE_HitFile6_Found; NVAR  SPE_HitFile6_Loaded = root:LoadSPE_II:SPE_HitFile6_Loaded; NVAR  SPE_FreqBand4Spec6 = root:LoadSPE_II:SPE_FreqBand4Spec6

	NVAR  SPE_PeakPos7 = root:LoadSPE_II:SPE_PeakPos7;	NVAR  SPE_PeakFixed7 = root:LoadSPE_II:SPE_PeakFixed7; NVAR  SPE_MixRatio7 = root:LoadSPE_II:SPE_MixRatio7; 
	NVAR  SPE_Fingerprint7 = root:LoadSPE_II:SPE_Fingerprint7;	SVAR  SPE_HitFile7 = root:LoadSPE_II:SPE_HitFile7; NVAR  SPE_HitFile7_Found = root:LoadSPE_II:SPE_HitFile7_Found; NVAR  SPE_HitFile7_Loaded = root:LoadSPE_II:SPE_HitFile7_Loaded; NVAR  SPE_FreqBand4Spec7 = root:LoadSPE_II:SPE_FreqBand4Spec7

	NVAR  SPE_PeakPos8 = root:LoadSPE_II:SPE_PeakPos8;	NVAR  SPE_PeakFixed8 = root:LoadSPE_II:SPE_PeakFixed8; NVAR  SPE_MixRatio8 = root:LoadSPE_II:SPE_MixRatio8; 
	NVAR  SPE_Fingerprint8 = root:LoadSPE_II:SPE_Fingerprint8;	SVAR  SPE_HitFile8 = root:LoadSPE_II:SPE_HitFile8; NVAR  SPE_HitFile8_Found = root:LoadSPE_II:SPE_HitFile8_Found; NVAR  SPE_HitFile8_Loaded = root:LoadSPE_II:SPE_HitFile8_Loaded; NVAR  SPE_FreqBand4Spec8 = root:LoadSPE_II:SPE_FreqBand4Spec8

	NVAR  SPE_timestamp = root:LoadSPE_II:SPE_timestamp;
	SVAR  SPE_time_date = root:LoadSPE_II:SPE_time_date;
	NVAR  SPE_ContinuousRefLok = root:LoadSPE_II:SPE_ContinuousRefLok;


	Wave/D ses_PropertyTimeStamp = root:LoadSPE_UI:ses_PropertyTimeStamp
	Wave/D ses_FileNameBasedTime = root:LoadSPE_UI:ses_FileNameBasedTime
	Wave/T ses_DisplayFileName = root:LoadSPE_UI:ses_DisplayFileName
	Wave/T ses_PackFileInfo = root:LoadSPE_UI:ses_PackFileInfo
	Wave/T ses_Path2File = root:LoadSPE_UI:ses_Path2File
	Wave/D ses_CellPressure = root:LoadSPE_UI:ses_CellPressure
	Wave/D ses_CellTemperature = root:LoadSPE_UI:ses_CellTemperature
	Wave/D ses_LaserPower_1 = root:LoadSPE_UI:ses_LaserPower_1
	Wave/D ses_LaserPower_2 = root:LoadSPE_UI:ses_LaserPower_2
	Wave/D ses_LaserPower_3 = root:LoadSPE_UI:ses_LaserPower_3
	Wave/D ses_LaserPower_4 = root:LoadSPE_UI:ses_LaserPower_4

	Wave/D ses_LaserLinewidth_1 = root:LoadSPE_UI:ses_LaserLinewidth_1
	Wave/D ses_LaserLinewidth_2 = root:LoadSPE_UI:ses_LaserLinewidth_2
	Wave/D ses_LaserLinewidth_3 = root:LoadSPE_UI:ses_LaserLinewidth_3
	Wave/D ses_LaserLinewidth_4 = root:LoadSPE_UI:ses_LaserLinewidth_4
		
	Wave/D ses_MixingRatioSpecies_1 = root:LoadSPE_UI:ses_MixingRatioSpecies_1
	Wave/D ses_PeakPositionSpecies_1 = root:LoadSPE_UI:ses_PeakPositionSpecies_1
	Wave/D ses_MixingRatioSpecies_2 = root:LoadSPE_UI:ses_MixingRatioSpecies_2;	Wave/D ses_PeakPositionSpecies_2 = root:LoadSPE_UI:ses_PeakPositionSpecies_2
	Wave/D ses_MixingRatioSpecies_3 = root:LoadSPE_UI:ses_MixingRatioSpecies_3;	Wave/D ses_PeakPositionSpecies_3 = root:LoadSPE_UI:ses_PeakPositionSpecies_3
	Wave/D ses_MixingRatioSpecies_4 = root:LoadSPE_UI:ses_MixingRatioSpecies_4;	Wave/D ses_PeakPositionSpecies_4 = root:LoadSPE_UI:ses_PeakPositionSpecies_4
	Wave/D ses_MixingRatioSpecies_5 = root:LoadSPE_UI:ses_MixingRatioSpecies_5;	Wave/D ses_PeakPositionSpecies_5 = root:LoadSPE_UI:ses_PeakPositionSpecies_5
	Wave/D ses_MixingRatioSpecies_6 = root:LoadSPE_UI:ses_MixingRatioSpecies_6;	Wave/D ses_PeakPositionSpecies_6 = root:LoadSPE_UI:ses_PeakPositionSpecies_6
	Wave/D ses_MixingRatioSpecies_7 = root:LoadSPE_UI:ses_MixingRatioSpecies_7;	Wave/D ses_PeakPositionSpecies_7 = root:LoadSPE_UI:ses_PeakPositionSpecies_7
	Wave/D ses_MixingRatioSpecies_8 = root:LoadSPE_UI:ses_MixingRatioSpecies_8;	Wave/D ses_PeakPositionSpecies_8 = root:LoadSPE_UI:ses_PeakPositionSpecies_8
	
	String this_filename = StringByKey( "FILE", packed_file )
	String this_packinfo = packed_file
	String this_path = path
								
	AppendVal( ses_PropertyTimeStamp, SPE_timestamp )
	AppendString( ses_DisplayFileName, this_filename )
	AppendString( ses_PackFileInfo, this_packinfo )
	AppendString( ses_Path2File, this_path )
	AppendVal( ses_CellPressure, SPE_CellPressure )
	AppendVal( ses_CellTemperature, SPE_CellTemperature )
	AppendVal( ses_LaserPower_1, SPE_LaserPower_1 )
	AppendVal( ses_LaserPower_2, SPE_LaserPower_2 )
	AppendVal( ses_LaserPower_3, SPE_LaserPower_3 )
	AppendVal( ses_LaserPower_4, SPE_LaserPower_4 )
	
	AppendVal( ses_LaserLinewidth_1, SPE_Linewidth1 )
	AppendVal( ses_LaserLinewidth_2, SPE_Linewidth2 )
	AppendVal( ses_LaserLinewidth_3, SPE_Linewidth3 )
	AppendVal( ses_LaserLinewidth_4, SPE_Linewidth4 )
	
	//	String prefix, sf
	//	sf = GetDataFolder(1); SetDataFolder root:;
	//	//prefix = UniqueName( "N2O_", 1, 0 )
	//	NVAR ses_index = root:LoadSPE_UI:ses_Index
	//	sprintf prefix, "CH4_%03d_", ses_index
	//	ses_index += 1
	//	SetDataFolder $sf
	//	Wave/T/Z ses_Prefix_tw = root:LoadSPE_UI:ses_Prefix_tw
	//	if( WaveExists( ses_Prefix_tw) != 1 )
	//		sf = GetDataFolder(1); SetDataFolder root:LoadSPE_UI
	//		Make/T/N=0 ses_Prefix_tw
	//		SetDataFolder $sf
	//	endif
	//	Wave/T/Z ses_Prefix_tw = root:LoadSPE_UI:ses_Prefix_tw
	//	AppendString( ses_Prefix_tw, prefix )
	//	QuickCopyToRoot( prefix, 2 )
	//	
	//	Variable idex = 1, count = 8
	//	do
	//		Wave/D mixx = $("root:LoadSPE_UI:ses_MixingRatioSpecies_"+num2str(idex))
	//		Wave/D posx = $("root:LoadSPE_UI:ses_PeakPositionSpecies_"+num2str(idex))
	//		NVAR  SPE_PeakPosx = $("root:LoadSPE_II:SPE_PeakPos"+num2str(idex))
	//		NVAR  SPE_MixRatiox = $("root:LoadSPE_II:SPE_MixRatio"+num2str(idex))
	//		
	//		AppendVal( mixx, SPE_MixRatiox )
	//		AppendVal( posx, SPE_PeakPosx )
	//		idex += 1
	//	while( idex <= count )
End
// Change tabs. Controls to be shown only for a hidden tab start with
// two letters and an underscore, where the two letters match the
// first two letters of the tab for which it should be shown.  For instance,
// a control called wa_Stevie should only be shown for the "watch" tab,
// a control called li_Jimi should only be shown for the "live pixels" tab,
// and a control called Kenny should be left alone when changing tabs.
//
// Here is where we hilite the appropriate controls
Function zSPE2_AutoTabProc( name, tab )
	String name
	Variable tab

	String msg
	
	// Get the name of the current tab
	ControlInfo $name
	String tabStr = S_Value
	sprintf msg, "Switch to %s", tabStr	
	tabStr = tabStr[0,1]
	
	// Get a list of all the controls in the window
	Variable i = 0
	String all = ControlNameList( "" )
	String thisControl
	
	do
		thisControl = StringFromList( i, all )
		if( strlen( thisControl ) <= 0 )
			break
		endif
		
		// Found another control.  Does it start with two letters and an underscore?
		if( !CmpStr( thisControl[2], "_" ) )
			// If it matches the current tab, show it.  Otherwise, hide it
			if( (CmpStr( thisControl[0,1], tabStr )==0) | (CmpStr( thisControl[0,1], "ao") == 0) )
				zSPE2_ShowControl( thisControl, 0 )
			else
				zSPE2_ShowControl( thisControl, 1)
			endif
		endif
		i += 1
	while( 1 )
	
	// Some controls on the new tab might be supposed to be hidden.  Here
	// is where we call the proc to set their hidden state, and do any other
	// tab-specific adjustments
	switch( tab )
		case 0:
			
			break
		
		case 1:
			
			break
	endswitch
End
// Show or hide any kind of control in the top window
Function zSPE2_ShowControl( name, disable )
	String name
	Variable disable
	
	// What kind of control is it?
	ControlInfo $name
	Variable type = v_flag
	switch( abs(type) )
		case 1:		// button
			Button $name disable=disable
			break
		
		case 2:		// checkbox
			CheckBox $name disable=disable
			break
		
		case 3:		// popup menu
			PopupMenu $name disable=disable
			break
		
		case 4:
			ValDisplay $name disable=disable
			break
		
		case 5:
			SetVariable $name disable=disable
			break
		
		case 6:
			Chart $name disable=disable
			break
		
		case 7:
			Slider $name disable=disable
			break
		
		case 8:
			TabControl $name disable=disable
			break
		
		case 9:
			GroupBox $name disable=disable
			break
		
		case 10:
			TitleBox $name disable=disable
			break
		
		case 11:
			ListBox $name disable=disable
			break
	endswitch
End

Function zSPE2_InitUIVars()
	
	String saveFolder = GetDataFolder(1)
	SetDataFolder root:; MakeAndOrSetDF( "LoadSPE_UI" )
	
	String destFolder = "root:LoadSPE_UI"
	Variable idex
	String useList, thisVarName, cmd
	
	String VarsList = "WorkingWithZip;xBox_IncludeZip;xBox_IncludeSPE;xBox_BlockBK;xBox_BlockRef;xBox_BlockCal;xBox_BlockPN;xBox_BlockRaw;xBox_BlockWild;xBox_BlockNorm;Roll_SpeciesNumber;xBox_DoUpdate;Mix_a;Mix_b;Pos_a;Pos_b;Fingerprint_a;Fingerprint_b;CellTemperature;CellPressure;PathLength;CellResponse;Laser1Power;Laser2Power;Laser3Power;Laser4Power;"
	idex = 0; Variable count = ItemsInLIst( VarsList )
	do
		thisVarName = StringFromList( idex, VarsList )
		NVAR/Z testNvar =$(destFolder + ":" + thisVarName )
		if( !NVAR_Exists( testNVar ) )
			sprintf cmd, "Variable/G %s=0", thisVarName
			Execute cmd
		endif
		idex += 1
	while( idex < count )
	
	//	xBox_ChiFilter;Value_ChiFilter;Sweep_ChiFilter;xBox_DoUEX;xBox_DoRES"		
	VarsList = "xBox_ChiFilter;Value_ChiFilter;Sweep_ChiFilter;xBox_DoUEX;xBox_DoRES"
	idex = 0; count = ItemsInList( VarsList )
	do
		thisVarName = StringFromList( idex, VarsList )
		NVAR/Z testNvar =$(destFolder + ":" + thisVarName )
		if( !NVAR_Exists( testNVar ) )
			sprintf cmd, "Variable/G %s=0", thisVarName
			Execute cmd
		endif
		idex += 1
	while( idex < count )
		
	String StrsList = "Path2Files;HitFile_a;HitFile_b;HitFile_JFa;HitFile_JFb;TimeStampTime;FileTimeTime;BrowseMSG;LoadMSG;PlayListMSG;AverageOptionsStr"
	idex = 0; count = ItemsInLIst( StrsList )
	do
		thisVarName = StringFromList( idex, StrsList )
		SVAR/Z testSvar =$(destFolder + ":" + thisVarName )
		if( !SVAR_Exists( testSVar ) )
			sprintf cmd, "String/G %s=\"notset\"", thisVarName
			Execute cmd
		endif
		idex += 1
	while( idex < count )
	
	Make/O/N=0/D disp_time
	SetScale/P y, 0, 0, "dat" disp_time
	
	Make/O/N=0/T disp_fileList, pack_fileList, path_fileList
	Make/O/N=0 disp_SelWave
	
	// these guys are the session waves which track activity and provide a poor mans stc file from a browse session
	Make/O/N=0/D ses_PropertyTimeStamp, ses_FileNameBasedTime
	SetScale/P y, 0, 0, "dat", ses_PropertyTimeStamp, ses_FileNameBasedTime
	
	Make/O/N=0/T ses_DisplayFileName, ses_PackFileInfo, ses_Path2File
	
	Make/O/N=0/D ses_CellPressure, ses_CellTemperature, ses_LaserPower_1, ses_LaserPower_2, ses_LaserPower_3, ses_LaserPower_4
	Make/O/N=0/D ses_LaserLinewidth_1, ses_LaserLinewidth_2, ses_LaserLinewidth_3, ses_LaserLinewidth_4
	
	Make/O/N=2/D SPB_NowBar; SPB_NowBar = p
	idex = 1; 
	do
		Make/O/N=0/D $("ses_MixingRatioSpecies_" + num2str(idex))
		Make/O/N=0/D $("ses_PeakPositionSpecies_" + num2str(idex))
		
		idex += 1
	while( idex <= 8 )
	
	SetDataFolder $saveFolder
	
	NVAR WorkingWithZip = root:LoadSPE_UI:WorkingWithZip
	NVAR xBox_IncludeZip = root:LoadSPE_UI:xBox_IncludeZip
	NVAR xBox_IncludeSPE = root:LoadSPE_UI:xBox_IncludeSPE
	NVAR xBox_BlockBK = root:LoadSPE_UI:xBox_BlockBK
	NVAR xBox_BlockRef = root:LoadSPE_UI:xBox_BlockRef
	NVAR xBox_BlockPN = root:LoadSPE_UI:xBox_BlockPN
	NVAR xBox_BlockRaw = root:LoadSPE_UI:xBox_BlockRaw
	NVAR xBox_BlockCal = root:LoadSPE_UI:xBox_BlockCal
	NVAR xBox_BlockWild = root:LoadSPE_UI:xBox_BlockWild
	NVAR xBox_BlockNorm = root:LoadSPE_UI:xBox_BlockNorm
	
	NVAR Roll_SpeciesNumber = root:LoadSPE_UI:Roll_SpeciesNumber
	NVAR xBox_DoUpdate = root:LoadSPE_UI:xBox_DoUpdate
	NVAR Mix_a = root:LoadSPE_UI:Mix_a
	NVAR Mix_b = root:LoadSPE_UI:Mix_b
	NVAR Pos_a = root:LoadSPE_UI:Pos_a
	NVAR Pos_b = root:LoadSPE_UI:Pos_b
	NVAR Fingerprint_b = root:LoadSPE_UI:Fingerprint_b
	
	NVAR CellTemperature = root:LoadSPE_UI:CellTemperature
	NVAR CellPressure = root:LoadSPE_UI:CellPressure
	NVAR PathLength = root:LoadSPE_UI:PathLength
	NVAR CellResponse = root:LoadSPE_UI:CellResponse
	NVAR Laser1Power = root:LoadSPE_UI:Laser1Power
	NVAR Laser2Power = root:LoadSPE_UI:Laser2Power
	NVAR Laser3Power = root:LoadSPE_UI:Laser3Power
	NVAR Laser4Power = root:LoadSPE_UI:Laser4Power

	SVAR Path2Files = root:LoadSPE_UI:Path2Files
	SVAR HitFile_a = root:LoadSPE_UI:HitFile_a
	SVAR HitFile_b = root:LoadSPE_UI:HitFile_b
	SVAR HitFile_JFa = root:LoadSPE_UI:HitFile_JFa
	SVAR HitFile_JFb = root:LoadSPE_UI:HitFile_JFb
	SVAR TimeStampTime = root:LoadSPE_UI:TimeStampTime
	SVAR FileTimeTime = root:LoadSPE_UI:FileTimeTime
	SVAR BrowseMSG = root:LoadSPE_UI:BrowseMSG
	SVAR LoadMSG = root:LoadSPE_UI:LoadMSG
	SVAR PlayListMSG = root:LoadSPE_UI:PlayListMSG

	Wave/D disp_time = root:LoadSPE_UI:disp_time
	Wave/T disp_fileList = root:LoadSPE_UI:disp_fileList
	Wave/T pack_fileList = root:LoadSPE_UI:pack_fileList
	Wave/T path_fileList = root:LoadSPE_UI:path_fileList
	Wave disp_SelWave = root:LoadSPE_UI:disp_SelWave
	
	// default - preferences - initialize default values
	xBox_IncludeZip = 1
	xBox_IncludeSPE = 1
	Roll_SpeciesNumber = 1
	// ses_ wave references to follow....
	
	
	Wave/D ses_PropertyTimeStamp = root:LoadSPE_UI:ses_PropertyTimeStamp
	Wave/D ses_FileNameBasedTime = root:LoadSPE_UI:ses_FileNameBasedTime
	Wave/T ses_DisplayFileName = root:LoadSPE_UI:ses_DisplayFileName
	Wave/T ses_PackFileInfo = root:LoadSPE_UI:ses_PackFileInfo
	Wave/T ses_Path2File = root:LoadSPE_UI:ses_Path2File
	Wave/D ses_CellPressure = root:LoadSPE_UI:ses_CellPressure
	Wave/D ses_CellTemperature = root:LoadSPE_UI:ses_CellTemperature
	Wave/D ses_LaserPower_1 = root:LoadSPE_UI:ses_LaserPower_1
	Wave/D ses_LaserPower_2 = root:LoadSPE_UI:ses_LaserPower_2
	Wave/D ses_LaserPower_3 = root:LoadSPE_UI:ses_LaserPower_3
	Wave/D ses_LaserPower_4 = root:LoadSPE_UI:ses_LaserPower_4
	Wave/D ses_LaserLinewidth_1 = root:LoadSPE_UI:ses_LaserLinewidth_1
	Wave/D ses_LaserLinewidth_2 = root:LoadSPE_UI:ses_LaserLinewidth_2
	Wave/D ses_LaserLinewidth_3 = root:LoadSPE_UI:ses_LaserLinewidth_3
	Wave/D ses_LaserLinewidth_4 = root:LoadSPE_UI:ses_LaserLinewidth_4
	
	Wave/D ses_MixingRatioSpecies_1 = root:LoadSPE_UI:ses_MixingRatioSpecies_1
	Wave/D ses_PeakPositionSpecies_1 = root:LoadSPE_UI:ses_PeakPositionSpecies_1
	Wave/D ses_MixingRatioSpecies_2 = root:LoadSPE_UI:ses_MixingRatioSpecies_2;	Wave/D ses_PeakPositionSpecies_2 = root:LoadSPE_UI:ses_PeakPositionSpecies_2
	Wave/D ses_MixingRatioSpecies_3 = root:LoadSPE_UI:ses_MixingRatioSpecies_3;	Wave/D ses_PeakPositionSpecies_3 = root:LoadSPE_UI:ses_PeakPositionSpecies_3
	Wave/D ses_MixingRatioSpecies_4 = root:LoadSPE_UI:ses_MixingRatioSpecies_4;	Wave/D ses_PeakPositionSpecies_4 = root:LoadSPE_UI:ses_PeakPositionSpecies_4
	Wave/D ses_MixingRatioSpecies_5 = root:LoadSPE_UI:ses_MixingRatioSpecies_5;	Wave/D ses_PeakPositionSpecies_5 = root:LoadSPE_UI:ses_PeakPositionSpecies_5
	Wave/D ses_MixingRatioSpecies_6 = root:LoadSPE_UI:ses_MixingRatioSpecies_6;	Wave/D ses_PeakPositionSpecies_6 = root:LoadSPE_UI:ses_PeakPositionSpecies_6
	Wave/D ses_MixingRatioSpecies_7 = root:LoadSPE_UI:ses_MixingRatioSpecies_7;	Wave/D ses_PeakPositionSpecies_7 = root:LoadSPE_UI:ses_PeakPositionSpecies_7
	Wave/D ses_MixingRatioSpecies_8 = root:LoadSPE_UI:ses_MixingRatioSpecies_8;	Wave/D ses_PeakPositionSpecies_8 = root:LoadSPE_UI:ses_PeakPositionSpecies_8
								
	
End

Function zSPE2_TransAndSigGraphDraw( wbx, force_redraw )
	Variable wbx
	Variable force_redraw
		
	String win
	sprintf win, "TransmissionAndSignal_wb%d", wbx
	DoWindow $win
	if( V_Flag )
		if( force_redraw == 0 )
			DoWindow/F $win
			return 0
		endif
		DoWindow/K $win
	endif
	Display/K=1 as win
	DoWindow/C $win
	zSPE_wbx_AddOrRemoveTrans( wbx, 1 )
	zSPE_wbx_AddOrRemoveSig( wbx, 1 )
	
	Execute("HandyGraphButtons()" )
	zSPE2_AddTrandSigSlider(win); 	zSPE2_TransAndSlideProc( "trans_sig_slide", 0.5, 1 )
	Execute("SetAxis/A bottom")
	Variable high_bound
	Variable extent, low_bound
	String wave_str
	sprintf wave_str, "root:LoadSPE_II:wb%d_frequency", wbx
	Wave/D wbx_frequency = $wave_Str

	WaveStats/Q wbx_frequency
	low_bound = v_min
	high_bound = v_max
	extent = v_max - v_min
	low_bound = v_min + 0.08 * extent
	String cmd
	sprintf cmd, "SetAxis bottom, %f, %f", low_bound, v_max - 0.05*extent
	Execute/P cmd
	
End
Function zSPE2_AddTrandSigSlider(win)
	String win
	
	if( cmpstr( win, "" ) == 0 )
		win = WinName(0,1)
	endif
	
	Slider trans_sig_slide, pos={229, 3}, size={100, 21}, proc=zSPE2_TransAndSlideProc, value=0.5, limits={0,1,0.05}, vert=0, ticks=0
	
End

Function zSPE2_TransAndSlideProc(name, value, event)
	String name
	Variable value
	Variable event
	
	String win  = WinName(0,1)
	
	Variable trans_lo, trans_hi
	GetAxis/W=$win/Q trans_ax
	trans_lo = V_Min
	trans_hi = V_Max

	Variable sig_lo, sig_hi
	GetAxis/W=$win/Q sig_ax
	sig_lo = V_Min
	sig_hi = V_Max	
	
	Variable bot_lo, bot_hi
	GetAxis/W=$win/Q bottom
	bot_lo = V_Min
	bot_hi = V_Max
	
	String wbx_num_str = win[strlen(win)-1]
	if( numtype( str2num( wbx_num_str ) ) == 2 )
		return 0
	endif	
	String list = tracenamelist( "", ";", 1 )
	if( strsearch( "trans", list, 0 ) == -1 )
		zSPE_wbx_AddOrRemoveTrans( str2num( wbx_num_str ), 1 )
	endif
	if( strsearch( "base", list, 0 ) == -1 )
		zSPE_wbx_AddOrRemoveSig( str2num( wbx_num_str ), 1 )
	endif
	 
	if( (value != 0 ) && (value != 1 ) )
		ModifyGraph axisEnab(trans_ax)={value+0.02,1}; DelayUpdate
		ModifyGraph axisEnab(sig_ax)={0,value-0.02}
		if( (numtype( sig_lo ) == 2 ) || (numtype( sig_hi) == 2) )
			SetAxis/W=$win/A sig_ax
		else
			SetAxis/W=$win sig_ax, sig_lo, sig_hi
		endif
		if( (numtype( trans_lo ) == 2 ) || (numtype( trans_hi) == 2) )
			SetAxis/W=$win/A trans_ax
		else
			SetAxis/W=$win trans_ax, trans_lo, trans_hi
		endif		
	else
		// we are at an extreme which raises the red flags
		if( value == 0 )
			zSPE_wbx_AddOrRemoveSig( str2num( wbx_num_str ), 0 )
			ModifyGraph axisEnab( trans_ax ) = {0,1};DelayUpdate
			if( (numtype( trans_lo ) == 2 ) || (numtype( trans_hi) == 2) )
				SetAxis/W=$win/A trans_ax
			else
				SetAxis/W=$win trans_ax, trans_lo, trans_hi
			endif		

		else
			zSPE_wbx_AddOrRemoveTrans( str2num( wbx_num_str ), 0 )
			ModifyGraph axisEnab(sig_ax)={0,1}
			if( (numtype( sig_lo ) == 2 ) || (numtype( sig_hi) == 2) )
				SetAxis/W=$win/A sig_ax
			else
				SetAxis/W=$win sig_ax, sig_lo, sig_hi
			endif					
		endif
	endif
	Variable set_to_auto = 0
	if( (numtype( bot_lo ) == 2 ) || (numtype( bot_hi) == 2) )
		set_to_auto = 1
	else
		if( bot_lo == 0 || bot_hi == 0 )
			set_to_auto = 1
		else
			// this should be the only case where user picked frequency comes to bear
			SetAxis/W=$win bottom, bot_lo, bot_hi
		endif
	endif
	if( set_to_auto )
		Execute/P "SetAxis/A bottom"
		//GetAxis bottom
		//printf "%f & %f\r", v_min, v_max
	endif

	
	return 0
End

Function zSPE_wbx_AddOrRemoveTrans( wbnum, addflag )
	Variable wbnum, addflag
	
	DelayUpdate;
	String trans_list = TraceNameList( "", ";", 1 )
	Variable count = ItemsInList( trans_list )
	String wbx_freq = "wb" + num2str( wbnum ) + "_frequency"
	String wbx_trans_spectrum = "wb" + num2str( wbnum ) + "_trans_spectrum"
	String wbx_trans_specMarker = "wb" + num2str( wbnum ) + "_trans_spectrum#1"

	String wbx_trans_fit = "wb" + num2str( wbnum ) + "_trans_fit"
	String wbx_curs = "wb" + num2str( wbnum ) + "_igr_cur"
	if( WhichListItem( wbx_trans_spectrum, trans_list ) != -1 )
		RemoveFromGraph $wbx_trans_spectrum
		trans_list = TraceNameList( "", ";", 1 )
	endif
	if( WhichListItem( wbx_trans_spectrum, trans_list ) != -1 )
		RemoveFromGraph $wbx_trans_spectrum
	endif
	if( WhichListItem( wbx_trans_fit, trans_list ) != -1 )
		RemoveFromGraph $wbx_trans_fit
	endif		
	Wave wbx_freq_w = $("root:LoadSPE_II:" + wbx_freq )
	Wave wbx_trans_spectrum_w = $("root:LoadSPE_II:" + wbx_trans_spectrum )
	Wave wbx_trans_fit_w = $("root:LoadSPE_II:" + wbx_trans_fit )
	Wave wbx_curs_w = $("root:LoadSPE_II:" + wbx_curs )
	if( addflag )
		// add them to the graph
		AppendToGraph/L=trans_ax wbx_trans_spectrum_w, wbx_trans_fit_w, wbx_trans_spectrum_w vs wbx_freq_w
		ModifyGraph mode($wbx_trans_spectrum) = 3
		ModifyGraph mode($wbx_trans_fit) = 3
		ModifyGraph mode($wbx_trans_specMarker) = 3
		ModifyGraph marker($wbx_trans_spectrum) = 18
		ModifyGraph marker($wbx_trans_specMarker) = 18
		ModifyGraph mode($wbx_trans_fit)=0
		ModifyGraph rgb($wbx_trans_spectrum)=(26112,52224,0),rgb($wbx_trans_fit)=(0,12800,52224)
		ModifyGraph rgb($wbx_trans_specMarker)=(65280,65280,0)
		ModifyGraph zmrkNum($wbx_trans_specMarker)={wbx_curs_w}
		ModifyGraph grid=2
		ModifyGraph tick=2
		ModifyGraph mirror=2
		ModifyGraph minor(bottom)=1
		ModifyGraph standoff=0
		ModifyGraph lblPos(trans_ax)=35
		ModifyGraph lblLatPos(trans_ax)=-20
		ModifyGraph freePos(trans_ax)={0,bottom}
		ModifyGraph msize($wbx_trans_specMarker) = 5
		Label trans_ax "Transmission"
		ModifyGraph axRGB(trans_ax)=(16384,28160,65280)
		ModifyGraph tlblRGB(trans_ax)=(16384,28160,65280)
		ModifyGraph alblRGB(trans_ax)=(16384,28160,65280)
		ModifyGraph gridRGB(trans_ax)=(16384,28160,65280)

	
	else
		// remove them from the graph
	endif
	ModifyGraph margin(left)=72
	Label bottom "Frequency (cm\\S-1\\M)"
End

Function zSPE_wbx_AddOrRemoveSig( wbnum, addflag )
	Variable wbnum, addflag
	
	DelayUpdate;
	String sig_list = TraceNameList( "", ";", 1 )
	Variable count = ItemsInList( sig_list )
	String wbx_freq = "wb" + num2str( wbnum ) + "_frequency"
	String wbx_spectrum = "wb" + num2str( wbnum ) + "_spectrum"
	String wbx_specMarker = "wb" + num2str( wbnum ) + "_spectrum#1"

	String wbx_fit = "wb" + num2str( wbnum ) + "_wintel_fit"
	String wbx_base = "wb" + num2str( wbnum ) + "_wintel_base"
	String wbx_curs = "wb" + num2str( wbnum ) + "_igr_cur"
	if( WhichListItem( wbx_spectrum, sig_list ) != -1 )
		RemoveFromGraph $wbx_spectrum
		sig_list = TraceNameList( "", ";", 1 )
	endif
	if( WhichListItem( wbx_spectrum, sig_list ) != -1 )
		RemoveFromGraph $wbx_spectrum
	endif
	if( WhichListItem( wbx_fit,sig_list ) != -1 )
		RemoveFromGraph $wbx_fit
	endif
	if( WhichListItem( wbx_base,sig_list ) != -1 )
		RemoveFromGraph $wbx_base
	endif			
	Wave wbx_freq_w = $("root:LoadSPE_II:" + wbx_freq )
	Wave wbx_spectrum_w = $("root:LoadSPE_II:" + wbx_spectrum )
	Wave wbx_fit_w = $("root:LoadSPE_II:" + wbx_fit )
	Wave wbx_base_w = $("root:LoadSPE_II:" + wbx_base )
	Wave wbx_curs_w = $("root:LoadSPE_II:" + wbx_curs )
	if( addflag )
		// add them to the graph
		AppendToGraph/L=sig_ax wbx_spectrum_w, wbx_fit_w, wbx_base_w, wbx_spectrum_w vs wbx_freq_w
		ModifyGraph mode($wbx_spectrum) = 3
		ModifyGraph mode($wbx_fit) = 3
		ModifyGraph mode($wbx_specMarker) = 3
		ModifyGraph marker($wbx_spectrum) = 18
		ModifyGraph marker($wbx_specMarker) = 18
		ModifyGraph mode($wbx_fit)=0
		ModifyGraph mode($wbx_base)=0
		ModifyGraph rgb($wbx_spectrum)=(26112,52224,0),rgb($wbx_fit)=(0,12800,52224), rgb($wbx_base)=(0,12800,52224)
		ModifyGraph rgb($wbx_specMarker)=(65280,65280,0)
		ModifyGraph zmrkNum($wbx_specMarker)={wbx_curs_w}
		ModifyGraph grid=2
		ModifyGraph tick=2
		ModifyGraph mirror=2
		ModifyGraph minor(bottom)=1
		ModifyGraph standoff=0
		ModifyGraph lblPos(sig_ax)=40
		ModifyGraph lblLatPos(sig_ax)=-10
		ModifyGraph freePos(sig_ax)={0,bottom}
		ModifyGraph msize($wbx_specMarker) = 5

		Label sig_ax "Signal (mV)"
		ModifyGraph axRGB(sig_ax)=(13056,26112,0),tlblRGB(sig_ax)=(13056,26112,0)
		ModifyGraph alblRGB(sig_ax)=(13056,26112,0),gridRGB(sig_ax)=(13056,26112,0)
	else
		// remove them from the graph
	endif
	ModifyGraph margin(left)=72
	Label bottom "Frequency (cm\\S-1\\M)"
End
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



Window QuadTDLStyle() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	SetDataFolder root:LoadSPE_II:
	Display /W=(135,44,902.25,507.5)/L=q1_lax/B=q1_bax wb1_spectrum,wb1_wintel_base vs wb1_frequency as "QuadTDLStyle"
	AppendToGraph/L=q1_lax/B=q1_bax wb1_wintel_fit vs wb1_frequency
	AppendToGraph/L=q2_lax/B=q2_bax wb2_spectrum,wb2_wintel_base,wb2_wintel_fit vs wb2_frequency
	AppendToGraph/L=q3_lax/B=q3_bax wb3_spectrum,wb3_wintel_base,wb3_wintel_fit vs wb3_frequency
	AppendToGraph/L=q4_lax/B=q4_bax wb4_spectrum,wb4_wintel_base,wb4_wintel_fit vs wb4_frequency
	AppendToGraph/L=q1_lax/B=q1_bax wb1_spectrum vs wb1_frequency
	AppendToGraph/L=q2_lax/B=q2_bax wb2_spectrum vs wb2_frequency
	AppendToGraph/L=q3_lax/B=q3_bax wb3_spectrum vs wb3_frequency
	AppendToGraph/L=q4_lax/B=q4_bax wb4_spectrum vs wb4_frequency
	SetDataFolder fldrSav
	ModifyGraph margin(left)=72,margin(bottom)=72,wbRGB=(47872,47872,47872),gbRGB=(47872,47872,47872)
	ModifyGraph mode(wb1_spectrum)=3,mode(wb2_spectrum)=3,mode(wb3_spectrum)=3,mode(wb4_spectrum)=3
	ModifyGraph mode(wb1_spectrum#1)=3,mode(wb2_spectrum#1)=3,mode(wb3_spectrum#1)=3
	ModifyGraph mode(wb4_spectrum#1)=3
	ModifyGraph marker(wb1_spectrum)=18,marker(wb2_spectrum)=19,marker(wb3_spectrum)=17
	ModifyGraph marker(wb4_spectrum)=16
	ModifyGraph lStyle(wb1_wintel_base)=2,lStyle(wb2_wintel_base)=2,lStyle(wb3_wintel_base)=2
	ModifyGraph lStyle(wb4_wintel_base)=4
	ModifyGraph rgb(wb1_spectrum)=(0,52224,0),rgb(wb1_wintel_base)=(0,0,52224),rgb(wb1_wintel_fit)=(0,0,52224)
	ModifyGraph rgb(wb2_spectrum)=(0,52224,0),rgb(wb2_wintel_base)=(0,0,52224),rgb(wb2_wintel_fit)=(0,0,52224)
	ModifyGraph rgb(wb3_spectrum)=(0,52224,0),rgb(wb3_wintel_base)=(0,0,52224),rgb(wb3_wintel_fit)=(0,0,52224)
	ModifyGraph rgb(wb4_spectrum)=(0,52224,0),rgb(wb4_wintel_base)=(0,0,52224),rgb(wb4_wintel_fit)=(0,0,52224)
	ModifyGraph rgb(wb1_spectrum#1)=(65280,65280,0),rgb(wb2_spectrum#1)=(65280,65280,0)
	ModifyGraph rgb(wb3_spectrum#1)=(65280,65280,0),rgb(wb4_spectrum#1)=(65280,65280,0)
	ModifyGraph msize(wb1_spectrum#1)=5,msize(wb2_spectrum#1)=5,msize(wb3_spectrum#1)=5
	ModifyGraph msize(wb4_spectrum#1)=5
	ModifyGraph zmrkNum(wb1_spectrum#1)={:LoadSPE_II:wb1_igr_cur},zmrkNum(wb2_spectrum#1)={:LoadSPE_II:wb2_igr_cur}
	ModifyGraph zmrkNum(wb3_spectrum#1)={:LoadSPE_II:wb3_igr_cur},zmrkNum(wb4_spectrum#1)={:LoadSPE_II:wb4_igr_cur}
	ModifyGraph standoff=0
	ModifyGraph freePos(q1_lax)={0,q1_bax}
	ModifyGraph freePos(q1_bax)={0,q1_lax}
	ModifyGraph freePos(q2_lax)={0,q2_bax}
	ModifyGraph freePos(q2_bax)={0,q2_lax}
	ModifyGraph freePos(q3_lax)={0,q3_bax}
	ModifyGraph freePos(q3_bax)={0,q3_lax}
	ModifyGraph freePos(q4_lax)={0,q4_bax}
	ModifyGraph freePos(q4_bax)={0,q4_lax}
	ModifyGraph axisEnab(q1_lax)={0.55,1}
	ModifyGraph axisEnab(q1_bax)={0,0.45}
	ModifyGraph axisEnab(q2_lax)={0.55,1}
	ModifyGraph axisEnab(q2_bax)={0.55,1}
	ModifyGraph axisEnab(q3_lax)={0,0.45}
	ModifyGraph axisEnab(q3_bax)={0,0.45}
	ModifyGraph axisEnab(q4_lax)={0,0.45}
	ModifyGraph axisEnab(q4_bax)={0.55,1}
	TextBox/N=text0/F=0/B=1/A=MC/X=-46.77/Y=-49.40 "\\Z09\\K(52224,0,0)\\{\"Field %d\", root:loadSpe_II:spe_fieldnumber}\r\r"
EndMacro


Window SimpleSessionFigure_1() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav= GetDataFolder(1)
	SetDataFolder root:LoadSPE_UI:
	Display /W=(9.75,110,404.25,532.25)/L=tempe_ax ses_CellTemperature vs ses_PropertyTimeStamp as "SimpleSessionFigure_1"
	AppendToGraph/L=presax ses_CellPressure vs ses_PropertyTimeStamp
	AppendToGraph/L=pposax1 ses_PeakPositionSpecies_1 vs ses_PropertyTimeStamp
	AppendToGraph/L=mr1ax ses_MixingRatioSpecies_1 vs ses_PropertyTimeStamp
	SetDataFolder fldrSav
	ModifyGraph rgb(ses_CellPressure)=(16384,28160,65280),rgb(ses_PeakPositionSpecies_1)=(34816,34816,34816)
	ModifyGraph rgb(ses_MixingRatioSpecies_1)=(26112,52224,0)
	ModifyGraph freePos(tempe_ax)=-50
	ModifyGraph freePos(presax)=-50
	ModifyGraph freePos(pposax1)=-50
	ModifyGraph freePos(mr1ax)=-50
	ModifyGraph axisEnab(tempe_ax)={0,0.25}
	ModifyGraph axisEnab(presax)={0.25,0.5}
	ModifyGraph axisEnab(pposax1)={0.5,0.75}
	ModifyGraph axisEnab(mr1ax)={0.75,1}
	ModifyGraph dateInfo(bottom)={0,0,0}
	Label bottom " "
EndMacro


Function TDLCore_LoadSTR( targetFullFile, DestDF )
	String targetFullFile
	String DestDF
	
	String formatStr = ""
	
	formatStr = formatStr + "C=1,T=4,N=new_source_rtime;"
	formatStr = formatStr + "C=1,T=4,N=new_tdl1_conc;"
	formatStr = formatStr + "C=1,T=4,N=new_tdl2_conc;"
	formatStr = formatStr + "C=1,T=4,N=new_tdl3_conc;"
	formatStr = formatStr + "C=1,T=4,N=new_tdl4_conc;"
	formatStr = formatStr + "C=1,T=4,N=new_tdl5_conc;"
	formatStr = formatStr + "C=1,T=4,N=new_tdl6_conc;"
	formatStr = formatStr + "C=1,T=4,N=new_tdl7_conc;"
	formatStr = formatStr + "C=1,T=4,N=new_tdl8_conc;"	
	MakeAndOrSetDF( DestDF )
	LoadWave/A/D/Q/G/L={0,1,0,0,0}/B=formatStr targetFullFile
	String list = S_waveNames, this_new_w, sans_new
	Variable idex = 0, count = ItemsInList( list )
	Wave/Z source_rtime=source_rtime
	if( WaveExists( source_rtime ) != 1 )
		if( count > 0 )
			do
				this_new_w = StringFromLIst( idex, list )
				sans_new = this_new_w[ strlen( "new_" ), strlen( this_new_w ) -1 ];
				rename $this_new_w, $sans_new
				idex += 1
			while( idex < count )
		endif
	else
		if( count > 0 )
			do
				this_new_w = StringFromLIst( idex, list )
				sans_new = this_new_w[ strlen( "new_" ), strlen( this_new_w ) -1 ];
				ConcatenateWaves( sans_new, this_new_w )
				idex += 1
			while( idex < count )
		endif
		
		KillWaves/Z new_source_rtime, new_tdl1_conc, new_tdl2_conc, new_tdl3_conc, new_tdl4_conc;
		KillWaves/Z new_tdl5_conc, new_tdl6_conc, new_tdl7_conc, new_tdl8_conc;
	endif
	Wave source_rtime=source_rtime
	SetScale/P y, 0, 0, "dat", source_rtime
	setdatafolder root:
End

Function zSTR_InitSTRPanel()

	if( k_Invoke2014_STRPanel == 1 )
		// 2014 version should be used.  We leave the switch here for menuing
		nSTR_a_Init();
		nSTR_b_Draw();
		// refresh data
		nSTR_g_PathOrRefresh()
		 
		return 0; // <new vector to leave this function
	endif
	NewDataFolder/O root:STRPanel_Folder
	SetDataFolder root:STRPanel_Folder
	
	Make/N=0/O str_loadfile_w
	Make/N=0/T/O str_files_w
	Variable/G LegacyWintelTime = 0
	String/G str_panel_prefix, str_panel_df, str_panel_path
	Variable/G TailEnable=0
	Variable/G TailValue=3
	Variable/G AutoNameAndGo=1
	
	str_panel_path = "c:"; str_panel_df = "root", str_panel_prefix = "str"
	zSTR_STRPanel()
	setdatafolder root:
End

Function zSTR_CBProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	switch( cba.eventCode )
		case 2: // mouse up
			Variable checked = cba.checked
			NVAR autonameandgo = root:strpanel_folder:autonameandgo
			if( autonameandgo )
				SetVariable STRPanelPrefix, disable = 2, fstyle=0
			else
				SetVariable STRPanelPrefix, disable = 0, fstyle=1, activate

			endif
			break
	endswitch

	return 0
End

Function zSTR_STRPanel() : Panel
	Variable button_width = 75, control_height = 20, text_box_width = 250
	Variable fileListwidth = 155, fileListheight = 150, row = 0
	Variable column_1 = 0, column_2 = fileListwidth + 5

	Variable column_b1 = column_1
	Variable column_b2 = 1.5 * button_width + column_b1 + 2
	Variable column_b3 = 1.5 * button_width + column_b2 + 2
	Wave/T str_files_w=root:STRPanel_Folder:str_files_w
	Wave/Z str_fileload_w=root:STRPanel_Folder:str_fileload_w
	
	PauseUpdate; Silent 1		// building window...
	if( strlen( WinList( "STR_Panel", ";", "" ) )> 0 )
		DoWindow/K STR_Panel
	endif
	NewPanel /W=(5,5,fileListwidth+10+text_box_width,filelistheight+2* control_height+15)
	DoWindow/C STR_Panel
	SetWindow STR_Panel hook=STR_PanelWinProc
	
	Button STRPath,pos={column_1,row},size={button_width,control_height},proc=zSTR_Panel_Button,title="Set Path"
	SetVariable strPathDisplay,pos={button_width+1,row},size={text_box_width+75,control_height},title=">",frame=0
	SetVariable strPathDisplay,value= root:STRPanel_Folder:str_panel_path
	zSTR_Panel_Button("STRPath")
	row+=control_height + 5
	
	CheckBox STRAutoname_ck, pos={column_2, row}, title="Auto str_/stc_", variable=root:strpanel_folder:autonameandgo, proc=zSTR_CBProc
	
	SetVariable STRPanelPrefix,pos={column_2 + 95,row},size={text_box_width/2,control_height},title="Wave Prefix"
	SetVariable STRPanelPrefix,value= root:STRPanel_Folder:str_panel_prefix
	NVAR autonameandgo = root:strpanel_folder:autonameandgo
	if( autonameandgo )
		SetVariable STRPanelPrefix, disable = 2, fstyle=0
	else
		SetVariable STRPanelPrefix, disable = 0, fstyle=1, activate

	endif
	
	ListBox STR_LB1,pos={column_1,row},size={fileListwidth,fileListheight}
	ListBox STR_LB1, listWave=str_files_w,selWave=str_loadfile_w,mode= 4
	
	row+= control_height + 5

	PopupMenu STRPanelGraphPop,pos={column_2,row},size={text_box_width,control_height},title="Graph"
	PopupMenu STRPanelGraphPop,mode=2,popvalue="Conc vs Time",value= #"\"Do not make graph; Conc vs Time\""

	row+= control_height + 5
	CheckBox STRQuickKill,pos={column_2,row},size={button_width*2,control_height},title="QuickKill Graphs"
	CheckBox STRQuickKill,value= 1
	Button STRPanel_MaskHelper, pos={ column_2 + button_width*2, row}, size={button_width+10, control_height}, title="Mask Panel"
	Button STRPanel_MaskHelper proc=zSTR_Panel_Button
	
	row+= control_height + 5
	CheckBox STRTimeBut,pos={column_2,row},size={button_width*2,control_height},title="Rel. Time [pre11/02]"
	NVAR legacyTime = root:STRPanel_Folder:LegacyWintelTime
	CheckBox STRTimeBut,variable= root:STRPanel_Folder:LegacyWintelTime
	
	row += control_height + 5
	SetVariable STRPanelDestDF,pos={column_2,row},size={text_box_width,control_height},title="Dest DF"
	SetVariable STRPanelDestDF,value= root:STRPanel_Folder:str_panel_df
	
	row += control_height + 5
	
	
	// tail features
	SetVariable STRPanelTailValue, pos={column_2 + button_width/2-2, row}, size={button_width, control_height}, title="Hours"
	SetVariable STRPanelTailValue, value=root:STRPanel_Folder:TailValue, limits={0, inf,0}
	CheckBox STRPanelTailEnable, pos={column_2, row}, size={button_width/2, control_height}, title="tail"
	CheckBox STRPanelTailEnable, variable=root:STRPanel_Folder:TailEnable, proc=zSTR_SetEnableState
	
	PopupMenu STRPanelTailPop, pos={column_2 + button_width + 38, row-2}, size={button_width, control_height}, title=""
	PopupMenu STRPanelTailPop, mode=2, value="Lines;Hours;", proc=zSTR_TailPopProc
	
	PopupMenu STRPanelTailPopAlgo, pos={column_2 + button_width + button_width + 40, row-2}, size={button_width, control_height}, title=""
	PopupMenu STRPanelTailPopAlgo, mode=1, value="Fast;Medium;Exact;"
		
	row = control_height + fileListHeight + 10
	//Button STRCancel,pos={column_b1,row},size={1.5*button_width,control_height},proc=zSTR_Panel_Button,title="Cancel"
	Button STRAll,pos={column_b2+45,row},size={35,control_height},proc=zSTR_Panel_Button,fsize=9,title="<all"

	Button STRLoad,pos={column_b2+45+45,row},size={1.2*button_width,control_height},proc=zSTR_Panel_Button,title="Load"
	Button STRTailLoad,pos={column_b3+45+35,row},size={1.2*button_width,control_height},proc=zSTR_Panel_Button,title="Tail"
	
	zSTR_SetEnableState("",0)
EndMacro

Function STR_PanelWinProc( infoStr )
	String infoStr
	
	String event = StringByKey( "EVENT", infoStr )
	Variable ret_code = 0
	Variable new_how_tall
	Variable bottom_line
	strswitch (event)
		case "kill":
			zSTR_Panel_Button( "STRCancel" )
			break;
		case "resize":
			GetWindow STR_Panel wsize
			new_how_tall = V_bottom - V_top
			bottom_line = new_how_tall - 20
			if( new_how_tall < 205 )
				ListBox STR_LB1,size={155,150}
			else
				ListBox STR_LB1,size={155,bottom_line - 20}
			endif
			
			break;
		default:
			ret_code = 0
	endswitch
	return ret_code
End
Function zSTR_TailPopProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	SetVariable STRPanelTailValue, win=STR_Panel, title=popStr
End

Function zSTR_SetEnableState(ctrl, var)
	String ctrl
	Variable var

	NVAR TailEnable = root:STRPanel_Folder:TailEnable
	
	if( TailEnable )
		Button STRTailLoad, win=STR_Panel, disable=0
		PopupMenu STRPanelTailPop, win=STR_Panel, disable=0
		PopupMenu STRPanelTailPopAlgo, win=STR_Panel, disable=0
		SetVariable STRPanelTailValue, win=STR_Panel, disable=0	
	else
		Button STRTailLoad, win=STR_Panel, disable=2
		PopupMenu STRPanelTailPop, win=STR_Panel, disable=2
		PopupMenu STRPanelTailPopAlgo, win=STR_Panel, disable=2
		SetVariable STRPanelTailValue, win=STR_Panel, disable=1
		
	endif
End
Function zSTR_STC_LoadEP( ctrlName )
	String ctrlName
	
	// This function is the entry point for numerous possibiilities.  
End
Function zSTR_Panel_Button(ctrlName) : ButtonControl
	String ctrlName
	// Handles STRPath, STRCancel and STRLoad

	// 11/2003 this function has been updated to handle stc files also.  Throws all load procery to the zSTR_STC_LoadEP function
	
	SVAR str_panel_prefix=root:STRPanel_Folder:str_panel_prefix
	SVAR str_panel_path=root:STRPanel_Folder:str_panel_path
	SVAR str_panel_df=root:STRPanel_Folder:str_panel_df
	Wave/T str_files_w=root:STRPanel_Folder:str_files_w
	Wave str_loadfile_w=root:STRPanel_Folder:str_loadfile_w
	
	String file_list, path_list
	Variable idex
	Variable tempVal, tempVal2
	if( cmpstr( ctrlName, "STRPath" ) == 0 )
		path_list = PathList( "*", ";", "" ); 
		if( WhichListItem( "LoadSTRPanelPath", path_list ) == -1 )
			// we've never been here before
			NewPath/O/Z/Q LoadSTRPanelPath, "c:tdlwintel:data"
		endif
		NewPath/O/M="Select folder where str files are located"/Q LoadSTRPanelPath
		PathInfo LoadSTRPanelPath
		str_panel_path = s_path
		printf "Building file list in folder %s for files ... [str] - ", str_panel_path
		file_list = IndexedFile( LoadSTRPanelPath, -1, ".str" )
		tempVal = ItemsInList( file_list )
		printf "(%d) and [stc] -", tempVal;
		file_list = file_list + ";" + IndexedFile( LoadSTRPanelPath, -1, ".stc" )
		tempVal2 = ItemsInList( file_list )
		printf "(%d) and [stc] // Total Files: %d\r", tempVal2 - tempVal, tempVal2;

		Redimension/N=0 str_files_w
		
		if( strlen( file_list ) > 0 )
			idex = 0
			do
				AppendString( str_files_w, StringFromList( idex, file_list ))
				idex += 1
			while( idex < ItemsInList( file_list )	)
			Redimension/N=(numpnts(str_files_w)) str_loadfile_w
			ListBox STR_LB1 disable=0
		else
			Redimension/N=1 str_files_w, str_loadfile_w
			str_files_w[0] = "No STR files here"
			//str_loadfile_w = 0
			ListBox STR_LB1, disable=0
		endif
	endif
	// Either other button is leading to a looping through zSTR_LoadMulti
	// if it was the tail load, variable tail_depressed is set to true and passed...
	Variable tail_depressed = 0
	if( cmpstr( ctrlName, "STRTailLoad" ) == 0 )
		tail_depressed = 1
	endif
	// Note, though it says STRLoad, this is misleading because file may be an stc file.
	if( (cmpstr( ctrlName, "STRLoad" ) == 0) | tail_depressed )
		Variable graph_code
		String path_str, file_str, base_str, dest_DF_str
		// resolve graph_code
		ControlInfo/W=STR_Panel STRPanelGraphPop
		graph_code = v_value - 1 

		path_str = str_panel_path
		base_str = str_panel_prefix
		dest_DF_str = str_panel_df
		if( cmpstr( dest_DF_str, "root" ) == 0 )
			dest_DF_str = ""
		endif
		idex = 0
		do
			if( str_loadfile_w[idex] == 1 )
				file_str = str_files_w[idex]
				zSTR_LoadMulti( path_str, file_str, base_str, dest_DF_str, graph_code, tail_depressed )
			endif
			idex +=1
		while( idex < numpnts( str_files_w ) )
		DoWindow/F STR_Panel
		
	endif
	if( cmpstr( ctrlName, "STRCancel" ) == 0 )
		DoWindow/K STR_Panel
		KillDataFolder root:STRPanel_Folder
		setdatafolder root:
	endif
	
	if( cmpstr( ctrlName, "STRPanel_MaskHelper" ) == 0 )
		mSTR_Init();
		mSTR_Panel();
		Execute("mSTR_LiveMaskWin();") 
	endif
	if( cmpstr( ctrlName, "STRAll" ) == 0 )
		str_loadfile_w = 1
	endif
End
Function zSTR_LoadMulti( path_str, file_str, base_str, dest_DF_str, graph_code, tail_depressed )
	String path_str, file_str, base_str, dest_DF_str
	Variable graph_code, tail_depressed
	
	// this function does need to account for the possibility of tail loading
	// this function splits load exectution of STR or STC also
	// looping is handled by the caller though...
	
	Variable fileType = -1
	Variable STR_Type = 1
	Variable STC_Type = 2
	
	String extension = lowerstr( GetFileExtensionFromFileOrFP( file_str ) )
	String saveFolder = GetDataFolder(1)
	String LoadType, LoadSpeed, TailToken
	ControlInfo/W=STR_Panel STRPanelTailPopAlgo
	LoadSpeed = S_Value
	ControlInfo/W=STR_Panel STRPanelTailPop
	TailToken = S_Value
	NVAR TailValue = root:STRPanel_Folder:TailValue
	NVAR AutoNameAndGo = root:STRPanel_Folder:AutoNameAndGo
	SVAR str_panel_prefix=root:STRPanel_Folder:str_panel_prefix

	String useBase_str = base_str
	String FormatStr, justLoadedList
	sprintf LoadType, "%s-%s", extension, LoadSpeed
	String FullPathFile =  TackSubFileOrFolderOntoPath( path_str, file_str )
	String ufile_str, mappedList
	Variable idex = 0, count
	Variable uTailValue
	strswitch( extension )
		case "str":
			if( AutoNameAndGo )
				str_panel_prefix = "str"
				useBase_str = str_panel_prefix
			endif
			FormatStr = TDLCore_STRFormatStr()
			// two buttons dictate load behavior -- if tail_depressed, we call the out and concatenate method
			if( tail_depressed )
				uTailValue = TailValue // leave TailValue unchanged
			else
				uTailValue = -1 // set TailValue to negative one which will cause tail load to just load all
				TailToken = "Lines"
				LoadType = "str-Fast"
			endif
			
			// THIS IS THE MAIN CALL TO STR LOAD -- all loading goes through 'tail' load whether it
			// is for whole file or not
			// Step One get the data into this folder // Step Two will be to concatenate out to the destination
			SetDataFolder root:; MakeAndOrSetDF( "Tail_STR_Load" )
			KillWavesWhichMatchStr( "*" )
			justLoadedList = TDLCore_TailLoad( LoadType, TailToken, uTailValue, FormatStr, FullPathFile )
			mappedList = TDLCore_MapLocalListToFinal( usebase_str, dest_DF_str, justLoadedList )
			TDLCore_DrawSTRGraph( mappedList, dest_DF_str, usebase_str )
			SetDataFolder $saveFolder
			break;
		case "stc":
			if( AutoNameAndGo )
					str_panel_prefix = "stc"
				useBase_str = str_panel_prefix

			endif
			SetDataFolder root:; MakeAndOrSetDF( "Tail_STC_Load" )
			KillWavesWhichMatchStr("*")
			ufile_Str = zSPE2_JustFileFromFull( FullPathFile )
			String parameterList = zSTC_GetHeaderLine( FullPathFile)
			if( strsearch( parameterList, "FILE", 0 ) == -1 )
				FormatStr = zSTC_MakeFormatStrFromList( parameterList )
				justLoadedList = TDLCore_TailLoad( LoadType, TailToken, uTailValue, FormatStr, FullPathFile )
				mappedList = TDLCore_MapLocalListToFinal( usebase_str, dest_DF_str, justLoadedList )
				TDLCore_DrawSTCGraph( mappedList, dest_DF_str, usebase_str )
				SetDataFolder $saveFolder
			else
				// error
			endif
			// convert paramter list to preprended stcL_ wavenames in format string
			
			break;
		default:
			printf "zSTR_LoadMulti fails to recognize file type %s from %s\\%s\r", extension, path_Str, file_str
	endswitch
End
Function TDLCore_DrawSTRGraph( mappedList, dest_DF_str, base_str )
	String mappedList, dest_DF_str, base_str

	String this_winName
	sprintf this_winName, "STR_%s_Graph", base_str
	Variable colon_dex, jdex, jcount
	String this_wave
	String first_wave, ax_name
	DoWindow $this_winName
	if( V_Flag )
		DoWindow/F $this_WinName
	else
		Variable left = 5, up = 200, right = 300, down = 360 
		Variable killer = 0
		ControlInfo/W=STR_Panel STRQuickKill
		killer = v_value

		display/W=(left,up,right,down)/K=(killer) as this_winName
		
		DoWindow/C $this_winName
		Execute( "HandyGraphButtons()" )
		Variable idex = 0, count = ItemsInLIst( mappedList )
		if( count > 0 )
			first_wave = StringFromList( idex, mappedList )
			if( strsearch( lowerStr( first_wave ), "time", 0 ) == -1 )
				printf "Warning in TDLCore_DrawSTRGraph -- first wave does not have 'time'\r"
			endif
			idex += 1
			do
				this_wave = StringFromList( idex, mappedList )
			
				Wave/Z x_w = $first_wave
				Wave/Z y_w = $this_wave
				
				jdex = strlen( this_wave ) - 1
				colon_dex = 0
				do
					if( cmpstr( this_wave[jdex], ":" ) == 0 )
						colon_dex = jdex
						jdex = 0
					endif
					jdex -=1
				while( jdex > 0 )
				
				if( colon_dex == 0 )
					sprintf ax_name, "%s_ax", this_wave[colon_dex, strlen(this_wave)-1]
				else
					sprintf ax_name, "%s_ax", this_wave[colon_dex+1, strlen(this_wave)-1]
				endif
				if( WaveExists( x_w ) + WaveExists( y_w ) == 2 )
					AppendToGraph/L=$ax_name y_w vs x_w
				endif
				idex += 1
			while( idex < count )
			StackAllAxes("", 2, 2); PrimaryColors("")
		endif
	endif
End

Function TDLCore_DrawSTCGraph( mappedList, dest_DF_str, base_str )
	String mappedList, dest_DF_str, base_str

	String this_winName
	sprintf this_winName, "STC_%s_Graph", base_str
	Variable colon_dex, jdex, jcount
	String this_wave
	String first_wave, ax_name
	String trace_list, this_trace, hit_list, this_hit_str
	
	DoWindow $this_winName
	if( V_Flag )
		DoWindow/F $this_WinName
	else
		Variable left = 15, up = 210, right = 310, down = 370 
		Variable killer = 0
		ControlInfo/W=STR_Panel STRQuickKill
		killer = v_value

		display/W=(left,up,right,down)/K=(killer) as this_winName
		DoWindow/C $this_winName
		Execute( "HandyGraphButtons()" )

		Variable idex = 0, count = ItemsInLIst( mappedList )
		if( count > 0 )
			first_wave = StringFromList( idex, mappedList )
			if( strsearch( lowerStr( first_wave ), "time", 0 ) == -1 )
				printf "Warning in TDLCore_DrawSTCGraph -- first wave does not have 'time'\r"
			endif
			idex += 1
			do
				this_wave = StringFromList( idex, mappedList )
			
				Wave/Z x_w = $first_wave
				Wave/Z y_w = $this_wave
				
				jdex = strlen( this_wave ) - 1
				colon_dex = 0
				do
					if( cmpstr( this_wave[jdex], ":" ) == 0 )
						colon_dex = jdex
						jdex = 0
					endif
					jdex -=1
				while( jdex > 0 )
				
				if( colon_dex == 0 )
					sprintf ax_name, "%s_ax", this_wave[colon_dex, strlen(this_wave)-1]
				else
					sprintf ax_name, "%s_ax", this_wave[colon_dex+1, strlen(this_wave)-1]
				endif
				if( WaveExists( x_w ) + WaveExists( y_w ) == 2 )
					AppendToGraph/L=$ax_name y_w vs x_w
				endif
				idex += 1
			while( idex < count )
			StackAllAxes("", 2, 2); PrimaryColors("")
			
		endif
	endif

	// modifications thereafter
	hit_list = "status;byte;spefile;lw_"
	
	for( idex = 0; idex < ItemsInList( hit_list ); idex += 1 )
		this_hit_str = StringFromList( idex, hit_list )
		trace_list = TraceNameList( "", ";", 1)

		for( jdex = 0; jdex < ItemsInList( trace_list ); jdex += 1 )
			this_trace = StringFromLIst( jdex, trace_list )
			if( strsearch( lowerstr( this_trace), this_hit_str, 0 ) != -1 )
				// it is in there somewhere -- lets kill it
				RemoveFromGraph/Z $this_trace
			endif
		endfor
	endfor
	StackAllAxes("", 2, 2); PrimaryColors("")
	ModifyGraph margin(left)=108
	trace_list = TraceNameList( "", ";", 1)
	Label bottom " "
	for( idex = 0; idex < ItemsInList( trace_list ); idex += 1 )
		this_trace = StringFromList( idex, trace_list )
		strswitch (this_trace)
			case "stc_Range_F_1_L_1":
				ModifyGraph axisEnab(stc_Range_F_1_L_1_ax)={0,0.15};DelayUpdate
				ModifyGraph freePos(stc_Range_F_1_L_1_ax)=0;DelayUpdate
				Label stc_Range_F_1_L_1_ax "F1"
				ModifyGraph rgb(stc_Range_F_1_L_1)=(65535,0,0)
				break;
			case "stc_Range_F_1_L_2":
				ModifyGraph axisEnab(stc_Range_F_1_L_2_ax)={0,0.15};DelayUpdate
				ModifyGraph freePos(stc_Range_F_1_L_2_ax)=55;DelayUpdate
				Label stc_Range_F_1_L_2_ax "F1"
				ModifyGraph rgb(stc_Range_F_1_L_2)=(1,12815,52428)
				break;
			case "stc_Range_F_2_L_1":
				ModifyGraph axisEnab(stc_Range_F_2_L_1_ax)={0.17,0.32};DelayUpdate
				ModifyGraph freePos(stc_Range_F_2_L_1_ax)=0;DelayUpdate
				Label stc_Range_F_2_L_1_ax "F2"	
				ModifyGraph axRGB(stc_Range_F_2_L_1_ax)=(65535,32768,32768);DelayUpdate
				ModifyGraph tlblRGB(stc_Range_F_2_L_1_ax)=(65535,32768,32768);DelayUpdate
				ModifyGraph alblRGB(stc_Range_F_2_L_1_ax)=(65535,32768,32768)
				ModifyGraph rgb(stc_Range_F_2_L_1)=(65535,32768,32768)
				break;
			case "stc_Range_F_2_L_2":
				ModifyGraph rgb(stc_Range_F_2_L_2)=(32768,40777,65535)
				ModifyGraph axisEnab(stc_Range_F_2_L_2_ax)={0.17,0.32};DelayUpdate
				ModifyGraph freePos(stc_Range_F_2_L_2_ax)=55;DelayUpdate
				ModifyGraph axRGB(stc_Range_F_2_L_2_ax)=(32768,40777,65535);DelayUpdate
				ModifyGraph tlblRGB(stc_Range_F_2_L_2_ax)=(32768,40777,65535);DelayUpdate
				ModifyGraph alblRGB(stc_Range_F_2_L_2_ax)=(32768,40777,65535);DelayUpdate
				Label stc_Range_F_2_L_2_ax "F2"
				break;	
			case "stc_Praw" :
				ModifyGraph rgb(stc_Praw)=(0,0,0)
				ModifyGraph axisEnab(stc_Praw_ax)={0.34,0.44},freePos(stc_Praw_ax)=55;DelayUpdate
				ModifyGraph axRGB(stc_Praw_ax)=(0,0,0),tlblRGB(stc_Praw_ax)=(0,0,0);DelayUpdate
				ModifyGraph alblRGB(stc_Praw_ax)=(0,0,0);DelayUpdate
				Label stc_Praw_ax "P"
			case "stc_Traw" :
				ModifyGraph rgb(stc_Traw)=(65535,21845,0)
				ModifyGraph axisEnab(stc_Traw_ax)={0.34,0.44},freePos(stc_Traw_ax)=0;DelayUpdate
				ModifyGraph axRGB(stc_Traw_ax)=(65535,21845,0),tlblRGB(stc_Traw_ax)=(65535,21845,0);DelayUpdate
				ModifyGraph alblRGB(stc_Traw_ax)=(65535,21845,0);DelayUpdate
				Label stc_Traw_ax "T"
				break;
			case "stc_T_Laser_1":
				ModifyGraph axisEnab(stc_T_Laser_1_ax)={0.46,0.56},freePos(stc_T_Laser_1_ax)=0;DelayUpdate
				ModifyGraph axRGB(stc_T_Laser_1_ax)=(39321,1,1);DelayUpdate
				ModifyGraph tlblRGB(stc_T_Laser_1_ax)=(39321,1,1);DelayUpdate
				ModifyGraph alblRGB(stc_T_Laser_1_ax)=(39321,1,1);DelayUpdate
				Label stc_T_Laser_1_ax "T\\Blas\\M"	
				ModifyGraph rgb(stc_T_Laser_1)=(26214,0,0)
				break;
			case "stc_V_Laser_1":
				ModifyGraph axisEnab(stc_V_Laser_1_ax)={0.58,0.68},freePos(stc_V_Laser_1_ax)=0;DelayUpdate
				ModifyGraph axRGB(stc_V_Laser_1_ax)=(65535,0,0);DelayUpdate
				ModifyGraph tlblRGB(stc_V_Laser_1_ax)=(65535,0,0);DelayUpdate
				ModifyGraph alblRGB(stc_V_Laser_1_ax)=(65535,0,0);DelayUpdate
				ModifyGraph rgb(stc_V_Laser_1) = (65535,0,0)
				Label stc_V_Laser_1_ax "V\\Blas\\M"
				break;
			case "stc_T_Laser_2":
				ModifyGraph axisEnab(stc_T_Laser_2_ax)={0.46,0.56},freePos(stc_T_Laser_2_ax)=55;DelayUpdate
				ModifyGraph axRGB(stc_T_Laser_2_ax)=(1,9611,39321);DelayUpdate
				ModifyGraph tlblRGB(stc_T_Laser_2_ax)=(1,9611,39321);DelayUpdate
				ModifyGraph alblRGB(stc_T_Laser_2_ax)=(1,9611,39321);DelayUpdate
				Label stc_T_Laser_2_ax "T\\Blas\\M"	
				ModifyGraph rgb(stc_T_Laser_2)=(1,9611,39321)
				break;
			case "stc_V_Laser_2":
				ModifyGraph axisEnab(stc_V_Laser_2_ax)={0.58,0.68},freePos(stc_V_Laser_2_ax)=55;DelayUpdate
				ModifyGraph axRGB(stc_V_Laser_2_ax)=(1,12815,52428);DelayUpdate
				ModifyGraph tlblRGB(stc_V_Laser_2_ax)=(1,12815,52428);DelayUpdate
				ModifyGraph alblRGB(stc_V_Laser_2_ax)=(1,12815,52428);DelayUpdate
				ModifyGraph rgb(stc_V_Laser_2) = (1,12815,52428)
				Label stc_V_Laser_2_ax "V\\Blas\\M"
				break;
			case "stc_X1" :
				ModifyGraph rgb(stc_X1)=(26214,0,0)
				ModifyGraph axisEnab(stc_X1_ax)={0.7,0.75},freePos(stc_X1_ax)=0;DelayUpdate
				ModifyGraph axRGB(stc_X1_ax)=(26214,0,0),tlblRGB(stc_X1_ax)=(26214,0,0);DelayUpdate
				ModifyGraph alblRGB(stc_X1_ax)=(26214,0,0);DelayUpdate
				Label stc_X1_ax "X"
				break
			case "stc_pos1" :
				ModifyGraph rgb(stc_pos1)=(65535,0,0)
				ModifyGraph axisEnab(stc_pos1_ax)={0.75,0.9},freePos(stc_pos1_ax)=0;DelayUpdate
				ModifyGraph axRGB(stc_pos1_ax)=(65535,0,0),tlblRGB(stc_pos1_ax)=(65535,0,0);DelayUpdate
				ModifyGraph alblRGB(stc_pos1_ax)=(65535,0,0);DelayUpdate
				Label stc_pos1_ax "pos"
				break;
			case "stc_X2" :
				//ModifyGraph rgb(stc_pos1)=(1,12815,52428)
				ModifyGraph rgb(stc_X2)=(1,12815,52428)
				ModifyGraph axisEnab(stc_X2_ax)={0.7,0.75},freePos(stc_X2_ax)=0;DelayUpdate
				ModifyGraph axRGB(stc_X2_ax)=(1,12815,52428),tlblRGB(stc_X2_ax)=(1,12815,52428);DelayUpdate
				ModifyGraph alblRGB(stc_X2_ax)=(1,12815,52428);DelayUpdate
				Label stc_X2_ax "X"
				break
			case "stc_pos2" :
				//ModifyGraph rgb(stc_X1)=(1,3,39321)
				ModifyGraph rgb(stc_pos2)=(1,3,39321)
				ModifyGraph axisEnab(stc_pos2_ax)={0.75,0.9},freePos(stc_pos2_ax)=0;DelayUpdate
				ModifyGraph axRGB(stc_pos2_ax)=(1,3,39321),tlblRGB(stc_pos2_ax)=(1,3,39321);DelayUpdate
				ModifyGraph alblRGB(stc_pos2_ax)=(1,3,39321);DelayUpdate
				Label stc_pos2_ax "pos"
				
		endswitch
	endfor
	
End

// This is the STC file loader. 
Function/T TDLCore_MapLocalListToFinal( base_str, dest_DF_str, justLoadedList )
	String base_str, dest_DF_str, justLoadedList
	
	String mappedToList = ""	
	Variable idex = 0, count = ItemsInList( justLoadedList )
	String this_source, this_sourceSans
	String this_dest
	String saveFolder = GetDataFolder(1)
	SetDataFolder root:; MakeAndOrSetDF( dest_DF_str )
	SetDataFolder $saveFolder
	
	if( count > 0 )
		do
			this_source = StringFromList( idex, justLoadedList )
			if( strsearch( this_source, "strL_", 0 ) != -1 )
				this_sourceSans = this_source[ strlen( "strL_" ) , strlen( this_source ) -1 ]
			else
				if( strsearch( this_source, "stcL_", 0 ) != -1 )
					this_sourceSans = this_source[ strlen( "stcL_" ) , strlen( this_source ) -1 ]
				else				
					this_sourceSans = this_source
				endif
			endif
			
		
			Wave this_w = $this_source
			if( cmpstr( dest_DF_str[strlen(dest_DF_str) -1 ], ":" ) == 0 )
				sprintf this_dest, "%s%s_%s", dest_DF_str, base_str, this_sourceSans
			else
				sprintf this_dest, "%s:%s_%s", dest_DF_str, base_str, this_sourceSans
			endif
			if( strsearch( this_dest, "root", 0 ) == -1 )
				if( cmpstr( this_dest[0], ":" ) == 0 )
					sprintf this_dest, "root%s", this_dest
				else
					sprintf this_dest, "root:%s", this_dest
				endif
			endif
			
			mappedToList = mappedToList + this_dest + ";"
			Wave/Z dest_w = $this_dest
			
			// compare lengths to the time wave
			if(stringmatch(this_dest,"*stc_time"))
				Variable oldTimeCount =0
				Variable FinalTimeCount=0
				if(waveexists(dest_w))
					 oldTimeCount = numpnts(dest_w)
				endif
				FinalTimeCount =oldTimeCount + numpnts(this_w)
			endif
			if(!stringmatch(this_dest,"*stc_time"))
				Variable thisOldTimeCount =0
				Variable thisFinalTimeCount=0
				if(waveexists(dest_w))
					 thisoldTimeCount = numpnts(dest_w)
				endif
				
				if(thisOldTimeCount < oldTimeCount)
					if(!waveexists(dest_w))
						make/n=(oldTimeCount)/O $this_Dest
						wave dest_w = $this_Dest
						dest_w = nan
					else		
						redimension/n=(oldTimeCount) dest_w
						dest_w[oldTimeCount,thisFinalTimeCount-1] = nan
					endif
				elseif(thisOldTimeCount > oldTimeCount)
					redimension/n=(oldTimeCount) dest_w

					Print "Error! old wave", this_dest, "has more points than new wave. Redimensioning. Old data is likely invalid. Try reloading all data"
				endif
			endif
			
			
			if( WaveExists( dest_w ) )
				ConcatenateWaves( this_dest, this_source )
			else
				Duplicate/O this_w, $this_dest
			endif
//			killwaves/z this_w
			
			idex += 1
		while( idex < count )
	endif
	return mappedToList
End
Function zSTR_LoadSTR( path_str, file_str, base_str, dest_DF_str, graph_code )
	String path_str, file_str, base_str, dest_DF_str
	Variable graph_code
	
	String filePath = path_str
	String fileName = file_str
	
	Variable err = 0
	String saveDF = GetDataFolder(1)
	// Now turn attention to baseName and dest_dF task
	if( strlen( dest_DF_str ) == 0 )
		dest_DF_str = "root:"
	endif
	if( DataFolderExists( dest_DF_str ) != 1 )
		// data folder should be created, assumptive, but probably handy for general use
		NewDataFolder $dest_DF_str
	endif
	SetDataFolder $dest_DF_Str
	
	String destTime = UniqueName( base_str + "_time_", 1, 0 )
	String destConc1 = UniqueName( base_str + "_conc1_", 1, 0 )
	String suffix = destConc1[ strlen( base_str + "_conc1_" ), strlen(destConc1) ]
	String destConc2 = base_str + "_conc2_" + suffix
	String destConc3 = base_str + "_conc3_" + suffix
	String destConc4 = base_str + "_conc4_" + suffix
	
	err = zSTR_LoadFile( filePath, fileName, destTime, destConc1, destConc2, destConc3, destConc4 )
	Printf "Data Loaded From %s to Time:%s //Concentration(s):%s", fileName, destTime, destConc1
	if( exists( destConc2 ) )
		printf ", %s", destConc2
	endif
	if( exists( destConc3 ))
		printf ", %s", destConc3
	endif
	if( exists( destConc4 ))
		printf " and %s", destConc4
	endif
	printf " -- into %s\r", dest_DF_Str
	if( graph_code > 0 )
		zSTR_MakeSTRFig( destTime, destConc1, destConc2, destConc3, destConc4 )
	endif
	SetDataFolder $saveDF
	return err
End

Function zSTR_MakeSTRFig( destTime, destConc1, destConc2, destConc3, destConc4 )
	String destTime, destConc1, destConc2, destConc3, destConc4
	
	Wave destTime_w = $destTime
	Wave destConc1_w = $destConc1
	Variable num_concs = 1
	if( exists( destConc2 ) )
		Wave destConc2_w = $destConc2
		num_concs += 1
	endif
	if( exists( destConc3 ) )
		Wave destConc3_w = $destConc3
		num_concs += 1
	endif
	if( exists( destConc4 ) )
		Wave destConc4_w = $destConc4
		num_concs += 1
	endif
	
	String axname = destConc1 +"_ax"
	Variable left = 5, up = 200, right = 300, down = 360 
	Variable killer = 0
	ControlInfo/W=STR_Panel STRQuickKill
	killer = v_value

	display/W=(left,up,right,down)/K=(killer)/L=$axname destConc1_w vs destTime_w
	if( num_concs > 1 )
		axname = destConc2 +"_ax"
		appendtograph/L=$axname destConc2_w vs destTime_w
	endif
	if( num_concs > 2 )
		axname = destConc3 +"_ax"
		appendtograph/L=$axname destConc3_w vs destTime_w
	endif
	if( num_concs > 3 )
		axname = destConc4 +"_ax"
		appendtograph/L=$axname destConc4_w vs destTime_w
	endif
	Label bottom "time"
	
	StackAllAxes( "", 1, 1 )
	PrimaryColors("")

End


// 11/2003 - Change in LoadType
// load type should be three characters, "str" or "stc", then "-" (dash), then "<algorithm string>"
// this is to allow the user choices of fast medium or exact when doing tail loadings...

Function/T TDLCore_TailLoad( LoadType, TailToken, TailValue, FormatStr, FullPathFile )
	String LoadType
	String TailToken
	Variable TailValue
	String FormatStr
	String FullPathFile
	
	// This little potent cocktail of a function is designed to give you the ability to load
	// only the last n lines of FullPathFile
	// the handlers to this function are responsible for setting the datafolder &
	// building the format string.  
	
	// LoadType -- as of the original writing this will be one of "str" or "stc"
	// the main reason it is needed is to tell the loader whether it is 'general' /G aka str
	// or
	// 'delimited' aka "stc" -- hopefully this will be figured out
	// this is now packed with two info's
	// string should be str-fast;str-med;str-exact or stc-fast...
	
	// TailToken
	// must be "lines", "X" -- this describes what TailValue is to be interpreted as
	// ie "X", (datetime - 3 * 3600 ) <- would get the last three hours from 'now'
	// or "lines", 3600 <- would get the last 3600 lines of the file...
	
	// FormatStr -<> this is a pain, the caller needs to know about the data before this function
	// can operate
	
	// FullPathFile is the target
	String LoadedWaves = ""
	Variable start_line
	String line
	Variable start_time, end_time
	Variable meanLineLength, approx_lines_in_file, fileSize, foundFraction, exact_lines_in_file
	Variable refNum
	String algo_Str = LoadType[4, strlen(LoadType)]
	// algo_Str will be one of fast, medium or exact 11/2003
	// fast will never do a linecount
	// exact will always do a linecount
	// medium probably won't do a linecount unless it really needs to
	// fast will not try to be accurate
	// medium will try to be a little more accurate
	// exact will be exact
		
	if( TailValue != -1 )
		//printf "-=-=-=-= Report for Tail Load of %s -=-=-=-=-=-=\r", FullPathFile
	
		Open/R/Z refNum as FullPathFile
		if( V_Flag != 0 )
			printf "%s could not be opened for read-only access\r", FullPathFile; return LoadedWaves
		endif	
		FStatus refNum
		if( V_logEOF  < k_TailSizeFeatherLimit)
			printf "!! Due to file size %d K, Tail load is being overridden and whole file will be loaded\r", Ceil(V_logEOF / 1024)
			start_line = 0
			approx_lines_in_file = 0.1
			TailValue = approx_lines_in_file + 1
		else
			Freadline refNum, line
			Freadline refNum, line
			meanLineLength = MeanFileLineLength( refNum )
			FStatus refNum
			fileSize = v_logEOF; approx_lines_in_file = Floor( fileSize / meanLineLength )
			
			if( cmpstr( LowerStr( algo_str ), "exact" ) == 0 )
				//scx_linecount( FullPathFile ) // Attention User:  If you get an error at this line, it is because you do not have DEFT.xop
				// DEFT.xop needs to be (or a short cut to) in the igor extensions directory.  Igor must be restarted once this has been done.
				NVAR V_FileLines=V_FileLines
				approx_lines_in_file = V_FileLines
			endif
		endif
	else
		start_line = 0
		approx_lines_in_file = 0.1
		TailValue = approx_lines_in_file + 1
	endif	
	strswitch( lowerStr( TailToken ) )
		case "lines":
			strswitch( LowerStr( algo_str ) )
				case "fast":
					start_line = approx_lines_in_file - TailValue
					if( start_line < 0 )
						start_line = 0
					endif
					foundFraction = start_line / approx_lines_in_file
					break;
				case "medium":
					start_line = approx_lines_in_file - TailValue
					if( start_line < 0 )
						start_line = 0
					endif
					foundFraction = start_line / approx_lines_in_file
			
					break;
				case "exact":
					start_line = approx_lines_in_file - TailValue // note that approx IS exact due to the scx_linecount
					break;
			endswitch
			
			break;
		case "X":
			if( fileSize < k_TailSizeFeatherLimit )
				start_line = 0
			else
				foundFraction = BinaryFileSearch( refNum, TailValue );
				if( foundFraction > 0.98 )
					foundFraction = 0.98
				endif
				if( (foundFraction > 0 ) & (foundFraction < 0.02) )
					foundFraction = 0.02
				endif
				start_line = Floor( foundFraction * fileSize / meanLineLength );
			endif
			break;
		default:
			start_line = 0;	
	endswitch
	
	if( start_line < 1 )
		start_line = 0
	endif
	if( start_line == 0 )
		//printf "Load from %s commencing from begining ... \r", FullPathFile
	else
		//printf "Tail Loading from %s {lines %d at %d chars each // line number %d or ~%f...}\r", FullPathFile, approx_lines_in_file, meanLineLength, start_line, foundFraction
	endif
	strswitch( lowerstr(LoadType[0,2]) )
		case "str":
			LoadWave/A/G/B=formatStr/L={0, start_line,0,0,0}/O/Q FullPathFile
			LoadedWaves = S_WaveNames
			printf "\t %d, %s\r", ItemsInList( S_WaveNames), S_WaveNames
			Wave first_w = $(StringByKey("N", StringFromList( 0, formatStr), "=", "," ))
			SetScale/P y, 0, 0, "dat", first_w
			break;
		case "stc":
			if( start_line < 2 )
				start_line = 2
			endif
			LoadWave/A/J/B=formatStr/L={0, start_line,0,0,0}/O/Q FullPathFile
			LoadedWaves = S_WaveNames
			Wave first_w = $(StringByKey("N", StringFromList( 0, formatStr), "=", "," ))
			SetScale/P y, 0, 0, "dat", first_w
			break;
	endswitch
	Return LoadedWaves
End
Constant k_TailSizeFeatherLimit = 40000

Function/T TDLCore_STRFormatStr()

	String formatStr = ""
	formatStr = formatStr + "C=1,T=4,N=strL_source_rtime;"
	formatStr = formatStr + "C=1,T=4,N=strL_mr1;"
	formatStr = formatStr + "C=1,T=4,N=strL_mr2;"
	formatStr = formatStr + "C=1,T=4,N=strL_mr3;"
	formatStr = formatStr + "C=1,T=4,N=strL_mr4;"
	formatStr = formatStr + "C=1,T=4,N=strL_mr5;"
	formatStr = formatStr + "C=1,T=4,N=strL_mr6;"
	formatStr = formatStr + "C=1,T=4,N=strL_mr7;"
	formatStr = formatStr + "C=1,T=4,N=strL_mr8;"
	
	return formatStr
End
Function TDLCore_XToLineNum( refNum, TailValue )
	Variable refNum
	Variable TailValue
	
	Variable line = 0
	
	FStatus refNum
	Variable fileSize = V_logEOF
	if( fileSize < k_TailSizeFeatherLimit )
		line = 0
	else
		Variable foundFraction = BinaryFileSearch( refNum, TailValue );
		Variable meanLineLength = MeanFileLineLength( refNum );
		Variable lineGuess = Floor( foundFraction * fileSize / meanLineLength );
	
		line = lineGuess
	endif
	
	return line
End
// Load str files

// format of an str file...
//5/30/01 1:55:29 PM           50129.67      3074075741.46394 
//0.763890 1.391e2 
//1.764020 1.382e2 
//2.764238 1.508e2

Function zSTR_LoadFile( filePath, fileName, destTime, destConc1, destConc2, destConc3, destConc4 )
	String filePath, fileName
	String destTime, destConc1, destConc2, destConc3, destConc4
	
	Variable begin_time_igor = 0
	String begin_date = "Unk"
	Variable begin_sam = 0
	Variable converted_igorTime = 0
	String packedData = ""
	
	// Step One, make STRLoadPath -- which will be used throughout this function and subordinates
	if( zSTR_MakeAndCheckPath( "STRLoadPath", filePath ) != 1 )
		Printf "Error in STR_LoadFile:  Attempt to make and check path %s failed\r", filePath
		return -1
	endif
	
	// Step Two, get the first line of text and chop it up into the relevent pieces
	packedData = zSTR_GetHeaderLine( fileName, begin_time_igor, begin_date, begin_sam )
	if( cmpstr(stringbykey("FILE",packedData), "Ok" ) == 0 )	
		begin_time_igor = str2num( stringbykey( "IGORTIME", packedData ) )
		begin_sam = str2num( stringbykey("SAM", packedData ) )
		begin_date = stringbykey( "DATE", packedData )
	else
		print "Using zero for start time"
		begin_time_igor = 0
		begin_sam =0
		begin_date = "Unk"
	endif
	
	// Step three, load the data from the file
	zSTR_LoadSTR4Columns( fileName )
	Wave time_w = $"STR_ZeroTime_w"
	NVAR legacyTime = root:STRPanel_Folder:LegacyWintelTime
	if ( legacyTime == 0 )
		// do nothing but check and make sure
		if( time_w[1] < 60 )
			printf "Warning, Absolute Time was specified, but first time is only %5.2f\r" time_w[0]
			printf "Loading without date time offset; but if you want it Check the Checkbox Rel. Time\r"
		endif
	else
		time_w += begin_time_igor
	endif
	
	setscale y, 0, 1, "dat", time_w
	Duplicate/O time_w, $destTime
	
	Wave col1_w = $"STR_Column1_w"
	Duplicate/O col1_w, $destConc1
	
	if( exists( "STR_Column2_w" ) )
		Wave col2_w = $"STR_Column2_w"
		Duplicate/O col2_w, $destConc2
	endif
	if( exists( "STR_Column3_w" ) )
		Wave col3_w = $"STR_Column3_w"
		Duplicate/O col3_w, $destConc3
	endif
	if( exists( "STR_Column4_w" ) )
		Wave col4_w = $"STR_Column4_w"
		Duplicate/O col4_w, $destConc4
	endif
	KillWaves/Z time_w, col1_w, col2_w, col3_w, col4_w
End

Function zSTR_MakeAndCheckPath( dest_pathName, path_str )
	String dest_pathName, path_str
	NewPath/Q/O/Z $dest_pathName, path_str
	PathInfo $dest_pathName
	return v_flag
End

Function zSTR_LoadSTR4Columns( file_str )
	String file_str

	String pathName = "STRLoadPath"
	String format_str = "C=1,F=0,T=4,N=STR_ZeroTime_w;"
	format_str += "C=1,F=0,T=4,N=STR_Column1_w;"
	format_str += "C=1,F=0,T=4,N=STR_Column2_w;"
	format_str += "C=1,F=0,T=4,N=STR_Column3_w;"
	format_str += "C=1,F=0,T=4,N=STR_Column4_w;"
	Variable start_line, end_line, num_points

	start_line = 2

	// infor for /L LoadWave flag
	// /L={nameLine, firstLine, numLines, firstColumn, numColumns }
	
	LoadWave/D/K=1/G/B=format_str/L={0, start_line, 0, 0, 0 }/P=$pathName/Q/A/O file_str 
	if( v_flag > 0 )
		return 1
	else
		return -1
	endif
End


Function/T zSTR_GetHeaderLine( file_str, begin_time_igor, begin_date, begin_sam )
	String file_str
	Variable begin_time_igor
	String begin_date
	Variable begin_sam

	String pathName = "STRLoadPath"
	Variable refNum, line, return_value
	String buffer, date_substr, sam_substr, igor_time_substr, ret_str
	Variable buflen
	
	Open/Z/R/P=$pathName refNum as file_str
	if( V_flag == 0 )
		// then file was opened
		FReadLine refNum, buffer
		Close refNum
		if( strlen(buffer) == 0 )
			return "FILE:Null"
		endif
		Variable locOfTime = 0
		locOfTime = strsearch( buffer, "PM", 0 )
		if( locOfTime == -1 )
			locOfTime = strsearch( buffer, "AM", 0 )
		endif
		if( locOfTime == -1 )
			printf "no AM or PM in %s\rcontinuing...\r", buffer
			locOfTime = 17 // this is a guess 
		endif
		buflen = strlen(buffer)
		
		date_substr = buffer[ 0, locOfTime + 2  ]
		sam_substr = buffer[ locOfTime + 2, buflen - 20 ]
		igor_time_substr = buffer[ buflen - 20, buflen ]

		
		sprintf ret_str, "FILE:Ok;DATE:%s;SAM:%g;IGORTIME:%20.6f", date_substr, str2num(sam_substr), str2num( igor_time_substr )
	else
		Printf "In GetSTRHeaderLine, couldn't find %s:%s\r", pathName, file_str
		return "FILE:Bad"
	endif
	return ret_str
End

	
// returns file:null or file:bad in case of error
// returns list of paramters in file as semicolon separated list
// added ',' delimiting capability
Function/T zSTC_GetHeaderLine( file_str)
	String file_str

	Variable begin_time_igor
	String begin_date
	Variable begin_sam
	
	Variable refNum, line, return_value
	String buffer, date_substr, sam_substr, igor_time_substr, ret_str
	Variable buflen
	String element
	Variable element_len
	
	String line_one, line_two, line_three
	
	Variable month=0, day=0, year=0, hour=0, minute=0, second=0
	String ampm = ""
	Variable sam=0, igor_datetime=0
	String list = "", datetime_str
	Open/Z/R refNum as file_str
	if( V_flag == 0 )
		// then file was opened
		FReadLine refNum, line_one
		FReadLine refNum, line_two
		FReadLine refNum, line_three
		
		Close refNum
		
		// as of 12/2003 the line_one looks like a human readable datetime, sam and igor time
		// line_two looks like the field names
		// line_three looks like data
		
		if( strlen( line_one ) != 0 )
			// line_one ok
			sscanf line_one, "%d/%d/%d %d:%d:%d %s %f %f", month, day, year, hour, minute, second, ampm, sam, igor_datetime
			// this is essentially done without
		else
			return "FILE:Null"
		endif
		Variable idex = 0
		if( strlen( line_two ) != 0 )
			buffer = line_two
			Variable commaDelim = 0
			if( strsearch( buffer, ",", 0 ) != -1 )
				commaDelim = 1
			endif
			
			if( commaDelim )
				idex = 0; Variable count = ItemsInList( buffer, "," )
				if( count > 0 )
					do
						element = StringFromList( idex, buffer, "," )
						if( cmpstr( element[0], " " ) == 0 )
							element = element[1, strlen(element) -1 ]
						endif
						if( cmpstr( element[0], " " ) == 0 )
							element = element[1, strlen(element) -1 ]
						endif
						if( cmpstr( element[0], " " ) == 0 )
							element = element[1, strlen(element) -1 ]
						endif
						if( cmpstr( element[0], " " ) == 0 )
							element = element[1, strlen(element) -1 ]
						endif
						
						if( (cmpstr( element[ strlen(element) - 1], "\r" ) == 0) & (strlen(element) > 2 ) )
							element = element[0, strlen(element) - 2]
						endif
						if( (cmpstr( element[ strlen(element) - 1], " " ) == 0) & (strlen(element) > 2 ) )
							element = element[0, strlen(element) - 2]
						endif						
						list = list + CleanUpName(element,0) + ";"
						idex += 1
					while( idex < count )
				endif
			else
				do
					sscanf buffer, "%s", element
					element_len = strlen( element )
					if( element_len > 0 )
						list = list + element + ";"
						element_len = strsearch( buffer, element, 0 )
						buffer = buffer[element_len + strlen(element), strlen(buffer)]
					else
						if( strlen(buffer) <= 1 )
							buffer = ""
						endif
					endif
					
				while( strlen(buffer) > 0 )
			endif
			return list
		else
			return "FILE:Null"
		endif
		
	else
		
		Printf "In GetSTRHeaderLine, couldn't find \"%s\"\r", file_str
		return "FILE:Bad"
	endif
	return ret_str
End

Function/T zSTC_MakeFormatStrFromList( parameterList )
	String parameterList
	SVAR LoadedWaveNamesSTC = root:STRPanel_Folder:LoadedWaveNamesSTC
	SVAR LoadedWaveNamesSTR = root:STRPanel_Folder:LoadedWaveNamesSTR
	Variable idex = 0, count = ItemsInList( parameterList )
	String this_p
	String format_str = ""
	String this_format_element = ""
	if( count > 0 )
		do
			this_p = StringFromList( idex, parameterList )
			sprintf this_format_element, "C=1,N=stcL_%s,T=4", this_p
			format_str = format_str + this_format_element + ";"
			idex += 1
		while( idex < count )
	endif
	
	LoadedWaveNamesSTC = ""
	variable i
	for(i=0;i<itemsinlist(parameterList);i+=1)
		LoadedWaveNamesSTC += "stc_"+stringFromList(i,parameterList)+";"
	endfor

	return format_str
End
////////////////////////////////////////////////////////////////////// mSTR is the prefix for the mask family of functionality
///////////////////////////////////////////////////////////////////// valve mask maker
StrConstant ks_mSTR_Window = "Mask_str_stc"


// Manifest names of tabs
Constant k_InputTab = 0
Constant k_ValveMethTab = 1
Constant k_TimeMethTab = 2
Constant k_OutputTab = 3

StrConstant ks_mSTRFolder = "root:mSTR_Folder"
StrConstant ksb_TabOne="Input"
StrConstant ksb_TabTwo="Valve_Method"
StrConstant ksb_TabThree="Time_Method"
StrConstant ksb_TabFour="Output"
StrConstant ksb_TabList = "Input;Valve Method;Time Method;Output"

/////////////////////////////////////////////////// This is the main function where all of the goodies get drawn to
///////////////////////////// just pile them on and the tabber will deal with the correct 
////////////// the controls must be NAMED appropriately though.  en_; re_; di_, pr_ etc...
// Change tabs. Controls to be shown only for a hidden tab start with
// two letters and an underscore, where the two letters match the
// first two letters of the tab for which it should be shown.  For instance,
// a control called wa_Stevie should only be shown for the "watch" tab,
// a control called li_Jimi should only be shown for the "live pixels" tab,
// and a control called Kenny should be left alone when changing tabs.
//
// Here is where we hilite the appropriate controls
Function mSTR_AutoTabProc( name, tab )
	String name
	Variable tab

	SVAR msg=$(ks_mSTRFolder+":msg" )
	
	// Get the name of the current tab
	ControlInfo $name
	String tabStr = S_Value
	sprintf msg, "Switch to %s", tabStr	
	tabStr = tabStr[0,1]
	
	// Get a list of all the controls in the window
	Variable i = 0
	String all = ControlNameList( "" )
	String thisControl
	
	do
		thisControl = StringFromList( i, all )
		if( strlen( thisControl ) <= 0 )
			break
		endif
		
		// Found another control.  Does it start with two letters and an underscore?
		if( !CmpStr( thisControl[2], "_" ) )
			// If it matches the current tab, show it.  Otherwise, hide it
			if( !CmpStr( thisControl[0,1], tabStr ) )
				mSTR_ShowControl( thisControl, 0 )
			else
				mSTR_ShowControl( thisControl, 1)
			endif
		endif
		i += 1
	while( 1 )
	
	// Some controls on the new tab might be supposed to be hidden.  Here
	// is where we call the proc to set their hidden state, and do any other
	// tab-specific adjustments
	ControlInfo/W=Mask_str_stc	in_Method_pop
	Variable method_chosen = v_value, idex, count, this_state
	String controls_list
	// method_chosen = 1 means valve method is desired
	// method_chosen = 2 means time method is desired
	switch( tab )
		case k_InputTab:
			//SetVariable en_entrySV activate
				
			break
		
		case k_ValveMethTab:
			controls_list = ControlNameList( "Mask_str_stc", ";", "va_*" ); count = ItemsInList( controls_list )
			if( method_chosen == 1 )
				this_state = 0
			endif
			if( method_chosen == 2 )
				this_state = 2
			endif
			
			for( idex = 0; idex < count; idex += 1 )
				mSTR_BlackGreyControl( StringFromList( idex, controls_list) , this_state )
			endfor
			break
		
		case k_TimeMethTab:
			controls_list = ControlNameList( "Mask_str_stc", ";", "ti_*" ); count = ItemsInList( controls_list )
			if( method_chosen == 2 )
				this_state = 0
			endif
			if( method_chosen == 1 )
				this_state = 2
			endif
			
			for( idex = 0; idex < count; idex += 1 )
				mSTR_BlackGreyControl( StringFromList( idex, controls_list) , this_state )
			endfor
			break
			
			break
		
		case k_OutputTab:
			NVAR trueMarker = root:mSTR_Folder:true_MarkerNum
			PopupMenu ou_TruthMarker_pop mode=(trueMarker+1)
			
			
			break

	endswitch
	mSTR_SaveCurTabNum()
End

// Save the current tab number
Function mSTR_SaveCurTabNum()
	if( !datafolderexists( "root:mSTR_folder" ))
		newdatafolder $"root:mSTR_folder"
	endif
	ControlInfo mainTab
	String cmd
	sprintf cmd, "Variable/G root:mSTR_folder:lastMainTabVal"
	Execute( cmd )
	NVAR lastVal = root:mSTR_folder:lastMainTabVal
	lastVal = V_Value
End	


// Show or hide any kind of control in the top window
Function mSTR_ShowControl( name, disable )
	String name
	Variable disable
	
	// What kind of control is it?
	ControlInfo $name
	Variable type = v_flag
	switch( abs(type) )
		case 1:		// button
			Button $name disable=disable
			break
		
		case 2:		// checkbox
			CheckBox $name disable=disable
			break
		
		case 3:		// popup menu
			PopupMenu $name disable=disable
			break
		
		case 4:
			ValDisplay $name disable=disable
			break
		
		case 5:
			SetVariable $name disable=disable
			break
		
		case 6:
			Chart $name disable=disable
			break
		
		case 7:
			Slider $name disable=disable
			break
		
		case 8:
			TabControl $name disable=disable
			break
		
		case 9:
			GroupBox $name disable=disable
			break
		
		case 10:
			TitleBox $name disable=disable
			break
		
		case 11:
			ListBox $name disable=disable
			break
	endswitch
End
Function mSTR_BlackGreyControl( name, disable )
	String name
	Variable disable
	
	// What kind of control is it?
	ControlInfo $name
	Variable type = v_flag
	switch( abs(type) )
		case 1:		// button
			Button $name disable=disable
			break
		
		case 2:		// checkbox
			CheckBox $name disable=disable
			break
		
		case 3:		// popup menu
			PopupMenu $name disable=disable
			break
		
		case 4:
			ValDisplay $name disable=disable
			break
		
		case 5:
			SetVariable $name disable=disable
			break
		
		case 6:
			Chart $name disable=disable
			break
		
		case 7:
			Slider $name disable=disable
			break
		
		case 8:
			TabControl $name disable=disable
			break
		
		case 9:
			GroupBox $name disable=disable
			break
		
		case 10:
			TitleBox $name disable=disable
			break
		
		case 11:
			ListBox $name disable=disable
			break
	endswitch
End
// Set up and display the prefs dialog.
// The ...Setup() functions can be run before the dialog exists; they
// The ...Redraw() functions actually set the controls, and require the
// dialog to exist
Function mSTR_InitTabs()
	String TabList = ksb_TabList, this_tab, test_funcName
	Variable idex, count = ItemsInList( TabList )
	SVAR msg=$(ks_mSTRFolder+":msg" )
	String cmd
	DoWindow/F $ks_mSTR_Window
	if( !V_Flag )
		// Here is where you might read saved values in from preference files, or
		// otherwise set up the default values that should be shown in the panel.
		// This is only parts that can be done *before* the panel is showing.
		//
		idex = 0
		do	
			this_tab = StringFromList( idex, TabList )
			sprintf test_funcName, "mSTR_TSetup_%s", this_tab
			FUNCREF mSTR_TSetup_Proto f = $test_funcName
			msg = f()		
			idex +=1
		while( idex < count )	

		
		Execute( "mSTR_Panel()" )
		SetWindow kwTopWin, hook=mSTR_KillPanel
		
		
		Variable tab
		NVAR/Z lastTab = root:mSTR_Folder:lastMainTabVal
		if( NVAR_Exists( lastTab ) )
			tab = lastTab
		else
			sprintf cmd ,"Variable/G root:mSTR_Folder:lastMainTabVal = 0"
			Execute( cmd )
			tab = 0
		endif
		
		// Set the tab to the preferred value, and run the tab control proc to show the correct controls
		TabControl mainTab, value=tab
		mSTR_AutoTabProc( "mainTab", tab )
		
	endif
End
Function/T mSTR_TSetup_Proto()
End

Window mSTR_LiveMaskWin() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:mSTR_Folder:
	Display /W=(779,45,1301,466)/K=1  statusW_sans16 vs mSTC_time as "LiveMaskWin"
	AppendToGraph mSTC_mask vs mSTC_time
	AppendToGraph mSTR_mask vs mSTR_time
	AppendToGraph/L=data_ax mSTR_data_raw,mSTR_data_filter vs mSTR_time
	SetDataFolder fldrSav0
	ModifyGraph mode(mSTC_mask)=4,mode(mSTR_mask)=3,mode(mSTR_data_raw)=4,mode(mSTR_data_filter)=4
	ModifyGraph marker(mSTC_mask)=46,marker(mSTR_mask)=5,marker(mSTR_data_raw)=18,marker(mSTR_data_filter)=7
	ModifyGraph lStyle(mSTR_mask)=1,lStyle(mSTR_data_raw)=4,lStyle(mSTR_data_filter)=1
	ModifyGraph rgb(statusW_sans16)=(34952,34952,34952),rgb(mSTR_mask)=(1,16019,65535)
	ModifyGraph rgb(mSTR_data_raw)=(30583,30583,30583),rgb(mSTR_data_filter)=(0,65535,0)
	ModifyGraph tick(left)=2,tick(data_ax)=2
	ModifyGraph mirror=1
	ModifyGraph minor=1
	ModifyGraph lblMargin(bottom)=5
	ModifyGraph standoff=0
	ModifyGraph axOffset(left)=-4.8
	ModifyGraph lblPos(left)=86,lblPos(data_ax)=84
	ModifyGraph lblLatPos(left)=-4,lblLatPos(bottom)=-1,lblLatPos(data_ax)=-3
	ModifyGraph axisOnTop=1
	ModifyGraph btLen(left)=6,btLen(data_ax)=6
	ModifyGraph freePos(data_ax)={0,kwFraction}
	ModifyGraph axisEnab(left)={0,0.25}
	ModifyGraph axisEnab(data_ax)={0.3,1}
	ModifyGraph dateInfo(bottom)={0,1,0}
	Label left "mask"
	Label bottom "str_source_rtime or stc_time"
	Label data_ax "raw data"
	SetAxis/A/N=1 left
	SetAxis/A/N=1 data_ax
	Cursor/P/A=0 A mSTR_data_raw 0;Cursor/P B mSTR_mask 0
	ShowInfo
	Legend/C/N=text0/J/F=0/B=1/A=MC/X=36.72/Y=-29.50 "\\s(statusW_sans16) valves\r\\s(mSTC_mask) STC mask\r\\s(mSTR_mask) STR mask"
	ControlBar 22
	Button tog_left,pos={5,0},size={55,22},proc=UsefulButtons,title="<pan left<"
	Button tog_right,pos={60,0},size={55,22},proc=UsefulButtons,title=">pan right>"
	Button widen,pos={115,0},size={55,22},proc=UsefulButtons,title="<widen>"
	Button scale_y,pos={170,0},size={55,22},proc=UsefulButtons,title="Scale Y"
	Button removeHGB,pos={235,0},size={65,22},proc=UsefulButtons,title="Remove"
	Button removeHGB,valueColor=(65535,0,0)
EndMacro

Function/T mSTR_GetSTCTimeList()
	
	Variable useFilter = 0
	NVAR/Z stc_time_filter = root:mSTR_Folder:stc_time_defaultFilter
	if( NVAR_Exists( stc_time_filter ) )
		useFilter = stc_time_filter
	endif
	
	String return_str 
	if( useFilter )
		return_str = WaveList( "*time*", ";", "" )
	else
		return_str = WaveList( "*", ";", "" )
	endif
	if( ItemsInList( return_str ) == 0 )
		return "no waves found"
	else
		return "not_selected;" + return_str
	endif
End
Function/T mSTR_GetSTRTimeList()
	
	Variable useFilter = 0
	NVAR/Z str_time_filter = root:mSTR_Folder:str_time_defaultFilter
	if( NVAR_Exists( str_time_filter ) )
		useFilter = str_time_filter
	endif
	
	String return_str 
	if( useFilter )
		return_str = WaveList( "*time*", ";", "" )
	else
		return_str = WaveList( "*", ";", "" )
	endif
	if( ItemsInList( return_str ) == 0 )
		return "no waves found"
	else
		return "not_selected;" + return_str
	endif
End
Function/T mSTR_GetSTRDataList()
	
	Variable useFilter = 0
	NVAR/Z str_data_filter = root:mSTR_Folder:str_data_defaultFilter
	if( NVAR_Exists( str_data_filter ) )
		useFilter = str_data_filter
	endif
	
	String return_str 
	if( useFilter )
		
		ControlInfo /W=Mask_str_stc in_str_time_pop
		String timeStr = S_value
		Wave/z timewave = $timeStr
		if(waveexists(timewave))
			variable rows = numpnts(timewave)
			String rowString = ""
			sprintf rowstring "MINROWS:%d,MAXROWS:%d", rows, rows // this required for long waves where num2str does not print enough precision
			return_str = WaveList( "*", ";", rowstring)
			
			variable item=0
			return_str = removefromlist(timeStr, return_Str, ";")
			do
				item = findListItem("*STC*", return_str, ";")
				if(item>=0 && item< itemsinlist(return_str))
					return_str = removelistitem(item, return_Str, ";")
				endif
			while (item>=0)
			
		else
			return_str = WaveList( "*", ";", "" )
		endif
		
	
	else
		return_str = WaveList( "*", ";", "" )
	endif
	if( ItemsInList( return_str ) == 0 )
		return "no waves found"
	else
		return "not_selected;" + return_str
	endif
End
Function mSTR_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			String ctrlName = ba.ctrlName
			if( cmpstr( ctrlName, "ou_CopyMask" ) == 0 )
				mSTR_CopyMask2Root()
			endif
			if( cmpstr( ctrlName, "va_calc_mask" ) == 0 || cmpstr(ctrlName,"ti_calc_mask")==0)
				mSTR_CalculateMask()
			endif
			if( cmpstr( ctrlName, "ou_CalculateEdges") ==0 )
				mstr_CalculateEdges()
			endif
			break
	endswitch

	return 0
End
Function mSTR_SVProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			if( cmpstr( sva.ctrlName, "ou_DestMask_sv" ) == 0 )
				SVAR destStr = root:mSTR_Folder:gui_target_mask_name
				deststr = CleanUpName( destStr, 0 )
			endif
			break
	endswitch

	return 0
End

Function mSTR_CheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba
	
	
	switch( cba.eventCode )
		case 2: // mouse up
			String ctrlName = cba.ctrlName
			Variable checked = cba.checked

				
			if( cmpstr( ctrlName, "ou_WriteMarkerWaves" ) == 0 )
				NVAR writeMarkerWave = root:mSTR_Folder:write_marker_waves
				Variable dis
				if( writeMarkerWave )
					dis = 0
				else
					dis = 2
				endif
				PopupMenu ou_TruthMarker_pop disable=dis
				CheckBox ou_WriteFalseMarkers disable=dis
				PopupMenu  ou_FalseMarker_pop disable=dis
				NVAR writeFalseMarkers = root:mSTR_Folder:write_marker_forFalse
				if( writeMarkerWave & (writeFalseMarkers==0) )
					PopupMenu ou_FalseMarker_pop disable = 2
				endif
			endif
			if( cmpstr( ctrlName, "ou_WriteFalseMarkers" ) == 0 )
				NVAR writeMarkerWave = root:mSTR_Folder:write_marker_waves
				if( writeMarkerWave )
					dis = 0
				else
					dis = 2
				endif
				PopupMenu ou_TruthMarker_pop disable=dis
				CheckBox ou_WriteFalseMarkers disable=dis
				PopupMenu ou_FalseMarker_pop disable=dis
				NVAR writeFalseMarkers = root:mSTR_Folder:write_marker_forFalse
				if( writeMarkerWave & (writeFalseMarkers==0) )
					PopupMenu ou_FalseMarker_pop disable = 2
				endif
			endif
				
					
			NVAR liveMode = root:mSTR_Folder:liveMode
			if(liveMode)
				Execute/P/Q ("mSTR_CalculateMask()") // this needs to be delayed because 
				// the checkbox wave that's used to make the masks is a := wave,
				// and doesn't update until after function is done 

			endif

			break
			
			
			
	endswitch

	return 0
End

Function mSTR_SetEdgesProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
			break
		case 2: // Enter key
			NVAR liveMode = root:mSTR_Folder:liveMode
			if(liveMode)
				Execute ("mSTR_CalculateMask()") // this needs to be delayed because 
				// the checkbox wave that's used to make the masks is a := wave,
				// and doesn't update until after function is done 

			endif
		
			break
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function mSTR_PopProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			Variable wavepop = 0
			NVAR liveMode = root:mSTR_Folder:liveMode

			if( (cmpstr( popStr, "not_selected" ) == 0) | (cmpstr(popStr, "no waves found" ) == 0 ) )
				// we need to just pass on processing
				NVAR status_var = root:mSTR_folder:stc_status_w_Exists; status_var = 0

			else
				// we'll assume a valid wave was found
				if( cmpstr( pa.ctrlName, "in_stc_time_pop" ) == 0 )
					Wave/Z w = $popStr
					NVAR g_pnts = root:mSTR_Folder:stc_time_pnts
					wavepop = 1
				endif
				if( cmpstr( pa.ctrlName, "in_str_time_pop" ) == 0 )
					Wave/Z w = $popStr
					NVAR g_pnts = root:mSTR_Folder:str_time_pnts
					wavepop = 2
				endif
				if( cmpstr( pa.ctrlName, "in_str_data_pop" ) == 0 )
					Wave/Z w = $popStr
					NVAR g_pnts = root:mSTR_Folder:str_data_pnts
					wavepop = 3
				endif
				if( wavepop != 0 )
					if( WaveExists( w ) )
						g_pnts = numpnts( w ); sprintf root:mSTR_folder:msg, "%s has %u points", NameOfWave(w), g_pnts
						switch( wavepop )
							case 1:
								Duplicate/O w, root:mSTR_Folder:mSTC_time
								mSTR_ProcSTCTimePick(NameOfWave( w ))
								break;
							case 2:
								Duplicate/O w, root:mSTR_Folder:mSTR_time
							
								break;
							case 3:
								Duplicate/O w, root:mSTR_Folder:mSTR_data_raw
								Duplicate/O w, root:mSTR_Folder:mSTR_data_filter
								Wave d = root:mSTR_Folder:mSTR_data_filter
								d = nan
								
								break;
						endswitch
					else
						sprintf root:mSTR_Folder:msg, "Wave not found? QQ"
					endif
				endif
			endif
			Wave mSTC_time = root:mSTR_Folder:mSTC_time
			Wave mSTC_mask = root:mSTR_Folder:mSTC_mask
			Wave mSTR_data_raw = root:mSTR_Folder:mSTR_data_raw
			Wave mSTR_data_filter = root:mSTR_Folder:mSTR_data_filter
			Wave mSTR_mask = root:mSTR_Folder:mSTR_mask
			
			if( cmpstr( pa.ctrlName, "va_Match_pop" ) == 0 )
				if(liveMode)
					Execute ("mSTR_CalculateMask()")
				endif			
			endif
			
			if( cmpstr( pa.ctrlName, "ou_TruthMarker_pop" )== 0 )
				NVAR trueMarker = root:mSTR_Folder:true_MarkerNum
				trueMarker = popNum - 1
			endif
			if( cmpstr( pa.ctrlName, "ou_FalseMarker_pop" )== 0 )
				NVAR falseMarker = root:mSTR_Folder:false_MarkerNum
				falseMarker = popNum - 1
			endif
			
			break
			
	endswitch

	return 0
End
Function mSTR_ProcSTCTimePick(stc_time_str)
	// this is the main meat function for parsing the Status Wave
	String stc_time_str
	
	SVAR msg = root:mSTR_Folder:msg
	
	Wave time_w = $stc_time_str
	String prefix = StringFromList( 0, stc_time_str, "_" )
	String statusStr = prefix + "_StatusW"
	Wave/Z status_w = $statusStr
	if( WaveExists( status_w ) )
		sprintf msg, "found status wave for this stc time wave"
		NVAR status_var = root:mSTR_folder:stc_status_w_Exists; status_var = 1
	else
		sprintf msg, "wave %s not found -- bad error", statusStr
		NVAR status_var = root:mSTR_folder:stc_status_w_Exists; status_var = 0
		
		return -1
	endif
		
	Wave mSTC_mask = root:mSTR_Folder:mSTC_mask
	
	Redimension/N=(numpnts(time_w )) mSTC_mask

	NVAR gui_valve_rep = root:mSTR_Folder:gui_valve_rep
	
	Duplicate/O status_W, root:mSTR_Folder:statusW_sans16
	Variable idex
	for( idex = 0; idex < 16; idex += 1 )
		Wave dest_w = root:mSTR_Folder:statusW_sans16
		dest_w = Floor( dest_w / 2 )
	endfor
	
	
			
		
End
Function mSTR_CalculateMask()
	
	SVAR msg=root:mSTR_Folder:msg
	// reference all that we might need to figure this out
	ControlInfo/W=Mask_str_stc	in_Method_pop
	Variable method_chosen = v_value, idex, count, this_state, dex, bdex, edex
	
	ControlInfo/W=Mask_str_stc	va_Match_pop
	Variable match_method = v_value
	
	Wave mSTC_mask = root:mSTR_Folder:mSTC_mask
	Wave mSTR_mask = root:mSTR_Folder:mSTR_mask
	Wave mSTC_time = root:mSTR_Folder:mSTC_time
	Wave mSTR_time = root:mSTR_Folder:mSTR_time
	Wave mSTR_data_raw = root:mSTR_Folder:mSTR_data_raw
	Wave mSTR_data_filter = root:mSTR_Folder:mSTR_data_filter
	Wave mSTR_LoToHi = root:mSTR_Folder:mSTR_LoToHi
	Wave mSTR_HiToLo = root:mSTR_Folder:mSTR_HiToLo
	Wave mSTR_LoToHi_point = root:mSTR_Folder:mSTR_LoToHi_point
	Wave mSTR_LoToHi_time = root:mSTR_Folder:mSTR_LoToHi_time
	Wave mSTR_HiToLo_point = root:mSTR_Folder:mSTR_HiToLo_point
	Wave mSTR_HiToLo_time = root:mSTR_Folder:mSTR_HiToLo_time
		
	Wave mSTR_TOD_Strobe = root:mSTR_Folder:mSTR_TOD_Strobe
	NVAR start_time_hour =			root:mSTR_Folder:start_time_hour
	NVAR start_time_minute =		root:mSTR_Folder:start_time_minute
	NVAR start_time_second =		root:mSTR_Folder:start_time_second
	NVAR interval_secs =			root:mSTR_Folder:interval_secs
	NVAR duration =					root:mSTR_Folder:duration
	NVAR preDwell =					root:mSTR_Folder:preDwell
	NVAR postDwell =				root:mSTR_Folder:postDwell		
	
			
	Variable start_sam = 3600 * start_time_hour + 60* start_time_minute + start_time_second
	NVAR mask_Rep = root:mSTR_Folder:gui_valve_rep
	switch (method_chosen)
		case 1:
			// this is the by VALVE method
			Wave/Z status_w = root:mSTR_Folder:statusW_sans16
			count = numpnts( status_w ) 
			Redimension/N=( count ) mSTC_mask; mSTC_mask = Nan
			switch( match_method )
				case 1:
					// implies by valve matching ANY
					mSTC_mask = status_w & mask_Rep
					mSTC_mask = mSTC_Mask[p] > 0 ? 1 : Nan
					break;
				case 2:
					// implies by valve matching EXACTLY
					mSTC_mask = status_w[p] == mask_Rep ? 1 : Nan
					break

			endswitch
			
			Redimension/N=(numpnts( mSTR_time )) mSTR_mask	
			mSTR_mask = Nan
			for( idex = 0; idex < numpnts( mSTR_time ); idex+= 1 )
				dex = BinarySearch( mSTC_time, mSTR_time[idex] )
				if( dex > 0 )
					mSTR_mask[idex] = mSTC_mask[dex]
				else
					mSTR_mask[idex]= nan
				endif
			endfor
			
			
			break
		case 2: 
			// this is the by Time Method
			//			mSTR_TOD_Strobe = nan
			//			
			//			count = numpnts( mSTR_TOD_Strobe ); 
			//			for( idex = 0; idex < count; idex += 1 )
			//				
			//				if( mod( idex - start_sam, interval_secs ) == 0 )
			//					mSTR_TOD_Strobe[ idex + preDwell, idex + duration - postDwell ] = 1
			//				endif
			//				
			//			endfor
			//			Duplicate/O mSTC_time, mSTC_TOD; 
			//			mSTC_TOD = Secs2SAM( mSTC_Time[p] )
			//			mSTC_mask = mSTR_TOD_Strobe(  x2pnt( mSTR_TOD_Strobe, mSTC_TOD[p] ))
			//			Duplicate/O mSTR_time, mSTR_TOD, mSTR_LUinS; 
			//			mSTR_TOD = Secs2SAM( mSTR_time[p] )
			//			mSTR_LUinS = x2pnt( mSTR_TOD_Strobe, mSTR_TOD[p] )
			//			mSTR_mask = mSTR_TOD_Strobe(  mSTR_LUinS[p] )
			//			Duplicate/O mSTR_mask, mSTR_maskPreInvert	
			//				//mSTR_TOD_Strobe = (Mod( x - start_sam , interval_secs) ) < (duration - postDwell  )? 1 : nan
			//		
			// figure out the entered values
			variable bSecondsAfterMidnight = start_time_hour*3600+start_time_minute*60 + start_time_second
			// simplify wierd start times to earliest possible start time
			do
				bSecondsAfterMidnight -= interval_secs
			While(bSecondsAfterMidnight > interval_secs)
			
			
			// parse earliest relevant time that a zero could be 
			Variable/D startTime = mSTR_time[0]
			if(mSTC_time[0]<startTime)
				startTime = mSTC_time[0]
			endif
			Variable/D endTime = mSTR_time[numpnts(mSTR_time)-1]
			if(mSTC_time[numpnts(mSTC_time)-1]>endTime)
				endTime = mSTC_time[numpnts(mSTC_time)-1]
			endif
			

			String time_str = Secs2Time(startTime,3)
			variable rHour = str2num(stringfromlist(0,time_str," "))
			variable rMinute = str2num(StringFromList( 1, time_str, ":" )	)
			variable rSecond = str2num(StringFromList( 2, time_str, ":" ))
			
			variable rSecondsAfterMidnight = rHour * 3600 + rMinute * 60 + rSecond
			variable midnight = startTime - rSecondsAfterMidnight
			
			// figure out when the first zero needs to be triggered (okay if before wave)
			variable firstZeroTime = midnight + bSecondsAfterMidnight
			do
				firstZeroTime +=interval_secs	
			while (firstZeroTime + duration < startTime)	
			
			// zeros wave gives start and stop times
			Wave/D/z zeros_start = root:mSTR_folder:Zeros_start
			if(!waveexists(zeros_start))
				mSTR_zeroWaveReset()
				wave/D zeros_start = root:mSTR_folder:Zeros_start
				
			endif
			Wave/D zeros_end = root:mSTR_folder:zeros_end
			mSTR_zeroWaveReset()
			// actually add the zero start and stop times to the waves.
			variable/D thisDateTime
			for(thisDateTime=firstZeroTime;thisDateTime<=endTime;thisDateTime+=interval_secs)
				AppendVal(zeros_start, thisDateTime + preDwell )					
				AppendVal(zeros_end, thisDateTime +duration - postDwell )						
			endfor
			
			Wave tempMask = mSTR_zeroTimes2maskWave(zeros_start, zeros_end, mSTR_time)
			duplicate/o tempMask, mSTR_mask ;// killwaves/z tempMask
			doupdate
			wave tempMask = mSTR_zeroTimes2maskWave(zeros_start, zeros_end, mSTC_time)
			duplicate/o tempMask, mSTC_mask; //killwaves/z tempMask
			
			break
			
	endswitch

	// do edges
	
	mSTR_calculateEdges()
	
	//	Duplicate/O mSTR_data_raw, mSTR_LoToHi, mSTR_HiToLo, mSTR_LoToHi_point, mSTR_LoToHi_time, mSTR_HiToLo_point, mSTR_HiToLo_time
	//	setscale d 0, 1, "dat", mSTR_LoToHi_time, mSTR_HiToLo_time
	//
	//	mSTR_LoToHi_point = p; mSTR_LoToHi_time = mSTR_time
	//	mSTR_LoToHi = numtype( mSTR_mask[p] ) == 0 ? 1 : 0
	//	Differentiate mSTR_LoToHi
	//	// differentiating causes double entries often
	//	mSTR_LoToHi = mSTR_LoToHi[p+1] == 0.5 && mSTR_LoToHi[p] ==0.5 ? 0 : mSTR_LoToHi[p]
	//	Sort/R mSTR_LoToHi, mSTR_LoToHi, mSTR_LoToHi_point, mSTR_LoToHi_time
	//	Variable where_zero = 1+BinarySearch( mSTR_LoToHi, 0.5 ); 
	//	count = numpnts( mSTR_LoToHi )
	//	DeletePoints where_zero, count - where_zero, mSTR_LoToHi, mSTR_LoToHi_point, mSTR_LoToHi_time
	//	Sort mSTR_LoToHi_time, mSTR_LoToHi_point, mSTR_LoToHi_time
	//	make/D/O/n=(numpnts(mSTR_LoToHi_time)/2) mSTR_LoToHi_time2, mSTR_LoToHi_point2
	//	if(mSTR_Mask[0] == 1 )
	//		insertPoints 0, 1, mSTR_LoToHi_time, mSTR_LoToHi_point
	//		mSTR_loToHi_time[0] = mSTR_Time[0]
	//		mSTR_LoToHi_point[0] = 0
	//	endif


	NVAR F2T_extra_secs = root:mSTR_Folder:F2T_extra_secs
	if( F2T_extra_secs != 0 )
		for( idex = 0; idex < numpnts( mSTR_LoToHi_time ); idex += 2 )
			bdex = BinarySearch( mSTR_time, mSTR_LoToHi_time[idex] )
			edex = BinarySearch( mSTR_time, mSTR_LoToHi_time[idex] + F2T_extra_secs )
			if(edex == -2)
				edex = numpnts(mSTR_time)-1
			endif
			if(bdex== -1)
				bdex = 0
			endif
			if(bdex == -2 || edex == -1)
				// this should never happen
				bdex = 0; edex = numpnts(mSTR_time)-1
			endif
			if( bdex > edex )
				variable where_zero = bdex; bdex = edex; edex = where_zero
			endif
			if(F2T_extra_secs > 0 ) // then clip edges
				mSTR_mask[bdex,edex] = nan
			elseif (F2T_extra_secs <0 )// then add to edges
				mSTR_mask[bdex,edex] = 1
			endif
		endfor
	endif
	
	//	
	//	mSTR_HiToLo_point = p; mSTR_HiToLo_time = mSTR_time
	//	mSTR_HiToLo = numtype( mSTR_mask[p] ) == 0 ? 1 : 0
	//	Differentiate mSTR_HiToLo
	//	// differentiating causes double entries often
	//	mSTR_HiToLo = mSTR_HiToLo[p-1] == -0.5 && mSTR_HiToLo[p] ==-0.5 ? 0 : mSTR_HiToLo[p]
	//	Sort mSTR_HiToLo, mSTR_HiToLo, mSTR_HiToLo_point, mSTR_HiToLo_time
	//	where_zero = 1+BinarySearch( mSTR_HiToLo, -0.5 ); 
	//	count = numpnts( mSTR_HiToLo )
	//	DeletePoints where_zero, count - where_zero, mSTR_HiToLo, mSTR_HiToLo_point, mSTR_HiToLo_time
	//	Sort mSTR_HiToLo_time, mSTR_HiToLo_point, mSTR_HiToLo_time
	//	if(mSTR_Mask[numpnts(mSTR_Mask)-1] == 1 )
	//		insertPoints (numpnts(mSTR_HiToLo_time)), 1, mSTR_HiToLo_time, mSTR_HiToLo_point
	//		mSTR_HiToLo_time[numpnts(mSTR_HiToLo_time)-1] = mSTR_Time[numpnts(mSTR_Time)-1]
	//		mSTR_HiToLo_point[numpnts(mSTR_HiToLo_point)-1] = numpnts(mSTR_Time)-1
	//	endif


	NVAR T2F_extra_secs = root:mSTR_Folder:T2F_extra_secs
	if( T2F_extra_secs != 0 )
		for( idex = 0; idex < numpnts( mSTR_HiToLo_time ); idex += 2 )
			bdex = BinarySearch( mSTR_time, mSTR_HiToLo_time[idex] )
			edex = BinarySearch( mSTR_time, mSTR_HiToLo_time[idex] + T2F_extra_secs )
			if(edex == -2)
				edex = numpnts(mSTR_time)-1
			endif
			if(bdex== -1)
				bdex = 0
			endif
			if(bdex == -2 || edex == -1)
				// this should never happen
				bdex = 0; edex = numpnts(mSTR_time)-1
			endif
				
			if( bdex > edex )
				where_zero = bdex; bdex = edex; edex = where_zero
			endif
			
			if(T2F_extra_secs > 0 ) // then add to edges
				mSTR_mask[bdex,edex] = 1
			elseif (T2F_extra_secs <0 )// then clip edges
				mSTR_mask[bdex,edex] = Nan
			endif
		endfor
	endif

	// handle the possible inversion here...
	NVAR invert = root:mSTR_Folder:gui_invert_mask
	if( invert )
		mSTC_mask = numtype( mSTC_mask[p] ) == 0 ? nan : 1
		mSTR_mask = numtype( mSTR_mask[p] ) == 0 ? nan : 1
	endif
	

	// set filtered
	mSTR_data_filter = mSTR_data_raw * mSTR_mask
	
End

Function mSTR_zeroWaveReset()
	Make/N=0/D/O root:mSTR_folder:Zeros_start
	Make/N=0/D/O root:mSTR_folder:Zeros_end
End

Function mSTR_GenerateCalMask( cal_time_w, startSec, freqSec, offsetSec, duration )
	Wave cal_time_w
	Variable startSec, freqSec, offsetSec, duration
	
	Variable count = numpnts( cal_time_w ), idex
	Variable this_mod_time
	if( count > 0 )
		Make/O/N=(count)/D mSTR_AutoCalGenMask
		mSTR_AutoCalGenMask = Nan;
	endif
	
	for( idex = 0; idex < count; idex += 1 )
		this_mod_time = Mod( cal_time_w[idex] - startSec - offsetSec, freqSec )
		if( this_mod_time < duration )
			mSTR_AutoCalGenMask[idex] = 1
		endif
	endfor
	
End

Function mSTR_AvgCALFromAutoMask( time_w, data_w, mask_w, destStr )
	Wave time_w
	Wave data_w
	Wave mask_w
	String destStr
	
	Variable idex, count = numpnts( time_w ), bdex, edex
	
	Duplicate/O mask_w, provo_mask
	provo_mask = numtype( provo_mask ) == 2 ? 0 : provo_mask
	Duplicate/O provo_mask, dprovo_mask
	Differentiate/METH=1 dprovo_mask
	dprovo_mask = round( dprovo_mask )
	Make/O/D/N=0 provo_start, provo_stop
	for( idex = 0; idex < count; idex += 1 )
		if( dprovo_mask[idex] == 1 )
			AppendVal( provo_start, time_w[idex] )
		endif
		if( dprovo_mask[idex] == -1 )
			AppendVal( provo_stop, time_w[idex] )
		endif
	endfor
	
	Duplicate/O provo_start, CAL_Time, CAL_MixingRatio
	CAL_Time = nan; CAL_mixingRatio = Nan
	for( idex = 0; idex < numpnts( provo_start ); idex += 1 )
		bdex = BinarySearch( time_w, provo_start[idex] )
		edex = BinarySearch( time_w, provo_stop[idex] )
		WaveStats/Q/R=[bdex, edex] data_w
		CAL_Time[idex] = 1/2 * ( provo_start[idex] + provo_stop[idex] )
		CAL_MixingRatio[idex] = v_avg
	endfor
	
	KillWaves/Z provo_mask, dprovo_mask, provo_start, provo_stop
End
Function/Wave mSTR_zeroTimes2maskWave(zStart, zEnd, dataTime) 
	Wave/D zStart, zEnd, dataTime
	
	String maskName = cleanupname("mask_"+nameofwave(dataTime),0)
	
	Make/O/n=(numpnts(dataTime)) $maskName
	Wave mask = $maskName
	mask = nan
	
	Variable nandex
	variable/D stime, etime
	for (nandex = 0; nandex<numpnts(Zstart); nandex+=1)
	
		sTime = zStart[nandex]
		eTime = zEnd[nandex]
		// search for times in question.
		variable sdex = binarysearch(dataTime, stime) // inclusive of the start point
		variable edex = binarysearch(dataTime, etime)
		//account for out of bounds indices
		// if sdex after end, ignore.
		// if empty wave, ignore
		if (sdex==-3)
			Return mask
		endif
		if(edex==-1 &&sdex==-1)
			// n/a
			return mask
		endif
		if(edex==-2 &&sdex==-2)
			return mask
		endif
		if (sdex ==-2)
			//		print "Error! start index is after end of wave"
			return mask
		endif
		//if edex after end
		if (edex==-2)
			edex = numpnts(dataTime)-1
		endif
		// if sdex before beginning
		if (sdex==-1)
			mask[0]=1 // why doesn't this work
			sdex = 0  
		endif
		if (edex<sdex)
			//		print "Error! End index before begin index"
			Return mask
		endif
		variable idex
		
		mask[sdex ,edex] = 1


	endfor 
	return mask
		
End
//////////////////////////////////////////////////////////////
//
//	mSTR_times2onOffGatedMaskWave(gateTimes, subTimes, dataTime)
//	
//	This mask takes a set of gate times (eg. every 15 minutes)
// and a set of sub-times (eg. every 2 minutes)
// and calculates an on-off-on-off type mask, resetting the 
// polarity at every gate.

// eg for sampling data that looks like
// ref, sample, ref | ref, sample, ref, sample| ref, sample, ref

// this function should be able to identify all ref samples as on
// and samples as off. 
///////////////////////////////////////////////////////////////
Function /Wave mSTR_times2onOffGatedMaskWave(gateTimes, subTimes, dataTime)
	wave/D datatime
	Wave/D gatetimes, subTimes
	
	String maskName = cleanupname("mask_"+nameofwave(dataTime),0)
	
	Make/O/n=(numpnts(dataTime)) $maskName
	Wave mask = $maskName
	mask = nan
	
	Variable gatedex, nanDex
	variable/D stime, etime
	
	variable gateCount = numpnts(gateTimes)
	if(numpnts(gateTimes)<2)
		// then gate is huge and encompasses full dataset
		gateCount = 2
	endif
	
	for(gateDex=1; gatedex<gateCount; gateDex+=1)
		variable subStart, subEnd
		if(numpnts(gateTimes)<2)
			subStart = binarySearch(subTimes, gateTimes[0])
			if(numpnts(gateTimes)<1)
				//basically ignore this first loop
				subStart = 0
			endif
			subEnd = numpnts(subTimes)-1
		else
		
			subStart = binarySearch(subTimes, gateTimes[gatedex-1])
			subEnd = binarySearch(subTimes, gateTimes[gateDex])
			
			if(subStart==-1&& subEnd>0)
				subStart = 0
			endif
			if(subEnd == -2 && subStart>0)
				subEnd = numpnts(subTimes)-1
			endif
			
		endif
		
		for (nandex = subStart; nandex<=subEnd; nandex+=2)
		
			sTime = subTimes[nandex] 
			eTime = subTimes[nandex+1]
			// search for times in question.
			variable sdex = binarysearch(dataTime, stime)+1 // do not include previous point. 
			variable edex = binarysearch(dataTime, etime)
			//account for out of bounds indices
			// if sdex after end, ignore.
			// if empty wave, ignore
			if (sdex==-3)
				Return mask
			endif
			if(edex==-1 &&sdex==-1)
				// n/a
				return mask
			endif
			if(edex==-2 &&sdex==-2)
				return mask
			endif
			if (sdex ==-2)
				//		print "Error! start index is after end of wave"
				return mask
			endif
			//if edex after end
			if (edex==-2)
				edex = numpnts(dataTime)-1
			endif
			// if sdex before beginning
			if (sdex==-1)
				mask[0]=1 // why doesn't this work
				sdex = 0  
			endif
			if (edex<sdex)
				//		print "Error! End index before begin index"
				Return mask
			endif
			variable idex
			
			mask[sdex ,edex] = 1
	
	
		endfor 
	endfor
	return mask


End

//////////////////////////////////////////////////////////////
//
//	mSTR_times2onOffMaskWave(times, dataTime)
//	
//	This mask takes a set times (eg. every 2 minutes)
// and calculates an on-off-on-off type mask.

// eg for sampling data that looks like
// ref, sample, ref, sample, ref, sample

// this function should be able to identify all ref samples as on
// and samples as off. 

// see also mSTR_times2onOffGatedMaskWave if the polarity ever resets at 
// a zero or something. 
//////////////////////////////////////////////////////////////
Function /Wave mSTR_times2onOffMaskWave(times, dataTime)

	Wave/D times, dataTime
	
	String maskName = cleanupname("mask_"+nameofwave(dataTime),0)
	
	Make/O/n=(numpnts(dataTime)) $maskName
	Wave mask = $maskName
	mask = nan
	
	Variable nandex
	variable/D stime, etime
	for (nandex = 1; nandex<numpnts(times); nandex+=2)
	
		sTime = times[nandex-1]
		eTime = times[nandex]
		// search for times in question.
		variable sdex = binarysearch(dataTime, stime) // inclusive of the start point
		variable edex = binarysearch(dataTime, etime)
		//account for out of bounds indices
		// if sdex after end, ignore.
		// if empty wave, ignore
		if (sdex==-3)
			Return mask
		endif
		if(edex==-1 &&sdex==-1)
			// n/a
			return mask
		endif
		if(edex==-2 &&sdex==-2)
			return mask
		endif
		if (sdex ==-2)
			//		print "Error! start index is after end of wave"
			return mask
		endif
		//if edex after end
		if (edex==-2)
			edex = numpnts(dataTime)-1
		endif
		// if sdex before beginning
		if (sdex==-1)
			mask[0]=1 // why doesn't this work
			sdex = 0  
		endif
		if (edex<sdex)
			//		print "Error! End index before begin index"
			Return mask
		endif
		variable idex
		
		mask[sdex ,edex] = 1


	endfor 
	return mask

End


Function mSTR_CalculateEdges()
	
	String saveFolder=GetDataFolder(1)
	SetDataFolder root:mSTR_Folder
		
	SVAR msg=root:mSTR_Folder:msg
	
	// reference all that we might need to figure this out
	ControlInfo/W=Mask_str_stc	in_Method_pop
	Variable method_chosen = v_value, idex, count, this_state, dex, bdex, edex
	
	ControlInfo/W=Mask_str_stc	va_Match_pop
	Variable match_method = v_value
	
	Wave mSTC_mask = root:mSTR_Folder:mSTC_mask
	Wave mSTR_mask = root:mSTR_Folder:mSTR_mask
	Wave mSTC_time = root:mSTR_Folder:mSTC_time
	Wave mSTR_time = root:mSTR_Folder:mSTR_time
	Wave mSTR_data_raw = root:mSTR_Folder:mSTR_data_raw
	Wave mSTR_data_filter = root:mSTR_Folder:mSTR_data_filter
	Wave mSTR_LoToHi = root:mSTR_Folder:mSTR_LoToHi
	Wave mSTR_HiToLo = root:mSTR_Folder:mSTR_HiToLo
	Wave mSTR_LoToHi_point = root:mSTR_Folder:mSTR_LoToHi_point
	Wave mSTR_LoToHi_time = root:mSTR_Folder:mSTR_LoToHi_time
	Wave mSTR_HiToLo_point = root:mSTR_Folder:mSTR_HiToLo_point
	Wave mSTR_HiToLo_time = root:mSTR_Folder:mSTR_HiToLo_time
		
	Wave mSTR_TOD_Strobe = root:mSTR_Folder:mSTR_TOD_Strobe
	NVAR start_time_hour =			root:mSTR_Folder:start_time_hour
	NVAR start_time_minute =		root:mSTR_Folder:start_time_minute
	NVAR start_time_second =		root:mSTR_Folder:start_time_second
	NVAR interval_secs =			root:mSTR_Folder:interval_secs
	NVAR duration =					root:mSTR_Folder:duration
	NVAR preDwell =					root:mSTR_Folder:preDwell
	NVAR postDwell =				root:mSTR_Folder:postDwell		
	SVAR name = root:mSTR_folder:gui_target_mask_name
	
	// do edges
	// 
	Duplicate/O mSTR_data_raw, mSTR_LoToHi, mSTR_LoToHi_point, mSTR_LoToHi_time

	mSTR_LoToHi_point = p; mSTR_LoToHi_time = mSTR_time
	mSTR_LoToHi = numtype( mSTR_mask[p] ) == 0 ? 1 : 0
	Differentiate mSTR_LoToHi
	// differentiating causes double entries often
	mSTR_LoToHi = mSTR_LoToHi[p+1] == 0.5 && mSTR_LoToHi[p] ==0.5 ? 0 : mSTR_LoToHi[p]
	// start and end times sometimes have non-0.5 values
	mSTR_loToHi = mSTR_LoToHi[p] != 0.5 && mSTR_LoToHi[p] != 0 ? 0 : mSTR_LoToHi[p]
	
	Sort/R mSTR_LoToHi, mSTR_LoToHi, mSTR_LoToHi_point, mSTR_LoToHi_time
	Variable where_zero = 1+BinarySearch( mSTR_LoToHi, 0.5 ); 
	count = numpnts( mSTR_LoToHi )
	DeletePoints where_zero, count - where_zero, mSTR_LoToHi, mSTR_LoToHi_point, mSTR_LoToHi_time
	Sort mSTR_LoToHi_time, mSTR_LoToHi_point, mSTR_LoToHi_time
	if(mSTR_Mask[0] == 1 )
		insertPoints 0, 1, mSTR_LoToHi_time, mSTR_LoToHi_point
		mSTR_loToHi_time[0] = mSTR_Time[0]
		mSTR_LoToHi_point[0] = 0
	endif
	Duplicate/O mSTR_data_raw, mSTR_HiToLo, mSTR_HiToLo_point, mSTR_HiToLo_time
	mSTR_HiToLo_point = p; mSTR_HiToLo_time = mSTR_time
	mSTR_HiToLo = numtype( mSTR_mask[p] ) == 0 ? 1 : 0
	Differentiate mSTR_HiToLo
	// differentiating causes double entries often
	mSTR_HiToLo = mSTR_HiToLo[p-1] == -0.5 && mSTR_HiToLo[p] ==-0.5 ? 0 : mSTR_HiToLo[p]
	// start and end times sometimes have non-0.5 values
	mSTR_HiToLo = mSTR_HiToLo[p] != -0.5 && mSTR_HiToLo[p] != 0 ? 0 : mSTR_HiToLo[p]
	
	Sort mSTR_HiToLo, mSTR_HiToLo, mSTR_HiToLo_point, mSTR_HiToLo_time
	where_zero = 1+BinarySearch( mSTR_HiToLo, -0.5 ); 
	count = numpnts( mSTR_HiToLo )
	DeletePoints where_zero, count - where_zero, mSTR_HiToLo, mSTR_HiToLo_point, mSTR_HiToLo_time
	Sort mSTR_HiToLo_time, mSTR_HiToLo_point, mSTR_HiToLo_time


	if(mSTR_Mask[numpnts(mSTR_Mask)-1] == 1 )
		insertPoints (numpnts(mSTR_HiToLo_time)), 1, mSTR_HiToLo_time, mSTR_HiToLo_point
		mSTR_HiToLo_time[numpnts(mSTR_HiToLo_time)-1] = mSTR_Time[numpnts(mSTR_Time)-1]
		mSTR_HiToLo_point[numpnts(mSTR_HiToLo_point)-1] = numpnts(mSTR_Time)-1
	endif
	setscale d 0, 1, "dat", mSTR_LoToHi_time, mSTR_HiToLo_time
	
	duplicate/o mSTR_LoToHi_point $("root:"+cleanupname(name + "_start_p",0))
	duplicate/o mSTR_LoToHi_time $("root:"+cleanupname(name + "_start_time",0))
	duplicate/o mSTR_HiToLo_point $("root:"+cleanupname(name + "_stop_p",0))
	duplicate/o mSTR_HiToLo_time $("root:"+cleanupname(name + "_stop_time",0))

	SetDataFolder $saveFolder
End

// wgSTC_ComputeMask();
// Default:
// Call wgSTC_ComputeMask() to work from stc_time and stc_StatusW
// produces wgSTC_Mask_v<n> valued 1 or 0 for valuve n, counting from zero
// also produces Valve_<n>_Start and Valve_<n>_Stop
//
// Advanced: to override and specify different stc_time and stc_statusW call like
// wgSTC_ComputeMask( stc_timeW = <wave>, statusword = <wave> )

Function wgSTC_ComputeMask( [statusword, stc_timeW] )
	Wave statusword
	Wave stc_timeW

	Variable idex, count, jdex, jcount, valveNum, parity;
	String list, this_
	
	Wave/Z  loc_statusW = $ks_default_stc_StatusWord
	Wave/Z  loc_stcTime = $ks_default_stc_datetime
	
	if( !ParamIsDefault( statusword ) )
		Wave/Z  loc_statusW = $NameOfWave( statusword )
	endif	
	if( !ParamIsDefault( stc_timeW ) )
		Wave/Z  loc_stcTime = $NameOfWave( stc_timeW )
	endif	
	
	if( WaveExists( loc_statusW ) != 1 )
		print "In wgSTC_ComputeMask: unable to locate default status word wave.  Aborting";		return -1;
	endif
	if( WaveExists( loc_stcTime ) != 1 )
		print "In wgSTC_ComputeMask: unable to locate default  stc time wave.  Aborting";		return -1;
	endif
	
	if( numpnts( loc_statusW ) != numpnts( loc_stcTime ) )
		print "in gsSTC_ComputeMask: unequal points in time and status wave.  Aborting"; 	return -1;
	endif
	
	SVAR/Z msg = root:STRPanel_Folder:msg
	String msg_cat = "";
	if( SVAR_Exists( msg ) )
		sprintf msg_cat , "mask->%s,%s | ", NameOfWave( loc_stcTime ), NameOfWave( loc_statusW )
		msg = msg_cat;
	endif
	
	Duplicate/O loc_statusW, wgSTC_temp
	for( idex = 0; idex < 16; idex += 1)
		wgSTC_temp = Floor( wgSTC_temp / 2 );
	endfor
	
	Make/O/B/N=(numpnts( loc_StatusW )) wgSTC_MaskSan16
	
	wgSTC_MaskSan16 = wgSTC_temp;
	
	Duplicate/O wgSTC_MaskSan16, wgSTC_Mask_v3,wgSTC_Mask_v2,wgSTC_Mask_v1,wgSTC_Mask_v0
	Duplicate/O wgSTC_MaskSan16, wgSTC_Mask_v7,wgSTC_Mask_v6,wgSTC_Mask_v5,wgSTC_Mask_v4

	for( idex = 0; idex < 8; idex += 1 )
		Wave w = $("wgSTC_Mask_v" + num2str( idex ) )
		w = wgSTC_MaskSan16 & 2^idex ? 1 : 0
	endfor
	for( idex = 0; idex < 8; idex += 1 )
		Wave w = $("wgSTC_Mask_v" + num2str( idex ) )
		if( sum( w ) == 0 )
			KillWaves/Z w
		else
			Make/D/O/N=0 $("Valve_" + num2str( idex ) + "_Start");
			Wave start_w = $("Valve_" + num2str( idex ) + "_Start");
			Make/D/O/N=0 $("Valve_" + num2str( idex ) + "_Stop");
			Wave stop_w = $("Valve_" + num2str( idex ) + "_Stop");
			SetScale/P y, 0,0, "dat" start_w, stop_w
			jcount = numpnts(w);	parity = 0;
			for( jdex = 0; jdex < jcount; jdex += 1 )
				if( parity  )
					if( w[jdex] == 0 )
						Appendval( stop_w, loc_stcTime[jdex] )
						parity = 0
					endif
				else
					if( w[jdex] == 1 )
						AppendVal( start_w, loc_stcTime[jdex] )
						parity = 1;
					endif
				endif
			endfor
		endif	
	endfor

	KillWaves/Z wgSTC_temp
	
	
End


Function mSTR_CopyMask2Root()
	
	SVAR msg = root:mSTR_Folder:msg
	SVAR destName = root:mSTR_Folder:gui_target_mask_name
	
	sprintf msg, "Copying current mast to root as %s", destName
	Wave w = root:mSTR_Folder:mSTR_mask
	String SaveFolder = getdatafolder(1)
	
	SetDatafolder root:;
	Duplicate/O w, $destName
	Wave mask_w = $destName
	
	NVAR writeMarker = root:mSTR_Folder:write_marker_waves
	NVAR writeFalseMarker = root:mSTR_Folder:write_marker_forFalse
	
	NVAR trueMarker = root:mSTR_Folder:true_markerNum
	NVAR falseMarker = root:mSTR_Folder:false_markerNum
	
	if( writeMarker )
		Duplicate/O mask_w, $(destName+"_markerNum");		Wave marker_w = $(destName+"_markerNum")
		if( writeFalseMarker )
			marker_w = numtype( mask_w[p] ) == 0 ? trueMarker : falseMarker
		else
			marker_w = numtype( mask_w[p] ) == 0 ? trueMarker :  Nan
		endif
	endif
	
	setDatafolder saveFolder
End

Function mSTR_Panel_and_Init()
	mSTR_init()
	mSTR_Panel()
	DoWindow/F mSTR_liveMaskWin
	if(!V_Flag)
		execute "mSTR_LiveMaskWin()"
	endif
End
Function mSTR_Panel()
	
	String TabList = ksb_TabList, this_tab, test_funcName
	Variable idex, count = ItemsInList( TabList )
	
	Variable left = 5, right = 480, top = 5, bottom = 305
	Variable tab_left = left, tab_right = right, tab_top = top, tab_bottom = bottom
	Variable tab_wid = tab_right - tab_left - 25
	Variable tab_height = tab_bottom - tab_top - 50
	
	left += 300
	right += 300
	PauseUpdate; Silent 1;
	MakeOrSetPanel( left, top, right, bottom, ks_mSTR_Window )
	
	TabControl mainTab, pos={tab_left, tab_top}
	TabControl mainTab, size={tab_wid, tab_height}, proc=mSTR_AutoTabProc
	do
		this_tab = StringFromList( idex, TabList )	
		TabControl mainTab, tabLabel(idex)=StringFromList( idex, TabList )
		idex += 1
	while( idex < count )

	TabControl mainTab, value=0

	Variable msg_row = tab_top + 25, msg_col = tab_left + 4, msg_height = 25, msg_wid = tab_wid - 7
	
	SetVariable mainMessage title = "`", value=$(ks_mSTRFolder+":msg"), fsize=12
	SetVariable mainMessage pos={msg_col, msg_row}, size={ msg_wid - 95, msg_height }
	SetVariable mainMessage noedit=1
	
	CheckBox mainLive title="Live", variable=root:mSTR_Folder:liveMode, pos={msg_col+msg_wid-90, msg_row}, fsize=12
	
	Variable t_col1 = 45, t_row = 60, ctrl_height = 20, popwid = 200, bodwid = 160, pntsWidth = 80
	PopupMenu in_stc_time_pop title = "stc time w", value = mSTR_GetSTCTimeList(), fsize=12
	PopupMenu in_stc_time_pop pos={t_col1, t_row}, size={popwid, ctrl_height}, bodywidth = bodwid
	PopupMenu in_stc_time_pop proc=mSTR_PopProc, mode=1
	
	CheckBox in_stc_time_filter_ck title = "filter", Variable = root:mSTR_Folder:stc_time_defaultFilter
	CheckBox in_stc_time_filter_ck pos = {t_col1 + popwid + 5, t_row}
	
	SetVariable in_stc_timePnts_sv title = "~", variable = root:mSTR_Folder:stc_time_pnts
	SetVariable in_stc_timePnts_sv pos = {t_col1 + popwid + 45, t_row}, noedit =1, limits = {-inf, inf, 0 }, size = {pntsWidth, ctrl_height}
	
	CheckBox in_statusExists_ck title = "Status W", Variable = root:mSTR_folder:stc_status_w_Exists
	CheckBox in_statusExists_ck pos = {t_col1 + popWid +45 + pntsWidth + 3, t_row}, disable=0, mode=1

	t_row += ctrl_height + 5
	
	PopupMenu in_str_time_pop title = "str time w", value = mSTR_GetSTRTimeList(), fsize=12
	PopupMenu in_str_time_pop pos={t_col1, t_row}, size={popwid, ctrl_height}, bodywidth = bodwid
	PopupMenu in_str_time_pop proc=mSTR_PopProc, mode=1
	
	CheckBox in_str_time_filter_ck title = "filter", Variable = root:mSTR_Folder:str_time_defaultFilter
	CheckBox in_str_time_filter_ck pos = {t_col1 + popwid+5, t_row}
	
	SetVariable in_str_timePnts_sv title = "~", variable = root:mSTR_Folder:str_time_pnts
	SetVariable in_str_timePnts_sv pos = {t_col1 + popwid + 45, t_row}, noedit =1, limits = {-inf, inf, 0 }, size = {pntsWidth, ctrl_height}
	
	t_row += ctrl_height + 5
	PopupMenu in_str_data_pop title = "str data w", value = mSTR_GetSTRDataList(), fsize=12
	PopupMenu in_str_data_pop pos={t_col1, t_row}, size={popwid, ctrl_height}, bodywidth = bodwid
	PopupMenu in_str_data_pop proc=mSTR_PopProc, mode=1
	
	CheckBox in_str_data_filter_ck title = "filter", Variable = root:mSTR_Folder:str_data_defaultFilter
	CheckBox in_str_data_filter_ck pos = {t_col1 + popwid+5, t_row}
	
	SetVariable in_str_dataPnts_sv title = "~", variable = root:mSTR_Folder:str_data_pnts
	SetVariable in_str_dataPnts_sv pos = {t_col1 + popwid + 45, t_row}, noedit =1, limits = {-inf, inf, 0 }, size = {pntsWidth, ctrl_height}
	
	t_row += ctrl_height * 2 + 5
	PopupMenu in_Method_pop title = "Mask Calculation Method ", value="by Valve State;by Time;", proc=mSTR_popproc
	PopupMenu in_Method_pop pos={t_col1 + 50, t_row}, size={300, ctrl_height}, bodywidth=120, mode=1, fsize=14, fstyle=3
	
	
	Variable offset = 2
	t_row = 60
	CheckBox va_valve1_ck title = "Valve #1 (cal)", variable=root:mSTR_Folder:gui_valve_1, pos={t_col1, t_row}, fsize=12, proc=mSTR_CheckProc
	
	SetVariable va_valveRep title ="state", variable=root:mSTR_Folder:gui_valve_rep, pos={t_col1+245, t_row}, fsize=09
	SetVariable va_valveRep noedit = 1, frame=0, fstyle = 0, limits={0, inf, 0}, format="%b", size={120, ctrl_height}, bodywidth=100

	t_row += ctrl_height + offset

	CheckBox va_valve2_ck title = "Valve #2 (ab)", variable=root:mSTR_Folder:gui_valve_2, pos={t_col1, t_row}, fsize=12, proc=mSTR_CheckProc
	BUtton va_calc_mask title="Calculate Mask", pos={t_col1+150, t_row}, size={135, ctrl_height}, proc=mSTR_ButtonProc
	t_row += ctrl_height + offset

	CheckBox va_valve3_ck title = "Valve #3", variable=root:mSTR_Folder:gui_valve_3, pos={t_col1, t_row}, fsize=12, proc=mSTR_CheckProc
	t_row += ctrl_height + offset
	CheckBox va_valve4_ck title = "Valve #4", variable=root:mSTR_Folder:gui_valve_4, pos={t_col1, t_row}, fsize=12, proc=mSTR_CheckProc

	PopupMenu va_Match_pop title = "Match Valves", value="Any;Exactly;", proc=mSTR_popproc
	PopupMenu va_Match_pop pos={t_col1 + 150, t_row}, size={200, ctrl_height}, bodywidth=120, mode=1, fsize=12, fstyle=0
	
	
	t_row += ctrl_height + offset
	CheckBox va_valve5_ck title = "Valve #5", variable=root:mSTR_Folder:gui_valve_5, pos={t_col1, t_row}, fsize=12, proc=mSTR_CheckProc
	CheckBox va_invert_ck title = "invert after match", variable=root:mSTR_Folder:gui_invert_mask, pos={t_col1+150, t_row}, fsize=12, proc=mSTR_CheckProc
	
	t_row += ctrl_height + offset
	CheckBox va_valve6_ck title = "Valve #6", variable=root:mSTR_Folder:gui_valve_6, pos={t_col1, t_row}, fsize=12, proc=mSTR_CheckProc

	t_row += ctrl_height + offset
	CheckBox va_valve7_ck title = "Valve #7", variable=root:mSTR_Folder:gui_valve_7, pos={t_col1, t_row}, fsize=12, proc=mSTR_CheckProc
	SetVariable va_F2T_extra_secs_sv title="F to T: at edge cut extra secs", variable =root:mSTR_Folder:F2T_extra_secs, pos={t_col1 + 150, t_row}, limits={-inf, inf, 0}, size={200, ctrl_height}, proc=mSTR_setEdgesProc

	t_row += ctrl_height + offset
	CheckBox va_valve8_ck title = "Valve #8", variable=root:mSTR_Folder:gui_valve_8, pos={t_col1, t_row}, fsize=12, proc=mSTR_CheckProc
	SetVariable va_T2F_extra_secs_sv title="T to F: at edge cut extra secs", variable= root:mSTR_Folder:T2F_extra_secs, pos={t_col1 + 150, t_row}, limits={-inf, inf, 0}, size={200, ctrl_height}, proc=mSTR_setEdgesProc

	t_row += ctrl_height + offset

	t_row = 60
	
	//CheckBox ti_valvex_ck title = "TimeMethod Not Installed Yet", variable=root:mSTR_Folder:gui_valve_1, pos={t_col1, t_row}, fsize=12
	t_row += ctrl_height + offset
	
	SetVariable ti_startHour title="HH", variable =root:mSTR_Folder:start_time_hour, pos={t_col1, t_row}, limits={0,23,0}
	SetVariable ti_startMinute title="MM", variable =root:mSTR_Folder:start_time_minute, pos={t_col1+45, t_row}, limits={0,59,0}
	SetVariable ti_startSecond title="SS", variable =root:mSTR_Folder:start_time_second, pos={t_col1+45*2, t_row}, limits={0,59,0}
	Button ti_calc_mask title="Calculate Mask", pos={t_col1+150, t_row}, size={135, ctrl_height}, proc=mSTR_ButtonProc

	t_col1 = 130
	t_row += ctrl_height + 5
	SetVariable ti_startTime title="StartTime", value=root:mSTR_Folder:start_time_formatedStr, pos={t_col1, t_row}, noedit=1, bodywidth=85, fsize=14
	SetVariable ti_startTime win=Mask_str_stc, value=root:mSTR_Folder:start_time_formatedStr

	t_row += ctrl_height + 5
	SetVariable ti_interval_secs title="Interval", variable=root:mSTR_Folder:interval_secs, pos={t_col1, t_row}, limits={0,86400,0}, bodywidth=60, fsize=14

	t_row += ctrl_height + 5
	SetVariable ti_duration title="Duration", variable=root:mSTR_Folder:duration, pos={t_col1, t_row}, limits={0,86400,0}, bodywidth=60, fsize=14
	
	t_row += ctrl_height + 5
	SetVariable ti_preDwell title="PreDwell", variable=root:mSTR_Folder:preDwell, pos={t_col1, t_row}, limits={-3600,3600,0}, bodywidth=60, fsize=14
	
	t_row += ctrl_height + 5
	SetVariable ti_postDwell title="PostDwell", variable=root:mSTR_Folder:postDwell, pos={t_col1, t_row}, limits={-3600,3600,0}, bodywidth=60, fsize=14

	CheckBox ti_invert_ck title = "invert mask", variable=root:mSTR_Folder:gui_invert_mask, pos={t_col1+150, t_row}, fsize=12


	t_row = 60
	t_col1 = 35
	Button ou_CopyMask title = "Copy Mask to Root as", pos = {t_col1-5, t_row}, size={150, ctrl_height}, fsize=12, proc=mSTR_ButtonProc
	
	SetVariable ou_DestMask_sv title = "~", variable=root:mSTR_Folder:gui_target_mask_name, pos={t_col1+150, t_row}, size={205, ctrl_height}, proc=mSTR_SVProc, fsize=12
	
	t_row += ctrl_height + 5
	CheckBox ou_WriteMarkerWaves title="Also write marker wave", variable=root:mSTR_Folder:write_marker_waves, pos={t_col1, t_row}, fsize=12, proc=mSTR_CheckProc
	
	PopupMenu ou_TruthMarker_pop title="True Marker", mode=1, value = "*MARKERPOP*", pos={t_col1 + 170, t_row-2}, fsize=12, proc=mSTR_popProc

	t_row += ctrl_height + 5
	CheckBox ou_WriteFalseMarkers title="Write non-mask marker", variable=root:mSTR_Folder:write_marker_forFalse, pos={t_col1+10, t_row}, fsize=12, proc=mSTR_CheckProc
	
	PopupMenu ou_FalseMarker_pop title="False Marker", mode=1, value = "*MARKERPOP*", pos={t_col1 + 170, t_row-2}, fsize=12, proc=mSTR_popProc

	//variable=root:mSTR_Folder:true_markerNum

	t_row += 2 * ctrl_height + 5

	Button ou_CalculateEdges title = "Copy Edges to Root", pos = {t_col1-5, t_row}, size={150, ctrl_height}, fsize=12, proc = mSTR_ButtonProc


	mSTR_InitTabs()
	NVAR/Z last = root:mSTR_Folder:lastMainTabVal 
	if( NVAR_EXists( last ))
		TabControl mainTab, value = last
		mSTR_AutoTabProc( "mainTab", last)
	else
		TabControl mainTab, value = 0
		mSTR_AutoTabProc( "mainTab", 0)
	endif
	
End



Function mSTR_Init()
	
	String saveFolder = GetDataFolder(1); SetDataFolder root:
	MakeAndOrSetDF( ks_mSTRFolder );
	String/G msg = "mask str/stc panel initialized"
	Variable/G liveMode = 1
	Variable/G stc_time_pnts = nan
	Variable/G str_time_pnts = nan
	Variable/G str_data_pnts = nan
	Variable/G stc_status_w_Exists = 0
		
	Variable/G stc_time_defaultFilter = 1
	Variable/G str_time_defaultFilter = 1
	Variable/G str_data_defaultFilter = 1
		
	Variable/G gui_valve_1 = 0
	Variable/G gui_valve_2 = 0
	Variable/G gui_valve_3 = 0
	Variable/G gui_valve_4 = 0
	Variable/G gui_valve_5 = 0
	Variable/G gui_valve_6 = 0
	Variable/G gui_valve_7 = 0
	Variable/G gui_valve_8 = 0
		
	Variable/G gui_valve_rep = 0
	Execute( "gui_valve_rep := gui_valve_1 * (2^0) + gui_valve_2 * (2^1) + gui_valve_3 * (2^2) + gui_valve_4 * (2^3) + gui_valve_5 * (2^4) + gui_valve_6 * (2^5) + gui_valve_7 * (2^6) + gui_valve_8 * (2^7)" ) 
	Variable/G gui_invert_mask = 0
		
	String/G gui_target_mask_name = "str_mask"
	Variable/G target_mask_alreadyExists = 0
	Variable/G lasttab = 0
		
	Variable/G F2T_extra_secs = 0
	Variable/G T2F_extra_secs = 0
		
	Variable/G start_time_hour = 0
	Variable/G start_time_minute = 0
	Variable/G start_time_second = 0
	String/G start_time_formatedStr
	Variable/G interval_secs = 120
	Variable/G duration = 15
	Variable/G preDwell = 1
	Variable/G postDwell = 3
	Variable resolution = 1	// don't change this, it will break algorithm later.
	Make/O/N=(86400/resolution) mSTR_TOD_Strobe
	SetScale/P x, 0, resolution, mSTR_TOD_Strobe
	Wave mSTR_TOD_Strobe = root:mSTR_Folder:mSTR_TOD_Strobe
		
	Execute( "start_time_formatedStr := mSTR_FormatHHMMSS( root:mSTR_Folder:start_time_hour,  root:mSTR_Folder:start_time_minute,  root:mSTR_Folder:start_time_second )")
	Wave/Z w = mstc_time
		
	Variable/G write_marker_waves = 1
	Variable/G true_markerNum = 16
	Variable/G write_marker_forFalse = 0
	Variable/G false_markerNum = 5
		
	if( WaveExists( w ) != 1 )
		Make/N=100/D/O mSTC_time, mSTC_mask,statusW_sans16
		SetScale/P x, datetime, 1, "dat", mSTC_time
		mSTC_mask = 1
		statusW_sans16 = 0
			 
		Make/N=100/D/O mSTR_data_raw, mSTR_data_filter, mSTR_time, mSTR_mask
		SetScale/P x, datetime, 1, "dat", mSTR_time
		mSTR_data_raw = gnoise(1) + 0.5
		mSTR_mask = 1
		Execute("mSTR_data_filter := mSTR_mask * mSTR_data_raw")
			 
		Make/N=100/D/O mSTR_LoToHi, mSTR_HiToLo, mSTR_LoToHi_point, mSTR_LoToHi_time, mSTR_HiToLo_point, mSTR_HiToLo_time
	endif
		
	SetDataFolder $saveFolder
End


Function/T mSTR_FormatHHMMSS( hour, minute, second )
	Variable hour, minute, second
	
	String hr_str = num2str( hour )
	String min_str = num2str( minute )
	String sec_str = num2str( second )
	
	String str = ""
	str = str + mSTR_AddLeadZero( hr_str, 2 ) + ":"
	str = str + mSTR_AddLeadZero( min_str, 2 ) + ":"
	str = str + mSTR_AddLeadZero( sec_str, 2 ) 
	return str
End	
Function/T mSTR_AddLeadZero( val_str, width )
	String val_str
	Variable width
	
	Variable as_num = str2num( val_str )
	Variable order = 10^(width-1)
	Variable this_order = order
	do
		if( as_num < this_order )
			val_str = "0" + val_str
		endif
		this_order /= 10
	while( this_order > 1 )
	
	return val_str
End  

Function mask_by_gap(gateGap, gap)
	
	variable gateGap // large gap, for zeroes eg.
	variable gap // regular gap, for sample switching, eg. 
	
	
	SVAR msg=root:mSTR_Folder:msg
	// reference all that we might need to figure this out
	ControlInfo/W=Mask_str_stc	in_Method_pop
	Variable method_chosen = v_value, idex, count, this_state, dex, bdex, edex
	
	ControlInfo/W=Mask_str_stc	va_Match_pop
	Variable match_method = v_value
	
	Wave mSTC_mask = root:mSTR_Folder:mSTC_mask
	Wave mSTR_mask = root:mSTR_Folder:mSTR_mask
	Wave mSTC_time = root:mSTR_Folder:mSTC_time
	Wave mSTR_time = root:mSTR_Folder:mSTR_time
	Wave mSTR_data_raw = root:mSTR_Folder:mSTR_data_raw
	Wave mSTR_data_filter = root:mSTR_Folder:mSTR_data_filter


	Variable/G thisTime
	
	
	Variable i

	Wave/D/z gapTimes = root:mSTR_folder:gapTimes
	Wave/D/z gateTimes = root:mSTR_folder:gateTimes
	if(!waveexists(gapTimes))
		make/n=0/D root:mSTR_folder:gapTimes
		wave/D gapTimes = root:mSTR_folder:gapTimes
	endif
	if(!waveexists(gateTimes))
		make/n=0/D root:mSTR_folder:gateTimes
		wave/D gateTimes = root:mSTR_folder:gateTimes
	endif
	redimension/N=0 gapTimes, gateTimes
	
	// actually add the zero start and 

	variable lastTime = mSTR_time[0]
	variable onOff =1
		
	// add the start of file as first 
	appendVal(gateTimes,lastTime-1)
	appendVal(gapTimes, lastTIme-1)
	// add any gaps as gates
	For(i=1;i<numpnts(mSTR_time);i+=1)
		lastTime = mSTR_time[i-1]
		thisTime = mSTR_time[i]
			
		if((thisTime-lastTime>=gap))
				
			if(thisTime-lastTime>=gateGap)
				appendVal(gateTimes,lastTIme + (thisTime-lastTIme)/2)
			endif
				
			appendval(gapTimes,lastTIme +(thisTime-lastTIme)/2)
				
		endif
			
	endfor
	
	mSTR_mask = nan
	Wave tempMask = mSTR_times2onOffGatedMaskWave(gateTimes,gapTimes,mSTR_time)
	duplicate/o tempMask mSTR_mask	
	mSTR_calculateEdges()
	
	
	// handle the possible inversion here...
	NVAR invert = root:mSTR_Folder:gui_invert_mask
	if( invert )
		mSTC_mask = numtype( mSTC_mask[p] ) == 0 ? nan : 1
		mSTR_mask = numtype( mSTR_mask[p] ) == 0 ? nan : 1
	endif
	

	// set filtered
	mSTR_data_filter = mSTR_data_raw * mSTR_mask
	

End


Function spe2_BrowseWholeListBox()

	Wave/T disp_fileList = root:LoadSPE_UI:disp_fileList
	Wave disp_SelWave = root:LoadSPE_UI:disp_SelWave
	
	String thePanel = ks_zSPE2PanelName
	Variable jdex=0, jcount = 5
	Variable idex = 0, count = numpnts( disp_SelWave )
	if( count > 0 )
	
		String saveFolder = GetDataFolder(1)
		SetDataFolder root:
		SetDataFolder root:LoadSPE_UI
		
		String this, target
		String list = WaveList( "ses_*", ";", "" )
		jdex = 0; jcount = ItemsInList( list )
		if( jcount > 0 )
			do
				this = StringFromList( jdex, list )
				Wave w = $this
				//sprintf target, "root:%s", this
				Redimension/N=0 w
				jdex += 1
			while( jdex < jcount )
		endif
		SetDataFolder $saveFolder
	
	
		Variable kdex = 0, kcount = count/10
		disp_SelWave = 0
		do
			disp_SelWave[idex] = 1
			LoadSPE_LBProc( "ao_STR_LB1", idex, 0, 4 )
			disp_SelWave[idex] = 0
			if( jdex > jcount )
				ListBox ao_STR_LB1,win=$thePanel,row=idex - 3
				doupdate
				jdex = 0
			endif
			if( kdex > kcount )
				printf "AutoBrowse All: %d of %d (%5.2f%)\r", idex, count, idex/count * 100
				kdex = 0
			endif
			
			kdex += 1
			jdex += 1
			idex += 1
		while( idex < count )
		
		saveFolder = GetDataFolder(1)
		SetDataFolder root:
		SetDataFolder root:LoadSPE_UI
		
		String source
		list = WaveList( "ses_*", ";", "" )
		jdex = 0; jcount = ItemsInList( list )
		if( jcount > 0 )
			do
				this = StringFromList( jdex, list )
				Wave w = $this
				sprintf source, "root:LoadSPE_UI:%s", this
				sprintf target, "root:%s", this
				// use the following to 'overwrite' the waves in root
				Duplicate/O w, $target
				// the following will tack the waves onto those in root, if present...
				// ConcatenateWaves( target, source )
				jdex += 1
			while( jdex < jcount )
		endif
		SetDataFolder $saveFolder
	endif
End

//	Function LoadSPE_LBProc( ctrl, row, col, event )
//	String ctrl
//	Variable row	// row if click in interior, -1 if click is in title
//	Variable col 	// column number
//	Variable event	// event code, which will be the first trap

Function mSPE2_ProcMean()

	NVAR/Z spec_count = root:spec_count
	if( NVAR_Exists( spec_count ) != 1 )
		String saveFolder = GetDataFolder(1)
		SetDataFolder root:
			
		Variable/G spec_count = 0
		NVAR spec_count = root:spec_count
		Wave freq_w = root:LoadSPE_II:wb1_frequency
		Wave spec_w = root:LoadSPE_II:wb1_spectrum
			
		Variable/G base_channel = -1
		NVAR base_channel = root:base_channel
		NVAR pos_a = root:loadspe_uI:pos_a
		base_channel = abs( pos_a )
			
			
		Duplicate/O freq_w, root:mean_freq
		Duplicate/O spec_w, root:mean_spec
			 
		SetDataFolder $saveFolder
	endif
	
	Wave freq_w = root:LoadSPE_II:wb1_frequency
	Wave spec_w = root:LoadSPE_II:wb1_spectrum

	NVAR base_channel = root:base_channel		
	NVAR pos_a = root:LoadSpe_uI:pos_a	
	Variable this_pos = abs(pos_a)
	Duplicate/O spec_w, chan_w, adjusted_w
	chan_w = 1 + p + ( this_pos - base_channel )

	Wave chan_w = chan_w
	Wave adjusted_w = adjusted_w
			
	Wave mean_freq = root:mean_freq
	Wave mean_spec = root:mean_spec
	
	adjusted_w = interp( x, chan_w, spec_w )
	Variable numnan = 0
	WaveStats/Q mean_spec
	numnan += v_numnans + v_numinfs
	
	
	
	if( numnan == 0 )
		mean_spec *= spec_count
		
		mean_spec += spec_w
	
		spec_count += 1
		mean_spec/= spec_count

	endif
End

// Steps to Average Spectra with this crude driver
// Step 1:  Use Loader/Browser II to get a view of the candidate spectra
// Step 2:  Be sure to remove PN BK REF and the like from the set ... 
// one can span multiple zip archives by Shift Selecting them prior to Expansion
// Step 3:  Hardwire the desired settings into mSPE_WriteJob_TemplateZero()
// Step 3a:  be sure to set the destination folder -- only one new level deep (this is a bug which will be fixed later)
// what this means is say you want them to be written to c:\this_folder\averaged_spectra\tdla_by1000
// for this to work you need to be sure that c:\this_folder\averaged_spectra already exists.  The file writer only knows how to 
// make one directory 
// Step 3b:  For TemplateZero set the boxcar width in multiples of spectra (this isn't yet time aware)
// 
// Step 4:  Run the JobWriter ... currently mSPE_WriteJob_TemplateZero()
// This writes a text wave called Job_tw, which consists of instructions to the averager
//
// Step 5: Run mSPE_ProcJob_TemplateZero( number )
// set number to 0 for fastest (no screen updates), set number to 1 or 3 for update every, set to 2 or 3 for screen update on Spectral File Write

// AverageSpectra
//	Mark, Joanne
// find string code: eggplant
// First Run  mSPE_WriteJob_TemplateZero(  ) with whatever hard wired tweaks you desire
// then
// mSPE_ProcJob_TemplateZero( local_verbosity )
// The writeJob doesn't need to be reinvoked if you haven't changed any settings
// if you use loadspe to browse to a new series of data, the writeJob MUST be reinvoked

Function mSPE_WriteJob_TemplateZero(  )
	
	
	Variable idex, count = 0
	Variable tiny = 0, tiny_roll = 128
	String job_line
	String assoc_key = "ASSOC"
	String prima_key = "PRIMARY"
	String target_key = "TARGET"
	String sPath_key = "SPATH"
	
	String saveFolder = GetDataFolder(1)
	SetDataFolder root:; MakeAndOrSetDF( "LoadSPE_AVG" )
	
	Make/T/O/N=0 job_tw
	
	Wave/T job_tw = root:LoadSPE_AVG:job_tw
	
	Wave disp_SelWave = root:LOADSPE_UI:disp_SelWave
	Wave/T path_fileList = root:LOADSPE_UI:path_fileList
	Wave/T pack_fileList = root:LOADSPE_UI:pack_fileList
	Wave/T disp_fileList = root:LOADSPE_UI:disp_fileList
	idex = 0; count = numpnts( disp_SelWave )
	// Step 3 boxcar width -- in this template boxcar width is fixed at jcount in the line floor(100) below, 
	// read this as take 0-99 and average, then 100-199, then 200-299, etc...
	// See TemplateOne for a variable boxcar example
	Variable jdex = 0, jcount = floor(500)

	// Step 3 sub element -- set target path ONLY ONE DEEP and use only colons for \
	//	String target_path = "c:average_spe:tdla_by_100s_321" << for example c:average_spe needs to already exist
	//     Make sure that C:lab data exists
	String target_path = "e:hcho data:qcl:qcl0505_500sec"  //avg 500 1-sec spectra (did save every) 
	String source_pack
	String assoc_pack
	String spath
	printf "Preparing Average Spectra Job %d by %d\r", count, jcount
	do
		jdex = 0
		assoc_pack = pack_fileList[ idex + jdex ] 
		do
			spath = path_fileList[ idex + jdex ]
			source_pack = pack_fileList[ idex + jdex ]
			sprintf job_line, "%s>%s|%s>%s|%s>%s|%s>%s|", assoc_key, assoc_pack, prima_key, source_pack, target_key, target_path, sPath_key, sPath
			AppendString( job_tw, job_line )
			jdex += 1
		while( jdex < jcount )
		if( tiny > tiny_roll )
			printf ".\r"
			tiny = 0
		endif
		printf "."
		idex += jdex
	while( idex < count )
	
	printf "x\r"
	SetDataFolder $saveFolder
End

Function mSPE_WriteJob_TemplateOne(  )
	
	
	Variable idex, count = 0
	Variable tiny = 0, tiny_roll = 128
	String job_line
	String assoc_key = "ASSOC"
	String prima_key = "PRIMARY"
	String target_key = "TARGET"
	String sPath_key = "SPATH"
	
	String saveFolder = GetDataFolder(1)
	SetDataFolder root:; MakeAndOrSetDF( "LoadSPE_AVG" )
	
	Make/T/O/N=0 job_tw
	
	Wave/T job_tw = root:LoadSPE_AVG:job_tw
	
	Wave disp_SelWave = root:LOADSPE_UI:disp_SelWave
	Wave/T path_fileList = root:LOADSPE_UI:path_fileList
	Wave/T pack_fileList = root:LOADSPE_UI:pack_fileList
	Wave/T disp_fileList = root:LOADSPE_UI:disp_fileList
	idex = 0; count = numpnts( disp_SelWave )
	Variable jdex = 0, jcount = 500, mult = 5
	//	String target_path = "e:mydocuments:out60:"
	String target_path = "e:mydocuments:outMarch:"
	String source_pack
	String assoc_pack
	String spath
	printf "Preparing Average Spectra Job %d by %d\r", count, jcount
	Variable fade = 0
	do
		jdex = 0; jcount = idex
		assoc_pack = pack_fileList[fade ] 
		do
			spath = path_fileList[  jdex ]
			source_pack = pack_fileList[  jdex ]
			sprintf job_line, "%s>%s|%s>%s|%s>%s|%s>%s|", assoc_key, assoc_pack, prima_key, source_pack, target_key, target_path, sPath_key, sPath
			AppendString( job_tw, job_line )
			jdex += 1
		while( jdex < jcount )
		printf "%d to %d\r", idex, count
		if( idex == 0 )
			idex = 1
		else
			if( idex < 50 )
				idex += 5
			else
				if( idex < 500 )
					idex += 50
				else
					if( idex < 3500 )
						idex += 500
					else
						if( idex < 7500 )
							idex += 1000
						else 
							idex = count
						endif
					endif
				endif
			endif
		endif
		fade += 1
	while( idex < count )
	
	printf "x\r"
	SetDataFolder $saveFolder
End
// set local_verbosity bit 0 to true for frequent updates
// set local_verbosity bit 1 to true for update on completed average
Function mSPE_ProcJob_TemplateZero( local_verbosity )
	Variable local_verbosity
	
	String job_line
	String assoc_key = "ASSOC"
	String prima_key = "PRIMARY"
	String target_key = "TARGET"
	String spath_key = "SPATH"
	
	String UpdateGraphWin = "mSPE_StatusGraph"
	
	String saveFolder = GetDataFolder(1)
	SetDataFolder root:; MakeAndOrSetDF( "LoadSPE_AVG" )
	
	String outfilename, fullpath 
	Variable use_pressure, use_temp, use_timestamp
	
	Wave/T/Z job_tw = root:LoadSPE_AVG:job_tw
	if( WaveExists( job_tw ) != 1 )
		printf "Cannot proceed; job_tw not referenced\r"
		return -1
	endif
	

	Variable idex = 0, count = numpnts( job_tw )
	Variable tiny = 0, tiny_roll = 128
	
	SVAR/Z this_assoc_pack = root:LoadSPE_AVG:this_assoc_pack
	if( SVAR_Exists( this_assoc_pack ) != 1 )
		String/G this_assoc_pack = "nil"
		SVAR this_assoc_pack = root:LoadSPE_AVG:this_assoc_pack
	endif
	this_assoc_pack = "new"
	
	NVAR/Z average_verbosity = root:LoadSPE_UI:average_verbosity
	if( NVAR_Exists( average_verbosity ) != 1 )
		String this_folder_vebo = GetDataFolder(1); SetDataFolder root:
		MakeAndOrSetDF( "LoadSPE_UI" ); Variable/G average_verbosity = 1
		NVAR average_verbosity = root:LoadSPE_UI:average_verbosity
		SetDataFolder $this_folder_vebo
	endif
	average_verbosity = 0
	
	Variable num_funnyNumbers = 0
	String target_path
	String source_pack
	String assoc_pack
	String spath
	Variable powerbrowse_trap, this_offset_is
	printf "Begin Spectral Averaging %d\r", count
	
	do
		job_line = job_tw[idex]
		
		target_path = StringByKey( target_key, job_line, ">", "|" )
		source_pack = StringByKey( prima_key, job_line, ">", "|" )
		assoc_pack = StringByKey( assoc_key, job_line, ">", "|" )
		spath = StringByKey( spath_key, job_line, ">", "|" )
		
		if( (cmpstr( this_assoc_pack, assoc_pack ) == 0 ) & (idex < count - 1) )
			// then we continue in this average
			
			// force a load
			powerbrowse_trap = zSPE2_PowerBrowsePackedFile( source_pack, spath )
			SetDataFolder root:; SetDataFolder LoadSPE_AVG
			if( powerbrowse_trap == 1 )
				num_funnyNumbers = 0
				Wave wbx_frequency = root:LoadSPE_II:wb2_frequency
				Wave wbx_spectrum = root:LoadSPE_II:wb2_spectrum
				Wave wbx_trans_spectrum = root:LoadSPE_II:wb2_trans_spectrum
				NVAR base_channel_x = root:LoadSPE_AVG:base_channel_1
				NVAR channel_offset = root:LoadSPE_AVG:channel_offset
				NVAR this_peakPos = root:LoadSPE_II:SPE_PeakPos1
				NVAR avg_spectral_count = root:LoadSPE_AVG:avg_spectral_count
				
				WaveStats/Q wbx_spectrum
				num_funnyNumbers = V_numNans + V_numInfs
				if( num_funnyNumbers == 0 )
					Wave avg_frequency = root:LoadSPE_AVG:avg_frequency
					Wave avg_spectrum = root:LoadSPE_AVG:avg_spectrum
					Wave avg_trans_spectrum = root:LoadSPE_AVG:avg_trans_spectrum
					Wave wbx_spectrum = root:loadspe_II:wb2_spectrum
					Duplicate/O wbx_spectrum, new_channelScale, new_Spectrum
					channel_offset = -1 * abs( this_peakPos ) + base_channel_x
					//channel_offset =0
					//this_offset_is = channel_offset + enoise(1) /////////// This would represent a mechanism for an electronic dithering of the signal to average 'card noise' phenom
					this_offset_is = channel_offset		

					new_channelScale = 12+p + this_offset_is
					new_Spectrum = interp( x, new_channelScale, wbx_spectrum )
					Wave/Z base_bar = root:LoadSPE_AVG:base_bar
					if( WaveExists( base_bar ) != 1 )
						String ttsave = getdatafolder(1); SetDataFolder root:; MakeAndOrSetDF("LoadSPE_AVG");
						Make/N=2/O base_bar, this_spec_bar, offset_to_bar
						base_bar = 1010 * p; this_spec_bar = 1010 * p; offset_to_bar = 1010 * p
					endif
					Wave base_bar = root:LoadSPE_AVG:base_bar
					Wave this_spec_bar = root:LoadSPE_AVG:this_spec_bar
					Wave offset_to_bar = root:LoadSPE_AVG:offset_to_bar
					SetScale/P x, base_channel_x,                          1e-10, "chan", base_bar
					SetScale/P x, base_channel_x + channel_offset,  1e-10, "chan", this_spec_bar
					SetScale/P x, base_channel_x + this_offset_is,   1e-10, "chan", offset_to_bar
					WaveStats/R=(base_channel_x - 5, base_channel_x + 5)/Q wbx_spectrum
					
					base_bar[0] = V_Min - 1/2*( V_Max - V_Min); this_spec_bar[0] = V_Min; offset_to_bar[0] = V_Min
					base_bar[1] = V_Max;this_spec_bar[1] = V_Max; offset_to_bar[1] = V_Max + 1/2*(V_Max - V_min)
											
					avg_spectrum *= avg_spectral_count
					avg_spectrum += new_Spectrum
					avg_spectral_count += 1
					avg_spectrum /= avg_spectral_count
				
				
					NVAR SPE_CellPressure = root:LoadSPE_II:SPE_CellPressure
					NVAR SPE_CellTemperature = root:LoadSPE_II:SPE_CellTemperature
					NVAR SPE_timestamp = root:LoadSPE_II:SPE_timestamp
					NVAR SPE_PeakPos1 = root:LoadSPE_II:SPE_PeakPos1
					AppendVal( avgw_pressure, SPE_CellPressure )
					AppendVal( avgw_temperature, SPE_CellTemperature )
					AppendVal( avgw_timestamp, SPE_timestamp )
					AppendVal( avgw_PeakPos1, SPE_PeakPos1 )
					
					if( local_verbosity & 2^0 )
						DoWindow $UpdateGraphWin
						if( V_Flag )
							DoWindow/F $UpdateGraphWin
						else
							mSPE_DrawMSPE( UpdateGraphWin, avg_Spectrum, wbx_Spectrum, new_Spectrum, new_ChannelScale )
						endif
						ScaleAllYAxes("");
						doupdate
					endif
					
				endif
				
				
				printf "."; tiny += 1
				
			else
				printf "0"; tiny += 1
			endif
		else
			// we need to start a new average
			if( ((cmpstr( this_assoc_pack, "nil" ) != 0)) & (idex > 0 ) )
				// must process old one
				if( local_verbosity & 2^1 )
					DoWindow $UpdateGraphWin
					if( V_Flag )
						DoWindow/F $UpdateGraphWin
					else
						mSPE_DrawMSPE( UpdateGraphWin, avg_Spectrum, wbx_Spectrum, new_Spectrum, new_ChannelScale )
					endif
					doupdate
				endif
				printf "Finalizing > %s", this_assoc_pack; tiny = 0;
				Wave/T ThisFrame = root:LoadSPE_AVG:TemplateFrame
				SetDataFolder root:; SetDataFolder LoadSPE_AVG
			
				// now we'll use a squence of the following call to stack a new frame_tw
				//SPE2_InjectParamIntoFrame( param_name, param_val, frame_tw )
				NVAR  SPE_CellPressure = root:LoadSPE_II:SPE_CellPressure
				NVAR  SPE_CellTemperature = root:LoadSPE_II:SPE_CellTemperature
				NVAR  SPE_timestamp = root:LoadSPE_II:SPE_timestamp;
				
				
				Wave/D avgw_pressure = root:LoadSPE_AVG:avgw_pressure
				WaveStats/Q avgw_pressure; printf "P=%5.2f(%4.2f) . ", V_avg, V_sdev
				use_pressure = v_avg
				SPE2_InjectParamIntoFrame( "cell pressure", use_pressure, ThisFrame )
				
				Wave/D avgw_temperature = root:LoadSPE_AVG:avgw_temperature
				WaveStats/Q avgw_temperature; printf "T=%5.2f(%4.2f) . ", V_avg, V_sdev
				use_temp = v_avg
				SPE2_InjectParamIntoFrame( "cell temp", use_temp, ThisFrame )
				
				
				Wave/D avgw_timestamp = root:LoadSPE_AVG:avgw_timestamp
				WaveStats/Q avgw_timestamp; printf "."
				use_timestamp = v_avg * 1000
				SPE2_InjectParamIntoFrame( "timestamp", use_timestamp, ThisFrame )
				
				Wave avg_spectrum = root:LoadSPE_AVG:avg_spectrum
				SPE2_InjectFiveColumns2Frame( avg_spectrum, 1, ThisFrame )
				
				outfilename = SPE2_DateTime2WintelSPEName( use_timestamp / 1000 , "AVG")
				sprintf fullpath, "%s>>%s", target_path, outfilename
				printf "\r>>%s...", fullpath
				WriteTextWave2File( ThisFrame, target_path, outfilename )
				
				
				// then we should write a file name
				printf "\r"; 
				zSPE2_SessionPurge()
			endif
			
			if( idex < count - 1 )
				this_assoc_pack = assoc_pack
				printf "Initializing > %s || ", this_assoc_pack; tiny = 0
				// load the association file and let it initialize the average
				powerbrowse_trap = zSPE2_PowerBrowsePackedFile( this_assoc_pack, spath )
				SetDataFolder root:; SetDataFolder LoadSPE_AVG
				if( powerbrowse_trap != 1 )
					printf "Loading template for this_assoc_pack failed... this could be pretty serious.  Continuing\r"
				endif
				
				// quickly copy the frame for latter injection
				Wave/T ThisFrame = root:LoadSPE_UI:LoadSPE_Frame
				Duplicate/O ThisFrame, root:LoadSPE_AVG:TemplateFrame
				
				NVAR SPE_CellPressure = root:LoadSPE_II:SPE_CellPressure
				NVAR SPE_CellTemperature = root:LoadSPE_II:SPE_CellTemperature
				NVAR SPE_timestamp = root:LoadSPE_II:SPE_timestamp
				NVAR SPE_PeakPos1 = root:LoadSPE_II:SPE_PeakPos1
				
				Make/D/O/N=0 avgw_pressure, avgw_temperature, avgw_timestamp, avgw_peakPos1
				Variable/G this_begin_time = SPE_timestamp
				Variable/G base_channel_1 = abs(SPE_PeakPos1)
				
				AppendVal( avgw_pressure, SPE_CellPressure )
				AppendVal( avgw_temperature, SPE_CellTemperature )
				AppendVal( avgw_timestamp, SPE_timestamp )
				AppendVal( avgw_PeakPos1, SPE_PeakPos1 )
				
				
				// Spectral Template
				// mechanism for all 4 wb's to be determined
				Wave wbx_frequency = root:LoadSPE_II:wb2_frequency
				Wave wbx_spectrum = root:LoadSPE_II:wb2_spectrum
				Wave wbx_trans_spectrum = root:LoadSPE_II:wb2_trans_spectrum
				
				Wave avg_spectrum = root:LoadSPE_AVG:avg_spectrum
				
				Duplicate/O wbx_frequency, root:LoadSPE_AVG:avg_frequency
				Duplicate/O wbx_spectrum, avg_spectrum
				Duplicate/O wbx_trans_spectrum, root:LoadSPE_AVG:avg_trans_spectrum
				Variable/G avg_spectral_count = 1
				Variable/G channel_offset 
				// can use SPE2_ProcFrameAsSPE( frame_w ) to reset quantities prior to injection
			endif
			
		endif
		
		if( tiny > tiny_roll )
			tiny = 0; print "\r"
		endif
		
		idex += 1
	while( idex < count )
	
	SetDataFolder $saveFolder
	SetDataFolder root:
End

Function zSPE2_SessionPurge()
	String saveFolder = GetDataFolder(1)
	SetDataFolder root:
	SetDataFolder root:LoadSPE_UI
	
	String list = WaveList( "ses_*", ";", "" )
	Variable idex = 0, count = ItemsInList( list )
	if( count > 0 )
		do
			Wave ses_w = $StringFromList( idex, list )
			Redimension/N=0 ses_w
			idex += 1
		while( idex < count )
	endif
End

Function mSPE_DrawMSPE( UpdateGraphWin, avg_Spectrum, wbx_Spectrum, new_Spectrum, new_ChannelScale )
	String UpdateGraphWin
	Wave avg_Spectrum
	Wave wbx_spectrum
	Wave new_Spectrum
	Wave new_ChannelScale
	
	Display/L=average_ax avg_Spectrum as UpdateGraphWin
	DoWindow/C $UpdateGraphWin
	Execute("HandyGraphButtons()")					
	AppendToGraph/L=raw_data wbx_spectrum
	AppendToGraph/L=raw_data new_Spectrum vs new_ChannelScale
	
	ModifyGraph grid=2,tick=2,mirror=1,minor=1,standoff=0
	ModifyGraph grid(raw_data)=0
	ModifyGraph gridRGB(average_ax)=(65280,0,0)
	ModifyGraph freePos(raw_data)=0
	ModifyGraph mode(wb2_spectrum)=4,rgb(wb2_spectrum)=(0,52224,0);DelayUpdate
	ModifyGraph rgb(new_Spectrum)=(0,12800,52224)
	ModifyGraph axRGB(raw_data)=(0,12800,52224),tlblRGB(raw_data)=(0,12800,52224);DelayUpdate
	ModifyGraph alblRGB(raw_data)=(0,12800,52224)
	ModifyGraph axRGB(average_ax)=(65280,0,0),tlblRGB(average_ax)=(65280,0,0);DelayUpdate
	ModifyGraph alblRGB(average_ax)=(65280,0,0)
	
	Wave base_bar = root:LoadSPE_AVG:base_bar
	Wave this_spec_bar = root:LoadSPE_AVG:this_spec_bar
	Wave offset_to_bar = root:LoadSPE_AVG:offset_to_bar
	
	AppendToGraph/L=raw_data base_bar, this_spec_bar, offset_to_bar
	ModifyGraph rgb(this_spec_bar)=(0,52224,0),rgb(offset_to_bar)=(0,12800,52224)
	ModifyGraph lsize(base_bar)=2,rgb(base_bar)=(0,0,0)
	TextBox/C/N=legend_one/F=0/S=3/B=1/A=MC "\\Z09\\s(avg_spectrum) average \\s(wb1_spectrum) loaded\\s(new_Spectrum) channel offset"
End
Function/T SPE2_DateTime2WintelSPEName( adatetime, spe_type )
	variable adatetime
	String spe_type
	string yy = Secs2Date( adatetime,0)
	
	// THESE depend on regional settings in computer control panels... sucks
	String year = StringFromList( 2, yy, "/" )
	String month = StringFromList( 0, yy, "/" )
	String day = stringfromlist( 1, yy, "/" )
	
	String dateComponent
	sprintf dateComponent, "%2s%2s%2s",  year, month, day
	
	sprintf yy, "%s_%s" dateComponent, Secs2Time( adatetime, 3 )
	
	yy = scReplaceCharWChar( yy, " ", "0" )
	yy = scReplaceCharWChar( yy, "/", "" )
	yy = scReplaceCharWChar( yy, ":", "" )
	
	yy = yy + "_1.spe"
	return yy
End

Function SPE2_WintelSPEName2DateTime( spename )
	String spename
	
	Variable adatetime
	string yy = Secs2Date( adatetime,0)
	
	// THESE depend on regional settings in computer control panels... sucks
	String year = "20" + spename[ 0, 1]
	String month = spename[ 2, 3]
	String day =  spename[ 4, 5]
	
	adatetime = Date2Secs( str2num( year ), str2num( month ), str2num( day ) )
	
	String hour = spename[ 7, 8 ]
	String minute = spename[ 9, 10 ]
	String second = spename[ 11, 12 ]
	
	adatetime += str2num( second ) + 60*str2num( minute ) + 3600*str2num( hour )
	
	return adatetime
End

Function XOPBackMakePath( pathStr )
	String pathStr
	
	printf "New Path >> %s\r", pathStr
	NewPath/O/C scx2, pathStr
	KillPath/Z scx2
End
// LoadPlayDotOut needs an igor style full path and a destination data folder
// inovkes
// LoadSPE2.ipf
// 		zSPE2_LoadTextToFrame
// Global_Utils.ipf
//		MakeAndOrSetDF
//		AddLeadingZeroToBase10
//		AppendString
// 		AppendVal
// zSPE2_LoadTextToFrame takes full path file and textwave
// The text wave comes back with the contents of the file
// it is parsed as though it were a play.out style file == Note that any permutation of \r & \n as terminators is tolerated
Function LoadPlayDotOut( filefp, destDF )
	String filefp, destDF
	
	String saveFolder = GetDataFolder(1);
	SetDataFolder root:; MakeAndOrSetDF( destDF );
	// create empty socket for text of file as text wave & fill
	Make/N=0/T/O file_tw;
	zSPE2_LoadTextToFrame( filefp, file_tw )
	 
	Variable NULL_READ_VAL = Nan;
	Variable idex = 0, count = numpnts( file_tw ), this_conversions, always_conversions
	Variable adatetime, mr1, mr2, mr3, mr4, mr5, mr6, mr7, mr8,  month, day, year, hour, minute, second
	String buffer, fpfile, textDT, todCode, TextRepDateTime, ks_ThisLoadWin
	sprintf ks_ThisLoadWin, "PDO_Load_%s", destDF
	if( count > 0 )
		// create empty waves -- could change here to make refs for cumulative loading
		// not sure if this would ever be desired in play.out loading
		Make/N=0/T/O FullPath2File_tw, TextRepDateTime_tw
		Make/N=0/D/O mr_8, mr_7, mr_6, mr_5, mr_4, mr_3, mr_2, mr_1, source_atime
		SetScale/P y, 0, 0, "dat", source_atime
		always_conversions = 1// established by reading the format string argument to sscanf
		do
			buffer = file_tw[idex];
			// pull first two text elements as first string in list, specifying Quote as the list separator
			// resultingly "string1" is not the zeroth but rather the oneth StringFromList
			fpfile = StringFromList( 1, buffer, "\"" )
			buffer = buffer[strlen(fpfile) + 2, strlen( buffer ) - 1];
			TextRepDateTime = StringFromList( 1, buffer, "\"" );
			buffer = buffer[ strlen(TextRepDateTime) + 3, strlen(buffer) - 1];
			sscanf TextRepDateTime, "%d/%d/%d %d:%d:%d %s", month, day, year, hour, minute, second, todCode
			
			// This beast will actually let us run input past the incoming strength and fill with zeros 
			sscanf buffer, "%f%f%f%f%f%f%f%f%f", adatetime, mr1, mr2, mr3, mr4, mr5, mr6, mr7, mr8
			this_conversions = V_Flag - always_conversions // rescue the number of conversions actually done
		
			// leaving mis read zeros isn't a good policy, convert to NULL_READ_VAL
			switch (this_conversions)
				case 1:
					mr2 = NULL_READ_VAL; mr3 = NULL_READ_VAL; mr4 = NULL_READ_VAL; mr5 = NULL_READ_VAL; mr6 = NULL_READ_VAL; mr7 = NULL_READ_VAL; mr8 = NULL_READ_VAL;
					break;
				case 2:
					mr3 = NULL_READ_VAL; mr4 = NULL_READ_VAL; mr5 = NULL_READ_VAL; mr6 = NULL_READ_VAL; mr7 = NULL_READ_VAL; mr8 = NULL_READ_VAL;
				case 3:
					mr4 = NULL_READ_VAL; mr5 = NULL_READ_VAL; mr6 = NULL_READ_VAL; mr7 = NULL_READ_VAL; mr8 = NULL_READ_VAL;
				case 4:
					mr5 = NULL_READ_VAL; mr6 = NULL_READ_VAL; mr7 = NULL_READ_VAL; mr8 = NULL_READ_VAL;
				case 5:
					mr6 = NULL_READ_VAL; mr7 = NULL_READ_VAL; mr8 = NULL_READ_VAL;
				case 6:
					mr7 = NULL_READ_VAL; mr8 = NULL_READ_VAL;
				case 7:
					mr8 = NULL_READ_VAL;
				case 8:
					// no changed required...						
			endswitch
			
			// reform a string from the text datetime
			sprintf textDT, "%d/%d/%d %s:%s:%s %s", month, day, year, AddLeadingZeroToBase10( num2str(hour), 2), AddLeadingZeroToBase10( num2str(minute), 2),  AddLeadingZeroToBase10( num2str(second), 2),  todCode
			// convert tdlwintel miliseconds to igor seconds
			adatetime /= 1000;

			// add vals in lockstep
			AppendString( TextRepDateTime_tw, textDT )
			AppendString( FullPath2File_tw, fpfile )
			AppendVal( source_atime,  adatetime )
			AppendVal( mr_1, mr1 );  AppendVal( mr_2, mr2 )
			AppendVal( mr_3, mr3 );  AppendVal( mr_4, mr4 )
			AppendVal( mr_5, mr5 );  AppendVal( mr_6, mr6 )
			AppendVal( mr_7, mr7 );  AppendVal( mr_8, mr8 )
			idex += 1;
		while( idex < count )
		DoWindow $ks_ThisLoadWin
		if( V_Flag )
			DoWindow/F $ks_ThisLoadWin
		else
			Edit FullPath2File_tw, TextRepDateTime_tw, source_atime, mr_1, mr_2, mr_3, mr_4, mr_5, mr_6, mr_7, mr_8 as ks_ThisLoadWin
			ModifyTable format(source_atime)=8
			DoWindow/C $ks_ThisLoadWin
		endif
	endif // count > 0
	SetDataFolder $saveFolder
End

// avg_code 1 equals to the minute
// avg_code 5 equals to the five minute
// avg_code 60 equals to the hour
Function STR_ConventionalAvg( prefix, avg_code )
	String prefix
	Variable avg_code
	
	String source_time_str
	String w_str
	Variable idex = 0, spec_count = 8
	String targ_time_str
	String targ_w_str
	Variable begin_time, end_time
	Variable begin_dex, end_dex
	
	sprintf source_time_str, "%s_source_rtime", prefix
	Wave source_time_w = $source_time_str
	if( WaveExists( source_time_w ) != 1 )
		printf "Cannot find reference wave %s -- edit code or figure prefix\r", source_time_str
		return -1
	endif
	sprintf targ_time_str, "%s%d_source_atime", prefix, avg_code
	Make/N=0/O/D $targ_time_str
	Wave/D targ_time_w = $targ_time_str
	idex = 0
	do
		sprintf w_str, "%s%d_mr%d", prefix, avg_code, idex+1
		Make/O/N=0/D $w_str
		Wave/D w = $w_str
		idex += 1
	while( idex < spec_count )
	
	Variable last_time = source_time_w[numpnts( source_time_w)];
	Variable this_time;
	
	idex = 0
	begin_time = CutTimeToTheMinute( source_time_w[0] )
	do
		this_time = begin_time;
		begin_dex = BinarySearch( source_time_w, begin_time );
		begin_dex = StandardSearchCleanse( begin_dex, source_time_w );
		
		end_time = begin_time + 60 * avg_code 
		end_dex = BinarySearch( source_time_w, end_time );
		end_dex = StandardSearchCleanse( end_dex, source_time_w );
		
		AppendVal( targ_time_w, (begin_time + end_time)/2 );
		idex = 0
		do
			sprintf targ_w_str, "%s_mr%d", prefix, idex+1
			Wave/Z targ_w= $targ_w_str
			if( WaveExists( targ_w ) == 1 )
				sprintf w_str, "%s%d_mr%d", prefix, avg_code, idex+1
				Wave/D w = $w_str
			
				WaveStats/Q/R=[begin_dex, end_dex ] targ_w
				AppendVal( w, v_avg )
			endif
			idex += 1
		while( idex < spec_count )
		//		San Demis Highschool Football Rules!
	
		begin_time = end_time;
	while( this_time < last_time )
	
End

Function StandardSearchCleanse( adex, awav )
	Variable adex
	Wave awav
	
	Variable ret = adex;
	if( adex == -1 )
		ret = 0;
	endif
	if( adex == -2 )
		ret = numpnts( awav )
	endif
	
	return ret;
End
Function CutTimeToTheMinute( adatetime )
	Variable adatetime 
	
	Variable year, month, day, hour, minute, second
	String timestr
	
	timestr = DateTime2Text( adatetime )
	sscanf timestr, "%d/%d/%d %d:%d:%d", month, day, year, hour, minute, second
	sprintf timestr, "%d/%d/%d %d:%d:%d", month, day, year, hour, minute, 0
	
	return Text2DateTime( timestr )
End

Function QuickCopyToRoot( prefix, sweep )
	String prefix
	Variable sweep
	
	
	Wave/D wb1_igr_cur = root:LoadSPE_II:wb1_igr_cur
	Wave/D wb1_wintel_cur = root:LoadSPE_II:wb1_wintel_cur
	Wave/D wb1_trans_fit = root:LoadSPE_II:wb1_trans_fit
	Wave/D wb1_trans_spectrum = root:LoadSPE_II:wb1_trans_spectrum
	Wave/D wb1_wintel_fit = root:LoadSPE_II:wb1_wintel_fit
	Wave/D wb1_wintel_base = root:LoadSPE_II:wb1_wintel_base
	Wave/D wb1_spectrum = root:LoadSPE_II:wb1_spectrum
	Wave/D wb1_frequency = root:LoadSPE_II:wb1_frequency
	Wave/T params_tw = root:LoadSPE_II:params_tw	
	Wave/T header_tw = root:LoadSPE_II:header_tw	

	Wave/D wb2_igr_cur = root:LoadSPE_II:wb2_igr_cur;	Wave/D wb2_wintel_cur = root:LoadSPE_II:wb2_wintel_cur; 	Wave/D wb2_trans_fit = root:LoadSPE_II:wb2_trans_fit;	Wave/D wb2_trans_spectrum = root:LoadSPE_II:wb2_trans_spectrum
	Wave/D wb2_wintel_fit = root:LoadSPE_II:wb2_wintel_fit;	Wave/D wb2_wintel_base = root:LoadSPE_II:wb2_wintel_base
	Wave/D wb2_spectrum = root:LoadSPE_II:wb2_spectrum;	Wave/D wb2_frequency = root:LoadSPE_II:wb2_frequency;

	Wave/D wb3_igr_cur = root:LoadSPE_II:wb3_igr_cur;	Wave/D wb3_wintel_cur = root:LoadSPE_II:wb3_wintel_cur; 	Wave/D wb3_trans_fit = root:LoadSPE_II:wb3_trans_fit;	Wave/D wb3_trans_spectrum = root:LoadSPE_II:wb3_trans_spectrum
	Wave/D wb3_wintel_fit = root:LoadSPE_II:wb3_wintel_fit;	Wave/D wb3_wintel_base = root:LoadSPE_II:wb3_wintel_base
	Wave/D wb3_spectrum = root:LoadSPE_II:wb3_spectrum;	Wave/D wb3_frequency = root:LoadSPE_II:wb3_frequency;

	Wave/D wb4_igr_cur = root:LoadSPE_II:wb4_igr_cur;	Wave/D wb4_wintel_cur = root:LoadSPE_II:wb4_wintel_cur; 	Wave/D wb4_trans_fit = root:LoadSPE_II:wb4_trans_fit;	Wave/D wb4_trans_spectrum = root:LoadSPE_II:wb4_trans_spectrum
	Wave/D wb4_wintel_fit = root:LoadSPE_II:wb4_wintel_fit;	Wave/D wb4_wintel_base = root:LoadSPE_II:wb4_wintel_base
	Wave/D wb4_spectrum = root:LoadSPE_II:wb4_spectrum;	Wave/D wb4_frequency = root:LoadSPE_II:wb4_frequency;


	String source_list = "spectrum;frequency;trans_fit;wintel_fit;wintel_base;trans_spectrum;"
	String this_str
	String fab_str
	String tobenamed_str
	Variable idex = 0, count = ItemsInList( source_list )
	do
		this_str = StringFromList( idex, source_list )
		
		sprintf fab_str, "root:LoadSPE_II:wb%d_%s", sweep, this_str
		
		Wave/Z s_w = $fab_str
		if( WaveExists( s_w ) != 1 )
			printf "Error in QuickCopyToRoot( %s, %d ) -- cannot reference %s\r", prefix, sweep, fab_str
			return -1
		endif
		
		sprintf tobenamed_str, "root:%s%d_%s", prefix, sweep, this_str
		Duplicate/O s_w, $tobenamed_str
		
		idex += 1
	while( idex < count )
End

Function Core_Cut2Min( atime )
	Variable atime
	
	String time_as_str = DateTime2Text( atime )
	String time_from_str
	Variable month, day, year
	Variable hour, minute, second
	
	sscanf time_as_str, "%d/%d/%d %d:%d:%d", month, day, year, hour, minute, second
	
	sprintf time_from_str, "%d/%d/%d %d:%d:%d", month, day, year, hour, minute, 0
	
	return Text2DateTime( time_from_str )
End

Function Core_DataXY2Minute( x_w, y_w, min_w, str_fix )
	Wave x_w, y_w, min_w
	String str_fix
	
	Variable idex = 0, count = numpnts( min_w )
	Variable bdex, edex
	
	Variable val_avg, val_med, val_std, start_minute
	String targ_avg, targ_med, targ_std
	
	sprintf targ_avg, "min_avg_%s", str_fix
	sprintf targ_med, "min_med_%s", str_fix
	sprintf targ_std, "min_std_%s", str_fix
	
	Duplicate/O min_w, $targ_avg, $targ_med, $targ_std
	Wave avg_w = $targ_avg; Wave med_w = $targ_med; Wave std_w = $targ_std
	SetScale/P y, 0, 0, "", avg_w, med_w, std_w
	SetScale/P x, min_w[0], 60, "dat", avg_w, med_w, std_w

	avg_w = Nan
	med_w = Nan
	std_w = Nan
	
	do
		start_minute = Core_Cut2Min( min_w[idex] )
		val_avg = nan; val_med = nan; val_std = nan
		
		bdex = BinarySearch( x_w, start_minute )
		edex = BinarySearch( x_w, start_minute + 59.999999999999999 )
		
		if( bdex == -1 )
			bdex = 0
		endif
		if( edex == -2 )
			edex = numpnts( y_w ) - 1
		endif
		
		WaveStats/Q/R=[bdex, edex ] y_w
		val_avg = v_avg
		val_std = v_sdev
		Duplicate/O/R=[bdex, edex] y_w, supertempmedianwave
		SortAndKillNans( "supertempmedianwave", 0 )
		val_med = supertempmedianwave[ (numpnts( supertempmedianwave ) - 1 ) /2]
		KillWaves/Z supertempmedianwave
		
		avg_w[idex] = val_avg
		med_w[idex] = val_med
		std_w[idex] = val_std
	
		idex += 1
	while( idex < count )
End

Function Core_MakeStdMinWave( btime, etime )
	Variable btime, etime 
	
	Variable start_time = Core_Cut2Min( btime )
	Variable end_time = Core_Cut2Min( etime )
	
	Variable minutes = (end_time - start_time ) / 60
	
	Make/D/O/N=(minutes) min_TimeWave
	
	min_TimeWave = p * 60 + start_time + 30
	SetScale/P y, 0, 0, "dat", min_TimeWave
End

Function HackSomeQCL( btime, etime )
	Variable btime, etime
	
	SetDataFolder root:
	Core_MakeStdMinWave( btime, etime )
	Wave t_w = min_TimeWave
	
	// get CO data crunched
	SetDataFolder root:
	Wave co_x = root:co_source_rtime
	Wave co_y = root:co_mr1
	Wave no2_y = root:co_mr2
	
	Core_DataXY2Minute( co_x, co_y,  t_w, "CO" )
	Core_DataXY2Minute( co_x, no2_y,  t_w, "NO2" )
	
	// do HCHO and NH3 and HNO3
	 
	SetDataFolder root:
	 
	Wave time_x = root:min1_re:source_atime
	Wave nh3_y = root:min1_re:mr_2
	Wave hcho_y = root:min1_re:mr_3
	Wave hno3_y = root:min1_re:mr_4
	Wave mzd_y = root:min1_re:mr_5
	 
	Core_DataXY2Minute( time_x, nh3_y,  t_w, "NH3" )
	Core_DataXY2Minute( time_x, hcho_y,  t_w, "HCHO" )
	Core_DataXY2Minute( time_x, hno3_y,  t_w, "HNO3" )
	Core_DataXY2Minute( time_x, mzd_y,  t_w, "MZ" )

End
	 
	 
Function AverageTimeWithinHour()
	
	String prefix = "cal"
	
	Wave time_w = $( prefix + "_source_rtime" )
	Wave mr1_w = $( prefix + "_mr1" )
	Wave mr2_w = $( prefix + "_mr2" )
	Wave mr3_w = $( prefix + "_mr3" )
	Wave mr4_w = $( prefix + "_mr4" )
	Wave mr5_w = $( prefix + "_mr5" )
	
	Variable kdex = 1, kcount = 5
	Variable second_of_hour, idex, count
	String this_str, minute_str, second_str
	Variable this_second
	
	do
		Wave source_w = $(prefix + "_mr" + num2str( kdex ))
		
		Make/N=3600/D/O average_on_minute, count_on_minute
		average_on_minute = 0; count_on_minute = 0
	
	
		idex = 0; count = numpnts( time_w )
		do
			this_str =Secs2Time( time_w[idex], 3 )
			minute_str = StringFromList( 1, this_str, ":" )
			second_str = StringFromList( 2, this_str, ":" )
			this_second = str2num( minute_str ) * 60 + str2num( second_str )
			average_on_minute[ this_second ] += source_w[idex]
			count_on_minute[ this_second ] += 1
			idex += 1
		while( idex < count )
		average_on_minute /= count_on_minute
		Duplicate/O average_on_minute, $( "average" + num2str( kdex ) )
		
		kdex += 1
	while( kdex < kcount )
End

Function STR_or_STC_to_SelectTS_DAT( ) :GraphMarquee

	String trace_list = TraceNameList( "", ";", 1 )
	
	
	Wave/Z an_X_Wave=XWaveRefFromTrace( "", StringFromList( 0, trace_list ) )
	Make/N=0/T/O SelectTS_dot_DAT_tw
	Wave/T tw = SelectTS_dot_DAT_tw
	Make/N=0/D/O SelectTS_dot_DAT_w
	Wave/D w = SelectTS_dot_DAT_w
	
	String axis_list = AxisList( "" )
	Variable idex, count = ItemsInList( axis_list )
	String this_ax, this_nfo
	String left_ax = "left"
	String bot_ax = "bottom"
	String this_str

	for( idex = 0; idex < count; idex += 1 )
		this_ax = StringFromList( idex, axis_list )
		this_nfo = AxisInfo( "", this_ax )
		if( cmpstr( StringByKey( "AXTYPE", this_nfo ), "left" ) == 0 )
			left_ax = this_ax
		endif
		if( cmpstr( StringByKey( "AXTYPE", this_nfo ), "bottom" ) == 0 )
			bot_ax = this_ax
		endif
	endfor		
	Variable lo_bot_bound, hi_bot_bound, lo_left_bound, hi_left_bound
	Variable lo_bot_pnt, hi_bot_pnt
	
	GetMarquee/K $left_ax, $bot_ax	
	lo_bot_bound = V_Left
	hi_bot_bound = V_Right
	lo_left_bound = V_Bottom
	hi_left_bound = V_Top
		
	printf "Acting on R:%g to L:%g and/or Low:%g up to Hi:%g\r", lo_bot_bound, hi_bot_bound, lo_left_bound, hi_left_bound
		
	Variable start_dex = BinarySearch( an_X_Wave, lo_bot_bound )
	Variable end_dex =  BinarySearch( an_X_Wave, hi_bot_bound )
	for( idex =  start_dex;  idex < end_dex; idex += 1 )
		AppendVal( w, an_X_Wave[idex] )
		AppendString( tw, DateTime2Text( an_X_Wave[idex] ) )
	endfor
		
	DoWindow SelectTS_dot_DAT_Win
	if( !V_Flag )
		Edit as "SelectTS_dot_DAT_Win"
		DoWindow/C SelectTS_dot_DAT_Win
		AppendToTable SelectTS_dot_DAT_tw, SelectTS_dot_DAT_w
	endif
		
		
	Duplicate/O tw, write_tw
	Wave/T ttw = write_tw
	for( idex = 0; idex < numpnts( write_tw ); idex += 1 )
		sprintf this_str, "%11u", w[idex]
		ttw[idex] = this_str
	endfor
End


#pragma rtGlobals=1		// Use modern global access method.

Proc mySTCStyle() : GraphStyle
	PauseUpdate; Silent 1		// modifying window...
	ModifyGraph/Z margin(left)=108
	ModifyGraph/Z rgb[0]=(0,0,0),rgb[2]=(1,12815,52428),rgb[3]=(0,0,0),rgb[4]=(65535,21845,0)
	ModifyGraph/Z rgb[5]=(52224,34816,0),rgb[6]=(26214,0,0),rgb[8]=(1,12815,52428),rgb[9]=(1,3,39321)
	ModifyGraph/Z rgb[10]=(0,0,0),rgb[11]=(0,0,0),rgb[12]=(0,0,0)
	ModifyGraph/Z gridRGB(stc_Range_F_1_L_1_ax)=(65280,0,0),gridRGB(stc_Range_F_1_L_2_ax)=(0,0,65280)
	ModifyGraph/Z gridRGB(stc_Praw_ax)=(0,52224,0),gridRGB(stc_Traw_ax)=(30464,30464,30464)
	ModifyGraph/Z gridRGB(stc_Tref_ax)=(52224,34816,0),gridRGB(stc_X1_ax)=(0,0,0),gridRGB(stc_pos1_ax)=(0,0,0)
	ModifyGraph/Z gridRGB(stc_X2_ax)=(0,0,0),gridRGB(stc_pos2_ax)=(0,0,0),gridRGB(mr1_ax)=(0,0,0)
	ModifyGraph/Z gridRGB(mr4_ax)=(0,0,0)
	ModifyGraph/Z axRGB(stc_Range_F_1_L_1_ax)=(65280,0,0),axRGB(stc_Range_F_1_L_2_ax)=(0,0,65280)
	ModifyGraph/Z axRGB(stc_Traw_ax)=(65535,21845,0),axRGB(stc_Tref_ax)=(52224,34816,0)
	ModifyGraph/Z axRGB(stc_X1_ax)=(26214,0,0),axRGB(stc_pos1_ax)=(65535,0,0),axRGB(stc_X2_ax)=(1,12815,52428)
	ModifyGraph/Z axRGB(stc_pos2_ax)=(1,3,39321)
	ModifyGraph/Z tlblRGB(stc_Range_F_1_L_1_ax)=(65280,0,0),tlblRGB(stc_Range_F_1_L_2_ax)=(0,0,65280)
	ModifyGraph/Z tlblRGB(stc_Traw_ax)=(65535,21845,0),tlblRGB(stc_Tref_ax)=(52224,34816,0)
	ModifyGraph/Z tlblRGB(stc_X1_ax)=(26214,0,0),tlblRGB(stc_pos1_ax)=(65535,0,0),tlblRGB(stc_X2_ax)=(1,12815,52428)
	ModifyGraph/Z tlblRGB(stc_pos2_ax)=(1,3,39321)
	ModifyGraph/Z alblRGB(stc_Range_F_1_L_1_ax)=(65280,0,0),alblRGB(stc_Range_F_1_L_2_ax)=(0,0,65280)
	ModifyGraph/Z alblRGB(stc_Traw_ax)=(65535,21845,0),alblRGB(stc_Tref_ax)=(52224,34816,0)
	ModifyGraph/Z alblRGB(stc_X1_ax)=(26214,0,0),alblRGB(stc_pos1_ax)=(65535,0,0),alblRGB(stc_X2_ax)=(1,12815,52428)
	ModifyGraph/Z alblRGB(stc_pos2_ax)=(1,3,39321)
	ModifyGraph/Z lblPos(stc_Range_F_1_L_1_ax)=-29,lblPos(stc_Range_F_1_L_2_ax)=-84
	ModifyGraph/Z lblPos(stc_Praw_ax)=-16,lblPos(stc_Traw_ax)=-11,lblPos(stc_Tref_ax)=-11
	ModifyGraph/Z lblPos(stc_pos1_ax)=108,lblPos(stc_pos2_ax)=102,lblPos(mr1_ax)=-98
	ModifyGraph/Z lblPos(mr4_ax)=-1
	ModifyGraph/Z lblLatPos(stc_Range_F_1_L_1_ax)=-20,lblLatPos(stc_Range_F_1_L_2_ax)=2
	ModifyGraph/Z lblLatPos(stc_Tref_ax)=16,lblLatPos(stc_pos1_ax)=4,lblLatPos(stc_pos2_ax)=-2
	ModifyGraph/Z lblLatPos(mr1_ax)=-6,lblLatPos(mr4_ax)=-21
	ModifyGraph/Z lblRot(stc_Range_F_1_L_1_ax)=-90,lblRot(stc_Range_F_1_L_2_ax)=-90
	ModifyGraph/Z lblRot(stc_Praw_ax)=-90,lblRot(stc_Traw_ax)=-90,lblRot(stc_Tref_ax)=-90
	ModifyGraph/Z lblRot(stc_X1_ax)=-90,lblRot(stc_pos1_ax)=-90,lblRot(stc_X2_ax)=-90
	ModifyGraph/Z lblRot(stc_pos2_ax)=-90,lblRot(mr1_ax)=-90,lblRot(mr4_ax)=-90
	ModifyGraph/Z freePos(stc_Range_F_1_L_1_ax)=0
	ModifyGraph/Z freePos(stc_Range_F_1_L_2_ax)=55
	ModifyGraph/Z freePos(stc_Praw_ax)=55
	ModifyGraph/Z freePos(stc_Traw_ax)=0
	ModifyGraph/Z freePos(stc_Tref_ax)=43
	ModifyGraph/Z freePos(stc_X1_ax)=0
	ModifyGraph/Z freePos(stc_pos1_ax)=0
	ModifyGraph/Z freePos(stc_X2_ax)=0
	ModifyGraph/Z freePos(stc_pos2_ax)=0
	ModifyGraph/Z freePos(mr1_ax)=64
	ModifyGraph/Z freePos(mr4_ax)=15
	ModifyGraph/Z axisEnab(stc_Range_F_1_L_1_ax)={0,0.15}
	ModifyGraph/Z axisEnab(stc_Range_F_1_L_2_ax)={0,0.15}
	ModifyGraph/Z axisEnab(stc_Praw_ax)={0.28,0.32}
	ModifyGraph/Z axisEnab(stc_Traw_ax)={0.34,0.44}
	ModifyGraph/Z axisEnab(stc_Tref_ax)={0.18,0.26}
	ModifyGraph/Z axisEnab(stc_X1_ax)={0.7,0.75}
	ModifyGraph/Z axisEnab(stc_pos1_ax)={0.75,0.9}
	ModifyGraph/Z axisEnab(stc_X2_ax)={0.7,0.75}
	ModifyGraph/Z axisEnab(stc_pos2_ax)={0.75,0.9}
	ModifyGraph/Z axisEnab(mr1_ax)={0.45,0.55}
	ModifyGraph/Z axisEnab(mr4_ax)={0.55,0.65}
	ModifyGraph/Z dateInfo(bottom)={0,1,0}
	Label/Z stc_Range_F_1_L_1_ax "F1"
	Label/Z bottom " "
	Label/Z stc_Range_F_1_L_2_ax "F1"
	Label/Z stc_Praw_ax "P"
	Label/Z stc_Traw_ax "T"
	Label/Z stc_Tref_ax "T chiller"
	Label/Z stc_X1_ax "X"
	Label/Z stc_pos1_ax "pos"
	Label/Z stc_X2_ax "X"
	Label/Z stc_pos2_ax "pos"
	Label/Z mr1_ax "HCHO "
	Label/Z mr4_ax "OCS (ppbv)"
	SetAxis/Z/N=1 stc_Range_F_1_L_1_ax 3852.75,3880.95
	SetAxis/Z bottom 3356935822.66065,3356949197.76677
	SetAxis/Z/N=1 stc_Range_F_1_L_2_ax 5169.94,5263.11
	SetAxis/Z/N=1 stc_Praw_ax 41.4736,41.7539
	SetAxis/Z/N=1 stc_Traw_ax 302.8595,302.963
	SetAxis/Z/N=1 stc_Tref_ax 297.4491,297.7171
	SetAxis/Z/N=1 stc_X1_ax 0.05477,1.466
	SetAxis/Z/N=1 stc_pos1_ax 120.271,120.732
	SetAxis/Z/N=1 stc_X2_ax 0.03812,0.4013
	SetAxis/Z/N=1 stc_pos2_ax 567.958,569.272
	SetAxis/Z/N=1 mr1_ax -0.165592,1.98396
	SetAxis/Z/N=1 mr4_ax -0.0181231,0.528074
EndMacro


Function nSTR_a_Init()

	String saveFolder = GetDataFolder(1);	SetDataFolder root:;	MakeAndOrSetDF( "STRPanel_Folder" )	
	
	
	String destStr, type, name, list = "", this_, defStr
	Variable num, defVal
	Variable idex, count
 
	list = list + "TYPE>String;NAME>msg;INIT:notset;" + "~"

	//   Background
	//
	//  Each of the four vectors, analyte, primary, auxiliary, analyte-B
	//	get per plume the start, stop times from the QAQCer
	//	and add
	//	time shift
	//	initial and final background 'times'
	//	initial and final background values
	//	an extra method code
	//	 

	list = list + "TYPE>String;NAME>DataPathOnDisk;INIT>0;" + "~"
	list = list + "TYPE>String;NAME>DestinationDataFolder;INIT>;" + "~"
	list = list + "TYPE>String;NAME>LoadedWaveNamesSTC;INIT>;" + "~"
	list = list + "TYPE>String;NAME>LoadedWaveNamesSTR;INIT>;" + "~"
	list = list + "TYPE>String;NAME>msg;INIT>;" + "~"
	list = list + "TYPE>Variable;NAME>PntsInThisFile;INIT>0;" + "~"
	list = list + "TYPE>Variable;NAME>PntsTotalTarget;INIT>0;" + "~"
	list = list + "TYPE>Variable;NAME>WintelGraphsIPFNeedsOpen;INIT>1;" + "~"
	list = list + "TYPE>Variable;NAME>WintelGraphsIPFNeedsWrite;INIT>0;" + "~"
	list = list + "TYPE>String;NAME>StashDestDF_STR_STC;INIT>;" + "~"
	list = list + "TYPE>String;NAME>StashDestDF_PB;INIT>a_pb;" + "~"
	list = list + "TYPE>String;NAME>StashDestDF_STany;INIT>a_sta;" + "~"
	list = list + "TYPE>String;NAME>StashDestDF_CAL;INIT>a_cal;" + "~"
	list = list + "TYPE>String;NAME>StashDestDF_Interp;INIT>a_interp;" + "~"
	list = list + "TYPE>String;NAME>StashDestDF_Future;INIT>b_str;" + "~"

	list = list + "TYPE>WaveT;NAME>found_str;PNTS>0;" + "~"
	list = list + "TYPE>WaveT;NAME>found_stc;PNTS>0;" + "~"
	list = list + "TYPE>WaveT;NAME>found_pb;PNTS>0;"+ "~"
	list = list + "TYPE>WaveT;NAME>found_cal;PNTS>0;"+ "~"
	list = list + "TYPE>WaveT;NAME>found_interp;PNTS>0;"+ "~"
	list = list + "TYPE>WaveT;NAME>found_stany;PNTS>0;"+"~"
	list = list + "TYPE>WaveT;NAME>found_stany_type;PNTS>0;"+"~"
	list = list + "TYPE>WaveT;NAME>LoadHistory;PNTS>0;" + "~"		
	list = list + "TYPE>WaveD;NAME>found_str_loaded;PNTS>0;" + "~"
	list = list + "TYPE>WaveD;NAME>found_stc_loaded;PNTS>0;" + "~"
	list = list + "TYPE>WaveD;NAME>found_str_dat0;PNTS>0;" + "~"
	list = list + "TYPE>WaveD;NAME>found_stc_dat0;PNTS>0;" + "~"
	list = list + "TYPE>WaveD;NAME>found_pb_dat0;PNTS>0;" + "~"
	list = list + "TYPE>WaveD;NAME>found_cal_dat0;PNTS>0;" + "~"
	list = list + "TYPE>WaveD;NAME>found_interp_dat0;PNTS>0;" + "~"
	list = list + "TYPE>WaveD;NAME>found_stany_dat0;PNTS>0;" + "~"
	list = list + "TYPE>WaveT;NAME>session_spec;PNTS>16;" + "~"
	list = list + "TYPE>WaveT;NAME>thisFile_spec;PNTS>16;" + "~"
		

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
		

	
	Make/T/O/N=(3,3) FileTimeDisplay_rcMat
	Make/T/O/N=(DimSize( FileTimeDisplay_rcMat, 1 )) 	FileTimeDisplay_Columntw
	Make/I/O/N=(DimSize( FileTimeDisplay_rcMat, 0 )) 	FileTimeDisplay_SelWave
	Make/O/N=(DimSize( FileTimeDisplay_rcMat, 0 ),3) 	FileTimeDisplay_ColorWave
		
	FileTimeDisplay_rcMat[][0] = "_notSet"
	FileTimeDisplay_rcMat[][1] = "_unknown"
	FileTimeDisplay_rcMat[][2] = "_notLoaded"
		
	FileTimeDisplay_Columntw[0] = "Datetime";
	FileTimeDisplay_Columntw[1] = "Type";
	FileTimeDisplay_Columntw[2] = "Loaded";

		
	SetDataFolder $saveFolder

	nSTR_h_ProbeCommonPaths();		// will set display path set variable	
	
	
End

Function nSTR_Z_DFStash(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			
			SVAR DestinationDataFolder 	= root:STRPanel_Folder:DestinationDataFolder
			SVAR StashDestDF_STR_STC 	= root:STRPanel_Folder:StashDestDF_STR_STC
			SVAR StashDestDF_PB			= root:STRPanel_Folder:StashDestDF_PB
			SVAR StashDestDF_CAL			= root:STRPanel_Folder:StashDestDF_CAL
			SVAR StashDestDF_Interp		= root:STRPanel_Folder:StashDestDF_Interp
			SVAR StashDestDF_Future		= root:STRPanel_Folder:StashDestDF_Future
			SVAR StashDestDF_STany		= root:STRPanel_Folder:StashDestDF_STany
			
			ControlInfo nSTR2014_FileFilter
			String popStr = S_Value;
			strswitch (popStr)
				case "sample str/stc":
					StashDestDF_STR_STC = sval;
					break;
				case "playback str":
					StashDestDF_PB = sval;
					break;
				case "calibration _CAL.str":
					StashDestDF_CAL = sval;
					break;
				case "EddyOut _Interp.str":
					StashDestDF_Interp = sval;
					break;
				case "any other type":
					StashDestDF_STany=sval;
			endswitch
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


Function nSTR_z_FilterPopProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			//nSTR_Q_FilterFileList();	// omnibus filter function; solves all?  no, stupid idea, fix it in the file sorter
			// HOWEVER, we need to help users keep their data separated here...
			SVAR DestinationDataFolder 	= root:STRPanel_Folder:DestinationDataFolder
			SVAR StashDestDF_STR_STC 	= root:STRPanel_Folder:StashDestDF_STR_STC
			SVAR StashDestDF_PB			= root:STRPanel_Folder:StashDestDF_PB
			SVAR StashDestDF_CAL			= root:STRPanel_Folder:StashDestDF_CAL
			SVAR StashDestDF_Interp		= root:STRPanel_Folder:StashDestDF_Interp
			SVAR StashDestDF_STany		= root:STRPanel_Folder:StashDestDF_STany
			SVAR StashDestDF_Future		= root:STRPanel_Folder:StashDestDF_Future

			strswitch (popStr)
				case "sample str/stc":
					DestinationDataFolder = 		StashDestDF_STR_STC;
					break;
				case "playback str":
					DestinationDataFolder = 		StashDestDF_PB;
					break;
				case "calibration _CAL.str":
					DestinationDataFolder = 		StashDestDF_CAL;
					break;
				case "EddyOut _Interp.str":
					DestinationDataFolder = 		StashDestDF_Interp;
					break;
				case "any other type":
					DestinationDataFolder = 		StashDestDF_STany;
					break
			endswitch
			nSTR_g_PathOrRefresh(); // refresh immediately 

			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function nSTR_Q_FilterFileList()

	// purpose of function is to establish what the popup filter reads
	// filter the list accordingly.

End

Function nSTR_b_Draw() 
	
	DoWindow STR_Panel
	if( V_Flag )
		DoWindow/K STR_Panel
	endif
	
	
	/////////////////////////////////////////////////////////////////////
	// [ message text box                                                                                                     ]
	// <Data Path> [path found on the disk ~ can be directly type                                      ]
	//{ list box with dynamic sizine}	DataFolder root:[ usr types here ]
	//{                                               } 	{ list box here with this, 2 }
	//{                                               }     {                                            }        count
	//{                                               }     {                                            }        sort
	//{                                               }     {                                            }        numNans
	//{                                               }     {                                            }
	//{                                               }     {                                            }
	//{                                               }     {                                            }
	//{                                               }                                                 
	//{                                               }                                                 
	//{                                               }     <All Button			<Load Button>                                            
	//////////////////////////////////////////////////////////////////////
	Variable wid_panel = 550, height = 450, ctrlHeight = 21
	Variable col1 = 5, wid_msg = wid_panel - 2* col1
	Variable wid_dbbut = 75, wid_path = wid_panel - wid_dbbut - 2 * col1
	Variable wid_filebox = 300, wid_specbox = 125
	Variable row_msg = 5, row_dbp = 25, row_filebox = 45, nrow_line = height - ctrlHeight - 5, nrow_pline = height - (2* ctrlHeight + 9)
	Variable col2 = col1 + wid_filebox + 10, wid_df = 185
	Variable row_filter = 45;
	
	SVAR msg = root:STRPanel_Folder:msg;	msg = "Drawing panel..."
	NewPanel /K=1 /W=(217,166,767,616) as "STR_Panel"
	DoWindow/C STR_Panel
	SetVariable nSTR_2014_msg_SV,pos={5.00,5.00},size={540.00,14.00},title="msg:"
	SetVariable nSTR_2014_msg_SV,help={"This is the message display window.  There is nothing for the user to enter here"}
	SetVariable nSTR_2014_msg_SV,valueColor=(26214,0,0)
	SetVariable nSTR_2014_msg_SV,valueBackColor=(61166,61166,61166)
	SetVariable nSTR_2014_msg_SV,limits={0,0,0},value= root:STRPanel_Folder:msg,noedit= 2
	Button nSTR2014_SelectPathButton,pos={5.00,25.00},size={75.00,21.00},proc=nSTR_z_ButtonProc,title="Disk Path"
	Button nSTR2014_SelectPathButton,help={"Use this button to browse to folder where str/stc files are located"}
	Button nSTR2014_SelectPathButton,fSize=12,fStyle=1,fColor=(48059,48059,48059)
	Button nSTR2014_RefreshFilesButton,pos={5.00,50.00},size={75.00,21.00},proc=nSTR_z_ButtonProc,title="Refresh"
	Button nSTR2014_RefreshFilesButton,help={"Use this button to refresh folder contents"}
	Button nSTR2014_RefreshFilesButton,fSize=12,fColor=(48059,48059,48059)
	Button nSTR2014_RefreshFilesButton,valueColor=(2,39321,1)
	PopupMenu nSTR2014_FileFilter,pos={96.00,51.00},size={165.00,23.00},proc=nSTR_z_FilterPopProc,title="File Filter"
	PopupMenu nSTR2014_FileFilter,fSize=12
	PopupMenu nSTR2014_FileFilter help={"change the file filter to view playback files, cal files or other non-standard formats"}
	PopupMenu nSTR2014_FileFilter,mode=1,popvalue="sample str/stc",value= #"\"sample str/stc;playback str;calibration _CAL.str;EddyOut _Interp.str;any other type\""
	SetVariable nSTR_2014_dbp_SV,pos={84.00,28.00},size={461.00,18.00},title=">"
	SetVariable nSTR_2014_dbp_SV,help={"This is the folder where .str and .stc files are stored"}
	SetVariable nSTR_2014_dbp_SV,fSize=12,fColor=(48059,48059,48059)
	SetVariable nSTR_2014_dbp_SV,valueBackColor=(65535,65535,65535)
	SetVariable nSTR_2014_dbp_SV,limits={0,0,0},value= root:STRPanel_Folder:DataPathOnDisk,styledText= 1
	ListBox nSTR_2014_FilesBox,pos={5.00,90.00},size={300.00,350.00},proc=nSTR_z_ListBoxProc
	ListBox nSTR_2014_FilesBox,help={"This is the listing of combined STR/STC files found in the directory, select to load"}
	ListBox nSTR_2014_FilesBox,fSize=11,frame=4
	ListBox nSTR_2014_FilesBox,listWave=root:STRPanel_Folder:FileTimeDisplay_rcMat
	ListBox nSTR_2014_FilesBox,selWave=root:STRPanel_Folder:FileTimeDisplay_SelWave
	ListBox nSTR_2014_FilesBox,colorWave=root:STRPanel_Folder:FileTimeDisplay_ColorWave
	ListBox nSTR_2014_FilesBox,titleWave=root:STRPanel_Folder:FileTimeDisplay_Columntw
	ListBox nSTR_2014_FilesBox,mode= 4,widths={125,55,55},userColumnResize= 1
	Button nSTR2014_SelectAllFiles,pos={309.00,424.00},size={60.00,21.00},proc=nSTR_z_ButtonProc,title="all"
	Button nSTR2014_SelectAllFiles,help={"Use this button to select all"},fSize=10
	Button nSTR2014_DefaultPlotSTRSTC,pos={316.00,349.00},size={150.00,25.00},proc=nSTR_z_ButtonProc,title="default graph"
	Button nSTR2014_DefaultPlotSTRSTC,help={"Use this button to plot all STR and STC data"}
	Button nSTR2014_DefaultPlotSTRSTC,fSize=12,fColor=(65535,65535,65535)
	Button nSTR2014_SelectAllButLastFiles,pos={309.00,399.00},size={60.00,21.00},proc=nSTR_z_ButtonProc,title="all but last"
	Button nSTR2014_SelectAllButLastFiles,help={"Use this button to select all but the last one"}
	Button nSTR2014_SelectAllButLastFiles,fSize=10
	Button nSTR2014_LoadSelectedFiles,pos={373.00,399.00},size={75.00,46.00},proc=nSTR_z_ButtonProc,title="Load\rSelected"
	Button nSTR2014_LoadSelectedFiles,help={"Use this button to load and process selected files"}
	Button nSTR2014_LoadSelectedFiles,fSize=12,fStyle=1,fColor=(49151,65535,49151)
	SetVariable nSTR_2014_DataFolder_SV,pos={314.00,108.00},size={185.00,18.00},proc=nSTR_Z_DFStash,title="root:"
	SetVariable nSTR_2014_DataFolder_SV,help={"Enter data sub folder for waves to load to here"}
	SetVariable nSTR_2014_DataFolder_SV,fSize=12
	SetVariable nSTR_2014_DataFolder_SV,limits={0,0,0},value= root:STRPanel_Folder:DestinationDataFolder,styledText= 1
	Button nSTR2014_RedimWavesToZero,pos={314.00,132.00},size={150.00,25.00},proc=nSTR_z_ButtonProc,title="Reset DataWaves"
	Button nSTR2014_RedimWavesToZero,help={"Use this button to Redimension/N=0 waves "}
	Button nSTR2014_RedimWavesToZero,fSize=12,fStyle=1
	Button nSTR2014_ManualSortSTR,pos={314.00,184.00},size={150.00,25.00},proc=nSTR_z_ButtonProc,title="Manual Sort str_"
	Button nSTR2014_ManualSortSTR,fSize=12,fColor=(49151,53155,65535)
	Button nSTR2014_ManualSortSTC,pos={314.00,209.00},size={150.00,25.00},proc=nSTR_z_ButtonProc,title="Manual Sort stc_"
	Button nSTR2014_ManualSortSTC help={"Use this button to sort stc waves and eliminate any nans"}
	Button nSTR2014_ManualSortSTR help={"Use this button to sort str waves and eliminate any nans"}
	Button nSTR2014_ManualSortSTC,fSize=12,fColor=(49151,53155,65535)
	Button nSTR2014_UpdateWintelGraphsIPF,pos={455.00,399.00},size={75.00,46.00},proc=nSTR_z_ButtonProc,title="Wintel\rGraphs"
	Button nSTR2014_UpdateWintelGraphsIPF,help={"Use this button to process data and plot graphs, using code in WintelGraphs.ipf "}
	Button nSTR2014_UpdateWintelGraphsIPF,fSize=12,fStyle=1
	Button nSTR2014_UpdateWintelGraphsIPF,fColor=(65535,60076,49151)
	TitleBox nSTR_2014_LabelDF,pos={338.00,92.00},size={140.00,15.00},title="Destination Data Folder  "
	TitleBox nSTR_2014_LabelDF,help={"Leave this blank for root: data folder in igor"}
	TitleBox nSTR_2014_LabelDF,fSize=12,frame=0,fStyle=0
	Button nSTR2014_ResetLoadHistory,pos={314.00,157.00},size={150.00,25.00},proc=nSTR_z_ButtonProc,title="Reset History"
	Button nSTR2014_ResetLoadHistory,help={"Reset history of loaded files"},fSize=12
	Button nSTR2014_ResetLoadHistory,fStyle=0
	Button nSTR2014_deleteWintelWin,pos={316.00,289.00},size={150.00,25.00},proc=nSTR_z_ButtonProc,title="delete top graph"
	Button nSTR2014_deleteWintelWin,help={"Graph macro will be deleted from WintelGraphs.ipf located in the str/stc data directory"}
	Button nSTR2014_deleteWintelWin,fSize=12,fColor=(65535,65535,65535)
	Button nSTR2014_newWintelWin,pos={316.00,262.00},size={150.00,25.00},proc=nSTR_z_ButtonProc,title="save top graph"
	Button nSTR2014_newWintelWin,help={"Graph macro will be saved to WintelGraphs.ipf, located in the str/stc data directory"}
	Button nSTR2014_newWintelWin,fSize=12,fColor=(65535,65535,65535)
	TitleBox nSTR_2014_LabelGraphs,pos={315.00,247.00},size={110.00,15.00},title="Wintel Graph Setup"
	TitleBox nSTR_2014_LabelGraphs,help={"Graphs that you save as WintelWin will be available the next time you open Igor. See WintelGraphs.ipf for more details"}
	TitleBox nSTR_2014_LabelGraphs,fSize=12,frame=0,fStyle=0
	Button nSTR2014_popWintelWin,pos={316.00,323.00},size={150.00,25.00},proc=nSTR_z_ButtonProc,title="edit prep waves"
	Button nSTR2014_popWintelWin,help={"Go to the procedure function where wave math can be done (e.g. calculate isotope ratios)"}
	Button nSTR2014_popWintelWin,fSize=12,fColor=(65535,65535,65535)
	
	return 0
End
Constant k_UseDotFeedBack = 1

Function nSTR_c_LoadSelectedFiles()

	Wave/T FileTimeDisplay_rcMat 		= root:STRPanel_Folder:FileTimeDisplay_rcMat
	Wave FileTimeDisplay_SelWave 	= root:STRPanel_Folder:FileTimeDisplay_SelWave
	Wave FileTimeDisplay_ColorWave 	= root:STRPanel_Folder:FileTimeDisplay_ColorWave
	Wave/T LoadHistory = root:STRPanel_Folder:LoadHistory
	SVAR DataPathOnDisk = root:STRPanel_Folder:DataPathOnDisk
	Variable count = numpnts( FileTimeDisplay_SelWave )
	Variable idex
	String fabFileName, candiFile
	// STC load code hijack variables and strings ...
	String saveFolder, str_panel_prefix, useBase_str, ufile_str, parameterList, JustLoadedList, LoadType, TailToekn, uTailValue, FormatStr, mappedList
	String DF_for_STC_PostLoadConcat 
	Variable loadedAlreadyCheck
	SVAR LoadedWaveNamesSTR = root:STRPanel_Folder:LoadedWaveNamesSTR
	SVAR LoadedWaveNamesSTC = root:STRPanel_Folder:LoadedWaveNamesSTC
	
	SVAR msg = root:STRPanel_Folder:msg;			
	
	if( k_UseDotFeedBack )
		printf "Loading Files "
	endif
	for( idex = 0; idex < count; idex += 1 )
		
		loadedAlreadyCheck = cmpstr( FileTimeDisplay_rcMat[idex][2], "<loaded>" ) == 0
		
		candiFile = FileTimeDisplay_rcMat[idex][0];
		if(cmpstr(candifile, "_notSet")==0)
			sprintf msg, "Please choose a valid disk path", idex, count - 1
			return -1
		endif
		if( !loadedAlreadyCheck )
			if( FileTimeDisplay_SelWave[idex] == 1 )
			
				if( (cmpstr( FileTimeDisplay_rcMat[idex][1], "both" ) == 0) | (cmpstr( FileTimeDisplay_rcMat[idex][1], "STR" ) == 0) | (cmpstr( FileTimeDisplay_rcMat[idex][1], "STC" ) == 0))
			
					if((cmpstr( FileTimeDisplay_rcMat[idex][1], "both" ) == 0) | (cmpstr( FileTimeDisplay_rcMat[idex][1], "STR" ) == 0) )
						
						sprintf fabFileName, "%s:%s.str", DataPathOnDisk, candiFile[2, strlen( candiFile ) -1]
						fabFileName = RemoveDoubleColon( fabFileName ); // just in case
						sprintf msg, "%03d/%d", idex, count - 1
							
						if ( k_UseDotFeedBack )
							printf ".r."	
						endif
						nSTR_LoadSTRFile( fabFileName );		// note that this nSTR function will reach "into: the right datafolder specified
						AppendString( LoadHistory, candiFile+"-"+fileTimeDisplay_rcMat[idex][1]);	// I think this is the right approach?
					endif
						
					if( (cmpstr( FileTimeDisplay_rcMat[idex][1], "both" ) == 0) | (cmpstr( FileTimeDisplay_rcMat[idex][1], "STC" ) == 0))
						sprintf fabFileName, "%s:%s.stc", DataPathOnDisk, candiFile[2, strlen( candiFile ) -1]
						fabFileName = RemoveDoubleColon( fabFileName ); // just in case
			
						sprintf msg, "%03d/%d", idex, count - 1
						if ( k_UseDotFeedBack )
							printf ".c."	
						endif
						
						
			
						// this is franken code ~ at this time ~
						// we will replicate old STC loading
			
				
						str_panel_prefix = "stc"
						useBase_str = str_panel_prefix
			
						saveFolder = GetDataFolder(1);
						SetDataFolder root:; MakeAndOrSetDF( "Tail_STC_Load" )
						KillWavesWhichMatchStr("*")
						ufile_Str = zSPE2_JustFileFromFull( fabFileName )
						parameterList = zSTC_GetHeaderLine( fabFileName)
						if( strsearch( parameterList, "FILE", 0 ) == -1 )
							FormatStr = zSTC_MakeFormatStrFromList( parameterList )		
							justLoadedList = TDLCore_TailLoad( "stc-fast", "default", -1, FormatStr, fabFileName )
							// in this next duplicate/concatenation step the second arbument needs to be set to DestinationDataFolder or root: for default
							SVAR DestinationDataFolder = root:STRPanel_Folder:DestinationDataFolder
							if( strlen( DestinationDataFolder ) > 0 )
								sprintf DF_for_STC_PostLoadConcat, "root:%s", DestinationDataFolder
							else
								DF_for_STC_PostLoadConcat = "root:"
							endif
							mappedList = TDLCore_MapLocalListToFinal( usebase_str, DF_for_STC_PostLoadConcat, justLoadedList )
							//TDLCore_DrawSTCGraph( mappedList, dest_DF_str, usebase_str )
							SetDataFolder $saveFolder
						else
			
						
							AppendString( LoadHistory, candiFile+"-"+fileTimeDisplay_rcMat[idex][1]  );	// I think this is the right approach?
	
						endif
					endif
	
				elseif( (cmpstr( FileTimeDisplay_rcMat[idex][1], "PB" ) == 0) )
			
					sprintf fabFileName, "%s:%s_PB.str", DataPathOnDisk, candiFile[2, strlen( candiFile ) -1]
					fabFileName = RemoveDoubleColon( fabFileName ); // just in case
					sprintf msg, "%03d/%d", idex, count - 1
					
					if ( k_UseDotFeedBack )
						printf ".r."	
					endif
					LoadedWaveNamesSTC=""; LoadedWaveNamesSTR=""
					nSTR_LoadSTRFile( fabFileName );		// note that this nSTR function will reach "into: the right datafolder specified
					AppendString( LoadHistory, candiFile+"-"+fileTimeDisplay_rcMat[idex][1]  );	// I think this is the right approach?
	
				elseif( (cmpstr( FileTimeDisplay_rcMat[idex][1], "CAL" ) == 0) )
			
					sprintf fabFileName, "%s:%s_CAL.str", DataPathOnDisk, candiFile[2, 7]
					fabFileName = RemoveDoubleColon( fabFileName ); // just in case
					sprintf msg, "%03d/%d", idex, count - 1
					
					if ( k_UseDotFeedBack )
						printf ".r."	
					endif
					LoadedWaveNamesSTC=""; LoadedWaveNamesSTR=""
					nSTR_LoadSTRFile( fabFileName );		// note that this nSTR function will reach "into: the right datafolder specified
					AppendString( LoadHistory, candiFile+"-"+fileTimeDisplay_rcMat[idex][1]  );	// I think this is the right approach?
	
				elseif( (cmpstr( FileTimeDisplay_rcMat[idex][1], "Interp" ) == 0) )
			
					sprintf fabFileName, "%s:%s_Interp.str", DataPathOnDisk, candiFile[2, 12]
					fabFileName = RemoveDoubleColon( fabFileName ); // just in case
					sprintf msg, "%03d/%d", idex, count - 1
					
					if ( k_UseDotFeedBack )
						printf ".r."	
					endif
					LoadedWaveNamesSTC=""; LoadedWaveNamesSTR=""
					nSTR_LoadSTRFile( fabFileName );		// note that this nSTR function will reach "into: the right datafolder specified
					AppendString( LoadHistory, candiFile+"-"+fileTimeDisplay_rcMat[idex][1]  );	// I think this is the right approach?
	
				elseif( (cmpstr( FileTimeDisplay_rcMat[idex][1], "both" ) == 0) | (cmpstr( FileTimeDisplay_rcMat[idex][1], "STC" ) == 0) )
			
				
					// this is for all other types
				else
			
					sprintf fabFileName, "%s:%s.%s", DataPathOnDisk, candiFile[2, strlen( candiFile ) -1], fileTimeDisplay_rcMat[idex][1]
					fabFileName = RemoveDoubleColon( fabFileName ); // just in case
					sprintf msg, "%03d/%d", idex, count - 1
					
					if ( k_UseDotFeedBack )
						printf ".r."	
					endif
					LoadedWaveNamesSTC=""; LoadedWaveNamesSTR=""
					nSTR_LoadSTRFile( fabFileName );		// note that this nSTR function will reach "into: the right datafolder specified
					AppendString( LoadHistory, candiFile+"-"+fileTimeDisplay_rcMat[idex][1] );	// I think this is the right approach?
	
				endif
				
			endif
		endif
	endfor
	if( k_UseDotFeedBack )
		printf "done \r"
	endif
	nSTR_g_PathOrRefresh() // this to reset the loaded tag
	FileTimeDisplay_SelWave = 0 // to further the feedback that the procedure is complete.
	
End

Function/T nSTR_e_BuildFormatStr( fpfile )
	String fpfile
	
	SVAR msg = root:STRPanel_Folder:msg;	sprintf msg "checking %s", fpfile		
	
	Variable refNum, SPEC_offset, idex, count, jcount, jdex
	String justSpecList, this_format, this_spec, retFormatStr = "", line_one, line_two
	
	Open/Z/R refNum as fpfile
	if( V_Flag == 0 )
		FReadLine refNum, line_one
		FReadLine refNum, line_two
		Close refNum
	else
		sprintf msg, "Unable to open %s", fpfile
		return "_error"					// error exit
	endif
	SPEC_offset = strsearch( line_one, "SPEC:", 0 )
	if( SPEC_offset == -1 )
		sprintf msg, "No SPEC: on line %s of file %s", line_one, fpfile
		line_one = replaceString(" \r", line_one, "")
		Variable columns = itemsInList(line_one, " ")
		if(columns > 0)
			retFormatStr = retFormatStr + "C=1,T=4,N=new_str_source_rtime;"
		endif
		// we default to old names until Dave changes the cal file format. 
		for(idex = 1; idex < columns; idex +=1)
			this_spec = "tdl"+num2str(idex)+"_conc"
			sprintf this_format, "C=1,T=4,N=new_%s;" this_spec;
			retFormatStr = retFormatStr + this_format
		endfor
	 	
		return retFormatStr	// old style naming exit
	endif
	
	justSpecList  = line_one[ SPEC_offset + strlen( "SPEC:") , strlen( line_one ) - 2 ]	// the minus 2 here drops the carraige return
//	justSpecList = nSTR_f_UniqueSPECNamer( justSpecList );
	justSpecList = nSTR_f2021_CheckForPosMetaCode( justSpecList );
	justSpecList = nSTR_ff_PrependCharacterIfIso( justSpecList );
	justSpecList = nSTR_fff_COScleaner (justspecList); // this should deal with OCS written as COS and bugging with cosine. Also does any other name bugs. 
	


	justSpecList = nSTR_f_UniqueSPECNamer( justSpecList );
	count = itemsInList( justSpecList, "," );
	if( count > 0 )
		retFormatStr = retFormatStr + "C=1,T=4,N=new_str_source_rtime;"
		
		for( idex = 0; idex < count; idex += 1 )
			this_spec = StringFromList( idex, justSpecList, "," );
			sprintf this_format, "C=1,T=4,N=new_%s;" this_spec;
			retFormatStr = retFormatStr + this_format
		endfor
	endif
	return retFormatStr
	
End

Function/T nSTR_f2021_CheckForPosMetaCode( spec_list )
	String spec_list

	String retList = "";
	
	Wave/Z/T SpeciesMetaPosnData = root:STRPanel_Folder:SpeciesMetaPosnData
	if( !WaveExists( SpeciesMetaPosnData ) )
		Make/O/T/N=0 root:STRPanel_Folder:SpeciesMetaPosnData
		Wave/Z/T SpeciesMetaPosnData = root:STRPanel_Folder:SpeciesMetaPosnData
	endif
	
	
	String this_, candidate_, characterCode, escape, buildRecordedEntry = "";
	Variable idex, count = ItemsInList( spec_list, "," );
	Variable checkForEscape
	
	for( idex = 0; idex < count; idex += 1 )
		
		this_ = StringFromList( idex, spec_list, "," );
	
		checkForEscape = 1;	
		
		do
			if( strlen( this_ ) >= 2 )
				escape = this_[0,1]
			else	
				escape = "no"
			endif
		
			if( cmpstr( lowerstr( escape), "x_" ) == 0 )
				// we have found an escapee
				characterCode = this_[2];
				candidate_ = this_[ 3, strlen( this_ ) - 1 ];
				// F indicates the Beginning of a new fit (BFIT), index starts at 0
				if( cmpstr( lowerstr( characterCode ), "f" )  == 0 )
					sprintf buildRecordedEntry, "%sBFIT:%d;", buildRecordedEntry, idex;
				endif
				// L indicates the Beginning of Laser 2 data (BLAS). 
				if( cmpstr( lowerstr( characterCode ), "l" ) == 0 )
					sprintf buildRecordedEntry, "%sBLAS:%d;", buildRecordedEntry, idex;
				endif
				// A indicates Ambient Pressure. 
				if( cmpstr( lowerstr( characterCode ), "a" ) == 0 )
					sprintf buildRecordedEntry, "%sAMB:%d;", buildRecordedEntry, idex;
					candidate_ = candidate_ + "_ambientPressure"
				endif
				// R indicates Field 4 frequency lock mixing ratio, as specified in con file. 
				if( cmpstr (lowerstr(characterCode ), "r" ) == 0 )
					sprintf buildRecordedEntry, "%sF4:%d;", buildRecordedEntry, idex;
					candidate_ = candidate_ + "_Field4"
				endif
			
				// there is a chance of a double escape e.g. x_Ax_FCO2
				// on the first run through we have pulled escape and built candidate
				// here, for the next do ..., we will set
				this_ = candidate_ ; // and retest
				checkForEscape = 1;  // e.g. check again
			else
				candidate_ = this_
				checkForEscape = 0;
			endif
		while( checkForEscape )
		
		retList = retList + candidate_ + ","
		
	endfor
		
	buildRecordedEntry = buildREcordedEntry + "SPEC:" + retList;
	
	// this gets added per file that loads. 
	AppendString( SpeciesMetaPosnData, buildRecordedEntry );
	
	return retList;
	
End

Function/T nSTR_ff_PrependCharacterIfIso( spec_list )
	String spec_list
	
	String return_list = "";
	
	String this_, candidate_, first_character
	Variable idex, count = ItemsInList( spec_list, "," ), ascii_val, ascii_zero = char2num( "0" ), ascii_nine = char2num( "9" );
	
	for( idex = 0; idex < count; idex += 1 )
		
		this_ = StringFromList( idex, spec_list, "," );
		first_character = this_[0];
		ascii_val = char2num( first_character)
		if( (ascii_val >= ascii_zero ) & (ascii_val <= ascii_nine) )
			return_list = return_list + "i" + this_ + ","	
		else
			return_list = return_list + this_ + ","
		endif
		
	endfor
	return return_list
	
End

// this function uses the checkName command to make sure OCS is not entered as COS (and therefore interferres with cosine)
Function/T nSTR_fff_COScleaner( spec_list)

	String spec_list
	
	String return_list = "";
	
	String this_, candidate_, first_character
	Variable idex, count = ItemsInList( spec_list, "," ), ascii_val, ascii_zero = char2num( "0" ), ascii_nine = char2num( "9" );
	
	for( idex = 0; idex < count; idex += 1 )
		
		this_ = StringFromList( idex, spec_list, "," );
		
		if( checkName(this_, 1) == 0 ) // this is ideal case. no conflict		
		elseif( checkName(this_, 1) == 27) // this is okay, wave already exists but no other error. Loader will deal. 
		else // this is any other case. eg. a wave called "cos" or "display"
			this_ = cleanupName(this_, 0)
			if(checkName(this_,1) !=0 && checkname(this_,1) !=27) // still bad
				this_ = "x"+this_
				if(checkName(this_,1) && checkname(this_,1) !=27) // still bad, this will never happen. 
					this_ = "x"+this_
				endif
			endif
		endif
		return_list = return_list + this_ + ","

		
	endfor
	return return_list

End

Function/T nSTR_f_UniqueSPECNamer( spec_list )
	String spec_list
	
	String unique_list = StringFromList( 0, spec_list, "," ) + ",";
	String this_, candidate_
	
	Variable idex=1, count = ItemsInLIst( spec_list, "," ), whichval;
	for( idex = 1; idex < count; idex += 1 )
		
		this_ = StringFromLIst( idex, spec_list, "," );
		// Hotfix of the "?" bug 3/2017
		if( cmpstr( this_, "?" ) == 0 )
			this_ = "QuestionMark"
		endif		
	
		if( WhichListItem( this_, unique_list, "," ) != -1 )

			// we have a duplicate to contend with	
			sprintf candidate_, "%s_A", this_
			if( WhichListItem( candidate_, unique_list, "," ) != -1 )
				// we have a triplicate to contend with	
				sprintf candidate_, "%s_B", this_
				if( WhichListItem( candidate_, unique_list, "," ) != -1 )
					// we have a quadruplicate to contend with	
					sprintf candidate_, "%s_C", this_
					if( WhichListItem( candidate_, unique_list, "," ) != -1 )
						// we have a <I give up> to contend with	
						sprintf candidate_, "%s_D", this_
						if( WhichListItem( candidate_, unique_list, "," ) != -1 )
							// we have a triplicate to contend with	
							sprintf candidate_, "%s_E", this_
							if( WhichListItem( candidate_, unique_list, "," ) != -1 )
								// we have a triplicate to contend with	
								sprintf candidate_, "%s_F", this_
								if( WhichListItem( candidate_, unique_list, "," ) != -1 )
									// we have a triplicate to contend with	
									sprintf candidate_, "%s_G", this_
								endif
							endif
						endif
					endif
				endif
			endif
			unique_list = unique_list + candidate_ + ","			
		else
			unique_list = unique_list + this_ + ","
		endif
		
		
	endfor
	
	return unique_list
	
End
Function nSTR_LoadSTRFile( fpfile )
	String fpfile
		
	Variable modfolder = 0, idex, count, start_line = 1;
	String saveFolder, formatStr, loaded_waves, this_w, OldWaveName
	
	Wave /T thisFile_spec = root:STRPanel_Folder:thisFile_Spec
	SVAR DestinationDataFolder = root:STRPanel_Folder:DestinationDataFolder
	SVAR LoadedWaveNamesSTR = root:STRPanel_Folder:LoadedWaveNamesSTR
	
	if( strlen( DestinationDataFolder ) > 0 )
		modfolder = 1; saveFolder = GetDataFolder(1); SetDataFolder root:; MakeAndOrSetDF( DestinationDataFolder );
	else
		modFolder = 1;
		saveFolder = GetDataFolder(1); SetDataFolder root:;
	endif
	
	// this format string has the waves named as new_ ... etc. 
	formatStr = nSTR_e_BuildFormatStr( fpfile );
		
	if(stringmatch(formatStr,"_error"))
		return -1
	endif
	LoadWave/A/G/B=formatStr/L={0, start_line,0,0,0}/O/Q fpfile
	
	loaded_waves = S_waveNames;

	// this is really annoying; we have found some files produce a double load of wavenames.
	// call function to strip duplicates
	loaded_waves = RemoveDuplicateListItems( loaded_waves )

	// save wave names in a string for future use in graph making, etc.
	loadedWaveNamesSTR=replaceString("new_",loaded_waves,"")
		
	thisFile_spec = "";
	count = ItemsInList( loaded_waves );
	for( idex = 0; idex < count ; idex += 1 )
		this_w = StringFromList( idex, loaded_waves )
		// check that potential wavename starts with a letter
		this_w = cleanupName(this_w,0)
		Wave/Z w = $this_w
		if( WaveExists( w ) != 1 )
			printf "bogus w ref %s in file %s \r", this_w, fpfile
		endif
		OldWaveName = CleanUpName(this_w[ strlen( "new_" ), strlen( this_w ) -1 ],0)
		thisFile_spec[idex] = OldWaveName;
		// use Time to check length
		if(stringmatch(oldWaveName,"str_source_rtime"))
			wave/z finalTime = $oldWaveName 
			Variable OldCount = 0
			Variable newCount = 0
			if(waveexists(finalTime))
				oldCount = numpnts(finalTime)
				newCount = oldCount + numpnts(w)
			else
				newCount = numpnts(w)
			endif
		endif
		
		//
		if(!stringmatch(oldWaveName,"str_source_rtime"))
			wave/z finalW = $oldWaveName 
			Variable ThisOldCount = 0
			Variable ThisNewCount = 0
			if(waveexists(finalW))
				ThisoldCount = numpnts(finalW)
				ThisnewCount = ThisoldCount + numpnts(w)
			else
				ThisnewCount = numpnts(w)
			endif
			
			// this is where we redimension or create waves that are new. 
			if(thisOldCount == 0 || !waveexists(finalW))
				make/n=(oldCount)/O $oldWaveName
				wave/z finalW = $oldWaveName
				finalW = nan
			elseif(thisOldCount != oldCount)
				redimension/n=(oldCount) finalW
				finalW[thisOldCount,oldCount-1]=nan
			endif
			
		endif
		
		ConcatenateWaves( OldWaveName, this_w );
		KillWaves/Z w
		
	
	endfor
	
	Wave time_w = str_source_rtime
	SetScale/P y, 0,0,"dat", time_w
	
	if( modfolder )
		SetDataFolder $saveFolder
	endif

End	

Function/S nSTR_h_ProbeCommonPaths()
	
	String bestPathStr = ""

	String list = "";


	// OPTION 1. TDLWintel Directory
	list = list + "f:data" + "|"
	list = list + "c:TDLWintel:data" + "|"
	list = list + "d:TDLWintel:data" + "|"

	// OPTION 2. User preference
	// users can add lines here, if they wish. These will be chosen over the more general "Documents" folder.
	// separate with colons, even if you are working on Windows. 
	list = list + "cocytus:Users:scott:Documents:provo-field:2014_GatherProcess:N2O_Mini:TdlWintel:Data" + "|"
	
	// OPTION 2.5 Load SPB location
	SvAR/Z SPBpath = root:LoadSPE_UI:Path2Files
	if(svar_exists(SPBpath))
		// go one level up 
		Variable colonLoc = strsearch(SPBpath, ":", strlen(SPBpath)-2, 3) // searching backwards, ignore case, ignore ending colons.
		if(colonLoc != -1)
			list = list + 	SPBpath[0,colonLoc-1]	+ "|"
		endif
	endif
	// OPTION 3. Documents folder
	// get known good path
	// Note this returns a final colon, so remove it to be consistent.
	String docPath = SpecialDirPath("Documents", 0, 0, 0)
	list = list + docPath[0,strlen(docPath)-2] + "|"

	// Option 4. Program Files. This will never be accessed, basically.
	// Not a great path to default to over user documents...
	list = list + "c:ProgramFiles:tdlwintel:data" + "|"

	// choose best path and place it in DataPathOnDisk
	String thisPath
	SVAR/Z path_svar = root:STRPanel_Folder:DataPathOnDisk
			
	Variable idex, count = ItemsInLIst( list, "|" )
	for( idex = 0; idex < count; idex += 1 )
		thisPath = StringFromList( idex, list, "|" );
		NewPath/O/Q/Z nSTR_Path thisPath
		if( V_Flag == 0  )
			// the path is hot, lets set it
			bestPathStr = thisPath
			
			// STRPanel_Folder might not exist if we are doing LoadSpe2, for example. that's ok. function will return a string. 
			if(svar_exists(path_svar))
				path_svar = thisPath			
			endif

			break
		endif
		//		KillPath/Z nSTR_Path // do not kill path, keep in memory
	endfor
	//	KillPath/Z nSTR_Path // do not kill path, keep in memory

	
	Return bestPathStr
End

StrConstant k_WintelGraphIPFFileName = "WintelGraphs.ipf"
StrConstant k_WintelGraphPrefix = "WintelWin_"
StrConstant k_WintelPrepWavesFunction = "WintelGraphs_PrepWaves"

Function nSTR_d_OpenCAECWintelGraphProc()
	SVAR msg = root:STRPanel_Folder:msg;	sprintf msg "nSTR_d_OpenCAECWintelGraphProc..."		
	
	String usePath
	
	if( k_AutoSearch_WintelGraphs != 1 )
		return -1								// this is a kill switch in case this isn't working and it becomes annoying.
	endif
	
	String cmd
	
	Variable idex, count;	String this_file, this_datetime
	Wave/T f_str = root:STRPanel_Folder:found_str
	Wave/T f_stc = root:STRPanel_Folder:found_stc
	Wave/T f_pb = root:STRPanel_Folder:found_pb
	Wave/T f_cal = root:STRPanel_Folder:found_cal
	Wave/T f_interp = root:STRPanel_Folder:found_interp
	Wave/T f_stany = root:STRPanel_Folder:found_stany
	
	SVAR path_svar = root:STRPanel_Folder:DataPathOnDisk
	count = ItemsInList( path_svar, ":" )
	// this was the old way to sneak .ipf into TDLWintel: but new way will be to 
	//usePath = RemoveListItem( count - 1, path_svar, ":" )
	// keep it in TDLWintel:Data with a better name
	//print usePath
	usePath = path_svar
	NewPath/O/Q/Z nSTR_WinGraphs usePath
	PathInfo 	nSTR_WinGraphs; Variable pathExists = V_flag
	GetFileFolderInfo /Z=1/Q/P=nSTR_winGraphs k_WintelGraphIPFfileName; 
	Variable ipfExists 
	if(V_flag==0)
		ipfExists=1
	endif
	GetWindow/z $k_WintelGraphIPFFileName, file
	Variable procLoaded =0
	if(!stringmatch(S_value, ""))
		procLoaded = 1	// this is not reliable because state may be different by the tiem the execute happens
	endif

	if(1)
		if( ipfExists && pathExists)
		
			sprintf cmd ,"OpenProc/A /P=nSTR_WinGraphs /V=0 /Z \"%s\"", k_WintelGraphIPFFileName
			Execute/P/Q cmd
			Execute/P/Q "SetIgorOption independentModuleDev=0"
			Execute/P/Q "Silent 101" // this forces a recompile of procedures.
		
		else
		
			// see if we create it
			variable newWintelGraphs=0
			String noteStr 
		
			notestr = "WintelGraphs.ipf stores custom analysis and graphs.\rIt is best to use the file\rC:\TDLWintel\Data\WintelGraphs.ipf\r\rCreate new WintelGraphs.ipf anyways?"
			DoAlert /T="Create new WintelGraphs.ipf?" 1, noteStr
			if(V_Flag==1)
				newWintelGraphs=1
			else
				newWintelGraphs=0
			endif
			
			if(newWintelGraphs)
				// make it new
				nSTR_d_CreateCAECWintelProc()
			endif
		endif
	endif // do nothing if already loaded
	NVAR openFlag = root:STRPanel_Folder:WintelGraphsIPFNeedsOpen
	openFlag = 0;
	//KillPath/Z nSTR_WinGraphs
End

Function nSTR_d_CreateCAECWintelProc()
	SVAR msg = root:STRPanel_Folder:msg;	sprintf msg "nSTR_d_OpenCAECWintelGraphProc..."		
	
	String usePath
	
	if( k_AutoSearch_WintelGraphs != 1 )
		return -1								// this is a kill switch in case this isn't working and it becomes annoying.
	endif
	
	String cmd
	
	Variable idex, count;	String this_file, this_datetime
	
	SVAR path_svar = root:STRPanel_Folder:DataPathOnDisk
	count = ItemsInList( path_svar, ":" )
	
	usePath = path_svar
	NewPath/O/Q/Z nSTR_WinGraphs usePath
	PathInfo 	nSTR_WinGraphs; Variable pathExists = V_flag
	GetFileFolderInfo /Z=1/P=nSTR_winGraphs k_WintelGraphIPFfileName; 
	Variable ipfExists 
	if(V_flag==0)
		ipfExists=1
	endif
	
	if(ipfExists!=1)
		// write a default file and then load it
		nSTR_createWintelGraphs() // This creates a new WintelGraphs in the same folder. 
		sprintf cmd ,"OpenProc/A /P=nSTR_WinGraphs /V=0 /Z \"%s\"", k_WintelGraphIPFFileName
		Execute/P/Q cmd
		Execute/P/Q "SetIgorOption independentModuleDev=0"
		Execute/P/Q "Silent 101"
	endif
	NVAR openFlag = root:STRPanel_Folder:WintelGraphsIPFNeedsOpen
	openFlag = 0;
	//KillPath/Z nSTR_WinGraphs
End


Function nSTR_d_CloseCAECWintelGraphProc()

	NVAR modFlag = root:STRPanel_Folder:WintelGraphsIPFNeedsWrite
	NVAR openFlag = root:STRPanel_Folder:WintelGraphsIPFNeedsOpen
	

	String usePath
	SVAR path_svar = root:STRPanel_Folder:DataPathOnDisk
	String cmd =""
	usePath = path_svar
	NewPath/O/Q/Z nSTR_WinGraphs usePath
	PathInfo 	nSTR_WinGraphs; Variable pathExists = V_flag
	GetFileFolderInfo /Q/Z=1/P=nSTR_winGraphs k_WintelGraphIPFfileName; 
	Variable ipfExists 
	if(V_flag==0)
		ipfExists=1
	endif
	GetWindow/z $k_WintelGraphIPFFileName, file
	Variable procLoaded =0
	if(!stringmatch(S_value, ""))
		procLoaded = 1
	endif
	
	if(pathExists && ipfExists )
		sprintf cmd, "CloseProc/SAVE /COMP /NAME=\"%s\"", k_WintelGraphIPFFileName
		Execute/P/Q cmd
		//		Execute /Q "SetIgorOption independentModuleDev=0"
		//		Execute/P/Q "Silent 101" // recompile
		modFlag = 0; openFlag = 0;
	endif
	
End

Function nSTR_popPrepWaves()
	DisplayProcedure/W=WintelGraphs "wintelGraphs_PrepWaves"
End

// This function
// 1. does prepWaves
// 2. calls the individual graph macros. 

Function nSTR_d_GraphWandProc()
	SVAR msg = root:STRPanel_Folder:msg;		
	
	String list = MacroList( k_WintelGraphPrefix + "*", ";", "" ), thisWin, cmd

	SVAR DestinationDataFolder = root:STRPanel_Folder:DestinationDataFolder
	string setdfcmd = "SetDataFolder root:"+DestinationDataFolder
	if( strlen( DestinationDataFolder ) > 0 )
		setdfcmd = "SetDataFolder root:"
	endif
	
	String saveFolder = GetDataFolder(1);
	
	// Wave preparation function call. Do this first.
	thisWin = StringFromList( 0, list );
	if( cmpstr( thisWin, "Procedures Not Compiled" ) != 0 )
	
	
	
		// if this is a user-defined function
		if(exists(k_WintelPrepWavesFunction)==6)
		
	
			SetDataFolder root:;
			SetDataFolder $DestinationDataFolder;			
	
			if( nSTR_d_str_exists() )
				sprintf cmd, "%s; %s(); setdatafolder %s; // autocall prepWaves from nSTR_d_GraphWandProc()", setdfcmd, k_WintelPrepWavesFunction, saveFolder
				msg = cmd;
				execute/P/Q cmd;
			else
				msg = "Load STR or STC data first"
			endif
			SetDataFolder SaveFolder;
		endif
	endif
					
	Variable idex, count = ItemsInLIst( list )
	
	for( idex = 0; idex < count; idex += 1 )
		thisWin = StringFromList( idex, list );
		if( cmpstr( thisWin, "Procedures Not Compiled" ) != 0 )
		
			// Here is where the graph is brought to the front or created from
			// the saved macro in WintelGraphs.ipf
			DoWindow $thisWin
			if( V_Flag )
				DoWindow/F $thisWin
				SetWindow $thisWin hook(wintelWinHook)=nSTR_WintelWinHook
			else
				sprintf cmd, "%s; %s(); setdatafolder %s; // autocall graph from nSTR_d_GraphWandProc()", setdfcmd, thisWin, saveFolder
				Execute/P/Q cmd
				sprintf cmd, "SetAxis/A bottom"
				Execute/P/Q/Z cmd
			endif
		else
			// well let's compile them
			Execute /P/Q "Silent 101"
		endif
		
	endfor
	
	// pop up a notice if no graphs. 
	if(count == 0)
		// no graphs 

		Dowindow/F WintelWin_AllSTRSTC
		if(!V_Flag)
			string notestr = "No Custom Wintel Graphs Specified. \r\rYou can make a graph and click \"save top graph\" to save changes.\r\rPlot default graph instead?"
			DoAlert /T="Plot Default Graph?" 1, noteStr

			if(V_Flag==1)
				SVAR destDF = root:STRPanel_Folder:DestinationDataFolder
				setDatafolder root:; setdatafolder destDF
				WintelWin_DrawAllSTRSTC()
			endif
		endif
	endif
	
	
End
Function nSTR_d_str_exists()
	
	String savefolder = GetDataFolder(1); SetDataFolder root:
	String dirlist = StringByKey( "FOLDERS", DataFolderDir( 1 )), this_folder, wave_list;
	Variable idex, count = ItemsInList( dirlist , ",")
	
	wave_list = StringByKey( "WAVES", DataFolderDir( 2 ))
	if( strsearch( lowerstr(wave_list), "str_", 0 ) >= 0 )
		SetDataFolder $savefolder;
		return 1;
	endif 
	for( idex = 0; idex < count; idex += 1 )
		this_folder = StringFromList( idex, dirlist, ",")
		SetDataFolder $this_folder
		wave_list = StringByKey( "WAVES", DataFolderDir( 2 ))
		if( strsearch( lowerstr(wave_list), "str_", 0 ) >= 0 )
			SetDataFolder $savefolder;
			return 1;
		endif
		SetDataFolder root: 
		
	endfor
	SetDataFolder $savefolder
	return 0;
	
End

// This updates all macros
// save/close and reopens wintelGraphs.ipf
Function nSTR_d_GraphWandMod()
	
	String list = MacroList( k_WintelGraphPrefix+"*", ";", "" ), thisWin, cmd
	
	Variable idex, count = ItemsInLIst( list )
	NVAR modFlag = root:STRPanel_Folder:WintelGraphsIPFNeedsWrite
	NVAR openFlag = root:STRPanel_Folder:WintelGraphsIPFNeedsOpen
	
	for( idex = 0; idex < count; idex += 1 )
		thisWin = StringFromList( idex, list );
		if( cmpstr( thisWin, "Procedures Not Compiled" ) != 0 )
			DoWindow $thisWin
			if( V_Flag )
				// update graph macro.
				sprintf cmd, "DoWindow/R %s", thisWin
				Execute/P/Q cmd
				SetWindow $thisWin hook(wintelWinHook)=nSTR_WintelWinHook
			endif
		endif
	endfor

	if( strlen( MacroList( k_WintelGraphPrefix+"*", ";", "" ) ) > 0 )
		// close, save
		nSTR_d_CloseCAECWintelGraphProc()
		// and reopen
		nSTR_d_OpenCAECWintelGraphProc()
	endif
	
End
Function nSTR_WintelWinHook(s)
	STRUCT WMWinHookStruct &s

	Variable hookResult = 0

	switch(s.eventCode)
		case 0:				// Activate
			// Handle activate
			break

		case 1:				// Deactivate
			// Handle deactivate
			break
		case 8:	
			NVAR/Z modFlag = root:STRPanel_Folder:WintelGraphsIPFNeedsWrite
			NVAR/Z openFlag = root:STRPanel_Folder:WintelGraphsIPFNeedsOpen
			if( NVAR_EXists( modFlag ) )
				modFlag = 1;
			endif
			break;
			// And so on . . .
	endswitch

	return hookResult		// 0 if nothing done, else 1
End


// This function will create a blank WintelGraphs.ipf (no graphs in it, and a default prep-waves function)
// It will place it in the current datapathondisk.
// it does NOT load the procedure.
Function nSTR_createWintelGraphs()
	
	SVAR path_svar = root:STRPanel_Folder:DataPathOnDisk
	variable fileref	= 6
	
	NewPath/O/Q wintelGraphsPath path_svar
	
	Open/Z/R /P=path_svar fileref as k_wintelgraphIPFfilename
	
	// does not exist
	if(V_flag !=0)

		Open /P=wintelGraphsPath fileref as k_WintelGraphIPFFileName
		//			fprintf fileref, "%s", "#pragma TextEncoding = \"Windows-1252\"	\r"
		fprintf fileref, "%s", "///////////////////////////////////////////////////////////////////////////\r"
		fprintf fileref, "%s", "//	WintelGraphs.ipf\r"
		fprintf fileref, "%s", "//	\r"
		fprintf fileref, "%s", "//	WintelGraphs.ipf is a customizable procedure file that contains graph macros\r"
		fprintf fileref, "%s", "// specific to a given instrument. It also contains a function called WintelGraphs_prepWaves\r"
		fprintf fileref, "%s", "// which allows you to do custom wave algebra prior to plotting waves.\r"
		fprintf fileref, "%s", "//\r"
		fprintf fileref, "%s", "// To create a new instrument graph macro:\r"
		fprintf fileref, "%s", "//\r"
		fprintf fileref, "%s", "//	1. Create a graph\r"
		fprintf fileref, "%s", "//	2. Click on graph to bring it to the front\r"
		fprintf fileref, "%s", "//	3. Ctrl+Y to open Graph properties\r"
		fprintf fileref, "%s", "//	4. Rename both Window Title and Window Name to something memorable.\r"
		fprintf fileref, "%s", "//	5. Click the \"save top graph\" button in the STR_Panel\r"
		fprintf fileref, "%s", "//	6. You may make as many graph macros as you like. \r"
		fprintf fileref, "%s", "//	7. Customize wave algebra by clicking \"edit prep waves\". This is often used to calculate isotope dels\r"
		fprintf fileref, "%s", "\r"
		fprintf fileref, "%s", "// To use and update instrument graph macros\r"
		fprintf fileref, "%s", "//\r"
		fprintf fileref, "%s", "// 0. When copying data, copy matching .str and .stc files along with WintelGraphs.ipf\r"
		fprintf fileref, "%s", "// 1. Open the \"STR_Panel\"\r"
		fprintf fileref, "%s", "//		if it already exists: Windows > Other Windows > STR_Panel\r"
		fprintf fileref, "%s", "//		if it does not exist: Macros > TDL File Loader Functions > STR Files Loader\r"
		fprintf fileref, "%s", "// 2. Select and load your data\r"
		fprintf fileref, "%s", "// 3. Click the Wintel Graphs button\r"
		fprintf fileref, "%s", "//		First click will show previously created graphs\r"
		fprintf fileref, "%s", "//		Subsequent clicks will save any changes in formatting or scaling\r"
		fprintf fileref, "%s", "//\r"
		fprintf fileref, "%s", "	\r"
		fprintf fileref, "%s", "////////////////////////////////////////////\r"
		fprintf fileref, "%s", "//	WintelGraphs_PrepWaves()\r"
		fprintf fileref, "%s", "//\r"
		fprintf fileref, "%s", "//	This is a spot to do wave algebra and other commands necessary to produce and \r"
		fprintf fileref, "%s", "// update the waves in the WintelWin_... set of named graphs.\r"
		fprintf fileref, "%s", "//\r"
		fprintf fileref, "%s", "// The default data folder for this function is shown  in the STR_Panel under \"Destination Data Folder\".\r"
		fprintf fileref, "%s", "// If your waves do not exist in this data folder, you must use a full path.\r"
		fprintf fileref, "%s", "////////////////////////////////////////////\r"
		fprintf fileref, "%s", "Function WintelGraphs_PrepWaves()\r"
		fprintf fileref, "%s", "\r"
		fprintf fileref, "%s", "	// define the waves of interest\r"
		fprintf fileref, "%s", "		// Example: No data folder needed usually\r"
		fprintf fileref, "%s", "		// wave CH4 = CH4\r"
		fprintf fileref, "%s", "		// Example: Full data folder needed if\r"
		fprintf fileref, "%s", "		// wave is in a non-standard location\r"
		fprintf fileref, "%s", "		// wave CH4_refit = root:refit:CH4\r"
		fprintf fileref, "%s", "		\r"
		fprintf fileref, "%s", "	\r"
		fprintf fileref, "%s", "	// create template waves\r"
		fprintf fileref, "%s", "		// Example:\r"
		fprintf fileref, "%s", "		// duplicate/o CH4, CH4_ppm\r"
		fprintf fileref, "%s", "\r"
		fprintf fileref, "%s", "	// do wave algebra\r"
		fprintf fileref, "%s", "		// Example: convert from ppb to ppm\r"
		fprintf fileref, "%s", "		// CH4_ppm = CH4/1000\r"
		fprintf fileref, "%s", "\r"
		fprintf fileref, "%s", "	// compute zero valve masks. mask waves are called	wgSTC_Mask_v1 ...\r"
		fprintf fileref, "%s", "	wgSTC_ComputeMask()\r"
		fprintf fileref, "%s", "\r"
		fprintf fileref, "%s", "End"
		
		Close fileRef
	else
		Close fileref
	endif
	KillPath /Z wintelGraphsPath
	Close/A
End

// This function will automatically save a new graph macro for the top window
// It will rename the graph with "WintelWin_" and place it in the appropriate file.

Function nSTR_newWintelWin()
	SVAR path_svar = root:STRPanel_Folder:DataPathOnDisk
	
	NewPath/O/Q wintelGraphsPath path_svar
	
	// test that WintelWin.ipf is loaded
	GetWindow/z $k_WintelGraphIPFFileName, file

	if(stringmatch(S_value,""))
		
		return -1
	endif
	
	// First find name of top graph
	String topWin = winname(0, 1, 1, 0)
	if(strlen(topwin)==0)
		return -1 // no graphs
	endif
	if(Stringmatch(topwin, k_WintelGraphPrefix + "AllSTRSTC")) // this is a special name
		// then it needs a re-name
		String NewtopWin = CleanupName(k_WintelGraphPrefix+"AllSTRSTCuser",0)
			
		Dowindow/F $NewTopWin
			
		if(V_flag == 0)
			// change name
			Dowindow/C/W=$topWin $NewTopWin 
			topWin = NewTopWin
			// change title
			Dowindow/T $topWin, NewTopWin
		else
			// lets start numbering these
		//	String NewTopWinRename = UniqueName(NewTopWin, 6, 0)
			print "already have a window called ", NewTopWin,"."
			Print "To change the graph name type (Ctrl + Y) and edit the graphName field before calling this function" 
			print "or close this graph and try again."
		
		endif
	elseif(Stringmatch(topWin, k_WintelGraphPrefix+"*"))
		// then it's named appropriately
		
	else
		// then it needs a re-name
		NewtopWin = CleanupName(k_WintelGraphPrefix+topWin,0)
		
				
		Dowindow/F $NewTopWin
		
		if(V_flag == 0)
			// change name
			Dowindow/C/W=$topWin $NewTopWin 
			topWin = NewTopWin
			// change title
			Dowindow/T $topWin, NewTopWin
		else
			// lets start numbering these
			String NewTopWinRename = UniqueName(NewTopWin, 6, 0)
			print "already have a window called ", NewTopWin,". Using ", NewTopWinRename, "instead."
			Print "To change the graph name type (Ctrl + Y) and edit the graphName field before calling this function." 
			NewTopWin = NewTopWinRename
		
			// change name
			Dowindow/C/W=$topWin $NewTopWin 
			topWin = NewTopWin
			// change title
			Dowindow/T $topWin, NewTopWin	
		endif

	endif
		

	// list macros in WintelWin.ipf
	String list = MacroList( k_WintelGraphPrefix+"*", ";", "WIN:"+k_wintelgraphIPFfilename ), thisWin, cmd
	String procedureMacros = MacroList( k_WintelGraphPrefix+"*", ";", "WIN:Procedure")
			
	if(whichListItem(topWin,procedureMacros)>=0)
		Print "The graph", topWin, "has already been saved as a macro in the Procedure window."
		Print "Please change the graph name (Ctrl + T) or delete the macro (Ctrl + Shift + F and search for",topWin,")"
		Print "and try again." 
		return -1
	endif
		
	Variable idex, count = ItemsInLIst( list )
	Variable macrodex = whichListItem(topWin, list)

	if(macrodex == -1)
		// not yet a macro
		// now we run the execution stack to close, write and re-open wintelWin		
		Execute/P/Q "Dowindow/F "+topWin
		nSTR_d_CloseCAECWintelGraphProc()
		Execute/P/Q "nSTR_exec_writeWintelWinMacro()"
		// Then re-load WintelWin.ipf
		nSTR_d_OpenCAECWintelGraphProc() // does execute within it
					
	else // macro exists
		//	nSTR_d_GraphWandMod() // this just updates macros, closes and opens. not needed here. 
			
	endif
	KillPath wintelGraphsPath
	//	Execute/Q/P "Dowindow/F "+topWin
End

// this function assumes 
// 1. wintelGraphs is CLOSED!!
// 2. graph is properly named
// 3. graph macro does not exist in wintelWin.ipf
Function nSTR_exec_writeWintelWinMacro()

	SVAR path_svar = root:STRPanel_Folder:DataPathOnDisk
	
	NewPath/O/Q wintelGraphsPath path_svar

	// test if winteGraphs.ipf file exists
	variable fileref	= 6
	Open/Z/R /P=path_svar fileref as k_wintelgraphIPFfilename
	// does exist
	if(V_flag >= 0)
		// open WintelWin.ipf for appending
		Open /A/P=wintelGraphsPath fileref as k_WintelGraphIPFFileName
		
		fprintf fileref, "%s", "\r"
	
		String recrStr = WinRecreation("", 0)
		// this string is so long, we have to break it up
		Variable lines = itemsinlist(WinRecreation("",0), "\r")

		do
		
			String ThisItem = stringfromlist(0, recrstr, "\r")
			recrstr = removeFromList(thisItem, recrstr, "\r")
			fprintf fileref, "%s%s",thisItem,"\r\n" // note windows style line endings.
		
		while(strlen(recrstr)>0)
		
		Close fileref
	endif
End

Function nSTR_deleteWintelWin()
	
	String topWin = winname(0, 1, 1, 0)
	


	String list = MacroList( k_WintelGraphPrefix + "*", ";", "" )
	
	if(whichListItem(topWin, list) >=0 && strlen(topWin) > 0)

	
		nSTR_d_CloseCAECWintelGraphProc()
		Execute/P/Q "nSTR_exec_deleteNamedGraphMacro(\""+topWin+"\")"
		Execute/P/Q "DoWIndow/K "+topWin
		nSTR_d_OpenCAECWintelGraphProc()

	endif
End
// this needs to be executed to the command line, preceded and ended with close and open of graph proc
//	Execute/P/Q "nSTR_d_CloseCAECWintelGraphProc();nSTR_deleteNamedGraphMacro("myname");nSTR_d_openCAECWintelGraphProc()"
// the reason is that open and close operations require recompiling procedures
// and also the macro cannot be deleted until the file is closed. 

Function nSTR_exec_deleteNamedGraphMacro(macroName)
	string macroName
	// 
	SVAR path_svar = root:STRPanel_Folder:DataPathOnDisk
	NewPath/O/Q wintelGraphsPath path_svar

	variable fileref	= 6
	Open/Z/R /P=path_svar fileref as k_wintelgraphIPFfilename
	// does exist
	if(V_flag >= 0)
		Close/A
		Variable lineNumber, len
		String buffer
		lineNumber = 0
		
		variable startMacroline=-1, endMacroLine=-1
		
		Make/T/O/N=0 wintelGraphTW;
		wave/T tw = wintelgraphTW
		String fullPath = path_svar +":"+ k_WintelGraphIPFfileName
		fullPath = replacestring("::",fullPath, ":")
		ReadFile2TextWave( fullPath, tw )
		
		do
			buffer = tw[lineNumber]
			
			if(stringmatch(buffer, "Window "+macroName+"*:*Graph*"))
				// then we found start of macro
				startMacroline = lineNumber
			endif
			if(startMacroLine >=0)
				if(stringmatch(buffer, "*EndMacro*"))
					endMacroLine = lineNumber
				endif
			endif
			lineNumber +=1
		while(lineNumber < numpnts(tw) && (startMacroLine<0 || endMacroLine<0))

		if(startMacroLine>=0 && endMacroLine >=0)
			DeletePoints startMacroLine, endMacroLine-startMacroLine+1, tw
			WriteTextWave2File( tw, path_sVAR, k_WintelGraphIPFfileName )
		endif
		killwaves/z tw
		
	endif

End


Function nSTR_g_PathOrRefresh()

	String history_check_str
	SVAR msg = root:STRPanel_Folder:msg;	sprintf msg "nSTR_g_PathOrRefresh..."		
	Wave/T FileTimeDisplay_rcMat 		= root:STRPanel_Folder:FileTimeDisplay_rcMat
	Wave FileTimeDisplay_SelWave 	= root:STRPanel_Folder:FileTimeDisplay_SelWave
	Wave FileTimeDisplay_ColorWave 	= root:STRPanel_Folder:FileTimeDisplay_ColorWave
	Wave/T LoadHistory = root:STRPanel_Folder:LoadHistory
	
	Variable found_times = 0;
	
	String file_filter_text;
	ControlInfo /W=STR_Panel nSTR2014_FileFilter
	if( V_Flag == 0 )
		// this suggests the window is open in pre-existing experiment, lets remake
		Execute("zSTR_initstrpanel()") //LoadSPE2.ipf
		ControlInfo /W=STR_Panel nSTR2014_FileFilter
	endif	
	if( V_Flag != 3 )
		print "Error in nSTR_g_PathOrRefresh()  Please invoke on cmd line and try again > zSTR_initstrpanel()"
		return -1;
	endif
	file_filter_text = S_Value
	
	// reset all finder waves
	Wave found_str_dat0 = root:STRPanel_Folder:found_str_dat0
	Wave found_stc_dat0 = root:STRPanel_Folder:found_stc_dat0
	Wave found_pb_dat0 = root:STRPanel_Folder:found_pb_dat0
	Wave found_cal_dat0 = root:STRPanel_Folder:found_cal_dat0
	Wave found_interp_dat0 = root:STRPanel_Folder:found_interp_dat0
	Wave found_stany_dat0 = root:STRPanel_Folder:found_stany_dat0
	Wave/T found_stany_type = root:STRPanel_folder:found_stany_type
	Wave/T f_stany = root:STRPanel_folder:found_stany
	
	// add any additional line endings you want to support here. 
	string anyList = "sto;ste;sts" 
	
	
	redimension/n=0 found_str_dat0, found_stc_dat0, found_pb_dat0, found_cal_dat0, found_interp_dat0, found_stany_dat0
	
	// now we switch
	strswitch (file_filter_text)
		case "sample str/stc":
			nSTR_g_PopulatePreFiles("STR");
			nSTR_g_PopulatePreFiles("STC");
			break;
		case "playback str":
			nSTR_g_PopulatePreFiles("PB");
			break;
		case "calibration _CAL.str":
			nSTR_g_PopulatePreFiles("CAL");
			break;
		case "EddyOut _Interp.str":
			nSTR_g_PopulatePreFiles("Interp");
			break;
		
		case "any other type":
			variable i
			for(i=0;i<itemsinlist(anyList);i+=1)
				string thisEnding = stringfromlist(i,anyList)
				nSTR_g_PopulatePreFiles(thisEnding)
			endfor
			nSTR_g_PopulatePreFilesAny(anyList)
			
			//	sort {found_stany_dat0,found_stany_type}, found_stany_type, found_stany, found_stany_dat0
			SortAndKillNansFast(getwavesdatafolder(found_stany_dat0,2)+";"+getwavesdatafolder(f_stany,2)+";"+getwavesdatafolder(found_stany_type,2),1)
			break
	endswitch
	
	
	// build the listing of waves
	Variable idex, typeCount, str_dex, stc_dex, pb_dex, cal_dex, interp_dex, any_dex
	found_times += numpnts( found_str_dat0 );
	found_times += numpnts( found_stc_dat0 );
	found_times += numpnts( found_pb_dat0 );
	found_times += numpnts( found_cal_dat0 );
	found_times += numpnts( found_interp_dat0 );
	Make/O/N=( found_times )/D temp_str_stc_datetimeset
	
	// don't add these other types yet. 
	found_times += numpnts( found_stany_dat0);
	
	// add the times for these guys. 
	if( numpnts( found_str_dat0 ) > 0 )
		temp_str_stc_datetimeset[0,numpnts( found_str_dat0 )] = found_str_dat0[p]
	endif
	if( numpnts( found_stc_dat0) > 0 )
		temp_str_stc_datetimeset[numpnts( found_str_dat0 ),] = found_stc_dat0[p-numpnts( found_str_dat0 )]
	endif
	if( numpnts( found_pb_dat0) > 0 )
		temp_str_stc_datetimeset[numpnts( found_str_dat0 ),] = found_pb_dat0[p-numpnts( found_str_dat0 )]
	endif
	if( numpnts( found_cal_dat0) > 0 )
		temp_str_stc_datetimeset[numpnts( found_str_dat0 ),] = found_cal_dat0[p-numpnts( found_str_dat0 )]
	endif
	if( numpnts( found_interp_dat0) > 0 )
		temp_str_stc_datetimeset[numpnts( found_str_dat0 ),] = found_interp_dat0[p-numpnts( found_str_dat0 )]
	endif

		 
	Sort temp_str_stc_datetimeset,temp_str_stc_datetimeset
	
	if( 0 < found_times  )
	
		// cut down to unique times between the two file types
		idex = 1
		do
			if( temp_str_stc_datetimeset[idex] == temp_str_stc_datetimeset[idex-1] )
				DeletePoints idex, 1, temp_str_stc_datetimeset
			else
				idex += 1
			endif 
		while( idex < numpnts( temp_str_stc_datetimeset ) )
		
		
		// we don't actually want to cut down double times for these other potentially unknown types	
		if( numpnts(found_stany_dat0) > 0)
			redimension/N=(found_times)/D temp_str_stc_datetimeset
			temp_str_stc_datetimeset[numpnts( found_str_dat0 ),] = found_stany_dat0[p+numpnts( found_str_dat0 )]
		endif
		
		
		Redimension/N=( numpnts( temp_Str_stc_datetimeset ) , 3) 	FileTimeDisplay_rcMat
		Redimension/N=( DimSize( FileTimeDisplay_rcMat, 0 )) 		FileTimeDisplay_SelWave
		Redimension/N=( DimSize( FileTimeDisplay_rcMat, 0 ),3)		FileTimeDisplay_ColorWave
		
		// each file type needs to be tested against the now unique timeset
		for( idex = 0; idex < numpnts( temp_str_stc_datetimeset ); idex +=1 )
			typeCount = 0;
			str_dex = BinarySearch( found_str_dat0, temp_str_stc_datetimeset[idex] )
			if( str_dex >= 0 )
				typeCount += 1;
			endif
			stc_dex = BinarySearch( found_stc_dat0, temp_str_stc_datetimeset[idex] )
			if( stc_dex >= 0 )
				typeCount += 2;
			endif
			
			if( numpnts( found_pb_dat0) > 0 )
				pb_dex = BinarySearch(found_pb_dat0, temp_str_stc_datetimeset[idex])
				if(pb_dex >=0)
					typecount = 4
				endif
			endif
			if( numpnts( found_cal_dat0) > 0 )
				cal_dex = BinarySearch(found_cal_dat0, temp_str_stc_datetimeset[idex])
				if(cal_dex >=0)
					typecount = 5
				endif
			endif
			if( numpnts( found_interp_dat0) > 0 )
				interp_dex = BinarySearch(found_interp_dat0, temp_str_stc_datetimeset[idex])
				if(interp_dex >=0)
					typecount = 6
				endif
			endif
			if( numpnts(found_stany_dat0) > 0)
				any_dex = BinarySearch(found_stany_dat0, temp_str_stc_datetimeset[idex])
				if(any_dex >=0)
					typecount = 7
				endif
			endif
			
			switch (typeCount)
				case 1:
					FileTimeDisplay_rcMat[idex][0] = nSTR_DateTime2FileDisplayText( temp_Str_stc_datetimeset[idex] )
					FileTimeDisplay_rcMat[idex][1] = "STR"
					break;
				case 2:
					FileTimeDisplay_rcMat[idex][0] = nSTR_DateTime2FileDisplayText( temp_Str_stc_datetimeset[idex] )
					FileTimeDisplay_rcMat[idex][1] = "STC"
					break;
				case 3:
					FileTimeDisplay_rcMat[idex][0] = nSTR_DateTime2FileDisplayText( temp_Str_stc_datetimeset[idex] )
					FileTimeDisplay_rcMat[idex][1] = "both"
					break;
				case 4:
					FileTimeDisplay_rcMat[idex][0] = nSTR_DateTime2FileDisplayText( temp_Str_stc_datetimeset[idex] )
					FileTimeDisplay_rcMat[idex][1] = "PB"
					break;
				case 5:
					FileTimeDisplay_rcMat[idex][0] = nSTR_DateTime2FileDisplayText( temp_Str_stc_datetimeset[idex] )
					FileTimeDisplay_rcMat[idex][1] = "CAL"
					break;	
				case 6:
					FileTimeDisplay_rcMat[idex][0] = nSTR_DT2FileDisplayText_EddyOut( temp_Str_stc_datetimeset[idex] )
					FileTimeDisplay_rcMat[idex][1] = "Interp"
					break;
				case 7:
					FileTimeDisplay_rcMat[idex][0] = nSTR_DateTime2FileDisplayText( temp_Str_stc_datetimeset[idex] )
					FileTimeDisplay_rcMat[idex][1] = upperStr(found_stany_type[idex - (numpnts(temp_str_stc_datetimeset)-numpnts(found_stany_dat0))])
					break;				
			endswitch	
			
			if( strsearch( FileTimeDisplay_rcMat[idex][0], "_", 0 ) != -1 )
				if(typeCount == 6)
					history_check_str = 	nSTR_DT2FileDisplayText_EddyOut( temp_Str_stc_datetimeset[idex])+"-"+FileTimeDisplay_rcMat[idex][1] 
				else
					history_check_str = 	nSTR_DateTime2FileDisplayText( temp_Str_stc_datetimeset[idex])+"-"+FileTimeDisplay_rcMat[idex][1] 
				endif
				if( FindStringInWave( history_check_str, Loadhistory, -1 ) == -1 )
					FileTimeDisplay_rcMat[idex][2] = "_NL"
				else
					FileTimeDisplay_rcMat[idex][2] = "<loaded>"
				endif

			endif		

		endfor
	else
		msg = "No .str/.stc files found"
		Redimension/N=(0,3) FileTimeDisplay_rcMat
		Redimension/N=0 FileTimeDisplay_SelWave
		Redimension/N=(0,3) FileTimeDisplay_ColorWave 
	endif
	KillWaves/Z temp_str_stc_datetimeset;	
	
End

Function nSTR_g_PopulatePreFilesAny(fileEndingList)
	string fileEndingList
	
	wave/T found_stany = root:STRPanel_Folder:found_stany
	wave/D found_stany_dat0 = root:STRPanel_Folder:found_stany_dat0
	Wave/T found_stany_type = root:STRPanel_folder:found_stany_type
	
	redimension/n=0 found_stany, found_stany_dat0, found_stany_type
	variable i
	for(i=0;i<itemsinlist(fileEndingList);i+=1)
		String thisEnding = stringfromlist(i,fileEndingList)
		Wave/T f_this = $("root:STRPanel_Folder:found_"+thisEnding)
		Wave/D f_this_dat0 = $("root:STRPanel_Folder:found_"+thisEnding+"_dat0")
		variable oldLength = numpnts(found_stany)
		concatenate /NP /T {f_this}, found_stany
		concatenate /NP {f_this_dat0}, found_stany_dat0
		make/n=(numpnts(f_this))/T tempEndingText ; wave /T tempT= tempEndingText; tempT = thisEnding
		concatenate /NP /T {tempT}, found_stany_type
		killwaves/z tempT
	endfor
		
end

Function nSTR_j_UpdateWintelGraphsIPF()
	SVAR msg = root:STRPanel_Folder:msg;
	Wave LoadHistory= root:STRPanel_folder:LoadHistory
	if( k_AutoSearch_WintelGraphs == 1 )

		// these are not needed. flags are set within functions		
		//		NVAR modFlag = root:STRPanel_Folder:WintelGraphsIPFNeedsWrite
		//		NVAR openFlag = root:STRPanel_Folder:WintelGraphsIPFNeedsOpen	
	
		nSTR_d_OpenCAECWintelGraphProc()


		//	The key here is that these functions will not have a compiled procedure
		// if run right away. We have to delay their running by doing Execute/P
		// which allows the various compiling functions (also run by Execute/P)
		// to work. 
	
		//	Check for existance of data here!
		if(numpnts(loadHistory)>0)
			Execute/P/Q "nSTR_d_GraphWandProc()"	
			Execute/P/Q "nSTR_d_GraphWandMod()"  // this handles closing the procedure and calling the open function if needed
		else
			msg = "Could not make graph. Please load .str/.stc files"
		endif
		
	endif
End

Function nSTR_w_ResetDataWaves()
	
	String list, this_, saveFolder
	Variable idex, count, pnts_in_timeWave, modFolder
	
	SVAR DestinationDataFolder = root:STRPanel_Folder:DestinationDataFolder
	if( strlen( DestinationDataFolder ) > 0 )
		modfolder = 1; saveFolder = GetDataFolder(1); SetDataFolder root:; MakeAndOrSetDF( DestinationDataFolder );
	else
		modFolder = 1;
		saveFolder = GetDataFolder(1); SetDataFolder root:;
	endif
	
	Wave/Z source = str_source_rtime
	if( WaveExists( source ) )
		pnts_in_timeWave = numpnts( source )
		list = WaveList( "*", ";", "" )
		count = ItemsInList( list );
		for( idex = 0; idex < count; idex += 1 )
			this_ = StringFromList( idex, list )
			Wave/Z w = $this_
			if( WaveExists( w ) )
				if( numpnts( w ) == pnts_in_timeWave )
					Redimension/N=0 w
				endif
			endif
		endfor
	endif
	
	Wave/Z source = stc_time
	if( WaveExists( source ) )
		pnts_in_timeWave = numpnts( source )
		list = WaveList( "*", ";", "" )
		count = ItemsInList( list );
		for( idex = 0; idex < count; idex += 1 )
			this_ = StringFromList( idex, list )
			Wave/Z w = $this_
			if( WaveExists( w ) )
				if( numpnts( w ) == pnts_in_timeWave )
					Redimension/N=0 w
				endif
			endif
		endfor
	endif
	
	wave/z/T speciesMeta = root:STRPanel_Folder:SpeciesMetaPosnData
	if(waveexists(speciesMeta))
		redimension/n=0 speciesMeta
	endif
	
	if(modFolder)
		setdatafolder SaveFolder
	endif
End

Function/S nSTR_DateTime2FileDisplayText( adatetime )
	variable adatetime
	
	//	string yy
	//	sprintf yy, "%s_%s" Secs2Date(adatetime, 0), Secs2Time( adatetime, 3 )
	//	
	//	yy = scReplaceCharWChar( yy, "/", "" )
	//	yy = scReplaceCharWChar( yy, ":", "" )
	//	return yy
	String returnStr = "000000_000000"
	String qstr = DateTime2Text( adatetime );
	Variable qyear, qmon, qday, qhour, qmin, qsec;
	qyear 	= str2num( StringFromList( 2, StringFromList( 0, qstr, " " ), "/" )); 
	qmon 	= str2num( StringFromList( 0, StringFromList( 0, qstr, " " ), "/" )); 
	qday 	= str2num( StringFromList( 1, StringFromList( 0, qstr, " " ), "/" )); 
	qhour 	= str2num( StringFromList( 0, StringFromList( 1, qstr, " " ), ":" )); 
	qmin 	= str2num( StringFromList( 1, StringFromList( 1, qstr, " " ), ":" )); 
	qsec 	= str2num( StringFromList( 2, StringFromList( 1, qstr, " " ), ":" )); 

	sprintf returnStr "%d%02d%02d_%02d%02d%02d", qyear, qmon, qday, qhour, qmin, qsec

	return returnStr

End

Function/S nSTR_DT2FileDisplayText_EddyOut( adatetime )
	variable adatetime
	
	//	string yy
	//	sprintf yy, "%s_%s" Secs2Date(adatetime, 0), Secs2Time( adatetime, 3 )
	//	
	//	yy = scReplaceCharWChar( yy, "/", "" )
	//	yy = scReplaceCharWChar( yy, ":", "" )
	//	return yy
	String returnStr = "000000_00_0"
	String qstr = DateTime2Text( adatetime );
	Variable qyear, qmon, qday, qhour, qmin, qsec;
	qyear 	= str2num( StringFromList( 2, StringFromList( 0, qstr, " " ), "/" )); 
	qmon 	= str2num( StringFromList( 0, StringFromList( 0, qstr, " " ), "/" )); 
	qday 	= str2num( StringFromList( 1, StringFromList( 0, qstr, " " ), "/" )); 
	qhour 	= str2num( StringFromList( 0, StringFromList( 1, qstr, " " ), ":" )); 
	qmin 	= str2num( StringFromList( 1, StringFromList( 1, qstr, " " ), ":" )); 
	qsec 	= str2num( StringFromList( 2, StringFromList( 1, qstr, " " ), ":" )); 

	sprintf returnStr "%d%02d%02d_%d_%01d", qyear, qmon, qday, qhour, round(qmin/30)

	return returnStr

End

Function nSTR_g_PopulatePreFiles(type)
	String type
	
	Variable idex, count
	String this_file, this_datetime
	Wave/T f_str = root:STRPanel_Folder:found_str
	Wave/T f_stc = root:STRPanel_Folder:found_stc
	Wave/T f_pb = root:STRPanel_Folder:found_pb
	Wave/T f_cal = root:STRPanel_Folder:found_cal
	Wave/T f_interp = root:STRPanel_Folder:found_interp

	SVAR path_svar = root:STRPanel_Folder:DataPathOnDisk
	variable i, PB_Search, CAL_Search, Interp_Search, CalcDAT, this_dat
	String SaveDF = GetDataFolder(1) 	
	SetDatafolder root:STRPanel_Folder
			
	NewPath/O/Q/Z nSTR_Path path_svar	
	strswitch( lowerstr(type) )
		case "CAL":
			GFL_FilelistAtOnce( "nSTR_Path", 0, f_cal, ".str" )
			Wave found_cal_dat0 = root:STRPanel_Folder:found_cal_dat0
			Redimension/N=(numpnts( f_cal ))/D found_cal_dat0
			if( numpnts( f_cal ) > 0 )
				for(i=numpnts(f_cal)-1;i>=0;i-=1)
					if(stringmatch(f_cal[i], "*CAL*"))
						found_cal_dat0[i] = FileNameToDAT( f_cal[i], "CAL_date_timestamp" )
					else
						DeletePoints i,1, found_cal_dat0, f_cal
					endif
				endfor
				//	Sort found_cal_dat0, found_cal_dat0, f_cal
				SortAndKillNansFast(getwavesdatafolder(found_cal_dat0,2)+";"+getwavesdatafolder(f_cal,2),1)
				
			endif

			break
		case "PB":
			GFL_FilelistAtOnce( "nSTR_Path", 0, f_pb, ".str" )
			Wave found_pb_dat0 = root:STRPanel_Folder:found_pb_dat0
			Redimension/N=(numpnts( f_pb ))/D found_pb_dat0
			if( numpnts( f_pb ) > 0 )
				for(i=numpnts(f_pb)-1;i>=0;i-=1)
					if(stringmatch(f_pb[i], "*_PB*"))
						found_pb_dat0[i] = Floor(FileNameToDAT( f_pb[i], "tdlwintel_date_timestamp" ))
						//printf "%d, %s & %s\r" i, DTI_DateTime2Text( found_pb_dat0[i], "sortable" ), f_pb[i] 
					else
						DeletePoints i,1, found_pb_dat0, f_pb
					endif
				endfor
				//	Sort found_pb_dat0, found_pb_dat0, f_pb
				SortAndKillNansFast(getwavesdatafolder(found_pb_dat0,2)+";"+getwavesdatafolder(f_pb,2),1)
			endif

			break
		case "Interp":
			GFL_FilelistAtOnce( "nSTR_Path", 0, f_interp, ".str" )
			Wave found_interp_dat0 = root:STRPanel_Folder:found_interp_dat0
			Redimension/N=(numpnts( f_interp ))/D found_interp_dat0
			if( numpnts( f_interp ) > 0 )
				for(i=numpnts(f_interp)-1;i>=0;i-=1)
					if(stringmatch(f_interp[i], "*_Interp*"))
						found_interp_dat0[i] = Floor(FileNameToDAT( f_interp[i], "EddyOut_date_timestamp" ))
						//printf "%d, %s & %s\r" i, DTI_DateTime2Text( found_interp_dat0[i], "sortable" ), f_interp[i] 
					else
						DeletePoints i,1, found_interp_dat0, f_interp
					endif
				endfor
				//	Sort found_interp_dat0, found_interp_dat0, f_interp
				SortAndKillNansFast(getwavesdatafolder(found_interp_dat0,2)+";"+getwavesdatafolder(f_interp,2),1)
			endif

			break
		case "str":
			GFL_FilelistAtOnce( "nSTR_Path", 0, f_str, ".str" )
			Wave found_str_dat0 = root:STRPanel_Folder:found_str_dat0
			Redimension/N=(numpnts( f_str ))/D found_str_dat0			
			if( numpnts( f_str ) > 0 )
				for(i=numpnts(f_str)-1;i>=0;i-=1)
					this_file = f_str[i];
					PB_Search = strsearch( this_file, "_PB", 0 );
					CAL_Search = strsearch( this_file, "_CAL", 0 );
					Interp_Search = strsearch( this_file, "_Interp", 0 );
					//if(	(!stringmatch(f_str[i], "*_PB*")) | ((!stringmatch(f_str[i], "*CAL*"))) )

					if( (PB_Search >= 0 ) | (CAL_Search >= 0 ) | (Interp_Search >= 0 ) )
						DeletePoints i, 1, found_str_dat0, f_str
					else
						this_dat = FileNameToDAT( f_str[i], "tdlwintel_date_timestamp" )
						found_str_dat0[i] = this_dat

					endif
				endfor
				//	Sort found_str_dat0, found_str_dat0, f_str
				SortAndKillNansFast(getwavesdatafolder(found_str_dat0,2)+";"+getwavesdatafolder(f_str,2),1)
				
			endif
		
			break;
		case "stc":
			GFL_FilelistAtOnce( "nSTR_Path", 0, f_stc, ".stc" )
			Wave found_stc_dat0 = root:STRPanel_Folder:found_stc_dat0
			Redimension/N=(numpnts( f_stc ))/D found_stc_dat0
			if( numpnts( f_stc ) > 0 )
				found_stc_dat0 =FileNameToDAT( f_stc[p], "tdlwintel_date_timestamp" )
				//	Sort found_stc_dat0, found_stc_dat0, f_stc
				SortAndKillNansFast(getwavesdatafolder(found_stc_dat0,2)+";"+getwavesdatafolder(f_stc,2),1)
				
			endif
			break;
			
			
		default: // this will catch anything else like sto, ste, etc. 
			wave/T/Z f_this = $("root:STRPanel_Folder:found_"+lowerstr(type))	
			if(!waveexists(f_this))
				Make/T/n=1 $("root:STRPanel_Folder:found_"+lowerstr(type))
				wave/T f_this= $("root:STRPanel_Folder:found_"+lowerstr(type))
			endif
			
			GFL_FilelistAtOnce( "nSTR_Path", 0, f_this, "."+lowerstr(type) )
			
			Wave/Z found_this_dat0 = $("root:STRPanel_Folder:found_"+lowerstr(type)+"_dat0")
			if(!waveexists(found_this_dat0))
				Make/n=(numpnts(f_this)) $("root:STRPanel_Folder:found_"+lowerstr(type)+"_dat0")
				wave found_this_dat0 = $("root:STRPanel_Folder:found_"+lowerstr(type)+"_dat0")
			endif

			Redimension/N=(numpnts( f_this ))/D found_this_dat0
			if( numpnts( f_this ) > 0 )
				found_this_dat0 =FileNameToDAT( f_this[p], "tdlwintel_date_timestamp" )
				//	Sort found_this_dat0, found_this_dat0, f_this
				SortAndKillNansFast(getwavesdatafolder(found_this_dat0,2)+";"+getwavesdatafolder(f_this,2),1)
				
			endif
			
			break;
			
	endswitch
	
	SetDatafolder SaveDF
	KillPath/Z nSTR_Path
	

End

Function nSTR_q_SortSTR()
	SVAR msg = root:STRPanel_Folder:msg;	sprintf msg "sort ... "		
	
	variable modFolder
	string SaveFolder
	SVAR DestinationDataFolder = root:STRPanel_Folder:DestinationDataFolder
	if( strlen( DestinationDataFolder ) > 0 )
		modfolder = 1; saveFolder = GetDataFolder(1); SetDataFolder root:; MakeAndOrSetDF( DestinationDataFolder );
	else
		modFolder = 1;
		saveFolder = GetDataFolder(1); SetDataFolder root:;
	endif
	String msg_loc = "sort...", this_, list_all, list_pnt_match
	Variable idex, count, pnts
	Wave/Z src_time = str_source_rtime
	if( WaveExists( src_time ) )
		pnts = numpnts( src_time );
		list_all = WaveList( "*", ";", "" ); list_pnt_match = "";
		count = ItemsInList( list_all );
		for( idex = 0; idex < count; idex += 1 )
			this_ = StringFromList( idex, list_all );
			Wave w = $this_
			if( numpnts( w ) == pnts )
				list_pnt_match = list_pnt_match + NameOfWave(w) +  ";"
			endif
		endfor
		
		nSTR_q_SortThisSet( list_pnt_match );
	else
		msg_loc = msg_loc + "no str_ time found! "
	endif
	
	if(modFolder)
		setDatafolder SaveFolder
	endif
End

Function nSTR_q_SortSTC()
	SVAR msg = root:STRPanel_Folder:msg;	sprintf msg "sort ... "		
	variable modFolder
	string SaveFolder
	SVAR DestinationDataFolder = root:STRPanel_Folder:DestinationDataFolder
	if( strlen( DestinationDataFolder ) > 0 )
		modfolder = 1; saveFolder = GetDataFolder(1); SetDataFolder root:; MakeAndOrSetDF( DestinationDataFolder );
	else
		modFolder = 1;
		saveFolder = GetDataFolder(1); SetDataFolder root:;
	endif
	String msg_loc = "sort...", this_, list_all, list_pnt_match
	Variable idex, count, pnts
	Wave/Z src_time = stc_time
	if( WaveExists( src_time ) )
		pnts = numpnts( src_time );
		list_all = WaveList( "*", ";", "" ); list_pnt_match = "";
		count = ItemsInList( list_all );
		for( idex = 0; idex < count; idex += 1 )
			this_ = StringFromList( idex, list_all );
			Wave w = $this_
			if( numpnts( w ) == pnts )
				list_pnt_match = list_pnt_match + NameOfWave(w) +  ";"
			endif
		endfor
		
		nSTR_q_SortThisSet( list_pnt_match );
	else
		msg_loc = msg_loc + "no stc_ time found! "
	endif
	if(modFolder)
		setDatafolder SaveFolder
	endif
	
End

Function nSTR_q_SortThisSet( list )
	String list 
	
	Variable idex, count = ItemsInLIst( list )
	String comma_line, cmd
	Variable jdex, fdex, jcount, typeVar
	
	for( idex = 0; idex < count; idex += 1 )
		Wave key_w = $StringFromList( idex, list )
		if( strsearch(  NameOfWave( key_w), "File", 0 ) == -1 )
			//comma_line = StringFromList( idex, list ) 	+ ","
			comma_line =  ReplaceString( ";", list, "," )
			comma_line = comma_line[0, strlen( comma_line ) -2 ]
			sprintf cmd, "Sort %s, %s", NameOfWave( key_w ),  comma_line
			printf " ... standby during [%02d/%02d] %s\r", idex, count -1, cmd
			Execute cmd
				
			jcount = numpnts( key_w );
			fdex = -1;
			for( jdex = 0; jdex < jcount; jdex += 1 )
				if( numtype( key_w[jdex] ) != 0 )
					fdex = jdex;
					jdex = jcount;
				endif	
			endfor
			if( fdex != -1 )
				// implies a nan wave located
				sprintf cmd, "DeletePoints %d, %d, %s", fdex, jcount - fdex, comma_line
				printf "Found Nans in %s -> %s\r", NameOfWave( key_w ), cmd
				Execute cmd
			endif
		endif
	endfor
	// and put it all back
	sprintf cmd, "Sort %s, %s" StringFromList( 0, list ), comma_line
	printf "Final Sort back to chronological -> %s\r", cmd

	Execute cmd
End
Function nSTR_z_ListBoxProc(lba) : ListBoxControl
	STRUCT WMListboxAction &lba

	Variable row = lba.row
	Variable col = lba.col
	WAVE/T/Z listWave = lba.listWave
	WAVE/Z selWave = lba.selWave

	switch( lba.eventCode )
		case -1: // control being killed
			break
		case 1: // mouse down
			break
		case 3: // double click
			break
		case 4: // cell selection
		case 5: // cell selection plus shift key
			break
		case 6: // begin edit
			break
		case 7: // finish edit
			break
		case 13: // checkbox clicked (Igor 6.2 or later)
			break
	endswitch

	return 0
End

////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////

#pragma ModuleName = CAECDataAcq

// depreciated. 
//Menu "Macros"
//	"Show CAEC Data Acq Panel/1", /Q, ShowCAECDataAcqPanel()
//End

// NOTE: The name you choose must be distinctive!
static Constant kPrefsVersion = 100
static StrConstant kPackageName = "CAEC Data Acquisition"
static StrConstant kPreferencesFileName = "caec_wintel_strstc.bin"
static Constant kPrefsRecordID = 0		// The recordID is a unique number identifying a record within the preference file.
// In this example we store only one record in the preference file.

// NOTE: Variable, String, WAVE, NVAR, SVAR or FUNCREF fields can not be used in this structure
// because they reference Igor objects that cease to exist when you do New Experiment.
Structure CAECDataAcqPrefs
uint32 version					// Preferences structure version number. 100 means 1.00.
double panelCoords[4]		// left, top, right, bottom
uchar phaseLock
uchar triggerMode
double ampGain
uint32 reserved[100]		// Reserved for future use
EndStructure

//	DefaultPackagePrefsStruct(prefs)
//	Sets prefs structure to default values.
static Function DefaultPackagePrefsStruct(prefs)
	STRUCT CAECDataAcqPrefs &prefs

	prefs.version = kPrefsVersion

	prefs.panelCoords[0] = 5				// Left
	prefs.panelCoords[1] = 40				// Top
	prefs.panelCoords[2] = 5+190		// Right
	prefs.panelCoords[3] = 40+125		// Bottom
	prefs.phaseLock = 1
	prefs.triggerMode = 1
	prefs.ampGain = 1.0

	Variable i
	for(i=0; i<100; i+=1)
		prefs.reserved[i] = 0
	endfor
End

// SyncPackagePrefsStruct(prefs)
// Syncs package prefs structures to match state of panel.
//	Call this only if the panel exists.
static Function SyncPackagePrefsStruct(prefs)
	STRUCT CAECDataAcqPrefs &prefs

	// Panel does exists. Set prefs to match panel settings.
	prefs.version = kPrefsVersion
	
	GetWindow CAECDataAcqPanel wsize
	// NewPanel uses device coordinates. We therefore need to scale from
	// points (returned by GetWindow) to device units for windows created
	// by NewPanel.
	Variable scale = ScreenResolution / 72
	prefs.panelCoords[0] = V_left * scale
	prefs.panelCoords[1] = V_top * scale
	prefs.panelCoords[2] = V_right * scale
	prefs.panelCoords[3] = V_bottom * scale
	
	ControlInfo /W=CAECDataAcqPanel PhaseLock
	prefs.phaseLock = V_Value				// 0=unchecked; 1=checked
	
	ControlInfo /W=CAECDataAcqPanel TriggerMode
	prefs.triggerMode = V_Value				// Menu item number starting from on
	
	ControlInfo /W=CAECDataAcqPanel AmpGain
	prefs.ampGain = str2num(S_value)		// 1, 2, 5 or 10
End

// InitPackagePrefsStruct(prefs)
// Sets prefs structures to match state of panel or to default values if panel does not exist.
static Function InitPackagePrefsStruct(prefs)
	STRUCT CAECDataAcqPrefs &prefs

	DoWindow CAECDataAcqPanel
	if (V_flag == 0)
		DefaultPackagePrefsStruct(prefs)		// Panel does not exist. Set prefs struct to default.
	else
		SyncPackagePrefsStruct(prefs)			// Panel does exists. Sync prefs struct to match panel state.
	endif
End

static Function LoadPackagePrefs(prefs)
	STRUCT CAECDataAcqPrefs &prefs

	// This loads preferences from disk if they exist on disk.
	LoadPackagePreferences kPackageName, kPreferencesFileName, kPrefsRecordID, prefs
	// Printf "%d byte loaded\r", V_bytesRead

	// If error or prefs not found or not valid, initialize them.
	if (V_flag!=0 || V_bytesRead==0 || prefs.version!=kPrefsVersion)
		InitPackagePrefsStruct(prefs)						// Set based on panel if it exists or set to default values.
		SavePackagePrefs(prefs)							// Create initial prefs record.
	endif
End

static Function SavePackagePrefs(prefs)
	STRUCT CAECDataAcqPrefs &prefs

	SavePackagePreferences kPackageName, kPreferencesFileName, kPrefsRecordID, prefs
End

static Function KillPackagePrefs()	// Used to test SavePackagePreferences /KILL flag added in Igor Pro 6.10B04.
	STRUCT CAECDataAcqPrefs prefs
	SavePackagePreferences /KILL kPackageName, kPreferencesFileName, kPrefsRecordID, prefs
End

static Function CAECDataAcqPanelHook(infoStr)
	String infoStr

	STRUCT CAECDataAcqPrefs prefs
	
	String event= StringByKey("EVENT",infoStr)
	strswitch(event)
		case "activate":				// We do not get this on Windows when the panel is first created.
			break

		case "moved":					// This message was added in Igor Pro 5.04B07.
		case "resize":
			SyncPackagePrefsStruct(prefs)			// Sync prefs struct to match panel state.
			SavePackagePrefs(prefs)
			break
	endswitch
	
	return 0
End

Function ShowCAECDataAcqPanel()
	DoWindow/F CAECDataAcqPanel
	if (V_flag != 0)
		return 0
	endif

	STRUCT CAECDataAcqPrefs prefs
	LoadPackagePrefs(prefs)

	Variable left = prefs.panelCoords[0]
	Variable top = prefs.panelCoords[1]
	Variable right = prefs.panelCoords[2]
	Variable bottom = prefs.panelCoords[3]
	NewPanel/W=(left, top, right, bottom) /K=1

	DoWindow/C CAECDataAcqPanel

	CheckBox PhaseLock, pos={31,24}, size={67,14}, proc=CAECDataAcq#CAECPanelCheckProc, title="Phase Lock", value=prefs.phaseLock

	Variable triggerMode = prefs.triggerMode
	PopupMenu TriggerMode,pos={31,50}, size={119,20}, proc=CAECDataAcq#CAECPanelPopMenuProc, title="Trigger Mode"
	PopupMenu TriggerMode,  mode=triggerMode, value= #"\"Auto;Manual\""

	Variable ampGainMode = 1
	switch(prefs.ampGain)
		case 1:
			ampGainMode = 1
			break
		case 2:
			ampGainMode = 2
			break
		case 5:
			ampGainMode = 3
			break
		case 10:
			ampGainMode = 4
			break
	endswitch
	PopupMenu AmpGain, pos={31,81}, size={119,20}, proc=CAECDataAcq#CAECPanelPopMenuProc, title="Amp Gain"
	PopupMenu AmpGain, mode=ampGainMode, value= #"\"1;2;5;10\""

	SetWindow kwTopWin,hook=CAECDataAcq#CAECDataAcqPanelHook
End

static Function CAECPanelCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked

	STRUCT CAECDataAcqPrefs prefs
	LoadPackagePrefs(prefs)
	
	strswitch(ctrlName)
		case "PhaseLock":
			prefs.phaseLock = checked
			break
	endswitch

	SavePackagePrefs(prefs)
End

static Function CAECPanelPopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	STRUCT CAECDataAcqPrefs prefs
	LoadPackagePrefs(prefs)
	
	strswitch(ctrlName)
		case "TriggerMode":
			prefs.triggerMode = popNum
			break
		
		case "AmpGain":
			prefs.ampGain = str2num(popStr)
			break
	endswitch
			
	SavePackagePrefs(prefs)
End


///////  TDLWintel External Command Protocol
// twex_
// 

// twex_test()
// this is a function that can test the configuration lightly and make the external controller session uptodate
// Things it checks
// a) is datafolder created?
// b) are paths to command units intact and valid
// c) what is the state of acknowledgments


//          "ab" = Quit TDLWintel
//          "ac" = Resynchronize the TDLWintel millisecond clock to
//                 the local time of day clock 
//          "ad"dstring = Synchronize the time of day clock on the
//                       tdlwintel computer to time of day clock on
//						 another computer with network address dstring
//          "ae"dstring = Change data folder to dstring
//          "af" = Go to stream mode
//          "ah"dstring = Switch to field number dstring
//          "ai" = Go to display mode
//          "aj" = Go to current signal mode
//          "ak" = Go to signal average mode
//          "al" = Go to burst mode
//          "amwd� = Toggle write disk
//          "amwd0� = Deactivate write disk
//          "amwd1� = Activate write disk
//          "amass� = Toggle automatic spectral save
//          "amass0� = Deactivate automatic spectral save
//          "amass1� = Activate automatic spectral save
//          �ampnorm� = Toggle pulse normalization
//          �ampnorm0� = Deactivate pulse normalization
//          �ampnorm1� = Activate pulse normalization
//          �amabg� = Toggle automatic background
//          �amabg0� = Deactivate automatic background
//          �amabg1� = Activate automatic background
//          �amrlock� = Toggle frequency lock
//          �amrlock0� = Deactivate frequency lock
//          �amrlock1� = Activate frequency lock
//          �amebg� = Toggle electronic background
//          �amebg0� = Deactivate electronic background
//          �amebg1� = Activate electronic background
//          "anc"dstring = Close valve # dstring 
//          �ant�dstring = Toggle valve # dstring (valve #�s are zero
//              based: first valve is 0) 
//          �anc�dstring = Close valve # dstring (valve #�s are zero
//              based: first valve is 0) 
//          �apon�dstring = Turn on the �fix baseline to 1000�
//              feature in Field # dstring 
//          �apoff�dstring = Turn off the �fix baseline to 1000�
//              feature in Field # dstring 
//          "aq" = Initiate background measurement � ABG must be
//              active
//          "ar" = Initiate calibration gas measurement � CAL must be
//              active 
//          "as" = Go to Playback mode
//          "aza0,3,30" = fill cell using AD chanel 0 (a pressure
//              sensor) by opening valve 4, to a pressure of 30 Torr.
//              Uses a predictive fill equation. 
//          "bdfits0" = activate fit
//          "bdfits1" = deactivate fit (warning: no way to reactivate
//              it except programmatically)
//          "bc"dstring = delay for dstring seconds


Constant k_twexVerbosity = 1

Function twex_test()
	
	String saveFolder = GetDataFolder(1); SetDatafolder root:;
	MakeAndOrSetDF( "twex" );
	
	Variable err = 0;
	
	// Check local data folder and variables
	err = twex_test_DFandStructure()
	if( err != 0 )
		//report
		if( k_twexVerbosity )
			printf "In twex_test.  DFandStructure test failed, error code = %d\r", err
			return err;
		endif
	endif

	
	// check paths and control
	err = twex_test_PathsToCommand()
	if( err != 0 )
		//report
		if( k_twexVerbosity )
			printf "In twex_test.  PathsToCommand test failed, error code = %d\r", err
			return err;
		endif
	endif

	// Check local data folder and variables
	err = twex_GetAckStates()
	if( err != 0 )
		//report
		if( k_twexVerbosity )
			printf "In twex_test.  GetACKStates failed, error code = %d\r", err
			return err;
		endif
	endif
	
	err = twex_testWrite()
	if(err == -1)
		// report
		if(k_twexVerbosity)
			printf "in twex_test. Could not write file to specified directory, error code = %d\r", err
			return err
		endif
	endif
	setdatafolder saveFolder
		
End
Function twex_testWrite()
	
	
		
	Variable idex, count;
	String this_, wStr;
	
	String saveFolder = GetDataFolder(1); SetDatafolder root:;
	MakeAndOrSetDF( "twex" );
	// use root:twex:re_init_all_vars = 1 // to manually force a reinit of everything
	NVAR/Z re_init_all_vars
	if( NVAR_Exists( re_init_all_vars )!= 1 )
		Variable/G re_init_all_vars = 0;
		NVAR re_init_all_vars
	endif
	
	Wave/Z/T tw_mat = twex_ControlMatrix;		
	string errStr = ""
	variable err=0
	variable i
	for(i=0;i<4;i+=1)
		if(stringmatch(tw_mat[i][3], "0"))
			err = twex_sendCommand(i,"testWrite")
			if(err != 1)
				errStr += "could not write file to"+tw_mat[i][2]+"\t"
				tw_mat[i][3] = num2str(-1)
			endif
		endif
	endfor
	print errStr
	return err

End
Function twex_test_DFandStructure()
	Variable err = 0;
	
	Variable idex, count;
	String this_, wStr;
	
	String saveFolder = GetDataFolder(1); SetDatafolder root:;
	MakeAndOrSetDF( "twex" );
	// use root:twex:re_init_all_vars = 1 // to manually force a reinit of everything
	NVAR/Z re_init_all_vars
	if( NVAR_Exists( re_init_all_vars )!= 1 )
		Variable/G re_init_all_vars = 0;
		NVAR re_init_all_vars
	endif
	
	Wave/Z/T tw_mat = twex_ControlMatrix;		
	if( (WaveExists( tw_mat )!= 1) | (re_init_all_vars) )
		Make/T/N=(4,6) twex_ControlMatrix
		Wave/T tw_mat = twex_ControlMatrix
		SetDimLabel 1,0, $"ChannelActive", tw_mat
		SetDimLabel 1,1, $"InstrumentName", tw_mat
		SetDimLabel 1,2, $"ComputerPath", tw_mat
		SetDimLabel 1,3, $"PathStatus", tw_mat
		SetDimLabel 1,4, $"cmdOutWave", tw_mat		
		SetDimLabel 1,5, $"ackBackWave", tw_mat
		
		tw_mat[0][0] = "n";	tw_mat[0][1] = "tdla";	tw_mat[0][2] = "q:tdlwintel:commands"; 	tw_mat[0][3] = "-1"; tw_mat[0][4] = "tdla_cmdque"; tw_mat[0][5] = "tdla_ackback";
		tw_mat[1][0] = "n";	tw_mat[1][1] = "tdlb";	tw_mat[1][2] = "v:tdlwintel:commands"; 	tw_mat[1][3] = "-1"; tw_mat[1][4] = "tdlb_cmdque"; tw_mat[1][5] = "tdlb_ackback";
		tw_mat[2][0] = "n";	tw_mat[2][1] = "tdlc";	tw_mat[2][2] = "w:tdlwintel:commands"; 	tw_mat[2][3] = "-1"; tw_mat[2][4] = "tdlc_cmdque"; tw_mat[2][5] = "tdlc_ackback";
		tw_mat[3][0] = "n";	tw_mat[3][1] = "tdld";	tw_mat[3][2] = "y:tdlwintel:commands"; 	tw_mat[3][3] = "-1"; tw_mat[3][4] = "tdld_cmdque"; tw_mat[3][5] = "tdld_ackback";
		
	endif
	
	NVAR/Z IndexOfTDLRunningZeroValve = root:twex:indexOfTDLRunningZeroValve;
	if(!NVAR_exists(IndexOfTDLRunningZeroValve))
		Variable/G root:twex:IndexOfTDLRunningZeroValve
		NVAR IndexOfTDLRunningZeroValve =root:twex:indexOfTDLRunningZeroValve;
		IndexOfTDLRunningZeroValve = 0
	endif
	
	count = DimSize( tw_mat, 0 )
	for( idex = 0; idex < count; idex += 1 )
		this_ = tw_mat[idex][4]
		Wave/Z cmdque = $this_ 
		if( WaveExists( cmdque ) != 1 )
			Make/T/O/N=0 $this_
			Wave cmdque = $this_
		endif
	endfor

	for( idex = 0; idex < count; idex += 1 )
		this_ = tw_mat[idex][5]
		Wave/Z ackback = $this_ 
		if( WaveExists( ackback ) != 1 )
			Make/T/O/N=0 $this_
			Wave ackback = $this_
		endif
	endfor


	SetDataFolder $saveFolder
	
	return err;
End
Function twex_write_configuration()


End
Function twex_test_PathsToCommand()
	Variable err = 0;

	Variable idex, count, pathok;
	String this_
	
	Wave/Z/T tw_mat = twex_ControlMatrix;		
	if( WaveExists( tw_mat ) != 1 )
		return 2;
	endif
	
	count = DimSize( tw_mat, 0 )
	for( idex = 0; idex < count; idex += 1 )
		if( cmpstr( upperstr(tw_mat[idex][0]), "Y" ) == 0 )
			this_ = tw_mat[idex][2]
			// quickly test this path
			NewPath/O/Z/Q twexPath, this_
			tw_mat[idex][3] = num2str( V_Flag )
		else
			tw_mat[idex][3] = "-1";
		
		endif
	endfor
	KillPath/Z twexPath
	
	return err;
End

Function twex_GetAckStates()
	Variable err = 0;
	
	// this will be supported in the future.  Dave has semi-disbanded it as abeing necessary. 
	
	return err;
End

// This function writes a command to ComQue.xyz 
// index corresponds to the line of the instrument 
// indicated in twex_controlMatrix 
// to change the command, open the wave labeled tdla_cmdque, for example.
// 
Function twex_WriteFile( index )
	Variable index;
	
	Wave/T tw_mat = root:twex:twex_ControlMatrix;
	string path = tw_mat[index][2];
	string quewStr = tw_mat[index][4];
	Wave/Z/T que_w = $("root:twex:"+quewStr);
		
	NewPath/O/Q tempPath, path
	PathInfo tempPath
	
	if( WaveExists( que_w ) && V_flag ) // both wave to write and path exist.
		WriteTextWave2File( que_w, path, "comque.xyz" )
	endif
End

// Here, you can use a single line command, as a string and send it.
// index is the instrument line in twex_controlMatrix
// que is the string, e.g. "ano1" to open valve 2.

Function twex_sendCommand( index, que)
	Variable index;
	string que
	variable err=0
	
	Wave/T tw_mat = root:twex:twex_ControlMatrix;
	string path = tw_mat[index][2];
	string quewStr = tw_mat[index][4];
	Make/N=1/T/O root:twex:temp_que
	Wave/T temp_que  = root:twex:temp_que
		
	temp_que[0] = que
	
	NewPath/O/Q tempPath, path
	PathInfo tempPath
	
	if(  V_flag ) // both wave to write and path exist.
		err = WriteTextWave2File( temp_que, path, "comque.xyz" )
	else
		print "path does not exist", path
		//	err=-1
	endif
	
	if(err!=1)
		print "did not successfully write file. Check permissions"
		err=-1
	endif
	return err
	
	//	killwaves/z temp_que
End


End

// You can change the requested instrument ID by changing the value
// of the NVAR in the twex folder, called IndexOfTDLRunningZeroValve

Function twex_ZeroValve( state )
	Variable state
	
	Variable err = twex_test_DFandStructure()
	// convention says TDLA = CO/N2O, thus here INDEX=0	
	NVAR/Z IndexOfTDLRunningZeroValve= root:twex:indexOfTDLRunningZeroValve;
	if(!NVAR_exists(IndexOfTDLRunningZeroValve))
		Variable/G root:twex:IndexOfTDLRunningZeroValve
		NVAR IndexOfTDLRunningZeroValve =root:twex:indexOfTDLRunningZeroValve;
		IndexOfTDLRunningZeroValve = 0
	endif
	
	if( !err )
		Wave/T tw_mat = root:twex:twex_ControlMatrix;
		string quewStr = tw_mat[IndexOfTDLRunningZeroValve][4];
		Wave/Z/T que_w = $("root:twex:"+quewStr);
		if( WaveExists( que_w ) )
		
			switch (state)
				case 0:
					Redimension/N=1 que_w
					que_w[0] = "5,NAK,anc1"
					break;
				case 1:
					Redimension/N=1 que_w
					que_w[0] = "5,NAK,ano1";
					break;
			endswitch
			twex_WriteFile( IndexOfTDLRunningZeroValve )	
		endif
		
	else
		// print already occurred when err generated
	endif
	
End

Function TWEX_UZA_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			if( cmpstr( ba.ctrlName, "COMQ_OpenZero" ) == 0 )
				twex_ZeroValve( 1 )
			endif
			if( cmpstr( ba.ctrlName, "COMQ_CloseZero" ) == 0 )
				twex_ZeroValve( 0 )
			endif
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function TWEX_Add_UZA_OperationButtons() 
	Button COMQ_OpenZero,pos={1,2},size={95,20},proc=TWEX_UZA_ButtonProc,title="Open UZA"
	Button COMQ_OpenZero,fSize=11,fStyle=1,fColor=(39321,39319,1)
	Button COMQ_OpenZero,valueColor=(26411,1,52428)
	Button COMQ_CloseZero,pos={102,3},size={95,20},proc=TWEX_UZA_ButtonProc,title="Close UZA"
	Button COMQ_CloseZero,fSize=11,fStyle=1,fColor=(39321,39319,1)
	Button COMQ_CloseZero,valueColor=(26411,1,52428)
EndMacro


//	---------------------------------------------------------------------
//	WintelWin_DrawAllSTRSTC()
//
//	This function attempts to automate a default graph maker for any 
// type of instrument, any type of species name.

// Becasue there are so many STC waves, it uses a default ignoreList.
// If you want to plot more of the stc waves, use your own ignore list, eg. 

//		WintelWin_DrawAllSTRSTC(ignoreList="stc_USBByte;stc_NI6024Byte;")

// if you have other waves (eg. ratio or del) that you want to plot up as well,
// you can add them as follows

//		WintelWin_DrawAllSTRSTC(extraSTRList="ratio")

// if you want to make a graph with only limited data, you can use the function
// with the onlyList option, and a special scale call. 

// 	WintelWin_DrawAllSTRSTC(onlyList="CH4;C2H6;H2O"); StackAllAxesPro(gap=2)


//	-------------------------------------------------------------------------

Function WintelWin_DrawAllSTRSTC([ignoreList,onlyList,extraSTRList])
	// function inists that caller will set approporiate datafolder

	// Default Ignore Files:
	string IgnoreList,onlyList,extrastrList
	if(paramisdefault(ignoreList))
		ignoreList="stc_StatusW;stc_Pref;stc_NI6024Byte;stc_SPEFile;stc_USBByte;stc_Range_F_2_L_1;stc_Range_F_2_L_2;stc_LW_Laser_1;stc_LW_Laser_2;stc_ConvergenceWord;stc_CV1_Volts;"
		ignoreList += "stc_AD0;stc_AD1;stc_AD2;stc_AD3;stc_AD4;stc_AD5;stc_AD6;stc_AD7;stc_AD9;stc_AD10;stc_AD11;stc_AD12;stc_AD13;stc_AD14;stc_AD15;stc_dLineW1;stc_dLineW2;stc_Zero_F_2"
	endif
	if(paramIsDefault(extrastrList))
		extrastrList=""
	endif
	
	
	///////////////////////////////
	// Window naming and creation
	///////////////////////////////
	PauseUpdate
	// some parameters	
	String thisWintelWinName = "WintelWin_AllSTRSTC";
	Variable labelPosNum = 80; 				// pick larger number to move labels to the left (vertical axes only)
	
	//	A check that it isn't alreayd made NOTE to remake you need to kill the window
	DoWindow/F $thisWintelWinName
	if( V_Flag )
		print thisWintelWinName +" graph already exists. Close or rename graph to recreate."
		print "\tTo save user changes, Click on graph, Ctrl + Y, Rename both fields, then click the WintelWin button again."
		return 0
	endif
	
	//	This makes it as a quick kill to prevent someone from believing they can cheat with 
	// window recreation macro.  This MUST be reprogramed here
	Display/K=1 as thisWintelWinName
	DoWindow/C $thisWintelWinName


	///////////////////////////////
	//	Getting lists of waves
	///////////////////////////////

	String stclist = "",strlist="",  cmd
	variable strcount, stcCount
	
	// create strList
	SVAR/Z LoadedWaveNamesSTC = root:STRPanel_Folder:LoadedWaveNamesSTC
	SVAR/Z LoadedWaveNamesSTR = root:STRPanel_Folder:LoadedWaveNamesSTR

	if(SVAR_exists(loadedWaveNamesSTR))
		strList = loadedWaveNamesSTR
		
	else // get the waves the old fashioned way
	
		Wave/Z str_source_rtime = str_source_rtime
		if( WaveExists( str_source_rtime ) )
			variable rows = numpnts( str_source_rtime );
			String rowString = ""
			sprintf rowstring "MINROWS:%d,MAXROWS:%d", rows, rows // this required for long waves where num2str does not print enough precision
			strList = WaveList( "*", ";", rowstring)
		endif
	endif		
	strList = removefromlist("str_source_rtime",strList, ";")
	strList = removeFromList(ignoreList,strList,";")
	strList += extraStrList
	strcount = ItemsInList( strList );

		
	// create stcList
	if(!paramIsDefault(onlyList))
		stcList=onlyList
		ignoreList=removeFromList(onlyList,ignoreList)
	else
		if(SVAR_exists(loadedWaveNamesSTC))
			stcList = loadedWaveNamesSTC
		else
			wave/Z stc_rtime = stc_time
			if(waveexists(stc_rtime))
				stcList=WaveList("stc*",";","")
				
			endif
		endif
	endif
	stcList = removefromlist("stc_time", stcList,";",0)
	stcList = removeFromList(ignoreList, stcList,";",0)
	stcCount = itemsinlist(stcList)

	////////////////////////////////
	//	Looping and Plotting STC files
	////////////////////////////////


	variable stcDex=0, matchDex
	string match1="",match2="", stcListLeft ="", rest="", thisName, thisMatch, matchName, stcListDup=stcList, axName, labelName
	wave/z time_w = $"stc_time"
	variable isDual = 0 
						
	if(waveexists(time_w))
	Variable dualEvidence = findListItem("stc_AD8", stcList)
	if(dualEvidence == -1)
		dualEvidence = findListItem("stc_F_1_L_2",stcList)
		if(dualEvidence == -1)
			isDual = 0
		else
			isDual = 1
		endif
	else
		isDual=1
	endif
	string overlaplist=""
	
	
	// Define matches
	String STCaxesMatch
	
	if(isDual)
		STCaxesMatch = "*Traw;*Tref;*AD8;*ChillerT;*ChillerPWM|*Valve*;*VICI_W;*VICI_2_W;*VICI_3_W;*VICI_4_W;*VICI*;*ECL*|*dTuneRate1*;*dT1*;*dTuneRate2*;*dT2*"
	else
		STCaxesMatch = "*Traw;*Tref;*ChillerT;*ChillerPWM|*Valve*;*VICI_W;*VICI_2_W;*VICI_3_W;*VICI_4_W;*VICI*;*ECL*|*dTuneRate*;*dT*"
	endif
		STCaxesMatch = STCaxesMatch + "|*pos1;*pos2;*pos3;*pos4;*pos5;*pos6;*pos_4_1;*pos_4_2;*pos_4_3;*pos_4_4;*pos_4_5;*pos_4_6;*pos_4_*"
		STCaxesMatch = STCaxesMatch + "|*X1;*X_*_1;*X2;*X_*_2;*X3;*X_*_3;*X4;*X_*_4;*X_4_*;*TimeStepRatio"
		STCaxesMatch = STCaxesMatch + "|*Fit6Pol0;*Fit6Pol1;*Fit6Pol2;*Fit6Pol3;*Fit6Pol4;*Fit6Pol5;*Fit6Pol6;"	
		STCaxesMatch = STCaxesMatch + "|*Fit5Pol0;*Fit5Pol1;*Fit5Pol2;*Fit5Pol3;*Fit5Pol4;*Fit5Pol5;*Fit5Pol6;"
		STCaxesMatch = STCaxesMatch + "|*Fit4Pol0;*Fit4Pol1;*Fit4Pol2;*Fit4Pol3;*Fit4Pol4;*Fit4Pol5;*Fit4Pol6;"
		STCaxesMatch = STCaxesMatch + "|*Fit3Pol0;*Fit3Pol1;*Fit3Pol2;*Fit3Pol3;*Fit3Pol4;*Fit3Pol5;*Fit3Pol6;"
		STCaxesMatch = STCaxesMatch + "|*Fit2Pol0;*Fit2Pol1;*Fit2Pol2;*Fit2Pol3;*Fit2Pol4;*Fit2Pol5;*Fit2Pol6;"
		STCaxesMatch = STCaxesMatch + "|*Fit1Pol0;*Fit1Pol1;*Fit1Pol2;*Fit1Pol3;*Fit1Pol4;*Fit1Pol5;*Fit1Pol6;"
		STCaxesMatch = STCaxesMatch + "|*Range_F_1_L_1;*Range_F_1_L_2;*_Zero_F_1"
			
	// first let's do named list of matching waves. 
	stcListDup = stcList
	matchdex = 0; variable querydex=0
	for(matchdex=0;matchdex<itemsinlist(stcaxesmatch,"|");matchdex+=1)
		string matches = stringfromlist(matchdex, stcaxesmatch, "|")
		
		String success = zSTR_plotMatchList(time_w, matches, stcListDup,isDual=isDual)
		if(itemsinlist(success)>0)
			stcListDup = removefromlist(success, stcListDup)
			success = replacestring(";",success,",")
			success = replacestring("stc_",success,"")
			success = replacestring(",",success,"_ax,")
			overlapList += replacestring(";",success, ",") + ";"
		endif
	endfor
	
	
	// Then let's plot all the numbered entries. 
	variable count = 0

	do
		thisName = stringFromList(0,stcListDup)
		wave w = $thisName
		
		if(waveexists(w))
					
			// Get Axis name and label
			axName = replacestring ("stc_",thisName,"") + "_ax"
			labelName = WintelWin_returnSTCLabel(thisName,isdual=isdual)
		
			//	Here we match Laser 1 and Laser 2 parameters for right and left axes				
			if(stringmatch(thisName,"*1"))
				match1+= axName+";"
				stcListDup= removeFromList(thisName, stcListDup)
				
				AppendToGraph/L=$axName w vs time_w; Label $axName LabelName;ModifyGraph lblPos($axName) = labelPosNum;
				
				matchName = thisName[0,strlen(thisName)-2] + "2"
				matchDex = whichListItem(matchName, stcListDup)
				if(matchDex>=0) // then found a match

					thisMatch=stringFromList(matchDex,stcListDup)	
					wave w = $thisMatch
					axName = replacestring ("stc_",thisMatch,"") + "_ax"
					labelName = WintelWin_returnSTCLabel(thisMatch,isdual=isdual)
					overlapList+= replacestring("stc_",thisName,"")+"_ax" + "," + axName
					match2+= axName+";"
					stcListDup= removeFromList(thisMatch,stcListDup)
					AppendToGraph/R=$axName w vs time_w; Label $axName LabelName;ModifyGraph lblPos($axName) = labelPosNum;
					
					matchName = thisName[0,strlen(thisName)-2] + "3"
					matchDex = whichListItem(matchName, stcListDup)
					if(matchDex>=0) // then found a match

						thisMatch=stringFromList(matchDex,stcListDup)	
						wave w = $thisMatch
						axName = replacestring ("stc_",thisMatch,"") + "_ax"
						labelName = WintelWin_returnSTCLabel(thisMatch,isdual=isdual)
						overlapList += "," + axName
						match1+=axName
						stcListDup= removeFromList(thisMatch,stcListDup)
						AppendToGraph/L=$axName w vs time_w; Label $axName LabelName;ModifyGraph lblPos($axName) = labelPosNum;
					
						
						matchName = thisName[0,strlen(thisName)-2] + "4"
						matchDex = whichListItem(matchName, stcListDup)
						if(matchDex>=0) // then found a match
		
							thisMatch=stringFromList(matchDex,stcListDup)	
							wave w = $thisMatch
							axName = replacestring ("stc_",thisMatch,"") + "_ax"
							labelName = WintelWin_returnSTCLabel(thisMatch,isdual=isdual)
							overlapList += "," + axName
							match1+=axName
							stcListDup= removeFromList(thisMatch,stcListDup)
							AppendToGraph/R=$axName w vs time_w; Label $axName LabelName;ModifyGraph lblPos($axName) = labelPosNum;
							
						endif // end match 4
					endif // end match 3
					overlapList += ";"
				endif // endmatch2
			else // endMatch1
				stcListLeft += thisName + ";"
				stcListDup= removeFromList(thisName, stcListDup)
			endif // endMatch 1
		endif // end waveexists
	while(itemsinlist(stcListDup) > 0)

		

	stcListDup = stcListLeft
	// now let's do the rest
	do
		thisName = stringFromList(0,stcListDup)
		axName = replacestring ("stc_",thisName,"") + "_ax"
		labelName = WintelWin_returnSTCLabel(thisName,isdual=isdual)
		wave w = $thisName
		
		if(waveexists(w))
			stcListDup= removeFromList(thisName,stcListDup)
			AppendToGraph/L=$axName w vs time_w; 
			Label $axName LabelName;ModifyGraph lblPos($axName) = labelPosNum;
		endif					
	
	while(itemsinlist(stcListDup)>0)
					
	if(stringmatch(stclist,""))
		print "No STC waves were found to plot. Load some data or try changing the destination data folder."
	endif
	
	
	// Scale Laser 1 and Laser 2, bottom half of graph
	variable half = 50
	if(itemsinlist(stcList) == 0)
		half = 0
	elseif(itemsinlist(stcList)>40)
		half = 70
	elseif(itemsinlist(stcList)>20)
		half = 60
	endif
	
	//axList=match1+match2
	
	StackAllAxesPro(startPercent=0, gap=0.5, stopPercent=half-0.5, leftAndRight=1,overlapList=overlapList)
	RainbowColors( thisWintelWinName ,colorTable="web216");
	
	endif // end check if there exist STC data.

	////////////////////////////////
	//	Looping and Plotting STR files
	////////////////////////////////	
	match1=""
	wave/z time_w = $"str_source_rtime"

		
	variable strdex=0
	String AxNames = ""
	Variable AxCount = 0
	do
		thisName = stringFromList(0,stRlist)
		wave w = $thisName

		if(waveexists(w))
			strdex+=1	
			// Get Axis name and label
			string specName = replacestring ("str_",thisName,"")
			string letter = stringFromList(1,specName,"_")

			// here we color known chemical names somewhat consistently. 
			variable r=WintelWin_returnRGB(specName,"R"), g=WintelWin_returnRGB(specName,"G"), b=WintelWin_returnRGB(specName,"B") 
				
			specName = stringFromList(0, specName, "_")

			axName = specName + "_ax"
			Variable axExists = whichListItem(axName, axNames)
			if(axExists < 0)
			// then a new axis
				AxCount += 1
				AxNames += axName + ";"
			endif
			
			variable extra = whichListItem(thisName,extraStrList)
				
			// only label as ppb waves that we have loaded (other extra waves have unknown units)
			if(extra<0)
				labelName = specName+"\r(ppb)"
			else 
				labelName = specName
			endif
				
			strList= removeFromList(thisName, strList)

			// Draw the trace.
				
			if(mod(axCount,2)==0)//even
				AppendToGraph/R=$axName /C=(r,g,b) w vs time_w; 
			else
				AppendToGraph/L=$axName /C=(r,g,b) w vs time_w; 
			endif
			//				ModifyGraph mirror($axName)=1
			if(stringmatch(letter,"")||stringmatch(letter,"conc"))
				match1 += axName+";"

				Label $axName LabelName; ModifyGraph lblPos($axName) = labelPosNum;
				ModifyGraph axRGB($axName)=(r,g,b),tlblRGB($axName)=(r,g,b),  alblRGB($axName)=(r,g,b)
			endif
			
		else
			strList = removeFromList(thisName,strList)
		endif
	while(itemsInList(strList)>0)

		
	if(stringmatch(match1,"") && stcCount==0)
		print "No STR or STC waves were found to plot. Load some data or try changing the destination data folder."
		KillWindow WintelWin_allSTRSTC
		return -1
	endif		
	


	StackAllAxesPro(axList=match1, startPercent=half+0.5, gap=1, leftAndRight=1)
	
	// stylings to promote standards
	ModifyGraph freePos = 0
	ModifyGraph lblMargin=10  // labels relative to window prevent them from overlapping numbers. 

	ModifyGraph tick=2
	ModifyGraph tick(bottom)=0
	ModifyGraph axisOnTop=1
	ModifyGraph mirror(bottom)=1

	ModifyGraph gfSize=10
	ModifyGraph nticks=3
	ModifyGraph nticks(bottom)=5
	ModifyGraph dateInfo(bottom)={0,1,0}

	fixAxisOverlap(gap=8,shrinkx=1)
	Label bottom "Time"
	ResumeUpdate
	print "WintelWin_DrawAllSTRSTC()"
	doupdate
	sprintf cmd, "HandyGraphButtons_v2();"
	Execute cmd

End

Function /S zSTR_plotMatchList(time_w, matchList, bigList,[isDual])
	wave time_w
	string matchList, bigList
	variable isDual
	if(paramisdefault(isDual))
		isDual = -1
	endif
	
	
	String thisQuery, thisComp, thisMatch, returnMatches="", labelName, axName
	variable i,j,matchdex=-1
	for(i=0;i<itemsinlist(matchList);i+=1)
		thisQuery = stringfromlist(i, matchList)
		
		j=0
		thisMatch=""
		do
			thisComp = stringfromlist(j,bigList)
			if(stringmatch(thisComp, thisQuery))
				matchdex +=1
				thisMatch=thisComp
				returnMatches+= thisMatch+";"
				bigList=removefromlist(thisMatch, bigList)
				wave w=$thisMatch
				
				axName = replacestring("stc_",thisMatch,"") + "_ax"
				labelName = WintelWin_returnSTCLabel(thisMatch, isDual = isDual)
				
				wavestats/Q w
				if((V_avg == V_min && V_avg == V_max) || V_numNans == numpnts(w))
					// skip plotting
				else
				
					variable evenodd = mod(matchdex,2)
					if(mod(matchDex,2)!=0) // then Odd
						Appendtograph /R=$axName w vs time_w
					else // then even
						Appendtograph /L=$axName w vs time_w
					endif
					label $axName LabelName;
					ModifyGraph lblPos($axName)=80
				endif
			endif
			j+=1
		while(j<itemsinlist(bigList) && strlen(thisMatch)==0)
	endfor
	return ReturnMatches
	
End


Function WintelWin_DrawPresTempPosRange1()
	variable laserNumber
	// function inists that caller will set approporiate datafolder

	// some parameters	
	String thisWintelWinName = "WintelWin_PTPosRange";
	Variable param_positionNumber = 1; 		// set to differnet speices IF .stc has it!
	Variable param_LaserRangeNumber = 1; 	// set to differnet speices IF .stc has it!
	Variable labelPosNum = 55; 				// pick larger number to move labels to the left (vertical axes only)
	
	//	A check that it isn't alreayd made NOTE to remake you need to kill the window
	DoWindow $thisWintelWinName
	if( V_Flag )
		return 0
	endif
	
	//	This makes it as a quick kill to prevent someone from believing they can cheat with 
	// window recreation macro.  This MUST be reprogramed here
	Display/K=1 as thisWintelWinName
	DoWindow/C $thisWintelWinName


	String list = "", aWaveNameStr, this_, label_, strip_stc, axName, cmd
	list = list + "stc_Praw;stc_Traw;"
	sprintf aWaveNameStr, "stc_pos%d;", param_positionNumber
	list = list + aWaveNameStr
	sprintf aWaveNameStr, "stc_Range_F_1_L_%d;", param_LaserRangeNumber
	list = list + aWaveNameStr
	
	String labels = "P(Torr);T(K);Pos(chan);Range(mV);"
	
	Variable idex, count = ItemsInList( list );
	Wave/Z time_w = stc_time;
	if( WaveExists( time_w ) != 1 )
		print "not able to reference stc_time."; return -1;
	endif
	
	for( idex = 0; idex < count; idex += 1 )
		
		this_ = StringFromLIst( idex, list );
		label_ = StringFromList( idex, labels );
		
		strip_stc = this_[strlen("stc_"), strlen(this_) - 1];
		axName = strip_stc + "_ax";
		Wave/Z w = $this_
		if( WaveExistS( w ) )
			AppendToGraph/L=$axName w vs time_w
			ModifyGraph freePos( $axName ) = {0, bottom }
			Label $axName label_; ModifyGraph lblPos( $axName ) = labelPosNum;
			
		else
			printf "Warning, unable to reference %s\r", this_
		endif
	endfor
	// stylings to promote standards
	ModifyGraph tick=2,mirror=1
	ModifyGraph dateInfo(bottom)={0,1,0}
	
	PrimaryColors( thisWintelWinName );
	StackAllAxes( thisWintelWinName, 0,0);
	sprintf cmd, "HandyGraphButtons();"
	print cmd
	Execute cmd

End
	

Function/S WintelWin_returnSTClabel(thisWaveName,[isdual])
	string thisWaveName
	variable isdual
	if(paramisdefault(isdual))
		isdual = -1
	endif
	String name = ""
	string laser = thisWaveName[strLen(thisWaveName)-1]
	if(stringmatch(thisWaveName, "*AD8"))
		name = "Ambient\rTemp \r(K)"
	elseif(stringmatch(thisWaveName, "*AD*"))	// default just write name
		name = "A/D "+laser
	elseif(stringmatch(thisWaveName, "*NI6024*"))
		name = "NI6024 byte"
	elseif(stringmatch(thisWaveName, "*Pos_4_1*"))
		name = "Peak\rPos. 1\rField 4\r(ch.)"
	elseif(stringmatch(thisWaveName, "*Pos_4_2*"))
		name = "Peak\rPos. 2\rField 4\r(ch.)"
	elseif(stringmatch(thisWaveName, "*Pos_4_3*"))
		name = "Peak\rPos. 3\rField 4\r(ch.)"
	elseif(stringmatch(thisWaveName, "*Pos_4_4*"))
		name = "Peak\rPos. 4\rField 4\r(ch.)"
	elseif(stringmatch(thisWaveName, "*Pos_4_5*"))
		name = "Peak\rPos. 5\rField 4\r(ch.)"
	elseif(stringmatch(thisWaveName, "*Pos_4_6*"))
		name = "Peak\rPos. 6\rField 4\r(ch.)"
	elseif(stringmatch(thisWaveName, "*pos*"))
		name = "Peak\rPos.\rSpec "+laser+"\r(ch.)"
	elseif(stringmatch(thisWaveName, "*Praw*"))
		name = "Sample \rPress\r(Torr)"
	elseif(stringmatch(thisWaveName, "*Range*"))
		name = "Laser "+laser+"\rRange\r(mV)"
	elseif(stringmatch(thisWaveName, "*SPEFile*"))
		name = "SPE file"
	elseif(stringmatch(thisWaveName, "*StatusW*"))
		name = "Valve\r state"
	elseif(stringmatch(thisWaveName, "*Traw*"))
		name = "Sample\rTemp\r(K)"
	elseif(stringmatch(thisWaveName, "*dTuneRate*"))
		name = "\\F'symbol'D\\F]0 Tune\rRate" + laser
	elseif(stringmatch(thisWaveName, "*_dT*"))
		name = "FLK \\F'symbol'D\\F]0\rFit "+laser+"\r(ch.)"
	elseif(stringmatch(thisWaveName, "*Tref"))
		if(isDual==1)
			name = "Water\rTemp \r(K)"
		elseif(isDual==0)
			name = "Ambient\rTemp \r(K)"
		else
			name = "Tref\r(K)"
		endif
	elseif(stringmatch(thisWaveName, "*T_Laser*"))
		if(igorVersion() >= 7||stringmatch(igorInfo(2),"Windows") )
			name = "Laser "+laser+"\rTemp\r("+num2char(176)+"C)"
		else // old Mac igor.
			name = "Laser "+laser+"\rTemp\r("+num2char(-95)+"C)"
		endif
	elseif(stringmatch(thisWaveName, "*V_Laser*"))
		name = "Laser "+laser+"\rCurrent\r(mA)"
	elseif(stringmatch(thisWaveName, "*USBbyte*"))
		name ="USB byte"
	elseif(stringmatch(thisWaveName, "*VICI_W"))
		name = "VICI 1\rvalve\rstate"
	elseif(stringmatch(thisWaveName, "*VICI_2_W"))
		name = "VICI 2\rvalve\rstate"
	elseif(stringmatch(thisWaveName, "*VICI_3_W"))
		name = "VICI 3\rvalve\rstate"
	elseif(stringmatch(thisWaveName, "*VICI_4_W"))
		name = "VICI 4\rvalve\rstate"
	elseif(stringmatch(thisWaveName, "*Zero_F_*"))
		name = "Laser "+laser+"\rZero\rLight\rLevel"
	elseif(stringmatch(thisWaveName,"*chillerT*"))
		name = "Chiller\rTemp"
	elseif(stringmatch(thisWaveName,"*valveW*"))
		name = "Valve\rStates"	
	elseif(stringmatch(thisWaveName, "*_X_4_1"))
		name = "\\F'symbol'c\\F]0\S2\M\rField 4"
	elseif(stringmatch(thisWaveName, "*_X*"))
		name = "\\F'symbol'c\\F]0\S2\M\rFit. "+laser
	elseif(stringmatch(thisWaveName,"*ECL*Index*"))
		name = "ECL\rIndex"
	elseif(stringmatch(thisWaveName,"*ChillerPWM"))
		name = "Chiller\rEffort\r(PWM)"
	else
		name = replaceString("stc_",thisWaveName,"")
		name = replaceString("_",name," ")
	endif
	return name
End

// This function attempts a semi-consistent color coding of common chemicals. 
// anything with an unknown color is given a random color. 
// replicates (eg. CH4_A) are given a color that is nearby but different
Function WintelWin_returnRGB(name,Which)
	string name,which
	variable R, G, B
	
	string token, dex
	token = stringFromList(0,name,"_")
	dex = stringFromList (1,name,"_")

	StrSwitch (token)
		case "C2H6":
			R=255; 	G=0; 	B=255;
			break
		case "CH4":
			R=128; 	G=128; 	B=0;
			break
		case "i12CH4":
			R=128; 	G=128; 	B=0;
			break
		case "CH4i211":
			R=128; 	G=128; 	B=0;
			break
		case "i13CH4":
			R=100; 	G=149; 	B=237;
			break
		case "CH4i311":
			R=100; 	G=149; 	B=237;
			break
		case "CH3D":
			R=189; G=50; B=227
			break
		case "CH4i212":
			R=189; G=50; B=227
			break
		case "CO":
			R=0; 	G=0; 	B=0;
			break
		case "N2O":
			R=0; 	G=128; 	B=0;
			break
		case "i446":
			R=255;	G=85;	B=0;
			break
		case "N2Oi446":
			R=255;	G=85;	B=0;
			break
		case "i456":
			R=255;	G=170;	B=0;
			break
		case "N2Oi456":
			R=255;	G=170;	B=0;
			break
		case "i546":
			R=144;	G=57;	B=230;
			break
		case "N2Oi546":
			R=144;	G=57;	B=230;
			break
		case "i448":
			R=0;	G=0;	B=0;
			break
		case "N2Oi448":
			R=0;	G=0;	B=0;
			break
		case "SO2":
			R=255; 	G=165; 	B=0;
			break
		case "COS":
			R=227; G=192; B=50;
			break
		case "OCS":
			R=227; G=192; B=50;
			break
		case "CO2":
			R=255; 	G=0; 	B=0;
			break
		case "i626":
			R=255; 	G=0; 	B=0;
			break
		case "CO2i626":
			R=255; 	G=0; 	B=0;
			break
		case "C2H2":
			R=102; 	G=0; 	B=102;
			break
		case "H2O":
			R=102; 	G=178; 	B=255;
			break
		case "RH":
			R=102; 	G=178; 	B=255;
			break
		case "i161":
			R=102; 	G=178; 	B=255;
			break
		case "C2H4":
			R=173;	G=255;	B=47;
			break		
		case "CH3OH":
			R=192;	G=192;	B=192;
			break
		case "NOx":
			R=255;	G=0;	B=255;
			break
		case "NOy":
			R=255;	G=0;	B=255;
			break
		case "NO":
			R=0;	G=204;	B=0;
			break	
		case "HCHO":
			R=192;	G=192;	B=192;
			break
		case "H2CO":
			R=192;	G=192;	B=192;
			break
		case "Air":
			R=0;	G=0;	B=0;
			break
		case "Air-":
			R=0;	G=0;	B=0;
			break
		case "Air (-)":
			R=0;	G=0;	B=0;
			break
		case "Air+":
			R=0;	G=0;	B=0;
			break
		case "_Air_":
			R=0;	G=0;	B=0;
			break
		case "none":
			R=0;	G=0;	B=0;
			break
		case "_none_":
			R=242;	G=242;	B=242;
			break
			
		default:
			// thing is, we want "reproducible" random numbers for H17...
			variable i
			variable seed = 0
			
			// This is just some math to turn a string into an integer.
			// I use both sum and multiplication for odd/even chars
			// in order to differentiate between things like i668 and i686
			// i866 and i668 will give same result, but those are not (i think)
			// in hitran
			for(i=0;i<strlen(token);i+=2)
				seed += char2num(token[i])
			endfor
			for(i=1;i<strlen(token);i+=2)
				seed *= char2num(token[i])
			endfor
			
			// integer needs to be between (0,1]
			if(seed > 1)
				do
					seed /=10
				while(seed > 1)
			endif
			
			setRandomSeed seed
			R=abs(enoise(255)); G=abs(enoise(255)); B=abs(enoise(255));
			break
	endswitch
	
	// assign a "dex" to vary the base color
	strSwitch(dex)
		case "A":		
			R= R + ( 0.25 * (255-R))
			G= G + ( 0.25 * (255-G))
			B= B + ( 0.25 * (255-B))

			break
		case "B":
			R= R * 0.75
			G= G * 0.75
			B= B * 0.75
			break
		case "C":
			R= R + ( 0.5 * (255-R))
			G= G + ( 0.5 * (255-G))
			B= B + ( 0.5 * (255-B))
			break
		case "D":
			R= R * 0.5
			G= G * 0.5
			B= B * 0.5
			break
		case "E":
			R= R + ( 0.75 * (255-R))
			G= G + ( 0.75 * (255-G))
			B= B + ( 0.75 * (255-B))
			break
		case "F":
			R= R * 0.25
			G= G * 0.25
			B= B * 0.25
			break
			break
	endswitch
	
	
	if(R>225 &&B>225 &&G>225)
		R=225; G=225; B=225
	endif
	
	if(R>255)
		R=255
	elseif(R<0)
		R=0
	endif
	
	if(G>255)
		G=255
	elseif(G<0)
		G=0
	endif
	
	if(B>255)
		b=255
	elseif(B<0)
		B=0
	endif
	
	strSwitch (Which)
		case "R":
			return R*65536/256 	
		case "G":
			return G*65536/256
		case "B":
			return B*65536/256
	endswitch 
end

Function nSTR_z_ButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	SVAR msg = root:STRPanel_Folder:msg;	sprintf msg "nSTR_z_ButtonProc...%s", ba.ctrlName
	
	// Buttons Serviced by this procedure
	// nSTR2014_LoadSelectedFiles
	// nSTR2014_RefreshFilesButton
	// nSTR2014_SelectAllFiles
	// nSTR2014_SelectAllButLastFiles
	// nSTR2014_SelectPathButton
	// nSTR2014_ResetLoadHistory
	// nSTR2014_RedimWavesToZero
	// nSTR2014_UpdateWintelGraphsIPF
	// nSTR2014_ManualSort
	
	// 
	Variable hook_file_refresh = 0;
	Variable idex, count;
	String this_check, check_list
	switch( ba.eventCode )
		case 2: // mouse up
			strswitch (ba.ctrlName)
				case "nSTR2014_SelectPathButton":
					SVAR DataPathOnDisk = root:STRPanel_Folder:DataPathOnDisk;
					//  2017 - improvement to function to let user do this once
					NewPath/Z/O/Q nSTR_Path DataPathOnDisk
						
					if( V_Flag != 0 )
						// this means DataPathOnDisk does NOT exist, let us *try* some options
						// This function checks paths, sets DataPathOnDisk, and returns a string.
						// Use this function to avoid duplicate functionality and keep list of "preferred" paths in one spot
						nSTR_h_ProbeCommonPaths()
					endif

					// preset the path before we browse.
					PathInfo/S nSTR_Path
					// Browse
					NewPath/O/Q/M="Select Folder where TDLWintel .str/.stc files are located" nSTR_Path
					if( V_Flag==0)
						// this means the user did select a path
						PathInfo nSTR_Path; 	DataPathOnDisk = S_Path;	sprintf msg, "DataPathOnDisk = %s", S_Path
						KillPath nSTR_Path;
						hook_File_refresh = 1;
					else
						// this means something didn't end well
						sprintf msg, "User Cancel or other failure"
					endif
					break;
				case "nSTR2014_SelectAllButLastFiles":
					Wave FileTimeDisplay_SelWave = root:STRPanel_Folder:FileTimeDisplay_SelWave
					FileTimeDisplay_SelWave[0, numpnts( FileTimeDisplay_SelWave ) - 2 ] = 1;
					FileTimeDisplay_SelWave[numpnts( FileTimeDisplay_SelWave ) - 1 ] = 0;
					break;
				case "nSTR2014_SelectAllFiles":
					Wave FileTimeDisplay_SelWave = root:STRPanel_Folder:FileTimeDisplay_SelWave
					FileTimeDisplay_SelWave[0, numpnts( FileTimeDisplay_SelWave ) - 1 ] = 1;					
					break;
				case "nSTR2014_RefreshFilesButton":
					hook_file_refresh = 1;
					break;
				case "nSTR2014_ResetLoadHistory":
					Wave/T LoadHistory = root:STRPanel_Folder:LoadHistory
					Redimension/N=0 LoadHistory
					break;
				case "nSTR2014_ManualSortSTR":
					nSTR_q_SortSTR();
					break;
				case "nSTR2014_ManualSortSTC":
					nSTR_q_SortSTC();
					break;
				case "nSTR2014_popWintelWin":
					nSTR_popPrepWaves()
					break
				case "nSTR2014_UpdateWintelGraphsIPF":
					nSTR_j_UpdateWintelGraphsIPF();
					break;
				case "nSTR2014_DefaultPlotSTRSTC":
					String saveFolder = GetDatafolder(1)
					SVAR destDF = root:STRPanel_Folder:DestinationDataFolder
					setDatafolder root:; setdatafolder destDF
					WintelWin_DrawAllSTRSTC()
					setdatafolder saveFolder
					break;
				case "nSTR2014_RedimWavesToZero":
					nSTR_w_ResetDataWaves();
					Wave/T LoadHistory = root:STRPanel_Folder:LoadHistory
					Redimension/N=0 LoadHistory
					nSTR_g_PathOrRefresh() // this to reset the loaded tag
					break;
				case "nSTR2014_newWintelWin":
					saveFolder = GetDatafolder(1)
					SVAR destDF = root:STRPanel_Folder:DestinationDataFolder
					setDatafolder root:; setdatafolder destDF
					// test that WintelWin.ipf is loaded
					GetWindow/z $k_WintelGraphIPFFileName, file
					if(stringmatch(S_value,""))
						nSTR_d_OpenCAECWintelGraphProc()
						execute/P/Q "nSTR_newWintelWin()"
					else
						nSTR_newWintelWin()
					endif
					setdatafolder saveFolder
					break;
				case "nSTR2014_deleteWintelWin":
					nSTR_deleteWintelWin()
					break;
				case "nSTR2014_LoadSelectedFiles":
					nSTR_c_LoadSelectedFiles();
					break;
			endswitch
			nSTR_g_PathOrRefresh();
			break
		case -1: // control being killed
			break
	endswitch

	NVAR/Z modFlag = root:STRPanel_Folder:WintelGraphsIPFNeedsWrite
	NVAR/Z openFlag = root:STRPanel_Folder:WintelGraphsIPFNeedsOpen
	if( modFlag )		
		//	nSTR_d_GraphWandMod();  // this code executes randomly (when you don't click on a button) otherwise
		openFlag = 1;
		//	modFlag = 0;
	endif
	
	return 0
End

Function ECL_GetValveStatus()
	Wave status_W = statusW;
	
	Duplicate/O status_W, root:statusW_valveSet
	Variable idex
	for( idex = 0; idex < 16; idex += 1 )
		Wave dest_w = root:statusW_valveSet
		dest_w = Floor( dest_w / 2 )
	endfor
	
	
End
/// ECL_ParseAndCutIndex
/// looks at an ECL generated index wave and produces
// 	 ECL_Index<n>_StartTime
//		 ECL_Index<n>_StopTime
// Call example below splits out index 1 and 2 and generates 4 waves in two tables
// ECL_ParseAndCutIndex( 1 );ECL_ParseAndCutIndex( 2 );
//
//  ECL_ParseAndCutIndex( 1, FirstLineIsStart=1 )	// will let the first stop use the start of the time wave as the companion 'start time'

Function ECL_ParseAndCutIndex( index, [stc_time_w, stc_index_w, subfolderSuffix, tidyup, FirstLineIsStart, LastLineIsStop, SummaryTable] )
	Variable index
	Wave stc_time_w
	Wave stc_index_w
	String subfolderSuffix
	Variable tidyup
	Variable FirstLineIsStart
	Variable LastLineIsStop
	Variable SummaryTable
	
	
	
	if( ParamIsDefault( stc_time_w ) )
		Wave stc_time = root:stc_time	// a good default
	else
		Wave stc_time = stc_time_w
	endif
		
	if( ParamIsDefault( stc_index_w ) )
		Wave loc_index = root:stc_ECL_index	// a good default
	else
		Wave loc_index = stc_index_w
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
	
	String saveFolder = GetDataFolder(1);
	
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
		SetDataFolder root:; MakeAndOrSetDF( global_ECL_WorkFolder )
	endif
	
	SetDataFolder root:; MakeAndOrSetDF( global_ECL_WorkFolder )
	Variable idex, count, doTable = 0, bdex, edex;
	String destStr
	
	// make the equivalent conc
	sprintf destStr, "ECL_%d_RawIndex", index
	Duplicate/O loc_index, $destStr
	Wave dw = $destStr
	
	dw = loc_index == index ? 1 : Nan
	
	Duplicate/O dw, ECL_Temp_all, ECL_Temp_d
	ECL_Temp_all = numtype( dw ) == 0 ? 1 : 0	
	ECL_Temp_d = ECL_Temp_all 
	Differentiate/METH=1 ECL_Temp_d
	
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
	sprintf destStr, "ECL_%d_StartTime", index; Make/N=0/O/D $destStr
	Wave ECL_StartTime = $destStr
	sprintf destStr, "ECL_%d_StopTime", index; Make/N=0/O/D $destStr
	Wave ECL_StopTime = $destStr
	SetScale/P y, 0,0, "dat", ECL_StartTime, ECL_StopTime
	

	Variable startingGun = 0
	
	count = numpnts( ECL_Temp_d )
	for( idex = 0; idex < count; idex += 1 )
		if( ECL_Temp_d[ idex ] == 1 )
			AppendVal( ECL_StartTime, stc_time[ idex+1 ] )
			startingGun = 1;
		endif
		if( (ECL_Temp_d[ idex ] == -1) & startingGun )
			AppendVal( ECL_StopTime, stc_time[ idex-1 ] )
		else
			if( (startingGun == 0) & (ECL_Temp_d[ idex ] == -1) )
				// then this indicates a Stop before a Start...
				// the solutions will be to indicate the problem and skip or honor the optional argument loc_FirstLineIsStart
				if( loc_FirstLineIsStart )
					AppendVal( ECL_StartTime, stc_time[ 0 ] ); AppendVal( ECL_StopTime, stc_time[ idex-1 ] )
					startingGun = 1;
				else
					printf "While processing the time at %s an ECL-Stop was detected prior to a start.\r  Skipping this <Stop> and looking for next <Start>\r", datetime2text( stc_time[ idex - 1] )
					printf "To override, add the optional argument -> ECL_ParseAndCutIndex( 1, FirstLineIsStart=1 )\r"	
				endif		
				// ECL_ParseAndCutIndex( 1, FirstLineIsStart=1 )	// will let the first stop use the start of the time wave as the companion 'start time'
			
			endif	
		endif		
		// ModifyTable format=8,width=160;
	endfor
	if( loc_LastLineIsStop & (numpnts( ECL_StartTime ) == (numpnts( ECL_StopTime )	+ 1 ) ) )
		// there is a start without a stop & the user is invoking last line is stop
		AppendVal( ECL_StopTime, stc_time[ numpnts( stc_time) - 1 ] )
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
			//ModifyTable format(NameOfWave(delta))=7
		endif			
	endif
	
	if( numpnts( 	ECL_StartTime ) != numpnts( ECL_StopTime ) )
		printf "Warning [%s] != [%s]\r", nameofwave( ECL_StartTime ), nameofwave( ECL_StopTime )
		if( loc_tidyup == 1 )
			printf "cutting off the un-stopped start time at the end {see the tidyup=0 option to override this behavior} \r"
			Redimension/N=( numpnts( ECL_StopTime) ) ECL_StartTime, mid, delta
		else
			printf "you will need to fix before continuing workflow\r"
		endif
		return -1;
	endif
	return 0 
	
	
End
// options for Algorithm
// Altorighm = "Mean"
// Algorithm = "OrderedInterval:0.05,0.95"
//  ->> Algorithm = "TimeInterval:0.2,1.05"
// ->> Algorithm = "TimeShift:3,0"
// ->> Algorithm = "TimeShiftBothRelTi:10,60"
// ->> Algorithm = "TimeShiftBothRelTf:-30,-10"

Function ECL_ApplyIndex2XY( index, time_w, data_w, destName, [Diagnostics, Algorithm, subfolderSuffix, listCall] )
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
	Variable uval, ustd, utime
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
		return -1;
		
		
	endif
	
	// make the receptacle data
	sprintf destStr, "ECL_%d_%s_Avg", index, destName
	Make/O/N=0/D $destStr
	Wave ECL_Average = $destStr
	
	sprintf destStr, "ECL_%d_%s_Sdev", index, destName
	Make/O/N=0/D $destStr
	Wave ECL_StdDev = $destStr

	sprintf destStr, "ECL_%d_%s_TrueTime", index, destName
	Make/O/N=0/D $destStr
	Wave ECL_TrueTime = $destStr
	//	
	//	if( miniT )
	//		sprintf destStr, "tECL_%d_%s_val", index, destName
	//		Make/O/N=0/D $destStr
	//		Wave tECL_val = $destStr
	//
	//		sprintf destStr, "tECL_%d_%s_time", index, destName
	//		Make/O/N=0/D $destStr
	//		Wave tECL_time = $destStr
	//	endif
	//	
	KillWaves/Z eclxy_diag_data, eclxy_diag_time
	Make/D/O/N=0 eclxy_diag_data, eclxy_diag_time
	count = numpnts( ECL_StartTime )
	for( idex = 0; idex < count; idex += 1 )
		switch ( algorithm_switch )
			
				//this is the timeShift algorithm
			case 4:
				bdex = BinarySearch( time_w, ECL_StartTime[ idex ] + lowF )
				edex = BinarySearch( time_w, ECL_StopTime[ idex ] + hiF )
			
				WaveStats/Q /R=[bdex, edex] data_w
				uval = v_avg;	ustd = v_sdev;		
				WaveStats/Q /R=[bdex, edex] time_w
				utime = v_avg;	
								
				Duplicate/O/R=[ bdex, edex ] data_w, seg_eclxy_diag_data;		Duplicate/O/R=[ bdex, edex ] time_w, seg_eclxy_diag_time
				Concatenate/NP "seg_eclxy_diag_data;", eclxy_diag_data	;				Concatenate/NP "seg_eclxy_diag_time;", eclxy_diag_time		
	
				break;
				//this is the TimeShiftBothRelTf algorithm
			case 5:
				bdex = BinarySearch( time_w, ECL_StopTime[ idex ] + lowF )
				edex = BinarySearch( time_w, ECL_StopTime[ idex ] + hiF )
			
				WaveStats/Q /R=[bdex, edex] data_w
				uval = v_avg;	ustd = v_sdev;		
				WaveStats/Q /R=[bdex, edex] time_w
				utime = v_avg;	
								
				Duplicate/O/R=[ bdex, edex ] data_w, seg_eclxy_diag_data;		Duplicate/O/R=[ bdex, edex ] time_w, seg_eclxy_diag_time
				Concatenate/NP "seg_eclxy_diag_data;", eclxy_diag_data	;				Concatenate/NP "seg_eclxy_diag_time;", eclxy_diag_time		
	
				break;
				//this is the TimeShiftBothRelTi algorithm
			case 6:
				bdex = BinarySearch( time_w, ECL_StartTime[ idex ] + lowF )
				edex = BinarySearch( time_w, ECL_StartTime[ idex ] + hiF )
			
				WaveStats/Q /R=[bdex, edex] data_w
				uval = v_avg;	ustd = v_sdev;		
				WaveStats/Q /R=[bdex, edex] time_w
				utime = v_avg;	
								
				Duplicate/O/R=[ bdex, edex ] data_w, seg_eclxy_diag_data;		Duplicate/O/R=[ bdex, edex ] time_w, seg_eclxy_diag_time
				Concatenate/NP "seg_eclxy_diag_data;", eclxy_diag_data	;				Concatenate/NP "seg_eclxy_diag_time;", eclxy_diag_time		
	
				break;
			
				//this is the time fraction algorithm
			case 10:
				bdex = BinarySearch( time_w, ECL_StartTime[ idex ]  )
				edex = BinarySearch( time_w, ECL_StopTime[ idex ] )
				span = time_w[ edex ] - time_w[ bdex]
				bdex = BinarySearch( time_w, ECL_StartTime[ idex ] + span * lowF  )
				edex = BinarySearch( time_w, ECL_StartTime[ idex ] + span * hiF )
								
				WaveStats/Q /R=[bdex, edex] data_w
				uval = v_avg;	ustd = v_sdev;	
				WaveStats/Q /R=[bdex, edex] time_w
				utime = v_avg;		
				
				Duplicate/O/R=[ bdex, edex ] data_w, seg_eclxy_diag_data;		Duplicate/O/R=[ bdex, edex ] time_w, seg_eclxy_diag_time
				Concatenate/NP "seg_eclxy_diag_data;", eclxy_diag_data	;				Concatenate/NP "seg_eclxy_diag_time;", eclxy_diag_time		
	
				break;
			
				//this is the intervalling algorithm
			case 2:
				bdex0 = BinarySearch( time_w, ECL_StartTime[ idex ] )
				edex0 = BinarySearch( time_w, ECL_StopTime[ idex ] )
				Duplicate/O/R=[ bdex0, edex0 ] data_w, ecl_temp
				Duplicate/O/R=[ bdex0, edex0 ] time_w, ecl_temp_time
				Sort ecl_temp, ecl_temp, ecl_temp_time
				bdex = Ceil( numpnts( ecl_temp ) * lowF )
				edex = Floor( numpnts( ecl_temp ) * hiF )
				
				WaveStats/Q /R=[bdex, edex] ecl_temp
				uval = v_avg;	ustd = v_sdev;
				WaveStats/Q /R=[bdex, edex] ecl_temp_time
				utime = v_avg;	
				
				Duplicate/O/R=[ bdex, edex ]  ecl_temp, seg_eclxy_diag_data;		Duplicate/O/R=[bdex, edex] ecl_temp_time, seg_eclxy_diag_time
				Concatenate/NP "seg_eclxy_diag_data;", eclxy_diag_data	;				Concatenate/NP "seg_eclxy_diag_time;", eclxy_diag_time		

				break;

				//this is the mean algorithm
			case 1:
			default:
				bdex = BinarySearch( time_w, ECL_StartTime[ idex ] )
				edex = BinarySearch( time_w, ECL_StopTime[ idex ] )
				WaveStats/Q /R=[bdex, edex] data_w
				uval = v_avg;	ustd = v_sdev;
				
				WaveStats/Q /R=[bdex, edex] time_w
				utime = v_avg;	
								
				Duplicate/O/R=[ bdex, edex ] data_w, seg_eclxy_diag_data;		Duplicate/O/R=[ bdex, edex ] time_w, seg_eclxy_diag_time
				Concatenate/NP "seg_eclxy_diag_data;", eclxy_diag_data	;				Concatenate/NP "seg_eclxy_diag_time;", eclxy_diag_time		

				break;
						
		endswitch
		
		
		

		AppendVal( ECL_Average, uval )
		AppendVal( ECL_StdDev, ustd )
		AppendVal( ECL_TrueTime, utime )

		//		if( miniT )
		//			for( jdex = bdex; jdex < edex; jdex += 1 )
		//				AppendVal( tECL_time, time_w[ jdex ] );
		//				AppendVal( tECL_val, data_w[ jdex ] );
		//			endfor 
		//		endif
		
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
	return 0;
End
Function ECL_PreserveLastApply(index, destName [SendToDF, FilterMode])
	Variable index
	String destName
	String SendToDF
	Variable filterMode

	Wave/Z eclxy_diag_data
	Wave/Z eclxy_diag_time

	if( WaveExists( eclxy_diag_data ) + WaveExists( eclxy_diag_time ) != 2 )
	
	endif
	
	return 0;

End
Function ECL_ApplyIndex2List( index, time_w, data_wList, [Diagnostics, Algorithm, subFolderSuffix] )
	Variable index
	Wave time_w
	String data_wList
	Variable Diagnostics
	String Algorithm
	String subFolderSuffix
	
	
	Variable locDiagnos = -99.99;
	if( !ParamIsDefault( Diagnostics ) )
		locDiagnos = Diagnostics
	endif
	
	String locAlgo = ""
	if( !ParamIsDefault( Algorithm ) )
		locAlgo = Algorithm
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
	
	DFREF timeSourceFolder = $GetWavesDataFolder( time_w, 1 ) 
	
	String thisStr, destName, str
	Variable idex, count = ItemsInList( data_wList ), error, looplistCall = 1;
	for( idex = 0; idex < count; idex +=1 )
		if( idex == count - 1 )
			looplistCall = 0; // this is the last time thru the loop, so invoke the XY as though diagnostics should be performed
		else
			looplistCall = 1
		endif
		thisStr = StringFromList( idex, data_wList );
		Wave/SDFR=timeSourceFolder data_w = $(thisStr )
		destName = NameOfWave( data_w );	str = destName;
		if( strsearch( lowerstr( destName ), "stc_", 0 ) != -1 )
			str = RemoveFromList( "stc", lowerstr( destName ), "_" );
		endif
		
		if( StrSearch( lowerstr(str), "range", 0 ) != -1 )
			str = ReplaceString( "_", str, "" );
		endif
		if( StrSearch( lowerstr(str), "zero", 0 ) != -1 )
			str = ReplaceString( "_", str, "" );
		endif
		if( StrSearch( lowerstr(str), "laser", 0 ) != -1 )
			str = ReplaceString( "_", str, "" );
		endif
		if( StrSearch( lowerstr(str), "ecl_index", 0 ) != -1 )
			//str = ReplaceString( "_", str, "" );
		endif
		if( StrSearch( lowerstr( str ), "conver", 0 ) != -1 )
			str = "ConVWord"
		endif
		destName = str	

		if( (locDiagnos != -99.99) & (strlen( locAlgo ) != 0 ) )
			error = ECL_ApplyIndex2XY( index, time_w, data_w, destName, Diagnostics=locDiagnos, Algorithm = locAlgo, subfolderSuffix = loc_suffix, listCall = loopListCall )
		else
			if( locDiagnos != -99.99 )
				error = ECL_ApplyIndex2XY( index, time_w, data_w, destName, Diagnostics=locDiagnos, subfolderSuffix = loc_suffix, listCall = loopListCall  )
			else
				if( strlen( locAlgo ) != 0 )
					error = ECL_ApplyIndex2XY( index, time_w, data_w, destName, Algorithm = locAlgo, subfolderSuffix = loc_suffix, listCall = loopListCall  )
				else
					error = ECL_ApplyIndex2XY( index, time_w, data_w, destName,subfolderSuffix = loc_suffix, listCall = loopListCall  )
				endif
			endif	
		endif
		if( error != 0 )
			printf "aborting the remainder of the list of waves.\r"
			return -1
		endif
	endfor

	return 0;
End

Function ECL_ApplyIndex2PairForRatio( index, time_w, data_wList, [Diagnostics, Algorithm, subFolderSuffix] )
	Variable index
	Wave time_w
	String data_wList
	Variable Diagnostics
	String Algorithm
	String subFolderSuffix
	
	
	Variable locDiagnos = 1;
	if( !ParamIsDefault( Diagnostics ) )
		locDiagnos = Diagnostics
	endif
	
	String locAlgo = ""
	if( !ParamIsDefault( Algorithm ) )
		locAlgo = Algorithm
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
	
	DFREF timeSourceFolder = $GetWavesDataFolder( time_w, 1 ) 
	
	String thisStr, thisDenomStr, destName, str
	Variable idex, count = ItemsInList( data_wList ), error, looplistcall = 0;
	if( count == 1 )
		print "This function call requires at least two members because it works on the ratio";
		return -1;
	endif
	// this index starts at 1, all ratioed to the quantity at 0 !!
	for( idex = 1; idex < count; idex +=1 )
		
		thisDenomStr = StringFromList( 0, data_wList );
		thisStr = StringFromList( idex, data_wList );
		Wave/SDFR=timeSourceFolder data_w = $(thisStr )
		Wave/SDFR=timeSourceFolder denomData_w = $(thisDenomStr )
		
		sprintf str, "%sOver%s", NameOfWave(data_w), NameOfWave( denomData_w )
		str = CleanupName(str, 0);
		Duplicate/O data_w, $str;
		Wave target = $str;
		
		target = data_w / denomData_w;
		 
		destName = str;


		if( (locDiagnos != -99.99) & (strlen( locAlgo ) != 0 ) )
			error = ECL_ApplyIndex2XY( index, time_w, target, destName, Diagnostics=locDiagnos, Algorithm = locAlgo, subfolderSuffix = loc_suffix, listCall = loopListCall )
		else
			if( locDiagnos != -99.99 )
				error = ECL_ApplyIndex2XY( index, time_w, target, destName, Diagnostics=locDiagnos, subfolderSuffix = loc_suffix, listCall = loopListCall  )
			else
				if( strlen( locAlgo ) != 0 )
					error = ECL_ApplyIndex2XY( index, time_w, target, destName, Algorithm = locAlgo, subfolderSuffix = loc_suffix, listCall = loopListCall  )
				else
					error = ECL_ApplyIndex2XY( index, time_w, target, destName,subfolderSuffix = loc_suffix, listCall = loopListCall  )
				endif
			endif	
		endif
		if( error != 0 )
			printf "aborting the remainder of the list of waves.\r"
			return -1
		endif
	endfor

	return 0;
End


Function ECL_ApplyIndex2DefaultStr( index, [Diagnostics, Algorithm, subfolderSuffix ] )
	Variable index
	Variable Diagnostics
	String Algorithm
	String subFolderSuffix
	
	Wave time_w = root:str_source_rtime
	SVAR loadList = root:STRPanel_Folder:LoadedWaveNamesSTR
	String data_wList = RemoveFromList( "str_source_rtime", loadList )
		
	Variable locDiagnos = -99.99;
	if( !ParamIsDefault( Diagnostics ) )
		locDiagnos = Diagnostics
	endif
	
	String locAlgo = ""
	if( !ParamIsDefault( Algorithm ) )
		locAlgo = Algorithm
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


	if( (locDiagnos != -99.99) & (strlen( locAlgo ) != 0 ) )
		ECL_ApplyIndex2List( index, time_w, data_wList, Diagnostics=locDiagnos, Algorithm = locAlgo, subfolderSuffix = loc_suffix  )
	else
		if( locDiagnos != -99.99 )
			ECL_ApplyIndex2List( index, time_w, data_wList, Diagnostics=locDiagnos, subfolderSuffix = loc_suffix  )
		else
			if( strlen( locAlgo ) != 0 )
				ECL_ApplyIndex2List( index, time_w, data_wList, Algorithm = locAlgo, subfolderSuffix = loc_suffix  )
			else
				ECL_ApplyIndex2List( index, time_w, data_wList, subfolderSuffix = loc_suffix  )
			endif
		endif	
	endif
		


End

Function ECL_ApplyIndex2DefaultStc( index, [Diagnostics, Algorithm, subfolderSuffix] )
	Variable index
	Variable Diagnostics
	String Algorithm
	String subfolderSuffix
	
	Wave time_w = root:str_source_rtime
	SVAR loadList = root:STRPanel_Folder:LoadedWaveNamesSTC
	String full_data_wList = loadList;
	full_data_wList = RemoveFromList( "stc_time", full_data_wList )
	full_data_wList = RemoveFromList( "stc_ECL_Index", full_data_wList )
	full_data_wList = RemoveFromList( "stc_SPEFile", full_data_wList )
	full_data_wList = RemoveFromList( "stc_StatusW", full_data_wList )
	full_data_wList = RemoveFromList( "stc_USBByte", full_data_wList )
	full_data_wList = RemoveFromList( "stc_V_Laser_2", full_data_wList )
	full_data_wList = RemoveFromList( "stc_V_Laser_1", full_data_wList )
	full_data_wList = RemoveFromList( "stc_VICI_W", full_data_wList )
	full_data_wList = RemoveFromList( "stc_VICI_2_W", full_data_wList )
	full_data_wList = RemoveFromList( "stc_VICI_3_W", full_data_wList )
	full_data_wList = RemoveFromList( "stc_VICI_4_W", full_data_wList )
	full_data_wList = RemoveFromList( "stc_Zero_F_2", full_data_wList )
	full_data_wList = RemoveFromList( "stc_Zero_F_1", full_data_wList )
	full_data_wList = RemoveFromList( "stc_Range_F_2_L_2", full_data_wList )
	full_data_wList = RemoveFromList( "stc_Range_F_2_L_1", full_data_wList )
	full_data_wList = RemoveFromList( "stc_LW_Laser_2", full_data_wList )
	full_data_wList = RemoveFromList( "stc_LW_Laser_1", full_data_wList )
	full_data_wList = RemoveFromList( "stc_ConvergenceWord", full_data_wList )
	full_data_wList = RemoveFromList( "stc_X2", full_data_wList )
	full_data_wList = RemoveFromList( "stc_X1", full_data_wList )
	String data_wList = full_data_wList;
		
	Variable locDiagnos = -99.99;
	if( !ParamIsDefault( Diagnostics ) )
		locDiagnos = Diagnostics
	endif
	
	String locAlgo = ""
	if( !ParamIsDefault( Algorithm ) )
		locAlgo = Algorithm
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

	//	Variable idex, count = ItemsInList( full_data_wList )
	//	String str, dstr
	//	for( idex = 0; idex < count; idex += 1 )
	//		data_wList = data_wList + str + ";" 
	//	endfor

	if( (locDiagnos != -99.99) & (strlen( locAlgo ) != 0 ) )
		ECL_ApplyIndex2List( index, time_w, data_wList, Diagnostics=locDiagnos, Algorithm = locAlgo )
	else
		if( locDiagnos != -99.99 )
			ECL_ApplyIndex2List( index, time_w, data_wList, Diagnostics=locDiagnos )
		else
			if( strlen( locAlgo ) != 0 )
				ECL_ApplyIndex2List( index, time_w, data_wList, Algorithm = locAlgo )
			else
				ECL_ApplyIndex2List( index, time_w, data_wList )
			endif
		endif	
	endif
		


End

Function ECL_MathOp( arg1, arg1index, arg2, arg2index, operation, scalar, modifier )
	String arg1
	Variable arg1index
	String arg2
	Variable arg2index
	String operation
	Variable scalar
	String modifier
	
	String w1str, w2str, dest, clipStr
	Variable tindex
	
	Variable doClipboard = 1;
	if( strsearch( modifier, "noclip", 0 ) != -1 )
		doClipboard = 0
	endif
	
	sprintf w1str, "ECL_%d_%s_Avg", arg1index, arg1
	Wave/Z w1 = $w1str
	if( WaveExists( w1 ) != 1 )
		printf "In function ECL_MathOp, wave %s not found, aborting\r", w1str
		return -1;
	endif
	
	sprintf w2str, "ECL_%d_%s_Avg", arg2index, arg2
	Wave/Z w2 = $w2str
	if( WaveExists( w2 ) != 1 )
		printf "In function ECL_MathOp, wave %s not found, aborting\r", w2str
		return -1;
	endif	
	
	strswitch (lowerstr(operation))
		case "do-del":	
			tindex = arg2index
			ECL_MathOpDivide( w1, arg1index, w2, arg2index, modifier );
			Wave eclmo_result
			eclmo_result -= 1;
			eclmo_result *= 1000;
			
			eclmo_result *= scalar
			
			sprintf dest, "ECLDel_%s%d_o_%s%d", arg1, arg1index, arg2, arg2index
			Duplicate/O eclmo_result, $dest

			break;
		case "divide":	
		case "div":
		case "ratio":
			tindex = arg2index
			ECL_MathOpDivide( w1, arg1index, w2, arg2index, modifier );
			Wave eclmo_result
			eclmo_result *= scalar;
			sprintf dest, "ECLRat_%s%d_o_%s%d", arg1, arg1index, arg2, arg2index
			Duplicate/O eclmo_result, $dest
			break;
		case "multiply":
		case "times":
		case "product":
			tindex = arg2index
			ECL_MathOpDivide( w1, arg1index, w2, arg2index, modifier );
			Wave eclmo_result
			eclmo_result *= scalar;
			sprintf dest, "ECLProd_%s%d_t_%s%d", arg1, arg1index, arg2, arg2index
			Duplicate/O eclmo_result, $dest
			break;	
		case "subtract":
		case "minus":
		case "difference":
			tindex = arg2index
			ECL_MathOpSubtract( w1, arg1index, w2, arg2index, modifier );
			Wave eclmo_result
			eclmo_result *= scalar;
			sprintf dest, "ECLDiff_%s%d_m_%s%d", arg1, arg1index, arg2, arg2index
			Duplicate/O eclmo_result, $dest
			break;
		case "add":
		case "sum":
		case "plus":
			tindex = arg2index
			ECL_MathOpAdd( w1, arg1index, w2, arg2index, modifier );
			Wave eclmo_result
			eclmo_result *= scalar;
			sprintf dest, "ECLSum_%s%d_p_%s%d", arg1, arg1index, arg2, arg2index
			Duplicate/O eclmo_result, $dest
			break;							
	endswitch
	Wave w = $dest
	if( doClipboard )
		clipStr = GetWavesDataFolder( w, 2 );
		printf "Resultant wave = %s has been put on the clipboard\r", clipStr
		PutScrapText clipStr
	endif		
End

Function ECL_MathOpDivide( w1, w1index, w2, w2index, modifier )
	Wave w1
	Variable w1index
	Wave w2
	Variable w2index
	String modifier
	
	String timeStr
	
	sprintf timeStr, "ECL_%d_MidTime", w1index
	Wave/Z time_w1 = $timeStr
	sprintf timeStr, "ECL_%d_MidTime", w2index
	Wave/Z time_w2 = $timeStr
	
	Make/N=(numpnts( time_w1 ))/D/O eclmo_temp, eclmo_result;

	eclmo_temp = interp( time_w1[p], time_w2, w2 );
	eclmo_result = w1 / eclmo_temp;
	
End

Function ECL_MathOpMultiply( w1, w1index, w2, w2index, modifier )
	Wave w1
	Variable w1index
	Wave w2
	Variable w2index
	String modifier
	
	String timeStr
	
	sprintf timeStr, "ECL_%d_MidTime", w1index
	Wave/Z time_w1 = $timeStr
	sprintf timeStr, "ECL_%d_MidTime", w2index
	Wave/Z time_w2 = $timeStr
	
	Make/N=(numpnts( time_w1 ))/D/O eclmo_temp, eclmo_result;

	eclmo_temp = interp( time_w1[p], time_w2, w2 );
	eclmo_result = w1 * eclmo_temp;
	
End

Function ECL_MathOpSubtract( w1, w1index, w2, w2index, modifier )
	Wave w1
	Variable w1index
	Wave w2
	Variable w2index
	String modifier
	
	String timeStr
	
	sprintf timeStr, "ECL_%d_MidTime", w1index
	Wave/Z time_w1 = $timeStr
	sprintf timeStr, "ECL_%d_MidTime", w2index
	Wave/Z time_w2 = $timeStr
	
	Make/N=(numpnts( time_w1 ))/D/O eclmo_temp, eclmo_result;

	eclmo_temp = interp( time_w1[p], time_w2, w2 );
	eclmo_result = w1 - eclmo_temp;
	
End

Function ECL_MathOpAdd( w1, w1index, w2, w2index, modifier )
	Wave w1
	Variable w1index
	Wave w2
	Variable w2index
	String modifier
	
	String timeStr
	
	sprintf timeStr, "ECL_%d_MidTime", w1index
	Wave/Z time_w1 = $timeStr
	sprintf timeStr, "ECL_%d_MidTime", w2index
	Wave/Z time_w2 = $timeStr
	
	Make/N=(numpnts( time_w1 ))/D/O eclmo_temp, eclmo_result;

	eclmo_temp = interp( time_w1[p], time_w2, w2 );
	eclmo_result = w1 + eclmo_temp;
	
End

Function ECL_RelDel( minorArg, majorArg, sampleIndex, refIndex, modifier )
	String minorArg
	String majorArg
	Variable sampleIndex
	Variable refIndex
	String modifier
	
	String minorSampleStr, majorSampleStr, minorRefStr, majorRefStr, timeStr, dest, clipStr
	
	Variable doClipboard = 1;
	if( strsearch( modifier, "noclip", 0 ) != -1 )
		doClipboard = 0
	endif
	
	sprintf minorSampleStr, "ECL_%d_%s_Avg", sampleIndex, minorArg
	Wave/Z wMinorSample = $minorSampleStr
	if( WaveExists( wMinorSample ) != 1 )
		printf "In function ECL_MathOp, wave %s not found, aborting\r", minorSampleStr
		return -1;
	endif
	
	sprintf majorSampleStr, "ECL_%d_%s_Avg", sampleIndex, majorArg
	Wave/Z wMajorSample = $majorSampleStr
	if( WaveExists( wMajorSample ) != 1 )
		printf "In function ECL_MathOp, wave %s not found, aborting\r", majorSampleStr
		return -1;
	endif
	
	sprintf minorRefStr, "ECL_%d_%s_Avg", refIndex, minorArg
	Wave/Z wMinorRef = $minorRefStr
	if( WaveExists( wMinorRef ) != 1 )
		printf "In function ECL_MathOp, wave %s not found, aborting\r", minorRefStr
		return -1;
	endif
	
	sprintf majorRefStr, "ECL_%d_%s_Avg", refIndex, majorArg
	Wave/Z wMajorRef = $majorRefStr
	if( WaveExists( wMajorRef ) != 1 )
		printf "In function ECL_MathOp, wave %s not found, aborting\r", majorRefStr
		return -1;
	endif
		
	sprintf timeStr, "ECL_%d_MidTime", sampleIndex
	Wave/Z wSampleTime = $timeStr
	sprintf timeStr, "ECL_%d_MidTime", refIndex
	Wave/Z wRefTime = $timeStr
	
	Make/N=(numpnts(wSampleTime))/D/O ecl_reldel_minor_temp, ecl_reldel_major_temp, ecl_reldel_result

	ecl_reldel_minor_temp = interp( wSampleTime[p], wRefTime, wMinorRef )
	ecl_reldel_major_temp = interp( wSampleTime[p], wRefTime, wMajorRef )
	
	ecl_reldel_result = 1000*(((wMinorSample/wMajorSample)/(ecl_reldel_minor_temp/ecl_reldel_major_temp)) - 1)
				
	sprintf dest, "ECL_RelDel_%s_%s_%d_%d", minorArg, majorArg, sampleIndex, refIndex
	Duplicate/O ecl_reldel_result, $dest
	
	Wave w = $dest
	if( doClipboard )
		clipStr = GetWavesDataFolder( w, 2 );
		printf "Resultant wave = %s has been put on the clipboard\r", clipStr
		PutScrapText clipStr
	endif
	
	killwaves ecl_reldel_minor_temp, ecl_reldel_major_temp, ecl_reldel_result
	
End

// ECL_Export( index )
// This function will take waves from the current datafolder [ SetDataFolder:root:ECL_WorkFolder_A // or other suffix ]
// The function discards waves that are probably unimportant
// The options are:
//											DEFAULTS
//		DiskPath, 						<dialog box, pick a folder>
//		FileName, 						ECLXport_YYYYMMDD_HHMMSS.cvs
//		FileFormat, 						csv
//		subFolderSuffix, 				"A" or root:gs_ECL_WorkFolder
//		AddToExport, 					<none**>
//		TimeFormat, 						"american"
//		FileLineTerminator				"\r\n" // CRLF
//
//	Examples:
//		ECL_Export( 1, DiskPath = "Macintosh HD:Users:scott:Dropbox:_MyMisc:ECLFolder" )

// named tioem format types are:
// american:		"MM/DD/YYYY HH:mm:SS"
// european:		"MM/DD/YYYY HH:mm:SS"
// sortable:			"YYYY/MM/DD HH:mm:SS"
// filename:		"YYYYMMDD_HHmmSS"
// filename2y:		"YYMMDD_HHmmSS"
// dash-american:	"MM-DD-YYYY HH:mm:SS"
// dash-european:	"DD-MM-YYYY HH:mm:SS"
// dash-sortable:	"YYYY-MM-DD HH:mm:SS"
// ** AddToExport is a textwave that contains waves the default algorithm isn't finding.
//	Example, you invoke Duplicate/O ECL_1_N2O_Avg, ImportantResult
// ImportantResult = function of other inputs, but it doesn't follow ECL_<index> naming convention
// Force it into the Export like this ...
// Make/N=0/T/O myExports
// AppendString( myExports, "ImportantResults" )
// AppendString( myExports, "ECL_1_N2O_TrueTime" ) // which was 'discarded' 
// then
// ECL_Export( 1, AddToExport = myExports );
//
		
Function ECL_Export( index, [DiskPath, FileName, FileFormat, subFolderSuffix, AddToExport, TimeFormat, FileLineTerminator] )
	Variable index
	String DiskPath
	String FileName
	String FileFormat
	String subFolderSuffix
	Wave/T AddToExport
	String TimeFormat
	String FileLineTerminator
	
	
	String locFileLineTerm = "\r\n"	// CRLF Windows
	if( !ParamIsDefault( FileLineTerminator ) )
		locFileLineTerm = FileLineTerminator
	endif
	String loctimeFormat = "american"
	if( !ParamIsDefault( TimeFormat ) )
		loctimeformat = TimeFormat
	endif												
	String locDiskPath = ""
	if( !ParamIsDefault( DiskPath ) )
		locDiskPath = DiskPath
	endif		
	if( cmpstr( locDiskPath, "" ) == 0 )
		NewPath/O/Q/M="Choose directory where the export should go" dat_ExportPATH
	else
		NewPath/O/Q dat_ExportPATH  locDiskPath
	endif
	if( V_Flag != 0 )
		printf "aborted, cancelled or failed NewPath (%s) \r", locDiskPath; return -1;
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
	///////
	String locFileFormat = "csv"
	if( !ParamIsDefault( FileFormat ) )
		locFileFormat = FileFormat
	endif
	
	
	String locFileName
	sprintf locFileName "ECLXport_%s.%s", DTI_DateTime2Text( datetime, "filename" ), locFileFormat
	if( !ParamIsDefault( FileName ))
		sprintf locFileName "%s", FileName
	endif
	Variable idex, count, points, jdex, jcount
	String list = "", defilter, defilterList, rawList, candidateStr, searchStr
	
	defilterList = "StopTime;StartTime;RawIndex;TrueTime;DeltaTime;"
	Wave/Z midTime_w = $( "ECL_" + num2str( index ) + "_MidTime" )
	if( WaveExists( midTime_w ) != 1 )
		printf "Unable to reference keystone time wave, ECL_%d_midTime\r in datafolder %s.  Aborting Export\r", index, GetDataFolder(1)
		return -1
	endif
	
	points = numpnts( midTime_w )
	sprintf searchStr, "ECL_%d_*", index
	rawList = WaveList( searchStr, ";", "" )
	count = ItemsinList( rawList )
	for ( idex = 0; idex < count; idex += 1 )
		candidateStr = StringFromList( idex, rawList )
		Wave/Z w = $candidateStr
		if( WaveExists( w ) )
			if( numpnts( w ) == points )
				list = list + NameOfWave( w ) + ";"
			endif
		endif
	endfor
	
	for( idex = 0; idex < ItemsInList( list ); idex += 1 )
		candidateStr = StringFromList( idex, list )
		jcount = ItemsInList( defilterlist )
		for( jdex = 0; jdex < jcount; jdex += 1 )
			defilter = StringFromList( jdex, defilterlist )
			if( strsearch( candidateStr, defilter, 0 ) != -1 )
				list = RemoveFromList( candidateStr, list )
				idex -= 1;
			endif	
		endfor	
	endfor
	
	if( !ParamIsDefault( AddToExport ) )
		for( idex = 0; idex < numpnts( AddToExport ); idex += 1 )
			Wave/Z w = $AddToExport[idex]
			if( WaveExists( w ) )
				if( numpnts( w ) != points )
					printf "Export Warning!  The AddToExport[ %d ], %s has %d points\r", idex, NameOfWave(w), numpnts( w )
					printf "\t while key wave %s has %d points\r", NameOfWave(midTime_w), points
					printf "\t <Adding it anyway>\r"
				endif
				list = list + NameOfWave( w ) + ";"
			else
				printf "Export Warning!  The AddToExport[ %d ], %s not found, skipping\r", idex, AddToExport[ idex ];
			endif
		endfor
	endif
	
	String line, numstr
	Variable refNum

	strswitch(lowerstr(locFileFormat))
		case "csv":
	
			count = numpnts( midTime_w )
			jcount = ItemsInList( list )
			for( idex = 0; idex < count; idex += 1 )
				if( idex == 0 )
					line = ""
					for( jdex = 0; jdex < jcount; jdex += 1 )
						candidateStr = StringFromList( jdex, list )
						Wave w = $candidateStr
						line = line + NameOfWave(w) + ","	
					endfor			
					
					Open/Z/P=dat_ExportPATH/T="TEXT" refNum as locfilename  // this commands ovewrites file. use /A to append
					if(V_flag !=0)
						print "WriteTextWave2File did not have permission to write file"
						return -1
					endif
					line = line[ 0, strlen( line ) - 2 ] // trim off the comma
					fprintf refNum, "%s%s", line, locFileLineTerm
				
				endif
			
				line = ""
				for( jdex = 0; jdex < jcount; jdex += 1 )
					candidateStr = StringFromList( jdex, list )
					Wave w = $candidateStr
					if( strsearch( lowerstr( NameOfWave( w ) ), "time", 0 ) != -1 )
						sprintf numstr, "%s", DTI_DateTime2Text( w[idex], loctimeFormat )
					else
						sprintf numstr, "%f", w[idex]
					endif
					line = line + numstr + ","	
				endfor	
				line = line[ 0, strlen( line ) - 2 ] // trim off the comma
				fprintf refNum, "%s%s", line, locFileLineTerm

			endfor	
		
			Close/A
	
			break;
	endswitch
	
	print list
End

Function ECL_EZ_Calc()

End

// Options
// Options must be a proper StringByKey string
// e.g. "AXIS:Left;COLOR:Blue;MARK:18"
//
// Color_str must match one of the following...
//Red, Pink, Salmon, Wine, Orange, Yellow, Mustard, PhosGreen, Green, DarkGreen
//Cyan, Aqua, Blue, Midnight, SkyBlue, StormBlue, Purple, Violet
//Black, DarkGray/Grey, Gray/Grey, LightGray/Grey, White
Function ECL_AppendToGraph( arg, index, [AddErrorBar subfolderSuffix, options] )
	String arg
	Variable index
	Variable AddErrorBar
	String subfolderSuffix
	String options

	String saveFolder = GetDataFolder(1);
	
	Variable loc_AddErrorBar
	if( ParamIsDefault( AddErrorBar ) )
		loc_AddErrorBar = 1
	else
		loc_AddErrorBar = AddErrorBar
	endif
		
	String loc_suffix
	if( ParamIsDefault( subfolderSuffix ) )
		loc_suffix = "A"	// a good default
	else
		loc_suffix = subfolderSuffix
	endif
	
	String loc_options
	if( ParamIsDefault( options ) )
		loc_options = "AXIS:Left;COLOR:Pink;MARK:18;"	// a good default
	else
		loc_options = options
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
	sprintf global_ECL_WorkFolder, "ECL_WorkFolder_%s", loc_suffix
	SetDataFolder $( "root:" + global_ECL_WorkFolder )

	String destStr, traceName, axisStr, cmd, colorStr
	Variable markerNo
	////////////////// The time templates
	// Reference the preCut Index Start Stops
	sprintf destStr, "ECL_%d_StartTime", index; 
	Wave/Z ECL_StartTime = $destStr
	
	sprintf destStr, "ECL_%d_StopTime", index; 
	Wave/Z ECL_StopTime = $destStr
	
	sprintf destStr, "ECL_%d_MidTime", index; 
	Wave/Z ECL_MidTime = $destStr
	
	if( WaveExists( ECL_StartTime ) + WaveExists( ECL_StopTime ) != 2 )
		printf "You need to run ECL_ParseAndCutIndex function prior to using this one.\r It will make ECL_Index%s_Start/Stop Time waves\r", index
		return -1;		
	endif
	
	// identify the receptacle data and true time
	sprintf destStr, "ECL_%d_%s_Avg", index, arg
	Wave/Z ECL_Average = $destStr
	
	sprintf destStr, "ECL_%d_%s_Sdev", index, arg
	Wave/Z ECL_StdDev = $destStr

	sprintf destStr, "ECL_%d_%s_TrueTime", index, arg
	Wave/Z ECL_TrueTime = $destStr
	
	if( WaveExists( ECL_Average ) + WaveExists( ECL_StdDev )  != 2 )
		printf "You need to run ECL_ApplyIndex2XY( %d, <time_w>, <data_w>, \"%s\") first\r", index, arg
		return -1;		
	endif
	
	if( WaveExists( ECL_TrueTime ) != 1 )
		Wave ECL_TrueTime = ECL_MidTime
		print "Warning, substituting MidTime"
	endif
	
	// actually put data on the graph
	axisStr = StringByKey( "AXIS", loc_options );
	if( strlen( axisStr ) == 0 )
		axisStr = "Left"
	endif
	
	colorStr = StringByKey( "COLOR", loc_options );
	if( strlen( colorStr ) == 0 )
		colorStr = "Pink"
	endif
	
	markerNo = str2num(StringByKey( "MARK", loc_options ));
	if( numtype( markerNo ) != 0 )
		markerNo = 18
	endif
	
	sprintf cmd, "AppendToGraph/L=%s %s vs %s", axisStr, GetWavesDataFolder( ECL_Average, 2 ), GetWavesDataFolder( ECL_TrueTime, 2 )
	Execute cmd
	
	traceName = NameOfWave( ECL_Average ); 
	sprintf cmd, "ModifyGraph mode(%s) = 3", traceName;							Execute cmd
	sprintf cmd, "ModifyGraph marker(%s) = %d", traceName, markerNo;		Execute cmd
	sprintf cmd, "ModifyGraph useMrkStrokeRGB(%s) = 1", traceName;			Execute cmd

	ApplyColor2Trace( "", traceName, colorstr )

	
	if( loc_AddErrorBar )
		sprintf cmd, "ErrorBars %s Y,wave=(%s,%s)", traceName, NameOfWave( ECL_StdDev ), NameOfWave( ECL_StdDev )
		Execute cmd
	endif
End