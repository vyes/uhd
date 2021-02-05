--
-- Copyright 2019 Ettus Research, A National Instruments Company
--
-- SPDX-License-Identifier: LGPL-3.0-or-later
--
-- Module: tb_x4xx_core_common
-- Description:
-- Testbench for X4XX core common

--nisim --op1="-L fifo_generator_v13_2_4 -L unisim"

--synopsys translate_off
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work;
  use work.PkgNiSim.all;
  use work.PkgNiUtilities.all;
  use work.PkgBusApi.all;
  use work.PkgAxi4Lite.all;
  use work.PkgGLOBAL_REGS_REGMAP.all;
  use work.PkgDIO_REGMAP.all;
  use work.PkgCORE_REGS_REGMAP.all;

entity tb_x4xx_core_common is end tb_x4xx_core_common;

architecture test of tb_x4xx_core_common is

  component axil_ctrlport_master
    generic (
      TIMEOUT         : integer := 10;
      AXI_AWIDTH      : integer := 17;
      CTRLPORT_AWIDTH : integer := 17);
    port (
      s_axi_aclk                : in  std_logic;
      s_axi_aresetn             : in  std_logic;
      s_axi_awaddr              : in  std_logic_vector((AXI_AWIDTH-1) downto 0);
      s_axi_awvalid             : in  std_logic;
      s_axi_awready             : out std_logic;
      s_axi_wdata               : in  std_logic_vector(31 downto 0);
      s_axi_wstrb               : in  std_logic_vector(3 downto 0);
      s_axi_wvalid              : in  std_logic;
      s_axi_wready              : out std_logic;
      s_axi_bresp               : out std_logic_vector(1 downto 0);
      s_axi_bvalid              : out std_logic;
      s_axi_bready              : in  std_logic;
      s_axi_araddr              : in  std_logic_vector((AXI_AWIDTH-1) downto 0);
      s_axi_arvalid             : in  std_logic;
      s_axi_arready             : out std_logic;
      s_axi_rdata               : out std_logic_vector(31 downto 0);
      s_axi_rresp               : out std_logic_vector(1 downto 0);
      s_axi_rvalid              : out std_logic;
      s_axi_rready              : in  std_logic;
      m_ctrlport_req_wr         : out std_logic;
      m_ctrlport_req_rd         : out std_logic;
      m_ctrlport_req_addr       : out std_logic_vector(19 downto 0);
      m_ctrlport_req_portid     : out std_logic_vector(9 downto 0);
      m_ctrlport_req_rem_epid   : out std_logic_vector(15 downto 0);
      m_ctrlport_req_rem_portid : out std_logic_vector(9 downto 0);
      m_ctrlport_req_data       : out std_logic_vector(31 downto 0);
      m_ctrlport_req_byte_en    : out std_logic_vector(3 downto 0);
      m_ctrlport_req_has_time   : out std_logic;
      m_ctrlport_req_time       : out std_logic_vector(63 downto 0);
      m_ctrlport_resp_ack       : in  std_logic;
      m_ctrlport_resp_status    : in  std_logic_vector(1 downto 0);
      m_ctrlport_resp_data      : in  std_logic_vector(31 downto 0));
  end component;

  component x4xx_core_common
    generic (
      CHDR_CLK_RATE  : integer := 200000000;
      CHDR_W         : integer := 64;
      RFNOC_PROTOVER : integer := 0;
      PCIE_PRESENT   : integer := 0
      );
    port (
      radio_clk                 : in  std_logic;
      radio_rst                 : in  std_logic;
      rfnoc_chdr_clk            : in  std_logic;
      rfnoc_chdr_rst            : in  std_logic;
      rfnoc_ctrl_clk            : in  std_logic;
      rfnoc_ctrl_rst            : in  std_logic;
      ctrlport_rst              : in  std_logic;
      ctrlport_clk              : in  std_logic;
      s_ctrlport_req_wr         : in  std_logic;
      s_ctrlport_req_rd         : in  std_logic;
      s_ctrlport_req_addr       : in  std_logic_vector(19 downto 0);
      s_ctrlport_req_portid     : in  std_logic_vector(9 downto 0);
      s_ctrlport_req_rem_epid   : in  std_logic_vector(15 downto 0);
      s_ctrlport_req_rem_portid : in  std_logic_vector(9 downto 0);
      s_ctrlport_req_data       : in  std_logic_vector(31 downto 0);
      s_ctrlport_req_byte_en    : in  std_logic_vector(3 downto 0);
      s_ctrlport_req_has_time   : in  std_logic;
      s_ctrlport_req_time       : in  std_logic_vector(63 downto 0);
      s_ctrlport_resp_ack       : out std_logic;
      s_ctrlport_resp_status    : out std_logic_vector(1 downto 0);
      s_ctrlport_resp_data      : out std_logic_vector(31 downto 0);
      pps_radioclk              : in  std_logic;
      refclk_locked             : in  std_logic;
      pps_select                : out std_logic_vector(1 downto 0);
      ref_select                : out std_logic;
      trig_io_select            : out std_logic_vector(1 downto 0);
      pll_sync_trigger          : out std_logic;
      pll_sync_delay            : out std_logic_vector(7 downto 0);
      pll_sync_done             : in  std_logic;
      pps_brc_delay             : out std_logic_vector(7 downto 0);
      pps_prc_delay             : out std_logic_vector(25 downto 0);
      prc_rc_divider            : out std_logic_vector(1 downto 0);
      pps_rc_enabled            : out std_logic;
      radio_spc                 : in  std_logic_vector(7 downto 0);
      radio_time                : out std_logic_vector(63 downto 0);
      sample_rx_stb             : in  std_logic;
      gpio_in_a                 : in  std_logic_vector(11 downto 0);
      gpio_in_b                 : in  std_logic_vector(11 downto 0);
      gpio_out_a                : out std_logic_vector(11 downto 0);
      gpio_out_b                : out std_logic_vector(11 downto 0);
      gpio_en_a                 : out std_logic_vector(11 downto 0);
      gpio_en_b                 : out std_logic_vector(11 downto 0);
      gpio_in_fabric_a          : out std_logic_vector(11 downto 0);
      gpio_in_fabric_b          : out std_logic_vector(11 downto 0);
      gpio_out_fabric_a         : in  std_logic_vector(11 downto 0);
      gpio_out_fabric_b         : in  std_logic_vector(11 downto 0);
      qsfp_port_0_0_info        : in  std_logic_vector(31 downto 0);
      qsfp_port_0_1_info        : in  std_logic_vector(31 downto 0);
      qsfp_port_0_2_info        : in  std_logic_vector(31 downto 0);
      qsfp_port_0_3_info        : in  std_logic_vector(31 downto 0);
      qsfp_port_1_0_info        : in  std_logic_vector(31 downto 0);
      qsfp_port_1_1_info        : in  std_logic_vector(31 downto 0);
      qsfp_port_1_2_info        : in  std_logic_vector(31 downto 0);
      qsfp_port_1_3_info        : in  std_logic_vector(31 downto 0);
      gps_status                : in  std_logic_vector(31 downto 0);
      gps_ctrl                  : out std_logic_vector(31 downto 0);
      dboard_status             : in  std_logic_vector(31 downto 0);
      dboard_ctrl               : out std_logic_vector(31 downto 0);
      device_id                 : out std_logic_vector(15 downto 0);
      mfg_test_en_fabric_clk    : out std_logic;
      mfg_test_en_gty_rcv_clk   : out std_logic;
      fpga_aux_ref              : in  std_logic;
      version_info              : in  std_logic_vector(64*96-1 downto 0)
      );
  end component;

  --vhook_sigstart
  signal cAxiReadAddressChannel: Axi4LiteAddressChannel_t;
  signal cAxiReadDataChannel: Axi4LiteReadDataChannel_t;
  signal cAxiReadDataReady: boolean;
  signal cAxiWriteAddressChannel: Axi4LiteAddressChannel_t;
  signal cAxiWriteDataChannel: Axi4LiteWriteDataChannel_t;
  signal cAxiWriteResponseChannel: Axi4LiteWriteResponseChannel_t;
  signal cAxiWriteResponseReady: boolean;
  signal ctrlport_req_addr: std_logic_vector(19 downto 0);
  signal ctrlport_req_byte_en: std_logic_vector(3 downto 0);
  signal ctrlport_req_data: std_logic_vector(31 downto 0);
  signal ctrlport_req_has_time: std_logic;
  signal ctrlport_req_portid: std_logic_vector(9 downto 0);
  signal ctrlport_req_rd: std_logic;
  signal ctrlport_req_rem_epid: std_logic_vector(15 downto 0);
  signal ctrlport_req_rem_portid: std_logic_vector(9 downto 0);
  signal ctrlport_req_time: std_logic_vector(63 downto 0);
  signal ctrlport_req_wr: std_logic;
  signal ctrlport_resp_ack: std_logic;
  signal ctrlport_resp_data: std_logic_vector(31 downto 0);
  signal ctrlport_resp_status: std_logic_vector(1 downto 0);
  --vhook_sigend

  constant REG_DWIDTH : integer := 32;

  component reset_sync
    port (
      clk       : in  std_logic;
      reset_in  : in  std_logic;
      reset_out : out std_logic);
  end component;

  signal dio_inout_a: std_logic_vector(11 downto 0);
  signal dio_inout_b: std_logic_vector(11 downto 0);

  signal gpio_in_fabric_a: std_logic_vector(11 downto 0);
  signal gpio_in_fabric_b: std_logic_vector(11 downto 0);
  signal gpio_out_fabric_a: std_logic_vector(11 downto 0);
  signal gpio_out_fabric_b: std_logic_vector(11 downto 0);

  signal gpio_out_a: std_logic_vector(11 downto 0);
  signal gpio_out_b: std_logic_vector(11 downto 0);
  signal gpio_en_a: std_logic_vector(11 downto 0);
  signal gpio_en_b: std_logic_vector(11 downto 0);

  signal s_axi_arready: std_logic;
  signal s_axi_awready: std_logic;
  signal s_axi_bready: std_logic;
  signal s_axi_bvalid: std_logic;
  signal s_axi_rready: std_logic;
  signal s_axi_rvalid: std_logic;
  signal s_axi_wready: std_logic;

  signal StopSim : boolean;
  shared variable Rand : Random_t;

  constant kClk40 : time := 25 ns;  -- 40 MHz
  constant kClk200 : time := 5 ns;  -- 200 MHz
  constant kRadioPer : time := 8.14 ns;  -- 122.88 MHz
  signal clk40 : std_logic := '0';
  signal clk200 : std_logic := '0';
  signal radio_clk : std_logic := '0';

  signal areset : std_logic := '0';
  signal radio_rst: std_logic;
  signal clk40_reset : std_logic := '0';
  signal clk40_reset_n : std_logic := '0';
  signal clk200_reset : std_logic := '0';

  signal mfg_test_en_fabric_clk : std_logic := '0';
  signal mfg_test_en_gty_rcv_clk : std_logic := '0';
  signal fpga_aux_ref : std_logic := '0';
begin

  clk40 <= not clk40 after kClk40/2 when not StopSim else '0';
  clk200 <= not clk200 after kClk200/2 when not StopSim else '0';
  radio_clk <= not radio_clk after kRadioPer/2 when not StopSim else '0';
  fpga_aux_ref <= not fpga_aux_ref after 1 us when not StopSim else '0';

  x4xx_core_commonx : x4xx_core_common
  generic map(
    CHDR_CLK_RATE  => 200000000,  --integer:=200000000
    CHDR_W         => 64,         --integer:=64
    RFNOC_PROTOVER => 256)        --integer:={8'b01,8'b0}
  port map(
    radio_clk                 => radio_clk,                  --in  wire
    radio_rst                 => radio_rst,                  --in  wire
    rfnoc_chdr_clk            => clk200,                     --in  wire
    rfnoc_chdr_rst            => clk200_reset,               --in  wire
    rfnoc_ctrl_clk            => clk40,                      --in  wire
    rfnoc_ctrl_rst            => clk40_reset,                --in  wire
    ctrlport_rst              => clk40_reset,                --in  wire
    ctrlport_clk              => Clk40,                      --in  wire
    s_ctrlport_req_wr         => ctrlport_req_wr,            --in  wire
    s_ctrlport_req_rd         => ctrlport_req_rd,            --in  wire
    s_ctrlport_req_addr       => ctrlport_req_addr,          --in  wire[19:0]
    s_ctrlport_req_portid     => ctrlport_req_portid,        --in  wire[9:0]
    s_ctrlport_req_rem_epid   => ctrlport_req_rem_epid,      --in  wire[15:0]
    s_ctrlport_req_rem_portid => ctrlport_req_rem_portid,    --in  wire[9:0]
    s_ctrlport_req_data       => ctrlport_req_data,          --in  wire[31:0]
    s_ctrlport_req_byte_en    => ctrlport_req_byte_en,       --in  wire[3:0]
    s_ctrlport_req_has_time   => ctrlport_req_has_time,      --in  wire
    s_ctrlport_req_time       => ctrlport_req_time,          --in  wire[63:0]
    s_ctrlport_resp_ack       => ctrlport_resp_ack,          --out wire
    s_ctrlport_resp_status    => ctrlport_resp_status,       --out wire[1:0]
    s_ctrlport_resp_data      => ctrlport_resp_data,         --out wire[31:0]
    pps_radioclk              => '0',                        --in  wire
    refclk_locked             => '0',                        --in  wire
    pps_select                => open,                       --out wire[1:0]
    ref_select                => open,                       --out wire
    trig_io_select            => open,                       --out std_logic_vector(1 downto 0);
    pll_sync_trigger          => open,                       --out std_logic;
    pll_sync_delay            => open,                       --out std_logic_vector(7 downto 0);
    pll_sync_done             => '0',                        --in  std_logic;
    pps_brc_delay             => open,                       --out std_logic_vector(7 downto 0);
    pps_prc_delay             => open,                       --out std_logic_vector(25 downto 0);
    prc_rc_divider            => open,                       --out std_logic_vector(1 downto 0);
    pps_rc_enabled            => open,                       --out std_logic;
    radio_spc                 => x"01",                      --in  wire[7:0]
    radio_time                => open,                       --out wire[63:0]
    sample_rx_stb             => '0',                        --in  wire
    gpio_in_a                 => dio_inout_a,                --in  wire[11:0]
    gpio_in_b                 => dio_inout_b,                --in  wire[11:0]
    gpio_out_a                => gpio_out_a,                 --out wire[11:0]
    gpio_out_b                => gpio_out_b,                 --out wire[11:0]
    gpio_en_a                 => gpio_en_a,                  --out wire[11:0]
    gpio_en_b                 => gpio_en_b,                  --out wire[11:0]
    gpio_in_fabric_a          => gpio_in_fabric_a,           --out wire[11:0]
    gpio_in_fabric_b          => gpio_in_fabric_b,           --out wire[11:0]
    gpio_out_fabric_a         => gpio_out_fabric_a,          --in  wire[11:0]
    gpio_out_fabric_b         => gpio_out_fabric_b,          --in  wire[11:0]
    qsfp_port_0_0_info        => X"FACE2200",                    --in  wire[31:0]
    qsfp_port_0_1_info        => X"FACE2201",                    --in  wire[31:0]
    qsfp_port_0_2_info        => X"FACE2202",                    --in  wire[31:0]
    qsfp_port_0_3_info        => X"FACE2203",                    --in  wire[31:0]
    qsfp_port_1_0_info        => X"FACE2204",                    --in  wire[31:0]
    qsfp_port_1_1_info        => X"FACE2205",                    --in  wire[31:0]
    qsfp_port_1_2_info        => X"FACE2206",                    --in  wire[31:0]
    qsfp_port_1_3_info        => X"FACE2207",                    --in  wire[31:0]
    gps_status                => (others => '0'),            --in  wire[31:0]
    gps_ctrl                  => open,                       --out wire[31:0]
    dboard_status             => (others => '0'),            --in  wire[31:0]
    dboard_ctrl               => open,                       --out wire[31:0]
    device_id                 => open,                       --out wire[15:0]
    mfg_test_en_fabric_clk    => mfg_test_en_fabric_clk,
    mfg_test_en_gty_rcv_clk   => mfg_test_en_gty_rcv_clk,
    fpga_aux_ref              => fpga_aux_ref,
    version_info              => (others => '0'));

  io_gen: for i in dio_inout_a'range generate
    dio_inout_a(i) <= gpio_out_a(i) when to_Boolean(gpio_en_a(i)) else 'Z';
    dio_inout_b(i) <= gpio_out_b(i) when to_Boolean(gpio_en_b(i)) else 'Z';
  end generate;

  cAxiReadDataChannel.Valid <= to_Boolean(s_axi_rvalid);
  cAxiWriteResponseChannel.Valid <= to_Boolean(s_axi_bvalid);
  s_axi_bready <= to_StdLogic(cAxiWriteResponseReady);
  s_axi_rready <= to_StdLogic(cAxiReadDataReady);

  --vhook_e MbAxi4LiteBfm
  --vhook_a kBfmInstance 0
  --vhook_a Clock clk40
  --vhook_a cAxiWriteAddressReady to_Boolean(s_axi_awready)
  --vhook_a cAxiWriteDataReady to_Boolean(s_axi_wready)
  --vhook_a cAxiReadAddressReady to_Boolean(s_axi_arready)
  --vhook_a RegStat open
  MbAxi4LiteBfmx: entity work.MbAxi4LiteBfm (model)
    generic map (kBfmInstance => 0)  --natural:=0
    port map (
      Clock                    => clk40,                      --in  std_logic
      cAxiWriteAddressChannel  => cAxiWriteAddressChannel,    --out Axi4LiteAddressChannel_t
      cAxiWriteAddressReady    => to_Boolean(s_axi_awready),  --in  boolean
      cAxiWriteDataChannel     => cAxiWriteDataChannel,       --out Axi4LiteWriteDataChannel_t
      cAxiWriteDataReady       => to_Boolean(s_axi_wready),   --in  boolean
      cAxiWriteResponseChannel => cAxiWriteResponseChannel,   --in  Axi4LiteWriteResponseChannel_t
      cAxiWriteResponseReady   => cAxiWriteResponseReady,     --out boolean
      cAxiReadAddressChannel   => cAxiReadAddressChannel,     --out Axi4LiteAddressChannel_t
      cAxiReadAddressReady     => to_Boolean(s_axi_arready),  --in  boolean
      cAxiReadDataChannel      => cAxiReadDataChannel,        --in  Axi4LiteReadDataChannel_t
      cAxiReadDataReady        => cAxiReadDataReady,          --out boolean
      RegStat                  => open);                      --out TestStatusString_t

  --vhook axil_ctrlport_master
  --vhook_a TIMEOUT 10
  --vhook_a AXI_AWIDTH 32
  --vhook_a CTRLPORT_AWIDTH 20
  --vhook_a s_axi_aclk Clk40
  --vhook_a s_axi_aresetn clk40_reset_n
  --vhook_a s_axi_awaddr std_logic_vector(cAxiWriteAddressChannel.Addr)
  --vhook_a s_axi_awvalid to_StdLogic(cAxiWriteAddressChannel.Valid)
  --vhook_a s_axi_awready s_axi_awready
  --vhook_a s_axi_wdata cAxiWriteDataChannel.Data
  --vhook_a s_axi_wstrb cAxiWriteDataChannel.Strb
  --vhook_a s_axi_wvalid to_StdLogic(cAxiWriteDataChannel.Valid)
  --vhook_a s_axi_wready s_axi_wready
  --vhook_a s_axi_bresp cAxiWriteResponseChannel.Resp
  --vhook_a s_axi_bvalid s_axi_bvalid
  --vhook_a s_axi_bready s_axi_bready
  --vhook_a s_axi_araddr std_logic_vector(cAxiReadAddressChannel.Addr)
  --vhook_a s_axi_arvalid to_StdLogic(cAxiReadAddressChannel.Valid)
  --vhook_a s_axi_arready s_axi_arready
  --vhook_a s_axi_rdata cAxiReadDataChannel.Data
  --vhook_a s_axi_rresp cAxiReadDataChannel.Resp
  --vhook_a s_axi_rvalid s_axi_rvalid
  --vhook_a s_axi_rready s_axi_rready
  --vhook_a {m_ctrlport(.*)} {ctrlport$1}
  axil_ctrlport_masterx: axil_ctrlport_master
    generic map (
      TIMEOUT         => 10,  --integer:=10
      AXI_AWIDTH      => 32,  --integer:=17
      CTRLPORT_AWIDTH => 20)  --integer:=17
    port map (
      s_axi_aclk                => Clk40,                                           --in  wire
      s_axi_aresetn             => clk40_reset_n,                                   --in  wire
      s_axi_awaddr              => std_logic_vector(cAxiWriteAddressChannel.Addr),  --in  wire[(AXI_AWIDTH-1):0]
      s_axi_awvalid             => to_StdLogic(cAxiWriteAddressChannel.Valid),      --in  wire
      s_axi_awready             => s_axi_awready,                                   --out wire
      s_axi_wdata               => cAxiWriteDataChannel.Data,                       --in  wire[31:0]
      s_axi_wstrb               => cAxiWriteDataChannel.Strb,                       --in  wire[3:0]
      s_axi_wvalid              => to_StdLogic(cAxiWriteDataChannel.Valid),         --in  wire
      s_axi_wready              => s_axi_wready,                                    --out wire
      s_axi_bresp               => cAxiWriteResponseChannel.Resp,                   --out wire[1:0]
      s_axi_bvalid              => s_axi_bvalid,                                    --out wire
      s_axi_bready              => s_axi_bready,                                    --in  wire
      s_axi_araddr              => std_logic_vector(cAxiReadAddressChannel.Addr),   --in  wire[(AXI_AWIDTH-1):0]
      s_axi_arvalid             => to_StdLogic(cAxiReadAddressChannel.Valid),       --in  wire
      s_axi_arready             => s_axi_arready,                                   --out wire
      s_axi_rdata               => cAxiReadDataChannel.Data,                        --out wire[31:0]
      s_axi_rresp               => cAxiReadDataChannel.Resp,                        --out wire[1:0]
      s_axi_rvalid              => s_axi_rvalid,                                    --out wire
      s_axi_rready              => s_axi_rready,                                    --in  wire
      m_ctrlport_req_wr         => ctrlport_req_wr,                                 --out wire
      m_ctrlport_req_rd         => ctrlport_req_rd,                                 --out wire
      m_ctrlport_req_addr       => ctrlport_req_addr,                               --out wire[19:0]
      m_ctrlport_req_portid     => ctrlport_req_portid,                             --out wire[9:0]
      m_ctrlport_req_rem_epid   => ctrlport_req_rem_epid,                           --out wire[15:0]
      m_ctrlport_req_rem_portid => ctrlport_req_rem_portid,                         --out wire[9:0]
      m_ctrlport_req_data       => ctrlport_req_data,                               --out wire[31:0]
      m_ctrlport_req_byte_en    => ctrlport_req_byte_en,                            --out wire[3:0]
      m_ctrlport_req_has_time   => ctrlport_req_has_time,                           --out wire
      m_ctrlport_req_time       => ctrlport_req_time,                               --out wire[63:0]
      m_ctrlport_resp_ack       => ctrlport_resp_ack,                               --in  wire
      m_ctrlport_resp_status    => ctrlport_resp_status,                            --in  wire[1:0]
      m_ctrlport_resp_data      => ctrlport_resp_data);                             --in  wire[31:0]

  reset_gen_clk40: reset_sync
    port map (
      clk       => clk40,
      reset_in  => areset,
      reset_out => clk40_reset);

  reset_gen_clk200: reset_sync
    port map (
      clk       => clk200,
      reset_in  => areset,
      reset_out => clk200_reset);

  reset_gen_radio: reset_sync
    port map (
      clk       => radio_clk,
      reset_in  => areset,
      reset_out => radio_rst);

  clk40_reset_n <= not clk40_reset;

  main: process
    variable randomData : std_logic_vector(REG_DWIDTH-1 downto 0) := (others => '0');
    variable randomDirection : std_logic_vector(REG_DWIDTH-1 downto 0) := (others => '0');
    variable randomMaster : std_logic_vector(REG_DWIDTH-1 downto 0) := (others => '0');
    variable readData : std_logic_vector(REG_DWIDTH-1 downto 0);
    variable writeData : std_logic_vector(REG_DWIDTH-1 downto 0);
  begin

    ----------------------------------------------------------------------------
    -- Default assignments
    ----------------------------------------------------------------------------
    dio_inout_a <= (others => 'Z');
    dio_inout_b <= (others => 'Z');

    ----------------------------------------------------------------------------
    -- Reset
    ----------------------------------------------------------------------------
    areset <= '1';
    wait for 4 us;
    areset <= '0';

    wait until clk40_reset = '0';
    wait for 100*kClk40;

    ------------------------------------------------------------------------------
    ---- Test Portinfo
    ------------------------------------------------------------------------------
    VPrint("test portinfo");
    BusRd(kGLOBAL_REGS+kQSFP_PORT_0_0_INFO_REG, readData);
    assert readData = X"FACE2200" report "QSFP_PORT_0_0_INFO_REG value incorrect: " severity error;
    BusRd(kGLOBAL_REGS+kQSFP_PORT_0_1_INFO_REG, readData);
    assert readData = X"FACE2201" report "QSFP_PORT_0_1_INFO_REG value incorrect: " severity error;
    BusRd(kGLOBAL_REGS+kQSFP_PORT_0_2_INFO_REG, readData);
    assert readData = X"FACE2202" report "QSFP_PORT_0_2_INFO_REG value incorrect: " severity error;
    BusRd(kGLOBAL_REGS+kQSFP_PORT_0_3_INFO_REG, readData);
    assert readData = X"FACE2203" report "QSFP_PORT_0_3_INFO_REG value incorrect: " severity error;
    BusRd(kGLOBAL_REGS+kQSFP_PORT_1_0_INFO_REG, readData);
    assert readData = X"FACE2204" report "QSFP_PORT_1_0_INFO_REG value incorrect: " severity error;
    BusRd(kGLOBAL_REGS+kQSFP_PORT_1_1_INFO_REG, readData);
    assert readData = X"FACE2205" report "QSFP_PORT_1_1_INFO_REG value incorrect: " severity error;
    BusRd(kGLOBAL_REGS+kQSFP_PORT_1_2_INFO_REG, readData);
    assert readData = X"FACE2206" report "QSFP_PORT_1_2_INFO_REG value incorrect: " severity error;
    BusRd(kGLOBAL_REGS+kQSFP_PORT_1_3_INFO_REG, readData);
    assert readData = X"FACE2207" report "QSFP_PORT_1_3_INFO_REG value incorrect: " severity error;


    ------------------------------------------------------------------------------
    ---- Test Mfg registers
    ------------------------------------------------------------------------------
    VPrint("test mfg");
    assert mfg_test_en_fabric_clk = '0';
    assert mfg_test_en_gty_rcv_clk = '0';

    writeData := (others=> '0');
    writeData(kMFG_TEST_EN_FABRIC_CLK)  := '1';
    writeData(kMFG_TEST_EN_GTY_RCV_CLK) := '0';
    BusWt(kGLOBAL_REGS+kMFG_TEST_CTRL_REG, writeData);
    assert mfg_test_en_fabric_clk = '1';
    assert mfg_test_en_gty_rcv_clk = '0';
    BusRd(kGLOBAL_REGS+kMFG_TEST_CTRL_REG, readData);
    assert readData = writeData;

    writeData := (others=> '0');
    writeData(kMFG_TEST_EN_FABRIC_CLK)  := '0';
    writeData(kMFG_TEST_EN_GTY_RCV_CLK) := '1';
    BusWt(kGLOBAL_REGS+kMFG_TEST_CTRL_REG, writeData);
    assert mfg_test_en_fabric_clk = '0';
    assert mfg_test_en_gty_rcv_clk = '1';
    BusRd(kGLOBAL_REGS+kMFG_TEST_CTRL_REG, readData);
    assert readData = writeData;

    wait for 1 us;
    BusRd(kGLOBAL_REGS+kMFG_TEST_STATUS_REG, readData);
    assert to_integer(unsigned(readData(kMFG_TEST_FPGA_AUX_REF_FREQMsb downto
                                        kMFG_TEST_FPGA_AUX_REF_FREQ))) = 79;

    ------------------------------------------------------------------------------
    ---- Test GPIOs
    ------------------------------------------------------------------------------
    for i in 0 to 100 loop
      randomData := Rand.GetStdLogicVector(randomData'length) and kDIO_OUTPUT_REGISTERMask;
      randomDirection := Rand.GetStdLogicVector(randomDirection'length) and kDIO_DIRECTION_REGISTERMask;
      randomMaster := Rand.GetStdLogicVector(randomMaster'length) and kDIO_MASTER_REGISTERMask;
      VPrint("test configuration: data=" & HexImage(randomData) & " direction=" & HexImage(randomDirection) & " master=" & HexImage(randomMaster));

      -- update GPIO line assignment
      for j in dio_inout_a'range loop
        -- assign outputs from outside
        if to_Boolean(randomDirection(j)) then
          dio_inout_a(j) <= 'Z';
        else
          dio_inout_a(j) <= randomData(j);
        end if;
        if to_Boolean(randomDirection(j+kDIO_DIRECTION_B)) then
          dio_inout_b(j) <= 'Z';
        else
          dio_inout_b(j) <= randomData(j+kDIO_DIRECTION_B);
        end if;
      end loop;

      -- update registers
      BusWt(kDIO+kDIO_MASTER_REGISTER, randomMaster);
      BusWt(kDIO+kDIO_OUTPUT_REGISTER, randomData);
      BusWt(kDIO+kDIO_DIRECTION_REGISTER, randomDirection);

      -- update internal drivers with negated values
      gpio_out_fabric_a <= not randomData(kDIO_OUTPUT_AMsb downto kDIO_OUTPUT_A);
      gpio_out_fabric_b <= not randomData(kDIO_OUTPUT_BMsb downto kDIO_OUTPUT_B);

      -- bits from internal user logic are negated
      randomData := randomData xor (randomDirection and (not randomMaster));

      -- check signals
      BusRd(kDIO+kDIO_INPUT_REGISTER, readData);
      assert readData = randomData report "input register value incorrect: " & HexImage(readData) severity error;
      assert dio_inout_a = randomData(kDIO_OUTPUT_AMsb downto kDIO_OUTPUT_A) report "DIO A value incorrect" severity error;
      assert dio_inout_b = randomData(kDIO_OUTPUT_BMsb downto kDIO_OUTPUT_B) report "DIO B value incorrect" severity error;
      assert gpio_in_fabric_a = randomData(kDIO_INPUT_AMsb downto kDIO_INPUT_A) report "GPIO input A incorrect" severity error;
      assert gpio_in_fabric_b = randomData(kDIO_INPUT_BMsb downto kDIO_INPUT_B) report "GPIO input B incorrect" severity error;
    end loop;

    StopSim <= true;
    wait;
  end process;

end test;
--synopsys translate_on
