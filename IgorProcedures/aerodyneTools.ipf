#pragma rtGlobals=1	// Use modern global access method.
//Menu "Macros"
//	Submenu "Hitran Functions"
//		"Make HIT File", DrawHitManPanel()
//		"Doppler Broadening Calc", LineBroaden()
//	End
//End

//Make/N=100000/D/O c2h4_bi_300
//SetScale/I x, 1, 1000, c2h4_bi_300
//c2h4_bi_300 = RC_Calc( 1e-28, 0.8, 8.8e-12,0, x, 300)


// this code for compatibility with Igor 6.
#if Exists("PanelResolution") != 3
Static Function PanelResolution(wName)
	String wName
	return 72
End
#endif

Function RC_Calc( grey_lpl, grey_n, grey_hpl, grey_m, P, T )
	Variable grey_lpl, grey_n, grey_hpl, grey_m, P, T
	
	Variable rc_bi, kotm, kinf, ratio, expoterm
	Variable M = 9.66e18 * P / T
	
	kotm = grey_lpl * (T/300)^(-grey_n) * M
	kinf = grey_hpl * (T/300)^(-grey_m)
	
	ratio = kotm / kinf
	
	expoterm = 1 + (Log( ratio ))^2
	
	rc_bi = (  kotm /  ( 1 + ratio ) ) * 0.6^( 1/expoterm )
	
	return rc_bi	
End

Function DrawHitManPanel()

	SetDataFolder root:
	Variable button_width = 110, control_height = 20, text_box_width = 200
	Variable button_width_big = 150
	Variable fileListwidth = 155, fileListheight = 150, row = 0
	variable space = 5
	Variable column_1 = 5, column_2 = fileListwidth + 5
	Variable thisNextPos = column_1
	
	variable windowWidth = 2*button_width + button_width_big + fileListWidth +6*space * PanelResolution("")/screenResolution

	// These two are global ish variables to determine the state of what the user has done
//	Variable/G hm_path2par = 0, hm_path2hit = 0
	Variable/g hm_begin_cm=1200, hm_end_cm=1205, hm_thresh=0
	Variable/g hm_rawLineCount, hm_filtLineCount
	String/g hm_message = "Use PAR File to select folder with sourcefiles, then pulldown to select"
	String/g hm_filename, hm_iso_filt, hm_file_list = "None", hm_hit_filename
	Make/O/T molparam_w = { "null", "H2O", "CO2", "O3", "N2O", "CO", "CH4", "O2", "NO", "SO2", "NO2", "NH3", "HNO3", "OH", "HF", "HCl", "HBr", "HI", "ClO", "COS", "H2CO", "HOCl", "N2", "HCN", "CH3Cl", "H2O2", "C2H2", "C2H6", "PH3", "COF2", "SF6", "H2S", "HCOOH", "HO2", "O", "ClONO2", "NO+", "HOBr", "C2H4", "CH3OH", "CH3Br", "CH3CN", "CF4", "C4H2", "HC3N", "H2", "CS", "SO3" }
	SVAR hm_filename=hm_filename; SVAR hm_iso_filt=hm_iso_filt
	SVAR hm_file_list=hm_file_list
	NVAR hm_begin_cm=hm_begin_cm; NVAR hm_end_cm=hm_end_cm; NVAR hm_thresh=hm_thresh
	SVAR hm_hit_filename=hm_hit_filename
	PauseUpdate; Silent 1		// building window...
	if( strlen( WinList( "HM_Panel", ";", "" ) )> 0 )
		DoWindow/K HM_Panel
	endif
	
	Display /K=1/W=(5,5,windowWidth,      (filelistheight+2*control_height)*2.5)
	DoWindow/C HM_Panel
	ControlBar 130
	Button HM_ShowMolParam, pos = { thisNextPos, row }, size={button_width_big, control_height}, font="Arial",fSize=11
	Button HM_ShowMolParam, proc=HM_ButtonProc, title = "(1) Show MolParam"
	thisNextPos += button_width_big + space
	
	Button HM_File, pos = { thisNextPos, row }, size={button_width, control_height}, font="Arial",fSize=11
	Button HM_File, proc=HM_ButtonProc, title = "(2) PAR File"
	thisNextPos += button_width + space
	
	NewPath/Z/O HM_Path2PAR, "C:Hitran:HITRAN2012:By-Molecule"
	PathInfo /S HM_Path2PAR
	
	PopupMenu HM_FileName, pos = {thisNextPos , row+1 }, size={fileListWidth, control_height}, font="Arial",fSize=11
	PopupMenu HM_FileName, title = ":", value=#"root:hm_file_list"
	PopupMenu HM_FileName, bodywidth = fileListWidth
	thisNextPos += fileListWidth + space
	variable last_column = thisNextPos	
	Button HM_Close, proc=HM_ButtonProc, pos={thisNextPos, row }, font="Arial",fSize=11
	Button HM_Close, title="Close", size={button_width, control_height}
	thisNextPos = column_1

	
	row+=control_height + 3
	SetVariable HM_BeginCM, pos = {thisNextPos, row }, size={1.75*button_width, control_height}, font="Arial",fSize=11
	SetVariable HM_BeginCM, title = "Wavelength (cm-1)", value = hm_begin_cm, limits={0,100000,0}
	SetVariable HM_BeginCM proc=HM_WavelengthSVP,frame=1
	thisNextPos += 2*button_width + space
	
	SetVariable HM_EndCM, pos = {thisNextPos, row }, size={button_width, control_height}, font="Arial",fSize=11
	SetVariable HM_EndCM, title = " to ", value = hm_end_cm, limits={0,100000,0}
	SetVariable HM_EndCM proc=HM_WavelengthSVP,frame=1
	thisNextPos += button_Width + space
	
	Button HM_LookUp, pos = { last_Column, row}, size = {button_width, control_height }, font="Arial",fSize=11
	Button HM_LookUp, proc=HM_ButtonProc, title = "(3) Load Lines"

	row+=control_height + 3
	CheckBox HM_FiltByIso pos = {column_1, row}, size={button_width,control_height}, font="Arial",fSize=11
	CheckBox HM_FiltByIso proc=HM_FilterCheckProc,title="Filter by Molec/Iso#"
	CheckBox HM_FiltByIso disable=2
	SetVariable HM_Rule, pos = {column_1+button_width+2, row }, size={3.8*button_width, control_height},  font="Arial",fSize=11
	SetVariable HM_Rule, title = "#(s) to Include", value = hm_iso_filt, help={"mm3;mm1 [where mm = hitran molec number and index is isotope number]"}
	SetVariable HM_Rule, proc=HM_FilterSVP
	SetVariable HM_Rule, disable=1
	row+=control_height + 3
	CheckBox HM_FiltThresh pos = {column_1, row}, size={1.5*button_width,control_height}, font="Arial",fSize=11
	CheckBox HM_FiltThresh proc=HM_FilterCheckProc,title="Filter by Threshold"
	CheckBox HM_FiltThresh disable=2
	SetVariable HM_Threshold, pos = {column_1+1.5*button_width+2, row }, size={button_width, control_height} , font="Arial",fSize=11
	SetVariable HM_Threshold, title = " ", value = hm_thresh
	SetVariable HM_Threshold, proc=HM_FilterSVP, limits = { 1e-50, 1e-15, 0 }
	SetVariable HM_Threshold disable =1
	Button HM_Filter, proc=HM_ButtonProc, pos ={ column_1 + 3.5 *button_width + 2, row}, font="Arial",fSize=11
	Button HM_Filter, size= {button_width, control_height}, title="Filter"
	Button HM_Filter, disable=1
	row+= control_height+4

	Button HM_Write, proc=HM_ButtonProc, pos={column_1, row-2}, font="Arial",fSize=11
	Button HM_Write, title="(4)Write HIT", size={button_width, control_height}
	Button HM_Write, disable=2
	hm_hit_filename = "name.hit"
	SetVariable HM_HITfilename, pos = {column_1+button_width+4, row }, size={3*button_width, control_height}, font="Arial",fSize=11
	SetVariable HM_HITfilename, title = "name.hit", value = hm_hit_filename
	SetVariable HM_HITfilename disable =2
	
	SetVariable HM_Message, pos={ column_1, row + control_height }, size = { 5 * button_width, control_height}, font="Arial",fSize=11
	SetVariable HM_Message, title = " ", value = hm_message, frame=0
	SetVariable HM_Message, noedit = 1
End

Function HM_ButtonProc( ctrlName ) : ButtonControl
	String ctrlName
	
	SetDataFolder root:

	SVAR hm_filename=hm_filename; SVAR hm_iso_filt=hm_iso_filt
	SVAR hm_file_list=hm_file_list
	NVAR hm_begin_cm=hm_begin_cm; NVAR hm_end_cm=hm_end_cm; NVAR hm_thresh=hm_thresh
		
	SVAR hm_Message=hm_Message
	NVAR hm_rawLineCount=hm_rawLineCount
	NVAR hm_filtLineCount=hm_filtLineCount
	SVAR hm_hit_filename=hm_hit_filename
	Wave/T molparam_w=molparam_w
	SVAR hm_iso_filt = hm_iso_filt	

	String parByMol = ""
	Variable refnum
	Variable this_path
	
	String specPiso, spec, iso
	if( cmpstr( ctrlName, "HM_LookUp" ) == 0 )
		if( hm_end_cm == 0 )
			hm_end_cm = 300
		endif
		ControlInfo HM_FileName
		parByMol = s_Value[0,1]
		
		PARFile_LoadRange( "HM_Path2PAR", s_value, hm_begin_cm, hm_end_cm )
		HM_GenerateNeighborFigure(); DoWindow/F HM_Panel;
		
		string chemname = "name", beginDecP="", endDecP=""
		if(!stringmatch(hm_iso_filt,"")) //then molecule filtering selected
			chemname = molParam_w[str2num(hm_iso_filt[0,1])]
		endif
		if(!stringmatch(parByMol, "HI")) // then this is not the full HITRAN par file
			Variable thisMol = str2num(parByMol)
			if(thisMol>0 && numtype(thisMol)==0)
				chemname = molParam_w[thismol]
			endif
		endif
		if(hm_begin_cm - floor(hm_begin_cm)>0 || hm_end_cm-floor(hm_end_cm) >0) // then decimals specified
			sprintf beginDecP, "p%02d", (hm_begin_cm-floor(hm_begin_cm))*100
			sprintf endDecP, "p%02d", (hm_end_cm -floor(hm_end_cm))*100
		endif
		hm_hit_filename = chemname + "_" + num2str(floor(hm_begin_cm)) +beginDecP+ "_" +num2str( floor(hm_end_cm)) + endDecp+".hit" 
		
		Wave species_w=species_w;Wave linestrength_w=linestrength_w
		duplicate/o species_w, iso_filt_w, thresh_filt_w, final_filt_w
		duplicate/o linestrength_w, filt_linestrength
		Wave iso_filt_w = iso_filt_w; Wave thresh_filt_w=thresh_filt_w; Wave final_filt_w=final_filt_w
		Wave filt_linestrength=filt_linestrength
		thresh_filt_w = 1; iso_filt_w = 1; final_filt_w = 1
 
 		HM_DoMessage()
		SetVariable HM_Threshold disable =0;SetVariable HM_Rule, disable=0
		CheckBox HM_FiltThresh disable=0; CheckBox HM_FiltByIso disable=0
		Button HM_Filter disable=0; Button HM_Write, disable=0
		SetVariable HM_HITfilename disable =0
		RemoveAllTracesFromGraph("")
		AppendToGraph/L=filt_data_axis filt_linestrength vs wavelength_w
		
		AppendToGraph/L=raw_data_axis linestrength_w vs wavelength_w
		
		Execute("stick_line_style()")
		WaveStats/Q/Z species_w
		if( V_min == V_max )
			sprintf hm_message, "OneIsotope(%g)  %s", species_w[0], hm_message
			ModifyGraph rgb(linestrength_w)=(0,0,52224),zColor(linestrength_w)=0
		else
			ModifyGraph zColor(linestrength_w)={species_w,*,*,Rainbow}
		endif
		ModifyGraph rgb(filt_linestrength)=(0,52224,0)
		ModifyGraph axRGB(filt_data_axis)=(0,52224,0),tlblRGB(filt_data_axis)=(0,52224,0);DelayUpdate
		ModifyGraph alblRGB(filt_data_axis)=(0,52224,0)
	endif
	if( cmpstr( ctrlName, "HM_ShowMolParam" ) == 0 )
		Wave/T molparam_w=molparam_w
		Edit/K=1/W=(190,37,365,300) molparam_w
		SVAR hm_message=hm_message
		hm_message = "These are the Hitran numbers for the species listed (by par)"
	endif
	if( cmpstr( ctrlName, "HM_File" ) == 0 )
		NewPath/O/M="Select folder PAR file(s) are located"/Q HM_Path2PAR
		PathInfo HM_Path2PAR
		hm_file_list = GetFilesFromPath( "HM_Path2PAR" )
		SetVariable HM_Threshold disable =1;SetVariable HM_Rule, disable=1
		CheckBox HM_FiltThresh disable=2; CheckBox HM_FiltByIso disable=2
		Button HM_Filter disable =1; Button HM_Write, disable=2
		SetVariable HM_HITfilename disable =1
		PopupMenu HM_FileName mode=1
		SVAR hm_message=hm_message
		pathinfo hm_path2par
		sprintf hm_message "pulldown working from %s", s_path
	endif
	if( cmpstr( ctrlName, "HM_Close" ) == 0 )
		DoWindow/K HM_Panel
		KillWaves/z linestrength_w, wavelength_w, species_w, thresh_filt_w, iso_filt_w, final_filt_w, line_w
		KillWaves/z filt_linestrength
		KillVariables/z hm_begin_cm, hm_end_cm, hm_thresh
		KillStrings/z hm_file_list, hm_filename, hm_iso_filt
	endif
	
	if( cmpstr( ctrlName, "HM_Write" ) == 0 )
		NewPath/Z/O HM_Path2Write, "C:Hit"
		PathInfo HM_Path2Write
		if( strlen( s_path ) < 1 )
			NewPath/Z/O/M="Select folder where HIT file is to be written" HM_Path2Write
			Pathinfo /S HM_Path2Write
		endif
		// this is your problem Scott... by doing NewPath you are pointing to the last open path.  I'm not sure how to redirect that
		// programatically
		SVAR hm_hit_filename=hm_hit_filename
		Open/P=HM_Path2Write refnum as hm_hit_filename
		Variable kdex = 0
		Wave final_filt_w=final_filt_w; Wave/T line_w=line_w
		do
			if( final_filt_w[kdex] == 1 )
				fprintf refnum, "%s\r\n", line_w[kdex]
				//fprintf 1, "%s\r", line_w[kdex]
			endif
			kdex += 1
		while( kdex < numpnts( line_w ) )
		Close refnum
		PathInfo HM_Path2Write
		printf "Data written to file %s%s", s_path, hm_hit_filename
		printf " at %s on %s\r", Secs2Time( datetime, 0 ), Secs2Date( datetime, 0 ) 
		SVAR hm_message=hm_message
		PathInfo HM_Path2Write
		sprintf hm_message "Data written to file %s%s", s_path, hm_hit_filename
	endif
	if( cmpstr( ctrlName, "HM_Filter" ) == 0 )
		Wave species_w=species_w;Wave linestrength_w=linestrength_w
		Wave iso_filt_w = iso_filt_w; Wave thresh_filt_w=thresh_filt_w; Wave final_filt_w=final_filt_w
		Wave filt_linestrength=filt_linestrength
		ControlInfo HM_FiltByIso
		if( V_value == 0 )
			// the box is presently is unchecked, which means it should set to 1 
			iso_filt_w = 1
		endif
		if( v_value == 1 )
			// the box is now checked which means we need to generate/update the filt_w
			
				beginDecP="", endDecP=""
				
				if(hm_begin_cm - floor(hm_begin_cm)>0 || hm_end_cm-floor(hm_end_cm) >0) // then decimals specified
					sprintf beginDecP, "p%02d", (hm_begin_cm-floor(hm_begin_cm))*100
					sprintf endDecP, "p%02d", (hm_end_cm -floor(hm_end_cm))*100
				endif
				
			if( strlen( hm_iso_filt ) < 1 )
				// lets just skip this, I have a feeling it isn't entered properly
				
				chemname = "name"
				hm_hit_filename = chemname + "_" + num2str(floor(hm_begin_cm)) +beginDecP+ "_" +num2str( floor(hm_end_cm)) + endDecp+".hit" 
				
			else
				PARSieveByIsotope( species_w, hm_iso_filt, iso_filt_w)
		
				chemname = molParam_w[str2num(hm_iso_filt[0,1])]
				hm_hit_filename = chemname + "_" + num2str(floor(hm_begin_cm)) +beginDecP+ "_" +num2str( floor(hm_end_cm)) + endDecp+".hit" 
				
				
			endif
		endif
		ControlInfo HM_FiltThresh
		if( V_value == 0 )
			// the box is presently is unchecked, which means it should set to 1 
			thresh_filt_w = 1
		endif
		if( v_value == 1 )
			 PARSieveLineStrength( linestrength_w, hm_thresh, thresh_filt_w)
		endif
		filt_linestrength = linestrength_w
		final_filt_w = thresh_filt_w * iso_filt_w
		filt_linestrength *= final_filt_w
		HM_DoMessage()
	endif
	
End
Function HM_GenerateNeighborFigure([H17_tf])
	variable H17_tf
	if(paramisdefault(H17_tf))
		H17_tf=0
	endif

//	DFREF dfr = $( "root:" + ks_H16_Folder + ":" + ks_H16_LinesFolder );		// dfr is now this line list folder
	SetDataFolder root: ; 
	
	if(H17_tf)
	
		NewDataFolder /O/S H17IgorSim
		NewDataFolder /O HitranLines
		
		SetDatafolder root:H17IgorSim
		
		Wave/T molparam_tw = molparam_tw
		wave/z intensity = root:H17IgorSim:HitranLines:intensity
		wave/z molecule_number = root:H17IgorSim:HitranLines:molecule_number
		
		if(!waveexists(intensity))
			print "load some hitran lines"
			return -1
		endif
	else // old style in root

		Wave/z species_w = species_w // this is the length of the loaded hitran lines and contains the full isotope specification
		Wave/T molparam_tw = molparam_w
		Duplicate/O species_w, molecule_number
		Wave molecule_number		 = molecule_number;
		Wave intensity				 = linestrength_w;


		String species_str, molecule_str
		Variable idex, count = numpnts( species_w ), 	 this_species
	
		// parse full species identifyer into molecule number, e.g. 1 from 121
		for( idex = 1; idex < count; idex += 1 )
			species_str = num2str( species_w[idex] )
			molecule_str = species_str[ 0, strlen( species_str ) - 2 ]
			molecule_number[idex] = str2num( molecule_str )
		endfor

	endif



	Make/N=100/O/D HMSurveyIntensity, HMSurveyDensity, HMSurveyIndex, HMSurveyImpact
	HMSurveyIntensity = 0
	HMSurveyDensity = 0
	HMSurveyIndex=p
	HMSurveyImpact=0
	Make/N=100/O/T HMSurveyLabel
	HMSurveyLabel = molparam_tw;
	count = numpnts( molecule_number )
	for( idex = 0; idex < count; idex += 1 )
		this_species = molecule_number[ idex ]
	
		HMSurveyIntensity[ this_species ] = max( HMSurveyIntensity[ this_species ], intensity[ idex ] )
		HMSurveyDensity[ this_species ] += 1;

	endfor
	
	// How to best judge "impact"? Here, we do sum of relative intensity and density.
	wavestats/Q HMSurveyIntensity; Variable MaxIntensity=V_max
	wavestats/Q HMSurveyDensity; Variable MaxDensity=V_max
	HMSurveyImpact = (HMSurveyIntensity/MaxIntensity) + (HMSurveyDensity/MaxDensity)
	Sort/R HMSurveyImpact,HMSurveyDensity,HMSurveyImpact,HMSurveyIntensity,HMSurveyLabel
		
	DoWindow HM_SurveyFigure
	if( V_Flag )
		DoWindow/F HM_SurveyFigure
	else
		Display /W=(615,45,857,399)/K=1  HMSurveyDensity vs HMSurveyIntensity as "HM_SurveyFigure"
		DoWindow/C HM_SurveyFigure
		AppendToGraph/VERT/T=impact/L=molecule HMSurveyImpact
		ModifyGraph userticks(molecule)={HMSurveyIndex,HMSurveyLabel}
		ModifyGraph mode(HMSurveyDensity)=3,mode(HMSurveyImpact)=1
		ModifyGraph lSize(HMSurveyImpact)=4
		ModifyGraph rgb(HMSurveyDensity)=(16385,28398,65535)
		ModifyGraph textMarker(HMSurveyDensity)={HMSurveyLabel,"default",1,0,5,0.00,0.00}
		ModifyGraph log(left)=1,log(bottom)=1
		ModifyGraph mirror(left)=2
		ModifyGraph noLabel(impact)=1
		ModifyGraph lblPos(left)=55,lblPos(impact)=27,lblPos(molecule)=70
		ModifyGraph lblLatPos(molecule)=-5
		ModifyGraph axisOnTop=1
		ModifyGraph axisOnTop(left)=0
		ModifyGraph freePos(impact)=0
		ModifyGraph freePos(molecule)=0
		ModifyGraph axisEnab(left)={0,0.48}
		ModifyGraph axisEnab(molecule)={0.52,1}
		ModifyGraph standoff=0
		Label left "Line Density (#)"
		Label bottom "Max Intensity [cm\\S-1\\M/(molecule cm\\S-2\\M) 296 K]"
		Label impact "Potential Impact on Spectral Region \r(Intensity or Density)"
		Label molecule "Hitran \rSpecies"
		SetAxis molecule 10.5, -0.5
	endif
	
End
Function HM_DoMessage()
		SetDataFolder root:

		SVAR hm_Message=hm_Message
		NVAR hm_rawLineCount=hm_rawLineCount
		NVAR hm_filtLineCount=hm_filtLineCount
 		hm_rawLineCount = numpnts( species_w )
 		hm_filtLineCount = FilterCount()
 		sprintf hm_message, "Prepared %g lines for hit file, out of %g loaded lines ",hm_filtLineCount, hm_rawLineCount 
End
Function /T GetFilesFromPath( pathName )
	String pathName
	
	String files = ""
	files = IndexedFile( $pathName, -1, "????" )
	return files
End
Function HM_FilterCheckProc(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	
	SetDataFolder root:

	Wave iso_filt_w=iso_filt_w; Wave thresh_filt_w=thresh_filt_w
	Wave final_filt_w=final_filt_w
	Wave filt_linestrength=filt_linestrength
	Wave linestrength_w=linestrength_w
	SVAR rule=hm_iso_filt; 
	NVAR hm_thresh=hm_thresh
	if( cmpstr( ctrlName, "HM_FiltByIso" ) == 0 )
		ControlInfo HM_FiltByIso
		if( V_value == 0 )
			// the box is presently is unchecked, which means it should set to 1 
			iso_filt_w = 1
			rule = ""
		endif
		if( v_value == 1 )
			// the box is now checked which means we need to generate/update the filt_w
			rule = "mm3;mm1 [where mm = hitran molec# and num = isotope#]"
		endif
	endif
	if( cmpstr( ctrlName, "HM_FiltThresh" ) == 0 )
		ControlInfo HM_FiltThresh
		if( V_value == 0 )
			// the box is presently is unchecked, which means it should set to 1 
			thresh_filt_w = 1
		endif
		if( v_value == 1 )
			// the box is now checked which means we need to generate/update the filt_w
			if( hm_thresh == 0 )
				hm_thresh = 1e-23
			endif
		endif
	endif
	filt_linestrength = linestrength_w
	final_filt_w = thresh_filt_w * iso_filt_w
	filt_linestrength *= final_filt_w
	HM_DoMessage()
End
Function HM_FilterSVP(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName

	SetDataFolder root:
	
	NVAR hm_begin_cm=hm_begin_cm
	NVAR hm_end_cm=hm_end_cm
	
	if( cmpstr( ctrlName, "HM_Rule" ) == 0 )
		if( hm_end_cm == 0 )
			hm_end_cm = 100 + hm_begin_cm
		endif
	endif
	
End

Function HM_WavelengthSVP(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	SetDataFolder root:
	
	NVAR hm_begin_cm=hm_begin_cm
	NVAR hm_end_cm=hm_end_cm
	
	if( cmpstr( ctrlName, "HM_BeginCM" ) == 0 )
		if( hm_end_cm == 0 )
			hm_end_cm = 100 + hm_begin_cm
		endif
	endif
	if( cmpstr( ctrlName, "HM_EndCM" ) == 0 )
		if( hm_begin_cm == 0 )
			hm_begin_cm = hm_end_cm - 100
		endif
	endif
	//if( hm_begin_cm > hm_end_cm )
	//	Variable holder = hm_begin_cm
	//	hm_begin_cm = hm_end_cm
	//	hm_end_cm = holder
	//endif
End
// hitman 
Function FilterCount()
	
	Wave filt = final_filt_w
	Variable idex = 0, count = 0
	do
		count += filt[idex]
		idex += 1
	while( idex < numpnts( filt ) )
	return count
End
Function PARFile_LoadRange( path, filename, begin_cm, end_cm )
	String path, filename
	Variable begin_cm, end_cm

	SetDataFolder root:
	
	String error_str
	//printf "ParFile_LoadRange debug called with args, %s & %s from %g to %g\r", path, filename, begin_cm, end_cm
	Variable file_ok = FileCheck( path, filename )
	if( file_ok != 1 )
		switch(file_ok)	
			case -1:		
				printf "File %s does not exist\r", filename
				break					
			case -2:		
				PathInfo $path
				printf "Path named %s, in igor directed to %s", path, s_path
				break
			return -1
		endswitch
	endif
	
	Variable refNum; String line
	Open/R/Z=2/P=$path refNum as filename
	if(V_Flag!=0)
		// open failed
		print "error in ParFile_LoadRange. Could not open ",filename
		return -1
	endif
	
	FReadLine refNum, line
	Variable line_characters = strlen( line )
	FStatus refNum
	Variable low_end, high_end, mid_pnt
	low_end = 0; high_end = V_logEOF;
	Variable idex = 0, line_count = 0, good_enough = 100, there_yet = 0
	String species_str, wavelength_str, linestrength_str, energy_str
	Variable species, wavelength, linestrength, energy
	printf "searching %s", filename
	do
		mid_pnt = floor( (high_end + low_end )/2)
		printf "."; idex += 1
		if( idex > 100 )
			printf "\r"; idex = 0
		endif
		
		if( high_end - low_end < good_enough )
			there_yet = 1
		else
			FSetPos refNum, mid_pnt
			FReadLine refNum, line; FReadLine refNum, line
			if( strlen( line ) < 1  )
				there_yet = 1; print "error in ParFile_LoadRange, hit eof before expected, continuing execution"
			endif
			ParParseLine( line, species_str, wavelength_str, linestrength_str, energy_str )
			species = str2num( species_str )
			wavelength = str2num( wavelength_str )
			linestrength = str2num( linestrength_str )
			energy = str2num( energy_str )
			//print species, wavelength, linestrength, begin_cm
			if( wavelength <= begin_cm )
				//print "adjusting low end to midpoint"
				low_end = mid_pnt
				
			else
				if( wavelength > begin_cm )
					//print "adjusting high end to midpoint"
					high_end = mid_pnt	
				else
					there_yet = 1; print "error in ParFile_LoadRange, binary search is lost, continuing"
				endif
			endif
			
		endif
	while( there_yet != 1 )
	printf "done\t"
	mid_pnt -= (good_enough + line_characters * 5 )
	if( mid_pnt < 0 )
		mid_pnt = 0
	endif 
	FSetPos refNum, mid_pnt
	FReadLine refNum, line // to clear back to the begining of the line
	Make/O/N=0/D species_w, wavelength_w, linestrength_w, energy_w
	Make/O/N=0/T line_w
	there_yet = 0
	printf "loading lines from %s ....wait...", filename
	do
		FReadLine refNum, line
		if( strlen( line ) < 1 )
			there_yet = 1 
		else
			line_count += 1
			ParParseLine( line, species_str, wavelength_str, linestrength_str, energy_Str )
			species = str2num( species_str )
			wavelength = str2num( wavelength_str )
			linestrength = str2num( linestrength_str )
			energy = str2num( energy_str )
			if( wavelength > end_cm )
				there_yet = 1
			else
				AppendVal( species_w, species )
				AppendVal( wavelength_w, wavelength )
				AppendVal( linestrength_w, linestrength )
				AppendVal( energy_w, energy )
				line = line[0, strlen(line) - 2 ]
				AppendString( line_w, line )
			endif
		
		endif
		
	
	while( there_yet != 1 )
	printf "done.  Triming..."
	idex = 0
	do
		if( wavelength_w[idex] < begin_cm )
			DeletePoints idex, 1, species_w, wavelength_w, linestrength_w, line_w, energy_w
		else
			idex = numpnts( species_w )
		endif
	while( idex < numpnts( species_w ) )
	printf "done\r"
End	




// 21  443.480903 4.727E-27 3.916E-05.0676.0818 2625.5233 .78 .000000 10  8             P 37 455 2 2 1
// 21  444.958851 5.928E-27 3.917E-05.0678.0835 2568.5724 .78 .000000 10  8             P 35 455 2 2 1
// 21  446.439719 7.301E-27 3.918E-05.0681.0852 2514.7372 .78 .000000 10  8             P 33 455 2 2 1

Function PARParseLine( line, species, wavelength, linestrength, energy )
	string line, &species, &wavelength, &linestrength, &energy
	
	species = line[0,2]
	wavelength = line[ 3, 14 ]
	linestrength = line[15, 25]
	energy = line[ 45, 54 ]
End
Function FileCheck( path, filename )
	String path, filename
	
	Variable refNum
	PathInfo $path
	if( v_flag == 1 )
		Open/P=$Path /R /Z=2 refNum as filename
		if( v_flag == 0 )
			Close refNum
			return 1
		else
			return -1
		endif
	else
		return -2
	endif
End

Function PARSieveByIsotope( species_w, rule, target_w)
	Wave species_w
	String rule // rule is a semicolon separated list of isotopes to be included ie; 311;312;313
	Wave target_w

	String this_species
	Variable species_val, rule_list = ItemsInList( rule )
	Variable idex = 0, count = numpnts( linestrength_w ), jdex
	Duplicate/O species_w, target_w
	target_w = Nan
	do
		jdex = 0
		do
			species_val = str2num( StringFromList( jdex, rule ) )
			if( species_w[idex] == species_val )
				target_w[idex] = 1
				jdex = rule_list
			else
				target_w[idex] = 0
			endif
			jdex += 1
		while( jdex < rule_list )
		idex += 1
	while( idex < count )
End

Function PARSieveLineStrength( linestrength_w, threshold, target_w )
	Wave linestrength_w
	Variable threshold
	Wave target_w
	
	Variable idex = 0, count = numpnts( linestrength_w )
	Duplicate/O linestrength_w, target_w
	target_w = Nan
	do
		if( linestrength_w[idex] > threshold )
			
			target_w[idex] = 1
		else
			
			target_w[idex] = 0
		endif
		idex += 1
	while( idex < count )
End


Proc stick_line_style() : GraphStyle
	PauseUpdate; Silent 1		// modifying window...
	ModifyGraph/Z margin(left)=54
	ModifyGraph/Z mode=1
	ModifyGraph/Z rgb[0]=(65280,0,0),rgb[1]=(0,0,65280)
	ModifyGraph/Z zColor[1]={species_w,*,*,RedWhiteBlue}
	ModifyGraph/Z log(filt_data_axis)=1,log(raw_data_axis)=1
	ModifyGraph/Z tick=2
	ModifyGraph/Z mirror=1
	ModifyGraph/Z minor=1
	ModifyGraph/Z standoff=0
	ModifyGraph/Z gridRGB(filt_data_axis)=(65280,0,0),gridRGB(raw_data_axis)=(0,0,65280)
	ModifyGraph/Z axRGB(filt_data_axis)=(65280,0,0),axRGB(raw_data_axis)=(0,0,65280)
	ModifyGraph/Z tlblRGB(filt_data_axis)=(65280,0,0),tlblRGB(raw_data_axis)=(0,0,65280)
	ModifyGraph/Z alblRGB(filt_data_axis)=(65280,0,0),alblRGB(raw_data_axis)=(0,0,65280)
	ModifyGraph/Z lblPos(raw_data_axis)=42
	ModifyGraph/Z lblLatPos(raw_data_axis)=63
	ModifyGraph/Z freePos(filt_data_axis)=0
	ModifyGraph/Z freePos(raw_data_axis)=0
	ModifyGraph/Z axisEnab(filt_data_axis)={0,0.5}
	ModifyGraph/Z axisEnab(raw_data_axis)={0.52,0.98}
	Label/Z filt_data_axis "\\u#2"
	Label bottom "wavelength (cm\\S-1\\M) (\\K(0,0,52224)top trace -- lines found; \\K(0,52224,0)bottom trace -- lines to be written)"
	Label/Z raw_data_axis "linestrength (cm\\S2\\Mmolecule\\S-1\\M cm\\S-1\\M)"
EndMacro
Function RemoveAllTracesFromGraph(graphName)
	String graphName
	
	
	Variable num_axes, axis_dex = 0, dex
	Variable num_traces_this_axis, trace_dex = 0
	String axis_list, this_trace_list, this_trace, this_ax
	axis_list = DiscriminatedAxisList( graphName, "left" )
	num_axes = ItemsInList( axis_list )
	if( num_axes == 0 )
		return -1
	endif
	do
		this_trace_list = DiscriminatedTraceList( graphName, StringFromList( axis_dex, axis_list ) )
		num_traces_this_axis = ItemsInList( this_trace_list )
		if( num_traces_this_axis == 0 )
			// do nothing
		else
			trace_dex = 0
			do
				this_trace = StringFromList( trace_dex, this_trace_list )
				RemoveFromGraph $this_trace
				trace_dex += 1
			while( trace_dex < num_traces_this_axis )
		endif
		axis_dex += 1
	while( axis_dex < num_axes )
	

End

///////////////////////////

Function LineBroaden()

if( !DataFolderExists( "root:LineBroad"))
	SetDataFolder "root:"
	NewDataFolder /O /S LineBroad
endif
SetDataFolder "root:LineBroad"

Variable /G c = 3E10 // cm s-1
Variable /G k = 1.38E-23 //  /K
Variable /G Na = 6.03E23 // mole-1

Variable /G m=33;
Variable /G temp = 298
Variable /G freq = 1407
Variable /G delta_freq = 1

CalNatBroad()

Execute ( "LineBroadeningPanel()" )

End 

Function SetVarProcLineBroad(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	CalNatBroad()
End

Function CalNatBroad()

NVAR c=root:LineBroad:c;	NVAR k=root:LineBroad:k; 		NVAR Na=root:LineBroad:Na
NVAR m=root:LineBroad:m;	NVAR temp=root:LineBroad:temp;	NVAR freq=root:LineBroad:freq
NVAR delta_freq=root:LineBroad:delta_freq

delta_freq = 2* freq/c * ( 2*k*temp/m*1000*Na * ln(2) * 100*100)^(1/2)

End
Function ButtonKillLineBroad(ctrlName) : ButtonControl
	String ctrlName
	
	DoWindow /K LineBroadeningPanel
	KillDataFolder root:LineBroad
	
End
Window LineBroadeningPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(77.25,50,377.25,175.25) as "LineBroadeningPanel"
	SetVariable setvar0,pos={6,1},size={250,18},proc=SetVarProcLineBroad,title="Molecular Mass (g/mole)"
	SetVariable setvar0,limits={2,250,1},value= root:LineBroad:m
	SetVariable setvar1,pos={6,24},size={250,18},proc=SetVarProcLineBroad,title="Temperature (K)"
	SetVariable setvar1,limits={-Inf,Inf,1},value= root:LineBroad:temp
	SetVariable setvar1_1,pos={6,47},size={250,18},proc=SetVarProcLineBroad,title="Frequency (cm-1)"
	SetVariable setvar1_1,limits={-Inf,Inf,1},value= root:LineBroad:freq
	ValDisplay valdisp0,pos={6,70},size={250,18},title="Delta v (cm-1)",frame=0
	ValDisplay valdisp0,limits={0,0,0},barmisc={0,1000}
	ValDisplay valdisp0,value= #"root:LineBroad:delta_freq"
	Button KillLineBroad,pos={88,96},size={50,20},proc=ButtonKillLineBroad,title="Close"
EndMacro


Function Load_Null( targetFullFile, DestDF )
	String targetFullFile, destDF
End

Function Eddy_LoadCOL_Flex( targetFullFile, DestDF )
	String targetFullFile
	String DestDF

	
	String formatStr = ""
	formatStr = formatStr + "C=1,T=4,N=new_source_rtime;"
	formatStr = formatStr + "C=1,T=4,W=13,N=new_x_wind_m_s;"
	formatStr = formatStr + "C=1,T=4,W=13,N=new_y_wind_m_s;"
	formatStr = formatStr + "C=1,T=4,W=13,N=new_z_wind_m_s;"
	formatStr = formatStr + "C=1,T=4,W=14,N=new_SpeedSound;"
	formatStr = formatStr + "C=1,T=4,W=9,N=new_counter;"
	
		
	MakeAndOrSetDF( DestDF )
//	LoadWave/A/D/Q/J/B=formatStr/V={ ",", "\"", 0, 0 } targetFullFile
	LoadWave/A/D/Q/J/V={ ",", " ", 0, 0 }/B=formatStr targetFullFile
//	LoadWave/A/D/Q/J/V={ ",", "\" ", 0, 0 }/B=formatStr targetFullFile
	variable numwaves = v_flag
	variable inc = 0;
	string new_str, dest_str
	
	Wave/Z source_rtime=source_rtime
	if( WaveExists( source_rtime ) != 1 )
		if( numwaves >= 1 )
			rename $"new_source_rtime", source_rtime;
		endif
		if( numwaves >= 2 )
			rename $"new_x_wind_m_s", x_wind_m_s;
		endif
		if( numwaves >= 3 )
			rename $"new_y_wind_m_s", y_wind_m_s;
		endif
		if( numwaves >= 4 )
			rename $"new_z_wind_m_s", z_wind_m_s;
		endif
		if( numwaves >= 5 )
			rename $"new_SpeedSound", SpeedSound;
		endif
		if( numwaves >= 6 )
			rename $"new_counter", counter;
		endif
		if( numwaves >= 7 )
			rename $"new_col6_conc", col6_conc;
		endif
		if( numwaves >= 8 )
			rename $"new_col7_conc", col7_conc;
		endif
		if( numwaves >= 9 )
			rename $"new_col8_conc", col8_conc;
		endif
		if( numwaves >= 10)
			rename $"new_col9_conc", col9_conc;
		endif
		if( numwaves >= 11 )
			rename $"new_col10_conc", col10_conc;
		endif
		if( numwaves >= 12 )
			rename $"new_col11_conc", col11_conc;
		endif
		if( numwaves >= 13 )
			rename $"new_col12_conc", col12_conc;
		endif
		if( numwaves >= 14 )
			rename $"new_col13_conc", col13_conc;
		endif
		if( numwaves >= 15 )
			rename $"new_col14_conc", col14_conc;
		endif
		if( numwaves >= 16 )
			rename $"new_col15_conc", col15_conc;
		endif
		if( numwaves >= 17 )
			rename $"new_col16_conc", col16_conc;
		endif
	else
		if( WaveExists( $"new_source_rtime" ) )	
			ConcatenateWaves( "source_rtime", "new_source_rtime" )
		endif
		if( WaveExists( $"new_x_wind_m_s" ) )	
			ConcatenateWaves( "x_wind_m_s", "new_x_wind_m_s" )
		endif
		if( WaveExists( $"new_y_wind_m_s" ) )	
			ConcatenateWaves( "y_wind_m_s", "new_y_wind_m_s" )
		endif
		if( WaveExists( $"new_z_wind_m_s" ) )	
			ConcatenateWaves( "z_wind_m_s", "new_z_wind_m_s" )
		endif
		if( WaveExists( $"new_SpeedSound" ) )	
			ConcatenateWaves( "SpeedSound", "new_SpeedSound" )
		endif
		if( WaveExists( $"new_counter" ) )	
			ConcatenateWaves( "counter", "new_counter" )
		endif
		if( WaveExists( $"new_col6_conc" ) )	
			ConcatenateWaves( "col6_conc", "new_col6_conc" )
		endif
		if( WaveExists( $"new_col7_conc" ) )	
			ConcatenateWaves( "col7_conc", "new_col7_conc" )
		endif
		if( WaveExists( $"new_col8_conc" ) )	
			ConcatenateWaves( "col8_conc", "new_col8_conc" )
		endif
		if( WaveExists( $"new_col9_conc" ) )	
			ConcatenateWaves( "col9_conc", "new_col9_conc" )
		endif
		if( WaveExists( $"new_col10_conc" ) )	
			ConcatenateWaves( "col10_conc", "new_col10_conc" )
		endif
		if( WaveExists( $"new_col11_conc" ) )	
			ConcatenateWaves( "col11_conc", "new_col11_conc" )
		endif
		if( WaveExists( $"new_col12_conc" ) )	
			ConcatenateWaves( "col12_conc", "new_col12_conc" )
		endif
		if( WaveExists( $"new_col13_conc" ) )	
			ConcatenateWaves( "col13_conc", "new_col13_conc" )
		endif
		if( WaveExists( $"new_col14_conc" ) )	
			ConcatenateWaves( "col14_conc", "new_col14_conc" )
		endif
		if( WaveExists( $"new_col15_conc" ) )	
			ConcatenateWaves( "col15_conc", "new_col15_conc" )
		endif
		if( WaveExists( $"new_col16_conc" ) )	
			ConcatenateWaves( "col16_conc", "new_col16_conc" )
		endif
		
	endif
	Wave source_rtime=source_rtime
	SetScale/P y, 0, 0, "dat", source_rtime
	
		KillWaves/Z new_source_rtime, new_x_wind_m_s, new_y_wind_m_s, new_z_wind_m_s, new_SpeedSound;
		KillWaves/Z new_counter, new_col6_conc, new_col7_conc, new_col8_conc;			
		KillWaves/Z new_col9_conc, new_col10_conc, new_col11_conc, new_col12_conc;
		KillWaves/Z new_col13_conc, new_col14_conc, new_col15_conc, new_col16_conc;
		KillWaves/Z new_instime
		
	String loadedwaves = wavelist("", ";", "DIMS:1;MINROWS:"+num2str(numpnts(source_Rtime))+";MAXROWS:"+num2str(numpnts(source_Rtime))+";")
	setdatafolder root:
	
End

	
// this is a function that will load all .dat files in a directory
// 
// 	fullpath2dat arg is the directory using colon separator syntax to the data folder
//  fileprefix is a casesensitive? prefix the the candidate file must start with
//  call_F is a DEFT style transient loader function
//  datafolder is the <igor datafolder name> to place this load

// for example to load all of the TLDA_*.dat files you might use
// LoadAlldat_inTimeRange( "c:myfiles:thisfolder", "csat3", LoadCOL_Flex, "a_csat3", text2datetime(""), text2datetime(""))
// if you want an interactive browse, leave the first arg empty, eg ""
// 
// Search terms:
// datInDir, datindir, loadalldatindir, load_all_dat_in_dir
// example
// Eddy_LoadAllDat_inTimeRange ("MacHD:Users:tyacov:Documents:My Documents:Aerodyne:2021 User:CS-128 Agri Food Canada Eddy Flux:", "noQuotes", Eddy_LoadCOL_Flex, "a_test", text2datetime("04/06/2021 00:10"), text2datetime("04/06/2021 02:00"))

Function Eddy_LoadAllDat_inTimeRange( fullpath2dat, fileprefix, call_F, datafolder, start, stop)
	String fullpath2dat, fileprefix
	FUNCREF Load_Null call_F
	String datafolder
	Variable/D start, stop
	
	if( cmpstr( fullpath2dat, "" ) == 0 )
		NewPath/O/Q/M="Choose directory where dat waves are located" dat_LoadPATH
	else
		NewPath/O/Q dat_LoadPATH  fullpath2dat
	endif
	if( V_Flag != 0 )
			printf "aborted, cancelled or failed NewPath\r"; return -1;
	endif
	
	Make/T/N=0/O temp_list_of_dat_tw

	// GLF_ functions are in Global_Utils.ipf
	GFL_FilelistAtOnce( "dat_LoadPATH", 0, temp_list_of_dat_tw, ".dat" )
	sort temp_list_of_dat_tw, temp_list_of_dat_tw

	// Parse files to get those covering start/stop range

	String this_dat
	Variable prefix_length = strlen( fileprefix)

	Variable idex = 0, count = Numpnts( temp_list_of_dat_tw )
	Variable found_dat = 0
	Variable load_this_one = 0
	String fullfile, dff
	Variable/G firstTime = 0
	Variable/G fileStartTime = 0
	Variable/G fileStopTime 

	variable i
	// pre-parse file list
	if(count>0)
		make/n=(numpnts(temp_list_of_dat_tw))/D/O temp_fileTimes, temp_fileStopTimes
		make/n=(numpnts(temp_list_of_dat_tw))/O temp_loadThis
		wave temp_loadThis = temp_loadThis; temp_loadThis = 0
		wave/D temp_fileTimes = temp_fileTimes; temp_fileTimes = nan
		wave/d temp_fileStopTimes = temp_FileStopTimes; temp_fileStopTimes=nan
		
		for(i=0;i<count;i+=1)
			this_dat = temp_list_of_dat_tw[i];	
			
			// Check the file prefix
				if( cmpstr( fileprefix, "" ) == 0 )
					temp_loadThis[i]=1
				else
					if( cmpstr( fileprefix, this_dat[0,prefix_length-1]) == 0 )
						temp_loadThis[i] = 1;
					endif
				endif
				
				// Parse the time
				if(temp_loadThis[i]==1)
				String timeStr = this_dat[prefix_length+1, strlen(this_dat)-5]
				if(strlen(timeStr)==9)
					// then the format is YYMMDD_HH
					timestr += "0000"
				elseif(strlen(timestr)!=13)
					load_this_one=0
				endif
				Variable/G fileTime = DTI_Text2Datetime(timeStr, "filename2y")
				temp_fileTimes[i] = fileTime	
				endif
				
		endfor
		
		// delete the lines not needed		
		for(i=count-1;i>=0;i-=1)
			if(temp_loadThis[i] == 0 )
				deletepoints i, 1, temp_list_of_dat_tw, temp_loadThis, temp_fileTimes, temp_fileStopTimes
			endif		
		endfor
		count = numpnts(temp_list_of_dat_tw)
		
		if(count>1)
		temp_fileStopTimes[0,numpnts(temp_fileStopTimes)-2] = temp_fileTimes[p+1]			
		endif
		
		for(i=count-1;i>=0;i-=1)
			if(numtype(temp_fileStopTimes[i])!=2 && temp_fileStopTimes[i] < start )
				deletepoints i, 1, temp_list_of_dat_tw, temp_loadThis, temp_fileTimes, temp_fileStopTimes
			endif		
			if(temp_fileTimes[i] > stop)
				deletepoints i, 1, temp_list_of_dat_tw, temp_loadThis, temp_fileTimes, temp_fileStopTimes
			endif

		endfor
		
		
		count = numpnts(temp_list_of_dat_tw)
	
		if(count == 0)
			found_dat = 0 
		else
			do
				this_dat = temp_list_of_dat_tw[idex];		load_this_one = 1
				
				if( load_this_one )
					PathInfo dat_LoadPATH
					sprintf fullfile "%s%s", s_path, this_dat
					sprintf dff "%s%s%s", s_path, "NQ_", this_dat
					Close/A; 	
					CopyFile/O fullfile as dff
					Close/A; 	
					printf "loading %s file ... filtering ...", dff
					Eddy_CheckAndFilterFirstLine( dff )
					printf "filter done loading ..."
					call_F( dff, datafolder )
					printf "load complete\r"
					
					DeleteFile/Z dff
					if( V_Flag != 0 )
						
						printf "\rpausing for operating system close time"
						Close/A; 	Sleep/T 120
						DeleteFile dff
						printf " %d\r", v_flag
						
					endif
					//LoadWave/P=dat_LoadPATH/O this_dat
					found_dat += 1
				endif
				idex += 1
			while( idex < count )
		endif
		if( found_dat == 0 )
			printf "no dat waves matching criteria were found\r"
		endif
		
			
	else
		printf "No dat files at all found in the directory\r"
	endif
	
	// and clean up afterward
	KillPath/Z dat_LoadPATH
	KillWaves/Z temp_list_of_dat_tw, temp_fileTimes, temp_fileStopTimes, temp_loadThis
	
	//AML_DataFolderBased_SAKN( datafolder, Text2DateTime( "5/1/2012 00:00" ), Text2DateTime( "5/30/2012 00:00" ) )
	SetDataFolder root:
End

// This loader to be used for Laird enclosure data. 
// Concatenate aspect is UNTESTED>
// This loader is to be called manually. Eventually we will write one that is similar to the Eddy files loader above.
// or one that works seamlessly with the STR loader. 
Function Laird_log_loader()

	//Header parsing
	Variable refnum, year, month, day, hour, minute, second, n1, n2, period
	string temp

	Open/D/R refnum
	Open/R refnum as S_fileName
	FReadLine refnum, temp
	FReadLine refnum, temp
	sscanf temp, "START LOGG - %f/%f/%f : %f:%f:%f", month, day, year, hour, minute, second
	FReadLine refnum, temp
	FReadLine refnum, temp
	FReadLine refnum, temp
	sscanf temp, "Sample rate:  %f samples / %f sec", n1, n2

	period = n2/n1
	year = year+2000

	close refnum

	//Load data
	LoadWave/A/J/D/W/K=0/L={6,7,0,0,0} S_fileName
	String firstName = StringFromList(0, S_waveNames)
	Wave firstWave = $firstName

	//construct DateTime wave
	Duplicate $firstName g_Time
	g_Time = date2secs(year, month, day) + 3600*hour + 60*minute + second + period*p
	SetScale d 0, 0, "dat", g_Time

	variable i
	for(i=0;i<(itemsinlist(S_waveNames)); i+=1)
		String thisBaseName =  stringFromList(i, S_wavenames)
		String thisWaveName = "Laird_" + thisBaseName
		wave/z thisWave = $thisWaveName
		if(!waveexists(thisWave))
			// then it's the first load, and we rename
			rename $thisBaseName, $thisWaveName
		else
			// then it's a subsequent load and we concatenate
			ConcatenateWaves( thisWaveName, thisBaseName )
			killwaves/z $thisBaseName
		endif
		

	endfor
		

	// rename or concat time wave
	Wave/z thisTime = $"Laird_datetime"
	if(!waveexists(thisTIme))
		rename g_time, $"Laird_datetime"
	else
		concatenateWaves ( "Laird_datetime", nameofwave(g_time) )
		killwaves/z g_time
	endif

end


Function Eddy_CheckAndFilterFirstLine( fp2check )
	String fp2check
	
	Variable refNum = 0, newRef, len
	String line
	String foo_file
	
	Open/R refNum as fp2check
	if( refNum != 0 )
		freadline refNum, line	
		if( strsearch( line, "\"", 0 ) == -1 )
			Close refNum
			return 0
		endif
		// this means we have to kill off the first line.
		sprintf foo_file, "%s:n_%s", GetPathNameFromFileOrFP(fp2check), GetPathNameFromFileOrFP( fp2check )
		foo_file = RemoveDoubleColon( foo_file )
		Open newRef as foo_file
		do
			Freadline refNum, line
			len = strlen( line )
			if( len == 0 )
				break;
			endif
			fprintf newRef, "%s\n", line
			
		while(1)
		Close refNum
		Close newRef
		Close/A; 	

		DeleteFile/Z fp2check
	 	if( V_Flag != 0 )
			printf "\rpausing for OS close time in line writer PreCopy ... "
			Close/A; 	Sleep/T 120
			DeleteFile/i=0/Z fp2check
			printf " %d\r", v_flag
 	
	 	endif
 		Close/A; 	//Sleep/T 60
		CopyFile/O/i=0 foo_file as fp2check
				Close/A; 	//Sleep/T 60
		DeleteFile/i=0/Z foo_file
		if( V_Flag != 0 )
			printf "\rpausing for OS close time in line writer PostCopy ... "
			Close/A; 	Sleep/T 120
			DeleteFile/i=0/Z foo_file
			printf " %d\r", v_flag
		endif
		
	else
		print "Error trying to open", fp2check
	endif
End



//-------------------------------------------------------------------------------------------------------------------------------
//	QA_NaNmarquis
//
//	This function allows you to NaN points manually on a single trace. 
// It may bonk if you select a non- xy trace
// It will print the command needed to recreate the NaN to the command line for you to copy and archive if desired. 
// Igor’s guess of which wave you are selecting is sometimes bad. It is a problem with the traceFromPixel guess
// You can improve the guess by hiding other traces on the graph. 

// example use: 
// highlight some data in a graph using the graph marquis
// right click in marquis and select "QA_NaNmarquis
// data will be set to NaN
// 
// a command like the following will be printed to the command line: 
//   QA_NaNmarquis(wavex=root:str_source_rtime,wavey=root:N2O,startTime=3701161182.4,stopTime=3701162424.4,minY=336.474,maxY=337.349) //04/13/2021 12:19:42, 04/13/2021 12:40:24

// this command can be copied and run from the command line; or edited as you see fit and run for other traces.
//-------------------------------------------------------------------------------------------------------------------------------
Function QA_NaNmarquee([wavex, wavey, startTime,stopTime,minY,maxY]) : GraphMarquee
	wave/D wavex, wavey
	variable startTime, stopTime, minY, maxY

//	// this wave is the one that you look for bad periods of data
//	String masterwave = "N2O"
//	//this list of waves are other waves taken by the same instrument
//	string others = "CO;H2O_A;" // this can be a list.
//	string classname = "N2O_dips"
//	string notetext = "Manual QAQC via marquis"
	
	
	// in this case, it is being called from the marquis, not from command line
	// and no waves and start times will be specified. 
	if(paramisdefault(startTime))
 
	 	GetMarquee 
	 	variable pixelX, dx, dy, pixelY
		dx = ceil((V_right - V_left)/2)
		dy = ceil((V_top - V_bottom)/2)
		
//		print "horiz:",V_left, V_right
//		print "vert:", V_bottom, V_top
//		
		pixelX = V_left + dx
		pixelY = V_bottom + dy
//		print "center:", pixelX, pixelY
		
		dx = abs(dx); dy=abs(dy);
//		print "dx:",dx, "dy:",dy
		string thisInfo= 	traceFromPixel(pixelX,pixelY,"DELTAX:"+num2str(dx)+";DELTAY:"+num2str(dy))
		
//		// check other possible traces
//		string altInfo1 = traceFromPixel(V_left, V_top,"DELTAX:3;DELTAY:3")
//		string altinfo2 = traceFromPixel(V_left, V_bottom,"DELTAX:3;DELTAY:3")
//		string altinfo3 = traceFromPixel(V_right, V_top,"DELTAX:3;DELTAY:3")
//		string altinfo4 = traceFromPixel(V_right, V_bottom,"DELTAX:3;DELTAY:3")
//		
//		if((stringmatch(thisInfo,altInfo1)||stringmatch(altinfo1,""))  &&  (stringmatch(thisInfo,altinfo2)||stringmatch(altinfo2,""))  &&  (stringmatch(thisInfo,altInfo3)||stringmatch(altinfo3,""))  &&  (stringmatch(thisInfo,altinfo4)||stringmatch(altinfo4,""))  )
//			// then the corners match
//		else
//			print "too many traces on graph. Try plotting only one trace for QA"
//			return -1
//		endif
		
		// sometimes traceFromPixel doesn't seem to find anything. make dx large
		if(stringmatch(thisInfo,""))
			thisInfo = traceFromPixel(pixelX, pixelY,"DELTAX:"+num2str(2*dx)+";DELTAY:"+num2str(2*dy))
		endif
		if(stringmatch(thisInfo,""))
			thisInfo = traceFromPixel(pixelX, pixelY,"DELTAX:"+num2str(4*dx)+";DELTAY:"+num2str(4*dy))
		endif	
		
		string thisTraceName = StringByKey("TRACE",thisInfo)
		
			if(stringmatch (thisTraceName,""))
				print "Aborting QA_NaNmarquis: no wave selected. Try zooming in and avoid selecting multiple traces/axes."
				return -1
			endif
		wave thisYwave = traceNametowaveref("", thisTraceName)
		wave thisXwave = xwavereffromtrace("",thisTraceName)
		
		String thisTraceInfo = TraceInfo("", stringFromList(0,thisTraceName,"#"), str2num(stringfromlist(1,thisTraceName,"#")))
		String thisYaxis = stringbykey("YAXIS", thisTraceInfo)
		string thisXaxis = stringbykey("XAXIS", thisTraceInfo)

		
		GetMarquee $thisYaxis
		minY = V_bottom
		maxY = V_top
			
		GetMarquee $thisXaxis
		
		startTime= V_left
		stopTime = V_right
		
		
		// Now lets get the y wave we want to apply this to. 
		if(!waveexists(thisYwave))
			print "Aborting QA_NaNmarquee: no wave found for ", nameofwave(thisYwave),"."
			return -1
		endif
		
	// otherwise, we are calling this on command line, like in a script,
	// and we know everything we need including waves and times. 	
	else
		wave/z thisYwave = wavey
		wave thisXwave = wavex
		if(!waveexists(thisYwave))
			print "Aborting QA_NaNmarquee: can't find wave ", getwavesdatafolder(wavey,2),". Try specifying entire data folder"
			return-1
		endif
	endif
	
	
	if(numpnts(thisYwave)!=numpnts(thisXwave))
		print "mismatched point numbers. Try running QAQCw_reset"
		return -1 
	endif
	
	// now get to Nan'ing
		
	// use wave to do quickly 
	thisYwave = thisXwave[p] >=startTime && thisXwave[p] <=stopTime && thisYwave[p]>=minY && thisYwave[p] <= maxY ? NaN : thisYwave[p]
	
	string cmdStr
	sprintf cmdStr, "QA_NaNmarquee(wavex=%s,wavey=%s,startTime=%10.1f,stopTime=%10.1f,minY=%7g,maxY=%7g) //%s, %s", getwavesdatafolder(thisXwave,2),getwavesdatafolder(thisYwave,2), starttime,stoptime, minY, maxY, datetime2text(starttime),datetime2text(stoptime)
		
	print cmdStr
	
End

