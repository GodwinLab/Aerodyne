#pragma rtGlobals=1		// Use modern global access method.
//Allan variance function for 1-D wave 
// The control panel is jiggered to make Allan Variance Plots for TDL stream files
// 10/2000 Scott

// The Macro invokes the following two routines and quits
// AllanPanel_Init creates a data folder and some global variables
// AllanPanel_make creates the graph which 
//  serves as the operators interface to the Allan Variance Functions
	
Function Allan_Variance_Panel()
	AllanPanel_Init()
	AllanPanel_Make()

End // Allan_Variance_Panel
	
Function AllanPanel_Init()
	
// Function makes and sets current data folder Allan_Var_Folder

	SetDataFolder root:
	NewDataFolder /O /S Allan_Var_Folder
	
	String /G candidate_waves
	Variable /G points_in_wave
	Variable /G using_input_points
	Variable /G using_output_points
	Variable /G dX_time
	String /G TDL_File_Note
	String /G Generic_Note
	String/G Candidate_time
	Variable /G range_flag
	
	Variable /G avar_compute_flag
	Variable /G avar_save_flag
	Variable /G user_dX_flag
	Variable /G user_OD
	Variable /G user_MR
	
	Variable/G chk_override_auto_Dt = 0
	Variable/G auto_Dt = NAN
	Variable/G override_Dt = 1
	
	Make/O/D /N=5000 in_data, in_time
	Make/O/D /N=16 avar_x, avar_y, avar_white, avar_white_plus, avar_white_minus
	////////////////////////////////////////////////////////////////////////////	
	in_data = 100 + enoise(1) + 1 * sin(2* Pi *p / numpnts( in_data ) )
	in_time = datetime - 2500 + p
	SetScale/P y, 0, 0, "dat", in_time
	dX_time = 1 // assumes you are likely to have 1 second data
	user_OD=NaN // this needs to be manually input
	user_MR=nan
	TDL_File_Note = "data from tdl file"
	Generic_Note = ""
	range_flag = 0; avar_compute_flag = 0; avar_save_flag = 0; user_dX_flag = 0
	

End // AllanPanel_Init

Function AllanPanel_Make()

	Variable row_num, col_1, col_2, col_3, short_control, wide_control, height, bodwid = 125
	Variable ori_x, ori_y, mag_x, mag_y
	Variable multiple = 25 // this is the jump in pixels per control panel 'line'.
		
	////////// teach this function about contents of Allan_Var_Folder (chud)
	SVAR candidate_waves=root:Allan_Var_Folder:candidate_waves; NVAR points_in_wave=root:Allan_Var_Folder:points_in_wave
	SVAR candidate_time=root:Allan_Var_Folder:candidate_time
	NVAR using_input_points=root:Allan_Var_Folder:using_input_points; NVAR using_output_points=root:Allan_Var_Folder:using_output_points
	NVAR dX_time=root:Allan_Var_Folder:dX_time; SVAR TDL_File_Note=root:Allan_Var_Folder:TDL_File_Note
	SVAR Generic_Note=root:Allan_Var_Folder:Generic_Note; NVAR range_flag=root:Allan_Var_Folder:range_flag
	NVAR override_Dt=root:Allan_Var_Folder:override_Dt; 
	NVAR auto_Dt=root:Allan_Var_Folder:auto_Dt; 
	NVAR chk_override_auto_Dt=root:Allan_Var_Folder:chk_override_auto_Dt

	NVAR avar_compute_flag=root:Allan_Var_Folder:avar_compute_flag; NVAR avar_save_flag=root:Allan_Var_Folder:avar_save_flag; NVAR user_dX_flag=root:Allan_Var_Folder:user_dX_flag
	NVAR user_OD = root:Allan_Var_Folder:user_OD
	NVAR user_MR = root:Allan_Var_Folder:user_MR
	WAVE in_data=root:Allan_Var_Folder:in_data; WAVE avar_x=root:Allan_Var_Folder:avar_x
	WAVE avar_y=root:Allan_Var_Folder:avar_y; WAVE avar_white=root:Allan_Var_Folder:avar_white
	WAVE avar_white_plus=root:Allan_Var_Folder:avar_white_plus; WAVE avar_white_minus=root:Allan_Var_Folder:avar_white_minus
	//////// end chud
	
	ori_x = 5; ori_y = 5; mag_x = 450; mag_y = 400
	short_control = 150; wide_control = 300; height = 21
	row_num = 0; col_1 = 1; col_2 = short_control + 5; col_3 = wide_control + 10
	
	DoWindow /K Allan_Werle_Var_Calc_Graph
	Display/K=1/W=(ori_x,ori_y,mag_x,mag_y) in_data vs in_time
	ModifyGraph rgb=(0,0,65280)
	DoWindow /C Allan_Werle_Var_Calc_Graph
	ControlBar 6 * multiple
		
	PopupMenu ReferencePop,pos={col_1,row_num*multiple},size={wide_control,height},title="Data Stream Wave"
	PopupMenu ReferencePop,mode=4,popvalue="in_data",value= #"WaveList(\"*\", \";\", \"\")"//, bodywidth = bodwid
	PopupMenu ReferencePop proc=Allan_PopMenuProc
	
//	SetVariable auto_dt, pos={col_2, row_num*multiple}, size={short_control, height}, title="delta t"
//	SetVariable auto_dt, variable=root:allan_var_folder:auto_Dt, noedit=1, limits={0,inf,0}
	
	// not useful to display this.
	//ValDisplay in_points,pos={col_3,row_num*multiple},size={short_control, height},title="In points"
	//ValDisplay in_points,frame=0,value= #"root:Allan_Var_Folder:using_input_points"
	row_num += 1

//	CheckBox override_ck, pos={col_2, row_num*multiple}, size={short_control, height}, title="Override dtime"
//	CheckBox override_ck, variable=root:ALLan_var_folder:chk_override_auto_dt
	
	
	//candidate_time
	PopupMenu ReferenceTimePop,pos={col_1,row_num*multiple},size={wide_control,height},title="Time Wave"
	PopupMenu ReferenceTimePop,mode=4,popvalue="in_time",value= Allan_PopTimes()//, bodywidth = bodwid
	PopupMenu ReferenceTimePop proc=Allan_PopMenuProc
	

	Button PreAverageGap_AVAR, pos={col_3, row_num*multiple}, size={short_control, height}, proc=Allan_Buttons, title="PreAverage Cluster"
	Button PreAverageGap_AVAR, help={"Use this to create averaged data between large nan gaps"}

	
	row_num += 1
	PopupMenu RangePop,pos={col_1,row_num*multiple},size={short_control, height},title="Range"
	PopupMenu RangePop,popvalue="Cursors",value= "All Data;Cursors", mode=2
	PopupMenu RangePop proc=Allan_PopMenuProc
	
	// not useful to display this
	//ValDisplay out_points,pos={col_2*0.75,row_num*multiple},size={short_control*0.6, height},title="Output points"
	//ValDisplay out_points,frame=0,value= #"root:Allan_Var_Folder:using_output_points"
	//SetVariable out_points help={"Number of time integrals calculated"}

	SetVariable show_dX_time,pos={164,row_num*multiple},size={short_control*.7, height},title="dX Time spacing"
	SetVariable show_dX_time,frame=1,value= dX_time
	SetVariable show_dX_time limits={1e-15,Inf,0}
	SetVariable show_dX_time help={"Manual time spacing for use if no time wave present"}

	SetVariable Show_OD,pos={288,row_num*multiple},size={short_control*.5, height},title="OD of line"
	SetVariable show_OD,frame=1,value= user_OD
	SetVariable show_OD limits={1e-15,Inf,0}
	SetVariable Show_OD help={"Optical density of the absorption line"}

	SetVariable Show_MR,pos={380,row_num*multiple},size={short_control*.5, height},title="MR"
	SetVariable show_MR,frame=1,value= user_MR
	SetVariable show_MR limits={1e-15,Inf,0}
	SetVariable Show_MR help={"Usual mixing ratio. Used for dark noise."}

		
	row_num += 1
	Button Calculate_AVAR,pos={col_1,row_num*multiple},size={short_control,height},proc=Allan_Buttons,title="Compute Variance"
	Button SaveToRoot_AVAR, pos={ col_2, row_num * multiple}, size={short_control, height}, proc=Allan_Buttons, title="Save Results to Root"
	Button Cancel_AVAR, pos={ col_3, row_num*multiple}, size={short_control, height}, proc=Allan_Buttons,title="Close Graph"
		
	row_num += 1
	Button Zoom_AVAR, pos={col_1, row_num*multiple}, size={short_control, height}, proc=Allan_Buttons, title="Zoom to Cursor"
	Button PullBack_AVAR, pos={col_2, row_num*multiple}, size={short_control, height}, proc=Allan_Buttons, title="Full scale X"
	Button scale_y,pos={col_3,row_num*multiple},size={short_control, height},proc=UsefulButtons,title="Scale Y"
//	SetVariable file_note,pos={col_1+wide_control,row_num*multiple},size={short_control,height},title="File:"
//	SetVariable file_note,frame=0,value= TDL_File_Note
//	SetVariable gen_note,pos={col_3,row_num*multiple},size={short_control,height},title="Note:"
//	SetVariable gen_note,frame=0,value= Generic_Note
	
	ShowInfo
	
	
	Live_Panel_Check() // first time through 
	SetDataFolder root:
End // AllanPanel_Make

Function/T Allan_PopDataWaves()

	String list = WaveList("*", ";", "");
	
	return list;
	
End
Function/T Allan_PopTimes()

	WAVE in_data=root:Allan_Var_Folder:in_data
	Variable in_points = numpnts(in_data)
	String list = WaveList( "*", ";", "" ), return_list = "no_time;"
	Variable idex = 0, count = ItemsInList( list )
	for( idex = 0; idex < count; idex += 1 )
		if( numpnts( $StringFromList( idex, list ) ) == in_points )
			return_list = return_list + StringFromList( idex, list ) + ";"
		endif
	endfor
	return return_list
	
End
Function Allan_PopMenuProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	
	NVAR avar_compute_flag=root:Allan_Var_Folder:avar_compute_flag
	WAVE in_data=root:Allan_Var_Folder:in_data
	Wave in_time = root:Allan_Var_Folder:in_time
	
	avar_compute_flag = 0	
	
	if( cmpstr( ctrlName, "ReferencePop" ) == 0 )
		ControlInfo /W=Allan_Werle_Var_Calc_Graph ReferencePop
		if(stringmatch("_none_", S_value))
			return -1
		endif
		Duplicate /O $S_value in_data
		WAVE in_data=root:Allan_Var_Folder:in_data
	
		
		SetAxis/A bottom
	
	endif
	if( cmpstr( ctrlName, "ReferenceTimePop" ) == 0 )
		
		ControlInfo /W=Allan_Werle_Var_Calc_Graph ReferenceTimePop
		if( cmpstr( S_Value, "no_time" ) == 0 )
			Duplicate /O in_data, in_time
			Wave in_time = root:Allan_Var_Folder:in_time
			in_time = p
		else
			ControlInfo /W=Allan_Werle_Var_Calc_Graph ReferenceTimePop
			Duplicate /O $S_value in_time
			SetScale/P y, 0, 0, "dat" in_time
		endif
		SetAxis/A bottom
	endif
	PopupMenu ReferencePop, value= #"WaveList(\"*\", \";\", \"\")"
	Live_Panel_Check()		
End

Function Live_Panel_Check()
	// this function checks and fills in the dynamic components of the Allan Variance Calculator
	////////// teach this function about contents of Allan_Var_Folder (chud)
	SVAR candidate_waves=root:Allan_Var_Folder:candidate_waves; NVAR points_in_wave=root:Allan_Var_Folder:points_in_wave
	NVAR using_input_points=root:Allan_Var_Folder:using_input_points; NVAR using_output_points=root:Allan_Var_Folder:using_output_points
	NVAR dX_time=root:Allan_Var_Folder:dX_time; SVAR TDL_File_Note=root:Allan_Var_Folder:TDL_File_Note
	SVAR Generic_Note=root:Allan_Var_Folder:Generic_Note; NVAR range_flag=root:Allan_Var_Folder:range_flag
	NVAR avar_compute_flag=root:Allan_Var_Folder:avar_compute_flag; NVAR avar_save_flag=root:Allan_Var_Folder:avar_save_flag; 
	NVAR user_dX_flag=root:Allan_Var_Folder:user_dX_flag
	NVAR user_OD = root:Allan_Var_Folder:user_OD
	NVAR user_MR = root:Allan_Var_Folder:user_MR
	
	NVAR auto_Dt=root:Allan_Var_Folder:auto_Dt; 

	WAVE in_time=root:Allan_Var_Folder:in_time	
	WAVE in_data=root:Allan_Var_Folder:in_data; WAVE avar_x=root:Allan_Var_Folder:avar_x
	WAVE avar_y=root:Allan_Var_Folder:avar_y; WAVE avar_white=root:Allan_Var_Folder:avar_white
	WAVE avar_white_plus=root:Allan_Var_Folder:avar_white_plus; WAVE avar_white_minus=root:Allan_Var_Folder:avar_white_minus
	//////// end chud
	Dowindow/F Allan_Werle_Var_Calc_Graph
	// set the in points
	using_input_points = numpnts( in_data )
	// set the out points
	using_output_points = numpnts( avar_x )
	
	
	if(avar_compute_flag == 0 )
		if( using_input_points > 10 )
			//Cursor/P A in_data (0.1*using_input_points);
			//Cursor/P B in_data (0.9*using_input_points);
		else
			//Cursor/P A in_data 0
			//Cursor/P B in_data using_input_points
		endif
		
		CheckDisplayed /W=Allan_Werle_Var_Calc_Graph avar_y
		if( V_flag > 0 )
			RemoveFromGraph avar_white_minus,avar_white_plus,avar_white,avar_y 
			RemoveFromGraph in_data
			AppendToGraph in_data vs in_time
			ModifyGraph mirror(left)=1,minor(left)=1,standoff(left)=0,axisEnab(left)={0,1}
			ModifyGraph minor(bottom)=1
			Label bottom "collected data time "
		endif
		ModifyGraph mirror=2
		ModifyGraph standoff=0
		ModifyGraph axisEnab(left)={0,1}
		Label left "signal data"
		Label bottom "Integration Time"
		ModifyGraph log(bottom)=0
	endif
	if( avar_compute_flag == 1 )
		PauseUpdate; Silent 1		// building window...
		
		checkdisplayed /W=Allan_Werle_Var_Calc_Graph avar_y
		if( v_flag == 0 )
			AppendToGraph/L=avar_ax avar_y vs avar_x
			AppendToGraph/L=avar_ax avar_white vs avar_x
			AppendToGraph/L=avar_ax avar_white_plus vs avar_x
			AppendToGraph/L=avar_ax avar_white_minus vs avar_x
			RemoveFromGraph in_data
			AppendToGraph/T in_data vs in_time
			ModifyGraph mirror(left)=1,minor(left)=1,standoff(left)=0,axisEnab(left)={0.66,1}
			ModifyGraph minor(top)=1;DelayUpdate
			Label top "collected data time "
		endif
		ModifyGraph log(bottom)=1
		SetAxis/A bottom
		ModifyGraph log(avar_ax)=1
		ModifyGraph mirror(avar_ax)=2
		ModifyGraph minor(avar_ax)=1
		ModifyGraph standoff=0
		ModifyGraph lblPos(left)=48,lblPos(avar_ax)=48
		ModifyGraph lblLatPos(avar_ax)=15
		ModifyGraph freePos(avar_ax)={0,bottom}
		ModifyGraph axisEnab(left)={0.63,1}
		ModifyGraph axisEnab(avar_ax)={0,0.66}
		ModifyGraph rgb(avar_white)=(30464,30464,30464)
		ModifyGraph rgb(avar_white_plus)=(30464,30464,30464)
		ModifyGraph rgb(avar_white_minus)=(30464,30464,30464)
		ModifyGraph lstyle(avar_white_plus)=4,lstyle(avar_white_minus)=4
		ModifyGraph rgb(avar_y)=(0,0,0)
		Label left "signal data"
		Label top "Time"
		Label bottom "Integration Time (points)"
		Label avar_ax "Allan-Werle Variance ("+Allan_sigma()+"\\S2\\M)"
		
	endif
End
Function/S Allan_sigma()
	String sigma
	#IF (igorversion()<7)
		sigma = "\F'Symbol's\F]0"
	#ELSE
		sigma = U+03C3 // unicode
	#ENDIF
	Return sigma
End
Function Allan_Buttons(ctrlName) : ButtonControl
	String ctrlName
	Variable low_x, high_x
	NVAR avar_compute_flag=root:Allan_Var_Folder:avar_compute_flag
	
	if( cmpstr(ctrlName, "Calculate_AVAR" ) == 0 )
		ControlInfo /W=Allan_Werle_Var_Calc_Graph RangePop
		if(cmpstr( S_value, "All Data") == 0 )	 	
			Calculate_AllanVariance(1)
			avar_compute_flag = 1
		endif
		if( cmpstr(S_value, "Cursors") == 0 )
			PullWaveletteFromCursors()
			Calculate_AllanVariance(1)
			avar_compute_flag = 1		
		endif
		
	
	
		Live_Panel_Check()
	endif
	if( cmpstr(ctrlName, "SaveToRoot_AVAR" ) == 0 )
		if(avar_compute_flag == 1 )
			DoSaveToRoot_AVAR()
		endif
	endif

	if( cmpstr(ctrlName, "Zoom_AVAR" ) == 0 )

		if( strlen( CsrWave(A) ) >1 && strlen(CsrWave(B)) > 1)
			
			low_x = pcsr(A)
			if( low_x < pcsr(B) )
				high_x = pcsr(B)
			else
				high_x = low_x
				low_x = pcsr(B)
			endif
			if( avar_compute_flag == 1 )
				Setaxis/Z top low_x, high_x
				Setaxis /A bottom
			else
				low_x = CsrXWaveRef(A)[low_x - 1]
				high_x = CsrXWaveRef(A)[high_x + 1]
				
				Setaxis/Z bottom low_x, high_x			
			endif
		else
			if( avar_compute_flag == 1 )
				GetAxis/Q top
				SetAxis/Z top ((V_max - V_min)*0.1 + V_min), (V_max - (V_max-V_min)*0.1)
			else
				GetAxis /Q bottom
				SetAxis/Z bottom ((V_max - V_min)*0.1 + V_min), (V_max - (V_max-V_min)*0.1)
			endif
		endif
	endif
	if( cmpstr(ctrlName, "PullBack_AVAR" ) == 0 )
		SetAxis/A bottom
	endif
	
	if( cmpstr(ctrlName, "Cancel_AVAR" ) == 0 )
		DoWindow/K Allan_Werle_Var_Calc_Graph
	endif
	
	WAVE in_time=root:Allan_Var_Folder:in_time	
	WAVE in_data=root:Allan_Var_Folder:in_data; 

	if( cmpstr( ctrlName, "PreAverageGap_AVAR" ) == 0 )
		AvgFastDataWithGaps2Pnts( in_data, in_time )
		// And now catch the output 
		Wave pac_AvgData
		Wave pac_AvgTime;		SetScale/P y, 0, 0, "dat", pac_AvgTime
		Wave pac_AvgStdDev
		DoWindow PreAverageOverGapsTable
		if( V_Flag )
			DoWindow/F PreAverageOverGapsTable
		else
			Edit/K=1/W=(41,243,394,531) as "PreAverageOverGapsTable"
			DoWindow/C PreAverageOverGapsTable
			AppendToTable pac_AvgTime
			AppendToTable pac_AvgData
			AppendToTable pac_AvgStdDev
			ModifyTable format(pac_AvgTime)=8; ModifyTable width(pac_AvgTime)=115

		endif

		DoWindow PreAverageOverGapsGraph
		if( V_Flag )
			DoWindow/F PreAverageOverGapsGraph
		else
			Display/K=1 as "PreAverageOverGapsGraph"
			DoWindow/C PreAverageOverGapsGraph
			 
			AppendToGraph pac_AvgData vs pac_AvgTime
			ModifyGraph mode=3,marker=18,rgb=(0,0,65280);
			ErrorBars pac_AvgData Y,wave=(pac_AvgStdDev,pac_AvgStdDev)
			
		endif
		
		DoWindow /F Allan_Werle_Var_Calc_Graph		
		Allan_PopMenuProc("ReferencePop",WhichListItem("pac_AvgData", Allan_PopDataWaves())   ,"pac_AvgData")
		Allan_PopMenuProc("ReferencePopTime",1,"pac_AvgTime")
	endif
	
End
Function PullWaveletteFromCursors()

Variable low_x, high_x, holder	
////////// teach this function about contents of Allan_Var_Folder (chud)
SVAR candidate_waves=root:Allan_Var_Folder:candidate_waves; NVAR points_in_wave=root:Allan_Var_Folder:points_in_wave
NVAR using_input_points=root:Allan_Var_Folder:using_input_points; NVAR using_output_points=root:Allan_Var_Folder:using_output_points
NVAR dX_time=root:Allan_Var_Folder:dX_time; SVAR TDL_File_Note=root:Allan_Var_Folder:TDL_File_Note
SVAR Generic_Note=root:Allan_Var_Folder:Generic_Note; NVAR range_flag=root:Allan_Var_Folder:range_flag
NVAR avar_compute_flag=root:Allan_Var_Folder:avar_compute_flag; NVAR avar_save_flag=root:Allan_Var_Folder:avar_save_flag; NVAR user_dX_flag=root:Allan_Var_Folder:user_dX_flag
NVAR user_OD = root:Allan_Var_Folder:user_OD
NVAR user_MR = root:Allan_Var_Folder:user_MR
WAVE in_time=root:Allan_Var_Folder:in_time	
	
WAVE in_data=root:Allan_Var_Folder:in_data; WAVE avar_x=root:Allan_Var_Folder:avar_x
WAVE avar_y=root:Allan_Var_Folder:avar_y; WAVE avar_white=root:Allan_Var_Folder:avar_white
WAVE avar_white_plus=root:Allan_Var_Folder:avar_white_plus; WAVE avar_white_minus=root:Allan_Var_Folder:avar_white_minus
//////// end chud
	if(strlen(csrinfo(A))==0)
		Cursor/A=1/P A in_data 0
	endif
	if(strlen(csrinfo(B))==0)
		Cursor/A=1/P B in_data numpnts(in_data)-1
	endif
	
	low_x = pcsr(A)
	if( low_x < pcsr(B) )
			high_x = pcsr(B)
	else
			high_x = low_x
			low_x = pcsr(B)
	endif
	Duplicate/O /R=[low_x, high_x] in_data, temp_data
	Duplicate/O /R=[low_x, high_x] in_time, temp_time
	Duplicate/O temp_data, in_data
	Duplicate/O temp_time, in_time
	using_input_points = numpnts( in_data )
	

//	SortAndKillNans( "in_time;in_data;", 1 );
	//KillWaves temp_data
	SetScale/P x, 0, 1, in_data, in_time
	

End
Function Calculate_AllanVariance(multiple)
Variable multiple

////////// teach this function about contents of Allan_Var_Folder (chud)
SVAR candidate_waves=root:Allan_Var_Folder:candidate_waves; NVAR points_in_wave=root:Allan_Var_Folder:points_in_wave
NVAR using_input_points=root:Allan_Var_Folder:using_input_points; NVAR using_output_points=root:Allan_Var_Folder:using_output_points
NVAR dX_time=root:Allan_Var_Folder:dX_time; SVAR TDL_File_Note=root:Allan_Var_Folder:TDL_File_Note
SVAR Generic_Note=root:Allan_Var_Folder:Generic_Note; NVAR range_flag=root:Allan_Var_Folder:range_flag
NVAR avar_compute_flag=root:Allan_Var_Folder:avar_compute_flag; NVAR avar_save_flag=root:Allan_Var_Folder:avar_save_flag; NVAR user_dX_flag=root:Allan_Var_Folder:user_dX_flag
NVAR user_OD = root:Allan_Var_Folder:user_OD
NVAR user_MR = root:Allan_Var_Folder:user_MR
WAVE in_time=root:Allan_Var_Folder:in_time	
	
WAVE in_data=root:Allan_Var_Folder:in_data; WAVE avar_x=root:Allan_Var_Folder:avar_x
WAVE avar_y=root:Allan_Var_Folder:avar_y; WAVE avar_white=root:Allan_Var_Folder:avar_white
WAVE avar_white_plus=root:Allan_Var_Folder:avar_white_plus; WAVE avar_white_minus=root:Allan_Var_Folder:avar_white_minus
//////// end chud
	
	Make_Appropriate_X_Values_AVAR(300)
	Redimension/N=(numpnts(avar_x)) avar_y 
//	SortAndKillNans("root:Allan_Var_Folder:in_time;root:Allan_Var_Folder:in_data;", 1 )

//	KillNansAndFictionalizeTime( "root:Allan_Var_Folder:in_time;root:Allan_Var_Folder:in_data;" )
	avar_y = FAllanVar(in_data,using_input_points,dX_time,avar_x[p])
	AllanWhite()

End

Function Make_Appropriate_X_Values_AVAR(max_num_Vars)
Variable max_num_Vars

////////// teach this function about contents of Allan_Var_Folder (chud)
SVAR candidate_waves=root:Allan_Var_Folder:candidate_waves; NVAR points_in_wave=root:Allan_Var_Folder:points_in_wave
NVAR using_input_points=root:Allan_Var_Folder:using_input_points; NVAR using_output_points=root:Allan_Var_Folder:using_output_points
NVAR dX_time=root:Allan_Var_Folder:dX_time; SVAR TDL_File_Note=root:Allan_Var_Folder:TDL_File_Note
SVAR Generic_Note=root:Allan_Var_Folder:Generic_Note; NVAR range_flag=root:Allan_Var_Folder:range_flag
NVAR avar_compute_flag=root:Allan_Var_Folder:avar_compute_flag; NVAR avar_save_flag=root:Allan_Var_Folder:avar_save_flag; NVAR user_dX_flag=root:Allan_Var_Folder:user_dX_flag
NVAR user_OD = root:Allan_Var_Folder:user_OD
NVAR user_MR = root:Allan_Var_Folder:user_MR
WAVE in_time=root:Allan_Var_Folder:in_time	
	
WAVE in_data=root:Allan_Var_Folder:in_data; WAVE avar_x=root:Allan_Var_Folder:avar_x
WAVE avar_y=root:Allan_Var_Folder:avar_y; WAVE avar_white=root:Allan_Var_Folder:avar_white
WAVE avar_white_plus=root:Allan_Var_Folder:avar_white_plus; WAVE avar_white_minus=root:Allan_Var_Folder:avar_white_minus
//////// end chud

	Variable n_1, n_2, n_3
	Variable base_points = using_input_points
	
	n_1 = 2*floor(sqrt(base_points)) 
	
	Redimension/N=(n_1) avar_x
	avar_x = (p+1)*dX_time
	
	avar_x[(n_1/2+1),(n_1-1)] = dX_time*round(base_points/(n_1-p+1))
	
	If(n_1 > max_num_Vars)  // replace middle point by  exp spaced pts
		n_2 = floor(max_num_Vars/3)
		n_3 = n_1-2*n_2
		
		DeletePoints n_2,n_3,avar_x
		InsertPoints n_2,n_2,avar_x
		
		Variable j=0
		Variable h = (avar_x[(2*n_2)]/avar_x[(n_2-1)])^(1/(n_2+1))
		Variable hh = h
		Do
			avar_x[j+n_2] = avar_x[(n_2-1)]*hh
			hh *=h
			j += 1
		While(j <= n_2)
	endif
		
End // Function MakeAppropriateXValues_AVAR

Function FAllanVar(inWave,npt,dX,xInt)
	WAVE inWave
	Variable npt       //  number of pts in inWave
	Variable dX   //  x-spacing for inWave
	Variable xInt   // x interval for averaging
	
	Variable numInt, ptsInt
	numInt = ceil(npt*dX/xInt)  // number of intervals
	ptsInt = ceil(npt/numInt)   // number of pts per interval
	Make/O/N=(numInt)/D tempAllan
	tempAllan = 0

	Variable i = 0,p1,p2
	Do
		p1 = pnt2x(inWave,i*ptsInt)
		p2 = pnt2x(inWave,(i+1)*ptsInt-1)
		tempAllan[i] = mean(inWave,p1,p2)
		i += 1
	While(i < numInt)
	tempAllan = tempAllan[p+1] - tempAllan[p]
	DeletePoints (numInt-1),1,tempAllan
	tempAllan = tempAllan*tempAllan/2
	If(numInt >2)
		WaveStats/Q tempAllan
		return V_avg
	else
		return tempAllan[0]
	endif
	KillWaves tempAllan
end
	
	
// Calculate lines for white noise
Function AllanWhite()

////////// teach this function about contents of Allan_Var_Folder (chud)
SVAR candidate_waves=root:Allan_Var_Folder:candidate_waves; NVAR points_in_wave=root:Allan_Var_Folder:points_in_wave
NVAR using_input_points=root:Allan_Var_Folder:using_input_points; NVAR using_output_points=root:Allan_Var_Folder:using_output_points
NVAR dX_time=root:Allan_Var_Folder:dX_time; SVAR TDL_File_Note=root:Allan_Var_Folder:TDL_File_Note
SVAR Generic_Note=root:Allan_Var_Folder:Generic_Note; NVAR range_flag=root:Allan_Var_Folder:range_flag
NVAR avar_compute_flag=root:Allan_Var_Folder:avar_compute_flag; NVAR avar_save_flag=root:Allan_Var_Folder:avar_save_flag; NVAR user_dX_flag=root:Allan_Var_Folder:user_dX_flag
NVAR user_OD = root:Allan_Var_Folder:user_OD
NVAR user_MR = root:Allan_Var_Folder:user_MR

WAVE in_time=root:Allan_Var_Folder:in_time	
	
WAVE in_data=root:Allan_Var_Folder:in_data; WAVE avar_x=root:Allan_Var_Folder:avar_x
WAVE avar_y=root:Allan_Var_Folder:avar_y; WAVE avar_white=root:Allan_Var_Folder:avar_white
WAVE avar_white_plus=root:Allan_Var_Folder:avar_white_plus; WAVE avar_white_minus=root:Allan_Var_Folder:avar_white_minus
//////// end chud
Variable scale = sqrt( using_input_points )

	Duplicate/O avar_y avar_white, avar_white_plus, avar_white_minus
	avar_white = ( avar_y[0] ) / avar_x[p] * dX_time
	avar_white_minus=nan;avar_white_plus=nan
	
	avar_white_plus = avar_y[0] * dX_time * sqrt( 2/floor(using_input_points)/avar_x[p]) + avar_white
	avar_white_minus = avar_white - avar_y[0] * dX_time * sqrt( 2/floor(using_input_points)/avar_x[p])

end 

Function DoSaveToRoot_AVAR()
	
	////////// teach this function about contents of Allan_Var_Folder (chud)
	SVAR candidate_waves=root:Allan_Var_Folder:candidate_waves; NVAR points_in_wave=root:Allan_Var_Folder:points_in_wave
	NVAR using_input_points=root:Allan_Var_Folder:using_input_points; NVAR using_output_points=root:Allan_Var_Folder:using_output_points
	NVAR dX_time=root:Allan_Var_Folder:dX_time; SVAR TDL_File_Note=root:Allan_Var_Folder:TDL_File_Note
	SVAR Generic_Note=root:Allan_Var_Folder:Generic_Note; NVAR range_flag=root:Allan_Var_Folder:range_flag
	NVAR avar_compute_flag=root:Allan_Var_Folder:avar_compute_flag; NVAR avar_save_flag=root:Allan_Var_Folder:avar_save_flag; NVAR user_dX_flag=root:Allan_Var_Folder:user_dX_flag
	NVAR user_OD = root:Allan_Var_Folder:user_OD
	NVAR user_MR = root:Allan_Var_Folder:user_MR
	WAVE in_time=root:Allan_Var_Folder:in_time	
		
	WAVE in_data=root:Allan_Var_Folder:in_data; 
	WAVE in_time=root:Allan_Var_Folder:in_time
	WAVE avar_x=root:Allan_Var_Folder:avar_x
	WAVE avar_y=root:Allan_Var_Folder:avar_y; WAVE avar_white=root:Allan_Var_Folder:avar_white
	WAVE avar_white_plus=root:Allan_Var_Folder:avar_white_plus; WAVE avar_white_minus=root:Allan_Var_Folder:avar_white_minus
	//////// end chud
	
	String original_wave, original_time
	String root_x, root_y,  root_segx, root_segy,root_white, root_whitep, root_whitem, root_original
	String new_rsegy, new_rsegx
	
	ControlInfo /W=Allan_Werle_Var_Calc_Graph ReferencePop
	original_wave = S_value 
	ControlInfo /W=Allan_Werle_Var_Calc_Graph ReferenceTimePop
	original_time = S_value 
	
	Variable stime, etime
	GetAxis/W=Allan_Werle_Var_Calc_Graph/Q top
	stime = V_min
	etime = V_max
	

	root_original = original_wave
	root_x = "root:"+original_wave+"_avar_x"
	root_y = "root:"+original_wave+"_avar_y"
	root_segx = "root:"+original_wave+"_avar_segx"
	root_segy = "root:"+original_wave+"_avar_segy"
	root_white = "root:"+original_wave+"_white"
	root_whitep = "root:"+original_wave+"_avar_whitep"
	root_whitem = "root:"+original_wave+"_avar_whitem"
	


	Duplicate/O avar_x $root_x;	//DoUpdate;
	Wave jw = $root_x
	SetFormula $GetWavesDataFolder(jw,2), ""
	
	Duplicate/O avar_y $root_y;	//DoUpdate;
	Wave jw = $root_y
	SetFormula $GetWavesDataFolder(jw,2), ""
	
	WAVE myin_data=root:Allan_Var_Folder:in_data; 
	WAVE myin_time=root:Allan_Var_Folder:in_time
	
	Wave/Z cr_data = $( "root:"+original_wave+"_avar_segy" )
	if( WaveExists( cr_data ) )
		Redimension/N=3 cr_data;	//DoUpdate;
	else
		SetDataFolder root:; Make/N=0/D $( "root:"+original_wave+"_avar_segy" )
		Wave/Z cr_data = $( "root:"+original_wave+"_avar_segy" )
	endif

	
	Duplicate/O myin_data, cr_data;	
	//printf "%5.3f\t%5.3f\r", myin_data[0], cr_data[0];
	SetFormula $GetWavesDataFolder( cr_data,2), ""

//	DoUpdate;


	Wave/Z cr_time = $( "root:"+original_wave+"_avar_segx" )
	if( WaveExists( cr_time ) )
		Redimension/N=0 cr_time;	//DoUpdate;
	else
		SetDataFolder root:; Make/N=0/D $( "root:"+original_wave+"_avar_segx" )
		Wave/Z cr_time = $( "root:"+original_wave+"_avar_segx" )
	endif
	SetFormula cr_time, ""
	
	Duplicate/O myin_time, cr_time;	//DoUpdate;
	
	Duplicate/O avar_white $root_white;	//DoUpdate;
	Duplicate/O avar_white_plus $root_whitep;	//DoUpdate;
	Duplicate/O avar_white_minus $root_whitem;	//DoUpdate;
	
//	PauseUpdate
	Wave w = $root_x;	//DoUpdate;
	Wave w_y = $root_y;	//DoUpdate;

	CurveFit/Q  line in_time /D
	Wave these_coef=W_Coef
	Wave w_c = these_coef
	w *= w_c[1]

	// We must name the graph properly with a legit title.
	String copyToRootWinName
	sprintf  copyToRootWinName, "AVAR_Archive_%s", original_wave
	DoWindow $copyToRootWinName
	if( V_Flag )
		DoWindow/K $copyToRootWinName
	endif
	
	Wave disp_y = $root_y;	DoUpdate;
	Wave disp_x = $root_x;	DoUpdate;
	Display /W=(514,45,1009,453) disp_y vs disp_x as copyToRootWinName
	DoWindow/C $copyToRootWinName
	
	ModifyGraph log=1,mirror(left)=2,minor=1,standoff=0,axisEnab(left)={0,0.66}
	AppendToGraph $root_white, $root_whitep, $root_whitem vs w
	
	// re-establish reference to the target segx and segy
	Wave cr_data=$root_segy
	Wave cr_time=$root_segx

	if( cmpstr( original_time, "no_time" ) == 0 )
		AppendToGraph/L=data_ax/T $root_segy
	else
		AppendToGraph/L=data_ax/T cr_data vs cr_time
		//SetAxis top stime, etime
	endif
	Execute("avar_style()")
	String anno_str = "", line
	
//	// this is the first point
//	String unit = "s"; Variable thisTime = w[0]
//	if(w[0]<60)
//		thisTime = w[0]
//		unit = "s   "
//	elseif(w[0]>=60 && w[0]<3600)
//		thisTime = w[0]/60
//		unit = "min"
//	elseif(w[0]>=3600)
//		thisTime = w[0]/3600
//		unit = "hr  "
//	endif
//	if(sqrt(w_y[0]) < 0.02)
//		sprintf line, " %3.1f %3s %3g", thisTime, unit, sqrt( w_y[0] )
//	else
//		sprintf line, " %3.1f %3s %7.3f", thisTime, unit, sqrt( w_y[0] )
//	endif
//	anno_str = anno_str + line
//	
//	// ignore the last 25% of the allan plot because data is so sparse. 
//	WaveStats/Q/R=[0, ceil( 0.75 * numpnts( w_y))] w_y
//	// w_y is not scaled data so we cannot reliably use v_minLoc to get the x-value here. 
//	// old code worked only for 1-second data. New code is general. 
//	unit = "s"; thisTime = w[v_minRowLoc]
//	if(thisTime<60)
//		unit = "s   " // spacing is a little kludgey becasue we are not using a monospaced font!
//	elseif(thisTime>=60 && thisTime<3600)
//		thisTime = thisTime/60
//		unit = "min"
//	elseif(thisTime>=3600)
//		thisTime = thisTime/3600
//		unit = "hr  "
//	endif
//	if(sqrt(v_min) < 0.02)
//		sprintf line, " %3.1f %3s %3g", thisTime, unit, sqrt( v_min )
//	else
//		sprintf line, " %3.1f %3s %7.3f", thisTime, unit, sqrt( v_min )
//	endif
//	
//	anno_str = anno_str +"\r"+ line
	
	avarLabel(OD=user_OD,MR=user_MR)
	Label data_ax original_wave
	Label top "Time"
	Label bottom "Integration Time (s)"
	Label  left "Allan-Werle Variance ("+Allan_sigma()+"\\S2\\M)"
End


Proc avar_style() : GraphStyle
	PauseUpdate; Silent 1		// modifying window...
	ModifyGraph/Z lStyle[2]=4,lStyle[3]=4
	ModifyGraph/Z rgb[0]=(0,0,0),rgb[1]=(30464,30464,30464),rgb[2]=(30464,30464,30464)
	ModifyGraph/Z rgb[3]=(30464,30464,30464),rgb[4]=(24576,24576,65280)
	ModifyGraph/Z log(left)=1,log(bottom)=1
	ModifyGraph/Z mirror(left)=2,mirror(data_ax)=2
	ModifyGraph/Z minor=1
	ModifyGraph/Z standoff=0
	ModifyGraph/Z lblPos(left)=50
	ModifyGraph/Z lblPos(data_ax)=50
	ModifyGraph/Z lblPosMode(left)=4
	modifyGraph/Z lblPosMode(data_ax)=4
	ModifyGraph/Z freePos(data_ax)={0,bottom}
	ModifyGraph/Z axisEnab(left)={0,0.63}
	ModifyGraph/Z axisEnab(data_ax)={0.66,1}
EndMacro

Function KillNansAndFictionalizeTime( list )
	String list
	
	// this function is dirty.  It is low, it is the only way to finally enable Mark to cheat time and disregard reality
	
	Wave/Z time_w = $StringFromList( 0, list )
	Wave/Z data_w = $StringFromList( 1, list )
	
	Duplicate/O time_w temporary_dt
	Differentiate/METH=1 temporary_dt
	QuartileReport( temporary_dt, 0 )
	NVAR V_Quartile50
	Variable assert_dt = V_Quartile50
	
	SortAndKillNans( list, 1 );
	
	time_w = time_w[0] + p * assert_dt;
	
	

End

Function AvgFastDataWithGaps2Pnts(data_w, time_w, [minTimeGap])
	Wave data_w
	Wave time_w
	Variable minTimeGap
	
	Variable useGap = 5
	if( !paramIsDefault( minTimeGap ) )
		useGap = minTimeGap;
	endif
	
	Variable idex, count, bdex, edex, parity, this_delta
	Duplicate/O data_w, pac_data
	Duplicate/O time_w, pac_time


		
	SortAndKillNansFast( "pac_time;pac_data;", 1 );
	
	Make/N=0/D/O pac_StartData, pac_StopData; SetScale/P y, 0, 0, "dat", pac_StartData, pac_StopData;
	count = numpnts( pac_time );
	
	Duplicate/O pac_time, pac_DeltaTime; Differentiate /METH=1 pac_DeltaTime;
	
	// initialize
	if( numtype( pac_data[0] ) == 0 )
		// first data point is valued, lets just start it off
		AppendVal( pac_StartData, pac_time[0] )
		parity = 1;
	else
		// we are starting in a nan'd block, capture dT later
		parity = 0;
	endif
	
	for( idex = 0; idex < count; idex += 1 )
		this_delta = pac_DeltaTime[idex];
		
		if( (this_delta > useGap) & (parity == 0 ) )
			// this will start time in the special case of starting with nan-d data?
			AppendVal( pac_StartData, pac_time[idex] )
			parity = 1;
			continue;
		endif
		
		if( (abs( this_delta ) > useGap) & (parity == 1 ) )
			// this will stop time
			AppendVal( pac_StopData, pac_time[idex] )
			// and immediately trigger the next data time IF
			if( (pac_time[idex+1] - pac_time[idex] ) > useGap )
				AppendVal( pac_StartData, pac_time[idex+1] )
				parity = 1;
			else
				parity = 0;
			endif
			continue;
		endif
	endfor
	
	// perhaps we end during data
	if( numpnts( pac_StartData ) > numpnts( pac_StopData ) )
		AppendVal( pac_StopData, pac_time[ numpnts( pac_time ) - 1 ] )
	endif
	
	Duplicate/O pac_StartData, pac_AvgData, pac_AvgTime, pac_AvgStdDev
	SetScale/P y, 0,0, "", pac_AvgData, pac_AvgStdDev
	count = numpnts( pac_AvgData )
	for( idex = 0; idex < count; idex  += 1 )
		bdex = BinarySearch( time_w, pac_StartData[idex] );
		edex = BinarySearch( time_w, pac_StopData[idex] );
		WaveStats/Q/R=[ bdex, edex ] data_w
		pac_AvgData[idex] = v_avg
		pac_AvgStdDev[idex] = v_sdev
		pac_AvgTime[idex] = 1/2*( pac_StartData[idex] + pac_StopData[idex] )
	endfor
	
	KillWaves/Z pac_StartData, pac_StopData, pac_DeltaTime, pac_time, pac_data

End


// Avarlabel is a function for labeling allan variance plots. It requires the name (Win) of the allan
// variance window to operate on, and the optical depth (OD) of the main feature for a given species.
// Win must be provided as a string, and OD as a value. The Mixing Ratio (MR) and delta switch (del)
// are optional parameters. If MR is not provided the function calculates the average MR from the allan
// variance data segment. The reason to provide MR is for calculating the absorbance and fractional
// noises on a dark noise plot.	del = 1 is used for delta ratio allan plots. When del is set to 1 the
// function does not calculate the absorbance and fractional noises, and it dose not print the OD, MR,
// and absorbance and fractional noises to the label. del defaults to 0 if not provided.
// 06/02/2018 - TIY
	// Made Win, OD into optional parameters. Now defaults to top window. OD defaults to 0
	// del is set to 1 if base name contains the word "del"
	// Does not produce an error if too short timescale is chosen; instead it will just avoid printing
	//		the larger timescalel summaries.
	// Added an Allan Minimum line, which is usually what users are looking for when using this function.
	
Function Avarlabel([Win,OD,MR,del])

	String Win	
	Variable OD, MR, del

	
	if(paramisdefault(Win))
		// then use top window
		Getwindow/z kwTopWin title
		 win = WinName(0, 1, 1)
		if(WinType(win) !=1) // not a graph
			Abort "No Window Specified, and top window is not a graph."
		endif
	endif
	
	DoWindow $Win
	if (v_flag == 0)
		Abort "Window does not exist"
	endif
	
	// this is the allan panel:
	String tracelist = tracenamelist(Win,"",1)
	String yname = removeending(listmatch(tracelist,"avar_y"),";")
	String wave_name_root=""
	if(strlen(yname)>0)
		wave/z avar_y = traceNametowaveref(Win, yname)
		wave/z avar_x = XwaveRefFromTrace(win, yname)
		wave/z segy = tracenametowaveref(win, "in_data")
	else
	// find wave prefix root for a given AVAR graph
		wave_name_root = tracenamelist(Win,"",1)
		wave_name_root = listmatch(wave_name_root,"*_avar_y")
		wave_name_root = replacestring("_avar_y",wave_name_root,"")
		wave_name_root = removeending(wave_name_root,";")
		Wave/z avar_x = xwaverefFromTrace(Win,(wave_name_root+"_avar_y"))
		Wave/z avar_y = traceNameToWaveRef(Win, (wave_name_root+"_avar_y"))
		wave/z segy=  traceNameToWaveRef(Win, (wave_name_root+"_avar_segy"))
	endif
	
	if(!waveexists(avar_Y) || !waveexists(avar_y))
			print "Window is not an Allan Variance plot"
			return -1
	endif


	if(paramisdefault(OD))
		OD=nan
	endif
	
	if (paramisdefault(MR))
		MR=nan		
	endif
	
	if (paramisdefault(del))
		if(stringmatch(wave_name_root, "*del*"))
			del=1
		else
			del=0
		endif
	endif

	//TextBox/K/w=$win/N=text0	//Kill existing text box from AVAR panel

	// Calculate avar at first point in avar wave, 0.1s, 1s, 10s, and 100s
	Variable p1 = binarysearchinterp(avar_x,1)
	Variable p10 = binarysearchinterp(avar_x,10)
	Variable p100 = binarysearchinterp(avar_x,100)
	
	// these are the results of the variance calculation at various timescales. 
	Variable avarp0, avar1, avar10, avar100, avarMin
	
	// these tell us whether the timescales exist.
	Variable exist1=1, exist10=1, exist100=1
	
	// we always calculate the smallest timescale point:
	avarp0 = sqrt(avar_y[0])

//		// is it 10 Hz?
//		if (round(10*avar_x[0])/10 == 1)
//			p1 = 0
//		endif
	
	// 1 second
	if(numtype(p1)==2)
	
		// binary search interp returns nan if interval is ever so slightly larger than 1 sec.
		if(1 - avar_x[0] > 0.001)
			// then the first time point not 1 sec.
			exist1=0
			avar1=nan
		else
			exist1=1
			p1=0
			avar1=sqrt(avar_y[p1])
		endif
		
	else
		avar1 = sqrt(avar_y[p1])
	endif
	
	// 10 second
	if (numtype(p10) == 2)
		avar10=nan
		exist10=0
	else
		avar10 = sqrt(avar_y[p10])
	endif
	
	// 100 second
	if (numtype(p100) == 2)
		avar100=nan
		exist100=0
	else
		avar100=sqrt(avar_y[p100])
	endif

	// set scale and units for label
	variable nscale 	//avar noise scale for annoStr#'s
	string nunit		//avar noise unit for annoStr#'s
	if (del == 1)
		nscale = 1
		nunit = "‰"
	else
		nscale = floor(log(abs(avarp0)))
		if (nscale < 0)
			nscale = 1000
			nunit = "ppt"
		elseif (nscale < 3)
			nscale = 1
			nunit = "ppb"
		elseif(nscale < 6)
			nscale = 1e-3
			nunit = "ppm"
		else
			nscale = 1e-7
			nunit = "%"
		endif
	endif



	// Calculate the Allan minimum
		
	
	WaveStats/Q/R=[0, ceil( .75 * numpnts( avar_y))] avar_y // ignore the last 25% of the allan plot because data is so sparse. 
	// w_y is not scaled data so we cannot reliably use v_minLoc to get the x-value here. 
	// old code worked only for 1-second data. New code is general. 
	
	string unit = "s"; Variable thisTime = avar_x[v_minRowLoc]; 
	avarMin = sqrt(avar_y[v_minRowLoc])
	
	Wavestats/Q avar_y
	if(avar_x[v_minRowLoc] != thisTime)
		// then the sparse points at long distances have better allan performance
		if( v_minRowLoc < numpnts(avar_y)*.95 && avarMin/sqrt(avar_y[v_minRowLoc]) <10)
			// if the difference is less than a factor of 10, use the sparse data. Otherwise ignore
			thisTime = avar_x[v_minRowLoc]
			avarMin=sqrt(avar_y[v_minRowLoc])
		endif
			
		
	endif
	
	if(thisTime<55)
		unit = "s"
	elseif(thisTime>=55 && thisTime<3540)
		thisTime = thisTime/60
		unit = "min"
	elseif(thisTime>=3540)
		thisTime = thisTime/3600
		unit = "hr"
	endif
	
	// make text box	
	String legendStr, annoStr0, annoStr1, annoStr2, annoStr3, annoStrMin		


	if (del == 1)
		sprintf legendStr, "\Z12"
		sprintf annoStr0, "%0.1f s\t%6.2f %s", avar_x[0], avarp0*nscale, nunit
		sprintf annoStr1, "%0.0f s\t%6.2f %s", 1, avar1*nscale, nunit
		sprintf annoStr2, "%0.0f s\t%6.2f %s", 10, avar10*nscale, nunit
		sprintf annoStr3, "%0.0f s\t%6.2f %s", 100, avar100*nscale, nunit
		sprintf annoStrMin, "%0.1f %s\t%6.2f %s", thisTime, unit, avarMin*nscale, nunit
		TextBox/C/W=$win/F=0/B=1/N=AvarText/A=LB/T={70} legendstr;delayupdate
		AppendText/W=$win/N=AvarText "===================";delayupdate
		AppendText/W=$win/N=AvarText "\f04Int. Time	  Std. Dev.\f00";delayupdate
		if (round(10*avar_x(0))/10 < 1) // if faster than 1s exists
			AppendText/W=$win/N=AvarText AnnoStr0;delayupdate
			AppendText/W=$win/N=AvarText AnnoStr1;delayupdate
		elseif (round(10*avar_x(0))/10 == 1)
			AppendText/W=$win/N=AvarText AnnoStr1;delayupdate
		else
			AppendText/W=$win/N=AvarText AnnoStr0;delayupdate
		endif
		
		if(exist10)
			AppendText/W=$win/N=AvarText AnnoStr2;delayupdate
		endif
		if(exist100)
			AppendText/W=$win/N=AvarText AnnoStr3
		endif
		AppendText/W=$win/N=AvarText "\f04Allan Minimum\f00";
		AppendText/W=$win/N=AvarText AnnoStrMin;delayupdate
	elseif(numtype(MR)==2)
		sprintf legendStr, "\Z12"
		// no fractional absorbance
		sprintf annoStr0, "%0.1f s\t%6.2f %s", avar_x[0], avarp0*nscale, nunit
		sprintf annoStr1, "%0.0f s\t%6.2f %s", 1, avar1*nscale, nunit
		sprintf annoStr2, "%0.0f s\t%6.2f %s", 10, avar10*nscale, nunit
		sprintf annoStr3, "%0.0f s\t%6.2f %s", 100, avar100*nscale, nunit
		sprintf annoStrMin, "%0.1f %s\t%6.2f %s", thisTime, unit, avarMin*nscale, nunit
		
		TextBox/C/W=$win/F=0/B=1/N=AvarText/A=LB/T={70,150,240} legendstr;delayupdate
			AppendText/W=$win/N=AvarText "===================";delayupdate
			AppendText/W=$win/N=AvarText "\f04Int. Time	  Std. Dev.\f00";delayupdate
		
		if (round(10*avar_x(0))/10 < 1) // if faster than 1s exists
			AppendText/W=$win/N=AvarText AnnoStr0;delayupdate
			AppendText/W=$win/N=AvarText AnnoStr1;delayupdate
		elseif (round(10*avar_x(0))/10 == 1)
			AppendText/W=$win/N=AvarText AnnoStr1;delayupdate
		else
			AppendText/W=$win/N=AvarText AnnoStr0;delayupdate
		endif
		
		if(exist10)
			AppendText/W=$win/N=AvarText AnnoStr2;delayupdate
		endif
		if(exist100)
			AppendText/W=$win/N=AvarText AnnoStr3
		endif
		
			AppendText/W=$win/N=AvarText "\f04Allan Minimum\f00";
			AppendText/W=$win/N=AvarText AnnoStrMin

		
	else
		sprintf legendStr, "\Z12	           "
		if(numtype(OD)!=2)
			sprintf legendStr, "%s          OD = %0.3e, ", legendStr,OD
		else
		//	sprintf legendStr, "%s       ",legendStr
		endif
		sprintf legendStr, "%sMR = %6.2f ppb", legendstr,MR
		
		if(numtype(OD)!=2)
		sprintf annoStr0, "%0.1f s\t%6.2f %s\t%11.3e\t%10.3e", avar_x[0], avarp0*nscale, nunit, avarp0*OD/MR, avarp0/MR
		sprintf annoStr1, "%0.0f s\t%6.2f %s\t%11.3e\t%10.3e", 1, avar1*nscale, nunit, avar1*OD/MR, avar1/MR
		sprintf annoStr2, "%0.0f s\t%6.2f %s\t%11.3e\t%10.3e", 10, avar10*nscale, nunit, avar10*OD/MR, avar10/MR
		sprintf annoStr3, "%0.0f s\t%6.2f %s\t%11.3e\t%10.3e", 100, avar100*nscale, nunit, avar100*OD/MR, avar100/MR
		sprintf annoStrMin, "%0.1f %s\t%6.2f %s\t%11.3e\t%10.3e", thisTime, unit, avarMin*nscale, nunit, avarMin*OD/MR, avarMin/MR
		else
		sprintf annoStr0, "%0.1f s\t%6.2f %s\t%10.3e", avar_x[0], avarp0*nscale, nunit,  avarp0/MR
		sprintf annoStr1, "%0.0f s\t%6.2f %s\t%10.3e", 1, avar1*nscale, nunit,  avar1/MR
		sprintf annoStr2, "%0.0f s\t%6.2f %s\t%10.3e", 10, avar10*nscale, nunit,  avar10/MR
		sprintf annoStr3, "%0.0f s\t%6.2f %s\t%10.3e", 100, avar100*nscale, nunit,  avar100/MR
		sprintf annoStrMin, "%0.1f %s\t%6.2f %s\t%10.3e", thisTime, unit, avarMin*nscale, nunit, avarMin/MR
		endif
	
		TextBox/C/W=$win/F=0/B=1/N=AvarText/A=LB/T={70,150,240} legendstr;delayupdate
		if(numtype(OD)==2)
			AppendText/W=$win/N=AvarText "================================";delayupdate
			AppendText/W=$win/N=AvarText "\f04Int. Time	  Std. Dev. 	Frac. Noise\f00";delayupdate
		else
			AppendText/W=$win/N=AvarText "=============================================";delayupdate
			AppendText/W=$win/N=AvarText "\f04Int. Time	  Std. Dev. 	Abso. Noise	Frac. Noise\f00";delayupdate
		endif
		
		if (round(10*avar_x(0))/10 < 1)  // if faster than 1s exists
			AppendText/W=$win/N=AvarText AnnoStr0;delayupdate
			AppendText/W=$win/N=AvarText AnnoStr1;delayupdate
		endif
		if(exist1)
			AppendText/W=$win/N=AvarText AnnoStr1;delayupdate
		else
			AppendText/W=$win/N=AvarText AnnoStr0;delayupdate // if something else exists, usuallly slower than 1s
		endif
		
		if(exist10)
			AppendText/W=$win/N=AvarText AnnoStr2;delayupdate
		endif
		if(exist100)
			AppendText/W=$win/N=AvarText AnnoStr3
		endif
		
			AppendText/W=$win/N=AvarText "\f04Allan Minimum\f00";
			AppendText/W=$win/N=AvarText AnnoStrMin

	endif

end