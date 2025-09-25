#pragma rtGlobals=1		// Use modern global access method.

// Revision 1.1 MAGN
// This is an updated version to work with the new Macro structure In Global Utils

// This procedure serves two purposes. First it is used to add the Spec. Plots submenu and its functions in
// the Macros menu. Second it contains the code for the Leak Rate function in the Spec. Plots submenu. All
// other functions under Spec. Plots submenu are coded in other procedure windows.

// The leak rate plot function is has been written to construct a standard formatted plot from the pressure
// data in memory (stc_Praw). If there is no pressure data in memory then the function allows the user to
// load some using the STR Files Loader. The function will abort if the user fails to load an STC file before
// continuing. 

// Once pressure data is available the function will construct a graph of the pressure data and embed a
// control panel. The control panel has Data Range and Fit Range sections, along with Reset, Full Scale,
// and Compute Leak Rate buttons. The Reset button will reset the graph back to the state it was in when
// created. The Full Scale button will autoscale the axes. The Compute Leak Rate button produces a
// standardized plot of the leak rate data. At execution the button does a linear fit of the pressure data within
// the selected fit range and duplicates the stc_Praw, and stc_time data within the selected data range. It
// then constructs a graph of the duplicated data, and places the fit line and the leak rate (fit slope) on it. The
// button will also cleanup any extra data (variables, strings, waves, etc.) that are no longer needed. It is up
// to the user to save the graph to an appropriate location.

// The data range and the fit range may be set using either the SetVariable boxes on the embedded panel or
// with cursors (A and B for the data range, C and D for the fit range). The cursors may be activated for both
// the data range and the fit range by selecting the Use Cursor check box in the respective section. The
// SetVariable boxes are still active if the cursors are selected and will move the cursors if adjusted. Both the
// data range cursors and the fit range cursors may be flipped. This means that cursor B may be placed
// before cursor A in which case the data range start point is at cursor B and the data range end point is at
// cursor A. Likewise for the fit range and cursors C and D. 

// The data range is not allowed to be outside of the stc_Praw data range, and the fit range is not allowed to
// be outside of the data range. This is to prevent the fit line from getting skewed when producing the leak
// rate graph. Therefore the code will not allow the fit range cursors to be placed outside of the data range
// cursors. If the user attempts this then the fit range cursor(s) will be moved to the data range cursor
// position; the data range cursors are dominant. The SetVariable boxes behave in a similar manner.

// 7/31/13 MAGN
// 4/05/2018 TIY - added sample and super ratio functions. versionning now handled in git.

//LRP Panel Initlization
Function InitLRPPanel()
	leak_rate_plot()
End

// Leak Rate function for producing a leak rate plot
Function leak_rate_plot()
	// Runs STR Files Loader and builds a continue window if there is no pressure data in memory
	if (waveexists(stc_Praw) == 0)
		setDataFolder root:;
		if(waveexists(stc_Praw)==0)		
			PauseUpdate; Silent 1
			NewPanel/N=Missing_data_panel /W=(431,56,831,146) as "Missing data"
			SetDrawLayer UserBack
			SetDrawEnv textxjust= 1,textyjust= 2
			DrawText 200,20,"Use STR_Panel to load pressure data then press continue"
			Button cont_button1, pos={175,50},size={50,20},title="Continue"
			Button cont_button1, proc=leak_buttons
			DoUpdate /W=Missing_data_panel
			zSTR_InitSTRPanel()
			PauseForUser Missing_data_panel, STR_Panel
			Dowindow/K STR_Panel
			Dowindow/K STC_stc_Graph		
		endif
		
		if (waveexists(stc_Praw) == 0)
			abort "No pressure data loaded"
		endif
	endif

	//Variable definition
	Variable/G data_start = 0
	Variable/G data_end = numpnts(stc_Praw)-1
	Variable/G fit_start = 0
	Variable/G fit_end = numpnts(stc_Praw)-1

	Variable ori_x, ori_y, mag_x, mag_y
	Variable mini_control, short_control, height, space
	Variable data_box_x, data_box_y, fit_box_x, fit_box_y, button_x, button_y
	Variable row_1, row_2,col_1, col_2
	
	ori_x = 5; ori_y = 5; mag_x = 450; mag_y = 400
	mini_control = 60; short_control = 150; height = 20; space = 5
	data_box_x = 5; data_box_y = 5; fit_box_x = mini_control*2+12*space; fit_box_y = 5; button_x = 355; button_y = 10
	row_1 = 15; row_2 = row_1+45; col_1 = 10; col_2 = col_1+mini_control+20

	//Graph and control setup
	PauseUpdate; Silent 1
	Display /N=stc_Praw_graph /W=(ori_x,ori_y,mag_x,mag_y) stc_Praw vs stc_time as "stc_Praw vs stc_time"
	ModifyGraph rgb=(0,0,65280)

	ControlBar 90
	GroupBox data_box, pos={data_box_x, data_box_y},size={mini_control*2+10*space, 80}, title="Data Range"
	GroupBox data_start_box, pos={data_box_x+col_1, data_box_y+row_1},size={mini_control+2*space, height+2*space+8}, title="Start"
	GroupBox data_end_box, pos={data_box_x+col_2, data_box_y+row_1},size={mini_control+2*space, height+2*space+8}, title="End"
	SetVariable data_start_disp, pos={data_box_x+col_1+space, data_box_y+row_1+16}, size={mini_control, height}, proc=leak_setvars, title=" "
	SetVariable data_start_disp, frame=1, value=data_start
	SetVariable data_end_disp, pos={data_box_x+col_2+space, data_box_y+row_1+16}, size={mini_control, height}, proc=leak_setvars,title=" "
	SetVariable data_end_disp, frame=1, value=data_end
	CheckBox data_csr, pos={data_box_x+col_1, data_box_y+row_2},size={mini_control, height},proc=leak_check, title="Use Cursors"
	Button zoom_data_range,pos={data_box_x+col_2+2*space, data_box_y+row_2-space},size={mini_control, height},proc=leak_buttons,title="Zoom"

	GroupBox fit_box, pos={fit_box_x, fit_box_y},size={mini_control*2+10*space, 80}, title="Fit Range"
	GroupBox fit_start_box, pos={fit_box_x+col_1, fit_box_y+row_1},size={mini_control+2*space, height+2*space+8}, title="Start"
	GroupBox fit_end_box, pos={fit_box_x+col_2, fit_box_y+row_1},size={mini_control+2*space, height+2*space+8}, title="End"
	SetVariable fit_start_disp, pos={fit_box_x+col_1+space, fit_box_y+row_1+16}, size={mini_control, height}, proc=leak_setvars, title=" "
	SetVariable fit_start_disp, frame=1, value=fit_start
	SetVariable fit_end_disp, pos={fit_box_x+col_2+space, fit_box_y+row_1+16}, size={mini_control, height}, proc=leak_setvars,title=" "
	SetVariable fit_end_disp, frame=1, value=fit_end
	CheckBox fit_csr, pos={fit_box_x+col_1, fit_box_y+row_2},size={mini_control, height},proc=leak_check, title="Use Cursors"
	Button zoom_fit_range,pos={fit_box_x+col_2+2*space, fit_box_y+row_2-space},size={mini_control, height},proc=leak_buttons,title="Zoom"

	Button reset,pos={button_x, button_y},size={short_control, height},proc=leak_buttons,title="Reset"
	Button full_scale,pos={button_x, button_y+height+space},size={short_control, height},proc=leak_buttons,title="Full Scale"
	Button calc_leak_rate, pos={button_x, button_y+2*(height+space)}, size={short_control, height}, proc=leak_buttons,title="Compute Leak Rate"
	
	SetWindow stc_Praw_graph, hook(testhook) = cursorhook
	DoUpdate

End

// This function operates the SetVariable boxes and updates the data range and fit range. It checks for and
// automatically fix errors with the data range and fit range and also updates the cursor placement if
// selected.
Function leak_setvars(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable
	NVAR data_start
	NVAR data_end
	NVAR fit_start
	NVAR fit_end
	
	Variable isA = strlen(csrinfo(A,"stc_Praw_graph"))
	Variable isB = strlen(csrinfo(B,"stc_Praw_graph"))
	Variable isC = strlen(csrinfo(C,"stc_Praw_graph"))
	Variable isD = strlen(csrinfo(D,"stc_Praw_graph"))

	// The SetVariable box controls
	if (cmpstr(ctrlName, "data_start_disp") == 0)
		if (fit_start < data_start)
			fit_start = data_start
		endif
		if (fit_start > fit_end)
			fit_end = fit_start
		endif
		if (data_start > data_end)
			data_start = data_end
			fit_start = data_end
			fit_end = data_end
		endif
	endif

	if (cmpstr(ctrlName, "data_end_disp") == 0)
		if (fit_end > data_end)
			fit_end = data_end
		endif
		if (fit_start > fit_end)
			fit_start = fit_end
		endif
		if (data_start>data_end)
			data_end = data_start
			fit_start = data_start
			fit_end = data_start
		endif
	endif

	if (cmpstr(ctrlName, "fit_start_disp") == 0)
		if (fit_start < data_start)
			fit_start = data_start
		endif
		if (fit_start > fit_end)
			fit_end = fit_start
		endif
		if (fit_end > data_end)
			fit_end = data_end
			fit_start = data_end
		endif
	endif

	if (cmpstr(ctrlName, "fit_end_disp") == 0)
		if (fit_end > data_end)
			fit_end = data_end
		endif
		if (fit_start > fit_end)
			fit_start = fit_end
		endif
		if (fit_start < data_start)
			fit_start = data_start
			fit_end = data_start
		endif
	endif

	// cursor placement
	ControlInfo data_csr
	if (V_value == 1)
		If (isA == 0 || isB == 0 || pcsr(A) <= pcsr(B))
			Cursor/P A, stc_Praw, data_start
			Cursor/P B, stc_Praw, data_end
		else
			Cursor/P B, stc_Praw, data_start
			Cursor/P A, stc_Praw, data_end
		endif
	endif
	ControlInfo fit_csr
	if (V_value == 1)
		If (isC == 0 || isD == 0 || pcsr(C) <= pcsr(D))
			Cursor/P C, stc_Praw, fit_start
			Cursor/P D, stc_Praw, fit_end
		else
			Cursor/P D, stc_Praw, fit_start
			Cursor/P C, stc_Praw, fit_end
		endif
	endif

End

// This function operates the check boxes.
Function leak_check(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked	// 1 if selected, 0 if not
	Variable isA = strlen(csrinfo(A,"stc_Praw_graph"))
	Variable isB = strlen(csrinfo(B,"stc_Praw_graph"))
	Variable isC = strlen(csrinfo(C,"stc_Praw_graph"))
	Variable isD = strlen(csrinfo(D,"stc_Praw_graph"))
	NVAR data_start
	NVAR data_end
	NVAR fit_start
	NVAR fit_end
	
	if (cmpstr(ctrlName, "data_csr") == 0)
		if (checked == 1)
			if (isA == 0)
				Cursor/P A, stc_Praw, data_start
			endif
			if (isB == 0)
				Cursor/P B, stc_Praw, data_end
			endif
		endif
		if (checked == 0)
			Cursor/K A
			Cursor/K B
		endif
	endif
	
	if (cmpstr(ctrlName, "fit_csr") == 0)
		if (checked == 1)
			if (isC == 0)
				Cursor/P C, stc_Praw, fit_start
			endif
			if (isD == 0)
				Cursor/P D, stc_Praw, fit_end
			endif
		endif
		if (checked == 0)
			Cursor/K C
			Cursor/K D
		endif
	endif
End

// This function operates the buttons.
Function leak_buttons(ctrlName) : ButtonControl
	String ctrlName
	Wave stc_time
	NVAR data_start
	NVAR data_end
	NVAR fit_start
	NVAR fit_end

	// continue button for loading data
	if (cmpstr( ctrlName, "cont_button1" ) == 0)
		DoWindow/K Missing_data_panel
	endif
	
	// zoom to data range
	if (cmpstr(ctrlName, "zoom_data_range") == 0)
		variable data_start_val = stc_time(data_start)
		variable data_end_val = stc_time(data_end)
		SetAxis /W=stc_Praw_graph bottom data_start_val,data_end_val
		SetAxis /A=2 /W=stc_Praw_graph left
		DoUpdate
	endif

	// zoom to fit range
	if (cmpstr(ctrlName, "zoom_fit_range") == 0)
		variable fit_start_val = stc_time(fit_start)
		variable fit_end_val = stc_time(fit_end)
		SetAxis /W=stc_Praw_graph bottom fit_start_val,fit_end_val
		SetAxis /A=2 /W=stc_Praw_graph left
		DoUpdate
	endif

	// resets window to defalt condition
	if (cmpstr(ctrlName, "reset") == 0)
		Cursor/K A
		Cursor/K B
		data_start = 0
		data_end = numpnts(stc_Praw)-1
		CheckBox data_csr, value = 0
		Cursor/K C
		Cursor/K D
		fit_start = 0
		fit_end = numpnts(stc_Praw)-1
		CheckBox fit_csr, value = 0
		SetAxis /A/W=stc_Praw_graph
		DoUpdate
	endif

	// autoscales axes
	if (cmpstr(ctrlName, "full_scale") == 0)
		SetAxis /A /W=stc_Praw_graph bottom
		SetAxis /A /W=stc_Praw_graph left
	endif

	// Produces leak rate plot based on data_range and fit_range
	if (cmpstr(ctrlName, "calc_leak_rate") == 0)
		CurveFit/NTHR=0 line stc_Praw[fit_start,fit_end] /X=stc_time /D 
		Duplicate/O/R=[data_start,data_end] stc_Praw lr_pres
		Duplicate/O/R=[data_start,data_end] stc_time lr_time
		PauseUpdate; Silent 1
		Dowindow/K stc_Praw_graph
		display /N=pres_graph lr_pres vs lr_time as "Leak_Rate"
		ModifyGraph rgb=(0,0,65280)
		Label bottom "Date and Time"
		Label  left "Pressure (Torr)"		
		AppendToGraph fit_stc_Praw
		ModifyGraph rgb(fit_stc_Praw)=(65280,0,0)
		WAVE W_coef
		WAVE W_sigma
		W_coef[1] *= 3600
		W_sigma[1] *= 3600
		Variable leak_rate =  W_coef[1]
		Variable lr_error = W_sigma[1]
		String line
//		sprintf line, "Leak Rate = %.3f ± %.2e Torr/h", W_coef[1], W_sigma[1]
		sprintf line, "Leak Rate = %.3f Torr/h", W_coef[1]
		TextBox /C /N=CF_lr_pres /A=LT /X=1 /Y=1 line 
		DoUpdate
		KillVariables/Z data_start, data_end, fit_start, fit_end
	endif

End

// This function executes upon a cursor movement. It checks for and automaticaly fixes data range and fit
// range errors that are encountered by moving the cusor.
Function CursorHook(s)
	Struct WMWinHookStruct &s
	Variable hookresult = 0
	NVAR data_start
	NVAR data_end
	NVAR fit_start
	NVAR fit_end
	Variable isA = strlen(csrinfo(A,"stc_Praw_graph"))
	Variable isB = strlen(csrinfo(B,"stc_Praw_graph"))
	Variable isC = strlen(csrinfo(C,"stc_Praw_graph"))
	Variable isD = strlen(csrinfo(D,"stc_Praw_graph"))
	
	switch (s.eventcode)
		case 7: // "cursormoved" eventcode

			if (cmpstr(s.cursorname, "A") == 0)	
				if (isA == 0) // A moved off plot
					//data_start = 0
					if (isB != 0) // B still present
						data_end = pcsr(B)
					endif
				elseif (isB == 0) // B was previously moved of of the graph
					data_start = s.pointnumber
					if (fit_start < data_start)
						fit_start = data_start
					endif
					if (fit_start > fit_end)
						fit_end = fit_start
					endif
				elseif (pcsr(A) <= pcsr(B)) // A is left B
					data_start = s.pointnumber
					data_end = pcsr(B)
					if (fit_start >= data_end && fit_end >= data_end) // A moved from right of B to left of B
						fit_start = data_start
						fit_end = data_end					
					else // A remained on left of B
						if (fit_start < data_start)
							fit_start = data_start
						endif
						if (fit_start > fit_end)
							fit_end = fit_start
						endif
					endif
				else // A is right B
					data_end = s.pointnumber
					data_start = pcsr(B)
					if (fit_start <= data_start && fit_end <= data_start) // A moved from left of B to right of B
						fit_start = data_start
						fit_end = data_end
					else // A remained on right of B
						if (fit_end > data_end)
							fit_end = data_end
						endif
						if (fit_start > fit_end)
							fit_start = fit_end
						endif
					endif
				endif
				// cursor placement
				ControlInfo fit_csr
				if (V_value == 1)
					If (isC == 0 || isD == 0 || pcsr(C) <= pcsr(D))
						Cursor/P C, stc_Praw, fit_start
						Cursor/P D, stc_Praw, fit_end
					else
						Cursor/P D, stc_Praw, fit_start
						Cursor/P C, stc_Praw, fit_end
					endif
				endif
			endif

			if (cmpstr(s.cursorname, "B") == 0)
				if (isB == 0) // B moved off plot
					//data_end = numpnts(stc_Praw)-1
					if (isA != 0) // A still present
						data_end = pcsr(A)
					endif
				elseif (isA == 0) // A was previously moved of of the graph
					data_end = s.pointnumber
					if (fit_end > data_end)
						fit_end = data_end
					endif
					if (fit_start > fit_end)
						fit_start = fit_end
					endif
				elseif (pcsr(A) <= pcsr(B))  // B is right A
					data_end = s.pointnumber
					data_start = pcsr(A)
					if (fit_start <= data_start && fit_end <= data_start) // B moved from left of A to right of A
						fit_start = data_start
						fit_end = data_end
					else // B remained on right of A
						if (fit_end > data_end)
							fit_end = data_end
						endif
						if (fit_start > fit_end)
							fit_start = fit_end
						endif
					endif
				else  // B is left A
					data_start = s.pointnumber
					data_end = pcsr(A)
					if (fit_start >= data_end && fit_end >= data_end) // B moved from right of A to left of A
						fit_start = data_start
						fit_end = data_end					
					else // B remained on left of A
						if (fit_start < data_start)
							fit_start = data_start
						endif
						if (fit_start > fit_end)
							fit_end = fit_start
						endif
					endif
				endif
				// cursor placement
				ControlInfo fit_csr
				if (V_value == 1)
					If (isC == 0 || isD == 0 || pcsr(C) <= pcsr(D))
						Cursor/P C, stc_Praw, fit_start
						Cursor/P D, stc_Praw, fit_end
					else
						Cursor/P D, stc_Praw, fit_start
						Cursor/P C, stc_Praw, fit_end
					endif
				endif
			endif

			if (cmpstr(s.cursorname, "C") == 0)	
				if (isC == 0) // C moved off plot
					//fit_start = data_start
					if (isD != 0) // D still present
						fit_end = pcsr(D)
					endif
				elseif (isD == 0) // D was previously moved of of the graph
					fit_start = s.pointnumber
				elseif (pcsr(C) <= pcsr(D)) // C is left D
					fit_start = s.pointnumber
					fit_end = pcsr(D)
					if (fit_start < data_start)
						fit_start = data_start
						Cursor/P C, stc_Praw, fit_start
					endif
				else // C is right D
					fit_end = s.pointnumber
					fit_start = pcsr(D)
					if (fit_end > data_end)
						fit_end = data_end
						Cursor/P C, stc_Praw, fit_end
					endif
				endif
			endif

			if (cmpstr(s.cursorname, "D") == 0)
				if (isD == 0) // D moved off plot
					//fit_end = data_end
					if (isC != 0) // C still present
						fit_start = pcsr(C)
					endif
				elseif (isC == 0) // C was previously moved of of the graph
					fit_end = s.pointnumber
				elseif (pcsr(C) <= pcsr(D)) // D is right C
					fit_end = s.pointnumber
					fit_start = pcsr(C)
					if (fit_end > data_end)
						fit_end = data_end
						Cursor/P D, stc_Praw, fit_end
					endif
				else // D is left C
					fit_start = s.pointnumber
					fit_end = pcsr(C)
					if (fit_start < data_start)
						fit_start = data_start
						Cursor/P D, stc_Praw, fit_start
					endif
				endif
			endif

	endswitch

	return hookresult

End


//--------------------------------------------------------------------------------------
// Function samples_average2StartStops(starts, stops, datatime, data, [name])
//--------------------------------------------------------------------------------------
// This function averages data between the times specified by "starts" and "stops"
// for sample usage, see samples_delVsRef
Function  samples_average2StartStops(starts, stops, datatime, data, [name])
	wave starts, stops, data
	wave/D datatime
	string name
	if(paramisdefault(name))
		name = nameofwave(data)
	endif
	
	String avgName =cleanupname("avg_"+name,0)
	String timeName = cleanupname("avgRtime_"+name,0)
	make/O/D/n=(numpnts(starts)) $avgName, $timeName
	wave avgtime = $timeName
	wave avg = $(avgName)
	avg = nan
	avgTime = nan
	if(numpnts(starts)!=numpnts(stops))
		print "unequal wave lengths for ",nameofwave(starts),"and",nameofwave(stops)
		return 0
	endif
	
	
	variable i, thisAvg, bdex, edex
	variable/D thisTime
	for( i=0;i<numpnts(starts);i+=1)
		bdex = binarysearch(datatime, starts[i])
		edex = binarysearch(datatime, stops[i])
		
		Wavestats/Q/R=[bdex,edex] datatime; thisTime=V_avg
		wavestats/Q/R=[bdex,edex] data; thisAvg = V_avg
		
		avgTime[i] = thisTime
		avg[i] = thisAvg
	endfor
	
	return 1

end

//--------------------------------------------------------------------------------------
// Function samples_DelVsRef(dataTime, dataAvg, refTime, refDataAvg, [BeforeAfterBoth, name])
//--------------------------------------------------------------------------------------
// This function calculates a super ratio, in del space.
// The super ratio is defined as follows:
// 
//		Super Ratio [per mil] = ( Rsamp / Rref - 1) * 1000
// 
// where R = conc minor Isotope / conc major Isotope
// 
//	this is equivalent to the following equation, for a TILDAS CO2 isotope instrument 
//
// 	Super Ratio [per mil] = { (i636_samp/i626_samp) / (i636_ref/i626_ref) -1 } * 1000
//
// in the usual use of this function, you need to give it ratios (not in del units)
//--------------------------------------------------------------------------------------
// Parameter			Description
// dataTime			sample time wave, usually called avgRtime_...
// dataAvg 			sample data. This should be a direct ratio, not a del (e.g. Rsamp), 
//									usually calculated with samples_average2startStops
// refTime			reference time wave, usually called avgRtime_...
// refDataAvg 		reference data. This is a direct ratio,  not a del (e.g. Rref),
//									 similarly calculated as Rsamp.
// beforeAfterBoth		"before" is the default value.
//                    determines which reference ratio to use when taking the super ratio
// name               "del_" plus the name of the dataAvg wave is the default value
//                    any name can be specified.
//--------------------------------------------------------------------------------------
// EXAMPLES
// 
// for sample use with TILDAS data following the Hitran convention, 
// for a CO2 isotope instrument with loaded data like i626
//	duplicate/o i626, R636vs626
//	R636vs626 = i636/i626
// >>> use mask maker to produce sets of even and odd start/stop times
// samples_average2startstops(str_minutemask_start_time, str_minutemask_stop_time, str_source_rtime, R636vs626, name="R636vs626_a")
// samples_average2startstops(str_otherminutemask_start_time, str_otherminutemask_stop_time, str_source_rtime, R636vs626, name="R636vs626_b")
// samples_delVsRef(avgRtime_R636vs626_b, avg_R636vs626_b,  avgRtime_R636vs626_a, avg_R636vs626_a, name="SR_C13")
// >>> now do an allan plot of SR_C13 vs avgRtime_636vs626_a
//----------------------------------------------------------------------------------------
// OUTPUT
// 
// A super ratio, in del space, units of per mil
// called, by default, del_ + the name of the data wave.
// if a "name" is specified, it will be called by that. 
//
// it can be plotted versus one of the original time waves, e.g. dataTime

Function samples_DelVsRef(dataTime, dataAvg, refTime, refDataAvg, [BeforeAfterBoth, name])
	wave/D dataTime, refTime
	wave dataavg, refDataAvg
	string name
	string beforeAfterBoth
	
	if(paramisdefault(beforeAfterBoth))
		beforeAfterBoth = "before"
	endif
	
	if(paramisdefault(name))
		name = "del_"+nameOfWave(dataAvg)
	endif
	variable i, refdex, datadex
	duplicate/o dataAvg $name
	wave delVsRef = $name
	
	
	strswitch (beforeAfterBoth)
		case "before": // before
		
			for(i=0;i<(numpnts(delVsRef)); i+=1)
				refdex = binarysearch(refTime, dataTime[i])
				
				if(refdex==-1)
					// data comes before a reference
					delVsRef[i]=NaN
				elseif(refdex==-2)
					// missing gobs of data at the end
					delVsRef[i]=NaN
				else
					// normal situation
					
					delVsRef[i]= (dataAvg[i]/refDataAvg[refdex] -1) * 1000
					
				endif
			endfor
		
		break
		
		case "after": // after
			for(i=0;i<(numpnts(delVsRef)); i+=1)
				datadex = binarysearch(dataTime, refTime[i])
				
				if(datadex==-1)
					// data comes before a reference
					delVsRef[i]=NaN
					
				elseif(datadex==-2)
					// missing gobs of data at the end
					delVsRef[i]=NaN
				else
					// normal situation
					
					delVsRef[i]= (dataAvg[datadex]/refDataAvg[i] -1) * 1000
					
				endif
			endfor
		
		break
		
		case "both": // before and after
		
			for(i=0;i<(numpnts(delVsRef)); i+=1)
				refdex = binarysearch(refTime, dataTime[i])
				variable refdex2 = refdex+1
				
				if(refdex==-1||refdex2==-1)
					// data comes before a reference
					delVsRef[i]=NaN
				elseif(refdex==-2||refdex2==-2)
					// missing gobs of data at the end
					delVsRef[i]=NaN
				else
					// normal situation
					Variable thisRef = interp(dataTime[i], refTime, refDataAvg)
					
					delVsRef[i]= (dataAvg[i]/thisRef -1) * 1000
					
				endif
			endfor
		
		
		break
	endswitch
	
end

// IRMS performance metrics use standard deviations (sigma) of del values. 
// This is totally analogous to Allan plots.
Function sample_IRMSstylePerformance(replicates, deltime, del, [startTime, endTime])
	variable/D startTime, endtime
	variable replicates
	wave del; wave/D delTime
	
	if(paramisdefault(startTime))
		startTime=deltime[0]
	endif
	if(paramisdefault(endTime))
		endTime = deltime[numpnts(deltime)-1]
	endif
	
	string name = cleanupname("sigma_"+nameofwave(del),0)
	string avgName = cleanupname("avg"+num2str(replicates)+"rep_"+nameofwave(del),0)
	string sameAvg = cleanupname("avg_"+nameofwave(del),0)
	string timename = cleanupname("sigmaRtime_"+nameofwave(del),0)
	make/o/n=0 $(name)
	make/o/n=0 $(avgName)
	make/D/o/n=0 $(timeName)
	wave sigmaDel = $name
	wave avgDel = $avgName
	wave sigmaTime = $timeName
	
	variable i=binarysearch(deltime, startTime)
	if(i==-1)
		i=0
	elseif(i==-2)
		print "error with start time\r", datetime2text(startTime), " > ", datetime2text(deltime[0])
		return 0
	endif
	for(i=binarysearch(deltime, startTime); i< numpnts(del)-replicates; i+= replicates)
		Wavestats/Q/R=[i, i+replicates-1] del; appendVal( sigmaDel, v_sdev); appendVal( avgDel, V_avg)
		wavestats/Q/R=[i,i+replicates-1] deltime; Appendval(sigmaTime, v_avg)
		
	endfor
	duplicate/o avgDel, $(sameAvg)
	
end

Function InitSPTR()
	// Runs Spectral Files Loader and builds a continue window if there is no spectral data in memory
	setDataFolder root:;
	if (waveexists(spectrum) == 0 || waveexists(L0_freq) == 0)
		PauseUpdate; Silent 1
		NewPanel/N=Missing_data_panel /W=(525,56,931,146) as "Missing data"
		SetDrawLayer UserBack
		SetDrawEnv textxjust= 1,textyjust= 2
		DrawText 200,20,"Use Load_Browse_SPE_Panel to load spectral data then press continue"
		Button cont_button1, pos={175,50},size={50,20},title="Continue"
		Button cont_button1, proc=SPTR_buttons
		DoUpdate /W=Missing_data_panel
		zSPE2_DrawPanel()
		PauseForUser Missing_data_panel, Load_Browse_SPE_Panel
		Dowindow/K Load_Browse_SPE_Panel
	endif
	
	if (waveexists(spectrum) == 0 || waveexists(L0_freq) == 0)
		abort "No spectral data was loaded"
	endif

	SPTR5mod2(spectrum, L0_freq)
End

Function SPTR_buttons(ctrlName) : ButtonControl
	String ctrlName

	// continue button for loading data
	if (cmpstr( ctrlName, "cont_button1" ) == 0)
		DoWindow/K Missing_data_panel
	endif
end

Function SPTR5mod2(Spec_Array, Freq_scale_init, [Et_len])

wave Spec_Array, Freq_scale_init
variable Et_len

// SPTR = similar point tuning rate.  
//	This program takes an array of etalon spectra and calculates a tuning rate and frequency scale based on the point differences
// 	between a set of similar points in the spectra: max and mins and specified levels in normalized spectra, both rising and falling.
//	It assumes that the array has been loaded with "Specarrayload", so that initial spectrum waves are available.
//	Edit variables below to setup the program.
//	Specify the level differences and number of levels below.  Avoid getting too close to +/-1, as there may be under-sampling.
//	Specify the sections of the spectrum to use, actions to perform, and parameters for processing.
//	Optional actions to perform include zero subtraction and normalizing by an average of spectra without the etalon.
//	Final outputs are TR_avg and Mod_Freq.
//	For inclusion in a Wintel spectrum, edit: L0_spec, L0_fit, L0_bkgn, L0_FM, Mod_Freq, then save a table copy as tab-delimited text.
//	Use a text editor to copy the spectral columns into a wintel spectrum.
//	Version 14/1/3, so far just single-laser.

SetDataFolder root:
NewDataFolder /O /S SPTR_Folder
variable WL_um, FSR, Ge_index, Lenspec_x, Lenspec_y, doPLots, MinSep, FitReplace, Presmooth
variable Nx_EtSpec, Ny_Etspec, Starty_Etspec, Endy_Etspec, ip, NanLev_ddt, NanLev_ddp, Normtype, NANType
variable PVarrayNormType, LevXNo, SPdimOld, SPdimNew, StartPX, EndPx, N1, N2, ilev, dlev, Nlev, Leveli, NSpecAn
variable Nsmooth, FracSmooth, FracProject, NProject, icount, MinPt, PR1, PR2, doZero, doNorm
variable PJumpmin, Pjumpmax, Ymatch_rng, iq, ylast, yi, edgei, SP_sdev_lim,  ddpSP_sdev_lim, NP_NoNans, MaxScale, SrchMax
WAVE L0_FM = Root:LoadSPE_II:FrameColumn_4
Lenspec_x= dimsize(Spec_Array, 0) ;  Lenspec_y= dimsize(Spec_Array, 1)


//  ----------------------------------edit variables here ---------------------------------------------------------------------------------

//------------ Parameters for optional actions ----------------------------
doZero = 1 												// if = 1, do zero offset calculation on the full array
doNorm = 1 												// if = 1, normalize etalon spectra by average spectrum without etalon
doPlots = 1 												// if = 1, creates plots of output
Nsmooth = 100  											// smooth points for Trinterp

//------- define etalon parameters and calculate FSR ----------------------

if( ParamIsDefault(Et_len) )		
	Et_len = 2											// etalon length, inches
endif
NVAR F_freq = root:LoadSPE_II:SPE_Fingerprint1   // fingerprint frequency, cm-1
WL_um = 1e4/F_freq										// fingerprint wavlength um
Ge_index = 9.28156 + (6.7288*WL_um^2)/(WL_um^2 - 0.44105) + (0.21307*WL_um^2)/(WL_um^2 - 3870.1)
Ge_index = sqrt(Ge_index)
FSR= 1/(2*Ge_index*2.54*Et_Len)
Print " Estimated etalon free spectral range at ", F_freq, " cm-1 :", FSR

//----------- Define spectral array sections -------------------------

//Etalon array processed range 
Starty_Etspec = 160					//defined based on ECL script
Endy_Etspec = Lenspec_y - 1

//SPTR search jump range
duplicate/O Freq_scale_init ddpFreq_scale_init
differentiate ddpFreq_scale_init
Make/O/N=(Lenspec_x) Periods
Periods=FSR/ddpFreq_scale_init
wavestats/Q Periods
variable minTR_loc
minTR_loc=V_maxRowLoc
Pjumpmax= trunc(1.1*V_max)
PJumpmin = 6

//Etalon spectrum dimention
findvalue /V=22 L0_FM; N1 = V_value	            
findvalue /V=22 /S=(N1+1) L0_FM; Nx_Etspec = V_value	// X length of normalized etalon spectrum to generate
Ny_Etspec = Endy_Etspec - Starty_Etspec + 1				// Y length of normalized etalon spectrum to generate

StartPx = 1				// Start point for similar point search (first N fitmarker)
EndPx = Nx_Etspec		// End for similar point search (second N fitmarker)

//Print
Print "Input spec array dimensions:", Lenspec_x, Lenspec_y
Print "Output etalon array dimensions:", Nx_Etspec, Ny_Etspec, " with start input array at y=", Starty_Etspec
Print "Point range for TR estimation:", StartPx, EndPx
Print "Level match range:", Ymatch_rng, "  P-search Range", PJumpmin, Pjumpmax

//Print " dLevel & Nlevels:", dlev, Nlev, " Fraction of points for init smooth:", FracSmooth, "Fraction of early pts for projection to zero:", FracProject
//Print "  Smooth averager 1-pt TR by:", Nsmooth2

//-------------- Other SPTR5 Parameters -----------------------------------------------------------------
Ymatch_rng = 0.8
SP_sdev_lim = 2.
ddpSP_sdev_lim = 4

//-------------- zero subtraction ---------------------------------------
if (doZero==1)
	Variable Zp1, Zp2    // specify zero offset ranges
	findvalue /V=3 L0_FM; Zp1 = V_value
	findvalue /V=3 /S=(Zp1 + 1) L0_FM; Zp2 = V_value
	Print "Doing zero subtraction, with zero range:", Zp1, Zp2
	make/O/N=(Lenspec_y) Zoffset
	Make/O/N=(Lenspec_x) Spec_Rowi

	ip=0
	do
		Spec_Rowi[] = Spec_Array[p][ip]
		Wavestats/Q/R = [(Zp1), (Zp2)] Spec_Rowi
		Zoffset[ip] = V_avg
	ip += 1
	while (ip < Lenspec_y) 

	Spec_Array[][] = Spec_Array[p][q] - Zoffset[q]

endif

//------------- make processed etalon array ------------------------
make/O/N=((Nx_Etspec), (Ny_Etspec)) EtSpec
EtSpec[][] = Spec_Array[p][(q+ Starty_Etspec)]
EtSpec[0][] = 2* EtSpec[1][q] - EtSpec[2][q]  //   replace first column, which is sometimes zero.

//------------- Normalize etalon spectrum by average spectrum without etalon ----------------------
if (doNorm==1)
		Variable Qnorm1 = 0, Qnorm2 = 99   		// specify vertical point [q] range for average of spectra without etalon. defined based on ECL script.
		Print "Doing etalon spectrum normalization with spectrum averaged over q-range:" , Qnorm1, Qnorm2
		Make/O/N = (Nx_Etspec)  Avg_Spec
		Make/O/N = (Qnorm2 - Qnorm1 + 1)  Spec_Coli
		ip = StartPx
		do
			Spec_Coli[] = Spec_Array[ip][p+ Qnorm1]
			Wavestats/Q Spec_Coli
			Avg_Spec[ip] = V_avg
		ip += 1
		while (ip < EndPx) 

	Avg_Spec[0, (StartPx-1)] = Avg_Spec[(StartPx)]
	Avg_Spec[(EndPx), (Nx_Etspec)] = Avg_Spec[(EndPx-1)]
	EtSpec[][] = EtSpec[p][q]/Avg_Spec[p]

endif

//------------ Pre-norm with smoothed s'dev array --------------------------------------------
duplicate/O EtSpec SDEV
smooth/dim=0 (Nx_Etspec), SDEV
smooth/dim=1 (Ny_Etspec), SDEV
EtSpec = EtSpec - SDEV
SDEV = EtSpec^2
smooth/dim=0 (Nx_Etspec), SDEV
smooth/dim=1 (Ny_Etspec), SDEV
SDEV = sqrt(2*SDEV)
EtSpec = EtSpec/SDEV

//-----------  Norm Et-Spec for range  -1 to +1 based on row-stats  -------------------
Make/O/N = (Ny_Etspec) Max_Wave, Min_Wave
Make/O/N = (Nx_Etspec) Spec_Rowi

ip=0
do
Spec_Rowi[] = EtSpec[p][ip]
Wavestats/Q Spec_Rowi
Max_Wave[ip] = V_max
Min_Wave[ip] = V_min

ip += 1
while (ip < Ny_Etspec) 

EtSpec[][] = (EtSpec[p][q] - (Max_Wave[q] + Min_Wave[q])/2) / ((Max_Wave[q] - Min_Wave[q])/2)  // project to zero.

//smooth/dim=1 (Presmooth), EtSpec

//-----------  Norm Et-Spec for range  -1 to +1 based on column-stats  -------------------
Redimension/N = (Nx_Etspec) Max_Wave, Min_Wave
Redimension/N = (Ny_Etspec) Spec_Rowi

ip=StartPx
do
Spec_Rowi[] = EtSpec[ip][p]
Wavestats/Q Spec_Rowi
Max_Wave[ip] = V_max
Min_Wave[ip] = V_min

ip+=1
while (ip < Nx_Etspec) 

EtSpec[][] = (EtSpec[p][q] - (Max_Wave[p] + Min_Wave[p])/2) / ((Max_Wave[p] - Min_Wave[p])/2)  // project to zero.

//smooth/dim=1 (Presmooth), EtSpec

//--------------- Process Etalon Array ----------------------------------

// --------------- continuous similar point array ---------------------
duplicate/O EtSpec SP_Array
Redimension/N = (Nx_Etspec) Spec_Rowi
SP_Array=nan
iq = 0
do
	
	Spec_Rowi[] = EtSpec[p][iq]
	ylast = Spec_Rowi[0]
	ip = 1
	do
	yi = Spec_Rowi[ip] ;  ylast = Spec_Rowi[ip-1]
	
	edgei = 1
	if (yi < ylast) 
		edgei=2
	endif
	
	SrchMax = ip + PJumpmax
	if (SrchMax > EndPx)
		SrchMax = EndPx + 5
	endif
	
	If (abs(yi) < Ymatch_rng)
		Findlevel /Edge=(edgei)/P/Q/R=[ (ip+PJumpmin), (SrchMax) ] Spec_Rowi, yi
	endif

	if (V_flag == 0)	// found level
		SP_Array[(ip)][(iq)] = V_Levelx - ip
	endif
	V_flag = 1

	ip += 1
	while (ip < Nx_Etspec)
iq += 1
while (iq < Ny_Etspec)
//--------------------------------------------------------------------------------------

//-------------- SP_Array outlier filter -------------------------
Make/O/N=(Nx_Etspec)  Avg_SP, Sdev_SP
Make/O/N=(Ny_Etspec)  Spec_Coli
duplicate/O Etspec NaNer
NaNer = 1

ip = 0
do
	Spec_Coli[] = SP_Array[(ip)][p]
	wavestats/Q Spec_Coli
	Avg_SP[ip] = V_Avg
	Sdev_SP[ip] = V_sdev
ip += 1
while (ip < Nx_Etspec)

NaNer[][] = sqrt(sign(SP_sdev_lim - abs((SP_Array[p][q] - Avg_SP[p])/Sdev_SP[p])))
SP_Array[][] = SP_Array[p][q]*NaNer[p][q]

ip = 0	// re-do stats.
do
	Spec_Coli[] = SP_Array[(ip)][p]
	wavestats/Q Spec_Coli
	Avg_SP[ip] = V_Avg
	Sdev_SP[ip] = V_sdev
ip += 1
while (ip < Nx_Etspec)//
//----------------------new 1/31/2019: interpolate --------------
//
Make/O/N= (Nx_Etspec) Scalex, SP_Rowi, SP_Rowi_denan, SP_Row_interp, SP_Rowi_ps, SP_Rowi_ps_denan
Scalex[]=p
duplicate/O SP_Array SP_Array_Interp
ip=0
do
SP_Rowi[]= SP_Array[p][ip]
SP_Rowi_ps[]= Scalex[p]*SP_Rowi[p]/SP_Rowi[p]
specPlots_NANremover(SP_Rowi, SP_Rowi_denan)
specPlots_NANremover(SP_Rowi_ps, SP_Rowi_ps_denan)
SP_Row_interp=interp(Scalex,  SP_Rowi_Ps_denan, SP_rowi_denan)
SP_Array_interp[][ip]= SP_Row_interp[p]

ip+=1
while (ip<Ny_Etspec)//
//-------------------- ddpSP Array ---------------------------------------------
duplicate/O SP_Array_interp ddpSP_Array
differentiate/dim=0 ddpSP_Array
Make/O/N=(Nx_Etspec)  Avg_ddpSP, Sdev_ddpSP

ip=0	// do stats.
do
	Spec_Coli[]= ddpSP_Array[(ip)][p]
	wavestats/Q Spec_Coli
	Avg_ddpSP[ip]= V_Avg
	Sdev_ddpSP[ip]= V_sdev
ip+=1
while (ip<Nx_Etspec)

//NaNer[][]= sqrt(sign(  ddpSP_sdev_lim - abs( (ddpSP_Array[p][q] - Avg_ddpSP[p])/Sdev_ddpSP[p] )  ))
//ddpSP_Array[][]= ddpSP_Array[p][q]*NaNer[p][q]

ip=0	// re-do stats.
do
	Spec_Coli[]= ddpSP_Array[(ip)][p]
	wavestats/Q Spec_Coli
	Avg_ddpSP[ip]= V_Avg
	Sdev_ddpSP[ip]= V_sdev
ip+=1
while (ip<Nx_Etspec)

//----------------- TR Array ---------------------------------------------------
duplicate/O SP_Array_interp TR_Array
Make/O/N= (Lenspec_x) TR_Avg, TR_scale
TR_scale[]=p

TR_Array[][]= FSR/( SP_Array_interp[p][q] - 0.5*SP_Array_interp[p][q]*ddpSP_Array[p][q] )

ip=0	// re-do stats.
do
	Spec_Coli[]= TR_Array[(ip)][p]
	wavestats/Q Spec_Coli
	TR_Avg[ip]= V_Avg
	
ip+=1
while (ip<Nx_Etspec)

 //-------------- Make avg freq-scale  -------------------------------------
 
 	//-------------- remove NAN's, regularize avg. ----------------------
 	duplicate/O TR_avg, TR_avg_NoNans
 	duplicate/O TR_scale, TR_scale_NoNans
 	
 	ip=0; NP_NoNans = 0
 do
 	
 	if(numtype( TR_avg[ip] ) <2)
 		TR_avg_NoNans[(NP_NoNans)]= TR_avg[ip]
 		TR_scale_NoNans[(NP_NoNans)]=  TR_scale[ip]
 		NP_NoNans=NP_NoNans+1
 	endif
 ip+=1
while (ip<Nx_Etspec)
Redimension/N=( NP_NoNans) TR_avg_NoNans, TR_scale_NoNans

wavestats/Q TR_scale_NoNans
MaxScale= V_Max +1

Make/O /N= ( MaxScale ) TRinterp, TRscaleInterp
TRscaleInterp[]=p
TRinterp = interp( TRscaleInterp, TR_scale_NoNans, TR_avg_NoNans)

 Redimension/N=( Lenspec_x) 	TRinterp
 TRinterp[ (MaxScale ) , ( Lenspec_x -1)] = TRinterp[(MaxScale-1 ) ]
 
 if (Nsmooth>0 )
	 smooth (Nsmooth), TRinterp
 endif
 
 Make/O/N= (Lenspec_x) Mod_Freq
Integrate/METH=1 TRinterp/D=Mod_Freq
 
 if (doPlots ==1) //-------------------------------------------------------------------------
 
display Freq_scale_init, Mod_Freq
modifygraph mirror=1
label left "Frequency Scale, cm-1" ; label bottom "Channel"
String name = NameOfWave(Freq_scale_init)
ModifyGraph lsize($name)=2,rgb($name)=(0,52224,52224),rgb(Mod_Freq)=(0,0,0)
Legend/C/N=text0/A=LT

display ddpFreq_scale_init
appendtograph TRinterp
modifygraph mirror=1
label left "Tuning Rate, cm-1/ch" ; label bottom "Channel"
ModifyGraph lsize(ddpFreq_scale_init)=3,rgb(ddpFreq_scale_init)=(44032,29440,58880);DelayUpdate
ModifyGraph lsize(TRinterp)=1.5,rgb(TRinterp)=(0,49664, 0)
Legend/C/N=text0/A=LT
 
endif //---------------------------------------------------------------------------------------

//Save modified SPE
SPE2_InjectFiveColumns2Frame(root:SPTR_Folder:Mod_freq, 5, root:LoadSPE_UI:LoadSPE_Frame)
SVAR Path = root:LoadSPE_UI:Path2FIles
SVAR LoadMSG = root:LoadSPE_UI:LoadMSG
string filename = LoadMSG
variable a = strsearch(filename,".spe",0,2)
filename = filename[0,a-4]
a = strsearch(filename," ",inf,3)
filename[0,a] = ""
WriteTextWave2File(root:LoadSPE_UI:LoadSPE_Frame, path, filename + "ITR.spe" )
SetDataFolder root:

end

Function specPlots_NANremover(wavein, waveout)
wave Wavein, waveout
variable npin, ip, npout
npin= numpnts(wavein)
redimension/N=(npin) waveout
duplicate/O wavein dummy

ip=0; npout=0
do

	if (numtype( dummy[ip]) <2 )
		waveout[npout] =  dummy[ip]
		npout= npout+1
	endif
		
ip+=1
while(ip<npin)

redimension/N=(npout) waveout
print "  Input points=", npin, "  Output points without nan's=", npout
killwaves dummy
end

