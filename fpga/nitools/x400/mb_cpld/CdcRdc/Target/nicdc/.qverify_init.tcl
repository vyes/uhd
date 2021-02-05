set baseDir [file normalize $::env(HWBUILDTOOLSBASE)]
set SetupTclToolsQuestaCdc ${baseDir}/TclTools/SetupTclToolsModelsim.tcl
uplevel #0 [list source $SetupTclToolsQuestaCdc]
