onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -clampanalog 1 -format Analog-Step -height 75 -max 0.5 -min -0.5 /tb_adc_100m_bd_filter/InputData.RE
add wave -noupdate -clampanalog 1 -format Analog-Step -height 75 -max 1.0 -min -1.0 /tb_adc_100m_bd_filter/DUTOutputDataSig.RE
add wave -noupdate -expand -subitemconfig {/tb_adc_100m_bd_filter/DUTOutputsFFT.Value -expand /tb_adc_100m_bd_filter/DUTOutputsFFT.Value.MAG {-clampanalog 1 -format Analog-Step -height 75 -max 0.080000000000000002} /tb_adc_100m_bd_filter/DUTOutputsFFT.MagnitudeIndB {-clampanalog 1 -format Analog-Step -height 75 -max -23.0 -min -55.0} /tb_adc_100m_bd_filter/DUTOutputsFFT.Frequency {-clampanalog 1 -format Analog-Step -height 75 -max 1.0}} /tb_adc_100m_bd_filter/DUTOutputsFFT
add wave -noupdate -expand -subitemconfig {/tb_adc_100m_bd_filter/MismatchSig.RE {-format Analog-Step -height 25 -max 0.00012999999999999999} /tb_adc_100m_bd_filter/MismatchSig.IM {-format Analog-Step -height 25 -max 0.00012999999999999999}} /tb_adc_100m_bd_filter/MismatchSig
add wave -noupdate -expand -subitemconfig {/tb_adc_100m_bd_filter/MaxMismatchSig.RE {-format Analog-Step -height 25 -max 0.00012210000000000001}} /tb_adc_100m_bd_filter/MaxMismatchSig
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {6871236 ps} 0}
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
WaveRestoreZoom {0 ps} {8372700 ps}
