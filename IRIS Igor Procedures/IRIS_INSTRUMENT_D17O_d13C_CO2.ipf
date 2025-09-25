#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

///////////////////////////////////////////////////////
// Bestiary of Specific Instruments by Serial Number //
///////////////////////////////////////////////////////

// FD117 (Cape Town 13C/18O/17O-CO2)
Function IRIS_BESTIARY_FD117()
	string/G sInstrumentType = "D17O_d13C_CO2_CapeTown"
End

// FD136 (Cambridge CO2 Isotope)
Function IRIS_BESTIARY_FD136()
//	string/G sInstrumentType = "D17O_d13C_CO2"
	string/G sInstrumentType = "D17O_d13C_CO2_FastMixer"
End

// FD143 (Yale CO2 Isotope)
Function IRIS_BESTIARY_FD143()
	string/G sInstrumentType = "D17O_d13C_CO2_FastMixer"
End

// FD140 (LBL CO2 Isotope)
Function IRIS_BESTIARY_FD140()
//	string/G sInstrumentType = "D17O_d13C_CO2_FastMixer"
	string/G sInstrumentType = "D17O_d13C_CO2_LBL"
End

///////////////////////////////////
// Variable Definition Functions //
///////////////////////////////////

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
	
	// INSTRUCTIONS:
	// For each output variable, assign string values for its name, sourceDataName, sourceDataType, units, and format;
	// and assign numeric values for calibrateOrNot (boolean), rescaleFactor, and diagnosticSlot.
	// Use the existing code for examples of how to assign those strings and numeric values.
	// For each output variable, those assignment statements must be followed by the line:
	// outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	// (entered exactly like that, character for character).
	// Do not use commas in any of the strings, as the configuration is saved as a comma delimited text file.
	
	name = "Δ'17O" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "CapD17O" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "avg" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "‰" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.4f" // sets the number format for onscreen display
	calibrateOrNot = 0 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "Δ'17O (L1-L2 Mix)" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "CapD17O_alt" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
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
	
	name = "δ13C (VPDB) (L1-L2 Mix)" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "d13C_VPDB_Avg_alt" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
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
	
	name = "δ17O (VSMOW) (L1-L2 Mix)" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "d17O_VSMOW_Avg_alt" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
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
	
	name = "δ18O (VSMOW) (L1-L2 Mix)" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "d18O_VSMOW_Avg_alt" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
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
	
	name = "CO2 Mole Fraction (L1-L2 Mix)" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "CO2_Avg_alt" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
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
	
	name = "626 Mole Fraction (L1)" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "i626" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "ppm" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.2f" // sets the number format for onscreen display
	calibrateOrNot = 1 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1/1000 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 1 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "626 Mole Fraction (L2)" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "i626_A" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "ppm" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.2f" // sets the number format for onscreen display
	calibrateOrNot = 1 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1/1000 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "636 Mole Fraction (L1)" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "i636" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "ppm" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.2f" // sets the number format for onscreen display
	calibrateOrNot = 1 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1/1000 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "627 Mole Fraction (L2)" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "i627_A" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "ppm" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.2f" // sets the number format for onscreen display
	calibrateOrNot = 1 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1/1000 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "628 Mole Fraction (L1)" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "i628" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "ppm" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.2f" // sets the number format for onscreen display
	calibrateOrNot = 1 // set calibrateOrNot = 1 if the value for each gas fill period needs to be calibrated against reference gas(es); set calibrateOrNot = 0 otherwise
	rescaleFactor = 1/1000 // e.g. set rescaleFactor = 1/1000 to convert ppb to ppm; set rescaleFactor = 1 for no rescaling
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "628 Mole Fraction (L2)" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "i628_A" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
	sourceDataType = "str" // set sourceDataType = "str" for data on the str_source_rtime time grid; set sourceDataType = "stc" for data on the "stc_time" time grid; set sourceDataType = "avg" for data on the cell-fill-period time grid
	units = "ppm" // sets the units that will accompany the variable when saved to disk or displayed onscreen
	format = "%.2f" // sets the number format for onscreen display
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
	
	name = "Unreferenced Δ'17O (L1-L2 Mix)" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "capDel17O_alt" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
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
	diagnosticSlot = 2 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "Unreferenced δ13C (L1-L2 Mix)" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "del13C_alt" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
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
	
	name = "Unreferenced δ17O (L1-L2 Mix)" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "del17O_alt" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
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
	diagnosticSlot = 0 // set diagnosticSlot = 1, 2, 3 to assign str or stc data to one of the three plots in the diagnostic graph; set diagnosticSlot = 0 otherwise
	outputIndex = IRIS_UTILITY_DefineVariable( outputIndex, name, sourceDataName, sourceDataType, units, format, calibrateOrNot, rescaleFactor, diagnosticSlot )
	
	name = "Unreferenced δ18O (L1-L2 Mix)" // the name of the variable that will accompany its values when saved to disk or displayed onscreen
	sourceDataName = "del18O_alt" // the name of the source wave that will be averaged and/or calibrated and/or shown to the user
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
	
	output1_gasID = 3 // 3 is the first sample gas
	output2_gasID = 3 // 3 is the first sample gas
	output3_gasID = 3 // 3 is the first sample gas
	gasToGraph1 = 1 // 1 is all the sample gases
	gasToGraph2 = 1 // 2 is all the sample gases
	output1_variableID = IRIS_UTILITY_GetOutputIndexFromName( "Δ'17O" )
	output2_variableID = IRIS_UTILITY_GetOutputIndexFromName( "δ13C (VPDB)" )
	output3_variableID = IRIS_UTILITY_GetOutputIndexFromName( "CO2 Mole Fraction" )
	variableToGraph1 = IRIS_UTILITY_GetOutputIndexFromName( "Δ'17O" )
	variableToGraph2 = IRIS_UTILITY_GetOutputIndexFromName( "CO2 Mole Fraction" )
	
End

Function IRIS_SCHEME_DefineVariables_D17O_d13C_CO2_FastMixer()
	
	IRIS_SCHEME_DefineVariables_D17O_d13C_CO2()
	
End

Function IRIS_SCHEME_DefineVariables_D17O_d13C_CO2_CapeTown()
	
	IRIS_SCHEME_DefineVariables_D17O_d13C_CO2()
	
End

Function IRIS_SCHEME_DefineVariables_D17O_d13C_CO2_LBL()
	
	IRIS_SCHEME_DefineVariables_D17O_d13C_CO2()
	
End

////////////////////////////////////
// Parameter Definition Functions //
////////////////////////////////////

Function IRIS_SCHEME_DefineParams_D17O_d13C_CO2()
	
	// === LOCAL VARIABLE DECLARATIONS ===
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	variable i
		
	// === DEFINE INSTRUMENT-SPECIFIC PARAMETERS ===
	
	// INSTRUCTIONS:
	// The syntax is: IRIS_UTILITY_DefineParameter( name, default value, units, type ),
	// where all those input parameters are strings, and where the type determines where in the GUI the parameter will appear.
	// The type must be "gas info", "system basic", "system advanced", or "hidden" (or "calibration" or "filter", but you should not be messing with those).
	// Do not use commas in any of the strings, as the configuration is saved as a comma delimited text file.
	
	// GAS INFO PARAMETERS
	for(i=0;i<numSampleGases;i+=1)
		IRIS_UTILITY_DefineParameter( "Sample " + num2str(i+1) + ": " + "ID", "unknown", "", "gas info")
	endfor
	for(i=0;i<numRefGases;i+=1)
		IRIS_UTILITY_DefineParameter( "Reference " + num2str(i+1) + ": " + "ID", "unknown", "", "gas info" )
		IRIS_UTILITY_DefineParameter( "Reference " + num2str(i+1) + ": " + "CO2 Mole Fraction", "unknown", "ppm", "gas info" )
		IRIS_UTILITY_DefineParameter( "Reference " + num2str(i+1) + ": " + "δ13C", "unknown", "‰ VPDB", "gas info" )
		IRIS_UTILITY_DefineParameter( "Reference " + num2str(i+1) + ": " + "δ18O", "unknown", "‰ VSMOW", "gas info" )
		IRIS_UTILITY_DefineParameter( "Reference " + num2str(i+1) + ": " + "δ17O", "unknown", "‰ VSMOW", "gas info" )
	endfor
	
	// BASIC SYSTEM PARAMETERS
	IRIS_UTILITY_DefineParameter( "Number of Cycles", "10", "(use 0 for perpetual run)", "system basic" )
	IRIS_UTILITY_DefineParameter( "Time Limit", "24", "hours", "system basic" )
	
	// ADVANCED SYSTEM PARAMETERS
	IRIS_UTILITY_DefineParameter( "Reference Slope (λ)", "0.528", "", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Measurement Duration", "64", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Time to Ignore at Start of Measurement", "5", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Subtract Background Spectrum", "y", "(y/n)", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Background Measurement Interval", "0", "minutes (use 0 for infinity)", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Number of Flushes of Int Vol", "0", "", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Number of Flushes of Cell", "0", "", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Vacuum Time before Flush of Int Vol", "5", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Vacuum Time before Final Fill of Int Vol", "10", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Vacuum Time before Flush of Cell", "10", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Vacuum Time before Final Fill of Cell", "20", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Vacuum Time before Background", "30", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Time to Wait for Fill of Cell from Int Vol", "2", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Target Cell Pressure", "40", "Torr", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Target Pressure for Flush of Int Vol", "40", "Torr", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Target Pressure for Flush of Cell", "40", "Torr", "system advanced" )
//	IRIS_UTILITY_DefineParameter( "Baseline Poly Order without Background", "2", "(will be 1 with background)", "system advanced" )
	for(i=0;i<numSampleGases;i+=1)
		IRIS_UTILITY_DefineParameter( "ECL Index for Sample " + num2str(i+1), num2str(i+1), "", "system advanced" )
	endfor
	for(i=0;i<numRefGases;i+=1)
		IRIS_UTILITY_DefineParameter( "ECL Index for Reference " + num2str(i+1), num2str(max(100,numSampleGases)+i+1), "", "system advanced" )
	endfor
//	IRIS_UTILITY_DefineParameter( "ECL Index for Zero Air", num2str(numSampleGases+numRefGases+1), "", "system advanced" )
	IRIS_UTILITY_DefineParameter( "ECL Index for Transition", "0", "", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Valve # for Sample Orifice", "1", "(counting from 1)", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Valve # for Reference Orifice", "2", "(counting from 1)", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Valve # for Reference Tank", "11", "(counting from 1)", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Valve # for Cell", "15", "(counting from 1)", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Valve # for Int Vol", "12", "(counting from 1)", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Valve # for Vacuum", "14", "(counting from 1)", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Valve # for Second Vacuum", "9", "(counting from 1)", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Valve # for Fast Cell Flush", "13", "(counting from 1)", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Valve # for Ref. Orifice Flush", "10", "(counting from 1)", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Pressure Sensor Number for Cell", "0", "", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Pressure Sensor Number for Int Vol", "1", "", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Ratio of Total System Volume to Int Vol", "4.3", "", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Valve Action Time Spacer", "0.3", "seconds", "system advanced" )
	
	// PARAMETERS THAT DO NOT APPEAR IN THE GUI
	IRIS_UTILITY_DefineParameter( "Pressure Sensor Limit for Int Vol", "1000", "", "hidden" )
	IRIS_UTILITY_DefineParameter( "Pressure Sensor Limit for Cell", "100", "", "hidden" )
	IRIS_UTILITY_DefineParameter( "Number of Aliquots per Sample", "1", "", "hidden" )
	IRIS_UTILITY_DefineParameter( "Background Measurement Duration", "15", "seconds", "hidden" )
	
End

Function IRIS_SCHEME_DefineParams_D17O_d13C_CO2_FastMixer()
	
	// === LOCAL VARIABLE DECLARATIONS ===
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	variable i
		
	// === DEFINE INSTRUMENT-SPECIFIC PARAMETERS ===
	
	// INSTRUCTIONS:
	// The syntax is: IRIS_UTILITY_DefineParameter( name, default value, units, type ),
	// where all those input parameters are strings, and where the type determines where in the GUI the parameter will appear.
	// The type must be "gas info", "system basic", "system advanced", or "hidden" (or "calibration" or "filter", but you should not be messing with those).
	// Do not use commas in any of the strings, as the configuration is saved as a comma delimited text file.
	
	// GAS INFO PARAMETERS
	for(i=0;i<numSampleGases;i+=1)
		IRIS_UTILITY_DefineParameter( "Sample " + num2str(i+1) + ": " + "ID", "unknown", "", "gas info")
	endfor
	for(i=0;i<numRefGases;i+=1)
		IRIS_UTILITY_DefineParameter( "Reference " + num2str(i+1) + ": " + "ID", "unknown", "", "gas info" )
		IRIS_UTILITY_DefineParameter( "Reference " + num2str(i+1) + ": " + "CO2 Mole Fraction", "unknown", "ppm", "gas info" )
		IRIS_UTILITY_DefineParameter( "Reference " + num2str(i+1) + ": " + "δ13C", "unknown", "‰ VPDB", "gas info" )
		IRIS_UTILITY_DefineParameter( "Reference " + num2str(i+1) + ": " + "δ18O", "unknown", "‰ VSMOW", "gas info" )
		IRIS_UTILITY_DefineParameter( "Reference " + num2str(i+1) + ": " + "δ17O", "unknown", "‰ VSMOW", "gas info" )
	endfor
	
	// BASIC SYSTEM PARAMETERS
//	IRIS_UTILITY_DefineParameter( "Number of Cycles", "10", "(use 0 for perpetual run)", "system basic" )
	IRIS_UTILITY_DefineParameter( "Number of Aliquots per Sample", "10", "", "system basic" )
	IRIS_UTILITY_DefineParameter( "Time Limit", "24", "hours", "system basic" )
	
	// ADVANCED SYSTEM PARAMETERS
	IRIS_UTILITY_DefineParameter( "Manual Sample Injection: (v)ial / (s)eptum / (n)one", "n", "(v/s/n)", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Time to Evacuate CO2 Port", "5", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Background Subtraction: (v)acuum / (z)ero gas / (n)one", "v", "(v/z/n)", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Vacuum Time before Background", "25", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Measurement Duration", "64", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Time to Ignore at Start of Measurement", "5", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Target Cell Pressure", "40", "Torr", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Target Mole Fraction", "400", "ppm", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Use Ref as Pretend Sample", "n", "(y/n)", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Put Ref in Cell Once and Pretend to Switch", "n", "(y/n)", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Sample Manifold: Vacuum Time before Fill", "10", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Flasks: Number of Flushes before Fill", "0", "", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Flasks: Target Pressure for Flush", "200", "Torr", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Flasks: Vacuum Time before Flush", "10", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Flasks: Vacuum Time before Fill", "60", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Flasks: Time to Leave Open After Adding CO2", "20", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Flasks: Number of Dilution Bursts to Help Mixing", "3", "", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Flasks: Dilution Burst Pressure Buildup Time", "5", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Flasks: Do a Forward Flush before Mixing", "y", "(y/n)", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Flasks: Do a Backward Flush (after Mixing)", "y", "(y/n)", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Flasks: Time to Flush Own Output Tube", "2", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Flasks: Time to Flush Joint Output Tube", "20", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Flasks: Time for Wait for First Mix", "1800", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Int Vol: Number of Flushes before Fill", "0", "", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Int Vol: Time to Keep Flush Gas Valve Open", "1", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Int Vol: Vacuum Time before Flush", "5", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Int Vol: Vacuum Time before Fill", "20", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Cell: Number of Flushes before Fill", "0", "", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Cell: Time to Keep Flush Gas Valve Open", "1", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Cell: Vacuum Time before Flush", "5", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Cell: Vacuum Time before Fill", "25", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Time to Wait for Fill of Cell from Int Vol", "4", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Vacuum Time for Ref Cross", "5", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "(Manifold+Bulb)/Manifold Volume Ratio (upper flask)", "14.82", "", "system advanced" )
	IRIS_UTILITY_DefineParameter( "(Manifold+Bulb)/Manifold Volume Ratio (lower flask)", "15.93", "", "system advanced" )
	IRIS_UTILITY_DefineParameter( "(Cell+IntVol)/IntVol Volume Ratio", "5", "", "system advanced" )
//	IRIS_UTILITY_DefineParameter( "Baseline Poly Order without Background", "2", "(will be 1 with background)", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Pressure Offset for Sample Orifice", "0", "Torr", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Pressure Offset for Ref Orifice", "0", "Torr", "system advanced" )
	for(i=0;i<numSampleGases;i+=1)
		IRIS_UTILITY_DefineParameter( "ECL Index for Sample " + num2str(i+1), num2str(i+1), "", "system advanced" )
	endfor
	for(i=0;i<numRefGases;i+=1)
		IRIS_UTILITY_DefineParameter( "ECL Index for Reference " + num2str(i+1), num2str(max(100,numSampleGases)+i+1), "", "system advanced" )
	endfor
	IRIS_UTILITY_DefineParameter( "ECL Index for Transition", "0", "", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Valve Action Time Spacer", "0.3", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Reference Slope (λ)", "0.528", "", "system advanced" )
	
	// PARAMETERS THAT DO NOT APPEAR IN THE GUI
	IRIS_UTILITY_DefineParameter( "Number of Cycles", "1", "(use 0 for perpetual run)", "hidden" )
	IRIS_UTILITY_DefineParameter( "Pressure Sensor Limit for Int Vol", "1000", "", "hidden" )
	IRIS_UTILITY_DefineParameter( "Pressure Sensor Limit for Cell", "100", "", "hidden" )
	IRIS_UTILITY_DefineParameter( "Background Measurement Duration", "15", "seconds", "hidden" )
	
End

Function IRIS_SCHEME_DefineParams_D17O_d13C_CO2_CapeTown()

	IRIS_SCHEME_DefineParams_D17O_d13C_CO2()
	IRIS_UTILITY_SetParamValueByName("Ratio of Total System Volume to Int Vol", "10")
	
End

Function IRIS_SCHEME_DefineParams_D17O_d13C_CO2_LBL()
	
	// === LOCAL VARIABLE DECLARATIONS ===
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	variable i
		
	// === DEFINE INSTRUMENT-SPECIFIC PARAMETERS ===
	
	// INSTRUCTIONS:
	// The syntax is: IRIS_UTILITY_DefineParameter( name, default value, units, type ),
	// where all those input parameters are strings, and where the type determines where in the GUI the parameter will appear.
	// The type must be "gas info", "system basic", "system advanced", or "hidden" (or "calibration" or "filter", but you should not be messing with those).
	// Do not use commas in any of the strings, as the configuration is saved as a comma delimited text file.
	
	// GAS INFO PARAMETERS
	for(i=0;i<numSampleGases;i+=1)
		IRIS_UTILITY_DefineParameter( "Sample " + num2str(i+1) + ": " + "ID", "unknown", "", "gas info")
	endfor
	for(i=0;i<numRefGases;i+=1)
		IRIS_UTILITY_DefineParameter( "Reference " + num2str(i+1) + ": " + "ID", "unknown", "", "gas info" )
		IRIS_UTILITY_DefineParameter( "Reference " + num2str(i+1) + ": " + "CO2 Mole Fraction", "unknown", "ppm", "gas info" )
		IRIS_UTILITY_DefineParameter( "Reference " + num2str(i+1) + ": " + "δ13C", "unknown", "‰ VPDB", "gas info" )
		IRIS_UTILITY_DefineParameter( "Reference " + num2str(i+1) + ": " + "δ18O", "unknown", "‰ VSMOW", "gas info" )
		IRIS_UTILITY_DefineParameter( "Reference " + num2str(i+1) + ": " + "δ17O", "unknown", "‰ VSMOW", "gas info" )
	endfor
	
	// BASIC SYSTEM PARAMETERS
//	IRIS_UTILITY_DefineParameter( "Number of Cycles", "10", "(use 0 for perpetual run)", "system basic" )
	IRIS_UTILITY_DefineParameter( "Number of Aliquots per Sample", "10", "", "system basic" )
	IRIS_UTILITY_DefineParameter( "Time Limit", "24", "hours", "system basic" )
	
	// ADVANCED SYSTEM PARAMETERS
	IRIS_UTILITY_DefineParameter( "Manual Sample Injection: (v)ial / (s)eptum / (n)one", "n", "(v/s/n)", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Time to Evacuate CO2 Port", "5", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Background Subtraction: (v)acuum / (z)ero gas / (n)one", "v", "(v/z/n)", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Vacuum Time before Background", "25", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Measurement Duration", "64", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Time to Ignore at Start of Measurement", "5", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Target Cell Pressure", "40", "Torr", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Target Mole Fraction", "400", "ppm", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Use Ref as Pretend Sample", "n", "(y/n)", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Put Ref in Cell Once and Pretend to Switch", "n", "(y/n)", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Sample Manifold: Vacuum Time before Fill", "10", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Flasks: Number of Flushes before Fill", "0", "", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Flasks: Target Pressure for Flush", "200", "Torr", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Flasks: Vacuum Time before Flush", "10", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Flasks: Vacuum Time before Fill", "60", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Flasks: Time to Leave Open After Adding CO2", "20", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Flasks: Number of Dilution Bursts to Help Mixing", "3", "", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Flasks: Dilution Burst Pressure Buildup Time", "5", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Flasks: Do a Forward Flush before Mixing", "y", "(y/n)", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Flasks: Do a Backward Flush (after Mixing)", "y", "(y/n)", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Flasks: Time to Flush Own Output Tube", "2", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Flasks: Time to Flush Joint Output Tube", "20", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Flasks: Time for Wait for First Mix", "1800", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Int Vol: Number of Flushes before Fill", "0", "", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Int Vol: Time to Keep Flush Gas Valve Open", "1", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Int Vol: Vacuum Time before Flush", "5", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Int Vol: Vacuum Time before Fill", "20", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Cell: Number of Flushes before Fill", "0", "", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Cell: Time to Keep Flush Gas Valve Open", "1", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Cell: Vacuum Time before Flush", "5", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Cell: Vacuum Time before Fill", "25", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Time to Wait for Fill of Cell from Int Vol", "4", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Vacuum Time for Ref Cross", "5", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "(Manifold+Bulb)/Manifold Volume Ratio (upper flask)", "14.82", "", "system advanced" )
	IRIS_UTILITY_DefineParameter( "(Manifold+Bulb)/Manifold Volume Ratio (lower flask)", "15.93", "", "system advanced" )
	IRIS_UTILITY_DefineParameter( "(Cell+IntVol)/IntVol Volume Ratio", "5", "", "system advanced" )
//	IRIS_UTILITY_DefineParameter( "Baseline Poly Order without Background", "2", "(will be 1 with background)", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Pressure Offset for Sample Orifice", "0", "Torr", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Pressure Offset for Ref Orifice", "0", "Torr", "system advanced" )
	for(i=0;i<numSampleGases;i+=1)
		IRIS_UTILITY_DefineParameter( "ECL Index for Sample " + num2str(i+1), num2str(i+1), "", "system advanced" )
	endfor
	for(i=0;i<numRefGases;i+=1)
		IRIS_UTILITY_DefineParameter( "ECL Index for Reference " + num2str(i+1), num2str(max(100,numSampleGases)+i+1), "", "system advanced" )
	endfor
	IRIS_UTILITY_DefineParameter( "ECL Index for Transition", "0", "", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Valve Action Time Spacer", "0.3", "seconds", "system advanced" )
	IRIS_UTILITY_DefineParameter( "Reference Slope (λ)", "0.528", "", "system advanced" )
	
	// PARAMETERS THAT DO NOT APPEAR IN THE GUI
	IRIS_UTILITY_DefineParameter( "Number of Cycles", "1", "(use 0 for perpetual run)", "hidden" )
	IRIS_UTILITY_DefineParameter( "Pressure Sensor Limit for Int Vol", "1000", "", "hidden" )
	IRIS_UTILITY_DefineParameter( "Pressure Sensor Limit for Cell", "100", "", "hidden" )
	IRIS_UTILITY_DefineParameter( "Background Measurement Duration", "15", "seconds", "hidden" )
	
End

//////////////////////////
// Scheduling Functions //
//////////////////////////

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
//   measurement period began. The command to vacuum out the cell will not be issued until the trigger
//   time has reached the desired measurement time relative to timer 1. Everything else will just use the
//   time relative to the previous schedule event (timer 0).
// - The aza command creates a unique situation (so far) because the length of time needed to complete aza is not
//   known in advance. So the command following the aza command does not trigger until the aza is done, and Timer 0
//   is reset when the aza fill completes, so that the timer 0 trigger time for the command after the aza
//   command is not the time since the aza command was sent, but rather the time since the aza fill completed.

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
	
	wave/T wStatusCategoryNames = root:wStatusCategoryNames
	
	SetDataFolder root:
	
	// === DEFINE MAXIMUM AND MINIMUM ALLOWED NUMBERS OF SAMPLE AND REFERENCE GASES BASED ON HARDWARE ===
	
	minNumSamples = 1
	maxNumSamples = 1
	minNumRefs = 1
	maxNumRefs = 1
	
	numSampleGases = max(numSampleGases, minNumSamples)
	numSampleGases = min(numSampleGases, maxNumSamples)
	numRefGases = max(numRefGases, minNumRefs)
	numRefGases = min(numRefGases, maxNumRefs)
	variable numSamplesIncrement = (maxNumSamples == minNumSamples) ? 0 : 1
	variable numRefsIncrement = (maxNumRefs == minNumRefs) ? 0 : 1
	SetVariable/Z IRIS_NumSampleGasInput_tabGas, win = IRISpanel, limits = {minNumSamples,maxNumSamples,numSamplesIncrement}
	SetVariable/Z IRIS_NumRefGasInput_tabGas, win = IRISpanel, limits = {minNumRefs,maxNumRefs,numRefsIncrement}
	IRIS_UTILITY_UpdateNumGasesInTables()
	
	// === DEFINE UP TO 3 SEPARATE STATUS REPORT CATEGORIES ===
	
	// Instructions:
	// (i) Keep the category names short enough to fit in the GUI nicely.
	// (ii) Give unused categories the name " " (i.e. a space).
	// (iii) To have your schedule report a status to one of these specific GUI status fields, give the ReportStatus or WaitForUser event a string argument that begins with the category name followed by a colon, e.g. "TILDAS: Measuring ref".
	wStatusCategoryNames[0] = "TILDAS"
	wStatusCategoryNames[1] = "SWITCHER"
	wStatusCategoryNames[2] = " "
	
	// === GET VARIABLES FROM CONFIG PARAMS ===
	
	// Hardware setup
	string valveNum_sample1 = IRIS_UTILITY_GetParamValueFromName("Valve # for Sample Orifice")
	string valveNum_ref1 = IRIS_UTILITY_GetParamValueFromName("Valve # for Reference Orifice")
	string valveNum_refTank = IRIS_UTILITY_GetParamValueFromName("Valve # for Reference Tank")
	string valveNum_cell = IRIS_UTILITY_GetParamValueFromName("Valve # for Cell")
	string valveNum_intermediateVolume = IRIS_UTILITY_GetParamValueFromName("Valve # for Int Vol")
	string valveNum_mainVac = IRIS_UTILITY_GetParamValueFromName("Valve # for Vacuum")
	string valveNum_secondVacuum = IRIS_UTILITY_GetParamValueFromName("Valve # for Second Vacuum")
	string valveNum_orificeFlush = IRIS_UTILITY_GetParamValueFromName("Valve # for Fast Cell Flush")
	string valveNum_fastFlush = IRIS_UTILITY_GetParamValueFromName("Valve # for Ref. Orifice Flush")
	string PsensorForCell = IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Number for Cell")
	string PsensorForIntVol = IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Number for Int Vol")
	variable system_to_intVol_volume_ratio = str2num(IRIS_UTILITY_GetParamValueFromName("Ratio of Total System Volume to Int Vol"))
	
	// Pressure sensor limits
	variable pressureSensorLimitForIntVol = str2num(IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Limit for Int Vol")) // torr, used to prevent the user from selecting target pressures that can never be measured, which would lead to runaway aza (up to its internal time limit)
	variable pressureSensorLimitForCell = str2num(IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Limit for Cell")) // torr, used to prevent the user from selecting target pressures that can never be measured, which would lead to runaway aza (up to its internal time limit)
	
	// Schedule options
	variable doABG = (stringMatch( IRIS_UTILITY_GetParamValueFromName("Subtract Background Spectrum"), "y*" ) == 1) ? 1 : 0 // 0 = no, 1 = yes
	variable ABGinterval = 60*str2num(IRIS_UTILITY_GetParamValueFromName("Background Measurement Interval")) // seconds
	variable backgroundDuration = str2num(IRIS_UTILITY_GetParamValueFromName("Background Measurement Duration")) // seconds
	variable numIntVolFlushes = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Flushes of Int Vol")) // number of intermediate volume flushes with nitrogen
	variable numCellFlushes = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Flushes of Cell")) // number of multipass cell flushes with nitrogen
	variable measurementDuration = str2num(IRIS_UTILITY_GetParamValueFromName("Measurement Duration")) // seconds
	variable IntVolEvacTimeForFlush = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Flush of Int Vol")) // seconds
	variable IntVolEvacTimeForFinalFill = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Final Fill of Int Vol")) // seconds
	variable cellEvacTimeForFlush = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Flush of Cell")) // seconds
	variable cellEvacTimeForFinalFill = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Final Fill of Cell")) // seconds
	variable cellEvacTimeForABG = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Background")) // seconds
	variable cellFillTimeFromIntVol = str2num(IRIS_UTILITY_GetParamValueFromName("Time to Wait for Fill of Cell from Int Vol")) // seconds
	variable valveActionTimeSpacer = str2num(IRIS_UTILITY_GetParamValueFromName("Valve Action Time Spacer")) // number of seconds to wait before sending valve open or close command, to avoid sending effectively overlapping commands
	
	// Pressures
	variable target_cell_pressure = str2num(IRIS_UTILITY_GetParamValueFromName("Target Cell Pressure")) // torr
	variable pressureTemp
	pressureTemp = target_cell_pressure
	if(pressureTemp > 0.9*pressureSensorLimitForCell) // includes a safety margin of 10% of the sensor range
		pressureTemp = 0.9*pressureSensorLimitForCell
		target_cell_pressure = pressureTemp
		IRIS_UTILITY_SetParamValueByName( "Target Cell Pressure", num2str(target_cell_pressure) )
		IRIS_UTILITY_PropagateParamsToTables()
		IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", "*** WARNING: Target pressure reduced to sensor limit! ***")
	endif
	string IntVolTargetPressureForFlush = IRIS_UTILITY_GetParamValueFromName("Target Pressure for Flush of Int Vol") // torr
	pressureTemp = str2num(IntVolTargetPressureForFlush)
	if(pressureTemp > 0.9*pressureSensorLimitForIntVol) // includes a safety margin of 10% of the sensor range
		pressureTemp = 0.9*pressureSensorLimitForIntVol
		IntVolTargetPressureForFlush = num2str(pressureTemp)
		IRIS_UTILITY_SetParamValueByName( "Target Pressure for Flush of Int Vol", IntVolTargetPressureForFlush )
		IRIS_UTILITY_PropagateParamsToTables()
		IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", "*** WARNING: Target pressure reduced to sensor limit! ***")
	endif
	string cellTargetPressureForFlush = IRIS_UTILITY_GetParamValueFromName("Target Pressure for Flush of Cell") // torr
	pressureTemp = str2num(cellTargetPressureForFlush)
	if(pressureTemp > 0.9*pressureSensorLimitForCell) // includes a safety margin of 10% of the sensor range
		pressureTemp = 0.9*pressureSensorLimitForCell
		cellTargetPressureForFlush = num2str(pressureTemp)
		IRIS_UTILITY_SetParamValueByName( "Target Pressure for Flush of Cell", cellTargetPressureForFlush )
		IRIS_UTILITY_PropagateParamsToTables()
		IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", "*** WARNING: Target pressure reduced to sensor limit! ***")
	endif
	string IntVolTargetPressureForFinalFill = num2istr(target_cell_pressure*system_to_intVol_volume_ratio) // torr
	
	// ECL indices
	string ECL_sampleIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Sample 1")
	string ECL_refIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Reference 1")
	string ECL_transitionIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Transition")
	
	variable i, j
	
	// === MAKE SCHEDULE MODULES TO USE AS BUILDING BLOCKS ===
	
	// USAGE: IRIS_UTILITY_AppendEventToSchedule(sScheduleName, whichTimer, triggerTime, sAction, sArgument, sComment)
	// where sAction is a string that will be appended to "IRIS_EVENT_" to create a reference to a function that takes at most one argument (sArgument), which must be a string
	//	e.g. IRIS_EVENT_SendECL, IRIS_EVENT_ReportStatus, IRIS_EVENT_FetchData, IRIS_EVENT_StartTimer
			
	// Flush int vol via ref. orifice flush valve
	IRIS_UTILITY_ClearSchedule("FlushIntVol")
	if(numIntVolFlushes > 0)
		IRIS_UTILITY_AppendEventToSchedule("FlushIntVol", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_intermediateVolume, "open intermediate volume valve")
		for(i=0;i<numIntVolFlushes;i+=1)
			IRIS_UTILITY_AppendEventToSchedule("FlushIntVol", 0, 0, "ReportStatus", "Evacuating intermediate volume", "")
			IRIS_UTILITY_AppendEventToSchedule("FlushIntVol", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_mainVac, "open vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushIntVol", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_secondVacuum, "open second vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushIntVol", 0, IntVolEvacTimeForFlush, "SendECL", "dnc" + valveNum_mainVac, "close vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushIntVol", 0, valveActionTimeSpacer, "SendECL", "dnc" + valveNum_secondVacuum, "close second vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushIntVol", 0, 0, "ReportStatus", "Filling int. volume with flush gas", "")
			IRIS_UTILITY_AppendEventToSchedule("FlushIntVol", 0, valveActionTimeSpacer, "SendECL", "azb" + PsensorForIntVol + "," + valveNum_orificeFlush + "," + IntVolTargetPressureForFlush, "fill intermediate volume with nitrogen")
		endfor
		IRIS_UTILITY_AppendEventToSchedule("FlushIntVol", 0, valveActionTimeSpacer, "SendECL", "dnc" + valveNum_intermediateVolume, "close intermediate volume valve")
	endif
	
	// Flush Cell via fast flush valve (to not disturb int vol)
	IRIS_UTILITY_ClearSchedule("FlushCell")
	if(numCellFlushes > 0)
		IRIS_UTILITY_AppendEventToSchedule("FlushCell", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_cell, "open Cell valve")
		for(i=0;i<numCellFlushes;i+=1)
			IRIS_UTILITY_AppendEventToSchedule("FlushCell", 0, 0, "ReportStatus", "Evacuating cell", "")
			IRIS_UTILITY_AppendEventToSchedule("FlushCell", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_mainVac, "open vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushCell", 0, cellEvacTimeForFlush, "SendECL", "dnc" + valveNum_mainVac, "close vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushCell", 0, 0, "ReportStatus", "Filling cell with flush gas", "")
			IRIS_UTILITY_AppendEventToSchedule("FlushCell", 0, valveActionTimeSpacer, "SendECL", "azb" + PsensorForCell + "," + valveNum_fastFlush + "," + cellTargetPressureForFlush, "fill cell with nitrogen")
		endfor
		IRIS_UTILITY_AppendEventToSchedule("FlushCell", 0, valveActionTimeSpacer, "SendECL", "dnc" + valveNum_cell, "close cell valve")
	endif
	
	// Measure and Subtract Background Spectrum
	IRIS_UTILITY_ClearSchedule("SubtractBackground")
	IRIS_UTILITY_AppendScheduleToSchedule("SubtractBackground", "FlushCell")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_cell, "open cell valve")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ReportStatus", "Evacuating cell", "")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_mainVac, "open vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, cellEvacTimeForABG, "SendECL", "dnc" + valveNum_mainVac, "close vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "dnc" + valveNum_cell, "close cell valve")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 1, "SendECL", "amabg1", "enable ABG")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ReportStatus", "Measuring spectral background", "")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "aq", "do a BG measurement")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, backgroundDuration, "", "", "wait for ABG to complete")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ResetABGtimer", "", "reset ABG timer")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ReportStatus", "Done measuring spectral background", "")
	
	// Fill int vol with Reference
	IRIS_UTILITY_ClearSchedule("FillIntVolWithRef")
	if(IntVolEvacTimeForFinalFill > 0)
		IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithRef", 0, 0, "ReportStatus", "Evacuating intermediate volume", "")
		IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithRef", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_intermediateVolume, "open intermediate volume valve")
		IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithRef", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_mainVac, "open vacuum valve")
		IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithRef", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_secondVacuum, "open second vacuum valve")
		IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithRef", 0, IntVolEvacTimeForFinalFill, "SendECL", "dnc" + valveNum_intermediateVolume, "close intermediate volume valve")
		IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithRef", 0, valveActionTimeSpacer, "SendECL", "dnc" + valveNum_mainVac, "close vacuum valve")
		IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithRef", 0, valveActionTimeSpacer, "SendECL", "dnc" + valveNum_secondVacuum, "close second vacuum valve")
	endif
	IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithRef", 0, 0, "ReportStatus", "Filling int. volume with reference", "")
	IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithRef", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_refTank, "open reference tank valve")
	IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithRef", 0, valveActionTimeSpacer, "SendECL", "azb" + PsensorForIntVol + "," + valveNum_ref1 + "," + IntVolTargetPressureForFinalFill, "fill intermediate volume with working reference")
	IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithRef", 0, valveActionTimeSpacer, "SendECL", "dnc" + valveNum_refTank, "close reference tank valve")
	
	// Fill int vol with Sample
	IRIS_UTILITY_ClearSchedule("FillIntVolWithSample")
	if(IntVolEvacTimeForFinalFill > 0)
		IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithSample", 0, 0, "ReportStatus", "Evacuating intermediate volume", "")
		IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithSample", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_intermediateVolume, "open intermediate volume valve")
		IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithSample", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_mainVac, "open vacuum valve")
		IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithSample", 0, IntVolEvacTimeForFinalFill, "SendECL", "dnc" + valveNum_intermediateVolume, "close intermediate volume valve")
		IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithSample", 0, valveActionTimeSpacer, "SendECL", "dnc" + valveNum_mainVac, "close vacuum valve")
	endif
	IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithSample", 0, 0, "ReportStatus", "Filling int. volume with sample", "")
	IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithSample", 0, valveActionTimeSpacer, "SendECL", "azb" + PsensorForIntVol + "," + valveNum_sample1 + "," + IntVolTargetPressureForFinalFill, "fill intermediate volume with sample")
	
	// Fill Cell from int vol
	IRIS_UTILITY_ClearSchedule("FillCell")
	IRIS_UTILITY_AppendEventToSchedule("FillCell", 0, 0, "ReportStatus", "Evacuating cell", "")
	IRIS_UTILITY_AppendEventToSchedule("FillCell", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_mainVac, "open vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("FillCell", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_cell, "open cell valve")
	IRIS_UTILITY_AppendEventToSchedule("FillCell", 0, cellEvacTimeForFinalFill, "SendECL", "dnc" + valveNum_mainVac, "close vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("FillCell", 0, 0, "ReportStatus", "Filling cell from intermediate volume", "")
	IRIS_UTILITY_AppendEventToSchedule("FillCell", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_intermediateVolume, "open intermediate volume valve")
	IRIS_UTILITY_AppendEventToSchedule("FillCell", 0, cellFillTimeFromIntVol, "SendECL", "dnc" + valveNum_cell, "close cell valve")
	IRIS_UTILITY_AppendEventToSchedule("FillCell", 0, valveActionTimeSpacer, "SendECL", "dnc" + valveNum_intermediateVolume, "close intermediate volume valve")
	
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
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FlushCell") // Flush Cell and then fill it with working reference from int vol
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FillCell")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "StartRefMeas") // Start measuring reference
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 0, 0, "StartTimer", "1", "start timer for reference measurement") // start timer 1
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FlushIntVol") // Flush int vol and then fill it with working reference (while previous ref is being measured in cell)
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FillIntVolWithRef")
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 1, measurementDuration, "", "", "wait for reference measurement to complete") // Wait for reference measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 0, 0, "ReportStatus", "Reference measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "StartTransition")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "SubtractBackground") // Flush Cell and record background spectrum
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
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "dnc1", "close valve 1")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "dnc2", "close valve 2")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "dnc9", "close valve 9")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "dnc11", "close valve 11")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "dnc12", "close valve 12")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "dnc14", "close valve 14")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "dnc15", "close valve 15")
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
	
	// Flush Cell and record background spectrum
	if(doABG == 1)
		IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "SubtractBackground")
	endif
	
	// Flush int vol and then fill it with working reference
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "FlushIntVol")
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "FillIntVolWithRef")
	
	// === BUILD THE CYCLE SCHEDULE ===
	// 3. A schedule called "Cycle", which consists of the things that happen repetitively;
	
	IRIS_UTILITY_ClearSchedule("Cycle")
	
	// Flush Cell and then fill it with working reference from int vol
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FlushCell")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillCell")
	
	// Start measuring reference
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartRefMeas")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "StartTimer", "1", "start timer for reference measurement") // start timer 1
	
	// Flush int vol and then fill it with sample (while working reference is being measured in cell)
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FlushIntVol")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillIntVolWithSample")
	
	// Wait for reference measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 1, measurementDuration, "", "", "wait for reference measurement to complete") // wait until timer 1 reaches measurementDuration
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "ReportStatus", "Reference measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartTransition")
	
	// Flush Cell and then fill it with sample from int vol
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FlushCell")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillCell")
	
	// Start measuring sample
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartSampleMeas")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "StartTimer", "1", "start timer for sample measurement") // start timer 1
	
	// Flush int vol and then fill it with working reference (while sample is being measured in cell)
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FlushIntVol")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillIntVolWithRef")
	
	// Fetch latest data (while sample is being measured in cell)
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
	
	// Flush Cell and then fill it with working reference from int vol
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "FlushCell")
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "FillCell")
	
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
	
	wave/T wStatusCategoryNames = root:wStatusCategoryNames
	
	SetDataFolder root:
	
	// === DEFINE MAXIMUM AND MINIMUM ALLOWED NUMBERS OF SAMPLE AND REFERENCE GASES BASED ON HARDWARE ===
	
	minNumSamples = 1
	maxNumSamples = 1
	minNumRefs = 1
	maxNumRefs = 1
	
	numSampleGases = max(numSampleGases, minNumSamples)
	numSampleGases = min(numSampleGases, maxNumSamples)
	numRefGases = max(numRefGases, minNumRefs)
	numRefGases = min(numRefGases, maxNumRefs)
	variable numSamplesIncrement = (maxNumSamples == minNumSamples) ? 0 : 1
	variable numRefsIncrement = (maxNumRefs == minNumRefs) ? 0 : 1
	SetVariable/Z IRIS_NumSampleGasInput_tabGas, win = IRISpanel, limits = {minNumSamples,maxNumSamples,numSamplesIncrement}
	SetVariable/Z IRIS_NumRefGasInput_tabGas, win = IRISpanel, limits = {minNumRefs,maxNumRefs,numRefsIncrement}
	IRIS_UTILITY_UpdateNumGasesInTables()
	
	// === DEFINE UP TO 3 SEPARATE STATUS REPORT CATEGORIES ===
	
	// Instructions:
	// (i) Keep the category names short enough to fit in the GUI nicely.
	// (ii) Give unused categories the name " " (i.e. a space).
	// (iii) To have your schedule report a status to one of these specific GUI status fields, give the ReportStatus or WaitForUser event a string argument that begins with the category name followed by a colon, e.g. "TILDAS: Measuring ref".
	wStatusCategoryNames[0] = "TILDAS"
	wStatusCategoryNames[1] = "SWITCHER"
	wStatusCategoryNames[2] = " "
	
	// === GET VARIABLES FROM CONFIG PARAMS ===
	
	// Hardware setup
	string valveNum_sample1 = IRIS_UTILITY_GetParamValueFromName("Valve # for Sample Orifice")
	string valveNum_ref1 = IRIS_UTILITY_GetParamValueFromName("Valve # for Reference Orifice")
	string valveNum_refTank = IRIS_UTILITY_GetParamValueFromName("Valve # for Reference Tank")
	string valveNum_intermediateVolume = IRIS_UTILITY_GetParamValueFromName("Valve # for Int Vol")
	string valveNum_flush = IRIS_UTILITY_GetParamValueFromName("Valve # for Flush")
	string valveNum_mainVac = IRIS_UTILITY_GetParamValueFromName("Valve # for Vacuum")
	string valveNum_secondVacuum = IRIS_UTILITY_GetParamValueFromName("Valve # for Second Vacuum")
	string valveNum_cell = IRIS_UTILITY_GetParamValueFromName("Valve # for Cell")
	string PsensorForCell = IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Number for Cell")
	string PsensorForIntVol = IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Number for Int Vol")
	variable system_to_intVol_volume_ratio = str2num(IRIS_UTILITY_GetParamValueFromName("Ratio of Total System Volume to Int Vol"))
	
	// Pressure sensor limits
	variable pressureSensorLimitForIntVol = str2num(IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Limit for Int Vol")) // torr, used to prevent the user from selecting target pressures that can never be measured, which would lead to runaway aza (up to its internal time limit)
	variable pressureSensorLimitForCell = str2num(IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Limit for Cell")) // torr, used to prevent the user from selecting target pressures that can never be measured, which would lead to runaway aza (up to its internal time limit)
	
	// Schedule options
	variable doABG = (stringMatch( IRIS_UTILITY_GetParamValueFromName("Subtract Background Spectrum"), "y*" ) == 1) ? 1 : 0 // 0 = no, 1 = yes
	variable ABGinterval = 60*str2num(IRIS_UTILITY_GetParamValueFromName("Background Measurement Interval")) // seconds
	variable backgroundDuration = str2num(IRIS_UTILITY_GetParamValueFromName("Background Measurement Duration")) // seconds
	variable numIntVolFlushes = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Flushes of Int Vol")) // number of intermediate volume flushes with nitrogen
	variable numCellFlushes = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Flushes of Cell")) // number of multipass cell flushes with nitrogen
	variable measurementDuration = str2num(IRIS_UTILITY_GetParamValueFromName("Measurement Duration")) // seconds
	variable IntVolEvacTimeForFlush = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Flush of Int Vol")) // seconds
	variable IntVolEvacTimeForFinalFill = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Final Fill of Int Vol")) // seconds
	variable cellEvacTimeForFlush = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Flush of Cell")) // seconds
	variable cellEvacTimeForFinalFill = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Final Fill of Cell")) // seconds
	variable cellEvacTimeForABG = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Background")) // seconds
	variable cellFillTimeFromIntVol = str2num(IRIS_UTILITY_GetParamValueFromName("Time to Wait for Fill of Cell from Int Vol")) // seconds
	variable valveActionTimeSpacer = str2num(IRIS_UTILITY_GetParamValueFromName("Valve Action Time Spacer")) // number of seconds to wait before sending valve open or close command, to avoid sending effectively overlapping commands
	
	// Pressures
	variable target_cell_pressure = str2num(IRIS_UTILITY_GetParamValueFromName("Target Cell Pressure")) // torr
	variable pressureTemp
	pressureTemp = target_cell_pressure
	if(pressureTemp > 0.9*pressureSensorLimitForCell) // includes a safety margin of 10% of the sensor range
		pressureTemp = 0.9*pressureSensorLimitForCell
		target_cell_pressure = pressureTemp
		IRIS_UTILITY_SetParamValueByName( "Target Cell Pressure", num2str(target_cell_pressure) )
		IRIS_UTILITY_PropagateParamsToTables()
		IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", "*** WARNING: Target pressure reduced to sensor limit! ***")
	endif
	string IntVolTargetPressureForFlush = IRIS_UTILITY_GetParamValueFromName("Target Pressure for Flush of Int Vol") // torr
	pressureTemp = str2num(IntVolTargetPressureForFlush)
	if(pressureTemp > 0.9*pressureSensorLimitForIntVol) // includes a safety margin of 10% of the sensor range
		pressureTemp = 0.9*pressureSensorLimitForIntVol
		IntVolTargetPressureForFlush = num2str(pressureTemp)
		IRIS_UTILITY_SetParamValueByName( "Target Pressure for Flush of Int Vol", IntVolTargetPressureForFlush )
		IRIS_UTILITY_PropagateParamsToTables()
		IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", "*** WARNING: Target pressure reduced to sensor limit! ***")
	endif
	string cellTargetPressureForFlush = IRIS_UTILITY_GetParamValueFromName("Target Pressure for Flush of Cell") // torr
	pressureTemp = str2num(cellTargetPressureForFlush)
	if(pressureTemp > 0.9*pressureSensorLimitForCell) // includes a safety margin of 10% of the sensor range
		pressureTemp = 0.9*pressureSensorLimitForCell
		cellTargetPressureForFlush = num2str(pressureTemp)
		IRIS_UTILITY_SetParamValueByName( "Target Pressure for Flush of Cell", cellTargetPressureForFlush )
		IRIS_UTILITY_PropagateParamsToTables()
		IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", "*** WARNING: Target pressure reduced to sensor limit! ***")
	endif
	string IntVolTargetPressureForFinalFill = num2istr(target_cell_pressure*system_to_intVol_volume_ratio) // torr
	
	// ECL indices
	string ECL_sampleIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Sample 1")
	string ECL_refIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Reference 1")
	string ECL_transitionIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Transition")
	
	variable i, j
	
	// === MAKE SCHEDULE MODULES TO USE AS BUILDING BLOCKS ===
	
	// USAGE: IRIS_UTILITY_AppendEventToSchedule(sScheduleName, whichTimer, triggerTime, sAction, sArgument, sComment)
	// where sAction is a string that will be appended to "IRIS_EVENT_" to create a reference to a function that takes at most one argument (sArgument), which must be a string
	//	e.g. IRIS_EVENT_SendECL, IRIS_EVENT_ReportStatus, IRIS_EVENT_FetchData, IRIS_EVENT_StartTimer
			
	// Flush int vol
	IRIS_UTILITY_ClearSchedule("FlushIntVol")
	if(numIntVolFlushes > 0)
		IRIS_UTILITY_AppendEventToSchedule("FlushIntVol", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_intermediateVolume, "open intermediate volume valve")
		for(i=0;i<numIntVolFlushes;i+=1)
			IRIS_UTILITY_AppendEventToSchedule("FlushIntVol", 0, 0, "ReportStatus", "Evacuating intermediate volume", "")
			IRIS_UTILITY_AppendEventToSchedule("FlushIntVol", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_mainVac, "open vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushIntVol", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_secondVacuum, "open second vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushIntVol", 0, IntVolEvacTimeForFlush, "SendECL", "dnc" + valveNum_mainVac, "close vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushIntVol", 0, valveActionTimeSpacer, "SendECL", "dnc" + valveNum_secondVacuum, "close second vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushIntVol", 0, 0, "ReportStatus", "Filling int. volume with flush gas", "")
			IRIS_UTILITY_AppendEventToSchedule("FlushIntVol", 0, valveActionTimeSpacer, "SendECL", "azb" + PsensorForIntVol + "," + valveNum_flush + "," + IntVolTargetPressureForFlush, "fill intermediate volume with nitrogen")
		endfor
		IRIS_UTILITY_AppendEventToSchedule("FlushIntVol", 0, valveActionTimeSpacer, "SendECL", "dnc" + valveNum_intermediateVolume, "close intermediate volume valve")
	endif
	
	// Flush Cell
	IRIS_UTILITY_ClearSchedule("FlushCell")
	if(numCellFlushes > 0)
		IRIS_UTILITY_AppendEventToSchedule("FlushCell", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_cell, "open Cell valve")
		for(i=0;i<numCellFlushes;i+=1)
			IRIS_UTILITY_AppendEventToSchedule("FlushCell", 0, 0, "ReportStatus", "Evacuating cell", "")
			IRIS_UTILITY_AppendEventToSchedule("FlushCell", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_mainVac, "open vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushCell", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_secondVacuum, "open second vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushCell", 0, cellEvacTimeForFlush, "SendECL", "dnc" + valveNum_mainVac, "close vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushCell", 0, valveActionTimeSpacer, "SendECL", "dnc" + valveNum_secondVacuum, "close second vacuum valve")
			IRIS_UTILITY_AppendEventToSchedule("FlushCell", 0, 0, "ReportStatus", "Filling cell with flush gas", "")
			IRIS_UTILITY_AppendEventToSchedule("FlushCell", 0, valveActionTimeSpacer, "SendECL", "azb" + PsensorForCell + "," + valveNum_flush + "," + cellTargetPressureForFlush, "fill Cell with nitrogen")
		endfor
		IRIS_UTILITY_AppendEventToSchedule("FlushCell", 0, valveActionTimeSpacer, "SendECL", "dnc" + valveNum_cell, "close Cell valve")
	endif
	
	// Measure and Subtract Background Spectrum
	IRIS_UTILITY_ClearSchedule("SubtractBackground")
	IRIS_UTILITY_AppendScheduleToSchedule("SubtractBackground", "FlushCell")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_cell, "open Cell valve")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ReportStatus", "Evacuating cell", "")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_mainVac, "open vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, cellEvacTimeForABG, "SendECL", "dnc" + valveNum_mainVac, "close vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "dnc" + valveNum_cell, "close Cell valve")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 1, "SendECL", "amabg1", "enable ABG")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ReportStatus", "Measuring spectral background", "")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, valveActionTimeSpacer, "SendECL", "aq", "do a BG measurement")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, backgroundDuration, "", "", "wait for ABG to complete")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ResetABGtimer", "", "reset ABG timer")
	IRIS_UTILITY_AppendEventToSchedule("SubtractBackground", 0, 0, "ReportStatus", "Done measuring spectral background", "")
	
	// Fill int vol with Reference
	IRIS_UTILITY_ClearSchedule("FillIntVolWithRef")
	if(IntVolEvacTimeForFinalFill > 0)
		IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithRef", 0, 0, "ReportStatus", "Evacuating intermediate volume", "")
		IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithRef", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_intermediateVolume, "open intermediate volume valve")
		IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithRef", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_mainVac, "open vacuum valve")
		IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithRef", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_secondVacuum, "open second vacuum valve")
		IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithRef", 0, IntVolEvacTimeForFinalFill, "SendECL", "dnc" + valveNum_intermediateVolume, "close intermediate volume valve")
		IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithRef", 0, valveActionTimeSpacer, "SendECL", "dnc" + valveNum_mainVac, "close vacuum valve")
		IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithRef", 0, valveActionTimeSpacer, "SendECL", "dnc" + valveNum_secondVacuum, "close second vacuum valve")
	endif
	IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithRef", 0, 0, "ReportStatus", "Filling int. volume with reference", "")
	IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithRef", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_refTank, "open reference tank valve")
	IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithRef", 0, valveActionTimeSpacer, "SendECL", "azb" + PsensorForIntVol + "," + valveNum_ref1 + "," + IntVolTargetPressureForFinalFill, "fill intermediate volume with working reference")
	IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithRef", 0, valveActionTimeSpacer, "SendECL", "dnc" + valveNum_refTank, "close reference tank valve")
	
	// Fill int vol with Sample
	IRIS_UTILITY_ClearSchedule("FillIntVolWithSample")
	if(IntVolEvacTimeForFinalFill > 0)
		IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithSample", 0, 0, "ReportStatus", "Evacuating intermediate volume", "")
		IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithSample", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_intermediateVolume, "open intermediate volume valve")
		IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithSample", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_mainVac, "open vacuum valve")
		IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithSample", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_secondVacuum, "open second vacuum valve")
		IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithSample", 0, IntVolEvacTimeForFinalFill, "SendECL", "dnc" + valveNum_intermediateVolume, "close intermediate volume valve")
		IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithSample", 0, valveActionTimeSpacer, "SendECL", "dnc" + valveNum_mainVac, "close vacuum valve")
		IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithSample", 0, valveActionTimeSpacer, "SendECL", "dnc" + valveNum_secondVacuum, "close second vacuum valve")
	endif
	IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithSample", 0, 0, "ReportStatus", "Filling int. volume with sample", "")
	IRIS_UTILITY_AppendEventToSchedule("FillIntVolWithSample", 0, valveActionTimeSpacer, "SendECL", "azb" + PsensorForIntVol + "," + valveNum_sample1 + "," + IntVolTargetPressureForFinalFill, "fill intermediate volume with sample")
	
	// Fill Cell from int vol
	IRIS_UTILITY_ClearSchedule("FillCell")
	IRIS_UTILITY_AppendEventToSchedule("FillCell", 0, 0, "ReportStatus", "Evacuating cell", "")
	IRIS_UTILITY_AppendEventToSchedule("FillCell", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_mainVac, "open vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("FillCell", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_cell, "open Cell valve")
	IRIS_UTILITY_AppendEventToSchedule("FillCell", 0, cellEvacTimeForFinalFill, "SendECL", "dnc" + valveNum_mainVac, "close vacuum valve")
	IRIS_UTILITY_AppendEventToSchedule("FillCell", 0, 0, "ReportStatus", "Filling cell from intermediate volume", "")
	IRIS_UTILITY_AppendEventToSchedule("FillCell", 0, valveActionTimeSpacer, "SendECL", "dno" + valveNum_intermediateVolume, "open intermediate volume valve")
	IRIS_UTILITY_AppendEventToSchedule("FillCell", 0, cellFillTimeFromIntVol, "SendECL", "dnc" + valveNum_cell, "close Cell valve")
	IRIS_UTILITY_AppendEventToSchedule("FillCell", 0, valveActionTimeSpacer, "SendECL", "dnc" + valveNum_intermediateVolume, "close intermediate volume valve")
	
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
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FlushCell") // Flush Cell and then fill it with working reference from int vol
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FillCell")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "StartRefMeas") // Start measuring reference
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 0, 0, "StartTimer", "1", "start timer for reference measurement") // start timer 1
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FlushIntVol") // Flush int vol and then fill it with working reference (while previous ref is being measured in Cell)
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "FillIntVolWithRef")
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 1, measurementDuration, "", "", "wait for reference measurement to complete") // Wait for reference measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("RedoABG", 0, 0, "ReportStatus", "Reference measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "StartTransition")
	IRIS_UTILITY_AppendScheduleToSchedule("RedoABG", "SubtractBackground") // Flush Cell and record background spectrum
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
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "dnc1", "close valve 1")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "dnc2", "close valve 2")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "dnc9", "close valve 9")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "dnc11", "close valve 11")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "dnc12", "close valve 12")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "dnc14", "close valve 14")
	IRIS_UTILITY_AppendEventToSchedule("Reset", 0, valveActionTimeSpacer, "SendECL", "dnc15", "close valve 15")
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
	
	// Flush Cell and record background spectrum
	if(doABG == 1)
		IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "SubtractBackground")
	endif
	
	// Flush int vol and then fill it with working reference
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "FlushIntVol")
	IRIS_UTILITY_AppendScheduleToSchedule("Prologue", "FillIntVolWithRef")
	
	// === BUILD THE CYCLE SCHEDULE ===
	// 3. A schedule called "Cycle", which consists of the things that happen repetitively;
	
	IRIS_UTILITY_ClearSchedule("Cycle")
	
	// Flush Cell and then fill it with working reference from int vol
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FlushCell")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillCell")
	
	// Start measuring reference
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartRefMeas")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "StartTimer", "1", "start timer for reference measurement") // start timer 1
	
	// Flush int vol and then fill it with sample (while working reference is being measured in Cell)
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FlushIntVol")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillIntVolWithSample")
	
	// Wait for reference measurement to complete
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 1, measurementDuration, "", "", "wait for reference measurement to complete") // wait until timer 1 reaches measurementDuration
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "ReportStatus", "Reference measurement complete", "")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartTransition")
	
	// Flush Cell and then fill it with sample from int vol
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FlushCell")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillCell")
	
	// Start measuring sample
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "StartSampleMeas")
	IRIS_UTILITY_AppendEventToSchedule("Cycle", 0, 0, "StartTimer", "1", "start timer for sample measurement") // start timer 1
	
	// Flush int vol and then fill it with working reference (while sample is being measured in Cell)
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FlushIntVol")
	IRIS_UTILITY_AppendScheduleToSchedule("Cycle", "FillIntVolWithRef")
	
	// Fetch latest data (while sample is being measured in Cell)
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
	
	// Flush Cell and then fill it with working reference from int vol
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "FlushCell")
	IRIS_UTILITY_AppendScheduleToSchedule("Epilogue", "FillCell")
	
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

Function IRIS_SCHEME_BuildSchedule_D17O_d13C_CO2_FastMixer()
	
	// NOTE: "UNIVERSAL" sections must be included exactly as they are, exactly where they are.
	
	// === UNIVERSAL: DECLARATIONS (do not modify) ===
	
	NVAR minNumSamples = root:minNumSamples
	NVAR maxNumSamples = root:maxNumSamples
	NVAR minNumRefs = root:minNumRefs
	NVAR maxNumRefs = root:maxNumRefs
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	NVAR numGases = root:numGases
	
	NVAR numSampleGases_prev = root:numSampleGases_prev
	NVAR numRefGases_prev = root:numRefGases_prev
	
	wave/T wStatusCategoryNames = root:wStatusCategoryNames
	
	SetDataFolder root:
	
	// === DEFINE MAXIMUM AND MINIMUM ALLOWED NUMBERS OF SAMPLE AND REFERENCE GASES BASED ON HARDWARE ===
	
	minNumSamples = 1
	maxNumSamples = 100
	minNumRefs = 1
	maxNumRefs = 1
	
	numSampleGases = max(numSampleGases, minNumSamples)
	numSampleGases = min(numSampleGases, maxNumSamples)
	numRefGases = max(numRefGases, minNumRefs)
	numRefGases = min(numRefGases, maxNumRefs)
	variable numSamplesIncrement = (maxNumSamples == minNumSamples) ? 0 : 1
	variable numRefsIncrement = (maxNumRefs == minNumRefs) ? 0 : 1
	SetVariable/Z IRIS_NumSampleGasInput_tabGas, win = IRISpanel, limits = {minNumSamples,maxNumSamples,numSamplesIncrement}
	SetVariable/Z IRIS_NumRefGasInput_tabGas, win = IRISpanel, limits = {minNumRefs,maxNumRefs,numRefsIncrement}
	if( (numSampleGases != numSampleGases_prev) || (numRefGases != numRefGases_prev) )
		IRIS_UTILITY_UpdateNumGasesInTables()
	endif
	
	// === DEFINE UP TO 3 SEPARATE STATUS REPORT CATEGORIES ===
	
	// Instructions:
	// (i) Keep the category names short enough to fit in the GUI nicely.
	// (ii) Give unused categories the name " " (i.e. a space).
	// (iii) To have your schedule report a status to one of these specific GUI status fields, give the ReportStatus or WaitForUser event a string argument that begins with the category name followed by a colon, e.g. "TILDAS: Measuring ref".
	wStatusCategoryNames[0] = "TILDAS"
	wStatusCategoryNames[1] = "SWITCHER"
	wStatusCategoryNames[2] = "MIXER"
//	wStatusCategoryNames[2] = " " // GUI TESTING!!!
	
	// === GET VARIABLES FROM CONFIG PARAMS ===
	
	// Hardware setup
//	string PsensorForCell = IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Number for Cell")
//	string PsensorForIntVol = IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Number for Int Vol")
//	string PsensorForManifoldLowP = IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Number for Manifold Low P")
//	string PsensorForManifoldHighP = IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Number for Manifold High P")
	variable system_to_intVol_volume_ratio = str2num(IRIS_UTILITY_GetParamValueFromName("(Cell+IntVol)/IntVol Volume Ratio"))
	
	// Pressure sensor limits
	variable pressureSensorLimitForIntVol = str2num(IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Limit for Int Vol")) // torr, used to prevent the user from selecting target pressures that can never be measured, which would lead to runaway aza (up to its internal time limit)
	variable pressureSensorLimitForCell = str2num(IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Limit for Cell")) // torr, used to prevent the user from selecting target pressures that can never be measured, which would lead to runaway aza (up to its internal time limit)
	
	// Schedule options
	variable measurementDuration = str2num(IRIS_UTILITY_GetParamValueFromName("Measurement Duration")) // seconds
	variable numAliquots = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Aliquots per Sample"))
	
	variable manualSampleInjectionByVial = (stringMatch( IRIS_UTILITY_GetParamValueFromName("Manual Sample Injection: (v)ial / (s)eptum / (n)one"), "v*" ) == 1) ? 1 : 0 // 0 = no, 1 = yes
	variable manualSampleInjectionBySeptum = (stringMatch( IRIS_UTILITY_GetParamValueFromName("Manual Sample Injection: (v)ial / (s)eptum / (n)one"), "s*" ) == 1) ? 1 : 0 // 0 = no, 1 = yes
	if(manualSampleInjectionByVial == 1)
		manualSampleInjectionBySeptum = 0
	endif
	variable timeToEvacuateCO2port = str2num(IRIS_UTILITY_GetParamValueFromName("Time to Evacuate CO2 Port"))
	
	variable manifold_vacTimeForFill = str2num(IRIS_UTILITY_GetParamValueFromName("Sample Manifold: Vacuum Time before Fill"))
	
	variable flasks_numFlushes = str2num(IRIS_UTILITY_GetParamValueFromName("Flasks: Number of Flushes before Fill"))
	variable flasks_flushPressure = str2num(IRIS_UTILITY_GetParamValueFromName("Flasks: Target Pressure for Flush"))
	variable flasks_vacTimeForFlush = str2num(IRIS_UTILITY_GetParamValueFromName("Flasks: Vacuum Time before Flush"))
	variable flasks_vacTimeForFill = str2num(IRIS_UTILITY_GetParamValueFromName("Flasks: Vacuum Time before Fill"))
	variable timeToLeaveFlaskOpenWithCO2 = str2num(IRIS_UTILITY_GetParamValueFromName("Flasks: Time to Leave Open After Adding CO2"))
	variable flasks_numDilutionBursts = str2num(IRIS_UTILITY_GetParamValueFromName("Flasks: Number of Dilution Bursts to Help Mixing"))
	variable flasks_dilutionBurstBuildupTime = str2num(IRIS_UTILITY_GetParamValueFromName("Flasks: Dilution Burst Pressure Buildup Time"))
	variable flasks_doForwardFlushBeforeMixing = (stringMatch( IRIS_UTILITY_GetParamValueFromName("Flasks: Do a Forward Flush before Mixing"), "y*" ) == 1) ? 1 : 0 // 0 = no, 1 = yes
	variable flasks_doBackwardFlushAfterMixing = (stringMatch( IRIS_UTILITY_GetParamValueFromName("Flasks: Do a Backward Flush (after Mixing)"), "y*" ) == 1) ? 1 : 0 // 0 = no, 1 = yes
	variable flasks_timeToFlushOwnOutputTube = str2num(IRIS_UTILITY_GetParamValueFromName("Flasks: Time to Flush Own Output Tube"))
	variable flasks_timeToFlushJointOutputTube = str2num(IRIS_UTILITY_GetParamValueFromName("Flasks: Time to Flush Joint Output Tube"))
	variable flasks_timeToWaitForFirstMix = str2num(IRIS_UTILITY_GetParamValueFromName("Flasks: Time for Wait for First Mix"))
		
	variable inVol_numFlushes = str2num(IRIS_UTILITY_GetParamValueFromName("Int Vol: Number of Flushes before Fill"))
	variable inVol_vacTimeForFlush = str2num(IRIS_UTILITY_GetParamValueFromName("Int Vol: Vacuum Time before Flush"))
	variable inVol_fillTimeForFlush = str2num(IRIS_UTILITY_GetParamValueFromName("Int Vol: Time to Keep Flush Gas Valve Open"))
	variable inVol_vacTimeForFill = str2num(IRIS_UTILITY_GetParamValueFromName("Int Vol: Vacuum Time before Fill"))
	
	variable vacTimeForRefCross = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time for Ref Cross"))
	
	variable cell_numFlushes = str2num(IRIS_UTILITY_GetParamValueFromName("Cell: Number of Flushes before Fill"))
	variable cell_vacTimeForFlush = str2num(IRIS_UTILITY_GetParamValueFromName("Cell: Vacuum Time before Flush"))
	variable cell_fillTimeForFlush = str2num(IRIS_UTILITY_GetParamValueFromName("Cell: Time to Keep Flush Gas Valve Open"))
	variable cell_vacTimeForFill = str2num(IRIS_UTILITY_GetParamValueFromName("Cell: Vacuum Time before Fill"))
	
	variable transferTimeFromIntVolToCell = str2num(IRIS_UTILITY_GetParamValueFromName("Time to Wait for Fill of Cell from Int Vol"))
	
	variable doABGwithZeroAir = (stringMatch( IRIS_UTILITY_GetParamValueFromName("Background Subtraction: (v)acuum / (z)ero gas / (n)one"), "z*" ) == 1) ? 1 : 0 // 0 = no, 1 = yes
	variable doABGwithVacuum = (stringMatch( IRIS_UTILITY_GetParamValueFromName("Background Subtraction: (v)acuum / (z)ero gas / (n)one"), "v*" ) == 1) ? 1 : 0 // 0 = no, 1 = yes
	if(doABGwithVacuum == 1)
		doABGwithZeroAir = 0
	endif
	
	variable backgroundDuration = str2num(IRIS_UTILITY_GetParamValueFromName("Background Measurement Duration")) // seconds
	variable evacTimeForABG = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Background")) // seconds
	variable pressureOffset_sample = str2num(IRIS_UTILITY_GetParamValueFromName("Pressure Offset for Sample Orifice")) // Torr
	variable pressureOffset_ref = str2num(IRIS_UTILITY_GetParamValueFromName("Pressure Offset for Ref Orifice")) // Torr
	
	variable pretend_Ref_is_Sample = (stringMatch( IRIS_UTILITY_GetParamValueFromName("Use Ref as Pretend Sample"), "y*" ) == 1) ? 1 : 0 // 0 = no, 1 = yes
	variable pretend_to_switch = (stringMatch( IRIS_UTILITY_GetParamValueFromName("Put Ref in Cell Once and Pretend to Switch"), "y*" ) == 1) ? 1 : 0 // 0 = no, 1 = yes
	
//	if(baselinePolyOrder >= 0)
//		baselinePolyOrder = round(baselinePolyOrder)
//	else
//		baselinePolyOrder = 2
//	endif
//	string sBaselinePolyOrder = num2istr(baselinePolyOrder)
	
//	string timeToLetSampleFlowIntoManifold_Part1 = IRIS_UTILITY_GetParamValueFromName("Time to let sample flow into manifold: Part 1")
//	string timeToLetSampleFlowIntoManifold_Part2 = IRIS_UTILITY_GetParamValueFromName("Time to let sample flow into manifold: Part 2")
	variable valveActionTimeSpacer = str2num(IRIS_UTILITY_GetParamValueFromName("Valve Action Time Spacer")) // number of seconds to wait before sending valve open or close command, to avoid sending effectively overlapping commands
	
//	// Pressures
	variable pChanged = 0
	variable target_cell_pressure = str2num(IRIS_UTILITY_GetParamValueFromName("Target Cell Pressure")) // Torr
	if(target_cell_pressure > 0.9*pressureSensorLimitForCell) // includes a safety margin of 10% of the sensor range
		target_cell_pressure = 0.9*pressureSensorLimitForCell
		pChanged = 1
		IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", "*** WARNING: Target pressure reduced to cell sensor limit! ***")
	endif
	variable IntVolTargetPressure_sample = (target_cell_pressure + pressureOffset_sample)*system_to_intVol_volume_ratio // torr
	variable IntVolTargetPressure_ref = (target_cell_pressure + pressureOffset_ref)*system_to_intVol_volume_ratio // torr
	if((IntVolTargetPressure_sample > 0.9*pressureSensorLimitForIntVol) || (IntVolTargetPressure_ref > 0.9*pressureSensorLimitForIntVol)) // includes a safety margin of 10% of the sensor range
		IntVolTargetPressure_sample = 0.9*pressureSensorLimitForIntVol
		IntVolTargetPressure_ref = 0.9*pressureSensorLimitForIntVol
		target_cell_pressure = IntVolTargetPressure_sample/system_to_intVol_volume_ratio
		pChanged = 1
		IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", "*** WARNING: Target pressure reduced to keep int vol pressure below sensor limit! ***")
	endif
	if(pChanged == 1)
		IRIS_UTILITY_SetParamValueByName( "Target Cell Pressure", num2str(target_cell_pressure) )
		IRIS_UTILITY_PropagateParamsToTables()
	endif
	string IntVolTargetPressureString_sample = num2str(IntVolTargetPressure_sample)
	string IntVolTargetPressureString_ref = num2str(IntVolTargetPressure_ref)
	
	variable manifold_to_manifoldPlusFlask_volume_ratio_upperFlask = str2num(IRIS_UTILITY_GetParamValueFromName("(Manifold+Bulb)/Manifold Volume Ratio (upper flask)")) // dimensionless
	variable manifold_to_manifoldPlusFlask_volume_ratio_lowerFlask = str2num(IRIS_UTILITY_GetParamValueFromName("(Manifold+Bulb)/Manifold Volume Ratio (lower flask)")) // dimensionless
	variable target_mole_fraction = str2num(IRIS_UTILITY_GetParamValueFromName("Target Mole Fraction")) // ppm
	target_mole_fraction = target_mole_fraction*1e-6 // conversion from ppm to dimensionless
	
	variable ratio_of_Ptot_to_PCO2_upperFlask = 1/(target_mole_fraction*manifold_to_manifoldPlusFlask_volume_ratio_upperFlask)
	variable ratio_of_Ptot_to_PCO2_lowerFlask = 1/(target_mole_fraction*manifold_to_manifoldPlusFlask_volume_ratio_lowerFlask)
	string ratio_of_Ptot_to_PCO2_string_upperFlask = num2str(ratio_of_Ptot_to_PCO2_upperFlask)
	string ratio_of_Ptot_to_PCO2_string_lowerFlask = num2str(ratio_of_Ptot_to_PCO2_lowerFlask)
	
	// ECL indices
	string ECL_refIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Reference 1")
	string ECL_transitionIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Transition")
	string thisECLindexName
	string thisECLindex
	
	string thisSampleIDparam, thisSampleID
	
	variable i, j
	
	// === MAKE SCHEDULE MODULES TO USE AS BUILDING BLOCKS ===
	
	// USAGE: IRIS_UTILITY_AppendEventToSchedule(sScheduleName, whichTimer, triggerTime, sAction, sArgument, sComment)
	// where sAction is a string that will be appended to "IRIS_EVENT_" to create a reference to a function that takes at most one argument (sArgument), which must be a string
	//	e.g. IRIS_EVENT_SendECL, IRIS_EVENT_ReportStatus, IRIS_EVENT_FetchData, IRIS_EVENT_StartTimer
	
	string thisScheduleName
	
	// SPECIAL NOTES
	
	// Register 10 (R10) must contain either a 1 (ECL commands access upper flask) or 0 (ECL commands access lower flask)
	// Register 1 (R1) must contain the literal number 1
	// Register 4 (R4) must contain the literal number 4
	// Register 34 (R34) stores the dynamic valve number for flask input, either 3 or 4 (counting from 1), computed from R10
	
	// Using new ECL command: dnx,y where x is the valve state (0 or 1) or register containing the valve state (if negative) and y is the valve number (counting from 1) or register containing valve number (if negative)
	// If R10 = 1, then P19 = 1 and fill valve = E3
	// If R10 = 0, then P19 = 0 and fill valve = E4
	// So the P19 state is R10 and the filling valve number is R4 - R10
	// So to set P19: dn-10,19
	// and to open filling valve: cysub,34,4,10 and dn1,-34
	// and to close filling valve: cysub,34,4,10 and dn0,-34
	
	// Filling the intermediate volume takes about 30 sec (this happens while the cell is being measured, except the first time).
	// Evacuating the cell and transferring gas from the intermediate volume takes 30 sec.
	// Measuring the gas in the cell takes 60 sec.
	// So each cut-and-paste cycle takes 180 sec.
	// So the total time is about 30 + n*180 + 90 sec = 120 + n*180 sec, where n is the number of sample-ref cell fill pairs apart from the final ref fill.
	// So to allow 30 min = 1800 sec for the flask to mix, we want 1800 = 120 + n*180 => n = 1680/180 = 9.33.
	// So we will do 10 cycles and thereby allow each flask to mix for 32 minutes.
	
	// THIS BLOCK INITIALIZES REGISTER VALUES FOR DYNAMIC VALVE CONTROL
	thisScheduleName = "InitializeRegisters"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cz0,1,1", "store '1' into Register 1 (R1); a constant")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cz0,4,4", "store '4' into Register 4 (R4); a constant")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cz0,10,1", "store '1' into Register 10 (R10), which must contain either a 1 (ECL commands access upper flask) or 0 (ECL commands access lower flask)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cysub,34,4,10", "update Register 34 (R34), which stores the valve number for flask input, either 3 or 4 (counting from 1), computed from R10")
	
	// THIS BLOCK TOGGLES ECL CONTROL TO THE OTHER MIXER FLASK
	thisScheduleName = "ToggleRegisters"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cysub,10,1,10	", "the register math to toggle R10 back and forth between 0 and 1")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cysub,34,4,10	", "the register math to update R34 with the target flask input valve number according to R10")
	
	// THIS BLOCK DEACTIVATES ALL VALVES
	thisScheduleName = "DeactivateAllValves"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: deactivating all valves", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: deactivating all valves", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc1", "close E1")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc2", "close E2")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc3", "close E3")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc4", "close E4")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc5", "close E5")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc9", "close P9")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc10", "close P10")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc11", "close P11")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc12", "close P12")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc13", "close P13")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc14", "close P14")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc15", "close P15")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc17", "close P17")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc18", "close P18")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc19", "set 3-way valve to lower flask")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: idle", "")
	
	// THIS BLOCK EVACUATES THE WHOLE SAMPLING SYSTEM FROM BOTH ENDS (BUT NOT THE CELL)
	thisScheduleName = "EvacuateSystem"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: evacuating system", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: evacuating system", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc15", "close valve P15 (cell), redundancy just in case")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno17", "open valve P17 (mixer vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 3, "SendECL", "dno14", "open valve P14 (switcher vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 3, "SendECL", "dno12", "open valve P12 (intermediate volume)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 3, "SendECL", "dno9", "open valve P9 (working ref cross vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 3, "SendECL", "dno3", "open valve E3 (upper flask input)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 3, "SendECL", "dno4", "open valve E4 (lower flask input)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, flasks_vacTimeForFill, "SendECL", "dno19", "set 3-way valve to upper flask in case any little pocket of gas is exposed when switching")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, flasks_vacTimeForFill, "SendECL", "", "wait 30 sec for second half of thorough evacuation")
	
	// THIS BLOCK OPENS THE REF GAS SUPPLY PORT
	thisScheduleName = "OpenRefGasSupplyPort"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno11", "open valve P11 (ref gas port)")
	
	// THIS BLOCK EVACUATES THE TARGET FLASK (AND ITS INPUT AND OUTPUT TUBES)
	thisScheduleName = "EvacuateFlask"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "MIXER: evacuating flask", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno17", "open valve P17 (mixer vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, manifold_vacTimeForFill, "SendECL", "dn1,-34", "open valve E3 or E4 (flask input)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, flasks_vacTimeForFill, "SendECL", "dn0,-34", "close valve E3 or E4 (flask input)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc17", "close valve P17 (mixer vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: idle", "")
	
	// THIS BLOCK FILLS THE TARGET FLASK WITH FLUSH GAS (POSSIBLY MULTIPLE TIMES)
	thisScheduleName = "FlushFlask"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	if(flasks_numFlushes > 0)
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "MIXER: flushing flask with N2", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dn1,-34", "open valve E3 or E4 (flask input)")
		for(i=0;i<flasks_numFlushes;i+=1)
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "MIXER: flushing flask with N2: evacuating", "")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno17", "open valve P17 (mixer vac)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, flasks_vacTimeForFlush, "SendECL", "dnc17", "close valve P17 (mixer vac)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "MIXER: flushing flask with N2: fill #" + num2str(i+1), "")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "azb3,5," + num2str(flasks_flushPressure), "control E5 to fill to flasks_flushPressure with N2")
		endfor
//		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "MIXER: flushing flask with N2: evacuating", "")
//		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno17", "open valve P17 (mixer vac)")
//		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, flasks_vacTimeForFill, "SendECL", "dnc17", "close valve P17 (mixer vac)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dn0,-34", "close valve E3 or E4 (flask input)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: idle", "")
	endif
		
	// THIS BLOCK RECORDS THE ZERO OFFSET FOR BOTH MIXER P SENSORS
	thisScheduleName = "RecordMixerZeroPressures"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "cz1,11,12", "capture into R11, the P(zero) of AD12 (the low-P sensor in mixer)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cz1,12,13", "capture into R12, the P(zero) oF AD13 (the high-P sensor in mixer)")
	
	// THIS BLOCK ADDS CO2 TO THE UPPER FLASK, FROM A SMALL VOLUME (e.g. A VIAL) UPSTREAM OF P18
	thisScheduleName = "AddCO2toUpperFlask"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "MIXER: adding CO2 to flask", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno18", "let CO2 sample flow into manifold for 1 sec (exact time not important)")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 1, "SendECL", "dnc18", "and then close valve P18") // testing because pure CO2 amount is 10X too high, but the "sample tube" volume is 2 mL, so expanding once into the 20 mL manifold and evacuating that gets it down to the correct amount
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno17", "open valve P17 (mixer vac) for 4 sec (exact time not important)") // testing because pure CO2 amount is 10X too high, but the "sample tube" volume is 2 mL, so expanding once into the 20 mL manifold and evacuating that gets it down to the correct amount
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 6, "SendECL", "dnc17", "close valve P17 (mixer vac)") // testing because pure CO2 amount is 10X too high, but the "sample tube" volume is 2 mL, so expanding once into the 20 mL manifold and evacuating that gets it down to the correct amount
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno18", "let CO2 sample flow into manifold for 1 sec (exact time not important)") // testing because pure CO2 amount is 10X too high, but the "sample tube" volume is 2 mL, so expanding once into the 20 mL manifold and evacuating that gets it down to the correct amount
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 1, "SendECL", "dnc18", "and then close valve P18 and let it settle 4 sec for readings")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 4, "SendECL", "cz1,13,12", "capture into R13, the P(CO2) of AD12 (the low-P sensor in mixer)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cysub,14,13,11", "store P(CO2) - P(zero) in register 14 (R14) to account for offset in gauge")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cz0,15," + ratio_of_Ptot_to_PCO2_string_upperFlask, "*** store 'ratio_of_Ptot_to_PCO2_string_upperFlask into R15     %%% the 125 factor controls the final [CO2] in the lower flask (it is the inverse of the product of the volume ratio and the target mixing ratio)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cymul,16,14,15", "store R14 * R15 into R16")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cyadd,17,16,12", "store R16 (target pressure) + R12 (high-P sensor zero offset) into R17 to get target high-P sensor reading")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dn1,-34", "open valve E3 or E4 (flask input) to let CO2 expand into flask")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, timeToLeaveFlaskOpenWithCO2, "SendECL", "dn0,-34", "after molecular diffusion 10*1/e time, close valve E3 or E4 (flask input) to isolate flask from manifold")
	
	// THIS BLOCK ADDS CO2 TO THE LOWER FLASK, FROM A SMALL VOLUME (e.g. A VIAL) UPSTREAM OF P18
	thisScheduleName = "AddCO2toLowerFlask"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "MIXER: adding CO2 to flask", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno18", "let CO2 sample flow into manifold for 1 sec (exact time not important)")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 1, "SendECL", "dnc18", "and then close valve P18") // testing because pure CO2 amount is 10X too high, but the "sample tube" volume is 2 mL, so expanding once into the 20 mL manifold and evacuating that gets it down to the correct amount
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno17", "open valve P17 (mixer vac) for 4 sec (exact time not important)") // testing because pure CO2 amount is 10X too high, but the "sample tube" volume is 2 mL, so expanding once into the 20 mL manifold and evacuating that gets it down to the correct amount
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 6, "SendECL", "dnc17", "close valve P17 (mixer vac)") // testing because pure CO2 amount is 10X too high, but the "sample tube" volume is 2 mL, so expanding once into the 20 mL manifold and evacuating that gets it down to the correct amount
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno18", "let CO2 sample flow into manifold for 1 sec (exact time not important)") // testing because pure CO2 amount is 10X too high, but the "sample tube" volume is 2 mL, so expanding once into the 20 mL manifold and evacuating that gets it down to the correct amount
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 1, "SendECL", "dnc18", "and then close valve P18 and let it settle 4 sec for readings")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 4, "SendECL", "cz1,13,12", "capture into R13, the P(CO2) of AD12 (the low-P sensor in mixer)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cysub,14,13,11", "store P(CO2) - P(zero) in register 14 (R14) to account for offset in gauge")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cz0,15," + ratio_of_Ptot_to_PCO2_string_lowerFlask, "*** store ratio_of_Ptot_to_PCO2_string_lowerFlask into R15     %%% the 125 factor controls the final [CO2] in the lower flask (it is the inverse of the product of the volume ratio and the target mixing ratio)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cymul,16,14,15", "store R14 * R15 into R16")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cyadd,17,16,12", "store R16 (target pressure) + R12 (high-P sensor zero offset) into R17 to get target high-P sensor reading")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dn1,-34", "open valve E3 or E4 (flask input) to let CO2 expand into flask")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, timeToLeaveFlaskOpenWithCO2, "SendECL", "dn0,-34", "after molecular diffusion 10*1/e time, close valve E3 or E4 (flask input) to isolate flask from manifold")
	
//	// THIS BLOCK ADDS DILUTION GAS TO THE TARGET FLASK, TO REACH THE TARGET CO2 MIXING RATIO
//	thisScheduleName = "AddDilutionGas"
//	IRIS_UTILITY_ClearSchedule(thisScheduleName)
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dmAdding_dilution_gas_to_the_unfilled_flask", "status message in popup window")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno17", "open valve P17 (mixer vac) to manifold to dispose of unrecoverable CO2")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, manifold_vacTimeForFill, "SendECL", "dnc17", "close valve P17 (mixer vac)")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno5", "open valve E5 (dilution gas) to load up a little pressure in the prep volume")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 1, "SendECL", "dno5", "close valve E5 (dilution gas)")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dn1,-34", "open valve E3 or E4 (flask input) to let dilution gas slam & mix into flask")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 2, "SendECL", "azb3,5,-17", "control E5 to fill to the R17 target P(tot) reading")
	
	// THIS BLOCK ADDS DILUTION GAS TO THE TARGET FLASK, TO REACH THE TARGET CO2 MIXING RATIO
	thisScheduleName = "AddDilutionGas"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "MIXER: adding dilution gas to flask", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno17", "open valve P17 (mixer vac) to manifold to dispose of unrecoverable CO2")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, manifold_vacTimeForFill, "SendECL", "dnc17", "close valve P17 (mixer vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno5", "open valve E5 (dilution gas) to load up pressure in the prep volume")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, flasks_dilutionBurstBuildupTime, "SendECL", "dn1,-34", "open valve E3 or E4 (flask input) to let dilution gas slam & mix into flask")
	if(flasks_numDilutionBursts >= 2)
		for(i=0;i<(flasks_numDilutionBursts-1);i+=1)
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 2, "SendECL", "dn0,-34", "close valve E3 or E4 (flask input) 2 seconds later to load up pressure in the prep volume")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, flasks_dilutionBurstBuildupTime, "SendECL", "dn1,-34", "open valve E3 or E4 (flask input) to let dilution gas slam & mix into flask")
		endfor
	endif
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 2, "SendECL", "azb3,5,-17", "control E5 to fill the rest of the way to the R17 target P(tot) reading")	
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: idle", "")
	
	// THIS BLOCK CLOSES ALL THE MIXER MANIFOLD VALVES
	thisScheduleName = "CloseAllMixerManifoldValves"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: closing all manifold valves", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc3", "close valve E3 (upper flask input)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc4", "close valve E4 (lower flask input)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc5", "close valve E5 (dilution gas supply)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc18", "close valve P18 (CO2 supply)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc17", "close valve P17 (mixer vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: idle", "")
	
	// THIS BLOCK WAITS FOR MIXING OF THE FIRST FLASK FILL
	thisScheduleName = "WaitForFirstMix"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "MIXER: waiting " + num2str(flasks_timeToWaitForFirstMix/60) + " min for first flask to mix", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, flasks_timeToWaitForFirstMix, "ReportStatus", "MIXER: mixing of first flask complete", "")
		
	// THIS BLOCK FORWARD-FLUSHES THE JOINT SAMPLE LINE WITH GAS FROM THE FLASK BEFORE MIXING
	thisScheduleName = "ForwardFlushBeforeMixing"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	if((flasks_doForwardFlushBeforeMixing > 0) && (flasks_timeToFlushOwnOutputTube > 0))
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "MIXER: forward flush: starting flow", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: forward flush: starting flow", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno14", "pre apply vacuum...")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno12", "...all the way through...")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, inVol_vacTimeForFill, "SendECL", "dno1", "...to measurement orifice")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 1, "SendECL", "dn-10,19", "wait 1 sec with flow from the mixed flask, then set 3-way valve to the unmixed flask")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: forward flush: from unmixed flask", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: forward flush: from unmixed flask", "")
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "ToggleRegisters")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, flasks_timeToFlushOwnOutputTube, "SendECL", "dn-10,19", "wait flasks_timeToFlushOwnOutputTube sec with flow from the umixed flask, then set 3-way valve back to the mixed flask")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: forward flush: from mixed flask", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: forward flush: from mixed flask", "")
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "ToggleRegisters")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, flasks_timeToFlushJointOutputTube, "SendECL", "dnc1", "downstream (i.e. forward) flush for flasks_timeToFlushJointOutputTube sec, then close valve E1 (sample orifice)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc12", "close valve P12 (intermediate volume)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc14", "close valve P14 (switcher vac)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: idle", "")
	endif
	
	// THIS BLOCK FORWARD-FLUSHES THE JOINT SAMPLE LINE WITH GAS FROM THE FLASK AFTER MIXING
	thisScheduleName = "ForwardFlushAfterMixing"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	if(flasks_timeToFlushJointOutputTube > 0)
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "MIXER: forward flush: starting flow", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: forward flush: starting flow", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno14", "pre apply vacuum...")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno12", "...all the way through...")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, inVol_vacTimeForFill, "SendECL", "dno1", "...to measurement orifice")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 1, "SendECL", "dn-10,19", "wait 1 sec with flow from old flask, then set 3-way valve to full flask")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: forward flush: from mixed flask", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: forward flush: from mixed flask", "")
		if(flasks_doForwardFlushBeforeMixing > 0)
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, flasks_timeToFlushJointOutputTube, "SendECL", "dnc1", "downstream (i.e. forward) flush for flasks_timeToFlushJointOutputTube sec, then close valve E1 (sample orifice)")
		else
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, flasks_timeToFlushOwnOutputTube + flasks_timeToFlushJointOutputTube, "SendECL", "dnc1", "downstream (i.e. forward) flush for flasks_timeToFlushOwnOutputTube + flasks_timeToFlushJointOutputTube sec, then close valve E1 (sample orifice)")
		endif
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc12", "close valve P12 (intermediate volume)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc14", "close valve P14 (switcher vac)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: idle", "")
	endif
	
	// THIS BLOCK BACK-FLUSHES THE INPUT TUBE OF THE FLASK (AFTER MIXING)
	thisScheduleName = "BackwardFlushAfterMixing"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	if(flasks_doBackwardFlushAfterMixing == 1)
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "MIXER: back-flush: from mixed flask", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno17", "open valve P17 (mixer vac) to evacuate mixer manifold")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, manifold_vacTimeForFill, "SendECL", "dnc17", "wait 5 sec, then close valve P17 (mixer vac)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dn1,-34", "open valve E3 or E4 (flask input) to let a finite portion of the flask gas flow back into the empty manifold")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 1, "SendECL", "dn0,-34", "close valve E3 or E4 (flask input) to isolate flask from manifold")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: idle", "")
	endif
	
	// THIS BLOCK HANDLES MANUAL SAMPLE INJECTION BY VIAL
	for(i=0;i<numSampleGases;i+=1)
		thisScheduleName = "ManualVialInjectionOfSample" + num2str(i+1)
		thisSampleIDparam = "Sample " + num2str(i+1) + ": " + "ID"
		thisSampleID = IRIS_UTILITY_GetParamValueFromName(thisSampleIDparam) // seconds
		IRIS_UTILITY_ClearSchedule(thisScheduleName)
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "WaitForUser", "MIXER: attach sample " + num2str(i+1) + " (" + thisSampleID + ")", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: evacuating CO2 port", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno17", "open valve P17 (mixer vac)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno18", "open valve P18 (to evacuate CO2 port)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, timeToEvacuateCO2port, "SendECL", "dnc18", "close valve P18")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc17", "close valve P17 (mixer vac)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "WaitForUser", "MIXER: open sample " + num2str(i+1) + " (" + thisSampleID + ")", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: idle", "")
	endfor
	
	// THIS BLOCK HANDLES MANUAL SAMPLE INJECTION BY SEPTUM
	for(i=0;i<numSampleGases;i+=1)
		thisScheduleName = "ManualSeptumInjectionOfSample" + num2str(i+1)
		thisSampleIDparam = "Sample " + num2str(i+1) + ": " + "ID"
		thisSampleID = IRIS_UTILITY_GetParamValueFromName(thisSampleIDparam) // seconds
		IRIS_UTILITY_ClearSchedule(thisScheduleName)
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: evacuating CO2 port", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno17", "open valve P17 (mixer vac)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno18", "open valve P18 (to evacuate CO2 port)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, timeToEvacuateCO2port, "SendECL", "dnc18", "close valve P18")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc17", "close valve P17 (mixer vac)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "WaitForUser", "MIXER: inject sample " + num2str(i+1) + " (" + thisSampleID + ")", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: idle", "")
	endfor
	
	// THIS BLOCK MEASURES AND SUBTRACTS A VACUUM SPECTRAL BACKGROUND
	thisScheduleName = "SubtractVacground"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: evacuating cell for spectral background", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno14", "open vac valve")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno15", "open cell valve")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, evacTimeForABG, "SendECL", "dnc15", "pump on cell for evacTimeForABG sec, then close cell valve")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc14", "close vac valve")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "ax1", "set baseline polynomial order to 1")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: measuring spectral background", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 1, "SendECL", "amabg1", "enable ABG")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "aq", "do a BG measurement")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, backgroundDuration, "", "", "wait for ABG to complete")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: idle", "")
	
	// THIS BLOCK MEASURES AND SUBTRACTS A ZERO AIR (OR N2) SPECTRAL BACKGROUND
	thisScheduleName = "SubtractZeroAirBackground"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: evacuating ref cross", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc10", "ensure valve P10 (ref cross zero air) is closed")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc11", "ensure valve P11 (ref port) is closed")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno9", "open valve P9 (ref cross vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, vacTimeForRefCross, "SendECL", "dnc9", "evacuate ref cross for vacTimeForRefCross seconds and then close valve P9 (ref cross vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: evacuating intermediate volume", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno14", "open valve P14 (switcher vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno12", "open valve P12 (intermediate volume)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, inVol_vacTimeForFill, "SendECL", "dnc12", "pump on intermediate volume for inVol_vacTimeForFill sec, then close valve P12 (intermediate volume)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "TILDAS: evacuating cell", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: evacuating cell", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno15", "open valve P15 (cell)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, evacTimeForABG, "SendECL", "dnc15", "pump on cell for evacTimeForABG sec, then close valve P15 (cell)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc14", "close valve P14 (switcher vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "TILDAS: idle", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: filling int vol with zero air (or N2)", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno10", "open valve P10 (ref cross zero air)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "azb1,2," + IntVolTargetPressureString_ref, "fill via valve E2 (ref orifice) until gauge 2 (intermediate volume) reaches IntVolTargetPressureString_ref torr")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: transferring zero air (or N2) to cell", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: transferring zero air (or N2) to cell", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno12", "open valve P12 (intermediate volume)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno15", "open valve P15 (cell)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, transferTimeFromIntVolToCell, "SendECL", "dnc15", "wait 4 seconds to expand gas into cell, then shut cell")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc12", "close valve P12 (intermediate volume)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: measuring spectral background", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 1, "SendECL", "amabg1", "enable ABG")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "aq", "do a BG measurement")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, backgroundDuration, "", "", "wait for ABG to complete")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: idle", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: evacuating ref cross", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc10", "ensure valve P10 (ref cross zero air) is closed")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc11", "ensure valve P11 (ref port) is closed")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno9", "open valve P9 (ref cross vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, vacTimeForRefCross, "SendECL", "dnc9", "evacuate ref cross for vacTimeForRefCross seconds and then close valve P9 (ref cross vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
	
	// THIS BLOCK FILLS THE INTERMEDIATE VOLUME WITH FLUSH GAS (POSSIBLY MULTIPLE TIMES)
	thisScheduleName = "FlushIntVol"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	if(inVol_numFlushes > 0)
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: flushing int vol: evacuating", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno12", "open valve P12 (intermediate volume)")
		for(i=0;i<inVol_numFlushes;i+=1)
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: flushing int vol: evacuating", "")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno14", "open valve P14 (switcher vac)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, inVol_vacTimeForFlush, "SendECL", "dnc14", "pump on intermediate volume for inVol_vacTimeForFlush sec, then close valve P14 (switcher vac)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: flushing int vol: fill #" + num2str(i+1), "")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno13", "add flush gas via valve P13 (flush gas)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, inVol_fillTimeForFlush, "SendECL", "dnc13", "stop adding flush gas via valve P13 (flush gas) after inVol_fillTimeForFlush sec")
		endfor
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc12", "close valve P12 (intermediate volume)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
	endif
	
//	// THIS BLOCK FILLS THE CELL WITH FLUSH GAS (POSSIBLY MULTIPLE TIMES)
//	thisScheduleName = "FlushCell"
//	IRIS_UTILITY_ClearSchedule(thisScheduleName)
//	if(inVol_numFlushes > 0)
//		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: flushing cell: evacuating", "")
//		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bz" + ECL_transitionIndex, "defines ecl index = transition")
//		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "ca1", "executes ecl index")
//		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bdFits1", "suspend fitting")
//		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc12", "ensure P12 (intermediate volume) is closed")
//		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc13", "ensure P13 (flush gas) is closed")
//		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno15", "open valve P15 (cell)")
//			for(i=0;i<inVol_numFlushes;i+=1)
//			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: flushing cell: evacuating", "")
//			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno14", "open valve P14 (switcher vac)")
//			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, cell_vacTimeForFlush, "SendECL", "dnc14", "pump on cell for cell_vacTimeForFlush sec, then close valve P14 (switcher vac)")
//			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: flushing cell: fill #" + num2str(i+1), "")
//			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno13", "add flush gas via valve P13 (flush gas)")
//			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, cell_fillTimeForFlush, "SendECL", "dnc13", "stop adding flush gas via valve P13 (flush gas) after cell_fillTimeForFlush sec")
//		endfor
//		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc15", "close valve P15 (cell)")
//		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
//	endif
	
	// THIS BLOCK FILLS THE CELL WITH FLUSH GAS (POSSIBLY MULTIPLE TIMES)
	thisScheduleName = "FlushCell"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	if(inVol_numFlushes > 0)
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 1, measurementDuration, "ReportStatus", "SWITCHER: flushing cell: evacuating", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bz" + ECL_transitionIndex, "defines ecl index = transition")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "ca1", "executes ecl index")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bdFits1", "suspend fitting")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc12", "ensure P12 (intermediate volume) is closed")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc13", "ensure P13 (flush gas) is closed")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc15", "ensure P15 (cell) is closed")
			for(i=0;i<inVol_numFlushes;i+=1)
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: flushing cell: evacuating", "")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno14", "open valve P14 (switcher vac)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno15", "open valve P15 (cell)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, cell_vacTimeForFlush, "SendECL", "dnc14", "pump on cell for cell_vacTimeForFlush sec, then close valve P14 (switcher vac)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc15", "close valve P15 (cell)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: flushing cell: fill #" + num2str(i+1), "")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno13", "add flush gas via valve P13 (flush gas)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, cell_fillTimeForFlush, "SendECL", "dnc13", "stop adding flush gas via valve P13 (flush gas) after cell_fillTimeForFlush sec")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno15", "open valve P15 (cell)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, transferTimeFromIntVolToCell, "SendECL", "dnc15", "close valve P15 (cell)")
		endfor
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
	endif
	
	// THIS BLOCK PRETENDS TO FILL THE CELL WITH FLUSH GAS (POSSIBLY MULTIPLE TIMES) // for performance testing
	thisScheduleName = "PretendToFlushCell"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	if(inVol_numFlushes > 0)
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 1, measurementDuration, "ReportStatus", "SWITCHER: pretend cell flush: evacuating", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bz" + ECL_transitionIndex, "defines ecl index = transition")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "ca1", "executes ecl index")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bdFits1", "suspend fitting")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "", "fake: ensure P12 (intermediate volume) is closed")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "", "fake: ensure P13 (flush gas) is closed")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "", "fake: ensure P15 (cell) is closed")
			for(i=0;i<inVol_numFlushes;i+=1)
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: pretend cell flush: evacuating", "")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "", "fake: open valve P14 (switcher vac)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "", "fake: open valve P15 (cell)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, cell_vacTimeForFlush, "SendECL", "", "fake: pump on cell for cell_vacTimeForFlush sec, then close valve P14 (switcher vac)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "", "fake: close valve P15 (cell)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: pretend cell flush: fill #" + num2str(i+1), "")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "", "fake: add flush gas via valve P13 (flush gas)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, cell_fillTimeForFlush, "SendECL", "", "fake: stop adding flush gas via valve P13 (flush gas) after cell_fillTimeForFlush sec")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "", "fake: open valve P15 (cell)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, transferTimeFromIntVolToCell, "SendECL", "", "fake: close valve P15 (cell)")
		endfor
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
	endif
	
	// THIS BLOCK FILLS THE INTERMEDIATE VOLUME WITH REF
	thisScheduleName = "FillIntVolWithRef"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: evacuating intermediate volume", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno14", "open valve P14 (switcher vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno12", "open valve P12 (intermediate volume)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, inVol_vacTimeForFill, "SendECL", "dnc12", "pump on intermediate volume for inVol_vacTimeForFill sec, then close valve P12 (intermediate volume)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc14", "close valve P14 (switcher vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: filling intermediate volume with ref", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "azb1,2," + IntVolTargetPressureString_ref, "fill via valve E2 (ref orifice) until gauge 2 (intermediate volume) reaches IntVolTargetPressureString_ref torr")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
	
	// THIS BLOCK TRANSFERS REF FROM THE INTERMEDIATE VOLUME TO THE CELL
	thisScheduleName = "TransferRefToCell"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 1, measurementDuration, "ReportStatus", "TILDAS: evacuating cell", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bz" + ECL_transitionIndex, "defines ecl index = transition")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "ca1", "executes ecl index")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bdFits1", "suspend fitting")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc12", "shut intermediate volume")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno14", "open vac valve")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno15", "open cell valve")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, cell_vacTimeForFill, "SendECL", "dnc14", "pump on cell for cell_vacTimeForFill sec, then shut vac valve")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: transferring ref to cell", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: transferring ref to cell", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno12", "open intermediate volume")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, transferTimeFromIntVolToCell, "SendECL", "dnc15", "wait 4 seconds to expand gas into cell, then shut cell")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc12", "close intermediate volume")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bz" + ECL_refIndex, "defines ecl index = ref")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "ca1", "executes ecl index")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bdFits0", "restarts fitting")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: measuring ref", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "StartTimer", "1", "start timer for ref measurement")
	
	// THIS BLOCK FILLS THE INTERMEDIATE VOLUME WITH SAMPLE
	thisScheduleName = "FillIntVolWithSample"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: evacuating intermediate volume", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno14", "open valve P14 (switcher vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno12", "open valve P12 (intermediate volume)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, inVol_vacTimeForFill, "SendECL", "dnc12", "pump on intermediate volume for inVol_vacTimeForFill sec, then close valve P12 (intermediate volume)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc14", "close valve P14 (switcher vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: filling intermediate volume from full flask", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: filling intermediate volume from full flask", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "azb1,1," + IntVolTargetPressureString_sample, "fill via valve E2 (ref orifice) until gauge 2 (intermediate volume) reaches IntVolTargetPressureString_sample torr")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: idle", "")
	
	// THIS BLOCK TRANSFERS SAMPLE FROM THE INTERMEDIATE VOLUME TO THE CELL
	thisScheduleName = "TransferSampleToCell"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 1, measurementDuration, "ReportStatus", "TILDAS: evacuating cell", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bz" + ECL_transitionIndex, "defines ecl index = transition")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "ca1", "executes ecl index")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bdFits1", "suspend fitting")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc12", "shut intermediate volume")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno14", "open vac valve")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno15", "open cell valve")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, cell_vacTimeForFill, "SendECL", "dnc14", "pump on cell for cell_vacTimeForFill sec, then shut vac valve")
	if(pretend_Ref_is_Sample == 1) // for performance testing
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: transferring pretend sample to cell", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: transferring pretend sample to cell", "")
	else // normal operation
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: transferring sample to cell", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: transferring sample to cell", "")
	endif
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno12", "open intermediate volume")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, transferTimeFromIntVolToCell, "SendECL", "dnc15", "wait 4 seconds to expand gas into cell, then shut cell")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc12", "close intermediate volume")
	
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bz" + ECL_sampleIndex, "defines ecl index = sample")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "ca1", "executes ecl index")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bdFits0", "restarts fitting")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: measuring sample", "")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "StartTimer", "1", "start timer for sample measurement")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "FetchData", "", "fetch latest data")
	
	// THIS BLOCK STARTS MEASUREMENT OF SAMPLE N
	for(i=0;i<numSampleGases;i+=1)
		thisScheduleName = "StartMeasuringSample" + num2str(i+1)
		thisECLindexName = "ECL Index for Sample " + num2str(i+1)
		thisECLindex = IRIS_UTILITY_GetParamValueFromName(thisECLindexName)
		IRIS_UTILITY_ClearSchedule(thisScheduleName)
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bz" + thisECLindex, "set ECL index for sample " + num2str(i+1))
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "ca1", "executes ecl index")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bdFits0", "restarts fitting")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: measuring sample " + num2str(i+1), "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "StartTimer", "1", "start timer for sample measurement")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 1, "ReportStatus", "TILDAS: fetching and analyzing data", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "FetchData", "", "fetch latest data")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: measuring sample " + num2str(i+1), "")
	endfor
	
	// THIS BLOCK PRETENDS TO TRANSFER GAS FROM THE INTERMEDIATE VOLUME TO THE CELL // for performance testing
	thisScheduleName = "PretendToTransferGasToCell"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 1, measurementDuration, "ReportStatus", "TILDAS: pretending to evacuating cell", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bz" + ECL_transitionIndex, "defines ecl index = transition")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "ca1", "executes ecl index")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bdFits1", "suspend fitting")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "", "fake: shut intermediate volume")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "", "fake: open vac valve")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "", "fake: open cell valve")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, cell_vacTimeForFill, "SendECL", "", "fake: pump on cell for cell_vacTimeForFill sec, then shut vac valve")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: pretending to transfer gas to cell", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: pretending to transfer gas to cell", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "", "fake: open intermediate volume")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, transferTimeFromIntVolToCell, "SendECL", "", "fake: wait 4 seconds to expand gas into cell, then shut cell")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "", "fake: close intermediate volume")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: idle", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
	
	// THIS BLOCK WAITS FOR THE FINAL REF MEASUREMENT TO COMPLETE
	thisScheduleName = "WaitForFinalRefToFinish"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 1, measurementDuration, "SendECL", "bz" + ECL_transitionIndex, "defines ecl index = transition")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "ca1", "executes ecl index")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: idle", "")
	
	// THIS BLOCK DOES THE SWITCHER CYCLES FOR SAMPLE N
	for(i=0;i<numSampleGases;i+=1)
		thisScheduleName = "DoSwitcherCyclesForSample" + num2str(i+1)
		IRIS_UTILITY_ClearSchedule(thisScheduleName)
		if(pretend_to_switch == 1) // for performance testing
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "StartTimer", "1", "start dummy timer for ref measurement")
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FlushIntVol")
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FillIntVolWithRef")
			for(j=0;j<numAliquots;j+=1)
				if(j==0)
					IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FlushCell")
					IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "TransferRefToCell")
				else
					IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "PretendToFlushCell")
					IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "PretendToTransferGasToCell")
					IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bz" + ECL_refIndex, "defines ecl index = ref")
					IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "ca1", "executes ecl index")
					IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bdFits0", "restarts fitting")
					IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: measuring ref", "")
					IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
					IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "StartTimer", "1", "start timer for ref measurement")
				endif
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "PretendToFlushCell")
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "PretendToTransferGasToCell")
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "StartMeasuringSample" + num2str(i+1))
			endfor
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "PretendToFlushCell")
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "PretendToTransferGasToCell")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bz" + ECL_refIndex, "defines ecl index = ref")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "ca1", "executes ecl index")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bdFits0", "restarts fitting")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: measuring ref", "")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "StartTimer", "1", "start timer for ref measurement")
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "WaitForFinalRefToFinish")
		else // normal operation
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "StartTimer", "1", "start dummy timer for ref measurement")
			for(j=0;j<numAliquots;j+=1)
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FlushIntVol")
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FillIntVolWithRef")
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FlushCell")
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "TransferRefToCell")
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FlushIntVol")
				if(pretend_Ref_is_Sample == 1) // for performance testing
					IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FillIntVolWithRef")
				else // normal operation
					IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FillIntVolWithSample")
				endif
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FlushCell")
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "TransferSampleToCell")
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "StartMeasuringSample" + num2str(i+1))
			endfor
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FlushIntVol")
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FillIntVolWithRef")
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FlushCell")
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "TransferRefToCell")
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "WaitForFinalRefToFinish")
		endif
	endfor
	
	// === BUILD THE RESET SCHEDULE ===
	// 1. A schedule called "Reset", which clears the ECL queue, closes the valves, and starts a new STR/STC file (this will be directly invoked when the "STOP" button is clicked and is also a convenient building block for the Prologue and Epilogue);
	
	// Reset sampling system
	thisScheduleName = "Reset"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: clearing queue", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "cq", "immediately clear the ECL queue (this command jumps to the front of the queue)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 3, "SendECL", "bz" + ECL_transitionIndex, "set ECL index to transition")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "bdfits0", "activate spectral fits")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: idle", "")
	IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "DeactivateAllValves")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: idle", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "amwd0", "deactivate write disk")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "amass0", "deactivate auto spectral save")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: fetching and analyzing data", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "FetchData", "", "fetch latest data")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "ax" + sBaselinePolyOrder, "set baseline polynomial order to sBaselinePolyOrder")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "amwd1", "activate write disk")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "amass1", "activate auto spectral save")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: idle", "")
	
	// === BUILD THE PROLOGUE SCHEDULE ===
	// 2. A schedule called "Prologue", which consists of the things that happen only at the beginning of the run;
	
	variable upperFlask = 1
	
	thisScheduleName = "Prologue"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "WaitForUser", "MIXER: attach sample " + num2str(1) + " (" + "S349283dkrfd" + ")", "")
	IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "Reset")	
//	// TESTING!!!
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "TILDAS: testing1a", "")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 1, "ReportStatus", "TILDAS: testing1b", "")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: testing2", "")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "testing0", "")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "WaitForUser", "MIXER: Inject sample and then click -->", "")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "MIXER: testing3", "")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 1, "ReportStatus", "TILDAS: testing1c", "")
//	// END TESTING!!!
	IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "InitializeRegisters")
	IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "EvacuateSystem")
	IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "DeactivateAllValves")
	if((pretend_Ref_is_Sample == 0) && (pretend_to_switch == 0)) // normal operation
		if(manualSampleInjectionByVial == 1)
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "ManualVialInjectionOfSample" + num2str(1))
		elseif(manualSampleInjectionBySeptum == 1)
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "ManualSeptumInjectionOfSample" + num2str(1))
		endif
		if(flasks_numFlushes > 0)
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FlushFlask")
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "EvacuateFlask")
		endif
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "RecordMixerZeroPressures")
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "AddCO2toUpperFlask")
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "AddDilutionGas")
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "CloseAllMixerManifoldValves")
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "ForwardFlushBeforeMixing")
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "WaitForFirstMix")
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "ForwardFlushAfterMixing")
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "BackwardFlushAfterMixing")
	endif
	IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "ToggleRegisters")
	upperFlask = 1 - upperFlask
//	if(pretend_to_switch == 1)
//		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "OpenRefGasSupplyPort")
//		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FlushIntVol")
//		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FillIntVolWithRef")
//		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FlushCell")
//		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "TransferRefToCell")
//	endif
	
	// === BUILD THE CYCLE SCHEDULE ===
	// 3. A schedule called "Cycle", which consists of the things that happen repetitively;
	
	thisScheduleName = "Cycle"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	for(i=1;i<numSampleGases;i+=1)
		if((pretend_Ref_is_Sample == 0) && (pretend_to_switch == 0)) // normal operation
			if(manualSampleInjectionByVial == 1)
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "ManualVialInjectionOfSample" + num2str(i+1))
			elseif(manualSampleInjectionBySeptum == 1)
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "ManualSeptumInjectionOfSample" + num2str(i+1))
			endif
			if(flasks_numFlushes > 0)
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FlushFlask")
			endif
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "EvacuateFlask")
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "RecordMixerZeroPressures")
			if(upperFlask == 1)
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "AddCO2toUpperFlask")
			else
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "AddCO2toLowerFlask")
			endif
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "AddDilutionGas")
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "CloseAllMixerManifoldValves")
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "ForwardFlushBeforeMixing")
		endif
		if(doABGwithZeroAir == 1)
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "SubtractZeroAirBackground")
		elseif(doABGwithVacuum == 1)
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "SubtractVacground")
		endif
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "OpenRefGasSupplyPort")
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "DoSwitcherCyclesForSample" + num2str(i))
		if((pretend_Ref_is_Sample == 0) && (pretend_to_switch == 0)) // normal operation
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "ForwardFlushAfterMixing")
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "BackwardFlushAfterMixing")
		endif
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "ToggleRegisters")
		upperFlask = 1 - upperFlask
	endfor
	
	// === BUILD THE EPILOGUE SCHEDULE ===
	// 4. A schedule called "Epilogue", which consists of the things that happen only at the end of the run, after the last cycle.
	
	thisScheduleName = "Epilogue"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	if(doABGwithZeroAir == 1)
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "SubtractZeroAirBackground")
	elseif(doABGwithVacuum == 1)
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "SubtractVacground")
	endif
	IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "OpenRefGasSupplyPort")
	IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "DoSwitcherCyclesForSample" + num2str(numSampleGases))
	IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "Reset")
	
	DoUpdate
	
End

Function IRIS_SCHEME_BuildSchedule_D17O_d13C_CO2_LBL()
	
	// NOTE: "UNIVERSAL" sections must be included exactly as they are, exactly where they are.
	
	// === UNIVERSAL: DECLARATIONS (do not modify) ===
	
	NVAR minNumSamples = root:minNumSamples
	NVAR maxNumSamples = root:maxNumSamples
	NVAR minNumRefs = root:minNumRefs
	NVAR maxNumRefs = root:maxNumRefs
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	NVAR numGases = root:numGases
	
	NVAR numSampleGases_prev = root:numSampleGases_prev
	NVAR numRefGases_prev = root:numRefGases_prev
	
	wave/T wStatusCategoryNames = root:wStatusCategoryNames
	
	SetDataFolder root:
	
	// === DEFINE MAXIMUM AND MINIMUM ALLOWED NUMBERS OF SAMPLE AND REFERENCE GASES BASED ON HARDWARE ===
	
	minNumSamples = 1
	maxNumSamples = 100
	minNumRefs = 1
	maxNumRefs = 1
	
	numSampleGases = max(numSampleGases, minNumSamples)
	numSampleGases = min(numSampleGases, maxNumSamples)
	numRefGases = max(numRefGases, minNumRefs)
	numRefGases = min(numRefGases, maxNumRefs)
	variable numSamplesIncrement = (maxNumSamples == minNumSamples) ? 0 : 1
	variable numRefsIncrement = (maxNumRefs == minNumRefs) ? 0 : 1
	SetVariable/Z IRIS_NumSampleGasInput_tabGas, win = IRISpanel, limits = {minNumSamples,maxNumSamples,numSamplesIncrement}
	SetVariable/Z IRIS_NumRefGasInput_tabGas, win = IRISpanel, limits = {minNumRefs,maxNumRefs,numRefsIncrement}
	if( (numSampleGases != numSampleGases_prev) || (numRefGases != numRefGases_prev) )
		IRIS_UTILITY_UpdateNumGasesInTables()
	endif
	
	// === DEFINE UP TO 3 SEPARATE STATUS REPORT CATEGORIES ===
	
	// Instructions:
	// (i) Keep the category names short enough to fit in the GUI nicely.
	// (ii) Give unused categories the name " " (i.e. a space).
	// (iii) To have your schedule report a status to one of these specific GUI status fields, give the ReportStatus or WaitForUser event a string argument that begins with the category name followed by a colon, e.g. "TILDAS: Measuring ref".
	wStatusCategoryNames[0] = "TILDAS"
	wStatusCategoryNames[1] = "SWITCHER"
	wStatusCategoryNames[2] = "MIXER"
//	wStatusCategoryNames[2] = " " // GUI TESTING!!!
	
	// === GET VARIABLES FROM CONFIG PARAMS ===
	
	// Hardware setup
//	string PsensorForCell = IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Number for Cell")
//	string PsensorForIntVol = IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Number for Int Vol")
//	string PsensorForManifoldLowP = IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Number for Manifold Low P")
//	string PsensorForManifoldHighP = IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Number for Manifold High P")
	variable system_to_intVol_volume_ratio = str2num(IRIS_UTILITY_GetParamValueFromName("(Cell+IntVol)/IntVol Volume Ratio"))
	
	// Pressure sensor limits
	variable pressureSensorLimitForIntVol = str2num(IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Limit for Int Vol")) // torr, used to prevent the user from selecting target pressures that can never be measured, which would lead to runaway aza (up to its internal time limit)
	variable pressureSensorLimitForCell = str2num(IRIS_UTILITY_GetParamValueFromName("Pressure Sensor Limit for Cell")) // torr, used to prevent the user from selecting target pressures that can never be measured, which would lead to runaway aza (up to its internal time limit)
	
	// Schedule options
	variable measurementDuration = str2num(IRIS_UTILITY_GetParamValueFromName("Measurement Duration")) // seconds
	variable numAliquots = str2num(IRIS_UTILITY_GetParamValueFromName("Number of Aliquots per Sample"))
	
	variable manualSampleInjectionByVial = (stringMatch( IRIS_UTILITY_GetParamValueFromName("Manual Sample Injection: (v)ial / (s)eptum / (n)one"), "v*" ) == 1) ? 1 : 0 // 0 = no, 1 = yes
	variable manualSampleInjectionBySeptum = (stringMatch( IRIS_UTILITY_GetParamValueFromName("Manual Sample Injection: (v)ial / (s)eptum / (n)one"), "s*" ) == 1) ? 1 : 0 // 0 = no, 1 = yes
	if(manualSampleInjectionByVial == 1)
		manualSampleInjectionBySeptum = 0
	endif
	variable timeToEvacuateCO2port = str2num(IRIS_UTILITY_GetParamValueFromName("Time to Evacuate CO2 Port"))
	
	variable manifold_vacTimeForFill = str2num(IRIS_UTILITY_GetParamValueFromName("Sample Manifold: Vacuum Time before Fill"))
	
	variable flasks_numFlushes = str2num(IRIS_UTILITY_GetParamValueFromName("Flasks: Number of Flushes before Fill"))
	variable flasks_flushPressure = str2num(IRIS_UTILITY_GetParamValueFromName("Flasks: Target Pressure for Flush"))
	variable flasks_vacTimeForFlush = str2num(IRIS_UTILITY_GetParamValueFromName("Flasks: Vacuum Time before Flush"))
	variable flasks_vacTimeForFill = str2num(IRIS_UTILITY_GetParamValueFromName("Flasks: Vacuum Time before Fill"))
	variable timeToLeaveFlaskOpenWithCO2 = str2num(IRIS_UTILITY_GetParamValueFromName("Flasks: Time to Leave Open After Adding CO2"))
	variable flasks_numDilutionBursts = str2num(IRIS_UTILITY_GetParamValueFromName("Flasks: Number of Dilution Bursts to Help Mixing"))
	variable flasks_dilutionBurstBuildupTime = str2num(IRIS_UTILITY_GetParamValueFromName("Flasks: Dilution Burst Pressure Buildup Time"))
	variable flasks_doForwardFlushBeforeMixing = (stringMatch( IRIS_UTILITY_GetParamValueFromName("Flasks: Do a Forward Flush before Mixing"), "y*" ) == 1) ? 1 : 0 // 0 = no, 1 = yes
	variable flasks_doBackwardFlushAfterMixing = (stringMatch( IRIS_UTILITY_GetParamValueFromName("Flasks: Do a Backward Flush (after Mixing)"), "y*" ) == 1) ? 1 : 0 // 0 = no, 1 = yes
	variable flasks_timeToFlushOwnOutputTube = str2num(IRIS_UTILITY_GetParamValueFromName("Flasks: Time to Flush Own Output Tube"))
	variable flasks_timeToFlushJointOutputTube = str2num(IRIS_UTILITY_GetParamValueFromName("Flasks: Time to Flush Joint Output Tube"))
	variable flasks_timeToWaitForFirstMix = str2num(IRIS_UTILITY_GetParamValueFromName("Flasks: Time for Wait for First Mix"))
		
	variable inVol_numFlushes = str2num(IRIS_UTILITY_GetParamValueFromName("Int Vol: Number of Flushes before Fill"))
	variable inVol_vacTimeForFlush = str2num(IRIS_UTILITY_GetParamValueFromName("Int Vol: Vacuum Time before Flush"))
	variable inVol_fillTimeForFlush = str2num(IRIS_UTILITY_GetParamValueFromName("Int Vol: Time to Keep Flush Gas Valve Open"))
	variable inVol_vacTimeForFill = str2num(IRIS_UTILITY_GetParamValueFromName("Int Vol: Vacuum Time before Fill"))
	
	variable vacTimeForRefCross = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time for Ref Cross"))
	
	variable cell_numFlushes = str2num(IRIS_UTILITY_GetParamValueFromName("Cell: Number of Flushes before Fill"))
	variable cell_vacTimeForFlush = str2num(IRIS_UTILITY_GetParamValueFromName("Cell: Vacuum Time before Flush"))
	variable cell_fillTimeForFlush = str2num(IRIS_UTILITY_GetParamValueFromName("Cell: Time to Keep Flush Gas Valve Open"))
	variable cell_vacTimeForFill = str2num(IRIS_UTILITY_GetParamValueFromName("Cell: Vacuum Time before Fill"))
	
	variable transferTimeFromIntVolToCell = str2num(IRIS_UTILITY_GetParamValueFromName("Time to Wait for Fill of Cell from Int Vol"))
	
	variable doABGwithZeroAir = (stringMatch( IRIS_UTILITY_GetParamValueFromName("Background Subtraction: (v)acuum / (z)ero gas / (n)one"), "z*" ) == 1) ? 1 : 0 // 0 = no, 1 = yes
	variable doABGwithVacuum = (stringMatch( IRIS_UTILITY_GetParamValueFromName("Background Subtraction: (v)acuum / (z)ero gas / (n)one"), "v*" ) == 1) ? 1 : 0 // 0 = no, 1 = yes
	if(doABGwithVacuum == 1)
		doABGwithZeroAir = 0
	endif
	
	variable backgroundDuration = str2num(IRIS_UTILITY_GetParamValueFromName("Background Measurement Duration")) // seconds
	variable evacTimeForABG = str2num(IRIS_UTILITY_GetParamValueFromName("Vacuum Time before Background")) // seconds
	variable pressureOffset_sample = str2num(IRIS_UTILITY_GetParamValueFromName("Pressure Offset for Sample Orifice")) // Torr
	variable pressureOffset_ref = str2num(IRIS_UTILITY_GetParamValueFromName("Pressure Offset for Ref Orifice")) // Torr
	
	variable pretend_Ref_is_Sample = (stringMatch( IRIS_UTILITY_GetParamValueFromName("Use Ref as Pretend Sample"), "y*" ) == 1) ? 1 : 0 // 0 = no, 1 = yes
	variable pretend_to_switch = (stringMatch( IRIS_UTILITY_GetParamValueFromName("Put Ref in Cell Once and Pretend to Switch"), "y*" ) == 1) ? 1 : 0 // 0 = no, 1 = yes
	
//	if(baselinePolyOrder >= 0)
//		baselinePolyOrder = round(baselinePolyOrder)
//	else
//		baselinePolyOrder = 2
//	endif
//	string sBaselinePolyOrder = num2istr(baselinePolyOrder)
	
//	string timeToLetSampleFlowIntoManifold_Part1 = IRIS_UTILITY_GetParamValueFromName("Time to let sample flow into manifold: Part 1")
//	string timeToLetSampleFlowIntoManifold_Part2 = IRIS_UTILITY_GetParamValueFromName("Time to let sample flow into manifold: Part 2")
	variable valveActionTimeSpacer = str2num(IRIS_UTILITY_GetParamValueFromName("Valve Action Time Spacer")) // number of seconds to wait before sending valve open or close command, to avoid sending effectively overlapping commands
	
//	// Pressures
	variable pChanged = 0
	variable target_cell_pressure = str2num(IRIS_UTILITY_GetParamValueFromName("Target Cell Pressure")) // Torr
	if(target_cell_pressure > 0.9*pressureSensorLimitForCell) // includes a safety margin of 10% of the sensor range
		target_cell_pressure = 0.9*pressureSensorLimitForCell
		pChanged = 1
		IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", "*** WARNING: Target pressure reduced to cell sensor limit! ***")
	endif
	variable IntVolTargetPressure_sample = (target_cell_pressure + pressureOffset_sample)*system_to_intVol_volume_ratio // torr
	variable IntVolTargetPressure_ref = (target_cell_pressure + pressureOffset_ref)*system_to_intVol_volume_ratio // torr
	if((IntVolTargetPressure_sample > 0.9*pressureSensorLimitForIntVol) || (IntVolTargetPressure_ref > 0.9*pressureSensorLimitForIntVol)) // includes a safety margin of 10% of the sensor range
		IntVolTargetPressure_sample = 0.9*pressureSensorLimitForIntVol
		IntVolTargetPressure_ref = 0.9*pressureSensorLimitForIntVol
		target_cell_pressure = IntVolTargetPressure_sample/system_to_intVol_volume_ratio
		pChanged = 1
		IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", "*** WARNING: Target pressure reduced to keep int vol pressure below sensor limit! ***")
	endif
	if(pChanged == 1)
		IRIS_UTILITY_SetParamValueByName( "Target Cell Pressure", num2str(target_cell_pressure) )
		IRIS_UTILITY_PropagateParamsToTables()
	endif
	string IntVolTargetPressureString_sample = num2str(IntVolTargetPressure_sample)
	string IntVolTargetPressureString_ref = num2str(IntVolTargetPressure_ref)
	
	variable manifold_to_manifoldPlusFlask_volume_ratio_upperFlask = str2num(IRIS_UTILITY_GetParamValueFromName("(Manifold+Bulb)/Manifold Volume Ratio (upper flask)")) // dimensionless
	variable manifold_to_manifoldPlusFlask_volume_ratio_lowerFlask = str2num(IRIS_UTILITY_GetParamValueFromName("(Manifold+Bulb)/Manifold Volume Ratio (lower flask)")) // dimensionless
	variable target_mole_fraction = str2num(IRIS_UTILITY_GetParamValueFromName("Target Mole Fraction")) // ppm
	target_mole_fraction = target_mole_fraction*1e-6 // conversion from ppm to dimensionless
	
	variable ratio_of_Ptot_to_PCO2_upperFlask = 1/(target_mole_fraction*manifold_to_manifoldPlusFlask_volume_ratio_upperFlask)
	variable ratio_of_Ptot_to_PCO2_lowerFlask = 1/(target_mole_fraction*manifold_to_manifoldPlusFlask_volume_ratio_lowerFlask)
	string ratio_of_Ptot_to_PCO2_string_upperFlask = num2str(ratio_of_Ptot_to_PCO2_upperFlask)
	string ratio_of_Ptot_to_PCO2_string_lowerFlask = num2str(ratio_of_Ptot_to_PCO2_lowerFlask)
	
	// ECL indices
	string ECL_refIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Reference 1")
	string ECL_transitionIndex = IRIS_UTILITY_GetParamValueFromName("ECL Index for Transition")
	string thisECLindexName
	string thisECLindex
	
	string thisSampleIDparam, thisSampleID
	
	variable i, j
	
	// === MAKE SCHEDULE MODULES TO USE AS BUILDING BLOCKS ===
	
	// USAGE: IRIS_UTILITY_AppendEventToSchedule(sScheduleName, whichTimer, triggerTime, sAction, sArgument, sComment)
	// where sAction is a string that will be appended to "IRIS_EVENT_" to create a reference to a function that takes at most one argument (sArgument), which must be a string
	//	e.g. IRIS_EVENT_SendECL, IRIS_EVENT_ReportStatus, IRIS_EVENT_FetchData, IRIS_EVENT_StartTimer
	
	string thisScheduleName
	
	// SPECIAL NOTES
	
	// Register 10 (R10) must contain either a 1 (ECL commands access upper flask) or 0 (ECL commands access lower flask)
	// Register 1 (R1) must contain the literal number 1
	// Register 4 (R4) must contain the literal number 4
	// Register 34 (R34) stores the dynamic valve number for flask input, either 3 or 4 (counting from 1), computed from R10
	
	// Using new ECL command: dnx,y where x is the valve state (0 or 1) or register containing the valve state (if negative) and y is the valve number (counting from 1) or register containing valve number (if negative)
	// If R10 = 1, then P19 = 1 and fill valve = E3
	// If R10 = 0, then P19 = 0 and fill valve = E4
	// So the P19 state is R10 and the filling valve number is R4 - R10
	// So to set P19: dn-10,19
	// and to open filling valve: cysub,34,4,10 and dn1,-34
	// and to close filling valve: cysub,34,4,10 and dn0,-34
	
	// Filling the intermediate volume takes about 30 sec (this happens while the cell is being measured, except the first time).
	// Evacuating the cell and transferring gas from the intermediate volume takes 30 sec.
	// Measuring the gas in the cell takes 60 sec.
	// So each cut-and-paste cycle takes 180 sec.
	// So the total time is about 30 + n*180 + 90 sec = 120 + n*180 sec, where n is the number of sample-ref cell fill pairs apart from the final ref fill.
	// So to allow 30 min = 1800 sec for the flask to mix, we want 1800 = 120 + n*180 => n = 1680/180 = 9.33.
	// So we will do 10 cycles and thereby allow each flask to mix for 32 minutes.
	
	// THIS BLOCK INITIALIZES REGISTER VALUES FOR DYNAMIC VALVE CONTROL
	thisScheduleName = "InitializeRegisters"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cz0,1,1", "store '1' into Register 1 (R1); a constant")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cz0,4,4", "store '4' into Register 4 (R4); a constant")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cz0,10,1", "store '1' into Register 10 (R10), which must contain either a 1 (ECL commands access upper flask) or 0 (ECL commands access lower flask)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cysub,34,4,10", "update Register 34 (R34), which stores the valve number for flask input, either 3 or 4 (counting from 1), computed from R10")
	
	// THIS BLOCK TOGGLES ECL CONTROL TO THE OTHER MIXER FLASK
	thisScheduleName = "ToggleRegisters"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cysub,10,1,10	", "the register math to toggle R10 back and forth between 0 and 1")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cysub,34,4,10	", "the register math to update R34 with the target flask input valve number according to R10")
	
	// THIS BLOCK DEACTIVATES ALL VALVES
	thisScheduleName = "DeactivateAllValves"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: deactivating all valves", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: deactivating all valves", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc1", "close E1")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc2", "close E2")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc3", "close E3")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc4", "close E4")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc5", "close E5")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc9", "close P9")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc10", "close P10")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc11", "close P11")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc12", "close P12")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc13", "close P13")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc14", "close P14")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc15", "close P15")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc17", "close P17")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc18", "close P18")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc19", "set 3-way valve to lower flask")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: idle", "")
	
	// THIS BLOCK EVACUATES THE WHOLE SAMPLING SYSTEM FROM BOTH ENDS (BUT NOT THE CELL)
	thisScheduleName = "EvacuateSystem"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: evacuating system", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: evacuating system", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc15", "close valve P15 (cell), redundancy just in case")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno17", "open valve P17 (mixer vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 3, "SendECL", "dno14", "open valve P14 (switcher vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 3, "SendECL", "dno12", "open valve P12 (intermediate volume)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 3, "SendECL", "dno9", "open valve P9 (working ref cross vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 3, "SendECL", "dno3", "open valve E3 (upper flask input)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 3, "SendECL", "dno4", "open valve E4 (lower flask input)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, flasks_vacTimeForFill, "SendECL", "dno19", "set 3-way valve to upper flask in case any little pocket of gas is exposed when switching")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, flasks_vacTimeForFill, "SendECL", "", "wait 30 sec for second half of thorough evacuation")
	
	// THIS BLOCK OPENS THE REF GAS SUPPLY PORT
	thisScheduleName = "OpenRefGasSupplyPort"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno11", "open valve P11 (ref gas port)")
	
	// THIS BLOCK EVACUATES THE TARGET FLASK (AND ITS INPUT AND OUTPUT TUBES)
	thisScheduleName = "EvacuateFlask"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "MIXER: evacuating flask", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno17", "open valve P17 (mixer vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, manifold_vacTimeForFill, "SendECL", "dn1,-34", "open valve E3 or E4 (flask input)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, flasks_vacTimeForFill, "SendECL", "dn0,-34", "close valve E3 or E4 (flask input)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc17", "close valve P17 (mixer vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: idle", "")
	
	// THIS BLOCK FILLS THE TARGET FLASK WITH FLUSH GAS (POSSIBLY MULTIPLE TIMES)
	thisScheduleName = "FlushFlask"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	if(flasks_numFlushes > 0)
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "MIXER: flushing flask with N2", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dn1,-34", "open valve E3 or E4 (flask input)")
		for(i=0;i<flasks_numFlushes;i+=1)
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "MIXER: flushing flask with N2: evacuating", "")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno17", "open valve P17 (mixer vac)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, flasks_vacTimeForFlush, "SendECL", "dnc17", "close valve P17 (mixer vac)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "MIXER: flushing flask with N2: fill #" + num2str(i+1), "")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "azb3,5," + num2str(flasks_flushPressure), "control E5 to fill to flasks_flushPressure with N2")
		endfor
//		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "MIXER: flushing flask with N2: evacuating", "")
//		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno17", "open valve P17 (mixer vac)")
//		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, flasks_vacTimeForFill, "SendECL", "dnc17", "close valve P17 (mixer vac)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dn0,-34", "close valve E3 or E4 (flask input)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: idle", "")
	endif
		
	// THIS BLOCK RECORDS THE ZERO OFFSET FOR BOTH MIXER P SENSORS
	thisScheduleName = "RecordMixerZeroPressures"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "cz1,11,12", "capture into R11, the P(zero) of AD12 (the low-P sensor in mixer)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cz1,12,13", "capture into R12, the P(zero) oF AD13 (the high-P sensor in mixer)")
	
	// THIS BLOCK ADDS CO2 TO THE UPPER FLASK, FROM A SMALL VOLUME (e.g. A VIAL) UPSTREAM OF P18
	thisScheduleName = "AddCO2toUpperFlask"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "MIXER: adding CO2 to flask", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno18", "let CO2 sample flow into manifold for 1 sec (exact time not important)")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 1, "SendECL", "dnc18", "and then close valve P18") // testing because pure CO2 amount is 10X too high, but the "sample tube" volume is 2 mL, so expanding once into the 20 mL manifold and evacuating that gets it down to the correct amount
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno17", "open valve P17 (mixer vac) for 4 sec (exact time not important)") // testing because pure CO2 amount is 10X too high, but the "sample tube" volume is 2 mL, so expanding once into the 20 mL manifold and evacuating that gets it down to the correct amount
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 6, "SendECL", "dnc17", "close valve P17 (mixer vac)") // testing because pure CO2 amount is 10X too high, but the "sample tube" volume is 2 mL, so expanding once into the 20 mL manifold and evacuating that gets it down to the correct amount
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno18", "let CO2 sample flow into manifold for 1 sec (exact time not important)") // testing because pure CO2 amount is 10X too high, but the "sample tube" volume is 2 mL, so expanding once into the 20 mL manifold and evacuating that gets it down to the correct amount
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 1, "SendECL", "dnc18", "and then close valve P18 and let it settle 4 sec for readings")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 4, "SendECL", "cz1,13,12", "capture into R13, the P(CO2) of AD12 (the low-P sensor in mixer)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cysub,14,13,11", "store P(CO2) - P(zero) in register 14 (R14) to account for offset in gauge")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cz0,15," + ratio_of_Ptot_to_PCO2_string_upperFlask, "*** store 'ratio_of_Ptot_to_PCO2_string_upperFlask into R15     %%% the 125 factor controls the final [CO2] in the lower flask (it is the inverse of the product of the volume ratio and the target mixing ratio)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cymul,16,14,15", "store R14 * R15 into R16")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cyadd,17,16,12", "store R16 (target pressure) + R12 (high-P sensor zero offset) into R17 to get target high-P sensor reading")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dn1,-34", "open valve E3 or E4 (flask input) to let CO2 expand into flask")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, timeToLeaveFlaskOpenWithCO2, "SendECL", "dn0,-34", "after molecular diffusion 10*1/e time, close valve E3 or E4 (flask input) to isolate flask from manifold")
	
	// THIS BLOCK ADDS CO2 TO THE LOWER FLASK, FROM A SMALL VOLUME (e.g. A VIAL) UPSTREAM OF P18
	thisScheduleName = "AddCO2toLowerFlask"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "MIXER: adding CO2 to flask", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno18", "let CO2 sample flow into manifold for 1 sec (exact time not important)")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 1, "SendECL", "dnc18", "and then close valve P18") // testing because pure CO2 amount is 10X too high, but the "sample tube" volume is 2 mL, so expanding once into the 20 mL manifold and evacuating that gets it down to the correct amount
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno17", "open valve P17 (mixer vac) for 4 sec (exact time not important)") // testing because pure CO2 amount is 10X too high, but the "sample tube" volume is 2 mL, so expanding once into the 20 mL manifold and evacuating that gets it down to the correct amount
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 6, "SendECL", "dnc17", "close valve P17 (mixer vac)") // testing because pure CO2 amount is 10X too high, but the "sample tube" volume is 2 mL, so expanding once into the 20 mL manifold and evacuating that gets it down to the correct amount
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno18", "let CO2 sample flow into manifold for 1 sec (exact time not important)") // testing because pure CO2 amount is 10X too high, but the "sample tube" volume is 2 mL, so expanding once into the 20 mL manifold and evacuating that gets it down to the correct amount
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 1, "SendECL", "dnc18", "and then close valve P18 and let it settle 4 sec for readings")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 4, "SendECL", "cz1,13,12", "capture into R13, the P(CO2) of AD12 (the low-P sensor in mixer)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cysub,14,13,11", "store P(CO2) - P(zero) in register 14 (R14) to account for offset in gauge")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cz0,15," + ratio_of_Ptot_to_PCO2_string_lowerFlask, "*** store ratio_of_Ptot_to_PCO2_string_lowerFlask into R15     %%% the 125 factor controls the final [CO2] in the lower flask (it is the inverse of the product of the volume ratio and the target mixing ratio)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cymul,16,14,15", "store R14 * R15 into R16")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "cyadd,17,16,12", "store R16 (target pressure) + R12 (high-P sensor zero offset) into R17 to get target high-P sensor reading")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dn1,-34", "open valve E3 or E4 (flask input) to let CO2 expand into flask")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, timeToLeaveFlaskOpenWithCO2, "SendECL", "dn0,-34", "after molecular diffusion 10*1/e time, close valve E3 or E4 (flask input) to isolate flask from manifold")
	
//	// THIS BLOCK ADDS DILUTION GAS TO THE TARGET FLASK, TO REACH THE TARGET CO2 MIXING RATIO
//	thisScheduleName = "AddDilutionGas"
//	IRIS_UTILITY_ClearSchedule(thisScheduleName)
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dmAdding_dilution_gas_to_the_unfilled_flask", "status message in popup window")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno17", "open valve P17 (mixer vac) to manifold to dispose of unrecoverable CO2")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, manifold_vacTimeForFill, "SendECL", "dnc17", "close valve P17 (mixer vac)")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno5", "open valve E5 (dilution gas) to load up a little pressure in the prep volume")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 1, "SendECL", "dno5", "close valve E5 (dilution gas)")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dn1,-34", "open valve E3 or E4 (flask input) to let dilution gas slam & mix into flask")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 2, "SendECL", "azb3,5,-17", "control E5 to fill to the R17 target P(tot) reading")
	
	// THIS BLOCK ADDS DILUTION GAS TO THE TARGET FLASK, TO REACH THE TARGET CO2 MIXING RATIO
	thisScheduleName = "AddDilutionGas"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "MIXER: adding dilution gas to flask", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno17", "open valve P17 (mixer vac) to manifold to dispose of unrecoverable CO2")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, manifold_vacTimeForFill, "SendECL", "dnc17", "close valve P17 (mixer vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno5", "open valve E5 (dilution gas) to load up pressure in the prep volume")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, flasks_dilutionBurstBuildupTime, "SendECL", "dn1,-34", "open valve E3 or E4 (flask input) to let dilution gas slam & mix into flask")
	if(flasks_numDilutionBursts >= 2)
		for(i=0;i<(flasks_numDilutionBursts-1);i+=1)
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 2, "SendECL", "dn0,-34", "close valve E3 or E4 (flask input) 2 seconds later to load up pressure in the prep volume")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, flasks_dilutionBurstBuildupTime, "SendECL", "dn1,-34", "open valve E3 or E4 (flask input) to let dilution gas slam & mix into flask")
		endfor
	endif
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 2, "SendECL", "azb3,5,-17", "control E5 to fill the rest of the way to the R17 target P(tot) reading")	
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: idle", "")
	
	// THIS BLOCK CLOSES ALL THE MIXER MANIFOLD VALVES
	thisScheduleName = "CloseAllMixerManifoldValves"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: closing all manifold valves", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc3", "close valve E3 (upper flask input)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc4", "close valve E4 (lower flask input)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc5", "close valve E5 (dilution gas supply)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc18", "close valve P18 (CO2 supply)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc17", "close valve P17 (mixer vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: idle", "")
	
	// THIS BLOCK WAITS FOR MIXING OF THE FIRST FLASK FILL
	thisScheduleName = "WaitForFirstMix"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "MIXER: waiting " + num2str(flasks_timeToWaitForFirstMix/60) + " min for first flask to mix", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, flasks_timeToWaitForFirstMix, "ReportStatus", "MIXER: mixing of first flask complete", "")
		
	// THIS BLOCK FORWARD-FLUSHES THE JOINT SAMPLE LINE WITH GAS FROM THE FLASK BEFORE MIXING
	thisScheduleName = "ForwardFlushBeforeMixing"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	if((flasks_doForwardFlushBeforeMixing > 0) && (flasks_timeToFlushOwnOutputTube > 0))
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "MIXER: forward flush: starting flow", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: forward flush: starting flow", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno14", "pre apply vacuum...")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno12", "...all the way through...")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, inVol_vacTimeForFill, "SendECL", "dno1", "...to measurement orifice")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 1, "SendECL", "dn-10,19", "wait 1 sec with flow from the mixed flask, then set 3-way valve to the unmixed flask")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: forward flush: from unmixed flask", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: forward flush: from unmixed flask", "")
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "ToggleRegisters")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, flasks_timeToFlushOwnOutputTube, "SendECL", "dn-10,19", "wait flasks_timeToFlushOwnOutputTube sec with flow from the umixed flask, then set 3-way valve back to the mixed flask")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: forward flush: from mixed flask", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: forward flush: from mixed flask", "")
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "ToggleRegisters")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, flasks_timeToFlushJointOutputTube, "SendECL", "dnc1", "downstream (i.e. forward) flush for flasks_timeToFlushJointOutputTube sec, then close valve E1 (sample orifice)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc12", "close valve P12 (intermediate volume)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc14", "close valve P14 (switcher vac)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: idle", "")
	endif
	
	// THIS BLOCK FORWARD-FLUSHES THE JOINT SAMPLE LINE WITH GAS FROM THE FLASK AFTER MIXING
	thisScheduleName = "ForwardFlushAfterMixing"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	if(flasks_timeToFlushJointOutputTube > 0)
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "MIXER: forward flush: starting flow", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: forward flush: starting flow", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno14", "pre apply vacuum...")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno12", "...all the way through...")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, inVol_vacTimeForFill, "SendECL", "dno1", "...to measurement orifice")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 1, "SendECL", "dn-10,19", "wait 1 sec with flow from old flask, then set 3-way valve to full flask")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: forward flush: from mixed flask", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: forward flush: from mixed flask", "")
		if(flasks_doForwardFlushBeforeMixing > 0)
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, flasks_timeToFlushJointOutputTube, "SendECL", "dnc1", "downstream (i.e. forward) flush for flasks_timeToFlushJointOutputTube sec, then close valve E1 (sample orifice)")
		else
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, flasks_timeToFlushOwnOutputTube + flasks_timeToFlushJointOutputTube, "SendECL", "dnc1", "downstream (i.e. forward) flush for flasks_timeToFlushOwnOutputTube + flasks_timeToFlushJointOutputTube sec, then close valve E1 (sample orifice)")
		endif
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc12", "close valve P12 (intermediate volume)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc14", "close valve P14 (switcher vac)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: idle", "")
	endif
	
	// THIS BLOCK BACK-FLUSHES THE INPUT TUBE OF THE FLASK (AFTER MIXING)
	thisScheduleName = "BackwardFlushAfterMixing"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	if(flasks_doBackwardFlushAfterMixing == 1)
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "MIXER: back-flush: from mixed flask", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno17", "open valve P17 (mixer vac) to evacuate mixer manifold")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, manifold_vacTimeForFill, "SendECL", "dnc17", "wait 5 sec, then close valve P17 (mixer vac)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dn1,-34", "open valve E3 or E4 (flask input) to let a finite portion of the flask gas flow back into the empty manifold")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 1, "SendECL", "dn0,-34", "close valve E3 or E4 (flask input) to isolate flask from manifold")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: idle", "")
	endif
	
	// THIS BLOCK HANDLES MANUAL SAMPLE INJECTION BY VIAL
	for(i=0;i<numSampleGases;i+=1)
		thisScheduleName = "ManualVialInjectionOfSample" + num2str(i+1)
		thisSampleIDparam = "Sample " + num2str(i+1) + ": " + "ID"
		thisSampleID = IRIS_UTILITY_GetParamValueFromName(thisSampleIDparam) // seconds
		IRIS_UTILITY_ClearSchedule(thisScheduleName)
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "WaitForUser", "MIXER: attach sample " + num2str(i+1) + " (" + thisSampleID + ")", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: evacuating CO2 port", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno17", "open valve P17 (mixer vac)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno18", "open valve P18 (to evacuate CO2 port)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, timeToEvacuateCO2port, "SendECL", "dnc18", "close valve P18")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc17", "close valve P17 (mixer vac)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "WaitForUser", "MIXER: open sample " + num2str(i+1) + " (" + thisSampleID + ")", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: idle", "")
	endfor
	
	// THIS BLOCK HANDLES MANUAL SAMPLE INJECTION BY SEPTUM
	for(i=0;i<numSampleGases;i+=1)
		thisScheduleName = "ManualSeptumInjectionOfSample" + num2str(i+1)
		thisSampleIDparam = "Sample " + num2str(i+1) + ": " + "ID"
		thisSampleID = IRIS_UTILITY_GetParamValueFromName(thisSampleIDparam) // seconds
		IRIS_UTILITY_ClearSchedule(thisScheduleName)
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: evacuating CO2 port", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno17", "open valve P17 (mixer vac)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno18", "open valve P18 (to evacuate CO2 port)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, timeToEvacuateCO2port, "SendECL", "dnc18", "close valve P18")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc17", "close valve P17 (mixer vac)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "WaitForUser", "MIXER: inject sample " + num2str(i+1) + " (" + thisSampleID + ")", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: idle", "")
	endfor
	
	// THIS BLOCK MEASURES AND SUBTRACTS A VACUUM SPECTRAL BACKGROUND
	thisScheduleName = "SubtractVacground"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: evacuating cell for spectral background", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno14", "open vac valve")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno15", "open cell valve")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, evacTimeForABG, "SendECL", "dnc15", "pump on cell for evacTimeForABG sec, then close cell valve")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc14", "close vac valve")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "ax1", "set baseline polynomial order to 1")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: measuring spectral background", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 1, "SendECL", "amabg1", "enable ABG")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "aq", "do a BG measurement")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, backgroundDuration, "", "", "wait for ABG to complete")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: idle", "")
	
	// THIS BLOCK MEASURES AND SUBTRACTS A ZERO AIR (OR N2) SPECTRAL BACKGROUND
	thisScheduleName = "SubtractZeroAirBackground"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: evacuating ref cross", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc10", "ensure valve P10 (ref cross zero air) is closed")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc11", "ensure valve P11 (ref port) is closed")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno9", "open valve P9 (ref cross vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, vacTimeForRefCross, "SendECL", "dnc9", "evacuate ref cross for vacTimeForRefCross seconds and then close valve P9 (ref cross vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: evacuating intermediate volume", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno14", "open valve P14 (switcher vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno12", "open valve P12 (intermediate volume)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, inVol_vacTimeForFill, "SendECL", "dnc12", "pump on intermediate volume for inVol_vacTimeForFill sec, then close valve P12 (intermediate volume)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "TILDAS: evacuating cell", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: evacuating cell", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno15", "open valve P15 (cell)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, evacTimeForABG, "SendECL", "dnc15", "pump on cell for evacTimeForABG sec, then close valve P15 (cell)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc14", "close valve P14 (switcher vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "TILDAS: idle", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: filling int vol with zero air (or N2)", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno10", "open valve P10 (ref cross zero air)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "azb1,2," + IntVolTargetPressureString_ref, "fill via valve E2 (ref orifice) until gauge 2 (intermediate volume) reaches IntVolTargetPressureString_ref torr")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: transferring zero air (or N2) to cell", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: transferring zero air (or N2) to cell", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno12", "open valve P12 (intermediate volume)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno15", "open valve P15 (cell)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, transferTimeFromIntVolToCell, "SendECL", "dnc15", "wait 4 seconds to expand gas into cell, then shut cell")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc12", "close valve P12 (intermediate volume)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: measuring spectral background", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 1, "SendECL", "amabg1", "enable ABG")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "aq", "do a BG measurement")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, backgroundDuration, "", "", "wait for ABG to complete")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: idle", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: evacuating ref cross", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc10", "ensure valve P10 (ref cross zero air) is closed")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc11", "ensure valve P11 (ref port) is closed")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno9", "open valve P9 (ref cross vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, vacTimeForRefCross, "SendECL", "dnc9", "evacuate ref cross for vacTimeForRefCross seconds and then close valve P9 (ref cross vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
	
	// THIS BLOCK FILLS THE INTERMEDIATE VOLUME WITH FLUSH GAS (POSSIBLY MULTIPLE TIMES)
	thisScheduleName = "FlushIntVol"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	if(inVol_numFlushes > 0)
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: flushing int vol: evacuating", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno12", "open valve P12 (intermediate volume)")
		for(i=0;i<inVol_numFlushes;i+=1)
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: flushing int vol: evacuating", "")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno14", "open valve P14 (switcher vac)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, inVol_vacTimeForFlush, "SendECL", "dnc14", "pump on intermediate volume for inVol_vacTimeForFlush sec, then close valve P14 (switcher vac)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: flushing int vol: fill #" + num2str(i+1), "")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno13", "add flush gas via valve P13 (flush gas)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, inVol_fillTimeForFlush, "SendECL", "dnc13", "stop adding flush gas via valve P13 (flush gas) after inVol_fillTimeForFlush sec")
		endfor
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc12", "close valve P12 (intermediate volume)")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
	endif
	
//	// THIS BLOCK FILLS THE CELL WITH FLUSH GAS (POSSIBLY MULTIPLE TIMES)
//	thisScheduleName = "FlushCell"
//	IRIS_UTILITY_ClearSchedule(thisScheduleName)
//	if(inVol_numFlushes > 0)
//		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: flushing cell: evacuating", "")
//		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bz" + ECL_transitionIndex, "defines ecl index = transition")
//		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "ca1", "executes ecl index")
//		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bdFits1", "suspend fitting")
//		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc12", "ensure P12 (intermediate volume) is closed")
//		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc13", "ensure P13 (flush gas) is closed")
//		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno15", "open valve P15 (cell)")
//			for(i=0;i<inVol_numFlushes;i+=1)
//			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: flushing cell: evacuating", "")
//			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno14", "open valve P14 (switcher vac)")
//			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, cell_vacTimeForFlush, "SendECL", "dnc14", "pump on cell for cell_vacTimeForFlush sec, then close valve P14 (switcher vac)")
//			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: flushing cell: fill #" + num2str(i+1), "")
//			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno13", "add flush gas via valve P13 (flush gas)")
//			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, cell_fillTimeForFlush, "SendECL", "dnc13", "stop adding flush gas via valve P13 (flush gas) after cell_fillTimeForFlush sec")
//		endfor
//		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc15", "close valve P15 (cell)")
//		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
//	endif
	
	// THIS BLOCK FILLS THE CELL WITH FLUSH GAS (POSSIBLY MULTIPLE TIMES)
	thisScheduleName = "FlushCell"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	if(inVol_numFlushes > 0)
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 1, measurementDuration, "ReportStatus", "SWITCHER: flushing cell: evacuating", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bz" + ECL_transitionIndex, "defines ecl index = transition")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "ca1", "executes ecl index")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bdFits1", "suspend fitting")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc12", "ensure P12 (intermediate volume) is closed")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc13", "ensure P13 (flush gas) is closed")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc15", "ensure P15 (cell) is closed")
			for(i=0;i<inVol_numFlushes;i+=1)
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: flushing cell: evacuating", "")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno14", "open valve P14 (switcher vac)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno15", "open valve P15 (cell)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, cell_vacTimeForFlush, "SendECL", "dnc14", "pump on cell for cell_vacTimeForFlush sec, then close valve P14 (switcher vac)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dnc15", "close valve P15 (cell)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: flushing cell: fill #" + num2str(i+1), "")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno13", "add flush gas via valve P13 (flush gas)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, cell_fillTimeForFlush, "SendECL", "dnc13", "stop adding flush gas via valve P13 (flush gas) after cell_fillTimeForFlush sec")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno15", "open valve P15 (cell)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, transferTimeFromIntVolToCell, "SendECL", "dnc15", "close valve P15 (cell)")
		endfor
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
	endif
	
	// THIS BLOCK PRETENDS TO FILL THE CELL WITH FLUSH GAS (POSSIBLY MULTIPLE TIMES) // for performance testing
	thisScheduleName = "PretendToFlushCell"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	if(inVol_numFlushes > 0)
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 1, measurementDuration, "ReportStatus", "SWITCHER: pretend cell flush: evacuating", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bz" + ECL_transitionIndex, "defines ecl index = transition")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "ca1", "executes ecl index")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bdFits1", "suspend fitting")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "", "fake: ensure P12 (intermediate volume) is closed")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "", "fake: ensure P13 (flush gas) is closed")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "", "fake: ensure P15 (cell) is closed")
			for(i=0;i<inVol_numFlushes;i+=1)
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: pretend cell flush: evacuating", "")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "", "fake: open valve P14 (switcher vac)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "", "fake: open valve P15 (cell)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, cell_vacTimeForFlush, "SendECL", "", "fake: pump on cell for cell_vacTimeForFlush sec, then close valve P14 (switcher vac)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "", "fake: close valve P15 (cell)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: pretend cell flush: fill #" + num2str(i+1), "")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "", "fake: add flush gas via valve P13 (flush gas)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, cell_fillTimeForFlush, "SendECL", "", "fake: stop adding flush gas via valve P13 (flush gas) after cell_fillTimeForFlush sec")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "", "fake: open valve P15 (cell)")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, transferTimeFromIntVolToCell, "SendECL", "", "fake: close valve P15 (cell)")
		endfor
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
	endif
	
	// THIS BLOCK FILLS THE INTERMEDIATE VOLUME WITH REF
	thisScheduleName = "FillIntVolWithRef"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: evacuating intermediate volume", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno14", "open valve P14 (switcher vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno12", "open valve P12 (intermediate volume)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, inVol_vacTimeForFill, "SendECL", "dnc12", "pump on intermediate volume for inVol_vacTimeForFill sec, then close valve P12 (intermediate volume)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc14", "close valve P14 (switcher vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: filling intermediate volume with ref", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "azb1,2," + IntVolTargetPressureString_ref, "fill via valve E2 (ref orifice) until gauge 2 (intermediate volume) reaches IntVolTargetPressureString_ref torr")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
	
	// THIS BLOCK TRANSFERS REF FROM THE INTERMEDIATE VOLUME TO THE CELL
	thisScheduleName = "TransferRefToCell"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 1, measurementDuration, "ReportStatus", "TILDAS: evacuating cell", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bz" + ECL_transitionIndex, "defines ecl index = transition")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "ca1", "executes ecl index")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bdFits1", "suspend fitting")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc12", "shut intermediate volume")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno14", "open vac valve")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno15", "open cell valve")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, cell_vacTimeForFill, "SendECL", "dnc14", "pump on cell for cell_vacTimeForFill sec, then shut vac valve")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: transferring ref to cell", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: transferring ref to cell", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno12", "open intermediate volume")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, transferTimeFromIntVolToCell, "SendECL", "dnc15", "wait 4 seconds to expand gas into cell, then shut cell")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc12", "close intermediate volume")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bz" + ECL_refIndex, "defines ecl index = ref")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "ca1", "executes ecl index")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bdFits0", "restarts fitting")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: measuring ref", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "StartTimer", "1", "start timer for ref measurement")
	
	// THIS BLOCK FILLS THE INTERMEDIATE VOLUME WITH SAMPLE
	thisScheduleName = "FillIntVolWithSample"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: evacuating intermediate volume", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno14", "open valve P14 (switcher vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno12", "open valve P12 (intermediate volume)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, inVol_vacTimeForFill, "SendECL", "dnc12", "pump on intermediate volume for inVol_vacTimeForFill sec, then close valve P12 (intermediate volume)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc14", "close valve P14 (switcher vac)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: filling intermediate volume from full flask", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: filling intermediate volume from full flask", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "azb1,1," + IntVolTargetPressureString_sample, "fill via valve E2 (ref orifice) until gauge 2 (intermediate volume) reaches IntVolTargetPressureString_sample torr")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: idle", "")
	
	// THIS BLOCK TRANSFERS SAMPLE FROM THE INTERMEDIATE VOLUME TO THE CELL
	thisScheduleName = "TransferSampleToCell"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 1, measurementDuration, "ReportStatus", "TILDAS: evacuating cell", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bz" + ECL_transitionIndex, "defines ecl index = transition")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "ca1", "executes ecl index")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bdFits1", "suspend fitting")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc12", "shut intermediate volume")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno14", "open vac valve")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dno15", "open cell valve")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, cell_vacTimeForFill, "SendECL", "dnc14", "pump on cell for cell_vacTimeForFill sec, then shut vac valve")
	if(pretend_Ref_is_Sample == 1) // for performance testing
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: transferring pretend sample to cell", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: transferring pretend sample to cell", "")
	else // normal operation
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: transferring sample to cell", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: transferring sample to cell", "")
	endif
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "dno12", "open intermediate volume")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, transferTimeFromIntVolToCell, "SendECL", "dnc15", "wait 4 seconds to expand gas into cell, then shut cell")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "dnc12", "close intermediate volume")
	
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bz" + ECL_sampleIndex, "defines ecl index = sample")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "ca1", "executes ecl index")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bdFits0", "restarts fitting")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: measuring sample", "")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "StartTimer", "1", "start timer for sample measurement")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "FetchData", "", "fetch latest data")
	
	// THIS BLOCK STARTS MEASUREMENT OF SAMPLE N
	for(i=0;i<numSampleGases;i+=1)
		thisScheduleName = "StartMeasuringSample" + num2str(i+1)
		thisECLindexName = "ECL Index for Sample " + num2str(i+1)
		thisECLindex = IRIS_UTILITY_GetParamValueFromName(thisECLindexName)
		IRIS_UTILITY_ClearSchedule(thisScheduleName)
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bz" + thisECLindex, "set ECL index for sample " + num2str(i+1))
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "ca1", "executes ecl index")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bdFits0", "restarts fitting")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: measuring sample " + num2str(i+1), "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "StartTimer", "1", "start timer for sample measurement")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 1, "ReportStatus", "TILDAS: fetching and analyzing data", "")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "FetchData", "", "fetch latest data")
		IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: measuring sample " + num2str(i+1), "")
	endfor
	
	// THIS BLOCK PRETENDS TO TRANSFER GAS FROM THE INTERMEDIATE VOLUME TO THE CELL // for performance testing
	thisScheduleName = "PretendToTransferGasToCell"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 1, measurementDuration, "ReportStatus", "TILDAS: pretending to evacuating cell", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bz" + ECL_transitionIndex, "defines ecl index = transition")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "ca1", "executes ecl index")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bdFits1", "suspend fitting")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "", "fake: shut intermediate volume")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "", "fake: open vac valve")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "", "fake: open cell valve")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, cell_vacTimeForFill, "SendECL", "", "fake: pump on cell for cell_vacTimeForFill sec, then shut vac valve")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: pretending to transfer gas to cell", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: pretending to transfer gas to cell", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "", "fake: open intermediate volume")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, transferTimeFromIntVolToCell, "SendECL", "", "fake: wait 4 seconds to expand gas into cell, then shut cell")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "", "fake: close intermediate volume")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: idle", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
	
	// THIS BLOCK WAITS FOR THE FINAL REF MEASUREMENT TO COMPLETE
	thisScheduleName = "WaitForFinalRefToFinish"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 1, measurementDuration, "SendECL", "bz" + ECL_transitionIndex, "defines ecl index = transition")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "ca1", "executes ecl index")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: idle", "")
	
	// THIS BLOCK DOES THE SWITCHER CYCLES FOR SAMPLE N
	for(i=0;i<numSampleGases;i+=1)
		thisScheduleName = "DoSwitcherCyclesForSample" + num2str(i+1)
		IRIS_UTILITY_ClearSchedule(thisScheduleName)
		if(pretend_to_switch == 1) // for performance testing
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "StartTimer", "1", "start dummy timer for ref measurement")
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FlushIntVol")
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FillIntVolWithRef")
			for(j=0;j<numAliquots;j+=1)
				if(j==0)
					IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FlushCell")
					IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "TransferRefToCell")
				else
					IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "PretendToFlushCell")
					IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "PretendToTransferGasToCell")
					IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bz" + ECL_refIndex, "defines ecl index = ref")
					IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "ca1", "executes ecl index")
					IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bdFits0", "restarts fitting")
					IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: measuring ref", "")
					IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
					IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "StartTimer", "1", "start timer for ref measurement")
				endif
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "PretendToFlushCell")
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "PretendToTransferGasToCell")
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "StartMeasuringSample" + num2str(i+1))
			endfor
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "PretendToFlushCell")
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "PretendToTransferGasToCell")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bz" + ECL_refIndex, "defines ecl index = ref")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "ca1", "executes ecl index")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "bdFits0", "restarts fitting")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: measuring ref", "")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "StartTimer", "1", "start timer for ref measurement")
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "WaitForFinalRefToFinish")
		else // normal operation
			IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "StartTimer", "1", "start dummy timer for ref measurement")
			for(j=0;j<numAliquots;j+=1)
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FlushIntVol")
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FillIntVolWithRef")
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FlushCell")
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "TransferRefToCell")
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FlushIntVol")
				if(pretend_Ref_is_Sample == 1) // for performance testing
					IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FillIntVolWithRef")
				else // normal operation
					IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FillIntVolWithSample")
				endif
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FlushCell")
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "TransferSampleToCell")
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "StartMeasuringSample" + num2str(i+1))
			endfor
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FlushIntVol")
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FillIntVolWithRef")
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FlushCell")
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "TransferRefToCell")
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "WaitForFinalRefToFinish")
		endif
	endfor
	
	// === BUILD THE RESET SCHEDULE ===
	// 1. A schedule called "Reset", which clears the ECL queue, closes the valves, and starts a new STR/STC file (this will be directly invoked when the "STOP" button is clicked and is also a convenient building block for the Prologue and Epilogue);
	
	// Reset sampling system
	thisScheduleName = "Reset"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: clearing queue", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "cq", "immediately clear the ECL queue (this command jumps to the front of the queue)")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 3, "SendECL", "bz" + ECL_transitionIndex, "set ECL index to transition")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "ca1", "start writing ECL index")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "bdfits0", "activate spectral fits")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: idle", "")
	IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "DeactivateAllValves")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "SWITCHER: idle", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "MIXER: idle", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "amwd0", "deactivate write disk")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "amass0", "deactivate auto spectral save")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: fetching and analyzing data", "")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "FetchData", "", "fetch latest data")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "SendECL", "ax" + sBaselinePolyOrder, "set baseline polynomial order to sBaselinePolyOrder")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "amwd1", "activate write disk")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "SendECL", "amass1", "activate auto spectral save")
	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 0, "ReportStatus", "TILDAS: idle", "")
	
	// === BUILD THE PROLOGUE SCHEDULE ===
	// 2. A schedule called "Prologue", which consists of the things that happen only at the beginning of the run;
	
	variable upperFlask = 1
	
	thisScheduleName = "Prologue"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "WaitForUser", "MIXER: attach sample " + num2str(1) + " (" + "S349283dkrfd" + ")", "")
	IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "Reset")	
//	// TESTING!!!
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "TILDAS: testing1a", "")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 1, "ReportStatus", "TILDAS: testing1b", "")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "SWITCHER: testing2", "")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "testing0", "")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "WaitForUser", "MIXER: Inject sample and then click -->", "")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, valveActionTimeSpacer, "ReportStatus", "MIXER: testing3", "")
//	IRIS_UTILITY_AppendEventToSchedule(thisScheduleName, 0, 1, "ReportStatus", "TILDAS: testing1c", "")
//	// END TESTING!!!
	IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "InitializeRegisters")
	IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "EvacuateSystem")
	IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "DeactivateAllValves")
	if((pretend_Ref_is_Sample == 0) && (pretend_to_switch == 0)) // normal operation
		if(manualSampleInjectionByVial == 1)
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "ManualVialInjectionOfSample" + num2str(1))
		elseif(manualSampleInjectionBySeptum == 1)
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "ManualSeptumInjectionOfSample" + num2str(1))
		endif
		if(flasks_numFlushes > 0)
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FlushFlask")
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "EvacuateFlask")
		endif
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "RecordMixerZeroPressures")
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "AddCO2toUpperFlask")
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "AddDilutionGas")
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "CloseAllMixerManifoldValves")
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "ForwardFlushBeforeMixing")
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "WaitForFirstMix")
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "ForwardFlushAfterMixing")
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "BackwardFlushAfterMixing")
	endif
	IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "ToggleRegisters")
	upperFlask = 1 - upperFlask
//	if(pretend_to_switch == 1)
//		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "OpenRefGasSupplyPort")
//		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FlushIntVol")
//		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FillIntVolWithRef")
//		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FlushCell")
//		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "TransferRefToCell")
//	endif
	
	// === BUILD THE CYCLE SCHEDULE ===
	// 3. A schedule called "Cycle", which consists of the things that happen repetitively;
	
	thisScheduleName = "Cycle"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	for(i=1;i<numSampleGases;i+=1)
		if((pretend_Ref_is_Sample == 0) && (pretend_to_switch == 0)) // normal operation
			if(manualSampleInjectionByVial == 1)
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "ManualVialInjectionOfSample" + num2str(i+1))
			elseif(manualSampleInjectionBySeptum == 1)
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "ManualSeptumInjectionOfSample" + num2str(i+1))
			endif
			if(flasks_numFlushes > 0)
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "FlushFlask")
			endif
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "EvacuateFlask")
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "RecordMixerZeroPressures")
			if(upperFlask == 1)
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "AddCO2toUpperFlask")
			else
				IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "AddCO2toLowerFlask")
			endif
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "AddDilutionGas")
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "CloseAllMixerManifoldValves")
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "ForwardFlushBeforeMixing")
		endif
		if(doABGwithZeroAir == 1)
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "SubtractZeroAirBackground")
		elseif(doABGwithVacuum == 1)
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "SubtractVacground")
		endif
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "OpenRefGasSupplyPort")
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "DoSwitcherCyclesForSample" + num2str(i))
		if((pretend_Ref_is_Sample == 0) && (pretend_to_switch == 0)) // normal operation
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "ForwardFlushAfterMixing")
			IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "BackwardFlushAfterMixing")
		endif
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "ToggleRegisters")
		upperFlask = 1 - upperFlask
	endfor
	
	// === BUILD THE EPILOGUE SCHEDULE ===
	// 4. A schedule called "Epilogue", which consists of the things that happen only at the end of the run, after the last cycle.
	
	thisScheduleName = "Epilogue"
	IRIS_UTILITY_ClearSchedule(thisScheduleName)
	if(doABGwithZeroAir == 1)
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "SubtractZeroAirBackground")
	elseif(doABGwithVacuum == 1)
		IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "SubtractVacground")
	endif
	IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "OpenRefGasSupplyPort")
	IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "DoSwitcherCyclesForSample" + num2str(numSampleGases))
	IRIS_UTILITY_AppendScheduleToSchedule(thisScheduleName, "Reset")
	
	DoUpdate
	
End

////////////////////////
// Analysis Functions //
////////////////////////

Function IRIS_SCHEME_Analyze_D17O_d13C_CO2()
	
	// NOTE: "UNIVERSAL" sections must be included exactly as they are, exactly where they are.
	
	// === UNIVERSAL: SETUP (do not modify) ===
	
	NVAR numSampleGases = root:numSampleGases
	NVAR numRefGases = root:numRefGases
	
	wave wNumCompleteMeasurementsByGas = root:wNumCompleteMeasurementsByGas
	
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
	
	variable infoFlag
	make/O/N=(numRefGases) wRefTrueValues_CO2, wRefTrueValues_d13C, wRefTrueValues_d18O, wRefTrueValues_d17O
	for(refNum=0;refNum<numRefGases;refNum+=1)
		
		infoFlag = 0
		
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
		
		if(infoFlag > 0)
			IRIS_EVENT_ReportStatus("TILDAS: WARNING: The info for working ref " + num2str(refNum+1) + " is invalid!")
			SetDataFolder $saveFolder
			return 1
		endif
		
	endfor
	
//	if(infoFlag > 0)
//		IRIS_UTILITY_AppendStringToNoteBook("StatusNotebook", secs2time(DateTime,3) + "  " + "*** WARNING: The info for working gas " + num2str(refNum+1) + " is invalid! ***")
//	endif
	
	// === CONVERT TRUE REF GAS DELTAS AND TOTAL CO2 TO ISOTOPOLOGUE MOLE FRACTIONS ===
	// NOTE: You must name the ref gas true isotopologue waves in the format: wRefTrueValues_iXXX, where XXX is 626 or 628 or 627_A, etc. (iXXX must be an entry in wOutputVariableSourceDataNames[wIndicesOfVariablesToCalibrate[j]] for some j).
	
	make/O/D/N=(numRefGases) wRefTrueValues_i626, wRefTrueValues_i626_A, wRefTrueValues_i636, wRefTrueValues_i628, wRefTrueValues_i628_A, wRefTrueValues_i627_A
	[wRefTrueValues_i626, wRefTrueValues_i636, wRefTrueValues_i628, wRefTrueValues_i627_A] = IRIS_UTILITY_ConvertFrom_d13C_d18O_d17O(wRefTrueValues_CO2, wRefTrueValues_d13C, wRefTrueValues_d18O, wRefTrueValues_d17O)
	wRefTrueValues_i626_A = wRefTrueValues_i626
	wRefTrueValues_i628_A = wRefTrueValues_i628
	
	// === CALCULATE DERIVED VARIABLES, PRE-CALIBRATION ===
	// NOTE: The names of the mole fraction waves imported from TDL Wintel have the format root:iXXX for isotopologues (e.g. root:i626, root:i638, root:i627_A) and simply root:XXX otherwise (e.g. root:CO2, root:N2O), except for OCS, which is root:xOCS for some reason.
	//       All variables in the IRIS_SCHEME_DefineVariables function that have type "str" or "stc" but are not imported from TDL Wintel must be created here.
	
	variable lambda_O17O18_slope = str2num(IRIS_UTILITY_GetParamValueFromName("Reference Slope (λ)"))
	
	if(exists("str_source_rtime") == 0)
		SetDataFolder $saveFolder
		return 1
	endif
	
	wave i626 = root:i626
	wave i626_A = root:i626_A
	wave i636 = root:i636
	wave i627_A = root:i627_A
	wave i628 = root:i628
	wave i628_A = root:i628_A
	
	duplicate/O i626, del13C, del17O, del18O, capDel17O
	del13C = 1000*((i636/i626) - 1) //permil (vs HITRAN, uncalibrated)
	del17O = 1000*((i627_A/i626_A) - 1) //permil (vs HITRAN, uncalibrated) // using L2 626 and L2 627
	del18O = 1000*((i628_A/i626_A) - 1) //permil (vs HITRAN, uncalibrated)	 // using L2 626 and L2 628
	capDel17O = 1000*ln(del17O/1000 + 1) - lambda_O17O18_slope*1000*ln(del18O/1000 + 1)
	
	duplicate/O i626, del13C_alt, del17O_alt, del18O_alt, capDel17O_alt
	del13C_alt = 1000*((i636/i626_A) - 1) //permil (vs HITRAN, uncalibrated)
	del17O_alt = 1000*((i627_A/i626) - 1) //permil (vs HITRAN, uncalibrated) // using L1 626 and L2 627
	del18O_alt = 1000*((i628/i626) - 1) //permil (vs HITRAN, uncalibrated) // using L1 626 and L1 628
	capDel17O_alt = 1000*ln(del17O_alt/1000 + 1) - lambda_O17O18_slope*1000*ln(del18O_alt/1000 + 1)
	
	// === UNIVERSAL: CALCULATE THE MEAN AND STANDARD ERROR FOR EACH CELL FILL (do not modify) ===
	
	IRIS_UTILITY_CalculateGasFillMeansForAllVariables()
	
	// === FOR EACH SAMPLE GAS... ===
		
	for(sampleNum=0;sampleNum<numSampleGases;sampleNum+=1) 
		
		if(wNumCompleteMeasurementsByGas[sampleNum] > 0)
			
			// === ...UNIVERSAL: CALIBRATE SAMPLE SPECIES/ISOTOPOLOGUE MEANS VIA THE REF GAS(ES) (do not modify) ===
			
			IRIS_UTILITY_CalibrateAllSampleVariablesViaRefs(sampleNum)
			
			// === ...CALCULATE DERIVED VARIABLES, POST-CALIBRATION ===
			// NOTE: The names of the calibrated mole fraction waves that you can use here have the format: root:X_cal, where X is the name of the corresponding wave imported from TDL Wintel (e.g. root:i626_cal or root:N2O_cal or root:xOCS_cal).
			//       All variables in the IRIS_SCHEME_DefineVariables function that have type "avg" but calibrateOrNot = 0 must be created here.
			
			wave i626_cal = root:i626_cal
			wave i626_A_cal = root:i626_A_cal
			wave i636_cal = root:i636_cal
			wave i627_A_cal = root:i627_A_cal
			wave i628_cal = root:i628_cal
			wave i628_A_cal = root:i628_A_cal
			
			duplicate/O i626_cal, CO2_Avg, d13C_VPDB_Avg, d18O_VSMOW_Avg, d17O_VSMOW_Avg, d17O_prime, d18O_prime, CapD17O
			duplicate/O i626_cal, CO2_Avg_alt, d13C_VPDB_Avg_alt, d18O_VSMOW_Avg_alt, d17O_VSMOW_Avg_alt, d17O_prime_alt, d18O_prime_alt, CapD17O_alt
			[CO2_Avg_alt, d13C_VPDB_Avg_alt, d18O_VSMOW_Avg, d17O_VSMOW_Avg] = IRIS_UTILITY_ConvertTo_d13C_d18O_d17O(i626_A_cal, i636_cal, i628_A_cal, i627_A_cal) // get d17O and d18O using L1 636 and L2 626, 627, 628
			[CO2_Avg, d13C_VPDB_Avg, d18O_VSMOW_Avg_alt, d17O_VSMOW_Avg_alt] = IRIS_UTILITY_ConvertTo_d13C_d18O_d17O(i626_cal, i636_cal, i628_cal, i627_A_cal) // get CO2 and d13C using L1 626, 636, 628 and L2 627
			d17O_prime = 1000*ln(d17O_VSMOW_Avg/1000 + 1)
			d18O_prime = 1000*ln(d18O_VSMOW_Avg/1000 + 1)
			CapD17O = d17O_prime - lambda_O17O18_slope * d18O_prime // this is the small deviation from the 'conventional' bulk slope (Sharp et al.)
			d17O_prime_alt = 1000*ln(d17O_VSMOW_Avg_alt/1000 + 1)
			d18O_prime_alt = 1000*ln(d18O_VSMOW_Avg_alt/1000 + 1)
			CapD17O_alt = d17O_prime_alt - lambda_O17O18_slope * d18O_prime_alt // this is the small deviation from the 'conventional' bulk slope (Sharp et al.)
			
			// === ...UNIVERSAL: ASSIGN REMAINING RESULTS TO OUTPUT VARIABLES (do not modify) ===
			
			IRIS_UTILITY_AssignAllSpecialOutputVariables(sampleNum)
			
		endif
		
	endfor
	
	// === UNIVERSAL: WRAP-UP (do not modify) ===
	
	IRIS_UTILITY_AnalysisWrapUp()
	
	SetDataFolder $saveFolder
	return 0
	
End

Function IRIS_SCHEME_Analyze_D17O_d13C_CO2_CapeTown()
	
	IRIS_SCHEME_Analyze_D17O_d13C_CO2()
	
End

Function IRIS_SCHEME_Analyze_D17O_d13C_CO2_FastMixer()
	
	IRIS_SCHEME_Analyze_D17O_d13C_CO2()
	
End

Function IRIS_SCHEME_Analyze_D17O_d13C_CO2_LBL()
	
	IRIS_SCHEME_Analyze_D17O_d13C_CO2()
	
End