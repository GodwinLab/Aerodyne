Global Utils quick tutor [see readme below for more information]

Dandy Global Utilities you can call yourself
tip: use graphName = "" for the top graph

ApplyColor2Graph( graphName, traceName, Color_str )
ApplyColor2Axis( graphName, axisName, Color_str )

	Color_str must match one of the following...
	Red, Pink, Salmon, Wine, Orange, Yellow, Mustard, PhosGreen, Green, DarkGreen
	Cyan, Aqua, Blue, Midnight, SkyBlue, StormBlue, Purple, Violet
	Black, DarkGray/Grey, Gray/Grey, LightGray/Grey, White 

StackAllAxes(graphName, 0, 0) or
	StackAllAxes(graphName, 1, 1) for 1% gaps
AllAxesFreePosZero(graphName)
PrimaryColors(graphName)
PutCursorsOnGraph(graphName)
ScaleAllYAxes( graph_name)

Date and Time functions where a 'DateTime' is a large number in igor time units
Text2DateTime( textDateTime )
	for example "10/31/01 15:59:59" becomes   3087388799
DateTime2Text (aDateTime )
	for example 3087388799 becomes   "10/31/2001 15:59:59"
	or   "10/31/01 15:59:59" depending on your windows date
	preferences

See the global_utils.ipf for more info on the following...
GenerateFileList, GenerateFolderList, XOP_FileMove( current, new )
IfNeedDoScroll(graph_name, thresh_frac, back_to)
FileExists( path, filename ) [note the return codes]

-=-=-=-=-= Readme File for TDL Igor Routines -=-=-=-=-=-

1. Contact Information
2. List of Files
3. Directions for Installation
4. Adding your own functions to these
5. Hook Registration in Global Utils


-=-=-=-=-=-= 1. Contact Information -=-=-=-=-=-=-=-=-=-

People who maintain and work on these ipfs
	Scott Herndon <herndon@aerodyne.com>
	Joanne Shorter <shorther@aerodyne.com>
	Dave Nelson <ddn@aerodyne.com>
	Mark Zahniser <mz@aerodyne.com>

People who also have contributed to the AMS tools which
may be partially located in this directory
	Manjula Canagaratna <mrcana@aerodyne.com>


-=-=-=-=-=-= 2. List of Files       -=-=-=-=-=-=-=-=-=-

**Global_Utils.ipf
	This file contains many functions which are handy.
Every procedure in this folder makes calls to functions
located in Global_utils.ipf, so this file is imperative.
Whenever you copy any other ipfs, go ahead and copy the
most recent Global_utils.ipf



**LoadSPE.ipf
	LoadSPE contains primative file loaders for tdlwintel
'spe' files and for tdlwintel 'str' files.  It also has 
reasonable user interfaces for loading one or more spe files 
and directing the creation of graphs, channel to wavelength.
The primative loader is the first function in the file, and there
are comments there, however see LoadSPE below for additional information

**aerodyneTools.ipf
	This ipf contains specific TDL Wintel helper functions, 
such as DrawHitManPanel() [useful for making hit files].  It could be
argued that aerodyneTools as a name is too large a class.  It is currently 
the ipf where Aerodyne's TDL functions belong.  It will continue to 
be named aerodyneTools for historical reasons.  LoadSPE can be thought
of as a subordinate ipf to aerodyneTools, which was spun out into
its own ipf.


-=-=-=-=-=-= 3. Directions for Installation -=-=-=-=-=-

Copy Global_Utils and any other ipfs you are interested in to
your locale drive.  It is suggested you place them somewhere like
c:igor routines or c:my documents:igor routines

Next open the Igor Procedures folder typically located at
c:program files:wavemetrics:igor pro folder:igor procedures
or
c:igor4:igor procedures 

Place short cuts to the ipfs you want to have loaded whenever igor
is launched in the igor procedures folder.  That is to say select 
the files you just copied and right click drag them to the other
open window [igor procedures] and select make short cuts here.

Place short cuts for the relevant XOPs by dropping them into the IGOR EXTENSIONS folder 

Relaunch igor

If you have a compile error, it will be because a file hasn't been loaded
To see a listing of what ipfs have been loaded go to
Igor Application and select Menu>Window:Other Windows> and make sure that
for example global_utils, aerodyneTools and LoadSPE are all listed.


-=-=-=-=-=-= 4. Adding your own Functions to these =-=-

Please do.  When you have a function(s) to add, you might develop them
in your own ipf file, locally and if there are functions which you
feel should be 'global', let one of the people in the contact list know.

-=-=-=-=-=-= 5. Hook Registration in Global Utils -=-=-

CursorMovedHook( infoStr ) is located in Global Utils.  If you use
this function yourself, you will have to reconcile the differences.
Renaming the Global Utils CursorMovedHook is probably the easiest
solution, and copying whatever functionality it provides that you like to your own


-=-=-=-= LoadSPE -=-=-=-=-=-

Function LoadSPE( path_str, file_str, base_str, dest_DF_str, graph_code, wavelength_code )
path_str is a string containing the path to the file, for example,

 "c:tdl wintel:data"
Note the use of : characters in place of windows "\".  Be aware that slash will also work,
but you must construct the string in igor using \\ to represent a single slash.
For Networked drives, "//NetWorkedDriveName:tdl wintel:data" will also work.

file_str is a string containing the filename, such as "011031_235959_1.spe"

base_str is a string containting a prefix with will be used to create the wavenames.  
This is an excellent opportunity to give the waves a descriptive name so they 
will be easy to use later.

dest_DF_str is a string containing the name of the data folder to load the
waves to.  This is an igor data folder.  If you do not use them, you can pass
the string "root:" or a null string, "" and it will be loaded in the root level.
This is also an opportunity to organize incoming data, but one either embraces the
notion of DataFolders or they don't.

graph_code is a variable, send 0 to make no graphs, and non zero for make different kinds
of graphs.  See ipf for details

wavelength_code is a variable, send 0 to prohibit the construction of a wavelength wave

This function returns error codes which your calling function can trap, but you
will have to see the ipf for details.

9/2002 LoadSpe has grown beyond its original scope.  It now supports Version 4 and 5 
SPE files.  A special readme will need to be created for LoaderBrowser.

-=-=-=-= SelectLines -=-=-=-=-=-
This is a series of functions to select peaks in a spectrum to generate a "hitran-like" listing.  It also contains functions for comparing high and low
resolution spectra.  
See the readme notebook for SelectLines (ReadMeSelectLines.txt) found in the folder:
Latest Software Versions\TDL Igor Routines 