#pragma rtGlobals=1		// Don't use modern global access method.

//**********Code Convention in Igor *****************//
//	prefix with 	gv_    	is a Global Variable
//				gs_	 	is a Global Srting
//				w_		is a Wave
//				ws_		is a Text Wave
//	No prefix				ia a Local Variable
//*************************************************************//

//*** If program said: "Variable or Wave is not define" . Hightlight the Code inside the Function Make_necessary_VariableWave()
//     and then press Ctrl+Enter
//***



Function Initialize_HitranIgor_panel()
	if (Make_necessary_VariableWave()==1)
		Execute "HitranSims()"
	endif
End

Constant species = 48, major_species=6, num_waves = 100000


Function Make_necessary_VariableWave()    // Make all the necessary waves, varaibles when initiate the Hitran Igor panel 
	Variable i
	
	Make/O/N=57 w_atmtrns_i0
	Make/O/N=10/T ws_Select_in
	Make/O/T ws_MolecuName={"H2O","CO2","O3","N2O","CO","CH4","O2","NO","SO2","NO2","NH3","HNO3","OH","HF","HCl","HBr","HI","ClO","OCS","H2CO","HOCl","N2","HCN","CH3Cl","H2O2","C2H2","C2H6","PH3","COF2","SF6","H2S","HCOOH","HO2","O","ClNO3","NO+","HOBr","C2H4","CH3OH","CH3Br","CH3CN","CF4","","","","","HONO","SO3"}
	Make/O/T ws_MolecuNameS={"H2O","CO2","O3","N2O","CO","CH4","O2","NO","SO2","NO2","NH3","HNO3","OH","HF","HCl","HBr","HI","ClO","OCS","H2CO","HOCl","N2","HCN","CH3Cl","H2O2","C2H2","C2H6","PH3","COF2","SF6","H2S","HCOOH","HO2","O","ClNO3","NOp","HOBr","C2H4","CH3OH","CH3Br","CH3CN","CF4","dum6","dum7","dum8","dum9","HONO","SO3"}
	Make/O w_H2O_Isotope={0,161,181,171,162}; Make/O w_CO2_Isotope={0,626,636,628,627,638,637,828,728}
	Make/O w_O3_Isotope={0,666,668,686,667,676}; Make/O w_N2O_Isotope={0,446,456,546,448,447}
	Make/O w_CO_Isotope={0,26,36,28,27,38,37};Make/O w_CH4_Isotope={0,211,311,212}
	Make/O w_O2_Isotope={0,66,68,67}; Make/O w_NO_Isotope={46,56,48}; Make/O w_SO2_Isotope={0,626,646} 
	Make/O w_NO2_Isotope={0,646}; Make/O w_NH3_Isotope={0,4111,5111}; Make/O w_HNO3_Isotope={0,146}
	Make/O w_OH_Isotope={0,61,81,62}; Make/O w_HF_Isotope={0,19}; Make/O w_HCl_Isotope={0,15,17}
	Make/O w_HBr_Isotope={0,19,11}; Make/O w_HI_Isotope={0,17}; Make/O w_ClO_Isotope={0,56,76}
	Make/O w_OCS_Isotope={0,622,624,632,822}; Make/O w_H2CO_Isotope={0,126,136,128}
	Make/O w_HOCl_Isotope={0,165,167}; Make/O w_N2_Isotope={0,44}; Make/O w_HCN_Isotope={0,124,134,125}
	Make/O w_CH3Cl_Isotope={0,215,217}; Make/O w_H2O2_Isotope={0,1661}; Make/O w_C2H2_Isotope={0,1221,1231} 
	Make/O w_C2H6_Isotope={0,1221}; Make/O w_PH3_Isotope={0,1111}; Make/O w_COF2_Isotope={0,269}
	Make/O w_SF6_Isotope={0,29}; Make/O w_H2S_Isotope={0,121,141,131}; Make/O w_HCOOH_Isotope={0,126}
	Make/O w_HO2_Isotope={0,166}; Make/O w_O_Isotope={0,6}; Make/O w_ClNO3_Isotope={0,5646,7646}
	Make/O w_NOp_Isotope={0,46}; Make/O w_HOBr_Isotope={0}
	
	String/G gs_Database = ""
	String/G gs_HitranFileName="hitemp"
	String/G gs_OutputFileName="N2O"
	String/G gs_allMoleculesPopup=""//"H2O;CO2;O3;N2O;CO;CH4;O2;NO;SO2;NO2;NH3;HNO3;OH;HF;HCl;HBr;HI;ClO;OCS;H2CO;HOCl;N2;HCN;CH3Cl;H2O2;C2H2;C2H6;PH3;COF2;SF6;H2S;HCOOH;HO2;O;ClNO3;NO+;HOBr;C2H4;;;;;;;;;;"
	String/G gs_IsotopePopup
	
	Variable/G gv_H2O,gv_CO2,gv_O3,gv_N2O,gv_CO,gv_CH4,gv_O2,gv_NO,gv_SO2,gv_NO2,gv_NH3,gv_HNO3
	Variable/G gv_OH,gv_HF,gv_HCl,gv_HBr,gv_HI,gv_ClO,gv_OCS,gv_H2CO,gv_HOCl,gv_N2,gv_HCN,gv_CH3Cl
	Variable/G gv_H2O2,gv_C2H2,gv_C2H6,gv_PH3,gv_COF2,gv_SF6,gv_H2S,gv_HCOOH,gv_HO2,gv_O,gv_ClNO3,gv_NOp
	Variable/G gv_HOBr,gv_dum1,gv_dum2,gv_dum3,gv_dum4,gv_dum5,gv_dum6,gv_dum7,gv_dum8,gv_dum9,gv_dum10,gv_dum11
	Variable/G gv_WaveNumStart=2240,gv_WaveNumRange=2,gv_WaveNumStep=0.0005
	Variable/G gv_PathLength=21000,gv_Pressure=60,gv_Temperature=296,gv_Threshold=1e-6
	Variable/G gv_ckTorr=1,gv_ckAllMolecules=1,gv_TheWayOfRun=1
	Variable/G gv_MoleculeSelectedNum=1,gv_IsotopeSelected=181,gv_SpectrumType=2,gv_ResetStatus=2
	Variable/G gv_wi, gv_shape,gv_userDefinedShape
	Variable/G gv_checkFixedWidth=1
	gv_H2O=0.013;gv_CO2=3.8e-4;gv_O3=3e-8;gv_N2O=3.2e-7;gv_CO=2e-7;gv_CH4=1.8e-6
	vecIso()
	
	Variable/G gv_GraphSection=1
	Variable/G gv_color=1
	
	Variable/G gv_WaveNumEnd=gv_WaveNumStart+gv_WaveNumRange, gv_computation, gv_length //global variables for ATMTRNS
	String/G gs_hitran, gs_outfil, gs_DatabasePath
	Make/O/D/N=(species) w_contint
	Make/O/D/N=(species) w_mix
	Make/O/D/N=(major_species) w_temp_switch
	Make/O/D/N=(num_waves+1) w_a
	Make/O/I/N=5 w_common_int
	for (i=0;i<48;i+=1)
		w_mix[i]=0
	endfor
	w_mix[0]=0.013;w_mix[1]=3.8e-4;w_mix[2]=3e-8;w_mix[3]=3.2e-7;w_mix[4]=2e-7;w_mix[5]=1.8e-6
	
	SetDimLabel 0, 0, ihitr, w_common_int
	SetDimLabel 0, 1, iout, w_common_int
	SetDimLabel 0, 2, temp_switch, w_common_int
	SetDimLabel 0, 3, computation, w_common_int
	SetDimLabel 0, 4, press_region, w_common_int
	//===Make color waves========
	Make/O/W/U/N=(1,3) myColors	// initially 1 row; more will be added
	
	myColors[0][]= {{0},{0},{0}}		// black in first row REB 03/28/03 0,0,0 to 65280,0,0
	myColors[1][]= {{65280},{0},{0}}	// red in new row REB 03/28/03 65535,0,0 to 65280,0,0
	myColors[2][]= {{0},{65280},{0}}	// green in new row REB 03/28/03 0,65535,0 to 0,0,65280
	myColors[3][]= {{0},{0},{65280}}	// blue in new row REB 03/28/03 0,0,65535 to 0,0,65280
	myColors[4][]= {{0},{65280},{65280}}	//Cyan in new row REB 03/28/03 0,65280,65535 to 0,52224,0
	myColors[5][]= {{65280},{0},{52224}}	// purple in new row Reb 03/28/03 65280,0,52224 to 0,52224,0
	myColors[6][]= {{65280},{43520},{0}}	// Orange in new row REB 03/28/03 65280,43520,0 to 0,52224,0
	myColors[7][]= {{39168},{0},{0}} // Brown in new row REB 03/28/03 39168,26112,0 to 34816,34816,34816
	myColors[8][]= {{39168},{39168},{0}} // Dark Yellow in new row REB 03/28/03 29440,0,58880 to 34816,34816,34816
	myColors[9][]= {{65280},{65280},{0}}	 // Yellow
	
	
		
	Return 1
End

//****************************************Saved HitranSims Window Macro***************************************************
Window HitranSims() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(65,79,634,535) /K=1 /N=HitranSims as "HitranSims"
	ModifyPanel cbRGB=(48896,65280,65280)
	SetDrawLayer UserBack
	SetDrawEnv linethick= 2,linefgc= (30464,30464,30464)
	DrawLine 193,31,193,125
	SetDrawEnv linethick= 2,linefgc= (30464,30464,30464)
	DrawLine 10,128,588,128
	SetDrawEnv linethick= 2,linefgc= (30464,30464,30464)
	DrawLine -1,373,586,373
	SetDrawEnv linethick= 2,linefgc= (30464,30464,30464)
	DrawLine 396,31,396,125
	SetDrawEnv fsize= 14,fstyle= 3,textrgb= (65280,0,0)
	DrawText 10,149,"MOLECULES:  mixing ratio"
	SetDrawEnv fsize= 11
	DrawText 411,107,"Shape: User Defined"
	SetDrawEnv fillpat= 0,fillfgc= (0,52224,0)
	SetDrawEnv save
	DrawLine 473,373,473,460
	SetVariable set_DatabasePath,pos={75,6},size={486,18},title="Path of Database"
	SetVariable set_DatabasePath,value= gs_Database
	SetVariable set_OutputFilename_1,pos={41,50},size={140,16},title="Output name:"
	SetVariable set_OutputFilename_1,value= gs_OutputFileName
	SetVariable set_WaveNum,pos={12,68},size={168,16},title="Wavenumber start:"
	SetVariable set_WaveNum,limits={200,40000,10},value= gv_WaveNumStart
	SetVariable set_WaveNumInterval,pos={73,87},size={107,16},title="Interval:"
	SetVariable set_WaveNumInterval,limits={1e-05,18000,0.1},value= gv_WaveNumRange
	SetVariable set_WaveNumStep,pos={87,106},size={93,16},title="Step:"
	SetVariable set_WaveNumStep,limits={0.0001,100,0.0001},value= gv_WaveNumStep
	PopupMenu popup_type,pos={201,50},size={157,21},proc=PopMenuProc_SpectrumType,title="Type"
	PopupMenu popup_type,mode=2,popvalue="      Voigt  (int press)    ",value= #"\" Gaussian (low press)  ;      Voigt  (int press)    ;Lorentzian (high press)\""
	SetVariable set_pressure,pos={209,72},size={118,16},title="Pressure:"
	SetVariable set_pressure,limits={0.0001,1000,10},value= gv_Pressure
	SetVariable set_temperature,pos={409,33},size={128,16},title="Temperature:"
	SetVariable set_temperature,limits={0.0001,1000,10},value= gv_Temperature
	PopupMenu popup_AtmTorr,pos={310,68},size={49,21},proc=PopMenuProc_1,title=" "
	PopupMenu popup_AtmTorr,mode=2,popvalue="torr ",value= #"\"atm;torr \""
	SetVariable set_pathlength,pos={209,89},size={171,16},title="Pathlength (cm):"
	SetVariable set_pathlength,limits={0,100000,100},value= gv_PathLength
	SetVariable set_Threshold,pos={240,107},size={140,16},proc=SetVarProc_SetThreshold,title="Threshold:"
	SetVariable set_Threshold,limits={0,1,0.0001},value= gv_Threshold
	SetVariable setvar1_0,pos={20,157},size={85,16},title="H2O:",fSize=9
	SetVariable setvar1_0,limits={0,1,1e-05},value= w_mix[0]
	SetVariable setvar1_1,pos={160,157},size={79,16},title="OH:",fSize=9
	SetVariable setvar1_1,limits={0,1,1e-05},value= w_mix[12]
	SetVariable setvar1_2,pos={283,157},size={91,16},title="H2O2:",fSize=9
	SetVariable setvar1_2,limits={0,1,1e-05},value= w_mix[24]
	SetVariable setvar1_3,pos={418,157},size={90,16},title="HOBr:",fSize=9
	SetVariable setvar1_3,limits={0,1,1e-05},value= w_mix[36]
	SetVariable setvar1_4,pos={20,174},size={85,16},title="CO2:",fSize=9
	SetVariable setvar1_4,limits={0,1,1e-05},value= w_mix[1]
	SetVariable setvar1_5,pos={162,174},size={77,16},title="HF:",fSize=9
	SetVariable setvar1_5,limits={0,1,1e-05},value= w_mix[13]
	SetVariable setvar1_6,pos={284,174},size={90,16},title="C2H2:",fSize=9
	SetVariable setvar1_6,limits={0,1,1e-05},value= w_mix[25]
	SetVariable setvar1_7,pos={414,174},size={94,16},title=" C2H4:",fSize=9
	SetVariable setvar1_7,limits={0,1,1e-05},value= w_mix[37]
	SetVariable setvar1_8,pos={27,191},size={78,16},title="O3:",fSize=9
	SetVariable setvar1_8,limits={0,1,1e-05},value= w_mix[2]
	SetVariable setvar1_9,pos={159,191},size={80,16},title="HCl:",fSize=9
	SetVariable setvar1_9,limits={0,1,1e-05},value= w_mix[14]
	SetVariable setvar1_10,pos={284,191},size={90,16},title="C2H6:",fSize=9
	SetVariable setvar1_10,limits={0,1,1e-05},value= w_mix[26]
	SetVariable setvar1_11,pos={408,191},size={100,16},title="CH3OH:",fSize=9
	SetVariable setvar1_11,limits={0,1,1e-05},value= w_mix[38]
	SetVariable setvar1_12,pos={20,208},size={85,16},title="N2O:",fSize=9
	SetVariable setvar1_12,format="%g",limits={0,1,1e-05},value= w_mix[3]
	SetVariable setvar1_13,pos={157,208},size={82,16},title="HBr:",fSize=9
	SetVariable setvar1_13,limits={0,1,1e-05},value= w_mix[15]
	SetVariable setvar1_14,pos={291,208},size={83,16},title="PH3:",fSize=9
	SetVariable setvar1_14,limits={0,1,1e-05},value= w_mix[27]
	SetVariable setvar1_15,pos={412,208},size={96,16},title="CH3Br:",fSize=9
	SetVariable setvar1_15,limits={0,1,1e-05},value= w_mix[39]
	SetVariable setvar1_16,pos={26,225},size={79,16},title="CO:",fSize=9
	SetVariable setvar1_16,limits={0,1,1e-05},value= w_mix[4]
	SetVariable setvar1_17,pos={166,225},size={73,16},title="HI:",fSize=9
	SetVariable setvar1_17,limits={0,1,1e-05},value= w_mix[16]
	SetVariable setvar1_18,pos={283,225},size={91,16},title="COF2:",fSize=9
	SetVariable setvar1_18,limits={0,1,1e-05},value= w_mix[28]
	SetVariable setvar1_19,pos={408,225},size={101,16},title="CH3CN:",fSize=9
	SetVariable setvar1_19,limits={0,1,1e-05},value= w_mix[40]
	SetVariable setvar1_20,pos={21,242},size={84,16},title="CH4:",fSize=9
	SetVariable setvar1_20,limits={0,1,1e-05},value= w_mix[5]
	SetVariable setvar1_21,pos={158,242},size={81,16},title="CIO:",fSize=9
	SetVariable setvar1_21,limits={0,1,1e-05},value= w_mix[17]
	SetVariable setvar1_22,pos={291,242},size={83,16},title="SF6:",fSize=9
	SetVariable setvar1_22,limits={0,1,1e-05},value= w_mix[29]
	SetVariable setvar1_23,pos={420,242},size={90,16},title=" CF4:",fSize=9
	SetVariable setvar1_23,limits={0,1,1e-05},value= w_mix[41]
	SetVariable setvar1_24,pos={24,259},size={81,16},title=" O2:",fSize=9
	SetVariable setvar1_24,limits={0,1,1e-05},value= w_mix[6]
	SetVariable setvar1_25,pos={153,259},size={86,16},title="OCS:",fSize=9
	SetVariable setvar1_25,limits={0,1,1e-05},value= w_mix[18]
	SetVariable setvar1_26,pos={290,259},size={84,16},title="H2S:",fSize=9
	SetVariable setvar1_26,limits={0,1,1e-05},value= w_mix[30]
	SetVariable setvar1_27,pos={441,259},size={67,16},title=" :",fSize=9
	SetVariable setvar1_27,limits={0,1,1e-05},value= w_mix[42]
	SetVariable setvar1_28,pos={26,276},size={79,16},title="NO:",fSize=9
	SetVariable setvar1_28,limits={0,1,1e-05},value= w_mix[7]
	SetVariable setvar1_29,pos={147,276},size={92,16},title="H2CO:",fSize=9
	SetVariable setvar1_29,limits={0,1,1e-05},value= w_mix[19]
	SetVariable setvar1_30,pos={273,276},size={101,16},title="HCOOH:",fSize=9
	SetVariable setvar1_30,limits={0,1,1e-05},value= w_mix[31]
	SetVariable setvar1_31,pos={441,276},size={67,16},title=" :",fSize=9
	SetVariable setvar1_31,limits={0,1,1e-05},value= w_mix[43]
	SetVariable setvar1_32,pos={20,293},size={85,16},title="SO2:",fSize=9
	SetVariable setvar1_32,limits={0,1,1e-05},value= w_mix[8]
	SetVariable setvar1_33,pos={151,293},size={88,16},title="HOCl:",fSize=9
	SetVariable setvar1_33,limits={0,1,1e-05},value= w_mix[20]
	SetVariable setvar1_34,pos={289,293},size={85,16},title="HO2:",fSize=9
	SetVariable setvar1_34,limits={0,1,1e-05},value= w_mix[32]
	SetVariable setvar1_35,pos={441,293},size={67,16},title=" :",fSize=9
	SetVariable setvar1_35,limits={0,1,1e-05},value= w_mix[44]
	SetVariable setvar1_36,pos={20,310},size={85,16},title="NO2:",fSize=9
	SetVariable setvar1_36,limits={0,1,1e-05},value= w_mix[9]
	SetVariable setvar1_37,pos={162,310},size={77,16},title="N2:",fSize=9
	SetVariable setvar1_37,limits={0,1,1e-05},value= w_mix[21]
	SetVariable setvar1_38,pos={302,310},size={72,16},title="O:",fSize=9
	SetVariable setvar1_38,limits={0,1,1e-05},value= w_mix[33]
	SetVariable setvar1_39,pos={441,310},size={67,16},title=" :",fSize=9
	SetVariable setvar1_39,limits={0,1,1e-05},value= w_mix[45]
	SetVariable setvar1_40,pos={21,327},size={84,16},title="NH3:",fSize=9
	SetVariable setvar1_40,limits={0,1,1e-05},value= w_mix[10]
	SetVariable setvar1_41,pos={154,327},size={85,16},title="HCN:",fSize=9
	SetVariable setvar1_41,limits={0,1,1e-05},value= w_mix[22]
	SetVariable setvar1_42,pos={280,327},size={94,16},title="ClNO3:",fSize=9
	SetVariable setvar1_42,limits={0,1,1e-05},value= w_mix[34]
	SetVariable setvar1_43,pos={416,327},size={94,16},title="HONO:",fSize=9
	SetVariable setvar1_43,limits={0,1,1e-05},value= w_mix[46]
	SetVariable setvar1_44,pos={13,344},size={92,16},title="HNO3:",fSize=9
	SetVariable setvar1_44,limits={0,1,1e-05},value= w_mix[11]
	SetVariable setvar1_45,pos={146,344},size={93,16},title="CH3Cl:",fSize=9
	SetVariable setvar1_45,limits={0,1,1e-05},value= w_mix[23]
	SetVariable setvar1_46,pos={289,344},size={85,16},title="NO+:",fSize=9
	SetVariable setvar1_46,limits={0,1,1e-05},value= w_mix[35]
	SetVariable setvar1_47,pos={424,344},size={86,16},title="SO3:",fSize=9
	SetVariable setvar1_47,limits={0,1,1e-05},value= w_mix[47]
	Button button0,pos={205,133},size={59,19},proc=ButtonProc_setzero,title="Reset To:"
	PopupMenu popup_SelectMolecules,pos={195,29},size={164,21},proc=PopMenu_allMolecs_or_Isotope,title="Select"
	PopupMenu popup_SelectMolecules,mode=1,popvalue=" All Molecules (default)",value= #"\" All Molecules (default); Individual (for isotope)\""
	Button button_LoadnNewGraph,pos={13,383},size={87,57},proc=ButtonProc_LoadnPlot,title="Run/New Graph"
	Button button_LoadnAppend,pos={106,383},size={74,58},proc=ButtonProc_LoadnAppend,title="Run/Append"
	PopupMenu popup_ResetStatus,pos={268,131},size={83,21},proc=PopMenuProc_ResetSatus
	PopupMenu popup_ResetStatus,mode=2,popvalue="Atmospheric",value= #"\"      Zero      ;Atmospheric\""
	SetVariable set_inst_width,pos={410,51},size={128,16},title="Inst. width cm-1"
	SetVariable set_inst_width,limits={0,1,0.001},value= gv_wi
	SetVariable set_inst_shape,pos={409,72},size={140,16},title="Shape: Gaus 0, Lor 1"
	SetVariable set_inst_shape,limits={0,1,1},value= gv_shape
	CheckBox Shape_userdefined,pos={517,94},size={16,14},proc=CheckProc_userDedinedShape,title=""
	CheckBox Shape_userdefined,value= 0
	Button button1,pos={484,383},size={75,26},proc=ButtonProc_nonLinearFit,title="Nonlinear Fit"
	CheckBox check_fixedWidth,pos={484,420},size={71,14},proc=CheckProc_HoldLineWidth,title="Hold Width"
	CheckBox check_fixedWidth,value= 1
	SetVariable setvar0,pos={374,384},size={92,16},title="to Section"
	SetVariable setvar0,limits={1,inf,1},value= gv_GraphSection
	PopupMenu popup_Color,pos={190,383},size={21,21},proc=PopMenu_myColor,title="Trace Color"
	PopupMenu popup_Color,mode=2,popvalue="Red",value= #"\"Black;Red;Green;Blue;Cyan;Purple;Orange;Brown;Dark Yellow;Yellow\""
	CheckBox ck_addToBgk,pos={371,401},size={53,14},proc=CheckProc_Add2Bgk,title="Add To"
	CheckBox ck_addToBgk,value= 0
	PopupMenu popup_traceNames,pos={372,417},size={82,21}
	PopupMenu popup_traceNames,mode=1,popvalue="                   ",value= #"\"                   \""
	Button bnt_HitranPath,pos={9,3},size={57,25},proc=ButtonProc_PathofHitranDB,title="Browse"
	Button button_SaveDefaults,pos={190,405},size={50,25},proc=ButtonProc_SaveDefaults,title="Save"
	Button button_LoadDefaults,pos={245,405},size={50,25},proc=ButtonProc_LoadDefaults,title="Load"
	
	LoadDefaults()
EndMacro

Function Set_Menu_Variables()
	SetVariable set_DatabasePath,value= gs_Database
	SetVariable set_OutputFilename_1,value= gs_OutputFileName
	SetVariable set_WaveNum,limits={200,40000,10},value= gv_WaveNumStart
	SetVariable set_WaveNumInterval,limits={1e-05,18000,0.1},value= gv_WaveNumRange
	SetVariable set_WaveNumStep,limits={0.0001,100,0.0001},value= gv_WaveNumStep
	SetVariable set_pressure,limits={0.0001,1000,10},value= gv_Pressure
	SetVariable set_temperature,limits={0.0001,1000,10},value= gv_Temperature
	SetVariable set_pathlength,limits={0,100000,100},value= gv_PathLength
	SetVariable set_Threshold,limits={0,1,0.0001},value= gv_Threshold
	SetVariable setvar1_0,limits={0,1,1e-05},value= w_mix[0]
	SetVariable setvar1_1,limits={0,1,1e-05},value= w_mix[12]
	SetVariable setvar1_2,limits={0,1,1e-05},value= w_mix[24]
	SetVariable setvar1_3,limits={0,1,1e-05},value= w_mix[36]
	SetVariable setvar1_4,limits={0,1,1e-05},value= w_mix[1]
	SetVariable setvar1_5,limits={0,1,1e-05},value= w_mix[13]
	SetVariable setvar1_6,limits={0,1,1e-05},value= w_mix[25]
	SetVariable setvar1_7,limits={0,1,1e-05},value= w_mix[37]
	SetVariable setvar1_8,limits={0,1,1e-05},value= w_mix[2]
	SetVariable setvar1_9,limits={0,1,1e-05},value= w_mix[14]
	SetVariable setvar1_10,limits={0,1,1e-05},value= w_mix[26]
	SetVariable setvar1_11,limits={0,1,1e-05},value= w_mix[38]
	SetVariable setvar1_12,format="%g",limits={0,1,1e-05},value= w_mix[3]
	SetVariable setvar1_13,limits={0,1,1e-05},value= w_mix[15]
	SetVariable setvar1_14,limits={0,1,1e-05},value= w_mix[27]
	SetVariable setvar1_15,limits={0,1,1e-05},value= w_mix[39]
	SetVariable setvar1_16,limits={0,1,1e-05},value= w_mix[4]
	SetVariable setvar1_17,limits={0,1,1e-05},value= w_mix[16]
	SetVariable setvar1_18,limits={0,1,1e-05},value= w_mix[28]
	SetVariable setvar1_19,limits={0,1,1e-05},value= w_mix[40]
	SetVariable setvar1_20,limits={0,1,1e-05},value= w_mix[5]
	SetVariable setvar1_21,limits={0,1,1e-05},value= w_mix[17]
	SetVariable setvar1_22,limits={0,1,1e-05},value= w_mix[29]
	SetVariable setvar1_23,limits={0,1,1e-05},value= w_mix[41]
	SetVariable setvar1_24,limits={0,1,1e-05},value= w_mix[6]
	SetVariable setvar1_25,limits={0,1,1e-05},value= w_mix[18]
	SetVariable setvar1_26,limits={0,1,1e-05},value= w_mix[30]
	SetVariable setvar1_27,limits={0,1,1e-05},value= w_mix[42]
	SetVariable setvar1_28,limits={0,1,1e-05},value= w_mix[7]
	SetVariable setvar1_29,limits={0,1,1e-05},value= w_mix[19]
	SetVariable setvar1_30,limits={0,1,1e-05},value= w_mix[31]
	SetVariable setvar1_31,limits={0,1,1e-05},value= w_mix[43]
	SetVariable setvar1_32,limits={0,1,1e-05},value= w_mix[8]
	SetVariable setvar1_33,limits={0,1,1e-05},value= w_mix[20]
	SetVariable setvar1_34,limits={0,1,1e-05},value= w_mix[32]
	SetVariable setvar1_35,limits={0,1,1e-05},value= w_mix[44]
	SetVariable setvar1_36,limits={0,1,1e-05},value= w_mix[9]
	SetVariable setvar1_37,limits={0,1,1e-05},value= w_mix[21]
	SetVariable setvar1_38,limits={0,1,1e-05},value= w_mix[33]
	SetVariable setvar1_39,limits={0,1,1e-05},value= w_mix[45]
	SetVariable setvar1_40,limits={0,1,1e-05},value= w_mix[10]
	SetVariable setvar1_41,limits={0,1,1e-05},value= w_mix[22]
	SetVariable setvar1_42,limits={0,1,1e-05},value= w_mix[34]
	SetVariable setvar1_43,limits={0,1,1e-05},value= w_mix[46]
	SetVariable setvar1_44,limits={0,1,1e-05},value= w_mix[11]
	SetVariable setvar1_45,limits={0,1,1e-05},value= w_mix[23]
	SetVariable setvar1_46,limits={0,1,1e-05},value= w_mix[35]
	SetVariable setvar1_47,limits={0,1,1e-05},value= w_mix[47]
	SetVariable set_inst_width,limits={0,1,0.001},value= gv_wi
	SetVariable set_inst_shape,limits={0,1,1},value= gv_shape
End

//*******************************The Code Begins Here**************************************************//

Function ButtonProc_PathofHitranDB(ctrlName) : ButtonControl
	String ctrlName
	String tempstring
	Variable refNum
	SVAR gs_Database, gs_HitranFileName, gs_OutputFileName, gs_DatabasePath
	NVAR gv_WaveNumStart, gv_WaveNumRange, gv_WaveNumStep, gv_PathLength, gv_Pressure, gv_Temperature, gv_Threshold, gv_wi
	Wave w_mix
	gs_Database=ChangePathConvention_Higor(DoOpenFileDialog())
	
	SetVariable set_DatabasePath,limits={-Inf,Inf,1},value= gs_Database
	GetFileFolderInfo gs_Database
	gs_DatabasePath = S_Path
	gs_DatabasePath = ParseFilePath(1, gs_DatabasePath, ":", 1, 0) //truncate file name to get just folder path
	
End

//******************************Various PopMenu Control Functions************************************//
Function PopMenuProc_SpectrumType(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	Nvar gv_SpectrumType
	gv_SpectrumType=popNum
End

Function PopMenuProc_1(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	Nvar gv_ckTorr
	gv_ckTorr=popNum-1  // 1 for unit torr
End

proc PopMenu_allMolecs_or_Isotope(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	gv_ckAllMolecules=2-popNum  // 1 for AllMolecules and 0 for isotope option
	if (popNum==2)
		Panel_Isotope()                 // Call for Panel_Isotope()
	endif
End

Function PopMenuProc_TheWayOfRun(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	Nvar gv_TheWayOfRun 
	gv_TheWayOfRun = popNum
End

Function PopMenuProc_ResetSatus(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	NVAR gv_ResetStatus 
	gv_ResetStatus =  popNum
End



//******************************Various Botton Control Functions************************************//

Function ButtonProc_setzero(ctrlName) : ButtonControl					 // call to set all molecule concentration 
	String ctrlName
	Reset_MixingRatio( )
End

Function ButtonPro_Shellout(ctrlName) : ButtonControl					 // Doing ShellOut to Run Select2004.exe or Atmtrns.exe
	String ctrlName
	
	Nvar gv_TheWayOfRun //1=both, 2=select2004 only, 3=atmtrns only
	Nvar gv_WaveNumRange
	NVAR gv_WaveNumStep
	SVAR gs_HitranFileName
	SVAR gs_OutputFileName
	NVAR gv_wi
	SVAR gs_DatabasePath
	NewPath/O/Z Path_of_Hitran gs_DatabasePath
	
	if (gv_WaveNumRange/gv_WaveNumStep>=1e5)
		doalert 0, "Wave Interval Divided by Step Should Be Smaller Than 1e5 !" //error for wave scale
		return -1
	endif
	
	fortran_select() //Igor version of Fortran program SELECT2004
	fortran_atmtrns() //Igor version of Fortran program ATMTRNS
	
	do                                                          
		// Keep idle until the .m0 file is generated.  *.m0 file is used in atmtrans_plot_transmission() procedure
		
	while (stringmatch(IndexedFile(Path_of_Hitran,0,".m0"),""))
	
	return 1
End


proc ButtonProc_LoadnPlot(ctrlName) : ButtonControl        // Doing Load and New Graph
	String ctrlName
	ButtonPro_Shellout("")
	atmtrans_plot_transmission("New")
	//Clean_dat_up()
End

proc ButtonProc_LoadnAppend(ctrlName) : ButtonControl				 // Doing Load and Append to Graph
	String ctrlName
	ButtonPro_Shellout("")
	atmtrans_plot_transmission("Append")
	//Clean_dat_up()
End

proc ButtonProc_SaveDefaults(ctrlName) : ButtonControl
	String ctrlName
	SaveDefaults()
End

proc ButtonProc_LoadDefaults(ctrlName) : ButtonControl
	String ctrlName
	LoadDefaults()
End


//******************************Various Function and Proc Being Called in Control Botton Functions************************************//

Function SaveDefaults()

	Variable/G gv_WaveNumStart, gv_WaveNumRange, gv_WaveNumStep, gv_PathLength, gv_Pressure, gv_Temperature, gv_Threshold, gv_ckTorr, gv_SpectrumType
	String/G gs_HitranFileName, gs_OutputFileName, gs_Database
	Wave w_mix
	Wave/T ws_MolecuName
	Variable refNum, i
	
	Open/P=Igor refNum as "hitran.sio"
	
	fprintf refNum, "%s;\t\tDatabase PAR file\r", gs_Database
	fprintf refNum, "%s;\t\tHitran file name\r", gs_HitranFileName
	fprintf refNum, "%s;\t\tOutput file name\r", gs_OutputFileName
	fprintf refNum, "%d;\t\tWave number start\r", gv_WaveNumStart
	fprintf refNum, "%d;\t\t\tWave number range\r", gv_WaveNumRange
	fprintf refNum, "%g;\t\tWave number resolution\r", gv_WaveNumStep
	fprintf refNum, "%g;\t\tTemperature\r", gv_Temperature
	fprintf refNum, "%g;\t\t\tPressure\r", gv_Pressure
	fprintf refNum, "%d;\t\t\tPressure units - 0 for atm, 1 for torr\r", gv_ckTorr
	fprintf refNum, "%d;\t\t\tPressure region\r", gv_SpectrumType
	fprintf refNum, "%g;\t\tPath length\r", gv_PathLength
	fprintf refNum, "%g;\t\tThreshold\r", gv_Threshold
	for (i=0; i < 48; i+=1)
		fprintf refNum, "%g;\t\t%s\r", w_mix[i], ws_MolecuName[i][0]
	endfor
	
	Close refNum
	
End

Function LoadDefaults()

	Variable/G gv_WaveNumStart, gv_WaveNumRange, gv_WaveNumStep, gv_PathLength, gv_Pressure, gv_Temperature, gv_Threshold, gv_ckTorr, gv_SpectrumType
	String/G gs_HitranFileName, gs_OutputFileName, gs_Database, gs_DatabasePath
	Wave w_mix
	Variable refNum, i
	String tempString
	
	GetFileFolderInfo/Z=1/P=Igor "hitran.sio"
	if(V_flag==0)
	
	Open/R/P=Igor refNum as "hitran.sio"
	
	FReadLine/T=";" refNum, tempString //read in parameter
	gs_Database = RemoveEnding(tempString) //remove semicolon terminator character
	FReadLine refNum, tempString //read in rest of the line and throw away
	
	FReadLine/T=";" refNum, tempString
	gs_HitranFileName = RemoveEnding(tempString)
	FReadLine refNum, tempString
	
	FReadLine/T=";" refNum, tempString
	gs_OutputFileName = RemoveEnding(tempString)
	FReadLine refNum, tempString
	
	FReadLine/T=";" refNum, tempString
	gv_WaveNumStart = str2num(tempString)
	FReadLine/T=num2char(13) refNum, tempString
	
	FReadLine/T=";" refNum, tempString
	gv_WaveNumRange = str2num(tempString)
	FReadLine/T=num2char(13) refNum, tempString
	
	FReadLine/T=";" refNum, tempString
	gv_WaveNumStep = str2num(tempString)
	FReadLine/T=num2char(13) refNum, tempString
	
	FReadLine/T=";" refNum, tempString
	gv_Temperature = str2num(tempString)
	FReadLine/T=num2char(13) refNum, tempString
	
	FReadLine/T=";" refNum, tempString
	gv_Pressure = str2num(tempString)
	FReadLine/T=num2char(13) refNum, tempString
	
	FReadLine/T=";" refNum, tempString
	gv_ckTorr = str2num(tempString)
	FReadLine/T=num2char(13) refNum, tempString
	
	FReadLine/T=";" refNum, tempString
	gv_SpectrumType = str2num(tempString)
	FReadLine/T=num2char(13) refNum, tempString
	
	FReadLine/T=";" refNum, tempString
	gv_PathLength = str2num(tempString)
	FReadLine/T=num2char(13) refNum, tempString
	
	FReadLine/T=";" refNum, tempString
	gv_Threshold = str2num(tempString)
	FReadLine/T=num2char(13) refNum, tempString
	
	for (i=0; i<48; i+=1)
		FReadLine/T=";" refNum, tempString
		w_mix[i] = str2num(tempString)
		FReadLine/T=num2char(13) refNum, tempString
	endfor
	
	GetFileFolderInfo gs_Database
	gs_DatabasePath = S_Path
	gs_DatabasePath = ParseFilePath(1, gs_DatabasePath, ":", 1, 0)
	
	Close refNum
	
	endif
	Set_Menu_Variables()

End

Function Clean_dat_up()

	

End

Function Reset_MixingRatio( )
	
	NVAR gv_ResetStatus
	Variable i
	Wave w_mix
	for (i=0;i<48;i+=1)
		w_mix[i] = 0
	endfor
	if (gv_ResetStatus==2)		 // reset to atmosphere concentration
		w_mix[0]=0.013;w_mix[1]=3.2e-4;w_mix[2]=3e-8;w_mix[3]=3e-7;w_mix[4]=2e-7;w_mix[5]=1.8e-6
	endif

End

Proc atmtrans_plot_transmission(HowtoPlot)										//Doing Load and New Graph
	String HowtoPlot
	//SVAR gs_DatabasePath, gs_hitran, gs_OutputFileName
	String atmfile = gs_OutputFileName
	String filename, transname, transname_orig
	Variable firstx, lastx, v_deltax
	
	filename=gs_DatabasePath+gs_outfil
	transname="trans_"+gs_OutputFileName
	LoadWave/J/D/N=freq/O/K=0/L={0,0,3,0,0} filename
	LoadWave/J/N=abs/O/K=0/L={0,3,0,0,0} filename
	
	
	Variable j=1
	Variable NamePosition=0
	
	do
		NamePosition=strsearch(WaveList("*",";",""),transname,NamePosition)
		if (NamePosition == -1)
			break
		endif
		transname = "trans_"+atmfile+"_"+num2str(j)
		j+=1
	while (NamePosition != -1)
			 
	make/n=(numpnts(abs0))/D $transname
	

	$transname =exp(-abs0)
	firstx=freq0[0]
	v_deltax=freq0[1]
	SetScale/P x firstx,v_deltax,"", $transname
	
	transname_orig=transname+"_orig"
	duplicate/o $transname $transname_orig
	String/G gs_transname_orig=transname_orig
	
	if (gv_userDefinedShape==1)  //convolve with user defined instrumental line width
		if  (!exists("instrumental_userDefined"))
			DoAlert 0, "User Defined Instrumental Line Does Not Exist !\n You Could Use spe Loader to Load the 0.1 Torr Spectrum \n After that use Macro: MakeInstrumentalFromCursors() \nto get the correct Instrumental Line"
			return -1
		endif
		//transname_orig=transname+"_orig"
		//duplicate/o $transname $transname_orig
		$transname=1-$transname
		
		Rotate_to_MiddleZero_Higor(instrumental_userdefined)  // Wrapped around function to center
		
		convolve/A instrumental_userDefined $transname
		$transname=1-$transname
	else
		if (gv_wi>0)								//convolve with instrumental line width
			//transname_orig=transname+"_orig"
			//duplicate/o $transname $transname_orig
			instrumental_template(v_deltax,gv_wi,gv_shape)
			$transname=1-$transname
			convolve/A instrumental $transname
			$transname=1-$transname
		endif
	endif
	
	if (cmpstr(HowtoPlot, "DontPlot")==0)
		//Clear_files()
		return 0
	endif
	
	String sPressType
	if (gv_ckTorr)
		sPressType = " torr"
	else
		sPressType = " atm"
	endif
	
	String sSpecies=""
	if (gv_ckAllMolecules==1)
		variable i=0
		do
			if (w_mix[i] != 0)
				sSpecies = sSpecies +  ws_MolecuName[i]+" " +num2str( w_mix[i]) + ": "
			endif
			i+=1
		while (i<48)
	else
		sSpecies=ws_MolecuName[gv_MoleculeSelectedNum-1]+" " +num2str( w_mix[gv_MoleculeSelectedNum-1]) + ": "+"Isotope: " + num2str(gv_IsotopeSelected)+": "
	endif
	
	//======The layout of plots=================
	
	Variable R,G,B
	R=myColors[gv_color-1][0];G=myColors[gv_color-1][1];B=myColors[gv_color-1][2]
			
	if (cmpstr(HowtoPlot, "New")==0)
		display/L=L1/B=B1 $transname
		Label L1 "TRANSMISSION"
		Label B1 "WAVENUMBER (cm-1)"
		ModifyGraph freePos(L1)={0,B1},freePos(B1)={0,L1}
		ModifyGraph margin(left)=60,margin(bottom)=50
		ModifyGraph lblPos(L1)=62-0.07*62,lblPos(B1)=50-0.07*50
		
		ModifyGraph rgb($transname)=(R,G,B)
		Textbox/C/N=text0/F=0 "\K(R,G,B)"+"\s"+"("+ transname +")"+sSpecies+"P = " + num2str(gv_Pressure)+ sPressType +":"+"L = "+num2str(gv_PathLength)+ " cm: "+"T = "+num2str(gv_Temperature)+" K: "+"lw = "+ num2str(gv_wi)+" cm-1"
	endif
	
	if (cmpstr(HowtoPlot, "Append")==0)
		
		//-------------Find Axis Number: L?--------------------------------------------- 
		Variable Pnselect=gv_GraphSection
		String strlist=AxisList("")
		Variable numInList=ItemsInList(strlist,";")
		Variable numpanel=numInList/2    // always have pair of L and B
		Variable n=numpanel,k
		if (Pnselect>=numpanel+1)
			Pnselect=numpanel+1
			n+=1
			k=1  // new axis
		endif
		//-------------------------------------------------------------------------------------------
		
		//-----------------------Add transmission to previous trace, if asked-----------------------
		ControlInfo ck_addToBgk 
		Variable vChkAdd2Bgk=V_value   // vChkAdd2Bgk=1, add the calculated trace to selected background trace, do it at the absorbance base
		if (vChkAdd2Bgk==1)
			ControlInfo popup_traceNames   // find the selected background trace name
			String bgkwname=S_value
			$transname=exp(ln($transname)+ln($bgkwname))  // Add in absorbance base
			//----reorder the traces, so $bgkwname is on the top--------------------
			//	strlist=TraceNameList("",";",1)
			//	numInList=ItemsInList(strlist,";")
			//	Variable ii=0 
			//	do
			//		ReorderTraces $bgkwname,{$StringFromList(ii,strlist,";")}
			//		ii+=1
			//	while (ii<numInList)
			//-------------------------------------------------------------------------------
		endif
		//-------------------------------------------------------------------------------------------
		
		
		AppendToGraph/L=$("L"+num2str(Pnselect))/B=$("B"+ num2str(Pnselect)) $transname
		if (vChkAdd2Bgk==1)
			ReorderTraces $bgkwname,{$transname}
			ModifyGraph mode($transname)=7,hbFill($transname)=2,toMode($transname)=1
		endif
		
		//---------------Color control--------------------------------------------------
		//Variable R,G,B
		
		//R=myColors[gv_color-1][0];G=myColors[gv_color-1][1];B=myColors[gv_color-1][2]
		
		ModifyGraph rgb($transname)=(R,G,B)
		ModifyGraph axRGB($("L"+num2str(Pnselect)))=(R,G,B)	
		ModifyGraph tlblRGB($("L"+num2str(Pnselect)))=(R,G,B)
		ModifyGraph alblRGB($("L"+num2str(Pnselect)))=(R,G,B)	
		
		appendtext/N=text0 "\K(R,G,B)"+"\s"+"("+ transname +")"+sSpecies+"P = " + num2str(gv_Pressure)+ sPressType +":"+"L = "+num2str(gv_PathLength)+ " cm: "+"T = "+num2str(gv_Temperature)+" K: "+"lw = "+ num2str(gv_wi)+" cm-1"
		
		//----------------------------------------------------------------------------------
		
		
		
		//-----------if new section, rearrange the plot layout--------------
		if (k==1)
			Variable axHs,axLs
		
			Variable axLength=1/n
			Variable gap=0.3*axLength
			String Lstr,Bstr
			i=0
			
			do  // for (i=0;i<n;i+=1)
		
				LStr="L"+num2str(i+1)
				BStr="B"+num2str(i+1)
				//yStr=strPrefix+spStr+num2str(isp)
				axHs=1-i*axLength
				axLS=1-(i+1)*axLength+gap
				print Lstr
				ModifyGraph axisEnab($LStr)={axLS,axHS}
				ModifyGraph freePos($LStr)={0,$BStr},freePos($Bstr)={0,$LStr}
				Label $(Bstr) ""
				Label $(Lstr) ""
				i+=1
			while  (i<n)	      //endfor
		endif
		//-------------------------------------------------------------------------------------------
		
		ModifyGraph margin(left)=60,margin(bottom)=50
		Label $("B"+num2str(n)) "WAVENUMBER (cm-1)"
		Label $("L"+num2str(round(n/2))) "TRANSMISSION"
		ModifyGraph lblPos($("L"+num2str(round(n/2))))=60-0.07*60,lblPos($("B"+num2str(n)))=50-0.07*50
		ModifyGraph fSize=8
	endif

	//Clear_files()
End

//Function Clear_files()
//	SVAR gs_OutputFileName
//	Make/O/T ws_Rr = {"cd\\Hitran","del Scratch3", "del " +gs_OutputFileName+".m0"}
//	//Make/O/T ws_Rr = {"cd\\Hitran","del select.in","del atmtrns.i0","del Scratch3", "del " +gs_OutputFileName+".m0"}
//	SaveTextWave("", "C:\Hitran\Rr.bat",  ws_Rr)														
//	ExecuteScriptText "C:\\Hitran\\Rr.bat"
//End

Function SaveTextWave(pathName, fileName, tw)								// Function from Igor people to protect \
	Wave/T tw
	String pathName		// Name of Igor symbolic path or "".
	String fileName			// file name, partial path or full path.
	
	Variable refNum
	Open/P=$pathName refNum as fileName
	wfprintf refNum, "%s\r\n", tw
	Close refNum
End



//************************** Isotope Panel********************************
// Called by proc PopMenu_allMolecs_or_Isotope(ctrlName,popNum,popStr) : PopupMenuControl

Window Panel_Isotope() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(264.75,73.25,507,175.25)
	ModifyPanel cbRGB=(65280,65280,48896)
	SetDrawLayer UserBack
	SetDrawEnv fstyle= 1,textrgb= (65280,16384,16384)
	DrawText 17,29,"Select a Molecule"
	SetDrawEnv fstyle= 1,textrgb= (65280,16384,16384)
	DrawText 19,61,"Select an Isotope"
	Set_gs_allMoleculesPopup()  
	Set_gs_IsotopePopup(ws_MolecuName[0])
	PopupMenu Pop_MoleculeName,pos={142,11},size={59,21},proc=PopMenuProc_MoleculeName
	PopupMenu Pop_MoleculeName,mode=1,value= #"gs_allMoleculesPopup"
	//	PopupMenu Pop_IsotopeName,pos={142,44},size={55,21},proc=PopMenuProc_selectIsotope
	PopupMenu Pop_IsotopeName,pos={142,44},size={55,21}
	PopupMenu Pop_IsotopeName,mode=2,value= new_Set_gs_IsotopePopup()
	Button button0,pos={19,73},size={50,20},proc=ButtonProc_ClosePanel_isotope,title="Close"
EndMacro


Function Set_gs_allMoleculesPopup()                       // Only been called once to generate name list for Molecule Popup menu
	
	SVAR gs_allMoleculesPopup
	Wave/T ws_MolecuName
	
	Variable i=1
	gs_allMoleculesPopup = ws_MolecuName[0]
	do
		gs_allMoleculesPopup+=";" + ws_MolecuName[i]
		i+=1
	while (i<48)
End

//#pragma rtGlobals=0
Function PopMenuProc_MoleculeName(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	NVAR gv_MoleculeSelectedNum
	SVAR gs_IsotopePopup
	
	gv_MoleculeSelectedNum=popNum						//selects specfic molecules
	if (cmpstr(popStr,"NO+")==0)
		popStr="NOp"
	endif
	Set_gs_IsotopePopup(popStr) 	
	//print "Hello"
	//String str=gs_IsotopePopup						// return gs_IsotopePopup to dynamically update the isotope pattern corresponding to the selected molecule
	//PopupMenu Pop_IsotopeName value = #gs_IsotopePopup
End

Function/T Set_gs_IsotopePopup(MolecName)
	string MolecName
	Duplicate/O $("w_"+ MolecName+"_Isotope" ) w_isotope
	Variable WaveNum = numpnts(w_isotope)
	Variable i=1
	SVAR gs_IsotopePopup
	gs_IsotopePopup = num2str (w_isotope[0])
	do
		gs_IsotopePopup+=";" + num2str (w_isotope[i])
		i+=1
	while (i<WaveNum)
	KillWaves  w_isotope
	return gs_isotopepopup
End
Function/T new_Set_gs_IsotopePopup()
	ControlInfo Pop_MoleculeName 
	String MolecName = S_value
	Duplicate/O $("w_"+ MolecName+"_Isotope" ) w_isotope
	Variable WaveNum = numpnts(w_isotope)
	Variable i=1
	SVAR gs_IsotopePopup
	gs_IsotopePopup = num2str (w_isotope[0])
	do
		gs_IsotopePopup+=";" + num2str (w_isotope[i])
		i+=1
	while (i<WaveNum)
	KillWaves  w_isotope
	return gs_isotopepopup
End
Function PopMenuProc_selectIsotope(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	NVAR gv_IsotopeSelected
	gv_IsotopeSelected = 	str2num(popStr)
End

Function ButtonProc_ClosePanel_isotope(ctrlName) : ButtonControl
	String ctrlName
	DoWindow/K Panel_Isotope
End

//************************** Isotope Panel End here********************************


function instrumental_template(delta,laser_width,laser_shape)
	variable delta,laser_width,laser_shape
	variable  wi

	variable center,lorentz_area, boxcar_area
	if(laser_width>0)
		//		if (laser_width<=delta)
		//				laser_width=delta						// execute if condition is true
		//		endif
		if (laser_shape==0)
			wi=laser_width												//half-width-half-max in cm-1
			make/D/o/n=(2*round(5*wi/delta)+1) instrumental					//make Gausian instrumental grid out to 5 half-widths 
			center=numpnts(instrumental)/2-0.5								//numpnts(instrumental) is odd
			instrumental=exp(-((p-center)*delta/wi)^2*ln(2))/sqrt(pi/ln(2))*delta/wi 	//normalize by sqrt(pi/ln(2))
		endif
		if (laser_shape==1)
			wi=laser_width
			make/D/o/n=(2*round(100*wi/delta)+1) instrumental					//make Lorentz instrumental grid out to 100 half-widths 
			center=numpnts(instrumental)/2-0.5								//numpnts(instrumental) is odd
			instrumental=wi/delta/((p-center)^2+(wi/delta)^2)
			lorentz_area=Area(instrumental,0,inf)
			instrumental/=lorentz_area
			print lorentz_area/(pi*wi/delta)
		endif
		if (laser_shape==2)										//BOXCAR instrumental shape (for FTIR spectra)
			wi=laser_width											//half-width in cm-1 (usually FTIR resolution/2)
			make/D/o/n=(2*round(5*wi/delta)+1) instrumental				//make BOXCAR instrumental grid out to 5 half-widths
			center=numpnts(instrumental)/2-0.5							//numpnts(instrumental) is odd
			instrumental = 0
			instrumental[center-round(wi/delta),center+round(wi/delta)]=1
			boxcar_area=Area(instrumental,0,inf)
			instrumental/=boxcar_area									//normalize to unit area
		endif

	endif	
end


proc graphprint(start,delta,finish)
	variable start,delta,finish

	variable initial, final
	initial=start-0.1*delta
	final=initial+1.2*delta
	do
		setaxis bottom initial, final
		PrintGraphs/I overview(1, 1,10, 7)
		initial+=delta
		final+=delta
	while (final<=(finish+0.1*delta))				// as long as expression is true
endmacro


Function SetVarProc_SetThreshold(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	NVAR gv_Threshold
	if (varNum==0) 
		doalert 0, "Threshold can't be 0, 1e-6 is used instead!"
		gv_Threshold=1e-6
	endif
End

Function CheckProc_userDedinedShape(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	Variable/G gv_userDefinedShape=checked
End


//--------------------1. You need to load the 0.1 Torr Spectrum from TDLWintel----------------------
//--------------------2. Make Instrumental Function from the cursors (interpret the Spectrum to delta x shown in Hitran Panel)------

Function MakeInstrumentalFromCursors()
	NVAR gv_WaveNumStep
	// Make a subset data from the two cursor positions
	String waveCursorAIsOn = CsrWave(A)				
	String waveCursorBIsOn = CsrWave(B)	      
	If ( !stringmatch(waveCursorAIsOn, waveCursorBIsOn))
		DoAlert 0, "CursorA and CursorB are not on the same trace!"
		return -1
	endif
	Variable pntCursorAIsOn = PCsr(A)	
	Variable pntCursorBIsOn = PCsr(B)	
	If (pntCursorAIsOn==pntCursorBIsOn)
		DoAlert 0, "CursorA and CursorB are on the same point!"
		return -1
	endif
	
	// Make the instrumental wave from the cursor
	Make/D/O/N=(abs(pntCursorBIsOn-pntCursorAIsOn)) instrumental_orig,xinstrumental_orig
	
	String xwave=CsrXWave(A)
	if (stringmatch(xwave,""))
		duplicate/O $waveCursorAIsOn xwaveCursorAIsOn
		xwaveCursorAIsOn=x
	else
		duplicate/O $xwave xwaveCursorAIsOn
	endif
	
	
	If (pntCursorAIsOn<pntCursorBIsOn)
		Duplicate/O/R=[pntCursorAIsOn,pntCursorBIsOn] $waveCursorAIsOn instrumental_orig
		Duplicate/O/R=[pntCursorAIsOn,pntCursorBIsOn] xwaveCursorAIsOn xinstrumental_orig
	else
		Duplicate/O/R=[pntCursorBIsOn,pntCursorAIsOn] $waveCursorAIsOn instrumental_orig
		Duplicate/O/R=[pntCursorBIsOn,pntCursorAIsOn] xwaveCursorAIsOn xinstrumental_orig
	endif
	
	// Make the correct instrumental wave, based on the correct delta freq from the panel
	Variable deltaFreq=abs(xwaveCursorAIsOn[pntCursorBIsOn]-xwaveCursorAIsOn[pntCursorAIsOn])
	Variable pnts=floor(deltaFreq/gv_WaveNumStep)
	Make/D/O/N=(pnts) instrumental, xinstrumental
	SetScale/P x xwaveCursorAIsOn[pntCursorAIsOn],gv_WaveNumStep,"",  xinstrumental
	xinstrumental=x
	
	// interpret the instrumental wave
	instrumental=interp(xinstrumental, xinstrumental_orig,instrumental_orig)
	
	
	// Find the zero point from the first five points
	Variable zero=(instrumental[0]+instrumental[1]+instrumental[2]+instrumental[3]+instrumental[4])/5  
	instrumental=instrumental-zero
	
	// the Aera under the instrumental is 1
	Variable NormalizedFactor=sum(instrumental,-Inf,Inf)
	instrumental=instrumental/NormalizedFactor	
	
	Rotate_to_MiddleZero_Higor(instrumental)
	Duplicate/O instrumental instrumental_userDefined
	display instrumental_userDefined, instrumental
End


//----------------------NonLinear fit involving convolutions to Hitran database------------------------------
Proc ButtonProc_nonLinearFit(ctrlName) : ButtonControl
	String ctrlName
	
	ButtonPro_Shellout("")
	
	atmtrans_plot_transmission("DontPlot")   //------1. Run Hitran database based on inputs from the panel
	
	InterpWaveFromCursors_Hitran()             //------2. Put the cursors (A and B) on the wave (loaded from TDLWintel) which need to be nonlinearily fitted
	//-------3. It makes a subset of data and interprets to right delta X shown on Panel
	//-------4. It also make a subset of data from nonConvolved Hitran data (from step 1) as the fit template
	Make/O/D/N=2 pw
	pw[0]=1								//-------5. Make the initial guess to be the concentration shown in the Panel
	pw[1]=gv_wi
	
	if (gv_userDefinedShape==1) 
		Rotate_to_MiddleZero_Higor(instrumental_userdefined)
	endif
	
	CheckBox check_fixedWidth value=gv_checkFixedWidth
	
	NonlinearFitConv(gv_checkFixedWidth)		//--------6. Invoke the nonLinear fitting routine
	
End

proc NonlinearFitConv(flag)
	Variable flag
	//String noConvolHitranWave;Variable intialGuess_Conc
	PauseUpdate; Silent 1	
	
	if (flag==0)	
		FuncFit/H="00" NonLinearFit_Convolv pw fitDataSubset /X=fit_inputFromHitran /D 
	endif
	
	if (flag==1)	
		FuncFit/H="01" NonLinearFit_Convolv pw fitDataSubset /X=fit_inputFromHitran /D 
	endif
	
	duplicate/O fit_inputFromHitran fit_result
	NonLinearFit_Convolv(pw,fit_result,fit_inputFromHitran)
	Appendtograph fit_result vs fitDataSubset_x
	WaveStats/Q w_mix
	print "The Species Concentrations from the Fitting:   ", w_mix[V_maxloc]*pw[0]
	print "The Instumental Linewidth:   ", pw[1]
	
	//---Updated the fitted results in panel
	$("gv_"+ws_MolecuName[V_maxloc])=w_mix[V_maxloc]*pw[0]
	gv_wi=pw[1]
End

Function NonLinearFit_Convolv(pw,yw,xw): FitFunc
	Wave pw,yw,xw
	Wave instrumental_userDefined,instrumental
	NVAR gv_userDefinedShape,gv_WaveNumStep,gv_shape,gv_wi
	
	yw=xw^pw[0]
	yw=1-yw
	if (gv_userDefinedShape==1)  //convolve with user defined instrumental line width
		if  (!exists("instrumental_userDefined"))
			DoAlert 0, "User Defined Instrumental Line Does Not Exist !\n You Could Use spe Loader to Load the 0.1 Torr Spectrum \n After that use Macro: MakeInstrumentalFromCursors() \nto get the correct Instrumental Line"
			return -1
		endif
		convolve/A instrumental_userDefined yw
	else
		if (gv_wi>0)
			instrumental_template(gv_WaveNumStep,pw[1],gv_shape)
			convolve/A instrumental yw
		endif
	endif
	yw=1-yw
End
	

Function InterpWaveFromCursors_Hitran()
	SVAR gs_transname_orig
	NVAR gv_WaveNumStep
	Variable delta=gv_WaveNumStep

	// Make subset data from the two cursor positions
	String waveCursorAIsOn = CsrWave(A)				
	String waveCursorBIsOn = CsrWave(B)	      
	If ( !stringmatch(waveCursorAIsOn, waveCursorBIsOn))
		DoAlert 0, "CursorA and CursorB are not on the same trace!"
		return -1
	endif
	
	Variable pntCursorAIsOn = PCsr(A)	
	Variable pntCursorBIsOn = PCsr(B)	
	If (pntCursorAIsOn==pntCursorBIsOn)
		DoAlert 0, "CursorA and CursorB are on the same point!"
		return -1
	endif
	
	String xwave=CsrXWave(A)
	if (stringmatch(xwave,""))
		duplicate/O $waveCursorAIsOn xwaveCursorAIsOn
		xwaveCursorAIsOn=x
	else
		duplicate/O $xwave xwaveCursorAIsOn
	endif
	
	//---------Interpret subset data based on the delta x shown in the panel
	//---------Interpreted data are the data will be fitted, it is called "fitDataSubset".
	Variable n=floor(abs(xwaveCursorAIsOn[pntCursorAIsOn]-xwaveCursorAIsOn[pntCursorBIsOn])/delta)
	Make/O/N=(n) $(waveCursorAIsOn+"_interp")
	
	If (pntCursorAIsOn<pntCursorBIsOn)
		SetScale/P x xwaveCursorAIsOn[pntCursorAIsOn],delta,"", $(waveCursorAIsOn+"_interp")
	else
		SetScale/P x xwaveCursorAIsOn[pntCursorBIsOn],delta,"", $(waveCursorAIsOn+"_interp")
	endif
		
	Wave wprt=$(waveCursorAIsOn+"_interp")
	
	wprt=interp(x,xwaveCursorAIsOn,$waveCursorAIsOn)
	
	
	Duplicate/O $(waveCursorAIsOn+"_interp") fitDataSubset
	
	//-------Make the input data from nonConvolved hitran data.  Interpreted data above will be fitted to these input data called "fit_inputFromHitran"
	Duplicate/O fitDataSubset fit_inputFromHitran, fitDataSubset_x
	fitDataSubset_x=x
	
	duplicate/O $gs_transname_orig noConvolHitranWave_x
	noConvolHitranWave_x=x
	
	fit_inputFromHitran=interp(fitDataSubset_x,noConvolHitranWave_x,$gs_transname_orig)
 	
	// Find the minmum of fit_inputFromHitran and fitDataSubset, if not the same rotate fitDataSubset
	WaveStats fit_inputFromHitran
	Variable v0=V_minloc
	WaveStats fitDataSubset
	rotate (v0-V_minloc)/gv_WaveNumStep, fitDataSubset
 	
	//---Rotate orignial data
	make/o/n=(numpnts(xwaveCursorAIsOn)) wpoint
	wpoint=x
	Variable rp=interp(v0,xwaveCursorAIsOn,wpoint)-interp(V_minloc,xwaveCursorAIsOn,wpoint)
	rotate rp, $waveCursorAIsOn
	if (rp>0.2)
		Print "Warning:  The central freq of data is not exact and data have been shift by ", rp, " points." 
	endif
End


Function Rotate_to_MiddleZero_Higor(inputW)
	Wave inputW
	Variable i,n=numpnts(inputW), sumLeft,sumRight
	Variable phaseshift=0
	
	WaveStats/Q inputW
	rotate n/2-x2pnt(inputW,V_maxloc), inputW
	if (sum(inputW,pnt2x(inputW,n/2),inf)<0.5)
		phaseshift=1
	endif
	
	Make/O/N=(n)  deltaArea, inputW_repeat
	inputW_repeat=inputW
	Redimension/N=(2*n)  inputW_repeat
	inputW_repeat[n,2*n-1]=inputW[p-n]  // inputW_repeat has two sets of inputW
	
	sumLeft=sum( inputW_repeat,0,n/2-1)
	sumRight=sum( inputW_repeat,n/2,n-1)
	deltaArea[0]=abs(sumLeft-sumRight)
	// Now each half side moves one point to right, then calculate the area difference.
	for (i=1;i<n;i+=1)
		sumLeft=sumLeft+inputW_repeat[i+n/2-1]-inputW_repeat[i-1]
		sumRight=sumRight+inputW_repeat[i+n-1]-inputW_repeat[i+n/2-1]
		deltaArea[i]=abs(sumLeft-sumRight)
	endfor
	
	// find the points where it has minimum aera difference
	WaveStats/Q deltaArea
	variable minloc=V_minloc
	
	if (phaseshift)
		rotate -minloc-n/2, inputW
	else
		//print minloc
		rotate -minloc, inputW
	endif
	
	Variable minDelx=deltax(inputW)
	SetScale/P x -n/2*minDelx,minDelx,"", inputW
	
	WaveStats/Q inputW
	if (inputW[x2pnt(inputW,0)]<V_avg)
		if (phaseshift)
			rotate n/2, inputW //?
		else
			rotate -n/2, inputW 
		endif
		SetScale/P x -n/2*minDelx,minDelx,"", inputW
	endif
End

//-----------------Advanced fitting Routines-----------------------------------------


Function SetVarProc_gvWidth(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName
	Variable varNum
	String varStr
	String varName
	NVAR gv_wi
	gv_wi=varNum
End

proc Advanced_Fitting_Panel() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(201,41.75,483,320)
	ShowTools
	SetDrawLayer UserBack
	DrawText 15,65,"Molecule Name"
	DrawText 130,66,"Mixing Ratios"
	DrawText 16,26,"Width (only one)"
	CheckBox check_fixedWidth,pos={115,12},size={40,14},proc=CheckProc_HoldLineWidth,title="Hold"
	CheckBox check_fixedWidth,value= 1
	SetVariable setvar0,pos={18,31},size={84,16},proc=SetVarProc_gvWidth,title=" "
	SetVariable setvar0,limits={-Inf,Inf,0},value= gv_wi
	DoWindow/C Avanved_Fitting_Panel
EndMacro

Function CheckProc_HoldLineWidth(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	NVAR gv_checkFixedWidth
	gv_checkFixedWidth=checked
End

Function PopMenu_myColor(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	NVAR gv_color
	gv_color=popNum
End

Function CheckProc_Add2Bgk(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	if (checked)
		PopupMenu popup_traceNames value=TraceNameList("",";",1)
	else
		PopupMenu popup_traceNames value="                   "
	endif
End


Function InterpWaveFromCursors(delta)
	Variable delta
	if (delta==0)
		delta=0.0005
	endif
	// Make a subset data from the two cursor positions
	String waveCursorAIsOn = CsrWave(A)				
	String waveCursorBIsOn = CsrWave(B)	      
	If ( !stringmatch(waveCursorAIsOn, waveCursorBIsOn))
		DoAlert 0, "CursorA and CursorB are not on the same trace!"
		return -1
	endif
	
	Variable pntCursorAIsOn = PCsr(A)	
	Variable pntCursorBIsOn = PCsr(B)	
	If (pntCursorAIsOn==pntCursorBIsOn)
		DoAlert 0, "CursorA and CursorB are on the same point!"
		return -1
	endif
	
	String xwave=CsrXWave(A)
	if (stringmatch(xwave,""))
		duplicate/O $waveCursorAIsOn xwaveCursorAIsOn
		xwaveCursorAIsOn=x
	else
		duplicate/O $xwave xwaveCursorAIsOn
	endif
	
	Variable n=floor(abs(xwaveCursorAIsOn[pntCursorAIsOn]-xwaveCursorAIsOn[pntCursorBIsOn])/delta)
	Make/O/N=(n) $(waveCursorAIsOn+"_interp")
	
	If (pntCursorAIsOn<pntCursorBIsOn)
		SetScale/P x xwaveCursorAIsOn[pntCursorAIsOn],delta,"", $(waveCursorAIsOn+"_interp")
	else
		SetScale/P x xwaveCursorAIsOn[pntCursorBIsOn],delta,"", $(waveCursorAIsOn+"_interp")
	endif
	//duplicate/O $(waveCursorAIsOn+"_interp") $("x_"+waveCursorAIsOn+"_interp")
	
	//Wave xwprt=$("x_"+waveCursorAIsOn+"_interp")
	//xwprt=x
	
	Wave wprt=$(waveCursorAIsOn+"_interp")
	

	wprt=interp(x,xwaveCursorAIsOn,$waveCursorAIsOn)
	
	
	appendtograph $(waveCursorAIsOn+"_interp")
End


Function/S DoOpenFileDialog()
	Variable refNum
	String message = "Select a file"
	String outputPath
	
	Open/D/R/T=".par"/M=message refNum
	outputPath = S_fileName
	
	return outputPath
End

Function/T ChangePathConvention_Higor(sM)  // same procedure exists in MakePlayList.ipf
	String sM
	String s=""
	//sw=sm
	Variable i, n=strlen(sM)
	for (i=0;i<n;i+=1)
		if ((cmpstr(sM[i],":")==0))
			if (i==1)
				s+=":\\"
			else
				s+="\\"
			endif
		else
			s+=sM[i]
		endif
	Endfor
	Return s
end


Function FileExists_HitranIgor(fileName)  // return 0 if exists     // this function exist in Global_Utils.ipf
	String fileName		// File name,  full path name
						
	Variable refNum

	Open/R/Z=1 refNum as fileName
	if (V_flag==0)
		Close refNum
	endif
	return V_flag
End

Function Print_Absorbance_cursor() 
	print  -ln(csrwaveref(a)[pcsr(a)])
	//  print "Cursor B   "; -ln(csrwaveref(b)[pcsr(b)])
End
 
Function get_MoleculeNumber(str)
	String str
	Variable i
	Wave/T ws_molecuname=ws_molecuname
	for (i=0;i<numpnts(ws_molecuname);i+=1)
		if (stringmatch(Str, ws_molecuname[i])==1)
			return i
		endif
	endfor
	return -1
end

Function Get_ConvolutionCorrectionCurve(MoleculeName,ExactFrequency,Pressure_Torr,LineWidth,PathLength_cm,CalibConcentrationRange_ppb)
	String MoleculeName
	Variable ExactFrequency,Pressure_Torr,LineWidth,PathLength_cm,CalibConcentrationRange_ppb
	Variable MaxmimumLinearConcentration_ppm
	//	Automate_ConvolutionCalibartion(MoleculeName,ExactFrequency,MaxmimumLinearConcentration_ppm,Pressure_Torr,LineWidth,PathLength_cm,CalibConcentrationRange_ppm)
	Automate_ConvolutionCalibartion(MoleculeName,ExactFrequency,Pressure_Torr,LineWidth,PathLength_cm,CalibConcentrationRange_ppb)

end

Function Automate_ConvolutionCalibartion(strSpName,f0,press,lw,pathlength,cmax)
	String strSpName;Variable f0,press,lw,pathlength,cmax
	Variable c0
	SVAR gs_OutputFileName=gs_OutputFileName
	NVAR gv_userDefinedShape=gv_userDefinedShape
	NVAR gv_WaveNumRange
	//NVAR gv_WaveNumStep
	NVAR gv_WaveNumStart
	//SVAR gs_HitranFileName
	SVAR gs_OutputFileName
	SVAR gs_DatabasePath
	NVAR gv_wi
	NVAR gv_pressure
	NVAR gv_pathlength
	NVAR gv_shape
	
	// default set range to 4 cm-1
	gv_WaveNumRange=4
	gv_WaveNumStart=f0-2
	
	//-----Get molecules number based on name to set mixing ratios.
	Variable iMolecule=get_MoleculeNumber(strSpName)
	if (iMolecule==-1)
		DoAlert 0, "Wrong Molecular Name!  Try again."
		return -1
	endif
	if (iMolecule>=37)  // for C2H4
		strSpName="dum"+num2str(iMolecule-37+1)
	endif
	//	Wave w_MixRatio=w_MixRatio
	//	w_MixRatio=0
	//	w_MixRatio[iMolecule]=c0*1e-6
	//	print imolecule
	
	NVAR gv_ResetStatus=gv_ResetStatus
	gv_ResetStatus=1
	Reset_MixingRatio( )	
	NVAR gv=$("gv_"+strSpName)
	gv_wi=lw
	gv_pressure=press
	gv_pathlength=pathlength
	
	String atmfile,filename
	c0=1e-9

	Variable j
	for (j=0;j<=5;j+=1)	
	
		gv=c0
		
		//Clear_files()
		//	CleanUp_m0files()
	
		ButtonPro_Shellout("")
	
		//String atmfile = gs_OutputFileName
		atmfile = gs_OutputFileName
		//String filename//, transname, transname_orig
		//Variable firstx, lastx, deltax
	
		filename=gs_DatabasePath+atmfile+".m0"
		//transname="trans_"+atmfile
	
		//killwaves freq0,abs0
		LoadWave/J/D/N=freq/O/K=0/L={0,0,3,0,0} filename
		LoadWave/J/N=abs/O/K=0/L={0,3,0,0,0} filename
	
		wave freq0=freq0
		wave abs0=abs0
		SetScale/P x freq0[0],freq0[1],"", abs0
		//edit abs0
		Variable ipnt=x2pnt(abs0,f0)
		if (abs0[ipnt]>0.1)
			c0=c0/(ceil(abs0[ipnt]/0.1))
			//Clear_files()
		elseif (abs0[ipnt]<0.001)
			c0=c0*(ceil(0.05/abs0[ipnt]))
			//Clear_files()
		else
			//Clear_files()
			break;// for
		endif
		sleep 00:00:01
		print "abs0=", abs0[ipnt],C0,j
	endfor	
	//	if (abs0[ipnt]>0.01)
	//		doalert 0, "maximum linear concentration is too high, try divide it by a factor of " +num2str(ceil(abs0[ipnt]/0.01))
	//		Clear_files()
	//		return 0
	//	endif
	//	CleanUp_m0files()	
	c0=c0/1e-9
	// ---------------convolution--------	
	variable i,k
	variable p=1.2
	Variable base=ln(p)
	Variable n=10
	
	Make/O/N=(n) C_CalibrationInput,A_Calibration
	//A_Calibration[0]=abs0[ipnt]
	
	SetScale/I x c0,cmax,"", C_CalibrationInput
	//C_CalibrationInput=x
	
	for (i=0;i<n;i+=1)
		C_CalibrationInput[i]=p^(ln(c0)/base+i/(n-1)*(ln(cmax)-ln(c0))/base)
	endfor
	

	//for (k=1;k<=2;k+=1)	


	for (i=0;i<n;i+=1)
		duplicate/O abs0 trans0

		trans0=C_CalibrationInput[i]/c0*abs0

		trans0=exp(-trans0)
	
		//SetScale/P x freq0[0],freq0[1],"", trans0
	
		
		if (gv_userDefinedShape==1)  //convolve with user defined instrumental line width
			if  (!exists("instrumental_userDefined"))
				DoAlert 0, "User Defined Instrumental Line Does Not Exist !\n You Could Use spe Loader to Load the 0.1 Torr Spectrum \n After that use Macro: MakeInstrumentalFromCursors() \nto get the correct Instrumental Line"
				return -1
			endif
			//transname_orig=transname+"_orig"
			//duplicate/o $transname $transname_orig
			trans0=1-trans0
		
			Rotate_to_MiddleZero_Higor(instrumental_userdefined)  // Wrapped around function to center
		
			convolve/A instrumental_userDefined trans0
			trans0=1-trans0
		else
			if (gv_wi>0)								//convolve with instrumental line width
				//transname_orig=transname+"_orig"
				//duplicate/o $transname $transname_orig
				instrumental_template(freq0[1],gv_wi,gv_shape)
				trans0=1-trans0
				convolve/A instrumental trans0
				trans0=1-trans0
			endif
		endif
		A_Calibration[i]=-ln(trans0[ipnt])
	endfor

	
	//	if (k==2)
	display C_CalibrationInput vs A_Calibration
	ModifyGraph mode(C_CalibrationInput)=3,marker(C_CalibrationInput)=19;DelayUpdate
	ModifyGraph rgb(C_CalibrationInput)=(0,0,65280)
	Legend/C/N=text0/F=0/A=MC
	Label left "Concentration, ppb";DelayUpdate
	Label bottom "Peak Absorbance"

	//	endif
	K0 = 0
	CurveFit/H="10000"/N/q poly 5, C_CalibrationInput /X=A_Calibration /D 
	//	if (k==1)
	//		variable a1,a2
	//		a1=A_Calibration[0];a2=A_Calibration[numpnts(A_Calibration)-1]
	//		SetScale/I x a1,a2,"", A_Calibration
	//		A_Calibration=x
	//		C_CalibrationInput=poly(W_coef,A_Calibration)
	//	endif
	
	//endfor
	
	string strlw
	strlw=num2str(lw)
	strlw[0,1]=""
	print ""
	print "-----------------------------------------------------------------"
	print ""
	print  "Function ConvlCorrect_"+strSpName+"_"+num2str(round(f0))+"_"+num2str(round(press))+"_"+strlw+"(c)"
	print "Variable c"
	Print "Variable a"
	print "a="+num2str(A_Calibration[0]/c0)+"*c"
	print "make/o w={0,"+num2str(K1)+","+num2str(K2)+","+num2str(K3)+","+num2str(K4)+"}"
	print "return poly(w,a)"
	Print "End Function"

//	Clear_files()
	//print abs0[ipnt]
End

//---------------------SELECT2004.FOR-------------------------//

Function fortran_select()
	NVAR gv_WaveNumStart, gv_WaveNumEnd, gv_WaveNumRange
	SVAR gs_Database
	SVAR gs_hitran, gs_outfil, gs_DatabasePath, gs_HitranFileName, gs_OutputFileName
	Variable refNum, refNum2
	String pathName, fileName, line
	Wave/T ws_Select_in = ws_Select_in
	gv_WaveNumEnd=gv_WaveNumStart+gv_WaveNumRange
	Variable begin_cm = gv_WaveNumStart
	Variable end_cm = gv_WaveNumEnd
	
	gs_hitran = gs_HitranFileName + ".dat"
	gs_outfil = gs_OutputFileName + ".m0"
	
	//split full file name into path name and file name for PARFile function
	Open/R refNum as gs_Database
	//PARFile_LoadRange begin
	FReadLine refNum, line
	Variable line_characters = strlen( line )
	FStatus refNum
	Variable low_end, high_end, mid_pnt
	low_end = 0; high_end = V_logEOF;
	Variable idex = 0, line_count = 0, good_enough = 100, there_yet = 0
	String species_str, wavelength_str, linestrength_str, energy_str
	Variable species, wavelength, linestrength, energy
	//printf "searching %s", filename
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
			energy = str2num(energy_str)
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
	//printf "loading lines from %s ....wait...", filename
	do
		FReadLine refNum, line
		if( strlen( line ) < 1 )
			there_yet = 1 
		else
			line_count += 1
			ParParseLine( line, species_str, wavelength_str, linestrength_str, energy_str )
			species = str2num( species_str )
			wavelength = str2num( wavelength_str )
			linestrength = str2num( linestrength_str )
			energy = str2num(energy_str)
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
	//PARFile_LoadRange end
	
	
	Wave species_w=species_w
	Wave linestrength_w=linestrength_w
	duplicate/o species_w, iso_filt_w, thresh_filt_w, final_filt_w
	duplicate/o linestrength_w, filt_linestrength
	Wave iso_filt_w = iso_filt_w;
	Wave thresh_filt_w=thresh_filt_w;
	Wave final_filt_w=final_filt_w
	Wave filt_linestrength=filt_linestrength
	thresh_filt_w = 1; iso_filt_w = 1; final_filt_w = 1	

	Variable kdex=0
	Wave/T ws_Select_in = ws_Select_in
	Wave final_filt_w=final_filt_w
	Wave/T line_w=line_w

	Close refNum

	//write to hitemp.dat
	NewPath/O pathName gs_DatabasePath
	Open/P=pathName refNum as gs_hitran
	
	do
		if( final_filt_w[kdex] == 1 )
			fprintf refNum, "%s\r\n", line_w[kdex]
		endif
		kdex += 1
	while( kdex < numpnts( line_w ) )
	
	Close refNum
	
	
End


//----------------------ATMTRNS.FOR---------------------------//

Function fortran_atmtrns()
	atm_calc()
	atm_put()
End

Function atm_put()
	NVAR gv_WaveNumStart, gv_WaveNumEnd, gv_WaveNumStep, gv_PathLength, gv_Temperature, gv_ihitr, gv_iout, gv_Pressure, gv_computation, gv_m_width, gv_length, gv_SpectrumType, gv_Threshold //bring in global variable
	SVAR gs_hitran, gs_outfil, gs_DatabasePath
	NVAR gv_ckTorr
	Wave w_mix = root:w_mix
	Wave w_a = root:w_a
	Wave w_b = root:w_b
	Variable refNum, i, wave1
	String pathName
	String s_wavlow, s_resint, s_wavhigh, s_a, temp_string
	
	NewPath/O pathName gs_DatabasePath
	Open/P=pathName refNum as gs_outfil
	
	gv_length = gv_length - 1
	if (gv_Threshold > 0)
		s_wavlow = num2str(gv_WaveNumStart)
		s_wavhigh = num2str(gv_WaveNumEnd)
		s_resint = num2str(gv_WaveNumStep)
		//Make/O/T/N=(gv_length+3) w_output = {s_wavlow, s_resint, s_wavhigh}
		fprintf refNum, "%s\r", s_wavlow
		fprintf refNum, "%s\r", s_resint
		fprintf refNum, "%s\r", s_wavhigh
		for (i=0; i<gv_length; i+=1)
			s_a = num2str(w_a[i])
			fprintf refNum, "%s\r", s_a
			//w_output[i+3] = s_a
		endfor
	endif
	if (gv_Threshold < 0)
		//Make/O/T/N=((gv_length)*2) w_output
		for (i=0; i<gv_length; i+=1)
			wave1 = gv_WaveNumStart + gv_WaveNumStep*(i-1)
			if (w_a[i] > abs(gv_Threshold))
				temp_string = num2str(wave1)
				s_a = num2str(w_a[i])
				fprintf refNum, "%s\r", temp_string
				fprintf refNum, "%s\r", s_a
				//w_output[i*2] = temp_string
				//w_output[i*2+1] = s_a
			endif
		endfor
	endif
	
	KillPath pathName
	Close refNum
	
	//Save/J/P=pathName w_output as gs_outfil
	//SaveTextWave("", "C:\\HITRAN:\\" + gs_outfil, w_output)

End

Function atm_calc()
	NVAR gv_WaveNumStart, gv_WaveNumEnd, gv_WaveNumStep, gv_PathLength, gv_Temperature, gv_ihitr, gv_iout, gv_Pressure, gv_computation, gv_m_width, gv_length, gv_SpectrumType, gv_Threshold //bring in global variables
	NVAR gv_ckTorr
	SVAR gs_hitran, gs_outfil, gs_DatabasePath
	Wave w_mix
	Wave w_a
	String temp_string
	Variable tref, tpass, QT, dxfact2, domega_sq, dxbigm, dxbigu, dxroot1, dxroot2, d2 //explicitly declared as doubles in FORTRAN. All Igor variables are double by default
	Variable ispec_num, iso, xdum, gridpts, contint_lor, contint_dop, contint_line, thresh1, thresh2, absthr1, absthr2, ilow, ihigh, max0, q296_0, xm, xmfactor, sign_, y, x, wr
	Variable sigma, edbl, xnexp, temp_fudge, m_width, alpha_doppler, alpha_lorentz, alpha_self, sigma0, omega_sq, base, big, alpha_voight, tratio, xni //mostly variables read from hitemp.dat
	Variable end_thresh, s_val, a0, a1, contint_end, wave_max, wave_min, cont_thresh, alpha //variables not explicitly declared in FORTRAN
	Make/O/N=(species) w_mole_weight = {18, 44, 48, 44, 28, 16, 32, 30, 64, 46, 17, 63, 17, 20, 36, 81, 128, 51, 60, 30, 52, 28, 27, 50, 34, 26, 30, 34, 66, 146, 34, 46, 33, 16, 97, 30, 97, 28, 32, 95, 41, 88, 50, 50, 50, 50, 37, 80}
	Make/O w_b
	String pathName = ""
	Variable refNum, i, wave0, wave1
	
	//convert pressure to atm
	if (gv_ckTorr)
		gv_Pressure = gv_Pressure/760
	endif
	
	//determine the baseline and the number of gridpoints
	gridpts = round(((gv_WaveNumEnd - gv_WaveNumStart)/gv_WaveNumStep)+2)
	gv_length = gridpts
	base = gv_WaveNumStart
	
	//compute the beginning range for starting computation
	//assuming linestrength and broadening coefficient
	end_thresh = 0.001
	s_val = 4E-20
	alpha_lorentz = 0.1 * gv_Pressure * 296/abs(gv_Temperature)
	big = 0
	for (i=0; i < species; i += 1)
		xni = gv_Pressure * (w_mix[i]* 7.34E21)/abs(gv_Temperature)
		a0 = s_val/(pi * alpha_lorentz) * xni * gv_PathLength
		if (a0 <= end_thresh)
		else
			contint_end = sqrt(a0/end_thresh - 1) * alpha_lorentz
			if (contint_end > big)
				big = contint_end
			endif
		endif
	endfor
	
	//maximum contribution interval set to 5 cm^-1
	if (big > 5)
		big = 5
	endif
	wave_max = gv_WaveNumEnd + big + gv_WaveNumStep
	wave_min = gv_WaveNumStart - big - gv_WaveNumStep
	
	//reset the a vector
	for (i=0; i < (gv_length + 2*big/gv_WaveNumStep); i += 1)
		w_a[i] = 0
	endfor
	
	NewPath/O pathName gs_DatabasePath
	Open/R/P=pathName refNum as gs_hitran
	
	cont_thresh = abs(gv_Threshold)
	tratio = 296/abs(gv_Temperature)
	
	do
		FStatus refNum
		if ((V_logEOF - V_filePos) < 150)
			break
		endif
		do
			//read data in from hitemp.dat
			//very specific format, not delimited in any way
			FReadLine/N=2/T="" refNum, temp_string
			ispec_num = str2num(temp_string)
			ispec_num = ispec_num - 1 //FORTRAN arrays are 1 indexed, Igor is 0 indexed
			FReadLine/N=1/T="" refNum, temp_string
			iso = str2num(temp_string)
			FReadLine/N=12/T="" refNum, temp_string
			wave0 = str2num(temp_string)
			FReadLine/N=10/T="" refNum, temp_string
			s_val = str2num(temp_string)
			FReadLine/N=10/T="" refNum, temp_string
			xdum = str2num(temp_string)
			FReadLine/N=5/T="" refNum, temp_string
			alpha_lorentz = str2num(temp_string)
			FReadLine/N=5/T="" refNum, temp_string
			alpha_self = str2num(temp_string)
			FReadLine/N=10/T="" refNum, temp_string
			edbl = str2num(temp_string)
			FReadLine/N=4/T="" refNum, temp_string
			xnexp = str2num(temp_string)
			
			FReadLine/T=(num2char(10)) refNum, temp_string //rest of the line is garbage, flush it out for FReadLine
		
			if (alpha_lorentz <= 0)
				alpha_lorentz = 0.05
			endif
		
			if (edbl > 10000)
				edbl = 10000
			endif
	
			//do the lorentz case
			alpha = alpha_lorentz * gv_Pressure * (tratio^xnexp) + alpha_self * gv_Pressure * w_mix[ispec_num] * (tratio^xnexp)
			temp_fudge = exp(edbl * (-1.44) * (1/abs(gv_Temperature) - 1/296)) * tratio^1.5
			xni = gv_Pressure*w_mix[ispec_num]*7.34E21/abs(gv_Temperature)
			sigma0 = s_val/(pi*alpha) * temp_fudge * xni
			a0 = sigma0 * gv_PathLength
		
			//then do doppler region
			alpha_doppler = (7.16E-7/2) * sqrt(abs(gv_Temperature)/w_mole_weight[ispec_num]) * wave0
			sigma0 = s_val * xni * temp_fudge/(1.06 * 2 * alpha_doppler)
			a1 = sigma0 * gv_PathLength
			
			contint_lor = sqrt(a0/cont_thresh - 1) * alpha
			contint_dop = sqrt(ln(a1/cont_thresh)/ln(2)) * alpha_doppler
	
			if (contint_dop > contint_lor)
				contint_line = contint_dop
			else
				contint_line = contint_lor
			endif
			contint_line *= 1.414
	
			//calculate species range
			thresh1 = wave0 - contint_line
			thresh2 = wave0 + contint_line
			//subtract base
			absthr1 = (thresh1 - base)/gv_WaveNumStep
			absthr2 = (thresh2 - base)/gv_WaveNumStep
			//determine indices of computation
			ilow = round(absthr1)
			ihigh = round(absthr2)
			max0 = gridpts - 1
	
			//begin test
			if (ilow < 0)
				ilow = 0
			endif
			if (ihigh > max0)
				ihigh = max0
			endif
			tratio = 296/abs(gv_Temperature)
	
		while((wave0 < wave_min) || (a0 < cont_thresh) || (a1 < cont_thresh) || (ilow > max0) || (ihigh < 0))
		
		if (wave0 > wave_max)
			break
		endif

		////////////////////////////////////////////////////////
		//////// high pressure calculation //////////
		////////////////////////////////////////////////////////
		if (gv_SpectrumType == 3)
			if (gv_Temperature < 0)
				alpha_lorentz = (alpha_lorentz * gv_Pressure) + (alpha_self * gv_Pressure * w_mix[ispec_num] * (tratio^xnexp))
			else
				alpha_lorentz = (alpha_lorentz * gv_Pressure * (tratio^xnexp)) + (alpha_self * gv_Pressure * w_mix[ispec_num] * (tratio^xnexp))
			endif
			if (edbl > 10000)
				edbl = 10000
			endif
			if ( (gv_Temperature != 296) && (gv_Temperature > 0) )
				temp_fudge = exp(edbl * -1.44 * (1/abs(gv_Temperature) - 1/296))
				if (ispec_num == 2)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 4)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 5)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 7)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 8)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 13)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 14)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 15)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 16)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 17)
					temp_fudge = temp_fudge * tratio	
				elseif (ispec_num == 18)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 19)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 22)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 23)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 36)
					temp_fudge = temp_fudge * tratio
				else
					temp_fudge = temp_fudge * (tratio^1.5)
				endif
			
				tref = 296
				QT = QofT(ispec_num, iso, tref)
				q296_0 = QT
				tpass = gv_Temperature
			
				QT = QofT(ispec_num, iso, tpass)
				if (QT <= 0)
				else
					temp_fudge = q296_0/QT * exp(edbl*-1.44*(1/abs(gv_Temperature) - 1/296))
				endif
			endif
		
			xni = gv_Pressure * w_mix[ispec_num]*7.34E+21/abs(gv_Temperature)
			sigma0 = s_val/(Pi*alpha_lorentz) * temp_fudge * xni
			if (gv_computation == 1)
				xm = m_width/alpha_lorentz
				xmfactor = sqrt(2)/xm
			elseif (gv_computation == 2)
				xm = m_width/alpha_lorentz
				xmfactor = sqrt(2)/xm
				dxfact2 = 2*sqrt(2)
			endif
		
			i = ilow
			do
				wave1 = base + (i*gv_WaveNumStep)
				if (gv_computation == 0)
					omega_sq = ((wave1-wave0)/alpha_lorentz)^2
					sigma = sigma0*(1/(1+omega_sq))
				else
					domega_sq = ((wave1-wave0)/alpha_lorentz)
					dxbigm = 1 - domega_sq^2 + xm^2
					dxbigu = sqrt(dxbigm^2 + (4*domega_sq*2))
					dxroot1 = sqrt(dxbigu + dxbigm)
					dxroot2 = sqrt(dxbigu - dxbigm)
					if (gv_computation == 1)
						if (omega_sq == 0)
							sign_ = 1
						else
							sign_ = (0-omega_sq)/abs(omega_sq)
						endif
						sigma = sign_*sigma0*xmfactor*((abs(domega_sq)*dxroot1)-dxroot2)/dxbigu
					elseif(gv_computation == 2)
						sigma = sigma0*xmfactor*(dxfact2 - (((dxbigm + 1 - domega_sq^2)*dxroot1)+(4*abs(domega_sq)*dxroot2))/dxbigu)
					endif
				endif
				w_a[i+1] = w_a[i+1] + sigma
				i += 1
			while (i <= ihigh)
		
			////////////////////////////////////////////////////////
			//////// low pressure calculation ///////////
			////////////////////////////////////////////////////////
		elseif (gv_SpectrumType == 1)
			alpha_doppler = 7.16E-07/2*sqrt(abs(gv_Temperature)/w_mole_weight[ispec_num])*wave0
			temp_fudge = 1
			if ( (gv_Temperature != 296) && (gv_Temperature > 0) )
				temp_fudge = exp(edbl * -1.44 * (1/abs(gv_Temperature) - 1/296))
				if (ispec_num == 2)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 4)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 5)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 7)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 8)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 13)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 14)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 15)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 16)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 17)
					temp_fudge = temp_fudge * tratio	
				elseif (ispec_num == 18)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 19)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 22)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 23)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 36)
					temp_fudge = temp_fudge * tratio
				else
					temp_fudge = temp_fudge * (tratio^1.5)
				endif
			
				if (ispec_num <= 36)
					tref = 296
					QT = QofT(ispec_num, iso, tref)
					q296_0 = QT
					tpass = gv_Temperature
			
					QT = QofT(ispec_num, iso, tpass)
					if (QT <= 0)
						//exit?
					else
						temp_fudge = q296_0/QT * exp(edbl*-1.44*(1/abs(gv_Temperature) - 1/296))
					endif
				endif
			endif
		
			xni = gv_Pressure * w_mix[ispec_num]*7.34E+21/abs(gv_Temperature)
			sigma0 = s_val*xni*temp_fudge/(2.12*alpha_doppler)
		
			i = ilow
			do
				wave1 = base + (i*gv_WaveNumStep)
				omega_sq = (((wave1-wave0)/alpha_doppler)^2) * ln(2)
				sigma = sigma0*exp(-1*omega_sq)
				w_a[i+1] = w_a[i+1] + sigma
				i+=1
			while (i <= ihigh)
	
	
	
			////////////////////////////////////////////////////////////////////////
			/////////// intermediate pressure calculation ///////////
			////////////////////////////////////////////////////////////////////////
		elseif (gv_SpectrumType == 2)
			if (gv_Temperature < 0)
				alpha_lorentz = alpha_lorentz*gv_Pressure + alpha_self*gv_Pressure*w_mix[ispec_num]*tratio^xnexp
			else
				alpha_lorentz = alpha_lorentz*gv_Pressure*tratio^xnexp + alpha_self*gv_Pressure*w_mix[ispec_num]*tratio^xnexp
			endif
		
			alpha_doppler = (7.16E-07/2) * (sqrt(abs(gv_Temperature)/w_mole_weight[ispec_num])) * wave0
			temp_fudge = 1
		
			if ( (gv_Temperature != 296) && (gv_Temperature > 0) )
				temp_fudge = exp(edbl * -1.44 * (1/abs(gv_Temperature) - 1/296))
				if (ispec_num == 2)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 4)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 5)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 7)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 8)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 13)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 14)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 15)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 16)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 17)
					temp_fudge = temp_fudge * tratio	
				elseif (ispec_num == 18)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 19)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 22)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 23)
					temp_fudge = temp_fudge * tratio
				elseif (ispec_num == 36)
					temp_fudge = temp_fudge * tratio
				else
					temp_fudge = temp_fudge * (tratio^1.5)
				endif
			
				if (ispec_num <= 36)
					tref = 296
					QT = QofT(ispec_num, iso, tref)
					q296_0 = QT
					tpass = gv_Temperature
			
					QT = QofT(ispec_num, iso, tpass)
					if (QT <= 0)
						//exit?
					else
						temp_fudge = q296_0/QT * exp(edbl*-1.44*(1/abs(gv_Temperature) - 1/296))
					endif
				endif
			endif
		
			xni = gv_Pressure * w_mix[ispec_num]*7.34E+21/abs(gv_Temperature)
			alpha_voight = sqrt(alpha_lorentz^2 + 2*alpha_doppler^2)
			sigma0 = s_val*xni*temp_fudge/(sqrt(Pi)*alpha_doppler)
			sigma0 = sigma0 * sqrt(ln(2))
			y = sqrt(ln(2)) * alpha_lorentz/alpha_doppler
		
			i = ilow
			do
				wave1 = base + i*gv_WaveNumStep
				x = sqrt(ln(2)) * (wave1-wave0)/alpha_doppler
				wr = complx_p_wr(x,y)
				sigma = sigma0*wr
				w_a[i+1] = w_a[i+1] + sigma
				i+=1
			while (i <= ihigh)
		endif
		
	while(1)
	
	i = 0
	do
		w_a[i] = w_a[i] * gv_PathLength
		i+=1
	while(i <= gridpts)
	
	//all points are off by one, shift backwards into array smaller by one point
	i=0
	do
		w_b[i] = w_a[i+1]
		i+=1
	while(i < gridpts)
	
	KillPath pathName
	Close refNum
	
	//convert pressure back to torr
	if (gv_ckTorr)
		gv_Pressure = gv_Pressure * 760
	endif

End

Function QofT(Mol, Iso, Tout)
	Variable Mol, Iso, Tout //input arguments
	Variable QT //output arguments
	Variable ivec //various local vars
	Wave w_isovec
	Make/O q296
	Make/O/N=(85,4) Qcoef1
	Make/O/N=(85,4) Qcoef2
	Make/O/N=(85,4) Qcoef3
	
	
	///////////////////////////////////////////////////
	//Q296
	///////////////////////////////////////////////////
	//H2O
	q296[0] = 174.626 //161
	q296[1] = 176.141 //181
	q296[2] = 1053.06 //171
	q296[3] = 865.122 //162
	//CO2
	q296[4] = 286.219 //626
	q296[5] = 576.928 //636
	q296[6] = 607.978 //628
	q296[7] = 3543.89 //627
	q296[8] = 1235.28 //638
	q296[9] = 7144.32 //637
	q296[10] = 323.407 //828
	q296[11] = 3767 //728
	//O3
	q296[12] =3481.86 //666
	q296[13] = 7462.07 //668
	q296[14] = 3645.63 //686
	q296[15] = 43064.7 //667
	q296[16] = 21279.1 //676
	//N2O
	q296[17] = 4991.83 //446
	q296[18] = 3349.38 //456
	q296[19] = 3449.4 //546
	q296[20] = 5265.95 //448
	q296[21] = 30700.8 //447
	//CO
	q296[22] = 107.428 //26
	q296[23] = 224.704 //36
	q296[24] = 112.781 //28
	q296[25] = 661.209 //27
	q296[26] = 236.447 //38
	q296[27] = 1380.71 //37
	//CH4
	q296[28] = 589.908 //211
	q296[29] = 1179.74 //311
	q296[30] = 4770.61//212
	//O2
	q296[31] = 215.726 //66
	q296[32] = 452.188 //68
	q296[33] = 2639.98 //67
	//NO
	q296[34] = 3397.3 //46
	q296[35] = 1570.4 //56
	q296[36] = 3582.52 //48
	//SO2
	q296[37] = 6344.49 //626
	q296[38] = 6373.21 //646
	q296[39] = 13631.8 //NO2 646
	//NH3
	q296[40] = 1710.89 //4111
	q296[41] = 1141.34 //5111
	q296[42] = 213822 //HNO3 146
	//OH
	q296[43] = 160.659 //61
	q296[44] = 161.629 //81
	q296[45] = 621.323 //62
	q296[46] = 41.4265 //HF 19
	//HCl
	q296[47] = 160.650 //15
	q296[48] = 160.887 //17
	//HBr
	q296[49] = 200.165 //19
	q296[50] = 200.227 //11
	q296[51] = 388.948 //HI 17
	//Clo
	q296[52] = 13152.4 //56
	q296[53] = 13382.4 //76
	//OCs
	q296[54] = 1217.46 //622
	q296[55] = 1247.93 //624
	q296[56] = 2474.82 //632
	q296[57] = 1309.48 //822
	//H2CO
	q296[58] = 2683.88 //126
	q296[59] = 5503.22 //136
	q296[60] = 2845.73 //128
	//HOCl
	q296[61] = 19316.6 //165
	q296[62] = 19658.4 //167
	q296[63] =  467.136 //N2 44
	//HCN
	q296[64] = 893.323 //124
	q296[65] = 1836.57 //134
	q296[66] = 615.046 //125
	//CH3Cl
	q296[67] = 14485.8 //215
	q296[68] = 14715.3 //217
	q296[69] = 7678.71 //H2O2 1661
	//C2H2
	q296[70] = 412.519 //1221
	q296[71] = 3300.14 //1231
	q296[72] = 5462.65 //C2H6 1221
	q296[73] = 3250.67 //PH3 1111
	q296[74] = 69763.2 //COF2 269
	q296[75] = 1622420 //SF6 29
	//H2S
	q296[76] = 503.204 //121
	q296[77] = 504.486 //141
	q296[78] = 2015.46 //131
	q296[79] = 38925.7 //HCOOH 126
	q296[80] = 4301.84 //HO2 166
	q296[81] = -1 //O 6
	//ClONO2
	q296[82] = 2128290 //5646
	q296[83] = 2182460 //7646
	q296[84] = 308.855 //NO+ 46
	
	///////////////////////////////////////////////////
	//QCoef 1
	///////////////////////////////////////////////////
	//H2O
	Qcoef1[0,0] = -4.4405
	Qcoef1[0,1] = .27678
	Qcoef1[0,2] = .0012536
	Qcoef1[0,3] = -.0000048938
	Qcoef1[1,0] = -4.3624
	Qcoef1[1,1] = .27647
	Qcoef1[1,2] = .0012802
	Qcoef1[1,3] = -.0000052046
	Qcoef1[2,0] = -25.767
	Qcoef1[2,1] = 1.6458
	Qcoef1[2,2] = .0076905
	Qcoef1[2,3] = -.000031668
	Qcoef1[3,0] = -23.916
	Qcoef1[3,1] = 1.3793
	Qcoef1[3,2] = .0061246
	Qcoef1[3,3] = -.000021530
	//CO2
	Qcoef1[4,0] = -1.3617
	Qcoef1[4,1] = .94899
	Qcoef1[4,2] = -.00069259
	Qcoef1[4,3] = .25974E-05
	Qcoef1[5,0] = -.20631E+01
	Qcoef1[5,1] = .18873E+01
	Qcoef1[5,2] = -.13669E-02
	Qcoef1[5,3] = .54032E-05
	Qcoef1[6,0] = -.29175E+01
	Qcoef1[6,1] = .20114E+01
	Qcoef1[6,2] = -.14786E-02
	Qcoef1[6,3] = .55941E-05
	Qcoef1[7,0] = -.16558E+02
	Qcoef1[7,1] = .11733E+02
	Qcoef1[7,2] = -.85844E-02
	Qcoef1[7,3] = .32379E-04
	Qcoef1[8,0] = -.44685E+01
	Qcoef1[8,1] = .40330E+01
	Qcoef1[8,2] = -.29590E-02
	Qcoef1[8,3] = .11770E-04
	Qcoef1[9,0] = -.26263E+02
	Qcoef1[9,1] = .23350E+02
	Qcoef1[9,2] = -.17032E-01
	Qcoef1[9,3] = .67532E-04
	Qcoef1[10,0] = -.14811E+01
	Qcoef1[10,1] = .10667E+01
	Qcoef1[10,2] = -.78758E-03
	Qcoef1[10,3] = .30133E-05
	Qcoef1[11,0] = -.17600E+02
	Qcoef1[11,1] = .12445E+02
	Qcoef1[11,2] = -.91837E-02
	Qcoef1[11,3] = .34915E-04
	//O3
	Qcoef1[12,0] = -.16443E+03
	Qcoef1[12,1] = .69047E+01
	Qcoef1[12,2] = .10396E-01
	Qcoef1[12,3] = .26669E-04
	Qcoef1[13,0] = -.35222E+03
	Qcoef1[13,1] = .14796E+02
	Qcoef1[13,2] = .21475E-01
	Qcoef1[13,3] = .59891E-04
	Qcoef1[14,0] = -.17466E+03
	Qcoef1[14,1] = .72912E+01
	Qcoef1[14,2] = .10093E-01
	Qcoef1[14,3] = .29991E-04
	Qcoef1[15,0] = -.20540E+04
	Qcoef1[15,1] = .85998E+02
	Qcoef1[15,2] = .12667E+00
	Qcoef1[15,3] = .33026E-03
	Qcoef1[16,0] = -.10148E+04
	Qcoef1[16,1] = .42494E+02
	Qcoef1[16,2] = .62586E-01
	Qcoef1[16,3] = .16319E-03
	//N2O
	Qcoef1[17,0] = .24892E+02
	Qcoef1[17,1] = .14979E+02
	Qcoef1[17,2] = -.76213E-02
	Qcoef1[17,3] = .46310E-04
	Qcoef1[18,0] = .36318E+02
	Qcoef1[18,1] = .95497E+01
	Qcoef1[18,2] = -.23943E-02
	Qcoef1[18,3] = .26842E-04
	Qcoef1[19,0] = .24241E+02
	Qcoef1[19,1] = .10179E+02
	Qcoef1[19,2] = -.43002E-02
	Qcoef1[19,3] = .30425E-04
	Qcoef1[20,0] = .67708E+02
	Qcoef1[20,1] = .14878E+02
	Qcoef1[20,2] = -.10730E-02
	Qcoef1[20,3] = .34254E-04
	Qcoef1[21,0] = .50069E+03
	Qcoef1[21,1] = .84526E+02
	Qcoef1[21,2] = .83494E-02
	Qcoef1[21,3] = .17154E-03
	//CO
	Qcoef1[22,0] = .27758E+00
	Qcoef1[22,1] = .36290E+00
	Qcoef1[22,2] = -.74669E-05
	Qcoef1[22,3] = .14896E-07
	Qcoef1[23,0] = .53142E+00
	Qcoef1[23,1] = .75953E+00
	Qcoef1[23,2] = -.17810E-04
	Qcoef1[23,3] = .35160E-07
	Qcoef1[24,0] = .26593E+00
	Qcoef1[24,1] = .38126E+00
	Qcoef1[24,2] = -.92083E-05
	Qcoef1[24,3] = .18086E-07
	Qcoef1[25,0] = .16376E+01
	Qcoef1[25,1] = .22343E+01
	Qcoef1[25,2] = -.49025E-04
	Qcoef1[25,3] = .97389E-07
	Qcoef1[26,0] = .51216E+00
	Qcoef1[26,1] = .79978E+00
	Qcoef1[26,2] = -.21784E-04
	Qcoef1[26,3] = .42749E-07
	Qcoef1[27,0] = .32731E+01
	Qcoef1[27,1] = .46577E+01
	Qcoef1[27,2] = -.69833E-04
	Qcoef1[27,3] = .18853E-06
	//CH4
	Qcoef1[28,0] = -.26479E+02
	Qcoef1[28,1] = .11557E+01
	Qcoef1[28,2] = .26831E-02
	Qcoef1[28,3] = .15117E-05
	Qcoef1[29,0] = -.52956E+02
	Qcoef1[29,1] = .23113E+01
	Qcoef1[29,2] = .53659E-02
	Qcoef1[29,3] = .30232E-05
	Qcoef1[30,0] = -.21577E+03
	Qcoef1[30,1] = .93318E+01
	Qcoef1[30,2] = .21779E-01
	Qcoef1[30,3] = .12183E-04
	//O2
	Qcoef1[31,0] = .35923E+00
	Qcoef1[31,1] = .73534E+00
	Qcoef1[31,2] = -.64870E-04
	Qcoef1[31,3] = .13073E-06
	Qcoef1[32,0] = -.40039E+01
	Qcoef1[32,1] = .15595E+01
	Qcoef1[32,2] = -.15357E-03
	Qcoef1[32,3] = .30969E-06
	Qcoef1[33,0] = -.23325E+02
	Qcoef1[33,1] = .90981E+01
	Qcoef1[33,2] = -.84435E-03
	Qcoef1[33,3] = .17062E-05
	//NO
	Qcoef1[34,0] = -.75888E+02
	Qcoef1[34,1] = .79048E+01
	Qcoef1[34,2] = .17555E-01
	Qcoef1[34,3] = -.15606E-04
	Qcoef1[35,0] = -.29980E+02
	Qcoef1[35,1] = .36479E+01
	Qcoef1[35,2] = .80522E-02
	Qcoef1[35,3] = -.71296E-05
	Qcoef1[36,0] = -.80558E+02
	Qcoef1[36,1] = .83447E+01
	Qcoef1[36,2] = .18448E-01
	Qcoef1[36,3] = -.16323E-04
	//SO2
	Qcoef1[37,0] = -.24056E+03
	Qcoef1[37,1] = .11101E+02
	Qcoef1[37,2] = .22164E-01
	Qcoef1[37,3] = .52334E-04
	Qcoef1[38,0] = -.24167E+03
	Qcoef1[38,1] = .11151E+02
	Qcoef1[38,2] = .22270E-01
	Qcoef1[38,3] = .52550E-04
	//NO2
	Qcoef1[39,0] = -.53042E+03
	Qcoef1[39,1] = .24216E+02
	Qcoef1[39,2] = .66856E-01
	Qcoef1[39,3] = .43823E-04
	//NH3
	Qcoef1[40,0] = -.42037E+02
	Qcoef1[40,1] = .25976E+01
	Qcoef1[40,2] = .13073E-01
	Qcoef1[40,3] = -.62230E-05
	Qcoef1[41,0] = -.28609E+02
	Qcoef1[41,1] = .17272E+01
	Qcoef1[41,2] = .87529E-02
	Qcoef1[41,3] = -.41714E-05
	//HNO3
	Qcoef1[42,0] = -.10000E+01
	Qcoef1[42,1] = .00000E+00
	Qcoef1[42,2] = .00000E+00
	Qcoef1[42,3] = .00000E+00
	//OH
	Qcoef1[43,0] = .17478E+02
	Qcoef1[43,1] = .31954E+00
	Qcoef1[43,2] = .76581E-03
	Qcoef1[43,3] = -.71337E-06
	Qcoef1[44,0] = .17354E+02
	Qcoef1[44,1] = .32350E+00
	Qcoef1[44,2] = .76446E-03
	Qcoef1[44,3] = -.70932E-06
	Qcoef1[45,0] = .30717E+02
	Qcoef1[45,1] = .13135E+01
	Qcoef1[45,2] = .31430E-02
	Qcoef1[45,3] = -.28371E-05
	//HF
	Qcoef1[46,0] = .15486E+01
	Qcoef1[46,1] = .13350E+00
	Qcoef1[46,2] = .59154E-05
	Qcoef1[46,3] = -.46889E-08
	//HCl
	Qcoef1[47,0] = .28627E+01
	Qcoef1[47,1] = .53122E+00
	Qcoef1[47,2] = .67464E-05
	Qcoef1[47,3] = -.16730E-08
	Qcoef1[48,0] = .28617E+01
	Qcoef1[48,1] = .53203E+00
	Qcoef1[48,2] = .66553E-05
	Qcoef1[48,3] = -.15168E-08
	//HBr
	Qcoef1[49,0] = .27963E+01
	Qcoef1[49,1] = .66532E+00
	Qcoef1[49,2] = .34255E-05
	Qcoef1[49,3] = .52274E-08
	Qcoef1[50,0] = .27953E+01
	Qcoef1[50,1] = .66554E+00
	Qcoef1[50,2] = .32931E-05
	Qcoef1[50,3] = .54823E-08
	//HI
	Qcoef1[51,0] = .40170E+01
	Qcoef1[51,1] = .13003E+01
	Qcoef1[51,2] = -.11409E-04
	Qcoef1[51,3] = .40026E-07
	//ClO
	Qcoef1[52,0] = .36387E+03
	Qcoef1[52,1] = .28367E+02
	Qcoef1[52,2] = .46556E-01
	Qcoef1[52,3] = .12058E-04
	Qcoef1[53,0] = .37039E+03
	Qcoef1[53,1] = .28834E+02
	Qcoef1[53,2] = .47392E-01
	Qcoef1[53,3] = .12522E-04
	//OCS
	Qcoef1[54,0] = -.93697E+00
	Qcoef1[54,1] = .36090E+01
	Qcoef1[54,2] = -.34552E-02
	Qcoef1[54,3] = .17462E-04
	Qcoef1[55,0] = -.11536E+01
	Qcoef1[55,1] = .37028E+01
	Qcoef1[55,2] = -.35582E-02
	Qcoef1[55,3] = .17922E-04
	Qcoef1[56,0] = -.61015E+00
	Qcoef1[56,1] = .72200E+01
	Qcoef1[56,2] = -.70044E-02
	Qcoef1[56,3] = .36708E-04
	Qcoef1[57,0] = -.21569E+00
	Qcoef1[57,1] = .38332E+01
	Qcoef1[57,2] = -.36783E-02
	Qcoef1[57,3] = .19177E-04
	//H2CO
	Qcoef1[58,0] = -.11760E+03
	Qcoef1[58,1] = .46885E+01
	Qcoef1[58,2] = .15088E-01
	Qcoef1[58,3] = .35367E-05
	Qcoef1[59,0] = -.24126E+03
	Qcoef1[59,1] = .96134E+01
	Qcoef1[59,2] = .30938E-01
	Qcoef1[59,3] = .72579E-05
	Qcoef1[60,0] = -.11999E+03
	Qcoef1[60,1] = .52912E+01
	Qcoef1[60,2] = .14686E-01
	Qcoef1[60,3] = .43505E-05
	//HOCl
	Qcoef1[61,0] = -.73640E+03
	Qcoef1[61,1] = .34149E+02
	Qcoef1[61,2] = .93554E-01
	Qcoef1[61,3] = .67409E-04
	Qcoef1[62,0] = -.74923E+03
	Qcoef1[62,1] = .34747E+02
	Qcoef1[62,2] = .95251E-01
	Qcoef1[62,3] = .68523E-04
	//N2
	Qcoef1[63,0] = .13684E+01
	Qcoef1[63,1] = .15756E+01
	Qcoef1[63,2] = -.18511E-04
	Qcoef1[63,3] = .38960E-07
	//HCN
	Qcoef1[64,0] = -.13992E+01
	Qcoef1[64,1] = .29619E+01
	Qcoef1[64,2] = -.17464E-02
	Qcoef1[64,3] = .65937E-05
	Qcoef1[65,0] = -.25869E+01
	Qcoef1[65,1] = .60744E+01
	Qcoef1[65,2] =  -.35719E-02
	Qcoef1[65,3] = .13654E-04
	Qcoef1[66,0] = -.11408E+01
	Qcoef1[66,1] = .20353E+01
	Qcoef1[66,2] = -.12159E-02
	Qcoef1[66,3] = .46375E-05
	//CH3Cl
	Qcoef1[67,0] = -.91416E+03
	Qcoef1[67,1] = .34081E+02
	Qcoef1[67,2] = .75461E-02
	Qcoef1[67,3] = .17933E-03
	Qcoef1[68,0] = -.92868E+03
	Qcoef1[68,1] = .34621E+02
	Qcoef1[68,2] = .76674E-02
	Qcoef1[68,3] = .18217E-03
	//H2O2
	Qcoef1[69,0] = -.36499E+03
	Qcoef1[69,1] = .13712E+02
	Qcoef1[69,2] = .38658E-01
	Qcoef1[69,3] = .23052E-04
	//C2H2
	Qcoef1[70,0] = -.83088E+01
	Qcoef1[70,1] = .14484E+01
	Qcoef1[70,2] = -.25946E-02
	Qcoef1[70,3] = .84612E-05
	Qcoef1[71,0] = -.66736E+02
	Qcoef1[71,1] = .11592E+02
	Qcoef1[71,2] = -.20779E-01
	Qcoef1[71,3] = .67719E-04
	//C2H6
	Qcoef1[72,0] = -.10000E+01
	Qcoef1[72,1] = .00000E+00
	Qcoef1[72,2] = 0
	Qcoef1[72,3] = 0
	//PH3
	Qcoef1[73,0] = -.15068E+03
	Qcoef1[73,1] = .64718E+01
	Qcoef1[73,2] = .12588E-01
	Qcoef1[73,3] = .14759E-04
	//COF2
	Qcoef1[74,0] = -.54180E+04
	Qcoef1[74,1] = .18868E+03
	Qcoef1[74,2] = -.33139E+00
	Qcoef1[74,3] = .18650E-02
	//SF6
	Qcoef1[75,0] = -1
	Qcoef1[75,1] = 0
	Qcoef1[75,2] = 0
	Qcoef1[75,3] = 0
	//H2S
	Qcoef1[76,0] = -.15521E+02
	Qcoef1[76,1] = .83130E+00
	Qcoef1[76,2] = .33656E-02
	Qcoef1[76,3] = -.85691E-06
	Qcoef1[77,0] = -.15561E+02
	Qcoef1[77,1] = .83337E+00
	Qcoef1[77,2] = .33744E-02
	Qcoef1[77,3] = -.85937E-06
	Qcoef1[78,0] = -.62170E+02
	Qcoef1[78,1] = .33295E+01
	Qcoef1[78,2] = .13480E-01
	Qcoef1[78,3] = -.34323E-05
	//HCOOH
	Qcoef1[79,0] = -.29550E+04
	Qcoef1[79,1] = .10349E+03
	Qcoef1[79,2] = -.13146E+00
	Qcoef1[79,3] = .87787E-03
	//HO2
	Qcoef1[80,0] = -.15684E+03
	Qcoef1[80,1] = .74450E+01
	Qcoef1[80,2] = .26011E-01
	Qcoef1[80,3] = -.92704E-06
	//O
	Qcoef1[81,0] = -1
	Qcoef1[81,1] = 0
	Qcoef1[81,2] = 0
	Qcoef1[81,3] = 0
	//ClONO2
	Qcoef1[82,0] = -1
	Qcoef1[82,1] = 0
	Qcoef1[82,2] = 0
	Qcoef1[82,3] = 0
	Qcoef1[83,0] = -1
	Qcoef1[83,1] = 0
	Qcoef1[83,2] = 0
	Qcoef1[83,3] = 0
	//NO+
	Qcoef1[84,0] = .91798E+00
	Qcoef1[84,1] = .10416E+01
	Qcoef1[84,2] = -.11614E-04
	Qcoef1[84,3] = .24499E-07
	
	///////////////////////////////////////////////////
	//QCoef 2
	///////////////////////////////////////////////////
	//H2O
	Qcoef2[0,0] = -.94327E+02
	Qcoef2[0,1] = .81903E+00
	Qcoef2[0,2] = .74005E-04
	Qcoef2[0,3] = .42437E-06
	Qcoef2[1,0] = -.95686E+02
	Qcoef2[1,1] = .82839E+00
	Qcoef2[1,2] = .68311E-04
	Qcoef2[1,3] = .42985E-06
	Qcoef2[2,0] = -.57133E+03
	Qcoef2[2,1] = .49480E+01
	Qcoef2[2,2] = .41517E-03
	Qcoef2[2,3] = .25599E-05
	Qcoef2[3,0] = -.53366E+03
	Qcoef2[3,1] = .44246E+01
	Qcoef2[3,2] = -.46935E-03
	Qcoef2[3,3] = .29548E-05
	//CO2
	Qcoef2[4,0] = -.50925E+03
	Qcoef2[4,1] = .32766E+01
	Qcoef2[4,2] = -.40601E-02
	Qcoef2[4,3] = .40907E-05
	Qcoef2[5,0] = -.11171E+04
	Qcoef2[5,1] = .70346E+01
	Qcoef2[5,2] = -.89063E-02
	Qcoef2[5,3] = .88249E-05
	Qcoef2[6,0] = -.11169E+04
	Qcoef2[6,1] = .71299E+01
	Qcoef2[6,2] = -.89194E-02
	Qcoef2[6,3] = .89268E-05
	Qcoef2[7,0] = -.66816E+04
	Qcoef2[7,1] = .42402E+02
	Qcoef2[7,2] = -.53269E-01
	Qcoef2[7,3] = .52774E-04
	Qcoef2[8,0] = -.25597E+04
	Qcoef2[8,1] = .15855E+02
	Qcoef2[8,2] = -.20440E-01
	Qcoef2[8,3] = .19855E-04
	Qcoef2[9,0] = -.14671E+05
	Qcoef2[9,1] = .91204E+02
	Qcoef2[9,2] = -.11703E+00
	Qcoef2[9,3] = .11406E-03
	Qcoef2[10,0] = -.63775E+03
	Qcoef2[10,1] = .40047E+01
	Qcoef2[10,2] = -.50950E-02
	Qcoef2[10,3] = .50023E-05
	Qcoef2[11,0] = -.73235E+04
	Qcoef2[11,1] = .46140E+02
	Qcoef2[11,2] = -.58473E-01
	Qcoef2[11,3] = .57573E-04
	//O3
	Qcoef2[12,0] = -.11725E+05
	Qcoef2[12,1] = .66515E+02
	Qcoef2[12,2] = -.96010E-01
	Qcoef2[12,3] = .94001E-04
	Qcoef2[13,0] = -.25409E+05
	Qcoef2[13,1] = .14393E+03
	Qcoef2[13,2] = -.20850E+00
	Qcoef2[13,3] = .20357E-03
	Qcoef2[14,0] = -.12624E+05
	Qcoef2[14,1] = .71391E+02
	Qcoef2[14,2] = -.10383E+00
	Qcoef2[14,3] = .10106E-03
	Qcoef2[15,0] = -.14000E+06
	Qcoef2[15,1] = .79825E+03
	Qcoef2[15,2] = -.11465E+01
	Qcoef2[15,3] = .11372E-02
	Qcoef2[16,0] = -.69175E+05
	Qcoef2[16,1] = .39442E+03
	Qcoef2[16,2] = -.56650E+00
	Qcoef2[16,3] = .56189E-03
	//N2O
	Qcoef2[17,0] = -.12673E+05
	Qcoef2[17,1] = .75128E+02
	Qcoef2[17,2] = -.10092E+00
	Qcoef2[17,3] = .95557E-04
	Qcoef2[18,0] = -.90045E+04
	Qcoef2[18,1] = .52833E+02
	Qcoef2[18,2] = -.71771E-01
	Qcoef2[18,3] = .67297E-04
	Qcoef2[19,0] = -.89960E+04
	Qcoef2[19,1] = .53096E+02
	Qcoef2[19,2] = -.71784E-01
	Qcoef2[19,3] = .67592E-04
	Qcoef2[20,0] = -.13978E+05
	Qcoef2[20,1] = .82338E+02
	Qcoef2[20,2] = -.11167E+00
	Qcoef2[20,3] = .10507E-03
	Qcoef2[21,0] = -.79993E+05
	Qcoef2[21,1] = .47265E+03
	Qcoef2[21,2] = -.63804E+00
	Qcoef2[21,3] = .60218E-03
	//CO
	Qcoef2[22,0] = .90723E+01
	Qcoef2[22,1] = .33263E+00
	Qcoef2[22,2] = .11806E-04
	Qcoef2[22,3] = .27035E-07
	Qcoef2[23,0] = .20651E+02
	Qcoef2[23,1] = .68810E+00
	Qcoef2[23,2] = .34217E-04
	Qcoef2[23,3] = .55823E-07
	Qcoef2[24,0] = .98497E+01
	Qcoef2[24,1] = .34713E+00
	Qcoef2[24,2] = .15290E-04
	Qcoef2[24,3] = .28766E-07
	Qcoef2[25,0] = .58498E+02
	Qcoef2[25,1] = .20351E+01
	Qcoef2[25,2] = .87684E-04
	Qcoef2[25,3] = .16554E-06
	Qcoef2[26,0] = .23511E+02
	Qcoef2[26,1] = .71565E+00
	Qcoef2[26,2] = .46681E-04
	Qcoef2[26,3] = .58223E-07
	Qcoef2[27,0] = .11506E+03
	Qcoef2[27,1] = .42727E+01
	Qcoef2[27,2] = .17494E-03
	Qcoef2[27,3] = .34413E-06
	//CH4
	Qcoef2[28,0] = -.10000E+01
	Qcoef2[28,1] = 0
	Qcoef2[28,2] = 0
	Qcoef2[28,3] = 0
	Qcoef2[29,0] = -1
	Qcoef2[29,1] = 0
	Qcoef2[29,2] = 0
	Qcoef2[29,3] = 0
	Qcoef2[30,0] = -1
	Qcoef2[30,1] = 0
	Qcoef2[30,2] = 0
	Qcoef2[30,3] = 0
	//O2
	Qcoef2[31,0] = .36539E+02
	Qcoef2[31,1] = .57015E+00
	Qcoef2[31,2] = .16332E-03
	Qcoef2[31,3] = .45568E-07
	Qcoef2[32,0] = .77306E+02
	Qcoef2[232,1] = .11818E+01
	Qcoef2[32,2] = .38661E-03
	Qcoef2[32,3] = .89415E-07
	Qcoef2[33,0] = .44281E+03
	Qcoef2[33,1] = .69531E+01
	Qcoef2[33,2] = .21669E-02
	Qcoef2[33,3] = .53053E-06
	//NO
	Qcoef2[34,0] = -.23651E+03
	Qcoef2[34,1] = .11752E+02
	Qcoef2[34,2] = .24197E-02
	Qcoef2[34,3] = .66127E-06
	Qcoef2[35,0] = -.13400E+03
	Qcoef2[35,1] = .55747E+01
	Qcoef2[35,2] = .90361E-03
	Qcoef2[35,3] = .42322E-06
	Qcoef2[36,0] = -.29538E+03
	Qcoef2[36,1] = .12704E+02
	Qcoef2[36,2] = .21465E-02
	Qcoef2[36,3] = .96379E-06
	//SO2
	Qcoef2[37,0] = -.21162E+05
	Qcoef2[37,1] = .11846E+03
	Qcoef2[37,2] = -.16648E+00
	Qcoef2[37,3] = .16825E-03
	Qcoef2[38,0] = -.21251E+05
	Qcoef2[38,1] = .11896E+03
	Qcoef2[38,2] = -.16717E+00
	Qcoef2[38,3] = .16895E-03
	//NO2
	Qcoef2[39,0] = -.27185E+05
	Qcoef2[39,1] = .16489E+03
	Qcoef2[39,2] = -.19540E+00
	Qcoef2[39,3] = .22024E-03
	//NH3
	Qcoef2[40,0] = -.47139E+03
	Qcoef2[40,1] = .54035E+01
	Qcoef2[40,2] = .64491E-02
	Qcoef2[40,3] = -.72674E-06
	Qcoef2[41,0] = -.31638E+03
	Qcoef2[41,1] = .36086E+01
	Qcoef2[41,2] = .43087E-02
	Qcoef2[41,3] = -.48207E-06
	//HNO3
	Qcoef2[42,0] = -1
	Qcoef2[42,1] = 0
	Qcoef2[42,2] = 0
	Qcoef2[42,3] = 0
	//OH
	Qcoef2[43,0] = -.17768E+02
	Qcoef2[43,1] = .60403E+00
	Qcoef2[43,2] = -.31129E-04
	Qcoef2[43,3] = .28659E-07
	Qcoef2[44,0] = -.10307E+02
	Qcoef2[44,1] = .58151E+00
	Qcoef2[44,2] = -.14468E-04
	Qcoef2[44,3] = .41404E-07
	Qcoef2[45,0] = -.12505E+03
	Qcoef2[45,1] = .25167E+01
	Qcoef2[45,2] = -.10819E-03
	Qcoef2[45,3] = .11425E-06
	//HF
	Qcoef2[46,0] = -.36045E-0
	Qcoef2[46,1] = .14220E+00
	Qcoef2[46,2] = -.10755E-04
	Qcoef2[46,3] = .65523E-08
	//HCl
	Qcoef2[47,0] = .25039E+01
	Qcoef2[47,1] = .54430E+00
	Qcoef2[47,2] = -.38656E-04
	Qcoef2[47,3] = .39793E-07
	Qcoef2[48,0] = .14998E+01
	Qcoef2[48,1] = .54847E+00
	Qcoef2[48,2] = -.42209E-04
	Qcoef2[48,3] = .41029E-07
	//HBr
	Qcoef2[49,0] = .67229E+01
	Qcoef2[49,1] = .66356E+00
	Qcoef2[49,2] = -.33749E-04
	Qcoef2[49,3] = .54818E-07
	Qcoef2[50,0] = .67752E+01
	Qcoef2[50,1] = .66363E+00
	Qcoef2[50,2] = -.33655E-04
	Qcoef2[50,3] = .54823E-07
	//HI
	Qcoef2[51,0] = .29353E+02
	Qcoef2[51,1] = .12220E+01
	Qcoef2[51,2] = .10209E-04
	Qcoef2[51,3] = .10719E-06
	//ClO
	Qcoef2[52,0] = .90646E+03
	Qcoef2[52,1] = .24437E+02
	Qcoef2[52,2] = .57815E-01
	Qcoef2[52,3] = .67712E-06
	Qcoef2[53,0] = .93217E+03
	Qcoef2[53,1] = .24722E+02
	Qcoef2[53,2] = .59189E-01
	Qcoef2[53,3] = .66517E-06
	//OCS
	Qcoef2[54,0] = -.54125E+04
	Qcoef2[54,1] = .29749E+02
	Qcoef2[54,2] = -.44698E-01
	Qcoef2[54,3] = .38878E-04
	Qcoef2[55,0] = -.55472E+04
	Qcoef2[55,1] = .30489E+02
	Qcoef2[55,2] = -.45809E-01
	Qcoef2[55,3] = .39847E-04
	Qcoef2[56,0] = -.11863E+05
	Qcoef2[56,1] = .64745E+02
	Qcoef2[56,2] = -.98318E-01
	Qcoef2[56,3] = .84563E-04
	Qcoef2[57,0] = -.61288E+04
	Qcoef2[57,1] = .33520E+02
	Qcoef2[57,2] = -.50734E-01
	Qcoef2[57,3] = .43792E-04
	//H2CO
	Qcoef2[58,0] = -.17628E+05
	Qcoef2[58,1] = .91794E+02
	Qcoef2[58,2] = -.13055E+00
	Qcoef2[58,3] = .89336E-04
	Qcoef2[59,0] = -.36151E+05
	Qcoef2[59,1] = .18825E+03
	Qcoef2[59,2] = -.26772E+00
	Qcoef2[59,3] = .18321E-03
	Qcoef2[60,0] = -.17628E+05
	Qcoef2[60,1] = .91794E+02
	Qcoef2[60,2] = -.13055E+00
	Qcoef2[60,3] = .89336E-04
	//HOCl
	Qcoef2[61,0] = -.24164E+05
	Qcoef2[61,1] = .15618E+03
	Qcoef2[61,2] = -.13206E+00
	Qcoef2[61,3] = .21900E-03
	Qcoef2[62,0] = -.24592E+05
	Qcoef2[62,1] = .15895E+03
	Qcoef2[62,2] = -.13440E+00
	Qcoef2[62,3] = .22289E-03
	//N2
	Qcoef2[63,0] = .27907E+02
	Qcoef2[63,1] = .14972E+01
	Qcoef2[63,2] = -.70424E-05
	Qcoef2[63,3] = .11734E-06
	//HCN
	Qcoef2[64,0] = -.78078E+03
	Qcoef2[64,1] = .61725E+01
	Qcoef2[64,2] = -.53816E-02
	Qcoef2[64,3] = .73379E-05
	Qcoef2[65,0] = -.16309E+04
	Qcoef2[65,1] = .12801E+02
	Qcoef2[65,2] = -.11242E-01
	Qcoef2[65,3] = .15268E-04
	Qcoef2[66,0] = -.56301E+03
	Qcoef2[66,1] = .43794E+01
	Qcoef2[66,2] = -.38928E-02
	Qcoef2[66,3] = .52467E-05
	//CH3Cl
	Qcoef2[67,0] = -1
	Qcoef2[67,1] = 0
	Qcoef2[67,2] = 0
	Qcoef2[67,3] = 0
	Qcoef2[68,0] = -1
	Qcoef2[68,1] = 0
	Qcoef2[68,2] = 0
	Qcoef2[68,3] = 0
	//H2O2
	Qcoef2[69,0] = -.27583E+05
	Qcoef2[69,1] = .15064E+03
	Qcoef2[69,2] = -.19917E+00
	Qcoef2[69,3] = .16977E-03
	//C2H2
	Qcoef2[70,0] = -1
	Qcoef2[70,1] = 0
	Qcoef2[70,2] = 0
	Qcoef2[70,3] = 0
	Qcoef2[71,0] = -1
	Qcoef2[71,1] = 0
	Qcoef2[71,2] = 0
	Qcoef2[71,3] = 0
	//C2H6
	Qcoef2[72,0] = -1
	Qcoef2[72,1] = 0
	Qcoef2[72,2] = 0
	Qcoef2[72,3] = 0
	//PH3
	Qcoef2[73,0] = -.28390E+05
	Qcoef2[73,1] = .14463E+03
	Qcoef2[73,2] = -.21473E+00
	Qcoef2[73,3] = .14346E-03
	//COF2
	Qcoef2[74,0] = -1
	Qcoef2[74,1] = 0
	Qcoef2[74,2] = 0
	Qcoef2[74,3] = 0
	//SF6
	Qcoef2[75,0] = -1
	Qcoef2[75,1] = 0
	Qcoef2[75,2] = 0
	Qcoef2[75,3] = 0
	//H2S
	Qcoef2[76,0] = -.37572E+03
	Qcoef2[76,1] = .29157E+01
	Qcoef2[76,2] = -.98642E-03
	Qcoef2[76,3] = .24113E-05
	Qcoef2[77,0] = -.37668E+03
	Qcoef2[77,1] = .29231E+01
	Qcoef2[77,2] = -.98894E-03
	Qcoef2[77,3] = .24174E-05
	Qcoef2[78,0] = -.15049E+04
	Qcoef2[78,1] = .11678E+02
	Qcoef2[78,2] = -.39510E-02
	Qcoef2[78,3] = .96579E-05
	//HCOOH
	Qcoef2[79,0] = -1
	Qcoef2[79,1] = 0
	Qcoef2[79,2] = 0
	Qcoef2[79,3] = 0
	//HO2
	Qcoef2[80,0] = -.32576E+04
	Qcoef2[80,1] = .25539E+02
	Qcoef2[80,2] = -.12803E-01
	Qcoef2[80,3] = .29358E-04
	//O
	Qcoef2[81,0] = -1
	Qcoef2[81,1] = 0
	Qcoef2[81,2] = 0
	Qcoef2[81,3] = 0
	//ClONO2
	Qcoef2[82,0] = -1
	Qcoef2[82,1] = 0
	Qcoef2[82,2] = 0
	Qcoef2[82,3] = 0
	Qcoef2[83,0] = -1
	Qcoef2[83,1] = 0
	Qcoef2[83,2] = 0
	Qcoef2[83,3] = 0
	//NO+
	Qcoef2[84,0] = .17755E+02
	Qcoef2[84,1] = .99262E+00
	Qcoef2[84,2] = -.70814E-05
	Qcoef2[84,3] = .76699E-07
	
	///////////////////////////////////////////////////
	//QCoef 3
	///////////////////////////////////////////////////
	//H2O
	Qcoef3[0,0] = -.11727E+04
	Qcoef3[0,1] = .29261E+01
	Qcoef3[0,2] = -.13299E-02
	Qcoef3[0,3] = .74356E-06
	Qcoef3[1,0] = -.17914E+04
	Qcoef3[1,1] = .39835E+01
	Qcoef3[1,2] = -.19288E-02
	Qcoef3[1,3] = .86144E-06
	Qcoef3[2,0] = -.10665E+05
	Qcoef3[2,1] = .23729E+02
	Qcoef3[2,2] = -.11474E-01
	Qcoef3[2,3] = .51294E-05
	Qcoef3[3,0] = -.12585E+05
	Qcoef3[3,1] = .26707E+02
	Qcoef3[3,2] = -.14454E-01
	Qcoef3[3,3] = .59457E-05
	//CO2
	Qcoef3[4,0] = -.34938E+05
	Qcoef3[4,1] = .66965E+02
	Qcoef3[4,2] = -.44010E-01
	Qcoef3[4,3] = .12662E-04
	Qcoef3[5,0] = -.76420E+05
	Qcoef3[5,1] = .14638E+03
	Qcoef3[5,2] = -.96343E-01
	Qcoef3[5,3] = .27589E-04
	Qcoef3[6,0] = -.76677E+05
	Qcoef3[6,1] = .14693E+03
	Qcoef3[6,2] = -.96622E-01
	Qcoef3[6,3] = .27746E-04
	Qcoef3[7,0] = -.44040E+06
	Qcoef3[7,1] = .84397E+03
	Qcoef3[7,2] = -.55484E+00
	Qcoef3[7,3] = .15946E-03
	Qcoef3[8,0] = -.16856E+06
	Qcoef3[8,1] = .32278E+03
	Qcoef3[8,2] = -.21259E+00
	Qcoef3[8,3] = .60747E-04
	Qcoef3[9,0] = -.96531E+06
	Qcoef3[9,1] = .18487E+04
	Qcoef3[9,2] = -.12172E+01
	Qcoef3[9,3] = .34817E-03
	Qcoef3[10,0] = -.42074E+05
	Qcoef3[10,1] = .80599E+02
	Qcoef3[10,2] = -.53035E-01
	Qcoef3[10,3] = .15202E-04
	Qcoef3[11,0] = -.48298E+06
	Qcoef3[11,1] = .92535E+03
	Qcoef3[11,2] = -.60873E+00
	Qcoef3[11,3] = .17463E-03
	//O3
	Qcoef3[12,0] = -.61205E+06
	Qcoef3[12,1] = .11896E+04
	Qcoef3[12,2] = -.80924E+00
	Qcoef3[12,3] = .24833E-03
	Qcoef3[13,0] = -.13289E+07
	Qcoef3[13,1] = .25826E+04
	Qcoef3[13,2] = -.17574E+01
	Qcoef3[13,3] = .53877E-03
	Qcoef3[14,0] = -.66163E+06
	Qcoef3[14,1] = .12857E+04
	Qcoef3[14,2] = -.87521E+00
	Qcoef3[14,3] = .26802E-03
	Qcoef3[15,0] = -.70636E+07
	Qcoef3[15,1] = .13772E+05
	Qcoef3[15,2] = -.94024E+01
	Qcoef3[15,3] = .29276E-02
	Qcoef3[16,0] = -.34902E+07
	Qcoef3[16,1] = .68051E+04
	Qcoef3[16,2] = -.46459E+01
	Qcoef3[16,3] = .14466E-02
	//N2O
	Qcoef3[17,0] = -.83406E+06
	Qcoef3[17,1] = .15951E+04
	Qcoef3[17,2] = -.10534E+01
	Qcoef3[17,3] = .29849E-03
	Qcoef3[18,0] = -.59281E+06
	Qcoef3[18,1] = .11334E+04
	Qcoef3[18,2] = -.74907E+00
	Qcoef3[18,3] = .21164E-03
	Qcoef3[19,0] = -.59301E+06
	Qcoef3[19,1] = .11339E+04
	Qcoef3[19,2] = -.74918E+00
	Qcoef3[19,3] = .21193E-03
	Qcoef3[20,0] = -.92317E+06
	Qcoef3[20,1] = .17651E+04
	Qcoef3[20,2] = -.11664E+01
	Qcoef3[20,3] = .32984E-03
	Qcoef3[21,0] = -.52739E+07
	Qcoef3[21,1] = .10085E+05
	Qcoef3[21,2] = -.66623E+01
	Qcoef3[21,3] = .18858E-02
	//CO
	Qcoef3[22,0] = .63418E+02
	Qcoef3[22,1] = .20760E+00
	Qcoef3[22,2] = .10895E-03
	Qcoef3[22,3] = .19844E-08
	Qcoef3[23,0] = .13265E+03
	Qcoef3[23,1] = .43434E+00
	Qcoef3[23,2] = .22794E-03
	Qcoef3[23,3] = .41523E-08
	Qcoef3[24,0] = .66581E+02
	Qcoef3[24,1] = .21800E+00
	Qcoef3[24,2] = .11441E-03
	Qcoef3[24,3] = .20839E-08
	Qcoef3[25,0] = .39033E+03
	Qcoef3[25,1] = .12780E+01
	Qcoef3[25,2] = .67066E-03
	Qcoef3[25,3] = .12218E-07
	Qcoef3[26,0] = .13959E+03
	Qcoef3[26,1] = .45717E+00
	Qcoef3[26,2] = .23991E-03
	Qcoef3[26,3] = .43712E-08
	Qcoef3[27,0] = .81756E+03
	Qcoef3[27,1] = .26767E+01
	Qcoef3[27,2] = .14046E-02
	Qcoef3[27,3] = .25378E-07
	//CH4
	Qcoef3[28,0] = -1
	Qcoef3[28,1] = 0
	Qcoef3[28,2] = 0
	Qcoef3[28,3] = 0
	Qcoef3[29,0] = -1
	Qcoef3[29,1] = 0
	Qcoef3[29,2] = 0
	Qcoef3[29,3] = 0
	Qcoef3[30,0] = -1
	Qcoef3[30,1] = 0
	Qcoef3[30,2] = 0
	Qcoef3[30,3] = 0
	//O2
	Qcoef3[31,0] = .76324E+01
	Qcoef3[31,1] = .58006E+00
	Qcoef3[31,2] = .18941E-03
	Qcoef3[31,3] = .27822E-07
	Qcoef3[32,0] = .16157E+02
	Qcoef3[32,1] = .12282E+01
	Qcoef3[32,2] = .40112E-03
	Qcoef3[32,3] = .58919E-07
	Qcoef3[33,0] = .94397E+02
	Qcoef3[33,1] = .71717E+01
	Qcoef3[33,2] = .23423E-02
	Qcoef3[33,3] = .34425E-06
	//NO
	Qcoef3[34,0] = .15610E+04
	Qcoef3[34,1] = .79144E+01
	Qcoef3[34,2] = .51530E-02
	Qcoef3[34,3] = .53799E-07
	Qcoef3[35,0] = .71310E+03
	Qcoef3[35,1] = .36249E+01
	Qcoef3[35,2] = .24251E-02
	Qcoef3[35,3] = .24220E-07
	Qcoef3[36,0] = .16257E+04
	Qcoef3[36,1] = .82742E+01
	Qcoef3[36,2] = .56081E-02
	Qcoef3[36,3] = .54798E-07
	//SO2
	Qcoef3[37,0] = -.10718E+07
	Qcoef3[37,1] = .20831E+04
	Qcoef3[37,2] = -.14138E+01
	Qcoef3[37,3] = .43806E-03
	Qcoef3[38,0] = -.10762E+07
	Qcoef3[38,1] = .20918E+04
	Qcoef3[38,2] = -.14196E+01
	Qcoef3[38,3] = .43988E-03
	//NO2
	Qcoef3[39,0] = -.12837E+07
	Qcoef3[39,1] = .25067E+04
	Qcoef3[39,2] = -.16761E+01
	Qcoef3[39,3] = .53904E-03
	//NH3
	Qcoef3[40,0] = -.17334E+04
	Qcoef3[40,1] = .80988E+01
	Qcoef3[40,2] = .44771E-02
	Qcoef3[40,3] = -.24084E-06
	Qcoef3[41,0] = -.11656E+04
	Qcoef3[41,1] = .54254E+01
	Qcoef3[41,2] = .29809E-02
	Qcoef3[41,3] = -.15750E-06
	//HNO3
	Qcoef3[42,0] = -1
	Qcoef3[42,1] = 0
	Qcoef3[42,2] = 0
	Qcoef3[42,3] = 0
	//OH
	Qcoef3[43,0] = .67499E+02
	Qcoef3[43,1] = .44259E+00
	Qcoef3[43,2] = .71905E-04
	Qcoef3[43,3] = .64732E-08
	Qcoef3[44,0] = .85432E+02
	Qcoef3[44,1] = .37686E+00
	Qcoef3[44,2] = .13435E-03
	Qcoef3[44,3] = .47805E-08
	Qcoef3[45,0] = .21874E+03
	Qcoef3[45,1] = .18729E+01
	Qcoef3[45,2] = .29722E-03
	Qcoef3[45,3] = .28351E-07
	//HF
	Qcoef3[46,0] = .18423E+02
	Qcoef3[46,1] = .10799E+00
	Qcoef3[46,2] = .10568E-04
	Qcoef3[46,3] = .20752E-08
	//HCl
	Qcoef3[47,0] = .92445E+02
	Qcoef3[47,1] = .35539E+00
	Qcoef3[47,2] = .96272E-04
	Qcoef3[47,3] = .71602E-08
	Qcoef3[48,0] = .92519E+02
	Qcoef3[48,1] = .35592E+00
	Qcoef3[48,2] = .96492E-04
	Qcoef3[48,3] = .71775E-08
	//HBr
	Qcoef3[49,0] = .11692E+03
	Qcoef3[49,1] = .42161E+00
	Qcoef3[49,2] = .14690E-03
	Qcoef3[49,3] = .92595E-08
	Qcoef3[50,0] = .11700E+03
	Qcoef3[50,1] = .42161E+00
	Qcoef3[50,2] = .14703E-03
	Qcoef3[50,3] = .92525E-08
	//HI
	Qcoef3[51,0] = .22138E+03
	Qcoef3[51,1] = .78595E+00
	Qcoef3[51,2] = .34579E-03
	Qcoef3[51,3] = .20348E-07
	//ClO
	Qcoef3[52,0] = .14939E+04
	Qcoef3[52,1] = .22720E+02
	Qcoef3[52,2] = .59221E-01
	Qcoef3[52,3] = .92670E-06
	Qcoef3[53,0] = .15244E+04
	Qcoef3[53,1] = .23012E+02
	Qcoef3[53,2] = .60567E-01
	Qcoef3[53,3] = .94609E-06
	//OCS
	Qcoef3[54,0] = -.37301E+06
	Qcoef3[54,1] = .71169E+03
	Qcoef3[54,2] = -.47328E+00
	Qcoef3[54,3] = .13049E-03
	Qcoef3[55,0] = -.38232E+06
	Qcoef3[55,1] = .72945E+03
	Qcoef3[55,2] = -.48509E+00
	Qcoef3[55,3] = .13375E-03
	Qcoef3[56,0] = -.82204E+06
	Qcoef3[56,1] = .15682E+04
	Qcoef3[56,2] = -.10435E+01
	Qcoef3[56,3] = .28668E-03
	Qcoef3[57,0] = -.42390E+06
	Qcoef3[57,1] = .80869E+03
	Qcoef3[57,2] = -.53803E+00
	Qcoef3[57,3] = .14798E-03
	//H2CO
	Qcoef3[58,0] = -.24906E+07
	Qcoef3[58,1] = .45519E+04
	Qcoef3[58,2] = -.28336E+01
	Qcoef3[58,3] = .64198E-03
	Qcoef3[59,0] = -.51075E+07
	Qcoef3[59,1] = .93349E+04
	Qcoef3[59,2] = -.58110E+01
	Qcoef3[59,3] = .13165E-02
	Qcoef3[60,0] = -.24906E+07
	Qcoef3[60,1] = .45519E+04
	Qcoef3[60,2] = -.28336E+01
	Qcoef3[60,3] = .64198E-03
	//HOCl
	Qcoef3[61,0] = -.11326E+07
	Qcoef3[61,1] = .22197E+04
	Qcoef3[61,2] = -.14357E+01
	Qcoef3[61,3] = .49952E-03
	Qcoef3[62,0] = -.11527E+07
	Qcoef3[62,1] = .22590E+04
	Qcoef3[62,2] = -.14612E+01
	Qcoef3[62,3] = .50838E-03
	//N2
	Qcoef3[63,0] = .27986E+03
	Qcoef3[63,1] = .93070E+00
	Qcoef3[63,2] = .42409E-03
	Qcoef3[63,3] = .95573E-08
	//HCN
	Qcoef3[64,0] = -.51989E+05
	Qcoef3[64,1] = .10057E+03
	Qcoef3[64,2] = -.64310E-01
	Qcoef3[64,3] = .19844E-04
	Qcoef3[65,0] = -.10838E+06
	Qcoef3[65,1] = .20960E+03
	Qcoef3[65,2] = -.13411E+00
	Qcoef3[65,3] = .41345E-04
	Qcoef3[66,0] = -.37363E+05
	Qcoef3[66,1] = .72225E+02
	Qcoef3[66,2] = -.46251E-01
	Qcoef3[66,3] = .14237E-04
	//CH3Cl
	Qcoef3[67,0] = -1
	Qcoef3[67,1] = 0
	Qcoef3[67,2] = 0
	Qcoef3[67,3] = 0
	Qcoef3[68,0] = -1
	Qcoef3[68,1] = 0
	Qcoef3[68,2] = 0
	Qcoef3[68,3] = 0
	//H2O2
	Qcoef3[69,0] = -.26863E+07
	Qcoef3[69,1] = .49815E+04
	Qcoef3[69,2] = -.31584E+01
	Qcoef3[69,3] = .78351E-03
	//C2H2
	Qcoef3[70,0] = -1
	Qcoef3[70,1] = 0
	Qcoef3[70,2] = 0
	Qcoef3[70,3] = 0
	Qcoef3[71,0] = -1
	Qcoef3[71,1] = 0
	Qcoef3[71,2] = 0
	Qcoef3[71,3] = 0
	//C2H6
	Qcoef3[72,0] = -1
	Qcoef3[72,1] = 0
	Qcoef3[72,2] = 0
	Qcoef3[72,3] = 0
	//PH3
	Qcoef3[73,0] = -.44074E+07
	Qcoef3[73,1] = .80563E+04
	Qcoef3[73,2] = -.50179E+01
	Qcoef3[73,3] = .11272E-02
	//COF2
	Qcoef3[74,0] = -1
	Qcoef3[74,1] = 0
	Qcoef3[74,2] = 0
	Qcoef3[74,3] = 0
	//SF6
	Qcoef3[75,0] = -1
	Qcoef3[75,1] = 0
	Qcoef3[75,2] = 0
	Qcoef3[75,3] = 0
	//H2S
	Qcoef3[76,0] = -.10043E+05
	Qcoef3[76,1] = .20827E+02
	Qcoef3[76,2] = -.12249E-01
	Qcoef3[76,3] = .48236E-05
	Qcoef3[77,0] = -.10069E+05
	Qcoef3[77,1] = .20881E+02
	Qcoef3[77,2] = -.12280E-01
	Qcoef3[77,3] = .48359E-05
	Qcoef3[78,0] = -.40225E+05
	Qcoef3[78,1] = .83420E+02
	Qcoef3[78,2] = -.49061E-01
	Qcoef3[78,3] = .19320E-04
	//HCOOH
	Qcoef3[79,0] = -1
	Qcoef3[79,1] = 0
	Qcoef3[79,2] = 0
	Qcoef3[79,3] = 0
	//HO2
	Qcoef3[80,0] = -.13056E+06
	Qcoef3[80,1] = .26188E+03
	Qcoef3[80,2] = -.16161E+00
	Qcoef3[80,3] = .61250E-04
	//O
	Qcoef3[81,0] = -1
	Qcoef3[81,1] = 0
	Qcoef3[81,2] = 0
	Qcoef3[81,3] = 0
	//ClONO2
	Qcoef3[82,0] = -1
	Qcoef3[82,1] = 0
	Qcoef3[82,2] = 0
	Qcoef3[82,3] = 0
	Qcoef3[83,0] = -1
	Qcoef3[83,1] = 0
	Qcoef3[83,2] = 0
	Qcoef3[83,3] = 0
	//NO+
	Qcoef3[84,0] = .18634E+03
	Qcoef3[84,1] = .61771E+00
	Qcoef3[84,2] = .27607E-03
	Qcoef3[84,3] = .45828E-08
	
	ivec = w_isovec[Mol] + Iso
	
	if (abs(Tout-296) < 0.00001)
		QT = q296[ivec]
	else
		if (Tout < 70 || Tout > 3005)
			QT = -1
		elseif (Tout >= 70 && Tout <= 500)
			QT = Qcoef1[ivec][0] + Qcoef1[ivec][1]*Tout + Qcoef1[ivec][2]*Tout*Tout + Qcoef1[ivec][3]*Tout*Tout*Tout
		elseif (Tout > 500 && Tout <= 1500)
			QT = Qcoef2[ivec][0] + Qcoef2[ivec][1]*Tout + Qcoef2[ivec][2]*Tout*Tout + Qcoef2[ivec][3]*Tout*Tout*Tout
		elseif (Tout > 1500 && Tout <= 3005)
			QT = Qcoef3[ivec][0] + Qcoef3[ivec][1]*Tout + Qcoef3[ivec][2]*Tout*Tout + Qcoef3[ivec][3]*Tout*Tout*Tout
		endif
	endif
	
	return QT
	
End

Function vecIso()
	Make/O/N=36 w_isovec = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
	Make/O/N=36 w_isonm = {4, 8, 5, 5, 6, 3, 3, 3, 2, 1, 2, 1, 3, 1, 2, 2, 1, 2, 4, 3, 2, 1, 3, 2, 1, 2, 1, 1, 1, 1, 3, 1, 1, 1, 2, 1}
	Variable i, j
	
	for (i = 1; i < 36; i += 1)
		for (j = 0; j < i - 1; j += 1)
			w_isovec[i] = w_isovec[i] + w_isonm[j]
		endfor
	endfor
End

Function complx_p_wr(x, y)
	//Computes real and imaginary parts of complex probability function
	//w(z) = exp(-z^2) * erfc(-i*z)
	//in the upper half-plane z = x*iy where y >= 0
	//only returns real part
	
	Variable x, y
	Variable y1, y2, i, r, d, d1, d2, d3, d4
	Variable wr, wi
	Make/O/N=6 t_, c_, s_
	//x = (wave - wave0) / alpha_voight
	//y = ratio of Lorentzian alpha to Doppler alpha
	//wr = real part
	//wi = imaginary part
	
	t_[0] = .314240376
	t_[1] = .947788391
	t_[2] = 1.59768264
	t_[3] = 2.27950708
	t_[4] = 3.02063703
	t_[5] = 3.8897249
	c_[0] = 1.01172805
	c_[1] = -.75197147
	c_[2] = 1.2557727E-2
	c_[3] = 1.00220082E-2
	c_[4] = -2.42068135E-4
	c_[5] = 5.00848061E-7
	s_[0] = 1.393237
	s_[1] = .231152406
	s_[2] = -.155351466
	s_[3] = 6.21836624E-3
	s_[4] = 9.19082986E-5
	s_[5] = -6.27525958E-7
	
	wr = 0
	wi = 0
	y1 = y + 1.5
	y2 = y1^2
	
	i = 0
	do
		r = x - t_[i]
		d = 1/(r^2+y2)
		d1 = y1 * d
		d2 = r * d
		r = x + t_[i]
		d = 1/(r^2+y2)
		d3 = y1 * d
		d4 = r * d
		wr = wr + c_[i]*(d1+d3)-s_[i]*(d2-d4)
		wi = wi + c_[i]*(d2+d4)+s_[i]*(d1-d3)
		i += 1
	while (i < 5)
	
	return wr
End

Function complx_p_wi(x, y)
	//Computes real and imaginary parts of complex probability function
	//w(z) = exp(-z^2) * erfc(-i*z)
	//in the upper half-plane z = x*iy where y >= 0
	//only returns imaginary part
	
	Variable x, y
	Variable y1, y2, i, r, d, d1, d2, d3, d4
	Variable wr, wi
	Make/O/N=6 t_, c_, s_
	//x = (wave - wave0) / alpha_voight
	//y = ratio of Lorentzian alpha to Doppler alpha
	//wr = real part
	//wi = imaginary part
	
	t_[0] = .314240376
	t_[1] = .947788391
	t_[2] = 1.59768264
	t_[3] = 2.27950708
	t_[4] = 3.02063703
	t_[5] = 3.8897249
	c_[0] = 1.01172805
	c_[1] = -.75197147
	c_[2] = 1.2557727E-2
	c_[3] = 1.00220082E-2
	c_[4] = -2.42068135E-4
	c_[5] = 5.00848061E-7
	s_[0] = 1.393237
	s_[1] = .231152406
	s_[2] = -.155351466
	s_[3] = 6.21836624E-3
	s_[4] = 9.19082986E-5
	s_[5] = -6.27525958E-7
	
	wr = 0
	wi = 0
	y1 = y + 1.5
	y2 = y1^2
	
	i = 0
	do
		r = x - t_[i]
		d = 1/(r^2+y2)
		d1 = y1 * d
		d2 = r * d
		r = x + t_[i]
		d = 1/(r^2+y2)
		d3 = y1 * d
		d4 = r * d
		wr = wr + c_[i]*(d1+d3)-s_[i]*(d2-d4)
		wi = wi + c_[i]*(d2+d4)+s_[i]*(d1-d3)
	while (i < 5)
	
	return wi
End