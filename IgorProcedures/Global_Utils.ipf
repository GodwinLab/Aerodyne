#pragma rtGlobals=1		// Use modern global access method.
#include <Wave Lists>
#include <Concatenate Waves>
/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Scott's global utility ipf
/////////////////////////////////////////////////////////////////////////////////////////////////////////
// graphName is window Name from with procedures or "" for top graph
// Color All Traces on Graph differently -- 	PrimaryColors(graphName)
// 										StackAllAxes( graphName, lo_twink, hi_twink )
// -- Obsolete, Don't use!~					ColorTraceOrAxes( graphName, code ) 
// 										ScaleAllYAxes( graphName )




// Macro Menu
// MAGN 1/31/14
//
// This procedure is for organizing the functions in the Macros menu. At the time this procedure was created the
// code for a particular submenu was in the file that contained the functions called by the submenu. This change
// was undertaken for a couple of reasons. First, there are now quite a few submenus, and it is nice have one
// place to go to organize the menu. Second, identifying the file containing a particular function was not very
// straight forward; the names of some of the procedure files did not relate very well to the macro menu names.
// Third, it is conceivable that one would want multiple procedure files for functions within the same submenu; at
// that point it becomes ambiguous as to which function should have the macro menu setup. Using the
// convention of defining the menu structure here required that the corresponding code be removed from the other
// procedure files. This is a onetime modification; in the future new menu items will be added here and will call a
// separate procedure file. 


Menu "Macros"

	Submenu "Global Utils"
		//"Handy Graph Buttons", HandyGraphButtons() //Global_Utils.ipf
		"Handy Graph Buttons/1", HandyGraphButtons_v2() //Global_Utils.ipf
		"Set Mirror, Pos and StandOff",  MirrorStandPos() //Global_Utils.ipf
		"Stack all axes", StackAllAxesPro()//Global_utils.ipf
		"Clone top graph to data folder", CloneGraphHandler() //Global_Utils.ipf
	End
	
	Submenu "TDLWintel File Loader Functions"
		"STR Files Loader/2", zSTR_initstrpanel() //LoadSPE2.ipf
		"------------------", Execute("")
		"Spectral Files Loader/3", zSPE2_DrawPanel() //LoadSPE2.ipf
	End

	
	Submenu "Data Plots: Allan-Werle, Leak, etc."
		"Allan-Werle Variance/4", Allan_Variance_Panel() //allan_variance.ipf
		"Leak Rate", InitLRPPanel() //spec_plots_1.1.ipf
		"Tuning Rate", Wintel_TuneRateSpecPlot() // SPB_for_LoadSPE.ipf
		"SPTR", InitSPTR() //SPTR5mod2.ipf
		"Mask Panel", mSTR_Panel_and_init() //LoadSPE2.ipf
	End
		
	Submenu "Hitran Functions"
		"Make HIT File", DrawHitManPanel() //aerodyneTools.ipf
		"Do a Spectral Simulation", Initialize_HitranIgor_panel() //HitranIgor11.ipf
	end
	
	Submenu "Other Tools"
		"Doppler Broadening Calc", LineBroaden() //aerodyneTools.ipf
		"Make Inst Lineshape From Cursors",MakeInstrumentalFromCursors() //HitranIgor11.ipf
		"Command Line Remote Access Monitor", IFJP_IgorFtpJournalProcDraw() //Global_Utils.ipf
		"Load and Process Single SMPS Data File", Load_Single_SMPS_Interactive() //Global_Utils.ipf

	//	"Make Convolution Correction Function", Get_ConvolutionCorrectionCurve()
		//		"-------------"
		// Depreciated for Igor 6
		//"OS X Spawn New Igor Process", Igor2("") //Global_Utils.ipf 
		
	End

End


// Usage Notes for the cool functions
// Invoke Handy Graph Buttons when ever you have a graph open and you want
// to zoom in, look at data and move out easily
// Handy Graph Button is a complement to Igor's own marquee
// it makes buttons to zoom out when looking at a portion of data
// scale-y looks to scale all 'y-style' axes, ie. anything not named 'bottom' or 'top'
// within the current x bounds window -- doesn't always work well on logrithmic axes or when 
// different named x axes exist
// scale all y is more useful than most initially suspect 

// ColorTraceOrAxes( graphName, code)
// Use ColorTraceOrAxes( "", 0 ) to give the traces on the graph a different
// color, you can use ColorTraceorAxes( "", 1 ) to give them all a different color and color the axis they
// are associated with too 

// StackAllAxes(graphName, lo_twink, hi_twink)
// this function will take all of the non 'top' or 'bottom' named axes, 
// and set the axis enab flags to display each axis on its own, stacked.
// low_twink and hi_twink are hundreths, or percent to leave as gaps between interior figures
// Call StackAllAxes( "", 0, 0 ) to stack everything with no gaps
// StackAllAxes( "", 1, 1 ) will leave a 2% gap between interior axes
// to use this function properly, the graph must have been created with the different data
// on different axes ie
// Display/L=myFirstAxis snark_wave vs boojum_wave
// AppendToGraph/L=mySecondAxis spot_wave vs boojum_wave
// StackAllAxes( "", 0, 0 ) will set the axis enab for myFirstAxis and mySecondAxis automatically
// axis names can be anything, just not top or bottom [and] the graph can't contain more than top or bottom x axes


// Originally, this code provided by Tim Onasch
// Scott retired the two string constants, and made a wrappper
// for interactive vs. procedural calling -- see Load_Single_SMPS * Proc and Interactive for difference
//User defined variables====
 //Path to local data source
//strconstant local_path_to_data = "C:documents:Aerodyne:AMS field:NEAQS 2004:Ron Brown:AMSDocs:SMPSdata"
//strconstant smps_datafile_name = "RonBrown6.txt"
//User defined variables====
Function Load_Single_SMPS_Interactive()
	
	Variable file_ok = 0
	string FPfilename
	Variable refNum
	Open/D/M="Locate SMPS .txt file to load"/R/T="????" refNum
	if( refNum != 0 )
		Close refNum
	endif
	
	if( strlen( S_filename ) > 0 )
		FPfilename = S_filename
		file_ok = 1
	endif
	
	if( file_ok )
		load_single_smps_Proc( FPfilename )
	else
		if( !file_ok )
			printf "User Cancel or Cannot Locate %s (aborting SMPS load)\r", FPfilename
			return -1
		endif
	endif
End
function load_single_smps_Proc(FPfilename)
	String FPfilename
	
        string sdf = getdatafolder(1)
        SetDatafolder root:; MakeAndOrSetDF( "SMPS" )
        
        if( fileexistsfullpath( FPFilename ) != 0 )
        	printf "Failure to locate for Open -> %s (aborting SMPS load)\r", FPfilename
       	return -1
       endif
       
        LoadWave/J/K=2/V={""," $",0,0}/L={0,0,0,0,1}/n=smps FPfilename
        wave/t smps0
        variable nr=numpnts(smps0)
        string d,t
        variable i,np=0,d1,d2,d3,t1,t2,t3
//Sample Number
        make/o/d/n=0 smps_sample_no
//DateTime Wave
        make/o/d/n=0 smps_date_time
        for (i=0;i<nr;i+=1)
                if (numtype(str2num(smps0[i]))==0)
                        insertpoints i,1,smps_date_time,smps_sample_no
                        smps_sample_no[i]=str2num(stringfromlist(0,smps0[i],"\t"))
                        d=stringfromlist(1,smps0[i],"\t")
                        d1=str2num(stringfromlist(0,d,"/"))
                        d2=str2num(stringfromlist(1,d,"/"))
                        d3=str2num(stringfromlist(2,d,"/"))
                        t=stringfromlist(2,smps0[i],"\t")
                        t1=str2num(stringfromlist(0,t,":"))
                        t2=str2num(stringfromlist(1,t,":"))
                        t3=str2num(stringfromlist(2,t,":"))
                        smps_date_time[i]=date2secs(2000+d3,d1,d2)+t1*3600+t2*60+t3
                        np+=1
                endif
        endfor

//Diameter Wave
        make/o/d/n=0 smps_diameter
        variable nd,j,k=0,l,m
        for (i=0;i<nr;i+=1)
                if (stringmatch(stringfromlist(0,smps0[i],"\t"),"Sample #"))
                        nd=itemsinlist(smps0[i],"\t")
                        for (j=0;j<nd;j+=1)
                                if (numtype(str2num(stringfromlist(j,smps0[i],"\t")))==0)
                                        insertpoints k,1,smps_diameter
                                        smps_diameter[k]=str2num(stringfromlist(j,smps0[i],"\t"))
                                        k+=1
                                endif
                        endfor
                        break
                endif
        endfor

//Number Matrix
        make/o/d/n=(0,k) smps_Nmatrix
        m=0
        l=0
        for (i=0;i<nr;i+=1)
                if (numtype(str2num(smps0[i]))==0)
                        nd=itemsinlist(smps0[i],"\t")
                        insertpoints l,1,smps_Nmatrix
                        for (j=4;j<k+4;j+=1)
                                smps_Nmatrix[l][m]=str2num(stringfromlist(j,smps0[i],"\t"))
                                m+=1
                        endfor
                        l+=1
                        m=0
                endif
        endfor

//Volume Matrix
        duplicate/o smps_Nmatrix,$("smps_Vmatrix")
        wave smps_Vmatrix = $("smps_Vmatrix")
        smps_Vmatrix = pi/6 * smps_diameter[q]^3 * smps_Nmatrix[p][q] / 10^9            //units of um3/cm3/dlogDp x density (1g/cm3) = ug/m3/dlogDp

//Integrate data and calculate mode and geometric mean diameters
        np=dimsize(smps_Nmatrix,0)
        variable nq=dimsize(smps_Nmatrix,1)
        make/o/d/n=(np) smps_integrated_N
        make/o/d/n=(np) smps_integrated_V
        make/o/d/n=(np) smps_mode_dia
        make/o/d/n=(np) smps_Geomean_dia
        smps_Geomean_dia = 0
        make/o/d/n=(np) smps_number_per_dia
        smps_number_per_dia = 0
        make/o/n=(nq)/d smps_dlogDp
        make/o/n=(nq) dist
        smps_dlogDp=log(smps_diameter[p+1])-log(smps_diameter[p])
        smps_dlogDp[nq]=smps_dlogDp[nq-2]
        smps_integrated_N=0
        smps_integrated_V = 0
        for (i=0;i<np;i+=1)
                dist = smps_Nmatrix[i][p]
                wavestats/q dist
                smps_mode_dia[i] = smps_diameter[V_maxloc]
                for (j=0;j<nq;j+=1)
                        smps_geomean_dia[i] += dist[j]*smps_dlogDp[j]*log(smps_diameter[j])
                        smps_number_per_dia[i] += dist[j]*smps_dlogDp[j]
                        smps_integrated_N[i] += smps_Nmatrix[i][j]*smps_dlogDp[j]
                        smps_integrated_V[i] += smps_Vmatrix[i][j]*smps_dlogDp[j]
                endfor
                smps_geomean_dia[i] = 10^(smps_geomean_dia[i]/smps_number_per_dia[i])
        endfor

//Create _im waves for image plotting purposes
        duplicate/o smps_diameter, smps_diameter_im
        duplicate/o smps_date_time, smps_date_time_im
        insertpoints 0,1, smps_diameter_im, smps_date_time_im
        smps_diameter_im[0]=smps_diameter_im[1]-(smps_diameter_im[2]-smps_diameter_im[1])
        smps_date_time_im[0]=smps_date_time_im[1]-(smps_date_time_im[2]-smps_date_time_im[1])
        SetScale d 0,0,"dat", root:SMPS:smps_date_time,root:SMPS:smps_date_time_im

//Kill unnecessary waves
        killwaves dist, smps0

        setdatafolder $sdf
end


Function MirrorStandPos()
	Execute( "ModifyGraph mirror=2,standoff=0, freePos=0, lblPosMode=4, lblPos=50 ")
End

Function BiExponential( w, x )
Wave w; Variable x
	Variable retval

	if( w[0] < 0 )
		w[0] = w[0] * (-1)
	endif
	if( w[2] < 0 )
		w[2] = w[2] * (-1)
	endif
	if( w[1] < 0 )
		w[1] = w[1] * (-1)
	endif
	if( w[3] < 0 )
		w[3] = w[3] * (-1)
	endif
	retval = (w[0] * exp( - w[1] * x )) - (w[2] * exp( - w[3] * x ))

	return retval

End Function
/////////////////////////////////////////////////////////////////////////////////////////////////////////
Function AppendString( thewave, thestring )
	wave/T thewave
	string thestring
	
	Redimension /N=(numpnts(thewave)+1) thewave
	thewave[ numpnts(thewave) ] = thestring
	
End

Function AppendVal( thewave, theval)
Wave thewave
Variable theval

	Redimension /N=(numpnts(thewave)+1) thewave
	thewave[ numpnts(thewave) ] = theval
End
/////////////////////////////////////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////////////////////////////////////////
Function UsefulButtons(ctrlName) : ButtonControl
	String ctrlName

Variable span, new_min, new_max

	String botaxlist = DiscriminatedAxisList( "", "bottom" )
	if( ItemsInList( botaxlist ) == 0 )
		print "In procedure, 'usefulButtons' - cannot determine a 'bottom' axis to use"
		return -1
	endif
	String anybotax = StringFromList( 0, botaxlist )
	if( cmpstr( ctrlName, "tog_left") == 0 )
		GetAxis /Q $anybotax
		span = V_max - V_min
		new_min = V_min - span/2
		new_max = V_max - span/2
		SetAxis $anybotax new_min, new_max
	endif
	if( cmpstr( ctrlName, "tog_right") == 0 )
		GetAxis /Q $anybotax
		span = V_max - V_min
		new_min = V_min + span/2
		new_max = V_max + span/2
		SetAxis $anybotax new_min, new_max
	endif
	if( cmpstr( ctrlName, "widen") == 0 )
		GetAxis /Q $anybotax
		span = V_max - V_min
		new_min = V_min - span/2
		new_max = V_max + span/2
		SetAxis $anybotax new_min, new_max
	endif
	if( cmpstr( ctrlName, "scale_y") == 0 )
		ScaleAllYAxes("")
	endif

	if( cmpstr( ctrlName, "removeHGB") == 0 )
		killcontrol tog_left
		killcontrol tog_right
		killcontrol widen
		killcontrol scale_y
		killcontrol removeHGB
		controlinfo kwcontrolbar
		ControlBar (v_height-22) 
		abort
	endif	
End

Macro HandyGraphButtons()
	PauseUpdate; Silent 1		// building window...
	ShowInfo
	//ShowTools
		controlinfo kwcontrolbar

	Variable width = 55, height = 22
	Variable line = v_height, col_1 = 0 * width+5 , col_2 = width + 5, col_3 = 2 * width + 5 , col_4 = 3 * width + 5,col_5 = 4 * width + 15
	
	ControlBar line + height * 1 // this 1 means there is only one line of buttons right now
	Button tog_left,pos={col_1, line},size={width, height},proc=UsefulButtons,title="<pan left<"
	Button tog_right,pos={col_2, line},size={width,height},proc=UsefulButtons,title=">pan right>"
	Button widen,pos={col_3, line},size={width,height},proc=UsefulButtons,title="<widen>"
	Button scale_y, pos={ col_4, line}, size={width, height}, proc=UsefulButtons, title = "Scale Y"
	Button removeHGB,pos={col_5, line},size={65,height},proc=UsefulButtons,title="Remove",valuecolor=(65535,0,0)
EndMacro
#pragma rtGlobals=1		// Use modern global access method.
#include <ControlBarManagerProcs>
#include <AxisSlider>
#include <Axis Utilities>

//Graphing Control Functions
//	Authored by Scott Herndon and Tim Onasch
//	Aerodyne Research, Inc.
//
//****Purpose:  Ease of panning through graphs with greater control of ranges and motion
//
//****Version 2.0
//	Modification 5/25/2010 - Fixed a minor problem where the HGB2 buttons would not function if the controls were included in 
//	    a graph macro and recreated from the macro.
//****Version 1.9
//	Modification 5/23/2010 - Fixed a problem where the function SetAxisRangeToVisibleData(), which I converted into Y and X
//	   functions in version 1.8, could not deal with multiple versions of the same YWave on the same graph.  Set autoscale X to setscale
//****Version 1.8
//	Modification 5/16/2010 - Fixed problem that the X-scaling and Full-scaling could not work with scaled waves (only worked for XY wave pairs).
//	   by modifying SetAxisRangeToVisibleData() and creating HGB2_SetAxisRngeToVisDat_X() and HGB2_SetAxisRngeToVisDat_Y()
//****Version 1.7
//	Modification 12/1/2009 - checks to see if data is hidden and scales only visible data.  Fixed problem that axisSlider info does not exist for an 
//	    axisSlider if the user has changed graph name after axisSlider was created.
//****Version 1.6
//	Modification 10/17/2009 - fixed problem with "Scale X" button (not sure why "SetAxis /A $anybotax" does not work - works if one does it manually or 
//	   if one goes through the debugger...  Fixed a small bug where "Scale All" scaled y data before x data.
//****Version 1.5
//	Modification 7/30/09 - checks first to see if there are already control buttons and adds HGB2() 
//		controls below any preexisting controls on graph.  Also resizes slider with each button press 
//		to adapt to changing graph sizes.
//****Version 1.4
//	Modification 7/28/09 - added "remove" button and got rid of "remove_HGB2()" macro
//****Version 1.3
//	Modification 4/7/09 - included "remove_HGB2()" macro to remove buttons
//****Version 1.2
//	Modification 2/18/09 - included Scale X button.  Resyncing slider position after each button press now!
//****Version 1.1
//	Modification 1/27/2009 - updated functions to include x and y offsets for Scale Y
//****Version 1.0
//	Modification 1/6/2006 - Modified functions to include Axis slider
//

Macro HandyGraphButtons_v3()
	PauseUpdate; Silent 1		// building window...
	ShowInfo
	
	controlinfo kwcontrolbar
	Variable line = v_height

//Define control button heights and widths
	Variable height = 22
	Variable width = 60 
	variable col_1 = 0 * width, col_2 = width, col_3 = 2*width, col_4 = 3*width, col_5 = 4*width, col_6 = 5*width, col_7 = 6*width, col_8 = 8*width, col_9 = 10*width
	
////Add control below existing controls
//	String CBIdent=""
//	Variable/G gOriginalHeight_hgb = ExtendControlBar("", height, CBIdent) // we append below original controls (if any)
//	String/G CBIdentifier_hgb = CBIdent
//
	ControlBar (line+height*1) // this 1 means there is only one line of buttons right now

	Button tog_left,pos={col_1, line},size={width,height},proc=HGB2_buttons,title="<pan left<"
	Button tog_right,pos={col_2, line},size={width,height},proc=HGB2_buttons,title=">pan right>"
	Button widen,pos={col_3, line},size={width,height},proc=HGB2_buttons,title="<widen>"
	Button narrow,pos={col_4, line},size={width,height},proc=HGB2_buttons,title=">narrow<"
	Button scale_y, pos={ col_5, line}, size={width, height}, proc=HGB2_buttons, title = "Scale Y"
	Button some_y, pos={ col_6, line}, size={width, height}, proc=HGB2_buttons, title = "Some Y"
	Button scale_x, pos={ col_7, line}, size={width, height}, proc=HGB2_buttons, title = "Scale X"
	Button scale_all, pos={ col_8, line}, size={width, height}, proc=HGB2_buttons, title = "Scale All"
	Button remove_cntrls, pos={ col_9, line}, size={width, height}, proc=HGB2_buttons, title = "Remove"
	
	WMAppendAxisSlider()
	WMAxSlPopProc("WMAxSlPop",3,"Resync Position")
//	ControlInfo WMAxSlSl
	controlbar (50+line)
	
EndMacro

// no slider, which is not compatible with graph recreation macros (yet.)
// the problem is in the AxisSlider.ipf
// if there is no root:Packages data folder, we are toast.
// all other controls are identical.

Function HandyGraphButtons_v2()
	PauseUpdate; Silent 1		// building window...
	ShowInfo
	
	controlinfo kwcontrolbar
	Variable line = v_height

//Define control button heights and widths
	Variable height = 22
	Variable width = 60 
	variable col_1 = 0 * width, col_2 = width, col_3 = 2*width, col_4 = 3*width, col_5 = 4*width, col_6 = 5*width, col_7 = 6*width, col_8 = 8*width, col_9 = 10*width
	
////Add control below existing controls
//	String CBIdent=""
//	Variable/G gOriginalHeight_hgb = ExtendControlBar("", height, CBIdent) // we append below original controls (if any)
//	String/G CBIdentifier_hgb = CBIdent
//
	ControlBar (line+height*1) // this 1 means there is only one line of buttons right now

	Button tog_left,pos={col_1, line},size={width,height},proc=HGB2_buttons,title="<pan left<", help={"move horizontally to the left"}
	Button tog_right,pos={col_2, line},size={width,height},proc=HGB2_buttons,title=">pan right>", help = {"move horizontally to the right"}
	Button widen,pos={col_3, line},size={width,height},proc=HGB2_buttons,title="<widen>", help={"zoom out"}
	Button narrow,pos={col_4, line},size={width,height},proc=HGB2_buttons,title=">narrow<", help={"zoom in"}
	Button scale_y, pos={ col_5, line}, size={width, height}, proc=HGB2_buttons, title = "Scale Y", help={"Scale to show all data vertically"}
	Button some_y, pos={ col_6, line}, size={width, height}, proc=HGB2_buttons, title = "Some Y", help={"Scale Y ignoring outliers"}
	Button scale_x, pos={ col_7, line}, size={width, height}, proc=HGB2_buttons, title = "Scale X", help={"Scale to show all data horizontally"}
	Button scale_all, pos={ col_8, line}, size={width, height}, proc=HGB2_buttons, title = "Scale All", help={"Scale to show all data"}
	Button remove_cntrls, pos={ col_9, line}, size={width, height}, proc=HGB2_buttons, title = "Remove", help={"Remove handy graph buttons"}
	
Endmacro
Function HGB2_buttons(ctrlName) : ButtonControl
	String ctrlName

	variable sliderTF=0
	controlinfo WMAxSlSl
	if(strlen(S_recreation)>0)
		sliderTF=1
	endif
	
	if( cmpstr( ctrlName, "remove_cntrls") == 0 )
		killcontrol tog_left
		killcontrol tog_right
		killcontrol widen
		killcontrol narrow
		killcontrol scale_y
		killcontrol some_y
		killcontrol scale_x
		killcontrol scale_all
		killcontrol CBSeparator0
		killcontrol remove_cntrls
		
		variable HGB2height=22
		if(sliderTF)
			killcontrol WMAxSlPop
			killcontrol WMAxSlSl
			HGB2height=50
		endif		
		controlinfo kwcontrolbar
		if(v_height <= HGB2height)
			ControlBar 0 // this is a hack. 
		else
			ControlBar (v_height-HGB2height) //  0 removes the control bar, but (v_height-50) should only remove hgb2 controls
		endif
		return 0
	endif	
	
	Variable span, new_min, new_max

////Find information on all axes on plot
//	string list_of_axes = AxisList("")
//	variable no_of_axes = itemsinlist(list_of_axes)
//	
////Determine how many X-axes there are on plot
//	string wave_names = tracenamelist("",";",1+4)	//only look at visible traces - NOT including hidden traces
//	
//	wave x_wave = XWaveRefFromTrace("",stringfromlist(0,wave_names))
////	string test = NameofWave(x_wave)[0,strlen(NameofWave(x_wave))-3]+"msk"

//Define "anybotax" for slider and button controlled x-axis scaling and motion
	String botaxlist = HGB2_DiscrimAxisList( "", "bottom" )
	if( ItemsInList( botaxlist ) == 0 )
		print "In procedure, 'usefulButtons' - cannot determine a 'bottom' axis to use"
		return -1
	endif
	String anybotax = StringFromList( 0, botaxlist )

// Need to test if the HGB on chosen plot is working.  If user renamed graph (ctrl-y), then the slider is not active anymore and needs to be reset
	String grfName= WinName(0, 1)
	
	if(sliderTF)
		string folderNameStr = "root:Packages:WMAxisSlider:"+grfName
		if (!DataFolderExists(folderNameStr))
			String dfSav= GetDataFolder(1)
			// this convoluted thing makes sure the multiple levels of DF are created
			NewDataFolder/S/O root:Packages
			NewDataFolder/S/O root:Packages:WMAxisSlider
			NewDataFolder/S/O $("root:Packages:WMAxisSlider:"+grfName)
			String/G gAxisName=anybotax
			Variable/G gLeftLim,gRightLim
			GetAxis /Q $anybotax
			gLeftLim = V_min
			gRightLim = V_max
			String/G CBIdentifier = ""
			string pos_str, size_str
			ControlInfo /w=$grfName CBSeparator0	// GroupBox
			sscanf S_recreation,"GroupBox %s,%s,%s", CBIdentifier,pos_str,size_str
			Variable/G gLastAuto=1
			SetDataFolder dfSav
		endif
	endif
//

	if( cmpstr( ctrlName, "tog_left") == 0 )
		GetAxis /Q $anybotax
		span = V_max - V_min
		new_min = V_min - span/2
		new_max = V_max - span/2
		SetAxis $anybotax new_min, new_max
	endif
	if( cmpstr( ctrlName, "tog_right") == 0 )
		GetAxis /Q $anybotax
		span = V_max - V_min
		new_min = V_min + span/2
		new_max = V_max + span/2
		SetAxis $anybotax new_min, new_max
	endif
	if( cmpstr( ctrlName, "widen") == 0 )
		GetAxis /Q $anybotax
		span = V_max - V_min
		new_min = V_min - span/2
		new_max = V_max + span/2
		SetAxis $anybotax, new_min, new_max
	endif
	if( cmpstr( ctrlName, "narrow") == 0 )
		GetAxis /Q $anybotax
		span = V_max - V_min
		new_min = V_min + span/4
		new_max = V_max - span/4
		SetAxis $anybotax, new_min, new_max
	endif
	if( cmpstr( ctrlName, "scale_y") == 0 )
		ScaleAllYAxes(grfName)
	endif
	if( cmpstr( ctrlName, "some_y") == 0 )
		SomeScaleAllYAxes(grfName)
	endif
	if( cmpstr( ctrlName, "scale_x") == 0 )
//		setaxis/a $anybotax
		HGB2_SetAxisRngeToVisDat_X()
//		SetAxis/A $anybotax	//problem - this does not work in functions, for some reason.
	endif
	if( cmpstr( ctrlName, "scale_all") == 0 )
//		setaxis/a $anybotax
		HGB2_SetAxisRngeToVisDat_X()
		ScaleAllYAxes(grfName)
	endif

	if(sliderTF)
	//Resync Slider Position to New axes positions
	WMAxSlPopProc("WMAxSlPop",3,"Resync Position")
	//Resize Slider to new graph widths
	WMAxSlPopProc("WMAxSlPop",4,"Resize")
	endif

End

Function/T HGB2_DiscrimAxisList( graphName, axis_Type )
	string graphName, axis_Type
	String return_str =""
	Variable left = cmpstr( LowerStr(axis_type), "left" )
	Variable bottom = cmpstr( LowerStr(axis_type), "bottom" )
	Variable right = cmpstr( LowerStr(axis_type), "right" )
	Variable top = cmpstr( LowerStr(axis_type), "top" )
	if( (left!=0) %& (bottom!=0) %& (right!=0) %& (top!=0) )
		return return_str
	endif
	String list = AxisList( graphName )
	Variable idex = 0
	String info
	do
		info = StringByKey( "AXTYPE", AxisInfo( graphName, StringFromList( idex, list ) ))
		if( cmpstr( LowerStr(info), Lowerstr(axis_Type) ) != 0 )
			list = RemoveListItem( idex, list )
		else
			idex += 1
		endif
	while( idex < ItemsInList( list ))
	return_str = list
	return return_str
End


// This function is decomissioned and replaced by ScallAllYaxes(). 
// This function does not work with hidden traces or traces with mis-matched points. 
Function HGB2_SetAxisRngeToVisDat_Y()
//Modified IgorPro Function from SetAxisRangeToVisibleData()
	String WindowName
	String VAxes,YWaves
	String ThisHAxis, ThisVAxis, TrialVAxis
	string ThisYWave, ThisXWave
	WAVE /Z ThisYWaveRef
	WAVE /Z ThisXWaveRef
	String TrInfo
	
	Variable i,j,k
	Variable MyVMin, MyVMax
	Variable XMin, XMax
	Variable hidden_flag = 0	//0 = visible, 1 = hidden, 2 = hidden with removal from autoscale
	string offset_str 	//= StringByKey("offset(x)",TrInfo,"=")
	variable xoffset = 0
	variable yoffset = 0
	
	WindowName=WinName(0,1)
	if (strlen(WindowName) == 0)
		Abort "No graphs"
	endif
	DoWindow/F $WindowName
	
	VAxes=HVAxisList("",0)	//List of all Vertical Axes
	if (strlen(VAxes) == 0)
		Abort "No vertical axes in top graph"
	endif
	
	YWaves = tracenamelist(WindowName,";",1)	//List of all YWaves on graph

	for (i=0;i<itemsinlist(VAxes);i+=1)	//loop over all Vertical axes
		ThisVAxis=StringFromList(i, VAxes)
		MyVMin=NaN
		MyVMax=NaN
		for (j=0;j<itemsinlist(YWaves);j+=1)	//loop over all YWaves in graph, including multiple versions of the same ywave
			WAVE ThisYWaveRef = WaveRefIndexed(WindowName, j, 1)
			ThisYWave = stringfromlist(j,YWaves)
			TrInfo=TraceInfo(WindowName, ThisYWave, 0)
			//skip hidden data
			hidden_flag = str2num(StringByKey("hideTrace(x)",TrInfo,"="))
			if (hidden_flag>0)	//i.e. hidden_flag = 1 for hidden and 2 for hidden without autoscale
				continue
			endif
			//Find any x- or y- offsets (addition/subtraction only at this point)
			offset_str = StringByKey("offset(x)",TrInfo,"=")
			sscanf offset_str, "{%f,%f}", xoffset, yoffset
			if (numtype(xoffset)>0)
				xoffset = 0
			endif
			if (numtype(yoffset)>0)
				yoffset = 0
			endif				

			TrialVAxis=StringByKey("YAXIS",TrInfo)
			if (cmpstr(TrialVAxis, ThisVAxis) == 0)	//compare TrialVAxis from each wave to the ThisVAxis, if the same then find VMin and VMax
				ThisHAxis = StringByKey("XAXIS",TrInfo)
				GetAxis/Q $ThisHAxis
				XMin=V_min
				XMax=V_max
				ThisXWave=StringByKey("XWAVE",TrInfo)
				if (strlen(ThisXWave) == 0)	//check if there is an associated XWave, if not, then use XMin and XMax from the associated HAxis
					WaveStats/Q/R=(XMin,XMax) ThisYWaveRef
					if (numtype(MyVMin) == 2)
						MyVMin=V_min
					else
						if (V_min < MyVMin)
							MyVMin=V_min
						endif
					endif
					if (numtype(MyVMax) == 2)
						MyVMax=V_max
					else
						if (V_max > MyVMax)
							MyVMax=V_max
						endif
					endif
				else		//else if there is an associated XWave, then use the XWave to get the VMin and VMax
					WAVE ThisXWaveRef = $(StringByKey("XWAVEDF",TrInfo)+ThisXWave)
					if(numpnts(thisXwaveRef)==numpnts(thisYwaveref)) // equal numbers of points
						for (k=0;k<numpnts(ThisXWaveRef);k+=1)
							if (( (ThisXWaveRef[k]+xoffset) >= XMin) && ( (ThisXWaveRef[k]+xoffset) <= XMax))
								if (numtype(MyVMin) == 2)
									MyVMin=ThisYWaveRef[k]+yoffset
								else
									if ( (ThisYWaveRef[k]+yoffset) < MyVMin)
										MyVMin=ThisYWaveRef[k] + yoffset
									endif
								endif
								if (numtype(MyVMax) == 2)
									MyVMax=ThisYWaveRef[k]+yoffset
								else
									if ( (ThisYWaveRef[k]+yoffset) > MyVMax)
										MyVMax=ThisYWaveRef[k]+yoffset
									endif
								endif
							endif
						endfor // end for loop through thisXwaveRef
					else // unequal numbers of points
						String xrange = StringByKey("XRANGE",TrInfo)
						string yrange = StringByKey("YRANGE",TrInfo)
						if(stringmatch(xrange, "[\*]") && stringmatch(yrange, "[\*]")) // unequal points, and no sub-range specified.
						// this should not happen but will if wavelengths is altered after plotting. 
							variable xstart = 0, ystart=0
							variable xend=min(numpnts(thisXwaveRef)-1,numpnts(thisYwaveRef)-1), yend=xend, koffset=0
							if( xend - xstart == yend - ystart)
								variable substart, subEnd
								substart = binarysearch(thisXwaveRef, Xmin)
								subEnd = binarysearch(thisXwaveRef,Xmax)
								if(subStart== -1)
									subStart = 0
								endif
								if(subEnd == -2)
									subEnd = numpnts(thisXwaveRef)-1
								endif
								
								WaveStats/Q/R=[subStart+koffset,subEnd+koffset] ThisYWaveRef
								
								if (numtype(MyVMin) == 2)
									MyVMin=V_min
								else
									if (V_min < MyVMin)
										MyVMin=V_min
									endif
								endif
								if (numtype(MyVMax) == 2)
									MyVMax=V_max
								else
									if (V_max > MyVMax)
										MyVMax=V_max
									endif
								endif
								
							endif
						
						else	// subrange specified
							string xstarts, xends, ystarts, yends
							xstarts = stringfromList(0, xrange, ","); xstarts = replacestring("[",xstarts,""); xstart = str2num(xstarts)
							xends = stringfromList(1, xrange, ","); xends = replacestring("]",xends,""); xend = str2num(xends)
							ystarts = stringfromList(0, yrange, ","); ystarts = replacestring("[",ystarts,""); ystart=str2num(ystarts)
							yends = stringfromList(1, yrange, ","); yends = replacestring("]",yends,""); yend = str2num(yends)
							// asterisks lead to nans.
							if(numtype(xstart)==2)
								xstart = 0
							endif
							if(numtype(xend)==2)
								xend = numpnts(thisXwaveRef)-1
							endif
							if(numtype(ystart)==2)
								ystart = 0
							endif
							if(numtype(yend)==2)
								yend = numpnts(thisYwaveRef)-1
							endif
							koffset = ystart - xstart
							if( xend - xstart == yend - ystart)
								substart = binarysearch(thisXwaveRef, Xmin)
								subEnd = binarysearch(thisXwaveRef,Xmax)
								if(subStart== -1)
									subStart = 0
								endif
								if(subEnd == -2)
									subEnd = numpnts(thisXwaveRef)-1
								endif
								
								WaveStats/Q/R=[subStart+koffset,subEnd+koffset] ThisYWaveRef
								
								if (numtype(MyVMin) == 2)
									MyVMin=V_min
								else
									if (V_min < MyVMin)
										MyVMin=V_min
									endif
								endif
								if (numtype(MyVMax) == 2)
									MyVMax=V_max
								else
									if (V_max > MyVMax)
										MyVMax=V_max
									endif
								endif
								
							endif // end equal points in subranges. 
						
						endif // end subrange
					endif // end inequal points
				endif // end of scaled vs xy wave pair selection
			endif
		endfor
		SetAxis $ThisVAxis,MyVMin,MyVMax
	endfor
end

Function HGB2_SetAxisRngeToVisDat_X()
//Modified IgorPro Function from SetAxisRangeToVisibleData()
	String WindowName
	String HAxes,YWaves
	String ThisHAxis, ThisVAxis, TrialHAxis
	string ThisYWave, ThisXWave
	WAVE /Z ThisYWaveRef
	WAVE /Z ThisXWaveRef
	String TrInfo
	
	Variable i,j,k
	Variable MyHMin, MyHMax
	Variable XMin, XMax
	Variable hidden_flag = 0	//0 = visible, 1 = hidden, 2 = hidden with removal from autoscale
	string offset_str 	//= StringByKey("offset(x)",TrInfo,"=")
	variable xoffset = 0
	variable yoffset = 0
	
	WindowName=WinName(0,1)
	if (strlen(WindowName) == 0)
		Abort "No graphs"
	endif
	DoWindow/F $WindowName
	
	HAxes=HVAxisList("",1)	//List of all Horizontal Axes
	if (strlen(HAxes) == 0)
		Abort "No vertical axes in top graph"
	endif
	
	YWaves = tracenamelist(WindowName,";",1)	//List of all YWaves on graph

	for (i=0;i<itemsinlist(HAxes);i+=1)	//loop over all Horizontal axes
		ThisHAxis=StringFromList(i, HAxes)
		MyHMin=NaN
		MyHMax=NaN
		for (j=0;j<itemsinlist(YWaves);j+=1)	//loop over all YWaves in graph, including multiple versions of the same ywave
			WAVE ThisYWaveRef = WaveRefIndexed(WindowName, j, 1)
			ThisYWave = stringfromlist(j,YWaves)
			TrInfo=TraceInfo(WindowName, ThisYWave, 0)
			//skip hidden data
			hidden_flag = str2num(StringByKey("hideTrace(x)",TrInfo,"="))
			if (hidden_flag>0)	//i.e. hidden_flag = 1 for hidden and 2 for hidden without autoscale
				continue
			endif
			//Find any x- or y- offsets (addition/subtraction only at this point)
			offset_str = StringByKey("offset(x)",TrInfo,"=")
			sscanf offset_str, "{%f,%f}", xoffset, yoffset
			if (numtype(xoffset)>0)
				xoffset = 0
			endif
			if (numtype(yoffset)>0)
				yoffset = 0
			endif

			TrialHAxis=StringByKey("XAXIS",TrInfo)
			if (cmpstr(TrialHAxis, ThisHAxis) == 0)	//compare TrialHAxis from each wave to the ThisHAxis, if the same then find Min and Max
				WAVE /Z ThisXWaveRef = XWaveRefFromTrace(WindowName, ThisYWave)	//$(StringByKey("XWAVEDF",TrInfo)+StringByKey("XWAVE",TrInfo))
				if (!waveexists(ThisXWaveRef)) 		//If the XWave does not exist, use YWave x-scaling				//((strlen(ThisXWave)==0) || (numtype(strlen(ThisXWave))>0))
					XMin = pnt2x(ThisYWaveRef,0)
					XMax = pnt2x(ThisYWaveRef,(numpnts(ThisYWaveRef)-1))
				elseif(numpnts(ThisXwaveRef)==0)
					// do nothing
				else								//If the XWave does exist, then find Max and Min
					wavestats/q ThisXWaveRef
					XMin = V_min
					XMax = V_max
				endif
				/////////////////////////
				if (numtype(MyHMin) == 2)
					MyHMin=XMin+xoffset
				else
					if (XMin+xoffset < MyHMin)
						MyHMin=XMin+xoffset
					endif
				endif
				if (numtype(MyHMax) == 2)
					MyHMax=XMax+xoffset
				else
					if (XMax+xoffset > MyHMax)
						MyHMax=XMax+xoffset
					endif
				
				endif
				//////////////////////
			endif
		endfor
		SetAxis $ThisHAxis,MyHMin,MyHMax
	endfor
end

Function/T RemoveDuplicateListItems( list, [separator] )
	String list
	String separator
	String loc_separator = ";"
	
	if( !ParamIsDefault( separator ) )
		loc_separator = separator
	endif
	
	String retlist = "", this_item
	Variable idex, count  = ItemsInList( list, loc_separator )
	for( idex = 0; idex < count; idex += 1 )
		this_item = StringFromList( idex, list, loc_separator )
		if( WhichListItem( this_item, retlist, loc_separator ) == -1 )
			retlist = retlist + this_item + loc_separator
		endif
	endfor
	return retlist
End

Function RemoveTracesOfThisAxis( graphName, doom_ax )
	String graphName, doom_ax
	
	String trace_list = TraceNameList( graphName, ";", 3 ) // include contours
	Variable idex = 0, count = ItemsInList( trace_list )
	
	String this_trace, tinfo, yaxis, xaxis
	Variable remove_this = 0
	if( count > 0 )
		do
			this_trace = StringFromList( idex, trace_list )
			tinfo = TraceInfo( graphName, this_trace, 0 )
			remove_this = 0
			yaxis = StringByKey( "YAXIS", tinfo )
			if( cmpstr( LowerStr( doom_ax ), LowerStr( yaxis ) ) == 0 )
				remove_this = 1
			endif
			
			xaxis = StringByKey( "XAXIS", tinfo )
			if( cmpstr( LowerStr( doom_ax ), LowerStr( xaxis ) ) == 0 )
				remove_this = 1
			endif
			
			if( remove_this )
				RemoveFromGraph/W=$graphName/Z $this_trace
			endif			
			idex += 1
		while( idex < count )
	
	endif
	
	String image_list = ImageNameList( graphName, ";" ), this_image, iinfo
	idex = 0; count = ItemsInList( image_list )
	if( count > 0 )
		do
			this_image = StringFromList( idex, image_list )
			iinfo = ImageInfo( graphName, this_image, 0 )
			remove_this = 0
			yaxis = StringByKey( "YAXIS", iinfo )
			if( cmpstr( LowerStr( doom_ax ), LowerStr( yaxis ) ) == 0 )
				remove_this = 1
			endif
			
			xaxis = StringByKey( "XAXIS", iinfo )
			if( cmpstr( LowerStr( doom_ax ), LowerStr( xaxis ) ) == 0 )
				remove_this = 1
			endif
			
			if( remove_this )
				RemoveImage/W=$graphName/Z $this_image
			endif			
			idex += 1
		while( idex < count )
	
	endif
	
End

Function StripGraph( win )
	String win
	
	Variable idex = 0
	String trace_list = TraceNameList( win, ";", 1 ), this_trace
	Variable count = itemsinlist( trace_list )
	if( count > 0 )
		do
			this_trace = StringFromList( idex, trace_list )
			
			removefromgraph/z/w=$win $this_trace
			idex += 1
		while( idex < count )
	endif
End

////// This Function is a keeper, it will decode and shift a UTC wave as recorded by Tron
/////  It jams the result into made wave sam_utc or 'seconds after midnight by utc'
Function DecodeUTCWave( raw_utc, time_zone_hrs )
Wave raw_utc
Variable time_zone_hrs

// function will correct utc to seconds after midnight

Duplicate /O raw_utc sam_utc, hrs_utc, mins_utc
hrs_utc = Floor( raw_utc/10000)
mins_utc = Floor((raw_utc - hrs_utc*10000)/100)
sam_utc = raw_utc - hrs_utc*10000 - mins_utc*100

sam_utc += 60*mins_utc
sam_utc += 3600 * (hrs_utc - time_zone_hrs )

KillWaves hrs_utc, mins_utc

End

// This next function will rescale all of the y-axes on a plot so that for a given
// x range, the 'autoscale' of over the present range

Function ScaleAllYAxes( graph_name)
String graph_name

Variable low_x, high_x
Variable num_of_axes
Variable num_of_traces

Variable this_y_max, this_y_min, this_avg, this_sdev, this_y_logMin, this_y_logMax // terminology, this refers to the current instance or trace
Variable glob_y_max, glob_y_min // refers to the ultimate or universal max and min (all traces)
Variable glob_y_logMax, glob_y_logMin // the max for log plots
String axes_list, this_axis_name, trace_list, this_trace_name
Variable axis_index, trace_index

String trace_x_info, trace_x_wave, trace_x_wave_df, x_axis_name, cmd, xrange, yrange
Variable low_point, high_point

// This is a bug, I think, do it later
//GetAxis/W=$graph_name/Q bottom
//low_x = V_min; high_x = V_max

// part one determine how many left or right axes on plot
axis_index = 0
axes_list =DiscriminatedAxisList( graph_name, "left" ) + DiscriminatedAxisList( graph_name, "right" )

num_of_axes = ItemsInList( axes_list )
if( num_of_axes < 1 )
	//Print "Error in Global Utility: AutoYAllAxes -- too few axes"
	return -1
endif
//Wave wave_ref
do
	// within part one step two cycle through all traces associated with that axis
	this_axis_name = StringFromList(axis_index, axes_list )
	trace_index = 0
	trace_list = ListTracesOnAxis( this_axis_name, graph_name )
	// determine y_u_max, and y_u_min
	GetAxis/W=$graph_name/Q $this_axis_name
	glob_y_min = V_max; glob_y_max = V_min // YES these are switched on purpose
	glob_y_logMin = V_max; glob_y_logMax = V_min
	do
		this_trace_name = StringFromList( trace_index, trace_list )	
		trace_x_info = TraceInfo( graph_name, this_trace_name, 0 )
		trace_x_wave = StringByKey( "XWAVE", trace_x_info )
		x_axis_name = StringByKey( "XAXIS", trace_x_info )
		yrange = stringByKey("YRANGE", trace_x_info)
		xrange = stringbykey("XRANGE", trace_x_info)
		//printf "for %s :::%s on %s gives ", this_trace_name, x_axis_name, graph_name
		GetAxis/W=$graph_name/Q $x_axis_name
		low_x = V_min; high_x = V_max
		//printf "the min as %g and teh max as %g\r", low_x, high_x
		if( strlen( trace_x_wave )< 1 )
			// it is an x scaled wave and we get the information via wavestats
			
			if(stringmatch(yrange,"")||cmpstr(yrange,"[*]",0)==0)
				WaveStats/Q /R=(low_x, high_x) TraceNameToWaveRef( graph_name, this_trace_name )
				low_point = V_min; high_point = V_max
			else // we've defined a sub-range
				WaveStats/Q /R=(low_x, high_x) TraceNameToWaveRef( graph_name, this_trace_name )
				low_point = V_min; high_point = V_max				
			endif
		else
			// it is an x - y pair and we need the infor mation from the x_wave 
			Wave wx = XwaveRefFromTrace( graph_name, this_trace_name )
			
			if(stringmatch(xrange,"")||cmpstr(xrange,"[*]",0)==0)
				// with out of order pairs this bugs... I don't know how to fix it at the moment
				// this bugged with non-monotonic
				low_point = BinarySearch( wx, low_x ); high_point = BinarySearch( wx, high_x )
			else // defined sub-range for x. 
				variable low_ref, high_ref
				sscanf xrange, "[%f,%f]", low_ref, high_ref
				low_point = BinarySearch( wx, low_x ); high_point = BinarySearch( wx, high_x )
			
				if(low_point < low_ref && low_point >=0)
					low_point = low_ref
				endif
				if(high_point > high_ref && high_point >=0)
					high_point = high_ref
				endif
			endif
			if( low_point == -1 )
				low_point = 0
			elseif(low_point == -2)
				low_point = numpnts(wx)
			endif
			if( high_point == -2 )
				high_point = numpnts( wx )
			elseif(high_point == -1)
				high_point = 0
			endif
			if(high_point < low_point)
				variable temp
				temp = low_point
				low_point=high_point
				high_point=temp
			endif
			//printf "In Scale Y:  low_pnt:%g & low_x:%g t hi_pnt:%g and hi_x:%g", low_point, low_x, high_point, high_x
			wave wy = TraceNameToWaveRef( graph_name, this_trace_name )
			
			if(stringmatch(yrange,"")||cmpstr(yrange,"[*]",0)==0)
				if(high_Point>low_Point && numpnts(wy) >= high_point && numpnts(wy) >= low_point)
					WaveStats/Q /R=[low_point, high_point] wy
				else
					// this is an invalid wave pair to scale
					V_min = nan
					V_max = nan
					V_avg = nan
					V_sdev = nan
				endif
			elseif(igorVersion()>=7)
				// a sub-range has been specified
				variable thisyrange
				sscanf yrange, "[*][%f]", thisYrange
				if(numtype(thisYrange)!=2)
					#if( igorVersion() >= 7 )
						WaveStats/Q /RMD=[low_point, high_point][thisYrange] wy
					#else
						printf "Scale-y on matrix vector plotting not supported until igor version 7\r"
					#endif
				endif
			endif

			//printf "   Result in %g, %g for Y's\r", V_min, V_max
		endif
		
		if(high_point != -1 && low_point != -2 && numtype(high_point)!=2 && numtype(low_point)!=2 && low_point != high_point) // don't try to scale traces that don't have data in range.
			this_y_min = V_min; this_y_max = V_max; this_avg = V_avg; this_sdev = V_sdev
			if( this_y_min < glob_y_min )
				glob_y_min = this_y_min
			endif
			if( this_y_max > glob_y_max )
				glob_y_max = this_y_max
			endif
			if(this_avg - this_sdev*3 < glob_y_logMin)
				if(this_avg - this_sdev*3 > 0)
				glob_y_logMin = this_avg - this_sdev*3
				elseif(this_avg - this_sdev*2 > 0)
				glob_y_logMin = this_avg - this_sdev*2
				elseif(this_avg - this_sdev > 0)
				glob_y_logMin = this_avg - this_sdev
				elseif(this_avg > 0)
				glob_y_logMin = this_avg 
				else
				glob_y_logMin = 10e-9
				endif
			endif
			if(this_avg + this_sdev*3  > glob_y_logMax)
				if(this_avg + this_sdev*3 < inf)
				glob_y_logMax = this_avg + this_sdev*3
				elseif(this_avg < inf)
				glob_y_logMax = this_avg
				else
				glob_y_logMax = 10e9
				endif
			endif
			
		endif
		trace_index += 1
	while( trace_index < ItemsInList( trace_list ) )
	//Print "Axis Name: "+this_axis_name+" y(max): "+num2str(glob_y_max)+" y(min): "+num2str(glob_y_min)
	
	// can we querry the axis name here
	// and if it is log scale, make sure we don't set to negative or zero
	String info_again = AxisInfo(graph_name, this_axis_name )
	String log_str = StringByKey( "log(x)", info_again, "=" )
	Variable log_val = str2num( log_str )
	if( log_val == 1 )
		if( glob_y_min <= 0 )
			glob_y_min = glob_y_logMin
		endif
		
	endif
	if(glob_y_max < glob_y_min)
		temp=glob_y_min
		glob_y_min = glob_y_max
		glob_y_max = temp
	endif
	SetAxis/W=$graph_name/N=1 $this_axis_name glob_y_min, glob_y_max
	axis_index += 1
while( axis_index < num_of_axes  )
End

// The goal of this function will be to scale all y axes without "blips".
Function SomeScaleAllYAxes( graph_name)
String graph_name

Variable low_x, high_x
Variable num_of_axes
Variable num_of_traces

Variable this_y_max, this_y_min, this_y_avg, this_y_sdev, this_y_logMin, this_y_logMax // terminology, this refers to the current instance or trace
Variable glob_y_max, glob_y_min // refers to the ultimate or universal max and min (all traces)
Variable glob_y_logMax, glob_y_logMin // the max for log plots
String axes_list, this_axis_name, trace_list, this_trace_name
Variable axis_index, trace_index

String trace_x_info, trace_x_wave, trace_x_wave_df, x_axis_name, cmd, xrange, yrange
Variable low_point, high_point

// This is a bug, I think, do it later
//GetAxis/W=$graph_name/Q bottom
//low_x = V_min; high_x = V_max

// part one determine how many left or right axes on plot
axis_index = 0
axes_list =DiscriminatedAxisList( graph_name, "left" ) + DiscriminatedAxisList( graph_name, "right" )

num_of_axes = ItemsInList( axes_list )
if( num_of_axes < 1 )
	//Print "Error in Global Utility: AutoYAllAxes -- too few axes"
	return -1
endif
//Wave wave_ref

do
	// within part one step two cycle through all traces associated with that axis
	this_axis_name = StringFromList(axis_index, axes_list )
	trace_index = 0
	trace_list = ListTracesOnAxis( this_axis_name, graph_name )
	// determine y_u_max, and y_u_min
	GetAxis/W=$graph_name/Q $this_axis_name
	glob_y_min = V_max; glob_y_max = V_min // YES these are switched on purpose
	glob_y_logMin = V_max; glob_y_logMax = V_min

	do
		this_trace_name = StringFromList( trace_index, trace_list )	
		trace_x_info = TraceInfo( graph_name, this_trace_name, 0 )
		trace_x_wave = StringByKey( "XWAVE", trace_x_info )
		x_axis_name = StringByKey( "XAXIS", trace_x_info )
		yrange = stringByKey("YRANGE", trace_x_info)
		xrange = stringbykey("XRANGE", trace_x_info)
		//printf "for %s :::%s on %s gives ", this_trace_name, x_axis_name, graph_name
		GetAxis/W=$graph_name/Q $x_axis_name
		low_x = V_min; high_x = V_max
		//printf "the min as %g and teh max as %g\r", low_x, high_x
		if( strlen( trace_x_wave )< 1 )
			// it is an x scaled wave and we get the information via
			WaveStats/Q /R=(low_x, high_x) TraceNameToWaveRef( graph_name, this_trace_name )
			low_point = V_min; high_point = V_max
		else
			// it is an x - y pair and we need the infor mation from the x_wave 
			Wave wx = XwaveRefFromTrace( graph_name, this_trace_name )
			if(stringmatch(xrange,"")||cmpstr(xrange,"[*]",0)==0)
				// with out of order pairs this bugs... I don't know how to fix it at the moment
				// this bugged with non-monotonic
				low_point = BinarySearch( wx, low_x ); high_point = BinarySearch( wx, high_x )
			else // defined sub-range for x. 
				variable low_ref, high_ref
				sscanf xrange, "[%f,%f]", low_ref, high_ref
				low_point = BinarySearch( wx, low_x ); high_point = BinarySearch( wx, high_x )
			
				if(low_point < low_ref && low_point >=0)
					low_point = low_ref
				endif
				if(high_point > high_ref && high_point >=0)
					high_point = high_ref
				endif
			endif
			
			if( low_point == -1 )
				low_point = 0
			elseif(low_point == -2)
				low_point = numpnts(wx)
			endif
			if( high_point == -2 )
				high_point = numpnts( wx )
			elseif(high_point == -1)
				high_point = 0
			endif
			if(high_point < low_point)
				variable temp
				temp = low_point
				low_point=high_point
				high_point=temp
			endif
			//printf "In Scale Y:  low_pnt:%g & low_x:%g t hi_pnt:%g and hi_x:%g", low_point, low_x, high_point, high_x
			wave wy = TraceNameToWaveRef( graph_name, this_trace_name )
			
				
			if(high_Point>low_Point && numpnts(wy) >= high_point && numpnts(wy) >= low_point)		
				if(stringmatch(yrange,"")||cmpstr(yrange,"[*]",0)==0)
					if(high_Point>low_Point && numpnts(wy) >= high_point && numpnts(wy) >= low_point)
						WaveStats/Q /R=[low_point, high_point] wy
					else
						// this is an invalid wave pair to scale
						V_min = nan
						V_max = nan
					endif
				elseif(igorVersion()>=7)
					// a sub-range has been specified
					variable thisyrange
					sscanf yrange, "[*][%f]", thisYrange
					if(numtype(thisYrange)!=2)

						#if( igorVersion() >= 7 )
							WaveStats/Q /RMD=[low_point, high_point][thisYrange] wy
						#else
							printf "Scale-y on matrix vector plotting not supported until igor version 7\r"
						#endif

					endif
				endif
				
				
			else
				// this is an invalid wave pair to scale
				V_min = nan
				V_max = nan
			endif
			//printf "   Result in %g, %g for Y's\r", V_min, V_max
		endif
		
		if(high_point != -1 && low_point != -2 && numtype(high_point)!=2 && numtype(low_point)!=2 && low_point != high_point) // don't try to scale traces that don't have data in range.
			this_y_min = V_min; this_y_max = V_max; this_y_Sdev = V_sdev; this_y_avg = V_avg
			if( this_y_min < glob_y_min && this_y_min >= this_y_avg - this_y_Sdev*3)
				glob_y_min = this_y_min
			elseif(this_y_avg - this_y_sdev*3 < glob_y_min && this_y_avg - this_y_sdev*3 > this_y_min)
				glob_y_min= this_y_avg - this_y_sdev*3
			endif
			if( this_y_max > glob_y_max && this_y_max <= this_y_avg + this_y_Sdev*3 )
				glob_y_max = this_y_max
			elseif(this_y_avg + this_y_Sdev*3 > glob_y_max && this_y_avg + this_y_sdev*3 < this_y_max)
				glob_y_max = this_y_avg + this_y_Sdev*3
			endif
			if(this_y_avg < glob_y_logMin)
				glob_y_logMin = this_y_avg
			endif
			if(this_y_avg > glob_y_logMax)
				glob_y_logMax = this_y_avg
			endif
		endif
		trace_index += 1
	while( trace_index < ItemsInList( trace_list ) )
	//Print "Axis Name: "+this_axis_name+" y(max): "+num2str(glob_y_max)+" y(min): "+num2str(glob_y_min)
	
	// can we querry the axis name here
	// and if it is log scale, make sure we don't set to negative or zero
	String info_again = AxisInfo(graph_name, this_axis_name )
	String log_str = StringByKey( "log(x)", info_again, "=" )
	Variable log_val = str2num( log_str )
	if( log_val == 1 )
		if( glob_y_min <= 0 )
			glob_y_min = glob_y_logMin
		endif
	endif
	if(glob_y_max < glob_y_min)
		temp=glob_y_min
		glob_y_min = glob_y_max
		glob_y_max = temp
	endif
	SetAxis/W=$graph_name/N=1 $this_axis_name glob_y_min, glob_y_max
	axis_index += 1
while( axis_index < num_of_axes  )
End


Function /T ListTracesOnAxis( axis_name, graph_name )
String axis_name, graph_name

String return_list = ""
String list_of_traces = TraceNameList( graph_name, ";", 2^0 + 2^2 ) // this omits hidden and contour traces.
Variable trace_index = 0, num_of_traces_to_check = ItemsInList( list_of_traces )
String info_str, this_axis_name
String name_of_trace

do
	name_of_trace = StringFromList( trace_index, list_of_traces )
	info_str = TraceInfo( graph_name, name_of_trace , 0)
	this_axis_name = StringByKey( "YAXIS", info_str )
	if( cmpstr( this_axis_name, axis_name )== 0 )
		return_list = return_list + name_of_trace + ";"
	endif
	trace_index += 1
while( trace_index < num_of_traces_to_check )

return return_list
End

//////////////////////////////////////////////////////////////////////////////




Function/T ReturnListofDFs()
string returnlist = "root:"
string data_folder_list = DataFolderDir(1)
data_folder_list = StringByKey( "FOLDERS", data_folder_list )

variable num_folders = ItemsInList( data_folder_list, ",")
variable idex = 0
do
	returnlist = returnlist + StringFromList( idex, data_folder_list, ", " ) + ";"
	idex += 1
while( idex < num_folders )
variable double_semicolon = strsearch( returnlist, ";;", 0) 
if( double_semicolon > 0 )
	if( double_semicolon == strlen( returnlist ) - 1 )
		returnlist = returnlist[0, double_semicolon ]
	endif
endif

 return returnlist
End
Function /T BroadListOfWaves()
ControlInfo /W=Panel0 Source_DF
if( DataFolderExists( S_value ) )
	SetDataFolder S_value
endif
return WaveListQualified( "", 4, 0,0, 0, 0, 2, "", "", "", 0 )
End

Function FileExists( path, filename )
	String path, filename
	

	Variable refNum
	Open/R/Z/P=$path refNum as filename
	if( v_flag == 0 )
		close refNum
		return 0
	else
		return v_flag
	endif
		
End
Function FileExistsFullPath( fullFilename )
	String fullFilename
	
	Variable refNum
	Open/R/Z refNum as fullFilename
	if( v_flag == 0 )
		close refNum
		return 0
	else
		return v_flag
	endif
End

// Usage Notes for FileIO( sourcePath, sourceFile, destPath, destFile, control_code )
// sourcePath and destPath are strings containing the drive letter and path to
// the files sourceFile and destFile (for example "C:myData:thisExperiment:")
// control code
// if bit 0 is set, FileIO does 'move' the data -- in other words control_code = 0,2,4,8 etc
// if bit 0 is not set, FileIO makes a copy of the file -- control_code = 1,3,5,7 etc
// if bit 1 is set, FileIO simply deletes the source file and does not copy the data at all
// in this case the destPath and destFile are ignored -- control_code = 2,3,6,7 etc.
// Return Codes -- If FileIO returns -43 it means the source file doesn't exist
// if FileIO returns -3, something very odd occured with the attempt to creat the dest path
// If FileIO returns -2 the path doesn't exist, returns -1 flow didn't execute in function
// if FileIO returns 1 you can be reasonably sure the operation was performed properly
Function FileIO( sourcePath, sourceFile, destPath, destFile, control_code )
String sourcePath, sourceFile, destPath, destFile
Variable control_code

KillPath/Z CopyFromPath
NewPath/O/Q/Z CopyFromPath, sourcePath
PathInfo CopyFromPath
if( V_flag == 0 )
	return -2
endif
V_flag = 0
if( control_code %& 2 )
	// then we are to delete this file, no questions asked
	OpenNotebook/N=CopyTempBook/P=CopyFromPath/Z/V=0 sourceFile
	if( v_flag != 0 )
		// error opening file return to calling function for error handling
		return -4
	endif
	DoWindow/K/D CopyTempBook
	return V_flag
endif
// Now the remaining question is when copying file, do we move or creat a copy?
NewPath/O/Q/Z/C CopyToPath, destPath
PathInfo CopyToPath
if( V_flag == 0 )
	// shouldn't ever be here
	return -3
endif

if( (control_code %& 1) == 0 )
	V_flag = 0
	OpenNotebook/N=CopyTempBook/P=CopyFromPath/Z/V=0 sourceFile
	if( V_flag != 0 )
		return -4
	endif
	SaveNotebook/O/P=CopyToPath/S=2 CopyTempBook as destFile
	if( v_flag != 0 )
		return -4
	endif
	DoWindow/K CopyTempBook
	return 1
endif
if( (control_code %& 1 ) == 1 )
	V_flag = 0
	OpenNotebook/N=CopyTempBook/P=CopyFromPath/Z/V=0 sourceFile
	if( V_flag != 0 )
		return -4
	endif
	SaveNotebook/O/P=CopyToPath/S=2 CopyTempBook as destFile
	if( v_flag != 0 )
		return -4
	endif
	DoWindow/K copytempbook
	OpenNotebook/N=CopyTempBook/P=CopyFromPath/Z/V=0 sourceFile
	if( V_flag != 0 )
		return -4
	endif
	DoWindow/K/D CopyTempBook
	return 1
endif
// there should be no way of getting here, return generic error
return -1

End

// interp through nan usage notes
// InterpThruNan( dest_sw, source_xw, source_yw, lag, code )
// use code == 0 for real interp( x - lag, source_xy, source_yw )
// use code == 1 for scaled 2 scaled interp( x - lag, source_yw.x, source_yw.y )
Function VanDerCorput(num, base)
	Variable num
	Variable base
	
	Variable numer, denom
	Variable n = num
	Variable myp = 0
	Variable myq = 1;
	if( num == 0 )
		return 0
	endif
	do
		myp = Floor( myp * base + Mod(n , base ));
		myq = Floor( myq * base);
		n = Floor( n/base);
	while( n > 0 )
	
	numer = myp;
	denom = myq;
	
	do
		n = myp;
		myp = Mod( myq, myp);
		myq = n;
	while( myp > 0 )
		
	numer = Floor(numer / myq);
	denom = Floor( denom / myq );
	
	//printf "num %d \t denom %d\r", numer, denom
	return numer/denom
End
Function GetVDCSequence( VDC_Index, count )
	Wave VDC_index
	Variable count
	
	VDC_index = Round(VanDerCorput( p, 2 ) * count)
	Duplicate/O VDC_index, VDC_p, VDC_origP
	VDC_p = p
	VDC_origP = p
//	Sort VDC_index, VDC_index, VDC_p
	Variable idex, herecount = numpnts( VDC_Index ), fdex, this_index
	idex = 0
	do
		this_index = VDC_index[idex]
		fdex = BinarySearch( VDC_p, this_index )
		if( fdex < 0 )
			// this_index is less than the remainders on the board
			// it is the same result as needing to keep it for later
			DeletePoints idex, 1, VDC_index
		else
			if( VDC_p[fdex] == this_index  )
				// then we have found an index in P wave we want to take off the board
				DeletePoints fdex, 1, VDC_p
				idex += 1
			else
				// this index has already been removed from VDC_p and needs to be deleted from VDC_index
				DeletePoints idex, 1, VDC_index
				// do NOT advance idex
			endif
		endif
	while( idex < numpnts( VDC_index) )
	for( idex = 0; idex < numpnts( VDC_p ); idex += 1 )
		// these are remaining points
		AppendVal( VDC_index, VDC_p[idex] )
	endfor
End
Function InterpThruNan( dest_sw, source_xy, source_yw, lag, code )
	Wave dest_sw, source_xy, source_yw
	Variable lag, code
	
	if( ( code != 0 ) & ( code != 1 ) )
		return -1
	endif
	
	if( code == 1 )
		Duplicate/O source_yw, itn_source_xw
		Duplicate/O source_yw, itn_source_yw
		itn_source_xw = pnt2x( itn_source_yw, p )
	endif
	
	if( code == 0 )
		Duplicate/O source_xw, itn_source_xw
		Duplicate/O source_yw, itn_source_yw	
	endif
	Duplicate/O source_yw, itn_mask_w
	itn_mask_w = source_yw/source_yw
	itn_source_xw *= itn_mask_w
	
	Sort itn_source_xw, itn_source_xw, itn_source_yw, itn_mask_w
	Variable idex = numpnts( itn_source_xw ) - 1
	do
		if( numtype( itn_source_xw[idex] ) == 2 )
			DeletePoints idex, 1, itn_source_xw, itn_source_yw, itn_mask_w
			idex = numpnts( itn_source_xw ) - 1
		else
			idex = -1
		endif
	while( idex > 0 )
	dest_sw = interp( x - lag, itn_source_xw, itn_source_yw )
	KillWaves/Z itn_source_xw, itn_source_yw, itn_mask_w
End 
// Usage Note SAM2Secs
// sam is seconds after midnight one wishes to convert
// secs is a 2104_seconds value which is 'representative' of the date you wish to specify
// tolerance is a number of seconds within which the function may assume the sam and secs could be 'off by' before
// the lower of the two dates should be applied
// code -- -1 implies sam clock is slow
// code -- 1 implies sam clock is fast
Function SAM2Secs( sam, secs, tolerance, code )
Variable sam, secs, tolerance,code

Variable max_day = 3600 * 24
Variable quick_sam = secs2sam( secs )
Variable just_date_seconds = secs - quick_sam
Variable mod_out = Mod( sam, max_day )
Variable sam_just_after = 0, sam_just_before = 0
Variable secs_just_after = 0, secs_just_before = 0

if( code == 0 )
	return just_date_seconds + mod_out
endif

if( (mod_out > tolerance ) %& ( mod_out < max_day - tolerance ) )
	return just_date_seconds + mod_out
endif

if( (mod_out >= 0 ) %& ( mod_out <= max_day - 2 * tolerance ) )
	sam_just_after = 1; sam_just_before = 0
elseif( (mod_out <= max_day) %& (mod_out >= max_day - 2 * tolerance) )
	sam_just_after = 0; sam_just_before = 1
endif

if( (quick_sam >= 0) %& ( quick_sam <= max_day - 2*tolerance ))
	secs_just_after = 1; secs_just_before = 0
elseif( (quick_sam <= max_day) %& (quick_sam >= max_day - 2*tolerance) )
	secs_just_after = 0; secs_just_before = 1
endif
//printf "%s\tSAMA:%g  SAMB:%g\t\t%s\tSECA:%g SECB:%g\r", secs2time(sam,1), sam_just_after, sam_just_before, secs2time(secs,1), secs_just_after, secs_just_before
// we are within the tolerance around midnight -- two cases exist secs clock is ahead of sam clock or vice versa
//
if( code == 1)
// then the calling function is telling us that the sam clock is slower than secs clock
	if( sam_just_before %& secs_just_before )
		return just_date_seconds + mod_out
	endif
	if( sam_just_before %& secs_just_after )
		return just_date_seconds - max_day + mod_out
	endif
	if( sam_just_after %& secs_just_after )
		return just_date_seconds + mod_out
	endif
	if( sam_just_after %& secs_just_before )
		Print "Error in SAM2Secs:  calling function said secs clock was ahead of sam clock, yet logic table determined otherwise"
		return -1
	endif
endif

if( code == -1)
// then the calling function is telling us that the sam clock is faster than secs clock
	if( sam_just_before %& secs_just_before )
		return just_date_seconds + mod_out
	endif
	if( sam_just_after %& secs_just_before )
		return just_date_seconds + max_day + mod_out
	endif
	if( sam_just_after %& secs_just_after )
		return just_date_seconds + mod_out
	endif
	if( sam_just_before %& secs_just_after )
		Print "Error in SAM2Secs:  calling function said secs clock was behind sam clock, yet logic table determined otherwise"
		return -1
	endif
endif	
			
	

End

// Secs2SAM( secs2104 )
Function Secs2SAM( secs2104 )
	Variable secs2104
	Variable ret_val = 0
	String short_date = secs2date( secs2104, 0 )
	String long_date = secs2date( secs2104, 2 )
	Variable month,day,year
	Variable slash = strsearch( short_date, "/", 0 )
	month = str2num( short_date[0, slash-1] )
	day = str2num( short_date[ slash+1, strsearch( short_date, "/", slash+1 )])
	year = str2num( long_date[ strlen(long_date)-5, strlen(long_date) ])
	
	ret_val = secs2104 - date2secs( year, month, day )

return ret_val
End

// Secs2DateHourMins( secs2104 )
Function Secs2DateHourMins( secs2104 )
	Variable secs2104
	Variable ret_val = 0
	String short_date = secs2date( secs2104, 0 )
	String long_date = secs2date( secs2104, 2 )
	Variable month,day,year
	Variable slash = strsearch( short_date, "/", 0 )
	month = str2num( short_date[0, slash-1] )
	day = str2num( short_date[ slash+1, strsearch( short_date, "/", slash+1 )])
	year = str2num( long_date[ strlen(long_date)-5, strlen(long_date) ])
	
	ret_val = secs2104 - date2secs( year, month, day )

return ret_val

End

Function Secs2JulianDay( now )
	Variable/D now
	
	String date_str=secs2date(now,0)
	String year_str = stringfromlist( 2, date_str, "/" )
	String month_str = stringfromlist( 0, date_str, "/" )
	String day_str = stringfromlist( 1, date_str, "/" )
	
	Variable year = str2num( year_str )
	if( year < 39 )
		year += 2000
	else
		if( year < 100 )
			year += 2100
		endif
	endif
	Variable month = str2num( month_str )
	Variable day = str2num( day_str )
	Variable remainder, yearoffset, secs_in_day = 24 * 3600
	
	yearoffset = Date2Secs( year, 1, 1 )
	
	remainder = now - yearoffset
	
	variable julianDayOfYear = remainder/secs_in_day + 1 // Jan 1st is 001. 
	
	return JulianDayOfYear
	
End

// see also JulianDecimal2DateTime
Function Secs2JulianDecimal(now)
	Variable/D now
	
	String date_str=secs2date(now,0)
	String year_str = stringfromlist( 2, date_str, "/" )
	String month_str = stringfromlist( 0, date_str, "/" )
	String day_str = stringfromlist( 1, date_str, "/" )
	
	Variable year = str2num( year_str )
	if( year < 39 )
		year += 2000
	else
		if( year < 100 )
			year += 2100
		endif
	endif
	
	Variable month = str2num( month_str )
	Variable day = str2num( day_str )
	Variable remainder, yearoffset, secs_in_day = 24 * 3600
	
	yearoffset = Date2Secs( year, 1, 1 ) // offset from Jan 1st. 
	
	remainder = now - yearoffset
	
	variable julianDayOfYear = remainder/secs_in_day + 1 // Jan 1st is 001. 
	
	return JulianDayOfYear
	
End
Function Military2Secs( hour, mins, secs )
Variable hour, mins, secs
	return hour*3600 + 60*mins + secs
end
Function NumSubStrInStr( str, sub )
String str, sub

Variable idex = 0, count = 0
Variable length = strlen( str )

do
	idex = strsearch( str, sub, idex )
	if( idex >= 0 )
		count += 1
		idex += 1
	else
		idex = length
	endif
while( idex < length )
return count
End

Function test_sam_2_secs()

Variable interval = 1
Variable end_time = military2secs( 0, 1, 0 )
String the_time
Make/T/O/N=0 the_wave
Make/D/O/N=0 the_idex, the_datesecs
Variable today = datetime - secs2sam(datetime)
Variable sent_datesecs
Variable idex = Military2Secs( 12+11, 59, 0 ), returned, run_through = 0
do
	sent_datesecs = today + idex + 10
	returned = SAM2Secs( mod(idex, 3600*24), sent_datesecs, 30, 1 )
	
	sprintf the_time, "Date:%s, Time:%s", secs2date( returned, 0 ), secs2time( returned, 1)
	AppendString( the_wave, the_time )
	AppendVal( the_idex, mod(idex, 3600*24) )
	AppendVal( the_datesecs, sent_datesecs )
	
	idex += interval
while( idex < end_time + 3600*24 )

End


// Usage Notes for StackAllAxes
// StackAllAxes looks for all left axes and stacks them
// on graphName
// lo_twink and hi_twink are the number of hundredth to inwardly twink the middle axes by
Function StackAllAxes(graphName, lo_twink, hi_twink)
String graphName
Variable lo_twink, hi_twink

String axes_list = AxisList( graphName ), this_ax, this_ax_type
axes_list = RemoveFromList(  "top", axes_list)
axes_list = RemoveFromList( "bottom", axes_list)
Variable num_axes = ItemsInList( axes_list )

if( num_axes == 0 )
	return -1
endif
Variable kdex = 0
do
	this_ax = StringFromList( kdex, axes_list )
	this_ax_type = StringByKey( "AXTYPE", AxisInfo( graphName, this_ax ) )
	if( (cmpstr( lowerstr( this_ax_type), "top" ) == 0)      %|     (cmpstr( lowerstr( this_ax_type), "bottom" ) == 0) )
		axes_list = RemoveFromList( this_ax, axes_list )
	endif
	kdex += 1
while( kdex < num_axes )
	 num_axes = ItemsInList( axes_list )
Variable idex = 0, interval = 1/num_axes, low_bound, high_bound
	// make sure twink aren't too big
	if(lo_twink/100 > interval/3)
		lo_twink = interval/10 * 100
	endif
	if(hi_twink/100 > interval/3)
		hi_twink = interval/10 * 100
	endif

do
	this_ax = StringFromList( idex, axes_list )
	low_bound = idex * interval
	high_bound = (idex + 1) * interval
	
	if( (idex > 0) %& (idex < num_axes + 1 ) )
		low_bound += lo_twink/100;	high_bound -= hi_twink/100
	endif
	if( low_bound < 0 )
		low_bound = 0
	endif
	if( high_bound > 1 )
		high_bound = 1 
	endif
	ModifyGraph axisEnab($this_ax)={low_bound,high_bound}
	idex += 1
while( idex < num_axes )
return 1

End

//	--------------------------------------------------------------------
//	StackAllAxesPro
//	--------------------------------------------------------------------
//	this is a multipurpose axis scaling function
//	Parameter		Description
//	axList			optional list of axes to include in scaling. 
//						special names _Lgap_ and _Rgap_ can be used to "skip" a spot.
//						this is useful for stc scaling with 2 lasers
//	gap				gap, in percentage, between axes
//	startPercent	location, in percentage, to start and stop the scaling
//	stopPercent
// 	OverlapList		list of axes to overlap. 	e.g. C2H6,CH4;H2O,N2O		
//					use with FixAxisOverlap() for pretty results
//	LeftAndRight		0 or no option at all to stack all axes on top of each other
//						1 to stack left on left and right on right. Use the axList
//						parameter with "_Lgap_" and _Rgap_" special names to leave spaces
//	Sample usage
// StackAllAxesPro()
// StackAllAxesPro(leftAndRight=1, gap=8)
// StackAllAxesPro(leftAndRight=1, gap=5, axList="left;N2O;dt;CO_A;_Rgap_;H2O",stopPercent=30)
// StackAllAxesPro(leftAndRight=1, gap=5,startPercent=10, stopPercent=70)
// StackAllAxesPro(overlaplist="i626_ax,i627_ax;Tref_ax,Traw_ax")
//	--------------------------------------------------------------------
Function StackAllAxesPro([axlist,gap,startPercent,stopPercent,LeftAndRight,overlapList])
	variable gap, startPercent,stopPercent,leftAndRight
	string axlist,overlapList
	
	GetWindow/z  kwTopWin title
	String winNameStr = WinName(0, 1, 1)
	if( WinType( winNameStr ) != 1 ) // this is a graph
		return -1
	endif
	
	String axisL = axisList(""), vertAxisL="", vertAxisR=""

	if(paramisdefault(gap))
		gap = 0.02
	else
		gap/=100
	endif
	
	if(paramisdefault(startPercent))
		startPercent=0
	else
		startPercent/=100
	endif
	
	if(paramisdefault(stopPercent))
		stopPercent=1
	else
		stopPercent/=100
	endif
	
	if(paramisdefault(leftAndRight))
		leftAndRight=0
	endif
	
	if(paramisdefault(overlapList))
		overlapList=""
	endif
	
	if(!paramisdefault(axList))
		axisL = axList		
	endif
	if(startPercent > stopPercent)
		variable savepercent = startPercent
		startPercent=stopPercent
		stopPercent=savePercent
	endif
	
	// get left vs right axes
	variable i
	for(i=0;i<itemsinlist(axisL);i+=1)
		string thisAxis = stringFromList(i,axisL)
		String axisI = AxisInfo("",thisAxis)
		string thisType = StringByKey("AXTYPE", AxisI)
		if(stringmatch(thisType,"left"))
			vertAxisL += thisAxis + ";"		
		elseif(stringmatch(thisType,"right"))		
			vertAxisR += thisAxis + ";"		
		elseif(stringmatch(thisAxis,"_Lgap_"))
			vertAxisL += "_Lgap_;"
		elseif(stringMatch(thisAxis,"_Rgap_"))
			vertAxisR += "_Rgap_;"
		endif
	endfor
	
	// get overlap list:
	i=0
	variable j=0, firstRight=0
	for(i=0;i<itemsinlist(overLapList,";");i+=1)
		String thisSet = stringFromList(i,overlapList,";")
		variable listdex=-1
		for(j=0;j<itemsinlist(thisSet,",");j+=1)
			string thisSub = stringFromList(j,thisSet,",")
			string firstOfKind=""
			firstright=0
			
			// find position in list
			
				variable ldex, rdex,thisDex
				ldex = whichListItem(thisSub, vertAxisL, ";",0,0)
				rdex = whichListItem(thisSub, vertAxisR, ";",0,0)

				
				if(j==0)
					if(ldex >= 0)
							
							firstRight=0
							firstOfKind = thisSub
							vertAxisL = removefromlist(thisSub, vertAxisL, ";",0)
							vertAxisL = AddListItem(thisSub, vertAxisL, ";", itemsinlist(vertAxisL))
							listdex = itemsinlist(vertAxisL)-1 	// first of its kind
					elseif(rdex >= 0)
							firstRight=1
							firstOfKind=thisSub
							vertAxisR = removefromlist(thisSub, vertAxisR, ";",0)
							vertAxisR = AddListItem(thisSub, vertAxisR, ";", itemsinlist(vertAxisR))
							listDex = itemsinlist(vertaxisR) // first of its kind	
					endif
				endif

				if(j>0)
					if(ldex>=0)
						// remove from global list
						thisDex = whichListItem(thisSub, vertAxisL,";",0,0)
						vertAxisL = removefromlist(thisSub, vertAxisL, ";",0)
						if(thisDex < listDex && !firstRight)
							listDex -=1
						endif
					endif		
					if(rdex>=0)
						// remove from global list
						thisDex = whichListItem(thisSub, vertAxisR,";",0,0)
						vertAxisR = removefromlist(thisSub, vertAxisR, ";",0)
						if(thisDex < listDex && firstRight)
							listDex -=1
						endif
					endif		
				
					if(ldex>=0 || rdex>=0)
					if(firstRight)
						vertAxisR = AddListItem(thisSub+",", vertAxisR, ";", listDex)
						vertAxisR = replacestring(",;", vertAxisR, ",") // so now list looks like a;b,b2,b3;c;d;e
					else
						// then even right axes can get added to left lift
						// add to list
						vertAxisL = AddListItem(thisSub+",", vertAxisL, ";", listDex)
						vertAxisL = replacestring(",;", vertAxisL, ",") // so now list looks like a;b,b2,b3;c;d;e										
					endif
					endif
				endif
		endfor
	endfor
	variable count, totCount
	if(leftAndRight)
		count = max(itemsinlist(vertAxisL),itemsinlist(vertAxisR))
	else
		count = itemsinlist(vertAxisL)+itemsInlist(vertAxisR)
	endif
	totcount = itemsinlist(vertAxisL)+itemsInlist(vertAxisR) 
	
	variable span = (stopPercent-startPercent)
	if(span>1)
		span=1
	endif
	
	variable each = (span - (count-1)*gap)/count
	variable start,stop
	
	// too small gaps?
	if(each<gap/3)
		gap = span/count * 0.1
		each = (span - (count-1)*gap)/count
	endif
	
	variable last= startPercent-gap, isRight=0
	string thisAx
	for(i=0;i<totCount;i+=1)
		
		if(i<itemsInList(vertAxisL))
			thisAx = stringFromList(i,vertAxisL,";")
			isRight=0
		else
			thisAx = stringFromList(i-itemsInList(vertAxisL,";"),vertAxisR,";")
			isRight=1
		endif
	

		if(leftAndRight && i==itemsInList(vertAxisL,";"))// first right axis
			last = startPercent-gap
		endif	
		start=last+gap
		stop=last+gap+each
		if(start<0)
			start=0
		endif
		if(stop>stopPercent)
			stop=stopPercent
		endif

		variable subcount = itemsInList(thisAx,",")
		for(j=0;j<subCount; j+=1)
			thisAxis = stringFromList(j, thisAx, ",")
			
			if(!stringmatch(thisAxis,"_*gap_"))
				ModifyGraph axisEnab($thisAxis)={start,stop}
			endif
		endfor
		
		last = last+gap+each
	endfor 

End


////////////////////////////////////////////////////////////////////////////////////
//	fixAxisOverlap([threshold,gap,shrinkX])
//
// threshold is the minimum overlap tolerated in percent of plot area 
// gap is a gap in percent plotted area.
// shrinkX=1				will shrink the bottom x axis so traces don't overlap axis.
// threshold=3			any axes that overlap more than 3% of plot area will be fixed.
// gap = 8				will use a gap between axes of 8% of the plot area. 
// 
// examples:
// 
Function FixAxisOverlap([threshold,gap,shrinkX])
	variable threshold,gap,shrinkX
	if(paramisdefault(threshold))
		threshold=0
	endif
	if(paramisdefault(gap))
		gap=5
	endif
	if(paramisdefault(shrinkX))
		shrinkx=0
	endif
	GetWindow/z  kwTopWin title
	String winNameStr = S_Value
	if( WinType( winNameStr ) != 1 ) // this is a graph
		return -1
	endif
	
	if(gap>=100)
		gap/=100
	endif
	if(gap<0)
		gap=0
	endif
	if(threshold>=100)
		threshold/=100
	endif
	if(threshold<0)
		threshold=0
	endif
	
	
	String axisL = axisList(""), vertAxisL="", vertAxisR=""
	variable maxLoffset=0,maxRoffset=0
	
	// get left vs right axes
	variable i
	for(i=0;i<itemsinlist(axisL);i+=1)
		string thisAxis = stringFromList(i,axisL)
		String axisI = AxisInfo("",thisAxis)
		string thisType = StringByKey("AXTYPE", AxisI)
		string thisSpan = stringbykey("axisEnab(x)", AxisI,"=",";")
		thisSpan = replacestring("{",thisSpan,"");thisSpan = replacestring("}",thisSpan,"")
		
		if(stringmatch(thisType,"left"))
			vertAxisL += thisAxis + ";"		
		elseif(stringmatch(thisType,"right"))		
			vertAxisR += thisAxis + ";"		
		elseif(stringmatch(thisAxis,"_Lgap_"))
			vertAxisL += "_Lgap_;"
		elseif(stringMatch(thisAxis,"_Rgap_"))
			vertAxisR += "_Rgap_;"
		endif

		variable this1,this2,comp1,comp2
		this1= str2num(stringfromlist(0,thisSpan,","))
		this2= str2num(stringfromlist(1,thisSpan,","))
		
	endfor
	
	
	variable j,listdex
	string thisList 
	for(listdex=0;listdex<2;listdex+=1)
		if(listdex==0)
			thisList = vertAxisL
		else
			thisList = vertAxisR
		endif
	for(i=0;i<itemsinlist(thisList);i+=1)
		thisAxis = stringFromList(i,thisList)
		axisI = AxisInfo("",thisAxis)
		thisSpan = stringbykey("axisEnab(x)",axisI,"=",";")
		thisSpan = replacestring("{",thisSpan,"");thisSpan = replacestring("}",thisSpan,"")
		this1= str2num(stringfromlist(0,thisSpan,","))
		this2= str2num(stringfromlist(1,thisSpan,","))
			
		ModifyGraph lblPosMode($thisAxis)=4
		ModifyGraph freePos($thisAxis)={0,kwFraction}
		
		for(j=0;j<itemsinlist(thisList);j+=1)
			variable match=0
		if(j!=i)
			string compAxis = stringFromList(j,thisList)
			String axisIc= AxisInfo("",compAxis)
			string compSpan = stringbykey("axisEnab(x)",axisIC,"=",";")
			compSpan = replacestring("{",compSpan,"");compSpan = replacestring("}",compSpan,"")	
			comp1= str2num(stringfromlist(0,compSpan,","))
			comp2= str2num(stringfromlist(1,compSpan,","))
			
			Variable overlap 
		
			// ranges have some overlap here:
			if(max(comp2,this2)-min(comp1,this1) < ((comp2-comp1)+(this2-this1)))
				match +=1
				// calculate overlap as a percent of the plot area
				overlap = (min(comp2, this2) - max(comp1, this1)) *100
				
				if(overlap > threshold)
					
					// then we do the offset. 
					ModifyGraph lblPosMode($compAxis)=4
					ModifyGraph freePos($compAxis)={match*gap/100,kwFraction}
					// and remove from list so it doesn't get done twice
					thisList = removefromlist(compAxis, thisList)
					if(listdex==0)
						if(maxLoffset < match*gap/100)
							maxLoffset = match*gap/100
						endif
					else
						if(maxRoffset < match*gap/100)
							maxRoffset = match*gap/100
						endif
					endif
				endif
			endif //end overlap check

		endif // don't match self
		endfor
	endfor
	endfor
	
	 // shrink horiz axis
	 if(shrinkX)
	 	ModifyGraph axisEnab(bottom)={maxLoffset,1-maxRoffset}
	 endif

End







// This function makes a few stylistic changes to Igor's axis display
Function FormatAxes()
	ModifyGraph standoff=0,freePos=0
	ModifyGraph lblPosMode=4,lblPos=50
	ModifyGraph dateInfo(bottom)={0,1,0}
End

Function ColorTraceOrAxes( graphName, code)
String graphName
Variable code


Make/O CCRed = 	{65280,        0,        0,        0, 65280, 52224, 30464, 0 }
Make/O CCBlue = 	{       0, 52224, 15872, 65280, 43520,        0, 30464, 0 }
Make/O CCGreen =	{       0,        0, 65280, 65280,        0, 20736, 30464, 0 }

Make/O/N=16 red_chart, green_chart, blue_chart
//					0		1		2		3		4		5			6		7		8		9		10		11		12		13		14		15
red_chart = { 		0,	65280,	65280/4, 	0, 	65280/2, 	65280/2, 	0,	65280/2,		0,		0,	65280/2,	65280/2,		0,	65280/4,		0,		0}
green_chart = { 		0,		0,	65280/2, 	0, 	65280/2, 		0, 	65280/2,		0,	65280/2,		0,	65280/2,		0,	65280/2,		0,		0,	65820/4}
blue_chart = { 		0,		0,	65280/4, 65280, 	65280/2, 	65280, 	65280/2,		0,		0,	65280/2,		0,	65280/2,	65280/2,		0,	65280/4,		0}

String axes_list = AxisList( graphName ), this_ax
axes_list = RemoveFromList(  "top", axes_list)
axes_list = RemoveFromList( "bottom", axes_list)

String this_trace, trace_list = TraceNameList( graphName, ";", 1), trace_info, just_wave

Variable instance, num_axes = ItemsInList( axes_list ), number_sign
if( num_axes == 0 )
	return -1
endif
Variable idex = 0, jdex, correct_color = 0, axis_colored = 0
do
	this_ax = StringFromList( idex, axes_list )
	jdex = 0
	do
		this_trace = StringFromList( jdex, trace_list )
		number_sign = strsearch( this_trace, "#", 0 )
		if( number_sign > 0 )
			just_wave = this_trace[0, number_sign - 1 ]
			instance = str2num( this_trace[number_sign+1, strlen( this_trace )] )
			trace_info = TraceInfo( graphName, just_wave, instance )
		else
			trace_info = TraceInfo( graphName, this_trace, 0 )
		endif
		if( cmpstr( StringbyKey( "YAXIS", trace_info ), this_ax ) == 0 )
			if( num_axes == 1 )
				correct_color = jdex
			else
				correct_color = idex
			endif
			ModifyGraph rgb($this_trace)=(CCRed[correct_color], CCBlue[correct_color], CCGreen[correct_color])
	
			if( (code %& 1) %& (axis_colored) )
				ModifyGraph axRGB($this_ax)=(CCRed[correct_color], CCBlue[correct_color], CCGreen[correct_color])
				ModifyGraph tlblRGB($this_ax)=(CCRed[correct_color], CCBlue[correct_color], CCGreen[correct_color])
				ModifyGraph alblRGB($this_ax)=(CCRed[correct_color], CCBlue[correct_color], CCGreen[correct_color])
				ModifyGraph gridRGB($this_ax)=(CCRed[correct_color], CCBlue[correct_color], CCGreen[correct_color])
				axis_colored = 1
			endif
		endif
		jdex += 1
	while( jdex < ItemsInList( trace_list ) )
	idex += 1 
while( idex < num_axes )	

KillWaves /Z CCRed, CCBlue, CCGreen, red_chart, blue_chart, green_chart

End
Function PrimaryColors(graphName)
	String graphName
	
	Wave/Z pc_red=pc_red
	Wave/Z pc_green=pc_green
	Wave/Z pc_blue=pc_blue
	Make/O/N=26 pc_red = {  65280, 52224, 39168, 52224, 65280, 0, 16384, 0, 0, 0, 0, 0, 0, 32768, 39168, 30464, 21760, 0, 34816, 43520, 52224, 39168, 29440, 65280, 26112, 0}
	Make/O/N=26 pc_green={   0, 17480, 0, 0, 32512, 0, 48896, 17408, 0, 65280, 52224, 26112, 65280, 65280, 39168, 30464, 21760, 0, 34816, 43520, 34816, 0, 0, 43520, 17408, 0}
	Make/O/N=26 pc_blue={    0, 0, 15616, 20736, 16384, 65280, 65280, 26112, 52224, 65280, 0, 0, 0, 65280, 0, 30464, 21760, 0, 34816, 43520, 0, 31232, 58880, 0, 0, 0}
	
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
				if( num_axes == 1 )
					dex = Floor( trace_dex/5 ) + Mod( trace_dex, 5 ) * 5
				else
					dex = axis_dex * 5 + trace_dex
				endif
				
				ModifyGraph rgb($this_trace)=(pc_red[dex], pc_green[dex], pc_blue[dex] )
				if( (trace_dex == 0) %&(num_axes != 1) )
					this_ax = StringFromList( axis_dex, axis_list )
					ModifyGraph axRGB($this_ax)=(pc_red[dex], pc_green[dex], pc_blue[dex])
					ModifyGraph tlblRGB($this_ax)=(pc_red[dex], pc_green[dex], pc_blue[dex])
					ModifyGraph alblRGB($this_ax)=(pc_red[dex], pc_green[dex], pc_blue[dex])
					ModifyGraph gridRGB($this_ax)=(pc_red[dex], pc_green[dex], pc_blue[dex])
				endif
				trace_dex += 1
			while( trace_dex < num_traces_this_axis )
		endif
		axis_dex += 1
	while( axis_dex < num_axes )
	
	KillWaves/Z pc_red, pc_green, pc_blue
End

Function RainbowColors(graphName,[colortable])
	String graphName,colorTable

	if(paramisdefault(colorTable))
		colorTable = "RainbowCycle"
	endif
	
	ColorTab2Wave $colorTable
	Wave M_colors = M_colors
	Variable num = Dimsize(M_colors,0)
		
	Variable num_axes, axis_dex = 0, dex
	Variable num_traces_this_axis, trace_dex = 0
	String axis_list, this_trace_list, this_trace, this_ax
	axis_list = DiscriminatedAxisList( graphName, "left" )+DiscriminatedAxisList( graphName, "right" )
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
				if( num_axes == 1 )
				
				// colors span the whol range
					dex = Floor( (trace_dex)/num_traces_this_axis * num)
				else
					// colors jump around
					dex =  axis_dex/num_axes*num +  trace_dex/num_traces_this_axis * num/num_axes
				endif
	
				ModifyGraph rgb($this_trace)=(M_colors[dex][0], M_colors[dex][1], M_colors[dex][2])
				if( (trace_dex == 0) %&(num_axes != 1) )
					this_ax = StringFromList( axis_dex, axis_list )
					ModifyGraph axRGB($this_ax)=(M_colors[dex][0], M_colors[dex][1], M_colors[dex][2])
					ModifyGraph tlblRGB($this_ax)=(M_colors[dex][0], M_colors[dex][1], M_colors[dex][2])
					ModifyGraph alblRGB($this_ax)=(M_colors[dex][0], M_colors[dex][1], M_colors[dex][2])
					ModifyGraph gridRGB($this_ax)=(M_colors[dex][0], M_colors[dex][1], M_colors[dex][2])
				endif
				trace_dex += 1
			while( trace_dex < num_traces_this_axis )
		endif
		axis_dex += 1
	while( axis_dex < num_axes )
	
	KillWaves/Z M_colors
End


Function/T DiscriminatedAxisList( graphName, axis_Type )
	string graphName, axis_Type
	String return_str =""
	Variable left = cmpstr( LowerStr(axis_type), "left" )
	Variable bottom = cmpstr( LowerStr(axis_type), "bottom" )
	Variable right = cmpstr( LowerStr(axis_type), "right" )
	Variable top = cmpstr( LowerStr(axis_type), "top" )
	if( (left!=0) %& (bottom!=0) %& (right!=0) %& (top!=0) )
		return return_str
	endif
	String list = AxisList( graphName )
	Variable idex = 0
	String info
	do
		info = StringByKey( "AXTYPE", AxisInfo( graphName, StringFromList( idex, list ) ))
		if( cmpstr( LowerStr(info), Lowerstr(axis_Type) ) != 0 )
			list = RemoveListItem( idex, list )
		else
			idex += 1
		endif
	while( idex < ItemsInList( list ))
	return_str = list
	return return_str
End

Function/T DiscriminatedTraceList( graphName, axisName )
	string graphName, axisName
	String return_str =""
	
	String list = TraceNameList( graphName, ";", 1 )
	Variable idex = 0
	String info
	do
		info = StringByKey( "YAXIS", TraceInfo( graphName, StringFromList( idex, list ), 0 ))
		if( cmpstr( LowerStr(info), Lowerstr(axisName) ) != 0 )
			list = RemoveListItem( idex, list )
		else
			idex += 1
		endif
	while( idex < ItemsInList( list ))
	return_str = list
	return return_str
End

Function BlankAndFillIn( scaled_y_wave, offending_index )
Wave scaled_y_wave
Variable offending_index


	Wave source_w = scaled_y_wave
	
	Duplicate/O source_w, smoothed_over, faux_x
	faux_x = pnt2x( source_w, p )
	DeletePoints offending_index, 1, source_w, faux_x
	smoothed_over = interp( x, faux_x, source_w )
	
	Duplicate/O smoothed_over, source_w
	KillWaves/Z smoothed_over, faux_x
End

////////////// Mark's Function for preconvolution
function instrumental_template_mzz(delta,laser_width)
variable delta,laser_width
variable/G  wi

variable center
	if(laser_width>0)
		if (laser_width<=delta)
				laser_width=delta						// execute if condition is true
		endif
		wi=laser_width												//half-width-half-max in cm-1
		make/D/o/n=(2*round(5*wi/delta)+1) instrumental					//make instrumental grid out to 5 half-widths 
		center=numpnts(instrumental)/2-0.5								//numpnts(instrumental) is odd
		instrumental=exp(-((p-center)*delta/wi)^2*ln(2))/sqrt(pi/ln(2))*delta/wi 	//normalize by sqrt(pi/ln(2))
	endif	
endmacro


Function IfNeedDoScroll(graph_name, thresh_frac, back_to)
String graph_name
Variable thresh_frac, back_to
//Printf "Doing Scroll on %s, with %g, %g as params\r", graph_name, thresh_frac, back_to
if( (thresh_frac > 1) %| (thresh_frac < 0 ) %| (back_to < 0) %| (back_to > 1 ) )
	print "If needed do scroll function sent out of bounds values", thresh_frac, back_to
	return -2
endif

GetAxis/W=$graph_name/Q bottom
Variable low = V_min, high = V_max
Variable span = high - low
String trace_list = TraceNameList( graph_name, ";", 1 );	Variable numtraces = ItemsInlist( trace_list )
Variable idex = 0;		Variable the_max = -inf;	String trace_data
if( numtraces > 0 )
	do
		trace_data = TraceInfo( graph_name, StringFromList( idex, trace_list ), 0)
		if( strlen(StringByKey("XWAVE", trace_data)) == 0)
			// then we are dealing with a scaled wave
			Wave w = TraceNameToWaveRef( graph_name,StringFromList( idex, trace_list ) )
			if( pnt2x( w, numpnts(w) ) > the_max )
				the_max = pnt2x( w, numpnts(w) )
			endif
		else
			// then we are dealing with an x-y pair
			Wave w = XWaveRefFromTrace(graph_name,StringFromList( idex, trace_list) )
			WaveStats/Q w
			if( V_max > the_max )
				the_max = V_max
			endif
		endif
		idex += 1
	while( idex < numtraces )
	// Now we exit from that do with a global value of "the_max" representative of whoever is 'first'
	if( the_max > high - (1-thresh_frac) * span )
		
		SetAxis/W=$graph_name bottom, the_max - back_to * span, the_max + (1 - back_to) * span
		return 1
	endif
	
	return 0
endif
return -1
End
///////////////////////////
Function LocateLastChar( str, char )
String str, char

Variable last_loc = strlen(str)
Variable idex = strlen( str )
String this
do
	this = str[idex]
	if( char2num( this ) == char2num( char ) )
		last_loc = idex
		idex = 0
	endif
	idex -= 1
while( idex > 0 )
if( last_loc == strlen(str ) )
	return -1
else
	return last_loc
endif
	
End
Function DataLoggerPanel() : Panel

	NewDataFolder/O root:DataLoggerPanel_Folder
	SetDataFolder root:DataLoggerPanel_Folder
	
	Make/N=0/O datalogger_loadfile_w
	Make/N=0/T/O datalogger_files_w
	
	String/G datalogger_panel_df, datalogger_panel_path
	
	datalogger_panel_path = "c:"; datalogger_panel_df = "root"
	setdatafolder root:

	Variable button_width = 75, control_height = 20, text_box_width = 250
	Variable fileListwidth = 175, fileListheight = 250, row = 0
	Variable column_1 = 0, column_2 = fileListwidth + 5
	Wave/T datalogger_files_w=root:DataLoggerPanel_Folder:datalogger_files_w
	Wave datalogger_fileload_w=root:DataLoggerPanel_Folder:datalogger_fileload_w
	
	PauseUpdate; Silent 1		// building window...
	if( strlen( WinList( "DataLogger_Panel", ";", "" ) )> 0 )
		DoWindow/K DataLogger_Panel
	endif
	NewPanel /W=(5,5,fileListwidth+10+text_box_width,filelistheight+2* control_height+15)
	DoWindow/C DataLogger_Panel
	
	Button SetPath, pos={column_1,row},size={button_width,control_height},proc=SetPathPanel_Button,title="Set Path"
	SetVariable dataloggerPathDisplay,pos={button_width+1,row},size={text_box_width,control_height},title=">",frame=0
	SetVariable dataloggerPathDisplay,value= root:dataloggerPanel_Folder:datalogger_panel_path
	DataLoggerPanel_Button("dataloggerPath")
	row+=control_height + 5
	
	ListBox datalogger_LB1,pos={column_1,row},size={fileListwidth,fileListheight}
	ListBox datalogger_LB1, listWave=datalogger_files_w,selWave=datalogger_loadfile_w,mode= 4
	PopupMenu dataloggerFormatPop,pos={column_2,row},size={text_box_width,control_height},title="Format"
	PopupMenu dataloggerFormatPop,mode=2,value= #"\"CO2 data 3 column;CO2 data 4 column;\""
	row+= control_height + 5
	
	SetVariable dataloggerPanelPrefix,pos={column_2,row},size={text_box_width,control_height},title="Wave Prefix"
	SetVariable dataloggerPanelPrefix,value= root:dataloggerPanel_Folder:datalogger_panel_prefix
	row+= control_height + 5
	//PopupMenu dataloggerPanelGraphPop,pos={column_2,row},size={text_box_width,control_height},proc=dataloggerPanel_Pop,title="Graph"
	//PopupMenu dataloggerPanelGraphPop,mode=2,popvalue=" Make Transmission Graph",value= #"\"Do not make graph; Make Transmission Graph; Make Raw Signal Graph; Make Both Graphs\""

	//row+= control_height + 5
	CheckBox dataloggerCat,pos={column_2,row},size={button_width*2,control_height},title="Concatenate Multiple"
	CheckBox dataloggerCat,value= 1
	
	//row += control_height + 5
	//SetVariable dataloggerPanelDestDF,pos={column_2,row},size={text_box_width,control_height},title="Dest DF"
	//SetVariable dataloggerPanelDestDF,value= root:dataloggerPanel_Folder:datalogger_panel_df
	
	row = control_height + fileListHeight + 10
	Button dataloggerCancel,pos={column_1,row},size={2*button_width,control_height},proc=dataloggerPanel_Button,title="Cancel"
	Button dataloggerLoad,pos={column_2,row},size={2*button_width,control_height},proc=dataloggerPanel_Button,title="Load"
EndMacro

Function dataloggerPanel_Button(ctrlName) : ButtonControl
String ctrlName
// Handles dataloggerPath, dataloggerCancel and dataloggerLoad
	
	SVAR datalogger_panel_prefix=root:dataloggerPanel_Folder:datalogger_panel_prefix
	SVAR datalogger_panel_path=root:dataloggerPanel_Folder:datalogger_panel_path
	SVAR datalogger_panel_df=root:dataloggerPanel_Folder:datalogger_panel_df
	Wave/T datalogger_files_w=root:dataloggerPanel_Folder:datalogger_files_w
	Wave datalogger_loadfile_w=root:dataloggerPanel_Folder:datalogger_loadfile_w
	
	String file_list
	Variable idex
	
	if( cmpstr( ctrlName, "dataloggerPath" ) == 0 )
		NewPath/O/M="Select folder where datalogger files are located"/Q LoaddataloggerPanelPath
		PathInfo LoaddataloggerPanelPath
		datalogger_panel_path = s_path
		file_list = IndexedFile( LoaddataloggerPanelPath, -1, "????" )
		Redimension/N=0 datalogger_files_w
		
		if( strlen( file_list ) > 0 )
			idex = 0
			do
				AppendString( datalogger_files_w, StringFromList( idex, file_list ))
				idex += 1
			while( idex < ItemsInList( file_list )	)
			Redimension/N=(numpnts(datalogger_files_w)) datalogger_loadfile_w
			ListBox datalogger_LB1 disable=0
		else
			Redimension/N=1 datalogger_files_w, datalogger_loadfile_w
			datalogger_files_w[0] = "No datalogger files here"
			//datalogger_loadfile_w = 0
			ListBox datalogger_LB1, disable=0
		endif
	endif
	if( cmpstr( ctrlName, "dataloggerLoad" ) == 0 )
		Variable format_code
		String path_str, file_str, format_str
		// resolve format_code
		ControlInfo/W=datalogger_Panel dataloggerFormatPop
		format_code = v_value 
		path_str = datalogger_panel_path
		NewPath/O/Q DataLoggerPath, path_str
	
		idex = 0
		do
			if( datalogger_loadfile_w[idex] == 1 )
				file_str = datalogger_files_w[idex]
				//print path_str, file_str, "Format", format_code
				// stolen code from LLV formatter
				//   C=1,F=-1,T=2,N=w_0;C=1,F=-1,T=2,N=w_1;C=1,F=-1,T=2,N=w_2;  
				//Loaddatalogger( path_str, file_str, base_str, dest_DF_str, graph_code, wavelength_code )
				if( format_code == 1 )
					format_str = "C=1,F=-1,T=4,N=w_0;C=1,F=-1,T=4,N=w_1;C=1,F=-1,T=4,N=w_2;"
				endif
				if( format_code == 2 )
					format_str = "C=1,F=-1,T=4,N=w_0;C=1,F=-1,T=4,N=w_1;C=1,F=-1,T=4,N=w_2;C=1,F=-1,T=4,N=w_3;"
				endif
				LoadWave/A/L={0,1,0,0,0}/O/Q/P=DataLoggerPath/B=format_str/J/O/V={"\t, ", "", 0, 0} file_str
				ControlInfo/W=datalogger_Panel dataloggerCat
				if( v_value )
					ConcatenateWaves( "co2_tron_time", "w_0")
					ConcatenateWaves( "co2_ins_time", "w_1" )
					ConcatenateWaves( "co2_mix", "w_2" )
					if( exists( "w_3" ) == 1 )
						ConcatenateWaves( "h2o_mix", "w_3" )
					endif
				else
					print "doing nothing to loaded waves"
				endif
			endif
			
			idex +=1
		while( idex < numpnts( datalogger_files_w ) )
		DoWindow/F datalogger_Panel
		
	endif
	if( cmpstr( ctrlName, "dataloggerCancel" ) == 0 )
		DoWindow/K datalogger_Panel
		KillDataFolder root:dataloggerPanel_Folder
		setdatafolder root:
	endif
End

Function SecondsToMinutes()

	Wave w_1 = $"co2_tron_time_jan11"
	Wave w_2 = $"co2_mix_jan_11"
	
	Make/D/O/N=0 co2_m_time_jan11
	Make/O/N=0 co2_m_mix_jan11
	
	Wave m_1 = co2_m_time_jan11
	Wave m_2 = co2_m_mix_jan11
	//display m_2 vs m_1
		
	Variable idex = 60
	Variable num = numpnts( w_1 )
	print "w_1:", num, "w_2", numpnts(w_2)
	
	do
		WaveStats/Q/R=[	idex, idex - 60 ] w_1
		appendval( m_1, v_avg )
		
		WaveStats/Q/R=[	idex, idex - 60 ] w_2
		appendval( m_2, v_avg )
		
		idex += 60
	while( idex < num )
	
end
Function AllAxesFreePosZero(graphName)
	String graphName
	
	String this, ax_list = AxisLIst( graphName )
	Variable idex = 0, count = ItemsInList( ax_list )
	if( count > 0 )
		do	
			this = StringFromList( idex, ax_list )
			ModifyGraph freePos($this)=0
			idex += 1
		while( idex < count )
	endif
End
Function ScrollAndScaleWindowsWith( phrase )		
	String phrase
	
	Variable doScroll = 0, doScale = 0
	String list, searchPhrase, this_win
	sprintf searchPhrase, "*%s*", phrase
	list = WinList( searchPhrase, ";", "WIN:1" )
	Variable num = ItemsInList(list), idex = 0
	if( num > 0 )
		do
			this_win = StringFromList( idex, list )
			doScroll = 0; doScale = 0
			ControlInfo/W=$this_win AutoScroll_ARI
			if( v_flag == 0 )
				// then control does not exist and we will scroll
				doScroll = 1
			endif 
			if( v_flag == 2 )
				// then control does exist
				if( v_value == 1 )
					// then control is checked
					doScroll = 1
				else
					// we assume it isn't
				endif
			endif
			
			ControlInfo/W=$this_win AutoScale_ARI
			if( v_flag == 0 )
				// then control does not exist and we will scroll
				doScale = 1
			endif 
			if( v_flag == 2 )
				// then control does exist
				if( v_value == 1 )
					// then control is checked
					doScale = 1
				else
					// we assume it isn't
				endif
			endif
			
			if( doScroll )
				IfNeedDoScroll( this_win, 0.9, 0.4 )
			else
				// do nothing
			endif
			if( doScale )
				ScaleAllYAxes( this_win )
			endif
			
			idex += 1
		while( idex < num )
	endif 

End
Function AddScaleScrollCheckBoxes( xpos, ypos )
	Variable xpos, ypos
	Variable wid = 60, height = 21
	
	CheckBox AutoScale_ARI title = "Auto Y",  pos={ xpos, ypos}, size={wid, height}, value=1
	CheckBox AutoScale_ARI help={"Check to invoke the ScaleAllYAxes, uncheck to prevent"}

	CheckBox AutoScroll_ARI title = "Auto X", pos={ xpos + wid+2, ypos}, size={wid, height}, value=1
	CheckBox AutoScroll_ARI help={"Check to invoke the Scroll, uncheck to prevent"}
End
Function/T MakeAndOrSetDF( data_folder )
	string data_folder
	
	string old_DF = GetDataFolder(1)
	setdatafolder root:
	if( !DataFolderExists( data_folder ) )
		NewDataFolder $data_folder
	endif
	SetDataFolder $data_folder
	return old_DF
End
Function MakeOrSetPath( pathName, pathLocation )
	String pathName, pathLocation
	
	PathInfo/S $pathName
	if( v_flag == 0 )
		NewPath/C/Q/O $pathName, pathLocation
		PathInfo/S $pathName
	endif
	
End
Function MakeOrSetPathNoCreate( pathName, pathLocation )
	String pathName, pathLocation
	
	PathInfo/S $pathName
	if( v_flag == 0 )
		NewPath/Z/Q/O $pathName, pathLocation
		PathInfo/S $pathName
	endif
	
End
Function MakeOrSetPanel( left, top, width, height, name )
	Variable top, left, height, width
	String name
	
	if( WinType( name ) == 7 )
		DoWindow/K $name
	endif
	NewPanel/W=( left,top, width, height)/K=1 as name
	DoWindow/C $name
	
End

Function Diurnal_TOD_SeaFire( tod_w, scaled_Y1 )
	Wave tod_w
	Variable scaled_Y1
	
	Variable idex = 0, count = numpnts( tod_w )
	String this_time
	Variable this_hour, hr_val
	for( idex = 0; idex < count; idex += 1 )
		if( scaled_Y1 )
			this_time = DateTime2Text( pnt2x( tod_w, idex ) )
		else
			this_time = DateTime2Text( tod_w[idex] )

		endif
		this_hour = str2num( StringFromList( 0, StringFromList( 1, this_time, " "), ":" ) )
		
		switch( this_hour )
			case 0:
			case 1:
			case 2:
				hr_val = 4
				break;
			case 3:
			case 4:
				hr_val = 3
				break;
			case 5:
				hr_val = 1
				break;
			case 6:	
			case 7:
			case 8:
				hr_val = 24
				break;
			case 9:
			case 10:
				hr_val = 20
				break;
			
			case 11:
			case 12:
				hr_val = 17
				break;
			case 13:
			case 14:
				hr_val = 15
				break;	
			case 15:
			case 16:
			case 17:
				hr_val = 12
				break;
			case 18:
			case 19:
				hr_val = 10
				break;
	
			case 20:
			case 21:
			case 22:
				hr_val = 7
				break;
			case 23:
			case 24:
				hr_val = 5
				break;
					
			
		endswitch	
		tod_w[idex] = hr_val
	endfor
	
End
Function DiurnalClip( source_x, source_y, dest_name, time_window )
	Wave source_x, source_y
	String dest_name
	Variable time_window
	
	Variable scaled_targ = 0
	if( cmpstr( NameOfWave( source_x ), NameOfWave( source_y ) ) == 0 )
		scaled_targ = 1
	endif
	
	Variable useIndepMask = 1
	
	Duplicate/O source_x, dc_indepMask 
	dc_indepMask = 1
//	dc_indepMask[0,x2pnt( source_x, Text2DateTime( "3/1/2006 15:00" )) ] = 0
//	dc_indepMask[ x2pnt( source_x, Text2DateTime( "3/30/2006 12:00" )), x2pnt(source_x, Text2DateTime( "3/31/2006 23:59" ))] = 0

	
	if( scaled_targ )
		Duplicate/o source_y, temp_dc_x
		temp_dc_x = x		
	else
		Duplicate/o source_x, temp_dc_x
	endif
	Duplicate/o source_y, temp_dc_y
	
	//temp_dc_x = Secs2SAM( temp_dc_x )
	
	//Sort temp_dc_x, temp_dc_x, temp_dc_y
	
	Make/N=(3600*24 / time_window)/D/O $dest_name
	Wave w = $dest_name
	SetScale/P x, time_window/2, time_window, "dat", w
	
	Duplicate/O w, temp_dc_bin_count
	temp_dc_bin_count = 0; w = 0
	
	Variable idex = 0, count = numpnts( temp_dc_x )-1, bin, now, sam, mindex = 0, mincount = 3600*6
	String now_text, sam_text
	do
		now = temp_dc_x[idex]; now_text = DateTime2Text( now );
		sam = Secs2SAM( now ); sam_text = DateTime2Text( sam );
		
	if( dc_indepMask(now) )
		bin = x2pnt( w, sam )
		if( numtype( temp_dc_y[idex]) != 2  )
			w[bin] += temp_dc_y[idex]
			temp_dc_bin_count[bin] += 1
		endif
	endif
		idex += 1
		
		mindex += 1
		if( mindex > mincount )
			mindex = 0; doupdate
		endif

	while( idex < count )
	w /= temp_dc_bin_count
	
End

Function DiurnalMedian( source_x, source_y, dest_name, time_window )
	Wave source_x, source_y
	String dest_name
	Variable time_window
	
	Variable scaled_targ = 0
	if( cmpstr( NameOfWave( source_x ), NameOfWave( source_y ) ) == 0 )
		scaled_targ = 1
	endif
	
	Variable useIndepMask = 1
	
	Duplicate/O source_x, dc_indepMask 
	dc_indepMask = 1
//	dc_indepMask[0,x2pnt( source_x, Text2DateTime( "3/1/2006 15:00" )) ] = 0
//	dc_indepMask[ x2pnt( source_x, Text2DateTime( "3/30/2006 12:00" )), x2pnt(source_x, Text2DateTime( "3/31/2006 23:59" ))] = 0

	
	if( scaled_targ )
		Duplicate/o source_y, temp_dc_x
		temp_dc_x = x		
	else
		Duplicate/o source_x, temp_dc_x
	endif
	Duplicate/o source_y, temp_dc_y
	
	//temp_dc_x = Secs2SAM( temp_dc_x )
	
	//Sort temp_dc_x, temp_dc_x, temp_dc_y
	
	Make/N=(3600*24 / time_window)/D/O $dest_name
	Wave w = $dest_name
	SetScale/P x, time_window/2, time_window, "dat", w
	
	Duplicate/O w, temp_dc_bin_count
	temp_dc_bin_count = 0; w = 0
	
	Variable idex = 0, count = numpnts( temp_dc_x )-1, bin, now, sam, mindex = 0, mincount = 3600*6
	String now_text, sam_text
	
	for( idex = 0; idex < numpnts( w ); idex +=1 )
		Wave/Z med_w = $("dimedexw_" + num2str( idex ) )
		KillWaves/Z med_w
	endfor
	
	do
		now = temp_dc_x[idex]; now_text = DateTime2Text( now );
		sam = Secs2SAM( now ); sam_text = DateTime2Text( sam );
		
	if( dc_indepMask(now) )
		bin = x2pnt( w, sam )
		if( numtype( temp_dc_y[idex]) != 2  )
			Wave/Z med_w = $("dimedexw_" + num2str( bin ) )
			if( WaveExists( med_w ) != 1 )
				Make/D/O/N=0 $("dimedexw_" + num2str( bin ) )
				Wave/Z med_w = $("dimedexw_" + num2str( bin ) )
			endif
			AppendVal( med_w, temp_dc_y[idex] )
			//w[bin] += temp_dc_y[idex]
			//temp_dc_bin_count[bin] += 1
		endif
	endif
		idex += 1
		
		// the mindex here is for any kind of "live" update opportunity
		// currently this executes a "doupdate" every mincount points, might not make sense in the median anyway.
		mindex += 1
		if( mindex > mincount )
			mindex = 0; doupdate
		endif

	while( idex < count )
	for( idex = 0; idex < numpnts( w ); idex +=1 )
		Wave/Z med_w = $("dimedexw_" + num2str( idex ) )
		if( WaveExists( med_w ) )
			QuartileReport( med_w, 0 )
			NVAR V_Quartile50
			w[idex] = V_Quartile50
		else
			w[idex] = nan
		endif
		KillWaves/Z med_w
	endfor
	//w /= temp_dc_bin_count
	
End

Function DiurnalStats( source_x, source_y, dest_name, time_window )
	Wave source_x, source_y
	String dest_name
	Variable time_window
	
	Variable scaled_targ = 0
	if( cmpstr( NameOfWave( source_x ), NameOfWave( source_y ) ) == 0 )
		scaled_targ = 1
	endif
	
	Variable useIndepMask = 1
	
	Duplicate/O source_x, dc_indepMask 
	dc_indepMask = 1
//	dc_indepMask[0,x2pnt( source_x, Text2DateTime( "3/1/2006 15:00" )) ] = 0
//	dc_indepMask[ x2pnt( source_x, Text2DateTime( "3/30/2006 12:00" )), x2pnt(source_x, Text2DateTime( "3/31/2006 23:59" ))] = 0

	
	if( scaled_targ )
		Duplicate/o source_y, temp_dc_x
		temp_dc_x = x		
	else
		Duplicate/o source_x, temp_dc_x
	endif
	Duplicate/o source_y, temp_dc_y
	
	//temp_dc_x = Secs2SAM( temp_dc_x )
	
	//Sort temp_dc_x, temp_dc_x, temp_dc_y
	
	Make/N=(3600*24 / time_window)/D/O $(dest_name+"_Mean")
	Wave mean_w = $dest_name+"_Mean"
	Duplicate/O mean_w, $(dest_name + "_Sdev"), $(dest_name + "_Median")
	Wave sdev_w = $(dest_name + "_Sdev")
	Wave median_w =  $(dest_name + "_Median")
	
	SetScale/P x, time_window/2, time_window, "dat", mean_w, sdev_w, median_w
	
	Duplicate/O mean_w, temp_dc_bin_count
	temp_dc_bin_count = 0; mean_w = 0
	
	Variable idex = 0, count = numpnts( temp_dc_x )-1, bin, now, sam, mindex = 0, mincount = 3600*6
	String now_text, sam_text
	
	for( idex = 0; idex < numpnts( mean_w ); idex +=1 )
		Wave/Z med_w = $("dimedexw_" + num2str( idex ) )
		KillWaves/Z med_w
	endfor
	
	do
		now = temp_dc_x[idex]; now_text = DateTime2Text( now );
		sam = Secs2SAM( now ); sam_text = DateTime2Text( sam );
		
	if( dc_indepMask(now) )
		bin = x2pnt( mean_w, sam )
		if( numtype( temp_dc_y[idex]) != 2  )
			Wave/Z med_w = $("dimedexw_" + num2str( bin ) )
			if( WaveExists( med_w ) != 1 )
				Make/D/O/N=0 $("dimedexw_" + num2str( bin ) )
				Wave/Z med_w = $("dimedexw_" + num2str( bin ) )
			endif
			AppendVal( med_w, temp_dc_y[idex] )
			//w[bin] += temp_dc_y[idex]
			//temp_dc_bin_count[bin] += 1
		endif
	endif
		idex += 1
		
		// the mindex here is for any kind of "live" update opportunity
		// currently this executes a "doupdate" every mincount points, might not make sense in the median anyway.
		mindex += 1
		if( mindex > mincount )
			mindex = 0; doupdate
		endif

	while( idex < count )
	for( idex = 0; idex < numpnts( mean_w ); idex +=1 )
		Wave/Z med_w = $("dimedexw_" + num2str( idex ) )
		if( WaveExists( med_w ) )
			QuartileReport( med_w, 0 )
			NVAR V_Quartile50
			median_w[idex] = V_Quartile50
			WaveStats/Q med_w
			mean_w[idex] = v_avg
			sdev_w[idex] = v_sdev
		else
			median_w[idex] = nan
			sdev_w[idex] = nan
			mean_w[idex] = nan
		endif
		KillWaves/Z med_w
	endfor
	//w /= temp_dc_bin_count
	
End

Function DiurnalClip_wAccount( source_x, source_y, dest_name, time_window )
	Wave source_x, source_y
	String dest_name
	Variable time_window
	
	Variable scaled_targ = 0
	if( cmpstr( NameOfWave( source_x ), NameOfWave( source_y ) ) == 0 )
		scaled_targ = 1
	endif
	

	if( scaled_targ )
		Duplicate/o source_y, temp_dc_x
		temp_dc_x = x		
	else
		Duplicate/o source_x, temp_dc_x
	endif
	Duplicate/o source_y, temp_dc_y
	
	//temp_dc_x = Secs2SAM( temp_dc_x )
	
	//Sort temp_dc_x, temp_dc_x, temp_dc_y
	Make/N=0/D/O $(dest_name+"_actime"), $(dest_name+"_acdat")
	Wave act= $(dest_name+"_actime")
	Wave acd = $(dest_name+"_acdat")
	Make/N=(3600*24 / time_window)/D/O $dest_name
	Wave w = $dest_name
	SetScale/P x, time_window/2, time_window, "dat", w
	
	Duplicate/O w, temp_dc_bin_count
	temp_dc_bin_count = 0; w = 0
	
	Variable day, idex = 0, count = numpnts( temp_dc_x )-1, bin, now, sam, mindex = 0, mincount = 3600*6
	String now_text, sam_text
	do
		now = temp_dc_x[idex]; now_text = DateTime2Text( now );
		sam = Secs2SAM( now ); sam_text = DateTime2Text( sam );
		day = str2num(StringFromList( 1, StringFromList( 0, now_text, " " ), "/" ))
		
		if( ((day>9) & (day<13)) | (day>18)  )
		bin = x2pnt( w, sam )
		if( numtype( temp_dc_y[idex]) != 2  )
			w[bin] += temp_dc_y[idex]
			temp_dc_bin_count[bin] += 1
		
			AppendVal(act, sam)
			AppendVal( acd, temp_dc_y[idex])
			Wave/Z day_w = $(dest_name+"_D"+num2str( day))
			if( WaveExists(day_w) != 1 )
				Make/N=(3600*24 / time_window)/D/O $(dest_name+"_D"+num2str( day)), $(dest_name+"_DCount"+num2str( day))
				Wave day_w = $(dest_name+"_D"+num2str( day))
				Wave count_w = $(dest_name+"_DCount"+num2str( day))
				SetScale/P x, time_window/2, time_window, "dat", day_w
				count_w = 0
				day_w = 0
			endif
			Wave day_w = $(dest_name+"_D"+num2str( day))
			Wave count_w = $(dest_name+"_DCount"+num2str( day))
			if( ((day>9) & (day<13)) | (day>18) )
				day_w[bin] += temp_dc_y[idex]
				count_w[bin] += 1
			endif
		endif
		endif
		idex += 1
		
		mindex += 1
		if( mindex > mincount )
			mindex = 0; doupdate
		endif
	while( idex < count )
	w /= temp_dc_bin_count
	
	for( idex = 9; idex < 19; idex += 1 )
			Wave day_w = $(dest_name+"_D"+num2str( idex))
			Wave count_w = $(dest_name+"_DCount"+num2str( idex))
			day_w /= count_w
	endfor
End

Function DiurnalClipDOW( source_x, source_y, dest_name, time_window )
	Wave source_x, source_y
	String dest_name
	Variable time_window
	
	Variable scaled_targ = 0
	if( cmpstr( NameOfWave( source_x ), NameOfWave( source_y ) ) == 0 )
		scaled_targ = 1
	endif
	

	if( scaled_targ )
		Duplicate/o source_y, temp_dc_x
		temp_dc_x = x		
	else
		Duplicate/o source_x, temp_dc_x
	endif
	Duplicate/o source_y, temp_dc_y
	
	//temp_dc_x = Secs2SAM( temp_dc_x )
	
	//Sort temp_dc_x, temp_dc_x, temp_dc_y
	String dest_name_MF = dest_name + "_MF"
	String dest_name_SS = dest_name + "_SS"
	
	Make/N=(3600*24 / time_window)/D/O $dest_name_MF, $dest_name_SS
	Wave w_MF = $dest_name_MF
	Wave w_SS = $dest_name_SS
	SetScale/P x, time_window/2, time_window, "dat", w_MF, w_SS
	
	Duplicate/O w_MF, temp_dc_bin_count_MF, temp_dc_bin_count_SS
	temp_dc_bin_count_MF = 0; w_MF = 0; w_SS = 0
	temp_dc_bin_count_SS = 0
	
	Variable idex = 0, count = numpnts( temp_dc_x )-1, bin, now, sam, mindex = 0, mincount = 3600*6
	String now_text, sam_text, dow_text
	Variable mf_setvar
	do
		now = temp_dc_x[idex]; now_text = DateTime2Text( now );
		sam = Secs2SAM( now ); sam_text = DateTime2Text( sam );
		dow_text = Secs2Date(now,2)
		mf_setvar = 1
		if( Strsearch( dow_text, "Sat", 0 ) != -1 )
			mf_setvar = 0
		endif
		if( strsearch( dow_text, "Sun", 0 ) != -1 )
			mf_setvar = 0
		endif
		
		if( MF_Setvar )
			Wave w = $dest_name_MF
			Wave cw = $"temp_dc_bin_count_MF"
		else
			Wave w = $dest_name_SS
			Wave cw = $"temp_dc_bin_count_SS"
		endif
		
		bin = x2pnt( w, sam )
		if( numtype( temp_dc_y[idex]) != 2  )
			w[bin] += temp_dc_y[idex]
			cw[bin] += 1
		endif
		idex += 1
		
		mindex += 1
		if( mindex > mincount )
			mindex = 0; doupdate
		endif
	while( idex < count )
	w_MF /= temp_dc_bin_count_MF
	w_SS /= temp_dc_bin_count_SS
	
End

Function MakeOrSetGraph( left, top, right, bottom, name )
	Variable left, top, right, bottom
	String name
	// /W=(left,top,right,bottom)
	// gives the graph a specific location and size on the screen. 
	// Coordinates for /W are in points unless /I or /M are specified before /W.
	if( WinType( name ) == 1 )
		DoWindow/K $name
	endif
	Display/W=(left, top, right, bottom)/K=1
	
	DoWindow/C $name
	
End

Function/T AddLeadingZeroToBase10( val_str, width )
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

Function/T ReplaceStringInString( target_str, old_str, new_str )
	String target_str, old_str, new_str
	
	Variable old_str_loc = Strsearch( target_str, old_str, 0 )
	if( old_str_loc == -1 )
		return target_str
	endif
	String ret_str = target_str[ 0, old_str_loc - 1] + new_str + target_str[ old_str_loc + strlen( new_str ), strlen( target_str ) ]
	
	if( cmpstr( ReplaceStringInString( ret_str, old_str, new_str ), ret_str ) == 0 )
	
		return ret_str
	else
		ret_str = ReplaceStringInString( ret_str, old_str, new_str )
	endif
	return ret_str
End
Function/T ReplaceStringInStringVLen( target_str, old_str, new_str )
	String target_str, old_str, new_str
	Variable new_set
	
	Variable old_str_loc = Strsearch( target_str, old_str, 0 )
	if( old_str_loc == -1 )
		return target_str
	endif
	if( strlen( old_str ) > strlen( new_str ) )
		new_set = strlen( old_str )
	else
		new_set = strlen( old_str )
	endif
	
	String ret_str = target_str[ 0, old_str_loc - 1] + new_str + target_str[ old_str_loc + new_set, strlen( target_str ) ]
	
	if( cmpstr( ReplaceStringInString( ret_str, old_str, new_str ), ret_str ) == 0 )
	
		return ret_str
	else
		ret_str = ReplaceStringInString( ret_str, old_str, new_str )
	endif
	return ret_str
End
Function/T KillWavesWhichMatchStr( str )
	String str
	String ret_str = "PRE:;POST:;"
	
	String w_list = WaveList( str, ";", "" )
	ret_str = ReplaceStringByKey( "PRE", ret_str, w_list )
	Variable idex = 0, count = ItemsInList( w_list )
	if( count > 0 )
		do
			KillWaves/Z $StringFromList( idex, w_list )
			idex += 1
		while( idex < count )
	endif
	w_list = WaveList( str, ";", "" )
	ret_str = ReplaceStringByKey( "POST", ret_str, w_list )
	return ret_str
End
Function/T DoubleUpCharacter( source_str, char_to_double )
	String source_str, char_to_double
	string char = char_to_double
	String return_str = "";
	Variable idex = 0
	do
		if( cmpstr(source_str[idex],char_to_double ) == 0 )
			return_str += char_to_double
		endif
		return_str += source_str[idex]
		idex += 1
	while( idex < strlen( source_str ) )
	return return_str
End
Function/T WindowsFullPath( path, file )
String path, file
	String ret_str = ""
	Variable idex, jdex, kdex, last_colon = 0
	idex = 0; jdex = 0; kdex = 0
	if( strsearch( path, ":", 0 ) == -1 )
		sprintf ret_str, "\\\\%s\\%s", path, file
		return ret_str
	endif 
	if( strlen( path ) == 2 )
		// then we likely have bare drive letter
		ret_str = path[0] + ":\\" + file
		return ret_str
	endif
	
	if( cmpstr( ":", path[strlen(path)-1]) ==0 )
		// strip last colon
		path = path[0, strlen(path)-2]
	endif
	do
		jdex = strsearch( path, ":", idex )
		if( jdex == -1 )
			last_colon = 1
			jdex = strlen( path )
		endif
		if( kdex == 0 )
			ret_str += path[ idex, jdex ]
			ret_str += "\\"
			//printf ">%s, idex %g, jdex %g\t", ret_str, idex, jdex
			kdex = 1
		else
			ret_str += path[ idex, jdex - 1 ]
			ret_str += "\\"
			//printf ">>%s, idex %g, jdex %g\t", ret_str, idex, jdex
		endif
		idex = jdex + 1
	while( last_colon == 0 )
	return ret_str+file
End
Function/T FullIgor2FullWindows( fullfile )
String fullfile
	String ret_str = ""
	Variable idex, jdex, kdex, last_colon = 0
	idex = 0; jdex = 0; kdex = 0
	if( strsearch( fullfile, ":", 0 ) == -1 )
		sprintf ret_str, "\\\\%s", fullfile
		return ret_str
	endif 

	
	if( cmpstr( ":", fullfile[strlen(fullfile)-1]) ==0 )
		// strip last colon
		fullfile = fullfile[0, strlen(fullfile)-2]
	endif
	do
		jdex = strsearch( fullfile, ":", idex )
		if( jdex == -1 )
			last_colon = 1
			jdex = strlen( fullfile )
		endif
		if( kdex == 0 )
			ret_str += fullfile[ idex, jdex ]
			ret_str += "\\"
			//printf ">%s, idex %g, jdex %g\t", ret_str, idex, jdex
			kdex = 1
		else
			ret_str += fullfile[ idex, jdex - 1 ]
			ret_str += "\\"
			//printf ">>%s, idex %g, jdex %g\t", ret_str, idex, jdex
		endif
		idex = jdex + 1
	while( last_colon == 0 )
	ret_str = ret_str[0, strlen(ret_str) - 2 ]
	return ret_str
End
Function/T TackSubFileOrFolderOntoPath( big_str, little_str )
	String big_str, little_str
	
	String return_str = big_str
	Variable last_is_colon = 0;
	Variable len = strlen( big_str );
	if( cmpstr( big_str[len-1], ":" ) == 0 )
		last_is_colon = 1
	endif
	
	if( last_is_colon )
		sprintf return_str, "%s%s", big_str, little_str
	else
		sprintf return_str, "%s:%s", big_str, little_str
	endif
	
	return return_str;
	
End
Function CheckDrivePath( drive_path )
	String drive_path
		
	Variable ret = 0
	 
	 NewPath/O/Q/Z gnt_cdp, drive_path
	 if( V_Flag == 0 )
	 	ret = 1
	 endif
	 KillPath/Z gnt_cdp
	 return ret
End
Function IgorCatFile( sourceFile, destFile )
	String sourceFile
	String destFile

	Variable sourceRef, destRef
	String line
	
	Variable result = 0;
	
	Open/Z/R sourceRef as sourceFile
	if( sourceRef == 0 )
		result = -2
		return result
	endif
	
	Open/Z/A destRef as destFile
	if( destRef == 0 )
		Close sourceRef
		result = -1
		return result;
	endif
	
	do
		FReadLine sourceRef, line
		if( strlen( line ) == 0 )
			break;
		endif
		line = line[0, strlen(line) -2 ]
		fprintf destRef, "%s\r\n", line
	while(1)
	Close destRef
	Close sourceRef
	return result;
End
Function XOP_FileMove( current, new )
	String current, new
	Variable return_val, refNum
	String sFold = getdatafolder(1)
	setdatafolder root:
	String cmd = ""
	sprintf cmd, "MoveFileXOP \"%s\", \"%s\"", DoubleUpCharacter(current, "\\"), DoubleUpCharacter(new, "\\")
	Execute cmd
	SetDataFolder $sFold
	//print cmd
	NVAR Move_File_Flag=root:gMoveFileResult
	//print Move_File_Flag
	if( move_File_Flag == 0 )
		Open/Z/R refNum new
		Close refNum
		if( V_Flag == 0 )
			return 1
		else
			return V_Flag
		endif
	else
		if(Move_File_Flag == 5 )
			// this probabljust a file busy code
		else
			printf "MoveFileXOP returned code %g", Move_File_Flag
			if( Move_File_Flag == 183 )	
				printf "\tmeans new file name already taken"
			endif
			if( Move_File_Flag == 161)
				printf "\tprobably means source file name not found"
			endif
			printf "\r"
		endif
		return -1
	endif
End

Function XOP_FileKill( current, new )
	String current, new
	Variable return_val, refNum
	String sFold = getdatafolder(1)
	setdatafolder root:
	String cmd = ""
	sprintf cmd, "KillFileXOP \"%s\", \"%s\"", DoubleUpCharacter(current, "\\"), DoubleUpCharacter(new, "\\")
	Execute cmd
	SetDataFolder $sFold
	//print cmd
	NVAR Kill_File_Flag=root:gKillFileResult
	//print Kill_File_Flag
//	if( Kill_File_Flag == 0 )
//		Open/Z/R refNum new
//		Close refNum
//		if( V_Flag == 0 )
//			return 1
//		else
//			return V_Flag
//		endif
//	else
//		if(Kill_File_Flag == 5 )
//			// this probabljust a file busy code
//		else
//			printf "KillFileXOP returned code %g", Kill_File_Flag
//			if( Kill_File_Flag == 183 )	
//				printf "\tmeans new file name already taken"
//			endif
//			if( Kill_File_Flag == 161)
//				printf "\tprobably means source file name not found"
//			endif
//			printf "\r"
//		endif
//		return -1
//	endif
End

#pragma rtGlobals=1		// Use modern global access method.

Function GenerateFileList( pathName, pathString, usePath, list_Wave, fileMask, quietOrReport )
	String pathName, pathString
	Variable usePath
	Wave/T list_Wave
	String fileMask
	Variable quietOrReport
	
	// usePath controls which of the paths is used in making the list
	// usePath = 1 means use the pathName as is
	// usePath = 0 means make a path using pathString
	
	if( usePath == 0 )
		NewPath/O/Q ThisFileListPath, pathString
		Pathinfo ThisFileListPath
		if( v_flag != 1 )
			print "Error in GenerateFileList, can't make path ", pathString
			return 0
		endif
	endif
	
	if( usePath == 0 )
		//GFL_Filelist( "ThisFileListPath", quietOrReport, list_Wave, fileMask )
		GFL_FilelistAtOnce( "ThisFileListPath", quietOrReport, list_Wave, fileMask )
	else
		//GFL_Filelist( pathName, quietOrReport, list_Wave, fileMask )
		GFL_FilelistAtOnce( pathName, quietOrReport, list_Wave, fileMask )
	endif
	return numpnts( list_Wave )
End
Function/T GetFileExtensionFromFileOrFP( file )
	String file
	
	String ret_ext = "???"
		
	Variable dotdex = -1, idex = strlen( file ) -1
	Variable len  = idex
	do
		if( cmpstr( file[idex], "." ) == 0 )
			dotdex = idex
			idex = 0
		endif
		idex -= 1
	while( idex > 0 )
	
	if( dotdex != -1 )
		if( len - 3 != dotdex )
			//print "Non standard length for file extension"
		endif
		ret_ext = file[dotdex+1, len ]
	endif
	
	return ret_ext
End

Function/T GetFileNameFromFileOrFP( file )
	String file
	
	String ret_ext = "???"
		
	Variable dotdex = -1, idex = strlen( file ) -1
	Variable len  = idex
	do
		if( cmpstr( file[idex], "." ) == 0 )
			dotdex = idex
			idex = 0
		endif
		idex -= 1
	while( idex > 0 )
	
	if( dotdex != -1 )
		if( len - 3 != dotdex )
			//print "Non standard length for file extension"
		endif
		ret_ext = file[dotdex+1, len ]
	endif
	
	Variable bdex = -1
	if( dotdex != -1 )
		idex = dotdex
		do
			if( (cmpstr( file[idex], ":" ) == 0) | (cmpstr(file[idex], "\\" )==0) )
				bdex = idex
				idex = 0
			endif
			idex -= 1
		while( idex > 0 )
	endif
	
	if( bdex != -1 )
		ret_ext = file[ bdex + 1, dotdex - 1 ]
	else
		ret_ext = file[ 0, dotdex - 1 ]
	endif
	
	return ret_ext
End
Function/T GetPathNameFromFileOrFP( file )
	String file
	
	String ret_ext = "???"
		
	Variable dotdex = -1, idex = strlen( file ) -1
	Variable len  = idex
	do
		if( cmpstr( file[idex], "." ) == 0 )
			dotdex = idex
			idex = 0
		endif
		idex -= 1
	while( idex > 0 )
	
	if( dotdex != -1 )
		if( len - 3 != dotdex )
			print "Non standard length for file extension"
		endif
		ret_ext = file[dotdex+1, len ]
	endif
	
	Variable bdex = -1
	if( dotdex != -1 )
		idex = dotdex
		do
			if( (cmpstr( file[idex], ":" ) == 0) | (cmpstr(file[idex], "\\" )==0) )
				bdex = idex
				idex = 0
			endif
			idex -= 1
		while( idex > 0 )
	endif
	
	if( bdex != -1 )
		ret_ext = file[ 0, bdex ]
	else
		ret_ext = ""//file[ 0, dotdex - 1 ]
	endif
	
	return ret_ext
End	
Function GFL_Filelist( path2files, report, list_Wave, fileMask )
	String path2files
	Variable report
	Wave/T list_Wave
	String fileMask
	
	String thisFile
	Variable idex = 0, dot_dex = 20, dot_count = 0, line_width = 20
	if( WaveExists( list_wave ) )
		redimension/n=0 list_wave
	else
		print "Can't see list_wave as passed to GFL_Filelist"
		return -1
	endif
	PathInfo $path2files
	if( v_flag != 1 )
		print "Can't see path called", path2files
		return -1
	endif
	NewPath/Q tempGFLPath, s_path
	do
		thisFile = IndexedFile( tempGFLPath, idex, fileMask )
		if( strlen( thisFile )< 2 )
			break
		endif
		idex += 1
		if( report > 0 )
			if( (idex/dot_dex) == round( idex/dot_dex ) )
				printf "."; dot_count += 1
			endif
			if( dot_count > line_width )
				dot_count = 0
				printf "%g\r", idex
			endif
		endif
		AppendString( list_wave, thisFile )
	while( 1 )
	KillPath tempGFLPath
	
End
Function GFL_FilelistAtOnce( path2files, report, list_Wave, fileMask )
	String path2files
	Variable report
	Wave/T list_Wave
	String fileMask
	
	String thisFile
	Variable idex = 0, dot_dex = 25, dot_count = 0, line_width = 10
	if( WaveExists( list_wave ) )
		redimension/n=0 list_wave
	else
		print "Can't see list_wave as passed to GFL_Filelist"
		return -1
	endif
	PathInfo $path2files
	if( v_flag != 1 )
		print "Can't see path called", path2files
		return -1
	endif
	NewPath/Q/O tempGFLPath, s_path
	if( report > 0 )
		print "Begining all encompassing dirlist"
	endif
	String theseFiles = IndexedFile( tempGFLPath, -1, fileMask )
	Variable count = ItemsInList( theseFiles )
	do
		thisFile = StringFromList( idex, theseFiles )
		if( strlen( thisFile )< 2 )
			break
		endif
		idex += 1
		if( report > 0 )
			if( (idex/dot_dex) == round( idex/dot_dex ) )
				printf "."; dot_count += 1
			endif
			if( dot_count > line_width )
				dot_count = 0
				printf "%g\r", idex
			endif
		endif
		AppendString( list_wave, thisFile )
	while( count )
	KillPath/Z tempGFLPath
	return 1
End
Function GenerateFolderList( pathName, pathString, usePath, list_Wave, fileMask, quietOrReport )
	String pathName, pathString
	Variable usePath
	Wave/T list_Wave
	String fileMask
	Variable quietOrReport
	
	// usePath controls which of the paths is used in making the list
	// usePath = 1 means use the pathName as is
	// usePath = 0 means make a path using pathString
	if( (cmpstr(pathString, "c:")==0) %& (usePath == 0 ) )
		print "Igor 4.02 doesn't like this, I don't know why"
	endif
	
	if( usePath == 0 )
		NewPath/O/Q ThisFileListPath, pathString
		Pathinfo ThisFileListPath
		if( v_flag != 1 )
			print "Error in GenerateFileList, can't make path ", pathString
			return 0
		endif
	endif
	
	if( usePath == 0 )
		GFL_Folderlist( "ThisFileListPath", quietOrReport, list_Wave, fileMask )
	else
		GFL_Folderlist( pathName, quietOrReport, list_Wave, fileMask )
	endif
	return numpnts( list_Wave )
End
Function GFL_Folderlist( path2files, report, list_Wave, fileMask )
	String path2files
	Variable report
	Wave/T list_Wave
	String fileMask
	
	String thisFolder
	Variable idex = 0, dot_dex = 25, dot_count = 0, line_width = 10
	if( WaveExists( list_wave ) )
		redimension/n=0 list_wave
	else
		print "Can't see list_wave as passed to GFL_Filelist"
		return -1
	endif
	PathInfo $path2files
	if( v_flag != 1 )
		print "Can't see path called", path2files
		return -1
	endif
	NewPath/Q tempGFLPath, s_path
	do
		thisFolder = IndexedDir( tempGFLPath, idex, 0 )
		if( strlen( thisFolder )< 2 )
			break
		endif
		idex += 1
		if( report > 0 )
			if( (idex/dot_dex) == round( idex/dot_dex ) )
				printf "."; dot_count += 1
			endif
			if( dot_count > line_width )
				dot_count = 0
				printf "%g\r", idex
			endif
		endif
		AppendString( list_wave, thisFolder )
	while( 1 )
	KillPath/Z tempGFLPath
	
End
Function ConvertTimeInTextWaveToNumeric(tw, newName)
        Wave/T tw
        String newName                  // Name to use for the new wave.


        Variable numPoints = numpnts(tw)
        Make/O/D/N=(numPoints) $newName
        Wave w = $newName


        Variable i
        Variable hour, minute, second
        String str


        for(i=0; i<numPoints; i+=1)
                str = tw[i]
                sscanf str, "%g:%g:%g", hour, minute, second
                w[i] = 3600*hour + 60*minute + second
        endfor
End

Function DetermineTimeLag( w_1, w_2, correl_lo, correl_hi )
	Wave w_1, w_2
	Variable correl_lo, correl_hi
	Variable return_time_lag = 0
	Variable could_be_off_by = 20
	
	if( correl_lo != -99 )
		Duplicate/O/R=(correl_lo, correl_hi) w_1, sw1, time_base
		Duplicate/O/R=(correl_lo, correl_hi) w_2, sw2
	else
		Duplicate/O w_1, sw1
		Duplicate/O w_2, sw2
	endif
	Duplicate/O sw1, time_base
	time_base = pnt2x( sw1, p )
	sw1 = interp( x, time_base, sw1 )
	sw2 = interp( x, time_base, sw2 )
	Variable ret_time
	setscale/p x, 0, 1, "x", sw1, sw2
	
	
	Correlate sw1, sw2
	Correlate sw1, sw1
	
	if( wintype( "correl_win" ) )
		dowindow/k correl_win
	endif
	display/l=lag_ax sw2
	dowindow/c correl_win
	appendtograph/l=auto_ax sw1;				
	Variable half_way = 1/2 * (sw1[0] + sw1[numpnts(sw1) ] )
	setaxis bottom  -could_be_off_by, could_be_off_by
	Execute("HandyGraphButtons()")
	
	Make/N=4/O/D coefs_1, coefs_2
	coefs_1 = {1e9, 1e7, 0, 5  };		coefs_2 = { 1e9, 1e7, -5, 5 };
	CurveFit/Q gauss kwCWave=coefs_2, sw2(-could_be_off_by,could_be_off_by) /D 
	
	CurveFit/Q gauss kwCWave=coefs_1, sw1(-could_be_off_by,could_be_off_by) /D 
	return_time_lag = coefs_2[2] - coefs_1[2]
	
	ModifyGraph rgb(sw2)=(0,0,39168),rgb(sw1)=(39168,0,15616);DelayUpdate
	ModifyGraph rgb(fit_sw2)=(16384,16384,65280)
	String text_str
	sprintf text_str, "time lag = %4.2f", return_time_lag
	TextBox/C/N=text0/F=0/A=MC text_str
	ScaleAllYAxes( "" )
	
	dowindow/b correl_win
	return return_time_lag

End


Function MakeOrSetGraphGentle( left, top, right, bottom, name )
	Variable left, top, right, bottom
	String name
	// /W=(left,top,right,bottom)
	// gives the graph a specific location and size on the screen. 
	// Coordinates for /W are in points unless /I or /M are specified before /W.
	if( WinType( name ) == 1 )
		//DoWindow/K $name
	else
		Display/W=(left, top, right, bottom)/K=1
		DoWindow/C $name
	endif
	DoWindow/F $name
End
Function/T MakeAndOrSetDFNested( data_folder )
	string data_folder
	
	string old_DF = GetDataFolder(1)
	if( !DataFolderExists( data_folder ) )
		NewDataFolder $data_folder
	endif
	SetDataFolder $data_folder
	return old_DF
End

Function FileNameToDAT( filename, convention )
	String filename, convention
//  Chaparro
	
	String yearstr, daystr, monthstr, hourstr, minutestr, secondstr, onlydateStr, onlytimeStr, halfhourStr
	Variable yearval, dayval, monthval, hourval, minuteval, secondval
	
	String jfile = StringFromList( 0, filename, "." ) // just in case the whole file has been passed
	
	strswitch (lowerstr(convention))
		case "tdlwintel_date_timestamp":
		case "YYMMDD_HHMMSS":
			onlydateStr = StringFromList( 0, jfile, "_" )
			onlytimeStr = StringFromList( 1, jfile, "_" )
			yearstr = onlydateStr[0,1]
			monthstr = onlydateStr[2,3]
			daystr = onlydateStr[4,5]
			hourstr = onlytimeStr[0,1]
			minutestr = onlytimeStr[2,3]
			secondstr = onlytimeStr[4,5]
			break;
		case "CAL_date_timestamp":
		case "YYMMDD_":
			onlydateStr = StringFromList( 0, jfile, "_" )
			onlytimeStr = StringFromList( 1, jfile, "_" )
			yearstr = onlydateStr[0,1]
			monthstr = onlydateStr[2,3]
			daystr = onlydateStr[4,5]
			hourstr = "00"
			minutestr = "00"
			secondstr = "00"
			break;
		case "EddyOut_date_timestamp":
			onlydateStr = StringFromList( 0, jfile, "_" )
			hourstr = StringFromList( 1, jfile, "_" )
			halfhourStr = StringFromList( 2, jfile, "_" )
			yearstr = onlydateStr[0,1]
			monthstr = onlydateStr[2,3]
			daystr = onlydateStr[4,5]
			if(cmpstr(halfhourStr,"0") == 0)
				minutestr = "00"
			elseif(cmpstr(halfhourStr,"1") == 0)
				minutestr = "30"
			else
				print "ERROR! Unrecognized EddyOut filename format!"
			endif
			secondstr = "00"
			break;
		case "YYYYMMDD_HHMMSS":
			onlydateStr = StringFromList( 0, jfile, "_" )
			onlytimeStr = StringFromList( 1, jfile, "_" )
			yearstr = onlydateStr[0,3]
			monthstr = onlydateStr[4,5]
			daystr = onlydateStr[6,7]
			hourstr = onlytimeStr[0,1]
			minutestr = onlytimeStr[2,3]
			secondstr = onlytimeStr[4,5]
			break;	
	endswitch
	
	yearval = str2num( yearstr );
	if( yearval < 87 )
		yearval += 2000
	endif
	
	monthval = str2num( monthstr );
	dayval = str2num( daystr );
	hourval = str2num( hourstr );
	minuteval = str2num( minutestr );
	hourval = str2num( hourstr );
	secondval = str2num( secondstr );
	
	return date2secs( yearval, monthval, dayval ) + 3600 * hourval + 60*minuteval + 1*secondval
End




Function DateTime2DecimalYear( adatetime )
	variable adatetime
	
	variable yy
	string datestr = StringFromList( 0, Secs2Date( adatetime, -1 ), " " )
	sprintf datestr, "%s/%s/%s", StringFromList( 1, datestr, "/" ),  StringFromList( 0, datestr, "/" ),  StringFromList( 2, datestr, "/" )
	sprintf yy, "%s %s", datestr, Secs2Time( adatetime, 3 )
	
	return yy
End

Function/T DateTime2Text( adatetime, [format] )
	variable adatetime
	string format
	
	string yy
	string datestr = StringFromList( 0, Secs2Date( adatetime, -1 ), " " )
	
	string loc_format = "american"
	if( !ParamIsDefault( format ) )
		loc_format = format;
	endif
	
	STRUCT ari_datetime dat
	dat.datval = adatetime
		
	//sprintf datestr, "%s/%s/%s", StringFromList( 1, datestr, "/" ),  StringFromList( 0, datestr, "/" ),  StringFromList( 2, datestr, "/" )
	//sprintf yy, "%s %s", datestr, Secs2Time( adatetime, 3 )
	DTI_DateTimeHandler( dat, ari_UpdateFromNum )
	strswitch( loc_format )
		case "filename":
			yy = dat.filename
			break;
		case "european":
			yy = dat.european
			break;
		case "filename2y":
			yy = dat.filename
			break;
		case "sortable":
			yy = dat.sortable
			break;
		case "american":
			yy = dat.american
			break;
		default:	
			yy = dat.american
			break;			
	endswitch
	
	return yy
End
Function/S DateTime2ShortText( adatetime )
	variable adatetime
	
	string yy
	sprintf yy, "%s_%s" Secs2Date(adatetime, 0), Secs2Time( adatetime, 3 )
	
	yy = scReplaceCharWChar( yy, "/", "" )
	yy = scReplaceCharWChar( yy, ":", "" )
	return yy
End
Function/T FileDateTime2ShortText( adatetime )
	variable adatetime
	
	string yy = Secs2Date( adatetime,0)
	
	// THESE depend on regional settings in computer control panels... sucks
	String year = StringFromList( 2, yy, "/" )
	String month = StringFromList( 0, yy, "/" )
	String day = stringfromlist( 1, yy, "/" )
	
	String dateComponent
	sprintf dateComponent, "%4s%2s%2s",  year, month, day
	
	sprintf yy, "%s_%s" dateComponent, Secs2Time( adatetime, 3 )
	
	yy = scReplaceCharWChar( yy, "/", "" )
	yy = scReplaceCharWChar( yy, ":", "" )
	return yy
End
Function/T DateTime2JustDateText( adatetime )
	variable adatetime
	
	string yy = Secs2Date( adatetime,0)
	
	// THESE depend on regional settings in computer control panels... sucks
	String year = StringFromList( 2, yy, "/" )
	String month = StringFromList( 0, yy, "/" )
	String day = stringfromlist( 1, yy, "/" )
	
	String dateComponent
	sprintf dateComponent, "%02d%02d%02d",  str2num(year), str2num(month), str2num(day)
	
	sprintf yy, "%s" dateComponent
	
	yy = scReplaceCharWChar( yy, "/", "" )
	yy = scReplaceCharWChar( yy, ":", "" )
	return yy
End
Function DateTime2JustDate( adatetime )
	variable adatetime
	
	String yy = Secs2Date( adatetime,-1)
	
	
	// THESE do not depend on regional settings in computer control panels... nice
	Variable year = str2num(	StringFromList( 2, yy, "/" ))
	Variable month = str2num(	StringFromList( 1, yy, "/" ))
	Variable day = str2num(	Stringfromlist( 0, yy, "/" )	)
	
	return date2secs( year, month, day )
End

Function DateTime2JustHour( adatetime )
	variable adatetime
	
	String yy = datetime2text( adatetime)
	
	Variable hour = Str2Num( StringFromList( 0, StringFromList( 1, yy, " " ), ":" ))
	return hour
End
Function DateTime2JustMinute( adatetime )
	variable adatetime
	
	String yy = datetime2text( adatetime)
	
	Variable minute = Str2Num( StringFromList( 1, StringFromList( 1, yy, " " ), ":" ))
	return minute
End
Function DateTime2JustTime( adatetime )
	variable adatetime
	
	String yy = Secs2Time( adatetime, 3)
	
	
	// THESE do not depend on regional settings in computer control panels... nice
	Variable hour = str2num(	StringFromList( 0, yy, ":" ))
	Variable minute = str2num(	StringFromList( 1, yy, ":" ))
	Variable seconds = str2num(	Stringfromlist( 2, yy, ":" )	)
	
	return 3600 * hour + 60*minute + seconds
End
Function/T FileDateTime2JustDate( adatetime )
	variable adatetime
	
	string yy = Secs2Date( adatetime,0)
	
	// THESE depend on regional settings in computer control panels... sucks
	String year = StringFromList( 2, yy, "/" )
	String month = StringFromList( 0, yy, "/" )
	String day = stringfromlist( 1, yy, "/" )
	
	String dateComponent
	sprintf dateComponent, "%4s%2s%2s",  year, month, day
	
	sprintf yy, "rd_%s" dateComponent
	
	yy = scReplaceCharWChar( yy, "/", "" )
	yy = scReplaceCharWChar( yy, ":", "" )
	return yy
End
Function/T DateTime2ShortTimeText( adatetime )
	variable adatetime
	
	string yy
	sprintf yy, "%s" Secs2Time( adatetime, 3 )
	
	yy = scReplaceCharWChar( yy, ":", "" )
	return yy
End
Function Text2DateTime( textDateTime )
	String textDateTime

	Variable year, month, day, hour, minute, second
	
	sscanf textDateTime, "%d/%d/%d %d:%d:%d", month, day, year, hour, minute, second
	if( year < 100 )
		if( year < 39 )
			year += 2000
		else
			year += 2100
		endif
	endif
	return 3600 * hour + 60 * minute + second + Date2Secs( year, month, day )
End

// DTI_text2Datetime and DTI_datetime2text provides an expanded set of time tools


///////////////////////////////////////////////////////////////
////////////// DateTime to Text and Text to DateTime ////// start  //////
///////////////////////////////////////////////////////////////
// Allowed formatStrs
// 'american', 'european',  'sortable', 'filename', 'monthspell', 
// almost any useage of YYYY MM DD HH/hh mm SS/ss

// named types are:
// american:		"MM/DD/YYYY HH:mm:SS"
// european:		"MM/DD/YYYY HH:mm:SS"
// sortable:			"YYYY/MM/DD HH:mm:SS"
// american:		"MM/DD/YYYY HH:mm:SS.zzz"
// european:		"MM/DD/YYYY HH:mm:SS.zzz"
// sortable:			"YYYY/MM/DD HH:mm:SS.zzz"
// filename:		"YYYYMMDD_HHmmSS"
// filename2y:		"YYMMDD_HHmmSS"
// dash-american:	"MM-DD-YYYY HH:mm:SS"
// dash-european:	"DD-MM-YYYY HH:mm:SS"
// dash-sortable:	"YYYY-MM-DD HH:mm:SS"

// you can also use any other format iwth YYYY mm etc.
Function/S DTI_DateTime2Text( adatetime, formatStr )
	Variable adatetime
	String formatStr
	
	STRUCT ari_datetime mydat								// carve out a structure for datetime
	mydat.datval = adatetime								// push number value into structure
	DTI_DateTimeHandler( mydat, ari_UpdateFromNum )		// ask handler to popupate all other fields of the structure
	
	// this is the speed intercept indicating formatStr is found and already done
	if( strlen( formatStr ) == 0 )
		return mydat.sortable
	endif

	Variable hasFractionalSeconds = 0;
	if( mydat.zzz > 0 )
		hasFractionalSeconds = 1;
	endif
	
	strswitch (formatStr)
		case "american":
		case "standard":
		case "default":
		
			return mydat.american
			break;
		case "dash-american":
			return replaceString("/",mydat.american, "-")
			break;
		case "european":
			return mydat.european
			break;
		case "dash-european":
			return replaceString("/", mydat.european, "-")
			break;
		case "american_z":
			return mydat.american_z;
			break;
		case "sortable_z":
			return mydat.sortable_z;
			break;
		case "european_z":
			return mydat.european_z;
			break;

		case "filename":
			return mydat.filename
			break;
		case "filename2y":
			String filenameFull =  mydat.filename
			return filenameFull[2,strlen(filenameFull)-1]
			break
		case "sortable":
			return mydat.sortable
			break;
		case "dash-sortable":
			return ReplaceString( "/", mydat.sortable, "-" )
			break; 
		case "legible":
		case "monthspell":
			return mydat.monthledge
			break;
		case "yyyyjdy_tod":
			return mydat.YYYYJDY_TOD
	endswitch
	
	// if we haven't exited, then format str might look like HHMMSS
	
	String returnStr = formatStr, insertStr, newStr
	
	// 
	
	if( strsearch( returnStr, "YYYY", 0 ) > -1 )
		insertStr = num2str( mydat.year );
		returnStr = ReplaceStringInStringVLen( returnStr, "YYYY", insertStr )
	endif
	if( strsearch( returnStr, "YY", 0 ) > -1 )
		sprintf insertStr, "%02d", Mod(mydat.year,100) ;
		returnStr = ReplaceStringInStringVLen( returnStr, "YY", insertStr )
	endif
	 
	if( strsearch( returnStr, "MM", 0 ) > -1 )
		sprintf insertStr, "%02d", mydat.month ;
		returnStr = ReplaceStringInStringVLen( returnStr, "MM", insertStr )
	endif

	if( strsearch( returnStr, "DD", 0 ) > -1 )
		sprintf insertStr, "%02d", mydat.day;
		returnStr = ReplaceStringInStringVLen( returnStr, "DD", insertStr )
	endif
	
	if( strsearch( returnStr, "mm", 0 ) > -1 )
		sprintf insertStr, "%02d", mydat.minute;
		returnStr = ReplaceStringInStringVLen( returnStr, "mm", insertStr )
	endif
	if( (strsearch( returnStr, "hh", 0 ) > -1 )) 
		sprintf insertStr, "%02d", mydat.hour;
		returnStr = ReplaceStringInStringVLen( returnStr, "hh", insertStr )
	endif
	if( (strsearch( returnStr, "ss", 0 ) > -1) )
		sprintf insertStr, "%02d", mydat.second;
		returnStr = ReplaceStringInStringVLen( returnStr, "ss", insertStr )
	endif


	if( (strsearch( returnStr, "HH", 0 ) > -1 )) 
		sprintf insertStr, "%02d", mydat.hour;
		returnStr = ReplaceStringInStringVLen( returnStr, "HH", insertStr )
	endif
	if( (strsearch( returnStr, "SS", 0 ) > -1) )
		sprintf insertStr, "%02d", mydat.second;
		returnStr = ReplaceStringInStringVLen( returnStr, "SS", insertStr )
	endif
	

	return returnStr
End

// formatStr isn't quite as flexible as the other function here
// allowed types are
// american:		"MM/DD/YYYY HH:mm:SS"
// european:		"MM/DD/YYYY HH:mm:SS"
// sortable:			"YYYY/MM/DD HH:mm:SS"
// filename:		"YYYYMMDD_HHmmSS"
// filename2y:		"YYMMDD_HHmmSS"
// dash-american:	"MM-DD-YYYY HH:mm:SS"
// dash-european:	"DD-MM-YYYY HH:mm:SS"
// dash-sortable:	"YYYY-MM-DD HH:mm:SS"

Function DTI_Text2DateTime( datetimeStr, formatStr )
	String datetimeStr
	String formatStr
	
	Variable returnVal
	STRUCT ari_datetime mydat								// carve out a structure for datetime
	
	Variable customScan = 1;
	String dashtoSlash = "";
	
	// this is the speed intercept indicating formatStr is found and already done
	if( strlen( formatStr ) == 0 )
		DTI_DateTimeHandler( mydat, ari_UpdateFromAmerican, adatetimeStr = datetimeStr );	customScan = 0;
	endif
	
	strswitch (formatStr)
		case "default":
		case "american":
		case "standard":
			DTI_DateTimeHandler( mydat, ari_UpdateFromAmerican, adatetimeStr = datetimeStr );	customScan = 0;
			break;
		case "american_z":
			DTI_DateTimeHandler( mydat, ari_UpdateFromAmerican, adatetimeStr = datetimeStr );	customScan = 0;
			break;
		case "european":
			DTI_DateTimeHandler( mydat, ari_UpdateFromEuropean, adatetimeStr = datetimeStr );	customScan = 0;
			break;
		case "european_z":
			DTI_DateTimeHandler( mydat, ari_UpdateFromEuropean, adatetimeStr = datetimeStr );	customScan = 0;
			break;
		case "filename":
			DTI_DateTimeHandler( mydat, ari_UpdateFromFileName, adatetimeStr = datetimeStr );	customScan = 0;
			break;
		case "filename2y":
			DTI_DateTimeHandler( mydat, ari_UpdateFromFileName2Y, adatetimeStr = datetimeStr );	customScan = 0;
			break;
		case "sortable":
			DTI_DateTimeHandler( mydat, ari_UpdateFromSort, adatetimeStr = datetimeStr );	customScan = 0;
			break;		
		case "sortable_z":
			DTI_DateTimeHandler( mydat, ari_UpdateFromSort, adatetimeStr = datetimeStr );	customScan = 0;
			break;
		case "legible":
		case "monthspell":
			DTI_DateTimeHandler( mydat, ari_UpdateFromLegible, adatetimeStr = datetimeStr );	customScan = 0;
			break;
			
		case "dash-american":
			dashtoSlash = ReplaceString( "-", datetimeStr, "/")
			DTI_DateTimeHandler( mydat, ari_UpdateFromAmerican, adatetimeStr = dashtoSlash );	customScan = 0;
			break;
		case "dash-european":
			dashtoSlash = ReplaceString("-", datetimeStr, "/" )
			DTI_DateTimeHandler( mydat, ari_UpdateFromEuropean, adatetimeStr = dashtoSlash );	customScan = 0;
			break;
		case "dash-sortable":
			dashtoSlash = ReplaceString( "-", datetimeStr, "/" )
			DTI_DateTimeHandler( mydat, ari_UpdateFromSort, adatetimeStr = dashtoSlash );	customScan = 0;
			break;

		case "yyyyjdy_tod":
			DTI_DateTimeHandler( mydat, ari_UpdateFromYYYYJDY_TOD, adatetimeStr = datetimeStr );	customScan = 0;
			break;	

	endswitch
	
	if( customScan == 0 )
		//we have set mydat
		returnVal = mydat.datval;
		return returnVal;			//	<< Route out of the function
	endif
	
	// if we haven't exited, then format str might look like HHMMSS
	
	String returnStr = formatStr, insertStr, newStr
	
	// 
	
	if( strsearch( returnStr, "YYYY", 0 ) > -1 )
		insertStr = num2str( mydat.year );
		returnStr = ReplaceStringInStringVLen( returnStr, "YYYY", insertStr )
	endif
	if( strsearch( returnStr, "YY", 0 ) > -1 )
		sprintf insertStr, "%02d", Mod(mydat.year,100) ;
		returnStr = ReplaceStringInStringVLen( returnStr, "YY", insertStr )
	endif
	 
	if( strsearch( returnStr, "MM", 0 ) > -1 )
		sprintf insertStr, "%02d", mydat.month ;
		returnStr = ReplaceStringInStringVLen( returnStr, "MM", insertStr )
	endif

	if( strsearch( returnStr, "DD", 0 ) > -1 )
		sprintf insertStr, "%02d", mydat.day;
		returnStr = ReplaceStringInStringVLen( returnStr, "DD", insertStr )
	endif
	
	if( strsearch( returnStr, "mm", 0 ) > -1 )
		sprintf insertStr, "%02d", mydat.minute;
		returnStr = ReplaceStringInStringVLen( returnStr, "mm", insertStr )
	endif
	if( (strsearch( returnStr, "hh", 0 ) > -1 )) 
		sprintf insertStr, "%02d", mydat.hour;
		returnStr = ReplaceStringInStringVLen( returnStr, "hh", insertStr )
	endif
	if( (strsearch( returnStr, "ss", 0 ) > -1) )
		sprintf insertStr, "%02d", mydat.second;
		returnStr = ReplaceStringInStringVLen( returnStr, "ss", insertStr )
	endif


	if( (strsearch( returnStr, "HH", 0 ) > -1 )) 
		sprintf insertStr, "%02d", mydat.hour;
		returnStr = ReplaceStringInStringVLen( returnStr, "HH", insertStr )
	endif
	if( (strsearch( returnStr, "SS", 0 ) > -1) )
		sprintf insertStr, "%02d", mydat.second;
		returnStr = ReplaceStringInStringVLen( returnStr, "SS", insertStr )
	endif
	

	return returnVal
End


// Call DTI_DateTimeHandler( mydat, ari_UpdateFromNum, adatetime=<date time value as argument> ) to push and set formats of mydat
// Call DTI_DateTimeHanler( mydat, ari_UpdateFromAmerican, adatetimeStr = "MM/DD/YYYY HH:MM:SS" to set and push formats from this update
// Calling DTI_dateTimeHander( mydat, any ) resets formats according to mydat.datval

Function DTI_DateTimeHandler( dat, event, [adatetime, adatetimeStr] )
	STRUCT ari_datetime &dat
	Variable event
	Variable adatetime
	String adatetimeStr

	
	String loc_adatetimeStr = ""
	if( !ParamIsDefault( adatetimeStr) ) 
		loc_adatetimeStr = adatetimeStr		
	endif

	Variable loc_adatetime = -1
	if( !ParamIsDefault( adatetime) ) 
		loc_adatetime = adatetime
		dat.datval = adatetime
	endif
	////////////////////	DateTimeHandler
	String datestr, timestr, qstr, SpelledMonth, MonthAndDay, YearAndTime, JustTimeStr, JustYearStr, WeekDayStr, TODstr, JulianStr
	Variable sam, qyear, qmon, qday, qhour, qsec, qmin, qzzz = 0, SetValFromStr = 0, Julian, JulianHelper
			

	// qzzz will be the explicit capture of fractional seconds
	// qsec will *also* have the fractional seconds, but passively	
			
	switch (event)
		case ari_UpdateFromNum:
			// this is here for form's sake ~ dat.datval is either set to the adatetime arg when present OR IS ASSUMED to have been set to truth.
			qzzz = 1000 * (dat.datval - floor( dat.datval ));
			SetValFromStr = 0;
			break;
		case ari_UpdateFromAmerican:
			if( !ParamIsDefault( adatetimeStr ) )
				qstr = adatetimeStr
			else
				qstr = dat.american
			endif
			
			qzzz = DTI_GetFracSecFromStr( qstr );
			
			qyear 	= str2num( StringFromList( 2, StringFromList( 0, qstr, " " ), "/" )); 
			qmon 	= str2num( StringFromList( 0, StringFromList( 0, qstr, " " ), "/" )); 
			qday 	= str2num( StringFromList( 1, StringFromList( 0, qstr, " " ), "/" )); 
			qhour 	= str2num( StringFromList( 0, StringFromList( 1, qstr, " " ), ":" )); 
			qmin 	= str2num( StringFromList( 1, StringFromList( 1, qstr, " " ), ":" )); 
			qsec 	= str2num( StringFromList( 2, StringFromList( 1, qstr, " " ), ":" ));

			SetValFromStr = 1;
			break;

		case ari_UpdateFromEuropean:
			if( !ParamIsDefault( adatetimeStr ) )
				qstr = adatetimeStr
			else
				qstr = dat.european
			endif
						qzzz = DTI_GetFracSecFromStr( qstr );

			qyear 	= str2num( StringFromList( 2, StringFromList( 0, qstr, " " ), "/" )); 
			qmon 	= str2num( StringFromList( 1, StringFromList( 0, qstr, " " ), "/" )); 
			qday 	= str2num( StringFromList( 0, StringFromList( 0, qstr, " " ), "/" )); 
			qhour 	= str2num( StringFromList( 0, StringFromList( 1, qstr, " " ), ":" )); 
			qmin 	= str2num( StringFromList( 1, StringFromList( 1, qstr, " " ), ":" )); 
			qsec 	= str2num( StringFromList( 2, StringFromList( 1, qstr, " " ), ":" )); 
			SetValFromStr = 1;
			break;
		case ari_UpdateFromSort:
			if( !ParamIsDefault( adatetimeStr ) )
				qstr = adatetimeStr
			else
				qstr = dat.sortable
			endif
			
						qzzz = DTI_GetFracSecFromStr( qstr );

			qyear 	= str2num( StringFromList( 0, StringFromList( 0, qstr, " " ), "/" )); 
			qmon 	= str2num( StringFromList( 1, StringFromList( 0, qstr, " " ), "/" )); 
			qday 	= str2num( StringFromList( 2, StringFromList( 0, qstr, " " ), "/" )); 
			qhour 	= str2num( StringFromList( 0, StringFromList( 1, qstr, " " ), ":" )); 
			qmin 	= str2num( StringFromList( 1, StringFromList( 1, qstr, " " ), ":" )); 
			qsec 	= str2num( StringFromList( 2, StringFromList( 1, qstr, " " ), ":" )); 
			SetValFromStr = 1;
			break;
		case ari_UpdateFromFilename:
			if( !ParamIsDefault( adatetimeStr ) )
				qstr = adatetimeStr
			else
				qstr = dat.filename
			endif
			datestr = StringFromList( 0, qstr, "_" );
			timestr = StringFromList( 1, qstr, "_" );
			
			qyear 	= str2num( datestr[0,3]);
			qmon 	=  str2num( datestr[4,5]);
			qday 	= str2num( datestr[6,7]);
			qhour 	= str2num( timestr[0,1]); 
			qmin 	= str2num(timestr[2,3]); 
			qsec 	= str2num( timestr[4,5]); 
			SetValFromStr = 1;
			break;
		case ari_UpdateFromFilename2Y:
			if( !ParamIsDefault( adatetimeStr ) )
				qstr = adatetimeStr
			else
				qstr = dat.filename
			endif
			datestr = StringFromList( 0, qstr, "_" );
			timestr = StringFromList( 1, qstr, "_" );
			
			qyear 	= 2000 + str2num( datestr[0,1]);
			qmon 	=  str2num( datestr[2,3]);
			qday 	= str2num( datestr[4,5]);
			qhour 	= str2num( timestr[0,1]); 
			qmin 	= str2num(timestr[2,3]);
			if( strlen( timestr ) > 3 ) 	
				qsec 	= str2num( timestr[4,5]); 
			else
				qsec = 0
			endif
			SetValFromStr = 1;
			break;
		case ari_UpdateFromLegible:
			if( !ParamIsDefault( adatetimeStr ) )
				qstr = adatetimeStr
			else
				qstr = dat.monthledge
			endif
			String infoStr = qstr[4, strlen( qstr )-1 ];
			sscanf infoStr, "%s %d,%d %d:%d:%d", SpelledMonth, qday, qyear, qhour, qmin, qsec 
		
			strswitch( lowerStr( spelledMonth ) )
				case "jan":
					qmon 	= 1;	
					break;
				case "feb":
					qmon 	= 2;	
					break;
				case "mar":
					qmon 	= 3;	
					break;
				case "apr":
					qmon 	= 4;	
					break;
				case "may":
					qmon 	= 5;	
					break;
				case "jun":
					qmon 	= 6;	
					break;
				case "jul":
					qmon 	= 7;	
					break;
				case "aug":
					qmon 	= 8;	
					break;
				case "sep":
					qmon 	= 9;	
					break;
				case "oct":
					qmon 	= 10;	
					break;
				case "nov":
					qmon 	= 11;	
					break;
				case "dec":
					qmon 	= 12;	
					break;
			endswitch
			SetValFromStr = 1;
			break;


			// ari_UpdateFromYYYYJDY_TOD
		case ari_UpdateFromYYYYJDY_TOD:
			if( !ParamIsDefault( adatetimeStr ) )
				qstr = adatetimeStr
			else
				qstr = dat.YYYYJDY_TOD
			endif
			datestr = StringFromList( 0, qstr, "." );
			TODstr = StringFromList( 1, qstr, "." );
			
			JustYearStr = datestr[0,3];
			qyear 	= str2num( JustYearStr );
			JulianHelper = DateToJulian( qyear, 1, 1 );
			
			JulianStr = datestr[4, strlen( datestr ) - 1 ];
			Julian = str2num( JulianStr ) + JulianHelper - 1;
			datestr = JulianToDate( Julian, 0 )
			
			qmon 	=  str2num( StringFromList( 0, datestr, "/" ) );
			qday 	= str2num( StringFromList( 1, datestr, "/" ));
			
			qhour 	= 0; 
			qmin 	= 0 
			qsec 	= str2num( TODstr ) / 1000 * 3600 * 24; 
			SetValFromStr = 1;
			break;	
	endswitch
	if( SetvalFromStr )
	if( qzzz == 0 )
			dat.datval = date2secs( qyear, qmon, qday ) + qsec  + 60*qmin + 3600 * qhour

	else
		dat.datval = date2secs( qyear, qmon, qday ) + qzzz/1000.0 + floor( qsec ) + 60*qmin + 3600 * qhour
	endif
	endif
	///////////// dat.datval is true and set from above /////
	/////// the following base sets all format
	datestr = Secs2Date( dat.datval, -2 ); dat.year = str2num(StringFromList( 0, datestr, "-" )); dat.month = str2num(StringFromList( 1, datestr, "-" )); dat.day = str2num(StringFromList( 2, datestr, "-" ));
	sam = dat.datval - date2secs( dat.year, dat.month, dat.day );
	dat.zzz = qzzz;
	timestr = Secs2Time( dat.datval, 3 ); dat.hour = str2num(StringFromList( 0, timestr, ":" ));dat.minute = str2num(StringFromList( 1, timestr, ":" ));
	
	dat.second = floor( str2num(StringFromList( 2, timestr, ":" )) );
	
	dat.julian = dateToJulian( dat.year, dat.month, dat.day ) + sam/(24*3600)
	sprintf dat.american "%02d/%02d/%d %02d:%02d:%02d", dat.month, dat.day, dat.year, dat.hour, dat.minute, dat.second
	sprintf dat.european "%02d/%02d/%d %02d:%02d:%02d", dat.day, dat.month, dat.year, dat.hour, dat.minute, dat.second
	sprintf dat.sortable "%04d/%02d/%02d %02d:%02d:%02d", dat.year, dat.month, dat.day, dat.hour, dat.minute, dat.second
	sprintf dat.american_z "%02d/%02d/%d %02d:%02d:%02d.%03d", dat.month, dat.day, dat.year, dat.hour, dat.minute, dat.second, dat.zzz
	sprintf dat.european_z "%02d/%02d/%d %02d:%02d:%02d.%03d", dat.day, dat.month, dat.year, dat.hour, dat.minute, dat.second, dat.zzz
	sprintf dat.sortable_z "%04d/%02d/%02d %02d:%02d:%02d.%03d", dat.year, dat.month, dat.day, dat.hour, dat.minute, dat.second, dat.zzz
	sprintf dat.filename "%d%02d%02d_%02d%02d%02d", dat.year, dat.month, dat.day, dat.hour, dat.minute, dat.second
	sprintf dat.monthledge "%s %s", Secs2Date( dat.datval, 2 ), Secs2Time( dat.datval, 3 )
	sprintf dat.yyyyjdy_tod "%d%07.3f", dat.year, (dat.julian - DateToJulian( dat.year, 1, 1 ) + 1);
End

Function DTI_GetFracSecFromStr( qstr )
	String qstr

	Variable qzzz = 0;
	// this is added to support possible fractional seconds, e.g.
	// [9:42 AM] Tara Yacovitch
	// print DTI_datetime2text(DTI_text2datetime("05/21/2021 00:00:00.9","MM/DD/YYYY hh:mm:ss.z"),"MM/DD/YYYY hh:mm:ss.z")

	// The presumption is that any string with '.' will be using fractional seconds
	// we need to internally set qzzz to miliseconds to assign later

	if( strsearch( qstr, ".", 0 ) != -1 ) 
		String zStr = StringFromList( 1, StringFromList( 1, qstr, " " ), "." );
		if( strlen( zStr ) == 0 )
			qzzz = 0;
		else 
			if( strlen( zStr ) == 1 )
				qzzz = 100 * str2num( zStr );
			else 
				if( strlen( zStr ) == 2 )
					qzzz = 10 * str2num( zStr );
				else 
					if( strlen( zStr ) == 3 )
						qzzz = str2num( zStr );
					else
						qzzz = str2num( zStr[0,2] );
					endif
				endif
			endif
		endif 
	else
		qzzz = 0;
	endif
	
	return qzzz;
	
End

Constant ari_UpdateFromNum			=1
Constant ari_UpdateFromAmerican	 	=2
Constant ari_UpdateFromEuropean		=3
Constant ari_UpdateFromSort			=4
Constant ari_UpdateFromFileName		=5
Constant ari_UpdateFromLegible 		=6
Constant ari_UpdateFromFileName2Y		=7
Constant ari_UpdateFromYYYYJDY_TOD		=8

Structure ari_datetime

double	datval 	
int16	 	year 	
int16		month 	
int16		day 		
int16		hour 	
int16		minute 	
int16		second	
int16		zzz
	
double		julian	
	
String		month3Char
String		monthfullName
	
String		american
String		european	
String		sortable
String		american_z
String		european_z	
String		sortable_z
String		filename	
String		monthledge
String		YYYYJDY_TOD
	
	
EndStructure


Function/S DateTime2FileName( adatetime )
	Variable adatetime
	
	STRUCT ari_datetime mydat
	mydat.datval = adatetime
	DTI_DateTimeHandler( mydat, ari_UpdateFromNum )
	return mydat.filename
End

///////////////////////////////////////////////////////////////
////////////// DateTime to Text and Text to DateTime ////// stop   //////
///////////////////////////////////////////////////////////////

















Function/T scPadStrLen( str, len, char )
	String str
	Variable len
	String char
	
	String retstr = ""
	Variable idex, count = strlen( str )
	if( count > len )
		retstr = str[0,len-1]
	else
		retstr = str
		idex = strlen(str)
		do
			retstr = retstr + char[0]
			idex += 1
		while( idex < len )
	endif
	
	return retstr
End
Function/T scReplaceCharWChar( str, char_old, char )
	String str
	String char_old
	String char
	
	String retstr = ""
	Variable idex=0, count = strlen( str )
	do
		if( cmpstr( str[idex], char_old ) == 0 )
			retstr = retstr + char
		else
			retstr = retstr + str[idex]
		endif
		
		idex += 1
	while( idex < count )
	
	
	return retstr
End
Function MatchText_TextText( str, header_tw, data_tw )
	String str
	Wave/T header_tw, data_tw
	Variable idex = 0, found_dex = -1, count = numpnts( header_tw )
	if( count != numpnts( data_tw ) )
		print "Error in MatchText_TextText two dissimilar wavelengths"
		return -1
	endif
	do
		if( cmpstr( str, header_tw[idex] ) == 0 )
			found_dex = idex
			idex = count
		endif
		idex += 1
	while( idex < count )
	
	return found_dex
End

Function MatchText_TextNum( str, header_tw, data_w )
	String str
	Wave/T header_tw
	Wave data_w
	Variable idex = 0, found_dex = -1, count = numpnts( header_tw )
	if( count != numpnts( data_w ) )
		print "Error in MatchText_TextNum two dissimilar wavelengths"
		return -1
	endif
	do
		if( cmpstr( str, header_tw[idex] ) == 0 )
			found_dex = idex
			idex = count
		endif
		idex += 1
	while( idex < count )
	
	return found_dex
End

//String graphName = <name of your graph>
//SetWindow $graphName hook=YourWindowHook, hookEvents=1          // 1 means we want mouse click events.


//Your window hook will look something like this:


Function QMyWindowHook (infoStr)
        String infoStr
        
        Variable result = 0                     // 0 tells Igor to do normal event processing.


        String event= StringByKey("EVENT", infoStr)
        Variable mouseX = NumberByKey("MOUSEX", infoStr)
        Variable mouseY = NumberByKey("MOUSEY", infoStr)
        
        String mytraceInfo, trace
        Variable xAxisVal, yAxisVal
        strswitch(event)
                case "mousedown":
                        mytraceInfo = TraceFromPixel(mouseX, mouseY, "ONLY:templateY")
                        trace = StringByKey("TRACE", mytraceInfo)
                        xAxisVal = AxisValFromPixel("", "bottom", mouseX)
                        yAxisVal = AxisValFromPixel("", "left", mouseX)
                        printf "mousedown @ %g, %g or on %s\r", xAxisVal, yAxisVal, trace
                 case "mouseup":
                        mytraceInfo = TraceFromPixel(mouseX, mouseY, "ONLY:templateY")
                        trace = StringByKey("TRACE", mytraceInfo)
                        xAxisVal = AxisValFromPixel("", "bottom", mouseX)
                        yAxisVal = AxisValFromPixel("", "left", mouseX)
                        printf "mouseup @ %g, %g or on %s\r", xAxisVal, yAxisVal, trace                    
               
                        
                        
                        //<Do your thing here>
                        //if (you want Igor to skip normal click processing)
                         //       result = 1      // Non-zero tells Igor to skip normal event processing.
                        //break
        endswitch
        
        return result
End



Function PutCursorsOnGraph(graphName)
	String graphName
	
	ShowInfo/W=$graphName
	
	String trace_list = TraceNameList( graphName, ";", 1 )
	Variable idex = 0, count = ItemsInList( trace_list )
	String this_trace, that_trace
	if( count > 0 )
		this_trace = StringFromList( 0, trace_list )
		Wave this_w = TraceNameToWaveRef( graphName, this_trace )
		Variable a_point, b_point
		a_point = numpnts( this_w ) * 1/3
		b_point = numpnts( this_w ) * 2/3
		if( count > 1 )
			that_trace = StringFromList( 1, trace_list )
			Wave that_w = TraceNameToWaveRef( graphName, that_trace )
			a_point = numpnts( this_w ) * 1/2
			b_point = numpnts( this_w ) * 1/2
		else
			Wave that_w = TraceNameToWaveRef( graphName, this_trace )
			that_trace = StringFromList( 0, trace_list )
		endif
		Cursor/P A, $this_trace, a_point
		Cursor/P B, $that_trace, b_point
	else
		printf "no traces on graph named [%s]\r", graphName
	endif
End

Function guCursorMovedHook( infoStr )
	String infoStr
	
	String graphName = WinName(0,1) // top graph
	Variable ValidFunc = 0
	
	if( cmpstr( graphName, "NYSL_Teal_SpecialGPS" ) == 0  )
		FuncRef ProtoCursorMovedFunc CurHandle = $"NYSLCurs_GPS2Time"
		ValidFunc = 1
	endif
	
	
	
	if( ValidFunc )
		CurHandle( graphName, infoStr )
	endif
End

Function ProtoCursorMovedFunc( graphName, infoStr )
	String graphName, infoStr
	
End

// ApplyColor2Graph( graphName, traceName, Color_str )
// Color_str must match one of the following...
//Red, Pink, Salmon, Wine, Orange, Yellow, Mustard, PhosGreen, Green, DarkGreen
//Cyan, Aqua, Blue, Midnight, SkyBlue, StormBlue, Purple, Violet
//Black, DarkGray/Grey, Gray/Grey, LightGray/Grey, White 

Function ApplyColor2Trace( graphName, traceName, Color_str )
	String graphName, traceName, Color_str
	
	String traceData = TraceInfo( graphName, traceName, 0 )
	if( strlen( traceData ) < 2 )
		return -1
	endif
	
	StrSwitch (Color_str)
		case "RedRed":
		case "Red":
			ModifyGraph/Z/W=$graphName rgb ($traceName) = (65280, 0, 0)
			break;
		case "Pink":
			ModifyGraph/Z/W=$graphName rgb ($traceName) =(65280,48896,48896)
			break;
		case "Wine":
			ModifyGraph/Z/W=$graphName rgb ($traceName) = (52224,0,20736)
			break;
		case "Salmon":
			ModifyGraph/Z/W=$graphName rgb ($traceName) = (65280,32768,32768)
			break;
		case "Orange":
			ModifyGraph/Z/W=$graphName rgb ($traceName) = (65280, 43520, 0)
			break;	
		case "Yellow":
			ModifyGraph/Z/W=$graphName rgb ($traceName) = (65280, 65280, 0)
			break;			
		case "Mustard":
			ModifyGraph/Z/W=$graphName rgb ($traceName) =(52224,52224,0)
			break;	

		case "PhosGreen":
			ModifyGraph/Z/W=$graphName rgb ($traceName) = (32768, 65280, 0)
			break;
		case "Green":
			ModifyGraph/Z/W=$graphName rgb ($traceName) = (0,52224, 0)
			break;
		case "DarkGreen":
			ModifyGraph/Z/W=$graphName rgb ($traceName) = (0, 26112,13056)
			break;			

		case "Cyan":
			ModifyGraph/Z/W=$graphName rgb ($traceName) =(0,65280,65280)
			break;
		case "Aqua":
			ModifyGraph/Z/W=$graphName rgb ($traceName) = (0,52224,52224)
			break;
		case "Blue":
			ModifyGraph/Z/W=$graphName rgb ($traceName) = (0, 12800, 52224)
			break;			
		case "Midnight":
			ModifyGraph/Z/W=$graphName rgb ($traceName) =(0, 0,39168)
			break;			
		case "SkyBlue":
			ModifyGraph/Z/W=$graphName rgb ($traceName) = (16384,48896,65280)
			break;
		case "StormBlue":
			ModifyGraph/Z/W=$graphName rgb ($traceName) =(0, 26112,39168)
			break;

		case "Purple":
			ModifyGraph/Z/W=$graphName rgb ($traceName) = (65280, 0, 52224)
			break;			
		case "Violet":
			ModifyGraph/Z/W=$graphName rgb ($traceName) = (26368, 0, 52224)
			break;

		case "Black":
			ModifyGraph/Z/W=$graphName rgb ($traceName) = (0, 0, 0)
			break;			
		case "DarkGray":
		case "DarkGrey":
			ModifyGraph/Z/W=$graphName rgb ($traceName) =(30464,30464,30464)
			break;	
		case "Gray":
		case "Grey":
			ModifyGraph/Z/W=$graphName rgb ($traceName) = (42520,42520, 42520)
			break;
		case "LightGray":
		case "LightGrey":
			ModifyGraph/Z/W=$graphName rgb ($traceName) = (52224, 52224,52224)
			break;			
		case "White":
			ModifyGraph/Z/W=$graphName rgb ($traceName) =(65535,65535,65535)
			break;

			

	EndSwitch
	
End

Function ApplyColor2Axis( graphName, axisName, Color_str )
	String graphName, axisName, Color_str
	
	
	
	Variable red, green, blue
	StrSwitch (Color_str)
		case "RedRed":
		case "Red":
			red = 65280;	green = 0; 	blue = 0
			break;
		case "Pink":
			red = 65280;	green = 48896; 	blue = 48896
			break;
		case "Wine":
			red = 52224;	green = 0; 	blue = 20736
			break;
		case "Salmon":
			red = 65280;	green = 32768; 	blue = 32768
			break;
		case "Orange":
			red = 65280;	green = 43520; 	blue = 0
			break;	
		case "Yellow":
			red = 65280;	green = 65280; 	blue = 0
			break;			
		case "Mustard":
			red = 52224;	green = 52224; 	blue = 0
			break;	

		case "PhosGreen":
			red = 32768;	green = 65280; 	blue = 0
			break;
		case "Green":
			red = 0;	green = 52224; 	blue = 0
			break;
		case "DarkGreen":
			red = 0;	green = 26112; 	blue = 13056
			break;			

		case "Cyan":
			red = 0;	green = 65280; 	blue = 65280
			break;
		case "Aqua":
			red = 0;	green = 52224; 	blue = 52224
			break;
		case "Blue":
			red = 0;	green = 12800; 	blue = 52224
			break;			
		case "Midnight":
			red = 0;	green = 0; 	blue = 39168
			break;			
		case "SkyBlue":
			red = 16384;	green = 48896; 	blue = 65280
			break;
		case "StormBlue":
			red = 0;	green = 26112; 	blue = 39168
			break;

		case "Purple":
			red = 65280;	green = 0; 	blue = 52224
			break;			
		case "Violet":
			red = 26368;	green = 0; 	blue = 52224
			break;

		case "Black":
			red = 0;	green = 0; 	blue = 0
			break;			
		case "DarkGray":
		case "DarkGrey":
			red = 30464;	green = 30464; 	blue = 30464
			break;	
		case "Gray":
		case "Grey":
			red = 42520;	green = 42520; 	blue = 42520
			break;
		case "LightGray":
		case "LightGrey":
			red = 52224;	green = 52224; 	blue = 52224
			break;			
		case "White":
			red = 65535;	green = 65535; 	blue = 65535
			break;
	EndSwitch
	ModifyGraph/Z axRGB($axisName)=(red, green, blue)
	ModifyGraph/Z tlblRGB($axisName)=(red, green, blue)
	ModifyGraph/Z alblRGB($axisName)=(red, green, blue)
	
End

Function SC_InterpXY2MadeDest( sx_w, sy_w, dest_str, template_str, code )
	Wave sx_w, sy_w
	String dest_str, template_str
	Variable code
	
	// code == 1 implies we should use the first sx_w point and the last sx_w point to define times of
	// dest_str
	
	// code == 2 implies we should find and use template_str for time wave
	
	Variable start_time, end_time
	
	if( code == 1 )
		start_time = sx_w[0]
		end_time = sx_w[ numpnts(sx_w) ]
	
	
		Make/O/D/N=( end_time - start_time + 1 ) $dest_str
		Wave dest_w = $dest_str
		SetScale/P x, start_time, 1, "dat" dest_w
	endif
	if( code == 2 )
		Wave template_w = $template_str
		Duplicate/O template_w, $dest_str
		Wave dest_w = $dest_str
	endif
	
	
	dest_w = interp( x, sx_w, sy_w )
End

Function GenericMarqueeMask( ) :GraphMarquee

	Wave/Z mask=root:mask  // the mask
//	Wave an_X_Wave=root:tdla_hcho
	
	String left_ax = "left"
	String bot_ax = "bottom"
	Variable lo_bot_bound, hi_bot_bound, lo_left_bound, hi_left_bound
	Variable lo_bot_pnt, hi_bot_pnt
	
	if( WaveExists( mask ) != 1 )
		print "No Mask wave for generic Marquee to work on"
		print "try duplicating the time wave, to 'mask' in the the root folder"
		print "and setting mask = 1 to start"
	else
		String trace_list = TraceNameList( "", ";", 1 )
		String trace_nfo = TraceInfo( "", StringFromList( 0, trace_list ), 0 )
		left_ax = StringByKey( "YAXIS", trace_nfo )
		bot_ax = StringByKey( "XAXIS", trace_nfo )
		Wave an_X_Wave = XwaveRefFromTrace( "", StringFromList( 0, trace_list ) )
		GetMarquee/K $left_ax, $bot_ax	
		lo_bot_bound = V_Left
		hi_bot_bound = V_Right
		lo_left_bound = V_Bottom
		hi_left_bound = V_Top
		
		printf "Acting on R:%g to L:%g and/or Low:%g up to Hi:%g\r", lo_bot_bound, hi_bot_bound, lo_left_bound, hi_left_bound
		
		// this will only work if point scaling is not being used!!
		// otherwise an x2pnt( ) call is needed
		lo_bot_pnt = BinarySearch( an_X_Wave, lo_bot_bound )
		hi_bot_pnt = BinarySearch( an_X_Wave, hi_bot_bound )
		
		mask[ lo_bot_pnt, hi_bot_pnt ] = nan
	
	endif

End





Function SortWavesInFolder( dataFolder, optString )
	String dataFolder, optString
	
	String useFolder = dataFolder
	if( cmpstr( dataFolder, "" ) == 0 )
		useFolder = "root"
	endif
	if( cmpstr( dataFolder, "root:" ) == 0 )
		useFolder = "root"
	endif
	
	Variable method = 0
	String method_str = StringByKey( "METHOD", UpperStr(optString) )
	if( cmpstr( LowerStr(method_str), "alpha" ) == 0 )
		method = 1
	endif
	if( cmpstr( LowerStr(method_str), "suffix" ) == 0 )
		method = 2
	endif
	if( method == 0 )
		method = 1
	endif
	
	// Steps involved in this function
	// collect the list, sort the list, duplicate the waves to the temp folder in sort order
	// kill each wave after it is moved
	// then, duplicate each wave in the temp folder back to the useFolder
	if( cmpstr( useFolder, "root" ) != 0 )
		SetDataFolder $useFolder
	endif
	String wave_list = WaveList( "*", ";", "")
	MakeAndOrSetDF( "root:SWIF_TempDF" )
	MakeAndOrSetDF( "root:SWIF_HousekeepDF" )
	
	Make/T/N=0/O root:SWIF_HousekeepDF:wave_list_tw
	Make/N=0/O root:SWIF_HousekeepDF:wave_suf_w
	Wave/T wave_list_tw=root:SWIF_HousekeepDF:wave_list_tw
	Wave wave_suf_w=root:SWIF_HousekeepDF:wave_suf_w
	
	String this_wave_str, this_suf_val
	Variable idex=0, count = ItemsInLIst( wave_list )
	do
		this_wave_str = StringFromList( idex, wave_list )
		AppendString( wave_list_tw, this_wave_str )
		this_suf_val = StringFromList( ItemsInList( this_Wave_str, "_" ) - 1, this_wave_str, "_" )
		AppendVal( wave_suf_w, str2num( this_suf_val ) )
		
		idex += 1
	while( idex < count )
	if( method == 1 )
		// simple alphabetic sort
		Sort wave_list_tw, wave_list_tw, wave_suf_w
	endif
	if( method == 2 )
		// suffix sort
		Sort { wave_suf_w, wave_list_tw }, wave_suf_w, wave_list_tw
	endif
	
	idex =0
	
	do
		Wave this_wave = $(useFolder+":"+wave_list_tw[idex])
		Duplicate/O this_wave, $("root:SWIF_TempDF:"+wave_list_tw[idex])
		KillWaves/Z this_wave
		idex += 1
	while( idex < count )
	
	MakeAndOrSetDF( "root:SWIF_TempDF" )
	idex = 0
	wave_list = WaveLIst( "*", ";", "" )
	count = ItemsInList( wave_list )
	do
		this_wave_str = StringFromLIst( idex, wave_list )
		Wave this_wave = $this_wave_str
		Duplicate/O this_wave, $(useFolder+":"+this_wave_str )
		
		idex += 1
	while( idex < count )
	
	KillDataFolder root:SWIF_TempDF
	KillDataFolder root:SWIF_HousekeepDF
End	

Function/T Fraction2MixingRatio( f )
	Variable f
	
	Variable pow
	Variable div
	String ret_str, text
	
	if( f > 0 )
		pow = log( f )
		
		if( pow >= 0 )
			// then this fraction is greater than one
				sprintf ret_str, "%15u", f
		else
			// then this is a genuine fraction
			pow = floor( pow )
			switch (pow)
				case -1:
				case -2:
				case -3:
					div = 100; sprintf text, "%"
					break;
				case -4:
				case -5:
				case -6:
					div = 1e6; sprintf text, "ppm"
					break;
				case -7:
				case -8:
				case -9:
					div = 1e9; sprintf text, "ppb"
					break;
				default :
					div = 1e12; sprintf text, "ppt"
					break;
			endswitch
			sprintf ret_str, "%5.2f %s", div * f, text
		endif
	else
		sprintf ret_str, "%g", f	
	endif	
	return ret_str
End

Function/T Fraction2MixingRatioRound( f )
	Variable f
	
	Variable pow
	Variable div
	String ret_str, text
	
	if( f > 0 )
		pow = log( f )
		
		if( pow >= 0 )
			// then this fraction is greater than one
				sprintf ret_str, "%15u", f
		else
			// then this is a genuine fraction
			pow = floor( pow )
			switch (pow)
				case -1:
				case -2:
				case -3:
					div = 100; sprintf text, "%"
					break;
				case -4:
				case -5:
				case -6:
					div = 1e6; sprintf text, "ppm"
					break;
				case -7:
				case -8:
				case -9:
					div = 1e9; sprintf text, "ppb"
					break;
				default :
					div = 1e12; sprintf text, "ppt"
					break;
			endswitch
			sprintf ret_str, "%3u %s", div * f, text
		endif
	else
		sprintf ret_str, "%g", f	
	endif	
	return ret_str
End


Function MixingRatio2Fraction( s )
	
	String s
	Variable f 
	Variable fset = 0
	Variable pow
	Variable div
	String ret_str, text
	
	if( strsearch( s, "%", 0 ) != -1 )
		sscanf s, "%f ", f
		f /= 100;	fset = 1
	endif
	if( strsearch( s, "ppm", 0 ) != -1 )
		sscanf s, "%f  ppm", f
		f /= 1e6;	fset = 1
	endif	
	if( strsearch( s, "ppb", 0 ) != -1 )
		sscanf s, "%f  ppb", f
		f /= 1e9;	fset = 1
	endif
	if( strsearch( s, "ppt", 0 ) != -1 )
		sscanf s, "%f  ppt", f
		f /= 1e12;	fset = 1
	endif
	
	if( fset == 0  )
		sscanf s, "%f", f
	endif
	return f
End

Function TER_CalcLogF( Fc, k0, kinf, M )
	Variable Fc, k0, kinf, M
	
	Variable logF
	
	logF = log( Fc ) /  (   1 + (  log( k0 * M / kinf )     )^2    )
	return logF
	
	

End

Function TER_Calc_k_M( k0, kinf, M, Fc )
	Variable k0, kinf, M, Fc
	
	Variable kM = (10^TER_CalcLogF( Fc, k0, kinf, M )) * ( kinf * k0 / (k0*M + kinf) )
	
	return kM
End

Function TER_Calculate_kM( k_w, numden_w, k0, kinf, Fc )
	Wave k_w, numden_w
	Variable k0, kinf, Fc

	Duplicate/O k_w, logF_w
	logF_w = TER_CalcLogF( Fc, k0, kinf, numden_w )
	k_w = (10^logF_w) * kinf * k0 * numden_w / ( numden_w * k0 + kinf ) 	


End

Function TER_k0tm( k0, T, n, M )
	Variable k0, T, n, M
	
	return k0 *(T/300)^(-n) * M
End
Function TER_kinfT( kinf, T, m )
	Variable kinf, T, m
	
	return kinf * (T/300)^(-m)
End

Function TER_Kii( k0, pn, kinf, pm, numden, T )
	Variable k0, pn, kinf, pm, numden, T
	
	Variable v_kotm = TER_k0tm( k0, T, pn, numden )
	Variable v_kinf = TER_kinfT( kinf, T, pm )
	Variable v_rat = v_kotm / v_kinf
	
	Variable expf = 1 + (log(v_rat) )^2
	
	return v_kotm / ( 1 + v_rat ) * ( 0.6^(1/expf )  )
End
Function/S GetNamedWindowTitle(windowNameStr)
        String windowNameStr


        String returnStr="",recreationStr=WinRecreation(windowNameStr,0)
        Variable startPos,stopPos
        if (!((strlen(windowNameStr)>0) && (cmpstr(WinList(windowNameStr,"",""),"")==0)))
                startPos=strsearch(recreationStr,") as \"",0) // search for 'Display /W(...) as "'
                if (startPos>0)
                        stopPos=strsearch(recreationStr,"\"",startPos+6)
                        if (stopPos>0)
                                returnStr=recreationStr[startPos+6,stopPos-1]
                        endif
                else
                        returnStr=WinName(0,1+2+4+16+64)
                endif
        endif
        return returnStr
End



Function/S GetNamedWindowPath(windowNameStr)
        String windowNameStr


        String returnStr="",recreationStr=WinRecreation(windowNameStr,0)
        Variable startPos,stopPos
        if (!((strlen(windowNameStr)>0) && (cmpstr(WinList(windowNameStr,"",""),"")==0)))
                startPos=strsearch(recreationStr,"// Path:",0)
                if (startPos>0)
                        stopPos=strsearch(recreationStr,"\r",startPos+9)
                        if (stopPos>0)
                                returnStr=recreationStr[startPos+9,stopPos-1]
                        endif
                endif
        endif
        return returnStr
End



////////////////////////////////// Global Utilites Latitude/Longitude UTC and TimeZone functions ////////////////
////////////
//////
//
// LatLon2UTM
// This function converts latitude and longitude waves to UTM style coordinates
// The key function takes source_waves lat, lon and generated equal length easting, northing and zone waves
// The ZoneOverride_var is simply a variable, set to zero to allow algorithm to do calculation
// LatLon2UTM( Latitude_w, Longitude_w, UTM_ZoneOverride_var, UTMEasting_w, UTMNorthing_w, UTMZone_w )
// or for the lazy, the wrapper
// LatLon2UTM( lat_w, lon_w ) will create UTM_Zone, UTM_Northing, UTM_Easting waves in the same directory as the lat_w
// returns zero if no problems were encountered.

// LatLon2SpeedAndBearing( igr_time, lat_w, lon_w, mph_w, kmph_w, bearing_w, bearing_smooth_var )
// LatLon2SB_DefaultNames( igr_time, lat_w, lon_w )

// These two functions create 'default' gps_mph, gps_kmph, gps_bearing or named referenced by Full non default call from
// source igr_time, lat_w, lon_w => speed and bearing -- the DefaultNames has a default BearingSmoothVar
// function does NOT allow for a speed greater than k_MAX_GPS_SPEED (160.9344 km h-1 or 100 mph -- unit is kmph though!)
Function LatLon2UTM_DefaultNames( lat_w, lon_w )
	Wave lat_w
	Wave lon_w
	
	Variable result = 0;
	String saveFolder = GetDataFolder(1);
		SetDataFolder $GetWavesDataFolder( lat_w, 1 ); // This will set the data folder to wherever lat_w is actually kept
		Duplicate/O lat_w, UTM_Zone, UTM_Northing, UTM_Easting
		Wave/Z zone_w=UTM_Zone
		if( WaveExists( zone_w ) != 1 )
			printf "Error in call to LatLon2UTM_DefaultNames( %s, %s )", NameOfWave( lat_w ), NameOfWave( lon_w )
			printf "\rUnable to generate duplicated waves for UTM Proc\r"
			return -1;
		endif
		Wave north_w=UTM_Northing;
		Wave east_w=UTM_Easting;
		
		result = LatLon2UTM( lat_w, lon_w, 0, east_w, north_w, zone_w );
		
	SetDataFolder $saveFolder;
	return result;
End

CONSTANT  DEG2RAD = 0.01745329;
CONSTANT  RAD2DEG = 57.29577951;
Structure GPSpos

	variable Latitude
	variable Longitude

	variable UTMNorthing
	variable UTMEasting
	string UTMzone

Endstructure
 
 Function x_TestGPS2UTC()
 	
 	Struct GPSpos mygps
 	
 	Variable testLat = 33.2
 	Variable testLong = -97.77
 	Variable referenceEllipsoid = 22
 	
 	LLtoUTM( ReferenceEllipsoid,   testLat,  testLong, mygps) // this old call is retained
 	
 	Variable result_N = mygps.UTMNorthing
 	Variable result_E = mygps.UTMEasting
 	Variable result_Z = str2num(mygps.UTMZone)
 	
 	printf "N:%f\tE:%f\tZ:%f\r", result_N, result_E, result_Z
 	Struct GPSpos challengeGPS
 	
 	challengeGPS.UTMNorthing = result_N;
 	challengeGPS.UTMEasting = result_E;
 	challengeGPS.UTMZone = num2str(result_Z);
	UTMtoLL(ReferenceEllipsoid, challengegps )
	
	printf "%f and %f\r", testLat, challengegps.Latitude
	printf "%f and %f\r", testLong, challengegps.Longitude
	
 End
 Function UTMWavesToLatLonWaves( UTM_N, UTM_E, UTM_Z, Lat, Lon )
 	Wave  UTM_N, UTM_E, UTM_Z, Lat, Lon 
 	
 	Variable idex, count = numpnts( utm_n ), ReferenceEllipsoid = 22 // WGS84
 	Redimension/N=(count) lat, lon
 	
 	STRUCT GPSpos gps
 	
 	for( idex = 0; idex < count; idex += 1 )
 		gps.UTMNorthing = UTM_N[idex]
 		gps.UTMEasting = UTM_E[idex]
 		gps.UTMZone = num2str(UTM_Z[idex])
		UTMtoLL(ReferenceEllipsoid, gps )
		Lat[idex] = gps.Latitude
		Lon[idex] = gps.Longitude
 	endfor
 End
 Function UTMtoLL(ReferenceEllipsoid, gps )
	variable ReferenceEllipsoid
	STRUCT GPSpos &gps


	make/o/d/n=(23) EquatorialRadius, SquareOfEccentricity
	 make/o/n=23/T EllipsoidName
	 EquatorialRadius={6377563, 	6378160, 6377397, 6377484, 6378206, 6378249, 6377276, 6378166, 6378150, 6378160, 6378137, 6378200, 6378270, 6378388, 6378245, 6377340, 6377304, 6378155, 6378160, 6378165, 6378145, 6378135, 6378137}
	SquareOfEccentricity={.00667054,.006694542,.006674372,.006674372,.006768658,.006803511,.006637847,.006693422,.006693422,.006694605,.00669438,.006693422,.00672267,.00672267,.006693422,.00667054,.006637847,.006693422,.006694542,.006693422,.006694542,.006694318,.00669438}
	EllipsoidName={"Airy","Australian National","Bessel 1841","Bessel 1841 (Nambia) ","Clarke 1866","Clarke 1880","Everest","Fischer 1960 (Mercury) ","Fischer 1968","GRS 1967", "GRS 1980", "Helmert 1906","Hough",  "International", "Krassovsky", "Modified Airy", "Modified Everest",	 "Modified Fischer 1960", "South American 1969","WGS 60","WGS 66","WGS-72", "WGS-84"}
	
	variable k0 = 0.9996;
	variable a = EquatorialRadius[ReferenceEllipsoid];
	variable eccSquared = SquareOfEccentricity[ReferenceEllipsoid];
	variable eccPrimeSquared;
	variable e1 = (1-sqrt(1-eccSquared))/(1+sqrt(1-eccSquared));
	variable N1, T1, C1, R1, D, M;
	variable LongOrigin;
	variable mu, phi1, phi1Rad;
	variable x, y, Lat, Long;
	variable ZoneNumber;
	string ZoneLetter;
	variable NorthernHemisphere; //1 for northern hemispher, 0 for southern

	x = gps.UTMEasting - 500000.0; //remove 500,000 meter offset for longitude
	y = gps.UTMNorthing;

//	ZoneNumber = strtoul(UTMZone, &ZoneLetter, 10);
//	if((*ZoneLetter - 'N') >= 0)
//		NorthernHemisphere = 1;//point is in northern hemisphere
//	else
//	{
//		NorthernHemisphere = 0;//point is in southern hemisphere
//		y -= 10000000.0;//remove 10,000,000 meter offset used for southern hemisphere
//	}
	NorthernHemisphere = 1;
	zoneNumber = str2num(gps.UTMZone);
	
	LongOrigin = (zoneNumber - 1)*6 - 180 + 3;  //+3 puts origin in middle of zone

	eccPrimeSquared = (eccSquared)/(1-eccSquared);

	M = y / k0;
	mu = M/(a*(1-eccSquared/4-3*eccSquared*eccSquared/64-5*eccSquared*eccSquared*eccSquared/256));

	phi1Rad = mu	+ (3*e1/2-27*e1*e1*e1/32)*sin(2*mu) + (21*e1*e1/16-55*e1*e1*e1*e1/32)*sin(4*mu) + (151*e1*e1*e1/96)*sin(6*mu);
	phi1 = phi1Rad*rad2deg;

	N1 = a/sqrt(1-eccSquared*sin(phi1Rad)*sin(phi1Rad));
	T1 = tan(phi1Rad)*tan(phi1Rad);
	C1 = eccPrimeSquared*cos(phi1Rad)*cos(phi1Rad);
	R1 = a*(1-eccSquared)/ ( (1-eccSquared*sin(phi1Rad)*sin(phi1Rad))^ (1.5));
	D = x/(N1*k0);

	Lat = phi1Rad - (N1*tan(phi1Rad)/R1)*(D*D/2-(5+3*T1+10*C1-4*C1*C1-9*eccPrimeSquared)*D*D*D*D/24	+(61+90*T1+298*C1+45*T1*T1-252*eccPrimeSquared-3*C1*C1)*D*D*D*D*D*D/720);
	Lat = Lat * rad2deg;

	Long = (D-(1+2*T1+C1)*D*D*D/6+(5-2*C1+28*T1-3*C1*C1+8*eccPrimeSquared+24*T1*T1) * D*D*D*D*D/120)/cos(phi1Rad);
	Long = LongOrigin + Long * rad2deg;

	gps.Latitude = Lat;
	gps.Longitude = Long;
	
End

Function LLtoUTM( ReferenceEllipsoid,   Lat,  Long, gps)
//converts lat/long to UTM coords.  Equations from USGS Bulletin 1532 
//East Longitudes are positive, West longitudes are negative. 
//North latitudes are positive, South latitudes are negative
//Lat and Long are in decimal degrees
	//Written by Chuck Gantz- chuck.gantz@globalstar.com
	variable ReferenceEllipsoid, Lat, Long
	struct GPSpos &gps
 
	variable UTMEasting,  UTMNorthing
	string UTMZone
 
	make/o/d/n=(23) EquatorialRadius, SquareOfEccentricity
	 make/o/n=23/T EllipsoidName
	 EquatorialRadius={6377563, 	6378160, 6377397, 6377484, 6378206, 6378249, 6377276, 6378166, 6378150, 6378160, 6378137, 6378200, 6378270, 6378388, 6378245, 6377340, 6377304, 6378155, 6378160, 6378165, 6378145, 6378135, 6378137}
	SquareOfEccentricity={.00667054,.006694542,.006674372,.006674372,.006768658,.006803511,.006637847,.006693422,.006693422,.006694605,.00669438,.006693422,.00672267,.00672267,.006693422,.00667054,.006637847,.006693422,.006694542,.006693422,.006694542,.006694318,.00669438}
	EllipsoidName={"Airy","Australian National","Bessel 1841","Bessel 1841 (Nambia) ","Clarke 1866","Clarke 1880","Everest","Fischer 1960 (Mercury) ","Fischer 1968","GRS 1967", "GRS 1980", "Helmert 1906","Hough",  "International", "Krassovsky", "Modified Airy", "Modified Everest",	 "Modified Fischer 1960", "South American 1969","WGS 60","WGS 66","WGS-72", "WGS-84"}
 
 
	variable a = EquatorialRadius[ReferenceEllipsoid]
	variable eccSquared = SquareOfEccentricity[ReferenceEllipsoid];
	variable k0 = 0.9996;
 
	variable LongOrigin;
	variable eccPrimeSquared;
	variable N, T, C, AA, M;
 
//Make sure the longitude is between -180.00 .. 179.9
	variable LongTemp = (Long+180)-floor((Long+180)/360)*360-180; // -180.00 .. 179.9;
 
	variable LatRad = Lat*DEG2RAD;
	variable LongRad = LongTemp*DEG2RAD;
	variable LongOriginRad;
	variable    ZoneNumber;
 
	ZoneNumber = floor((LongTemp + 180)/6) + 1;
 
	if( Lat >= 56.0 && Lat < 64.0 && LongTemp >= 3.0 && LongTemp < 12.0 )
		ZoneNumber = 32;
	endif
  // Special zones for Svalbard
	if( Lat >= 72.0 && Lat < 84.0 ) 
	  if  ( LongTemp >= 0.0  && LongTemp <  9.0 ) 
	  	ZoneNumber = 31;
	  elseif( LongTemp >= 9.0  && LongTemp < 21.0 )
	  	ZoneNumber = 33;
	  elseif(LongTemp >= 21.0 && LongTemp < 33.0 )
	  	ZoneNumber = 35;
	  elseif(LongTemp >= 33.0 && LongTemp < 42.0 ) 
	  	ZoneNumber = 37;
	  endif
	 endif
	LongOrigin = (ZoneNumber - 1)*6 - 180 + 3;  //+3 puts origin in middle of zone
	LongOriginRad = LongOrigin * DEG2RAD;
 
	//compute the UTM Zone from the latitude and longitude
 
	eccPrimeSquared = (eccSquared)/(1-eccSquared);
 
	N = a/sqrt(1-eccSquared*sin(LatRad)*sin(LatRad));
	T = tan(LatRad)*tan(LatRad);
	C = eccPrimeSquared*cos(LatRad)*cos(LatRad);
	AA = cos(LatRad)*(LongRad-LongOriginRad);
 
	M = (1	- eccSquared/4		- 3*eccSquared*eccSquared/64	- 5*eccSquared*eccSquared*eccSquared/256)*LatRad
	M -=  (3*eccSquared/8	+ 3*eccSquared*eccSquared/32	+ 45*eccSquared*eccSquared*eccSquared/1024)*sin(2*LatRad)
	M += (15*eccSquared*eccSquared/256 + 45*eccSquared*eccSquared*eccSquared/1024)*sin(4*LatRad)
	M -=  (35*eccSquared*eccSquared*eccSquared/3072)*sin(6*LatRad)
	M *= a
 
	UTMEasting = (k0*N*(AA+(1-T+C)*AA*AA*AA/6+ (5-18*T+T*T+72*C-58*eccPrimeSquared)*AA*AA*AA*AA*AA/120)+ 500000.0);
 
	UTMNorthing = (k0*(M+N*tan(LatRad)*(AA*AA/2+(5-T+9*C+4*C*C)*AA*AA*AA*AA/24+ (61-58*T+T*T+600*C-330*eccPrimeSquared)*AA*AA*AA*AA*AA*AA/720)));
	if(Lat < 0)
		UTMNorthing += 10000000.0; //10000000 meter offset for southern hemisphere
	endif
 
	gps.UTMEasting = UTMEasting
	gps.UTMNorthing = UTMNorthing
	gps.UTMZone = num2str(ZoneNumber)+ UTMLetterDesignator(Lat)
	//print gps
End
 
Function/S UTMLetterDesignator( Lat)
variable Lat
//This routine determines the correct UTM letter designator for the given latitude
//returns "Z" if latitude is outside the UTM limits of 84N to 80S
	//Written by Chuck Gantz- chuck.gantz@globalstar.com
	string LetterDesignator;
 
	if((84 >= Lat) && (Lat >= 72)) 
		LetterDesignator = "X";
	elseif((72 > Lat) && (Lat >= 64))
		 LetterDesignator = "W";
	elseif((64 > Lat) && (Lat >= 56)) 
		LetterDesignator = "V";
	elseif((56 > Lat) && (Lat >= 48)) 
		LetterDesignator = "U";
	elseif((48 > Lat) && (Lat >= 40))
	 LetterDesignator = "T";
	elseif((40 > Lat) && (Lat >= 32))
	 LetterDesignator = "S";
	elseif((32 > Lat) && (Lat >= 24))
	 LetterDesignator = "R";
	elseif((24 > Lat) && (Lat >= 16))
	 LetterDesignator = "Q";
	elseif((16 > Lat) && (Lat >= 8)) 
	LetterDesignator = "P";
	elseif(( 8 > Lat) && (Lat >= 0)) 
	LetterDesignator = "N";
	elseif(( 0 > Lat) && (Lat >= -8)) 
	LetterDesignator = "M";
	elseif((-8> Lat) && (Lat >= -16)) 
	LetterDesignator = "L";
	elseif((-16 > Lat) && (Lat >= -24))
	 LetterDesignator = "K";
	elseif((-24 > Lat) && (Lat >= -32))
	 LetterDesignator = "J";
	elseif((-32 > Lat) && (Lat >= -40)) 
	LetterDesignator = "H";
	elseif((-40 > Lat) && (Lat >= -48)) 
	LetterDesignator = "G";
	elseif((-48 > Lat) && (Lat >= -56))
	 LetterDesignator = "F";
	elseif((-56 > Lat) && (Lat >= -64)) 
	LetterDesignator = "E";
	elseif((-64 > Lat) && (Lat >= -72))
	 LetterDesignator = "D";
	elseif((-72 > Lat) && (Lat >= -80)) 
	LetterDesignator = "C";
	else
		 LetterDesignator = "Z"; //This is here as an error flag to show that the Latitude is outside the UTM limits
	endif
	return LetterDesignator;
End

Function LatLon2UTM( lat_w, lon_w, UTMOver_var, easting_w, northing_w, zone_w )
	Wave lat_w
	Wave lon_w
	Variable UTMOver_var
	Wave easting_w
	Wave northing_w
	Wave zone_w
	
	struct GPSpos gps
	Variable idex, count = numpnts( lat_w )
	for( idex = 0; idex < count; idex += 1 )
		LLtoUTM( 22,   lat_w[idex],  lon_w[idex], gps)	// the 22 here is "WGS-84
		easting_w[idex] = gps.UTMEasting
		northing_w[idex] = gps.UTMNorthing
		if( UTMOver_var )
			zone_w[idex] = UTMOver_var
		else
//			zone_w[idex] = Floor( (180 + lon_w[idex])/6 ) + 1
			// the line above is a bug, new line below { 08/2016 - sc }
			zone_w[idex] = round( (180 + lon_w[idex])/6 ) + 1
		endif
		
	endfor
	return 0;
	
	/////////////// code below is obsoleted	
	Variable result = 0;
	
	Variable k_k0 = 0.9996
	Variable k_a = 6378206.4
	Variable k_e2 = 0.00676866
	Variable k_ep2 = 0.0068148
	Variable k_false_e = 500000.0
	Variable k_Pi = 3.141592654
	Variable k_dtr = k_Pi/180
	
	if( UTMOver_var )
		zone_w = UTMOver_var
	else
		zone_w = Floor( (180 + lon_w)/6 ) + 1
	endif
	
	 idex = 0; count = numpnts( lat_w );
	Variable this_lat, this_lon, this_zone, this_east, this_north
	
	Variable dl, p, sinp, N, tanp, T, cosp, C, A1, M, A2, A3, A4, A5, A6, T2, false_n
	
	if( count > 0 )
	do
		this_lat = lat_w[idex]
		this_lon = lon_w[idex]
		this_zone = zone_w[idex]
		
		dl = UTMUtility_RangeReset( k_dtr * ( this_lon - ( 6 * this_zone - 183 ) ) );
		
		p = k_dtr * this_lat
		sinp = Sin( p )
		N = k_a / ( Sqrt( 1.0 - k_e2 * sinp * sinp ) )
		tanp = Tan( p )
		T = tanp^2;
		cosp = Cos( p )
		C = k_ep2 * cosp^2
		A1 = dl * cosp
		M = 111132.0894 * this_lat - 16216.94 * sin( 2 * p ) + 17.21 * sin( 4 * p ) - 0.02 * sin( 6 * p )
		
		A2 = A1^2
		A3 = A2 * A1
		A4 = A2^2
		A5 = A4 * A1
		A6 = A4 * A2
		T2 = T^2
		 
		 this_east = 0.001 * (k_k0 * N * ( A1 + ( 1 - T + C) * A3/6 + ( 5 - 18*T + T2 + 72 * C - 58 * k_ep2) * A5/120) + k_false_e)
		
		this_north = ( M + N * tanp * (A2/2 + (5 - T + 9 * C + 4 * C^2) * A4/24 + (61 - 58 * T + T2 + 600 * C - 330 * k_ep2) * A6/720))
		
		false_n = 0
		if( this_lat < 0 )
			false_n = 10000
		endif
		this_north = 0.001 * k_k0 * this_north + false_n
		
		easting_w[idex] = this_east;
		northing_w[idex] = this_north;
		
		idex += 1
	while( idex < count )
	endif
	
		
	return result;
	
End

Function UTMUtility_RangeReset( dl_val )
	Variable dl_val
	
	Variable ret_val = dl_val;
	
	if( dl_val < - Pi )
			ret_val += 2 * Pi
	else
		if( dl_val > Pi )
			ret_val -= 2 * Pi
		endif
	endif
	
	return ret_val;
End

// DataLogger Conventions
// Aerodyne Believes that the GPS data handled in the NMEA 0183 format will be in the form
// Latitude -> 	+ddmm.mmmm or ddmm.mmm or ddmm.mm 
// Longitude ->	+dddmm.mmmm or +ddmm.mm or there abouts
// Basically what we are talking about is SIGNED degrees, 2 decimal digits of minute data (0-59) and after the decimal
// are fractional minutes (NOT SECONDS)
// The sign Convention +Latitude => North Hemisphere & NEGATIVE - Latitude => degrees South
// + Longitude => Degrees East &  (NEGATIVE) - Longitude => degrees West

// Function DataLoggerGPS2DecimalDegree take the format of numeric data which 
// DataLogger writes for latitude and longitude and converts to decimal degrees
// This utility is hard wired for the following behavior;
// NameOfLat_w spawns new wave called "dec_<NameOfLat_w>"  same for lon_w
// This function leaves BOTH in place, returns 0 for ok, nonzero indicates an error
Function DataLoggerGPS2DecimalDegree( dl_lat_w, dl_lon_w )
	Wave dl_lat_w
	Wave dl_lon_w
	
	Variable result = 0;
	String prefix = "dec_", dataFolderName
	String origLatName = NameOfWave( dl_lat_w );	String origLonName = NameOfWave( dl_lon_w );
	String newLat, newLon;
	
	sprintf newLat, "%s%s", prefix, origLatName;	sprintf newLon, "%s%s", prefix, origLonName;
	String saveFolder = GetDataFolder(1);
		if( cmpstr( saveFolder, "root:" ) != 0 )
			dataFolderName = GetWavesDataFolder( dl_lat_w, 1 );
			SetDataFolder $dataFolderName
		endif
		Duplicate/O dl_lat_w, $newLat;		Duplicate/O dl_lon_w, $newLon
		Wave/Z dec_lat_w=$newLat;		Wave/Z dec_lon_w=$newLon
		
		if( ( WaveExists( dec_lat_w ) + WaveExists( dec_lon_w ) ) != 2 )
			print "Fatal Error in DataLoggerGPS2DecimalDegree: Unable to ref duplicated dec_ waves"
			return -1;
		endif
		
		Duplicate/O dec_lat_w, dec_lat_wAid, sign_lat
		Duplicate/O dec_lon_w, dec_lon_wAid, sign_lon
		
		sign_lat = sign( dl_lat_w );
		sign_lon = sign( dl_lon_w );
		dec_lat_wAid = floor( abs(dl_lat_w)/100 );
		dec_lat_w = sign_lat * (( abs(dl_lat_w) - 100 * dec_lat_wAid )/60 + dec_lat_wAid)

		dec_lon_wAid = floor( abs(dl_lon_w)/100 );
		dec_lon_w = sign_lon * (( abs(dl_lon_w) - 100 * dec_lon_wAid )/60 + dec_lon_wAid)
		
		KillWaves/Z sign_lat, sign_lon, dec_lat_wAid, dec_lon_wAid
	SetDataFolder $saveFolder
	
	return result;
End


// LatLon2SpeedAndBearing( igr_time, lat_w, lon_w, mph_w, kmph_w, bearing_w, bearing_smooth_var )
// LatLon2SB_DefaultNames( igr_time, lat_w, lon_w )
Function LatLon2SB_DefaultNames( igr_time, lat_w, lon_w )
	Wave igr_time
	Wave lat_w
	Wave lon_w
	
	Variable default_speedBearingSmooth = 5;
	
	Variable result = 0;
	String saveFolder = GetDataFolder(1);
		SetDataFolder $GetWavesDataFolder( lat_w, 1 ); // This will set the data folder to wherever lat_w is actually kept
		Duplicate/O lat_w, gps_mph, gps_kmph, gps_bearing
		Wave/Z gps_mph=gps_mph
		if( WaveExists( gps_mph ) != 1 )
			printf "Error in call to LatLon2SB_DefaultNames( %s, %s )", NameOfWave( lat_w ), NameOfWave( lon_w )
			printf "\rUnable to generate duplicated waves for Speed & Bearing Proc\r"
			return -1;
		endif
		Wave gps_mph=gps_mph;
		Wave gps_kmph=gps_kmph;
		Wave gps_bearing=gps_bearing;
		
		result = LatLon2SpeedAndBearing( igr_time, lat_w, lon_w, gps_mph, gps_kmph, gps_bearing, default_speedBearingSmooth )
		
	SetDataFolder $saveFolder;
	return result;
End
Function LatLon2SpeedAndBearing( igr_time, lat_w, lon_w, mph_w, kmph_w, bearing_w, smooth_bearing )
	Wave igr_time
	Wave lat_w
	Wave lon_w
	Wave mph_w
	Wave kmph_w
	Wave bearing_w
	Variable smooth_bearing
	
	Variable result = 0;
	Variable average_latitude;
	
	Variable k_MAX_GPS_SPEED = 160.9344
	Variable k_k0 = 0.9996
	Variable k_a = 6378206.4
	Variable k_e2 = 0.00676866
	Variable k_ep2 = 0.0068148
	Variable k_false_e = 500000.0
	Variable k_Pi = 3.141592654
	Variable k_dtr = k_Pi/180
	
	Variable k_EarthRadius
	String killPrefix = "LLSBTemp_";
	Duplicate/O lat_w, LLSBTemp_kmN, LLSBTemp_kmW, LLSBTemp_Bear, LLSBTemp_DBear
	
	WaveStats/Q lat_w
	average_latitude = v_avg
	if( (average_latitude > 90) %| (average_latitude < -90) )	
		print "Setting mean latitude to that of Aerodyne"
		average_latitude = 42.0
	endif
	
	LLSBTemp_kmN = Pi/180 * lat_w * EarthRadiusAtLatitude( average_latitude )
	LLSBTemp_kmW = Pi/180 * cos( Pi/180 * lat_w ) * lon_w * EarthRadiusAtLatitude( average_latitude )
	
	Variable start_time = igr_time[0]
	Variable end_time = igr_time[numpnts(igr_time)]
	Make/D/N=( end_time - start_time + 1 )/O LLSBTemp_Scale
	SetScale/P x, start_time, 1, "dat", LLSBTemp_Scale
	Duplicate/O LLSBTemp_Scale, LLSBTemp_kmN_Scale, LLSBTemp_kmW_Scale, LLSBTemp_Velocity
	
	LLSBTemp_kmN_Scale = interp( x, igr_time, LLSBTemp_kmN )
	LLSBTemp_kmW_Scale = interp( x, igr_time, LLSBTemp_kmW )
	
	Duplicate/O LLSBTemp_kmN_Scale, LLSBTemp_DkmN_Scale
	Duplicate/O LLSBTemp_kmW_Scale, LLSBTemp_DkmW_Scale
	
	Differentiate LLSBTemp_DkmN_Scale;		Differentiate LLSBTemp_DkmW_Scale;
	LLSBTemp_Velocity = 3600 * Sqrt( LLSBTemp_DkmN_Scale^2 + LLSBTemp_DkmW_Scale^2 )
	
	UtilityLatLon2Bearing( lat_w, lon_w, bearing_w, smooth_bearing )
	
	WaveStats/Q LLSBTemp_Velocity
	if( v_max > k_MAX_GPS_SPEED )
		UtilityLatLonVelocityCap( LLSBTemp_Velocity, k_MAX_GPS_SPEED )
	endif
	Duplicate/O LLSBTemp_Velocity, kmph_w, mph_w
	mph_w *= 0.6213712 		// convert kmph to mph

	String search = ( killPrefix + "*" )
	String list = WaveList( search, ";", "" )
	Variable idex = 0, count = ItemsInLIst( list )
	if( count > 0 )
		do
			KillWaves/Z $StringFromLIst( idex, list )
			idex += 1
		while( idex < count )
	endif
	
	return result;
	
End
Function UtilityLatLonVelocityCap( vel_w, max_v )
	Wave vel_w
	Variable max_v
	
	Variable idex = 0, count = numpnts( vel_w )
	if(count > 0 )
		do
			if( vel_w[idex] > max_v )
				vel_w[idex] = max_v
			endif
			idex += 1
		while( idex < count )
	endif
End
Function UtilityLatLon2Bearing( lat, lon, bearing, smooth_bearing )
	Wave lat, lon, bearing
	Variable smooth_bearing
	
	Variable idex = smooth_bearing, count = numpnts( lat )
	Variable lat_2, lat_1
	Variable lon_2, lon_1
	Variable this_bearing
	if( count > 1)
		duplicate/o lat, bearing
		bearing[0] = 0
		do
			WaveStats/Q/R=[idex, idex+smooth_bearing] lat
			lat_2 = v_avg * Pi/180
			WaveStats/Q/R=[idex - smooth_bearing, idex] lat
			lat_1 = v_avg * Pi/180
			WaveStats/Q/R=[idex, idex + smooth_bearing] lon
			lon_2 = v_avg * Pi/180
			WaveStats/Q/R=[idex - smooth_bearing, idex ] lon
			lon_1 = v_avg * Pi/180
			
			this_bearing = atan2( sin(lon_1 - lon_2) * cos( lat_2 ), cos(lat_1)*sin(lat_2) - sin(lat_1)*cos(lat_2) * cos(lon_1 - lon_2))		
			bearing[ idex ] = this_bearing * 180/Pi
			idex += 1
		while(idex < count )
		Smooth/B/E=3 smooth_bearing, bearing
	endif
End 
Function EarthRadiusAtLatitude( lat )
	Variable lat
	
	// semimajor axis
	Variable a = 6378137 / 1000
	
	// semiminor axis
	Variable b = 6356752.314245 / 1000
	
	Variable radius
	Variable e
	Variable tanlat2
	
//	e = ( a^2 - b^2 ) / a^2
	
//	radius = a * ( 1 - e^2 ) / ( ( 1 - e^2 * (sin(Pi/180 * lat))^2 )^(3/2) )

//	tanlat2 = Tan( Pi/180 * lat )^2
//	radius = b * ( 1 + tanlat2)^0.5 / ( (b^2/a^2) + tanlat2) ^0.5
	
	radius = a - (a-b) * abs(sin( Pi / 180 * lat ))
			
	return radius
End


// IgrUTC2Drift( igr_time, utc_w, delta_w, drift_w )
// IgrUTC2Drift_DefaultNames( igr_time, utc_w)
Function IgrUTC2Drift_DefaultNames( igr_time, utc_w, lon_w )
	Wave igr_time
	Wave utc_w
	Wave lon_w
	
	Variable result = 0;
	String saveFolder = GetDataFolder(1);
		SetDataFolder $GetWavesDataFolder( lon_w, 1 ); // This will set the data folder to wherever lat_w is actually kept
		Duplicate/O igr_time, drift_w, absOff_w
		Wave/Z drift_w=drift_w
		if( WaveExists( drift_w ) != 1 )
			printf "Error in call to IrgUTC2Drift_DefaultNames( %s, %s )", NameOfWave( itr_time ), NameOfWave( utc_w )
			printf "\rUnable to generate duplicated waves for Drift & Delta Proc\r"
			return -1;
		endif

		Wave absOff_w=absOff_w
		Wave drift_w=drift_w;
		
		result = IgrUTC2Drift( igr_time, utc_w, lon_w, absOff_w, drift_w )
		SetScale/P y, 0, 0, "sec", absOff_w, drift_w
	SetDataFolder $saveFolder;
	return result;
End
Function IgrUTC2Drift( igr_time, utc_w, lon_w, absOff_w, drift_w )
	Wave igr_time
	Wave utc_w
	Wave lon_w
	Wave absOff_w
	Wave drift_w
	
	Variable result = 0;
	
	// This function will endeavor to esitmate the absolute Offset and the drift present between the DataLogger Clock
	// and the GPS
	
	String killPrefix = "IUDTemp_";
	Duplicate/O igr_time, IUDTemp_UTCSam, IUDTemp_IgrSAM
	

	Duplicate /O utc_w, IUDTemp_hrs_utc, IUDTemp_mins_utc
	IUDTemp_hrs_utc = Floor( utc_w/10000)
	IUDTemp_mins_utc = Floor((utc_w - IUDTemp_hrs_utc*10000)/100)
	IUDTemp_UTCSam = utc_w - IUDTemp_hrs_utc*10000 - IUDTemp_mins_utc*100

	IUDTemp_UTCSam += 60*IUDTemp_mins_utc
	IUDTemp_UTCSam += 3600 * (IUDTemp_hrs_utc - GuessUTCOffset( igr_time, lon_w)  )

	IUDTemp_IgrSAM = Secs2Sam( igr_time );
	
	absOff_w = IUDTemp_IgrSAM - IUDTemp_UTCSam;
	UtilityIgrUTC2Drift_FilterABS( absOff_w )
	Duplicate/O absOff_w, drift_w
	Differentiate drift_w
	
	String search = ( killPrefix + "*" )
	String list = WaveList( search, ";", "" )
	Variable idex = 0, count = ItemsInLIst( list )
	if( count > 0 )
		do
			KillWaves/Z $StringFromLIst( idex, list )
			idex += 1
		while( idex < count )
	endif
	
	return result;
	
End
Function UtilityIgrUTC2Drift_FilterABS( w )
	Wave w
	// so this is really meant to distill each offset value down to a meaningful 'minute' offset
	
	Variable daybreak = 3600 * 24;
	Variable hour = 3600;
	
	w = mod( w, daybreak )
	w = mod( w, hour )
	
End
Function GuessUTCOffset( igr_time_val, ari_lon )
	Variable igr_time_val
	Variable ari_lon
	
	Variable offset = 0;
	if( (ari_lon < 7.5) & (ari_lon > -7.5 ) )
		offset = 0
	else
		offset = Round( ari_lon / 15 )
	endif
	
	// This has a nice basic offset Now we tackle DaylightSavings
	offset += GuessDayLightSavings( igr_time_val );

	return offset
End

Function GuessDaylightSavings( igr_time )
	Variable igr_time
	
	/////////// This function assumes you are using the same regional settings in your control panel as I am~!
	String date_str=secs2date(igr_time,0)
	String year_str = stringfromlist( 2, date_str, "/" )
	String month_str = stringfromlist( 0, date_str, "/" )
	String day_str = stringfromlist( 1, date_str, "/" )
	
	Variable jday = Secs2JulianDay( igr_time )
	
	string  DSTstartList = "", DSTendList = ""
	DSTendList = DSTendList+ "10/27/2002 1:00:00;"
	DSTendList= DSTendList+ "10/26/2003 1:00:00;"
	DSTendList=DSTendList+ "10/31/2004 1:00:00;"
	DSTendList= DSTendList+ "10/30/2005 1:00:00;"
	DSTendList= DSTendList+ "10/29/2006 1:00:00;"
	DSTendList= DSTendList+ "11/4/2007 1:00:00;"
	DSTendList= DSTendList+ "11/2/2008 1:00:00;"
	DSTendList= DSTendList+ "11/1/2009 1:00:00;"
	DSTendList= DSTendList+ "11/7/2010 1:00:00;"
	DSTendList= DSTendList+ "11/6/2011 1:00:00;"
	DSTendList= DSTendList+ "11/4/2012 1:00:00;"
	DSTendList= DSTendList+ "11/3/2013 1:00:00;"
	DSTendList= DSTendList+ "11/2/2014 1:00:00;"
	DSTendList= DSTendList+ "11/1/2015 1:00:00;"
	DSTendList= DSTendList+ "11/6/2016 1:00:00;"
	DSTendList= DSTendList+ "11/5/2017 1:00:00;"
	DSTendList= DSTendList+ "11/4/2018 1:00:00;"
	
	DSTstartList =DSTstartList+"4/7/2002 3:00:00;"
	DSTstartList =DSTstartList+"4/6/2003 3:00:00;"
	DSTstartList =DSTstartList+"4/4/2004 3:00:00;"
	DSTstartList =DSTstartList+"4/3/2005 3:00:00;"
	DSTstartList =DSTstartList+ "4/2/2006 3:00:00;"
	DSTstartList =DSTstartList+ "3/11/2007 3:00:00;"
	DSTstartList =DSTstartList+ "3/9/2008 3:00:00;"
	DSTstartList =DSTstartList+ "3/8/2009 3:00:00;"
	DSTstartList =DSTstartList+"3/14/2010 3:00:00;"
	DSTstartList =DSTstartList+"3/13/2011 3:00:00;"
	DSTstartList =DSTstartList+"3/11/2012 3:00:00;"
	DSTstartList =DSTstartList+"3/10/2013 3:00:00;"
	DSTstartList =DSTstartList+"3/9/2014 3:00:00;"
	DSTstartList =DSTstartList+"3/8/2015 3:00:00;"
	DSTstartList =DSTstartList+"3/13/2016 3:00:00;"
	DSTstartList =DSTstartList+"3/12/2017 3:00:00;"
	DSTstartList =DSTstartList+"3/11/2018 3:00:00;"
	
	
	String daylightSavingsEnd="_null_"
	String daylightSavingsBegin="_null_"
	variable i
	string thisDSTstart="_null_",thisDSTend="_null_"
	for(i=0;i<itemsinlist(DSTstartList);i+=1)
		thisDSTstart = stringfromlist(i,DSTstartList,";")
		thisDSTend = stringfromlist(i,DSTendList,";")
		if(stringmatch(thisDSTstart, "*"+year_Str+"*"))
			daylightSavingsBegin = thisDSTstart
			daylightSavingsEnd = thisDSTend
		endif
	endfor

	if(stringmatch(daylightSavingsBegin,"_null_")||stringmatch(daylightSavingsend,"_null_"))
		print "ERROR! Year",year_str, "is not within the known DST range. Please update function \"GuessDaylightSavings\"."	
		return nan
	endif
	
	Variable jdayEnd = Secs2JulianDay( Text2DateTime(daylightSavingsEnd) );
	Variable jdayBegin = Secs2JulianDay( Text2DateTime(daylightSavingsBegin) );
	
	if( (jday > jdayBegin) & (jday < jdayEnd) )
		return 1
	else
		return 0
	endif
	
End


Function/T GetThisComputerName()

	String info = IgorInfo(2);
	String pathName
	Variable pathPreExist = 0;
	Variable refNum, done
	String fileName
	String cmd, line
	String return_string = "noone."
	
	if( strsearch( UpperStr(info), "WINDOWS", 0 ) != -1 )
		sprintf pathName, "c:gnt_notes"
		sprintf fileName, "getip.bat"
		
		NewPath/Q/O/Z path2GTCN , pathName
		PathInfo path2GTCN
		if( v_flag )
			pathPreExist = 1
		else
			NewPath/C/Q/O path2GTCN , pathName
		endif
		
		Open/P=path2GTCN refNum as fileName
		if( refNum != 0 )
			fprintf refNum, "ipconfig /all >c:\\gnt_notes\\ipout.txt\r\n"
			fprintf refNum, "type c:\\gnt_notes\\ipout.txt\r\n"
			
			Close refNum
			Close/A
			ExecuteScriptText  "\"c:\\gnt_notes\\getip.bat\""
			Variable lags = 0, maxlags = 5, keepWaiting = 1;
			do
//				Make/O/N=12800 this_lame_wave;	
//				this_lame_wave = Sin( p/360 );	
//				FFT this_lame_wave;
//				KillWaves/Z this_lame_wave
				sleep 00:00:01
				lags += 1
				if( FileExists( "path2GTCN", "ipout.txt" ) == 0 )
					keepWaiting = 0;
				endif
				if( lags > maxlags )
					sprintf return_string, "TIMED_OUT"
				endif
			while( keepWaiting )
			
			if( fileExists( "path2GTCN", "ipout.txt" ) == 0 )
				Open/R/P=path2GTCN refNum as "ipout.txt"
				Variable colon_dex
				if( refNum == 0 )
					sprintf return_string, "Failure to find ipout.txt"
				else
					done = 0;
					do
						freadline refNum, line
						if( strlen( line ) > 0 )
							Variable dot_dex
							if( strsearch( line, "Host Name .", 0 ) != -1 )
								colon_dex = strsearch( line, ":" , 0 )
								return_string = line[colon_dex+1, strlen(line) - 2 ]
								dot_dex = strsearch(  return_string, ".", 0 )
								if( dot_dex != -1 )
									return_string = return_string[ 0, dot_dex - 1 ]
								endif
								Close refNum
								done = 1
							endif
						else
							done = 1;
						endif
					while( done != 1 )	
					Close/a
				endif // opened the ipout.txt
				FileIO( "c:gnt_notes", "ipout.txt", "dest", "destFile", 2 )
				FileIO("c:gnt_notes", "getip.bat", "dest", "destFile", 2 )
				if( pathPreExist != 1 )
					
				endif
			endif
		else
			sprintf return_string, "FailureToOpenBAT"
			Close/A
		endif // fileopen refNum
	endif // info returned WINDOWS
	
	return_string = StripCharsFromString( return_string, " ." )
	return return_string
End

Function/T StripCharsFromString( orig, charlist )
	String orig
	String charlist
	
	String return_str = "";
	Variable charlist_len = strlen( charlist )
	String this_char, this_orig
	Variable idex, jdex, orig_count = strlen( orig )
	
	Variable this_ok = 0;
	
	if( orig_count > 0 )
	do
		this_orig = orig[idex];
		jdex = 0;
		this_ok = 1;
		if( charlist_len > 0 )
			do
				this_char = charlist[jdex]
				if( cmpstr( this_orig, this_char ) == 0 )
					this_ok = 0; jdex = charlist_len;
				endif
				jdex += 1
			while( jdex < charlist_len )
			if( this_ok )
				return_str = return_str + this_orig
			endif
		endif
	
		idex += 1
	while( idex < orig_count )
	endif
	
	return return_str
End


Function ZIP_ClineZip( sourceDir, mask, destDir, destName, flags )
	String sourceDir
	String mask
	String destDir
	String destName
	String flags
	

	// This function drives wzzip cline add on to winzip.
	String writeListFile = "ZTF_IGR.txt"
		String cmd
	String fulldestName, fullListName
	Variable result = 0
	Make/T/O/N=0 ZIP_TempFileName
	Wave/T zip_temp=ZIP_TempFileName
	NewPath/O/Q path2zipTarg, sourceDir
	result = GFL_FileListAtOnce( "path2zipTarg", 0, zip_temp, mask )
	if( result != 1 )
		printf "ZIP_ClineZip encountered a filelisting error with %s, %s\r", sourceDir, mask
		return -1
	endif
	
	// now take that filelist and write
	if( fileexists( destDir, writeListFile ) != 1 )
		FileIO( destDir, writeLIstFile, destDir, writeListFile, 2 )
	endif
	result = ZIP_WriteListFileFromTextWave( destDir, writeListFile, sourceDir, zip_temp )
	KillPath/Z path2zipTarg
	KillWaves/Z zip_temp

	fullDestName = WindowsFullPath( destDir, destName )
	fullListName = WindowsFullPath( destDir, writeListFile )	
	sprintf cmd, "wzzip %s %s @%s", flags, fullDestName, fullListName
	
	Variable refNum
	String lockFile
	if( cmpstr( sourceDir[strlen(sourceDir)-1], ":" ) == 0 )
		sprintf lockFile, "%sLockDir.txt", sourcedir
	else
		sprintf lockFile, "%s:LockDir.txt", sourcedir
	endif	
	Open refNum  as lockFile
	Close refNum
	//print cmd
	ExecuteScriptText/B cmd
	//print v_flag
End

Function ZIP_WriteListFileFromTextWave( destDir, filename, sourceDir, textWave )
	String destDir
	String filename
	String sourceDir
	Wave/T textWave
	
	Variable result = 0, refNum
	String this_file, fline
	NewPath/Q/O/C ZIP_ListFilePath , destDir
	PathInfo ZIP_ListFilePath
	if( V_Flag == 0 )
		print "ZIP_WriteListFileFromTextWave couldn't make a path to", destDir
		return -1
	endif
	if( FileExists( "ZIP_ListFilePAth", filename ) == 0 )
		print "Deleting preexisting listfile"
		FileIO( S_Path, filename, S_Path, filename, 2 )
	endif
	String realSourceDir
	if( cmpstr( sourceDir[strlen(sourceDir)-1], ":" ) == 0 )
		sprintf realSourceDir, "%s", sourceDir
	else
		sprintf realSourceDir, "%s:", sourceDir
	endif
	Variable idex = 0, count = numpnts( textWave )
	if( count > 0 )
		Open/P=ZIP_ListFilePath refNum as filename
		if( refNum != 0 )
			do
				this_file = textWave[idex]
				fline = WindowsFullPath( realSourceDir, this_file)
				fprintf refNum, "%s\r\n", fline
				idex += 1
			while( idex < count )
			Close refNum
			result = 1
		else
			print "ZIP_WriteListFileFromTextWave couldn't open file for write"
			return -1
		endif
	else
		print "Zip_WriteListFileFromTextWave didn't find any points in ", nameofwave(textWave)
		return -1
	endif
	KillPath/Z ZIP_ListFilePath
	return result
	
End

Function FindStringInWave( str, tw, alpha )
	String str
	Wave/T tw
	Variable alpha
	
	// if alpha = -1 then ToLower is applied
	// alpha = 0 implies str match is case sens
	// alpha = 1 then ToUpper is applied
	
	Variable idex = 0, count = numpnts( tw )
	Variable retdex = -1
	
	
	if( count > 0 )
		switch (alpha)
			case 0:
				do
					if( cmpstr( str, tw[idex] ) == 0 )
						retdex = idex
						idex = count
					endif	
					idex += 1
				while( idex < count )
				break;
			case -1:
				do
					if( cmpstr( LowerStr(str), LowerStr(tw[idex] ) ) == 0 )
						retdex = idex
						idex = count
					endif	
					idex += 1
				while( idex < count )
				break;
			case 1:
				do
					if( cmpstr( UpperStr(str), UpperStr(tw[idex] )) == 0 )
						retdex = idex
						idex = count
					endif	
					idex += 1
				while( idex < count )
				break;
		endswitch			
		
	endif
	
	return retdex
End

Function IFJP_IgorFtpJournalProcDraw()

	String destFolder = "root:ifjp"
	String ifjp_win_name = "ifjp_StatusWindow"
	String saveFolder = GetDataFolder(1)
	
	// two checks, first for variables, second for acual window
	NVAR/Z last = $( destFolder + ":last" )
	if( !NVAR_Exists( last ) )
		MakeAndOrSetDF( destFolder )
		IFJP_VariableInit()
	endif
	NVAR freq = $(destFolder + ":freq" )
	NVAR last = $(destFolder + ":last" )
	NVAR next = $(destFolder + ":next" )
	NVAR now = $(destFolder + ":now" )
	
	SVAR last_str = $(destFolder + ":last_str" )
	SVAR next_str = $(destFolder + ":next_str" )
	SVAR now_str = $(destFolder + ":now_str" )
	
	SVAR current_file = $(destFolder + ":current_file" )
	SVAR msg = $(destFolder + ":msg" )
	
	DoWindow $ifjp_win_name
	if( !V_Flag )
		IFJP_WindowDraw(ifjp_win_name)
	endif
	

	SetDataFolder $saveFolder
End

Function IFJP_VariableInit()
	
	Variable/G freq = 30
	Variable/G last = 0
	Variable/G next = datetime + 2 * freq
	Variable/G now = datetime
	
	String/G last_str = DateTime2Text( last )
	String/G next_str = DateTime2Text( next )
	String/G now_str = DateTime2Text( now )
	
	String/G incoming_dir = "c:gnt_notes:"
	String/G processed_dir = "c:gnt_notes:jprocd:"
	
	Variable/G tick_check = 59
	
	String/G current_file = ""
	
	String/G msg = ""

End
Function IFJP_WindowDraw(this_winName)
	String this_winName
	
	Variable left = 5, right = 400, top = 5, bottom = 220
	MakeOrSetPanel( left, top, right, bottom, this_winName )
	
	Variable col1 = 5, col1wid = 1/2 * (right - left ) - 8, ctrl_height = 21
	Variable row1 = 12
	Variable space = 2
	Variable col2 = col1 + col1wid 
	Variable row2 = row1 + ctrl_height + space
	Variable row3 = row2 + ctrl_height + space
	Variable row4 = row3 + ctrl_height + space
	Variable row5 = row4 + ctrl_height + space
	Variable row6 = row5 + ctrl_height + space
	Variable row7 = row6 + ctrl_height + space
	Variable row8 = row7 + ctrl_height + space
	Variable row9 = row8 + ctrl_height + space
	
	SetVariable inc_sv, title = "inc:", win=$this_winName, pos={col1, row1 }, size={2 * col1wid, ctrl_height}
	SetVariable inc_sv, value=root:ifjp:incoming_dir
	
	SetVariable out_sv, title = "proc:", win=$this_winName, pos = {col1, row2}, size={2 * col1wid,ctrl_height}
	SetVariable out_sv, value=root:ifjp:processed_dir
	
	Button enable_disable_but , title = "toggle active/inactive", win=$this_winName, pos = {col1, row3}, size={col1wid, ctrl_height}, proc=IFJP_Toggle
	
	SetVariable last_str_sv, title = "last", pos = {col1, row5}, size={col1Wid, ctrl_height}, win=$this_winName
	SetVariable last_str_sv, value = root:ifjp:last_str, win=$this_winName
	
	SetVariable next_str_sv, title = "next", pos = {col2, row5}, size={col1Wid, ctrl_height}, win=$this_winName
	SetVariable next_str_sv, value = root:ifjp:next_str, win=$this_winName
	
	SetVariable now_str_sv, title = "now", pos = {col2, row6}, size={col1Wid, ctrl_height}, win=$this_winName
	SetVariable now_str_sv, value = root:ifjp:now_str, win=$this_winName
	
	SetVariable freq_str_sv, title = "freq", pos = {col1, row6}, size={col1Wid, ctrl_height}, win=$this_winName
	SetVariable freq_str_sv, value = root:ifjp:freq, win=$this_winName, limits={4,9999,2}
				
	SetVariable msg_str_sv, title = "msg", pos = {col1, row9}, size={col1Wid * 2, ctrl_height}, win=$this_winName
	SetVariable msg_str_sv, value = root:ifjp:msg, win=$this_winName
	
	SetVariable file_str_sv, title = "file", pos = {col1, row8}, size={col1Wid * 2, ctrl_height}, win=$this_winName
	SetVariable file_str_sv, value = root:ifjp:current_file, win=$this_winName
	
	
End
Function IFJP_Toggle(ctrl)
	String ctrl
		
		
	String destFolder = "root:ifjp"
	
	NVAR freq = $(destFolder + ":freq" )
	NVAR last = $(destFolder + ":last" )
	NVAR next = $(destFolder + ":next" )
	NVAR now = $(destFolder + ":now" )
	NVAR tick_check = $(destFolder + ":tick_check" )
	
	SVAR last_str = $(destFolder + ":last_str" )
	SVAR next_str = $(destFolder + ":next_str" )
	SVAR now_str = $(destFolder + ":now_str" )
	
	SVAR current_file = $(destFolder + ":current_file" )
	SVAR msg = $(destFolder + ":msg" )
	
	if( cmpstr( ctrl, "enable_disable_but" ) == 0 )
		BackgroundInfo
		if( V_Flag == 0 )
			msg = "Starting Background"
			SetBackground IFJP_BackgroundTask()
			CtrlBackground period=tick_check, start, noBurst=1
		else
			if( V_flag == 1 )
				msg = "Resuming Background"
				CtrlBackground period=tick_check, start, noBurst = 1
			else
				if( V_Flag == 2 )
					msg = "Halting Background"
					CtrlBackground stop
				endif
			endif
		endif
	endif
	
End

Function IFJP_BackgroundTask()

	Variable ret_val = 0
	
	String destFolder = "root:ifjp"
	
	NVAR freq = $(destFolder + ":freq" )
	NVAR last = $(destFolder + ":last" )
	NVAR next = $(destFolder + ":next" )
	NVAR now = $(destFolder + ":now" )
	NVAR tick_check = $(destFolder + ":tick_check" )
	
	SVAR last_str = $(destFolder + ":last_str" )
	SVAR next_str = $(destFolder + ":next_str" )
	SVAR now_str = $(destFolder + ":now_str" )
	
	SVAR current_file = $(destFolder + ":current_file" )
	SVAR msg = $(destFolder + ":msg" )
	
	now = datetime
	last_str = DateTime2Text( last )
	next_str = DateTime2Text ( next )
	now_str = DateTime2Text( now )
	
	if( now >= next )
		sprintf msg, "Executing File Check"
		IFJP_LookForJournalFiles()
		last = datetime
		next = last + freq
	else
		sprintf msg, "Waiting to execute check"
	endif
	now = datetime
	last_str = DateTime2Text( last )
	next_str = DateTime2Text ( next )
	now_str = DateTime2Text( now )
	
	String ifjp_win_name = "ifjp_StatusWindow"
	String this_winName = ifjp_win_name
	
	if( now - last < 5 )
		SetVariable last_str_sv, win=$this_winName, labelBack=(21456,39168,0)
	else
		SetVariable last_str_sv, win=$this_winName, labelBack=0
	endif
	
	if( next - now < 5 )
		SetVariable next_str_sv, win=$this_winName, labelBack=(52224,0,0)
	else
		SetVariable next_str_sv, win=$this_winName, labelBack=0
	endif
	
	
	if( now == last  )
		SetVariable now_str_sv, win=$this_winName, labelBack=(0,43520,65280)
	else
		SetVariable now_str_sv, win=$this_winName, labelBack=0
	endif
	return ret_val
End
Function IFJP_LookForJournalFiles()

	String destFolder = "root:ifjp"
	
	NVAR freq = $(destFolder + ":freq" )
	NVAR last = $(destFolder + ":last" )
	NVAR next = $(destFolder + ":next" )
	NVAR now = $(destFolder + ":now" )
	NVAR tick_check = $(destFolder + ":tick_check" )
	
	SVAR last_str = $(destFolder + ":last_str" )
	SVAR next_str = $(destFolder + ":next_str" )
	SVAR now_str = $(destFolder + ":now_str" )
	
	SVAR incoming_dir = $(destFolder + ":incoming_dir" )
	SVAR processed_dir = $(destFolder + ":processed_dir" )
	SVAR current_file = $(destFolder + ":current_file" )
	SVAR msg = $(destFolder + ":msg" )
	
	String fullfile
	Variable ret_val = 0
	NewPath/O/Q Path2Incoming_IJFP, incoming_dir
	PathInfo Path2Incoming_IJFP
	if( !V_Flag )
		sprintf msg, "Cannot find directory %s", incoming_dir
		return 0
	endif
	
	NewPath/O/C/Q Path2OutProc_ifjp, processed_dir
	
	Make/N=0/T/O ijfp_files_tw
	Wave/T ijfp_files_tw = ijfp_files_tw
	 
	 GFL_FilelistAtOnce( "Path2Incoming_IJFP", 0, ijfp_files_tw, ".txt" )
	 
	 Variable idex = 0, count = numpnts( ijfp_files_tw )
	 if( count > 0 )
	 	sprintf msg , "%d unmatched files found in %s", count, incoming_dir
	 	
	 	do
	 		current_file = ijfp_files_tw[idex]
	 		if( strsearch( current_file, "igrj", 0 ) == -1 )
	 			DeletePoints idex, 1, ijfp_files_tw
	 			count = numpnts( ijfp_files_tw )
	 		else
		 		idex += 1
		 	endif
	 	while( idex < count )
	 
	 else
	 	sprintf msg ,"No files found in %s", incoming_dir 
	 endif
	 
	 idex = 0; count = numpnts( ijfp_files_tw )
	 if( count > 0 )
	 	do
	 		current_file = ijfp_files_tw[idex]
	 		sprintf fullfile, "%s%s", incoming_dir, current_file
	 		ret_val = IJFP_RunJournalFile( fullfile )
	 		if( FileExists( "Path2OutProc_ifjp", current_file ) == 0 )
	 			if( FileExists( "Path2OutProc_ifjp", (current_file + ".tag") ) == 0 )
	 				FileIO( processed_dir, (current_file + ".tag" ), processed_dir, current_file + ".tag", 2 )
	 			endif
	 			ret_val = FileIO( incoming_dir, current_file, processed_dir, current_file + ".tag", 1 )
	 		else
				ret_val = FileIO( incoming_dir, current_file, processed_dir, current_file, 1 ) 		
	 		endif
			idex += 1
	 	while( idex < count )
	 else
	 	sprintf msg, "no igor journal files found"
	 endif
End

Function IJFP_RunJournalFile( fullfile )
	String fullfile 
	
	String line
	String cmd
	Variable refNum
	
	Variable ret_Val = -1
	Open/R refNum as fullfile
	if( refNum != 0 )
		ret_val = 0
		do
			freadline refnum, line
			if( strlen(line) < 1 )
				break;
			else
				cmd = line[0, strlen(line) - 2 ]
				printf "RemoteQ: %s\r", cmd
				Execute/Z cmd
				if( V_Flag )
					IJFP_DropFailureNoteToLog( cmd )
				endif
			endif
		
		while( 1 )
		close/A
	else
		ret_val = -1
	endif
	
	return ret_val
End

Function IJFP_DropFailureNoteToLog( cmd )
	String cmd
	
	String destFolder = "root:ifjp"
	
	NVAR freq = $(destFolder + ":freq" )
	NVAR last = $(destFolder + ":last" )
	NVAR next = $(destFolder + ":next" )
	NVAR now = $(destFolder + ":now" )
	NVAR tick_check = $(destFolder + ":tick_check" )
	
	SVAR last_str = $(destFolder + ":last_str" )
	SVAR next_str = $(destFolder + ":next_str" )
	SVAR now_str = $(destFolder + ":now_str" )
	
	SVAR incoming_dir = $(destFolder + ":incoming_dir" )
	SVAR processed_dir = $(destFolder + ":processed_dir" )
	SVAR current_file = $(destFolder + ":current_file" )
	SVAR msg = $(destFolder + ":msg" )
	
	String logFileFull, line
	sprintf logFileFull, "%sLogFile_IJFP.txt", incoming_dir
	
	Variable refNum
	if( fileexistsfullpath( logFileFull ) != 0 )
		Open/Z refNum as logFileFull
		if( refNum != 0 )
			sprintf line, "//Log File Initiated at %s", DateTime2Text(datetime)
			fprintf refNum, "%s\r\n", line
			printf "%s\r", line
			Close refnum
		endif
	endif
	Open/A/Z refNum as logFileFull
	if( refNum != 0 )
		sprintf line, "CMDF:%s", cmd
		fprintf refNum, "%s\r\n", line
		close refNum
	endif
	
End
// This function return -1 for misc failures, 0 for sucess or non zero for failure code
// Example Call IJFP_PassFile2FTPSite( "c:my local directory", "myfile.txt", "ARI_MCMA" )

Function IJFP_PassFile2FTPSite(path, file, site_token)
	String path, file, site_token
	
	NewPath/O ijfp_send_path, path
	PathInfo ijfp_send_path
	if( !V_Flag )
		print "Failue to generate path to %s on local computer, aborting"
		return -1
	endif
	
	if( FileExists( "ijfp_send_path", file ) != 0 )
		print "Failure to find %s on local computer.  Aborting"
		return -1
	endif
	
	String site_address
	String user
	String drop_folder
	String password
	String url
	
	String msg_str
	
	Variable ftpUploadCode = -1
	strswitch (lowerstr(site_token))
		case"ari_mcma":
			site_address = "ftp://mcma.aerodyne.com"
			drop_folder = "inc_to_igor"
			user = "igrj_user"
			password = "j0ur2al"
			break;
		case "ari_company":
			site_address = "ftp://ftp.aerodyne.com"
			drop_folder = "herndon"
			user = "ariuser"
			password = "transfer"
			break;	
	endswitch
	
	sprintf url, "%s/%s/%s", site_address, drop_folder, file
	if( strlen( site_address ) > 0 )
		
		FTPUpload/P=ijfp_send_path/U=user/W=password/Z/V=7/T=1 url, file
		ftpUploadCode = V_Flag
	else
		print "Warning -- evidently no token %s has been taught to ijfp_passFile2FTPsite"
		ftpUploadCode = -1
	endif

	KillPath/Z ijfp_send_path
	return ftpUploadCode
	// This function return -1 for misc failures, 0 for sucess or non zero for failure code
End
Function TestDriveBFS()
	
	Variable refNum
	
	Open/R refNum as "e:MyDocuments:031014_182908.str"
	
	// 3149036802.603550 3.252e2 4.296e5 

	FStatus refNum
	Variable fileSize = V_logEOF	
	Variable foundFraction = BinaryFileSearch( refNum, 3149036802 )
	Variable meanLineLength = MeanFileLineLength( refNum )
	Variable lineGuess = Floor( foundFraction * fileSize / meanLineLength )
	Print lineGuess
	String line
	
	FreadLine refNum, line;
	Variable idex = 0, count = 5
	do
		FreadLine refNum, line
		printf "%s\r", line[0, strlen(line) - 3 ]
		
		idex += 1
	while( idex < count )
	
	Close refNum
End
Function FileLines( refNum )
	Variable refNum
	
	FStatus refNum
	Variable atPos = V_filePos
	String line
	Variable line_count = 0
	do
		FreadLine refNum, line
		if( strlen( line ) > 1 )
			line_count += 1
		else
			break;
		endif
	while( 1 )
	
	FSetPos refNum, atPos
	return line_count
End
Function MeanFileLineLength( refNum )
	Variable refNum
	
	FStatus refNum
	Variable atPos = V_filePos
	
	String line
	Variable this_len
	Make/O/N=0 temp_meanlinelength
	Variable idex = 0, count = 200
	do
		FReadLine refNum, line
		this_len = strlen( line )
		if( this_len > 1 )
			AppendVal( temp_meanlinelength, this_len )
		else
			idex = count
		endif
	
		idex += 1
	while( idex < count )
	WaveStats/Q temp_meanlinelength 
	FSetPos refNum, atPos
	return V_avg
End
Function BinaryFileSearch( refNum, FirstColumnX )
	Variable refNum
	Variable FirstColumnX
	
	String line
	FStatus refNum
	Variable low_end, high_end, mid_pnt
	low_end = 0; high_end = V_logEOF
	
	Variable found_pos_fraction, sizeOfFile = high_end
	
	Variable idex = 0, line_count = 0, good_enough = 200, there_yet = 0
	Variable this_x
	
	do
		mid_pnt = floor( (high_end + low_end)/2 )
		
		if( high_end - low_end < good_enough )
			there_yet = 1
		else
			FSetPos refNum, mid_pnt
			FReadLine refNum, line; FreadLine refNum, line
			if( strlen( line ) < 1 )
				print "unusual in load range eof before converge"
				there_yet = 1
			else
			
			endif
			sscanf line, "%f", this_x
			if( this_x <= FirstColumnX )
				low_end = mid_pnt
			else
				if( this_x > FirstColumnX )
					high_end = mid_pnt
				else
					there_yet = 1; print "Error in BinaryFileSearch ... lost continuing"
				endif
			endif
		endif
	while( there_yet != 1 )
	
	mid_pnt -= (good_enough * 2 )
	if( mid_pnt < 0 )
		mid_pnt = 0
	endif
	
	FSetPos refNum, mid_pnt
	
	found_pos_fraction = mid_pnt / sizeOfFile
	
	return found_pos_fraction
End
Function LineFileSearchMedium( refNum, FirstColumnX, line_guess)
	Variable refNum
	Variable FirstColumnX
	Variable line_guess
	
	String style
	
	String line
	FStatus refNum
	Variable low_end, high_end, mid_pnt
	low_end = 0; high_end = V_logEOF
	
	Variable found_pos_fraction, sizeOfFile = high_end
	
	Variable idex = 0, line_count = 0, good_enough = 200, there_yet = 0
	Variable this_x
	
	do
		mid_pnt = floor( (high_end + low_end)/2 )
		
		if( high_end - low_end < good_enough )
			there_yet = 1
		else
			FSetPos refNum, mid_pnt
			FReadLine refNum, line; FreadLine refNum, line
			if( strlen( line ) < 1 )
				print "unusual in load range eof before converge"
				there_yet = 1
			else
			
			endif
			sscanf line, "%f", this_x
			if( this_x <= FirstColumnX )
				low_end = mid_pnt
			else
				if( this_x > FirstColumnX )
					high_end = mid_pnt
				else
					there_yet = 1; print "Error in BinaryFileSearch ... lost continuing"
				endif
			endif
		endif
	while( there_yet != 1 )
	
	mid_pnt -= (good_enough * 2 )
	if( mid_pnt < 0 )
		mid_pnt = 0
	endif
	
	FSetPos refNum, mid_pnt
	
	found_pos_fraction = mid_pnt / sizeOfFile
	
	return found_pos_fraction
End
Function SplitListOfScaledToXYPair( list, new_x, new_y )
	String list
	String new_x, new_y
	
	Variable idex = 0, count = ItemsInLIst( list )
	if( count > 0 )
		do
			Wave sw = $StringFromList( idex, list )
			SplitScaledWave2XY_wConcatenate( sw, new_x, new_y )
			idex += 1
		while( idex < count )
	endif
	
End
Function SplitScaledWave2XY_wConcatenate( sw, new_x, new_y )
	Wave sw
	String new_x, new_y
	
	//Step One -- see if new_x and new_y are already somewhere
	Wave/Z/D xw = $new_x
	if( !WaveExists( xw ) )
		// this conditionaly is saying not waveexists
		// therefore we get here only if the xw wave reference attempted above fails
		// so we know we ought to make them from scratch
		Make/N=0/D/O $new_x, $new_y
	endif
	Wave/D xw = $new_x
	Wave/D yw = $new_y
	
	// Step Two, run through each element in sw and tack it on the end of new_x and new_y
	Variable idex = 0, count = numpnts( sw )
	if( count > 0 )
		do
			AppendVal( xw, x2pnt( sw, idex ) )
			AppendVal( yw, sw[idex] ) 
			idex += 1
		while( idex < count )
	endif

End


Function ReturnATimeFromCursor( cursor_str , graphName)
	String cursor_str, graphName
	
	Variable ret_time = -1;

	
	String wStr = csrWave( $cursor_str, graphName )
	if( cmpstr( wStr, "" ) != 0 )
		String wXstr = csrXWave( $cursor_str, graphName )
		if( cmpstr( wXstr, "" ) == 0 )
			// then cursor is on scaled wave
			ret_time = xcsr( $cursor_str )
		else
			// cursor is displayed x vs y
			Wave xw = CsrXWaveRef( $cursor_str, graphName )
			ret_time =xw[pcsr( $cursor_str )]
		endif
	else
		printf "Cursor %s is not on any wave in %s\r", cursor_str, SelectString( cmpstr( graphName, ""), "the top window", graphName )
	endif
	return ret_time
End

// call with list = "mytimewave;data_w1;data_w2;"
// control 0 only sorst and kills on time, which you can probalby do on your own
// control 1 means that any data_w(j)[index] = Nan kills all mytimewave and data_w(all) at index
// optional argument verbosity = 1 will show diagnostic message
Function SortAndKillNansFast( list, control, [verbosity] )
	String list
	Variable control
	Variable verbosity
	
	Variable sdex, idex, jdex, count = ItemsInList( list ), kdex, kcount, fdex, loc_verbosity=0;
	String first_item = StringFromList( 0, list ), cmd;
	
	if( !ParamIsDefault( verbosity ))
		loc_verbosity = verbosity;
	endif
	
	
	Wave/Z first_w = $first_item
	if( WaveExists( first_w ) != 1 )
		return -1;
	endif
	
	if( control )
		// sort and kill from the 'back' of the list
		sdex = count - 1;
	else
		// just sort and kill on time
		sdex = 0;
	endif
	
	for( idex = sdex; idex >= 0; idex -= 1 )
		Wave sort_w = $StringFromList( idex, list );
		sprintf cmd "Sort %s", GetWavesDataFolder( sort_w,2 )
		for( jdex = 0; jdex < count; jdex += 1 )
			cmd = cmd + ", " + StringFromList( jdex, list );
		endfor
		execute/Q/Z cmd;
		kcount = numpnts( sort_w );	
		fdex= -1;
		for( kdex = 0; kdex < kcount; kdex += 1 )
			if( numtype( sort_w[kdex ] ) != 0 )
				fdex = kdex;
				kdex = kcount;
			endif
		endfor
		if( fdex != -1 )
			sprintf cmd, "DeletePoints %d, %d ", fdex, kcount - fdex
			for( jdex = 0; jdex < count; jdex += 1 )
				cmd = cmd + ", " + StringFromList( jdex, list );
			endfor
			if( verbosity )
				print cmd;
			endif
			Execute cmd;
		endif	
				
	endfor
End
Function SortAndKillNans( list, control )
	String list
	Variable control
	
	// set control to 0 to only skim Nans on Time
	// set control to 1 to skim Nans on Whole List
	
	// This is an extremely powerful function
	// it will take each wave in the list and go through killing all data points where anyone in the list is a nan
	// very potent
	// it also sorts according to the first item in the list
	// so be sure to put time here
	
	Variable idex = 0, count = ItemsInList( list )
	String first_item = StringFromList( 0, list )
	Wave/Z first_w = $first_item
	if( WaveExists( first_w ) != 1 )
		return -1
	endif
	String cmd
	sprintf cmd,  "Sort %s, %s", first_item, first_item
	idex = 1
	do
		sprintf cmd, "%s, %s", cmd, StringFromList( idex, list )
		idex += 1
	while( idex < count ) 
	Execute/Q cmd
	Variable jdex = 0, jcount = numpnts( first_w )
	if( count == 0 )
		return -1 
	endif
	
	// note that the roles of idex and jdex are reversed from convention here
	idex = 0
	do
		Wave/Z this_w = $StringFromList( idex, list )
		if( WaveExists( this_w ) != 1 )
			return -1
		endif
		jdex = 0
		do
	
			if( numtype( this_w[jdex] ) == 2 )
				DeleteIndexFromWaveList( list, jdex )
				jcount = numpnts( first_w )

			else
			
				jdex += 1
			endif
		while( jdex < jcount )
		idex += 1
		if( control == 0 )
			// then we have really already done the time this first time through
			idex = count
		endif
	while( idex < count )
	
End

Function DeleteIndexFromWaveList( list, index )
	String list
	Variable index
	
	Variable idex = 0, count = ItemsInList( list )
	Variable delCount = 0
	if( count > 0 )
		do
			Wave/Z this_w = $StringFromList( idex, list )
			if( WaveExists( this_w ) != 1 )
				print "Error in DeleteIndexFromWaveList -- Possibly very serious error, can't reference wave"
				printf "%s can't be found, this call has already deleted index %d %d of %d times", StringFromLIst( idex, list ), index, delCount, count
				return -1
			endif
			DeletePoints index, 1, this_w
			delCount += 1
			idex += 1
		while( idex < count )
	endif
End

Function ReadFile2TextWave( fullfile, tw )
	String fullfile 
	Wave/T tw
	
	String line
	String cmd
	Variable refNum
	
	Variable ret_Val = -1
	Open/R refNum as fullfile
	if( refNum != 0 )
		ret_val = 0
		Redimension/N=0 tw
		do
			freadline refnum, line
			if( strlen(line) < 1 )
				break;
			else
				cmd = line[0, strlen(line) - 2 ]
				AppendString( tw, cmd )
			endif
		
		while( 1 )
		close/A
	else
		ret_val = -1
	endif
	
	return ret_val
End

Function WriteOrAppendTextWave2File( tw, targetDir, filename )
	Wave/T tw
	String targetDir
	String filename
	
	
	Variable result = 0, refNum
	String this_file, fline
	
	String destDir
	if( cmpstr( targetDir[strlen(targetDir)-1], ":" ) == 0 )
		destDir = targetDir[0,strlen(targetDir)-2]
	else
		destDir = targetDir
	endif
	NewPath/Q/O/C twPathOut , destDir
	PathInfo twPathOut
	if( V_Flag == 0 )
		print "WriteTextWave2File couldn't make a path to", destDir
		return -1
	endif

	
	Variable idex = 0, count = numpnts( tw )
	if( count > 0 )
		Open/A/Z/P=twPathOut/T="TEXT" refNum as filename  // this commands ovewrites file. use /A to append
		if(V_flag !=0)
			print "WriteTextWave2File did not have permission to write file"
			return -1
		endif
		if( refNum != 0 )
			do
				fline = tw[idex]
				fprintf refNum, "%s\r\n", fline
				idex += 1
			while( idex < count )
			Close refNum
			result = 1
		else
			print "WriteTextWave2File couldn't open file for write"
			return -1
		endif
	else
		print "WriteTextWave2File didn't find any points in ", nameofwave(textWave)
		print "Writing empty file!"
		Open/Z/P=twPathOut/T="TEXT" refNum as filename  // this commands ovewrites file. use /A to append
		if(V_flag !=0)
			print "WriteTextWave2File did not have permission to write file"
			return -1
		endif
		
		Close refNum
		
		
		
		return 0
	endif
	KillPath/Z twPathOut
	return result
	
End

// write or append text wave 2 file. 
Function WriteOrAppTextWave2FileNoFail( tw, targetDir, filename )
	Wave/T tw
	String targetDir
	String filename
	
	// the strategy will be to prewrite the file first to a temporary name
	// then invoke the "new" move file 
	
	Variable result = 0, refNum
	String this_file, fline
	
	String destDir
	if( cmpstr( targetDir[strlen(targetDir)-1], ":" ) == 0 )
		destDir = targetDir[0,strlen(targetDir)-2]
	else
		destDir = targetDir
	endif
	NewPath/Q/O/C twPathOut , destDir
	PathInfo twPathOut
	if( V_Flag == 0 )
		print "WriteTextWave2File couldn't make a path to", destDir
		return -1
	endif

	String temporaryFileName = "tx_" + filename;
	
	Variable idex = 0, count = numpnts( tw )
	if( count > 0 )
		Open/A/Z/P=twPathOut/T="TEXT" refNum as temporaryFileName  
		if(V_flag !=0)
			print "WriteTextWave2File did not have permission to write file"
			return -1
		endif
		if( refNum != 0 )
			do
				fline = tw[idex]
				fprintf refNum, "%s\r\n", fline
				idex += 1
			while( idex < count )
			Close refNum
			result = 1
		else
			print "WriteTextWave2File couldn't open file for write"
			return -1
		endif
	else
		print "WriteTextWave2File didn't find any points in ", nameofwave(textWave)
		print "Writing empty file!"
		Open/Z/P=twPathOut/T="TEXT" refNum as filename  // this commands ovewrites file. use /A to append
		if(V_flag !=0)
			print "WriteTextWave2File did not have permission to write file"
			return -1
		endif
		
		Close refNum
		
		
		
		return 0
	endif
	
	
	// ok lets movefile
	variable moveError = 0;
	MoveFile/Z=0 /O /P=twPathOut temporaryFileName as fileName;
	moveError = V_Flag;
	if( V_Flag != 0 )
		// we have an error
		// now, because this is using the append scheme above, we won't really permanently lose
		// the queued text
		// but lets try it again, once
		Sleep/T 2
	MoveFile/Z=0 /O /P=twPathOut temporaryFileName as fileName;
		moveError = V_Flag;

		
		endif
	
	KillPath/Z twPathOut
	return moveError;
	
End


Function WriteTextWave2File( tw, targetDir, filename )
	Wave/T tw
	String targetDir
	String filename
	
	
	Variable result = 0, refNum
	String this_file, fline
	
	String destDir
	if( cmpstr( targetDir[strlen(targetDir)-1], ":" ) == 0 )
		destDir = targetDir[0,strlen(targetDir)-2]
	else
		destDir = targetDir
	endif
	NewPath/Q/O/C twPathOut , destDir
	PathInfo twPathOut
	if( V_Flag == 0 )
		print "WriteTextWave2File couldn't make a path to", destDir
		return -1
	endif
	if( FileExists( "twPathOut", filename ) == 0 ) // this is not a function
		print "Deleting preexisting listfile"
		FileIO( S_Path, filename, S_Path, filename, 2 )
	endif
	
	Variable idex = 0, count = numpnts( tw )
	if( count > 0 )
		Open/Z/P=twPathOut/T="TEXT" refNum as filename  // this commands ovewrites file. use /A to append
		if(V_flag !=0)
			print "WriteTextWave2File did not have permission to write file"
			return -1
		endif
		if( refNum != 0 )
			do
				fline = tw[idex]
				fprintf refNum, "%s\r\n", fline
				idex += 1
			while( idex < count )
			Close refNum
			result = 1
		else
			print "WriteTextWave2File couldn't open file for write"
			return -1
		endif
	else
		print "WriteTextWave2File didn't find any points in ", nameofwave(textWave)
		print "Writing empty file!"
		Open/Z/P=twPathOut/T="TEXT" refNum as filename  // this commands ovewrites file. use /A to append
		if(V_flag !=0)
			print "WriteTextWave2File did not have permission to write file"
			return -1
		endif
		
		Close refNum
		
		
		
		return 0
	endif
	KillPath/Z twPathOut
	return result
	
End
Function WriteTextWave2UnixFile( tw, targetDir, filename )
	Wave/T tw
	String targetDir
	String filename
	
	
	Variable result = 0, refNum
	String this_file, fline
	
	String destDir
	if( cmpstr( targetDir[strlen(targetDir)-1], ":" ) == 0 )
		destDir = targetDir[0,strlen(targetDir)-2]
	else
		destDir = targetDir
	endif
	NewPath/Q/O/C twPathOut , destDir
	PathInfo twPathOut
	if( V_Flag == 0 )
		print "WriteTextWave2File couldn't make a path to", destDir
		return -1
	endif
	if( FileExists( "twPathOut", filename ) == 0 )
		print "Deleting preexisting listfile"
		FileIO( S_Path, filename, S_Path, filename, 2 )
	endif
	
	Variable idex = 0, count = numpnts( tw )
	if( count > 0 )
		Open/P=twPathOut/T="TEXT" refNum as filename
		if( refNum != 0 )
			do
				fline = tw[idex]
				fprintf refNum, "%s\n", fline
				idex += 1
			while( idex < count )
			Close refNum
			result = 1
		else
			print "WriteTextWave2File couldn't open file for write"
			return -1
		endif
	else
		print "WriteTextWave2File didn't find any points in ", nameofwave(textWave)
		return -1
	endif
	KillPath/Z twPathOut
	return result
	
End

// Grid Load
// Function to load file in as textwave then parse the ascci geometrically
Function ASCII_GridLoad( fpfile, columnWidth )
	String fpfile
	Variable columnWidth
	
	Make/N=0/T/O FileAsTextWave_tw
	ReadFile2TextWave( fpfile, FileAsTextWave_tw )
	
	Variable column, linelength, row, count = numpnts( FileAsTextWave_tw )
	Variable singleColStep = columnWidth, start, stop
	String candidate_str, val_str
	
	linelength = strlen( FileAsTextWave_tw[ 0 ] )
	column = 0;
	do
		start = column * singleColStep;
		stop = start + singleColStep - 2;
		candidate_str = (FileAsTextWave_tw[ 0 ])[ start, stop ]
		candidate_str = RemoveSpaces( candidate_str );
		candidate_str = CleanUpName( candidate_str, 0 ) 
		if( cmpstr( candidate_str, "TIME" ) == 0 )
			candidate_str = "TIMEW"
		endif
		Make/D/O/N=(count-1) $candidate_str
		Wave w = $candidate_str
		//for( row = 1; row < count; row += 1 )
		//	val_str = (FileAsTextWave_tw[ row ])[ start, stop ]
		//	w[ row - 1 ] = str2num( val_Str ); 
		//endfor
		w = str2num( (FileAsTextWave_tw[ p + 1 ])[ start, stop ] );
		column += 1;
	while( start < (linelength - singleColStep ))
End
// Modified from a script by Peter Ulrich <wolf-peter.ulrich@epfl.ch>
// posted to <igor@igor.nhmfl.gov> on Nov 21, 2004

// pass a path string to have the launched Igor open an exeriment (or other file)
// pass an empty string to just launch
Function Igor2(experiment)
	String experiment
	
//	Good readings: http://developer.apple.com/technotes/tn2002/tn2065.html#TNTAG4
	String exit=" & \" > /dev/null 2>&1 & echo $!\""
	String launcher="\"/System/Library/Frameworks/Carbon.framework/Versions/A/Support/LaunchCFMApp \""
	String com="do shell script "+launcher + " & quoted form of POSIX path of (path to me)" + exit
	ExecuteScriptText com
	String pid = S_value
	
	if (strlen(experiment) > 0)
		// The 2nd Igor doesn't wake up to accepting AppleEvents for awhile.
		// Things get ugly if we don't wait a bit. Tune this time to your liking.
		Sleep 00:00:10
		
		// Sleazy! Exploit Fast User Switching to send a remote AppleEvent to the current user on the current machine...
		// Thanks to Jim Correia and <http://developer.apple.com/releasenotes/Carbon/AppleEvents.html>
		
		ExecuteScriptText "path to me as text"
		String igorName = S_value[1,strlen(S_value) - 2]
		igorName = ParseFilePath(0, igorName, ":", 1, 0)
		String  newIgor = "application \"" + igorName + "\""
		
		// It may be necessary to enter your password at times
		// change this to "eppc://username:password@127.0.0.1" if you don't like that and don't mind the security risk
		newIgor += " of machine (\"eppc://127.0.0.1/?&pid=\" & " + pid + ")"

		com = "tell " + newIgor + " to open alias \"" + experiment + "\""
		ExecuteScriptText com
	endif
End

Function LoadAndParseFlexPartTrajFile( fpfile )
	String fpfile
	
	String use_fpfile = Check4FileOrBrowse( "Select Flexpart Trajectory", fpfile )
	if( strlen( use_fpfile ) < 2 )
		printf "Invocation of LoadAndParseFlexPartTrajFile( %s ) failed to find or canceled browse\r", fpfile
		return -1
	endif
	
	String/G Check4FileMSG = use_fpfile + " file from Browse"
	
	
	make/O/T/N=0 lapfptf_tw
	printf "Loading %s >>>", use_fpfile
	ReadFile2TextWave( use_fpfile, lapfptf_tw )
	printf " in memory, parsing to waves >>>"
	
	Variable idex = 0, count = numpnts( lapfptf_tw )
	if( count > 0 )
		
		Variable inDataField = 0
		Variable newDate
		String line
		do
			// this procedure is an effort to parse
			line = lapfptf_tw[idex]
			if( inDataField )
				// throw to dataFieldParser
			
			
			
			endif // endInDataField
			
			idex += 1
		while( idex < count )
	endif
	printf "\r"
	
End

Function/T Check4FileOrBrowse( msg, fpfile )
	String msg, fpfile
	
	String return_fpfile = ""
	if( strlen( fpfile ) < 2 )
		// this will kick into a browse for dialog
		Variable refNum
		Open/M=msg/R refnum as fpfile
		if( refnum != 0 )
			Close refNum
			return_fpfile = S_fileName
		endif
	else
		return_fpfile = fpfile
	endif
	
	if( strlen( return_fpfile ) > 2 )
		if( FileExistsFullPath( return_fpfile ) != 0 )
			String/G Check4FileMSG = return_fpfile + " was not found!"
			return_fpfile = ""
		endif
	endif
	
	return return_fpfile
End
Function/T RemoveSpaces( oldstr )
	String oldstr

	String newstr = ""
	variable idex, count = strlen( oldstr )
	for( idex = 0; idex < count; idex += 1 )
		if( cmpstr( oldstr[ idex ], " " ) != 0 )
			newstr = newstr + oldstr[ idex ];
		endif
	endfor
	return newstr
End
Function/T RemoveDoubleColon( fullfile )
	String fullfile 

	Variable double_colon_pos = -2
	double_colon_pos = strsearch(  fullfile, "::", 0 )
	if( double_colon_pos == -1 )
		return fullfile
	endif
	if( double_colon_pos == -2 )
		printf "no '::' in %s\r" fullfile
		return fullfile
	endif
	
	String new_fullfile = fullfile[0, double_colon_pos-1 ]
	new_fullfile = new_fullfile + fullfile[ double_colon_pos + 1, strlen( fullfile )-1 ]
	return new_fullfile
	
End

Function/T RemoveDoubleSlash( fullfile )
	String fullfile 

	Variable double_colon_pos = -2
	double_colon_pos = strsearch(  fullfile, "//", 0 )
	if( double_colon_pos == -1 )
		return fullfile
	endif
	if( double_colon_pos == -2 )
		printf "no '//' in %s\r" fullfile
		return fullfile
	endif
	
	String new_fullfile = fullfile[0, double_colon_pos-1 ]
	new_fullfile = new_fullfile + fullfile[ double_colon_pos + 1, strlen( fullfile )-1 ]
	return new_fullfile
	
End
Function AppendWave( m, w )
	Wave m, w
	
	Variable m_rows = DimSize( m, 0 )
	Variable m_cols = DimSize( m, 1 )
	Redimension/N=( 1 + m_rows, m_cols ) m
	m[ m_rows ][] = w[q]
	
End

Function MapDataOnDriveToRoot(fullpath2files, fileprefix)
	String fullpath2files, fileprefix
	
	if( cmpstr( fullpath2files, "" ) == 0 )
		NewPath/O/Q/M="Choose directory where folders with waves are located" tot_LoadPATH
	else
		NewPath/O/Q tot_LoadPATH  fullpath2files
	endif
	if( V_Flag != 0 )
			printf "aborted, cancelled or failed NewPath\r"; return -1;
	endif
	
	Make/T/N=0/O temp_list_of_path_tw
	// GLF_ functions are in Global_Utils.ipf
	GFL_Folderlist( "tot_LoadPATH", 0, temp_list_of_path_tw, "" )
	Variable idex, count = numpnts( temp_list_of_path_tw )
	String use_path_str
	if( count > 0 )
		for( idex = 0; idex < count; idex += 1 )
			PathInfo tot_LoadPATH; use_path_str = s_path  + temp_list_of_path_tw[idex]
			print use_path_str
			NewPath/Q/O fullpath2ibw, use_path_str
			SetDataFolder root:
			MakeAndOrSetDF( temp_list_of_path_tw[idex] )
			
			LoadAll_ibw_inDir( use_path_str, "" )
			setDataFolder root:
		endfor
	endif
	SetDataFolder root:
End

Function LoadAll_ibw_inDir( fullpath2ibw, fileprefix )
	String fullpath2ibw, fileprefix
	
	if( cmpstr( fullpath2ibw, "" ) == 0 )
		NewPath/O/Q/M="Choose directory where ibw waves are located" ibw_LoadPATH
	else
		NewPath/O/Q ibw_LoadPATH  fullpath2ibw
	endif
	if( V_Flag != 0 )
			printf "aborted, cancelled or failed NewPath\r"; return -1;
	endif
	
	Make/T/N=0/O temp_list_of_ibw_tw

	// GLF_ functions are in Global_Utils.ipf
	GFL_FilelistAtOnce( "ibw_LoadPATH", 0, temp_list_of_ibw_tw, ".ibw" )
	
	String this_ibw
	Variable prefix_length = strlen( fileprefix)
	Variable idex = 0, count = Numpnts( temp_list_of_ibw_tw )
	Variable found_ibws = 0
	Variable load_this_one = 0
	if( count > 0 )
		do
			this_ibw = temp_list_of_ibw_tw[idex];		load_this_one = 0
			if( cmpstr( fileprefix, "" ) == 0 )
				load_this_one = 1;
			else
				if( cmpstr( fileprefix, this_ibw[0,prefix_length-1]) == 0 )
					load_this_one = 1;
				endif
			endif
			
			if( load_this_one )
				LoadWave/H/P=ibw_LoadPATH/O this_ibw
				found_ibws += 1
			endif
			idex += 1
		while( idex < count )
		if( found_ibws == 0 )
			printf "no ibw waves matching criteria were found\r"
		endif
	
	else
		printf "No ibw files at all found in the directory\r"
	endif
	
	// and clean up afterward
	KillPath/Z ibw_LoadPATH
	KillWaves/Z temp_list_of_ibw_tw
	return found_ibws
End
Function DF_Reconstruct_Open( fullpath2ibw, data_folder )
	String fullpath2ibw, data_folder
	
	if( cmpstr( fullpath2ibw, "" ) == 0 )
		NewPath/O/Q/M="Choose directory where data folder reconstrct waves are located" ibw_LoadPATH
	else
		NewPath/O/Q ibw_LoadPATH  fullpath2ibw
	endif
	if( V_Flag != 0 )
			printf "aborted, cancelled or failed NewPath\r"; return -1;
	endif
	PathInfo ibw_LoadPATH
	// we need to help the user here in case they picked too deep or misused the function

	String call_in_str = s_path, final_path, no_trail_colon;
	if( cmpstr( call_in_str[strlen(call_in_str)-1], ":" ) == 0 )
		no_trail_colon = call_in_str[0, strlen(call_in_str) - 2 ]
	else
		no_trail_colon = call_in_str
	endif
	String last_in_path = StringFromList( ItemsInList( no_trail_colon, ":" )-1, call_in_str, ":" )
	if( cmpstr( last_in_path, data_folder ) != 0 )
		sprintf final_path, "%s:%s", call_in_str, data_folder
		final_path =  RemoveDoubleColon( final_path )
	else
		final_path = call_in_str;
	endif
	NewPath/O/Q/C ibw_LoadPATH final_path	
	Make/T/N=0/O temp_list_of_ibw_tw

	// GLF_ functions are in Global_Utils.ipf
	GFL_FilelistAtOnce( "ibw_LoadPATH", 0, temp_list_of_ibw_tw, ".ibw" )
	SetDataFolder root:;
	MakeAndOrSetDF( data_folder );
	
	String this_ibw
	Variable idex = 0, count = Numpnts( temp_list_of_ibw_tw )
	Variable found_ibws = 0
	Variable load_this_one = 0
	if( count > 0 )
		do
			this_ibw = temp_list_of_ibw_tw[idex];
			if( strlen( this_ibw) > 0 )		
				LoadWave/H/P=ibw_LoadPATH/O this_ibw
			endif
			idex += 1
		while( idex < count )
	else
		printf "No ibw files at all found in the directory\r"
	endif
	
	// and clean up afterward
	KillPath/Z ibw_LoadPATH
	KillWaves/Z temp_list_of_ibw_tw
	SetDataFolder root:;
	return count
End
Function DF_Reconstruct_Save( fullpath2ibw, data_folder )
	String fullpath2ibw, data_folder
	
	if( cmpstr( fullpath2ibw, "" ) == 0 )
		NewPath/O/Q/M="Choose directory where data folder should be saved" ibw_LoadPATH
	else
		NewPath/O/Q ibw_LoadPATH  fullpath2ibw
	endif
	if( V_Flag != 0 )
			printf "aborted, cancelled or failed NewPath\r"; return -1;
	endif
	PathInfo ibw_LoadPATH
	// we need to help the user here in case they picked too deep or misused the function

	String call_in_str = s_path, final_path;
	String last_in_path = StringFromList( ItemsInList( call_in_str ), call_in_str, ":" )
	if( cmpstr( last_in_path, data_folder ) != 0 )
		sprintf final_path, "%s%s", call_in_str, data_folder
	else
		final_path = call_in_str;
	endif
	NewPath/O/Q/C ibw_LoadPATH final_path
	
	
	
	Make/T/N=0/O temp_list_of_ibw_tw

	// GLF_ functions are in Global_Utils.ipf
//	GFL_FilelistAtOnce( "ibw_LoadPATH", 0, temp_list_of_ibw_tw, ".ibw" )
	
	SetDataFolder root:;
	MakeAndOrSetDF( data_folder );
	String list = WaveList( "*", ";", "" )
	String this_ibw
	Variable idex = 0, count = ItemsInList( list )
	Variable found_ibws = 0
	Variable load_this_one = 0
	if( count > 0 )
		do
			this_ibw = StringFromList( idex, list );
			Wave w = $this_ibw
			Save/O/P=ibw_LoadPATH  w
			idex += 1
		while( idex < count )
	else
		printf "No ibw files at all found in the directory\r"
	endif
	
	// and clean up afterward
	KillPath/Z ibw_LoadPATH
	KillWaves/Z temp_list_of_ibw_tw
	return count
End

Function QuartileReport( w, verbosity )
	Wave w
	Variable verbosity
	
	Duplicate/O w, TempQuart; 
	Sort TempQuart, TempQuart; 
	Variable idex, count
	WaveStats/Q TempQuart
	if( V_numNans > 0 )
		do
			if( numtype( TempQuart[idex] )== 2  )
				DeletePoints idex, numpnts( TempQuart ) - idex, TempQuart
			else
				idex += 1
			endif
		while( idex < numpnts(TempQuart) )
	endif
	count = numpnts( TempQuart )
	Variable/G V_Quartilen = count
	Variable/G V_Quartile25 = TempQuart[ Floor(0.25 	* count)]
	Variable/G V_Quartile50 = TempQuart[ 0.5 		* count]
	Variable/G V_Quartile75 = TempQuart[ 0.75	* count]	
	
	if( verbosity != 0 )
		if( v_Quartile50 > 1000 )
			printf "Quartile (%d) 25th: %5.3e   50th: %5.3e  75th %5.3e\r", v_Quartilen, V_Quartile25, V_Quartile50, V_Quartile75
		else
			printf "Quartile (%d) 25th: %5.4f   50th: %5.4f  75th %5.4f\r", v_Quartilen, V_Quartile25, V_Quartile50, V_Quartile75
		endif
	endif
End

Function JulianDecimal2DateTime( in_year, in_julian_w_decimal )
	Variable in_year
	Variable in_julian_w_decimal
	
	Variable integer = Floor( in_julian_w_decimal )
	Variable decimal = in_julian_w_decimal - integer
	
	String julian_str = JulianToDate( integer, 0 )
	String month_str = StringFromList( 0, julian_str, "/" )
	String day_str = StringFromList( 1, julian_str, "/" )
	String year_str = num2str( in_year )
	
	String full_date_str
	sprintf full_date_str, "%s/%s/%s 00:00:00", month_str, day_str, year_str
	
	Variable ret_val = Text2DateTime( full_date_str ) + decimal * (24*3600)
	
	return ret_val
End
	
	
	

/////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
Function AddCalendarWindow( start_time, returnFunc, winNameStr )
	Variable start_time
	String returnFunc
	String winNameStr
	
	String saveFolder = GetDataFolder(1); SetDataFolder root:; MakeAndOrSetDF( "panel_calendar" )
	Variable/G now_time = start_time
	String/G now_str = DateTime2Text( now_time )
	String/G month_str = AddCalendarMonthStr( AddCalendarWindowDAT2M( now_time ))
	String/G gs_returnFunc = returnFunc
	
	NewPanel/EXT=0 /FLT=1 /W=(0,0,280,210) /HOST=$winNAmeStr /N=kwCalendar
	AddCalendarUpdateDisp()

	SetDataFolder $saveFolder
End

Function AddCalendarWindowDOW( a_dat )
	Variable a_dat
		String braket_str = StringFromList( 1, Secs2Date( a_dat ,-1), " ")
	return str2num( braket_str[1] )
End
Function AddCalendarWindowDAT2D( a_dat )
	Variable a_dat
		String fds = StringFromList( 0, StringFromList( 0, Secs2Date( a_dat, -1 ), " " ), " " )
	return str2num( fds )
End
Function AddCalendarWindowDAT2M( a_dat )
	Variable a_dat
		String fds = StringFromList( 0, Secs2Date( a_dat, -1 ), " " )
		String pms = StringFromLIst(1, fds , "/" )
	return str2num( pms )
End

Function AddCalendarUpdateDisp()

	NVAR now_time = root:panel_calendar:now_time
	
	String full_date_str = Secs2Date( now_time, -1 )
	
	String date_str = StringFromList( 0, full_date_str, " " )
	String dow_str = StringFromList( 1, full_date_str, " " )[1]

	String saveFolder = GetDataFolder(1); SetDataFolder root:panel_calendar

	Variable/G year = str2num( StringFromList( 2, date_str, "/" ))
	Variable/G month = str2num( StringFromList(1, date_str, "/" ))
	Variable/G day = str2num( StringFromList( 0, date_str, "/" ))
	String/G month_str =  AddCalendarMonthStr( month )
	Variable/G day1dat = Date2Secs( year, month, 1 )
	Variable/G dow0 = AddCalendarWindowDOW( day1dat )
	
	
	NVAR month=root:panel_calendar:month
	NVAR year = root:panel_calendar:year
	NVAR day1dat = root:panel_calendar:day1dat
	NVAR dow0 = root:panel_calendar:dow0
	
	Make/D/O/N=42 datInMonth
	Make/O/N=42 IsThisMonth
	datInMonth = nan; IsThisMonth = 0
	Variable idex = 0, count = 42
	for( idex = 0; idex < count; idex +=1 )
		datInMonth[idex] = day1dat + (idex-(dow0-1)) * 24*3600
		if( AddCalendarWindowDAT2M( datInMonth[idex] ) == month )
			IsThisMonth[idex] =  1
		else
			IsThisMonth[idex] = 0
		endif
	endfor
	Make/O/N=(6,7) DispNumber
	
	Variable jdex, jcount = 7
	for( idex = 0; idex < 6; idex += 1 )
		for( jdex = 0; jdex < jcount; jdex += 1 )
			DispNumber[idex][jdex] = AddCalendarWindowDAT2D( datInMonth[ idex * 7 + jdex ] )
		endfor
	endfor
	
	String but_name, but_title
	Variable pos_x, pos_y, thismonth
	for( idex = 0; idex < 6; idex += 1 )
		for( jdex = 0; jdex < 7; jdex += 1 )
			pos_y = idex * 22 + 50
			pos_x = jdex * 35 + 5
			sprintf but_name, "CalendarButton_%d_%d", idex, jdex
			thismonth = IsThisMonth[idex*7+jdex]
			sprintf but_title, " %d", DispNumber[idex][jdex]
			Button $but_name, pos={pos_x, pos_y}, title = but_title, size={30,20}, fstyle=thismonth, proc=AddCalendarBut
		endfor
	endfor
	Button MinusButton, pos={5, 5}, size={50, 20}, title="prev", proc=AddCalendarBut
	SetVariable ThisMonthSV, pos = {57, 5}, size={90, 20}, fsize=14, title=" ", disable=2, bodywidth=83, frame=0, value=root:panel_calendar:month_str
	SetVariable ThisYearSV, pos={150, 5}, size={40, 20}, fsize=14, title=" ", disable=2, bodywidth=45, frame=0, value=root:panel_calendar:year, limits={-inf, inf, 0}
	Button PlusButton, pos={200, 5}, size={50, 20}, title="next", proc=AddCalendarBut
	SetDataFolder $saveFolder
End

Function AddCalendarBut(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	Variable jump_month = 0
	Variable row_push, col_push
	NVAR now_time = root:panel_calendar:now_time
	Wave datInMonth = root:panel_calendar:datInMonth
	NVAR month = root:panel_calendar:month
	NVAR year = root:panel_calendar:year
	NVAR day = root:panel_calendar:day
	SVAR gs_returnFunc = root:panel_calendar:gs_returnFunc
	
	switch( ba.eventCode )
		case 2: // mouse up
			strswitch( ba.ctrlName )
				case "MinusButton":
					jump_month = -1
					break;
				case "PlusButton":
					jump_month = 1
					break;
			endswitch
			if( jump_month != 0 )
				month += jump_month
				now_time = Date2Secs( year, month, day )
				AddCalendarUpdateDisp()	
			endif
			if( jump_month == 0 )
				if( cmpstr( StringFromList( 0, ba.ctrlName, "_" ), "CalendarButton" ) == 0 )
					row_push = str2num(  StringFromList( 1, ba.ctrlName, "_" ))
					col_push = str2num(  StringFromList( 2, ba.ctrlName, "_" ))
					now_time = datInMonth[ row_push * 7 + col_push ] 
					Funcref AddCalendarWindowDat2D f = $gs_returnFunc
					f( now_time )
					DoUpdate
					print "calendar complete - returning " +  datetime2text( now_time )
					KillWindow #
					//DoWindow/K  
					///T kwCalendar
					
				endif
			endif	
			break
	endswitch

	return 0
End

Function/T AddCalendarMonthStr( month )
	Variable month
	
	string ret_str = ""
		Switch( month )
			case 1:
				ret_str= "January"
				break;
			case 2:
				ret_str= "February"
				break;
			case 3:
				ret_str= "March"
				break;
			case 4:
				ret_str= "April"
				break;
			case 5:
				ret_str= "May"
				break;
			case 6:
				ret_str= "June"
				break;
			case 7:
				ret_str= "July"
				break;
			case 8:
				ret_str= "August"
				break;
			case 9:
				ret_str= "September"
				break;
			case 10:
				ret_str= "October"
				break;
			case 11:
				ret_str= "November"
				break;
			case 12:
				ret_str= "December"
				break;
		endswitch			
	return ret_str
End


Function/S DemoUnixShellCommand()
		// Paths must be POSIX paths (using /).
		// Paths containing spaces or other nonstandard characters
		// must be single-quoted. See Apple Techical Note TN2065 for
		// more on shell scripting via AppleScript.
		String unixCmd
		unixCmd = "ls '/Applications/Igor Pro Folder'"
		
		String igorCmd
		
		sprintf igorCmd, "do shell script \"%s\"", unixCmd
		Print igorCmd							// For debugging only.
	
		ExecuteScriptText igorCmd
		Print S_value							// For debugging only.
		return S_value
End

Function Secs2DateHourMin_NoSec( a_DateTime )
	Variable a_DateTime

	String TextDateTime = DateTime2Text( a_DateTime )
	Variable year, month, day, hour, minute, second
	
	sscanf textDateTime, "%d/%d/%d %d:%d:%d", month, day, year, hour, minute, second
	if( year < 100 )
		if( year < 39 )
			year += 2000
		else
			year += 1900
		endif
	endif
	return 3600 * hour + 60 * minute + Date2Secs( year, month, day )
End

// Function MC06_anyXYontoQAMV( source_time, source_data, vector_name, modification_Note )
// Call like , 
// MC06_anyXYontoQAMV( d3_InletTime, d3_RH, "M4_AtmosphericRH", "kit from Scott" )
Function MET_AnyXYontoQAMV( source_time, source_data, vector_name, modification_Note )
	Wave source_time
	Wave source_data
	String vector_name
	String modification_Note
	
	Variable algorithm_number = 1
	
	Variable begin_time = Text2DateTime( "1/1/08 00:00:00" ); 
	Variable end_time = Text2DateTime( "1/1/09 00:00:00" );
	Variable one_minute = 300 // seconds
	Variable pnts = ceil((end_time - begin_time + 1 )/ one_minute )
	Variable use_wave_locks = 1;
	Wave/Z QAMaster_w = $vector_name
	if( WaveExists( QAMaster_w ) != 1 )
		printf "Warning:  Creating %s for the first time with foo defaults\r", vector_name
		
		Make/N=(pnts)/D/O $vector_name
		//Make/N=(908/2)/D/O $vector_name
		//Make/N=(31*24*60)/D/O $(vector_name + "_Narsto_tw")
		
		Wave QAMaster_w = $vector_name
		//Wave/T narsto_tw = $(vector_name + "_Narsto_tw")
		
		SetScale/P x, begin_time, one_minute, "dat", QAMaster_w
		SetScale/P y, 0, 0, "", QAMaster_w
		QAMaster_w = nan; 
	endif
	
	Variable idex = 0, count = numpnts( source_time )
	Variable this_index, print_warning = 0;
	if( use_wave_locks )
		SetWaveLock 0, QAMaster_w    // This unlocks the wave for this overlay
	endif
	
	// we will trigger the minute averaging algorithm using the next minute after the first data
	// or if the first data in source_time is 3/10/2006 23:34:18
	// this algorithm will begin to work on 3/10/2006 23:35:00
	
	Variable begin_minute = Secs2DateHourMin_noSec(source_time[0]) + 60
	Variable end_minute = Secs2DateHourMin_noSec(source_time[numpnts(source_time)-1])
	Variable now_minute = begin_minute
	Variable begin_dex, end_dex, master_dex
	Variable points, number_to_keep
	do
		begin_dex = BinarySearch( source_time, now_minute )
		end_dex = BinarySearch( source_time, now_minute + one_minute )
		WaveStats/R=[begin_dex, end_dex]/Q source_data
		points = v_npnts
		// DO NOT INSERT CODE HERE V_<flags> are set
		if( algorithm_number == 1 ) // algorithm_1 is like the 'mean'
			number_to_keep = Nan
			if( points > 0 )
				number_to_keep = v_avg
//				number_to_keep = V_sdev
			endif
		endif
		
		master_dex = x2pnt( QAMaster_w, now_minute )
		QAMaster_w[master_Dex] = number_to_keep

		now_minute += one_minute
	while( now_minute < end_minute )

	if( use_wave_locks )
		SetWaveLock 1, QAMaster_w // This locks the wave for casual modifications
		printf "Locking wave %s for modification access\r Use SetWaveLock 0, %s to unlock\r", NameOfWave( QAMaster_w ), NameOfWave( QA_Master_w )	
	endif
		
	Note QAMaster_w, modification_Note
	
	printf "Overlay is complete for %s; %s; %s\r", NameOfWave( source_time ), NameOfWave( source_data ), NameOfWave( QAMaster_w )
	printf "-=-=-= History of %s -=-=-=-= \r -=-=-=-=-=-=-=-=-=-=-=\r", NameOfWave( QAMaster_w )
	printf "%s\r", note( QAMaster_w )
End
Function ConvertFarh2Cels( F )
	Variable F
	return (5/9) * ( F-32 )
End
Function ConvertCels2Farh( C )
	Variable C
	return (9/5) * C + 32
End
Function ConvertMPH2MetersPerSecond( mph )
	Variable mph
	return mph / 2.236
End
Function MET_Suite()

	MET_AnyXYontoQAMV( met_time, met_temperatureF, "M08_TemperatureF", "KMABILLE7-scott-6-9" )
	MET_AnyXYontoQAMV( met_time, met_pressureIn, "M08_PressureIn", "KMABILLE7-scott-6-9" )
	MET_AnyXYontoQAMV( met_time, met_dewpointF, "M08_DewPointF", "KMABILLE7-scott-6-9" )
	MET_AnyXYontoQAMV( met_time, met_WindDirectionDegrees, "M08_WindDegrees", "KMABILLE7-scott-6-9" )
	MET_AnyXYontoQAMV( met_time, met_WindSpeedMPH, "M08_WindSpeedMPH", "KMABILLE7-scott-6-9" )
	MET_AnyXYontoQAMV( met_time, met_WindSpeedGustMPH, "M08_WindSpeedGustMPH", "KMABILLE7-scott-6-9" )
	MET_AnyXYontoQAMV( met_time, met_Humidity, "M08_Humidity", "KMABILLE7-scott-6-9" )
	MET_AnyXYontoQAMV( met_time, met_temperatureF, "M08_HourlyPrecipIn", "KMABILLE7-scott-6-9" )
	
	Wave t = M08_TemperatureF; Duplicate/O t, M08_TemperatureC; Wave d = M08_TemperatureC; d=ConvertFarh2Cels( t )
	Wave t = M08_WindSpeedMPH; Duplicate/O t, M08_WindSpeedMPS; Wave d = M08_WindSpeedMPS; d=ConvertMPH2MetersPerSecond( t )
	
	
End

Function scAverageFastDataBetweenBigGaps( time_w, data_w, newName )
	Wave time_w
	Wave data_w
	String newName
	
	Make/o/d/n=0 $(newName + "_time" );		Wave dest_t = $(newName + "_time" )
	Duplicate/O dest_t, $(newName + "_data" );		Wave dest_w = $(newName + "_data" )
	Duplicate/O dest_t, $(newName + "_sigma" );	Wave dest_s = $(newName + "_sigma" )
	
	Duplicate/O time_w, afdbg_dtime,afdbg_hist_dtime
	Wave afdbg_dtime=afdbg_dtime
	Wave afdbg_hist_dtime=afdbg_hist_dtime
	Differentiate afdbg_dtime; Histogram afdbg_dtime, afdbg_hist_dtime
	WaveStats/Q afdbg_hist_dtime
	Variable fast_common_step = v_maxloc
	Variable threshold_dt = 4 * fast_common_step
	
	Duplicate/O time_w, afdbg_gaptime
	Duplicate/O afdbg_dtime, afdbg_gapdt
	 afdbg_gapdt =  afdbg_gapdt[p] > threshold_dt ? 1 : nan
	 Sort afdbg_gapdt, afdbg_gapdt, afdbg_gaptime
	 
	Variable idex, count = numpnts( afdbg_gapdt )
	for( idex = 0; idex < count; idex += 1 )
		if( numtype( afdbg_gapdt[idex] ) != 0 )
			print idex
			DeletePoints idex, count - idex, afdbg_gapdt, afdbg_gaptime
			idex = count
		endif
	endfor
	
	Sort afdbg_gaptime, afdbg_gapdt, afdbg_gaptime
	Variable bdex, edex
	count = numpnts( afdbg_gaptime )
	for( idex = 0; idex < count; idex += 1 )
		if( idex == 0 )
			bdex = 0
		else
			bdex = BinarySearch( time_w, afdbg_gaptime[idex] )
			idex += 1
		endif
		
		edex = BinarySearch( time_w, afdbg_gaptime[idex] )
		edex -= 1
	//	print bdex, edex
		WaveStats/Q/R=[bdex, edex] time_w
		AppendVal( dest_t, v_avg )
		WaveStats/Q/R=[bdex, edex] data_w
		Appendval( dest_w, v_avg )
		AppendVal( dest_s, v_sdev )
	endfor
	
End
Function CloneGraphHandler()

	GetWindow/z  kwTopWin title
	string savefolder = GetDatafolder(1)
	
	
	String winNameStr = S_Value
	if( WinType( winNameStr ) == 1 ) // this is a graph
		String sdfStr
		Prompt sdfStr, "data folder to clone to"
		DoPrompt/Help="function makes copy of all data in top graph and stashes in subfolder"	"Clone Top Graph to DataFolder" , sdfStr
		CloneGraph2NameDF(GraphName=winNameStr,name=sdfStr)
	elseif(winType( winNameStr) == 3) // this is a Layout
		Prompt sdfStr, "data folder to clone to"
		DoPrompt/Help="function makes copy of all data in top graph and stashes in subfolder"	"Clone Top Graph to DataFolder" , sdfStr
		
		String generalInfo = LayoutInfo(winNameStr, "Layout")
		Variable objects = str2num(stringbykey("NUMOBJECTS", generalInfo))
		

		SetDataFolder root:;
		String RecMacStr=WinRecreation(winNameStr,0)
		
		// now investigate graphs in layout
		variable i
		for(i=0;i<objects;i+=1)
			string objInfo = LayoutInfo(winNameStr, num2str(i))
			String objName = stringbykey("NAME",objinfo)
			String objType = stringbykey("TYPE",objinfo)
			if(stringmatch(objType,"Graph"))
				CloneGraph2NameDF(GraphName=objName,name=sdfStr)
				String ThisNewName = sdfStr +"_" +num2str(i)
				dowindow/F $sdfStr
				DoWindow/C $thisNewName
				DoWindow/T $thisNewName, thisNewName
				
				// replace
				recMacStr = ReplaceString (objName+"\r", recMacStr, thisNewName+"\r")
				
			elseif(stringmatch(objType,"Textbox"))
				// do nothing, it's probably fine
			else
				printf "no support for %s type objects in layouts. Make sure required data is in %s folder.", objType, sdfstr
			endif
		endfor


		Execute /Q recMacStr
		String name = sdfStr + "_Layout"
		DoWindow/C $name
		DoWindow/T $name, name
		
	else
		printf "Set the graph or layout for cloning to be foremost\rCloneGraphHandler()\r"
	endif
	setdatafolder saveFolder
	
End


// set CloneGraph2NameDF(GraphName="DispTransWin",name="Isop_2301")
// to copy DispTransWin to new datafolder root:Isop_2301 and slide wave copy
Function CloneGraph2NameDF([GraphName,name])
	String GraphName
	String name 
	
	if(ParamIsDefault(GraphName))
		GraphName=WinName(0,1)
	endif
	if(ParamIsDefault(name))
		name=UniqueName(GraphName,6, 0)
	else
		name=CleanupName(name,0)
	endif

	Variable  idex, jdex, count 
	String saveFolder, RecMacStr, traceList, this_trace, imagelist
	String line, xtra_names, xtra_path, xtra_name
	
	SetDataFolder root:; // this should make recreation wave locations from the root reference. 
	RecMacStr=WinRecreation(GraphName,0)
	saveFolder=GetDataFolder(1); MakeAndOrSetDF( name ) 
	
	// normal traces, possible Y only or XY
		traceList=TraceNameList(GraphName,";",3) 
		count = ItemsInList(traceList);
		for( idex =0; idex <count; idex +=1)
			this_trace=StringFromList( idex ,traceList)
			
			Wave/Z TraceWave=TraceNameToWaveRef(GraphName,this_trace)
			Duplicate/O TraceWave $NameOfWave(TraceWave)
	
			Wave/Z TraceXWave=XWaveRefFromTrace(GraphName,this_trace)
			if(WaveExists(TraceXWave))
				Duplicate/O TraceXWave $NameOfWave(TraceXWave)
			endif
			
		endfor

	// images		
		imagelist = ImageNameList(GraphName,";")
	 	count = ItemsInList(imageList);
		for( idex =0; idex <count; idex +=1)
			this_trace=StringFromList( idex ,imageList)
			wave/z TraceWave = imageNameToWaveRef(graphName, this_trace)
			Duplicate/O TraceWave $NameOfWave(TraceWave)
		endfor
		
	// other waves needed for macro recreation!!
	 	count = ItemsInList( recMacStr, "\r" );
		for( idex = 0; idex < count; idex +=1)
			line = StringFromList( idex, RecMacStr,"\r")
			
			//ErrorBars UTM_Northing Y,wave=(:test:UTM_Easting,:test:UTM_Northing)
			if(stringmatch(line,"*ErrorBars*") )
				sscanf line,"%*[^=]=(%[^)])",xtra_names
				
				for(jdex=0;jdex<2;jdex+=1)
					xtra_path=StringFromList(jdex,xtra_names,",")
					sscanf xtra_path,"%[^[])",xtra_path
					xtra_name=StringFromList(ItemsInList(xtra_path,":")-1,xtra_path,":")
					xtra_path = "root:"+xtra_path
					xtra_path = replaceString("::",xtra_path,":")
					
					Duplicate /O $(xtra_path) $xtra_name
				endfor
				

			// they need to be OK with multiple on same line. 
			
		// trace z options!
		// these Regex need to be OK with Sub-ranges or no sub-ranges...			

			//	ModifyGraph/Z zColor[3]={:GUD:gps_CH4,1800,5000,Geo},zColor[10]={:GUD:seg_gps_time[0,4],*,*,Rainbow}
				//	ModifyGraph/Z zmrkSize[1]={:GUD:gps_N2O,*,700,3,6},zmrkSize[2]={:GUD:gps_N2O,*,*,1,5}
				//	ModifyGraph zmrkNum(fullShore_Northing#1)={:geolocs:nl_edf:fullShore_FacilityTypeNUM}
				//	ModifyGraph zpatNum(seg_gps_north#2)={fullShore_clusterID[0,203]}
				//	ModifyGraph/Z arrowMarker[10]={:GUD:WindBarbsData,2,10,0.5,0}
				//ModifyGraph/Z textMarker[14]={:GUD:otm_emisSLPM_CH4,"default",0,0,5,0.00,0.00}
			elseif(stringmatch(line, "*zColor*={*}*")||stringmatch(line, "*zmrkSize*={*}*")||stringmatch(line, "*zmrkNum*={*}*")||stringmatch(line, "*zpatNum*={*}*")||stringmatch(line, "*arrowMarker*={*}*")||stringmatch(line, "*textMarker*={*}*"))

		// the below REGEX should work but doesn't...
		//		splitstring /E="(?<={)*(?=,|}|\[)" line, name1, name2, name3, name4, name5

		// instead we tediously parse. 
			do
				splitstring /E="{\S*?}" line
				xtra_names = S_value
				
				if(strlen(S_Value)>0)
				// remove the match from line. 
				line = replaceString(S_value, line, "", 1)
				
				// remove those curly quotes
				xtra_names = replaceString("{", xtra_names, "", 1)
				xtra_names = replacestring("}", xtra_names, "", 1)
				
				// parse wavename portion before comma
				xtra_names = stringFromList(0, xtra_names, ",")
				
				// parse wavename portion before optional sub-range
				xtra_names = stringFromList(0, xtra_names, "[")
				
				// make sure we have a full path
				xtra_names = "root:"+xtra_names
				xtra_names = replaceString("::", xtra_names, ":")
				
				// get name of wave without path
				xtra_name = stringfromList(itemsInList(xtra_names,":")-1, xtra_Names, ":")
				
				Duplicate/O $xtra_names $xtra_name
				endif
			while (!stringmatch(S_value,"")) // do while we have matches

			endif

		endfor
	 
		
		Execute/Q RecMacStr
		
		Dowindow $name
		if(V_flag != 0 ) // then graph exists
			Killwindow $name
		endif
		

		DoWindow/C $name
		DoWindow/T $name, name
		ReplaceWave allInCDF
		

	SetDataFolder $saveFolder
End

Function CatDataFolderToRoot( dfstr )
	String dfstr


	SetDataFolder root:;
	SetDataFolder $dfstr
	
	String list = WaveList( "*", ";", "" ), cmd
	Variable idex, count = itemsinlist( list )
	
	for( idex = 0; idex < count ; idex += 1 )
	
		
		Wave w = $StringFromList( idex, list )
		Wave/Z dw = $("root:" +  StringFromList( idex, list ) )
		if( WaveExists( dw ) )
			sprintf cmd, "ConcatenateWaves( \"%s\", \"%s\" )",  ("root:" + StringFromList( idex, list ) ), ("root:" + dfstr + ":" + StringFromList( idex, list ) )
			Execute cmd
		else
			Duplicate/O w, $("root:"+ StringFromList( idex, list ) )
		endif
	endfor
	SetDataFolder root:
	
End

// Convolve Fast Data With Rev[erse] Tau Shape
// this function takes the x-y source waves, the variable tau and generates a new y-wave named "destStr" that has been convolved
Function ConvolveFastDataWithRevTauShape( src_time, src_data, var_tau, str_destStr)
	Wave src_time
	Wave src_data
	Variable var_tau
	String str_destStr
	
	Duplicate/O src_data, $str_destStr
	Wave dest_w = $str_destStr
	
	Duplicate/O src_time, cfdwrts_temp
	Histogram src_time, cfdwrts_temp
	WaveStats/Q cfdwrts_temp
	Variable common_dtime = v_maxloc
	Variable side_pnts = (var_tau+1)*5
	Variable pnts = 2*side_pnts + 1
	Make/N=(pnts)/O cfdwrts_conv
	SetScale/P x,  -1*side_pnts, 1, cfdwrts_conv
	cfdwrts_conv = x <=0 ? exp(  x/var_tau ) : 0
	Variable areasum = sum( cfdwrts_conv )
	cfdwrts_conv /= areasum
	
	// cfdwrts_conv is now a fin shaped function exponentially tapering to the negative and zero to the positive side.
	
End

Function GetPxpName()

	string combo
	String fileName = IgorInfo(1)
	String path
	PathInfo home
	path = s_path
	
//	sprintf combo, "%s%s.pxp", path, fileName
	sprintf combo, "%s.pxp",  fileName
	PutScrapText combo
	
End

Function QCL_GetGoodStuffFromValve( dataFolder )
	String dataFolder

	SetDatafolder root:
	SetDataFolder dataFolder	
	// function goes into folder with loaded STC and decimates it into just the good stuff
	String waklist = WaveList( "*", ";", "" )
	waklist = RemoveFromList( "stc_time", waklist )
	waklist = RemoveFromList( "stc_StatusW", waklist )
	
	Variable idex, count = ItemsInList( waklist ), checkInpnts, checkOutpnts
	for( idex = 0; idex < count; idex += 1 )
		KillWaves/Z $StringFromList( idex, waklist )
	endfor
	
	Wave status_w = stc_StatusW
	Wave time_w = stc_time
	
	Duplicate/O status_w, status_sans16
	for( idex = 0; idex < 16; idex += 1 )
		Wave dest_w = status_sans16
		dest_w = Floor( dest_w / 2 )
	endfor
	
	Duplicate/O dest_w, status_V1, status_V2, status_V3, status_v4, status_V2or3
	
	status_V1 = dest_w & 1 ? 1 : 0
	status_v4 = dest_w & 8 ? 1 : 0
	//
	status_V1 = status_v4 == 1 ? 1 : status_v1
	
	status_V2 = dest_w & 2 ? 1 : 0
	status_V3 = dest_w & 4 ? 1 : 0
	status_V2or3 = (status_v2 ==1) | ( status_v3 == 1 ) ? 1 : 0
	 
	// make V2 in times and accompanying v2 out times?
	Make/N=0/D/O V2_InTime, V2_OutTime
	Duplicate/O status_V2, dstatus;	Differentiate/METH=1 dstatus
	Duplicate/O dstatus, ddstatus;	Differentiate/METH=1 ddstatus
	count = numpnts( status_v2 )
	for( idex = 0; idex < count; idex += 1 )
		
			if( dstatus[idex] > 0 )
				// this is a valve on time
				AppendVal( V2_InTime, time_w[idex] )
			endif
			if( dstatus[idex] < 0 )
				AppendVal( V2_OutTime, time_w[idex] )
			endif
		
	endfor
	checkInPnts = numpnts( V2_InTime );	checkOutPnts = numpnts( V2_OutTime )
	if( checkInPnts > checkOutpnts )
		printf "In Function GetGoodStuffFromValves -- mismatch in V2_ -- deleteing ONE in Time at %s\r", DateTime2Text( V2_InTime[ checkInPnts - 1] )
		DeletePoints checkInPnts -1, 1, V2_InTime
	endif
	
	
	// make V1 in times and accompanying v1 out times?
	Make/N=0/D/O V1_InTime, V1_OutTime
	Duplicate/O status_V1, dstatus;	Differentiate/METH=1 dstatus
	Duplicate/O dstatus, ddstatus;	Differentiate/METH=1 ddstatus
	count = numpnts( status_v1 )
	for( idex = 0; idex < count; idex += 1 )
		
			if( dstatus[idex] == 1 )
				// this is a valve on time
				AppendVal( V1_InTime, time_w[idex] )
			endif
			if( dstatus[idex] == -1 )
				AppendVal( V1_OutTime, time_w[idex] )
			endif
		
	endfor
	checkInPnts = numpnts( V1_InTime );	checkOutPnts = numpnts( V1_OutTime )
	if( checkInPnts > checkOutpnts )
		printf "In Function GetGoodStuffFromValves -- mismatch in V1_ -- deleteing ONE in Time at %s\r", DateTime2Text( V1_InTime[ checkInPnts - 1] )
		DeletePoints checkInPnts -1, 1, V1_InTime
	endif
	
	// make V2or3 in times and accompanying v1 out times?
	Make/N=0/D/O V23_InTime, V23_OutTime
	Duplicate/O status_V2or3, dstatus;	Differentiate/METH=1 dstatus
	Duplicate/O dstatus, ddstatus;	Differentiate/METH=1 ddstatus
	count = numpnts( status_v2or3 )
	for( idex = 0; idex < count; idex += 1 )
		
			if( dstatus[idex] > 0 )
				// this is a valve on time
				AppendVal( V23_InTime, time_w[idex] )
			endif
			if( dstatus[idex] < 0 )
				AppendVal( V23_OutTime, time_w[idex] )
			endif
		
	endfor
	checkInPnts = numpnts( V23_InTime );	checkOutPnts = numpnts( V23_OutTime )
	if( checkInPnts > checkOutpnts )
		printf "In Function GetGoodStuffFromValves -- mismatch in V23_ -- deleteing ONE in Time at %s\r", DateTime2Text( V23_InTime[ checkInPnts - 1] )
		DeletePoints checkInPnts -1, 1, V23_InTime
	endif

	Variable valveBegin = Text2DateTime( "1/9/2012 17:09:41" )
	
	Variable bdex = BinarySearch( V23_InTime, valveBegin )
	if( bdex >= 0 )
		DeletePoints 0, bdex, V23_InTime, V23_OutTime
	endif
	
	bdex = BinarySearch( V2_InTime, valveBegin )
	if( bdex >= 0 )
		DeletePoints 0, bdex, V2_InTime, V2_OutTime
	endif
	
	bdex = BinarySearch( V1_InTime, valveBegin )
	if( bdex >= 0 )
		DeletePoints 0, bdex, V1_InTime, V1_OutTime
	endif
End

// -------------------------------------------------
// Kill any window that matches nameMatch
// nameMatch can include wildcard characters
// windows allowed are windows, tables and layouts. 


Function KillWindowsThatMatch(nameMatch)
	string nameMatch

	string cmd 
	string list = winList(nameMatch,";","WIN:"+num2str(1+2+4))
	variable i,count=0
		for(i=0;i<itemsinlist(list);i+=1)
			cmd =  "DoWindow/K "+ stringFromList(i, list)
			Execute cmd		
			count +=1	
		endfor
	print "Killed ",count,"windows matching",nameMatch
	

End

// takes a number like 1111 or 100111 and
// returns a variable representing a binary number.
// e.g 15 = 1111 or 39 = 100111

// note that the 0th bit is the right-most, and we read
// RIGHT to LEFT

Function binary2var(binary)
	variable binary
	binary=round(binary)
	string binaryStr
	
	sprintf binaryStr, "%.0f", binary
	variable var=0
	
	variable i=strlen(binaryStr)-1, thisBit=0, thisValue
	
	for(i=strlen(binaryStr)-1;i>=0;i-=1)
		thisValue = str2num(binaryStr[i])
		
		if(thisValue==1)
			// set bit
			var = var | 2^thisBit
		elseif(thisValue==0)
			// clear bit
			var = var & ~(2^thisBit)
		else
			return -1
		endif
		thisBit+=1
		
	endfor
	
	return var

End

Function var2binary(var)
	variable var
	variable binary
	
	variable i=0, thisValue
	string thisBitStr=""
	do
		if( (var & 2^i) !=0 )
			thisBitStr = "1"+thisBitStr
			// clear it
			var = var & ~(2^i)	
		else
			thisBitStr = "0"+thisBitStr
		endif
		i+=1
	while(var>0)
	
	binary = str2num(thisBitStr)
	return binary
end

Function CutTimeToTheHour(adatetime)
    Variable adatetime 
    
    Variable year, month, day, hour, minute, second
    String timestr
    
    timestr = DateTime2Text( adatetime )
    sscanf timestr, "%d/%d/%d %d:%d:%d", month, day, year, hour, minute, second
    sprintf timestr, "%d/%d/%d %d:%d:%d", month, day, year, hour, 0, 0
    
    return Text2DateTime( timestr )
end

Function/T FilterWaveListModTime( waveListStr, Start_modTime, Stop_modTime )
	String waveListStr
	Variable Start_modTime
	Variable Stop_modTime
	
	String returnList = "", wstr, winfo;
	Variable idex, count = ItemsInList( waveListStr ), wMod
	for( idex = 0; idex < count; idex += 1 )
		wstr = StringFromList( idex, waveListStr )
		Wave/Z w = $wstr
		
		if( WaveExists( w ) )
			winfo = WaveInfo( w , 0 );
			wMod = NumberByKey( "MODTIME", winfo );
			if( (wMod >= Start_modTime) & (wMod <= Stop_modTime) )
				// we will promote it
				returnList = returnList + wstr + ";"
			endif
		endif
		
	endfor
	
	return returnList
End