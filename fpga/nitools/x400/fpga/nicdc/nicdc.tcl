# nicdc.tcl

set projectRoot "[file normalize ../../../../../]"

set vlogFiles [list \
    $projectRoot/fpga/usrp3/top/x400/ip/axi_interconnect_dma_bd/axi_interconnect_dma.sv \
    $projectRoot/fpga/usrp3/top/x400/ip/axi_interconnect_eth_bd/axi_interconnect_eth.sv \
    $projectRoot/fpga/usrp3/top/x400/ip/axi_eth_dma_bd/axi_eth_dma.sv \
    $projectRoot/fpga/usrp3/lib/axi4_sv/PkgAxi.sv \
    $projectRoot/fpga/usrp3/lib/axi4_sv/AxiIf.sv \
    $projectRoot/fpga/usrp3/lib/axi4lite_sv/PkgAxiLite.sv \
    $projectRoot/fpga/usrp3/lib/axi4lite_sv/AxiLiteIf.sv \
    $projectRoot/fpga/usrp3/lib/axi4s_sv/AxiStreamIf.sv \
    $projectRoot/fpga/usrp3/lib/axi4s_sv/axi4s_remove_bytes_start.sv \
    $projectRoot/fpga/usrp3/lib/axi4s_sv/axi4s_remove_bytes.sv \
    $projectRoot/fpga/usrp3/lib/axi4s_sv/axi4s_width_conv.sv \
    $projectRoot/fpga/usrp3/lib/axi4s_sv/axi4s_packet_gate.sv \
    $projectRoot/fpga/usrp3/lib/axi4s_sv/axi4s_add_bytes.sv \
    $projectRoot/fpga/usrp3/lib/rfnoc/xport_sv/eth_ipv4_chdr_dispatch.sv \
    $projectRoot/fpga/usrp3/lib/rfnoc/xport_sv/chdr_xport_adapter.sv \
    $projectRoot/fpga/usrp3/lib/axi4s_sv/axi4s_fifo.sv \
    $projectRoot/fpga/usrp3/lib/rfnoc/xport_sv/eth_ipv4_add_udp.sv \
    $projectRoot/fpga/usrp3/lib/rfnoc/xport_sv/eth_ipv4_chdr_adapter.sv \
    $projectRoot/fpga/usrp3/lib/rfnoc/xport_sv/eth_ipv4_interface.sv \
    $projectRoot/fpga/usrp3/lib/rfnoc/xport_sv/eth_ipv4_internal.sv \
    $projectRoot/fpga/usrp3/top/x400/x4xx_mgt_io_core.sv \
    $projectRoot/fpga/usrp3/top/x400/x4xx_qsfp_wrapper.sv \
    $projectRoot/fpga/usrp3/top/x400/x4xx_qsfp_wrapper_temp.sv \
    \
    $projectRoot/fpga/usrp3/lib/rfnoc/utils/chdr_trim_payload.v \
    $projectRoot/fpga/usrp3/lib/control/regport_resp_mux.v \
    $projectRoot/fpga/usrp3/lib/control/axil_regport_master.v \
    $projectRoot/fpga/usrp3/lib/packet_proc/arm_deframer.v \
    $projectRoot/fpga/usrp3/lib/xge_interface/axi64_to_xge64.v \
    \
    $projectRoot/fpga/usrp3/lib/timing/pps_generator.v \
    $projectRoot/fpga/usrp3/top/x400/dboards/db_gpio_reordering.v \
    $projectRoot/fpga/usrp3/top/x400/cpld_interface_regs.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/utils/ctrlport_terminator.v \
    $projectRoot/fpga/usrp3/lib/control/axil_ctrlport_master.v \
    $projectRoot/fpga/usrp3/top/x400/x4xx_versioning_regs.v \
    $projectRoot/fpga/usrp3/lib/control/glitch_free_mux.v \
    $projectRoot/fpga/usrp3/lib/control/map/cam_priority_encoder.v \
    $projectRoot/fpga/usrp3/lib/fifo/axis_strm_monitor.v \
    $projectRoot/fpga/usrp3/lib/fifo/axis_fifo_monitor.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/crossbar/axis_port_terminator.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/split_stream.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/axi_pipe.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/axi_join.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/axi_pipe_join.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/mult.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/cvita_hdr_decoder.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/cvita_hdr_encoder.v \
    $projectRoot/fpga/usrp3/lib/control/setting_reg.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/split_complex.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/join_complex.v \
    $projectRoot/fpga/usrp3/lib/dsp/sign_extend.v \
    $projectRoot/fpga/usrp3/lib/dsp/clip.v \
    $projectRoot/fpga/usrp3/lib/dsp/add2_and_clip.v \
    $projectRoot/fpga/usrp3/lib/dsp/add2_and_clip_reg.v \
    $projectRoot/fpga/usrp3/lib/dsp/round.v \
    $projectRoot/fpga/usrp3/lib/dsp/round_sd.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/utils/ctrlport_to_settings_bus.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/utils/ctrlport_splitter.v \
    $projectRoot/fpga/usrp3/lib/control/pulse_stretch_min.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/core/axis_ctrl_master.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/core/chdr_compute_tkeep.v \
    $projectRoot/fpga/usrp3/lib/axi/axis_upsizer.v \
    $projectRoot/fpga/usrp3/lib/axi/axis_downsizer.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/utils/ctrlport_decoder.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/utils/ctrlport_combiner.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/utils/ctrlport_decoder_param.v \
    $projectRoot/fpga/usrp3/lib/control/gearbox_2x1.v \
    $projectRoot/fpga/usrp3/lib/fifo/axi_fifo_flop2.v \
    $projectRoot/fpga/usrp3/lib/fifo/axi_fifo_short.v \
    $projectRoot/fpga/usrp3/lib/control/ram_2port.v \
    $projectRoot/fpga/usrp3/lib/fifo/axi_fifo_bram.v \
    $projectRoot/fpga/usrp3/lib/control/synchronizer_impl.v \
    $projectRoot/fpga/usrp3/lib/control/synchronizer.v \
    $projectRoot/fpga/usrp3/lib/fifo/axi_fifo_flop.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/utils/ctrlport_timer.v \
    $projectRoot/fpga/usrp3/top/x400/dboards/ctrlport_byte_serializer.v \
    $projectRoot/fpga/usrp3/top/x400/dboards/db_gpio_interface.v \
    $projectRoot/fpga/usrp3/top/x400/x4xx_pps_sync.v \
    $projectRoot/fpga/usrp3/top/x400/qsfp_led_controller.v \
    $projectRoot/fpga/usrp3/top/x400/ipass_present_controller.v \
    $projectRoot/fpga/usrp3/lib/control/simple_spi_core_64bit.v \
    $projectRoot/fpga/usrp3/top/x400/ctrlport_spi_master.v \
    $projectRoot/fpga/usrp3/top/x400/x4xx_dio.v \
    $projectRoot/fpga/usrp3/lib/control/map/cam_srl.v \
    $projectRoot/fpga/usrp3/lib/control/map/cam_bram.v \
    $projectRoot/fpga/usrp3/lib/control/map/cam.v \
    $projectRoot/fpga/usrp3/lib/control/map/kv_map.v \
    $projectRoot/fpga/usrp3/lib/axi/axis_data_swap.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/core/chdr_data_swapper.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/crossbar/axis_switch.v \
    $projectRoot/fpga/usrp3/lib/control/reset_sync.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/cic_decimate.v \
    $projectRoot/fpga/usrp3/lib/dsp/clip_reg.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/blocks/rfnoc_block_radio/radio_tx_core.v \
    $projectRoot/fpga/usrp3/lib/control/pulse_synchronizer.v \
    $projectRoot/fpga/usrp3/lib/fifo/axi_fifo_2clk.v \
    $projectRoot/fpga/usrp3/lib/axi/axis_packet_flush.v \
    $projectRoot/fpga/usrp3/top/x400/rfdc_timing_control.v \
    $projectRoot/fpga/usrp3/top/x400/rf/400m/rf_core_400m.v \
    $projectRoot/fpga/usrp3/lib/fifo/axi_fifo.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/axi_clip.v \
    $projectRoot/fpga/usrp3/top/x400/rf/200m/rf_up_2to4.v \
    $projectRoot/fpga/usrp3/lib/control/handshake.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/utils/ctrlport_clk_cross.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/utils/timekeeper.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/core/chdr_ingress_fifo.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/core/chdr_stream_input.v \
    $projectRoot/fpga/usrp3/lib/axi/axi_to_strobed.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/axi_tag_time.v \
    $projectRoot/fpga/usrp3/lib/control/axi_setting_reg.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/axi_sync.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/axi_round.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/axi_round_complex.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/dds_freq_tune.v \
    $projectRoot/fpga/usrp3/lib/axi/strobed_to_axi.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/ddc.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/blocks/rfnoc_block_radio/radio_rx_core.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/blocks/rfnoc_block_radio/radio_core.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/core/backend_iface.v \
    $projectRoot/fpga/usrp3/lib/fifo/axi_packet_gate.v \
    $projectRoot/fpga/usrp3/lib/fifo/axi_demux.v \
    $projectRoot/fpga/usrp3/lib/fifo/axi_mux.v \
    $projectRoot/fpga/usrp3/lib/axi/axis_width_conv.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/core/axis_data_to_chdr.v \
    $projectRoot/fpga/usrp3/top/x400/rf/200m/rf_down_4to2.v \
    $projectRoot/fpga/usrp3/top/x400/rf/200m/rf_core_200m.v \
    $projectRoot/fpga/usrp3/top/x400/cpld_interface.v \
    $projectRoot/fpga/usrp3/top/x400/x4xx_global_regs.v \
    $projectRoot/fpga/usrp3/top/x400/x4xx_core_common.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/crossbar/chdr_xb_ingress_buff.v \
    $projectRoot/fpga/usrp3/lib/control/map/axis_muxed_kv_map.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/crossbar/chdr_xb_routing_table.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/core/chdr_to_axis_ctrl.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/core/chdr_stream_output.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/core/chdr_mgmt_pkt_handler.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/core/chdr_stream_endpoint.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/crossbar/axis_ingress_vc_buff.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/crossbar/torus_2d_dor_router_single_sw.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/cic_interpolate.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/axi_round_and_clip.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/axi_round_and_clip_complex.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/duc.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/axi_drop_partial_packet.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/axi_rate_change.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/core/axis_ctrl_slave.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/core/ctrlport_endpoint.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/core/chdr_to_axis_data.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/blocks/rfnoc_block_radio/noc_shell_radio.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/blocks/rfnoc_block_radio/rfnoc_block_radio.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/crossbar/chdr_crossbar_nxn.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/crossbar/mesh_2d_dor_router_single_sw.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/crossbar/axis_ctrl_crossbar_2d_mesh.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/crossbar/axis_ctrl_crossbar_nxn.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/core/rfnoc_core_kernel.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/dds_timed.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/blocks/rfnoc_block_duc/noc_shell_duc.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/blocks/rfnoc_block_duc/rfnoc_block_duc.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/blocks/rfnoc_block_ddc/noc_shell_ddc.v \
    $projectRoot/fpga/usrp3/lib/rfnoc/blocks/rfnoc_block_ddc/rfnoc_block_ddc.v \
    $projectRoot/fpga/usrp3/top/x400/x410_100_rfnoc_image_core.v \
    $projectRoot/fpga/usrp3/top/x400/x4xx_core.v \
    $projectRoot/fpga/usrp3/top/x400/x4xx.v \
]

set vcomFiles [list \
    $projectRoot/fpga/usrp3/lib/packet_proc/arp_responder/arp_responder.vhd \
]

# Set `define values for X410_X4_200 build
set X410_X4_200_DEFINES [ list \
    +define+X410 \
    +define+QSFP0_0=2 \
    +define+QSFP0_1=2 \
    +define+QSFP0_2=2 \
    +define+QSFP0_3=2 \
    +define+RFBW_200M=1 \
]

netlist fpga -vendor xilinx -library vivado -version 2019.1
vcom -quiet -2008 -skipsynthoffregion $vcomFiles
vlog -quiet -skipsynthoffregion $X410_X4_200_DEFINES $vlogFiles

do directives.tcl
do exceptions.tcl

# CDC Analysis
configure output directory cdc
# cdc run -d x4xx -report_clock
cdc run -d x4xx
cdc generate report cdc_detail.rpt
msg generate report cdc_msg.rpt
puts "======================================================================="
puts "Running ni_check_cdc"
puts "======================================================================="
ni_check_cdc

# RDC Analysis
configure output directory rdc
resetcheck run -d x4xx
resetcheck generate report rdc_detail.rpt
msg generate report rdc_msg.rpt
puts "======================================================================="
puts "Running ni_check_rdc"
puts "======================================================================="
ni_check_rdc

# NI Analysis
puts "======================================================================="
puts "Running ni_report_summary"
puts "======================================================================="
ni_report_summary
