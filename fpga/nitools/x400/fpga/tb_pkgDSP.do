onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -subitemconfig {/tb_pkgdsp/FFTVisual.MagnitudeIndB {-clampanalog 1 -format Analog-Step -height 100 -max 0.001 -min -120.0} /tb_pkgdsp/FFTVisual.Frequency {-clampanalog 1 -format Analog-Step -height 50 -max 1.0}} /tb_pkgdsp/FFTVisual
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1208320 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {2150400 ps}
